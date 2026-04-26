# nuna-llm-local

Run an LLM locally via [Ollama](https://ollama.com/), installed natively on the host. Default port `11434`. Models persist in your home directory.

📖 **Docs:** [chevp.github.io/nuna-llm-local](https://chevp.github.io/nuna-llm-local/)

---

## Why native

Ollama runs as a host service and uses the GPU directly:

- **Apple Silicon**: Metal acceleration.
- **Linux + NVIDIA**: CUDA acceleration — only the NVIDIA driver is required.
- **Windows**: native Windows installer.

Service management is platform-native: LaunchAgent on macOS, systemd on Linux, Windows service on Windows.

## Install

### One-liner (recommended)

Installs Ollama, starts the service, and pulls the default chat + embedding models. Idempotent — safe to re-run.

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/chevp/nuna-llm-local/main/install.sh | sh
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/chevp/nuna-llm-local/main/install.ps1 | iex
```

Skip the model pull with `--no-models` (sh) / `-NoModels` (PowerShell). Override defaults with `NUNA_CHAT_MODEL` / `NUNA_EMBED_MODEL` env vars.

### Use as a git submodule

If you embed `nuna-llm-local` in a parent project (e.g. an Electron app) and want to share the install logic:

```bash
git submodule add https://github.com/chevp/nuna-llm-local vendor/nuna-llm-local
./vendor/nuna-llm-local/install.sh        # macOS / Linux
pwsh -File vendor/nuna-llm-local/install.ps1   # Windows
```

The scripts don't depend on the working directory and are safe to invoke from any path.

### Manual install

If you'd rather not pipe a script:

**macOS (Apple Silicon, Metal):**
```bash
brew install ollama
brew services start ollama
```

**Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
systemctl status ollama
```

**Windows:** Download from [ollama.com/download](https://ollama.com/download).

### Verify
```bash
curl http://localhost:11434/api/tags
# → {"models":[...]}
```

## Quick start

Pull a model and test it:

```bash
./scripts/pull-model.sh mistral:7b-instruct-q4_K_M
./scripts/test-prompt.sh mistral:7b-instruct-q4_K_M "Was ist Metal?"
```

Direct API call:

```bash
curl http://localhost:11434/api/generate \
  -d '{"model":"mistral:7b-instruct-q4_K_M","prompt":"Hello","stream":false}'
```

Interactive shell:

```bash
ollama run mistral:7b-instruct-q4_K_M
```

## Recommended models

With Metal (macOS) or CUDA (Linux/NVIDIA), 7B–13B models run comfortably:

| Model | Disk | Use case |
|---|---|---|
| `llama3.2:3b` | ~2 GB | Fast dev loop, short answers |
| `phi3:mini` | ~2 GB | Very fast, small reasoning tasks |
| `mistral:7b-instruct-q4_K_M` | ~4 GB | **Default** — well-rounded chat |
| `llama3.1:8b-instruct-q4_K_M` | ~5 GB | Slightly higher quality |
| `llama3.1:13b-instruct-q4_K_M` | ~8 GB | Best quality on 16+ GB unified memory / 12+ GB VRAM |
| `nomic-embed-text` | ~270 MB | Embeddings (RAG) |

For a basic RAG stack (chat + embeddings):

```bash
./scripts/setup-rag.sh
```

## Configuration

Ollama reads environment variables. Set them at the **service wrapper**, not via `.env`:

| Variable | Default | Purpose |
|---|---|---|
| `OLLAMA_HOST` | `127.0.0.1:11434` | Bind address. Set to `0.0.0.0:11434` for LAN access (no auth — be careful). |
| `OLLAMA_KEEP_ALIVE` | `5m` | How long an idle model stays in memory. |
| `OLLAMA_MAX_LOADED_MODELS` | `1` | How many models can be loaded simultaneously (set `2` for chat + embedding RAG). |

### macOS (brew services)
```bash
brew services stop ollama
launchctl setenv OLLAMA_KEEP_ALIVE 24h
launchctl setenv OLLAMA_MAX_LOADED_MODELS 2
brew services start ollama
```

### Linux (systemd)
```bash
sudo systemctl edit ollama.service
# Add under [Service]:
#   Environment="OLLAMA_KEEP_ALIVE=24h"
#   Environment="OLLAMA_MAX_LOADED_MODELS=2"
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## Model storage

Models are pulled on demand and cached locally:

| Platform / setup | Location |
|---|---|
| macOS | `~/.ollama/models/` |
| Linux (systemd default) | `/usr/share/ollama/.ollama/models/` |
| Linux (manual / user mode) | `~/.ollama/models/` |
| Windows | `%USERPROFILE%\.ollama\models\` |

## Stop / clean up

```bash
# macOS
brew services stop ollama

# Linux
sudo systemctl stop ollama

# Remove all downloaded models (macOS / user-mode Linux)
rm -rf ~/.ollama/models
```

## Troubleshooting

**`port already in use 11434`**
Another Ollama instance is already bound to the port. Stop it, or set `OLLAMA_HOST=127.0.0.1:11435` for the native service.

**GPU not used (slow responses on Apple Silicon)**
Run `ollama ps` while a query is running — it should list the model under `PROCESSOR` as `100% GPU`. If it shows CPU, you're likely on Intel Mac (no Metal) or running an older Ollama version (`brew upgrade ollama`).

**GPU not detected on Linux**
Verify the NVIDIA driver: `nvidia-smi`. Ollama auto-detects CUDA — no toolkit setup required, just the driver.

**Service won't start after reboot (macOS)**
`brew services list` should show `ollama` as `started`. If not: `brew services start ollama`.

**Service won't start (Linux)**
`journalctl -u ollama -e` shows the last error.

**Model download stalls or fails**
Check available disk space — a 7B-q4 model is ~4 GB.

## License

MIT
