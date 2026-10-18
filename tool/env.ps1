# environnement de developpement Relio
# A sourcer dans PowerShell avant d utiliser flutter / git :
#
#   . C:\Users\Docker\Desktop\Relio\tool\env.ps1

$env:JAVA_HOME    = "$env:USERPROFILE\jdk\jdk-17.0.20.1+1"
$env:ANDROID_SDK_ROOT = "$env:USERPROFILE\android-sdk"
$env:ANDROID_HOME  = $env:ANDROID_SDK_ROOT

$env:PATH = @(
    "$env:USERPROFILE\flutter\bin"
    "$env:USERPROFILE\git-portable\cmd"
    "$env:JAVA_HOME\bin"
    "$env:ANDROID_SDK_ROOT\platform-tools"
    $env:PATH
) -join ";"

Write-Host "Relio : flutter, dart, git, java et adb sont sur le PATH." -ForegroundColor Green