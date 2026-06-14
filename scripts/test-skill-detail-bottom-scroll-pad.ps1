$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$mainScript = Join-Path $projectRoot "scripts\main.gd"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Read-ConstNumber {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $pattern = "(?m)^const $([regex]::Escape($Name)) := ([0-9]+(?:\.[0-9]+)?)$"
    $match = [regex]::Match($Source, $pattern)
    Assert-True $match.Success "Missing $Name constant."
    [double]$match.Groups[1].Value
}

Assert-True (Test-Path -LiteralPath $mainScript) "Missing scripts\main.gd."

$source = Get-Content -LiteralPath $mainScript -Raw
$standardPad = Read-ConstNumber -Source $source -Name "SKILL_DETAIL_BOTTOM_SCROLL_PAD"
$thievingPad = Read-ConstNumber -Source $source -Name "THIEVING_SKILL_DETAIL_BOTTOM_SCROLL_PAD"

Assert-True ($standardPad -ge 24 -and $standardPad -le 64) "Skill detail bottom scroll pad should stay small enough to avoid blank space; got $standardPad."
Assert-True ($thievingPad -ge 24 -and $thievingPad -le 64) "Thieving detail bottom scroll pad should stay small enough to avoid blank space; got $thievingPad."

Write-Output "skill-detail-bottom-scroll-pad-ok standard=$standardPad thieving=$thievingPad"
