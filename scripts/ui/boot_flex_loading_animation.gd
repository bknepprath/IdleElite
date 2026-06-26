class_name BootFlexLoadingAnimation
extends Control


const SHEET_PATH := "res://assets/loading/blue-guy-flex-loading-spritesheet.png"
const BUBBLE_PATH := "res://assets/loading/blue-guy-flex-speech-bubble-blank.png"
const FONT_PATH := "res://assets/fonts/Fredoka.ttf"
const FRAME_SIZE := Vector2(512, 512)
const LOOP_SECONDS := 2.15
const SHAKE_START := 0.22
const COLOR_INK := Color("#171615")
const SKILL_THEME_COLORS := [
	Color("#e84d4d"),
	Color("#8956bc"),
	Color("#237cd5"),
	Color("#6ea937"),
	Color("#2dc0b9")
]


var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var previous_loop_pos := 0.0
var sheet_texture: Texture2D
var bubble_texture: Texture2D
var bubble_font: Font
var atlas_texture: AtlasTexture
var sprite_holder: Control
var sprite: TextureRect
var bubble: TextureRect
var bubble_text: Control
var bubble_line_top: Label
var bubble_line_big: Label
var xp_layer: Control
var sprite_base_position := Vector2.ZERO
var current_frame := -1
var transparent_texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	sheet_texture = _load_texture_or_fallback(SHEET_PATH, Vector2i(int(FRAME_SIZE.x * 4.0), int(FRAME_SIZE.y)))
	bubble_texture = _load_texture_or_fallback(BUBBLE_PATH, Vector2i(8, 8))
	_load_bubble_font()
	_build_nodes()
	_sync_layout()
	set_process(not _headless_mode())


func restart() -> void:
	elapsed = 0.0
	previous_loop_pos = 0.0
	current_frame = -1
	_set_frame(0)
	if sprite_holder != null:
		sprite_holder.position = sprite_base_position
	if xp_layer != null:
		for child in xp_layer.get_children():
			child.queue_free()
	set_process(not _headless_mode())


func stop() -> void:
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_layout()


func _process(delta: float) -> void:
	if _headless_mode():
		return
	var next_elapsed := elapsed + delta
	var loop_pos := fmod(next_elapsed, LOOP_SECONDS)
	var wrapped := loop_pos < previous_loop_pos
	if wrapped or (previous_loop_pos < LOOP_SECONDS * SHAKE_START and loop_pos >= LOOP_SECONDS * SHAKE_START):
		_spawn_xp_drop()
	elapsed = next_elapsed
	previous_loop_pos = loop_pos
	var phase := loop_pos / LOOP_SECONDS
	_set_frame(_frame_for_phase(phase))
	if sprite_holder != null:
		sprite_holder.position = sprite_base_position + Vector2(_shake_x_for_phase(phase), 0.0)


func _build_nodes() -> void:
	sprite_holder = Control.new()
	sprite_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_holder.z_index = 10
	add_child(sprite_holder)

	atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = null if _headless_mode() else sheet_texture
	atlas_texture.region = Rect2(Vector2.ZERO, FRAME_SIZE)

	sprite = TextureRect.new()
	sprite.texture = _transparent_fallback_texture(Vector2i(int(FRAME_SIZE.x), int(FRAME_SIZE.y))) if _headless_mode() else atlas_texture
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_holder.add_child(sprite)

	bubble = TextureRect.new()
	bubble.texture = bubble_texture
	bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)

	bubble_text = Control.new()
	bubble_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble_text)

	bubble_line_top = _make_bubble_label("I must become an")
	bubble_text.add_child(bubble_line_top)

	bubble_line_big = _make_bubble_label("IDLE ELITIST!")
	bubble_text.add_child(bubble_line_big)

	xp_layer = Control.new()
	xp_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	xp_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_layer.z_index = 30
	add_child(xp_layer)


func _make_bubble_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", COLOR_INK)
	label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.64))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.10))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	if bubble_font != null:
		label.add_theme_font_override("font", bubble_font)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _load_bubble_font() -> void:
	if ResourceLoader.exists(FONT_PATH):
		var loaded := load(FONT_PATH)
		if loaded is Font:
			var bold := FontVariation.new()
			bold.base_font = loaded
			bold.variation_embolden = 1.45
			bubble_font = bold
	if bubble_font == null:
		bubble_font = ThemeDB.fallback_font


func _sync_layout() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var sprite_size := clampf(minf(size.x, size.y) * 2.05, 1000.0, 1500.0)
	var center := size * 0.5 + Vector2(0.0, 720.0)
	sprite_base_position = center - Vector2(sprite_size, sprite_size) * 0.5
	sprite_base_position.y -= sprite_size * 0.22
	if sprite_holder != null:
		sprite_holder.size = Vector2(sprite_size, sprite_size)
		sprite_holder.position = sprite_base_position

	var bubble_width := clampf(size.x * 0.78, 1240.0, 1760.0)
	var bubble_height := bubble_width * 0.43
	var bubble_y := maxf(56.0, sprite_base_position.y - bubble_height + 166.0)
	if bubble != null:
		bubble.size = Vector2(bubble_width, bubble_height)
		bubble.position = Vector2((size.x - bubble_width) * 0.5, bubble_y)
	if bubble_text != null:
		bubble_text.size = Vector2(bubble_width * 0.92, bubble_height * 0.78)
		bubble_text.position = Vector2((size.x - bubble_text.size.x) * 0.5, bubble_y + bubble_height * 0.135)
		_layout_bubble_text()


func _layout_bubble_text() -> void:
	if bubble_text == null:
		return
	var top_height := bubble_text.size.y * 0.30
	var big_height := bubble_text.size.y * 0.70
	var small_font := int(clampf(bubble_text.size.x * 0.064, 48.0, 94.0))
	var big_font := int(clampf(bubble_text.size.x * 0.136, 122.0, 210.0))
	if bubble_line_top != null:
		bubble_line_top.size = Vector2(bubble_text.size.x, top_height)
		bubble_line_top.position = Vector2.ZERO
		bubble_line_top.add_theme_font_size_override("font_size", small_font)
	if bubble_line_big != null:
		bubble_line_big.size = Vector2(bubble_text.size.x, big_height)
		bubble_line_big.position = Vector2(0.0, top_height - bubble_text.size.y * 0.20)
		bubble_line_big.add_theme_font_size_override("font_size", big_font)


func _frame_for_phase(phase: float) -> int:
	if phase < 0.08:
		return 0
	if phase < 0.15:
		return 1
	if phase < 0.22:
		return 2
	if phase < 0.92:
		return 3
	return 0


func _set_frame(frame: int) -> void:
	if _headless_mode() or frame == current_frame or atlas_texture == null:
		return
	current_frame = frame
	atlas_texture.region = Rect2(Vector2(FRAME_SIZE.x * frame, 0.0), FRAME_SIZE)


func _shake_x_for_phase(phase: float) -> float:
	if phase < 0.22 or phase >= 0.31:
		return 0.0
	if phase < 0.232:
		return -12.0
	if phase < 0.244:
		return 12.0
	if phase < 0.256:
		return -12.0
	if phase < 0.268:
		return 12.0
	if phase < 0.280:
		return -7.0
	if phase < 0.292:
		return 7.0
	if phase < 0.302:
		return -3.0
	return 3.0


func _spawn_xp_drop() -> void:
	if xp_layer == null or sprite_holder == null:
		return
	var amount := rng.randi_range(1, 3)
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var sprite_size := sprite_holder.size.x
	var start := sprite_base_position + Vector2(
		sprite_size * 0.5 + side * rng.randf_range(sprite_size * 0.18, sprite_size * 0.30),
		rng.randf_range(sprite_size * 0.18, sprite_size * 0.25)
	)
	var color: Color = SKILL_THEME_COLORS[rng.randi_range(0, SKILL_THEME_COLORS.size() - 1)]
	_float_reward("+%s XP" % amount, color, start)


func _float_reward(text: String, color: Color, center: Vector2) -> void:
	var reward_size := Vector2(480, 128)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	holder.position = center - reward_size * 0.5
	holder.modulate.a = 0.0
	holder.scale = Vector2(0.82, 0.82)
	xp_layer.add_child(holder)

	var shadow := Label.new()
	shadow.text = text
	shadow.size = reward_size
	shadow.position = Vector2(3, 4)
	shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shadow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shadow.add_theme_font_size_override("font_size", 92)
	shadow.add_theme_color_override("font_color", COLOR_INK)
	shadow.modulate = Color(1, 1, 1, 0.34)
	holder.add_child(shadow)

	var label := Label.new()
	label.text = text
	label.size = reward_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 92)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", COLOR_INK)
	label.add_theme_constant_override("outline_size", 14)
	holder.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + Vector2(0, -132), 1.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.08)
	tween.tween_property(holder, "modulate:a", 0.0, 0.85).set_delay(0.55)
	tween.chain().tween_callback(_queue_free_instance_id.bind(holder.get_instance_id()))


func _load_texture_or_fallback(path: String, fallback_size: Vector2i) -> Texture2D:
	if _headless_mode():
		return _transparent_fallback_texture(fallback_size)
	var loaded = load(path)
	if loaded is Texture2D:
		return loaded
	return _transparent_fallback_texture(fallback_size)


func _transparent_fallback_texture(fallback_size: Vector2i) -> Texture2D:
	if transparent_texture != null:
		return transparent_texture
	if _headless_mode():
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = Vector2(maxi(1, fallback_size.x), maxi(1, fallback_size.y))
		transparent_texture = placeholder
		return transparent_texture
	var image := Image.create(maxi(1, fallback_size.x), maxi(1, fallback_size.y), false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	transparent_texture = ImageTexture.create_from_image(image)
	return transparent_texture


func _queue_free_instance_id(instance_id: int) -> void:
	var node := instance_from_id(instance_id) as Node
	if node != null and is_instance_valid(node):
		node.queue_free()


func _headless_mode() -> bool:
	return DisplayServer.get_name() == "headless"
