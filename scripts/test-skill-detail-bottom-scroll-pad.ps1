$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$mainScript = Join-Path $projectRoot "scripts\main.gd"
$skillDetailScript = Join-Path $projectRoot "scripts\ui\skill_detail_surface.gd"

function Read-ConstNumber {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $pattern = "(?m)^const $([regex]::Escape($Name)) := ([0-9]+(?:\.[0-9]+)?)\r?$"
    $match = [regex]::Match($Source, $pattern)
    Assert-True $match.Success "Missing $Name constant."
    [double]$match.Groups[1].Value
}

Assert-True (Test-Path -LiteralPath $mainScript) "Missing scripts\main.gd."
Assert-True (Test-Path -LiteralPath $skillDetailScript) "Missing scripts\ui\skill_detail_surface.gd."

$source = Get-Content -LiteralPath $mainScript -Raw
$skillDetailSource = Get-Content -LiteralPath $skillDetailScript -Raw
$standardPad = Read-ConstNumber -Source $source -Name "SKILL_DETAIL_BOTTOM_SCROLL_PAD"
$thievingPad = Read-ConstNumber -Source $source -Name "THIEVING_SKILL_DETAIL_BOTTOM_SCROLL_PAD"

Assert-True ($standardPad -ge 24 -and $standardPad -le 64) "Skill detail bottom scroll pad should stay small enough to avoid blank space; got $standardPad."
Assert-True ($thievingPad -ge 24 -and $thievingPad -le 64) "Thieving detail bottom scroll pad should stay small enough to avoid blank space; got $thievingPad."

$scrollTargetMatch = [regex]::Match($skillDetailSource, '(?s)func _detail_actions_scroll_target_for_card\(card: Control, centered := false\) -> int:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True $scrollTargetMatch.Success "Missing skill detail action-card scroll target helper."
$scrollTargetBody = $scrollTargetMatch.Groups[1].Value
Assert-True ($scrollTargetBody -match '_detail_actions_scroll_viewport_height\(\)') "Centered skill detail scroll targets must use the visible viewport height above chat/nav."
Assert-True ($scrollTargetBody -match '_sync_detail_actions_scroll_limit\(\)') "Skill detail scroll targets must sync the live content limit before clamping."
Assert-True ($scrollTargetBody -match 'clampi\(int\(round\(target_y\)\), 0, detail_actions_scroll\.get_max_scroll_vertical\(\)\)') "Skill detail scroll targets must clamp to the current max scroll."

Write-Output "skill-detail-bottom-scroll-pad-ok standard=$standardPad thieving=$thievingPad"
