# PathfinderLM Setup Guide

Three ways to run PathfinderLM: local (venv), Docker Compose, or bare-metal.
All paths are local-first — models run on your own hardware via Ollama 0.22.1.

## Prerequisites

- Python 3.10+
- [Ollama](https://ollama.com/) (native install) **or** Docker + the NVIDIA
  Container Toolkit for the GPU compose path
- The models, pulled once:
  ```bash
  ollama pull deepseek-r1:14b     # generation (or a lighter tag, e.g. deepseek-r1:8b)
  ollama pull nomic-embed-text    # embeddings
  ```

## Option A — Local (venv)

```bash
git clone https://github.com/danindiana/PathfinderLM.git
cd PathfinderLM
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env              # then edit; set OLLAMA_HOST=http://localhost:11434

# Build the retrieval index from the seed corpus (data/processed/)
python scripts/build_index.py

# Run the API
python app/main.py
```

Verify:

```bash
curl -s http://localhost:5000/health
curl -s -X POST http://localhost:5000/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "How do I beat procrastination?"}'
```

## Option B — Docker Compose

```bash
cp .env.example .env

# Start Ollama and pull models (first run only)
docker compose up -d ollama
docker compose exec ollama ollama pull deepseek-r1:14b
docker compose exec ollama ollama pull nomic-embed-text

# Build & run the app
docker compose up --build app
```

The app is on `http://localhost:5000`, Ollama on `http://localhost:11434`. Models
persist in the `ollama_models` volume.

## Option C — Bare metal

`scripts/setup_bare_metal.sh` provisions an Ubuntu 22.04 host (packages, Python,
Docker, optional NVIDIA drivers, UFW, Fail2Ban) and `scripts/deploy.sh` installs a
systemd service. See [CICD_GUIDE.md](CICD_GUIDE.md) for the deployment pipeline.

## Optional — custom coaching model

Bake the persona + sampling into a named model:

```bash
make model            # ollama create pathfinder-coach -f Modelfile
export MODEL_NAME=pathfinder-coach
```

## Adding your own knowledge

1. Drop `.txt`/`.md` files into `data/processed/` (or raw files into `data/raw/`
   and run `python scripts/preprocess_data.py`).
2. Rebuild the index: `python scripts/build_index.py`.
3. Restart the app — `/health` should show `"index": true` and `/ask` answers will
   cite `sources`.

## Running the tests

```bash
pip install pytest pytest-cov
make test            # offline; the Ollama client is mocked
```
