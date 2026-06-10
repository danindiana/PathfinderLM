"""Retrieval-Augmented Generation support backed by FAISS + Ollama embeddings."""

from __future__ import annotations

import json
import os
from typing import List, Optional

from app.config import get_config
from app.models.model import get_client


def embed(text: str, model: Optional[str] = None, host: Optional[str] = None):
    """Return the embedding vector for ``text`` as a float32 numpy array."""
    import numpy as np

    config = get_config()
    client = get_client(host or config.ollama_host)
    resp = client.embeddings(model=model or config.embedding_model, prompt=text)
    return np.asarray(resp["embedding"], dtype="float32")


def _docs_sidecar(index_path: str) -> str:
    return f"{index_path}.docs.json"


class Retriever:
    """Loads a FAISS index (and its document sidecar) and answers queries.

    When the index file is absent the retriever degrades gracefully: ``retrieve``
    returns an empty list so the ``/ask`` endpoint still works before any index
    has been built.
    """

    def __init__(self, index_path: Optional[str] = None) -> None:
        config = get_config()
        self.index_path = index_path or config.faiss_index_path
        self.default_top_k = config.top_k
        self._index = None
        self._docs: List[str] = []
        self._load()

    @property
    def available(self) -> bool:
        return self._index is not None and bool(self._docs)

    def _load(self) -> None:
        if not os.path.exists(self.index_path):
            return
        try:
            import faiss

            self._index = faiss.read_index(self.index_path)
            sidecar = _docs_sidecar(self.index_path)
            if os.path.exists(sidecar):
                with open(sidecar, "r", encoding="utf-8") as handle:
                    self._docs = json.load(handle)
        except Exception:  # pragma: no cover - corrupt/missing index is non-fatal
            self._index = None
            self._docs = []

    def retrieve(self, query: str, top_k: Optional[int] = None) -> List[str]:
        """Return up to ``top_k`` document chunks most similar to ``query``."""
        if not self.available:
            return []
        k = min(top_k or self.default_top_k, len(self._docs))
        if k <= 0:
            return []
        vector = embed(query).reshape(1, -1)
        _distances, indices = self._index.search(vector, k)
        return [self._docs[i] for i in indices[0] if 0 <= i < len(self._docs)]
