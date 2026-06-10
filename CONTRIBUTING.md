# Contributing to PathfinderLM

Thanks for your interest in improving PathfinderLM! This document explains how to
get set up, the standards we hold code to, and how to submit changes.

By participating, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Ways to Contribute

- 🐛 **Report bugs** via [GitHub Issues](https://github.com/danindiana/PathfinderLM/issues)
- 💡 **Propose features** or discuss ideas in [Discussions](https://github.com/danindiana/PathfinderLM/discussions)
- 📝 **Improve documentation** — typos, clarifications, and examples are all welcome
- 🔧 **Submit code** — see the workflow below

## Development Setup

```bash
# 1. Fork & clone
git clone https://github.com/<you>/PathfinderLM.git
cd PathfinderLM

# 2. Create a virtual environment
python3 -m venv .venv && source .venv/bin/activate

# 3. Install dev dependencies (pytest, black, isort, flake8, pylint, mypy, bandit)
make install-dev

# 4. Copy the environment template
cp .env.example .env
```

## Before You Open a PR

Run the full quality gate locally — CI runs the same checks:

```bash
make format    # auto-format (black + isort)
make lint      # flake8 + pylint + mypy
make test      # pytest
make security  # bandit + safety
```

Or run everything at once:

```bash
make all
```

## Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org). Format:

```
<type>(<optional scope>): <description>
```

Common types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`,
`ci`, `perf`, `security`.

Examples:

```
feat(rag): add top-k re-ranking with cross-encoder
fix(auth): handle expired JWT gracefully
docs(readme): document DEVICE env var
```

## Pull Request Checklist

- [ ] Branch is up to date with `main`
- [ ] `make all` passes locally
- [ ] New/changed behavior is covered by tests
- [ ] Documentation updated where relevant
- [ ] Commits follow Conventional Commits
- [ ] PR description explains the *why*, not just the *what*

## Code Style

- **Python:** formatted with `black`, imports sorted with `isort`, linted with
  `flake8`/`pylint`, type-checked with `mypy`.
- **Line length:** 88 (black default).
- **Security:** no secrets in code or history; `.env` is git-ignored.

## Reporting Security Issues

Please **do not** file public issues for vulnerabilities. Follow the process in
[SECURITY.md](SECURITY.md).

## License

By contributing, you agree that your contributions will be licensed under the
[Apache License 2.0](LICENSE).
