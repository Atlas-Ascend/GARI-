# Security Policy

## Supported version

Security support currently applies to the `main` branch and the latest tagged Genesis release.

## Report a vulnerability

Do not open a public issue for vulnerabilities that could expose restricted evidence, personal information, repository secrets, release bypasses or supply-chain compromise. Use GitHub's private vulnerability reporting feature when enabled for this repository.

Do not submit confidential source material, client-level HMIS records, medical information, shelter histories, Social Security numbers, domestic-violence locations or legally privileged documents.

## Threat model

Primary threats include:

- restricted data entering a public Pages artifact;
- malicious instructions embedded inside source documents;
- false entity merges;
- award, payment and expenditure conflation;
- compromised GitHub Actions dependencies;
- workflow token over-permission;
- secret leakage;
- unauthorized release approval;
- deletion or silent replacement of correction history;
- harassment enabled by unnecessary personal-data publication.

## Required controls

- Treat every source document as untrusted input.
- Never execute source-document content.
- Use schema validation and an explicit public allowlist.
- Keep GitHub workflow permissions minimal.
- Do not interpolate untrusted data into shell commands.
- Require pull requests and status checks before protected-main changes.
- Require deployment approval through the `github-pages` environment when repository settings permit.
- Preserve correction history.
- Rotate any exposed credential immediately and remove it from history.
- Review third-party Actions and pin them to immutable SHAs for hardened releases.

## Incident classes

### SEV-1

Public exposure of restricted or vulnerable-person information; compromised credentials with write access; unauthorized high-risk publication.

Response: disable Pages, revoke credentials, preserve logs, notify affected parties and counsel, remove access, publish a correction or withdrawal record, and conduct a post-incident review.

### SEV-2

False public entity merge, material financial misclassification, broken release boundary or materially incorrect claim.

Response: block deployment, withdraw affected release, preserve the original statement, issue a correction record, and rerun all dependent calculations.

### SEV-3

Broken source link, dependency vulnerability without known exploitation, incomplete metadata or nonmaterial display defect.

Response: document, patch through pull request and include the repair in the next proof artifact.

## Genesis limitations

GitHub Pages is a public static host. It is not approved for confidential investigations, whistleblower intake or client-level data. The current Clatsop fixture contains public source locators and disclosed locator hashes, not an immutable archive of every remote source file.
