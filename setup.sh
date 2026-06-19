#!/usr/bin/env bash
# Sets up the local Python environment for analysis (pandas/numpy/scipy/
# sklearn/matplotlib) and checks that BigQuery access is reachable.
#
# This does NOT set up BigQuery auth itself -- that happens via OAuth the
# first time Claude Code calls the bigquery MCP tool. This script just
# checks gcloud is around and gives you a heads-up if it isn't, since some
# people prefer to pre-authenticate.

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "==> Creating Python virtual environment (venv/)..."
python3 -m venv venv

echo "==> Installing pinned requirements..."
./venv/bin/pip install --upgrade pip --quiet
./venv/bin/pip install -r requirements.txt --quiet

echo "==> Checking for gcloud CLI (optional, for pre-auth / sanity check)..."
if command -v gcloud >/dev/null 2>&1; then
  echo "    gcloud found: $(gcloud --version | head -n1)"
  echo "    Current project (if set): $(gcloud config get-value project 2>/dev/null || echo 'none set')"
else
  echo "    gcloud not found locally. That's fine -- BigQuery access in this"
  echo "    tool goes through OAuth via the bigquery MCP server, not gcloud."
  echo "    You'll be prompted to sign in with your Google account the first"
  echo "    time Claude Code calls a BigQuery tool."
fi

if [ ! -f .env ]; then
  echo "==> No .env found. Copying .env.example -> .env"
  cp .env.example .env
  echo "    Edit .env and set GCP_PROJECT_ID to your own project."
fi

mkdir -p outputs

echo ""
echo "Setup complete."
echo "Next steps:"
echo "  1. Edit .env and set GCP_PROJECT_ID to your own GCP project."
echo "  2. Run 'claude' in this directory."
echo "  3. The first BigQuery query will prompt you to OAuth into your Google account."
echo "  4. Try: /diagnose-telemetry"
