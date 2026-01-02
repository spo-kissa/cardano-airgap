@echo off

for %%I in (.) do set "CURDIR=%%~nxI"
SET AIRGAP_NAME=%CURDIR%

echo.
echo ※ 注意 ※
echo このコマンドを続行すると、鍵ファイルも削除されます！
echo 鍵ファイルをエクスポートしている事を確認してください！
echo.
echo 中止するにはウィンドウを閉じるか、Ctrl+Cで終了してください。
echo.

pause


docker compose down --rmi all --volumes --remove-orphans
