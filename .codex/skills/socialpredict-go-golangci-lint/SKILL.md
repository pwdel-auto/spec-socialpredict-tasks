---
name: socialpredict-go-golangci-lint
description: Run `golangci-lint` for SocialPredict backend Go code and summarize lint findings. Use when a user asks to run golangci-lint, wants a stricter lint pass than `go vet`, or needs a consolidated lint report before review or verifier handoff.
---

# SocialPredict Go golangci-lint

## Workflow

1. Confirm the target repo and scope. Default to `../socialpredict/backend`.
2. Read `references/golangci-lint-guidance.md` for install, package, and reporting rules.
3. Run `scripts/run_golangci_lint.sh [repo-dir] [packages...]`.
4. Report the exact command and prioritize blocking or policy-relevant lint findings.
5. If `golangci-lint` is missing, stop and report the install command.

## Defaults

- Default repo dir: `../socialpredict`
- Default package pattern: `./...`

## Resources

- `references/golangci-lint-guidance.md`: install, package scope, and reporting guidance.
- `scripts/run_golangci_lint.sh`: wrapper for `golangci-lint run`.
