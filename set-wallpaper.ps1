$url = "https://raw.githubusercontent.com/Felipegf-hub/wallpaper-empresa/main/desktop_NPE.jpg"
$logFile = "C:\ProgramData\WallpaperUpdater\wallpaper.log"

function Write-Log($msg) {
    "$(Get-Date) - $msg" | Out-File $logFile -Append
}

try {
    Write-Log "Iniciando..."

    $explorerProc = Get-CimInstance Win32_Process -Filter "Name = 'explorer.exe'" | Select-Object -First 1
    if (-not $explorerProc) {
        Write-Log "Nenhum processo explorer.exe encontrado. Nenhum usuario logado. Abortando."
        exit
    }

    $ownerInfo = Invoke-CimMethod -InputObject $explorerProc -MethodName GetOwner
    $usuario = $ownerInfo.User
    $dominio = $ownerInfo.Domain
    Write-Log "Usuario ativo detectado: $dominio\$usuario"

    $sid = (New-Object System.Security.Principal.NTAccount($dominio, $usuario)).Translate([System.Security.Principal.SecurityIdentifier]).Value
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

    Write-Log "Wallpaper aplicado com sucesso para $dominio\$usuario"
    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Log "ERRO: $_"
}