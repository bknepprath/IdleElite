extends Control

const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const HEIGHT := 170.0
const BUTTON_SIZE := Vector2(480, 142)
const CORNER_WIDTH := 128.0
const REVEAL_SECONDS := 0.24
const HIDE_DELAY := 0.65
var desktop
var previous: Button
var next: Button
var hint: Label
var hint_visibility := 1.0
var cues: Array[Control] = []
var progress := [0.0, 0.0]
var linger := [0.0, 0.0]
var hover_time := [0.0, 0.0]
var pointer := Vector2(-1000, -1000)
var swallowed_touch := -1
var state_key := ""

func setup(owner) -> void:
	desktop = owner
	name = "DesktopSkillNavigation"
	z_index = 1801
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_window().mouse_exited.connect(func(): pointer = Vector2(-1000, -1000))
	previous = add_arrow(-1, "woodcutting")
	next = add_arrow(1, "build")
	for direction in [-1, 1]:
		var cue = NavigationShell.PageSwitchChevronIcon.new()
		cue.set_direction(direction)
		cue.size = Vector2(77, 110)
		cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cue)
		cues.append(cue)
	hint = Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_font_override("font", desktop.host.app_bold_font)
	hint.add_theme_font_size_override("font_size", 34)
	add_child(hint)
	hide()

func add_arrow(direction: int, skill_id: String) -> Button:
	var button: Button = desktop.host._navigation_shell()._page_switch_button(skill_id, "right" if direction < 0 else "left", desktop.navigate_carousel.bind(direction))
	button.size = BUTTON_SIZE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and not event.pressed:
			button.call_deferred("release_focus")
	)
	add_child(button)
	return button

func corner_rect(index: int) -> Rect2:
	return Rect2(global_position + Vector2(desktop.EDGE if index == 0 else size.x - desktop.EDGE - CORNER_WIDTH, 0), Vector2(CORNER_WIDTH, HEIGHT))

func route_event(event: InputEvent) -> bool:
	if not is_visible_in_tree(): return false
	if event is InputEventMouse:
		pointer = event.position
	if event is InputEventScreenTouch and event.index == swallowed_touch:
		if not event.pressed: swallowed_touch = -1
		get_viewport().set_input_as_handled()
		return true
	if not (event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag): return false
	var buttons := [previous, next]
	for index in range(2):
		var in_corner := corner_rect(index).has_point(event.position)
		var in_button: bool = float(progress[index]) > 0.05 and buttons[index].get_global_rect().has_point(event.position)
		if not in_corner and not in_button: continue
		if event is InputEventScreenTouch and event.pressed and float(progress[index]) < 0.9:
			linger[index] = 2.5
			swallowed_touch = event.index
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and float(progress[index]) < 0.9:
			linger[index] = HIDE_DELAY
			get_viewport().set_input_as_handled()
		return true
	return false

func update_view(delta: float) -> void:
	visible = desktop.enabled() and desktop.host.current_screen == "skill" and desktop.intro_stage >= 2 and desktop.intro_reveal_elapsed >= desktop.INTRO_REVEAL_SECONDS and not desktop.host._onboarding_runtime().tutorial_active
	if not visible:
		progress = [0.0, 0.0]
		linger = [0.0, 0.0]
		hover_time = [0.0, 0.0]
		return
	size = Vector2(desktop.gameplay_width(), HEIGHT)
	position = Vector2(0, desktop.host._current_canvas_size().y - desktop.RIBBON_HEIGHT - HEIGHT - 12)
	var modal: bool = desktop.host._input_routing_shell()._any_modal_overlay_visible()
	var blocked: bool = desktop.rendering or desktop.page_transition or desktop.carousel_settling or desktop.carousel_dragging or modal
	var key := str(desktop.skill_slots) + str(desktop.page_count()) + str(desktop.host.dark_mode_enabled)
	if key != state_key:
		state_key = key
		var ids: Array = desktop.skill_ids()
		if not desktop.skill_slots.is_empty():
			var leading: int = ids.find(desktop.skill_slots[0])
			var focused := 0 if previous.has_focus() else (1 if next.has_focus() else -1)
			remove_child(previous)
			remove_child(next)
			previous.queue_free()
			next.queue_free()
			previous = add_arrow(-1, ids[posmod(leading - 1, ids.size())])
			next = add_arrow(1, ids[posmod(leading + desktop.page_count(), ids.size())])
			if focused >= 0: [previous, next][focused].grab_focus()
	var buttons := [previous, next]
	for index in range(2):
		var button: Button = buttons[index]
		var hovered := corner_rect(index).has_point(pointer) or (float(progress[index]) > 0.05 and button.get_global_rect().grow(16).has_point(pointer))
		hover_time[index] = float(hover_time[index]) + delta if hovered and not blocked else 0.0
		if float(hover_time[index]) >= 0.10 or button.has_focus():
			linger[index] = HIDE_DELAY
		else:
			linger[index] = maxf(0, float(linger[index]) - delta)
		var target := 1.0 if float(linger[index]) > 0 and not modal else 0.0
		progress[index] = move_toward(float(progress[index]), target, delta / REVEAL_SECONDS)
		var eased: float = desktop.bezier_progress(float(progress[index]), true) if float(progress[index]) > 0.0 and float(progress[index]) < 1.0 else float(progress[index])
		button.position = Vector2(desktop.EDGE if index == 0 else size.x - desktop.EDGE - BUTTON_SIZE.x, 16 + (1.0 - eased) * 12)
		button.modulate.a = eased
		button.disabled = blocked or float(progress[index]) < 0.9
		button.mouse_filter = Control.MOUSE_FILTER_STOP if float(progress[index]) >= 0.9 else Control.MOUSE_FILTER_IGNORE
		cues[index].position = Vector2(desktop.EDGE + 26 if index == 0 else size.x - desktop.EDGE - 103, 25)
		cues[index].modulate.a = 0.35 * (1.0 - eased) if not blocked else 0.0
	var text_width: float = desktop.host.app_bold_font.get_string_size("Drag left or right to see all 5 skills", HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
	var hint_width := minf(size.x - desktop.EDGE * 2, text_width + 32)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size = Vector2(hint_width, 104 if hint_width < text_width + 32 else 58)
	hint.position = Vector2((size.x - hint.size.x) * 0.5, HEIGHT - hint.size.y)
	if key != str(hint.get_meta("surface_key", "")):
		hint.set_meta("surface_key", key)
		hint.add_theme_stylebox_override("normal", desktop.panel_style(desktop.panel_fill(), false, 12))
	hint.text = "Drag left or right to see all 5 skills"
	hint_visibility = move_toward(hint_visibility, 0.0 if desktop.carousel_discovered else 1.0, delta / 0.4)
	hint.modulate.a = desktop.intro_fade(hint_visibility)
	hint.visible = hint_visibility > 0.0
	hint.add_theme_color_override("font_color", desktop.panel_ink())
