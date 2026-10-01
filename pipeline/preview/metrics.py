"""Cheap image metrics over headless renders + hard thresholds."""

from __future__ import annotations

from dataclasses import asdict, dataclass

BLACK_LEVEL = 8  # max channel value (0-255) still counted as black
IDENTICAL_TOLERANCE = 2  # per-channel difference still counted as unchanged
MAX_BLACK_RATIO = 0.30
MAX_IDENTICAL_RATIO = 0.98
MIN_ANIMATION_DIFF = 0.002  # mean abs difference between first and last frame (0..1)


@dataclass
class FrameMetrics:
    black_ratio: float
    identical_ratio: float
    mean_luminance: float
    mean_saturation: float


def frame_metrics(frame, image) -> FrameMetrics:
    import numpy as np

    f = frame.astype(np.float32)
    black = (frame.max(axis=2) <= BLACK_LEVEL).mean()
    identical = (np.abs(f - image.astype(np.float32)).max(axis=2) <= IDENTICAL_TOLERANCE).mean()
    rgb = f / 255.0
    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    mx, mn = rgb.max(axis=2), rgb.min(axis=2)
    sat = np.where(mx > 1e-4, (mx - mn) / np.maximum(mx, 1e-4), 0.0)
    return FrameMetrics(float(black), float(identical), float(lum.mean()), float(sat.mean()))


def evaluate(result, needs_time: bool) -> tuple[dict, list[str], list[str]]:
    """Return (metrics dict, errors, warnings) for a RenderResult."""
    import numpy as np

    per_frame = [frame_metrics(fr, result.input_image) for fr in result.frames]
    errors: list[str] = []
    warnings: list[str] = []
    worst_black = max(m.black_ratio for m in per_frame)
    most_identical = min(m.identical_ratio for m in per_frame)
    if worst_black > MAX_BLACK_RATIO:
        errors.append(f"Preview: {worst_black:.0%} of pixels are black/NaN (max {MAX_BLACK_RATIO:.0%})")
    if most_identical > MAX_IDENTICAL_RATIO:
        errors.append(f"Preview: {most_identical:.0%} of pixels equal the input — the shader does nothing visible")
    animation_diff = None
    if needs_time and len(result.frames) > 1:
        a, b = result.frames[0].astype(np.float32), result.frames[-1].astype(np.float32)
        animation_diff = float(np.abs(a - b).mean() / 255.0)
        if animation_diff < MIN_ANIMATION_DIFF:
            warnings.append("Preview: frames at different uTime look identical — animation has no visible effect")
    metrics = {
        "frames": [{"t": t, **asdict(m)} for t, m in zip(result.times, per_frame, strict=True)],
        "worst_black_ratio": worst_black,
        "max_identical_ratio": most_identical,
        "animation_diff": animation_diff,
        "render_ms": result.render_ms,
    }
    return metrics, errors, warnings
