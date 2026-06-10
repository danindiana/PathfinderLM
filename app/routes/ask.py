"""The ``/ask`` endpoint: retrieval-augmented coaching responses."""

from __future__ import annotations

import logging
import time

from flask import Blueprint, jsonify, request

from app import activity, llm
from app.config import get_config
from app.rag import Retriever
from app.utils.postprocessing import format_answer

ask_bp = Blueprint("ask", __name__)
logger = logging.getLogger("pathfinderlm.ask")

# Built once per process; degrades gracefully if no index exists yet.
_retriever = Retriever()

# The coaching persona is applied via the system role (see app.config /
# Modelfile); this template carries only the retrieved context and the question.
_PROMPT_TEMPLATE = (
    "Use the following context when it is relevant.\n\n"
    "Context:\n{context}\n\n"
    "Question: {question}\n\n"
    "Answer:"
)


def _build_prompt(question: str, user_context: str, retrieved: list) -> str:
    parts = []
    if user_context:
        parts.append(user_context)
    parts.extend(retrieved)
    context = "\n\n".join(p for p in parts if p) or "(no additional context)"
    return _PROMPT_TEMPLATE.format(context=context, question=question)


@ask_bp.route("/ask", methods=["POST"])
def ask():
    """Answer a coaching question, grounded in retrieved knowledge."""
    started = time.perf_counter()
    data = request.get_json(silent=True) or {}
    question = (data.get("question") or "").strip()
    config = get_config()
    if not question:
        activity.record("", 400, 0.0, 0, config.model_name, error="missing question")
        return jsonify({"error": "Field 'question' is required."}), 400

    user_context = (data.get("context") or "").strip()

    try:
        retrieved = _retriever.retrieve(question)
    except Exception as exc:  # retrieval must never hard-fail the request
        logger.warning("retrieval failed: %s", exc)
        retrieved = []

    prompt = _build_prompt(question, user_context, retrieved)

    def _elapsed() -> float:
        return (time.perf_counter() - started) * 1000

    try:
        answer = llm.generate(prompt, system=config.system_prompt)
    except NotImplementedError as exc:
        activity.record(question, 501, _elapsed(), len(retrieved), config.model_name, error=str(exc))
        return jsonify({"error": str(exc)}), 501
    except Exception as exc:
        logger.error("generation failed: %s", exc)
        activity.record(question, 502, _elapsed(), len(retrieved), config.model_name, error=str(exc))
        return jsonify({"error": "Language model backend unavailable."}), 502

    activity.record(question, 200, _elapsed(), len(retrieved), config.model_name)
    return jsonify(format_answer(answer, sources=retrieved, model=config.model_name))
