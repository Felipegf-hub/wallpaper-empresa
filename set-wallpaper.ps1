$url = "https://drive.google.com/uc?export=download&id=1FlwTR2q-03M9KucwX1IAKOdep6fBEyQR"
$path = "$env:APPDATA\wallpaper.jpg"
$hashFile = "$env:APPDATA\wallpaper.hash"

try {
    $tempPath = "$env:TEMP\wallpaper_novo.jpg"
    Invoke-WebRequest -Uri $url -OutFile $tempPath -UseBasicParsing

    $novoHash = (Get-FileHash $tempPath -Algorithm SHA256).Hash
    $hashAntigo = if (Test-Path $hashFile) { Get-Content $hashFile } else { "" }

    if ($novoHash -ne $hashAntigo) {
        Copy-Item $tempPath $path -Force
        Set-Content -Path $hashFile -Value $novoHash

        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet=CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
        [Wallpaper]::SystemParametersInfo(20, 0, $path, 3)
    }

    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Output "Erro ao atualizar wallpaper: $_"
}