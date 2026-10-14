extends RefCounted

const BOOT_WARMUP_MIN_VISIBLE_SECONDS := 0.35

var host
var active := false
var layer: CanvasLayer
var overlay: Control
var background: ColorRect
var splash: Control
var shade: ColorRect
var footer: VBoxContainer
var label: Label
var progress_bar
var show_msec := 0
var hide_requested := false
var boot_early_services_started := false


func _init(host_ref) -> void:
	host = host_ref


func _boot_progress_step(text: String, progress: float):
	_set_progress(text, progress)
	await host.get_tree().process_frame


func _finish_boot_render_async() -> bool:
	if not host.is_inside_tree():
		return false
	if host._save_runtime().boot_storage_failure_blocks_restore():
		_show_save_recovery_state()
		return false
	host.current_screen = "skill"
	host.boot_detail_render_in_progress = true
	host.boot_detail_card_yield = true
	_set_progress("Drawing first skill...", 0.70)
	await host._navigation_shell()._render_screen(true, -1, true)
	host.boot_detail_card_yield = false
	host.boot_detail_render_in_progress = false
	host.boot_lazy_background_mount_allowed = false
	_set_progress("Finishing startup...", 0.74)
	# A loaded save is not playable or writable until every subsystem, including
	# profile/auth identity, has completed the same restore transaction.
	if not host._save_runtime().pending_save_restore_data.is_empty():
		host._save_runtime()._load_game_secondary_restore()
	if host._save_runtime().boot_recovery_blocks_reveal():
		_show_save_recovery_state()
		return false
	# Keep the loading cover opaque until the final desktop hierarchy is mounted.
	await host.desktop_layout.start()
	await host.get_tree().process_frame
	if not host.startup_initialized:
		host.startup_initialized = true
		host._crash_report_runtime().write_session_marker("running")
	host._update_ui(0.0, true)
	_dismiss_boot_splash_for_play()
	if host.app_resume_repair_pending:
		host._app_lifecycle_runtime().call_deferred("_repair_after_app_resume")
	host._activity_unlock_runtime().call_deferred("_run_startup_auto_unlock_lockpads")
	if DisplayServer.get_name() != "headless":
		if not boot_early_services_started:
			boot_early_services_started = true
			host._audio_director().call_deferred("_prepare_audio_buses")
			host._navigation_shell().call_deferred("_ensure_nav_bar_icons")
			host._navigation_shell().call_deferred("_sync_hero_nav_button", true)
			host._navigation_shell().call_deferred("_sync_hub_nav_button", true)
			host._navigation_shell().call_deferred("_sync_shop_nav_button", true)
			host._profile_chat_overlay_surface().call_deferred("_ensure_chat_strip")
		host._achievement_toast_surface().call_deferred("show_pending_completed_toasts")
		host._save_runtime().call_deferred("_schedule_boot_post_load_simulation")
		call_deferred("begin_background_boot_validation")
		host._ad_bonus_runtime().call_deferred("_init_ads")
	return true


func _show_save_recovery_state() -> void:
	active = true
	hide_requested = false
	if overlay != null and is_instance_valid(overlay):
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	if footer != null and is_instance_valid(footer):
		footer.offset_top = -550
		footer.offset_bottom = -50
		footer.add_theme_constant_override("separation", 0)
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(footer, true)
	if label != null and is_instance_valid(label):
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(800, 380)
		label.add_theme_font_size_override("font_size", 60)
	if progress_bar != null and is_instance_valid(progress_bar):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(progress_bar, false)
	if splash != null and is_instance_valid(splash) and splash.has_method("stop"):
		splash.call("stop")
	_set_progress(host._save_runtime().boot_recovery_status_text(), 1.0)
	_add_save_recovery_actions()


func _add_save_recovery_actions() -> void:
	if footer == null or not is_instance_valid(footer) or not host._save_runtime().boot_recovery_can_start_fresh():
		return
	footer.mouse_filter = Control.MOUSE_FILTER_STOP
	footer.offset_top = -800
	footer.add_theme_constant_override("separation", 24)
	var copy_button: Button = host._menu_button("Copy Save Data")
	copy_button.custom_minimum_size = Vector2(620, 110)
	copy_button.pressed.connect(func():
		DisplayServer.clipboard_set(host._save_runtime().support_save_export_text())
		copy_button.text = "Copied for Support"
	)
	footer.add_child(copy_button)
	var fresh_button: Button = host._menu_button("Start New Game")
	fresh_button.custom_minimum_size = Vector2(620, 110)
	fresh_button.pressed.connect(_on_save_recovery_start_fresh_pressed.bind(fresh_button))
	footer.add_child(fresh_button)


func _on_save_recovery_start_fresh_pressed(button: Button) -> void:
	# The first tap only arms the reset; old files are archived, never deleted.
	if not bool(button.get_meta("confirm_armed", false)):
		button.set_meta("confirm_armed", true)
		button.text = "Tap Again: Old Save Is Archived"
		return
	button.disabled = true
	if not host._save_runtime().archive_local_saves_for_fresh_start():
		button.text = "Could Not Archive Save"
		return
	host.get_tree().reload_current_scene()


func validate_state(priority_skill_ids: Array = []) -> void:
	var validate_all := priority_skill_ids.is_empty()
	SkillState.invalidate_stat_caches(host)
	host.fishing_runtime.equipped_tool_id = "hands"
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		if not host.skills.has(skill_id):
			host.skills[skill_id] = {"xp": 0, "level": 1}
		if not host.stamina.has(skill_id):
			host.stamina[skill_id] = float(SkillState.max_stamina(host, skill_id))
		if not host.stamina_bank.has(skill_id):
			host.stamina_bank[skill_id] = 0.0
		_validate_skill_actions(skill_id, validate_all or priority_skill_ids.has(skill_id))
		SkillState.recalculate_level(host, skill_id)
	if not host.skills.has(host.selected_skill_id):
		host.selected_skill_id = "fight"
	host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	host.thieving_state.ensure_all_trophy_state()
	host._hub_runtime().sync_trophy_level_from_thieving()
	host._hub_surface()._validate_hub_module_positions()
	host._hub_runtime().sync_missions()
	SkillState.invalidate_stat_caches(host)


func validate_state_bootstrap() -> void:
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		if not host.skills.has(skill_id):
			host.skills[skill_id] = {"xp": 0, "level": 1}
	SkillState.invalidate_max_stamina_cache()
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		if not host.stamina.has(skill_id):
			host.stamina[skill_id] = float(SkillState.max_stamina(host, skill_id))
		if not host.stamina_bank.has(skill_id):
			host.stamina_bank[skill_id] = 0.0
	if not host.skills.has(host.selected_skill_id):
		host.selected_skill_id = "fight"


func prepare_selected_skill_for_render(boot_fast := false) -> void:
	validate_state_bootstrap()
	if boot_fast:
		var prepared_action_ids := {}
		for entry in host._skill_detail_surface()._visible_detail_entries_for_skill(host.selected_skill_id):
			var entry_data := entry as Dictionary
			if str(entry_data.get("kind", "")) == "thieving_heist":
				continue
			var action := entry_data.get("action", {}) as Dictionary
			if action.is_empty():
				continue
			var action_id := str(action.get("id", ""))
			if action_id.is_empty() or prepared_action_ids.has(action_id):
				continue
			prepared_action_ids[action_id] = true
			var key: String = host._action_key(host.selected_skill_id, action_id)
			if not host.mastery.has(key):
				host.mastery[key] = {"xp": 0, "level": 0}
			MasteryState.recalculate_host(host, key)
		_ensure_skill_mastery_keys(host.selected_skill_id)
		SkillState.recalculate_level(host, host.selected_skill_id, false)
		return
	for action in host.actions_by_skill.get(host.selected_skill_id, []):
		var action_data := action as Dictionary
		if host._convergence_runtime()._is_convergence_action(action_data):
			host._convergence_runtime()._ensure_convergence_state(str(action_data.get("id", "")))
			continue
		if host._passive_modules_runtime().is_passive_action(action_data):
			host._passive_modules_runtime().ensure_passive_module_state(str(action_data.get("id", "")), host._unix_now())
			continue
		var key: String = host._action_key(host.selected_skill_id, str(action_data.get("id", "")))
		if not host.mastery.has(key):
			host.mastery[key] = {"xp": 0, "level": 0}
		MasteryState.recalculate_host(host, key)
	SkillState.recalculate_level(host, host.selected_skill_id, false)


func begin_background_boot_validation() -> void:
	if not host.is_inside_tree():
		return
	if host.deferred_selected_skill_mastery_pending:
		host.deferred_selected_skill_mastery_pending = false
		prepare_selected_skill_for_render(false)
	if not host.deferred_skill_validation_pending:
		return
	if not host._save_runtime().pending_save_restore_data.is_empty():
		host._save_runtime()._load_game_secondary_restore()
	await host.get_tree().process_frame
	_validate_remaining_skills_deferred()


func _ensure_skill_mastery_keys(skill_id: String) -> void:
	for action in host.actions_by_skill.get(skill_id, []):
		if host._convergence_runtime()._is_convergence_action(action as Dictionary) or host._passive_modules_runtime().is_passive_action(action as Dictionary):
			continue
		var key: String = host._action_key(skill_id, str(action["id"]))
		if not host.mastery.has(key):
			host.mastery[key] = {"xp": 0, "level": 0}


func _validate_skill_actions(skill_id: String, recalculate_mastery: bool) -> void:
	for action in host.actions_by_skill.get(skill_id, []):
		if host._convergence_runtime()._is_convergence_action(action as Dictionary):
			host._convergence_runtime()._ensure_convergence_state(str(action.get("id", "")))
			continue
		if host._passive_modules_runtime().is_passive_action(action as Dictionary):
			host._passive_modules_runtime().ensure_passive_module_state(str(action.get("id", "")), host._unix_now())
			continue
		var key: String = host._action_key(skill_id, str(action["id"]))
		if not host.mastery.has(key):
			host.mastery[key] = {"xp": 0, "level": 0}
		if recalculate_mastery:
			MasteryState.recalculate_host(host, key)


func _validate_remaining_skills_deferred() -> void:
	if not host.deferred_skill_validation_pending or not host.is_inside_tree():
		return
	for def in host.skill_defs:
		if not host.deferred_skill_validation_pending or not host.is_inside_tree():
			return
		var skill_id := str(def.get("id", ""))
		if skill_id.is_empty() or skill_id == host.selected_skill_id:
			continue
		_validate_skill_actions(skill_id, true)
		SkillState.recalculate_level(host, skill_id)
		await host.get_tree().process_frame
	if not host.deferred_skill_validation_pending or not host.is_inside_tree():
		return
	host.deferred_skill_validation_pending = false
	SkillState.invalidate_stat_caches(host)
	if host.current_screen == "skill" or host.current_screen == "home":
		host._update_ui(0.0)


func build_overlay() -> void:
	layer = CanvasLayer.new()
	layer.layer = host.BOOT_WARMUP_LAYER
	host.add_child(layer)

	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	layer.add_child(overlay)

	background = ColorRect.new()
	background.color = host._theme_paper_color()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(background)

	splash = preload("res://scripts/ui/progression_loading_screen.gd").new()
	splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(splash)

	shade = ColorRect.new()
	shade.color = Color(0.10, 0.08, 0.04, 0.04)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)

	footer = VBoxContainer.new()
	footer.anchor_left = 0.5
	footer.anchor_right = 0.5
	footer.anchor_top = 1.0
	footer.anchor_bottom = 1.0
	footer.offset_left = -310
	footer.offset_right = 310
	footer.offset_top = -215
	footer.offset_bottom = -105
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 17)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.visible = false
	overlay.add_child(footer)

	label = host._label("Warming up...", 58, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 9)
	footer.add_child(label)

	progress_bar = ThemeStyles.progress_bar(host.COLOR_GREEN, 34, 0.0)
	progress_bar.custom_minimum_size = Vector2(590, 17)
	progress_bar.border_color = host.COLOR_INK
	footer.add_child(progress_bar)


func show_overlay() -> void:
	active = true
	hide_requested = false
	show_msec = Time.get_ticks_msec()
	if overlay == null:
		return
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(overlay, true)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(overlay, 1.0)
	if splash != null and is_instance_valid(splash) and splash.has_method("restart"):
		splash.call("restart")
	_set_progress("Warming up...", 0.0)


func hide_overlay() -> void:
	if overlay == null or not is_instance_valid(overlay) or overlay.is_queued_for_deletion():
		active = false
		return
	if hide_requested:
		return
	hide_requested = true
	if BOOT_WARMUP_MIN_VISIBLE_SECONDS > 0.0 and show_msec > 0:
		var visible_elapsed := float(Time.get_ticks_msec() - show_msec) / 1000.0
		var remaining := BOOT_WARMUP_MIN_VISIBLE_SECONDS - visible_elapsed
		if remaining > 0.0:
			await host.get_tree().create_timer(remaining).timeout
			if overlay == null or not is_instance_valid(overlay) or overlay.is_queued_for_deletion():
				active = false
				return
	active = false
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._clear_page_transient_input_state()
	var tween: Tween = host.create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_overlay_hide)


func _finish_overlay_hide() -> void:
	if overlay != null and is_instance_valid(overlay):
		if splash != null and is_instance_valid(splash) and splash.has_method("stop"):
			splash.call("stop")
	if layer != null and is_instance_valid(layer):
		layer.queue_free()
	layer = null
	overlay = null
	background = null
	splash = null
	shade = null
	footer = null
	label = null
	progress_bar = null


func _add_boot_warmup_texture_path(paths: Array, path: String) -> void:
	if not path.is_empty() and not paths.has(path):
		paths.append(path)


func _set_progress(text: String, progress: float) -> void:
	if is_instance_valid(splash): splash.set_progress(progress)
	if label != null:
		label.text = text
	if progress_bar != null:
		progress_bar.set_value(clampf(progress, 0.0, 1.0) * 100.0)


func _dismiss_boot_splash_for_play() -> void:
	active = false
	if overlay == null or not is_instance_valid(overlay):
		return
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if footer != null and is_instance_valid(footer):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(footer, false)
	hide_overlay()


func reset_for_shutdown() -> void:
	active = false
	show_msec = 0
	hide_requested = false
	layer = null
	overlay = null
	background = null
	splash = null
	shade = null
	footer = null
	label = null
	progress_bar = null


func apply_theme_background() -> void:
	if background != null and is_instance_valid(background):
		background.color = host._theme_paper_color()
