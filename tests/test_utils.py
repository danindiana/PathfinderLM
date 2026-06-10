"""Tests for preprocessing / postprocessing utilities."""

from __future__ import annotations

from app.utils.postprocessing import format_answer, strip_think
from app.utils.preprocessing import chunk_text, clean_text


def test_strip_think_removes_reasoning():
    assert strip_think("<think>hidden</think>visible") == "visible"
    assert strip_think("plain") == "plain"


def test_format_answer_from_string():
    payload = format_answer("hello", sources=["doc1"], model="deepseek-r1:14b")
    assert payload["answer"] == "hello"
    assert payload["sources"] == ["doc1"]
    assert payload["model"] == "deepseek-r1:14b"


def test_format_answer_from_dict():
    payload = format_answer({"answer": "<think>x</think>hi", "score": 0.9})
    assert payload["answer"] == "hi"
    assert payload["score"] == 0.9


def test_clean_text_collapses_whitespace():
    assert clean_text("  a\n\t b  ") == "a b"


def test_chunk_text_splits_and_overlaps():
    text = "word " * 500  # ~2500 chars
    chunks = chunk_text(text, chunk_size=200, overlap=50)
    assert len(chunks) > 1
    assert all(len(c) <= 200 for c in chunks)


def test_chunk_text_empty():
    assert chunk_text("") == []
