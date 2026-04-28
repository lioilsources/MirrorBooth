"""
ShaderGen pipeline — CLI entrypoint.

Usage:
    python run.py --style "oil painting warm palette" --name "oil_warm"
    python run.py --style "glitch RGB shift animated" --name "glitch_v2"
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

from config import OUTPUT_DIR
from graph import build_graph
from state import ShaderGenState


def main():
    parser = argparse.ArgumentParser(description="Generate a GLSL shader via LangGraph agents")
    parser.add_argument("--style", required=True, help="Natural language description of the desired filter effect")
    parser.add_argument("--name", required=True, help="Short snake_case name for the output shader (e.g. oil_warm)")
    args = parser.parse_args()

    shader_name = args.name.strip().replace(" ", "_").lower()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = OUTPUT_DIR / f"filter_{shader_name}_{timestamp}"
    run_dir.mkdir(parents=True, exist_ok=True)

    initial_state: ShaderGenState = {
        "style_prompt": args.style,
        "tech_spec": {},
        "rag_context": [],
        "glsl_code": "",
        "validation_errors": [],
        "retry_count": 0,
        "rank_report": {},
        "output_path": "",
    }

    print(f"\n[ShaderGen] Style: {args.style!r}")
    print(f"[ShaderGen] Output: {run_dir}\n")

    graph = build_graph()
    final_state: ShaderGenState = graph.invoke(initial_state)

    # --- save outputs ---
    frag_path = run_dir / f"filter_{shader_name}.frag"
    frag_path.write_text(final_state["glsl_code"], encoding="utf-8")

    tech_spec_path = run_dir / "tech_spec.json"
    tech_spec_path.write_text(json.dumps(final_state["tech_spec"], indent=2, ensure_ascii=False), encoding="utf-8")

    rank_path = run_dir / "rank_report.json"
    rank_path.write_text(json.dumps(final_state["rank_report"], indent=2, ensure_ascii=False), encoding="utf-8")

    # --- summary ---
    rank = final_state.get("rank_report", {})
    overall = rank.get("overall", "n/a")
    explanation = rank.get("explanation", "")
    val_errors = final_state.get("validation_errors", [])
    retries = final_state.get("retry_count", 0)

    print("\n" + "=" * 60)
    print(f"  Shader:    {frag_path}")
    print(f"  Overall:   {overall}/10")
    print(f"  Retries:   {retries}")
    if val_errors:
        print(f"  Warnings:  {'; '.join(val_errors)}")
    if explanation:
        print(f"  Judge:     {explanation}")
    print("=" * 60)
    print(f"\nNext step: copy {frag_path.name} to mirrorbooth/shaders/ and register in pubspec.yaml + mirror_filter.dart")


if __name__ == "__main__":
    main()
