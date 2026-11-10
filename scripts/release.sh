#!/usr/bin/env bash
# Ship dev to main as ONE commit holding only the shipping files.
#
#   scripts/release.sh <slug> "<message>"            # branch, commit, push, PR → main
#   scripts/release.sh --dry-run <slug> "<message>"  # stop before push, show the diff
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

version() { python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])'; }
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
