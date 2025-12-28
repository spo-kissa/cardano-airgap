#!/usr/bin/env bash
set -euo pipefail

docker compose down
if [ $? -ne 0 ]; then
    echo "Failed to shut down the Docker containers."
    exit 1
fi
