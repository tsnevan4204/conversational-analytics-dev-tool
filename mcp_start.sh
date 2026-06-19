#!/usr/bin/env bash
# MCP server launcher — works for both local clones and plugin installs.
#
# Local clone:  ./setup.sh creates venv/ → uses venv/bin/python
# Plugin install: no venv → uses `uv run` (auto-installs deps, cached globally)
#
# Install uv if needed: curl -LsSf https://astral.sh/uv/install.sh | sh
#
# Usage: mcp_start.sh <bigquery|local-files>
# To add a new data source: drop in a new case branch + mcp_<name>_server.py.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="${1:?usage: mcp_start.sh <bigquery|local-files>}"

case "$SERVER" in
    bigquery)
        PYFILE="mcp_bigquery_server.py"
        EXTRA_DEP="google-cloud-bigquery>=3.0.0"
        ;;
    local-files)
        PYFILE="mcp_local_server.py"
        EXTRA_DEP="duckdb>=1.0.0"
        ;;
    *)
        echo "ERROR: unknown server '$SERVER' (expected: bigquery, local-files)" >&2
        exit 1
        ;;
esac

if [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
    exec "$SCRIPT_DIR/venv/bin/python" "$SCRIPT_DIR/$PYFILE"
elif command -v uv >/dev/null 2>&1; then
    exec uv run --with "$EXTRA_DEP" --with "mcp>=1.0.0" python "$SCRIPT_DIR/$PYFILE"
else
    echo "ERROR: No Python environment found." >&2
    echo "  Option A (local clone): run ./setup.sh" >&2
    echo "  Option B (plugin): install uv — curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    exit 1
fi
