# Codex Report Convention

This workspace keeps orchestration state in the control repo and writes curated
task journals into the target repo.

## Ownership Split

- Control repo (`spec-socialpredict-tasks`):
  - `TASKS.json`
  - `.codex-runs/` raw event streams, stderr, prompt captures, runner state
- Target repo (`../socialpredict`):
  - `.codex-reports/tasks/<task-id>/` curated task journal and summary

## Canonical Target-Repo Layout

```text
../socialpredict/.codex-reports/tasks/<task-id>/
├── meta.json
├── summary.json
├── conversation.ndjson
└── decisions.ndjson
```

## File Roles

- `meta.json`: stable metadata for the task, repos, dispatcher, and file paths
- `summary.json`: dispatcher-owned rolled-up current state
- `conversation.ndjson`: append-only event journal across dispatcher and specialists
- `decisions.ndjson`: append-only architectural/process decisions

## Why NDJSON

- append-friendly for long-running tasks
- easy to slice with `tail`, `rg`, `jq`, or helper scripts
- agents do not need to re-read the full conversation to process new entries

## Helper Script

Use [`scripts/codex-report.py`](/workspace/spec-socialpredict-tasks/scripts/codex-report.py) to
interact with the report files deterministically.

Examples:

```bash
python3 scripts/codex-report.py read-summary \
  --report-dir ../socialpredict/.codex-reports/tasks/PR581-008

python3 scripts/codex-report.py read-events \
  --report-dir ../socialpredict/.codex-reports/tasks/PR581-008 \
  --after-seq 12

python3 scripts/codex-report.py append-event \
  --report-dir ../socialpredict/.codex-reports/tasks/PR581-008 \
  --agent-name dispatcher_agent \
  --agent-role dispatcher \
  --event-type plan_updated \
  --summary "Narrowed scope to the two remaining markets handlers."
```

## Summary Ownership

- Specialists should append facts and decisions.
- The dispatcher owns `summary.json`.
- `summary.json.last_event_seq` tracks the last rolled-up conversation event so
  dispatcher-led summarization can operate incrementally.
