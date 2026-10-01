"""Validator v2: contract regexes -> perf budget -> impellerc compilation.

Port mode (source.kind == "shadertoy") checks the uniforms strictly against the
transpiler's needs_time/needs_face. Inspire mode derives both flags from the
uniforms the coder declared (they must still form a contract shape) so the
state always describes the code that will be integrated.
"""

from checks.compile import compile_shader
from checks.contract import check_contract, uniform_shape
from checks.perf import check_perf
from state import ShaderGenState

UNRESOLVED_PREFIX = "Unresolved port fix: "


def validator_node(state: ShaderGenState) -> ShaderGenState:
    code = state.get("glsl_code", "")
    is_port = state.get("source", {}).get("kind") == "shadertoy"
    needs_time = state.get("needs_time", False)
    needs_face = state.get("needs_face", False)

    if is_port:
        errors = check_contract(code, needs_time, needs_face)
    else:
        errors = check_contract(code)
        shape = uniform_shape(code)
        if shape:
            needs_time, needs_face = shape

    perf_errors, warnings, perf_summary = check_perf(code)
    errors += perf_errors

    compile_info: dict = {}
    if code.strip():
        result = compile_shader(code)
        errors += result.errors
        warnings += result.warnings
        compile_info = result.to_dict()
        for w in result.warnings:
            print(f"[validator] {w}")

    # port mode: constructs the transpiler could not convert keep the run from passing
    errors.extend(f"{UNRESOLVED_PREFIX}{fix}" for fix in state.get("fixes_needed", []))

    provenance = {
        **state.get("provenance", {}),
        "compile": compile_info,
        "perf": perf_summary,
        "validation_warnings": warnings,
    }
    # `retry_count` counts failed validations; the graph stops retrying once it reaches
    # settings.max_retries, so a run can end with invalid code. `validation_passed`
    # is the explicit flag run.py uses to mark such a run FAILED.
    return {
        **state,
        "needs_time": needs_time,
        "needs_face": needs_face,
        "validation_errors": errors,
        "validation_passed": not errors,
        "retry_count": state.get("retry_count", 0) + (1 if errors else 0),
        "provenance": provenance,
    }
