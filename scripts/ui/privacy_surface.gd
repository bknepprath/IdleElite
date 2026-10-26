extends RefCounted

const SkillState = preload("res://scripts/progression/skill_state.gd")
const PROFILE_DIALOG_LAYER := 134 # Above chat (132) and account profile (133).
const WEBSITE := "https://idle-elite.web.app"
const CHAT_RULES_VERSION := 1
const IDLE_ELITE_BROWSER_URL := "https://www.futurebrian.com/projects/idle-elite/play/"
var host
var overlay: CanvasLayer

func _init(owner) -> void:
	host = owner

func visible() -> bool:
	return is_instance_valid(overlay) and not overlay.is_queued_for_deletion()

func close() -> void:
	if visible(): overlay.queue_free()
	overlay = null
	host._input_routing_shell()._block_background_input_briefly()

func _panel(title: String, player_profile := false) -> VBoxContainer:
	close()
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback()
	host._action_stop_hold().cancel_action()
	overlay = CanvasLayer.new()
	overlay.name = "PrivacyDialog"
	overlay.layer = PROFILE_DIALOG_LAYER
	host.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, .75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	var center := MarginContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		center.add_theme_constant_override("margin_" + side, 48)
	shade.add_child(center)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stack.add_theme_constant_override("separation", 22)
	if player_profile:
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var align := CenterContainer.new()
		align.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(align)
		var panel := PanelContainer.new()
		panel.name = "PlayerStatsPanel"
		panel.custom_minimum_size.x = 900
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.add_theme_stylebox_override("panel", host._surface_style(host.COLOR_PANEL, host.CARD_RADIUS, 36, true))
		align.add_child(panel)
		panel.add_child(stack)
		shade.gui_input.connect(func(event: InputEvent):
			if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
				shade.accept_event()
				close())
	else:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		center.add_child(scroll)
		scroll.add_child(stack)
	stack.add_child(host._label(title, 60, host.COLOR_INK if player_profile else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	return stack

func _text(stack: VBoxContainer, value: String) -> void:
	var label: Label = host._label(value, 52, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(label)

func _button(stack: VBoxContainer, text: String, action: Callable) -> Button:
	var button: Button = host._settings_surface().settings_page_button(text, "", 0, 64, 92)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	stack.add_child(button)
	return button

func show_settings() -> void:
	var stack := _panel("Privacy & chat")
	_button(stack, "Privacy policy", func(): OS.shell_open(WEBSITE + "/privacy.html"))
	_button(stack, "Delete account / data", show_deletion)
	if OS.get_name() == "Android" and host._ad_bonus_runtime().privacy_options_required:
		_button(stack, "Ad privacy choices", func(): host._ad_bonus_runtime().show_privacy_options())
	_button(stack, "Blocked players", show_blocked)
	_button(stack, "Chat rules", func(): OS.shell_open(WEBSITE + "/community-rules.html"))
	_button(stack, "Close", close)

func show_deletion() -> void:
	var stack := _panel("Delete account / data")
	_text(stack, "Request deletion of your account, cloud saves, profile, scores and chat messages. Hard Reset only resets this device.")
	_button(stack, "Request deletion", func():
		var subject := "Idle Elite account deletion"
		var body := "Please delete my Idle Elite account and associated data.\nPlayer ID: %s\nPlayer name: %s\n" % [host.leaderboard_profile.player_id, host.leaderboard_profile.display_name]
		OS.shell_open("mailto:weskillnow@gmail.com?subject=" + subject.uri_encode() + "&body=" + body.uri_encode()))
	_button(stack, "Deletion instructions", func(): OS.shell_open(WEBSITE + "/delete-account.html"))
	_button(stack, "Back", show_settings)

func show_chat_rules() -> void:
	var stack := _panel("Chat rules")
	_text(stack, "No harassment, hate, sexual content, threats, scams, spam or sharing private information. Messages are public. Violations may be removed and chat access restricted.")
	_button(stack, "Read chat rules", func(): OS.shell_open(WEBSITE + "/community-rules.html"))
	_button(stack, "Agree", func():
		host._online_runtime().chat_rules_version = CHAT_RULES_VERSION
		host.save_game()
		close())
	_button(stack, "Cancel", close)

func show_player_profile(row: Dictionary) -> void:
	var stack := _panel(str(row.get("name", "Player")), true)
	var portrait: Control = host._profile_chat_overlay_surface().profile_avatar_frame(int(row.get("avatar_index", 0)), Vector2(140, 140))
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(portrait)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	stack.add_child(grid)
	var labels := {}
	for category in host.leaderboard_state.categories():
		var id := str(category.id)
		var title := "Total level" if id == "total_level" else str(category.label)
		var label: Label = host._label(title, 48, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(label)
		var value: Label = host._label("…", 48, host.COLOR_INK, HORIZONTAL_ALIGNMENT_RIGHT)
		grid.add_child(value)
		labels[id] = value
	var total_xp: Label = host._label("…", 48, host.COLOR_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	grid.add_child(host._label("Total XP", 48, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
	grid.add_child(total_xp)
	labels["total_xp"] = total_xp
	var uid := str(row.get("sender_id", ""))
	if uid != host.leaderboard_profile.player_id and not bool(row.get("deleted", false)):
		var actions := HBoxContainer.new()
		stack.add_child(actions)
		stack.move_child(actions, 0)
		_profile_small_action(actions, "Block", func():
			host._online_runtime().set_chat_player_blocked(uid, str(row.get("name", "Player")), true)
			close())
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(gap)
		_profile_small_action(actions, "Report", func(): show_report(row))
	var close_button := _button(stack, "Close", close)
	close_button.name = "ClosePlayerProfile"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.custom_minimum_size.x = 240
	for state in ["normal", "hover"]:
		close_button.add_theme_stylebox_override(state, host._paper_button_style(Color("#ff6b6b"), 22))
	close_button.add_theme_stylebox_override("pressed", host._paper_button_style(Color("#ef5656"), 22, 32, true))
	var opened_overlay := overlay
	host._online_runtime().fetch_public_player_stats(uid, func(stats: Dictionary):
		if not visible() or overlay != opened_overlay:
			return
		for id in labels:
			var value: Label = labels[id]
			if not stats.has(id):
				value.text = "—"
				continue
			var record: Dictionary = stats[id]
			if id.begins_with("skill_xp:"):
				value.text = "Lv %s" % int(record.get("skill_level", SkillState.skill_level_for_xp(int(record.get("score", 0)))))
			else:
				value.text = str(int(record.get("score", 0))))

# The owner requested these secondary profile actions be small and unobtrusive.
func _profile_small_action(row: HBoxContainer, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.custom_minimum_size = Vector2(128, 64)
	button.add_theme_font_size_override("font_size", 32)
	if host.app_font != null:
		button.add_theme_font_override("font", host.app_font)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, host.COLOR_MUTED)
	button.pressed.connect(action)
	row.add_child(button)

func show_report(row: Dictionary) -> void:
	var stack := _panel("Report message")
	_text(stack, str(row.get("text", "")))
	for reason in ["Harassment or hate", "Sexual content", "Threats or private information", "Spam or scam", "Other"]:
		_button(stack, reason, func():
			host._online_runtime().report_chat_message(str(row.get("message_id", "")), reason)
			close())
	_button(stack, "Back", func(): show_player_profile(row))

func show_blocked() -> void:
	var stack := _panel("Blocked players")
	var blocked: Dictionary = host._online_runtime().chat_blocked_players
	if blocked.is_empty(): _text(stack, "No blocked players.")
	for raw_uid in blocked:
		var uid := str(raw_uid)
		_button(stack, "Unblock " + str(blocked[uid]), func():
			host._online_runtime().set_chat_player_blocked(uid, "", false)
			show_blocked())
	_button(stack, "Back", show_settings)

func show_itch_ad_notice() -> void:
	var stack := _panel("Ads on itch.io", true)
	overlay.name = "ItchAdNotice"
	var message: Label = host._label("I can't serve ads on itch.io.\nYou can play on my website instead.", 52, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(message)
	var link := _button(stack, "FutureBrian.com", func(): OS.shell_open(IDLE_ELITE_BROWSER_URL))
	link.name = "WebsiteLink"
	link.tooltip_text = IDLE_ELITE_BROWSER_URL
	var dismiss := _button(stack, "Close", close)
	dismiss.name = "CloseNotice"
	dismiss.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dismiss.custom_minimum_size.x = 240
	dismiss.add_theme_stylebox_override("normal", host._paper_button_style(Color("#ff6262"), 21))
	dismiss.add_theme_stylebox_override("hover", host._paper_button_style(Color("#ff8585"), 21))
	dismiss.add_theme_stylebox_override("pressed", host._paper_button_style(Color("#e34e4e"), 21, 32, true))
