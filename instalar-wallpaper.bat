@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Este script precisa ser executado como Administrador.
    echo Clique com o botao direito e escolha "Executar como administrador".
    pause
    exit /b 1
)

set SCRIPT_DIR=C:\ProgramData\WallpaperUpdater
set "SCRIPT_URL=https://drive.google.com/uc?export=download&id=1fiamT3bTE5GPlRb7T5xYJ08iVKnVKLz8"

mkdir "%SCRIPT_DIR%" 2>nul

echo Baixando script de atualizacao...
powershell -Command "Invoke-WebRequest -Uri '%SCRIPT_URL%' -OutFile '%SCRIPT_DIR%\set-wallpaper.ps1' -UseBasicParsing"

if not exist "%SCRIPT_DIR%\set-wallpaper.ps1" (
    echo ERRO: Nao foi possivel baixar o script. Verifique o link ou a conexao.
    pause
    exit /b 1
)

schtasks /create /tn "AtualizarWallpaper" /tr "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT_DIR%\set-wallpaper.ps1\"" /sc onlogon /rl highest /f
schtasks /create /tn "AtualizarWallpaperPeriodico" /tr "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT_DIR%\set-wallpaper.ps1\"" /sc daily /st 09:00 /rl highest /f

powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\set-wallpaper.ps1"

echo.
echo Instalacao concluida! O wallpaper sera atualizado automaticamente.
pause