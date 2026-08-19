param(
    [string]$ActionId = "fight-chickens",
    [int]$FightLevel = 99,
    [ValidateSet("auto", "close-brawl", "directional-breath", "guys-guard-hit", "rouses-crash", "werewolf-transform", "werewolves-wall-miss", "cave-troll-slam", "giant-flip-denial", "vampire-flank-cross", "area-clear-xp")]
    [string]$CaptureCue = "auto",
    [int]$ViewportWidth = 1080,
    [int]$ViewportHeight = 1920,
    [int]$WindowWidth = 1080,
    [int]$WindowHeight = 1920,
    [string]$CaptureLabel = "",
    [string]$ValidatePath = "",
    [switch]$StatsTucked,
    [switch]$Inactive
)

$ErrorActionPreference = "Stop"

function Test-CaptureCompleteness {
    param([string]$Path)

    Add-Type -AssemblyName System.Drawing
    $bitmap = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $Path).Path)
    try {
        if ($bitmap.Width -ne 1080 -or $bitmap.Height -ne 1920) {
            throw "Capture dimensions are $($bitmap.Width)x$($bitmap.Height), expected 1080x1920."
        }
        $regions = @(
            @{ Name = "header"; X = 70; Y = 110; Width = 940; Height = 270 },
            @{ Name = "task-card"; X = 70; Y = 408; Width = 940; Height = 360 },
            @{ Name = "diamond"; X = 85; Y = 780; Width = 910; Height = 590 },
            @{ Name = "footer"; X = 70; Y = 1390; Width = 940; Height = 500 },
            @{ Name = "whole-frame"; X = 0; Y = 0; Width = 1080; Height = 1920 }
        )
        foreach ($region in $regions) {
            foreach ($axis in @("row", "column")) {
                $outer = if ($axis -eq "row") { $region.Height } else { $region.Width }
                $inner = if ($axis -eq "row") { $region.Width } else { $region.Height }
                $run = 0
                for ($offset = 0; $offset -lt $outer; $offset++) {
                    $nearWhite = 0
                    $nearBlack = 0
                    for ($innerOffset = 0; $innerOffset -lt $inner; $innerOffset++) {
                        $x = if ($axis -eq "row") { $region.X + $innerOffset } else { $region.X + $offset }
                        $y = if ($axis -eq "row") { $region.Y + $offset } else { $region.Y + $innerOffset }
                        $pixel = $bitmap.GetPixel($x, $y)
                        if ($pixel.A -lt 255) { throw "Capture has transparency at $x,$y." }
                        if ($pixel.R -ge 248 -and $pixel.G -ge 248 -and $pixel.B -ge 248) { $nearWhite++ }
                        if ($pixel.R -le 16 -and $pixel.G -le 16 -and $pixel.B -le 16) { $nearBlack++ }
                    }
                    if ($nearWhite / [double]$inner -ge 0.985 -or $nearBlack / [double]$inner -ge 0.985) {
                        $run++
                        if ($run -ge 48) {
                            throw "Capture has a large near-white/solid band in $($region.Name) ($axis)."
                        }
                    } else {
                        $run = 0
                    }
                }
            }
        }
        $requiredContentRegions = @(
            @{ Name = "arena-focus-content"; X = 70; Y = 408; Width = 940; Height = 690 },
            @{ Name = "diamond-content"; X = 85; Y = 430; Width = 910; Height = 650 }
        )
        $captureFileName = [IO.Path]::GetFileName($Path)
        if ($captureFileName -notlike "*vampire-flank-cross*" -and $captureFileName -notlike "*cave-troll-slam*") {
            $requiredContentRegions += @{ Name = "controls-content"; X = 70; Y = 1000; Width = 940; Height = 500 }
        }
        foreach ($region in $requiredContentRegions) {
            $paper = 0
            $samples = 0
            for ($y = $region.Y; $y -lt $region.Y + $region.Height; $y += 4) {
                for ($x = $region.X; $x -lt $region.X + $region.Width; $x += 4) {
                    $pixel = $bitmap.GetPixel($x, $y)
                    $samples++
                    if ([Math]::Abs($pixel.R - 248) -le 3 -and [Math]::Abs($pixel.G - 241) -le 3 -and [Math]::Abs($pixel.B - 229) -le 3) { $paper++ }
                }
            }
            if ($paper / [double]$samples -ge 0.72) {
                throw "Capture is missing visible $($region.Name) content."
            }
        }
        foreach ($anchor in @(
            @{ Name = "fighting-icon"; X = 80; Y = 145; Width = 205; Height = 205; Background = @(241, 231, 215); MinUseful = 0.20; MaxBlack = 0.55; MinInk = 0.02 },
            @{ Name = "fighting-title"; X = 305; Y = 130; Width = 390; Height = 215; Background = @(241, 231, 215); MinUseful = 0.08; MaxBlack = 0.55; MinInk = 0.02 },
            @{ Name = "fighting-orb"; X = 730; Y = 95; Width = 280; Height = 285; Background = @(241, 231, 215); MinUseful = 0.20; MaxBlack = 0.55; MinInk = 0.02 },
            @{ Name = "diamond-complete"; X = 85; Y = 445; Width = 910; Height = 540; Background = @(248, 241, 229); MinUseful = 0.30; MaxBlack = 0.12; MinInk = 0.02 },
            @{ Name = "carousel-left"; X = 130; Y = 1380; Width = 390; Height = 180; Background = @(248, 241, 229); MinUseful = 0.25; MaxBlack = 0.25; MinInk = 0.02 },
            @{ Name = "carousel-right"; X = 560; Y = 1380; Width = 390; Height = 180; Background = @(248, 241, 229); MinUseful = 0.25; MaxBlack = 0.25; MinInk = 0.02 },
            @{ Name = "control-1"; X = 145; Y = 1395; Width = 150; Height = 170; Background = @(248, 241, 229); MinUseful = 0.20; MaxBlack = 0.55; MinInk = 0.02 },
            @{ Name = "control-2"; X = 360; Y = 1395; Width = 150; Height = 170; Background = @(248, 241, 229); MinUseful = 0.20; MaxBlack = 0.55; MinInk = 0.02 },
            @{ Name = "control-3"; X = 575; Y = 1395; Width = 150; Height = 170; Background = @(248, 241, 229); MinUseful = 0.20; MaxBlack = 0.55; MinInk = 0.02 },
            @{ Name = "control-4"; X = 785; Y = 1395; Width = 150; Height = 170; Background = @(248, 241, 229); MinUseful = 0.20; MaxBlack = 0.55; MinInk = 0.02 },
            @{ Name = "chat-bar"; X = 0; Y = 1580; Width = 1080; Height = 140; Background = @(185, 185, 185); MinUseful = 0.08; MaxBlack = 0.35; MinInk = 0.02 },
            @{ Name = "bottom-nav"; X = 0; Y = 1720; Width = 1080; Height = 200; Background = @(68, 74, 91); MinUseful = 0.08; MaxBlack = 0.35; MinInk = 0.02 }
        )) {
            $useful = 0
            $black = 0
            $ink = 0
            $samples = 0
            for ($y = $anchor.Y; $y -lt $anchor.Y + $anchor.Height; $y += 4) {
                for ($x = $anchor.X; $x -lt $anchor.X + $anchor.Width; $x += 4) {
                    $pixel = $bitmap.GetPixel($x, $y)
                    $samples++
                    $distance = [Math]::Max([Math]::Abs($pixel.R - $anchor.Background[0]), [Math]::Max([Math]::Abs($pixel.G - $anchor.Background[1]), [Math]::Abs($pixel.B - $anchor.Background[2])))
                    if ($distance -ge 12) { $useful++ }
                    if ($pixel.R -le 16 -and $pixel.G -le 16 -and $pixel.B -le 16) { $black++ }
                    if (($pixel.R -le 90 -and $pixel.G -le 90 -and $pixel.B -le 90) -or ([Math]::Max($pixel.R, [Math]::Max($pixel.G, $pixel.B)) - [Math]::Min($pixel.R, [Math]::Min($pixel.G, $pixel.B)) -ge 35)) { $ink++ }
                }
            }
            if ($useful / [double]$samples -lt $anchor.MinUseful -or $black / [double]$samples -gt $anchor.MaxBlack -or $ink / [double]$samples -lt $anchor.MinInk) {
                throw "Capture is missing complete $($anchor.Name) content (useful=$([Math]::Round(100 * $useful / $samples, 1))%, black=$([Math]::Round(100 * $black / $samples, 1))%, ink=$([Math]::Round(100 * $ink / $samples, 1))%)."
            }
        }
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
        if ($hash -eq "8A735ECBB03D4900CBB963AF18BD4B21E02F9200DBEE2BE28CB1009216A39E73") {
            throw "Known rejected level-32 Guys unlock proof is not eligible for acceptance."
        }
        Write-Output "Capture completeness: $Path dimensions=$($bitmap.Width)x$($bitmap.Height) bytes=$((Get-Item -LiteralPath $Path).Length) sha256=$hash"
    } finally {
        $bitmap.Dispose()
    }
}

if (-not [string]::IsNullOrWhiteSpace($ValidatePath)) {
    Test-CaptureCompleteness $ValidatePath
    exit 0
}

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$captureDir = Join-Path $projectRoot ".codex-tmp\fighting-diamond-real"
$captureState = if ($Inactive) { "inactive" } else { "active" }
$captureSlug = $ActionId -replace '[^a-zA-Z0-9]+', '-'
$captureNameCue = if ($CaptureCue -eq "close-brawl") { "close-brawl-strike" } elseif ($CaptureCue -eq "directional-breath") { "breath-strike" } else { $CaptureCue }
$captureSuffix = if ([string]::IsNullOrWhiteSpace($CaptureLabel)) { "" } else { "-$CaptureLabel" }
$capturePath = Join-Path $captureDir "$captureSlug-lv$FightLevel-$captureNameCue-real-card-$captureState$captureSuffix-${ViewportWidth}x${ViewportHeight}.png"
$captureTempPath = Join-Path $captureDir "$captureSlug-lv$FightLevel-$captureNameCue-real-card-$captureState$captureSuffix-${ViewportWidth}x${ViewportHeight}.tmp.png"
$captureLogPath = Join-Path $captureDir "$captureSlug-lv$FightLevel-$captureNameCue-real-card-$captureState$captureSuffix-${ViewportWidth}x${ViewportHeight}.natural.log"
$scriptPath = Join-Path $captureDir "capture_fighting_diamond_arena.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $captureTempPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $captureLogPath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_PATH
$previousCaptureTempPath = $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_TEMP_PATH
$previousCaptureLogPath = $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_LOG_PATH
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)

try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_PATH = $capturePath
    $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_TEMP_PATH = $captureTempPath
    $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_LOG_PATH = $captureLogPath
    $statsTuckedLiteral = if ($StatsTucked) { "true" } else { "false" }
    $activeLiteral = if ($Inactive) { "false" } else { "true" }
    $actionIdLiteral = $ActionId.Replace('"', '')
    $captureCueLiteral = $CaptureCue.Replace('"', '')
    @"
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var window_size := Vector2i($ViewportWidth, $ViewportHeight)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = window_size
	root.size = window_size
	DisplayServer.window_set_size(window_size)
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		_fail("main scene did not become capture-ready")
		return
	_hide_capture_overlays(scene)
	_unlock_for_capture(scene)
	for _frame in range(120):
		_hide_capture_overlays(scene)
		await process_frame
	var action := scene.call("_action_data", "fight", "$actionIdLiteral") as Dictionary
	if action.is_empty():
		_fail("diamond arena action missing")
		return
	var expected_enemy_id := str((action.get("combat", {}) as Dictionary).get("enemy_id", ""))
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fight")
	scene.set("running_skill_id", "fight" if $activeLiteral else "")
	scene.set("running_action_id", "$actionIdLiteral" if $activeLiteral else "")
	scene.set("action_progress", 0.38 if $activeLiteral else 0.0)
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _frame in range(12):
		await process_frame
	var detail_surface: Object = scene.call("_skill_detail_surface")
	detail_surface.call("_ensure_detail_lazy_entry_mounted", "$actionIdLiteral")
	var center_card := "$captureCueLiteral" not in ["rouses-crash", "cave-troll-slam", "giant-flip-denial", "vampire-flank-cross", "area-clear-xp"]
	await detail_surface.call("_scroll_to_activity_card", "$actionIdLiteral", false, center_card)
	for _frame in range(18):
		await process_frame
	for _frame in range(12):
		await process_frame
	var combat_stage := _find_production_diamond_stage(scene, expected_enemy_id)
	if combat_stage == null:
		_fail("production diamond stage was not found")
		return
	_hide_capture_tier_banners(scene.get("detail_actions_scroll") as Node)
	for _frame in range(18):
		await process_frame
	combat_stage = _find_production_diamond_stage(scene, expected_enemy_id)
	if combat_stage == null:
		_fail("production diamond stage disappeared after capture framing cleanup")
		return
	var capture_scroll := scene.get("detail_actions_scroll") as ScrollContainer
	var original_capture_scroll := capture_scroll.scroll_vertical if capture_scroll != null else -1
	if capture_scroll != null:
		var layout_delta := -70 if expected_enemy_id not in ["rouses", "cave-trolls", "giants", "vampires"] else 0
		capture_scroll.scroll_vertical = maxi(0, capture_scroll.scroll_vertical + layout_delta)
		capture_scroll.set("drag_scroll_position", float(capture_scroll.scroll_vertical))
	print("production-diamond-stage action=$actionIdLiteral enemy=%s rect=%s" % [str(combat_stage.get("enemy_id")), combat_stage.get_global_rect()])
	combat_stage.call("setup_fighting_level", $FightLevel)
	combat_stage.call("set_active_fight", $activeLiteral)
	if ((expected_enemy_id == "guys" and "$captureCueLiteral" == "guys-guard-hit") or (expected_enemy_id == "werewolves" and "$captureCueLiteral" == "werewolf-transform")) and ${activeLiteral}:
		combat_stage.call("set_active_fight", false)
		combat_stage.call("set_active_fight", true)
		for raw_label in combat_stage.get("float_labels") as Array:
			(raw_label as Label).visible = false
	var found_natural_goblin_break := false
	var found_natural_guys_guard_hit := false
	var found_natural_identity_cue := false
	var found_natural_giant_denial := false
	var found_natural_area_clear_xp := false
	var strict_natural_vampire := "$captureCueLiteral" == "vampire-flank-cross" and expected_enemy_id == "vampires"
	var strict_natural_cave_troll := "$captureCueLiteral" == "cave-troll-slam" and expected_enemy_id == "cave-trolls"
	var strict_natural_giant := "$captureCueLiteral" == "giant-flip-denial" and expected_enemy_id == "giants"
	var strict_natural_area_clear := "$captureCueLiteral" == "area-clear-xp" and expected_enemy_id == "giants"
	var expected_area_clear_xp := int(action.get("xp", 0)) - int(floor(float((action.get("combat", {}) as Dictionary).get("reward_xp", 0.0)) * float((action.get("combat", {}) as Dictionary).get("kill_reward_share", 0.0))))
	_log_capture("natural-area-clear-start action=%s enemy=%s reward_xp=%d kill_budget=%d planned=%d" % ["$actionIdLiteral", expected_enemy_id, int(action.get("xp", 0)), int(combat_stage.call("kill_xp_budget")), int(combat_stage.get("planned_kill_count"))])
	var observation_frames := 12000 if "$captureCueLiteral" == "area-clear-xp" else 1800
	for _frame in range(observation_frames):
		if not strict_natural_vampire and not strict_natural_cave_troll and not strict_natural_giant and not strict_natural_area_clear:
			_force_diamond_stage_state(combat_stage, $activeLiteral, $statsTuckedLiteral)
		if expected_enemy_id == "dragons" and "$captureCueLiteral" == "directional-breath":
			combat_stage.set("hero_attack_cd", 999.0)
		if expected_enemy_id == "guys" and "$captureCueLiteral" == "guys-guard-hit":
			combat_stage.set("hero_attack_cd", 0.0)
		_hide_capture_overlays(scene)
		await process_frame
		if strict_natural_area_clear and _frame % 300 == 0:
			_log_capture("natural-area-clear-progress frame=%d timer=%.3f wave=%d end_wave=%s living=%d kill_count=%d kill_xp=%d" % [_frame, float(combat_stage.get("area_clear_restart_timer")), int(combat_stage.get("wave_index")), str(combat_stage.get("end_wave_active")), int(combat_stage.call("_living_chicken_count")), int(combat_stage.get("kill_count_awarded")), int(combat_stage.get("kill_xp_already_awarded"))])
		if ${activeLiteral}:
			if expected_enemy_id == "rouses" and "$captureCueLiteral" == "rouses-crash":
				for raw_actor in combat_stage.get("chickens") as Array:
					var observed_rouses := raw_actor as Dictionary
					if float(observed_rouses.get("stagger_timer", 0.0)) > 0.0:
						_log_capture("natural-rouses-crash-observed frame=%d phase=%s stagger_timer=%.3f attack_damage_done=%s pos=%s hero=%s" % [_frame, str(observed_rouses.get("attack_phase", "")), float(observed_rouses.get("stagger_timer", 0.0)), str(observed_rouses.get("attack_damage_done", false)), str(observed_rouses.get("pos", Vector2.ZERO)), str(combat_stage.get("hero_pos"))])
			if expected_enemy_id == "goblins":
				if _has_natural_goblin_shield_break(combat_stage):
					found_natural_goblin_break = true
					print("natural-goblin-shield-break frame=%s" % str(_frame))
					break
			elif expected_enemy_id == "guys" and "$captureCueLiteral" == "guys-guard-hit":
				if _has_natural_guys_guard_hit(combat_stage):
					found_natural_guys_guard_hit = true
					for raw_actor in combat_stage.get("chickens") as Array:
						var natural_actor := raw_actor as Dictionary
						if bool(natural_actor.get("guarding", false)):
							_log_capture("natural-guys-guard-hit frame=%d phase=%s guarding=%s hit_flash=%.3f hero_attack_timer=%.3f actor_pos=%s hero=%s" % [_frame, str(natural_actor.get("attack_phase", "")), str(natural_actor.get("guarding", false)), float(natural_actor.get("hit_flash", 0.0)), float(combat_stage.get("hero_attack_timer")), str(natural_actor.get("pos", Vector2.ZERO)), str(combat_stage.get("hero_pos"))])
					break
			elif expected_enemy_id == "werewolves" and "$captureCueLiteral" == "werewolf-transform":
				for raw_actor in combat_stage.get("chickens") as Array:
					var natural_actor := raw_actor as Dictionary
					var transform_timer := float(natural_actor.get("transform_timer", 0.0))
					if transform_timer > 0.56 and transform_timer < 0.64:
						found_natural_identity_cue = true
						_log_capture("natural-werewolf-transform frame=%d transform_timer=%.3f pos=%s" % [_frame, transform_timer, str(natural_actor.get("pos", Vector2.ZERO))])
						break
				if found_natural_identity_cue:
					break
			elif strict_natural_cave_troll and _has_decisive_signature(combat_stage, "$captureCueLiteral"):
				found_natural_identity_cue = true
				for raw_actor in combat_stage.get("chickens") as Array:
					var natural_actor := raw_actor as Dictionary
					if bool(natural_actor.get("slam_impacted", false)):
						_log_capture("natural-cave-troll-slam frame=%d phase=%s signature_t=%.3f slam_impacted=%s attack_damage_done=%s actor_pos=%s hero=%s" % [_frame, str(natural_actor.get("attack_phase", "")), float(natural_actor.get("signature_t", 0.0)), str(natural_actor.get("slam_impacted", false)), str(natural_actor.get("attack_damage_done", false)), str(natural_actor.get("pos", Vector2.ZERO)), str(combat_stage.get("hero_pos"))])
				break
			elif strict_natural_giant and _has_decisive_signature(combat_stage, "$captureCueLiteral"):
				found_natural_giant_denial = true
				for raw_actor in combat_stage.get("chickens") as Array:
					var natural_actor := raw_actor as Dictionary
					if bool(natural_actor.get("grabbed_hero", false)):
						_log_capture("natural-giant-flip-denial frame=%d phase=%s signature_t=%.3f grabbed_hero=%s hero_flip_timer=%.3f hero_flip_attack_blocked=%s hero_attack_timer=%.3f hero_attack_cd=%.3f actor_pos=%s hero=%s" % [_frame, str(natural_actor.get("attack_phase", "")), float(natural_actor.get("signature_t", 0.0)), str(natural_actor.get("grabbed_hero", false)), float(combat_stage.get("hero_flip_timer")), str(combat_stage.get("hero_flip_attack_blocked")), float(combat_stage.get("hero_attack_timer")), float(combat_stage.get("hero_attack_cd")), str(natural_actor.get("pos", Vector2.ZERO)), str(combat_stage.get("hero_pos"))])
				break
			elif strict_natural_area_clear and float(combat_stage.get("area_clear_restart_timer")) > 0.0 and _has_visible_float(combat_stage, "+%d XP" % expected_area_clear_xp):
				found_natural_area_clear_xp = true
				_log_capture("natural-area-clear-xp frame=%d timer=%.3f reward_xp=%d kill_budget=%d kill_xp=%d expected=+%d XP" % [_frame, float(combat_stage.get("area_clear_restart_timer")), int(combat_stage.get("combat_reward_xp")), int(combat_stage.call("kill_xp_budget")), int(combat_stage.get("kill_xp_already_awarded")), expected_area_clear_xp])
				break
			elif strict_natural_vampire and _has_decisive_signature(combat_stage, "$captureCueLiteral"):
				found_natural_identity_cue = true
				for raw_actor in combat_stage.get("chickens") as Array:
					var natural_actor := raw_actor as Dictionary
					if bool(natural_actor.get("vampire_crossed", false)):
						_log_capture("natural-vampire-flank-cross frame=%d phase=%s crossed=%s target=%s roll_dir=%s actor_pos=%s hero=%s swipe=%s" % [_frame, str(natural_actor.get("attack_phase", "")), str(natural_actor.get("vampire_crossed", false)), str(natural_actor.get("vampire_target_pos", Vector2.ZERO)), str(natural_actor.get("roll_dir", Vector2.ZERO)), str(natural_actor.get("pos", Vector2.ZERO)), str(combat_stage.get("hero_pos")), str(_has_visible_float(combat_stage, "SWIPE!"))])
				break
			elif "$captureCueLiteral" != "area-clear-xp" and _has_decisive_signature(combat_stage, "$captureCueLiteral"):
				found_natural_identity_cue = "$captureCueLiteral" == "rouses-crash" or "$captureCueLiteral" == "werewolves-wall-miss"
				for raw_actor in combat_stage.get("chickens") as Array:
					var natural_actor := raw_actor as Dictionary
					if "$captureCueLiteral" == "rouses-crash" and float(natural_actor.get("stagger_timer", 0.0)) > 0.0:
						_log_capture("natural-rouses-crash frame=%d phase=%s stagger_timer=%.3f wall_hit=%s attack_damage_done=%s pos=%s hero=%s" % [_frame, str(natural_actor.get("attack_phase", "")), float(natural_actor.get("stagger_timer", 0.0)), str(natural_actor.get("wall_hit", false)), str(natural_actor.get("attack_damage_done", false)), str(natural_actor.get("pos", Vector2.ZERO)), str(combat_stage.get("hero_pos"))])
					elif "$captureCueLiteral" == "werewolves-wall-miss" and bool(natural_actor.get("charge_skidded", false)):
						_log_capture("natural-werewolves-skid frame=%d phase=%s charge_skidded=%s wall_missed=%s wall_hit=%s stagger_timer=%.3f attack_damage_done=%s roll_dir=%s pos=%s hero=%s" % [_frame, str(natural_actor.get("attack_phase", "")), str(natural_actor.get("charge_skidded", false)), str(natural_actor.get("wall_missed", false)), str(natural_actor.get("wall_hit", false)), float(natural_actor.get("stagger_timer", 0.0)), str(natural_actor.get("attack_damage_done", false)), str(natural_actor.get("roll_dir", Vector2.ZERO)), str(natural_actor.get("pos", Vector2.ZERO)), str(combat_stage.get("hero_pos"))])
					else:
						_log_capture("natural-dragon-cue frame=%d phase=%s kind=%s breath_dir=%s center_gap=%.3f pos=%s hero=%s" % [_frame, str(natural_actor.get("attack_phase", "")), str(natural_actor.get("dragon_attack_kind", "")), str(natural_actor.get("breath_dir", Vector2.ZERO)), (natural_actor.get("pos", Vector2.ZERO) as Vector2).distance_to(combat_stage.get("hero_pos")), str(natural_actor.get("pos", Vector2.ZERO)), str(combat_stage.get("hero_pos"))])
				combat_stage.set("hero_attack_cd", 999.0)
				break
	if $activeLiteral and expected_enemy_id == "goblins" and not found_natural_goblin_break:
		_fail("natural goblin shield break was not reached")
		return
	if $activeLiteral and expected_enemy_id == "guys" and "$captureCueLiteral" == "guys-guard-hit" and not found_natural_guys_guard_hit:
		_fail("natural Guys guard hit was not reached")
		return
	if $activeLiteral and "$captureCueLiteral" in ["rouses-crash", "werewolf-transform", "werewolves-wall-miss", "cave-troll-slam", "vampire-flank-cross"] and not found_natural_identity_cue:
		for raw_actor in combat_stage.get("chickens") as Array:
			var timeout_actor := raw_actor as Dictionary
			_log_capture("natural-identity-timeout cue=$captureCueLiteral phase=%s pos=%s roll_dir=%s attack_damage_done=%s stagger_timer=%.3f wall_missed=%s charge_skidded=%s hero=%s" % [str(timeout_actor.get("attack_phase", "")), str(timeout_actor.get("pos", Vector2.ZERO)), str(timeout_actor.get("roll_dir", Vector2.ZERO)), str(timeout_actor.get("attack_damage_done", false)), float(timeout_actor.get("stagger_timer", 0.0)), str(timeout_actor.get("wall_missed", false)), str(timeout_actor.get("charge_skidded", false)), str(combat_stage.get("hero_pos"))])
		_fail("requested natural identity cue was not reached")
		return
	if $activeLiteral and "$captureCueLiteral" == "giant-flip-denial" and not found_natural_giant_denial:
		_fail("natural Giant flip denial was not reached")
		return
	if $activeLiteral and "$captureCueLiteral" == "area-clear-xp" and not found_natural_area_clear_xp:
		_fail("natural Giants area clear +%d XP was not reached" % expected_area_clear_xp)
		return
	# Capture the exact detected production state in its already-mounted composition. Reframing here can remount the lazy card.
	var settle_frames := 24
	var final_frames := 12
	if "$captureCueLiteral" in ["goblins", "rouses-crash", "werewolf-transform", "cave-troll-slam", "directional-breath"]:
		settle_frames = 1
		final_frames = 1
	if expected_enemy_id == "dragons":
		# Preserve the naturally detected brawl/strike cue; do not mutate the actor to hold it.
		settle_frames = 2
		final_frames = 1
	if "$captureCueLiteral" == "area-clear-xp":
		settle_frames = 45
		final_frames = 1
	for _frame in range(settle_frames):
		await process_frame
	for _frame in range(final_frames):
		await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() == "headless":
		print("fighting-diamond-capture skipped=headless")
		quit(0)
		return
	var texture := root.get_texture()
	if texture == null:
		_fail("capture texture missing")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("capture image empty")
		return
	var capture_path := OS.get_environment("IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_PATH")
	var temp_path := OS.get_environment("IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_TEMP_PATH")
	var result := image.save_png(temp_path)
	print("fighting-diamond-capture-temp path=%s result=%s size=%sx%s display=%s" % [temp_path, str(result), str(image.get_width()), str(image.get_height()), DisplayServer.get_name()])
	if capture_scroll != null and original_capture_scroll >= 0:
		capture_scroll.scroll_vertical = original_capture_scroll
		capture_scroll.set("drag_scroll_position", float(original_capture_scroll))
	if result != OK:
		_fail("diamond arena capture could not save the temporary PNG")
		return
	scene.queue_free()
	quit(0)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(240):
		if bool(scene.get("startup_initialized")):
			return true
		await process_frame
	return false


func _hide_capture_overlays(scene: Node) -> void:
	if scene.has_method("_boot_warmup_runtime"):
		scene.call("_boot_warmup_runtime").call("_dismiss_boot_splash_for_play")
	if scene.has_method("_achievement_overlay_surface"):
		scene.call("_achievement_overlay_surface").call("hide_offline_summary_immediate")
	if scene.has_method("_achievement_toast_surface"):
		var toast_layer := scene.call("_achievement_toast_surface").get("achievement_toast_layer") as CanvasLayer
		if toast_layer != null:
			toast_layer.visible = false
	scene.set("boot_warmup_active", false)
	for property_name in ["boot_splash_overlay", "boot_warmup_overlay", "offline_summary_overlay", "achievements_overlay", "achievement_toast_layer", "achievement_toast_root", "page_transition_cover"]:
		var item := scene.get(property_name) as CanvasItem
		if item != null:
			item.visible = false


func _hide_capture_tier_banners(detail_surface: Node) -> void:
	for node in detail_surface.get_children():
		_hide_capture_tier_banner(node)


func _hide_capture_tier_banner(node: Node) -> void:
	if node.has_meta("tier_banner_plaque_hit"):
		var banner := node.get_parent() as Control
		if banner != null:
			banner.custom_minimum_size = Vector2.ZERO
			banner.size = Vector2.ZERO
			banner.visible = false
		return
	for child in node.get_children():
		_hide_capture_tier_banner(child)




func _unlock_for_capture(scene: Node) -> void:
	var fight := scene.skills.get("fight", {}) as Dictionary
	fight["level"] = $FightLevel
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level($FightLevel))
	scene.skills["fight"] = fight
	for raw_action in (scene.get("actions_by_skill") as Dictionary).get("fight", []) as Array:
		var action_id := str((raw_action as Dictionary).get("id", ""))
		if not action_id.is_empty():
			scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", action_id, "real combat card capture")
	scene.stamina["fight"] = 999.0
	if scene.has_method("_sync_stamina_bank"):
		scene.call("_sync_stamina_bank", "fight")


func _find_production_diamond_stage(node: Node, expected_enemy_id: String) -> Control:
	var script := node.get_script() as Script
	if node is Control and script != null and script.resource_path == "res://scripts/ui/blue_guy_chicken_brawl_stage.gd" and str(node.get("arena_shape")) == "diamond" and str(node.get("enemy_id")) == expected_enemy_id:
		return node as Control
	for child in node.get_children():
		var found := _find_production_diamond_stage(child, expected_enemy_id)
		if found != null:
			return found
	return null


func _frame_production_stage(scene: Node, combat_stage: Control) -> void:
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null:
		return
	var scroll_rect := scroll.get_global_rect()
	var stage_rect := combat_stage.get_global_rect()
	# Focus the real dragon arena itself; preceding lazy cards are not proof content.
	var target_scroll := float(scroll.scroll_vertical) + stage_rect.get_center().y - scroll_rect.get_center().y + 700.0
	scroll.scroll_vertical = maxi(0, int(round(target_scroll)))
	scroll.set("drag_scroll_position", float(scroll.scroll_vertical))


func _force_diamond_stage_state(root_node: Node, active: bool, stats_tucked: bool) -> void:
	if root_node.has_method("set_active_fight"):
		var enemy_id := str(root_node.get("enemy_id"))
		root_node.call("set_active_fight", active)
		root_node.set("cover_open_amount", 1.0 if active else 0.0)
		if not active or (enemy_id != "goblins" and enemy_id != "dragons"):
			root_node.set("hero_attack_timer", 0.0)
			root_node.set("hero_attack_cd", 999.0)
		root_node.set("hero_hp", root_node.call("_hero_max_hp"))
		root_node.set("hero_hurt_cooldown", 999.0)
		root_node.set("diamond_stats_tucked", stats_tucked)
	for child in root_node.get_children():
		_force_diamond_stage_state(child, active, stats_tucked)


func _has_decisive_signature(root_node: Node, cue := "auto") -> bool:
	if root_node == null:
		return false
	var actors = root_node.get("chickens")
	if not actors is Array:
		return false
	var id := str(root_node.get("enemy_id"))
	for actor in actors:
		var enemy := actor as Dictionary
		var phase := str(enemy.get("attack_phase", ""))
		var t := float(enemy.get("signature_t", 0.0))
		match id:
			"giants":
				if cue == "giant-flip-denial":
					return bool(enemy.get("grabbed_hero", false)) and float(root_node.get("hero_flip_timer")) > 0.0 and not bool(root_node.get("hero_flip_attack_blocked")) and _has_visible_float(root_node, "STUNNED!")
				if bool(enemy.get("grabbed_hero", false)) and float(root_node.get("hero_flip_timer")) > 0.0:
					return true
			"vampires":
				if cue == "vampire-flank-cross":
					return phase == "strike" and bool(enemy.get("vampire_crossed", false))
				if phase == "strike" and t > 0.20 and (enemy.get("roll_dir", Vector2.ZERO) as Vector2).length() > 0.001:
					return true
			"chicken-swarm", "goblins":
				if phase == "strike" and t > 0.18:
					return true
			"rouses":
				if cue == "rouses-crash":
					return phase in ["recovery", "stagger"] and float(enemy.get("stagger_timer", 0.0)) > 0.0
				if (phase == "strike" and t > 0.20) or (phase == "recovery" and float(enemy.get("stagger_timer", 0.0)) > 0.0):
					return true
			"guys":
				if phase == "windup" and bool(enemy.get("guarding", false)):
					return true
			"werewolves":
				if cue == "werewolves-wall-miss":
					return phase == "recovery" and bool(enemy.get("charge_skidded", false)) and is_zero_approx(float(enemy.get("stagger_timer", 0.0)))
				if (phase == "windup" and t > 0.50) or phase == "strike":
					return true
			"cave-trolls":
				if cue == "cave-troll-slam":
					return bool(enemy.get("slam_impacted", false))
				if phase == "recovery" or (phase == "strike" and t > 0.55):
					return true
			"dragons":
				var kind := str(enemy.get("dragon_attack_kind", "brawl"))
				if cue == "close-brawl":
					return kind == "brawl" and phase == "strike" and float(root_node.get("hero_attack_timer")) > 0.04
				if cue == "directional-breath":
					var center_gap := (enemy.get("pos", Vector2.ZERO) as Vector2).distance_to(root_node.get("hero_pos"))
					return kind == "breath" and phase == "strike" and t > 0.18 and (enemy.get("breath_dir", Vector2.ZERO) as Vector2).length() > 0.001 and center_gap >= 0.39
				if phase == "strike" and t > 0.18:
					return true
	return false


func _has_visible_float(root_node: Node, text: String) -> bool:
	var labels = root_node.get("float_labels")
	if not labels is Array:
		return false
	for label in labels:
		if label is Label and (label as Label).visible and (label as Label).text == text:
			return true
	return false


func _has_natural_goblin_shield_break(root_node: Node) -> bool:
	var actors = root_node.get("chickens")
	if not actors is Array:
		return false
	var has_intact := false
	var has_falling := false
	for actor in actors:
		var enemy := actor as Dictionary
		if bool(enemy.get("shield_up", false)):
			has_intact = true
		elif float(enemy.get("shield_fall_timer", 0.0)) > 0.0:
			has_falling = true
	return has_intact and has_falling


func _has_natural_guys_guard_hit(root_node: Node) -> bool:
	var actors = root_node.get("chickens")
	if not actors is Array:
		return false
	var has_guarded_hit := false
	for actor in actors:
		var enemy := actor as Dictionary
		if bool(enemy.get("guarding", false)) and float(enemy.get("hit_flash", 0.0)) > 0.0:
			has_guarded_hit = true
	if not has_guarded_hit:
		return false
	if float(root_node.get("hero_attack_timer")) <= 0.0:
		return false
	var labels = root_node.get("float_labels")
	if not labels is Array:
		return false
	for label in labels:
		if label is Label and (label as Label).visible and (label as Label).text == "GUARD!":
			return true
	return false


func _log_capture(message: String) -> void:
	print(message)
	var log_path := OS.get_environment("IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_LOG_PATH")
	if log_path.is_empty():
		return
	var file := FileAccess.open(log_path, FileAccess.READ_WRITE if FileAccess.file_exists(log_path) else FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(message)
		file.close()

func _fail(message: String) -> void:
	_log_capture("capture-failed %s" % message)
	push_error("fighting-diamond-capture-failed: %s" % message)
	print("fighting-diamond-capture-failed: %s" % message)
	quit(1)
"@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    $output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/fighting-diamond-real/capture_fighting_diamond_arena.gd" 2>&1
    $output | Write-Output
    if ($LASTEXITCODE -ne 0) {
        throw "Godot capture exited with code $LASTEXITCODE."
    }
    Assert-True (Test-Path -LiteralPath $captureTempPath) "Fighting diamond arena temporary capture was not created."
    Assert-True ((Get-Item -LiteralPath $captureTempPath).Length -gt 1024) "Fighting diamond arena temporary capture was empty."
    Test-CaptureCompleteness $captureTempPath
    Move-Item -LiteralPath $captureTempPath -Destination $capturePath -Force
    Test-CaptureCompleteness $capturePath
    Write-Host "fighting-diamond-capture-file=$capturePath"
}
finally {
    if ($null -eq $previousTimeout) { Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue } else { $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout }
    if ($null -eq $previousCapturePath) { Remove-Item Env:\IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_PATH = $previousCapturePath }
    if ($null -eq $previousCaptureTempPath) { Remove-Item Env:\IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_TEMP_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_TEMP_PATH = $previousCaptureTempPath }
    if ($null -eq $previousCaptureLogPath) { Remove-Item Env:\IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_LOG_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_FIGHTING_DIAMOND_CAPTURE_LOG_PATH = $previousCaptureLogPath }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        Write-Warning "Unrelated headless Godot process appeared during fighting diamond arena capture; leaving it running."
    }
}
