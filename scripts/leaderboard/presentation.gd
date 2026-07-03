class_name LeaderboardPresentation

const GameFormatting = preload("res://scripts/core/formatting.gd")
const LeaderboardStyles = preload("res://scripts/leaderboard/styles.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const OrganicLeaderboardBorder = preload("res://scripts/ui/organic_leaderboard_border.gd")

var host

func _init(host_ref = null) -> void:
	host = host_ref


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

	var rows = host._leaderboard_state().rows()
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
	margin.add_theme_constant_override("margin_left", 190)
	margin.add_theme_constant_override("margin_right", 190)
	margin.add_theme_constant_override("margin_top", 330)
	margin.add_theme_constant_override("margin_bottom", 400)
	frame.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 40)
	margin.add_child(stack)
	var title = host._label("Leaderboard", 210, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", host.app_bold_font)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(title)

	stack.add_child(_leaderboard_category_dropdown())

	var list_stack := VBoxContainer.new()
	list_stack.custom_minimum_size = Vector2(1580, 0)
	list_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	list_stack.add_theme_constant_override("separation", 20)
	stack.add_child(list_stack)
	if rows.is_empty():
		list_stack.add_child(_leaderboard_empty_state())
	else:
		for i in range(rows.size()):
			list_stack.add_child(_leaderboard_row(i + 1, rows[i] as Dictionary))
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, host.LEADERBOARD_BOTTOM_SCROLL_PAD)
	list_stack.add_child(bottom_spacer)
	return frame


func _leaderboard_frame_width() -> float:
	return maxf(host.LEADERBOARD_BASE_FRAME_WIDTH, host._current_canvas_size().x)


func _leaderboard_page_frame_height(row_count: int) -> float:
	var content_height = 1040.0 + float(row_count) * 260.0 + float(host.LEADERBOARD_BOTTOM_SCROLL_PAD) + host.LEADERBOARD_PLAYER_OVERLAY_HEIGHT + 128.0
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
	overlay.offset_top = -float(host.LEADERBOARD_PLAYER_OVERLAY_HEIGHT)
	overlay.offset_bottom = -34.0
	overlay.z_index = 32
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := _leaderboard_player_card()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 56
	card.offset_right = -56
	card.offset_top = 24
	card.offset_bottom = -24
	overlay.add_child(card)
	return overlay


func _leaderboard_category_dropdown() -> OptionButton:
	var dropdown := OptionButton.new()
	dropdown.custom_minimum_size = Vector2(1360, 280)
	dropdown.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dropdown.focus_mode = Control.FOCUS_NONE
	dropdown.fit_to_longest_item = false
	dropdown.alignment = HORIZONTAL_ALIGNMENT_CENTER
	dropdown.add_theme_font_size_override("font_size", 96)
	if host.app_bold_font != null:
		dropdown.add_theme_font_override("font", host.app_bold_font)
	dropdown.add_theme_stylebox_override("normal", LeaderboardStyles.dropdown(Color("#e8f6ff"), false, host.COLOR_INK))
	dropdown.add_theme_stylebox_override("hover", LeaderboardStyles.dropdown(Color("#f4fbff"), false, host.COLOR_INK))
	dropdown.add_theme_stylebox_override("pressed", LeaderboardStyles.dropdown(Color("#cfefff"), true, host.COLOR_INK))
	dropdown.add_theme_color_override("font_color", host.COLOR_INK)
	dropdown.add_theme_color_override("font_pressed_color", host.COLOR_INK)
	dropdown.add_theme_color_override("font_hover_color", host.COLOR_INK)
	var leaderboard_state = host._leaderboard_state()
	var categories = leaderboard_state.categories()
	for i in range(categories.size()):
		var category := categories[i] as Dictionary
		var id := str(category.get("id", ""))
		dropdown.add_item(str(category.get("label", id)))
	dropdown.select(leaderboard_state.selected_category_index())
	var popup := dropdown.get_popup()
	if popup != null:
		popup.add_theme_font_size_override("font_size", 90)
		popup.add_theme_constant_override("v_separation", 26)
		if host.app_bold_font != null:
			popup.add_theme_font_override("font", host.app_bold_font)
	dropdown.item_selected.connect(_leaderboard_category_selected)
	return dropdown


func _leaderboard_category_selected(index: int) -> void:
	var category_id: String = host._leaderboard_state().select_category_index(index)
	if category_id.is_empty():
		return
	host._online_runtime().fetch_leaderboard_category(category_id)
	host._refresh_leaderboard_if_visible()


func _leaderboard_player_card() -> Control:
	var leaderboard_state = host._leaderboard_state()
	var category_id = leaderboard_state.valid_category_id(host.leaderboard_category_id)
	var player_score = leaderboard_state.score_for_category(category_id)
	var card := Button.new()
	card.text = ""
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.add_theme_stylebox_override("normal", LeaderboardStyles.player_card(Color("#d8f5ff"), false, host.COLOR_INK))
	card.add_theme_stylebox_override("hover", LeaderboardStyles.player_card(Color("#e7f9ff"), false, host.COLOR_INK))
	card.add_theme_stylebox_override("pressed", LeaderboardStyles.player_card(Color("#beeaff"), true, host.COLOR_INK))
	card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	card.pressed.connect(host._profile_chat_overlay_surface()._open_profile_overlay)
	host._button_press_runtime().attach_button_depress_animation(card, 0.986)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 34)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(host._profile_chat_overlay_surface()._profile_avatar_frame(host.leaderboard_avatar_index, Vector2(232, 232), true))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var eyebrow = host._label("Tap to edit profile", 48, Color("#22546c"), HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(eyebrow)
	var score = host._label(host.leaderboard_display_name, 104, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	score.add_theme_color_override("font_outline_color", host.COLOR_INK)
	score.add_theme_constant_override("outline_size", 18)
	copy.add_child(score)
	var rank_text = leaderboard_state.player_rank_text(category_id)
	var rank = host._label("%s  |  %s" % [leaderboard_state.format_score(category_id, player_score, leaderboard_state.skill_level_for_category(category_id), leaderboard_state.total_xp_for_category(category_id)), rank_text if rank_text == "unranked" else "Rank %s" % rank_text], 52, Color("#4b3828"), HORIZONTAL_ALIGNMENT_LEFT)
	copy.add_child(rank)
	var status := VBoxContainer.new()
	status.custom_minimum_size = Vector2(560, 0)
	status.add_theme_constant_override("separation", 8)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(status)
	var status_title = host._label(leaderboard_state.submit_status_title(), 54, host.COLOR_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	status.add_child(status_title)
	var detail = host._label(leaderboard_state.submit_status_detail(), host.MIN_MOBILE_BODY_FONT_SIZE, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(560, 146)
	status.add_child(detail)
	return card


func _leaderboard_row(rank: int, row_data: Dictionary) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 244)
	var fill := Color("#ececec")
	if bool(row_data.get("is_player", false)):
		fill = Color("#d8f5ff")
	row.add_theme_stylebox_override("panel", host._surface_style(fill, 30, 22, false))
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 34)
	row.add_child(h)
	h.add_child(_leaderboard_rank_badge(rank))
	var avatar = host._profile_chat_overlay_surface()._profile_avatar_frame(int(row_data.get("avatar_index", rank - 1)), Vector2(190, 190), bool(row_data.get("is_player", false)))
	h.add_child(avatar)
	var name_label = host._label(str(row_data.get("name", "Player")), 80, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	name_label.add_theme_constant_override("outline_size", 30)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	h.add_child(copy)
	name_label.custom_minimum_size = Vector2(0, 108)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_child(name_label)
	var score_label = host._label(str(row_data.get("score_text", GameFormatting.compact_number(float(row_data.get("score", 0)), 4))), 76, Color("#ffbf35"), HORIZONTAL_ALIGNMENT_RIGHT)
	score_label.custom_minimum_size = Vector2(0, 98)
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	score_label.add_theme_constant_override("outline_size", 28)
	copy.add_child(score_label)
	return row


func _leaderboard_rank_badge(rank: int) -> Control:
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(198, 154)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel", LeaderboardStyles.rank_badge())
	var label = host._label(str(rank), 102, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 22)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
	return badge


func _leaderboard_empty_state() -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 420)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", host._surface_style(Color("#fff6e1"), 38, 30, false))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 46)
	margin.add_theme_constant_override("margin_bottom", 46)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 22)
	margin.add_child(stack)
	var title_text := "Loading leaderboard..."
	var detail_text := "Only this visible category is being read. There are no realtime listeners."
	if not host._online_runtime()._leaderboard_firebase_enabled():
		title_text = "Rankings offline"
		detail_text = "Online rankings are not available."
	elif not host.leaderboard_fetch_in_flight:
		title_text = "No scores yet"
		detail_text = host._leaderboard_state().empty_state_detail_text()
	var title = host._label(title_text, 84, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
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
