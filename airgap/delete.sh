#!/usr/bin/env bash
set -euo pipefail

echo
echo "※ 注意 ※"
echo "このコマンドを続行すると、鍵ファイルも削除されます！"
echo "鍵ファイルをエクスポートしている事を確認してください！"
echo
echo "中止するにはウィンドウを閉じるか、Ctrl+Cで終了してください。"
echo

# pause 相当（対話端末でのみキー待ち）
if [ -t 0 ]; then
  read -n1 -s -r -p "続行するには何かキーを押してください..." ; echo
else
  echo "非対話環境のため自動的に続行します..."
fi

# docker compose / docker-compose どちらでも対応
if docker compose version >/dev/null 2>&1; then
  DC=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  DC=(docker-compose)
else
  echo "Docker Compose が見つかりません。インストールを確認してください。" >&2
  exit 1
fi

"${DC[@]}" down --rmi all --volumes --remove-orphans

