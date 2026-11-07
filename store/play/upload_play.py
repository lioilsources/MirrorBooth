#!/usr/bin/env python3
"""Push a release and new phone screenshots to Google Play in one edit.

    python3 store/play/upload_play.py 2.4.0 [--track internal] [--no-shots] [--dry-run]

- Downloads app-release.aab from the GitHub release v<version> (gh CLI) and
  uploads it to --track (default internal: testers only, nothing public).
- Appends the character shots in SHOTS to the en-US phone screenshots, up to
  Play's limit of 8; ones already there (same SHA-1) are skipped.
- Release notes come from RELEASE_NOTES.

Uses store/play/play_api.py (service account from PLAY_SA_PATH). --dry-run
opens the edit, prints what it would do and deletes the edit unchanged.
Promoting to production stays a Play Console click.
"""
import hashlib
import pathlib
import subprocess
import sys
import tempfile

from play_api import PACKAGE, UPLOAD, call

HERE = pathlib.Path(__file__).resolve().parent
CANDIDATES = HERE.parent / "appstore/screenshots/candidates/play"
SHOTS = ["cat_01_lr", "comic_01_lr", "alien_01_lr", "alien_02_filters"]
MAX_SHOTS = 8
RELEASE_NOTES = {
    "en-US": "• Art and Fantasy purchases restore on a new phone\n"
             "• Better TalkBack support and larger text\n"
             "• Shared photos and videos link back to Mirror Booth",
    "cs-CZ": "• Nákupy Art a Fantasy se obnoví i na novém telefonu\n"
             "• Lepší podpora TalkBacku a většího písma\n"
             "• Sdílené fotky a videa odkazují zpět na Mirror Booth",
}


def download_aab(version, folder):
    subprocess.run(["gh", "release", "download", f"v{version}", "--pattern",
                    "app-release.aab", "--dir", str(folder), "--clobber",
                    "--repo", "lioilsources/MirrorBooth"], check=True)
    return folder / "app-release.aab"


def main():
    argv = sys.argv[1:]
    dry = "--dry-run" in argv
    shots = "--no-shots" not in argv
    track = argv[argv.index("--track") + 1] if "--track" in argv else "internal"
    version = next(a for a in argv if a[0].isdigit())

    edit = call("POST", f"/applications/{PACKAGE}/edits", {})["id"]
    base = f"/applications/{PACKAGE}/edits/{edit}"
    try:
        with tempfile.TemporaryDirectory() as tmp:
            aab = download_aab(version, pathlib.Path(tmp))
            print(f"bundle {aab.stat().st_size // 1_000_000} MB -> {track}")
            if not dry:
                bundle = call("POST", base + "/bundles?uploadType=media", base=UPLOAD,
                              raw=aab.read_bytes(), content_type="application/octet-stream")
                code = bundle["versionCode"]
                call("PUT", base + f"/tracks/{track}", {"track": track, "releases": [{
                    "name": version, "versionCodes": [str(code)], "status": "completed",
                    "releaseNotes": [{"language": k, "text": v}
                                     for k, v in RELEASE_NOTES.items()],
                }]})
                print(f"versionCode {code} on {track}")

        if shots:
            have = call("GET", base + "/listings/en-US/phoneScreenshots").get("images", [])
            sha = {i.get("sha1") for i in have}
            room = MAX_SHOTS - len(have)
            for name in SHOTS:
                data = (CANDIDATES / f"{name}.png").read_bytes()
                if hashlib.sha1(data).hexdigest() in sha:
                    print(name, "already there")
                    continue
                if room <= 0:
                    print(name, "skipped: Play allows", MAX_SHOTS)
                    continue
                print(name, "added" if not dry else "would be added")
                if not dry:
                    call("POST", base + "/listings/en-US/phoneScreenshots?uploadType=media",
                         base=UPLOAD, raw=data, content_type="image/png")
                room -= 1

        if dry:
            call("DELETE", base)
            print("dry run: edit discarded")
        else:
            call("POST", base + ":commit")
            print("committed")
    except BaseException:
        call("DELETE", base)
        raise


if __name__ == "__main__":
    main()
