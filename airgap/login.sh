#!/bin/sh

if ! docker compose exec airgap bash; then
    echo "Dockerに接続出来ませんでした。"
    echo "先に './build.sh' と './start.sh' を実行する必要があります。"
fi
