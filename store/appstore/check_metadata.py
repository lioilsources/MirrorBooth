#!/usr/bin/env python3
"""Check store/appstore/metadata/<locale>/ against App Store limits.

    python3 store/appstore/check_metadata.py

name and subtitle ≤ 30 characters, keywords ≤ 100 with no space after a
comma and no word that is already in the name or subtitle (the store
indexes those anyway), promotional text ≤ 170.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent / "metadata"
LIMITS = {"name.txt": 30, "subtitle.txt": 30, "keywords.txt": 100,
          "promotional_text.txt": 170}


def words(text):
    return {w for w in re.split(r"[\s:,&+\-]+", text.lower()) if w}


def main():
    problems = []
    for loc in sorted(p for p in ROOT.iterdir() if p.is_dir()):
        texts = {f: (loc / f).read_text().strip() for f in LIMITS if (loc / f).exists()}
        for f, text in texts.items():
            if len(text) > LIMITS[f]:
                problems.append(f"{loc.name}/{f}: {len(text)} > {LIMITS[f]}")
        kw = texts.get("keywords.txt", "")
        if ", " in kw:
            problems.append(f"{loc.name}/keywords.txt: space after a comma")
        terms = [t for t in kw.split(",") if t]
        if len(terms) != len(set(terms)):
            problems.append(f"{loc.name}/keywords.txt: duplicate keyword")
        taken = words(texts.get("name.txt", "")) | words(texts.get("subtitle.txt", ""))
        clash = sorted(set(terms) & taken)
        if clash:
            problems.append(f"{loc.name}/keywords.txt: already in name/subtitle: {clash}")
        print(f"{loc.name:6} name {len(texts.get('name.txt', '')):2}  "
              f"subtitle {len(texts.get('subtitle.txt', '')):2}  keywords {len(kw):3}  "
              f"promo {len(texts.get('promotional_text.txt', '')):3}")
    for p in problems:
        print("PROBLEM", p)
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
