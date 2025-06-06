@echo off

docker compose airgap down
if %errorlevel% neq 0 (
    echo Failed to stop the Docker containers.
    exit /b %errorlevel%
)
