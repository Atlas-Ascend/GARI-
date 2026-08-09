# FTS UNIVERSAL AUDIT CONSTITUTION

**Constitution ID:** `FTS-UAC-001`  
**Parent:** Full Transparency Systems / GARI  
**Campaign role:** Domain-agnostic audit constitution  
**No-duplicate status:** Protocol layer only; no replacement organ created.

## I. Supreme law

A system becomes governable when its claims, actors, evidence, requirements, decisions, impacts, failures, remedies, tests, and state transitions can be represented in one traceable graph.

The governing Ghost Atlas law remains:

> **No work without a Packet. No completion without proof. No institutional truth without an archived authoritative record.**

FTS adds one operational corollary:

> **No audit verdict without a replayable path from source -> normalized object -> applicable control -> test -> finding -> remediation state -> receipt.**

## II. Scope of auditability

FTS treats anything with observable state, claims, behavior, actors, interfaces, rules, resources, incentives, decisions, outputs, or effects as an auditable system.

The same kernel can therefore be instantiated for software, AI, organizations, public institutions, service systems, business processes, research programs, media systems, physical infrastructure, governance frameworks, projects, products, workflows, case files, and the Ghost Atlas Estate itself.

Domain vocabulary is translated through adapters. The canonical audit grammar does not change.

## III. Canonical object model

Every audit may contain the following object classes:

- `SYSTEM` — bounded system under review.
- `COMPONENT` — subsystem, department, service, repository, process, device, or organ.
- `ACTOR` — person, role, team, institution, agent, model, vendor, or authority.
- `CLAIM` — assertion about state, behavior, cause, compliance, completion, outcome, identity, or responsibility.
- `EVENT` — timestamped occurrence or state transition.
- `SOURCE` — originating document, recording, log, message, file, API result, observation, testimony, measurement, or dataset.
- `EVIDENCE` — a source-bound object used to support, weaken, contextualize, or contradict a claim.
- `RULE` — law, policy, contract, standard, requirement, specification, procedure, doctrine, acceptance criterion, or explicit user instruction.
- `CONTROL` — mechanism intended to satisfy a rule or reduce a failure mode.
- `DECISION` — choice, authorization, denial, promotion, classification, or disposition.
- `INTERFACE` — boundary through which information, authority, money, commands, artifacts, or responsibility move.
- `INCENTIVE` — pressure or reward shaping actor/system behavior.
- `DEPENDENCY` — prerequisite relationship.
- `RISK` — condition that can create failure or harm.
- `IMPACT` — human, technical, operational, financial, legal, institutional, reputational, or public effect.
- `FAILURE` — divergence between required/stated and observed behavior.
- `REMEDY` — proposed or executed repair.
- `TEST` — procedure that can change confidence in a claim or remedy.
- `FINDING` — audit interpretation linked to evidence and control.
- `VERDICT` — adjudicated audit state.
- `RECEIPT` — immutable or durable proof that a command, test, decision, publication, or transition occurred.
- `VERSION` — historical state of any auditable object.

## IV. Canonical edges

The graph must be able to express at minimum:

`ASSERTS`, `SUPPORTED_BY`, `CONTRADICTED_BY`, `CORROBORATED_BY`, `DERIVED_FROM`, `OCCURRED_BEFORE`, `OCCURRED_AFTER`, `GOVERNED_BY`, `REQUIRED_BY`, `VIOLATES`, `SATISFIES`, `DEPENDS_ON`, `CONTROLS`, `AUTHORIZED_BY`, `DENIED_BY`, `AFFECTS`, `OPERATED_BY`, `OWNED_BY`, `ROUTED_THROUGH`, `REMEDIATES`, `TESTED_BY`, `VERIFIED_BY`, `SUPERSEDES`, `RETRACTS`, `ARCHIVED_AS`, `PUBLISHED_AS`.

## V. Truth-state separation

FTS separates what a claim says from the state of evidence around it.

Canonical claim states:

`ASSERTED`, `SOURCE_ANCHORED`, `CORROBORATED`, `CONTESTED`, `CONTRADICTED`, `PROVISIONAL`, `VERIFIED`, `RETRACTED`, `SUPERSEDED`, `UNRESOLVED`.

Canonical completion states:

`NOT_STARTED`, `IN_PROGRESS`, `BLOCKED`, `EXECUTED`, `TESTED`, `VERIFIED`, `PROMOTED`, `PUBLISHED`, `ARCHIVED`.

Canonical audit verdicts:

`PASS`, `PASS_WITH_GAPS`, `REPAIR_REQUIRED`, `BLOCKED`, `FAIL`, `INSUFFICIENT_EVIDENCE`, `OUT_OF_SCOPE`.

A claim may remain archived even after retraction. Preservation and promotion are different operations.

## VI. Evidence discipline

Every evidence object carries:

- canonical ID;
- source ID and source location;
- capture time and event time when distinguishable;
- collector/ingestor;
- integrity metadata or hash when available;
- evidence class;
- relationship to claims;
- privacy/exposure class;
- transformations/derivatives;
- confidence dimensions;
- unresolved authenticity or completeness questions.

Evidence is never promoted merely because it is abundant. The graph records what it can establish.

## VII. Universal control adapter law

FTS does not hard-code one industry's rules as universal law. Instead every audit loads one or more `CONTROL_PACK` adapters.

A control pack maps external or internal requirements into:

`CONTROL_ID -> REQUIREMENT -> TEST -> REQUIRED_EVIDENCE -> PASS_CRITERIA -> FAIL_CRITERIA -> REMEDIATION_ROUTE`.

This is the hinge that makes FTS portable across domains without losing rigor.

## VIII. Power and transparency model

Every audit must be capable of mapping:

`WHO_KNOWS`, `WHO_DECIDES`, `WHO_CAN_ACT`, `WHO_CAN_BLOCK`, `WHO_BENEFITS`, `WHO_PAYS`, `WHO_IS_AFFECTED`, `WHO_CAN_REVIEW`, `WHAT_IS_VISIBLE`, `WHAT_IS_HIDDEN`, `WHAT_IS_MISSING`, `WHERE_INFORMATION_CHANGES`, `WHERE_RESPONSIBILITY_DIFFUSES`.

This preserves the original FTS concern with manipulation, governance, oversight, power, and accountability while converting it into computable graph structure.

## IX. Contradiction engine

A contradiction is a first-class object, not a paragraph in a report.

Each contradiction links:

`CLAIM_A <-> CLAIM_B / EVIDENCE / RULE / OBSERVED_STATE`

and records:

- contradiction type;
- source strength;
- time relationship;
- possible reconciliation;
- unresolved questions;
- materiality;
- downstream affected findings.

When a claim is corrected, dependent findings are automatically marked for re-evaluation.

## X. Remediation is part of the audit

FTS audits do not terminate at diagnosis.

A material finding can generate a governed repair chain:

`FINDING -> REMEDY -> PACKET -> OWNER -> ACTION -> RECEIPT -> TEST -> MA'AT VERDICT -> ARCHIVE`.

MetaForge builds technical repairs. Workforce Spine routes work. PROMETHEUS executes command-to-proof pathways. EDEN runs bounded actions. SECA/DevOS verifies. Thoth preserves. ProofGrid exposes proof state.

## XI. Recursive auditability

The auditor, audit framework, model, source transformation, control pack, verdict, and remediation process are themselves auditable objects.

FTS therefore supports:

`AUDIT(system)`
`AUDIT(audit)`
`AUDIT(auditor)`
`AUDIT(control_pack)`
`AUDIT(remediation)`
`AUDIT(publication)`

No layer receives a permanent exemption from inspection.

## XII. Publication law

Medusa classifies the proof package before exposure. Public output is generated only from approved evidence and findings, while private source lineage remains linked in the internal graph.

Audience Forge translates verified findings without becoming a new truth authority.

## XIII. Success condition

An FTS audit is complete only when another authorized reviewer can answer:

1. What system was scoped?
2. What evidence entered?
3. What claims were tested?
4. What controls applied?
5. What contradictions mattered?
6. What findings were reached?
7. What remained unresolved?
8. What remediation was routed or executed?
9. What tests established the current state?
10. Where is the authoritative receipt chain?

That is Full Transparency as an operating system rather than a slogan.
