## Command-to-proof change

### Case scope

- Case ID:
- Jurisdiction / period:
- Mission effect:

### Change classes

- [ ] Code or architecture
- [ ] Source record
- [ ] Entity resolution
- [ ] Money event
- [ ] Outcome record
- [ ] Claim
- [ ] Correction
- [ ] Public website
- [ ] Security or deployment

### Evidence boundary

- Are any entities added, merged, split, demoted or disputed?
- Are any award, obligation, allocation, payment or expenditure classifications changed?
- Does this change modify an exact public claim?
- Does this change alter public output?
- Could restricted, personal, client-level or confidential data be introduced?
- What contrary evidence or alternative explanation was considered?

### Required reviewers

- [ ] Entity Resolution Examiner
- [ ] Forensic Nonprofit Accountant
- [ ] Outcome Measurement Scientist
- [ ] Claim-Level Fact Checker
- [ ] Adversarial Evidence Examiner
- [ ] Privacy Officer
- [ ] Publication Counsel
- [ ] Director of Evidence Integrity
- [ ] None required; explain why

### Proof

- [ ] `ruff check .`
- [ ] `mypy`
- [ ] `pytest -q`
- [ ] `lantern generate-schema`
- [ ] `lantern validate LSC-OR-CLATSOP-001`
- [ ] `lantern build-public LSC-OR-CLATSOP-001`
- [ ] Public output contains no restricted records
- [ ] No fake professional approval was generated

### Summary

Explain what changed, why it changed, which failure it prevents, and what remains unresolved.
