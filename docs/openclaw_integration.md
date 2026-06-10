# Integrating PathfinderLM with OpenClaw

[OpenClaw](https://openclaw.ai/) is a local-first personal-AI agent ("the AI that
actually does things") reachable from chat apps like WhatsApp, Telegram, Discord,
Slack, Signal, and iMessage. PathfinderLM composes with OpenClaw in two
complementary ways.

## 1. Shared local runtime

Both PathfinderLM and OpenClaw can use the **same local Ollama runtime**. Point
OpenClaw's model configuration at the same endpoint PathfinderLM uses:

```
OLLAMA_HOST=http://localhost:11434
```

This keeps everything local — no data leaves the host — and lets the same pulled
models (`deepseek-r1:14b`, `nomic-embed-text`) serve both systems.

## 2. PathfinderLM as an OpenClaw skill/tool

Expose PathfinderLM's RAG-grounded coaching to OpenClaw as a **skill** that calls
the `/ask` API. A runnable example lives in
[`integrations/openclaw/`](../integrations/openclaw/):

- `ask_pathfinder.sh` — a small wrapper that POSTs a question to `/ask` and prints
  the coached answer. OpenClaw (which has shell access) can invoke it directly.
- `skill.json` — an example OpenClaw skill manifest describing the tool, so it can
  be dropped into an OpenClaw skills directory.
- `README.md` — install/use instructions.

### Quick test (no OpenClaw required)

With the PathfinderLM API running on `http://localhost:5000`:

```bash
integrations/openclaw/ask_pathfinder.sh "How do I start a new habit?"
```

```bash
# Or directly:
curl -s -X POST http://localhost:5000/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I start a new habit?"}' | jq -r .answer
```

### Wiring it into OpenClaw

1. Install OpenClaw: `curl -fsSL https://openclaw.ai/install.sh | bash`
   (see [docs.openclaw.ai](https://docs.openclaw.ai/)).
2. Copy `integrations/openclaw/` into your OpenClaw skills directory (or point the
   skill manifest at this repo).
3. Set `PATHFINDER_URL` if the API is not on `http://localhost:5000`.
4. Ask OpenClaw something like *"use the pathfinder coach to help me plan my
   week"* — it will call the skill and relay the answer.

## Status

This is an **example integration** to make the agent-layer story concrete. The
shell wrapper and skill manifest are intentionally minimal; adapt them to your
OpenClaw version's skill format. The `OPENCLAW_ENABLED` flag in
[`.env.example`](../.env.example) is a placeholder for app-side toggles you may add.
