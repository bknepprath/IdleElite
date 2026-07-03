extends RefCounted

const LeaderboardProfile = preload("res://scripts/online/leaderboard_profile.gd")
const LeaderboardStyles = preload("res://scripts/leaderboard/styles.gd")
const ChatStyles = preload("res://scripts/chat/styles.gd")

const PROFILE_AVATAR_SHEETS := [
	"res://assets/content/ui/profile-avatar-game-objects-spritesheet.png",
	"res://assets/content/ui/profile-avatar-blue-guy-spritesheet.png"
]
const PROFILE_AVATAR_COUNT := 20
const PROFILE_AVATAR_SHEET_CELL_COUNT := 10
const PROFILE_AVATAR_COLUMNS := 5
const PROFILE_AVATAR_CELL_SIZE := 512
const PROFILE_AVATAR_ATLAS_INSET := 16
const PROFILE_AVATAR_COLORED_ATLAS_INSET := 60
const PROFILE_AVATAR_FRAME_BORDER := 16

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

func _init(host_ref) -> void:
	host = host_ref

func _global_chat_allowed() -> bool:
	return not host._onboarding_runtime()._onboarding_path_active()

func _chat_strip_visible_on_current_screen() -> bool:
	return host.current_screen == "menu" or host.current_screen == "skill" or host.current_screen == "pinned" or host.current_screen == "queue"

func _ensure_chat_strip() -> void:
	if not _global_chat_allowed():
		return
	if host.chat_strip != null and is_instance_valid(host.chat_strip):
		return
	host._online_runtime().ensure_leaderboard_http()
	_build_chat_strip()

func _ensure_chat_overlay() -> void:
	if host._lazy_overlay_built("chat"):
		return
	host._mark_lazy_overlay_built("chat")
	_build_chat_overlay()

func _ensure_profile_overlay() -> void:
	if host._lazy_overlay_built("profile"):
		return
	host._mark_lazy_overlay_built("profile")
	_build_profile_overlay()

func _rebuild_profile_overlay_if_visible() -> void:
	if profile_overlay != null and profile_overlay.visible:
		_rebuild_profile_overlay()

func _profile_overlay_visible() -> bool:
	return profile_overlay != null and profile_overlay.visible

func _hide_profile_overlay() -> void:
	if profile_overlay != null:
		host._set_canvas_item_visible_if_changed(profile_overlay, false)

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
	if host.chat_unread_dot == null or not is_instance_valid(host.chat_unread_dot):
		return
	var should_show = host.chat_strip != null and is_instance_valid(host.chat_strip) and host.chat_strip.visible and host._online_runtime()._chat_has_unread_messages()
	host._set_canvas_item_visible_if_changed(host.chat_unread_dot, should_show)

func _render_chat_if_visible() -> void:
	if host.chat_overlay != null and host.chat_overlay.visible:
		host._online_runtime().mark_chat_opened_to_latest(false)
	_update_chat_strip()
	_refresh_chat_status_labels()
	if host.chat_overlay == null or not host.chat_overlay.visible:
		return
	_ensure_chat_overlay_shell()
	_sync_chat_overlay_rows()
	_chat_scroll_to_latest_deferred()

func _track_chat_status_labels(title: Label, detail: Label) -> void:
	if title != null and is_instance_valid(title):
		host.chat_status_title_labels.append(title)
	if detail != null and is_instance_valid(detail):
		host.chat_status_detail_labels.append(detail)

func _refresh_chat_status_labels() -> void:
	var title_text = _chat_status_title()
	var detail_text = _chat_status_detail()
	for i in range(host.chat_status_title_labels.size() - 1, -1, -1):
		var raw_title_label = host.chat_status_title_labels[i]
		if raw_title_label == null or not is_instance_valid(raw_title_label):
			host.chat_status_title_labels.remove_at(i)
		else:
			var title_label = raw_title_label as Label
			if title_label == null:
				host.chat_status_title_labels.remove_at(i)
				continue
			title_label.text = title_text
	for i in range(host.chat_status_detail_labels.size() - 1, -1, -1):
		var raw_detail_label = host.chat_status_detail_labels[i]
		if raw_detail_label == null or not is_instance_valid(raw_detail_label):
			host.chat_status_detail_labels.remove_at(i)
		else:
			var detail_label = raw_detail_label as Label
			if detail_label == null:
				host.chat_status_detail_labels.remove_at(i)
				continue
			detail_label.text = detail_text

func _destroy_chat_overlay_shell() -> void:
	host.chat_overlay_shell_ready = false
	host.chat_overlay_list = null
	host.chat_overlay_notice = null
	host.chat_overlay_row_nodes.clear()
	host.chat_overlay_row_signatures.clear()
	host.chat_status_title_labels.clear()
	host.chat_status_detail_labels.clear()
	host.chat_message_edit = null
	host.chat_profile_button = null
	host.chat_overlay_scroll = null
	if host.chat_overlay_body == null or not is_instance_valid(host.chat_overlay_body):
		return
	for child in host.chat_overlay_body.get_children():
		host.chat_overlay_body.remove_child(child)
		child.queue_free()

func _ensure_chat_overlay_shell() -> void:
	if host.chat_overlay == null or host.chat_overlay_body == null:
		return
	if (
		host.chat_overlay_shell_ready
		and host.chat_overlay_list != null
		and is_instance_valid(host.chat_overlay_list)
		and host.chat_overlay_scroll != null
		and is_instance_valid(host.chat_overlay_scroll)
		and host.chat_message_edit != null
		and is_instance_valid(host.chat_message_edit)
	):
		return
	_destroy_chat_overlay_shell()
	host.chat_overlay_body.add_child(_chat_expanded_header())
	var scroll = host.MobileScrollContainer.new()
	host.chat_overlay_scroll = scroll
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.set_pull_resistance_enabled(false)
	host.chat_overlay_body.add_child(scroll)
	var list_margin = MarginContainer.new()
	var viewport_width = host.get_viewport_rect().size.x
	list_margin.custom_minimum_size = Vector2(viewport_width, 0)
	list_margin.add_theme_constant_override("margin_left", 64)
	list_margin.add_theme_constant_override("margin_right", 48)
	list_margin.add_theme_constant_override("margin_top", 58)
	list_margin.add_theme_constant_override("margin_bottom", 34)
	scroll.add_child(list_margin)
	var list = VBoxContainer.new()
	host.chat_overlay_list = list
	list.custom_minimum_size = Vector2(maxf(1.0, viewport_width - 112.0), 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 36)
	list_margin.add_child(list)
	host.chat_overlay_body.add_child(_chat_expanded_composer())
	host.chat_overlay_shell_ready = true

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
	if host.chat_overlay_list == null or not is_instance_valid(host.chat_overlay_list):
		return
	var should_show = _chat_expanded_notice_visible()
	if should_show:
		var fresh = _chat_expanded_notice()
		if host.chat_overlay_notice != null and is_instance_valid(host.chat_overlay_notice):
			var notice_index = host.chat_overlay_notice.get_index()
			host.chat_overlay_notice.queue_free()
			host.chat_overlay_list.add_child(fresh)
			host.chat_overlay_list.move_child(fresh, notice_index)
		else:
			host.chat_overlay_list.add_child(fresh)
			host.chat_overlay_list.move_child(fresh, 0)
		host.chat_overlay_notice = fresh
	elif host.chat_overlay_notice != null and is_instance_valid(host.chat_overlay_notice):
		host.chat_overlay_notice.queue_free()
		host.chat_overlay_notice = null

func _sync_chat_overlay_rows() -> void:
	if host.chat_overlay == null or not host.chat_overlay.visible or host.chat_overlay_list == null:
		return
	_sync_chat_overlay_notice()
	var row_start_index = 1 if host.chat_overlay_notice != null and is_instance_valid(host.chat_overlay_notice) else 0
	var desired_ids: Array[String] = []
	for raw_row in host.chat_rows:
		desired_ids.append(str((raw_row as Dictionary).get("message_id", "")))
	for raw_message_id in host.chat_overlay_row_nodes.keys():
		var message_id = str(raw_message_id)
		if message_id not in desired_ids:
			var stale = host.chat_overlay_row_nodes.get(message_id) as Control
			if stale != null and is_instance_valid(stale):
				stale.queue_free()
			host.chat_overlay_row_nodes.erase(message_id)
			host.chat_overlay_row_signatures.erase(message_id)
	for i in range(host.chat_rows.size()):
		var row_data = host.chat_rows[i] as Dictionary
		var message_id = str(row_data.get("message_id", ""))
		if message_id.is_empty():
			continue
		var target_index = row_start_index + i
		var signature = _chat_overlay_row_signature(row_data)
		var row_widget = host.chat_overlay_row_nodes.get(message_id) as Control
		if row_widget == null or not is_instance_valid(row_widget) or str(host.chat_overlay_row_signatures.get(message_id, "")) != signature:
			if row_widget != null and is_instance_valid(row_widget):
				row_widget.queue_free()
			row_widget = _chat_expanded_row(row_data)
			host.chat_overlay_list.add_child(row_widget)
			host.chat_overlay_row_nodes[message_id] = row_widget
			host.chat_overlay_row_signatures[message_id] = signature
		if row_widget.get_index() != target_index:
			host.chat_overlay_list.move_child(row_widget, target_index)

func _build_chat_strip() -> void:
	host.chat_strip = PanelContainer.new()
	host.chat_strip.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	host.chat_strip.offset_top = -host.BOTTOM_NAV_HEIGHT - host.CHAT_STRIP_HEIGHT
	host.chat_strip.offset_bottom = -host.BOTTOM_NAV_HEIGHT
	host.chat_strip.z_index = host.CHAT_UI_Z
	host.chat_strip.z_as_relative = false
	host.chat_strip.visible = false
	host.chat_strip.clip_contents = true
	host.chat_strip.mouse_filter = Control.MOUSE_FILTER_STOP
	host.chat_strip.add_theme_stylebox_override("panel", ChatStyles.strip())
	host.chat_strip.gui_input.connect(_on_chat_strip_gui_input)
	host.add_child(host.chat_strip)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 46)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	host.chat_strip.add_child(margin)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	margin.add_child(row)
	var icon_holder = Control.new()
	icon_holder.custom_minimum_size = Vector2(213, 213)
	icon_holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_holder)
	var icon = host.visual_texture_cache._image(host.CHAT_STRIP_ICON, Vector2(213, 213))
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_holder.add_child(icon)
	host.chat_unread_dot = PanelContainer.new()
	host.chat_unread_dot.anchor_left = 1.0
	host.chat_unread_dot.anchor_right = 1.0
	host.chat_unread_dot.anchor_top = 0.0
	host.chat_unread_dot.anchor_bottom = 0.0
	host.chat_unread_dot.offset_left = -host.CHAT_UNREAD_DOT_DIAMETER - host.CHAT_UNREAD_DOT_EDGE_INSET
	host.chat_unread_dot.offset_right = -host.CHAT_UNREAD_DOT_EDGE_INSET
	host.chat_unread_dot.offset_top = host.CHAT_UNREAD_DOT_EDGE_INSET
	host.chat_unread_dot.offset_bottom = host.CHAT_UNREAD_DOT_EDGE_INSET + host.CHAT_UNREAD_DOT_DIAMETER
	host.chat_unread_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.chat_unread_dot.visible = false
	host.chat_unread_dot.add_theme_stylebox_override("panel", ChatStyles.unread_dot())
	icon_holder.add_child(host.chat_unread_dot)
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 4)
	row.add_child(copy)
	host.chat_strip_line_one = host._label("", 58, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	host.chat_strip_line_one.add_theme_color_override("font_outline_color", Color("#9d9d9d"))
	host.chat_strip_line_one.add_theme_constant_override("outline_size", 5)
	host.chat_strip_line_one.autowrap_mode = TextServer.AUTOWRAP_OFF
	host.chat_strip_line_one.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	host.chat_strip_line_one.clip_text = true
	host.chat_strip_line_one.custom_minimum_size = Vector2(0, 84)
	copy.add_child(host.chat_strip_line_one)
	host.chat_strip_line_two = host._label("", 58, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	host.chat_strip_line_two.add_theme_color_override("font_outline_color", Color("#9d9d9d"))
	host.chat_strip_line_two.add_theme_constant_override("outline_size", 5)
	host.chat_strip_line_two.autowrap_mode = TextServer.AUTOWRAP_OFF
	host.chat_strip_line_two.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	host.chat_strip_line_two.clip_text = true
	host.chat_strip_line_two.custom_minimum_size = Vector2(0, 84)
	copy.add_child(host.chat_strip_line_two)
	_update_chat_strip()

func _build_chat_overlay() -> void:
	host.chat_overlay_layer = CanvasLayer.new()
	host.chat_overlay_layer.layer = host.CHAT_OVERLAY_CANVAS_LAYER
	host.add_child(host.chat_overlay_layer)

	host.chat_overlay = ColorRect.new()
	host.chat_overlay.color = Color.WHITE
	host.chat_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.chat_overlay.z_index = host.MODAL_OVERLAY_Z
	host.chat_overlay.z_as_relative = false
	host.chat_overlay.visible = false
	host.chat_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.chat_overlay.add_to_group("modal_overlay")
	host.chat_overlay_layer.add_child(host.chat_overlay)
	host.chat_keyboard_fill = ColorRect.new()
	host.chat_keyboard_fill.color = host.COLOR_NAV
	host.chat_keyboard_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.chat_keyboard_fill.anchor_top = 1.0
	host.chat_keyboard_fill.offset_top = 0.0
	host.chat_keyboard_fill.offset_bottom = 0.0
	host.chat_keyboard_fill.visible = false
	host.chat_keyboard_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.chat_overlay.add_child(host.chat_keyboard_fill)
	host.chat_overlay_body = VBoxContainer.new()
	host.chat_overlay_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.chat_overlay_body.add_theme_constant_override("separation", 0)
	host.chat_overlay.add_child(host.chat_overlay_body)
	host.chat_keyboard_preview = PanelContainer.new()
	host.chat_keyboard_preview.anchor_left = 0.0
	host.chat_keyboard_preview.anchor_right = 1.0
	host.chat_keyboard_preview.anchor_top = 1.0
	host.chat_keyboard_preview.anchor_bottom = 1.0
	host.chat_keyboard_preview.offset_left = 46.0
	host.chat_keyboard_preview.offset_right = -46.0
	host.chat_keyboard_preview.offset_top = -host.CHAT_KEYBOARD_PREVIEW_HEIGHT
	host.chat_keyboard_preview.offset_bottom = 0.0
	host.chat_keyboard_preview.z_index = host.MODAL_OVERLAY_Z
	host.chat_keyboard_preview.visible = false
	host.chat_keyboard_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.chat_keyboard_preview.add_theme_stylebox_override("panel", ChatStyles.keyboard_preview(host.COLOR_BLUE))
	host.chat_overlay.add_child(host.chat_keyboard_preview)
	host.chat_keyboard_preview_label = host._label("", 62, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	host.chat_keyboard_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	host.chat_keyboard_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.chat_keyboard_preview_label.clip_text = true
	host.chat_keyboard_preview_label.custom_minimum_size = Vector2(0, host.CHAT_KEYBOARD_PREVIEW_HEIGHT - 34)
	host.chat_keyboard_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.chat_keyboard_preview.add_child(host.chat_keyboard_preview_label)

func _on_chat_strip_gui_input(event: InputEvent) -> void:
	if host.chat_overlay != null and host.chat_overlay.visible:
		return
	if host._skill_detail_surface()._event_points_inside_detail_jump_arrow(event, host.chat_strip):
		host.chat_strip.accept_event()
		return
	if host._achievement_toast_surface()._event_points_inside_achievement_toast(event, host.chat_strip):
		host.chat_strip.accept_event()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_chat_overlay()
		host.chat_strip.accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_open_chat_overlay()
		host.chat_strip.accept_event()

func _route_chat_strip_input(event: InputEvent) -> bool:
	if host.chat_overlay != null and host.chat_overlay.visible:
		return false
	if host.chat_strip == null or not is_instance_valid(host.chat_strip) or not host.chat_strip.visible:
		return false
	if host._skill_detail_surface()._event_points_inside_detail_jump_arrow(event):
		return false
	if host._achievement_toast_surface()._event_points_inside_achievement_toast(event):
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if host.chat_strip.get_global_rect().has_point(event.global_position):
			_open_chat_overlay()
			return true
	if event is InputEventScreenTouch and event.pressed:
		if host.chat_strip.get_global_rect().has_point(event.position):
			_open_chat_overlay()
			return true
	return false

func _position_inside_chat_strip_interactive_ui(event_position: Vector2) -> bool:
	if host.chat_strip == null or not is_instance_valid(host.chat_strip) or not host.chat_strip.is_visible_in_tree():
		return false
	return host.chat_strip.get_global_rect().grow(4.0).has_point(event_position)

func _open_chat_overlay() -> void:
	host._button_press_runtime().play_default_button_sfx()
	_ensure_chat_overlay()
	if host.chat_overlay == null or not _chat_strip_visible_on_current_screen():
		return
	host._set_canvas_item_visible_if_changed(host.chat_overlay, true)
	host.chat_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host._online_runtime()._chat_stream_connect()
	host._online_runtime()._start_chat_stream_poll_timer()
	_ensure_chat_overlay_shell()
	_sync_chat_overlay_rows()
	host._online_runtime().mark_chat_opened_to_latest(true)
	_chat_scroll_to_latest_deferred()

func _close_chat_overlay(play_sfx := true) -> void:
	if play_sfx:
		host._button_press_runtime().play_default_button_sfx()
	if host.chat_overlay != null and host.chat_overlay.visible:
		host._online_runtime().mark_chat_opened_to_latest(true)
	if host.chat_overlay != null:
		host._set_canvas_item_visible_if_changed(host.chat_overlay, false)
	_reset_chat_keyboard_lift()
	if host.chat_overlay_body != null and is_instance_valid(host.chat_overlay_body):
		host.chat_overlay_body.offset_bottom = 0.0
	if host.chat_keyboard_fill != null and is_instance_valid(host.chat_keyboard_fill):
		host._set_canvas_item_visible_if_changed(host.chat_keyboard_fill, false)
		host.chat_keyboard_fill.offset_top = 0.0
	_hide_chat_keyboard_preview()
	if _chat_strip_visible_on_current_screen():
		_update_chat_strip()

func _chat_expanded_header() -> Control:
	var header = Control.new()
	header.custom_minimum_size = Vector2(0, 330)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var shelf = ColorRect.new()
	shelf.color = host._theme_paper_color()
	shelf.set_anchors_preset(Control.PRESET_FULL_RECT)
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(shelf)
	var top = MarginContainer.new()
	top.set_anchors_preset(Control.PRESET_FULL_RECT)
	top.add_theme_constant_override("margin_left", 64)
	top.add_theme_constant_override("margin_right", 64)
	top.add_theme_constant_override("margin_top", 56)
	top.add_theme_constant_override("margin_bottom", 64)
	header.add_child(top)
	var tabs = HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_theme_constant_override("separation", 46)
	top.add_child(tabs)
	tabs.add_child(_chat_profile_button())
	var world = PanelContainer.new()
	world.custom_minimum_size = Vector2(780, 136)
	world.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	world.add_theme_stylebox_override("panel", ChatStyles.world_tab(host.COLOR_INK))
	tabs.add_child(world)
	var world_label = host._label("Global Chat", 66, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	world_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	world.add_child(world_label)
	var shadow = host.SkillDetailPageShelfShadow.new()
	shadow.anchor_left = 0.0
	shadow.anchor_right = 1.0
	shadow.anchor_top = 0.0
	shadow.anchor_bottom = 0.0
	shadow.offset_left = 0.0
	shadow.offset_right = 0.0
	shadow.offset_top = 330.0
	shadow.offset_bottom = 422.0
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(shadow)
	return header

func _chat_expanded_notice_visible() -> bool:
	return _chat_status_actionable() or host.chat_rows.is_empty()

func _chat_status_actionable() -> bool:
	return not host.chat_status_message.is_empty() and host.chat_status_message != "Chat loaded." and host.chat_status_message != "Global chat is live."

func _chat_expanded_notice() -> Control:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", host._surface_style(Color("#e8f6ff"), 30, 28, false))
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	panel.add_child(row)
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 8)
	row.add_child(copy)
	var title = host._label(_chat_status_title(), 58, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(title)
	var detail = host._label(_chat_status_detail(), host.MIN_MOBILE_BODY_FONT_SIZE, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(0, 96)
	copy.add_child(detail)
	_track_chat_status_labels(title, detail)
	return panel

func _chat_expanded_row(row_data: Dictionary) -> Control:
	var deleted = bool(row_data.get("deleted", false))
	var is_self = str(row_data.get("sender_id", "")) == host.leaderboard_player_id
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.custom_minimum_size = Vector2(0, 260)
	row.add_child(_profile_avatar_frame(int(row_data.get("avatar_index", 0)), Vector2(188, 188), is_self))
	var copy = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 10)
	row.add_child(copy)
	var meta = HBoxContainer.new()
	meta.add_theme_constant_override("separation", 12)
	copy.add_child(meta)
	var name_text = _chat_sender_label(row_data)
	var name_color = Color("#57b8ff") if is_self else Color("#ffc94a")
	var player_name_label = host._label(name_text, 66, name_color, HORIZONTAL_ALIGNMENT_LEFT)
	var name_settings = LabelSettings.new()
	if host.app_bold_font != null:
		name_settings.font = host.app_bold_font
	elif host.app_font != null:
		name_settings.font = host.app_font
	name_settings.font_size = 66
	name_settings.font_color = name_color
	name_settings.outline_color = Color.BLACK
	name_settings.outline_size = 30
	player_name_label.label_settings = name_settings
	player_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_margin = MarginContainer.new()
	name_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_margin.add_theme_constant_override("margin_left", 34)
	name_margin.add_theme_constant_override("margin_top", 6)
	name_margin.add_theme_constant_override("margin_bottom", 6)
	name_margin.add_child(player_name_label)
	meta.add_child(name_margin)
	var time = host._label(host.ChatState.time_text(row_data), 58, Color("#a7a7a7"), HORIZONTAL_ALIGNMENT_RIGHT)
	time.custom_minimum_size = Vector2(210, 0)
	meta.add_child(time)
	var bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", ChatStyles.expanded_message(deleted, is_self))
	copy.add_child(bubble)
	var body_text = "Message removed by moderator." if deleted else str(row_data.get("text", ""))
	var body = host._label(body_text, 70, Color("#080808") if not deleted else Color("#6c625a"), HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(0, 112)
	bubble.add_child(body)
	return row

func _chat_expanded_composer() -> Control:
	var stack = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 0)
	var bar = PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, host.CHAT_STRIP_HEIGHT)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("panel", ChatStyles.strip())
	stack.add_child(bar)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_right", 56)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	bar.add_child(margin)
	var column = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 34)
	column.add_child(row)
	var back = host._menu_button("<")
	back.custom_minimum_size = Vector2(154, 154)
	back.add_theme_font_size_override("font_size", 84)
	back.add_theme_stylebox_override("normal", ChatStyles.back_button(false, host.COLOR_INK))
	back.add_theme_stylebox_override("hover", ChatStyles.back_button(false, host.COLOR_INK))
	back.add_theme_stylebox_override("pressed", ChatStyles.back_button(true, host.COLOR_INK))
	back.pressed.connect(_close_chat_overlay)
	row.add_child(back)
	host.chat_message_edit = LineEdit.new()
	host.chat_message_edit.placeholder_text = "Send a message..."
	host.chat_message_edit.max_length = host.CHAT_MESSAGE_MAX_CHARS
	host.chat_message_edit.custom_minimum_size = Vector2(0, 154)
	host.chat_message_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.chat_message_edit.focus_mode = Control.FOCUS_ALL
	host.chat_message_edit.add_theme_font_size_override("font_size", 68)
	if host.app_bold_font != null:
		host.chat_message_edit.add_theme_font_override("font", host.app_bold_font)
	elif host.app_font != null:
		host.chat_message_edit.add_theme_font_override("font", host.app_font)
	host.chat_message_edit.add_theme_color_override("font_color", host.COLOR_INK)
	host.chat_message_edit.add_theme_color_override("font_placeholder_color", Color("#b9b9b9"))
	host.chat_message_edit.add_theme_color_override("caret_color", host.COLOR_INK)
	host.chat_message_edit.add_theme_constant_override("caret_width", 8)
	host.chat_message_edit.set("caret_blink", true)
	host.chat_message_edit.set("caret_blink_interval", 0.42)
	host.chat_message_edit.add_theme_stylebox_override("normal", ChatStyles.input(false, host.COLOR_INK, host.COLOR_BLUE))
	host.chat_message_edit.add_theme_stylebox_override("focus", ChatStyles.input(true, host.COLOR_INK, host.COLOR_BLUE))
	host.chat_message_edit.text = host.chat_draft_message
	host.chat_message_edit.text_changed.connect(_on_chat_draft_changed)
	host.chat_message_edit.gui_input.connect(_on_chat_input_gui_input)
	host.chat_message_edit.focus_entered.connect(_on_chat_input_focus_entered)
	host.chat_message_edit.focus_exited.connect(_on_chat_input_focus_exited)
	host.chat_message_edit.text_submitted.connect(_chat_text_submitted)
	host.chat_message_edit.editable = host._online_runtime()._leaderboard_firebase_enabled()
	row.add_child(host.chat_message_edit)
	var send_button = _chat_send_button()
	row.add_child(send_button)
	var ribbon_frame = Control.new()
	ribbon_frame.custom_minimum_size = Vector2(0, host.BOTTOM_NAV_HEIGHT)
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
	ribbon_row.add_theme_constant_override("separation", 120)
	ribbon_row.clip_contents = true
	ribbon_row.custom_minimum_size = Vector2(0, host.BOTTOM_NAV_HEIGHT - host.BOTTOM_NAV_SAFE_PAD)
	ribbon.add_child(ribbon_row)
	host.chat_home_tab = navigation_shell._nav_button(host.PROGRESS_STAR_ICON_TEXTURE)
	host.chat_home_tab.custom_minimum_size = Vector2(318, 318)
	host.chat_home_tab.add_theme_constant_override("icon_max_width", 244)
	navigation_shell._register_nav_new_symbol_dot(host.chat_home_tab, "hero")
	host.chat_home_tab.modulate = Color.WHITE if host._hero_unlocked() else host.HUB_NAV_LOCKED_MODULATE
	host.chat_home_tab.tooltip_text = ""
	host.chat_home_tab.pressed.connect(_on_chat_home_nav_pressed)
	ribbon_row.add_child(host.chat_home_tab)
	host.chat_hub_tab = navigation_shell._nav_button("res://assets/content/hub/hub-nav-barn.png")
	host.chat_hub_tab.add_theme_constant_override("icon_max_width", 220)
	navigation_shell._register_nav_new_symbol_dot(host.chat_hub_tab, "hub")
	host.chat_hub_tab.modulate = Color.WHITE if host._hub_unlocked() else host.HUB_NAV_LOCKED_MODULATE
	host.chat_hub_tab.tooltip_text = ""
	host.chat_hub_tab.pressed.connect(_on_chat_hub_nav_pressed)
	ribbon_row.add_child(host.chat_hub_tab)
	var chat_skills = navigation_shell._nav_button(host.TOTAL_LEVEL_BARGRAPH_TEXTURE)
	chat_skills.pressed.connect(_on_chat_skills_nav_pressed)
	ribbon_row.add_child(chat_skills)
	var chat_settings = navigation_shell._nav_button(host.SETTINGS_GEAR_ICON_TEXTURE)
	chat_settings.pressed.connect(_on_chat_settings_nav_pressed)
	ribbon_row.add_child(chat_settings)
	host.chat_shop_tab = navigation_shell._nav_button(host.SHOP_ICON_TEXTURE)
	host.chat_shop_tab.add_theme_constant_override("icon_max_width", 232)
	navigation_shell._register_nav_new_symbol_dot(host.chat_shop_tab, "shop")
	host.chat_shop_tab.modulate = Color.WHITE if host._shop_unlocked() else host.HUB_NAV_LOCKED_MODULATE
	host.chat_shop_tab.tooltip_text = ""
	host.chat_shop_tab.pressed.connect(_on_chat_shop_nav_pressed)
	ribbon_row.add_child(host.chat_shop_tab)
	return stack

func _on_chat_home_nav_pressed() -> void:
	_close_chat_overlay(false)
	host._show_home(host.chat_home_tab)


func _on_chat_hub_nav_pressed() -> void:
	_close_chat_overlay(false)
	host._show_hub(host.chat_hub_tab)


func _on_chat_skills_nav_pressed() -> void:
	_close_chat_overlay(false)
	host._show_skills_module()


func _on_chat_settings_nav_pressed() -> void:
	_close_chat_overlay(false)
	host._settings_surface()._show_settings()


func _on_chat_shop_nav_pressed() -> void:
	_close_chat_overlay(false)
	host._show_shop(host.chat_shop_tab)


func _update_chat_strip(force_visibility := false) -> void:
	if not _global_chat_allowed():
		if host.chat_stream_connected or host.chat_stream_connecting or host.chat_stream_request_sent:
			host._online_runtime()._chat_stream_disconnect(false)
		if host.chat_strip != null and is_instance_valid(host.chat_strip):
			host._set_canvas_item_visible_if_changed(host.chat_strip, false)
			host.chat_strip_last_visible = false
		if host.chat_unread_dot != null and is_instance_valid(host.chat_unread_dot):
			host._set_canvas_item_visible_if_changed(host.chat_unread_dot, false)
		return
	if host.chat_strip == null or not is_instance_valid(host.chat_strip):
		if _chat_strip_visible_on_current_screen() or force_visibility:
			_ensure_chat_strip()
		if host.chat_strip == null or not is_instance_valid(host.chat_strip):
			return
	var should_show_chat_strip := _chat_strip_committed_visible(force_visibility)
	if host.chat_strip_last_visible != should_show_chat_strip:
		host.chat_strip_last_visible = should_show_chat_strip
		if should_show_chat_strip:
			host._online_runtime()._chat_stream_connect()
		else:
			host._online_runtime()._chat_stream_disconnect(false)
	elif should_show_chat_strip and (host.chat_stream_connecting or host.chat_stream_request_sent) and not host.chat_stream_connected:
		host._online_runtime()._start_chat_stream_poll_timer()
	_sync_chat_unread_dot()
	if host.chat_strip_line_one == null or host.chat_strip_line_two == null:
		return
	var lines := _chat_strip_lines()
	var line_one := str(lines[0])
	var line_two := str(lines[1])
	if host.chat_strip_last_line_one != line_one:
		host.chat_strip_last_line_one = line_one
		host._set_label_text_if_changed(host.chat_strip_line_one, line_one)
	if host.chat_strip_last_line_two != line_two:
		host.chat_strip_last_line_two = line_two
		host._set_label_text_if_changed(host.chat_strip_line_two, line_two)

func _chat_strip_committed_visible(force_visibility := false) -> bool:
	var target_visible: bool = _chat_strip_visible_on_current_screen()
	var now := Time.get_ticks_msec()
	if target_visible:
		host.chat_strip_hide_started_msec = 0
		host._set_canvas_item_visible_if_changed(host.chat_strip, true)
		return true
	if force_visibility:
		host._set_canvas_item_visible_if_changed(host.chat_strip, false)
		host.chat_strip_hide_started_msec = 0
		return false
	if host.chat_strip.visible:
		if host.chat_strip_hide_started_msec <= 0:
			host.chat_strip_hide_started_msec = now
			return true
		if now - host.chat_strip_hide_started_msec < host.CHAT_STRIP_HIDE_GRACE_MSEC:
			return true
		host._set_canvas_item_visible_if_changed(host.chat_strip, false)
		host.chat_strip_hide_started_msec = 0
	return false

func _chat_strip_lines() -> Array:
	var messages: Array = []
	for raw_row in host.chat_rows:
		var row := raw_row as Dictionary
		if bool(row.get("deleted", false)):
			messages.append("mod: message removed")
		else:
			var display_name: String = _chat_sender_name(row)
			var text: String = host.ChatState.sanitize_message(str(row.get("text", "")), host.CHAT_MESSAGE_MAX_CHARS, host.CHAT_CENSORED_WORDS)
			if text.is_empty():
				continue
			messages.append("%s: %s" % [display_name, text])
	if messages.size() >= 2:
		return _chat_strip_remember_lines(messages[messages.size() - 2], messages[messages.size() - 1])
	if messages.size() == 1:
		return _chat_strip_remember_lines("Global Chat", messages[0])
	if not host.chat_strip_stable_line_two.is_empty() and _chat_strip_should_hold_empty_state():
		return [host.chat_strip_stable_line_one, host.chat_strip_stable_line_two]
	host.chat_strip_stable_line_one = ""
	host.chat_strip_stable_line_two = ""
	host.chat_strip_empty_started_msec = 0
	if not host._online_runtime()._leaderboard_firebase_enabled():
		return ["Global Chat", "Tap to open chat."]
	return ["Global Chat", "Tap to open chat."]

func _chat_strip_remember_lines(line_one: String, line_two: String) -> Array:
	host.chat_strip_stable_line_one = line_one
	host.chat_strip_stable_line_two = line_two
	host.chat_strip_empty_started_msec = 0
	return [line_one, line_two]

func _chat_strip_should_hold_empty_state() -> bool:
	if not (host.chat_stream_connecting or host.chat_stream_request_sent or host.chat_stream_retry_unix > host._unix_now()):
		return false
	var now := Time.get_ticks_msec()
	if host.chat_strip_empty_started_msec <= 0:
		host.chat_strip_empty_started_msec = now
	return now - host.chat_strip_empty_started_msec <= host.CHAT_STRIP_EMPTY_GRACE_MSEC

func _chat_profile_button_text() -> String:
	if LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS):
		return LeaderboardProfile.sanitize_display_name(host.leaderboard_display_name, host.PROFILE_DISPLAY_NAME_MAX_CHARS)
	return "Claim Name"

func _chat_profile_button() -> Button:
	var button: Button = host._menu_button(_chat_profile_button_text())
	host.chat_profile_button = button
	button.custom_minimum_size = Vector2(720, 136)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 50)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(_open_profile_overlay)
	return button

func _refresh_chat_profile_button() -> void:
	if host.chat_profile_button != null and is_instance_valid(host.chat_profile_button):
		host.chat_profile_button.text = _chat_profile_button_text()

func _chat_row_total_level(row_data: Dictionary) -> int:
	var total_level := maxi(0, int(row_data.get("total_level", 0)))
	if total_level <= 0 and str(row_data.get("sender_id", "")) == host.leaderboard_player_id:
		total_level = host._global_level()
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
	if host.chat_send_in_flight:
		return "Sending..."
	if host.chat_stream_connecting:
		return "Connecting..."
	if host.chat_stream_connected:
		return "Real-time chat live"
	if host.leaderboard_auth_in_flight:
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
	if not host.chat_status_message.is_empty() and host.chat_status_message != "Chat loaded.":
		return host.chat_status_message
	if host.chat_stream_connected:
		return "One live chat connection is open here, capped to %s recent messages." % host._online_runtime()._chat_target_visible_count()
	var wait := maxi(0, host.chat_stream_retry_unix - host._unix_now())
	if wait > 0:
		return "The chat stream is cooling down for %s before reconnecting." % GameFormatting.duration(float(wait))
	var auth_wait: int = host._online_runtime()._leaderboard_auth_retry_wait_seconds()
	if auth_wait > 0:
		return "Messages can load without login. Sending waits %s before retrying online login." % GameFormatting.duration(float(auth_wait))
	if host.leaderboard_auth_in_flight:
		return "Messages can load while online send login starts."
	if not host._online_runtime()._leaderboard_auth_ready():
		return "Messages can load without login. Sending starts anonymous online login first."
	return "The skills chat strip opens one live chat connection while it is visible."

func _on_chat_draft_changed(text: String) -> void:
	host.chat_draft_message = text
	host.chat_keyboard_close_submit_done = false
	_update_chat_keyboard_preview()

func _on_chat_input_focus_entered() -> void:
	host.chat_keyboard_lift_active = true
	host.chat_keyboard_focus_active = true
	host.chat_keyboard_lift_hold_seconds = 0.9
	host.chat_keyboard_lift_zero_seconds = 0.0
	host.chat_keyboard_was_visible = false
	host.chat_keyboard_close_submit_done = false
	host.chat_keyboard_lift_viewport_height = maxf(host.chat_keyboard_lift_viewport_height, host.get_viewport_rect().size.y)
	_process_chat_keyboard_lift(1.0)

func _on_chat_input_focus_exited() -> void:
	var should_submit_web_keyboard_done := _chat_web_mobile_keyboard_platform() and _chat_keyboard_done_submit_ready()
	host.chat_keyboard_focus_active = false
	host.chat_keyboard_preview_keyboard_visible = false
	_hide_chat_keyboard_preview()
	if should_submit_web_keyboard_done:
		call_deferred("_chat_submit_web_keyboard_done")
	if _chat_mobile_keyboard_platform():
		host.chat_keyboard_lift_hold_seconds = 0.20
		return
	_reset_chat_keyboard_lift()

func _reset_chat_keyboard_lift() -> void:
	host.chat_keyboard_lift_active = false
	host.chat_keyboard_lift_pixels = 0.0
	host.chat_keyboard_lift_hold_seconds = 0.0
	host.chat_keyboard_lift_last_height = 0.0
	host.chat_keyboard_lift_target_pixels = 0.0
	host.chat_keyboard_lift_viewport_height = 0.0
	host.chat_keyboard_lift_window_height = 0.0
	host.chat_keyboard_lift_zero_seconds = 0.0
	host.chat_keyboard_preview_keyboard_visible = false
	host.chat_keyboard_was_visible = false
	host.chat_keyboard_close_submit_done = false
	host.chat_keyboard_focus_active = false
	_hide_chat_keyboard_preview()

func _collapse_chat_keyboard_lift_after_submit() -> void:
	host.chat_keyboard_lift_active = false
	host.chat_keyboard_focus_active = false
	host.chat_keyboard_lift_hold_seconds = 0.0
	host.chat_keyboard_lift_last_height = 0.0
	host.chat_keyboard_lift_target_pixels = 0.0
	host.chat_keyboard_lift_zero_seconds = 0.0
	host.chat_keyboard_preview_keyboard_visible = false
	host.chat_keyboard_close_submit_done = true
	_hide_chat_keyboard_preview()

func _chat_keyboard_height_canvas_units(raw_keyboard_height: float) -> float:
	var viewport_height := maxf(1.0, host.get_viewport_rect().size.y)
	var window_height := viewport_height
	if DisplayServer.get_name() != "headless":
		window_height = maxf(1.0, float(DisplayServer.window_get_size().y))
	host.chat_keyboard_lift_viewport_height = maxf(host.chat_keyboard_lift_viewport_height, viewport_height)
	host.chat_keyboard_lift_window_height = maxf(host.chat_keyboard_lift_window_height, window_height)
	var height_from_keyboard := 0.0
	if raw_keyboard_height > 0.0:
		height_from_keyboard = raw_keyboard_height * viewport_height / maxf(1.0, host.chat_keyboard_lift_window_height)
	var height_from_resize := 0.0
	if host.chat_keyboard_lift_window_height > window_height + 1.0:
		height_from_resize = (host.chat_keyboard_lift_window_height - window_height) * viewport_height / maxf(1.0, host.chat_keyboard_lift_window_height)
	return maxf(height_from_keyboard, height_from_resize)

func _update_chat_keyboard_preview() -> void:
	if host.chat_keyboard_preview == null or not is_instance_valid(host.chat_keyboard_preview):
		return
	if host.chat_keyboard_preview_label == null or not is_instance_valid(host.chat_keyboard_preview_label):
		return
	var should_show: bool = host.chat_overlay != null and host.chat_overlay.visible and _chat_mobile_keyboard_platform() and host.chat_keyboard_preview_keyboard_visible
	host._set_canvas_item_visible_if_changed(host.chat_keyboard_preview, should_show)
	if not should_show:
		return
	var preview_text: String = host.chat_draft_message.strip_edges()
	if preview_text.is_empty():
		host.chat_keyboard_preview_label.text = "Send a message..."
		host.chat_keyboard_preview_label.add_theme_color_override("font_color", Color("#8a8175"))
	else:
		host.chat_keyboard_preview_label.text = host.chat_draft_message
		host.chat_keyboard_preview_label.add_theme_color_override("font_color", host.COLOR_INK)
	host.chat_keyboard_preview.offset_top = -host.chat_keyboard_lift_pixels - host.CHAT_KEYBOARD_PREVIEW_HEIGHT - 22.0
	host.chat_keyboard_preview.offset_bottom = -host.chat_keyboard_lift_pixels - 22.0

func _hide_chat_keyboard_preview() -> void:
	if host.chat_keyboard_preview != null and is_instance_valid(host.chat_keyboard_preview):
		host._set_canvas_item_visible_if_changed(host.chat_keyboard_preview, false)

func _process_chat_keyboard_lift(delta: float) -> void:
	if host.chat_overlay_body == null or not is_instance_valid(host.chat_overlay_body):
		return
	var target := 0.0
	var is_mobile_keyboard := _chat_mobile_keyboard_platform()
	var raw_keyboard_height := 0.0
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		raw_keyboard_height = float(DisplayServer.virtual_keyboard_get_height())
		if raw_keyboard_height > 0.0:
			host.chat_keyboard_lift_active = true
			host.chat_keyboard_lift_zero_seconds = 0.0
			host.chat_keyboard_was_visible = true
		else:
			host.chat_keyboard_preview_keyboard_visible = false
			_hide_chat_keyboard_preview()
			host.chat_keyboard_lift_zero_seconds += delta
			if not host.chat_keyboard_focus_active and host.chat_keyboard_lift_zero_seconds > 0.85:
				host.chat_keyboard_lift_active = false
	if host.chat_overlay != null and host.chat_overlay.visible and is_mobile_keyboard and (host.chat_keyboard_focus_active or host.chat_keyboard_lift_active or raw_keyboard_height > 0.0 or host.chat_keyboard_lift_hold_seconds > 0.0):
		var viewport_height := maxf(host.chat_keyboard_lift_viewport_height, host.get_viewport_rect().size.y)
		var keyboard_height := _chat_keyboard_height_canvas_units(raw_keyboard_height)
		host.chat_keyboard_preview_keyboard_visible = keyboard_height > 1.0
		if keyboard_height > 0.0:
			host.chat_keyboard_lift_last_height = keyboard_height
			host.chat_keyboard_lift_hold_seconds = 0.9
		elif host.chat_keyboard_lift_hold_seconds > 0.0:
			host.chat_keyboard_lift_hold_seconds = maxf(0.0, host.chat_keyboard_lift_hold_seconds - delta)
			keyboard_height = host.chat_keyboard_lift_last_height * clampf(host.chat_keyboard_lift_hold_seconds / 0.20, 0.0, 1.0)
		if keyboard_height > 0.0:
			host.chat_keyboard_lift_target_pixels = clampf(keyboard_height - host.BOTTOM_NAV_HEIGHT + 128.0, 0.0, viewport_height * 0.72)
		else:
			host.chat_keyboard_lift_target_pixels = 0.0
		target = host.chat_keyboard_lift_target_pixels
	else:
		host.chat_keyboard_preview_keyboard_visible = false
		_reset_chat_keyboard_lift()
	var t := clampf(delta * 12.0, 0.0, 1.0)
	host.chat_keyboard_lift_pixels = lerpf(host.chat_keyboard_lift_pixels, target, t)
	if absf(host.chat_keyboard_lift_pixels - target) < 1.0:
		host.chat_keyboard_lift_pixels = target
	host.chat_overlay_body.offset_bottom = -host.chat_keyboard_lift_pixels
	if host.chat_keyboard_fill != null and is_instance_valid(host.chat_keyboard_fill):
		host._set_canvas_item_visible_if_changed(host.chat_keyboard_fill, host.chat_keyboard_lift_pixels > 1.0)
		host.chat_keyboard_fill.offset_top = -host.chat_keyboard_lift_pixels - 8.0
	_update_chat_keyboard_preview()
	if host.chat_keyboard_focus_active:
		_chat_scroll_to_latest()

func _chat_scroll_to_latest_deferred(attempts_remaining := 4) -> void:
	call_deferred("_chat_scroll_to_latest", attempts_remaining)

func _chat_scroll_to_latest(attempts_remaining := 0) -> void:
	if host.chat_overlay_scroll == null or not is_instance_valid(host.chat_overlay_scroll):
		if attempts_remaining > 0:
			call_deferred("_chat_scroll_to_latest", attempts_remaining - 1)
		return
	host.chat_overlay_scroll.scroll_vertical = host.chat_overlay_scroll.get_max_scroll_vertical()
	if attempts_remaining > 0:
		call_deferred("_chat_scroll_to_latest", attempts_remaining - 1)

func _route_chat_overlay_key_input(event: InputEvent) -> bool:
	if host.chat_overlay == null or not host.chat_overlay.visible:
		return false
	if _chat_mobile_keyboard_platform() and not _chat_submit_event_pressed(event):
		return false
	if _chat_submit_event_pressed(event):
		_chat_submit_current_draft()
		return true
	return false

func _on_chat_input_gui_input(event: InputEvent) -> void:
	if _chat_submit_event_pressed(event):
		if host.chat_message_edit != null and is_instance_valid(host.chat_message_edit):
			host.chat_message_edit.accept_event()
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
	return host.chat_message_edit != null and is_instance_valid(host.chat_message_edit) and host.chat_message_edit.has_focus() and host.chat_message_edit.is_visible_in_tree()

func _process_chat_enter_submit_poll() -> void:
	if not _chat_input_has_focus():
		host.chat_enter_submit_armed = true
		return
	var enter_down: bool = Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
	if not enter_down:
		host.chat_enter_submit_armed = true
		return
	if not host.chat_enter_submit_armed:
		return
	host.chat_enter_submit_armed = false
	_chat_submit_current_draft()

func _chat_submit_current_draft() -> void:
	var text: String = host.chat_draft_message
	if host.chat_message_edit != null and is_instance_valid(host.chat_message_edit):
		text = host.chat_message_edit.text
	_chat_send_pressed(text)
	_chat_finish_mobile_submit_attempt()

func _chat_queue_submit_current_draft() -> void:
	if host.chat_submit_deferred:
		return
	host.chat_submit_deferred = true
	call_deferred("_chat_submit_current_draft_deferred")

func _chat_submit_current_draft_deferred() -> void:
	host.chat_submit_deferred = false
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
	if host.chat_keyboard_close_submit_done or host.chat_send_in_flight:
		return false
	var text: String = host.chat_draft_message
	if host.chat_message_edit != null and is_instance_valid(host.chat_message_edit):
		text = host.chat_message_edit.text
	return not host.ChatState.sanitize_message(text, host.CHAT_MESSAGE_MAX_CHARS, host.CHAT_CENSORED_WORDS).is_empty()

func _chat_submit_web_keyboard_done() -> void:
	if not _chat_web_mobile_keyboard_platform() or not _chat_keyboard_done_submit_ready():
		return
	if host.chat_overlay == null or not host.chat_overlay.visible:
		return
	_chat_submit_current_draft()

func _chat_finish_mobile_submit_attempt() -> void:
	if not _chat_mobile_keyboard_platform():
		return
	if host.chat_message_edit != null and is_instance_valid(host.chat_message_edit):
		host.chat_message_edit.release_focus()
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		DisplayServer.virtual_keyboard_hide()
	_collapse_chat_keyboard_lift_after_submit()

func _chat_send_pressed(text: String) -> void:
	host._button_press_runtime().play_default_button_sfx()
	host.chat_draft_message = text
	host._online_runtime().send_chat(text)

func _chat_send_button() -> Button:
	var button: Button = host._menu_button("Send")
	button.custom_minimum_size = Vector2(220, 150)
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

func _open_profile_overlay() -> void:
	host._online_runtime().ensure_leaderboard_http()
	_ensure_profile_overlay()
	if profile_overlay == null:
		return
	profile_avatar_picker_open = false
	_rebuild_profile_overlay()
	host._set_canvas_item_visible_if_changed(profile_overlay, true)

func _on_profile_overlay_gui_input(event: InputEvent) -> void:
	if host._event_is_outside_panel_press(event, profile_panel):
		_save_profile_and_close()

func _on_profile_name_submitted(_submitted_text: String) -> void:
	_save_profile_and_close()

func _sync_pending_profile_name_edit() -> void:
	if host.leaderboard_profile_claimed or profile_name_edit == null or not is_instance_valid(profile_name_edit):
		return
	host.leaderboard_display_name = LeaderboardProfile.sanitize_display_name(profile_name_edit.text, host.PROFILE_DISPLAY_NAME_MAX_CHARS)
	host.leaderboard_name_key = ""
	if LeaderboardProfile.is_default_display_name(host.leaderboard_display_name, host.PROFILE_DISPLAY_NAME_MAX_CHARS):
		host.leaderboard_display_name = LeaderboardProfile.make_guest_display_name(host.PROFILE_GUEST_NAME_PREFIX)

func _toggle_profile_avatar_picker() -> void:
	_sync_pending_profile_name_edit()
	profile_avatar_picker_open = not profile_avatar_picker_open
	_rebuild_profile_overlay()

func _save_profile_and_close() -> void:
	if not host.leaderboard_profile_claimed and profile_name_edit != null and is_instance_valid(profile_name_edit):
		host.leaderboard_display_name = LeaderboardProfile.sanitize_display_name(profile_name_edit.text, host.PROFILE_DISPLAY_NAME_MAX_CHARS)
		host.leaderboard_name_key = ""
		host.leaderboard_name_claim_verified = false
	if LeaderboardProfile.is_default_display_name(host.leaderboard_display_name, host.PROFILE_DISPLAY_NAME_MAX_CHARS):
		host.leaderboard_display_name = LeaderboardProfile.make_guest_display_name(host.PROFILE_GUEST_NAME_PREFIX)
		host.leaderboard_name_key = ""
	_hide_profile_overlay()
	host.save_game()
	if host.current_screen == "leaderboard":
		host._render_screen()

func _select_profile_avatar(index: int) -> void:
	var new_avatar_index: int = LeaderboardProfile.valid_avatar_index(index, PROFILE_AVATAR_COUNT)
	if host.leaderboard_avatar_index == new_avatar_index:
		profile_avatar_picker_open = false
		_rebuild_profile_overlay()
		return
	host.leaderboard_avatar_index = new_avatar_index
	_sync_pending_profile_name_edit()
	profile_avatar_picker_open = false
	host._online_runtime()._refresh_profile_references()
	host.save_game()
	_rebuild_profile_overlay()
	if host.current_screen == "leaderboard":
		host._render_screen()

func _create_leaderboard_account() -> void:
	if host.leaderboard_profile_claimed or host.leaderboard_name_claim_in_flight:
		return
	var chosen_name: String = host.leaderboard_display_name
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
	profile_overlay_layer.layer = host.PROFILE_OVERLAY_CANVAS_LAYER
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
	profile_panel.custom_minimum_size = Vector2(1540, 2020)
	profile_panel.add_theme_stylebox_override("panel", host._surface_style(host.COLOR_PANEL, host.CARD_RADIUS, 72, true))
	center.add_child(profile_panel)
	profile_content_stack = VBoxContainer.new()
	profile_content_stack.add_theme_constant_override("separation", 34)
	profile_panel.add_child(profile_content_stack)

func _rebuild_profile_overlay() -> void:
	if profile_content_stack == null:
		return
	if profile_panel != null:
		profile_panel.custom_minimum_size = Vector2(1540, 2020 if profile_avatar_picker_open else 1280)
	for child in profile_content_stack.get_children():
		child.queue_free()
	profile_avatar_buttons.clear()
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	profile_content_stack.add_child(header)
	var title = host._label("Profile", 124, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close = host._menu_button("Done")
	close.custom_minimum_size = Vector2(300, 154)
	close.pressed.connect(_save_profile_and_close)
	header.add_child(close)

	var identity_row = HBoxContainer.new()
	identity_row.alignment = BoxContainer.ALIGNMENT_CENTER
	identity_row.add_theme_constant_override("separation", 42)
	profile_content_stack.add_child(identity_row)
	identity_row.add_child(_profile_avatar_change_button())
	var name_stack = VBoxContainer.new()
	name_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_stack.add_theme_constant_override("separation", 18)
	identity_row.add_child(name_stack)
	profile_name_edit = LineEdit.new()
	profile_name_edit.text = host.leaderboard_display_name
	profile_name_edit.placeholder_text = "Username"
	profile_name_edit.max_length = host.PROFILE_DISPLAY_NAME_MAX_CHARS
	profile_name_edit.custom_minimum_size = Vector2(0, 150)
	profile_name_edit.focus_mode = Control.FOCUS_ALL
	profile_name_edit.editable = not host.leaderboard_profile_claimed
	profile_name_edit.add_theme_font_size_override("font_size", 66)
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
	profile_status_label = host._label(_profile_status_text(), host.MIN_MOBILE_BODY_FONT_SIZE, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	profile_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	profile_status_label.custom_minimum_size = Vector2(0, 112)
	name_stack.add_child(profile_status_label)
	var cloud_status = host._label(host._online_runtime().cloud_save_status_text(), host.MIN_MOBILE_BODY_FONT_SIZE, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	cloud_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cloud_status.custom_minimum_size = Vector2(0, 136)
	name_stack.add_child(cloud_status)
	if (
		host.leaderboard_auth_provider != "google"
		and LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS)
	):
		var google_button = host._menu_button("Connect Google")
		google_button.custom_minimum_size = Vector2(0, 132)
		google_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		google_button.disabled = host.google_auth_in_flight or host.leaderboard_auth_in_flight
		if host.google_auth_in_flight or host.leaderboard_auth_in_flight:
			google_button.text = "Connecting..."
		google_button.pressed.connect(host._start_google_account_sign_in)
		name_stack.add_child(google_button)

	if not host.leaderboard_profile_claimed:
		var account_button = host._menu_button("Save Username")
		account_button.custom_minimum_size = Vector2(0, 154)
		account_button.disabled = host.leaderboard_name_claim_in_flight
		if host.leaderboard_name_claim_in_flight:
			account_button.text = "Checking..."
		account_button.pressed.connect(_create_leaderboard_account)
		name_stack.add_child(account_button)

	if profile_avatar_picker_open:
		var grid = GridContainer.new()
		grid.columns = PROFILE_AVATAR_COLUMNS
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 24)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		profile_content_stack.add_child(grid)
		for i in range(PROFILE_AVATAR_COUNT):
			var avatar_button = _profile_avatar_picker_button(i)
			profile_avatar_buttons.append(avatar_button)
			grid.add_child(avatar_button)

func _profile_avatar_change_button() -> Button:
	var button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(310, 310)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.clip_contents = true
	button.add_theme_stylebox_override("normal", _profile_avatar_button_style(true, false))
	button.add_theme_stylebox_override("hover", _profile_avatar_button_style(true, false, true))
	button.add_theme_stylebox_override("pressed", _profile_avatar_button_style(true, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host._button_press_runtime().attach_button_depress_animation(button, 0.94)
	button.pressed.connect(_toggle_profile_avatar_picker)
	var art = host.visual_texture_cache._image_from_texture(_profile_avatar_texture(host.leaderboard_avatar_index), Vector2(310, 310))
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(art)
	button.add_child(_profile_avatar_border_overlay(true))
	return button

func _profile_avatar_picker_button(index: int) -> Button:
	var selected = LeaderboardProfile.valid_avatar_index(index, PROFILE_AVATAR_COUNT) == host.leaderboard_avatar_index
	var button = Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(250, 250)
	button.focus_mode = Control.FOCUS_NONE
	button.clip_contents = true
	button.add_theme_stylebox_override("normal", _profile_avatar_button_style(selected, false))
	button.add_theme_stylebox_override("hover", _profile_avatar_button_style(selected, false, true))
	button.add_theme_stylebox_override("pressed", _profile_avatar_button_style(selected, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host._button_press_runtime().attach_button_depress_animation(button, 0.94)
	button.pressed.connect(_select_profile_avatar.bind(index))
	var art = host.visual_texture_cache._image_from_texture(_profile_avatar_texture(index), Vector2(250, 250))
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

func _profile_avatar_frame(index: int, minimum_size: Vector2, selected := false) -> PanelContainer:
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
	if host.leaderboard_name_claim_in_flight:
		return "Checking username..."
	if host.leaderboard_profile_claimed:
		return "Username saved."
	return "Choose a username for rankings."

func _profile_avatar_frame_background_style(selected := false) -> StyleBoxFlat:
	return LeaderboardStyles.avatar_frame_background(selected, Callable(host, "_theme_surface_color"))

func _profile_avatar_frame_style(selected := false) -> StyleBoxFlat:
	return LeaderboardStyles.avatar_frame(selected, host.COLOR_INK, PROFILE_AVATAR_FRAME_BORDER)

func _profile_avatar_button_style(selected := false, pressed := false, hovered := false) -> StyleBoxFlat:
	return LeaderboardStyles.avatar_button(selected, pressed, hovered, Callable(host, "_theme_surface_color"))

func _profile_avatar_border_overlay_style(selected := false) -> StyleBoxFlat:
	return _profile_avatar_frame_style(selected)

func _profile_name_field_style(focused := false) -> StyleBoxFlat:
	return LeaderboardStyles.name_field(
		focused,
		host.COLOR_INK,
		host.COLOR_BLUE,
		Callable(host, "_theme_surface_color"),
		Callable(host, "_theme_outline_color")
	)

