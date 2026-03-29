# github-bootstrap

`github-bootstrap` is a small local repo that automates the GitHub workflow you just used:

- publish a local repo to GitHub
- keep `main` as the protected branch
- push work on `init`
- open the initial `init -> main` PR
- apply the same `main` protections
- add the repo to your GitHub list

## What it solves

GitHub template repositories are good for carrying files and starter structure, but they do not replace repo-by-repo settings like:

- branch protection
- initial branch push/PR flow
- GitHub list assignment

This repo gives you a repeatable script for those settings.

## Files

- `defaults.env` holds your personal defaults
- `bin/publish-repo` bootstraps the current local git repo
- `templates/claude/README.md` is the tracked `.claude` placeholder used when you opt in with `--track-claude`

## Current defaults

The shipped defaults match your current setup:

- owner: `pwdel`
- visibility: `public`
- default branch: `main`
- working branch: `init`
- list: `Automated Coding`
- branch protection:
  - PR-based changes
  - no force-push
  - no delete
  - conversation resolution required

## Usage

Run the script from any local git repo you want to publish:

```bash
cd ~/Projects/some-repo
~/Projects/github-bootstrap/bin/publish-repo \
  --description "Short repository description"
```

Useful flags:

```bash
~/Projects/github-bootstrap/bin/publish-repo --help
~/Projects/github-bootstrap/bin/publish-repo --private
~/Projects/github-bootstrap/bin/publish-repo --skip-list
~/Projects/github-bootstrap/bin/publish-repo --skip-protection
~/Projects/github-bootstrap/bin/publish-repo --track-claude
~/Projects/github-bootstrap/bin/publish-repo --list-name automated-coding
```

## Notes

- The script stages the current working tree on the `init` branch and commits it if needed
- If the repo has no commit yet, it creates an empty `main` commit first so the `init -> main` PR has a real base branch
- It uses your authenticated `gh` session and expects `git`, `gh`, and `jq` to be installed

## Recommended next step

If you want this repo to act as an actual GitHub template too, publish `github-bootstrap` and mark it as a template repository on GitHub. That gives you:

- reusable starter files from the repo itself
- plus the `publish-repo` script for per-repo settings GitHub templates do not handle
