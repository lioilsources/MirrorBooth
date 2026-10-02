"""Shadertoy REST API client with on-disk JSON cache, rate limit and backoff.

Endpoints (all require ``?key=<app key>``, see https://www.shadertoy.com/howto):
  GET /api/v1/shaders                 -> {"Shaders": n, "Results": [ids]}
  GET /api/v1/shaders/query/{q}       -> {"Shaders": n, "Results": [ids]}
  GET /api/v1/shaders/{id}            -> {"Shader": {...}}

The API only returns shaders published as "public + API". Errors come back as
HTTP 200 with ``{"Error": "..."}``.
"""

from __future__ import annotations

import json
import time
from collections.abc import Callable, Iterable
from pathlib import Path
from typing import Any
from urllib.parse import quote

import httpx

from config import SHADERTOY_CACHE_DIR, settings
from shadertoy.model import Shader, parse_shader

API_BASE = "https://www.shadertoy.com/api/v1"
SORTS = ("name", "love", "popular", "newest", "hot")
FILTERS = ("vr", "soundoutput", "soundinput", "webcam", "multipass", "musicstream")
RETRY_STATUS = {429, 500, 502, 503, 504}


class ShadertoyError(RuntimeError):
    pass


class MissingApiKeyError(ShadertoyError):
    def __init__(self) -> None:
        super().__init__(
            "SHADERTOY_API_KEY is not set. Create a free app key at https://www.shadertoy.com/myapps "
            "and put it into pipeline/.env as SHADERTOY_API_KEY=..."
        )


class ShadertoyClient:
    def __init__(
        self,
        api_key: str | None = None,
        cache_dir: Path | None = SHADERTOY_CACHE_DIR,
        min_interval: float = 1.0,
        max_retries: int = 5,
        http: httpx.Client | None = None,
        sleep: Callable[[float], None] = time.sleep,
        clock: Callable[[], float] = time.monotonic,
    ):
        self.api_key = settings.shadertoy_api_key if api_key is None else api_key
        self.cache_dir = cache_dir
        self.min_interval = min_interval
        self.max_retries = max_retries
        self.http = http or httpx.Client(timeout=30.0, headers={"User-Agent": "MirrorBooth-ShaderGen/0.2"})
        self._sleep = sleep
        self._clock = clock
        self._last_request: float | None = None

    # -- low level ---------------------------------------------------------

    def _throttle(self) -> None:
        if self._last_request is not None:
            wait = self.min_interval - (self._clock() - self._last_request)
            if wait > 0:
                self._sleep(wait)
        self._last_request = self._clock()

    def _get(self, path: str, params: Iterable[tuple[str, Any]] = ()) -> dict:
        if not self.api_key:
            raise MissingApiKeyError()
        query = [(k, v) for k, v in params if v is not None] + [("key", self.api_key)]
        url = f"{API_BASE}/{path}"
        delay = 2.0
        for attempt in range(self.max_retries + 1):
            self._throttle()
            try:
                response = self.http.get(url, params=query)
            except httpx.TransportError as exc:
                if attempt == self.max_retries:
                    raise ShadertoyError(f"network error for {path}: {exc}") from exc
                self._sleep(delay)
                delay *= 2
                continue
            if response.status_code in RETRY_STATUS and attempt < self.max_retries:
                retry_after = response.headers.get("Retry-After", "")
                self._sleep(float(retry_after) if retry_after.isdigit() else delay)
                delay *= 2
                continue
            if response.status_code == 403:
                raise ShadertoyError(
                    f"HTTP 403 for {path} — Shadertoy blocks some proxies/cloud IPs; run from a LAN machine (M2/JODA)"
                )
            if response.status_code >= 400:
                raise ShadertoyError(f"HTTP {response.status_code} for {path}: {response.text[:200]}")
            try:
                data = response.json()
            except ValueError as exc:
                raise ShadertoyError(f"non-JSON response for {path}: {response.text[:200]!r}") from exc
            if isinstance(data, dict) and data.get("Error"):
                message = str(data["Error"])
                if "key" in message.lower():
                    raise ShadertoyError(f"Shadertoy rejected the API key: {message} (check SHADERTOY_API_KEY)")
                raise ShadertoyError(f"Shadertoy API error for {path}: {message}")
            return data
        raise ShadertoyError(f"giving up on {path} after {self.max_retries} retries")  # pragma: no cover

    # -- public API -------------------------------------------------------

    def list_ids(self) -> list[str]:
        return list(self._get("shaders").get("Results") or [])

    def search(
        self,
        query: str,
        sort: str = "popular",
        filter: str | Iterable[str] | None = None,  # noqa: A002 - mirrors the API parameter name
        from_: int = 0,
        num: int = 25,
    ) -> list[str]:
        if sort not in SORTS:
            raise ValueError(f"sort must be one of {SORTS}, got {sort!r}")
        filters = [filter] if isinstance(filter, str) else list(filter or [])
        unknown = [f for f in filters if f not in FILTERS]
        if unknown:
            raise ValueError(f"unknown Shadertoy filter(s) {unknown}; expected {FILTERS}")
        params: list[tuple[str, Any]] = [("sort", sort), ("from", from_), ("num", num)]
        params += [("filter", f) for f in filters]
        data = self._get(f"shaders/query/{quote(query, safe='')}", params)
        return list(data.get("Results") or [])

    def cache_path(self, shader_id: str) -> Path | None:
        return self.cache_dir / f"{shader_id}.json" if self.cache_dir else None

    def get_raw(self, shader_id: str, refresh: bool = False) -> dict:
        path = self.cache_path(shader_id)
        if path and path.exists() and not refresh:
            return json.loads(path.read_text(encoding="utf-8"))
        data = self._get(f"shaders/{quote(shader_id, safe='')}")
        if "Shader" not in data:
            raise ShadertoyError(f"unexpected response for shader {shader_id}: keys={list(data)}")
        if path:
            path.parent.mkdir(parents=True, exist_ok=True)
            tmp = path.with_suffix(".json.tmp")
            tmp.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            tmp.replace(path)  # atomic: an interrupted harvest never leaves a half-written cache file
        return data

    def get(self, shader_id: str, refresh: bool = False) -> Shader:
        return parse_shader(self.get_raw(shader_id, refresh=refresh))


def load_cached(shader_id: str, cache_dir: Path = SHADERTOY_CACHE_DIR) -> Shader:
    """Load a shader from the cache only (no network); raises FileNotFoundError."""
    path = cache_dir / f"{shader_id}.json"
    return parse_shader(json.loads(path.read_text(encoding="utf-8")))


def iter_cached(cache_dir: Path = SHADERTOY_CACHE_DIR) -> Iterable[Shader]:
    for path in sorted(cache_dir.glob("*.json")):
        try:
            yield parse_shader(json.loads(path.read_text(encoding="utf-8")))
        except (ValueError, KeyError) as exc:
            print(f"[shadertoy] WARNING: skipping unreadable cache file {path.name}: {exc}")
