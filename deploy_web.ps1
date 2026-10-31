[CmdletBinding()]
param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = $PSScriptRoot
$appDirectory = Join-Path $repositoryRoot 'fisherman_app'
$pubspecPath = Join-Path $appDirectory 'pubspec.yaml'
$composePath = Join-Path $repositoryRoot 'docker-compose.web.yml'

foreach ($requiredPath in @($pubspecPath, $composePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required project file not found: $requiredPath"
    }
}

foreach ($toolName in @('flutter', 'docker')) {
    if (-not (Get-Command $toolName -ErrorAction SilentlyContinue)) {
        throw "Required command '$toolName' was not found in PATH."
    }
}

$pubspec = [System.IO.File]::ReadAllText($pubspecPath)
$versionPattern = '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$'
$versionMatch = [regex]::Match($pubspec, $versionPattern)
if (-not $versionMatch.Success) {
    throw "Could not parse the version/build number in $pubspecPath."
}

$appVersion = $versionMatch.Groups[1].Value
$currentBuildNumber = [int]$versionMatch.Groups[2].Value
$nextBuildNumber = $currentBuildNumber + 1
$nextVersionLine = "version: $appVersion+$nextBuildNumber"

if ($CheckOnly) {
    Write-Output "Flutter: $((Get-Command flutter).Source)"
    Write-Output "Docker: $((Get-Command docker).Source)"
    Write-Output "Current app version: $appVersion+$currentBuildNumber"
    Write-Output "Next build version: $appVersion+$nextBuildNumber"
    Write-Output "Android APK will be available at /downloads/fisherman-app.apk"
    Write-Output "Compose file: $composePath"
    exit 0
}

$updatedPubspec = [regex]::Replace(
    $pubspec,
    $versionPattern,
    [System.Text.RegularExpressions.MatchEvaluator]{
        param($match)
        $nextVersionLine
    },
    1
)
[System.IO.File]::WriteAllText(
    $pubspecPath,
    $updatedPubspec,
    [System.Text.UTF8Encoding]::new($false)
)
Write-Output "Updated app build number: $appVersion+$currentBuildNumber -> $appVersion+$nextBuildNumber"

Push-Location $appDirectory
try {
    & flutter build web --release `
        --dart-define=API_BASE_URL=https://apifisherman.berlin2026.dpdns.org `
        --dart-define=APP_VERSION=$appVersion `
        --dart-define=APP_BUILD_NUMBER=$nextBuildNumber
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter Web build failed with exit code $LASTEXITCODE."
    }

    & flutter build apk --release `
        --dart-define=API_BASE_URL=https://apifisherman.berlin2026.dpdns.org `
        --dart-define=APP_VERSION=$appVersion `
        --dart-define=APP_BUILD_NUMBER=$nextBuildNumber
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter Android APK build failed with exit code $LASTEXITCODE."
    }

    $downloadDirectory = Join-Path $appDirectory 'build\web\downloads'
    $apkPath = Join-Path $appDirectory 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
        throw "Android APK build succeeded but the APK was not found: $apkPath"
    }
    New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null
    Copy-Item -LiteralPath $apkPath `
        -Destination (Join-Path $downloadDirectory 'fisherman-app.apk') -Force
    Write-Output "Android APK staged at $downloadDirectory\fisherman-app.apk"
}
finally {
    Pop-Location
}

Push-Location $repositoryRoot
try {
    & docker compose -f $composePath up -d --build
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Web deployment failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}

Write-Output "Web deployment completed. Open https://fisherman.berlin2026.dpdns.org/"
