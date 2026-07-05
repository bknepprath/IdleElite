$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\woodcutting-firepit"
$testScript = Join-Path $testDir "woodcutting_firepit_test.gd"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

function Assert-NoUnexpectedGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Output) {
        return
    }

    foreach ($line in @($Output)) {
        $text = [string]$line
        if ($text -notmatch '(ERROR|SCRIPT ERROR|powershell\.exe : ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

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

const AchievementState := preload("res://scripts/achievements/state.gd")

var test_failed := false


func _firepit_active(scene) -> bool:
	return scene.call("_passive_modules_runtime").firepit_active(int(scene.call("_unix_now")))

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("woodcutting-firepit-start")
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
	print("woodcutting-firepit-scene-ready")
	_unlock_firepit(scene)
	scene.material_runtime.set_amount("scrapwood", 3.0)
	if not scene.call("_passive_modules_runtime").start_firepit(int(scene.call("_unix_now"))):
		_fail("firepit did not start with available Scrapwood")
		return
	print("woodcutting-firepit-started")
	_expect(_firepit_active(scene), "firepit should be active after start")
	_expect(absf(scene.material_runtime.amount("scrapwood") - 3.0) < 0.001, "starting should not immediately consume fuel")
	_expect(absf(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", int(scene.call("_unix_now")))) - 0.04) < 0.001, "Warm Momentum should start at +4% Woodcutting stamina regen")
	_expect(absf(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "fight", int(scene.call("_unix_now"))))) < 0.001, "Warm Momentum should not buff other skills")
	_expect(absf(float(AchievementState.global_reward_bonus(scene, "xp_mult", "fight"))) < 0.001, "Warm Momentum should not be a global XP bonus")
	print("woodcutting-firepit-buff-ok")
	var starting_woodcutting_xp := int((scene.skills["woodcutting"] as Dictionary).get("xp", 0))
	var now := int(scene.call("_unix_now"))
	var firepit_state := scene.passive_modules["woodcutting-firepit"] as Dictionary
	firepit_state["last_update"] = now - 30
	firepit_state["started_unix"] = now - 30
	scene.passive_modules["woodcutting-firepit"] = firepit_state
	scene.call("_passive_modules_runtime").apply_firepit_fuel(now)
	_expect(_firepit_active(scene), "firepit should remain active after partial fuel burn")
	_expect(absf(scene.material_runtime.amount("scrapwood") - 2.0) < 0.05, "firepit should burn about one Scrapwood in 30 seconds")
	_expect(int((scene.skills["woodcutting"] as Dictionary).get("xp", 0)) == starting_woodcutting_xp + 2, "firepit should award 2 Woodcutting XP per whole Scrapwood burned")
	firepit_state = scene.passive_modules["woodcutting-firepit"] as Dictionary
	firepit_state["started_unix"] = now - 60
	scene.passive_modules["woodcutting-firepit"] = firepit_state
	_expect(absf(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", now)) - 0.08) < 0.001, "Warm Momentum should reach +8% after one uninterrupted minute")
	print("woodcutting-firepit-partial-burn-ok")
	firepit_state = scene.passive_modules["woodcutting-firepit"] as Dictionary
	firepit_state["last_update"] = now - 90
	scene.passive_modules["woodcutting-firepit"] = firepit_state
	scene.call("_passive_modules_runtime").apply_firepit_fuel(now)
	_expect(not _firepit_active(scene), "firepit should shut down when Scrapwood runs out")
	_expect(scene.material_runtime.amount("scrapwood") <= 0.001, "firepit should spend remaining Scrapwood on shutdown")
	_expect(int((scene.skills["woodcutting"] as Dictionary).get("xp", 0)) == starting_woodcutting_xp + 6, "firepit should award XP for every whole Scrapwood burned before shutdown")
	_expect(absf(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", now)) - 0.08) < 0.001, "Warm Momentum should begin decaying instead of vanishing after shutdown")
	_expect(absf(float(scene.call("_passive_modules_runtime").firepit_heat_bonus_progress_pct(now)) - (0.08 / 0.60 * 100.0)) < 0.25, "Firepit bonus ring should show remaining cooling bonus after shutdown")
	print("woodcutting-firepit-shutdown-ok")
	scene.material_runtime.set_amount("scrapwood", 3.0)
	_expect(bool(scene.call("_passive_modules_runtime").start_firepit(int(scene.call("_unix_now")))), "firepit should restart from a cooling state with available Scrapwood")
	var restart_now := int(scene.call("_unix_now"))
	_expect(absf(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", restart_now)) - 0.08) < 0.001, "Warm Momentum restart should preserve the cooling warmth tier instead of resetting to +4%")
	scene.call("_passive_modules_runtime").extinguish_firepit(int(scene.call("_unix_now")))
	_expect(absf(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", restart_now + 20)) - 0.04) < 0.001, "Warm Momentum should decay by 1 percentage point every 5 seconds")
	_expect(absf(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", restart_now + 40))) < 0.001, "Warm Momentum should fully fade after enough cooling time")
	print("woodcutting-firepit-restart-warmth-ok")
	_check_save_roundtrip(scene)
	print("woodcutting-firepit-save-ok")
	await _check_card_ui(scene)
	print("woodcutting-firepit-card-ok")
	await _check_button_activation(scene)
	print("woodcutting-firepit-button-ok")
	_check_lazy_layout_heights(scene)
	print("woodcutting-firepit-lazy-layout-ok")
	_check_flame_animation_assets(scene)
	print("woodcutting-firepit-flame-ok")
	scene.queue_free()
	if test_failed:
		quit(1)
		return
	print("woodcutting-firepit-ok")
	quit(0)


func _unlock_firepit(scene: Node) -> void:
	if scene.has_method("_test_state_runtime"):
		scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var woodcutting := scene.skills["woodcutting"] as Dictionary
	woodcutting["level"] = maxi(2, int(woodcutting.get("level", 1)))
	woodcutting["xp"] = maxi(int(woodcutting.get("xp", 0)), SkillState.xp_for_level(2))
	scene.skills["woodcutting"] = woodcutting
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "woodcutting", "woodcutting-firepit", "woodcutting firepit test unlock")


func _check_save_roundtrip(scene: Node) -> void:
	var loaded := {
		"active": true,
		"igniting": true,
		"last_update": -10,
		"started_unix": -5,
		"burned_scrapwood": -2.0,
		"cooling_bonus": -1.0,
		"cooling_started_unix": -2,
		"shutdown_reason": "manual"
	}
	var normalized := scene.call("_passive_modules_runtime").firepit_state_from_save(loaded, int(scene.call("_unix_now"))) as Dictionary
	_expect(bool(normalized.get("active", false)), "save normalization should preserve active flag")
	_expect(not bool(normalized.get("igniting", true)), "save normalization should not restore transient ignition")
	_expect(int(normalized.get("started_unix", -1)) == 0, "save normalization should clamp started_unix")
	_expect(float(normalized.get("burned_scrapwood", -1.0)) == 0.0, "save normalization should clamp burned fuel")
	_expect(float(normalized.get("cooling_bonus", -1.0)) == 0.0, "save normalization should clamp cooling bonus")
	_expect(int(normalized.get("cooling_started_unix", -1)) == 0, "save normalization should clamp cooling timestamp")


func _check_card_ui(scene: Node) -> void:
	scene.material_runtime.set_amount("scrapwood", 6.0)
	var now := int(scene.call("_unix_now"))
	scene.passive_modules["woodcutting-firepit"] = {
		"active": true,
		"last_update": now,
		"started_unix": now,
		"burned_scrapwood": 0.0,
		"shutdown_reason": ""
	}
	var action := scene.call("_action_data", "woodcutting", "woodcutting-firepit") as Dictionary
	var result := scene.call("_passive_firepit_surface")._build_firepit_module_card("woodcutting", action, 1080.0, true) as Dictionary
	var card := result.get("card", {}) as Dictionary
	_expect(str((card.get("status") as Label).text).contains("Feels"), "card should show active Firepit comfort status")
	_expect(not card.has("fuel"), "card should not show a boxed fuel line")
	_expect(str((card.get("scrapwood_label") as Label).text).length() > 0, "card should show Scrapwood in the dependency resource module")
	_expect(str((card.get("timer") as Label).text).contains("left"), "card should show active fuel timer")
	_expect((card.get("toggle") as Button).text == "", "firepit click target should not show a separate Stop Fire button")
	_expect((card.get("flame_fx") as Control) != null, "card should include flame FX control")
	_expect((card.get("active_dim") as Control) != null and (card.get("active_dim") as Control).visible, "active firepit card should darken the module background")
	_expect((card.get("firepit_glow") as Control) != null and (card.get("firepit_glow") as Control).visible, "active firepit card should show a warm glow around the fire")
	var progress := card.get("progress") as Control
	_expect(progress != null and progress.has_method("set_inner_target_value"), "card should use the circular firepit fuel ring")
	_expect(str((card.get("info_label") as Label).text) == "Tap firepit to start. Burning Scrapwood rewards XP and increases your Woodcutting stamina regeneration rate.", "firepit info popover should use the concise instructional copy")
	_expect(not card.has("dependency_label"), "card should not show a separate Scrapwood dependency box above the fire")
	_expect((card.get("scrapwood_module") as Control) != null and (card.get("scrapwood_module") as Control).visible, "active card should show the Scrapwood resource module above the Firepit")
	_expect((card.get("scrapwood_connector") as Control) != null and (card.get("scrapwood_connector") as Control).visible, "active card should connect Scrapwood to the Firepit")
	var regen_circle: Control = scene.RegenCircle.new()
	scene.add_child(regen_circle)
	regen_circle.call("sync_for_skill", scene, "woodcutting", true)
	_expect(float(regen_circle.get("firepit_warmth")) > 0.0, "Woodcutting regen circle should show firepit warmth while the fire is active")
	regen_circle.call("sync_for_skill", scene, "fight", true)
	_expect(absf(float(regen_circle.get("firepit_warmth"))) < 0.001, "non-Woodcutting regen circle should not show firepit warmth")
	regen_circle.queue_free()
	var root := result.get("root") as Control
	if root != null:
		scene.add_child(root)
		await process_frame
		var key := str(scene.call("_action_key", "woodcutting", "woodcutting-firepit"))
		scene.action_cards[key] = card
		var before_floats := get_node_count_in_group("skill_reward_float")
		var burn_progress := card.get("progress") as Control
		if burn_progress != null:
			burn_progress.call("set_inner_value", 76.0)
		scene.call("_passive_modules_runtime").call("award_firepit_burn_xp", 3)
		var immediate_floats := get_node_count_in_group("skill_reward_float")
		_expect(immediate_floats == before_floats, "firepit +XP should wait until Scrapwood reaches the fire")
		if burn_progress != null:
			_expect(absf(float(burn_progress.get("inner_value"))) < 0.001, "firepit XP timing should hold the yellow next-Scrapwood ring empty")
			_expect(int(burn_progress.get_meta("firepit_consume_hold_until_msec", 0)) > Time.get_ticks_msec(), "firepit yellow ring empty hold should be active when XP pops")
		scene.call("_passive_firepit_surface").call("_float_firepit_xp_reward_from_fire", 0)
		var after_floats := get_node_count_in_group("skill_reward_float")
		_expect(after_floats >= before_floats + 1, "firepit should spawn visible +XP floats from the fire anchor")
	if root != null:
		root.queue_free()


func _check_lazy_layout_heights(scene: Node) -> void:
	scene.set("selected_skill_id", "woodcutting")
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	var firepit_action := scene.call("_action_data", "woodcutting", "woodcutting-firepit") as Dictionary
	var firepit_result := scene.call("_passive_firepit_surface")._build_firepit_module_card("woodcutting", firepit_action, 1080.0, true) as Dictionary
	var firepit_root := firepit_result.get("root") as Control
	var firepit_height := firepit_root.custom_minimum_size.y if firepit_root != null else 0.0
	if firepit_root != null:
		firepit_root.queue_free()
	var idle_plan := scene.call("_skill_detail_surface").call("_build_detail_lazy_plan", "woodcutting") as Array
	var firepit_entry := _plan_entry(idle_plan, "woodcutting-firepit")
	_expect(not firepit_entry.is_empty(), "lazy plan should include Firepit")
	_expect(absf(float(firepit_entry.get("height", 0.0)) - firepit_height) <= 0.5, "Firepit lazy height should match its actual card height")
	scene.set("running_skill_id", "woodcutting")
	scene.set("running_action_id", "gather-fallen-branches")
	var running_plan := scene.call("_skill_detail_surface").call("_build_detail_lazy_plan", "woodcutting") as Array
	var gather_entry := _plan_entry(running_plan, "gather-fallen-branches")
	_expect(not gather_entry.is_empty(), "lazy plan should include Gather Fallen Branches")
	var expected_gather_height := ActivityCardStyles.root_height(false, 720.0, 1080.0, 34.0) + 870.0
	_expect(absf(float(gather_entry.get("height", 0.0)) - expected_gather_height) <= 0.5, "running material reward action should reserve its collection module height")
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")


func _plan_entry(plan: Array, track_id: String) -> Dictionary:
	for raw_entry in plan:
		var entry := raw_entry as Dictionary
		if str(entry.get("track_id", "")) == track_id:
			return entry
	return {}


func _check_flame_animation_assets(scene: Node) -> void:
	var action := scene.call("_action_data", "woodcutting", "woodcutting-firepit") as Dictionary
	var result := scene.call("_passive_firepit_surface")._build_firepit_module_card("woodcutting", action, 1080.0, true) as Dictionary
	var root := result.get("root") as Control
	var card := result.get("card", {}) as Dictionary
	var fx := card.get("flame_fx") as Control
	_expect(fx != null, "firepit flame FX control should instantiate through PassiveFirepitSurface")
	_expect(absf(float(fx.call("_current_duration")) - 1.5) < 0.001, "firepit flame frames should advance every 1.5 seconds")
	var file := FileAccess.open("res://assets/content/woodcutting/modules/woodcutting-firepit-flame-sheet.png", FileAccess.READ)
	_expect(file != null, "firepit flame sheet should open")
	var image := Image.new()
	var load_result := image.load_png_from_buffer(file.get_buffer(file.get_length()))
	_expect(load_result == OK and not image.is_empty(), "firepit flame sheet should load")
	_expect(image.get_width() == 2048 and image.get_height() == 512, "firepit flame sheet should keep four 512px cells")
	var expected_floor := -1
	for frame_index in range(4):
		var bounds := _alpha_bounds(image, frame_index * 512, 0, 512, 512)
		_expect(bounds.has("left"), "flame frame %s should have visible alpha" % frame_index)
		_expect(int(bounds.get("top", 0)) > 0, "flame frame %s should not touch the top border" % frame_index)
		_expect(int(bounds.get("left", 0)) > 0 and int(bounds.get("right", 511)) < 511, "flame frame %s should not touch side borders" % frame_index)
		var floor := int(bounds.get("bottom", 0))
		if expected_floor < 0:
			expected_floor = floor
		_expect(absi(floor - expected_floor) <= 1, "flame frames should share the same bottom floor")
	if root != null:
		root.queue_free()


func _alpha_bounds(image: Image, start_x: int, start_y: int, width: int, height: int) -> Dictionary:
	var left := width
	var right := -1
	var top := height
	var bottom := -1
	for y in range(start_y, start_y + height):
		for x in range(start_x, start_x + width):
			if image.get_pixel(x, y).a <= 0.002:
				continue
			left = mini(left, x - start_x)
			right = maxi(right, x - start_x)
			top = mini(top, y - start_y)
			bottom = maxi(bottom, y - start_y)
	if right < 0:
		return {}
	return {"left": left, "right": right, "top": top, "bottom": bottom}


func _check_button_activation(scene: Node) -> void:
	_unlock_firepit(scene)
	scene.material_runtime.set_amount("scrapwood", 3.0)
	var now := int(scene.call("_unix_now"))
	scene.passive_modules["woodcutting-firepit"] = {
		"active": false,
		"igniting": false,
		"last_update": now,
		"started_unix": 0,
		"burned_scrapwood": 0.0,
		"cooling_bonus": 0.0,
		"cooling_started_unix": 0,
		"shutdown_reason": "manual"
	}
	var action := scene.call("_action_data", "woodcutting", "woodcutting-firepit") as Dictionary
	var result := scene.call("_passive_firepit_surface")._build_firepit_module_card("woodcutting", action, 1080.0, true) as Dictionary
	var card := result.get("card", {}) as Dictionary
	var root := result.get("root") as Control
	var toggle := card.get("toggle") as Button
	if toggle == null:
		_fail("firepit toggle button was not created")
		return
	_expect(bool(scene.call("_passive_modules_runtime").is_passive_module_unlocked("woodcutting-firepit")), "firepit should be passively unlocked before button signal testing")
	_expect(not toggle.disabled, "firepit toggle should be enabled when Scrapwood is available")
	_expect(toggle.pressed.get_connections().size() > 0, "firepit toggle should connect pressed signal")
	_expect(toggle.button_down.get_connections().size() > 0, "firepit toggle should connect button_down signal")
	_expect(toggle.button_up.get_connections().size() > 0, "firepit toggle should connect button_up signal")
	_expect(toggle.text == "", "inactive firepit click target should not show a separate Start Fire button")
	var progress := card.get("progress") as Control
	_expect(progress != null and absf(float(progress.get("target_value"))) < 0.001, "inactive firepit ring should stay empty even when Scrapwood is ready")
	var timer := card.get("timer") as Label
	_expect(timer != null and str(timer.text).is_empty() and not timer.visible, "inactive firepit should not show Ready text")
	var glow := card.get("firepit_glow") as Control
	_expect(glow != null and glow.visible, "inactive firepit should keep the module dark")
	_expect((card.get("scrapwood_module") as Control) != null and not (card.get("scrapwood_module") as Control).visible, "inactive firepit should hide the Scrapwood dependency module")
	_expect((card.get("scrapwood_connector") as Control) != null and not (card.get("scrapwood_connector") as Control).visible, "inactive firepit should hide the Scrapwood connector")
	var starting_xp := int((scene.skills["woodcutting"] as Dictionary).get("xp", 0))
	toggle.emit_signal("pressed")
	var ignition_state := scene.passive_modules.get("woodcutting-firepit", {}) as Dictionary
	_expect(bool(ignition_state.get("igniting", false)), "Start Fire button signal should begin the ignition sequence")
	_expect(not _firepit_active(scene), "firepit should not become active until Scrapwood reaches the fire")
	scene.call("_passive_modules_runtime").finish_firepit_ignition(int(scene.call("_unix_now")))
	_expect(_firepit_active(scene), "firepit should become active after the ignition Scrapwood lands")
	_expect(absf(scene.material_runtime.amount("scrapwood") - 2.0) < 0.001, "ignition should consume one Scrapwood")
	_expect(int((scene.skills["woodcutting"] as Dictionary).get("xp", 0)) == starting_xp + 2, "ignition should award Woodcutting XP for the burned Scrapwood")
	toggle.emit_signal("pressed")
	_expect(_firepit_active(scene), "tap should not put out an active firepit")
	var firepit_surface = scene.call("_passive_firepit_surface")
	toggle.emit_signal("button_down")
	firepit_surface._process_firepit_stop_hold(0.20)
	toggle.emit_signal("button_up")
	_expect(_firepit_active(scene), "releasing the firepit before hold completion should keep the fire active")
	toggle.emit_signal("button_down")
	firepit_surface._process_firepit_stop_hold(0.20)
	firepit_surface._process_firepit_stop_hold(0.90)
	firepit_surface._process_firepit_stop_hold(0.25)
	toggle.emit_signal("button_up")
	_expect(not _firepit_active(scene), "completed firepit button hold should put out the active fire")
	_expect(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", now)) > 0.0, "completed firepit button hold should leave a decaying Woodcutting regen bonus")
	scene.call("_passive_modules_runtime").start_firepit(int(scene.call("_unix_now")))
	scene.call("_passive_modules_runtime").extinguish_firepit(int(scene.call("_unix_now")))
	_expect(not _firepit_active(scene), "manual extinguish should stop the active firepit")
	_expect(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", now)) > 0.0, "manual extinguish should leave a decaying Woodcutting regen bonus")
	scene.material_runtime.set_amount("scrapwood", 3.0)
	scene.call("_passive_modules_runtime").begin_firepit_ignition(int(scene.call("_unix_now")))
	scene.call("_passive_modules_runtime").finish_firepit_ignition(int(scene.call("_unix_now")))
	var ignition_restart_now := int(scene.call("_unix_now"))
	_expect(absf(float(scene.call("_passive_modules_runtime").call("firepit_stamina_regen_bonus", "woodcutting", ignition_restart_now)) - 0.04) < 0.001, "ignition restart should keep the cooling warmth tier instead of dropping below it")
	scene.call("_passive_modules_runtime").extinguish_firepit(int(scene.call("_unix_now")))
	if root != null and not root.is_inside_tree():
		scene.add_child(root)
		await process_frame
		var action_key := str(scene.call("_action_key", "woodcutting", "woodcutting-firepit"))
		scene.action_cards[action_key] = card
	scene.material_runtime.set_amount("scrapwood", 0.0)
	var floats_before_need := get_node_count_in_group("skill_reward_float")
	scene.call("_passive_modules_runtime").begin_firepit_ignition(int(scene.call("_unix_now")))
	var floats_after_need := get_node_count_in_group("skill_reward_float")
	_expect(floats_after_need >= floats_before_need + 1, "failed firepit start should pop visible Need Scrapwood text")
	scene.passive_modules["woodcutting-firepit"] = {
		"active": false,
		"igniting": false,
		"last_update": now,
		"started_unix": 0,
		"burned_scrapwood": 0.0,
		"cooling_bonus": 0.0,
		"cooling_started_unix": 0,
		"shutdown_reason": "manual"
	}
	if root != null:
		root.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	test_failed = true
	push_error(message)
	print("woodcutting-firepit-failed: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script "res://.codex-tmp/woodcutting-firepit/woodcutting_firepit_test.gd" 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-NoUnexpectedGodotErrors $output "woodcutting firepit validation"
    Assert-True (($output | Out-String) -match "woodcutting-firepit-ok") "Woodcutting Firepit test did not report success."
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    $afterHeadless = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    $settleDeadline = (Get-Date).AddSeconds(5)
    while ($afterHeadless.Count -gt 0 -and (Get-Date) -lt $settleDeadline) {
        Start-Sleep -Milliseconds 500
        $afterHeadless = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    }
    if ($afterHeadless.Count -gt 0) {
        $afterHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "Headless Godot process left behind after Woodcutting Firepit test."
    }
}
