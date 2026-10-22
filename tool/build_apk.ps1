# Build de l'APK release, avec la clé du tuteur injectée à la compilation.
#
# La clé n'est JAMAIS écrite dans le dépôt : elle vient de
#   - $env:TUTOR_API_KEY, ou
#   - tool/tutor.env (gitignoré), contenant TUTOR_API_KEY=sk-or-v1-...
#
# Sans clé, le build reste possible : l'application démarre en mode simulé
# (voir docs/TUTEUR_LLM.md) et le signale par un avertissement.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$key = $env:TUTOR_API_KEY
$envFile = Join-Path $PSScriptRoot 'tutor.env'
if (-not $key -and (Test-Path $envFile)) {
  Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*TUTOR_API_KEY\s*=\s*(.+)$') { $key = $Matches[1].Trim() }
  }
}

$args = @('build', 'apk', '--release', '--target-platform', 'android-arm64')
if ($key) {
  $args += "--dart-define=TUTOR_API_KEY=$key"
  Write-Output 'Clé du tuteur injectée (dart-define, jamais commitée).'
} else {
  Write-Warning 'TUTOR_API_KEY absente : build en mode simulé.'
}

& flutter @args
exit $LASTEXITCODE
