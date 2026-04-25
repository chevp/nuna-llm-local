#!/usr/bin/env bash
# Pull a model into the running Ollama container.
# Usage: ./scripts/pull-model.sh [model-name]
set -euo pipefail
MODEL="${1:-mistral:7b-instruct-q4_K_M}"
docker compose exec ollama ollama pull "$MODEL"
echo "✓ Model '$MODEL' is ready"