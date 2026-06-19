Build or refresh the local schema cache for a BigQuery project/dataset.

$ARGUMENTS

If no project/dataset is specified above, read `.env` to get
`GCP_PROJECT_ID` and `GCP_DATASET` and use `GCP_PROJECT_ID.GCP_DATASET`
as the target. If `.env` is missing or those variables are unset, ask the
user before proceeding.

Steps:

1. List all tables in the target dataset:
   ```sql
   SELECT table_name, table_type, row_count, creation_time
   FROM `<project>.<dataset>.INFORMATION_SCHEMA.TABLES`
   ORDER BY table_name
   ```

2. For each table, fetch column metadata:
   ```sql
   SELECT column_name, data_type, is_nullable, description
   FROM `<project>.<dataset>.INFORMATION_SCHEMA.COLUMNS`
   WHERE table_name = '<table>'
   ORDER BY ordinal_position
   ```

3. For each table, run a lightweight profiling query:
   - Total row count
   - MIN/MAX of any TIMESTAMP or DATE columns (time range covered)
   - COUNT(DISTINCT ...) on columns that look like natural keys, status
     fields, or enum-like strings (use judgment — don't profile every
     column on wide tables)
   - Sample values for low-cardinality string columns

4. Write one file per table to `schema/<table_name>.md`:

   ```
   # `project.dataset.table_name`

   ## Columns
   | Column | Type | Notes |
   |---|---|---|
   | column_name | TYPE | distinct count / sample values / nullability |

   ## Profile
   - Row count: ...
   - Time range covered: ... to ... (if timestamp column exists)

   ## Known issues
   (leave empty; filled in by /diagnose-telemetry runs)
   ```

5. Write or update `schema/_index.md`:

   ```
   # Dataset index: project.dataset
   - `table_name` — one-line description (event log, dimension table, etc.)
   ```

6. Report back: how many tables found, which look like primary event/time-
   series tables vs. dimension/lookup tables, and anything surprising
   (unexpected nulls, very low row counts, no timestamp columns).

On re-runs against the same dataset: read `schema/_index.md` first and
report what's new or changed rather than starting from scratch. If a
column you expected isn't present, re-verify rather than trusting stale
cache.
