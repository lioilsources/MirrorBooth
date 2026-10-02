"""
ShaderGen pipeline — CLI entrypoint.

Usage:
    python run.py --style "oil painting warm palette" --name "oil_warm"
    python run.py --style "glitch RGB shift animated" --name "glitch_v2"
"""

import argparse
import json
from datetime import datetime

from config import OUTPUT_DIR
from graph import build_graph
from state import ShaderGenState, initial_state


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Generate a GLSL shader via LangGraph agents")
    parser.add_argument("--style", required=True, help="Natural language description of the desired filter effect")
    parser.add_argument("--name", required=True, help="Short snake_case name for the output shader (e.g. oil_warm)")
    args = parser.parse_args(argv)

    shader_name = args.name.strip().replace(" ", "_").lower()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = OUTPUT_DIR / f"filter_{shader_name}_{timestamp}"
    run_dir.mkdir(parents=True, exist_ok=True)

    state = initial_state(args.style)

    print(f"\n[ShaderGen] Style: {args.style!r}")
    print(f"[ShaderGen] Output: {run_dir}\n")

    graph = build_graph()
    final_state: ShaderGenState = graph.invoke(state)

    # --- save outputs ---
    frag_path = run_dir / f"filter_{shader_name}.frag"
    frag_path.write_text(final_state["glsl_code"], encoding="utf-8")

    tech_spec_path = run_dir / "tech_spec.json"
    tech_spec_path.write_text(json.dumps(final_state["tech_spec"], indent=2, ensure_ascii=False), encoding="utf-8")

    rank_path = run_dir / "rank_report.json"
    rank_path.write_text(json.dumps(final_state["rank_report"], indent=2, ensure_ascii=False), encoding="utf-8")

    passed = bool(final_state.get("validation_passed", False))
    val_errors = final_state.get("validation_errors", [])
    validation_path = run_dir / "validation.json"
    validation_path.write_text(
        json.dumps(
            {
                "validation_passed": passed,
                "validation_errors": val_errors,
                "retry_count": final_state.get("retry_count", 0),
            },
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    if not passed:
        (run_dir / "FAILED").write_text(
            "Shader did not pass validation after the maximum number of retries.\n"
            + "\n".join(f"- {e}" for e in val_errors)
            + "\n",
            encoding="utf-8",
        )

    # --- summary ---
    rank = final_state.get("rank_report", {})
    overall = rank.get("overall", "n/a")
    explanation = rank.get("explanation", "")
    retries = final_state.get("retry_count", 0)

    print("\n" + "=" * 60)
    print(f"  Status:    {'PASSED' if passed else 'FAILED (validation did not pass — do not integrate)'}")
    print(f"  Shader:    {frag_path}")
    print(f"  Overall:   {overall}/10")
    print(f"  Retries:   {retries}")
    if val_errors:
        print(f"  Errors:    {'; '.join(val_errors)}")
    if explanation:
        print(f"  Judge:     {explanation}")
    print("=" * 60)
    if passed:
        print(
            f"\nNext step: copy {frag_path.name} to mirrorbooth/shaders/ "
            "and register in pubspec.yaml + mirror_filter.dart"
        )
        return 0
    print(f"\n[ShaderGen] FAILED — see {validation_path}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
