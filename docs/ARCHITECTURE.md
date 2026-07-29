# GARI LANTERN OSS · Genesis Architecture

**Version:** 0.1.0-GENESIS  
**Case namespace:** `LSC-OR-CLATSOP-001`  
**Deployment:** GitHub repository + GitHub Actions + GitHub Pages  
**Posture:** public-source shadow research, no accusation authority

## 1. Senior Architect mandate

The Senior Architect translates institutional doctrine into executable constraints. The role owns system boundaries, schemas, trust zones, threat models, CI gates, deployment topology, failure recovery, acceptance tests and architecture decisions. The role does not decide whether a person or organization committed misconduct and cannot fabricate accounting, legal, privacy, factual or substantive approval.

## 2. Command-to-proof chain

```mermaid
flowchart LR
    A[Public source locator or preserved record] --> B[SourceRecord]
    B --> C[Canonical extraction]
    C --> D[Human-reviewed EntityRecord]
    C --> E[Typed MoneyEvent]
    D --> F[Claim candidate]
    E --> F
    F --> G[Fact / accounting / privacy / adversarial / legal gates]
    G -->|passed| H[Public release compiler]
    G -->|failed or incomplete| I[Blocked claim ledger]
    H --> J[Static JSON evidence bundle]
    J --> K[GitHub Pages]
    I --> L[Correction, more records, or closure]
```

## 3. Trust zones

| Zone | Meaning | Public build behavior |
|---|---|---|
| `candidate` | Machine-generated or unverified research lead | Always excluded |
| `canonical` | Human-reviewed internal record | Excluded unless explicitly promoted |
| `restricted` | Sensitive, legally constrained or source-protected material | Always excluded and build-blocking if marked public |
| `public` | Explicitly approved, non-sensitive record | Eligible for allowlisted compilation |

The release compiler uses an allowlist. It never copies a case directory wholesale.

## 4. Container boundaries

```mermaid
C4Container
    title GARI LANTERN Genesis containers
    Person(operator, "Investigator / researcher", "Creates and reviews structured evidence records")
    System_Boundary(github, "GitHub") {
        Container(repo, "Git repository", "Git + JSON + Python", "Governance ledger and canonical structured records")
        Container(actions, "GitHub Actions", "Python 3.12", "Validation, adversarial tests, schema generation, public compilation")
        Container(pages, "GitHub Pages", "Static HTML/CSS/JavaScript", "Read-only public evidence portal")
        Container(releases, "Artifacts / Releases", "ZIP / JSON / checksums", "Versioned proof outputs")
    }
    System_Ext(publicRecords, "Public record systems", "County, state, federal and nonprofit filing sources")

    Rel(operator, repo, "Submits bounded records and reviews through pull requests")
    Rel(publicRecords, operator, "Provides public records")
    Rel(repo, actions, "Triggers validation")
    Rel(actions, pages, "Deploys allowlisted static output after protected-main success")
    Rel(actions, releases, "Emits proof artifacts")
```

## 5. Canonical object model

- `CaseRecord`: mission boundary, jurisdiction, period and publication authority.
- `SourceRecord`: provenance, source limitations, amendment status and citation locations.
- `EntityRecord`: canonical identity, identifiers, resolution method and reviewer.
- `MoneyEvent`: typed financial event with flow lineage, source records and aggregation permissions.
- `OutcomeRecord`: metric definition, numerator, denominator, attribution class and comparability.
- `ClaimRecord`: exact sentence, support, contrary evidence, alternatives and review gates.
- `CorrectionRecord`: immutable original statement and append-only supersession chain.
- `ReleaseManifest`: commit, software versions, hashes and independent certificates.

## 6. Financial semantics

An amount is never sufficient by itself. Every `MoneyEvent` must state what the number means.

```text
award ≠ obligation ≠ outlay ≠ county receipt ≠ provider allocation
      ≠ reimbursement request ≠ payment ≠ reported expenditure
```

The validator rejects aggregation when:

- event types differ;
- currencies differ;
- no explicit aggregation group exists;
- one selected event is the parent of another selected event;
- any event lacks affirmative aggregation permission.

## 7. AI authority ceiling

GARI may suggest extraction candidates, entity candidates, discrepancies, searches and alternative explanations. `ai_candidate` claims cannot enter public output. AI cannot merge identities, classify illegality, certify accounting, approve publication or alter corrections.

## 8. Publication boundary

The Genesis public portal may show:

- the bounded case mission;
- resolved public entities;
- typed official award or allocation summaries;
- source limitations;
- publication authority;
- the no-misconduct notice;
- methodology and corrections.

It may not show:

- unresolved identities;
- blocked claims;
- confidential tips;
- client-level HMIS or health information;
- internal investigator notes;
- high-risk allegations without every gate;
- a corruption score, fraud probability or suspicion leaderboard.

## 9. GitHub control plane

```mermaid
flowchart TD
    PR[Pull request] --> CI[Command to Proof CI]
    CI --> L[Lint]
    CI --> T[Type check]
    CI --> A[Adversarial tests]
    CI --> S[Schema generation]
    CI --> V[Case validation]
    CI --> P[Public-boundary compiler]
    CI --> Q[Prohibited-field scan]
    L --> PASS{All pass?}
    T --> PASS
    A --> PASS
    S --> PASS
    V --> PASS
    P --> PASS
    Q --> PASS
    PASS -->|no| BLOCK[Merge and deployment blocked]
    PASS -->|yes, protected main| DEPLOY[Pages deployment workflow]
```

## 10. Failure modes and responses

| Failure | Required behavior |
|---|---|
| Source changes after acquisition | Preserve prior version and create a source-conflict record |
| Entity identity becomes disputed | Demote match status and remove affected public claims |
| Award confused with payment | Validation failure and correction review |
| Client-level field enters data | Public build fails immediately |
| AI output promoted directly | Public build fails immediately |
| New evidence changes a claim | Preserve original statement and append correction |
| CI fails | No Pages deployment |
| GitHub unavailable | Canonical plain files remain locally reproducible after clone |

## 11. Genesis limitations

- Source files are not yet preserved in an immutable evidence vault; current fixture hashes identify source locator manifests and disclose that limitation.
- No independent forensic accountant, fact checker, privacy officer or Oregon publication counsel has certified the Clatsop claims.
- No final reimbursement, payment, expenditure, utilization or outcome records are represented.
- GitHub Pages is a public static surface, not a confidential research environment.
- Genesis is a working governance kernel and public portal, not a completed institutional audit.

## 12. Promotion path

1. Pass all repository CI and security checks.
2. Preserve complete primary documents and cryptographic hashes.
3. Complete the manual Clatsop shadow case.
4. Add independent role reviews.
5. Add release manifests and correction simulations.
6. Only then consider jurisdiction adapters, automated public ingestion and broader deployments.
