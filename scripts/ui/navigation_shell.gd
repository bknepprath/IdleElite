extends RefCounted

const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const ButtonPressState = preload("res://scripts/ui/button_press_state.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActivityProgressRail = preload("res://scripts/ui/activity_progress_rail.gd")
const SkillIconBadge = preload("res://scripts/ui/skill_icon_badge.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const CleanProgressBar = preload("res://scripts/ui/clean_progress_bar.gd")
const HERO_UNLOCK_TOTAL_LEVEL := 25
const HERO_LOCKED_MESSAGE := "Total Lv 25 required!"
const HUB_UNLOCK_BUILD_LEVEL := 3
const HUB_LOCKED_MESSAGE := "Lv 3 Building required!"
const SHOP_UNLOCK_BRONZE_MEDALS := 5
const SHOP_LOCKED_MESSAGE := "5 Bronze medals\nrequired!"
const HUB_NAV_LOCKED_MODULATE := Color("#3f3f3f")
const HUB_NAV_UNLOCK_FADE_SECONDS := 0.62
const TOP_LEVEL_NAV_DEBOUNCE_MSEC := 120
const MODULE_UTILITY_ROW_HEIGHT := 172
const MODULE_UTILITY_ROW_GAP := 14
const MODULE_UTILITY_BUTTON_SIZE := Vector2(195, 156)
const NAV_BUTTON_DEPTH_OFFSET := ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET * 2.0
const MODULE_UTILITY_COLLAPSE_TOGGLE_SIZE := Vector2(73, 73)
const MODULE_UTILITY_BUTTONS_SLIDE_PIXELS := 156.0
const MODULE_UTILITY_BUTTONS_ENTER_SECONDS := 0.26
const MODULE_UTILITY_BUTTONS_EXIT_SECONDS := 0.18
const MODULE_UTILITY_BUTTONS_STAGGER_STEP := 0.16
const MODULE_UTILITY_BUTTONS_STAGGER_MIN_SCALE := 0.86
const MODULE_SORT_MENU_UNWRAP_SECONDS := 0.24
const MODULE_SORT_MENU_WRAP_SECONDS := 0.16
const MODULE_SORT_MENU_COLLAPSED_SCALE_Y := 0.14
const MODULE_QUEUE_ICON_TEXTURE := "res://assets/content/ui/navigation-controls/queue.png"
const BOTTOM_NAV_HEIGHT := 210
const BOTTOM_NAV_SAFE_PAD := 48
const NAV_OPEN_CLOSE_ICON_TEXTURE := "res://assets/content/ui/navigation-controls/nav-open-close.png"
const PINNED_ACTIVITIES_EMPTY_DECOR_PIN_COUNT := 7
const SKILL_MENU_COPY_WIDTH := 420
const SKILL_MENU_SHELF_HEIGHT := 184
const SKILL_MENU_TOP_SCROLL_PAD := 27
const SKILL_MENU_BOTTOM_SCROLL_CLEARANCE := 90
const SKILL_MENU_HEADER_HEIGHT := 305
const SKILL_MENU_ACTIVE_DRAWER_TOP_PAD := 9
const SKILL_MENU_ACTIVE_DRAWER_BOTTOM_PAD := 22
const SKILL_MENU_LIGHT_PASTEL_MIX := 0.68
const SKILL_MENU_DARK_THEME_DARKEN := 0.18
const SKILL_MENU_DARK_PANEL_MIX := 0.10
const PAGE_SWITCH_MODULE_HEIGHT := 170
const PAGE_SWITCH_SKILL_ICON_STAGE_SIZE := Vector2(215, 215)
const PAGE_SWITCH_SKILL_ICON_SYMBOL_BASE_SIZE := Vector2(223, 223)
const PAGE_SWITCH_SKILL_ICON_EDGE_CROP := 54.0
const PAGE_SWITCH_SKILL_ICON_VERTICAL_SHIFT := -4.0

class _ModuleSortMenuBuilder:
	static func build(z_index: int, level_toggle: Callable, priority_toggle: Callable, depress: Callable, app_font: Font, bold_font: Font, ink: Color) -> Dictionary:
		var menu := Control.new()
		menu.custom_minimum_size = Vector2(280, 360)
		menu.size = menu.custom_minimum_size
		menu.z_index = z_index
		menu.z_as_relative = false
		menu.visible = false
		menu.mouse_filter = Control.MOUSE_FILTER_STOP

		var visual := Control.new()
		visual.name = "ModuleSortMenuVisual"
		visual.set_anchors_preset(Control.PRESET_FULL_RECT)
		visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		menu.add_child(visual)

		var row := VBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 17)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(row)

		var low_level_button := _button("Level: Low", level_toggle, depress, app_font, bold_font, ink)
		row.add_child(low_level_button)

		var combo_button := _button("Combo", priority_toggle.bind("combo"), depress, app_font, bold_font, ink)
		combo_button.set_meta("module_sort_priority_kind", "combo")
		combo_button.set_meta("module_sort_label", "Combo")
		row.add_child(combo_button)

		var collection_button := _button("Collection", priority_toggle.bind("collection"), depress, app_font, bold_font, ink)
		collection_button.set_meta("module_sort_priority_kind", "collection")
		collection_button.set_meta("module_sort_label", "Collection")
		row.add_child(collection_button)

		return {
			"menu": menu,
			"visual": visual,
			"low_level_button": low_level_button,
			"combo_button": combo_button,
			"collection_button": collection_button
		}

	static func sync_buttons(low_level_button: Button, combo_button: Button, collection_button: Button, high_level_first: bool, combo_first: bool, collection_first: bool, ink: Color) -> void:
		if low_level_button != null and is_instance_valid(low_level_button):
			_sync_button(low_level_button, "Level: High" if high_level_first else "Level: Low", false, ink)
		_sync_priority_button(combo_button, combo_first, ink)
		_sync_priority_button(collection_button, collection_first, ink)

	static func _sync_priority_button(button: Button, active: bool, ink: Color) -> void:
		if button == null or not is_instance_valid(button):
			return
		_sync_button(button, str(button.get_meta("module_sort_label", "Combo")), active, ink)

	static func _button(label_text: String, callback: Callable, depress: Callable, app_font: Font, bold_font: Font, ink: Color) -> Button:
		var button := Button.new()
		button.custom_minimum_size = Vector2(280, 97.5)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		_apply_text(button, label_text, 60, app_font, bold_font, ink)
		if callback.is_valid():
			button.pressed.connect(callback)
		if depress.is_valid():
			depress.call(button, 0.975)
		return button

	static func _apply_text(button: Button, label_text: String, font_size: int, app_font: Font, bold_font: Font, ink: Color) -> void:
		button.text = label_text
		button.clip_contents = false
		button.add_theme_font_size_override("font_size", font_size)
		button.add_theme_color_override("font_color", ink)
		button.add_theme_color_override("font_hover_color", ink)
		button.add_theme_color_override("font_pressed_color", ink)
		button.add_theme_color_override("font_outline_color", Color.WHITE)
		button.add_theme_constant_override("outline_size", 3)
		if bold_font != null:
			button.add_theme_font_override("font", bold_font)
		elif app_font != null:
			button.add_theme_font_override("font", app_font)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	static func _sync_button(button: Button, label_text: String, active: bool, ink: Color) -> void:
		button.text = label_text
		button.add_theme_stylebox_override("normal", _style(active, false, ink))
		button.add_theme_stylebox_override("hover", _style(active, false, ink))
		button.add_theme_stylebox_override("pressed", _style(active, true, ink))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	static func _style(active: bool, pressed := false, ink := Color.BLACK) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#d8d8d8") if active else Color("#ffffff")
		if pressed:
			style.bg_color = style.bg_color.darkened(0.06)
		style.border_color = ink
		style.set_border_width_all(10)
		style.set_corner_radius_all(999)
		style.content_margin_left = 22
		style.content_margin_right = 22
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		style.shadow_size = 0
		style.shadow_color = Color.TRANSPARENT
		return style

class _UtilityCollapseArrow:
	extends Control

	var direction := -1
	var ink_color := Color("#8a6f4e")
	var stroke_width := 13.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func set_direction(next_direction: int) -> void:
		direction = 1 if next_direction >= 0 else -1
		queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var center := size * 0.5
		var width := size.x * 0.34
		var height := size.y * 0.42
		var points := PackedVector2Array()
		if direction < 0:
			points.append(Vector2(center.x + width * 0.42, center.y - height * 0.5))
			points.append(Vector2(center.x - width * 0.42, center.y))
			points.append(Vector2(center.x + width * 0.42, center.y + height * 0.5))
		else:
			points.append(Vector2(center.x - width * 0.42, center.y - height * 0.5))
			points.append(Vector2(center.x + width * 0.42, center.y))
			points.append(Vector2(center.x - width * 0.42, center.y + height * 0.5))
		draw_polyline(points, ink_color, stroke_width, true)
		for point in points:
			draw_circle(point, stroke_width * 0.5, ink_color)

class _ModuleUtilityRowBuilder:
	static func build(config: Dictionary) -> Dictionary:
		var root := Control.new()
		root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		root.offset_top = -float(config.get("bottom_nav_height", 0.0)) - float(config.get("chat_strip_height", 0.0)) - float(config.get("gap", 0.0)) - float(config.get("height", 0.0))
		root.offset_bottom = -float(config.get("bottom_nav_height", 0.0)) - float(config.get("chat_strip_height", 0.0)) - float(config.get("gap", 0.0))
		root.z_index = int(config.get("z_index", 0))
		root.z_as_relative = false
		root.visible = false
		root.mouse_filter = Control.MOUSE_FILTER_STOP

		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 18)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(row)

		var texture := config.get("texture") as Callable
		var res_path := config.get("res_path") as Callable
		var install_shell := config.get("install_shell") as Callable
		var attach_press := config.get("attach_press") as Callable
		var button_size := config.get("button_size", Vector2.ZERO) as Vector2
		var radius := float(config.get("radius", 36.0))
		var gutter := float(config.get("gutter", 0.0))
		var depth_offset := config.get("depth_offset", Vector2.ZERO) as Vector2
		var diagonal_side := str(config.get("diagonal_side", ""))
		var buttons := {}
		for raw_def in config.get("buttons", []):
			var button_def := raw_def as Dictionary
			var button := nav_button(str(button_def.get("label", "")), str(button_def.get("icon", "")), button_def.get("fill", Color.WHITE) as Color, button_size, texture, res_path, install_shell, attach_press, radius, gutter, depth_offset, diagonal_side)
			buttons[str(button_def.get("id", ""))] = button
			row.add_child(button)

		var collapse := collapse_toggle(config.get("collapse_size", Vector2.ZERO) as Vector2, attach_press)
		root.add_child(collapse)

		return {
			"root": root,
			"row": row,
			"buttons": buttons,
			"collapse_toggle": collapse
		}

	static func nav_button(label_text: String, icon_path: String, fill: Color, button_size: Vector2, texture: Callable, res_path: Callable, install_shell: Callable, attach_press: Callable, radius: float, gutter: float, depth_offset: Vector2, diagonal_side: String) -> Button:
		var button := Button.new()
		button.text = ""
		button.tooltip_text = ""
		button.custom_minimum_size = button_size
		button.clip_contents = false
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pop := install_shell.call(button, fill, radius, gutter, depth_offset, diagonal_side) as Control
		var icon := TextureRect.new()
		icon.name = "ActivityButtonIcon"
		icon.texture = texture.call(icon_path)
		icon.set_meta("source_texture_path", res_path.call(icon_path) if res_path.is_valid() else icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.anchor_left = 0.0
		icon.anchor_right = 1.0
		icon.anchor_top = 0.0
		icon.anchor_bottom = 1.0
		icon.offset_left = 12
		icon.offset_right = -12
		icon.offset_top = 9
		icon.offset_bottom = -17
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.z_index = 210
		pop.add_child(icon)
		button.set_meta("module_utility_fill", fill)
		button.set_meta("module_utility_nav_button", true)
		attach_press.call(button)
		return button

	static func collapse_toggle(toggle_size: Vector2, attach_press: Callable) -> Button:
		var button := Button.new()
		button.name = "ModuleUtilityCollapseToggle"
		button.custom_minimum_size = toggle_size
		button.size = toggle_size
		button.clip_contents = false
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_theme_stylebox_override("normal", collapse_toggle_style(false))
		button.add_theme_stylebox_override("hover", collapse_toggle_style(false))
		button.add_theme_stylebox_override("pressed", collapse_toggle_style(true))
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

		var arrow := _UtilityCollapseArrow.new()
		arrow.name = "ActivityButtonArrow"
		arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
		arrow.offset_left = 14
		arrow.offset_right = -14
		arrow.offset_top = 14
		arrow.offset_bottom = -14
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.z_index = 210
		button.add_child(arrow)
		attach_press.call(button)
		return button

	static func collapse_toggle_style(pressed := false) -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#eadfca") if pressed else Color("#fff4dd")
		style.border_color = Color("#8a6f4e")
		style.set_border_width_all(10)
		style.set_corner_radius_all(999)
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		return style

class PageSwitchChevronIcon:
	extends Control

	var direction := -1
	var ink_color := Color("#171615")
	var fill_color := Color.WHITE
	var shadow_color := Color(0.0, 0.0, 0.0, 0.18)
	var stroke_width := 50.0
	var fill_width := 31.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func set_direction(next_direction: int) -> void:
		direction = 1 if next_direction >= 0 else -1
		queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var points := _chevron_points()
		if points.size() != 3:
			return
		var shadow_points := PackedVector2Array()
		for point in points:
			shadow_points.append(point + Vector2(3.5, 4.0))
		_draw_round_chevron(shadow_points, shadow_color, stroke_width)
		_draw_round_chevron(points, ink_color, stroke_width)
		_draw_round_chevron(points, fill_color, fill_width)

	func _chevron_points() -> PackedVector2Array:
		var center := size * 0.5
		var half_width := size.x * 0.18
		var half_height := size.y * 0.36
		var points := PackedVector2Array()
		if direction < 0:
			points.append(Vector2(center.x + half_width, center.y - half_height))
			points.append(Vector2(center.x - half_width, center.y))
			points.append(Vector2(center.x + half_width, center.y + half_height))
		else:
			points.append(Vector2(center.x - half_width, center.y - half_height))
			points.append(Vector2(center.x + half_width, center.y))
			points.append(Vector2(center.x - half_width, center.y + half_height))
		return points

	func _draw_round_chevron(points: PackedVector2Array, color: Color, width: float) -> void:
		if points.size() != 3:
			return
		var radius := width * 0.5
		draw_line(points[0], points[1], color, width, true)
		draw_line(points[1], points[2], color, width, true)
		for point in points:
			draw_circle(point, radius, color)

class SkillMenuPanelChrome:
	extends Control

	var radius := 64.0
	var border_width := 9.0
	var shadow_height := 24.0
	var border_color := Color("#171615")
	var shadow_color := Color(0.05, 0.04, 0.03, 0.18)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		if radius <= 0.0:
			return
		_draw_bottom_shadow()
		_draw_border()

	func _draw_bottom_shadow() -> void:
		var bottom := maxf(0.0, size.y - border_width * 1.35)
		var top := maxf(0.0, bottom - shadow_height)
		var r := minf(radius, minf(size.x, size.y) * 0.5)
		var curve_top := size.y - r
		var lines := maxi(1, int(minf(8.0, shadow_height)))
		var step_y := shadow_height / float(lines)
		for i in range(lines):
			var y := top + float(i) * step_y
			var depth := float(i) / maxf(1.0, float(lines - 1))
			var alpha := shadow_color.a * depth * depth
			var line_left := border_width
			var line_right := size.x - border_width
			if y > curve_top:
				var dy := y - curve_top
				var chord := sqrt(maxf(0.0, r * r - dy * dy))
				var corner_inset := r - chord
				var shadow_corner_guard := border_width + 10.0
				line_left = maxf(line_left, corner_inset + shadow_corner_guard)
				line_right = minf(line_right, size.x - corner_inset - shadow_corner_guard)
			if line_right > line_left:
				draw_line(Vector2(line_left, y), Vector2(line_right, y), Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha), step_y + 1.0, false)

	func _draw_border() -> void:
		var half := border_width * 0.5
		var left := half
		var right := maxf(half, size.x - half)
		var top := half
		var bottom := maxf(half, size.y - half)
		var r := minf(radius, minf(size.x, size.y) * 0.5 - half)
		draw_line(Vector2(left + r, top), Vector2(right - r, top), border_color, border_width, true)
		draw_line(Vector2(left + r, bottom), Vector2(right - r, bottom), border_color, border_width, true)
		draw_line(Vector2(left, top + r), Vector2(left, bottom - r), border_color, border_width, true)
		draw_line(Vector2(right, top + r), Vector2(right, bottom - r), border_color, border_width, true)
		draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 8, border_color, border_width, true)
		draw_arc(Vector2(right - r, top + r), r, PI * 1.5, PI * 2.0, 8, border_color, border_width, true)
		draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 8, border_color, border_width, true)
		draw_arc(Vector2(left + r, bottom - r), r, PI * 0.5, PI, 8, border_color, border_width, true)

var host
var screen_render_in_progress := false
var screen_render_target_key := ""
var last_rendered_screen_key := ""
var pending_screen_render_request := {}
var pending_skill_detail_refresh_request := {}
var queue_return_screen := "skill"
var queue_return_skill_id := ""
var queue_return_detail_scroll := -1
var pinned_return_screen := "skill"
var pinned_return_skill_id := ""
var pinned_return_detail_scroll := -1
var skills_utility_return_screen := "skill"
var skills_utility_return_skill_id := ""
var pinned_active_shelf_header: Control
var pinned_active_shelf_background: Control
var pinned_active_shelf_skill_id := ""
var pinned_active_shelf_transition_skill_id := ""
var pinned_active_shelf_transition_active := false
var pinned_active_shelf_content: Control
var pinned_active_shelf_stamina_strip: Control
var pinned_active_shelf_stamina_gauges := {}
var pinned_active_shelf_xp_label: Label
var pinned_active_shelf_xp_bar: CleanProgressBar
var pinned_active_shelf_regen_circle: RegenCircle
var pinned_active_shelf_fish_circle: FishCircle
var pinned_active_shelf_tween: Tween
var pinned_active_shelf_height_tween: Tween
var pin_transition_blocker: ColorRect
var pin_transition_blocker_tween: Tween
var pin_transition_blocker_target_screen := ""
var pin_transition_blocker_started_msec := 0
var pin_transition_blocker_release_started := false
var pin_transition_blocker_fade_in_done := false
var top_level_nav_locked_until_msec := 0
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
var nav_bar: PanelContainer
var bottom_nav_buttons_row: HBoxContainer
var hero_tab: Button
var hub_tab: Button
var chat_home_tab: Button
var chat_hub_tab: Button
var chat_shop_tab: Button
var shop_tab: Button
var bottom_nav_open_close_return_to_skill_active := false
var post_onboarding_bottom_chrome_fade_tween: Tween
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
var skill_menu_active_drawers := {}
var skill_menu_cache_overlay: Control
var skill_menu_page_cache := {}
var skill_menu_return_state := {}
var skill_menu_cache_dark_mode := false

func _init(next_host) -> void:
	host = next_host


func cancel_post_onboarding_bottom_chrome_fade() -> void:
	if post_onboarding_bottom_chrome_fade_tween != null and post_onboarding_bottom_chrome_fade_tween.is_valid():
		post_onboarding_bottom_chrome_fade_tween.kill()
	post_onboarding_bottom_chrome_fade_tween = null


func _fade_in_post_onboarding_bottom_chrome() -> void:
	if not host._onboarding_runtime().onboarding_tutorial_complete:
		return
	module_utility_collapsed = true
	host._profile_chat_overlay_surface()._ensure_chat_strip()
	host._profile_chat_overlay_surface()._update_chat_strip(true)
	_sync_module_utility_row_visibility(false)
	cancel_post_onboarding_bottom_chrome_fade()
	var fade_targets := []
	for raw_control in [host._profile_chat_overlay_surface().chat_strip_control(), module_utility_row]:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control) or not control.visible:
			continue
		control.modulate.a = 0.0
		fade_targets.append(control)
	if fade_targets.is_empty():
		return
	post_onboarding_bottom_chrome_fade_tween = host.create_tween()
	var first := fade_targets[0] as Control
	post_onboarding_bottom_chrome_fade_tween.tween_property(first, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for index in range(1, fade_targets.size()):
		var control := fade_targets[index] as Control
		post_onboarding_bottom_chrome_fade_tween.parallel().tween_property(control, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	post_onboarding_bottom_chrome_fade_tween.finished.connect(_finish_post_onboarding_bottom_chrome_fade)


func _finish_post_onboarding_bottom_chrome_fade() -> void:
	post_onboarding_bottom_chrome_fade_tween = null


func _intro_bottom_controls_unlocked() -> bool:
	return host._onboarding_runtime().onboarding_tutorial_complete and not host._onboarding_runtime().tutorial_active


func _hero_unlocked() -> bool:
	return SkillState.global_level(host.skills) >= HERO_UNLOCK_TOTAL_LEVEL


func _hub_unlocked() -> bool:
	return SkillState.host_skill_level(host, "build") >= HUB_UNLOCK_BUILD_LEVEL


func _shop_unlocked() -> bool:
	var tiers := AchievementState.all_medal_tier_counts(host)
	if tiers.is_empty():
		return false
	return int(tiers[0]) >= SHOP_UNLOCK_BRONZE_MEDALS


func _event_points_inside_bottom_nav(event: InputEvent, source: Control = null) -> bool:
	return host._input_routing_shell()._event_points_inside_bottom_interactive_ui(event, source, true)


func _position_inside_bottom_nav(event_position: Vector2) -> bool:
	if nav_bar == null or not is_instance_valid(nav_bar) or not nav_bar.is_visible_in_tree():
		return false
	var nav_rect: Rect2 = nav_bar.get_global_rect().grow(4.0)
	return nav_rect.has_point(event_position)


func _build_ui_shell() -> void:
	var root := ColorRect.new()
	host.app_background_rect = root
	root.color = host._theme_paper_color()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(root)

	host.home_page = Control.new()
	host.home_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.home_page.offset_bottom = -BOTTOM_NAV_HEIGHT
	host.add_child(host.home_page)

	host.skills_page = Control.new()
	host.skills_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.skills_page.offset_bottom = -BOTTOM_NAV_HEIGHT
	host.skills_page.clip_contents = true
	host.add_child(host.skills_page)
	host._skill_swipe_activity_surface()._ensure_skill_swipe_paper_fade_overlay()


func _update_page_visibility() -> void:
	if host.current_screen != "menu":
		_deactivate_skill_menu_page_cache()
	host.home_page.visible = host.current_screen == "home"
	host.skills_page.visible = host.current_screen != "home"
	_refresh_hero_nav_unlock_state()
	_refresh_hub_nav_unlock_state()
	_refresh_shop_nav_unlock_state()
	_apply_nav_style(hero_tab, host.current_screen == "home" or host.current_screen == "achievements")
	_apply_nav_style(hub_tab, host.current_screen == "hub")
	_apply_nav_style(host.skills_tab, host.current_screen == "menu" or host.current_screen == "skill" or host.current_screen == "pinned")
	_apply_nav_style(shop_tab, host.current_screen == "shop")
	_apply_nav_style(host.settings_tab, host.current_screen == "settings")
	host._profile_chat_overlay_surface()._update_chat_strip()
	host._onboarding_runtime()._tutorial_check_progress()
	host._tutorial_overlay_surface()._sync_tutorial_target_indicator()


func _build_nav_bar() -> void:
	nav_bar = PanelContainer.new()
	nav_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav_bar.offset_top = -BOTTOM_NAV_HEIGHT
	nav_bar.z_index = ProfileChatOverlaySurface.CHAT_UI_Z
	nav_bar.z_as_relative = false
	nav_bar.clip_contents = true
	nav_bar.add_theme_stylebox_override("panel", _nav_style())
	host.add_child(nav_bar)
	var row := HBoxContainer.new()
	row.name = "BottomNavButtonsRow"
	bottom_nav_buttons_row = row
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 60)
	row.clip_contents = true
	row.custom_minimum_size = Vector2(0, BOTTOM_NAV_HEIGHT - BOTTOM_NAV_SAFE_PAD)
	nav_bar.add_child(row)
	hero_tab = _nav_button(host.PROGRESS_STAR_ICON_TEXTURE, true)
	hero_tab.custom_minimum_size = Vector2(159, 159)
	hero_tab.add_theme_constant_override("icon_max_width", 122)
	_register_nav_new_symbol_dot(hero_tab, "hero")
	hero_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	hero_tab.pressed.connect(_activate_bottom_nav_target.bind("home", hero_tab))
	hero_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("home", hero_tab))
	row.add_child(hero_tab)
	_sync_hero_nav_button(true)
	hub_tab = _nav_button("res://assets/content/hub/hub-nav-barn.png", true)
	hub_tab.add_theme_constant_override("icon_max_width", 110)
	_register_nav_new_symbol_dot(hub_tab, "hub")
	hub_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	hub_tab.pressed.connect(_activate_bottom_nav_target.bind("hub", hub_tab))
	hub_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("hub", hub_tab))
	row.add_child(hub_tab)
	_sync_hub_nav_button(true)
	host.skills_tab = _nav_button(host.TOTAL_LEVEL_BARGRAPH_TEXTURE, true)
	host.skills_tab.set_meta("nav_open_icon_disabled", true)
	host.skills_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	host.skills_tab.pressed.connect(_show_skills_module)
	host.skills_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("skill", host.skills_tab))
	row.add_child(host.skills_tab)
	host.settings_tab = _nav_button(host.SETTINGS_GEAR_ICON_TEXTURE, true)
	host.settings_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	host.settings_tab.pressed.connect(_activate_bottom_nav_target.bind("settings", host.settings_tab))
	host.settings_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("settings", host.settings_tab))
	row.add_child(host.settings_tab)
	shop_tab = _nav_button(host.SHOP_ICON_TEXTURE, true)
	shop_tab.add_theme_constant_override("icon_max_width", 116)
	_register_nav_new_symbol_dot(shop_tab, "shop")
	shop_tab.set_meta("bottom_nav_builtin_pressed_route", true)
	shop_tab.pressed.connect(_activate_bottom_nav_target.bind("shop", shop_tab))
	shop_tab.gui_input.connect(Callable(self, "_on_bottom_nav_button_gui_input").bind("shop", shop_tab))
	row.add_child(shop_tab)
	shop_nav_unlocked = false
	shop_tab.modulate = HUB_NAV_LOCKED_MODULATE
	_sync_bottom_nav_visibility()


func _ensure_nav_bar_icons() -> void:
	for button in [hero_tab, hub_tab, host.skills_tab, host.settings_tab, shop_tab]:
		if button == null or not is_instance_valid(button):
			continue
		var path := str(button.get_meta("deferred_icon_path", ""))
		if path.is_empty():
			continue
		button.remove_meta("deferred_icon_path")
		button.icon = host.visual_texture_cache._texture_or_visual_fallback(path)
		button.set_meta("nav_current_icon_path", path)
		_ensure_nav_icon_stroke(button)


func _nav_button(path: String, defer_icon := false) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(134, 134)
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
	button.add_theme_constant_override("icon_max_width", 92)
	_apply_nav_style(button, false)
	var button_id := button.get_instance_id()
	host.button_press_runtime.attach_button_depress_animation(button, 0.92, false)
	button.pressed.connect(host.button_press_runtime._pop_nav_button_bound.bind(button_id))
	return button


func _set_nav_button_icon(button: Button, path: String) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.icon = host.visual_texture_cache._texture_or_visual_fallback(path)
	button.set_meta("nav_current_icon_path", path)
	_ensure_nav_icon_stroke(button)


func _sync_nav_button_open_icon(button: Button, active: bool) -> void:
	if button == null or not is_instance_valid(button):
		return
	var default_path := str(button.get_meta("nav_default_icon_path", ""))
	if default_path.is_empty():
		return
	var target_path := default_path
	if active and not bool(button.get_meta("nav_open_icon_disabled", false)):
		target_path = NAV_OPEN_CLOSE_ICON_TEXTURE
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
	style.border_width_top = 7.5
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 18
	style.content_margin_bottom = BOTTOM_NAV_SAFE_PAD
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
	_ensure_nav_icon_stroke(button)
	_sync_nav_button_open_icon(button, _active)


func _ensure_nav_icon_stroke(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var stroke: TextureRect = null
	if button.has_meta("nav_icon_stroke"):
		stroke = button.get_meta("nav_icon_stroke") as TextureRect
	if stroke == null or not is_instance_valid(stroke):
		stroke = TextureRect.new()
		stroke.name = "NavIconStroke"
		stroke.anchor_left = 0.5
		stroke.anchor_right = 0.5
		stroke.anchor_top = 0.5
		stroke.anchor_bottom = 0.5
		stroke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stroke.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stroke.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stroke.z_index = -1
		stroke.modulate = host.COLOR_INK
		button.add_child(stroke)
		button.set_meta("nav_icon_stroke", stroke)
	var icon_size := float(button.get_theme_constant("icon_max_width"))
	var stroke_width := ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
	var outer_size := Vector2(icon_size + stroke_width, icon_size + stroke_width)
	stroke.offset_left = -outer_size.x * 0.5
	stroke.offset_right = outer_size.x * 0.5
	stroke.offset_top = -outer_size.y * 0.5
	stroke.offset_bottom = outer_size.y * 0.5
	stroke.texture = button.icon


func _sync_bottom_nav_visibility() -> void:
	if nav_bar == null or not is_instance_valid(nav_bar):
		return
	var controls_unlocked: bool = _intro_bottom_controls_unlocked()
	nav_bar.visible = true
	if bottom_nav_buttons_row != null and is_instance_valid(bottom_nav_buttons_row):
		bottom_nav_buttons_row.visible = true
	if controls_unlocked:
		if hero_tab != null and is_instance_valid(hero_tab):
			hero_tab.visible = true
			hero_tab.disabled = false
			hero_tab.mouse_filter = Control.MOUSE_FILTER_STOP
			hero_tab.self_modulate = Color.WHITE
		if hub_tab != null and is_instance_valid(hub_tab):
			hub_tab.visible = true
			hub_tab.disabled = false
			hub_tab.mouse_filter = Control.MOUSE_FILTER_STOP
			hub_tab.self_modulate = Color.WHITE
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
		if shop_tab != null and is_instance_valid(shop_tab):
			shop_tab.visible = true
			shop_tab.disabled = false
			shop_tab.mouse_filter = Control.MOUSE_FILTER_STOP
			shop_tab.self_modulate = Color.WHITE
		_sync_hero_nav_button(true)
		_sync_hub_nav_button(true)
		_sync_shop_nav_button(true)
		return
	for raw_button in [hero_tab, hub_tab, host.skills_tab, host.settings_tab, shop_tab]:
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
			button.modulate = HUB_NAV_LOCKED_MODULATE
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_STOP if controls_unlocked or settings_button or skills_button else Control.MOUSE_FILTER_IGNORE


func _on_bottom_nav_button_gui_input(event: InputEvent, target_screen: String, button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if _bottom_nav_transition_input_locked(button):
		return
	var event_position: Vector2 = host._input_routing_shell()._passive_button_event_position(event, button)
	var event_kind := ButtonPressState.event_kind(event)
	if event_kind == "press":
		ButtonPressState.begin(button, "bottom_nav", event_position)
		return
	if event_kind == "drag":
		ButtonPressState.update_drag(button, "bottom_nav", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
		if _handoff_bottom_nav_drag_to_skill_swipe(button, event, event_position):
			return
		return
	if event_kind != "release":
		return
	if not ButtonPressState.finish(button, "bottom_nav", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, 24.0):
		return
	_arm_bottom_nav_clean_activation(button, target_screen)
	_activate_bottom_nav_target(target_screen, button)


func _handoff_bottom_nav_drag_to_skill_swipe(button: Button, event: InputEvent, event_position: Vector2) -> bool:
	if host.current_screen != "skill":
		return false
	if not ButtonPressState.active(button, "bottom_nav"):
		return false
	var press_position = button.get_meta("bottom_nav_press_position", event_position)
	if not (press_position is Vector2):
		return false
	if event_position.distance_to(press_position) <= host.PASSIVE_BUTTON_TAP_RELEASE_SLOP:
		return false
	ButtonPressState.clear(button, "bottom_nav")
	host.button_press_runtime.animate_button_release(button)
	var touch_index := (event as InputEventScreenDrag).index if event is InputEventScreenDrag else -1
	host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(press_position, touch_index)
	if host._skill_swipe_activity_surface().skill_swipe_tracking:
		host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event_position)
	return true


func _route_bottom_nav_button_global_input(event: InputEvent) -> bool:
	if nav_bar == null or not is_instance_valid(nav_bar):
		return false
	if not nav_bar.is_inside_tree() or not nav_bar.is_visible_in_tree():
		return false
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	var event_position: Vector2 = host._input_routing_shell()._passive_button_event_position(event, null)
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
	if not host._skill_swipe_activity_surface().skill_swipe_tracking:
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	host._fishing_ui_surface()._clear_active_fishing_method_button_press()
	host._skill_detail_surface().action_card_press_key = ""
	return true


func _bottom_nav_button_at_position(event_position: Vector2) -> Button:
	for raw_button in [hero_tab, hub_tab, host.skills_tab, host.settings_tab, shop_tab]:
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
	for raw_button in [hero_tab, hub_tab, host.skills_tab, host.settings_tab, shop_tab]:
		var button := raw_button as Button
		if ButtonPressState.active(button, "bottom_nav"):
			return button
	return null


func _bottom_nav_target_for_button(button: Button) -> String:
	if button == hero_tab:
		return "home"
	if button == hub_tab:
		return "hub"
	if button == host.skills_tab:
		return "skill"
	if button == host.settings_tab:
		return "settings"
	if button == shop_tab:
		return "shop"
	return ""


func _bottom_nav_target_locked(target_screen: String) -> bool:
	match target_screen:
		"home":
			return not _hero_unlocked()
		"hub":
			return not _hub_unlocked()
		"shop":
			return not _shop_unlocked()
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
	var diameter: float = ProfileChatOverlaySurface.CHAT_UNREAD_DOT_DIAMETER
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
	dot.add_theme_stylebox_override("panel", ProfileChatOverlaySurface.chat_unread_dot_style())
	button.add_child(dot)
	return dot


func _nav_symbol_unlocked(nav_id: String) -> bool:
	match nav_id:
		"hero":
			return _hero_unlocked()
		"hub":
			return _hub_unlocked()
		"shop":
			return _shop_unlocked()
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
				host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(dot, should_show)


func _nav_symbol_buttons(nav_id: String) -> Array:
	match nav_id:
		"hero":
			return [hero_tab, chat_home_tab]
		"hub":
			return [hub_tab, chat_hub_tab]
		"shop":
			return [shop_tab, chat_shop_tab]
	return []


func _sync_hero_nav_button(instant := false) -> void:
	if hero_tab == null or not is_instance_valid(hero_tab):
		return
	var unlocked: bool = _hero_unlocked()
	var target_modulate: Color = Color.WHITE if unlocked else HUB_NAV_LOCKED_MODULATE
	hero_nav_unlocked = unlocked
	hero_tab.tooltip_text = ""
	if chat_home_tab != null and is_instance_valid(chat_home_tab):
		chat_home_tab.tooltip_text = ""
	if hero_nav_fade_tween != null and hero_nav_fade_tween.is_valid():
		hero_nav_fade_tween.kill()
		hero_nav_fade_tween = null
	if instant:
		hero_tab.modulate = target_modulate
		if chat_home_tab != null and is_instance_valid(chat_home_tab):
			chat_home_tab.modulate = target_modulate
		_sync_nav_new_symbol_dot("hero")
		return
	hero_nav_fade_tween = host.create_tween()
	hero_nav_fade_tween.tween_property(hero_tab, "modulate", target_modulate, HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if chat_home_tab != null and is_instance_valid(chat_home_tab):
		hero_nav_fade_tween.parallel().tween_property(chat_home_tab, "modulate", target_modulate, HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sync_nav_new_symbol_dot("hero")
	hero_nav_fade_tween.finished.connect(_finish_hero_nav_fade_tween)


func _finish_hero_nav_fade_tween() -> void:
	hero_nav_fade_tween = null


func _refresh_hero_nav_unlock_state() -> void:
	if hero_tab == null or not is_instance_valid(hero_tab):
		return
	var unlocked: bool = _hero_unlocked()
	if unlocked == hero_nav_unlocked:
		return
	_sync_hero_nav_button(not unlocked)


func _show_hero_locked_message(source_button: Control = null) -> void:
	host._reward_feedback_surface()._set_result(HERO_LOCKED_MESSAGE, false)
	var anchor: Control = source_button
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		anchor = hero_tab
	if anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree():
		_float_nav_locked_message(anchor, HERO_LOCKED_MESSAGE)


func _sync_shop_nav_button(instant := false) -> void:
	if shop_tab == null or not is_instance_valid(shop_tab):
		return
	var unlocked: bool = _shop_unlocked()
	var target_modulate: Color = Color.WHITE if unlocked else HUB_NAV_LOCKED_MODULATE
	shop_nav_unlocked = unlocked
	shop_tab.tooltip_text = ""
	if chat_shop_tab != null and is_instance_valid(chat_shop_tab):
		chat_shop_tab.tooltip_text = ""
	if shop_nav_fade_tween != null and shop_nav_fade_tween.is_valid():
		shop_nav_fade_tween.kill()
		shop_nav_fade_tween = null
	if instant:
		shop_tab.modulate = target_modulate
		if chat_shop_tab != null and is_instance_valid(chat_shop_tab):
			chat_shop_tab.modulate = target_modulate
		_sync_nav_new_symbol_dot("shop")
		return
	shop_nav_fade_tween = host.create_tween()
	shop_nav_fade_tween.tween_property(shop_tab, "modulate", target_modulate, HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if chat_shop_tab != null and is_instance_valid(chat_shop_tab):
		shop_nav_fade_tween.parallel().tween_property(chat_shop_tab, "modulate", target_modulate, HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sync_nav_new_symbol_dot("shop")
	shop_nav_fade_tween.finished.connect(_finish_shop_nav_fade_tween)


func _finish_shop_nav_fade_tween() -> void:
	shop_nav_fade_tween = null


func _refresh_shop_nav_unlock_state() -> void:
	if shop_tab == null or not is_instance_valid(shop_tab):
		return
	var unlocked: bool = _shop_unlocked()
	if unlocked == shop_nav_unlocked:
		return
	_sync_shop_nav_button(not unlocked)


func _show_shop_locked_message(source_button: Control = null) -> void:
	host._reward_feedback_surface()._set_result(SHOP_LOCKED_MESSAGE, false)
	var anchor: Control = source_button
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		anchor = shop_tab
	if anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree():
		_float_nav_locked_message(anchor, SHOP_LOCKED_MESSAGE)


func _sync_hub_nav_button(instant := false) -> void:
	if hub_tab == null or not is_instance_valid(hub_tab):
		return
	var unlocked: bool = _hub_unlocked()
	var target_modulate: Color = Color.WHITE if unlocked else HUB_NAV_LOCKED_MODULATE
	hub_nav_unlocked = unlocked
	hub_tab.tooltip_text = ""
	if chat_hub_tab != null and is_instance_valid(chat_hub_tab):
		chat_hub_tab.tooltip_text = ""
	if hub_nav_fade_tween != null and hub_nav_fade_tween.is_valid():
		hub_nav_fade_tween.kill()
		hub_nav_fade_tween = null
	if instant:
		hub_tab.modulate = target_modulate
		if chat_hub_tab != null and is_instance_valid(chat_hub_tab):
			chat_hub_tab.modulate = target_modulate
		_sync_nav_new_symbol_dot("hub")
		return
	hub_nav_fade_tween = host.create_tween()
	hub_nav_fade_tween.tween_property(hub_tab, "modulate", target_modulate, HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if chat_hub_tab != null and is_instance_valid(chat_hub_tab):
		hub_nav_fade_tween.parallel().tween_property(chat_hub_tab, "modulate", target_modulate, HUB_NAV_UNLOCK_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sync_nav_new_symbol_dot("hub")
	hub_nav_fade_tween.finished.connect(_finish_hub_nav_fade_tween)


func _finish_hub_nav_fade_tween() -> void:
	hub_nav_fade_tween = null


func _refresh_hub_nav_unlock_state() -> void:
	if hub_tab == null or not is_instance_valid(hub_tab):
		return
	var unlocked: bool = _hub_unlocked()
	if unlocked == hub_nav_unlocked:
		return
	_sync_hub_nav_button(not unlocked)


func _show_hub_locked_message(source_button: Control = null) -> void:
	host._reward_feedback_surface()._set_result(HUB_LOCKED_MESSAGE, false)
	var anchor: Control = source_button
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		anchor = hub_tab
	if anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree():
		_float_nav_locked_message(anchor, HUB_LOCKED_MESSAGE)


func _float_nav_locked_message(anchor: Control, text: String) -> void:
	if (
		anchor == null
		or not is_instance_valid(anchor)
		or anchor.is_queued_for_deletion()
		or not anchor.is_visible_in_tree()
	):
		return
	var holder_size := Vector2(215, 56)
	var holder := Control.new()
	holder.z_index = ProfileChatOverlaySurface.CHAT_UI_Z + 20
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = holder_size
	host.add_child(holder)
	var shadow: Label = host._label(text, 58, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = holder_size
	shadow.position = Vector2(2, 2.5)
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
	host._reward_feedback_surface()._start_reward_float_tween(holder, Vector2(0, -17), 0.0)


func _is_bottom_nav_button(button: Control) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	return button == hero_tab or button == hub_tab or button == host.skills_tab or button == host.settings_tab or button == shop_tab


func _bottom_nav_transition_input_locked(button: Button = null) -> bool:
	var button_press_runtime: ButtonPressState = host.button_press_runtime
	if not button_press_runtime.bottom_nav_transition_active():
		return false
	if not _bottom_nav_transition_visual_active():
		button_press_runtime.release_bottom_nav_transition_button()
		return false
	if button != null and is_instance_valid(button):
		button_press_runtime.force_button_unpressed(button)
	return true


func _bottom_nav_transition_visual_active() -> bool:
	if host._skill_swipe_activity_surface().direct_skill_nav_cover_active or host._skill_swipe_activity_surface().skill_swipe_outgoing_cover_active or host._skill_swipe_activity_surface().skill_swipe_rebuild_cover_active or host._skill_swipe_activity_surface().skill_detail_refresh_cover_active:
		return true
	if host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_cream_transition() or _page_switch_scroll_cover_active():
		return true
	if pin_transition_blocker != null and is_instance_valid(pin_transition_blocker) and pin_transition_blocker.visible:
		return true
	return screen_render_in_progress or not pending_screen_render_request.is_empty()


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
	var button_press_runtime: ButtonPressState = host.button_press_runtime
	if button_press_runtime.bottom_nav_transition_visual_active(Callable(self, "_bottom_nav_transition_visual_active")):
		if nav_button != null and is_instance_valid(nav_button):
			button_press_runtime.force_button_unpressed(nav_button)
		return
	if _is_bottom_nav_button(nav_button) and _bottom_nav_target_locked(target_screen):
		button_press_runtime.force_button_unpressed(nav_button)
		_show_bottom_nav_locked_message(target_screen, source_button)
		return
	if _is_bottom_nav_button(nav_button) and not _consume_bottom_nav_clean_activation(nav_button, target_screen):
		button_press_runtime.force_button_unpressed(nav_button)
		return
	host._skill_swipe_activity_surface()._clear_queued_skill_swipe_navigation()
	if _is_bottom_nav_button(nav_button):
		button_press_runtime.hold_bottom_nav_transition_button(nav_button)
		button_press_runtime._schedule_bottom_nav_transition_button_idle_release()
	if _bottom_nav_open_close_returns_to_skill(target_screen, source_button):
		_clear_top_level_nav_lock()
		bottom_nav_open_close_return_to_skill_active = true
		_show_skills_module()
		bottom_nav_open_close_return_to_skill_active = false
		return
	if target_screen == "settings" and host.current_screen == "settings":
		_clear_top_level_nav_lock()
		host._settings_surface()._return_from_settings_page()
		return
	match target_screen:
		"home":
			_show_home(source_button)
		"hub":
			_show_hub(source_button)
		"skill":
			_show_skills_module()
		"settings":
			host._settings_surface()._show_settings()
		"shop":
			_show_shop(source_button)


func _show_home(source_button: Control = null) -> void:
	if not _top_level_nav_allowed("home"):
		return
	if not _hero_unlocked():
		_show_hero_locked_message(source_button)
		return
	_mark_nav_symbol_seen("hero")
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	if host.current_screen == "skill":
		host._onboarding_runtime()._complete_passive_module_tip_page_visit()
		host._onboarding_runtime()._complete_silver_opportunity_tip_page_visit()
	host.current_screen = "home"
	host._reward_feedback_surface()._clear_skill_reward_floats()
	_update_page_visibility()
	if not host._achievement_overlay_surface().home_page_built:
		call_deferred("_finish_show_home")
		return
	_finish_show_home()


func _finish_show_home() -> void:
	if host.current_screen != "home":
		return
	host._achievement_overlay_surface().ensure_home_page(host.home_page)
	_update_page_visibility()
	host._achievement_overlay_surface().scroll_home_to_top()
	host._achievement_overlay_surface()._queue_home_achievement_refresh()


func _show_skills(use_page_cover := false) -> void:
	if host.current_screen == "menu":
		return
	if not _top_level_nav_allowed("menu"):
		return
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	if host.current_screen == "skill":
		host._onboarding_runtime()._complete_passive_module_tip_page_visit()
		host._onboarding_runtime()._complete_silver_opportunity_tip_page_visit()
	if use_page_cover:
		var cover_id := _begin_page_switch_scroll_cover_timed()
		if cover_id == 0:
			_complete_show_skills()
		else:
			_queue_page_switch_transition("show_skills", cover_id)
		return
	_complete_show_skills()


func _complete_show_skills() -> void:
	if _activate_skill_menu_page_cache():
		_fade_clear_page_switch_scroll_cover()
		return
	host.current_screen = "menu"
	await _render_screen()
	_fade_clear_page_switch_scroll_cover()


func _select_launch_skill_page() -> void:
	if host._onboarding_runtime()._onboarding_path_active():
		host.selected_skill_id = host.TUTORIAL_STARTER_SKILL_ID
		host.current_screen = "skill"
		return
	if not host.running_skill_id.is_empty() and host.skills.has(host.running_skill_id) and not host._action_data(host.running_skill_id, host.running_action_id).is_empty():
		host.selected_skill_id = host.running_skill_id
		host.current_screen = "skill"
		return
	var best_skill_id: String = host.selected_skill_id
	var best_level := -1
	var best_xp := -1
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		var skill_level := SkillState.host_skill_level(host, skill_id)
		var skill_xp := int(host.skills.get(skill_id, {}).get("xp", 0))
		if best_skill_id.is_empty() or skill_level > best_level or (skill_level == best_level and skill_xp > best_xp):
			best_skill_id = skill_id
			best_level = skill_level
			best_xp = skill_xp
	if host.skills.has(best_skill_id):
		host.selected_skill_id = best_skill_id
	host.current_screen = "skill"


func _select_skill(skill_id: String) -> void:
	if host._consume_skill_menu_gauge_parent_suppression(skill_id):
		return
	_select_skill_with_initial_scroll(skill_id, true, -1)


func _select_skill_from_page_switch(skill_id: String, source_button: Button = null) -> void:
	if _page_switch_transition_active():
		return
	if host._onboarding_runtime()._onboarding_path_active() and not host._onboarding_runtime()._onboarding_swipe_to_other_skills_allowed():
		if not host._onboarding_runtime().onboarding_swipe_tip_sequence_running:
			host._tutorial_overlay_surface().call_deferred("_run_onboarding_swipe_tip_sequence")
		_release_page_switch_transition_button()
		return
	_complete_onboarding_swipe_navigation_attempt(skill_id)
	if source_button != null and is_instance_valid(source_button) and page_switch_transition_button_id == 0:
		_hold_page_switch_transition_button(source_button, skill_id)
	_begin_page_switch_scroll_cover()
	var cover: Control = host._skill_swipe_activity_surface().skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_release_page_switch_transition_button()
		_select_skill_with_initial_scroll(skill_id, false, host.DETAIL_RESTORE_SCROLL_BOTTOM, false)
		return
	var cover_id: int = cover.get_instance_id()
	_queue_page_switch_transition("select_skill", cover_id, {
		"skill_id": skill_id,
		"scroll_latest_activity": false,
		"restore_detail_scroll": host.DETAIL_RESTORE_SCROLL_BOTTOM,
		"play_nav_sfx": false,
	})


func _complete_onboarding_swipe_navigation_attempt(target_skill_id: String) -> void:
	if not host._onboarding_runtime()._onboarding_path_active():
		return
	if host.selected_skill_id != host.TUTORIAL_STARTER_SKILL_ID or target_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		return
	if not host._onboarding_runtime().onboarding_swipe_navigation_unlocked:
		return
	host._tutorial_overlay_surface()._fade_tip_group("skill_swipe_tip_notes", false, true)
	host._tutorial_overlay_surface().fade_out_onboarding_swipe_overlay_tip()
	host._onboarding_runtime()._mark_skill_swipe_tip_seen()


func _select_skill_with_initial_scroll(skill_id: String, scroll_latest_activity: bool, restore_detail_scroll: int, play_nav_sfx := true) -> void:
	if screen_render_in_progress or (host._skill_swipe_loading_transition_active() and not _page_switch_scroll_cover_active()):
		return
	if not host._onboarding_runtime()._onboarding_skill_accessible(skill_id):
		var card := host.skill_cards.get(skill_id, {}) as Dictionary
		var source := card.get("button") as Control
		host._onboarding_runtime()._show_onboarding_skill_locked_message(source)
		return
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	if skill_id != host.selected_skill_id and host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		host._onboarding_runtime()._clear_tutorial_gate_latch_only_after_skill_swipe(false)
	if host.current_screen != "skill":
		host._skill_swipe_activity_surface()._begin_direct_skill_nav_cover()
	host.selected_skill_id = skill_id
	host.current_screen = "skill"
	if play_nav_sfx:
		host.button_press_runtime.play_default_button_sfx()
	if host._onboarding_runtime().tutorial_active and host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		host.action_cards.clear()
		host.action_card_keys.clear()
		host._skill_detail_surface().detail_action_card_nodes.clear()
		host._skill_detail_surface().detail_rendered_action_ids.clear()
		host._skill_detail_surface().detail_lazy_plan.clear()
		_render_screen(false, 0)
	else:
		_render_screen(scroll_latest_activity, restore_detail_scroll)
	if _page_switch_scroll_cover_active():
		call_deferred("_fade_clear_page_switch_scroll_cover")


func _show_skills_module() -> void:
	if host.current_screen == "skill":
		return
	if not _top_level_nav_allowed("skill"):
		return
	var previous_screen: String = host.current_screen
	var can_reveal_current_skill_page: bool = previous_screen == "home" or previous_screen == "achievements"
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
		if bottom_nav_open_close_return_to_skill_active:
			if not host._settings_surface().settings_return_skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, host._settings_surface().settings_return_skill_id):
				host.selected_skill_id = host._settings_surface().settings_return_skill_id
			host.current_screen = "skill"
		else:
			_select_launch_skill_page()
	elif not SkillState.has_skill_id(host.skill_defs, host.selected_skill_id):
		_select_launch_skill_page()
	else:
		host.current_screen = "skill"
	if can_reveal_current_skill_page and not host._onboarding_runtime()._onboarding_path_active():
		if _try_reveal_current_skill_page(_screen_page_cache_key(host.current_screen), true):
			return
	_render_screen(true)
	if host._onboarding_runtime()._onboarding_path_active():
		host._onboarding_runtime().call_deferred("_resync_onboarding_skill_detail_after_navigation")


func _show_hub(source_button: Control = null) -> void:
	if not _top_level_nav_allowed("hub"):
		return
	if not _hub_unlocked():
		_show_hub_locked_message(source_button)
		return
	_mark_nav_symbol_seen("hub")
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	host.current_screen = "hub"
	host._hub_surface().hub_detail_open = false
	_render_screen()


func _show_shop(source_button: Control = null) -> void:
	if not _top_level_nav_allowed("shop"):
		return
	if source_button != null and not _shop_unlocked():
		_show_shop_locked_message(source_button)
		return
	if _shop_unlocked():
		_mark_nav_symbol_seen("shop")
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	host.current_screen = "shop"
	_render_screen()


func _clear_top_level_nav_lock() -> void:
	top_level_nav_locked_until_msec = 0


func _top_level_nav_allowed(target_screen: String) -> bool:
	var now := Time.get_ticks_msec()
	if screen_render_in_progress or host._skill_swipe_loading_transition_active():
		return false
	if now < top_level_nav_locked_until_msec:
		return false
	if host.current_screen == target_screen:
		return false
	top_level_nav_locked_until_msec = now + TOP_LEVEL_NAV_DEBOUNCE_MSEC
	return true


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


func _reset_page_control_refs() -> void:
	host.skill_cards.clear()
	skill_menu_active_drawers.clear()
	host._skill_detail_surface()._clear_detail_lazy_cache_bin()
	host._skill_swipe_activity_surface()._clear_action_pop_tweens()
	host._reward_feedback_surface()._clear_action_crit_tweens()
	host._reward_feedback_surface()._clear_stamina_gauge_pop_tween()
	host._activity_unlock_ceremony_surface().clear_visual_scroll_tween()
	host.action_cards.clear()
	host.action_card_keys.clear()
	host.content_scroll = null
	host._skill_detail_surface().detail_xp_label = null
	host._skill_detail_surface().detail_xp_bar = null
	host._skill_detail_surface().detail_regen_circle = null
	host._skill_detail_surface().detail_regen_circle_host = null
	host._skill_detail_surface().detail_regen_circle_fade_group = null
	host._skill_detail_surface().detail_fish_circle = null
	host._skill_detail_surface().detail_blue_guy_health_gauge = null
	host._skill_detail_surface().detail_auto_eat_fish_button = null
	pinned_active_shelf_header = null
	pinned_active_shelf_background = null
	pinned_active_shelf_skill_id = ""
	pinned_active_shelf_transition_skill_id = ""
	pinned_active_shelf_transition_active = false
	pinned_active_shelf_content = null
	pinned_active_shelf_stamina_strip = null
	pinned_active_shelf_stamina_gauges.clear()
	pinned_active_shelf_xp_label = null
	pinned_active_shelf_xp_bar = null
	pinned_active_shelf_regen_circle = null
	pinned_active_shelf_fish_circle = null
	if pinned_active_shelf_tween != null and pinned_active_shelf_tween.is_valid():
		pinned_active_shelf_tween.kill()
	pinned_active_shelf_tween = null
	if pinned_active_shelf_height_tween != null and pinned_active_shelf_height_tween.is_valid():
		pinned_active_shelf_height_tween.kill()
	pinned_active_shelf_height_tween = null
	host._skill_detail_surface().detail_stamina_bar = null
	host._skill_detail_surface().detail_header_body = null
	host._skill_detail_surface().detail_header_left_block = null
	host._skill_detail_surface().detail_actions_scroll = null
	host._skill_detail_surface().detail_actions_top_spacer = null
	if host._skill_detail_surface().onboarding_first_module_spacer_tween != null and host._skill_detail_surface().onboarding_first_module_spacer_tween.is_valid():
		host._skill_detail_surface().onboarding_first_module_spacer_tween.kill()
	host._skill_detail_surface().onboarding_first_module_spacer_tween = null
	host._skill_detail_surface().detail_unlock_scroll_spacer = null
	host._skill_detail_surface().detail_shelf_shadow_overlay = null
	host._skill_detail_surface()._clear_detail_back_arrow_state()
	host._skill_detail_surface()._clear_detail_jump_arrow_state()
	host._audio_director().chain_audio_scroll_direction = 0
	host._audio_director().chain_audio_scroll_focus_seconds = 0.0
	host._skill_detail_surface().detail_action_card_nodes.clear()
	host._skill_detail_surface().detail_rendered_action_ids.clear()
	host._skill_detail_surface().detail_lazy_plan.clear()
	host._skill_detail_surface().detail_lazy_last_scroll = -1.0
	host._skill_detail_surface().detail_lazy_stack = null
	host._skill_detail_surface().detail_lazy_refresh_token += 1
	host._skill_detail_surface()._cancel_detail_card_texture_prewarm()
	host._tutorial_overlay_surface()._dismiss_activity_start_highlight(true)
	host._skill_swipe_activity_surface().skill_swipe_frame = null
	host._skill_swipe_activity_surface().skill_swipe_page = null
	host._skill_swipe_activity_surface().skill_swipe_drag_offset_x = 0.0
	host._skill_swipe_activity_surface().skill_swipe_gap_render_offset_x = 0.0
	host._skill_swipe_activity_surface().skill_swipe_animating = false
	host._skill_swipe_activity_surface().skill_strip_ids.clear()
	host._skill_swipe_activity_surface().skill_strip_index = 0
	host._skill_swipe_activity_surface().skill_strip_refs.clear()
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


func _flush_skill_swipe_handoff_for_navigation() -> void:
	host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()


func _capture_skill_menu_swap_refs() -> Dictionary:
	return {
		"skill_cards": host.skill_cards,
		"content_scroll": host.content_scroll,
		"action_cards": host.action_cards,
		"action_card_keys": host.action_card_keys,
		"active_drawers": skill_menu_active_drawers,
		"shadow_overlay": host._skill_detail_surface().detail_shelf_shadow_overlay,
		"shadow_alpha": host._skill_detail_surface().detail_shelf_shadow_alpha,
	}


func _install_skill_menu_swap_refs(refs: Dictionary) -> void:
	host.skill_cards = refs.get("skill_cards", {}) as Dictionary
	host.content_scroll = refs.get("content_scroll") as ScrollContainer
	host.action_cards = refs.get("action_cards", {}) as Dictionary
	host.action_card_keys = refs.get("action_card_keys", []) as Array
	skill_menu_active_drawers = refs.get("active_drawers", {}) as Dictionary
	host._skill_detail_surface().detail_shelf_shadow_overlay = refs.get("shadow_overlay") as Control
	host._skill_detail_surface().detail_shelf_shadow_alpha = float(refs.get("shadow_alpha", 0.0))


func _ensure_skill_menu_cache_overlay() -> bool:
	if skill_menu_cache_overlay != null and is_instance_valid(skill_menu_cache_overlay):
		return true
	if host.skills_page == null or not is_instance_valid(host.skills_page):
		return false
	skill_menu_cache_overlay = Control.new()
	skill_menu_cache_overlay.name = "SkillMenuCacheOverlay"
	skill_menu_cache_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	skill_menu_cache_overlay.z_index = 1
	skill_menu_cache_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	skill_menu_cache_overlay.visible = false
	skill_menu_cache_overlay.process_mode = Node.PROCESS_MODE_DISABLED
	host.skills_page.add_child(skill_menu_cache_overlay)
	var backdrop := ColorRect.new()
	backdrop.name = "SkillMenuCacheBackdrop"
	backdrop.color = host._theme_paper_color()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_menu_cache_overlay.add_child(backdrop)
	return true


func _prebuild_skill_menu_page_cache(force_rebuild := false) -> bool:
	if not skill_menu_return_state.is_empty():
		return true
	if force_rebuild and skill_menu_cache_overlay != null and is_instance_valid(skill_menu_cache_overlay):
		skill_menu_cache_overlay.visible = false
		skill_menu_cache_overlay.queue_free()
		skill_menu_cache_overlay = null
		skill_menu_page_cache = {}
	if not _ensure_skill_menu_cache_overlay():
		return false
	if (
		not skill_menu_page_cache.is_empty()
		and skill_menu_cache_overlay.get_child_count() > 0
		and skill_menu_cache_dark_mode == host.dark_mode_enabled
	):
		return true
	var previous_content: Control = host.skills_content
	var previous_screen: String = host.current_screen
	var previous_refs := _capture_skill_menu_swap_refs()
	host.skills_content = skill_menu_cache_overlay
	_install_skill_menu_swap_refs({})
	host.current_screen = "menu"
	skill_menu_cache_overlay.visible = false
	skill_menu_cache_overlay.process_mode = Node.PROCESS_MODE_INHERIT
	_apply_skills_content_layout_for_screen()
	_render_skill_menu_shelf()
	_render_skill_menu_page()
	_sync_skill_menu_page(0.0, true, true)
	skill_menu_page_cache = _capture_skill_menu_swap_refs()
	skill_menu_cache_dark_mode = host.dark_mode_enabled
	skill_menu_cache_overlay.visible = false
	skill_menu_cache_overlay.process_mode = Node.PROCESS_MODE_DISABLED
	host.skills_content = previous_content
	host.current_screen = previous_screen
	_install_skill_menu_swap_refs(previous_refs)
	if host.skills_content != null and is_instance_valid(host.skills_content):
		_apply_skills_content_layout_for_screen()
	return skill_menu_cache_overlay.get_child_count() > 0


func _activate_skill_menu_page_cache() -> bool:
	if host.skills_content == skill_menu_cache_overlay and not skill_menu_return_state.is_empty():
		return true
	if not _prebuild_skill_menu_page_cache(skill_menu_cache_dark_mode != host.dark_mode_enabled):
		return false
	var previous_content: Control = host.skills_content
	skill_menu_return_state = {
		"skills_content": previous_content,
		"content_visible": previous_content.visible if previous_content != null else false,
		"content_process_mode": previous_content.process_mode if previous_content != null else Node.PROCESS_MODE_INHERIT,
		"refs": _capture_skill_menu_swap_refs(),
		"screen_key": last_rendered_screen_key,
	}
	host._clear_page_transient_input_state()
	host._reward_feedback_surface()._clear_skill_reward_floats()
	host._activity_unlock_ceremony_surface().cancel_transients_for_navigation()
	_flush_skill_swipe_handoff_for_navigation()
	if previous_content != null and is_instance_valid(previous_content):
		previous_content.visible = false
		previous_content.process_mode = Node.PROCESS_MODE_DISABLED
	host.skills_content = skill_menu_cache_overlay
	_install_skill_menu_swap_refs(skill_menu_page_cache)
	host.current_screen = "menu"
	skill_menu_cache_overlay.visible = true
	skill_menu_cache_overlay.process_mode = Node.PROCESS_MODE_INHERIT
	_apply_skills_content_layout_for_screen()
	_finish_render_screen_transition("menu")
	return true


func _deactivate_skill_menu_page_cache() -> bool:
	if skill_menu_return_state.is_empty():
		return false
	skill_menu_page_cache = _capture_skill_menu_swap_refs()
	var return_state := skill_menu_return_state
	skill_menu_return_state = {}
	if skill_menu_cache_overlay != null and is_instance_valid(skill_menu_cache_overlay):
		skill_menu_cache_overlay.visible = false
		skill_menu_cache_overlay.process_mode = Node.PROCESS_MODE_DISABLED
	host.skills_content = return_state.get("skills_content") as Control
	_install_skill_menu_swap_refs(return_state.get("refs", {}) as Dictionary)
	last_rendered_screen_key = str(return_state.get("screen_key", ""))
	if host.skills_content != null and is_instance_valid(host.skills_content):
		host.skills_content.visible = bool(return_state.get("content_visible", true))
		host.skills_content.process_mode = int(return_state.get("content_process_mode", Node.PROCESS_MODE_INHERIT))
		_apply_skills_content_layout_for_screen()
	return true


func reset_navigation_render_state() -> void:
	last_rendered_screen_key = ""
	host._skill_swipe_activity_surface()._kill_skill_swipe_tween()
	host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
	host._skill_swipe_activity_surface()._clear_skill_swipe_preview()
	host._skill_swipe_activity_surface().skill_swipe_frame = null
	host._skill_swipe_activity_surface().skill_swipe_page = null
	host._skill_swipe_activity_surface().skill_swipe_drag_offset_x = 0.0
	host._skill_swipe_activity_surface().skill_swipe_gap_render_offset_x = 0.0


func _try_reveal_current_skill_page(target_key: String, scroll_latest_activity: bool) -> bool:
	if target_key.is_empty() or not target_key.begins_with("skill:"):
		return false
	if last_rendered_screen_key != target_key:
		return false
	if host.skills_content == null or not is_instance_valid(host.skills_content) or host.skills_content.get_child_count() == 0:
		return false
	if host._skill_swipe_activity_surface().skill_swipe_frame == null or not is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_frame):
		return false
	var stack: Control = host._skill_detail_surface()._detail_actions_stack()
	if stack == null or not is_instance_valid(stack) or not host._skill_swipe_activity_surface()._skill_detail_stack_has_visible_modules(stack):
		return false
	if not _detail_render_signature_current(host.selected_skill_id):
		return false
	host._clear_page_transient_input_state()
	host._skill_swipe_activity_surface().skill_swipe_animating = false
	host._skill_swipe_activity_surface().skill_swipe_animation_mode = ""
	host._skill_swipe_activity_surface()._kill_skill_swipe_tween()
	_apply_skills_content_layout_for_screen()
	host._skill_detail_surface()._sync_skill_detail_back_arrow_visibility()
	if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		Callable(host._skill_detail_surface(), "_sync_detail_actions_scroll_limit_deferred").call_deferred()
		if scroll_latest_activity:
			host._skill_detail_surface().call_deferred("_scroll_to_resume_activity", false)
	_finish_render_screen_transition(target_key)
	return true


func _detail_render_signature_current(skill_id: String) -> bool:
	var plan_data: Dictionary = host._skill_detail_surface()._detail_lazy_plan_and_signature_for_skill(skill_id)
	var expected := plan_data.get("signature", []) as Array
	if expected.size() != host._skill_detail_surface().detail_rendered_action_ids.size():
		return false
	for index in range(expected.size()):
		if str(expected[index]) != str(host._skill_detail_surface().detail_rendered_action_ids[index]):
			return false
	var expected_plan := plan_data.get("plan", []) as Array
	if expected_plan.size() != host._skill_detail_surface().detail_lazy_plan.size():
		return false
	for index in range(expected_plan.size()):
		var expected_entry: Dictionary = expected_plan[index] as Dictionary
		var rendered_entry: Dictionary = host._skill_detail_surface().detail_lazy_plan[index] as Dictionary
		if str(expected_entry.get("kind", "")) != str(rendered_entry.get("kind", "")):
			return false
		if str(expected_entry.get("track_id", "")) != str(rendered_entry.get("track_id", "")):
			return false
		if absf(float(expected_entry.get("height", 0.0)) - float(rendered_entry.get("height", 0.0))) > 0.5:
			return false
	return true


func _render_screen(scroll_latest_activity := false, restore_detail_scroll := -1, boot_async := false):
	if host.current_screen != "menu":
		_deactivate_skill_menu_page_cache()
	elif host.skills_content == skill_menu_cache_overlay and not skill_menu_return_state.is_empty():
		_sync_skill_menu_page(0.0, true, true)
		_finish_render_screen_transition("menu")
		return
	host.module_ui_refresh_token += 1
	host._skill_detail_surface().detail_lazy_refresh_token += 1
	var requested_key: String = _screen_page_cache_key(host.current_screen)
	if screen_render_in_progress:
		if requested_key != screen_render_target_key:
			_store_pending_screen_render_request(scroll_latest_activity, restore_detail_scroll, boot_async, requested_key)
		return
	screen_render_in_progress = true
	screen_render_target_key = requested_key
	if host.skills_content == null:
		_finish_screen_render_request()
		return
	if host.current_screen == "skill" and host._skill_swipe_activity_surface()._skill_swipe_navigation_blocks_detail_refresh():
		_finish_screen_render_request()
		return
	var target_key: String = requested_key
	if host.current_screen == "skill" and _try_reveal_current_skill_page(target_key, scroll_latest_activity):
		_finish_screen_render_request()
		return
	host.visual_texture_cache.begin_runtime_scope()
	host._skill_swipe_activity_surface().skill_swipe_animating = false
	host._skill_swipe_activity_surface().skill_swipe_animation_mode = ""
	host._skill_swipe_activity_surface()._kill_skill_swipe_tween()
	host._clear_page_transient_input_state()
	if host.current_screen != "skill":
		host._reward_feedback_surface()._clear_skill_reward_floats()
		host._activity_unlock_ceremony_surface().cancel_transients_for_navigation()
	_prepare_skills_page_transition(target_key)
	if host.current_screen != "settings":
		host._settings_surface()._clear_settings_page_control_refs()
	host._hub_surface()._kill_hub_detail_motion_tween()
	_apply_skills_content_layout_for_screen()
	host._skill_swipe_activity_surface()._clear_skill_swipe_preview()
	host._skill_swipe_activity_surface().skill_swipe_frame = null
	host._skill_swipe_activity_surface().skill_swipe_page = null
	_reset_page_control_refs()
	_clear_skills_content_orphans()
	if host.current_screen == "skill":
		await host._skill_detail_surface()._render_skill_detail(scroll_latest_activity, restore_detail_scroll, boot_async)
	elif host.current_screen == "pinned":
		_render_pinned_activities_page()
	elif host.current_screen == "queue":
		host._skill_swipe_activity_surface()._render_activity_queue_page()
	elif host.current_screen == "leaderboard":
		host.leaderboard_presentation._render_leaderboard_page()
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
	_finish_render_screen_transition(target_key)
	host.visual_texture_cache.finish_runtime_scope()
	_finish_screen_render_request()


func _clear_skills_content_orphans() -> void:
	if host.skills_content == null or host.skills_content.get_child_count() == 0:
		return
	host._clear(host.skills_content)


func _finish_render_screen_transition(target_key: String) -> void:
	_apply_skills_content_layout_for_screen()
	last_rendered_screen_key = target_key
	if host.current_screen == "skill" and not host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition() and not host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount:
		host._skill_detail_surface()._repair_blank_detail_lazy_stack()
		host._skill_detail_surface().call_deferred("_repair_blank_detail_lazy_stack")
	if (
		host._skill_swipe_activity_surface().skill_detail_refresh_cover_active
		and not host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize
		and host._skill_detail_surface().module_ui_pending_pin_scroll_anchor.is_empty()
		and not host._skill_detail_surface().module_ui_pin_refresh_cover_requested
	):
		host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
	elif host._skill_swipe_activity_surface().direct_skill_nav_cover_active and not host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize:
		host._skill_swipe_activity_surface()._fade_clear_direct_skill_nav_cover()
	elif (
		not host._skill_swipe_activity_surface().skill_swipe_pending_full_finalize
		and
		not host._skill_swipe_activity_surface().skill_swipe_outgoing_cover_active
		and not host._skill_swipe_activity_surface().skill_swipe_rebuild_cover_active
		and not host._skill_swipe_activity_surface().skill_swipe_animating
		and host._skill_swipe_activity_surface().skill_swipe_handoff_cover != null
		and is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_handoff_cover)
		and not _page_switch_scroll_cover_active()
	):
		host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
	_update_page_visibility()
	host._profile_chat_overlay_surface()._update_chat_strip(true)
	host.call_deferred("_update_ui", 0.0, true)
	if host.current_screen == "skill":
		if host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
			if host._onboarding_runtime()._onboarding_swipe_tip_sequence_resumable() and not host._onboarding_runtime().onboarding_swipe_tip_sequence_running:
				host._tutorial_overlay_surface().call_deferred("_run_onboarding_swipe_tip_sequence")
		else:
			host._onboarding_runtime().call_deferred("_maybe_show_onboarding_explore_tip")
	elif host.current_screen == "hub":
		host._hub_surface().call_deferred("_maybe_show_hub_tutorial_tip")
	if (
		host.current_screen == "skill"
		and not host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_opaque_cream_transition()
		and not host._skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount
	):
		if host._skill_detail_surface().detail_lazy_plan.size() > 0 and not host._skill_detail_surface()._detail_lazy_all_mounted():
			host._skill_detail_surface().call_deferred("_detail_lazy_refresh_after_page_ready", host._skill_detail_surface().detail_lazy_refresh_token)


func _apply_skills_content_layout_for_screen() -> void:
	host.skills_content.offset_left = 0.0
	host.skills_content.offset_right = 0.0
	host.skills_content.offset_bottom = 0.0
	if host.current_screen == "hub" or host.current_screen == "menu" or host.current_screen == "pinned" or host.current_screen == "queue":
		host.skills_content.offset_top = 0.0
	else:
		host.skills_content.offset_top = host.SKILLS_PAGE_TOP_PAD
	if host.current_screen == "skill":
		host._skill_swipe_activity_surface()._ensure_skill_swipe_frame_centered()
		if not host._skill_swipe_activity_surface().skill_swipe_animating:
			host._skill_swipe_activity_surface()._normalize_skill_detail_page_layout()


func _prepare_skills_page_transition(target_key: String) -> void:
	host._skill_detail_surface()._cancel_boot_detail_completion()
	var leaving_skill: bool = not target_key.begins_with("skill:")
	if leaving_skill:
		host._skill_swipe_activity_surface().skill_swipe_real_card_prewarm_token += 1
		host._skill_swipe_activity_surface()._free_global_swipe_real_card_cache()
		host._skill_detail_surface()._clear_detail_lazy_cached_roots()
	host._skill_swipe_activity_surface()._cancel_skill_swipe_finalize_for_navigation()
	if not target_key.begins_with("skill:"):
		_flush_skill_swipe_handoff_for_navigation()
	var previous_key: String = last_rendered_screen_key
	if previous_key.begins_with("skill:") and target_key.begins_with("skill:") and previous_key != target_key:
		host._reward_feedback_surface()._clear_skill_reward_floats()
	if previous_key == target_key:
		if host.skills_content.get_child_count() > 0 or host._skill_swipe_activity_surface().skill_swipe_handoff_cover != null:
			var preserve_pin_anchor_cover: bool = host._skill_swipe_activity_surface().skill_detail_refresh_cover_active and not host._skill_detail_surface().module_ui_pending_pin_scroll_anchor.is_empty()
			if not preserve_pin_anchor_cover:
				host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
			if host.skills_content.get_child_count() > 0:
				host._skill_swipe_activity_surface()._clear_skill_swipe_preview()
				host._clear(host.skills_content)
				_reset_page_control_refs()
		return
	if previous_key.is_empty():
		return
	if previous_key.begins_with("skill:"):
		if host.skills_content.get_child_count() > 0:
			host._skill_swipe_activity_surface()._clear_skill_swipe_preview()
			host._clear(host.skills_content)
			_reset_page_control_refs()
		elif (
			host._skill_swipe_activity_surface().skill_swipe_handoff_cover != null
			and is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_handoff_cover)
			and not host._skill_swipe_activity_surface()._skill_swipe_handoff_cover_is_cream_transition()
		):
			_flush_skill_swipe_handoff_for_navigation()
		if leaving_skill:
			host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
		return
	if host.skills_content.get_child_count() > 0:
		host._skill_swipe_activity_surface()._clear_skill_swipe_preview()
		host._clear(host.skills_content)
		_reset_page_control_refs()


func _store_pending_screen_render_request(scroll_latest_activity: bool, restore_detail_scroll: int, boot_async: bool, requested_key := "") -> void:
	pending_screen_render_request = {
		"scroll_latest_activity": scroll_latest_activity,
		"restore_detail_scroll": restore_detail_scroll,
		"boot_async": boot_async,
		"requested_key": requested_key
	}


func _store_pending_skill_detail_refresh_request(restore_detail_scroll: int, target_skill_id: String, allow_thieving_scroll_restore: bool, suppress_layout_transition: bool) -> void:
	pending_skill_detail_refresh_request = {
		"restore_detail_scroll": restore_detail_scroll,
		"target_skill_id": target_skill_id,
		"allow_thieving_scroll_restore": allow_thieving_scroll_restore,
		"suppress_layout_transition": suppress_layout_transition
	}


func _finish_screen_render_request() -> void:
	screen_render_in_progress = false
	screen_render_target_key = ""
	if pending_screen_render_request.is_empty():
		_defer_pending_skill_detail_refresh_request()
		return
	var request := pending_screen_render_request
	pending_screen_render_request = {}
	call_deferred(
		"_render_screen",
		bool(request.get("scroll_latest_activity", false)),
		int(request.get("restore_detail_scroll", -1)),
		bool(request.get("boot_async", false))
	)


func _defer_pending_skill_detail_refresh_request() -> void:
	if pending_skill_detail_refresh_request.is_empty():
		return
	call_deferred("_run_pending_skill_detail_refresh_request")


func _run_pending_skill_detail_refresh_request() -> void:
	if pending_skill_detail_refresh_request.is_empty() or screen_render_in_progress:
		return
	var request := pending_skill_detail_refresh_request
	pending_skill_detail_refresh_request = {}
	host._skill_detail_surface()._refresh_visible_skill_detail_action_list(
		int(request.get("restore_detail_scroll", -1)),
		str(request.get("target_skill_id", "")),
		bool(request.get("allow_thieving_scroll_restore", false)),
		bool(request.get("suppress_layout_transition", false))
	)


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


func _apply_skill_page_cover_bounds(cover: Control, include_bottom_interactive_ui := false) -> void:
	if cover == null or not is_instance_valid(cover):
		return
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.offset_left = 0.0
	cover.offset_top = 0.0
	cover.offset_right = 0.0
	cover.offset_bottom = _skill_page_cover_bottom_offset(include_bottom_interactive_ui)


func _skill_page_cover_bottom_offset(include_bottom_interactive_ui := false) -> float:
	if include_bottom_interactive_ui or host._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		return _global_chat_nav_cover_bottom_offset()
	if host.skills_page == null or not is_instance_valid(host.skills_page):
		return -_skills_content_bottom_inset_for_screen()
	var page_rect: Rect2 = host.skills_page.get_global_rect()
	var cover_bottom_y: float = page_rect.end.y - _skills_content_bottom_inset_for_screen()
	for raw_control in [host._profile_chat_overlay_surface().chat_strip_control(), nav_bar]:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control) or not control.visible:
			continue
		var rect: Rect2 = control.get_global_rect()
		if rect.size.y <= 1.0:
			continue
		cover_bottom_y = minf(cover_bottom_y, rect.position.y)
	return minf(0.0, cover_bottom_y - page_rect.end.y)


func _global_chat_nav_cover_bottom_offset() -> float:
	var viewport_bottom: float = host._current_canvas_size().y
	var cover_bottom_y: float = viewport_bottom
	for raw_control in [host._profile_chat_overlay_surface().chat_strip_control(), nav_bar]:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control) or not control.visible:
			continue
		var rect: Rect2 = control.get_global_rect()
		if rect.size.y <= 1.0:
			continue
		cover_bottom_y = minf(cover_bottom_y, rect.position.y)
	if cover_bottom_y >= viewport_bottom - 1.0:
		cover_bottom_y = maxf(0.0, viewport_bottom - float(BOTTOM_NAV_HEIGHT))
	return minf(0.0, cover_bottom_y - viewport_bottom)


func _begin_page_switch_scroll_cover(include_bottom_interactive_ui := false) -> void:
	if _page_switch_scroll_cover_active():
		return
	host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()
	var cover := Control.new()
	_apply_skill_page_cover_bounds(cover, include_bottom_interactive_ui)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	cover.modulate = Color(1.0, 1.0, 1.0, 0.0)
	cover.set_meta("swipe_cream_transition_cover", true)
	cover.set_meta("page_switch_scroll_cover", true)
	cover.set_meta("page_switch_scroll_cover_started_msec", Time.get_ticks_msec())
	cover.set_meta("page_switch_scroll_cover_includes_bottom_interactive_ui", include_bottom_interactive_ui)
	host._skill_swipe_activity_surface()._ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = host._theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.add_child(backing)

	host._skill_swipe_activity_surface().skill_swipe_handoff_cover = cover
	_start_page_switch_scroll_cover_fade_in(cover)
	host.get_tree().create_timer(host.PAGE_SWITCH_SCROLL_COVER_FADE_IN_SECONDS, true, false, true).timeout.connect(
		_force_page_switch_scroll_cover_opaque.bind(cover.get_instance_id())
	)


func _start_page_switch_scroll_cover_fade_in(cover: Control) -> void:
	if cover == null or not is_instance_valid(cover):
		return
	host._skill_swipe_activity_surface()._kill_skill_swipe_cover_fade_tween()
	host._skill_swipe_activity_surface().skill_swipe_cover_fade_tween = host.create_tween()
	host._skill_swipe_activity_surface().skill_swipe_cover_fade_tween.tween_property(
		cover,
		"modulate:a",
		1.0,
		host.PAGE_SWITCH_SCROLL_COVER_FADE_IN_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	host._skill_swipe_activity_surface().skill_swipe_cover_fade_tween.tween_callback(host._skill_swipe_activity_surface()._finish_skill_nav_cover_fade_in.bind(cover.get_instance_id()))


func _begin_page_switch_scroll_cover_timed(include_bottom_interactive_ui := false) -> int:
	_begin_page_switch_scroll_cover(include_bottom_interactive_ui)
	var cover: Control = host._skill_swipe_activity_surface().skill_swipe_handoff_cover
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
	var cover: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(cover_id))
	if cover == null or cover != host._skill_swipe_activity_surface().skill_swipe_handoff_cover:
		return null
	if not bool(cover.get_meta("page_switch_scroll_cover", false)):
		return null
	return cover


func _force_page_switch_scroll_cover_opaque(cover_id: int) -> void:
	var cover := _active_page_switch_cover_ref(cover_id)
	if cover == null:
		return
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(cover, Color.WHITE)


func _fade_clear_page_switch_scroll_cover() -> void:
	var cover: Control = host._skill_swipe_activity_surface().skill_swipe_handoff_cover
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
	host._skill_swipe_activity_surface()._fade_clear_skill_swipe_cover(host.PAGE_SWITCH_SCROLL_COVER_FADE_SECONDS)


func _fade_clear_page_switch_scroll_cover_after_delay(delay_seconds: float) -> void:
	await host.get_tree().create_timer(maxf(0.01, delay_seconds), true, false, true).timeout
	var cover: Control = host._skill_swipe_activity_surface().skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover) or not bool(cover.get_meta("page_switch_scroll_cover", false)):
		return
	cover.remove_meta("page_switch_scroll_cover_release_pending")
	_fade_clear_page_switch_scroll_cover()


func _page_switch_scroll_cover_active() -> bool:
	return (
		host._skill_swipe_activity_surface().skill_swipe_handoff_cover != null
		and is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_handoff_cover)
		and bool(host._skill_swipe_activity_surface().skill_swipe_handoff_cover.get_meta("page_switch_scroll_cover", false))
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
	margin.add_theme_constant_override("margin_left", 59)
	margin.add_theme_constant_override("margin_right", 59)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 9)
	module.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var previous_button := _page_switch_button(previous_skill, "right")
	previous_button.set_meta("page_switch_owner_skill_id", skill_id)
	row.add_child(previous_button)
	var next_button := _page_switch_button(next_skill, "left")
	next_button.set_meta("page_switch_owner_skill_id", skill_id)
	row.add_child(next_button)
	return module


func _render_page_switch_module(stack: VBoxContainer, skill_id: String, content_width: float, actions_width: float) -> void:
	if (host._onboarding_runtime().tutorial_active or host._onboarding_runtime()._onboarding_path_active()) and not _onboarding_page_switch_module_visible():
		_remove_page_switch_modules(stack)
		return
	var entry: Control = null
	for child in stack.get_children():
		var control := child as Control
		if control == null:
			continue
		if control.name == "PageSwitchModule" or bool(control.get_meta("page_switch_module_entry", false)):
			entry = control
			break
	if entry == null:
		var module := _build_page_switch_module(skill_id, content_width)
		if module == null:
			return
		entry = host._skill_detail_surface()._detail_stack_entry(module, content_width, actions_width)
		if entry != module:
			entry.name = "PageSwitchModuleEntry"
			entry.set_meta("page_switch_module_entry", true)
		stack.add_child(entry)
	if _skill_swipe_page_switch_module_should_start_hidden():
		_set_skill_page_switch_module_alpha(entry, 0.0)
	for i in range(stack.get_child_count()):
		var child := stack.get_child(i)
		if child != entry and child.name == "DetailActionsBottomSpacer":
			stack.move_child(entry, i)
			return


func _ensure_onboarding_page_switch_module_faded_in(stack: VBoxContainer) -> Control:
	if stack == null or not is_instance_valid(stack):
		return null
	if not _onboarding_page_switch_module_visible():
		return null
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null:
			continue
		if child.name == "PageSwitchModule" or child.find_child("PageSwitchModule", true, false) != null:
			return child
	var content_width: float = host._skill_content_width()
	var module: Control = _build_page_switch_module(host.selected_skill_id, content_width)
	if module == null:
		return null
	var entry: Control = host._skill_detail_surface()._detail_stack_entry(module, content_width, content_width)
	var target_height := maxf(1.0, entry.custom_minimum_size.y)
	entry.custom_minimum_size.y = 0.0
	entry.modulate.a = 0.0
	entry.clip_contents = true
	stack.add_child(entry)
	var insert_index := maxi(0, stack.get_child_count() - 1)
	for i in range(stack.get_child_count()):
		var child := stack.get_child(i)
		if child == entry:
			continue
		if child.name == "DetailActionsBottomSpacer":
			insert_index = i
			break
	stack.move_child(entry, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(entry, "custom_minimum_size:y", target_height, host.TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(entry, "modulate:a", 1.0, host.TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(Callable(host._skill_detail_surface(), "_finish_smooth_tutorial_tip_entry_reveal").bind(entry.get_instance_id()))
	Callable(host._skill_detail_surface(), "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	return entry


func _remove_page_switch_modules(root_node: Node) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	for raw_child in root_node.get_children():
		var child := raw_child as Node
		if child == null:
			continue
		if child.name == "PageSwitchModule" or bool(child.get_meta("page_switch_module_entry", false)):
			child.queue_free()
			continue
		_remove_page_switch_modules(child)


func _skill_swipe_page_switch_module_should_start_hidden() -> bool:
	return (
		host.current_screen == "skill"
		and host._skill_swipe_activity_surface().skill_swipe_animating
		and host._skill_swipe_activity_surface().skill_swipe_animation_mode == "entry"
	)


func _collect_page_switch_modules(root_node: Node, modules: Array) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	if root_node is Control and (
		root_node.name == "PageSwitchModule"
		or bool(root_node.get_meta("page_switch_module_entry", false))
	):
		modules.append(root_node)
		return
	for raw_child in root_node.get_children():
		_collect_page_switch_modules(raw_child as Node, modules)


func _current_page_switch_modules() -> Array:
	var modules := []
	var root_node: Node = host._skill_swipe_activity_surface().skill_swipe_page if host._skill_swipe_activity_surface().skill_swipe_page != null and is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_page) else host.skills_content
	_collect_page_switch_modules(root_node, modules)
	return modules


func _fade_skill_page_switch_modules(visible: bool, seconds: float) -> void:
	for raw_module in _current_page_switch_modules():
		var module := raw_module as Control
		if module == null or not is_instance_valid(module):
			continue
		host._app_lifecycle_runtime()._kill_meta_tween(module, "skill_swipe_page_switch_fade_tween")
		var target_alpha := 1.0 if visible else 0.0
		if seconds <= 0.001:
			_set_skill_page_switch_module_alpha(module, target_alpha)
			continue
		var tween: Tween = host.create_tween()
		module.set_meta("skill_swipe_page_switch_fade_tween", tween)
		var module_id := module.get_instance_id()
		tween.tween_method(
			func(alpha: float) -> void:
				_set_skill_page_switch_module_alpha(module_id, alpha),
			module.modulate.a,
			target_alpha,
			seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_finish_skill_page_switch_module_fade.bind(module.get_instance_id()))


func _finish_skill_page_switch_module_fade(module_id: int) -> void:
	var module: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(module_id))
	if module != null and module.has_meta("skill_swipe_page_switch_fade_tween"):
		module.remove_meta("skill_swipe_page_switch_fade_tween")


func _set_skill_page_switch_module_alpha(module_or_alpha, maybe_alpha = null) -> void:
	var module: Control = null
	var alpha := 1.0
	if maybe_alpha == null:
		module = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(module_or_alpha)))
		alpha = 1.0
	else:
		if module_or_alpha is Control:
			module = module_or_alpha as Control
		else:
			module = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(module_or_alpha)))
		alpha = float(maybe_alpha)
	if module == null:
		return
	var next_alpha := clampf(alpha, 0.0, 1.0)
	var next_modulate := module.modulate
	next_modulate.a = next_alpha
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(module, next_modulate)
	if bool(module.get_meta("page_switch_module_entry", false)):
		for raw_child in module.get_children():
			var child := raw_child as Control
			if child != null and child.name == "PageSwitchModule":
				var child_modulate := child.modulate
				child_modulate.a = 1.0
				host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(child, child_modulate)


func _set_skill_page_switch_modules_alpha(alpha: float) -> void:
	for raw_module in _current_page_switch_modules():
		var module := raw_module as Control
		if module == null or not is_instance_valid(module):
			continue
		host._app_lifecycle_runtime()._kill_meta_tween(module, "skill_swipe_page_switch_fade_tween")
		_set_skill_page_switch_module_alpha(module, alpha)


func _sync_skill_page_switch_modules_for_drag(abs_x: float) -> void:
	_set_skill_page_switch_modules_alpha(1.0)


func _onboarding_page_switch_module_visible() -> bool:
	return (
		host._onboarding_runtime()._onboarding_path_active()
		and not host._onboarding_runtime().tutorial_active
		and host._onboarding_runtime().onboarding_swipe_navigation_unlocked
	)


func _build_queue_activities_module(module_key: String, content_width: float) -> Control:
	return _build_page_activity_module_copy(module_key, content_width, _queue_page_card_key(module_key))


func _build_pinned_activities_module(module_key: String, content_width: float) -> Control:
	return _build_page_activity_module_copy(module_key, content_width, _pinned_page_card_key(module_key))


func _prepare_page_activity_module_copy_card(card: Dictionary, suppress_collection_modules := false) -> Dictionary:
	if card.is_empty():
		return card
	if suppress_collection_modules and not (card.get("mat_collection", {}) as Dictionary).is_empty():
		card["page_copy_suppresses_collection_modules"] = true
	return card


func _build_page_activity_module_copy(module_key: String, content_width: float, page_card_key: String) -> Control:
	if page_card_key.is_empty():
		return null
	if module_key.begins_with("action:"):
		var action_key := module_key.substr("action:".length())
		var parts := action_key.split(":", false, 2)
		if parts.size() < 2:
			return null
		var skill_id := str(parts[0])
		var action_id := str(parts[1])
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty():
			return null
		if host._passive_modules_runtime().is_passive_action(action):
			var passive_card: Dictionary = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
			var passive_root := passive_card.get("root") as Control
			var passive_dict := passive_card.get("card", {}) as Dictionary
			passive_dict["entry"] = passive_root
			passive_dict["action_id"] = action_id
			passive_dict = _prepare_page_activity_module_copy_card(passive_dict, page_card_key.begins_with("pinned_page:"))
			host._skill_detail_surface()._register_action_card(page_card_key, passive_dict)
			host._skill_detail_surface()._detail_lazy_finalize_action_card(passive_dict, skill_id, action, action_id)
			return passive_root
		var built: Dictionary = host._skill_detail_surface()._build_detail_interactive_action_card(skill_id, action, content_width, content_width)
		var card_root := built.get("card_root") as Control
		var card := _prepare_page_activity_module_copy_card(built.get("card", {}) as Dictionary, page_card_key.begins_with("pinned_page:"))
		var pop_card := card.get("pop") as Control
		if pop_card != null and is_instance_valid(pop_card):
			host._skill_swipe_activity_surface()._attach_swipe_preview_activity_button(card, skill_id, action_id, pop_card)
		var page_entry: Control = card_root
		if page_card_key.begins_with("queue_page:"):
			page_entry = _page_activity_module_copy_entry(card_root, content_width)
		card["entry"] = page_entry
		host._skill_detail_surface()._register_action_card(page_card_key, card)
		host._skill_detail_surface()._detail_lazy_finalize_action_card(card, skill_id, action, action_id)
		return page_entry
	if module_key.begins_with("thieving_heist:"):
		var heist_id := module_key.substr("thieving_heist:".length())
		var heist: Dictionary = host.thieving_state.heist_def(heist_id)
		if heist.is_empty():
			return null
		return host._thieving_surface()._build_thieving_heist_card(heist, content_width, false, page_card_key)
	if module_key.begins_with("fishing_area:"):
		var area_key := module_key.substr("fishing_area:".length())
		for raw_area_def in host._fishing_ui_surface().render_area_modules("fishing"):
			var area_def := raw_area_def as Dictionary
			if host.fishing_runtime.area_module_key("fishing", area_def) != area_key:
				continue
			var built: Dictionary = host._fishing_ui_surface()._build_fishing_area_module("fishing", area_def, content_width)
			var area_card := built.get("area_card", {}) as Dictionary
			if not area_card.is_empty():
				host._skill_detail_surface()._register_action_card(page_card_key, area_card)
			return built.get("root") as Control
	if module_key.begins_with("fishing_offer:"):
		return host._fishing_ui_surface()._build_fishing_offer_module(module_key.substr("fishing_offer:".length()), content_width)
	return null


func _page_activity_module_copy_entry(module_root: Control, content_width: float) -> Control:
	if module_root == null:
		return null
	var entry := Control.new()
	entry.set_meta("detail_stack_entry_wrapper", true)
	entry.set_meta("page_activity_module_copy_entry", true)
	var module_height := maxf(1.0, module_root.custom_minimum_size.y)
	if module_height <= 1.0:
		module_height = maxf(1.0, module_root.size.y)
	entry.custom_minimum_size = Vector2(content_width, module_height)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.clip_contents = false
	module_root.anchor_left = 0.0
	module_root.anchor_right = 1.0
	module_root.anchor_top = 0.0
	module_root.anchor_bottom = 0.0
	module_root.offset_left = 0.0
	module_root.offset_right = 0.0
	module_root.offset_top = 0.0
	module_root.offset_bottom = module_height
	module_root.custom_minimum_size = Vector2(content_width, module_height)
	module_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(module_root)
	return entry


func _pinned_page_card_key(module_key: String) -> String:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return ""
	return "pinned_page:%s" % normalized_key


func _queue_page_card_key(module_key: String) -> String:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return ""
	return "queue_page:%s" % normalized_key


func _remove_registered_card_collapse_zone(card_key: String) -> void:
	if card_key.is_empty() or not host.action_cards.has(card_key):
		return
	var card := host.action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	var zones := card.get("module_action_zones", {}) as Dictionary
	if zones.is_empty():
		return
	zones.erase("collapse")
	if zones.is_empty():
		card.erase("module_action_zones")
	else:
		card["module_action_zones"] = zones


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
	var theme: Color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
	var activity_surface = host._skill_swipe_activity_surface()
	var pop: Control = activity_surface._install_activity_button_shell(button, theme, host.ACTION_CARD_FACE_RADIUS, host.ACTION_CARD_POP_GUTTER, NAV_BUTTON_DEPTH_OFFSET, diagonal_side)
	if diagonal_side == "right" or diagonal_side == "left":
		_add_page_switch_skill_icon(pop, skill_id, diagonal_side)
		var chevron := PageSwitchChevronIcon.new()
		chevron.name = "PageSwitchChevronIcon"
		chevron.set_direction(-1 if diagonal_side == "right" else 1)
		chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chevron.z_index = 250
		chevron.anchor_top = 0.0
		chevron.anchor_bottom = 1.0
		chevron.offset_top = 9.0
		chevron.offset_bottom = -23.0
		if diagonal_side == "right":
			chevron.anchor_left = 0.0
			chevron.anchor_right = 0.0
			chevron.offset_left = 26.0
			chevron.offset_right = 103.0
		else:
			chevron.anchor_left = 1.0
			chevron.anchor_right = 1.0
			chevron.offset_left = -103.0
			chevron.offset_right = -26.0
		pop.add_child(chevron)
		var outline = ActivityCardStyles.page_switch_button_face()
		outline.name = "PageSwitchFaceOutline"
		outline.side = diagonal_side
		outline.ink_color = host.COLOR_INK
		outline.stroke_width = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
		outline.draw_fill = false
		outline.set_anchors_preset(Control.PRESET_FULL_RECT)
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline.z_index = 260
		pop.add_child(outline)
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
				host.button_press_runtime.force_button_unpressed(button)
	if clear_transition:
		_clear_page_switch_render_cover_transition_state()
		_release_page_switch_transition_button()
		if _page_switch_scroll_cover_active():
			host._skill_swipe_activity_surface()._clear_skill_swipe_handoff_cover_immediate()


func _recover_stale_page_switch_input_lock() -> void:
	if page_switch_press_active and _active_page_switch_button() == null:
		_clear_page_switch_press_state()
	if page_switch_transition_button_id != 0:
		var button: Button = host._app_lifecycle_runtime().valid_button_ref(instance_from_id(page_switch_transition_button_id))
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
	var event_position: Vector2 = host._input_routing_shell()._passive_button_event_position(event, button)
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
		host.button_press_runtime.play_default_button_sfx()
		_press_page_switch_button_shell(button)
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if bool(button.get_meta("page_switch_press_active", false)):
			var press_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(button, "page_switch_press_position", event_position)
			if event_position.distance_to(press_position) > host.PASSIVE_BUTTON_TAP_RELEASE_SLOP:
				button.set_meta("page_switch_press_dragged", true)
		return
	if not is_release:
		return
	var was_active := bool(button.get_meta("page_switch_press_active", false))
	var was_dragged := bool(button.get_meta("page_switch_press_dragged", false))
	var press_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(button, "page_switch_press_position", event_position)
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
	_select_skill_from_page_switch(skill_id, button)


func _on_page_switch_button_pressed(skill_id: String, button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if host.current_screen != "skill":
		return
	if not _page_switch_button_belongs_to_current_page(button):
		return
	if _page_switch_pressed_signal_suppressed(button):
		return
	host.button_press_runtime.force_button_unpressed(button)


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
	var button: Button = host._app_lifecycle_runtime().valid_button_ref(instance_from_id(button_id))
	if button == null:
		return
	if button.has_meta("page_switch_transition_hold"):
		button.remove_meta("page_switch_transition_hold")
	if button.has_meta("activity_button_hold_nav_press"):
		button.remove_meta("activity_button_hold_nav_press")
	if button.has_meta("activity_button_hold_nav_target_active"):
		button.remove_meta("activity_button_hold_nav_target_active")
	_clear_page_switch_button_press_state(button)
	host.button_press_runtime.force_button_unpressed(button)
	host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button_id, true)


func _release_page_switch_transition_button_visual_hold() -> void:
	var button_id := page_switch_transition_button_id
	if button_id == 0:
		return
	var button: Button = host._app_lifecycle_runtime().valid_button_ref(instance_from_id(button_id))
	if button == null:
		return
	if _page_switch_scroll_cover_active():
		if button.has_meta("activity_button_hold_nav_press"):
			button.remove_meta("activity_button_hold_nav_press")
		if button.has_meta("activity_button_hold_nav_target_active"):
			button.remove_meta("activity_button_hold_nav_target_active")
		_clear_page_switch_button_press_state(button, false)
		host.button_press_runtime.force_button_unpressed(button)
		host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button_id, true)
		return
	if button.has_meta("activity_button_hold_nav_press"):
		button.remove_meta("activity_button_hold_nav_press")
	if button.has_meta("activity_button_hold_nav_target_active"):
		button.remove_meta("activity_button_hold_nav_target_active")
	_clear_page_switch_button_press_state(button, false)
	host.button_press_runtime.force_button_unpressed(button)
	host._skill_swipe_activity_surface().forget_depressed_activity_shell_button(button_id)
	var pop := host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(button.get_meta("activity_button_pop_id", 0)))) as Control
	if pop != null:
		host._skill_swipe_activity_surface()._kill_activity_button_shell_tween(button)
		host._skill_swipe_activity_surface()._set_activity_button_pop_depth_offset_bound(Vector2.ZERO, pop.get_instance_id())
	host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button_id, true)


func _press_page_switch_button_shell(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var button_id := button.get_instance_id()
	if host._skill_swipe_activity_surface().has_depressed_activity_shell_button(button_id):
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
	if not host._skill_swipe_activity_surface().has_depressed_activity_shell_button(button_id):
		return
	host._skill_swipe_activity_surface()._release_activity_button_shell_bound(button_id)


func _add_page_switch_skill_icon(parent: Control, skill_id: String, diagonal_side: String) -> void:
	parent.clip_contents = true
	var icon_clip := Control.new()
	icon_clip.name = "PageSwitchIconClip"
	icon_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_clip.offset_bottom = -ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
	icon_clip.clip_contents = true
	icon_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_clip.z_index = 170
	parent.add_child(icon_clip)
	var icon_center := _page_switch_skill_icon_center(diagonal_side)
	var icon := _page_switch_skill_symbol(skill_id, diagonal_side)
	icon.name = "PageSwitchSkillIcon"
	icon.z_index = 0
	icon.modulate = Color(1, 1, 1, 0.96)
	icon.anchor_top = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_top = icon_center.y - PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.y * 0.5 + ActivityCardStyles.ACTION_CARD_STROKE_WIDTH * 0.5
	icon.offset_bottom = icon_center.y + PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.y * 0.5 + ActivityCardStyles.ACTION_CARD_STROKE_WIDTH * 0.5
	if diagonal_side == "right":
		icon.anchor_left = 1.0
		icon.anchor_right = 1.0
	else:
		icon.anchor_left = 0.0
		icon.anchor_right = 0.0
	icon.offset_left = icon_center.x - PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.x * 0.5
	icon.offset_right = icon_center.x + PAGE_SWITCH_SKILL_ICON_STAGE_SIZE.x * 0.5
	icon_clip.add_child(icon)


func _page_switch_skill_symbol(skill_id: String, diagonal_side: String) -> Control:
	var stage := Control.new()
	stage.custom_minimum_size = PAGE_SWITCH_SKILL_ICON_STAGE_SIZE
	stage.size = PAGE_SWITCH_SKILL_ICON_STAGE_SIZE
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.clip_contents = false

	var symbol_size: Vector2 = SkillIconBadge.symbol_size(skill_id, _page_switch_skill_symbol_base_size(skill_id, diagonal_side))
	var symbol := SkillIconBadge.symbol_control(host, skill_id)
	symbol.name = "PageSwitchSkillIconSymbol"
	symbol.custom_minimum_size = symbol_size
	symbol.size = symbol_size
	symbol.position = SkillIconBadge.symbol_position(skill_id, PAGE_SWITCH_SKILL_ICON_STAGE_SIZE, symbol_size, host.SKILL_MENU_ICON_BADGE_SIZE) + _page_switch_skill_symbol_focus_offset(skill_id, diagonal_side)
	symbol.pivot_offset = symbol_size * 0.5
	symbol.rotation = SkillIconBadge.symbol_rotation(skill_id)
	symbol.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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
				return Vector2(196, 196)
			return Vector2(193, 193)
		_:
			return PAGE_SWITCH_SKILL_ICON_SYMBOL_BASE_SIZE


func _page_switch_skill_symbol_focus_offset(skill_id: String, diagonal_side: String) -> Vector2:
	match skill_id:
		"build":
			if diagonal_side == "right":
				return Vector2(-37, 21)
			return Vector2(56, 21)
		"woodcutting":
			if diagonal_side == "right":
				return Vector2(-40, 17)
			return Vector2(35, 17)
		"fishing":
			if diagonal_side == "right":
				return Vector2(-95, -4)
			return Vector2(52, -4)
		"thieving":
			if diagonal_side == "left":
				return Vector2(84, 4)
			return Vector2(-35, 4)
		"fight":
			if diagonal_side == "left":
				return Vector2(66, -18)
			return Vector2(-68, -18)
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


func _process_page_switch_pending_transition() -> void:
	if page_switch_release_when_render_idle:
		if screen_render_in_progress or not pending_screen_render_request.is_empty():
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
	if screen_render_in_progress or not pending_screen_render_request.is_empty():
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
	_render_screen()
	_mark_page_switch_release_after_render()


func _start_return_from_skills_utility_under_page_switch_cover(target_screen: String) -> void:
	host.current_screen = target_screen
	_render_screen()
	_mark_page_switch_release_after_render()


func _start_show_pinned_activities_under_page_switch_cover() -> void:
	host.current_screen = "pinned"
	_render_screen()
	_mark_page_switch_release_after_render()


func _start_return_from_pinned_activities_under_page_switch_cover(target_screen: String, restore_scroll: int) -> void:
	host.current_screen = target_screen
	_render_screen(false, restore_scroll)
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
	host._skill_swipe_activity_surface()._clear_skill_swipe_button_suppression()
	if play_nav_sfx:
		host.button_press_runtime.play_default_button_sfx()
	if host._onboarding_runtime().tutorial_active:
		host.action_cards.clear()
		host.action_card_keys.clear()
		host._skill_detail_surface().detail_action_card_nodes.clear()
		host._skill_detail_surface().detail_rendered_action_ids.clear()
		host._skill_detail_surface().detail_lazy_plan.clear()
		_render_screen(false, 0)
	else:
		_render_screen(scroll_latest_activity, restore_detail_scroll)
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
	host.content_scroll.offset_top = SKILL_MENU_SHELF_HEIGHT
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = _skill_menu_active_drawer_content_width()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 26)
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
	shelf.offset_bottom = SKILL_MENU_SHELF_HEIGHT
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
	total_level_header.offset_bottom = SKILL_MENU_SHELF_HEIGHT
	total_level_header.add_theme_constant_override("margin_top", 75)
	total_level_header.add_theme_constant_override("margin_bottom", 6)
	total_level_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	total_level_header.z_index = 430
	host.skills_content.add_child(total_level_header)
	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 11)
	total_level_header.add_child(total_row)
	var total_icon: TextureRect = host.visual_texture_cache._image(host.TOTAL_LEVEL_BARGRAPH_TEXTURE, Vector2(59, 59))
	total_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	total_row.add_child(total_icon)
	total_row.add_child(host._label("Total Lv %s" % SkillState.global_level(host.skills), 77, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	host._skill_detail_surface().detail_shelf_shadow_alpha = 0.0
	host._skill_detail_surface().detail_shelf_shadow_overlay = host._skill_detail_surface()._add_skill_detail_shadow_overlay_to(host.skills_content, SKILL_MENU_SHELF_HEIGHT, host._skill_detail_surface().detail_shelf_shadow_alpha)


func _render_skill_menu(stack: VBoxContainer) -> void:
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, SKILL_MENU_TOP_SCROLL_PAD)
	stack.add_child(top_spacer)
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		var theme_color: Color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
		var card_slot := Control.new()
		card_slot.custom_minimum_size = Vector2(0, SKILL_MENU_HEADER_HEIGHT)
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
		var card_fill: Color = ThemeStyles.skill_paper_button_color(skill_id, host.dark_mode_enabled, SKILL_MENU_LIGHT_PASTEL_MIX, SKILL_MENU_DARK_THEME_DARKEN, host.COLOR_DARK_PANEL, SKILL_MENU_DARK_PANEL_MIX, host.COLOR_BLUE)
		button.add_theme_stylebox_override("normal", _skill_menu_band_style(card_fill))
		button.add_theme_stylebox_override("hover", _skill_menu_band_style(card_fill))
		button.add_theme_stylebox_override("pressed", _skill_menu_band_style(card_fill.darkened(0.08), true))
		host.button_press_runtime.attach_button_depress_animation(button, 0.982)
		button.pressed.connect(_select_skill.bind(skill_id))
		card_slot.add_child(button)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 36)
		margin.add_theme_constant_override("margin_right", 36)
		margin.add_theme_constant_override("margin_top", 17)
		margin.add_theme_constant_override("margin_bottom", 36)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.z_index = 20
		button.add_child(margin)
		
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)
		row.add_child(SkillIconBadge.menu_icon_badge(host, skill_id, theme_color))
		var copy := VBoxContainer.new()
		copy.custom_minimum_size.x = SKILL_MENU_COPY_WIDTH
		copy.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		copy.add_theme_constant_override("separation", 15)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var title: Label = host._label("", 66, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(title)
		var meta: Label = host._label("", 52, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(meta)
		var xp_bar: Control = ThemeStyles.progress_bar(theme_color, 62)
		ThemeStyles.apply_xp_progress_bar_theme(xp_bar, theme_color, host.COLOR_INK)
		xp_bar.custom_minimum_size.x = 380
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
		}
		var accessible: bool = host._onboarding_runtime()._onboarding_skill_accessible(skill_id)
		button.disabled = not accessible
		button.modulate = Color.WHITE if accessible else HUB_NAV_LOCKED_MODULATE
		var drawer_slot := Control.new()
		drawer_slot.name = "SkillMenuActiveDrawer_%s" % skill_id
		drawer_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		drawer_slot.custom_minimum_size = Vector2(0, 0)
		drawer_slot.visible = false
		drawer_slot.clip_contents = false
		stack.add_child(drawer_slot)
		skill_menu_active_drawers[skill_id] = {
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
		fish_gauge.custom_minimum_size = Vector2(270, 270)
		fish_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fish_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return fish_gauge
	var stamina_gauge := RegenCircle.new()
	stamina_gauge.custom_minimum_size = Vector2(270, 270)
	stamina_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stamina_gauge.mouse_filter = Control.MOUSE_FILTER_STOP
	stamina_gauge.set_dark_mode(host.dark_mode_enabled)
	stamina_gauge.set_theme_color(theme_color)
	stamina_gauge.gui_input.connect(Callable(host._action_runtime(), "_on_stamina_gauge_input").bind(skill_id, stamina_gauge))
	return stamina_gauge


func _normalize_skill_menu_card_button(card: Dictionary) -> void:
	var button := card.get("button") as BaseButton
	if button == null or not is_instance_valid(button):
		return
	if button.scale.x <= 1.0001 and button.scale.y <= 1.0001:
		return
	host.button_press_runtime.kill_button_depress_tween(button)
	button.scale = Vector2.ONE
	button.pivot_offset = button.size * 0.5


func _sync_skill_menu_page(delta: float, instant: bool, static_refresh: bool) -> void:
	host._skill_detail_surface()._update_skill_detail_shadow(delta, instant)
	for skill_id in host.skill_cards.keys():
		var skill_id_text := str(skill_id)
		var card: Dictionary = host.skill_cards[skill_id]
		if static_refresh:
			_normalize_skill_menu_card_button(card)
			host._app_lifecycle_runtime().set_label_text_if_changed(card["title"] as Label, "%s" % SkillState.skill_name(host.skill_defs, skill_id_text))
			host._app_lifecycle_runtime().set_label_text_if_changed(card["meta"] as Label, SkillState.level_xp_text(host.skills, skill_id_text, SkillState.host_skill_level(host, skill_id_text)))
			ThemeStyles.apply_xp_progress_bar_theme(card["xp"] as CleanProgressBar, ThemeStyles.skill_theme_color(skill_id_text, host.COLOR_BLUE), host.COLOR_INK)
		var xp := SkillState.xp_progress(host.skills, skill_id_text, SkillState.host_skill_level(host, skill_id_text))
		ThemeStyles.set_progress_bar_value(card["xp"], float(xp["pct"]), delta, instant)
		_update_skill_menu_card(card, skill_id_text, delta, instant)
		_sync_skill_menu_active_drawer(skill_id_text, instant)


func _update_skill_menu_card(card: Dictionary, skill_id: String, delta: float, instant: bool) -> void:
	var button := card.get("button") as Button
	if button != null and is_instance_valid(button):
		var accessible: bool = host._onboarding_runtime()._onboarding_skill_accessible(skill_id)
		host._app_lifecycle_runtime().set_base_button_disabled_if_changed(button, not accessible)
		host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(button, Color.WHITE if accessible else HUB_NAV_LOCKED_MODULATE)
	var activity_running := false
	var activity_progress := card.get("activity") as ActivityProgressRail
	if activity_progress != null and is_instance_valid(activity_progress):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(activity_progress, activity_running)
	if host._fishing_rework_active_for_skill(skill_id):
		var fish_gauge := card.get("fish") as FishCircle
		if fish_gauge != null:
			host._fishing_ui_surface()._set_fish_circle_for_skill(fish_gauge, skill_id, instant)
		return
	var stamina_gauge := card.get("stamina") as RegenCircle
	if stamina_gauge != null:
		stamina_gauge.sync_for_skill(host, skill_id, instant)


func _skill_menu_bottom_scroll_pad() -> float:
	return _bottom_ui_reserved_height_for_current_screen() + float(SKILL_MENU_BOTTOM_SCROLL_CLEARANCE)


func _skill_menu_active_drawer_card_key(skill_id: String, action_id: String) -> String:
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	return "skill_menu_active:%s:%s" % [skill_id, action_id]


func _skill_menu_active_drawer_module_key(skill_id: String, action_id: String) -> String:
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	if host._fishing_rework_active_for_skill(skill_id):
		var area_def: Dictionary = host._fishing_ui_surface().render_area_module_for_action(skill_id, action_id)
		if not area_def.is_empty():
			return ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key(skill_id, area_def))
	return ModuleUiRuntime.action_for_record(skill_id, host._action_data(skill_id, action_id), host.FISHING_ACTION_ID_ALIASES)


func _skill_menu_active_drawer_content_width() -> float:
	return maxf(host.BASE_CANVAS.x, host._skill_column_host_width())


func _clear_skill_menu_active_drawer(drawer: Dictionary) -> void:
	for raw_card_key in drawer.get("card_keys", []) as Array:
		host._skill_detail_surface()._discard_action_card_key(str(raw_card_key))
	var card_key := str(drawer.get("card_key", ""))
	if not card_key.is_empty():
		host._skill_detail_surface()._discard_action_card_key(card_key)
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
	if skill_id.is_empty() or not skill_menu_active_drawers.has(skill_id):
		return
	var drawer := skill_menu_active_drawers.get(skill_id, {}) as Dictionary
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
	var collapsed: bool = host._skill_detail_surface()._module_ui_is_collapsed(module_key)
	var card_key := _skill_menu_active_drawer_card_key(skill_id, action_id)
	var active_fishing_area_def := {}
	if host._fishing_rework_active_for_skill(skill_id):
		active_fishing_area_def = host._fishing_ui_surface().render_area_module_for_action(skill_id, action_id)
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
	if host._passive_modules_runtime().is_passive_action(action):
		var passive_card: Dictionary = host._passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
		module_root = passive_card.get("root") as Control
		var passive_dict := passive_card.get("card", {}) as Dictionary
		passive_dict["entry"] = module_root
		passive_dict["action_id"] = action_id
		host._skill_detail_surface()._register_action_card(card_key, passive_dict)
		host._skill_detail_surface()._detail_lazy_finalize_action_card(passive_dict, skill_id, action, action_id)
		registered_card_key = card_key
		registered_card_keys.append(card_key)
	elif not active_fishing_area_def.is_empty():
		var built: Dictionary = host._build_fishing_area_module(skill_id, active_fishing_area_def, content_width)
		module_root = built.get("root") as Control
		var area_key := str(built.get("area_key", ""))
		var area_card := built.get("area_card", {}) as Dictionary
		if not area_key.is_empty() and not area_card.is_empty():
			area_card["entry"] = module_root
			host._skill_detail_surface()._register_action_card(area_key, area_card)
			registered_card_key = area_key
			registered_card_keys.append(area_key)
			for raw_method_id in built.get("method_ids", []) as Array:
				var method_key: String = host._action_key(skill_id, str(raw_method_id))
				if host.action_cards.has(method_key):
					registered_card_keys.append(method_key)
				var method_card: Dictionary = host._fishing_ui_surface()._fishing_method_card_for_action(skill_id, str(raw_method_id))
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
		host._skill_detail_surface()._register_action_card(card_key, card)
		host._skill_detail_surface()._detail_lazy_finalize_action_card(card, skill_id, action, action_id)
		registered_card_key = card_key
		registered_card_keys.append(card_key)
	if module_root == null:
		return
	module_root = host._skill_detail_surface()._apply_collapsed_module_squeeze(module_root, module_key, collapsed)
	var module_height := maxf(1.0, module_root.custom_minimum_size.y)
	slot.custom_minimum_size = Vector2(slot_width, module_height + SKILL_MENU_ACTIVE_DRAWER_TOP_PAD + SKILL_MENU_ACTIVE_DRAWER_BOTTOM_PAD)
	slot.visible = true
	var module_left := maxf(0.0, (slot_width - content_width) * 0.5)
	module_root.anchor_left = 0.0
	module_root.anchor_right = 0.0
	module_root.anchor_top = 0.0
	module_root.anchor_bottom = 0.0
	module_root.offset_left = module_left
	module_root.offset_right = module_left + content_width
	module_root.offset_top = SKILL_MENU_ACTIVE_DRAWER_TOP_PAD
	module_root.offset_bottom = SKILL_MENU_ACTIVE_DRAWER_TOP_PAD + module_height
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
	host._skill_swipe_activity_surface()._apply_skill_column_layout(frame, content_width, 0.0)
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
	host.content_scroll.gui_input.connect(_on_pinned_activities_action_scroll_input)
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
	stack.add_child(_build_pinned_activities_shelf_content(content_width))
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, _skills_content_bottom_inset_for_screen() + 52.0)
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(bottom_spacer)
	_add_pinned_active_shelf_shadow_overlay()


func _refresh_pinned_activities_shelf_after_pin_change() -> void:
	if host.current_screen != "pinned" or host.content_scroll == null or not is_instance_valid(host.content_scroll):
		return
	var existing_shelf: Control = host._find_named_control_descendant(host.content_scroll, "PinnedActivitiesShelf")
	var existing_empty: Control = host._find_named_control_descendant(host.content_scroll, "PinnedActivitiesEmptyState")
	var anchor: Control = existing_shelf if existing_shelf != null else existing_empty
	if anchor == null:
		return
	var stack := anchor.get_parent() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return
	var insert_index: int = anchor.get_index()
	var previous_scroll := int(round(host.content_scroll.scroll_vertical))
	var old_keys: Array[String] = []
	for child in stack.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		if child_control.name == "PinnedActivitiesShelf":
			for raw_module in child_control.get_children():
				var module_control := raw_module as Control
				if module_control == null:
					continue
				var module_key := ModuleUiRuntime.normalize(module_control.get_meta("module_ui_key", ""))
				if not module_key.is_empty():
					old_keys.append(module_key)
			stack.remove_child(child_control)
			child_control.queue_free()
		elif child_control.name == "PinnedActivitiesEmptyState":
			stack.remove_child(child_control)
			child_control.queue_free()
	for old_key in old_keys:
		host.action_cards.erase(_pinned_page_card_key(old_key))
	var content_width: float = host._skill_content_width()
	var replacement := _build_pinned_activities_shelf_content(content_width)
	stack.add_child(replacement)
	stack.move_child(replacement, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))
	host.content_scroll.scroll_vertical = previous_scroll
	if host.content_scroll is MobileScrollContainer:
		(host.content_scroll as MobileScrollContainer).drag_scroll_position = float(previous_scroll)


func _build_pinned_activities_shelf_content(content_width: float) -> Control:
	var shelf := VBoxContainer.new()
	shelf.name = "PinnedActivitiesShelf"
	shelf.custom_minimum_size = Vector2(content_width, 0)
	shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelf.add_theme_constant_override("separation", 17)
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for raw_key in host.module_ui_runtime.pinned_order:
		var module_key := ModuleUiRuntime.normalize(raw_key)
		if module_key.is_empty():
			continue
		var module_root := _build_pinned_activities_module(module_key, content_width)
		if module_root == null:
			continue
		module_root.set_meta("module_ui_pinned_page_copy", true)
		module_root.set_meta("module_ui_force_expanded", true)
		module_root.set_meta("module_ui_key", module_key)
		host._skill_detail_surface()._remove_module_collapse_zones(module_root)
		_remove_registered_card_collapse_zone(_pinned_page_card_key(module_key))
		shelf.add_child(module_root)
	if shelf.get_child_count() <= 0:
		shelf.queue_free()
		return _pinned_activities_empty_state(content_width)
	return shelf


func _on_pinned_activities_action_scroll_input(event: InputEvent) -> void:
	if host.current_screen != "pinned" and host.current_screen != "queue":
		return
	var routed_event := _pinned_activities_globalized_scroll_event(event)
	if routed_event == null:
		return
	if host._input_routing_shell()._event_points_inside_bottom_interactive_ui(routed_event):
		return
	if host._input_routing_shell()._route_action_card_release(routed_event):
		host.accept_event()
		return
	host._skill_detail_surface()._update_action_card_press_drag_state(routed_event)
	if routed_event is InputEventMouseButton and routed_event.button_index == MOUSE_BUTTON_LEFT and routed_event.pressed:
		host.action_card_press_consumed = false
		var routed_mouse_event := routed_event as InputEventMouseButton
		var press_position: Vector2 = routed_mouse_event.global_position
		if host._input_routing_shell()._route_action_card_press(press_position):
			host.accept_event()
			return
	elif routed_event is InputEventScreenTouch and routed_event.pressed:
		host.action_card_press_consumed = false
		var routed_touch_event := routed_event as InputEventScreenTouch
		var touch_position: Vector2 = routed_touch_event.position
		if host._input_routing_shell()._route_action_card_press(touch_position, routed_touch_event.index):
			host.accept_event()
			return


func _pinned_activities_globalized_scroll_event(event: InputEvent) -> InputEvent:
	if host.content_scroll == null or not is_instance_valid(host.content_scroll):
		return null
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var global_position: Vector2 = host._input_routing_shell()._global_event_position(mouse_event.position, mouse_event.global_position, host.content_scroll)
		var routed := InputEventMouseButton.new()
		routed.button_index = mouse_event.button_index
		routed.pressed = mouse_event.pressed
		routed.button_mask = mouse_event.button_mask
		routed.position = global_position
		routed.global_position = global_position
		return routed
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		var global_position: Vector2 = host._input_routing_shell()._global_event_position(motion_event.position, motion_event.global_position, host.content_scroll)
		var routed := InputEventMouseMotion.new()
		routed.position = global_position
		routed.global_position = global_position
		routed.relative = motion_event.relative
		routed.velocity = motion_event.velocity
		return routed
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		var global_position: Vector2 = host.content_scroll.get_global_transform() * touch_event.position
		var routed := InputEventScreenTouch.new()
		routed.index = touch_event.index
		routed.pressed = touch_event.pressed
		routed.position = global_position
		return routed
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		var global_position: Vector2 = host.content_scroll.get_global_transform() * drag_event.position
		var routed := InputEventScreenDrag.new()
		routed.index = drag_event.index
		routed.position = global_position
		routed.relative = drag_event.relative
		routed.velocity = drag_event.velocity
		return routed
	return event


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
		52,
		host.COLOR_INK,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	label.name = "PinnedActivitiesEmptyStateLabel"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 24
	label.offset_right = -24
	label.offset_top = 0
	label.offset_bottom = 0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 2)
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
	var badge_top_left_offset: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_ORIGIN + ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	var badge_visible_height: float = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_SIZE.y - ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION.y
	var hit_zone_size: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MAX - ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MIN
	hit_zone_size.y = minf(hit_zone_size.y, badge_visible_height - ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MIN.y)
	var horizontal_margin := 30.0
	var vertical_margin := 26.0
	var occupied_rects: Array[Rect2] = []
	for index in range(PINNED_ACTIVITIES_EMPTY_DECOR_PIN_COUNT):
		var badge_position := _pinned_activities_empty_decor_pin_position(
			rng,
			content_width,
			empty_height,
			ModuleUiRuntime.MODULE_PIN_BADGE_SIZE.x,
			badge_visible_height,
			horizontal_margin,
			vertical_margin,
			occupied_rects
		)
		var badge_left := badge_position.x
		var badge_top := badge_position.y
		occupied_rects.append(Rect2(badge_position, Vector2(ModuleUiRuntime.MODULE_PIN_BADGE_SIZE.x, badge_visible_height)).grow(18.0))
		var decor_host := Control.new()
		decor_host.name = "PinnedActivitiesEmptyDecorPin_%s" % index
		decor_host.anchor_left = 0.0
		decor_host.anchor_right = 0.0
		decor_host.anchor_top = 0.0
		decor_host.anchor_bottom = 0.0
		decor_host.position = Vector2(badge_left, badge_top) - badge_top_left_offset
		decor_host.size = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_SIZE
		decor_host.custom_minimum_size = ModuleUiRuntime.MODULE_PIN_BADGE_CLIP_SIZE
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
		hit_zone.position = decor_host.position + badge_top_left_offset + ModuleUiRuntime.MODULE_PIN_BADGE_HIT_MIN
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
	var badge: TextureButton = host._skill_detail_surface()._ensure_module_pin_badge(decor_host, "")
	if badge == null:
		return null
	badge.name = "PinnedActivitiesEmptyDecorPinBadge_%s" % index
	if badge.is_in_group("module_pin_badges"):
		badge.remove_from_group("module_pin_badges")
	var texture_path: String = host.module_ui_runtime.random_pin_texture_path(ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE)
	badge.texture_normal = host.visual_texture_cache._texture_or_visual_fallback(texture_path)
	badge.texture_pressed = badge.texture_normal
	badge.texture_hover = badge.texture_normal
	badge.texture_disabled = badge.texture_normal
	badge.texture_focused = badge.texture_normal
	badge.set_meta("module_pin_texture_path", texture_path)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.disabled = true
	badge.visible = true
	badge.position = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	badge.set_meta("module_pin_module_key", "")
	badge.set_meta("pinned_activities_empty_decor_pin", true)
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 1.0)
	host._skill_detail_surface()._set_module_pin_badge_clip_enabled(badge, true)
	host._skill_detail_surface()._set_module_pin_entry_seam_visible(badge, true)
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
	var hit_zone: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(hit_zone_id))
	if hit_zone != null:
		hit_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hit_zone.accept_event()
	var decor_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(decor_host_id))
	var badge: TextureButton = host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(badge_id))
	if decor_host == null or badge == null:
		return
	_play_pinned_activities_empty_decor_pin_exit_animation(badge, decor_host, hit_zone_id)


func _pinned_activities_empty_state_height() -> float:
	var active_shelf_height: float = _pinned_active_shelf_target_height(_pinned_active_shelf_skill_id())
	var content_top_reserved: float = active_shelf_height + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT + host.SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT
	var visible_bottom: float = host.BASE_CANVAS.y - float(BOTTOM_NAV_HEIGHT) - _skills_content_bottom_inset_for_screen()
	return maxf(860.0, visible_bottom - content_top_reserved)


func _play_pinned_activities_empty_decor_pin_exit_animation(badge: TextureButton, decor_host: Control, hit_zone_id: int) -> void:
	if badge == null or decor_host == null or not is_instance_valid(badge) or not is_instance_valid(decor_host):
		return
	if badge.is_queued_for_deletion() or decor_host.is_queued_for_deletion() or badge.has_meta("module_pin_tween"):
		return
	host._skill_detail_surface()._set_module_pin_entry_seam_visible(badge, false)
	host._skill_detail_surface()._set_module_pin_badge_clip_enabled(badge, true)
	badge.visible = true
	badge.disabled = true
	badge.position = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(badge, 1.0)
	host._audio_director()._play_module_pin_exit_sfx()
	var tween: Tween = host.create_tween()
	badge.set_meta("module_pin_tween", tween)
	var badge_id := badge.get_instance_id()
	tween.set_parallel(true)
	tween.tween_method(host._skill_detail_surface()._keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, 0.075)
	tween.tween_property(badge, "position", ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION + ModuleUiRuntime.MODULE_PIN_EXIT_LIFT_OFFSET, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_callback(host._skill_detail_surface()._set_module_pin_badge_clip_enabled_by_id.bind(badge.get_instance_id(), false))
	tween.set_parallel(true)
	tween.tween_method(host._skill_detail_surface()._keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, 0.195)
	tween.tween_property(badge, "position", ModuleUiRuntime.MODULE_PIN_BADGE_PULL_OUT_POSITION, 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "scale", Vector2(0.96, 0.96), 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "modulate:a", 0.0, 0.15).set_delay(0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(_finish_pinned_activities_empty_decor_pin_exit_animation.bind(badge.get_instance_id(), decor_host.get_instance_id(), hit_zone_id))


func _finish_pinned_activities_empty_decor_pin_exit_animation(badge_id: int, decor_host_id: int, hit_zone_id: int) -> void:
	var hit_zone: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(hit_zone_id))
	if hit_zone != null and not hit_zone.is_queued_for_deletion():
		hit_zone.queue_free()
	var badge: TextureButton = host._app_lifecycle_runtime().valid_texture_button_ref(instance_from_id(badge_id))
	if badge != null and not badge.is_queued_for_deletion() and badge.has_meta("module_pin_tween"):
		badge.remove_meta("module_pin_tween")
	var decor_host: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(decor_host_id))
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
	pinned_active_shelf_header = header

	var body := Control.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(body)
	pinned_active_shelf_background = _add_pinned_active_shelf_background(body, active_skill_id, content_width)
	body.add_child(_activity_queue_static_title())
	pinned_active_shelf_stamina_strip = _build_pinned_active_shelf_stamina_strip()
	body.add_child(pinned_active_shelf_stamina_strip)

	pinned_active_shelf_content = Control.new()
	pinned_active_shelf_content.name = "ActivityQueueActiveShelfContent"
	pinned_active_shelf_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	pinned_active_shelf_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pinned_active_shelf_content.z_index = 20
	body.add_child(pinned_active_shelf_content)

	_rebuild_pinned_active_shelf_content(active_skill_id, true)
	return header

func _activity_queue_static_title() -> Label:
	var title: Label = host._label("Activity Queue", 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "ActivityQueueTitle"
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 0.0
	title.offset_left = 0.0
	title.offset_right = 0.0
	title.offset_top = 10.0
	title.offset_bottom = 90.0
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
	pinned_active_shelf_header = header

	var body := Control.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(body)
	pinned_active_shelf_background = _add_pinned_active_shelf_background(body, active_skill_id, content_width)
	body.add_child(_pinned_activities_static_title())
	pinned_active_shelf_stamina_strip = _build_pinned_active_shelf_stamina_strip()
	body.add_child(pinned_active_shelf_stamina_strip)

	pinned_active_shelf_content = Control.new()
	pinned_active_shelf_content.name = "PinnedActivitiesActiveShelfContent"
	pinned_active_shelf_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	pinned_active_shelf_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pinned_active_shelf_content.z_index = 20
	body.add_child(pinned_active_shelf_content)

	_rebuild_pinned_active_shelf_content(active_skill_id, true)
	return header

func _pinned_active_shelf_expanded_height() -> float:
	return host.SKILLS_PAGE_TOP_PAD + host.SKILL_DETAIL_HEADER_HEIGHT

func _pinned_active_shelf_target_height(skill_id: String) -> float:
	return _pinned_active_shelf_expanded_height()

func _pinned_active_shelf_shadow_top_y() -> float:
	if pinned_active_shelf_header != null and is_instance_valid(pinned_active_shelf_header):
		return maxf(1.0, pinned_active_shelf_header.custom_minimum_size.y + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)
	return _pinned_active_shelf_target_height(_pinned_active_shelf_skill_id()) + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT

func _add_pinned_active_shelf_shadow_overlay() -> void:
	if host.skills_content == null:
		return
	host._skill_detail_surface().detail_shelf_shadow_alpha = host._skill_detail_surface()._skill_detail_shadow_target_alpha()
	host._skill_detail_surface().detail_shelf_shadow_overlay = host._skill_detail_surface()._add_skill_detail_shadow_overlay_to(host.skills_content, _pinned_active_shelf_shadow_top_y(), host._skill_detail_surface().detail_shelf_shadow_alpha)

func _add_pinned_active_shelf_background(parent: Control, skill_id: String, content_width: float) -> Control:
	var background: Control = host._skill_detail_surface()._add_skill_detail_shelf_background(parent, _pinned_active_shelf_theme_skill_id(skill_id), content_width)
	background.name = "PinnedActivitiesFullBleedShelfBackground"
	background.z_index = 0
	return background

func _pinned_activities_static_title() -> Label:
	var title: Label = host._label("Pinned Activities", 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "PinnedActivitiesTitle"
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.0
	title.anchor_bottom = 0.0
	title.offset_left = 0.0
	title.offset_right = 0.0
	title.offset_top = 19.5
	title.offset_bottom = 56.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.z_index = 50
	return title

func _pinned_active_shelf_skill_id() -> String:
	if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty() and _running_action_is_pinned():
		return host.running_skill_id
	return _pinned_active_shelf_jailed_skill_id()

func _pinned_active_shelf_jailed_skill_id() -> String:
	if host.thieving_state.action_jails.is_empty():
		return ""
	for raw_action_id in host.thieving_state.action_jails.keys():
		var action_id := str(raw_action_id)
		if action_id.is_empty() or host._thieving_surface()._thieving_action_jail_remaining(action_id) <= 0:
			continue
		var state := host.thieving_state.action_jails.get(action_id, {}) as Dictionary
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
			for raw_area_def in host._fishing_ui_surface().render_area_modules("fishing"):
				var area_def := raw_area_def as Dictionary
				if host.fishing_runtime.area_module_key("fishing", area_def) == area_key and host.fishing_runtime.action_belongs_to_area(host, str(area_def.get("id", "")), host.running_action_id):
					return true
	return false

func _rebuild_pinned_active_shelf_content(skill_id: String, instant := false) -> void:
	if pinned_active_shelf_content == null or not is_instance_valid(pinned_active_shelf_content):
		return
	if pinned_active_shelf_tween != null and pinned_active_shelf_tween.is_valid():
		pinned_active_shelf_tween.kill()
	pinned_active_shelf_tween = null
	host._clear(pinned_active_shelf_content)
	pinned_active_shelf_skill_id = skill_id
	pinned_active_shelf_transition_skill_id = ""
	pinned_active_shelf_transition_active = false
	pinned_active_shelf_xp_label = null
	pinned_active_shelf_xp_bar = null
	pinned_active_shelf_regen_circle = null
	pinned_active_shelf_fish_circle = null
	_apply_pinned_active_shelf_theme(skill_id, instant)
	if skill_id.is_empty():
		host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(pinned_active_shelf_content, 0.0)
		_set_pinned_active_shelf_stamina_strip_visible(true)
		_sync_pinned_active_shelf_stamina_gauges(0.0, true)
		return
	_set_pinned_active_shelf_stamina_strip_visible(false)
	_build_pinned_active_shelf_skill_content(pinned_active_shelf_content, skill_id)
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(pinned_active_shelf_content, 1.0 if instant else 0.0)
	if not instant:
		pinned_active_shelf_tween = host.create_tween()
		pinned_active_shelf_tween.tween_property(pinned_active_shelf_content, "modulate:a", 1.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if pinned_active_shelf_background != null and is_instance_valid(pinned_active_shelf_background):
			pinned_active_shelf_tween.parallel().tween_property(pinned_active_shelf_background, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _build_pinned_active_shelf_stamina_strip() -> Control:
	var strip := Control.new()
	strip.name = "PinnedActivitiesStaminaGaugeShelf"
	strip.set_anchors_preset(Control.PRESET_FULL_RECT)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.z_index = 12
	pinned_active_shelf_stamina_gauges.clear()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", host.SKILLS_PAGE_TOP_PAD + 76)
	margin.add_theme_constant_override("margin_bottom", 37)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
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
		gauge.gui_input.connect(Callable(host._action_runtime(), "_on_stamina_gauge_input").bind(skill_id, gauge))
		row.add_child(gauge)
		gauge.sync_for_skill(host, skill_id, true)
		pinned_active_shelf_stamina_gauges[skill_id] = gauge
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
	if pinned_active_shelf_stamina_strip == null or not is_instance_valid(pinned_active_shelf_stamina_strip):
		return
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(pinned_active_shelf_stamina_strip, visible)
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(pinned_active_shelf_stamina_strip, 1.0 if visible else 0.0)

func _sync_pinned_active_shelf_stamina_gauges(_delta: float, instant := false) -> void:
	var live := {}
	for raw_skill_id in pinned_active_shelf_stamina_gauges.keys():
		var skill_id := str(raw_skill_id)
		var gauge := pinned_active_shelf_stamina_gauges.get(raw_skill_id, null) as RegenCircle
		if gauge == null or not is_instance_valid(gauge):
			continue
		live[skill_id] = gauge
		gauge.sync_for_skill(host, skill_id, instant)
	pinned_active_shelf_stamina_gauges = live

func _build_pinned_active_shelf_skill_content(parent: Control, skill_id: String) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 33)
	margin.add_theme_constant_override("margin_right", 23)
	margin.add_theme_constant_override("margin_top", host.SKILLS_PAGE_TOP_PAD + 88)
	margin.add_theme_constant_override("margin_bottom", host.SKILL_DETAIL_HEADER_MARGIN_BOTTOM + host.SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(margin)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 33)
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

	var title: Label = host._label(SkillState.skill_name(host.skill_defs, skill_id), SkillState.skill_detail_title_font_size(skill_id, host.SKILL_DETAIL_TITLE_FONT_SIZE, host.SKILL_DETAIL_WOODCUTTING_TITLE_FONT_SIZE), host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(title)
	pinned_active_shelf_xp_label = host._label(SkillState.level_xp_text(host.skills, skill_id, SkillState.host_skill_level(host, skill_id)), host.SKILL_DETAIL_XP_FONT_SIZE, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	pinned_active_shelf_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(pinned_active_shelf_xp_label)
	var xp: Dictionary = SkillState.xp_progress(host.skills, skill_id, SkillState.host_skill_level(host, skill_id))
	pinned_active_shelf_xp_bar = ThemeStyles.skill_detail_xp_bar(skill_id, float(xp["pct"]), host.COLOR_BLUE, host.COLOR_INK, host.SKILL_DETAIL_XP_BAR_HEIGHT, host.SKILL_DETAIL_XP_BAR_WIDTH)
	title_stack.add_child(pinned_active_shelf_xp_bar)

	if host._fishing_rework_active_for_skill(skill_id):
		pinned_active_shelf_fish_circle = FishCircle.new()
		pinned_active_shelf_fish_circle.custom_minimum_size = Vector2(276, 276)
		pinned_active_shelf_fish_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pinned_active_shelf_fish_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_row.add_child(pinned_active_shelf_fish_circle)
		host._fishing_ui_surface()._set_fish_circle_for_skill(pinned_active_shelf_fish_circle, skill_id, true)
	else:
		var regen_circle_host := Control.new()
		regen_circle_host.custom_minimum_size = Vector2(276, 276)
		regen_circle_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		regen_circle_host.clip_contents = false
		header_row.add_child(regen_circle_host)
		pinned_active_shelf_regen_circle = RegenCircle.new()
		pinned_active_shelf_regen_circle.custom_minimum_size = Vector2(276, 276)
		pinned_active_shelf_regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pinned_active_shelf_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
		pinned_active_shelf_regen_circle.gui_input.connect(Callable(host._action_runtime(), "_on_stamina_gauge_input").bind(skill_id, pinned_active_shelf_regen_circle))
		regen_circle_host.add_child(pinned_active_shelf_regen_circle)
		host._fishing_ui_surface()._attach_auto_eat_fish_toggle(regen_circle_host, skill_id)
		pinned_active_shelf_regen_circle.sync_for_skill(host, skill_id, true)

func _apply_pinned_active_shelf_theme(skill_id: String, instant := false) -> void:
	if pinned_active_shelf_content == null or not is_instance_valid(pinned_active_shelf_content):
		return
	var body := pinned_active_shelf_content.get_parent() as Control
	if body == null:
		return
	var header := body.get_parent() as PanelContainer
	if header != null:
		header.add_theme_stylebox_override("panel", _pinned_active_shelf_panel_style(skill_id))
	var background: Control = pinned_active_shelf_background
	if background == null or not is_instance_valid(background):
		for child in body.get_children():
			var panel := child as Control
			if panel != null and panel.name == "PinnedActivitiesFullBleedShelfBackground":
				background = panel
				pinned_active_shelf_background = panel
				break
	if background == null:
		return
	_apply_pinned_active_shelf_background_colors(background, skill_id)
	var target_alpha := 1.0
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(background, target_alpha if instant or skill_id.is_empty() else 0.0)

func _apply_pinned_active_shelf_background_colors(background: Control, skill_id: String) -> void:
	if not background.has_method("set_colors"):
		return
	if skill_id.is_empty():
		background.call("set_colors", Color("#ececea"), Color("#d4d2cc"))
		return
	var theme_skill_id := _pinned_active_shelf_theme_skill_id(skill_id)
	background.call("set_colors", host._skill_detail_surface()._skill_detail_shelf_color(theme_skill_id), host._skill_detail_surface()._skill_detail_shelf_gradient_bottom_color(theme_skill_id))

func _pinned_active_shelf_theme_skill_id(skill_id: String) -> String:
	return skill_id if not skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, skill_id) else "woodcutting"

func _pinned_active_shelf_panel_style(skill_id: String) -> StyleBoxFlat:
	if not skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, skill_id):
		return host._skill_detail_surface()._skill_detail_shelf_style(skill_id, false)
	return _pinned_active_shelf_style("", false)

func _pinned_active_shelf_style(skill_id: String, draw_bottom_border := true) -> StyleBoxFlat:
	if not skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, skill_id):
		return host._skill_detail_surface()._skill_detail_shelf_style(skill_id, draw_bottom_border)
	var style := StyleBoxFlat.new()
	style.bg_color = host.COLOR_PAPER
	style.border_color = Color(0.09, 0.08, 0.07, 0.12)
	style.border_width_bottom = 2.5 if draw_bottom_border else 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func _sync_pinned_active_shelf(delta: float, instant := false) -> void:
	if (host.current_screen != "pinned" and host.current_screen != "queue") or pinned_active_shelf_content == null or not is_instance_valid(pinned_active_shelf_content):
		return
	_sync_pinned_active_shelf_stamina_gauges(delta, instant)
	var active_skill_id: String = host._activity_queue_runtime()._activity_queue_active_shelf_skill_id() if host.current_screen == "queue" else _pinned_active_shelf_skill_id()
	if pinned_active_shelf_transition_active and active_skill_id == pinned_active_shelf_transition_skill_id:
		return
	if active_skill_id != pinned_active_shelf_skill_id:
		_transition_pinned_active_shelf_to(active_skill_id, instant)
		return
	if active_skill_id.is_empty():
		return
	var xp: Dictionary = SkillState.xp_progress(host.skills, active_skill_id, SkillState.host_skill_level(host, active_skill_id))
	if pinned_active_shelf_xp_label != null:
		host._app_lifecycle_runtime().set_label_text_if_changed(pinned_active_shelf_xp_label, SkillState.level_xp_text(host.skills, active_skill_id, SkillState.host_skill_level(host, active_skill_id)))
	if pinned_active_shelf_xp_bar != null:
		ThemeStyles.apply_xp_progress_bar_theme(pinned_active_shelf_xp_bar, ThemeStyles.skill_theme_color(active_skill_id, host.COLOR_BLUE), host.COLOR_INK)
		ThemeStyles.set_progress_bar_value(pinned_active_shelf_xp_bar, float(xp["pct"]), delta, instant)
	if pinned_active_shelf_fish_circle != null:
		host._fishing_ui_surface()._set_fish_circle_for_skill(pinned_active_shelf_fish_circle, active_skill_id, instant)
	elif pinned_active_shelf_regen_circle != null:
		pinned_active_shelf_regen_circle.sync_for_skill(host, active_skill_id, instant)

func _transition_pinned_active_shelf_to(skill_id: String, instant := false) -> void:
	if pinned_active_shelf_content == null or not is_instance_valid(pinned_active_shelf_content):
		return
	if pinned_active_shelf_tween != null and pinned_active_shelf_tween.is_valid():
		pinned_active_shelf_tween.kill()
	pinned_active_shelf_tween = null
	_animate_pinned_active_shelf_height(skill_id, instant)
	if instant:
		_rebuild_pinned_active_shelf_content(skill_id, true)
		return
	var current_alpha: float = pinned_active_shelf_content.modulate.a
	if current_alpha <= 0.001:
		_rebuild_pinned_active_shelf_content(skill_id, false)
		return
	pinned_active_shelf_transition_skill_id = skill_id
	pinned_active_shelf_transition_active = true
	var content_id: int = pinned_active_shelf_content.get_instance_id()
	pinned_active_shelf_tween = host.create_tween()
	var fade_out_seconds := 0.10
	pinned_active_shelf_tween.tween_property(pinned_active_shelf_content, "modulate:a", 0.0, fade_out_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	pinned_active_shelf_tween.tween_callback(Callable(self, "_finish_pinned_active_shelf_fade_out").bind(content_id, skill_id))

func _finish_pinned_active_shelf_fade_out(content_id: int, skill_id: String) -> void:
	var content: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(content_id))
	if content == null or content != pinned_active_shelf_content:
		return
	_rebuild_pinned_active_shelf_content(skill_id, false)

func _animate_pinned_active_shelf_height(skill_id: String, instant := false) -> void:
	if pinned_active_shelf_header == null or not is_instance_valid(pinned_active_shelf_header):
		return
	if pinned_active_shelf_height_tween != null and pinned_active_shelf_height_tween.is_valid():
		pinned_active_shelf_height_tween.kill()
	pinned_active_shelf_height_tween = null
	var target_height := _pinned_active_shelf_target_height(skill_id)
	if instant:
		_set_pinned_active_shelf_height(target_height)
		return
	var current_height: float = pinned_active_shelf_header.custom_minimum_size.y
	if absf(current_height - target_height) <= 0.5:
		_set_pinned_active_shelf_height(target_height)
		return
	pinned_active_shelf_height_tween = host.create_tween()
	pinned_active_shelf_height_tween.tween_method(Callable(self, "_set_pinned_active_shelf_height"), current_height, target_height, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func _set_pinned_active_shelf_height(height: float) -> void:
	if pinned_active_shelf_header == null or not is_instance_valid(pinned_active_shelf_header):
		return
	pinned_active_shelf_header.custom_minimum_size = Vector2(pinned_active_shelf_header.custom_minimum_size.x, maxf(1.0, height))
	if host._skill_detail_surface().detail_shelf_shadow_overlay != null and is_instance_valid(host._skill_detail_surface().detail_shelf_shadow_overlay):
		var shadow_top := _pinned_active_shelf_shadow_top_y()
		host._skill_detail_surface().detail_shelf_shadow_overlay.offset_top = shadow_top
		host._skill_detail_surface().detail_shelf_shadow_overlay.offset_bottom = shadow_top + 116.0

func _route_pinned_shelf_action_card_input(event: InputEvent) -> bool:
	if host.current_screen != "skill":
		return false
	if host._input_routing_shell()._is_primary_press_event(event) and host._input_routing_shell()._event_points_inside_bottom_interactive_ui(event):
		return false
	if host.selected_skill_id == "fishing" and not host._skill_detail_surface().action_card_press_key.begins_with("pinned_shelf:"):
		var fishing_event_position: Vector2 = host._input_routing_shell()._fishing_detail_event_position(event)
		if fishing_event_position != Vector2.INF and host._input_routing_shell()._position_inside_detail_actions_viewport(fishing_event_position):
			return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		var event_position: Vector2 = host._input_routing_shell()._global_event_position(mouse_event.position, mouse_event.global_position)
		if mouse_event.pressed:
			var action_hit: Dictionary = host._skill_detail_surface()._module_action_circle_at_position(event_position)
			if _non_shelf_pin_center_hit(action_hit, event_position):
				return false
			var card_hit := _pinned_shelf_action_card_at_position(event_position)
			if card_hit.is_empty():
				return false
			var card := card_hit.get("card", {}) as Dictionary
			host.action_card_press_consumed = false
			var routed := _begin_pinned_shelf_action_card_press(card, event_position, -1)
			return routed
		if host._skill_detail_surface().action_card_press_key.begins_with("pinned_shelf:"):
			return host._input_routing_shell()._route_action_card_release(event)
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			var action_hit: Dictionary = host._skill_detail_surface()._module_action_circle_at_position(touch_event.position)
			if _non_shelf_pin_center_hit(action_hit, touch_event.position):
				return false
			var card_hit := _pinned_shelf_action_card_at_position(touch_event.position)
			if card_hit.is_empty():
				return false
			var card := card_hit.get("card", {}) as Dictionary
			host.action_card_press_consumed = false
			var routed := _begin_pinned_shelf_action_card_press(card, touch_event.position, touch_event.index)
			return routed
		if host._skill_detail_surface().action_card_press_key.begins_with("pinned_shelf:"):
			return host._input_routing_shell()._route_action_card_release(event)
	return false


func _non_shelf_pin_center_hit(action_hit: Dictionary, _event_position: Vector2) -> bool:
	if action_hit.is_empty():
		return false
	if str(action_hit.get("kind", "")) != "pin":
		return false
	if str(action_hit.get("module_key", "")).begins_with("pinned_shelf:"):
		return false
	var hit_host: Control = host._app_lifecycle_runtime().valid_control_ref(action_hit.get("host", null))
	return hit_host != null


func _pinned_shelf_action_card_at_position(event_position: Vector2) -> Dictionary:
	if host.current_screen != "skill" or not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
		return {}
	var keys: Array = host.action_card_keys.duplicate()
	keys.reverse()
	for raw_action_key in host.action_cards.keys():
		var action_key := str(raw_action_key)
		if action_key.begins_with("pinned_shelf:") and not keys.has(action_key):
			keys.push_front(action_key)
	for raw_key in keys:
		var key := str(raw_key)
		if not key.begins_with("pinned_shelf:") or not host.action_cards.has(key):
			continue
		var card := host.action_cards[key] as Dictionary
		var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		if not pop.get_global_rect().has_point(event_position):
			continue
		var skill_id := str(card.get("skill_id", ""))
		var action_id := str(card.get("action_id", ""))
		if skill_id.is_empty() or action_id.is_empty():
			continue
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty() or host._passive_modules_runtime().is_passive_action(action):
			continue
		if bool(card.get("unlock_ceremony_active", false)) or bool(card.get("unlock_ceremony_pending", false)):
			continue
		if not host._skill_detail_surface()._module_action_zone_kind_at_position(pop, event_position).is_empty():
			return {}
		return {
			"card": card,
			"skill_id": skill_id,
			"action_id": action_id
		}
	return {}


func _begin_pinned_shelf_action_card_press(card: Dictionary, press_position: Vector2, pointer_id := -1) -> bool:
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("action_id", ""))
	var action: Dictionary = host._action_data(skill_id, action_id)
	if host._input_routing_shell()._activity_card_is_locked_or_covered(skill_id, action, card):
		host._action_stop_hold().cancel_action()
		return false
	var stat_kind: String = host._skill_detail_surface()._activity_stat_kind_at_position(card, press_position)
	if stat_kind.is_empty() and host._skill_swipe_activity_surface()._action_card_medal_hit_at_position(card, press_position):
		stat_kind = host.ACTION_CARD_MEDAL_PRESS_KIND
	if not stat_kind.is_empty() and stat_kind != host.ACTION_CARD_MEDAL_PRESS_KIND:
		host._skill_detail_surface()._begin_activity_stat_hold(card, skill_id, action_id, stat_kind, press_position, pointer_id)
		return true
	var scroll := host._app_lifecycle_runtime().valid_control_ref(host._skill_detail_surface().detail_actions_scroll) as MobileScrollContainer
	if scroll != null:
		scroll.prepare_child_tap()
	host._skill_detail_surface().action_card_press_key = str(card.get("card_key", host._action_key(skill_id, action_id)))
	host._skill_detail_surface().action_card_press_position = press_position
	host._skill_detail_surface().action_card_press_stat_kind = stat_kind
	host._skill_detail_surface().action_card_press_dragged = false
	if stat_kind.is_empty():
		host._skill_swipe_activity_surface()._queue_action_card_3d_press(host._skill_detail_surface().action_card_press_key)
	return true


func _process_pin_transition_blocker() -> void:
	if pin_transition_blocker == null or not is_instance_valid(pin_transition_blocker):
		return
	if not pin_transition_blocker.visible or pin_transition_blocker_release_started:
		return
	pin_transition_blocker.offset_bottom = _global_chat_nav_cover_bottom_offset()
	if not pin_transition_blocker_fade_in_done:
		return
	var elapsed_seconds := float(maxi(0, Time.get_ticks_msec() - pin_transition_blocker_started_msec)) / 1000.0
	if elapsed_seconds < host.PIN_TRANSITION_BLOCKER_MIN_SECONDS:
		return
	if not _pin_transition_blocker_target_ready():
		return
	pin_transition_blocker_release_started = true
	if pin_transition_blocker_tween != null and pin_transition_blocker_tween.is_valid():
		pin_transition_blocker_tween.kill()
	pin_transition_blocker_tween = host.create_tween()
	pin_transition_blocker_tween.tween_property(
		pin_transition_blocker,
		"modulate:a",
		0.0,
		host.PIN_TRANSITION_BLOCKER_FADE_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pin_transition_blocker_tween.tween_callback(_finish_pin_transition_blocker_fade)


func _pin_transition_blocker_target_ready() -> bool:
	if screen_render_in_progress:
		return false
	if not pending_screen_render_request.is_empty():
		return false
	if pin_transition_blocker_target_screen == "pinned":
		return host.current_screen == "pinned" and host._skill_swipe_activity_surface()._pinned_page_ready_to_reveal_under_cover()
	if pin_transition_blocker_target_screen == "skill":
		return (
			host.current_screen == "skill"
			and host._skill_detail_surface().detail_actions_scroll != null
			and is_instance_valid(host._skill_detail_surface().detail_actions_scroll)
			and host._skill_detail_surface().detail_actions_scroll.is_inside_tree()
			and host._skill_detail_surface().detail_lazy_stack != null
			and is_instance_valid(host._skill_detail_surface().detail_lazy_stack)
		)
	return host.current_screen == pin_transition_blocker_target_screen


func _finish_pin_transition_blocker_fade() -> void:
	pin_transition_blocker_tween = null
	if pin_transition_blocker != null and is_instance_valid(pin_transition_blocker):
		pin_transition_blocker.visible = false
		pin_transition_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin_transition_blocker_target_screen = ""
	pin_transition_blocker_release_started = false
	pin_transition_blocker_fade_in_done = false

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
	module_utility_row.offset_top = -BOTTOM_NAV_HEIGHT - ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT - MODULE_UTILITY_ROW_GAP - MODULE_UTILITY_ROW_HEIGHT
	module_utility_row.offset_bottom = -BOTTOM_NAV_HEIGHT - ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT - MODULE_UTILITY_ROW_GAP

func _set_skill_swipe_module_utility_alpha(alpha: float) -> void:
	if module_utility_row == null or not is_instance_valid(module_utility_row):
		return
	var next_modulate := module_utility_row.modulate
	next_modulate.a = clampf(alpha, 0.0, 1.0)
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(module_utility_row, next_modulate)


func _fade_skill_swipe_module_utility_row(visible: bool, seconds: float) -> void:
	if module_utility_row == null or not is_instance_valid(module_utility_row):
		return
	host._app_lifecycle_runtime()._kill_meta_tween(module_utility_row, "skill_swipe_module_utility_fade_tween")
	var target_alpha := 1.0 if visible else 0.0
	if seconds <= 0.001:
		_set_skill_swipe_module_utility_alpha(target_alpha)
		return
	var tween: Tween = host.create_tween()
	module_utility_row.set_meta("skill_swipe_module_utility_fade_tween", tween)
	tween.tween_method(_set_skill_swipe_module_utility_alpha, module_utility_row.modulate.a, target_alpha, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_skill_swipe_module_utility_row_fade)


func _finish_skill_swipe_module_utility_row_fade() -> void:
	if module_utility_row != null and is_instance_valid(module_utility_row) and module_utility_row.has_meta("skill_swipe_module_utility_fade_tween"):
		module_utility_row.remove_meta("skill_swipe_module_utility_fade_tween")


func _sync_skill_swipe_module_utility_row_for_drag(abs_x: float) -> void:
	host._app_lifecycle_runtime()._kill_meta_tween(module_utility_row, "skill_swipe_module_utility_fade_tween")
	_set_skill_swipe_module_utility_alpha(1.0)

func _build_module_utility_row() -> void:
	var built := _ModuleUtilityRowBuilder.build({
		"bottom_nav_height": BOTTOM_NAV_HEIGHT,
		"chat_strip_height": ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT,
		"gap": MODULE_UTILITY_ROW_GAP,
		"height": MODULE_UTILITY_ROW_HEIGHT,
		"z_index": ProfileChatOverlaySurface.CHAT_UI_Z + 1,
		"button_size": MODULE_UTILITY_BUTTON_SIZE,
		"radius": 36.0,
		"gutter": host.ACTION_CARD_POP_GUTTER,
		"depth_offset": NAV_BUTTON_DEPTH_OFFSET,
		"diagonal_side": "",
		"collapse_size": MODULE_UTILITY_COLLAPSE_TOGGLE_SIZE,
		"texture": Callable(host.visual_texture_cache, "_texture_or_visual_fallback"),
		"res_path": Callable(host.visual_texture_cache, "_res_path"),
		"install_shell": Callable(host._skill_swipe_activity_surface(), "_install_activity_button_shell"),
		"attach_press": Callable(host._skill_swipe_activity_surface(), "_attach_activity_button_press_animation"),
		"buttons": [
			{"id": "pinned", "label": "Pinned", "icon": ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE, "fill": Color.WHITE},
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
	_show_pinned_activities()

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
	if not _top_level_nav_allowed("queue"):
		return
	queue_return_screen = _module_utility_return_screen_for_current()
	queue_return_skill_id = host.selected_skill_id
	queue_return_detail_scroll = _module_utility_return_detail_scroll_for_current()
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	host._skill_swipe_activity_surface()._begin_direct_skill_nav_cover()
	host.current_screen = "queue"
	_render_screen()
	_sync_module_utility_row_visibility()

func _return_from_activity_queue() -> void:
	var target_screen := queue_return_screen
	if target_screen.is_empty() or _module_utility_screen_overlays_skill_detail(target_screen):
		target_screen = "skill"
	if not _top_level_nav_allowed(target_screen):
		return
	if not queue_return_skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, queue_return_skill_id):
		host.selected_skill_id = queue_return_skill_id
	var restore_scroll := queue_return_detail_scroll if target_screen == "skill" else -1
	queue_return_detail_scroll = -1
	host._skill_swipe_activity_surface()._begin_direct_skill_nav_cover()
	host.current_screen = target_screen
	_render_screen(false, restore_scroll)
	_sync_module_utility_row_visibility()

func _show_pinned_activities() -> void:
	if host.current_screen == "pinned":
		_return_from_pinned_activities()
		return
	if not _top_level_nav_allowed("pinned"):
		return
	pinned_return_screen = _module_utility_return_screen_for_current()
	pinned_return_skill_id = host.selected_skill_id
	pinned_return_detail_scroll = _module_utility_return_detail_scroll_for_current()
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
		host._skill_swipe_activity_surface()._begin_direct_skill_nav_cover()
	host.current_screen = "pinned"
	_render_screen()

func _return_from_pinned_activities() -> void:
	var target_screen: String = pinned_return_screen
	if target_screen.is_empty() or _module_utility_screen_overlays_skill_detail(target_screen):
		target_screen = "skill"
	if not _top_level_nav_allowed(target_screen):
		return
	if not pinned_return_skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, pinned_return_skill_id):
		host.selected_skill_id = pinned_return_skill_id
	var restore_scroll: int = pinned_return_detail_scroll if target_screen == "skill" else -1
	pinned_return_detail_scroll = -1
	host._skill_swipe_activity_surface()._begin_direct_skill_nav_cover()
	host.current_screen = target_screen
	_render_screen(false, restore_scroll)

func _on_skills_utility_pressed() -> void:
	if skills_utility_tab != null and is_instance_valid(skills_utility_tab):
		_prime_module_utility_nav_button_press_state(skills_utility_tab)
	if host.current_screen == "menu":
		_return_from_skills_utility()
		return
	skills_utility_return_screen = _module_utility_return_screen_for_current()
	skills_utility_return_skill_id = host.selected_skill_id
	_show_skills()

func _module_utility_screen_overlays_skill_detail(screen: String) -> bool:
	return screen == "pinned" or screen == "queue" or screen == "menu"

func _module_utility_return_screen_for_current() -> String:
	if _module_utility_screen_overlays_skill_detail(host.current_screen):
		return "skill"
	return host.current_screen

func _module_utility_return_detail_scroll_for_current() -> int:
	if host.current_screen == "skill":
		if host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
			return -1
		return maxi(0, int(round(host._skill_detail_surface().detail_actions_scroll.scroll_vertical)))
	if host.current_screen == "pinned" and pinned_return_screen == "skill":
		return pinned_return_detail_scroll
	if host.current_screen == "queue" and queue_return_screen == "skill":
		return queue_return_detail_scroll
	return -1

func _return_from_skills_utility() -> void:
	var target_screen: String = skills_utility_return_screen
	if target_screen.is_empty() or _module_utility_screen_overlays_skill_detail(target_screen):
		target_screen = "skill"
	if not _top_level_nav_allowed(target_screen):
		return
	if not skills_utility_return_skill_id.is_empty() and SkillState.has_skill_id(host.skill_defs, skills_utility_return_skill_id):
		host.selected_skill_id = skills_utility_return_skill_id
	host.current_screen = target_screen
	_render_screen()

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
	var event_position: Vector2 = host._input_routing_shell()._passive_button_event_position(event, null)
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
	var event_position: Vector2 = host._input_routing_shell()._passive_button_event_position(event, null)
	var event_kind := ButtonPressState.event_kind(event)
	if event_kind == "press":
		ButtonPressState.begin(button, "module_utility", event_position)
		host.button_press_runtime.play_default_button_sfx()
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
	if not _intro_bottom_controls_unlocked():
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
	visual.scale = Vector2(1.0, MODULE_SORT_MENU_COLLAPSED_SCALE_Y)
	visual.modulate.a = 0.0
	module_sort_menu_tween = host.create_tween()
	module_sort_menu_tween.set_parallel(true)
	module_sort_menu_tween.tween_property(visual, "scale:y", 1.0, MODULE_SORT_MENU_UNWRAP_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	module_sort_menu_tween.tween_property(visual, "modulate:a", 1.0, MODULE_SORT_MENU_UNWRAP_SECONDS * 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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
	module_sort_menu_tween.tween_property(visual, "scale:y", MODULE_SORT_MENU_COLLAPSED_SCALE_Y, MODULE_SORT_MENU_WRAP_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	module_sort_menu_tween.tween_property(visual, "modulate:a", 0.0, MODULE_SORT_MENU_WRAP_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
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
	var built := _ModuleSortMenuBuilder.build(ProfileChatOverlaySurface.CHAT_UI_Z + 2, Callable(self, "_toggle_module_ui_level_sort"), Callable(self, "_toggle_module_ui_sort_priority"), Callable(host.button_press_runtime, "attach_button_depress_animation"), host.app_font, host.app_bold_font, host.COLOR_INK)
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
	var top_y: float = host.size.y - BOTTOM_NAV_HEIGHT - ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT - MODULE_UTILITY_ROW_GAP - MODULE_UTILITY_ROW_HEIGHT - menu_size.y - 22.0
	if sort_utility_tab != null and is_instance_valid(sort_utility_tab):
		var sort_rect: Rect2 = host._skill_swipe_activity_surface()._activity_button_target_face_global_rect(sort_utility_tab, true)
		center_x = sort_rect.position.x + sort_rect.size.x * 0.5
		top_y = sort_rect.position.y - menu_size.y - 22.0
	module_sort_menu.position = Vector2(
		clampf(center_x - menu_size.x * 0.5, 18.0, maxf(18.0, host.size.x - menu_size.x - 18.0)),
		maxf(18.0, top_y)
	)

func _sync_module_sort_menu_buttons() -> void:
	_ModuleSortMenuBuilder.sync_buttons(module_sort_low_level_button, module_sort_combo_button, module_sort_collection_button, host.module_ui_runtime.sort_mode == ModuleUiRuntime.SORT_LEVEL_REVERSE, host.module_ui_runtime.combo_first, host.module_ui_runtime.collection_first, host.COLOR_INK)

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
		if not host._skill_detail_surface()._try_refresh_detail_module_order_in_place():
			host._skill_detail_surface().call_deferred("_refresh_visible_skill_detail_action_list", host._skill_detail_surface().detail_actions_scroll.scroll_vertical if host._skill_detail_surface().detail_actions_scroll != null else -1, host.selected_skill_id, true)
	elif host.current_screen == "menu":
		_render_screen()

func _sync_module_utility_row_visibility(animate_buttons := false) -> void:
	if module_utility_row == null or not is_instance_valid(module_utility_row):
		return
	_layout_module_utility_row()
	module_utility_row.visible = (
		_intro_bottom_controls_unlocked()
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
	var slide_offset := Vector2(-MODULE_UTILITY_BUTTONS_SLIDE_PIXELS, 0)
	if not animate_buttons:
		_finish_module_utility_buttons_row_motion(expanded)
		return
	module_utility_buttons_motion_active = true
	module_utility_buttons_motion_expanded = expanded
	module_utility_buttons_motion_started_msec = Time.get_ticks_msec()
	if expanded:
		module_utility_buttons_row.visible = true
		module_utility_buttons_motion_duration_msec = int(MODULE_UTILITY_BUTTONS_ENTER_SECONDS * 1000.0)
		module_utility_buttons_motion_frame = 0
		module_utility_buttons_motion_total_frames = maxi(1, int(ceil(MODULE_UTILITY_BUTTONS_ENTER_SECONDS * 60.0)))
		module_utility_buttons_motion_from_offset = slide_offset.x
		module_utility_buttons_motion_to_offset = 0.0
		module_utility_buttons_motion_from_alpha = 0.0
		module_utility_buttons_motion_to_alpha = 1.0
		_set_module_utility_buttons_row_offset_x(slide_offset.x)
		module_utility_buttons_row.modulate.a = 0.0
	else:
		module_utility_buttons_row.visible = true
		module_utility_buttons_motion_duration_msec = int(MODULE_UTILITY_BUTTONS_EXIT_SECONDS * 1000.0)
		module_utility_buttons_motion_frame = 0
		module_utility_buttons_motion_total_frames = maxi(1, int(ceil(MODULE_UTILITY_BUTTONS_EXIT_SECONDS * 60.0)))
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
	var max_delay: float = MODULE_UTILITY_BUTTONS_STAGGER_STEP * float(maxi(0, count - 1))
	var active_span := maxf(0.001, 1.0 - max_delay)
	for index in range(count):
		var button := controls[index] as Control
		if button == null or not is_instance_valid(button):
			continue
		button.pivot_offset = button.size * 0.5
		var delayed_progress := clampf((progress - MODULE_UTILITY_BUTTONS_STAGGER_STEP * float(index)) / active_span, 0.0, 1.0)
		var local_progress := _module_utility_buttons_motion_ease(delayed_progress, true)
		var visibility_progress := delayed_progress if entering else 1.0 - delayed_progress
		button.modulate.a = smoothstep(0.0, 1.0, visibility_progress)
		var scale_progress := local_progress if entering else 1.0 - local_progress
		var button_scale := lerpf(MODULE_UTILITY_BUTTONS_STAGGER_MIN_SCALE, 1.0, scale_progress)
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
	if arrow != null and arrow.has_method("set_direction"):
		arrow.set_direction(1 if module_utility_collapsed else -1)
	module_utility_collapse_toggle.size = MODULE_UTILITY_COLLAPSE_TOGGLE_SIZE
	var expanded_x := 46.0
	var collapsed_x := 46.0
	module_utility_collapse_toggle.position = Vector2(
		collapsed_x if module_utility_collapsed else expanded_x,
		(MODULE_UTILITY_ROW_HEIGHT - MODULE_UTILITY_COLLAPSE_TOGGLE_SIZE.y) * 0.5
	)

func _sync_module_utility_button_states() -> void:
	if pinned_utility_tab != null and is_instance_valid(pinned_utility_tab):
		var fill := pinned_utility_tab.get_meta("module_utility_fill", Color.WHITE) as Color
		var active: bool = host.current_screen == "pinned"
		host._skill_swipe_activity_surface()._set_activity_button_shell_theme(pinned_utility_tab, fill, active, true)
	if queue_utility_tab != null and is_instance_valid(queue_utility_tab):
		var fill := queue_utility_tab.get_meta("module_utility_fill", Color.WHITE) as Color
		var active: bool = host.current_screen == "queue"
		host._skill_swipe_activity_surface()._set_activity_button_shell_theme(queue_utility_tab, fill, active, true)
	if skills_utility_tab != null and is_instance_valid(skills_utility_tab):
		var fill := skills_utility_tab.get_meta("module_utility_fill", Color.WHITE) as Color
		var active: bool = host.current_screen == "menu"
		host._skill_swipe_activity_surface()._set_activity_button_shell_theme(skills_utility_tab, fill, active, true)
	if sort_utility_tab != null and is_instance_valid(sort_utility_tab):
		var fill := sort_utility_tab.get_meta("module_utility_fill", Color.WHITE) as Color
		var active: bool = module_sort_menu != null and is_instance_valid(module_sort_menu) and module_sort_menu.visible
		host._skill_swipe_activity_surface()._set_activity_button_shell_theme(sort_utility_tab, fill, active, true)


func _module_utility_row_reserved_height_for_screen() -> float:
	return float(MODULE_UTILITY_ROW_HEIGHT + MODULE_UTILITY_ROW_GAP) if host._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen() else 0.0


func _skills_content_bottom_inset_for_screen() -> float:
	if not host._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		return 0.0
	return float(ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT) + _module_utility_row_reserved_height_for_screen()


func _bottom_ui_reserved_height_for_current_screen() -> float:
	return float(BOTTOM_NAV_HEIGHT) + _skills_content_bottom_inset_for_screen()


func _skill_menu_band_style(color: Color, pressed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.08 if pressed else 0.0)
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(54)
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
	feather.offset_top = -12.0 if top_edge else -118.0
	feather.offset_bottom = 118.0 if top_edge else 12.0
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
