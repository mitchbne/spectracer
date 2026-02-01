#!/bin/bash

set -euo pipefail

export REGISTRY="$(nsc workspace describe -o json -k registry_url)"
export SERVICE="base"
export DOCKER_REPOSITORY="${REGISTRY}/${SERVICE}:1.0"

docker buildx build \
  --no-cache \
  --file .buildkite/Dockerfile.build \
  --platform linux/amd64 \
  --tag "${DOCKER_REPOSITORY}" \
  --progress plain \
  --push .

buildkite-agent annotate --style "success" ":rocket: Image pushed to ${DOCKER_REPOSITORY} :rocket:"
