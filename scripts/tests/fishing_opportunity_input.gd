extends "res://scripts/tests/first_session_input.gd"

const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
var target_action_id := OS.get_environment("IDLE_ELITE_FISHING_TEST_ACTION")

func _run() -> void:
	if target_action_id.is_empty():
		target_action_id = "practice-pool"
	create_timer(90).timeout.connect(func(): quit(1))
	# The safe runner supplies an isolated profile; boot must create its first save.
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "0")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "90")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized, "Production scene must boot")
	if not game.startup_initialized:
		quit(1)
		return
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game._save_runtime().fishing_help_seen = true
	for skill_id in ["fishing", "fight"]:
		game.skills[skill_id].xp = SkillState.xp_for_level(56 if target_action_id == "fight-a-shark" else 2)
		SkillState.recalculate_level(game, skill_id)
	game._activity_unlock_runtime()._mark_action_manually_unlocked("fishing", target_action_id)
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(0.7)
	game.content_scroll.scroll_vertical = 700
	await settle(0.4)
	await click(game.skill_cards.fishing.button.get_global_rect().get_center())
	await settle(1.0)
	check(game.current_screen == "skill" and game.selected_skill_id == "fishing", "Fishing reached through the production menu")
	await game._skill_detail_surface()._scroll_to_activity_card(target_action_id, false, true)
	await settle(0.8)
	var card: Dictionary = game.action_cards.get("fishing:" + target_action_id, {})
	check(not card.is_empty(), "Target fishing activity must be mounted: " + target_action_id)
	if card.is_empty():
		quit(1)
		return
	var action_id := str(card.action_id)
	var key: String = game._action_key("fishing", action_id)
	var runtime = game._action_runtime()
	var button: Control = card.button
	game.mastery[key] = {"xp": MasteryState.xp_for_level(2), "level": 2}
	await click(button.get_global_rect().get_center())
	check(game.running_action_id == action_id, "Native click starts fishing")
	# Freeze simulation only; production UI and real viewport input remain live.
	game.set_process(false)
	capture_dir = "res://.codex-tmp/fishing-opportunity/" + target_action_id
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute(capture_dir)
	for touch in [false, true]:
		game.running_skill_id = "fishing"
		game.running_action_id = action_id
		game.action_progress = 0.62
		runtime.action_opportunity_consumed = false
		runtime.action_opportunity_missed = false
		runtime.action_opportunity_boost_seconds = 0.0
		runtime.last_action_opportunity_tap_key = ""
		game._update_ui(0.0, true)
		await settle(0.4)
		if not touch:
			await capture("before-timing-tap")
		await click(button.get_global_rect().get_center(), touch)
		check(game.running_skill_id == "fishing" and game.running_action_id == action_id, "Timing tap must keep fishing active; touch=%s" % touch)
		check(runtime.action_opportunity_boost_seconds > 0.0, "Timing tap must award the opportunity boost; touch=%s" % touch)
		check(game.action_progress > 0.62, "Timing tap must advance progress; touch=%s" % touch)
		game._update_ui(0.0, true)
		if not touch:
			await capture("after-timing-tap")
		# A mistimed attempt gives miss feedback without toggling the activity.
		game.action_progress = 0.1
		runtime.action_opportunity_consumed = false
		runtime.action_opportunity_missed = false
		runtime.action_opportunity_boost_seconds = 0.0
		game._update_ui(0.0, true)
		await settle(0.4)
		await click(button.get_global_rect().get_center(), touch)
		check(game.running_action_id == action_id, "Missed timing tap must not stop fishing; touch=%s" % touch)
		check(runtime.action_opportunity_missed, "Mistimed tap must register a miss; touch=%s" % touch)
		check(runtime.action_opportunity_boost_seconds == 0.0, "Missed tap must not award a boost")
		# Judge at press time even when the progress bar moves before release.
		game.action_progress = 0.62
		runtime.action_opportunity_consumed = false
		runtime.action_opportunity_missed = false
		runtime.last_action_opportunity_tap_key = ""
		game._update_ui(0.0, true)
		await settle(0.4)
		var point := button.get_global_rect().get_center()
		for down in [true, false]:
			var event: InputEvent
			if touch:
				var tap := InputEventScreenTouch.new()
				tap.position = point
				tap.pressed = down
				event = tap
			else:
				var tap := InputEventMouseButton.new()
				tap.position = point
				tap.global_position = point
				tap.button_index = MOUSE_BUTTON_LEFT
				tap.pressed = down
				event = tap
			root.push_input(event, true)
			await process_frame
			if down:
				check(runtime.action_opportunity_consumed, "Opportunity must be judged on press, not release")
				game.action_progress = 0.9
			# Godot can synthesize the other pointer type for the same gesture.
			var emulated: InputEvent
			if touch:
				var copy := InputEventMouseButton.new()
				copy.position = point
				copy.global_position = point
				copy.button_index = MOUSE_BUTTON_LEFT
				copy.pressed = down
				emulated = copy
			else:
				var copy := InputEventScreenTouch.new()
				copy.position = point
				copy.pressed = down
				emulated = copy
			emulated.device = InputEvent.DEVICE_ID_EMULATION
			root.push_input(emulated, true)
			await process_frame
		check(game.running_action_id == action_id, "Release outside the timing window must not stop fishing")
		# Activities without an opportunity retain their existing start/stop click.
		game.mastery[key] = {"xp": 0, "level": 0}
		runtime.action_opportunity_consumed = false
		runtime.action_opportunity_missed = false
		await settle(0.4)
		await click(button.get_global_rect().get_center(), touch)
		check(game.running_action_id.is_empty(), "Ordinary stop tap must still stop fishing")
		await click(button.get_global_rect().get_center(), touch)
		check(game.running_action_id == action_id, "Ordinary start tap must still start fishing")
		game.mastery[key] = {"xp": MasteryState.xp_for_level(2), "level": 2}
	print("FISHING_OPPORTUNITY_INPUT failures=", failures)
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
