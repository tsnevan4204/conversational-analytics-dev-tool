# Conversational Analytics Dev Tool

Ask questions about your data in plain English. Claude runs queries, forms
hypotheses, writes follow-ups, and drops into Python for charts and stats —
on BigQuery or on local CSV/JSON/Parquet files. Runs on your Claude
subscription (no per-token API cost). Everything is read-only.

## Install

```
/plugin marketplace add tsnevan4204/conversational-analytics-dev-tool
/plugin install conversational-analytics@tsnevan4204-conversational-analytics
```

Install [uv](https://docs.astral.sh/uv/getting-started/installation/) so the
bundled MCP servers can fetch their own dependencies:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

That's enough to analyze **local files** — skip to [Usage](#usage).

### BigQuery setup (skip this if you only need local files)

1. Install the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`).
2. Authenticate — **this step is required**, every BigQuery query fails
   without it:
   ```bash
   gcloud auth application-default login
   ```
   One-time browser sign-in; `gcloud` caches the result.
3. Grant your account access to the project:
   ```bash
   PROJECT_ID="your-project-id"; USER_EMAIL="you@example.com"
   for ROLE in roles/bigquery.jobUser roles/bigquery.dataViewer roles/mcp.toolUser; do
     gcloud projects add-iam-policy-binding "$PROJECT_ID" \
       --member="user:$USER_EMAIL" --role="$ROLE"
   done
   ```
4. Create a `.env` in your project directory:
   ```
   GCP_PROJECT_ID=your-project-id
   GCP_DATASET=your-dataset-name
   ```

<details>
<summary>Clone-and-run instead of plugin install</summary>

```bash
git clone https://github.com/tsnevan4204/conversational-analytics-dev-tool.git
cd conversational-analytics-dev-tool
./setup.sh
```

`setup.sh` creates a venv with pandas/numpy/scipy/sklearn/matplotlib/duckdb
and checks whether BigQuery auth is already done, telling you if it isn't.
The same `gcloud auth application-default login` step above still applies
if you're using BigQuery.
</details>

## Usage

```bash
cd your-data-folder   # CSV/JSON/Parquet files, or a .env pointed at BigQuery
claude
```

First time pointed at a new dataset or folder, build the schema cache:

```
/discover-schema project.dataset      # BigQuery
/discover-files                       # local CSV/JSON/Parquet
```

Then just ask:

```
what does the data look like overall?
are there any gaps or null values I should know about?
why does run abc123 look different from the others?
```

## Features

| Command | What it does |
|---|---|
| `/discover-schema <project.dataset>` | Profile BigQuery tables → schema cache |
| `/discover-files [path]` | Profile local CSV/JSON/Parquet files → schema cache |
| `/diagnose-telemetry` | Data-quality audit: nulls, cardinality, frozen values |
| `/explore <question>` | Open-ended hypothesis-driven investigation |
| `/backtest-report` | Performance summary → markdown report + charts in `outputs/` |

> Plugin installs namespace commands, e.g. `/conversational-analytics:discover-schema`.

Claude mixes SQL and Python in the same turn — query and aggregate with
SQL, then drop into pandas/scipy/sklearn/matplotlib for statistical tests,
models, or charts. Charts and reports land in `outputs/`.

**Safety:** write/DDL SQL (`INSERT`, `CREATE`, `DROP`, ...) is rejected at
the MCP server level for both BigQuery and local files — not just by
instruction. Nothing is ever written back to your warehouse or your files.

## Adding a new data source

BigQuery and local files both follow the same pattern — adding Postgres,
SQLite, MongoDB, etc. means repeating it:

1. A small MCP server exposing one read-only query tool (see
   `mcp_bigquery_server.py` or `mcp_local_server.py`, ~80 lines each),
   registered in `.mcp.json`.
2. A `/discover-<source>` command that profiles it into
   `schema/<name>.md` + `schema/_index.md`, in the same format the
   existing commands use.
3. A line in `CLAUDE.md` / `SKILL.md` telling Claude how to recognize when
   that source applies.

The reasoning loop, schema cache, and `outputs/` convention all work
unchanged for any source plugged in this way.

## Notes

- `outputs/` and `schema/` are gitignored — per-machine scratch space, not
  shared history. Re-run `/discover-schema` or `/discover-files` after your
  data changes.
- If a Python package a session needs isn't installed, Claude will `pip
  install` it into the venv on the fly; add it to `requirements.txt` to
  make that permanent.
