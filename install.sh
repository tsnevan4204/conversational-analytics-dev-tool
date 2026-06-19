#!/usr/bin/env bash
# One-command installer for conversational-analytics-dev-tool.
# Usage: curl -fsSL https://raw.githubusercontent.com/tsnevan4204/conversational-analytics-dev-tool/main/install.sh | bash

set -e

REPO="https://github.com/tsnevan4204/conversational-analytics-dev-tool.git"
INSTALL_DIR="$HOME/conversational-analytics"

echo ""
echo "=== Conversational Analytics Dev Tool ==="
echo ""

# --- Prerequisites check ---
fail() { echo "ERROR: $1"; exit 1; }

command -v python3 >/dev/null 2>&1 || fail "Python 3 is required. Install from https://python.org"
command -v git    >/dev/null 2>&1 || fail "git is required."
command -v claude >/dev/null 2>&1 || fail "Claude Code CLI is required. Install from https://docs.anthropic.com/en/docs/claude-code"

if ! command -v gcloud >/dev/null 2>&1; then
  echo "NOTE: gcloud CLI not found. Only needed for BigQuery -- skip if you're"
  echo "      just analyzing local CSV/JSON/Parquet files. Install from"
  echo "      https://cloud.google.com/sdk/docs/install if you need BigQuery."
  echo ""
fi

PYTHON_VERSION=$(python3 -c "import sys; print(sys.version_info.minor)")
[ "$PYTHON_VERSION" -ge 10 ] || fail "Python 3.10+ required (found 3.$PYTHON_VERSION)."

echo "✓ Prerequisites found"
echo ""

# --- Clone ---
if [ -d "$INSTALL_DIR" ]; then
  echo "Directory $INSTALL_DIR already exists — pulling latest changes."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "Cloning into $INSTALL_DIR ..."
  git clone "$REPO" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# --- Venv + dependencies ---
echo ""
echo "Setting up Python environment ..."
./setup.sh

# --- .env ---
if [ ! -f .env ]; then
  cp .env.example .env
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo ""
echo "  Analyzing local CSV/JSON/Parquet files? Just:"
echo "    cd $INSTALL_DIR && claude"
echo "    Then run: /discover-files"
echo ""
echo "  Analyzing BigQuery? First:"
echo "    1. Edit $INSTALL_DIR/.env with your GCP project and dataset:"
echo "         GCP_PROJECT_ID=your-project-id"
echo "         GCP_DATASET=your-dataset-name"
echo "    2. Grant IAM roles (bigquery.jobUser, bigquery.dataViewer, mcp.toolUser)"
echo "       on your GCP project to your Google account."
echo "       See README.md for the gcloud one-liner."
echo "    3. Authenticate (required -- BigQuery queries fail without this):"
echo "         gcloud auth application-default login"
echo "    4. cd $INSTALL_DIR && claude"
echo "       Then run: /discover-schema"
echo ""
