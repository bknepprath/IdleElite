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
var focused_index := 0
var column_width := 1014.0
var toolbar: PanelContainer
var ribbon_buttons := {}
var ribbon_state := ""
var atmosphere: ColorRect
var hub_inspector: Control
var social_panel: Control
var scores_content: Control
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
var pending_social: Variant = null
const OPEN_SECONDS := 0.26
const CLOSE_SECONDS := 0.18

const GAP := 36.0
const EDGE := 32.0
const TOP := 0.0
const RIBBON_HEIGHT := 166.0
const SOCIAL_WIDTH := 1030.0

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
		_finish_modal_hide(control)
	return true

func _finish_modal_hide(control: Control) -> void:
	await host.get_tree().create_timer(CLOSE_SECONDS).timeout
	if is_instance_valid(control) and bool(control.get_meta("desktop_closing", false)):
		control.hide()
		control.modulate.a = 1.0
		control.set_meta("desktop_closing", false)

func saved_preferences() -> Dictionary:
	remember_scrolls()
	return {"skills": skill_slots.duplicate(), "scroll": scroll_positions.duplicate(), "focused": focused_index}

func restore_preferences(value: Variant) -> void:
	skill_slots.clear()
	scroll_positions.clear()
	focused_index = 0
	preferences_restored = false
	if not value is Dictionary: return
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
	if OS.has_feature("desktop_layout") and not OS.has_feature("web"):
		window.size = Vector2i(1600, 900)
	window.min_size = Vector2i(800, 600)

func start() -> void:
	ready = true
	if not enabled():
		return
	if not skill_slots.is_empty(): host.selected_skill_id = skill_slots[mini(focused_index, skill_slots.size() - 1)]
	build_toolbar()
	last_layout_size = host._current_canvas_size()
	last_window_size = host.get_window().size
	last_page_count = page_count()
	host._navigation_shell()._render_screen()

func page_count() -> int:
	if host._onboarding_runtime().tutorial_active: return 1
	var physical_width: int = host.get_window().size.x
	var total := 3 if physical_width >= 1200 else 2
	if not social_tab.is_empty():
		total -= 1
	return maxi(1, total)

func gameplay_width() -> float:
	return host._current_canvas_size().x - (SOCIAL_WIDTH + GAP if not social_tab.is_empty() else 0.0)

func build_toolbar() -> void:
	if is_instance_valid(toolbar): return
	var nav = host._navigation_shell()
	toolbar = PanelContainer.new()
	toolbar.name = "DesktopRibbon"
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

func add_ribbon_button(row: HBoxContainer, key: String, label: String, path: String, width: float) -> void:
	var button: Button = host._navigation_shell()._nav_button(path)
	button.name = key.capitalize()
	button.tooltip_text = label
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(width, 134)
	button.add_theme_constant_override("icon_max_width", int(width * 0.76))
	button.set_meta("nav_open_icon_disabled", true)
	host._navigation_shell()._ensure_nav_icon_stroke(button)
	if key in ["chat", "scores"]:
		button.pressed.connect(func(): set_social("" if social_tab == key else key))
	else:
		button.pressed.connect(navigate.bind(key))
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
uniform float first_center;
uniform float spacing;
void fragment() {
 vec4 tint = colors[0];
 for (int i = 1; i < 5; i++) {
  tint = mix(tint, colors[i], smoothstep(first_center + float(i - 1) * spacing, first_center + float(i) * spacing, UV.x));
 }
 float strength = (0.12 + 0.20 * smoothstep(0.0, 0.5, UV.y)) * (1.0 - smoothstep(0.52, 1.0, UV.y));
 COLOR = mix(paper, tint, strength);
} """
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("paper", host._theme_paper_color())
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
	toolbar.visible = nav._intro_bottom_controls_unlocked()
	update_ribbon()
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
	for column in all_columns:
		var scroll = column.context.get("detail_actions_scroll")
		if is_instance_valid(scroll): scroll_positions[column.skill_id] = scroll.scroll_vertical

func before_clear() -> void:
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
	if preferences_restored and not skill_slots.is_empty():
		chosen = skill_slots[focused_index]
		host.selected_skill_id = chosen
		preferences_restored = false
	if skill_slots.is_empty(): rotate_slots(chosen)
	else: rotate_slots(skill_slots[0])
	var count := page_count()
	column_width = minf(1150.0, (gameplay_width() - EDGE * 2 - GAP * (count - 1)) / count)
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
		page.clip_contents = false
		var title: Label = page.find_child("DesktopSkillTitle", true, false)
		all_columns.append({"skill_id": id, "context": adjacent.capture_context(), "page": page, "picker": title})
	position_carousel()
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
	update_atmosphere()

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
	for column in all_columns:
		var scroll = column.context.get("detail_actions_scroll")
		if is_instance_valid(scroll): scroll.child_click_suppressed = false

func settle_carousel(direction: int) -> void:
	carousel_tracking = false
	carousel_dragging = false
	carousel_settling = true
	var from := carousel_frame.position.x
	var target := -direction * (column_width + GAP)
	carousel_tween = carousel_frame.create_tween()
	carousel_tween.tween_method(func(progress: float):
		carousel_frame.position.x = lerpf(from, target, bezier_progress(progress, true))
	, 0.0, 1.0, OPEN_SECONDS)
	carousel_tween.tween_callback(func():
		remember_scrolls()
		if direction != 0:
			var ids := skill_ids()
			rotate_slots(ids[posmod(ids.find(skill_slots[0]) + direction, ids.size())])
		position_carousel()
		focus_column(clampi(focused_index, 0, columns.size() - 1), false)
		cancel_carousel()
	)

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
				settle_carousel(-int(signf(offset)) if absf(offset) > (column_width + GAP) * 0.18 else 0)
				host.get_viewport().set_input_as_handled()
			return was_dragging
		if host._onboarding_runtime().tutorial_active or host._input_routing_shell()._any_modal_overlay_visible(): return false
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
	var size: Vector2 = host._current_canvas_size()
	if size.distance_to(last_layout_size) > 1.0 or last_window_size != host.get_window().size or last_page_count != page_count():
		resize_elapsed += delta
		if resize_elapsed > 0.25 and not rendering and not host._navigation_shell().screen_render_in_progress:
			resize_elapsed = 0
			last_layout_size = size
			last_window_size = host.get_window().size
			last_page_count = page_count()
			remember_scrolls()
			if host.get_window().size.x < 1200 and not social_tab.is_empty() and host.current_screen == "hub":
				host._hub_surface().hub_detail_open = false
			if enabled():
				sync_shell()
			else:
				if is_instance_valid(toolbar): toolbar.hide()
				set_social("")
				host.skills_page.offset_left = 0
				host.skills_page.offset_top = 0
				host.skills_page.offset_right = 0
				host.skills_page.offset_bottom = -host.BOTTOM_NAV_HEIGHT
				host.home_page.offset_left = 0
				host.home_page.offset_top = 0
				host.home_page.offset_right = 0
				host.home_page.offset_bottom = -host.BOTTOM_NAV_HEIGHT
			host._navigation_shell()._render_screen()
	if not enabled() or rendering or host._navigation_shell().screen_render_in_progress: return
	secondary_refresh_elapsed += delta
	var refresh_secondary := secondary_refresh_elapsed >= 0.5
	if refresh_secondary:
		secondary_refresh_elapsed = 0.0
		if social_tab == "scores" and host.leaderboard_presentation.displayed_local_score_key != host.leaderboard_presentation._local_score_key():
			refresh_scores()
	if host.current_screen != "skill": return
	var keep := focused_index
	var refresh_pages := false
	for i in range(columns.size()):
		if i == keep: continue
		focus_column(i)
		var detail = host._skill_detail_surface()
		detail._process_detail_lazy_window(delta)
		detail._update_detail_header_gauges(refresh_secondary, true, true, delta, false)
		if refresh_secondary and detail._skill_detail_needs_action_list_refresh(): refresh_pages = true
	focus_column(keep)
	if refresh_pages: host._navigation_shell().call_deferred("_render_screen")

func set_social(tab: String) -> void:
	cancel_carousel()
	if social_transition:
		pending_social = tab
		return
	if rendering or host._navigation_shell().screen_render_in_progress: return
	social_transition = true
	if is_instance_valid(social_panel):
		animate_panel(social_panel, false, Vector2(36, 0))
		var overlay = host._profile_chat_overlay_surface().chat_overlay
		if social_tab == "chat" and is_instance_valid(overlay): animate_panel(overlay, false, Vector2(36, 0))
		await host.get_tree().create_timer(CLOSE_SECONDS).timeout
	remember_scrolls()
	var chat = host._profile_chat_overlay_surface()
	chat._close_chat_overlay(false)
	social_tab = tab
	if not tab.is_empty() and host.get_window().size.x < 1200 and host.current_screen == "hub":
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

func style_info_button(button: Button) -> void:
	if not enabled(): return
	button.text = "i"
	button.add_theme_color_override("font_outline_color", Color.WHITE)
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_font_size_override("font_size", 42)
	for state in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())

