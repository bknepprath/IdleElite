extends RefCounted

const LeaderboardProfile = preload("res://scripts/leaderboard/profile.gd")
const InputRoutingShell = preload("res://scripts/ui/input_routing_shell.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const ChatState = preload("res://scripts/online/chat_state.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

const PROFILE_AVATAR_SHEETS := [
	"res://assets/content/ui/profile-avatar-game-objects-spritesheet-1080p.png",
	"res://assets/content/ui/profile-avatar-blue-guy-spritesheet-1080p.png"
]
const PROFILE_AVATAR_COUNT := 20
const PROFILE_AVATAR_SHEET_CELL_COUNT := 10
const PROFILE_AVATAR_COLUMNS := 5
const PROFILE_AVATAR_CELL_SIZE := 256
const PROFILE_AVATAR_ATLAS_INSET := 8
const PROFILE_AVATAR_COLORED_ATLAS_INSET := 30
const PROFILE_AVATAR_FRAME_BORDER := 8
const CHAT_KEYBOARD_PREVIEW_HEIGHT := 89
const CHAT_STRIP_HEIGHT := 130
const CHAT_UI_Z := 3500
const CHAT_OVERLAY_CANVAS_LAYER := 132
const PROFILE_OVERLAY_CANVAS_LAYER := CHAT_OVERLAY_CANVAS_LAYER + 1
const CHAT_STRIP_EMPTY_GRACE_MSEC := 2200
const CHAT_STRIP_HIDE_GRACE_MSEC := 800
const CHAT_STRIP_ICON := "res://assets/content/ui/chat-speech-bubble.png"
const CHAT_STRIP_FONT_WIDTH_SCALE := 0.58
const CHAT_UNREAD_DOT_DIAMETER := 22.0
const CHAT_UNREAD_DOT_EDGE_INSET := 16.0
var host
var profile_overlay: Control
var profile_overlay_layer: CanvasLayer
var profile_panel: PanelContainer
var profile_content_stack: VBoxContainer
var profile_name_edit: LineEdit
var profile_status_label: Label
var profile_avatar_buttons := []
var profile_avatar_picker_open := false
var profile_avatar_texture_cache := {}
var chat_message_edit: LineEdit
var chat_strip: PanelContainer
var chat_unread_dot: PanelContainer
var chat_strip_line_one: Label
var chat_strip_line_two: Label
var chat_strip_condensed_font: Font
var chat_strip_last_visible := false
var chat_strip_last_line_one := ""
var chat_strip_last_line_two := ""
var chat_strip_stable_line_one := ""
var chat_strip_stable_line_two := ""
var chat_strip_empty_started_msec := 0
var chat_strip_hide_started_msec := 0
var chat_overlay_layer: CanvasLayer
var chat_overlay: ColorRect
var chat_keyboard_fill: ColorRect
var chat_keyboard_preview: PanelContainer
var chat_keyboard_preview_label: Label
var chat_overlay_body: VBoxContainer
var chat_overlay_scroll: MobileScrollContainer
var chat_overlay_list: VBoxContainer
var chat_overlay_notice: Control
var chat_overlay_row_nodes := {}
var chat_overlay_row_signatures := {}
var chat_overlay_shell_ready := false
var chat_profile_button: Button
var chat_status_title_labels := []
var chat_status_detail_labels := []
var chat_keyboard_lift_active := false
var chat_keyboard_lift_pixels := 0.0
var chat_keyboard_lift_hold_seconds := 0.0
var chat_keyboard_lift_last_height := 0.0
var chat_keyboard_lift_target_pixels := 0.0
var chat_keyboard_lift_viewport_height := 0.0
var chat_keyboard_lift_window_height := 0.0
var chat_keyboard_lift_zero_seconds := 0.0
var chat_keyboard_preview_keyboard_visible := false
var chat_keyboard_was_visible := false
var chat_keyboard_close_submit_done := false
var chat_keyboard_focus_active := false
var chat_draft_message := ""
var chat_enter_submit_armed := true
var chat_submit_deferred := false


func _init(host_ref) -> void:
	host = host_ref

static func _chat_world_tab_style(ink_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3f5068")
	style.border_color = ink_color
	style.set_border_width_all(5)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func chat_unread_dot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ef2f2f")
	style.border_color = Color("#111111")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 499.5
	style.corner_radius_top_right = 499.5
	style.corner_radius_bottom_left = 499.5
	style.corner_radius_bottom_right = 499.5
	return style

static func _chat_expanded_message_style(deleted := false, is_self := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#e7f5ff") if is_self and not deleted else Color("#e8e8e8") if not deleted else Color("#ddd7cf")
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 5 if is_self and not deleted else 9
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

static func _chat_back_button_style(pressed := false, ink_color := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ef3f55").darkened(0.08 if pressed else 0.0)
	style.border_color = ink_color
	style.set_border_width_all(4)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 5 + (2.5 if pressed else 0.0)
	style.content_margin_bottom = 5 - (1.5 if pressed else 0.0)
	return style

static func _chat_input_style(focused := false, ink_color := Color.BLACK, focus_color := Color.BLUE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = focus_color if focused else ink_color
	style.set_border_width_all(4)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.content_margin_left = 23
	style.content_margin_right = 23
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func _chat_keyboard_preview_style(focus_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = focus_color
	style.set_border_width_all(4)
	style.corner_radius_top_left = 11
	style.corner_radius_top_right = 11
	style.corner_radius_bottom_left = 11
	style.corner_radius_bottom_right = 11
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 4)
	return style

static func _chat_strip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.725, 0.725, 0.725, 1.0)
	style.draw_center = true
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style

func chat_strip_control() -> Control:
	return chat_strip

func chat_overlay_visible() -> bool:
	return chat_overlay != null and is_instance_valid(chat_overlay) and chat_overlay.visible

func keyboard_lift_active() -> bool:
	return chat_keyboard_lift_active

func keyboard_focus_active() -> bool:
	return chat_keyboard_focus_active

func keyboard_lift_pixels() -> float:
	return chat_keyboard_lift_pixels

func set_chat_draft_message(text: String) -> void:
	chat_draft_message = text
	if chat_message_edit != null and is_instance_valid(chat_message_edit):
		chat_message_edit.text = text
	_update_chat_keyboard_preview()

func clear_chat_draft_message() -> void:
	set_chat_draft_message("")

func reset_chat_overlay_refs() -> void:
	chat_overlay_layer = null
	chat_overlay = null
	chat_overlay_body = null
	chat_overlay_scroll = null
	chat_overlay_list = null
	chat_overlay_notice = null
	chat_overlay_row_nodes.clear()
	chat_overlay_row_signatures.clear()
	chat_overlay_shell_ready = false
	chat_profile_button = null

func _global_chat_allowed() -> bool:
	return not host._onboarding_runtime()._onboarding_path_active()

func _chat_strip_visible_on_current_screen() -> bool:
	return host.current_screen == "menu" or host.current_screen == "skill" or host.current_screen == "pinned" or host.current_screen == "queue"

func _ensure_chat_strip() -> void:
	if not _global_chat_allowed():
		return
	if chat_strip != null and is_instance_valid(chat_strip):
		return
	host._online_runtime().ensure_leaderboard_http()
	_build_chat_strip()

func _ensure_chat_overlay() -> void:
	if host._app_lifecycle_runtime().lazy_overlay_built("chat"):
		return
	host._app_lifecycle_runtime().mark_lazy_overlay_built("chat")
	_build_chat_overlay()

func _ensure_profile_overlay() -> void:
	if host._app_lifecycle_runtime().lazy_overlay_built("profile"):
		return
	host._app_lifecycle_runtime().mark_lazy_overlay_built("profile")
	_build_profile_overlay()

func _rebuild_profile_overlay_if_visible() -> void:
	if profile_overlay != null and profile_overlay.visible:
		_rebuild_profile_overlay()

func _profile_overlay_visible() -> bool:
	return profile_overlay != null and profile_overlay.visible

func _hide_profile_overlay() -> void:
	if profile_overlay != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(profile_overlay, false)

func _reset_profile_overlay_refs() -> void:
	profile_overlay_layer = null
	profile_overlay = null
	profile_panel = null
	profile_content_stack = null
	profile_name_edit = null
	profile_status_label = null
	profile_avatar_buttons.clear()
	profile_avatar_texture_cache.clear()

func _sync_chat_unread_dot() -> void:
	if chat_unread_dot == null or not is_instance_valid(chat_unread_dot):
		return
	var should_show = chat_strip != null and is_instance_valid(chat_strip) and chat_strip.visible and host._online_runtime()._chat_has_unread_messages()
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_unread_dot, should_show)

func _render_chat_if_visible() -> void:
	if chat_overlay != null and chat_overlay.visible:
		host._online_runtime().mark_chat_opened_to_latest(false)
	_update_chat_strip()
	_refresh_chat_status_labels()
	if chat_overlay == null or not chat_overlay.visible:
		return
	_ensure_chat_overlay_shell()
	_sync_chat_overlay_rows()
	_chat_scroll_to_latest_deferred()

func _track_chat_status_labels(title: Label, detail: Label) -> void:
	if title != null and is_instance_valid(title):
		chat_status_title_labels.append(title)
	if detail != null and is_instance_valid(detail):
		chat_status_detail_labels.append(detail)

func _refresh_chat_status_labels() -> void:
	var title_text = _chat_status_title()
	var detail_text = _chat_status_detail()
	for i in range(chat_status_title_labels.size() - 1, -1, -1):
		var raw_title_label = chat_status_title_labels[i]
		if raw_title_label == null or not is_instance_valid(raw_title_label):
			chat_status_title_labels.remove_at(i)
		else:
			var title_label = raw_title_label as Label
			if title_label == null:
				chat_status_title_labels.remove_at(i)
				continue
			title_label.text = title_text
	for i in range(chat_status_detail_labels.size() - 1, -1, -1):
		var raw_detail_label = chat_status_detail_labels[i]
		if raw_detail_label == null or not is_instance_valid(raw_detail_label):
			chat_status_detail_labels.remove_at(i)
		else:
			var detail_label = raw_detail_label as Label
			if detail_label == null:
				chat_status_detail_labels.remove_at(i)
				continue
			detail_label.text = detail_text

func _destroy_chat_overlay_shell() -> void:
	chat_overlay_shell_ready = false
	chat_overlay_list = null
	chat_overlay_notice = null
	chat_overlay_row_nodes.clear()
	chat_overlay_row_signatures.clear()
	chat_status_title_labels.clear()
	chat_status_detail_labels.clear()
	chat_message_edit = null
	chat_profile_button = null
	chat_overlay_scroll = null
	if chat_overlay_body == null or not is_instance_valid(chat_overlay_body):
		return
	for child in chat_overlay_body.get_children():
		chat_overlay_body.remove_child(child)
		child.queue_free()

func _ensure_chat_overlay_shell() -> void:
	if chat_overlay == null or chat_overlay_body == null:
		return
	if (
		chat_overlay_shell_ready
		and chat_overlay_list != null
		and is_instance_valid(chat_overlay_list)
		and chat_overlay_scroll != null
		and is_instance_valid(chat_overlay_scroll)
		and chat_message_edit != null
		and is_instance_valid(chat_message_edit)
	):
		return
	_destroy_chat_overlay_shell()
	chat_overlay_body.add_child(_chat_expanded_header())
	var scroll = MobileScrollContainer.new()
	chat_overlay_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.set_pull_resistance_enabled(false)
	chat_overlay_body.add_child(scroll)
	var list_margin = MarginContainer.new()
	var viewport_width = host.get_viewport_rect().size.x
	list_margin.custom_minimum_size = Vector2(viewport_width, 0)
	list_margin.add_theme_constant_override("margin_left", 32)
	list_margin.add_theme_constant_override("margin_right", 24)
	list_margin.add_theme_constant_override("margin_top", 29)
	list_margin.add_theme_constant_override("margin_bottom", 17)
	scroll.add_child(list_margin)
	var list = VBoxContainer.new()
	chat_overlay_list = list
	list.custom_minimum_size = Vector2(maxf(1.0, viewport_width - 112.0), 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	list_margin.add_child(list)
	chat_overlay_body.add_child(_chat_expanded_composer())
	chat_overlay_shell_ready = true

func _chat_overlay_row_signature(row_data: Dictionary) -> String:
	return "%s|%s|%s|%s|%s|%s|%s" % [
		str(row_data.get("text", "")),
		str(row_data.get("deleted", false)),
		str(row_data.get("name", "")),
		str(row_data.get("total_level", 0)),
		str(row_data.get("created_at", 0)),
		str(row_data.get("avatar_index", 0)),
		str(row_data.get("sender_id", "")),
	]

func _sync_chat_overlay_notice() -> void:
	if chat_overlay_list == null or not is_instance_valid(chat_overlay_list):
		return
	var should_show = _chat_expanded_notice_visible()
	if should_show:
		var fresh = _chat_expanded_notice()
		if chat_overlay_notice != null and is_instance_valid(chat_overlay_notice):
			var notice_index = chat_overlay_notice.get_index()
			chat_overlay_notice.queue_free()
			chat_overlay_list.add_child(fresh)
			chat_overlay_list.move_child(fresh, notice_index)
		else:
			chat_overlay_list.add_child(fresh)
			chat_overlay_list.move_child(fresh, 0)
		chat_overlay_notice = fresh
	elif chat_overlay_notice != null and is_instance_valid(chat_overlay_notice):
		chat_overlay_notice.queue_free()
		chat_overlay_notice = null

func _sync_chat_overlay_rows() -> void:
	if chat_overlay == null or not chat_overlay.visible or chat_overlay_list == null:
		return
	_sync_chat_overlay_notice()
	var row_start_index = 1 if chat_overlay_notice != null and is_instance_valid(chat_overlay_notice) else 0
	var desired_ids: Array[String] = []
	for raw_row in host._online_runtime().chat_rows:
		desired_ids.append(str((raw_row as Dictionary).get("message_id", "")))
	for raw_message_id in chat_overlay_row_nodes.keys():
		var message_id = str(raw_message_id)
		if message_id not in desired_ids:
			var stale = chat_overlay_row_nodes.get(message_id) as Control
			if stale != null and is_instance_valid(stale):
				stale.queue_free()
			chat_overlay_row_nodes.erase(message_id)
			chat_overlay_row_signatures.erase(message_id)
	for i in range(host._online_runtime().chat_rows.size()):
		var row_data = host._online_runtime().chat_rows[i] as Dictionary
		var message_id = str(row_data.get("message_id", ""))
		if message_id.is_empty():
			continue
		var target_index = row_start_index + i
		var signature = _chat_overlay_row_signature(row_data)
		var row_widget = chat_overlay_row_nodes.get(message_id) as Control
		if row_widget == null or not is_instance_valid(row_widget) or str(chat_overlay_row_signatures.get(message_id, "")) != signature:
			if row_widget != null and is_instance_valid(row_widget):
				row_widget.queue_free()
			row_widget = _chat_expanded_row(row_data)
			chat_overlay_list.add_child(row_widget)
			chat_overlay_row_nodes[message_id] = row_widget
			chat_overlay_row_signatures[message_id] = signature
		if row_widget.get_index() != target_index:
			chat_overlay_list.move_child(row_widget, target_index)

func _build_chat_strip() -> void:
	chat_strip = PanelContainer.new()
	chat_strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	chat_strip.offset_top = -NavigationShell.BOTTOM_NAV_HEIGHT - CHAT_STRIP_HEIGHT
	chat_strip.offset_bottom = -NavigationShell.BOTTOM_NAV_HEIGHT
	chat_strip.z_index = CHAT_UI_Z
	chat_strip.z_as_relative = false
	chat_strip.visible = false
	chat_strip.clip_contents = true
	chat_strip.mouse_filter = Control.MOUSE_FILTER_STOP
	chat_strip.add_theme_stylebox_override("panel", _chat_strip_style())
	chat_strip.gui_input.connect(_on_chat_strip_gui_input)
	host.add_child(chat_strip)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 23)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	chat_strip.add_child(margin)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	var icon_holder = Control.new()
	icon_holder.custom_minimum_size = Vector2(106.5, 106.5)
	icon_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_holder)
	var icon = host.visual_texture_cache._image(CHAT_STRIP_ICON, Vector2(106.5, 106.5))
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_holder.add_child(icon)
	chat_unread_dot = PanelContainer.new()
	chat_unread_dot.anchor_left = 1.0
	chat_unread_dot.anchor_right = 1.0
	chat_unread_dot.anchor_top = 0.0
	chat_unread_dot.anchor_bottom = 0.0
	chat_unread_dot.offset_left = -CHAT_UNREAD_DOT_DIAMETER - CHAT_UNREAD_DOT_EDGE_INSET
	chat_unread_dot.offset_right = -CHAT_UNREAD_DOT_EDGE_INSET
	chat_unread_dot.offset_top = CHAT_UNREAD_DOT_EDGE_INSET
	chat_unread_dot.offset_bottom = CHAT_UNREAD_DOT_EDGE_INSET + CHAT_UNREAD_DOT_DIAMETER
	chat_unread_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_unread_dot.visible = false
	chat_unread_dot.add_theme_stylebox_override("panel", chat_unread_dot_style())
	icon_holder.add_child(chat_unread_dot)
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	chat_strip_line_one = host._label("", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	chat_strip_line_one.add_theme_font_override("font", _chat_strip_font())
	chat_strip_line_one.add_theme_color_override("font_outline_color", Color("#9d9d9d"))
	chat_strip_line_one.add_theme_constant_override("outline_size", 2.5)
	chat_strip_line_one.autowrap_mode = TextServer.AUTOWRAP_OFF
	chat_strip_line_one.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chat_strip_line_one.clip_text = true
	chat_strip_line_one.custom_minimum_size = Vector2(0, 48)
	copy.add_child(chat_strip_line_one)
	chat_strip_line_two = host._label("", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	chat_strip_line_two.add_theme_font_override("font", _chat_strip_font())
	chat_strip_line_two.add_theme_color_override("font_outline_color", Color("#9d9d9d"))
	chat_strip_line_two.add_theme_constant_override("outline_size", 2.5)
	chat_strip_line_two.autowrap_mode = TextServer.AUTOWRAP_OFF
	chat_strip_line_two.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chat_strip_line_two.clip_text = true
	chat_strip_line_two.custom_minimum_size = Vector2(0, 48)
	copy.add_child(chat_strip_line_two)
	_update_chat_strip()

func _chat_strip_font() -> Font:
	if chat_strip_condensed_font != null:
		return chat_strip_condensed_font
	var base_font: Font = host.app_bold_font if host.app_bold_font != null else host.app_font
	if base_font == null:
		return ThemeDB.fallback_font
	var condensed := FontVariation.new()
	condensed.base_font = base_font
	condensed.variation_transform = Transform2D(Vector2(CHAT_STRIP_FONT_WIDTH_SCALE, 0.0), Vector2(0.0, 1.0), Vector2.ZERO)
	chat_strip_condensed_font = condensed
	return chat_strip_condensed_font

func _build_chat_overlay() -> void:
	chat_overlay_layer = CanvasLayer.new()
	chat_overlay_layer.layer = CHAT_OVERLAY_CANVAS_LAYER
	host.add_child(chat_overlay_layer)

	chat_overlay = ColorRect.new()
	chat_overlay.color = Color.WHITE
	chat_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	chat_overlay.z_index = host.MODAL_OVERLAY_Z
	chat_overlay.z_as_relative = false
	chat_overlay.visible = false
	chat_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	chat_overlay.add_to_group("modal_overlay")
	chat_overlay_layer.add_child(chat_overlay)
	chat_keyboard_fill = ColorRect.new()
	chat_keyboard_fill.color = host.COLOR_NAV
	chat_keyboard_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	chat_keyboard_fill.anchor_top = 1.0
	chat_keyboard_fill.offset_top = 0.0
	chat_keyboard_fill.offset_bottom = 0.0
	chat_keyboard_fill.visible = false
	chat_keyboard_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_overlay.add_child(chat_keyboard_fill)
	chat_overlay_body = VBoxContainer.new()
	chat_overlay_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	chat_overlay_body.add_theme_constant_override("separation", 0)
	chat_overlay.add_child(chat_overlay_body)
	chat_keyboard_preview = PanelContainer.new()
	chat_keyboard_preview.anchor_left = 0.0
	chat_keyboard_preview.anchor_right = 1.0
	chat_keyboard_preview.anchor_top = 1.0
	chat_keyboard_preview.anchor_bottom = 1.0
	chat_keyboard_preview.offset_left = 23.0
	chat_keyboard_preview.offset_right = -23.0
	chat_keyboard_preview.offset_top = -CHAT_KEYBOARD_PREVIEW_HEIGHT
	chat_keyboard_preview.offset_bottom = 0.0
	chat_keyboard_preview.z_index = host.MODAL_OVERLAY_Z
	chat_keyboard_preview.visible = false
	chat_keyboard_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_keyboard_preview.add_theme_stylebox_override("panel", _chat_keyboard_preview_style(host.COLOR_BLUE))
	chat_overlay.add_child(chat_keyboard_preview)
	chat_keyboard_preview_label = host._label("", 48, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	chat_keyboard_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chat_keyboard_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chat_keyboard_preview_label.clip_text = true
	chat_keyboard_preview_label.custom_minimum_size = Vector2(0, CHAT_KEYBOARD_PREVIEW_HEIGHT - 34)
	chat_keyboard_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_keyboard_preview.add_child(chat_keyboard_preview_label)

func _on_chat_strip_gui_input(event: InputEvent) -> void:
	if chat_overlay != null and chat_overlay.visible:
		return
	if host._skill_detail_surface()._event_points_inside_detail_jump_arrow(event, chat_strip):
		chat_strip.accept_event()
		return
	if host._achievement_toast_surface()._event_points_inside_achievement_toast(event, chat_strip):
		chat_strip.accept_event()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_chat_overlay()
		chat_strip.accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_open_chat_overlay()
		chat_strip.accept_event()

func _route_chat_strip_input(event: InputEvent) -> bool:
	if chat_overlay != null and chat_overlay.visible:
		return false
	if chat_strip == null or not is_instance_valid(chat_strip) or not chat_strip.visible:
		return false
	if host._skill_detail_surface()._event_points_inside_detail_jump_arrow(event):
		return false
	if host._achievement_toast_surface()._event_points_inside_achievement_toast(event):
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if chat_strip.get_global_rect().has_point(event.global_position):
			_open_chat_overlay()
			return true
	if event is InputEventScreenTouch and event.pressed:
		if chat_strip.get_global_rect().has_point(event.position):
			_open_chat_overlay()
			return true
	return false

func _position_inside_chat_strip_interactive_ui(event_position: Vector2) -> bool:
	if chat_strip == null or not is_instance_valid(chat_strip) or not chat_strip.is_visible_in_tree():
		return false
	return chat_strip.get_global_rect().grow(4.0).has_point(event_position)

func _open_chat_overlay() -> void:
	host.button_press_runtime.play_default_button_sfx()
	_ensure_chat_overlay()
	if chat_overlay == null or not _chat_strip_visible_on_current_screen():
		return
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_overlay, true)
	chat_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host._online_runtime()._chat_stream_connect()
	host._online_runtime()._start_chat_stream_poll_timer()
	_ensure_chat_overlay_shell()
	_sync_chat_overlay_rows()
	host._online_runtime().mark_chat_opened_to_latest(true)
	_chat_scroll_to_latest_deferred()

func _close_chat_overlay(play_sfx := true) -> void:
	if play_sfx:
		host.button_press_runtime.play_default_button_sfx()
	if chat_overlay != null and chat_overlay.visible:
		host._online_runtime().mark_chat_opened_to_latest(true)
	if chat_overlay != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_overlay, false)
	_reset_chat_keyboard_lift()
	if chat_overlay_body != null and is_instance_valid(chat_overlay_body):
		chat_overlay_body.offset_bottom = 0.0
	if chat_keyboard_fill != null and is_instance_valid(chat_keyboard_fill):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_keyboard_fill, false)
		chat_keyboard_fill.offset_top = 0.0
	_hide_chat_keyboard_preview()
	if _chat_strip_visible_on_current_screen():
		_update_chat_strip()

func _chat_expanded_header() -> Control:
	var header = Control.new()
	header.custom_minimum_size = Vector2(0, 165)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var shelf = ColorRect.new()
	shelf.color = host._theme_paper_color()
	shelf.set_anchors_preset(Control.PRESET_FULL_RECT)
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(shelf)
	var top = MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.add_theme_constant_override("margin_left", 32)
	top.add_theme_constant_override("margin_right", 32)
	top.add_theme_constant_override("margin_top", 28)
	top.add_theme_constant_override("margin_bottom", 32)
	header.add_child(top)
	var tabs = HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_theme_constant_override("separation", 23)
	top.add_child(tabs)
	tabs.add_child(_chat_profile_button())
	var world = PanelContainer.new()
	world.custom_minimum_size = Vector2(390, 68)
	world.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	world.add_theme_stylebox_override("panel", _chat_world_tab_style(host.COLOR_INK))
	tabs.add_child(world)
	var world_label = host._label("Global Chat", 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	world_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	world.add_child(world_label)
	host._skill_detail_surface()._add_skill_detail_shadow_overlay_to(header, 165.0, 1.0, 211.0, "ChatExpandedHeaderShelfShadow", 0)
	return header

func _chat_expanded_notice_visible() -> bool:
	return _chat_status_actionable() or host._online_runtime().chat_rows.is_empty()

func _chat_status_actionable() -> bool:
	return not host._online_runtime().chat_status_message.is_empty() and host._online_runtime().chat_status_message != "Chat loaded." and host._online_runtime().chat_status_message != "Global chat is live."

func _chat_expanded_notice() -> Control:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", host._surface_style(Color("#e8f6ff"), 15, 14, false))
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 13)
	panel.add_child(row)
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 4)
	row.add_child(copy)
	var title = host._label(_chat_status_title(), 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(title)
	var detail = host._label(_chat_status_detail(), host.MIN_MOBILE_HELP_FONT_SIZE, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(0, 48)
	copy.add_child(detail)
	_track_chat_status_labels(title, detail)
	return panel

func _chat_expanded_row(row_data: Dictionary) -> Control:
	var deleted = bool(row_data.get("deleted", false))
	var is_self = str(row_data.get("sender_id", "")) == host.leaderboard_profile.player_id
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size = Vector2(0, 130)
	row.add_child(profile_avatar_frame(int(row_data.get("avatar_index", 0)), Vector2(94, 94), is_self))
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	var meta = HBoxContainer.new()
	meta.add_theme_constant_override("separation", 6)
	copy.add_child(meta)
	var name_text = _chat_sender_label(row_data)
	var name_color = Color("#57b8ff") if is_self else Color("#ffc94a")
	var player_name_label = host._label(name_text, 48, name_color, HORIZONTAL_ALIGNMENT_LEFT)
	var name_settings = LabelSettings.new()
	if host.app_bold_font != null:
		name_settings.font = host.app_bold_font
	elif host.app_font != null:
		name_settings.font = host.app_font
	name_settings.font_size = 48
	name_settings.font_color = name_color
	name_settings.outline_color = Color.BLACK
	name_settings.outline_size = 15
	player_name_label.label_settings = name_settings
	player_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_margin = MarginContainer.new()
	name_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_margin.add_theme_constant_override("margin_left", 17)
	name_margin.add_theme_constant_override("margin_top", 0)
	name_margin.add_theme_constant_override("margin_bottom", 0)
	name_margin.add_child(player_name_label)
	meta.add_child(name_margin)
	var time = host._label(_chat_time_text(row_data), 48, Color("#a7a7a7"), HORIZONTAL_ALIGNMENT_RIGHT)
	time.custom_minimum_size = Vector2(105, 0)
	meta.add_child(time)
	var bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _chat_expanded_message_style(deleted, is_self))
	copy.add_child(bubble)
	var body_text = "Message removed by moderator." if deleted else str(row_data.get("text", ""))
	var body = host._label(body_text, 48, Color("#080808") if not deleted else Color("#6c625a"), HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0, 56)
	bubble.add_child(body)
	return row

func _chat_time_text(row_data: Dictionary) -> String:
	var created := maxi(0, int(row_data.get("created_at_unix", 0)))
	if created <= 0:
		return ""
	var timestamp := _chat_central_datetime_from_unix_time(created)
	return "%02d:%02d" % [int(timestamp.get("hour", 0)), int(timestamp.get("minute", 0))]

func _chat_central_datetime_from_unix_time(unix_time: int) -> Dictionary:
	var offset_seconds := -5 * 60 * 60 if _chat_central_daylight_time_active(unix_time) else -6 * 60 * 60
	return Time.get_datetime_dict_from_unix_time(unix_time + offset_seconds)

func _chat_central_daylight_time_active(unix_time: int) -> bool:
	var utc := Time.get_datetime_dict_from_unix_time(unix_time)
	var year := int(utc.get("year", 1970))
	var dst_start_utc := _chat_central_dst_transition_utc(year, 3, 2, 2, -6)
	var dst_end_utc := _chat_central_dst_transition_utc(year, 11, 1, 2, -5)
	return unix_time >= dst_start_utc and unix_time < dst_end_utc

func _chat_central_dst_transition_utc(year: int, month: int, sunday_ordinal: int, local_hour: int, offset_hours_before_transition: int) -> int:
	var day := _chat_nth_sunday_day_of_month(year, month, sunday_ordinal)
	var local_unix := Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": local_hour,
		"minute": 0,
		"second": 0
	})
	return int(local_unix) - offset_hours_before_transition * 60 * 60

func _chat_nth_sunday_day_of_month(year: int, month: int, sunday_ordinal: int) -> int:
	var first_day_unix := Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	})
	var first_day := Time.get_datetime_dict_from_unix_time(first_day_unix)
	var first_weekday := int(first_day.get("weekday", 0))
	var first_sunday := 1 if first_weekday == 0 else 8 - first_weekday
	return first_sunday + (maxi(1, sunday_ordinal) - 1) * 7

func _chat_expanded_composer() -> Control:
	var stack = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 0)
	var bar = PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, CHAT_STRIP_HEIGHT)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("panel", _chat_strip_style())
	stack.add_child(bar)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	bar.add_child(margin)
	var column = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 17)
	column.add_child(row)
	var back = host._menu_button("<")
	back.custom_minimum_size = Vector2(77, 77)
	back.add_theme_font_size_override("font_size", 48)
	back.add_theme_stylebox_override("normal", _chat_back_button_style(false, host.COLOR_INK))
	back.add_theme_stylebox_override("hover", _chat_back_button_style(false, host.COLOR_INK))
	back.add_theme_stylebox_override("pressed", _chat_back_button_style(true, host.COLOR_INK))
	back.pressed.connect(_close_chat_overlay)
	row.add_child(back)
	chat_message_edit = LineEdit.new()
	chat_message_edit.placeholder_text = "Send a message..."
	chat_message_edit.max_length = host.CHAT_MESSAGE_MAX_CHARS
	chat_message_edit.custom_minimum_size = Vector2(0, 77)
	chat_message_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_message_edit.focus_mode = Control.FOCUS_ALL
	chat_message_edit.add_theme_font_size_override("font_size", 48)
	if host.app_bold_font != null:
		chat_message_edit.add_theme_font_override("font", host.app_bold_font)
	elif host.app_font != null:
		chat_message_edit.add_theme_font_override("font", host.app_font)
	chat_message_edit.add_theme_color_override("font_color", host.COLOR_INK)
	chat_message_edit.add_theme_color_override("font_placeholder_color", Color("#b9b9b9"))
	chat_message_edit.add_theme_color_override("caret_color", host.COLOR_INK)
	chat_message_edit.add_theme_constant_override("caret_width", 8)
	chat_message_edit.set("caret_blink", true)
	chat_message_edit.set("caret_blink_interval", 0.42)
	chat_message_edit.add_theme_stylebox_override("normal", _chat_input_style(false, host.COLOR_INK, host.COLOR_BLUE))
	chat_message_edit.add_theme_stylebox_override("focus", _chat_input_style(true, host.COLOR_INK, host.COLOR_BLUE))
	chat_message_edit.text = chat_draft_message
	chat_message_edit.text_changed.connect(_on_chat_draft_changed)
	chat_message_edit.gui_input.connect(_on_chat_input_gui_input)
	chat_message_edit.focus_entered.connect(_on_chat_input_focus_entered)
	chat_message_edit.focus_exited.connect(_on_chat_input_focus_exited)
	chat_message_edit.text_submitted.connect(_chat_text_submitted)
	chat_message_edit.editable = host._online_runtime()._leaderboard_firebase_enabled()
	row.add_child(chat_message_edit)
	var send_button = _chat_send_button()
	row.add_child(send_button)
	var ribbon_frame = Control.new()
	ribbon_frame.custom_minimum_size = Vector2(0, NavigationShell.BOTTOM_NAV_HEIGHT)
	ribbon_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ribbon_frame.clip_contents = true
	stack.add_child(ribbon_frame)
	var navigation_shell = host._navigation_shell()
	var ribbon = PanelContainer.new()
	ribbon.set_anchors_preset(Control.PRESET_FULL_RECT)
	ribbon.add_theme_stylebox_override("panel", navigation_shell._nav_style())
	ribbon_frame.add_child(ribbon)
	var ribbon_row = HBoxContainer.new()
	ribbon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ribbon_row.add_theme_constant_override("separation", 60)
	ribbon_row.clip_contents = true
	ribbon_row.custom_minimum_size = Vector2(0, NavigationShell.BOTTOM_NAV_HEIGHT - NavigationShell.BOTTOM_NAV_SAFE_PAD)
	ribbon.add_child(ribbon_row)
	navigation_shell.chat_home_tab = navigation_shell._nav_button(host.PROGRESS_STAR_ICON_TEXTURE)
	navigation_shell.chat_home_tab.custom_minimum_size = Vector2(159, 159)
	navigation_shell.chat_home_tab.add_theme_constant_override("icon_max_width", 122)
	navigation_shell._register_nav_new_symbol_dot(navigation_shell.chat_home_tab, "hero")
	navigation_shell.chat_home_tab.modulate = Color.WHITE if host._navigation_shell()._hero_unlocked() else NavigationShell.HUB_NAV_LOCKED_MODULATE
	navigation_shell.chat_home_tab.tooltip_text = ""
	navigation_shell.chat_home_tab.pressed.connect(_on_chat_home_nav_pressed)
	ribbon_row.add_child(navigation_shell.chat_home_tab)
	navigation_shell.chat_hub_tab = navigation_shell._nav_button("res://assets/content/hub/hub-nav-barn.png")
	navigation_shell.chat_hub_tab.add_theme_constant_override("icon_max_width", 110)
	navigation_shell._register_nav_new_symbol_dot(navigation_shell.chat_hub_tab, "hub")
	navigation_shell.chat_hub_tab.modulate = Color.WHITE if host._navigation_shell()._hub_unlocked() else NavigationShell.HUB_NAV_LOCKED_MODULATE
	navigation_shell.chat_hub_tab.tooltip_text = ""
	navigation_shell.chat_hub_tab.pressed.connect(_on_chat_hub_nav_pressed)
	ribbon_row.add_child(navigation_shell.chat_hub_tab)
	var chat_skills = navigation_shell._nav_button(host.TOTAL_LEVEL_BARGRAPH_TEXTURE)
	chat_skills.pressed.connect(_on_chat_skills_nav_pressed)
	ribbon_row.add_child(chat_skills)
	var chat_settings = navigation_shell._nav_button(host.SETTINGS_GEAR_ICON_TEXTURE)
	chat_settings.pressed.connect(_on_chat_settings_nav_pressed)
	ribbon_row.add_child(chat_settings)
	navigation_shell.chat_shop_tab = navigation_shell._nav_button(host.SHOP_ICON_TEXTURE)
	navigation_shell.chat_shop_tab.add_theme_constant_override("icon_max_width", 116)
	navigation_shell._register_nav_new_symbol_dot(navigation_shell.chat_shop_tab, "shop")
	navigation_shell.chat_shop_tab.modulate = Color.WHITE if host._navigation_shell()._shop_unlocked() else NavigationShell.HUB_NAV_LOCKED_MODULATE
	navigation_shell.chat_shop_tab.tooltip_text = ""
	navigation_shell.chat_shop_tab.pressed.connect(_on_chat_shop_nav_pressed)
	ribbon_row.add_child(navigation_shell.chat_shop_tab)
	return stack

func _on_chat_home_nav_pressed() -> void:
	_close_chat_overlay(false)
	var navigation_shell: NavigationShell = host._navigation_shell()
	navigation_shell._show_home(navigation_shell.chat_home_tab)


func _on_chat_hub_nav_pressed() -> void:
	_close_chat_overlay(false)
	var navigation_shell: NavigationShell = host._navigation_shell()
	navigation_shell._show_hub(navigation_shell.chat_hub_tab)


func _on_chat_skills_nav_pressed() -> void:
	_close_chat_overlay(false)
	host._navigation_shell()._show_skills_module()


func _on_chat_settings_nav_pressed() -> void:
	_close_chat_overlay(false)
	host._settings_surface()._show_settings()


func _on_chat_shop_nav_pressed() -> void:
	_close_chat_overlay(false)
	var navigation_shell: NavigationShell = host._navigation_shell()
	navigation_shell._show_shop(navigation_shell.chat_shop_tab)


func _update_chat_strip(force_visibility := false) -> void:
	if not _global_chat_allowed():
		if host._online_runtime().chat_stream_connected or host._online_runtime().chat_stream_connecting or host._online_runtime().chat_stream_request_sent:
			host._online_runtime()._chat_stream_disconnect(false)
		if chat_strip != null and is_instance_valid(chat_strip):
			host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_strip, false)
			chat_strip_last_visible = false
		if chat_unread_dot != null and is_instance_valid(chat_unread_dot):
			host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_unread_dot, false)
		return
	if chat_strip == null or not is_instance_valid(chat_strip):
		if _chat_strip_visible_on_current_screen() or force_visibility:
			_ensure_chat_strip()
		if chat_strip == null or not is_instance_valid(chat_strip):
			return
	var should_show_chat_strip := _chat_strip_committed_visible(force_visibility)
	if chat_strip_last_visible != should_show_chat_strip:
		chat_strip_last_visible = should_show_chat_strip
		if should_show_chat_strip:
			host._online_runtime()._chat_stream_connect()
		else:
			host._online_runtime()._chat_stream_disconnect(false)
	elif should_show_chat_strip and (host._online_runtime().chat_stream_connecting or host._online_runtime().chat_stream_request_sent) and not host._online_runtime().chat_stream_connected:
		host._online_runtime()._start_chat_stream_poll_timer()
	_sync_chat_unread_dot()
	if chat_strip_line_one == null or chat_strip_line_two == null:
		return
	var lines := _chat_strip_lines()
	var line_one := str(lines[0])
	var line_two := str(lines[1])
	if chat_strip_last_line_one != line_one:
		chat_strip_last_line_one = line_one
		host._app_lifecycle_runtime().set_label_text_if_changed(chat_strip_line_one, line_one)
	if chat_strip_last_line_two != line_two:
		chat_strip_last_line_two = line_two
		host._app_lifecycle_runtime().set_label_text_if_changed(chat_strip_line_two, line_two)

func _chat_strip_committed_visible(force_visibility := false) -> bool:
	var target_visible: bool = _chat_strip_visible_on_current_screen()
	var now := Time.get_ticks_msec()
	if target_visible:
		chat_strip_hide_started_msec = 0
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_strip, true)
		return true
	if force_visibility:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_strip, false)
		chat_strip_hide_started_msec = 0
		return false
	if chat_strip.visible:
		if chat_strip_hide_started_msec <= 0:
			chat_strip_hide_started_msec = now
			return true
		if now - chat_strip_hide_started_msec < CHAT_STRIP_HIDE_GRACE_MSEC:
			return true
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_strip, false)
		chat_strip_hide_started_msec = 0
	return false

func _chat_strip_lines() -> Array:
	var messages: Array = []
	for raw_row in host._online_runtime().chat_rows:
		var row := raw_row as Dictionary
		if bool(row.get("deleted", false)):
			messages.append("mod: message removed")
		else:
			var display_name: String = _chat_sender_name(row)
			var text: String = ChatState.sanitize_message(str(row.get("text", "")), host.CHAT_MESSAGE_MAX_CHARS, host.CHAT_CENSORED_WORDS)
			if text.is_empty():
				continue
			messages.append("%s: %s" % [display_name, text])
	if messages.size() >= 2:
		return _chat_strip_remember_lines(messages[messages.size() - 2], messages[messages.size() - 1])
	if messages.size() == 1:
		return _chat_strip_remember_lines("Global Chat", messages[0])
	if not chat_strip_stable_line_two.is_empty() and _chat_strip_should_hold_empty_state():
		return [chat_strip_stable_line_one, chat_strip_stable_line_two]
	chat_strip_stable_line_one = ""
	chat_strip_stable_line_two = ""
	chat_strip_empty_started_msec = 0
	if not host._online_runtime()._leaderboard_firebase_enabled():
		return ["Global Chat", "Tap to open chat."]
	return ["Global Chat", "Tap to open chat."]

func _chat_strip_remember_lines(line_one: String, line_two: String) -> Array:
	chat_strip_stable_line_one = line_one
	chat_strip_stable_line_two = line_two
	chat_strip_empty_started_msec = 0
	return [line_one, line_two]

func _chat_strip_should_hold_empty_state() -> bool:
	if not (host._online_runtime().chat_stream_connecting or host._online_runtime().chat_stream_request_sent or host._online_runtime().chat_stream_retry_unix > host._unix_now()):
		return false
	var now := Time.get_ticks_msec()
	if chat_strip_empty_started_msec <= 0:
		chat_strip_empty_started_msec = now
	return now - chat_strip_empty_started_msec <= CHAT_STRIP_EMPTY_GRACE_MSEC

func _chat_profile_button_text() -> String:
	if LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS):
		return LeaderboardProfile.sanitize_display_name(host.leaderboard_profile.display_name, host.PROFILE_DISPLAY_NAME_MAX_CHARS)
	return "Claim Name"

func _chat_profile_button() -> Button:
	var button: Button = host._menu_button(_chat_profile_button_text())
	chat_profile_button = button
	button.custom_minimum_size = Vector2(360, 68)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 48)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(open_profile_overlay)
	return button

func _refresh_chat_profile_button() -> void:
	if chat_profile_button != null and is_instance_valid(chat_profile_button):
		chat_profile_button.text = _chat_profile_button_text()

func _chat_row_total_level(row_data: Dictionary) -> int:
	var total_level := maxi(0, int(row_data.get("total_level", 0)))
	if total_level <= 0 and str(row_data.get("sender_id", "")) == host.leaderboard_profile.player_id:
		total_level = SkillState.global_level(host.skills)
	return total_level

func _chat_sender_name(row_data: Dictionary) -> String:
	var name_text: String = LeaderboardProfile.sanitize_display_name(str(row_data.get("name", "Player")), host.PROFILE_DISPLAY_NAME_MAX_CHARS)
	if name_text.is_empty():
		name_text = "Player"
	return name_text

func _chat_sender_label(row_data: Dictionary) -> String:
	var name_text := _chat_sender_name(row_data)
	var total_level := _chat_row_total_level(row_data)
	if total_level > 0:
		return "%s - %s" % [name_text, total_level]
	return name_text

func _chat_status_title() -> String:
	if not host._online_runtime()._leaderboard_firebase_enabled():
		return "Online chat unavailable"
	if host._online_runtime().chat_send_in_flight:
		return "Sending..."
	if host._online_runtime().chat_stream_connecting:
		return "Connecting..."
	if host._online_runtime().chat_stream_connected:
		return "Real-time chat live"
	if host._online_runtime().leaderboard_auth_in_flight:
		return "Chat send login starting"
	var auth_wait: int = host._online_runtime()._leaderboard_auth_retry_wait_seconds()
	if auth_wait > 0:
		return "Chat send login cooling down"
	if not host._online_runtime()._leaderboard_auth_ready():
		return "Chat read ready"
	var wait: int = host._online_runtime()._chat_next_send_seconds()
	if wait > 0:
		return "Next message in %s" % GameFormatting.duration(float(wait))
	return "Live chat ready"

func _chat_status_detail() -> String:
	if not host._online_runtime()._leaderboard_firebase_enabled():
		return "Online chat is not connected yet."
	if not host._online_runtime().chat_status_message.is_empty() and host._online_runtime().chat_status_message != "Chat loaded.":
		return host._online_runtime().chat_status_message
	if host._online_runtime().chat_stream_connected:
		return "One live chat connection is open here, capped to %s recent messages." % host._online_runtime()._chat_target_visible_count()
	var wait := maxi(0, host._online_runtime().chat_stream_retry_unix - host._unix_now())
	if wait > 0:
		return "The chat stream is cooling down for %s before reconnecting." % GameFormatting.duration(float(wait))
	var auth_wait: int = host._online_runtime()._leaderboard_auth_retry_wait_seconds()
	if auth_wait > 0:
		return "Messages can load without login. Sending waits %s before retrying online login." % GameFormatting.duration(float(auth_wait))
	if host._online_runtime().leaderboard_auth_in_flight:
		return "Messages can load while online send login starts."
	if not host._online_runtime()._leaderboard_auth_ready():
		return "Messages can load without login. Sending starts anonymous online login first."
	return "The skills chat strip opens one live chat connection while it is visible."

func _on_chat_draft_changed(text: String) -> void:
	chat_draft_message = text
	chat_keyboard_close_submit_done = false
	_update_chat_keyboard_preview()

func _on_chat_input_focus_entered() -> void:
	chat_keyboard_lift_active = true
	chat_keyboard_focus_active = true
	chat_keyboard_lift_hold_seconds = 0.9
	chat_keyboard_lift_zero_seconds = 0.0
	chat_keyboard_was_visible = false
	chat_keyboard_close_submit_done = false
	chat_keyboard_lift_viewport_height = maxf(chat_keyboard_lift_viewport_height, host.get_viewport_rect().size.y)
	_process_chat_keyboard_lift(1.0)

func _on_chat_input_focus_exited() -> void:
	var should_submit_web_keyboard_done := _chat_web_mobile_keyboard_platform() and _chat_keyboard_done_submit_ready()
	chat_keyboard_focus_active = false
	chat_keyboard_preview_keyboard_visible = false
	_hide_chat_keyboard_preview()
	if should_submit_web_keyboard_done:
		call_deferred("_chat_submit_web_keyboard_done")
	if _chat_mobile_keyboard_platform():
		chat_keyboard_lift_hold_seconds = 0.20
		return
	_reset_chat_keyboard_lift()

func _reset_chat_keyboard_lift() -> void:
	chat_keyboard_lift_active = false
	chat_keyboard_lift_pixels = 0.0
	chat_keyboard_lift_hold_seconds = 0.0
	chat_keyboard_lift_last_height = 0.0
	chat_keyboard_lift_target_pixels = 0.0
	chat_keyboard_lift_viewport_height = 0.0
	chat_keyboard_lift_window_height = 0.0
	chat_keyboard_lift_zero_seconds = 0.0
	chat_keyboard_preview_keyboard_visible = false
	chat_keyboard_was_visible = false
	chat_keyboard_close_submit_done = false
	chat_keyboard_focus_active = false
	_hide_chat_keyboard_preview()

func _collapse_chat_keyboard_lift_after_submit() -> void:
	chat_keyboard_lift_active = false
	chat_keyboard_focus_active = false
	chat_keyboard_lift_hold_seconds = 0.0
	chat_keyboard_lift_last_height = 0.0
	chat_keyboard_lift_target_pixels = 0.0
	chat_keyboard_lift_zero_seconds = 0.0
	chat_keyboard_preview_keyboard_visible = false
	chat_keyboard_close_submit_done = true
	_hide_chat_keyboard_preview()

func _chat_keyboard_height_canvas_units(raw_keyboard_height: float) -> float:
	var viewport_height := maxf(1.0, host.get_viewport_rect().size.y)
	var window_height := viewport_height
	if DisplayServer.get_name() != "headless":
		window_height = maxf(1.0, float(DisplayServer.window_get_size().y))
	chat_keyboard_lift_viewport_height = maxf(chat_keyboard_lift_viewport_height, viewport_height)
	chat_keyboard_lift_window_height = maxf(chat_keyboard_lift_window_height, window_height)
	var height_from_keyboard := 0.0
	if raw_keyboard_height > 0.0:
		height_from_keyboard = raw_keyboard_height * viewport_height / maxf(1.0, chat_keyboard_lift_window_height)
	var height_from_resize := 0.0
	if chat_keyboard_lift_window_height > window_height + 1.0:
		height_from_resize = (chat_keyboard_lift_window_height - window_height) * viewport_height / maxf(1.0, chat_keyboard_lift_window_height)
	return maxf(height_from_keyboard, height_from_resize)

func _update_chat_keyboard_preview() -> void:
	if chat_keyboard_preview == null or not is_instance_valid(chat_keyboard_preview):
		return
	if chat_keyboard_preview_label == null or not is_instance_valid(chat_keyboard_preview_label):
		return
	var should_show: bool = chat_overlay != null and chat_overlay.visible and _chat_mobile_keyboard_platform() and chat_keyboard_preview_keyboard_visible
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_keyboard_preview, should_show)
	if not should_show:
		return
	var preview_text: String = chat_draft_message.strip_edges()
	if preview_text.is_empty():
		chat_keyboard_preview_label.text = "Send a message..."
		chat_keyboard_preview_label.add_theme_color_override("font_color", Color("#8a8175"))
	else:
		chat_keyboard_preview_label.text = chat_draft_message
		chat_keyboard_preview_label.add_theme_color_override("font_color", host.COLOR_INK)
	chat_keyboard_preview.offset_top = -chat_keyboard_lift_pixels - CHAT_KEYBOARD_PREVIEW_HEIGHT - 22.0
	chat_keyboard_preview.offset_bottom = -chat_keyboard_lift_pixels - 22.0

func _hide_chat_keyboard_preview() -> void:
	if chat_keyboard_preview != null and is_instance_valid(chat_keyboard_preview):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_keyboard_preview, false)

func _process_chat_keyboard_lift(delta: float) -> void:
	if chat_overlay_body == null or not is_instance_valid(chat_overlay_body):
		return
	var target := 0.0
	var is_mobile_keyboard := _chat_mobile_keyboard_platform()
	var raw_keyboard_height := 0.0
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		raw_keyboard_height = float(DisplayServer.virtual_keyboard_get_height())
		if raw_keyboard_height > 0.0:
			chat_keyboard_lift_active = true
			chat_keyboard_lift_zero_seconds = 0.0
			chat_keyboard_was_visible = true
		else:
			chat_keyboard_preview_keyboard_visible = false
			_hide_chat_keyboard_preview()
			chat_keyboard_lift_zero_seconds += delta
			if not chat_keyboard_focus_active and chat_keyboard_lift_zero_seconds > 0.85:
				chat_keyboard_lift_active = false
	if chat_overlay != null and chat_overlay.visible and is_mobile_keyboard and (chat_keyboard_focus_active or chat_keyboard_lift_active or raw_keyboard_height > 0.0 or chat_keyboard_lift_hold_seconds > 0.0):
		var viewport_height := maxf(chat_keyboard_lift_viewport_height, host.get_viewport_rect().size.y)
		var keyboard_height := _chat_keyboard_height_canvas_units(raw_keyboard_height)
		chat_keyboard_preview_keyboard_visible = keyboard_height > 1.0
		if keyboard_height > 0.0:
			chat_keyboard_lift_last_height = keyboard_height
			chat_keyboard_lift_hold_seconds = 0.9
		elif chat_keyboard_lift_hold_seconds > 0.0:
			chat_keyboard_lift_hold_seconds = maxf(0.0, chat_keyboard_lift_hold_seconds - delta)
			keyboard_height = chat_keyboard_lift_last_height * clampf(chat_keyboard_lift_hold_seconds / 0.20, 0.0, 1.0)
		if keyboard_height > 0.0:
			chat_keyboard_lift_target_pixels = clampf(keyboard_height - NavigationShell.BOTTOM_NAV_HEIGHT + 128.0, 0.0, viewport_height * 0.72)
		else:
			chat_keyboard_lift_target_pixels = 0.0
		target = chat_keyboard_lift_target_pixels
	else:
		chat_keyboard_preview_keyboard_visible = false
		_reset_chat_keyboard_lift()
	var t := clampf(delta * 12.0, 0.0, 1.0)
	chat_keyboard_lift_pixels = lerpf(chat_keyboard_lift_pixels, target, t)
	if absf(chat_keyboard_lift_pixels - target) < 1.0:
		chat_keyboard_lift_pixels = target
	chat_overlay_body.offset_bottom = -chat_keyboard_lift_pixels
	if chat_keyboard_fill != null and is_instance_valid(chat_keyboard_fill):
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(chat_keyboard_fill, chat_keyboard_lift_pixels > 1.0)
		chat_keyboard_fill.offset_top = -chat_keyboard_lift_pixels - 8.0
	_update_chat_keyboard_preview()
	if chat_keyboard_focus_active:
		_chat_scroll_to_latest()

func _chat_scroll_to_latest_deferred(attempts_remaining := 4) -> void:
	call_deferred("_chat_scroll_to_latest_after_frame", attempts_remaining)

func _chat_scroll_to_latest_after_frame(attempts_remaining := 0) -> void:
	await host.get_tree().process_frame
	_chat_scroll_to_latest(attempts_remaining)

func _chat_scroll_to_latest(attempts_remaining := 0) -> void:
	if chat_overlay_scroll == null or not is_instance_valid(chat_overlay_scroll):
		if attempts_remaining > 0:
			call_deferred("_chat_scroll_to_latest_after_frame", attempts_remaining - 1)
		return
	chat_overlay_scroll.scroll_vertical = chat_overlay_scroll.get_max_scroll_vertical()
	if attempts_remaining > 0:
		call_deferred("_chat_scroll_to_latest_after_frame", attempts_remaining - 1)

func _route_chat_overlay_key_input(event: InputEvent) -> bool:
	if chat_overlay == null or not chat_overlay.visible:
		return false
	if _chat_mobile_keyboard_platform() and not _chat_submit_event_pressed(event):
		return false
	if _chat_submit_event_pressed(event):
		_chat_submit_current_draft()
		return true
	return false

func _on_chat_input_gui_input(event: InputEvent) -> void:
	if _chat_submit_event_pressed(event):
		if chat_message_edit != null and is_instance_valid(chat_message_edit):
			chat_message_edit.accept_event()
		_chat_submit_current_draft()

func _chat_submit_key_pressed(key: InputEventKey) -> bool:
	if key == null or not key.pressed or key.echo:
		return false
	return (
		key.keycode == KEY_ENTER
		or key.keycode == KEY_KP_ENTER
		or key.physical_keycode == KEY_ENTER
		or key.physical_keycode == KEY_KP_ENTER
		or key.key_label == KEY_ENTER
		or key.key_label == KEY_KP_ENTER
	)

func _chat_submit_event_pressed(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key := event as InputEventKey
	return _chat_submit_key_pressed(key)

func _chat_input_has_focus() -> bool:
	return chat_message_edit != null and is_instance_valid(chat_message_edit) and chat_message_edit.has_focus() and chat_message_edit.is_visible_in_tree()

func _process_chat_enter_submit_poll() -> void:
	if not _chat_input_has_focus():
		chat_enter_submit_armed = true
		return
	var enter_down: bool = Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	if not enter_down:
		chat_enter_submit_armed = true
		return
	if not chat_enter_submit_armed:
		return
	chat_enter_submit_armed = false
	_chat_submit_current_draft()

func _chat_submit_current_draft() -> void:
	var text: String = chat_draft_message
	if chat_message_edit != null and is_instance_valid(chat_message_edit):
		text = chat_message_edit.text
	_chat_send_pressed(text)
	_chat_finish_mobile_submit_attempt()

func _chat_queue_submit_current_draft() -> void:
	if chat_submit_deferred:
		return
	chat_submit_deferred = true
	call_deferred("_chat_submit_current_draft_deferred")

func _chat_submit_current_draft_deferred() -> void:
	chat_submit_deferred = false
	_chat_submit_current_draft()

func _chat_text_submitted(text: String) -> void:
	_chat_send_pressed(text)
	_chat_finish_mobile_submit_attempt()

func _chat_mobile_keyboard_platform() -> bool:
	return OS.get_name() == "Android" or OS.get_name() == "iOS" or _chat_web_mobile_keyboard_platform()

func _chat_web_mobile_keyboard_platform() -> bool:
	if not OS.has_feature("web"):
		return false
	return DisplayServer.is_touchscreen_available()

func _chat_keyboard_done_submit_ready() -> bool:
	if chat_keyboard_close_submit_done or host._online_runtime().chat_send_in_flight:
		return false
	var text: String = chat_draft_message
	if chat_message_edit != null and is_instance_valid(chat_message_edit):
		text = chat_message_edit.text
	return not ChatState.sanitize_message(text, host.CHAT_MESSAGE_MAX_CHARS, host.CHAT_CENSORED_WORDS).is_empty()

func _chat_submit_web_keyboard_done() -> void:
	if not _chat_web_mobile_keyboard_platform() or not _chat_keyboard_done_submit_ready():
		return
	if chat_overlay == null or not chat_overlay.visible:
		return
	_chat_submit_current_draft()

func _chat_finish_mobile_submit_attempt() -> void:
	if not _chat_mobile_keyboard_platform():
		return
	if chat_message_edit != null and is_instance_valid(chat_message_edit):
		chat_message_edit.release_focus()
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		DisplayServer.virtual_keyboard_hide()
	_collapse_chat_keyboard_lift_after_submit()

func _chat_send_pressed(text: String) -> void:
	host.button_press_runtime.play_default_button_sfx()
	chat_draft_message = text
	host._online_runtime().send_chat(text)

func _chat_send_button() -> Button:
	var button: Button = host._menu_button("Send")
	button.custom_minimum_size = Vector2(110, 75)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.tooltip_text = ""
	button.pressed.connect(_chat_queue_submit_current_draft)
	button.gui_input.connect(_on_chat_send_button_gui_input.bind(button))
	return button

func _on_chat_send_button_gui_input(event: InputEvent, button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			button.accept_event()
			_chat_queue_submit_current_draft()
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			button.accept_event()
			_chat_queue_submit_current_draft()

func open_profile_overlay() -> void:
	host._online_runtime().ensure_leaderboard_http()
	_ensure_profile_overlay()
	if profile_overlay == null:
		return
	profile_avatar_picker_open = false
	_rebuild_profile_overlay()
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(profile_overlay, true)

func _on_profile_overlay_gui_input(event: InputEvent) -> void:
	if InputRoutingShell.event_is_outside_panel_press(event, profile_panel):
		_save_profile_and_close()

func _on_profile_name_submitted(_submitted_text: String) -> void:
	_save_profile_and_close()

func _sync_pending_profile_name_edit() -> void:
	if host.leaderboard_profile.profile_claimed or profile_name_edit == null or not is_instance_valid(profile_name_edit):
		return
	host.leaderboard_profile.display_name = LeaderboardProfile.sanitize_display_name(profile_name_edit.text, host.PROFILE_DISPLAY_NAME_MAX_CHARS)
	host.leaderboard_profile.name_key = ""
	if LeaderboardProfile.is_default_display_name(host.leaderboard_profile.display_name, host.PROFILE_DISPLAY_NAME_MAX_CHARS):
		host.leaderboard_profile.display_name = LeaderboardProfile.make_guest_display_name(host.PROFILE_GUEST_NAME_PREFIX)

func _toggle_profile_avatar_picker() -> void:
	_sync_pending_profile_name_edit()
	profile_avatar_picker_open = not profile_avatar_picker_open
	_rebuild_profile_overlay()

func _save_profile_and_close() -> void:
	if not host.leaderboard_profile.profile_claimed and profile_name_edit != null and is_instance_valid(profile_name_edit):
		host.leaderboard_profile.display_name = LeaderboardProfile.sanitize_display_name(profile_name_edit.text, host.PROFILE_DISPLAY_NAME_MAX_CHARS)
		host.leaderboard_profile.name_key = ""
		host.leaderboard_profile.name_claim_verified = false
	if LeaderboardProfile.is_default_display_name(host.leaderboard_profile.display_name, host.PROFILE_DISPLAY_NAME_MAX_CHARS):
		host.leaderboard_profile.display_name = LeaderboardProfile.make_guest_display_name(host.PROFILE_GUEST_NAME_PREFIX)
		host.leaderboard_profile.name_key = ""
	_hide_profile_overlay()
	host.save_game()
	if host.current_screen == "leaderboard":
		host._navigation_shell()._render_screen()

func _select_profile_avatar(index: int) -> void:
	var new_avatar_index: int = LeaderboardProfile.valid_avatar_index(index, PROFILE_AVATAR_COUNT)
	if host.leaderboard_profile.avatar_index == new_avatar_index:
		profile_avatar_picker_open = false
		_rebuild_profile_overlay()
		return
	host.leaderboard_profile.avatar_index = new_avatar_index
	_sync_pending_profile_name_edit()
	profile_avatar_picker_open = false
	host._online_runtime()._refresh_profile_references()
	host.save_game()
	_rebuild_profile_overlay()
	if host.current_screen == "leaderboard":
		host._navigation_shell()._render_screen()

func _create_leaderboard_account() -> void:
	if host.leaderboard_profile.profile_claimed or host._online_runtime().leaderboard_name_claim_in_flight:
		return
	var chosen_name: String = host.leaderboard_profile.display_name
	if profile_name_edit != null and is_instance_valid(profile_name_edit):
		chosen_name = LeaderboardProfile.sanitize_display_name(profile_name_edit.text, host.PROFILE_DISPLAY_NAME_MAX_CHARS)
	if LeaderboardProfile.is_guest_display_name(chosen_name, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS):
		_set_profile_status_text("Choose a username first.")
		_focus_profile_name_edit()
		return
	host._online_runtime()._claim_leaderboard_name(chosen_name)

func _set_profile_status_text(text: String) -> void:
	if profile_status_label != null and is_instance_valid(profile_status_label):
		profile_status_label.text = text

func _focus_profile_name_edit() -> void:
	if profile_name_edit != null and is_instance_valid(profile_name_edit):
		profile_name_edit.grab_focus()

func _build_profile_overlay() -> void:
	profile_overlay_layer = CanvasLayer.new()
	profile_overlay_layer.layer = PROFILE_OVERLAY_CANVAS_LAYER
	host.add_child(profile_overlay_layer)

	profile_overlay = ColorRect.new()
	(profile_overlay as ColorRect).color = Color(0, 0, 0, 0.38)
	profile_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	profile_overlay.z_index = host.MODAL_OVERLAY_Z
	profile_overlay.z_as_relative = false
	profile_overlay.visible = false
	profile_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	profile_overlay.add_to_group("modal_overlay")
	profile_overlay.gui_input.connect(_on_profile_overlay_gui_input)
	profile_overlay_layer.add_child(profile_overlay)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	profile_overlay.add_child(center)
	profile_panel = PanelContainer.new()
	profile_panel.custom_minimum_size = Vector2(770, 1010)
	var profile_style: StyleBoxFlat = host._surface_style(host.COLOR_PANEL, host.CARD_RADIUS, 36, true)
	profile_style.content_margin_top = 18
	profile_style.content_margin_bottom = 18
	profile_panel.add_theme_stylebox_override("panel", profile_style)
	center.add_child(profile_panel)
	profile_content_stack = VBoxContainer.new()
	profile_content_stack.add_theme_constant_override("separation", 17)
	profile_panel.add_child(profile_content_stack)

func _rebuild_profile_overlay() -> void:
	if profile_content_stack == null:
		return
	if profile_panel != null:
		profile_panel.custom_minimum_size = Vector2(770, 1010 if profile_avatar_picker_open else 640)
	for child in profile_content_stack.get_children():
		child.queue_free()
	profile_avatar_buttons.clear()
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	profile_content_stack.add_child(header)
	var title = host._label("Profile", 62, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close = host._menu_button("Done")
	close.custom_minimum_size = Vector2(150, 77)
	close.pressed.connect(_save_profile_and_close)
	header.add_child(close)

	var identity_row = HBoxContainer.new()
	identity_row.alignment = BoxContainer.ALIGNMENT_CENTER
	identity_row.add_theme_constant_override("separation", 21)
	profile_content_stack.add_child(identity_row)
	identity_row.add_child(_profile_avatar_change_button())
	var name_stack = VBoxContainer.new()
	name_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_stack.add_theme_constant_override("separation", 9)
	identity_row.add_child(name_stack)
	profile_name_edit = LineEdit.new()
	profile_name_edit.text = host.leaderboard_profile.display_name
	profile_name_edit.placeholder_text = "Username"
	profile_name_edit.max_length = host.PROFILE_DISPLAY_NAME_MAX_CHARS
	profile_name_edit.custom_minimum_size = Vector2(0, 75)
	profile_name_edit.focus_mode = Control.FOCUS_ALL
	profile_name_edit.editable = not host.leaderboard_profile.profile_claimed
	profile_name_edit.add_theme_font_size_override("font_size", 48)
	if host.app_bold_font != null:
		profile_name_edit.add_theme_font_override("font", host.app_bold_font)
	elif host.app_font != null:
		profile_name_edit.add_theme_font_override("font", host.app_font)
	profile_name_edit.add_theme_color_override("font_color", host.COLOR_INK)
	profile_name_edit.add_theme_color_override("font_uneditable_color", host.COLOR_INK)
	profile_name_edit.add_theme_color_override("font_placeholder_color", Color("#8a8175"))
	profile_name_edit.add_theme_color_override("caret_color", host.COLOR_BLUE)
	profile_name_edit.add_theme_stylebox_override("normal", _profile_name_field_style(false))
	profile_name_edit.add_theme_stylebox_override("focus", _profile_name_field_style(true))
	profile_name_edit.add_theme_stylebox_override("read_only", _profile_name_field_style(false))
	profile_name_edit.text_submitted.connect(_on_profile_name_submitted)
	name_stack.add_child(profile_name_edit)
	profile_status_label = host._label(_profile_status_text(), host.MIN_MOBILE_HELP_FONT_SIZE, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	profile_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_status_label.custom_minimum_size = Vector2(0, 56)
	name_stack.add_child(profile_status_label)
	var cloud_status = host._label(host._online_runtime().cloud_save_status_text(), host.MIN_MOBILE_HELP_FONT_SIZE, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	cloud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cloud_status.custom_minimum_size = Vector2(0, 68)
	name_stack.add_child(cloud_status)
	if (
		host._online_runtime().leaderboard_auth_provider != "google"
		and LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS)
	):
		var google_button = host._menu_button("Connect Google")
		google_button.custom_minimum_size = Vector2(0, 66)
		google_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		google_button.disabled = host._online_runtime().google_auth_in_flight or host._online_runtime().leaderboard_auth_in_flight
		if host._online_runtime().google_auth_in_flight or host._online_runtime().leaderboard_auth_in_flight:
			google_button.text = "Connecting..."
		google_button.pressed.connect(host._start_google_account_sign_in)
		name_stack.add_child(google_button)

	if not host.leaderboard_profile.profile_claimed:
		var account_button = host._menu_button("Save Username")
		account_button.custom_minimum_size = Vector2(0, 77)
		account_button.disabled = host._online_runtime().leaderboard_name_claim_in_flight
		if host._online_runtime().leaderboard_name_claim_in_flight:
			account_button.text = "Checking..."
		account_button.pressed.connect(_create_leaderboard_account)
		name_stack.add_child(account_button)

	if profile_avatar_picker_open:
		var grid = GridContainer.new()
		grid.columns = PROFILE_AVATAR_COLUMNS
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		profile_content_stack.add_child(grid)
		for i in range(PROFILE_AVATAR_COUNT):
			var avatar_button = _profile_avatar_picker_button(i)
			profile_avatar_buttons.append(avatar_button)
			grid.add_child(avatar_button)

func _profile_avatar_change_button() -> Button:
	var button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(155, 155)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.clip_contents = true
	button.add_theme_stylebox_override("normal", _profile_avatar_button_style(true, false))
	button.add_theme_stylebox_override("hover", _profile_avatar_button_style(true, false, true))
	button.add_theme_stylebox_override("pressed", _profile_avatar_button_style(true, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host.button_press_runtime.attach_button_depress_animation(button, 0.94)
	button.pressed.connect(_toggle_profile_avatar_picker)
	var art = host.visual_texture_cache._image_from_texture(_profile_avatar_texture(host.leaderboard_profile.avatar_index), Vector2(155, 155))
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(art)
	button.add_child(_profile_avatar_border_overlay(true))
	return button

func _profile_avatar_picker_button(index: int) -> Button:
	var selected = LeaderboardProfile.valid_avatar_index(index, PROFILE_AVATAR_COUNT) == host.leaderboard_profile.avatar_index
	var button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(125, 125)
	button.focus_mode = Control.FOCUS_NONE
	button.clip_contents = true
	button.add_theme_stylebox_override("normal", _profile_avatar_button_style(selected, false))
	button.add_theme_stylebox_override("hover", _profile_avatar_button_style(selected, false, true))
	button.add_theme_stylebox_override("pressed", _profile_avatar_button_style(selected, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host.button_press_runtime.attach_button_depress_animation(button, 0.94)
	button.pressed.connect(_select_profile_avatar.bind(index))
	var art = host.visual_texture_cache._image_from_texture(_profile_avatar_texture(index), Vector2(125, 125))
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(art)
	button.add_child(_profile_avatar_border_overlay(selected))
	return button

func _profile_avatar_texture(index: int) -> Texture2D:
	var valid_index = LeaderboardProfile.valid_avatar_index(index, PROFILE_AVATAR_COUNT)
	if profile_avatar_texture_cache.has(valid_index):
		return profile_avatar_texture_cache[valid_index] as Texture2D
	if DisplayServer.get_name() == "headless":
		var headless_fallback = host.visual_texture_cache._visual_fallback_texture()
		profile_avatar_texture_cache[valid_index] = headless_fallback
		return headless_fallback
	var sheet_index = clampi(int(floor(float(valid_index) / float(PROFILE_AVATAR_SHEET_CELL_COUNT))), 0, PROFILE_AVATAR_SHEETS.size() - 1)
	var source = host.visual_texture_cache._texture(str(PROFILE_AVATAR_SHEETS[sheet_index]))
	if source == null:
		var fallback = host.visual_texture_cache._visual_fallback_texture()
		profile_avatar_texture_cache[valid_index] = fallback
		return fallback
	var atlas = AtlasTexture.new()
	var sheet_avatar_index = valid_index % PROFILE_AVATAR_SHEET_CELL_COUNT
	atlas.atlas = source
	var column = sheet_avatar_index % PROFILE_AVATAR_COLUMNS
	var row = int(floor(float(sheet_avatar_index) / float(PROFILE_AVATAR_COLUMNS)))
	var inset = PROFILE_AVATAR_COLORED_ATLAS_INSET if _profile_avatar_has_colored_background(valid_index) else PROFILE_AVATAR_ATLAS_INSET
	var region_size = PROFILE_AVATAR_CELL_SIZE - inset * 2
	atlas.region = Rect2(Vector2(column * PROFILE_AVATAR_CELL_SIZE + inset, row * PROFILE_AVATAR_CELL_SIZE + inset), Vector2(region_size, region_size))
	profile_avatar_texture_cache[valid_index] = atlas
	return atlas

func profile_avatar_frame(index: int, minimum_size: Vector2, selected := false) -> PanelContainer:
	var frame = PanelContainer.new()
	frame.custom_minimum_size = minimum_size
	frame.size = minimum_size
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.clip_contents = true
	frame.add_theme_stylebox_override("panel", _profile_avatar_frame_background_style(selected))
	var art = host.visual_texture_cache._image_from_texture(_profile_avatar_texture(index), minimum_size)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(art)
	frame.add_child(_profile_avatar_border_overlay(selected))
	return frame

func _profile_avatar_border_overlay(selected := false) -> PanelContainer:
	var overlay = PanelContainer.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", _profile_avatar_border_overlay_style(selected))
	return overlay

func _profile_avatar_has_colored_background(index: int) -> bool:
	return LeaderboardProfile.valid_avatar_index(index, PROFILE_AVATAR_COUNT) >= PROFILE_AVATAR_SHEET_CELL_COUNT

func _profile_status_text() -> String:
	if host._online_runtime().leaderboard_name_claim_in_flight:
		return "Checking username..."
	if host.leaderboard_profile.profile_claimed:
		return "Username saved."
	return "Choose a username for rankings."

static func avatar_frame_background(selected := false, theme_surface_color := Callable()) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff1b8") if selected else theme_surface_color.call(Color("#fffdf8"))
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(12)
	if selected:
		style.shadow_color = Color(0.09, 0.08, 0.07, 0.22)
		style.shadow_size = 5
		style.shadow_offset = Vector2(0, 4)
	return style


static func avatar_frame(_selected := false, ink_color := Color.BLACK, frame_border := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.draw_center = false
	style.border_color = ink_color
	style.set_border_width_all(frame_border)
	style.set_corner_radius_all(12)
	return style


static func avatar_button(selected := false, pressed := false, hovered := false, theme_surface_color := Callable()) -> StyleBoxFlat:
	var style: StyleBoxFlat = avatar_frame_background(selected, theme_surface_color)
	var fill: Color = Color("#fff1b8") if selected else theme_surface_color.call(Color("#fffdf8"))
	if hovered and not pressed:
		fill = fill.lightened(0.04)
	style.bg_color = fill.darkened(0.08 if pressed else 0.0)
	if pressed:
		style.shadow_size = 2
		style.shadow_offset = Vector2(0, 3)
	return style


static func name_field(
	focused := false,
	ink_color := Color.BLACK,
	focus_color := Color.BLUE,
	theme_surface_color := Callable(),
	theme_outline_color := Callable()
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = theme_surface_color.call(Color("#fffaf0"))
	style.border_color = focus_color if focused else theme_outline_color.call(ink_color, Color("#fffaf0"))
	style.set_border_width_all(5)
	style.set_corner_radius_all(18)
	style.content_margin_left = 17
	style.content_margin_right = 17
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style


func _profile_avatar_frame_background_style(selected := false) -> StyleBoxFlat:
	return avatar_frame_background(selected, Callable(host, "_theme_surface_color"))

func _profile_avatar_frame_style(selected := false) -> StyleBoxFlat:
	return avatar_frame(selected, host.COLOR_INK, PROFILE_AVATAR_FRAME_BORDER)

func _profile_avatar_button_style(selected := false, pressed := false, hovered := false) -> StyleBoxFlat:
	return avatar_button(selected, pressed, hovered, Callable(host, "_theme_surface_color"))

func _profile_avatar_border_overlay_style(selected := false) -> StyleBoxFlat:
	return _profile_avatar_frame_style(selected)

func _profile_name_field_style(focused := false) -> StyleBoxFlat:
	return name_field(
		focused,
		host.COLOR_INK,
		host.COLOR_BLUE,
		Callable(host, "_theme_surface_color"),
		Callable(host, "_theme_outline_color")
	)
