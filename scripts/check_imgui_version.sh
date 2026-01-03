#!/usr/bin/env bash
set -e

cd third_party/imgui
git describe --tags --exact-match \
  || (echo "ERROR: imgui is not on a tag" && exit 1)
