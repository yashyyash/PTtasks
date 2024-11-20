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
if "%ARCH%"=="64-bit" (
    set ARCH=amd64
) else (
    echo Unsupported architecture: %ARCH%
    exit /b 1
)

:: Prepare variables
set BASE_URL=https://github.com/trufflesecurity/trufflehog/releases/download/v3.83.7
set BINARY_NAME=trufflehog
set INSTALL_DIR=%~dp0bin
set FILE=trufflehog_3.83.7_windows_%ARCH%.tar.gz

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Download the binary
echo Downloading %FILE% from %BASE_URL%
curl -LO "%BASE_URL%/%FILE%"
if %errorlevel% neq 0 (
    echo Failed to download %FILE%
    exit /b 1
)

:: Extract the TAR.GZ file
echo Extracting %FILE%
powershell -Command "tar -xvf '%FILE%' -C '%INSTALL_DIR%'"
if %errorlevel% neq 0 (
    echo Failed to extract %FILE%.
    exit /b 1
)

:: Clean up downloaded archive
del %FILE%

:: Ensure the binary directory is in the PATH
for /f "tokens=*" %%A in ('powershell -Command "[System.Environment]::GetEnvironmentVariable('Path', 'User')"') do set "USER_PATH=%%A"

echo Adding %INSTALL_DIR% to PATH...
echo Current USER PATH: !USER_PATH!

if "!USER_PATH!" == "" (
    echo "Path variable could not be fetched properly. Please verify the script's execution."
    exit /b 1
)

echo !USER_PATH! | findstr /i /c:"%INSTALL_DIR%" >nul
if %errorlevel% neq 0 (
    powershell -Command "[System.Environment]::SetEnvironmentVariable('Path', '!USER_PATH!;%INSTALL_DIR%', 'User')"
    echo %INSTALL_DIR% has been added to PATH. Please restart your terminal for changes to take effect.
) else (
    echo %INSTALL_DIR% is already in PATH.
)


:: Test if TruffleHog is accessible
%INSTALL_DIR%\%BINARY_NAME%.exe --version
if %errorlevel% neq 0 (
    echo Failed to verify TruffleHog installation.
    exit /b 1
)

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
echo         entry: "%INSTALL_DIR%\%BINARY_NAME%.exe git file://. --since-commit HEAD --fail"
echo         language: system
echo         stages: [^"pre-commit^", ^"pre-push^"]
) > .pre-commit-config.yaml

echo Installing pre-commit hook...
pre-commit install

echo Pre-commit and TruffleHog setup complete.
