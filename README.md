# nuna-llm-local

Run an LLM locally via [Ollama](https://ollama.com/) in Docker. Default port `11434`. Persistent models in a named volume.

📖 **Docs:** [chevp.github.io/nuna-llm-local](https://chevp.github.io/nuna-llm-local/)

---

## Why Docker (and not native)

Running Ollama in Docker keeps dev and prod identical across Linux, macOS, and Windows. The Apple Silicon GPU is not exposed to Docker, so on macOS the container is CPU-only. On an M-series chip that's still fast enough for 7B-q4 models.

If you only need raw speed and don't care about parity, install Ollama natively (`brew install ollama`) — it uses the Apple GPU via Metal. This repo does not cover that path.

## Prerequisites

- Docker + Docker Compose
- Optional, Linux only: NVIDIA driver + [`nvidia-container-toolkit`](https://github.com/NVIDIA/nvidia-container-toolkit)

## Quick start

```bash
cp .env.example .env
docker compose up -d

# Linux + NVIDIA GPU instead:
docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
```

Pull a model and test it:

```bash
./scripts/pull-model.sh mistral:7b-instruct-q4_K_M
./scripts/test-prompt.sh mistral:7b-instruct-q4_K_M "Was ist Docker?"
```

Direct API call:

```bash
curl http://localhost:11434/api/generate \
  -d '{"model":"mistral:7b-instruct-q4_K_M","prompt":"Hello","stream":false}'
```

Interactive shell inside the container:

```bash
docker compose exec ollama ollama run mistral:7b-instruct-q4_K_M
```

## Recommended models

CPU-only on Apple Silicon (M-series) — these run in seconds, not minutes:

| Model | Disk | Use case |
|---|---|---|
| `llama3.2:3b` | ~2 GB | Fast dev loop, short answers |
| `phi3:mini` | ~2 GB | Very fast, small reasoning tasks |
| `mistral:7b-instruct-q4_K_M` | ~4 GB | **Default** — well-rounded chat |
| `llama3.1:8b-instruct-q4_K_M` | ~5 GB | Slightly higher quality |
| `nomic-embed-text` | ~270 MB | Embeddings (RAG) |

For a basic RAG stack (chat + embeddings):

```bash
./scripts/setup-rag.sh
```

## Stop / clean up

```bash
docker compose down            # stop containers, keep models
docker compose down -v         # also delete the volume (models gone)
```

## Platform notes

- **macOS (Apple Silicon)**: native ARM64 image, no Rosetta. CPU-only — Apple GPU is not exposed to Docker. Stick to q4-quantised 7B–8B models.
- **Linux**: full GPU support via `nvidia-container-toolkit`. Use the GPU compose override.
- **Windows**: WSL2 + Docker Desktop. NVIDIA GPU works via WSL CUDA.

## Troubleshooting

**`port already in use 11434`**
Ollama is already running natively. Either stop it (`brew services stop ollama` / `systemctl stop ollama`) or set `OLLAMA_PORT=11435` in `.env`.

**`could not select device driver "nvidia"` (Linux)**
Install the toolkit:
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```
Verify: `docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi`

**GPU not detected inside container**
`docker compose exec ollama nvidia-smi` should list the GPU. If not, re-check the host driver (`nvidia-smi`) and ensure the GPU compose override is active.

**Model download stalls or fails**
Check available volume space: `docker system df -v`. A 7B-q4 model is ~4 GB.

**Healthcheck reports `unhealthy`**
First 20 s is the configured `start_period` — that's normal. If it persists, inspect logs: `docker compose logs ollama`.

**Very slow responses (CPU)**
Expected on CPU-only setups. Use q4-quantised models (`mistral:7b-instruct-q4_K_M`) or smaller (`llama3.2:3b`, `phi3:mini`).

## License

MIT