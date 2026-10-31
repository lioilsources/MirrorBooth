"""Small App Store Connect API client for the listing scripts.

Reads the key from ASC_KEY_PATH, ASC_KEY_ID and ASC_ISSUER_ID. It needs the App
Manager role; the CI key (Developer) gets 403 on every metadata change.
"""
import json
import os
import pathlib
import time
import urllib.error
import urllib.request

import jwt

API = "https://api.appstoreconnect.apple.com"
APP_ID = "6767824892"


def _token():
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1000,
         "aud": "appstoreconnect-v1"},
        pathlib.Path(os.environ["ASC_KEY_PATH"]).expanduser().read_text(),
        algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"]},
    )


def call(method, path, body=None):
    req = urllib.request.Request(
        path if path.startswith("http") else API + path,
        method=method,
        data=None if body is None else json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {_token()}",
                 "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as res:
            raw = res.read()
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path}: {e.code} {e.read().decode()[:800]}")
    return json.loads(raw) if raw else None
