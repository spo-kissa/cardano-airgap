#!/bin/sh

docker compose exec airgap bash
RET=$?
if [ $RET -eq 1 ]; then
	echo
    echo "※ Dockerに接続出来ませんでした。"
    echo "※ 先に './build.sh' と './start.sh' を実行する必要があります。"
    echo
fi
