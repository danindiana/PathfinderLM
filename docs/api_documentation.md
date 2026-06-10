# PathfinderLM API Documentation

The PathfinderLM Flask app exposes a small JSON API. Base URL in development:
`http://localhost:5000`.

All request and response bodies are JSON (`Content-Type: application/json`).

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET`  | `/`        | API index (name + endpoint list) |
| `GET`  | `/health`  | Liveness/readiness with subsystem status |
| `POST` | `/ask`     | Ask a coaching question (RAG-grounded) |
| `GET`  | `/metrics` | Prometheus metrics |

---

### `GET /`

Returns a small self-describing index.

```bash
curl -s http://localhost:5000/
```

```json
{
  "name": "PathfinderLM",
  "description": "Local-first RAG life-coach API (Ollama + OpenClaw).",
  "endpoints": {
    "GET /health": "Liveness/readiness with subsystem status.",
    "POST /ask": "Ask a coaching question. Body: {\"question\": str, \"context\"?: str}.",
    "GET /metrics": "Prometheus metrics."
  }
}
```

---

### `GET /health`

Always returns **200** once Flask is up, even if a subsystem is degraded — this is
what the Docker `HEALTHCHECK` relies on. Inspect the body for actual status.

```bash
curl -s http://localhost:5000/health
```

```json
{
  "status": "ok",
  "provider": "ollama",
  "model": "deepseek-r1:14b",
  "ollama": true,
  "index": true
}
```

| Field | Meaning |
|-------|---------|
| `status` | Always `"ok"` if the process is serving |
| `provider` | Configured `LLM_PROVIDER` |
| `model` | Configured `MODEL_NAME` |
| `ollama` | Whether the Ollama runtime is reachable |
| `index` | Whether a FAISS index exists at `FAISS_INDEX_PATH` |

---

### `POST /ask`

Answers a coaching question. If a FAISS index is present, the question is embedded
(Ollama), the Top-K most similar knowledge-base chunks are retrieved and injected
as context, and the configured model generates a grounded answer. The coaching
persona is applied via the system role (see [`Modelfile`](../Modelfile) /
`SYSTEM_PROMPT`). `<think>…</think>` reasoning blocks are stripped from the answer.

**Request**

```json
{
  "question": "How can I improve my productivity?",
  "context": "I struggle with time management and procrastination."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `question` | string | yes | The user's question. Empty/missing → 400. |
| `context`  | string | no  | Extra caller-supplied context, merged with retrieved docs. |

```bash
curl -s -X POST http://localhost:5000/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How can I improve my productivity?",
       "context": "I struggle with time management."}'
```

**Response — 200**

```json
{
  "answer": "Start by time-boxing your work into focused 25-minute blocks...",
  "sources": ["The Pomodoro Technique: work in focused 25-minute intervals..."],
  "model": "deepseek-r1:14b"
}
```

| Field | Type | Notes |
|-------|------|-------|
| `answer` | string | The coaching response (reasoning blocks removed). |
| `sources` | string[] | Retrieved knowledge-base chunks used as context (may be empty). |
| `model` | string | The model that produced the answer. |

**Status codes**

| Code | When |
|------|------|
| `200` | Success |
| `400` | `question` missing or empty |
| `501` | `LLM_PROVIDER=openai` (cloud fallback is a stub — not implemented) |
| `502` | LLM backend unavailable (e.g. Ollama not running) |

---

### `GET /metrics`

Prometheus exposition format (default process/HTTP metrics via
`prometheus_client`). Scrape it from Prometheus or:

```bash
curl -s http://localhost:5000/metrics | head
```

---

## Configuration

Behaviour is controlled by environment variables (see the
[Configuration table in the README](../README.md#configuration) and
[`.env.example`](../.env.example)). The most relevant for the API:

| Variable | Default | Effect |
|----------|---------|--------|
| `MODEL_NAME` | `deepseek-r1:14b` | Generation model (set to `pathfinder-coach` to use the Modelfile persona) |
| `EMBEDDING_MODEL` | `nomic-embed-text` | Embedding model for retrieval |
| `OLLAMA_HOST` | `http://ollama:11434` | Ollama endpoint (`http://localhost:11434` outside Docker) |
| `FAISS_INDEX_PATH` | `results/faiss.index` | Index loaded at startup |
| `TOP_K` | `5` | Documents retrieved per query |
| `SYSTEM_PROMPT` | _(coaching persona)_ | Overrides the system role text |
| `LLM_PROVIDER` | `ollama` | `ollama` or `openai` (stub) |

## Building the retrieval index

`/ask` works without an index (it simply skips retrieval). To enable grounding,
populate `KNOWLEDGE_BASE_DIR` and build the index:

```bash
python scripts/build_index.py
```

See [setup_guide.md](setup_guide.md) for the full walkthrough.
