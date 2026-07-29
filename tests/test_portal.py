from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PORTAL = ROOT / "site" / "index.html"


def test_full_public_portal_contains_required_system_surfaces() -> None:
    html = PORTAL.read_text(encoding="utf-8")
    required_routes = {
        "home",
        "cases",
        "pilot",
        "money",
        "contracts",
        "organizations",
        "sources",
        "outcomes",
        "claims",
        "corrections",
        "requests",
        "methodology",
        "governance",
        "contribute",
        "security",
        "limitations",
    }
    for route in required_routes:
        assert f'data-route="{route}"' in html
        assert f"{route}:()=>" in html


def test_pilot_controls_remain_visible_and_nonaccusatory() -> None:
    html = PORTAL.read_text(encoding="utf-8")
    required_text = [
        "LSC-OR-CLATSOP-001",
        "Publication authority: none",
        "Misconduct findings: 0",
        "Amounts remain typed",
        "Targets are not results",
        "No total-spending number is displayed",
        "Inconclusive is an acceptable result",
    ]
    for text in required_text:
        assert text in html


def test_pilot_data_does_not_request_client_level_records() -> None:
    html = PORTAL.read_text(encoding="utf-8")
    assert "All utilization and outcome requests are aggregate-only" in html
    assert "No client names" in html
