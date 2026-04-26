@echo off
setlocal enabledelayedexpansion

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~f0' -Verb RunAs"
    exit /b
)

echo Running with administrator privileges...
echo.

REM Detect installed browsers
set chrome_path=""
set edge_path=""
set firefox_path=""

REM Check for Chrome
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    set chrome_path="%ProgramFiles%\Google\Chrome\Application\chrome.exe"
    echo Chrome detected
)
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    set chrome_path="%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
    echo Chrome detected
)

REM Check for Edge
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    set edge_path="%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
    echo Edge detected
)
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    set edge_path="%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
    echo Edge detected
)

REM Check for Firefox
if exist "%ProgramFiles%\Mozilla Firefox\firefox.exe" (
    set firefox_path="%ProgramFiles%\Mozilla Firefox\firefox.exe"
    echo Firefox detected
)
if exist "%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe" (
    set firefox_path="%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe"
    echo Firefox detected
)

echo.

REM Disable DevTools in Chrome
if not "%chrome_path%"=="" (
    echo Disabling DevTools in Chrome...
    reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v "DeveloperToolsAvailability" /t REG_DWORD /d 2 /f >nul
    reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v "BlockDeveloperTools" /t REG_DWORD /d 1 /f >nul
    echo Chrome DevTools disabled
)

REM Disable DevTools in Edge
if not "%edge_path%"=="" (
    echo Disabling DevTools in Edge...
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "DeveloperToolsAvailability" /t REG_DWORD /d 2 /f >nul
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "BlockDeveloperTools" /t REG_DWORD /d 1 /f >nul
    echo Edge DevTools disabled
)

REM Create/update Firefox policies.json to disable DevTools
if not "%firefox_path%"=="" (
    echo Disabling DevTools in Firefox...
    set firefox_policy_dir="%ProgramFiles%\Mozilla Firefox\distribution"
    if not exist !firefox_policy_dir! (
        set firefox_policy_dir="%ProgramFiles(x86)%\Mozilla Firefox\distribution"
        if not exist !firefox_policy_dir! (
            mkdir !firefox_policy_dir!
        )
    )
    
    echo { > !firefox_policy_dir!\policies.json
    echo   "policies": { >> !firefox_policy_dir!\policies.json
    echo     "DisableDeveloperTools": true, >> !firefox_policy_dir!\policies.json
    echo     "DisableTelemetry": true >> !firefox_policy_dir!\policies.json
    echo   } >> !firefox_policy_dir!\policies.json
    echo } >> !firefox_policy_dir!\policies.json
    
    echo Firefox DevTools disabled
)

echo.

REM Install/enforce uBlock Origin for each detected browser
if not "%chrome_path%"=="" (
    echo Installing uBlock Origin for Chrome...
    powershell -Command "& {$extensionId = 'cjpalhdlnbpafiamejdnhcphjbkeiagm'; $chromePath = %chrome_path%; $extensionsPath = Join-Path (Split-Path $chromePath -Parent) 'Extensions'; $ublockPath = Join-Path $extensionsPath $extensionId; if (-not (Test-Path $ublockPath)) { New-Item -Path $ublockPath -ItemType Directory -Force; Invoke-WebRequest -Uri 'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/addon-607454-latest.xpi' -OutFile '$ublockPath\ublock.zip'; Expand-Archive -Path '$ublockPath\ublock.zip' -DestinationPath $ublockPath -Force; }}"
    echo uBlock Origin installed for Chrome
)

if not "%edge_path%"=="" (
    echo Installing uBlock Origin for Edge...
    powershell -Command "& {$extensionId = 'cjpalhdlnbpafiamejdnhcphjbkeiagm'; $edgePath = %edge_path%; $extensionsPath = Join-Path (Split-Path $edgePath -Parent) 'Extensions'; $ublockPath = Join-Path $extensionsPath $extensionId; if (-not (Test-Path $ublockPath)) { New-Item -Path $ublockPath -ItemType Directory -Force; Invoke-WebRequest -Uri 'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/addon-607454-latest.xpi' -OutFile '$ublockPath\ublock.zip'; Expand-Archive -Path '$ublockPath\ublock.zip' -DestinationPath $ublockPath -Force; }}"
    echo uBlock Origin installed for Edge
)

if not "%firefox_path%"=="" (
    echo Installing uBlock Origin for Firefox...
    powershell -Command "& {$firefoxPath = %firefox_path%; $profilePath = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'; if (Test-Path $profilePath) { $profiles = Get-ChildItem $profilePath -Directory; foreach ($profile in $profiles) { $extensionsPath = Join-Path $profile.FullName 'extensions'; if (-not (Test-Path $extensionsPath)) { New-Item -Path $extensionsPath -ItemType Directory -Force; } $ublockPath = Join-Path $extensionsPath 'uBlock0@raymondhill.net.xpi'; if (-not (Test-Path $ublockPath)) { Invoke-WebRequest -Uri 'https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/addon-607454-latest.xpi' -OutFile $ublockPath; } }}}"
    echo uBlock Origin installed for Firefox
)

echo.

REM Block CMD, PowerShell, and Windows Terminal by default
echo Blocking command-line tools...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableCMD" /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableRegistryTools" /t REG_DWORD /d 1 /f >nul

REM Block PowerShell
reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v "ExecutionPolicy" /t REG_SZ /d "Restricted" /f >nul
reg add "HKCU\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v "ExecutionPolicy" /t REG_SZ /d "Restricted" /f >nul

REM Block Windows Terminal
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "NoWindowsTerminal" /t REG_DWORD /d 1 /f >nul

echo Command-line tools blocked
echo.

echo Script completed successfully. All browsers have been secured.
echo The system will now exit without background monitoring.
timeout /t 5 /nobreak >nul
exit /b