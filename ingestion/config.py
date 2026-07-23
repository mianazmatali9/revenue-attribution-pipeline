"""Shared paths for the ingestion + analytics layers.

Everything resolves relative to the repo root so scripts run from anywhere.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"
DB_PATH = ROOT / "warehouse.duckdb"
REPORTS_DIR = ROOT / "reports"
ANALYTICS_OUT = ROOT / "analytics" / "output"

# Canonical source files
SOURCES = {
    "raw_campaign_metadata": DATA_DIR / "campaign_metadata.csv",
    "raw_content_performance": DATA_DIR / "content_performance.csv",
    "raw_portfolio_revenue": DATA_DIR / "portfolio_revenue.csv",
    "raw_user_signups": DATA_DIR / "user_signups.json",
}

# The four portfolio companies (reference dimension).
COMPANIES = {
    "CTC-001": "GreenLeaf Landscaping",
    "CTC-002": "BrightPath Education",
    "CTC-003": "QuickFix Auto Repair",
    "CTC-004": "Summit Dental Group",
}

# Paid/owned content channels vs. the extra signup-only channels.
CONTENT_CHANNELS = ["youtube", "twitter", "instagram", "newsletter", "podcast", "blog"]
SIGNUP_CHANNELS = CONTENT_CHANNELS + ["organic", "referral"]
