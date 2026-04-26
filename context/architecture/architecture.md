# Architecture — nuna-llm-local

> Architektur-Wechsel von Docker auf nativ siehe [ADR-001](../adr/ADR-001-native-install-instead-of-docker.md).

## Layer
Sehr flach — kein Application-Code. Das Repo dokumentiert und automatisiert eine externe Service-Installation.

| Layer | Inhalt | Files |
|---|---|---|
| **Runtime** | Ollama-Service, nativ via Paketmanager installiert | (extern: brew / install.sh / Windows-Installer) |
| **Service-Wrapper** | LaunchAgent (macOS) oder systemd-Unit (Linux), vom Installer angelegt | (extern, Host-OS) |
| **Operations** | Helper-Skripte für tägliche Workflows | [scripts/](../../scripts/) |
| **Persistence** | Modell-Storage im Filesystem | `~/.ollama/` bzw. `/usr/share/ollama/.ollama/` |
| **Docs** | GitHub-Pages-Site (Jekyll) | [docs/](../../docs/) |

## Module / Komponenten
- **Ollama-Service (extern)** — Vom Paketmanager installiert. Auto-Start via LaunchAgent (`brew services`) bzw. systemd. Lauscht auf `localhost:11434`.
- **Config-Surface** — Env-Variablen werden plattform-spezifisch am Service-Wrapper gesetzt:
  - macOS (brew services): `launchctl setenv OLLAMA_KEEP_ALIVE 24h` vor `brew services start ollama`.
  - Linux (systemd): Drop-In-Datei unter `/etc/systemd/system/ollama.service.d/override.conf` mit `Environment="OLLAMA_KEEP_ALIVE=24h"`.
  - Relevante Vars: `OLLAMA_HOST` (Bind-Adresse), `OLLAMA_KEEP_ALIVE` (Idle-Unload-Zeit), `OLLAMA_MAX_LOADED_MODELS` (Parallel-Slots).
- **Skripte** —
  - [scripts/pull-model.sh](../../scripts/pull-model.sh): pullt ein Modell via `ollama pull`.
  - [scripts/test-prompt.sh](../../scripts/test-prompt.sh): smoke-test eines Modells über `curl` gegen `/api/generate`.
  - [scripts/setup-rag.sh](../../scripts/setup-rag.sh): pullt Chat- + Embedding-Modell für ein RAG-Setup.

## Kommunikationspfade
```
Client (curl/SDK)
   │  HTTP
   ▼
localhost:11434  ──▶  Ollama Engine (nativer Prozess)
                            │
                            ├──▶ GPU (Metal / CUDA, automatisch)
                            └──▶ ~/.ollama (Modell-Storage)
```
- Keine eigenen API-Endpunkte — Ollamas REST-API wird 1:1 genutzt (`/api/generate`, `/api/chat`, `/api/embeddings`, `/api/tags`, ...).
- Modelle werden pull-on-demand ins lokale Storage-Verzeichnis geladen.

## Tech-Stack
| Technologie | Zweck | Begründung |
|---|---|---|
| Ollama (nativ) | LLM-Server (Modell-Hosting + HTTP-API) | Stabile API, breites Modell-Ökosystem, GGUF-Modelle, automatische GPU-Erkennung (Metal/CUDA) |
| Paketmanager (brew / install.sh / Windows-Installer) | Installation + Service-Setup | Plattform-natives Lifecycle-Management ohne Container-Overhead |
| Bash-Skripte | Operative Helfer | Keine zusätzliche Sprach-/Tool-Abhängigkeit |
| Jekyll / GitHub Pages | Doku-Site | Standard für `chevp.github.io/*`-Repos |

## Forbidden Patterns / Invariants
- **Kein Container-Lieferweg im Repo** — Docker-Compose ist mit [ADR-001](../adr/ADR-001-native-install-instead-of-docker.md) entfernt. Wer containerisieren will, tut das in einem Consumer-Repo.
- **Keine Hardcoded-Ports/Hosts in Skripten** — wenn ein Skript einen Port braucht, liest es ihn aus `OLLAMA_PORT` mit Default `11434`.
- **Keine Auth/TLS-Schicht in diesem Repo** — Scope ist lokal/dev. Wer Production will, baut einen Proxy davor (anderes Repo).
- **Keine Anwendungs-/RAG-Pipeline-Code im Repo** — nur die Modelle werden bereitgestellt; Pipelines leben in Consumer-Repos.

## Erweiterungspunkte
- Neue Skripte: ein Zweck pro Skript, `set -euo pipefail`, Argumente dokumentiert im Header.
- Plattform-spezifische Setup-Hinweise gehen in den README-Quick-Start, nicht in die Skripte (Skripte bleiben plattform-neutral und nutzen die `ollama`-CLI).
- ADRs für nicht-triviale Entscheidungen (Modell-Default, Service-Strategie, Lieferweg) → [context/adr/](../adr/).
