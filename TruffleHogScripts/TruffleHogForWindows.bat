@echo off
setlocal

:: Determine system architecture
set ARCH=%PROCESSOR_ARCHITECTURE%
set OS=windows

:: Set download URL and base directory
set BASE_URL=https://github.com/trufflesecurity/trufflehog/releases/download/v3.83.7
set BINARY_NAME=trufflehog.exe
set INSTALL_DIR=%ProgramFiles%

:: Determine the correct binary to download
if "%ARCH%"=="AMD64" (
    set FILE=trufflehog_3.83.7_windows_amd64.tar.gz
) else if "%ARCH%"=="ARM64" (
    set FILE=trufflehog_3.83.7_windows_arm64.tar.gz
) else (
    echo Unsupported architecture: %ARCH% for Windows
    exit /b 1
)

:: Download the file
echo Downloading %FILE% from %BASE_URL%
powershell -Command "Invoke-WebRequest -OutFile %TEMP%\%FILE% -Uri %BASE_URL%/%FILE%"

:: Extract the tar.gz file
echo Extracting...
powershell -Command "Expand-Archive -Path %TEMP%\%FILE% -DestinationPath %TEMP%\trufflehog"

:: Move the binary to the installation directory
move /Y "%TEMP%\trufflehog\%BINARY_NAME%" "%INSTALL_DIR%"

:: Clean up
rd /S /Q "%TEMP%\trufflehog"
del "%TEMP%\%FILE%"

:: Verify installation
echo Installation complete. Verifying version...
"%INSTALL_DIR%\%BINARY_NAME%" --version

endlocal
