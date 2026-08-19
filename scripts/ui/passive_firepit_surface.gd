extends RefCounted

const ActivityCardBorder = preload("res://scripts/ui/activity_card_border.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const MaterialRuntime = preload("res://scripts/materials/runtime.gd")
const MaterialCollectionSurface = preload("res://scripts/ui/material_collection_surface.gd")
const PassiveModulesRuntime = preload("res://scripts/gameplay/passive_modules_runtime.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const RewardFeedbackSurface = preload("res://scripts/ui/reward_feedback_surface.gd")
const RoundedCornerCropOverlay = preload("res://scripts/ui/rounded_corner_crop_overlay.gd")
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")
const StopHoldCircle = preload("res://scripts/ui/stop_hold_circle.gd")

const WOODCUTTING_LOG_MODULE_INFO := "Legacy collector kept only for save compatibility."
const WOODCUTTING_FIREPIT_TIP_TEXT := "Tap Firepit to start."
const WOODCUTTING_FIREPIT_TEXTURE := "res://assets/content/woodcutting/modules/woodcutting-firepit.png"
const WOODCUTTING_FIREPIT_BACKGROUND_TEXTURE := "res://assets/content/woodcutting/modules/woodcutting-firepit-bg.png"
const WOODCUTTING_FIREPIT_INFO := "Tap firepit to start. Burning Scrapwood rewards XP and increases your Woodcutting stamina regeneration rate."
const WOODCUTTING_FIREPIT_CARD_HEIGHT := 470.0
const WOODCUTTING_FIREPIT_DEPENDENCY_GAP := 17.0
const WOODCUTTING_FIREPIT_DEPENDENCY_HEIGHT := 394.0
const FIREPIT_STOP_HOLD_SECONDS := 0.8
const PASSIVE_LOG_TEXTURE_VISIBLE_MIN := Vector2(0.146, 0.246)
const PASSIVE_LOG_TEXTURE_VISIBLE_MAX := Vector2(0.856, 0.755)
const PASSIVE_LOG_PILE_MEDIUM_THRESHOLD := 25
const PASSIVE_LOG_PILE_LARGE_THRESHOLD := 100
const PASSIVE_LOG_PILE_CLICK_PROMPT := "tap!"
const PASSIVE_LOG_PILE_CLICK_PROMPT_FONT_SIZE := 48
const PASSIVE_LOG_PILE_CLICK_PROMPT_SIZE := Vector2(170, 59)
const PASSIVE_LOG_PILE_CLICK_PROMPT_OFFSET := Vector2(-29, -23)
const PASSIVE_INFO_CLICK_AWAY_SECONDS := 2.0
const INFO_POPOVER_PREWARM_FRAMES := 2


class _FirepitFuelRing:
	extends Control

	var value := 0.0
	var target_value := 0.0
	var inner_value := 0.0
	var inner_target_value := 0.0
	var easing_speed := 6.0
	var fill_color := Color("#ff9c2f")
	var empty_color := Color("#553220")
	var inner_fill_color := Color("#ffd55f")
	var inner_empty_color := Color("#3a251b")
	var outline_color := Color("#171615")
	var shadow_color := Color(0.08, 0.07, 0.06, 0.32)
	var heat_gradient_colors := [
		Color("#d63a16"),
		Color("#ff641f"),
		Color("#ff9c2f"),
		Color("#ffd45a"),
		Color("#fff08c"),
	]

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)

	func set_value(next_value: float) -> void:
		var clamped := clampf(next_value, 0.0, 100.0)
		if absf(value - clamped) <= 0.001 and absf(target_value - clamped) <= 0.001:
			return
		value = clamped
		target_value = clamped
		queue_redraw()
		_maybe_sleep()

	func set_inner_value(next_value: float) -> void:
		var clamped := clampf(next_value, 0.0, 100.0)
		if absf(inner_value - clamped) <= 0.001 and absf(inner_target_value - clamped) <= 0.001:
			return
		inner_value = clamped
		inner_target_value = clamped
		queue_redraw()
		_maybe_sleep()

	func set_target_value(next_value: float, instant := false) -> void:
		var clamped := clampf(next_value, 0.0, 100.0)
		if instant:
			set_value(clamped)
			return
		if absf(target_value - clamped) <= 0.001:
			return
		target_value = clamped
		if not is_processing():
			set_process(true)

	func set_inner_target_value(next_value: float, instant := false) -> void:
		var clamped := clampf(next_value, 0.0, 100.0)
		if instant:
			set_inner_value(clamped)
			return
		if absf(inner_target_value - clamped) <= 0.001:
			return
		inner_target_value = clamped
		if not is_processing():
			set_process(true)

	func _process(delta: float) -> void:
		if absf(value - target_value) <= 0.001 and absf(inner_value - inner_target_value) <= 0.001:
			value = target_value
			inner_value = inner_target_value
			_maybe_sleep()
			return
		var speed := easing_speed if target_value >= value else easing_speed * 0.9
		value = lerpf(value, target_value, 1.0 - exp(-speed * minf(delta, 0.1)))
		var inner_speed := easing_speed * 1.45 if inner_target_value >= inner_value else easing_speed * 0.85
		inner_value = lerpf(inner_value, inner_target_value, 1.0 - exp(-inner_speed * minf(delta, 0.1)))
		queue_redraw()

	func _maybe_sleep() -> void:
		if absf(value - target_value) <= 0.001 and absf(inner_value - inner_target_value) <= 0.001:
			set_process(false)

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.42
		var tube_width := maxf(22.0, radius * 0.13)
		var outline_width := tube_width + maxf(9.0, tube_width * 0.34)
		var inner_radius := radius - outline_width * 1.06
		var inner_tube_width := maxf(20.0, tube_width * 0.70)
		var inner_outline_width := inner_tube_width + maxf(7.0, inner_tube_width * 0.34)
		var start_angle := deg_to_rad(-75.0)
		var sweep := deg_to_rad(330.0)
		var fill_pct := clampf(value / 100.0, 0.0, 1.0)
		var inner_fill_pct := clampf(inner_value / 100.0, 0.0, 1.0)
		_draw_round_arc(center + Vector2(0.0, 2.5), radius, start_angle, sweep, shadow_color, outline_width + 4.0)
		_draw_round_arc(center, radius, start_angle, sweep, outline_color, outline_width)
		_draw_round_arc(center, radius, start_angle, sweep, empty_color, tube_width)
		if fill_pct > 0.001:
			_draw_heat_arc(center, radius, start_angle, sweep * fill_pct, sweep, tube_width)
		if inner_radius > inner_outline_width:
			_draw_round_arc(center + Vector2(0.0, 3.0), inner_radius, start_angle, sweep, shadow_color.darkened(0.2), inner_outline_width + 3.0)
			_draw_round_arc(center, inner_radius, start_angle, sweep, outline_color, inner_outline_width)
			_draw_round_arc(center, inner_radius, start_angle, sweep, inner_empty_color, inner_tube_width)
			if inner_fill_pct > 0.001:
				_draw_round_arc(center, inner_radius, start_angle, sweep * inner_fill_pct, inner_fill_color, inner_tube_width)

	func _draw_round_arc(center: Vector2, radius: float, start_angle: float, sweep: float, color: Color, width: float) -> void:
		if sweep <= 0.001 or color.a <= 0.0 or width <= 0.0:
			return
		var segments := maxi(12, int(ceil(absf(sweep) / TAU * 96.0)))
		var end_angle := start_angle + sweep
		draw_arc(center, radius, start_angle, end_angle, segments, color, width, true)
		var start_point := center + Vector2(cos(start_angle), sin(start_angle)) * radius
		var end_point := center + Vector2(cos(end_angle), sin(end_angle)) * radius
		draw_circle(start_point, width * 0.5, color)
		draw_circle(end_point, width * 0.5, color)

	func _draw_heat_arc(center: Vector2, radius: float, start_angle: float, filled_sweep: float, full_sweep: float, width: float) -> void:
		if filled_sweep <= 0.001 or full_sweep <= 0.001 or width <= 0.0:
			return
		var segments := maxi(18, int(ceil(absf(filled_sweep) / TAU * 128.0)))
		for segment in range(segments):
			var start_t := float(segment) / float(segments)
			var end_t := float(segment + 1) / float(segments)
			var segment_start := start_angle + filled_sweep * start_t
			var segment_end := start_angle + filled_sweep * end_t
			var full_ring_t := clampf(((segment_start + segment_end) * 0.5 - start_angle) / full_sweep, 0.0, 1.0)
			draw_arc(
				center,
				radius,
				segment_start,
				segment_end,
				3,
				_heat_gradient_color(full_ring_t),
				width,
				true
			)
		var end_angle := start_angle + filled_sweep
		var end_t := clampf(filled_sweep / full_sweep, 0.0, 1.0)
		draw_circle(center + Vector2(cos(start_angle), sin(start_angle)) * radius, width * 0.5, _heat_gradient_color(0.0))
		draw_circle(center + Vector2(cos(end_angle), sin(end_angle)) * radius, width * 0.5, _heat_gradient_color(end_t))

	func _heat_gradient_color(t: float) -> Color:
		if heat_gradient_colors.is_empty():
			return fill_color
		if heat_gradient_colors.size() == 1:
			return heat_gradient_colors[0]
		var scaled := clampf(t, 0.0, 1.0) * float(heat_gradient_colors.size() - 1)
		var left_index := clampi(int(floor(scaled)), 0, heat_gradient_colors.size() - 1)
		var right_index := clampi(left_index + 1, 0, heat_gradient_colors.size() - 1)
		return heat_gradient_colors[left_index].lerp(heat_gradient_colors[right_index], scaled - float(left_index))


class _FirepitWarmthOverlay:
	extends Control

	var cutout_center := Vector2.ZERO
	var base_radius := 520.0
	var feather_radius := 260.0
	var flicker_radius := 46.0
	var darkness := 0.46
	var unlit_darkness := 0.42
	var glow_alpha := 0.16
	var active := false
	var cover_visible := false
	var corner_radius := 66.0

	var _time := 0.0

	func set_active(is_active: bool) -> void:
		set_cover(is_active, is_active)

	func set_cover(is_visible: bool, is_fire_lit: bool) -> void:
		cover_visible = is_visible
		active = is_fire_lit
		visible = cover_visible
		set_process(cover_visible and active)
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(active)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		if not cover_visible:
			return
		if not active:
			_draw_rounded_cover(Color(0.03, 0.022, 0.014, unlit_darkness))
			return
		var flicker := sin(_time * 4.8) * 0.52 + sin(_time * 9.7 + 1.4) * 0.31 + sin(_time * 15.3 + 0.6) * 0.17
		var radius := base_radius + flicker * flicker_radius
		var feather := feather_radius + sin(_time * 3.3 + 0.8) * 24.0
		var outer_radius := radius + feather
		var center := cutout_center
		_draw_rounded_cover(Color(0.03, 0.022, 0.014, darkness))
		var steps := 72
		for step in range(steps):
			var t := float(step) / float(maxi(1, steps - 1))
			var circle_radius := lerpf(outer_radius, radius * 0.22, t)
			var alpha := glow_alpha * pow(t, 1.18) * 0.28
			var glow_color := Color(1.0, 0.50 + 0.22 * t, 0.16, alpha)
			draw_circle(center, circle_radius, glow_color)

	func _draw_rounded_cover(color: Color) -> void:
		if color.a <= 0.0 or size.x <= 1.0 or size.y <= 1.0:
			return
		var r := minf(corner_radius, minf(size.x, size.y) * 0.5)
		if r <= 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), color)
			return
		var step := 1.0
		var y := 0.0
		while y < size.y:
			var sample_y := y + step * 0.5
			var inset := 0.0
			if sample_y < r:
				var dy_top := sample_y - r
				inset = r - sqrt(maxf(0.0, r * r - dy_top * dy_top))
			elif sample_y > size.y - r:
				var dy_bottom := sample_y - (size.y - r)
				inset = r - sqrt(maxf(0.0, r * r - dy_bottom * dy_bottom))
			draw_rect(Rect2(Vector2(inset, y), Vector2(maxf(0.0, size.x - inset * 2.0), step)), color)
			y += step


class FirepitFlameFx:
	extends Control

	const FLAME_ATLAS_PATH := "res://assets/content/woodcutting/modules/woodcutting-firepit-flame-sheet.png"
	const SMOKE_ATLAS_PATH := "res://assets/content/woodcutting/modules/woodcutting-firepit-smoke-sheet.png"
	const FRAME_COUNT := 4
	const SMOKE_FRAME_COUNT := 8
	const FLAME_CELL_SIZE := Vector2(512, 512)
	const SMOKE_CELL_SIZE := Vector2(256, 256)
	const FRAME_SEQUENCE := [0, 1, 2, 3]
	const FRAME_DURATION_SECONDS := 1.5
	const SMOKE_PUFF_COUNT := 4
	const FLAME_WARBLE_SHADER := """
shader_type canvas_item;
uniform float heat = 0.0;
void fragment() {
	vec2 uv = UV;
	float sway = sin(TIME * 2.4 + uv.y * 8.0) * 0.006;
	float flutter = sin(TIME * 3.7 + uv.y * 15.0) * 0.003;
	uv.x += (sway + flutter) * heat * smoothstep(0.16, 0.92, uv.y);
	COLOR = texture(TEXTURE, uv) * COLOR;
}
"""

	var active := false
	var heat := 0.0
	var sequence_index := 0
	var frame_elapsed := 0.0
	var frame_textures: Array[Texture2D] = []
	var smoke_textures: Array[Texture2D] = []
	var flame_rect: TextureRect
	var flame_material: ShaderMaterial
	var smoke_puffs: Array[TextureRect] = []

	func set_active(next_active: bool) -> void:
		if active == next_active:
			if active and not is_processing():
				set_process(true)
			return
		active = next_active
		set_process(active or heat > 0.01)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_build_frame_textures()
		flame_rect = TextureRect.new()
		flame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		flame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flame_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flame_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		flame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flame_rect.z_index = 1
		_build_flame_material()
		if flame_material != null:
			flame_rect.material = flame_material
		add_child(flame_rect)
		_build_smoke_puffs()
		_apply_frame(0)
		_sync_visual_transform()
		set_process(active or heat > 0.01)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED and flame_rect != null:
			flame_rect.pivot_offset = size * Vector2(0.5, 0.80)

	func _build_flame_material() -> void:
		var shader := Shader.new()
		shader.code = FLAME_WARBLE_SHADER
		flame_material = ShaderMaterial.new()
		flame_material.shader = shader

	func _process(delta: float) -> void:
		var target := 1.0 if active else 0.0
		heat = lerpf(heat, target, 1.0 - exp(-delta * 5.0))
		if active:
			_advance_frame(delta)
		_sync_visual_transform()
		if not active and heat <= 0.01:
			heat = 0.0
			set_process(false)

	func _build_frame_textures() -> void:
		frame_textures.clear()
		var atlas := load(FLAME_ATLAS_PATH) as Texture2D
		if atlas == null:
			return
		for frame_index in range(FRAME_COUNT):
			var frame := AtlasTexture.new()
			frame.atlas = atlas
			frame.region = Rect2(Vector2(float(frame_index) * FLAME_CELL_SIZE.x, 0.0), FLAME_CELL_SIZE)
			frame.filter_clip = true
			frame_textures.append(frame)

	func _advance_frame(delta: float) -> void:
		if frame_textures.is_empty():
			return
		frame_elapsed += maxf(0.0, delta)
		var guard := 0
		while guard < 8 and frame_elapsed >= _current_duration():
			frame_elapsed -= _current_duration()
			sequence_index = (sequence_index + 1) % FRAME_SEQUENCE.size()
			_apply_frame(sequence_index)
			guard += 1

	func _current_duration() -> float:
		return FRAME_DURATION_SECONDS

	func _apply_frame(next_sequence_index: int) -> void:
		if flame_rect == null or frame_textures.is_empty():
			return
		sequence_index = clampi(next_sequence_index, 0, FRAME_SEQUENCE.size() - 1)
		var frame_index := clampi(int(FRAME_SEQUENCE[sequence_index]), 0, frame_textures.size() - 1)
		flame_rect.texture = frame_textures[frame_index]

	func _build_smoke_puffs() -> void:
		smoke_puffs.clear()
		_build_smoke_textures()
		if smoke_textures.is_empty():
			return
		for index in range(SMOKE_PUFF_COUNT):
			var puff := TextureRect.new()
			puff.texture = smoke_textures[index % smoke_textures.size()]
			puff.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			puff.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			puff.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			puff.mouse_filter = Control.MOUSE_FILTER_IGNORE
			puff.z_index = 2
			add_child(puff)
			smoke_puffs.append(puff)

	func _build_smoke_textures() -> void:
		smoke_textures.clear()
		var atlas := load(SMOKE_ATLAS_PATH) as Texture2D
		if atlas == null:
			return
		for frame_index in range(SMOKE_FRAME_COUNT):
			var frame := AtlasTexture.new()
			frame.atlas = atlas
			frame.region = Rect2(Vector2(float(frame_index) * SMOKE_CELL_SIZE.x, 0.0), SMOKE_CELL_SIZE)
			frame.filter_clip = true
			smoke_textures.append(frame)

	func _sync_visual_transform() -> void:
		if flame_rect == null:
			return
		var t := float(Time.get_ticks_msec()) / 1000.0
		flame_rect.modulate = Color(1.0, 1.0, 1.0, clampf(heat, 0.0, 1.0))
		flame_rect.pivot_offset = size * Vector2(0.5, 0.80)
		var warm_scale := 0.96 + sin(t * 2.1) * 0.012 * heat
		var side_scale := 1.0 + sin(t * 2.8 + 0.6) * 0.018 * heat
		var height_scale := 1.0 + sin(t * 2.4 + 1.1) * 0.014 * heat
		flame_rect.scale = Vector2(warm_scale * side_scale, warm_scale * height_scale)
		flame_rect.rotation = sin(t * 1.7 + 0.4) * 0.018 * heat
		if flame_material != null:
			flame_material.set_shader_parameter("heat", clampf(heat, 0.0, 1.0))
		_sync_smoke_puffs(t)

	func _sync_smoke_puffs(t: float) -> void:
		if smoke_puffs.is_empty():
			return
		var base := size * Vector2(0.5, 0.44)
		for index in range(smoke_puffs.size()):
			var puff := smoke_puffs[index]
			var phase := float(index) * 0.23
			var cycle := fmod(t * (0.12 + float(index % 2) * 0.025) + phase, 1.0)
			var fade := sin(cycle * PI)
			var lane := float(index) - float(smoke_puffs.size() - 1) * 0.5
			var side := lane * 52.0 + sin(t * 0.95 + float(index) * 1.7) * 28.0
			var rise := cycle * (220.0 + float(index % 2) * 28.0)
			var puff_size := 178.0 + cycle * 126.0 + float(index % 2) * 28.0
			puff.size = Vector2(puff_size, puff_size)
			puff.position = base + Vector2(side, -rise + 24.0) - puff.size * 0.5
			puff.pivot_offset = puff.size * 0.5
			puff.rotation = sin(t * 0.58 + float(index)) * 0.13
			puff.scale = Vector2.ONE * (0.9 + cycle * 0.18)
			puff.modulate = Color(1.0, 1.0, 1.0, clampf(heat * fade * 0.36, 0.0, 0.36))


class _ActivityCardInnerShadow:
	extends Control

	var radius := 66.0
	var inset := 14.0
	var shadow_height := 42.0
	var side_lift := 10.0
	var shadow_color := Color(0.05, 0.04, 0.03, 0.24)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var left := inset
		var right := maxf(left, size.x - inset)
		var bottom := maxf(inset, size.y - inset * 0.62)
		var lines := maxi(1, int(minf(8.0, shadow_height)))
		var step_y := shadow_height / float(lines)
		for i in range(lines):
			var y := bottom - shadow_height + float(i) * step_y
			var depth := float(i) / maxf(1.0, float(lines - 1))
			var alpha := shadow_color.a * depth * depth
			var lift := side_lift * (1.0 - depth)
			var side_curve := clampf((y - (bottom - shadow_height - lift)) / maxf(1.0, shadow_height + lift), 0.0, 1.0)
			var x_inset := (1.0 - side_curve) * radius * 0.26
			var line_left := left + x_inset
			var line_right := right - x_inset
			if y > size.y - radius:
				var dy := y - (size.y - radius)
				var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
				var corner_inset := radius - chord
				line_left = maxf(line_left, corner_inset + 18.0)
				line_right = minf(line_right, size.x - corner_inset - 18.0)
			if line_right > line_left:
				draw_line(Vector2(line_left, y), Vector2(line_right, y), Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha), step_y + 1.0, false)
		draw_line(Vector2(left + radius * 0.35, bottom - shadow_height - side_lift * 0.44), Vector2(right - radius * 0.35, bottom - shadow_height - side_lift * 0.44), Color(1, 1, 1, 0.08), 4.0, true)


class _CardBorder:
	extends Control

	const FAST_ARC_SEGMENTS := 8

	var border_color := Color("#171615")
	var border_width := 8.0
	var radius := 66.0
	var bottom_trim := 0.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var half := border_width * 0.5
		var left := half
		var right := maxf(half, size.x - half)
		var top := half
		var bottom := maxf(top + radius, size.y - half - maxf(0.0, bottom_trim))
		var r := maxf(0.0, minf(radius, minf(size.x, size.y) * 0.5 - half))
		var points := PackedVector2Array()
		points.append(Vector2(left, bottom))
		points.append(Vector2(left, top + r))
		_append_arc_points(points, Vector2(left + r, top + r), r, PI, PI * 1.5)
		points.append(Vector2(right - r, top))
		_append_arc_points(points, Vector2(right - r, top + r), r, PI * 1.5, PI * 2.0)
		points.append(Vector2(right, bottom))
		draw_polyline(points, border_color, border_width, true)

	func _append_arc_points(points: PackedVector2Array, center: Vector2, arc_radius: float, start_angle: float, end_angle: float) -> void:
		for i in range(1, FAST_ARC_SEGMENTS + 1):
			var t := float(i) / float(FAST_ARC_SEGMENTS)
			var angle := lerpf(start_angle, end_angle, t)
			points.append(center + Vector2(cos(angle), sin(angle)) * arc_radius)


class PassiveIconSprite:
	extends Control

	var texture: Texture2D
	var draw_size := Vector2(24, 24)
	var draw_offset := Vector2.ZERO
	var shadow_offset := Vector2.ZERO
	var shadow_alpha := 0.0
	var stroke_color := Color.TRANSPARENT
	var stroke_width := 0.0

	func configure(next_texture: Texture2D, next_size: Vector2, next_offset := Vector2.ZERO) -> void:
		texture = next_texture
		draw_size = next_size
		draw_offset = next_offset
		custom_minimum_size = draw_size + Vector2(absf(draw_offset.x), absf(draw_offset.y)) * 2.0
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		if texture == null:
			return
		var rect := Rect2(draw_offset, draw_size)
		if shadow_alpha > 0.0:
			draw_texture_rect(texture, Rect2(draw_offset + shadow_offset, draw_size), false, Color(0, 0, 0, shadow_alpha))
		if stroke_width > 0.0 and stroke_color.a > 0.0:
			var stroke_offsets: Array[Vector2] = [
				Vector2(-stroke_width, 0),
				Vector2(stroke_width, 0),
				Vector2(0, -stroke_width),
				Vector2(0, stroke_width),
				Vector2(-stroke_width * 0.72, -stroke_width * 0.72),
				Vector2(stroke_width * 0.72, -stroke_width * 0.72),
				Vector2(-stroke_width * 0.72, stroke_width * 0.72),
				Vector2(stroke_width * 0.72, stroke_width * 0.72)
			]
			for offset in stroke_offsets:
				draw_texture_rect(texture, Rect2(draw_offset + offset, draw_size), false, stroke_color)
		draw_texture_rect(texture, rect, false, Color.WHITE)


class PassiveLogPileSprite:
	extends Control

	var texture: Texture2D
	var icon_size := Vector2(24, 24)
	var log_slots: Array = []
	var log_rotations: Array = []
	var visible_logs := 0
	var shadow_rect := Rect2()
	var shadow_color := Color(0.10, 0.07, 0.04, 0.20)

	func configure(
		next_texture: Texture2D,
		next_icon_size: Vector2,
		next_log_slots: Array,
		next_log_rotations: Array,
		next_visible_logs: int,
		next_shadow_rect: Rect2
	) -> void:
		texture = next_texture
		icon_size = next_icon_size
		log_slots = next_log_slots
		log_rotations = next_log_rotations
		visible_logs = next_visible_logs
		shadow_rect = next_shadow_rect
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		_draw_shadow()
		if texture == null:
			return
		var count := mini(visible_logs, log_slots.size())
		for i in range(count):
			var base_position := log_slots[i] as Vector2
			var rotation := deg_to_rad(float(log_rotations[i])) if i < log_rotations.size() else 0.0
			draw_set_transform(base_position + icon_size * 0.5, rotation, Vector2.ONE)
			draw_texture_rect(texture, Rect2(-icon_size * 0.5, icon_size), false, Color.WHITE)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	func _draw_shadow() -> void:
		if shadow_rect.size.x <= 1.0 or shadow_rect.size.y <= 1.0:
			return
		var center := shadow_rect.position + shadow_rect.size * 0.5
		var radius_x := shadow_rect.size.x * 0.5
		var radius_y := shadow_rect.size.y * 0.5
		var line_count := maxi(10, int(ceil(shadow_rect.size.y)))
		for i in range(line_count):
			var t := float(i) / maxf(1.0, float(line_count - 1))
			var y := lerpf(-radius_y, radius_y, t)
			var normalized_y := y / maxf(1.0, radius_y)
			var width := radius_x * sqrt(maxf(0.0, 1.0 - normalized_y * normalized_y))
			var center_weight := 1.0 - absf(normalized_y)
			var alpha := shadow_color.a * pow(center_weight, 2.15)
			var color := Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha)
			draw_line(Vector2(center.x - width, center.y + y), Vector2(center.x + width, center.y + y), color, 2.0, true)


var host
var firepit_stop_hold_active = false
var firepit_stop_hold_armed = false
var firepit_stop_hold_unloading = false
var firepit_stop_hold_elapsed = 0.0
var firepit_stop_hold_unload_elapsed = 0.0
var firepit_stop_hold_position = Vector2.ZERO
var firepit_stop_hold_start_position = Vector2.ZERO
var passive_button_press_source: Control
var passive_button_press_kind := ""
var passive_button_press_module_id := ""
var passive_button_press_stat_type := ""
var passive_button_press_popover: Control
var passive_button_press_position := Vector2.ZERO
var passive_button_press_dragged := false
var passive_button_press_touch_index := -1
var passive_button_pending_tap_id := 0


func _init(host_ref) -> void:
	host = host_ref


func _route_passive_button_global_input(event: InputEvent) -> bool:
	if passive_button_press_source == null or not is_instance_valid(passive_button_press_source):
		return false
	var event_position := Vector2.ZERO
	var is_drag := false
	var is_release := false
	if event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_drag = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		event_position = (event as InputEventMouseButton).global_position
		is_release = not (event as InputEventMouseButton).pressed
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		is_drag = true
	elif event is InputEventScreenTouch and (passive_button_press_touch_index < 0 or (event as InputEventScreenTouch).index == passive_button_press_touch_index):
		event_position = (event as InputEventScreenTouch).position
		is_release = not (event as InputEventScreenTouch).pressed
	if not is_drag and not is_release:
		return false
	if event_position.distance_to(passive_button_press_position) > host.PASSIVE_BUTTON_TAP_RELEASE_SLOP:
		passive_button_press_dragged = true
		_invalidate_passive_button_tap()
		host._skill_swipe_activity_surface().skill_swipe_button_suppressed_until_msec = Time.get_ticks_msec() + host.SKILL_SWIPE_BUTTON_SUPPRESS_MSEC
	if is_release and passive_button_press_dragged:
		_clear_passive_button_press()
		return true
	return false


func _route_passive_info_button_press(event: InputEvent) -> bool:
	var event_position := Vector2.ZERO
	var touch_index := -1
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		pressed = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		touch_index = touch_event.index
		pressed = touch_event.pressed
	if not pressed:
		return false
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position):
		return false
	if not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
		return false
	for raw_card in host.action_cards.values():
		var card := raw_card as Dictionary
		if not bool(card.get("passive", false)):
			continue
		var info_button: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("info_button"))
		var info_popover: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("info_popover"))
		var action := card.get("action", {}) as Dictionary
		if info_button == null or info_popover == null or action.is_empty():
			continue
		if not info_button.is_visible_in_tree():
			continue
		if not info_button.get_global_rect().grow(8.0).has_point(event_position):
			continue
		var module_id := str(action.get("id", PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID))
		passive_button_press_source = info_button
		passive_button_press_kind = "info"
		passive_button_press_module_id = module_id
		passive_button_press_stat_type = ""
		passive_button_press_popover = info_popover
		passive_button_press_position = event_position
		passive_button_press_dragged = false
		passive_button_press_touch_index = touch_index
		host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(event_position, touch_index)
		return true
	return false


func _schedule_passive_info_click_away_dismiss(event: InputEvent) -> void:
	var event_position := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		pressed = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	for raw_card in host.action_cards.values():
		var card := raw_card as Dictionary
		if not bool(card.get("passive", false)):
			continue
		var info_popover: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("info_popover"))
		if info_popover == null or not info_popover.visible:
			continue
		var info_button: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("info_button"))
		if info_button != null and info_button.get_global_rect().grow(8.0).has_point(event_position):
			continue
		if info_popover.get_global_rect().grow(8.0).has_point(event_position):
			continue
		_schedule_passive_info_popover_dismiss(info_popover)


func _on_passive_module_button_input(event: InputEvent, action_kind: String, module_id: String, stat_type: String, info_popover: Control, source: Control) -> void:
	var event_position: Vector2 = host._input_routing_shell()._passive_button_event_position(event, source)
	var is_press := false
	var is_release := false
	var touch_index := -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		is_press = touch_event.pressed
		is_release = not touch_event.pressed
		touch_index = touch_event.index
	if is_press:
		if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position):
			return
		if not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
			return
		if action_kind != "info" and _route_passive_info_button_press(event):
			host.get_viewport().set_input_as_handled()
			return
		passive_button_press_source = source
		passive_button_press_kind = action_kind
		passive_button_press_module_id = module_id
		passive_button_press_stat_type = stat_type
		passive_button_press_popover = info_popover
		passive_button_press_position = event_position
		passive_button_press_dragged = false
		passive_button_press_touch_index = touch_index
		host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
		host.get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if passive_button_press_source == source or host._skill_swipe_activity_surface().skill_swipe_tracking:
			if passive_button_press_source == source:
				if event_position.distance_to(passive_button_press_position) > host.PASSIVE_BUTTON_TAP_RELEASE_SLOP:
					passive_button_press_dragged = true
					_invalidate_passive_button_tap()
			host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
			host.get_viewport().set_input_as_handled()
		return
	if is_release:
		var matches_press := passive_button_press_source == source and passive_button_press_kind == action_kind
		if host._skill_swipe_activity_surface().skill_swipe_tracking:
			host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
		var tap_like: bool = (
			matches_press
			and not passive_button_press_dragged
			and host._input_routing_shell()._position_inside_detail_actions_viewport(event_position)
			and event_position.distance_to(passive_button_press_position) <= host.PASSIVE_BUTTON_TAP_RELEASE_SLOP
		)
		if tap_like and not host._skill_swipe_activity_surface()._skill_swipe_suppresses_button_action():
			_schedule_passive_module_button_activation(action_kind, module_id, stat_type, info_popover, source)
		else:
			_clear_passive_button_press()
		host.get_viewport().set_input_as_handled()


func _route_passive_module_button_input_by_position(event: InputEvent) -> bool:
	if host.current_screen != "skill" and host.current_screen != "pinned" and host.current_screen != "menu":
		return false
	if passive_button_press_source != null and is_instance_valid(passive_button_press_source):
		if event is InputEventMouseMotion or event is InputEventScreenDrag or host.button_press_runtime._input_event_releases_primary_pointer(event):
			var active_source := passive_button_press_source
			var routed_event := _passive_button_event_for_source(event, active_source)
			_on_passive_module_button_input(
				routed_event,
				passive_button_press_kind,
				passive_button_press_module_id,
				passive_button_press_stat_type,
				passive_button_press_popover,
				active_source
			)
			return true
	if not host._input_routing_shell()._is_primary_press_event(event):
		return false
	var event_position := _passive_button_global_event_position(event)
	if event_position == Vector2.INF:
		return false
	if host._input_routing_shell()._position_inside_bottom_interactive_ui(event_position) or not host._input_routing_shell()._position_inside_detail_actions_viewport(event_position):
		return false
	var hit := _passive_button_hit_at_position(event_position)
	if hit.is_empty():
		return false
	var source := hit.get("source", null) as Control
	if source == null or not is_instance_valid(source):
		return false
	_on_passive_module_button_input(
		_passive_button_event_for_source(event, source),
		str(hit.get("kind", "")),
		str(hit.get("module_id", "")),
		str(hit.get("stat_type", "")),
		hit.get("popover", null) as Control,
		source
	)
	return true


func _passive_button_global_event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).global_position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).global_position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2.INF


func _passive_button_event_for_source(event: InputEvent, source: Control) -> InputEvent:
	if source == null or not is_instance_valid(source):
		return event
	var global_position := _passive_button_global_event_position(event)
	if global_position == Vector2.INF:
		return event
	var local_position := source.get_global_transform().affine_inverse() * global_position
	var duplicate_event := event.duplicate()
	if duplicate_event is InputEventMouseButton:
		var mouse_button := duplicate_event as InputEventMouseButton
		mouse_button.position = local_position
		mouse_button.global_position = global_position
	elif duplicate_event is InputEventMouseMotion:
		var mouse_motion := duplicate_event as InputEventMouseMotion
		mouse_motion.position = local_position
		mouse_motion.global_position = global_position
	elif duplicate_event is InputEventScreenTouch:
		(duplicate_event as InputEventScreenTouch).position = global_position
	elif duplicate_event is InputEventScreenDrag:
		(duplicate_event as InputEventScreenDrag).position = global_position
	return duplicate_event


func _passive_button_hit_at_position(event_position: Vector2) -> Dictionary:
	host._skill_detail_surface()._prune_invalid_action_cards()
	var keys: Array = host.action_card_keys.duplicate()
	keys.reverse()
	for raw_action_key in host.action_cards.keys():
		var action_key := str(raw_action_key)
		if not keys.has(action_key):
			keys.push_front(action_key)
	for raw_key in keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card := host.action_cards.get(key, {}) as Dictionary
		if not bool(card.get("passive", false)):
			continue
		var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		if not pop.get_global_rect().has_point(event_position):
			continue
		var action := card.get("action", {}) as Dictionary
		var module_id := str(action.get("id", card.get("action_id", PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID)))
		var info_hit := _passive_source_hit_dict(card.get("info_button", null), event_position, "info", module_id, "", card.get("info_popover", null))
		if not info_hit.is_empty():
			return info_hit
		var plank_hit := _passive_source_hit_dict(card.get("plank", null), event_position, "plank", module_id)
		if not plank_hit.is_empty():
			return plank_hit
		var upgrade_buttons := card.get("upgrade_buttons", {}) as Dictionary
		for raw_stat_type in ["time", "yield", "capacity"]:
			var stat_type := str(raw_stat_type)
			var upgrade_hit := _passive_source_hit_dict(upgrade_buttons.get(stat_type, null), event_position, "upgrade", module_id, stat_type)
			if not upgrade_hit.is_empty():
				return upgrade_hit
		var firepit_hit := _passive_source_hit_dict(card.get("toggle", null), event_position, "firepit", module_id)
		if not firepit_hit.is_empty():
			return firepit_hit
		var loot: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("loot", null))
		if loot != null and loot.has_meta("passive_log_collect_hotspot_id"):
			var hotspot: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(loot.get_meta("passive_log_collect_hotspot_id", 0))))
			var hotspot_hit := _passive_source_hit_dict(hotspot, event_position, "collect", module_id)
			if not hotspot_hit.is_empty():
				return hotspot_hit
		var collect_hit := _passive_source_hit_dict(card.get("button", null), event_position, "collect", module_id)
		if not collect_hit.is_empty():
			return collect_hit
	return {}


func _passive_source_hit_dict(source_variant, event_position: Vector2, action_kind: String, module_id: String, stat_type := "", info_popover_variant = null) -> Dictionary:
	var source: Control = host._app_lifecycle_runtime().valid_control_ref(source_variant)
	if source == null or not source.is_inside_tree() or not source.is_visible_in_tree():
		return {}
	if source.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return {}
	if source is BaseButton and (source as BaseButton).disabled:
		return {}
	if not source.get_global_rect().has_point(event_position):
		return {}
	return {
		"source": source,
		"kind": action_kind,
		"module_id": module_id,
		"stat_type": stat_type,
		"popover": host._app_lifecycle_runtime().valid_control_ref(info_popover_variant)
	}


func _schedule_passive_module_button_activation(action_kind: String, module_id: String, stat_type: String, info_popover: Control, source: Control) -> void:
	_invalidate_passive_button_tap()
	var tap_id := passive_button_pending_tap_id
	var source_id := source.get_instance_id() if source != null and is_instance_valid(source) else 0
	var popover_id := info_popover.get_instance_id() if info_popover != null and is_instance_valid(info_popover) else 0
	await host.get_tree().create_timer(host.PASSIVE_BUTTON_TAP_CONFIRM_SECONDS).timeout
	if tap_id != passive_button_pending_tap_id:
		return
	var source_ref: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(source_id)) if source_id != 0 else null
	if source_ref == null or passive_button_press_source != source_ref or passive_button_press_kind != action_kind:
		return
	if passive_button_press_dragged or host._skill_swipe_activity_surface()._skill_swipe_suppresses_button_action():
		_clear_passive_button_press()
		return
	_clear_passive_button_press()
	var popover_ref: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(popover_id)) if popover_id != 0 else null
	_activate_passive_module_button(action_kind, module_id, stat_type, popover_ref)
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)


func _activate_passive_module_button(action_kind: String, module_id: String, stat_type: String, info_popover: Control) -> void:
	if action_kind == "collect":
		host._passive_modules_runtime().collect_passive_module(module_id, host._unix_now())
	elif action_kind == "info":
		_toggle_passive_info_popover(info_popover)
	elif action_kind == "plank":
		host._passive_modules_runtime().toggle_plank_boost()
	elif action_kind == "upgrade":
		host._passive_modules_runtime().upgrade_passive_module(module_id, stat_type, host._unix_now())
	elif action_kind == "firepit":
		host._passive_modules_runtime().toggle_firepit_pressed(module_id, host._unix_now())


func _on_passive_collect_pressed(module_id: String) -> void:
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	_clear_passive_button_press()
	host._passive_modules_runtime().collect_passive_module(module_id, host._unix_now())


func _on_passive_plank_pressed(module_id := PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID) -> void:
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	_clear_passive_button_press()
	host._passive_modules_runtime().toggle_plank_boost()


func _on_passive_upgrade_pressed(module_id: String, stat_type: String) -> void:
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	_clear_passive_button_press()
	host._passive_modules_runtime().upgrade_passive_module(module_id, stat_type, host._unix_now())


func _invalidate_passive_button_tap() -> void:
	passive_button_pending_tap_id += 1


func _clear_passive_button_press() -> void:
	_invalidate_passive_button_tap()
	passive_button_press_source = null
	passive_button_press_kind = ""
	passive_button_press_module_id = ""
	passive_button_press_stat_type = ""
	passive_button_press_popover = null
	passive_button_press_position = Vector2.ZERO
	passive_button_press_dragged = false
	passive_button_press_touch_index = -1


func _on_firepit_button_down(module_id := "", button: Button = null) -> void:
	if module_id.is_empty():
		module_id = PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID
	var passive_runtime = host._passive_modules_runtime()
	var now: int = host._unix_now()
	if not passive_runtime.is_firepit_module(module_id) or not passive_runtime.is_passive_module_unlocked(module_id):
		return
	passive_runtime.apply_firepit_fuel(now)
	if not passive_runtime.firepit_active(now):
		return
	host._action_stop_hold().cancel_action()
	var center = host.get_viewport().get_mouse_position()
	if button != null and is_instance_valid(button):
		center = _control_local_point_to_global(button, button.size * 0.5)
	_begin_firepit_stop_hold(center)


func _on_firepit_button_up(module_id := "") -> void:
	if module_id.is_empty():
		module_id = PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID
	if not host._passive_modules_runtime().is_firepit_module(module_id):
		return
	if firepit_stop_hold_unloading:
		return
	_cancel_firepit_stop_hold()


func _begin_firepit_stop_hold(pointer_position: Vector2) -> void:
	firepit_stop_hold_active = true
	firepit_stop_hold_armed = false
	firepit_stop_hold_unloading = false
	firepit_stop_hold_elapsed = 0.0
	firepit_stop_hold_unload_elapsed = 0.0
	firepit_stop_hold_position = pointer_position
	firepit_stop_hold_start_position = pointer_position
	host._action_stop_hold().hide_ring()


func _process_firepit_stop_hold(delta: float) -> void:
	if not firepit_stop_hold_active and not firepit_stop_hold_unloading:
		return
	if not host._passive_modules_runtime().firepit_active(host._unix_now()):
		_cancel_firepit_stop_hold()
		return
	if firepit_stop_hold_unloading:
		firepit_stop_hold_unload_elapsed += delta
		var unload = clampf(firepit_stop_hold_unload_elapsed / StopHoldCircle.ACTION_STOP_HOLD_UNLOAD_SECONDS, 0.0, 1.0)
		_sync_firepit_stop_hold_circle(1.0, unload, true)
		if unload >= 1.0:
			host._action_stop_hold().hide_ring()
			_clear_firepit_stop_hold_state()
			host._passive_modules_runtime().extinguish_firepit(host._unix_now())
		return
	if not firepit_stop_hold_armed:
		firepit_stop_hold_elapsed += delta
		if firepit_stop_hold_elapsed < StopHoldCircle.ACTION_STOP_HOLD_ARM_DELAY_SECONDS:
			return
		firepit_stop_hold_armed = true
		firepit_stop_hold_elapsed = 0.0
		_show_firepit_stop_hold_circle()
		return
	firepit_stop_hold_elapsed += delta
	var progress = clampf(firepit_stop_hold_elapsed / FIREPIT_STOP_HOLD_SECONDS, 0.0, 1.0)
	_sync_firepit_stop_hold_circle(progress, 0.0, false)
	if progress >= 1.0:
		firepit_stop_hold_active = false
		firepit_stop_hold_unloading = true
		firepit_stop_hold_unload_elapsed = 0.0
		_sync_firepit_stop_hold_circle(1.0, 0.0, true)


func _show_firepit_stop_hold_circle() -> void:
	host._action_stop_hold().show_ring(Color("#ff9c2f"), firepit_stop_hold_position)


func _sync_firepit_stop_hold_circle(progress: float, unload: float, unloading: bool) -> void:
	host._action_stop_hold().sync_ring(firepit_stop_hold_position, progress, unload, unloading)


func _cancel_firepit_stop_hold() -> void:
	host._action_stop_hold().hide_ring()
	_clear_firepit_stop_hold_state()


func _clear_firepit_stop_hold_state() -> void:
	firepit_stop_hold_active = false
	firepit_stop_hold_armed = false
	firepit_stop_hold_unloading = false
	firepit_stop_hold_elapsed = 0.0
	firepit_stop_hold_unload_elapsed = 0.0
	firepit_stop_hold_position = Vector2.ZERO
	firepit_stop_hold_start_position = Vector2.ZERO


func _passive_module_shell(skill_id: String, action: Dictionary, content_width: float, interactive: bool, passive_face_bottom_trim: float) -> Dictionary:
	var card_root = Control.new()
	card_root.custom_minimum_size = Vector2(content_width, host.PASSIVE_MODULE_CARD_HEIGHT)
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = not interactive
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE if not interactive else Control.MOUSE_FILTER_PASS

	var pop_card = Control.new()
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = host.ACTION_CARD_POP_GUTTER
	pop_card.offset_right = -host.ACTION_CARD_POP_GUTTER
	pop_card.offset_top = 0.0
	pop_card.offset_bottom = 0.0
	pop_card.clip_contents = false
	pop_card.mouse_filter = Control.MOUSE_FILTER_IGNORE if not interactive else Control.MOUSE_FILTER_PASS
	card_root.add_child(pop_card)

	var bg = RoundedTextureRect.new()
	bg.texture = host.visual_texture_cache._texture_or_visual_fallback(str(action.get("bg", "res://assets/content/woodcutting/backgrounds/01-early.png")))
	bg.radius = 66.0
	bg.art_height = host.PASSIVE_MODULE_CARD_HEIGHT
	bg.fallback_color = ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_bottom = -passive_face_bottom_trim
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	pop_card.add_child(bg)

	var shade = _passive_card_shade(pop_card, passive_face_bottom_trim)
	return {"root": card_root, "pop": pop_card, "bg": bg, "shade": shade}


func _passive_card_shade(pop_card: Control, bottom_trim: float) -> Panel:
	var shade = Panel.new()
	shade.add_theme_stylebox_override("panel", ActivityCardStyles.cached_shade(0.50))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.offset_bottom = -bottom_trim
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.visible = false
	shade.z_index = 224
	pop_card.add_child(shade)
	return shade


func _passive_collect_button(pop_card: Control, module_id: String, interactive: bool) -> Button:
	var collect_button = Button.new()
	collect_button.text = ""
	collect_button.focus_mode = Control.FOCUS_NONE
	collect_button.flat = true
	collect_button.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	collect_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	host._apply_empty_button_style(collect_button)
	collect_button.z_index = 180
	host.button_press_runtime.attach_default_button_sfx(collect_button)
	if interactive:
		collect_button.gui_input.connect(_on_passive_module_button_input.bind("collect", module_id, "", null, collect_button))
		collect_button.pressed.connect(_on_passive_collect_pressed.bind(module_id))
	pop_card.add_child(collect_button)
	return collect_button


func _passive_module_title(card_root: Control, pop_card: Control, skill_id: String, action: Dictionary, default_name: String, title_width: float) -> Label:
	var title = host._label(str(action.get("name", default_name)), 60, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	title.add_theme_constant_override("outline_size", 17)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.position = Vector2(37, 24)
	title.size = Vector2(title_width, 106)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.set_meta("module_ui_title_label", true)
	title.set_meta("activity_card_locked_title_z_index", 200)
	title.z_index = ActivityCardStyles.activity_card_title_z_index(host._activity_unlock_runtime()._is_action_unlocked(skill_id, action), title, host.MODULE_TITLE_OVER_PIN_Z_INDEX)
	pop_card.add_child(title)
	card_root.set_meta("module_ui_title_label_id", title.get_instance_id())
	pop_card.set_meta("module_ui_title_label_id", title.get_instance_id())
	return title


func _passive_info_controls(pop_card: Control, module_id: String, info_text: String, popover_position: Vector2, popover_size: Vector2, label_size: Vector2, button_position: Vector2, interactive: bool) -> Dictionary:
	var info_popover = PanelContainer.new()
	info_popover.position = popover_position
	info_popover.custom_minimum_size = popover_size
	info_popover.size = info_popover.custom_minimum_size
	info_popover.visible = false
	info_popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_popover.z_index = 4095
	info_popover.z_as_relative = false
	info_popover.add_theme_stylebox_override("panel", PassiveModuleStyles.popup(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style")))
	pop_card.add_child(info_popover)
	var info_label = host._label(info_text, 52, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = label_size
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_popover.add_child(info_label)

	var info_button = Button.new()
	info_button.text = "i"
	info_button.custom_minimum_size = Vector2(43, 43)
	info_button.size = info_button.custom_minimum_size
	info_button.position = button_position
	info_button.focus_mode = Control.FOCUS_NONE
	info_button.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	info_button.z_index = 221
	info_button.add_theme_font_size_override("font_size", host.MIN_MOBILE_BODY_FONT_SIZE)
	host._skill_detail_surface()._apply_info_symbol_button_text_color(info_button)
	info_button.add_theme_stylebox_override("normal", PassiveModuleStyles.round_button(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	info_button.add_theme_stylebox_override("hover", PassiveModuleStyles.round_button(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	info_button.add_theme_stylebox_override("pressed", PassiveModuleStyles.round_button(host.COLOR_GOLD.darkened(0.08), host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	info_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host.button_press_runtime.attach_button_depress_animation(info_button, 0.90)
	if host.app_bold_font != null:
		info_button.add_theme_font_override("font", host.app_bold_font)
	if interactive:
		info_button.gui_input.connect(_on_passive_module_button_input.bind("info", module_id, "", info_popover, info_button))
		info_button.pressed.connect(_toggle_passive_info_popover.bind(info_popover))
	pop_card.add_child(info_button)
	return {"button": info_button, "popover": info_popover, "label": info_label}


func _toggle_passive_info_popover(info_popover: Control) -> void:
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	_clear_passive_button_press()
	if info_popover != null and is_instance_valid(info_popover):
		if info_popover.visible:
			_hide_passive_info_popover(info_popover)
		else:
			_show_passive_info_popover(info_popover)


func _show_passive_info_popover(info_popover: Control) -> void:
	_cancel_passive_info_fade(info_popover)
	info_popover.set_meta("info_popover_show_requested", true)
	info_popover.visible = true
	info_popover.modulate.a = 1.0


func _hide_passive_info_popover(info_popover: Control) -> void:
	if info_popover == null or not is_instance_valid(info_popover):
		return
	_cancel_passive_info_fade(info_popover)
	info_popover.set_meta("info_popover_show_requested", false)
	info_popover.visible = false
	info_popover.modulate.a = 1.0


func _prewarm_passive_info_popover(info_popover: Control) -> void:
	if info_popover == null or not is_instance_valid(info_popover):
		return
	if bool(info_popover.get_meta("info_popover_prewarm_started", false)):
		return
	info_popover.set_meta("info_popover_prewarm_started", true)
	call_deferred("_prewarm_passive_info_popover_deferred", info_popover.get_instance_id())


func _prewarm_passive_info_popover_deferred(info_popover_id: int) -> void:
	var info_popover: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(info_popover_id))
	if info_popover == null:
		return
	if info_popover.visible:
		info_popover.set_meta("info_popover_prewarmed", true)
		return
	info_popover.visible = true
	info_popover.modulate.a = 0.0
	for _i in range(INFO_POPOVER_PREWARM_FRAMES):
		await host.get_tree().process_frame
		info_popover = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(info_popover_id))
		if info_popover == null:
			return
	if not bool(info_popover.get_meta("info_popover_show_requested", false)):
		info_popover.visible = false
		info_popover.modulate.a = 1.0
	info_popover.set_meta("info_popover_prewarmed", true)


func _schedule_passive_info_popover_dismiss(info_popover: Control) -> void:
	if info_popover == null or not is_instance_valid(info_popover) or not info_popover.visible:
		return
	_cancel_passive_info_fade(info_popover)
	var dismiss_id := int(info_popover.get_meta("dismiss_id", 0)) + 1
	info_popover.set_meta("dismiss_id", dismiss_id)
	await host.get_tree().create_timer(PASSIVE_INFO_CLICK_AWAY_SECONDS).timeout
	if info_popover == null or not is_instance_valid(info_popover) or not info_popover.visible:
		return
	if int(info_popover.get_meta("dismiss_id", 0)) != dismiss_id:
		return
	_fade_passive_info_popover(info_popover)


func _fade_passive_info_popover(info_popover: Control) -> void:
	_cancel_passive_info_fade(info_popover)
	var tween: Tween = host.create_tween()
	info_popover.set_meta("fade_tween", tween)
	tween.tween_property(info_popover, "modulate:a", 0.0, host.TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var popover_id := info_popover.get_instance_id()
	tween.tween_callback(_finish_passive_info_popover_fade.bind(popover_id))


func _finish_passive_info_popover_fade(popover_id: int) -> void:
	var cb_popover: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(popover_id))
	if cb_popover != null:
		cb_popover.visible = false
		cb_popover.modulate.a = 1.0
		if cb_popover.has_meta("fade_tween"):
			cb_popover.remove_meta("fade_tween")


func _cancel_passive_info_fade(info_popover: Control) -> void:
	if info_popover == null or not is_instance_valid(info_popover):
		return
	info_popover.set_meta("dismiss_id", int(info_popover.get_meta("dismiss_id", 0)) + 1)
	if info_popover.has_meta("fade_tween"):
		var tween_variant = info_popover.get_meta("fade_tween")
		host._app_lifecycle_runtime()._kill_tween_value(tween_variant)
		info_popover.remove_meta("fade_tween")
	info_popover.modulate.a = 1.0


func _passive_module_resource_controls(pop_card: Control, module_id: String, interactive: bool) -> Dictionary:
	var plank_button = Button.new()
	plank_button.text = ""
	plank_button.icon = host.visual_texture_cache._texture_or_visual_fallback(MaterialRuntime.PLANK_ICON_TEXTURE)
	plank_button.expand_icon = true
	plank_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plank_button.custom_minimum_size = Vector2(96, 84)
	plank_button.anchor_left = 1.0
	plank_button.anchor_right = 1.0
	plank_button.offset_left = -381
	plank_button.offset_right = -285
	plank_button.offset_top = 24
	plank_button.offset_bottom = 108
	plank_button.focus_mode = Control.FOCUS_NONE
	plank_button.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	plank_button.z_index = 220
	plank_button.tooltip_text = ""
	plank_button.add_theme_constant_override("icon_max_width", 146)
	host.button_press_runtime.attach_button_depress_animation(plank_button, 0.94)
	if interactive:
		plank_button.gui_input.connect(_on_passive_module_button_input.bind("plank", module_id, "", null, plank_button))
		plank_button.pressed.connect(_on_passive_plank_pressed.bind(module_id))
	pop_card.add_child(plank_button)

	var plank_light = Panel.new()
	plank_light.anchor_left = 1.0
	plank_light.anchor_right = 1.0
	plank_light.offset_left = -406
	plank_light.offset_right = -389
	plank_light.offset_top = 55.5
	plank_light.offset_bottom = 72.5
	plank_light.size = Vector2(17, 17)
	plank_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plank_light.z_index = 221
	plank_light.add_theme_stylebox_override("panel", PassiveModuleStyles.plank_light(false, host.COLOR_INK))
	pop_card.add_child(plank_light)

	var currency_panel = PanelContainer.new()
	currency_panel.anchor_left = 1.0
	currency_panel.anchor_right = 1.0
	currency_panel.offset_left = -270
	currency_panel.offset_right = -48
	currency_panel.offset_top = 24
	currency_panel.offset_bottom = 108
	currency_panel.custom_minimum_size = Vector2(220, 84)
	currency_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	currency_panel.z_index = 219
	currency_panel.add_theme_stylebox_override("panel", PassiveModuleStyles.currency(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style")))
	pop_card.add_child(currency_panel)
	var currency_row = HBoxContainer.new()
	currency_row.alignment = BoxContainer.ALIGNMENT_CENTER
	currency_row.add_theme_constant_override("separation", 4)
	currency_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	currency_panel.add_child(currency_row)
	var currency_label = host._label("", 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	currency_label.custom_minimum_size = Vector2(135, 67)
	currency_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	currency_row.add_child(currency_label)
	var currency_icon = host.visual_texture_cache._image(MaterialRuntime.LOG_CURRENCY_ICON_TEXTURE, Vector2(56, 56))
	currency_row.add_child(currency_icon)
	return {
		"plank": plank_button,
		"plank_light": plank_light,
		"currency": currency_label,
		"currency_panel": currency_panel,
		"currency_icon": currency_icon,
	}


func _passive_module_stat_upgrade_controls(pop_card: Control, module_id: String, interactive: bool) -> Dictionary:
	var stats = {}
	var stat_panels = {}
	var upgrade_buttons = {}
	var stat_y = 166.0
	var stat_step = 206.0
	var stat_types = ["time", "yield", "capacity"]
	for i in range(3):
		var stat_type = str(stat_types[i])
		var stat_panel = Panel.new()
		stat_panel.position = Vector2(74, stat_y + float(i) * stat_step)
		stat_panel.custom_minimum_size = Vector2(215, 89)
		stat_panel.size = stat_panel.custom_minimum_size
		stat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stat_panel.z_index = 200
		stat_panel.add_theme_stylebox_override("panel", PassiveModuleStyles.stat(host.COLOR_INK, Callable(host, "_surface_style")))
		pop_card.add_child(stat_panel)
		var stat_name = host._label("Max" if stat_type == "capacity" else stat_type.capitalize(), 56, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
		stat_name.position = Vector2(14, 10)
		stat_name.size = Vector2(69, 69)
		stat_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stat_panel.add_child(stat_name)
		var stat_value = host._label("", 52, host.COLOR_GREEN, HORIZONTAL_ALIGNMENT_CENTER)
		stat_value.position = Vector2(81, 9)
		stat_value.size = Vector2(122, 71)
		stat_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stat_value.add_theme_color_override("font_outline_color", host.COLOR_INK)
		stat_value.add_theme_constant_override("outline_size", 12)
		stat_panel.add_child(stat_value)
		stats[stat_type] = stat_value
		stat_panels[stat_type] = stat_panel

		var upgrade = Button.new()
		upgrade.text = ""
		upgrade.custom_minimum_size = Vector2(175, 95)
		upgrade.size = upgrade.custom_minimum_size
		upgrade.position = Vector2(512, stat_y + float(i) * stat_step - 6.0)
		upgrade.focus_mode = Control.FOCUS_NONE
		upgrade.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
		upgrade.z_index = 220
		upgrade.add_theme_stylebox_override("normal", PassiveModuleStyles.upgrade_button())
		upgrade.add_theme_stylebox_override("hover", PassiveModuleStyles.upgrade_button())
		upgrade.add_theme_stylebox_override("pressed", PassiveModuleStyles.upgrade_button())
		upgrade.add_theme_stylebox_override("disabled", PassiveModuleStyles.upgrade_button())
		upgrade.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		host.button_press_runtime.attach_button_depress_animation(upgrade, 0.94)
		var upgrade_visual = HBoxContainer.new()
		upgrade_visual.alignment = BoxContainer.ALIGNMENT_BEGIN
		upgrade_visual.add_theme_constant_override("separation", 4)
		upgrade_visual.set_anchors_preset(Control.PRESET_FULL_RECT)
		upgrade_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		upgrade.add_child(upgrade_visual)
		var upgrade_arrow = _passive_upgrade_arrow_icon(Vector2(93, 93))
		upgrade_visual.add_child(upgrade_arrow)
		var cost_label = host._label("", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		cost_label.add_theme_color_override("font_outline_color", Color.BLACK)
		cost_label.add_theme_constant_override("outline_size", 10)
		cost_label.custom_minimum_size = Vector2(35, 84)
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		upgrade_visual.add_child(cost_label)
		var cost_icon = host.visual_texture_cache._image(MaterialRuntime.LOG_CURRENCY_ICON_TEXTURE, Vector2(47, 47))
		cost_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		upgrade_visual.add_child(cost_icon)
		upgrade.set_meta("cost_label", cost_label)
		if interactive:
			upgrade.gui_input.connect(_on_passive_module_button_input.bind("upgrade", module_id, stat_type, null, upgrade))
			upgrade.pressed.connect(_on_passive_upgrade_pressed.bind(module_id, stat_type))
		pop_card.add_child(upgrade)
		upgrade_buttons[stat_type] = upgrade
	return {"stats": stats, "stat_panels": stat_panels, "upgrade_buttons": upgrade_buttons}


func _passive_module_loot_and_chrome(pop_card: Control, skill_id: String, content_width: float, passive_bar_height: float, passive_face_bottom_trim: float) -> Dictionary:
	var loot = Control.new()
	loot.position = Vector2(content_width - host.ACTION_CARD_POP_GUTTER * 2.0 - 720, 288)
	loot.custom_minimum_size = Vector2(330, 215)
	loot.size = loot.custom_minimum_size
	loot.clip_contents = false
	loot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loot.z_index = 223
	pop_card.add_child(loot)

	var progress = PassiveModuleStyles.SerpentineProgressBar.new()
	progress.fill_color = ThemeStyles.progress_fill_color(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
	progress.unlocked_empty_color = ThemeStyles.progress_empty_color(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE), host.COLOR_INK)
	progress.anchor_left = 0.0
	progress.anchor_right = 1.0
	progress.anchor_top = 1.0
	progress.anchor_bottom = 1.0
	progress.offset_left = host.ACTION_PROGRESS_RAIL_INSET
	progress.offset_right = -host.ACTION_PROGRESS_RAIL_INSET
	progress.offset_top = -passive_bar_height
	progress.offset_bottom = -host.ACTION_PROGRESS_RAIL_INSET
	progress.z_index = host.PASSIVE_PROGRESS_BAR_Z_INDEX
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(progress)

	var inner_shadow = _ActivityCardInnerShadow.new()
	inner_shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_shadow.offset_bottom = -passive_face_bottom_trim
	inner_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_shadow.z_index = 153
	pop_card.add_child(inner_shadow)

	var border = _CardBorder.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.offset_bottom = -passive_face_bottom_trim
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
	pop_card.add_child(border)
	return {"loot": loot, "progress": progress, "border": border}


func _build_passive_module_card(skill_id: String, action: Dictionary, content_width: float, interactive: bool, defer_loot_render := false) -> Dictionary:
	var module_id = str(action.get("id", PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID))
	if host._passive_modules_runtime().is_firepit_module(module_id):
		return _build_firepit_module_card(skill_id, action, content_width, interactive)
	var passive_bar_height = host.ACTION_PROGRESS_RAIL_HEIGHT * 1.72
	var passive_face_bottom_trim = passive_bar_height * 0.50
	var shell = _passive_module_shell(skill_id, action, content_width, interactive, passive_face_bottom_trim)
	var card_root = shell.get("root") as Control
	var pop_card = shell.get("pop") as Control
	var bg = shell.get("bg") as RoundedTextureRect
	var shade = shell.get("shade") as Panel
	var collect_button = _passive_collect_button(pop_card, module_id, interactive)
	var title = _passive_module_title(card_root, pop_card, skill_id, action, "Legacy Softwood Collector", 600.0)
	var info_controls = _passive_info_controls(
		pop_card,
		module_id,
		WOODCUTTING_LOG_MODULE_INFO,
		Vector2(260, 69),
		Vector2(490, 130),
		Vector2(460, 110),
		Vector2(350, 29),
		interactive
	)
	var resource_controls = _passive_module_resource_controls(pop_card, module_id, interactive)
	var stat_controls = _passive_module_stat_upgrade_controls(pop_card, module_id, interactive)
	var chrome = _passive_module_loot_and_chrome(pop_card, skill_id, content_width, passive_bar_height, passive_face_bottom_trim)
	var lock_overlay = host._skill_detail_surface()._activity_lock_overlay(pop_card, int(action.get("unlock", PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_UNLOCK_LEVEL)), skill_id, host._skill_detail_surface()._lock_requirements_for_overlay(skill_id, action))
	host._skill_detail_surface()._connect_activity_lock_handler(lock_overlay, skill_id, module_id)
	var card = {
		"passive": true,
		"root": card_root,
		"skill_id": skill_id,
		"pop": pop_card,
		"button": collect_button,
		"bg": bg,
		"shade": shade,
		"title": title,
		"info_button": info_controls.get("button"),
		"info_popover": info_controls.get("popover"),
		"currency": resource_controls.get("currency"),
		"currency_panel": resource_controls.get("currency_panel"),
		"currency_icon": resource_controls.get("currency_icon"),
		"plank": resource_controls.get("plank"),
		"plank_light": resource_controls.get("plank_light"),
		"stats": stat_controls.get("stats"),
		"stat_panels": stat_controls.get("stat_panels"),
		"upgrade_buttons": stat_controls.get("upgrade_buttons"),
		"loot": chrome.get("loot"),
		"progress": chrome.get("progress"),
		"border": chrome.get("border"),
		"lock_overlay": lock_overlay,
		"action": action
	}
	if interactive:
		card["module_action_zones"] = host._skill_detail_surface()._add_module_action_zones(pop_card, ModuleUiRuntime.action_for_record(skill_id, action, host.FISHING_ACTION_ID_ALIASES))
	if defer_loot_render:
		card["passive_loot_render_deferred"] = true
	_update_passive_card_static_state(card, skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(skill_id, action))
	return {"root": card_root, "card": card}


func _firepit_entry_shell(content_width: float, firepit_card_height: float, dependency_height: float, interactive: bool) -> Dictionary:
	var root = Control.new()
	root.name = "FirepitEntryRoot"
	root.custom_minimum_size = Vector2(content_width, dependency_height + firepit_card_height)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.clip_contents = not interactive
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE if not interactive else Control.MOUSE_FILTER_PASS

	var scrapwood_module = host._material_collection_surface()._mat_collection_module("scrapwood")
	scrapwood_module.position = Vector2((content_width - MaterialCollectionSurface.MAT_COLLECTION_MODULE_SIZE.x) * 0.5, 0.0)
	scrapwood_module.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrapwood_module.z_index = 16
	root.add_child(scrapwood_module)
	var scrapwood_icon = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(int(scrapwood_module.get_meta("icon_id", 0)))) as Control
	var scrapwood_label = host._app_lifecycle_runtime().valid_label_ref(instance_from_id(int(scrapwood_module.get_meta("amount_label_id", 0))))
	var scrapwood_connector = host._material_collection_surface()._mat_collection_connector(host.material_runtime.color("scrapwood").lerp(Color("#ffe27a"), 0.38))
	scrapwood_connector.position = Vector2(content_width * 0.5 - 12.0, MaterialCollectionSurface.MAT_COLLECTION_MODULE_SIZE.y - 8.0)
	scrapwood_connector.custom_minimum_size = Vector2(24.0, WOODCUTTING_FIREPIT_DEPENDENCY_GAP + 18.0)
	scrapwood_connector.size = scrapwood_connector.custom_minimum_size
	scrapwood_connector.z_index = 8
	root.add_child(scrapwood_connector)

	var card_root = Control.new()
	card_root.name = "FirepitCardRoot"
	card_root.custom_minimum_size = Vector2(content_width, firepit_card_height)
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = true
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE if not interactive else Control.MOUSE_FILTER_PASS
	card_root.position = Vector2(0.0, dependency_height)
	root.add_child(card_root)

	var pop_card = Control.new()
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = host.ACTION_CARD_POP_GUTTER
	pop_card.offset_right = -host.ACTION_CARD_POP_GUTTER
	pop_card.offset_top = 0.0
	pop_card.offset_bottom = 0.0
	pop_card.clip_contents = true
	pop_card.mouse_filter = Control.MOUSE_FILTER_IGNORE if not interactive else Control.MOUSE_FILTER_PASS
	card_root.add_child(pop_card)

	return {
		"root": root,
		"card_root": card_root,
		"pop": pop_card,
		"scrapwood_module": scrapwood_module,
		"scrapwood_connector": scrapwood_connector,
		"scrapwood_icon": scrapwood_icon,
		"scrapwood_label": scrapwood_label,
	}


func _firepit_background_layers(pop_card: Control, firepit_card_height: float, passive_face_bottom_trim: float) -> Dictionary:
	var bg_underlay = Panel.new()
	bg_underlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_underlay.offset_bottom = -passive_face_bottom_trim
	bg_underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_underlay.z_index = 149
	var underlay_style = host._surface_style(Color("#8d5f3a"), 66, 0, false)
	underlay_style.border_width_left = 0
	underlay_style.border_width_right = 0
	underlay_style.border_width_top = 0
	underlay_style.border_width_bottom = 0
	bg_underlay.add_theme_stylebox_override("panel", underlay_style)
	pop_card.add_child(bg_underlay)

	var bg = RoundedTextureRect.new()
	bg.texture = host.visual_texture_cache._texture_or_visual_fallback(WOODCUTTING_FIREPIT_BACKGROUND_TEXTURE)
	bg.radius = 66.0
	bg.art_height = firepit_card_height
	bg.feather_height = 0.0
	bg.mask_inset = 0.0
	bg.corner_mask_mode = 1
	bg.aspect_mode = 2
	bg.sample_zoom = 1.50
	bg.fallback_color = Color("#8d5f3a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_bottom = -passive_face_bottom_trim
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	pop_card.add_child(bg)

	var wash = Panel.new()
	wash.add_theme_stylebox_override("panel", ActivityCardStyles.cached_shade(0.30))
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.offset_bottom = -passive_face_bottom_trim
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wash.z_index = 152
	pop_card.add_child(wash)
	return {"bg": bg, "underlay": bg_underlay, "wash": wash}


func _firepit_art_bundle(pop_card: Control, content_width: float, passive_face_bottom_trim: float) -> Dictionary:
	var face_width = content_width - host.ACTION_CARD_POP_GUTTER * 2.0
	var firepit_art_size = Vector2(270, 270)
	var firepit_ring_size = Vector2(410, 410)
	var art_root_size = Vector2(480, 450)
	var module_center_x = face_width * 0.5
	var firepit_layout_shift_x = -130.0

	var art_root = Control.new()
	art_root.position = Vector2(module_center_x - art_root_size.x * 0.5 + firepit_layout_shift_x, 40)
	art_root.custom_minimum_size = art_root_size
	art_root.size = art_root.custom_minimum_size
	art_root.clip_contents = false
	art_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_root.z_index = 210
	pop_card.add_child(art_root)

	var fuel_ring = _FirepitFuelRing.new()
	var firepit_art_position = Vector2((art_root_size.x - firepit_art_size.x) * 0.5, 170)
	var firepit_art_center = firepit_art_position + firepit_art_size * 0.5
	fuel_ring.position = firepit_art_center - firepit_ring_size * 0.5
	fuel_ring.size = firepit_ring_size
	fuel_ring.custom_minimum_size = fuel_ring.size
	fuel_ring.fill_color = Color("#ff9c2f")
	fuel_ring.empty_color = Color("#553220")
	fuel_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fuel_ring.z_index = 3
	art_root.add_child(fuel_ring)

	var firepit_art = TextureRect.new()
	firepit_art.texture = host.visual_texture_cache._texture_or_visual_fallback(WOODCUTTING_FIREPIT_TEXTURE)
	firepit_art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	firepit_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	firepit_art.position = firepit_art_position
	firepit_art.size = firepit_art_size
	firepit_art.custom_minimum_size = firepit_art.size
	firepit_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	firepit_art.z_index = 1
	art_root.add_child(firepit_art)

	var active_dim = _FirepitWarmthOverlay.new()
	active_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	active_dim.offset_bottom = -passive_face_bottom_trim
	active_dim.cutout_center = art_root.position + firepit_art.position + firepit_art.size * Vector2(0.5, 0.54)
	active_dim.base_radius = 360.0
	active_dim.feather_radius = 360.0
	active_dim.flicker_radius = 42.0
	active_dim.corner_radius = 66.0
	active_dim.darkness = 0.58
	active_dim.unlit_darkness = 0.46
	active_dim.glow_alpha = 0.18
	active_dim.z_index = 153
	active_dim.set_active(false)
	pop_card.add_child(active_dim)

	var flame_fx = FirepitFlameFx.new()
	flame_fx.position = Vector2((art_root_size.x - 620.0) * 0.5, 58)
	flame_fx.size = Vector2(310, 310)
	flame_fx.custom_minimum_size = flame_fx.size
	flame_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flame_fx.z_index = 4
	art_root.add_child(flame_fx)
	return {"art_root": art_root, "progress": fuel_ring, "active_dim": active_dim, "flame_fx": flame_fx}


func _firepit_status_controls(pop_card: Control) -> Dictionary:
	var status_panel = Control.new()
	status_panel.custom_minimum_size = Vector2(250, 180)
	status_panel.position = Vector2(610.0, 52)
	status_panel.size = status_panel.custom_minimum_size
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.z_index = 242
	pop_card.add_child(status_panel)

	var status_label = host._label("", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	status_label.position = Vector2(0, 0)
	status_label.size = Vector2(245, 41)
	status_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	status_label.add_theme_constant_override("outline_size", 10)
	status_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_child(status_label)
	var buff_label = host._label("", 52, Color("#ffe27a"), HORIZONTAL_ALIGNMENT_RIGHT)
	buff_label.position = Vector2(0, 59)
	buff_label.size = Vector2(245, 85)
	buff_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	buff_label.add_theme_constant_override("outline_size", 7)
	buff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buff_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	buff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_child(buff_label)
	var timer_label = host._label("", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	timer_label.position = Vector2(0, 147)
	timer_label.size = Vector2(245, 35)
	timer_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	timer_label.add_theme_constant_override("outline_size", 7)
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_child(timer_label)
	return {"panel": status_panel, "status": status_label, "buff": buff_label, "timer": timer_label}


func _firepit_toggle_button(pop_card: Control, module_id: String, art_root: Control, interactive: bool) -> Button:
	var toggle_button = Button.new()
	toggle_button.text = ""
	toggle_button.flat = true
	toggle_button.custom_minimum_size = art_root.size
	toggle_button.size = toggle_button.custom_minimum_size
	toggle_button.position = art_root.position
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	toggle_button.z_index = 230
	host._apply_empty_button_style(toggle_button)
	host.button_press_runtime.attach_button_depress_animation(toggle_button, 0.94)
	host.button_press_runtime.attach_default_button_sfx(toggle_button)
	if interactive:
		toggle_button.gui_input.connect(_on_passive_module_button_input.bind("firepit", module_id, "", null, toggle_button))
		toggle_button.button_down.connect(_on_firepit_button_down.bind(module_id, toggle_button))
		toggle_button.button_up.connect(_on_firepit_button_up.bind(module_id))
		toggle_button.pressed.connect(_on_firepit_toggle_pressed.bind(module_id))
	pop_card.add_child(toggle_button)
	return toggle_button


func _on_firepit_toggle_pressed(module_id: String) -> void:
	host._passive_modules_runtime().toggle_firepit_pressed(module_id, host._unix_now())


func _firepit_chrome(pop_card: Control, passive_face_bottom_trim: float) -> Dictionary:
	var inner_shadow = _ActivityCardInnerShadow.new()
	inner_shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_shadow.offset_bottom = -passive_face_bottom_trim
	inner_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_shadow.z_index = 153
	pop_card.add_child(inner_shadow)

	var corner_crop = RoundedCornerCropOverlay.new()
	corner_crop.radius = 66.0
	corner_crop.cover_color = host._theme_paper_color()
	corner_crop.set_anchors_preset(Control.PRESET_FULL_RECT)
	corner_crop.offset_bottom = -passive_face_bottom_trim
	corner_crop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corner_crop.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX - 1
	pop_card.add_child(corner_crop)

	var border = ActivityCardBorder.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.offset_bottom = -passive_face_bottom_trim
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = host.ACTION_CARD_FACE_BORDER_Z_INDEX
	pop_card.add_child(border)
	var shade = _passive_card_shade(pop_card, passive_face_bottom_trim)
	return {"corner_crop": corner_crop, "border": border, "shade": shade}


func _build_firepit_module_card(skill_id: String, action: Dictionary, content_width: float, interactive: bool) -> Dictionary:
	var module_id = str(action.get("id", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID))
	var firepit_card_height = WOODCUTTING_FIREPIT_CARD_HEIGHT
	var passive_face_bottom_trim = 0.0
	var dependency_height = WOODCUTTING_FIREPIT_DEPENDENCY_HEIGHT
	var shell = _firepit_entry_shell(content_width, firepit_card_height, dependency_height, interactive)
	var root = shell.get("root") as Control
	var card_root = shell.get("card_root") as Control
	var pop_card = shell.get("pop") as Control
	var scrapwood_module = shell.get("scrapwood_module") as Control
	var scrapwood_connector = shell.get("scrapwood_connector") as Control
	var scrapwood_icon = shell.get("scrapwood_icon") as Control
	var scrapwood_label = shell.get("scrapwood_label") as Label
	var background_layers = _firepit_background_layers(pop_card, firepit_card_height, passive_face_bottom_trim)
	var bg = background_layers.get("bg") as RoundedTextureRect
	var title = _passive_module_title(card_root, pop_card, skill_id, action, "Firepit", 760.0)
	var info_controls = _passive_info_controls(
		pop_card,
		module_id,
		WOODCUTTING_FIREPIT_INFO,
		Vector2(37, 119),
		Vector2(450, 180),
		Vector2(420, 160),
		Vector2(180, 29),
		interactive
	)
	var art_bundle = _firepit_art_bundle(pop_card, content_width, passive_face_bottom_trim)
	var art_root = art_bundle.get("art_root") as Control
	var active_dim = art_bundle.get("active_dim") as Control
	var flame_fx = art_bundle.get("flame_fx") as Control
	var fuel_ring = art_bundle.get("progress") as _FirepitFuelRing
	var status_controls = _firepit_status_controls(pop_card)
	var status_panel = status_controls.get("panel") as Control
	var status_label = status_controls.get("status") as Label
	var buff_label = status_controls.get("buff") as Label
	var timer_label = status_controls.get("timer") as Label
	var toggle_button = _firepit_toggle_button(pop_card, module_id, art_root, interactive)
	var chrome = _firepit_chrome(pop_card, passive_face_bottom_trim)
	var corner_crop = chrome.get("corner_crop") as RoundedCornerCropOverlay
	var border = chrome.get("border") as ActivityCardBorder
	var shade = chrome.get("shade") as Panel
	var lock_overlay = host._skill_detail_surface()._activity_lock_overlay(pop_card, int(action.get("unlock", PassiveModulesRuntime.WOODCUTTING_FIREPIT_UNLOCK_LEVEL)), skill_id, host._skill_detail_surface()._lock_requirements_for_overlay(skill_id, action))
	host._skill_detail_surface()._connect_activity_lock_handler(lock_overlay, skill_id, module_id)

	var card = {
		"passive": true,
		"firepit": true,
		"root": card_root,
		"firepit_entry_root": root,
		"skill_id": skill_id,
		"pop": pop_card,
		"bg": bg,
		"active_dim": active_dim,
		"corner_crop": corner_crop,
		"shade": shade,
		"title": title,
		"info_button": info_controls.get("button"),
		"info_label": info_controls.get("label"),
		"info_popover": info_controls.get("popover"),
		"scrapwood_module": scrapwood_module,
		"scrapwood_connector": scrapwood_connector,
		"scrapwood_icon": scrapwood_icon,
		"scrapwood_label": scrapwood_label,
		"art_root": art_root,
		"firepit_glow": active_dim,
		"status_panel": status_panel,
		"flame_fx": flame_fx,
		"status": status_label,
		"timer": timer_label,
		"buff": buff_label,
		"toggle": toggle_button,
		"progress": fuel_ring,
		"border": border,
		"lock_overlay": lock_overlay,
		"action": action
	}
	if interactive:
		card["module_action_zones"] = host._skill_detail_surface()._add_module_action_zones(pop_card, ModuleUiRuntime.action_for_record(skill_id, action, host.FISHING_ACTION_ID_ALIASES))
	_update_firepit_card_static_state(card, skill_id, action, host._activity_unlock_runtime()._is_action_unlocked(skill_id, action))
	return {"root": root, "card": card}


func _hold_firepit_next_scrapwood_ring_empty() -> void:
	var key: String = host._action_key("woodcutting", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID)
	if not host.action_cards.has(key):
		return
	var card := host.action_cards[key] as Dictionary
	var progress := card.get("progress") as _FirepitFuelRing
	if progress == null or not is_instance_valid(progress):
		return
	progress.set_inner_value(0.0)
	progress.set_meta("firepit_consume_hold_until_msec", Time.get_ticks_msec() + 900)


func _float_firepit_xp_reward_from_fire(index := 0) -> void:
	var key: String = host._action_key("woodcutting", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID)
	if not host.action_cards.has(key):
		return
	var card := host.action_cards[key] as Dictionary
	var anchor := card.get("flame_fx") as Control
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		anchor = card.get("art_root") as Control
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		anchor = card.get("status_panel") as Control
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		return
	var per_scrapwood_xp: int = PassiveModulesRuntime.FIREPIT_WOODCUTTING_XP_PER_SCRAPWOOD
	var lane_x := float((index % 3) - 1) * 42.0
	host._reward_feedback_surface()._float_reward(
		host,
		anchor,
		"+%s XP" % per_scrapwood_xp,
		66,
		ThemeStyles.skill_theme_color("woodcutting", host.COLOR_BLUE).lerp(Color("#ffb347"), 0.35),
		Vector2(lane_x, -60.0 - float(index % 2) * 16.0),
		Vector2(lane_x * 0.35, -176.0 - float(index % 2) * 18.0),
		0.0,
		false,
		-1.0,
		RewardFeedbackSurface.SKILL_REWARD_FLOAT_GROUP
	)


func _animate_firepit_scrapwood_to_fire(scrapwood_burned: int, pronounced := false, arrival_callback := Callable()) -> void:
	if scrapwood_burned <= 0:
		return
	var key: String = host._action_key("woodcutting", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID)
	if not host.action_cards.has(key):
		return
	var card := host.action_cards[key] as Dictionary
	var source := card.get("scrapwood_icon") as Control
	var fire := card.get("flame_fx") as Control
	if fire == null or not is_instance_valid(fire) or not fire.is_visible_in_tree():
		fire = card.get("art_root") as Control
	if source == null or fire == null or not is_instance_valid(source) or not is_instance_valid(fire):
		return
	if not source.is_inside_tree() or not fire.is_inside_tree():
		return
	var visible_count := 1 if pronounced else mini(3, maxi(1, scrapwood_burned))
	var start_center: Vector2 = _control_local_point_to_global(source, source.size * 0.5)
	var fire_center: Vector2 = _control_local_point_to_global(fire, fire.size * Vector2(0.5, 0.62))
	for index in range(visible_count):
		var flyer_size := Vector2(115, 115) if pronounced else Vector2(61, 61)
		var flyer: TextureRect = host.visual_texture_cache._image(host.material_runtime.icon_path("scrapwood"), flyer_size)
		flyer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flyer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flyer.z_index = RewardFeedbackSurface.REWARD_FLOAT_Z
		flyer.z_as_relative = false
		host.add_child(flyer)
		var lane_offset := Vector2(float(index - visible_count / 2) * 28.0, float(index % 2) * -12.0)
		var start: Vector2 = _control_global_point_to_local(host, start_center + lane_offset) - flyer.size * 0.5
		var finish: Vector2 = _control_global_point_to_local(host, fire_center + Vector2(float(index % 3 - 1) * 36.0, float(index % 2) * 18.0)) - flyer.size * 0.5
		var arc_mid := (start + finish) * 0.5 + Vector2(0, (-120.0 if pronounced else -230.0) - float(index) * 20.0)
		flyer.position = start
		flyer.scale = Vector2(0.72, 0.72)
		flyer.modulate = Color(1, 1, 1, 0.0)
		var tween: Tween = host.create_tween()
		tween.set_parallel(true)
		var delay := float(index) * 0.12
		var flight_seconds := 0.96 if pronounced else 0.74
		tween.tween_property(flyer, "modulate:a", 1.0, 0.12).set_delay(delay)
		tween.tween_property(flyer, "scale", Vector2(1.38, 1.38) if pronounced else Vector2(1.10, 1.10), 0.24).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_method(_move_firepit_scrapwood_flyer.bind(flyer.get_instance_id(), start, arc_mid, finish), 0.0, 1.0, flight_seconds).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(flyer, "rotation_degrees", randf_range(-56.0, 56.0), flight_seconds).set_delay(delay)
		if index == 0 and arrival_callback.is_valid():
			tween.tween_callback(arrival_callback).set_delay(delay + flight_seconds * 0.94)
		else:
			tween.tween_callback(_float_firepit_xp_reward_from_fire.bind(index)).set_delay(delay + flight_seconds * 0.94)
		tween.tween_property(flyer, "scale", Vector2(0.72, 0.72), 0.14).set_delay(delay + flight_seconds * 0.86)
		tween.tween_property(flyer, "modulate:a", 0.0, 0.16).set_delay(delay + flight_seconds * 0.88)
		tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(flyer.get_instance_id()))


func _move_firepit_scrapwood_flyer(progress: float, flyer_id: int, start: Vector2, arc_mid: Vector2, finish: Vector2) -> void:
	var flyer: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(flyer_id))
	if flyer == null:
		return
	var a := start.lerp(arc_mid, progress)
	var b := arc_mid.lerp(finish, progress)
	flyer.position = a.lerp(b, progress)


func _launch_firepit_ignition_flyer() -> void:
	for _frame in range(10):
		if not bool(host._passive_modules_runtime().firepit_state(host._unix_now()).get("igniting", false)):
			return
		host._update_ui(0.0, false)
		await host.get_tree().process_frame
	var key: String = host._action_key("woodcutting", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID)
	if not host.action_cards.has(key):
		host._passive_modules_runtime().finish_firepit_ignition(host._unix_now())
		return
	_animate_firepit_scrapwood_to_fire(1, true, func(): host._passive_modules_runtime().finish_firepit_ignition(host._unix_now()))


func _float_firepit_need_scrapwood() -> void:
	var key: String = host._action_key("woodcutting", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID)
	var anchor: Control = null
	if host.action_cards.has(key):
		var card := host.action_cards[key] as Dictionary
		anchor = card.get("art_root") as Control
		if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
			anchor = card.get("toggle") as Control
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		return
	host._reward_feedback_surface()._float_reward(
		host,
		anchor,
		"Need Scrapwood",
		58,
		Color("#ffd95a"),
		Vector2(0, -27),
		Vector2(0, -75),
		0.0,
		false,
		-1.0,
		RewardFeedbackSurface.SKILL_REWARD_FLOAT_GROUP
	)


func _render_passive_loot(card: Dictionary, module_id: String, unlocked: bool) -> void:
	var loot := card.get("loot") as Control
	if loot == null or not is_instance_valid(loot):
		return
	var state: Dictionary = host._passive_modules_runtime().passive_module_state(module_id, host._unix_now())
	var stored := maxi(0, int(state.get("stored", 0))) if unlocked else 0
	var previous_stored := int(card.get("last_rendered_stored", -1))
	var previous_tier := str(card.get("last_rendered_pile_tier", ""))
	if int(card.get("last_rendered_stored", -1)) == stored and bool(card.get("last_rendered_unlocked", false)) == unlocked:
		return
	card["last_rendered_stored"] = stored
	card["last_rendered_unlocked"] = unlocked
	loot.remove_meta("passive_log_collect_hotspot_id")
	host._clear(loot)
	if stored <= 0:
		card["last_rendered_pile_tier"] = ""
		loot.remove_meta("passive_log_flyer_size")
		loot.remove_meta("passive_log_flight_points_local")
		var empty: Label = host._label("empty", 58, Color(0.29, 0.20, 0.12, 0.50), HORIZONTAL_ALIGNMENT_CENTER)
		var empty_rect := _passive_log_pile_empty_label_rect()
		empty.position = empty_rect.position
		empty.size = empty_rect.size
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		loot.add_child(empty)
		return
	var pile_tier := _passive_log_pile_tier(stored)
	card["last_rendered_pile_tier"] = pile_tier
	var pile_config := _passive_log_pile_config(pile_tier, stored)
	var visible_logs := int(pile_config["visible"])
	var icon_size := pile_config["icon_size"] as Vector2
	var pile_slots := pile_config["slots"] as Array
	var pile_rotations := pile_config["rotations"] as Array
	loot.set_meta("passive_log_flyer_size", icon_size)
	loot.set_meta("passive_log_flight_points_local", _passive_log_pile_flight_points(pile_slots, visible_logs, icon_size))
	var shadow_rect := _passive_log_pile_shadow_rect(pile_slots, visible_logs, icon_size)
	var log_layer := PassiveLogPileSprite.new()
	log_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_layer.pivot_offset = loot.size * 0.5
	log_layer.z_index = 1
	log_layer.configure(host.visual_texture_cache._texture(MaterialRuntime.LOG_CURRENCY_ICON_TEXTURE), icon_size, pile_slots, pile_rotations, visible_logs, shadow_rect)
	loot.add_child(log_layer)
	var click_prompt: Label = host._label(PASSIVE_LOG_PILE_CLICK_PROMPT, PASSIVE_LOG_PILE_CLICK_PROMPT_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	click_prompt.position = (pile_config["count_position"] as Vector2) + PASSIVE_LOG_PILE_CLICK_PROMPT_OFFSET
	click_prompt.size = PASSIVE_LOG_PILE_CLICK_PROMPT_SIZE
	click_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	click_prompt.z_index = 80
	click_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	click_prompt.add_theme_constant_override("outline_size", 11)
	loot.add_child(click_prompt)
	_add_passive_log_collect_hotspot(loot, module_id, _passive_log_pile_visible_bounds(pile_slots, visible_logs, icon_size), click_prompt)
	var tier_changed := previous_tier != "" and previous_tier != pile_tier
	var count_increased := previous_stored >= 0 and stored > previous_stored
	_animate_passive_log_pile(log_layer, null, tier_changed, count_increased)


func _add_passive_log_collect_hotspot(loot: Control, module_id: String, visible_bounds: Rect2, click_prompt: Label) -> void:
	var hotspot_rect := visible_bounds.grow(30.0)
	if click_prompt != null and is_instance_valid(click_prompt):
		hotspot_rect = hotspot_rect.merge(Rect2(click_prompt.position, click_prompt.size).grow(14.0))
	hotspot_rect = hotspot_rect.intersection(Rect2(Vector2.ZERO, loot.size))
	if hotspot_rect.size.x <= 1.0 or hotspot_rect.size.y <= 1.0:
		return
	var collect_hotspot := Button.new()
	collect_hotspot.text = ""
	collect_hotspot.name = "PassiveLogCollectHotspot"
	collect_hotspot.focus_mode = Control.FOCUS_NONE
	collect_hotspot.flat = true
	collect_hotspot.position = hotspot_rect.position
	collect_hotspot.size = hotspot_rect.size
	collect_hotspot.custom_minimum_size = hotspot_rect.size
	collect_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	collect_hotspot.z_index = 120
	collect_hotspot.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	collect_hotspot.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	collect_hotspot.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	collect_hotspot.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	collect_hotspot.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	collect_hotspot.pressed.connect(_on_passive_collect_pressed.bind(module_id))
	collect_hotspot.gui_input.connect(_on_passive_module_button_input.bind("collect", module_id, "", null, collect_hotspot))
	loot.add_child(collect_hotspot)
	loot.set_meta("passive_log_collect_hotspot_id", collect_hotspot.get_instance_id())


func _passive_log_pile_shadow_rect(pile_slots: Array, visible_logs: int, icon_size: Vector2) -> Rect2:
	var visible_bounds := _passive_log_pile_visible_bounds(pile_slots, visible_logs, icon_size)
	var shadow_height := clampf(visible_bounds.size.y * 0.17, 34.0, 48.0)
	var shadow_width := clampf(visible_bounds.size.x * 0.74, 240.0, 320.0)
	var shadow_center_x := visible_bounds.position.x + visible_bounds.size.x * 0.52
	var shadow_bottom := visible_bounds.end.y + 12.0
	return Rect2(
		Vector2(shadow_center_x - shadow_width * 0.5, shadow_bottom - shadow_height),
		Vector2(shadow_width, shadow_height)
	)


func _passive_log_pile_empty_label_rect() -> Rect2:
	var pile_config := _passive_log_pile_config("tiny", PASSIVE_LOG_PILE_MEDIUM_THRESHOLD - 1)
	var visible_bounds := _passive_log_pile_visible_bounds(
		pile_config["slots"] as Array,
		int(pile_config["visible"]),
		pile_config["icon_size"] as Vector2
	)
	var label_size := Vector2(150, 48)
	return Rect2(visible_bounds.position + visible_bounds.size * 0.5 - label_size * 0.5, label_size)


func _passive_log_pile_flight_points(pile_slots: Array, visible_logs: int, icon_size: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in range(mini(visible_logs, pile_slots.size())):
		var slot := pile_slots[i] as Vector2
		points.append(slot + icon_size * 0.5)
	return points


func _passive_log_pile_visible_bounds(pile_slots: Array, visible_logs: int, icon_size: Vector2) -> Rect2:
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	var log_min := icon_size * PASSIVE_LOG_TEXTURE_VISIBLE_MIN
	var log_max := icon_size * PASSIVE_LOG_TEXTURE_VISIBLE_MAX
	for i in range(mini(visible_logs, pile_slots.size())):
		var slot := pile_slots[i] as Vector2
		min_pos.x = minf(min_pos.x, slot.x + log_min.x)
		min_pos.y = minf(min_pos.y, slot.y + log_min.y)
		max_pos.x = maxf(max_pos.x, slot.x + log_max.x)
		max_pos.y = maxf(max_pos.y, slot.y + log_max.y)
	if max_pos.x < min_pos.x or max_pos.y < min_pos.y:
		return Rect2(Vector2(85, 195), Vector2(160, 60))
	return Rect2(min_pos, max_pos - min_pos)


func _passive_log_pile_tier(stored: int) -> String:
	if stored >= PASSIVE_LOG_PILE_LARGE_THRESHOLD:
		return "large"
	if stored >= PASSIVE_LOG_PILE_MEDIUM_THRESHOLD:
		return "medium"
	return "tiny"


func _passive_log_pile_config(tier: String, stored: int) -> Dictionary:
	if tier == "large":
		return {
			"visible": 10,
			"icon_size": Vector2(143, 143),
			"count_position": Vector2(10, 36),
			"slots": [
				Vector2(-56, 119), Vector2(-16, 123), Vector2(24, 119), Vector2(64, 123),
				Vector2(-36, 92), Vector2(4, 87), Vector2(44, 92),
				Vector2(-16, 65), Vector2(24, 60),
				Vector2(4, 33)
			],
			"rotations": [-8.0, 5.0, -3.0, 0.0, -6.0, 4.0, 2.0, -7.0, 5.0, -3.0]
		}
	if tier == "medium":
		return {
			"visible": 7,
			"icon_size": Vector2(151, 151),
			"count_position": Vector2(9, 53),
			"slots": [
				Vector2(-51, 118), Vector2(-8, 122), Vector2(35, 118),
				Vector2(-30, 90), Vector2(13, 85), Vector2(56, 90),
				Vector2(-9, 58)
			],
			"rotations": [-8.0, 4.0, 0.0, -6.0, 5.0, 2.0, -4.0]
		}
	return {
		"visible": mini(5, maxi(1, int(ceil(float(stored) / 2.0)))),
		"icon_size": Vector2(157, 157),
		"count_position": Vector2(9, 78),
		"slots": [
			Vector2(-46, 118), Vector2(-1, 122), Vector2(44, 118),
			Vector2(-24, 90), Vector2(21, 87)
		],
		"rotations": [-8.0, 5.0, 0.0, -6.0, 4.0]
	}


func _animate_passive_log_pile(log_layer: Control, shadow: Control, tier_changed: bool, count_increased: bool) -> void:
	if log_layer == null or not is_instance_valid(log_layer):
		return
	if not tier_changed and not count_increased:
		return
	var pop_scale := Vector2(0.84, 0.84) if tier_changed else Vector2(0.94, 0.94)
	var peak_scale := Vector2(1.10, 1.10) if tier_changed else Vector2(1.04, 1.04)
	log_layer.scale = pop_scale
	log_layer.modulate = Color(1, 1, 1, 0.86)
	var tween: Tween = host.create_tween()
	tween.tween_property(log_layer, "scale", peak_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(log_layer, "modulate:a", 1.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(log_layer, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shadow != null and is_instance_valid(shadow):
		shadow.scale = Vector2(0.92, 0.92) if tier_changed else Vector2(0.97, 0.97)
		var shadow_tween: Tween = host.create_tween()
		shadow_tween.tween_property(shadow, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _passive_log_sprite(sprite_size: Vector2, shadow_offset: Vector2, shadow_alpha: float) -> Control:
	var sprite := PassiveIconSprite.new()
	sprite.configure(host.visual_texture_cache._texture(MaterialRuntime.LOG_CURRENCY_ICON_TEXTURE), sprite_size)
	sprite.shadow_offset = shadow_offset
	sprite.shadow_alpha = shadow_alpha
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite


func _passive_upgrade_arrow_icon(icon_size: Vector2) -> Control:
	var sprite := PassiveIconSprite.new()
	sprite.configure(host.visual_texture_cache._texture(MaterialRuntime.UPGRADE_ARROW_ICON_TEXTURE), icon_size)
	sprite.stroke_color = host.COLOR_INK
	sprite.stroke_width = 8.0
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return sprite


func _float_log_currency_feedback(module_id: String, amount: int) -> void:
	var key: String = host._action_key("woodcutting", module_id)
	if amount <= 0 or not host.action_cards.has(key):
		return
	var card := host.action_cards[key] as Dictionary
	var panel := card.get("currency_panel") as Control
	var currency_icon := card.get("currency_icon") as Control
	var loot := card.get("loot") as Control
	if loot != null and panel != null and is_instance_valid(loot) and is_instance_valid(panel):
		_arc_passive_collection_logs(loot, panel, currency_icon, amount, module_id)
	if panel != null and is_instance_valid(panel) and panel.is_inside_tree():
		host._reward_feedback_surface()._flash_bonus_control(panel)
		host._reward_feedback_surface()._float_reward(host, panel, "+%s Softwood" % amount, 58, RewardFeedbackSurface.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -22), Vector2(0, -73), 0.0)


func _play_build_log_spend_feedback(action_key: String) -> void:
	if not host.action_cards.has(action_key):
		return
	var card := host.action_cards[action_key] as Dictionary
	var anchor := card.get("progress") as Control
	if anchor != null and is_instance_valid(anchor) and anchor.is_inside_tree():
		_float_build_log_spend(anchor)


func _float_log_spend(anchor: Control, cost: int) -> void:
	if cost <= 0:
		return
	var text := "-%s" % cost
	var reward_size := Vector2(150, 58)
	var holder := Control.new()
	holder.z_index = RewardFeedbackSurface.REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	host.add_child(holder)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 2)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(row)
	var label: Label = host._label(text, 58, Color("#fff2a8"), HORIZONTAL_ALIGNMENT_RIGHT)
	label.custom_minimum_size = Vector2(152, reward_size.y)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 7)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	var icon: TextureRect = host.visual_texture_cache._image(MaterialRuntime.LOG_CURRENCY_ICON_TEXTURE, Vector2(37, 37))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var local_pos: Vector2 = anchor.global_position - host.global_position
	holder.position = host._reward_feedback_surface()._clamp_reward_holder_position(
		host,
		local_pos + Vector2(anchor.size.x * 0.5 - reward_size.x * 0.5, -76),
		reward_size
	)
	holder.modulate = Color(1, 1, 1, 0)
	holder.scale = Vector2(0.82, 0.82)
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + Vector2(0, -71), 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.08)
	tween.tween_property(holder, "modulate:a", 0.0, 0.70).set_delay(0.45)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(holder.get_instance_id()))


func _float_build_log_spend(anchor: Control) -> void:
	var reward_size := Vector2(110, 52)
	var holder := Control.new()
	holder.z_index = RewardFeedbackSurface.REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = reward_size
	host.add_child(holder)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 1)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(row)
	var label: Label = host._label("-1", 52, Color("#fff2a8"), HORIZONTAL_ALIGNMENT_RIGHT)
	label.custom_minimum_size = Vector2(92, reward_size.y)
	label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	var icon: TextureRect = host.visual_texture_cache._image(MaterialRuntime.LOG_CURRENCY_ICON_TEXTURE, Vector2(41, 41))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var local_pos: Vector2 = anchor.global_position - host.global_position
	holder.position = host._reward_feedback_surface()._clamp_reward_holder_position(
		host,
		local_pos + Vector2(anchor.size.x - reward_size.x + 8.0, anchor.size.y * 0.42 - reward_size.y * 0.5),
		reward_size
	)
	holder.modulate = Color(1, 1, 1, 0)
	holder.scale = Vector2(0.76, 0.76)
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + Vector2(0, -62), 1.05).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.08)
	tween.tween_property(holder, "modulate:a", 0.0, 0.62).set_delay(0.48)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(holder.get_instance_id()))


func _float_passive_production_feedback(module_id: String, amount: int) -> void:
	var key: String = host._action_key("woodcutting", module_id)
	if amount <= 0 or not host.action_cards.has(key):
		return
	var card := host.action_cards[key] as Dictionary
	var loot := card.get("loot") as Control
	if loot == null or not is_instance_valid(loot) or not loot.is_visible_in_tree():
		return
	var stat_panels := card.get("stat_panels", {}) as Dictionary
	var yield_panel := stat_panels.get("yield") as Control
	if yield_panel == null or not is_instance_valid(yield_panel) or not yield_panel.is_visible_in_tree():
		host._reward_feedback_surface()._flash_bonus_control(loot)
		host._reward_feedback_surface()._float_reward(host, loot, "+%s" % amount, 50, RewardFeedbackSurface.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -9), Vector2(0, -52), 0.0)
		return
	host._reward_feedback_surface()._flash_bonus_control(yield_panel)
	_pop_passive_control(yield_panel)
	host._reward_feedback_surface()._float_reward(host, yield_panel, "+%s" % amount, 46, RewardFeedbackSurface.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -13), Vector2(0, -49), 0.0)
	_arc_passive_yield_logs(yield_panel, loot, amount, module_id)


func _arc_passive_yield_logs(source: Control, target: Control, amount: int, module_id: String) -> void:
	if source == null or target == null or not source.is_inside_tree() or not target.is_inside_tree():
		return
	var visible_count := mini(10, maxi(2, amount))
	var effect_parent := _passive_local_effect_parent(source, target)
	var source_rect := source.get_global_rect()
	var base_start: Vector2 = _control_global_point_to_local(effect_parent, source_rect.position + Vector2(source_rect.size.x * 0.82, source_rect.size.y * 0.52))
	var destination_points := _passive_storage_destination_points(target, effect_parent)
	var flyer_size := _passive_log_flyer_size(module_id, target)
	for i in range(visible_count):
		var flyer := _passive_log_sprite(flyer_size, _passive_log_flyer_shadow_offset(flyer_size), 0.28)
		flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flyer.z_index = 225
		effect_parent.add_child(flyer)
		var start: Vector2 = base_start + Vector2(float(i % 3) * 8.0, float(i % 2) * 5.0)
		var end: Vector2 = destination_points[i % destination_points.size()]
		var apex: Vector2 = (start + end) * 0.5 + Vector2(0, -58.0 - float(i % 3) * 10.0)
		flyer.position = start - flyer_size * 0.5
		flyer.rotation_degrees = float(((i * 23) % 37) - 18)
		flyer.pivot_offset = flyer_size * 0.5
		var tween: Tween = host.create_tween()
		tween.tween_interval(float(i) * 0.035)
		tween.tween_property(flyer, "position", apex - flyer_size * 0.5, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(flyer, "rotation_degrees", flyer.rotation_degrees + 24.0, 0.18)
		tween.tween_property(flyer, "position", end - flyer_size * 0.5, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(flyer, "rotation_degrees", flyer.rotation_degrees + 54.0, 0.24)
		tween.tween_callback(_on_passive_yield_log_stored_bound.bind(target.get_instance_id(), module_id, i))
		tween.tween_property(flyer, "modulate:a", 0.0, 0.06)
		tween.tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(flyer.get_instance_id()))


func _arc_passive_collection_logs(source: Control, target: Control, currency_icon: Control, amount: int, module_id: String) -> void:
	if source == null or target == null or not source.is_inside_tree() or not target.is_inside_tree():
		return
	var visible_count := mini(14, maxi(4, amount))
	var effect_parent := _passive_local_effect_parent(source, target)
	var source_rect := source.get_global_rect()
	var target_rect := target.get_global_rect()
	var base_start: Vector2 = _control_global_point_to_local(effect_parent, source_rect.position + source_rect.size * 0.5)
	var base_end: Vector2 = _control_global_point_to_local(effect_parent, target_rect.position + target_rect.size * 0.5)
	var flyer_size := _passive_log_flyer_size(module_id, source)
	var source_points := _passive_collection_start_points(source, effect_parent)
	for i in range(visible_count):
		var flyer := _passive_log_sprite(flyer_size, _passive_log_flyer_shadow_offset(flyer_size), 0.28)
		flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flyer.z_index = 225
		effect_parent.add_child(flyer)
		var jitter := Vector2(float((i * 13) % 31) - 15.0, float((i * 7) % 25) - 12.0)
		var start: Vector2 = source_points[i % source_points.size()] if not source_points.is_empty() else base_start + jitter
		var end: Vector2 = base_end + Vector2(float((i * 11) % 23) - 11.0, float((i * 7) % 17) - 8.0)
		var arc_height := 72.0 + float(i % 4) * 12.0
		var apex: Vector2 = (start + end) * 0.5 + Vector2(0, -arc_height)
		flyer.position = start - flyer_size * 0.5
		flyer.rotation_degrees = float(((i * 19) % 41) - 20)
		flyer.pivot_offset = flyer_size * 0.5
		var tween: Tween = host.create_tween()
		var delay := float(i) * 0.035
		tween.tween_interval(delay)
		tween.tween_property(flyer, "position", apex - flyer_size * 0.5, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(flyer, "rotation_degrees", flyer.rotation_degrees + 38.0, 0.20)
		tween.tween_property(flyer, "position", end - flyer_size * 0.5, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(flyer, "rotation_degrees", flyer.rotation_degrees + 82.0, 0.26)
		var currency_icon_id := currency_icon.get_instance_id() if currency_icon != null and is_instance_valid(currency_icon) else 0
		tween.tween_callback(_on_passive_log_landed_bound.bind(target.get_instance_id(), currency_icon_id, i))
		tween.tween_property(flyer, "modulate:a", 0.0, 0.08)
		tween.tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(flyer.get_instance_id()))


func _passive_effect_parent() -> Control:
	var toast_root: Control = host._achievement_toast_surface().toast_root()
	if toast_root != null and is_instance_valid(toast_root):
		return toast_root
	return host


func _passive_log_flyer_size(module_id: String, storage: Control = null) -> Vector2:
	var state: Dictionary = host._passive_modules_runtime().passive_module_state(module_id, host._unix_now())
	var stored := maxi(1, int(state.get("stored", 1)))
	var pile_config := _passive_log_pile_config(_passive_log_pile_tier(stored), stored)
	var fallback_size := pile_config["icon_size"] as Vector2
	if storage != null and is_instance_valid(storage) and storage.has_meta("passive_log_flyer_size"):
		return host._app_lifecycle_runtime().meta_vector2(storage, "passive_log_flyer_size", fallback_size)
	return fallback_size


func _passive_log_flyer_shadow_offset(flyer_size: Vector2) -> Vector2:
	return Vector2(flyer_size.x * 0.035, flyer_size.y * 0.045)


func _passive_local_effect_parent(source: Control, target: Control) -> Control:
	if source != null and target != null:
		var source_parent := source.get_parent() as Control
		if source_parent != null and source_parent == target.get_parent():
			return source_parent
	if source != null:
		var parent := source.get_parent() as Control
		if parent != null:
			return parent
	return host


func _passive_collection_start_points(source: Control, effect_parent: Control) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if source.has_meta("passive_log_flight_points_local"):
		for point in source.get_meta("passive_log_flight_points_local") as Array:
			points.append(_control_global_point_to_local(effect_parent, _control_local_point_to_global(source, point as Vector2)))
		return points
	for child in source.get_children():
		if child is Control and (child as Control).is_visible_in_tree():
			var rect := (child as Control).get_global_rect()
			points.append(_control_global_point_to_local(effect_parent, rect.position + rect.size * 0.5))
	return points


func _passive_storage_destination_points(target: Control, effect_parent: Control) -> Array[Vector2]:
	if target.has_meta("passive_log_flight_points_local"):
		var meta_points: Array[Vector2] = []
		for point in target.get_meta("passive_log_flight_points_local") as Array:
			meta_points.append(_control_global_point_to_local(effect_parent, _control_local_point_to_global(target, point as Vector2)))
		if not meta_points.is_empty():
			return meta_points
	var local_points: Array[Vector2] = [
		Vector2(167, 146),
		Vector2(142, 152),
		Vector2(193, 150),
		Vector2(158, 125),
		Vector2(185, 129),
		Vector2(122, 134),
		Vector2(212, 135)
	]
	var points: Array[Vector2] = []
	for point in local_points:
		points.append(_control_global_point_to_local(effect_parent, _control_local_point_to_global(target, point)))
	return points


func _control_global_point_to_local(control: Control, global_point: Vector2) -> Vector2:
	if control == null or not is_instance_valid(control) or not control.is_inside_tree():
		return global_point
	return control.get_global_transform_with_canvas().affine_inverse() * global_point


func _control_local_point_to_global(control: Control, local_point: Vector2) -> Vector2:
	if control == null or not is_instance_valid(control) or not control.is_inside_tree():
		return local_point
	return control.get_global_transform_with_canvas() * local_point


func _on_passive_yield_log_stored_bound(target_id: int, module_id: String, index: int) -> void:
	var target: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(target_id))
	_on_passive_yield_log_stored(target, module_id, index)


func _on_passive_yield_log_stored(target: Control, module_id: String, index: int) -> void:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return
	host._audio_director()._play_passive_log_land_sfx(index)
	_refresh_passive_loot_for_module(module_id)
	_pop_passive_control(target)


func _refresh_passive_loot_for_module(module_id: String) -> void:
	var key: String = host._action_key("woodcutting", module_id)
	if not host.action_cards.has(key):
		return
	var card := host.action_cards[key] as Dictionary
	card["last_rendered_stored"] = -999999
	card["last_rendered_unlocked"] = false
	_render_passive_loot(card, module_id, host._passive_modules_runtime().is_passive_module_unlocked(module_id))


func _on_passive_log_landed_bound(target_id: int, currency_icon_id: int, index: int) -> void:
	var target: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(target_id))
	var currency_icon: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(currency_icon_id)) if currency_icon_id != 0 else null
	_on_passive_log_landed(target, currency_icon, index)


func _on_passive_log_landed(target: Control, currency_icon: Control, index: int) -> void:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return
	host._audio_director()._play_passive_log_land_sfx(index)
	var pop_anchor := currency_icon if currency_icon != null and is_instance_valid(currency_icon) and currency_icon.is_inside_tree() else target
	_pop_passive_currency_icon(pop_anchor)
	host._reward_feedback_surface()._float_reward(_passive_effect_parent(), pop_anchor, "+1", 46, RewardFeedbackSurface.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -14), Vector2(0, -43), 0.0)


func _pop_passive_currency_icon(anchor: Control) -> void:
	_pop_passive_control(anchor)


func _pop_passive_control(anchor: Control) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	anchor.pivot_offset = anchor.size * 0.5
	var tween: Tween = host.create_tween()
	tween.tween_property(anchor, "scale", Vector2(1.18, 1.18), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(anchor, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _float_passive_upgrade_feedback(module_id: String, stat_type: String, cost: int, old_value: int, new_value: int) -> void:
	var key: String = host._action_key("woodcutting", module_id)
	if not host.action_cards.has(key):
		return
	var card := host.action_cards[key] as Dictionary
	var currency_panel := card.get("currency_panel") as Control
	if currency_panel != null and is_instance_valid(currency_panel) and currency_panel.is_inside_tree():
		host._reward_feedback_surface()._flash_bonus_control(currency_panel)
		_float_log_spend(currency_panel, cost)
	var stats := card.get("stats", {}) as Dictionary
	var stat_anchor := stats.get(stat_type) as Control
	if stat_anchor == null or not is_instance_valid(stat_anchor) or not stat_anchor.is_inside_tree():
		return
	var gain_text: String = _passive_upgrade_gain_text(stat_type, old_value, new_value)
	if gain_text.is_empty():
		return
	host._reward_feedback_surface()._flash_bonus_control(stat_anchor)
	host._reward_feedback_surface()._float_reward(host, stat_anchor, gain_text, 54, RewardFeedbackSurface.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -22), Vector2(0, -69), 0.0)


func _passive_upgrade_gain_text(stat_type: String, old_value: int, new_value: int) -> String:
	if stat_type == "time":
		var saved := old_value - new_value
		return "-%s" % GameFormatting.passive_time(saved) if saved > 0 else ""
	if stat_type == "yield":
		var gained_yield := new_value - old_value
		return "+%s" % gained_yield if gained_yield > 0 else ""
	var gained_capacity := new_value - old_value
	return "+%s" % gained_capacity if gained_capacity > 0 else ""


func _pop_passive_upgrade_button(module_id: String, stat_type: String) -> void:
	var key: String = host._action_key("woodcutting", module_id)
	if not host.action_cards.has(key):
		return
	var card := host.action_cards[key] as Dictionary
	var upgrade_buttons := card.get("upgrade_buttons", {}) as Dictionary
	var upgrade := upgrade_buttons.get(stat_type) as Control
	if upgrade == null or not is_instance_valid(upgrade):
		return
	upgrade.pivot_offset = upgrade.size * 0.5
	var tween: Tween = host.create_tween()
	tween.tween_property(upgrade, "scale", Vector2(1.14, 1.14), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(upgrade, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_passive_card_static_state(card: Dictionary, _skill_id: String, action: Dictionary, unlocked: bool) -> void:
	host._skill_swipe_activity_surface()._update_passive_card_static_state(card, _skill_id, action, unlocked)

func _update_passive_card_progress(card: Dictionary, action: Dictionary, unlocked: bool, instant := false) -> void:
	var progress = card.get("progress") as PassiveModuleStyles.SerpentineProgressBar
	if progress == null:
		return
	var module_id = str(action.get("id", PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID))
	var now: int = host._unix_now()
	var state = host._passive_modules_runtime().passive_module_state(module_id, now)
	var progress_target = host._passive_modules_runtime().passive_production_progress_pct(module_id, state, unlocked, now)
	var progress_instant = instant or (not unlocked) or progress_target + 5.0 < progress.value
	progress.set_target_value(progress_target, progress_instant)


func _update_firepit_card_static_state(card: Dictionary, skill_id: String, action: Dictionary, unlocked: bool, instant := false) -> void:
	host._skill_swipe_activity_surface()._update_firepit_card_static_state(card, skill_id, action, unlocked, instant)


func _passive_action_card_height(action: Dictionary) -> float:
	var now: int = host._unix_now()
	if host._passive_modules_runtime().is_firepit_module(str(action.get("id", ""))):
		var dependency_height := WOODCUTTING_FIREPIT_DEPENDENCY_HEIGHT if host._passive_modules_runtime().firepit_active(now) else 0.0
		return WOODCUTTING_FIREPIT_CARD_HEIGHT + dependency_height
	return float(host.PASSIVE_MODULE_CARD_HEIGHT)


func _apply_firepit_dependency_layout_height(value: float, card_root_id: int, entry_root_id: int, entry_id: int, action_id: String) -> void:
	var reveal_height = clampf(value, 0.0, WOODCUTTING_FIREPIT_DEPENDENCY_HEIGHT)
	var target_height = WOODCUTTING_FIREPIT_CARD_HEIGHT + reveal_height
	var card_root = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_root_id)) if card_root_id != 0 else null
	if card_root != null:
		card_root.position.y = reveal_height
	var firepit_entry_root = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(entry_root_id)) if entry_root_id != 0 else null
	if firepit_entry_root != null:
		firepit_entry_root.custom_minimum_size.y = target_height
		firepit_entry_root.size.y = target_height
		firepit_entry_root.update_minimum_size()
		var firepit_parent = firepit_entry_root.get_parent() as Container
		if firepit_parent != null:
			firepit_parent.queue_sort()
	var entry = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(entry_id)) if entry_id != 0 else null
	if entry != null:
		entry.custom_minimum_size.y = target_height
		entry.size.y = target_height
		entry.update_minimum_size()
		var entry_parent = entry.get_parent() as Container
		if entry_parent != null:
			entry_parent.queue_sort()
	if not action_id.is_empty():
		var lazy_entry = host._skill_detail_surface()._detail_lazy_entry_for_track_id(action_id)
		if not lazy_entry.is_empty():
			lazy_entry["height"] = target_height


func _clear_firepit_dependency_height_tween(card_root_id: int) -> void:
	var card_root = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(card_root_id)) if card_root_id != 0 else null
	if card_root != null and card_root.has_meta("firepit_dependency_height_tween"):
		card_root.remove_meta("firepit_dependency_height_tween")


func _finish_firepit_dependency_visuals(module_id: int, connector_id: int, show_dependency: bool) -> void:
	var module = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(module_id)) if module_id != 0 else null
	var connector = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(connector_id)) if connector_id != 0 else null
	for node in [module, connector]:
		if node == null:
			continue
		if node.has_meta("firepit_dependency_visual_tween"):
			node.remove_meta("firepit_dependency_visual_tween")
		if not show_dependency:
			host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(node, false)


func _sync_firepit_dependency_layout(card: Dictionary, show_dependency: bool, instant := false) -> void:
	var firepit_entry_root = card.get("firepit_entry_root") as Control
	var card_root = card.get("root") as Control
	var scrapwood_module = card.get("scrapwood_module") as Control
	var scrapwood_connector = card.get("scrapwood_connector") as Control
	var entry = card.get("entry") as Control
	var target_reveal_height = WOODCUTTING_FIREPIT_DEPENDENCY_HEIGHT if show_dependency else 0.0
	var current_reveal_height = target_reveal_height
	if card_root != null and is_instance_valid(card_root):
		current_reveal_height = clampf(card_root.position.y, 0.0, WOODCUTTING_FIREPIT_DEPENDENCY_HEIGHT)
	var action = card.get("action", {}) as Dictionary
	var action_id = str(action.get("id", card.get("action_id", "")))
	var seed_layout = not bool(card.get("firepit_dependency_layout_initialized", false))
	var card_root_id = card_root.get_instance_id() if card_root != null and is_instance_valid(card_root) else 0
	var entry_root_id = firepit_entry_root.get_instance_id() if firepit_entry_root != null and is_instance_valid(firepit_entry_root) else 0
	var entry_id = entry.get_instance_id() if entry != null and is_instance_valid(entry) else 0
	if absf(current_reveal_height - target_reveal_height) > 0.5:
		if card_root != null and is_instance_valid(card_root):
			host._app_lifecycle_runtime()._kill_meta_tween(card_root, "firepit_dependency_height_tween")
		if instant or seed_layout or card_root == null or not is_instance_valid(card_root):
			_apply_firepit_dependency_layout_height(target_reveal_height, card_root_id, entry_root_id, entry_id, action_id)
		else:
			var height_tween = card_root.create_tween()
			card_root.set_meta("firepit_dependency_height_tween", height_tween)
			height_tween.tween_method(Callable(self, "_apply_firepit_dependency_layout_height").bind(card_root_id, entry_root_id, entry_id, action_id), current_reveal_height, target_reveal_height, MaterialCollectionSurface.MAT_COLLECTION_APPEAR_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if show_dependency else Tween.EASE_IN)
			height_tween.finished.connect(Callable(self, "_clear_firepit_dependency_height_tween").bind(card_root_id))
	else:
		_apply_firepit_dependency_layout_height(target_reveal_height, card_root_id, entry_root_id, entry_id, action_id)
	card["firepit_dependency_layout_initialized"] = true
	var visual_nodes: Array[Control] = []
	if scrapwood_module != null and is_instance_valid(scrapwood_module):
		visual_nodes.append(scrapwood_module)
	if scrapwood_connector != null and is_instance_valid(scrapwood_connector):
		visual_nodes.append(scrapwood_connector)
	for node in visual_nodes:
		host._app_lifecycle_runtime()._kill_meta_tween(node, "firepit_dependency_visual_tween")
		if show_dependency:
			host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(node, true)
	var target_alpha = 1.0 if show_dependency else 0.0
	var target_scale = Vector2.ONE if show_dependency else Vector2(0.94, 0.94)
	if instant or seed_layout:
		for node in visual_nodes:
			node.modulate.a = target_alpha
			node.scale = target_scale
			host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(node, show_dependency)
		return
	var module_id = scrapwood_module.get_instance_id() if scrapwood_module != null and is_instance_valid(scrapwood_module) else 0
	var connector_id = scrapwood_connector.get_instance_id() if scrapwood_connector != null and is_instance_valid(scrapwood_connector) else 0
	for node in visual_nodes:
		var visual_tween = host.create_tween()
		node.set_meta("firepit_dependency_visual_tween", visual_tween)
		visual_tween.set_parallel(true)
		visual_tween.tween_property(node, "modulate:a", target_alpha, MaterialCollectionSurface.MAT_COLLECTION_APPEAR_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if show_dependency else Tween.EASE_IN)
		visual_tween.tween_property(node, "scale", target_scale, MaterialCollectionSurface.MAT_COLLECTION_APPEAR_SECONDS).set_trans(Tween.TRANS_BACK if show_dependency else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if show_dependency else Tween.EASE_IN)
		visual_tween.finished.connect(_finish_firepit_dependency_visuals.bind(module_id, connector_id, show_dependency))
