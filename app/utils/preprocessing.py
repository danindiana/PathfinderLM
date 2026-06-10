"""Text preprocessing helpers used when ingesting the knowledge base."""

from __future__ import annotations

import re
from typing import List

_WHITESPACE_RE = re.compile(r"\s+")


def clean_text(text: str) -> str:
    """Collapse whitespace and strip surrounding noise from ``text``."""
    return _WHITESPACE_RE.sub(" ", text or "").strip()


def chunk_text(text: str, chunk_size: int = 800, overlap: int = 100) -> List[str]:
    """Split ``text`` into overlapping word-bounded chunks for embedding.

    ``chunk_size`` and ``overlap`` are measured in characters. Overlap preserves
    context across chunk boundaries.
    """
    cleaned = clean_text(text)
    if not cleaned:
        return []
    if chunk_size <= 0:
        return [cleaned]

    step = max(1, chunk_size - max(0, overlap))
    chunks: List[str] = []
    start = 0
    length = len(cleaned)
    while start < length:
        end = min(start + chunk_size, length)
        # Prefer to break on a space to avoid splitting words.
        if end < length:
            space = cleaned.rfind(" ", start, end)
            if space > start:
                end = space
        chunks.append(cleaned[start:end].strip())
        if end >= length:
            break
        start += step
    return [chunk for chunk in chunks if chunk]
