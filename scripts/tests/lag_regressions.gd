extends SceneTree

const FishingState = preload("res://scripts/fishing/state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
var host: Node
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func run() -> void:
	create_timer(160).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "150")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	AudioServer.set_bus_mute(0, true)
	host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	while not host.startup_initialized or host._boot_warmup_runtime().active: await process_frame
	host._test_state_runtime()._god_mode_unlock_onboarding_state()
	host.selected_skill_id = "fishing"
	host.auto_unlock_lockpads_enabled = false
	var unlocks = host._activity_unlock_runtime()
	var projects = host._project_runtime()
	var cases := 0
	var positive_cases := 0
	var old_us := 0
	var new_us := 0
	# Compare with the previous implementation across level, tool, resource,
	# Wisdom and manual-unlock changes, including multiple changes in one frame.
	for resources_complete in [false, true]:
		projects.work.clear()
		if resources_complete:
			for definition in projects.definitions.values():
				var work := {"materials": 1}
				for step in definition.project.steps: work[str(step.id)] = int(step.target)
				projects.work[str(definition.project.id)] = work
		for level in [1, 5, 15, 30, 60, 99]:
			for skill in host.skills:
				host.skills[skill].xp = SkillState.xp_for_level(level)
				SkillState.recalculate_level(host, skill, false)
			for wisdom in [0, 100000]:
				host.material_runtime.wisdom_by_skill["fishing"] = wisdom
				for tool in FishingState.FISHING_TOOL_DEFS:
					host.fishing_runtime.equipped_tool_id = str(tool.id)
					for unlocked_count in [0, 1, 3, 8, 18, 99]:
						unlocks.manual_activity_unlocks.clear()
						unlocks.manual_activity_requirement_unlocks.clear()
						for action in host.actions_by_skill.fishing.slice(0, unlocked_count):
							unlocks._mark_action_manually_unlocked("fishing", str(action.id))
						var start := Time.get_ticks_usec()
						var expected := reference_next_unlock()
						old_us += Time.get_ticks_usec() - start
						start = Time.get_ticks_usec()
						var actual: String = unlocks._fishing_next_visible_auto_unlock_action_id()
						new_us += Time.get_ticks_usec() - start
						check(actual == expected, "Unlock mismatch: level=%s tool=%s prefix=%s expected=%s actual=%s" % [level, tool.id, unlocked_count, expected, actual])
						cases += 1
						if not actual.is_empty(): positive_cases += 1
	check(positive_cases > 0, "Fixture must exercise available unlocks")
	print("UNLOCK_SCAN cases=%d available=%d reference_us=%d optimized_us=%d" % [cases, positive_cases, old_us, new_us])
	await test_cleanup()
	print("lag-regression-ok" if failures.is_empty() else "lag-regression-failed")
	host.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

func test_cleanup() -> void:
	var parent := Control.new()
	host.add_child(parent)
	var art := Control.new()
	art.modulate.a = 0.35
	parent.add_child(art)
	var reveal := Control.new()
	parent.add_child(reveal)
	reveal.position.y = 80
	reveal.scale = Vector2(0.5, 0.5)
	reveal.set_meta("detail_lazy_reveal_base_y", 20.0)
	reveal.set_meta("detail_lazy_reveal_base_scale", Vector2.ONE)
	var tween_keys := ["detail_lazy_reveal_tween", "depress_tween", "reset_feedback_tween", "bonus_tween", "bonus_content_tween", "medal_ceremony_tween", "medal_outgoing_tween", "medal_tap_pop_tween", "medal_tap_effect_tween", "mastery_bar_tween", "activity_crit_text_tween", "hub_decor_pop_tween", "mat_flyer_tween", "mat_pulse_tween", "fishing_net_offer_idle_tween"]
	var tweens: Array[Tween] = []
	for key in tween_keys:
		var tween := host.create_tween()
		tween.tween_interval(10)
		reveal.set_meta(key, tween)
		tweens.append(tween)
	var button := Button.new()
	parent.add_child(button)
	button.set_meta("reset_feedback_active", true)
	var persistent := host.create_tween()
	persistent.tween_interval(10)
	art.set_meta("unrelated_tween", persistent)
	host._app_lifecycle_runtime()._kill_transient_tweens_in_subtree(parent)
	for i in range(tween_keys.size()):
		check(not tweens[i].is_valid() and not reveal.has_meta(tween_keys[i]), "Transient tween survives: " + str(tween_keys[i]))
	check(reveal.position.y == 20 and reveal.scale == Vector2.ONE, "Reveal geometry must restore")
	check(is_equal_approx(art.modulate.a, 0.35), "Static art opacity must survive cleanup")
	check(persistent.is_valid(), "Unrelated tween must survive cleanup")
	check(not button.has_meta("reset_feedback_active"), "Reset feedback state must clear")
	persistent.kill()
	parent.queue_free()
	await process_frame
	print("TWEEN_CLEANUP checked=%d" % tween_keys.size())

func _can_unlock_action(skill_id: String, action: Dictionary) -> bool:
	return host._activity_unlock_runtime()._can_unlock_action(skill_id, action)

func reference_next_unlock() -> String:
	if host.selected_skill_id != "fishing":
		return ""
	var best_action_id := ""
	var best_unlock := 999999
	var best_render_order := 999999
	var render_order := 0
	for raw_area in host.fishing_runtime.area_definitions:
		var area_def := raw_area as Dictionary
		if not host.fishing_runtime.area_uses_location_tiles(area_def, FishingState.FISHING_LOCATION_DEFS):
			continue
		var area_id := str(area_def.get("id", ""))
		for raw_location in host.fishing_runtime.locations_for_area(area_id, FishingState.FISHING_LOCATION_DEFS):
			var location := raw_location as Dictionary
			var candidate_render_order := render_order
			render_order += 1
			if host.fishing_runtime.location_is_unlocked(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS):
				continue
			if not host.fishing_runtime.location_should_show(host, area_id, location, FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS):
				continue
			var action_id: String = host.fishing_runtime.location_action_id(area_id, str(location.get("id", "")), FishingState.FISHING_TOOL_LOCATION_ACTIONS)
			if action_id.is_empty():
				continue
			var action: Dictionary = host._action_data("fishing", action_id)
			if action.is_empty() or not _can_unlock_action("fishing", action):
				continue
			var unlock_level := int(action.get("unlock", location.get("unlock", 1)))
			if unlock_level < best_unlock or (unlock_level == best_unlock and candidate_render_order < best_render_order):
				best_unlock = unlock_level
				best_render_order = candidate_render_order
				best_action_id = action_id
	return best_action_id

