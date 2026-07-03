class_name NavigationShell
extends RefCounted

const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const BlueGuyHealthHeartGauge = preload("res://scripts/ui/blue_guy_health_heart_gauge.gd")
const ButtonPressState = preload("res://scripts/ui/button_press_state.gd")
const ModuleSortMenuUi = preload("res://scripts/ui/module_sort_menu_ui.gd")
const ModuleUtilityRowUi = preload("res://scripts/ui/module_utility_row_ui.gd")
const PageSwitchButtonFace = preload("res://scripts/ui/page_switch_button_face.gd")
const PageSwitchChevronIcon = preload("res://scripts/ui/page_switch_chevron_icon.gd")
const SkillIconBadge = preload("res://scripts/ui/skill_icon_badge.gd")
const SkillIconSymbolDraw = preload("res://scripts/ui/skill_icon_symbol_draw.gd")
const ChatStyles = preload("res://scripts/chat/styles.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const MODULE_QUEUE_ICON_TEXTURE := "res://assets/content/ui/navigation-controls/queue.png"
const PINNED_ACTIVITIES_EMPTY_DECOR_PIN_COUNT := 7
const PAGE_SWITCH_MODULE_HEIGHT := 340
const PAGE_SWITCH_SKILL_ICON_STAGE_SIZE := Vector2(430, 430)
const PAGE_SWITCH_SKILL_ICON_SYMBOL_BASE_SIZE := Vector2(446, 446)
const PAGE_SWITCH_SKILL_ICON_EDGE_CROP := 54.0
const PAGE_SWITCH_SKILL_ICON_VERTICAL_SHIFT := -4.0

var host
var queue_return_screen := "skill"
var queue_return_skill_id := ""
var queue_return_detail_scroll := -1
var module_utility_row: Control
var module_utility_buttons_row: HBoxContainer
var module_utility_collapse_toggle: Button
var module_utility_collapsed := false
var module_utility_buttons_motion_active := false
var module_utility_buttons_motion_expanded := true
var module_utility_buttons_motion_started_msec := 0
var module_utility_buttons_motion_duration_msec := 0
var module_utility_buttons_motion_frame := 0
var module_utility_buttons_motion_total_frames := 1
var module_utility_buttons_motion_from_offset := 0.0
var module_utility_buttons_motion_to_offset := 0.0
var module_utility_buttons_motion_from_alpha := 1.0
var module_utility_buttons_motion_to_alpha := 1.0
var pinned_utility_tab: Button
var queue_utility_tab: Button
var skills_utility_tab: Button
var sort_utility_tab: Button
var module_sort_menu: Control
var module_sort_menu_visual: Control
var module_sort_menu_tween: Tween
var module_sort_low_level_button: Button
var module_sort_high_level_button: Button
var module_sort_combo_button: Button
var module_sort_collection_button: Button
var nav_symbol_seen_ids := {}
var hero_nav_unlocked := false
var hero_nav_fade_tween: Tween
var hub_nav_unlocked := false
var hub_nav_fade_tween: Tween
var shop_nav_unlocked := false
var shop_nav_fade_tween: Tween
var page_switch_pending_transition := {}
var page_switch_release_when_render_idle := false
var page_switch_transition_button_id := 0
var page_switch_transition_target_skill_id := ""
var page_switch_press_active := false
var page_switch_press_target_skill_id := ""
var page_switch_press_position := Vector2.ZERO
var page_switch_press_dragged := false

func _init(next_host) -> void:
	host = next_host


func _event_points_inside_bottom_nav(event: InputEvent, source: Control = null) -> bool:
	return host._event_points_inside_bottom_interactive_ui(event, source, true)


func _position_inside_bottom_nav(event_position: Vector2) -> bool:
	if host.nav_bar == null or not is_instance_valid(host.nav_bar) or not host.nav_bar.is_visible_in_tree():
		return false
	var nav_rect: Rect2 = host.nav_bar.get_global_rect().grow(4.0)
	return nav_rect.has_point(event_position)


func _build_nav_bar() -> void:
	host.nav_bar = PanelContainer.new()
	host.nav_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	host.nav_bar.offset_top = -host.BOTTOM_NAV_HEIGHT
	host.nav_bar.z_index = host.CHAT_UI_Z
	host.nav_bar.z_as_relative = false
	host.nav_bar.clip_contents = true
	host.nav_bar.add_theme_stylebox_override("panel", _nav_style())
	host.add_child(host.nav_bar)
	var row := HBoxContainer.new()
	row.name = "BottomNavButtonsRow"
	host.bottom_nav_buttons_row = row
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 120)
	row.clip_contents = true
	row.custom_minimum_size = Vector2(0, host.BOTTOM_NAV_HEIGHT - host.BOTTOM_NAV_SAFE_PAD)
	host.nav_bar.add_child(row)
	host.hero_tab = _nav_button(host.PROGRESS_STAR_ICON_TEXTURE, true)
	host.hero_tab.custom_minimum_size = Vector2(318, 318)
	host.hero_tab.add_theme_constant_override("icon_max_width", 244)
	_register_nav_new_symbol_dot(host.hero_tab, "hero")
	host.hero_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	host.hero_tab.pressed.connect(_activate_bottom_nav_target.bind("home", host.hero_tab))
	host.hero_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("home", host.hero_tab))
	row.add_child(host.hero_tab)
	_sync_hero_nav_button(true)
	host.hub_tab = _nav_button("res://assets/content/hub/hub-nav-barn.png", true)
	host.hub_tab.add_theme_constant_override("icon_max_width", 220)
	_register_nav_new_symbol_dot(host.hub_tab, "hub")
	host.hub_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	host.hub_tab.pressed.connect(_activate_bottom_nav_target.bind("hub", host.hub_tab))
	host.hub_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("hub", host.hub_tab))
	row.add_child(host.hub_tab)
	_sync_hub_nav_button(true)
	host.skills_tab = _nav_button(host.TOTAL_LEVEL_BARGRAPH_TEXTURE, true)
	host.skills_tab.set_meta("nav_open_icon_disabled", true)
	host.skills_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	host.skills_tab.pressed.connect(host._show_skills_module)
	host.skills_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("skill", host.skills_tab))
	row.add_child(host.skills_tab)
	host.settings_tab = _nav_button(host.SETTINGS_GEAR_ICON_TEXTURE, true)
	host.settings_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	host.settings_tab.pressed.connect(_activate_bottom_nav_target.bind("settings", host.settings_tab))
	host.settings_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("settings", host.settings_tab))
	row.add_child(host.settings_tab)
	host.shop_tab = _nav_button(host.SHOP_ICON_TEXTURE, true)
	host.shop_tab.add_theme_constant_override("icon_max_width", 232)
	_register_nav_new_symbol_dot(host.shop_tab, "shop")
	host.shop_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	host.shop_tab.pressed.connect(_activate_bottom_nav_target.bind("shop", host.shop_tab))
	host.shop_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("shop", host.shop_tab))
	row.add_child(host.shop_tab)
	shop_nav_unlocked = false
	host.shop_tab.modulate = host.HUB_NAV_LOCKED_MODULATE
	_sync_bottom_nav_visibility()


func _ensure_nav_bar_icons() -> void:
	for button in [host.hero_tab, host.hub_tab, host.skills_tab, host.settings_tab, host.shop_tab]:
		if button == null or not is_instance_valid(button):
			continue
		var path := str(button.get_meta("deferred_icon_path", ""))
		if path.is_empty():
			continue
		button.remove_meta("deferred_icon_path")
		button.icon = host.visual_texture_cache._texture_or_visual_fallback(path)
		button.set_meta("nav_current_icon_path", path)


func _nav_button(path: String, defer_icon := false) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(268, 268)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("nav_default_icon_path", path)
	if defer_icon:
		button.set_meta("deferred_icon_path", path)
	else:
		button.icon = host.visual_texture_cache._texture_or_visual_fallback(path)
		button.set_meta("nav_current_icon_path", path)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 184)
	_apply_nav_style(button, false)
	var button_id := button.get_instance_id()
	host._button_press_runtime().attach_button_depress_animation(button, 0.92, false)
	button.pressed.connect(host._button_press_runtime()._pop_nav_button_bound.bind(button_id))
	return button


func _set_nav_button_icon(button: Button, path: String) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.icon = host.visual_texture_cache._texture_or_visual_fallback(path)
	button.set_meta("nav_current_icon_path", path)


func _sync_nav_button_open_icon(button: Button, active: bool) -> void:
	if button == null or not is_instance_valid(button):
		return
	var default_path := str(button.get_meta("nav_default_icon_path", ""))
	if default_path.is_empty():
		return
	var target_path := default_path
	if active and not bool(button.get_meta("nav_open_icon_disabled", false)):
		target_path = host.NAV_OPEN_CLOSE_ICON_TEXTURE
	if button.has_meta("deferred_icon_path"):
		button.remove_meta("deferred_icon_path")
		_set_nav_button_icon(button, target_path)
		return
	if str(button.get_meta("nav_current_icon_path", "")) == target_path:
		return
	_set_nav_button_icon(button, target_path)


func _nav_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = host.COLOR_NAV
	style.border_color = host.COLOR_INK
	style.border_width_top = 15
	style.content_margin_left = 96
	style.content_margin_right = 96
	style.content_margin_top = 36
	style.content_margin_bottom = host.BOTTOM_NAV_SAFE_PAD
	return style


func _apply_nav_style(button: Button, _active: bool) -> void:
	if button == null:
		return
	if not bool(button.get_meta("nav_empty_style_applied", false)):
		button.add_theme_stylebox_override("normal", host.empty_style_cache)
		button.add_theme_stylebox_override("hover", host.empty_style_cache)
		button.add_theme_stylebox_override("pressed", host.empty_style_cache)
		button.add_theme_stylebox_override("focus", host.empty_style_cache)
		button.set_meta("nav_empty_style_applied", true)
	_sync_nav_button_open_icon(button, _active)


func _sync_bottom_nav_visibility() -> void:
	if host.nav_bar == null or not is_instance_valid(host.nav_bar):
		return
	var controls_unlocked: bool = host._intro_bottom_controls_unlocked()
	host.nav_bar.visible = true
	if host.bottom_nav_buttons_row != null and is_instance_valid(host.bottom_nav_buttons_row):
		host.bottom_nav_buttons_row.visible = true
	if controls_unlocked:
		if host.hero_tab != null and is_instance_valid(host.hero_tab):
			host.hero_tab.visible = true
			host.hero_tab.disabled = false
			host.hero_tab.mouse_filter = Control.MOUSE_FILTER_STOP
			host.hero_tab.self_modulate = Color.WHITE
		if host.hub_tab != null and is_instance_valid(host.hub_tab):
			host.hub_tab.visible = true
			host.hub_tab.disabled = false
			host.hub_tab.mouse_filter = Control.MOUSE_FILTER_STOP
			host.hub_tab.self_modulate = Color.WHITE
		if host.skills_tab != null and is_instance_valid(host.skills_tab):
			host.skills_tab.visible = true
			host.skills_tab.disabled = false
			host.skills_tab.mouse_filter = Control.MOUSE_FILTER_STOP
			host.skills_tab.self_modulate = Color.WHITE
			host.skills_tab.modulate = Color.WHITE
		if host.settings_tab != null and is_instance_valid(host.settings_tab):
			host.settings_tab.visible = true
			host.settings_tab.disabled = false
			host.settings_tab.mouse_filter = Control.MOUSE_FILTER_STOP
			host.settings_tab.self_modulate = Color.WHITE
			host.settings_tab.modulate = Color.WHITE
		if host.shop_tab != null and is_instance_valid(host.shop_tab):
			host.shop_tab.visible = true
			host.shop_tab.disabled = false
			host.shop_tab.mouse_filter = Control.MOUSE_FILTER_STOP
			host.shop_tab.self_modulate = Color.WHITE
		_sync_hero_nav_button(true)
		_sync_hub_nav_button(true)
		_sync_shop_nav_button(true)
		return
	for raw_button in [host.hero_tab, host.hub_tab, host.skills_tab, host.settings_tab, host.shop_tab]:
		var button := raw_button as Button
		if button == null or not is_instance_valid(button):
			continue
		var settings_button: bool = button == host.settings_tab
		var skills_button: bool = button == host.skills_tab
		button.visible = true
		button.self_modulate = Color.WHITE
		if controls_unlocked or settings_button or skills_button:
			button.modulate = Color.WHITE
		else:
			button.modulate = host.HUB_NAV_LOCKED_MODULATE
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_STOP if controls_unlocked or settings_button or skills_button else Control.MOUSE_FILTER_IGNORE


func _on_bottom_nav_button_gui_input(event: InputEvent, target_screen: String, button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if _bottom_nav_transition_input_locked(button):
		return
	var event_position: Vector2 = host._passive_button_event_position(event, button)
	var event_kind := ButtonPressState.event_kind(event)
	if event_kind == "press":
		ButtonPressState.begin(button, "bottom_nav", event_position)
		return
	if event_kind == "drag":
		ButtonPressState.update_drag(button, "bottom_nav", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
		return
	if event_kind != "release":
		return
	if not ButtonPressState.finish(button, "bottom_nav", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, 24.0):
		return
	_arm_bottom_nav_clean_activation(button, target_screen)
	_activate_bottom_nav_target(target_screen, button)


func _route_bottom_nav_button_global_input(event: InputEvent) -> bool:
	if host.nav_bar == null or not is_instance_valid(host.nav_bar):
		return false
	if not host.nav_bar.is_inside_tree() or not host.nav_bar.is_visible_in_tree():
		return false
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	var event_position: Vector2 = host._passive_button_event_position(event, null)
	var is_press: bool = _module_utility_event_is_press(event)
	if is_press and _position_inside_module_utility_interactive_ui(event_position):
		return false
	if is_press and host._profile_chat_overlay_surface()._position_inside_chat_strip_interactive_ui(event_position):
		return false
	var button := _bottom_nav_button_at_position(event_position) if is_press else _active_bottom_nav_button()
	if button == null:
		return false
	var target_screen := _bottom_nav_target_for_button(button)
	if target_screen.is_empty():
		return false
	_on_bottom_nav_button_gui_input(event, target_screen, button)
	host._cancel_skill_swipe_feedback(false)
	host._clear_active_fishing_method_button_press()
	host.action_card_press_key = ""
	return true


func _bottom_nav_button_at_position(event_position: Vector2) -> Button:
	for raw_button in [host.hero_tab, host.hub_tab, host.skills_tab, host.settings_tab, host.shop_tab]:
		var button := raw_button as Button
		if button == null or not is_instance_valid(button) or button.disabled:
			continue
		if not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		var button_rect := button.get_global_rect().grow(24.0)
		if button_rect.has_point(event_position):
			return button
	return null


func _active_bottom_nav_button() -> Button:
	for raw_button in [host.hero_tab, host.hub_tab, host.skills_tab, host.settings_tab, host.shop_tab]:
		var button := raw_button as Button
		if ButtonPressState.active(button, "bottom_nav"):
			return button
	return null


func _bottom_nav_target_for_button(button: Button) -> String:
	if button == host.hero_tab:
		return "home"
	if button == host.hub_tab:
		return "hub"
	if button == host.skills_tab:
		return "skill"
	if button == host.settings_tab:
		return "settings"
	if button == host.shop_tab:
		return "shop"
	return ""


func _bottom_nav_target_locked(target_screen: String) -> bool:
	match target_screen:
		"home":
			return not host._hero_unlocked()
		"hub":
			return not host._hub_unlocked()
		"shop":
			return not host._shop_unlocked()
	return false


func _show_bottom_nav_locked_message(target_screen: String, source_button: Control) -> void:
	match target_screen:
		"home":
			_show_hero_locked_message(source_button)
		"hub":
			_show_hub_locked_message(source_button)
		"shop":
			_show_shop_locked_message(source_button)


func _register_nav_new_symbol_dot(button: Button, nav_id: String) -> void:
	if button == null or nav_id.is_empty():
		return
	button.set_meta("nav_symbol_id", nav_id)
	button.set_meta("nav_new_symbol_dot", _nav_new_symbol_dot(button))
	_sync_nav_new_symbol_dot(nav_id)


func _nav_new_symbol_dot(button: Button) -> PanelContainer:
	var dot := PanelContainer.new()
	var diameter: float = host.CHAT_UNREAD_DOT_DIAMETER
	var inset := 28.0
	dot.anchor_left = 1.0
	dot.anchor_right = 1.0
	dot.anchor_top = 0.0
	dot.anchor_bottom = 0.0
	dot.offset_left = -diameter - inset
	dot.offset_right = -inset
	dot.offset_top = inset
	dot.offset_bottom = inset + diameter
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.visible = false
	dot.z_index = 20
	dot.add_theme_stylebox_override("panel", ChatStyles.unread_dot())
	button.add_child(dot)
	return dot


func _nav_symbol_unlocked(nav_id: String) -> bool:
	match nav_id:
		"hero":
			return host._hero_unlocked()
		"hub":
			return host._hub_unlocked()
		"shop":
			return host._shop_unlocked()
	return true


func _nav_symbol_has_been_seen(nav_id: String) -> bool:
	return bool(nav_symbol_seen_ids.get(nav_id, false))


func _mark_nav_symbol_seen(nav_id: String) -> void:
	if nav_id.is_empty() or _nav_symbol_has_been_seen(nav_id):
		return
	nav_symbol_seen_ids[nav_id] = true
	_sync_nav_new_symbol_dot(nav_id)
	host.save_game()


func _nav_symbol_seen_ids_for_save() -> Dictionary:
	var normalized := {}
	for raw_id in nav_symbol_seen_ids.keys():
		var nav_id := str(raw_id)
		if not nav_id.is_empty() and bool(nav_symbol_seen_ids.get(raw_id, false)):
			normalized[nav_id] = true
	return normalized


func _restore_nav_symbol_seen_ids(raw_seen: Variant) -> void:
	nav_symbol_seen_ids.clear()
	if typeof(raw_seen) != TYPE_DICTIONARY:
		return
	for raw_id in (raw_seen as Dictionary).keys():
		var nav_id := str(raw_id)
		if not nav_id.is_empty() and bool((raw_seen as Dictionary).get(raw_id, false)):
			nav_symbol_seen_ids[nav_id] = true


func _sync_nav_new_symbol_dot(nav_id: String = "") -> void:
	var ids := ["hero", "hub", "shop"] if nav_id.is_empty() else [nav_id]
	for raw_id in ids:
		var id := str(raw_id)
		var should_show: bool = _nav_symbol_unlocked(id) and not _nav_symbol_has_been_seen(id)
		for button in _nav_symbol_buttons(id):
			if button == null or not is_instance_valid(button):
				continue
			var dot := button.get_meta("nav_new_symbol_dot", null) as CanvasItem
			if dot != null and is_instance_valid(dot):
				host._set_canvas_item_visible_if_changed(dot, should_show)


func _nav_symbol_buttons(nav_id: String) -> Array:
	match nav_id:
		"hero":
			return [host.hero_tab, host.chat_home_tab]
		"hub":
			return [host.hub_tab, host.chat_hub_tab]
		"shop":
			return [host.shop_tab, host.chat_shop_tab]
	return []


func _sync_hero_nav_button(instant := false) -> void:
	if host.hero_tab == null or not is_instance_valid(host.hero_tab):
		return
	var unlocked: bool = host._hero_unlocked()
	var target_modulate: Color = Color.WHITE if unlocked else host.HUB_NAV_LOCKED_MODULATE
	hero_nav_unlocked = unlocked
	host.hero_tab.tooltip_text = ""
	if host.chat_home_tab != null and is_instance_valid(host.chat_home_tab):
		host.chat_home_tab.tooltip_text = ""
	if hero_nav_fade_tween != null and hero_nav_fade_tween.is_valid():
		hero_nav_fade_tween.kill()
		hero_nav_fade_tween = null
	if instant:
		host.hero_tab.modulate = target_modulate
		if host.chat_home_tab != null and is_instance_valid(host.chat_home_tab):
			host.chat_home_tab.modulate = target_modulate
		_sync_nav_new_symbol_dot("hero")
		return
	hero_nav_fade_tween = host.create_tween()
	hero_nav_fade_tween.tween_property(host.hero_tab, "modulate", target_modulate, host.HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if host.chat_home_tab != null and is_instance_valid(host.chat_home_tab):
		hero_nav_fade_tween.parallel().tween_property(host.chat_home_tab, "modulate", target_modulate, host.HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sync_nav_new_symbol_dot("hero")
	hero_nav_fade_tween.finished.connect(_finish_hero_nav_fade_tween)


func _finish_hero_nav_fade_tween() -> void:
	hero_nav_fade_tween = null


func _refresh_hero_nav_unlock_state() -> void:
	if host.hero_tab == null or not is_instance_valid(host.hero_tab):
		return
	var unlocked: bool = host._hero_unlocked()
	if unlocked == hero_nav_unlocked:
		return
	_sync_hero_nav_button(not unlocked)


func _show_hero_locked_message(source_button: Control = null) -> void:
	host._set_result(host.HERO_LOCKED_MESSAGE, false)
	var anchor: Control = source_button
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		anchor = host.hero_tab
	if anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree():
		_float_nav_locked_message(anchor, host.HERO_LOCKED_MESSAGE)


func _sync_shop_nav_button(instant := false) -> void:
	if host.shop_tab == null or not is_instance_valid(host.shop_tab):
		return
	var unlocked: bool = host._shop_unlocked()
	var target_modulate: Color = Color.WHITE if unlocked else host.HUB_NAV_LOCKED_MODULATE
	shop_nav_unlocked = unlocked
	host.shop_tab.tooltip_text = ""
	if host.chat_shop_tab != null and is_instance_valid(host.chat_shop_tab):
		host.chat_shop_tab.tooltip_text = ""
	if shop_nav_fade_tween != null and shop_nav_fade_tween.is_valid():
		shop_nav_fade_tween.kill()
		shop_nav_fade_tween = null
	if instant:
		host.shop_tab.modulate = target_modulate
		if host.chat_shop_tab != null and is_instance_valid(host.chat_shop_tab):
			host.chat_shop_tab.modulate = target_modulate
		_sync_nav_new_symbol_dot("shop")
		return
	shop_nav_fade_tween = host.create_tween()
	shop_nav_fade_tween.tween_property(host.shop_tab, "modulate", target_modulate, host.HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if host.chat_shop_tab != null and is_instance_valid(host.chat_shop_tab):
		shop_nav_fade_tween.parallel().tween_property(host.chat_shop_tab, "modulate", target_modulate, host.HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sync_nav_new_symbol_dot("shop")
	shop_nav_fade_tween.finished.connect(_finish_shop_nav_fade_tween)


func _finish_shop_nav_fade_tween() -> void:
	shop_nav_fade_tween = null


func _refresh_shop_nav_unlock_state() -> void:
	if host.shop_tab == null or not is_instance_valid(host.shop_tab):
		return
	var unlocked: bool = host._shop_unlocked()
	if unlocked == shop_nav_unlocked:
		return
	_sync_shop_nav_button(not unlocked)


func _show_shop_locked_message(source_button: Control = null) -> void:
	host._set_result(host.SHOP_LOCKED_MESSAGE, false)
	var anchor: Control = source_button
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		anchor = host.shop_tab
	if anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree():
		_float_nav_locked_message(anchor, host.SHOP_LOCKED_MESSAGE)


func _sync_hub_nav_button(instant := false) -> void:
	if host.hub_tab == null or not is_instance_valid(host.hub_tab):
		return
	var unlocked: bool = host._hub_unlocked()
	var target_modulate: Color = Color.WHITE if unlocked else host.HUB_NAV_LOCKED_MODULATE
	hub_nav_unlocked = unlocked
	host.hub_tab.tooltip_text = ""
	if host.chat_hub_tab != null and is_instance_valid(host.chat_hub_tab):
		host.chat_hub_tab.tooltip_text = ""
	if hub_nav_fade_tween != null and hub_nav_fade_tween.is_valid():
		hub_nav_fade_tween.kill()
		hub_nav_fade_tween = null
	if instant:
		host.hub_tab.modulate = target_modulate
		if host.chat_hub_tab != null and is_instance_valid(host.chat_hub_tab):
			host.chat_hub_tab.modulate = target_modulate
		_sync_nav_new_symbol_dot("hub")
		return
	hub_nav_fade_tween = host.create_tween()
	hub_nav_fade_tween.tween_property(host.hub_tab, "modulate", target_modulate, host.HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if host.chat_hub_tab != null and is_instance_valid(host.chat_hub_tab):
		hub_nav_fade_tween.parallel().tween_property(host.chat_hub_tab, "modulate", target_modulate, host.HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sync_nav_new_symbol_dot("hub")
	hub_nav_fade_tween.finished.connect(_finish_hub_nav_fade_tween)


func _finish_hub_nav_fade_tween() -> void:
	hub_nav_fade_tween = null


func _refresh_hub_nav_unlock_state() -> void:
	if host.hub_tab == null or not is_instance_valid(host.hub_tab):
		return
	var unlocked: bool = host._hub_unlocked()
	if unlocked == hub_nav_unlocked:
		return
	_sync_hub_nav_button(not unlocked)


func _show_hub_locked_message(source_button: Control = null) -> void:
	host._set_result(host.HUB_LOCKED_MESSAGE, false)
	var anchor: Control = source_button
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		anchor = host.hub_tab
	if anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree():
		_float_nav_locked_message(anchor, host.HUB_LOCKED_MESSAGE)


func _float_nav_locked_message(anchor: Control, text: String) -> void:
	if (
		anchor == null
		or not is_instance_valid(anchor)
		or anchor.is_queued_for_deletion()
		or not anchor.is_visible_in_tree()
	):
		return
	var holder_size := Vector2(430, 112)
	var holder := Control.new()
	holder.z_index = host.CHAT_UI_Z + 20
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = holder_size
	host.add_child(holder)
	var shadow: Label = host._label(text, 58, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = holder_size
	shadow.position = Vector2(4, 5)
	shadow.modulate = Color(1, 1, 1, 0.58)
	holder.add_child(shadow)
	var label: Label = host._label(text, 58, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.size = holder_size
	holder.add_child(label)
	var local_pos: Vector2 = anchor.global_position - host.global_position
	var desired_position := local_pos + Vector2(
		anchor.size.x * 0.5 - holder_size.x * 0.5,
		-holder_size.y - 8.0
	)
	var canvas_size: Vector2 = host._current_canvas_size()
	var margin := 14.0
	holder.position = Vector2(
		clampf(desired_position.x, margin, maxf(margin, canvas_size.x - holder_size.x - margin)),
		clampf(desired_position.y, margin, maxf(margin, canvas_size.y - holder_size.y - margin))
	)
	host._reward_feedback_surface()._start_reward_float_tween(holder, Vector2(0, -34), 0.0)


func _is_bottom_nav_button(button: Control) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	return button == host.hero_tab or button == host.hub_tab or button == host.skills_tab or button == host.settings_tab or button == host.shop_tab


func _bottom_nav_transition_input_locked(button: Button = null) -> bool:
	if host.bottom_nav_transition_button_id == 0:
		return false
	if not host._bottom_nav_transition_visual_active():
		host._button_press_runtime()._release_bottom_nav_transition_button()
		return false
	if button != null and is_instance_valid(button):
		host._button_press_runtime().force_button_unpressed(button)
	return true


func _arm_bottom_nav_clean_activation(button: Button, target_screen: String) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.set_meta("bottom_nav_clean_activation_target", target_screen)
	button.set_meta("bottom_nav_clean_activation_until_frame", Engine.get_process_frames() + 2)


func _consume_bottom_nav_clean_activation(button: Button, target_screen: String) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	var armed_target := str(button.get_meta("bottom_nav_clean_activation_target", ""))
	var until_frame := int(button.get_meta("bottom_nav_clean_activation_until_frame", -1))
	if button.has_meta("bottom_nav_clean_activation_target"):
		button.remove_meta("bottom_nav_clean_activation_target")
	if button.has_meta("bottom_nav_clean_activation_until_frame"):
		button.remove_meta("bottom_nav_clean_activation_until_frame")
	return armed_target == target_screen and Engine.get_process_frames() <= until_frame


func _activate_bottom_nav_target(target_screen: String, source_button: Control) -> void:
	var nav_button := source_button as Button
	if host.bottom_nav_transition_button_id != 0 and host._bottom_nav_transition_visual_active():
		if nav_button != null and is_instance_valid(nav_button):
			host._button_press_runtime().force_button_unpressed(nav_button)
		return
	if _is_bottom_nav_button(nav_button) and _bottom_nav_target_locked(target_screen):
		host._button_press_runtime().force_button_unpressed(nav_button)
		_show_bottom_nav_locked_message(target_screen, source_button)
		return
	if _is_bottom_nav_button(nav_button) and not _consume_bottom_nav_clean_activation(nav_button, target_screen):
		host._button_press_runtime().force_button_unpressed(nav_button)
		return
	host._clear_queued_skill_swipe_navigation()
	if _is_bottom_nav_button(nav_button):
		host._hold_bottom_nav_transition_button(nav_button)
		host._button_press_runtime()._schedule_bottom_nav_transition_button_idle_release()
	if _bottom_nav_open_close_returns_to_skill(target_screen, source_button):
		host.top_level_nav_locked_until_msec = 0
		host.bottom_nav_open_close_return_to_skill_active = true
		host._show_skills_module()
		host.bottom_nav_open_close_return_to_skill_active = false
		return
	if target_screen == "settings" and host.current_screen == "settings":
		host.top_level_nav_locked_until_msec = 0
		host._settings_surface()._return_from_settings_page()
		return
	match target_screen:
		"home":
			host._show_home(source_button)
		"hub":
			host._show_hub(source_button)
		"skill":
			host._show_skills_module()
		"settings":
			host._settings_surface()._show_settings()
		"shop":
			host._show_shop(source_button)


func _bottom_nav_open_close_returns_to_skill(target_screen: String, source_button: Control) -> bool:
	if target_screen == "skill" or source_button == null or not is_instance_valid(source_button):
		return false
	var nav_button := source_button as Button
	if nav_button == null or not _is_bottom_nav_button(nav_button):
		return false
	if _bottom_nav_target_for_button(nav_button) != target_screen:
		return false
	match target_screen:
		"home":
			return host.current_screen == "home" or host.current_screen == "achievements"
		"hub":
			return host.current_screen == "hub"
		"settings":
			return host.current_screen == "settings"
		"shop":
			return host.current_screen == "shop"
	return false


func _capture_page_state() -> Dictionary:
	return {
		"skill_cards": host.skill_cards,
		"action_cards": host.action_cards,
		"action_card_keys": host.action_card_keys,
		"content_scroll": host.content_scroll,
		"detail_xp_label": host.detail_xp_label,
		"detail_xp_bar": host.detail_xp_bar,
		"detail_regen_circle": host.detail_regen_circle,
		"detail_fish_circle": host.detail_fish_circle,
		"detail_blue_guy_health_gauge": host.detail_blue_guy_health_gauge,
		"detail_auto_eat_fish_button": host.detail_auto_eat_fish_button,
		"detail_stamina_bar": host.detail_stamina_bar,
		"detail_header_body": host.detail_header_body,
		"detail_header_left_block": host.detail_header_left_block,
		"detail_actions_scroll": host.detail_actions_scroll,
		"detail_actions_top_spacer": host.detail_actions_top_spacer,
		"detail_unlock_scroll_spacer": host.detail_unlock_scroll_spacer,
		"detail_shelf_shadow_overlay": host.detail_shelf_shadow_overlay,
		"detail_back_button": host.detail_back_button,
		"detail_back_press_active": host.detail_back_press_active,
		"detail_back_press_touch_index": host.detail_back_press_touch_index,
		"detail_jump_top_button": host.detail_jump_top_button,
		"detail_jump_bottom_button": host.detail_jump_bottom_button,
		"detail_jump_top_hold": host.detail_jump_top_hold,
		"detail_jump_bottom_hold": host.detail_jump_bottom_hold,
		"detail_jump_top_hovered": host.detail_jump_top_hovered,
		"detail_jump_bottom_hovered": host.detail_jump_bottom_hovered,
		"chain_audio_scroll_direction": host._audio_director().chain_audio_scroll_direction,
		"chain_audio_scroll_focus_seconds": host._audio_director().chain_audio_scroll_focus_seconds,
		"detail_action_card_nodes": host.detail_action_card_nodes,
		"detail_rendered_action_ids": host.detail_rendered_action_ids,
		"detail_lazy_plan": host.detail_lazy_plan,
		"detail_lazy_stack": host.detail_lazy_stack,
		"detail_lazy_last_scroll": host.detail_lazy_last_scroll,
		"skill_swipe_frame": host.skill_swipe_frame,
		"skill_swipe_page": host.skill_swipe_page,
		"skill_swipe_animating": host.skill_swipe_animating,
		"skill_strip_ids": host.skill_strip_ids.duplicate(),
		"skill_strip_index": host.skill_strip_index,
		"skill_strip_refs": host.skill_strip_refs.duplicate(),
		"skill_swipe_preview_state": host._skill_swipe_activity_surface()._navigation_state(),
		"settings_surface_state": host._settings_surface()._navigation_state(),
		"god_mode_controls": host.god_mode_controls,
	}


func _apply_page_state(state: Dictionary) -> void:
	host.skill_cards = state.get("skill_cards", {}) as Dictionary
	host.action_cards = state.get("action_cards", {}) as Dictionary
	host.action_card_keys = state.get("action_card_keys", []) as Array
	host._prune_invalid_action_cards()
	host.content_scroll = host._state_object_ref(state.get("content_scroll"))
	host.detail_xp_label = host._state_object_ref(state.get("detail_xp_label"))
	host.detail_xp_bar = host._state_object_ref(state.get("detail_xp_bar"))
	host.detail_regen_circle = host._state_object_ref(state.get("detail_regen_circle"))
	host.detail_fish_circle = host._state_object_ref(state.get("detail_fish_circle"))
	host.detail_blue_guy_health_gauge = host._state_object_ref(state.get("detail_blue_guy_health_gauge"))
	host.detail_auto_eat_fish_button = host._state_object_ref(state.get("detail_auto_eat_fish_button"))
	host.detail_stamina_bar = host._state_object_ref(state.get("detail_stamina_bar"))
	host.detail_header_body = host._state_object_ref(state.get("detail_header_body"))
	host.detail_header_left_block = host._state_object_ref(state.get("detail_header_left_block"))
	host.detail_actions_scroll = host._state_object_ref(state.get("detail_actions_scroll"))
	host.detail_actions_top_spacer = host._state_object_ref(state.get("detail_actions_top_spacer"))
	host.detail_unlock_scroll_spacer = host._state_object_ref(state.get("detail_unlock_scroll_spacer"))
	host.detail_shelf_shadow_overlay = host._state_object_ref(state.get("detail_shelf_shadow_overlay"))
	host.detail_back_button = host._state_object_ref(state.get("detail_back_button"))
	host.detail_back_press_active = bool(state.get("detail_back_press_active", false))
	host.detail_back_press_touch_index = int(state.get("detail_back_press_touch_index", -1))
	host.detail_jump_top_button = host._state_object_ref(state.get("detail_jump_top_button"))
	host.detail_jump_bottom_button = host._state_object_ref(state.get("detail_jump_bottom_button"))
	host.detail_jump_top_hold = float(state.get("detail_jump_top_hold", 0.0))
	host.detail_jump_bottom_hold = float(state.get("detail_jump_bottom_hold", 0.0))
	host.detail_jump_top_hovered = bool(state.get("detail_jump_top_hovered", false))
	host.detail_jump_bottom_hovered = bool(state.get("detail_jump_bottom_hovered", false))
	host._audio_director().chain_audio_scroll_direction = int(state.get("chain_audio_scroll_direction", 0))
	host._audio_director().chain_audio_scroll_focus_seconds = float(state.get("chain_audio_scroll_focus_seconds", 0.0))
	host.detail_action_card_nodes = state.get("detail_action_card_nodes", {}) as Dictionary
	host.detail_rendered_action_ids = state.get("detail_rendered_action_ids", []) as Array
	host.detail_lazy_plan = state.get("detail_lazy_plan", []) as Array
	host.detail_lazy_stack = host._state_object_ref(state.get("detail_lazy_stack"))
	host.detail_lazy_last_scroll = float(state.get("detail_lazy_last_scroll", -1.0))
	host.skill_swipe_frame = host._state_object_ref(state.get("skill_swipe_frame"))
	host.skill_swipe_page = host._state_object_ref(state.get("skill_swipe_page"))
	host.skill_swipe_animating = bool(state.get("skill_swipe_animating", false))
	host.skill_strip_ids = state.get("skill_strip_ids", []) as Array
	host.skill_strip_index = int(state.get("skill_strip_index", 0))
	host.skill_strip_refs = state.get("skill_strip_refs", {}) as Dictionary
	host._skill_swipe_activity_surface()._apply_navigation_state(state.get("skill_swipe_preview_state", {}) as Dictionary)
	host._settings_surface()._apply_navigation_state(state.get("settings_surface_state", {}) as Dictionary)
	host.god_mode_controls = state.get("god_mode_controls", []) as Array


func _reset_page_control_refs() -> void:
	host.skill_cards.clear()
	host.skill_menu_active_drawers.clear()
	host._clear_detail_lazy_cache_bin()
	host._clear_action_pop_tweens()
	host._reward_feedback_surface()._clear_action_crit_tweens()
	host._clear_stamina_gauge_pop_tween()
	host._clear_activity_unlock_visual_scroll_tween()
	host.action_cards.clear()
	host.action_card_keys.clear()
	host.content_scroll = null
	host.detail_xp_label = null
	host.detail_xp_bar = null
	host.detail_regen_circle = null
	host.detail_regen_circle_host = null
	host.detail_regen_circle_fade_group = null
	host.detail_fish_circle = null
	host.detail_blue_guy_health_gauge = null
	host.detail_auto_eat_fish_button = null
	host.pinned_active_shelf_header = null
	host.pinned_active_shelf_background = null
	host.pinned_active_shelf_skill_id = ""
	host.pinned_active_shelf_transition_skill_id = ""
	host.pinned_active_shelf_transition_active = false
	host.pinned_active_shelf_content = null
	host.pinned_active_shelf_stamina_strip = null
	host.pinned_active_shelf_stamina_gauges.clear()
	host.pinned_active_shelf_xp_label = null
	host.pinned_active_shelf_xp_bar = null
	host.pinned_active_shelf_regen_circle = null
	host.pinned_active_shelf_fish_circle = null
	if host.pinned_active_shelf_tween != null and host.pinned_active_shelf_tween.is_valid():
		host.pinned_active_shelf_tween.kill()
	host.pinned_active_shelf_tween = null
	if host.pinned_active_shelf_height_tween != null and host.pinned_active_shelf_height_tween.is_valid():
		host.pinned_active_shelf_height_tween.kill()
	host.pinned_active_shelf_height_tween = null
	host.detail_stamina_bar = null
	host.detail_header_body = null
	host.detail_header_left_block = null
	host.detail_actions_scroll = null
	host.detail_actions_top_spacer = null
	if host.onboarding_first_module_spacer_tween != null and host.onboarding_first_module_spacer_tween.is_valid():
		host.onboarding_first_module_spacer_tween.kill()
	host.onboarding_first_module_spacer_tween = null
	host.detail_unlock_scroll_spacer = null
	host.detail_shelf_shadow_overlay = null
	host.detail_back_button = null
	host.detail_back_press_active = false
	host.detail_back_press_touch_index = -1
	host._skill_detail_surface()._clear_detail_jump_arrow_state()
	host._audio_director().chain_audio_scroll_direction = 0
	host._audio_director().chain_audio_scroll_focus_seconds = 0.0
	host.detail_action_card_nodes.clear()
	host.detail_rendered_action_ids.clear()
	host.detail_lazy_plan.clear()
	host.detail_lazy_last_scroll = -1.0
	host.detail_lazy_stack = null
	host.detail_lazy_refresh_token += 1
	host._skill_detail_surface()._cancel_detail_card_texture_prewarm()
	host.activity_start_highlight_token += 1
	host.activity_start_highlight_pending = false
	host.activity_start_highlight_active = false
	if host.activity_start_highlight_fade_tween != null:
		host.activity_start_highlight_fade_tween.kill()
	host.activity_start_highlight_fade_tween = null
	host.activity_start_highlight_border = null
	host.activity_start_highlight_card_key = ""
	host._restore_activity_start_highlight_frame_clip()
	host.skill_swipe_frame = null
	host.skill_swipe_page = null
	host.skill_swipe_drag_offset_x = 0.0
	host.skill_swipe_gap_render_offset_x = 0.0
	host.skill_swipe_animating = false
	host.skill_strip_ids.clear()
	host.skill_strip_index = 0
	host.skill_strip_refs.clear()
	host._skill_swipe_activity_surface()._clear_skill_swipe_preview()
	host._hub_surface()._clear_hub_page_control_refs()
	host._settings_surface()._clear_settings_page_control_refs()


func _screen_page_cache_key(screen: String) -> String:
	if screen == "skill":
		return "skill:%s" % host.selected_skill_id
	return screen


func _skill_detail_cache_key(skill_id: String = "") -> String:
	var id: String = skill_id if not skill_id.is_empty() else host.selected_skill_id
	return "skill:%s" % id


func _render_screen(scroll_latest_activity := false, restore_detail_scroll := -1, boot_async := false):
	host.module_ui_refresh_token += 1
	host.detail_lazy_refresh_token += 1
	var requested_key: String = _screen_page_cache_key(host.current_screen)
	if host.screen_render_in_progress:
		if requested_key != host.screen_render_target_key:
			host._store_pending_screen_render_request(scroll_latest_activity, restore_detail_scroll, boot_async, requested_key)
		return
	host.screen_render_in_progress = true
	host.screen_render_target_key = requested_key
	if host.skills_content == null:
		host._finish_screen_render_request()
		return
	if host.current_screen == "skill" and host._skill_swipe_navigation_blocks_detail_refresh():
		host._finish_screen_render_request()
		return
	var target_key: String = requested_key
	if host.current_screen == "skill" and host._try_reveal_current_skill_page(target_key, scroll_latest_activity):
		host._finish_screen_render_request()
		return
	host.skill_swipe_animating = false
	host.skill_swipe_animation_mode = ""
	host._kill_skill_swipe_tween()
	host._clear_page_transient_input_state()
	if host.current_screen != "skill":
		host._reward_feedback_surface()._clear_skill_reward_floats()
		host._cancel_activity_unlock_transients_for_navigation()
	host._prepare_skills_page_transition(target_key)
	if host.current_screen != "settings":
		host._settings_surface()._clear_settings_page_control_refs()
	host._hub_surface()._kill_hub_detail_motion_tween()
	host._kill_transient_tweens_in_subtree(host.skills_content)
	host._apply_skills_content_layout_for_screen()
	host._skill_swipe_activity_surface()._clear_skill_swipe_preview()
	host.skill_swipe_frame = null
	host.skill_swipe_page = null
	_reset_page_control_refs()
	host._clear_skills_content_orphans()
	if host.current_screen == "skill":
		await host._skill_detail_surface()._render_skill_detail(scroll_latest_activity, restore_detail_scroll, boot_async)
	elif host.current_screen == "pinned":
		_render_pinned_activities_page()
	elif host.current_screen == "queue":
		host._skill_swipe_activity_surface()._render_activity_queue_page()
	elif host.current_screen == "leaderboard":
		host._leaderboard_presentation()._render_leaderboard_page()
	elif host.current_screen == "hub":
		host._hub_surface()._render_hub_page()
	elif host.current_screen == "settings":
		host._settings_surface().render_page()
	elif host.current_screen == "shop":
		host._shop_surface().render_page()
	elif host.current_screen == "achievements":
		host._achievement_overlay_surface()._render_achievements_page()
	else:
		_render_skill_menu_shelf()
		_render_skill_menu_page()
	host._finish_render_screen_transition(target_key)
	host._finish_screen_render_request()


func _page_switch_pending_transition_queued() -> bool:
	return not page_switch_pending_transition.is_empty()


func _page_switch_render_cover_transition_waiting() -> bool:
	return not page_switch_pending_transition.is_empty() or page_switch_release_when_render_idle


func _page_switch_transition_active() -> bool:
	return (
		_page_switch_scroll_cover_active()
		or not page_switch_pending_transition.is_empty()
		or page_switch_release_when_render_idle
	)


func _clear_page_switch_render_cover_transition_state() -> void:
	page_switch_pending_transition.clear()
	page_switch_release_when_render_idle = false


func _recover_stale_page_switch_transition() -> void:
	if page_switch_pending_transition.is_empty():
		return
	var cover_id := int(page_switch_pending_transition.get("cover_id", 0))
	if _page_switch_cover_id_active(cover_id):
		return
	_clear_page_switch_render_cover_transition_state()
	_release_page_switch_transition_button()


func _begin_page_switch_scroll_cover(include_bottom_interactive_ui := false) -> void:
	if _page_switch_scroll_cover_active():
		return
	host._clear_skill_swipe_handoff_cover_immediate()
	var cover := Control.new()
	host._apply_skill_page_cover_bounds(cover, include_bottom_interactive_ui)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	cover.modulate = Color(1.0, 1.0, 1.0, 0.0)
	cover.set_meta("swipe_cream_transition_cover", true)
	cover.set_meta("page_switch_scroll_cover", true)
	cover.set_meta("page_switch_scroll_cover_started_msec", Time.get_ticks_msec())
	cover.set_meta("page_switch_scroll_cover_includes_bottom_interactive_ui", include_bottom_interactive_ui)
	host._ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = host._theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.add_child(backing)

	host.skill_swipe_handoff_cover = cover
	_start_page_switch_scroll_cover_fade_in(cover)


func _start_page_switch_scroll_cover_fade_in(cover: Control) -> void:
	if cover == null or not is_instance_valid(cover):
		return
	host._kill_skill_swipe_cover_fade_tween()
	host.skill_swipe_cover_fade_tween = host.create_tween()
	host.skill_swipe_cover_fade_tween.tween_property(
		cover,
		"modulate:a",
		1.0,
		host.PAGE_SWITCH_SCROLL_COVER_FADE_IN_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	host.skill_swipe_cover_fade_tween.tween_callback(Callable(host, "_finish_skill_nav_cover_fade_in").bind(cover.get_instance_id()))


func _begin_page_switch_scroll_cover_timed(include_bottom_interactive_ui := false) -> int:
	_begin_page_switch_scroll_cover(include_bottom_interactive_ui)
	var cover: Control = host.skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return 0
	if not bool(cover.get_meta("page_switch_scroll_cover", false)):
		return 0
	var cover_id := cover.get_instance_id()
	host.get_tree().create_timer(host.PAGE_SWITCH_SCROLL_COVER_FADE_IN_SECONDS, true, false, true).timeout.connect(
		_force_page_switch_scroll_cover_opaque.bind(cover_id)
	)
	return cover_id


func _page_switch_cover_id_active(cover_id: int) -> bool:
	return _active_page_switch_cover_ref(cover_id) != null


func _active_page_switch_cover_ref(cover_id: int) -> Control:
	var cover: Control = host._valid_control_ref(instance_from_id(cover_id))
	if cover == null or cover != host.skill_swipe_handoff_cover:
		return null
	if not bool(cover.get_meta("page_switch_scroll_cover", false)):
		return null
	return cover


func _force_page_switch_scroll_cover_opaque(cover_id: int) -> void:
	var cover := _active_page_switch_cover_ref(cover_id)
	if cover == null:
		return
	host._set_canvas_item_modulate_if_changed(cover, Color.WHITE)


func _fade_clear_page_switch_scroll_cover() -> void:
	var cover: Control = host.skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover) or not bool(cover.get_meta("page_switch_scroll_cover", false)):
		if not _page_switch_render_cover_transition_waiting():
			_release_page_switch_transition_button()
		return
	var started_msec := int(cover.get_meta("page_switch_scroll_cover_started_msec", Time.get_ticks_msec()))
	var elapsed_seconds := float(maxi(0, Time.get_ticks_msec() - started_msec)) / 1000.0
	var remaining_seconds: float = host.PAGE_SWITCH_SCROLL_COVER_HOLD_SECONDS - elapsed_seconds
	if bool(cover.get_meta("page_switch_scroll_cover_release_pending", false)):
		if remaining_seconds > 0.0:
			return
		cover.remove_meta("page_switch_scroll_cover_release_pending")
	if remaining_seconds > 0.0:
		cover.set_meta("page_switch_scroll_cover_release_pending", true)
		call_deferred("_fade_clear_page_switch_scroll_cover_after_delay", remaining_seconds)
		return
	host._fade_clear_skill_swipe_cover(host.PAGE_SWITCH_SCROLL_COVER_FADE_SECONDS)


func _fade_clear_page_switch_scroll_cover_after_delay(delay_seconds: float) -> void:
	await host.get_tree().create_timer(maxf(0.01, delay_seconds), true, false, true).timeout
	var cover: Control = host.skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover) or not bool(cover.get_meta("page_switch_scroll_cover", false)):
		return
	cover.remove_meta("page_switch_scroll_cover_release_pending")
	_fade_clear_page_switch_scroll_cover()


func _page_switch_scroll_cover_active() -> bool:
	return (
		host.skill_swipe_handoff_cover != null
		and is_instance_valid(host.skill_swipe_handoff_cover)
		and bool(host.skill_swipe_handoff_cover.get_meta("page_switch_scroll_cover", false))
	)


func _build_page_switch_module(skill_id: String, content_width: float) -> Control:
	var neighbors: Dictionary = host._skill_swipe_activity_surface()._skill_page_neighbor_ids(skill_id)
	var previous_skill := str(neighbors.get("previous", ""))
	var next_skill := str(neighbors.get("next", ""))
	if previous_skill.is_empty() or next_skill.is_empty():
		return null
	var module := Control.new()
	module.name = "PageSwitchModule"
	module.custom_minimum_size = Vector2(content_width, PAGE_SWITCH_MODULE_HEIGHT)
	module.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	module.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 118)
	margin.add_theme_constant_override("margin_right", 118)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 18)
	module.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var previous_button := _page_switch_button(previous_skill, "right")
	previous_button.set_meta("page_switch_owner_skill_id", skill_id)
	row.add_child(previous_button)
	var next_button := _page_switch_button(next_skill, "left")
	next_button.set_meta("page_switch_owner_skill_id", skill_id)
	row.add_child(next_button)
	return module


func _page_switch_button(skill_id: String, diagonal_side := "") -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = ""
	button.custom_minimum_size = Vector2(0, PAGE_SWITCH_MODULE_HEIGHT - 28)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_contents = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_meta("page_switch_target_skill_id", skill_id)
	button.add_to_group("page_switch_buttons")
	button.gui_input.connect(Callable(self, "_on_page_switch_button_gui_input").bind(skill_id, button))
	button.pressed.connect(Callable(self, "_on_page_switch_button_pressed").bind(skill_id, button))
	var theme: Color = host._skill_theme_color(skill_id)
	var activity_surface = host._skill_swipe_activity_surface()
	var pop: Control = activity_surface._install_activity_button_shell(button, theme, host.ACTION_CARD_FACE_RADIUS, host.ACTION_CARD_POP_GUTTER, host.ACTION_CARD_3D_DEPTH_OFFSET, diagonal_side)
	if diagonal_side == "right" or diagonal_side == "left":
		_add_page_switch_skill_icon(pop, skill_id, diagonal_side)
		_add_page_switch_outline_overlay(pop, diagonal_side)
		var chevron := PageSwitchChevronIcon.new()
		chevron.name = "PageSwitchChevronIcon"
		chevron.set_direction(-1 if diagonal_side == "right" else 1)
		chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chevron.z_index = 250
		chevron.anchor_top = 0.0
		chevron.anchor_bottom = 1.0
		chevron.offset_top = 18.0
		chevron.offset_bottom = -46.0
		if diagonal_side == "right":
			chevron.anchor_left = 0.0
			chevron.anchor_right = 0.0
			chevron.offset_left = 52.0
			chevron.offset_right = 206.0
		else:
			chevron.anchor_left = 1.0
			chevron.anchor_right = 1.0
			chevron.offset_left = -206.0
			chevron.offset_right = -52.0
		pop.add_child(chevron)
	activity_surface._attach_activity_button_press_animation(button)
	return button


func _clear_page_switch_press_state() -> void:
	page_switch_press_active = false
	page_switch_press_target_skill_id = ""
	page_switch_press_position = Vector2.ZERO
	page_switch_press_dragged = false


func _clear_page_switch_input_state(clear_transition := false) -> void:
	_clear_page_switch_press_state()
	var tree: SceneTree = host.get_tree()
	if tree != null:
		for raw_node in tree.get_nodes_in_group("page_switch_buttons"):
			var button := raw_node as Button
			if button != null and is_instance_valid(button):
				_clear_page_switch_button_press_state(button)
				host._button_press_runtime().force_button_unpressed(button)
	if clear_transition:
		_clear_page_switch_render_cover_transition_state()
		_release_page_switch_transition_button()
		if _page_switch_scroll_cover_active():
			host._clear_skill_swipe_handoff_cover_immediate()


func _recover_stale_page_switch_input_lock() -> void:
	if page_switch_press_active and _active_page_switch_button() == null:
		_clear_page_switch_press_state()
	if page_switch_transition_button_id != 0:
		var button: Button = host._valid_button_ref(instance_from_id(page_switch_transition_button_id))
		if button == null or not button.is_inside_tree():
			_clear_page_switch_input_state(true)
	_recover_stale_page_switch_transition()


func _clear_page_switch_button_press_state(button: Button, keep_nav_hold := false) -> void:
	if button == null or not is_instance_valid(button):
		return
	if button.has_meta("page_switch_press_active"):
		button.remove_meta("page_switch_press_active")
	if button.has_meta("page_switch_press_position"):
		button.remove_meta("page_switch_press_position")
	if button.has_meta("page_switch_press_dragged"):
		button.remove_meta("page_switch_press_dragged")
	if keep_nav_hold:
		return
	if button.has_meta("activity_button_hold_nav_press"):
		button.remove_meta("activity_button_hold_nav_press")
	if button.has_meta("activity_button_hold_nav_target_active"):
		button.remove_meta("activity_button_hold_nav_target_active")


func _suppress_page_switch_pressed_signal(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.set_meta("page_switch_suppress_pressed_signal_until_frame", Engine.get_process_frames() + 2)


func _page_switch_pressed_signal_suppressed(button: Button) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	if not button.has_meta("page_switch_suppress_pressed_signal_until_frame"):
		return false
	var until_frame := int(button.get_meta("page_switch_suppress_pressed_signal_until_frame", 0))
	if Engine.get_process_frames() <= until_frame:
		return true
	button.remove_meta("page_switch_suppress_pressed_signal_until_frame")
	return false


func _active_page_switch_button() -> Button:
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return null
	for raw_node in tree.get_nodes_in_group("page_switch_buttons"):
		var button := raw_node as Button
		if (
			button != null
			and is_instance_valid(button)
			and _page_switch_button_belongs_to_current_page(button)
			and bool(button.get_meta("page_switch_press_active", false))
		):
			return button
	return null


func _page_switch_button_belongs_to_current_page(button: Button) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	var owner_skill_id := str(button.get_meta("page_switch_owner_skill_id", ""))
	return owner_skill_id.is_empty() or owner_skill_id == host.selected_skill_id


func _on_page_switch_button_gui_input(event: InputEvent, skill_id: String, button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if not _page_switch_button_belongs_to_current_page(button):
		return
	var event_position: Vector2 = host._passive_button_event_position(event, button)
	var is_press := false
	var is_release := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventScreenTouch:
		is_press = (event as InputEventScreenTouch).pressed
		is_release = not (event as InputEventScreenTouch).pressed
	if is_press and not host._input_routing_shell()._action_card_at_position(event_position).is_empty():
		return
	if _page_switch_input_locked() and not bool(button.get_meta("page_switch_press_active", false)):
		return
	if is_press:
		button.set_meta("page_switch_press_active", true)
		button.set_meta("page_switch_press_position", event_position)
		button.set_meta("page_switch_press_dragged", false)
		button.set_meta("activity_button_hold_nav_press", true)
		button.set_meta("activity_button_hold_nav_target_active", true)
		host._button_press_runtime().play_default_button_sfx()
		_press_page_switch_button_shell(button)
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if bool(button.get_meta("page_switch_press_active", false)):
			var press_position: Vector2 = host._meta_vector2(button, "page_switch_press_position", event_position)
			if event_position.distance_to(press_position) > host.PASSIVE_BUTTON_TAP_RELEASE_SLOP:
				button.set_meta("page_switch_press_dragged", true)
		return
	if not is_release:
		return
	var was_active := bool(button.get_meta("page_switch_press_active", false))
	var was_dragged := bool(button.get_meta("page_switch_press_dragged", false))
	var press_position: Vector2 = host._meta_vector2(button, "page_switch_press_position", event_position)
	if button.has_meta("page_switch_press_active"):
		button.remove_meta("page_switch_press_active")
	if button.has_meta("page_switch_press_position"):
		button.remove_meta("page_switch_press_position")
	if button.has_meta("page_switch_press_dragged"):
		button.remove_meta("page_switch_press_dragged")
	var valid_tap: bool = (
		was_active
		and not was_dragged
		and event_position.distance_to(press_position) <= host.PASSIVE_BUTTON_TAP_RELEASE_SLOP
	)
	if not valid_tap:
		if button.has_meta("activity_button_hold_nav_press"):
			button.remove_meta("activity_button_hold_nav_press")
		if button.has_meta("activity_button_hold_nav_target_active"):
			button.remove_meta("activity_button_hold_nav_target_active")
		_release_page_switch_button_shell(button)
		return
	_clear_page_switch_button_press_state(button, true)
	_suppress_page_switch_pressed_signal(button)
	host._select_skill_from_page_switch(skill_id, button)


func _on_page_switch_button_pressed(skill_id: String, button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if host.current_screen != "skill":
		return
	if not _page_switch_button_belongs_to_current_page(button):
		return
	if _page_switch_pressed_signal_suppressed(button):
		return
	host._button_press_runtime().force_button_unpressed(button)


func _page_switch_input_locked() -> bool:
	return page_switch_transition_button_id != 0 or _page_switch_transition_active()


func _hold_page_switch_transition_button(button: Button, target_skill_id: String) -> void:
	if button == null or not is_instance_valid(button):
		return
	if page_switch_transition_button_id != 0:
		return
	page_switch_transition_button_id = button.get_instance_id()
	page_switch_transition_target_skill_id = target_skill_id
	button.set_meta("page_switch_transition_hold", true)
	button.set_meta("activity_button_hold_nav_press", true)
	button.set_meta("activity_button_hold_nav_target_active", true)
	_press_page_switch_button_shell(button)


func _release_page_switch_transition_button() -> void:
	var button_id := page_switch_transition_button_id
	page_switch_transition_button_id = 0
	page_switch_transition_target_skill_id = ""
	if button_id == 0:
		return
	var button: Button = host._valid_button_ref(instance_from_id(button_id))
	if button == null:
		return
	if button.has_meta("page_switch_transition_hold"):
		button.remove_meta("page_switch_transition_hold")
	if button.has_meta("activity_button_hold_nav_press"):
		button.remove_meta("activity_button_hold_nav_press")
	if button.has_meta("activity_button_hold_nav_target_active"):
		button.remove_meta("activity_button_hold_nav_target_active")
	_clear_page_switch_button_press_state(button)
	host._button_press_runtime().force_button_unpressed(button)
	host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button_id, true)


func _release_page_switch_transition_button_visual_hold() -> void:
	var button_id := page_switch_transition_button_id
	if button_id == 0:
		return
	var button: Button = host._valid_button_ref(instance_from_id(button_id))
	if button == null:
		return
	if _page_switch_scroll_cover_active():
		if button.has_meta("activity_button_hold_nav_press"):
			button.remove_meta("activity_button_hold_nav_press")
		if button.has_meta("activity_button_hold_nav_target_active"):
			button.remove_meta("activity_button_hold_nav_target_active")
		_clear_page_switch_button_press_state(button, false)
		host._button_press_runtime().force_button_unpressed(button)
		host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button_id, true)
		return
	if button.has_meta("activity_button_hold_nav_press"):
		button.remove_meta("activity_button_hold_nav_press")
	if button.has_meta("activity_button_hold_nav_target_active"):
		button.remove_meta("activity_button_hold_nav_target_active")
	_clear_page_switch_button_press_state(button, false)
	host._button_press_runtime().force_button_unpressed(button)
	host.depressed_activity_shell_buttons.erase(button_id)
	var pop := host._valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop != null:
		host._skill_swipe_activity_surface()._kill_activity_button_shell_tween(button)
		host._skill_swipe_activity_surface()._set_activity_button_pop_depth_offset_bound(Vector2.ZERO, pop.get_instance_id())
	host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button_id, true)


func _press_page_switch_button_shell(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var button_id := button.get_instance_id()
	if host.depressed_activity_shell_buttons.has(button_id):
		return
	host._skill_swipe_activity_surface()._press_activity_button_shell_bound(button_id)


func _page_switch_button_shell_release_preserved(button: Button) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	if not button.is_in_group("page_switch_buttons"):
		return false
	if bool(button.get_meta("page_switch_transition_hold", false)):
		return true
	if bool(button.get_meta("page_switch_press_active", false)):
		return true
	return page_switch_transition_button_id == button.get_instance_id()


func _release_page_switch_button_shell(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var button_id := button.get_instance_id()
	if not host.depressed_activity_shell_buttons.has(button_id):
		return
	host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button_id)


func _add_page_switch_skill_icon(parent: Control, skill_id: String, diagonal_side: String) -> void:
	parent.clip_contents = true
	var icon_center := _page_switch_skill_icon_center(diagonal_side)
	var icon := _page_switch_skill_symbol(skill_id, diagonal_side)
	icon.name = "PageSwitchSkillIcon"
	icon.z_index = 170
	icon.modulate = Color(1, 1, 1, 0.96)
	icon.anchor_top = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_top = icon_center.y - PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.y * 0.5
	icon.offset_bottom = icon_center.y + PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.y * 0.5
	if diagonal_side == "right":
		icon.anchor_left = 1.0
		icon.anchor_right = 1.0
	else:
		icon.anchor_left = 0.0
		icon.anchor_right = 0.0
	icon.offset_left = icon_center.x - PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.x * 0.5
	icon.offset_right = icon_center.x + PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.x * 0.5
	parent.add_child(icon)


func _add_page_switch_outline_overlay(parent: Control, diagonal_side: String) -> void:
	var outline := PageSwitchButtonFace.new()
	outline.name = "PageSwitchOutlineOverlay"
	outline.side = diagonal_side
	outline.fill_color = Color.TRANSPARENT
	outline.ink_color = host.COLOR_INK
	outline.radius = host.ACTION_CARD_FACE_RADIUS
	outline.stroke_width = 12.0
	outline.draw_fill = false
	outline.draw_stroke = true
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outline.z_index = 240
	var button_root := parent.get_parent() as Control
	if button_root != null:
		outline.anchor_left = 0.0
		outline.anchor_right = 1.0
		outline.anchor_top = 0.0
		outline.anchor_bottom = 1.0
		outline.offset_left = host.ACTION_CARD_POP_GUTTER
		outline.offset_right = -host.ACTION_CARD_POP_GUTTER
		outline.offset_top = 0.0
		outline.offset_bottom = -host.ACTION_CARD_3D_DEPTH_OFFSET.y
		button_root.add_child(outline)
		parent.set_meta("activity_card_outline_node_id", outline.get_instance_id())
	else:
		outline.set_anchors_preset(Control.PRESET_FULL_RECT)
		parent.add_child(outline)


func _page_switch_skill_symbol(skill_id: String, diagonal_side: String) -> Control:
	var stage := Control.new()
	stage.custom_minimum_size = PAGE_SWITCH_SKILL_ICON_STAGE_SIZE
	stage.size = PAGE_SWITCH_SKILL_ICON_STAGE_SIZE
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.clip_contents = false

	var symbol_size: Vector2 = SkillIconBadge.symbol_size(skill_id, _page_switch_skill_symbol_base_size(skill_id, diagonal_side))
	var symbol: Control
	if skill_id == "fishing":
		var drawn_symbol := SkillIconSymbolDraw.new()
		drawn_symbol.texture = host.visual_texture_cache._texture_or_visual_fallback(host._skill_icon_path(skill_id))
		symbol = drawn_symbol
	else:
		var texture_symbol := TextureRect.new()
		texture_symbol.texture = host.visual_texture_cache._texture_or_visual_fallback(host._skill_icon_path(skill_id))
		texture_symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		symbol = texture_symbol
	symbol.name = "PageSwitchSkillIconSymbol"
	symbol.custom_minimum_size = symbol_size
	symbol.size = symbol_size
	symbol.position = SkillIconBadge.symbol_position(skill_id, PAGE_SWITCH_SKILL_ICON_STAGE_SIZE, symbol_size, host.SKILL_MENU_ICON_BADGE_SIZE) + _page_switch_skill_symbol_focus_offset(skill_id, diagonal_side)
	symbol.pivot_offset = symbol_size * 0.5
	symbol.rotation = SkillIconBadge.symbol_rotation(skill_id)
	symbol.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(symbol)
	return stage


func _page_switch_skill_icon_center(diagonal_side: String) -> Vector2:
	var center_x := PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.x * 0.5 - PAGE_SWITCH_SKILL_ICON_EDGE_CROP
	if diagonal_side == "right":
		center_x = -center_x
	return Vector2(center_x, PAGE_SWITCH_SKILL_ICON_VERTICAL_SHIFT)


func _page_switch_skill_symbol_base_size(skill_id: String, diagonal_side: String) -> Vector2:
	match skill_id:
		"fight":
			if diagonal_side == "right":
				return Vector2(392, 392)
			return Vector2(386, 386)
		_:
			return PAGE_SWITCH_SKILL_ICON_SYMBOL_BASE_SIZE


func _page_switch_skill_symbol_focus_offset(skill_id: String, diagonal_side: String) -> Vector2:
	match skill_id:
		"build":
			if diagonal_side == "right":
				return Vector2(-74, 42)
			return Vector2(112, 42)
		"woodcutting":
			if diagonal_side == "right":
				return Vector2(-80, 34)
			return Vector2(70, 34)
		"fishing":
			if diagonal_side == "right":
				return Vector2(-190, -8)
			return Vector2(104, -8)
		"thieving":
			if diagonal_side == "left":
				return Vector2(168, 8)
			return Vector2(-70, 8)
		"fight":
			if diagonal_side == "left":
				return Vector2(132, -36)
			return Vector2(-136, -36)
		_:
			return Vector2.ZERO


func _queue_page_switch_transition(kind: String, cover_id: int, payload := {}) -> void:
	if cover_id == 0:
		return
	page_switch_pending_transition = {
		"kind": kind,
		"cover_id": cover_id,
		"payload": payload,
	}
	page_switch_release_when_render_idle = false
	_release_page_switch_transition_button_visual_hold()


func _process_page_switch_pending_transition() -> void:
	if page_switch_release_when_render_idle:
		if host.screen_render_in_progress or not host.pending_screen_render_request.is_empty():
			return
		page_switch_release_when_render_idle = false
		_fade_clear_page_switch_scroll_cover()
		return
	if page_switch_pending_transition.is_empty():
		return
	var cover_id := int(page_switch_pending_transition.get("cover_id", 0))
	if not _page_switch_cover_id_active(cover_id):
		_clear_page_switch_render_cover_transition_state()
		_release_page_switch_transition_button()
		return
	var cover: Control = _active_page_switch_cover_ref(cover_id)
	if cover == null or not cover.visible:
		return
	if cover.modulate.a < 0.98:
		return
	if host.screen_render_in_progress or not host.pending_screen_render_request.is_empty():
		return
	_force_page_switch_scroll_cover_opaque(cover_id)
	var transition := page_switch_pending_transition
	page_switch_pending_transition = {}
	_start_page_switch_render_under_cover(str(transition.get("kind", "")), transition.get("payload", {}) as Dictionary)


func _start_page_switch_render_under_cover(kind: String, payload: Dictionary) -> void:
	match kind:
		"show_skills":
			_start_show_skills_under_page_switch_cover()
		"return_skills_utility":
			_start_return_from_skills_utility_under_page_switch_cover(str(payload.get("target_screen", "skill")))
		"show_pinned":
			_start_show_pinned_activities_under_page_switch_cover()
		"return_pinned":
			_start_return_from_pinned_activities_under_page_switch_cover(
				str(payload.get("target_screen", "skill")),
				int(payload.get("restore_scroll", -1))
			)
		"select_skill":
			_start_select_skill_under_page_switch_cover(
				str(payload.get("skill_id", "")),
				bool(payload.get("scroll_latest_activity", false)),
				int(payload.get("restore_detail_scroll", host.DETAIL_RESTORE_SCROLL_BOTTOM)),
				bool(payload.get("play_nav_sfx", false))
			)
		_:
			_fade_clear_page_switch_scroll_cover()


func _mark_page_switch_release_after_render() -> void:
	page_switch_release_when_render_idle = true


func _start_show_skills_under_page_switch_cover() -> void:
	host.current_screen = "menu"
	host._render_screen()
	_mark_page_switch_release_after_render()


func _start_return_from_skills_utility_under_page_switch_cover(target_screen: String) -> void:
	host.current_screen = target_screen
	host._render_screen()
	_mark_page_switch_release_after_render()


func _start_show_pinned_activities_under_page_switch_cover() -> void:
	host.current_screen = "pinned"
	host._render_screen()
	_mark_page_switch_release_after_render()


func _start_return_from_pinned_activities_under_page_switch_cover(target_screen: String, restore_scroll: int) -> void:
	host.current_screen = target_screen
	host._render_screen(false, restore_scroll)
	_mark_page_switch_release_after_render()


func _start_select_skill_under_page_switch_cover(skill_id: String, scroll_latest_activity: bool, restore_detail_scroll: int, play_nav_sfx := true) -> void:
	if skill_id.is_empty():
		_fade_clear_page_switch_scroll_cover()
		return
	if not host._onboarding_runtime()._onboarding_skill_accessible(skill_id):
		var card := host.skill_cards.get(skill_id, {}) as Dictionary
		var source := card.get("button") as Control
		host._onboarding_runtime()._show_onboarding_skill_locked_message(source)
		_fade_clear_page_switch_scroll_cover()
		return
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	if skill_id != host.selected_skill_id and host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		host._onboarding_runtime()._clear_tutorial_gate_latch_only_after_skill_swipe(false)
	host.selected_skill_id = skill_id
	host.current_screen = "skill"
	host._clear_skill_swipe_button_suppression()
	if play_nav_sfx:
		host._button_press_runtime().play_default_button_sfx()
	if host.tutorial_active:
		host.action_cards.clear()
		host.action_card_keys.clear()
		host.detail_action_card_nodes.clear()
		host.detail_rendered_action_ids.clear()
		host.detail_lazy_plan.clear()
		host._render_screen(false, 0)
	else:
		host._render_screen(scroll_latest_activity, restore_detail_scroll)
	_mark_page_switch_release_after_render()


func _render_skill_menu_page() -> void:
	host.content_scroll = MobileScrollContainer.new()
	host.content_scroll.clip_contents = true
	host.content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.content_scroll.set_pull_resistance_enabled(true)
	host.content_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.content_scroll.offset_left = 0.0
	host.content_scroll.offset_right = 0.0
	host.content_scroll.offset_bottom = 0.0
	host.skills_content.add_child(host.content_scroll)
	host.content_scroll.offset_top = host.SKILL_MENU_SHELF_HEIGHT
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = _skill_menu_active_drawer_content_width()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 52)
	host.content_scroll.add_child(stack)
	_render_skill_menu(stack)


func _render_skill_menu_shelf() -> void:
	var shelf := ColorRect.new()
	shelf.color = host._theme_paper_color()
	shelf.anchor_left = 0.0
	shelf.anchor_right = 1.0
	shelf.anchor_top = 0.0
	shelf.anchor_bottom = 0.0
	shelf.offset_left = 0.0
	shelf.offset_right = 0.0
	shelf.offset_top = 0.0
	shelf.offset_bottom = host.SKILL_MENU_SHELF_HEIGHT
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shelf.z_index = 420
	host.skills_content.add_child(shelf)

	var total_level_header := MarginContainer.new()
	total_level_header.anchor_left = 0.0
	total_level_header.anchor_right = 1.0
	total_level_header.anchor_top = 0.0
	total_level_header.anchor_bottom = 0.0
	total_level_header.offset_left = 0.0
	total_level_header.offset_right = 0.0
	total_level_header.offset_top = 0.0
	total_level_header.offset_bottom = host.SKILL_MENU_SHELF_HEIGHT
	total_level_header.add_theme_constant_override("margin_top", 150)
	total_level_header.add_theme_constant_override("margin_bottom", 12)
	total_level_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	total_level_header.z_index = 430
	host.skills_content.add_child(total_level_header)
	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 22)
	total_level_header.add_child(total_row)
	var total_icon: TextureRect = host.visual_texture_cache._image(host.TOTAL_LEVEL_BARGRAPH_TEXTURE, Vector2(118, 118))
	total_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	total_row.add_child(total_icon)
	total_row.add_child(host._label("Total Lv %s" % host._global_level(), 154, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	host.detail_shelf_shadow_alpha = 0.0
	host.detail_shelf_shadow_overlay = host._add_skill_detail_shadow_overlay_to(host.skills_content, host.SKILL_MENU_SHELF_HEIGHT, host.detail_shelf_shadow_alpha)


func _render_skill_menu(stack: VBoxContainer) -> void:
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, host.SKILL_MENU_TOP_SCROLL_PAD)
	stack.add_child(top_spacer)
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		var theme_color: Color = host._skill_theme_color(skill_id)
		var card_slot := Control.new()
		card_slot.custom_minimum_size = Vector2(0, host.SKILL_MENU_HEADER_HEIGHT)
		card_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_child(card_slot)

		var button := Button.new()
		button.text = ""
		button.anchor_left = 0.0
		button.anchor_right = 1.0
		button.anchor_top = 0.0
		button.anchor_bottom = 1.0
		button.offset_left = 0.0
		button.offset_right = 0.0
		button.offset_top = 0.0
		button.offset_bottom = 0.0
		button.focus_mode = Control.FOCUS_NONE
		button.set_meta("depress_release_no_overshoot", true)
		button.set_meta("skill_menu_card_skill_id", skill_id)
		var card_fill: Color = host._skill_paper_button_color(skill_id)
		button.add_theme_stylebox_override("normal", _skill_menu_band_style(card_fill))
		button.add_theme_stylebox_override("hover", _skill_menu_band_style(card_fill))
		button.add_theme_stylebox_override("pressed", _skill_menu_band_style(card_fill.darkened(0.08), true))
		host._button_press_runtime().attach_button_depress_animation(button, 0.982)
		button.pressed.connect(host._select_skill.bind(skill_id))
		card_slot.add_child(button)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 72)
		margin.add_theme_constant_override("margin_right", 72)
		margin.add_theme_constant_override("margin_top", 34)
		margin.add_theme_constant_override("margin_bottom", 72)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.z_index = 20
		button.add_child(margin)
		
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 16)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)
		row.add_child(SkillIconBadge.menu_icon_badge(host, skill_id, theme_color))
		var copy := VBoxContainer.new()
		copy.custom_minimum_size.x = host.SKILL_MENU_COPY_WIDTH
		copy.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		copy.add_theme_constant_override("separation", 30)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var title: Label = host._label("", 132, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(title)
		var meta: Label = host._label("", 74, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(meta)
		var xp_bar: Control = host._progress(theme_color, 62)
		host._apply_xp_progress_bar_theme(xp_bar, theme_color)
		xp_bar.custom_minimum_size.x = 760
		xp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		copy.add_child(xp_bar)
		var side_gauge: Control = _build_skill_menu_side_gauge(skill_id, theme_color)
		row.add_child(side_gauge)
		var panel_chrome := SkillMenuPanelChrome.new()
		panel_chrome.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel_chrome.radius = 0.0
		panel_chrome.z_index = 30
		panel_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(panel_chrome)
		button.add_child(_skill_menu_band_edge_feather(true))
		button.add_child(_skill_menu_band_edge_feather(false))
		host.skill_cards[skill_id] = {
			"button": button,
			"title": title,
			"meta": meta,
			"xp": xp_bar,
			"stamina": side_gauge if side_gauge is RegenCircle else null,
			"fish": side_gauge if side_gauge is FishCircle else null,
			"health": side_gauge if side_gauge is BlueGuyHealthHeartGauge else null,
		}
		var accessible: bool = host._onboarding_runtime()._onboarding_skill_accessible(skill_id)
		button.disabled = not accessible
		button.modulate = Color.WHITE if accessible else host.HUB_NAV_LOCKED_MODULATE
		var drawer_slot := Control.new()
		drawer_slot.name = "SkillMenuActiveDrawer_%s" % skill_id
		drawer_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		drawer_slot.custom_minimum_size = Vector2(0, 0)
		drawer_slot.visible = false
		drawer_slot.clip_contents = false
		stack.add_child(drawer_slot)
		host.skill_menu_active_drawers[skill_id] = {
			"slot": drawer_slot,
			"module_key": "",
			"card_key": ""
		}
		_sync_skill_menu_active_drawer(skill_id, true)
	var bottom_pad := _skill_menu_bottom_scroll_pad()
	if bottom_pad > 1.0:
		var bottom_spacer := Control.new()
		bottom_spacer.custom_minimum_size = Vector2(0, bottom_pad)
		stack.add_child(bottom_spacer)


func _build_skill_menu_side_gauge(skill_id: String, theme_color: Color) -> Control:
	if host._fishing_rework_active_for_skill(skill_id):
		var fish_gauge := FishCircle.new()
		fish_gauge.custom_minimum_size = Vector2(540, 540)
		fish_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fish_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return fish_gauge
	var stamina_gauge := RegenCircle.new()
	stamina_gauge.custom_minimum_size = Vector2(540, 540)
	stamina_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stamina_gauge.mouse_filter = Control.MOUSE_FILTER_STOP
	stamina_gauge.set_dark_mode(host.dark_mode_enabled)
	stamina_gauge.set_theme_color(theme_color)
	stamina_gauge.gui_input.connect(Callable(host, "_on_stamina_gauge_input").bind(skill_id, stamina_gauge))
	return stamina_gauge


func _skill_menu_bottom_scroll_pad() -> float:
	return host._bottom_ui_reserved_height_for_current_screen() + float(host.SKILL_MENU_BOTTOM_SCROLL_CLEARANCE)


func _skill_menu_active_drawer_card_key(skill_id: String, action_id: String) -> String:
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	return "skill_menu_active:%s:%s" % [skill_id, action_id]


func _skill_menu_active_drawer_module_key(skill_id: String, action_id: String) -> String:
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	if host._fishing_rework_active_for_skill(skill_id):
		var area_def: Dictionary = host._fishing_render_area_module_for_action(skill_id, action_id)
		if not area_def.is_empty():
			return ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key(skill_id, area_def))
	return ModuleUiRuntime.action_for_record(skill_id, host._action_data(skill_id, action_id), host.FISHING_ACTION_ID_ALIASES)


func _skill_menu_active_drawer_content_width() -> float:
	return maxf(host.BASE_CANVAS.x, host._skill_column_host_width())


func _clear_skill_menu_active_drawer(drawer: Dictionary) -> void:
	for raw_card_key in drawer.get("card_keys", []) as Array:
		host._discard_action_card_key(str(raw_card_key))
	var card_key := str(drawer.get("card_key", ""))
	if not card_key.is_empty():
		host._discard_action_card_key(card_key)
	var slot := drawer.get("slot") as Control
	if slot != null and is_instance_valid(slot):
		for child in slot.get_children():
			child.queue_free()
		slot.custom_minimum_size = Vector2(0, 0)
		slot.visible = false
	drawer["module_key"] = ""
	drawer["card_key"] = ""
	drawer["card_keys"] = []
	drawer["collapsed"] = false


func _sync_skill_menu_active_drawer(skill_id: String, instant := false) -> void:
	if skill_id.is_empty() or not host.skill_menu_active_drawers.has(skill_id):
		return
	var drawer := host.skill_menu_active_drawers.get(skill_id, {}) as Dictionary
	var slot := drawer.get("slot", null) as Control
	if slot == null or not is_instance_valid(slot):
		return
	var action_id: String = host.running_action_id if host.running_skill_id == skill_id else ""
	if action_id.is_empty():
		_clear_skill_menu_active_drawer(drawer)
		return
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty():
		_clear_skill_menu_active_drawer(drawer)
		return
	var module_key := _skill_menu_active_drawer_module_key(skill_id, action_id)
	var collapsed: bool = host._module_ui_is_collapsed(module_key)
	var card_key := _skill_menu_active_drawer_card_key(skill_id, action_id)
	var active_fishing_area_def := {}
	if host._fishing_rework_active_for_skill(skill_id):
		active_fishing_area_def = host._fishing_render_area_module_for_action(skill_id, action_id)
		if not active_fishing_area_def.is_empty():
			card_key = host.fishing_runtime.area_module_key(skill_id, active_fishing_area_def)
	if (
		str(drawer.get("module_key", "")) == module_key
		and str(drawer.get("card_key", "")) == card_key
		and bool(drawer.get("collapsed", false)) == collapsed
		and slot.get_child_count() > 0
	):
		return
	_clear_skill_menu_active_drawer(drawer)
	var slot_width := _skill_menu_active_drawer_content_width()
	var content_width: float = host._skill_content_width()
	var module_root: Control = null
	var registered_card_key := ""
	var registered_card_keys: Array = []
	if host._is_passive_action(action):
		var passive_card: Dictionary = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
		module_root = passive_card.get("root") as Control
		var passive_dict := passive_card.get("card", {}) as Dictionary
		passive_dict["entry"] = module_root
		passive_dict["action_id"] = action_id
		host._register_action_card(card_key, passive_dict)
		host._detail_lazy_finalize_action_card(passive_dict, skill_id, action, action_id)
		registered_card_key = card_key
		registered_card_keys.append(card_key)
	elif not active_fishing_area_def.is_empty():
		var built: Dictionary = host._build_fishing_area_module(skill_id, active_fishing_area_def, content_width)
		module_root = built.get("root") as Control
		var area_key := str(built.get("area_key", ""))
		var area_card := built.get("area_card", {}) as Dictionary
		if not area_key.is_empty() and not area_card.is_empty():
			area_card["entry"] = module_root
			host._register_action_card(area_key, area_card)
			registered_card_key = area_key
			registered_card_keys.append(area_key)
			for raw_method_id in built.get("method_ids", []) as Array:
				var method_key: String = host._action_key(skill_id, str(raw_method_id))
				if host.action_cards.has(method_key):
					registered_card_keys.append(method_key)
				var method_card: Dictionary = host._fishing_method_card_for_action(skill_id, str(raw_method_id))
				if bool(method_card.get("is_fishing_location", false)):
					var location_key := "%s:location-%s-%s" % [
						skill_id,
						str(method_card.get("area_id", "")),
						str(method_card.get("location_id", ""))
					]
					if host.action_cards.has(location_key):
						registered_card_keys.append(location_key)
	else:
		var built: Dictionary = host._skill_detail_surface()._build_detail_interactive_action_card(skill_id, action, content_width, content_width)
		module_root = built.get("card_root") as Control
		var card := built.get("card", {}) as Dictionary
		card["entry"] = module_root
		host._register_action_card(card_key, card)
		host._detail_lazy_finalize_action_card(card, skill_id, action, action_id)
		registered_card_key = card_key
		registered_card_keys.append(card_key)
	if module_root == null:
		return
	module_root = host._apply_collapsed_module_squeeze(module_root, module_key, collapsed)
	var module_height := maxf(1.0, module_root.custom_minimum_size.y)
	slot.custom_minimum_size = Vector2(slot_width, module_height + host.SKILL_MENU_ACTIVE_DRAWER_TOP_PAD + host.SKILL_MENU_ACTIVE_DRAWER_BOTTOM_PAD)
	slot.visible = true
	var module_left := maxf(0.0, (slot_width - content_width) * 0.5)
	module_root.anchor_left = 0.0
	module_root.anchor_right = 0.0
	module_root.anchor_top = 0.0
	module_root.anchor_bottom = 0.0
	module_root.offset_left = module_left
	module_root.offset_right = module_left + content_width
	module_root.offset_top = host.SKILL_MENU_ACTIVE_DRAWER_TOP_PAD
	module_root.offset_bottom = host.SKILL_MENU_ACTIVE_DRAWER_TOP_PAD + module_height
	module_root.size = Vector2(content_width, module_height)
	slot.add_child(module_root)
	drawer["module_key"] = module_key
	drawer["card_key"] = registered_card_key
	drawer["card_keys"] = registered_card_keys
	drawer["collapsed"] = collapsed


func _render_pinned_activities_page() -> void:
	var content_width: float = host._skill_content_width()
	var frame := Control.new()
	frame.name = "PinnedActivitiesFrame"
	frame.clip_contents = false
	host._apply_skill_column_layout(frame, content_width, 0.0)
	host.skills_content.add_child(frame)

	var page := VBoxContainer.new()
	page.name = "PinnedActivitiesPage"
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.custom_minimum_size.x = content_width
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	frame.add_child(page)

	page.add_child(_pinned_activities_active_shelf(content_width))
	var divider := Control.new()
	divider.name = "PinnedActivitiesShelfDivider"
	divider.custom_minimum_size = Vector2(content_width, host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(divider)

	var actions_clip := Control.new()
	actions_clip.name = "PinnedActivitiesActionsClip"
	actions_clip.custom_minimum_size.x = content_width
	actions_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_clip.clip_contents = true
	page.add_child(actions_clip)

	host.content_scroll = MobileScrollContainer.new()
	host.content_scroll.name = "PinnedActivitiesActionsScroll"
	host.content_scroll.clip_contents = true
	host.content_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.content_scroll.set_pull_resistance_enabled(true)
	host.content_scroll.gui_input.connect(host._on_pinned_activities_action_scroll_input)
	actions_clip.add_child(host.content_scroll)

	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = content_width
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 0)
	host.content_scroll.add_child(stack)

	var shelf_clearance := Control.new()
	shelf_clearance.name = "PinnedActivitiesShelfClearance"
	shelf_clearance.custom_minimum_size = Vector2(content_width, host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT)
	shelf_clearance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(shelf_clearance)
	var shelf := VBoxContainer.new()
	shelf.name = "PinnedActivitiesShelf"
	shelf.custom_minimum_size = Vector2(content_width, 0)
	shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelf.add_theme_constant_override("separation", 34)
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for raw_key in host.module_ui_runtime.pinned_order:
		var module_key: String = ModuleUiRuntime.normalize(raw_key)
		if module_key.is_empty():
			continue
		var module_root: Control = host._build_pinned_activities_module(module_key, content_width)
		if module_root == null:
			continue
		module_root.set_meta("module_ui_pinned_page_copy", true)
		module_root.set_meta("module_ui_force_expanded", true)
		module_root.set_meta("module_ui_key", module_key)
		host._skill_detail_surface()._remove_module_collapse_zones(module_root)
		host._remove_registered_card_collapse_zone(host._pinned_page_card_key(module_key))
		shelf.add_child(module_root)
	if shelf.get_child_count() <= 0:
		stack.add_child(_pinned_activities_empty_state(content_width))
	else:
		stack.add_child(shelf)
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, host._skills_content_bottom_inset_for_screen() + 52.0)
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(bottom_spacer)
	_add_pinned_active_shelf_shadow_overlay()


func _pinned_activities_empty_state(content_width: float) -> Control:
	var empty := Control.new()
	empty.name = "PinnedActivitiesEmptyState"
	empty.custom_minimum_size = Vector2(content_width, _pinned_activities_empty_state_height())
	empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty.clip_contents = true
	_add_pinned_activities_empty_decor_pins(empty, content_width)
	var label: Label = host._label(
		"Press the top left of any activity to pin it.\nPinned activities from every skill page will appear here.",
		72,
		host.COLOR_INK,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	label.name = "PinnedActivitiesEmptyStateLabel"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 48
	label.offset_right = -48
	label.offset_top = 0
	label.offset_bottom = 0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	empty.add_child(label)
	return empty


func _add_pinned_activities_empty_decor_pins(empty: Control, content_width: float) -> void:
	if empty == null or not is_instance_valid(empty):
		return
	var empty_height := maxf(1.0, empty.custom_minimum_size.y)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	rng.seed = int(Time.get_ticks_usec()) + int(Engine.get_process_frames()) * 104729
	var badge_top_left_offset: Vector2 = host.MODULE_PIN_BADGE_CLIP_ORIGIN + host.MODULE_PIN_BADGE_SETTLED_POSITION
	var badge_visible_height: float = host.MODULE_PIN_BADGE_CLIP_SIZE.y - host.MODULE_PIN_BADGE_SETTLED_POSITION.y
	var hit_zone_size: Vector2 = host.MODULE_PIN_BADGE_HIT_MAX - host.MODULE_PIN_BADGE_HIT_MIN
	hit_zone_size.y = minf(hit_zone_size.y, badge_visible_height - host.MODULE_PIN_BADGE_HIT_MIN.y)
	var horizontal_margin := 30.0
	var vertical_margin := 26.0
	var occupied_rects: Array[Rect2] = []
	for index in range(PINNED_ACTIVITIES_EMPTY_DECOR_PIN_COUNT):
		var badge_position := _pinned_activities_empty_decor_pin_position(
			rng,
			content_width,
			empty_height,
			host.MODULE_PIN_BADGE_SIZE.x,
			badge_visible_height,
			horizontal_margin,
			vertical_margin,
			occupied_rects
		)
		var badge_left := badge_position.x
		var badge_top := badge_position.y
		occupied_rects.append(Rect2(badge_position, Vector2(host.MODULE_PIN_BADGE_SIZE.x, badge_visible_height)).grow(18.0))
		var decor_host := Control.new()
		decor_host.name = "PinnedActivitiesEmptyDecorPin_%s" % index
		decor_host.anchor_left = 0.0
		decor_host.anchor_right = 0.0
		decor_host.anchor_top = 0.0
		decor_host.anchor_bottom = 0.0
		decor_host.position = Vector2(badge_left, badge_top) - badge_top_left_offset
		decor_host.size = host.MODULE_PIN_BADGE_CLIP_SIZE
		decor_host.custom_minimum_size = host.MODULE_PIN_BADGE_CLIP_SIZE
		decor_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		decor_host.clip_contents = false
		decor_host.z_index = 4 + index
		empty.add_child(decor_host)
		var badge := _create_pinned_activities_empty_decor_pin_badge(decor_host, index)
		if badge == null:
			continue
		var hit_zone := Control.new()
		hit_zone.name = "PinnedActivitiesEmptyDecorPinHit_%s" % index
		hit_zone.anchor_left = 0.0
		hit_zone.anchor_right = 0.0
		hit_zone.anchor_top = 0.0
		hit_zone.anchor_bottom = 0.0
		hit_zone.position = decor_host.position + badge_top_left_offset + host.MODULE_PIN_BADGE_HIT_MIN
		hit_zone.size = hit_zone_size
		hit_zone.custom_minimum_size = hit_zone_size
		hit_zone.mouse_filter = Control.MOUSE_FILTER_STOP
		hit_zone.z_index = 44 + index
		hit_zone.gui_input.connect(_on_pinned_activities_empty_decor_pin_gui_input.bind(decor_host.get_instance_id(), badge.get_instance_id(), hit_zone.get_instance_id()))
		empty.add_child(hit_zone)


func _pinned_activities_empty_decor_pin_position(
	rng: RandomNumberGenerator,
	content_width: float,
	empty_height: float,
	pin_width: float,
	pin_height: float,
	horizontal_margin: float,
	vertical_margin: float,
	occupied_rects: Array[Rect2]
) -> Vector2:
	var min_x := horizontal_margin
	var max_x := maxf(min_x, content_width - pin_width - horizontal_margin)
	var min_y := vertical_margin
	var max_y := maxf(min_y, empty_height - pin_height - vertical_margin)
	var label_clear_rect := Rect2(
		Vector2(content_width * 0.045, empty_height * 0.355),
		Vector2(content_width * 0.91, empty_height * 0.245)
	)
	for _attempt in range(80):
		var top_band := rng.randf() < 0.5
		var band_min_y := min_y if top_band else maxf(min_y, empty_height * 0.58)
		var band_max_y := minf(max_y, empty_height * 0.315) if top_band else max_y
		if band_max_y < band_min_y:
			band_min_y = min_y
			band_max_y = max_y
		var candidate := Vector2(
			rng.randf_range(min_x, max_x),
			rng.randf_range(band_min_y, band_max_y)
		)
		var candidate_rect := Rect2(candidate, Vector2(pin_width, pin_height))
		if candidate_rect.intersects(label_clear_rect):
			continue
		var overlaps := false
		for occupied_rect in occupied_rects:
			if candidate_rect.intersects(occupied_rect):
				overlaps = true
				break
		if not overlaps:
			return candidate
	return Vector2(
		rng.randf_range(min_x, max_x),
		rng.randf_range(min_y, max_y)
	)


func _create_pinned_activities_empty_decor_pin_badge(decor_host: Control, index: int) -> TextureButton:
	if decor_host == null or not is_instance_valid(decor_host):
		return null
	var badge: TextureButton = host._ensure_module_pin_badge(decor_host, "")
	if badge == null:
		return null
	badge.name = "PinnedActivitiesEmptyDecorPinBadge_%s" % index
	if badge.is_in_group("module_pin_badges"):
		badge.remove_from_group("module_pin_badges")
	var texture_path: String = host.module_ui_runtime.random_pin_texture_path(host.MODULE_PIN_COLOR_TEXTURES, host.MODULE_PIN_ICON_TEXTURE)
	badge.texture_normal = host.visual_texture_cache._texture_or_visual_fallback(texture_path)
	badge.texture_pressed = badge.texture_normal
	badge.texture_hover = badge.texture_normal
	badge.texture_disabled = badge.texture_normal
	badge.texture_focused = badge.texture_normal
	badge.set_meta("module_pin_texture_path", texture_path)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.disabled = true
	badge.visible = true
	badge.position = host.MODULE_PIN_BADGE_SETTLED_POSITION
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	badge.set_meta("module_pin_module_key", "")
	badge.set_meta("pinned_activities_empty_decor_pin", true)
	host._set_canvas_item_alpha_if_changed(badge, 1.0)
	host._set_module_pin_badge_clip_enabled(badge, true)
	return badge


func _on_pinned_activities_empty_decor_pin_gui_input(event: InputEvent, decor_host_id: int, badge_id: int, hit_zone_id: int) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event != null:
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return
	else:
		var touch_event := event as InputEventScreenTouch
		if touch_event == null or not touch_event.pressed:
			return
	var hit_zone: Control = host._valid_control_ref(instance_from_id(hit_zone_id))
	if hit_zone != null:
		hit_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hit_zone.accept_event()
	var decor_host: Control = host._valid_control_ref(instance_from_id(decor_host_id))
	var badge: TextureButton = host._valid_texture_button_ref(instance_from_id(badge_id))
	if decor_host == null or badge == null:
		return
	_play_pinned_activities_empty_decor_pin_exit_animation(badge, decor_host, hit_zone_id)


func _pinned_activities_empty_state_height() -> float:
	var active_shelf_height: float = _pinned_active_shelf_target_height(_pinned_active_shelf_skill_id())
	var content_top_reserved: float = active_shelf_height + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT + host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT
	var visible_bottom: float = host.BASE_CANVAS.y - float(host.BOTTOM_NAV_HEIGHT) - host._skills_content_bottom_inset_for_screen()
	return maxf(860.0, visible_bottom - content_top_reserved)


func _play_pinned_activities_empty_decor_pin_exit_animation(badge: TextureButton, decor_host: Control, hit_zone_id: int) -> void:
	if badge == null or decor_host == null or not is_instance_valid(badge) or not is_instance_valid(decor_host):
		return
	if badge.is_queued_for_deletion() or decor_host.is_queued_for_deletion() or badge.has_meta("module_pin_tween"):
		return
	host._set_module_pin_badge_clip_enabled(badge, true)
	badge.visible = true
	badge.disabled = true
	badge.position = host.MODULE_PIN_BADGE_SETTLED_POSITION
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	host._set_canvas_item_alpha_if_changed(badge, 1.0)
	host._audio_director()._play_module_pin_exit_sfx()
	var tween: Tween = host.create_tween()
	badge.set_meta("module_pin_tween", tween)
	var badge_id := badge.get_instance_id()
	tween.set_parallel(true)
	tween.tween_method(host._keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, 0.075)
	tween.tween_property(badge, "position", host.MODULE_PIN_BADGE_SETTLED_POSITION + host.MODULE_PIN_EXIT_LIFT_OFFSET, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_callback(host._set_module_pin_badge_clip_enabled_by_id.bind(badge.get_instance_id(), false))
	tween.set_parallel(true)
	tween.tween_method(host._keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, 0.195)
	tween.tween_property(badge, "position", host.MODULE_PIN_BADGE_PULL_OUT_POSITION, 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "scale", Vector2(0.96, 0.96), 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "modulate:a", 0.0, 0.15).set_delay(0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(_finish_pinned_activities_empty_decor_pin_exit_animation.bind(badge.get_instance_id(), decor_host.get_instance_id(), hit_zone_id))


func _finish_pinned_activities_empty_decor_pin_exit_animation(badge_id: int, decor_host_id: int, hit_zone_id: int) -> void:
	var hit_zone: Control = host._valid_control_ref(instance_from_id(hit_zone_id))
	if hit_zone != null and not hit_zone.is_queued_for_deletion():
		hit_zone.queue_free()
	var badge: TextureButton = host._valid_texture_button_ref(instance_from_id(badge_id))
	if badge != null and not badge.is_queued_for_deletion() and badge.has_meta("module_pin_tween"):
		badge.remove_meta("module_pin_tween")
	var decor_host: Control = host._valid_control_ref(instance_from_id(decor_host_id))
	if decor_host != null and not decor_host.is_queued_for_deletion():
		decor_host.queue_free()


func _activity_queue_active_shelf(content_width: float) -> Control:
	var header := PanelContainer.new()
	header.name = "ActivityQueueActiveShelf"
	var active_skill_id: String = host._activity_queue_runtime()._activity_queue_active_shelf_skill_id()
	header.custom_minimum_size = Vector2(content_width, _pinned_active_shelf_target_height(active_skill_id))
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _pinned_active_shelf_panel_style(active_skill_id))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.pinned_active_shelf_header = header

	var body := Control.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(body)
	host.pinned_active_shelf_background = _add_pinned_active_shelf_background(body, active_skill_id, content_width)
	body.add_child(_activity_queue_static_title())
	host.pinned_active_shelf_stamina_strip = _build_pinned_active_shelf_stamina_strip()
	body.add_child(host.pinned_active_shelf_stamina_strip)

	host.pinned_active_shelf_content = Control.new()
	host.pinned_active_shelf_content.name = "ActivityQueueActiveShelfContent"
	host.pinned_active_shelf_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.pinned_active_shelf_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.pinned_active_shelf_content.z_index = 20
	body.add_child(host.pinned_active_shelf_content)

	_rebuild_pinned_active_shelf_content(active_skill_id, true)
	return header

func _activity_queue_static_title() -> Label:
	var title: Label = host._label("Activity Queue", 54, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "ActivityQueueTitle"
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 0.0
	title.offset_left = 0.0
	title.offset_right = 0.0
	title.offset_top = 39.0
	title.offset_bottom = 112.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.z_index = 50
	return title

func _pinned_activities_active_shelf(content_width: float) -> Control:
	var header := PanelContainer.new()
	header.name = "PinnedActivitiesActiveShelf"
	var active_skill_id: String = _pinned_active_shelf_skill_id()
	header.custom_minimum_size = Vector2(content_width, _pinned_active_shelf_target_height(active_skill_id))
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _pinned_active_shelf_panel_style(active_skill_id))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.pinned_active_shelf_header = header

	var body := Control.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(body)
	host.pinned_active_shelf_background = _add_pinned_active_shelf_background(body, active_skill_id, content_width)
	body.add_child(_pinned_activities_static_title())
	host.pinned_active_shelf_stamina_strip = _build_pinned_active_shelf_stamina_strip()
	body.add_child(host.pinned_active_shelf_stamina_strip)

	host.pinned_active_shelf_content = Control.new()
	host.pinned_active_shelf_content.name = "PinnedActivitiesActiveShelfContent"
	host.pinned_active_shelf_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.pinned_active_shelf_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.pinned_active_shelf_content.z_index = 20
	body.add_child(host.pinned_active_shelf_content)

	_rebuild_pinned_active_shelf_content(active_skill_id, true)
	return header

func _pinned_active_shelf_expanded_height() -> float:
	return host.SKILLS_PAGE_TOP_PAD + host.SKILL_DETAIL_HEADER_HEIGHT

func _pinned_active_shelf_target_height(skill_id: String) -> float:
	return _pinned_active_shelf_expanded_height()

func _pinned_active_shelf_shadow_top_y() -> float:
	if host.pinned_active_shelf_header != null and is_instance_valid(host.pinned_active_shelf_header):
		return maxf(1.0, host.pinned_active_shelf_header.custom_minimum_size.y + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)
	return _pinned_active_shelf_target_height(_pinned_active_shelf_skill_id()) + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT

func _add_pinned_active_shelf_shadow_overlay() -> void:
	if host.skills_content == null:
		return
	host.detail_shelf_shadow_alpha = host._skill_detail_shadow_target_alpha()
	host.detail_shelf_shadow_overlay = host._add_skill_detail_shadow_overlay_to(host.skills_content, _pinned_active_shelf_shadow_top_y(), host.detail_shelf_shadow_alpha)

func _add_pinned_active_shelf_background(parent: Control, skill_id: String, content_width: float) -> Control:
	var background: Control = host._add_skill_detail_shelf_background(parent, _pinned_active_shelf_theme_skill_id(skill_id), content_width)
	background.name = "PinnedActivitiesFullBleedShelfBackground"
	background.z_index = 0
	return background

func _pinned_activities_static_title() -> Label:
	var title: Label = host._label("Pinned Activities", 54, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "PinnedActivitiesTitle"
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 0.0
	title.offset_left = 0.0
	title.offset_right = 0.0
	title.offset_top = 39.0
	title.offset_bottom = 112.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.z_index = 50
	return title

func _pinned_active_shelf_skill_id() -> String:
	if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty() and _running_action_is_pinned():
		return host.running_skill_id
	return _pinned_active_shelf_jailed_skill_id()

func _pinned_active_shelf_jailed_skill_id() -> String:
	if host.thieving_action_jails.is_empty():
		return ""
	for raw_action_id in host.thieving_action_jails.keys():
		var action_id := str(raw_action_id)
		if action_id.is_empty() or host._thieving_surface()._thieving_action_jail_remaining(action_id) <= 0:
			continue
		var state := host.thieving_action_jails.get(action_id, {}) as Dictionary
		if not bool(state.get("resume_when_free", false)):
			continue
		var module_key: String = ModuleUiRuntime.normalize("action:thieving:%s" % action_id)
		if host.module_ui_runtime.pinned_order.has(module_key):
			return "thieving"
	return ""

func _pinned_active_shelf_has_jailed_action() -> bool:
	return not _pinned_active_shelf_jailed_skill_id().is_empty()

func _running_action_is_pinned() -> bool:
	if host.running_skill_id.is_empty() or host.running_action_id.is_empty():
		return false
	var direct_action_key: String = ModuleUiRuntime.normalize("action:%s:%s" % [host.running_skill_id, host.running_action_id])
	if host.module_ui_runtime.pinned_order.has(direct_action_key):
		return true
	for raw_key in host.module_ui_runtime.pinned_order:
		var module_key: String = ModuleUiRuntime.normalize(raw_key)
		if module_key.is_empty():
			continue
		if module_key == direct_action_key:
			return true
		if module_key.begins_with("fishing_area:") and host.running_skill_id == "fishing":
			var area_key: String = module_key.substr("fishing_area:".length())
			for raw_area_def in host._fishing_render_area_modules("fishing"):
				var area_def := raw_area_def as Dictionary
				if host.fishing_runtime.area_module_key("fishing", area_def) == area_key and host.fishing_runtime.action_belongs_to_area(host, str(area_def.get("id", "")), host.running_action_id):
					return true
	return false

func _rebuild_pinned_active_shelf_content(skill_id: String, instant := false) -> void:
	if host.pinned_active_shelf_content == null or not is_instance_valid(host.pinned_active_shelf_content):
		return
	if host.pinned_active_shelf_tween != null and host.pinned_active_shelf_tween.is_valid():
		host.pinned_active_shelf_tween.kill()
	host.pinned_active_shelf_tween = null
	host._clear(host.pinned_active_shelf_content)
	host.pinned_active_shelf_skill_id = skill_id
	host.pinned_active_shelf_transition_skill_id = ""
	host.pinned_active_shelf_transition_active = false
	host.pinned_active_shelf_xp_label = null
	host.pinned_active_shelf_xp_bar = null
	host.pinned_active_shelf_regen_circle = null
	host.pinned_active_shelf_fish_circle = null
	_apply_pinned_active_shelf_theme(skill_id, instant)
	if skill_id.is_empty():
		host._set_canvas_item_alpha_if_changed(host.pinned_active_shelf_content, 0.0)
		_set_pinned_active_shelf_stamina_strip_visible(true)
		_sync_pinned_active_shelf_stamina_gauges(0.0, true)
		return
	_set_pinned_active_shelf_stamina_strip_visible(false)
	_build_pinned_active_shelf_skill_content(host.pinned_active_shelf_content, skill_id)
	host._set_canvas_item_alpha_if_changed(host.pinned_active_shelf_content, 1.0 if instant else 0.0)
	if not instant:
		host.pinned_active_shelf_tween = host.create_tween()
		host.pinned_active_shelf_tween.tween_property(host.pinned_active_shelf_content, "modulate:a", 1.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if host.pinned_active_shelf_background != null and is_instance_valid(host.pinned_active_shelf_background):
			host.pinned_active_shelf_tween.parallel().tween_property(host.pinned_active_shelf_background, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _build_pinned_active_shelf_stamina_strip() -> Control:
	var strip := Control.new()
	strip.name = "PinnedActivitiesStaminaGaugeShelf"
	strip.set_anchors_preset(Control.PRESET_FULL_RECT)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.z_index = 12
	host.pinned_active_shelf_stamina_gauges.clear()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", host.SKILLS_PAGE_TOP_PAD + 76)
	margin.add_theme_constant_override("margin_bottom", 74)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	for raw_skill_id in _pinned_activities_stamina_skill_ids():
		var skill_id := str(raw_skill_id)
		var gauge := RegenCircle.new()
		gauge.name = "PinnedActivitiesStaminaGauge_%s" % skill_id
		gauge.custom_minimum_size = host.PINNED_ACTIVITIES_STAMINA_GAUGE_SIZE
		gauge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		gauge.mouse_filter = Control.MOUSE_FILTER_STOP
		gauge.set_dark_mode(host.dark_mode_enabled)
		gauge.set_theme_color(host._skill_theme_color(skill_id))
		gauge.set_regen_ring_color(host._stamina_regen_circle_color(skill_id))
		gauge.gui_input.connect(Callable(host, "_on_stamina_gauge_input").bind(skill_id, gauge))
		row.add_child(gauge)
		host.pinned_active_shelf_stamina_gauges[skill_id] = gauge
	return strip

func _pinned_activities_stamina_skill_ids() -> Array:
	var ids := []
	for raw_def in host.skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
			continue
		ids.append(skill_id)
	return ids

func _set_pinned_active_shelf_stamina_strip_visible(visible: bool) -> void:
	if host.pinned_active_shelf_stamina_strip == null or not is_instance_valid(host.pinned_active_shelf_stamina_strip):
		return
	host._set_canvas_item_visible_if_changed(host.pinned_active_shelf_stamina_strip, visible)
	host._set_canvas_item_alpha_if_changed(host.pinned_active_shelf_stamina_strip, 1.0 if visible else 0.0)

func _sync_pinned_active_shelf_stamina_gauges(_delta: float, instant := false) -> void:
	var live := {}
	for raw_skill_id in host.pinned_active_shelf_stamina_gauges.keys():
		var skill_id := str(raw_skill_id)
		var gauge := host.pinned_active_shelf_stamina_gauges.get(raw_skill_id, null) as RegenCircle
		if gauge == null or not is_instance_valid(gauge):
			continue
		live[skill_id] = gauge
		host._set_regen_circle_for_skill(gauge, skill_id, instant)
	host.pinned_active_shelf_stamina_gauges = live

func _build_pinned_active_shelf_skill_content(parent: Control, skill_id: String) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 66)
	margin.add_theme_constant_override("margin_right", 46)
	margin.add_theme_constant_override("margin_top", host.SKILLS_PAGE_TOP_PAD + 88)
	margin.add_theme_constant_override("margin_bottom", host.SKILL_DETAIL_HEADER_MARGIN_BOTTOM + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(margin)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 66)
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(header_row)

	var left_block := HBoxContainer.new()
	left_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_block.alignment = BoxContainer.ALIGNMENT_CENTER
	left_block.add_theme_constant_override("separation", host.SKILL_DETAIL_LEFT_SEPARATION)
	left_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(left_block)
	left_block.add_child(SkillIconBadge.detail_icon(host, skill_id))

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", host.SKILL_DETAIL_TEXT_SEPARATION)
	title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(title_stack)

	var title: Label = host._label(host._skill_name(skill_id), host._skill_detail_title_font_size(skill_id), host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(title)
	host.pinned_active_shelf_xp_label = host._label(host._skill_level_xp_text(skill_id), host.SKILL_DETAIL_XP_FONT_SIZE, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	host.pinned_active_shelf_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(host.pinned_active_shelf_xp_label)
	var xp: Dictionary = SkillState.xp_progress(host.skills, skill_id, host._skill_level(skill_id))
	host.pinned_active_shelf_xp_bar = host._skill_detail_xp_bar(skill_id, float(xp["pct"]))
	title_stack.add_child(host.pinned_active_shelf_xp_bar)

	if host._fishing_rework_active_for_skill(skill_id):
		host.pinned_active_shelf_fish_circle = FishCircle.new()
		host.pinned_active_shelf_fish_circle.custom_minimum_size = Vector2(552, 552)
		host.pinned_active_shelf_fish_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		host.pinned_active_shelf_fish_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_row.add_child(host.pinned_active_shelf_fish_circle)
		host._set_fish_circle_for_skill(host.pinned_active_shelf_fish_circle, skill_id, true)
	else:
		var regen_circle_host := Control.new()
		regen_circle_host.custom_minimum_size = Vector2(552, 552)
		regen_circle_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		regen_circle_host.clip_contents = false
		header_row.add_child(regen_circle_host)
		host.pinned_active_shelf_regen_circle = RegenCircle.new()
		host.pinned_active_shelf_regen_circle.custom_minimum_size = Vector2(552, 552)
		host.pinned_active_shelf_regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		host.pinned_active_shelf_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
		host.pinned_active_shelf_regen_circle.set_dark_mode(host.dark_mode_enabled)
		host.pinned_active_shelf_regen_circle.set_theme_color(host._skill_theme_color(skill_id))
		host.pinned_active_shelf_regen_circle.set_regen_ring_color(host._stamina_regen_circle_color(skill_id))
		host.pinned_active_shelf_regen_circle.gui_input.connect(Callable(host, "_on_stamina_gauge_input").bind(skill_id, host.pinned_active_shelf_regen_circle))
		regen_circle_host.add_child(host.pinned_active_shelf_regen_circle)
		host._fishing_ui_surface()._attach_auto_eat_fish_toggle(regen_circle_host, skill_id)
		host._set_regen_circle_for_skill(host.pinned_active_shelf_regen_circle, skill_id, true)

func _apply_pinned_active_shelf_theme(skill_id: String, instant := false) -> void:
	if host.pinned_active_shelf_content == null or not is_instance_valid(host.pinned_active_shelf_content):
		return
	var body := host.pinned_active_shelf_content.get_parent() as Control
	if body == null:
		return
	var header := body.get_parent() as PanelContainer
	if header != null:
		header.add_theme_stylebox_override("panel", _pinned_active_shelf_panel_style(skill_id))
	var background: Control = host.pinned_active_shelf_background
	if background == null or not is_instance_valid(background):
		for child in body.get_children():
			var panel := child as Control
			if panel != null and panel.name == "PinnedActivitiesFullBleedShelfBackground":
				background = panel
				host.pinned_active_shelf_background = panel
				break
	if background == null:
		return
	_apply_pinned_active_shelf_background_colors(background, skill_id)
	var target_alpha := 1.0
	host._set_canvas_item_alpha_if_changed(background, target_alpha if instant or skill_id.is_empty() else 0.0)

func _apply_pinned_active_shelf_background_colors(background: Control, skill_id: String) -> void:
	var gradient := background as SkillDetailGradientShelf
	if gradient == null:
		return
	if skill_id.is_empty():
		gradient.set_colors(Color("#ececea"), Color("#d4d2cc"))
		return
	var theme_skill_id := _pinned_active_shelf_theme_skill_id(skill_id)
	gradient.set_colors(host._skill_detail_shelf_color(theme_skill_id), host._skill_detail_shelf_gradient_bottom_color(theme_skill_id))

func _pinned_active_shelf_theme_skill_id(skill_id: String) -> String:
	return skill_id if not skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, skill_id) else "woodcutting"

func _pinned_active_shelf_panel_style(skill_id: String) -> StyleBoxFlat:
	if not skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, skill_id):
		return host._skill_detail_shelf_style(skill_id, false)
	return _pinned_active_shelf_style("", false)

func _pinned_active_shelf_style(skill_id: String, draw_bottom_border := true) -> StyleBoxFlat:
	if not skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, skill_id):
		return host._skill_detail_shelf_style(skill_id, draw_bottom_border)
	var style := StyleBoxFlat.new()
	style.bg_color = host.COLOR_PAPER
	style.border_color = Color(0.09, 0.08, 0.07, 0.12)
	style.border_width_bottom = 5 if draw_bottom_border else 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _sync_pinned_active_shelf(delta: float, instant := false) -> void:
	if (host.current_screen != "pinned" and host.current_screen != "queue") or host.pinned_active_shelf_content == null or not is_instance_valid(host.pinned_active_shelf_content):
		return
	_sync_pinned_active_shelf_stamina_gauges(delta, instant)
	var active_skill_id: String = host._activity_queue_runtime()._activity_queue_active_shelf_skill_id() if host.current_screen == "queue" else _pinned_active_shelf_skill_id()
	if host.pinned_active_shelf_transition_active and active_skill_id == host.pinned_active_shelf_transition_skill_id:
		return
	if active_skill_id != host.pinned_active_shelf_skill_id:
		_transition_pinned_active_shelf_to(active_skill_id, instant)
		return
	if active_skill_id.is_empty():
		return
	var xp: Dictionary = SkillState.xp_progress(host.skills, active_skill_id, host._skill_level(active_skill_id))
	if host.pinned_active_shelf_xp_label != null:
		host._set_label_text_if_changed(host.pinned_active_shelf_xp_label, host._skill_level_xp_text(active_skill_id))
	if host.pinned_active_shelf_xp_bar != null:
		host._apply_xp_progress_bar_theme(host.pinned_active_shelf_xp_bar, host._skill_theme_color(active_skill_id))
		host._set_bar(host.pinned_active_shelf_xp_bar, float(xp["pct"]), delta, instant)
	if host.pinned_active_shelf_fish_circle != null:
		host._set_fish_circle_for_skill(host.pinned_active_shelf_fish_circle, active_skill_id, instant)
	elif host.pinned_active_shelf_regen_circle != null:
		host._set_regen_circle_for_skill(host.pinned_active_shelf_regen_circle, active_skill_id, instant)

func _transition_pinned_active_shelf_to(skill_id: String, instant := false) -> void:
	if host.pinned_active_shelf_content == null or not is_instance_valid(host.pinned_active_shelf_content):
		return
	if host.pinned_active_shelf_tween != null and host.pinned_active_shelf_tween.is_valid():
		host.pinned_active_shelf_tween.kill()
	host.pinned_active_shelf_tween = null
	_animate_pinned_active_shelf_height(skill_id, instant)
	if instant:
		_rebuild_pinned_active_shelf_content(skill_id, true)
		return
	var current_alpha: float = host.pinned_active_shelf_content.modulate.a
	if current_alpha <= 0.001:
		_rebuild_pinned_active_shelf_content(skill_id, false)
		return
	host.pinned_active_shelf_transition_skill_id = skill_id
	host.pinned_active_shelf_transition_active = true
	var content_id: int = host.pinned_active_shelf_content.get_instance_id()
	host.pinned_active_shelf_tween = host.create_tween()
	var fade_out_seconds := 0.10
	host.pinned_active_shelf_tween.tween_property(host.pinned_active_shelf_content, "modulate:a", 0.0, fade_out_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	host.pinned_active_shelf_tween.tween_callback(Callable(self, "_finish_pinned_active_shelf_fade_out").bind(content_id, skill_id))

func _finish_pinned_active_shelf_fade_out(content_id: int, skill_id: String) -> void:
	var content: Control = host._valid_control_ref(instance_from_id(content_id))
	if content == null or content != host.pinned_active_shelf_content:
		return
	_rebuild_pinned_active_shelf_content(skill_id, false)

func _animate_pinned_active_shelf_height(skill_id: String, instant := false) -> void:
	if host.pinned_active_shelf_header == null or not is_instance_valid(host.pinned_active_shelf_header):
		return
	if host.pinned_active_shelf_height_tween != null and host.pinned_active_shelf_height_tween.is_valid():
		host.pinned_active_shelf_height_tween.kill()
	host.pinned_active_shelf_height_tween = null
	var target_height := _pinned_active_shelf_target_height(skill_id)
	if instant:
		_set_pinned_active_shelf_height(target_height)
		return
	var current_height: float = host.pinned_active_shelf_header.custom_minimum_size.y
	if absf(current_height - target_height) <= 0.5:
		_set_pinned_active_shelf_height(target_height)
		return
	host.pinned_active_shelf_height_tween = host.create_tween()
	host.pinned_active_shelf_height_tween.tween_method(Callable(self, "_set_pinned_active_shelf_height"), current_height, target_height, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _set_pinned_active_shelf_height(height: float) -> void:
	if host.pinned_active_shelf_header == null or not is_instance_valid(host.pinned_active_shelf_header):
		return
	host.pinned_active_shelf_header.custom_minimum_size = Vector2(host.pinned_active_shelf_header.custom_minimum_size.x, maxf(1.0, height))
	if host.detail_shelf_shadow_overlay != null and is_instance_valid(host.detail_shelf_shadow_overlay):
		var shadow_top := _pinned_active_shelf_shadow_top_y()
		host.detail_shelf_shadow_overlay.offset_top = shadow_top
		host.detail_shelf_shadow_overlay.offset_bottom = shadow_top + 116.0

func _position_inside_module_utility_interactive_ui(event_position: Vector2) -> bool:
	if _module_sort_button_at_position(event_position) != null:
		return true
	if _module_utility_button_at_position(event_position) != null:
		return true
	if module_sort_menu != null and is_instance_valid(module_sort_menu) and module_sort_menu.is_visible_in_tree():
		if module_sort_menu.get_global_rect().grow(4.0).has_point(event_position):
			return true
	if module_utility_row != null and is_instance_valid(module_utility_row) and module_utility_row.is_visible_in_tree():
		if module_utility_row.get_global_rect().grow(4.0).has_point(event_position):
			return true
	return false

func _layout_module_utility_row() -> void:
	if module_utility_row == null or not is_instance_valid(module_utility_row):
		return
	module_utility_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	module_utility_row.offset_top = -host.BOTTOM_NAV_HEIGHT - host.CHAT_STRIP_HEIGHT - host.MODULE_UTILITY_ROW_GAP - host.MODULE_UTILITY_ROW_HEIGHT
	module_utility_row.offset_bottom = -host.BOTTOM_NAV_HEIGHT - host.CHAT_STRIP_HEIGHT - host.MODULE_UTILITY_ROW_GAP

func _build_module_utility_row() -> void:
	var built := ModuleUtilityRowUi.build({
		"bottom_nav_height": host.BOTTOM_NAV_HEIGHT,
		"chat_strip_height": host.CHAT_STRIP_HEIGHT,
		"gap": host.MODULE_UTILITY_ROW_GAP,
		"height": host.MODULE_UTILITY_ROW_HEIGHT,
		"z_index": host.CHAT_UI_Z + 1,
		"button_size": host.MODULE_UTILITY_BUTTON_SIZE,
		"radius": 36.0,
		"gutter": host.ACTION_CARD_POP_GUTTER,
		"depth_offset": host.ACTION_CARD_3D_DEPTH_OFFSET,
		"diagonal_side": "",
		"collapse_size": host.MODULE_UTILITY_COLLAPSE_TOGGLE_SIZE,
		"texture": Callable(host, "_texture_or_visual_fallback"),
		"res_path": Callable(host.visual_texture_cache, "_res_path"),
		"install_shell": Callable(host._skill_swipe_activity_surface(), "_install_activity_button_shell"),
		"attach_press": Callable(host._skill_swipe_activity_surface(), "_attach_activity_button_press_animation"),
		"buttons": [
			{"id": "pinned", "label": "Pinned", "icon": host.MODULE_PIN_ICON_TEXTURE, "fill": Color.WHITE},
			{"id": "queue", "label": "Queue", "icon": MODULE_QUEUE_ICON_TEXTURE, "fill": Color.WHITE},
			{"id": "skills", "label": "Skills", "icon": "res://assets/content/ui/navigation-controls/skills-overview.png", "fill": Color.WHITE},
			{"id": "sort", "label": "Sort", "icon": "res://assets/content/ui/navigation-controls/sort-list.png", "fill": Color.WHITE}
		]
	})
	module_utility_row = built.get("root") as Control
	module_utility_buttons_row = built.get("row") as HBoxContainer
	host.add_child(module_utility_row)
	_layout_module_utility_row()

	var buttons := built.get("buttons", {}) as Dictionary
	pinned_utility_tab = buttons.get("pinned") as Button
	pinned_utility_tab.pressed.connect(_on_pinned_utility_pressed)
	queue_utility_tab = buttons.get("queue") as Button
	queue_utility_tab.pressed.connect(_on_queue_utility_pressed)
	skills_utility_tab = buttons.get("skills") as Button
	skills_utility_tab.pressed.connect(_on_skills_utility_pressed)
	sort_utility_tab = buttons.get("sort") as Button
	sort_utility_tab.pressed.connect(_on_sort_utility_pressed)
	module_utility_collapse_toggle = built.get("collapse_toggle") as Button
	module_utility_collapse_toggle.pressed.connect(_toggle_module_utility_collapsed)
	_sync_module_utility_row_visibility()

func _on_pinned_utility_pressed() -> void:
	if pinned_utility_tab != null and is_instance_valid(pinned_utility_tab):
		_prime_module_utility_nav_button_press_state(pinned_utility_tab)
	host._show_pinned_activities()

func _on_queue_utility_pressed() -> void:
	if queue_utility_tab != null and is_instance_valid(queue_utility_tab):
		_prime_module_utility_nav_button_press_state(queue_utility_tab)
	if host.queue_selection_mode:
		host._skill_swipe_activity_surface()._finish_queue_selection_mode()
		return
	_show_activity_queue()

func _show_activity_queue() -> void:
	if host.current_screen == "queue":
		_return_from_activity_queue()
		return
	if not host._top_level_nav_allowed("queue"):
		return
	queue_return_screen = _module_utility_return_screen_for_current()
	queue_return_skill_id = host.selected_skill_id
	queue_return_detail_scroll = _module_utility_return_detail_scroll_for_current()
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	host._begin_direct_skill_nav_cover()
	host.current_screen = "queue"
	host._render_screen()
	_sync_module_utility_row_visibility()

func _return_from_activity_queue() -> void:
	var target_screen := queue_return_screen
	if target_screen.is_empty() or _module_utility_screen_overlays_skill_detail(target_screen):
		target_screen = "skill"
	if not host._top_level_nav_allowed(target_screen):
		return
	if not queue_return_skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, queue_return_skill_id):
		host.selected_skill_id = queue_return_skill_id
	var restore_scroll := queue_return_detail_scroll if target_screen == "skill" else -1
	queue_return_detail_scroll = -1
	host._begin_direct_skill_nav_cover()
	host.current_screen = target_screen
	host._render_screen(false, restore_scroll)
	_sync_module_utility_row_visibility()

func _on_skills_utility_pressed() -> void:
	if skills_utility_tab != null and is_instance_valid(skills_utility_tab):
		_prime_module_utility_nav_button_press_state(skills_utility_tab)
	if host.current_screen == "menu":
		_return_from_skills_utility()
		return
	host.skills_utility_return_screen = _module_utility_return_screen_for_current()
	host.skills_utility_return_skill_id = host.selected_skill_id
	host._show_skills()

func _module_utility_screen_overlays_skill_detail(screen: String) -> bool:
	return screen == "pinned" or screen == "queue" or screen == "menu"

func _module_utility_return_screen_for_current() -> String:
	if _module_utility_screen_overlays_skill_detail(host.current_screen):
		return "skill"
	return host.current_screen

func _module_utility_return_detail_scroll_for_current() -> int:
	if host.current_screen == "skill":
		return host._current_detail_scroll_for_pinned_return()
	if host.current_screen == "pinned" and host.pinned_return_screen == "skill":
		return host.pinned_return_detail_scroll
	if host.current_screen == "queue" and queue_return_screen == "skill":
		return queue_return_detail_scroll
	return -1

func _return_from_skills_utility() -> void:
	var target_screen: String = host.skills_utility_return_screen
	if target_screen.is_empty() or _module_utility_screen_overlays_skill_detail(target_screen):
		target_screen = "skill"
	if not host._top_level_nav_allowed(target_screen):
		return
	if not host.skills_utility_return_skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, host.skills_utility_return_skill_id):
		host.selected_skill_id = host.skills_utility_return_skill_id
	host.current_screen = target_screen
	host._render_screen()

func _on_sort_utility_pressed() -> void:
	_toggle_module_sort_menu()

func _route_module_utility_button_global_input(event: InputEvent) -> bool:
	if module_utility_row == null or not is_instance_valid(module_utility_row):
		return false
	if not module_utility_row.is_inside_tree() or not module_utility_row.is_visible_in_tree():
		return false
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	var event_position: Vector2 = host._passive_button_event_position(event, null)
	var is_press := _module_utility_event_is_press(event)
	var button := _module_utility_button_at_position(event_position) if is_press else _active_module_utility_button()
	if button == null:
		return false
	_on_module_utility_button_global_input(event, button)
	return true

func _module_utility_button_at_position(event_position: Vector2) -> Button:
	for raw_button in [pinned_utility_tab, queue_utility_tab, skills_utility_tab, sort_utility_tab, module_utility_collapse_toggle]:
		var button := raw_button as Button
		if button == null or not is_instance_valid(button) or button.disabled:
			continue
		if not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		var button_rect := _module_utility_button_hit_rect(button)
		if button_rect.has_point(event_position):
			return button
	return null

func _module_utility_button_hit_rect(button: Button) -> Rect2:
	if button == null or not is_instance_valid(button):
		return Rect2()
	var button_rect := button.get_global_rect()
	if button.has_meta("activity_button_pop_id"):
		button_rect = host._skill_swipe_activity_surface()._activity_button_target_face_global_rect(button, true)
	return button_rect.grow(24.0)

func _module_sort_button_at_position(event_position: Vector2) -> Button:
	for raw_button in [module_sort_low_level_button, module_sort_high_level_button, module_sort_combo_button, module_sort_collection_button]:
		var button := raw_button as Button
		if button == null or not is_instance_valid(button) or button.disabled:
			continue
		if not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		if button.get_global_rect().grow(16.0).has_point(event_position):
			return button
	return null

func _active_module_utility_button() -> Button:
	for raw_button in [pinned_utility_tab, queue_utility_tab, skills_utility_tab, sort_utility_tab, module_utility_collapse_toggle]:
		var button := raw_button as Button
		if ButtonPressState.active(button, "module_utility"):
			return button
	return null

func _module_utility_event_is_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		return event.pressed
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false

func _on_module_utility_button_global_input(event: InputEvent, button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	var event_position: Vector2 = host._passive_button_event_position(event, null)
	var event_kind := ButtonPressState.event_kind(event)
	if event_kind == "press":
		ButtonPressState.begin(button, "module_utility", event_position)
		host._button_press_runtime().play_default_button_sfx()
		host._skill_swipe_activity_surface()._press_activity_button_shell_bound(button.get_instance_id())
		return
	if event_kind == "drag":
		ButtonPressState.update_drag(button, "module_utility", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
		return
	if event_kind != "release":
		return
	var valid_tap := ButtonPressState.finish(button, "module_utility", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
	host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button.get_instance_id())
	if valid_tap:
		_activate_module_utility_button(button)

func _activate_module_utility_button(button: Button) -> void:
	if button == pinned_utility_tab:
		_on_pinned_utility_pressed()
	elif button == queue_utility_tab:
		_on_queue_utility_pressed()
	elif button == skills_utility_tab:
		_on_skills_utility_pressed()
	elif button == sort_utility_tab:
		_on_sort_utility_pressed()
	elif button == module_utility_collapse_toggle:
		_toggle_module_utility_collapsed()

func _is_module_utility_nav_button(button: Button) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	if bool(button.get_meta("module_utility_nav_button", false)):
		return true
	if module_utility_buttons_row == null or not is_instance_valid(module_utility_buttons_row):
		return false
	return button.get_parent() == module_utility_buttons_row

func _prime_module_utility_nav_button_press_state(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var target_active := false
	if button == pinned_utility_tab:
		target_active = host.current_screen != "pinned"
	elif button == queue_utility_tab:
		target_active = host.current_screen != "queue"
	elif button == skills_utility_tab:
		target_active = host.current_screen != "menu"
	elif button == sort_utility_tab:
		target_active = not (module_sort_menu != null and is_instance_valid(module_sort_menu) and module_sort_menu.visible)
	else:
		button.set_meta("activity_button_hold_nav_press", true)
		return
	button.set_meta("activity_button_hold_nav_press", true)
	button.set_meta("activity_button_hold_nav_target_active", target_active)

func _toggle_module_sort_menu() -> void:
	if module_sort_menu != null and is_instance_valid(module_sort_menu) and module_sort_menu.visible:
		_hide_module_sort_menu(true)
	else:
		_show_module_sort_menu()

func _show_module_sort_menu() -> void:
	if not host._intro_bottom_controls_unlocked():
		_hide_module_sort_menu(false)
		return
	if module_sort_menu == null or not is_instance_valid(module_sort_menu):
		_build_module_sort_menu()
	_sync_module_sort_menu_buttons()
	_layout_module_sort_menu()
	_animate_module_sort_menu_unwrap()
	_sync_module_utility_button_states()

func _hide_module_sort_menu(animate_menu := false) -> void:
	if module_sort_menu != null and is_instance_valid(module_sort_menu):
		if animate_menu:
			_animate_module_sort_menu_wrap()
		else:
			_kill_module_sort_menu_tween()
			_finish_module_sort_menu_wrap()
	_sync_module_utility_button_states()

func _animate_module_sort_menu_unwrap() -> void:
	if module_sort_menu == null or not is_instance_valid(module_sort_menu):
		return
	_kill_module_sort_menu_tween()
	module_sort_menu.visible = true
	var visual := _module_sort_menu_visual()
	visual.pivot_offset = Vector2(visual.size.x * 0.5, visual.size.y)
	visual.scale = Vector2(1.0, host.MODULE_SORT_MENU_COLLAPSED_SCALE_Y)
	visual.modulate.a = 0.0
	module_sort_menu_tween = host.create_tween()
	module_sort_menu_tween.set_parallel(true)
	module_sort_menu_tween.tween_property(visual, "scale:y", 1.0, host.MODULE_SORT_MENU_UNWRAP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	module_sort_menu_tween.tween_property(visual, "modulate:a", 1.0, host.MODULE_SORT_MENU_UNWRAP_SECONDS * 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	module_sort_menu_tween.finished.connect(_finish_module_sort_menu_unwrap)

func _animate_module_sort_menu_wrap() -> void:
	if module_sort_menu == null or not is_instance_valid(module_sort_menu):
		return
	_kill_module_sort_menu_tween()
	module_sort_menu.visible = true
	var visual := _module_sort_menu_visual()
	visual.pivot_offset = Vector2(visual.size.x * 0.5, visual.size.y)
	visual.scale = Vector2.ONE
	visual.modulate.a = 1.0
	module_sort_menu_tween = host.create_tween()
	module_sort_menu_tween.set_parallel(true)
	module_sort_menu_tween.tween_property(visual, "scale:y", host.MODULE_SORT_MENU_COLLAPSED_SCALE_Y, host.MODULE_SORT_MENU_WRAP_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	module_sort_menu_tween.tween_property(visual, "modulate:a", 0.0, host.MODULE_SORT_MENU_WRAP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	module_sort_menu_tween.finished.connect(_finish_module_sort_menu_wrap)

func _finish_module_sort_menu_unwrap() -> void:
	module_sort_menu_tween = null
	if module_sort_menu == null or not is_instance_valid(module_sort_menu):
		return
	module_sort_menu.visible = true
	var visual := _module_sort_menu_visual()
	visual.scale = Vector2.ONE
	visual.modulate.a = 1.0

func _finish_module_sort_menu_wrap() -> void:
	module_sort_menu_tween = null
	if module_sort_menu == null or not is_instance_valid(module_sort_menu):
		return
	module_sort_menu.visible = false
	var visual := _module_sort_menu_visual()
	visual.scale = Vector2.ONE
	visual.modulate.a = 1.0
	_sync_module_utility_button_states()

func _module_sort_menu_visual() -> Control:
	if module_sort_menu_visual != null and is_instance_valid(module_sort_menu_visual):
		return module_sort_menu_visual
	return module_sort_menu

func _kill_module_sort_menu_tween() -> void:
	if module_sort_menu_tween != null and module_sort_menu_tween.is_valid():
		module_sort_menu_tween.kill()
	module_sort_menu_tween = null

func _build_module_sort_menu() -> void:
	var built := ModuleSortMenuUi.build(host.CHAT_UI_Z + 2, Callable(self, "_toggle_module_ui_level_sort"), Callable(self, "_toggle_module_ui_sort_priority"), Callable(host._button_press_runtime(), "attach_button_depress_animation"), host.app_font, host.app_bold_font, host.COLOR_INK)
	module_sort_menu = built.get("menu") as Control
	module_sort_menu_visual = built.get("visual") as Control
	module_sort_low_level_button = built.get("low_level_button") as Button
	module_sort_high_level_button = null
	module_sort_combo_button = built.get("combo_button") as Button
	module_sort_collection_button = built.get("collection_button") as Button
	host.add_child(module_sort_menu)

func _layout_module_sort_menu() -> void:
	if module_sort_menu == null or not is_instance_valid(module_sort_menu):
		return
	var menu_size: Vector2 = module_sort_menu.custom_minimum_size
	module_sort_menu.size = menu_size
	var center_x: float = host.size.x * 0.5
	var top_y: float = host.size.y - host.BOTTOM_NAV_HEIGHT - host.CHAT_STRIP_HEIGHT - host.MODULE_UTILITY_ROW_GAP - host.MODULE_UTILITY_ROW_HEIGHT - menu_size.y - 22.0
	if sort_utility_tab != null and is_instance_valid(sort_utility_tab):
		var sort_rect: Rect2 = host._skill_swipe_activity_surface()._activity_button_target_face_global_rect(sort_utility_tab, true)
		center_x = sort_rect.position.x + sort_rect.size.x * 0.5
		top_y = sort_rect.position.y - menu_size.y - 22.0
	module_sort_menu.position = Vector2(
		clampf(center_x - menu_size.x * 0.5, 18.0, maxf(18.0, host.size.x - menu_size.x - 18.0)),
		maxf(18.0, top_y)
	)

func _sync_module_sort_menu_buttons() -> void:
	ModuleSortMenuUi.sync_buttons(module_sort_low_level_button, module_sort_combo_button, module_sort_collection_button, host.module_ui_runtime.sort_mode == host.MODULE_UI_SORT_LEVEL_REVERSE, host.module_ui_runtime.combo_first, host.module_ui_runtime.collection_first, host.COLOR_INK)

func _toggle_module_ui_level_sort() -> void:
	if host.module_ui_runtime.toggle_level_sort():
		_apply_module_ui_sort_preference_change()

func _toggle_module_ui_sort_priority(priority_kind: String) -> void:
	if host.module_ui_runtime.toggle_sort_priority(priority_kind):
		_apply_module_ui_sort_preference_change()

func _apply_module_ui_sort_preference_change() -> void:
	host._mark_save_dirty("module sort changed")
	host.save_game()
	_sync_module_sort_menu_buttons()
	if host.current_screen == "skill":
		if not host._try_refresh_detail_module_order_in_place():
			host.call_deferred("_refresh_visible_skill_detail_action_list", host.detail_actions_scroll.scroll_vertical if host.detail_actions_scroll != null else -1, host.selected_skill_id, true)
	elif host.current_screen == "menu":
		host._render_screen()

func _sync_module_utility_row_visibility(animate_buttons := false) -> void:
	if module_utility_row == null or not is_instance_valid(module_utility_row):
		return
	_layout_module_utility_row()
	module_utility_row.visible = (
		host._intro_bottom_controls_unlocked()
		and host._profile_chat_overlay_surface()._global_chat_allowed()
		and host._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen()
	)
	if module_utility_buttons_row != null and is_instance_valid(module_utility_buttons_row):
		if module_utility_row.visible:
			if module_utility_buttons_motion_active:
				_update_module_utility_buttons_row_motion()
			if not module_utility_buttons_motion_active:
				_set_module_utility_buttons_row_expanded(not module_utility_collapsed, animate_buttons)
		else:
			_finish_module_utility_buttons_row_motion(false)
	_layout_module_utility_collapse_toggle()
	_sync_module_utility_button_states()
	if not module_utility_row.visible:
		_hide_module_sort_menu(false)

func _toggle_module_utility_collapsed() -> void:
	module_utility_collapsed = not module_utility_collapsed
	if module_utility_collapsed:
		_hide_module_sort_menu(false)
	_sync_module_utility_row_visibility(true)

func _set_module_utility_buttons_row_expanded(expanded: bool, animate_buttons: bool) -> void:
	if module_utility_buttons_row == null or not is_instance_valid(module_utility_buttons_row):
		return
	_cancel_module_utility_buttons_row_motion()
	var slide_offset := Vector2(-host.MODULE_UTILITY_BUTTONS_SLIDE_PIXELS, 0)
	if not animate_buttons:
		_finish_module_utility_buttons_row_motion(expanded)
		return
	module_utility_buttons_motion_active = true
	module_utility_buttons_motion_expanded = expanded
	module_utility_buttons_motion_started_msec = Time.get_ticks_msec()
	if expanded:
		module_utility_buttons_row.visible = true
		module_utility_buttons_motion_duration_msec = int(host.MODULE_UTILITY_BUTTONS_ENTER_SECONDS * 1000.0)
		module_utility_buttons_motion_frame = 0
		module_utility_buttons_motion_total_frames = maxi(1, int(ceil(host.MODULE_UTILITY_BUTTONS_ENTER_SECONDS * 60.0)))
		module_utility_buttons_motion_from_offset = slide_offset.x
		module_utility_buttons_motion_to_offset = 0.0
		module_utility_buttons_motion_from_alpha = 0.0
		module_utility_buttons_motion_to_alpha = 1.0
		_set_module_utility_buttons_row_offset_x(slide_offset.x)
		module_utility_buttons_row.modulate.a = 0.0
	else:
		module_utility_buttons_row.visible = true
		module_utility_buttons_motion_duration_msec = int(host.MODULE_UTILITY_BUTTONS_EXIT_SECONDS * 1000.0)
		module_utility_buttons_motion_frame = 0
		module_utility_buttons_motion_total_frames = maxi(1, int(ceil(host.MODULE_UTILITY_BUTTONS_EXIT_SECONDS * 60.0)))
		module_utility_buttons_motion_from_offset = 0.0
		module_utility_buttons_motion_to_offset = slide_offset.x
		module_utility_buttons_motion_from_alpha = 1.0
		module_utility_buttons_motion_to_alpha = 0.0
		_set_module_utility_buttons_row_offset_x(0.0)
		module_utility_buttons_row.modulate.a = 1.0
	_update_module_utility_buttons_row_motion()

func _update_module_utility_buttons_row_motion() -> void:
	if module_utility_buttons_row == null or not is_instance_valid(module_utility_buttons_row):
		module_utility_buttons_motion_active = false
		return
	var elapsed_msec: int = Time.get_ticks_msec() - module_utility_buttons_motion_started_msec
	var duration_msec: int = int(maxi(1, module_utility_buttons_motion_duration_msec))
	module_utility_buttons_motion_frame += 1
	var clock_progress: float = clampf(float(elapsed_msec) / float(duration_msec), 0.0, 1.0)
	var frame_progress: float = clampf(float(module_utility_buttons_motion_frame) / float(module_utility_buttons_motion_total_frames), 0.0, 1.0)
	var progress: float = maxf(clock_progress, frame_progress)
	var eased: float = _module_utility_buttons_motion_ease(progress, module_utility_buttons_motion_expanded)
	_set_module_utility_buttons_row_offset_x(lerpf(module_utility_buttons_motion_from_offset, module_utility_buttons_motion_to_offset, eased))
	module_utility_buttons_row.modulate.a = lerpf(module_utility_buttons_motion_from_alpha, module_utility_buttons_motion_to_alpha, smoothstep(0.0, 1.0, progress))
	_apply_module_utility_buttons_stagger(progress, module_utility_buttons_motion_expanded)
	if progress >= 1.0:
		_finish_module_utility_buttons_row_motion(module_utility_buttons_motion_expanded)

func _module_utility_buttons_motion_ease(progress: float, entering: bool) -> float:
	var t := clampf(progress, 0.0, 1.0)
	if entering:
		var back := 1.32
		var shifted := t - 1.0
		return 1.0 + (back + 1.0) * shifted * shifted * shifted + back * shifted * shifted
	return t * t * t

func _apply_module_utility_buttons_stagger(progress: float, entering: bool) -> void:
	if module_utility_buttons_row == null or not is_instance_valid(module_utility_buttons_row):
		return
	var controls := _module_utility_button_controls()
	var count := controls.size()
	if count <= 0:
		return
	var max_delay: float = host.MODULE_UTILITY_BUTTONS_STAGGER_STEP * float(maxi(0, count - 1))
	var active_span := maxf(0.001, 1.0 - max_delay)
	for index in range(count):
		var button := controls[index] as Control
		if button == null or not is_instance_valid(button):
			continue
		button.pivot_offset = button.size * 0.5
		var delayed_progress := clampf((progress - host.MODULE_UTILITY_BUTTONS_STAGGER_STEP * float(index)) / active_span, 0.0, 1.0)
		var local_progress := _module_utility_buttons_motion_ease(delayed_progress, true)
		var visibility_progress := delayed_progress if entering else 1.0 - delayed_progress
		button.modulate.a = smoothstep(0.0, 1.0, visibility_progress)
		var scale_progress := local_progress if entering else 1.0 - local_progress
		var button_scale := lerpf(host.MODULE_UTILITY_BUTTONS_STAGGER_MIN_SCALE, 1.0, scale_progress)
		button.scale = Vector2(button_scale, button_scale)

func _module_utility_button_controls() -> Array:
	var controls := []
	if module_utility_buttons_row == null or not is_instance_valid(module_utility_buttons_row):
		return controls
	for raw_child in module_utility_buttons_row.get_children():
		var control := raw_child as Control
		if control != null and is_instance_valid(control):
			controls.append(control)
	return controls

func _reset_module_utility_buttons_stagger() -> void:
	for raw_button in _module_utility_button_controls():
		var button := raw_button as Control
		if button == null or not is_instance_valid(button):
			continue
		button.modulate.a = 1.0
		button.scale = Vector2.ONE
		button.pivot_offset = button.size * 0.5

func _set_module_utility_buttons_row_offset_x(offset_x: float) -> void:
	if module_utility_buttons_row == null or not is_instance_valid(module_utility_buttons_row):
		return
	module_utility_buttons_row.offset_left = offset_x
	module_utility_buttons_row.offset_right = offset_x

func _finish_module_utility_buttons_row_motion(expanded: bool) -> void:
	module_utility_buttons_motion_active = false
	if module_utility_buttons_row == null or not is_instance_valid(module_utility_buttons_row):
		return
	module_utility_buttons_row.visible = expanded
	_set_module_utility_buttons_row_offset_x(0.0)
	module_utility_buttons_row.modulate.a = 1.0
	_reset_module_utility_buttons_stagger()

func _cancel_module_utility_buttons_row_motion() -> void:
	module_utility_buttons_motion_active = false
	_reset_module_utility_buttons_stagger()

func _layout_module_utility_collapse_toggle() -> void:
	if module_utility_collapse_toggle == null or not is_instance_valid(module_utility_collapse_toggle):
		return
	module_utility_collapse_toggle.visible = module_utility_row.visible
	var arrow = host._skill_swipe_activity_surface()._activity_button_arrow(module_utility_collapse_toggle)
	if arrow != null:
		arrow.set_direction(1 if module_utility_collapsed else -1)
	module_utility_collapse_toggle.size = host.MODULE_UTILITY_COLLAPSE_TOGGLE_SIZE
	var expanded_x := 46.0
	var collapsed_x := 46.0
	module_utility_collapse_toggle.position = Vector2(
		collapsed_x if module_utility_collapsed else expanded_x,
		(host.MODULE_UTILITY_ROW_HEIGHT - host.MODULE_UTILITY_COLLAPSE_TOGGLE_SIZE.y) * 0.5
	)

func _sync_module_utility_button_states() -> void:
	if pinned_utility_tab != null and is_instance_valid(pinned_utility_tab):
		var fill := pinned_utility_tab.get_meta("module_utility_fill", Color.WHITE) as Color
		var active: bool = host.current_screen == "pinned"
		var active_fill: Color = host.MODULE_UTILITY_ACTIVE_FILL if active else fill
		host._skill_swipe_activity_surface()._set_activity_button_shell_theme(pinned_utility_tab, active_fill, active, true)
	if queue_utility_tab != null and is_instance_valid(queue_utility_tab):
		var fill := queue_utility_tab.get_meta("module_utility_fill", Color.WHITE) as Color
		var active: bool = host.current_screen == "queue"
		var active_fill: Color = host.MODULE_UTILITY_ACTIVE_FILL if active else fill
		host._skill_swipe_activity_surface()._set_activity_button_shell_theme(queue_utility_tab, active_fill, active, true)
	if skills_utility_tab != null and is_instance_valid(skills_utility_tab):
		var fill := skills_utility_tab.get_meta("module_utility_fill", Color.WHITE) as Color
		var active: bool = host.current_screen == "menu"
		var active_fill: Color = host.MODULE_UTILITY_ACTIVE_FILL if active else fill
		host._skill_swipe_activity_surface()._set_activity_button_shell_theme(skills_utility_tab, active_fill, active, true)
	if sort_utility_tab != null and is_instance_valid(sort_utility_tab):
		var fill := sort_utility_tab.get_meta("module_utility_fill", Color.WHITE) as Color
		var active: bool = module_sort_menu != null and is_instance_valid(module_sort_menu) and module_sort_menu.visible
		var active_fill: Color = host.MODULE_UTILITY_ACTIVE_FILL if active else fill
		host._skill_swipe_activity_surface()._set_activity_button_shell_theme(sort_utility_tab, active_fill, active, true)


func _skill_menu_band_style(color: Color, pressed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.08 if pressed else 0.0)
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	style.anti_aliasing = false
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = max(18, 72 - 18 + (6 if pressed else 0))
	style.content_margin_bottom = max(18, 72 - 8 - (4 if pressed else 0))
	return style


func _skill_menu_band_edge_feather(top_edge: bool) -> TextureRect:
	var feather := TextureRect.new()
	feather.name = "SkillMenuBandTopFeather" if top_edge else "SkillMenuBandBottomFeather"
	feather.anchor_left = 0.0
	feather.anchor_right = 1.0
	feather.anchor_top = 0.0 if top_edge else 1.0
	feather.anchor_bottom = 0.0 if top_edge else 1.0
	feather.offset_left = 0.0
	feather.offset_right = 0.0
	feather.offset_top = -24.0 if top_edge else -236.0
	feather.offset_bottom = 236.0 if top_edge else 24.0
	feather.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feather.z_index = 1
	var gradient := Gradient.new()
	var paper: Color = host._theme_paper_color()
	var paper_edge := Color(paper.r, paper.g, paper.b, 0.92)
	var paper_strong := Color(paper.r, paper.g, paper.b, 0.62)
	var paper_mid := Color(paper.r, paper.g, paper.b, 0.28)
	var paper_soft := Color(paper.r, paper.g, paper.b, 0.07)
	var paper_clear := Color(paper.r, paper.g, paper.b, 0.0)
	gradient.set_color(0, paper_edge if top_edge else paper_clear)
	gradient.set_offset(0, 0.0)
	gradient.add_point(0.12, paper_strong if top_edge else paper_soft)
	gradient.add_point(0.34, paper_mid if top_edge else paper_mid)
	gradient.add_point(0.68, paper_soft if top_edge else paper_strong)
	gradient.set_color(4, paper_clear if top_edge else paper_edge)
	gradient.set_offset(4, 1.0)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 16
	texture.height = 256
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	feather.texture = texture
	feather.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feather.stretch_mode = TextureRect.STRETCH_SCALE
	return feather
