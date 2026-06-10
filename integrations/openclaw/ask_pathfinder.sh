#!/usr/bin/env sh
# ask_pathfinder.sh — query the PathfinderLM coaching API and print the answer.
#
# Designed to be called by OpenClaw (or any agent/shell) as a skill/tool.
#
# Usage:
#   ask_pathfinder.sh "How do I build a morning routine?" ["optional context"]
#
# Environment:
#   PATHFINDER_URL  Base URL of the PathfinderLM API (default http://localhost:5000)
#
# Dependencies: curl, jq
set -eu

PATHFINDER_URL="${PATHFINDER_URL:-http://localhost:5000}"

if [ "$#" -lt 1 ] || [ -z "$1" ]; then
    echo "usage: $0 \"<question>\" [\"<context>\"]" >&2
    exit 2
fi

question="$1"
context="${2:-}"

for bin in curl jq; do
    command -v "$bin" >/dev/null 2>&1 || { echo "error: '$bin' is required" >&2; exit 1; }
done

payload="$(jq -n --arg q "$question" --arg c "$context" '{question: $q} + (if $c == "" then {} else {context: $c} end)')"

response="$(curl -s -m 120 -X POST "${PATHFINDER_URL}/ask" \
    -H "Content-Type: application/json" \
    -d "$payload")" || { echo "error: request to ${PATHFINDER_URL}/ask failed" >&2; exit 1; }

# Print the answer if present, otherwise surface the error JSON.
if printf '%s' "$response" | jq -e 'has("answer")' >/dev/null 2>&1; then
    printf '%s\n' "$response" | jq -r '.answer'
else
    printf '%s\n' "$response" | jq -r '.error // "unexpected response"' >&2
    exit 1
fi
