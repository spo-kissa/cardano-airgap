#!/bin/bash

echo
echo "Dockerのビルドを開始しています..."
echo
echo

docker compose build --no-cache
RESULT=$?

if [ "$RESULT" -ne 0 ]; then
    echo
    tput setaf 1 && echo "Dockerのビルドに失敗しました..." && tput setaf 7
    echo "  ・インターネットに接続出来ているか確認してください。"
    echo "  ・時間をおいてから再度お試しください。"
    echo
    exit "$RESULT"
fi

exit 0
