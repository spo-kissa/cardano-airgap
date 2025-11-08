@echo off

echo.
echo 「バージョンアップ」
echo.
echo ※ 注意 ※
echo.
echo このコマンドを続行すると、鍵ファイルも削除されます！
echo 鍵ファイルをエクスポートしている事を確認してください！
echo.
echo 中止するにはウィンドウを閉じるか、Ctrl+Cで終了してください。
echo.

pause

docker compose -f build --no-cache

docker compose -f up -d

docker cp bin/ctool.sh airgap:/home/cardano/bin/ctool.sh
