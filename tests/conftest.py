"""Shared test fixtures.

The Ollama client is mocked process-wide so the suite runs fully offline (no
Ollama server, no model downloads) — this is what CI relies on.
"""

from __future__ import annotations

import numpy as np
import pytest


class FakeClient:
    """Stand-in for ``ollama.Client`` returning deterministic canned data."""

    def __init__(self, *args, **kwargs):
        pass

    def generate(self, model=None, prompt=None, **kwargs):
        return {"response": "<think>reasoning</think>This is a coached answer."}

    def embeddings(self, model=None, prompt=None, **kwargs):
        # Small fixed-dimension vector; deterministic per prompt length.
        vec = np.zeros(8, dtype="float32")
        vec[0] = float(len(prompt or ""))
        return {"embedding": vec.tolist()}

    def list(self, *args, **kwargs):
        return {"models": []}


@pytest.fixture(autouse=True)
def mock_ollama(monkeypatch):
    """Patch the single client chokepoint used across the app."""
    monkeypatch.setattr("app.models.model.Client", FakeClient)
    yield


@pytest.fixture
def client():
    """Flask test client."""
    from app import app as flask_app

    flask_app.config.update(TESTING=True)
    return flask_app.test_client()
