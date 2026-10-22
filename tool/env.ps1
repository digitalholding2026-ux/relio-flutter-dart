# environnement de developpement Relio
# A sourcer dans PowerShell avant d utiliser flutter / git / python :
#
#   . C:\Users\Docker\Desktop\Relio\tool\env.ps1
#
# Ces chemins decrivent LA machine de developpement actuelle. Sur une autre
# machine, les remplacer par les emplacements reels : ce script ne detecte
# rien, il ne fait que poser des variables.

$env:FLUTTER_ROOT      = "C:\tools\flutter"
$env:JAVA_HOME         = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot"
$env:ANDROID_SDK_ROOT  = "C:\Android\sdk"
$env:ANDROID_HOME      = $env:ANDROID_SDK_ROOT
$env:GIT_ROOT          = "C:\tools\PortableGit"
$env:GH_ROOT           = "C:\tools\gh"
$env:PYTHON_ROOT       = "$env:LOCALAPPDATA\Programs\Python\Python313"

$env:PATH = @(
    "$env:FLUTTER_ROOT\bin"
    "$env:GIT_ROOT\cmd"
    "$env:GH_ROOT"
    "$env:JAVA_HOME\bin"
    "$env:ANDROID_SDK_ROOT\platform-tools"
    "$env:ANDROID_SDK_ROOT\cmdline-tools\latest\bin"
    "$env:PYTHON_ROOT"
    "$env:PYTHON_ROOT\Scripts"
    $env:PATH
) -join ";"

Write-Host "Relio : flutter, dart, git, gh, java et adb sont sur le PATH." -ForegroundColor Green

# Avertit d'un composant absent plutot que de laisser echouer un build
# plus tard sur une cause obscure.
foreach ($outil in @(
    @{ nom = "flutter"; exe = "$env:FLUTTER_ROOT\bin\flutter.bat" }
    @{ nom = "dart";    exe = "$env:FLUTTER_ROOT\bin\dart.bat" }
    @{ nom = "git";     exe = "$env:GIT_ROOT\cmd\git.exe" }
    @{ nom = "gh";      exe = "$env:GH_ROOT\gh.exe" }
    @{ nom = "java";    exe = "$env:JAVA_HOME\bin\java.exe" }
    @{ nom = "adb";     exe = "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe" }
)) {
    if (-not (Test-Path $outil.exe)) {
        Write-Host "  MANQUANT : $($outil.nom) ($($outil.exe))" -ForegroundColor Red
    }
}

# Le tuteur a besoin d'une cle au moment du build (voir docs/TUTEUR_LLM.md).
# Sans elle, tool\build_apk.ps1 refuse de produire une release : un APK muet
# passerait pour une panne de l'IA.
$tutorEnv = Join-Path $PSScriptRoot 'tutor.env'
if (-not $env:TUTOR_API_KEY -and -not (Test-Path $tutorEnv)) {
    Write-Host "  TUTEUR : aucune cle (ni TUTOR_API_KEY, ni tool\tutor.env) — build de release impossible." -ForegroundColor Yellow
}
