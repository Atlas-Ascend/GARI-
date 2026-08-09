# FTS UNIVERSAL AUDIT PROTOCOL

**Protocol ID:** `FTS-UAP-001`  
**Purpose:** Turn any bounded system into a reproducible command-to-proof audit campaign.

## Audit invocation

`FTS AUDIT <target> --scope <boundary> --control-pack <frameworks> --exposure <private|reviewer|public>`

The implementation surface may vary, but every run must emit the same logical sequence and receipt family.

## Stage 00 — INTAKE / SCOPE FREEZE

Inputs:
- audit request;
- target identity;
- time boundary;
- access boundary;
- known source locations;
- applicable control packs;
- public/private classification assumptions.

Outputs:
- `00_AUDIT_CHARTER.md`
- `00_SCOPE_FREEZE.json`
- `00_AUTHORITY_AND_ACCESS_MAP.json`
- `00_SOURCE_EXPECTATION_REGISTER.csv`

Gate:
- target and boundary are explicit;
- no source mutation is required for intake;
- collection authority and disclosure boundary are recorded.

## Stage 01 — CENSUS / SYSTEM MAP

Mission:
Establish what the system contains before deciding what it means.

Map:
- components;
- actors and roles;
- interfaces;
- repositories/datastores;
- policies/requirements;
- queues/workflows;
- money/resource flows when in scope;
- decision points;
- external dependencies;
- observability surfaces;
- known blind spots.

Outputs:
- `01_SYSTEM_CENSUS.csv`
- `01_ACTOR_ROLE_MAP.csv`
- `01_INTERFACE_MAP.csv`
- `01_DEPENDENCY_GRAPH.json`
- `01_BLIND_SPOT_REGISTER.md`

Owners:
GARI + Universal Atlas + Seshat Atlas + CrownGrid.

## Stage 02 — SOURCE INGEST / PROVENANCE

Mission:
Convert source material into immutable-addressable or durable-addressable evidence objects.

Source families may include:
- documents;
- email/messages;
- logs;
- repositories;
- recordings;
- images/video;
- database rows;
- API results;
- telemetry;
- interviews/testimony;
- field observation;
- contracts/policies;
- external standards;
- prior audits.

Outputs:
- `02_SOURCE_MANIFEST.csv`
- `02_EVIDENCE_LEDGER.jsonl`
- `02_HASH_MANIFEST.sha256`
- `02_TRANSFORMATION_LINEAGE.csv`
- `02_MISSING_SOURCE_REGISTER.md`

Owners:
RoadBridge / CrownGrid connectors -> GARI -> Thoth -> Aletheia.

## Stage 03 — NORMALIZATION / UNIVERSAL OBJECT GRAPH

Mission:
Translate domain-native data into the FTS canonical object and edge model without destroying the original vocabulary.

Outputs:
- `03_OBJECTS.jsonl`
- `03_EDGES.jsonl`
- `03_DOMAIN_EQUIVALENCE_MAP.csv`
- `03_IDENTITY_COLLISION_REPORT.md`

Owners:
Universal Atlas + Seshat Atlas + Thoth.

## Stage 04 — CLAIM / CHRONOLOGY / STATE RECONSTRUCTION

Mission:
Build the best source-linked reconstruction of what was claimed, what occurred, what changed, and what remains unknown.

Required operations:
- extract claims;
- bind each claim to originating source;
- distinguish event time from capture time;
- reconstruct ordered chronology;
- detect source conflicts;
- preserve corrections/retractions;
- identify state transitions;
- propagate uncertainty.

Outputs:
- `04_CLAIM_LEDGER.csv`
- `04_EVENT_CHRONOLOGY.csv`
- `04_STATE_TRANSITIONS.json`
- `04_RETRACTION_SUPERSESSION_LEDGER.csv`

Owners:
CaseGraph-compatible evidence model + Thoth + Seshat + Aletheia.

## Stage 05 — POWER / INCENTIVE / INFORMATION FLOW MAP

Mission:
Expose the system architecture that ordinary chronology misses.

For every material workflow ask:
- who can decide;
- who can observe;
- who can alter the record;
- who can withhold information;
- who bears consequences;
- who benefits from delay, ambiguity, success, or failure;
- where incentives diverge from stated purpose;
- where responsibility can be diffused;
- where review rights exist or fail.

Outputs:
- `05_POWER_MAP.json`
- `05_INCENTIVE_MAP.csv`
- `05_INFORMATION_FLOW_GRAPH.json`
- `05_ACCOUNTABILITY_GAP_REGISTER.md`

Owners:
FTS + GARI/Civitas + Universal Atlas.

## Stage 06 — CONTROL PACK CROSSWALK

Mission:
Load applicable laws, policies, standards, contracts, technical specifications, internal rules, user requirements, ethical codes, or acceptance criteria as testable controls.

Normalize each control to:
- ID;
- authority/source;
- requirement text/summary;
- objects governed;
- evidence required;
- test procedure;
- pass threshold;
- failure threshold;
- remediation route.

Outputs:
- `06_CONTROL_PACKS.json`
- `06_REQUIREMENT_CROSSWALK.csv`
- `06_TEST_PLAN.csv`

Owners:
GARI + SECA/DevOS + domain adapters.

## Stage 07 — CONTRADICTION / GAP / FAILURE ANALYSIS

Mission:
Find where stories, records, behavior, requirements, and outcomes stop agreeing.

Detection classes:
- claim vs claim;
- claim vs source;
- claim vs system state;
- policy vs practice;
- requirement vs implementation;
- public representation vs internal record;
- completion claim vs test result;
- chronology conflict;
- missing evidence;
- broken chain of custody;
- inconsistent treatment;
- authority without receipt;
- remedy without verification;
- audit conclusion without traceable basis.

Outputs:
- `07_CONTRADICTION_LEDGER.csv`
- `07_GAP_REGISTER.csv`
- `07_FAILURE_TAXONOMY.json`
- `07_DEPENDENT_FINDINGS_RECHECK_QUEUE.csv`

Owners:
Aletheia + SECA + Seshat.

## Stage 08 — TEST / MEASURE

Mission:
Execute the tests defined by the control packs and evidence plan.

Tests may be documentary, logical, computational, statistical, technical, procedural, physical, or reviewer-based.

Outputs:
- `08_TEST_RESULTS.jsonl`
- `08_MEASUREMENT_REPORT.md`
- `08_UNRESOLVED_TESTS.csv`
- test receipts/artifacts.

Owners:
PROMETHEUS / EDEN / domain tools / SECA.

## Stage 09 — MA'AT ADJUDICATION

Mission:
Assign finding and verdict states from the evidence actually present.

Each finding must contain:
- finding ID;
- affected objects;
- applicable controls;
- evidence set;
- contradicting evidence;
- analysis path;
- confidence dimensions;
- materiality;
- verdict;
- remediation requirement;
- unresolved questions.

Outputs:
- `09_FINDINGS.jsonl`
- `09_MAAT_VERDICT.md`
- `09_OPEN_QUESTIONS.csv`

Owners:
Ma'at / SECA / DevOS.

## Stage 10 — REMEDIATION COMPILER

Mission:
Turn findings into executable repair work rather than decorative recommendations.

For every `REPAIR_REQUIRED` finding generate:

`FINDING -> REMEDY -> PACKET -> OWNER -> DEPENDENCIES -> ACCEPTANCE_TEST -> PROOF_REQUIREMENT -> DEADLINE/QUEUE -> ESCALATION`.

Outputs:
- `10_REMEDIATION_PLAN.md`
- `10_PACKET_OS_IMPORT.jsonl`
- `10_WORKFORCE_HANDOFF.csv`
- `10_ACCEPTANCE_MATRIX.csv`

Owners:
Janus/Odin -> Packet OS -> Workforce Spine -> MetaForge/PROMETHEUS/EDEN.

## Stage 11 — EXECUTION / RE-TEST

Mission:
Execute authorized repairs and prove whether the audited state changed.

Outputs:
- action receipts;
- changed artifacts;
- re-test results;
- rollback coordinates;
- residual failures;
- new evidence objects.

Owners:
PROMETHEUS / MetaForge / EDEN / Workforce Spine / Osiris / SECA.

## Stage 12 — MEDUSA DISCLOSURE GATE

Mission:
Separate what may be published from what must remain internal, protected, redacted, privileged, proprietary, personally sensitive, security-sensitive, or otherwise restricted.

Outputs:
- `12_DISCLOSURE_MATRIX.csv`
- `12_REDACTION_MANIFEST.json`
- `12_PUBLIC_PROOF_SET.json`
- `12_PRIVATE_ARCHIVE_SET.json`

Owner:
Medusa.

## Stage 13 — ARCHIVE / PROOF / PUBLICATION

Mission:
Close the loop with durable lineage.

Outputs:
- `13_THOTH_RECEIPT.md`
- `13_PROOFGRID_INDEX.json`
- `13_REPRODUCIBILITY_PACK.md`
- reviewer portal or CaseGraph projection;
- public briefing / case study / documentary packet when authorized;
- machine-readable next-state snapshot.

Owners:
Thoth + Aletheia/ProofGrid + Audience Forge.

## Stage 14 — REAUDIT / DELTA

Mission:
Treat every audit as a versioned state, not a one-time report.

Compare:
- previous findings;
- repaired findings;
- new evidence;
- changed controls;
- changed actors/ownership;
- regressions;
- newly visible blind spots.

Outputs:
- `14_DELTA_REPORT.md`
- `14_REGRESSION_LEDGER.csv`
- `14_NEXT_AUDIT_SEED.json`

Owners:
Seshat + Thoth + Janus + SAMI.

# Universal handoff rule

No stage hands narrative prose alone to the next stage. Every handoff includes machine-readable objects, human-readable explanation, source pointers, state, owner, acceptance condition, and next route.

# Minimum completion contract

An audit cannot be promoted unless:

`scope_frozen && source_manifest_exists && object_graph_exists && claims_have_source_state && control_crosswalk_exists && contradictions_recorded && tests_receipted && findings_traceable && open_questions_explicit && disclosure_review_complete && thoth_receipt_exists`

# Command-to-proof closure

`SIGNAL -> SOURCE -> OBJECT -> CLAIM -> CONTROL -> TEST -> FINDING -> REMEDY -> PACKET -> EXECUTION -> RETEST -> VERDICT -> RECEIPT -> ARCHIVE -> PUBLIC PROOF -> DELTA`
