from __future__ import annotations

import json
from collections.abc import Iterable
from dataclasses import dataclass
from decimal import Decimal
from pathlib import Path
from typing import Any, TypeVar

from pydantic import BaseModel

from lantern.models import (
    CaseRecord,
    ClaimClass,
    ClaimOrigin,
    ClaimRecord,
    CorrectionRecord,
    EntityRecord,
    MatchStatus,
    MoneyEvent,
    ReleaseManifest,
    ReleaseStatus,
    SourceRecord,
    TrustZone,
)

T = TypeVar("T", bound=BaseModel)

PROHIBITED_PUBLIC_KEYS = {
    "ssn",
    "social_security_number",
    "client_name",
    "client_id",
    "hmis_id",
    "medical_record",
    "diagnosis",
    "date_of_birth",
    "shelter_history",
    "domestic_violence_location",
}

PROHIBITED_ALLEGATION_TERMS = {
    "fraud",
    "stole",
    "stolen",
    "theft",
    "embezzlement",
    "kickback",
    "corrupt",
    "criminal conspiracy",
    "misappropriated",
}

PUBLIC_STATES = {ReleaseStatus.APPROVED, ReleaseStatus.PUBLISHED, ReleaseStatus.CORRECTED}
UNRESOLVED_MATCHES = {
    MatchStatus.PROBABLE,
    MatchStatus.POSSIBLE,
    MatchStatus.UNRESOLVED,
    MatchStatus.DISPUTED,
}


class ValidationFailure(RuntimeError):
    """Raised when a command-to-proof gate fails."""


@dataclass(frozen=True)
class CaseBundle:
    case: CaseRecord
    sources: list[SourceRecord]
    entities: list[EntityRecord]
    money_events: list[MoneyEvent]
    claims: list[ClaimRecord]
    corrections: list[CorrectionRecord]
    release: ReleaseManifest | None


def read_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def parse_list(path: Path, model: type[T]) -> list[T]:
    payload = read_json(path)
    if not isinstance(payload, list):
        raise ValidationFailure(f"{path} must contain a JSON array")
    return [model.model_validate(item) for item in payload]


def load_case(case_dir: Path) -> CaseBundle:
    release_path = case_dir / "release.json"
    return CaseBundle(
        case=CaseRecord.model_validate(read_json(case_dir / "case.json")),
        sources=parse_list(case_dir / "sources.json", SourceRecord),
        entities=parse_list(case_dir / "entities.json", EntityRecord),
        money_events=parse_list(case_dir / "money_events.json", MoneyEvent),
        claims=parse_list(case_dir / "claims.json", ClaimRecord),
        corrections=parse_list(case_dir / "corrections.json", CorrectionRecord),
        release=ReleaseManifest.model_validate(read_json(release_path))
        if release_path.exists()
        else None,
    )


def assert_unique(values: Iterable[str], label: str) -> None:
    seen: set[str] = set()
    duplicates: set[str] = set()
    for value in values:
        if value in seen:
            duplicates.add(value)
        seen.add(value)
    if duplicates:
        raise ValidationFailure(f"duplicate {label}: {sorted(duplicates)}")


def scan_prohibited_keys(payload: Any, path: str = "root") -> None:
    if isinstance(payload, dict):
        for key, value in payload.items():
            if key.lower() in PROHIBITED_PUBLIC_KEYS:
                raise ValidationFailure(f"prohibited personal-data key at {path}.{key}")
            scan_prohibited_keys(value, f"{path}.{key}")
    elif isinstance(payload, list):
        for index, item in enumerate(payload):
            scan_prohibited_keys(item, f"{path}[{index}]")


def validate_bundle(bundle: CaseBundle) -> list[str]:
    notes: list[str] = []
    assert_unique((item.source_id for item in bundle.sources), "source IDs")
    assert_unique((item.entity_id for item in bundle.entities), "entity IDs")
    assert_unique((item.event_id for item in bundle.money_events), "money event IDs")
    assert_unique((item.claim_id for item in bundle.claims), "claim IDs")
    assert_unique((item.correction_id for item in bundle.corrections), "correction IDs")

    source_ids = {item.source_id for item in bundle.sources}
    entities = {item.entity_id: item for item in bundle.entities}
    event_ids = {item.event_id for item in bundle.money_events}
    claim_ids = {item.claim_id for item in bundle.claims}

    for source in bundle.sources:
        if source.trust_zone is TrustZone.RESTRICTED and source.public_release_status in PUBLIC_STATES:
            raise ValidationFailure(f"restricted source {source.source_id} cannot be public")

    for entity in bundle.entities:
        if entity.public_release_status in PUBLIC_STATES and entity.match_status in UNRESOLVED_MATCHES:
            raise ValidationFailure(
                f"entity {entity.entity_id} is {entity.match_status} and cannot enter public output"
            )
        unknown_sources = set(entity.supporting_sources) - source_ids
        if unknown_sources:
            raise ValidationFailure(
                f"entity {entity.entity_id} references unknown sources {sorted(unknown_sources)}"
            )

    for event in bundle.money_events:
        if event.source_entity not in entities or event.recipient_entity not in entities:
            raise ValidationFailure(f"money event {event.event_id} references an unknown entity")
        if event.intermediary_entity and event.intermediary_entity not in entities:
            raise ValidationFailure(f"money event {event.event_id} has an unknown intermediary")
        unknown_sources = set(event.source_records) - source_ids
        if unknown_sources:
            raise ValidationFailure(
                f"money event {event.event_id} references unknown sources {sorted(unknown_sources)}"
            )
        if event.parent_event_id and event.parent_event_id not in event_ids:
            raise ValidationFailure(
                f"money event {event.event_id} references missing parent {event.parent_event_id}"
            )
        if event.public_release_status in PUBLIC_STATES and event.trust_zone is not TrustZone.PUBLIC:
            raise ValidationFailure(
                f"money event {event.event_id} must be explicitly promoted into the public trust zone"
            )

    for claim in bundle.claims:
        unknown_sources = set(claim.supporting_sources + claim.contrary_sources) - source_ids
        if unknown_sources:
            raise ValidationFailure(
                f"claim {claim.claim_id} references unknown sources {sorted(unknown_sources)}"
            )
        unknown_subjects = set(claim.subjects) - entities.keys()
        if unknown_subjects:
            raise ValidationFailure(
                f"claim {claim.claim_id} references unknown subjects {sorted(unknown_subjects)}"
            )
        if claim.public_release_status in PUBLIC_STATES:
            if claim.origin is ClaimOrigin.AI_CANDIDATE:
                raise ValidationFailure(f"AI candidate claim {claim.claim_id} cannot be public")
            unresolved_subjects = [
                subject
                for subject in claim.subjects
                if entities[subject].match_status in UNRESOLVED_MATCHES
            ]
            if unresolved_subjects:
                raise ValidationFailure(
                    f"claim {claim.claim_id} has unresolved subjects {unresolved_subjects}"
                )
            required_reviews = [
                claim.factual_review,
                claim.privacy_review,
                claim.substantive_review,
            ]
            if any(review.status != "passed" for review in required_reviews):
                raise ValidationFailure(f"claim {claim.claim_id} lacks required public reviews")
            if claim.claim_class in {
                ClaimClass.INVESTIGATIVE_FINDING,
                ClaimClass.HIGH_RISK_ALLEGATION,
            }:
                heightened = [
                    claim.accounting_review,
                    claim.adversarial_review,
                    claim.legal_review,
                ]
                if any(review.status != "passed" for review in heightened):
                    raise ValidationFailure(
                        f"high-risk claim {claim.claim_id} lacks heightened review"
                    )
            statement = claim.exact_statement.lower()
            if claim.claim_class is not ClaimClass.HIGH_RISK_ALLEGATION and any(
                term in statement for term in PROHIBITED_ALLEGATION_TERMS
            ):
                raise ValidationFailure(
                    f"claim {claim.claim_id} uses allegation language outside the high-risk class"
                )

    for correction in bundle.corrections:
        if correction.affected_claim not in claim_ids:
            raise ValidationFailure(
                f"correction {correction.correction_id} references unknown claim"
            )
        if not correction.original_statement or correction.original_statement == correction.corrected_statement:
            raise ValidationFailure(
                f"correction {correction.correction_id} must preserve a distinct original statement"
            )

    public_payload = public_projection(bundle)
    scan_prohibited_keys(public_payload)
    notes.append("unique identifiers verified")
    notes.append("source and entity references verified")
    notes.append("money-event parentage and trust zones verified")
    notes.append("claim review and allegation boundaries verified")
    notes.append("correction history verified")
    notes.append("public payload passed prohibited-field scan")
    return notes


def aggregate_money(events: Iterable[MoneyEvent]) -> Decimal:
    items = list(events)
    if not items:
        return Decimal("0")
    event_types = {item.event_type for item in items}
    currencies = {item.currency for item in items}
    groups = {item.aggregation_group for item in items}
    if len(event_types) != 1:
        raise ValidationFailure("incompatible money event types cannot be aggregated")
    if len(currencies) != 1:
        raise ValidationFailure("mixed currencies cannot be aggregated")
    if None in groups or len(groups) != 1:
        raise ValidationFailure("events require one explicit aggregation group")
    if not all(item.aggregation_permission for item in items):
        raise ValidationFailure("every event must explicitly permit aggregation")
    parent_ids = {item.parent_event_id for item in items if item.parent_event_id}
    selected_ids = {item.event_id for item in items}
    if parent_ids & selected_ids:
        raise ValidationFailure("a parent event and its child cannot be aggregated together")
    return sum((item.amount for item in items), Decimal("0"))


def public_projection(bundle: CaseBundle) -> dict[str, Any]:
    public_sources = [
        item.model_dump(mode="json")
        for item in bundle.sources
        if item.public_release_status in PUBLIC_STATES and item.trust_zone is TrustZone.PUBLIC
    ]
    public_entities = [
        item.model_dump(mode="json")
        for item in bundle.entities
        if item.public_release_status in PUBLIC_STATES and item.trust_zone is TrustZone.PUBLIC
    ]
    public_events = [
        item.model_dump(mode="json")
        for item in bundle.money_events
        if item.public_release_status in PUBLIC_STATES and item.trust_zone is TrustZone.PUBLIC
    ]
    public_claims = [
        item.model_dump(mode="json")
        for item in bundle.claims
        if item.public_release_status in PUBLIC_STATES and item.trust_zone is TrustZone.PUBLIC
    ]
    public_corrections = [
        item.model_dump(mode="json")
        for item in bundle.corrections
        if item.public_release_status in PUBLIC_STATES and item.trust_zone is TrustZone.PUBLIC
    ]
    return {
        "case": bundle.case.model_dump(mode="json"),
        "sources": public_sources,
        "entities": public_entities,
        "money_events": public_events,
        "claims": public_claims,
        "corrections": public_corrections,
        "release_state": {
            "publication_authority": bundle.case.publication_authority,
            "notice": bundle.case.no_misconduct_notice,
        },
    }
