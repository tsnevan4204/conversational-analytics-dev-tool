Build or refresh the local schema cache for data files in this directory and
its subdirectories (CSV, TSV, JSON, JSONL, Parquet).

$ARGUMENTS

If a path is given above, scan that directory; otherwise scan the current
working directory and all subdirectories. Skip `.git/`, `venv/`,
`node_modules/`, `outputs/`, `schema/`, and other hidden directories.

Steps:

1. Find candidate data files: `*.csv`, `*.tsv`, `*.json`, `*.jsonl`,
   `*.parquet`. Skip `.txt` files unless they're clearly delimited data
   (e.g. tab/comma-separated rows), not prose.

2. For each file, use the `execute_sql_local` tool (DuckDB) to profile it:
   ```sql
   DESCRIBE SELECT * FROM 'path/to/file.csv';
   SELECT COUNT(*) FROM 'path/to/file.csv';
   ```
   DuckDB infers columns/types automatically from the file — no manual
   schema needed. Reference `.json`/`.jsonl` files the same way; use
   `read_json_auto('path')` if a plain path doesn't parse cleanly.

3. For each file, gather the same kind of profile as `/discover-schema`:
   - Row count
   - Column names + inferred types
   - MIN/MAX of any date/timestamp-looking columns
   - COUNT(DISTINCT ...) on natural keys, status fields, or enum-like
     columns (use judgment — don't profile every column on wide files)
   - Sample values for low-cardinality string columns

4. Write one file per data file to `schema/<relative-path-with-slashes-as-underscores>.md`,
   same format `/discover-schema` uses:

   ```
   # `relative/path/to/file.csv`

   ## Columns
   | Column | Type | Notes |
   |---|---|---|
   | column_name | TYPE | distinct count / sample values / nullability |

   ## Profile
   - Row count: ...
   - Time range covered: ... to ... (if a date/timestamp column exists)

   ## Known issues
   (leave empty; filled in by /diagnose-telemetry runs)
   ```

5. Write or update `schema/_index.md`:

   ```
   # Local files index: <directory>
   - `relative/path/to/file.csv` — one-line description
   ```

6. Report back: how many files found, what formats, which look like the
   primary data files vs. small lookup/reference files, and anything
   surprising (unexpected nulls, tiny row counts, inconsistent columns
   across files that look like they should share a schema).

On re-runs: read `schema/_index.md` first and report what's new, changed,
or removed rather than re-profiling everything from scratch.
