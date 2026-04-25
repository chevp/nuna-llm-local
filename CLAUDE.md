# nuna-llm-local

## System Overview
- **Was**: Lokaler LLM-Stack via [Ollama](https://ollama.com/) in Docker. Default-Port `11434`, Modelle persistiert in einem Named Volume (`ollama-data`).
- **Wer nutzt es**: Entwickler, die lokal/offline mit LLMs arbeiten wollen — Dev-Loop, Prototyping, einfaches RAG-Setup. Keine Multi-User-/Produktivumgebung.
- **Architektur**: Single-Service `docker-compose` mit optionalem GPU-Override für Linux + NVIDIA. Siehe [context/architecture/architecture.md](context/architecture/architecture.md) und [context/architecture/system-spec.md](context/architecture/system-spec.md).

## Key Patterns & Conventions
- **Compose-Layering**: Basis in [docker-compose.yml](docker-compose.yml), optionale Hardware-Pfade als Override (`docker-compose.gpu.yml`). Kein Vermischen von Hardware-Pfaden in der Basis.
- **Konfiguration via `.env`**: Alle ports/limits/tunables stehen in [.env.example](.env.example) und werden im Compose mit `${VAR:-default}` referenziert. Kein Hardcoding.
- **Scripts**: Kleine, idempotente Bash-Skripte unter [scripts/](scripts/). Ein Skript = ein Zweck (`pull-model.sh`, `test-prompt.sh`, `setup-rag.sh`). `set -euo pipefail`-Stil.
- **Modell-Defaults**: `mistral:7b-instruct-q4_K_M` als Standard-Chatmodell, `nomic-embed-text` als Standard-Embedding (RAG). Apple-Silicon = CPU-only → q4-Quantisierungen bevorzugen.
- **Docs**: Jekyll-Site unter [docs/](docs/) wird via GitHub Pages publiziert (`chevp.github.io/nuna-llm-local`).

## Context Inventory
- [README.md](README.md) — Nutzer-Dokumentation (Quick Start, Modelle, Troubleshooting)
- [docker-compose.yml](docker-compose.yml) / [docker-compose.gpu.yml](docker-compose.gpu.yml) — Service-Definition
- [.env.example](.env.example) — Konfigurations-Template
- [scripts/pull-model.sh](scripts/pull-model.sh) — Modell pullen
- [scripts/test-prompt.sh](scripts/test-prompt.sh) — Smoke-Test eines Modells via API
- [scripts/setup-rag.sh](scripts/setup-rag.sh) — Pull Chat- + Embedding-Modell für RAG
- [docs/](docs/) — GitHub-Pages-Site
- **Externe Abhängigkeiten**: Docker Engine, Docker Compose v2, optional `nvidia-container-toolkit` (Linux/GPU)
- **ADRs**: [context/adr/](context/adr/) (noch leer)

## Active Plans
- Keine aktiven CTX/EXP/PRD. Verzeichnis: [context/plans/active/](context/plans/active/)
- Gate-Status: —
- Proposals: [context/plans/proposals/](context/plans/proposals/) (leer)
- Governance-Log: [context/governance-log.md](context/governance-log.md)

## Last Updated
- 2026-04-25 — Initiales Setup gemäss [chevp-ai-framework](https://chevp.github.io/chevp-ai-framework/chevp-ai-framework.md): CLAUDE.md, context-Struktur, system-spec, architecture, governance-log.
