@echo off
REM ============================================================
REM Silvestre Fotoservizi - deploy manuale
REM Build Flutter web release + deploy su Firebase Hosting
REM ============================================================

setlocal

REM Carica FIREBASE_TOKEN da .env.local
for /f "tokens=2 delims==" %%a in ('findstr /b "FIREBASE_REFRESH_TOKEN=" .env.local 2^>nul') do set FIREBASE_TOKEN=%%a
if "%FIREBASE_TOKEN%"=="" (
    echo.
    echo ATTENZIONE: nessun FIREBASE_REFRESH_TOKEN trovato in .env.local
    echo Imposta manualmente:  set FIREBASE_TOKEN=il_tuo_refresh_token
    echo Oppure aggiungi al .env.local:  FIREBASE_REFRESH_TOKEN=...
    pause
    exit /b 1
)

echo.
echo === 1/3 Flutter analyze ===
cd app
call C:\Users\Nicola\dev\flutter\bin\flutter.bat analyze
if errorlevel 1 (
    echo ERRORE: flutter analyze ha trovato problemi. Risolverli prima di fare deploy.
    pause
    exit /b 1
)

echo.
echo === 2/3 Flutter build web ^(release^) ===
call C:\Users\Nicola\dev\flutter\bin\flutter.bat build web --release
if errorlevel 1 (
    echo ERRORE: build fallito.
    pause
    exit /b 1
)

echo.
echo === 3/3 Deploy Firebase Hosting ===
cd ..
if exist firebase\public rd /s /q firebase\public
mkdir firebase\public
xcopy /E /Y /Q app\build\web firebase\public >nul

cd firebase
set PATH=C:\Program Files\nodejs;%PATH%
call C:\Users\Nicola\AppData\Roaming\npm\firebase.cmd deploy --only hosting --token "%FIREBASE_TOKEN%"
if errorlevel 1 (
    echo ERRORE: deploy fallito.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  DEPLOY COMPLETO
echo  App live: https://silvestre-fotoservizi.web.app
echo ============================================================
echo.
pause
