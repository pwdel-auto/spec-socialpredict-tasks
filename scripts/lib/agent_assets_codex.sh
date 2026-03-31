#!/usr/bin/env bash

aa_codex_collect_entries() {
  local repo_root="$1"
  local output_tsv="$2"
  local source_root="${repo_root}/.codex"

  if [[ ! -d "$source_root" ]]; then
    printf 'Codex source directory is missing: %s\n' "$source_root" >&2
    return 3
  fi

  local rel_path source_rel target_rel digest
  while IFS= read -r rel_path; do
    source_rel=".codex/${rel_path}"
    target_rel=".codex/${rel_path}"
    digest="$(aa_sha256_file "${repo_root}/${source_rel}")"
    printf 'codex\t%s\t%s\t%s\n' "$source_rel" "$target_rel" "$digest" >>"$output_tsv"
  done < <(
    cd "$source_root"
    find skills agents -type f 2>/dev/null | sed 's#^\./##' | LC_ALL=C sort
  )

  if [[ -f "${repo_root}/AGENTS.md" ]]; then
    digest="$(aa_sha256_file "${repo_root}/AGENTS.md")"
    printf 'codex\tAGENTS.md\t.codex/AGENTS.md\t%s\n' "$digest" >>"$output_tsv"
  fi
}

aa_codex_write_target() {
  local repo_root="$1"
  local source_rel="$2"
  local target_abs="$3"

  case "$source_rel" in
  .codex/skills/* | .codex/agents/* | AGENTS.md)
    ;;
  *)
    printf 'Refusing to copy unexpected codex source: %s\n' "$source_rel" >&2
    return 2
    ;;
  esac

  mkdir -p "$(dirname "$target_abs")"
  cp -f "${repo_root}/${source_rel}" "$target_abs"
}
