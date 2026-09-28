@echo off
rem Sync all GitHub repositories into the Claude folder - double-click to run.
rem  - Clones any repository this PC does not have yet.
rem  - Updates (fast-forward only) repositories that are behind GitHub.
rem  - Never overwrites local work: repos with uncommitted changes are skipped.
rem Default Claude folder = the folder that contains tokyo-meiten-map.
rem To use another folder:  sync-all.cmd "C:\path\to\Claude"
setlocal EnableDelayedExpansion

set OWNER=shungeekgogo
rem Add new repository names here (separated by spaces).
set REPOS=tokyo-meiten-map tokyo-gym-map Paris-apartment-listing-map Language-practice-2 Calculator

if "%~1"=="" (set "ROOT=%~dp0..\..") else (set "ROOT=%~1")
for %%I in ("%ROOT%") do set "ROOT=%%~fI"

where git >nul 2>nul || (
  echo Git was not found. Install Git for Windows from https://git-scm.com/
  pause
  exit /b 1
)

echo Claude folder: %ROOT%
echo.
if not exist "%ROOT%" mkdir "%ROOT%"

set PROBLEMS=0
for %%R in (%REPOS%) do call :sync %%R

echo.
if %PROBLEMS%==0 (echo All repositories are up to date with GitHub.) else (echo %PROBLEMS% repository^(s^) need attention - see messages above.)
pause
exit /b 0

:sync
set "NAME=%~1"
set "DIR=%ROOT%\%NAME%"
if not exist "%DIR%\" (
  echo [%NAME%] not on this PC - cloning...
  git clone --quiet "https://github.com/%OWNER%/%NAME%.git" "%DIR%"
  if errorlevel 1 (echo [%NAME%] ERROR: clone failed. & set /a PROBLEMS+=1) else (echo [%NAME%] cloned.)
  exit /b 0
)
if not exist "%DIR%\.git" (
  echo [%NAME%] WARNING: folder exists but is not a git repository - skipped.
  set /a PROBLEMS+=1
  exit /b 0
)
pushd "%DIR%"
git fetch --quiet origin
if errorlevel 1 (
  echo [%NAME%] ERROR: could not reach GitHub.
  set /a PROBLEMS+=1
  popd & exit /b 0
)
set DIRTY=
for /f "delims=" %%L in ('git status --porcelain') do set DIRTY=1
set BEHIND=0
set AHEAD=0
for /f %%N in ('git rev-list --count "HEAD..@{u}" 2^>nul') do set BEHIND=%%N
for /f %%N in ('git rev-list --count "@{u}..HEAD" 2^>nul') do set AHEAD=%%N
if defined DIRTY (
  echo [%NAME%] WARNING: uncommitted changes on this PC - not updated. Commit and push them first.
  set /a PROBLEMS+=1
) else if not !BEHIND!==0 (
  git merge --quiet --ff-only "@{u}" >nul 2>nul
  if errorlevel 1 (
    echo [%NAME%] ERROR: this PC and GitHub both have different changes - resolve manually.
    set /a PROBLEMS+=1
  ) else (
    echo [%NAME%] updated ^(!BEHIND! new commit^(s^) from GitHub^).
  )
) else (
  echo [%NAME%] up to date.
)
if not !AHEAD!==0 (
  echo [%NAME%] NOTE: !AHEAD! local commit^(s^) not pushed to GitHub yet - run git push.
  set /a PROBLEMS+=1
)
popd
exit /b 0
