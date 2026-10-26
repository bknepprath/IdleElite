extends RefCounted

# Views only. Simulation, identity, saves and network scheduling remain on main.
var host
var ready := false
var rendering := false
var columns: Array[Dictionary] = []
var all_columns: Array[Dictionary] = []
var carousel_frame: Control
var carousel_left := 0.0
var carousel_tracking := false
var carousel_dragging := false
var carousel_start := Vector2.ZERO
var carousel_tween: Tween
var carousel_settling := false
var skill_slots: Array[String] = []
var scroll_positions := {}
var detail_bookmarks := {}
var remembered_focus := ""
var reflow_anchor := ""
var reflow_anchor_index := 0
var preferred_column_indices := {}
var focused_index := 0
var column_width := 1014.0
var toolbar: PanelContainer
var skill_navigation: Control
var carousel_discovered := false
var pending_column_refreshes: Array[String] = []
var ribbon_buttons := {}
var ribbon_state := ""
var atmosphere: ColorRect
var hub_inspector: Control
var social_panel: Control
var scores_content: Control
var scores_scroll_category := ""
var social_tab := ""
var social_dark_mode := false
var last_layout_size := Vector2.ZERO
var resize_elapsed := 0.0
var last_window_size := Vector2i.ZERO
var last_page_count := 0
var secondary_refresh_elapsed := 0.0
var selector_root: Control
var selector_panel: PanelContainer
var selector_return_focus: WeakRef
var social_transition := false
var page_transition := false
var preferences_restored := false
var intro_stage := 3
const INTRO_NEIGHBOR_FADE_SECONDS := 0.55
const INTRO_NEIGHBOR_STAGGER_SECONDS := 1.25
const INTRO_REVEAL_SECONDS := 1.8
const INTRO_UI_FADE_SECONDS := 0.65
var intro_reveal_elapsed := INTRO_REVEAL_SECONDS
var intro_ribbon_elapsed := INTRO_UI_FADE_SECONDS
var intro_guided := false
var intro_features: Array[String] = []
var intro_feature_cooldown := 30.0
var intro_feature_key := ""
var intro_feature_elapsed := INTRO_UI_FADE_SECONDS
var intro_feature_check_elapsed := 0.0
const INTRO_FEATURE_INTERVAL := 30.0
const INTRO_FEATURE_KEYS := ["pinned", "queue", "hub", "shop", "home", "scores", "chat"]
var pending_social: Variant = null
# The tab a transition in flight is heading for.
var social_target := ""
const OPEN_SECONDS := 0.26
const CLOSE_SECONDS := 0.18

const GAP := 36.0
const EDGE := 32.0
const TOP := 0.0
const RIBBON_HEIGHT := 166.0
const SOCIAL_WIDTH := 1030.0
const MIN_COLUMN_PIXELS := 440.0
# The narrowest a page may be. A page is laid out for the phone, where it is 984
# wide. Its header needs about 875 for the gauge to sit beside the title. The
# longest activity name is 595 wide at the title's size; beside the widest medal
# (165 wide), and with the title's outline size (17) kept clear of the medal as
# well, it needs a page of 992. A screen with less room than that for each of
# three pages (a 16:10 screen has 979) shows two wider pages.
const MIN_COLUMN_CANVAS := 993.0
const MAX_COLUMN_PIXELS := 1024.0
const MAX_COLUMN_CANVAS := 1550.0
const INFO_BUTTON_SIZE := Vector2(56, 56)

static func fitted_window_rect(usable: Rect2i, preferred: Vector2i, decorations: Vector2i) -> Rect2i:
	var room := Vector2i(maxi(1, usable.size.x - decorations.x - 48), maxi(1, usable.size.y - decorations.y - 48))
	var ratio := minf(1.0, minf(float(room.x) / preferred.x, float(room.y) / preferred.y))
	var dimensions := Vector2i(Vector2(preferred) * ratio)
	var origin := usable.position + (usable.size - dimensions - decorations) / 2
	return Rect2i(origin, dimensions)

static func fit_startup_window(window: Window) -> void:
	if OS.has_feature("web") or OS.has_feature("android") or DisplayServer.get_name() == "headless": return
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var decorations := window.get_size_with_decorations() - window.size
	# Some window managers do not report decorations before the first visible frame.
	decorations = Vector2i(maxi(16, decorations.x), maxi(48, decorations.y))
	var target := fitted_window_rect(usable, Vector2i(1600, 900), decorations)
	window.min_size = Vector2i(mini(800, target.size.x), mini(600, target.size.y))
	window.size = target.size
	window.position = target.position + Vector2i(decorations.x / 2, decorations.y - decorations.x / 2)

func canvas_pixel_scale() -> float:
	return float(host.get_window().size.x) / maxf(1.0, host._current_canvas_size().x)

static func columns_for_space(canvas_width: float, pixel_scale: float) -> int:
	var minimum := maxf(MIN_COLUMN_CANVAS, MIN_COLUMN_PIXELS / maxf(0.01, pixel_scale))
	return clampi(int(floor((canvas_width - EDGE * 2 + GAP) / (minimum + GAP))), 1, 3)

func column_capacity(with_social := true) -> int:
	return columns_for_space(gameplay_width() if with_social else host._current_canvas_size().x, canvas_pixel_scale())

func fitted_column_width(count: int) -> float:
	# The pixel cap stops a page growing on a large screen; it never makes one
	# narrower than the narrowest page allowed. Where a window is more than about
	# 2000 pixels high, 1024 pixels are fewer units than that, and a page cut down
	# to them lost the right side of its header gauge and ran titles into medals.
	var limit := maxf(MIN_COLUMN_CANVAS, minf(MAX_COLUMN_CANVAS, MAX_COLUMN_PIXELS / maxf(0.01, canvas_pixel_scale())))
	return minf(limit, (gameplay_width() - EDGE * 2 - GAP * (count - 1)) / count)


func _init(owner) -> void:
	host = owner

# Evaluate CSS-style cubic Bezier timing by solving its x coordinate first.
static func bezier_progress(time: float, opening: bool) -> float:
	var c1 := Vector2(0.22, 1.0) if opening else Vector2(0.4, 0.0)
	var c2 := Vector2(0.36, 1.0) if opening else Vector2(1.0, 1.0)
	var low := 0.0
	var high := 1.0
	for i in range(14):
		var t := (low + high) * 0.5
		var x := 3.0 * (1.0 - t) * (1.0 - t) * t * c1.x + 3.0 * (1.0 - t) * t * t * c2.x + t * t * t
		if x < time: low = t
		else: high = t
	var t := (low + high) * 0.5
	return 3.0 * (1.0 - t) * (1.0 - t) * t * c1.y + 3.0 * (1.0 - t) * t * t * c2.y + t * t * t

func animate_panel(control: Control, opening: bool, shift := Vector2.ZERO) -> void:
	if not is_instance_valid(control): return
	var old = control.get_meta("desktop_motion") if control.has_meta("desktop_motion") else null
	var interrupted: bool = old is Tween and old.is_valid() and old.is_running()
	if old is Tween and old.is_valid(): old.kill()
	var origin: Vector2 = control.get_meta("desktop_motion_origin", control.position)
	control.set_meta("desktop_motion_origin", origin)
	var from_alpha := 0.0 if opening and not interrupted else control.modulate.a
	var from_position := origin + shift if opening and not interrupted else control.position
	var to_position := origin if opening else origin + shift
	control.modulate.a = from_alpha
	control.position = from_position
	var tween := control.create_tween()
	control.set_meta("desktop_motion", tween)
	tween.tween_method(func(progress: float):
		var eased := bezier_progress(progress, opening)
		control.modulate.a = lerpf(from_alpha, 1.0 if opening else 0.0, eased)
		control.position = from_position.lerp(to_position, eased)
	, 0.0, 1.0, OPEN_SECONDS if opening else CLOSE_SECONDS)

func animate_modal_visibility(control: Control, showing: bool) -> bool:
	if not enabled() or not control.is_in_group("modal_overlay") or control == host._profile_chat_overlay_surface().chat_overlay or host.shutdown_cleanup_started:
		return false
	if showing:
		control.set_meta("desktop_closing", false)
		control.show()
		animate_panel(control, true)
	else:
		if bool(control.get_meta("desktop_closing", false)): return true
		control.set_meta("desktop_closing", true)
		animate_panel(control, false)
		# Attach hiding to this animation. A separate timer can survive a
		# close/open/close interruption and hide the next animation halfway through.
		var motion: Tween = control.get_meta("desktop_motion")
		motion.tween_callback(_finish_modal_hide.bind(control))
	return true

func _finish_modal_hide(control: Control) -> void:
	if is_instance_valid(control) and bool(control.get_meta("desktop_closing", false)):
		control.hide()
		control.modulate.a = 1.0
		control.set_meta("desktop_closing", false)

func saved_preferences() -> Dictionary:
	remember_scrolls()
	var preferences := {"skills": skill_slots.duplicate(), "scroll": scroll_positions.duplicate(), "focused": focused_index, "intro_stage": intro_stage}
	preferences["carousel_discovered"] = carousel_discovered
	if intro_guided:
		preferences["intro_features"] = intro_features.duplicate()
		preferences["intro_feature_cooldown"] = intro_feature_cooldown
	return preferences

func restore_preferences(value: Variant) -> void:
	skill_slots.clear()
	scroll_positions.clear()
	focused_index = 0
	preferences_restored = false
	carousel_discovered = value is Dictionary and value.get("carousel_discovered", false) == true
	# Saves from before staged onboarding retain their full desktop interface.
	intro_stage = 3
	intro_reveal_elapsed = INTRO_REVEAL_SECONDS
	intro_ribbon_elapsed = INTRO_UI_FADE_SECONDS
	intro_guided = false
	intro_features.clear()
	intro_feature_key = ""
	intro_feature_elapsed = INTRO_UI_FADE_SECONDS
	intro_feature_cooldown = INTRO_FEATURE_INTERVAL
	if not value is Dictionary: return
	var stage = value.get("intro_stage", 3)
	if (stage is int or stage is float) and is_finite(float(stage)):
		intro_stage = clampi(int(stage), 0, 3)
	intro_guided = value.has("intro_features") or intro_stage < 3
	var features = value.get("intro_features", [])
	if features is Array:
		for key in features:
			if key is String and key in INTRO_FEATURE_KEYS and not key in intro_features: intro_features.append(key)
	var cooldown = value.get("intro_feature_cooldown", INTRO_FEATURE_INTERVAL)
	if (cooldown is int or cooldown is float) and is_finite(float(cooldown)):
		intro_feature_cooldown = clampf(float(cooldown), 0.0, INTRO_FEATURE_INTERVAL)
	var ids: Array[String] = []
	for definition in host.skill_defs: ids.append(str(definition.id))
	var stored = value.get("skills", [])
	if stored is Array:
		for id in stored:
			if id is String and id in ids and not id in skill_slots and skill_slots.size() < 3: skill_slots.append(id)
	if not skill_slots.is_empty(): rotate_slots(skill_slots[0])
	var scroll = value.get("scroll", {})
	if scroll is Dictionary:
		for id in ids:
			var amount = scroll.get(id, 0)
			if (amount is int or amount is float) and is_finite(float(amount)):
				scroll_positions[id] = clampi(int(amount), 0, 1000000)
	var focus = value.get("focused", 0)
	if (focus is int or focus is float) and is_finite(float(focus)): focused_index = clampi(int(focus), 0, 2)
	preferences_restored = not skill_slots.is_empty()

func style_scroll(scroll: ScrollContainer) -> void:
	scroll.set_meta("desktop_scrollbar", true)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var bar := scroll.get_v_scroll_bar()
	bar.custom_minimum_size.x = 12
	for state in ["scroll", "scroll_focus"]:
		var track := StyleBoxFlat.new()
		track.bg_color = Color.TRANSPARENT
		track.content_margin_left = 6
		track.content_margin_right = 6
		bar.add_theme_stylebox_override(state, track)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = Color(0.6, 0.6, 0.6, 0.65) if host.dark_mode_enabled else Color(0.3, 0.29, 0.26, 0.32 if state == "grabber" else 0.6)
		grabber.set_corner_radius_all(6)
		grabber.content_margin_top = 24
		grabber.content_margin_bottom = 24
		bar.add_theme_stylebox_override(state, grabber)

func available() -> bool:
	return not OS.has_feature("android") and (OS.has_feature("web") or OS.has_feature("desktop_layout") or OS.get_environment("IDLE_ELITE_DESKTOP") == "1")

func enabled() -> bool:
	return ready and available() and host._current_canvas_size().x > host._current_canvas_size().y * 1.25

func configure_window() -> void:
	if not available():
		return
	var window: Window = host.get_window()
	# Desktop renders at the actual window resolution; Android retains viewport stretch.
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	# In a browser the page decides the frame. A minimum here made the game lay
	# itself out 800 wide inside a narrower frame (itch's 540 x 960 embed, a phone
	# held upright): shifted right and cut off until the frame was next resized.
	if not OS.has_feature("web"):
		window.min_size = Vector2i(800, 600)
	if OS.has_feature("desktop_layout") and not OS.has_feature("web"):
		fit_startup_window(window)

func start() -> void:
	if ready: return
	ready = true
	if not enabled():
		return
	if host._onboarding_runtime().tutorial_active: reset_intro()
	if not skill_slots.is_empty(): host.selected_skill_id = skill_slots[mini(focused_index, skill_slots.size() - 1)]
	build_toolbar()
	last_layout_size = host._current_canvas_size()
	last_window_size = host.get_window().size
	last_page_count = page_count()
	await host._navigation_shell()._render_screen()

func page_count() -> int:
	if host._onboarding_runtime().tutorial_active or intro_stage < 2: return 1
	var total := column_capacity()
	# Keep Fighting centered until all three initial columns fit.
	if intro_stage == 2 and total < 3: return 1
	return total

func reset_intro() -> void:
	scroll_positions.clear()
	detail_bookmarks.clear()
	preferred_column_indices.clear()
	remembered_focus = ""
	reflow_anchor = ""
	carousel_discovered = false
	intro_guided = true
	intro_features.clear()
	intro_feature_key = ""
	intro_feature_elapsed = INTRO_UI_FADE_SECONDS
	intro_feature_cooldown = INTRO_FEATURE_INTERVAL
	intro_stage = 0
	intro_reveal_elapsed = 0.0
	intro_ribbon_elapsed = 0.0

func update_intro(delta: float) -> void:
	if not enabled() or rendering or host._navigation_shell().screen_render_in_progress: return
	var onboarding = host._onboarding_runtime()
	if not onboarding.tutorial_active and intro_stage < 3:
		var level := int(host.skills.get("fight", {}).get("level", 1))
		var next := intro_stage
		if onboarding.onboarding_starter_action_completion_count >= 1: next = maxi(next, 1)
		if onboarding.onboarding_starter_action_completion_count >= 2 or level >= 2: next = maxi(next, 2)
		var explored := false
		for id in host.skills:
			if id != "fight" and float(host.skills[id].get("xp", 0)) > 0: explored = true
		if level >= 3 or explored: next = 3
		if next > intro_stage:
			if intro_stage < 2 and next >= 2:
				# Introduce the two neighbors around Fighting, without moving it left.
				rotate_slots("fishing" if column_capacity(false) >= 3 else "fight")
				focused_index = 1 if column_capacity(false) >= 3 else 0
				host.selected_skill_id = "fight"
				preferences_restored = false
				intro_reveal_elapsed = 0.0
				intro_feature_cooldown = INTRO_FEATURE_INTERVAL
			if intro_stage == 0: intro_ribbon_elapsed = 0.0
			intro_stage = next
			sync_shell()
			host.save_game()
	# Begin only after the new pages are mounted. Keep the clock across rerenders.
	if intro_stage >= 2 and intro_reveal_elapsed < INTRO_REVEAL_SECONDS and columns.size() == page_count():
		intro_reveal_elapsed = minf(INTRO_REVEAL_SECONDS, intro_reveal_elapsed + delta)
		apply_intro_reveal()
	if intro_ribbon_elapsed < INTRO_UI_FADE_SECONDS:
		intro_ribbon_elapsed = minf(INTRO_UI_FADE_SECONDS, intro_ribbon_elapsed + delta)
		apply_intro_ribbon()
	apply_intro_activity_reveal()
	update_intro_features(delta)

func intro_feature_eligible(key: String) -> bool:
	var nav = host._navigation_shell()
	match key:
		"pinned": return not host.module_ui_runtime.pinned_order.is_empty()
		"queue": return intro_stage >= 2
		"hub": return nav._hub_unlocked()
		"shop": return nav._shop_unlocked()
		"home", "scores": return nav._hero_unlocked()
		"chat": return preload("res://scripts/progression/skill_state.gd").global_level(host.skills) >= 30
	return false

func update_intro_features(delta: float) -> void:
	if not intro_guided: return
	if intro_feature_elapsed < INTRO_UI_FADE_SECONDS:
		intro_feature_elapsed = minf(INTRO_UI_FADE_SECONDS, intro_feature_elapsed + delta)
		apply_intro_ribbon()
	if intro_stage < 2 or intro_reveal_elapsed < INTRO_REVEAL_SECONDS or host.current_screen != "skill" or carousel_tracking or host._input_routing_shell()._any_modal_overlay_visible(): return
	intro_feature_cooldown = maxf(0.0, intro_feature_cooldown - delta)
	intro_feature_check_elapsed += delta
	if intro_feature_cooldown > 0.0 or intro_feature_check_elapsed < 0.5: return
	intro_feature_check_elapsed = 0.0
	for key in INTRO_FEATURE_KEYS:
		if key in intro_features or not intro_feature_eligible(key): continue
		intro_features.append(key)
		intro_feature_key = key
		intro_feature_elapsed = 0.0
		intro_feature_cooldown = INTRO_FEATURE_INTERVAL
		apply_intro_ribbon()
		host.save_game()
		break

# Cubic Bezier with x controls 1/3 and 2/3, y controls 0 and 1.
# Unlike the menu ease-out curve, this keeps a gradual start and finish.
static func intro_fade(time: float) -> float:
	var t := clampf(time, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func apply_intro_activity_reveal() -> void:
	if not intro_guided: return
	var card: Dictionary = host.action_cards.get(host.TUTORIAL_STARTER_SKILL_ID + ":" + host.TUTORIAL_LEVEL_TWO_ACTION_ID, {})
	var control = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
	if is_instance_valid(control):
		if intro_ribbon_elapsed >= INTRO_UI_FADE_SECONDS:
			if control.has_meta("intro_activity_reveal_active"):
				preload("res://scripts/ui/reveal_cover.gd").apply(control, 1.0, host)
				control.remove_meta("intro_activity_reveal_active")
			return
		control.set_meta("intro_activity_reveal_active", true)
		preload("res://scripts/ui/reveal_cover.gd").apply(control, intro_fade(intro_ribbon_elapsed / host.ACTIVITY_PREVIEW_FADE_IN_SECONDS), host)

func apply_intro_reveal() -> void:
	for column in all_columns:
		var delay := INTRO_NEIGHBOR_STAGGER_SECONDS if column.skill_id == "thieving" else 0.0
		preload("res://scripts/ui/reveal_cover.gd").apply(column.page, 1.0 if column.skill_id == "fight" else intro_fade((intro_reveal_elapsed - delay) / INTRO_NEIGHBOR_FADE_SECONDS), host)
	if is_instance_valid(atmosphere):
		atmosphere.material.set_shader_parameter("reveal", 0.0 if intro_stage < 2 else intro_fade(intro_reveal_elapsed / INTRO_REVEAL_SECONDS))

func apply_intro_ribbon() -> void:
	if is_instance_valid(toolbar):
		toolbar.modulate.a = intro_fade(intro_ribbon_elapsed / INTRO_UI_FADE_SECONDS)
	for key in ribbon_buttons:
		var button: Button = ribbon_buttons[key]
		var allowed := ribbon_feature_available(key)
		var amount := 1.0
		if intro_guided and key == intro_feature_key:
			amount = intro_fade(intro_feature_elapsed / INTRO_UI_FADE_SECONDS)
		button.modulate = Color(0, 0, 0, 0.38).lerp(Color.WHITE, amount) if allowed else Color(0, 0, 0, 0.38)
		button.set_meta("nav_locked", not allowed)
		# Locked icons accept inspection, but activation is guarded separately.
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_ALL

func ribbon_feature_available(key: String) -> bool:
	return key in ["skill", "settings"] or not intro_guided or key in intro_features

func ribbon_requirement(key: String) -> String:
	if intro_feature_eligible(key):
		var seconds := intro_feature_cooldown
		for candidate in INTRO_FEATURE_KEYS:
			if candidate == key: break
			if candidate not in intro_features and intro_feature_eligible(candidate): seconds += INTRO_FEATURE_INTERVAL
		return "Available in about %d seconds\nwhile playing Skills." % maxi(1, int(ceil(seconds)))
	match key:
		"pinned": return "Pin an activity using its upper-left corner."
		"queue": return "Complete two activities to reveal more skills."
		"hub": return "Reach Building level %d." % host._navigation_shell().HUB_UNLOCK_BUILD_LEVEL
		"shop": return "Earn %d Bronze medals." % host._navigation_shell().SHOP_UNLOCK_BRONZE_MEDALS
		"home", "scores": return "Reach total level %d." % host._navigation_shell().HERO_UNLOCK_TOTAL_LEVEL
		"chat": return "Reach total level 30."
	return "Complete your first activity."

func activate_ribbon(key: String) -> void:
	if not ribbon_feature_available(key):
		host._navigation_shell()._float_nav_locked_message(ribbon_buttons[key], ribbon_requirement(key))
		return
	if key in ["chat", "scores"]:
		# The icon toggles where the panel is heading, not where a transition in
		# flight happens to stand: a click while the panel closes opens it again.
		set_social("" if social_destination() == key else key)
	else:
		navigate(key)

# Where the social panel will be once everything asked of it is done.
func social_destination() -> String:
	if pending_social != null: return str(pending_social)
	return social_target if social_transition else social_tab

func gameplay_width() -> float:
	return host._current_canvas_size().x - (SOCIAL_WIDTH + GAP if not social_tab.is_empty() else 0.0)

func build_toolbar() -> void:
	if is_instance_valid(toolbar): return
	var nav = host._navigation_shell()
	toolbar = PanelContainer.new()
	toolbar.name = "DesktopRibbon"
	# Column construction can yield. Only sync_shell reveals the finished ribbon.
	toolbar.hide()
	toolbar.z_index = 1800
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toolbar.offset_top = -RIBBON_HEIGHT
	var paper := StyleBoxFlat.new()
	paper.bg_color = host.COLOR_NAV
	paper.border_color = Color("#282b34")
	paper.border_width_top = 4
	paper.content_margin_left = 44
	paper.content_margin_right = 44
	paper.content_margin_top = 12
	paper.content_margin_bottom = 12
	toolbar.add_theme_stylebox_override("panel", paper)
	host.add_child(toolbar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	toolbar.add_child(row)
	add_ribbon_button(row, "pinned", "Pinned", "res://assets/content/ui/navigation-controls/pin.png", 102)
	add_ribbon_button(row, "queue", "Queue", "res://assets/content/ui/navigation-controls/queue.png", 102)
	var left_space := Control.new()
	left_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left_space)
	for entry in [["home", "Progress", host.PROGRESS_STAR_ICON_TEXTURE], ["hub", "Hub", "res://assets/content/hub/hub-nav-barn.png"], ["skill", "Skills", host.TOTAL_LEVEL_BARGRAPH_TEXTURE], ["shop", "Shop", host.SHOP_ICON_TEXTURE], ["settings", "Settings", host.SETTINGS_GEAR_ICON_TEXTURE]]:
		add_ribbon_button(row, entry[0], entry[1], entry[2], 134)
	var right_space := Control.new()
	right_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right_space)
	add_ribbon_button(row, "chat", "Chat", "res://assets/content/ui/chat-speech-bubble.png", 102)
	add_ribbon_button(row, "scores", "High Scores", "res://assets/content/ui/leaderboard-podium-icon.png", 102)
	skill_navigation = preload("res://scripts/ui/desktop_skill_navigation.gd").new()
	host.add_child(skill_navigation)
	skill_navigation.setup(self)

func add_ribbon_button(row: HBoxContainer, key: String, label: String, path: String, width: float) -> void:
	var button: Button = host._navigation_shell()._nav_button(path)
	button.name = key.capitalize()
	button.tooltip_text = label
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(width, 134)
	button.add_theme_constant_override("icon_max_width", int(width * 0.76))
	button.set_meta("nav_open_icon_disabled", true)
	host._navigation_shell()._ensure_nav_icon_stroke(button)
	button.pressed.connect(activate_ribbon.bind(key))
	row.add_child(button)
	ribbon_buttons[key] = button

func update_ribbon() -> void:
	var state: String = host.current_screen + ":" + social_tab
	if state == ribbon_state: return
	ribbon_state = state
	for key in ribbon_buttons:
		var button: Button = ribbon_buttons[key]
		var active: bool = (social_tab == key) if key in ["chat", "scores"] else host.current_screen == key
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#656d80") if active else Color.TRANSPARENT
		normal.set_corner_radius_all(20)
		normal.shadow_color = Color(0, 0, 0, 0.18 if active else 0.0)
		normal.shadow_size = 16 if active else 0
		normal.shadow_offset = Vector2(0, 4)
		button.add_theme_stylebox_override("normal", normal)
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(1, 1, 1, 0.20)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		var focus := StyleBoxFlat.new()
		focus.draw_center = false
		focus.border_color = Color("#bbc4d7")
		focus.set_border_width_all(3)
		focus.set_corner_radius_all(20)
		button.add_theme_stylebox_override("focus", focus)

func make_skill_title(skill_id: String, _slot: int, font_size: int) -> Label:
	var title := Label.new()
	title.name = "DesktopSkillTitle"
	title.text = str(host.skill_defs.filter(func(definition): return str(definition.id) == skill_id)[0].name)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_override("font", host.app_bold_font)
	title.add_theme_font_size_override("font_size", mini(font_size, 58))
	title.add_theme_color_override("font_color", panel_ink())
	return title

func skill_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition in host.skill_defs: ids.append(str(definition.id))
	return ids

func rotate_slots(leading: String) -> void:
	var ids := skill_ids()
	var start := maxi(0, ids.find(leading))
	skill_slots.clear()
	for i in range(3): skill_slots.append(ids[(start + i) % ids.size()])

func open_selector(source: Control, entries: Array, selected: int, callback: Callable) -> void:
	if is_instance_valid(selector_root): return
	selector_return_focus = weakref(source)
	selector_root = Control.new()
	selector_root.name = "DesktopSelector"
	selector_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selector_root.z_index = 2400
	selector_root.add_to_group("modal_overlay")
	host.add_child(selector_root)
	selector_root.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed: close_selector()
	)
	selector_panel = PanelContainer.new()
	selector_panel.name = "Choices"
	selector_panel.add_theme_stylebox_override("panel", panel_style(panel_fill(), true, 16))
	selector_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	selector_panel.custom_minimum_size.x = 540
	var point := source.get_global_rect().end
	selector_panel.position = Vector2(clampf(source.global_position.x, EDGE, host.size.x - 580), point.y + 20)
	selector_root.add_child(selector_panel)
	var list := VBoxContainer.new()
	list.name = "Items"
	list.add_theme_constant_override("separation", 8)
	selector_panel.add_child(list)
	for i in range(entries.size()):
		var button := make_button(str(entries[i].text))
		button.name = "Choice" + str(i)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 96
		button.add_theme_constant_override("h_separation", 24)
		if not str(entries[i].get("icon", "")).is_empty():
			button.icon = host.visual_texture_cache._texture_or_visual_fallback(entries[i].icon)
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", 70)
		style_button(button, i == selected)
		button.pressed.connect(func():
			await close_selector()
			callback.call(i)
		)
		list.add_child(button)
	list.get_child(selected).grab_focus()
	animate_panel(selector_panel, true, Vector2(0, -24))

func close_selector() -> void:
	if not is_instance_valid(selector_root) or bool(selector_root.get_meta("closing", false)): return
	var closing := selector_root
	closing.set_meta("closing", true)
	animate_panel(selector_panel, false, Vector2(0, -18))
	await host.get_tree().create_timer(CLOSE_SECONDS).timeout
	if is_instance_valid(closing): closing.queue_free()
	selector_root = null
	selector_panel = null
	var source = selector_return_focus.get_ref() if selector_return_focus != null else null
	if is_instance_valid(source): source.grab_focus()

func add_atmosphere() -> void:
	atmosphere = ColorRect.new()
	atmosphere.name = "ContinuousSkillHeaderColor"
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atmosphere.position.x = carousel_left - column_width - GAP - EDGE
	atmosphere.size = Vector2((column_width + GAP) * 5 + EDGE * 2, 440)
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec4 paper : source_color;
uniform vec4 colors[5] : source_color;
uniform vec4 intro_color : source_color;
uniform float reveal = 1.0;
uniform float first_center;
uniform float spacing;
void fragment() {
 vec4 tint = colors[0];
 for (int i = 1; i < 5; i++) {
  tint = mix(tint, colors[i], smoothstep(first_center + float(i - 1) * spacing, first_center + float(i) * spacing, UV.x));
 }
 float strength = (0.12 + 0.20 * smoothstep(0.0, 0.5, UV.y)) * (1.0 - smoothstep(0.52, 1.0, UV.y));
 COLOR = mix(paper, mix(intro_color, tint, reveal), strength);
} """
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("paper", host._theme_paper_color())
	material.set_shader_parameter("intro_color", preload("res://scripts/ui/theme_styles.gd").skill_theme_color("fight", host.COLOR_BLUE))
	material.set_shader_parameter("first_center", (EDGE + column_width * 0.5) / atmosphere.size.x)
	material.set_shader_parameter("spacing", (column_width + GAP) / atmosphere.size.x)
	atmosphere.material = material
	carousel_frame.add_child(atmosphere)
	update_atmosphere()

func update_atmosphere() -> void:
	if not is_instance_valid(atmosphere): return
	var ids := skill_ids()
	var leading := ids.find(skill_slots[0])
	var colors := PackedColorArray()
	var theme = preload("res://scripts/ui/theme_styles.gd")
	for i in range(-1, 4):
		colors.append(theme.skill_theme_color(ids[posmod(leading + i, ids.size())], host.COLOR_BLUE))
	atmosphere.material.set_shader_parameter("colors", colors)
	apply_intro_reveal()

func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 76
	style_button(button)
	if host.app_bold_font != null:
		button.add_theme_font_override("font", host.app_bold_font)
	return button

func panel_ink() -> Color:
	return Color("#eeeae2") if host.dark_mode_enabled else Color("#38372f")

func panel_fill() -> Color:
	return Color("#2d3036") if host.dark_mode_enabled else Color("#faf6ee")

func inset_fill() -> Color:
	return Color("#383d44") if host.dark_mode_enabled else Color("#eee8dc")

func panel_style(fill: Color, elevated := false, padding := 24) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(28 if elevated else 18)
	box.corner_detail = 12
	box.set_content_margin_all(padding)
	if elevated:
		box.shadow_color = Color(0.05, 0.04, 0.03, 0.14)
		box.shadow_size = 34
		box.shadow_offset = Vector2(0, 12)
	return box

func add_panel_backdrop(parent: Control) -> void:
	var panel := Panel.new()
	panel.name = "PanelSurface"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", panel_style(panel_fill(), true, 0))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	parent.move_child(panel, 0)

func soften_labels(node: Node, font_size := 42) -> void:
	if node is Label:
		node.add_theme_color_override("font_color", panel_ink())
		node.add_theme_constant_override("outline_size", 0)
		node.add_theme_font_size_override("font_size", font_size)
	for child in node.get_children(): soften_labels(child, font_size)

func style_hub_text(node: Node) -> void:
	if node is Label or node is Button:
		node.add_theme_color_override("font_color", Color.WHITE)
		node.add_theme_color_override("font_outline_color", host.COLOR_INK)
		node.add_theme_constant_override("outline_size", maxi(8, roundi(node.get_theme_font_size("font_size") * 0.20)))
		if node is Button:
			for state in ["font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
				node.add_theme_color_override(state, Color.WHITE)
	for child in node.get_children(): style_hub_text(child)

func style_button(button: Button, selected := false) -> void:
	button.add_theme_font_size_override("font_size", 42)
	button.add_theme_constant_override("outline_size", 0)
	for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, panel_ink())
	button.add_theme_color_override("font_disabled_color", panel_ink().lerp(panel_fill(), 0.5))
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var active: bool = selected or state in ["pressed", "hover_pressed"]
		var fill := inset_fill() if active else panel_fill()
		if state == "hover": fill = inset_fill().lerp(panel_fill(), 0.4)
		var box := panel_style(fill, false, 18)
		button.add_theme_stylebox_override(state, box)
	var focus := panel_style(Color.TRANSPARENT, false, 18)
	focus.border_color = panel_ink().lerp(panel_fill(), 0.5)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)

func hub_left_width() -> float:
	return SOCIAL_WIDTH + GAP if host.current_screen == "hub" and host._hub_surface().hub_detail_open else 0.0

func dock_hub_panel() -> void:
	var hub = host._hub_surface()
	if not hub.hub_detail_open or not is_instance_valid(hub.hub_detail_panel): return
	var rail := Control.new()
	rail.name = "HubInspector"
	rail.position = Vector2(EDGE, 28)
	rail.z_index = 200
	hub_inspector = rail
	rail.size = Vector2(SOCIAL_WIDTH - EDGE, host._current_canvas_size().y - RIBBON_HEIGHT - 56)
	rail.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(rail)
	add_panel_backdrop(rail)
	var close := make_button("Back to hub")
	close.name = "CloseInspector"
	close.tooltip_text = "Close details"
	close.position = Vector2(32, 24)
	close.size = Vector2(300, 76)
	close.pressed.connect(hub._close_hub_detail_popup)
	rail.add_child(close)
	var panel: Control = hub.hub_detail_panel
	var scroll := ScrollContainer.new()
	scroll.name = "InspectorScroll"
	scroll.position = Vector2(32, 132)
	scroll.size = Vector2(SOCIAL_WIDTH - EDGE - 64, rail.size.y - 164)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	rail.add_child(scroll)
	style_scroll(scroll)
	panel.reparent(scroll, false)
	panel.position = Vector2.ZERO
	panel.custom_minimum_size.x = scroll.size.x - 16
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size.x = scroll.size.x - 16
	if panel is PanelContainer:
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var stack: VBoxContainer = panel.get_child(0).get_child(0)
		stack.add_theme_constant_override("separation", 30)
		var art = hub.hub_module_art.get(host._hub_runtime().hub_selected_module_id) if host._hub_runtime().hub_selected_module_id != "mission" else null
		if is_instance_valid(art):
			var portrait := TextureRect.new()
			portrait.name = "SelectedBuilding"
			portrait.texture = art.texture
			portrait.custom_minimum_size = Vector2(0, 320)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stack.add_child(portrait)
			stack.move_child(portrait, 0)
			soften_labels(stack, 42)
			hub.hub_detail_title.add_theme_font_size_override("font_size", 56)
			if is_instance_valid(hub.hub_detail_button): style_button(hub.hub_detail_button, true)
			style_hub_text(stack)

	animate_panel(rail, true, Vector2(-36, 0))

func navigate(screen: String) -> void:
	cancel_carousel()
	if rendering or page_transition or host._input_routing_shell()._any_modal_overlay_visible():
		return
	page_transition = true
	remember_scrolls()
	var outgoing: Control = host.home_page if host.current_screen == "home" else host.skills_content
	animate_panel(outgoing, false)
	if is_instance_valid(hub_inspector): animate_panel(hub_inspector, false, Vector2(-36, 0))
	await host.get_tree().create_timer(CLOSE_SECONDS).timeout
	outgoing.modulate.a = 1.0
	if screen == "skill" and not remembered_focus.is_empty():
		host.selected_skill_id = remembered_focus
	match screen:
		"home": host._navigation_shell()._show_home()
		"hub": host._navigation_shell()._show_hub()
		"settings": host._settings_surface()._show_settings()
		"shop": host._navigation_shell()._show_shop(ribbon_buttons.get("shop"))
		_:
			host.current_screen = screen
			host._navigation_shell()._render_screen()
	sync_shell()
	var incoming: Control = host.home_page if screen == "home" else host.skills_content
	animate_panel(incoming, true)
	await host.get_tree().create_timer(OPEN_SECONDS).timeout
	page_transition = false

func sync_shell() -> void:
	if not enabled():
		return
	build_toolbar()
	var nav = host._navigation_shell()
	toolbar.visible = nav._intro_bottom_controls_unlocked() and intro_stage >= 1
	update_ribbon()
	apply_intro_ribbon()
	if is_instance_valid(skill_navigation): skill_navigation.update_view(0.0)
	if is_instance_valid(nav.nav_bar): nav.nav_bar.hide()
	if is_instance_valid(nav.module_utility_row): nav.module_utility_row.hide()
	var chat_strip = host._profile_chat_overlay_surface().chat_strip_control()
	if is_instance_valid(chat_strip): chat_strip.hide()
	for page in [host.skills_page, host.home_page]:
		if is_instance_valid(page):
			page.offset_top = TOP
			page.offset_left = hub_left_width() if host.current_screen == "hub" else 0.0
			page.offset_bottom = -RIBBON_HEIGHT
			page.offset_right = -(SOCIAL_WIDTH + GAP) if not social_tab.is_empty() else 0.0
	if is_instance_valid(social_panel):
		if social_dark_mode != host.dark_mode_enabled:
			social_dark_mode = host.dark_mode_enabled
			social_panel.get_node("PanelSurface").add_theme_stylebox_override("panel", panel_style(panel_fill(), true, 0))
			var tabs := social_panel.get_node("SocialTabs")
			for i in range(tabs.get_child_count()): style_button(tabs.get_child(i), social_tab == ["chat", "scores", ""][i])
			if social_tab == "chat":
				var chat = host._profile_chat_overlay_surface()
				chat._destroy_chat_overlay_shell()
				chat._ensure_chat_overlay_shell()
				chat._sync_chat_overlay_rows()
			else: refresh_scores()
		layout_social()

func remember_scrolls() -> void:
	if not columns.is_empty() and not rendering:
		remembered_focus = str(columns[clampi(focused_index, 0, columns.size() - 1)].skill_id)
		var detail = host._skill_detail_surface()
		detail_bookmarks = {"stat_key": detail.expanded_activity_stat_key, "stat_kind": detail.expanded_activity_stat_kind, "tier": detail.expanded_tier_banner_key}
	for column in all_columns:
		var scroll = column.context.get("detail_actions_scroll")
		if is_instance_valid(scroll): scroll_positions[column.skill_id] = scroll.scroll_vertical

func preserve_reflow_anchor() -> void:
	if intro_stage < 3 or columns.is_empty(): return
	var ids: Array = columns.map(func(column): return str(column.skill_id))
	var running := str(host.running_skill_id)
	reflow_anchor = running if running in ids else str(ids[clampi(focused_index, 0, ids.size() - 1)])
	var actual_index: int = ids.find(reflow_anchor)
	if page_count() < ids.size() and not preferred_column_indices.has(reflow_anchor):
		preferred_column_indices[reflow_anchor] = actual_index
	reflow_anchor_index = int(preferred_column_indices.get(reflow_anchor, actual_index))
	if page_count() == 3: preferred_column_indices.erase(reflow_anchor)

func before_clear() -> void:
	pending_column_refreshes.clear()
	cancel_carousel()
	if is_instance_valid(selector_root): selector_root.queue_free()
	selector_root = null
	selector_panel = null
	if is_instance_valid(hub_inspector): hub_inspector.queue_free()
	hub_inspector = null
	remember_scrolls()
	# Each virtual list owns an offscreen cache under main, outside the page tree.
	for column in all_columns:
		var cache = column.context.get("detail_lazy_cache_bin")
		if is_instance_valid(cache) and not cache.is_queued_for_deletion():
			host._app_lifecycle_runtime()._kill_transient_tweens_in_subtree(cache)
			cache.queue_free()
	if not columns.is_empty(): host._skill_detail_surface().detail_lazy_cache_bin = null
	columns.clear()
	all_columns.clear()
	carousel_frame = null

func render_skills() -> void:
	rendering = true
	sync_shell()
	var chosen: String = host.selected_skill_id
	var detail_state = host._skill_detail_surface()
	if not detail_bookmarks.is_empty():
		detail_state.expanded_activity_stat_key = detail_bookmarks.get("stat_key", "")
		detail_state.expanded_activity_stat_kind = detail_bookmarks.get("stat_kind", "")
		detail_state.expanded_tier_banner_key = detail_bookmarks.get("tier", "")
	if not reflow_anchor.is_empty():
		chosen = reflow_anchor
		var ids := skill_ids()
		rotate_slots(ids[posmod(ids.find(chosen) - mini(reflow_anchor_index, page_count() - 1), ids.size())])
		reflow_anchor = ""
	if host._onboarding_runtime().tutorial_active or intro_stage < 2:
		chosen = host.TUTORIAL_STARTER_SKILL_ID
		host.selected_skill_id = chosen
		rotate_slots(chosen)
		preferences_restored = false
	elif preferences_restored and not skill_slots.is_empty():
		chosen = skill_slots[focused_index]
		host.selected_skill_id = chosen
		preferences_restored = false
	if skill_slots.is_empty(): rotate_slots(chosen)
	elif chosen not in skill_slots.slice(0, page_count()): rotate_slots(chosen)
	else: rotate_slots(skill_slots[0])
	var count := page_count()
	column_width = fitted_column_width(count)
	if intro_stage < 2 and column_capacity(false) >= 3:
		column_width = fitted_column_width(3)
	carousel_left = (gameplay_width() - column_width * count - GAP * (count - 1)) * 0.5
	var swipe = host._skill_swipe_activity_surface()
	var adjacent = swipe._adjacent_pages()
	var clip := Control.new()
	clip.name = "DesktopCarouselClip"
	clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.skills_content.add_child(clip)
	carousel_frame = Control.new()
	carousel_frame.name = "DesktopSkillColumns"
	carousel_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	carousel_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(carousel_frame)
	add_atmosphere()
	swipe.skill_swipe_frame = carousel_frame
	var ids := skill_ids()
	for index in range(ids.size()):
		var id := ids[index]
		adjacent.apply_context(adjacent.blank_context())
		host.selected_skill_id = id
		await host._skill_detail_surface()._render_skill_detail(false, -1, false, index)
		var page: Control = swipe.skill_swipe_page
		page.name = "DesktopSkill_" + id
		page.clip_contents = true
		var title: Label = page.find_child("DesktopSkillTitle", true, false)
		all_columns.append({"skill_id": id, "context": adjacent.capture_context(), "page": page, "picker": title})
	position_carousel()
	apply_intro_activity_reveal()
	var focus := skill_slots.find(chosen)
	focus_column(clampi(focus, 0, columns.size() - 1), false)
	rendering = false
	call_deferred("settle_columns")

func position_carousel() -> void:
	var ids := skill_ids()
	var leading := ids.find(skill_slots[0])
	columns.clear()
	for i in range(page_count()): columns.append(all_columns[(leading + i) % ids.size()])
	for column in all_columns:
		var relative := posmod(ids.find(column.skill_id) - leading, ids.size())
		if relative == ids.size() - 1: relative = -1
		column.page.offset_left = carousel_left + relative * (column_width + GAP)
		column.page.offset_right = column.page.offset_left + column_width
	carousel_frame.position.x = 0
	_sync_carousel_page_visibility()
	update_atmosphere()

func _sync_carousel_page_visibility(moving := false) -> void:
	# Neighbor pages stay mounted for dragging, but must not peek into the
	# centered tutorial's margins or remain partially visible after settling.
	for column in all_columns:
		column.page.visible = moving or columns.has(column)

func settle_columns() -> void:
	if not enabled() or host.current_screen != "skill" or rendering: return
	var keep := focused_index
	var adjacent = host._skill_swipe_activity_surface()._adjacent_pages()
	# Warm all five real pages once; rotation reuses them without rebuilding nodes.
	for column in all_columns:
		host.selected_skill_id = column.skill_id
		adjacent.apply_context(column.context)
		var detail = host._skill_detail_surface()
		detail._sync_detail_actions_scroll_limit()
		var scroll = detail.detail_actions_scroll
		if is_instance_valid(scroll):
			style_scroll(scroll)
			var y := int(scroll_positions.get(column.skill_id, 0))
			scroll.scroll_vertical = y
			scroll.drag_scroll_position = y
			detail._sync_detail_lazy_visible_cards(true, 8)
		column.context = adjacent.capture_context()
	focus_column(keep, false)

func focus_column(index: int, save_current := true) -> void:
	if index < 0 or index >= columns.size(): return
	var adjacent = host._skill_swipe_activity_surface()._adjacent_pages()
	if save_current and focused_index < columns.size() and host.selected_skill_id == str(columns[focused_index].skill_id):
		columns[focused_index].context = adjacent.capture_context()
	focused_index = index
	host.selected_skill_id = columns[index].skill_id
	adjacent.apply_context(columns[index].context)

func cancel_carousel() -> void:
	carousel_tracking = false
	carousel_dragging = false
	carousel_settling = false
	if carousel_tween != null and carousel_tween.is_valid(): carousel_tween.kill()
	if is_instance_valid(carousel_frame): carousel_frame.position.x = 0
	_sync_carousel_page_visibility()
	for column in all_columns:
		var scroll = column.context.get("detail_actions_scroll")
		if is_instance_valid(scroll): scroll.child_click_suppressed = false

func settle_carousel(direction: int) -> void:
	carousel_tracking = false
	carousel_dragging = false
	carousel_settling = true
	_sync_carousel_page_visibility(true)
	var from := carousel_frame.position.x
	var target := -direction * (column_width + GAP)
	carousel_tween = carousel_frame.create_tween()
	carousel_tween.tween_method(func(progress: float):
		carousel_frame.position.x = lerpf(from, target, bezier_progress(progress, true))
	, 0.0, 1.0, OPEN_SECONDS)
	carousel_tween.tween_callback(func():
		remember_scrolls()
		if direction != 0:
			preferred_column_indices.clear()
			var ids := skill_ids()
			rotate_slots(ids[posmod(ids.find(skill_slots[0]) + direction, ids.size())])
		position_carousel()
		host._performance_runtime().request_ui_static_refresh()
		focus_column(clampi(focused_index, 0, columns.size() - 1), false)
		cancel_carousel()
	)

func navigate_carousel(direction: int) -> void:
	if not enabled() or host.current_screen != "skill" or not is_instance_valid(carousel_frame): return
	if rendering or page_transition or carousel_settling or carousel_dragging or intro_stage < 2 or intro_reveal_elapsed < INTRO_REVEAL_SECONDS: return
	if host._input_routing_shell()._any_modal_overlay_visible(): return
	host._clear_page_transient_input_state()
	settle_carousel(clampi(direction, -1, 1))

func queue_column_refresh(skill_id: String) -> void:
	if not skill_id.is_empty() and skill_id not in pending_column_refreshes:
		pending_column_refreshes.append(skill_id)

func refresh_next_column() -> void:
	if pending_column_refreshes.is_empty() or carousel_dragging or carousel_settling: return
	if host._activity_unlock_ceremony_surface().ceremony_count > 0: return
	var target: String = pending_column_refreshes.pop_front()
	var keep := focused_index
	var adjacent = host._skill_swipe_activity_surface()._adjacent_pages()
	# Retain the live cards, locks and animation clocks in every other column.
	for column in all_columns:
		if column.skill_id != target: continue
		if keep < columns.size(): columns[keep].context = adjacent.capture_context()
		host.selected_skill_id = target
		adjacent.apply_context(column.context)
		var detail = host._skill_detail_surface()
		var refreshed: bool = detail._try_refresh_detail_module_order_in_place()
		detail._sync_detail_actions_scroll_limit()
		column.context = adjacent.capture_context()
		focus_column(keep, false)
		if not refreshed: host._navigation_shell().call_deferred("_render_screen")
		return

func route_carousel(event: InputEvent) -> bool:
	if host.current_screen != "skill" or not is_instance_valid(carousel_frame): return false
	if carousel_settling:
		if event is InputEventMouse and event.position.y < host.size.y - RIBBON_HEIGHT and event.position.x < gameplay_width():
			host.get_viewport().set_input_as_handled()
			return true
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			var was_dragging := carousel_dragging
			carousel_tracking = false
			if was_dragging:
				var offset := carousel_frame.position.x
				if absf(offset) > (column_width + GAP) * 0.18: carousel_discovered = true
				settle_carousel(-int(signf(offset)) if absf(offset) > (column_width + GAP) * 0.18 else 0)
				host.get_viewport().set_input_as_handled()
			return was_dragging
		if host._onboarding_runtime().tutorial_active or intro_stage < 2 or intro_reveal_elapsed < INTRO_REVEAL_SECONDS or host._input_routing_shell()._any_modal_overlay_visible(): return false
		var hovered: Control = host.get_viewport().gui_get_hovered_control()
		if hovered is Range or hovered is LineEdit or hovered is TextEdit: return false
		carousel_tracking = Rect2(Vector2.ZERO, Vector2(gameplay_width(), host.size.y - RIBBON_HEIGHT)).has_point(event.position)
		carousel_start = event.position
	if event is InputEventMouseMotion and carousel_tracking:
		if host._input_routing_shell().activity_lock_input_active:
			carousel_tracking = false
			return false
		var distance: Vector2 = event.position - carousel_start
		if not carousel_dragging:
			if absf(distance.y) > 30 and absf(distance.y) > absf(distance.x) * 1.15:
				carousel_tracking = false
				return false
			if absf(distance.x) < 30 or absf(distance.x) < absf(distance.y) * 1.15: return false
			carousel_dragging = true
			_sync_carousel_page_visibility(true)
			host._clear_page_transient_input_state()
			for column in all_columns:
				var scroll = column.context.get("detail_actions_scroll")
				if is_instance_valid(scroll):
					scroll.drag_tracking = false
					scroll.drag_scrolling = false
					scroll.velocity = 0
					scroll._clear_pending_drag_motion()
					scroll.child_click_suppressed = true
		carousel_frame.position.x = clampf(distance.x, -column_width - GAP, column_width + GAP)
		host.get_viewport().set_input_as_handled()
		return true
	return false

func route_input(event: InputEvent) -> bool:
	if not enabled(): return false
	if is_instance_valid(selector_root):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: close_selector()
		return true
	if rendering or page_transition: return true
	# A page that has not appeared yet must not intercept clicks or hover focus.
	var reveal_pointer: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseMotion and event.button_mask == 0)
	if reveal_pointer and not host._input_routing_shell()._any_modal_overlay_visible():
		for cover in host.get_tree().get_nodes_in_group("activity_reveal_covers"):
			if cover.is_visible_in_tree() and cover.revealed < 0.95 and cover.get_global_rect().has_point(event.position):
				host.get_viewport().set_input_as_handled()
				return true
	# Let the shared navigator's GUI buttons receive input without starting an
	# activity or a new drag. A drag already in flight still owns its release.
	if not carousel_tracking and is_instance_valid(skill_navigation) and skill_navigation.route_event(event): return true
	if route_carousel(event): return true
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag:
		var position: Vector2 = event.position
		if position.y < TOP or position.y >= host._current_canvas_size().y - RIBBON_HEIGHT or (not social_tab.is_empty() and position.x >= gameplay_width()): return true
		# A release belongs to the column where the gesture began, including outside-window releases.
		var can_focus: bool = event is InputEventMouseButton and event.pressed
		can_focus = can_focus or (event is InputEventScreenTouch and event.pressed)
		can_focus = can_focus or (event is InputEventMouseMotion and event.button_mask == 0)
		if can_focus and host.current_screen == "skill":
			for i in range(columns.size()):
				if is_instance_valid(columns[i].page) and columns[i].page.get_global_rect().has_point(position):
					focus_column(i)
					break
	return false

func update(delta: float) -> void:
	if not ready or not available(): return
	host._achievement_toast_surface().sync_desktop_position()
	update_intro(delta)
	if is_instance_valid(skill_navigation): skill_navigation.update_view(delta)
	var size: Vector2 = host._current_canvas_size()
	if size.distance_to(last_layout_size) > 1.0 or last_window_size != host.get_window().size or last_page_count != page_count():
		resize_elapsed += delta
		if resize_elapsed > 0.25 and not rendering and not host._navigation_shell().screen_render_in_progress:
			resize_elapsed = 0
			last_layout_size = size
			last_window_size = host.get_window().size
			preserve_reflow_anchor()
			last_page_count = page_count()
			remember_scrolls()
			if column_capacity(false) < 3 and not social_tab.is_empty() and host.current_screen == "hub":
				host._hub_surface().hub_detail_open = false
			if enabled():
				sync_shell()
			else:
				if is_instance_valid(toolbar): toolbar.hide()
				set_social("")
				host.skills_page.offset_left = 0
				host.skills_page.offset_top = 0
				host.skills_page.offset_right = 0
				host.skills_page.offset_bottom = -host._navigation_shell().BOTTOM_NAV_HEIGHT
				host.home_page.offset_left = 0
				host.home_page.offset_top = 0
				host.home_page.offset_right = 0
				host.home_page.offset_bottom = -host._navigation_shell().BOTTOM_NAV_HEIGHT
			host._navigation_shell()._render_screen()
	# A chat or scores request that came while the pages were being built.
	if pending_social != null and not social_transition and not rendering and not host._navigation_shell().screen_render_in_progress:
		var requested: String = pending_social
		pending_social = null
		if enabled() and requested != social_tab: set_social(requested)
	if not enabled() or rendering or host._navigation_shell().screen_render_in_progress: return
	secondary_refresh_elapsed += delta
	var refresh_secondary := secondary_refresh_elapsed >= 0.5
	if refresh_secondary:
		secondary_refresh_elapsed = 0.0
		if social_tab == "scores" and host.leaderboard_presentation.displayed_local_score_key != host.leaderboard_presentation._local_score_key():
			refresh_scores()
	if host.current_screen != "skill": return
	var keep := focused_index
	for i in range(columns.size()):
		if i == keep: continue
		focus_column(i)
		var detail = host._skill_detail_surface()
		detail._process_detail_lazy_window(delta)
		detail._update_detail_header_gauges(refresh_secondary, true, true, delta, false)
		if refresh_secondary and detail._skill_detail_needs_action_list_refresh(): queue_column_refresh(str(columns[i].skill_id))
	focus_column(keep)
	refresh_next_column()

func set_social(tab: String) -> void:
	cancel_carousel()
	# There is no panel to open outside the wide layout. A request kept from
	# before the window was made narrow must not leave a tab set with no panel.
	if not tab.is_empty() and not enabled(): return
	if social_transition:
		pending_social = tab
		return
	if rendering or host._navigation_shell().screen_render_in_progress:
		# Kept until the pages are built, when update carries it out. It used to
		# be dropped, and a click on the icon then did nothing.
		pending_social = tab
		return
	# Open on this tab already: nothing to close and build again.
	if tab == social_tab and not tab.is_empty() and is_instance_valid(social_panel): return
	social_transition = true
	social_target = tab
	if is_instance_valid(social_panel):
		animate_panel(social_panel, false, Vector2(36, 0))
		var overlay = host._profile_chat_overlay_surface().chat_overlay
		if social_tab == "chat" and is_instance_valid(overlay): animate_panel(overlay, false, Vector2(36, 0))
		await host.get_tree().create_timer(CLOSE_SECONDS).timeout
	remember_scrolls()
	var chat = host._profile_chat_overlay_surface()
	chat._close_chat_overlay(false)
	# The docked chat is moved and faded by its own animation. Put away, it is
	# left still and opaque, so that it shows wherever it is opened next.
	var docked = chat.chat_overlay
	if is_instance_valid(docked):
		var motion = docked.get_meta("desktop_motion") if docked.has_meta("desktop_motion") else null
		if motion is Tween and motion.is_valid(): motion.kill()
		docked.modulate.a = 1.0
	social_tab = tab
	preserve_reflow_anchor()
	if not tab.is_empty() and column_capacity(false) < 3 and host.current_screen == "hub":
		host._hub_surface().hub_detail_open = false
	if is_instance_valid(social_panel):
		social_panel.queue_free()
	social_panel = null
	scores_content = null
	if not tab.is_empty() and enabled():
		social_panel = Control.new()
		social_panel.name = "DesktopSocialPanel"
		social_dark_mode = host.dark_mode_enabled
		host.add_child(social_panel)
		var tabs := HBoxContainer.new()
		tabs.name = "SocialTabs"
		tabs.position = Vector2(24, 24)
		tabs.add_theme_constant_override("separation", 8)
		social_panel.add_child(tabs)
		for entry in [["Chat", "chat"], ["High Scores", "scores"], ["Close", ""]]:
			var button := make_button(entry[0])
			style_button(button, tab == entry[1])
			button.pressed.connect(set_social.bind(entry[1]))
			tabs.add_child(button)
		add_panel_backdrop(social_panel)
		if tab == "chat":
			chat._ensure_chat_overlay()
			chat._destroy_chat_overlay_shell()
			chat._open_chat_overlay()
		else:
			scores_content = Control.new()
			scores_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			scores_content.offset_top = 132
			scores_content.offset_left = 32
			scores_content.offset_right = -32
			scores_content.offset_bottom = -32
			social_panel.add_child(scores_content)
			refresh_scores()
			host._online_runtime().fetch_leaderboard_category(host.leaderboard_state.category_id)
		layout_social()
		# Out of sight until it is animated in below. The pages are laid out again
		# first, and a panel shown meanwhile blinked when its animation then began
		# from nothing: it opened, went, and opened again.
		social_panel.modulate.a = 0.0
		if tab == "chat" and is_instance_valid(chat.chat_overlay): chat.chat_overlay.modulate.a = 0.0
	sync_shell()
	if not rendering: await host._navigation_shell()._render_screen()
	if is_instance_valid(social_panel):
		animate_panel(social_panel, true, Vector2(36, 0))
		if tab == "chat":
			var overlay = host._profile_chat_overlay_surface().chat_overlay
			overlay.remove_meta("desktop_motion_origin")
			animate_panel(overlay, true, Vector2(36, 0))
	await host.get_tree().create_timer(OPEN_SECONDS).timeout
	social_transition = false
	if pending_social != null:
		var next: String = pending_social
		pending_social = null
		if next != social_tab: call_deferred("set_social", next)

func layout_social() -> void:
	if not is_instance_valid(social_panel): return
	social_panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	social_panel.offset_left = -SOCIAL_WIDTH
	social_panel.offset_right = -EDGE
	social_panel.offset_top = TOP + 28
	social_panel.offset_bottom = -RIBBON_HEIGHT - 28
	var overlay = host._profile_chat_overlay_surface().chat_overlay
	if social_tab == "chat" and is_instance_valid(overlay):
		overlay.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		overlay.color = Color.TRANSPARENT
		overlay.offset_left = -SOCIAL_WIDTH + 24
		overlay.offset_right = -EDGE - 24
		overlay.offset_top = TOP + 148
		overlay.offset_bottom = -RIBBON_HEIGHT - 52

func refresh_scores() -> void:
	if social_tab != "scores" or not is_instance_valid(scores_content): return
	# The list is built again whenever the player's own number changes (every
	# completion while training) and when rows arrive, so it keeps its place
	# within a category instead of jumping back to the top.
	var category := str(host.leaderboard_state.category_id)
	var keep_scroll := 0
	if category == scores_scroll_category:
		for child in scores_content.get_children():
			if child is ScrollContainer and not child.is_queued_for_deletion(): keep_scroll = child.scroll_vertical
	scores_scroll_category = category
	host._clear(scores_content)
	var original = host.skills_content
	var scroll = host.content_scroll
	host.skills_content = scores_content
	host.leaderboard_presentation._render_leaderboard_page()
	host.skills_content = original
	host.content_scroll = scroll
	scores_content.offset_top = 132
	scores_content.offset_left = 32
	scores_content.offset_right = -32
	scores_content.offset_bottom = -32
	if keep_scroll > 0:
		for child in scores_content.get_children():
			if child is ScrollContainer and not child.is_queued_for_deletion(): _restore_scores_scroll.call_deferred(child, keep_scroll)

func _restore_scores_scroll(list: ScrollContainer, scroll_y: int) -> void:
	if not is_instance_valid(list): return
	list.scroll_vertical = scroll_y
	if "drag_scroll_position" in list: list.drag_scroll_position = float(list.scroll_vertical)

# An information button here is the phone's round "i", a little larger for a
# pointer. It used to be the letter alone, without its circle: players read a
# bare "i" beside a skill's name as a fault, and what could be clicked was the
# letter's own box, about 20 pixels on a laptop.
func style_info_button(button: Button) -> void:
	if not enabled(): return
	var growth := INFO_BUTTON_SIZE - button.custom_minimum_size
	button.custom_minimum_size = INFO_BUTTON_SIZE
	button.size = INFO_BUTTON_SIZE
	# One placed by hand keeps its centre; a container places the others.
	button.position -= growth * 0.5
	button.add_theme_font_size_override("font_size", 36)

