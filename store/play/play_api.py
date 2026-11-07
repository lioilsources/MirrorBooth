"""Small Google Play Developer API client for the listing scripts.

Reads the service account JSON from PLAY_SA_PATH (default: the shared key in
~/Dev/Distribution). Same shape as store/appstore/asc_api.py: call(method,
path, body) against https://androidpublisher.googleapis.com/androidpublisher/v3.
"""
import json
import os
import pathlib
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

API = "https://androidpublisher.googleapis.com/androidpublisher/v3"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3"
PACKAGE = "com.ab.mirrorbooth"
SA_PATH = os.environ.get("PLAY_SA_PATH", str(pathlib.Path(
    "~/Dev/Distribution/Android/_GoogleConsole/GooglePlay/"
    "fir-app-distribution-bb2ae-0e3f418ce63b_service_account.json").expanduser()))

_token = None


def token():
    global _token
    if _token and _token[1] > time.time() + 60:
        return _token[0]
    sa = json.loads(pathlib.Path(SA_PATH).read_text())
    now = int(time.time())
    assertion = jwt.encode({
        "iss": sa["client_email"], "scope": "https://www.googleapis.com/auth/androidpublisher",
        "aud": sa["token_uri"], "iat": now, "exp": now + 3600,
    }, sa["private_key"], algorithm="RS256")
    body = urllib.parse.urlencode({
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion,
    }).encode()
    with urllib.request.urlopen(urllib.request.Request(sa["token_uri"], data=body)) as res:
        data = json.load(res)
    _token = (data["access_token"], now + data["expires_in"])
    return _token[0]


def call(method, path, body=None, base=API, raw=None, content_type=None):
    data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
    headers = {"Authorization": f"Bearer {token()}"}
    if data is not None:
        headers["Content-Type"] = content_type or "application/json"
    req = urllib.request.Request(base + path, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=300) as res:
            text = res.read()
            return json.loads(text) if text else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path}: {e.code} {e.read().decode()[:800]}")
