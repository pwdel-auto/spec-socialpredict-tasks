---
name: socialpredict-wave-closeout
description: Close out a completed SocialPredict task wave across the sibling task, target, and log repositories. Use when Codex is asked to commit/push completed run changes, open wave PRs, choose previous-wave bases, create the next timestamped wave branch, summarize repo results, or automate the post-run handoff for spec-socialpredict-tasks, socialpredict, and log-socialpredict-tasks.
---

# SocialPredict Wave Closeout

## Overview

Close a completed SocialPredict wave run across:

- task repo: `/workspace/spec-socialpredict-tasks`
- target repo: `/workspace/socialpredict`
- log repo: `/workspace/log-socialpredict-tasks`

The workflow commits each repo's local wave artifacts, pushes only to the writable `origin` remote under `pwdel-auto`, opens PRs against the previous wave branch or `main`, then creates and pushes the next timestamped wave branch.

## Hard Safety Rules

- Write operations must target `origin` only.
- `origin` must resolve to `https://github.com/pwdel-auto/<repo>.git` or another explicit `pwdel-auto` URL for the same repo.
- Never push to, open PRs against, or otherwise write to `upstream` or `openpredictionmarkets/*`.
- If `gh` infers `openpredictionmarkets/*`, override it with `--repo pwdel-auto/<repo>`.
- Treat `upstream` and `openpredictionmarkets/*` as read-only context at most.
- Do not use destructive git commands. Do not rewrite branch history unless the user explicitly asks for it.
- Preserve user changes. Commit the actual current working tree state; do not revert unrelated files.
- Authenticate GitHub operations through `gh` before any push or PR command.
- Do not trust an ambient `GH_TOKEN` until `gh auth status` proves it is valid.

## Workflow

1. Preflight GitHub authentication.
   - Run `gh auth status` before any GitHub write or PR lookup.
   - If `gh auth status` reports an invalid `GH_TOKEN`, retry with `env -u GH_TOKEN gh auth status`.
   - If the retry succeeds, run subsequent `gh` commands and GitHub-facing `git push` commands with `env -u GH_TOKEN` so the valid stored `gh` credential is used instead of the invalid environment token.
   - Run `gh auth setup-git` after confirming a valid `gh` login when branch pushes are required; this keeps HTTPS Git pushes on the GitHub CLI credential path.
   - If neither normal nor `env -u GH_TOKEN` status succeeds, attempt `gh auth login` only when an interactive login is possible.
   - If login cannot complete or the token remains invalid, stop remote write/PR operations and report the exact authentication blocker. Continue only local inspection and non-remote validation.

2. Inspect all three repos.
   - Run `git status --short --branch`.
   - Run `git remote -v`.
   - Run `git branch --list`.
   - Confirm all repos are on the expected current wave branch or document any mismatch.

3. Select the PR base.
   - If the current branch is a wave branch, use the immediately previous wave branch when present in that repo.
   - Preserve the repo's existing branch-name style when identifying previous waves.
   - If no previous wave branch exists, use `main`.
   - State the selected base in each PR body.

4. Review changes before committing.
   - Use `git diff --stat` and targeted diffs.
   - For backend Go changes, use the applicable SocialPredict Go quality and testing skills before committing.
   - Record any verification blocker exactly.

5. Commit each repo.
   - Stage with `git add -A`.
   - Use a repo-specific detailed commit message.
   - Include what changed and what checks were run.
   - Let pre-commit hooks run; do not bypass secret scans.

6. Push current wave branches.
   - Push only after the `gh` authentication preflight passes.
   - Push with `git push origin <current-branch>`.
   - If the preflight selected `env -u GH_TOKEN`, push with `env -u GH_TOKEN git push origin <current-branch>`.
   - If GitHub rejects workflow-file updates, report the token permission blocker and retry after the user grants workflow write access.
   - Let pre-push hooks run; do not bypass secret scans.

7. Open PRs.
   - Use `gh pr create --repo pwdel-auto/<repo> --base <base> --head <current-branch>`.
   - If the preflight selected `env -u GH_TOKEN`, use `env -u GH_TOKEN gh pr create ...`.
   - Do not omit `--repo`; this prevents `gh` from targeting `openpredictionmarkets/*`.
   - Write a detailed title and body with summary, changes, validation, and notes.
   - If a PR already exists, capture its URL instead of creating a duplicate.

8. Create next wave branches.
   - Increment the wave number by one: `wave08` becomes `wave09`.
   - Use UTC timestamp format `YYYYMMDD-HHMMSS`.
   - Prefer `run-YYYYMMDD-HHMMSS-waveNN` for new branches unless the user requires another active convention.
   - Create each next branch on top of the just-committed current wave branch.
   - Push with `git push -u origin <next-branch>`.
   - If the preflight selected `env -u GH_TOKEN`, push with `env -u GH_TOKEN git push -u origin <next-branch>`.
   - If a repo push is blocked, leave the local branch in place and report the blocker.

9. Final status.
   - Recheck `git status --short --branch` in all repos.
   - Record the checked-out branch for each repo after any next-wave branch creation.
   - Return a table with repo, old branch, commit, push status, PR URL, new branch, and new branch push status.
   - Include checks run and any blocker.
   - End with a clear `READY_FOR_NEXT_RUN` signal only when all required repos are on their next wave branches; use a qualified signal such as `READY_FOR_NEXT_RUN_LOCAL` if anything remains local-only.
   - If the requested handoff uses `READY_FOR_NEXT_PLAN`, use that signal instead of `READY_FOR_NEXT_RUN`.
   - Immediately after the readiness signal, show the current checked-out branches for:
     - `/workspace/spec-socialpredict-tasks`
     - `/workspace/socialpredict`
     - `/workspace/log-socialpredict-tasks`

## Command Patterns

Use explicit repository selection for GitHub CLI operations:

```bash
gh pr create \
  --repo pwdel-auto/socialpredict \
  --base run_20260501-022327_wave07 \
  --head run-20260502-161144-wave08 \
  --title "Complete WAVE08 deployment hardening" \
  --body "..."
```

Check the inferred repo before using `gh` without `--repo`; prefer not to rely on inference:

```bash
gh repo view pwdel-auto/socialpredict --json nameWithOwner,viewerPermission,defaultBranchRef
```

Authenticate before remote work:

```bash
gh auth status
env -u GH_TOKEN gh auth status
gh auth setup-git
```

If `GH_TOKEN` is invalid but stored `gh` auth is valid, keep the bad token out of both GitHub CLI and HTTPS Git commands:

```bash
env -u GH_TOKEN git push origin run-20260502-233232-wave11
env -u GH_TOKEN gh pr list --repo pwdel-auto/socialpredict --head run-20260502-233232-wave11 --state all
```

## Failure Handling

- If a repo has no changes, do not create an empty commit; still create the next branch if the wave closeout requires it.
- If `GH_TOKEN` is invalid but `env -u GH_TOKEN gh auth status` succeeds, treat the environment token as the blocker and continue remote operations with `env -u GH_TOKEN`.
- If no valid `gh` authentication is available after attempting login, stop push/PR work and tell the user to refresh or replace the GitHub token; include the command that failed and the exact `gh auth status` summary.
- If push succeeds but PR creation fails, inspect `gh repo view pwdel-auto/<repo> --json viewerPermission` and retry with explicit `--repo`.
- If `gh pr create` returns `Resource not accessible by personal access token`, confirm the command uses `--repo pwdel-auto/<repo>` before reporting a real permission blocker.
- If a command fails because of sandboxing, rerun it with escalation rather than changing the workflow.
- If workflow-file pushes are rejected for missing `workflow` scope, stop only that repo's remote work, continue unblocked repos, and report the exact rejected file and token-scope issue.

## Final Response Shape

Keep the final concise and operational:

- a short note on assumptions
- a results table
- checks run
- blockers or follow-ups
- `READY_FOR_NEXT_RUN`, `READY_FOR_NEXT_PLAN`, or a qualified readiness signal
- current branches for the task, target, and log repos immediately after the readiness signal
