extends Control

const SAVE_PATH := "user://idle_elite_save.json"
const BASE_MAX_STAMINA := 30
const STAMINA_REGEN_SECONDS := 12.0
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const BASE_CANVAS := Vector2(2160, 3840)
const BOTTOM_NAV_HEIGHT := 420
const BOTTOM_NAV_SAFE_PAD := 96
const PAGE_PAD := 96
const CARD_RADIUS := 64
const ACTION_CARD_HEIGHT := 390

const COLOR_INK := Color("#171615")
const COLOR_PAPER := Color("#f8f1e5")
const COLOR_PANEL := Color("#fffdf8")
const COLOR_LINE := Color("#d9cfbc")
const COLOR_MUTED := Color("#6e6658")
const COLOR_GOLD := Color("#fff2a8")
const COLOR_GREEN := Color("#35d86d")
const COLOR_BLUE := Color("#3aa0ff")
const COLOR_NAV := Color("#444a5b")

const SKILL_DEFS := [
	{"id": "fight", "name": "Fight", "verb": "Fighting", "time_scale": 0.88, "xp_scale": 1.00, "success_start": 95.0},
	{"id": "thieving", "name": "Thief", "verb": "Sneaking", "time_scale": 0.72, "xp_scale": 1.00, "success_start": 96.0},
	{"id": "build", "name": "Build", "verb": "Building", "time_scale": 1.28, "xp_scale": 1.00, "success_start": 86.0},
	{"id": "woodcutting", "name": "Wood", "verb": "Chopping", "time_scale": 1.08, "xp_scale": 1.00, "success_start": 90.0},
	{"id": "fishing", "name": "Fish", "verb": "Fishing", "time_scale": 1.58, "xp_scale": 1.72, "success_start": 90.0},
]

const UNLOCK_LEVELS := [
	1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
	12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
	33, 36, 40, 45, 50
]

const ACTION_FILES := {
	"fight": [
		"01-shove-wobbly-hay-bale.png",
		"02-kick-mud-off-boot.png",
		"03-wrestle-stuck-gate-latch.png",
		"04-box-suspicious-feed-sack.png",
		"05-duel-leaning-fence-post.png",
		"06-outmuscle-angry-wheelbarrow.png"
	],
	"thieving": [
		"01-pocket-a-penny-nobody-wanted.png",
		"02-borrow-a-cookie-permanently.png",
		"03-sneak-past-tip-jar-eye-contact.png",
		"04-lift-loose-coins-from-couch-cushions.png",
		"05-distract-fruit-stand-with-jazz-hands.png",
		"06-steal-a-wallet-from-a-mannequin.png"
	],
	"build": [
		"01-stack-two-rocks-confidently.png",
		"02-hammer-a-loose-fence-nail.png",
		"03-patch-leaky-bucket-with-hope.png",
		"04-build-a-wobbly-stool.png",
		"05-repair-squeaky-barn-door.png",
		"06-assemble-judgmental-birdhouse.png"
	],
	"woodcutting": [
		"01-gather-fallen-branches.png",
		"02-snap-a-twig-with-purpose.png",
		"03-trim-overconfident-shrub.png",
		"04-chop-softwood-tree.png",
		"05-split-firewood.png",
		"06-fell-skinny-pine.png"
	],
	"fishing": [
		"01-scoop-pond-minnows.png",
		"02-dangle-string-from-dock.png",
		"03-cast-bamboo-rod.png",
		"04-drag-net-through-creek.png",
		"05-set-tiny-crab-pot.png",
		"06-fly-fish-at-river-bend.png"
	]
}

var skills := {}
var actions_by_skill := {}
var selected_skill_id := "fight"
var current_screen := "home"
var running_skill_id := ""
var running_action_id := ""
var action_progress := 0.0
var stamina := {}
var stamina_bank := {}
var last_result := "Pick a skill and start training."
var is_muted := false

var app_font: Font
var home_page: Control
var skills_page: Control
var nav_bar: PanelContainer
var content_scroll: ScrollContainer
var skills_content: Control
var home_total_label: Label
var home_skill_labels := {}
var hero_message: Label
var skills_tab: Button
var hero_tab: Button
var skill_cards := {}
var action_cards := {}
var settings_overlay: Control
var mute_button: Button
var click_player: AudioStreamPlayer
var success_player: AudioStreamPlayer
var level_player: AudioStreamPlayer


func _ready() -> void:
	_load_font()
	_load_action_data()
	_init_state()
	_build_audio()
	_build_ui()
	load_game()
	_validate_state()
	_render_screen()
	_update_ui(0.0, true)
	var timer := Timer.new()
	timer.wait_time = 10.0
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)


func _process(delta: float) -> void:
	_regen_stamina(delta)
	_process_action(delta)
	_update_ui(delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()


func _build_ui() -> void:
	var root := ColorRect.new()
	root.color = COLOR_PAPER
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	
	home_page = Control.new()
	home_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	home_page.offset_bottom = -BOTTOM_NAV_HEIGHT
	add_child(home_page)
	_build_home_page()
	
	skills_page = Control.new()
	skills_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	skills_page.offset_bottom = -BOTTOM_NAV_HEIGHT
	add_child(skills_page)
	_build_skills_page()
	
	_build_nav_bar()
	_build_settings_overlay()


func _build_home_page() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", PAGE_PAD)
	margin.add_theme_constant_override("margin_right", PAGE_PAD)
	margin.add_theme_constant_override("margin_top", 288)
	margin.add_theme_constant_override("margin_bottom", 0)
	home_page.add_child(margin)
	
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 40)
	margin.add_child(stack)
	
	var logo := TextureRect.new()
	logo.texture = _texture("res://docs/assets/logo/idle-elite-logo-chroma.png")
	logo.custom_minimum_size = Vector2(0, 430)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.material = _chroma_material(Color("#00ff00"))
	stack.add_child(logo)
	
	stack.add_child(_make_level_snapshot())
	
	var hero_panel := PanelContainer.new()
	hero_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.96, 0.78, 0.35), 0, 0))
	stack.add_child(hero_panel)
	_build_hero(hero_panel)


func _make_level_snapshot() -> Control:
	home_skill_labels.clear()
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 36)
	
	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 34)
	stack.add_child(total_row)
	total_row.add_child(_image("res://docs/assets/ui/total-lv-bargraph.png", Vector2(150, 150)))
	home_total_label = _label("", 108, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	total_row.add_child(home_total_label)
	
	var rows := VBoxContainer.new()
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 22)
	stack.add_child(rows)
	for def in SKILL_DEFS:
		var skill_id := str(def["id"])
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(720, 185)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 38)
		rows.add_child(row)
		row.add_child(_image("res://docs/assets/icons/%s.png" % skill_id, Vector2(144, 144)))
		var value := _label("", 78, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		value.custom_minimum_size = Vector2(520, 0)
		row.add_child(value)
		home_skill_labels[skill_id] = value
	return stack


func _build_hero(parent: PanelContainer) -> void:
	var scene := Control.new()
	scene.clip_contents = true
	parent.add_child(scene)

	var stage := Control.new()
	stage.anchor_right = 1.0
	stage.anchor_bottom = 0.0
	stage.offset_bottom = 1530
	scene.add_child(stage)
	
	var hero := TextureRect.new()
	hero.texture = _texture("res://docs/assets/characters/stick-hero.png")
	hero.anchor_left = 0.03
	hero.anchor_right = 0.80
	hero.anchor_top = 0.30
	hero.anchor_bottom = 1.48
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.material = _hero_chroma_material()
	stage.add_child(hero)
	
	var bubble := Control.new()
	bubble.anchor_left = 0.02
	bubble.anchor_right = 0.82
	bubble.anchor_top = 0.12
	bubble.anchor_bottom = 0.40
	stage.add_child(bubble)
	var bubble_art := TextureRect.new()
	bubble_art.texture = _texture("res://docs/assets/ui/speech-bubble-down.png")
	bubble_art.set_anchors_preset(Control.PRESET_FULL_RECT)
	bubble_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble_art.stretch_mode = TextureRect.STRETCH_SCALE
	bubble.add_child(bubble_art)
	hero_message = _label("I MUST BECOME AN IDLE ELITIST!", 72, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	hero_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_message.anchor_left = 0.08
	hero_message.anchor_right = 0.92
	hero_message.anchor_top = 0.08
	hero_message.anchor_bottom = 0.68
	hero_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.add_child(hero_message)
	
	var tools := VBoxContainer.new()
	tools.anchor_left = 0.80
	tools.anchor_right = 1.0
	tools.anchor_top = 0.16
	tools.anchor_bottom = 0.64
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 58)
	stage.add_child(tools)
	var ad := _icon_button("res://docs/assets/ui/ad-simple.png")
	ad.pressed.connect(func(): _set_result("Rewarded ads are enabled in Android builds."))
	tools.add_child(ad)
	var settings := _icon_button("res://docs/assets/ui/settings-gear-simple.png")
	settings.pressed.connect(_open_settings)
	tools.add_child(settings)
	var discord := _icon_button("res://docs/assets/ui/discord-simple.png")
	discord.pressed.connect(func(): _set_result("Discord button tapped."))
	tools.add_child(discord)


func _build_skills_page() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", PAGE_PAD)
	margin.add_theme_constant_override("margin_right", PAGE_PAD)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_bottom", 72)
	skills_page.add_child(margin)
	
	skills_content = Control.new()
	skills_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(skills_content)


func _build_nav_bar() -> void:
	nav_bar = PanelContainer.new()
	nav_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nav_bar.offset_top = -BOTTOM_NAV_HEIGHT
	nav_bar.clip_contents = true
	nav_bar.add_theme_stylebox_override("panel", _nav_style())
	add_child(nav_bar)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 220)
	row.clip_contents = true
	row.custom_minimum_size = Vector2(0, BOTTOM_NAV_HEIGHT - BOTTOM_NAV_SAFE_PAD)
	nav_bar.add_child(row)
	skills_tab = _nav_button("res://docs/assets/ui/total-lv-bargraph.png")
	skills_tab.pressed.connect(_show_skills)
	row.add_child(skills_tab)
	hero_tab = _nav_button("res://docs/assets/ui/nav-hero.png")
	hero_tab.pressed.connect(_show_home)
	row.add_child(hero_tab)


func _build_settings_overlay() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color(0, 0, 0, 0.34)
	settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.visible = false
	add_child(settings_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1300, 0)
	panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, 16, CARD_RADIUS))
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 46)
	panel.add_child(stack)
	stack.add_child(_label("Settings", 124, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	mute_button = _menu_button("")
	mute_button.pressed.connect(_toggle_mute)
	stack.add_child(mute_button)
	var reset := _menu_button("Reset Data")
	reset.add_theme_stylebox_override("normal", _panel_style(Color("#ffe2e2"), 12, 48))
	reset.pressed.connect(_reset_data)
	stack.add_child(reset)
	var close := _menu_button("Close")
	close.pressed.connect(_close_settings)
	stack.add_child(close)


func _render_screen() -> void:
	if skills_content == null:
		return
	_clear(skills_content)
	skill_cards.clear()
	action_cards.clear()
	
	if current_screen == "skill":
		_render_skill_detail()
	else:
		content_scroll = ScrollContainer.new()
		content_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		skills_content.add_child(content_scroll)
		var stack := VBoxContainer.new()
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_theme_constant_override("separation", 52)
		content_scroll.add_child(stack)
		_render_skill_menu(stack)
	_update_page_visibility()


func _render_skill_menu(stack: VBoxContainer) -> void:
	stack.add_child(_label("Skills", 132, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	for def in SKILL_DEFS:
		var skill_id := str(def["id"])
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size = Vector2(0, 500)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _panel_style(COLOR_PANEL, 12, CARD_RADIUS))
		button.add_theme_stylebox_override("hover", _panel_style(COLOR_GOLD, 12, CARD_RADIUS))
		button.add_theme_stylebox_override("pressed", _panel_style(COLOR_GOLD.darkened(0.08), 12, CARD_RADIUS))
		button.pressed.connect(_select_skill.bind(skill_id))
		stack.add_child(button)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 72)
		margin.add_theme_constant_override("margin_right", 72)
		margin.add_theme_constant_override("margin_top", 58)
		margin.add_theme_constant_override("margin_bottom", 58)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 62)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)
		row.add_child(_image("res://docs/assets/icons/%s.png" % skill_id, Vector2(300, 300)))
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 28)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var title := _label("", 108, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(title)
		var meta := _label("", 54, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(meta)
		var xp_bar := _progress(COLOR_GREEN, 58)
		copy.add_child(xp_bar)
		var stamina_bar := _progress(COLOR_BLUE, 58)
		copy.add_child(stamina_bar)
		skill_cards[skill_id] = {"title": title, "meta": meta, "xp": xp_bar, "stamina": stamina_bar}


func _render_skill_detail() -> void:
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.add_theme_constant_override("separation", 38)
	skills_content.add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 230)
	header.add_theme_constant_override("separation", 42)
	page.add_child(header)
	header.add_child(_image("res://docs/assets/icons/%s.png" % selected_skill_id, Vector2(205, 205)))
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 8)
	header.add_child(title_stack)
	var title := _label(_skill_name(selected_skill_id), 108, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_stack.add_child(title)
	var xp := _xp_progress(selected_skill_id)
	title_stack.add_child(_label("Lv %s - XP %s / %s" % [_skill_level(selected_skill_id), int(xp["current"]), int(xp["needed"])], 54, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
	
	var summary := PanelContainer.new()
	summary.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, 12, CARD_RADIUS))
	page.add_child(summary)
	var summary_stack := VBoxContainer.new()
	summary_stack.add_theme_constant_override("separation", 32)
	summary.add_child(summary_stack)
	summary_stack.add_child(_progress(COLOR_GREEN, 62, float(xp["pct"])))
	summary_stack.add_child(_progress(COLOR_BLUE, 62, float(_stamina(selected_skill_id)) / float(_max_stamina()) * 100.0))

	var divider := ColorRect.new()
	divider.color = COLOR_INK
	divider.custom_minimum_size = Vector2(0, 16)
	page.add_child(divider)

	var actions_scroll := ScrollContainer.new()
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(actions_scroll)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 52)
	actions_scroll.add_child(stack)
	
	for action in actions_by_skill.get(selected_skill_id, []):
		var action_id := str(action["id"])
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size = Vector2(0, ACTION_CARD_HEIGHT)
		button.focus_mode = Control.FOCUS_NONE
		button.clip_contents = true
		button.add_theme_stylebox_override("normal", _action_card_style(COLOR_PANEL))
		button.add_theme_stylebox_override("hover", _action_card_style(Color("#fff8cf")))
		button.add_theme_stylebox_override("pressed", _action_card_style(Color("#f8eaa2")))
		button.pressed.connect(_start_action.bind(selected_skill_id, action_id))
		stack.add_child(button)
		
		var bg := TextureRect.new()
		bg.texture = _texture(str(action["bg"]))
		bg.modulate = Color(1, 1, 1, 0.58)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(bg)
		
		var shade := ColorRect.new()
		shade.color = Color(1, 0.98, 0.84, 0.34)
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(shade)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 54)
		margin.add_theme_constant_override("margin_right", 54)
		margin.add_theme_constant_override("margin_top", 30)
		margin.add_theme_constant_override("margin_bottom", 74)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 34)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)

		var art_panel := PanelContainer.new()
		art_panel.custom_minimum_size = Vector2(310, 245)
		art_panel.add_theme_stylebox_override("panel", _action_art_style())
		art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(art_panel)
		var art := _image(str(action["art"]), Vector2(270, 210))
		art_panel.add_child(art)

		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 14)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var name := _label(str(action["name"]), 58, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(name)

		var stat_row := HBoxContainer.new()
		stat_row.add_theme_constant_override("separation", 30)
		stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(stat_row)
		var stamina_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(stamina_label))
		var success_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(success_label))

		var active_progress := _progress(Color("#f4bf35"), 46)
		active_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_child(active_progress)

		var progress := _progress(COLOR_GREEN, 58)
		progress.anchor_left = 0.0
		progress.anchor_right = 1.0
		progress.anchor_top = 1.0
		progress.anchor_bottom = 1.0
		progress.offset_left = 0
		progress.offset_right = 0
		progress.offset_top = -70
		progress.offset_bottom = -12
		progress.z_index = 20
		button.add_child(progress)
		action_cards[_action_key(selected_skill_id, action_id)] = {
			"button": button,
			"stamina": stamina_label,
			"success": success_label,
			"active_progress": active_progress,
			"progress": progress
		}


func _update_page_visibility() -> void:
	home_page.visible = current_screen == "home"
	skills_page.visible = current_screen != "home"
	_apply_nav_style(hero_tab, current_screen == "home")
	_apply_nav_style(skills_tab, current_screen != "home")


func _update_ui(delta: float, instant := false) -> void:
	if home_total_label != null:
		home_total_label.text = "Total Lv %s" % _global_level()
	for skill_id in home_skill_labels.keys():
		(home_skill_labels[skill_id] as Label).text = "%s Lvl %s" % [_skill_name(str(skill_id)), _skill_level(str(skill_id))]
	for skill_id in skill_cards.keys():
		var xp := _xp_progress(str(skill_id))
		var card: Dictionary = skill_cards[skill_id]
		(card["title"] as Label).text = "%s" % _skill_name(str(skill_id))
		(card["meta"] as Label).text = "Lv %s  XP %s / %s%s" % [
			_skill_level(str(skill_id)),
			int(xp["current"]),
			int(xp["needed"]),
			"  Training" if running_skill_id == str(skill_id) else ""
		]
		_set_bar(card["xp"], float(xp["pct"]), delta, instant)
		_set_bar(card["stamina"], float(_stamina(str(skill_id))) / float(_max_stamina()) * 100.0, delta, instant)
	for key in action_cards.keys():
		var parts := str(key).split(":")
		var skill_id := parts[0]
		var action_id := parts[1]
		var action := _action_data(skill_id, action_id)
		var unlocked := _skill_level(skill_id) >= int(action.get("unlock", 1))
		var running := running_skill_id == skill_id and running_action_id == action_id
		var card: Dictionary = action_cards[key]
		(card["button"] as Button).disabled = not unlocked
		(card["button"] as Button).modulate = Color(1, 1, 1, 1.0 if unlocked else 0.52)
		(card["stamina"] as Label).text = "%s\nSTAMINA" % action.get("stamina", 1)
		(card["success"] as Label).text = "%s%%\nSUCCESS" % int(action.get("success", 90))
		_set_bar(card["active_progress"], action_progress * 100.0 if running else 0.0, delta, instant)
		var xp := _xp_progress(skill_id)
		_set_bar(card["progress"], float(xp["pct"]), delta, instant)
	if mute_button != null:
		mute_button.text = "Unmute" if is_muted else "Mute"


func _process_action(delta: float) -> void:
	if running_skill_id.is_empty():
		return
	var action := _action_data(running_skill_id, running_action_id)
	if action.is_empty():
		running_skill_id = ""
		return
	action_progress += delta / maxf(0.1, float(action["seconds"]))
	if action_progress < 1.0:
		return
	action_progress = 0.0
	var cost := int(action["stamina"])
	if _stamina(running_skill_id) < cost:
		last_result = "Out of stamina."
		running_skill_id = ""
		return
	stamina[running_skill_id] = _stamina(running_skill_id) - cost
	var success := randf() * 100.0 <= float(action["success"])
	if success:
		skills[running_skill_id]["xp"] = int(skills[running_skill_id]["xp"]) + int(action["xp"])
		_recalculate_level(running_skill_id)
		last_result = "+%s XP from %s." % [int(action["xp"]), action["name"]]
		_play(success_player)
	else:
		last_result = "Failed %s." % action["name"]
	_update_ui(0.0, true)


func _regen_stamina(delta: float) -> void:
	var max_stamina := _max_stamina()
	for def in SKILL_DEFS:
		var skill_id := str(def["id"])
		if _stamina(skill_id) >= max_stamina:
			stamina_bank[skill_id] = 0.0
			continue
		stamina_bank[skill_id] = float(stamina_bank.get(skill_id, 0.0)) + delta
		if float(stamina_bank[skill_id]) >= STAMINA_REGEN_SECONDS:
			var gained := int(floor(float(stamina_bank[skill_id]) / STAMINA_REGEN_SECONDS))
			stamina[skill_id] = mini(max_stamina, _stamina(skill_id) + gained)
			stamina_bank[skill_id] = fmod(float(stamina_bank[skill_id]), STAMINA_REGEN_SECONDS)


func _start_action(skill_id: String, action_id: String) -> void:
	var action := _action_data(skill_id, action_id)
	if action.is_empty() or _skill_level(skill_id) < int(action["unlock"]):
		return
	if _stamina(skill_id) < int(action["stamina"]):
		_set_result("Not enough stamina.")
		return
	selected_skill_id = skill_id
	running_skill_id = skill_id
	running_action_id = action_id
	action_progress = 0.0
	_set_result("%s started." % action["name"])


func _select_skill(skill_id: String) -> void:
	selected_skill_id = skill_id
	current_screen = "skill"
	_play(click_player)
	_render_screen()


func _show_home() -> void:
	current_screen = "home"
	_play(click_player)
	_render_screen()


func _show_skills() -> void:
	current_screen = "menu"
	_play(click_player)
	_render_screen()


func _back_to_skills() -> void:
	current_screen = "menu"
	_play(click_player)
	_render_screen()


func _open_settings() -> void:
	settings_overlay.visible = true
	_play(click_player)


func _close_settings() -> void:
	settings_overlay.visible = false
	_play(click_player)


func _toggle_mute() -> void:
	is_muted = not is_muted
	AudioServer.set_bus_mute(0, is_muted)
	_update_ui(0.0, true)


func _reset_data() -> void:
	_init_state()
	running_skill_id = ""
	running_action_id = ""
	action_progress = 0.0
	current_screen = "home"
	last_result = "Progress reset."
	save_game()
	_close_settings()
	_render_screen()
	_update_ui(0.0, true)


func _set_result(text: String) -> void:
	last_result = text
	if hero_message != null:
		hero_message.text = text.to_upper()
	_play(click_player)


func _load_action_data() -> void:
	actions_by_skill.clear()
	for raw_def in SKILL_DEFS:
		var skill := raw_def as Dictionary
		var skill_id := str(skill["id"])
		var actions := []
		var dir_path := "res://docs/assets/%s/actions" % skill_id
		var files := PackedStringArray(ACTION_FILES.get(skill_id, []))
		if files.is_empty():
			var dir := DirAccess.open(dir_path)
			if dir != null:
				files = dir.get_files()
				files.sort()
		for file_name in files:
			if not file_name.ends_with(".png"):
				continue
			var number := int(file_name.substr(0, 2))
			if number <= 0 or number > UNLOCK_LEVELS.size():
				continue
			var index := number - 1
			var action_name := _title_from_asset(file_name)
			var stamina_cost := 1 + int(floor(float(index) / 3.0))
			var seconds := (1.0 + float(stamina_cost) * 0.75 + float(UNLOCK_LEVELS[index]) * 0.06) * float(skill["time_scale"])
			var xp := maxi(1, int(round(pow(float(index + 1), 1.35) * float(skill["xp_scale"]))))
			actions.append({
				"id": _slug(action_name),
				"name": action_name,
				"unlock": UNLOCK_LEVELS[index],
				"seconds": seconds,
				"xp": xp,
				"stamina": stamina_cost,
				"success": maxf(20.0, float(skill["success_start"]) - float(index) * 2.0),
				"art": "%s/%s" % [dir_path, file_name],
				"bg": _background_for_action(skill_id, index)
			})
		actions_by_skill[skill_id] = actions


func _background_for_action(skill_id: String, index: int) -> String:
	var bg_dir := "res://docs/assets/%s/backgrounds" % skill_id
	var dir := DirAccess.open(bg_dir)
	if dir == null:
		return "res://docs/assets/%s/actions/01-placeholder.png" % skill_id
	var files := dir.get_files()
	files.sort()
	var wanted := clampi(int(floor(float(index) / 5.0)) + 1, 1, 5)
	if skill_id == "fishing":
		wanted = clampi(int(floor(float(index) / 2.0)), 0, 11)
	for file_name in files:
		if file_name.ends_with(".png") and int(file_name.substr(0, 2)) == wanted:
			return "%s/%s" % [bg_dir, file_name]
	for file_name in files:
		if file_name.ends_with(".png"):
			return "%s/%s" % [bg_dir, file_name]
	return ""


func _init_state() -> void:
	skills.clear()
	stamina.clear()
	stamina_bank.clear()
	for def in SKILL_DEFS:
		var skill_id := str(def["id"])
		skills[skill_id] = {"xp": 0, "level": 1}
		stamina[skill_id] = BASE_MAX_STAMINA
		stamina_bank[skill_id] = 0.0


func _validate_state() -> void:
	for def in SKILL_DEFS:
		var skill_id := str(def["id"])
		if not skills.has(skill_id):
			skills[skill_id] = {"xp": 0, "level": 1}
		if not stamina.has(skill_id):
			stamina[skill_id] = _max_stamina()
		if not stamina_bank.has(skill_id):
			stamina_bank[skill_id] = 0.0
		_recalculate_level(skill_id)
	if not skills.has(selected_skill_id):
		selected_skill_id = "fight"


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"skills": skills,
		"stamina": stamina,
		"stamina_bank": stamina_bank,
		"selected_skill_id": selected_skill_id,
		"running_skill_id": running_skill_id,
		"running_action_id": running_action_id,
		"action_progress": action_progress,
		"is_muted": is_muted,
		"last_result": last_result,
		"saved_at": Time.get_unix_time_from_system()
	}))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) == TYPE_DICTIONARY:
		for skill_id in loaded_skills.keys():
			if skills.has(skill_id) and typeof(loaded_skills[skill_id]) == TYPE_DICTIONARY:
				skills[skill_id]["xp"] = int(loaded_skills[skill_id].get("xp", 0))
	var loaded_stamina = data.get("stamina", {})
	if typeof(loaded_stamina) == TYPE_DICTIONARY:
		for skill_id in loaded_stamina.keys():
			if stamina.has(skill_id):
				stamina[skill_id] = clampi(int(loaded_stamina[skill_id]), 0, _max_stamina())
	var loaded_bank = data.get("stamina_bank", {})
	if typeof(loaded_bank) == TYPE_DICTIONARY:
		for skill_id in loaded_bank.keys():
			if stamina_bank.has(skill_id):
				stamina_bank[skill_id] = float(loaded_bank[skill_id])
	selected_skill_id = str(data.get("selected_skill_id", selected_skill_id))
	running_skill_id = str(data.get("running_skill_id", ""))
	running_action_id = str(data.get("running_action_id", ""))
	action_progress = float(data.get("action_progress", 0.0))
	is_muted = bool(data.get("is_muted", false))
	last_result = str(data.get("last_result", last_result))
	AudioServer.set_bus_mute(0, is_muted)
	var offline := int(clamp(Time.get_unix_time_from_system() - int(data.get("saved_at", Time.get_unix_time_from_system())), 0, MAX_OFFLINE_SECONDS))
	if offline > 0:
		for skill_id in stamina.keys():
			stamina[skill_id] = mini(_max_stamina(), _stamina(str(skill_id)) + int(floor(float(offline) / STAMINA_REGEN_SECONDS)))


func _skill_level(skill_id: String) -> int:
	return int(skills.get(skill_id, {}).get("level", 1))


func _skill_name(skill_id: String) -> String:
	for def in SKILL_DEFS:
		if str(def["id"]) == skill_id:
			return str(def["name"])
	return skill_id.capitalize()


func _global_level() -> int:
	var total := 0
	for skill_id in skills.keys():
		total += _skill_level(str(skill_id))
	return total


func _max_stamina() -> int:
	return BASE_MAX_STAMINA + int(floor(float(_global_level()) / 10.0))


func _stamina(skill_id: String) -> int:
	return clampi(int(stamina.get(skill_id, _max_stamina())), 0, _max_stamina())


func _xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return int(round(22.0 * pow(float(level - 1), 2.08)))


func _xp_progress(skill_id: String) -> Dictionary:
	var level := _skill_level(skill_id)
	var xp_total := int(skills.get(skill_id, {}).get("xp", 0))
	var start := _xp_for_level(level)
	var end := _xp_for_level(level + 1)
	var current := xp_total - start
	var needed := maxi(1, end - start)
	return {"current": current, "needed": needed, "pct": clampf(float(current) / float(needed) * 100.0, 0.0, 100.0)}


func _recalculate_level(skill_id: String) -> void:
	var xp_total := int(skills[skill_id]["xp"])
	var old_level := int(skills[skill_id].get("level", 1))
	var level := 1
	while level < 99 and xp_total >= _xp_for_level(level + 1):
		level += 1
	skills[skill_id]["level"] = level
	if level > old_level:
		_play(level_player)


func _action_data(skill_id: String, action_id: String) -> Dictionary:
	for action in actions_by_skill.get(skill_id, []):
		if str(action["id"]) == action_id:
			return action
	return {}


func _action_key(skill_id: String, action_id: String) -> String:
	return "%s:%s" % [skill_id, action_id]


func _title_from_asset(file_name: String) -> String:
	var base := file_name.get_basename()
	if base.length() > 3 and base.substr(2, 1) == "-":
		base = base.substr(3)
	var words := base.replace("-s-", "'s-").split("-")
	for i in range(words.size()):
		words[i] = str(words[i]).capitalize()
	return " ".join(words)


func _slug(text: String) -> String:
	return text.to_lower().replace("'", "").replace(",", "").replace(" ", "-")


func _format_seconds(seconds: float) -> String:
	return "%.1f" % seconds if seconds < 10.0 else "%.0f" % seconds


func _load_font() -> void:
	if ResourceLoader.exists("res://assets/fonts/Fredoka.ttf"):
		app_font = load("res://assets/fonts/Fredoka.ttf")


func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if app_font != null:
		label.add_theme_font_override("font", app_font)
	return label


func _image(path: String, minimum_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _texture(path)
	image.custom_minimum_size = minimum_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _icon_button(path: String) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(300, 300)
	button.texture_normal = _texture(path)
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	return button


func _nav_button(path: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(280, 280)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.icon = _texture(path)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 190)
	return button


func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 220)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 72)
	if app_font != null:
		button.add_theme_font_override("font", app_font)
	button.add_theme_color_override("font_color", COLOR_INK)
	button.add_theme_color_override("font_hover_color", COLOR_INK)
	button.add_theme_color_override("font_pressed_color", COLOR_INK)
	button.add_theme_stylebox_override("normal", _panel_style(COLOR_PANEL, 12, 48))
	button.add_theme_stylebox_override("hover", _panel_style(COLOR_GOLD, 12, 48))
	button.add_theme_stylebox_override("pressed", _panel_style(COLOR_GOLD.darkened(0.08), 12, 48))
	return button


func _action_stat_label(text: String) -> Label:
	var label := _label(text, 42, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _action_stat_box(label: Label) -> PanelContainer:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(360, 132)
	box.add_theme_stylebox_override("panel", _stat_box_style())
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return box


func _progress(fill: Color, height: int, value := 0.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.add_theme_stylebox_override("background", _progress_style(Color("#fff1c8")))
	bar.add_theme_stylebox_override("fill", _progress_style(fill))
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _set_bar(bar, target: float, delta: float, instant: bool) -> void:
	if bar == null:
		return
	var progress := bar as ProgressBar
	if instant or delta <= 0.0:
		progress.value = target
	else:
		progress.value = lerpf(float(progress.value), target, 1.0 - exp(-12.0 * delta))


func _panel_style(color: Color, border: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLOR_INK
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_width_bottom = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 72
	style.content_margin_right = 72
	style.content_margin_top = 58
	style.content_margin_bottom = 58
	return style


func _action_card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLOR_INK
	style.border_width_left = 16
	style.border_width_right = 16
	style.border_width_top = 16
	style.border_width_bottom = 16
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _action_art_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d9ffd4")
	style.border_color = COLOR_INK
	style.border_width_left = 9
	style.border_width_right = 9
	style.border_width_top = 9
	style.border_width_bottom = 9
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _stat_box_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.72)
	style.border_color = COLOR_INK
	style.border_width_left = 9
	style.border_width_right = 9
	style.border_width_top = 9
	style.border_width_bottom = 9
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _nav_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_NAV
	style.content_margin_left = 96
	style.content_margin_right = 96
	style.content_margin_top = 36
	style.content_margin_bottom = BOTTOM_NAV_SAFE_PAD
	return style


func _progress_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = COLOR_INK
	style.border_width_left = 9
	style.border_width_right = 9
	style.border_width_top = 9
	style.border_width_bottom = 9
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	return style


func _apply_nav_style(button: Button, active: bool) -> void:
	button.add_theme_stylebox_override("normal", _nav_tab_style(active))
	button.add_theme_stylebox_override("hover", _nav_tab_style(true))
	button.add_theme_stylebox_override("pressed", _nav_tab_style(true))


func _nav_tab_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = COLOR_GOLD
	var border := 18 if active else 0
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_width_bottom = border
	style.corner_radius_top_left = 52
	style.corner_radius_top_right = 52
	style.corner_radius_bottom_left = 52
	style.corner_radius_bottom_right = 52
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	return style


func _texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _chroma_material(chroma: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec4 chroma_key : source_color = vec4(0.0, 1.0, 0.0, 1.0);
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float distance_from_key = distance(color.rgb, chroma_key.rgb);
	if (distance_from_key < 0.30) {
		color.a = 0.0;
	}
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("chroma_key", chroma)
	return material


func _hero_chroma_material() -> ShaderMaterial:
	return _chroma_material(Color("#ffffff"))


func _build_audio() -> void:
	click_player = _sfx("res://assets/sfx/click.wav")
	success_player = _sfx("res://assets/sfx/action_success_ding.wav")
	level_player = _sfx("res://assets/sfx/level_up_jingle.wav")


func _sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player


func _play(player: AudioStreamPlayer) -> void:
	if player != null and not is_muted:
		player.stop()
		player.play()


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
