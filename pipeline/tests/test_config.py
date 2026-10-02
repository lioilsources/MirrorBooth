import pytest

from config import DEFAULT_GATEWAY_URL, Settings

ENV_VARS = [
    "LLM_PROVIDER",
    "LLM_PROVIDER_VISION",
    "SPARK_BASE_URL",
    "SPARK_MODEL",
    "SPARK_API_KEY",
    "SPARK_VISION_BASE_URL",
    "SPARK_VISION_MODEL",
    "SPARK_VISION_API_KEY",
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_MODEL",
    "SHADERTOY_API_KEY",
    "FLUTTER_ROOT",
    "PREVIEW_ENABLED",
]


@pytest.fixture
def clean_env(monkeypatch):
    for var in ENV_VARS:
        monkeypatch.delenv(var, raising=False)


def test_defaults_point_to_litellm_gateway(clean_env):
    s = Settings(_env_file=None)
    assert s.spark_base_url == "http://192.168.88.66:8080/v1" == DEFAULT_GATEWAY_URL
    assert s.spark_model == "translate"
    assert s.spark_api_key == "dummy"
    assert s.spark_vision_base_url == DEFAULT_GATEWAY_URL
    assert s.spark_vision_model == "vl"
    assert s.llm_provider == "spark"
    assert s.llm_provider_vision is None
    assert s.anthropic_model == "claude-opus-5"
    assert s.shadertoy_api_key == ""
    assert s.flutter_root == ""
    assert s.preview_enabled is True


def test_perf_limits_defaults(clean_env):
    s = Settings(_env_file=None)
    assert s.perf_max_loop_fetch_budget == 64
    assert s.perf_max_loop_depth == 2
    assert s.perf_raymarch_warn_steps == 48
    assert s.perf_raymarch_max_steps == 96


def test_env_overrides(clean_env, monkeypatch):
    monkeypatch.setenv("SPARK_MODEL", "bench-qwen36")
    monkeypatch.setenv("SPARK_API_KEY", "sk-gateway")
    monkeypatch.setenv("LLM_PROVIDER_VISION", "anthropic")
    monkeypatch.setenv("SHADERTOY_API_KEY", "abc123")
    monkeypatch.setenv("FLUTTER_ROOT", "/opt/flutter")
    monkeypatch.setenv("PREVIEW_ENABLED", "false")
    s = Settings(_env_file=None)
    assert s.spark_model == "bench-qwen36"
    assert s.spark_api_key == "sk-gateway"
    assert s.llm_provider_vision == "anthropic"
    assert s.shadertoy_api_key == "abc123"
    assert s.flutter_root == "/opt/flutter"
    assert s.preview_enabled is False


def test_invalid_provider_rejected(clean_env, monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openai")
    with pytest.raises(ValueError):
        Settings(_env_file=None)


def test_env_example_documents_all_keys():
    from config import PIPELINE_DIR

    text = (PIPELINE_DIR / ".env.example").read_text()
    for key in [
        "SPARK_BASE_URL=http://192.168.88.66:8080/v1",
        "SPARK_MODEL=translate",
        "SPARK_API_KEY",
        "SPARK_VISION_BASE_URL",
        "SPARK_VISION_MODEL=vl",
        "SHADERTOY_API_KEY",
        "FLUTTER_ROOT",
        "LLM_PROVIDER",
        "ANTHROPIC_API_KEY",
    ]:
        assert key in text, key
