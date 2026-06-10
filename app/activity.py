"""In-memory activity tracking for the operator console.

A small, thread-safe ring buffer of recent ``/ask`` requests plus running
counters. Intentionally ephemeral (per-process) — it exists to give a human
operator live insight, not durable analytics.
"""

from __future__ import annotations

import time
from collections import deque
from threading import Lock
from typing import Any, Dict, Optional

_LOCK = Lock()
_RECENT: deque = deque(maxlen=50)
_STARTED = time.time()
_STATS = {"total": 0, "errors": 0, "latency_ms_sum": 0.0}


def record(
    question: str,
    status: int,
    latency_ms: float,
    sources: int,
    model: str,
    error: Optional[str] = None,
) -> None:
    """Record one handled request."""
    with _LOCK:
        _STATS["total"] += 1
        _STATS["latency_ms_sum"] += latency_ms
        if status >= 400:
            _STATS["errors"] += 1
        _RECENT.appendleft(
            {
                "ts": time.time(),
                "question": (question or "")[:140],
                "status": status,
                "latency_ms": round(latency_ms),
                "sources": sources,
                "model": model,
                "error": error,
            }
        )


def snapshot() -> Dict[str, Any]:
    """Return current stats + recent requests for the console/API."""
    with _LOCK:
        total = _STATS["total"]
        avg = round(_STATS["latency_ms_sum"] / total) if total else 0
        return {
            "stats": {
                "total": total,
                "errors": _STATS["errors"],
                "avg_latency_ms": avg,
                "uptime_s": round(time.time() - _STARTED),
            },
            "recent": list(_RECENT),
        }
