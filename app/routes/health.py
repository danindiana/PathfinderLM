"""Health and readiness endpoint."""

from __future__ import annotations

import os

from flask import Blueprint, jsonify

from app.config import get_config
from app.models.model import get_client

health_bp = Blueprint("health", __name__)


def _ollama_reachable(host: str) -> bool:
    try:
        get_client(host).list()
        return True
    except Exception:
        return False


@health_bp.route("/health", methods=["GET"])
def health():
    """Always returns 200 once Flask is up; reports degraded subsystems inline."""
    config = get_config()
    index_present = os.path.exists(config.faiss_index_path)
    body = {
        "status": "ok",
        "provider": config.llm_provider,
        "model": config.model_name,
        "ollama": _ollama_reachable(config.ollama_host),
        "index": index_present,
    }
    return jsonify(body), 200
