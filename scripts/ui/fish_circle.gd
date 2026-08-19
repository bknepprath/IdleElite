extends Button

signal wallet_pressed

const PAPER_BUTTON_OUTLINE_WIDTH := 4.5
const FISH_CIRCLE_ICON_BASE_SIZE := Vector2(114, 114)
const FISH_CURRENCY_ICON_TEXTURE := "res://assets/content/icons/resources/fish-currency-icon.png"
const COLOR_MUTED := Color("#6e6658")
const COLOR_GOLD := Color("#fff2a8")

const RING_ARC_SEGMENTS := 40
const BEVEL_ARC_SEGMENTS := 32
const CENTER_NUMBER_STROKE_SCALE := 18.0
const CENTER_NUMBER_STROKE_MIN := 13
const CENTER_DECIMAL_SUFFIX_SCALE := 0.5
const CENTER_DECIMAL_SUFFIX_ALPHA := 0.6

var fish_count := 0.0
var display_text := "0"
var tool_text := ""
var tool_icon_path := "res://assets/content/fishing/tools/tool-bare-hands.png"
var theme_color := Color("#2dc0b9")
var readout_font: Font
var currency_icon_texture: Texture2D
var fish_icon: TextureRect
var wallet_hit_button: Button
var last_toggle_msec := 0
var wallet_open := false
var wallet_tool_ids: Array = []
var wallet_tool_icons: Array = []
var wallet_unlocked_states: Array = []
var wallet_equipped_tool_id := ""
var wallet_button_rects: Array = []
var wallet_visual_root: Control
var tool_icon_texture_resolver := Callable()

func _ready() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_load_readout_font()
	currency_icon_texture = _fish_currency_icon_texture()
	fish_icon = TextureRect.new()
	fish_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fish_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fish_icon.texture = _fish_circle_icon_texture()
	fish_icon.z_index = 4
	add_child(fish_icon)
	wallet_hit_button = Button.new()
	wallet_hit_button.name = "FishCircleWalletHitButton"
	wallet_hit_button.text = ""
	wallet_hit_button.flat = true
	wallet_hit_button.focus_mode = Control.FOCUS_NONE
	wallet_hit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	wallet_hit_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	wallet_hit_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	wallet_hit_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	wallet_hit_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	wallet_hit_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	wallet_hit_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	wallet_hit_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	wallet_hit_button.z_index = 1000
	wallet_hit_button.pressed.connect(_trigger_circle_pressed)
	add_child(wallet_hit_button)
	_layout_fish_icon()

func _on_circle_pressed() -> void:
	wallet_pressed.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			wallet_pressed.emit()
			accept_event()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			wallet_pressed.emit()
			accept_event()

func _trigger_circle_pressed() -> void:
	wallet_pressed.emit()

func _fish_circle_icon_texture() -> Texture2D:
	if tool_icon_texture_resolver.is_valid():
		var resolved_texture := tool_icon_texture_resolver.call(tool_icon_path) as Texture2D
		if resolved_texture != null:
			return resolved_texture
	if DisplayServer.get_name() != "headless" and ResourceLoader.exists(tool_icon_path):
		var loaded_texture := load(tool_icon_path) as Texture2D
		if loaded_texture != null:
			return loaded_texture
	return _fallback_texture(Vector2i(8, 8))

func _fish_currency_icon_texture() -> Texture2D:
	if DisplayServer.get_name() != "headless" and ResourceLoader.exists(FISH_CURRENCY_ICON_TEXTURE):
		var loaded_texture := load(FISH_CURRENCY_ICON_TEXTURE) as Texture2D
		if loaded_texture != null:
			return loaded_texture
	return _fallback_texture(Vector2i(8, 8))

func _fallback_texture(texture_size: Vector2i) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		var placeholder := PlaceholderTexture2D.new()
		placeholder.size = Vector2i(maxi(1, texture_size.x), maxi(1, texture_size.y))
		return placeholder
	var fallback_image := Image.create(maxi(1, texture_size.x), maxi(1, texture_size.y), false, Image.FORMAT_RGBA8)
	fallback_image.fill(Color(1.0, 1.0, 1.0, 0.0))
	return ImageTexture.create_from_image(fallback_image)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_fish_icon()
		if wallet_open:
			_build_wallet_rects()
			_rebuild_wallet_visual_children()

func _layout_fish_icon() -> void:
	if fish_icon == null or not is_instance_valid(fish_icon):
		return
	var min_size := minf(size.x, size.y)
	var draw_scale := min_size / 552.0
	var icon_size := (Vector2(400, 400) if wallet_open else FISH_CIRCLE_ICON_BASE_SIZE) * draw_scale * 0.95
	fish_icon.custom_minimum_size = icon_size
	fish_icon.size = icon_size
	if wallet_open:
		fish_icon.position = (size - icon_size) * 0.5
	else:
		fish_icon.position = Vector2(
			(size.x - icon_size.x) * 0.5,
			size.y * 0.5 - 278.0 * draw_scale
		)

func set_wallet_open_visual(open: bool) -> void:
	if wallet_open == open:
		return
	wallet_open = open
	_layout_fish_icon()
	queue_redraw()

func set_theme_color(next_color: Color) -> void:
	theme_color = next_color
	queue_redraw()

func set_fish_count(count: float, formatted_text: String, _instant := false) -> void:
	var next_count := maxf(0.0, count)
	if fish_count == next_count and display_text == formatted_text:
		return
	fish_count = next_count
	display_text = formatted_text
	queue_redraw()

func set_tool_text(next_tool_text: String) -> void:
	if tool_text == next_tool_text:
		return
	tool_text = next_tool_text
	queue_redraw()

func set_tool_icon_texture_resolver(resolver: Callable) -> void:
	tool_icon_texture_resolver = resolver
	if fish_icon != null and is_instance_valid(fish_icon):
		fish_icon.texture = _fish_circle_icon_texture()

func set_tool_icon(path: String) -> void:
	if tool_icon_path == path:
		return
	tool_icon_path = path
	if fish_icon != null and is_instance_valid(fish_icon):
		fish_icon.texture = _fish_circle_icon_texture()
	queue_redraw()

func tool_icon_global_rect() -> Rect2:
	if fish_icon != null and is_instance_valid(fish_icon):
		return fish_icon.get_global_rect()
	return get_global_rect()

func _draw() -> void:
	var center := size * 0.5
	var min_size := minf(size.x, size.y)
	var draw_scale := min_size / 552.0
	var gauge_stroke := PAPER_BUTTON_OUTLINE_WIDTH * draw_scale
	var radius := min_size * 0.5 - gauge_stroke * 0.5 - 4.0 * draw_scale
	draw_circle(center, radius, theme_color)
	_draw_inner_bevel(center, radius, draw_scale)
	draw_arc(center, radius + gauge_stroke * 0.5, -PI * 0.5, PI * 1.5, RING_ARC_SEGMENTS, Color("#171615"), gauge_stroke, true)
	_draw_center_content(center, draw_scale, min_size)

func _draw_inner_bevel(center: Vector2, radius: float, draw_scale: float) -> void:
	var bevel_radius := radius - 8.0 * draw_scale
	draw_arc(center, bevel_radius, PI * 0.12, PI * 0.88, BEVEL_ARC_SEGMENTS, Color(0.05, 0.04, 0.03, 0.14), maxf(4.0, 8.0 * draw_scale), true)
	draw_arc(center, bevel_radius - 5.0 * draw_scale, PI * 0.18, PI * 0.82, BEVEL_ARC_SEGMENTS, Color(0.05, 0.04, 0.03, 0.07), maxf(3.0, 5.0 * draw_scale), true)
	draw_arc(center, bevel_radius, PI * 1.12, PI * 1.88, BEVEL_ARC_SEGMENTS, Color(1, 1, 1, 0.13), maxf(2.0, 3.5 * draw_scale), true)

func _draw_center_content(center: Vector2, draw_scale: float, min_size: float) -> void:
	if wallet_open:
		return
	var font := readout_font if readout_font != null else ThemeDB.fallback_font
	var max_text_width := min_size * 0.72
	var number_parts := _split_decimal_text(display_text)
	var main_text := str(number_parts.get("main", display_text))
	var suffix_text := str(number_parts.get("suffix", ""))
	var font_size := _fit_font_size(font, main_text, maxi(64, int(min_size * 0.34)), 42, max_text_width)
	var stroke_size := maxi(CENTER_NUMBER_STROKE_MIN, int(round(CENTER_NUMBER_STROKE_SCALE * draw_scale)))
	var text_center := center
	_draw_currency_minnow_cluster(font, main_text, text_center, font_size, draw_scale)
	_draw_stroked_number_with_decimal_suffix(font, main_text, suffix_text, text_center, font_size, Color.WHITE, stroke_size)

func _split_decimal_text(label_text: String) -> Dictionary:
	var decimal_index := label_text.find(".")
	if decimal_index < 0 or not label_text.is_valid_float():
		return {"main": label_text, "suffix": ""}
	var main_text := label_text.substr(0, decimal_index)
	if main_text.is_empty() or main_text == "-":
		main_text += "0"
	return {
		"main": main_text,
		"suffix": label_text.substr(decimal_index)
	}

func _draw_currency_minnow_cluster(_font: Font, _text: String, _text_center: Vector2, _font_size: int, draw_scale: float) -> void:
	if currency_icon_texture == null:
		return
	var icon_size := Vector2(689.0, 462.0) * draw_scale
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - (PAPER_BUTTON_OUTLINE_WIDTH + 6.0) * draw_scale
	var rect := Rect2(
		Vector2(
			size.x * 0.5 - icon_size.x * 0.5,
			size.y - icon_size.y * 0.84 + 100.0 * draw_scale
		),
		icon_size
	)
	var row_height := maxf(2.0, 4.0 * draw_scale)
	var y := rect.position.y
	while y < rect.end.y:
		var slice_height := minf(row_height, rect.end.y - y)
		var sample_y := y + slice_height * 0.5
		var dy := sample_y - center.y
		var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
		if chord > 0.0:
			var left := maxf(rect.position.x, center.x - chord)
			var right := minf(rect.end.x, center.x + chord)
			if right > left:
				var src_y := (y - rect.position.y) / rect.size.y
				var src_h := slice_height / rect.size.y
				var src_x := (left - rect.position.x) / rect.size.x
				var src_w := (right - left) / rect.size.x
				draw_texture_rect_region(
					currency_icon_texture,
					Rect2(Vector2(left, y), Vector2(right - left, slice_height)),
					Rect2(Vector2(src_x * currency_icon_texture.get_width(), src_y * currency_icon_texture.get_height()), Vector2(src_w * currency_icon_texture.get_width(), src_h * currency_icon_texture.get_height())),
					Color(1, 1, 1, 0.34)
				)
		y += row_height

func _load_readout_font() -> void:
	if ResourceLoader.exists("res://assets/fonts/Fredoka.ttf"):
		var loaded := load("res://assets/fonts/Fredoka.ttf")
		if loaded is Font:
			var bold := FontVariation.new()
			bold.base_font = loaded
			bold.variation_embolden = 1.05
			readout_font = bold
	if readout_font == null:
		readout_font = ThemeDB.fallback_font

func _fit_font_size(font: Font, label_text: String, desired_size: int, minimum_size: int, max_width: float) -> int:
	var fitted := desired_size
	while fitted > minimum_size and font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
		fitted -= 2
	return fitted

func _draw_stroked_text_centered(font: Font, label_text: String, center: Vector2, font_size: int, fill_color: Color, stroke_size: int) -> void:
	var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var text_position := Vector2(center.x - text_size.x * 0.5, baseline)
	draw_string_outline(font, text_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, stroke_size, Color("#171615"))
	draw_string(font, text_position, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill_color)

func _draw_stroked_number_with_decimal_suffix(font: Font, main_text: String, suffix_text: String, center: Vector2, font_size: int, fill_color: Color, stroke_size: int) -> void:
	var main_size := font.get_string_size(main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var main_baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var main_position := Vector2(center.x - main_size.x * 0.5, main_baseline)
	draw_string_outline(font, main_position, main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, stroke_size, Color("#171615"))
	draw_string(font, main_position, main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill_color)
	if suffix_text.is_empty():
		return
	var suffix_size := maxi(24, int(round(float(font_size) * CENTER_DECIMAL_SUFFIX_SCALE)))
	var suffix_stroke := maxi(6, int(round(float(stroke_size) * CENTER_DECIMAL_SUFFIX_SCALE)))
	var suffix_gap := maxf(4.0, float(font_size) * 0.075)
	var suffix_baseline := center.y + (font.get_ascent(suffix_size) - font.get_descent(suffix_size)) * 0.5
	var suffix_position := Vector2(main_position.x + main_size.x + suffix_gap, suffix_baseline)
	var suffix_fill := fill_color
	suffix_fill.a *= CENTER_DECIMAL_SUFFIX_ALPHA
	var suffix_outline := Color("#171615", CENTER_DECIMAL_SUFFIX_ALPHA)
	draw_string_outline(font, suffix_position, suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, suffix_size, suffix_stroke, suffix_outline)
	draw_string(font, suffix_position, suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, suffix_size, suffix_fill)

func configure_wallet(open: bool, tool_ids: Array, tool_icons: Array, unlocked_states: Array, equipped_tool_id: String) -> void:
	wallet_open = open
	wallet_tool_ids = tool_ids
	wallet_tool_icons = tool_icons
	wallet_unlocked_states = unlocked_states
	wallet_equipped_tool_id = equipped_tool_id
	_build_wallet_rects()
	_rebuild_wallet_visual_children()
	queue_redraw()

func wallet_button_index_at(global_point: Vector2) -> int:
	if not wallet_open:
		return -1
	var local_point := get_global_transform_with_canvas().affine_inverse() * global_point
	for index in range(wallet_button_rects.size()):
		var rect := wallet_button_rects[index] as Rect2
		if rect.has_point(local_point):
			return index
	return -1

func wallet_button_center_global(index: int) -> Vector2:
	if index < 0 or index >= wallet_button_rects.size():
		return Vector2.ZERO
	var rect := wallet_button_rects[index] as Rect2
	return get_global_transform_with_canvas() * rect.get_center()

func _build_wallet_rects() -> void:
	wallet_button_rects.clear()
	var count := wallet_tool_ids.size()
	if count <= 0:
		return
	var min_size := minf(size.x, size.y)
	if min_size <= 0.0:
		min_size = 552.0
	var draw_scale := min_size / 552.0
	var button_size := 148.0 * draw_scale
	var gap := 18.0 * draw_scale
	var padding := 24.0 * draw_scale
	var panel_width := button_size + padding * 2.0
	var panel_left := size.x - panel_width - 8.0 * draw_scale
	var panel_top := 12.0 * draw_scale
	for index in range(count):
		wallet_button_rects.append(Rect2(
			Vector2(panel_left + padding, panel_top + padding + float(index) * (button_size + gap)),
			Vector2(button_size, button_size)
		))

func _rebuild_wallet_visual_children() -> void:
	if wallet_visual_root != null and is_instance_valid(wallet_visual_root):
		wallet_visual_root.queue_free()
		wallet_visual_root = null
	if not wallet_open or wallet_button_rects.is_empty():
		return
	var root := Control.new()
	root.name = "FishCircleVisibleWallet"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.top_level = true
	root.position = get_global_rect().position
	root.size = size
	root.clip_contents = false
	root.z_index = 4090
	root.z_as_relative = false
	add_child(root)
	wallet_visual_root = root
	var min_size := minf(size.x, size.y)
	if min_size <= 0.0:
		min_size = 552.0
	var draw_scale := min_size / 552.0
	var padding := 24.0 * draw_scale
	var first := wallet_button_rects[0] as Rect2
	var last := wallet_button_rects[wallet_button_rects.size() - 1] as Rect2
	var panel_rect := Rect2(
		Vector2(first.position.x - padding, first.position.y - padding),
		Vector2(first.size.x + padding * 2.0, last.end.y - first.position.y + padding * 2.0)
	)
	var panel := Panel.new()
	panel.name = "FishCircleVisibleWalletPill"
	panel.position = panel_rect.position
	panel.size = panel_rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _wallet_style(Color("#e8fbf6", 0.94), Color("#168f83"), 6.0 * draw_scale, panel_rect.size.x * 0.5))
	root.add_child(panel)
	for index in range(wallet_button_rects.size()):
		var rect := wallet_button_rects[index] as Rect2
		var tool_id := str(wallet_tool_ids[index])
		var unlocked := bool(wallet_unlocked_states[index])
		var equipped := tool_id == wallet_equipped_tool_id
		var fill := Color("#32c5bd") if equipped else (Color("#ffffff") if unlocked else Color("#cfcac0"))
		var border := COLOR_GOLD if equipped else (Color("#171615") if unlocked else COLOR_MUTED)
		var circle := Panel.new()
		circle.name = "FishCircleVisibleWalletGear%s" % str(index)
		circle.position = rect.position
		circle.size = rect.size
		circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		circle.add_theme_stylebox_override("panel", _wallet_style(fill, border, 8.0 * draw_scale if equipped else 5.0 * draw_scale, rect.size.x * 0.5))
		root.add_child(circle)
		var tool_icon := wallet_tool_icons[index] as Texture2D
		if tool_icon != null:
			var icon_rect := _fit_wallet_texture_rect(tool_icon, Rect2(Vector2.ZERO, rect.size).grow(-18.0 * draw_scale))
			var texture_rect := TextureRect.new()
			texture_rect.texture = tool_icon
			texture_rect.position = icon_rect.position
			texture_rect.size = icon_rect.size
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.modulate = Color.WHITE if unlocked else Color(1, 1, 1, 0.42)
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			circle.add_child(texture_rect)

func _wallet_style(fill: Color, border: Color, border_width: float, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	var border_int := maxi(1, int(round(border_width)))
	style.border_width_left = border_int
	style.border_width_top = border_int
	style.border_width_right = border_int
	style.border_width_bottom = border_int
	var corner := maxi(1, int(round(radius)))
	style.corner_radius_top_left = corner
	style.corner_radius_top_right = corner
	style.corner_radius_bottom_left = corner
	style.corner_radius_bottom_right = corner
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 4
	style.shadow_offset = Vector2(1.5, 2.5)
	return style

func _draw_wallet_menu(draw_scale: float) -> void:
	_build_wallet_rects()
	var count := wallet_button_rects.size()
	if count <= 0:
		return
	var padding := 24.0 * draw_scale
	var first := wallet_button_rects[0] as Rect2
	var last := wallet_button_rects[count - 1] as Rect2
	var panel_rect := Rect2(
		Vector2(first.position.x - padding, first.position.y - padding),
		Vector2(first.size.x + padding * 2.0, last.end.y - first.position.y + padding * 2.0)
	)
	_draw_wallet_pill(panel_rect, Color("#fff6df"), Color("#171615"), 10.0 * draw_scale)
	for index in range(count):
		var rect := wallet_button_rects[index] as Rect2
		var tool_id := str(wallet_tool_ids[index])
		var unlocked := bool(wallet_unlocked_states[index])
		var equipped := tool_id == wallet_equipped_tool_id
		var fill := Color("#32c5bd") if equipped else (Color("#ffffff") if unlocked else Color("#cfcac0"))
		var border := COLOR_GOLD if equipped else (Color("#171615") if unlocked else COLOR_MUTED)
		_draw_wallet_pill(rect, fill, border, (8.0 if equipped else 5.0) * draw_scale)
		var tool_icon := wallet_tool_icons[index] as Texture2D
		if tool_icon != null:
			var icon_rect := _fit_wallet_texture_rect(tool_icon, rect.grow(-18.0 * draw_scale))
			draw_texture_rect(tool_icon, icon_rect, false, Color.WHITE if unlocked else Color(1, 1, 1, 0.42))

func _draw_wallet_pill(rect: Rect2, fill: Color, border: Color, border_width: float) -> void:
	_draw_wallet_filled_pill(rect, border)
	_draw_wallet_filled_pill(rect.grow(-border_width), fill)

func _draw_wallet_filled_pill(rect: Rect2, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var radius := minf(rect.size.x, rect.size.y) * 0.5
	if rect.size.y >= rect.size.x:
		draw_rect(Rect2(rect.position.x, rect.position.y + radius, rect.size.x, maxf(0.0, rect.size.y - radius * 2.0)), color)
		draw_circle(Vector2(rect.position.x + radius, rect.position.y + radius), radius, color)
		draw_circle(Vector2(rect.position.x + radius, rect.end.y - radius), radius, color)
	else:
		draw_rect(Rect2(rect.position.x + radius, rect.position.y, maxf(0.0, rect.size.x - radius * 2.0), rect.size.y), color)
		draw_circle(Vector2(rect.position.x + radius, rect.position.y + radius), radius, color)
		draw_circle(Vector2(rect.end.x - radius, rect.position.y + radius), radius, color)

func _fit_wallet_texture_rect(texture: Texture2D, bounds: Rect2) -> Rect2:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return bounds
	var draw_scale := minf(bounds.size.x / texture_size.x, bounds.size.y / texture_size.y)
	var draw_size := texture_size * draw_scale
	return Rect2(bounds.position + (bounds.size - draw_size) * 0.5, draw_size)
