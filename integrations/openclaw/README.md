# PathfinderLM × OpenClaw — example integration

A minimal, runnable example that exposes PathfinderLM's `/ask` coaching API to the
[OpenClaw](https://openclaw.ai/) agent as a skill. See the full write-up in
[`docs/openclaw_integration.md`](../../docs/openclaw_integration.md).

## Files

| File | Purpose |
|------|---------|
| `ask_pathfinder.sh` | POSTs a question to the PathfinderLM API and prints the answer. |
| `skill.json` | Example OpenClaw skill manifest pointing at the wrapper. |

## Prerequisites

- The PathfinderLM API running (default `http://localhost:5000` — see
  [`docs/setup_guide.md`](../../docs/setup_guide.md)).
- `curl` and `jq` installed.

## Use it standalone

```bash
chmod +x ask_pathfinder.sh
./ask_pathfinder.sh "How do I build a consistent morning routine?"

# Point at a non-default API:
PATHFINDER_URL=http://192.168.1.85:5000 ./ask_pathfinder.sh "How do I stay focused?"
```

## Use it from OpenClaw

1. Install OpenClaw (`curl -fsSL https://openclaw.ai/install.sh | bash`).
2. Copy this directory into your OpenClaw skills location, or register `skill.json`
   per your OpenClaw version's docs ([docs.openclaw.ai](https://docs.openclaw.ai/)).
3. Ask OpenClaw, e.g. *"use the pathfinder coach to help me plan my week."*

> This is an example. OpenClaw's skill schema may differ across versions — adjust
> `skill.json` field names accordingly.
