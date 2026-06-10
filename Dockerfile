# PathfinderLM — application image
# Local-first by default: generation + embeddings run on a separate Ollama
# container (see docker-compose.yml). This image only contains the Flask app
# and a lightweight Ollama HTTP client — no torch/transformers needed for the
# default path.
FROM python:3.10-slim

# System deps (build tools for faiss/numpy wheels, curl for healthchecks)
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies first for better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application
COPY . .

# Flask
EXPOSE 5000

# The app talks to the Ollama service over the compose network.
ENV OLLAMA_HOST=http://ollama:11434 \
    LLM_PROVIDER=ollama \
    MODEL_NAME=deepseek-r1:14b \
    EMBEDDING_MODEL=nomic-embed-text \
    FLASK_PORT=5000 \
    PYTHONUNBUFFERED=1

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:5000/health || exit 1

CMD ["python3", "app/main.py"]
