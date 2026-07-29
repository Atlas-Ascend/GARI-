# GARI LANTERN OSS

**Command-to-proof infrastructure for public institutional financial accountability.**

GARI LANTERN is an open-source evidence system for reconstructing public funding flows, contracts, institutional identities, reported outcomes, exact claims, disputes and corrections without converting uncertainty into accusation.

> **Genesis boundary:** no misconduct finding, no confidential intake, no client-level data, no corruption score and no autonomous publication.

## Active pilot

`LSC-OR-CLATSOP-001` examines the public funding path surrounding Clatsop County, Astoria, Clatsop Community Action and Columbia Inn for FY 2024-25.

The pilot asks:

> What public funds supported Columbia Inn, what obligations accompanied them, what amounts were authorized, reimbursed, paid and reported as spent, what outcomes were required, and what remains unknown?

Inclusion in the case does not imply waste, fraud, self-dealing, misuse of funds or any other misconduct.

## What exists in Genesis

- Typed Pydantic evidence models
- Public-source provenance registry
- Human-reviewed entity model
- Financial event ontology separating awards, allocations, payments and expenditures
- Claim ledger with independent review gates
- Append-only correction model
- Explicit `candidate`, `canonical`, `restricted` and `public` trust zones
- Public-release compiler using an allowlist
- Adversarial tests for unsafe publication paths
- Static evidence portal for GitHub Pages
- GitHub Actions CI, security scanning and gated Pages deployment
- One-command PowerShell bootstrap
- Clatsop County / Astoria demonstration fixture

## Command-to-proof sequence

```text
public record
→ provenance record
→ canonical extraction
→ human-reviewed identity
→ typed money event
→ exact claim
→ factual / accounting / adversarial / privacy / legal gates
→ allowlisted public bundle
→ GitHub Pages
→ permanent correction history
```

## What the software refuses

- Unresolved entities in public output
- AI candidate claims in public output
- Restricted records in the Pages artifact
- Parent awards added to their child allocations
- Incompatible money-event aggregation
- Client-level HMIS, medical or shelter-history fields
- High-risk findings without heightened review
- Quiet deletion of corrected statements
- Fraud scores, corruption rankings and suspicion leaderboards

## Quick start

### Windows PowerShell

```powershell
./scripts/bootstrap.ps1
```

### Cross-platform

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -e '.[dev]'
ruff check .
mypy
pytest -q
lantern generate-schema
lantern validate LSC-OR-CLATSOP-001
lantern build-public LSC-OR-CLATSOP-001
python -m http.server 8000 --directory site
```

Then open `http://localhost:8000`.

## Core CLI

```text
lantern validate CASE_ID
lantern case-status CASE_ID
lantern generate-schema
lantern build-public CASE_ID
lantern release-check CASE_ID
```

Every validation or release command exits nonzero when a proof gate fails.

## Repository map

```text
lantern/        typed models, validators and CLI
cases/          bounded canonical case records
site/           static public portal
schemas/        generated JSON Schema output
_tests/         adversarial and regression intent
.github/        CI, security and Pages delivery
scripts/        operator bootstrap
_docs/          architecture and governance doctrine
```

The actual folders are `tests/` and `docs/`; the leading underscores above visually separate explanatory entries from command paths.

## Financial semantics

Dollar values cannot be combined merely because they are denominated in dollars.

```text
award ≠ obligation ≠ outlay ≠ receipt ≠ allocation
      ≠ reimbursement request ≠ payment ≠ expenditure
```

Every money event carries a type, period, flow ID, source, verification state and interpretation limit.

## AI authority ceiling

GARI may suggest extractions, matches, discrepancies, searches and alternative explanations. It may not merge entities, certify accounting, decide criminality, approve a claim or publish autonomously.

## Public website

The repository contains a static site designed for GitHub Pages. The deploy workflow:

1. checks out protected `main`;
2. validates the bounded case;
3. compiles only explicitly approved `public` records;
4. uploads the `site/` directory;
5. deploys through the `github-pages` environment.

Raw case folders are never copied directly into the website.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Governance](docs/GOVERNANCE.md)
- [Security](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Data licensing](DATA-LICENSE.md)

## License

Original software is licensed under `AGPL-3.0-or-later`. Original documentation is intended for CC BY 4.0 reuse subject to third-party rights. Public records and external datasets retain their own legal conditions.

## Current proof state

Genesis establishes a working governance kernel, public compiler, tests and website source. It does **not** establish final reimbursements, provider expenditures, utilization, housing outcomes, audit findings, related-party transactions or misconduct in Clatsop County.

The standard is not “we found something.”

The standard is:

> **A hostile reviewer tried to break the finding and the receipts held.**
