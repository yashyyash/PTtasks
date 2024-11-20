@echo off
setlocal enabledelayedexpansion

:: Check if inside a git repository
git rev-parse --is-inside-work-tree >nul 2>&1
if %errorlevel% neq 0 (
    echo This script must be run inside a git repository.
    exit /b 1
)

:: Determine system architecture
for /f "tokens=2 delims==" %%A in ('wmic os get osarchitecture /value 2^>nul') do (
    set "ARCH=%%A"
)

:: Trim whitespace
set ARCH=%ARCH: =%
if "%ARCH%" == "64-bit" (
    set ARCH=amd64
) else (
    echo Unsupported architecture: %ARCH%
    exit /b 1
)

:: Determine operating system
for /f "tokens=*" %%A in ('ver') do (
    set "OS=%%A"
)
echo Detected OS: %OS%

:: Prepare variables
set BASE_URL=https://github.com/trufflesecurity/trufflehog/releases/download/v3.83.7
set BINARY_NAME=trufflehog
set INSTALL_DIR=%~dp0bin
set FILE=

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Check Windows architecture for compatibility
if /i "%ARCH%"=="amd64" (
    set FILE=trufflehog_3.83.7_windows_amd64.zip
) else (
    echo Unsupported architecture for Windows: %ARCH%
    exit /b 1
)

echo Downloading %FILE% from %BASE_URL%
curl -LO "%BASE_URL%/%FILE%"
if %errorlevel% neq 0 (
    echo Failed to download %FILE%
    exit /b 1
)

echo Extracting %FILE%
tar -xzf %FILE%
move "%BINARY_NAME%.exe" "%INSTALL_DIR%"

echo Cleaning up...
del %FILE%

:: Ensure the binary is executable
set PATH=%PATH%;%INSTALL_DIR%

:: Setup Python virtual environment
if not exist venv (
    echo Setting up a Python virtual environment...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo Failed to create a Python virtual environment.
        exit /b 1
    )
)

echo Activating the virtual environment...
call venv\Scripts\activate

echo Installing pre-commit...
pip install pre-commit

echo Configuring pre-commit for TruffleHog...
(
echo repos:
echo   - repo: local
echo     hooks:
echo       - id: trufflehog
echo         name: TruffleHog
echo         description: Detect secrets in your data.
echo         entry: trufflehog git file://. --since-commit HEAD --fail
echo         language: system
echo         stages: [^"pre-commit^", ^"pre-push^"]
) > .pre-commit-config.yaml

echo Installing pre-commit hook...
pre-commit install

echo Pre-commit and TruffleHog setup complete.
