---
name: socialpredict-go-staticcheck
description: Run `staticcheck` for SocialPredict backend Go code and summarize analyzer findings. Use when a user asks for deeper static analysis beyond `go vet`, wants a staticcheck pass on backend packages, or needs a focused report on staticcheck issues before handoff.
---

# SocialPredict Go staticcheck

## Workflow

1. Confirm the target repo and scope. Default to `../socialpredict/backend`.
2. Read `references/staticcheck-guidance.md` for install, package, and reporting rules.
3. Run `scripts/run_staticcheck.sh [repo-dir] [packages...]`.
4. Report the exact command and prioritize production-code findings over test-only noise.
5. If `staticcheck` is missing, stop and report the install command.

## Defaults

- Default repo dir: `../socialpredict`
- Default package pattern: `./...`

## Resources

- `references/staticcheck-guidance.md`: install, package scope, and reporting guidance.
- `scripts/run_staticcheck.sh`: wrapper for `staticcheck`.
