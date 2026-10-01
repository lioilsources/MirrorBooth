"""
ShaderGen pipeline — CLI entrypoint.

Usage:
    # inspire mode: new shader from a style prompt (RAG incl. Shadertoy snippets)
    python run.py --style "oil painting warm palette" --name "oil_warm"

    # port mode: deterministic port of a permissively licensed Shadertoy shader
    python run.py --from-shadertoy XsX3zB --name hologram [--blend multiply]
"""

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime
from pathlib import Path

from config import OUTPUT_DIR
from shadertoy.transpile import BLEND_MODES, TranspileError
from state import ShaderGenState, initial_state


def slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", text.strip().lower()).strip("_")
    return slug or "shader"


def _write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _preflight_port(shader_id: str, blend: str | None, allow_nc: bool) -> tuple[str | None, str]:
    """Fetch + check the shader before starting the graph. Returns (error, shader name)."""
    from agents.transpiler import load_source_shader
    from shadertoy.client import ShadertoyError
    from shadertoy.transpile import transpile

    try:
        shader = load_source_shader(shader_id)
        transpile(shader, blend_mode=blend, allow_nc_license=allow_nc)
    except (ShadertoyError, TranspileError) as exc:
        return str(exc), ""
    return None, shader.info.name


def save_outputs(final_state: ShaderGenState, run_dir: Path, shader_name: str) -> tuple[Path, bool]:
    frag_path = run_dir / f"filter_{shader_name}.frag"
    frag_path.write_text(final_state["glsl_code"], encoding="utf-8")
    _write_json(run_dir / "tech_spec.json", final_state["tech_spec"])
    _write_json(run_dir / "rank_report.json", final_state["rank_report"])

    passed = bool(final_state.get("validation_passed", False))
    val_errors = final_state.get("validation_errors", [])
    _write_json(
        run_dir / "validation.json",
        {
            "validation_passed": passed,
            "validation_errors": val_errors,
            "retry_count": final_state.get("retry_count", 0),
            "compile": final_state.get("provenance", {}).get("compile", {}),
        },
    )

    source = final_state.get("source", {})
    provenance = dict(final_state.get("provenance", {}))
    if source.get("kind") != "shadertoy":
        provenance = {
            **provenance,
            "source": {"kind": "style", "style_prompt": final_state.get("style_prompt", "")},
            # generated from scratch: no third-party code; RAG snippets are attributed in the prompt only
            "license_ok": True,
            "license": "original (generated)",
            "category": final_state.get("category", ""),
        }
    provenance.update(
        {
            "shader_name": shader_name,
            "frag": frag_path.name,
            "needs_time": final_state.get("needs_time", False),
            "needs_face": final_state.get("needs_face", False),
            "validation_passed": passed,
            "generated": datetime.now().isoformat(timespec="seconds"),
        }
    )
    _write_json(run_dir / "provenance.json", provenance)

    if not passed:
        (run_dir / "FAILED").write_text(
            "Shader did not pass validation after the maximum number of retries.\n"
            + "\n".join(f"- {e}" for e in val_errors)
            + "\n",
            encoding="utf-8",
        )
    return frag_path, passed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Generate a MirrorBooth GLSL filter via LangGraph agents")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--style", help="inspire mode: natural language description of the desired filter effect")
    mode.add_argument("--from-shadertoy", metavar="ID", help="port mode: Shadertoy shader id (permissive license only)")
    parser.add_argument("--name", help="short snake_case name for the output shader (e.g. oil_warm)")
    parser.add_argument("--blend", choices=sorted(BLEND_MODES), help="port mode, procedural shaders: blend with camera")
    parser.add_argument(
        "--i-accept-nc-license",
        action="store_true",
        help="port a non-permissive shader for a LOCAL experiment only (license_ok=false, integrate.py refuses it)",
    )
    args = parser.parse_args(argv)

    if args.style is not None and not args.name:
        parser.error("--name is required with --style")

    if args.from_shadertoy:
        error, st_name = _preflight_port(args.from_shadertoy, args.blend, args.i_accept_nc_license)
        if error:
            print(f"\n[ShaderGen] Cannot port {args.from_shadertoy}:\n  {error}")
            return 2
        if args.i_accept_nc_license:
            print("[ShaderGen] WARNING: --i-accept-nc-license — output is for local experiments only and cannot ship.")
        shader_name = slugify(args.name or st_name)
        source = {
            "kind": "shadertoy",
            "id": args.from_shadertoy,
            "license": "",
            "blend": args.blend or "",
            "allow_nc_license": bool(args.i_accept_nc_license),
        }
        state = initial_state(f"port of shadertoy/{args.from_shadertoy}", source)
        label = f"Shadertoy {args.from_shadertoy} ({st_name})"
    else:
        shader_name = slugify(args.name)
        state = initial_state(args.style)
        label = repr(args.style)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = OUTPUT_DIR / f"filter_{shader_name}_{timestamp}"
    run_dir.mkdir(parents=True, exist_ok=True)
    state["output_path"] = str(run_dir)

    print(f"\n[ShaderGen] Source: {label}")
    print(f"[ShaderGen] Output: {run_dir}\n")

    from graph import build_graph

    final_state: ShaderGenState = build_graph().invoke(state)
    frag_path, passed = save_outputs(final_state, run_dir, shader_name)

    # --- summary ---
    rank = final_state.get("rank_report", {})
    val_errors = final_state.get("validation_errors", [])
    print("\n" + "=" * 60)
    print(f"  Status:    {'PASSED' if passed else 'FAILED (validation did not pass — do not integrate)'}")
    print(f"  Shader:    {frag_path}")
    print(f"  Overall:   {rank.get('overall', 'n/a')}/10")
    print(f"  Retries:   {final_state.get('retry_count', 0)}")
    if final_state.get("provenance", {}).get("fixer_rounds"):
        print(f"  Fixer:     {len(final_state['provenance']['fixer_rounds'])} round(s), see fixer_diff.patch")
    compile_info = final_state.get("provenance", {}).get("compile", {})
    if compile_info.get("impeller_verified"):
        print("  Compile:   impellerc OK (Metal, GLES, GLES3, Vulkan, SkSL)")
    else:
        print(f"  Compile:   !!! NOT verified by impellerc (backend: {compile_info.get('backend', 'none')}) !!!")
    if val_errors:
        print(f"  Errors:    {'; '.join(val_errors)}")
    if rank.get("explanation"):
        print(f"  Judge:     {rank['explanation']}")
    print("=" * 60)
    if passed:
        print(
            f"\nNext step: copy {frag_path.name} to mirrorbooth/shaders/ "
            "and register in pubspec.yaml + mirror_filter.dart"
        )
        return 0
    print(f"\n[ShaderGen] FAILED — see {run_dir / 'validation.json'}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
