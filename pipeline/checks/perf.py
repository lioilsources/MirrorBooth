"""Mobile GPU performance budget (heuristic, limits in config.py)."""

from __future__ import annotations

from config import Settings, settings
from glslscan import loop_summary


def check_perf(code: str, cfg: Settings | None = None) -> tuple[list[str], list[str], dict]:
    """Return (errors, warnings, summary)."""
    cfg = cfg or settings
    s = loop_summary(code)
    errors: list[str] = []
    warnings: list[str] = []
    if s["max_depth"] > cfg.perf_max_loop_depth:
        errors.append(f"Perf: loops nested {s['max_depth']} deep (max {cfg.perf_max_loop_depth})")
    if s["fetch_cost"] > cfg.perf_max_loop_fetch_budget:
        errors.append(
            f"Perf: ~{s['fetch_cost']} texture fetches in loops per pixel (budget {cfg.perf_max_loop_fetch_budget}); "
            "reduce taps or iterations"
        )
    steps = s["raymarch_steps"]
    if steps > cfg.perf_raymarch_max_steps:
        errors.append(f"Perf: raymarch loop with {steps} steps (max {cfg.perf_raymarch_max_steps})")
    elif steps > cfg.perf_raymarch_warn_steps:
        warnings.append(f"Perf: raymarch loop with {steps} steps (warn above {cfg.perf_raymarch_warn_steps})")
    if s["unknown_bounds"]:
        warnings.append(f"Perf: {s['unknown_bounds']} loop(s) with non-constant bounds (cost estimated)")
    return errors, warnings, s
