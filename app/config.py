"""Centralised configuration for PathfinderLM.

All settings are read from environment variables (loaded from a ``.env`` file via
python-dotenv when present), with the documented defaults. Non-secret defaults may
also be supplied via ``configs/config.yaml``.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Any, Dict

try:  # python-dotenv is optional at runtime
    from dotenv import load_dotenv

    load_dotenv()
except Exception:  # pragma: no cover - dotenv is a convenience only
    pass


def _yaml_defaults() -> Dict[str, Any]:
    """Load non-secret defaults from configs/config.yaml if available."""
    path = os.getenv("CONFIG_FILE", "configs/config.yaml")
    if not os.path.exists(path):
        return {}
    try:
        import yaml  # local import keeps yaml optional

        with open(path, "r", encoding="utf-8") as handle:
            return yaml.safe_load(handle) or {}
    except Exception:  # pragma: no cover - defaults are best-effort
        return {}


_DEFAULTS = _yaml_defaults()

# Default coaching persona, applied via Ollama's ``system`` role. Mirrors the
# SYSTEM block in the repo-root Modelfile; override with the SYSTEM_PROMPT env var
# or by building and selecting the ``pathfinder-coach`` model.
DEFAULT_SYSTEM_PROMPT = (
    "You are PathfinderLM, an empathetic, evidence-based life coach. "
    "Help the user set goals and take small, achievable next steps. Be warm, "
    "concise, and practical. Ground your advice in the provided context when it "
    "is relevant. You are not a medical or mental-health professional: for crises "
    "or clinical concerns, encourage the user to contact a licensed professional "
    "or emergency services."
)


def _get(name: str, fallback: str) -> str:
    """Env var > config.yaml > hard-coded fallback."""
    return os.getenv(name, str(_DEFAULTS.get(name.lower(), fallback)))


@dataclass
class Config:
    """Runtime configuration resolved from the environment."""

    flask_env: str = field(default_factory=lambda: _get("FLASK_ENV", "production"))
    flask_port: int = field(default_factory=lambda: int(_get("FLASK_PORT", "5000")))
    secret_key: str = field(default_factory=lambda: _get("SECRET_KEY", "dev-insecure-key"))

    llm_provider: str = field(default_factory=lambda: _get("LLM_PROVIDER", "ollama"))
    ollama_host: str = field(default_factory=lambda: _get("OLLAMA_HOST", "http://localhost:11434"))
    model_name: str = field(default_factory=lambda: _get("MODEL_NAME", "deepseek-r1:14b"))
    embedding_model: str = field(default_factory=lambda: _get("EMBEDDING_MODEL", "nomic-embed-text"))
    openai_api_key: str = field(default_factory=lambda: _get("OPENAI_API_KEY", ""))

    faiss_index_path: str = field(default_factory=lambda: _get("FAISS_INDEX_PATH", "results/faiss.index"))
    knowledge_base_dir: str = field(default_factory=lambda: _get("KNOWLEDGE_BASE_DIR", "data/processed"))
    top_k: int = field(default_factory=lambda: int(_get("TOP_K", "5")))

    device: str = field(default_factory=lambda: _get("DEVICE", "auto"))
    log_level: str = field(default_factory=lambda: _get("LOG_LEVEL", "INFO"))

    system_prompt: str = field(default_factory=lambda: _get("SYSTEM_PROMPT", DEFAULT_SYSTEM_PROMPT))

    @property
    def debug(self) -> bool:
        return self.flask_env.lower() == "development"


def get_config() -> Config:
    """Return a freshly resolved configuration (re-reads the environment)."""
    return Config()
