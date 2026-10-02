"""Shadertoy client against recorded responses (respx) — no network."""

import json

import httpx
import pytest
import respx

from shadertoy.client import API_BASE, MissingApiKeyError, ShadertoyClient, ShadertoyError
from tests.shadertoy_factory import load_fixture


@pytest.fixture
def client(tmp_path):
    sleeps: list[float] = []
    c = ShadertoyClient(api_key="KEY", cache_dir=tmp_path / "cache", sleep=sleeps.append, clock=lambda: 0.0)
    c.sleeps = sleeps
    return c


@respx.mock
def test_search_passes_params(client):
    route = respx.get(f"{API_BASE}/shaders/query/webcam%20fx").mock(
        return_value=httpx.Response(200, json={"Shaders": 2, "Results": ["a1", "b2"]})
    )
    ids = client.search("webcam fx", sort="love", filter="webcam", num=10)
    assert ids == ["a1", "b2"]
    params = route.calls.last.request.url.params
    assert params["key"] == "KEY" and params["sort"] == "love" and params["filter"] == "webcam"
    assert params["num"] == "10" and params["from"] == "0"


@respx.mock
def test_get_caches_shader(client):
    payload = load_fixture("webcam_invert")
    route = respx.get(f"{API_BASE}/shaders/stWebInv").mock(return_value=httpx.Response(200, json=payload))
    shader = client.get("stWebInv")
    again = client.get("stWebInv")
    assert route.call_count == 1
    assert shader.info.name == again.info.name == "Webcam Invert Wave"
    assert shader.image_pass.inputs[0].ctype == "webcam"
    assert json.loads(client.cache_path("stWebInv").read_text())["Shader"]["info"]["id"] == "stWebInv"


@respx.mock
def test_backoff_on_429_then_success(client):
    respx.get(f"{API_BASE}/shaders").mock(
        side_effect=[httpx.Response(429), httpx.Response(503), httpx.Response(200, json={"Results": ["x"]})]
    )
    assert client.list_ids() == ["x"]
    backoffs = [s for s in client.sleeps if s >= 2.0]
    assert backoffs == [2.0, 4.0]


@respx.mock
def test_rate_limit_sleeps_between_requests(tmp_path):
    now = [0.0]
    sleeps: list[float] = []
    c = ShadertoyClient(api_key="K", cache_dir=None, sleep=sleeps.append, clock=lambda: now[0], min_interval=1.0)
    respx.get(f"{API_BASE}/shaders").mock(return_value=httpx.Response(200, json={"Results": []}))
    c.list_ids()
    now[0] = 0.3
    c.list_ids()
    assert sleeps == [pytest.approx(0.7)]


@respx.mock
def test_api_error_payload(client):
    respx.get(f"{API_BASE}/shaders/nope").mock(return_value=httpx.Response(200, json={"Error": "Shader not found"}))
    with pytest.raises(ShadertoyError, match="not found"):
        client.get("nope")


@respx.mock
def test_403_mentions_proxy(client):
    respx.get(f"{API_BASE}/shaders").mock(return_value=httpx.Response(403))
    with pytest.raises(ShadertoyError, match="403"):
        client.list_ids()


def test_missing_key_message(tmp_path):
    c = ShadertoyClient(api_key="", cache_dir=tmp_path)
    with pytest.raises(MissingApiKeyError, match="shadertoy.com/myapps"):
        c.search("webcam")


def test_invalid_sort_rejected(client):
    with pytest.raises(ValueError):
        client.search("x", sort="random")


@pytest.mark.network
def test_live_search_smoke():  # pragma: no cover - needs SHADERTOY_API_KEY + internet
    from config import settings

    if not settings.shadertoy_api_key:
        pytest.skip("SHADERTOY_API_KEY not set")
    ids = ShadertoyClient(cache_dir=None).search("webcam", num=3)
    assert ids
