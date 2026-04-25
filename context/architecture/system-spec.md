# System Spec — nuna-llm-local

## Was ist das System
Ein reproduzierbares lokales LLM-Setup auf Basis von [Ollama](https://ollama.com/), gestartet über Docker Compose. Ziel: identische Dev-/Prod-Erfahrung über Linux, macOS und Windows hinweg, ohne Abhängigkeit von Cloud-LLM-APIs.

## Komponenten
| Komponente | Zweck | Quelle |
|---|---|---|
| `ollama` Container | LLM-Runtime + HTTP-API auf Port 11434 | [docker-compose.yml](../../docker-compose.yml) |
| `ollama-data` Volume | Persistenz der gepullten Modelle | docker-compose.yml |
| GPU-Override | NVIDIA-GPU-Mapping für Linux-Hosts | [docker-compose.gpu.yml](../../docker-compose.gpu.yml) |
| `.env` | Tunables (Port, Keep-Alive, Max Loaded Models) | [.env.example](../../.env.example) |
| Helper-Skripte | Modell-Pull, Smoke-Test, RAG-Setup | [scripts/](../../scripts/) |
| Docs-Site | Nutzerdokumentation via GitHub Pages | [docs/](../../docs/) |

## Wer wird bedient
- **Primärer Nutzer**: Entwickler auf Apple Silicon (M-Serie) oder Linux-Workstations, die lokal mit LLMs experimentieren oder offline arbeiten.
- **Sekundär**: Nutzer mit NVIDIA-GPU unter Linux, die Inferenz beschleunigen wollen.
- **Nicht-Ziel**: Multi-User-Hosting, Produktivbetrieb, Authentifizierung, Rate-Limiting, Telemetrie.

## Erfolgskriterien
- `docker compose up -d` startet den Service in <30 s auf einem aktuellen Macbook (M-Serie).
- Ein gepulltes 7B-q4-Modell antwortet via HTTP-API innerhalb weniger Sekunden.
- Modelle bleiben zwischen Restarts erhalten (Volume).
- GPU-Pfad funktioniert unter Linux ohne Änderung der Basis-Compose-Datei.

## Annahmen / Constraints
- Apple-GPU ist Docker nicht zugänglich → macOS = CPU-only (q4-Modelle bevorzugen).
- Ollama-API (`/api/generate`, `/api/embeddings`) wird unverändert exponiert; kein Reverse-Proxy.
- Keine Authentifizierung — Service hört auf `0.0.0.0:11434` im Container, gemappt auf den Host. Nicht für öffentliche Hosts gedacht.

## Komponenten-Diagramm (logisch)
```
Host
 └── Docker
      └── ollama (Container)
           ├── Port 11434 → Host:${OLLAMA_PORT}
           ├── Volume ollama-data → /root/.ollama
           └── GPU (optional, Linux/NVIDIA via Override)
```

## Out of Scope
- Modell-Fine-Tuning
- Vektordatenbank / RAG-Pipeline-Code (nur Embedding-Modell wird bereitgestellt)
- UI/Chat-Frontend
- Multi-Tenant- oder Auth-Layer
