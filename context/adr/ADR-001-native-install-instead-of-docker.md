---
status: approved
proposed-by: pair
decided-by: chevp
approved-by: chevp
approved-at: 2026-04-25
---

# ADR-001 — Native Ollama-Installation statt Docker

## Context
Initial wurde Ollama in einem Docker-Container ausgeliefert, um Plattform-Parität (macOS/Linux/Windows) zu erreichen. Auf macOS Apple Silicon ist die GPU dem Container jedoch nicht zugänglich — Inferenz lief CPU-only und war damit für 7B-Modelle 3–5× langsamer als ein nativer Lauf via Metal. Auf Linux/NVIDIA war der Containerpfad funktional, brachte aber gegenüber nativ keine messbare Geschwindigkeits-Differenz, kostete aber den `nvidia-container-toolkit`-Setup-Overhead.

Der Hauptzweck dieses Repos — schneller lokaler Dev-Loop und einfache RAG-Setups — wurde durch den CPU-only-Pfad auf der Mehrheits-Hardware (Apple-Silicon-Macbooks) ausgebremst.

## Decision
Native Installation von Ollama ist der einzige unterstützte Pfad. Docker wird als Lieferweg entfernt:
- `docker-compose.yml` und `docker-compose.gpu.yml` werden gelöscht.
- `.env.example` wird gelöscht — Env-Vars werden plattform-spezifisch über `launchctl setenv` (macOS) bzw. systemd-Drop-In (Linux) gesetzt.
- Helper-Skripte rufen `ollama` direkt auf, nicht mehr via `docker compose exec`.
- Installations-Pfade: `brew install ollama` (macOS), `curl … ollama.com/install.sh | sh` (Linux), nativer Installer (Windows).

## Rationale
- **Performance**: Metal auf Apple Silicon liefert auf der primären Zielhardware den entscheidenden Speed-up. Das war der ursprünglich akzeptierte Tradeoff von Docker; mit dem Wechsel ist er aufgehoben.
- **Komplexität ↓**: Ein einziger Lieferweg, kein Compose-Layering, kein GPU-Override, kein Volume-Mapping, kein Container-Healthcheck. Das Repo schrumpft auf README + Scripts.
- **API-Kompatibilität**: Ollamas REST-API ist in beiden Setups identisch — Consumer-Code (RAG-Pipelines, SDK-Clients) bleibt unverändert.
- **Daten-Migration einmalig**: Vorhandene Modelle aus dem Docker-Volume `ollama-data` lassen sich per `cp` ins Home-Verzeichnis migrieren (siehe README), ohne Re-Download.

## Consequences
- **Vorteile**: Schnellere Inferenz auf der Hauptzielhardware; weniger bewegliche Teile; einfacherer Onboarding-Pfad.
- **Nachteile / Tradeoffs**:
  - Plattform-Parität verschiebt sich vom Container auf den Paketmanager (brew vs. apt vs. Windows-Installer). Out-of-the-box-Identität geht teilweise verloren.
  - Process-Isolation des Containers entfällt — Ollama läuft als User- oder System-Service direkt auf dem Host.
  - Auto-Restart-Verhalten muss platformspezifisch konfiguriert werden (LaunchAgent / systemd) statt durch Compose `restart: unless-stopped`.
- **Repo-Auswirkungen**: [system-spec.md](../architecture/system-spec.md) und [architecture.md](../architecture/architecture.md) ändern Tech-Stack und Deployment-Surface; [CLAUDE.md](../../CLAUDE.md) und [README.md](../../README.md) müssen entsprechend angepasst werden.

## Alternatives Rejected
- **Parallel halten (Docker + nativ als gleichwertige Pfade)**: Verdoppelt die Wartungslast (zwei Skript-Versionen, zwei Konfigurations-Mechanismen, zwei Dokumentations-Pfade), ohne dass beide Pfade auf der Hauptzielhardware sinnvoll sind. Nativ allein deckt die Use-Cases ab.
- **Native Ollama nur auf macOS, Docker auf Linux**: Asymmetrie ohne Mehrwert — nativ funktioniert auf Linux genauso gut und der Install-Script setzt systemd selbständig auf.
- **Reverse-Proxy + Container für Multi-User-Hosting**: Out-of-Scope dieses Repos (system-spec.md schliesst Multi-User-/Produktivbetrieb explizit aus).
