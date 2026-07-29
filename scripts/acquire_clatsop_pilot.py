from __future__ import annotations

import hashlib
import json
import re
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError:  # pragma: no cover
    PdfReader = None  # type: ignore[assignment]

ROOT = Path("pilot-acquisition")
RAW = ROOT / "raw"
TEXT = ROOT / "text"
MANIFEST = ROOT / "manifest.json"
SUMMARY = ROOT / "PUBLIC-EVIDENCE-SUMMARY.md"
USER_AGENT = (
    "GARI-LANTERN/0.2 public-record-preservation "
    "(+https://github.com/Atlas-Ascend/GARI-)"
)
MAC_PAGE = (
    "https://www.clatsopcounty.gov/257/"
    "Homelessness-MAC-Group-in-Clatsop-County"
)

Target = tuple[str, str, str, str]

SEED_TARGETS: list[Target] = [
    (
        "BOS_MASTER_PLAN",
        "Clatsop Regional Plan / BOS Master Agreement",
        "https://www.clatsopcounty.gov/DocumentCenter/View/1198/"
        "Bos-Master-Grant-Agreements",
        "regional plan and target definitions",
    ),
    (
        "IGA_8078",
        "Balance of State IGA Agreement 8078",
        "https://www.clatsopcounty.gov/DocumentCenter/View/1204/"
        "Balance-of-the-State-Iga-State-of-Emergency-Due-to-Homelessness",
        "state-to-county reimbursement grant",
    ),
    (
        "CCA_BOS_AMENDMENT",
        "CCA BOS Subrecipient Agreement Amendment",
        "https://www.clatsopcounty.gov/DocumentCenter/View/1228/"
        "Clatsop-Community-Action-Subrecipient-Agreement-Bos-Amend",
        "county-to-provider amendment",
    ),
    (
        "ORI_IGA",
        "Oregon Rehousing Initiative IGA",
        "https://www.clatsopcounty.gov/DocumentCenter/View/1237/"
        "Oregon-Rehousing-Initiative-Ori-Eo-24-02-Intergovernmental-Agreement",
        "state-to-county rehousing grant",
    ),
    (
        "CCA_ORI",
        "CCA ORI Subrecipient Agreement",
        "https://www.clatsopcounty.gov/DocumentCenter/View/1243/"
        "Signed-Ori-Agreement-Cca",
        "county-to-provider rehousing agreement",
    ),
    (
        "REGIONAL_FAQ",
        "Regional Shelter Program FAQ",
        "https://www.clatsopcounty.gov/DocumentCenter/View/4220/"
        "1--FAQ---Regional-Shelter-Program",
        "later funding and capacity summary",
    ),
    (
        "SSP_9314",
        "OHCS Statewide Shelter Program Grant 9314",
        "https://www.clatsopcounty.gov/DocumentCenter/View/4251/"
        "3--Fully-Executed---OHCS-number-9314",
        "current control framework",
    ),
    (
        "CCA_LTRA",
        "CCA LTRA Subrecipient Agreement",
        "https://www.clatsopcounty.gov/DocumentCenter/View/4250/"
        "5--LTRA---CCA-Subrecipient-Agreement",
        "later provider agreement",
    ),
    (
        "COLUMBIA_JAN_2024",
        "Columbia Inn January 2024 Report",
        "https://www.clatsopcounty.gov/DocumentCenter/View/1472/"
        "Columbia-Inn---January-2024-Report",
        "early operating and outcome report",
    ),
    (
        "OREGON_SUBGRANTEE_MAY_2024",
        "EO 23-02 and 24-02 Subgrantees Information, May 2024",
        "https://olis.oregonlegislature.gov/liz/2023I1/Downloads/"
        "CommitteeMeetingDocument/283981",
        "statewide allocation schedule",
    ),
    (
        "CCA_990_2024_XML",
        "CCA Form 990 XML, fiscal year ending June 2024",
        "https://projects.propublica.org/nonprofits/download-xml?"
        "object_id=202631189349301248",
        "IRS-derived organization-wide filing",
    ),
    (
        "CCA_ANNUAL_2023_2024",
        "CCA 2023-2024 Annual Report",
        "https://ccaservices.org/docs/2018_events/"
        "Annual_Report_2023-2024.pdf",
        "provider-published annual outcomes",
    ),
    (
        "PROVIDENCE_FY23",
        "Providence Seaside FY2023 Community Benefit Narrative",
        "https://www.oregon.gov/oha/HPA/ANALYTICS/HospitalDocuments/"
        "FY23%20CBR-1%20Narrative%20Providence%20Seaside%20Hospital.pdf",
        "independent grant and service statement",
    ),
]

PATTERNS = [
    re.compile(value, re.I)
    for value in (
        r"not to exceed.{0,180}",
        r"reimburse.{0,180}",
        r"payment.{0,180}",
        r"Columbia.{0,220}",
        r"rehous.{0,180}",
        r"shelter beds?.{0,180}",
        r"monitor.{0,180}",
        r"report.{0,180}",
        r"utilization.{0,180}",
        r"corrective action.{0,180}",
        r"\$[0-9,]+(?:\.[0-9]{2})?",
    )
]


@dataclass
class Record:
    record_id: str
    title: str
    url: str
    role: str
    status: str
    http_status: int | None
    content_type: str | None
    final_url: str | None
    acquired_at: str
    byte_size: int | None
    sha256: str | None
    filename: str | None
    text_filename: str | None
    page_count: int | None
    extraction_notes: list[str]
    selected_evidence: list[str]
    error: str | None


def safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", value).strip("_")


def fetch(url: str, attempts: int = 3) -> tuple[bytes, int, str, str]:
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        request = urllib.request.Request(
            url,
            headers={
                "User-Agent": USER_AGENT,
                "Accept": (
                    "application/pdf, application/xml, text/xml, "
                    "text/html;q=0.9, */*;q=0.5"
                ),
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                return (
                    response.read(),
                    int(getattr(response, "status", 200)),
                    response.headers.get_content_type(),
                    response.geturl(),
                )
        except Exception as error:  # noqa: BLE001
            last_error = error
            if attempt < attempts:
                time.sleep(attempt * 2)
    if last_error is None:
        raise RuntimeError("acquisition failed without an exception")
    raise last_error


def discover_document_links() -> list[Target]:
    try:
        body, _, _, final_url = fetch(MAC_PAGE)
    except Exception as error:  # noqa: BLE001
        print(f"MAC_DISCOVERY_ERROR: {error}", file=sys.stderr)
        return []
    html = body.decode("utf-8", errors="replace")
    hrefs = re.findall(
        r'href=["\']([^"\']*DocumentCenter/View/[^"\']+)["\']',
        html,
        flags=re.I,
    )
    discovered: list[Target] = []
    seen: set[str] = set()
    for index, href in enumerate(hrefs, start=1):
        absolute = urllib.parse.urljoin(final_url, href.replace("&amp;", "&"))
        if absolute in seen:
            continue
        seen.add(absolute)
        match = re.search(r"/View/(\d+)(?:/([^?#]+))?", absolute)
        document_id = match.group(1) if match else f"DISCOVERED_{index}"
        slug = (
            urllib.parse.unquote(match.group(2))
            if match and match.group(2)
            else "document"
        )
        discovered.append(
            (
                f"DISCOVERED_{document_id}",
                slug.replace("-", " "),
                absolute,
                "document linked from official MAC page",
            )
        )
    print(f"MAC_DISCOVERY_COUNT={len(discovered)}")
    return discovered


def extract_pdf(path: Path) -> tuple[str, int | None, list[str]]:
    if PdfReader is None:
        return "", None, ["pypdf unavailable"]
    notes: list[str] = []
    try:
        reader = PdfReader(str(path))
        chunks: list[str] = []
        for index, page in enumerate(reader.pages, start=1):
            try:
                chunks.append(f"\n--- PAGE {index} ---\n{page.extract_text() or ''}")
            except Exception as error:  # noqa: BLE001
                notes.append(f"page {index} extraction error: {error}")
        return "\n".join(chunks), len(reader.pages), notes
    except Exception as error:  # noqa: BLE001
        return "", None, [f"PDF extraction error: {error}"]


def extract_xml(text: str) -> list[str]:
    try:
        root = ET.fromstring(text)
    except ET.ParseError as error:
        return [f"XML parse error: {error}"]
    wanted = {
        "TaxPeriodEndDt",
        "CYTotalRevenueAmt",
        "CYTotalExpensesAmt",
        "TotalAssetsEOYAmt",
        "TotalLiabilitiesEOYAmt",
        "GovernmentGrantsAmt",
        "ContributionsGrantsAmt",
        "ProgramServiceRevenueAmt",
        "TotalEmployeeCnt",
        "TotalVolunteersCnt",
    }
    evidence = []
    for node in root.iter():
        local = node.tag.rsplit("}", 1)[-1]
        if local in wanted and node.text:
            evidence.append(f"{local}={node.text.strip()}")
    return sorted(set(evidence))


def select_evidence(text: str, limit: int = 80) -> list[str]:
    normalized = re.sub(r"[\t\r ]+", " ", text)
    evidence: list[str] = []
    for pattern in PATTERNS:
        for match in pattern.finditer(normalized):
            item = re.sub(r"\s+", " ", match.group(0)).strip()
            if item and item not in evidence:
                evidence.append(item[:420])
            if len(evidence) >= limit:
                return evidence
    return evidence


def unique_targets(items: list[Target]) -> list[Target]:
    by_url: dict[str, Target] = {}
    for item in items:
        by_url.setdefault(item[2], item)
    return list(by_url.values())


def acquire(record_id: str, title: str, url: str, role: str) -> Record:
    acquired_at = datetime.now(timezone.utc).isoformat()
    http_status: int | None = None
    try:
        body, http_status, content_type, final_url = fetch(url)
        digest = hashlib.sha256(body).hexdigest()
        basename = Path(urllib.parse.urlparse(final_url).path).name
        extension = ".pdf" if body.startswith(b"%PDF") else Path(basename).suffix
        filename = f"{safe_name(record_id)}{extension or '.bin'}"
        raw_path = RAW / filename
        raw_path.write_bytes(body)

        pages: int | None = None
        notes: list[str] = []
        selected: list[str] = []
        text_filename: str | None = None
        if body.startswith(b"%PDF"):
            text, pages, notes = extract_pdf(raw_path)
            if text:
                text_filename = f"{safe_name(record_id)}.txt"
                (TEXT / text_filename).write_text(text, encoding="utf-8")
                selected = select_evidence(text)
        else:
            decoded = body.decode("utf-8", errors="replace")
            text_filename = f"{safe_name(record_id)}.txt"
            (TEXT / text_filename).write_text(decoded, encoding="utf-8")
            is_xml = "xml" in content_type or decoded.lstrip().startswith("<?xml")
            selected = extract_xml(decoded) if is_xml else select_evidence(decoded)

        return Record(
            record_id,
            title,
            url,
            role,
            "acquired",
            http_status,
            content_type,
            final_url,
            acquired_at,
            len(body),
            digest,
            filename,
            text_filename,
            pages,
            notes,
            selected,
            None,
        )
    except Exception as error:  # noqa: BLE001
        return Record(
            record_id,
            title,
            url,
            role,
            "unavailable",
            http_status,
            None,
            None,
            acquired_at,
            None,
            None,
            None,
            None,
            None,
            [],
            [],
            f"{type(error).__name__}: {error}",
        )


def build_summary(records: list[Record]) -> str:
    acquired = [item for item in records if item.status == "acquired"]
    unavailable = [item for item in records if item.status != "acquired"]
    lines = [
        "# LANTERN Pilot Run 002 · Public Evidence Acquisition Summary",
        "",
        f"Generated: {datetime.now(timezone.utc).isoformat()}",
        "",
        (
            "This packet records public-source acquisition only. It does not "
            "establish reimbursement, county payment, provider expenditure, "
            "causal outcome, or misconduct unless a source expressly supports it."
        ),
        "",
        f"- Records acquired: **{len(acquired)}**",
        f"- Records unavailable: **{len(unavailable)}**",
        "- Hash algorithm: **SHA-256 over actual response bytes**",
        "",
        "## Acquisition manifest",
        "",
        "| ID | Status | Bytes | Pages | SHA-256 | Title |",
        "|---|---:|---:|---:|---|---|",
    ]
    for record in records:
        digest = record.sha256 or "unavailable"
        lines.append(
            "| {id} | {status} | {size} | {pages} | `{digest}` | {title} |".format(
                id=record.record_id,
                status=record.status,
                size=record.byte_size or "—",
                pages=record.page_count or "—",
                digest=digest,
                title=record.title.replace("|", "/"),
            )
        )
    lines.extend(
        [
            "",
            "## Publication result",
            "",
            "The public record supports a typed map of grants, allocations, "
            "contracts, reporting duties, targets, and organization-wide filing "
            "context. It does not yet establish a complete FY 2024-25 chain of "
            "county payments, Columbia Inn program expenditures, or independently "
            "verified provider outcomes.",
            "",
            "## Remaining records",
            "",
            "- County reimbursement requests and approvals",
            "- County payment-ledger entries",
            "- Columbia Inn aggregate expenditure reports",
            "- Monitoring and closeout records",
            "- Monthly utilization and housing-exit reports",
            "- Independent accounting, factual, privacy, and legal review",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    RAW.mkdir(parents=True, exist_ok=True)
    TEXT.mkdir(parents=True, exist_ok=True)
    targets = unique_targets(SEED_TARGETS + discover_document_links())
    records = [acquire(*target) for target in targets]
    MANIFEST.write_text(
        json.dumps([asdict(item) for item in records], indent=2),
        encoding="utf-8",
    )
    SUMMARY.write_text(build_summary(records), encoding="utf-8")
    acquired = sum(item.status == "acquired" for item in records)
    print(f"PILOT_ACQUISITION_COMPLETE total={len(records)} acquired={acquired}")
    return 0 if acquired >= 6 else 1


if __name__ == "__main__":
    raise SystemExit(main())
