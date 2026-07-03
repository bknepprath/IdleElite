extends RefCounted

const AchievementRewards = preload("res://scripts/achievements/rewards.gd")
const BootFlexLoadingAnimationClass = preload("res://scripts/ui/boot_flex_loading_animation.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")

const BOOT_WARMUP_FRAME_BUDGET_MSEC := 32
const BOOT_WARMUP_MIN_VISIBLE_SECONDS := 1.65

var host
var boot_early_services_started := false


func _init(host_ref) -> void:
	host = host_ref


func _boot_progress_step(text: String, progress: float):
	_set_boot_warmup_progress(text, progress)
	await host.get_tree().process_frame


func _finish_boot_render_async():
	if not host.is_inside_tree():
		return
	host.current_screen = "skill"
	host.boot_detail_render_in_progress = true
	host.boot_detail_card_yield = true
	_set_boot_warmup_progress("Drawing first skill...", 0.70)
	await host._render_screen(true, -1, true)
	host.boot_detail_card_yield = false
	host.boot_detail_render_in_progress = false
	host.boot_lazy_background_mount_allowed = false
	_set_boot_warmup_progress("Finishing startup...", 0.74)
	if not host.startup_initialized:
		host.startup_initialized = true
		host._crash_report_runtime().write_session_marker("running")
	host._update_ui(0.0, true)
	_dismiss_boot_splash_for_play()
	if host.app_resume_repair_pending:
		host._app_lifecycle_runtime().call_deferred("_repair_after_app_resume")
	host.call_deferred("_run_startup_auto_unlock_lockpads")
	if DisplayServer.get_name() != "headless":
		if not boot_early_services_started:
			host._audio_director().call_deferred("_prepare_audio_buses")
			host._navigation_shell().call_deferred("_ensure_nav_bar_icons")
			host._navigation_shell().call_deferred("_sync_hero_nav_button", true)
			host._navigation_shell().call_deferred("_sync_hub_nav_button", true)
			host._navigation_shell().call_deferred("_sync_shop_nav_button", true)
			host._profile_chat_overlay_surface().call_deferred("_ensure_chat_strip")
		host._achievement_toast_surface().call_deferred("show_pending_completed_toasts")
		host._save_runtime().call_deferred("_schedule_boot_post_load_simulation")
		host.call_deferred("_begin_background_boot_validation")
		call_deferred("_boot_texture_warmup_background")


func _build_boot_warmup_overlay() -> void:
	host.boot_warmup_layer = CanvasLayer.new()
	host.boot_warmup_layer.layer = host.BOOT_WARMUP_LAYER
	host.add_child(host.boot_warmup_layer)

	host.boot_warmup_overlay = Control.new()
	host.boot_warmup_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.boot_warmup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.boot_warmup_overlay.visible = false
	host.boot_warmup_layer.add_child(host.boot_warmup_overlay)

	host.boot_warmup_background = ColorRect.new()
	host.boot_warmup_background.color = host._theme_paper_color()
	host.boot_warmup_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.boot_warmup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.boot_warmup_overlay.add_child(host.boot_warmup_background)

	host.boot_warmup_splash = BootFlexLoadingAnimationClass.new()
	host.boot_warmup_splash.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.boot_warmup_splash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.boot_warmup_overlay.add_child(host.boot_warmup_splash)

	host.boot_warmup_shade = ColorRect.new()
	host.boot_warmup_shade.color = Color(0.10, 0.08, 0.04, 0.04)
	host.boot_warmup_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.boot_warmup_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.boot_warmup_overlay.add_child(host.boot_warmup_shade)

	host.boot_warmup_footer = VBoxContainer.new()
	host.boot_warmup_footer.anchor_left = 0.5
	host.boot_warmup_footer.anchor_right = 0.5
	host.boot_warmup_footer.anchor_top = 1.0
	host.boot_warmup_footer.anchor_bottom = 1.0
	host.boot_warmup_footer.offset_left = -620
	host.boot_warmup_footer.offset_right = 620
	host.boot_warmup_footer.offset_top = -430
	host.boot_warmup_footer.offset_bottom = -210
	host.boot_warmup_footer.alignment = BoxContainer.ALIGNMENT_CENTER
	host.boot_warmup_footer.add_theme_constant_override("separation", 34)
	host.boot_warmup_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.boot_warmup_footer.visible = false
	host.boot_warmup_overlay.add_child(host.boot_warmup_footer)

	host.boot_warmup_label = host._label("Warming up...", 58, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	host.boot_warmup_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	host.boot_warmup_label.add_theme_constant_override("outline_size", 18)
	host.boot_warmup_footer.add_child(host.boot_warmup_label)

	host.boot_warmup_progress = host._progress(host.COLOR_GREEN, 34, 0.0)
	host.boot_warmup_progress.custom_minimum_size = Vector2(1180, 34)
	host.boot_warmup_progress.border_color = host.COLOR_INK
	host.boot_warmup_footer.add_child(host.boot_warmup_progress)


func _show_boot_warmup_overlay() -> void:
	host.boot_warmup_active = true
	host.boot_warmup_game_revealed = false
	host.boot_warmup_hide_requested = false
	host.boot_warmup_show_msec = Time.get_ticks_msec()
	if host.boot_warmup_overlay == null:
		return
	host._set_canvas_item_visible_if_changed(host.boot_warmup_overlay, true)
	host.boot_warmup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host._set_canvas_item_alpha_if_changed(host.boot_warmup_overlay, 1.0)
	if host.boot_warmup_splash != null and is_instance_valid(host.boot_warmup_splash) and host.boot_warmup_splash.has_method("restart"):
		host.boot_warmup_splash.call("restart")
	_set_boot_warmup_progress("Warming up...", 0.0)


func _hide_boot_warmup_overlay() -> void:
	if host.boot_warmup_overlay == null or not is_instance_valid(host.boot_warmup_overlay) or host.boot_warmup_overlay.is_queued_for_deletion():
		host.boot_warmup_active = false
		return
	if host.boot_warmup_hide_requested:
		return
	host.boot_warmup_hide_requested = true
	if BOOT_WARMUP_MIN_VISIBLE_SECONDS > 0.0 and host.boot_warmup_show_msec > 0:
		var visible_elapsed := float(Time.get_ticks_msec() - host.boot_warmup_show_msec) / 1000.0
		var remaining := BOOT_WARMUP_MIN_VISIBLE_SECONDS - visible_elapsed
		if remaining > 0.0:
			await host.get_tree().create_timer(remaining).timeout
			if host.boot_warmup_overlay == null or not is_instance_valid(host.boot_warmup_overlay) or host.boot_warmup_overlay.is_queued_for_deletion():
				host.boot_warmup_active = false
				return
	host.boot_warmup_active = false
	host.boot_warmup_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._clear_page_transient_input_state()
	var tween: Tween = host.create_tween()
	tween.tween_property(host.boot_warmup_overlay, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_boot_warmup_overlay_hide)


func _finish_boot_warmup_overlay_hide() -> void:
	if host.boot_warmup_overlay != null and is_instance_valid(host.boot_warmup_overlay):
		if host.boot_warmup_splash != null and is_instance_valid(host.boot_warmup_splash) and host.boot_warmup_splash.has_method("stop"):
			host.boot_warmup_splash.call("stop")
		host._set_canvas_item_visible_if_changed(host.boot_warmup_overlay, false)
		host._set_canvas_item_alpha_if_changed(host.boot_warmup_overlay, 1.0)


func _set_boot_warmup_progress(text: String, progress: float) -> void:
	if host.boot_warmup_label != null:
		host.boot_warmup_label.text = text
	if host.boot_warmup_progress != null:
		host.boot_warmup_progress.set_value(clampf(progress, 0.0, 1.0) * 100.0)


func _reveal_game_under_boot_splash() -> void:
	if host.boot_warmup_game_revealed or host.boot_warmup_overlay == null or not is_instance_valid(host.boot_warmup_overlay):
		return
	host.boot_warmup_game_revealed = true


func _dismiss_boot_splash_for_play() -> void:
	host.boot_warmup_active = false
	if host.boot_warmup_overlay == null or not is_instance_valid(host.boot_warmup_overlay):
		return
	host.boot_warmup_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if host.boot_warmup_footer != null and is_instance_valid(host.boot_warmup_footer):
		host._set_canvas_item_visible_if_changed(host.boot_warmup_footer, false)
	_hide_boot_warmup_overlay()


func _boot_shared_texture_paths() -> Array:
	var paths := []
	_add_boot_warmup_texture_path(paths, "res://assets/loading/blue-guy-flex-loading-spritesheet.png")
	_add_boot_warmup_texture_path(paths, "res://assets/loading/blue-guy-flex-speech-bubble-blank.png")
	_add_boot_warmup_texture_path(paths, "res://assets/content/logo/idle-elite-logo-cutout.png")
	_add_boot_warmup_texture_path(paths, "res://assets/content/characters/stick-hero.png")
	_add_boot_warmup_texture_path(paths, host.HERO_SPEECH_BUBBLE_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.TOTAL_LEVEL_BARGRAPH_TEXTURE)
	_add_boot_warmup_texture_path(paths, "res://assets/content/icons/gear.png")
	_add_boot_warmup_texture_path(paths, host.REWARDED_AD_ICON_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.DISCORD_LOGO_ICON_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.MASTERY_MEDALS_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.UNLOCK_LOCK_CHAINS_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.UNLOCK_CHAIN_LINK_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.UNLOCK_CHAIN_LEFT_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.UNLOCK_CHAIN_RIGHT_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.UNLOCK_PADLOCK_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.ACTIVITY_JUMP_TOP_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.ACTIVITY_JUMP_BOTTOM_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.ACTIVITY_BACK_TEXTURE)
	for raw_nav_path in [
		host.PROGRESS_STAR_ICON_TEXTURE,
		"res://assets/content/hub/hub-nav-barn.png",
		host.NAV_OPEN_CLOSE_ICON_TEXTURE,
		host.SETTINGS_GEAR_ICON_TEXTURE,
		host.SHOP_ICON_TEXTURE,
		host.MODULE_PIN_ICON_TEXTURE,
		NavigationShell.MODULE_QUEUE_ICON_TEXTURE,
		"res://assets/content/ui/navigation-controls/skills-overview.png",
		"res://assets/content/ui/navigation-controls/sort-list.png"
	]:
		_add_boot_warmup_texture_path(paths, raw_nav_path)
	return paths


func _boot_warmup_texture_paths() -> Array:
	var paths := _boot_shared_texture_paths()
	_add_boot_warmup_texture_path(paths, AchievementRewards.TOTAL_LEVEL_ART)
	_add_boot_warmup_texture_path(paths, AchievementRewards.CRIT_ART)
	_add_boot_warmup_texture_path(paths, AchievementRewards.CREDIT_ART)
	_add_boot_warmup_texture_path(paths, AchievementRewards.CUMULATIVE_MEDALS_ART)
	_add_boot_warmup_texture_path(paths, host.LOG_CURRENCY_ICON_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.PLANK_ICON_TEXTURE)
	_add_boot_warmup_texture_path(paths, host.UPGRADE_ARROW_ICON_TEXTURE)
	var warmup_skill_ids := _boot_warmup_skill_ids()
	if warmup_skill_ids.has("fishing"):
		_add_boot_warmup_texture_path(paths, host.FISH_CURRENCY_ICON_TEXTURE)
		host._fishing_ui_surface()._add_fishing_boot_warmup_texture_paths(paths)
	for skill_id in warmup_skill_ids:
		_add_boot_warmup_texture_path(paths, host._skill_icon_path(skill_id))
		if skill_id == "thieving":
			_add_boot_warmup_texture_path(paths, host.THIEVING_HEIST_BACKGROUND_SHEET)
			_add_boot_warmup_texture_path(paths, host.THIEVING_HEIST_TROPHY_SHEET)
			_add_boot_warmup_texture_path(paths, host.THIEVING_HEIST_JAIL_BARS_TEXTURE)
		for action in host._visible_actions_for_skill(skill_id):
			var action_data := action as Dictionary
			_add_boot_warmup_texture_path(paths, str(action_data.get("art", "")))
			_add_boot_warmup_texture_path(paths, str(action_data.get("bg", "")))
			if skill_id == "fishing":
				var action_id := str(action_data.get("id", ""))
				if FishingState.FISHING_ACTION_CATCH_TEXTURE_PATHS.has(action_id):
					_add_boot_warmup_texture_path(paths, FishingState.FISHING_ACTION_CATCH_TEXTURE_PATHS[action_id])
	return paths


func _uncached_boot_warmup_texture_paths() -> Array:
	return host.visual_texture_cache._uncached_texture_paths(_boot_warmup_texture_paths())


func _boot_warmup_skill_ids() -> Array:
	var ids := []
	var current_index: int = host._skill_index(host.selected_skill_id)
	if current_index < 0 or host.skill_defs.is_empty():
		return ids
	var skill_id := str(host.skill_defs[current_index].get("id", ""))
	if not skill_id.is_empty():
		ids.append(skill_id)
	return ids


func _add_boot_warmup_texture_path(paths: Array, path: String) -> void:
	if path.is_empty() or paths.has(path):
		return
	paths.append(path)


func _boot_texture_warmup_background() -> void:
	if not host.is_inside_tree():
		return
	var paths: Array = _uncached_boot_warmup_texture_paths()
	if paths.is_empty():
		host._audio_director().call_deferred("_warm_extended_audio_async")
		host._ad_bonus_runtime().call_deferred("_init_ads")
		return
	var last_yield_msec := Time.get_ticks_msec()
	for raw_path in paths:
		if not host.is_inside_tree():
			return
		host.visual_texture_cache._texture(str(raw_path))
		if Time.get_ticks_msec() - last_yield_msec >= BOOT_WARMUP_FRAME_BUDGET_MSEC:
			await host.get_tree().process_frame
			last_yield_msec = Time.get_ticks_msec()
	host._audio_director().call_deferred("_warm_extended_audio_async")
	host._ad_bonus_runtime().call_deferred("_init_ads")
