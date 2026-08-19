$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$presetPath = Join-Path $projectRoot "export_presets.cfg"
$requiredExcludes = @(
    "assets/content/ui/berry-mode-borders-source.png",
    "assets/content/ui/profile-avatar-game-objects-spritesheet.png",
    "assets/content/ui/profile-avatar-blue-guy-spritesheet.png",
    "assets/content/thieving/heists/thieving-trophy-heist-backgrounds-wide.png",
    "assets/sfx/action_failure.wav",
    "assets/sfx/action_success_ding.wav",
    "assets/sfx/activity_start_badge_whisk.wav",
    "assets/sfx/mastery_level_up.wav",
    "assets/sfx/sfx_pebbles_click.wav",
    "assets/sfx/sfx_small_pop.mp3",
    "assets/sfx/sfx_small_pop.wav",
    "assets/sfx/ui_single_clean_switch.wav",
    "assets/sfx/pin-candidates/pin_entry_thwick_02_dry.wav",
    "assets/sfx/pin-candidates/pin_entry_thwick_03_chunk.wav",
    "assets/sfx/pin-candidates/pin_entry_thwick_04_bright.wav",
    "assets/sfx/pin-candidates/pin_entry_thwick_05_soft_card.wav",
    "assets/sfx/pin-candidates/pin_exit_pull_01_tiny.wav",
    "assets/sfx/pin-candidates/pin_exit_pull_02_dry.wav",
    "assets/sfx/pin-candidates/pin_exit_pull_03_soft_pop.wav",
    "assets/sfx/pin-candidates/pin_exit_pull_05_felt.wav"
)

$lines = Get-Content -LiteralPath $presetPath
$updatedCount = 0
for ($index = 0; $index -lt $lines.Count; $index++) {
    if (-not $lines[$index].StartsWith('exclude_filter="')) {
        continue
    }
    $value = $lines[$index].Substring('exclude_filter="'.Length)
    if (-not $value.EndsWith('"')) {
        throw "Malformed exclude_filter at line $($index + 1)."
    }
    $items = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $value.Substring(0, $value.Length - 1).Split(',')) {
        if (-not [string]::IsNullOrWhiteSpace($item) -and -not $items.Contains($item)) {
            $items.Add($item)
        }
    }
    foreach ($required in $requiredExcludes) {
        if (-not $items.Contains($required)) {
            $items.Add($required)
        }
    }
    $lines[$index] = 'exclude_filter="' + ($items -join ',') + '"'
    $updatedCount++
}

if ($updatedCount -eq 0) {
    throw "No export exclude filters were found."
}

Set-Content -LiteralPath $presetPath -Value $lines -Encoding UTF8
Write-Output "Updated $updatedCount export exclude filter(s)."
