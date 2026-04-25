#!/usr/bin/env bash
# Run a one-shot prompt against the local Ollama HTTP API.
# Usage: ./scripts/test-prompt.sh [model] [prompt]
set -euo pipefail
MODEL="${1:-mistral:7b-instruct-q4_K_M}"
PROMPT="${2:-Erkläre Docker in einem Satz.}"
PORT="${OLLAMA_PORT:-11434}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required (brew install jq / apt install jq)" >&2
  exit 1
fi

curl -s "http://localhost:${PORT}/api/generate" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n --arg m "$MODEL" --arg p "$PROMPT" '{model:$m, prompt:$p, stream:false}')" \
  | jq -r '.response'