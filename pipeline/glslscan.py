"""Lightweight lexical analysis of GLSL source (no parser, heuristics only).

Shared by the Shadertoy portability classifier (Phase 1) and the validator's
performance budget check (Phase 4). Everything here works on plain text and is
intentionally forgiving: shaders in the wild are messy, and the goal is a cheap
estimate, not a proof.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field

# Iterations assumed for loops whose bound cannot be resolved statically.
UNKNOWN_LOOP_ITERATIONS = 16

_BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)
_LINE_COMMENT_RE = re.compile(r"//[^\n]*")
_FETCH_RE = re.compile(r"\b(?:texture|textureLod|textureGrad|textureProj|texelFetch|texture2D)\s*\(")
_FUNC_DEF_RE = re.compile(
    r"(?:^|\n)[ \t]*(?:(?:highp|mediump|lowp|inline)\s+)?[A-Za-z_]\w*\s+([A-Za-z_]\w*)\s*\([^;{)]*\)\s*\{"
)
_DEFINE_RE = re.compile(r"^[ \t]*#define[ \t]+(\w+)[ \t]+\(?\s*([-+]?\d+(?:\.\d*)?)\s*\)?[ \t]*$", re.MULTILINE)
_CONST_RE = re.compile(r"\bconst\s+(?:int|float|uint)\s+(\w+)\s*=\s*([-+]?\d+(?:\.\d*)?)\s*[uU]?\s*;")
_RAYMARCH_CALL_RE = re.compile(
    r"\b(?:map|scene|sdf|sdScene|sceneSDF|de|DE|SDF|getDist|GetDist|getDistance|dist|march|raymarch)\s*\("
)
_RAYMARCH_STEP_RE = re.compile(r"\b\w+\s*\+=\s*(?:d|h|dist|dS|res\.x|ds|d\.x|h\.x)\b")


def strip_comments(code: str) -> str:
    """Remove comments, keeping line structure (block comments become blank lines)."""
    code = _BLOCK_COMMENT_RE.sub(lambda m: "\n" * m.group(0).count("\n"), code)
    return _LINE_COMMENT_RE.sub("", code)


def extract_comments(code: str) -> str:
    """Return only the comment text of ``code`` (license headers live there)."""
    parts = [m.group(0) for m in _BLOCK_COMMENT_RE.finditer(code)]
    parts += [m.group(0) for m in _LINE_COMMENT_RE.finditer(_BLOCK_COMMENT_RE.sub("", code))]
    return "\n".join(parts)


def count_fetches(code: str) -> int:
    return len(_FETCH_RE.findall(code))


def _match_close(code: str, open_idx: int, open_ch: str, close_ch: str) -> int:
    """Index of the bracket closing the one at ``open_idx`` (or len(code) if unbalanced)."""
    depth = 0
    for i in range(open_idx, len(code)):
        ch = code[i]
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return i
    return len(code)


def constants(code: str) -> dict[str, float]:
    """Numeric ``#define`` and ``const`` values usable as loop bounds."""
    values: dict[str, float] = {}
    for name, value in _DEFINE_RE.findall(code):
        values[name] = float(value)
    for name, value in _CONST_RE.findall(code):
        values[name] = float(value)
    return values


def function_bodies(code: str) -> dict[str, str]:
    """Map of top-level function name -> body text (first definition wins)."""
    bodies: dict[str, str] = {}
    for m in _FUNC_DEF_RE.finditer(code):
        name = m.group(1)
        if name in {"if", "for", "while", "switch", "return"}:
            continue
        open_idx = m.end() - 1
        close_idx = _match_close(code, open_idx, "{", "}")
        bodies.setdefault(name, code[open_idx + 1 : close_idx])
    return bodies


@dataclass
class LoopInfo:
    header: str
    start: int
    end: int
    iterations: int | None  # None = could not be resolved statically
    depth: int = 1
    direct_fetches: int = 0
    cost: int = 0  # iterations x (fetches in body incl. nested loops / called functions)
    is_raymarch: bool = False
    children: list[LoopInfo] = field(default_factory=list)

    @property
    def effective_iterations(self) -> int:
        return self.iterations if self.iterations is not None else UNKNOWN_LOOP_ITERATIONS


_NUM = r"[-+]?\d+(?:\.\d*)?|[-+]?\.\d+"


def _resolve(token: str, consts: dict[str, float]) -> float | None:
    token = token.strip().rstrip("uU").strip("()")
    if re.fullmatch(_NUM, token):
        return float(token)
    if token in consts:
        return consts[token]
    m = re.fullmatch(r"(\w+)\s*([*/+-])\s*(" + _NUM + r"|\w+)", token)
    if m:
        a, op, b = _resolve(m.group(1), consts), m.group(2), _resolve(m.group(3), consts)
        if a is not None and b is not None:
            return {"*": a * b, "/": a / b if b else None, "+": a + b, "-": a - b}[op]
    return None


def _loop_iterations(header: str, consts: dict[str, float]) -> int | None:
    parts = header.split(";")
    if len(parts) != 3:
        return None
    init, cond, step = (p.strip() for p in parts)
    m_init = re.search(r"(\w+)\s*=\s*([^,]+)$", init)
    m_cond = re.fullmatch(r"(\w+)\s*(<=|<|>=|>)\s*(.+)", cond)
    if not m_init or not m_cond:
        return None
    start = _resolve(m_init.group(2), consts)
    bound = _resolve(m_cond.group(3), consts)
    if start is None or bound is None:
        return None
    step_val: float | None = 1.0
    if re.search(r"(\+\+|--)", step):
        step_val = 1.0
    else:
        m_step = re.search(r"[+-]=\s*(.+)$", step)
        step_val = _resolve(m_step.group(1), consts) if m_step else None
    if not step_val:
        return None
    span = abs(bound - start)
    if m_cond.group(2) in ("<=", ">="):
        span += step_val
    return max(0, int(round(span / abs(step_val))))


def find_loops(code: str) -> list[LoopInfo]:
    """All ``for``/``while`` loops (flat list, nesting resolved via ``depth``/``children``)."""
    code = strip_comments(code)
    consts = constants(code)
    funcs = function_bodies(code)
    func_fetches = {name: count_fetches(body) for name, body in funcs.items()}

    loops: list[LoopInfo] = []
    for m in re.finditer(r"\b(for|while)\s*\(", code):
        paren_open = m.end() - 1
        paren_close = _match_close(code, paren_open, "(", ")")
        header = code[paren_open + 1 : paren_close]
        i = paren_close + 1
        while i < len(code) and code[i].isspace():
            i += 1
        if i < len(code) and code[i] == "{":
            end = _match_close(code, i, "{", "}")
        else:
            end = code.find(";", i)
            end = len(code) if end < 0 else end
        iterations = _loop_iterations(header, consts) if m.group(1) == "for" else None
        loops.append(LoopInfo(header=header.strip(), start=m.start(), end=end, iterations=iterations))

    # nesting
    for loop in loops:
        parents = [p for p in loops if p is not loop and p.start < loop.start and loop.end <= p.end]
        loop.depth = 1 + len(parents)
        if parents:
            direct_parent = max(parents, key=lambda p: p.start)
            direct_parent.children.append(loop)

    # cost, innermost first
    for loop in sorted(loops, key=lambda lp: -lp.depth):
        body = code[loop.start : loop.end + 1]
        nested_spans = [(c.start, c.end) for c in loop.children]
        own = body
        for s, e in sorted(nested_spans, reverse=True):
            own = own[: s - loop.start] + own[e - loop.start + 1 :]
        calls = re.findall(r"\b([A-Za-z_]\w*)\s*\(", own)
        called_fetches = sum(func_fetches.get(name, 0) for name in calls if name in func_fetches)
        loop.direct_fetches = count_fetches(own) + called_fetches
        loop.cost = loop.effective_iterations * (loop.direct_fetches + sum(c.cost for c in loop.children))
        loop.is_raymarch = bool(_RAYMARCH_CALL_RE.search(own) and (_RAYMARCH_STEP_RE.search(own) or "break" in own))
    return loops


def loop_summary(code: str) -> dict:
    """Aggregate numbers used by the portability score and the perf budget."""
    loops = find_loops(code)
    top = [lp for lp in loops if lp.depth == 1]
    marches = [lp for lp in loops if lp.is_raymarch]
    return {
        "loop_count": len(loops),
        "max_depth": max((lp.depth for lp in loops), default=0),
        "fetch_cost": sum(lp.cost for lp in top),
        "unknown_bounds": sum(1 for lp in loops if lp.iterations is None),
        "max_iterations": max((lp.effective_iterations for lp in loops), default=0),
        "raymarch_steps": max((lp.effective_iterations for lp in marches), default=0),
    }
