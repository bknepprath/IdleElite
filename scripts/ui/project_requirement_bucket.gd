extends Button

var source_label: Label
var count_label: Label
var source_icon: TextureRect
var bar: ProgressBar
var fill_motion: Tween
var displayed_fraction := -1.0

func setup(host, stone: bool, color: Color) -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#8e9ca5") if stone else Color("#cba77a")
	style.border_color = Color("#131313")
	style.set_border_width_all(10)
	style.set_corner_radius_all(28)
	style.shadow_color = Color("#131313")
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 10)
	for key in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(key, style)
	var icon_frame := Panel.new()
	icon_frame.name = "SourceFrame"
	icon_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color("#f6ecdc")
	icon_style.border_color = Color("#131313")
	icon_style.set_border_width_all(8)
	icon_style.set_corner_radius_all(22)
	icon_frame.add_theme_stylebox_override("panel", icon_style)
	add_child(icon_frame)
	source_icon = TextureRect.new()
	source_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	source_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	source_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_frame.add_child(source_icon)
	source_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	source_icon.offset_left = 10
	source_icon.offset_top = 10
	source_icon.offset_right = -10
	source_icon.offset_bottom = -10
	source_label = host._label("", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	count_label = host._label("", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	for label in [source_label, count_label]:
		label.add_theme_font_override("font", host.app_bold_font)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 16)
		label.add_theme_constant_override("line_spacing", -12)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(source_label)
	bar = ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in ["background", "fill"]:
		var rail := StyleBoxFlat.new()
		rail.bg_color = Color("#35302b") if key == "background" else color
		rail.border_color = Color.BLACK
		rail.set_border_width_all(6)
		rail.set_corner_radius_all(26)
		bar.add_theme_stylebox_override(key, rail)
	add_child(bar)
	add_child(count_label)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_instance_valid(bar): return
	var frame: Control = get_node("SourceFrame")
	frame.position = Vector2(20, 28)
	frame.size = Vector2(146, 146)
	for control in [source_label, bar, count_label]:
		control.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		control.offset_left = 190
		control.offset_right = -32
	source_label.offset_top = 12
	source_label.offset_bottom = 124
	bar.offset_top = 133
	bar.offset_bottom = 191
	count_label.offset_top = 125
	count_label.offset_bottom = 199

func update_requirement(row: Dictionary, texture: Texture2D) -> void:
	source_label.text = str(row.label)
	count_label.text = str(row.count)
	source_icon.texture = texture
	var fraction := clampf(float(row.fraction), 0, 1)
	if is_equal_approx(displayed_fraction, fraction): return
	if is_instance_valid(fill_motion): fill_motion.kill()
	if displayed_fraction < 0: bar.value = fraction * 100
	else:
		fill_motion = create_tween()
		fill_motion.tween_property(bar, "value", fraction * 100, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	displayed_fraction = fraction

func reset_requirement() -> void:
	displayed_fraction = -1

func _exit_tree() -> void:
	if is_instance_valid(fill_motion): fill_motion.kill()
