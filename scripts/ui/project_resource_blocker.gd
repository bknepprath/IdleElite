extends Button

const Arc := preload("res://scripts/ui/lock_progress_bar.gd")
var resource := ""
var progress: Control
var resource_icon: TextureRect

func setup(host, row: Dictionary, material_id := "stone") -> void:
	resource = str(row.id)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for key in ["normal", "hover", "pressed", "focus", "disabled"]: add_theme_stylebox_override(key, StyleBoxEmpty.new())
	var body := TextureRect.new()
	body.texture = load("res://assets/content/ui/unlock-holder-%s.png" % material_id)
	body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The timber opening is authored 14px right of center on its 256px canvas.
	# Translate the frame, preserving its size and the shared icon/bar center.
	if material_id == "timber":
		body.offset_left = -12.0
		body.offset_right = -12.0
	resource_icon = TextureRect.new()
	resource_icon.texture = host.visual_texture_cache._texture_or_visual_fallback(str(row.icon))
	resource_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	resource_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resource_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resource_icon.position = Vector2(55, 48)
	resource_icon.size = Vector2(110, 110)
	add_child(resource_icon)
	progress = Arc.new()
	progress.setup(host.app_bold_font)
	progress.fill_color = Color("#ffd84a")
	progress.position = Vector2(60, 150)
	progress.size = Vector2(100, 28)
	add_child(progress)
	update_requirement(row)

func update_requirement(row: Dictionary) -> void:
	progress.set_progress(float(row.amount) / maxi(1, int(row.target)))
	tooltip_text = str(row.tooltip)
