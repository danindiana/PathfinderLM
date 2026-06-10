"""Flask blueprints for PathfinderLM."""

from app.routes.ask import ask_bp
from app.routes.console import console_bp
from app.routes.health import health_bp


def register_blueprints(app) -> None:
    """Attach all route blueprints to the given Flask app."""
    app.register_blueprint(health_bp)
    app.register_blueprint(ask_bp)
    app.register_blueprint(console_bp)


__all__ = ["ask_bp", "health_bp", "console_bp", "register_blueprints"]
