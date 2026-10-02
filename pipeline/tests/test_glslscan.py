from glslscan import extract_comments, find_loops, loop_summary, strip_comments


def test_strip_and_extract_comments():
    code = "/* a\n b */ float x; // tail\nfloat y;"
    assert "tail" not in strip_comments(code)
    assert strip_comments(code).count("\n") == code.count("\n")
    assert "tail" in extract_comments(code) and "a\n b" in extract_comments(code)


def test_loop_iterations_resolve_defines_and_consts():
    code = """
#define STEPS 32
const int N = 8;
void f() {
    for (int i = 0; i < STEPS; i++) { }
    for (int j = 0; j <= N; j++) { }
    for (float t = 0.0; t < 1.0; t += 0.25) { }
}
"""
    its = [lp.iterations for lp in find_loops(code)]
    assert its == [32, 9, 4]


def test_nested_cost_and_depth():
    code = """
vec3 tap(vec2 uv) { return texture(uTexture, uv).rgb; }
void main() {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            c += tap(uv) + texture(uTexture, uv).rgb;
        }
    }
}
"""
    s = loop_summary(code)
    assert s["max_depth"] == 2
    assert s["fetch_cost"] == 4 * 4 * 2


def test_dynamic_bound_counts_as_unknown():
    s = loop_summary("void f(int n){ for (int i = 0; i < n; i++) { x += texture(t, uv).r; } }")
    assert s["unknown_bounds"] == 1


def test_raymarch_detection():
    code = "float map(vec3 p){return length(p)-1.;}\nvoid m(){ for(int i=0;i<100;i++){ float d = map(p); if(d<.001) break; t += d; } }"
    assert loop_summary(code)["raymarch_steps"] == 100
