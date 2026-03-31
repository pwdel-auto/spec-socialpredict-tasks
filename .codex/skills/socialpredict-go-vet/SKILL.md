---
name: socialpredict-go-vet
description: Run `go vet` for SocialPredict backend Go code and summarize correctness-oriented findings. Use when a user asks to run `go vet`, enforce a backend quality gate, or investigate vet findings before review or verifier handoff.
---

# SocialPredict Go vet

## Workflow

1. Confirm the target repo and scope. Default to `../socialpredict/backend`.
2. Read `references/go-vet-guidance.md` for package selection and reporting rules.
3. Run `scripts/run_go_vet.sh [repo-dir] [packages...]`.
4. Report the exact command and any findings.
5. Treat vet failures as blocking unless the user explicitly wants exploratory output only.

## Defaults

- Default repo dir: `../socialpredict`
- Default package pattern: `./...`

## Resources

- `references/go-vet-guidance.md`: package scope and reporting expectations.
- `scripts/run_go_vet.sh`: wrapper for `go vet`.
