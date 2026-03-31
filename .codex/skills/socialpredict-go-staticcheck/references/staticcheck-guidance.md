# staticcheck Guidance

## Command Pattern

Use the wrapper first:

```bash
./.codex/skills/socialpredict-go-staticcheck/scripts/run_staticcheck.sh [repo-dir] [packages...]
```

Defaults from the control repo:

```bash
./.codex/skills/socialpredict-go-staticcheck/scripts/run_staticcheck.sh
```

That resolves to:

```bash
cd ../socialpredict/backend
staticcheck ./...
```

## Installation

If `staticcheck` is not installed:

```bash
go install honnef.co/go/tools/cmd/staticcheck@latest
```

## Reporting

1. Quote the exact command that ran.
2. State whether the run covered all backend packages or a narrower package list.
3. Prioritize production-code findings before tests when the output is noisy.
