$url = "https://raw.githubusercontent.com/Felipegf-hub/wallpaper-empresa/main/desktop_NPE.jpg"
$logFile = "C:\ProgramData\WallpaperUpdater\wallpaper.log"

function Write-Log($msg) {
    "$(Get-Date) - $msg" | Out-File $logFile -Append
}

try {
    Write-Log "Iniciando..."

    $sessao = quser 2>$null | Where-Object { $_ -match "Ativo|Active" }
    if (-not $sessao) {
        Write-Log "Nenhum usuario com sessao ativa encontrado. Abortando."
        exit
    }

    $linhaLimpa = ($sessao -replace '^>', '').Trim()
    $campos = $linhaLimpa -split '\s+'
    $usuario = $campos[0]
    Write-Log "Usuario ativo detectado: $usuario"

    $sid = (New-Object System.Security.Principal.NTAccount($usuario)).Translate([System.Security.Principal.SecurityIdentifier]).Value
    Write-Log "SID: $sid"

    $perfilPath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid").ProfileImagePath
    $path = "$perfilPath\AppData\Roaming\wallpaper.jpg"

    $tempPath = "$env:TEMP\wallpaper_novo.jpg"
    Invoke-WebRequest -Uri $url -OutFile $tempPath -UseBasicParsing
    Copy-Item $tempPath $path -Force
    Write-Log "Imagem salva em: $path"

    $hiveCarregado = Test-Path "Registry::HKEY_USERS\$sid"
    if (-not $hiveCarregado) {
        reg load "HKU\$sid" "$perfilPath\NTUSER.DAT" | Out-Null
        Write-Log "Hive do usuario carregado manualmente"
    }

    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Control Panel\Desktop" -Name WallpaperStyle -Value "10"
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Control Panel\Desktop" -Name TileWallpaper -Value "0"
    Set-ItemProperty -Path "Registry::HKEY_USERS\$sid\Control Panel\Desktop" -Name Wallpaper -Value $path

    if (-not $hiveCarregado) {
        [gc]::Collect()
        reg unload "HKU\$sid" | Out-Null
    }

    RUNDLL32.EXE user32.dll, UpdatePerUserSystemParameters

    Write-Log "Wallpaper aplicado com sucesso para $usuario"
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Log "ERRO: $_"
}