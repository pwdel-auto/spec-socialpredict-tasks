---
name: socialpredict-go-gofmt
description: Run `gofmt` in check or write mode for SocialPredict Go code. Use when a user asks to check formatting drift, format backend Go files, or confirm `gofmt -l` passes before review or verifier handoff.
---

# SocialPredict Go fmt

## Workflow

1. Confirm the target repo and scope. Default to `../socialpredict/backend`.
2. Read `references/gofmt-guidance.md` for mode and output rules.
3. Run `scripts/run_gofmt.sh [repo-dir] [mode] [targets...]`.
4. Report the exact command and affected files.
5. In `check` mode, treat returned files as formatting drift that must be resolved before handoff.
6. In `write` mode, list the files that were reformatted.

## Defaults

- Default repo dir: `../socialpredict`
- Default mode: `check`
- Default target list: `.`

## Resources

- `references/gofmt-guidance.md`: check versus write mode and reporting guidance.
- `scripts/run_gofmt.sh`: wrapper for `gofmt -l` and `gofmt -w`.
