"""Build the FAISS index from the knowledge base using Ollama embeddings.

Walks ``KNOWLEDGE_BASE_DIR`` for ``.txt``/``.md`` files, chunks them, embeds each
chunk with the Ollama ``nomic-embed-text`` model, and writes a FAISS index plus a
``<index>.docs.json`` sidecar mapping vector ids back to their source text.

Customising the assistant's behaviour is done with an Ollama Modelfile (system
prompt + parameters), not by training weights — see ground_game.md.
"""

from __future__ import annotations

import json
import os
import sys
from typing import List

import faiss
import numpy as np
from ollama import Client

# Allow ``python scripts/build_index.py`` from the repo root.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.utils.preprocessing import chunk_text, clean_text  # noqa: E402

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
EMBED_MODEL = os.getenv("EMBEDDING_MODEL", "nomic-embed-text")
KNOWLEDGE_BASE_DIR = os.getenv("KNOWLEDGE_BASE_DIR", "data/processed")
INDEX_PATH = os.getenv("FAISS_INDEX_PATH", "results/faiss.index")

_client = Client(host=OLLAMA_HOST)


def embed(text: str) -> np.ndarray:
    """Embed a single string into a float32 vector."""
    resp = _client.embeddings(model=EMBED_MODEL, prompt=text)
    return np.asarray(resp["embedding"], dtype="float32")


def load_documents(directory: str) -> List[str]:
    """Read and chunk every .txt/.md file under ``directory``."""
    docs: List[str] = []
    for root, _dirs, files in os.walk(directory):
        for name in sorted(files):
            if not name.lower().endswith((".txt", ".md")):
                continue
            path = os.path.join(root, name)
            with open(path, "r", encoding="utf-8", errors="ignore") as handle:
                docs.extend(chunk_text(clean_text(handle.read())))
    return docs


def build(docs: List[str], index_path: str = INDEX_PATH) -> None:
    """Embed ``docs`` and persist a FAISS index plus its document sidecar."""
    if not docs:
        raise ValueError("No documents to index. Add files to KNOWLEDGE_BASE_DIR.")
    vectors = np.vstack([embed(d) for d in docs])
    index = faiss.IndexFlatL2(vectors.shape[1])
    index.add(vectors)

    os.makedirs(os.path.dirname(index_path) or ".", exist_ok=True)
    faiss.write_index(index, index_path)
    with open(f"{index_path}.docs.json", "w", encoding="utf-8") as handle:
        json.dump(docs, handle)


def main() -> int:
    docs = load_documents(KNOWLEDGE_BASE_DIR)
    print(f"Loaded {len(docs)} chunks from {KNOWLEDGE_BASE_DIR!r}")
    build(docs)
    print(f"Wrote index to {INDEX_PATH} (+ {INDEX_PATH}.docs.json)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
