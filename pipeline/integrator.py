"""
Deterministic, idempotent auto-integration of a generated shader into the
Flutter app.

Runs AFTER the LangGraph pipeline (called from run.py), not as a graph node,
so filesystem mutation is decoupled from the retry state machine and is
trivially unit-testable against a fake tree.

It performs three edits, transactionally (all-or-nothing — the in-memory
result is fully validated before anything is written):

1. copy  `filter_<snake>.frag`              -> mirrorbooth/shaders/
2. insert `- shaders/filter_<snake>.frag`   -> pubspec.yaml shaders: block
3. insert enum + label/icon/needsTime/shaderAsset arms -> mirror_filter.dart
   (each above its `// >>> generated-filters-<x> <<<` sentinel)

Re-running with the same --name is a zero-diff no-op. A name whose camelCase
enum identifier collides with an existing filter gets a numeric suffix applied
consistently to the enum id, all switch arms and the .frag filename.
"""

from __future__ import annotations

import re
from pathlib import Path

from config import MIRROR_FILTER_DART, PUBSPEC_PATH, SHADERS_DIR

SENTINELS = {
    "enum": "// >>> generated-filters-enum <<<",
    "label": "// >>> generated-filters-label <<<",
    "icon": "// >>> generated-filters-icon <<<",
    "needstime": "// >>> generated-filters-needstime <<<",
    "shaderasset": "// >>> generated-filters-shaderasset <<<",
}

_ICON_POOL = ["#", "@", "&", "%", "+", "=", "?", "$", "~", "^", "¤", "¶", "µ", "Ω"]


class IntegrationError(Exception):
    pass


def _snake(name: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "_", name.strip().lower())
    return re.sub(r"_+", "_", s).strip("_") or "filter"


def _camel(snake: str) -> str:
    parts = [p for p in snake.split("_") if p]
    head = parts[0]
    name = head + "".join(p[:1].upper() + p[1:] for p in parts[1:])
    if name[0].isdigit():
        name = "f" + name
    return name


def _enum_identifiers(dart: str) -> set[str]:
    m = re.search(r"enum\s+MirrorFilter\s*\{", dart)
    if not m:
        raise IntegrationError("enum MirrorFilter not found")
    start = m.end()
    end = dart.find(SENTINELS["enum"], start)
    if end == -1:
        raise IntegrationError(f"missing sentinel: {SENTINELS['enum']}")
    ids = set()
    for line in dart[start:end].splitlines():
        tok = line.strip().rstrip(",").rstrip(";").strip()
        if re.fullmatch(r"[A-Za-z_]\w*", tok):
            ids.add(tok)
    return ids


def _used_icons(dart: str) -> set[str]:
    block = ""
    m = re.search(r"get icon =>.*?\};", dart, re.S)
    if m:
        block = m.group(0)
    return set(re.findall(r"=>\s*'([^']*)'", block))


def _derive_label(tech_spec: dict, enum_name: str) -> str:
    raw = str(tech_spec.get("effect_name") or "").strip()
    raw = raw.replace("'", "").replace("\\", "").replace("\n", " ").strip()
    label = raw[:6].strip()
    if not label:
        label = enum_name[:6]
    return label[:1].upper() + label[1:]


def _derive_icon(tech_spec: dict, enum_name: str, used: set[str]) -> str:
    for ch in str(tech_spec.get("effect_name") or "") + enum_name:
        if ch.isascii() and ch.isalpha():
            return ch.upper()
    for ch in _ICON_POOL:
        if ch not in used:
            return ch
    return "*"


_PREV_MARKER = {
    "enum": "enum MirrorFilter {",
    "label": SENTINELS["enum"],
    "icon": SENTINELS["label"],
    "needstime": SENTINELS["icon"],
    "shaderasset": SENTINELS["needstime"],
}


def _section(dart: str, key: str) -> str:
    start = _PREV_MARKER[key]
    b = dart.find(start)
    e = dart.find(SENTINELS[key])
    if b == -1 or e == -1 or e < b:
        raise IntegrationError(f"cannot locate section for: {key}")
    return dart[b + len(start):e]


def _site_has_entry(dart: str, key: str, enum_name: str) -> bool:
    sec = _section(dart, key)
    if key == "enum":
        return any(
            ln.strip().rstrip(",").rstrip(";").strip() == enum_name
            for ln in sec.splitlines()
        )
    return re.search(rf"MirrorFilter\.{re.escape(enum_name)}\s*=>", sec) is not None


def _insert_before_sentinel(dart: str, key: str, new_line: str) -> str:
    sentinel = SENTINELS[key]
    idx = dart.find(sentinel)
    if idx == -1:
        raise IntegrationError(f"missing sentinel: {sentinel}")
    line_start = dart.rfind("\n", 0, idx) + 1
    return dart[:line_start] + new_line + "\n" + dart[line_start:]


def _pubspec_with_entry(pubspec: str, asset_rel: str) -> tuple[str, bool]:
    lines = pubspec.splitlines()
    s_idx = next(
        (i for i, ln in enumerate(lines) if re.fullmatch(r"\s*shaders:\s*", ln)),
        None,
    )
    if s_idx is None:
        raise IntegrationError("pubspec.yaml has no 'shaders:' block")
    entry_re = re.compile(r"^(\s*)-\s+shaders/.*\.frag\s*$")
    last, indent = s_idx, "    "
    for i in range(s_idx + 1, len(lines)):
        m = entry_re.match(lines[i])
        if m:
            last, indent = i, m.group(1)
            if lines[i].strip() == f"- {asset_rel}":
                return pubspec, False
        elif lines[i].strip() == "":
            continue
        else:
            break
    lines.insert(last + 1, f"{indent}- {asset_rel}")
    trailing = "\n" if pubspec.endswith("\n") else ""
    return "\n".join(lines) + trailing, True


def install(
    frag_path: Path,
    name: str,
    tech_spec: dict,
    *,
    shaders_dir: Path = SHADERS_DIR,
    pubspec_path: Path = PUBSPEC_PATH,
    dart_path: Path = MIRROR_FILTER_DART,
) -> dict:
    frag_path = Path(frag_path)
    if not frag_path.is_file():
        raise IntegrationError(f"shader not found: {frag_path}")

    dart = dart_path.read_text(encoding="utf-8")
    for s in SENTINELS.values():
        if s not in dart:
            raise IntegrationError(f"missing sentinel: {s}")

    pubspec = pubspec_path.read_text(encoding="utf-8")
    existing_ids = _enum_identifiers(dart)
    base_snake = _snake(name)
    base_camel = _camel(base_snake)

    # Resolve a (snake, enum) pair: idempotent if this exact asset already
    # exists, otherwise numerically suffixed until free.
    snake = enum_name = asset_rel = None
    already = False
    for i in range(0, 50):
        sfx = "" if i == 0 else str(i + 1)
        cand_snake = base_snake + sfx
        cand_enum = base_camel + sfx
        cand_asset = f"shaders/filter_{cand_snake}.frag"
        if f"'{cand_asset}'" in dart:
            snake, enum_name, asset_rel, already = (
                cand_snake, cand_enum, cand_asset, True,
            )
            break
        if cand_enum in existing_ids:
            continue
        snake, enum_name, asset_rel = cand_snake, cand_enum, cand_asset
        break
    if enum_name is None:
        raise IntegrationError("could not resolve a free enum identifier")

    label = _derive_label(tech_spec, enum_name)
    icon = _derive_icon(tech_spec, enum_name, _used_icons(dart))
    needs_time = bool(tech_spec.get("needs_time"))

    arms = {
        "enum": f"  {enum_name},",
        "label": f"        MirrorFilter.{enum_name} => '{label}',",
        "icon": f"        MirrorFilter.{enum_name} => '{icon}',",
        "shaderasset": f"        MirrorFilter.{enum_name} => '{asset_rel}',",
    }
    if needs_time:
        arms["needstime"] = f"        MirrorFilter.{enum_name} => true,"

    changed_sites: list[str] = []
    skipped: list[str] = []
    new_dart = dart
    for key in ("enum", "label", "icon", "needstime", "shaderasset"):
        if key not in arms:
            continue
        if _site_has_entry(dart, key, enum_name):
            skipped.append(key)
            continue
        new_dart = _insert_before_sentinel(new_dart, key, arms[key])
        changed_sites.append(key)

    new_pubspec, pubspec_changed = _pubspec_with_entry(pubspec, asset_rel)

    dest = shaders_dir / f"filter_{snake}.frag"
    src_bytes = frag_path.read_bytes()
    frag_changed = not (dest.is_file() and dest.read_bytes() == src_bytes)

    # ---- commit (validated in-memory; write order: dart, pubspec, frag) ----
    files_changed: list[str] = []
    if new_dart != dart:
        dart_path.write_text(new_dart, encoding="utf-8")
        files_changed.append(str(dart_path))
    if pubspec_changed:
        pubspec_path.write_text(new_pubspec, encoding="utf-8")
        files_changed.append(str(pubspec_path))
    if frag_changed:
        shaders_dir.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(src_bytes)
        files_changed.append(str(dest))

    return {
        "installed": True,
        "already_installed": already,
        "enum_name": enum_name,
        "label": label,
        "icon": icon,
        "needs_time": needs_time,
        "frag_filename": dest.name,
        "asset": asset_rel,
        "files_changed": files_changed,
        "skipped_sites": skipped,
    }
