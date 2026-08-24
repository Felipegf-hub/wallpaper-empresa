$url = "https://raw.githubusercontent.com/Felipegf-hub/wallpaper-empresa/main/desktop_NPE.jpg"
$path = "$env:APPDATA\wallpaper.jpg"
$hashFile = "$env:APPDATA\wallpaper.hash"
$logFile = "$env:APPDATA\wallpaper.log"

try {
    "$(Get-Date) - Iniciando..." | Out-File $logFile -Append

    $tempPath = "$env:TEMP\wallpaper_novo.jpg"
    Invoke-WebRequest -Uri $url -OutFile $tempPath -UseBasicParsing

    $novoHash = (Get-FileHash $tempPath -Algorithm SHA256).Hash
    $hashAntigo = if (Test-Path $hashFile) { Get-Content $hashFile } else { "" }

    "$(Get-Date) - Hash novo: $novoHash | Hash antigo: $hashAntigo" | Out-File $logFile -Append

    Copy-Item $tempPath $path -Force
    Set-Content -Path $hashFile -Value $novoHash

    # Garante o estilo "Preencher" (evita imagem nao aparecer corretamente)
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value "10"
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0"

    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    $resultado = [Wallpaper]::SystemParametersInfo(20, 0, $path, 3)
    "$(Get-Date) - Resultado SystemParametersInfo: $resultado" | Out-File $logFile -Append

    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
} catch {
    "$(Get-Date) - ERRO: $_" | Out-File $logFile -Append
}