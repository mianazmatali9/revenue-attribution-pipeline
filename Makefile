# Cross-Portfolio Revenue Attribution & Forecasting Pipeline
# One-command local run. Everything targets a single DuckDB file (warehouse.duckdb).

PY := ./.venv/bin/python
DBT_DIR := transform

.PHONY: all setup data ingest dbt analytics dashboard clean help

help:
	@echo "make setup     - create .venv and install requirements"
	@echo "make data      - (re)generate deterministic seed data into data/"
	@echo "make ingest    - load 4 sources into DuckDB raw + write validation report"
	@echo "make dbt       - run dbt build (all models + tests)"
	@echo "make analytics - run the 5 analytics queries + forecast, write CSVs"
	@echo "make all       - ingest -> dbt -> analytics (assumes 'make setup' done)"
	@echo "make clean     - remove warehouse + dbt target + analytics output"

setup:
	python3 -m venv .venv
	$(PY) -m pip install --upgrade pip
	$(PY) -m pip install -r requirements.txt

data:
	$(PY) generate_data.py

ingest:
	$(PY) ingestion/ingest.py
	$(PY) ingestion/validate.py

dbt:
	cd $(DBT_DIR) && ../.venv/bin/dbt build --profiles-dir .

analytics:
	$(PY) analytics/run_analytics.py

all: ingest dbt analytics
	@echo ""
	@echo "Pipeline complete. Warehouse: warehouse.duckdb"
	@echo "Validation report: reports/validation_report.md"
	@echo "Analytics output:  analytics/output/*.csv"

clean:
	rm -f warehouse.duckdb warehouse.duckdb.wal
	rm -rf $(DBT_DIR)/target $(DBT_DIR)/logs
	rm -f analytics/output/*.csv
