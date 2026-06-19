#!/usr/bin/env bash
# MCP server launcher — works for both local clones and plugin installs.
#
# Local clone:  ./setup.sh creates venv/ → uses venv/bin/python
# Plugin install: no venv → uses `uv run` (auto-installs deps, cached globally)
#
# Install uv if needed: curl -LsSf https://astral.sh/uv/install.sh | sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
    exec "$SCRIPT_DIR/venv/bin/python" "$SCRIPT_DIR/mcp_server.py"
elif command -v uv >/dev/null 2>&1; then
    exec uv run \
        --with "google-cloud-bigquery>=3.0.0" \
        --with "mcp>=1.0.0" \
        python "$SCRIPT_DIR/mcp_server.py"
else
    echo "ERROR: No Python environment found." >&2
    echo "  Option A (local clone): run ./setup.sh" >&2
    echo "  Option B (plugin): install uv — curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    exit 1
fi
