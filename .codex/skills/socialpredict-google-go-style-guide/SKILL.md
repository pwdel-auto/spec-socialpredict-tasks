---
name: socialpredict-google-go-style-guide
description: Search a local working copy of the Google Go Style Guide and return only the matching sections with nearby context. Use when interpreting Google Go Style Guide rules, answering Go style questions, checking naming/commentary/simplicity/consistency guidance, or reviewing SocialPredict Go changes without loading the full guide into context.
---

# SocialPredict Google Go Style Guide

## Workflow

1. Use `scripts/search_style_guide.sh <regex>` for targeted lookups instead of loading the full reference file.
2. Start with obvious guide terms such as `clarity`, `simplicity`, `concision`, `maintainability`, `consistency`, `formatting`, `MixedCaps`, `line length`, `naming`, or `local consistency`.
3. Increase context with `--context N` if the first match is too narrow.
4. Read `references/google-go-style-guide.md` directly only when the search output is insufficient.
5. Treat this skill as the primary local source for Google Go Style Guide lookups. Use the official source URL in the reference header if a fresh manual comparison is needed.

## Default Command

```bash
scripts/search_style_guide.sh naming
```

Useful variants:

```bash
scripts/search_style_guide.sh --context 6 "line length|indentation"
scripts/search_style_guide.sh --list-topics
```

## Output Rules

- State the exact search command.
- Quote only the returned nearby lines that matter for the current style question.
- Summarize the style implication in repo terms after citing the relevant local excerpt.
- If the search is ambiguous, refine the regex instead of loading the whole guide.
- If the answer depends on Google Go Style Decisions or Go Best Practices rather than the main guide, say that explicitly instead of pretending this reference file covers more than it does.

## Resources

- `scripts/search_style_guide.sh`: regex search wrapper with context output and topic hints.
- `references/google-go-style-guide.md`: local working copy of the official Google Go Style Guide for targeted lookup.

## Limit

This skill intentionally covers only the main Google Go Style Guide page. It does not replace future dedicated skills for Go Style Decisions or Go Best Practices.
