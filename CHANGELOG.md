# Changelog

All notable changes to PathfinderLM will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Operator console.** A self-contained HTML dashboard at `/console` (live status,
  throughput, recent-requests table, in-browser ask box) backed by a new
  `/api/activity` JSON feed and an in-memory ring buffer (`app/activity.py`); `/ask`
  now records each request's status, latency, and retrieved-source count.
- **Coaching persona via Ollama system role + `Modelfile`.** New repo-root
  `Modelfile` (`pathfinder-coach`) and `make model` target; the persona is applied
  through the model's system role (configurable via `SYSTEM_PROMPT`) instead of
  being concatenated into the prompt.
- **Full `docs/` set**: `api_documentation.md` (live endpoint reference),
  `architecture.md`, `setup_guide.md`, `user_manual.md`, and
  `openclaw_integration.md`.
- **OpenClaw example integration** under `integrations/openclaw/`: a `/ask`
  wrapper (`ask_pathfinder.sh`), an example skill manifest (`skill.json`), and a
  README.
- **Codecov coverage badge** and a Tests badge in the README; the CI test job now
  fails on real test failures (removed the failure-swallowing fallback).

### Fixed
- CI **Docker Build & Scan** failed uploading the Trivy SARIF report
  (`Resource not accessible by integration`). Granted the job
  `security-events: write` and made the upload `continue-on-error`, so the pipeline
  is green and stays green if code scanning is disabled.

### Added (app stack)
- **Implemented the application code stack** (previously docs-only). New `app/`
  Flask package with an application factory, `POST /ask` (full RAG: Ollama
  embeddings → FAISS Top-K retrieval → context-augmented generation), `GET
  /health` (degraded-aware), `GET /metrics` (Prometheus), and a JSON API index.
- Ollama provider layer (`app/llm.py`) with a clearly-stubbed OpenAI fallback;
  shared client helper (`app/models/model.py`); FAISS retriever (`app/rag.py`)
  that degrades gracefully when no index exists; pre/post-processing utils
  (chunking, `<think>`-block stripping, answer formatting).
- `scripts/build_index.py` (knowledge base → FAISS index + doc sidecar) and
  `scripts/preprocess_data.py`.
- `configs/config.yaml` + `configs/logging.conf`.
- Offline-mocked `pytest` suite (`tests/`, 14 tests) that runs with no Ollama
  server, plus `pyproject.toml`, `setup.cfg`, and `.dockerignore`.
- Reconciled the smoke-test / CI import checks to the slimmed deps (flask,
  ollama, faiss).

### Changed
- **Repositioned to a local-first model stack.** Generation and embeddings now
  run on the [Ollama](https://ollama.com/) **0.22.1** runtime (default model
  `deepseek-r1:14b`, embeddings via `nomic-embed-text`), orchestrated by the
  [OpenClaw](https://openclaw.ai/) agent layer. OpenAI GPT-4 / HuggingFace
  Transformers are demoted to an optional cloud fallback.
- Updated README badges, Overview, Technology Stack, Configuration table,
  Acknowledgments, and all architecture diagrams (Mermaid + Graphviz `.dot`
  re-renders) to reflect the Ollama/OpenClaw stack.
- Slimmed `requirements.txt` to the `ollama` client + `faiss-cpu`; `torch`/
  `transformers`/`sentence-transformers` moved to a commented fallback block.
- Refreshed `mission.md` and `ground_game.md` setup/code examples for Ollama
  (Modelfile customization, Ollama Python client in the Flask example).

### Added
- **Real Docker assets** (previously referenced but missing): `Dockerfile` for
  the Flask app and `docker-compose.yml` with a GPU-enabled
  `ollama/ollama:0.22.1` service, persistent model volume, and health checks.
- Complete CI/CD pipeline with GitHub Actions
  - CI workflow (`.github/workflows/ci.yml`) for automated testing
  - CD workflow (`.github/workflows/cd.yml`) for deployment
- Comprehensive build automation with Makefile
  - Lint, test, security, and build targets
  - Docker build and run commands
  - Deployment commands for staging and production
- Bare metal deployment infrastructure
  - `scripts/setup_bare_metal.sh` - Initial server setup for Ubuntu 22.04
  - `scripts/deploy.sh` - Production deployment script with rollback
  - `scripts/smoke_test.sh` - Comprehensive smoke test suite
- Complete CI/CD documentation (`docs/CICD_GUIDE.md`)
  - Architecture diagrams
  - Deployment procedures
  - Troubleshooting guide
  - Best practices
- Production-ready configuration
  - `requirements.txt` - Python dependencies
  - `.gitignore` - Comprehensive ignore patterns
  - Systemd service configuration
  - Prometheus and Grafana monitoring
- Mermaid diagram fixes
  - Fixed rendering issues in `tree.md`
  - Fixed node references in `ellipsis/ellipsis.md`
  - Completely restructured `ellipsis/InformationAssuranceFramework.md`

### Changed
- Updated all mermaid diagrams to use proper syntax
- Improved diagram styling and readability

### Security
- Added security scanning with Bandit and Safety
- Configured UFW firewall rules
- Implemented Fail2Ban for intrusion prevention
- Added security headers validation in smoke tests
- Container vulnerability scanning with Trivy

### Infrastructure
- Ubuntu 22.04 LTS optimized deployment
- NVIDIA GPU driver support
- Docker and Docker Compose integration
- Systemd service management
- Automated backup and rollback mechanisms

## [0.1.0] - 2025-11-15

### Added
- Initial project structure
- Core documentation (README, mission, architecture)
- Information Assurance Framework
- Project structure and organization guidelines

---

## Version History Format

Each version should include:
- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** for vulnerability fixes
