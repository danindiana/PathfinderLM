"""Response post-processing helpers."""

from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

_THINK_RE = re.compile(r"<think>.*?</think>", re.DOTALL | re.IGNORECASE)


def strip_think(text: str) -> str:
    """Remove deepseek-r1 ``<think>…</think>`` reasoning blocks and trim."""
    return _THINK_RE.sub("", text or "").strip()


def format_answer(
    answer: Any,
    sources: Optional[List[str]] = None,
    model: Optional[str] = None,
) -> Dict[str, Any]:
    """Normalise a model response into the documented ``/ask`` payload.

    Accepts either a raw answer string or a dict containing an ``answer`` key
    (the historical shape), and optionally attaches retrieval ``sources`` and the
    ``model`` that produced it.
    """
    if isinstance(answer, dict):
        text = answer.get("answer", "")
        score = answer.get("score")
    else:
        text = answer
        score = None

    payload: Dict[str, Any] = {"answer": strip_think(str(text))}
    if score is not None:
        payload["score"] = score
    if sources:
        payload["sources"] = sources
    if model:
        payload["model"] = model
    return payload
