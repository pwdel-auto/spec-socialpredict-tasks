# go vet Guidance

## Command Pattern

Use the wrapper first:

```bash
./.codex/skills/socialpredict-go-vet/scripts/run_go_vet.sh [repo-dir] [packages...]
```

Defaults from the control repo:

```bash
./.codex/skills/socialpredict-go-vet/scripts/run_go_vet.sh
```

That resolves to:

```bash
cd ../socialpredict/backend
go vet ./...
```

## Reporting

1. Quote the exact command that ran.
2. State whether the run covered all backend packages or a narrower package list.
3. Treat findings as correctness-oriented and usually blocking.
