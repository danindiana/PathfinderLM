"""The ``/ask`` endpoint: retrieval-augmented coaching responses."""

from __future__ import annotations

import logging

from flask import Blueprint, jsonify, request

from app import llm
from app.config import get_config
from app.rag import Retriever
from app.utils.postprocessing import format_answer

ask_bp = Blueprint("ask", __name__)
logger = logging.getLogger("pathfinderlm.ask")

# Built once per process; degrades gracefully if no index exists yet.
_retriever = Retriever()

_PROMPT_TEMPLATE = (
    "You are PathfinderLM, an empathetic, evidence-based life coach.\n"
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
    data = request.get_json(silent=True) or {}
    question = (data.get("question") or "").strip()
    if not question:
        return jsonify({"error": "Field 'question' is required."}), 400

    user_context = (data.get("context") or "").strip()
    config = get_config()

    try:
        retrieved = _retriever.retrieve(question)
    except Exception as exc:  # retrieval must never hard-fail the request
        logger.warning("retrieval failed: %s", exc)
        retrieved = []

    prompt = _build_prompt(question, user_context, retrieved)

    try:
        answer = llm.generate(prompt)
    except NotImplementedError as exc:
        return jsonify({"error": str(exc)}), 501
    except Exception as exc:
        logger.error("generation failed: %s", exc)
        return jsonify({"error": "Language model backend unavailable."}), 502

    return jsonify(format_answer(answer, sources=retrieved, model=config.model_name))
