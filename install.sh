#!/usr/bin/env sh
# nuna-llm-local installer (macOS + Linux)
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/chevp/nuna-llm-local/main/install.sh | sh
#   ./install.sh [--no-models]
#
# Env overrides:
#   NUNA_CHAT_MODEL   (default: mistral:7b-instruct-q4_K_M)
#   NUNA_EMBED_MODEL  (default: nomic-embed-text)

set -eu

CHAT_MODEL="${NUNA_CHAT_MODEL:-mistral:7b-instruct-q4_K_M}"
EMBED_MODEL="${NUNA_EMBED_MODEL:-nomic-embed-text}"
SKIP_MODELS=0
for arg in "$@"; do
  [ "$arg" = "--no-models" ] && SKIP_MODELS=1
done

log()  { printf '\033[1;34m▶\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

OS="$(uname -s)"
case "$OS" in
  Darwin|Linux) ;;
  *) die "Unsupported OS: $OS. For Windows use install.ps1" ;;
esac

# 1. Install Ollama if missing
if command -v ollama >/dev/null 2>&1; then
  ok "Ollama already installed: $(ollama --version 2>&1 | head -n1)"
else
  log "Installing Ollama..."
  if [ "$OS" = "Darwin" ]; then
    command -v brew >/dev/null 2>&1 \
      || die "Homebrew not found. Install from https://brew.sh and re-run."
    brew install ollama
  else
    curl -fsSL https://ollama.com/install.sh | sh
  fi
  ok "Ollama installed"
fi

# 2. Start service (idempotent)
log "Starting Ollama service..."
if [ "$OS" = "Darwin" ]; then
  brew services start ollama >/dev/null 2>&1 || true
else
  # Linux installer registers systemd unit; ensure it's running.
  if systemctl list-unit-files 2>/dev/null | grep -q '^ollama\.service'; then
    sudo systemctl enable --now ollama >/dev/null 2>&1 || true
  fi
fi

# 3. Wait for API
log "Waiting for API on localhost:11434..."
i=0
until curl -fsS --max-time 2 http://localhost:11434/api/tags >/dev/null 2>&1; do
  i=$((i + 1))
  [ "$i" -ge 30 ] && die "API did not come up. Check 'brew services list' (macOS) or 'journalctl -u ollama' (Linux)."
  sleep 1
done
ok "API ready"

# 4. Pull default models
if [ "$SKIP_MODELS" -eq 1 ]; then
  warn "Skipping model pull (--no-models)"
else
  log "Pulling chat model: $CHAT_MODEL"
  ollama pull "$CHAT_MODEL"
  log "Pulling embedding model: $EMBED_MODEL"
  ollama pull "$EMBED_MODEL"
  ok "Models ready: $CHAT_MODEL + $EMBED_MODEL"
fi

ok "Done. Smoke test:"
printf "    curl http://localhost:11434/api/generate -d '{\"model\":\"%s\",\"prompt\":\"Hallo\",\"stream\":false}'\n" "$CHAT_MODEL"
