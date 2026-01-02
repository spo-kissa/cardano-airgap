#!/usr/bin/env bash
set -euo pipefail

CURDIR="$(basename "$PWD")"
export AIRGAP_NAME="$CURDIR"

docker compose stop
if [ $? -ne 0 ]; then
    echo "Failed to stop the Docker containers."
    exit 1
fi
