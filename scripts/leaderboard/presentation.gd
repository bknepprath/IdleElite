class_name LeaderboardPresentation
const GameFormatting = preload("res://scripts/core/formatting.gd")
const LeaderboardProfile = preload("res://scripts/leaderboard/profile.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ICON := "res://assets/content/ui/leaderboard-podium-icon.png"
const BOTTOM_SCROLL_PAD := 360
const BASE_FRAME_WIDTH := 1080
const PLAYER_OVERLAY_HEIGHT := 380
const TEXT_OUTLINE_WIDTH := 5
const FRAME_STROKE_WIDTH := 3
var host
var sync_title_label: Label
var sync_detail_label: Label
var displayed_local_score_key: Array = []
class OrganicLeaderboardBorder extends Control:
	var border_color := Color("#77c9ff")
	var paper_color := Color("#f8f1e5")
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()
	func _draw() -> void:
		if size.x <= 220.0 or size.y <= 320.0:
			return
		draw_rect(Rect2(Vector2.ZERO, size), border_color)
		var paper_shape := _inner_paper_shape()
		draw_polygon(paper_shape, PackedColorArray([paper_color]))
		var paper_edge := PackedVector2Array(paper_shape)
		if not paper_edge.is_empty():
			paper_edge.append(paper_edge[0])
			draw_polyline(paper_edge, paper_color, 43.0, true)
	func _inner_paper_shape() -> PackedVector2Array:
		var points := []
		var left_top_side := Vector2(52.0, 260.0)
		var top_left := Vector2(119.0, 135.0)
		var top_mid := Vector2(size.x * 0.50, 123.0)
		var top_right := Vector2(size.x - 107.0, 135.0)
		var right_top_side := Vector2(size.x - 52.0, 260.0)
		var right_mid := Vector2(size.x - 48.0, size.y * 0.48)
		var right_bottom := Vector2(size.x - 56.0, size.y + 90.0)
		var left_bottom := Vector2(56.0, size.y + 90.0)
		var left_mid := Vector2(52.0, size.y * 0.48)
		points.append(left_top_side)
		_append_leaderboard_curve(points, left_top_side, Vector2(54.0, 191.0), Vector2(63.0, 150.0), top_left, 96)
		_append_leaderboard_curve(points, top_left, Vector2(172.0, 108.0), Vector2(size.x * 0.34, 122.0), top_mid, 112)
		_append_leaderboard_curve(points, top_mid, Vector2(size.x * 0.66, 122.0), Vector2(size.x - 165.0, 108.0), top_right, 112)
		_append_leaderboard_curve(points, top_right, Vector2(size.x - 59.0, 150.0), Vector2(size.x - 54.0, 191.0), right_top_side, 96)
		_append_leaderboard_curve(points, right_top_side, Vector2(size.x - 39.0, size.y * 0.30), Vector2(size.x - 59.0, size.y * 0.36), right_mid, 128)
		_append_leaderboard_curve(points, right_mid, Vector2(size.x - 36.0, size.y * 0.64), Vector2(size.x - 56.0, size.y * 0.86), right_bottom, 128)
		points.append(left_bottom)
		_append_leaderboard_curve(points, left_bottom, Vector2(56.0, size.y * 0.86), Vector2(36.0, size.y * 0.64), left_mid, 128)
		_append_leaderboard_curve(points, left_mid, Vector2(59.0, size.y * 0.36), Vector2(39.0, size.y * 0.30), left_top_side, 128)
		return PackedVector2Array(points)
	func _append_leaderboard_curve(points: Array, p0: Vector2, c1: Vector2, c2: Vector2, p3: Vector2, steps: int) -> void:
		for i in range(1, steps + 1):
			var t := float(i) / float(steps)
			var inv := 1.0 - t
			points.append(inv * inv * inv * p0 + 3.0 * inv * inv * t * c1 + 3.0 * inv * t * t * c2 + t * t * t * p3)
static func dropdown(color: Color, pressed := false, ink_color := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.06 if pressed else 0.0)
	style.border_color = ink_color
	style.set_border_width_all(FRAME_STROKE_WIDTH)
	style.set_corner_radius_all(23)
	style.content_margin_left = 35
	style.content_margin_right = 35
	style.content_margin_top = 21 + (3 if pressed else 0)
	style.content_margin_bottom = 21 - (2 if pressed else 0)
	style.shadow_color = Color(0.08, 0.07, 0.06, 0.28 if not pressed else 0.14)
	style.shadow_size = 5 if not pressed else 4
	style.shadow_offset = Vector2(0, 4 if not pressed else 2)
	return style
static func player_card(color: Color, pressed := false, ink_color := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.06 if pressed else 0.0)
	style.border_color = ink_color
	style.set_border_width_all(FRAME_STROKE_WIDTH)
	style.set_corner_radius_all(29)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20 + (3 if pressed else 0)
	style.content_margin_bottom = 20 - (2 if pressed else 0)
	style.shadow_color = Color(0.08, 0.07, 0.06, 0.32 if not pressed else 0.16)
	style.shadow_size = 6 if not pressed else 5
	style.shadow_offset = Vector2(0, 5 if not pressed else 2)
	return style
static func rank_badge() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style
func _init(host_ref = null) -> void:
	host = host_ref
func _show_leaderboard() -> void:
	if not host._navigation_shell()._top_level_nav_allowed("leaderboard"):
		return
	host._online_runtime().ensure_leaderboard_http()
	if host.current_screen == "settings":
		host._settings_surface()._disarm_reset_data_confirmation()
	host.current_screen = "leaderboard"
	var leaderboard_state = host.leaderboard_state
	host._online_runtime().fetch_leaderboard_category(leaderboard_state.valid_category_id(leaderboard_state.category_id))
	if leaderboard_state.submit_ready():
		host._online_runtime().submit_leaderboard_scores()
	host.button_press_runtime.play_default_button_sfx()
	host._navigation_shell()._render_screen()


func _render_leaderboard_page() -> void:
	if host.desktop_layout.enabled() and host.desktop_layout.social_tab == "scores":
		_render_desktop_leaderboard()
		return
	host.skills_content.offset_top = 0.0
	var background := ColorRect.new()
	background.color = Color("#77c9ff")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.skills_content.add_child(background)
	host.content_scroll = MobileScrollContainer.new()
	host.content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host.content_scroll.set_pull_resistance_enabled(true)
	host.content_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.content_scroll.offset_left = 0
	host.content_scroll.offset_right = 0
	host.content_scroll.offset_top = 0
	host.content_scroll.offset_bottom = 0
	host.skills_content.add_child(host.content_scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = _leaderboard_frame_width()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	host.content_scroll.add_child(stack)

	var rows = _display_rows_for_category(host.leaderboard_state.category_id)
	displayed_local_score_key = _local_score_key()
	var page_frame = _leaderboard_page_frame(rows)
	stack.add_child(page_frame)
	if host.desktop_layout.enabled() and host.desktop_layout.social_tab == "scores":
		var status = host._label(_player_sync_status().title, 42, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
		status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		status.offset_top = -80
		status.offset_bottom = -16
		host.skills_content.add_child(status)
	else:
		host.skills_content.add_child(_leaderboard_player_overlay())


func _render_desktop_leaderboard() -> void:
	var desktop = host.desktop_layout
	var scroll := MobileScrollContainer.new()
	scroll.name = "DesktopRankingsScroll"
	desktop.style_scroll(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.skills_content.add_child(scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = desktop.SOCIAL_WIDTH - desktop.EDGE - 80
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 24)
	scroll.add_child(stack)
	var dropdown := _leaderboard_category_dropdown()
	dropdown.custom_minimum_size = Vector2(0, 100)
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desktop.style_button(dropdown, true)
	stack.add_child(dropdown)
	var rows := _display_rows_for_category(host.leaderboard_state.category_id)
	displayed_local_score_key = _local_score_key()
	if rows.is_empty():
		var empty := _leaderboard_empty_state()
		empty.add_theme_stylebox_override("panel", desktop.panel_style(desktop.panel_fill()))
		desktop.soften_labels(empty, 40)
		stack.add_child(empty)
	else:
		for i in range(rows.size()): stack.add_child(_leaderboard_row(i + 1, rows[i]))
	var status = host._label(_player_sync_status().title, 36, desktop.panel_ink(), HORIZONTAL_ALIGNMENT_LEFT)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(status)


func _local_score_key() -> Array:
	var state = host.leaderboard_state
	return [state.category_id, state.score_for_category(state.category_id), state.total_xp_for_category(state.category_id), host.leaderboard_profile.player_id, host.leaderboard_profile.display_name, host.leaderboard_profile.avatar_index, host.god_mode_save_tainted]


func _display_rows_for_category(category_id: String) -> Array:
	var state = host.leaderboard_state
	var valid_id: String = state.valid_category_id(category_id)
	var server_rows: Array = state.rows_for_category(valid_id)
	if host.god_mode_save_tainted:
		return server_rows
	var local_row := {
		"player_id": host.leaderboard_profile.player_id,
		"name": host.leaderboard_profile.display_name,
		"avatar_index": host.leaderboard_profile.avatar_index,
		"score": state.score_for_category(valid_id),
		"total_xp": state.total_xp_for_category(valid_id),
		"skill_level": state.skill_level_for_category(valid_id),
	}
	local_row["score_text"] = format_score(valid_id, local_row.score, local_row.skill_level, local_row.total_xp, state.CATEGORY_TOTAL_LEVEL, state.CATEGORY_MEDALS, state.CATEGORY_ELITE_HEAVENLY, state.CATEGORY_SKILL_PREFIX, Callable(state, "skill_level_from_total_xp"))
	return rows_with_local_score(server_rows, local_row, valid_id == state.CATEGORY_TOTAL_LEVEL, state.TOP_COUNT, state.fetch_unix_by_category.has(valid_id))


func _leaderboard_page_frame(rows: Array) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(_leaderboard_frame_width(), _leaderboard_page_frame_height(rows.size()))
	for row_data in rows:
		if bool(row_data.get("local_fallback", false)):
			frame.custom_minimum_size.y += 60.0
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.clip_contents = false
	var border := OrganicLeaderboardBorder.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(border)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 95)
	margin.add_theme_constant_override("margin_right", 95)
	margin.add_theme_constant_override("margin_top", 150)
	margin.add_theme_constant_override("margin_bottom", 165)
	frame.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_BEGIN
	stack.add_theme_constant_override("separation", 20)
	margin.add_child(stack)
	var title = host._label_on_light_panel("Leaderboard", 80, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", host.app_bold_font)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(title)

	stack.add_child(_leaderboard_category_dropdown())

	var list_stack := VBoxContainer.new()
	list_stack.custom_minimum_size = Vector2(790, 0)
	list_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list_stack.add_theme_constant_override("separation", 10)
	stack.add_child(list_stack)
	if rows.is_empty():
		list_stack.add_child(_leaderboard_empty_state())
	else:
		for i in range(rows.size()):
			list_stack.add_child(_leaderboard_row(i + 1, rows[i] as Dictionary))
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, BOTTOM_SCROLL_PAD)
	list_stack.add_child(bottom_spacer)
	return frame


func _leaderboard_frame_width() -> float:
	if host.desktop_layout.enabled() and host.desktop_layout.social_tab == "scores":
		return host.desktop_layout.SOCIAL_WIDTH - host.desktop_layout.EDGE
	return maxf(BASE_FRAME_WIDTH, host._current_canvas_size().x)

func _leaderboard_page_frame_height(row_count: int) -> float:
	var content_height = 520.0 + float(row_count) * 130.0 + float(BOTTOM_SCROLL_PAD) + PLAYER_OVERLAY_HEIGHT + 64.0
	return maxf(content_height, host._current_canvas_size().y)

func _leaderboard_player_overlay() -> Control:
	var overlay := Control.new()
	var content_width = host._skill_content_width()
	overlay.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	overlay.offset_left = -content_width * 0.5
	overlay.offset_right = content_width * 0.5
	overlay.offset_top = -float(PLAYER_OVERLAY_HEIGHT)
	overlay.offset_bottom = -17.0
	overlay.z_index = 32
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := _leaderboard_player_card()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 28
	card.offset_right = -28
	card.offset_top = 12
	card.offset_bottom = -12
	overlay.add_child(card)
	return overlay

func _leaderboard_category_dropdown() -> Button:
	if host.desktop_layout.enabled() and host.desktop_layout.social_tab == "scores":
		var categories: Array = host.leaderboard_state.categories()
		var selected: int = host.leaderboard_state.selected_category_index()
		var dropdown: Button = host.desktop_layout.make_button(str(categories[selected].label) + "  ▾")
		dropdown.pressed.connect(func():
			var entries: Array = []
			for category in categories: entries.append({"text": str(category.label)})
			host.desktop_layout.open_selector(dropdown, entries, selected, _leaderboard_category_selected)
		)
		return dropdown
	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size = Vector2(620, 110)
	dropdown.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dropdown.focus_mode = Control.FOCUS_NONE
	dropdown.fit_to_longest_item = false
	dropdown.alignment = HORIZONTAL_ALIGNMENT_CENTER
	dropdown.add_theme_font_size_override("font_size", 48)
	if host.app_bold_font != null:
		dropdown.add_theme_font_override("font", host.app_bold_font)
	dropdown.add_theme_stylebox_override("normal", LeaderboardPresentation.dropdown(Color("#e8f6ff"), false, host.COLOR_INK))
	dropdown.add_theme_stylebox_override("hover", LeaderboardPresentation.dropdown(Color("#f4fbff"), false, host.COLOR_INK))
	dropdown.add_theme_stylebox_override("pressed", LeaderboardPresentation.dropdown(Color("#cfefff"), true, host.COLOR_INK))
	dropdown.add_theme_color_override("font_color", host.COLOR_INK)
	dropdown.add_theme_color_override("font_pressed_color", host.COLOR_INK)
	dropdown.add_theme_color_override("font_hover_color", host.COLOR_INK)
	var leaderboard_state = host.leaderboard_state
	var categories = leaderboard_state.categories()
	for i in range(categories.size()):
		var category := categories[i] as Dictionary
		var id := str(category.get("id", ""))
		dropdown.add_item(str(category.get("label", id)))
	dropdown.select(leaderboard_state.selected_category_index())
	var popup := dropdown.get_popup()
	if popup != null:
		popup.add_theme_font_size_override("font_size", 48)
		popup.add_theme_constant_override("v_separation", 13)
		if host.app_bold_font != null:
			popup.add_theme_font_override("font", host.app_bold_font)
	dropdown.item_selected.connect(_leaderboard_category_selected)
	return dropdown

func _leaderboard_category_selected(index: int) -> void:
	var category_id: String = host.leaderboard_state.select_category_index(index)
	if category_id.is_empty():
		return
	host._online_runtime().fetch_leaderboard_category(category_id)
	_refresh_if_visible()

func _refresh_if_visible() -> void:
	if host.desktop_layout.enabled() and host.desktop_layout.social_tab == "scores":
		host.desktop_layout.refresh_scores()
		return
	if host.current_screen != "leaderboard" or host.skills_content == null or not is_instance_valid(host.skills_content):
		return
	host._app_lifecycle_runtime()._kill_transient_tweens_in_subtree(host.skills_content)
	host._clear(host.skills_content)
	_render_leaderboard_page()
	host._navigation_shell()._update_page_visibility()

func _leaderboard_player_card() -> Control:
	var leaderboard_state = host.leaderboard_state
	var category_id = leaderboard_state.valid_category_id(leaderboard_state.category_id)
	var player_score = leaderboard_state.score_for_category(category_id)
	var card := Button.new()
	card.text = ""
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("normal", LeaderboardPresentation.player_card(Color("#d8f5ff"), false, host.COLOR_INK))
	card.add_theme_stylebox_override("hover", LeaderboardPresentation.player_card(Color("#e7f9ff"), false, host.COLOR_INK))
	card.add_theme_stylebox_override("pressed", LeaderboardPresentation.player_card(Color("#beeaff"), true, host.COLOR_INK))
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	card.pressed.connect(host._profile_chat_overlay_surface().open_profile_overlay)
	host.button_press_runtime.attach_button_depress_animation(card, 0.986)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 19)
	margin.add_theme_constant_override("margin_right", 19)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var row := Control.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var avatar: Control = host._profile_chat_overlay_surface().profile_avatar_frame(host.leaderboard_profile.avatar_index, Vector2(116, 116), true, FRAME_STROKE_WIDTH)
	avatar.anchor_left = 0.0
	avatar.anchor_right = 0.0
	avatar.anchor_top = 0.5
	avatar.anchor_bottom = 0.5
	avatar.offset_left = 0.0
	avatar.offset_right = 116.0
	avatar.offset_top = -58.0
	avatar.offset_bottom = 58.0
	row.add_child(avatar)
	var copy := VBoxContainer.new()
	copy.anchor_left = 0.0
	copy.anchor_right = 1.0
	copy.anchor_top = 0.0
	copy.anchor_bottom = 1.0
	copy.offset_left = 133.0
	copy.offset_right = -357.0
	copy.offset_top = 0.0
	copy.offset_bottom = 0.0
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 1)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var score = host._label(host.leaderboard_profile.display_name, 60, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	score.clip_text = true
	score.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	score.add_theme_color_override("font_outline_color", host.COLOR_INK)
	score.add_theme_constant_override("outline_size", TEXT_OUTLINE_WIDTH)
	copy.add_child(score)
	var rank_text = LeaderboardPresentation.player_rank_text(host.leaderboard_profile.player_id, _display_rows_for_category(category_id), leaderboard_state.TOP_COUNT)
	var score_text = LeaderboardPresentation.format_score(leaderboard_state.valid_category_id(category_id), player_score, leaderboard_state.skill_level_for_category(category_id), leaderboard_state.total_xp_for_category(category_id), leaderboard_state.CATEGORY_TOTAL_LEVEL, leaderboard_state.CATEGORY_MEDALS, leaderboard_state.CATEGORY_ELITE_HEAVENLY, leaderboard_state.CATEGORY_SKILL_PREFIX, Callable(leaderboard_state, "skill_level_from_total_xp"))
	for score_line in score_text.split("  |  "):
		copy.add_child(host._label(score_line, 52, Color("#4b3828"), HORIZONTAL_ALIGNMENT_LEFT))
	var rank = host._label("Rank %s" % rank_text if rank_text.begins_with("#") else rank_text, 52, Color("#4b3828"), HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(rank)
	var status := VBoxContainer.new()
	status.anchor_left = 1.0
	status.anchor_right = 1.0
	status.anchor_top = 0.5
	status.anchor_bottom = 0.5
	status.offset_left = -340.0
	status.offset_right = 0.0
	status.offset_top = -170.0
	status.offset_bottom = 170.0
	status.alignment = BoxContainer.ALIGNMENT_CENTER
	status.add_theme_constant_override("separation", 4)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(status)
	var status_copy := _player_sync_status()
	var status_title = host._label_on_light_panel(status_copy.title, 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	status_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_title.custom_minimum_size = Vector2(340, 0)
	status.add_child(status_title)
	sync_title_label = status_title
	var detail = host._label_on_light_panel(status_copy.detail, 52, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(340, 0)
	sync_detail_label = detail
	status.add_child(detail)
	return card


func _player_sync_status() -> Dictionary:
	var state = host.leaderboard_state
	var online = host._online_runtime()
	var enabled: bool = online._leaderboard_firebase_enabled()
	var claimed: bool = LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS)
	var ready: bool = online._leaderboard_auth_ready()
	var pending: bool = state.has_pending_category_score() or state.repair_publish_due()
	var sync_info := {"error": state.submission_error, "pending": pending, "retry_wait": state.next_submit_seconds(), "recovery_required": online.leaderboard_auth_recovery_required}
	return {
		"title": submit_status_title(host.god_mode_save_tainted, enabled, claimed, ready, online.leaderboard_submit_in_flight, state.last_submit_unix, state.submit_ready(), sync_info),
		"detail": submit_status_detail(host.god_mode_save_tainted, enabled, claimed, online._leaderboard_auth_retry_wait_seconds(), online.leaderboard_auth_in_flight, ready, online.leaderboard_submit_in_flight, simple_status_message(state.status_message), state.last_submit_unix, state.queued_score(), pending, state.submit_ready(), sync_info),
	}


func update_sync_status() -> void:
	if host.current_screen != "leaderboard" or not is_instance_valid(sync_title_label) or not is_instance_valid(sync_detail_label):
		return
	if displayed_local_score_key != _local_score_key():
		var scroll_position: int = host.content_scroll.scroll_vertical
		_refresh_if_visible()
		host.content_scroll.set_deferred("scroll_vertical", scroll_position)
		return
	var status := _player_sync_status()
	sync_title_label.text = status.title
	sync_detail_label.text = status.detail


func _leaderboard_row(rank: int, row_data: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 122)
	var fill := Color("#ececec")
	if bool(row_data.get("is_player", false)):
		fill = Color("#d8f5ff")
	row.add_theme_stylebox_override("panel", host._surface_style(fill, 15, 11, false))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 17)
	row.add_child(h)
	var rank_text := str(rank)
	if bool(row_data.get("rank_unavailable", false)) or bool(row_data.get("outside_top", false)):
		rank_text = "—"
	elif bool(row_data.get("local_fallback", false)):
		rank_text = "~%s" % rank
	h.add_child(_leaderboard_rank_badge(rank_text))
	var avatar = host._profile_chat_overlay_surface().profile_avatar_frame(int(row_data.get("avatar_index", rank - 1)), Vector2(95, 95), bool(row_data.get("is_player", false)), FRAME_STROKE_WIDTH)
	h.add_child(avatar)
	var name_label = host._label(str(row_data.get("name", "Player")), 48, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	name_label.add_theme_constant_override("outline_size", TEXT_OUTLINE_WIDTH)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	h.add_child(copy)
	name_label.custom_minimum_size = Vector2(0, 54)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(name_label)
	var score_label = host._label(str(row_data.get("score_text", GameFormatting.compact_number(float(row_data.get("score", 0)), 4))), 48, Color("#ffbf35"), HORIZONTAL_ALIGNMENT_RIGHT)
	score_label.custom_minimum_size = Vector2(0, 49)
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	score_label.add_theme_constant_override("outline_size", TEXT_OUTLINE_WIDTH)
	copy.add_child(score_label)
	if bool(row_data.get("local_fallback", false)):
		row.custom_minimum_size.y += 60.0
		copy.add_child(host._label_on_light_panel("Local score", 52, host.COLOR_INK, HORIZONTAL_ALIGNMENT_RIGHT))
	if host.desktop_layout.enabled() and host.desktop_layout.social_tab == "scores":
		var desktop = host.desktop_layout
		row.add_theme_stylebox_override("panel", desktop.panel_style(desktop.inset_fill() if bool(row_data.get("is_player", false)) else desktop.panel_fill(), false, 18))
		desktop.soften_labels(row, 40)
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		score_label.add_theme_font_size_override("font_size", 36)
	return row


func _leaderboard_rank_badge(rank: String) -> Control:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(99, 77)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", LeaderboardPresentation.rank_badge())
	var label = host._label(str(rank), 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", TEXT_OUTLINE_WIDTH)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	return badge

func _leaderboard_empty_state() -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 210)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", host._surface_style(Color("#fff6e1"), 19, 15, false))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 27)
	margin.add_theme_constant_override("margin_right", 27)
	margin.add_theme_constant_override("margin_top", 23)
	margin.add_theme_constant_override("margin_bottom", 23)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 11)
	margin.add_child(stack)
	var leaderboard_state = host.leaderboard_state
	var title_text := "Loading leaderboard..."
	var detail_text := "Only this visible category is being read. There are no realtime listeners."
	if not host._online_runtime()._leaderboard_firebase_enabled():
		title_text = "Rankings offline"
		detail_text = "Online rankings are not available."
	elif not leaderboard_state.fetch_in_flight:
		title_text = "No scores yet"
		detail_text = LeaderboardPresentation.empty_state_detail_text(str(leaderboard_state.status_message))
	var title = host._label(title_text, 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(title)
	var detail = host._label(detail_text, 52, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(detail)
	return card

static func format_score(
	valid_category_id: String,
	score: int,
	skill_level: int,
	total_xp: int,
	total_level_category_id: String,
	medals_category_id: String,
	elite_category_id: String,
	skill_prefix: String,
	skill_level_from_total_xp: Callable
) -> String:
	if valid_category_id == total_level_category_id:
		if total_xp > 0:
			return "Lv %s  |  %s XP" % [score, GameFormatting.compact_number(float(total_xp), 4)]
		return "Lv %s" % score
	if valid_category_id == medals_category_id or valid_category_id == elite_category_id:
		return "%s medals" % score
	if valid_category_id.begins_with(skill_prefix):
		var level := skill_level if skill_level > 0 else int(skill_level_from_total_xp.call(score))
		return "Lv %s  |  %s XP" % [level, GameFormatting.compact_number(float(score), 4)]
	return "%s XP" % GameFormatting.compact_number(float(score), 4)

static func row_precedes(a: Dictionary, b: Dictionary, total_level: bool) -> bool:
	if int(a.get("score", 0)) != int(b.get("score", 0)):
		return int(a.get("score", 0)) > int(b.get("score", 0))
	if total_level and int(a.get("total_xp", 0)) != int(b.get("total_xp", 0)):
		return int(a.get("total_xp", 0)) > int(b.get("total_xp", 0))
	if str(a.get("name", "")) != str(b.get("name", "")):
		return str(a.get("name", "")) < str(b.get("name", ""))
	return str(a.get("player_id", "")) < str(b.get("player_id", ""))


static func rows_with_local_score(server_rows: Array, local_row: Dictionary, total_level: bool, top_count: int, board_loaded: bool) -> Array:
	# Presentation only: never add this row to the server cache or acknowledge it
	# as an upload. Failed writes must remain eligible for their normal retries.
	var rows := server_rows.duplicate(true)
	var player_id := str(local_row.get("player_id", ""))
	if player_id.is_empty() or top_count <= 0:
		return rows
	var own_row := local_row.duplicate(true)
	own_row["is_player"] = true
	own_row["local_fallback"] = true
	own_row["rank_unavailable"] = not board_loaded
	for index in range(rows.size() - 1, -1, -1):
		var server_row := rows[index] as Dictionary
		server_row["is_player"] = str(server_row.get("player_id", "")) == player_id
		if not server_row.is_player:
			continue
		var server_current := int(server_row.get("score", 0)) >= int(own_row.get("score", 0))
		if total_level:
			server_current = server_current and int(server_row.get("total_xp", 0)) >= int(own_row.get("total_xp", 0))
		if server_current:
			own_row = server_row
		rows.remove_at(index)
	rows.append(own_row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return row_precedes(a, b, total_level))
	var own_index := rows.find(own_row)
	if rows.size() > top_count:
		rows = rows.slice(0, top_count)
		if own_index >= top_count:
			own_row["outside_top"] = true
			rows.append(own_row)
	return rows


static func player_rank_text(player_id: String, rows: Array, top_count: int) -> String:
	if not player_id.is_empty():
		for index in range(rows.size()):
			if typeof(rows[index]) == TYPE_DICTIONARY and str(rows[index].get("player_id", "")) == player_id:
				if bool(rows[index].get("outside_top", false)):
					return "Outside top %s" % top_count
				if index >= top_count:
					return "Not listed"
				if bool(rows[index].get("rank_unavailable", false)):
					return "Rank unavailable"
				if bool(rows[index].get("local_fallback", false)):
					return "Est. #%s" % (index + 1)
				return "#%s" % (index + 1)
	return "Not listed"

static func submit_status_title(
	god_mode_save_tainted: bool,
	firebase_enabled: bool,
	profile_claim_valid: bool,
	auth_ready: bool,
	submit_in_flight: bool,
	last_submit_unix: int,
	submit_ready: bool,
	sync_info: Dictionary = {}
) -> String:
	if god_mode_save_tainted:
		return "Test save"
	if not firebase_enabled:
		return "Rankings offline"
	if not profile_claim_valid:
		return "Choose Username"
	if bool(sync_info.get("recovery_required", false)):
		return "Sign in"
	if not str(sync_info.get("error", "")).is_empty():
		return "Not synced"
	if not auth_ready:
		return "Connecting"
	if submit_in_flight:
		return "Updating..."
	if last_submit_unix <= 0 or submit_ready or bool(sync_info.get("pending", false)):
		return "Pending"
	return "Synced"


static func submit_status_detail(
	god_mode_save_tainted: bool,
	firebase_enabled: bool,
	profile_claim_valid: bool,
	retry_wait: int,
	auth_in_flight: bool,
	auth_ready: bool,
	submit_in_flight: bool,
	simple_status: String,
	last_submit_unix: int,
	queued_score: int,
	category_pending: bool,
	submit_ready: bool,
	sync_info: Dictionary = {}
) -> String:
	if god_mode_save_tainted:
		return "Rankings are hidden for this test save."
	if not firebase_enabled:
		return "Online rankings are not available."
	if not profile_claim_valid:
		return "Save a name to join rankings."
	if bool(sync_info.get("recovery_required", false)):
		return "Open profile to sign in."
	var wait_seconds := maxi(retry_wait, int(sync_info.get("retry_wait", 0)))
	if wait_seconds > 0 and (not str(sync_info.get("error", "")).is_empty() or bool(sync_info.get("pending", false)) or retry_wait > 0):
		return "Retry in %s." % GameFormatting.duration(float(wait_seconds))
	if auth_in_flight and not auth_ready:
		return "Connecting..."
	if not auth_ready:
		return "Scores update automatically."
	if submit_in_flight:
		return "Updating rankings..."
	if not str(sync_info.get("error", "")).is_empty():
		return "Retrying automatically."
	if not simple_status.is_empty():
		return simple_status
	if last_submit_unix <= 0:
		return "Scores update automatically."
	if queued_score <= 0 and not category_pending and not bool(sync_info.get("pending", false)):
		return "Your score is up to date."
	if submit_ready:
		return "New score ready."
	return "Waiting to upload."


static func simple_status_message(raw_status: String) -> String:
	var status := raw_status.strip_edges()
	if status.is_empty() or status == "Leaderboard loaded.":
		return ""
	if status == "Leaderboard published." or status == "Leaderboard name saved.":
		return ""
	if status.findn("failed") >= 0 or status.findn("http") >= 0 or status.findn("denied") >= 0 or status.findn("retry") >= 0:
		return "Will try again soon."
	if status.findn("loading") >= 0 or status.findn("creating") >= 0 or status.findn("refreshing") >= 0 or status.findn("checking") >= 0:
		return "Connecting..."
	return ""


static func empty_state_detail_text(raw_status: String) -> String:
	var fallback := "Scores appear here after the first update."
	var status := raw_status.strip_edges()
	if status.is_empty() or status == "Leaderboard loaded.":
		return fallback
	if status.begins_with("Leaderboard read"):
		return status
	return fallback
