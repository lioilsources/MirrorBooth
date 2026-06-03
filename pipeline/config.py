from pydantic_settings import BaseSettings, SettingsConfigDict
from pathlib import Path

PIPELINE_DIR = Path(__file__).parent
PROJECT_ROOT = PIPELINE_DIR.parent
SHADERS_DIR = PROJECT_ROOT / "mirrorbooth" / "shaders"
SEED_SHADERS_DIR = PIPELINE_DIR / "seed_shaders"
RAG_DB_DIR = PIPELINE_DIR / "rag" / "db"
OUTPUT_DIR = PIPELINE_DIR / "output"
FLUTTER_APP_DIR = PROJECT_ROOT / "mirrorbooth"
PUBSPEC_PATH = FLUTTER_APP_DIR / "pubspec.yaml"
MIRROR_FILTER_DART = FLUTTER_APP_DIR / "lib" / "core" / "mirror_filter.dart"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=PIPELINE_DIR / ".env", env_file_encoding="utf-8")

    spark_base_url: str = "http://192.168.88.66:8000/v1"
    spark_model: str = "llama3"
    spark_api_key: str = "dummy"

    embedding_model: str = "sentence-transformers/all-MiniLM-L6-v2"
    rag_top_k: int = 5
    max_retries: int = 3

    auto_install: bool = True
    min_install_score: float = 7.0


settings = Settings()
