# Conversational Analytics Dev Tool

Ask questions about your BigQuery data in plain English. Claude runs the
queries, forms hypotheses, writes follow-up queries, drops into Python for
charts and stats — and shows you the full reasoning trail, not just a final
number.

Runs on your Claude subscription (no per-token API cost). All BigQuery access
is read-only. Nothing is written back to your warehouse.

---

## Installation

### Option A — Plugin install (recommended)

If you already have Claude Code, this is the fastest path:

```
/plugin marketplace add tsnevan4204/conversational-analytics-dev-tool
/plugin install conversational-analytics@tsnevan4204-conversational-analytics
```

The plugin adds the analytics skill, slash commands, and BigQuery MCP to any Claude Code session. You still need to complete the **GCP setup** steps (4 and 5) below, and install [uv](https://docs.astral.sh/uv/getting-started/installation/) so the MCP server can install its Python dependencies automatically:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Then run `gcloud auth application-default login` and you're done.

---

### Option B — Clone and run

Good for contributing or running the tool as a standalone project.

## One-time setup

### 1. Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — the CLI, with an active subscription
- Python 3.10+
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) (`gcloud`)

### 2. Clone and install

```bash
git clone https://github.com/tsnevan4204/conversational-analytics-dev-tool.git
cd conversational-analytics-dev-tool
./setup.sh
```

`setup.sh` creates a Python virtualenv and installs all dependencies
(pandas, numpy, scipy, scikit-learn, matplotlib, google-cloud-bigquery, etc.).

### 3. Point it at your GCP project

Edit the `.env` file that `setup.sh` created:

```
GCP_PROJECT_ID=your-project-id
GCP_DATASET=your-dataset-name
```

### 4. Grant BigQuery access

Your Google account needs three IAM roles on the project:

```bash
PROJECT_ID="your-project-id"
USER_EMAIL="you@example.com"

for ROLE in roles/mcp.toolUser roles/bigquery.jobUser roles/bigquery.dataViewer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="user:$USER_EMAIL" --role="$ROLE"
done
```

Or do it in the [GCP IAM console](https://console.cloud.google.com/iam-admin/iam).

### 5. Authenticate

```bash
gcloud auth application-default login
```

This opens a browser to sign in. You only need to do this once (credentials
are cached by gcloud and stay valid for an extended period).

### 6. Discover your schema

Start Claude Code and run the schema discovery command:

```bash
claude
```

```
/discover-schema
```

This profiles every table in your dataset and writes local schema docs that
Claude reads before writing any query. Takes 1–2 minutes the first time.

---

## Every time you use it

```bash
cd conversational-analytics-dev-tool
claude
```

That's it. The BigQuery connection, your credentials, and the schema cache are
all already set up. Just start asking questions.

---

## What you can do

**Ask naturally:**
```
what does the data look like overall?
are there any gaps or null values I should know about?
show me how metric X changed over the last 30 days
why does run abc123 look different from the others?
```

**Or use slash commands for structured workflows:**

| Command | What it does |
|---|---|
| `/discover-schema` | Profile all tables and build the local schema cache |
| `/diagnose-telemetry` | Data-quality audit: nulls, cardinality, frozen values |
| `/explore <question>` | Open-ended hypothesis-driven investigation |
| `/backtest-report` | Performance summary → markdown report + charts in `outputs/` |

> **Plugin users:** commands are namespaced — use `/conversational-analytics:discover-schema`, `/conversational-analytics:diagnose-telemetry`, etc.

**SQL + Python in the same turn:**

Claude will run a BigQuery query to aggregate data, then drop into Python to
plot it, fit a model, or run a statistical test — whatever the question
requires. Output charts and reports land in the `outputs/` folder.

---

## What's in the Python environment

| Category | Packages |
|---|---|
| Data manipulation | pandas, numpy, pyarrow |
| Statistics / ML | scipy, scikit-learn |
| Charts | matplotlib, pillow |
| BigQuery client | google-cloud-bigquery, db-dtypes |

If a session needs a package that isn't listed, Claude will `pip install` it
into the venv on the fly. To make it permanent, add it to `requirements.txt`.

---

## Notes

- **Outputs** (reports, CSVs, charts) go in `outputs/` — gitignored, local
  scratch space per machine.
- **Schema cache** lives in `schema/` — also gitignored. Re-run
  `/discover-schema` after your dataset changes.
- **Nothing is ever written to BigQuery.** Write/DDL operations are blocked
  at the MCP server level, not just by instruction.
- Supports BigQuery only today. MySQL/SQLite/Postgres is a natural extension.
