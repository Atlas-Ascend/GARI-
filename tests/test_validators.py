from __future__ import annotations

from datetime import date, datetime, timezone
from decimal import Decimal
from pathlib import Path

import pytest
from pydantic import ValidationError

from lantern.models import (
    ClaimClass,
    ClaimOrigin,
    ClaimRecord,
    EntityRecord,
    MatchStatus,
    MoneyEvent,
    MoneyEventType,
    ReleaseStatus,
    ReviewState,
    SourceRecord,
    TrustZone,
    VerificationStatus,
)
from lantern.validators import (
    CaseBundle,
    ValidationFailure,
    aggregate_money,
    load_case,
    public_projection,
    scan_prohibited_keys,
    validate_bundle,
)

ROOT = Path(__file__).resolve().parents[1]
CASE_DIR = ROOT / "cases" / "LSC-OR-CLATSOP-001"


def review(status: str = "passed") -> ReviewState:
    return ReviewState(
        reviewer_role="test reviewer",
        status=status,  # type: ignore[arg-type]
        reviewer="fixture",
        reviewed_at=datetime.now(timezone.utc) if status == "passed" else None,
    )


def public_source() -> SourceRecord:
    return SourceRecord(
        source_id="SRC-TEST",
        title="Test source",
        publisher="Test publisher",
        source_type="official record",
        source_url="https://example.com/source",
        jurisdiction="Test",
        acquisition_method="fixture",
        acquired_at=datetime.now(timezone.utc),
        content_hash="a" * 64,
        reliability_class="fixture",
        amendment_status="none",
        trust_zone=TrustZone.PUBLIC,
        public_release_status=ReleaseStatus.APPROVED,
    )


def entity(entity_id: str = "ORG-TEST") -> EntityRecord:
    return EntityRecord(
        entity_id=entity_id,
        canonical_name=entity_id,
        entity_type="organization",
        jurisdiction="Test",
        match_status=MatchStatus.CONFIRMED,
        resolution_method="fixture",
        supporting_sources=["SRC-TEST"],
        reviewer="fixture",
        reviewed_at=datetime.now(timezone.utc),
        trust_zone=TrustZone.PUBLIC,
        public_release_status=ReleaseStatus.APPROVED,
    )


def money_event(event_id: str, event_type: MoneyEventType, amount: str) -> MoneyEvent:
    return MoneyEvent(
        event_id=event_id,
        flow_id="FLOW-TEST",
        event_type=event_type,
        source_entity="ORG-SOURCE",
        recipient_entity="ORG-TARGET",
        program="Test",
        amount=Decimal(amount),
        period_start=date(2025, 1, 1),
        period_end=date(2025, 12, 31),
        fiscal_year="2025",
        geographic_scope="Test",
        source_records=["SRC-TEST"],
        aggregation_group="GROUP-1",
        aggregation_permission=True,
        verification_status=VerificationStatus.VERIFIED,
        interpretation_note="fixture",
        trust_zone=TrustZone.PUBLIC,
        public_release_status=ReleaseStatus.APPROVED,
    )


def public_claim(origin: ClaimOrigin = ClaimOrigin.SOURCE_DERIVED) -> ClaimRecord:
    return ClaimRecord(
        claim_id="CLM-TEST",
        exact_statement="The source reports a test fact.",
        claim_class=ClaimClass.SOURCE_FACT,
        origin=origin,
        subjects=["ORG-TEST"],
        supporting_sources=["SRC-TEST"],
        factual_review=review(),
        accounting_review=review("not_required"),
        adversarial_review=review("not_required"),
        privacy_review=review(),
        legal_review=review("not_required"),
        substantive_review=review(),
        trust_zone=TrustZone.PUBLIC,
        publication_status=ReleaseStatus.APPROVED,
        public_release_status=ReleaseStatus.APPROVED,
    )


def test_real_clatsop_bundle_validates() -> None:
    bundle = load_case(CASE_DIR)
    notes = validate_bundle(bundle)
    assert "public payload passed prohibited-field scan" in notes


def test_blocked_claims_do_not_enter_public_projection() -> None:
    bundle = load_case(CASE_DIR)
    assert public_projection(bundle)["claims"] == []


def test_missing_claim_source_is_rejected_by_schema() -> None:
    payload = public_claim().model_dump(mode="json")
    payload["supporting_sources"] = []
    with pytest.raises(ValidationError):
        ClaimRecord.model_validate(payload)


def test_incompatible_money_event_types_cannot_be_aggregated() -> None:
    award = money_event("EVT-AWARD", MoneyEventType.AWARD, "100")
    payment = money_event("EVT-PAYMENT", MoneyEventType.PAYMENT, "100")
    with pytest.raises(ValidationFailure, match="incompatible money event types"):
        aggregate_money([award, payment])


def test_parent_and_child_cannot_be_aggregated() -> None:
    parent = money_event("EVT-PARENT", MoneyEventType.ALLOCATION, "100")
    child = money_event("EVT-CHILD", MoneyEventType.ALLOCATION, "50").model_copy(
        update={"parent_event_id": "EVT-PARENT"}
    )
    with pytest.raises(ValidationFailure, match="parent event and its child"):
        aggregate_money([parent, child])


def test_prohibited_personal_data_is_rejected() -> None:
    with pytest.raises(ValidationFailure, match="prohibited personal-data key"):
        scan_prohibited_keys({"client_name": "Never publish"})


def test_ai_candidate_claim_cannot_be_public() -> None:
    source = public_source()
    subject = entity()
    claim = public_claim(ClaimOrigin.AI_CANDIDATE)
    case = load_case(CASE_DIR).case
    bundle = CaseBundle(case, [source], [subject], [], [claim], [], None)
    with pytest.raises(ValidationFailure, match="AI candidate claim"):
        validate_bundle(bundle)


def test_unresolved_entity_cannot_be_public() -> None:
    source = public_source()
    unresolved = entity().model_copy(update={"match_status": MatchStatus.UNRESOLVED})
    case = load_case(CASE_DIR).case
    bundle = CaseBundle(case, [source], [unresolved], [], [], [], None)
    with pytest.raises(ValidationFailure, match="cannot enter public output"):
        validate_bundle(bundle)


def test_restricted_source_cannot_be_public() -> None:
    source = public_source().model_copy(update={"trust_zone": TrustZone.RESTRICTED})
    case = load_case(CASE_DIR).case
    bundle = CaseBundle(case, [source], [], [], [], [], None)
    with pytest.raises(ValidationFailure, match="restricted source"):
        validate_bundle(bundle)


def test_high_risk_claim_requires_heightened_review() -> None:
    source = public_source()
    subject = entity()
    claim = public_claim().model_copy(
        update={
            "claim_class": ClaimClass.HIGH_RISK_ALLEGATION,
            "accounting_review": review("not_started"),
            "adversarial_review": review("not_started"),
            "legal_review": review("not_started"),
        }
    )
    case = load_case(CASE_DIR).case
    bundle = CaseBundle(case, [source], [subject], [], [claim], [], None)
    with pytest.raises(ValidationFailure, match="lacks heightened review"):
        validate_bundle(bundle)
