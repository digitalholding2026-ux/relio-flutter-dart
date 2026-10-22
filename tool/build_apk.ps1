# Build de l'APK release, avec la cle du tuteur injectee a la compilation.
#
# La cle n'est JAMAIS ecrite dans le depot : elle vient de
#   - $env:TUTOR_API_KEY, ou
#   - tool/tutor.env (gitignore), contenant TUTOR_API_KEY=sk-or-v1-...
#
# Sans cle, ce script ECHOUE : un APK de release sans cle ne peut pas joindre
# le modele, et l'interface affiche alors le message de repli — ce qui se
# confond avec une panne de l'IA. Pour un build de diagnostic volontairement
# muet :
#
#   .\tool\build_apk.ps1 -AllowMock
[CmdletBinding()]
param(
    [switch]$AllowMock
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$key = $env:TUTOR_API_KEY
$envFile = Join-Path $PSScriptRoot 'tutor.env'
if (-not $key -and (Test-Path $envFile)) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*TUTOR_API_KEY\s*=\s*(.+)$') { $key = $Matches[1].Trim() }
  }
}

$arguments = @('build', 'apk', '--release', '--target-platform', 'android-arm64')
if ($key) {
  $arguments += "--dart-define=TUTOR_API_KEY=$key"
  Write-Host 'Cle du tuteur injectee (dart-define, jamais committee).' -ForegroundColor Green
}
elseif ($AllowMock) {
  Write-Warning 'TUTOR_API_KEY absente : build de diagnostic en mode simule (-AllowMock).'
}
else {
  Write-Error @'
TUTOR_API_KEY absente : release refusee.

Un APK sans cle ne joint pas OpenRouter : il affiche le message du tuteur
simule, ce qui se confond avec une panne. Renseigner $env:TUTOR_API_KEY ou
tool\tutor.env, ou relancer avec -AllowMock pour un build de diagnostic.
'@
  exit 1
}

& flutter @arguments
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apk = Join-Path (Get-Location) 'build\app\outputs\flutter-apk\app-release.apk'
if (Test-Path $apk) {
  $size = [math]::Round((Get-Item $apk).Length / 1MB, 1)
  Write-Host "APK : $apk ($size Mo)" -ForegroundColor Green
}
