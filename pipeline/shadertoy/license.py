"""License classifier for Shadertoy shaders (decision B of the ShaderGen v2 plan).

Shadertoy's default license is CC BY-NC-SA 3.0 (non-commercial). MirrorBooth
sells filter collections, so only shaders whose header *explicitly* grants a
permissive license may be ported verbatim. The classifier is conservative:

* any restrictive marker (NonCommercial, ShareAlike, GPL, "all rights reserved",
  "you cannot use this work", ...) wins over a permissive one,
* a shader that says it is derived from another Shadertoy shader is not
  permissive (the upstream license is unknown),
* no recognisable header -> the Shadertoy default (non-permissive).

The input is the comment text of all passes plus the shader description; code
outside comments is ignored so identifiers like ``mit`` cannot trigger a match.
"""

from __future__ import annotations

import re
from dataclasses import asdict, dataclass

from glslscan import extract_comments

DEFAULT_LICENSE = "CC BY-NC-SA 3.0 (default)"

# (regex, label) — order matters: first match is reported as the license.
_PERMISSIVE: list[tuple[str, str]] = [
    (r"SPDX-License-Identifier:\s*MIT\b", "MIT"),
    (r"SPDX-License-Identifier:\s*CC0", "CC0 1.0"),
    (r"SPDX-License-Identifier:\s*Unlicense", "Unlicense"),
    (r"SPDX-License-Identifier:\s*BSD", "BSD"),
    (r"SPDX-License-Identifier:\s*CC-BY-(?:4\.0|3\.0)\b", "CC BY"),
    (
        r"\bMIT\s+License\b|\bLicen[cs]ed\s+under\s+(?:the\s+)?MIT\b|\bMIT\s+licen[cs]ed\b|\(MIT\)|\bLicen[cs]e:\s*MIT\b",
        "MIT",
    ),
    (r"Permission is hereby granted, free of charge", "MIT"),
    (r"\bCC0\b|\bCC\s*Zero\b|Creative\s+Commons\s+Zero|publicdomain/zero", "CC0 1.0"),
    (r"\bUnlicen[sc]e\b|unlicense\.org", "Unlicense"),
    (r"\bpublic[\s-]+domain\b", "Public Domain"),
    (r"\bBSD[\s-]*(?:[23][\s-]*Clause|licen[cs]e|style)\b|\b[23]-clause\s+BSD\b", "BSD"),
    (r"\bCC[\s-]+BY[\s-]+(?:4\.0|3\.0)\b|\bCC[\s-]+BY\s+licen[cs]e", "CC BY"),
    (r"Creative\s+Commons\s+Attribution\s+(?:4\.0|3\.0)\s+(?:International|Unported)", "CC BY"),
    (r"licenses/by/(?:4\.0|3\.0)", "CC BY"),
]

_RESTRICTIVE: list[tuple[str, str]] = [
    (r"\bCC[\s-]+BY[\s-]+NC[\s-]+SA\b|BY-NC-SA|licenses/by-nc-sa", "CC BY-NC-SA"),
    (r"\bCC[\s-]+BY[\s-]+NC[\s-]+ND\b|BY-NC-ND|licenses/by-nc-nd", "CC BY-NC-ND"),
    (r"\bCC[\s-]+BY[\s-]+NC\b|BY-NC\b|licenses/by-nc", "CC BY-NC"),
    (r"\bCC[\s-]+BY[\s-]+SA\b|BY-SA\b|licenses/by-sa", "CC BY-SA"),
    (r"\bCC[\s-]+BY[\s-]+ND\b|BY-ND\b|licenses/by-nd", "CC BY-ND"),
    (r"Non[\s-]?Commercial", "NonCommercial"),
    (r"Share[\s-]?Alike", "ShareAlike"),
    (r"\bL?GPL(?:v?\d)?\b|GNU\s+(?:Lesser\s+)?General\s+Public", "GPL"),
    (r"all\s+rights\s+reserved", "All rights reserved"),
    (r"sole\s+copyright\s+owner", "All rights reserved"),
    (
        r"you\s+(?:cannot|can\s*not|may\s+not|are\s+not\s+allowed\s+to)\s+(?:use|host|display|distribute|share|sell)",
        "Restricted",
    ),
    (
        r"\bnot\s+for\s+commercial\b|\bno\s+commercial\b|\bcommercial\s+use\s+(?:is\s+)?(?:not|prohibited|forbidden)",
        "NonCommercial",
    ),
    (r"without\s+(?:my\s+|explicit\s+|written\s+)?permission", "Restricted"),
]

_DERIVED = re.compile(
    r"(?:based\s+on|forked?\s+from|fork\s+of|adapted\s+from|derived\s+from|port(?:ed)?\s+(?:of|from)|"
    r"modified\s+(?:version\s+)?of|stolen\s+from|borrowed\s+from|from)\s*:?\s*"
    r"(?:https?://)?(?:www\.)?shadertoy\.com/view/\w+",
    re.IGNORECASE,
)


@dataclass
class LicenseInfo:
    license: str
    permissive: bool
    evidence: str = ""  # matched text (for the harvest report)
    reason: str = ""

    def to_dict(self) -> dict:
        return asdict(self)


def _first(patterns: list[tuple[str, str]], text: str) -> tuple[str, str] | None:
    for pattern, label in patterns:
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            return label, m.group(0)
    return None


def classify_text(comment_text: str, description: str = "", name: str = "") -> LicenseInfo:
    """Classify already-extracted comment text (plus optional description/name)."""
    text = "\n".join(t for t in (comment_text, description) if t)

    restrictive = _first(_RESTRICTIVE, text)
    if restrictive:
        label, evidence = restrictive
        return LicenseInfo(
            license=label, permissive=False, evidence=evidence.strip(), reason="restrictive license terms found"
        )

    permissive = _first(_PERMISSIVE, text)
    if not permissive:
        return LicenseInfo(license=DEFAULT_LICENSE, permissive=False, reason="no explicit license header")

    label, evidence = permissive
    derived = _DERIVED.search(text) or (name.lower().startswith("fork ") and "fork")
    if derived:
        snippet = derived.group(0) if hasattr(derived, "group") else derived
        return LicenseInfo(
            license=f"{label} (derived work)",
            permissive=False,
            evidence=evidence.strip(),
            reason=f"derived from another Shadertoy shader ({snippet}); upstream license unknown",
        )
    return LicenseInfo(license=label, permissive=True, evidence=evidence.strip(), reason="explicit permissive license")


def classify_shader(shader) -> LicenseInfo:
    """Classify a :class:`shadertoy.model.Shader` from all pass comments + description."""
    comments = "\n".join(extract_comments(p.code) for p in shader.renderpass)
    return classify_text(comments, shader.info.description, shader.info.name)
