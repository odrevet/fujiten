#!/usr/bin/env bash
set -e

REPO=$(basename -s .git "$(git remote get-url origin)")

flutter build web --release --base-href "/$REPO/"

WT=$(mktemp -d)
git worktree add "$WT" gh-pages
trap 'git worktree remove --force "$WT"' EXIT

find "$WT" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +

cp -r build/web/. "$WT"/

git -C "$WT" add -A
git -C "$WT" commit -m "update web build"
git -C "$WT" push origin gh-pages