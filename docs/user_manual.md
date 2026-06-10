# PathfinderLM User Manual

PathfinderLM is a personal life-coaching assistant. You ask questions about your
goals; it responds with warm, practical, evidence-based guidance grounded in a
knowledge base you control.

> ⚠️ **Not a medical or mental-health service.** PathfinderLM is an educational
> self-improvement tool. It does not provide medical, psychological, or
> addiction-treatment advice. In a crisis, contact a licensed professional or your
> local emergency services.

## Asking a question

Send a question to the `/ask` endpoint:

```bash
curl -s -X POST http://localhost:5000/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How can I build a consistent morning routine?"}'
```

You can add personal `context` to tailor the answer:

```bash
curl -s -X POST http://localhost:5000/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I stay motivated?",
       "context": "I work night shifts and have low energy in the mornings."}'
```

The reply includes the `answer`, the `sources` it drew on (if any), and the
`model` used.

## What the coach is good at

- Goal setting and breaking big goals into small next steps
- Habit formation and beating procrastination
- Stress-management techniques and daily reflection
- Drawing on the documents you add to its knowledge base

## What it will not do

- Replace professional medical, legal, or financial advice
- Make decisions for you — it offers options and encouragement
- Access the internet or your private data (it runs locally)

## Personalising the coach

- **Add knowledge:** put `.txt`/`.md` files in `data/processed/` and rebuild the
  index (`python scripts/build_index.py`). Future answers will cite them.
- **Change the persona:** edit the [`Modelfile`](../Modelfile) (or set
  `SYSTEM_PROMPT`) and rebuild with `make model`.

## Using it through OpenClaw

PathfinderLM can be driven by the [OpenClaw](https://openclaw.ai/) agent so you can
chat from WhatsApp, Telegram, Discord, etc. See
[openclaw_integration.md](openclaw_integration.md).
