"""Headless preview node: render the validated shader, gate on image metrics."""

from __future__ import annotations

import tempfile
import threading
from pathlib import Path

from config import settings
from state import ShaderGenState

# one GL context at a time: batch runs render from worker threads
_GL_LOCK = threading.Lock()


def preview_node(state: ShaderGenState) -> ShaderGenState:
    if not settings.preview_enabled or not state.get("validation_passed"):
        return state

    from preview.metrics import evaluate
    from preview.render import PreviewUnavailable, default_input, load_image, render, save_frames

    provenance = dict(state.get("provenance", {}))
    warnings = list(provenance.get("validation_warnings", []))
    try:
        input_path = default_input()
        with _GL_LOCK:
            result = render(state["glsl_code"], load_image(input_path), state["needs_time"], state["needs_face"])
    except PreviewUnavailable as exc:
        print(f"[preview] skipped: {exc}")
        return {**state, "provenance": {**provenance, "preview": {"skipped": str(exc)}}}
    except (ValueError, OSError) as exc:
        # impellerc already accepted the shader; desktop GL differences are not fatal
        print(f"[preview] WARNING: render failed: {exc}")
        warnings.append(f"Preview: render failed ({str(exc)[:200]})")
        return {**state, "provenance": {**provenance, "validation_warnings": warnings, "preview": {"failed": str(exc)}}}

    metrics, errors, metric_warnings = evaluate(result, state["needs_time"])
    out_dir = (
        Path(state["output_path"]) if state.get("output_path") else Path(tempfile.mkdtemp(prefix="shadergen_preview_"))
    )
    paths = save_frames(result, out_dir)
    provenance["preview"] = {**metrics, "input": input_path.name}
    provenance["validation_warnings"] = warnings + metric_warnings

    new_state = {**state, "preview_paths": paths, "provenance": provenance}
    if errors:
        new_state.update(
            {
                "validation_errors": errors,
                "validation_passed": False,
                "retry_count": state.get("retry_count", 0) + 1,
            }
        )
    return new_state
