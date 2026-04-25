# Architecture — nuna-llm-local

## Layer
Sehr flach — eine Service-Schicht, kein Application-Code.

| Layer | Inhalt | Files |
|---|---|---|
| **Runtime** | Ollama-Container (LLM-Engine + REST-API) | [docker-compose.yml](../../docker-compose.yml) |
| **Hardware-Override** | Optionale GPU-Reservation für Linux | [docker-compose.gpu.yml](../../docker-compose.gpu.yml) |
| **Config** | Tunables für Port, Keep-Alive, max. parallel geladene Modelle | [.env.example](../../.env.example) |
| **Operations** | Helper-Skripte für tägliche Workflows | [scripts/](../../scripts/) |
| **Persistence** | Docker Named Volume für gepullte Modelle | `ollama-data` (in compose) |
| **Docs** | GitHub-Pages-Site (Jekyll) | [docs/](../../docs/) |

## Module / Komponenten
- **`ollama` Service** — Single Container, Image `ollama/ollama:latest`, Restart `unless-stopped`. Healthcheck via `ollama list`.
- **Config-Surface** — Drei Env-Variablen: `OLLAMA_PORT`, `OLLAMA_KEEP_ALIVE`, `OLLAMA_MAX_LOADED_MODELS`. Default RAG-tauglich (2 Modelle parallel).
- **Skripte** —
  - [scripts/pull-model.sh](../../scripts/pull-model.sh): pullt ein Modell via `docker compose exec`.
  - [scripts/test-prompt.sh](../../scripts/test-prompt.sh): smoke-test eines Modells über `curl` gegen `/api/generate`.
  - [scripts/setup-rag.sh](../../scripts/setup-rag.sh): pullt Chat- + Embedding-Modell für ein RAG-Setup.

## Kommunikationspfade
```
Client (curl/SDK)
   │  HTTP
   ▼
Host:${OLLAMA_PORT}  ──port-mapping──▶  Container:11434  ──▶  Ollama Engine
                                                          │
                                                          ▼
                                              /root/.ollama (Volume ollama-data)
```
- Keine eigenen API-Endpunkte — Ollamas REST-API wird 1:1 exponiert (`/api/generate`, `/api/chat`, `/api/embeddings`, `/api/tags`, ...).
- Modelle werden pull-on-demand ins Volume geladen.

## Tech-Stack
| Technologie | Zweck | Begründung |
|---|---|---|
| Docker + Compose v2 | Runtime-Isolation, Cross-Plattform-Parität | Identische DX über macOS/Linux/WSL |
| Ollama | LLM-Server (Modell-Hosting + HTTP-API) | Stabile API, breites Modell-Ökosystem, q-quantisierte GGUF-Modelle |
| Bash-Skripte | Operative Helfer | Keine zusätzliche Sprach-/Tool-Abhängigkeit |
| Jekyll / GitHub Pages | Doku-Site | Standard für `chevp.github.io/*`-Repos |

## Forbidden Patterns / Invariants
- **Keine Hardware-Spezialisierung in der Basis-Compose** — GPU-Reservations gehören in `docker-compose.gpu.yml`.
- **Keine Hardcoded-Ports/Limits** — alles über `.env` mit `${VAR:-default}`.
- **Keine Auth/TLS-Schicht in diesem Repo** — Scope ist lokal/dev. Wer Production will, baut einen Proxy davor (anderes Repo).
- **Keine Anwendungs-/RAG-Pipeline-Code im Repo** — nur die Modelle werden bereitgestellt; Pipelines leben in Consumer-Repos.

## Erweiterungspunkte
- Weitere Compose-Overrides (z. B. `docker-compose.amd-rocm.yml`) folgen dem GPU-Override-Muster.
- Neue Skripte: ein Zweck pro Skript, `set -euo pipefail`, Argumente dokumentiert im Header.
- ADRs für nicht-triviale Entscheidungen (Modell-Default, Port-Wahl, Volume-Strategie) → [context/adr/](../adr/).
