$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $projectRoot "scripts\main.gd"
$boundaryMapPath = Join-Path $projectRoot "docs\ui-runtime-boundary-map.md"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-FunctionExists {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Boundary
    )

    Assert-True ($Text -match "(?m)^func $([regex]::Escape($Name))\b") "Missing $Boundary UI boundary function: $Name"
}

Assert-True (Test-Path -LiteralPath $mainPath) "Missing scripts\main.gd"
Assert-True (Test-Path -LiteralPath $boundaryMapPath) "Missing docs\ui-runtime-boundary-map.md"

$main = Get-Content -LiteralPath $mainPath -Raw
$boundaryMap = Get-Content -LiteralPath $boundaryMapPath -Raw

$boundaries = @{
    "home/navigation" = @("_build_home_page", "_build_nav_bar", "_nav_button", "_apply_nav_style", "_show_skills", "_show_shop")
    "shop/ads" = @("_shop_unlocked", "_shop_ad_offer_button", "_shop_ad_pressed")
    "chat transport" = @("_chat_stream_connect", "_chat_send", "_chat_apply_stream_payload", "_chat_sort_and_trim_rows")
    "chat presentation" = @("_build_chat_strip", "_build_chat_overlay", "_chat_strip_visible_on_current_screen", "_chat_row", "_chat_composer")
    "leaderboard networking/data" = @("_leaderboard_fetch_category", "_leaderboard_submit_scores", "_leaderboard_categories", "_leaderboard_score_for_category")
    "leaderboard page" = @("_render_leaderboard_page", "_leaderboard_page_frame", "_leaderboard_player_card", "_leaderboard_row")
    "profile/avatar" = @("_build_profile_overlay", "_profile_avatar_picker_button", "_profile_avatar_texture", "_profile_avatar_frame")
}

foreach ($boundary in ($boundaries.Keys | Sort-Object)) {
    foreach ($functionName in $boundaries[$boundary]) {
        Assert-FunctionExists $main $functionName $boundary
        Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "UI boundary map must mention $functionName."
    }
}

Assert-True ($boundaryMap -match 'current_screen') "UI boundary map should call out top-level screen routing risk."
Assert-True ($boundaryMap -match 'Firebase') "UI boundary map should call out Firebase coupling for chat and leaderboard."
Assert-True ($boundaryMap -match 'saved avatar/profile keys') "UI boundary map should call out profile save compatibility."

Write-Output "ui-boundary-contracts-ok"
