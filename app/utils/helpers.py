"""Small shared helpers (logging setup, env coercion)."""

from __future__ import annotations

import logging
import os


def setup_logging(level: str = "INFO") -> logging.Logger:
    """Configure root logging once and return the application logger."""
    numeric = getattr(logging, str(level).upper(), logging.INFO)
    logging.basicConfig(
        level=numeric,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    return logging.getLogger("pathfinderlm")


def env_bool(name: str, default: bool = False) -> bool:
    """Read a boolean-ish environment variable."""
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}
