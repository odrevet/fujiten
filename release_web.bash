#!/usr/bin/env bash
set -e

flutter build web --release --base-href /fujiten/

cp -r build/web /tmp/fujiten_web

git switch gh-pages
rm -rf -- *
cp -r /tmp/fujiten_web/. .

git add -A
git commit -m "update web build"
git push origin gh-pages

git switch main

rm -rf /tmp/fujiten_web