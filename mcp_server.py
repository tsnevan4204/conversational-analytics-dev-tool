#!/usr/bin/env python3
"""Read-only BigQuery MCP server.

Uses Application Default Credentials (gcloud auth application-default login).
Exposes a single tool: execute_sql_readonly — rejects any DDL/DML at the
code level before the query is sent to BigQuery.
"""
import asyncio
import json

from google.cloud import bigquery
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import TextContent, Tool

server = Server("bigquery-readonly")

_FORBIDDEN_VERBS = {
    "INSERT", "UPDATE", "DELETE", "MERGE",
    "CREATE", "DROP", "TRUNCATE", "ALTER", "REPLACE",
}


def _is_readonly(sql: str) -> bool:
    first_word = sql.strip().upper().split()[0] if sql.strip().split() else ""
    return first_word not in _FORBIDDEN_VERBS


@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="execute_sql_readonly",
            description=(
                "Execute a read-only SQL SELECT query against BigQuery. "
                "DDL and DML are rejected. Returns up to 3,000 rows."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "sql": {"type": "string", "description": "SQL SELECT query to run."},
                    "project_id": {
                        "type": "string",
                        "description": "GCP project ID (optional; uses ADC default if omitted).",
                    },
                },
                "required": ["sql"],
            },
        )
    ]


@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name != "execute_sql_readonly":
        raise ValueError(f"Unknown tool: {name}")

    sql = arguments.get("sql", "").strip()
    project_id = arguments.get("project_id") or None

    if not _is_readonly(sql):
        return [TextContent(type="text", text="Error: only SELECT queries are permitted.")]

    try:
        client = bigquery.Client(project=project_id)
        rows = list(client.query(sql).result(max_results=3000))
        if not rows:
            result = {"columns": [], "rows": [], "row_count": 0}
        else:
            headers = list(rows[0].keys())
            result = {
                "columns": headers,
                "rows": [dict(r) for r in rows],
                "row_count": len(rows),
            }
        return [TextContent(type="text", text=json.dumps(result, default=str))]
    except Exception as e:
        return [TextContent(type="text", text=f"Error: {e}")]


async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
