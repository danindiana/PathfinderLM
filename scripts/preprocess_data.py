"""Clean raw knowledge-base documents into ``data/processed``.

Reads ``.txt``/``.md`` files from a source directory, normalises their text, and
writes the cleaned versions to the processed directory ready for ``build_index``.
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.utils.preprocessing import clean_text  # noqa: E402

RAW_DIR = os.getenv("RAW_DIR", "data/raw")
PROCESSED_DIR = os.getenv("KNOWLEDGE_BASE_DIR", "data/processed")


def preprocess(raw_dir: str = RAW_DIR, processed_dir: str = PROCESSED_DIR) -> int:
    """Clean every supported file from ``raw_dir`` into ``processed_dir``."""
    os.makedirs(processed_dir, exist_ok=True)
    count = 0
    for name in sorted(os.listdir(raw_dir)) if os.path.isdir(raw_dir) else []:
        if not name.lower().endswith((".txt", ".md")):
            continue
        with open(os.path.join(raw_dir, name), "r", encoding="utf-8", errors="ignore") as handle:
            cleaned = clean_text(handle.read())
        out_name = os.path.splitext(name)[0] + ".txt"
        with open(os.path.join(processed_dir, out_name), "w", encoding="utf-8") as handle:
            handle.write(cleaned)
        count += 1
    return count


def main() -> int:
    written = preprocess()
    print(f"Preprocessed {written} file(s) into {PROCESSED_DIR!r}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
