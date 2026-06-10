"""Tests for the RAG retriever."""

from __future__ import annotations

from app.rag import Retriever, embed


def test_retriever_graceful_without_index(tmp_path):
    missing = str(tmp_path / "does_not_exist.index")
    retriever = Retriever(index_path=missing)
    assert retriever.available is False
    assert retriever.retrieve("anything") == []


def test_embed_returns_vector():
    vec = embed("hello world")
    assert vec.shape[0] == 8  # FakeClient embedding dimension
    assert vec.dtype.name == "float32"
