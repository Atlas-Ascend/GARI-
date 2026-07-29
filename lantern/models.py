from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from enum import StrEnum
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, HttpUrl, model_validator


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class TrustZone(StrEnum):
    CANDIDATE = "candidate"
    CANONICAL = "canonical"
    RESTRICTED = "restricted"
    PUBLIC = "public"


class ReleaseStatus(StrEnum):
    BLOCKED = "blocked"
    REVIEW = "review"
    APPROVED = "approved"
    PUBLISHED = "published"
    CORRECTED = "corrected"
    WITHDRAWN = "withdrawn"


class MatchStatus(StrEnum):
    CONFIRMED = "confirmed"
    PROBABLE = "probable"
    POSSIBLE = "possible"
    UNRESOLVED = "unresolved"
    DISPUTED = "disputed"
    REJECTED = "rejected"


class VerificationStatus(StrEnum):
    UNREVIEWED = "unreviewed"
    PRESERVED = "preserved"
    EXTRACTED = "extracted"
    VERIFIED = "verified"
    REPRODUCED = "reproduced"
    CORROBORATED = "corroborated"


class MoneyEventType(StrEnum):
    AUTHORIZATION = "authorization"
    APPROPRIATION = "appropriation"
    ALLOCATION = "allocation"
    AWARD = "award"
    MODIFICATION = "modification"
    OBLIGATION = "obligation"
    DEOBLIGATION = "deobligation"
    OUTLAY = "outlay"
    RECEIPT = "receipt"
    REVENUE_RECOGNITION = "revenue_recognition"
    SUBAWARD = "subaward"
    CONTRACT_COMMITMENT = "contract_commitment"
    REIMBURSEMENT_REQUEST = "reimbursement_request"
    INVOICE = "invoice"
    PAYMENT = "payment"
    EXPENDITURE = "expenditure"
    REFUND = "refund"
    RECOVERY = "recovery"
    TRANSFER = "transfer"
    INTERNAL_ALLOCATION = "internal_allocation"
    RESTRICTED_BALANCE = "restricted_balance"
    UNRESTRICTED_BALANCE = "unrestricted_balance"


class ClaimClass(StrEnum):
    SOURCE_FACT = "source_fact"
    CALCULATED_METRIC = "calculated_metric"
    RELATIONSHIP = "relationship"
    DISCREPANCY = "discrepancy"
    INVESTIGATIVE_FINDING = "investigative_finding"
    HIGH_RISK_ALLEGATION = "high_risk_allegation"
    METHODOLOGY = "methodology"


class ClaimOrigin(StrEnum):
    HUMAN = "human"
    SOURCE_DERIVED = "source_derived"
    AI_CANDIDATE = "ai_candidate"


class AttributionClass(StrEnum):
    PROVIDER_REPORTED = "provider_reported"
    GOVERNMENT_REPORTED = "government_reported"
    CONTRACT_VERIFIED = "contract_verified"
    REGIONAL_ASSOCIATION = "regional_association"
    NOT_ATTRIBUTABLE = "not_attributable"
    CAUSAL_INFERENCE_NOT_ESTABLISHED = "causal_inference_not_established"


class CitationLocation(StrictModel):
    locator_type: Literal["page", "line", "cell", "xpath", "json_path", "section", "url"]
    locator: str
    excerpt: str | None = None


class SourceRecord(StrictModel):
    source_id: str = Field(pattern=r"^SRC-[A-Z0-9-]+$")
    title: str
    publisher: str
    source_type: str
    source_url: HttpUrl
    jurisdiction: str
    acquisition_method: str
    acquired_at: datetime
    content_hash: str = Field(pattern=r"^[a-fA-F0-9]{64}$")
    publication_date: date | None = None
    coverage_start: date | None = None
    coverage_end: date | None = None
    reliability_class: str
    amendment_status: str
    trust_zone: TrustZone = TrustZone.CANONICAL
    public_release_status: ReleaseStatus = ReleaseStatus.BLOCKED
    limitations: list[str] = Field(default_factory=list)
    citation_locations: list[CitationLocation] = Field(default_factory=list)


class EntityIdentifier(StrictModel):
    scheme: str
    value: str


class EntityRecord(StrictModel):
    entity_id: str = Field(pattern=r"^(ORG|GOV|CITY|PRG|COC|PER|PRP)-[A-Z0-9-]+$")
    canonical_name: str
    entity_type: str
    identifiers: list[EntityIdentifier] = Field(default_factory=list)
    aliases: list[str] = Field(default_factory=list)
    jurisdiction: str
    match_status: MatchStatus
    resolution_method: str
    supporting_sources: list[str] = Field(default_factory=list)
    reviewer: str | None = None
    reviewed_at: datetime | None = None
    trust_zone: TrustZone = TrustZone.CANONICAL
    public_release_status: ReleaseStatus = ReleaseStatus.BLOCKED


class MoneyEvent(StrictModel):
    event_id: str = Field(pattern=r"^EVT-[A-Z0-9-]+$")
    flow_id: str = Field(pattern=r"^FLOW-[A-Z0-9-]+$")
    event_type: MoneyEventType
    source_entity: str
    recipient_entity: str
    intermediary_entity: str | None = None
    program: str
    amount: Decimal
    currency: str = Field(default="USD", min_length=3, max_length=3)
    event_date: date | None = None
    period_start: date
    period_end: date
    fiscal_year: str
    geographic_scope: str
    source_records: list[str] = Field(min_length=1)
    parent_event_id: str | None = None
    aggregation_group: str | None = None
    aggregation_permission: bool = False
    verification_status: VerificationStatus
    interpretation_note: str
    trust_zone: TrustZone = TrustZone.CANONICAL
    public_release_status: ReleaseStatus = ReleaseStatus.BLOCKED

    @model_validator(mode="after")
    def validate_period(self) -> MoneyEvent:
        if self.period_end < self.period_start:
            raise ValueError("period_end must not precede period_start")
        return self


class OutcomeRecord(StrictModel):
    outcome_id: str = Field(pattern=r"^OUT-[A-Z0-9-]+$")
    reporting_entity: str
    program: str
    metric_name: str
    metric_definition: str
    numerator: Decimal | None = None
    denominator: Decimal | None = None
    period_start: date
    period_end: date
    population: str
    geographic_scope: str
    reporting_basis: str
    attribution_class: AttributionClass
    source_records: list[str] = Field(min_length=1)
    comparability_status: str
    limitations: list[str] = Field(default_factory=list)
    trust_zone: TrustZone = TrustZone.CANONICAL
    public_release_status: ReleaseStatus = ReleaseStatus.BLOCKED


class ReviewState(StrictModel):
    reviewer_role: str
    status: Literal["not_started", "in_progress", "passed", "failed", "not_required"]
    reviewer: str | None = None
    reviewed_at: datetime | None = None
    notes: str | None = None


class ClaimRecord(StrictModel):
    claim_id: str = Field(pattern=r"^CLM-[A-Z0-9-]+$")
    exact_statement: str
    claim_class: ClaimClass
    origin: ClaimOrigin
    subjects: list[str] = Field(default_factory=list)
    supporting_sources: list[str] = Field(min_length=1)
    contrary_sources: list[str] = Field(default_factory=list)
    alternative_explanations: list[str] = Field(default_factory=list)
    factual_review: ReviewState
    accounting_review: ReviewState
    adversarial_review: ReviewState
    privacy_review: ReviewState
    legal_review: ReviewState
    substantive_review: ReviewState
    subject_response: str | None = None
    trust_zone: TrustZone = TrustZone.CANONICAL
    publication_status: ReleaseStatus = ReleaseStatus.BLOCKED
    public_release_status: ReleaseStatus = ReleaseStatus.BLOCKED


class CorrectionRecord(StrictModel):
    correction_id: str = Field(pattern=r"^COR-[A-Z0-9-]+$")
    affected_claim: str
    original_statement: str
    corrected_statement: str
    reason: str
    materiality: Literal["minor", "material", "withdrawal"]
    discovered_at: datetime
    corrected_at: datetime
    reviewer: str
    affected_releases: list[str] = Field(default_factory=list)
    supersedes_correction: str | None = None
    trust_zone: TrustZone = TrustZone.PUBLIC
    public_release_status: ReleaseStatus = ReleaseStatus.APPROVED


class ReleaseManifest(StrictModel):
    release_id: str = Field(pattern=r"^REL-[A-Z0-9-]+$")
    version: str
    case_ids: list[str]
    included_claims: list[str]
    included_sources: list[str]
    excluded_restricted_records: list[str]
    build_commit: str
    build_workflow: str
    generated_at: datetime
    software_versions: dict[str, str]
    dataset_hashes: dict[str, str]
    technical_certificate: ReviewState
    substantive_certificate: ReviewState
    deployment_approval: ReviewState


class CaseRecord(StrictModel):
    case_id: str = Field(pattern=r"^LSC-[A-Z0-9-]+$")
    title: str
    jurisdiction: str
    operating_focus: str
    primary_period: str
    mission_question: str
    publication_authority: Literal["none", "limited", "approved"] = "none"
    no_misconduct_notice: str
    status: Literal["shadow", "review", "public", "closed"] = "shadow"
