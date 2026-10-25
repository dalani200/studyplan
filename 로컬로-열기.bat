@echo off
setlocal
cd /d "%~dp0"
set "STUDYPLAN_PORT=4173"

where py >nul 2>nul
if %errorlevel%==0 (
  start "Studyplan local server" /min cmd /c "cd /d ""%~dp0"" && py -m http.server %STUDYPLAN_PORT% --bind 127.0.0.1"
  goto open_site
)

where python >nul 2>nul
if %errorlevel%==0 (
  start "Studyplan local server" /min cmd /c "cd /d ""%~dp0"" && python -m http.server %STUDYPLAN_PORT% --bind 127.0.0.1"
  goto open_site
)

echo Python was not found. Install Python, then run this file again.
pause
exit /b 1

:open_site
timeout /t 2 /nobreak >nul
start "" "http://127.0.0.1:%STUDYPLAN_PORT%/"
endlocal
