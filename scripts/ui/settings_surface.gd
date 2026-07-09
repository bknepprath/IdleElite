extends RefCounted

const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const RESET_DATA_CONFIRM_SECONDS := 8.0
const RESET_DATA_CONFIRM_MIN_SECONDS := 0.08
const RESET_DATA_CONFIRM_TEXT := "Are you sure?"
const DISCORD_INVITE_URL := "https://discord.com/invite/NHvsGdGfVW"
const MAX_CRASH_REPORT_CLIPBOARD_CHARS := 1800
const DISCORD_LOGO_ICON_TEXTURE := "res://assets/content/ui/discord-logo-icon.png"

var host
var reset_data_confirm_until := 0.0
var reset_data_confirm_armed_at := 0.0
var reset_data_confirm_button: Button
var reset_data_buttons := []
var music_volume_sliders := []
var music_volume_labels := []
var music_mute_toggles := []
var music_mute_labels := []
var sfx_volume_sliders := []
var sfx_volume_labels := []
var sfx_mute_toggles := []
var sfx_mute_labels := []
var offline_progress_toggles := []
var auto_unlock_lockpad_toggles := []
var stamina_decimal_toggles := []
var offline_progress_cap_notification_toggles := []
var dark_mode_toggles := []
var god_mode_controls := []
var settings_return_screen := "skill"
var settings_return_skill_id := ""
var settings_return_detail_scroll := -1
var audio_controls_sync_key := ""
var audio_slider_grabber_texture: Texture2D
var audio_slider_grabber_highlight_texture: Texture2D
var active_audio_slider: HSlider
var active_audio_slider_is_music := false
var active_audio_slider_touch_index := -1
var notification_permission_notice: Control
var notification_permission_notice_tween: Tween

func _init(host_ref) -> void:
	host = host_ref


func _show_settings() -> void:
	if not host._navigation_shell()._top_level_nav_allowed("settings"):
		return
	_remember_settings_return_context()
	_disarm_reset_data_confirmation()
	host._skill_swipe_activity_surface()._clear_queued_skill_swipe_navigation()
	host._skill_swipe_activity_surface()._kill_skill_swipe_tween()
	host._skill_swipe_activity_surface()._cancel_skill_swipe_finalize_for_navigation()
	host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
	host.current_screen = "settings"
	host._navigation_shell()._render_screen()


func _remember_settings_return_context() -> void:
	if host.current_screen == "settings":
		return
	settings_return_screen = host.current_screen
	settings_return_skill_id = host.selected_skill_id if SkillState.has_skill_id(host.skill_defs, host.selected_skill_id) else ""
	settings_return_detail_scroll = -1
	if host.current_screen == "skill" and host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		settings_return_detail_scroll = maxi(0, int(round(host._skill_detail_surface().detail_actions_scroll.scroll_vertical)))


func _return_from_settings_page() -> void:
	_disarm_reset_data_confirmation()
	if host.settings_overlay != null and host.settings_overlay.visible:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(host.settings_overlay, false)
	var target_screen := settings_return_screen
	var target_skill_id := settings_return_skill_id
	var restore_detail_scroll := settings_return_detail_scroll if target_screen == "skill" else -1
	settings_return_detail_scroll = -1
	if target_screen.is_empty() or target_screen == "settings":
		target_screen = "skill"
	if not target_skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, target_skill_id):
		host.selected_skill_id = target_skill_id
	if target_screen == "home":
		host._navigation_shell()._clear_top_level_nav_lock()
		host._navigation_shell()._show_home()
		return
	if not ["skill", "menu", "pinned", "leaderboard", "hub", "shop", "achievements"].has(target_screen):
		target_screen = "skill"
	if target_screen == "skill" and not SkillState.has_skill_id(host.skill_defs, host.selected_skill_id):
		host.selected_skill_id = host._save_runtime()._default_skill_id_for_save()
	host._navigation_shell()._clear_top_level_nav_lock()
	host.current_screen = target_screen
	host._navigation_shell()._render_screen(false, restore_detail_scroll)


func _close_settings() -> void:
	_disarm_reset_data_confirmation()
	var closed_overlay := false
	if host.settings_overlay != null and host.settings_overlay.visible:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(host.settings_overlay, false)
		closed_overlay = true
	if host.current_screen == "settings":
		_return_from_settings_page()
	elif not closed_overlay:
		host._navigation_shell()._show_home()


func _route_onboarding_settings_nav_input(event: InputEvent) -> bool:
	if not (host._onboarding_runtime().tutorial_active or host._onboarding_runtime()._onboarding_path_active()):
		return false
	if host.settings_tab == null or not is_instance_valid(host.settings_tab) or not host.settings_tab.is_visible_in_tree():
		return false
	var is_press := false
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_press = event.pressed
		event_position = event.global_position
	elif event is InputEventScreenTouch:
		is_press = (event as InputEventScreenTouch).pressed
		event_position = event.position
	if not is_press:
		return false
	var settings_rect: Rect2 = host.settings_tab.get_global_rect().grow(24.0)
	var hit_settings: bool = settings_rect.has_point(event_position)
	if not hit_settings:
		return false
	if host.current_screen == "settings":
		host._navigation_shell()._clear_top_level_nav_lock()
		if host._navigation_shell()._bottom_nav_open_close_returns_to_skill("settings", host.settings_tab):
			host._navigation_shell().bottom_nav_open_close_return_to_skill_active = true
			host._navigation_shell()._show_skills_module()
			host._navigation_shell().bottom_nav_open_close_return_to_skill_active = false
			return true
		_return_from_settings_page()
		return true
	_show_settings()
	return true


func _settings_discord_pressed() -> void:
	var err := OS.shell_open(DISCORD_INVITE_URL)
	if err == OK:
		host._reward_feedback_surface()._set_result("Opening Discord invite.")
	else:
		host._reward_feedback_surface()._set_result("Couldn't open Discord invite.")


func _settings_copy_crash_report_pressed() -> void:
	var crash_runtime = host._crash_report_runtime()
	if not crash_runtime.pending_report_exists():
		host._reward_feedback_surface()._set_result("No crash report found.")
		return
	var report: String = crash_runtime.pending_report_clipboard_text()
	if report.is_empty():
		host._reward_feedback_surface()._set_result("Couldn't read crash report.")
		return
	if report.length() > MAX_CRASH_REPORT_CLIPBOARD_CHARS:
		report = report.substr(0, MAX_CRASH_REPORT_CLIPBOARD_CHARS) + "\n\n[Crash report truncated for clipboard.]"
	DisplayServer.clipboard_set(report)
	crash_runtime.clear_pending_report()
	var err := OS.shell_open(DISCORD_INVITE_URL)
	if err == OK:
		host._reward_feedback_surface()._set_result("Crash report copied. Paste it to the dev. Local report cleared.")
	else:
		host._reward_feedback_surface()._set_result("Crash report copied. Local report cleared.")
	if host.current_screen == "settings":
		host._navigation_shell()._render_screen()


func _apply_god_mode_toggle_style(button: Button) -> void:
	var fill: Color = Color("#48dd6c") if host._test_state_runtime()._god_mode_active() else host.COLOR_BLUE
	var pressed_fill: Color = fill.darkened(0.10)
	button.add_theme_stylebox_override("normal", host._paper_button_style(fill, 44))
	button.add_theme_stylebox_override("hover", host._paper_button_style(fill, 44))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(pressed_fill, 44, 64, true))
	button.add_theme_stylebox_override("hover_pressed", host._paper_button_style(pressed_fill, 44, 64, true))


func _refresh_god_mode_controls() -> void:
	var live := []
	for raw_control in god_mode_controls:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control):
			continue
		var kind := str(control.get_meta("god_mode_kind", ""))
		if kind == "toggle" and control is Button:
			var button := control as Button
			host._app_lifecycle_runtime().set_button_text_if_changed(button, host._test_state_runtime()._god_mode_toggle_text())
			_apply_god_mode_toggle_style(button)
		elif kind == "performance" and control is Button:
			host._app_lifecycle_runtime().set_button_text_if_changed(control as Button, host._performance_runtime()._performance_overlay_toggle_text())
		elif kind == "status" and control is Label:
			host._app_lifecycle_runtime().set_label_text_if_changed(control as Label, host._test_state_runtime()._god_mode_status_text())
		live.append(control)
	god_mode_controls = live


func render_page() -> void:
	host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
	_clear_reset_data_buttons_for_rebuild()
	_clear_settings_page_control_refs()
	host.content_scroll = MobileScrollContainer.new()
	host.content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host._add_centered_skill_column(host.content_scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = host._skill_content_width()
	var settings_page_height = host.skills_page.size.y - host.SKILLS_PAGE_TOP_PAD
	if settings_page_height <= 1.0:
		settings_page_height = host.BASE_CANVAS.y - NavigationShell.BOTTOM_NAV_HEIGHT - host.SKILLS_PAGE_TOP_PAD
	stack.custom_minimum_size.y = settings_page_height
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	host.content_scroll.add_child(stack)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 32)
	stack.add_child(top_spacer)
	stack.add_child(host._label("Settings", 124, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	var audio_top_spacer := Control.new()
	audio_top_spacer.custom_minimum_size = Vector2(0, 8)
	stack.add_child(audio_top_spacer)
	stack.add_child(audio_volume_control("Music", true, 1400))
	stack.add_child(audio_volume_control("SFX", false, 1400))
	stack.add_child(offline_progress_toggle_button(1320, 132))
	stack.add_child(auto_unlock_lockpad_toggle_button(1320, 132))
	stack.add_child(stamina_decimal_toggle_button(1320, 132))
	stack.add_child(offline_progress_cap_notification_toggle_button(1320, 132))
	stack.add_child(dark_mode_toggle_button(1320, 132))
	var fill_spacer := Control.new()
	fill_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill_spacer.custom_minimum_size = Vector2(0, 12)
	stack.add_child(fill_spacer)
	var action_stack := VBoxContainer.new()
	action_stack.custom_minimum_size = Vector2(1320, 424)
	action_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	action_stack.add_theme_constant_override("separation", 28)
	var discord := settings_page_button("Contact the dev", DISCORD_LOGO_ICON_TEXTURE, 1320, 170, 220)
	discord.add_theme_stylebox_override("normal", host._paper_button_style(host.COLOR_BLUE, 54))
	discord.add_theme_stylebox_override("hover", host._paper_button_style(host.COLOR_BLUE, 54))
	discord.add_theme_stylebox_override("pressed", host._paper_button_style(host.COLOR_BLUE.darkened(0.10), 54, 72, true))
	discord.pressed.connect(_settings_discord_pressed)
	if host._crash_report_runtime().pending_report_exists():
		var crash_report := settings_page_button("Copy Crash Report", "", 1320, 128, 132)
		crash_report.tooltip_text = ""
		crash_report.add_theme_stylebox_override("normal", host._paper_button_style(Color("#ffd94d"), 48))
		crash_report.add_theme_stylebox_override("hover", host._paper_button_style(Color("#ffd94d"), 48))
		crash_report.add_theme_stylebox_override("pressed", host._paper_button_style(Color("#f0c23a"), 48, 72, true))
		crash_report.pressed.connect(_settings_copy_crash_report_pressed)
		stack.add_child(crash_report)
	var reset := settings_page_button("Hard Reset", "", 940, 128, 176)
	reset.add_theme_stylebox_override("normal", host._paper_button_style(Color("#ff6b6b"), 48))
	reset.add_theme_stylebox_override("hover", host._paper_button_style(Color("#ff6b6b"), 48))
	reset.add_theme_stylebox_override("pressed", host._paper_button_style(Color("#ef5656"), 48, 72, true))
	_register_reset_button(reset, "Hard Reset")
	action_stack.add_child(reset)
	action_stack.add_child(discord)
	stack.add_child(action_stack)
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 12)
	stack.add_child(bottom_spacer)

func audio_volume_control(title: String, music: bool, min_width := 1120, bottom_padding := 0) -> Control:
	var mute_size := 128
	var control_gap := 32
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(min_width, 252 + bottom_padding)
	stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_theme_constant_override("separation", 10)
	var label_row := HBoxContainer.new()
	label_row.add_theme_constant_override("separation", 18)
	stack.add_child(label_row)
	var label_indent := Control.new()
	label_indent.custom_minimum_size = Vector2(mute_size + control_gap, 1)
	label_row.add_child(label_indent)
	var name_label: Label = host._label(title, 62, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	if host.app_bold_font != null:
		name_label.add_theme_font_override("font", host.app_bold_font)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_row.add_child(name_label)
	var value_label: Label = host._label("", 62, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.custom_minimum_size = Vector2(210, 76)
	label_row.add_child(value_label)
	var control_padding := MarginContainer.new()
	control_padding.add_theme_constant_override("margin_top", 6)
	control_padding.add_theme_constant_override("margin_bottom", 10)
	stack.add_child(control_padding)
	var control_row := HBoxContainer.new()
	control_row.add_theme_constant_override("separation", control_gap)
	control_padding.add_child(control_row)
	var mute_toggle := Button.new()
	mute_toggle.text = ""
	mute_toggle.custom_minimum_size = Vector2(mute_size, mute_size)
	mute_toggle.focus_mode = Control.FOCUS_NONE
	mute_toggle.tooltip_text = ""
	mute_toggle.toggle_mode = true
	mute_toggle.button_pressed = host._audio_director().music_muted if music else host._audio_director().sfx_muted
	mute_toggle.add_theme_stylebox_override("normal", audio_mute_toggle_style(false, false))
	mute_toggle.add_theme_stylebox_override("hover", audio_mute_toggle_style(false, true))
	mute_toggle.add_theme_stylebox_override("pressed", audio_mute_toggle_style(true, false))
	mute_toggle.add_theme_stylebox_override("hover_pressed", audio_mute_toggle_style(true, true))
	mute_toggle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host.button_press_runtime.attach_button_depress_animation(mute_toggle, 0.92)
	control_row.add_child(mute_toggle)
	var mute_mark: Label = host._label("", 78, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	mute_mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	mute_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mute_toggle.add_child(mute_mark)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(maxi(320, min_width - mute_size - control_gap), 128)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.focus_mode = Control.FOCUS_NONE
	slider.value = round((host._audio_director().music_volume if music else host._audio_director().sfx_volume) * 100.0)
	style_audio_slider(slider)
	slider.gui_input.connect(Callable(self, "_on_audio_slider_gui_input").bind(slider, music))
	control_row.add_child(slider)
	if bottom_padding > 0:
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, bottom_padding)
		stack.add_child(spacer)
	if music:
		music_mute_toggles.append(mute_toggle)
		music_mute_labels.append(mute_mark)
		music_volume_sliders.append(slider)
		music_volume_labels.append(value_label)
		mute_toggle.toggled.connect(Callable(self, "_set_music_muted_from_toggle"))
		slider.value_changed.connect(Callable(self, "_set_music_volume_from_slider"))
	else:
		sfx_mute_toggles.append(mute_toggle)
		sfx_mute_labels.append(mute_mark)
		sfx_volume_sliders.append(slider)
		sfx_volume_labels.append(value_label)
		mute_toggle.toggled.connect(Callable(self, "_set_sfx_muted_from_toggle"))
		slider.value_changed.connect(Callable(self, "_set_sfx_volume_from_slider"))
	_refresh_audio_volume_controls()
	return stack

func style_audio_slider(slider: HSlider) -> void:
	var grabber := audio_slider_grabber()
	if grabber != null:
		slider.add_theme_icon_override("grabber", grabber)
		slider.add_theme_icon_override("grabber_disabled", grabber)
	var grabber_highlight := audio_slider_grabber(true)
	if grabber_highlight != null:
		slider.add_theme_icon_override("grabber_highlight", grabber_highlight)
	var track := StyleBoxFlat.new()
	track.bg_color = host.COLOR_INK
	track.corner_radius_top_left = 7
	track.corner_radius_top_right = 7
	track.corner_radius_bottom_left = 7
	track.corner_radius_bottom_right = 7
	track.content_margin_top = 9
	track.content_margin_bottom = 9
	slider.add_theme_stylebox_override("slider", track)

func audio_mute_toggle_style(pressed: bool, _hovered: bool) -> StyleBoxTexture:
	var fill = Color("#e54845") if pressed else host.COLOR_BLUE
	return host._paper_button_style(fill, 18, 0, pressed)


func _set_music_volume_from_slider(value: float) -> void:
	host._audio_director().music_volume = clampf(value / 100.0, 0.0, 1.0)
	host._audio_director()._apply_audio_bus_volumes()
	_refresh_audio_volume_controls()
	host.save_game()


func _set_sfx_volume_from_slider(value: float) -> void:
	host._audio_director().sfx_volume = clampf(value / 100.0, 0.0, 1.0)
	host._audio_director()._apply_audio_bus_volumes()
	_refresh_audio_volume_controls()
	host.save_game()


func _set_music_muted_from_toggle(pressed: bool) -> void:
	host._audio_director().music_muted = pressed
	host._audio_director()._apply_audio_bus_volumes()
	_refresh_audio_volume_controls()
	host.save_game()


func _set_sfx_muted_from_toggle(pressed: bool) -> void:
	host._audio_director().sfx_muted = pressed
	host._audio_director()._apply_audio_bus_volumes()
	_refresh_audio_volume_controls()
	host.save_game()

func offline_progress_toggle_button(min_width := 1120, min_height := 180) -> Control:
	var row := settings_labeled_toggle_row("Offline Progress:", offline_progress_toggle_text(), min_width, min_height)
	var button := row.get_meta("toggle_button") as Button
	apply_offline_progress_toggle_style(button)
	offline_progress_toggles.append(button)
	button.pressed.connect(Callable(self, "_toggle_offline_progress_enabled"))
	return row

func offline_progress_toggle_text() -> String:
	return "ON" if host.offline_progress_enabled else "OFF"

func apply_offline_progress_toggle_style(button: Button) -> void:
	var fill = Color("#48dd6c") if host.offline_progress_enabled else host.COLOR_BLUE
	var pressed_fill = fill.darkened(0.10)
	button.add_theme_stylebox_override("normal", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("hover", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(pressed_fill, 48, 72, true))
	button.add_theme_stylebox_override("hover_pressed", host._paper_button_style(pressed_fill, 48, 72, true))


func _toggle_offline_progress_enabled() -> void:
	host.offline_progress_enabled = not host.offline_progress_enabled
	var now: int = host._unix_now()
	host._save_runtime().last_save_unix_time = now
	if not host.offline_progress_enabled:
		host._passive_modules_runtime().reset_passive_module_timestamps(now)
	_refresh_offline_progress_controls()
	host.save_game()

func auto_unlock_lockpad_toggle_button(min_width := 1120, min_height := 180) -> Control:
	var row := settings_labeled_toggle_row("Auto Unlock Lockpads:", auto_unlock_lockpad_toggle_text(), min_width, min_height)
	var button := row.get_meta("toggle_button") as Button
	apply_auto_unlock_lockpad_toggle_style(button)
	auto_unlock_lockpad_toggles.append(button)
	button.pressed.connect(Callable(self, "toggle_auto_unlock_lockpads_enabled"))
	return row

func auto_unlock_lockpad_toggle_text() -> String:
	return "ON" if host.auto_unlock_lockpads_enabled else "OFF"

func apply_auto_unlock_lockpad_toggle_style(button: Button) -> void:
	var fill = Color("#48dd6c") if host.auto_unlock_lockpads_enabled else host.COLOR_BLUE
	var pressed_fill = fill.darkened(0.10)
	button.add_theme_stylebox_override("normal", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("hover", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(pressed_fill, 48, 72, true))
	button.add_theme_stylebox_override("hover_pressed", host._paper_button_style(pressed_fill, 48, 72, true))

func toggle_auto_unlock_lockpads_enabled() -> void:
	host.auto_unlock_lockpads_enabled = not host.auto_unlock_lockpads_enabled
	_refresh_auto_unlock_lockpad_controls()
	if host.auto_unlock_lockpads_enabled and not host._onboarding_runtime()._onboarding_path_active():
		host._activity_unlock_runtime()._auto_unlock_retroactive_lockpads()
		host._activity_unlock_runtime()._auto_unlock_pending_lockpads()
	host.save_game()

func stamina_decimal_toggle_button(min_width := 1120, min_height := 180) -> Control:
	var row := settings_labeled_toggle_row("Show Stamina Decimal:", stamina_decimal_toggle_text(), min_width, min_height)
	var button := row.get_meta("toggle_button") as Button
	apply_stamina_decimal_toggle_style(button)
	stamina_decimal_toggles.append(button)
	button.pressed.connect(Callable(self, "_toggle_stamina_decimal_enabled"))
	return row

func stamina_decimal_toggle_text() -> String:
	return "ON" if host.show_stamina_decimal else "OFF"

func apply_stamina_decimal_toggle_style(button: Button) -> void:
	var fill = Color("#48dd6c") if host.show_stamina_decimal else host.COLOR_BLUE
	var pressed_fill = fill.darkened(0.10)
	button.add_theme_stylebox_override("normal", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("hover", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(pressed_fill, 48, 72, true))
	button.add_theme_stylebox_override("hover_pressed", host._paper_button_style(pressed_fill, 48, 72, true))

func _toggle_stamina_decimal_enabled() -> void:
	host.show_stamina_decimal = not host.show_stamina_decimal
	_refresh_stamina_decimal_controls()
	_sync_stamina_decimal_gauge_preference()
	host.save_game()


func offline_progress_cap_notification_toggle_button(min_width := 1120, min_height := 180) -> Control:
	var row := settings_labeled_toggle_row("Offline Cap Notification:", offline_progress_cap_notification_toggle_text(), min_width, min_height)
	var button := row.get_meta("toggle_button") as Button
	apply_offline_progress_cap_notification_toggle_style(button)
	offline_progress_cap_notification_toggles.append(button)
	button.pressed.connect(Callable(self, "_toggle_offline_progress_cap_notifications_enabled"))
	return row

func offline_progress_cap_notification_toggle_text() -> String:
	return "ON" if host.offline_progress_cap_notifications_enabled else "OFF"

func apply_offline_progress_cap_notification_toggle_style(button: Button) -> void:
	var fill = Color("#48dd6c") if host.offline_progress_cap_notifications_enabled else host.COLOR_BLUE
	var pressed_fill = fill.darkened(0.10)
	button.add_theme_stylebox_override("normal", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("hover", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(pressed_fill, 48, 72, true))
	button.add_theme_stylebox_override("hover_pressed", host._paper_button_style(pressed_fill, 48, 72, true))

func _toggle_offline_progress_cap_notifications_enabled() -> void:
	host.offline_progress_cap_notifications_enabled = not host.offline_progress_cap_notifications_enabled
	if host.offline_progress_cap_notifications_enabled:
		request_notification_permission_if_available()
		_show_notification_settings_notice()
	_refresh_offline_progress_cap_notification_controls()
	host.save_game()


func request_notification_permission_if_available() -> void:
	if not OS.has_feature("android"):
		return
	if OS.has_method("request_permissions"):
		OS.request_permissions()


func dark_mode_toggle_button(min_width := 1120, min_height := 180) -> Control:
	var row := settings_labeled_toggle_row("Dark Mode:", dark_mode_toggle_text(), min_width, min_height)
	var button := row.get_meta("toggle_button") as Button
	apply_dark_mode_toggle_style(button)
	dark_mode_toggles.append(button)
	button.pressed.connect(Callable(self, "toggle_dark_mode_enabled"))
	return row

func dark_mode_toggle_text() -> String:
	return "ON" if host.dark_mode_enabled else "OFF"

func apply_dark_mode_toggle_style(button: Button) -> void:
	var fill = Color("#48dd6c") if host.dark_mode_enabled else host.COLOR_BLUE
	var pressed_fill = fill.darkened(0.10)
	button.add_theme_stylebox_override("normal", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("hover", host._paper_button_style(fill, 48))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(pressed_fill, 48, 72, true))
	button.add_theme_stylebox_override("hover_pressed", host._paper_button_style(pressed_fill, 48, 72, true))

func toggle_dark_mode_enabled() -> void:
	host.dark_mode_enabled = not host.dark_mode_enabled
	apply_dark_mode_visual()
	_refresh_dark_mode_controls()
	rebuild_visible_ui_after_dark_mode_changed()
	host.save_game()


func apply_dark_mode_visual() -> void:
	if host.app_background_rect != null and is_instance_valid(host.app_background_rect):
		host.app_background_rect.color = host._theme_paper_color()
	host._boot_warmup_runtime().apply_theme_background()
	_sync_stamina_gauge_dark_mode()
	host._skill_detail_surface()._sync_info_symbol_button_text_colors()


func rebuild_visible_ui_after_dark_mode_changed() -> void:
	host.paper_button_style_textures.clear()
	ActivityCardStyles.clear_cache()
	host._skill_swipe_activity_surface()._clear_light_preview_style_cache()
	host.summary_style_cache = null
	if not host.startup_initialized:
		return
	if host.current_screen == "home":
		if host.home_page != null and is_instance_valid(host.home_page):
			host._clear(host.home_page)
		host._achievement_overlay_surface().invalidate_home_page()
		host._navigation_shell()._finish_show_home()
	else:
		host._navigation_shell()._render_screen(false, -1, false)

func settings_labeled_toggle_row(label_text: String, button_text: String, min_width := 1120, min_height := 180) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(min_width, min_height)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 48)
	var label: Label = host._label(label_text, 84, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.custom_minimum_size = Vector2(0, min_height)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var button: Button = host._menu_button(button_text)
	button.custom_minimum_size = Vector2(250, min_height)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.tooltip_text = ""
	button.add_theme_font_size_override("font_size", 64)
	row.add_child(button)
	row.set_meta("toggle_button", button)
	return row

func audio_slider_grabber(highlighted := false) -> Texture2D:
	if highlighted and audio_slider_grabber_highlight_texture != null:
		return audio_slider_grabber_highlight_texture
	if not highlighted and audio_slider_grabber_texture != null:
		return audio_slider_grabber_texture
	if not host.visual_texture_cache._can_create_image_textures():
		return null
	var diameter := 106 if highlighted else 96
	var radius := float(diameter) * 0.5
	var border := 14.0
	var border_color = host.COLOR_BLUE if highlighted else host.COLOR_INK
	var fill_color = host.COLOR_PANEL.lightened(0.08) if highlighted else host.COLOR_PANEL
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	for y in range(diameter):
		for x in range(diameter):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			var distance := point.distance_to(Vector2(radius, radius))
			if distance <= radius - 1.0:
				image.set_pixel(x, y, border_color if distance >= radius - border else fill_color)
	var texture: Texture2D = host.visual_texture_cache._create_image_texture(image)
	if highlighted:
		audio_slider_grabber_highlight_texture = texture
	else:
		audio_slider_grabber_texture = texture
	return texture

func _on_audio_slider_gui_input(event: InputEvent, slider: HSlider, music: bool) -> void:
	if slider == null or not is_instance_valid(slider):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		active_audio_slider = slider if event.pressed else active_audio_slider
		active_audio_slider_is_music = music
		active_audio_slider_touch_index = -1
		_update_active_audio_slider(event.global_position)
		if not event.pressed:
			_clear_active_audio_slider()
		host.get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and active_audio_slider == slider:
		_update_active_audio_slider(event.global_position)
		host.get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			active_audio_slider = slider
			active_audio_slider_is_music = music
			active_audio_slider_touch_index = event.index
			_update_active_audio_slider(event.position)
		elif active_audio_slider == slider and event.index == active_audio_slider_touch_index:
			_update_active_audio_slider(event.position)
			_clear_active_audio_slider()
		host.get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and active_audio_slider == slider and event.index == active_audio_slider_touch_index:
		_update_active_audio_slider(event.position)
		host.get_viewport().set_input_as_handled()


func _route_audio_slider_input(event: InputEvent) -> bool:
	if active_audio_slider == null or not is_instance_valid(active_audio_slider):
		_clear_active_audio_slider()
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_update_active_audio_slider(event.global_position)
		if not event.pressed:
			_clear_active_audio_slider()
		return true
	if event is InputEventMouseMotion:
		_update_active_audio_slider(event.global_position)
		return true
	if event is InputEventScreenTouch and event.index == active_audio_slider_touch_index:
		_update_active_audio_slider(event.position)
		if not event.pressed:
			_clear_active_audio_slider()
		return true
	if event is InputEventScreenDrag and event.index == active_audio_slider_touch_index:
		_update_active_audio_slider(event.position)
		return true
	return false


func _update_active_audio_slider(global_point: Vector2) -> void:
	if active_audio_slider == null or not is_instance_valid(active_audio_slider):
		return
	var rect := active_audio_slider.get_global_rect()
	if rect.size.x <= 1.0:
		return
	var pct := clampf((global_point.x - rect.position.x) / rect.size.x, 0.0, 1.0)
	var next_value: float = round(lerpf(float(active_audio_slider.min_value), float(active_audio_slider.max_value), pct))
	active_audio_slider.set_value_no_signal(next_value)
	if active_audio_slider_is_music:
		music_volume_labels = _sync_volume_labels(music_volume_labels, next_value / 100.0)
		_set_music_volume_from_slider(next_value)
	else:
		sfx_volume_labels = _sync_volume_labels(sfx_volume_labels, next_value / 100.0)
		_set_sfx_volume_from_slider(next_value)


func _clear_active_audio_slider() -> void:
	active_audio_slider = null
	active_audio_slider_touch_index = -1


func _clear_settings_page_control_refs() -> void:
	_clear_active_audio_slider()
	music_volume_sliders.clear()
	music_volume_labels.clear()
	music_mute_toggles.clear()
	music_mute_labels.clear()
	sfx_volume_sliders.clear()
	sfx_volume_labels.clear()
	sfx_mute_toggles.clear()
	sfx_mute_labels.clear()
	offline_progress_toggles.clear()
	auto_unlock_lockpad_toggles.clear()
	stamina_decimal_toggles.clear()
	offline_progress_cap_notification_toggles.clear()
	dark_mode_toggles.clear()
	god_mode_controls.clear()
	audio_controls_sync_key = ""


func _refresh_audio_volume_controls() -> void:
	var sync_key_parts := [
		host._audio_director().music_volume,
		host._audio_director().sfx_volume,
		host._audio_director().music_muted,
		host._audio_director().sfx_muted,
		host.offline_progress_enabled,
		host.auto_unlock_lockpads_enabled,
		host.show_stamina_decimal,
		host.offline_progress_cap_notifications_enabled,
		host.dark_mode_enabled,
		_control_array_ids(music_volume_sliders),
		_control_array_ids(sfx_volume_sliders),
		_control_array_ids(music_volume_labels),
		_control_array_ids(sfx_volume_labels),
		_control_array_ids(music_mute_toggles),
		_control_array_ids(sfx_mute_toggles),
		_control_array_ids(music_mute_labels),
		_control_array_ids(sfx_mute_labels),
		_control_array_ids(offline_progress_toggles),
		_control_array_ids(auto_unlock_lockpad_toggles),
		_control_array_ids(stamina_decimal_toggles),
		_control_array_ids(offline_progress_cap_notification_toggles),
		_control_array_ids(dark_mode_toggles),
		_control_array_ids(god_mode_controls),
	]
	var sync_key := ":".join(sync_key_parts.map(func(part): return str(part)))
	if audio_controls_sync_key == sync_key:
		return
	audio_controls_sync_key = sync_key
	music_volume_sliders = _sync_volume_sliders(music_volume_sliders, host._audio_director().music_volume)
	sfx_volume_sliders = _sync_volume_sliders(sfx_volume_sliders, host._audio_director().sfx_volume)
	music_volume_labels = _sync_volume_labels(music_volume_labels, host._audio_director().music_volume)
	sfx_volume_labels = _sync_volume_labels(sfx_volume_labels, host._audio_director().sfx_volume)
	music_mute_toggles = _sync_mute_toggles(music_mute_toggles, host._audio_director().music_muted)
	sfx_mute_toggles = _sync_mute_toggles(sfx_mute_toggles, host._audio_director().sfx_muted)
	music_mute_labels = _sync_mute_labels(music_mute_labels, host._audio_director().music_muted)
	sfx_mute_labels = _sync_mute_labels(sfx_mute_labels, host._audio_director().sfx_muted)
	_refresh_offline_progress_controls()
	_refresh_auto_unlock_lockpad_controls()
	_refresh_stamina_decimal_controls()
	_refresh_offline_progress_cap_notification_controls()
	_refresh_dark_mode_controls()
	_refresh_god_mode_controls()


func _control_array_ids(controls: Array) -> String:
	var ids := PackedStringArray()
	for raw_control in controls:
		if raw_control == null or not is_instance_valid(raw_control):
			ids.append("x")
			continue
		var control := raw_control as Control
		if control == null or not is_instance_valid(control):
			ids.append("x")
		else:
			ids.append(str(control.get_instance_id()))
	return ",".join(ids)


func _refresh_offline_progress_controls() -> void:
	var live := []
	for raw_toggle in offline_progress_toggles:
		if raw_toggle == null or not is_instance_valid(raw_toggle):
			continue
		var toggle := raw_toggle as Button
		if toggle == null or not is_instance_valid(toggle):
			continue
		host._app_lifecycle_runtime().set_button_text_if_changed(toggle, offline_progress_toggle_text())
		apply_offline_progress_toggle_style(toggle)
		live.append(toggle)
	offline_progress_toggles = live


func _refresh_auto_unlock_lockpad_controls() -> void:
	var live := []
	for raw_toggle in auto_unlock_lockpad_toggles:
		if raw_toggle == null or not is_instance_valid(raw_toggle):
			continue
		var toggle := raw_toggle as Button
		if toggle == null or not is_instance_valid(toggle):
			continue
		host._app_lifecycle_runtime().set_button_text_if_changed(toggle, auto_unlock_lockpad_toggle_text())
		apply_auto_unlock_lockpad_toggle_style(toggle)
		live.append(toggle)
	auto_unlock_lockpad_toggles = live


func _refresh_stamina_decimal_controls() -> void:
	var live := []
	for raw_toggle in stamina_decimal_toggles:
		if raw_toggle == null or not is_instance_valid(raw_toggle):
			continue
		var toggle := raw_toggle as Button
		if toggle == null or not is_instance_valid(toggle):
			continue
		host._app_lifecycle_runtime().set_button_text_if_changed(toggle, stamina_decimal_toggle_text())
		apply_stamina_decimal_toggle_style(toggle)
		live.append(toggle)
	stamina_decimal_toggles = live


func _sync_stamina_decimal_gauge_preference() -> void:
	var seen := {}
	var navigation_shell = host._navigation_shell()
	_apply_stamina_decimal_preference_to_circle(host._skill_detail_surface().detail_regen_circle, seen)
	_apply_stamina_decimal_preference_to_circle(navigation_shell.pinned_active_shelf_regen_circle, seen)
	for raw_gauge in navigation_shell.pinned_active_shelf_stamina_gauges.values():
		_apply_stamina_decimal_preference_to_circle(raw_gauge as RegenCircle, seen)
	for raw_card in host.skill_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		_apply_stamina_decimal_preference_to_circle(card.get("stamina") as RegenCircle, seen)


func _apply_stamina_decimal_preference_to_circle(circle: RegenCircle, seen: Dictionary) -> void:
	if circle == null or not is_instance_valid(circle):
		return
	var instance_id := circle.get_instance_id()
	if seen.has(instance_id):
		return
	seen[instance_id] = true
	circle.set_show_decimal(host.show_stamina_decimal)


func _refresh_offline_progress_cap_notification_controls() -> void:
	var live := []
	for raw_toggle in offline_progress_cap_notification_toggles:
		if raw_toggle == null or not is_instance_valid(raw_toggle):
			continue
		var toggle := raw_toggle as Button
		if toggle == null or not is_instance_valid(toggle):
			continue
		host._app_lifecycle_runtime().set_button_text_if_changed(toggle, offline_progress_cap_notification_toggle_text())
		apply_offline_progress_cap_notification_toggle_style(toggle)
		live.append(toggle)
	offline_progress_cap_notification_toggles = live


func _refresh_dark_mode_controls() -> void:
	var live := []
	for raw_toggle in dark_mode_toggles:
		if raw_toggle == null or not is_instance_valid(raw_toggle):
			continue
		var toggle := raw_toggle as Button
		if toggle == null or not is_instance_valid(toggle):
			continue
		host._app_lifecycle_runtime().set_button_text_if_changed(toggle, dark_mode_toggle_text())
		apply_dark_mode_toggle_style(toggle)
		live.append(toggle)
	dark_mode_toggles = live


func _sync_stamina_gauge_dark_mode() -> void:
	var seen := {}
	var navigation_shell = host._navigation_shell()
	_apply_stamina_gauge_dark_mode_to_circle(host._skill_detail_surface().detail_regen_circle, seen)
	_apply_stamina_gauge_dark_mode_to_circle(navigation_shell.pinned_active_shelf_regen_circle, seen)
	for raw_gauge in navigation_shell.pinned_active_shelf_stamina_gauges.values():
		_apply_stamina_gauge_dark_mode_to_circle(raw_gauge as RegenCircle, seen)
	for raw_card in host.skill_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		_apply_stamina_gauge_dark_mode_to_circle(card.get("stamina") as RegenCircle, seen)


func _apply_stamina_gauge_dark_mode_to_circle(circle: RegenCircle, seen: Dictionary) -> void:
	if circle == null or not is_instance_valid(circle):
		return
	var instance_id := circle.get_instance_id()
	if seen.has(instance_id):
		return
	seen[instance_id] = true
	circle.set_dark_mode(host.dark_mode_enabled)


func _sync_volume_sliders(sliders: Array, volume: float) -> Array:
	var live := []
	for raw_slider in sliders:
		if raw_slider == null or not is_instance_valid(raw_slider):
			continue
		var slider := raw_slider as HSlider
		if slider == null or not is_instance_valid(slider):
			continue
		var next_value: float = round(clampf(volume, 0.0, 1.0) * 100.0)
		if absf(float(slider.value) - next_value) > 0.001:
			slider.set_value_no_signal(next_value)
		live.append(slider)
	return live


func _sync_mute_labels(labels: Array, muted: bool) -> Array:
	var live := []
	for raw_label in labels:
		if raw_label == null or not is_instance_valid(raw_label):
			continue
		var label := raw_label as Label
		if label == null or not is_instance_valid(label):
			continue
		host._app_lifecycle_runtime().set_label_text_if_changed(label, "X" if muted else "")
		live.append(label)
	return live


func _sync_volume_labels(labels: Array, volume: float) -> Array:
	var live := []
	for raw_label in labels:
		if raw_label == null or not is_instance_valid(raw_label):
			continue
		var label := raw_label as Label
		if label == null or not is_instance_valid(label):
			continue
		host._app_lifecycle_runtime().set_label_text_if_changed(label, "%s%%" % int(round(clampf(volume, 0.0, 1.0) * 100.0)))
		live.append(label)
	return live


func _sync_mute_toggles(toggles: Array, muted: bool) -> Array:
	var live := []
	for raw_toggle in toggles:
		if raw_toggle == null or not is_instance_valid(raw_toggle):
			continue
		var toggle := raw_toggle as Button
		if toggle == null or not is_instance_valid(toggle):
			continue
		toggle.set_pressed_no_signal(muted)
		live.append(toggle)
	return live


func _show_notification_settings_notice() -> void:
	if not host.is_inside_tree():
		return
	host._app_lifecycle_runtime()._kill_tween_value(notification_permission_notice_tween)
	notification_permission_notice_tween = null
	if notification_permission_notice != null and is_instance_valid(notification_permission_notice):
		notification_permission_notice.queue_free()

	var canvas_size: Vector2 = host._current_canvas_size()
	var base_size := Vector2(1180, 250)
	var fitted_scale: float = host._fit_scale_to_canvas(base_size, Vector2(48, 48))
	var notice_size: Vector2 = base_size * fitted_scale
	var target_position := Vector2(
		(canvas_size.x - notice_size.x) * 0.5,
		clampf(canvas_size.y * 0.50, 48.0, maxf(48.0, canvas_size.y - notice_size.y - 48.0))
	)
	var banner := Control.new()
	banner.z_index = host.MODAL_OVERLAY_Z
	banner.z_as_relative = false
	banner.mouse_filter = Control.MOUSE_FILTER_STOP
	banner.custom_minimum_size = notice_size
	banner.size = notice_size
	banner.position = target_position + Vector2(0, 62.0 * fitted_scale)
	banner.pivot_offset = notice_size * 0.5
	banner.modulate = Color(1, 1, 1, 0)
	banner.scale = Vector2(0.94, 0.94)
	banner.gui_input.connect(_on_notification_settings_notice_gui_input)
	host.add_child(banner)
	notification_permission_notice = banner

	var card := PanelContainer.new()
	card.custom_minimum_size = base_size
	card.size = base_size
	card.scale = Vector2(fitted_scale, fitted_scale)
	card.add_theme_stylebox_override("panel", host._surface_style(Color("#fff6d8"), 42, 52, true))
	banner.add_child(card)

	var body: Label = host._label("Turn on notifications in your phone settings if they are not already on.", 56, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(body)

	var tween: Tween = host.create_tween()
	notification_permission_notice_tween = tween
	tween.set_parallel(true)
	tween.tween_property(banner, "position", target_position, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate:a", 1.0, 0.10)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(4.0)
	tween.chain().tween_callback(_dismiss_notification_settings_notice)


func _on_notification_settings_notice_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_dismiss_notification_settings_notice()
			host.get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_dismiss_notification_settings_notice()
			host.get_viewport().set_input_as_handled()


func _dismiss_notification_settings_notice() -> void:
	var banner := notification_permission_notice
	if banner == null or not is_instance_valid(banner):
		notification_permission_notice = null
		notification_permission_notice_tween = null
		return
	host._app_lifecycle_runtime()._kill_tween_value(notification_permission_notice_tween)
	notification_permission_notice_tween = host.create_tween()
	notification_permission_notice_tween.tween_property(banner, "modulate:a", 0.0, 0.12)
	notification_permission_notice_tween.tween_callback(_finish_notification_settings_notice)


func _finish_notification_settings_notice() -> void:
	if notification_permission_notice != null and is_instance_valid(notification_permission_notice):
		notification_permission_notice.queue_free()
	notification_permission_notice = null
	notification_permission_notice_tween = null


func _clear_notification_settings_notice_immediate() -> void:
	host._app_lifecycle_runtime()._kill_tween_value(notification_permission_notice_tween)
	if notification_permission_notice != null and is_instance_valid(notification_permission_notice):
		notification_permission_notice.queue_free()
	notification_permission_notice = null
	notification_permission_notice_tween = null


func _navigation_state() -> Dictionary:
	return {
		"music_volume_sliders": music_volume_sliders,
		"music_volume_labels": music_volume_labels,
		"music_mute_toggles": music_mute_toggles,
		"music_mute_labels": music_mute_labels,
		"sfx_volume_sliders": sfx_volume_sliders,
		"sfx_volume_labels": sfx_volume_labels,
		"sfx_mute_toggles": sfx_mute_toggles,
		"sfx_mute_labels": sfx_mute_labels,
		"offline_progress_toggles": offline_progress_toggles,
		"auto_unlock_lockpad_toggles": auto_unlock_lockpad_toggles,
		"stamina_decimal_toggles": stamina_decimal_toggles,
		"offline_progress_cap_notification_toggles": offline_progress_cap_notification_toggles,
		"dark_mode_toggles": dark_mode_toggles,
		"audio_controls_sync_key": audio_controls_sync_key,
		"reset_data_buttons": reset_data_buttons,
		"reset_data_confirm_until": reset_data_confirm_until,
		"reset_data_confirm_armed_at": reset_data_confirm_armed_at,
		"reset_data_confirm_button": reset_data_confirm_button,
	}


func _apply_navigation_state(state: Dictionary) -> void:
	music_volume_sliders = state.get("music_volume_sliders", []) as Array
	music_volume_labels = state.get("music_volume_labels", []) as Array
	music_mute_toggles = state.get("music_mute_toggles", []) as Array
	music_mute_labels = state.get("music_mute_labels", []) as Array
	sfx_volume_sliders = state.get("sfx_volume_sliders", []) as Array
	sfx_volume_labels = state.get("sfx_volume_labels", []) as Array
	sfx_mute_toggles = state.get("sfx_mute_toggles", []) as Array
	sfx_mute_labels = state.get("sfx_mute_labels", []) as Array
	offline_progress_toggles = state.get("offline_progress_toggles", []) as Array
	auto_unlock_lockpad_toggles = state.get("auto_unlock_lockpad_toggles", []) as Array
	stamina_decimal_toggles = state.get("stamina_decimal_toggles", []) as Array
	offline_progress_cap_notification_toggles = state.get("offline_progress_cap_notification_toggles", []) as Array
	dark_mode_toggles = state.get("dark_mode_toggles", []) as Array
	audio_controls_sync_key = str(state.get("audio_controls_sync_key", ""))
	reset_data_buttons = state.get("reset_data_buttons", []) as Array
	reset_data_confirm_until = float(state.get("reset_data_confirm_until", 0.0))
	reset_data_confirm_armed_at = float(state.get("reset_data_confirm_armed_at", 0.0))
	reset_data_confirm_button = host._app_lifecycle_runtime().state_object_ref(state.get("reset_data_confirm_button")) as Button


func _register_reset_button(button: Button, default_text: String) -> void:
	button.set_meta("reset_default_text", default_text)
	button.set_meta("reset_confirm_until", 0.0)
	button.set_meta("reset_confirm_armed_at", 0.0)
	button.pressed.connect(_confirm_reset_data_bound.bind(button.get_instance_id()))
	if not reset_data_buttons.has(button):
		reset_data_buttons.append(button)
	_refresh_reset_data_buttons()


func _confirm_reset_data_bound(button_id: int) -> void:
	var button: Button = host._app_lifecycle_runtime().valid_button_ref(instance_from_id(button_id))
	if button == null:
		return
	_confirm_reset_data(button)


func _confirm_reset_data(_button: Button) -> void:
	if _button == null or not is_instance_valid(_button):
		return
	if not reset_data_buttons.has(_button):
		reset_data_buttons.append(_button)
	_kill_reset_data_feedback_tween(_button)
	var now := Time.get_ticks_msec() / 1000.0
	var confirm_until := float(_button.get_meta("reset_confirm_until", 0.0))
	var confirm_armed_at := float(_button.get_meta("reset_confirm_armed_at", 0.0))
	if str(_button.text) == RESET_DATA_CONFIRM_TEXT and confirm_until > now:
		if now - confirm_armed_at < RESET_DATA_CONFIRM_MIN_SECONDS:
			return
		_clear_reset_button_confirmation(_button)
		host._save_runtime().reset_data(_button)
		return
	reset_data_confirm_until = now + RESET_DATA_CONFIRM_SECONDS
	reset_data_confirm_armed_at = now
	reset_data_confirm_button = _button
	_button.set_meta("reset_confirm_armed_at", now)
	_button.set_meta("reset_confirm_until", reset_data_confirm_until)
	_button.text = RESET_DATA_CONFIRM_TEXT
	host._reward_feedback_surface()._set_result("Tap again to confirm hard reset.")
	_refresh_reset_data_buttons()


func _disarm_reset_data_confirmation() -> void:
	if reset_data_buttons.is_empty() and reset_data_confirm_until <= 0.0 and reset_data_confirm_button == null:
		return
	reset_data_confirm_until = 0.0
	reset_data_confirm_armed_at = 0.0
	reset_data_confirm_button = null
	for raw_button in reset_data_buttons:
		_clear_reset_button_confirmation(raw_button as Button)
	_refresh_reset_data_buttons()


func _clear_reset_data_buttons_for_rebuild() -> void:
	reset_data_confirm_until = 0.0
	reset_data_confirm_armed_at = 0.0
	reset_data_confirm_button = null
	for raw_button in reset_data_buttons:
		if raw_button == null or not is_instance_valid(raw_button):
			continue
		var button := raw_button as Button
		if button == null:
			continue
		_kill_reset_data_feedback_tween(button)
		_clear_reset_button_confirmation(button)
		button.modulate = Color.WHITE
	reset_data_buttons.clear()


func _disarm_reset_data_confirmation_on_outside_press(event: InputEvent) -> void:
	var press_position := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		press_position = host._input_routing_shell()._global_event_position(mouse_event.position, mouse_event.global_position)
		pressed = event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		press_position = host._input_routing_shell()._global_event_position(touch_event.position, touch_event.position)
		pressed = event.pressed
	if not pressed:
		return
	var any_armed := false
	var now := Time.get_ticks_msec() / 1000.0
	for raw_button in reset_data_buttons:
		if raw_button == null or not is_instance_valid(raw_button):
			continue
		var button := raw_button as Button
		if button == null:
			continue
		if float(button.get_meta("reset_confirm_until", 0.0)) > now:
			any_armed = true
			if button.is_visible_in_tree():
				var button_rect := button.get_global_rect()
				if button_rect.has_point(press_position):
					return
				for candidate in host._input_routing_shell()._activity_input_position_candidates(press_position):
					if button_rect.has_point(candidate):
						return
	if not any_armed:
		return
	call_deferred("_disarm_reset_data_confirmation")


func _refresh_reset_data_buttons() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var live_buttons := []
	for raw_button in reset_data_buttons:
		if raw_button == null or not is_instance_valid(raw_button):
			continue
		var button := raw_button as Button
		if button == null:
			continue
		var is_armed_button := float(button.get_meta("reset_confirm_until", 0.0)) > now
		if is_armed_button:
			button.text = RESET_DATA_CONFIRM_TEXT
		else:
			_clear_reset_button_confirmation(button)
		live_buttons.append(button)
	reset_data_buttons = live_buttons


func _expire_reset_data_confirm_if_needed() -> void:
	reset_data_confirm_until = 0.0
	reset_data_confirm_armed_at = 0.0
	reset_data_confirm_button = null
	_refresh_reset_data_buttons()


func _clear_reset_button_confirmation(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.set_meta("reset_confirm_until", 0.0)
	button.set_meta("reset_confirm_armed_at", 0.0)
	button.text = str(button.get_meta("reset_default_text", "Hard Reset"))
	button.modulate = Color.WHITE


func _is_dead_reset_confirm_press(button: BaseButton) -> bool:
	if button == null or not is_instance_valid(button) or not (button is Button):
		return false
	var reset_button := button as Button
	if str(reset_button.text) != RESET_DATA_CONFIRM_TEXT:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	var confirm_until := float(reset_button.get_meta("reset_confirm_until", 0.0))
	if confirm_until <= now:
		return false
	var confirm_armed_at := float(reset_button.get_meta("reset_confirm_armed_at", 0.0))
	return now - confirm_armed_at < RESET_DATA_CONFIRM_MIN_SECONDS


func _play_reset_data_wiped_feedback_by_id(feedback_button_id: int = 0) -> void:
	var feedback_button: Button = host._app_lifecycle_runtime().valid_button_ref(instance_from_id(feedback_button_id)) if feedback_button_id != 0 else null
	_play_reset_data_wiped_feedback(feedback_button)


func _play_reset_data_wiped_feedback(feedback_button: Button = null) -> void:
	var feedback_buttons := []
	if feedback_button != null and is_instance_valid(feedback_button):
		feedback_buttons.append(feedback_button)
	for raw_button in reset_data_buttons:
		var button := raw_button as Button
		if button == null or not is_instance_valid(button) or not button.is_visible_in_tree():
			continue
		if not feedback_buttons.has(button):
			feedback_buttons.append(button)
	for raw_button in feedback_buttons:
		var button := raw_button as Button
		if button == null or not is_instance_valid(button) or not button.is_visible_in_tree():
			continue
		host._reward_feedback_surface()._float_reward(host, button, "data wiped!", 72, Color("#ff6b6b"), Vector2(0, -72), Vector2(0, -190), 0.0)


func _kill_reset_data_feedback_tween(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	host._app_lifecycle_runtime()._kill_meta_tween(button, "reset_feedback_tween")
	if button.has_meta("reset_feedback_active"):
		button.remove_meta("reset_feedback_active")

func settings_page_button(text: String, icon_path := "", min_width := 900, icon_max_width := 128, min_height := 250) -> Button:
	var button: Button = host._menu_button(text if icon_path.is_empty() else "")
	button.custom_minimum_size = Vector2(min_width, min_height)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 70)
	button.add_theme_stylebox_override("normal", host._paper_button_style(host.COLOR_BLUE, 54))
	button.add_theme_stylebox_override("hover", host._paper_button_style(host.COLOR_BLUE, 54))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(host.COLOR_BLUE.darkened(0.10), 54, 72, true))
	if not icon_path.is_empty():
		var content := MarginContainer.new()
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("margin_left", 54)
		content.add_theme_constant_override("margin_right", 68)
		content.add_theme_constant_override("margin_top", 18)
		content.add_theme_constant_override("margin_bottom", 18)
		button.add_child(content)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 38)
		content.add_child(row)
		var icon_holder := CenterContainer.new()
		icon_holder.custom_minimum_size = Vector2(icon_max_width, icon_max_width)
		icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_holder)
		var icon := TextureRect.new()
		icon.texture = host.visual_texture_cache._texture_or_visual_fallback(icon_path)
		icon.custom_minimum_size = Vector2(icon_max_width, icon_max_width)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_holder.add_child(icon)
		var label: Label = host._label(text, 70, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		label.add_theme_color_override("font_outline_color", host.COLOR_INK)
		label.add_theme_constant_override("outline_size", host.DEFAULT_BUTTON_TEXT_OUTLINE_SIZE)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
	return button
