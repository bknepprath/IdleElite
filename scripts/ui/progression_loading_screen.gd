extends Control

const BOOT_ART := preload("res://assets/content/ui/boot/progression-070.png")
var illustration: TextureRect
var stack: VBoxContainer
var progress: Control
var target_progress := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 24)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stack)
	# The version as the build has it, with the code of a build for itch.io (0.7.1i).
	var version_text := str(ProjectSettings.get_setting("application/config/version", "")) + str(ProjectSettings.get_setting("application/config/version_suffix", ""))
	for text in ["Idle Elite", version_text]:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", ThemeStyles.load_app_fonts().bold_font)
		label.add_theme_font_size_override("font_size", 104 if text == "Idle Elite" else 52)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color("#171615"))
		label.add_theme_constant_override("outline_size", 18 if text == "Idle Elite" else 10)
		stack.add_child(label)
	illustration = TextureRect.new()
	illustration.texture = BOOT_ART
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(illustration)
	progress = preload("res://scripts/ui/clean_progress_bar.gd").new()
	progress.custom_minimum_size.y = 38
	progress.fill_color = Color("#6ea937")
	progress.track_color = Color("#31442a")
	progress.border_color = Color("#171615")
	progress.border_width = 7
	stack.add_child(progress)
	resized.connect(_layout)
	_layout()
	set_progress(target_progress)

func _layout() -> void:
	if not is_instance_valid(stack): return
	var width := minf(1350.0, minf(size.x - 120.0, (size.y - 380.0) * 1.5))
	var height := width * 2.0 / 3.0 + 300.0
	illustration.custom_minimum_size.y = width * 2.0 / 3.0
	stack.position = Vector2((size.x - width) * 0.5, maxf(40.0, (size.y - height) * 0.45))
	stack.size = Vector2(width, height)

func set_progress(value: float) -> void:
	target_progress = maxf(target_progress, clampf(value, 0.0, 1.0))
	if is_instance_valid(progress): progress.set_value(target_progress * 100.0)
