# golangci-lint Guidance

## Command Pattern

Use the wrapper first:

```bash
./.codex/skills/socialpredict-go-golangci-lint/scripts/run_golangci_lint.sh [repo-dir] [packages...]
```

Defaults from the control repo:

```bash
./.codex/skills/socialpredict-go-golangci-lint/scripts/run_golangci_lint.sh
```

That resolves to:

```bash
cd ../socialpredict/backend
golangci-lint run ./...
```

## Installation

If `golangci-lint` is not installed:

```bash
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

## Reporting

1. Quote the exact command that ran.
2. State whether the run covered all backend packages or a narrower package list.
3. Prioritize blocking, policy, or maintainability findings over stylistic noise.
