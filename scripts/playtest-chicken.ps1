[CmdletBinding()]
param(
    [string]$ActionId = "fight-chickens",
    [string]$OpponentLabel = "CHICKEN",
    [int]$UnlockLevel = 5,
    [ValidateSet("Unlock", "MediumHigh", "High")]
    [string]$Preset = "Unlock",
    [ValidateSet("Opening", "SpawnWindowEnd", "PostEndRestart", "Windup", "Strike", "AttackFrame3", "RouseRollSequence", "Damaged", "WerewolfTransform", "WerewolfScratch", "WaveReady", "GoblinHit", "Defeated", "DeathAirborne", "DeathBounce", "DeathRest", "DeathFade", "DeathComparison", "DeathAngles", "VariantAttacks", "VariantStates", "Crowd", "ShieldDropRest", "PunchStack", "GuysFlee", "GiantWalk", "GiantPair", "GiantToss", "GiantStomp", "GiantBoulder", "GiantBoulderBreak", "GiantBoulderDrop", "GiantProgression", "GiantLayer", "CaveTrollPound", "DragonMeleeAim", "DragonBoundary", "DragonBreath", "DragonPounce", "VampireSpecials", "VampireGiant", "LowHP", "HeroGuard", "HeroPunch", "HeroUppercut", "KO", "KORetreat", "KOSequence", "MegaCrit")]
    [string]$CaptureState = "Windup",
    [string]$CapturePath = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$middleLevel = if ($UnlockLevel + 25 -lt 99) { $UnlockLevel + 25 } else { [int][Math]::Ceiling(($UnlockLevel + 99) / 2.0) }
$levels = @{ Unlock = $UnlockLevel; MediumHigh = $middleLevel; High = 99 }
$testUserDataDir = Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-chicken-playtest-" + [guid]::NewGuid().ToString("N"))
$previousUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$previousLevel = $env:IDLE_ELITE_CHICKEN_PLAYTEST_LEVEL
$previousCapturePath = $env:IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_PATH
$previousCaptureState = $env:IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_STATE
$previousActionId = $env:IDLE_ELITE_FIGHT_PLAYTEST_ACTION_ID
$previousOpponentLabel = $env:IDLE_ELITE_FIGHT_PLAYTEST_LABEL
$previousUnlockLevel = $env:IDLE_ELITE_FIGHT_PLAYTEST_UNLOCK_LEVEL

if (-not (Test-Path -LiteralPath $runner)) {
    throw "Godot runner was not found at $runner"
}

try {
    New-Item -ItemType Directory -Path $testUserDataDir | Out-Null
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserDataDir
    $env:IDLE_ELITE_CHICKEN_PLAYTEST_LEVEL = [string]$levels[$Preset]
    $env:IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_PATH = $CapturePath
    $env:IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_STATE = $CaptureState
    $env:IDLE_ELITE_FIGHT_PLAYTEST_ACTION_ID = $ActionId
    $env:IDLE_ELITE_FIGHT_PLAYTEST_LABEL = $OpponentLabel
    $env:IDLE_ELITE_FIGHT_PLAYTEST_UNLOCK_LEVEL = [string]$UnlockLevel

    $runnerArgs = @("--visible-game", "--path", $projectRoot, "--script", "res://scripts/dev/chicken_playtest.gd")
    if (-not [string]::IsNullOrWhiteSpace($CapturePath)) {
        $captureParent = Split-Path -Parent $CapturePath
        if (-not [string]::IsNullOrWhiteSpace($captureParent)) {
            New-Item -ItemType Directory -Path $captureParent -Force | Out-Null
        }
    }

    & $runner @runnerArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
finally {
    if ($null -eq $previousUserDataDir) { Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousUserDataDir }
    if ($null -eq $previousLevel) { Remove-Item Env:\IDLE_ELITE_CHICKEN_PLAYTEST_LEVEL -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_CHICKEN_PLAYTEST_LEVEL = $previousLevel }
    if ($null -eq $previousCapturePath) { Remove-Item Env:\IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_PATH = $previousCapturePath }
    if ($null -eq $previousCaptureState) { Remove-Item Env:\IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_STATE -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_CHICKEN_PLAYTEST_CAPTURE_STATE = $previousCaptureState }
    if ($null -eq $previousActionId) { Remove-Item Env:\IDLE_ELITE_FIGHT_PLAYTEST_ACTION_ID -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_FIGHT_PLAYTEST_ACTION_ID = $previousActionId }
    if ($null -eq $previousOpponentLabel) { Remove-Item Env:\IDLE_ELITE_FIGHT_PLAYTEST_LABEL -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_FIGHT_PLAYTEST_LABEL = $previousOpponentLabel }
    if ($null -eq $previousUnlockLevel) { Remove-Item Env:\IDLE_ELITE_FIGHT_PLAYTEST_UNLOCK_LEVEL -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_FIGHT_PLAYTEST_UNLOCK_LEVEL = $previousUnlockLevel }
    if (Test-Path -LiteralPath $testUserDataDir) {
        Remove-Item -LiteralPath $testUserDataDir -Recurse -Force
    }
}
