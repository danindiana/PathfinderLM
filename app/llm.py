"""LLM provider abstraction.

Default provider is local Ollama. A cloud OpenAI provider is intentionally left
as a clearly-marked stub (``LLM_PROVIDER=openai``) — the dispatch and lazy import
are in place, but the call path raises ``NotImplementedError`` until the optional
``openai`` dependency and credentials are wired up.
"""

from __future__ import annotations

from typing import Optional

from app.config import get_config
from app.models.model import get_client


def generate(prompt: str, model: Optional[str] = None, system: Optional[str] = None) -> str:
    """Generate a completion for ``prompt`` using the configured provider.

    ``system`` is the optional system/persona prompt (applied via the provider's
    native system role rather than concatenated into ``prompt``).
    """
    config = get_config()
    provider = config.llm_provider.lower()

    if provider == "ollama":
        return _generate_ollama(prompt, model or config.model_name, config.ollama_host, system)
    if provider == "openai":
        return _generate_openai(prompt, model or config.model_name, system)
    raise ValueError(f"Unknown LLM_PROVIDER: {config.llm_provider!r} (expected 'ollama' or 'openai')")


def _generate_ollama(prompt: str, model: str, host: str, system: Optional[str]) -> str:
    client = get_client(host)
    kwargs = {"model": model, "prompt": prompt}
    if system:
        kwargs["system"] = system
    result = client.generate(**kwargs)
    # ollama returns a dict-like with a "response" key.
    return result["response"]


def _generate_openai(prompt: str, model: str, system: Optional[str]) -> str:
    """Cloud fallback — stubbed.

    To enable: ``pip install openai``, set ``LLM_PROVIDER=openai`` and
    ``OPENAI_API_KEY``, then implement the call here.
    """
    raise NotImplementedError(
        "The OpenAI cloud fallback is not implemented yet. "
        "PathfinderLM is local-first; set LLM_PROVIDER=ollama (the default)."
    )
