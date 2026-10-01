from pathlib import Path
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict

PIPELINE_DIR = Path(__file__).parent
PROJECT_ROOT = PIPELINE_DIR.parent
SHADERS_DIR = PROJECT_ROOT / "mirrorbooth" / "shaders"
RAG_DB_DIR = PIPELINE_DIR / "rag" / "db"
OUTPUT_DIR = PIPELINE_DIR / "output"
SHADERTOY_CACHE_DIR = PIPELINE_DIR / "rag" / "shadertoy_cache"

LLMProvider = Literal["spark", "anthropic"]

# LiteLLM gateway on SPARK. ShaderGen window per the SPARK schedule: llm 17:00-01:00 with
# `openclaw-default` (qwen36, also vision) and `bench-nano` (Nano-30B); outside it no LLM is served.
DEFAULT_GATEWAY_URL = "http://192.168.88.66:8080/v1"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=PIPELINE_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # --- LLM: provider selection -------------------------------------------
    llm_provider: LLMProvider = "spark"
    # Provider for the `vision` role; None = same as llm_provider.
    llm_provider_vision: LLMProvider | None = None

    # --- LLM: SPARK (OpenAI-compatible LiteLLM gateway) ----------------------
    spark_base_url: str = DEFAULT_GATEWAY_URL
    # qwen36: 16 s/shader, 100 % B1 contract in the model benchmark; `bench-nano` is the faster alternative.
    spark_model: str = "openclaw-default"
    # LiteLLM expects `Authorization: Bearer <key>` — put the gateway key here.
    spark_api_key: str = "dummy"

    spark_vision_base_url: str = DEFAULT_GATEWAY_URL
    spark_vision_model: str = "openclaw-default"  # qwen36 sees images; the old `vl` alias is gone
    # None = reuse spark_api_key.
    spark_vision_api_key: str | None = None

    # --- LLM: Anthropic (optional) -----------------------------------------
    anthropic_api_key: str = ""
    anthropic_model: str = "claude-opus-5"
    anthropic_max_tokens: int = 16000

    # --- External tools / sources ------------------------------------------
    shadertoy_api_key: str = ""
    flutter_root: str = ""
    # SkSL = Skia fallback renderer on older Android devices; all shipped shaders compile for it.
    compile_require_sksl: bool = True

    # --- RAG -----------------------------------------------------------------
    embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"
    rag_top_k: int = 5

    # --- Graph ---------------------------------------------------------------
    max_retries: int = 3

    # --- Mobile GPU performance budget (validator heuristics, Phase 4) -------
    perf_max_loop_fetch_budget: int = 64  # sum(loop iterations x texture fetches in body)
    perf_max_loop_depth: int = 2
    perf_raymarch_warn_steps: int = 48
    perf_raymarch_max_steps: int = 96

    # --- Headless preview (Phase 5) ------------------------------------------
    preview_enabled: bool = True


settings = Settings()
