from state import ShaderGenState, initial_state


def test_initial_state_has_all_fields():
    s = initial_state("neon glow")
    assert set(s) == set(ShaderGenState.__annotations__)
    assert s["style_prompt"] == "neon glow"
    assert s["source"]["kind"] == "style"
    assert s["validation_passed"] is False
    assert s["needs_time"] is False and s["needs_face"] is False
    assert s["preview_paths"] == [] and s["provenance"] == {}


def test_initial_state_custom_source():
    src = {"kind": "shadertoy", "id": "XsXXDn", "license": "MIT", "permissive": True}
    s = initial_state("", source=src)
    assert s["source"] == src
