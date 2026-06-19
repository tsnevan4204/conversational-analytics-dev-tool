Investigate the following question using the reasoning loop in CLAUDE.md
(triage broadly -> form a hypothesis -> targeted follow-up query -> repeat
until you have a confident answer or have clearly identified what's
unresolved):

$ARGUMENTS

Guidelines:

- Start broad. Don't write a narrow query based on a guess about what the
  user wants -- run something that surfaces the shape of the data first
  (counts, distinct values, time ranges, nulls), then narrow based on what
  you actually see.
- Use BigQuery (`execute_sql_readonly`) for aggregation, filtering, and
  anything SQL expresses naturally. Drop into Python (pandas/numpy/
  scipy/sklearn/matplotlib, run via bash in the venv) for anything SQL
  can't do cleanly: statistical tests, model fitting, multi-step
  transforms, or chart generation.
- If you produce a chart, save it as a PNG under `outputs/` and describe
  what it shows in text.
- If the investigation reaches a real conclusion (not just "I looked and
  found nothing notable"), offer to write a short markdown report to
  `outputs/` summarizing the question, key queries, and finding. Don't
  write a report file for trivial one-query answers.
- If at any point a query fails, times out, or returns something that
  doesn't match your expectation, say so explicitly before continuing --
  do not paper over it.
