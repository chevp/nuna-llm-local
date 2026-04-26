# System Spec — nuna-llm-local

## Was ist das System
Ein reproduzierbares lokales LLM-Setup auf Basis von [Ollama](https://ollama.com/), nativ auf dem Host installiert. Ziel: schneller Dev-Loop und einfache RAG-Setups, mit GPU-Beschleunigung (Metal auf Apple Silicon, CUDA auf Linux/NVIDIA), ohne Cloud-LLM-Abhängigkeit.

> **Architektur-Wechsel (2026-04-25)**: Dieses Repo lieferte ursprünglich einen Docker-basierten Stack. Mit [ADR-001](../adr/ADR-001-native-install-instead-of-docker.md) wurde auf native Installation umgestellt — siehe ADR für die Begründung.

## Komponenten
| Komponente | Zweck | Quelle |
|---|---|---|
| Ollama (nativ) | LLM-Runtime + HTTP-API auf `localhost:11434` | Paketmanager (brew / install.sh / Windows-Installer) |
| Service-Wrapper | Auto-Start: LaunchAgent (macOS) bzw. systemd-Unit (Linux) | Vom Installer angelegt |
| Modell-Storage | Persistenz der gepullten Modelle | `~/.ollama/` (macOS, Linux-User) bzw. `/usr/share/ollama/.ollama/` (Linux-systemd) |
| Helper-Skripte | Modell-Pull, Smoke-Test, RAG-Setup | [scripts/](../../scripts/) |
| Docs-Site | Nutzerdokumentation via GitHub Pages | [docs/](../../docs/) |

## Wer wird bedient
- **Primärer Nutzer**: Entwickler auf Apple Silicon (M-Serie), die lokal mit GPU-beschleunigten LLMs experimentieren oder offline arbeiten.
- **Sekundär**: Linux-Nutzer (mit oder ohne NVIDIA-GPU) und Windows-Nutzer, die denselben Workflow wollen.
- **Nicht-Ziel**: Multi-User-Hosting, Produktivbetrieb, Authentifizierung, Rate-Limiting, Telemetrie.

## Erfolgskriterien
- Frische Installation (Paketmanager) bringt Ollama in <2 min lauffähig auf den Host.
- Ein gepulltes 7B-Modell antwortet via HTTP-API in <2 s auf Apple Silicon (Metal).
- Modelle bleiben über Reboots erhalten (User-Home bzw. systemd-Pfad).
- API-Surface (`/api/generate`, `/api/chat`, `/api/embeddings`) ist plattformübergreifend identisch.

## Annahmen / Constraints
- Ollama-Service hört per Default auf `localhost:11434`. Für Remote-Zugriff explizit `OLLAMA_HOST=0.0.0.0` setzen — nicht für öffentliche Hosts gedacht.
- Modell-Storage liegt im Home (User-Service) bzw. unter `/usr/share/ollama` (Linux-systemd-Service-User). Plattenplatz: ~4 GB pro 7B-q4-Modell.
- Keine Authentifizierung im Repo-Scope — wer Production will, baut einen Reverse-Proxy davor (anderes Repo).

## Komponenten-Diagramm (logisch)
```
Host
 ├── Ollama (Service: LaunchAgent / systemd)
 │    ├── HTTP API → localhost:11434
 │    └── Modell-Storage → ~/.ollama (bzw. /usr/share/ollama/.ollama)
 └── GPU
      ├── macOS: Metal (Apple Silicon, automatisch)
      └── Linux: CUDA (via NVIDIA-Treiber, automatisch erkannt)
```

## Out of Scope
- Modell-Fine-Tuning
- Vektordatenbank / RAG-Pipeline-Code (nur Embedding-Modell wird bereitgestellt)
- UI/Chat-Frontend
- Multi-Tenant- oder Auth-Layer
- Container-/Compose-basierter Lieferweg (siehe [ADR-001](../adr/ADR-001-native-install-instead-of-docker.md))
