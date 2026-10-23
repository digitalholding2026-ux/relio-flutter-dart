# Verifie que le jeton du tuteur est REELLEMENT dans l'APK.
#
# Pourquoi ce script existe : un APK compile sans TUTOR_API_KEY est valide,
# se lance et affiche le message du tuteur simule. Rien ne le distingue d'une
# panne reseau. C'est exactement ce qui s'est produit avec l'APK v0.4.6-38 :
# l'URL OpenRouter etait presente dans libapp.so, mais aucun "sk-or-v1-".
#
# Le jeton est injecte par --dart-define : il atterrit dans la photo AOT
# Dart, c'est-a-dire lib/arm64-v8a/libapp.so. C'est LA que ce script le
# cherche, et nulle part ailleurs.
#
# Sortie : code 0 si le jeton est present, 1 sinon.
[CmdletBinding()]
param(
    [string]$Apk = 'build\app\outputs\flutter-apk\app-release.apk'
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

# Meme resolution que build_apk.ps1 : variable d'environnement, sinon fichier.
$key = $env:TUTOR_API_KEY
$envFile = Join-Path $PSScriptRoot 'tutor.env'
if (-not $key -and (Test-Path $envFile)) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*TUTOR_API_KEY\s*=\s*(.+)$') { $key = $Matches[1].Trim() }
    }
}

if (-not $key) {
    Write-Error "TUTOR_API_KEY introuvable : impossible de verifier l'APK."
    exit 1
}

if (-not (Test-Path $Apk)) {
    Write-Error "APK introuvable : $Apk"
    exit 1
}

$tmp = Join-Path $env:TEMP ('relio-apk-check-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $tmp | Out-Null

try {
    tar -xf $Apk -C $tmp 'lib/arm64-v8a/libapp.so'
    $lib = Join-Path $tmp 'lib\arm64-v8a\libapp.so'
    if (-not (Test-Path $lib)) {
        Write-Error "lib/arm64-v8a/libapp.so absent de l'APK : build inattendu."
        exit 1
    }

    # Latin-1 : lecture octet par octet, sans perdre les sequences binaires.
    $encoding = [Text.Encoding]::GetEncoding(28591)
    $snapshot = $encoding.GetString([IO.File]::ReadAllBytes($lib))

    if (-not $snapshot.Contains($key)) {
        Write-Host ''
        Write-Host "ECHEC : le jeton du tuteur est ABSENT de l'APK." -ForegroundColor Red
        Write-Host "L'application tombera en mode simule : elle repondra par le"
        Write-Host "message de repli, ce qui se confond avec une panne de l'IA."
        Write-Host "Ne pas publier cet APK. Relancer :"
        Write-Host "    powershell -File tool/build_apk.ps1"
        Write-Host ''
        exit 1
    }

    if (-not $snapshot.Contains('openrouter.ai')) {
        Write-Error "L'URL OpenRouter est absente de libapp.so : code du tuteur non embarque."
        exit 1
    }

    $size = [math]::Round((Get-Item $Apk).Length / 1MB, 1)
    Write-Host "Jeton du tuteur present dans libapp.so - APK verifie ($size Mo)." -ForegroundColor Green
}
finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
