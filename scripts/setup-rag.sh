#!/usr/bin/env bash
# Pull the chat model + embedding model needed for a basic RAG stack.
set -euo pipefail
ollama pull mistral:7b-instruct-q4_K_M
ollama pull nomic-embed-text
echo "✓ RAG models ready: mistral (chat) + nomic-embed-text (embeddings)"