#!/usr/bin/env python3
"""Verify (or with --fix, rewrite) every [N] character count in
play_console_metadata.md against Play's limits.

    python3 store/play/check_lengths.py [--fix]

Counted:
  * a line "<Label> [N]:" followed (after blank lines) by a fenced block — limit taken from the
    nearest preceding "### ... (LIMIT)" heading;
  * inline "`text` [N]" in table rows — App name (30), in-app product
    name (55) and description (200).
Counts are Python len() of the exact text (Unicode code points), which is
what Play counts. Exit status 1 on any mismatch or overflow.
"""
import pathlib
import re
import sys

MD = pathlib.Path(__file__).resolve().parent / "play_console_metadata.md"
LABEL = re.compile(r"^(?P<label>[^\[`|#]+?) \[(?P<n>\d+)\]:$")
HEADING = re.compile(r"^###? .*\((?P<limit>\d+)\)\s*$")
INLINE = re.compile(r"`(?P<text>[^`]+)` \[(?P<n>\d+)\]")


def inline_limits(row):
    if row.startswith("| App name"):
        return [30]
    if row.startswith("| `com.ol1n.mirrorbooth.collection."):
        return [55, 200]
    return None


def main():
    fix = "--fix" in sys.argv
    lines = MD.read_text(encoding="utf-8").split("\n")
    errors, limit, i = [], None, 0
    while i < len(lines):
        line = lines[i]
        h = HEADING.match(line)
        if h:
            limit = int(h["limit"])
        m = LABEL.match(line)
        k = i + 1
        while m and k < len(lines) and not lines[k].strip():
            k += 1
        if m and k < len(lines) and lines[k].startswith("```"):
            j = k + 1
            while not lines[j].startswith("```"):
                j += 1
            text = "\n".join(lines[k + 1:j])
            n = len(text)
            status = "ok" if n <= limit else "OVER"
            print(f"{status:4} {n:5}/{limit:<5} {m['label']} (line {i + 1})")
            if n > limit:
                errors.append(f"line {i + 1}: {n} > {limit}")
            if n != int(m["n"]):
                if fix:
                    lines[i] = f"{m['label']} [{n}]:"
                else:
                    errors.append(f"line {i + 1}: says {m['n']}, is {n}")
            i = j + 1
            continue
        limits = inline_limits(line)
        if limits:
            matches = list(INLINE.finditer(line))
            for k, (mm, lim) in enumerate(zip(matches, limits)):
                n = len(mm["text"])
                status = "ok" if n <= lim else "OVER"
                print(f"{status:4} {n:5}/{lim:<5} {mm['text'][:50]}")
                if n > lim:
                    errors.append(f"line {i + 1}: {n} > {lim}")
                if n != int(mm["n"]):
                    errors.append(f"line {i + 1}: says {mm['n']}, is {n}")
            if fix:
                lines[i] = INLINE.sub(
                    lambda mm: f"`{mm['text']}` [{len(mm['text'])}]", line)
        i += 1
    if fix:
        MD.write_text("\n".join(lines), encoding="utf-8")
        print("counts rewritten")
        return
    if errors:
        print("\n".join(errors), file=sys.stderr)
        sys.exit(1)
    print("all counts match and are within limits")


if __name__ == "__main__":
    main()
