"""Shared offline test fixtures.

No network, no live LLM, no embedding-model download. The Spark endpoint in
config.py is a LAN address that does not resolve in CI, so every test that
would touch an LLM uses the `fake_llm` fixture instead.
"""

import sys
import types
from pathlib import Path

import pytest

PIPELINE_DIR = Path(__file__).resolve().parent.parent
if str(PIPELINE_DIR) not in sys.path:
    sys.path.insert(0, str(PIPELINE_DIR))

FIXTURES = Path(__file__).parent / "fixtures"

# A minimal mirror_filter.dart carrying exactly the five integrator sentinels.
DART_TEMPLATE = """enum MirrorFilter {
  none,
  pencil,
  // >>> generated-filters-enum <<<
  ;

  String get label => switch (this) {
        MirrorFilter.none => 'None',
        MirrorFilter.pencil => 'Pencil',
        // >>> generated-filters-label <<<
      };

  String get icon => switch (this) {
        MirrorFilter.none => 'O',
        MirrorFilter.pencil => '/',
        // >>> generated-filters-icon <<<
      };

  bool get needsTime => switch (this) {
        // >>> generated-filters-needstime <<<
        _ => false,
      };

  String? get shaderAsset => switch (this) {
        MirrorFilter.none => null,
        MirrorFilter.pencil => 'shaders/filter_pencil.frag',
        // >>> generated-filters-shaderasset <<<
      };
}
"""

PUBSPEC_TEMPLATE = """name: mirrorbooth
flutter:
  uses-material-design: true
  shaders:
    - shaders/mirror.frag
    - shaders/filter_pencil.frag
"""


class _FakeTree:
    def __init__(self, root: Path):
        self.root = root
        self.shaders_dir = root / "mirrorbooth" / "shaders"
        self.pubspec = root / "mirrorbooth" / "pubspec.yaml"
        self.dart = root / "mirrorbooth" / "lib" / "core" / "mirror_filter.dart"


@pytest.fixture
def fake_flutter_tree(tmp_path) -> _FakeTree:
    t = _FakeTree(tmp_path)
    t.shaders_dir.mkdir(parents=True)
    (t.shaders_dir / "mirror.frag").write_text("// mirror\n")
    (t.shaders_dir / "filter_pencil.frag").write_text("// pencil\n")
    t.pubspec.write_text(PUBSPEC_TEMPLATE)
    t.dart.parent.mkdir(parents=True)
    t.dart.write_text(DART_TEMPLATE)
    return t


def _canned(system_text: str) -> str:
    if "technical specification as JSON" in system_text:
        return (
            '{"effect_name":"Test FX","techniques":["noise","hue_rotation"],'
            '"uniforms":["uTexture","uResolution"],"needs_time":false,'
            '"description":"a deterministic test effect"}'
        )
    if "GLSL shader developer" in system_text or "compilable GLSL" in system_text:
        return (
            "#include <flutter/runtime_effect.glsl>\n"
            "uniform sampler2D uTexture;\n"
            "uniform vec2 uResolution;\n"
            "out vec4 fragColor;\n"
            "void main() {\n"
            "  vec2 uv = FlutterFragCoord().xy / uResolution;\n"
            "  vec3 col = texture(uTexture, uv).rgb;\n"
            "  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);\n"
            "}\n"
        )
    if "GLSL code reviewer" in system_text:
        return (
            '{"scores":{"correctness":9,"creativity":7,'
            '"mobile_optimization":8,"flutter_compliance":10},'
            '"overall":8.5,"explanation":"clean and compliant"}'
        )
    return "{}"


class _FakeLLM:
    def __init__(self, *a, **k):
        pass

    def invoke(self, messages):
        system_text = messages[0].content if messages else ""
        return types.SimpleNamespace(content=_canned(system_text))


@pytest.fixture
def fake_llm(monkeypatch):
    """Replace ChatOpenAI in every agent that calls it with a canned responder."""
    import agents.style_architect as sa
    import agents.glsl_coder as gc
    import agents.ranker as rk

    for mod in (sa, gc, rk):
        monkeypatch.setattr(mod, "ChatOpenAI", _FakeLLM)
    return _FakeLLM
