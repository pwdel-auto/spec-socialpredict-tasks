# gofmt Guidance

## Command Pattern

Use the wrapper first:

```bash
./.codex/skills/socialpredict-go-gofmt/scripts/run_gofmt.sh [repo-dir] [mode] [targets...]
```

Defaults from the control repo:

```bash
./.codex/skills/socialpredict-go-gofmt/scripts/run_gofmt.sh
```

That resolves to a formatting check over `../socialpredict/backend`.

## Modes

- `check`: run `gofmt -l` and treat any returned files as formatting drift
- `write`: run `gofmt -w` on the target list and report the files that changed

## Reporting

1. Quote the exact command that ran.
2. Distinguish between check mode and write mode.
3. In check mode, list only files that need formatting.
4. In write mode, list files that were rewritten.
