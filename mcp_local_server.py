#!/usr/bin/env python3
"""Read-only DuckDB MCP server for local files (CSV/JSON/Parquet).

Lets Claude run SQL directly against files on disk without loading them into
BigQuery or a database first. File paths in queries are resolved relative to
the working directory the MCP server was started in (the project directory),
e.g. SELECT * FROM 'data/trades.csv'. Exposes a single tool:
execute_sql_local — rejects any DDL/DML at the code level before running.
"""
import asyncio
import json

import duckdb
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import TextContent, Tool

server = Server("local-files-readonly")
_connection = duckdb.connect()

_FORBIDDEN_VERBS = {
    "INSERT", "UPDATE", "DELETE", "MERGE",
    "CREATE", "DROP", "TRUNCATE", "ALTER", "REPLACE", "COPY", "ATTACH",
}


def _is_readonly(sql: str) -> bool:
    first_word = sql.strip().upper().split()[0] if sql.strip().split() else ""
    return first_word not in _FORBIDDEN_VERBS


@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="execute_sql_local",
            description=(
                "Execute a read-only SQL SELECT query against local data files "
                "(CSV, JSON, Parquet) using DuckDB. Reference a file directly in "
                "the FROM clause, e.g. SELECT * FROM 'data/trades.csv' or "
                "SELECT * FROM read_json_auto('events.json'). Use "
                "DESCRIBE SELECT * FROM 'path' to inspect columns/types. Paths "
                "are relative to the project's working directory. DDL and DML "
                "are rejected. Returns up to 3,000 rows."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "sql": {"type": "string", "description": "SQL SELECT query to run."},
                },
                "required": ["sql"],
            },
        )
    ]


@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    if name != "execute_sql_local":
        raise ValueError(f"Unknown tool: {name}")

    sql = arguments.get("sql", "").strip()

    if not _is_readonly(sql):
        return [TextContent(type="text", text="Error: only SELECT queries are permitted.")]

    try:
        cursor = _connection.execute(sql)
        columns = [d[0] for d in cursor.description] if cursor.description else []
        rows = cursor.fetchmany(3000)
        result = {
            "columns": columns,
            "rows": [dict(zip(columns, row)) for row in rows],
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
