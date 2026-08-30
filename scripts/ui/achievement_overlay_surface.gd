extends RefCounted

const AchievementPresentation = preload("res://scripts/achievements/presentation.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const ActionRuntime = preload("res://scripts/gameplay/action_runtime.gd")
const LeaderboardPresentation = preload("res://scripts/leaderboard/presentation.gd")
const InputRoutingShell = preload("res://scripts/ui/input_routing_shell.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const SkillIconBadge = preload("res://scripts/ui/skill_icon_badge.gd")
const CleanProgressBar = preload("res://scripts/ui/clean_progress_bar.gd")
const ACHIEVEMENT_MEDAL_SLOT_SIZE := Vector2(31, 31)
const IDLE_ELITE_LOGO_TEXTURE := "res://assets/content/logo/idle-elite-logo-cutout.png"
const OFFLINE_SUMMARY_MODAL_WIDTH := 840.0
const OFFLINE_SUMMARY_MODAL_MIN_HEIGHT := 620.0
const OFFLINE_SUMMARY_MODAL_MAX_HEIGHT := 1090.0
const OFFLINE_SUMMARY_MODAL_CHROME_HEIGHT := 620.0
const OFFLINE_SUMMARY_MODAL_MAX_PROGRESS_HEIGHT := 410.0
const OFFLINE_SUMMARY_MODAL_VIEWPORT_MARGIN := Vector2(32, 40)
const OFFLINE_SUMMARY_SECTION_HEIGHT := 44.0
const OFFLINE_SUMMARY_ROW_HEIGHT := 107.0
const OFFLINE_SUMMARY_ROW_GAP := 14.0
const ACHIEVEMENTS_MODAL_SIZE := Vector2(880, 1500)
const ACHIEVEMENTS_MODAL_VIEWPORT_MARGIN := Vector2(32, 40)
const ACHIEVEMENTS_MODAL_SCROLL_HEIGHT := 1110.0
const GLOBAL_BUFFS_MODAL_MIN_HEIGHT := 720.0
const GLOBAL_BUFFS_MODAL_BASE_HEIGHT := 630.0
const GLOBAL_BUFFS_MODAL_ROW_HEIGHT := 60.0
const GLOBAL_BUFFS_MODAL_MAX_HEIGHT := 1370.0
const GLOBAL_BUFFS_MODAL_SCROLL_CHROME := 760.0

class AchievementMedalSlotStrip:
	extends Control

	var slot_count := 25
	var slot_size := Vector2(29, 29)
	var row_overlap := 0.48
	var max_single_row_count := 11
	var medal_icons := []
	var medal_shadows := []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		_layout_icons()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout_icons()
			queue_redraw()

	func add_slot_icon(icon: TextureRect, shadow: TextureRect = null) -> void:
		if shadow != null:
			medal_shadows.append(shadow)
			add_child(shadow)
		medal_icons.append(icon)
		add_child(icon)
		_layout_icons()

	func clear_slot_icons() -> void:
		medal_shadows.clear()
		medal_icons.clear()
		_layout_icons()

	func _layout_icons() -> void:
		if medal_icons.is_empty():
			return
		var row_count := _row_count()
		var row_gap_ratio := maxf(0.20, 1.0 - clampf(row_overlap, 0.0, 0.80))
		var height_ratio := 1.0 + row_gap_ratio * float(row_count - 1)
		var icon_size := minf(slot_size.x, maxf(1.0, _layout_height() / height_ratio))
		for i in range(medal_icons.size()):
			var center := _slot_center(i, icon_size)
			var row_z := _slot_row(i) * 1000
			var slot_z := row_z + i * 2
			var icon := medal_icons[i] as TextureRect
			if icon == null:
				continue
			var base_visual_size := maxf(icon_size, icon.custom_minimum_size.x)
			var visual_size := base_visual_size * AchievementPresentation.mastery_medal_display_scale(int(icon.get_meta("achievement_medal_level", 0)))
			if i < medal_shadows.size():
				var shadow := medal_shadows[i] as TextureRect
				if shadow != null:
					var outline := bool(shadow.get_meta("achievement_medal_outline", false))
					var shadow_size := visual_size
					shadow.size = Vector2(shadow_size, shadow_size)
					shadow.position = center - shadow.size * 0.5
					shadow.z_index = slot_z
					if not outline:
						shadow.position += Vector2(3.5, 4.5)
			icon.size = Vector2(visual_size, visual_size)
			icon.position = center - icon.size * 0.5
			icon.z_index = slot_z + 1

	func _slot_center(index: int, icon_size: float) -> Vector2:
		var count := maxi(1, slot_count)
		if _row_count() <= 1:
			return _row_slot_center(index, count, icon_size, 0, count)
		if count > 1:
			var top_row_count := _top_row_count(count)
			if index >= top_row_count:
				return _row_slot_center(index - top_row_count, count - top_row_count, icon_size, 1, top_row_count)
			return _row_slot_center(index, top_row_count, icon_size, 0, top_row_count)
		return Vector2(_layout_width() * 0.5, _layout_height() * 0.5)

	func _row_slot_center(row_index: int, row_slot_count: int, icon_size: float, row: int, top_row_count: int) -> Vector2:
		var count := maxi(1, row_slot_count)
		var left := icon_size * 0.5
		var right := maxf(left, _layout_width() - icon_size * 0.5)
		var x := (left + right) * 0.5
		if count > 1:
			var available_width := maxf(0.0, right - left)
			var snug_step := icon_size * 0.72
			var total_snug_width := snug_step * float(count - 1)
			var row_left := (left + right) * 0.5 - total_snug_width * 0.5
			var row_right := row_left + total_snug_width
			if total_snug_width > available_width:
				row_left = left
				row_right = right
			if row == 1 and count < top_row_count and top_row_count > 1:
				var top_step := (row_right - row_left) / float(maxi(1, top_row_count - 1))
				row_left += top_step * 0.5
				row_right -= top_step * 0.5
			x = lerpf(row_left, row_right, float(row_index) / float(count - 1))
		var row_gap := icon_size * maxf(0.20, 1.0 - clampf(row_overlap, 0.0, 0.80))
		var total_height := icon_size + row_gap * float(_row_count() - 1)
		var top_y := (_layout_height() - total_height) * 0.5 + icon_size * 0.5
		return Vector2(x, top_y + row_gap * float(row))

	func _row_count() -> int:
		var count := maxi(slot_count, medal_icons.size())
		if count <= max_single_row_count:
			return 1
		return 2

	func _top_row_count(count: int) -> int:
		return int(ceil(float(count) / 2.0))

	func _slot_row(index: int) -> int:
		if _row_count() <= 1:
			return 0
		return 1 if index >= _top_row_count(maxi(1, slot_count)) else 0

	func _layout_width() -> float:
		return maxf(maxf(size.x, custom_minimum_size.x), slot_size.x)

	func _layout_height() -> float:
		return maxf(maxf(size.y, custom_minimum_size.y), slot_size.y)

var host
var home_page_built := false
var home_scroll: MobileScrollContainer
var home_achievement_refresh_token := 0
var home_achievements_build_token := 0
var offline_summary_overlay: Control
var offline_summary_panel_frame: Control
var offline_summary_panel: PanelContainer
var offline_summary_stack: VBoxContainer
var offline_summary_scroll: MobileScrollContainer
var offline_summary_close_pending := false
var achievements_overlay: Control
var achievements_panel_frame: Control
var achievements_panel: PanelContainer
var achievements_scroll: ScrollContainer
var achievements_list_stack: VBoxContainer
var achievements_tab_buttons := {}
var achievements_hide_completed: CheckBox
var achievements_modal_tab := "achievements"
var achievements_rebuild_signature := ""
var achievements_rebuild_token := 0
var achievement_total_label: Label
var achievement_elite_label: Label
var achievement_total_bar: CleanProgressBar
var achievement_buff_label: Label
var achievement_total_level_label: Label
var achievement_best_card: MarginContainer
var achievement_best_art_frame: PanelContainer
var achievement_best_art: TextureRect
var achievement_best_name_label: Label
var achievement_best_medal: TextureRect
var achievement_skill_count_labels := {}
var achievement_skill_bars := {}
var achievement_skill_level_labels := {}
var achievement_skill_tier_name_labels := {}
var achievement_skill_tier_count_labels := {}
var achievement_skill_tier_bars := {}
var achievement_medal_slot_strips := {}
var achievement_medal_slot_panels := {}
var achievement_medal_slot_icons := {}

func _init(host_ref) -> void:
	host = host_ref


func reset_home_scroll_ref() -> void:
	home_scroll = null


func invalidate_home_page() -> void:
	home_page_built = false


func offline_summary_visible() -> bool:
	return offline_summary_overlay != null and offline_summary_overlay.visible


func hide_offline_summary_immediate() -> void:
	if offline_summary_overlay != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(offline_summary_overlay, false)
	offline_summary_close_pending = false


func is_overlay_visible() -> bool:
	return achievements_overlay != null and achievements_overlay.visible


func hide_overlay_without_sfx() -> void:
	if achievements_overlay != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(achievements_overlay, false)


func global_buff_anchor() -> Label:
	return achievement_buff_label


func ensure_home_page(home_page: Control) -> void:
	if home_page_built or home_page == null:
		return
	home_page_built = true
	build_home_page(home_page)
	call_deferred("_prewarm_achievements_overlay")


func build_home_page(home_page: Control) -> void:
	home_page_built = true
	invalidate_home_achievement_build()
	achievement_skill_count_labels.clear()
	achievement_skill_bars.clear()
	achievement_skill_level_labels.clear()
	achievement_skill_tier_name_labels.clear()
	achievement_skill_tier_count_labels.clear()
	achievement_skill_tier_bars.clear()
	achievement_medal_slot_strips.clear()
	achievement_medal_slot_panels.clear()
	achievement_medal_slot_icons.clear()
	achievement_total_label = null
	achievement_elite_label = null
	achievement_total_bar = null
	achievement_buff_label = null
	achievement_total_level_label = null
	achievement_best_card = null
	achievement_best_art_frame = null
	achievement_best_art = null
	achievement_best_name_label = null
	achievement_best_medal = null
	host.hero_message = null
	var scroll := MobileScrollContainer.new()
	home_scroll = scroll
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	home_page.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", host.PAGE_PAD)
	margin.add_theme_constant_override("margin_right", host.PAGE_PAD)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", NavigationShell.BOTTOM_NAV_SAFE_PAD + 190)
	scroll.add_child(margin)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 26)
	margin.add_child(stack)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 37)
	stack.add_child(top_spacer)
	var logo: TextureRect = host.visual_texture_cache._image(IDLE_ELITE_LOGO_TEXTURE, Vector2(842, 207))
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(logo)
	var achievement_page := PanelContainer.new()
	achievement_page.custom_minimum_size = Vector2(host._skill_content_width(), 0)
	achievement_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievement_page.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stack.add_child(achievement_page)
	_build_achievements(achievement_page)


func scroll_home_to_top() -> void:
	if home_scroll == null or not is_instance_valid(home_scroll):
		return
	home_scroll.drag_scroll_position = 0.0
	home_scroll.scroll_vertical = 0


func invalidate_home_achievement_build() -> void:
	home_achievements_build_token += 1


func _ensure_offline_summary_overlay() -> void:
	if host._app_lifecycle_runtime().lazy_overlay_built("offline_summary"):
		return
	host._app_lifecycle_runtime().mark_lazy_overlay_built("offline_summary")
	_build_offline_summary_overlay()

func _build_offline_summary_overlay() -> void:
	offline_summary_overlay = ColorRect.new()
	(offline_summary_overlay as ColorRect).color = Color(0, 0, 0, 0.46)
	offline_summary_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	offline_summary_overlay.z_index = host.MODAL_OVERLAY_Z
	offline_summary_overlay.z_as_relative = false
	offline_summary_overlay.visible = false
	offline_summary_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	offline_summary_overlay.add_to_group("modal_overlay")
	offline_summary_overlay.gui_input.connect(_on_offline_summary_overlay_gui_input)
	host.add_child(offline_summary_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	offline_summary_overlay.add_child(center)
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(OFFLINE_SUMMARY_MODAL_WIDTH, OFFLINE_SUMMARY_MODAL_MIN_HEIGHT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(frame)
	offline_summary_panel_frame = frame
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(OFFLINE_SUMMARY_MODAL_WIDTH, OFFLINE_SUMMARY_MODAL_MIN_HEIGHT)
	panel.add_theme_stylebox_override("panel", host._surface_style(host.COLOR_PANEL, host.CARD_RADIUS, 72, true))
	frame.add_child(panel)
	offline_summary_panel = panel
	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 29)
	outer.add_theme_constant_override("margin_right", 29)
	outer.add_theme_constant_override("margin_top", 26)
	outer.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(outer)
	offline_summary_stack = VBoxContainer.new()
	offline_summary_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	offline_summary_stack.add_theme_constant_override("separation", 12)
	var scroll := MobileScrollContainer.new()
	offline_summary_scroll = scroll
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(scroll)
	scroll.add_child(offline_summary_stack)

func _on_offline_summary_overlay_gui_input(event: InputEvent) -> void:
	var panel = offline_summary_panel if offline_summary_panel != null and is_instance_valid(offline_summary_panel) else offline_summary_panel_frame
	if InputRoutingShell.event_is_outside_panel_press(event, panel):
		_close_offline_summary_overlay()

func _close_offline_summary_overlay() -> void:
	host._input_routing_shell()._block_background_input_briefly()
	host.get_viewport().set_input_as_handled()
	if offline_summary_overlay != null and not offline_summary_overlay.visible:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(offline_summary_overlay, false)
		offline_summary_close_pending = false
		return
	if offline_summary_close_pending:
		return
	offline_summary_close_pending = true
	call_deferred("_finish_close_offline_summary_overlay")

func _finish_close_offline_summary_overlay() -> void:
	offline_summary_close_pending = false
	if offline_summary_overlay != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(offline_summary_overlay, false)
	host.button_press_runtime.play_default_button_sfx()
	host._achievement_toast_surface().play_pending_offline_summary_toasts()

func _fit_offline_summary_modal(modal_size: Vector2) -> void:
	if offline_summary_panel == null:
		return
	var fitted_scale = host._fit_scale_to_canvas(modal_size, OFFLINE_SUMMARY_MODAL_VIEWPORT_MARGIN)
	var fitted_frame_size = modal_size * fitted_scale
	if offline_summary_panel_frame != null:
		offline_summary_panel_frame.custom_minimum_size = fitted_frame_size
		offline_summary_panel_frame.size = fitted_frame_size
		offline_summary_panel_frame.reset_size()
		offline_summary_panel_frame.update_minimum_size()
	offline_summary_panel.custom_minimum_size = modal_size
	offline_summary_panel.size = modal_size
	offline_summary_panel.position = Vector2.ZERO
	offline_summary_panel.scale = Vector2(fitted_scale, fitted_scale)
	offline_summary_panel.reset_size()
	offline_summary_panel.update_minimum_size()

func _maybe_show_offline_summary(offline_seconds: float, active_result: Dictionary) -> void:
	_ensure_offline_summary_overlay()
	if offline_summary_overlay == null or not bool(active_result.get("handled", false)):
		return
	var achievements := _offline_summary_achievements(active_result)
	var has_progress := int(active_result.get("completions", 0)) > 0
	has_progress = has_progress or int(active_result.get("xp", 0)) > 0
	has_progress = has_progress or int(active_result.get("new_skill_level", 1)) > int(active_result.get("old_skill_level", 1))
	has_progress = has_progress or int(active_result.get("new_mastery_level", 0)) > int(active_result.get("old_mastery_level", 0))
	has_progress = has_progress or not (active_result.get("unlocked_actions", []) as Array).is_empty()
	if not has_progress:
		host._achievement_toast_surface().show_offline_summary_toasts(achievements)
		return
	host._achievement_toast_surface().pending_offline_summary_achievements = achievements
	_rebuild_offline_summary_overlay(offline_seconds, active_result)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(offline_summary_overlay, true)

func _rebuild_offline_summary_overlay(offline_seconds: float, active_result: Dictionary) -> void:
	if offline_summary_stack == null:
		return
	host._clear(offline_summary_stack)
	var progress_content_height := _offline_summary_progress_content_height(active_result)
	var progress_area_height := minf(progress_content_height, OFFLINE_SUMMARY_MODAL_MAX_PROGRESS_HEIGHT)
	var modal_height := clampf(
		OFFLINE_SUMMARY_MODAL_CHROME_HEIGHT + progress_area_height,
		OFFLINE_SUMMARY_MODAL_MIN_HEIGHT,
		OFFLINE_SUMMARY_MODAL_MAX_HEIGHT
	)
	_fit_offline_summary_modal(Vector2(OFFLINE_SUMMARY_MODAL_WIDTH, modal_height))
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	offline_summary_stack.add_child(header)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 1)
	header.add_child(title_stack)
	var title = host._label("Welcome Back", 62, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_stack.add_child(title)
	var subtitle = host._label("Away for %s" % GameFormatting.duration(offline_seconds), 32, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	title_stack.add_child(subtitle)
	var close = host._menu_button("X")
	close.custom_minimum_size = Vector2(85, 79)
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(_close_offline_summary_overlay)
	header.add_child(close)

	offline_summary_stack.add_child(_offline_summary_activity_card(active_result))

	var stat_row := HBoxContainer.new()
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.add_theme_constant_override("separation", 14)
	offline_summary_stack.add_child(stat_row)
	stat_row.add_child(_offline_summary_stat_card("XP Earned", "+%s" % int(active_result.get("xp", 0)), Color("#35d86d"), host.PROGRESS_STAR_ICON_TEXTURE))
	stat_row.add_child(_offline_summary_stat_card("Offline Rate", "%s%% speed" % int(round(ActionRuntime.OFFLINE_XP_MULT * 100.0)), Color("#f4bf35"), host.TOTAL_LEVEL_BARGRAPH_TEXTURE))

	if progress_content_height > 0.0:
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", int(OFFLINE_SUMMARY_ROW_GAP))
		offline_summary_stack.add_child(list)
		_populate_offline_summary_progress(list, active_result)

	var done = host._menu_button("Nice")
	done.custom_minimum_size = Vector2(0, 95)
	done.focus_mode = Control.FOCUS_NONE
	done.pressed.connect(_close_offline_summary_overlay)
	offline_summary_stack.add_child(done)
	_scroll_offline_summary_to_top_after_layout()


func _scroll_offline_summary_to_top_after_layout() -> void:
	if offline_summary_scroll == null or not is_instance_valid(offline_summary_scroll):
		return
	offline_summary_scroll.drag_scroll_position = 0.0
	offline_summary_scroll.scroll_vertical = 0
	call_deferred("_finish_scroll_offline_summary_to_top")


func _finish_scroll_offline_summary_to_top() -> void:
	await host.get_tree().process_frame
	if offline_summary_scroll == null or not is_instance_valid(offline_summary_scroll):
		return
	offline_summary_scroll.drag_scroll_position = 0.0
	offline_summary_scroll.scroll_vertical = 0

func _offline_summary_activity_card(active_result: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 152)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _offline_summary_info_style())
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 19)
	card.add_child(row)
	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(139, 139)
	art_frame.add_theme_stylebox_override("panel", host.ActivityCardStyles.featured_art(Callable(host, "_surface_style"), host.COLOR_LINE))
	row.add_child(art_frame)
	art_frame.add_child(host.visual_texture_cache._image(str(active_result.get("action_art", "")), Vector2(120, 120)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 5)
	row.add_child(copy)
	var eyebrow = host._label(str(active_result.get("skill_name", "Skill")), 29, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(eyebrow)
	var action_name_label = host._label(str(active_result.get("action_name", "Activity")), 44, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	action_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(action_name_label)
	var detail = host._label("%s successes from %s completed runs" % [int(active_result.get("successes", 0)), int(active_result.get("completions", 0))], 28, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(detail)
	return card

func _offline_summary_info_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = host._surface_style(Color("#fffdf8"), 14, 9, false)
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0
	style.shadow_color = Color(0, 0, 0, 0)
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style

func _offline_summary_stat_card(title: String, value: String, accent: Color, icon_path: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 163)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _offline_summary_stat_style(accent))
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 4)
	card.add_child(stack)
	stack.add_child(host.visual_texture_cache._image(icon_path, Vector2(50, 50)))
	var value_label = host._label(value, 41, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(value_label)
	var title_label = host._label(title, 29, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(title_label)
	return card

func _offline_summary_stat_style(accent: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = host._surface_style(Color("#fffdf8"), 16, 11, false)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.34)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.shadow_color = Color(0, 0, 0, 0)
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	return style

func _offline_summary_medal_stack(old_level: int, new_level: int) -> Control:
	var levels := []
	for level in range(old_level + 1, new_level + 1):
		levels.append(level)
	var medal_size := Vector2(59, 59)
	var overlap_step := 29.0
	var stack_width := medal_size.x + maxf(0.0, float(levels.size() - 1) * overlap_step)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(stack_width, medal_size.y + 9)
	holder.size = holder.custom_minimum_size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(levels.size()):
		var level := int(levels[i])
		var medal = host.visual_texture_cache._image_from_texture(AchievementPresentation.mastery_medal_texture(level, host.MASTERY_MAX_LEVEL, Callable(host.visual_texture_cache, "_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture")), medal_size)
		medal.position = Vector2(float(i) * overlap_step, float(levels.size() - 1 - i) * 3.5)
		medal.z_index = i + 1
		medal.tooltip_text = ""
		holder.add_child(medal)
	return holder

func _offline_summary_progress_content_height(active_result: Dictionary) -> float:
	var rows := 0
	var sections := 0
	var old_skill_level := int(active_result.get("old_skill_level", 1))
	var new_skill_level := int(active_result.get("new_skill_level", old_skill_level))
	var old_global_level := int(active_result.get("old_global_level", 1))
	var new_global_level := int(active_result.get("new_global_level", old_global_level))
	var old_mastery_level := int(active_result.get("old_mastery_level", 0))
	var new_mastery_level := int(active_result.get("new_mastery_level", old_mastery_level))
	var show_skill_level_row := new_skill_level > old_skill_level
	var show_global_level_row := new_global_level > old_global_level
	var show_mastery_row := new_mastery_level > old_mastery_level
	if show_skill_level_row or show_global_level_row or show_mastery_row:
		sections += 1
		if show_skill_level_row:
			rows += 1
		if show_global_level_row:
			rows += 1
		if show_mastery_row:
			rows += 1
	var unlocked_actions := active_result.get("unlocked_actions", []) as Array
	if not unlocked_actions.is_empty():
		sections += 1
		rows += unlocked_actions.size()
	var item_count := sections + rows
	if item_count <= 0:
		return 0.0
	return (
		float(sections) * OFFLINE_SUMMARY_SECTION_HEIGHT
		+ float(rows) * OFFLINE_SUMMARY_ROW_HEIGHT
		+ float(item_count - 1) * OFFLINE_SUMMARY_ROW_GAP
	)

func _populate_offline_summary_progress(list: VBoxContainer, active_result: Dictionary) -> void:
	var old_skill_level := int(active_result.get("old_skill_level", 1))
	var new_skill_level := int(active_result.get("new_skill_level", old_skill_level))
	var old_global_level := int(active_result.get("old_global_level", 1))
	var new_global_level := int(active_result.get("new_global_level", old_global_level))
	var old_mastery_level := int(active_result.get("old_mastery_level", 0))
	var new_mastery_level := int(active_result.get("new_mastery_level", old_mastery_level))
	var show_skill_level_row := new_skill_level > old_skill_level
	var show_global_level_row := new_global_level > old_global_level
	var show_mastery_row := new_mastery_level > old_mastery_level
	if show_skill_level_row or show_global_level_row or show_mastery_row:
		list.add_child(_offline_summary_section_label("Levels"))
	if show_skill_level_row:
		list.add_child(_offline_summary_row(SkillIconBadge.icon_path(str(active_result.get("skill_id", ""))), "%s Level" % str(active_result.get("skill_name", "Skill")), "Lv %s -> %s" % [old_skill_level, new_skill_level], "Achieved %s" % _offline_level_range_text(old_skill_level, new_skill_level), ThemeStyles.skill_theme_color(str(active_result.get("skill_id", "")), host.COLOR_BLUE)))
	if show_global_level_row:
		list.add_child(_offline_summary_row(host.TOTAL_LEVEL_BARGRAPH_TEXTURE, "Total Level", "Lv %s -> %s" % [old_global_level, new_global_level], "Total level increased while away.", Color("#f4bf35")))
	if show_mastery_row:
		list.add_child(_offline_summary_mastery_row(str(active_result.get("action_art", "")), old_mastery_level, new_mastery_level))

	var unlocked_actions := active_result.get("unlocked_actions", []) as Array
	if not unlocked_actions.is_empty():
		list.add_child(_offline_summary_section_label("Unlocked"))
		for unlocked in unlocked_actions:
			list.add_child(_offline_summary_unlock_card(unlocked as Dictionary, str(active_result.get("skill_id", ""))))

func _offline_summary_achievements(active_result: Dictionary) -> Array:
	var achievements := active_result.get("achievements", []) as Array
	var compact := []
	var index_by_chain := {}
	for raw_achievement in achievements:
		var achievement := raw_achievement as Dictionary
		var id := str(achievement.get("id", ""))
		var chain_key := str(achievement.get("chain_key", id))
		if chain_key.is_empty():
			chain_key = id
		if chain_key.is_empty():
			continue
		if index_by_chain.has(chain_key):
			compact[int(index_by_chain[chain_key])] = achievement
		else:
			index_by_chain[chain_key] = compact.size()
			compact.append(achievement)
	return compact

func _offline_level_range_text(old_level: int, new_level: int) -> String:
	if new_level <= old_level:
		return "none"
	if new_level == old_level + 1:
		return "Lv %s" % new_level
	return "Lv %s-%s" % [old_level + 1, new_level]

func _mastery_medals_earned_subtitle(old_level: int, new_level: int) -> String:
	if new_level <= old_level:
		return ""
	if new_level == old_level + 1:
		return "New %s medal earned." % MasteryState.medal_name(new_level)
	return "New mastery medals earned."

func _offline_summary_section_label(text: String) -> Label:
	var label = host._label(text, 34, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.45))
	label.add_theme_constant_override("outline_size", 5)
	return label

func _offline_summary_row(icon_path: String, title: String, value: String, subtitle: String, accent: Color) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 107)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _offline_summary_info_style())
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 15)
	card.add_child(row)
	row.add_child(host.visual_texture_cache._image(icon_path, Vector2(68, 68)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	var title_label = host._label(title, 31, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(title_label)
	var subtitle_label = host._label(subtitle, 27, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle_label)
	var value_label = host._label(value, 34, accent, HORIZONTAL_ALIGNMENT_RIGHT)
	value_label.custom_minimum_size = Vector2(215, 0)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(value_label)
	return card

func _offline_summary_mastery_row(icon_path: String, old_level: int, new_level: int) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 107)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _offline_summary_info_style())
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 15)
	card.add_child(row)
	row.add_child(host.visual_texture_cache._image(icon_path, Vector2(68, 68)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	var title_label = host._label("Activity Mastery", 31, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(title_label)
	var subtitle_label = host._label(_mastery_medals_earned_subtitle(old_level, new_level), 27, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle_label)
	row.add_child(_offline_summary_medal_stack(old_level, new_level))
	return card

func _offline_summary_unlock_card(unlocked: Dictionary, skill_id: String) -> Control:
	var accent = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
	return _offline_summary_row(str(unlocked.get("art", "")), str(unlocked.get("name", "Activity")), "Lv %s" % int(unlocked.get("level", 1)), "New activity unlocked.", accent)

func _legacy_home_link_button(text: String, icon_texture: Texture2D, minimum_size := Vector2(840, 105), icon_size := Vector2(50, 50), font_size := 52) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = minimum_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", host._paper_button_style(host.COLOR_BLUE, 42, 28))
	button.add_theme_stylebox_override("hover", host._paper_button_style(host.COLOR_BLUE, 42, 28))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(host.COLOR_BLUE.darkened(0.10), 42, 28, true))
	host.button_press_runtime.attach_button_depress_animation(button, 0.982)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 19)
	margin.add_theme_constant_override("margin_right", 19)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(host.visual_texture_cache._image_from_texture(icon_texture, icon_size))
	var label: Label = host._label(text, font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 10)
	row.add_child(label)
	return button

func _build_achievements(parent: PanelContainer) -> void:
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_top", 17)
	margin.add_theme_constant_override("margin_bottom", 60)
	parent.add_child(margin)

	var stack = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 15)
	margin.add_child(stack)

	var link_row = HBoxContainer.new()
	link_row.custom_minimum_size = Vector2(840, 0)
	link_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	link_row.alignment = BoxContainer.ALIGNMENT_CENTER
	link_row.add_theme_constant_override("separation", 17)
	stack.add_child(link_row)

	var link_button_size = Vector2(411.5, 130)
	var achievements_button = _legacy_home_link_button("Achievements", host.visual_texture_cache._texture(host.PROGRESS_STAR_ICON_TEXTURE), link_button_size, Vector2(56, 56), 48)
	achievements_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievements_button.pressed.connect(_open_achievements_overlay)
	link_row.add_child(achievements_button)
	var leaderboard_button = _legacy_home_link_button("Leaderboard", host.visual_texture_cache._texture(LeaderboardPresentation.ICON), link_button_size, Vector2(56, 56), 48)
	leaderboard_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leaderboard_button.pressed.connect(host.leaderboard_presentation._show_leaderboard)
	link_row.add_child(leaderboard_button)

	achievement_best_card = MarginContainer.new()
	achievement_best_card.visible = false
	achievement_best_card.custom_minimum_size = Vector2(840, 146)
	achievement_best_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(achievement_best_card)
	var best_margin = MarginContainer.new()
	best_margin.add_theme_constant_override("margin_left", 17)
	best_margin.add_theme_constant_override("margin_right", 17)
	best_margin.add_theme_constant_override("margin_top", 11)
	best_margin.add_theme_constant_override("margin_bottom", 11)
	achievement_best_card.add_child(best_margin)
	var best_copy = VBoxContainer.new()
	best_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	best_copy.add_theme_constant_override("separation", 5)
	best_margin.add_child(best_copy)
	best_copy.add_child(host._label("Most impressive activity:", 52, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var best_row = HBoxContainer.new()
	best_row.alignment = BoxContainer.ALIGNMENT_CENTER
	best_row.add_theme_constant_override("separation", 9)
	best_copy.add_child(best_row)
	achievement_best_art_frame = PanelContainer.new()
	achievement_best_art_frame.custom_minimum_size = Vector2(95, 95)
	achievement_best_art_frame.add_theme_stylebox_override("panel", host.ActivityCardStyles.featured_art(Callable(host, "_surface_style"), host.COLOR_LINE))
	best_row.add_child(achievement_best_art_frame)
	achievement_best_art = host.visual_texture_cache._image("", Vector2(80, 80))
	achievement_best_art_frame.add_child(achievement_best_art)
	achievement_best_name_label = host._label("Earn a medal to feature an activity", 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	achievement_best_name_label.custom_minimum_size = Vector2(360, 0)
	achievement_best_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	best_row.add_child(achievement_best_name_label)
	achievement_best_medal = host.visual_texture_cache._image_from_texture(null, Vector2(76, 76))
	best_row.add_child(achievement_best_medal)

	var total_margin = MarginContainer.new()
	total_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_margin.add_theme_constant_override("margin_top", 21)
	stack.add_child(total_margin)
	var total_section = HBoxContainer.new()
	total_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_section.alignment = BoxContainer.ALIGNMENT_CENTER
	total_section.add_theme_constant_override("separation", 20)
	total_margin.add_child(total_section)
	total_section.add_child(host.visual_texture_cache._image(host.TOTAL_LEVEL_BARGRAPH_TEXTURE, Vector2(105, 105)))
	achievement_total_level_label = host._label("", 62, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	total_section.add_child(achievement_total_level_label)

	var total_separator_margin = MarginContainer.new()
	total_separator_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_separator_margin.add_theme_constant_override("margin_left", 105)
	total_separator_margin.add_theme_constant_override("margin_right", 105)
	total_separator_margin.add_theme_constant_override("margin_top", 6)
	total_separator_margin.add_theme_constant_override("margin_bottom", 14)
	stack.add_child(total_separator_margin)
	var total_separator = ColorRect.new()
	total_separator.color = Color.BLACK
	total_separator.custom_minimum_size = Vector2(0, 9)
	total_separator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_separator_margin.add_child(total_separator)

	home_achievements_build_token += 1
	call_deferred("_build_home_achievement_skill_sections", stack, home_achievements_build_token)

func _build_home_achievement_skill_sections(stack: VBoxContainer, token: int) -> void:
	await host.get_tree().process_frame
	if token != home_achievements_build_token or stack == null or not is_instance_valid(stack):
		return
	for def in host.skill_defs:
		if token != home_achievements_build_token or stack == null or not is_instance_valid(stack):
			return
		var skill_id = str(def["id"])
		stack.add_child(_achievement_skill_section(skill_id))
		await host.get_tree().process_frame

	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 35)
	stack.add_child(bottom_spacer)
	_queue_home_achievement_refresh()

func _achievement_skill_section(skill_id: String) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 280)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", AchievementPresentation.skill_section())

	var skill_stack = VBoxContainer.new()
	skill_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_stack.add_theme_constant_override("separation", 11)
	card.add_child(skill_stack)

	var header = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 17)
	skill_stack.add_child(header)
	var icon = SkillIconBadge.achievement_icon_badge(host, skill_id, host.ACHIEVEMENT_SECTION_SKILL_ICON_SIZE)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(icon)

	var level_label = host._label("", 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	level_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header.add_child(level_label)
	achievement_skill_level_labels[skill_id] = level_label

	var actions: Array = AchievementState.mastery_actions_for_skill(host, skill_id)
	var slot_strip = _achievement_medal_slot_strip(skill_id, actions)
	skill_stack.add_child(slot_strip["root"])
	achievement_skill_tier_name_labels[skill_id] = []
	achievement_skill_tier_count_labels[skill_id] = []
	achievement_medal_slot_strips[skill_id] = slot_strip["root"]
	achievement_medal_slot_panels[skill_id] = [slot_strip["panels"]]
	achievement_medal_slot_icons[skill_id] = [slot_strip["icons"]]
	return card

func _update_achievements_ui(delta: float, instant: bool) -> void:
	if achievement_elite_label == null and achievement_total_bar == null and achievement_total_level_label == null:
		return
	var totals: Dictionary = AchievementState.elite_completion_counts(host)
	var total_earned := int(totals["earned"])
	var total_possible := int(totals["possible"])
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		if achievement_skill_level_labels.has(skill_id):
			var level_label := achievement_skill_level_labels[skill_id] as Label
			level_label.text = "%s Lv %s" % [SkillState.skill_name(host.skill_defs, skill_id), SkillState.host_skill_level(host, skill_id)]
		_update_achievement_medal_slots(skill_id, AchievementState.mastery_actions_for_skill(host, skill_id))
	if achievement_elite_label != null:
		var elite_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		achievement_elite_label.text = "%s%% Elite" % int(round(elite_pct))
	if achievement_total_level_label != null:
		achievement_total_level_label.text = "Total Lv %s" % SkillState.global_level(host.skills)
	if achievement_buff_label != null:
		achievement_buff_label.text = AchievementState.global_medal_buff_lines(host)
	if achievement_total_bar != null:
		var total_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		ThemeStyles.set_progress_bar_value(achievement_total_bar, total_pct, delta, instant)
	_update_most_impressive_activity()

func _update_most_impressive_activity() -> void:
	if achievement_best_name_label == null:
		return
	var best: Dictionary = AchievementState.most_impressive_activity(host)
	if best.is_empty():
		if achievement_best_card != null:
			achievement_best_card.visible = false
		if achievement_best_art_frame != null:
			achievement_best_art_frame.visible = false
		if achievement_best_art != null:
			achievement_best_art.visible = false
		if achievement_best_medal != null:
			achievement_best_medal.visible = false
		achievement_best_name_label.text = ""
		return
	if achievement_best_card != null:
		achievement_best_card.visible = true
	if achievement_best_art_frame != null:
		achievement_best_art_frame.visible = true
	if achievement_best_art != null:
		achievement_best_art.visible = true
		achievement_best_art.texture = host.visual_texture_cache._texture_or_visual_fallback(str(best.get("art", "")))
	if achievement_best_medal != null:
		achievement_best_medal.visible = true
		achievement_best_medal.texture = AchievementPresentation.mastery_medal_visual_texture(int(best.get("level", 1)), host.MASTERY_MAX_LEVEL, Callable(host.visual_texture_cache, "_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture"))
		achievement_best_medal.set_meta("achievement_skill_id", str(best.get("skill_id", "")))
		achievement_best_medal.set_meta("achievement_action_id", str(best.get("action_id", "")))
		achievement_best_medal.set_meta("achievement_action_name", str(best.get("name", "")))
		achievement_best_medal.set_meta("achievement_action_art", str(best.get("art", "")))
		achievement_best_medal.set_meta("achievement_medal_level", int(best.get("level", 1)))
	achievement_best_name_label.text = str(best.get("name", ""))

func _queue_home_achievement_refresh() -> void:
	home_achievement_refresh_token += 1
	call_deferred("_refresh_home_achievements_incremental", home_achievement_refresh_token)

func _refresh_home_achievements_incremental(token: int) -> void:
	if token != home_achievement_refresh_token or host.current_screen != "home" or host._input_routing_shell()._any_modal_overlay_visible():
		return
	var totals: Dictionary = AchievementState.elite_completion_counts(host)
	var total_earned := int(totals["earned"])
	var total_possible := int(totals["possible"])
	if achievement_elite_label != null:
		var elite_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		achievement_elite_label.text = "%s%% Elite" % int(round(elite_pct))
	if achievement_total_level_label != null:
		achievement_total_level_label.text = "Total Lv %s" % SkillState.global_level(host.skills)
	if achievement_buff_label != null:
		achievement_buff_label.text = AchievementState.global_medal_buff_lines(host)
	if achievement_total_bar != null:
		var total_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		ThemeStyles.set_progress_bar_value(achievement_total_bar, total_pct, 0.0, true)
	_update_most_impressive_activity()
	await host.get_tree().process_frame
	for def in host.skill_defs:
		if token != home_achievement_refresh_token or host.current_screen != "home" or host._input_routing_shell()._any_modal_overlay_visible():
			return
		var skill_id := str(def["id"])
		if achievement_skill_level_labels.has(skill_id):
			var level_label := achievement_skill_level_labels[skill_id] as Label
			level_label.text = "%s Lv %s" % [SkillState.skill_name(host.skill_defs, skill_id), SkillState.host_skill_level(host, skill_id)]
		_update_achievement_medal_slots(skill_id, AchievementState.mastery_actions_for_skill(host, skill_id))
		await host.get_tree().process_frame

func _achievement_medal_slot_strip(skill_id: String, actions: Array) -> Dictionary:
	var strip := AchievementMedalSlotStrip.new()
	var medal_entries := _earned_achievement_medal_entries(skill_id, actions)
	strip.slot_count = medal_entries.size()
	strip.slot_size = ACHIEVEMENT_MEDAL_SLOT_SIZE * 3.55
	strip.custom_minimum_size = Vector2(840, 140)
	strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	strip.mouse_filter = Control.MOUSE_FILTER_PASS
	var medal_shadows := []
	var medal_icons := []
	_rebuild_achievement_medal_strip_icons(strip, skill_id, medal_entries, medal_shadows, medal_icons)
	return {"root": strip, "panels": medal_shadows, "icons": medal_icons}

func _update_achievement_medal_slots(skill_id: String, actions: Array) -> void:
	var strip := achievement_medal_slot_strips.get(skill_id, null) as AchievementMedalSlotStrip
	if strip == null or not is_instance_valid(strip):
		return
	var panel_rows: Array = achievement_medal_slot_panels.get(skill_id, [])
	var icon_rows: Array = achievement_medal_slot_icons.get(skill_id, [])
	var medal_shadows: Array = panel_rows[0] if not panel_rows.is_empty() else []
	var medal_icons: Array = icon_rows[0]
	var medal_entries := _earned_achievement_medal_entries(skill_id, actions)
	if _achievement_medal_strip_needs_rebuild(medal_icons, medal_entries):
		_rebuild_achievement_medal_strip_icons(strip, skill_id, medal_entries, medal_shadows, medal_icons)
		achievement_medal_slot_panels[skill_id] = [medal_shadows]
		achievement_medal_slot_icons[skill_id] = [medal_icons]
		return
	for slot_index in range(medal_icons.size()):
		var icon := medal_icons[slot_index] as TextureRect
		var shadow := medal_shadows[slot_index] as TextureRect if slot_index < medal_shadows.size() else null
		_configure_achievement_medal_slot(icon, shadow, skill_id, medal_entries, slot_index)
	strip._layout_icons()

func _earned_achievement_medal_entries(skill_id: String, actions: Array) -> Array:
	var medal_entries := []
	for action in actions:
		var action_def := action as Dictionary
		var action_id := str(action_def.get("id", ""))
		var mastery_level: int = MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
		if mastery_level <= 0:
			continue
		medal_entries.append({
			"action": action_def,
			"action_id": action_id,
			"level": mastery_level
		})
	return medal_entries

func _achievement_medal_strip_needs_rebuild(medal_icons: Array, medal_entries: Array) -> bool:
	if medal_icons.size() != medal_entries.size():
		return true
	for i in range(medal_icons.size()):
		var icon := medal_icons[i] as TextureRect
		var medal_entry := medal_entries[i] as Dictionary
		if icon == null or str(icon.get_meta("achievement_action_id", "")) != str(medal_entry.get("action_id", "")):
			return true
	return false

func _rebuild_achievement_medal_strip_icons(strip: AchievementMedalSlotStrip, skill_id: String, medal_entries: Array, medal_shadows: Array, medal_icons: Array) -> void:
	for raw_icon in medal_icons:
		var icon := raw_icon as TextureRect
		if icon != null and is_instance_valid(icon):
			icon.queue_free()
	for raw_shadow in medal_shadows:
		var shadow := raw_shadow as TextureRect
		if shadow != null and is_instance_valid(shadow):
			shadow.queue_free()
	medal_shadows.clear()
	medal_icons.clear()
	strip.clear_slot_icons()
	strip.slot_count = medal_entries.size()
	for i in range(medal_entries.size()):
		var slot_z := (medal_entries.size() - i) * 2
		var shadow: TextureRect = host.visual_texture_cache._image_from_texture(AchievementPresentation.mastery_medal_texture(1, host.MASTERY_MAX_LEVEL, Callable(host.visual_texture_cache, "_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture")), strip.slot_size)
		shadow.material = AchievementPresentation.mastery_medal_silhouette_material(Color(0, 0, 0, 0.70))
		shadow.z_index = slot_z
		var icon: TextureRect = host.visual_texture_cache._image_from_texture(AchievementPresentation.mastery_medal_texture(1, host.MASTERY_MAX_LEVEL, Callable(host.visual_texture_cache, "_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture")), strip.slot_size)
		icon.z_index = slot_z + 1
		icon.tooltip_text = ""
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.gui_input.connect(_on_achievement_medal_slot_input.bind(strip.get_instance_id(), icon.get_instance_id(), skill_id))
		_configure_achievement_medal_slot(icon, shadow, skill_id, medal_entries, i)
		strip.add_slot_icon(icon, shadow)
		medal_shadows.append(shadow)
		medal_icons.append(icon)

func _configure_achievement_medal_slot(icon: TextureRect, shadow: TextureRect, skill_id: String, medal_entries: Array, slot_index: int) -> void:
	if icon == null:
		return
	if slot_index >= medal_entries.size():
		icon.visible = false
		if shadow != null:
			shadow.visible = false
		return
	var medal_entry := medal_entries[slot_index] as Dictionary
	var action := medal_entry.get("action", {}) as Dictionary
	var action_id := str(medal_entry.get("action_id", ""))
	var mastery_level := int(medal_entry.get("level", 0))
	icon.set_meta("achievement_action_id", action_id)
	icon.set_meta("achievement_action_name", str(action.get("name", "")))
	icon.set_meta("achievement_action_art", str(action.get("art", "")))
	icon.set_meta("achievement_medal_level", mastery_level)
	icon.material = null
	icon.texture = AchievementPresentation.mastery_medal_visual_texture(mastery_level, host.MASTERY_MAX_LEVEL, Callable(host.visual_texture_cache, "_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture"))
	icon.visible = true
	if shadow != null:
		shadow.set_meta("achievement_medal_outline", false)
		shadow.visible = false
	icon.modulate = Color.WHITE

func _on_achievement_medal_slot_input(event: InputEvent, strip_id: int, icon_id: int, skill_id: String) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	var strip: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(strip_id))
	var icon: TextureRect = host._app_lifecycle_runtime().valid_texture_rect_ref(instance_from_id(icon_id))
	if strip == null or icon == null:
		return
	_show_achievement_medal_popover(strip, icon, skill_id)

func _route_achievement_medal_press(event: InputEvent) -> bool:
	if not host._input_routing_shell()._is_primary_press_event(event):
		return false
	var event_position := _primary_press_event_position(event)
	if event_position == Vector2.INF:
		return false
	var featured_icon := achievement_best_medal as TextureRect
	if featured_icon != null and _achievement_medal_icon_hit(featured_icon, event_position):
		var featured_skill_id := str(featured_icon.get_meta("achievement_skill_id", ""))
		if not featured_skill_id.is_empty():
			var featured_anchor := achievement_best_card as Control
			_show_achievement_medal_popover(featured_anchor if featured_anchor != null else featured_icon, featured_icon, featured_skill_id)
			return true
	for raw_skill_id in achievement_medal_slot_icons.keys():
		var skill_id := str(raw_skill_id)
		var strip := achievement_medal_slot_strips.get(skill_id, null) as Control
		if strip == null or not is_instance_valid(strip) or not strip.is_visible_in_tree():
			continue
		var icon_rows: Array = achievement_medal_slot_icons.get(skill_id, [])
		for raw_row in icon_rows:
			var row := raw_row as Array
			for raw_icon in row:
				var icon := raw_icon as TextureRect
				if not _achievement_medal_icon_hit(icon, event_position):
					continue
				_show_achievement_medal_popover(strip, icon, skill_id)
				return true
	return false

func _achievement_medal_icon_hit(icon: TextureRect, event_position: Vector2) -> bool:
	return (
		icon != null
		and is_instance_valid(icon)
		and icon.visible
		and icon.is_visible_in_tree()
		and icon.get_global_rect().grow(22.0).has_point(event_position)
	)

func _primary_press_event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			return mouse_event.global_position
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			return touch_event.position
	return Vector2.INF

func _show_achievement_medal_popover(strip: Control, icon: TextureRect, skill_id: String) -> void:
	_hide_achievement_medal_popovers()
	var popover := _achievement_medal_popover(
		str(icon.get_meta("achievement_action_name", "")),
		str(icon.get_meta("achievement_action_art", "")),
		int(icon.get_meta("achievement_medal_level", 0)),
		skill_id
	)
	var popover_parent := _achievement_medal_popover_parent(strip)
	popover_parent.add_child(popover)
	var popover_size := popover.custom_minimum_size
	popover.set_anchors_preset(Control.PRESET_TOP_LEFT)
	popover.size = popover_size
	var icon_rect := icon.get_global_rect()
	var parent_rect := popover_parent.get_global_rect()
	var canvas_bottom: float = host.BASE_CANVAS.y - host._navigation_shell()._bottom_ui_reserved_height_for_current_screen() - 24.0
	var max_x: float = host.BASE_CANVAS.x - popover_size.x - 24.0
	var max_y: float = canvas_bottom - popover_size.y
	var global_x := clampf(icon_rect.get_center().x - popover_size.x * 0.5, 24.0, maxf(24.0, max_x))
	var global_y := icon_rect.position.y - popover_size.y - 18.0
	if global_y < host.SKILLS_PAGE_TOP_PAD:
		global_y = icon_rect.position.y + icon_rect.size.y + 18.0
	global_y = clampf(global_y, host.SKILLS_PAGE_TOP_PAD, maxf(host.SKILLS_PAGE_TOP_PAD, max_y))
	popover.position = Vector2(global_x, global_y) - parent_rect.position
	popover.visible = true
	popover.set_meta("achievement_medal_popover_opened_msec", Time.get_ticks_msec())
	popover.modulate = Color(1, 1, 1, 0)
	popover.scale = Vector2(0.96, 0.96)
	popover.pivot_offset = Vector2(popover_size.x * 0.5, popover_size.y)
	var tween: Tween = host.create_tween()
	popover.set_meta("achievement_medal_popover_tween", tween)
	tween.tween_property(popover, "modulate:a", 1.0, 0.08)
	tween.parallel().tween_property(popover, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _achievement_medal_popover_parent(strip: Control) -> Control:
	var visible_home_page := host._app_lifecycle_runtime().valid_control_ref(host.home_page) as Control
	if host.current_screen == "home" and visible_home_page != null and visible_home_page.is_visible_in_tree():
		return visible_home_page
	var visible_skills_content := host._app_lifecycle_runtime().valid_control_ref(host.skills_content) as Control
	if visible_skills_content != null and visible_skills_content.is_visible_in_tree():
		return visible_skills_content
	if strip != null and is_instance_valid(strip):
		return strip
	return host

func _achievement_medal_popover(action_name: String, art_path: String, medal_level: int, skill_id: String) -> PanelContainer:
	var popover := PanelContainer.new()
	popover.custom_minimum_size = Vector2(460, 370)
	popover.size = popover.custom_minimum_size
	popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.z_index = 4095
	popover.add_to_group("achievement_medal_popovers")
	popover.add_theme_stylebox_override("panel", PassiveModuleStyles.popup(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style")))
	var margin := MarginContainer.new()
	margin.custom_minimum_size = Vector2(428, 340)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 15)
	popover.add_child(margin)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(428, 340)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)
	var art: TextureRect = host.visual_texture_cache._image_from_texture(host.visual_texture_cache._texture_or_visual_fallback(art_path), Vector2(105, 105))
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(art)
	var title: Label = host._label(action_name if not action_name.is_empty() else SkillState.skill_name(host.skill_defs, skill_id), 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size = Vector2(428, 132)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(title)
	var medal_name: String = MasteryState.medal_name(medal_level) if medal_level > 0 else "Medal"
	var subtitle: Label = host._label("%s medal" % medal_name, 48, ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.custom_minimum_size = Vector2(428, 58)
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_color_override("font_outline_color", host.COLOR_INK)
	subtitle.add_theme_constant_override("outline_size", 6)
	stack.add_child(subtitle)
	return popover

func _route_achievement_medal_popover_dismiss(event: InputEvent) -> bool:
	if not host._input_routing_shell()._is_primary_press_event(event):
		return false
	var has_visible_popover := false
	var newest_opened_msec := 0
	for raw_popover in host.get_tree().get_nodes_in_group("achievement_medal_popovers"):
		var popover := raw_popover as Control
		if popover == null or not is_instance_valid(popover):
			continue
		has_visible_popover = true
		newest_opened_msec = maxi(newest_opened_msec, int(popover.get_meta("achievement_medal_popover_opened_msec", 0)))
	if not has_visible_popover:
		return false
	if Time.get_ticks_msec() - newest_opened_msec < 120:
		return false
	_hide_achievement_medal_popovers()
	return true

func _hide_achievement_medal_popovers() -> void:
	for raw_popover in host.get_tree().get_nodes_in_group("achievement_medal_popovers"):
		var popover := raw_popover as Control
		if popover == null or not is_instance_valid(popover):
			continue
		host._app_lifecycle_runtime()._kill_meta_tween(popover, "achievement_medal_popover_tween")
		popover.queue_free()

func _prewarm_achievements_overlay() -> void:
	if host.home_page == null or not is_instance_valid(host.home_page):
		return
	_ensure_achievements_overlay()
	call_deferred("_rebuild_achievements_overlay")

func _ensure_achievements_overlay() -> void:
	if host._app_lifecycle_runtime().lazy_overlay_built("achievements"):
		return
	host._app_lifecycle_runtime().mark_lazy_overlay_built("achievements")
	_build_achievements_overlay()

func _on_achievements_overlay_gui_input(event: InputEvent) -> void:
	var panel: Control = achievements_panel if achievements_panel != null and is_instance_valid(achievements_panel) else achievements_panel_frame
	if InputRoutingShell.event_is_outside_panel_press(event, panel):
		_hide_achievement_medal_popovers()
		_close_achievements_overlay()

func _open_achievements_overlay() -> void:
	achievements_modal_tab = "achievements"
	home_achievement_refresh_token += 1
	host.button_press_runtime.play_default_button_sfx()
	_ensure_achievements_overlay()
	if achievements_overlay == null:
		return
	host._reward_feedback_surface()._clear_skill_reward_floats()
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(achievements_overlay, true)
	call_deferred("_rebuild_achievements_overlay")

func _close_achievements_overlay() -> void:
	if achievements_overlay != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(achievements_overlay, false)
	host.button_press_runtime.play_default_button_sfx()

func _build_achievements_overlay() -> void:
	achievements_overlay = ColorRect.new()
	achievements_overlay.color = Color(0, 0, 0, 0.42)
	achievements_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_overlay.z_index = host.MODAL_OVERLAY_Z
	achievements_overlay.z_as_relative = false
	achievements_overlay.visible = false
	achievements_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	achievements_overlay.add_to_group("modal_overlay")
	achievements_overlay.gui_input.connect(_on_achievements_overlay_gui_input)
	host.add_child(achievements_overlay)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_overlay.add_child(center)
	var frame = Control.new()
	frame.custom_minimum_size = ACHIEVEMENTS_MODAL_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(frame)
	achievements_panel_frame = frame
	var panel = PanelContainer.new()
	panel.custom_minimum_size = ACHIEVEMENTS_MODAL_SIZE
	panel.add_theme_stylebox_override("panel", host._surface_style(host.COLOR_PANEL, host.CARD_RADIUS, 72, true))
	frame.add_child(panel)
	achievements_panel = panel
	var outer = MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 27)
	outer.add_theme_constant_override("margin_right", 27)
	outer.add_theme_constant_override("margin_top", 23)
	outer.add_theme_constant_override("margin_bottom", 23)
	panel.add_child(outer)
	var stack = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 14)
	outer.add_child(stack)

	var tabs = HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tabs.add_theme_constant_override("separation", 12)
	stack.add_child(tabs)
	achievements_tab_buttons.clear()
	var achievements_tab = host._menu_button("Achievements")
	achievements_tab.pressed.connect(_set_achievements_modal_tab.bind("achievements"))
	tabs.add_child(achievements_tab)
	achievements_tab_buttons["achievements"] = achievements_tab
	var buffs_tab = host._menu_button("Global Buffs")
	buffs_tab.pressed.connect(_set_achievements_modal_tab.bind("buffs"))
	tabs.add_child(buffs_tab)
	achievements_tab_buttons["buffs"] = buffs_tab

	achievements_hide_completed = CheckBox.new()
	achievements_hide_completed.text = "Show completed achievements"
	achievements_hide_completed.button_pressed = false
	achievements_hide_completed.add_theme_font_size_override("font_size", 48)
	achievements_hide_completed.add_theme_color_override("font_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_hover_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_hover_pressed_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_pressed_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_focus_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_disabled_color", host.COLOR_INK)
	if host.app_bold_font != null:
		achievements_hide_completed.add_theme_font_override("font", host.app_bold_font)
	elif host.app_font != null:
		achievements_hide_completed.add_theme_font_override("font", host.app_font)
	host.button_press_runtime.attach_default_button_sfx(achievements_hide_completed)
	achievements_hide_completed.toggled.connect(_on_achievements_hide_completed_toggled)
	stack.add_child(achievements_hide_completed)

	var scroll = MobileScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, ACHIEVEMENTS_MODAL_SCROLL_HEIGHT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	stack.add_child(scroll)
	achievements_scroll = scroll
	achievements_list_stack = VBoxContainer.new()
	achievements_list_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievements_list_stack.add_theme_constant_override("separation", 14)
	scroll.add_child(achievements_list_stack)

func _render_achievements_page() -> void:
	achievements_panel_frame = null
	achievements_panel = null
	achievements_scroll = null
	achievements_list_stack = null
	host.content_scroll = MobileScrollContainer.new()
	host.content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.content_scroll.set_pull_resistance_enabled(true)
	host._add_centered_skill_column(host.content_scroll)
	var stack = VBoxContainer.new()
	stack.custom_minimum_size.x = host._skill_content_width()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	host.content_scroll.add_child(stack)
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 46)
	stack.add_child(top_spacer)

	var tabs = HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tabs.add_theme_constant_override("separation", 12)
	stack.add_child(tabs)
	achievements_tab_buttons.clear()
	var achievements_tab = host._menu_button("Achievements")
	achievements_tab.pressed.connect(_set_achievements_modal_tab.bind("achievements"))
	tabs.add_child(achievements_tab)
	achievements_tab_buttons["achievements"] = achievements_tab
	var buffs_tab = host._menu_button("Global Buffs")
	buffs_tab.pressed.connect(_set_achievements_modal_tab.bind("buffs"))
	tabs.add_child(buffs_tab)
	achievements_tab_buttons["buffs"] = buffs_tab

	achievements_hide_completed = CheckBox.new()
	achievements_hide_completed.text = "Show completed achievements"
	achievements_hide_completed.button_pressed = false
	achievements_hide_completed.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	achievements_hide_completed.add_theme_font_size_override("font_size", 48)
	achievements_hide_completed.add_theme_color_override("font_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_hover_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_hover_pressed_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_pressed_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_focus_color", host.COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_disabled_color", host.COLOR_INK)
	if host.app_bold_font != null:
		achievements_hide_completed.add_theme_font_override("font", host.app_bold_font)
	elif host.app_font != null:
		achievements_hide_completed.add_theme_font_override("font", host.app_font)
	host.button_press_runtime.attach_default_button_sfx(achievements_hide_completed)
	achievements_hide_completed.toggled.connect(_on_achievements_hide_completed_toggled)
	stack.add_child(achievements_hide_completed)

	achievements_list_stack = VBoxContainer.new()
	achievements_list_stack.custom_minimum_size.x = host._skill_content_width()
	achievements_list_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievements_list_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	achievements_list_stack.add_theme_constant_override("separation", 14)
	stack.add_child(achievements_list_stack)
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 110)
	stack.add_child(bottom_spacer)
	call_deferred("_rebuild_achievements_overlay")

func _apply_achievements_modal_tab_style(button: Button, active: bool) -> void:
	var fill = Color("#959088") if active else host.COLOR_BLUE
	var hover_fill = fill if active else fill.lightened(0.06)
	var pressed = fill.darkened(0.10)
	button.add_theme_stylebox_override("normal", host._paper_button_style(fill, 24, 18))
	button.add_theme_stylebox_override("hover", host._paper_button_style(hover_fill, 24, 18))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(pressed, 24, 18, true))

func _set_achievements_modal_tab(tab: String) -> void:
	achievements_modal_tab = tab
	_rebuild_achievements_overlay()
	host.button_press_runtime.play_default_button_sfx()

func _on_achievements_hide_completed_toggled(_pressed: bool) -> void:
	_rebuild_achievements_overlay()

func _achievements_current_signature() -> String:
	var show_completed = achievements_hide_completed != null and achievements_hide_completed.button_pressed
	return "%s:%s:%s:%s:%s:%s:%s" % [
		achievements_modal_tab,
		show_completed,
		SkillState.global_level(host.skills),
		host.mastery.size(),
		host.activity_crit_seen,
		host.activity_mega_crit_seen,
		AchievementState.global_medal_buff_lines(host)
	]

func _rebuild_achievements_overlay(force = false) -> void:
	if achievements_list_stack == null:
		return
	var signature = _achievements_current_signature()
	if not force and achievements_rebuild_signature == signature and achievements_list_stack.get_child_count() > 0:
		return
	achievements_rebuild_signature = signature
	achievements_rebuild_token += 1
	var token = achievements_rebuild_token
	host._clear(achievements_list_stack)
	var active_buffs = AchievementState.active_global_buff_lines(host) if achievements_modal_tab == "buffs" else []
	_apply_achievements_modal_layout(active_buffs.size())
	for key in achievements_tab_buttons.keys():
		var button = achievements_tab_buttons[key] as Button
		if button != null:
			_apply_achievements_modal_tab_style(button, str(key) == achievements_modal_tab)
	if achievements_hide_completed != null:
		achievements_hide_completed.visible = achievements_modal_tab == "achievements"
	if achievements_modal_tab == "buffs":
		call_deferred("_rebuild_global_buffs_tab_deferred", active_buffs, token)
	else:
		achievements_list_stack.add_child(host._label("Loading achievements...", 52, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		call_deferred("_rebuild_achievement_log_tab_deferred", token)
	_apply_achievements_modal_layout(active_buffs.size())

func _apply_achievements_modal_layout(buff_count: int) -> void:
	if achievements_panel == null or achievements_scroll == null:
		return
	var modal_size = ACHIEVEMENTS_MODAL_SIZE
	var scroll_height = ACHIEVEMENTS_MODAL_SCROLL_HEIGHT
	if achievements_modal_tab != "buffs":
		achievements_scroll.custom_minimum_size = Vector2(0, scroll_height)
		_fit_achievements_modal(modal_size)
		return
	var visible_rows = maxi(1, buff_count)
	var modal_height = clampf(
		GLOBAL_BUFFS_MODAL_BASE_HEIGHT + float(visible_rows) * GLOBAL_BUFFS_MODAL_ROW_HEIGHT,
		GLOBAL_BUFFS_MODAL_MIN_HEIGHT,
		GLOBAL_BUFFS_MODAL_MAX_HEIGHT
	)
	modal_size = Vector2(ACHIEVEMENTS_MODAL_SIZE.x, modal_height)
	scroll_height = maxf(520.0, modal_height - GLOBAL_BUFFS_MODAL_SCROLL_CHROME)
	achievements_scroll.custom_minimum_size = Vector2(0, scroll_height)
	_fit_achievements_modal(modal_size)

func _fit_achievements_modal(modal_size: Vector2) -> void:
	var fitted_scale = host._fit_scale_to_canvas(modal_size, ACHIEVEMENTS_MODAL_VIEWPORT_MARGIN)
	var fitted_frame_size = modal_size * fitted_scale
	if achievements_panel_frame != null:
		achievements_panel_frame.custom_minimum_size = fitted_frame_size
		achievements_panel_frame.size = fitted_frame_size
		achievements_panel_frame.reset_size()
		achievements_panel_frame.update_minimum_size()
	achievements_panel.custom_minimum_size = modal_size
	achievements_panel.size = modal_size
	achievements_panel.position = Vector2.ZERO
	achievements_panel.scale = Vector2(fitted_scale, fitted_scale)
	achievements_panel.reset_size()
	achievements_panel.update_minimum_size()

func _achievements_rebuild_current(token: int) -> bool:
	return (
		token == achievements_rebuild_token
		and achievements_list_stack != null
		and is_instance_valid(achievements_list_stack)
	)

func _rebuild_achievement_log_tab_deferred(token: int) -> void:
	if not _achievements_rebuild_current(token):
		return
	host._clear(achievements_list_stack)
	await host.get_tree().process_frame
	if not _achievements_rebuild_current(token):
		return
	var hide_completed = achievements_hide_completed != null and not achievements_hide_completed.button_pressed
	var any_visible = false
	var cards_since_yield = 0
	for achievement in AchievementState.visible_host_milestones(host, hide_completed):
		if not _achievements_rebuild_current(token):
			return
		any_visible = true
		achievements_list_stack.add_child(_achievement_log_card(achievement))
		cards_since_yield += 1
		if cards_since_yield >= 4:
			cards_since_yield = 0
			await host.get_tree().process_frame
	if not any_visible:
		if not _achievements_rebuild_current(token):
			return
		achievements_list_stack.add_child(host._label("Everything visible here is complete.", 52, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))

func _rebuild_global_buffs_tab_deferred(buffs: Array, token: int) -> void:
	if not _achievements_rebuild_current(token):
		return
	host._clear(achievements_list_stack)
	await host.get_tree().process_frame
	if not _achievements_rebuild_current(token):
		return
	if buffs.is_empty():
		achievements_list_stack.add_child(host._label("No global buffs earned yet.", 60, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var empty_detail: Label = host._label("Earn your first Bronze medal on any activity to unlock the first account buff.", 52, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty_detail.custom_minimum_size = Vector2(0, 180)
		empty_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		achievements_list_stack.add_child(empty_detail)
		return
	var rows_since_yield := 0
	for buff_text in buffs:
		if not _achievements_rebuild_current(token):
			return
		achievements_list_stack.add_child(_global_buff_list_row(str(buff_text)))
		rows_since_yield += 1
		if rows_since_yield >= 6:
			rows_since_yield = 0
			await host.get_tree().process_frame

func _global_buff_list_row(text: String) -> Control:
	var row := MarginContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("margin_left", 20)
	row.add_theme_constant_override("margin_right", 20)
	row.add_theme_constant_override("margin_top", 4)
	row.add_theme_constant_override("margin_bottom", 4)
	var label: Label = host._label(text, 48, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	return row

func _achievement_art(achievement: Dictionary) -> Control:
	var art = Control.new()
	art.custom_minimum_size = Vector2(94, 76)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match str(achievement.get("kind", "")):
		"skill_level":
			var skill_id = str(achievement.get("skill_id", ""))
			_add_achievement_art_image(art, host.visual_texture_cache._texture(SkillIconBadge.icon_path(skill_id)), Vector2(3, -3.5), Vector2(83, 83), 1)
		"action_medal":
			_add_achievement_art_image(art, host.visual_texture_cache._texture(str(achievement.get("art", ""))), Vector2(0, 3), Vector2(66, 66), 1)
			_add_achievement_art_image(art, AchievementPresentation.mastery_medal_visual_texture(int(achievement.get("medal_level", 1)), host.MASTERY_MAX_LEVEL, Callable(host.visual_texture_cache, "_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture")), Vector2(48, 29), Vector2(43, 43), 2)
		"total_level":
			_add_achievement_art_image(art, host.visual_texture_cache._texture(AchievementPresentation.TOTAL_LEVEL_ART), Vector2(3, -3.5), Vector2(83, 83), 1)
		"tier_count":
			var tier = int(achievement.get("tier", achievement.get("medal_level", 1)))
			var levels = []
			for _i in range(AchievementPresentation.same_tier_medal_count(int(achievement.get("target", 1)))):
				levels.append(tier)
			_populate_achievement_medal_cluster(art, levels)
		"cumulative_medals":
			art.custom_minimum_size = Vector2(110, 86)
			_add_achievement_art_image(art, host.visual_texture_cache._texture(AchievementPresentation.CUMULATIVE_MEDALS_ART), Vector2(0, -2), Vector2(86, 86), 1)
		"activity_crit":
			art.custom_minimum_size = Vector2(118, 90)
			_add_achievement_art_image(art, host.visual_texture_cache._texture(AchievementPresentation.CRIT_ART), Vector2(0, 2), Vector2(118, 88), 1)
		_:
			_add_achievement_art_image(art, host.visual_texture_cache._texture(AchievementPresentation.CREDIT_ART), Vector2(6, 0), Vector2(77, 72), 1)
	return art

func _add_achievement_art_image(parent: Control, texture: Texture2D, image_position: Vector2, image_size: Vector2, image_z_index: int) -> void:
	var image = host.visual_texture_cache._image_from_texture(texture, image_size)
	image.position = image_position
	image.size = image_size
	image.z_index = image_z_index
	parent.add_child(image)

func _populate_achievement_medal_cluster(parent: Control, levels: Array) -> void:
	var count = levels.size()
	var positions = AchievementPresentation.medal_cluster_positions(count)
	var medal_size = 72.0
	if count >= 9:
		medal_size = 28.0
	elif count >= 7:
		medal_size = 31.0
	elif count >= 5:
		medal_size = 35.0
	elif count >= 3:
		medal_size = 38.0
	for i in range(count):
		var center: Vector2 = positions[i] if i < positions.size() else Vector2(44.5, 36)
		var icon_size = Vector2(medal_size, medal_size)
		_add_achievement_art_image(parent, AchievementPresentation.mastery_medal_visual_texture(int(levels[i]), host.MASTERY_MAX_LEVEL, Callable(host.visual_texture_cache, "_texture"), Callable(host.visual_texture_cache, "_visual_fallback_texture")), center - icon_size * 0.5, icon_size, i + 1)

func _achievement_log_card(achievement: Dictionary, show_progress = true) -> Control:
	var completed = bool(achievement.get("completed", false))
	var accent = Color(str(achievement.get("accent", "#f4bf35")))
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 163 if show_progress else 138)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", AchievementPresentation.card(Color("#fffdf8") if completed else Color("#fff6e1"), 17, 17, Callable(host, "_surface_style")))
	card.modulate = Color.WHITE if completed else Color(1, 1, 1, 0.78)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 11)
	card.add_child(stack)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 15)
	stack.add_child(row)
	row.add_child(_achievement_art(achievement))
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 4)
	row.add_child(copy)
	var title_label = host._label(str(achievement.get("title", "")), 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(title_label)
	var subtitle_label = host._label(str(achievement.get("subtitle", "")), 48, accent if completed else host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle_label)
	var reward_label = host._label(str(achievement.get("reward", "")), 48, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(reward_label)
	if show_progress:
		stack.add_child(ThemeStyles.progress_bar(accent, 18, AchievementPresentation.progress_pct(achievement)))
	return card

