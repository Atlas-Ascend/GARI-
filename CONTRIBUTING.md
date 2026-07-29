# Contributing to GARI LANTERN

GARI LANTERN accepts code, methodology, public-record pointers, corrections and nonconfidential research questions.

## Never submit

- client-level HMIS records;
- medical, behavioral-health or substance-use records;
- Social Security numbers or benefit-account data;
- domestic-violence shelter locations;
- confidential whistleblower material;
- stolen, privileged or access-controlled documents;
- accusations without a source-backed claim packet.

## Development setup

Requirements:

- Python 3.12+
- Git
- GitHub CLI for publication workflows

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -e '.[dev]'
lantern generate-schema
lantern validate LSC-OR-CLATSOP-001
pytest -q
lantern build-public LSC-OR-CLATSOP-001
python -m http.server 8000 --directory site
```

Windows PowerShell users may run `./scripts/bootstrap.ps1`.

## Change classes

### Code change

Include tests and explain which architectural boundary is affected.

### Source addition

State the custodian, jurisdiction, acquisition method, amendment status, limitations and exact case relevance. A URL is not an immutable archive.

### Entity change

Provide identifiers and supporting sources. Never infer ownership, control or family relationship from a shared address or name alone.

### Money-event change

Classify the event precisely. Award, obligation, outlay, payment and expenditure are not synonyms.

### Claim change

Write the exact sentence. Include supporting sources, contrary material, alternative explanations and required review states.

### Correction

Preserve the original statement. Do not overwrite history.

## Pull requests

Use a focused branch. Pull requests must answer:

- Which case is affected?
- Are entities added, merged, split or disputed?
- Are money-event types or aggregation rules changed?
- Are claims or corrections changed?
- Does public output change?
- Could restricted or personal data enter the build?
- Which tests prove the change?
- Which independent reviewer roles are required?

CI failure blocks merge and deployment.

## Conduct

Challenge conclusions hard. Treat people carefully. Do not harass subjects, contributors, clients, workers or community members. The project exists to improve public truth, not to create a digital punishment arena.
