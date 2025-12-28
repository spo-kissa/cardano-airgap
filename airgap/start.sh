#!/usr/bin/env bash
set -euo pipefail

CURDIR="$(basename "$PWD")"
export AIRGAP_NAME="$CURDIR"

docker compose -f docker-compose.yml up -d
RET=$?
if [ $RET -eq 1 ]; then
    echo
    echo "※ Dockerに接続出来ませんでした。"
    echo
else
    docker compose exec airgap bash
    RET=$?
    if [ $RET -eq 1 ]; then
        echo
        echo "※ Dockerに接続出来ませんでした。"
        echo
    fi
fi
