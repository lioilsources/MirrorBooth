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

import integrator
from config import OUTPUT_DIR, settings
from graph import build_graph
from state import ShaderGenState


def main():
    parser = argparse.ArgumentParser(description="Generate a GLSL shader via LangGraph agents")
    parser.add_argument("--style", required=True, help="Natural language description of the desired filter effect")
    parser.add_argument("--name", required=True, help="Short snake_case name for the output shader (e.g. oil_warm)")
    parser.add_argument("--no-install", action="store_true",
                        help="Generate only; do not register the shader in the Flutter app")
    parser.add_argument("--min-install-score", type=float, default=settings.min_install_score,
                        help=f"Minimum ranker overall score to auto-install (default {settings.min_install_score})")
    args = parser.parse_args()

    shader_name = args.name.strip().replace(" ", "_").lower()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    run_dir = OUTPUT_DIR / f"filter_{shader_name}_{timestamp}"
    run_dir.mkdir(parents=True, exist_ok=True)

    initial_state: ShaderGenState = {
        "style_prompt": args.style,
        "tech_spec": {},
        "rag_context": [],
        "port_reference": "",
        "port_techniques": [],
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

    # --- auto-integration into the Flutter app ---
    try:
        overall_num = float(overall)
    except (TypeError, ValueError):
        overall_num = 0.0

    do_install = settings.auto_install and not args.no_install
    if not do_install:
        print(f"\nSkipped install (--no-install). To register manually: copy "
              f"{frag_path.name} to mirrorbooth/shaders/ and add it to "
              f"pubspec.yaml + mirror_filter.dart")
        return

    if overall_num < args.min_install_score:
        print(f"\nSkipped install: score {overall_num} < threshold "
              f"{args.min_install_score}. Re-run or lower --min-install-score "
              f"to register {frag_path.name}.")
        return

    try:
        report = integrator.install(frag_path, shader_name, final_state["tech_spec"])
    except integrator.IntegrationError as e:
        print(f"\nInstall FAILED: {e}\nOutputs are saved in {run_dir}.")
        sys.exit(1)

    (run_dir / "install_report.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"\nInstalled as MirrorFilter.{report['enum_name']} "
          f"(label '{report['label']}', icon '{report['icon']}')")
    if report["already_installed"]:
        print("  (already present — no changes needed)")
    for f in report["files_changed"]:
        print(f"  changed: {f}")
    print("\nRebuild the Flutter app to pick up the new filter "
          "(flutter pub get && flutter run).")


if __name__ == "__main__":
    main()
