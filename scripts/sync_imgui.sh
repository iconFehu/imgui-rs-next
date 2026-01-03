#!/usr/bin/env bash
set -e

cd third_party/imgui
git fetch origin
git checkout master
git pull

cd ../..
git add third_party/imgui
git commit -m "chore: sync imgui upstream"
