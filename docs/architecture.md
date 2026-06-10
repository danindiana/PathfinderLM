# PathfinderLM Architecture

PathfinderLM is a **local-first** RAG life-coach: language models run on your own
hardware via [Ollama](https://ollama.com/) 0.22.1, retrieval is backed by FAISS,
and the [OpenClaw](https://openclaw.ai/) agent layer can drive it. Cloud models
(OpenAI GPT-4) are an optional, currently-stubbed fallback.

## Components

| Layer | Module / asset | Responsibility |
|-------|----------------|----------------|
| HTTP API | `app/__init__.py`, `app/routes/` | Flask app factory; `/`, `/health`, `/ask`, `/metrics` |
| Config | `app/config.py`, `configs/config.yaml` | Env/.env/YAML resolution with defaults |
| LLM | `app/llm.py`, `app/models/model.py` | Provider dispatch (Ollama; OpenAI stub); Ollama client |
| RAG | `app/rag.py`, `scripts/build_index.py` | Embeddings + FAISS retrieval; index builder |
| Utils | `app/utils/` | Chunking, `<think>`-stripping, answer formatting, logging |
| Runtime | `Dockerfile`, `docker-compose.yml` | App image + `ollama/ollama:0.22.1` service |

## Request flow (`POST /ask`)

```
client → /ask (app/routes/ask.py)
            │
            ├─ Retriever.retrieve(question)        app/rag.py
            │     └─ embed(question) → FAISS Top-K  (skipped if no index)
            │
            ├─ build prompt = context + question
            ├─ llm.generate(prompt, system=persona) app/llm.py → Ollama
            └─ format_answer() (strip <think>)      app/utils/postprocessing.py
                  → {answer, sources, model}
```

The coaching persona is applied via the model's **system role** (see the
repo-root [`Modelfile`](../Modelfile) and `SYSTEM_PROMPT`), keeping retrieval and
question text in the prompt and personality in the system message.

## Diagrams

Rendered architecture diagrams (Mermaid in the [README](../README.md#architecture)
and Graphviz exports in [`diagrams/`](../diagrams/)):

- [System architecture](../diagrams/system_architecture.png)
- [RAG pipeline](../diagrams/rag_pipeline.png)
- [Deployment architecture](../diagrams/deployment_architecture.png)

## Design notes

- **Graceful degradation:** `/health` stays 200 when Ollama is down or no index
  exists; `/ask` still answers (without retrieval) so the app is usable pre-index.
- **Single client chokepoint:** all Ollama access goes through
  `app/models/model.get_client()`, which makes the suite trivially mockable
  (`tests/conftest.py`) and keeps it offline in CI.
- **Local-first privacy:** no data leaves the host on the default path.
