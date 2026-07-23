#!/usr/bin/env python3
"""
run_analytics.py — Execute the analytics + forecast SQL against warehouse.duckdb,
print a readable summary, and write each result to analytics/output/*.csv.

Run:  python analytics/run_analytics.py   (after `make dbt`)
"""
from __future__ import annotations

from pathlib import Path

import duckdb
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "warehouse.duckdb"
ANALYTICS_DIR = ROOT / "analytics"
OUT_DIR = ANALYTICS_DIR / "output"
FORECAST_SQL = ROOT / "forecasting" / "forecast.sql"

# Ordered list of (sql_file, [labels for each result-returning statement])
QUERIES: list[tuple[Path, list[str]]] = [
    (ANALYTICS_DIR / "01_channel_revenue_ranking.sql", ["channel_revenue_ranking"]),
    (ANALYTICS_DIR / "02_campaign_roi.sql", ["campaign_roi", "campaign_roi_coverage"]),
    (ANALYTICS_DIR / "03_cac_by_channel_company.sql", ["cac_by_channel_company"]),
    (ANALYTICS_DIR / "04_cohort_retention_by_channel.sql", ["cohort_retention_by_channel"]),
    (ANALYTICS_DIR / "05_revenue_trend_by_channel.sql", ["revenue_trend_by_channel"]),
    (FORECAST_SQL, ["forecast_3mo_by_company"]),
]


def split_statements(sql: str) -> list[str]:
    """Split a SQL file into individual statements (no semicolons inside our strings)."""
    return [s.strip() for s in sql.split(";") if s.strip()]


def is_query(stmt: str) -> bool:
    """True if a statement returns rows, ignoring leading -- comment / blank lines."""
    body = "\n".join(
        line for line in stmt.splitlines()
        if line.strip() and not line.strip().startswith("--")
    )
    return body.lower().lstrip().startswith(("select", "with"))


def main() -> int:
    if not DB_PATH.exists():
        print(f"ERROR: {DB_PATH} not found. Run `make ingest && make dbt` first.")
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(DB_PATH), read_only=True)
    pd.set_option("display.width", 160)
    pd.set_option("display.max_columns", 30)

    for sql_file, labels in QUERIES:
        statements = split_statements(sql_file.read_text())
        result_stmts = [s for s in statements if is_query(s)]
        for idx, stmt in enumerate(result_stmts):
            label = labels[idx] if idx < len(labels) else f"{sql_file.stem}_{idx + 1}"
            df = con.execute(stmt).fetchdf()
            out_path = OUT_DIR / f"{label}.csv"
            df.to_csv(out_path, index=False)
            print(f"\n{'=' * 78}\n{label}   ({len(df)} rows)  ->  {out_path.relative_to(ROOT)}\n{'-' * 78}")
            # show a preview (whole thing if small)
            preview = df if len(df) <= 16 else df.head(16)
            print(preview.to_string(index=False))
            if len(df) > 16:
                print(f"... ({len(df) - 16} more rows in the CSV)")

    con.close()
    print(f"\n{'=' * 78}\nAll analytics written to {OUT_DIR.relative_to(ROOT)}/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
