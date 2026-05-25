param(
    [Parameter(Mandatory = $true)]
    [string] $AdMobAppId,

    [Parameter(Mandatory = $true)]
    [string] $RewardedUnitId
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot "addons\admob\android\config.gd"
$mainPath = Join-Path $projectRoot "scripts\main.gd"

if ($AdMobAppId -notmatch '^ca-app-pub-\d+~\d+$') {
    throw "AdMobAppId must look like ca-app-pub-0000000000000000~0000000000"
}

if ($RewardedUnitId -notmatch '^ca-app-pub-\d+/\d+$') {
    throw "RewardedUnitId must look like ca-app-pub-0000000000000000/0000000000"
}

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Could not find $configPath"
}

if (-not (Test-Path -LiteralPath $mainPath)) {
    throw "Could not find $mainPath"
}

$configText = Get-Content -LiteralPath $configPath -Raw
if ($configText -notmatch 'const APPLICATION_ID := "ca-app-pub-\d+~\d+"') {
    throw "Could not find Android APPLICATION_ID constant in $configPath"
}
$configText = [regex]::Replace(
    $configText,
    'const APPLICATION_ID := "ca-app-pub-\d+~\d+"',
    "const APPLICATION_ID := `"$AdMobAppId`"",
    1
)
Set-Content -LiteralPath $configPath -Value $configText -NoNewline

$mainText = Get-Content -LiteralPath $mainPath -Raw
if ($mainText -notmatch 'const AD_LIVE_UNIT_ANDROID_REWARDED := "[^"]*"') {
    throw "Could not find AD_LIVE_UNIT_ANDROID_REWARDED constant in $mainPath"
}
$mainText = [regex]::Replace(
    $mainText,
    'const AD_LIVE_UNIT_ANDROID_REWARDED := "[^"]*"',
    "const AD_LIVE_UNIT_ANDROID_REWARDED := `"$RewardedUnitId`"",
    1
)
Set-Content -LiteralPath $mainPath -Value $mainText -NoNewline

Write-Output "Updated Android AdMob app ID in $configPath"
Write-Output "Updated Android rewarded ad unit ID in $mainPath"
Write-Output "Next: run .\scripts\check-project.ps1, then .\scripts\build-android-release.ps1"
