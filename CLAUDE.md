# nuna-llm-local

## System Overview
- **Was**: Lokaler LLM-Stack via nativ installiertem [Ollama](https://ollama.com/). Default-Port `11434`, Modelle persistiert im Home (`~/.ollama/`) bzw. unter `/usr/share/ollama/.ollama/` (Linux/systemd).
- **Wer nutzt es**: Entwickler, die lokal/offline mit GPU-beschleunigten LLMs arbeiten wollen — Dev-Loop, Prototyping, einfaches RAG-Setup. Keine Multi-User-/Produktivumgebung.
- **Architektur**: Nativer Service (LaunchAgent auf macOS, systemd auf Linux). Siehe [context/architecture/architecture.md](context/architecture/architecture.md) und [context/architecture/system-spec.md](context/architecture/system-spec.md). Lieferweg-Wechsel von Docker auf nativ in [ADR-001](context/adr/ADR-001-native-install-instead-of-docker.md).

## Key Patterns & Conventions
- **Lieferweg = Paketmanager**: `brew install ollama` (macOS), Install-Script (Linux), Windows-Installer. Kein Container, keine Compose-Datei. Begründung in [ADR-001](context/adr/ADR-001-native-install-instead-of-docker.md).
- **Installer-Symmetrie**: [install.sh](install.sh) (POSIX, macOS+Linux) und [install.ps1](install.ps1) (Windows) leisten dasselbe — Ollama installieren, Service starten, Default-Modelle pullen. Idempotent, ohne `cd`, von jedem CWD aufrufbar (Submodule-Use-Case).
- **Konfiguration am Service-Wrapper**: Env-Vars (`OLLAMA_HOST`, `OLLAMA_KEEP_ALIVE`, `OLLAMA_MAX_LOADED_MODELS`) werden plattform-spezifisch gesetzt — `launchctl setenv` (macOS) bzw. systemd-Drop-In (Linux). Keine `.env`-Datei.
- **Scripts**: Kleine, idempotente Bash-Skripte unter [scripts/](scripts/). Ein Skript = ein Zweck (`pull-model.sh`, `test-prompt.sh`, `setup-rag.sh`). `set -euo pipefail`-Stil. Skripte rufen `ollama` direkt auf, nicht via Container.
- **Modell-Defaults**: `mistral:7b-instruct-q4_K_M` als Standard-Chatmodell, `nomic-embed-text` als Standard-Embedding (RAG). Mit Metal/CUDA sind 13B-q4 oder unquantisierte 7B realistisch.
- **Docs**: Jekyll-Site unter [docs/](docs/) wird via GitHub Pages publiziert (`chevp.github.io/nuna-llm-local`).

## Context Inventory
- [README.md](README.md) — Nutzer-Dokumentation (Install, Quick Start, Modelle, Troubleshooting)
- [install.sh](install.sh) / [install.ps1](install.ps1) — One-liner-Installer (Ollama install + service start + Default-Modell-Pull). Submodule-tauglich, idempotent.
- [scripts/pull-model.sh](scripts/pull-model.sh) — Modell pullen
- [scripts/test-prompt.sh](scripts/test-prompt.sh) — Smoke-Test eines Modells via API
- [scripts/setup-rag.sh](scripts/setup-rag.sh) — Pull Chat- + Embedding-Modell für RAG
- [docs/](docs/) — GitHub-Pages-Site (Landing) + [docs/chat.html](docs/chat.html) (Browser-Chat-Demo gegen `localhost:11434`, single-file, vanilla JS, vom Cura UXIP-001-Prototyp portiert)
- **Externe Abhängigkeiten**: Ollama (nativ), Bash/PowerShell, `curl`, `jq`. Optional `nvidia-driver` (Linux/GPU).
- **ADRs**: [ADR-001 — Native Ollama-Installation statt Docker](context/adr/ADR-001-native-install-instead-of-docker.md)

## Active Plans
- Keine aktiven CTX/EXP/PRD. Verzeichnis: [context/plans/active/](context/plans/active/)
- Gate-Status: —
- Proposals: [context/plans/proposals/](context/plans/proposals/) (leer)
- Governance-Log: [context/governance-log.md](context/governance-log.md)

## Last Updated
- 2026-04-25 — Wechsel von Docker auf native Installation (ADR-001). Compose-Dateien und `.env.example` entfernt; Skripte nutzen `ollama` direkt; README/system-spec/architecture aktualisiert.
- 2026-04-25 — Initiales Setup gemäss [chevp-ai-framework](https://chevp.github.io/chevp-ai-framework/chevp-ai-framework.md).
