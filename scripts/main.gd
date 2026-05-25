extends Control

class RegenCircle:
	extends Control

	var value := 0.0
	var target_value := 0.0
	var displayed_current := 0.0
	var target_current := 0.0
	var current := 0
	var maximum := 1
	var theme_color := Color("#36b8e8")
	var value_initialized := false
	var stamina_initialized := false
	var readout_font: Font

	func _ready() -> void:
		_load_readout_font()
		set_process(true)

	func set_value(next_value: float, instant := false) -> void:
		var clamped_value := clampf(next_value, 0.0, 1.0)
		var wrapped_to_next_refill := value_initialized and clamped_value < target_value - 0.18
		target_value = clamped_value
		if instant or not value_initialized or wrapped_to_next_refill:
			value = target_value
			value_initialized = true
		queue_redraw()

	func set_theme_color(next_color: Color) -> void:
		theme_color = next_color
		queue_redraw()

	func set_stamina(next_current: int, next_maximum: int, instant := false, regen_fraction := 0.0) -> void:
		current = maxi(0, next_current)
		maximum = maxi(1, next_maximum)
		target_current = clampf(float(current) + clampf(regen_fraction, 0.0, 1.0), 0.0, float(maximum))
		if instant or not stamina_initialized:
			displayed_current = target_current
			stamina_initialized = true
		queue_redraw()

	func _process(delta: float) -> void:
		var next_value := _ease_to(value, target_value, 18.0, delta)
		var next_current := _ease_to(displayed_current, target_current, 9.0, delta)
		if absf(next_value - value) > 0.0005 or absf(next_current - displayed_current) > 0.01:
			value = next_value
			displayed_current = next_current
			queue_redraw()
		else:
			var needs_final_redraw := absf(value - target_value) > 0.0 or absf(displayed_current - target_current) > 0.0
			value = target_value
			displayed_current = target_current
			if needs_final_redraw:
				queue_redraw()

	func _ease_to(from: float, to: float, speed: float, delta: float) -> float:
		if delta <= 0.0:
			return from
		return lerpf(from, to, 1.0 - exp(-speed * delta))

	func _draw() -> void:
		var center := size * 0.5
		var scale := minf(size.x, size.y) / 552.0
		var outer_radius := minf(size.x, size.y) * 0.5
		var outer_border := 18.0 * scale
		var ring_width := 60.0 * scale
		var ring_radius := outer_radius - outer_border - ring_width * 0.5
		var black_radius := outer_radius - 48.0 * scale
		var inner_radius := 186.0 * scale
		var inner_border := 18.0 * scale
		draw_circle(center, outer_radius, Color("#171615"))
		draw_circle(center, outer_radius - outer_border, Color("#fff2a8"))
		draw_arc(center, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * value, 128, theme_color, ring_width, true)
		draw_circle(center, black_radius, Color("#171615"))
		draw_circle(center, inner_radius + inner_border, Color("#171615"))
		draw_circle(center, inner_radius, Color("#fffaf0"))
		_draw_inner_fill(center, inner_radius)
		_draw_center_text(center)

	func _draw_inner_fill(center: Vector2, radius: float) -> void:
		var pct := clampf(displayed_current / float(maximum), 0.0, 1.0)
		if pct <= 0.0:
			return
		if pct >= 0.995:
			draw_circle(center, radius, theme_color)
			return
		var fill_top := center.y + radius - radius * 2.0 * pct
		var fill_bottom := center.y + radius
		var step := maxf(1.0, radius / 64.0)
		var y := fill_top
		while y <= fill_bottom:
			var dy := y - center.y
			var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
			draw_line(Vector2(center.x - chord, y), Vector2(center.x + chord, y), theme_color, step + 1.0, true)
			y += step

	func _draw_center_text(center: Vector2) -> void:
		var font := readout_font if readout_font != null else ThemeDB.fallback_font
		var min_size := minf(size.x, size.y)
		var scale := min_size / 552.0
		var max_text_width := min_size * 0.58
		var large := _fit_font_size(font, str(clampi(current, 0, maximum)), maxi(54, int(min_size * 0.275)), 42, max_text_width)
		var small_text := str(maximum)
		var small := _fit_font_size(font, small_text, maxi(24, int(min_size * 0.092)), 18, max_text_width)
		var shown_current := clampi(current, 0, maximum)
		var current_center_y := center.y - 16.0 * scale
		var divider_y := center.y + 62.0 * scale
		var max_center_y := center.y + 114.0 * scale
		_draw_stroked_text_centered(font, str(shown_current), Vector2(center.x, current_center_y), large, Color.WHITE, maxi(5, int(round(8.0 * scale))))
		_draw_center_divider(center, divider_y, 106.0 * scale, scale)
		_draw_stroked_text_centered(font, small_text, Vector2(center.x, max_center_y), small, Color("#fff2a8"), maxi(4, int(round(5.0 * scale))))

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

	func _fit_font_size(font: Font, text: String, desired_size: int, minimum_size: int, max_width: float) -> int:
		var fitted := desired_size
		while fitted > minimum_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
			fitted -= 2
		return fitted

	func _draw_center_divider(center: Vector2, y: float, width: float, scale: float) -> void:
		var start := Vector2(center.x - width * 0.5, y)
		var finish := Vector2(center.x + width * 0.5, y)
		var stroke_width := maxf(6.0, 12.0 * scale)
		var fill_width := maxf(2.0, 4.5 * scale)
		draw_line(start, finish, Color("#171615"), stroke_width, true)
		draw_circle(start, stroke_width * 0.5, Color("#171615"))
		draw_circle(finish, stroke_width * 0.5, Color("#171615"))
		draw_line(start, finish, Color.WHITE, fill_width, true)
		draw_circle(start, fill_width * 0.5, Color.WHITE)
		draw_circle(finish, fill_width * 0.5, Color.WHITE)

	func _draw_stroked_text_centered(font: Font, text: String, center: Vector2, font_size: int, fill_color: Color, stroke_size: int) -> void:
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		var position := Vector2(center.x - text_size.x * 0.5, baseline)
		for x in range(-stroke_size, stroke_size + 1):
			for y in range(-stroke_size, stroke_size + 1):
				if x == 0 and y == 0:
					continue
				var offset := Vector2(x, y)
				if offset.length() <= float(stroke_size) + 0.25:
					draw_string(font, position + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#171615"))
		draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill_color)


class CleanProgressBar:
	extends Control

	var value := 0.0
	var fill_color := Color.WHITE
	var track_color := Color("#fff1c8")
	var border_color := Color("#d9cfbc")
	var border_width := 8.0
	var easing_speed := 12.0

	func set_value(next_value: float) -> void:
		value = clampf(next_value, 0.0, 100.0)
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var radius := size.y * 0.5
		_draw_round_rect(rect, track_color, radius)
		var inner := rect.grow(-border_width)
		_draw_round_rect(inner, track_color, maxf(0.0, radius - border_width))
		var fill_width := inner.size.x * value / 100.0
		if fill_width > 0.0:
			var fill := Rect2(inner.position, Vector2(fill_width, inner.size.y))
			if fill_width >= inner.size.x - 0.5:
				_draw_round_rect(inner, fill_color, maxf(0.0, radius - border_width))
			else:
				draw_rect(fill, fill_color)
		_draw_round_outline(rect, border_color, radius, border_width)

	func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
		var center_y := rect.position.y + rect.size.y * 0.5
		var clamped_radius := minf(radius, rect.size.x * 0.5)
		draw_rect(Rect2(rect.position + Vector2(clamped_radius, 0), Vector2(maxf(0.0, rect.size.x - clamped_radius * 2.0), rect.size.y)), color)
		draw_circle(Vector2(rect.position.x + clamped_radius, center_y), clamped_radius, color)
		draw_circle(Vector2(rect.end.x - clamped_radius, center_y), clamped_radius, color)

	func _draw_round_outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
		var half_width := width * 0.5
		var y_top := rect.position.y + half_width
		var y_bottom := rect.end.y - half_width
		var x_left := rect.position.x + radius
		var x_right := rect.end.x - radius
		draw_line(Vector2(x_left, y_top), Vector2(x_right, y_top), color, width, true)
		draw_line(Vector2(x_left, y_bottom), Vector2(x_right, y_bottom), color, width, true)
		draw_arc(Vector2(x_left, rect.position.y + radius), radius - half_width, PI, PI * 1.5, 32, color, width, true)
		draw_arc(Vector2(x_right, rect.position.y + radius), radius - half_width, PI * 1.5, TAU, 32, color, width, true)
		draw_arc(Vector2(x_left, rect.end.y - radius), radius - half_width, PI * 0.5, PI, 32, color, width, true)
		draw_arc(Vector2(x_right, rect.end.y - radius), radius - half_width, 0.0, PI * 0.5, 32, color, width, true)


class ActivityProgressRail:
	extends Control

	var value := 0.0
	var easing_speed := 24.0
	var fill_color := Color("#35d86d")
	var empty_color := Color("#fff1c8")
	var top_lip_color := Color("#171615")
	var top_lip_height := 16.0
	var bottom_radius := 66.0
	var fill_style := StyleBoxFlat.new()
	var empty_style := StyleBoxFlat.new()

	func set_value(next_value: float) -> void:
		var clamped := clampf(next_value, 0.0, 100.0)
		if absf(value - clamped) <= 0.001:
			return
		value = clamped
		queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, top_lip_height)), top_lip_color)
		var track_rect := Rect2(Vector2(0, top_lip_height), Vector2(size.x, maxf(0.0, size.y - top_lip_height)))
		_draw_bottom_round_fill(track_rect, empty_style, empty_color, 1.0)
		_draw_bottom_round_fill(track_rect, fill_style, fill_color, value / 100.0)

	func _draw_bottom_round_fill(rect: Rect2, style: StyleBoxFlat, color: Color, fill_pct: float) -> void:
		var pct := clampf(fill_pct, 0.0, 1.0)
		if pct <= 0.0 or rect.size.y <= 0.0:
			return
		var radius := minf(bottom_radius, minf(rect.size.x * 0.5, rect.size.y))
		var fill_rect := Rect2(rect.position, Vector2(rect.size.x * pct, rect.size.y))
		if fill_rect.size.x <= 0.0:
			return
		style.bg_color = color
		var left_radius := int(minf(radius, fill_rect.size.x * 0.5))
		style.corner_radius_bottom_left = left_radius
		style.corner_radius_bottom_right = 0
		if pct >= 0.999:
			style.corner_radius_bottom_right = int(radius)
		draw_style_box(style, fill_rect)


class AchievementMedalSlotStrip:
	extends Control

	var slot_count := 25
	var slot_size := Vector2(58, 58)
	var icons := []
	var shadows := []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layout_icons()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout_icons()
			queue_redraw()

	func add_slot_icon(icon: TextureRect, shadow: TextureRect = null) -> void:
		if shadow != null:
			shadows.append(shadow)
			add_child(shadow)
		icons.append(icon)
		add_child(icon)
		_layout_icons()

	func _layout_icons() -> void:
		if icons.is_empty():
			return
		var icon_size := minf(slot_size.x, maxf(1.0, size.y * 0.92))
		for i in range(icons.size()):
			var center := _slot_center(i, icon_size)
			if i < shadows.size():
				var shadow := shadows[i] as TextureRect
				if shadow != null:
					shadow.size = Vector2(icon_size, icon_size)
					shadow.position = center - shadow.size * 0.5 + Vector2(7, 9)
			var icon := icons[i] as TextureRect
			if icon == null:
				continue
			icon.size = Vector2(icon_size, icon_size)
			icon.position = center - icon.size * 0.5

	func _slot_center(index: int, icon_size: float) -> Vector2:
		var count := maxi(1, slot_count)
		var left := icon_size * 0.5
		var right := maxf(left, size.x - icon_size * 0.5)
		var x := (left + right) * 0.5
		if count > 1:
			x = lerpf(left, right, float(index) / float(count - 1))
		return Vector2(x, size.y * 0.52)


class ActivityCardBorder:
	extends Control

	var border_color := Color("#171615")
	var border_width := 24.0
	var radius := 66.0

	func _draw() -> void:
		var half := border_width * 0.5
		var left := half
		var right := maxf(half, size.x - half)
		var top := half
		var bottom := maxf(half, size.y - half)
		var r := minf(radius, minf(size.x, size.y) * 0.5 - half)
		draw_line(Vector2(left + r, top), Vector2(right - r, top), border_color, border_width, true)
		draw_line(Vector2(left + r, bottom), Vector2(right - r, bottom), border_color, border_width, true)
		draw_line(Vector2(left, top + r), Vector2(left, bottom - r), border_color, border_width, true)
		draw_line(Vector2(right, top + r), Vector2(right, bottom - r), border_color, border_width, true)
		draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 24, border_color, border_width, true)
		draw_arc(Vector2(right - r, top + r), r, PI * 1.5, PI * 2.0, 24, border_color, border_width, true)
		draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 24, border_color, border_width, true)
		draw_arc(Vector2(left + r, bottom - r), r, PI * 0.5, PI, 24, border_color, border_width, true)


class RoundedTextureRect:
	extends TextureRect

	var radius := 66.0
	var crop_left := 0.0
	var crop_right := 0.0

	func _ready() -> void:
		_ensure_mask_material()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_update_mask_params()

	func _ensure_mask_material() -> void:
		if material == null:
			var shader := Shader.new()
			shader.code = """
shader_type canvas_item;

uniform vec2 control_size = vec2(1.0, 1.0);
uniform float radius_px = 64.0;
uniform float crop_left = 0.0;
uniform float crop_right = 0.0;

void fragment() {
	vec2 p = UV * control_size;
	vec2 half_size = control_size * 0.5;
	float r = min(radius_px, min(half_size.x, half_size.y));
	vec2 q = abs(p - half_size) - (half_size - vec2(r));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
	float alpha = 1.0 - smoothstep(0.0, 2.0, distance);
	vec4 tint = COLOR;
	float crop_width = max(0.001, 1.0 - crop_left - crop_right);
	vec2 source_uv = vec2(crop_left + UV.x * crop_width, UV.y);
	vec4 color = texture(TEXTURE, source_uv) * tint;
	color.a *= alpha;
	COLOR = color;
}
"""
			var shader_material := ShaderMaterial.new()
			shader_material.shader = shader
			material = shader_material
		_update_mask_params()

	func _update_mask_params() -> void:
		var shader_material := material as ShaderMaterial
		if shader_material == null:
			return
		shader_material.set_shader_parameter("control_size", size)
		shader_material.set_shader_parameter("radius_px", radius)
		shader_material.set_shader_parameter("crop_left", crop_left)
		shader_material.set_shader_parameter("crop_right", crop_right)


class ActivityChainLink:
	extends Control

	var texture: Texture2D

	func _draw() -> void:
		if texture == null or size.x <= 1.0 or size.y <= 1.0:
			return
		var rect := Rect2(Vector2.ZERO, size)
		var shadow_offset := Vector2(maxf(5.0, size.x * 0.035), maxf(6.0, size.y * 0.08))
		draw_texture_rect(texture, Rect2(shadow_offset, size), false, Color(0, 0, 0, 0.26))
		draw_texture_rect(texture, rect, false, Color.WHITE)
		var shine_width := maxf(6.0, size.y * 0.065)
		var shine_y := size.y * 0.30
		draw_line(Vector2(size.x * 0.20, shine_y), Vector2(size.x * 0.34, shine_y), Color(1, 1, 1, 0.78), shine_width, true)


class ActivityLockNumber:
	extends Control

	var text := "1"
	var font: Font
	var font_size := 250
	var outline_size := 46

	func set_text(next_text: String) -> void:
		text = next_text
		queue_redraw()

	func _draw() -> void:
		var active_font := font if font != null else ThemeDB.fallback_font
		var fitted := font_size
		var max_width := size.x * 0.86
		while fitted > 72 and active_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
			fitted -= 4
		var text_size := active_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted)
		var baseline := size.y * 0.5 + (active_font.get_ascent(fitted) - active_font.get_descent(fitted)) * 0.5
		var position := Vector2((size.x - text_size.x) * 0.5, baseline)
		for x in range(-outline_size, outline_size + 1, 3):
			for y in range(-outline_size, outline_size + 1, 3):
				if x == 0 and y == 0:
					continue
				var offset := Vector2(x, y)
				if offset.length() <= float(outline_size) + 0.25:
					draw_string(active_font, position + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Color("#171615"))
		draw_string(active_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Color.WHITE)


class ActivityLockRig:
	extends Control

	signal chain_moved
	signal padlock_clicked

	const LINKS_PER_SIDE := 6
	const CENTER_CHAIN_LINKS := 3
	const LINK_SIZE := Vector2(188, 116)
	const PADLOCK_SIZE := Vector2(540, 590)
	const CONSTRAINT_PASSES := 7
	const LOCK_DRAG_DEADZONE := 14.0
	const CHAIN_SFX_COOLDOWN_MSEC := 170
	const CHAIN_SFX_MOVE_DISTANCE := 38.0
	const LOCK_CLICK_SHAKE_SECONDS := 0.26

	var link_texture: Texture2D
	var padlock_texture: Texture2D
	var chain_points := {-1: [], 1: []}
	var chain_prev_points := {-1: [], 1: []}
	var chain_rest_lengths := {-1: [], 1: []}
	var chain_base_points := {-1: [], 1: []}
	var padlock_shadow: TextureRect
	var padlock: TextureRect
	var level_label: ActivityLockNumber
	var level := 1
	var base_lock_position := Vector2.ZERO
	var lock_offset := Vector2.ZERO
	var lock_velocity := Vector2.ZERO
	var lock_rotation := 0.0
	var physics_active := false
	var pressing_lock := false
	var dragging_lock := false
	var press_position := Vector2.ZERO
	var drag_start_lock_offset := Vector2.ZERO
	var last_chain_sound_msec := 0
	var last_chain_sound_offset := Vector2.ZERO
	var click_shake_remaining := 0.0
	var click_shake_direction := 1.0
	var rng := RandomNumberGenerator.new()

	func setup(next_link_texture: Texture2D, next_padlock_texture: Texture2D, unlock_level: int, font: Font, fallback_font: Font) -> void:
		link_texture = next_link_texture
		padlock_texture = next_padlock_texture
		level = unlock_level
		mouse_filter = Control.MOUSE_FILTER_PASS
		rng.randomize()
		_build(font, fallback_font)
		set_process(true)

	func set_unlock_level(next_level: int) -> void:
		level = next_level
		if level_label != null:
			level_label.set_text(str(level))

	func unlock_impulse() -> void:
		_rattle_lock()

	func _build(font: Font, fallback_font: Font) -> void:
		_clear_children()
		padlock_shadow = _padlock_piece(Color(0, 0, 0, 0.26))
		padlock_shadow.z_index = 4
		add_child(padlock_shadow)
		padlock = _padlock_piece(Color.WHITE)
		padlock.mouse_filter = Control.MOUSE_FILTER_STOP
		padlock.gui_input.connect(_on_padlock_gui_input)
		padlock.z_index = 5
		add_child(padlock)
		level_label = ActivityLockNumber.new()
		level_label.set_text(str(level))
		level_label.font_size = 206
		level_label.outline_size = 24
		if font != null:
			level_label.font = font
		elif fallback_font != null:
			level_label.font = fallback_font
		level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		level_label.z_index = 6
		add_child(level_label)
		_layout_base()

	func _padlock_piece(color: Color) -> TextureRect:
		var piece := TextureRect.new()
		piece.texture = padlock_texture
		piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.modulate = color
		return piece

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			_layout_base()

	func _gui_input(event: InputEvent) -> void:
		if pressing_lock or _padlock_contains_local_point(get_local_mouse_position()):
			_on_padlock_gui_input(event)

	func handle_pointer_event(event: InputEvent) -> bool:
		var local_position := _event_local_position(event)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not _padlock_contains_local_point(local_position):
				return false
			if pressing_lock or _padlock_contains_local_point(local_position):
				_on_padlock_gui_input(event)
				return true
		elif event is InputEventMouseMotion and pressing_lock:
			_on_padlock_gui_input(event)
			return true
		elif event is InputEventScreenTouch:
			if event.pressed and not _padlock_contains_local_point(local_position):
				return false
			if pressing_lock or _padlock_contains_local_point(local_position):
				_on_padlock_gui_input(event)
				return true
		elif event is InputEventScreenDrag and pressing_lock:
			_on_padlock_gui_input(event)
			return true
		return false

	func _event_local_position(event: InputEvent) -> Vector2:
		if event is InputEventMouseButton:
			return get_global_transform_with_canvas().affine_inverse() * event.global_position
		if event is InputEventMouseMotion:
			return get_global_transform_with_canvas().affine_inverse() * event.global_position
		if event is InputEventScreenTouch:
			return get_global_transform_with_canvas().affine_inverse() * event.position
		if event is InputEventScreenDrag:
			return get_global_transform_with_canvas().affine_inverse() * event.position
		return get_local_mouse_position()

	func _process(delta: float) -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		if pressing_lock and dragging_lock:
			var target := get_local_mouse_position() - press_position + drag_start_lock_offset
			var next_offset := lock_offset.lerp(target, 1.0 - exp(-30.0 * delta))
			lock_velocity = (next_offset - lock_offset) / maxf(delta, 0.001)
			lock_offset = next_offset
			physics_active = true
			_emit_chain_moved_if_ready()
		elif physics_active:
			lock_velocity += -lock_offset * 72.0 * delta
			lock_velocity *= exp(-9.5 * delta)
			lock_offset += lock_velocity * delta
			if lock_offset.length() <= 0.35 and lock_velocity.length() <= 3.0 and _chains_settled() and click_shake_remaining <= 0.0:
				lock_offset = Vector2.ZERO
				lock_velocity = Vector2.ZERO
				lock_rotation = 0.0
				physics_active = false
				_reset_chain_points(false)
		if click_shake_remaining > 0.0:
			click_shake_remaining = maxf(0.0, click_shake_remaining - delta)
		if physics_active:
			_simulate_chains(delta)
			lock_rotation = clampf(lock_velocity.x * 0.00055, -0.10, 0.10)
			var shake_pct := click_shake_remaining / LOCK_CLICK_SHAKE_SECONDS
			var shake_wave := sin((1.0 - shake_pct) * PI * 7.0) * shake_pct * click_shake_direction
			var visual_offset := lock_offset + Vector2(shake_wave * 10.0, absf(shake_wave) * 3.0)
			var visual_rotation := lock_rotation + shake_wave * 0.085
			_place_padlock(visual_offset, visual_rotation)
			queue_redraw()

	func _layout_base() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		base_lock_position = Vector2(size.x * 0.5 - PADLOCK_SIZE.x * 0.5, 48.0)
		_reset_chain_points(true)
		_place_padlock(lock_offset, lock_rotation)
		queue_redraw()

	func _reset_chain_points(reset_motion: bool) -> void:
		if reset_motion:
			lock_offset = Vector2.ZERO
			lock_velocity = Vector2.ZERO
			lock_rotation = 0.0
			physics_active = false
		for side in [-1, 1]:
			var points := []
			var previous := []
			var base_points := []
			var rest_lengths := []
			for i in range(LINKS_PER_SIDE):
				var point := _base_chain_point(side, i, lock_offset)
				points.append(point)
				previous.append(point)
				base_points.append(_base_chain_point(side, i, Vector2.ZERO))
				if i > 0:
					rest_lengths.append((point - points[i - 1]).length())
			chain_points[side] = points
			chain_prev_points[side] = previous
			chain_base_points[side] = base_points
			chain_rest_lengths[side] = rest_lengths

	func _base_chain_point(side: int, index: int, offset: Vector2) -> Vector2:
		var t := float(index) / float(LINKS_PER_SIDE - 1)
		var outer_anchor := _outer_chain_anchor(side)
		var inner_anchor := _lock_chain_anchor(side, offset)
		var point := outer_anchor.lerp(inner_anchor, t)
		point.y += sin(t * PI) * size.y * 0.085
		return point

	func _outer_chain_anchor(side: int) -> Vector2:
		var margin := LINK_SIZE.x * 0.48
		return Vector2(margin if side < 0 else size.x - margin, size.y * 0.28)

	func _lock_chain_anchor(side: int, offset: Vector2) -> Vector2:
		return base_lock_position + offset + Vector2(PADLOCK_SIZE.x * 0.5 + float(side) * PADLOCK_SIZE.x * 0.38, PADLOCK_SIZE.y * 0.35)

	func _simulate_chains(delta: float) -> void:
		var damping := exp(-10.0 * delta)
		var rest_pull := 1.0 - exp(-18.0 * delta)
		for side in [-1, 1]:
			var points := chain_points[side] as Array
			var previous := chain_prev_points[side] as Array
			var base_points := chain_base_points[side] as Array
			if points.is_empty():
				continue
			for i in range(points.size()):
				var point := points[i] as Vector2
				var last := previous[i] as Vector2
				var velocity := (point - last) * damping
				previous[i] = point
				point += velocity
				var base_point := base_points[i] as Vector2
				if i > 0 and i < points.size() - 1:
					point = point.lerp(base_point + lock_offset * (float(i) / float(points.size() - 1)) * 0.25, rest_pull * 0.22)
				points[i] = point
			for pass_index in range(CONSTRAINT_PASSES):
				points[0] = _outer_chain_anchor(side)
				points[points.size() - 1] = (points[points.size() - 1] as Vector2).lerp(_lock_chain_anchor(side, lock_offset), 0.58)
				_apply_chain_constraints(side)
			points[0] = _outer_chain_anchor(side)
			points[points.size() - 1] = (points[points.size() - 1] as Vector2).lerp(_lock_chain_anchor(side, lock_offset), 0.72)
			chain_points[side] = points
			chain_prev_points[side] = previous

	func _apply_chain_constraints(side: int) -> void:
		var points := chain_points[side] as Array
		var rest_lengths := chain_rest_lengths[side] as Array
		for i in range(points.size() - 1):
			var a := points[i] as Vector2
			var b := points[i + 1] as Vector2
			var delta := b - a
			var distance := maxf(delta.length(), 0.001)
			var rest := float(rest_lengths[i])
			var correction := delta * ((distance - rest) / distance)
			if i == 0:
				b -= correction
			elif i == points.size() - 2:
				a += correction * 0.45
				b -= correction * 0.55
			else:
				a += correction * 0.5
				b -= correction * 0.5
			points[i] = a
			points[i + 1] = b

	func _chains_settled() -> bool:
		for side in [-1, 1]:
			var points := chain_points[side] as Array
			var base_points := chain_base_points[side] as Array
			for i in range(points.size()):
				if ((points[i] as Vector2) - (base_points[i] as Vector2)).length() > 1.4:
					return false
		return true

	func _on_padlock_gui_input(event: InputEvent) -> void:
		var pointer_position := _event_local_position(event)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				pressing_lock = true
				dragging_lock = false
				press_position = pointer_position
				drag_start_lock_offset = lock_offset
				physics_active = true
				accept_event()
			elif pressing_lock and not event.pressed:
				if not dragging_lock:
					padlock_clicked.emit()
					_click_rattle_lock()
				pressing_lock = false
				dragging_lock = false
				physics_active = true
				accept_event()
		elif event is InputEventMouseMotion and pressing_lock:
			if dragging_lock or pointer_position.distance_to(press_position) >= LOCK_DRAG_DEADZONE:
				var started_dragging := not dragging_lock
				dragging_lock = true
				physics_active = true
				if started_dragging:
					last_chain_sound_offset = lock_offset
					_emit_chain_moved_if_ready(true)
				accept_event()
		elif event is InputEventScreenTouch:
			if event.pressed:
				pressing_lock = true
				dragging_lock = false
				press_position = pointer_position
				drag_start_lock_offset = lock_offset
				physics_active = true
				accept_event()
			elif pressing_lock and not event.pressed:
				if not dragging_lock:
					padlock_clicked.emit()
					_click_rattle_lock()
				pressing_lock = false
				dragging_lock = false
				physics_active = true
				accept_event()
		elif event is InputEventScreenDrag and pressing_lock:
			if dragging_lock or pointer_position.distance_to(press_position) >= LOCK_DRAG_DEADZONE:
				var started_dragging := not dragging_lock
				dragging_lock = true
				physics_active = true
				if started_dragging:
					last_chain_sound_offset = lock_offset
					_emit_chain_moved_if_ready(true)
				accept_event()

	func _emit_chain_moved_if_ready(force := false) -> void:
		var now := Time.get_ticks_msec()
		if not force and now - last_chain_sound_msec < CHAIN_SFX_COOLDOWN_MSEC:
			return
		if not force and lock_offset.distance_to(last_chain_sound_offset) < CHAIN_SFX_MOVE_DISTANCE:
			return
		last_chain_sound_msec = now
		last_chain_sound_offset = lock_offset
		chain_moved.emit()

	func _click_rattle_lock() -> void:
		click_shake_remaining = LOCK_CLICK_SHAKE_SECONDS
		click_shake_direction = -1.0 if rng.randf() < 0.5 else 1.0
		lock_velocity += Vector2(220.0 * click_shake_direction, rng.randf_range(-60.0, 70.0))
		_pull_chains_from_lock(Vector2(1.0 * click_shake_direction, 0.18), 44.0)
		_emit_chain_moved_if_ready(true)
		physics_active = true

	func _pull_chains_from_lock(direction: Vector2, force: float) -> void:
		var pull := direction.normalized()
		for side in [-1, 1]:
			var points := chain_points[side] as Array
			var previous := chain_prev_points[side] as Array
			if points.is_empty():
				continue
			for i in range(1, points.size()):
				var t := float(i) / float(points.size() - 1)
				var weight := t * t
				var local_pull := pull * force * weight + Vector2(float(side) * 12.0, rng.randf_range(-8.0, 8.0)) * weight
				previous[i] = (previous[i] as Vector2) - local_pull
			chain_prev_points[side] = previous

	func _padlock_contains_local_point(point: Vector2) -> bool:
		if padlock == null:
			return false
		return Rect2(padlock.position, padlock.size).has_point(point)

	func _rattle_lock() -> void:
		lock_velocity += Vector2(rng.randf_range(-260.0, 260.0), rng.randf_range(-70.0, 110.0))
		for side in [-1, 1]:
			var points := chain_points[side] as Array
			var previous := chain_prev_points[side] as Array
			for i in range(1, points.size()):
				var impulse := Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-8.0, 12.0)) * float(i)
				previous[i] = (previous[i] as Vector2) - impulse
			chain_prev_points[side] = previous
		physics_active = true

	func _draw() -> void:
		var render_links := _chain_render_links()
		_draw_interlocked_chain(render_links, 0)

	func _chain_path_points() -> Array:
		var left_points := chain_points[-1] as Array
		var right_points := chain_points[1] as Array
		var points := []
		if left_points.is_empty() or right_points.is_empty():
			return points
		for point in left_points:
			points.append(point)
		var left_anchor := left_points[left_points.size() - 1] as Vector2
		var right_anchor := right_points[right_points.size() - 1] as Vector2
		var hidden_dip := maxf(left_anchor.y, right_anchor.y) + size.y * 0.018
		for i in range(CENTER_CHAIN_LINKS):
			var t := float(i + 1) / float(CENTER_CHAIN_LINKS + 1)
			var point := left_anchor.lerp(right_anchor, t)
			point.y = lerpf(point.y, hidden_dip, sin(t * PI))
			points.append(point)
		for i in range(right_points.size() - 1, -1, -1):
			points.append(right_points[i])
		return points

	func _chain_render_links() -> Array:
		var points := _chain_path_points()
		var render_links := []
		for i in range(points.size()):
			var previous_index := maxi(i - 1, 0)
			var next_index := mini(i + 1, points.size() - 1)
			var previous_point := points[previous_index] as Vector2
			var next_point := points[next_index] as Vector2
			var tangent := next_point - previous_point
			var rotation := clampf(atan2(tangent.y, maxf(tangent.x, 1.0)), -0.45, 0.45)
			var weave := -1.0 if i % 2 == 0 else 1.0
			rotation += weave * 0.035
			render_links.append({
				"center": points[i] as Vector2,
				"rotation": rotation,
				"size": LINK_SIZE,
				"index": i,
				"front_side": 1 if i % 2 == 0 else -1
			})
		return render_links

	func _draw_interlocked_chain(render_links: Array, index := 0) -> void:
		if index >= render_links.size():
			return
		var link := render_links[index] as Dictionary
		_draw_link_half(link, false, _link_front_side(link))
		_draw_interlocked_chain(render_links, index + 1)
		_draw_link_half(link, true, _link_front_side(link))

	func _link_front_side(link: Dictionary) -> int:
		return int(link.get("front_side", 1))

	func _draw_link_half(link: Dictionary, front: bool, front_side := 1, fill_override := Color.TRANSPARENT, draw_detail := true) -> void:
		if link_texture != null:
			_draw_textured_link_half(link, front, front_side, fill_override)
			return
		var center := link["center"] as Vector2
		var rotation := float(link["rotation"])
		var link_size := link["size"] as Vector2
		var rx := link_size.x * 0.5
		var ry := link_size.y * 0.5
		var metal := link_size.y * 0.30
		var inner_rx := rx - metal
		var inner_ry := ry - metal
		var draw_right_side := front == (front_side > 0)
		var start_angle := -PI * 0.5 if draw_right_side else PI * 0.5
		var end_angle := PI * 0.5 if draw_right_side else PI * 1.5
		var outer := _ellipse_points(center, rotation, rx, ry, start_angle, end_angle, 18)
		var inner := _ellipse_points(center, rotation, inner_rx, inner_ry, end_angle, start_angle, 18)
		var polygon := PackedVector2Array()
		for point in outer:
			polygon.append(point)
		for point in inner:
			polygon.append(point)
		var fill := fill_override if fill_override.a > 0.0 else Color("#d99b35")
		draw_colored_polygon(polygon, fill)

	func _draw_textured_link_half(link: Dictionary, front: bool, front_side := 1, fill_override := Color.TRANSPARENT) -> void:
		var center := link["center"] as Vector2
		var rotation := float(link["rotation"])
		var link_size := link["size"] as Vector2
		var texture_size := link_texture.get_size()
		var half_width := texture_size.x * 0.5
		var draw_right_side := front == (front_side > 0)
		var source_x := half_width if draw_right_side else 0.0
		var dest_x := 0.0 if draw_right_side else -link_size.x * 0.5
		var tint := fill_override if fill_override.a > 0.0 else Color("#d99b35")
		draw_set_transform(center, rotation, Vector2.ONE)
		draw_texture_rect_region(
			link_texture,
			Rect2(Vector2(dest_x, -link_size.y * 0.5), Vector2(link_size.x * 0.5, link_size.y)),
			Rect2(Vector2(source_x, 0), Vector2(half_width, texture_size.y)),
			tint
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _ellipse_points(center: Vector2, rotation: float, rx: float, ry: float, start_angle: float, end_angle: float, steps: int) -> Array:
		var points := []
		var basis_x := Vector2(cos(rotation), sin(rotation))
		var basis_y := Vector2(-sin(rotation), cos(rotation))
		for step in range(steps + 1):
			var t := float(step) / float(steps)
			var angle := lerpf(start_angle, end_angle, t)
			var local := basis_x * (cos(angle) * rx) + basis_y * (sin(angle) * ry)
			points.append(center + local)
		return points

	func _place_padlock(offset: Vector2, rotation: float) -> void:
		var lock_position := base_lock_position + offset
		if padlock_shadow != null:
			padlock_shadow.size = PADLOCK_SIZE
			padlock_shadow.position = lock_position + Vector2(12, 16)
			padlock_shadow.pivot_offset = PADLOCK_SIZE * 0.5
			padlock_shadow.rotation = rotation
		if padlock != null:
			padlock.size = PADLOCK_SIZE
			padlock.position = lock_position
			padlock.pivot_offset = PADLOCK_SIZE * 0.5
			padlock.rotation = rotation
		if level_label != null:
			level_label.size = Vector2(240, 210)
			level_label.position = lock_position + Vector2(PADLOCK_SIZE.x * 0.5 - level_label.size.x * 0.5 - 15.0, PADLOCK_SIZE.y * 0.52)
			level_label.pivot_offset = level_label.size * 0.5
			level_label.rotation = rotation

	func _clear_children() -> void:
		for child in get_children():
			child.queue_free()


class MobileScrollContainer:
	extends ScrollContainer

	signal user_scroll_direction(direction: int)

	const DRAG_DEADZONE := 18.0
	const FLICK_SAMPLE_SECONDS := 0.14
	const FLICK_MIN_VELOCITY := 90.0
	const FLICK_MAX_VELOCITY := 4200.0
	const INERTIA_DECAY := 5.4
	const PULL_RESISTANCE_MAX := 210.0
	const PULL_SNAP_SECONDS := 0.34

	var drag_tracking := false
	var drag_scrolling := false
	var drag_start := Vector2.ZERO
	var drag_last := Vector2.ZERO
	var drag_touch_index := -1
	var drag_scroll_position := 0.0
	var drag_velocity_samples := []
	var velocity := 0.0
	var pull_resistance_enabled := false
	var pull_raw_offset := 0.0
	var pull_offset := 0.0
	var child_click_suppressed := false
	var scroll_tween: Tween
	var pull_tween: Tween

	func _ready() -> void:
		set_process(true)
		scroll_deadzone = int(DRAG_DEADZONE)

	func set_pull_resistance_enabled(enabled: bool) -> void:
		pull_resistance_enabled = enabled
		if not enabled:
			_set_pull_raw_offset(0.0)
			_cancel_pull_tween()

	func _input(event: InputEvent) -> void:
		if not is_visible_in_tree():
			return
		if _modal_blocks_this_scroll():
			drag_tracking = false
			drag_scrolling = false
			velocity = 0.0
			_cancel_scroll_tween()
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _contains_global_point(event.global_position):
					_cancel_scroll_tween()
					_cancel_pull_tween()
					drag_tracking = true
					drag_scrolling = false
					drag_start = event.global_position
					drag_last = event.global_position
					drag_touch_index = -1
					drag_scroll_position = float(scroll_vertical)
					_reset_drag_velocity_samples(event.global_position)
					velocity = 0.0
			elif drag_tracking:
				if drag_scrolling:
					child_click_suppressed = true
					_apply_release_velocity(event.global_position)
					get_viewport().set_input_as_handled()
				drag_tracking = false
				drag_scrolling = false
				drag_touch_index = -1
				_snap_pull_offset()
				if child_click_suppressed:
					call_deferred("_clear_child_click_suppression")
			elif child_click_suppressed:
				call_deferred("_clear_child_click_suppression")
			return
		if event is InputEventMouseMotion and drag_tracking:
			var distance: float = event.global_position.distance_to(drag_start)
			var drag_offset: Vector2 = event.global_position - drag_start
			if distance >= DRAG_DEADZONE and absf(drag_offset.y) > absf(drag_offset.x) * 1.15:
				drag_scrolling = true
			if drag_scrolling:
				child_click_suppressed = true
				var delta_y: float = event.global_position.y - drag_last.y
				_apply_drag_delta(delta_y)
				drag_last = event.global_position
				_record_drag_velocity_sample(event.global_position)
				get_viewport().set_input_as_handled()
		if event is InputEventScreenTouch:
			if event.pressed:
				if _contains_global_point(event.position):
					_cancel_scroll_tween()
					_cancel_pull_tween()
					drag_tracking = true
					drag_scrolling = false
					drag_start = event.position
					drag_last = event.position
					drag_touch_index = event.index
					drag_scroll_position = float(scroll_vertical)
					_reset_drag_velocity_samples(event.position)
					velocity = 0.0
			elif drag_tracking and event.index == drag_touch_index:
				if drag_scrolling:
					child_click_suppressed = true
					_apply_release_velocity(event.position)
					get_viewport().set_input_as_handled()
				drag_tracking = false
				drag_scrolling = false
				drag_touch_index = -1
				_snap_pull_offset()
				if child_click_suppressed:
					call_deferred("_clear_child_click_suppression")
			elif child_click_suppressed:
				call_deferred("_clear_child_click_suppression")
			return
		if event is InputEventScreenDrag and drag_tracking and event.index == drag_touch_index:
			var distance: float = event.position.distance_to(drag_start)
			var drag_offset: Vector2 = event.position - drag_start
			if distance >= DRAG_DEADZONE and absf(drag_offset.y) > absf(drag_offset.x) * 1.15:
				drag_scrolling = true
			if drag_scrolling:
				child_click_suppressed = true
				var delta_y: float = event.position.y - drag_last.y
				_apply_drag_delta(delta_y)
				drag_last = event.position
				_record_drag_velocity_sample(event.position)
				get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and event.pressed and _contains_global_point(event.global_position):
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				user_scroll_direction.emit(1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				user_scroll_direction.emit(-1)

	func _process(delta: float) -> void:
		if _modal_blocks_this_scroll():
			velocity = 0.0
			return
		if drag_tracking or absf(pull_offset) > 0.0 or absf(velocity) < 4.0:
			return
		var old_scroll := drag_scroll_position
		_set_scroll_vertical_float(drag_scroll_position + velocity * delta)
		_emit_user_scroll_direction_from_delta(drag_scroll_position - old_scroll)
		velocity = lerpf(velocity, 0.0, 1.0 - exp(-INERTIA_DECAY * delta))

	func _apply_drag_delta(delta_y: float) -> void:
		if pull_resistance_enabled:
			if absf(pull_raw_offset) > 0.0:
				var next_pull_raw_offset := pull_raw_offset + delta_y
				if pull_raw_offset > 0.0 and next_pull_raw_offset < 0.0:
					next_pull_raw_offset = 0.0
				elif pull_raw_offset < 0.0 and next_pull_raw_offset > 0.0:
					next_pull_raw_offset = 0.0
				_set_pull_raw_offset(next_pull_raw_offset)
				velocity = 0.0
				return
			var max_scroll := float(get_max_scroll_vertical())
			var requested_scroll := drag_scroll_position - delta_y
			if requested_scroll < 0.0:
				_set_scroll_vertical_float(0.0)
				_set_pull_raw_offset(-requested_scroll)
				velocity = 0.0
				return
			if requested_scroll > max_scroll:
				_set_scroll_vertical_float(max_scroll)
				_set_pull_raw_offset(max_scroll - requested_scroll)
				velocity = 0.0
				return
		var old_scroll := drag_scroll_position
		_set_scroll_vertical_float(drag_scroll_position - delta_y)
		_emit_user_scroll_direction_from_delta(drag_scroll_position - old_scroll)
		velocity = -delta_y * 60.0

	func _set_scroll_vertical_float(next_value: float) -> void:
		drag_scroll_position = clampf(next_value, 0.0, float(get_max_scroll_vertical()))
		scroll_vertical = int(round(drag_scroll_position))

	func _contains_global_point(point: Vector2) -> bool:
		return Rect2(global_position, size).has_point(point)

	func _reset_drag_velocity_samples(position: Vector2) -> void:
		drag_velocity_samples.clear()
		_record_drag_velocity_sample(position)

	func _record_drag_velocity_sample(position: Vector2) -> void:
		var now := Time.get_ticks_msec() / 1000.0
		drag_velocity_samples.append({"position": position, "time": now})
		while drag_velocity_samples.size() > 2 and now - float(drag_velocity_samples[0]["time"]) > FLICK_SAMPLE_SECONDS:
			drag_velocity_samples.pop_front()

	func _apply_release_velocity(position: Vector2) -> void:
		if absf(pull_raw_offset) > 0.0 or drag_velocity_samples.is_empty():
			velocity = 0.0
			return
		_record_drag_velocity_sample(position)
		var newest: Dictionary = drag_velocity_samples[drag_velocity_samples.size() - 1]
		var oldest: Dictionary = drag_velocity_samples[0]
		var elapsed := float(newest["time"]) - float(oldest["time"])
		if elapsed <= 0.0:
			return
		var delta_y := (newest["position"] as Vector2).y - (oldest["position"] as Vector2).y
		var release_velocity := clampf(-delta_y / elapsed, -FLICK_MAX_VELOCITY, FLICK_MAX_VELOCITY)
		velocity = release_velocity if absf(release_velocity) >= FLICK_MIN_VELOCITY else 0.0

	func _modal_blocks_this_scroll() -> bool:
		var tree := get_tree()
		if tree == null:
			return false
		for node in tree.get_nodes_in_group("modal_overlay"):
			var modal := node as Control
			if modal != null and modal.visible and modal.is_visible_in_tree() and not _is_descendant_of(modal):
				return true
		return false

	func _is_descendant_of(node: Node) -> bool:
		var current: Node = self
		while current != null:
			if current == node:
				return true
			current = current.get_parent()
		return false

	func get_max_scroll_vertical() -> int:
		var scroll_bar := get_v_scroll_bar()
		if scroll_bar != null:
			return maxi(0, int(ceil(scroll_bar.max_value - scroll_bar.page)))
		var max_scroll: float = 0.0
		for child in get_children():
			if child is Control:
				var control := child as Control
				max_scroll = maxf(max_scroll, control.position.y + control.size.y)
		return maxi(0, int(ceil(max_scroll - size.y)))

	func scroll_to_vertical(target: int, duration := 0.26) -> void:
		_cancel_scroll_tween()
		velocity = 0.0
		var clamped_target := clampi(target, 0, get_max_scroll_vertical())
		if duration <= 0.0:
			drag_scroll_position = float(clamped_target)
			scroll_vertical = clamped_target
			return
		scroll_tween = create_tween()
		scroll_tween.tween_property(self, "scroll_vertical", clamped_target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		scroll_tween.finished.connect(func():
			drag_scroll_position = float(scroll_vertical)
			scroll_tween = null
		)

	func is_child_click_suppressed() -> bool:
		return child_click_suppressed or drag_scrolling or absf(velocity) >= 4.0

	func _clear_child_click_suppression() -> void:
		child_click_suppressed = false

	func _cancel_scroll_tween() -> void:
		if scroll_tween != null and scroll_tween.is_valid():
			scroll_tween.kill()
			drag_scroll_position = float(scroll_vertical)
		scroll_tween = null

	func _emit_user_scroll_direction_from_delta(delta: float) -> void:
		if absf(delta) < 0.5:
			return
		user_scroll_direction.emit(1 if delta > 0.0 else -1)

	func _set_pull_raw_offset(next_raw_offset: float) -> void:
		pull_raw_offset = next_raw_offset
		var direction := signf(pull_raw_offset)
		pull_offset = direction * PULL_RESISTANCE_MAX * (1.0 - exp(-absf(pull_raw_offset) / PULL_RESISTANCE_MAX))
		position.y = pull_offset

	func _snap_pull_offset() -> void:
		if not pull_resistance_enabled and absf(pull_offset) <= 0.0:
			pull_raw_offset = 0.0
			pull_offset = 0.0
			return
		if absf(pull_offset) <= 0.0:
			_set_pull_raw_offset(0.0)
			return
		_cancel_pull_tween()
		velocity = 0.0
		pull_raw_offset = 0.0
		pull_tween = create_tween()
		pull_tween.tween_property(self, "position:y", 0.0, PULL_SNAP_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		pull_tween.finished.connect(func():
			pull_offset = 0.0
			pull_raw_offset = 0.0
			pull_tween = null
		)

	func _cancel_pull_tween() -> void:
		if pull_tween != null and pull_tween.is_valid():
			pull_tween.kill()
			pull_offset = position.y
			var pull_pct := clampf(absf(pull_offset) / PULL_RESISTANCE_MAX, 0.0, 0.98)
			pull_raw_offset = signf(pull_offset) * -PULL_RESISTANCE_MAX * log(1.0 - pull_pct)
		pull_tween = null


const SAVE_PATH := "user://idle_elite_save.json"
const ACTIVITY_DATABASE_PATH := "res://docs/activity-database.json"
const MASTERY_MEDALS_TEXTURE := "res://docs/assets/ui/mastery-medals-20.png"
const UNLOCK_LOCK_CHAINS_TEXTURE := "res://docs/assets/ui/unlock-lock-chains.png"
const UNLOCK_CHAIN_LINK_TEXTURE := "res://docs/assets/ui/unlock-chain-link.png"
const UNLOCK_CHAIN_LEFT_TEXTURE := "res://docs/assets/ui/unlock-chain-left.png"
const UNLOCK_CHAIN_RIGHT_TEXTURE := "res://docs/assets/ui/unlock-chain-right.png"
const UNLOCK_PADLOCK_TEXTURE := "res://docs/assets/ui/unlock-padlock.png"
const ACHIEVEMENT_TOTAL_LEVEL_ART := "res://docs/assets/achievements/achievement-total-level.png"
const ACHIEVEMENT_CREDIT_ART := "res://docs/assets/achievements/achievement-credit.png"
const ACHIEVEMENT_CUMULATIVE_MEDALS_ART := "res://docs/assets/achievements/achievement-cumulative-medals.png"
const BASE_MAX_STAMINA := 30
const STAMINA_REGEN_SECONDS := 12.0
const STAMINA_GAUGE_REGEN_BOOST_MULT := 2.0
const STAMINA_GAUGE_REGEN_EASE_SPEED := 7.5
const STAMINA_GAUGE_POP_SCALE := Vector2(1.018, 1.018)
const STAMINA_GAUGE_SETTLE_SCALE := Vector2(0.997, 0.997)
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const MASTERY_MAX_LEVEL := 10
const ACHIEVEMENT_MEDAL_ART_COUNT := 20
const ACHIEVEMENT_MEDAL_SLOT_COUNT := 25
const ACHIEVEMENT_MEDAL_SLOT_SIZE := Vector2(62, 62)
const ACHIEVEMENT_MEDAL_SLOT_STEP := 36.0
const TOTAL_LEVEL_ACHIEVEMENT_TARGETS := [25, 50, 100, 150, 250, 375, 495]
const TIER_COUNT_ACHIEVEMENT_STEP := 5
const MASTERY_MEDAL_NAMES := [
	"Bronze",
	"Silver",
	"Gold",
	"Platinum",
	"Sapphire",
	"Emerald",
	"Ruby",
	"Diamond",
	"Demonic",
	"Heavenly"
]
const MASTERY_MEDAL_ACCENTS := [
	Color("#b77938"),
	Color("#a9adb7"),
	Color("#f4bf35"),
	Color("#a7d6e8"),
	Color("#3aa0ff"),
	Color("#35d86d"),
	Color("#e84d4d"),
	Color("#8fdcff"),
	Color("#9b54ff"),
	Color("#fff2a8")
]
const GLOBAL_MEDAL_BUFFS := [
	{"level": 1, "stat": "max_stamina", "amount": 1.0},
	{"level": 2, "stat": "xp_mult", "amount": 0.02},
	{"level": 3, "stat": "speed_mult", "amount": 0.02},
	{"level": 4, "stat": "success_bonus", "amount": 1.0},
	{"level": 5, "stat": "max_stamina", "amount": 1.0},
	{"level": 6, "stat": "xp_mult", "amount": 0.03},
	{"level": 7, "stat": "speed_mult", "amount": 0.03},
	{"level": 8, "stat": "success_bonus", "amount": 1.0},
	{"level": 9, "stat": "max_stamina", "amount": 2.0},
	{"level": 10, "stat": "xp_mult", "amount": 0.05}
]
const BASE_CANVAS := Vector2(2160, 3840)
const BOTTOM_NAV_HEIGHT := 420
const BOTTOM_NAV_SAFE_PAD := 96
const PAGE_PAD := 96
const CARD_RADIUS := 64
const ACTION_CARD_HEIGHT := 720
const ACTION_CARD_POP_GUTTER := 44
const SKILL_MENU_CARD_SIDE_INSET := 130
const SKILL_MENU_COPY_WIDTH := 660
const SKILL_SWIPE_THRESHOLD := 230.0
const SKILL_SWIPE_FEEDBACK_DEADZONE := 46.0
const SKILL_SWIPE_MAX_DRAG := 1120.0
const SKILL_SWIPE_PAGE_GAP := 82.0
const SKILL_SWIPE_SETTLE_SECONDS := 0.46
const SKILL_SWIPE_CANCEL_SECONDS := 0.22
const ACTIVITY_JUMP_TOP_TEXTURE := "res://docs/assets/ui/jump-top-circle.png"
const ACTIVITY_JUMP_BOTTOM_TEXTURE := "res://docs/assets/ui/jump-bottom-circle.png"
const ACTIVITY_JUMP_ARROW_SIZE := Vector2(296, 296)
const ACTIVITY_JUMP_ARROW_EDGE_INSET := 28.0
const ACTIVITY_JUMP_ARROW_LINGER_SECONDS := 1.2
const ACTIVITY_JUMP_ARROW_FADE_IN_SECONDS := 0.10
const ACTIVITY_JUMP_ARROW_FADE_OUT_SECONDS := 0.22
const ACTIVITY_JUMP_ARROW_EDGE_EPSILON := 6
const AD_BONUS_SECONDS := 2 * 60 * 60
const AD_BONUS_WARN_THRESHOLD_SECONDS := 4 * 60 * 60
const AD_BONUS_MAX_SECONDS := 6 * 60 * 60
const AD_BONUS_XP_MULT := 0.10
const AD_BONUS_SPEED_MULT := 0.10
const ACTIVITY_STREAK_BONUS_STEP := 5
const ACTIVITY_SUCCESS_SFX_PATHS := [
	"res://assets/sfx/action_success_glass_pip_1.wav",
	"res://assets/sfx/action_success_glass_pip_2.wav",
	"res://assets/sfx/action_success_glass_pip_3.wav",
	"res://assets/sfx/action_success_glass_pip_4.wav",
]
const CHAIN_MOVE_SFX_PATHS := [
	"res://assets/sfx/chain_move_soft_links.wav",
	"res://assets/sfx/chain_move_low_rattle.wav",
	"res://assets/sfx/chain_move_bright_safe.wav",
	"res://assets/sfx/chain_move_distant_chain.wav",
	"res://assets/sfx/chain_move_tight_ui.wav",
]
const CHAIN_JINGLE_SFX_PATH := "res://assets/sfx/Jingle Chains.wav"
const PADLOCK_CLUSTER_SFX_PATH := "res://assets/sfx/padlock_cluster.wav"
const ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS := 4.92
const ACTIVITY_UNLOCK_CHAIN_FADE_SECONDS := 2.04
const ACTIVITY_UNLOCK_CHAIN_FADE_DELAY := 2.76
const ACTIVITY_BONUS_JINGLE_DELAY := 0.08
const AD_TEST_UNIT_ANDROID_REWARDED := "ca-app-pub-3940256099942544/5224354917"
const AD_LIVE_UNIT_ANDROID_REWARDED := "ca-app-pub-3570919669688101/7376748559"
const MODAL_OVERLAY_Z := 4096
const TARGET_FRAME_RATE := 120
const ACHIEVEMENTS_MODAL_SIZE := Vector2(1760, 3000)
const ACHIEVEMENTS_MODAL_VIEWPORT_MARGIN := Vector2(64, 80)
const ACHIEVEMENTS_MODAL_SCROLL_HEIGHT := 2220.0
const ACHIEVEMENT_TOAST_SIZE := Vector2(1500, 360)
const ACHIEVEMENT_TOAST_GAP := 28.0
const ACHIEVEMENT_TOAST_VIEWPORT_MARGIN := Vector2(36, 36)
const ACHIEVEMENT_TOAST_EXIT_DELAY := 4.0
const GLOBAL_BUFFS_MODAL_MIN_HEIGHT := 1440.0
const GLOBAL_BUFFS_MODAL_BASE_HEIGHT := 1260.0
const GLOBAL_BUFFS_MODAL_ROW_HEIGHT := 120.0
const GLOBAL_BUFFS_MODAL_MAX_HEIGHT := 2740.0
const GLOBAL_BUFFS_MODAL_SCROLL_CHROME := 760.0
const ACTION_PROGRESS_RAIL_INSET := 16
const BUTTON_BORDER := 22
const SECONDARY_BUTTON_BORDER := 18
const PASSIVE_BORDER := 0

const COLOR_INK := Color("#171615")
const COLOR_PAPER := Color("#f8f1e5")
const COLOR_PANEL := Color("#fffdf8")
const COLOR_LINE := Color("#d9cfbc")
const COLOR_MUTED := Color("#6e6658")
const COLOR_GOLD := Color("#fff2a8")
const COLOR_GREEN := Color("#35d86d")
const COLOR_BLUE := Color("#3aa0ff")
const COLOR_NAV := Color("#444a5b")
const COLOR_RED := Color("#e84d4d")
const SKILL_THEME_COLORS := {
	"fight": Color("#e84d4d"),
	"thieving": Color("#8956bc"),
	"build": Color("#237cd5"),
	"woodcutting": Color("#6ea937"),
	"fishing": Color("#2dc0b9")
}

const SKILL_DEFS := [
	{"id": "fight", "name": "Fight", "verb": "Fighting", "time_scale": 0.88, "xp_scale": 1.00, "success_start": 95.0},
	{"id": "thieving", "name": "Thieving", "verb": "Sneaking", "time_scale": 0.72, "xp_scale": 1.00, "success_start": 96.0},
	{"id": "build", "name": "Build", "verb": "Building", "time_scale": 1.28, "xp_scale": 1.00, "success_start": 86.0},
	{"id": "woodcutting", "name": "Woodcutting", "verb": "Chopping", "time_scale": 1.08, "xp_scale": 1.00, "success_start": 90.0},
	{"id": "fishing", "name": "Fishing", "verb": "Fishing", "time_scale": 1.58, "xp_scale": 1.72, "success_start": 90.0},
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
var skill_defs := []
var actions_by_skill := {}
var selected_skill_id := "fight"
var current_screen := "home"
var running_skill_id := ""
var running_action_id := ""
var action_progress := 0.0
var activity_streak_action_key := ""
var activity_streak_count := 0
var mastery := {}
var stamina := {}
var stamina_bank := {}
var stamina_gauge_regen_multiplier := 1.0
var stamina_gauge_regen_target_multiplier := 1.0
var stamina_gauge_boost_skill_id := ""
var stamina_gauge_press_active := false
var ad_bonus_seconds_remaining := 0.0
var rewarded_ad: RewardedAd
var ad_reward_listener := OnUserEarnedRewardListener.new()
var ad_load_callback := RewardedAdLoadCallback.new()
var ad_content_callback := FullScreenContentCallback.new()
var ad_loading := false
var ad_showing := false
var ad_show_after_load := false
var ad_reward_earned_for_show := false
var last_result := "Pick a skill and start training."
var is_muted := false

var app_font: Font
var app_bold_font: Font
var mastery_medal_textures := {}
var mastery_medal_silhouette_textures := {}
var mastery_medal_dot_texture: Texture2D
var home_page: Control
var skills_page: Control
var nav_bar: PanelContainer
var content_scroll: ScrollContainer
var skills_content: Control
var home_total_label: Label
var home_skill_labels := {}
var hero_message: Label
var achievement_total_label: Label
var achievement_elite_label: Label
var achievement_total_bar: CleanProgressBar
var achievement_buff_label: Label
var achievement_total_level_label: Label
var achievement_best_art_frame: PanelContainer
var achievement_best_art: TextureRect
var achievement_best_name_label: Label
var achievement_best_medal: TextureRect
var achievement_skill_count_labels := {}
var achievement_skill_bars := {}
var achievement_skill_level_labels := {}
var achievement_skill_tier_name_labels := {}
var achievement_skill_tier_count_labels := {}
var achievement_skill_tier_bars := {}
var achievement_medal_slot_panels := {}
var achievement_medal_slot_icons := {}
var skills_tab: Button
var hero_tab: Button
var shop_tab: Button
var settings_tab: Button
var shop_bonus_label: Label
var skill_cards := {}
var action_cards := {}
var action_pop_tweens := {}
var pending_activity_unlock_ceremony := {}
var activity_unlock_ceremony_count := 0
var activity_unlock_preview_after_ceremony_id := ""
var locked_activity_material: ShaderMaterial
var detail_xp_label: Label
var detail_xp_bar: CleanProgressBar
var detail_stamina_bar: CleanProgressBar
var detail_regen_circle: RegenCircle
var detail_actions_scroll: MobileScrollContainer
var detail_stamina_gauge_pop_tween: Tween
var detail_jump_top_button: TextureButton
var detail_jump_bottom_button: TextureButton
var detail_jump_top_hold := 0.0
var detail_jump_bottom_hold := 0.0
var detail_jump_top_hovered := false
var detail_jump_bottom_hovered := false
var detail_action_card_nodes := {}
var detail_rendered_action_ids := []
var skill_swipe_tracking := false
var skill_swipe_horizontal := false
var skill_swipe_start := Vector2.ZERO
var skill_swipe_last := Vector2.ZERO
var skill_swipe_touch_index := -1
var skill_swipe_tween: Tween
var skill_swipe_frame: Control
var skill_swipe_page: Control
var skill_swipe_preview_page: Control
var skill_swipe_preview_pages := {}
var skill_swipe_preview_states := {}
var skill_swipe_preview_offset := 0
var skill_swipe_animating := false
var skill_swipe_animation_mode := ""
var skill_swipe_drag_base_x := 0.0
var skill_swipe_child_click_suppressed := false
var skill_swipe_handoff_cover: Control
var settings_overlay: Control
var settings_panel: PanelContainer
var achievements_overlay: Control
var achievements_panel_frame: Control
var achievements_panel: PanelContainer
var achievements_scroll: ScrollContainer
var achievements_list_stack: VBoxContainer
var achievements_tab_buttons := {}
var achievements_hide_completed: CheckBox
var achievements_modal_tab := "achievements"
var achievement_toasts := []
var mute_button: Button
var click_player: AudioStreamPlayer
var success_players: Array[AudioStreamPlayer] = []
var failure_player: AudioStreamPlayer
var level_player: AudioStreamPlayer
var medal_player: AudioStreamPlayer
var bonus_jingle_player: AudioStreamPlayer
var bonus_jingle_echo_player: AudioStreamPlayer
var chain_move_players: Array[AudioStreamPlayer] = []
var chain_jingle_players: Array[AudioStreamPlayer] = []
var padlock_cluster_player: AudioStreamPlayer
var audio_unlocked_by_input := false
var max_stamina_cache_valid := false
var cached_max_stamina := BASE_MAX_STAMINA


func _ready() -> void:
	OS.low_processor_usage_mode = false
	OS.low_processor_usage_mode_sleep_usec = 0
	Engine.max_fps = TARGET_FRAME_RATE
	_load_font()
	_load_action_data()
	_init_state()
	_build_audio()
	_init_ads()
	_build_ui()
	load_game()
	_validate_state()
	_render_screen(current_screen == "skill")
	_update_ui(0.0, true)
	var timer := Timer.new()
	timer.wait_time = 10.0
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)


func _process(delta: float) -> void:
	_process_ad_bonus(delta)
	_process_stamina_gauge_regen_boost(delta)
	_regen_stamina(delta)
	_process_action(delta)
	_update_ui(delta)
	_process_detail_jump_arrows(delta)


func _input(event: InputEvent) -> void:
	_note_player_input(event)
	if _is_stamina_gauge_release_event(event):
		_set_stamina_gauge_pressed(false)
		get_viewport().set_input_as_handled()
		return
	var overlay_open := (settings_overlay != null and settings_overlay.visible) or (achievements_overlay != null and achievements_overlay.visible)
	if current_screen != "skill" or overlay_open:
		_cancel_skill_swipe_feedback()
		return
	if _route_activity_lock_input(event):
		_cancel_skill_swipe_feedback()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_interrupt_skill_swipe_animation_for_input()
			if skills_page != null and Rect2(skills_page.global_position, skills_page.size).has_point(event.global_position):
				skill_swipe_tracking = true
				skill_swipe_horizontal = false
				skill_swipe_start = event.global_position
				skill_swipe_last = event.global_position
				skill_swipe_drag_base_x = _current_skill_swipe_page_x()
				skill_swipe_touch_index = -1
		elif skill_swipe_tracking:
			_finish_skill_swipe(event.global_position)
		return
	if event is InputEventMouseMotion and skill_swipe_tracking:
		_update_skill_swipe_feedback(event.global_position)
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_interrupt_skill_swipe_animation_for_input()
			skill_swipe_tracking = true
			skill_swipe_horizontal = false
			skill_swipe_start = event.position
			skill_swipe_last = event.position
			skill_swipe_drag_base_x = _current_skill_swipe_page_x()
			skill_swipe_touch_index = event.index
		elif skill_swipe_tracking and event.index == skill_swipe_touch_index:
			_finish_skill_swipe(event.position)
		return
	if event is InputEventScreenDrag and skill_swipe_tracking and event.index == skill_swipe_touch_index:
		_update_skill_swipe_feedback(event.position)


func _route_activity_lock_input(event: InputEvent) -> bool:
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		var overlay := card.get("lock_overlay", {}) as Dictionary
		if overlay.is_empty():
			continue
		var overlay_root := overlay.get("root") as Control
		var rig := overlay.get("group") as ActivityLockRig
		if overlay_root == null or rig == null or not overlay_root.visible or not rig.visible:
			continue
		if rig.handle_pointer_event(event):
			return true
	return false


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
	skills_page.clip_contents = true
	add_child(skills_page)
	_build_skills_page()
	
	_build_nav_bar()
	_build_settings_overlay()
	_build_achievements_overlay()


func _build_home_page() -> void:
	achievement_skill_count_labels.clear()
	achievement_skill_bars.clear()
	achievement_skill_level_labels.clear()
	achievement_skill_tier_name_labels.clear()
	achievement_skill_tier_count_labels.clear()
	achievement_skill_tier_bars.clear()
	achievement_medal_slot_panels.clear()
	achievement_medal_slot_icons.clear()
	achievement_total_label = null
	achievement_elite_label = null
	achievement_total_bar = null
	achievement_buff_label = null
	achievement_total_level_label = null
	achievement_best_art_frame = null
	achievement_best_art = null
	achievement_best_name_label = null
	achievement_best_medal = null
	hero_message = null
	var scroll := MobileScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	home_page.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", PAGE_PAD)
	margin.add_theme_constant_override("margin_right", PAGE_PAD)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_bottom", BOTTOM_NAV_SAFE_PAD + 190)
	scroll.add_child(margin)
	
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	
	var logo := TextureRect.new()
	logo.texture = _texture("res://docs/assets/logo/idle-elite-logo-chroma.png")
	logo.custom_minimum_size = Vector2(0, 560)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.material = _chroma_material(Color("#00ff00"))
	stack.add_child(logo)

	stack.add_child(_build_elite_summary())
	
	var hero_panel := PanelContainer.new()
	hero_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_panel.add_theme_stylebox_override("panel", _panel_style(Color(1, 0.96, 0.78, 0.35), 0, 0))
	stack.add_child(hero_panel)
	_build_achievements(hero_panel)


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
	for def in skill_defs:
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


func _build_elite_summary() -> Control:
	var row := VBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var copy := VBoxContainer.new()
	copy.custom_minimum_size = Vector2(660, 0)
	copy.add_theme_constant_override("separation", 12)
	row.add_child(copy)
	achievement_elite_label = _label("", 112, Color("#f4bf35"), HORIZONTAL_ALIGNMENT_CENTER)
	achievement_elite_label.add_theme_color_override("font_outline_color", COLOR_INK)
	achievement_elite_label.add_theme_constant_override("outline_size", 18)
	copy.add_child(achievement_elite_label)
	achievement_total_bar = _progress(Color("#f4bf35"), 58)
	copy.add_child(achievement_total_bar)
	return row


func _build_achievements(parent: PanelContainer) -> void:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 120)
	parent.add_child(margin)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 30)
	margin.add_child(stack)

	var achievements_button := Button.new()
	achievements_button.text = ""
	achievements_button.custom_minimum_size = Vector2(1680, 210)
	achievements_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	achievements_button.focus_mode = Control.FOCUS_NONE
	achievements_button.add_theme_stylebox_override("normal", _button_style(Color("#fffdf8"), BUTTON_BORDER, 42, 28))
	achievements_button.add_theme_stylebox_override("hover", _button_style(COLOR_GOLD, BUTTON_BORDER, 42, 28))
	achievements_button.add_theme_stylebox_override("pressed", _button_style(COLOR_GOLD.darkened(0.08), BUTTON_BORDER, 42, 28))
	achievements_button.pressed.connect(_open_achievements_overlay)
	stack.add_child(achievements_button)
	var achievement_button_margin := MarginContainer.new()
	achievement_button_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievement_button_margin.add_theme_constant_override("margin_left", 38)
	achievement_button_margin.add_theme_constant_override("margin_right", 38)
	achievement_button_margin.add_theme_constant_override("margin_top", 20)
	achievement_button_margin.add_theme_constant_override("margin_bottom", 20)
	achievement_button_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievements_button.add_child(achievement_button_margin)
	var achievement_title_row := HBoxContainer.new()
	achievement_title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	achievement_title_row.add_theme_constant_override("separation", 28)
	achievement_title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	achievement_button_margin.add_child(achievement_title_row)
	achievement_title_row.add_child(_image("res://docs/assets/ui/motivation-star.png", Vector2(100, 100)))
	achievement_title_row.add_child(_label("Achievements", 104, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))

	var best_card := PanelContainer.new()
	best_card.custom_minimum_size = Vector2(1680, 290)
	best_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	best_card.add_theme_stylebox_override("panel", _achievement_card_style(Color("#fffdf8"), 42, 26))
	stack.add_child(best_card)
	var best_margin := MarginContainer.new()
	best_margin.add_theme_constant_override("margin_left", 34)
	best_margin.add_theme_constant_override("margin_right", 34)
	best_margin.add_theme_constant_override("margin_top", 22)
	best_margin.add_theme_constant_override("margin_bottom", 22)
	best_card.add_child(best_margin)
	var best_copy := VBoxContainer.new()
	best_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	best_copy.add_theme_constant_override("separation", 10)
	best_margin.add_child(best_copy)
	best_copy.add_child(_label("Most impressive activity:", 52, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var best_row := HBoxContainer.new()
	best_row.alignment = BoxContainer.ALIGNMENT_CENTER
	best_row.add_theme_constant_override("separation", 18)
	best_copy.add_child(best_row)
	achievement_best_art_frame = PanelContainer.new()
	achievement_best_art_frame.custom_minimum_size = Vector2(174, 174)
	achievement_best_art_frame.add_theme_stylebox_override("panel", _featured_activity_art_style())
	best_row.add_child(achievement_best_art_frame)
	achievement_best_art = _image("", Vector2(146, 146))
	achievement_best_art_frame.add_child(achievement_best_art)
	achievement_best_name_label = _label("Earn a medal to feature an activity", 66, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	achievement_best_name_label.custom_minimum_size = Vector2(610, 0)
	achievement_best_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	best_row.add_child(achievement_best_name_label)
	achievement_best_medal = _image_from_texture(null, Vector2(140, 140))
	best_row.add_child(achievement_best_medal)

	var total_margin := MarginContainer.new()
	total_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_margin.add_theme_constant_override("margin_top", 42)
	stack.add_child(total_margin)
	var total_section := HBoxContainer.new()
	total_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_section.alignment = BoxContainer.ALIGNMENT_CENTER
	total_section.add_theme_constant_override("separation", 40)
	total_margin.add_child(total_section)
	total_section.add_child(_image("res://docs/assets/ui/total-lv-bargraph.png", Vector2(210, 210)))
	achievement_total_level_label = _label("", 122, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	total_section.add_child(achievement_total_level_label)

	for def in skill_defs:
		var skill_id := str(def["id"])
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 470)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _achievement_card_style(COLOR_PANEL, 46, 38))
		stack.add_child(card)

		var skill_stack := VBoxContainer.new()
		skill_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skill_stack.add_theme_constant_override("separation", 22)
		card.add_child(skill_stack)

		var header := HBoxContainer.new()
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.alignment = BoxContainer.ALIGNMENT_CENTER
		header.add_theme_constant_override("separation", 34)
		skill_stack.add_child(header)
		var icon := _image("res://docs/assets/icons/%s.png" % skill_id, Vector2(178, 178))
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(icon)

		var level_label := _label("", 112, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		level_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		header.add_child(level_label)
		achievement_skill_level_labels[skill_id] = level_label

		var actions: Array = actions_by_skill.get(skill_id, [])
		var slot_strip := _achievement_medal_slot_strip(skill_id, actions)
		skill_stack.add_child(slot_strip["root"])
		achievement_skill_tier_name_labels[skill_id] = []
		achievement_skill_tier_count_labels[skill_id] = []
		achievement_medal_slot_panels[skill_id] = [slot_strip["panels"]]
		achievement_medal_slot_icons[skill_id] = [slot_strip["icons"]]

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 70)
	stack.add_child(bottom_spacer)


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
	var settings := _icon_button("res://docs/assets/ui/settings-gear-simple.png")
	settings.pressed.connect(_open_settings)
	tools.add_child(settings)
	var discord := _icon_button("res://docs/assets/ui/discord-simple.png")
	discord.pressed.connect(func(): _set_result("Discord button tapped."))
	tools.add_child(discord)


func _build_skills_page() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
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
	row.add_theme_constant_override("separation", 160)
	row.clip_contents = true
	row.custom_minimum_size = Vector2(0, BOTTOM_NAV_HEIGHT - BOTTOM_NAV_SAFE_PAD)
	nav_bar.add_child(row)
	skills_tab = _nav_button("res://docs/assets/ui/total-lv-bargraph.png")
	skills_tab.pressed.connect(_show_skills)
	row.add_child(skills_tab)
	hero_tab = _nav_button("res://docs/assets/ui/motivation-star.png")
	hero_tab.pressed.connect(_show_home)
	row.add_child(hero_tab)
	settings_tab = _nav_button("res://docs/assets/ui/settings-gear-simple.png")
	settings_tab.pressed.connect(_show_settings)
	row.add_child(settings_tab)
	shop_tab = _nav_button("res://docs/assets/ui/shop.png")
	shop_tab.pressed.connect(_show_shop)
	row.add_child(shop_tab)


func _build_settings_overlay() -> void:
	settings_overlay = ColorRect.new()
	settings_overlay.color = Color(0, 0, 0, 0.34)
	settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.z_index = MODAL_OVERLAY_Z
	settings_overlay.z_as_relative = false
	settings_overlay.visible = false
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_overlay.add_to_group("modal_overlay")
	settings_overlay.gui_input.connect(_on_settings_overlay_gui_input)
	add_child(settings_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	settings_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1300, 0)
	panel.add_theme_stylebox_override("panel", _surface_style(COLOR_PANEL, CARD_RADIUS, 72, true))
	center.add_child(panel)
	settings_panel = panel
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 46)
	panel.add_child(stack)
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	stack.add_child(header)
	var title := _label("Settings", 124, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _menu_button("X")
	close.custom_minimum_size = Vector2(170, 150)
	close.pressed.connect(_close_settings)
	header.add_child(close)
	mute_button = _menu_button("")
	mute_button.pressed.connect(_toggle_mute)
	stack.add_child(mute_button)
	var discord := _menu_button("Discord")
	discord.pressed.connect(_settings_discord_pressed)
	stack.add_child(discord)
	var reset := _menu_button("Reset Data")
	reset.add_theme_stylebox_override("normal", _button_style(Color("#ffe2e2"), BUTTON_BORDER, 48))
	reset.pressed.connect(_reset_data)
	stack.add_child(reset)


func _build_achievements_overlay() -> void:
	achievements_overlay = ColorRect.new()
	achievements_overlay.color = Color(0, 0, 0, 0.42)
	achievements_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_overlay.z_index = MODAL_OVERLAY_Z
	achievements_overlay.z_as_relative = false
	achievements_overlay.visible = false
	achievements_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	achievements_overlay.add_to_group("modal_overlay")
	achievements_overlay.gui_input.connect(_on_achievements_overlay_gui_input)
	add_child(achievements_overlay)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	achievements_overlay.add_child(center)
	var frame := Control.new()
	frame.custom_minimum_size = ACHIEVEMENTS_MODAL_SIZE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(frame)
	achievements_panel_frame = frame
	var panel := PanelContainer.new()
	panel.custom_minimum_size = ACHIEVEMENTS_MODAL_SIZE
	panel.add_theme_stylebox_override("panel", _surface_style(COLOR_PANEL, CARD_RADIUS, 72, true))
	frame.add_child(panel)
	achievements_panel = panel
	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 54)
	outer.add_theme_constant_override("margin_right", 54)
	outer.add_theme_constant_override("margin_top", 46)
	outer.add_theme_constant_override("margin_bottom", 46)
	panel.add_child(outer)
	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 28)
	outer.add_child(stack)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	stack.add_child(header)
	var title := _label("Achievements", 112, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _menu_button("X")
	close.custom_minimum_size = Vector2(170, 160)
	close.pressed.connect(_close_achievements_overlay)
	header.add_child(close)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 24)
	stack.add_child(tabs)
	achievements_tab_buttons.clear()
	var achievements_tab := _menu_button("Achievements")
	achievements_tab.pressed.connect(_set_achievements_modal_tab.bind("achievements"))
	tabs.add_child(achievements_tab)
	achievements_tab_buttons["achievements"] = achievements_tab
	var buffs_tab := _menu_button("Global Buffs")
	buffs_tab.pressed.connect(_set_achievements_modal_tab.bind("buffs"))
	tabs.add_child(buffs_tab)
	achievements_tab_buttons["buffs"] = buffs_tab

	achievements_hide_completed = CheckBox.new()
	achievements_hide_completed.text = "Hide completed achievements"
	achievements_hide_completed.button_pressed = false
	achievements_hide_completed.add_theme_font_size_override("font_size", 52)
	achievements_hide_completed.add_theme_color_override("font_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_hover_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_hover_pressed_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_pressed_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_focus_color", COLOR_INK)
	achievements_hide_completed.add_theme_color_override("font_disabled_color", COLOR_INK)
	if app_bold_font != null:
		achievements_hide_completed.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		achievements_hide_completed.add_theme_font_override("font", app_font)
	achievements_hide_completed.toggled.connect(func(_pressed: bool): _rebuild_achievements_overlay())
	stack.add_child(achievements_hide_completed)

	var scroll := MobileScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, ACHIEVEMENTS_MODAL_SCROLL_HEIGHT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	stack.add_child(scroll)
	achievements_scroll = scroll
	achievements_list_stack = VBoxContainer.new()
	achievements_list_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievements_list_stack.add_theme_constant_override("separation", 24)
	scroll.add_child(achievements_list_stack)


func _render_screen(scroll_latest_activity := false, restore_detail_scroll := -1) -> void:
	if skills_content == null:
		return
	_kill_skill_swipe_tween()
	skills_content.position = Vector2.ZERO
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		skill_swipe_page.position = Vector2.ZERO
	_clear_skill_swipe_preview()
	skill_swipe_frame = null
	skill_swipe_page = null
	skill_swipe_animating = false
	_clear(skills_content)
	skill_cards.clear()
	_clear_action_pop_tweens()
	_clear_stamina_gauge_pop_tween()
	action_cards.clear()
	detail_jump_top_button = null
	detail_jump_bottom_button = null
	detail_jump_top_hold = 0.0
	detail_jump_bottom_hold = 0.0
	detail_jump_top_hovered = false
	detail_jump_bottom_hovered = false
	
	if current_screen == "skill":
		_render_skill_detail(scroll_latest_activity, restore_detail_scroll)
	elif current_screen == "settings":
		_render_settings_page()
	elif current_screen == "shop":
		_render_shop_page()
	else:
		content_scroll = MobileScrollContainer.new()
		content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		content_scroll.set_pull_resistance_enabled(true)
		_add_centered_skill_column(content_scroll)
		var stack := VBoxContainer.new()
		stack.custom_minimum_size.x = _skill_content_width()
		stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_theme_constant_override("separation", 52)
		content_scroll.add_child(stack)
		_render_skill_menu(stack)
	_update_page_visibility()


func _skill_content_width() -> float:
	return BASE_CANVAS.x - PAGE_PAD * 2.0


func _add_centered_skill_column(control: Control) -> void:
	var content_width := _skill_content_width()
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = -content_width * 0.5
	control.offset_right = content_width * 0.5
	control.offset_top = 0.0
	control.offset_bottom = 0.0
	control.custom_minimum_size.x = content_width
	skills_content.add_child(control)


func _render_settings_page() -> void:
	content_scroll = MobileScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_add_centered_skill_column(content_scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = _skill_content_width()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 36)
	content_scroll.add_child(stack)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 106)
	stack.add_child(top_spacer)
	stack.add_child(_label("Settings", 132, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	mute_button = _settings_page_button("", "", 940, 128, 236)
	mute_button.pressed.connect(_toggle_mute)
	stack.add_child(mute_button)
	var discord := _settings_page_button("Contact the dev", "res://docs/assets/ui/discord-simple.png", 1320, 220, 286)
	discord.add_theme_stylebox_override("normal", _button_style(Color("#eaf6ff"), BUTTON_BORDER, 54))
	discord.add_theme_stylebox_override("hover", _button_style(Color("#d9efff"), BUTTON_BORDER, 54))
	discord.add_theme_stylebox_override("pressed", _button_style(Color("#c3e4ff"), BUTTON_BORDER, 54))
	discord.pressed.connect(_settings_discord_pressed)
	stack.add_child(discord)
	var reset := _settings_page_button("Hard Reset", "", 940, 128, 236)
	reset.add_theme_stylebox_override("normal", _button_style(Color("#ffb8b8"), BUTTON_BORDER, 48))
	reset.add_theme_stylebox_override("hover", _button_style(Color("#ff9f9f"), BUTTON_BORDER, 48))
	reset.add_theme_stylebox_override("pressed", _button_style(Color("#ff8080"), BUTTON_BORDER, 48))
	reset.pressed.connect(_reset_data)
	stack.add_child(reset)
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 220)
	stack.add_child(bottom_spacer)


func _render_shop_page() -> void:
	shop_bonus_label = null
	content_scroll = MobileScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_add_centered_skill_column(content_scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = _skill_content_width()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 42)
	content_scroll.add_child(stack)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 106)
	stack.add_child(top_spacer)
	stack.add_child(_label("Shop", 132, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	stack.add_child(_image("res://docs/assets/ui/shop.png", Vector2(300, 300)))
	var offer := _shop_ad_offer_button()
	offer.pressed.connect(_shop_ad_pressed)
	stack.add_child(offer)
	shop_bonus_label = _label("", 54, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	shop_bonus_label.custom_minimum_size = Vector2(1320, 0)
	shop_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(shop_bonus_label)
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 220)
	stack.add_child(bottom_spacer)


func _render_skill_menu(stack: VBoxContainer) -> void:
	var total_level_header := MarginContainer.new()
	total_level_header.add_theme_constant_override("margin_top", 150)
	total_level_header.add_theme_constant_override("margin_bottom", 12)
	stack.add_child(total_level_header)
	var total_row := HBoxContainer.new()
	total_row.alignment = BoxContainer.ALIGNMENT_CENTER
	total_row.add_theme_constant_override("separation", 22)
	total_level_header.add_child(total_row)
	var total_icon := _image("res://docs/assets/ui/total-lv-bargraph.png", Vector2(118, 118))
	total_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	total_row.add_child(total_icon)
	total_row.add_child(_label("Total Lv %s" % _global_level(), 154, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER))
	for def in skill_defs:
		var skill_id := str(def["id"])
		var theme_color := _skill_theme_color(skill_id)
		var card_slot := Control.new()
		card_slot.custom_minimum_size = Vector2(0, 480)
		card_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_child(card_slot)

		var button := Button.new()
		button.text = ""
		button.anchor_left = 0.0
		button.anchor_right = 1.0
		button.anchor_top = 0.0
		button.anchor_bottom = 1.0
		button.offset_left = SKILL_MENU_CARD_SIDE_INSET
		button.offset_right = -SKILL_MENU_CARD_SIDE_INSET
		button.offset_top = 0.0
		button.offset_bottom = 0.0
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _button_style(COLOR_PANEL, BUTTON_BORDER, CARD_RADIUS))
		button.add_theme_stylebox_override("hover", _button_style(COLOR_GOLD, BUTTON_BORDER, CARD_RADIUS))
		button.add_theme_stylebox_override("pressed", _button_style(COLOR_GOLD.darkened(0.08), BUTTON_BORDER, CARD_RADIUS))
		button.pressed.connect(_select_skill.bind(skill_id))
		card_slot.add_child(button)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 54)
		margin.add_theme_constant_override("margin_right", 54)
		margin.add_theme_constant_override("margin_top", 36)
		margin.add_theme_constant_override("margin_bottom", 36)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(margin)
		
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 34)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)
		row.add_child(_image("res://docs/assets/icons/%s.png" % skill_id, Vector2(258, 258)))
		var copy := VBoxContainer.new()
		copy.custom_minimum_size.x = SKILL_MENU_COPY_WIDTH
		copy.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		copy.add_theme_constant_override("separation", 28)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var title := _label("", 102, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(title)
		var meta := _label("", 52, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(meta)
		var xp_bar := _progress(theme_color, 46)
		xp_bar.custom_minimum_size.x = 580
		xp_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		copy.add_child(xp_bar)
		var stamina_gauge := RegenCircle.new()
		stamina_gauge.custom_minimum_size = Vector2(366, 366)
		stamina_gauge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stamina_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stamina_gauge.set_theme_color(theme_color)
		row.add_child(stamina_gauge)
		skill_cards[skill_id] = {"title": title, "meta": meta, "xp": xp_bar, "stamina": stamina_gauge}


func _render_skill_detail(scroll_latest_activity := false, restore_detail_scroll := -1) -> void:
	var content_width := _skill_content_width()
	var frame := Control.new()
	skill_swipe_frame = frame
	_add_centered_skill_column(frame)

	var page := VBoxContainer.new()
	skill_swipe_page = page
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.custom_minimum_size.x = content_width
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	page.z_index = 20
	frame.add_child(page)

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 760)
	header.custom_minimum_size.x = content_width
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _summary_style())
	page.add_child(header)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 66)
	header_margin.add_theme_constant_override("margin_right", 46)
	header_margin.add_theme_constant_override("margin_top", 88)
	header_margin.add_theme_constant_override("margin_bottom", 74)
	header.add_child(header_margin)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 66)
	header_margin.add_child(header_row)

	var left_block := HBoxContainer.new()
	left_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_block.alignment = BoxContainer.ALIGNMENT_CENTER
	left_block.add_theme_constant_override("separation", 58)
	left_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(left_block)
	var summary_icon_panel := PanelContainer.new()
	summary_icon_panel.custom_minimum_size = Vector2(344, 344)
	summary_icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	summary_icon_panel.add_theme_stylebox_override("panel", _summary_icon_style())
	summary_icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(summary_icon_panel)
	summary_icon_panel.add_child(_image("res://docs/assets/icons/%s.png" % selected_skill_id, Vector2(304, 304)))
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 22)
	title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(title_stack)
	var title := _label(_skill_name(selected_skill_id), 132, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(title)
	var xp := _xp_progress(selected_skill_id)
	detail_xp_label = _label("", 66, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	detail_xp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_stack.add_child(detail_xp_label)
	detail_xp_bar = _progress(_skill_theme_color(selected_skill_id), 78, float(xp["pct"]))
	title_stack.add_child(detail_xp_bar)

	detail_regen_circle = RegenCircle.new()
	detail_regen_circle.custom_minimum_size = Vector2(552, 552)
	detail_regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_regen_circle.gui_input.connect(_on_stamina_gauge_input)
	header_row.add_child(detail_regen_circle)
	detail_stamina_bar = null

	var divider := Control.new()
	divider.custom_minimum_size = Vector2(0, 24)
	divider.custom_minimum_size.x = content_width
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(divider)

	var actions_clip := Control.new()
	actions_clip.custom_minimum_size.x = content_width
	actions_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_clip.clip_contents = true
	page.add_child(actions_clip)

	var actions_scroll := MobileScrollContainer.new()
	detail_actions_scroll = actions_scroll
	detail_action_card_nodes.clear()
	detail_rendered_action_ids.clear()
	actions_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	actions_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	actions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	actions_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	actions_scroll.set_pull_resistance_enabled(true)
	actions_clip.add_child(actions_scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = content_width
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 56)
	actions_scroll.add_child(stack)
	var scroll_top_spacer := Control.new()
	scroll_top_spacer.custom_minimum_size = Vector2(0, 12)
	stack.add_child(scroll_top_spacer)
	
	for action in _visible_actions_for_skill(selected_skill_id):
		var action_id := str(action["id"])
		detail_rendered_action_ids.append(action_id)
		var card_root := Control.new()
		card_root.custom_minimum_size = Vector2(0, ACTION_CARD_HEIGHT)
		card_root.custom_minimum_size.x = content_width
		card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_root.clip_contents = false
		stack.add_child(card_root)
		detail_action_card_nodes[action_id] = card_root

		var pop_card := Control.new()
		pop_card.anchor_left = 0.0
		pop_card.anchor_right = 1.0
		pop_card.anchor_top = 0.0
		pop_card.anchor_bottom = 1.0
		pop_card.offset_left = ACTION_CARD_POP_GUTTER
		pop_card.offset_right = -ACTION_CARD_POP_GUTTER
		pop_card.offset_top = 0.0
		pop_card.offset_bottom = 0.0
		pop_card.clip_contents = false
		card_root.add_child(pop_card)
		
		var bg := RoundedTextureRect.new()
		bg.texture = _texture(str(action["bg"]))
		bg.modulate = Color.WHITE
		bg.radius = 66.0
		bg.crop_left = 0.025 if selected_skill_id == "fishing" else 0.0
		bg.crop_right = 0.015 if selected_skill_id == "fishing" else 0.0
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.z_index = 150
		pop_card.add_child(bg)
		
		var shade := Panel.new()
		shade.add_theme_stylebox_override("panel", _activity_shade_style(0.50))
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade.visible = false
		shade.z_index = 224
		pop_card.add_child(shade)
		
		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 54)
		margin.add_theme_constant_override("margin_right", 54)
		margin.add_theme_constant_override("margin_top", 46)
		margin.add_theme_constant_override("margin_bottom", 126)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.z_index = 200
		pop_card.add_child(margin)
		
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 56)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(row)

		var art_slot := MarginContainer.new()
		art_slot.add_theme_constant_override("margin_top", 42)
		art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(art_slot)
		var art_panel := Panel.new()
		art_panel.custom_minimum_size = Vector2(410, 410)
		art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		art_panel.add_theme_stylebox_override("panel", _action_art_style())
		art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art_slot.add_child(art_panel)
		var art := _image(str(action["art"]), Vector2(356, 356))
		art.position = Vector2(27, 27)
		art_panel.add_child(art)

		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 38)
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(copy)
		var name := _label(str(action["name"]), 82, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		name.add_theme_color_override("font_outline_color", COLOR_INK)
		name.add_theme_constant_override("outline_size", 34)
		name.autowrap_mode = TextServer.AUTOWRAP_OFF
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		copy.add_child(name)

		var stat_row := HBoxContainer.new()
		stat_row.add_theme_constant_override("separation", 28)
		stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		copy.add_child(stat_row)
		var xp_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(xp_label))
		var stamina_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(stamina_label))
		var time_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(time_label))
		var success_label := _action_stat_label("")
		stat_row.add_child(_action_stat_box(success_label))

		var medal := TextureRect.new()
		medal.anchor_left = 0.0
		medal.anchor_right = 0.0
		medal.anchor_top = 0.0
		medal.anchor_bottom = 0.0
		medal.offset_left = 300
		medal.offset_right = 490
		medal.offset_top = -62
		medal.offset_bottom = 128
		medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medal.z_index = 21
		art_panel.add_child(medal)
		var mastery_progress := _progress(Color("#f4bf35"), 56)
		mastery_progress.easing_speed = 5.0
		mastery_progress.z_index = 20
		copy.add_child(mastery_progress)

		var status := _label("", 42, COLOR_RED, HORIZONTAL_ALIGNMENT_LEFT)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var progress := ActivityProgressRail.new()
		progress.fill_color = _skill_theme_color(selected_skill_id)
		progress.anchor_left = 0.0
		progress.anchor_right = 1.0
		progress.anchor_top = 1.0
		progress.anchor_bottom = 1.0
		progress.offset_left = ACTION_PROGRESS_RAIL_INSET
		progress.offset_right = -ACTION_PROGRESS_RAIL_INSET
		progress.offset_top = -126
		progress.offset_bottom = -ACTION_PROGRESS_RAIL_INSET
		progress.z_index = 152
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pop_card.add_child(progress)

		var border := ActivityCardBorder.new()
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = 220
		pop_card.add_child(border)

		var lock_overlay := _activity_lock_overlay(pop_card, int(action.get("unlock", 1)))

		var button := Button.new()
		button.text = ""
		button.modulate = Color(1, 1, 1, 0)
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.z_index = 230
		button.pressed.connect(_start_action.bind(selected_skill_id, action_id))
		pop_card.add_child(button)
		action_cards[_action_key(selected_skill_id, action_id)] = {
			"root": card_root,
			"pop": pop_card,
			"button": button,
			"bg": bg,
			"shade": shade,
			"art_panel": art_panel,
			"art": art,
			"xp": xp_label,
			"stamina": stamina_label,
			"time": time_label,
			"success": success_label,
			"status": status,
			"medal": medal,
			"mastery": mastery_progress,
			"progress": progress,
			"border": border,
			"lock_overlay": lock_overlay,
			"medal_destination": Vector2(medal.offset_left, medal.offset_top)
		}
		if _pending_activity_unlock_matches(action_id):
			action_cards[_action_key(selected_skill_id, action_id)]["unlock_ceremony_pending"] = true
		if _pending_activity_unlock_preview_matches(action_id):
			card_root.modulate = Color(1, 1, 1, 0)
			action_cards[_action_key(selected_skill_id, action_id)]["fade_in_pending"] = true
		elif activity_unlock_preview_after_ceremony_id == action_id:
			card_root.modulate = Color(1, 1, 1, 0)
			action_cards[_action_key(selected_skill_id, action_id)]["fade_in_pending"] = true

	var scroll_bottom_spacer := Control.new()
	scroll_bottom_spacer.custom_minimum_size = Vector2(0, 180)
	stack.add_child(scroll_bottom_spacer)
	_build_detail_jump_arrows(actions_clip)
	if restore_detail_scroll >= 0:
		actions_scroll.drag_scroll_position = float(maxi(0, restore_detail_scroll))
		actions_scroll.scroll_vertical = maxi(0, restore_detail_scroll)
		call_deferred("_restore_detail_actions_scroll", restore_detail_scroll)
	elif scroll_latest_activity:
		call_deferred("_scroll_to_latest_unlocked_activity", false)
	call_deferred("_prepare_skill_swipe_preview_pages")


func _build_detail_jump_arrows(parent: Control) -> void:
	if detail_actions_scroll == null:
		return
	if not detail_actions_scroll.user_scroll_direction.is_connected(_on_detail_actions_user_scroll_direction):
		detail_actions_scroll.user_scroll_direction.connect(_on_detail_actions_user_scroll_direction)
	detail_jump_top_button = _activity_jump_button(ACTIVITY_JUMP_TOP_TEXTURE, true)
	detail_jump_bottom_button = _activity_jump_button(ACTIVITY_JUMP_BOTTOM_TEXTURE, false)
	parent.add_child(detail_jump_top_button)
	parent.add_child(detail_jump_bottom_button)


func _activity_jump_button(path: String, top: bool) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = _texture(path)
	button.texture_hover = button.texture_normal
	button.texture_pressed = button.texture_normal
	button.texture_disabled = button.texture_normal
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = ACTIVITY_JUMP_ARROW_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.z_index = 800
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.offset_left = -ACTIVITY_JUMP_ARROW_SIZE.x * 0.5
	button.offset_right = ACTIVITY_JUMP_ARROW_SIZE.x * 0.5
	if top:
		button.anchor_top = 0.0
		button.anchor_bottom = 0.0
		button.offset_top = ACTIVITY_JUMP_ARROW_EDGE_INSET
		button.offset_bottom = ACTIVITY_JUMP_ARROW_EDGE_INSET + ACTIVITY_JUMP_ARROW_SIZE.y
	else:
		button.anchor_top = 1.0
		button.anchor_bottom = 1.0
		button.offset_top = -ACTIVITY_JUMP_ARROW_EDGE_INSET - ACTIVITY_JUMP_ARROW_SIZE.y
		button.offset_bottom = -ACTIVITY_JUMP_ARROW_EDGE_INSET
	button.modulate = Color(1, 1, 1, 0)
	button.disabled = true
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.mouse_entered.connect(_on_detail_jump_arrow_hovered.bind(top, true))
	button.mouse_exited.connect(_on_detail_jump_arrow_hovered.bind(top, false))
	button.pressed.connect(_on_detail_jump_arrow_pressed.bind(-1 if top else 1))
	return button


func _on_detail_actions_user_scroll_direction(direction: int) -> void:
	if current_screen != "skill":
		return
	_reveal_detail_jump_arrow(direction)


func _on_detail_jump_arrow_hovered(top: bool, hovered: bool) -> void:
	if top:
		detail_jump_top_hovered = hovered
		if hovered:
			_reveal_detail_jump_arrow(-1)
		else:
			detail_jump_top_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS
	else:
		detail_jump_bottom_hovered = hovered
		if hovered:
			_reveal_detail_jump_arrow(1)
		else:
			detail_jump_bottom_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS


func _on_detail_jump_arrow_pressed(direction: int) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	if direction < 0:
		detail_jump_top_hold = 0.0
		detail_jump_bottom_hold = 0.0
		detail_jump_bottom_hovered = false
		detail_actions_scroll.scroll_to_vertical(0, 0.24)
	else:
		detail_jump_bottom_hold = 0.0
		detail_jump_top_hold = 0.0
		detail_jump_top_hovered = false
		detail_actions_scroll.scroll_to_vertical(detail_actions_scroll.get_max_scroll_vertical(), 0.24)
	get_viewport().set_input_as_handled()


func _reveal_detail_jump_arrow(direction: int) -> void:
	if detail_actions_scroll == null:
		return
	var max_scroll := detail_actions_scroll.get_max_scroll_vertical()
	if max_scroll <= ACTIVITY_JUMP_ARROW_EDGE_EPSILON:
		return
	var scroll := detail_actions_scroll.scroll_vertical
	if direction < 0 and scroll > ACTIVITY_JUMP_ARROW_EDGE_EPSILON:
		detail_jump_top_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS
	elif direction > 0 and scroll < max_scroll - ACTIVITY_JUMP_ARROW_EDGE_EPSILON:
		detail_jump_bottom_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS


func _process_detail_jump_arrows(delta: float) -> void:
	if detail_actions_scroll == null or current_screen != "skill":
		_process_detail_jump_arrow(detail_jump_top_button, true, false, delta)
		_process_detail_jump_arrow(detail_jump_bottom_button, false, false, delta)
		return
	var max_scroll := detail_actions_scroll.get_max_scroll_vertical()
	var scroll := detail_actions_scroll.scroll_vertical
	var can_jump_top := max_scroll > ACTIVITY_JUMP_ARROW_EDGE_EPSILON and scroll > ACTIVITY_JUMP_ARROW_EDGE_EPSILON
	var can_jump_bottom := max_scroll > ACTIVITY_JUMP_ARROW_EDGE_EPSILON and scroll < max_scroll - ACTIVITY_JUMP_ARROW_EDGE_EPSILON
	_process_detail_jump_arrow(detail_jump_top_button, true, can_jump_top, delta)
	_process_detail_jump_arrow(detail_jump_bottom_button, false, can_jump_bottom, delta)


func _process_detail_jump_arrow(button: TextureButton, top: bool, can_use: bool, delta: float) -> void:
	if button == null or not is_instance_valid(button):
		return
	if top:
		if not can_use:
			detail_jump_top_hold = 0.0
			detail_jump_top_hovered = false
		elif detail_jump_top_hovered:
			detail_jump_top_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS
		else:
			detail_jump_top_hold = maxf(0.0, detail_jump_top_hold - delta)
	else:
		if not can_use:
			detail_jump_bottom_hold = 0.0
			detail_jump_bottom_hovered = false
		elif detail_jump_bottom_hovered:
			detail_jump_bottom_hold = ACTIVITY_JUMP_ARROW_LINGER_SECONDS
		else:
			detail_jump_bottom_hold = maxf(0.0, detail_jump_bottom_hold - delta)
	var held := detail_jump_top_hold if top else detail_jump_bottom_hold
	var hovered := detail_jump_top_hovered if top else detail_jump_bottom_hovered
	var target_alpha := 1.0 if can_use and (hovered or held > 0.0) else 0.0
	var fade_seconds := ACTIVITY_JUMP_ARROW_FADE_IN_SECONDS if target_alpha > button.modulate.a else ACTIVITY_JUMP_ARROW_FADE_OUT_SECONDS
	var step := delta / maxf(0.001, fade_seconds)
	var next_alpha := move_toward(button.modulate.a, target_alpha, step)
	button.modulate = Color(1, 1, 1, next_alpha)
	var active := can_use and next_alpha > 0.04
	button.disabled = not active
	button.mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_IGNORE


func _update_page_visibility() -> void:
	home_page.visible = current_screen == "home"
	skills_page.visible = current_screen != "home"
	_apply_nav_style(hero_tab, current_screen == "home")
	_apply_nav_style(skills_tab, current_screen == "menu" or current_screen == "skill")
	_apply_nav_style(shop_tab, current_screen == "shop")
	_apply_nav_style(settings_tab, current_screen == "settings")


func _update_ui(delta: float, instant := false) -> void:
	if _skill_detail_needs_action_list_refresh():
		_render_screen(false, detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1)
	if current_screen == "home" and home_total_label != null:
		home_total_label.text = "Total Lv %s" % _global_level()
		for skill_id in home_skill_labels.keys():
			var skill_id_text := str(skill_id)
			(home_skill_labels[skill_id] as Label).text = "%s Lvl %s" % [_skill_name(skill_id_text), _skill_level(skill_id_text)]
	var achievements_visible := current_screen == "home" or (achievements_overlay != null and achievements_overlay.visible)
	if achievements_visible:
		_update_achievements_ui(delta, instant)
	if current_screen == "menu":
		for skill_id in skill_cards.keys():
			var skill_id_text := str(skill_id)
			var xp := _xp_progress(skill_id_text)
			var card: Dictionary = skill_cards[skill_id]
			(card["title"] as Label).text = "%s" % _skill_name(skill_id_text)
			(card["meta"] as Label).text = "Lv %s  XP %s / %s" % [
				_skill_level(skill_id_text),
				int(xp["current"]),
				int(xp["needed"])
			]
			(card["xp"] as CleanProgressBar).fill_color = _skill_theme_color(skill_id_text)
			_set_bar(card["xp"], float(xp["pct"]), delta, instant)
			var stamina_gauge := card["stamina"] as RegenCircle
			if stamina_gauge != null:
				var max_stamina := _max_stamina()
				var stamina_value := _stamina(skill_id_text)
				var circle_value := 1.0
				if stamina_value < max_stamina:
					circle_value = float(stamina_bank.get(skill_id_text, 0.0)) / STAMINA_REGEN_SECONDS
				stamina_gauge.set_theme_color(_skill_theme_color(skill_id_text))
				stamina_gauge.set_stamina(stamina_value, max_stamina, instant, circle_value)
				stamina_gauge.set_value(_regen_ring_ease(circle_value), instant)
	if current_screen == "skill":
		var detail_xp := _xp_progress(selected_skill_id)
		if detail_xp_label != null:
			detail_xp_label.text = "Lv %s - XP %s / %s" % [_skill_level(selected_skill_id), int(detail_xp["current"]), int(detail_xp["needed"])]
		if detail_xp_bar != null:
			detail_xp_bar.fill_color = _skill_theme_color(selected_skill_id)
			_set_bar(detail_xp_bar, float(detail_xp["pct"]), delta, instant)
		if detail_regen_circle != null:
			var max_stamina := _max_stamina()
			var stamina_value := _stamina(selected_skill_id)
			var circle_value := 1.0
			if stamina_value < max_stamina:
				circle_value = float(stamina_bank.get(selected_skill_id, 0.0)) / STAMINA_REGEN_SECONDS
			detail_regen_circle.set_theme_color(_skill_theme_color(selected_skill_id))
			detail_regen_circle.set_stamina(stamina_value, max_stamina, instant, circle_value)
			detail_regen_circle.set_value(_regen_ring_ease(circle_value), instant)
		_update_skill_swipe_preview_states(delta, instant)
	for key in action_cards.keys():
		var parts := str(key).split(":")
		var skill_id := parts[0]
		var action_id := parts[1]
		var action := _action_data(skill_id, action_id)
		var unlocked := _skill_level(skill_id) >= int(action.get("unlock", 1))
		var running := running_skill_id == skill_id and running_action_id == action_id
		var card: Dictionary = action_cards[key]
		_update_action_card_static_state(card, skill_id, action, unlocked)
		var status := card["status"] as Label
		status.text = ""
		var medal := card["medal"] as TextureRect
		var mastery_level := _mastery_level(skill_id, action_id)
		_set_action_card_medal(card, medal, mastery_level, instant)
		_set_bar(card["mastery"], _mastery_progress_pct(skill_id, action_id), delta, instant)
		var progress_rail := card["progress"] as ActivityProgressRail
		progress_rail.fill_color = _skill_theme_color(skill_id)
		var progress_target := action_progress * 100.0 if running else 0.0
		var progress_instant := instant
		if running and progress_target + 6.0 < progress_rail.value:
			progress_instant = true
		_set_bar(progress_rail, progress_target, delta, progress_instant)
	_play_pending_activity_unlock_ceremony()
	if mute_button != null:
		mute_button.text = "Unmute" if is_muted else "Mute"
	if shop_bonus_label != null:
		shop_bonus_label.text = _shop_bonus_status_text()


func _set_action_card_medal(card: Dictionary, medal: TextureRect, mastery_level: int, instant: bool) -> void:
	if medal == null or not is_instance_valid(medal):
		return
	var last_level := int(card.get("last_mastery_level", -1))
	if last_level == mastery_level:
		return
	var should_animate := not instant and last_level >= 0 and mastery_level > last_level and mastery_level > 0
	var old_texture := medal.texture
	var replacing := should_animate and last_level > 0 and old_texture != null and medal.visible
	_clear_action_card_medal_ceremony(card)
	if should_animate:
		_play_new_medal_ceremony(card, medal, old_texture, replacing, mastery_level)
	else:
		_place_action_card_medal(card, medal, mastery_level)
	card["last_mastery_level"] = mastery_level


func _place_action_card_medal(card: Dictionary, medal: TextureRect, mastery_level: int) -> void:
	var destination := _action_card_medal_destination(card, medal)
	medal.visible = mastery_level > 0
	medal.texture = _mastery_medal_texture(mastery_level) if mastery_level > 0 else null
	medal.position = destination
	medal.scale = Vector2.ONE
	medal.rotation_degrees = 0.0
	medal.pivot_offset = medal.size * 0.5
	medal.modulate = Color.WHITE


func _play_new_medal_ceremony(card: Dictionary, medal: TextureRect, old_texture: Texture2D, replacing: bool, mastery_level: int) -> void:
	var destination := _action_card_medal_destination(card, medal)
	medal.texture = _mastery_medal_texture(mastery_level)
	medal.visible = true
	medal.position = destination + Vector2(92, -148)
	medal.scale = Vector2(1.34, 1.34)
	medal.rotation_degrees = -7.0
	medal.pivot_offset = medal.size * 0.5
	medal.modulate = Color(1, 1, 1, 0)
	if replacing:
		_start_replaced_medal_fall(card, medal, old_texture, destination)
	var anticipation_position := destination + Vector2(122, -192)
	var tween := create_tween()
	card["medal_ceremony_tween"] = tween
	tween.tween_property(medal, "position", anticipation_position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "scale", Vector2(1.48, 1.48), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", -13.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "modulate:a", 1.0, 0.12)
	tween.chain().tween_property(medal, "position", destination, 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "scale", Vector2(0.95, 0.95), 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 2.0, 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(medal, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		medal.position = destination
		medal.scale = Vector2.ONE
		medal.rotation_degrees = 0.0
		medal.modulate = Color.WHITE
		card.erase("medal_ceremony_tween")
	)


func _start_replaced_medal_fall(card: Dictionary, medal: TextureRect, old_texture: Texture2D, destination: Vector2) -> void:
	var parent := medal.get_parent() as Control
	if parent == null or old_texture == null:
		return
	var outgoing := TextureRect.new()
	outgoing.texture = old_texture
	outgoing.anchor_left = 0.0
	outgoing.anchor_right = 0.0
	outgoing.anchor_top = 0.0
	outgoing.anchor_bottom = 0.0
	outgoing.position = destination
	outgoing.size = medal.size
	outgoing.expand_mode = medal.expand_mode
	outgoing.stretch_mode = medal.stretch_mode
	outgoing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outgoing.z_index = medal.z_index + 1
	outgoing.pivot_offset = outgoing.size * 0.5
	outgoing.modulate = Color.WHITE
	parent.add_child(outgoing)
	card["medal_outgoing"] = outgoing
	var tween := create_tween()
	card["medal_outgoing_tween"] = tween
	tween.set_parallel(true)
	tween.tween_property(outgoing, "position", destination + Vector2(-62, 260), 0.60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "rotation_degrees", -46.0, 0.60).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "scale", Vector2(0.76, 0.76), 0.54).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "modulate:a", 0.0, 0.39).set_delay(0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func():
		if is_instance_valid(outgoing):
			outgoing.queue_free()
		card.erase("medal_outgoing")
		card.erase("medal_outgoing_tween")
	)


func _clear_action_card_medal_ceremony(card: Dictionary) -> void:
	var ceremony_tween := card.get("medal_ceremony_tween", null) as Tween
	if ceremony_tween != null and ceremony_tween.is_valid():
		ceremony_tween.kill()
	card.erase("medal_ceremony_tween")
	var outgoing_tween := card.get("medal_outgoing_tween", null) as Tween
	if outgoing_tween != null and outgoing_tween.is_valid():
		outgoing_tween.kill()
	card.erase("medal_outgoing_tween")
	var outgoing := card.get("medal_outgoing", null) as Node
	if outgoing != null and is_instance_valid(outgoing):
		outgoing.queue_free()
	card.erase("medal_outgoing")


func _action_card_medal_destination(card: Dictionary, medal: TextureRect) -> Vector2:
	if card.has("medal_destination"):
		return card["medal_destination"] as Vector2
	card["medal_destination"] = medal.position
	return medal.position


func _update_action_card_static_state(card: Dictionary, skill_id: String, action: Dictionary, unlocked: bool) -> void:
	var xp_text := "+%s\nXP" % _effective_xp(action)
	var stamina_text := "%s\nSTAM" % _effective_stamina(action)
	var time_text := "%ss\nTIME" % _format_seconds(_effective_seconds(skill_id, action))
	var success_text := "%s%%\nRATE" % int(_success_chance(skill_id, action))
	if card.get("last_xp_text", "") != xp_text:
		_set_label_text_if_changed(card["xp"] as Label, xp_text)
		card["last_xp_text"] = xp_text
	if card.get("last_stamina_text", "") != stamina_text:
		_set_label_text_if_changed(card["stamina"] as Label, stamina_text)
		card["last_stamina_text"] = stamina_text
	if card.get("last_time_text", "") != time_text:
		_set_label_text_if_changed(card["time"] as Label, time_text)
		card["last_time_text"] = time_text
	if card.get("last_success_text", "") != success_text:
		_set_label_text_if_changed(card["success"] as Label, success_text)
		card["last_success_text"] = success_text
	_sync_activity_lock_overlay(card, action, unlocked)
	if card.get("last_unlocked", null) == unlocked:
		return
	var button := card["button"] as Button
	if button != null:
		button.disabled = (not unlocked) or bool(card.get("unlock_ceremony_active", false)) or bool(card.get("unlock_ceremony_pending", false))
		button.modulate = Color(1, 1, 1, 0)
	var bg := card["bg"] as RoundedTextureRect
	if bg != null:
		bg.modulate = Color.WHITE
	var shade := card["shade"] as Panel
	if shade != null:
		shade.visible = not unlocked
	var art_panel := card["art_panel"] as CanvasItem
	if art_panel != null:
		art_panel.modulate = Color.WHITE
		art_panel.material = null
	var art := card.get("art") as CanvasItem
	if art != null:
		art.material = null
	var border := card.get("border") as ActivityCardBorder
	if border != null:
		border.border_color = COLOR_INK
		border.border_width = 24.0
		border.queue_redraw()
	card["last_unlocked"] = unlocked


func _update_skill_swipe_preview_states(delta: float, instant: bool) -> void:
	for raw_offset in skill_swipe_preview_states.keys():
		var state := skill_swipe_preview_states[raw_offset] as Dictionary
		if state == null:
			continue
		var page := state.get("page") as Control
		if page == null or not is_instance_valid(page):
			continue
		_sync_skill_swipe_preview_scroll_state(state)
		var skill_id := str(state.get("skill_id", ""))
		if skill_id.is_empty():
			continue
		var xp := _xp_progress(skill_id)
		var xp_label := state.get("xp_label") as Label
		if xp_label != null:
			xp_label.text = "Lv %s - XP %s / %s" % [_skill_level(skill_id), int(xp["current"]), int(xp["needed"])]
		var xp_bar := state.get("xp_bar") as CleanProgressBar
		if xp_bar != null:
			xp_bar.fill_color = _skill_theme_color(skill_id)
			_set_bar(xp_bar, float(xp["pct"]), delta, instant)
		var regen_circle := state.get("regen_circle") as RegenCircle
		if regen_circle != null:
			_set_regen_circle_for_skill(regen_circle, skill_id, instant)
		var preview_cards := state.get("action_cards", []) as Array
		for card in preview_cards:
			var action_card := card as Dictionary
			if action_card == null:
				continue
			var action := action_card.get("action", {}) as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			var unlocked := _skill_level(skill_id) >= int(action.get("unlock", 1))
			var running := running_skill_id == skill_id and running_action_id == action_id
			_update_action_card_static_state(action_card, skill_id, action, unlocked)
			var medal := action_card.get("medal") as TextureRect
			var mastery_level := _mastery_level(skill_id, action_id)
			_set_action_card_medal(action_card, medal, mastery_level, instant)
			_set_bar(action_card.get("mastery"), _mastery_progress_pct(skill_id, action_id), delta, instant)
			var progress_rail := action_card.get("progress") as ActivityProgressRail
			if progress_rail != null:
				progress_rail.fill_color = _skill_theme_color(skill_id)
				var progress_target := action_progress * 100.0 if running else 0.0
				var progress_instant := instant
				if running and progress_target + 6.0 < progress_rail.value:
					progress_instant = true
				_set_bar(progress_rail, progress_target, delta, progress_instant)


func _sync_skill_swipe_preview_scroll_state(state: Dictionary) -> void:
	var preview_scroll := state.get("actions_scroll") as ScrollContainer
	if preview_scroll == null or not is_instance_valid(preview_scroll):
		return
	var scroll_value := float(detail_actions_scroll.scroll_vertical) if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll) else 0.0
	var scroll_bar := preview_scroll.get_v_scroll_bar()
	if scroll_bar != null:
		scroll_value = clampf(scroll_value, 0.0, maxf(0.0, scroll_bar.max_value - scroll_bar.page))
	preview_scroll.scroll_vertical = int(round(scroll_value))


func _set_label_text_if_changed(label: Label, next_text: String) -> void:
	if label != null and label.text != next_text:
		label.text = next_text


func _update_achievements_ui(delta: float, instant: bool) -> void:
	if achievement_elite_label == null and achievement_total_bar == null and achievement_total_level_label == null:
		return
	var totals := _all_medal_counts()
	var total_earned := int(totals["earned"])
	var total_possible := int(totals["possible"])
	for def in skill_defs:
		var skill_id := str(def["id"])
		if achievement_skill_level_labels.has(skill_id):
			var level_label := achievement_skill_level_labels[skill_id] as Label
			level_label.text = "%s Lv %s" % [_skill_name(skill_id), _skill_level(skill_id)]
		_update_achievement_medal_slots(skill_id, actions_by_skill.get(skill_id, []))
	if achievement_elite_label != null:
		var elite_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		achievement_elite_label.text = "%s%% Elite" % int(round(elite_pct))
	if achievement_total_level_label != null:
		achievement_total_level_label.text = "Total Lv %s" % _global_level()
	if achievement_buff_label != null:
		achievement_buff_label.text = _global_medal_buff_lines()
	if achievement_total_bar != null:
		var total_pct := 0.0 if total_possible <= 0 else float(total_earned) / float(total_possible) * 100.0
		_set_bar(achievement_total_bar, total_pct, delta, instant)
	_update_most_impressive_activity()


func _update_most_impressive_activity() -> void:
	if achievement_best_name_label == null:
		return
	var best := _most_impressive_activity()
	if best.is_empty():
		if achievement_best_art_frame != null:
			achievement_best_art_frame.visible = false
		if achievement_best_art != null:
			achievement_best_art.visible = false
		if achievement_best_medal != null:
			achievement_best_medal.visible = false
		achievement_best_name_label.text = "Earn a medal to feature an activity"
		return
	if achievement_best_art_frame != null:
		achievement_best_art_frame.visible = true
	if achievement_best_art != null:
		achievement_best_art.visible = true
		achievement_best_art.texture = _texture(str(best.get("art", "")))
	if achievement_best_medal != null:
		achievement_best_medal.visible = true
		achievement_best_medal.texture = _mastery_medal_texture(int(best.get("level", 1)))
	achievement_best_name_label.text = str(best.get("name", ""))


func _update_achievement_medal_slots(skill_id: String, actions: Array) -> void:
	var panel_rows: Array = achievement_medal_slot_panels.get(skill_id, [])
	var icon_rows: Array = achievement_medal_slot_icons.get(skill_id, [])
	if icon_rows.is_empty():
		return
	var panels: Array = panel_rows[0] if not panel_rows.is_empty() else []
	var icons: Array = icon_rows[0]
	var skill_level := _skill_level(skill_id)
	for slot_index in range(mini(ACHIEVEMENT_MEDAL_SLOT_COUNT, icons.size())):
		var has_action := slot_index < actions.size()
		var accessible := false
		var mastery_level := 0
		if has_action:
			var action := actions[slot_index] as Dictionary
			accessible = skill_level >= int(action.get("unlock", 1))
			mastery_level = _mastery_level(skill_id, str(action["id"]))
		var icon := icons[slot_index] as TextureRect
		if icon != null:
			icon.material = null
			var shadow := panels[slot_index] as TextureRect if slot_index < panels.size() else null
			if mastery_level > 0:
				icon.texture = _mastery_medal_texture(mastery_level)
				if shadow != null:
					shadow.visible = false
			elif accessible:
				icon.texture = _mastery_medal_silhouette_texture(1, Color("#555555"))
				if shadow != null:
					shadow.visible = true
					shadow.texture = _mastery_medal_silhouette_texture(1, Color(0, 0, 0, 0.62))
			else:
				icon.texture = _mastery_medal_dot_texture()
				if shadow != null:
					shadow.visible = false
			icon.modulate = Color.WHITE


func _skill_medal_counts(skill_id: String) -> Dictionary:
	var actions: Array = actions_by_skill.get(skill_id, [])
	var tiers := []
	for _i in range(MASTERY_MAX_LEVEL):
		tiers.append(0)
	var cumulative := 0
	for action in actions:
		var level := _mastery_level(skill_id, str(action["id"]))
		cumulative += level
		for tier in range(1, MASTERY_MAX_LEVEL + 1):
			if level >= tier:
				tiers[tier - 1] = int(tiers[tier - 1]) + 1
	return {
		"actions": actions.size(),
		"earned": cumulative,
		"possible": actions.size() * MASTERY_MAX_LEVEL,
		"tiers": tiers
	}


func _all_medal_counts() -> Dictionary:
	var earned := 0
	var possible := 0
	for def in skill_defs:
		var counts := _skill_medal_counts(str(def["id"]))
		earned += int(counts["earned"])
		possible += int(counts["possible"])
	return {"earned": earned, "possible": possible}


func _all_medal_tier_counts() -> Array:
	var totals := []
	for _i in range(MASTERY_MAX_LEVEL):
		totals.append(0)
	for def in skill_defs:
		var counts := _skill_medal_counts(str(def["id"]))
		var tiers: Array = counts["tiers"]
		for i in range(mini(MASTERY_MAX_LEVEL, tiers.size())):
			totals[i] = int(totals[i]) + int(tiers[i])
	return totals


func _most_impressive_activity() -> Dictionary:
	var best := {}
	var best_score := -1.0
	var best_level := 0
	for def in skill_defs:
		var skill_id := str(def["id"])
		var actions: Array = actions_by_skill.get(skill_id, [])
		for action in actions:
			var action_id := str(action.get("id", ""))
			var level := _mastery_level(skill_id, action_id)
			if level <= 0:
				continue
			var seconds_required := float(action.get("seconds", 1.0)) * float(_mastery_xp_for_level(level))
			if seconds_required > best_score or (is_equal_approx(seconds_required, best_score) and level > best_level):
				best_score = seconds_required
				best_level = level
				best = {
					"skill_id": skill_id,
					"action_id": action_id,
					"name": str(action.get("name", "")),
					"art": str(action.get("art", "")),
					"level": level,
					"medal": str(MASTERY_MEDAL_NAMES[clampi(level, 1, MASTERY_MAX_LEVEL) - 1]),
					"seconds_required": seconds_required
				}
	return best


func _total_activity_count() -> int:
	var total := 0
	for def in skill_defs:
		total += int(actions_by_skill.get(str(def["id"]), []).size())
	return total


func _max_total_level() -> int:
	return skill_defs.size() * 99


func _skill_level_milestone_medal(target: int) -> int:
	match target:
		10:
			return 2
		25:
			return 5
		50:
			return 10
		75:
			return 15
		99:
			return 20
	return clampi(int(ceil(float(target) / 99.0 * float(ACHIEVEMENT_MEDAL_ART_COUNT))), 1, ACHIEVEMENT_MEDAL_ART_COUNT)


func _total_level_milestone_medal(target: int, max_total: int) -> int:
	if max_total <= 0:
		return 1
	var scaled := int(ceil(float(target) / float(max_total) * float(MASTERY_MAX_LEVEL)))
	return clampi(scaled, 1, MASTERY_MAX_LEVEL)


func _achievement_milestones() -> Array:
	var milestones := []
	var total_counts := _all_medal_counts()
	var cumulative := int(total_counts["earned"])
	var cumulative_possible := int(total_counts["possible"])
	var total_level := _global_level()
	var max_total_level := _max_total_level()
	for def in skill_defs:
		var skill_id := str(def["id"])
		var skill_level := _skill_level(skill_id)
		var skill_name := _skill_name(skill_id)
		for target in _skill_level_achievement_targets():
			milestones.append({
				"id": "skill-level-%s-%s" % [skill_id, target],
				"chain_key": "skill-level-%s" % skill_id,
				"kind": "skill_level",
				"skill_id": skill_id,
				"title": "%s Level %s" % [skill_name, target],
				"subtitle": "%s Lv %s of %s" % [skill_name, mini(skill_level, int(target)), target],
				"reward": _skill_level_achievement_reward_text(skill_name, int(target)),
				"reward_stat": "skill_timer_reduction",
				"reward_skill_id": skill_id,
				"reward_amount": _skill_level_achievement_timer_reward(int(target)),
				"current": skill_level,
				"target": int(target),
				"completed": skill_level >= int(target),
				"medal_level": _skill_level_milestone_medal(int(target)),
				"accent": "#" + _skill_theme_color(skill_id).to_html(false)
			})
	for target in TOTAL_LEVEL_ACHIEVEMENT_TARGETS:
		if max_total_level < int(target) and total_level < int(target):
			continue
		milestones.append({
			"id": "total-level-%s" % target,
			"chain_key": "total-level",
			"kind": "total_level",
			"title": "Total Level %s" % target,
			"subtitle": "Total Lv %s of %s" % [mini(total_level, int(target)), target],
			"reward": _total_level_achievement_reward_text(int(target)),
			"reward_stat": "max_stamina",
			"reward_amount": _total_level_achievement_stamina_reward(int(target)),
			"current": total_level,
			"target": int(target),
			"completed": total_level >= int(target),
			"medal_level": _total_level_milestone_medal(int(target), max_total_level),
			"accent": "#f4bf35"
			})
	var tier_counts := _all_medal_tier_counts()
	var total_activity_count := _total_activity_count()
	for tier_index in range(mini(MASTERY_MAX_LEVEL, tier_counts.size())):
		var tier := tier_index + 1
		var target := _tier_count_achievement_target(tier)
		var current := int(tier_counts[tier_index])
		if total_activity_count < target and current < target:
			continue
		var medal_name := str(MASTERY_MEDAL_NAMES[tier_index])
		milestones.append({
			"id": "tier-count-%s-%s" % [tier, target],
			"chain_key": "tier-count-medals",
			"kind": "tier_count",
			"tier": tier,
			"title": "%s Medals" % medal_name,
			"subtitle": "%s of %s %s medals earned" % [mini(current, target), target, medal_name],
			"reward": _tier_count_achievement_reward_text(tier),
			"reward_stat": "max_stamina",
			"reward_amount": _tier_count_achievement_stamina_reward(tier),
			"current": current,
			"target": target,
			"completed": current >= target,
			"medal_level": tier,
			"accent": "#" + _mastery_medal_accent(tier).to_html(false)
		})
	for target in [10, 25, 50, 100, 250, 500, 1000]:
		if cumulative_possible < target and cumulative < target:
			continue
		milestones.append({
			"id": "cumulative-%s" % target,
			"chain_key": "cumulative-medals",
			"kind": "cumulative_medals",
			"title": "Cumulative Medals",
			"subtitle": "%s of %s total medals earned" % [mini(cumulative, target), target],
			"reward": _cumulative_medal_achievement_reward_text(int(target)),
			"reward_stat": "max_stamina",
			"reward_amount": _cumulative_medal_achievement_stamina_reward(int(target)),
			"current": cumulative,
			"target": int(target),
			"completed": cumulative >= target,
			"medal_level": 1,
			"accent": "#f4bf35"
		})
	return milestones


func _completed_achievement_ids() -> Dictionary:
	var completed := {}
	for achievement in _achievement_milestones():
		if bool(achievement.get("completed", false)):
			completed[str(achievement.get("id", ""))] = true
	return completed


func _newly_completed_achievements(before: Dictionary) -> Array:
	var unlocked := []
	for achievement in _achievement_milestones():
		var id := str(achievement.get("id", ""))
		if id.is_empty() or not bool(achievement.get("completed", false)):
			continue
		if not bool(before.get(id, false)):
			unlocked.append(achievement)
	return unlocked


func _visible_achievement_milestones(hide_completed: bool) -> Array:
	var chain_order := []
	var chains := {}
	for achievement in _achievement_milestones():
		var chain_key := str(achievement.get("chain_key", achievement.get("id", "")))
		if chain_key.is_empty():
			continue
		if not chains.has(chain_key):
			chains[chain_key] = []
			chain_order.append(chain_key)
		(chains[chain_key] as Array).append(achievement)
	var visible := []
	for chain_key in chain_order:
		var chain: Array = chains[chain_key]
		var next_achievement := {}
		for achievement in chain:
			if not bool(achievement.get("completed", false)):
				next_achievement = achievement
				break
		if next_achievement.is_empty():
			if hide_completed:
				continue
			next_achievement = chain[chain.size() - 1]
		visible.append(next_achievement)
	return visible


func _skill_level_achievement_targets() -> Array:
	var targets := []
	for level in range(2, 100):
		targets.append(level)
	return targets


func _skill_level_achievement_timer_reward(_target: int) -> float:
	return 0.01


func _skill_level_timer_reduction(skill_id: String) -> float:
	return maxf(0.0, float(_skill_level(skill_id) - 1) * _skill_level_achievement_timer_reward(2))


func _total_level_achievement_stamina_reward(target: int) -> int:
	if target >= 250:
		return 4
	if target >= 100:
		return 3
	if target >= 50:
		return 2
	return 1


func _cumulative_medal_achievement_stamina_reward(target: int) -> int:
	if target >= 500:
		return 5
	if target >= 100:
		return 3
	if target >= 25:
		return 2
	return 1


func _tier_count_achievement_target(tier: int) -> int:
	return maxi(1, tier) * TIER_COUNT_ACHIEVEMENT_STEP


func _tier_count_achievement_stamina_reward(tier: int) -> int:
	if tier >= 9:
		return 3
	if tier >= 5:
		return 2
	return 1


func _mastery_medal_accent(tier: int) -> Color:
	var index := clampi(tier - 1, 0, MASTERY_MEDAL_ACCENTS.size() - 1)
	return MASTERY_MEDAL_ACCENTS[index]


func _stamina_reward_text(amount: int) -> String:
	return "+%s max stamina" % maxi(1, amount)


func _skill_level_achievement_reward_text(skill_name: String, target: int) -> String:
	return "Reward: +%s%% %s activity timer reduction" % [
		int(round(_skill_level_achievement_timer_reward(target) * 100.0)),
		skill_name
	]


func _total_level_achievement_reward_text(target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_total_level_achievement_stamina_reward(target))


func _cumulative_medal_achievement_reward_text(target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_cumulative_medal_achievement_stamina_reward(target))


func _tier_count_achievement_reward_text(tier: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_tier_count_achievement_stamina_reward(tier))


func _achievement_reward_bonus(stat: String, skill_id := "") -> float:
	var total := 0.0
	for achievement in _achievement_milestones():
		if not bool(achievement.get("completed", false)) or str(achievement.get("reward_stat", "")) != stat:
			continue
		var reward_skill_id := str(achievement.get("reward_skill_id", ""))
		if not skill_id.is_empty() and not reward_skill_id.is_empty() and reward_skill_id != skill_id:
			continue
		if skill_id.is_empty() and not reward_skill_id.is_empty():
			continue
		total += float(achievement.get("reward_amount", 0.0))
	return total


func _global_medal_buff_lines() -> String:
	var lines := _active_global_buff_lines()
	if lines.is_empty():
		return "Earn your first Bronze medal to unlock the first global buff."
	return "\n".join(lines)


func _active_global_buff_lines() -> Array:
	var lines := []
	var stamina_bonus := int(round(_global_medal_bonus("max_stamina")))
	var xp_bonus := int(round((_global_medal_bonus("xp_mult") + _ad_bonus_xp_mult()) * 100.0))
	var speed_bonus := int(round((_global_medal_bonus("speed_mult") + _ad_bonus_speed_mult()) * 100.0))
	var success_bonus := int(round(_global_medal_bonus("success_bonus")))
	if stamina_bonus > 0:
		lines.append("+%s max stamina" % stamina_bonus)
	if xp_bonus > 0:
		lines.append("+%s%% XP" % xp_bonus)
	if speed_bonus > 0:
		lines.append("+%s%% speed" % speed_bonus)
	if success_bonus > 0:
		lines.append("+%s%% success" % success_bonus)
	return lines


func _ad_bonus_xp_mult() -> float:
	return AD_BONUS_XP_MULT if ad_bonus_seconds_remaining > 0.0 else 0.0


func _ad_bonus_speed_mult() -> float:
	return AD_BONUS_SPEED_MULT if ad_bonus_seconds_remaining > 0.0 else 0.0


func _shop_bonus_status_text() -> String:
	if ad_bonus_seconds_remaining <= 0.0:
		return "No shop bonus active."
	return "Shop bonus remaining: %s" % _format_duration(ad_bonus_seconds_remaining)


func _on_stamina_gauge_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_set_stamina_gauge_pressed(event.pressed)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		_set_stamina_gauge_pressed(event.pressed)
		get_viewport().set_input_as_handled()


func _is_stamina_gauge_release_event(event: InputEvent) -> bool:
	if not stamina_gauge_press_active:
		return false
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


func _set_stamina_gauge_pressed(pressed: bool) -> void:
	if pressed:
		if current_screen != "skill":
			return
		stamina_gauge_press_active = true
		stamina_gauge_boost_skill_id = selected_skill_id
		stamina_gauge_regen_target_multiplier = STAMINA_GAUGE_REGEN_BOOST_MULT
		_cancel_skill_swipe_feedback(false)
		_pop_stamina_gauge()
	else:
		stamina_gauge_press_active = false
		stamina_gauge_regen_target_multiplier = 1.0


func _process_stamina_gauge_regen_boost(delta: float) -> void:
	if delta <= 0.0:
		return
	if stamina_gauge_press_active and current_screen != "skill":
		_set_stamina_gauge_pressed(false)
	var target := clampf(stamina_gauge_regen_target_multiplier, 1.0, STAMINA_GAUGE_REGEN_BOOST_MULT)
	var weight := 1.0 - exp(-STAMINA_GAUGE_REGEN_EASE_SPEED * delta)
	stamina_gauge_regen_multiplier = lerpf(stamina_gauge_regen_multiplier, target, weight)
	if absf(stamina_gauge_regen_multiplier - target) <= 0.001:
		stamina_gauge_regen_multiplier = target
		if not stamina_gauge_press_active and target <= 1.0:
			stamina_gauge_boost_skill_id = ""


func _pop_stamina_gauge() -> void:
	if detail_regen_circle == null or not is_instance_valid(detail_regen_circle):
		return
	_clear_stamina_gauge_pop_tween()
	detail_regen_circle.pivot_offset = detail_regen_circle.size * 0.5
	detail_regen_circle.scale = Vector2.ONE
	detail_stamina_gauge_pop_tween = create_tween()
	detail_stamina_gauge_pop_tween.tween_property(detail_regen_circle, "scale", STAMINA_GAUGE_POP_SCALE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	detail_stamina_gauge_pop_tween.tween_property(detail_regen_circle, "scale", STAMINA_GAUGE_SETTLE_SCALE, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	detail_stamina_gauge_pop_tween.tween_property(detail_regen_circle, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	detail_stamina_gauge_pop_tween.finished.connect(func(): detail_stamina_gauge_pop_tween = null)


func _clear_stamina_gauge_pop_tween() -> void:
	if detail_stamina_gauge_pop_tween != null and detail_stamina_gauge_pop_tween.is_valid():
		detail_stamina_gauge_pop_tween.kill()
	detail_stamina_gauge_pop_tween = null


func _visible_actions_for_skill(skill_id: String) -> Array:
	var visible_actions := []
	var showed_locked_preview := false
	var skill_level := _skill_level(skill_id)
	for action in actions_by_skill.get(skill_id, []):
		var unlocked := skill_level >= int(action.get("unlock", 1))
		if not unlocked:
			if showed_locked_preview:
				continue
			showed_locked_preview = true
		visible_actions.append(action)
	return visible_actions


func _skill_detail_needs_action_list_refresh() -> bool:
	if current_screen != "skill":
		return false
	if skill_swipe_animating:
		return false
	if not pending_activity_unlock_ceremony.is_empty() or activity_unlock_ceremony_count > 0:
		return false
	var expected_action_ids := []
	for action in _visible_actions_for_skill(selected_skill_id):
		expected_action_ids.append(str(action["id"]))
	if expected_action_ids.size() != detail_rendered_action_ids.size():
		return true
	for i in range(expected_action_ids.size()):
		if str(expected_action_ids[i]) != str(detail_rendered_action_ids[i]):
			return true
	return false


func _latest_unlocked_action_id(skill_id: String) -> String:
	var latest_id := ""
	for action in actions_by_skill.get(skill_id, []):
		if _skill_level(skill_id) >= int(action.get("unlock", 1)):
			latest_id = str(action["id"])
	return latest_id


func _scroll_to_latest_unlocked_activity(animated := true) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	var action_id := _latest_unlocked_action_id(selected_skill_id)
	if action_id.is_empty() or not detail_action_card_nodes.has(action_id):
		return
	await get_tree().process_frame
	if detail_actions_scroll == null or not detail_action_card_nodes.has(action_id):
		return
	var card := detail_action_card_nodes[action_id] as Control
	if card == null:
		return
	var target := maxi(0, int(round(card.position.y - 18.0)))
	detail_actions_scroll.scroll_to_vertical(target, 0.24 if animated else 0.0)


func _scroll_detail_actions_to_top(animated := true) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	detail_actions_scroll.scroll_to_vertical(0, 0.28 if animated else 0.0)


func _restore_detail_actions_scroll(target: int) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	await get_tree().process_frame
	if detail_actions_scroll == null:
		return
	detail_actions_scroll.scroll_to_vertical(target, 0.0)
	_clear_skill_swipe_handoff_cover()


func _update_skill_swipe_feedback(position: Vector2) -> void:
	skill_swipe_last = position
	var delta := position - skill_swipe_start
	var abs_x := absf(delta.x)
	var abs_y := absf(delta.y)
	if not skill_swipe_horizontal:
		if abs_y >= SKILL_SWIPE_FEEDBACK_DEADZONE and abs_y > abs_x * 1.15:
			skill_swipe_tracking = false
			skill_swipe_touch_index = -1
			return
		if abs_x < SKILL_SWIPE_FEEDBACK_DEADZONE:
			return
		if abs_x < abs_y * 1.25:
			return
		skill_swipe_horizontal = true
	if skill_swipe_horizontal:
		_suppress_skill_swipe_action_click()
	var target := _skill_swipe_visual_target()
	if target == null:
		return
	var offset := 1 if delta.x < 0.0 else -1
	_ensure_skill_swipe_preview(offset)
	var direction := 1.0 if delta.x > 0.0 else -1.0
	var visual_distance := _skill_swipe_visual_distance(abs_x)
	_set_skill_swipe_positions(offset, skill_swipe_drag_base_x + direction * visual_distance)


func _skill_swipe_visual_target() -> Control:
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		return skill_swipe_page
	return null


func _skill_swipe_visual_distance(abs_x: float) -> float:
	var drag_distance := clampf(abs_x - SKILL_SWIPE_FEEDBACK_DEADZONE, 0.0, SKILL_SWIPE_MAX_DRAG)
	return minf(_skill_swipe_page_span() * 0.86, drag_distance)


func _skill_swipe_page_span() -> float:
	return _skill_content_width() + SKILL_SWIPE_PAGE_GAP


func _current_skill_swipe_page_x() -> float:
	var target := _skill_swipe_visual_target()
	if target == null:
		return 0.0
	return target.position.x


func _set_skill_swipe_positions(offset: int, current_x: float) -> void:
	var target := _skill_swipe_visual_target()
	if target != null:
		target.position.x = current_x
	if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
		skill_swipe_preview_page.position.x = current_x + signi(offset) * _skill_swipe_page_span()


func _kill_skill_swipe_tween() -> void:
	if skill_swipe_tween != null and skill_swipe_tween.is_valid():
		skill_swipe_tween.kill()
	skill_swipe_tween = null
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""


func _interrupt_skill_swipe_animation_for_input() -> void:
	if not skill_swipe_animating:
		return
	var mode := skill_swipe_animation_mode
	var offset := skill_swipe_preview_offset
	if mode == "settle" and offset != 0 and skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
		_kill_skill_swipe_tween()
		_navigate_skill_page(offset, 0.0, false, false)
		return
	_kill_skill_swipe_tween()


func _clear_skill_swipe_preview() -> void:
	var active_was_cached := false
	for preview in skill_swipe_preview_pages.values():
		var preview_page := preview as Control
		if preview_page != null and is_instance_valid(preview_page):
			if preview_page == skill_swipe_preview_page:
				active_was_cached = true
			preview_page.queue_free()
	skill_swipe_preview_pages.clear()
	skill_swipe_preview_states.clear()
	if not active_was_cached and skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
		skill_swipe_preview_page.queue_free()
	skill_swipe_preview_page = null
	skill_swipe_preview_offset = 0


func _begin_skill_swipe_handoff_cover() -> void:
	_clear_skill_swipe_handoff_cover()
	if skills_page == null or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	if skill_swipe_preview_page == null or not is_instance_valid(skill_swipe_preview_page):
		return
	var page := skill_swipe_preview_page
	for raw_offset in skill_swipe_preview_pages.keys():
		if skill_swipe_preview_pages[raw_offset] == page:
			skill_swipe_preview_pages.erase(raw_offset)
			break
	skill_swipe_preview_states.erase(skill_swipe_preview_offset)

	var cover := Control.new()
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 900
	cover.z_as_relative = false
	cover.clip_contents = true
	skills_page.add_child(cover)

	var holder := Control.new()
	holder.position = skill_swipe_frame.global_position - skills_page.global_position
	holder.size = skill_swipe_frame.size
	holder.custom_minimum_size = skill_swipe_frame.size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(holder)
	page.reparent(holder)
	page.position = Vector2.ZERO
	page.z_index = 0

	skill_swipe_handoff_cover = cover
	skill_swipe_preview_page = null
	skill_swipe_preview_offset = 0


func _clear_skill_swipe_handoff_cover() -> void:
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		skill_swipe_handoff_cover.queue_free()
	skill_swipe_handoff_cover = null


func _park_skill_swipe_preview() -> void:
	if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page) and skill_swipe_preview_offset != 0:
		skill_swipe_preview_page.position.x = signi(skill_swipe_preview_offset) * _skill_swipe_page_span()
	skill_swipe_preview_page = null
	skill_swipe_preview_offset = 0


func _cancel_skill_swipe_feedback(animated := true) -> void:
	skill_swipe_tracking = false
	skill_swipe_horizontal = false
	skill_swipe_touch_index = -1
	skill_swipe_drag_base_x = 0.0
	var target := _skill_swipe_visual_target()
	if target == null:
		_clear_skill_swipe_preview()
		return
	_kill_skill_swipe_tween()
	if animated and absf(target.position.x) > 1.0:
		skill_swipe_animating = true
		skill_swipe_animation_mode = "cancel"
		skill_swipe_tween = create_tween()
		skill_swipe_tween.set_parallel(true)
		skill_swipe_tween.tween_property(target, "position:x", 0.0, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page):
			var preview_exit := signi(skill_swipe_preview_offset) * _skill_swipe_page_span()
			skill_swipe_tween.tween_property(skill_swipe_preview_page, "position:x", preview_exit, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		skill_swipe_tween.finished.connect(func():
			skill_swipe_animating = false
			skill_swipe_animation_mode = ""
			_park_skill_swipe_preview()
		)
	else:
		target.position.x = 0.0
		_park_skill_swipe_preview()


func _finish_skill_swipe(end_position: Vector2) -> void:
	var delta: Vector2 = end_position - skill_swipe_start
	skill_swipe_tracking = false
	skill_swipe_touch_index = -1
	skill_swipe_drag_base_x = 0.0
	if absf(delta.x) < SKILL_SWIPE_THRESHOLD or absf(delta.x) < absf(delta.y) * 1.35:
		_cancel_skill_swipe_feedback(true)
		if skill_swipe_child_click_suppressed:
			call_deferred("_clear_skill_swipe_action_click_suppression")
		return
	_update_skill_swipe_feedback(end_position)
	_commit_skill_swipe(1 if delta.x < 0.0 else -1)
	if skill_swipe_child_click_suppressed:
		call_deferred("_clear_skill_swipe_action_click_suppression")


func _suppress_skill_swipe_action_click() -> void:
	skill_swipe_child_click_suppressed = true
	get_viewport().set_input_as_handled()


func _clear_skill_swipe_action_click_suppression() -> void:
	skill_swipe_child_click_suppressed = false


func _commit_skill_swipe(offset: int) -> void:
	skill_swipe_horizontal = false
	var target := _skill_swipe_visual_target()
	if target == null or skill_swipe_preview_page == null or not is_instance_valid(skill_swipe_preview_page):
		_navigate_skill_page(offset, 0.0, true, false)
		return
	_kill_skill_swipe_tween()
	var span := _skill_swipe_page_span()
	var exit_x := -signi(offset) * span
	skill_swipe_animating = true
	skill_swipe_animation_mode = "settle"
	skill_swipe_tween = create_tween()
	skill_swipe_tween.set_parallel(true)
	skill_swipe_tween.tween_property(target, "position:x", exit_x, SKILL_SWIPE_SETTLE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	skill_swipe_tween.tween_property(skill_swipe_preview_page, "position:x", 0.0, SKILL_SWIPE_SETTLE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	skill_swipe_tween.finished.connect(func():
		skill_swipe_animating = false
		skill_swipe_animation_mode = ""
		skill_swipe_tween = null
		_navigate_skill_page(offset, 0.0, false, false)
	)


func _navigate_skill_page(offset: int, entry_x := 0.0, animate_entry := true, play_click := true) -> void:
	var current_index := _skill_index(selected_skill_id)
	if current_index < 0:
		return
	var skill_count := skill_defs.size()
	if skill_count <= 0:
		return
	var next_index := (current_index + offset) % skill_count
	if next_index < 0:
		next_index += skill_count
	var next_skill_id := str(skill_defs[next_index]["id"])
	selected_skill_id = next_skill_id
	current_screen = "skill"
	if play_click:
		_play(click_player)
	var restore_detail_scroll := detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1
	if not play_click and not animate_entry and absf(entry_x) <= 1.0:
		_begin_skill_swipe_handoff_cover()
	_render_screen(false, restore_detail_scroll)
	_update_ui(0.0, true)
	var target := _skill_swipe_visual_target()
	if target != null:
		if animate_entry and absf(entry_x) > 1.0:
			target.position.x = entry_x
			_kill_skill_swipe_tween()
			skill_swipe_animating = true
			skill_swipe_animation_mode = "entry"
			skill_swipe_tween = create_tween()
			skill_swipe_tween.tween_property(target, "position:x", 0.0, SKILL_SWIPE_SETTLE_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			skill_swipe_tween.finished.connect(func():
				skill_swipe_animating = false
				skill_swipe_animation_mode = ""
			)
		else:
			_kill_skill_swipe_tween()
			target.position.x = 0.0


func _ensure_skill_swipe_preview(offset: int) -> void:
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	if skill_swipe_preview_page != null and is_instance_valid(skill_swipe_preview_page) and skill_swipe_preview_offset == offset:
		return
	_park_skill_swipe_preview()
	var current_index := _skill_index(selected_skill_id)
	if current_index < 0 or skill_defs.is_empty():
		return
	var next_index := (current_index + offset) % skill_defs.size()
	if next_index < 0:
		next_index += skill_defs.size()
	var next_skill_id := str(skill_defs[next_index]["id"])
	var cached_page := skill_swipe_preview_pages.get(offset) as Control
	if cached_page == null or not is_instance_valid(cached_page):
		cached_page = _build_skill_swipe_preview_page(next_skill_id, offset)
		cached_page.position.x = signi(offset) * _skill_swipe_page_span()
		skill_swipe_frame.add_child(cached_page)
		skill_swipe_preview_pages[offset] = cached_page
	skill_swipe_preview_page = cached_page
	skill_swipe_preview_offset = offset
	skill_swipe_preview_page.position.x = signi(offset) * _skill_swipe_page_span()


func _prepare_skill_swipe_preview_pages() -> void:
	if current_screen != "skill" or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	for raw_offset in [-1, 1]:
		var offset := int(raw_offset)
		if skill_swipe_preview_pages.has(offset):
			var existing := skill_swipe_preview_pages[offset] as Control
			if existing != null and is_instance_valid(existing):
				continue
		var current_index := _skill_index(selected_skill_id)
		if current_index < 0 or skill_defs.is_empty():
			return
		var next_index: int = (current_index + offset) % skill_defs.size()
		if next_index < 0:
			next_index += skill_defs.size()
		var next_skill_id := str(skill_defs[next_index]["id"])
		var preview_page := _build_skill_swipe_preview_page(next_skill_id, offset)
		preview_page.position.x = signi(offset) * _skill_swipe_page_span()
		skill_swipe_frame.add_child(preview_page)
		skill_swipe_preview_pages[offset] = preview_page


func _build_skill_swipe_preview_page(skill_id: String, offset := 0) -> Control:
	var content_width := _skill_content_width()
	var state := {
		"skill_id": skill_id,
		"action_cards": []
	}
	var page := VBoxContainer.new()
	state["page"] = page
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.custom_minimum_size.x = content_width
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.z_index = 10

	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 760)
	header.custom_minimum_size.x = content_width
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _summary_style())
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(header)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 66)
	header_margin.add_theme_constant_override("margin_right", 46)
	header_margin.add_theme_constant_override("margin_top", 88)
	header_margin.add_theme_constant_override("margin_bottom", 74)
	header_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_margin)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 66)
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_margin.add_child(header_row)

	var left_block := HBoxContainer.new()
	left_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_block.alignment = BoxContainer.ALIGNMENT_CENTER
	left_block.add_theme_constant_override("separation", 58)
	left_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.add_child(left_block)

	var summary_icon_panel := PanelContainer.new()
	summary_icon_panel.custom_minimum_size = Vector2(344, 344)
	summary_icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	summary_icon_panel.add_theme_stylebox_override("panel", _summary_icon_style())
	summary_icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(summary_icon_panel)
	summary_icon_panel.add_child(_image("res://docs/assets/icons/%s.png" % skill_id, Vector2(304, 304)))

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 22)
	title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_block.add_child(title_stack)
	title_stack.add_child(_label(_skill_name(skill_id), 132, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
	var xp := _xp_progress(skill_id)
	var xp_label := _label("Lv %s - XP %s / %s" % [_skill_level(skill_id), int(xp["current"]), int(xp["needed"])], 66, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_stack.add_child(xp_label)
	state["xp_label"] = xp_label
	var xp_bar := _progress(_skill_theme_color(skill_id), 78, float(xp["pct"]))
	title_stack.add_child(xp_bar)
	state["xp_bar"] = xp_bar

	var regen_circle := RegenCircle.new()
	regen_circle.custom_minimum_size = Vector2(552, 552)
	regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	regen_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	regen_circle.set_theme_color(_skill_theme_color(skill_id))
	header_row.add_child(regen_circle)
	state["regen_circle"] = regen_circle
	_set_regen_circle_for_skill(regen_circle, skill_id, true)
	call_deferred("_set_regen_circle_for_skill", regen_circle, skill_id, true)

	var divider := Control.new()
	divider.custom_minimum_size = Vector2(0, 24)
	divider.custom_minimum_size.x = content_width
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(divider)

	var preview_scroll := ScrollContainer.new()
	preview_scroll.custom_minimum_size.x = content_width
	preview_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	preview_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	preview_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(preview_scroll)
	state["actions_scroll"] = preview_scroll

	var preview_stack := VBoxContainer.new()
	preview_stack.custom_minimum_size.x = content_width
	preview_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_stack.add_theme_constant_override("separation", 56)
	preview_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_scroll.add_child(preview_stack)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 12)
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(top_spacer)

	for action in _visible_actions_for_skill(skill_id):
		var card_result := _skill_swipe_preview_action_card(skill_id, action, content_width)
		preview_stack.add_child(card_result["root"])
		(state["action_cards"] as Array).append(card_result["card"])
	var scroll_bottom_spacer := Control.new()
	scroll_bottom_spacer.custom_minimum_size = Vector2(0, 180)
	scroll_bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_stack.add_child(scroll_bottom_spacer)
	if offset != 0:
		skill_swipe_preview_states[offset] = state
	_sync_skill_swipe_preview_scroll_state(state)
	_update_skill_swipe_preview_states(0.0, true)
	return page


func _skill_swipe_preview_action_card(skill_id: String, action: Dictionary, content_width: float) -> Dictionary:
	var unlocked := _skill_level(skill_id) >= int(action.get("unlock", 1))
	var card_root := Control.new()
	card_root.custom_minimum_size = Vector2(content_width, ACTION_CARD_HEIGHT)
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pop_card := Control.new()
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = ACTION_CARD_POP_GUTTER
	pop_card.offset_right = -ACTION_CARD_POP_GUTTER
	pop_card.offset_top = 0.0
	pop_card.offset_bottom = 0.0
	pop_card.clip_contents = false
	pop_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(pop_card)

	var bg := RoundedTextureRect.new()
	bg.texture = _texture(str(action["bg"]))
	bg.modulate = Color.WHITE
	bg.radius = 66.0
	bg.crop_left = 0.025 if skill_id == "fishing" else 0.0
	bg.crop_right = 0.015 if skill_id == "fishing" else 0.0
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	pop_card.add_child(bg)

	var shade := Panel.new()
	shade.add_theme_stylebox_override("panel", _activity_shade_style(0.50))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.visible = false
	shade.z_index = 224
	pop_card.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 54)
	margin.add_theme_constant_override("margin_right", 54)
	margin.add_theme_constant_override("margin_top", 46)
	margin.add_theme_constant_override("margin_bottom", 126)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.z_index = 200
	pop_card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 56)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var art_slot := MarginContainer.new()
	art_slot.add_theme_constant_override("margin_top", 42)
	art_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(art_slot)
	var art_panel := Panel.new()
	art_panel.custom_minimum_size = Vector2(410, 410)
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_panel.add_theme_stylebox_override("panel", _action_art_style())
	art_panel.modulate = Color.WHITE
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_slot.add_child(art_panel)
	var art := _image(str(action["art"]), Vector2(356, 356))
	art.position = Vector2(27, 27)
	art_panel.add_child(art)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 38)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)

	var name := _label(str(action["name"]), 82, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name.add_theme_color_override("font_outline_color", COLOR_INK)
	name.add_theme_constant_override("outline_size", 34)
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(name)

	var stat_row := HBoxContainer.new()
	stat_row.add_theme_constant_override("separation", 28)
	stat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(stat_row)
	var xp_label := _action_stat_label("")
	stat_row.add_child(_action_stat_box(xp_label))
	var stamina_label := _action_stat_label("")
	stat_row.add_child(_action_stat_box(stamina_label))
	var time_label := _action_stat_label("")
	stat_row.add_child(_action_stat_box(time_label))
	var success_label := _action_stat_label("")
	stat_row.add_child(_action_stat_box(success_label))

	var medal := TextureRect.new()
	medal.anchor_left = 0.0
	medal.anchor_right = 0.0
	medal.anchor_top = 0.0
	medal.anchor_bottom = 0.0
	medal.offset_left = 300
	medal.offset_right = 490
	medal.offset_top = -62
	medal.offset_bottom = 128
	medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	medal.z_index = 21
	art_panel.add_child(medal)
	var mastery_progress := _progress(Color("#f4bf35"), 56)
	mastery_progress.easing_speed = 5.0
	mastery_progress.z_index = 20
	copy.add_child(mastery_progress)

	var progress := ActivityProgressRail.new()
	progress.fill_color = _skill_theme_color(skill_id)
	progress.anchor_left = 0.0
	progress.anchor_right = 1.0
	progress.anchor_top = 1.0
	progress.anchor_bottom = 1.0
	progress.offset_left = ACTION_PROGRESS_RAIL_INSET
	progress.offset_right = -ACTION_PROGRESS_RAIL_INSET
	progress.offset_top = -126
	progress.offset_bottom = -ACTION_PROGRESS_RAIL_INSET
	progress.z_index = 152
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(progress)

	var border := ActivityCardBorder.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = 220
	pop_card.add_child(border)
	var lock_overlay := _activity_lock_overlay(pop_card, int(action.get("unlock", 1)))
	var card := {
		"root": card_root,
		"pop": pop_card,
		"button": null,
		"bg": bg,
		"shade": shade,
		"art_panel": art_panel,
		"art": art,
		"xp": xp_label,
		"stamina": stamina_label,
		"time": time_label,
		"success": success_label,
		"status": null,
		"medal": medal,
		"mastery": mastery_progress,
		"progress": progress,
		"border": border,
		"lock_overlay": lock_overlay,
		"action": action,
		"medal_destination": Vector2(medal.offset_left, medal.offset_top)
	}
	return {"root": card_root, "card": card}


func _activity_lock_overlay(parent: Control, unlock_level: int) -> Dictionary:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.clip_contents = true
	overlay.z_index = 225
	parent.add_child(overlay)

	var group := ActivityLockRig.new()
	group.setup(_texture(UNLOCK_CHAIN_LINK_TEXTURE), _texture(UNLOCK_PADLOCK_TEXTURE), unlock_level, app_bold_font, app_font)
	group.set_anchors_preset(Control.PRESET_FULL_RECT)
	group.clip_contents = true
	group.chain_moved.connect(_play_chain_move_jingle_mix)
	group.padlock_clicked.connect(_play_padlock_cluster_sfx)
	overlay.add_child(group)

	return {
		"root": overlay,
		"group": group
	}


func _activity_lock_piece(path: String, minimum_size: Vector2) -> TextureRect:
	var piece := TextureRect.new()
	piece.texture = _texture(path)
	piece.custom_minimum_size = minimum_size
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return piece


func _sync_activity_lock_overlay(card: Dictionary, action: Dictionary, unlocked: bool) -> void:
	var overlay := card.get("lock_overlay", {}) as Dictionary
	if overlay.is_empty():
		return
	var overlay_root := overlay.get("root") as Control
	if overlay_root == null:
		return
	var ceremony_active := bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false))
	overlay_root.visible = (not unlocked) or ceremony_active
	var rig := overlay.get("group") as ActivityLockRig
	if rig != null:
		rig.set_unlock_level(int(action.get("unlock", 1)))


func _reset_activity_lock_overlay_pieces(card: Dictionary) -> void:
	var overlay := card.get("lock_overlay", {}) as Dictionary
	for key in ["group"]:
		var piece := overlay.get(key) as Control
		if piece == null:
			continue
		piece.visible = true
		piece.modulate = Color.WHITE
		piece.scale = Vector2.ONE
		piece.rotation = 0.0
		piece.pivot_offset = piece.size * 0.5


func _queue_activity_unlock_ceremony(skill_id: String, old_level: int, new_level: int) -> void:
	if current_screen != "skill" or selected_skill_id != skill_id or new_level <= old_level:
		return
	var unlocked_ids := []
	var next_locked_id := ""
	for action in actions_by_skill.get(skill_id, []):
		var unlock_level := int(action.get("unlock", 1))
		var action_id := str(action.get("id", ""))
		if unlock_level > old_level and unlock_level <= new_level:
			unlocked_ids.append(action_id)
		elif unlock_level > new_level and next_locked_id.is_empty():
			next_locked_id = action_id
	if unlocked_ids.is_empty():
		return
	pending_activity_unlock_ceremony = {
		"skill_id": skill_id,
		"unlocked": unlocked_ids,
		"preview": next_locked_id
	}


func _pending_activity_unlock_matches(action_id: String) -> bool:
	if pending_activity_unlock_ceremony.is_empty():
		return false
	if str(pending_activity_unlock_ceremony.get("skill_id", "")) != selected_skill_id:
		return false
	var unlocked_ids := pending_activity_unlock_ceremony.get("unlocked", []) as Array
	return unlocked_ids.has(action_id)


func _pending_activity_unlock_preview_matches(action_id: String) -> bool:
	if pending_activity_unlock_ceremony.is_empty():
		return false
	if str(pending_activity_unlock_ceremony.get("skill_id", "")) != selected_skill_id:
		return false
	return str(pending_activity_unlock_ceremony.get("preview", "")) == action_id


func _play_pending_activity_unlock_ceremony() -> void:
	if pending_activity_unlock_ceremony.is_empty():
		return
	if str(pending_activity_unlock_ceremony.get("skill_id", "")) != selected_skill_id:
		pending_activity_unlock_ceremony = {}
		return
	var unlocked_ids := pending_activity_unlock_ceremony.get("unlocked", []) as Array
	var started_ceremony := false
	for raw_action_id in unlocked_ids:
		var action_id := str(raw_action_id)
		var key := _action_key(selected_skill_id, action_id)
		if not action_cards.has(key):
			continue
		var card := action_cards[key] as Dictionary
		if not bool(card.get("unlock_ceremony_active", false)):
			card["unlock_ceremony_pending"] = true
			_play_activity_unlock_ceremony(card)
			started_ceremony = true
	var preview_id := str(pending_activity_unlock_ceremony.get("preview", ""))
	activity_unlock_preview_after_ceremony_id = preview_id
	pending_activity_unlock_ceremony = {}
	if not started_ceremony:
		_refresh_skill_detail_after_activity_unlock_ceremony()
	elif not preview_id.is_empty():
		var preview_key := _action_key(selected_skill_id, preview_id)
		if action_cards.has(preview_key):
			var preview_card := action_cards[preview_key] as Dictionary
			if bool(preview_card.get("fade_in_pending", false)):
				_play_activity_preview_fade_in(preview_card)


func _play_activity_unlock_ceremony(card: Dictionary) -> void:
	card["unlock_ceremony_pending"] = false
	card["unlock_ceremony_active"] = true
	activity_unlock_ceremony_count += 1
	_reset_activity_lock_overlay_pieces(card)
	var overlay := card.get("lock_overlay", {}) as Dictionary
	var overlay_root := overlay.get("root") as Control
	var group := overlay.get("group") as Control
	var button := card.get("button") as Button
	if overlay_root == null or group == null:
		card["unlock_ceremony_active"] = false
		activity_unlock_ceremony_count = maxi(0, activity_unlock_ceremony_count - 1)
		if button != null:
			button.disabled = false
		return
	overlay_root.visible = true
	if button != null:
		button.disabled = true
	if group is ActivityLockRig:
		(group as ActivityLockRig).unlock_impulse()

	_play_chain_fall_sfx_sequence()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(group, "position", group.position + Vector2(0, 650), ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(group, "rotation", 0.12, ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(group, "modulate:a", 0.0, ACTIVITY_UNLOCK_CHAIN_FADE_SECONDS).set_delay(ACTIVITY_UNLOCK_CHAIN_FADE_DELAY)
	tween.finished.connect(func():
		overlay_root.visible = false
		card["unlock_ceremony_active"] = false
		if button != null:
			button.disabled = false
		activity_unlock_ceremony_count = maxi(0, activity_unlock_ceremony_count - 1)
		if activity_unlock_ceremony_count <= 0:
			call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
	)


func _play_activity_preview_fade_in(card: Dictionary) -> void:
	card["fade_in_pending"] = false
	var root := card.get("root") as Control
	if root == null:
		return
	var target_y := root.position.y
	root.position.y = target_y + 34.0
	root.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(root, "position:y", target_y, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _refresh_skill_detail_after_activity_unlock_ceremony() -> void:
	if current_screen != "skill":
		activity_unlock_preview_after_ceremony_id = ""
		return
	var preview_id := activity_unlock_preview_after_ceremony_id
	var restore_scroll := detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1
	_render_screen(false, restore_scroll)
	_update_ui(0.0, true)
	if preview_id.is_empty():
		return
	call_deferred("_play_activity_preview_fade_in_by_id", preview_id)


func _play_activity_preview_fade_in_by_id(action_id: String) -> void:
	if action_id.is_empty():
		return
	var key := _action_key(selected_skill_id, action_id)
	if not action_cards.has(key):
		activity_unlock_preview_after_ceremony_id = ""
		return
	var card := action_cards[key] as Dictionary
	if bool(card.get("fade_in_pending", false)):
		_play_activity_preview_fade_in(card)
	activity_unlock_preview_after_ceremony_id = ""


func _skill_index(skill_id: String) -> int:
	for i in range(skill_defs.size()):
		if str(skill_defs[i]["id"]) == skill_id:
			return i
	return -1


func _process_ad_bonus(delta: float) -> void:
	if ad_bonus_seconds_remaining <= 0.0:
		ad_bonus_seconds_remaining = 0.0
		return
	ad_bonus_seconds_remaining = maxf(0.0, ad_bonus_seconds_remaining - delta)


func _process_action(delta: float) -> void:
	if running_skill_id.is_empty():
		return
	var action := _action_data(running_skill_id, running_action_id)
	if action.is_empty():
		running_skill_id = ""
		running_action_id = ""
		action_progress = 0.0
		return
	var cost := _effective_stamina(action)
	if _stamina(running_skill_id) < cost:
		last_result = "Out of stamina."
		running_skill_id = ""
		running_action_id = ""
		action_progress = 0.0
		_update_ui(0.0, false)
		return
	action_progress += delta / _effective_seconds(running_skill_id, action)
	if action_progress < 1.0:
		return
	action_progress = 0.0
	stamina[running_skill_id] = _stamina(running_skill_id) - cost
	var reward_key := _action_key(running_skill_id, running_action_id)
	var old_mastery_level := _mastery_level(running_skill_id, running_action_id)
	var mastery_reward := _mastery_xp_reward(action)
	var tiers_unlocked_before := {}
	for tier in range(1, MASTERY_MAX_LEVEL + 1):
		tiers_unlocked_before[tier] = _global_medal_tier_unlocked(tier)
	var completed_achievements_before := _completed_achievement_ids()
	var old_skill_level := _skill_level(running_skill_id)
	var success := randf() * 100.0 <= _success_chance(running_skill_id, action)
	if success:
		var streak_step := _record_successful_activity_completion(reward_key)
		var streak_bonus := streak_step == ACTIVITY_STREAK_BONUS_STEP
		var xp_reward := _effective_xp(action)
		if streak_bonus:
			xp_reward *= 2
		skills[running_skill_id]["xp"] = int(skills[running_skill_id]["xp"]) + xp_reward
		_add_mastery_xp(running_skill_id, running_action_id, mastery_reward)
		var new_mastery_level := _mastery_level(running_skill_id, running_action_id)
		_recalculate_level(running_skill_id)
		var new_skill_level := _skill_level(running_skill_id)
		_queue_activity_unlock_ceremony(running_skill_id, old_skill_level, new_skill_level)
		last_result = "+%s XP from %s." % [xp_reward, action["name"]]
		if streak_bonus:
			last_result += " Fifth repeat: double XP."
		var new_global_buffs := _new_global_medal_buff_messages(old_mastery_level, new_mastery_level, tiers_unlocked_before)
		if not new_global_buffs.is_empty():
			last_result += " " + " ".join(new_global_buffs)
		_play_action_feedback(reward_key, true, xp_reward, mastery_reward)
		for achievement in _newly_completed_achievements(completed_achievements_before):
			_show_achievement_unlocked(achievement)
		_play_activity_success_sound(streak_step, new_mastery_level > old_mastery_level, streak_bonus)
	else:
		_reset_activity_completion_streak()
		var failure_mastery_reward := 0.0 if _would_mastery_reward_medal_up(running_skill_id, running_action_id, mastery_reward) else mastery_reward
		if failure_mastery_reward > 0:
			_add_mastery_xp(running_skill_id, running_action_id, failure_mastery_reward)
		var failure_mastery_level := _mastery_level(running_skill_id, running_action_id)
		last_result = "Failed %s. +%s mastery." % [action["name"], failure_mastery_reward]
		if failure_mastery_reward <= 0:
			last_result += " Next medal needs a success."
		var failure_global_buffs := _new_global_medal_buff_messages(old_mastery_level, failure_mastery_level, tiers_unlocked_before)
		if not failure_global_buffs.is_empty():
			last_result += " " + " ".join(failure_global_buffs)
		_play_action_feedback(reward_key, false, 0, failure_mastery_reward)
		for achievement in _newly_completed_achievements(completed_achievements_before):
			_show_achievement_unlocked(achievement)
		_play(failure_player)
	if _stamina(running_skill_id) < cost:
		running_skill_id = ""
		running_action_id = ""
	_update_ui(0.0, false)


func _regen_stamina(delta: float) -> void:
	var max_stamina := _max_stamina()
	for def in skill_defs:
		var skill_id := str(def["id"])
		if _stamina(skill_id) >= max_stamina:
			stamina_bank[skill_id] = 0.0
			continue
		var regen_delta := delta
		if skill_id == stamina_gauge_boost_skill_id:
			regen_delta *= stamina_gauge_regen_multiplier
		stamina_bank[skill_id] = float(stamina_bank.get(skill_id, 0.0)) + regen_delta
		if float(stamina_bank[skill_id]) >= STAMINA_REGEN_SECONDS:
			var gained := int(floor(float(stamina_bank[skill_id]) / STAMINA_REGEN_SECONDS))
			stamina[skill_id] = mini(max_stamina, _stamina(skill_id) + gained)
			stamina_bank[skill_id] = fmod(float(stamina_bank[skill_id]), STAMINA_REGEN_SECONDS)


func _regen_ring_ease(raw_value: float) -> float:
	return clampf(raw_value, 0.0, 1.0)


func _set_regen_circle_for_skill(circle: RegenCircle, skill_id: String, instant := false) -> void:
	if circle == null or not is_instance_valid(circle):
		return
	var maximum := _max_stamina()
	var stamina_value := _stamina(skill_id)
	var circle_value := 1.0
	if stamina_value < maximum:
		circle_value = float(stamina_bank.get(skill_id, 0.0)) / STAMINA_REGEN_SECONDS
	circle.set_theme_color(_skill_theme_color(skill_id))
	circle.set_stamina(stamina_value, maximum, instant, circle_value)
	circle.set_value(_regen_ring_ease(circle_value), instant)


func _start_action(skill_id: String, action_id: String) -> void:
	if skill_swipe_child_click_suppressed:
		return
	if detail_actions_scroll != null and detail_actions_scroll.is_child_click_suppressed():
		return
	var action := _action_data(skill_id, action_id)
	if action.is_empty() or _skill_level(skill_id) < int(action["unlock"]):
		return
	if running_skill_id == skill_id and running_action_id == action_id:
		running_skill_id = ""
		running_action_id = ""
		action_progress = 0.0
		_set_result("%s stopped." % action["name"])
		_update_ui(0.0, false)
		return
	if _stamina(skill_id) < _effective_stamina(action):
		_set_result("Not enough stamina.")
		_play(failure_player)
		return
	selected_skill_id = skill_id
	running_skill_id = skill_id
	running_action_id = action_id
	action_progress = 0.0
	_pop_activity_button(_action_key(skill_id, action_id))
	_set_result("%s started." % action["name"])


func _pop_activity_button(action_key: String) -> void:
	if not action_cards.has(action_key):
		return
	var card := action_cards[action_key].get("pop") as Control
	if card == null:
		return
	if action_pop_tweens.has(action_key):
		var existing := action_pop_tweens[action_key] as Tween
		if existing != null and existing.is_valid():
			existing.kill()
	card.scale = Vector2.ONE
	card.pivot_offset = card.size * 0.5
	var tween := create_tween()
	action_pop_tweens[action_key] = tween
	tween.tween_property(card, "scale", Vector2(1.035, 1.035), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2(0.985, 0.985), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): action_pop_tweens.erase(action_key))


func _clear_action_pop_tweens() -> void:
	for tween in action_pop_tweens.values():
		if tween != null and (tween as Tween).is_valid():
			(tween as Tween).kill()
	action_pop_tweens.clear()


func _select_skill(skill_id: String) -> void:
	selected_skill_id = skill_id
	current_screen = "skill"
	_play(click_player)
	_render_screen(true)


func _show_home() -> void:
	current_screen = "home"
	_play(click_player)
	_render_screen()


func _show_skills() -> void:
	current_screen = "menu"
	_play(click_player)
	_render_screen()


func _show_shop() -> void:
	current_screen = "shop"
	_play(click_player)
	_render_screen()


func _show_settings() -> void:
	current_screen = "settings"
	_play(click_player)
	_render_screen()


func _back_to_skills() -> void:
	current_screen = "menu"
	_play(click_player)
	_render_screen()


func _open_settings() -> void:
	_show_settings()


func _on_settings_overlay_gui_input(event: InputEvent) -> void:
	if _event_is_outside_panel_press(event, settings_panel):
		_close_settings()


func _on_achievements_overlay_gui_input(event: InputEvent) -> void:
	var panel := achievements_panel if achievements_panel != null and is_instance_valid(achievements_panel) else achievements_panel_frame
	if _event_is_outside_panel_press(event, panel):
		_close_achievements_overlay()


func _event_is_outside_panel_press(event: InputEvent, panel: Control) -> bool:
	if panel == null or not is_instance_valid(panel):
		return false
	var panel_rect := panel.get_global_rect()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		return not panel_rect.has_point(event.global_position)
	if event is InputEventScreenTouch and event.pressed:
		return not panel_rect.has_point(event.position)
	return false


func _close_settings() -> void:
	if settings_overlay != null and settings_overlay.visible:
		settings_overlay.visible = false
	else:
		_show_home()


func _open_achievements_overlay() -> void:
	achievements_modal_tab = "achievements"
	if achievements_overlay != null:
		achievements_overlay.visible = true
	_rebuild_achievements_overlay()
	_play(click_player)


func _close_achievements_overlay() -> void:
	if achievements_overlay != null:
		achievements_overlay.visible = false
	_play(click_player)


func _set_achievements_modal_tab(tab: String) -> void:
	achievements_modal_tab = tab
	_rebuild_achievements_overlay()
	_play(click_player)


func _rebuild_achievements_overlay() -> void:
	if achievements_list_stack == null:
		return
	_clear(achievements_list_stack)
	var active_buffs := _active_global_buff_lines() if achievements_modal_tab == "buffs" else []
	_apply_achievements_modal_layout(active_buffs.size())
	for key in achievements_tab_buttons.keys():
		var button := achievements_tab_buttons[key] as Button
		if button != null:
			var active := str(key) == achievements_modal_tab
			button.add_theme_stylebox_override("normal", _button_style(COLOR_GOLD if active else COLOR_PANEL, BUTTON_BORDER, 48))
			button.add_theme_stylebox_override("hover", _button_style(COLOR_GOLD, BUTTON_BORDER, 48))
			button.add_theme_stylebox_override("pressed", _button_style(COLOR_GOLD.darkened(0.08), BUTTON_BORDER, 48))
	if achievements_hide_completed != null:
		achievements_hide_completed.visible = achievements_modal_tab == "achievements"
	if achievements_modal_tab == "buffs":
		_rebuild_global_buffs_tab(active_buffs)
	else:
		_rebuild_achievement_log_tab()


func _apply_achievements_modal_layout(buff_count: int) -> void:
	if achievements_panel == null or achievements_scroll == null:
		return
	var modal_size := ACHIEVEMENTS_MODAL_SIZE
	var scroll_height := ACHIEVEMENTS_MODAL_SCROLL_HEIGHT
	if achievements_modal_tab != "buffs":
		_fit_achievements_modal(modal_size)
		achievements_scroll.custom_minimum_size = Vector2(0, scroll_height)
		return
	var visible_rows := maxi(1, buff_count)
	var modal_height := clampf(
		GLOBAL_BUFFS_MODAL_BASE_HEIGHT + float(visible_rows) * GLOBAL_BUFFS_MODAL_ROW_HEIGHT,
		GLOBAL_BUFFS_MODAL_MIN_HEIGHT,
		GLOBAL_BUFFS_MODAL_MAX_HEIGHT
	)
	modal_size = Vector2(ACHIEVEMENTS_MODAL_SIZE.x, modal_height)
	scroll_height = maxf(520.0, modal_height - GLOBAL_BUFFS_MODAL_SCROLL_CHROME)
	_fit_achievements_modal(modal_size)
	achievements_scroll.custom_minimum_size = Vector2(0, scroll_height)


func _fit_achievements_modal(modal_size: Vector2) -> void:
	var fitted_scale := _fit_scale_to_canvas(ACHIEVEMENTS_MODAL_SIZE, ACHIEVEMENTS_MODAL_VIEWPORT_MARGIN)
	var fitted_frame_size := ACHIEVEMENTS_MODAL_SIZE * fitted_scale
	if achievements_panel_frame != null:
		achievements_panel_frame.custom_minimum_size = fitted_frame_size
		achievements_panel_frame.size = fitted_frame_size
	achievements_panel.custom_minimum_size = modal_size
	achievements_panel.size = modal_size
	achievements_panel.position = Vector2.ZERO
	achievements_panel.scale = Vector2(fitted_scale, fitted_scale)


func _fit_scale_to_canvas(base_size: Vector2, margin: Vector2) -> float:
	var canvas_size := _current_canvas_size()
	var available := Vector2(
		maxf(1.0, canvas_size.x - margin.x * 2.0),
		maxf(1.0, canvas_size.y - margin.y * 2.0)
	)
	return clampf(minf(available.x / base_size.x, available.y / base_size.y), 0.1, 1.0)


func _current_canvas_size() -> Vector2:
	var canvas_size := size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		var viewport := get_viewport()
		if viewport != null:
			canvas_size = viewport.get_visible_rect().size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		canvas_size = BASE_CANVAS
	return canvas_size


func _rebuild_achievement_log_tab() -> void:
	var hide_completed := achievements_hide_completed != null and achievements_hide_completed.button_pressed
	var any_visible := false
	for achievement in _visible_achievement_milestones(hide_completed):
		var completed := bool(achievement["completed"])
		any_visible = true
		achievements_list_stack.add_child(_achievement_log_card(achievement))
	if not any_visible:
		achievements_list_stack.add_child(_label("Everything visible here is complete.", 64, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))


func _rebuild_global_buffs_tab(buffs: Array) -> void:
	if buffs.is_empty():
		achievements_list_stack.add_child(_label("No global buffs earned yet.", 64, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		return
	achievements_list_stack.add_child(_label("Active Global Buffs", 70, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT))
	achievements_list_stack.add_child(_label("All earned medal bonuses combined.", 44, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	for buff_text in buffs:
		achievements_list_stack.add_child(_global_buff_list_row(str(buff_text)))


func _global_buff_list_row(text: String) -> Control:
	var row := MarginContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("margin_left", 10)
	row.add_theme_constant_override("margin_right", 10)
	row.add_theme_constant_override("margin_top", 2)
	row.add_theme_constant_override("margin_bottom", 2)
	var label := _label("- %s" % text, 52, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	return row


func _achievement_art(achievement: Dictionary) -> Control:
	var art := Control.new()
	art.custom_minimum_size = Vector2(188, 152)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match str(achievement.get("kind", "")):
		"skill_level":
			var skill_id := str(achievement.get("skill_id", ""))
			_add_achievement_art_image(art, _texture(_skill_icon_path(skill_id)), Vector2(6, -7), Vector2(166, 166), 1)
		"action_medal":
			_add_achievement_art_image(art, _texture(str(achievement.get("art", ""))), Vector2(0, 6), Vector2(132, 132), 1)
			_add_achievement_art_image(art, _achievement_medal_texture(int(achievement.get("medal_level", 1))), Vector2(96, 58), Vector2(86, 86), 2)
		"total_level":
			_add_achievement_art_image(art, _texture(ACHIEVEMENT_TOTAL_LEVEL_ART), Vector2(6, -7), Vector2(166, 166), 1)
		"tier_count":
			var tier := int(achievement.get("tier", achievement.get("medal_level", 1)))
			var levels := []
			for _i in range(_same_tier_achievement_medal_count(int(achievement.get("target", 1)))):
				levels.append(tier)
			_populate_achievement_medal_cluster(art, levels)
		"cumulative_medals":
			_add_achievement_art_image(art, _texture(ACHIEVEMENT_CUMULATIVE_MEDALS_ART), Vector2(6, -7), Vector2(166, 166), 1)
		_:
			_add_achievement_art_image(art, _texture(ACHIEVEMENT_CREDIT_ART), Vector2(12, 0), Vector2(154, 144), 1)
	return art


func _add_achievement_art_image(parent: Control, texture: Texture2D, position: Vector2, size: Vector2, z_index: int) -> void:
	var image := _image_from_texture(texture, size)
	image.position = position
	image.size = size
	image.z_index = z_index
	parent.add_child(image)


func _skill_icon_path(skill_id: String) -> String:
	return "res://docs/assets/icons/%s.png" % skill_id


func _same_tier_achievement_medal_count(target: int) -> int:
	if target <= 1:
		return 1
	if target <= 10:
		return 3
	if target <= 25:
		return 5
	if target <= 50:
		return 7
	return 9


func _cumulative_achievement_medal_levels(target: int) -> Array:
	var count := 3
	if target >= 1000:
		count = 10
	elif target >= 500:
		count = 8
	elif target >= 250:
		count = 7
	elif target >= 100:
		count = 6
	elif target >= 50:
		count = 5
	elif target >= 25:
		count = 4
	var levels := []
	for i in range(count):
		levels.append((i % MASTERY_MAX_LEVEL) + 1)
	return levels


func _populate_achievement_medal_cluster(parent: Control, levels: Array) -> void:
	var count := levels.size()
	var positions := _achievement_medal_cluster_positions(count)
	var medal_size := 144.0
	if count >= 9:
		medal_size = 64.0
	elif count >= 7:
		medal_size = 72.0
	elif count >= 5:
		medal_size = 82.0
	elif count >= 3:
		medal_size = 92.0
	for i in range(count):
		var center: Vector2 = positions[i] if i < positions.size() else Vector2(89, 72)
		var icon_size := Vector2(medal_size, medal_size)
		_add_achievement_art_image(parent, _achievement_medal_texture(int(levels[i])), center - icon_size * 0.5, icon_size, i + 1)


func _achievement_medal_cluster_positions(count: int) -> Array:
	if count <= 1:
		return [Vector2(89, 72)]
	if count <= 3:
		return [Vector2(56, 84), Vector2(89, 50), Vector2(122, 84)]
	if count <= 5:
		return [Vector2(45, 86), Vector2(72, 52), Vector2(106, 52), Vector2(133, 86), Vector2(89, 104)]
	if count <= 7:
		return [Vector2(42, 86), Vector2(64, 54), Vector2(92, 43), Vector2(120, 54), Vector2(142, 86), Vector2(73, 110), Vector2(111, 110)]
	if count <= 8:
		return [Vector2(36, 88), Vector2(58, 56), Vector2(84, 42), Vector2(112, 42), Vector2(138, 56), Vector2(158, 88), Vector2(72, 112), Vector2(116, 112)]
	return [Vector2(30, 88), Vector2(50, 60), Vector2(72, 42), Vector2(98, 38), Vector2(124, 42), Vector2(146, 60), Vector2(164, 88), Vector2(65, 112), Vector2(98, 118), Vector2(131, 112)]


func _achievement_progress_pct(achievement: Dictionary) -> float:
	var target := maxi(1, int(achievement.get("target", 1)))
	var current := clampi(int(achievement.get("current", 0)), 0, target)
	return clampf(float(current) / float(target) * 100.0, 0.0, 100.0)


func _achievement_log_card(achievement: Dictionary) -> Control:
	var completed := bool(achievement.get("completed", false))
	var accent := Color(str(achievement.get("accent", "#f4bf35")))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _achievement_card_style(Color("#fffdf8") if completed else Color("#fff6e1"), 34, 28))
	card.modulate = Color.WHITE if completed else Color(1, 1, 1, 0.78)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	card.add_child(stack)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	stack.add_child(row)
	row.add_child(_achievement_art(achievement))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 8)
	row.add_child(copy)
	var title_label := _label(str(achievement.get("title", "")), 54, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(title_label)
	var subtitle_label := _label(str(achievement.get("subtitle", "")), 44, accent if completed else COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(subtitle_label)
	var reward_label := _label(str(achievement.get("reward", "")), 40, COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(reward_label)
	stack.add_child(_progress(accent, 28, _achievement_progress_pct(achievement)))
	return card


func _toggle_mute() -> void:
	is_muted = not is_muted
	AudioServer.set_bus_mute(0, is_muted)
	_update_ui(0.0, true)


func _init_ads() -> void:
	ad_reward_listener.on_user_earned_reward = _on_rewarded_ad_user_earned_reward
	ad_load_callback.on_ad_loaded = _on_rewarded_ad_loaded
	ad_load_callback.on_ad_failed_to_load = _on_rewarded_ad_failed_to_load
	ad_content_callback.on_ad_dismissed_full_screen_content = _on_rewarded_ad_dismissed
	ad_content_callback.on_ad_failed_to_show_full_screen_content = _on_rewarded_ad_failed_to_show
	ad_content_callback.on_ad_showed_full_screen_content = _on_rewarded_ad_showed
	if _ads_supported() and not _rewarded_ad_unit_id().is_empty():
		MobileAds.initialize()
		_load_rewarded_ad(false)


func _ads_supported() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMobRewardedAd")


func _rewarded_ad_unit_id() -> String:
	if OS.get_name() != "Android":
		return ""
	if OS.is_debug_build():
		return AD_TEST_UNIT_ANDROID_REWARDED
	return AD_LIVE_UNIT_ANDROID_REWARDED


func _load_rewarded_ad(show_when_loaded: bool) -> void:
	var unit_id := _rewarded_ad_unit_id()
	if unit_id.is_empty():
		_set_result("Ad Not Configured")
		return
	if not _ads_supported():
		_set_result("Ads need an Android build.")
		return
	if ad_loading:
		ad_show_after_load = ad_show_after_load or show_when_loaded
		if show_when_loaded:
			_set_result("Ad loading...")
		return
	ad_loading = true
	ad_show_after_load = show_when_loaded
	if show_when_loaded:
		_set_result("Ad loading...")
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), ad_load_callback)


func _show_rewarded_ad() -> void:
	if rewarded_ad == null:
		_load_rewarded_ad(true)
		return
	ad_showing = true
	ad_reward_earned_for_show = false
	_set_result("Opening ad...")
	rewarded_ad.show(ad_reward_listener)


func _destroy_rewarded_ad() -> void:
	if rewarded_ad != null:
		rewarded_ad.destroy()
		rewarded_ad = null


func _on_rewarded_ad_loaded(ad: RewardedAd) -> void:
	ad_loading = false
	_destroy_rewarded_ad()
	rewarded_ad = ad
	rewarded_ad.full_screen_content_callback = ad_content_callback
	if ad_show_after_load:
		ad_show_after_load = false
		_show_rewarded_ad()


func _on_rewarded_ad_failed_to_load(error: LoadAdError) -> void:
	var should_report := ad_show_after_load
	ad_loading = false
	ad_show_after_load = false
	if not should_report:
		return
	var message := "Ad failed to load."
	if error != null and not error.message.is_empty():
		message = "Ad failed to load: %s" % error.message
	_set_result(message)


func _on_rewarded_ad_showed() -> void:
	ad_showing = true


func _on_rewarded_ad_failed_to_show(error: AdError) -> void:
	ad_showing = false
	ad_show_after_load = false
	var message := "Ad failed to show."
	if error != null and not error.message.is_empty():
		message = "Ad failed to show: %s" % error.message
	_set_result(message)
	_destroy_rewarded_ad()
	_load_rewarded_ad(false)


func _on_rewarded_ad_dismissed() -> void:
	ad_showing = false
	_destroy_rewarded_ad()
	if not ad_reward_earned_for_show:
		_set_result("Ad closed before reward.")
	_load_rewarded_ad(false)


func _on_rewarded_ad_user_earned_reward(_item: RewardedItem) -> void:
	ad_reward_earned_for_show = true
	ad_bonus_seconds_remaining = minf(float(AD_BONUS_MAX_SECONDS), ad_bonus_seconds_remaining + float(AD_BONUS_SECONDS))
	_set_result("Ad bonus active: +10% XP, +10% speed for 2 hours.")
	if shop_bonus_label != null:
		shop_bonus_label.text = _shop_bonus_status_text()
	save_game()


func _shop_ad_pressed() -> void:
	if ad_bonus_seconds_remaining > float(AD_BONUS_WARN_THRESHOLD_SECONDS):
		_set_result("Max stackable bonus time is 6 hours.")
		if shop_bonus_label != null:
			shop_bonus_label.text = _shop_bonus_status_text()
		return
	if ad_showing:
		_set_result("Ad already open.")
		return
	if rewarded_ad != null:
		_show_rewarded_ad()
	else:
		_load_rewarded_ad(true)


func _settings_discord_pressed() -> void:
	_set_result("Discord button tapped.")
	_play(click_player)


func _reset_data() -> void:
	_init_state()
	running_skill_id = ""
	running_action_id = ""
	action_progress = 0.0
	current_screen = "home"
	last_result = "Progress reset."
	save_game()
	_render_screen()
	_update_ui(0.0, true)


func _set_result(text: String) -> void:
	last_result = text
	if hero_message != null:
		hero_message.text = text.to_upper()
	_play(click_player)


func _play_action_feedback(key: String, success: bool, xp_amount: int, mastery_amount: float) -> void:
	if not action_cards.has(key):
		return
	var card: Dictionary = action_cards[key]
	var button := card.get("button") as Button
	var art_panel := card.get("art_panel") as Control
	var mastery_bar := card.get("mastery") as Control
	if button == null or art_panel == null:
		return
	art_panel.pivot_offset = art_panel.size * 0.5
	if success:
		_flash_art_glow(art_panel, Color("#35d86d"))
		art_panel.modulate = Color("#93ff9e")
		art_panel.scale = Vector2.ONE
		var pop := create_tween()
		pop.set_parallel(true)
		pop.tween_property(art_panel, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(art_panel, "modulate", Color.WHITE, 0.28)
		pop.chain().tween_property(art_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_float_xp(self, art_panel, xp_amount)
		_float_mastery_bar(self, mastery_bar, mastery_amount)
	else:
		_flash_art_glow(art_panel, Color("#ff4f4f"))
		art_panel.modulate = Color("#ff8d8d")
		art_panel.rotation_degrees = 0.0
		var shake := create_tween()
		shake.tween_property(art_panel, "rotation_degrees", -5.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 5.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", -4.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 3.0, 0.05)
		shake.tween_property(art_panel, "rotation_degrees", 0.0, 0.06)
		shake.parallel().tween_property(art_panel, "modulate", Color.WHITE, 0.26)
		_float_mastery_bar(self, mastery_bar, mastery_amount)


func _flash_art_glow(anchor: Control, color: Color) -> void:
	var glow := Panel.new()
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 80
	glow.add_theme_stylebox_override("panel", _art_glow_style(color))
	anchor.add_child(glow)
	glow.modulate = Color(1, 1, 1, 0.95)
	var tween := create_tween()
	tween.tween_property(glow, "modulate:a", 0.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(glow.queue_free)


func _float_xp(parent: Control, anchor: Control, xp_amount: int) -> void:
	if xp_amount <= 0:
		return
	_float_reward(parent, anchor, "+%s XP" % xp_amount, 92, Color("#2ff06d"), Vector2(0, -86), Vector2(0, -230), 0.0)


func _float_mastery_bar(parent: Control, anchor: Control, mastery_amount: float) -> void:
	if mastery_amount <= 0:
		return
	_float_reward(parent, anchor, "+%s" % mastery_amount, 70, Color("#ffd95a"), Vector2(0, -84), Vector2(0, -88), 0.08, true)


func _float_reward(parent: Control, anchor: Control, text: String, font_size: int, color: Color, start_offset: Vector2, rise: Vector2, delay: float, at_right_end := false) -> void:
	if anchor == null:
		return
	var reward_size := Vector2(560, 130)
	var holder := Control.new()
	holder.z_index = 4096
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	parent.add_child(holder)
	var shadow := _label(text, font_size, Color("#171615"), HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = reward_size
	shadow.position = Vector2(6, 7)
	shadow.modulate = Color(1, 1, 1, 0.58)
	holder.add_child(shadow)
	var label := _label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.size = reward_size
	holder.add_child(label)
	var local_pos := anchor.global_position - parent.global_position
	var anchor_x := anchor.size.x * 0.5 - reward_size.x * 0.5
	if at_right_end:
		anchor_x = anchor.size.x - reward_size.x * 0.5 - 16.0
	holder.position = local_pos + Vector2(
		anchor_x,
		anchor.size.y * 0.18 - reward_size.y * 0.5
	) + start_offset
	holder.modulate = Color(1, 1, 1, 0)
	holder.scale = Vector2(0.82, 0.82)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + rise, 1.25).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.18).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.08).set_delay(delay)
	tween.tween_property(holder, "modulate:a", 0.0, 0.85).set_delay(delay + 0.55)
	tween.chain().tween_callback(holder.queue_free)


func _show_achievement_unlocked(achievement: Dictionary) -> void:
	_prune_achievement_toasts()
	var canvas_size := _current_canvas_size()
	var fitted_scale := _fit_scale_to_canvas(ACHIEVEMENT_TOAST_SIZE, ACHIEVEMENT_TOAST_VIEWPORT_MARGIN)
	var presentation_size := ACHIEVEMENT_TOAST_SIZE * fitted_scale
	var banner_data := achievement.duplicate()
	banner_data["completed"] = true
	var banner := Control.new()
	banner.z_index = 8192
	banner.z_as_relative = false
	banner.mouse_filter = Control.MOUSE_FILTER_STOP
	banner.custom_minimum_size = presentation_size
	banner.size = presentation_size
	add_child(banner)
	achievement_toasts.append(banner)
	var card := _achievement_toast_card(banner_data)
	card.custom_minimum_size = ACHIEVEMENT_TOAST_SIZE
	card.size = ACHIEVEMENT_TOAST_SIZE
	card.scale = Vector2(fitted_scale, fitted_scale)
	banner.add_child(card)

	var toast_index := achievement_toasts.size() - 1
	var bottom_inset := minf(BOTTOM_NAV_HEIGHT, canvas_size.y * 0.22)
	var target_position := Vector2(
		(canvas_size.x - presentation_size.x) * 0.5,
		canvas_size.y - bottom_inset - presentation_size.y - ACHIEVEMENT_TOAST_VIEWPORT_MARGIN.y - float(toast_index) * (presentation_size.y + ACHIEVEMENT_TOAST_GAP * fitted_scale)
	)
	target_position.x = clampf(
		target_position.x,
		ACHIEVEMENT_TOAST_VIEWPORT_MARGIN.x,
		maxf(ACHIEVEMENT_TOAST_VIEWPORT_MARGIN.x, canvas_size.x - presentation_size.x - ACHIEVEMENT_TOAST_VIEWPORT_MARGIN.x)
	)
	target_position.y = clampf(
		target_position.y,
		ACHIEVEMENT_TOAST_VIEWPORT_MARGIN.y,
		maxf(ACHIEVEMENT_TOAST_VIEWPORT_MARGIN.y, canvas_size.y - presentation_size.y - ACHIEVEMENT_TOAST_VIEWPORT_MARGIN.y)
	)
	banner.position = target_position + Vector2(0, 90.0 * fitted_scale)
	banner.modulate = Color(1, 1, 1, 0)
	banner.scale = Vector2(0.92, 0.92)
	banner.pivot_offset = presentation_size * 0.5
	var exit_offset := Vector2(0, 110.0 * fitted_scale)
	banner.gui_input.connect(_on_achievement_toast_gui_input.bind(banner, exit_offset))

	var tween := create_tween()
	banner.set_meta("achievement_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(banner, "position", target_position, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate:a", 1.0, 0.12)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2(1.03, 1.03), 0.14).set_delay(0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "scale", Vector2.ONE, 0.16).set_delay(0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_interval(ACHIEVEMENT_TOAST_EXIT_DELAY)
	tween.tween_callback(_dismiss_achievement_toast.bind(banner, exit_offset))


func _on_achievement_toast_gui_input(event: InputEvent, banner: Control, exit_offset: Vector2) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dismiss_achievement_toast(banner, exit_offset)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_dismiss_achievement_toast(banner, exit_offset)
		get_viewport().set_input_as_handled()


func _dismiss_achievement_toast(banner: Control, exit_offset: Vector2) -> void:
	if banner == null or not is_instance_valid(banner) or bool(banner.get_meta("achievement_dismissing", false)):
		return
	banner.set_meta("achievement_dismissing", true)
	var active_tween := banner.get_meta("achievement_tween", null) as Tween
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	var tween := create_tween()
	banner.set_meta("achievement_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(banner, "position", banner.position + exit_offset, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(banner, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(func():
		achievement_toasts.erase(banner)
		banner.queue_free()
	)


func _prune_achievement_toasts() -> void:
	for i in range(achievement_toasts.size() - 1, -1, -1):
		var toast := achievement_toasts[i] as Control
		if toast == null or not is_instance_valid(toast):
			achievement_toasts.remove_at(i)


func _achievement_toast_card(achievement: Dictionary) -> Control:
	var completed := bool(achievement.get("completed", true))
	var accent := Color(str(achievement.get("accent", "#f4bf35")))
	var card := PanelContainer.new()
	card.clip_contents = true
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _achievement_card_style(Color("#fffdf8") if completed else Color("#fff6e1"), 34, 28))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var art_holder := CenterContainer.new()
	art_holder.custom_minimum_size = Vector2(230, 252)
	art_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(art_holder)
	art_holder.add_child(_achievement_art(achievement))

	var copy := VBoxContainer.new()
	copy.custom_minimum_size = Vector2(1040, 0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 10)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)

	var eyebrow := _label("ACHIEVEMENT UNLOCKED", 36, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(eyebrow)

	var title_label := _label(str(achievement.get("title", "Achievement")), 54, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title_label.custom_minimum_size = Vector2(0, 74)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title_label)

	var subtitle_label := _label(str(achievement.get("subtitle", "")), 36, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	subtitle_label.custom_minimum_size = Vector2(0, 48)
	subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(subtitle_label)

	var reward_label := _label(_achievement_toast_reward_text(achievement), 38, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	reward_label.custom_minimum_size = Vector2(0, 54)
	reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	reward_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(reward_label)

	return card


func _achievement_toast_reward_text(achievement: Dictionary) -> String:
	var reward_text := str(achievement.get("reward", "")).strip_edges()
	if reward_text.is_empty():
		return "Buff unlocked"
	if reward_text.begins_with("Reward:"):
		reward_text = reward_text.substr("Reward:".length()).strip_edges()
	return "Buff: %s" % reward_text


func _load_action_data() -> void:
	actions_by_skill.clear()
	skill_defs.clear()
	if _load_activity_database():
		return
	skill_defs.assign(SKILL_DEFS)
	for raw_def in SKILL_DEFS:
		var skill := raw_def as Dictionary
		var skill_id := str(skill["id"])
		var actions := []
		var dir_path := "res://docs/assets/%s/actions" % skill_id
		var files := PackedStringArray()
		var dir := DirAccess.open(dir_path)
		if dir != null:
			files = dir.get_files()
			files.sort()
		if files.is_empty():
			files = PackedStringArray(ACTION_FILES.get(skill_id, []))
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


func _load_activity_database() -> bool:
	if not FileAccess.file_exists(ACTIVITY_DATABASE_PATH):
		return false
	var file := FileAccess.open(ACTIVITY_DATABASE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var loaded_skills = data.get("skills", [])
	if typeof(loaded_skills) != TYPE_ARRAY or loaded_skills.is_empty():
		return false
	for raw_skill in loaded_skills:
		if typeof(raw_skill) != TYPE_DICTIONARY:
			continue
		var skill := raw_skill as Dictionary
		var skill_id := str(skill.get("id", ""))
		if skill_id.is_empty():
			continue
		skill_defs.append({
			"id": skill_id,
			"name": str(skill.get("name", skill_id.capitalize())),
			"verb": str(skill.get("verb", "Training"))
		})
		var loaded_actions = skill.get("actions", [])
		var actions := []
		if typeof(loaded_actions) == TYPE_ARRAY:
			for raw_action in loaded_actions:
				if typeof(raw_action) != TYPE_DICTIONARY:
					continue
				var action := raw_action as Dictionary
				var action_id := str(action.get("id", ""))
				if action_id.is_empty():
					action_id = _slug(str(action.get("name", "Action")))
				actions.append({
					"id": action_id,
					"name": str(action.get("name", action_id.capitalize())),
					"unlock": int(action.get("unlock", 1)),
					"seconds": float(action.get("seconds", 1.0)),
					"xp": int(action.get("xp", action.get("rewards", {}).get("xp", 1))),
					"stamina": int(action.get("stamina", action.get("costs", {}).get("stamina", 1))),
					"success": float(action.get("success", 90.0)),
					"art": _res_path(str(action.get("art", ""))),
					"bg": _res_path(str(action.get("background", action.get("bg", ""))))
				})
		actions_by_skill[skill_id] = actions
	return not skill_defs.is_empty()


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
	_invalidate_stat_caches()
	skills.clear()
	mastery.clear()
	stamina.clear()
	stamina_bank.clear()
	ad_bonus_seconds_remaining = 0.0
	for def in skill_defs:
		var skill_id := str(def["id"])
		skills[skill_id] = {"xp": 0, "level": 1}
		stamina[skill_id] = BASE_MAX_STAMINA
		stamina_bank[skill_id] = 0.0
		for action in actions_by_skill.get(skill_id, []):
			mastery[_action_key(skill_id, str(action["id"]))] = {"xp": 0, "level": 0}
	_invalidate_stat_caches()


func _validate_state() -> void:
	_invalidate_stat_caches()
	for def in skill_defs:
		var skill_id := str(def["id"])
		if not skills.has(skill_id):
			skills[skill_id] = {"xp": 0, "level": 1}
		if not stamina.has(skill_id):
			stamina[skill_id] = _max_stamina()
		if not stamina_bank.has(skill_id):
			stamina_bank[skill_id] = 0.0
		for action in actions_by_skill.get(skill_id, []):
			var key := _action_key(skill_id, str(action["id"]))
			if not mastery.has(key):
				mastery[key] = {"xp": 0, "level": 0}
			_recalculate_mastery(key)
		_recalculate_level(skill_id)
	if not skills.has(selected_skill_id):
		selected_skill_id = "fight"
	_invalidate_stat_caches()


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"skills": skills,
		"mastery": mastery,
		"stamina": stamina,
		"stamina_bank": stamina_bank,
		"ad_bonus_seconds_remaining": ad_bonus_seconds_remaining,
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
	var raw := file.get_buffer(file.get_length()).get_string_from_utf8()
	var json := JSON.new()
	if json.parse(raw) != OK:
		return
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) == TYPE_DICTIONARY:
		for skill_id in loaded_skills.keys():
			if skills.has(skill_id) and typeof(loaded_skills[skill_id]) == TYPE_DICTIONARY:
				skills[skill_id]["xp"] = int(loaded_skills[skill_id].get("xp", 0))
	var loaded_mastery = data.get("mastery", {})
	if typeof(loaded_mastery) == TYPE_DICTIONARY:
		for key in loaded_mastery.keys():
			if mastery.has(key) and typeof(loaded_mastery[key]) == TYPE_DICTIONARY:
				mastery[key]["xp"] = int(loaded_mastery[key].get("xp", 0))
				_recalculate_mastery(str(key))
	for skill_id in skills.keys():
		_recalculate_level(str(skill_id))
	_invalidate_stat_caches()
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
	ad_bonus_seconds_remaining = clampf(float(data.get("ad_bonus_seconds_remaining", 0.0)), 0.0, float(AD_BONUS_MAX_SECONDS))
	selected_skill_id = str(data.get("selected_skill_id", selected_skill_id))
	running_skill_id = str(data.get("running_skill_id", ""))
	running_action_id = str(data.get("running_action_id", ""))
	action_progress = float(data.get("action_progress", 0.0))
	is_muted = bool(data.get("is_muted", false))
	last_result = str(data.get("last_result", last_result))
	AudioServer.set_bus_mute(0, is_muted)
	var offline := int(clamp(Time.get_unix_time_from_system() - int(data.get("saved_at", Time.get_unix_time_from_system())), 0, MAX_OFFLINE_SECONDS))
	if offline > 0:
		ad_bonus_seconds_remaining = maxf(0.0, ad_bonus_seconds_remaining - float(offline))
		for skill_id in stamina.keys():
			stamina[skill_id] = mini(_max_stamina(), _stamina(str(skill_id)) + int(floor(float(offline) / STAMINA_REGEN_SECONDS)))


func _skill_level(skill_id: String) -> int:
	return int(skills.get(skill_id, {}).get("level", 1))


func _skill_name(skill_id: String) -> String:
	for def in skill_defs:
		if str(def["id"]) == skill_id:
			return str(def["name"])
	return skill_id.capitalize()


func _skill_theme_color(skill_id: String) -> Color:
	return SKILL_THEME_COLORS.get(skill_id, COLOR_BLUE)


func _global_level() -> int:
	var total := 0
	for skill_id in skills.keys():
		total += _skill_level(str(skill_id))
	return total


func _max_stamina() -> int:
	if not max_stamina_cache_valid:
		cached_max_stamina = BASE_MAX_STAMINA + int(floor(float(_global_level()) / 10.0)) + int(round(_global_medal_bonus("max_stamina"))) + int(round(_achievement_reward_bonus("max_stamina")))
		max_stamina_cache_valid = true
	return cached_max_stamina


func _invalidate_stat_caches() -> void:
	max_stamina_cache_valid = false


func _stamina(skill_id: String) -> int:
	var maximum := _max_stamina()
	return clampi(int(stamina.get(skill_id, maximum)), 0, maximum)


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
		_invalidate_stat_caches()
		_play(level_player)


func _mastery_xp_for_level(level: int) -> int:
	if level <= 0:
		return 0
	return int(round(18.0 * pow(float(level), 2.05)))


func _mastery_level(skill_id: String, action_id: String) -> int:
	return int(mastery.get(_action_key(skill_id, action_id), {}).get("level", 0))


func _mastery_progress_pct(skill_id: String, action_id: String) -> float:
	var key := _action_key(skill_id, action_id)
	var level := _mastery_level(skill_id, action_id)
	if level >= MASTERY_MAX_LEVEL:
		return 100.0
	var xp_total := float(mastery.get(key, {}).get("xp", 0))
	var start := _mastery_xp_for_level(level)
	var end := _mastery_xp_for_level(level + 1)
	var needed := maxi(1, end - start)
	return clampf(float(xp_total - start) / float(needed) * 100.0, 0.0, 100.0)


func _would_mastery_reward_medal_up(skill_id: String, action_id: String, amount: float) -> bool:
	if amount <= 0.0:
		return false
	var level := _mastery_level(skill_id, action_id)
	if level >= MASTERY_MAX_LEVEL:
		return false
	var xp_total := float(mastery.get(_action_key(skill_id, action_id), {}).get("xp", 0))
	return xp_total + amount >= float(_mastery_xp_for_level(level + 1))


func _mastery_color(level: int) -> Color:
	var colors := [
		Color("#b8793f"),
		Color("#c8d0d8"),
		Color("#f4bf35"),
		Color("#b9d3ff"),
		Color("#4aa7ff"),
		Color("#35d86d"),
		Color("#e84d4d"),
		Color("#f2fbff"),
		Color("#9c4dff"),
		Color("#fff2a8")
	]
	return colors[clampi(maxi(level, 1) - 1, 0, colors.size() - 1)]


func _mastery_medal_texture(level: int) -> Texture2D:
	var sheet := _texture(MASTERY_MEDALS_TEXTURE)
	if sheet == null:
		return null
	var index := clampi(maxi(level, 1) - 1, 0, MASTERY_MAX_LEVEL - 1)
	if mastery_medal_textures.has(index):
		return mastery_medal_textures[index]
	var region := _mastery_medal_region(index, Vector2i(sheet.get_width(), sheet.get_height()))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(region.position), Vector2(region.size))
	mastery_medal_textures[index] = atlas
	return atlas


func _achievement_medal_texture(level: int) -> Texture2D:
	var sheet := _texture(MASTERY_MEDALS_TEXTURE)
	if sheet == null:
		return null
	var index := clampi(maxi(level, 1) - 1, 0, ACHIEVEMENT_MEDAL_ART_COUNT - 1)
	var key := "achievement:%s" % index
	if mastery_medal_textures.has(key):
		return mastery_medal_textures[key]
	var region := _mastery_medal_region(index, Vector2i(sheet.get_width(), sheet.get_height()))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(region.position), Vector2(region.size))
	mastery_medal_textures[key] = atlas
	return atlas


func _mastery_medal_region(index: int, sheet_size: Vector2i) -> Rect2i:
	var regions := [
		Rect2i(0, 19, 278, 278),
		Rect2i(267, 19, 278, 278),
		Rect2i(536, 19, 278, 278),
		Rect2i(804, 19, 278, 278),
		Rect2i(1073, 18, 278, 278),
		Rect2i(2, 296, 279, 279),
		Rect2i(266, 296, 279, 279),
		Rect2i(534, 296, 279, 279),
		Rect2i(841, 280, 280, 280),
		Rect2i(1121, 280, 280, 280),
		Rect2i(0, 574, 282, 282),
		Rect2i(267, 574, 282, 282),
		Rect2i(536, 574, 282, 282),
		Rect2i(804, 574, 282, 282),
		Rect2i(1068, 574, 297, 282),
		Rect2i(0, 842, 282, 280),
		Rect2i(267, 842, 282, 280),
		Rect2i(536, 842, 282, 280),
		Rect2i(804, 842, 282, 280),
		Rect2i(1068, 842, 297, 280)
	]
	if index >= 0 and index < regions.size():
		var region := regions[index] as Rect2i
		var max_position := Vector2i(maxi(0, sheet_size.x - region.size.x), maxi(0, sheet_size.y - region.size.y))
		region.position.x = clampi(region.position.x, 0, max_position.x)
		region.position.y = clampi(region.position.y, 0, max_position.y)
		region.size.x = mini(region.size.x, sheet_size.x - region.position.x)
		region.size.y = mini(region.size.y, sheet_size.y - region.position.y)
		return region
	var columns := 5
	var rows := 4
	var cell := Vector2i(sheet_size.x / columns, sheet_size.y / rows)
	return Rect2i(Vector2i((index % columns) * cell.x, int(floor(float(index) / float(columns))) * cell.y), cell)


func _mastery_medal_silhouette_texture(level: int, color: Color) -> Texture2D:
	var index := clampi(maxi(level, 1) - 1, 0, MASTERY_MAX_LEVEL - 1)
	var key := "%s:%s" % [index, color.to_html(true)]
	if mastery_medal_silhouette_textures.has(key):
		return mastery_medal_silhouette_textures[key]
	var sheet := _texture(MASTERY_MEDALS_TEXTURE)
	if sheet == null:
		return null
	var sheet_image := sheet.get_image()
	if sheet_image == null or sheet_image.is_empty():
		return null
	var region := _mastery_medal_region(index, Vector2i(sheet_image.get_width(), sheet_image.get_height()))
	var image := sheet_image.get_region(region)
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var source := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, source.a * color.a))
	var texture := ImageTexture.create_from_image(image)
	mastery_medal_silhouette_textures[key] = texture
	return texture


func _mastery_medal_dot_texture() -> Texture2D:
	if mastery_medal_dot_texture != null:
		return mastery_medal_dot_texture
	var size := 128
	var radius := 13.0
	var center := Vector2(float(size) * 0.5, float(size) * 0.5)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(size):
		for x in range(size):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			if point.distance_to(center) <= radius:
				image.set_pixel(x, y, Color("#171615"))
	mastery_medal_dot_texture = ImageTexture.create_from_image(image)
	return mastery_medal_dot_texture


func _global_medal_tier_unlocked(level: int) -> bool:
	for key in mastery.keys():
		var entry = mastery[key]
		if typeof(entry) == TYPE_DICTIONARY and int(entry.get("level", 0)) >= level:
			return true
	return false


func _global_medal_bonus(stat: String) -> float:
	var total := 0.0
	for buff in GLOBAL_MEDAL_BUFFS:
		if str(buff.get("stat", "")) == stat and _global_medal_tier_unlocked(int(buff.get("level", 0))):
			total += float(buff.get("amount", 0.0))
	return total


func _global_medal_buff_text() -> String:
	var lines := _active_global_buff_lines()
	if lines.is_empty():
		return "Global buffs unlock from your first Bronze, Silver, Gold, and higher medals."
	return "Global buffs: %s" % ", ".join(lines)


func _new_global_medal_buff_messages(old_level: int, new_level: int, tiers_unlocked_before: Dictionary) -> Array:
	var messages := []
	for tier in range(old_level + 1, new_level + 1):
		if tier >= 1 and tier <= MASTERY_MAX_LEVEL and not bool(tiers_unlocked_before.get(tier, false)):
			messages.append("%s global buff unlocked: %s." % [MASTERY_MEDAL_NAMES[tier - 1], _global_medal_tier_bonus_text(tier)])
	return messages


func _global_medal_tier_bonus_text(level: int) -> String:
	for buff in GLOBAL_MEDAL_BUFFS:
		if int(buff.get("level", 0)) != level:
			continue
		var stat := str(buff.get("stat", ""))
		var amount := float(buff.get("amount", 0.0))
		if stat == "max_stamina":
			return "+%s max stamina" % int(round(amount))
		if stat == "xp_mult":
			return "+%s%% XP" % int(round(amount * 100.0))
		if stat == "speed_mult":
			return "+%s%% speed" % int(round(amount * 100.0))
		if stat == "success_bonus":
			return "+%s%% success" % int(round(amount))
	return "global power"


func _mastery_xp_reward(action: Dictionary) -> float:
	return 1.0


func _add_mastery_xp(skill_id: String, action_id: String, amount: float) -> void:
	var key := _action_key(skill_id, action_id)
	if not mastery.has(key):
		mastery[key] = {"xp": 0, "level": 0}
	mastery[key]["xp"] = float(mastery[key].get("xp", 0)) + amount
	_recalculate_mastery(key)


func _recalculate_mastery(key: String) -> void:
	if not mastery.has(key):
		return
	var xp_total := float(mastery[key].get("xp", 0))
	var old_level := int(mastery[key].get("level", 0))
	var level := 0
	while level < MASTERY_MAX_LEVEL and xp_total >= _mastery_xp_for_level(level + 1):
		level += 1
	mastery[key]["level"] = level
	if level != old_level:
		_invalidate_stat_caches()


func _effective_stamina(action: Dictionary) -> int:
	return maxi(1, int(action.get("stamina", 1)))


func _effective_seconds(skill_id: String, action: Dictionary) -> float:
	var base_seconds := maxf(0.1, float(action.get("seconds", 1.0)))
	var speed_bonus := clampf(_global_medal_bonus("speed_mult") + _ad_bonus_speed_mult(), 0.0, 0.75)
	var skill_timer_reduction := clampf(_skill_level_timer_reduction(skill_id), 0.0, 0.85)
	var total_reduction := clampf(speed_bonus + skill_timer_reduction, 0.0, 0.9)
	return maxf(0.1, base_seconds * (1.0 - total_reduction))


func _record_successful_activity_completion(action_key: String) -> int:
	if activity_streak_action_key == action_key:
		activity_streak_count += 1
	else:
		activity_streak_action_key = action_key
		activity_streak_count = 1
	return ((activity_streak_count - 1) % ACTIVITY_STREAK_BONUS_STEP) + 1


func _reset_activity_completion_streak() -> void:
	activity_streak_action_key = ""
	activity_streak_count = 0


func _effective_xp(action: Dictionary) -> int:
	var xp_bonus := _global_medal_bonus("xp_mult") + _ad_bonus_xp_mult()
	return maxi(1, int(round(float(action.get("xp", 1)) * (1.0 + xp_bonus))))


func _action_data(skill_id: String, action_id: String) -> Dictionary:
	for action in actions_by_skill.get(skill_id, []):
		if str(action["id"]) == action_id:
			return action
	return {}


func _action_key(skill_id: String, action_id: String) -> String:
	return "%s:%s" % [skill_id, action_id]


func _success_chance(skill_id: String, action: Dictionary) -> float:
	return clampf(float(action.get("success", 90.0)) + _global_medal_bonus("success_bonus"), 5.0, 99.0)


func _res_path(path: String) -> String:
	if path.is_empty() or path.begins_with("res://"):
		return path
	return "res://%s" % path


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


func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(0, int(ceil(seconds)))
	var hours := int(total_seconds / 3600)
	var minutes := int((total_seconds % 3600) / 60)
	if hours > 0:
		return "%sh %sm" % [hours, minutes]
	return "%sm" % maxi(1, minutes)


func _format_percent(value: float) -> String:
	return "%.1f" % (value * 100.0)


func _load_font() -> void:
	if ResourceLoader.exists("res://assets/fonts/Fredoka.ttf"):
		app_font = load("res://assets/fonts/Fredoka.ttf")
		var bold := FontVariation.new()
		bold.base_font = app_font
		bold.variation_embolden = 0.9
		app_bold_font = bold


func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if app_bold_font != null:
		label.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
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


func _image_from_texture(texture: Texture2D, minimum_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = minimum_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _inset_full_rect(control: Control, inset: int) -> void:
	control.offset_left = inset
	control.offset_top = inset
	control.offset_right = -inset
	control.offset_bottom = -inset


func _icon_button(path: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(300, 300)
	button.focus_mode = Control.FOCUS_NONE
	button.icon = _texture(path)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 180)
	button.add_theme_stylebox_override("normal", _button_style(COLOR_PANEL, SECONDARY_BUTTON_BORDER, 72, 28))
	button.add_theme_stylebox_override("hover", _button_style(COLOR_GOLD, SECONDARY_BUTTON_BORDER, 72, 28))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_GOLD.darkened(0.08), SECONDARY_BUTTON_BORDER, 72, 28))
	return button


func _nav_button(path: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(268, 268)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.icon = _texture(path)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 184)
	return button


func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 220)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 72)
	if app_bold_font != null:
		button.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		button.add_theme_font_override("font", app_font)
	button.add_theme_color_override("font_color", COLOR_INK)
	button.add_theme_color_override("font_hover_color", COLOR_INK)
	button.add_theme_color_override("font_pressed_color", COLOR_INK)
	button.add_theme_stylebox_override("normal", _button_style(COLOR_PANEL, BUTTON_BORDER, 48))
	button.add_theme_stylebox_override("hover", _button_style(COLOR_GOLD, BUTTON_BORDER, 48))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_GOLD.darkened(0.08), BUTTON_BORDER, 48))
	button.add_theme_stylebox_override("disabled", _button_style(Color("#fffaf0"), SECONDARY_BUTTON_BORDER, 48))
	return button


func _settings_page_button(text: String, icon_path := "", min_width := 900, icon_max_width := 128, min_height := 250) -> Button:
	var button := _menu_button(text if icon_path.is_empty() else "")
	button.custom_minimum_size = Vector2(min_width, min_height)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 70)
	button.add_theme_stylebox_override("normal", _button_style(COLOR_PANEL, BUTTON_BORDER, 54))
	button.add_theme_stylebox_override("hover", _button_style(COLOR_GOLD, BUTTON_BORDER, 54))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_GOLD.darkened(0.08), BUTTON_BORDER, 54))
	if not icon_path.is_empty():
		var content := MarginContainer.new()
		content.set_anchors_preset(Control.PRESET_FULL_RECT)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("margin_left", 54)
		content.add_theme_constant_override("margin_right", 68)
		content.add_theme_constant_override("margin_top", 18)
		content.add_theme_constant_override("margin_bottom", 18)
		button.add_child(content)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 38)
		content.add_child(row)
		var icon_holder := CenterContainer.new()
		icon_holder.custom_minimum_size = Vector2(icon_max_width, icon_max_width)
		icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_holder)
		var icon := TextureRect.new()
		icon.texture = _texture(icon_path)
		icon.custom_minimum_size = Vector2(icon_max_width, icon_max_width)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_holder.add_child(icon)
		var label := _label(text, 70, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
	return button


func _shop_ad_offer_button() -> Button:
	var button := _menu_button("")
	button.custom_minimum_size = Vector2(1480, 520)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_stylebox_override("normal", _button_style(Color("#fff5c7"), BUTTON_BORDER, 58))
	button.add_theme_stylebox_override("hover", _button_style(COLOR_GOLD, BUTTON_BORDER, 58))
	button.add_theme_stylebox_override("pressed", _button_style(COLOR_GOLD.darkened(0.08), BUTTON_BORDER, 58))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 70)
	margin.add_theme_constant_override("margin_right", 70)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 54)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(_image("res://docs/assets/ui/ad-reward.png", Vector2(300, 300)))
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 12)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var title := _label("Play Ad", 84, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)
	var details := _label("+10% XP\n+10% Speed\nFor 2 hours\n(Stackable)", 58, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(details)
	return button


func _action_stat_label(text: String) -> Label:
	var label := _label(text, 60, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _action_stat_box(label: Label) -> PanelContainer:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(300, 222)
	box.add_theme_stylebox_override("panel", _stat_box_style())
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return box


func _progress(fill: Color, height: int, value := 0.0) -> CleanProgressBar:
	var bar := CleanProgressBar.new()
	bar.fill_color = fill
	bar.custom_minimum_size = Vector2(0, height)
	bar.set_value(value)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _achievement_medal_slot_strip(skill_id: String, actions: Array) -> Dictionary:
	var strip := AchievementMedalSlotStrip.new()
	strip.slot_count = ACHIEVEMENT_MEDAL_SLOT_COUNT
	strip.slot_size = ACHIEVEMENT_MEDAL_SLOT_SIZE * 2.7
	strip.custom_minimum_size = Vector2(0, 170)
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panels := []
	var icons := []
	for i in range(ACHIEVEMENT_MEDAL_SLOT_COUNT):
		var shadow := _image_from_texture(_mastery_medal_silhouette_texture(1, Color(0, 0, 0, 0.70)), strip.slot_size)
		shadow.z_index = ACHIEVEMENT_MEDAL_SLOT_COUNT - i
		var icon := _image_from_texture(_mastery_medal_silhouette_texture(1, Color(0, 0, 0, 0.58)), strip.slot_size)
		icon.z_index = ACHIEVEMENT_MEDAL_SLOT_COUNT - i + ACHIEVEMENT_MEDAL_SLOT_COUNT
		if i < actions.size():
			var action := actions[i] as Dictionary
			icon.tooltip_text = "%s: %s" % [_skill_name(skill_id), str(action.get("name", ""))]
			shadow.tooltip_text = icon.tooltip_text
		strip.add_slot_icon(icon, shadow)
		panels.append(shadow)
		icons.append(icon)
	return {"root": strip, "panels": panels, "icons": icons}


func _set_bar(bar, target: float, delta: float, instant: bool) -> void:
	if bar == null:
		return
	var progress := bar as Control
	if progress == null:
		return
	var current_value := 0.0
	if progress is CleanProgressBar:
		current_value = float((progress as CleanProgressBar).value)
	elif progress is ActivityProgressRail:
		current_value = float((progress as ActivityProgressRail).value)
	if instant:
		if absf(current_value - target) > 0.001:
			progress.call("set_value", target)
	else:
		if absf(current_value - target) <= 0.01:
			if absf(current_value - target) > 0.001:
				progress.call("set_value", target)
			return
		var step_delta := maxf(delta, 1.0 / 60.0)
		var speed := 12.0
		if progress is CleanProgressBar:
			speed = float((progress as CleanProgressBar).easing_speed)
		elif progress is ActivityProgressRail:
			speed = float((progress as ActivityProgressRail).easing_speed)
			if target < current_value:
				speed = 5.5
		progress.call("set_value", lerpf(current_value, target, 1.0 - exp(-speed * step_delta)))


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


func _button_style(color: Color, border: int, radius: int, margin := 72) -> StyleBoxFlat:
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
	style.shadow_color = Color(0.09, 0.08, 0.07, 0.28)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = max(18, margin - 14)
	style.content_margin_bottom = max(18, margin - 14)
	return style


func _surface_style(color: Color, radius: int, margin := 28, elevated := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_left = PASSIVE_BORDER
	style.border_width_right = PASSIVE_BORDER
	style.border_width_top = PASSIVE_BORDER
	style.border_width_bottom = PASSIVE_BORDER
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if elevated:
		style.shadow_color = Color(0.09, 0.08, 0.07, 0.16)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


func _summary_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PAPER
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _summary_icon_style() -> StyleBoxFlat:
	var style := _surface_style(COLOR_PANEL, 44, 20, true)
	style.border_color = COLOR_LINE
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


func _achievement_card_style(color: Color, radius: int, margin: int) -> StyleBoxFlat:
	var style := _surface_style(color, radius, margin, true)
	return style


func _achievement_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff6d6")
	style.border_color = Color("#d2c3a0")
	style.border_width_left = 10
	style.border_width_right = 10
	style.border_width_top = 10
	style.border_width_bottom = 10
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


func _featured_activity_art_style() -> StyleBoxFlat:
	var style := _surface_style(Color("#fffaf0"), 24, 8, true)
	style.border_color = COLOR_LINE
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _activity_shade_style(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.5, 0.5, alpha)
	style.corner_radius_top_left = 66
	style.corner_radius_top_right = 66
	style.corner_radius_bottom_left = 66
	style.corner_radius_bottom_right = 66
	return style


func _action_card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.0)
	style.draw_center = false
	style.border_color = COLOR_INK
	style.border_width_left = 16
	style.border_width_right = 16
	style.border_width_top = 16
	style.border_width_bottom = 16
	style.corner_radius_top_left = 66
	style.corner_radius_top_right = 66
	style.corner_radius_bottom_left = 66
	style.corner_radius_bottom_right = 66
	style.shadow_color = Color(0.09, 0.08, 0.07, 0.72)
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 16)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _action_art_style() -> StyleBoxFlat:
	var style := _surface_style(Color.WHITE, 56, 16, true)
	style.border_color = Color("#eee2ce")
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_width_top = 5
	style.border_width_bottom = 5
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _art_glow_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.28)
	style.border_color = Color(color.r, color.g, color.b, 0.95)
	style.border_width_left = 24
	style.border_width_right = 24
	style.border_width_top = 24
	style.border_width_bottom = 24
	style.corner_radius_top_left = 56
	style.corner_radius_top_right = 56
	style.corner_radius_bottom_left = 56
	style.corner_radius_bottom_right = 56
	return style


func _stat_box_style() -> StyleBoxFlat:
	var style := _surface_style(Color.WHITE, 38, 18, true)
	style.border_color = Color("#eadfcd")
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
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
	var border := 16 if active else 0
	style.border_width_left = border
	style.border_width_right = border
	style.border_width_top = border
	style.border_width_bottom = border
	style.corner_radius_top_left = 46
	style.corner_radius_top_right = 46
	style.corner_radius_bottom_left = 46
	style.corner_radius_bottom_right = 46
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 24
	style.content_margin_bottom = 24
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


func _locked_activity_material() -> ShaderMaterial:
	if locked_activity_material != null:
		return locked_activity_material
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(gray), vec3(0.74, 0.74, 0.70), 0.18);
	COLOR = color;
}
"""
	locked_activity_material = ShaderMaterial.new()
	locked_activity_material.shader = shader
	return locked_activity_material


func _hero_chroma_material() -> ShaderMaterial:
	return _chroma_material(Color("#ffffff"))


func _build_audio() -> void:
	click_player = _sfx("res://assets/sfx/click.wav")
	success_players.clear()
	for path in ACTIVITY_SUCCESS_SFX_PATHS:
		success_players.append(_sfx(path))
	chain_move_players.clear()
	for path in CHAIN_MOVE_SFX_PATHS:
		chain_move_players.append(_sfx(path))
	chain_jingle_players.clear()
	for i in range(3):
		var player := _sfx(CHAIN_JINGLE_SFX_PATH)
		player.volume_db = -8.0 - float(i) * 3.0
		chain_jingle_players.append(player)
	padlock_cluster_player = _sfx(PADLOCK_CLUSTER_SFX_PATH)
	failure_player = _sfx("res://assets/sfx/warm_reject.wav")
	level_player = _sfx("res://assets/sfx/level_up_jingle.wav")
	medal_player = _sfx("res://assets/sfx/xp_spark.wav")
	bonus_jingle_player = _sfx("res://assets/sfx/xp_spark.wav")
	bonus_jingle_player.volume_db = -7.0
	bonus_jingle_echo_player = _sfx("res://assets/sfx/xp_spark.wav")
	bonus_jingle_echo_player.volume_db = -10.0


func _sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player


func _play(player: AudioStreamPlayer) -> void:
	if player != null and _can_play_audio():
		player.stop()
		player.pitch_scale = 1.0
		player.play()


func _play_with_pitch(player: AudioStreamPlayer, pitch: float) -> void:
	if player != null and _can_play_audio():
		player.stop()
		player.pitch_scale = pitch
		player.play()


func _play_random_chain_move_sfx() -> void:
	if chain_move_players.is_empty() or not _can_play_audio():
		return
	var player := chain_move_players.pick_random() as AudioStreamPlayer
	_play_with_pitch(player, randf_range(0.96, 1.04))


func _play_chain_move_jingle_mix() -> void:
	if not _can_play_audio():
		return
	var shuffled_move_players := chain_move_players.duplicate()
	shuffled_move_players.shuffle()
	var move_count := mini(2, shuffled_move_players.size())
	for i in range(move_count):
		var player := shuffled_move_players[i] as AudioStreamPlayer
		player.volume_db = -3.0 - float(i) * 2.5
		_play_with_pitch(player, randf_range(0.94, 1.08))
	var variant := randi_range(0, 3)
	_play_chain_jingle_mix(variant)


func _play_padlock_cluster_sfx() -> void:
	_play(padlock_cluster_player)


func _play_chain_fall_sfx_sequence() -> void:
	_play_chain_jingle_mix()
	var tween := create_tween()
	tween.tween_interval(ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS * 0.28)
	tween.tween_callback(_play_random_chain_move_sfx)
	tween.tween_interval(ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS * 0.26)
	tween.tween_callback(_play_chain_jingle_mix.bind(1))
	tween.tween_interval(ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS * 0.24)
	tween.tween_callback(_play_random_chain_move_sfx)


func _play_chain_jingle_mix(variant := 0) -> void:
	if chain_jingle_players.is_empty() or not _can_play_audio():
		return
	var pitches := [0.90, 0.98, 1.07]
	var player_count := mini(chain_jingle_players.size(), pitches.size())
	for i in range(player_count):
		var player := chain_jingle_players[i] as AudioStreamPlayer
		player.volume_db = -10.0 - float(i) * 3.0
		var pitch := float(pitches[i]) + float(variant) * 0.025
		_play_with_pitch(player, pitch)


func _play_activity_success_sound(streak_step: int, medal_unlocked: bool, streak_bonus: bool) -> void:
	if not success_players.is_empty():
		var pitch_index := clampi(streak_step, 1, success_players.size()) - 1
		_play(success_players[pitch_index])
	if streak_bonus:
		_play_bonus_jingle()
	elif medal_unlocked:
		_play(medal_player)


func _play_bonus_jingle() -> void:
	if not _can_play_audio():
		return
	_play_with_pitch(bonus_jingle_player, 1.18)
	var tween := create_tween()
	tween.tween_interval(ACTIVITY_BONUS_JINGLE_DELAY)
	tween.tween_callback(func(): _play_with_pitch(bonus_jingle_echo_player, 1.42))


func _can_play_audio() -> bool:
	return audio_unlocked_by_input and not is_muted


func _note_player_input(event: InputEvent) -> void:
	if audio_unlocked_by_input:
		return
	if event is InputEventMouseButton and event.pressed:
		audio_unlocked_by_input = true
	elif event is InputEventScreenTouch and event.pressed:
		audio_unlocked_by_input = true
	elif event is InputEventKey and event.pressed and not event.echo:
		audio_unlocked_by_input = true


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
