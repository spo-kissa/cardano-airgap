@echo off

for %%I in (.) do set "CURDIR=%%~nxI"
SET AIRGAP_NAME=%CURDIR%

docker compose -f docker-compose.yml up -d
if %errorlevel% neq 0 (
    echo Failed to start Docker containers.
    exit /b %errorlevel%
)

docker compose exec airgap bash
if %errorlevel% neq 0 (
    echo Failed to execute command in airgap container.
    exit /b %errorlevel%
)
