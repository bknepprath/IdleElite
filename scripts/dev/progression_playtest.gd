extends SceneTree

var game: Node
var changing := false
const SkillState = preload("res://scripts/progression/skill_state.gd")

class ChapterKeys extends Node:
	var choose: Callable
	func _input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode in [KEY_F1, KEY_F2, KEY_F3, KEY_F4]:
				choose.call(int(event.keycode - KEY_F1))
				get_viewport().set_input_as_handled()

func _init() -> void:
	call_deferred("start")

func start() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	AudioServer.set_bus_mute(0, false)
	preload("res://scripts/ui/desktop_layout.gd").fit_startup_window(root)
	var keys := ChapterKeys.new()
	keys.choose = chapter
	root.add_child(keys)
	await chapter(0)

func chapter(index: int) -> void:
	if changing: return
	changing = true
	if is_instance_valid(game):
		game._app_lifecycle_runtime()._prepare_for_shutdown()
		game.queue_free()
		await process_frame
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "100")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for attempt in range(1500):
		await create_timer(0.02).timeout
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	if not game.startup_initialized:
		push_error("Progression playtest could not boot")
		changing = false
		return
	game._project_runtime().clear()
	if index == 0:
		# The isolated profile may contain an initial boot/recovery snapshot.
		# F1 always means a genuinely fresh opening, including onboarding.
		game._save_runtime().reset_data()
		await create_timer(0.8).timeout
	else:
		game._test_state_runtime()._god_mode_unlock_onboarding_state()
		game._tutorial_overlay_surface()._update_tutorial_overlay()
		game._tutorial_overlay_surface()._dismiss_blocking_tip()
		game._onboarding_runtime().activity_start_tip_seen = true
		game._activity_unlock_runtime().manual_activity_unlocks.clear()
		game._activity_unlock_runtime().manual_activity_unlocks_trust_checked = false
		var first := {"fight": 9, "thieving": 9, "build": 6, "woodcutting": 15, "fishing": 11}
		for skill in game.skills:
			var level: int = int(first[skill]) if index == 1 else (25 if index == 2 else 70)
			game.skills[skill].xp = SkillState.xp_for_level(level)
			SkillState.recalculate_level(game, skill, false)
			game.stamina[skill] = 99
			for action in game.actions_by_skill[skill]:
				if int(action.unlock) >= level: continue
				var project: Dictionary = action.get("unlock_project", {})
				if not project.is_empty():
					var row := {}
					for step in project.steps: row[str(step.id)] = int(step.target)
					if project.has("cost"): row.materials = 1
					game._project_runtime().work[str(project.id)] = row
				game._activity_unlock_runtime()._mark_action_manually_unlocked(str(skill), str(action.id))
		game.fishing_runtime.rod_collected = true
		game.auto_unlock_lockpads_enabled = false
		game.current_screen = "skill"
		game.selected_skill_id = "build" if index < 3 else "fishing"
		await game._navigation_shell()._render_screen()
		await create_timer(0.8).timeout
		var target := "build-repair-small-shack" if index == 1 else ("build-construct-fishing-pier" if index == 2 else "fishing-chum-line")
		if game.desktop_layout.enabled():
			for column in range(game.desktop_layout.columns.size()):
				if str(game.desktop_layout.columns[column].skill_id) == game.selected_skill_id:
					game.desktop_layout.focus_column(column)
					break
		var detail = game._skill_detail_surface()
		for entry in detail.detail_lazy_plan:
			if str(entry.track_id) == "project:" + target:
				detail.detail_actions_scroll.scroll_vertical = int(entry.y)
				detail._sync_detail_lazy_visible_cards(true, 30)
				break
	root.title = "Idle Elite 0.7.0 Prototype | F1 Opening | F2 First projects | F3 Midgame | F4 Late game | Unsaved test progress"
	print("PLAYTEST_AUDIO driver=", AudioServer.get_driver_name(), " master_muted=", AudioServer.is_bus_mute(0))
	changing = false
	if DisplayServer.get_name() != "headless":
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		if picture.get_size() == root.size:
			picture.save_png("res://.codex-tmp/progression-prototype/playtest.png")
