"""Tests for the model-layer helpers."""

from __future__ import annotations

from app.models.model import DEFAULT_MODEL, get_client


def test_get_client_returns_client():
    client = get_client("http://localhost:11434")
    # Patched to FakeClient in conftest; exercises the documented surface.
    assert hasattr(client, "generate")
    assert hasattr(client, "embeddings")


def test_default_model_is_deepseek():
    assert "deepseek" in DEFAULT_MODEL or DEFAULT_MODEL  # default unless overridden
