"""PathfinderLM Flask application factory.

Exposes both ``create_app()`` and a module-level ``app`` instance so callers can
use either ``from app import app`` (tests, ``app/main.py``) or the factory.
"""

from __future__ import annotations

from flask import Flask, jsonify

from app.config import get_config
from app.utils.helpers import setup_logging

_API_INFO = {
    "name": "PathfinderLM",
    "description": "Local-first RAG life-coach API (Ollama + OpenClaw).",
    "endpoints": {
        "GET /console": "Human operator dashboard (live status + ask box).",
        "GET /health": "Liveness/readiness with subsystem status.",
        "POST /ask": "Ask a coaching question. Body: {\"question\": str, \"context\"?: str}.",
        "GET /api/activity": "Recent request activity + running stats (JSON).",
        "GET /metrics": "Prometheus metrics.",
    },
}


def create_app() -> Flask:
    """Build and configure the Flask application."""
    config = get_config()
    setup_logging(config.log_level)

    flask_app = Flask(__name__)
    flask_app.config["SECRET_KEY"] = config.secret_key
    flask_app.config["JSON_SORT_KEYS"] = False

    try:  # CORS is convenient but optional
        from flask_cors import CORS

        CORS(flask_app)
    except Exception:  # pragma: no cover
        pass

    from app.routes import register_blueprints

    register_blueprints(flask_app)

    @flask_app.route("/")
    def index():  # pragma: no cover - trivial
        return jsonify(_API_INFO)

    _register_metrics(flask_app)
    return flask_app


def _register_metrics(flask_app: Flask) -> None:
    """Expose a Prometheus ``/metrics`` endpoint if the client is installed."""
    try:
        from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
    except Exception:  # pragma: no cover - metrics are optional
        return

    @flask_app.route("/metrics")
    def metrics():  # pragma: no cover - thin wrapper
        return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


app = create_app()

__all__ = ["app", "create_app"]
