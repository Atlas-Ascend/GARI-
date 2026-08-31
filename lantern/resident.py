from __future__ import annotations

import argparse
import hashlib
import json
import os
import time
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, cast
from urllib.parse import urlparse

from lantern.validators import ValidationFailure, load_case, validate_bundle

STARTED = time.time()


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


class JarvisGariResident:
    """Bounded resident adapter over the existing GARI Lantern evidence kernel."""

    def __init__(self, *, case_root: Path, receipt_root: Path) -> None:
        self.case_root = case_root
        self.receipt_root = receipt_root
        self.receipt_root.mkdir(parents=True, exist_ok=True)

    def cases(self) -> list[str]:
        if not self.case_root.exists():
            return []
        return sorted(path.name for path in self.case_root.iterdir() if path.is_dir())

    def status(self) -> dict[str, Any]:
        cases = self.cases()
        return {
            "ok": True,
            "schema": "ghost-atlas.gari-jarvis-resident.v1",
            "resident": "JARVIS",
            "domain": "GARI",
            "state": "LIVE",
            "node": os.environ.get("COMPUTERNAME") or os.environ.get("HOSTNAME") or "EDEN",
            "case_root": str(self.case_root),
            "case_count": len(cases),
            "cases": cases,
            "uptime_seconds": round(time.time() - STARTED, 3),
            "observed_at": utc_now(),
            "authority_ceiling": {
                "may": [
                    "suggest evidence searches",
                    "summarize bounded case posture",
                    "validate canonical GARI bundles",
                    "surface discrepancies and alternative explanations",
                    "return provenance-aware context to Atlas Mind",
                ],
                "may_not": [
                    "merge entities autonomously",
                    "certify accounting",
                    "decide criminality or misconduct",
                    "approve a claim",
                    "publish autonomously",
                ],
            },
            "truth_boundary": (
                "JARVIS is a resident interface over the existing GARI Lantern evidence kernel. "
                "It does not create publication authority or convert candidate analysis into a finding."
            ),
        }

    def capabilities(self) -> dict[str, Any]:
        return {
            "ok": True,
            "schema": "ghost-atlas.gari-jarvis-capabilities.v1",
            "resident": "JARVIS",
            "domain": "GARI",
            "capabilities": [
                {"id": "research.synthesize", "mode": "bounded_evidence_context", "provable": True},
                {"id": "gari.case.status", "mode": "read_only", "provable": True},
                {"id": "gari.case.validate", "mode": "read_only_validation", "provable": True},
                {"id": "gari.provenance.context", "mode": "read_only", "provable": True},
            ],
            "publication_authority": False,
            "observed_at": utc_now(),
        }

    def _case_context(self, case_id: str) -> dict[str, Any]:
        case_dir = self.case_root / case_id
        bundle = load_case(case_dir)
        validation_state = "VALID"
        validation_notes: list[str] = []
        validation_error: str | None = None
        try:
            validation_notes = list(validate_bundle(bundle))
        except (ValidationFailure, ValueError, OSError, json.JSONDecodeError) as exc:
            validation_state = "BLOCKED"
            validation_error = str(exc)

        payload: dict[str, Any] = {
            "case_id": bundle.case.case_id,
            "title": bundle.case.title,
            "status": str(bundle.case.status),
            "publication_authority": str(bundle.case.publication_authority),
            "no_misconduct_notice": bundle.case.no_misconduct_notice,
            "counts": {
                "sources": len(bundle.sources),
                "entities": len(bundle.entities),
                "money_events": len(bundle.money_events),
                "claims": len(bundle.claims),
                "corrections": len(bundle.corrections),
            },
            "validation": {
                "state": validation_state,
                "notes": validation_notes,
                "error": validation_error,
            },
        }
        return payload

    def context(self, body: dict[str, Any]) -> dict[str, Any]:
        query = str(body.get("query") or body.get("prompt") or "").strip()
        requested_case = str(body.get("case_id") or "").strip()
        available = self.cases()

        if requested_case:
            if requested_case not in available:
                raise ValueError(f"unknown case_id: {requested_case}")
            case_context: dict[str, Any] | None = self._case_context(requested_case)
        else:
            case_context = None

        response: dict[str, Any] = {
            "ok": True,
            "schema": "ghost-atlas.gari-jarvis-context.v1",
            "resident": "JARVIS",
            "domain": "GARI",
            "mode": "CONTEXT_ONLY",
            "query": query,
            "requested_case_id": requested_case or None,
            "available_cases": available,
            "case": case_context,
            "instructions": [
                "Treat this as evidence context, not a finding.",
                "Preserve uncertainty and provenance boundaries.",
                "Do not infer misconduct from inclusion, discrepancy, absence, or unresolved status.",
                "Publication and claim approval remain outside JARVIS authority.",
            ],
            "observed_at": utc_now(),
        }
        response["receipt"] = self._emit_receipt("context", body, response)
        return response

    def validate_case(self, body: dict[str, Any]) -> dict[str, Any]:
        case_id = str(body.get("case_id") or "").strip()
        if not case_id:
            raise ValueError("case_id required")
        context = self._case_context(case_id)
        response: dict[str, Any] = {
            "ok": context["validation"]["state"] == "VALID",
            "schema": "ghost-atlas.gari-jarvis-validation.v1",
            "resident": "JARVIS",
            "domain": "GARI",
            "case": context,
            "observed_at": utc_now(),
        }
        response["receipt"] = self._emit_receipt("validate", body, response)
        return response

    def _emit_receipt(
        self,
        action: str,
        request_body: dict[str, Any],
        response_body: dict[str, Any],
    ) -> dict[str, Any]:
        receipt_id = (
            "JARVIS-GARI-"
            + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
            + "-"
            + uuid.uuid4().hex[:10]
        )
        receipt_path = self.receipt_root / f"{receipt_id}.json"
        response_without_receipt = dict(response_body)
        response_without_receipt.pop("receipt", None)
        receipt: dict[str, Any] = {
            "schema": "ghost-atlas.gari-jarvis-receipt.v1",
            "id": receipt_id,
            "state": "RETURNED",
            "timestamp": utc_now(),
            "resident": "JARVIS",
            "domain": "GARI",
            "action": action,
            "request_sha256": sha256_bytes(canonical_bytes(request_body)),
            "response_sha256": sha256_bytes(canonical_bytes(response_without_receipt)),
            "receipt_path": str(receipt_path),
            "publication_authority": False,
            "truth_boundary": (
                "Receipt proves the bounded resident action and returned context/validation state only; "
                "it does not certify a substantive finding or publication decision."
            ),
        }
        receipt_path.write_text(json.dumps(receipt, indent=2, ensure_ascii=False), encoding="utf-8")
        return receipt


class Handler(BaseHTTPRequestHandler):
    server_version = "JarvisGariResident/1.0"

    @property
    def resident(self) -> JarvisGariResident:
        return cast(JarvisGariResident, getattr(self.server, "resident"))

    def log_message(self, fmt: str, *args: Any) -> None:
        print(f"{utc_now()} {fmt % args}", flush=True)

    def send_json(self, status: int, body: Any) -> None:
        payload = canonical_bytes(body)
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def read_json(self) -> dict[str, Any]:
        size = int(self.headers.get("Content-Length", "0") or "0")
        if size < 1 or size > 2_000_000:
            raise ValueError("invalid request size")
        value = json.loads(self.rfile.read(size).decode("utf-8"))
        if not isinstance(value, dict):
            raise ValueError("JSON object required")
        return value

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        try:
            if path == "/gari/v1/status":
                self.send_json(200, self.resident.status())
            elif path == "/gari/v1/capabilities":
                self.send_json(200, self.resident.capabilities())
            elif path == "/gari/v1/cases":
                cases = self.resident.cases()
                self.send_json(
                    200,
                    {"ok": True, "cases": cases, "count": len(cases), "observed_at": utc_now()},
                )
            else:
                self.send_json(404, {"ok": False, "error": "NOT_FOUND"})
        except Exception as exc:
            self.send_json(503, {"ok": False, "error": str(exc), "observed_at": utc_now()})

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        try:
            body = self.read_json()
            if path == "/gari/v1/context":
                self.send_json(200, self.resident.context(body))
            elif path == "/gari/v1/validate":
                result = self.resident.validate_case(body)
                self.send_json(200 if result["ok"] else 409, result)
            else:
                self.send_json(404, {"ok": False, "error": "NOT_FOUND"})
        except ValueError as exc:
            self.send_json(400, {"ok": False, "error": str(exc)})
        except Exception as exc:
            self.send_json(500, {"ok": False, "error": str(exc)})


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8772)
    parser.add_argument("--case-root", default="cases")
    parser.add_argument("--receipt-root", required=True)
    args = parser.parse_args()

    resident = JarvisGariResident(case_root=Path(args.case_root), receipt_root=Path(args.receipt_root))
    server = ThreadingHTTPServer((args.host, args.port), Handler)
    server.resident = resident  # type: ignore[attr-defined]
    print(
        json.dumps(
            {
                "state": "LISTENING",
                "resident": "JARVIS",
                "domain": "GARI",
                "endpoint": f"http://{args.host}:{args.port}/gari/v1",
                "case_root": str(Path(args.case_root)),
                "receipt_root": str(Path(args.receipt_root)),
                "timestamp": utc_now(),
            }
        ),
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
