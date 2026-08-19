class_name LeaderboardPresentation

const GameFormatting = preload("res://scripts/core/formatting.gd")
const LeaderboardProfile = preload("res://scripts/leaderboard/profile.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")

const ICON := "res://assets/content/ui/leaderboard-podium-icon.png"
const BOTTOM_SCROLL_PAD := 360
const BASE_FRAME_WIDTH := 1080
const PLAYER_OVERLAY_HEIGHT := 410

var host

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
	style.set_border_width_all(9)
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
	style.set_border_width_all(8)
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
	host.button_press_runtime.play_default_button_sfx()
	host._navigation_shell()._render_screen()


func _render_leaderboard_page() -> void:
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

	var rows = host.leaderboard_state.rows()
	var page_frame = _leaderboard_page_frame(rows)
	stack.add_child(page_frame)
	host.skills_content.add_child(_leaderboard_player_overlay())


func _leaderboard_page_frame(rows: Array) -> Control:
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(_leaderboard_frame_width(), _leaderboard_page_frame_height(rows.size()))
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
	margin.add_theme_constant_override("margin_top", 165)
	margin.add_theme_constant_override("margin_bottom", 200)
	frame.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 20)
	margin.add_child(stack)
	var title = host._label("Leaderboard", 105, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
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
	return maxf(BASE_FRAME_WIDTH, host._current_canvas_size().x)


func _leaderboard_page_frame_height(row_count: int) -> float:
	var content_height = 520.0 + float(row_count) * 130.0 + float(BOTTOM_SCROLL_PAD) + PLAYER_OVERLAY_HEIGHT + 64.0
	return maxf(content_height, host._current_canvas_size().y)


func _leaderboard_player_overlay() -> Control:
	var overlay := Control.new()
	var content_width = host._skill_content_width()
	overlay.anchor_left = 0.5
	overlay.anchor_right = 0.5
	overlay.anchor_top = 1.0
	overlay.anchor_bottom = 1.0
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


func _leaderboard_category_dropdown() -> OptionButton:
	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size = Vector2(680, 140)
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
	if host.current_screen != "leaderboard" or host.skills_content == null:
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
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 17)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(host._profile_chat_overlay_surface().profile_avatar_frame(host.leaderboard_profile.avatar_index, Vector2(116, 116), true))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var eyebrow = host._label("Tap to edit profile", 48, Color("#22546c"), HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(eyebrow)
	var score = host._label(host.leaderboard_profile.display_name, 60, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	score.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	score.add_theme_color_override("font_outline_color", host.COLOR_INK)
	score.add_theme_constant_override("outline_size", 5)
	copy.add_child(score)
	var rank_text = LeaderboardPresentation.player_rank_text(player_score, leaderboard_state.rows_for_category(category_id), leaderboard_state.TOP_COUNT)
	var score_text = LeaderboardPresentation.format_score(leaderboard_state.valid_category_id(category_id), player_score, leaderboard_state.skill_level_for_category(category_id), leaderboard_state.total_xp_for_category(category_id), leaderboard_state.CATEGORY_TOTAL_LEVEL, leaderboard_state.CATEGORY_MEDALS, leaderboard_state.CATEGORY_ELITE_HEAVENLY, leaderboard_state.CATEGORY_SKILL_PREFIX, Callable(leaderboard_state, "skill_level_from_total_xp"))
	var rank = host._label("%s  |  %s" % [score_text, rank_text if rank_text == "unranked" else "Rank %s" % rank_text], 52, Color("#4b3828"), HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(rank)
	var status := VBoxContainer.new()
	status.custom_minimum_size = Vector2(360, 0)
	status.add_theme_constant_override("separation", 4)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(status)
	var status_title = host._label(LeaderboardPresentation.submit_status_title(host.god_mode_save_tainted, host._online_runtime()._leaderboard_firebase_enabled(), LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS), host._online_runtime()._leaderboard_auth_ready(), host._online_runtime().leaderboard_submit_in_flight, leaderboard_state.last_submit_unix, leaderboard_state.submit_ready()), 52, host.COLOR_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	status_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_title.custom_minimum_size = Vector2(360, 62)
	status.add_child(status_title)
	var simple_status = LeaderboardPresentation.simple_status_message(str(leaderboard_state.status_message))
	var detail = host._label(LeaderboardPresentation.submit_status_detail(host.god_mode_save_tainted, host._online_runtime()._leaderboard_firebase_enabled(), LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS), host._online_runtime()._leaderboard_auth_retry_wait_seconds(), host._online_runtime().leaderboard_auth_in_flight, host._online_runtime()._leaderboard_auth_ready(), host._online_runtime().leaderboard_submit_in_flight, simple_status, leaderboard_state.last_submit_unix, leaderboard_state.queued_score(), leaderboard_state.has_pending_category_score(), leaderboard_state.submit_ready()), 52, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(360, 146)
	status.add_child(detail)
	return card


func _leaderboard_row(rank: int, row_data: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 122)
	var fill := Color("#ececec")
	if bool(row_data.get("is_player", false)):
		fill = Color("#d8f5ff")
	row.add_theme_stylebox_override("panel", host._surface_style(fill, 30, 22, false))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 17)
	row.add_child(h)
	h.add_child(_leaderboard_rank_badge(rank))
	var avatar = host._profile_chat_overlay_surface().profile_avatar_frame(int(row_data.get("avatar_index", rank - 1)), Vector2(95, 95), bool(row_data.get("is_player", false)))
	h.add_child(avatar)
	var name_label = host._label(str(row_data.get("name", "Player")), 52, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	name_label.add_theme_constant_override("outline_size", 8)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	h.add_child(copy)
	name_label.custom_minimum_size = Vector2(0, 54)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(name_label)
	var score_label = host._label(str(row_data.get("score_text", GameFormatting.compact_number(float(row_data.get("score", 0)), 4))), 52, Color("#ffbf35"), HORIZONTAL_ALIGNMENT_RIGHT)
	score_label.custom_minimum_size = Vector2(0, 49)
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	score_label.add_theme_constant_override("outline_size", 7)
	copy.add_child(score_label)
	return row


func _leaderboard_rank_badge(rank: int) -> Control:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(99, 77)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", LeaderboardPresentation.rank_badge())
	var label = host._label(str(rank), 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	return badge


func _leaderboard_empty_state() -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 210)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", host._surface_style(Color("#fff6e1"), 38, 30, false))
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
	var detail = host._label(detail_text, 56, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
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


static func player_rank_text(score: int, rows: Array, top_count: int) -> String:
	if score <= 0:
		return "unranked"
	var rank := 1
	for row in rows:
		if int((row as Dictionary).get("score", 0)) > score:
			rank += 1
	if rank > top_count:
		return "#%s+" % top_count
	return "#%s" % rank


static func submit_status_title(
	god_mode_save_tainted: bool,
	firebase_enabled: bool,
	profile_claim_valid: bool,
	auth_ready: bool,
	submit_in_flight: bool,
	last_submit_unix: int,
	submit_ready: bool
) -> String:
	if god_mode_save_tainted:
		return "Test save"
	if not firebase_enabled:
		return "Rankings offline"
	if not profile_claim_valid:
		return "Choose Username"
	if not auth_ready:
		return "Scores ready"
	if submit_in_flight:
		return "Updating..."
	if last_submit_unix <= 0:
		return "Scores ready"
	if submit_ready:
		return "Scores ready"
	return "Scores saved"


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
	submit_ready: bool
) -> String:
	if god_mode_save_tainted:
		return "Rankings are hidden for this test save."
	if not firebase_enabled:
		return "Online rankings are not available."
	if not profile_claim_valid:
		return "Save a name to join rankings."
	if retry_wait > 0:
		return "Will try again soon."
	if auth_in_flight and not auth_ready:
		return "Connecting..."
	if not auth_ready:
		return "Scores update automatically."
	if submit_in_flight:
		return "Updating rankings..."
	if not simple_status.is_empty():
		return simple_status
	if last_submit_unix <= 0:
		return "Scores update automatically."
	if queued_score <= 0 and not category_pending:
		return "Your score is up to date."
	if submit_ready:
		return "New score ready."
	return "New score saved."


static func simple_status_message(raw_status: String) -> String:
	var status := raw_status.strip_edges()
	if status.is_empty() or status == "Leaderboard loaded.":
		return ""
	if status == "Leaderboard published." or status == "Leaderboard name saved.":
		return "Scores saved."
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
