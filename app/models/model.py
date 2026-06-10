"""Ollama client helpers shared across the application."""

from __future__ import annotations

import os
from typing import Optional

from ollama import Client


def get_client(host: Optional[str] = None) -> Client:
    """Return an Ollama client bound to ``OLLAMA_HOST`` (or the given host)."""
    return Client(host=host or os.getenv("OLLAMA_HOST", "http://localhost:11434"))


DEFAULT_MODEL = os.getenv("MODEL_NAME", "deepseek-r1:14b")
