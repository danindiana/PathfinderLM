#!/usr/bin/env bash
# Regenerate PNG + SVG from every Graphviz .dot source in this directory.
# Requires: graphviz (`sudo apt install graphviz`).
set -euo pipefail
cd "$(dirname "$0")"

command -v dot >/dev/null || { echo "error: graphviz 'dot' not found"; exit 1; }

for f in *.dot; do
    name="${f%.dot}"
    dot -Tpng "$f" -o "$name.png"
    dot -Tsvg "$f" -o "$name.svg"
    echo "rendered $name (.png + .svg)"
done
