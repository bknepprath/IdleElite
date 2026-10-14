extends Button

# Canonical atlas regions share a canvas and anchor, never alpha-bound scaling.
const SHEET := "res://assets/content/ui/project-timber-states.png"
var face: TextureRect
var incoming: TextureRect
var title_label: Label
var source_label: Label
var count_label: Label
var source_icon: TextureRect
var bar: ProgressBar
var state := -1
var last_fraction := -1.0
var motion: Tween
var damage_motion: Tween

func setup(host, title: String, source: String, texture: Texture2D, color: Color) -> void:
	custom_minimum_size.y = 300
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for key in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(key, StyleBoxEmpty.new())
	for index in range(2):
		var layer := TextureRect.new()
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(layer)
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if index == 0: face = layer
		else: incoming = layer; incoming.modulate.a = 0.0
	source_icon = TextureRect.new()
	source_icon.texture = texture
	source_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	source_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	source_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(source_icon)
	title_label = host._label(title, 52, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	source_label = host._label(source, 52, Color("#fff1d7"), HORIZONTAL_ALIGNMENT_LEFT)
	count_label = host._label("", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	for label in [title_label, source_label, count_label]:
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.add_theme_constant_override("outline_size", 12)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(label)
	bar = ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for key in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#35271f") if key == "background" else color
		style.border_color = Color("#171615")
		style.set_border_width_all(6)
		style.set_corner_radius_all(20)
		bar.add_theme_stylebox_override(key, style)
	add_child(bar)
	resized.connect(_layout)
	mouse_entered.connect(func(): modulate = Color(1.06, 1.06, 1.06))
	mouse_exited.connect(func(): modulate = Color.WHITE)
	_layout()

func _layout() -> void:
	if not is_instance_valid(bar): return
	source_icon.position = Vector2(38, 38)
	source_icon.size = Vector2(155, 155)
	title_label.position = Vector2(210, 30)
	title_label.size = Vector2(maxf(100, size.x - 470), 76)
	source_label.position = Vector2(210, 103)
	source_label.size = Vector2(maxf(100, size.x - 310), 125)
	count_label.position = Vector2(size.x - 280, 35)
	count_label.size = Vector2(200, 76)
	bar.position = Vector2(210, 240)
	bar.size = Vector2(maxf(100, size.x - 305), 34)

func update_progress(value: float, count: String) -> void:
	count_label.text = count
	value = clampf(value, 0.0, 1.0)
	if is_equal_approx(last_fraction, value): return
	var first := last_fraction < 0.0
	last_fraction = value
	if is_instance_valid(motion): motion.kill()
	if first: bar.value = value * 100.0
	else:
		motion = create_tween()
		motion.tween_property(bar, "value", value * 100.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var next_state := 2 if value >= 0.66 else (1 if value > 0.0 else 0)
	if next_state == state: return
	var texture := AtlasTexture.new()
	texture.atlas = load(SHEET)
	texture.region = Rect2(0, next_state * 230, 768, 230)
	if is_instance_valid(damage_motion): damage_motion.kill()
	if state < 0:
		face.texture = texture
	else:
		incoming.texture = texture
		incoming.modulate.a = 0.0
		damage_motion = create_tween()
		damage_motion.tween_property(incoming, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		damage_motion.tween_callback(func(): face.texture = texture; incoming.modulate.a = 0.0)
	state = next_state

func _exit_tree() -> void:
	if is_instance_valid(motion): motion.kill()
	if is_instance_valid(damage_motion): damage_motion.kill()
