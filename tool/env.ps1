# environnement de developpement Relio
# A sourcer dans PowerShell avant d utiliser flutter / git / python :
#
#   . C:\Users\Docker\Desktop\relio\tool\env.ps1
#
# Ces chemins decrivent LA machine de developpement actuelle. Sur une autre
# machine, les remplacer par les emplacements reels : ce script ne detecte
# rien, il ne fait que poser des variables.

$env:FLUTTER_ROOT      = "$env:USERPROFILE\flutter"
$env:JAVA_HOME         = "$env:LOCALAPPDATA\Programs\jdk17"
$env:ANDROID_SDK_ROOT  = "$env:LOCALAPPDATA\Android\Sdk"
$env:ANDROID_HOME      = $env:ANDROID_SDK_ROOT
$env:GIT_ROOT          = "$env:LOCALAPPDATA\Programs\PortableGit"
$env:PYTHON_ROOT       = "$env:LOCALAPPDATA\Programs\Python\Python313"

$env:PATH = @(
    "$env:FLUTTER_ROOT\bin"
    "$env:GIT_ROOT\cmd"
    "$env:JAVA_HOME\bin"
    "$env:ANDROID_SDK_ROOT\platform-tools"
    "$env:PYTHON_ROOT"
    "$env:PYTHON_ROOT\Scripts"
    $env:PATH
) -join ";"

Write-Host "Relio : flutter, dart, git, java, adb et python sont sur le PATH." -ForegroundColor Green

# Avertit d'un composant absent plutot que de laisser echouer un build
# plus tard sur une cause obscure.
foreach ($outil in @(
    @{ nom = "flutter"; exe = "$env:FLUTTER_ROOT\bin\flutter.bat" }
    @{ nom = "dart";    exe = "$env:FLUTTER_ROOT\bin\dart.bat" }
    @{ nom = "git";     exe = "$env:GIT_ROOT\cmd\git.exe" }
    @{ nom = "java";    exe = "$env:JAVA_HOME\bin\java.exe" }
    @{ nom = "adb";     exe = "$env:ANDROID_SDK_ROOT\platform-tools\adb.exe" }
    @{ nom = "python";  exe = "$env:PYTHON_ROOT\python.exe" }
)) {
    if (-not (Test-Path $outil.exe)) {
        Write-Host "  MANQUANT : $($outil.nom) ($($outil.exe))" -ForegroundColor Red
    }
}