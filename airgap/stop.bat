@echo off

docker compose stop
if %errorlevel% neq 0 (
    echo Failed to stop the Docker containers.
    exit /b %errorlevel%
)
