@echo off

for %%I in (.) do set "CURDIR=%%~nxI"
SET AIRGAP_NAME=%CURDIR%

docker compose stop
if %errorlevel% neq 0 (
    echo Failed to stop the Docker containers.
    exit /b %errorlevel%
)
