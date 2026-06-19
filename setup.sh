#!/usr/bin/env bash
# Sets up the local Python environment for analysis (pandas/numpy/scipy/
# sklearn/matplotlib/duckdb) and checks BigQuery auth if you'll use it.
#
# Local files (CSV/JSON/Parquet) work with no extra setup beyond this
# script. BigQuery needs the gcloud CLI and a one-time
# `gcloud auth application-default login` -- this script does NOT do that
# for you, it only checks whether it's already done.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "==> Creating Python virtual environment (venv/)..."
python3 -m venv venv

echo "==> Installing pinned requirements..."
./venv/bin/pip install --upgrade pip --quiet
./venv/bin/pip install -r requirements.txt --quiet

echo "==> Checking BigQuery auth (skip this if you're only analyzing local files)..."
if ! command -v gcloud >/dev/null 2>&1; then
  echo "    gcloud CLI not found. Required for BigQuery -- install from"
  echo "    https://cloud.google.com/sdk/docs/install, then run:"
  echo "      gcloud auth application-default login"
elif ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
  echo "    gcloud found, but not authenticated for BigQuery yet. Run:"
  echo "      gcloud auth application-default login"
else
  echo "    gcloud authenticated. Current project: $(gcloud config get-value project 2>/dev/null || echo 'none set')"
fi

if [ ! -f .env ]; then
  echo "==> No .env found. Copying .env.example -> .env"
  cp .env.example .env
  echo "    Edit .env and set GCP_PROJECT_ID to your own project (BigQuery only)."
fi

mkdir -p outputs

echo ""
echo "Setup complete."
echo "Next steps:"
echo "  - Local files: cd into a folder with CSV/JSON/Parquet data, run 'claude', then /discover-files"
echo "  - BigQuery: edit .env, run 'gcloud auth application-default login' if you haven't, then 'claude' and /discover-schema"
