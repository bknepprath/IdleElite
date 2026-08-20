$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$importCheck = Join-Path $PSScriptRoot "configure-performance-imports.ps1"
$exportedImageAudit = Join-Path $PSScriptRoot "audit-exported-image-assets.ps1"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$audioDirectorPath = Join-Path $projectRoot "scripts/audio/audio_director.gd"
$textureCachePath = Join-Path $projectRoot "scripts/core/visual_texture_cache.gd"
$navigationShellPath = Join-Path $projectRoot "scripts/ui/navigation_shell.gd"
$skillDetailSurfacePath = Join-Path $projectRoot "scripts/ui/skill_detail_surface.gd"
$skillSwipeSurfacePath = Join-Path $projectRoot "scripts/ui/skill_swipe_activity_surface.gd"
$fishingSurfacePath = Join-Path $projectRoot "scripts/fishing/ui_surface.gd"
$projectSettingsPath = Join-Path $projectRoot "project.godot"

& $importCheck -Check
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
& $exportedImageAudit -CheckSnapshot
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$projectSettings = Get-Content -Raw -LiteralPath $projectSettingsPath
if ($projectSettings -notmatch '(?m)^textures/vram_compression/import_etc2_astc=true\r?$') {
    throw "ETC2/ASTC texture import is not enabled."
}

$requiredExcludes = @(
    ".playwright-cli/*",
    "assets/content/ui/berry-mode-borders-source.png",
    "assets/content/ui/profile-avatar-game-objects-spritesheet.png",
    "assets/content/ui/profile-avatar-blue-guy-spritesheet.png",
    "assets/content/thieving/heists/thieving-trophy-heist-backgrounds-wide.png",
    "assets/music/*.wav",
    "assets/sfx-candidates/*",
    "assets/content/sfx-candidates/*",
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
$excludeLines = @(Get-Content -LiteralPath $exportPresetsPath | Where-Object { $_.StartsWith('exclude_filter="') })
if ($excludeLines.Count -eq 0) {
    throw "No export exclusion filters were found."
}
foreach ($line in $excludeLines) {
    foreach ($required in $requiredExcludes) {
        if (-not $line.Contains($required)) {
            throw "Export filter is missing required exclusion: $required"
        }
    }
}

Add-Type -AssemblyName System.Drawing
$expectedDimensions = @{
    "assets/content/ui/berry-mode-borders-1080p.png" = @(1080, 1920)
    "assets/content/thieving/heists/thieving-trophy-heist-backgrounds-1080p.png" = @(4320, 619)
    "assets/content/ui/profile-avatar-game-objects-spritesheet-1080p.png" = @(1280, 512)
    "assets/content/ui/profile-avatar-blue-guy-spritesheet-1080p.png" = @(1280, 512)
}
foreach ($entry in $expectedDimensions.GetEnumerator()) {
    $path = Join-Path $projectRoot $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Derived 1080p texture is missing: $($entry.Key)"
    }
    $image = [System.Drawing.Image]::FromFile($path)
    try {
        if ($image.Width -ne $entry.Value[0] -or $image.Height -ne $entry.Value[1]) {
            throw "Derived texture has wrong dimensions: $($entry.Key) is $($image.Width)x$($image.Height)"
        }
    } finally {
        $image.Dispose()
    }
}

$audioDirector = Get-Content -Raw -LiteralPath $audioDirectorPath
if ([regex]::Matches($audioDirector, '_ensure_extended_audio\(\)').Count -ne 1) {
    throw "Extended SFX preload was reintroduced; SFX must remain category-on-demand."
}
if ([regex]::Matches($audioDirector, '_warm_extended_audio_async\(\)').Count -ne 1) {
    throw "Extended SFX boot warmup was reintroduced."
}
if ($audioDirector -notmatch '(?s)func _build_music_players\(\).*?_dispose_music_players\(\).*?music_stream_cache\.clear\(\)') {
    throw "Inactive music streams are not released when the song set changes."
}

$textureCache = Get-Content -Raw -LiteralPath $textureCachePath
$navigationShell = Get-Content -Raw -LiteralPath $navigationShellPath
foreach ($requiredFunction in @('begin_runtime_scope', 'finish_runtime_scope', 'clear_runtime_cache')) {
    if ($textureCache -notmatch "func $requiredFunction\(") {
        throw "Scoped texture cache function is missing: $requiredFunction"
    }
}
if ($navigationShell -notmatch 'visual_texture_cache\.begin_runtime_scope\(\)' -or $navigationShell -notmatch 'visual_texture_cache\.finish_runtime_scope\(\)') {
    throw "Screen rendering is not using scoped texture cache eviction."
}
if ($navigationShell -notmatch '_free_global_swipe_real_card_cache\(\)' -or $navigationShell -notmatch '_clear_detail_lazy_cached_roots\(\)') {
    throw "Skill navigation does not release adjacent-card caches."
}

$skillDetailSurface = Get-Content -Raw -LiteralPath $skillDetailSurfacePath
$skillSwipeSurface = Get-Content -Raw -LiteralPath $skillSwipeSurfacePath
$fishingSurface = Get-Content -Raw -LiteralPath $fishingSurfacePath
foreach ($staleHostCall in @(
    'host\._consume_queued_skill_swipe_navigation\(',
    'host\._ensure_finalized_skill_detail_presentable\(',
    'host\._find_skill_preview_actions_scroll\(',
    'host\._find_skill_preview_stack\(',
    'host\._skill_detail_stack_is_presentable\(',
    'host\._fade_clear_skill_swipe_rebuild_cover\('
)) {
    if ($skillDetailSurface -match $staleHostCall) {
        throw "Skill-detail navigation still calls a swipe-surface method through the main host: $staleHostCall"
    }
}
if ($skillSwipeSurface -match 'detail_regen_circle\.sync_for_skill\(self,') {
    throw "Promoted swipe gauges are still being synchronized against the RefCounted surface instead of the game host."
}
if ($skillDetailSurface -notmatch 'const DETAIL_LAZY_WINDOW_SYNC_INTERVAL_SECONDS := 0\.25' -or
    $skillDetailSurface -notmatch 'detail_lazy_settle_warm_mount_exhausted') {
    throw "Idle lazy-card scanning or warm-mount exhaustion protection was removed."
}
if ($fishingSurface -notmatch 'func _fishing_detail_render_signature_state_key\(\) -> int:' -or
    $fishingSurface -notmatch 'fishing_detail_render_signature_cache_key' -or
    $fishingSurface -notmatch 'fishing_detail_render_signature_cache') {
    throw "Fishing detail layout signatures are not cached between static UI refreshes."
}

Write-Output "performance-resource-contracts-ok"
