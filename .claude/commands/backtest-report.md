Summarize performance metrics from the connected dataset into a markdown
report. If no specific scope is given, ask which table, session/run ID,
or time range to cover — don't guess silently.

$ARGUMENTS

Steps:

1. Read the relevant `schema/<table>.md` to understand available columns
   before querying. Don't make up or reference metrics the schema doesn't
   support.

2. Identify the natural performance dimensions in this dataset:
   - Session/run/batch identifiers (to scope the report)
   - A primary outcome metric (balance, revenue, error rate, conversion —
     whatever "performance" means in this domain)
   - Time-series progression of that metric
   - Activity counts (events per period, actions taken, etc.)
   - Latency or timing columns if present

3. Pull the data and build the report:
   - **Session metadata**: identifiers, start/end time, duration, total rows
   - **Key outcome**: primary metric at start vs. end, and the trajectory
     if it's non-trivial
   - **Activity summary**: what happened (event counts, action frequency)
   - **Latency / performance** (if timing columns exist): p50/p95/p99
   - **Data-quality caveats**: if anything looks like a logging bug while
     pulling this data, flag it explicitly — a performance report built on
     broken data is misleading, so caveat any numbers you're uncertain about

4. Use Python (matplotlib) for any time-series or distribution charts.
   Save charts as PNGs in `outputs/` alongside the markdown report.

5. Write the final report to
   `outputs/YYYY-MM-DD-performance-report-<scope>.md`.
