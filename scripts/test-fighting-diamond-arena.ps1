$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fighting-diamond-test"
$testScript = Join-Path $testDir "fighting_diamond_arena_test.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
Assert-True (-not (Test-Path -LiteralPath (Join-Path $projectRoot "scripts\ui\diamond_arena_frame.gd"))) "Stale diamond_arena_frame.gd should stay folded into skill_detail_surface.gd."
Assert-True (-not (Test-Path -LiteralPath (Join-Path $projectRoot "scripts\ui\diamond_arena_frame.gd.uid"))) "Stale diamond_arena_frame.gd.uid should stay deleted."
Assert-True (-not (Select-String -LiteralPath (Join-Path $projectRoot "scripts\ui\skill_detail_surface.gd") -Pattern 'preload("res://scripts/ui/diamond_arena_frame.gd")' -Quiet)) "SkillDetailSurface should not preload the external diamond frame script."
$stageSource = Get-Content -Raw (Join-Path $projectRoot "scripts\ui\blue_guy_chicken_brawl_stage.gd")
$runtimeSource = Get-Content -Raw (Join-Path $projectRoot "scripts\gameplay\fighting_runtime.gd")
$audioSource = Get-Content -Raw (Join-Path $projectRoot "scripts\audio\audio_director.gd")
$shieldDropSfx = Join-Path $projectRoot "assets\sfx\fight_goblin_shield_drop.wav"
$dragonBase = Join-Path $projectRoot "assets\content\fight\base-models\dragon-base.png"
Assert-True ((Get-FileHash -Algorithm SHA256 -LiteralPath $dragonBase).Hash -eq "DC33ECB8677C3A70C8860521FB727107E96CFC8F27DB83C72F8780007B0D24F8") "Dragon base must remain the user-approved compact right-facing model."
foreach ($path in @(
    "assets\content\fight\prototype\chicken-attack-01.png", "assets\content\fight\prototype\chicken-attack-02.png", "assets\content\fight\prototype\chicken-attack-03.png", "assets\content\fight\prototype\chicken-attack-04.png",
    "assets\content\fight\enemies\goblins\goblins-attack-01.png", "assets\content\fight\enemies\goblins\goblins-attack-02.png", "assets\content\fight\enemies\goblins\goblins-attack-03.png", "assets\content\fight\enemies\goblins\goblins-attack-04.png",
    "assets\content\fight\enemies\rouses\rouses-attack-01.png", "assets\content\fight\enemies\rouses\rouses-attack-02.png", "assets\content\fight\enemies\rouses\rouses-attack-03.png", "assets\content\fight\enemies\rouses\rouses-attack-04.png",
    "assets\content\fight\enemies\guys\guys-attack-01.png", "assets\content\fight\enemies\guys\guys-attack-02.png", "assets\content\fight\enemies\guys\guys-attack-03.png", "assets\content\fight\enemies\guys\guys-attack-04.png",
    "assets\content\fight\enemies\guys\guys-walk-01.png", "assets\content\fight\enemies\guys\guys-walk-02.png", "assets\content\fight\enemies\guys\guys-walk-03.png", "assets\content\fight\enemies\guys\guys-walk-04.png",
    "assets\content\fight\enemies\guys\guys-run-01.png", "assets\content\fight\enemies\guys\guys-run-02.png", "assets\content\fight\enemies\guys\guys-run-03.png", "assets\content\fight\enemies\guys\guys-run-04.png",
    "assets\content\fight\enemies\werewolves\werewolves-attack-01.png", "assets\content\fight\enemies\werewolves\werewolves-attack-02.png", "assets\content\fight\enemies\werewolves\werewolves-attack-03.png", "assets\content\fight\enemies\werewolves\werewolves-attack-04.png",
    "assets\content\fight\enemies\cave-trolls\cave-trolls-attack-01.png", "assets\content\fight\enemies\cave-trolls\cave-trolls-attack-02.png", "assets\content\fight\enemies\cave-trolls\cave-trolls-attack-03.png", "assets\content\fight\enemies\cave-trolls\cave-trolls-attack-04.png",
    "assets\content\fight\enemies\giants\giants-attack-01.png", "assets\content\fight\enemies\giants\giants-attack-02.png", "assets\content\fight\enemies\giants\giants-attack-03.png", "assets\content\fight\enemies\giants\giants-attack-04.png",
    "assets\content\fight\enemies\vampires\vampires-attack-01.png", "assets\content\fight\enemies\vampires\vampires-attack-02.png", "assets\content\fight\enemies\vampires\vampires-attack-03.png", "assets\content\fight\enemies\vampires\vampires-attack-04.png",
    "assets\content\fight\enemies\dragons\dragons-claw-01.png", "assets\content\fight\enemies\dragons\dragons-claw-02.png", "assets\content\fight\enemies\dragons\dragons-claw-03.png", "assets\content\fight\enemies\dragons\dragons-claw-04.png",
    "assets\content\fight\enemies\dragons\dragons-breath-01.png", "assets\content\fight\enemies\dragons\dragons-breath-02.png", "assets\content\fight\enemies\dragons\dragons-breath-03.png", "assets\content\fight\enemies\dragons\dragons-breath-04.png")) {
    Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot $path)) "Missing runtime attack asset: $path"
}
foreach ($frame in 1..5) {
    $path = "assets\content\fight\enemies\werewolves\werewolves-transform-{0:D2}.png" -f $frame
    Assert-True (Test-Path -LiteralPath (Join-Path $projectRoot $path)) "Missing Werewolf transformation frame: $path"
}
Assert-True ($stageSource -match '_enemy_attack_texture|_load_enemy_attack_frames') "Runtime attack frame helpers should be present."
Assert-True (-not $stageSource.Contains('and lunge_timer <= 0.0')) "Chicken strike frames should not be hidden by their lunge movement."
Assert-True ($stageSource.Contains('if not dead and enemy_id == "rouses" and attack_phase == "strike":')) "The stretched R.O.U.S.es strike frame should use its fitted draw scale."
Assert-True ($stageSource -match 'WEREWOLF_TRANSFORM_DURATION|werewolves-transform') "Werewolf transformation timing and frame loading should be present."
foreach ($legacyCue in @('_draw_enemy_signature', 'CRASH!', 'SKID!', 'SWIPE!', 'SLAM!', 'GRAB!', 'FLIP!', 'BLOCK!', 'GUARD!')) {
    Assert-True (-not ($stageSource.Contains($legacyCue))) "Legacy enemy cue should be absent from stage: $legacyCue"
}
foreach ($prohibitedPaletteValue in @('XP_GOLD', '#ffe56b', '#ffb938', '#ffcf35', '#fff27b', '#ffef7a', '#e1a944', '(1.0, 0.80, 0.16)', '(1.0, 0.95, 0.42)', '(1.0, 0.94, 0.48)', '(1.0, 0.96, 0.62)')) {
    Assert-True (-not $stageSource.Contains($prohibitedPaletteValue)) "Yellow fight palette value should be absent: $prohibitedPaletteValue"
}
Assert-True ($stageSource -match 'const REWARD_GREEN := Color\("#38e57e"\)') "Fight rewards should use a named green constant."
Assert-True ($stageSource -match 'hp < max_hp - 0\.01') "Enemy HP bars should remain hidden at full health."
Assert-True ($stageSource -match 'health_width, hp / max_hp, DANGER') "Damaged enemy HP bars should use DANGER red."
Assert-True (-not $stageSource.Contains('hp / max_hp < 0.38')) "Low health should not fake a permanent stagger pose."
Assert-True (-not $stageSource.Contains('hp / max_hp >= 0.38')) "Low health should not hide enemy attack frames."
Assert-True ($stageSource -match 'var fill_color: Color = Color\(0\.31, 0\.76, 1\.0') "Hero attack feedback fill should use blue/cyan."
Assert-True ($stageSource -match 'var ring_color: Color = Color\(0\.72, 0\.92, 1\.0') "Hero attack feedback ring should use blue/cyan/white."
Assert-True ($stageSource -match 'state_scale \*= _enemy_death_scale_for_id\(enemy_id\)') "Defeated enemies should use their fitted family scale."
Assert-True ($stageSource -match 'if enemy_id == "chicken-swarm" and not dead:[\r\n]+\s+state_scale \*= 1\.15') "Living chickens should render 15 percent larger than their previous scale."
Assert-True (-not $stageSource.Contains('death_tilt')) "Defeated enemies should not slowly rotate while fading."
Assert-True ($stageSource -match 'var hop := 0\.0 if not active or dead') "Defeated enemies should not inherit the living idle hop."
Assert-True ($stageSource -match 'var idle_wobble := 0\.0 if not active or dead') "Defeated enemies should not inherit the living idle wobble."
Assert-True (-not $stageSource.Contains('_draw_low_hp_danger_tint')) "Low HP should not draw a red stroke around the fight module."
Assert-True ($stageSource -match 'Vector2\(212, 212\).*if is_striking') "Normal punches should stay close to the guard pose scale."
Assert-True ($stageSource -match 'foot_line_y - hero_content\.end\.y') "Blue Guy action poses should share one visible foot line."
Assert-True ($stageSource -match 'lunge\.y \* 0\.22') "Blue Guy should retain only a small vertical attack step."
Assert-True (-not $stageSource.Contains('hero_sprite_center += Vector2(0.0, -20.0)')) "Blue Guy punches should not use the old pose-specific vertical pop."
Assert-True ($stageSource -match 'const ENEMY_DEATH_FADE_DELAY := 1\.93') "Defeated enemies should remain still for one extra second before fading."
Assert-True (-not $stageSource.Contains('ENEMY_DEATH_SETTLE_SECONDS')) "Defeated enemies should stop after two airborne arcs."
Assert-True ($stageSource -match 'Vector2\(-68\.0 if face_right else 68\.0, 18\.0\)') "Goblin shields should anchor to the mirrored non-sword hand."
Assert-True ($stageSource -match 'punch_landed\.emit\(shield_dropped\)') "Goblin shield drops should be identified by the landed-punch signal."
Assert-True ($runtimeSource -match '_play_goblin_shield_drop_sfx\(\)') "Goblin shield drops should trigger their dedicated SFX."
Assert-True ($audioSource -match 'GOBLIN_SHIELD_DROP_SFX_VOLUME_DB := -20\.0') "Goblin shield drop SFX should sit below the normal punch mix."
Assert-True (Test-Path -LiteralPath $shieldDropSfx) "Goblin shield drop SFX asset should exist."
Assert-True (Test-Path -LiteralPath "$shieldDropSfx.import") "Goblin shield drop SFX should have a Godot import remap."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree

const ActivityCardStyles := preload("res://scripts/ui/activity_card_styles.gd")
const SkillState := preload("res://scripts/progression/skill_state.gd")
const Stage := preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")

var test_failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("fighting-diamond-arena-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	scene.get("activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 5
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(5))
	scene.skills["fight"] = fight
	var action := scene.call("_action_data", "fight", "fight-chickens") as Dictionary
	_expect(not action.is_empty(), "Fight Chickens should load")
	var legacy_action := scene.call("_action_data", "fight", "chicken-sparring-pit") as Dictionary
	_expect(not legacy_action.is_empty() and str(legacy_action.get("id", "")) == "fight-chickens", "legacy chicken alias should resolve to canonical data")
	var fighting_runtime = scene.call("_fighting_runtime")
	_expect(fighting_runtime.action_is_free_fighting_proto("fight", "fight-chickens"), "canonical chicken action should activate")
	_expect(fighting_runtime.action_is_free_fighting_proto("fight", "chicken-sparring-pit"), "legacy chicken action should activate")
	_expect(fighting_runtime.action_is_free_fighting_proto("fight", "fight-r.o.u.s.es"), "canonical R.O.U.S.es action should activate")
	_expect(fighting_runtime.action_is_free_fighting_proto("fight", "fight-rouses"), "legacy R.O.U.S.es action should activate")
	_expect(fighting_runtime.action_uses_blue_guy_chicken_brawl_stage(action), "Fight Chickens should still use the chicken brawl stage")
	_expect(fighting_runtime.action_uses_diamond_combat_arena(action), "Fight Chickens should opt into the diamond combat arena")
	var combat := action.get("combat", {}) as Dictionary
	_expect(str(combat.get("enemy_id", "")) == "chicken-swarm", "combat enemy id should be normalized from data")
	_expect(float(combat.get("contact_damage", 0.0)) == 8.0, "combat contact damage should be preserved")
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1080.0, 1080.0) as Dictionary
	var root_control := built.get("card_root") as Control
	var normal_card_height := ActivityCardStyles.root_height(false, 720.0, 1080.0, 34.0)
	_expect(root_control != null and str(root_control.get_meta("combat_arena_shape", "")) == "diamond", "card root should mark diamond combat arena shape")
	_expect(root_control.custom_minimum_size.y > normal_card_height * 1.4, "diamond combat arena should stay larger than a normal card")
	_expect(root_control.custom_minimum_size.y < normal_card_height * 1.7, "diamond combat arena should not be double-height")
	var card := built.get("card", {}) as Dictionary
	scene.call("_skill_detail_surface").call("_set_activity_card_expanded", card, root_control, false, true)
	_expect(root_control.custom_minimum_size.y > normal_card_height * 1.4, "diamond combat arena should not shrink to normal card height after stat sync")
	var pop := card.get("pop") as Control
	_expect(_has_diamond_frame(pop), "diamond combat arena should attach a local diamond frame overlay")
	var stage := card.get("blue_guy_chicken_stage") as Control
	_expect(stage != null and str(stage.get("arena_shape")) == "diamond", "chicken brawl gameplay should render inside the diamond arena")
	stage.call("_ready")
	_expect(stage != null and not stage.clip_contents, "diamond arena depth should not be clipped by the stage rect")
	stage.size = Vector2(1080.0, 1080.0)
	_check_runtime_art_sources(stage)
	_check_diamond_chicken_steering(stage)
	_check_enemy_hero_exclusion_ring(stage)
	_check_wave_one_spawn_cadence(stage)
	_check_enemy_health_bar_anchors(stage)
	_check_diamond_crit_feedback(scene, card)
	_check_enemy_attack_displacement(stage)
	_check_vampire_identity(stage)
	_check_population_caps(stage)
	_check_reward_contract(scene, stage, fighting_runtime)
	_check_goblin_shield(stage, scene)
	_check_giant_identity(stage, scene)
	_check_guys_guard(stage, scene)
	_check_rouses_werewolves_identity(stage)
	_check_cave_troll_identity(stage, scene)
	stage.set("diamond_stats_tucked", false)
	var open_rect := stage.call("_diamond_stats_plate_draw_rect", 1.0) as Rect2
	_expect(bool(stage.call("_toggle_diamond_stats_if_tapped", open_rect.get_center())), "diamond stat plate should tuck when tapped")
	_expect(bool(stage.get("diamond_stats_tucked")), "diamond stat plate should be tucked after tap")
	var tucked_rect := stage.call("_diamond_stats_plate_draw_rect", 1.0) as Rect2
	_expect(bool(stage.call("_toggle_diamond_stats_if_tapped", tucked_rect.get_center())), "diamond stat tab should reopen when tapped")
	_expect(not bool(stage.get("diamond_stats_tucked")), "diamond stat plate should reopen after second tap")
	_check_shared_lifecycle(stage)
	_check_dragon_cycle(stage)
	_check_center_identity_reachability(stage, scene)
	_check_profiles(scene)
	_check_chicken_balance_curve(scene)
	_check_completion_rates(scene)
	_check_stationary_interrupts(scene)
	scene.queue_free()
	if test_failed:
		quit(1)
		return
	print("fighting-diamond-arena-ok")
	quit(0)


func _has_diamond_frame(root_control: Control) -> bool:
	if root_control == null:
		return false
	for child in root_control.get_children():
		if child is Control and child.has_method("_diamond_points") and child.has_method("_rounded_diamond_points"):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _check_runtime_art_sources(stage: Control) -> void:
	var paths: Array[String] = [
		"res://assets/content/fight/prototype/chicken-cover-clean.png",
		"res://assets/content/fight/prototype/blue-guy-ko.png",
		"res://assets/content/fight/enemies/goblins/goblin-shield.png",
		"res://assets/content/fight/terrain/cave-trolls-cave-floor.png",
		"res://assets/content/fight/terrain/giants-mountain-stone.png",
		"res://assets/content/fight/terrain/vampires-carpeted-hall.png",
		"res://assets/content/fight/terrain/werewolves-moonlit-grass.png",
	]
	for frame in range(1, 7):
		paths.append("res://assets/content/fight/prototype/blue-guy-ko-%02d.png" % frame)
	for variant in ["", "gray-", "black-"]:
		for state in ["idle", "windup-v2", "hit", "dizzy", "defeated"]:
			paths.append("res://assets/content/fight/prototype/chicken-%s%s.png" % [variant, state])
		var movement_prefix := "chicken-white-move" if variant.is_empty() else "chicken-%smove" % variant
		var attack_prefix := "chicken-attack" if variant.is_empty() else "chicken-%sattack" % variant
		for frame in range(1, 5):
			paths.append("res://assets/content/fight/prototype/%s-%02d.png" % [movement_prefix, frame])
			paths.append("res://assets/content/fight/prototype/%s-%02d.png" % [attack_prefix, frame])
	for family in ["goblins", "rouses", "werewolves", "cave-trolls", "vampires", "dragons"]:
		for state in ["idle", "hit", "dizzy", "defeated"]:
			paths.append("res://assets/content/fight/enemies/%s/%s-%s.png" % [family, family, state])
		for frame in range(1, 5):
			paths.append("res://assets/content/fight/enemies/%s/%s-move-%02d.png" % [family, family, frame])
			if family != "dragons":
				paths.append("res://assets/content/fight/enemies/%s/%s-attack-%02d.png" % [family, family, frame])
			else:
				paths.append("res://assets/content/fight/enemies/dragons/dragons-claw-%02d.png" % frame)
				paths.append("res://assets/content/fight/enemies/dragons/dragons-breath-%02d.png" % frame)
	for frame in range(1, 6):
		paths.append("res://assets/content/fight/enemies/werewolves/werewolves-transform-%02d.png" % frame)
	for effect in ["hit-impact-yellow", "dizzy-stars", "dragon-breath-flame", "cave-troll-slam", "wolf-claw-tear"]:
		for frame in range(1, 5):
			paths.append("res://assets/content/fight/effects/%s-%02d.png" % [effect, frame])
	for path in paths:
		var source := Image.new()
		_expect(source.load(ProjectSettings.globalize_path(path)) == OK, "runtime monster source should load: %s" % path)
		var texture := stage.call("load_png_texture", path) as Texture2D
		_expect(texture != null and texture.get_image().get_data() == source.get_data(), "runtime should use current monster PNG instead of stale imported art: %s" % path)
	var terrain_paths := {
		"cave-trolls": "res://assets/content/fight/terrain/cave-trolls-cave-floor.png",
		"giants": "res://assets/content/fight/terrain/giants-mountain-stone.png",
		"vampires": "res://assets/content/fight/terrain/vampires-carpeted-hall.png",
		"werewolves": "res://assets/content/fight/terrain/werewolves-moonlit-grass.png",
	}
	for terrain_enemy in terrain_paths:
		_expect(stage.call("_arena_floor_path_for_enemy", terrain_enemy) == terrain_paths[terrain_enemy], "monster should select its unique terrain: %s" % terrain_enemy)
	_expect(stage.call("_arena_floor_path_for_enemy", "goblins") == "res://assets/content/fight/prototype/arena-floor.png", "unmapped monsters should retain the shared arena floor")
	var terrain_depth_colors := {
		"cave-trolls": Color("#343832"),
		"giants": Color("#756b5b"),
		"vampires": Color("#650e14"),
		"werewolves": Color("#0b3f5a"),
	}
	for terrain_enemy in terrain_depth_colors:
		_expect((stage.call("_arena_depth_color_for_enemy", terrain_enemy) as Color).is_equal_approx(terrain_depth_colors[terrain_enemy]), "diamond depth should match its terrain: %s" % terrain_enemy)
	_expect((stage.call("_arena_depth_color_for_enemy", "goblins") as Color).is_equal_approx(Color("#315d1d")), "grass arenas should retain the green diamond depth")
	var white_states := {
		"idle": "chicken-idle.png",
		"windup-v2": "chicken-windup-v2.png",
		"hit": "chicken-hit.png",
		"dizzy": "chicken-dizzy.png",
		"defeated": "chicken-defeated.png",
	}
	for variant in ["gray", "black"]:
		for state in white_states:
			_expect_same_alpha_mask(
				"res://assets/content/fight/prototype/%s" % white_states[state],
				"res://assets/content/fight/prototype/chicken-%s-%s.png" % [variant, state],
				"%s %s" % [variant, state]
			)
		for frame in range(1, 5):
			_expect_same_alpha_mask(
				"res://assets/content/fight/prototype/chicken-white-move-%02d.png" % frame,
				"res://assets/content/fight/prototype/chicken-%s-move-%02d.png" % [variant, frame],
				"%s move %d" % [variant, frame]
			)
			_expect_same_alpha_mask(
				"res://assets/content/fight/prototype/chicken-attack-%02d.png" % frame,
				"res://assets/content/fight/prototype/chicken-%s-attack-%02d.png" % [variant, frame],
				"%s attack %d" % [variant, frame]
			)
	for variant in ["gray", "black"]:
		var idle_source := Image.new()
		var defeated_source := Image.new()
		_expect(idle_source.load(ProjectSettings.globalize_path("res://assets/content/fight/prototype/chicken-%s-idle.png" % variant)) == OK, "%s chicken idle source should load" % variant)
		_expect(defeated_source.load(ProjectSettings.globalize_path("res://assets/content/fight/prototype/chicken-%s-defeated.png" % variant)) == OK, "%s chicken defeated source should load" % variant)
		_expect(defeated_source.get_used_rect().size.x > idle_source.get_used_rect().size.x * 1.5, "%s chicken defeated art should use the collapsed death pose" % variant)
	var expected_scales := {
		"chicken-swarm": 1.90,
		"goblins": 1.2834,
		"rouses": 2.70,
		"guys": 1.2325,
		"werewolves": 2.10,
		"cave-trolls": 2.40,
		"vampires": 2.05,
		"dragons": 2.30,
	}
	for enemy_id in expected_scales:
		_expect(is_equal_approx(float(stage.call("_enemy_sprite_scale_for_id", enemy_id)), float(expected_scales[enemy_id])), "replacement monster scale should stay calibrated: %s" % enemy_id)
	var expected_death_scales := {
		"chicken-swarm": 0.70,
		"goblins": 1.00,
		"rouses": 0.80,
		"guys": 1.00,
		"werewolves": 0.92,
		"cave-trolls": 1.00,
		"giants": 1.00,
		"vampires": 0.84,
		"dragons": 1.00,
	}
	for enemy_id in expected_death_scales:
		_expect(is_equal_approx(float(stage.call("_enemy_death_scale_for_id", enemy_id)), float(expected_death_scales[enemy_id])), "monster death scale should stay fitted to its collapsed silhouette: %s" % enemy_id)
	stage.set("enemy_id", "goblins")
	_expect(stage.call("_chicken_texture", "black", "hit") == stage.get("hit_chicken"), "non-chicken hit frames should ignore chicken color variants")
	_expect(stage.call("_chicken_texture", "gray", "dizzy") == stage.get("dizzy_chicken"), "non-chicken dizzy frames should ignore chicken color variants")
	_expect(stage.call("_chicken_texture", "black", "defeated") == stage.get("defeated_chicken"), "non-chicken death frames should ignore chicken color variants")
	stage.set("enemy_id", "chicken-swarm")
	var expected_shadow_scales := {
		"chicken-swarm": 0.30,
		"goblins": 0.62,
		"rouses": 0.38,
		"guys": 0.52,
		"werewolves": 0.52,
		"cave-trolls": 0.70,
		"giants": 0.70,
		"vampires": 0.48,
		"dragons": 0.78,
	}
	for enemy_id in expected_shadow_scales:
		_expect(is_equal_approx(float(stage.call("_enemy_shadow_scale_for_id", enemy_id)), float(expected_shadow_scales[enemy_id])), "monster shadow scale should stay fitted to its visible silhouette: %s" % enemy_id)
	var first_bounce := stage.call("_enemy_death_bounce_pose", 0.19, true, 1.0, Vector2.RIGHT) as Vector2
	var normal_bounce := stage.call("_enemy_death_bounce_pose", 0.19, true, 1.0 / 3.0) as Vector2
	var second_bounce := stage.call("_enemy_death_bounce_pose", 0.505, true, 1.0) as Vector2
	var vertical_bounce := stage.call("_enemy_death_bounce_pose", 0.19, true, 1.0, Vector2.UP) as Vector2
	var diagonal_bounce := stage.call("_enemy_death_bounce_pose", 0.19, true, 1.0, Vector2(1.0, -1.0)) as Vector2
	var after_second_bounce := stage.call("_enemy_death_bounce_pose", 0.70, true, 1.0) as Vector2
	var settled := stage.call("_enemy_death_bounce_pose", 0.80, true, 1.0) as Vector2
	_expect(first_bounce.x < -80.0 and absf(first_bounce.y) > 0.8, "defeated enemies should flip through a strong first bounce")
	_expect(normal_bounce.is_equal_approx(first_bounce / 3.0), "ordinary deaths should travel one third as far as uppercut deaths")
	_expect(second_bounce.x < -30.0, "defeated enemies should rebound after hitting the ground")
	_expect(is_equal_approx(vertical_bounce.x, first_bounce.x) and is_zero_approx(vertical_bounce.y), "vertical death bounces should keep their lift without rubbery rotation")
	_expect(absf(diagonal_bounce.y) > 0.0 and absf(diagonal_bounce.y) < absf(first_bounce.y), "diagonal death bounces should taper rotation by travel angle")
	_expect(after_second_bounce.is_zero_approx(), "defeated enemies should not take a third bounce")
	_expect(settled.is_zero_approx(), "defeated enemies should become still before fading")
	var defeated_texture := stage.get("gray_defeated_chicken") as Texture2D
	var defeated_content := stage.call("_texture_content_rect", defeated_texture, Vector2(172.0, 156.0)) as Rect2
	_expect(defeated_content.size.x > 0.0 and defeated_content.end.y > 0.0, "defeated sprites should expose their opaque bounds for ground-aligned shadows")
	var guard_content := stage.call("_texture_content_rect", stage.get("blue_guy_guard"), Vector2(198.0, 198.0)) as Rect2
	var punch_content := stage.call("_texture_content_rect", stage.get("blue_guy_punch"), Vector2(212.0, 212.0)) as Rect2
	var guard_center_y := -12.0
	var punch_center_y := guard_center_y + guard_content.end.y - punch_content.end.y
	_expect(is_equal_approx(guard_center_y + guard_content.end.y, punch_center_y + punch_content.end.y), "Blue Guy guard and punch art should resolve to the same visible foot line")
	_expect(punch_content.size.y < guard_content.size.y * 1.08, "Blue Guy punch silhouette should not pop much larger than his guard pose")
	var ko_bounds: Array[Rect2i] = []
	for frame in range(1, 7):
		var ko_source := Image.new()
		var path := "res://assets/content/fight/prototype/blue-guy-ko-%02d.png" % frame
		_expect(ko_source.load(ProjectSettings.globalize_path(path)) == OK, "Blue Guy KO animation frame should load: %s" % path)
		_expect(ko_source.get_size() == Vector2i(640, 640), "Blue Guy KO frames should share one stable canvas")
		var bounds := ko_source.get_used_rect()
		_expect(bounds.position.x >= 96 and bounds.position.y >= 96 and bounds.end.x <= 544 and bounds.end.y <= 544, "Blue Guy KO frame should retain at least 15 percent transparent padding: %s" % path)
		_expect(bounds.end.y == 544, "Blue Guy KO frames should share one exact ground line: %s" % path)
		ko_bounds.append(bounds)
	_expect(ko_bounds[2].position.y < ko_bounds[1].position.y, "Blue Guy KO apex should visibly extend above the arm-lift frame")
	_expect(ko_bounds[5].size.x > ko_bounds[5].size.y * 2, "Blue Guy KO final frame should be a low collapsed body")
	_expect((stage.get("blue_guy_ko_frames") as Array).size() == 6, "Blue Guy KO runtime should load all six animation frames")
	_expect(stage.call("_blue_guy_ko_frame", 0.0) == (stage.get("blue_guy_ko_frames") as Array)[0], "Blue Guy KO should begin on the brace frame")
	_expect(stage.call("_blue_guy_ko_frame", 0.84) == (stage.get("blue_guy_ko_frames") as Array)[5], "Blue Guy KO should settle on the final still body")
	_expect((stage.get("blue_guy_ko") as Texture2D).get_size() == Vector2(424, 224), "giant flip should retain the tight regenerated final-body asset")


func _expect_same_alpha_mask(expected_path: String, actual_path: String, label: String) -> void:
	var expected := Image.new()
	var actual := Image.new()
	if expected.load(ProjectSettings.globalize_path(expected_path)) != OK or actual.load(ProjectSettings.globalize_path(actual_path)) != OK:
		_fail("Chicken variant frame should load: %s" % label)
		return
	expected.convert(Image.FORMAT_RGBA8)
	actual.convert(Image.FORMAT_RGBA8)
	if expected.get_size() != actual.get_size():
		_fail("Chicken variant frame should preserve its source canvas: %s" % label)
		return
	var expected_data := expected.get_data()
	var actual_data := actual.get_data()
	for offset in range(3, expected_data.size(), 4):
		if expected_data[offset] != actual_data[offset]:
			_fail("Chicken variant frame should preserve its source silhouette and padding: %s" % label)
			return


func _check_diamond_chicken_steering(stage: Control) -> void:
	stage.set("active", true)
	stage.set("hero_pos", Vector2(0.5, 0.55))
	var samples := [
		Vector2(0.04, 0.30),
		Vector2(0.96, 0.38),
		Vector2(0.22, 0.08),
		Vector2(0.78, 0.92),
	]
	for i in range(samples.size()):
		var chicken := {
			"id": i + 1,
			"pos": samples[i],
			"hp": 30.0,
			"max_hp": 30.0,
			"attack_cd": 9.0,
			"lunge_timer": 0.0,
			"uppercut_knock_timer": 0.0,
			"hit_flash": 0.0,
			"uppercut_pop": 0.0,
			"dead_timer": 0.0,
			"damage_done": false,
			"speed": 0.45,
			"variant": "white",
			"damage": 1.0
		}
		var before: float = samples[i].distance_to(Vector2(0.5, 0.55))
		stage.call("_step_chicken", chicken, 0.6)
		var after: float = (chicken.get("pos", samples[i]) as Vector2).distance_to(Vector2(0.5, 0.55))
		_expect(after < before, "diamond chicken steering should move sample %d toward blue guy" % i)


func _check_enemy_hero_exclusion_ring(stage: Control) -> void:
	stage.set("hero_pos", Vector2(0.50, 0.55))
	for family in ["goblins"]:
		stage.set("enemy_id", family)
		var radius := float(stage.call("_enemy_hero_ring_radius", {"dragon_attack_kind": "brawl"}))
		var stopped := stage.call("_clamp_enemy_approach_to_hero_ring", {"id": 3, "dragon_attack_kind": "brawl"}, stage.get("hero_pos") + Vector2.RIGHT * radius * 1.1, stage.get("hero_pos") - Vector2.RIGHT * radius * 1.1) as Vector2
		_expect(stopped.distance_to(stage.get("hero_pos")) >= radius - 0.001 and stopped.x > (stage.get("hero_pos") as Vector2).x, "%s should stop on its original side of the hero ring" % family)
		var actor := {
			"id": 3,
			"pos": stage.get("hero_pos") + Vector2.RIGHT * radius * 2.0,
			"render_pos": stage.get("hero_pos") + Vector2.LEFT * radius * 2.0,
			"render_sim_pos": stage.get("hero_pos") + Vector2.LEFT * radius * 2.0,
			"hp": 30.0,
			"dragon_attack_kind": "brawl",
		}
		var before := actor.get("render_pos") as Vector2
		stage.call("_update_enemy_render_pos", actor, 1.0 / 60.0)
		var render_pos := actor.get("render_pos") as Vector2
		_expect(render_pos.x > before.x and is_equal_approx(render_pos.y, before.y), "%s render correction should move directly instead of orbiting around Blue Guy" % family)
		actor["pos"] = stage.get("hero_pos")
		var distance_before := render_pos.distance_to(stage.get("hero_pos"))
		stage.call("_update_enemy_render_pos", actor, 0.10)
		_expect((actor.get("render_pos") as Vector2).distance_to(stage.get("hero_pos")) < distance_before, "%s render correction should keep taking the shortest path" % family)
	var facing_actor := {"pos": Vector2(0.49, 0.40), "hp": 30.0, "face_right": true}
	stage.call("_update_chicken_facing", facing_actor, Vector2.LEFT * 0.02)
	stage.call("_update_chicken_facing", facing_actor, Vector2.RIGHT * 0.02)
	_expect(bool(facing_actor.get("face_right")), "Goblin should ignore side-to-side attack jitter near the hero axis")
	facing_actor["pos"] = Vector2(0.70, 0.55)
	stage.call("_update_chicken_facing", facing_actor, Vector2.RIGHT * 0.02)
	_expect(not bool(facing_actor.get("face_right")), "Goblin should turn once when the hero clearly crosses sides")
	stage.set("enemy_id", "guys")
	var walking_actor := {
		"id": 3,
		"pos": stage.get("hero_pos") + Vector2.LEFT * 0.30,
		"render_pos": stage.get("hero_pos") + Vector2.RIGHT * 0.30,
		"render_sim_pos": stage.get("hero_pos") + Vector2.RIGHT * 0.30,
		"hp": 30.0,
		"face_right": true,
		"attack_phase": "",
	}
	var walking_before := (walking_actor.get("render_pos") as Vector2).x
	stage.call("_update_enemy_render_pos", walking_actor, 0.10)
	_expect((walking_actor.get("render_pos") as Vector2).x < walking_before and not bool(walking_actor.get("face_right")), "Walking Guys should face their rendered travel direction")
	stage.set("enemy_id", "chicken-swarm")


func _check_enemy_health_bar_anchors(stage: Control) -> void:
	var source: String = stage.get_script().get_source_code()
	_expect(source.find("if not dead and hp < max_hp - 0.01") >= 0, "enemy health bars should appear only after taking damage")
	_expect(source.find("_enemy_health_bar_center") >= 0, "damaged enemy health bars should stay anchored above their sprite")
	_expect(source.find("draw_arc(center + Vector2(0.0, 20.0)") < 0, "Chicken wind-up should use character art instead of a yellow UI arc")


func _check_wave_one_spawn_cadence(stage: Control) -> void:
	var previous_serial := int(stage.get("chicken_serial"))
	stage.set("enemy_id", "chicken-swarm")
	stage.set("enemy_population_curve", [4, 5, 6, 7, 8])
	stage.set("enemy_population_cap", 8)
	stage.set("wave_index", 0)
	stage.set("wave_spawn_phase_duration_current", 6.0)
	stage.set("wave_spawn_remaining", -1)
	stage.set("wave_spawned_count", 0)
	stage.set("spawn_timer", 0.0)
	(stage.get("chickens") as Array).clear()
	stage.call("_step_random_wave_spawning", 0.0)
	_expect((stage.get("chickens") as Array).size() == 1, "Random Chicken wave one should guarantee one opening chicken")
	_expect(float(stage.call("_random_spawn_chance_per_roll")) > 0.07 and float(stage.call("_random_spawn_chance_per_roll")) < 0.09, "Chicken wave one should use a low per-roll spawn chance")
	stage.set("chicken_serial", previous_serial)
	stage.call("_seed_fight")


func _check_diamond_crit_feedback(scene: Node, card: Dictionary) -> void:
	var key := str(scene.call("_action_key", "fight", "fight-chickens"))
	var feedback = scene.call("_reward_feedback_surface")
	feedback.call("_play_activity_crit_feedback", key, card, true)
	var pop := card.get("pop") as Control
	var highlight := pop.get_meta("activity_crit_highlight_node", null) as Panel
	_expect(highlight != null and highlight.get_theme_stylebox("panel") is StyleBoxEmpty, "Diamond fight crits should not draw a thick rectangular outline")
	_expect(not pop.has_meta("activity_crit_art_burst_node"), "Diamond fight crits should not copy hidden card art over the arena")
	feedback.call("_clear_action_crit_tweens")


func _check_shared_lifecycle(stage: Control) -> void:
	var enemy := {"attack_phase": "", "attack_timer": 0.0, "attack_damage_done": false, "stagger_timer": 0.0, "hit_flash": 0.0}
	stage.call("setup_fighting_level", 43)
	stage.call("_begin_enemy_attack", enemy, Vector2.RIGHT)
	_expect(float(enemy.get("attack_timer", 0.0)) > 0.0, "enemy attack should seed a readable wind-up")
	enemy["attack_phase"] = "windup"
	stage.call("_stagger_enemy", enemy)
	_expect(str(enemy.get("attack_phase", "")) == "stagger", "wind-up hit should stagger enemy")
	_expect(bool(enemy.get("attack_damage_done", false)), "stagger should consume pending enemy strike")
	_expect(bool(enemy.get("interrupt_protected", false)), "an interrupt should protect the next attack cycle")
	enemy["attack_phase"] = "windup"
	stage.call("_stagger_enemy", enemy)
	_expect(str(enemy.get("attack_phase", "")) == "windup", "an already interrupted attack should still complete its next wind-up")
	enemy["attack_phase"] = "strike"
	enemy["attack_timer"] = 0.01
	enemy["attack_duration"] = 0.01
	enemy["stagger_timer"] = 0.0
	enemy["hp"] = 100.0
	enemy["pos"] = Vector2(0.5, 0.55)
	enemy["roll_dir"] = Vector2.RIGHT
	stage.call("_step_chicken", enemy, 0.05)
	_expect(str(enemy.get("attack_phase", "")) == "recovery", "protected wind-up should reach recovery")
	_expect(not bool(enemy.get("interrupt_protected", false)), "interrupt protection should reset on recovery")
	enemy["attack_phase"] = "windup"
	stage.call("_stagger_enemy", enemy)
	_expect(str(enemy.get("attack_phase", "")) == "stagger", "a later attack cycle should be interruptible again")
	stage.set("hero_hp", 100.0)
	stage.set("hero_hurt_cooldown", 0.0)
	enemy["damage"] = 40.0
	stage.call("_apply_enemy_contact_damage", enemy)
	var after_one := float(stage.get("hero_hp"))
	stage.call("_apply_enemy_contact_damage", enemy)
	_expect(float(stage.get("hero_hp")) == after_one, "hurt cooldown should block same-frame dogpile")
	var stage_source: String = stage.get_script().get_source_code()
	_expect(stage_source.find("END_WAVE_SOFT_KILL_SECONDS") < 0, "final wave should have no forced KO timeout")
	_expect(stage_source.find("Vector2(430, 430) * s * draw_scale") >= 0, "KO animation should compensate for its padded canvas and match standing Blue Guy scale")
	_expect(stage_source.find("_blue_guy_ko_frame(elapsed_ko)") >= 0, "KO presentation should step through the generated death sequence")
	_expect(stage_source.find("down_wiggle") < 0, "settled Blue Guy death art should not receive procedural corpse wiggle")
	_expect(stage_source.find("_draw_alpha_rounded_rect(arena") < 0, "KO presentation should not cover the arena with a rectangular tint")
	stage.set("enemy_id", "giants")
	enemy["grabbed_hero"] = true
	stage.set("hero_flip_timer", 0.82)
	stage.call("_step_enemy_recovery", enemy, Vector2(0.5, 0.4), 0.20)
	_expect(is_equal_approx(float(stage.get("hero_flip_timer")), 0.82), "giant recovery must not double-decrement hero flip timer")
	var giant := {"pos": Vector2(0.42, 0.55), "attack_damage_done": true, "signature_t": 0.70, "roll_dir": Vector2.RIGHT}
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.call("_step_enemy_strike", giant, giant["pos"], Vector2.RIGHT, 0.01)
	_expect(bool(giant.get("grabbed_hero", false)), "near giant strike should grab the hero at signature frame")
	_expect(float(stage.get("hero_flip_timer")) > 0.0, "near giant strike should start the readable flip")
	stage.set("hero_flip_timer", 0.0)
	var far_giant := {"pos": Vector2(0.42, 0.55), "attack_damage_done": true, "signature_t": 0.70, "roll_dir": Vector2.RIGHT}
	stage.set("hero_pos", Vector2(0.90, 0.55))
	stage.call("_step_enemy_strike", far_giant, far_giant["pos"], Vector2.RIGHT, 0.01)
	_expect(not bool(far_giant.get("grabbed_hero", false)), "far giant strike should not grab a dodged hero")
	_expect(is_equal_approx(float(stage.get("hero_flip_timer")), 0.0), "far giant strike should not start the flip")


func _check_enemy_attack_displacement(stage: Control) -> void:
	var signatures := ["chicken-swarm", "goblins", "rouses", "werewolves", "vampires"]
	for id in signatures:
		stage.set("enemy_id", id)
		var actor := {"pos": Vector2(0.32, 0.55), "roll_dir": Vector2.ZERO, "attack_damage_done": true}
		var before := actor["pos"] as Vector2
		stage.call("_step_enemy_strike", actor, before, Vector2.RIGHT, 0.10)
		var after := actor.get("pos", before) as Vector2
		_expect(after.distance_to(before) > 0.001, "%s strike should displace the enemy" % id)
	stage.set("enemy_id", "chicken-swarm")
	stage.call("_load_enemy_attack_frames")
	var chicken_strike := {"attack_phase": "strike", "signature_t": 0.5, "variant": "white"}
	var chicken_frames := (stage.get("chicken_attack_variant_frames") as Dictionary).get("white", []) as Array
	_expect(chicken_frames.size() == 4 and stage.call("_enemy_attack_texture", chicken_strike) == chicken_frames[2], "Chicken strike should select attack frame 3")
	stage.set("hero_pos", Vector2(0.68, 0.55))
	stage.set("hero_hp", 100.0)
	stage.set("hero_hurt_cooldown", 0.0)
	var miss := {"pos": Vector2(0.50, 0.55), "roll_dir": Vector2.LEFT, "attack_damage_done": false, "damage": 20.0}
	stage.call("_step_enemy_strike", miss, miss["pos"], Vector2.LEFT, 0.50)
	_expect(float(stage.get("hero_hp")) == 100.0, "a strike that travels away should miss after the hero dodges")


func _check_vampire_identity(stage: Control) -> void:
	stage.set("enemy_id", "vampires")
	stage.set("active", true)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_hp", 100000.0)
	stage.set("hero_hurt_cooldown", 0.0)
	var actor := _identity_test_actor(Vector2(0.72, 0.55), Vector2.LEFT)
	actor["id"] = 7
	actor["vampire_attack_count"] = 0
	stage.call("_begin_enemy_attack", actor, Vector2.LEFT)
	var first_pos := actor.get("pos") as Vector2
	var target := actor.get("vampire_target_pos") as Vector2
	var first_dir := actor.get("roll_dir") as Vector2
	_expect(first_pos.distance_to(target) >= 0.16 and first_pos.distance_to(target) <= 0.19, "Vampire attack should save a flank at the requested distance")
	_expect(first_dir.dot((target - first_pos).normalized()) > 0.99, "Vampire flank should save a direction through the snapshotted hero")
	var repeat := actor.duplicate(true)
	stage.call("_begin_enemy_attack", repeat, Vector2.LEFT)
	_expect(signf(float(first_pos.x - target.x)) == -signf(float((repeat.get("pos") as Vector2).x - (repeat.get("vampire_target_pos") as Vector2).x)), "same Vampire should alternate flank sides")
	var stable := _identity_test_actor(Vector2(0.72, 0.55), Vector2.LEFT)
	stable["id"] = 7
	stable["vampire_attack_count"] = 0
	stage.call("_begin_enemy_attack", stable, Vector2.LEFT)
	_expect((stable.get("pos") as Vector2).is_equal_approx(first_pos), "stable Vampire actor state should choose a deterministic flank")

	actor["attack_phase"] = "strike"
	actor["attack_damage_done"] = false
	stage.set("hero_pos", target + Vector2(0.35, 0.0))
	stage.call("_step_enemy_strike", actor, first_pos, first_dir, 0.30)
	_expect(bool(actor.get("vampire_crossed", false)), "Vampire should cross its saved target plane once")
	_expect(float(stage.get("hero_hp")) == 100000.0, "Vampire crossing should miss a hero who moved off the saved path")
	stage.call("_step_enemy_strike", actor, actor.get("pos"), first_dir, 0.30)

	stage.set("hero_pos", target)
	stage.set("hero_hurt_cooldown", 0.0)
	var contact := _identity_test_actor(first_pos, first_dir)
	contact["id"] = 7
	contact["vampire_target_pos"] = target
	contact["vampire_crossed"] = false
	contact["attack_damage_done"] = false
	stage.call("_step_enemy_strike", contact, first_pos, first_dir, 0.30)
	var hp_after_hit := float(stage.get("hero_hp"))
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_step_enemy_strike", contact, contact.get("pos"), first_dir, 0.30)
	_expect(hp_after_hit < 100000.0 and float(stage.get("hero_hp")) == hp_after_hit, "Vampire contact damage should be capped at one hit")
	var recovery_before := contact.get("pos") as Vector2
	stage.call("_step_enemy_recovery", contact, recovery_before, 0.20)
	var recovery_after := contact.get("pos") as Vector2
	_expect((recovery_after - target).dot(first_dir) > (recovery_before - target).dot(first_dir), "Vampire recovery should continue outward along its saved direction")

	var interrupted := _identity_test_actor(first_pos, first_dir)
	interrupted["id"] = 7
	interrupted["vampire_target_pos"] = target
	interrupted["attack_phase"] = "windup"
	interrupted["attack_timer"] = 0.40
	interrupted["attack_duration"] = 0.40
	stage.set("hero_pos", target)
	stage.set("hero_hp", 100000.0)
	stage.call("_stagger_enemy", interrupted)
	_expect(not bool(interrupted.get("vampire_crossed", false)) and float(stage.get("hero_hp")) == 100000.0, "Vampire wind-up interrupt should prevent crossing and damage")
	interrupted["attack_phase"] = "windup"
	interrupted["attack_timer"] = 0.01
	interrupted["attack_duration"] = 0.01
	interrupted["attack_damage_done"] = false
	interrupted["stagger_timer"] = 0.0
	stage.call("_step_chicken", interrupted, 0.05)
	stage.call("_step_chicken", interrupted, 0.30)
	_expect(bool(interrupted.get("vampire_crossed", false)), "protected Vampire retry should complete its saved cross")


func _check_dragon_cycle(stage: Control) -> void:
	stage.set("enemy_id", "dragons")
	stage.set("active", true)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_hp", 100000.0)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("setup_fighting_level", 99)
	var dragon_scale := float(stage.call("_enemy_sprite_scale_for_id", "dragons"))
	_expect(dragon_scale >= 2.2 and dragon_scale <= 2.5, "dragon render scale should stay boss-sized without obscuring the arena")
	var approach := _dragon_test_actor(Vector2(0.08, 0.55), "brawl")
	approach["speed"] = 0.40
	approach["attack_cd"] = 999.0
	var approach_before := (approach["pos"] as Vector2).distance_to(stage.get("hero_pos"))
	stage.call("_step_chicken", approach, 0.50)
	_expect((approach.get("pos") as Vector2).distance_to(stage.get("hero_pos")) < approach_before, "dragon close approach should reduce distance")

	var far := _dragon_test_actor(Vector2(0.82, 0.55), "brawl")
	far["speed"] = 0.0
	far["attack_cd"] = 0.0
	stage.call("_step_chicken", far, 0.05)
	_expect(str(far.get("attack_phase", "")) == "", "dragon brawl should not begin from distance")
	var close := _dragon_test_actor(Vector2(0.70, 0.55), "brawl")
	close["speed"] = 0.0
	close["attack_cd"] = 0.0
	stage.call("_step_chicken", close, 0.05)
	_expect(str(close.get("attack_phase", "")) == "windup", "dragon brawl should begin only in short range")
	stage.call("_stagger_enemy", close)
	_expect(str(close.get("attack_phase", "")) == "stagger", "dragon first brawl wind-up should be interruptible")
	close["attack_phase"] = "windup"
	close["stagger_timer"] = 0.0
	stage.call("_stagger_enemy", close)
	_expect(str(close.get("attack_phase", "")) == "windup", "dragon protected retry should not be interrupted")
	close["attack_timer"] = 0.01
	close["attack_duration"] = 0.01
	stage.call("_step_chicken", close, 0.05)
	for _frame in range(105):
		if str(close.get("attack_phase", "")) == "recovery":
			break
		stage.call("_step_chicken", close, 0.05)
	_expect(str(close.get("attack_phase", "")) == "recovery", "dragon protected brawl retry should complete")

	var dragon := _dragon_test_actor(Vector2(0.70, 0.55), "brawl")
	dragon["speed"] = 0.40
	dragon["attack_cd"] = 0.0
	var saw_brawl := false
	var saw_brawl_strike := false
	var close_distance := 0.0
	var saw_retreat := false
	var retreat_start_distance := -1.0
	var retreat_max_distance := 0.0
	var saw_breath := false
	var saw_breath_strike := false
	var saw_reentry := false
	var breath_direction := Vector2.ZERO
	for _frame in range(240):
		stage.call("_step_chicken", dragon, 0.05)
		var phase := str(dragon.get("attack_phase", ""))
		var kind := str(dragon.get("dragon_attack_kind", ""))
		var distance := (dragon.get("pos") as Vector2).distance_to(stage.get("hero_pos"))
		if kind == "brawl" and phase == "windup" and not saw_brawl:
			saw_brawl = true
			close_distance = distance
		if kind == "brawl" and phase == "strike":
			saw_brawl_strike = true
		if kind == "brawl" and saw_brawl_strike and phase == "recovery" and distance > close_distance + 0.01:
			saw_retreat = true
			if retreat_start_distance < 0.0:
				retreat_start_distance = distance
			retreat_max_distance = maxf(retreat_max_distance, distance)
		if kind == "breath" and phase == "windup":
			saw_breath = distance >= 0.39
			breath_direction = dragon.get("breath_dir", Vector2.ZERO) as Vector2
		if kind == "breath" and phase == "strike":
			saw_breath_strike = true
		if saw_breath_strike and kind == "brawl" and phase == "windup" and distance <= 0.24:
			saw_reentry = true
			break
	_expect(saw_brawl and saw_brawl_strike, "dragon cycle should reach its close brawl strike")
	_expect(close_distance <= 0.24, "dragon brawl should begin at a genuinely close center distance")
	_expect(saw_retreat, "dragon brawl recovery should increase separation")
	_expect(saw_breath, "dragon breath should begin from distance")
	_expect(retreat_max_distance - close_distance >= 0.14, "dragon retreat should add meaningful separation before breath")
	_expect(breath_direction.length() > 0.001, "dragon breath should save a nonzero direction")
	_expect(saw_breath_strike, "dragon breath should complete its strike")
	_expect(saw_reentry, "dragon cycle should return to close re-entry")

	stage.set("hero_hurt_cooldown", 0.0)
	stage.set("hero_hp", 100000.0)
	var centered := _dragon_test_actor(Vector2(0.25, 0.55), "breath")
	centered["attack_phase"] = "strike"
	centered["breath_dir"] = Vector2.RIGHT
	centered["roll_dir"] = Vector2.RIGHT
	stage.call("_step_enemy_strike", centered, centered["pos"], Vector2.RIGHT, 0.05)
	_expect(float(stage.get("hero_hp")) < 100000.0, "hero centered in dragon breath lane should take damage")
	stage.set("hero_hurt_cooldown", 0.0)
	stage.set("hero_hp", 100000.0)
	var off_axis := _dragon_test_actor(Vector2(0.25, 0.55), "breath")
	off_axis["attack_phase"] = "strike"
	off_axis["breath_dir"] = Vector2.RIGHT
	off_axis["roll_dir"] = Vector2.RIGHT
	stage.set("hero_pos", Vector2(0.50, 0.82))
	stage.call("_step_enemy_strike", off_axis, off_axis["pos"], Vector2.RIGHT, 0.05)
	_expect(is_equal_approx(float(stage.get("hero_hp")), 100000.0), "clearly off-axis hero should miss dragon breath")
	stage.set("hero_hp", stage.call("_hero_max_hp"))
	stage.set("hero_hurt_cooldown", 0.0)
	var cap_actor := _dragon_test_actor(Vector2(0.50, 0.55), "brawl")
	cap_actor["damage"] = 100000.0
	stage.call("_apply_enemy_contact_damage", cap_actor)
	_expect(is_zero_approx(float(stage.get("hero_hp"))), "dragon damage should use its authored value without a health-percentage cap")


func _dragon_test_actor(pos: Vector2, kind: String) -> Dictionary:
	return {
		"id": 1,
		"pos": pos,
		"hp": 100000.0,
		"max_hp": 100000.0,
		"attack_cd": 0.0,
		"speed": 0.40,
		"damage": 230.0,
		"attack_phase": "",
		"attack_timer": 0.0,
		"attack_duration": 0.0,
		"attack_damage_done": false,
		"stagger_timer": 0.0,
		"interrupt_protected": false,
		"signature_t": 0.0,
		"roll_dir": Vector2.ZERO,
		"breath_dir": Vector2.ZERO,
		"dragon_attack_kind": kind,
		"dragon_next_attack_kind": "breath" if kind == "brawl" else "brawl",
		"wall_hit": false,
		"hit_flash": 0.0,
		"dead_timer": 0.0,
		"lunge_timer": 0.0,
		"lunge_dir": Vector2.ZERO
	}


func _check_population_caps(stage: Control) -> void:
	stage.set("end_wave_active", false)
	stage.set("wave_index", 4)
	for profile in [
		{"id": "guys", "curve": [16, 20, 24, 28, 32], "cap": 24, "total": 32},
		{"id": "goblins", "curve": [2, 3, 3, 4, 5], "cap": 3, "total": 5}
	]:
		stage.set("enemy_id", profile["id"])
		stage.set("enemy_population_curve", profile["curve"])
		stage.set("enemy_population_cap", profile["cap"])
		_expect(int(stage.call("_wave_spawn_total_for_wave")) == profile["total"], "%s wave should keep its total entrants" % profile["id"])
		_expect(int(stage.call("_max_chickens_for_wave")) == profile["total"], "%s fixed wave five should admit its full entrant count" % profile["id"])
	stage.set("enemy_final_population", 5)
	stage.set("end_wave_active", true)
	_expect(int(stage.call("_wave_spawn_total_for_wave")) == 5, "final wave should keep explicit entrant total")
	_expect(int(stage.call("_max_chickens_for_wave")) == 3, "final wave should still enforce its simultaneous cap")


func _check_goblin_shield(stage: Control, scene: Node) -> void:
	var action := scene.call("_action_data", "fight", "fight-goblins") as Dictionary
	stage.call("setup_action", action)
	stage.call("setup_fighting_level", 16)
	stage.call("set_active_fight", true)
	_expect(stage.get("goblin_shield") != null, "goblin shield texture should load")
	stage.call("_spawn_chicken", 0)
	_expect(bool((stage.get("chickens") as Array)[-1].get("shield_up", false)), "spawned goblin should seed one shield")
	(stage.get("chickens") as Array).clear()
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_uppercut_cd", 999.0)
	var goblin := {
		"id": 1,
		"pos": Vector2(0.62, 0.55),
		"hp": 1000.0,
		"max_hp": 1000.0,
		"attack_cd": 999.0,
		"speed": 0.0,
		"damage": 1.0,
		"attack_phase": "windup",
		"attack_timer": 0.2,
		"attack_duration": 0.2,
		"attack_damage_done": false,
		"stagger_timer": 0.0,
		"interrupt_protected": false,
		"signature_t": 0.0,
		"roll_dir": Vector2.ZERO,
		"wall_hit": false,
		"uppercut_knock_timer": 0.0,
		"uppercut_pop": 0.0,
		"hit_flash": 0.0,
		"dead_timer": 0.0,
		"shield_up": true,
		"shield_fall_timer": 0.0,
		"shield_fall_direction": Vector2.ZERO,
		"shield_fall_rotation": 0.0
	}
	(stage.get("chickens") as Array).append(goblin)
	var hp_before := float(goblin["hp"])
	var first_hit := bool(stage.call("_start_hero_attack"))
	_expect(first_hit, "goblin shield block should count as a landed punch")
	_expect(float(goblin.get("hp")) == hp_before, "first goblin punch should leave HP unchanged")
	_expect(not bool(goblin.get("shield_up")), "first goblin punch should detach the shield")
	_expect(float(goblin.get("shield_fall_timer")) > 0.0, "detached shield should have a falling timer")
	_expect(str(goblin.get("attack_phase", "")) == "windup", "blocked punch should not stagger the goblin")
	var second_hit := bool(stage.call("_start_hero_attack"))
	_expect(second_hit and float(goblin.get("hp")) < hp_before, "second goblin punch should use normal damage")
	_expect(str(goblin.get("attack_phase", "")) == "stagger", "second goblin punch should use normal interrupt rules")
	var fall_rotation := float(goblin.get("shield_fall_rotation"))
	var drop_pos := goblin.get("shield_drop_pos") as Vector2
	stage.call("_step_chicken", goblin, 0.20)
	_expect(float(goblin.get("shield_fall_timer")) < 2.06, "falling shield timer should advance")
	_expect(float(goblin.get("shield_fall_rotation")) == fall_rotation, "falling shield rotation should persist during tumble")
	stage.call("_step_chicken", goblin, 0.40)
	_expect(float(goblin.get("shield_fall_timer")) > 1.60, "fallen shield should remain after both bounces")
	_expect((goblin.get("shield_drop_pos") as Vector2).is_equal_approx(drop_pos), "fallen shield should stay anchored to its drop point")
	stage.call("_step_chicken", goblin, 1.70)
	_expect(float(goblin.get("shield_fall_timer")) == 0.0, "fallen shield should fade after the shared death lifetime")
	_expect((goblin.get("shield_fall_direction", Vector2.ONE) as Vector2) == Vector2.ZERO, "finished shield fall should clear its direction")
	var chicken_action := scene.call("_action_data", "fight", "fight-chickens") as Dictionary
	stage.call("setup_action", chicken_action)
	stage.call("_seed_fight")
	stage.call("_spawn_chicken", 0)
	_expect(not bool((stage.get("chickens") as Array)[-1].get("shield_up", false)), "non-goblin actor should not seed a shield")

	stage.call("setup_action", action)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_uppercut_cd", 0.0)
	var uppercut_goblin := goblin.duplicate()
	var uppercut_hit := false
	for candidate_seed in range(128):
		seed(candidate_seed)
		uppercut_goblin = goblin.duplicate()
		uppercut_goblin["hp"] = 1000.0
		uppercut_goblin["shield_up"] = true
		uppercut_goblin["attack_phase"] = "windup"
		uppercut_goblin["stagger_timer"] = 0.0
		uppercut_goblin["interrupt_protected"] = false
		uppercut_goblin["shield_fall_timer"] = 0.0
		(stage.get("chickens") as Array).clear()
		(stage.get("chickens") as Array).append(uppercut_goblin)
		uppercut_hit = bool(stage.call("_start_hero_attack"))
		if bool(stage.get("hero_attack_is_uppercut")):
			break
	var uppercut_hp_before := 1000.0
	_expect(uppercut_hit and bool(stage.get("hero_attack_is_uppercut")), "deterministic goblin uppercut should land")
	_expect(float(uppercut_goblin.get("hp")) == uppercut_hp_before, "first goblin uppercut should leave HP unchanged")
	_expect(not bool(uppercut_goblin.get("shield_up")), "uppercut should detach the goblin shield")
	_expect(str(uppercut_goblin.get("attack_phase", "")) == "windup", "blocked uppercut should not stagger the goblin")

	stage.set("hero_uppercut_cd", 999.0)
	var target := goblin.duplicate()
	target["pos"] = Vector2(0.62, 0.55)
	target["hp"] = 1000.0
	target["shield_up"] = false
	var forward_bystander := target.duplicate()
	forward_bystander["pos"] = Vector2(0.66, 0.55)
	var wide_bystander := target.duplicate()
	wide_bystander["pos"] = Vector2(0.62, 0.65)
	var outside_bystander := target.duplicate()
	outside_bystander["pos"] = Vector2(0.90, 0.55)
	var behind_bystander := target.duplicate()
	behind_bystander["pos"] = Vector2(0.37, 0.55)
	(stage.get("chickens") as Array).clear()
	(stage.get("chickens") as Array).append_array([target, forward_bystander, wide_bystander, outside_bystander, behind_bystander])
	_expect(bool(stage.call("_start_hero_attack")), "Goblin punch should land")
	_expect(float(target.get("hp")) < 1000.0 and float(forward_bystander.get("hp")) < 1000.0, "Goblin punch should damage every stacked target intersecting its hit circle")
	_expect(float(wide_bystander.get("hp")) == 1000.0 and float(outside_bystander.get("hp")) == 1000.0 and float(behind_bystander.get("hp")) == 1000.0, "Goblin punch should not damage targets beside, outside, or behind its hit circle")
	stage.set("hero_attack_is_uppercut", true)
	stage.set("hero_attack_dir", Vector2.RIGHT)
	_expect(bool(stage.call("_chicken_inside_current_punch", forward_bystander.get("pos"))), "uppercut should retain its forward crowd reach")
	_expect(not bool(stage.call("_chicken_inside_current_punch", behind_bystander.get("pos"))), "uppercut should never hit behind the hero")


func _check_giant_identity(stage: Control, scene: Node) -> void:
	var action := scene.call("_action_data", "fight", "fight-giants") as Dictionary
	stage.call("setup_action", action)
	stage.call("setup_fighting_level", 74)
	stage.call("set_active_fight", true)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_hp", 100000.0)
	stage.set("hero_hurt_cooldown", 999.0)
	(stage.get("chickens") as Array).clear()
	for label in stage.get("float_labels") as Array:
		label.visible = false
	var giant := _giant_test_actor(Vector2(0.62, 0.55))
	(stage.get("chickens") as Array).append(giant)
	stage.call("_step_enemy_strike", giant, giant["pos"], Vector2.LEFT, 0.01)
	_expect(bool(giant.get("grabbed_hero", false)), "in-range Giant strike should grab the hero")
	_expect(float(stage.get("hero_flip_timer")) > 0.0, "in-range Giant strike should start the flip")
	_expect(bool(stage.get("hero_flip_attack_blocked")), "Giant grab should arm exactly one attack denial")

	stage.set("hero_attack_cd", 0.0)
	stage.set("hero_attack_timer", 0.0)
	stage.set("hero_attack_is_uppercut", false)
	stage.set("hero_uppercut_cd", 999.0)
	var hp_before := float(giant.get("hp"))
	var denied := bool(stage.call("_start_hero_attack"))
	_expect(not denied, "Giant denial should reject the first hero attack attempt")
	_expect(not bool(stage.get("hero_flip_attack_blocked")), "Giant denial should consume its token")
	_expect(is_equal_approx(float(giant.get("hp")), hp_before), "Giant denial should not damage the target")
	_expect(is_zero_approx(float(stage.get("hero_attack_timer"))) and not bool(stage.get("hero_attack_is_uppercut")), "Giant denial should not start attack or uppercut side effects")
	_expect(is_equal_approx(float(stage.get("hero_attack_cd")), float(stage.call("_hero_attack_interval"))), "Giant denial should start the normal attack cooldown")
	_expect(_visible_float_count(stage, "STUNNED!") == 1, "Giant denial should show exactly one STUNNED! cue")
	stage.set("hero_attack_cd", 0.0)
	var landed := bool(stage.call("_start_hero_attack"))
	_expect(landed and float(giant.get("hp")) < hp_before, "the second Giant attack attempt should land normally")
	_expect(_visible_float_count(stage, "STUNNED!") == 1, "the second Giant attack should not add another STUNNED! cue")

	(stage.get("chickens") as Array).clear()
	stage.set("hero_flip_timer", 0.0)
	stage.set("hero_flip_attack_blocked", false)
	var far_giant := _giant_test_actor(Vector2(0.90, 0.55))
	(stage.get("chickens") as Array).append(far_giant)
	stage.call("_step_enemy_strike", far_giant, far_giant["pos"], Vector2.LEFT, 0.01)
	_expect(not bool(far_giant.get("grabbed_hero", false)) and is_zero_approx(float(stage.get("hero_flip_timer"))) and not bool(stage.get("hero_flip_attack_blocked")), "out-of-range Giant strike should not grab or arm")

	(stage.get("chickens") as Array).clear()
	stage.set("hero_flip_timer", 0.0)
	stage.set("hero_flip_attack_blocked", false)
	var interrupted := _giant_test_actor(Vector2(0.62, 0.55))
	interrupted["attack_phase"] = "windup"
	interrupted["attack_timer"] = 0.20
	interrupted["attack_duration"] = 0.20
	(stage.get("chickens") as Array).append(interrupted)
	stage.call("_stagger_enemy", interrupted)
	_expect(str(interrupted.get("attack_phase", "")) == "stagger" and not bool(stage.get("hero_flip_attack_blocked")), "interrupted Giant windup should not arm the denial")
	interrupted["attack_phase"] = "windup"
	interrupted["attack_timer"] = 0.05
	interrupted["attack_duration"] = 0.05
	interrupted["stagger_timer"] = 0.0
	interrupted["interrupt_protected"] = true
	for _frame in range(20):
		stage.call("_step_chicken", interrupted, 0.05)
		if bool(stage.get("hero_flip_attack_blocked")):
			break
	_expect(bool(stage.get("hero_flip_attack_blocked")), "protected Giant retry should complete and arm the denial")

	for level in [74, 99]:
		var natural_stage := Stage.new()
		natural_stage.size = Vector2(1080.0, 1080.0)
		natural_stage.set("arena_shape", "diamond")
		root.add_child(natural_stage)
		natural_stage.call("setup_action", action)
		natural_stage.call("setup_fighting_level", level)
		natural_stage.call("set_active_fight", true)
		natural_stage.set("hero_pos", Vector2(0.50, 0.55))
		var saw_grab := false
		var denial_count := 0
		var token_armed := false
		for _frame in range(1800):
			natural_stage.call("_process", 1.0 / 60.0)
			for raw_actor in natural_stage.get("chickens") as Array:
				if bool((raw_actor as Dictionary).get("grabbed_hero", false)):
					saw_grab = true
			var token_now := bool(natural_stage.get("hero_flip_attack_blocked"))
			if token_now:
				token_armed = true
			elif token_armed:
				denial_count += 1
				token_armed = false
			if saw_grab and denial_count == 1:
				break
		_expect(saw_grab and denial_count == 1, "level-%d stationary Giant loop should naturally grab and consume exactly one denial" % level)
		natural_stage.queue_free()


func _giant_test_actor(pos: Vector2) -> Dictionary:
	var actor := _identity_test_actor(pos, Vector2.LEFT)
	actor["signature_t"] = 0.70
	actor["grabbed_hero"] = false
	return actor


func _check_guys_guard(stage: Control, scene: Node) -> void:
	var action := scene.call("_action_data", "fight", "fight-guys") as Dictionary
	stage.call("setup_action", action)
	stage.call("setup_fighting_level", 32)
	stage.call("set_active_fight", true)
	stage.set("enemy_id", "guys")
	stage.set("hero_pos", Vector2(0.50, 0.55))
	var guys_curve := stage.get("enemy_population_curve") as Array
	_expect(guys_curve.size() == 5 and int(guys_curve[0]) == 16 and int(guys_curve[-1]) == 32 and int(stage.get("enemy_population_cap")) == 24 and int(stage.get("enemy_final_population")) == 40, "Guys should load their doubled crowd profile")
	_expect(is_equal_approx(float(stage.get("enemy_spawn_rhythm")), 0.275), "Doubled Guys crowd should spawn twice as quickly")
	_expect(is_equal_approx(float(stage.get("enemy_speed_scale")), 1.40), "Guys should load their faster shared walk/run speed")
	_expect(is_equal_approx(float(stage.get("enemy_base_hp_max")), 59.0 * 1.15) and is_equal_approx(float(stage.get("enemy_damage")), 6.0), "Each Guy should load the wave-one mortality-tuned health and damage")
	stage.call("_spawn_chicken", 0)
	var eager_guy := (stage.get("chickens") as Array)[-1] as Dictionary
	_expect(is_equal_approx(float(eager_guy.get("attack_cd", 0.0)), 0.10) and is_equal_approx(float(stage.call("_enemy_attack_cooldown")), 0.45), "Guys should attack immediately and keep jabbing quickly")
	(stage.get("chickens") as Array).clear()
	_expect(int(stage.get("planned_kill_count")) == 160 and int(stage.get("combat_reward_xp")) == 58, "Doubled Guys should split the same XP budget across twice as many kills")

	var frame_target := Vector2(172.0, 156.0)
	var frame_heights: Array[float] = []
	var guys_frames: Array = [stage.get("idle_chicken"), stage.get("hit_chicken"), stage.get("dizzy_chicken")]
	guys_frames.append_array((stage.get("enemy_attack_frames") as Dictionary).get("guys-attack", []) as Array)
	var movement_frames := stage.get("enemy_movement_frames") as Dictionary
	var walk_frames := movement_frames.get("guys", []) as Array
	var run_frames := movement_frames.get("guys-run", []) as Array
	guys_frames.append_array(walk_frames)
	guys_frames.append_array(run_frames)
	_expect(walk_frames.size() == 4 and run_frames.size() == 6, "Guys run should mix four sprint poses with two less-splayed walk poses")
	_expect(run_frames[1] == walk_frames[2] and run_frames[4] == walk_frames[0], "Guys run should recover through walk frames 03 and 01")
	for texture in guys_frames:
		var normalized_size := frame_target * float(stage.call("_guys_frame_scale", texture, frame_target))
		frame_heights.append((stage.call("_texture_content_rect", texture, normalized_size) as Rect2).size.y)
	_expect(frame_heights.size() == 17 and frame_heights.max() - frame_heights.min() < 1.0, "Guys idle, hit, dizzy, attack, walk, and run frames should keep one normalized visual height")
	var walk_actor := _guys_test_actor(false)
	_expect(walk_frames.has(stage.call("_movement_texture", walk_actor)), "A normally moving Guy should use the walk animation")
	walk_actor["punch_flee_timer"] = 0.50
	_expect(run_frames.has(stage.call("_movement_texture", walk_actor)), "A fleeing Guy should use the faster run animation")
	_expect((stage.get_script().get_source_code() as String).contains('"HP %d" % int(round(hero_hp))'), "Fight HUD should show current HP so enemy damage is visible")
	var standing_size := frame_target * float(stage.get("enemy_sprite_scale"))
	standing_size *= float(stage.call("_guys_frame_scale", stage.get("idle_chicken"), standing_size))
	var standing_height := (stage.call("_texture_content_rect", stage.get("idle_chicken"), standing_size) as Rect2).size.y
	var defeated_size := frame_target * float(stage.get("enemy_sprite_scale")) * float(stage.call("_enemy_death_scale_for_id", "guys"))
	var defeated_width := (stage.call("_texture_content_rect", stage.get("defeated_chicken"), defeated_size) as Rect2).size.x
	_expect(absf(defeated_width - standing_height) / standing_height < 0.02, "Defeated Guy body length should match a standing Guy's height")

	var hit_actor := _guys_test_actor(false)
	hit_actor["pos"] = Vector2(0.62, 0.55)
	var near_miss_actor := _guys_test_actor(true)
	near_miss_actor["id"] = 2
	near_miss_actor["pos"] = Vector2(0.59, 0.84)
	near_miss_actor["speed"] = 0.20
	var behind_actor := _guys_test_actor(false)
	behind_actor["id"] = 3
	behind_actor["pos"] = Vector2(0.36, 0.55)
	var committed_actor := _guys_test_actor(false)
	committed_actor["id"] = 4
	committed_actor["pos"] = Vector2(0.55, 0.72)
	(stage.get("chickens") as Array).clear()
	(stage.get("chickens") as Array).append_array([hit_actor, near_miss_actor, behind_actor, committed_actor])
	stage.set("hero_uppercut_cd", 999.0)
	var hit_hp_before := float(hit_actor.get("hp", 0.0))
	_expect(bool(stage.call("_start_hero_attack")), "Guys near-miss test punch should land")
	var punched := (stage.get("chickens") as Array)[0] as Dictionary
	var fleeing := (stage.get("chickens") as Array)[1] as Dictionary
	var behind := (stage.get("chickens") as Array)[2] as Dictionary
	var committed := (stage.get("chickens") as Array)[3] as Dictionary
	_expect(is_equal_approx(float(stage.call("_enemy_attack_range", committed)), 0.26) and is_equal_approx(float(stage.call("_enemy_contact_range", committed)), 0.22), "Guys should commit outside contact range and jab forward")
	_expect(float(punched.get("hp", 0.0)) < hit_hp_before and float(punched.get("punch_flee_timer", 0.0)) <= 0.0, "A punched Guy should take the hit instead of fleeing")
	var flee_dir := fleeing.get("punch_flee_dir", Vector2.ZERO) as Vector2
	var flee_radial := ((fleeing.get("pos", Vector2.ZERO) as Vector2) - (stage.get("hero_pos") as Vector2)).normalized()
	var flee_duration := float(fleeing.get("punch_flee_timer", 0.0))
	var flee_speed := float(fleeing.get("punch_flee_speed", 0.0))
	_expect(flee_duration >= 0.60 and flee_duration <= 0.80 and flee_speed >= 1.15 and flee_speed <= 1.35 and absf(flee_dir.dot(flee_radial)) < 0.001, "A close Guy outside the punch should flee sideways with randomized duration and speed")
	_expect(float(behind.get("punch_flee_timer", 0.0)) <= 0.0, "A Guy behind Blue Guy should not react to a forward punch")
	_expect(float(committed.get("punch_flee_timer", 0.0)) <= 0.0, "A Guy already inside attack range should keep advancing instead of fleeing")
	for _flee_step in range(3):
		var flee_pos_before := fleeing.get("pos", Vector2.ZERO) as Vector2
		var flee_radial_before := (flee_pos_before - (stage.get("hero_pos") as Vector2)).normalized()
		stage.call("_step_chicken", fleeing, 0.10)
		var flee_travel := (fleeing.get("pos", Vector2.ZERO) as Vector2) - flee_pos_before
		_expect(flee_travel.length() > 0.02 and absf(flee_travel.normalized().dot(flee_radial_before)) < 0.001 and str(fleeing.get("attack_phase", "")).is_empty(), "A scared Guy should keep running sideways without starting an attack")
	var jab := _guys_test_actor(false)
	jab["pos"] = Vector2(0.76, 0.55)
	jab["roll_dir"] = Vector2.LEFT
	jab["attack_damage_done"] = true
	stage.call("_step_enemy_strike", jab, jab["pos"], Vector2.LEFT, 0.10)
	_expect((jab.get("pos") as Vector2).x < 0.72, "Guys jab should lunge forward into contact")
	stage.set("wave_spawn_remaining", 0)
	stage.set("wave_rest_timer", 1.0)
	stage.set("end_wave_active", false)
	stage.set("hero_attack_cd", 999.0)
	(stage.get("chickens") as Array).clear()
	(stage.get("chickens") as Array).append(_guys_test_actor(false))
	stage.call("_step_fight", 0.10)
	_expect(is_equal_approx(float(stage.get("wave_rest_timer")), 1.0), "Guys wave should wait while its crowd is still alive")
	(stage.get("chickens") as Array).clear()
	stage.call("_step_fight", 0.10)
	_expect(float(stage.get("wave_rest_timer")) < 1.0, "Guys wave rest should begin after its crowd is defeated")

	var counter := _guys_test_actor(true)
	counter["pos"] = Vector2(0.62, 0.55)
	counter["hp"] = 100.0
	counter["max_hp"] = 100.0
	(stage.get("chickens") as Array).clear()
	(stage.get("chickens") as Array).append(counter)
	stage.set("hero_uppercut_cd", 999.0)
	_expect(bool(stage.call("_start_hero_attack")), "A guarded Guy counter test punch should land")
	counter = (stage.get("chickens") as Array)[0] as Dictionary
	_expect(str(counter.get("attack_phase", "")) == "windup" and is_equal_approx(float(counter.get("attack_timer", 0.0)), 0.18) and bool(counter.get("interrupt_protected", false)), "A surviving guard should start a fast protected counterpunch")
	stage.set("hero_hp", 100.0)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_step_chicken", counter, 0.19)
	stage.call("_step_chicken", counter, 0.05)
	_expect(float(stage.get("hero_hp")) < 100.0, "A guarded Guy's counterpunch should damage Blue Guy")

	var max_hp := float(stage.call("_hero_max_hp"))
	stage.set("hero_hp", max_hp)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_apply_enemy_contact_damage", {"damage": 1.0, "guarding": false})
	var unguarded_outgoing_loss := max_hp - float(stage.get("hero_hp"))
	stage.set("hero_hp", max_hp)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_apply_enemy_contact_damage", {"damage": 1.0, "guarding": true})
	var guarded_outgoing_loss := max_hp - float(stage.get("hero_hp"))
	_expect(is_equal_approx(guarded_outgoing_loss, unguarded_outgoing_loss), "guarded Guys should deal the same outgoing damage")
	stage.set("hero_hp", max_hp)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_apply_enemy_contact_damage", {"damage": 999.0})
	_expect(is_zero_approx(float(stage.get("hero_hp"))), "Guys crowd hits should use authored damage without a health-percentage cap")
	_expect(is_zero_approx(float(stage.get("hero_hurt_cooldown"))), "Guys should not share a crowd-wide hit lockout")

	var normal_seed := 4127
	var unguarded_normal_loss := _guys_hit_loss(stage, false, false, normal_seed)
	var guarded_normal_loss := _guys_hit_loss(stage, true, false, normal_seed)
	_expect(unguarded_normal_loss > 0.0 and guarded_normal_loss > 0.0, "normal Guys hits should both deal damage")
	_expect(absf(guarded_normal_loss - unguarded_normal_loss * 0.72) <= 0.001, "guarded normal Guys damage should be 72%%")

	var uppercut_seed := -1
	for candidate_seed in range(9000, 9128):
		seed(candidate_seed)
		stage.set("hero_uppercut_cd", 0.0)
		(stage.get("chickens") as Array).clear()
		(stage.get("chickens") as Array).append(_guys_test_actor(false))
		stage.call("_start_hero_attack")
		if bool(stage.get("hero_attack_is_uppercut")):
			uppercut_seed = candidate_seed
			break
	_expect(uppercut_seed >= 0, "deterministic Guys uppercut seed should be found")
	var unguarded_uppercut_loss := _guys_hit_loss(stage, false, true, uppercut_seed)
	var guarded_uppercut_loss := _guys_hit_loss(stage, true, true, uppercut_seed)
	_expect(unguarded_uppercut_loss > 0.0 and guarded_uppercut_loss > 0.0, "uppercut Guys hits should both deal damage")
	_expect(absf(guarded_uppercut_loss - unguarded_uppercut_loss * 0.72) <= 0.001, "guarded uppercut Guys damage should be 72%%")

	var frozen_guard := _guys_test_actor(true)
	frozen_guard["id"] = 0
	frozen_guard["pos"] = Vector2(0.80, 0.55)
	stage.set("elapsed_seconds", 0.0)
	stage.call("_step_chicken", frozen_guard, 0.01)
	_expect(bool(frozen_guard.get("guarding", false)), "Guys guard should sample during approach")
	stage.set("elapsed_seconds", 1.20)
	frozen_guard["attack_phase"] = "windup"
	frozen_guard["attack_timer"] = 0.40
	frozen_guard["attack_duration"] = 0.40
	stage.call("_step_chicken", frozen_guard, 0.05)
	_expect(bool(frozen_guard.get("guarding", false)), "Guys guard should remain frozen during committed windup")

	stage.call("_begin_enemy_attack", frozen_guard, Vector2.LEFT)
	_expect(is_equal_approx(float(frozen_guard.get("attack_timer", 0.0)), 0.18), "Guys should commit with the fast jab windup")
	frozen_guard["attack_phase"] = "windup"
	stage.call("_stagger_enemy", frozen_guard)
	_expect(bool(frozen_guard.get("interrupt_protected", false)) and str(frozen_guard.get("attack_phase", "")) == "windup", "Guys committed windup should survive a normal punch")
	frozen_guard["attack_phase"] = "strike"
	frozen_guard["attack_timer"] = 0.01
	frozen_guard["attack_duration"] = 0.01
	stage.call("_step_chicken", frozen_guard, 0.05)
	_expect(str(frozen_guard.get("attack_phase", "")) == "recovery", "guarded Guys protected retry should complete")


func _guys_hit_loss(stage: Control, guarding: bool, uppercut: bool, seed_value: int) -> float:
	seed(seed_value)
	var actor := _guys_test_actor(guarding)
	(stage.get("chickens") as Array).clear()
	for label in stage.get("float_labels") as Array:
		label.visible = false
	stage.set("hero_hp", 100000.0)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.set("hero_uppercut_cd", 0.0 if uppercut else 999.0)
	(stage.get("chickens") as Array).append(actor)
	var before := float(actor.get("hp", 0.0))
	var landed := bool(stage.call("_start_hero_attack"))
	_expect(landed and (not uppercut or bool(stage.get("hero_attack_is_uppercut"))), "Guys attack should land deterministically")
	return before - float(actor.get("hp", 0.0))


func _check_rouses_werewolves_identity(stage: Control) -> void:
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_hp", 100000.0)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.set("enemy_id", "rouses")
	var rolling := _identity_test_actor(Vector2(0.32, 0.55), Vector2.RIGHT)
	rolling["attack_damage_done"] = true
	var rolling_before := rolling["pos"] as Vector2
	stage.call("_step_enemy_strike", rolling, rolling["pos"], Vector2.LEFT, 0.05)
	_expect((rolling["pos"] as Vector2).x > rolling_before.x, "R.O.U.S.es roll should use its saved direction")
	var waiting := _identity_test_actor(Vector2(0.62, 0.55), Vector2.LEFT)
	waiting["attack_phase"] = ""
	waiting["attack_cd"] = 0.50
	waiting["speed"] = 0.20
	var waiting_pos := waiting["pos"] as Vector2
	stage.call("_step_chicken", waiting, 0.10)
	_expect((waiting["pos"] as Vector2).is_equal_approx(waiting_pos), "R.O.U.S.es should hold inside attack range instead of crossing and circling the hero")
	waiting["attack_cd"] = 0.0
	stage.call("_step_chicken", waiting, 0.01)
	_expect(str(waiting.get("attack_phase", "")) == "windup", "waiting R.O.U.S.es should attack when their cooldown expires")

	var crash := _identity_test_actor(Vector2(0.90, 0.55), Vector2.RIGHT)
	crash["roll_origin"] = crash["pos"]
	crash["attack_damage_done"] = true
	crash["attack_timer"] = 0.10
	crash["attack_duration"] = 0.10
	stage.call("_step_chicken", crash, 0.10)
	_expect(str(crash.get("attack_phase", "")) == "recovery" and is_zero_approx(float(crash.get("stagger_timer", 0.0))) and bool(crash.get("rouses_crashed", false)), "R.O.U.S.es hard stage-edge collision should bounce into recovery")
	_expect(bool(crash.get("wall_hit", false)) == false, "R.O.U.S.es crash should clear wall state after transition")
	_expect(bool(crash.get("attack_damage_done", false)), "R.O.U.S.es crash should preserve attack damage state")

	var outside_roll := _identity_test_actor(Vector2(0.368, 0.20), Vector2.LEFT)
	outside_roll["roll_origin"] = outside_roll["pos"]
	outside_roll["render_pos"] = outside_roll["pos"]
	outside_roll["render_sim_pos"] = outside_roll["pos"]
	outside_roll["attack_timer"] = 0.02
	outside_roll["attack_duration"] = 0.02
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.call("_step_chicken", outside_roll, 0.02)
	stage.call("_update_enemy_render_pos", outside_roll, 0.02)
	var outside_pos := outside_roll["pos"] as Vector2
	_expect(str(outside_roll.get("attack_phase", "")) == "recovery" and bool(stage.call("_diamond_contains_norm", outside_pos)) and not outside_pos.is_equal_approx(stage.call("_clamp_norm_to_arena", outside_pos)), "R.O.U.S.es committed roll should temporarily enter the visible non-walkable diamond fringe")
	_expect((outside_roll["render_pos"] as Vector2).is_equal_approx(outside_roll["pos"] as Vector2), "R.O.U.S.es render path should follow its straight roll outside the walkable diamond")

	var bounce := _identity_test_actor(Vector2(0.32, 0.55), Vector2.RIGHT)
	stage.call("_begin_enemy_attack", bounce, Vector2.RIGHT)
	var bounce_origin := bounce["roll_origin"] as Vector2
	bounce["attack_phase"] = "strike"
	bounce["attack_timer"] = 0.42
	bounce["attack_duration"] = 0.42
	bounce["render_pos"] = bounce_origin
	bounce["render_sim_pos"] = bounce_origin
	var furthest_x := bounce_origin.x
	var max_render_y_error := 0.0
	for _frame in range(90):
		stage.call("_step_chicken", bounce, 1.0 / 60.0)
		stage.call("_update_enemy_render_pos", bounce, 1.0 / 60.0)
		furthest_x = maxf(furthest_x, (bounce["pos"] as Vector2).x)
		max_render_y_error = maxf(max_render_y_error, absf((bounce["render_pos"] as Vector2).y - bounce_origin.y))
		if bool(bounce.get("rouses_returned", false)) and str(bounce.get("attack_phase", "")) == "":
			break
	_expect(furthest_x > stage.get("hero_pos").x, "R.O.U.S.es roll should pass through the target before bouncing")
	_expect(furthest_x <= float(stage.get("hero_pos").x) + 0.03, "R.O.U.S.es roll should turn at the hero instead of diving behind them")
	_expect(bool(bounce.get("rouses_returned", false)) and (bounce["pos"] as Vector2).is_equal_approx(bounce_origin), "R.O.U.S.es recovery should return exactly to its roll origin")
	_expect(max_render_y_error < 0.001, "R.O.U.S.es out-and-back render path should stay straight instead of circling the hero")
	stage.call("_begin_enemy_attack", bounce, Vector2.RIGHT)
	_expect(not bool(bounce.get("rouses_returned", true)) and not bool(bounce.get("rouses_crashed", false)), "R.O.U.S.es return state should reset on the next attack")

	stage.set("hero_hp", 100000.0)
	stage.set("hero_hurt_cooldown", 0.0)
	var one_hit := _identity_test_actor(Vector2(0.35, 0.55), Vector2.RIGHT)
	one_hit["damage"] = 100.0
	stage.call("_step_enemy_strike", one_hit, one_hit["pos"], Vector2.RIGHT, 0.05)
	var after_contact := float(stage.get("hero_hp"))
	_expect(after_contact < 100000.0 and bool(one_hit.get("attack_damage_done", false)), "R.O.U.S.es contact should damage once")
	stage.set("hero_hurt_cooldown", 0.0)
	one_hit["pos"] = Vector2(0.90, 0.55)
	stage.call("_step_enemy_strike", one_hit, one_hit["pos"], Vector2.RIGHT, 0.10)
	_expect(is_equal_approx(float(stage.get("hero_hp")), after_contact), "R.O.U.S.es crash should not deal a second hit")

	var committed := _identity_test_actor(Vector2(0.68, 0.55), Vector2.LEFT)
	stage.call("_begin_enemy_attack", committed, Vector2.LEFT)
	committed["attack_phase"] = "windup"
	stage.call("_stagger_enemy", committed)
	_expect(bool(committed.get("interrupt_protected", false)) and str(committed.get("attack_phase", "")) == "windup", "R.O.U.S.es windup should survive a normal punch and complete its roll")

	stage.set("enemy_id", "werewolves")
	stage.call("_load_monster_movement_frames")
	var transform_frames: Array = (stage.get("enemy_movement_frames") as Dictionary).get("werewolves-transform", []) as Array
	var orange_walk_frames: Array = (stage.get("enemy_movement_frames") as Dictionary).get("guys", []) as Array
	_expect(transform_frames.size() == 5, "Werewolf transformation should load five frames")
	var transforming := _identity_test_actor(Vector2(0.40, 0.55), Vector2.RIGHT)
	transforming["attack_phase"] = ""
	transforming["attack_cd"] = 0.0
	transforming["werewolf_transformed"] = false
	transforming["transform_timer"] = 0.0
	_expect(orange_walk_frames.has(stage.call("_movement_texture", transforming)), "Werewolf should enter using the Orange Guy walk cycle")
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.call("_step_chicken", transforming, 0.05)
	_expect(str(transforming.get("attack_phase", "")).is_empty(), "An unhurt Orange Guy should not start a Werewolf attack")
	transforming["pos"] = Vector2(0.62, 0.55)
	transforming["hp"] = 1000.0
	transforming["max_hp"] = 1000.0
	(stage.get("chickens") as Array).clear()
	(stage.get("chickens") as Array).append(transforming)
	stage.set("hero_uppercut_cd", 999.0)
	_expect(bool(stage.call("_start_hero_attack")), "The first punch should hit the disguised Werewolf")
	transforming = (stage.get("chickens") as Array)[0] as Dictionary
	_expect(bool(transforming.get("werewolf_transformed", false)) and is_equal_approx(float(transforming.get("transform_timer", 0.0)), 0.80), "The first damage should trigger the Werewolf transformation")
	_expect(stage.call("_movement_texture", transforming) == transform_frames[0], "The triggered transformation should start on its Orange Guy frame")
	var transforming_hp := float(transforming.get("hp", 0.0))
	_expect(not bool(stage.call("_start_hero_attack")) and is_equal_approx(float(transforming.get("hp", 0.0)), transforming_hp), "Blue Guy should let the first-hit transformation finish")
	stage.call("_step_chicken", transforming, 0.41)
	_expect(is_equal_approx(float(transforming.get("transform_timer", 0.0)), 0.39), "Werewolf transformation timer should advance with combat time")
	_expect(stage.call("_movement_texture", transforming) == transform_frames[2], "Werewolf should reach the midpoint tween frame")
	transforming["transform_timer"] = 0.01
	_expect(stage.call("_movement_texture", transforming) == transform_frames[4], "Werewolf transformation should finish on the accepted Werewolf")
	var committed_wolf := _identity_test_actor(Vector2(0.40, 0.55), Vector2.RIGHT)
	stage.call("_begin_enemy_attack", committed_wolf, Vector2.RIGHT)
	committed_wolf["attack_phase"] = "windup"
	stage.call("_stagger_enemy", committed_wolf)
	_expect(str(committed_wolf.get("attack_phase", "")) == "windup", "Werewolf charge windup should be committed after its transformation")
	var saved_charge := _identity_test_actor(Vector2(0.40, 0.55), Vector2.RIGHT)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.call("_begin_enemy_attack", saved_charge, Vector2.RIGHT)
	saved_charge["attack_phase"] = "strike"
	stage.set("hero_pos", Vector2(0.10, 0.55))
	var charge_before := saved_charge["pos"] as Vector2
	stage.call("_step_enemy_strike", saved_charge, saved_charge["pos"], Vector2.LEFT, 0.05)
	_expect((saved_charge["pos"] as Vector2).x > charge_before.x, "Werewolf charge should keep its saved direction after hero movement")

	# Natural production beat: the stationary center hero is crossed once, then the saved straight charge skids at the far wall.
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_hp", 100000.0)
	stage.set("hero_hurt_cooldown", 0.0)
	var natural_wolf := _identity_test_actor(Vector2(0.30, 0.55), Vector2.RIGHT)
	natural_wolf["attack_duration"] = 0.35
	natural_wolf["attack_timer"] = 0.35
	for _frame in range(12):
		stage.call("_step_chicken", natural_wolf, 0.05)
		if str(natural_wolf.get("attack_phase", "")) == "recovery":
			break
	_expect(str(natural_wolf.get("attack_phase", "")) == "recovery" and bool(natural_wolf.get("charge_skidded", false)), "center stationary Werewolf charge should pass its target and SKID at the wall")
	_expect(is_zero_approx(float(natural_wolf.get("stagger_timer", 0.0))) and not bool(natural_wolf.get("wall_hit", false)), "Werewolf SKID should enter ordinary recovery without stagger")
	_expect(float(stage.get("hero_hp")) < 100000.0 and bool(natural_wolf.get("attack_damage_done", false)), "center stationary Werewolf charge may damage once before SKID")

	# Synthetic off-path proof: moving the hero off the saved line must not create contact damage.
	stage.set("hero_pos", Vector2(0.50, 0.82))
	stage.set("hero_hp", 100000.0)
	stage.set("hero_hurt_cooldown", 0.0)
	var miss := _identity_test_actor(Vector2(0.90, 0.55), Vector2.RIGHT)
	miss["attack_phase"] = "strike"
	miss["attack_timer"] = 0.20
	miss["attack_duration"] = 0.20
	for _frame in range(12):
		stage.call("_step_chicken", miss, 0.05)
		if str(miss.get("attack_phase", "")) == "recovery":
			break
	_expect(str(miss.get("attack_phase", "")) == "recovery" and bool(miss.get("wall_missed", false)) and bool(miss.get("charge_skidded", false)), "Werewolf wall miss should enter ordinary recovery")
	_expect(is_zero_approx(float(miss.get("stagger_timer", 0.0))) and not bool(miss.get("wall_hit", false)), "Werewolf wall miss should have no R.O.U.S.-style stagger")
	_expect(is_equal_approx(float(stage.get("hero_hp")), 100000.0), "Werewolf path miss should not damage the hero")

	var contact := _identity_test_actor(Vector2(0.35, 0.55), Vector2.RIGHT)
	contact["damage"] = 100.0
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_step_enemy_strike", contact, contact["pos"], Vector2.RIGHT, 0.05)
	var after_wolf_contact := float(stage.get("hero_hp"))
	_expect(after_wolf_contact < 100000.0, "Werewolf contact should damage the hero")
	stage.set("hero_hurt_cooldown", 0.0)
	stage.call("_step_enemy_strike", contact, contact["pos"], Vector2.RIGHT, 0.05)
	_expect(is_equal_approx(float(stage.get("hero_hp")), after_wolf_contact), "Werewolf contact should damage exactly once")
	_expect(bool(bounce.get("rouses_returned", false)) == false and bool(natural_wolf.get("charge_skidded", false)) and not bool(natural_wolf.get("rouses_crashed", false)), "R.O.U.S.es and Werewolves should expose different return results")


func _check_cave_troll_identity(stage: Control, scene: Node) -> void:
	var action := scene.call("_action_data", "fight", "fight-cave-trolls") as Dictionary
	stage.call("setup_action", action)
	stage.call("setup_fighting_level", 59)
	stage.call("set_active_fight", true)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	var max_hp := float(stage.call("_hero_max_hp"))
	for label in stage.get("float_labels") as Array:
		(label as Label).visible = false
	stage.set("hero_hp", max_hp)
	stage.set("hero_hurt_cooldown", 0.0)
	var early := _cave_troll_test_actor(Vector2(0.62, 0.55), 0.20)
	stage.call("_step_enemy_strike", early, early["pos"], Vector2.LEFT, 0.01)
	_expect(is_equal_approx(float(stage.get("hero_hp")), max_hp), "early Cave Troll strike should not hurt the hero")
	_expect(not bool(early.get("attack_damage_done", false)) and not bool(early.get("slam_impacted", false)), "early Cave Troll strike should not consume its impact")

	for label in stage.get("float_labels") as Array:
		(label as Label).visible = false
	stage.set("hero_hp", max_hp)
	stage.set("hero_hurt_cooldown", 0.0)
	var impact := _cave_troll_test_actor(Vector2(0.62, 0.55), 0.68)
	stage.call("_step_enemy_strike", impact, impact["pos"], Vector2.LEFT, 0.01)
	_expect(float(stage.get("hero_hp")) < max_hp, "Cave Troll impact should damage an in-range hero once")
	_expect(bool(impact.get("attack_damage_done", false)) and bool(impact.get("slam_impacted", false)), "Cave Troll impact should consume its strike")
	var hp_after_impact := float(stage.get("hero_hp"))
	stage.set("hero_hurt_cooldown", 0.0)
	impact["signature_t"] = 0.92
	stage.call("_step_enemy_strike", impact, impact["pos"], Vector2.LEFT, 0.01)
	_expect(is_equal_approx(float(stage.get("hero_hp")), hp_after_impact), "later Cave Troll strike frames should not damage again")

	for label in stage.get("float_labels") as Array:
		(label as Label).visible = false
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_hp", max_hp)
	stage.set("hero_hurt_cooldown", 0.0)
	var missed := _cave_troll_test_actor(Vector2(0.90, 0.55), 0.68)
	stage.call("_step_enemy_strike", missed, missed["pos"], Vector2.LEFT, 0.01)
	_expect(bool(missed.get("slam_impacted", false)) and not bool(missed.get("attack_damage_done", false)), "out-of-range Cave Troll impact should mark SLAM without damage")
	_expect(is_equal_approx(float(stage.get("hero_hp")), max_hp), "out-of-range Cave Troll impact should not hurt the hero")
	stage.set("hero_pos", Vector2(0.62, 0.55))
	stage.set("hero_hurt_cooldown", 0.0)
	missed["signature_t"] = 0.92
	stage.call("_step_enemy_strike", missed, missed["pos"], Vector2.LEFT, 0.01)
	_expect(is_equal_approx(float(stage.get("hero_hp")), max_hp), "moving into range after a missed Cave Troll impact should stay safe")

	for label in stage.get("float_labels") as Array:
		(label as Label).visible = false
	stage.set("hero_pos", Vector2(0.50, 0.55))
	stage.set("hero_hp", max_hp)
	stage.set("hero_hurt_cooldown", 0.0)
	var interrupted := _cave_troll_test_actor(Vector2(0.62, 0.55), 0.0)
	interrupted["attack_phase"] = "windup"
	interrupted["attack_timer"] = 0.20
	interrupted["attack_duration"] = 0.78
	stage.call("_stagger_enemy", interrupted)
	_expect(str(interrupted.get("attack_phase", "")) == "stagger" and not bool(interrupted.get("slam_impacted", false)), "Cave Troll windup interrupt should prevent SLAM")
	_expect(is_equal_approx(float(stage.get("hero_hp")), max_hp), "Cave Troll windup interrupt should prevent damage")
	stage.call("_begin_enemy_attack", interrupted, Vector2.LEFT)
	interrupted["attack_phase"] = "windup"
	stage.call("_step_chicken", interrupted, 0.78)
	stage.call("_step_chicken", interrupted, 0.17)
	_expect(bool(interrupted.get("slam_impacted", false)) and bool(interrupted.get("attack_damage_done", false)), "protected Cave Troll retry should reach one late impact")


func _cave_troll_test_actor(pos: Vector2, signature_t: float) -> Dictionary:
	return {
		"id": 1,
		"pos": pos,
		"hp": 100000.0,
		"max_hp": 100000.0,
		"attack_cd": 0.0,
		"speed": 0.0,
		"damage": 100.0,
		"attack_phase": "strike",
		"attack_timer": 0.24 * (1.0 - signature_t),
		"attack_duration": 0.24,
		"attack_damage_done": false,
		"slam_impacted": false,
		"stagger_timer": 0.0,
		"interrupt_protected": false,
		"signature_t": signature_t,
		"roll_dir": Vector2.ZERO,
		"wall_hit": false,
		"hit_flash": 0.0,
		"dead_timer": 0.0,
		"lunge_timer": 0.0,
		"lunge_dir": Vector2.ZERO
	}


func _visible_float_count(stage: Control, text: String) -> int:
	var count := 0
	for raw_label in stage.get("float_labels") as Array:
		var label := raw_label as Label
		if label != null and label.visible and label.text == text:
			count += 1
	return count


func _check_center_identity_reachability(stage: Control, scene: Node) -> void:
	# Actual stage loop: normal center hero, production approach/attack lifecycle, no actor or phase injection.
	for sample in [{"id": "fight-r.o.u.s.es", "level": 24, "flag": "rouses_returned", "label": "R.O.U.S.es return"}, {"id": "fight-r.o.u.s.es", "level": 99, "flag": "rouses_returned", "label": "level-99 R.O.U.S.es return"}, {"id": "fight-werewolves", "level": 47, "flag": "charge_skidded", "label": "Werewolf skid"}, {"id": "fight-werewolves", "level": 99, "flag": "charge_skidded", "label": "level-99 Werewolf skid"}, {"id": "fight-cave-trolls", "level": 59, "flag": "slam_impacted", "label": "Cave Troll SLAM"}, {"id": "fight-cave-trolls", "level": 99, "flag": "slam_impacted", "label": "level-99 Cave Troll SLAM"}, {"id": "fight-vampires", "level": 88, "flag": "vampire_crossed", "label": "level-88 Vampire flank cross"}, {"id": "fight-vampires", "level": 99, "flag": "vampire_crossed", "label": "level-99 Vampire flank cross"}]:
		var action := scene.call("_action_data", "fight", str(sample["id"])) as Dictionary
		stage.call("setup_action", action)
		stage.call("setup_fighting_level", int(sample["level"]))
		stage.call("set_active_fight", true)
		stage.set("hero_pos", Vector2(0.50, 0.55))
		if str(sample["id"]) != "fight-cave-trolls":
			stage.set("hero_attack_cd", 999.0)
			stage.set("hero_hurt_cooldown", 999.0)
		var reached := false
		for _frame in range(1800):
			stage.call("_process", 1.0 / 60.0)
			for raw_actor in stage.get("chickens") as Array:
				var actor := raw_actor as Dictionary
				if bool(actor.get(str(sample["flag"]), false)):
					reached = true
					break
			if reached:
				break
		_expect(reached, "%s should be naturally reachable at center hero" % str(sample["label"]))
		if str(sample["flag"]) == "charge_skidded":
			for raw_actor in stage.get("chickens") as Array:
				var actor := raw_actor as Dictionary
				if bool(actor.get("charge_skidded", false)):
					_expect(str(actor.get("attack_phase", "")) == "recovery" and is_zero_approx(float(actor.get("stagger_timer", 0.0))), "%s should recover without stagger" % str(sample["label"]))
					break


func _identity_test_actor(pos: Vector2, roll_dir: Vector2) -> Dictionary:
	return {
		"id": 1,
		"pos": pos,
		"hp": 100000.0,
		"max_hp": 100000.0,
		"attack_cd": 0.0,
		"speed": 0.0,
		"damage": 1.0,
		"attack_phase": "strike",
		"attack_timer": 0.35,
		"attack_duration": 0.35,
		"attack_damage_done": false,
		"stagger_timer": 0.0,
		"interrupt_protected": false,
		"punch_flee_timer": 0.0,
		"punch_flee_dir": Vector2.ZERO,
		"punch_flee_side": 1.0,
		"signature_t": 0.0,
		"roll_dir": roll_dir,
		"wall_hit": false,
		"rouses_crashed": false,
		"rouses_returned": false,
		"roll_origin": pos,
		"wall_missed": false,
		"charge_skidded": false,
		"hit_flash": 0.0,
		"dead_timer": 0.0,
		"lunge_timer": 0.0,
		"lunge_dir": Vector2.ZERO
	}


func _guys_test_actor(guarding: bool) -> Dictionary:
	return {
		"id": 1,
		"pos": Vector2(0.62, 0.55),
		"hp": 100000.0,
		"max_hp": 100000.0,
		"attack_cd": 999.0,
		"speed": 0.0,
		"damage": 1.0,
		"guarding": guarding,
		"attack_phase": "",
		"attack_timer": 0.0,
		"attack_duration": 0.0,
		"attack_damage_done": false,
		"stagger_timer": 0.0,
		"interrupt_protected": false,
		"signature_t": 0.0,
		"roll_dir": Vector2.ZERO,
		"wall_hit": false,
		"hit_flash": 0.0,
		"uppercut_knock_timer": 0.0,
		"uppercut_pop": 0.0,
		"dead_timer": 0.0
	}


func _check_profiles(scene: Node) -> void:
	var ids := ["fight-chickens", "fight-goblins", "fight-r.o.u.s.es", "fight-guys", "fight-werewolves", "fight-cave-trolls", "fight-giants", "fight-vampires", "fight-dragons"]
	var signatures := {}
	var state_assets := {}
	for id in ids:
		var action := scene.call("_action_data", "fight", id) as Dictionary
		var combat := action.get("combat", {}) as Dictionary
		_expect(str(combat.get("enemy_id", "")).length() > 0, "%s should declare enemy_id" % id)
		_expect(not (combat.get("population_curve", []) as Array).is_empty(), "%s should declare population curve" % id)
		var signature := str(combat.get("signature", ""))
		_expect(not signature.is_empty() and not signatures.has(signature), "%s should have a distinct signature" % id)
		signatures[signature] = true
		var state_asset := str(combat.get("art_ref", ""))
		_expect(not state_asset.is_empty() and not state_assets.has(state_asset), "%s should have distinct state art data" % id)
		state_assets[state_asset] = true


func _check_reward_contract(scene: Node, stage: Control, fighting_runtime: Object) -> void:
	var ids := ["fight-chickens", "fight-goblins", "fight-r.o.u.s.es", "fight-guys", "fight-werewolves", "fight-cave-trolls", "fight-giants", "fight-vampires", "fight-dragons"]
	var giant_has_nontrivial_payout := false
	for id in ids:
		var action := scene.call("_action_data", "fight", id) as Dictionary
		var rewards := action.get("rewards", {}) as Dictionary
		var combat := action.get("combat", {}) as Dictionary
		var reward_xp := int(combat.get("reward_xp", 0.0))
		_expect(int(action.get("xp", 0)) == int(rewards.get("xp", 0)) and int(rewards.get("xp", 0)) == reward_xp, "%s XP values should share one authored reward" % id)
		_expect(is_equal_approx(float(combat.get("kill_reward_share", 0.0)), 0.75), "%s should load kill_reward_share 0.75" % id)
		stage.call("setup_action", action)
		var curve := combat.get("population_curve", []) as Array
		var planned_expected := 0
		for wave in range(5):
			planned_expected += maxi(1, int(curve[clampi(wave, 0, curve.size() - 1)]))
		planned_expected += maxi(1, int(combat.get("final_population", 1)))
		var planned := int(stage.call("_planned_kill_count_for_reward"))
		_expect(planned == planned_expected, "%s planned kill count should match its five-wave curve plus final population" % id)
		var kill_budget := int(floor(float(reward_xp) * 0.75))
		var kill_sum := 0
		for _kill in range(planned):
			var payout := int(stage.call("_xp_reward_for_kill"))
			_expect(payout >= 0, "%s kill XP should never be negative" % id)
			kill_sum += payout
			_expect(kill_sum <= kill_budget, "%s cumulative kill XP should stay within its budget" % id)
			if id == "fight-giants" and payout > 1:
				giant_has_nontrivial_payout = true
		_expect(kill_sum == kill_budget, "%s kill XP should exactly consume its budget" % id)
		var clear_payout := int(stage.call("_xp_reward_for_area_clear"))
		_expect(clear_payout == reward_xp - kill_budget, "%s clear XP should pay the exact remainder" % id)
		_expect(int(stage.call("_xp_reward_for_area_clear")) == 0, "%s clear XP should not duplicate" % id)
		_expect(kill_sum + clear_payout == reward_xp, "%s kill plus clear XP should equal its authored total" % id)
	_expect(giant_has_nontrivial_payout, "Giant kill XP should include nontrivial integer payouts")

	var chicken_action := scene.call("_action_data", "fight", "fight-chickens") as Dictionary
	stage.call("setup_action", chicken_action)
	var sparse_payouts: Array = []
	for _kill in range(int(stage.call("_planned_kill_count_for_reward"))):
		sparse_payouts.append(int(stage.call("_xp_reward_for_kill")))
	_expect(sparse_payouts.any(func(payout: int) -> bool: return payout == 0), "Chicken kills should include sparse zero-payout kills")
	_expect(sparse_payouts.any(func(payout: int) -> bool: return payout == 1), "Chicken kills should include one-point payouts")
	var death_payouts: Array = []
	stage.chicken_killed.connect(func(amount: int): death_payouts.append(amount))
	for raw_label in stage.get("float_labels") as Array:
		(raw_label as Label).visible = false
	(stage.get("chickens") as Array).clear()
	stage.set("hero_pos", Vector2(0.5, 0.55))
	stage.set("hero_uppercut_cd", 999.0)
	(stage.get("chickens") as Array).append({"id": 1, "pos": Vector2(0.55, 0.55), "hp": 1.0, "max_hp": 1.0, "attack_phase": "", "interrupt_protected": false, "dead_timer": 0.0, "hit_flash": 0.0, "uppercut_pop": 0.0, "lunge_timer": 0.0, "lunge_dir": Vector2.ZERO, "shield_up": false})
	_expect(bool(stage.call("_start_hero_attack")), "Chicken real death path should land a killing hit")
	_expect(death_payouts.size() == 1 and int(death_payouts[0]) == 0, "Chicken real death path should emit its zero XP death signal")
	_expect(not (stage.get("float_labels") as Array).any(func(label: Label) -> bool: return label.visible and label.text == "+0 XP"), "zero XP chicken death should not show a +0 floater")
	var host_xp_before := int((scene.skills["fight"] as Dictionary).get("xp", 0))
	fighting_runtime.on_blue_guy_chicken_brawl_chicken_killed(1, stage)
	var host_xp_after := int((scene.skills["fight"] as Dictionary).get("xp", 0))
	_expect(host_xp_after == host_xp_before + 1, "host skill XP should receive awarded kill XP")
	stage.call("_seed_fight")
	_expect(int(stage.get("kill_xp_already_awarded")) == 0 and int(stage.get("kill_count_awarded")) == 0, "reseed should reset only the new area's reward ledger")
	_expect(int((scene.skills["fight"] as Dictionary).get("xp", 0)) == host_xp_after, "reseed should not erase host skill XP")


func _check_chicken_balance_curve(scene: Node) -> void:
	var unlock := _run_stationary_chicken_lives(scene, 5, 12)
	var consistent := _run_stationary_chicken_lives(scene, 10, 12)
	var growing := _run_stationary_chicken_lives(scene, 20, 12)
	var unlock_kills := unlock["kills"] as Array
	var consistent_kills := consistent["kills"] as Array
	var growing_kills := growing["kills"] as Array
	print("chicken-balance level5=%s level10=%s level20=%s" % [str(unlock_kills), str(consistent_kills), str(growing_kills)])
	_expect(unlock_kills.min() == 0 and unlock_kills.max() == 1, "level-5 Chicken should sometimes get zero kills and feel fortunate to get one")
	_expect(consistent_kills.min() >= 1 and consistent_kills.max() <= 2, "level-10 Chicken should get one kill consistently")
	_expect(growing_kills.min() >= 2 and growing_kills.max() <= 4, "level-20 Chicken should grow into two or three kills")
	_expect(int(unlock["widest_punch"]) == 1 and int(consistent["widest_punch"]) == 1 and int(growing["widest_punch"]) == 1, "each Chicken punch should damage at most one target")


func _run_stationary_chicken_lives(scene: Node, level: int, sample_count: int) -> Dictionary:
	var action := scene.call("_action_data", "fight", "fight-chickens") as Dictionary
	var kills := []
	var widest_punch := 0
	for sample in range(sample_count):
		seed(4100 + level * 31 + sample)
		var stage := Stage.new()
		stage.size = Vector2(1080.0, 1080.0)
		stage.set("arena_shape", "diamond")
		root.add_child(stage)
		stage.call("setup_action", action)
		stage.call("setup_fighting_level", level)
		stage.call("set_active_fight", true)
		var previous_hp := {}
		for _frame in range(6000):
			previous_hp.clear()
			for raw_actor in stage.get("chickens") as Array:
				var actor := raw_actor as Dictionary
				previous_hp[int(actor.get("id", -1))] = float(actor.get("hp", 0.0))
			stage.call("_step_fight", 0.05)
			var hit_count := 0
			for raw_actor in stage.get("chickens") as Array:
				var actor := raw_actor as Dictionary
				var actor_id := int(actor.get("id", -1))
				if previous_hp.has(actor_id) and float(actor.get("hp", 0.0)) < float(previous_hp[actor_id]):
					hit_count += 1
			widest_punch = maxi(widest_punch, hit_count)
			if float(stage.get("hero_ko_timer")) > 0.0 or float(stage.get("area_clear_restart_timer")) > 0.0:
				break
		kills.append(int(stage.get("ko_count")))
		stage.queue_free()
	return {"kills": kills, "widest_punch": widest_punch}


func _check_completion_rates(scene: Node) -> void:
	var ids := ["fight-chickens", "fight-goblins", "fight-r.o.u.s.es", "fight-guys", "fight-werewolves", "fight-cave-trolls", "fight-giants", "fight-vampires", "fight-dragons"]
	var unlocks := [5, 16, 24, 32, 47, 59, 74, 88, 98]
	var unlock_floors := [0, 3, 3, 0, 3, 3, 3, 3, 3]
	var unlock_clears := 0
	var unlock_total := 0
	var max_clears := 0
	var max_total := 0
	for i in range(ids.size()):
		var module_unlock_clears := 0
		var module_max_clears := 0
		for sample in range(4):
			unlock_total += 1
			var unlock_clear := int(_run_cycle(scene, ids[i], unlocks[i], 1000 + i * 17 + sample))
			unlock_clears += unlock_clear
			module_unlock_clears += unlock_clear
			max_total += 1
			var max_clear := int(_run_cycle(scene, ids[i], 99, 9000 + i * 17 + sample))
			max_clears += max_clear
			module_max_clears += max_clear
		print("fighting-module %s unlock=%d/4 floor=%d/4 max=%d/4" % [ids[i], module_unlock_clears, unlock_floors[i], module_max_clears])
		_expect(module_unlock_clears >= unlock_floors[i], "%s unlock-level completion should meet its deterministic floor" % ids[i])
		_expect(module_max_clears == 4, "%s level-99 completion should be 4/4" % ids[i])
	print("fighting-completion unlock=%d/%d max=%d/%d chicken-and-guys-floor=0/4 other-floors=3/4" % [unlock_clears, unlock_total, max_clears, max_total])
	_expect(max_clears == 36, "level-99 full-cycle completion should be 36/36")
	_expect(float(unlock_clears) / float(maxi(1, unlock_total)) >= 0.60, "unlock-level full-cycle completion should be at least 60%%")
	_expect(float(max_clears) / float(maxi(1, max_total)) >= 0.95, "level-99 full-cycle completion should be at least 95%%")


func _check_stationary_interrupts(scene: Node) -> void:
	for action_id in ["fight-guys", "fight-giants", "fight-dragons"]:
		for level in [43, 60, 98, 99]:
			seed(12000 + action_id.hash() + level)
			var action := scene.call("_action_data", "fight", action_id) as Dictionary
			var stage := Stage.new()
			stage.size = Vector2(1080.0, 1080.0)
			stage.set("arena_shape", "diamond")
			root.add_child(stage)
			stage.call("setup_action", action)
			stage.call("setup_fighting_level", level)
			stage.call("set_active_fight", true)
			stage.set("hero_pos", Vector2(0.50, 0.55))
			stage.set("wave_spawn_remaining", 1)
			stage.set("spawn_timer", 0.0)
			stage.call("_step_fight", 0.05)
			stage.set("wave_rest_timer", 999.0)
			stage.set("end_wave_active", true)
			stage.set("hero_hp", 1000000.0)
			stage.set("hero_uppercut_cd", 999.0)
			var setup_enemy := (stage.get("chickens") as Array)[0] as Dictionary
			setup_enemy["pos"] = Vector2(0.62, 0.55)
			setup_enemy["hp"] = 1000000.0
			setup_enemy["max_hp"] = 1000000.0
			setup_enemy["attack_cd"] = 0.0
			setup_enemy["speed"] = 0.0
			setup_enemy["damage"] = 1.0
			setup_enemy["attack_phase"] = ""
			setup_enemy["attack_timer"] = 0.0
			setup_enemy["attack_duration"] = 0.0
			setup_enemy["attack_damage_done"] = false
			setup_enemy["stagger_timer"] = 0.0
			setup_enemy["interrupt_protected"] = false
			setup_enemy["signature_t"] = 0.0
			setup_enemy["roll_dir"] = Vector2.ZERO
			setup_enemy["wall_hit"] = false
			setup_enemy["uppercut_knock_timer"] = 0.0
			setup_enemy["hit_flash"] = 0.0
			setup_enemy["uppercut_pop"] = 0.0
			setup_enemy["dead_timer"] = 0.0
			var saw_completed_attack := false
			var saw_enemy_damage := false
			var saw_hit_feedback := false
			for frame in range(100):
				stage.call("_step_fight", 0.05)
				if float(stage.get("hero_hp")) < 1000000.0:
					saw_enemy_damage = true
				for actor in stage.get("chickens") as Array:
					var enemy := actor as Dictionary
					if float(enemy.get("hit_flash", 0.0)) > 0.0:
						saw_hit_feedback = true
					if str(enemy.get("attack_phase", "")) in ["strike", "recovery"]:
						saw_completed_attack = true
				if saw_completed_attack and saw_enemy_damage and saw_hit_feedback:
					break
			_expect(saw_completed_attack, "%s level-%d stationary hero should let a solo enemy complete an attack" % [action_id, level])
			_expect(saw_enemy_damage, "%s level-%d committed attack should damage the hero" % [action_id, level])
			_expect(saw_hit_feedback, "%s level-%d punch should show hit feedback" % [action_id, level])
			stage.queue_free()


func _run_cycle(scene: Node, action_id: String, level: int, seed_value: int) -> bool:
	seed(seed_value)
	var action := scene.call("_action_data", "fight", action_id) as Dictionary
	var stage := Stage.new()
	stage.size = Vector2(1080.0, 1080.0)
	stage.set("arena_shape", "diamond")
	root.add_child(stage)
	stage.call("setup_action", action)
	stage.call("setup_fighting_level", level)
	stage.call("set_active_fight", true)
	var cleared := false
	for frame in range(18000):
		# ponytail: deterministic orbit, with a longer goblin retreat, exercises attack range and avoidance.
		var dodge_t := float(frame) * 0.05
		var dodge_target := Vector2(0.5 + cos(dodge_t * 0.9) * 0.16, 0.55 + sin(dodge_t * 0.9) * 0.16)
		var current_pos := stage.get("hero_pos") as Vector2
		var evasion := Vector2.ZERO
		for actor in stage.get("chickens") as Array:
			var enemy := actor as Dictionary
			var phase := str(enemy.get("attack_phase", ""))
			var dragon_brawl := action_id == "fight-dragons" and str(enemy.get("dragon_attack_kind", "")) == "brawl"
			var enemy_pos := enemy.get("pos", current_pos) as Vector2
			var enemy_distance := enemy_pos.distance_to(current_pos)
			if phase in ["windup", "strike"] and enemy_distance < 0.65 and not dragon_brawl:
				evasion += (current_pos - enemy_pos).normalized()
		if evasion.length() > 0.001:
			var retreat_distance := 0.44 if action_id == "fight-goblins" else (0.18 if action_id == "fight-vampires" else 0.30)
			dodge_target = current_pos + evasion.normalized() * retreat_distance
		stage.set("hero_pos", stage.call("_clamp_norm_to_arena", dodge_target))
		stage.call("_step_fight", 0.05)
		if float(stage.get("area_clear_restart_timer")) > 0.0:
			cleared = true
			break
		if float(stage.get("hero_ko_timer")) > 0.0:
			break
	stage.queue_free()
	return cleared


func _fail(message: String) -> void:
	test_failed = true
	push_error(message)
	print("fighting-diamond-arena-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script "res://.codex-tmp/fighting-diamond-test/fighting_diamond_arena_test.gd" 2>&1
    $output | Write-Output
    Assert-True (($output | Out-String) -match "fighting-diamond-arena-ok") "Fighting diamond arena test did not report success."
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        throw "Headless Godot process left behind after fighting diamond arena test."
    }
}
