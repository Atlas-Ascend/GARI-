from __future__ import annotations

import json
from pathlib import Path
from typing import Annotated

import typer

from lantern.models import (
    CaseRecord,
    ClaimRecord,
    CorrectionRecord,
    EntityRecord,
    MoneyEvent,
    OutcomeRecord,
    ReleaseManifest,
    SourceRecord,
)
from lantern.validators import ValidationFailure, load_case, public_projection, validate_bundle

app = typer.Typer(
    name="lantern",
    help="GARI LANTERN command-to-proof validation and release compiler.",
    no_args_is_help=True,
)


def _case_dir(case_id: str, root: Path) -> Path:
    return root / case_id


@app.command()
def validate(
    case_id: Annotated[str, typer.Argument(help="Case identifier")],
    root: Annotated[Path, typer.Option(help="Case data root")] = Path("cases"),
    as_json: Annotated[bool, typer.Option("--json", help="Emit JSON output")] = False,
) -> None:
    """Validate the complete evidence bundle and all publication gates."""
    try:
        bundle = load_case(_case_dir(case_id, root))
        notes = validate_bundle(bundle)
    except (ValidationFailure, ValueError, OSError, json.JSONDecodeError) as exc:
        if as_json:
            typer.echo(json.dumps({"ok": False, "case_id": case_id, "error": str(exc)}))
        else:
            typer.secho(f"BLOCKED {case_id}: {exc}", fg=typer.colors.RED)
        raise typer.Exit(code=1) from exc
    payload = {"ok": True, "case_id": case_id, "checks": notes}
    if as_json:
        typer.echo(json.dumps(payload, indent=2))
    else:
        typer.secho(f"VALID {case_id}", fg=typer.colors.GREEN)
        for note in notes:
            typer.echo(f"  ✓ {note}")


@app.command("case-status")
def case_status(
    case_id: Annotated[str, typer.Argument(help="Case identifier")],
    root: Annotated[Path, typer.Option(help="Case data root")] = Path("cases"),
) -> None:
    """Show the bounded case posture without implying a finding."""
    bundle = load_case(_case_dir(case_id, root))
    typer.echo(f"Case: {bundle.case.case_id}")
    typer.echo(f"Title: {bundle.case.title}")
    typer.echo(f"Status: {bundle.case.status}")
    typer.echo(f"Publication authority: {bundle.case.publication_authority}")
    typer.echo(f"Sources: {len(bundle.sources)}")
    typer.echo(f"Entities: {len(bundle.entities)}")
    typer.echo(f"Money events: {len(bundle.money_events)}")
    typer.echo(f"Claims: {len(bundle.claims)}")
    typer.echo(f"Notice: {bundle.case.no_misconduct_notice}")


@app.command("build-public")
def build_public(
    case_id: Annotated[str, typer.Argument(help="Case identifier")],
    root: Annotated[Path, typer.Option(help="Case data root")] = Path("cases"),
    output: Annotated[Path, typer.Option(help="Public JSON output file")] = Path(
        "site/data/case.json"
    ),
) -> None:
    """Compile only explicitly approved public records through an allowlist."""
    bundle = load_case(_case_dir(case_id, root))
    validate_bundle(bundle)
    payload = public_projection(bundle)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    typer.secho(f"PUBLIC BUILD WRITTEN: {output}", fg=typer.colors.GREEN)


@app.command("generate-schema")
def generate_schema(
    output: Annotated[Path, typer.Option(help="Schema output directory")] = Path("schemas"),
) -> None:
    """Generate version-controlled JSON Schemas from canonical Pydantic models."""
    output.mkdir(parents=True, exist_ok=True)
    models = {
        "case": CaseRecord,
        "source": SourceRecord,
        "entity": EntityRecord,
        "money-event": MoneyEvent,
        "outcome": OutcomeRecord,
        "claim": ClaimRecord,
        "correction": CorrectionRecord,
        "release": ReleaseManifest,
    }
    for name, model in models.items():
        target = output / f"{name}.schema.json"
        target.write_text(json.dumps(model.model_json_schema(), indent=2), encoding="utf-8")
        typer.echo(f"generated {target}")


@app.command("release-check")
def release_check(
    case_id: Annotated[str, typer.Argument(help="Case identifier")],
    root: Annotated[Path, typer.Option(help="Case data root")] = Path("cases"),
) -> None:
    """Fail unless technical, substantive, and deployment certificates all passed."""
    bundle = load_case(_case_dir(case_id, root))
    validate_bundle(bundle)
    if bundle.release is None:
        typer.secho("BLOCKED: release manifest does not exist", fg=typer.colors.RED)
        raise typer.Exit(code=1)
    required = [
        bundle.release.technical_certificate,
        bundle.release.substantive_certificate,
        bundle.release.deployment_approval,
    ]
    if any(item.status != "passed" for item in required):
        typer.secho("BLOCKED: release certificates are incomplete", fg=typer.colors.RED)
        raise typer.Exit(code=1)
    typer.secho(f"RELEASE READY: {bundle.release.release_id}", fg=typer.colors.GREEN)


if __name__ == "__main__":
    app()
