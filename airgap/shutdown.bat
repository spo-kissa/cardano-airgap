@echo off

docker compose down
if %errorlevel% neq 0 (
    echo Failed to stop the Docker containers.
    exit /b %errorlevel%
)
echo Docker containers stopped successfully.
