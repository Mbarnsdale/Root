@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Grannies Helper

:: =========================
:: ADMIN CHECK (CMD ONLY)
:: =========================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elev.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\elev.vbs"
    cscript //nologo "%temp%\elev.vbs"
    del "%temp%\elev.vbs"
    exit /b
)

echo Running as administrator...
echo.

:: =========================
:: DETECT BROWSERS
:: =========================
set CHROME=0
set EDGE=0
set FIREFOX=0

if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set CHROME=1
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set CHROME=1

if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" set EDGE=1

if exist "%ProgramFiles%\Mozilla Firefox\firefox.exe" set FIREFOX=1
if exist "%ProgramFiles(x86)%\Mozilla Firefox\firefox.exe" set FIREFOX=1

echo Chrome: !CHROME!
echo Edge: !EDGE!
echo Firefox: !FIREFOX!
echo.

:: =========================
:: CHROME POLICY
:: =========================
if !CHROME! EQU 1 (
    echo Configuring Chrome...

    reg add "HKLM\SOFTWARE\Policies\Google\Chrome" ^
    /v DeveloperToolsAvailability /t REG_DWORD /d 2 /f >nul

    reg add "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" ^
    /v 1 /t REG_SZ ^
    /d "cjpalhdlnbpafiamejdnhcphjbkeiagm;https://clients2.google.com/service/update2/crx" /f >nul

    echo Chrome configured

    :: Kill Chrome to apply changes
    taskkill /IM chrome.exe /F >nul 2>&1
)

:: =========================
:: EDGE POLICY
:: =========================
if !EDGE! EQU 1 (
    echo Configuring Edge...

    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" ^
    /v DeveloperToolsAvailability /t REG_DWORD /d 2 /f >nul

    reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist" ^
    /v 1 /t REG_SZ ^
    /d "odfafepnkmbhccpbejgmiehpchacaeak;https://edge.microsoft.com/extensionwebstorebase/v1/crx" /f >nul

    echo Edge configured

    :: Kill Edge to apply changes
    taskkill /IM msedge.exe /F >nul 2>&1
)

:: =========================
:: FIREFOX POLICY
:: =========================
if !FIREFOX! EQU 1 (
    echo Configuring Firefox...

    set "FF_DIR=%ProgramFiles%\Mozilla Firefox\distribution"

    if not exist "!FF_DIR!" (
        set "FF_DIR=%ProgramFiles(x86)%\Mozilla Firefox\distribution"
    )

    if not exist "!FF_DIR!" (
        mkdir "!FF_DIR!" >nul 2>&1
    )

    (
    echo {
    echo   "policies": {
    echo     "DisableDeveloperTools": true,
    echo     "Extensions": {
    echo       "Install": [
    echo         "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
    echo       ]
    echo     }
    echo   }
    echo }
    ) > "!FF_DIR!\policies.json"

    echo Firefox configured

    :: Kill Firefox to apply changes
    taskkill /IM firefox.exe /F >nul 2>&1
)

echo.

:: =========================
:: BLOCK CMD / POWERSHELL / TERMINAL
:: =========================
echo Applying shell restrictions...

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" ^
/v DisallowRun /t REG_DWORD /d 1 /f >nul

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" ^
/v 1 /t REG_SZ /d cmd.exe /f >nul

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" ^
/v 2 /t REG_SZ /d powershell.exe /f >nul

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" ^
/v 3 /t REG_SZ /d wt.exe /f >nul

:: kill current sessions
taskkill /IM cmd.exe /F >nul 2>&1
taskkill /IM powershell.exe /F >nul 2>&1
taskkill /IM wt.exe /F >nul 2>&1

echo.
echo COMPLETE.
echo Rebooting computer in 60 seconds to apply all registry changes...
shutdown /r /t 60
exit