#!/usr/bin/env bash
# Ship dev to main as ONE commit holding only the shipping files.
#
#   scripts/release.sh <slug> "<message>"            # branch, commit, push, PR → main
#   scripts/release.sh --dry-run <slug> "<message>"  # stop before push, show the diff
#   scripts/release.sh --draft-release <notes.md>     # AFTER that PR merged: draft GitHub release
#
# Why not merge dev → main: main keeps only what the plugin directory scans
# (see CONTRIBUTING "Branches"). A merge would bring evals/, scripts/,
# CONTRIBUTING.md and CI onto main, and the GitHub compare main...dev
# conflicts on purpose whenever a dev-only file changes.
#
# RELEASE_SOURCE (default origin/dev) is what gets shipped; CI sets it to the
# PR's commit to dry-run a pull request before it reaches dev.
#
# Works in a throwaway worktree, so your checkout and branch are untouched.
# Needs: git, gh (signed in), claude (for the directory validator).
set -euo pipefail

SHIPPING=(
  .claude-plugin
  plugins/omisell/.claude-plugin
  plugins/omisell/.mcp.json
  plugins/omisell/skills
  README.md
  LICENSE
  .gitignore
)

# Public repo: never ship internal hosts, ids, staff emails or tokens.
LEAK_PATTERN='10\.148\.|34\.87\.|34\.124\.|BEGIN [A-Z ]*PRIVATE|Bearer [A-Za-z0-9._-]{20,}|@boxme\.(tech|asia|vn)|business[_ ]?id[^a-z]{0,4}[0-9]{3,}|OMISELL-BACKEND|space\.boxme|\b(DS|TK|DP)-[0-9]{3,}'

die() { echo "release: $*" >&2; exit 1; }
version() { python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])'; }

# Merging to main publishes a directory version, not a GitHub Release. This
# drafts one for the version on main: tag v<version> on main's head, the zips
# users upload to claude.ai, notes = <notes.md> under "What's new" plus the
# Install/Skills part of the latest release. A draft is not public and creates
# no tag until someone publishes it on GitHub.
draft_release() {
  local notes=$1 root sha tag tmp body prev pending
  [[ -s "$notes" ]] || die "notes file missing or empty: $notes"
  root=$(git rev-parse --show-toplevel)
  cd "$root"
  git fetch --quiet origin main dev
  pending=$(git diff --name-only origin/main origin/dev -- "${SHIPPING[@]}")
  [[ -z "$pending" ]] || die "main differs from dev; merge the release PR first:"$'\n'"$pending"
  sha=$(git rev-parse origin/main)
  tag="v$(git show origin/main:plugins/omisell/.claude-plugin/plugin.json | version)"
  git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null && die "tag $tag already exists"
  gh release view "$tag" >/dev/null 2>&1 && die "a release for $tag already exists (maybe a draft)"
  prev=$(gh release view --json body -q .body | sed -n '/^## Install/,$p')
  [[ -n "$prev" ]] || die "the latest release has no '## Install' section to reuse"

  tmp=$(mktemp -d "${TMPDIR:-/tmp}/omisell-draft.XXXXXX")
  trap "rm -rf '$tmp'" EXIT
  body="$tmp/notes.md"
  {
    echo 'Omisell skills for Claude on the Omisell connector (`https://mcp.omisell.com/mcp`). Start with `/omisell:start`, or just ask `/omisell:ask`.'
    echo
    echo "## What's new in $tag"
    cat "$notes"
    echo
    printf '%s\n' "$prev"
  } > "$body"
  local leaks
  leaks=$(grep -n -E "$LEAK_PATTERN" "$body" || true)
  [[ -z "$leaks" ]] || die "possible internal data in the notes (public repo):"$'\n'"$leaks"

  # Zips are built from main's tree, never from a working copy.
  git archive "$sha" plugins/omisell | tar -x -C "$tmp"
  python3 - "$tmp/plugins/omisell" "$tmp/assets" <<'PY'
import sys, zipfile
from pathlib import Path

src, out = Path(sys.argv[1]), Path(sys.argv[2])
out.mkdir()

def files(folder):
    return sorted(p for p in folder.rglob("*") if p.is_file())

# Whole plugin, for "Upload plugin" on claude.ai.
with zipfile.ZipFile(out / "omisell-plugin.zip", "w", zipfile.ZIP_DEFLATED) as zf:
    for part in (src / ".claude-plugin", src / "skills"):
        for f in files(part):
            zf.write(f, f.relative_to(src))
    zf.write(src / ".mcp.json", ".mcp.json")
# One per skill; the top entry is the skill folder (claude.ai skill upload).
for folder in sorted(p for p in (src / "skills").iterdir() if p.is_dir()):
    with zipfile.ZipFile(out / f"omisell-{folder.name}.zip", "w", zipfile.ZIP_DEFLATED) as zf:
        for f in files(folder):
            zf.write(f, Path(folder.name) / f.relative_to(folder))
PY
  gh release create "$tag" --draft --target "$sha" --title "Omisell for Claude $tag" \
    --notes-file "$body" "$tmp"/assets/*.zip
  echo "release: draft $tag on ${sha:0:7} with $(ls "$tmp"/assets | wc -l) zips; review it, then Publish on GitHub."
}

if [[ "${1:-}" == "--draft-release" ]]; then
  [[ $# -eq 2 ]] || die "usage: scripts/release.sh --draft-release <notes.md>"
  draft_release "$2"
  exit 0
fi

dry_run=0
if [[ "${1:-}" == "--dry-run" ]]; then dry_run=1; shift; fi
[[ $# -eq 2 ]] || die "usage: scripts/release.sh [--dry-run] <slug> \"<message>\""
slug=$1
message=$2
[[ "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "slug must be kebab-case: $slug"
branch="release/$slug"
source=${RELEASE_SOURCE:-origin/dev}

root=$(git rev-parse --show-toplevel)
cd "$root"
git fetch --quiet origin main dev
git rev-parse --verify --quiet "$source^{commit}" >/dev/null || die "unknown source: $source"
git rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null \
  && die "origin/$branch already exists"

work=$(mktemp -d "${TMPDIR:-/tmp}/omisell-release.XXXXXX")
pushed=0
cleanup() {
  git -C "$root" worktree remove --force "$work" 2>/dev/null || rm -rf "$work"
  if [[ $pushed -eq 0 ]]; then git -C "$root" branch -D "$branch" >/dev/null 2>&1 || true; fi
}
trap cleanup EXIT
git worktree add --quiet -b "$branch" "$work" origin/main
cd "$work"

# --no-overlay (restore's default): a file removed on dev is removed here too.
git restore --source="$source" --staged --worktree -- "${SHIPPING[@]}"

if git diff --cached --quiet; then
  echo "release: main already matches $source for the shipping files; nothing to do."
  exit 0
fi

outside=$(git diff --cached --name-only | grep -v -E "^($(IFS='|'; echo "${SHIPPING[*]//./\\.}"))(/|$)" || true)
[[ -z "$outside" ]] || die "files outside the shipping set staged:"$'\n'"$outside"

leaks=$(git diff --cached -U0 | grep -E '^\+' | grep -n -E "$LEAK_PATTERN" || true)
[[ -z "$leaks" ]] || die "possible internal data in the diff (public repo):"$'\n'"$leaks"

v_main=$(git show origin/main:plugins/omisell/.claude-plugin/plugin.json | version)
v_new=$(version < plugins/omisell/.claude-plugin/plugin.json)
if [[ "$v_main" == "$v_new" ]]; then
  echo "release: warning: version is still $v_new (bump it on dev before a real release)." >&2
fi

claude plugin validate plugins/omisell --profile directory --strict

echo
git diff --cached --stat
git commit --quiet -m "$message"

if [[ $dry_run -eq 1 ]]; then
  echo "release: dry run OK ($v_main → $v_new); nothing pushed."
  exit 0
fi

git push --quiet -u origin "$branch"
pushed=1
gh pr create --base main --head "$branch" --title "$message" --body "$(cat <<EOF
Release from \`dev\` ($v_main → $v_new): only the shipping files, one commit. Built by \`scripts/release.sh\`.

- validated: \`claude plugin validate plugins/omisell --profile directory --strict\`
- scanned the diff for internal hosts, ids, emails and tokens
EOF
)"
echo "release: after merging that PR (squash), run: scripts/release.sh --draft-release <notes.md>"
