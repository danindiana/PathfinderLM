# Security Policy

PathfinderLM handles sensitive, personal, and potentially health-related data.
We take security and privacy seriously and appreciate responsible disclosure.

## Supported Versions

The project is in pre-alpha. Security fixes are applied to the `main` branch.

| Version | Supported |
|---------|-----------|
| `main` (development) | ✅ |
| Tagged pre-releases | ⚠️ best-effort |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues,
discussions, or pull requests.**

Instead, use one of the following private channels:

1. **GitHub Security Advisories** — preferred. Open a private advisory at
   <https://github.com/danindiana/PathfinderLM/security/advisories/new>.
2. **Direct contact** — reach the maintainer (`danindiana` on GitHub).

Please include:

- A description of the vulnerability and its impact
- Steps to reproduce (proof-of-concept if possible)
- Affected component(s), versions, and configuration
- Any suggested remediation

## What to Expect

- **Acknowledgement** within 72 hours.
- **Assessment & triage** with a severity rating (CVSS where applicable).
- **Coordinated disclosure** — we will agree on a timeline before any public
  disclosure and credit you (if you wish) in the changelog.

## Scope

In scope: authentication/authorization flaws, data exposure, injection,
insecure deserialization, RAG prompt-injection leading to data exfiltration,
container/deployment misconfiguration in shipped scripts.

Out of scope: issues requiring physical access, social engineering, or
vulnerabilities in third-party dependencies already tracked upstream (report
those to the respective project, and feel free to open a normal issue to bump
the pin).

## Hardening Notes

- Secrets live in `.env` / a secrets manager, never in source control.
- The deployment scripts configure UFW and Fail2Ban; review before production.
- Run `make security` (bandit + safety) before each release.
