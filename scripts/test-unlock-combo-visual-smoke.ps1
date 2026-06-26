param(
    [switch]$TripleOnly,
    [switch]$FishingComboOnly
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\unlock-combo-visual-smoke"
$testScript = Join-Path $testDir "unlock_combo_visual_smoke.gd"

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
$previousTripleOnly = $env:IDLE_ELITE_TRIPLE_LOCK_SMOKE_ONLY
$previousFishingComboOnly = $env:IDLE_ELITE_FISHING_COMBO_SMOKE_ONLY
$env:GODOT_RUN_TIMEOUT_SECONDS = "120"
if ($TripleOnly) {
    $env:IDLE_ELITE_TRIPLE_LOCK_SMOKE_ONLY = "1"
} else {
    $env:IDLE_ELITE_TRIPLE_LOCK_SMOKE_ONLY = "0"
}
if ($FishingComboOnly) {
    $env:IDLE_ELITE_FISHING_COMBO_SMOKE_ONLY = "1"
} else {
    $env:IDLE_ELITE_FISHING_COMBO_SMOKE_ONLY = "0"
}

try {
    @'
extends SceneTree

const ActivityLockRig = preload("res://scripts/activity_lock_rig.gd")
const BOOT_TIMEOUT_FRAMES := 720
const LOCK_ALPHA_THRESHOLD := 0.08

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("unlock-combo-visual-smoke-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	root.size = Vector2i(1800, 900)
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return
	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_max_skills_state")
	scene.call("_god_mode_unlock_actions_state")

	if OS.get_environment("IDLE_ELITE_FISHING_COMBO_SMOKE_ONLY") == "1":
		await _check_fishing_combo_progress_rails(scene)
	elif OS.get_environment("IDLE_ELITE_TRIPLE_LOCK_SMOKE_ONLY") == "1":
		await _check_three_lock_combo(scene)
	else:
		await _check_mono_lock(scene)
		await _check_two_lock_combo(scene)
		await _check_three_lock_combo(scene)
		await _check_five_lock_cluster(scene)
		await _check_drop_animation(scene)
		await _check_colored_xp_floats(scene)
		await _check_event_insertion(scene)
		await _check_fishing_combo_progress_rails(scene)

	if failures.is_empty():
		print("unlock-combo-visual-smoke-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _check_mono_lock(scene: Node) -> void:
	var action := _first_action_with_requirement_count(scene, "build", 1)
	if action.is_empty():
		_record("no mono build action available for visual smoke")
		return
	var requirements := scene.call("_lock_requirements_for_overlay", "build", action) as Array
	var cluster := await _build_lock_cluster(scene, "mono", int(action.get("unlock", 1)), "build", requirements)
	if cluster == null:
		return
	_expect_rig_count(cluster, 1, "mono lock")
	var rigs := cluster.get("rigs") as Array
	if not rigs.is_empty():
		var rig := rigs[0] as Control
		_expect_color_close(_rig_tint_color(rig), scene.call("_skill_theme_color", "build") as Color, "mono lock build tint")


func _check_two_lock_combo(scene: Node) -> void:
	var action := scene.call("_action_data", "thieving", "scope-out-a-heist") as Dictionary
	if action.is_empty():
		_record("missing thieving/build combo action scope-out-a-heist")
		return
	var requirements := scene.call("_lock_requirements_for_overlay", "thieving", action) as Array
	var cluster := await _build_lock_cluster(scene, "two-lock", int(action.get("unlock", 1)), "thieving", requirements)
	if cluster == null:
		return
	_expect_rig_count(cluster, 2, "two-lock combo")
	cluster.call("set_requirement_states", [
		{"skill": "thieving", "level": 34, "met": true},
		{"skill": "build", "level": 29, "met": false},
	])
	await process_frame
	var rigs := cluster.get("rigs") as Array
	if rigs.size() >= 2:
		_expect_equal(str((rigs[0] as Control).get("lock_state")), ActivityLockRig.LOCK_STATE_READY_OPEN, "first combo lock ready-open")
		_expect_equal(str((rigs[1] as Control).get("lock_state")), ActivityLockRig.LOCK_STATE_CLOSED, "second combo lock closed")
		_expect_color_close(_rig_tint_color(rigs[0] as Control), scene.call("_skill_theme_color", "thieving") as Color, "thieving lock tint")
		_expect_color_close(_rig_tint_color(rigs[1] as Control), scene.call("_skill_theme_color", "build") as Color, "build lock tint")
		_expect_ready_open_lock_kinematics(rigs[0] as Control)


func _check_three_lock_combo(scene: Node) -> void:
	var found_actions := _action_refs_with_requirement_count(scene, 3)
	if found_actions.is_empty():
		_record("no triple-lock combo action available for visual smoke")
		return
	for raw_found in found_actions:
		await _check_three_lock_combo_action(scene, raw_found as Dictionary)


func _check_three_lock_combo_action(scene: Node, found: Dictionary) -> void:
	var skill_id := str(found.get("skill_id", ""))
	var action := found.get("action", {}) as Dictionary
	var action_id := str(action.get("id", ""))
	var requirements := scene.call("_lock_requirements_for_overlay", skill_id, action) as Array
	var label := "three-lock combo %s:%s" % [skill_id, action_id]
	print("triple-lock-action=%s:%s" % [skill_id, action_id])
	var cluster := await _build_lock_cluster(scene, "three-lock-%s" % action_id, int(action.get("unlock", 1)), skill_id, requirements)
	if cluster == null:
		return
	_expect_rig_count(cluster, 3, label)
	if requirements.size() != 3:
		_record("%s expected 3 requirements, found %s" % [label, requirements.size()])
	var states := []
	for index in range(requirements.size()):
		var requirement := requirements[index] as Dictionary
		states.append({
			"skill": str(requirement.get("skill", skill_id)),
			"level": int(requirement.get("level", 1)),
			"met": index != 1,
		})
	cluster.call("set_requirement_states", states)
	await process_frame
	var rigs := cluster.get("rigs") as Array
	var seen_positions := {}
	for index in range(mini(rigs.size(), requirements.size())):
		var rig := rigs[index] as Control
		var requirement := requirements[index] as Dictionary
		var requirement_skill := str(requirement.get("skill", skill_id))
		var expected_state := ActivityLockRig.LOCK_STATE_CLOSED if index == 1 else ActivityLockRig.LOCK_STATE_READY_OPEN
		_expect_equal(str(rig.get("lock_state")), expected_state, "%s rig %s state" % [label, index])
		_expect_color_close(_rig_tint_color(rig), scene.call("_skill_theme_color", requirement_skill) as Color, "%s %s tint" % [label, requirement_skill])
		if index != 1:
			_expect_ready_open_lock_kinematics(rig)
		var key := "%0.2f:%0.2f" % [rig.position.x, rig.position.y]
		if seen_positions.has(key):
			_record("%s has overlapping rig positions at %s" % [label, key])
		seen_positions[key] = true
	_expect_visual_lock_rects(cluster, rigs, label)
	cluster.call("play_unlock_drop_animation")
	await process_frame
	if not bool(cluster.get("unlock_drop_active")):
		_record("%s drop animation did not mark cluster active" % label)
	for index in range(rigs.size()):
		_expect_equal(str((rigs[index] as Control).get("lock_state")), ActivityLockRig.LOCK_STATE_DROPPING, "%s drop rig %s state" % [label, index])


func _check_five_lock_cluster(scene: Node) -> void:
	var skills := ["fight", "thieving", "build", "woodcutting", "fishing"]
	var requirements := []
	for index in range(skills.size()):
		var skill_id := str(skills[index])
		requirements.append({
			"skill": skill_id,
			"level": 10 + index,
			"theme_color": scene.call("_skill_theme_color", skill_id) as Color,
		})
	var cluster := await _build_lock_cluster(scene, "five-lock", 20, "fight", requirements)
	if cluster == null:
		return
	_expect_rig_count(cluster, 5, "five-lock combo")
	var rigs := cluster.get("rigs") as Array
	var seen_positions := {}
	for index in range(rigs.size()):
		var rig := rigs[index] as Control
		var key := "%0.2f:%0.2f" % [rig.position.x, rig.position.y]
		if seen_positions.has(key):
			_record("five-lock combo has overlapping rig positions at %s" % key)
		seen_positions[key] = true
		if rig.scale.x > 0.55:
			_record("five-lock rig %s is too large for clustered layout: %.3f" % [index, rig.scale.x])


func _check_drop_animation(scene: Node) -> void:
	var action := scene.call("_action_data", "thieving", "scope-out-a-heist") as Dictionary
	var requirements := scene.call("_lock_requirements_for_overlay", "thieving", action) as Array
	var cluster := await _build_lock_cluster(scene, "drop", int(action.get("unlock", 1)), "thieving", requirements)
	if cluster == null:
		return
	cluster.call("set_requirement_states", [
		{"skill": "thieving", "level": 34, "met": true},
		{"skill": "build", "level": 29, "met": true},
	])
	cluster.call("play_unlock_drop_animation")
	await process_frame
	if not bool(cluster.get("unlock_drop_active")):
		_record("drop animation did not mark cluster active")
	var rigs := cluster.get("rigs") as Array
	for index in range(rigs.size()):
		_expect_equal(str((rigs[index] as Control).get("lock_state")), ActivityLockRig.LOCK_STATE_DROPPING, "drop rig %s state" % index)


func _check_colored_xp_floats(scene: Node) -> void:
	var parent := Control.new()
	parent.size = Vector2(1800, 1200)
	parent.position = Vector2.ZERO
	root.add_child(parent)
	var anchor := Control.new()
	anchor.size = Vector2(320, 220)
	anchor.position = Vector2(720, 620)
	parent.add_child(anchor)
	scene.call("_float_xp_rewards", parent, anchor, {"thieving": 120, "woodcutting": 30}, "thieving")
	await process_frame
	var labels := []
	for raw_node in get_nodes_in_group("skill_reward_float"):
		_collect_labels(raw_node as Node, labels)
	var found_thieving := false
	var found_woodcutting := false
	var found_thieving_color := false
	var found_woodcutting_color := false
	var xp_label_count := 0
	for raw_label in labels:
		var label := raw_label as Label
		if label == null:
			continue
		var text := label.text
		var color := label.get_theme_color("font_color")
		if text.find("XP") < 0:
			continue
		xp_label_count += 1
		if _color_distance(color, scene.call("_skill_theme_color", "thieving") as Color) <= 0.30:
			found_thieving = true
			found_thieving_color = true
		if _color_distance(color, scene.call("_skill_theme_color", "woodcutting") as Color) <= 0.30:
			found_woodcutting = true
			found_woodcutting_color = true
	if xp_label_count < 2:
		_record("expected at least two colored XP float labels, found %s" % xp_label_count)
	if not found_thieving:
		_record("missing thieving colored XP float")
	elif not found_thieving_color:
		_record("missing thieving foreground XP float color")
	if not found_woodcutting:
		_record("missing woodcutting colored XP float")
	elif not found_woodcutting_color:
		_record("missing woodcutting foreground XP float color")
	parent.queue_free()


func _check_event_insertion(scene: Node) -> void:
	var event_id := "covered-wagon-ambush-drill"
	var event_def := scene.call("_event_module_def", event_id) as Dictionary
	if event_def.is_empty():
		_record("missing covered wagon event definition")
		return
	var page := str(event_def.get("page", ""))
	var now := int(scene.call("_unix_now"))
	var active := scene.get("temporary_event_active") as Dictionary
	active[event_id] = {
		"event_id": event_id,
		"spawned_unix": now,
		"expires_unix": now + 900,
		"completed": false,
	}
	scene.set("temporary_event_active", active)
	var event_actions := scene.call("_active_event_actions_for_skill", page) as Array
	if event_actions.is_empty():
		_record("active event action did not appear for %s" % page)
		return
	var entries := scene.call("_visible_detail_entries_for_skill", page) as Array
	var event_index := -1
	for index in range(entries.size()):
		var entry := entries[index] as Dictionary
		var action := entry.get("action", {}) as Dictionary
		if str(action.get("id", "")) == event_id:
			event_index = index
			break
	if event_index < 0:
		_record("event module was not inserted into visible detail entries")
		return
	var event_sort := int(scene.call("_activity_action_display_sort_level", event_def))
	if event_index > 0:
		var prev_action := (entries[event_index - 1] as Dictionary).get("action", {}) as Dictionary
		if not prev_action.is_empty() and int(scene.call("_activity_action_display_sort_level", prev_action)) > event_sort:
			_record("event module sorted before a higher-level previous action")
	if event_index < entries.size() - 1:
		var next_action := (entries[event_index + 1] as Dictionary).get("action", {}) as Dictionary
		if not next_action.is_empty() and int(scene.call("_activity_action_display_sort_level", next_action)) < event_sort:
			_record("event module sorted after a lower-level next action")
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", page)
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(4):
		await process_frame
	var event_plan_item := scene.call("_detail_lazy_entry_for_track_id", event_id) as Dictionary
	if event_plan_item.is_empty():
		_record("event module was not present in the detail lazy plan")
		return
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	var target_scroll := 0
	var max_scroll := 0
	if scroll != null:
		max_scroll = int(scroll.call("get_max_scroll_vertical"))
		target_scroll = clampi(maxi(0, int(event_plan_item.get("y", 0.0)) - 120), 0, max_scroll)
		scroll.call("scroll_to_vertical", target_scroll, 0.0)
		scroll.set("drag_scroll_position", float(target_scroll))
		scroll.set("scroll_vertical", target_scroll)
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	scene.call("_ensure_detail_lazy_entry_mounted", event_id)
	var cards := scene.get("action_cards") as Dictionary
	var card_key := "%s:%s" % [page, event_id]
	if not cards.has(card_key):
		_record("event module did not render an action card at %s after scrolling to its lazy slot; target_scroll=%s max_scroll=%s actual_scroll=%s plan=%s cards=%s nodes=%s" % [
			card_key,
			target_scroll,
			max_scroll,
			int(scroll.get("scroll_vertical")) if scroll != null else -1,
			_detail_lazy_plan_debug(scene),
			_string_array(scene.get("action_cards") as Dictionary),
			_string_array(scene.get("detail_action_card_nodes") as Dictionary),
		])


func _check_fishing_combo_progress_rails(scene: Node) -> void:
	scene.call("_stage_art_review_test_save")
	await _render_live_fishing_page(scene)
	await _check_fishing_scroll_limit_reaches_lazy_bottom(scene)
	var combo_actions := scene.call("_fishing_visible_standalone_actions", "fishing") as Array
	if combo_actions.is_empty():
		_record("no Fishing standalone combo actions available for progress rail check")
		return
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(1800, 1)
	root.add_child(stack)
	scene.set("detail_lazy_stack", stack)
	scene.call("_render_fishing_area_modules", stack, 1800.0)
	for _i in range(4):
		await process_frame
	var plan := scene.get("detail_lazy_plan") as Array
	for raw_action in combo_actions:
		var action := raw_action as Dictionary
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		var plan_item := _plan_item_for_track(plan, action_id)
		if plan_item.is_empty():
			_record("Fishing combo %s was missing from the detail plan" % action_id)
			continue
		if str(plan_item.get("kind", "")) != "action":
			_record("Fishing combo %s should render as an action item, got %s" % [action_id, str(plan_item.get("kind", ""))])
			continue
		for raw_item in plan:
			var item := raw_item as Dictionary
			if str(item.get("kind", "")) != "fishing_area":
				continue
			for raw_method_id in item.get("method_ids", []) as Array:
				if str(raw_method_id) == action_id:
					_record("Fishing combo %s was still owned by an area method tile" % action_id)
		scene.call("_ensure_detail_lazy_entry_mounted", action_id)
		var card := _action_card_for_action_id(scene.get("action_cards") as Dictionary, action_id)
		if card.is_empty():
			_record("Fishing combo %s did not mount an action card" % action_id)
			continue
		if card.get("progress") == null:
			_record("Fishing combo %s has no progress rail" % action_id)
		if card.get("fluid_strip") != null:
			_record("Fishing combo %s still has a Fishing fluid strip" % action_id)
	stack.queue_free()


func _render_live_fishing_page(scene: Node) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(4):
		await process_frame


func _check_fishing_scroll_limit_reaches_lazy_bottom(scene: Node) -> void:
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null:
		_record("Fishing detail page did not create an actions scroll")
		return
	scene.call("_sync_detail_actions_scroll_limit")
	await process_frame
	var plan := scene.get("detail_lazy_plan") as Array
	var expected_bottom := _expected_fishing_lazy_module_bottom(scene, plan)
	if expected_bottom <= 1.0:
		_record("Fishing lazy plan had no scrollable module bottom")
		return
	var viewport_height := float(scene.call("_detail_actions_scroll_viewport_height"))
	var bottom_gap := maxf(
		0.0,
		float(scene.call("_skill_detail_bottom_scroll_pad", "fishing")) - float(scene.call("_skills_content_bottom_inset_for_screen"))
	)
	var expected_max := maxi(0, int(ceil(expected_bottom + bottom_gap - viewport_height)))
	var actual_max := int(scroll.call("get_max_scroll_vertical"))
	if actual_max + 2 < expected_max:
		_record("Fishing scroll max stops before lazy bottom: actual=%s expected>=%s bottom=%s viewport=%s gap=%s plan=%s" % [
			actual_max,
			expected_max,
			expected_bottom,
			viewport_height,
			bottom_gap,
			_detail_lazy_plan_debug(scene),
		])
	scroll.call("scroll_to_vertical", actual_max, 0.0)
	scroll.set("drag_scroll_position", float(actual_max))
	scroll.set("scroll_vertical", actual_max)
	await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	await process_frame
	var last_item := _last_scrollable_fishing_plan_item(plan)
	if last_item.is_empty():
		_record("Fishing lazy plan had no final scrollable item")
		return
	if not bool(last_item.get("mounted", false)):
		_record("Fishing last module did not mount at bottom scroll: kind=%s track=%s actual=%s expected>=%s" % [
			str(last_item.get("kind", "")),
			str(last_item.get("track_id", "")),
			actual_max,
			expected_max,
		])


func _expected_fishing_lazy_module_bottom(scene: Node, plan: Array) -> float:
	var top_spacer_height := float(scene.call("_detail_actions_top_spacer_height"))
	var stack := scene.get("detail_lazy_stack") as VBoxContainer
	var stack_separation := 56.0
	if stack != null:
		stack_separation = float(stack.get_theme_constant("separation"))
	var bottom := 0.0
	for raw_item in plan:
		var item := raw_item as Dictionary
		var kind := str(item.get("kind", ""))
		if not kind in ["action", "passive", "heist", "fishing_area", "fishing_offer"]:
			continue
		bottom = maxf(
			bottom,
			top_spacer_height + stack_separation + float(item.get("y", 0.0)) + float(item.get("height", 0.0))
		)
	return bottom


func _last_scrollable_fishing_plan_item(plan: Array) -> Dictionary:
	for index in range(plan.size() - 1, -1, -1):
		var item := plan[index] as Dictionary
		var kind := str(item.get("kind", ""))
		if kind in ["action", "passive", "heist", "fishing_area", "fishing_offer"]:
			return item
	return {}


func _plan_item_for_track(plan: Array, track_id: String) -> Dictionary:
	for raw_item in plan:
		var item := raw_item as Dictionary
		if str(item.get("track_id", "")) == track_id:
			return item
	return {}


func _action_card_for_action_id(cards: Dictionary, action_id: String) -> Dictionary:
	for raw_card in cards.values():
		var card := raw_card as Dictionary
		var action := card.get("action", {}) as Dictionary
		if str(action.get("id", card.get("action_id", ""))) == action_id:
			return card
	return {}


func _build_lock_cluster(scene: Node, name: String, unlock_level: int, skill_id: String, requirements: Array) -> Control:
	var parent := Control.new()
	parent.name = "VisualSmoke%sParent" % name.capitalize()
	parent.size = Vector2(1800, 900)
	root.add_child(parent)
	var overlay := scene.call("_activity_lock_overlay", parent, unlock_level, skill_id, requirements) as Dictionary
	var overlay_root := overlay.get("root") as Control
	var cluster := overlay.get("group") as Control
	if overlay_root == null or cluster == null:
		_record("%s lock overlay did not build" % name)
		parent.queue_free()
		return null
	overlay_root.size = parent.size
	cluster.size = parent.size
	cluster.visible = true
	overlay_root.visible = true
	cluster.call("_layout_base")
	await process_frame
	return cluster


func _first_action_with_requirement_count(scene: Node, skill_id: String, count: int) -> Dictionary:
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	for raw_action in actions_by_skill.get(skill_id, []) as Array:
		var action := raw_action as Dictionary
		var requirements := scene.call("_action_unlock_requirements", skill_id, action) as Array
		if requirements.size() == count:
			return action
	return {}


func _first_action_ref_with_requirement_count(scene: Node, count: int) -> Dictionary:
	var skill_defs := scene.get("skill_defs") as Array
	for raw_skill_def in skill_defs:
		var skill_def := raw_skill_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		var action := _first_action_with_requirement_count(scene, skill_id, count)
		if not action.is_empty():
			return {
				"skill_id": skill_id,
				"action": action,
			}
	return {}


func _action_refs_with_requirement_count(scene: Node, count: int) -> Array:
	var result := []
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	var skill_defs := scene.get("skill_defs") as Array
	for raw_skill_def in skill_defs:
		var skill_def := raw_skill_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		for raw_action in actions_by_skill.get(skill_id, []) as Array:
			var action := raw_action as Dictionary
			var requirements := scene.call("_action_unlock_requirements", skill_id, action) as Array
			if requirements.size() == count:
				result.append({
					"skill_id": skill_id,
					"action": action,
				})
	return result


func _expect_rig_count(cluster: Control, expected: int, label: String) -> void:
	var rigs := cluster.get("rigs") as Array
	if rigs.size() != expected:
		_record("%s expected %s locks, found %s" % [label, expected, rigs.size()])


func _rig_tint_color(rig: Control) -> Color:
	if rig == null:
		return Color.TRANSPARENT
	var tint := rig.get("padlock_tint") as CanvasItem
	if tint == null:
		return Color.TRANSPARENT
	return tint.modulate


func _expect_equal(actual: String, expected: String, label: String) -> void:
	if actual != expected:
		_record("%s expected %s, found %s" % [label, expected, actual])


func _expect_color_close(actual: Color, expected: Color, label: String) -> void:
	var distance := _color_distance(actual, expected)
	if distance > 0.30:
		_record("%s color mismatch: actual=%s expected=%s" % [label, actual, expected])


func _expect_ready_open_lock_kinematics(rig: Control) -> void:
	var body := rig.get("padlock") as Control
	var shackle := rig.get("padlock_shackle") as Control
	if body == null or shackle == null:
		_record("ready-open lock missing split body/shackle controls")
		return
	if absf(body.rotation - shackle.rotation) > 0.001:
		_record("ready-open shackle rotated independently of lock body")
	if absf(body.position.x - shackle.position.x) > 0.001:
		_record("ready-open shackle moved horizontally instead of only vertically")
	if shackle.position.y >= body.position.y:
		_record("ready-open shackle did not slide vertically upward from the lock body")


func _expect_visual_lock_rects(cluster: Control, rigs: Array, label: String) -> void:
	var cluster_rect := cluster.get_global_rect()
	var rects := []
	for index in range(rigs.size()):
		var rig := rigs[index] as Control
		var rect := _lock_visual_global_rect(rig)
		print("%s opaque rect %s: %s" % [label, index, rect])
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			_record("%s rig %s did not expose a visible lock rect" % [label, index])
			continue
		if not cluster_rect.encloses(rect):
			_record("%s rig %s lock rect sits outside the overlay: rect=%s overlay=%s" % [label, index, rect, cluster_rect])
		for raw_previous in rects:
			var previous := raw_previous as Rect2
			var overlap := rect.intersection(previous)
			if overlap.size.x > 1.0 and overlap.size.y > 1.0:
				_record("%s lock rects overlap: %s with %s" % [label, rect, previous])
		rects.append(rect)


func _lock_visual_global_rect(rig: Control) -> Rect2:
	if rig == null:
		return Rect2()
	var merged := Rect2()
	var has_rect := false
	for property in ["padlock", "padlock_shackle"]:
		var part := rig.get(property) as TextureRect
		if part == null or not part.visible:
			continue
		var rect := _texture_part_opaque_global_rect(part)
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			rect = part.get_global_rect()
		if not has_rect:
			merged = rect
			has_rect = true
		else:
			merged = merged.merge(rect)
	return merged


func _texture_part_opaque_global_rect(part: TextureRect) -> Rect2:
	if part == null or part.texture == null:
		return Rect2()
	var image := part.texture.get_image()
	if image == null or image.is_empty():
		return Rect2()
	if image.is_compressed() and image.decompress() != OK:
		return Rect2()
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var alpha_bounds := _image_alpha_bounds(image)
	if alpha_bounds.size.x <= 0 or alpha_bounds.size.y <= 0:
		return Rect2()
	var texture_size := Vector2(float(image.get_width()), float(image.get_height()))
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()
	var fit_scale := minf(part.size.x / texture_size.x, part.size.y / texture_size.y)
	var drawn_size := texture_size * fit_scale
	var drawn_position := (part.size - drawn_size) * 0.5
	var local_rect := Rect2(
		drawn_position + Vector2(alpha_bounds.position) * fit_scale,
		Vector2(alpha_bounds.size) * fit_scale
	)
	return _transform_rect(part.get_global_transform(), local_rect)


func _image_alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a < LOCK_ALPHA_THRESHOLD:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))


func _transform_rect(transform: Transform2D, rect: Rect2) -> Rect2:
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	var first := transform * (corners[0] as Vector2)
	var min_pos := first
	var max_pos := first
	for index in range(1, corners.size()):
		var point := transform * (corners[index] as Vector2)
		min_pos.x = minf(min_pos.x, point.x)
		min_pos.y = minf(min_pos.y, point.y)
		max_pos.x = maxf(max_pos.x, point.x)
		max_pos.y = maxf(max_pos.y, point.y)
	return Rect2(min_pos, max_pos - min_pos)


func _color_distance(actual: Color, expected: Color) -> float:
	return absf(actual.r - expected.r) + absf(actual.g - expected.g) + absf(actual.b - expected.b)


func _collect_labels(node: Node, labels: Array) -> void:
	if node == null:
		return
	if node is Label:
		labels.append(node)
	for child in node.get_children():
		_collect_labels(child, labels)


func _detail_lazy_plan_debug(scene: Node) -> Array:
	var result := []
	var plan := scene.get("detail_lazy_plan") as Array
	for raw_item in plan:
		var item := raw_item as Dictionary
		result.append("%s:%s:%s" % [str(item.get("kind", "")), str(item.get("track_id", "")), str(item.get("mounted", false))])
	return result


func _string_array(dictionary: Dictionary) -> Array:
	var result := []
	for raw_key in dictionary.keys():
		result.append(str(raw_key))
	result.sort()
	return result


func _record(message: String) -> void:
	failures.append(message)


func _fail(message: String) -> void:
	push_error("unlock-combo-visual-smoke-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "unlock-combo-visual-smoke-ok") "Unlock combo visual smoke did not report success."
    Assert-NoUnexpectedGodotErrors $output "unlock combo visual smoke"
    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after unlock combo visual smoke."
    }
}
finally {
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    if ($null -eq $previousTripleOnly) {
        Remove-Item Env:\IDLE_ELITE_TRIPLE_LOCK_SMOKE_ONLY -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TRIPLE_LOCK_SMOKE_ONLY = $previousTripleOnly
    }
    if ($null -eq $previousFishingComboOnly) {
        Remove-Item Env:\IDLE_ELITE_FISHING_COMBO_SMOKE_ONLY -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FISHING_COMBO_SMOKE_ONLY = $previousFishingComboOnly
    }
}
