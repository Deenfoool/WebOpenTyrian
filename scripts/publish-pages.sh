#!/usr/bin/env bash
# Publish the verified dist directory to gh-pages using ordinary git (no Actions).
set -Eeuo pipefail
cd "$(dirname "$0")/.."
python3 tests/check_dist.py dist

REMOTE="${GIT_REMOTE:-origin}"
git remote get-url "$REMOTE" >/dev/null
tmp="$(mktemp -d)"
cleanup() {
  git worktree remove --force "$tmp" >/dev/null 2>&1 || true
  rmdir "$tmp" >/dev/null 2>&1 || true
}
trap cleanup EXIT

remote_head="$(git ls-remote --heads "$REMOTE" refs/heads/gh-pages | cut -f1)"
git worktree add --detach "$tmp" HEAD >/dev/null
if [[ -n "$remote_head" ]]; then
  git fetch "$REMOTE" "refs/heads/gh-pages:refs/remotes/$REMOTE/gh-pages"
  git -C "$tmp" checkout --detach "refs/remotes/$REMOTE/gh-pages" >/dev/null
else
  git -C "$tmp" checkout --orphan gh-pages >/dev/null
fi

# Remove only versioned files from the disposable deployment worktree.
git -C "$tmp" rm -r -q --ignore-unmatch -- .
cp -a dist/. "$tmp/"
git -C "$tmp" add -A
if git -C "$tmp" diff --cached --quiet; then
  echo 'Published files are unchanged; nothing to push.'
  exit 0
fi
git -C "$tmp" commit -m "Publish browser build from $(git rev-parse --short HEAD)" >/dev/null
git -C "$tmp" push "$REMOTE" HEAD:refs/heads/gh-pages
echo 'Published to gh-pages. In GitHub Settings → Pages choose Deploy from a branch, gh-pages, /(root).'
