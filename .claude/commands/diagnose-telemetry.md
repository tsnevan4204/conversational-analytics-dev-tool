Run a data-quality audit against the primary event/time-series table in the
connected dataset, following the reasoning loop in CLAUDE.md.

$ARGUMENTS

If a specific table, partition key, or session/run ID is given above, scope
to that. Otherwise identify the primary time-series table from
`schema/_index.md` and audit it broadly across all partitions.

Steps:

1. Read `schema/_index.md` and the relevant `schema/<table>.md` before
   querying. Check the "Known issues" section so you don't re-discover
   something already documented — but do verify whether the issue is still
   present, rather than just assuming the doc is current.

2. Run a headline triage query grouped by the natural partition key (a
   session/run/batch ID if one exists, otherwise by date or another natural
   grouping). For each partition compute:
   - `COUNT(*)` — total rows
   - `COUNTIF(<col> IS NULL)` for any columns that should be non-null
   - `COUNT(DISTINCT <col>)` for key fields that should have meaningful
     variation (sequence numbers, status fields, primary metric values)
   - Time range: `MIN`/`MAX` of any timestamp column
   - Duration in seconds: `TIMESTAMP_DIFF(MAX(...), MIN(...), SECOND)`

3. Classify each partition:
   - **healthy** — plausible variation relative to time range and context
   - **frozen** — low-but-nonzero distinct values relative to duration
     (needs judgment: genuine quiet period vs. logging bug)
   - **broken** — `COUNT(DISTINCT x) = 0` meaning every value is NULL,
     or other categorical failures (all values identical non-null, etc.)

4. For any partition flagged frozen or broken:
   - Use a LAG window to find the exact row where a field goes NULL or
     stops varying (or confirm it was broken from row 1 — that's a
     different root cause than a mid-run failure).
   - Check whether any "status" or "health" column shows "ok" throughout
     while metrics are broken — a silent failure is more dangerous than a
     loud one.

5. Write a markdown report to `outputs/YYYY-MM-DD-data-quality-audit.md`
   summarizing: which partitions were checked, the classification of each,
   the evidence for each classification, and what to check next for
   anything still unresolved.

6. If this audit confirms or contradicts something in the schema
   "Known issues" section, say so explicitly so the user can update that
   file.
