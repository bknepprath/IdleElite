extends Control

const PassiveModulesRuntime = preload("res://scripts/gameplay/passive_modules_runtime.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const ThemeStyles = preload("res://scripts/ui/theme_styles.gd")

const PAPER_BUTTON_OUTLINE_WIDTH := 9.0
const STAMINA_GAUGE_UNFILL_SECONDS := 0.34
const STAMINA_GAUGE_POP_SCALE := Vector2(1.018, 1.018)
const STAMINA_GAUGE_SETTLE_SCALE := Vector2(0.997, 0.997)

const VALUE_EPSILON := 0.0015
const RING_ARC_SEGMENTS := 40
const MIN_VISIBLE_REGEN_RING := 0.035
const BEVEL_ARC_SEGMENTS := 32
const LIQUID_FILL_ROWS := 42
const FULL_LIQUID_FILL_ROWS := 48
const SURFACE_OVAL_ROWS := 14
const CENTER_NUMBER_STROKE_SCALE := 36.0
const CENTER_NUMBER_STROKE_MIN := 13
const CENTER_DECIMAL_SUFFIX_SCALE := 0.5
const CENTER_DECIMAL_SUFFIX_ALPHA := 0.6
const LIQUID_EDGE_INSET_SCALE := 2.4
const LIQUID_EDGE_SEAL_WIDTH_SCALE := 4.8
const THEME_COLOR_EASE_SPEED := 7.5
const THEME_COLOR_EPSILON := 0.002
const FIREPIT_WARMTH_COLOR := Color("#ff8f2b")

var value := 0.0
var target_value := 0.0
var displayed_current := 0.0
var target_current := 0.0
var current := 0
var maximum := 1
var show_decimal := true
var dark_mode := false
var theme_color := Color("#36b8e8")
var target_theme_color := Color("#36b8e8")
var regen_ring_color := Color("#36b8e8")
var target_regen_ring_color := Color("#36b8e8")
var firepit_warmth := 0.0
var theme_color_initialized := false
var value_initialized := false
var stamina_initialized := false
var intro_fill_lock := false
var regen_wrap_emptying := false
var regen_wrap_pending_value := 0.0
var regen_unfill_from_max_pending := false
var regen_unfill_start_value := 0.0
var regen_unfill_elapsed := 0.0
var readout_font: Font
var _glass_bowl_texture: ImageTexture
var _glass_bowl_cached_size := Vector2.ZERO
var _pop_tween: Tween
static var _shared_glass_bowl_textures := {}

func _ready() -> void:
	_load_readout_font()
	set_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_invalidate_glass_bowl_cache()

func sync_for_skill(host, skill_id: String, instant := false) -> void:
	if not is_instance_valid(self) or not is_inside_tree():
		return
	var maximum: int = SkillState.max_stamina(host, skill_id)
	var stamina_value: int = SkillState.host_stamina_int(skill_id, host)
	var stamina_decimal_fraction: float = SkillState.stamina_fraction(host.stamina, skill_id, Callable(SkillState, "host_max_stamina").bind(host))
	var circle_value: float = SkillState.stamina_regen_fraction(host.stamina, host.stamina_bank, skill_id, Callable(SkillState, "host_max_stamina").bind(host))
	set_dark_mode(host.dark_mode_enabled)
	set_theme_color(ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE))
	set_regen_ring_color(_regen_ring_color(host, skill_id), instant)
	set_firepit_warmth(host._passive_modules_runtime().firepit_stamina_regen_bonus(skill_id, host._unix_now()) / (PassiveModulesRuntime.FIREPIT_STAMINA_REGEN_PER_TIER * float(PassiveModulesRuntime.FIREPIT_MAX_HEAT_TIER)))
	set_show_decimal(host.show_stamina_decimal)
	set_stamina(stamina_value, maximum, instant, stamina_decimal_fraction)
	set_value(circle_value, instant)

func _regen_ring_color(host, skill_id: String) -> Color:
	return host.material_runtime.color("honey") if host._action_runtime().player_has_stamina_honey() else ThemeStyles.skill_theme_color(skill_id, host.COLOR_BLUE)

func _invalidate_glass_bowl_cache() -> void:
	_glass_bowl_texture = null
	_glass_bowl_cached_size = Vector2.ZERO

func play_pop() -> void:
	clear_pop_tween()
	pivot_offset = size * 0.5
	scale = Vector2.ONE
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "scale", STAMINA_GAUGE_POP_SCALE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pop_tween.tween_property(self, "scale", STAMINA_GAUGE_SETTLE_SCALE, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_pop_tween.tween_property(self, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pop_tween.finished.connect(_finish_stamina_gauge_pop_tween)

func clear_pop_tween() -> void:
	if _pop_tween != null and _pop_tween.is_valid():
		_pop_tween.kill()
	scale = Vector2.ONE
	_pop_tween = null

func play_fail_shake() -> void:
	var tween_meta_key := "stamina_eat_fail_tween"
	var rest_position_meta_key := "stamina_eat_fail_rest_position"
	var rest_rotation_meta_key := "stamina_eat_fail_rest_rotation"
	var base_position := position
	if has_meta(rest_position_meta_key):
		var raw_position = get_meta(rest_position_meta_key)
		if raw_position is Vector2:
			base_position = raw_position
	else:
		set_meta(rest_position_meta_key, base_position)
	var base_rotation := rotation
	if has_meta(rest_rotation_meta_key):
		base_rotation = float(get_meta(rest_rotation_meta_key))
	else:
		set_meta(rest_rotation_meta_key, base_rotation)
	_kill_meta_tween(tween_meta_key)
	pivot_offset = size * 0.5
	position = base_position
	rotation = base_rotation
	modulate = Color(1.0, 1.0, 1.0, modulate.a)
	var direction := -1.0 if randf() < 0.5 else 1.0
	var tween := create_tween()
	set_meta(tween_meta_key, tween)
	tween.set_parallel(true)
	tween.tween_method(_apply_stamina_fail_shake_frame.bind(base_position, base_rotation, direction), 0.0, 1.0, 0.36).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(_finish_stamina_fail_shake.bind(base_position, base_rotation, tween_meta_key, rest_position_meta_key, rest_rotation_meta_key))

func _apply_stamina_fail_shake_frame(progress: float, base_position: Vector2, base_rotation: float, direction: float) -> void:
	var remaining := 1.0 - progress
	var wave := sin(progress * PI * 7.0) * remaining * direction
	position = base_position + Vector2(wave * 7.0, absf(wave) * 1.5)
	rotation = base_rotation + wave * 0.035

func _finish_stamina_fail_shake(base_position: Vector2, base_rotation: float, tween_meta_key: String, rest_position_meta_key: String, rest_rotation_meta_key: String) -> void:
	position = base_position
	rotation = base_rotation
	modulate = Color(1.0, 1.0, 1.0, modulate.a)
	if has_meta(tween_meta_key):
		remove_meta(tween_meta_key)
	if has_meta(rest_position_meta_key):
		remove_meta(rest_position_meta_key)
	if has_meta(rest_rotation_meta_key):
		remove_meta(rest_rotation_meta_key)

func _finish_stamina_gauge_pop_tween() -> void:
	_pop_tween = null

func _kill_meta_tween(meta_name: String) -> void:
	if not has_meta(meta_name):
		return
	var tween := get_meta(meta_name) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	remove_meta(meta_name)

func set_value(next_value: float, instant := false) -> void:
	var clamped_value := clampf(next_value, 0.0, 1.0)
	if instant or not value_initialized:
		if (
			instant
			and value_initialized
			and absf(value - clamped_value) <= 0.0005
			and absf(target_value - clamped_value) <= 0.0005
			and not regen_wrap_emptying
			and not regen_unfill_from_max_pending
		):
			_maybe_sleep_animation_process()
			return
		regen_wrap_emptying = false
		regen_wrap_pending_value = clamped_value
		regen_unfill_from_max_pending = false
		regen_unfill_start_value = clamped_value
		regen_unfill_elapsed = 0.0
		target_value = clamped_value
		value = target_value
		value_initialized = true
		queue_redraw()
		_maybe_sleep_animation_process()
		return
	if (
		not regen_wrap_emptying
		and not regen_unfill_from_max_pending
		and absf(target_value - clamped_value) <= VALUE_EPSILON
		and absf(value - target_value) <= VALUE_EPSILON
	):
		_maybe_sleep_animation_process()
		return
	var wrapped_to_next_refill := clamped_value < target_value - 0.18
	if wrapped_to_next_refill:
		regen_wrap_pending_value = clamped_value
		if regen_unfill_from_max_pending:
			regen_wrap_emptying = true
			regen_unfill_start_value = value
			regen_unfill_elapsed = 0.0
			target_value = 0.0
		else:
			regen_wrap_emptying = false
			target_value = clamped_value
			value = target_value
		regen_unfill_from_max_pending = false
		queue_redraw()
		_ensure_animation_process()
		return
	if regen_wrap_emptying:
		regen_wrap_pending_value = clamped_value
		queue_redraw()
		_ensure_animation_process()
		return
	target_value = clamped_value
	if clamped_value >= 0.995:
		regen_wrap_pending_value = clamped_value
		regen_wrap_emptying = false
		regen_unfill_from_max_pending = false
	if absf(target_value - clamped_value) <= VALUE_EPSILON and absf(value - target_value) <= VALUE_EPSILON:
		_maybe_sleep_animation_process()
		return
	queue_redraw()
	_ensure_animation_process()

func _ensure_animation_process() -> void:
	if intro_fill_lock:
		return
	if not is_processing():
		set_process(true)

func _maybe_sleep_animation_process() -> void:
	if regen_wrap_emptying:
		return
	if absf(value - target_value) > VALUE_EPSILON:
		return
	if absf(displayed_current - target_current) > 0.01:
		return
	if _color_delta(theme_color, target_theme_color) > THEME_COLOR_EPSILON:
		return
	if _color_delta(regen_ring_color, target_regen_ring_color) > THEME_COLOR_EPSILON:
		return
	set_process(false)

func _process(delta: float) -> void:
	if regen_wrap_emptying:
		regen_unfill_elapsed += delta
		var unfill_t := clampf(regen_unfill_elapsed / STAMINA_GAUGE_UNFILL_SECONDS, 0.0, 1.0)
		var unfill_ease := unfill_t * unfill_t * (3.0 - 2.0 * unfill_t)
		var next_empty_value := lerpf(regen_unfill_start_value, 0.0, unfill_ease)
		var unfill_current := _ease_to(displayed_current, target_current, 9.0, delta)
		if unfill_t >= 1.0 or next_empty_value <= 0.003:
			next_empty_value = 0.0
			regen_wrap_emptying = false
			target_value = regen_wrap_pending_value
		value = next_empty_value
		displayed_current = unfill_current
		_update_theme_color(delta)
		queue_redraw()
		return
	var next_value := _ease_to(value, target_value, 18.0, delta)
	var eased_current := _ease_to(displayed_current, target_current, 9.0, delta)
	var color_changed := _update_theme_color(delta)
	if absf(next_value - value) > 0.0005 or absf(eased_current - displayed_current) > 0.01 or color_changed:
		value = next_value
		displayed_current = eased_current
		queue_redraw()
	else:
		var needs_final_redraw := absf(value - target_value) > 0.0 or absf(displayed_current - target_current) > 0.0 or _color_delta(theme_color, target_theme_color) > 0.0 or _color_delta(regen_ring_color, target_regen_ring_color) > 0.0
		value = target_value
		displayed_current = target_current
		theme_color = target_theme_color
		regen_ring_color = target_regen_ring_color
		if needs_final_redraw:
			queue_redraw()
	_maybe_sleep_animation_process()

func _ease_to(from: float, to: float, speed: float, delta: float) -> float:
	if delta <= 0.0:
		return from
	return lerpf(from, to, 1.0 - exp(-speed * delta))

func _ease_color_to(from: Color, to: Color, speed: float, delta: float) -> Color:
	var weight := 1.0 - exp(-speed * maxf(0.0, delta))
	return from.lerp(to, weight)

func _color_delta(a: Color, b: Color) -> float:
	return maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), maxf(absf(a.b - b.b), absf(a.a - b.a)))

func _update_theme_color(delta: float) -> bool:
	var changed := false
	if _color_delta(theme_color, target_theme_color) <= THEME_COLOR_EPSILON:
		if _color_delta(theme_color, target_theme_color) > 0.0:
			theme_color = target_theme_color
			changed = true
	else:
		var next_color := _ease_color_to(theme_color, target_theme_color, THEME_COLOR_EASE_SPEED, delta)
		changed = _color_delta(theme_color, next_color) > 0.0001
		theme_color = next_color
	if _color_delta(regen_ring_color, target_regen_ring_color) <= THEME_COLOR_EPSILON:
		if _color_delta(regen_ring_color, target_regen_ring_color) > 0.0:
			regen_ring_color = target_regen_ring_color
			changed = true
	else:
		var next_ring_color := _ease_color_to(regen_ring_color, target_regen_ring_color, THEME_COLOR_EASE_SPEED, delta)
		changed = changed or _color_delta(regen_ring_color, next_ring_color) > 0.0001
		regen_ring_color = next_ring_color
	return changed

func set_theme_color(next_color: Color, instant := false) -> void:
	if theme_color_initialized and target_theme_color.is_equal_approx(next_color) and target_regen_ring_color.is_equal_approx(next_color) and (not instant or (theme_color.is_equal_approx(next_color) and regen_ring_color.is_equal_approx(next_color))):
		return
	target_theme_color = next_color
	target_regen_ring_color = next_color
	if instant or not theme_color_initialized:
		theme_color = next_color
		regen_ring_color = next_color
		theme_color_initialized = true
		queue_redraw()
		_maybe_sleep_animation_process()
		return
	theme_color_initialized = true
	queue_redraw()
	_ensure_animation_process()

func set_regen_ring_color(next_color: Color, instant := false) -> void:
	if theme_color_initialized and target_regen_ring_color.is_equal_approx(next_color) and (not instant or regen_ring_color.is_equal_approx(next_color)):
		return
	target_regen_ring_color = next_color
	if instant or not theme_color_initialized:
		regen_ring_color = next_color
		queue_redraw()
		_maybe_sleep_animation_process()
		return
	queue_redraw()
	_ensure_animation_process()

func set_firepit_warmth(next_warmth: float) -> void:
	var clamped_warmth := clampf(next_warmth, 0.0, 1.0)
	if absf(firepit_warmth - clamped_warmth) <= 0.002:
		return
	firepit_warmth = clamped_warmth
	queue_redraw()

func set_show_decimal(enabled: bool) -> void:
	if show_decimal == enabled:
		return
	show_decimal = enabled
	queue_redraw()

func set_dark_mode(enabled: bool) -> void:
	if dark_mode == enabled:
		return
	dark_mode = enabled
	queue_redraw()

func set_stamina(next_current: int, next_maximum: int, instant := false, regen_fraction := 0.0) -> void:
	var next_current_clamped := maxi(0, next_current)
	var next_maximum_clamped := maxi(1, next_maximum)
	var next_target_current := clampf(float(next_current_clamped) + clampf(regen_fraction, 0.0, 1.0), 0.0, float(next_maximum_clamped))
	if (
		stamina_initialized
		and current == next_current_clamped
		and maximum == next_maximum_clamped
		and absf(target_current - next_target_current) <= 0.01
		and (not instant or absf(displayed_current - next_target_current) <= 0.01)
	):
		if not instant and absf(displayed_current - target_current) > 0.01:
			_ensure_animation_process()
		else:
			_maybe_sleep_animation_process()
		return
	var was_full := stamina_initialized and current >= maximum
	current = next_current_clamped
	maximum = next_maximum_clamped
	var is_below_max := current < maximum
	if instant or not stamina_initialized:
		regen_unfill_from_max_pending = false
	elif was_full and is_below_max:
		regen_unfill_from_max_pending = true
	target_current = next_target_current
	if instant or not stamina_initialized:
		displayed_current = target_current
		stamina_initialized = true
	queue_redraw()
	_ensure_animation_process()

func _draw() -> void:
	var center := size * 0.5
	var draw_scale := minf(size.x, size.y) / 552.0
	var outer_radius := minf(size.x, size.y) * 0.5
	var gauge_stroke := PAPER_BUTTON_OUTLINE_WIDTH * draw_scale
	var ring_width := 30.0 * draw_scale
	var ring_radius := outer_radius - ring_width * 0.5
	var ring_inner_radius := ring_radius - ring_width * 0.5
	var inner_radius := ring_inner_radius - gauge_stroke
	var visible_value := value
	if visible_value > VALUE_EPSILON and visible_value < MIN_VISIBLE_REGEN_RING:
		visible_value = MIN_VISIBLE_REGEN_RING
	if visible_value > VALUE_EPSILON:
		_draw_regen_progress_arc(center, ring_radius, visible_value, ring_width)
	_draw_inner_fill(center, inner_radius, draw_scale)
	_draw_inner_bevel(center, inner_radius, draw_scale)
	_draw_liquid_edge_seal(center, inner_radius, draw_scale)
	draw_arc(center, inner_radius + gauge_stroke * 0.5, -PI * 0.5, PI * 1.5, RING_ARC_SEGMENTS, Color("#171615"), gauge_stroke, true)
	_draw_center_text(center)

func _draw_regen_progress_arc(center: Vector2, radius: float, visible_value: float, width: float) -> void:
	var start_angle := -PI * 0.5
	var sweep := TAU * clampf(visible_value, 0.0, 1.0)
	if firepit_warmth <= 0.002:
		draw_arc(center, radius, start_angle, start_angle + sweep, RING_ARC_SEGMENTS, regen_ring_color, width, true)
		return
	var segments := maxi(16, int(ceil(absf(sweep) / TAU * 96.0)))
	for segment in range(segments):
		var a0 := start_angle + sweep * float(segment) / float(segments)
		var a1 := start_angle + sweep * float(segment + 1) / float(segments)
		var mid_angle := (a0 + a1) * 0.5
		draw_arc(center, radius, a0, a1, 2, _firepit_regen_ring_color(mid_angle), width, true)

func _firepit_regen_ring_color(angle: float) -> Color:
	var visual_warmth := lerpf(0.82, 1.0, firepit_warmth)
	var lower_strength := smoothstep(-0.08, 0.42, sin(angle))
	var warmth := FIREPIT_WARMTH_COLOR.lerp(Color("#ffd27a"), 0.10 * (1.0 - lower_strength))
	return regen_ring_color.lerp(warmth, clampf(lower_strength * visual_warmth, 0.0, 1.0))

func _ensure_glass_bowl_texture() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var draw_size := size.floor()
	if draw_size.x < 2.0 or draw_size.y < 2.0:
		return
	if _glass_bowl_texture != null and _glass_bowl_cached_size.is_equal_approx(draw_size):
		return
	var cache_key := "%sx%s" % [str(int(draw_size.x)), str(int(draw_size.y))]
	if _shared_glass_bowl_textures.has(cache_key):
		_glass_bowl_texture = _shared_glass_bowl_textures[cache_key] as ImageTexture
		_glass_bowl_cached_size = draw_size
		return
	var center := draw_size * 0.5
	var draw_scale := minf(draw_size.x, draw_size.y) / 552.0
	var outer_radius := minf(draw_size.x, draw_size.y) * 0.5
	var gauge_stroke := PAPER_BUTTON_OUTLINE_WIDTH * draw_scale
	var ring_width := 30.0 * draw_scale
	var ring_radius := outer_radius - ring_width * 0.5
	var ring_inner_radius := ring_radius - ring_width * 0.5
	var inner_radius := ring_inner_radius - gauge_stroke
	var image := Image.create(int(draw_size.x), int(draw_size.y), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_paint_glass_bowl_to_image(image, center, inner_radius, draw_scale)
	if DisplayServer.get_name() == "headless" or image == null or image.is_empty():
		return
	_glass_bowl_texture = ImageTexture.create_from_image(image)
	_glass_bowl_cached_size = draw_size
	_shared_glass_bowl_textures[cache_key] = _glass_bowl_texture

func _paint_glass_bowl_to_image(image: Image, center: Vector2, radius: float, draw_scale: float) -> void:
	_image_paint_disc(image, center, radius, Color("#fffaf0"))
	var step := maxf(1.0, radius / 74.0)
	var y := center.y - radius
	while y <= center.y + radius:
		var dy := y - center.y
		var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
		var vertical := clampf((dy / radius + 1.0) * 0.5, 0.0, 1.0)
		var glass_tint := Color("#eef7ff", 0.18 * (1.0 - vertical) + 0.04)
		_image_paint_thick_hline(
			image,
			int(round(center.x - chord)),
			int(round(center.x + chord)),
			int(round(y)),
			glass_tint,
			int(ceil(step + 1.0))
		)
		y += step
	_image_paint_ellipse_arc(
		image,
		center + Vector2(-radius * 0.25, -radius * 0.39),
		radius * 0.30,
		radius * 0.11,
		Color(1, 1, 1, 0.34),
		maxf(1.0, 2.0 * draw_scale),
		center,
		radius
	)
	_image_paint_ellipse_arc(
		image,
		center + Vector2(radius * 0.26, radius * 0.27),
		radius * 0.19,
		radius * 0.07,
		Color(1, 1, 1, 0.11),
		maxf(1.0, 1.4 * draw_scale),
		center,
		radius
	)

func _image_paint_disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var pixel_radius := int(ceil(radius))
	var center_x := int(round(center.x))
	var center_y := int(round(center.y))
	for y in range(center_y - pixel_radius, center_y + pixel_radius + 1):
		if y < 0 or y >= image.get_height():
			continue
		for x in range(center_x - pixel_radius, center_x + pixel_radius + 1):
			if x < 0 or x >= image.get_width():
				continue
			if Vector2(x + 0.5, y + 0.5).distance_to(center) <= radius + 0.5:
				_image_blend_pixel(image, x, y, color)

func _image_blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var existing := image.get_pixel(x, y)
	var alpha := clampf(color.a, 0.0, 1.0)
	if alpha <= 0.0:
		return
	if alpha >= 0.999 and existing.a <= 0.001:
		image.set_pixel(x, y, color)
		return
	var blended := existing.lerp(color, alpha)
	blended.a = clampf(existing.a + alpha * (1.0 - existing.a), 0.0, 1.0)
	image.set_pixel(x, y, blended)

func _image_paint_thick_hline(image: Image, x0: int, x1: int, y: int, color: Color, thickness: int) -> void:
	if thickness <= 0:
		return
	var left := mini(x0, x1)
	var right := maxi(x0, x1)
	var half := int(thickness / 2.0)
	for row in range(y - half, y - half + thickness):
		for x in range(left, right + 1):
			_image_blend_pixel(image, x, row, color)

func _image_paint_ellipse_arc(
	image: Image,
	ellipse_center: Vector2,
	half_width: float,
	half_height: float,
	color: Color,
	width: float,
	clip_center: Vector2,
	clip_radius: float
) -> void:
	var previous := Vector2.ZERO
	var has_previous := false
	for i in range(97):
		var angle := lerpf(0.0, TAU, float(i) / 96.0)
		var point := ellipse_center + Vector2(cos(angle) * half_width, sin(angle) * half_height)
		var inside := point.distance_to(clip_center) <= clip_radius + width * 0.5
		if inside and has_previous:
			_image_paint_line(image, previous, point, color, width)
		previous = point
		has_previous = inside

func _image_paint_line(image: Image, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var length := maxf(1.0, from.distance_to(to))
	var steps := maxi(1, int(ceil(length)))
	var half_width := maxi(1, int(ceil(width * 0.5)))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var point := from.lerp(to, t)
		for oy in range(-half_width, half_width + 1):
			for ox in range(-half_width, half_width + 1):
				_image_blend_pixel(image, int(round(point.x)) + ox, int(round(point.y)) + oy, color)

func _draw_inner_fill(center: Vector2, radius: float, draw_scale: float) -> void:
	var pct := clampf(displayed_current / float(maximum), 0.0, 1.0)
	if current <= 0:
		return
	if pct <= VALUE_EPSILON:
		return
	var fill_radius := maxf(1.0, radius - LIQUID_EDGE_INSET_SCALE * draw_scale)
	if pct >= 0.995:
		_draw_full_liquid_sphere(center, fill_radius)
		return
	var fill_top := center.y + fill_radius - fill_radius * 2.0 * pct
	var fill_bottom := center.y + fill_radius
	var top_color := theme_color.lerp(Color.BLACK, 0.03)
	var bottom_color := theme_color.lerp(Color.BLACK, 0.26)
	var surface_half_width := sqrt(maxf(0.0, fill_radius * fill_radius - pow(fill_top - center.y, 2.0))) * 0.97
	var surface_curve_depth := clampf(fill_radius * 0.075, 4.0, 9.5)
	var surface_height := surface_curve_depth
	_draw_liquid_segment(center, fill_radius, fill_top, fill_bottom, top_color, bottom_color)
	if displayed_current >= 1.0 and pct < 0.96:
		_draw_liquid_surface_oval(center, fill_radius, fill_top, surface_half_width, surface_height, draw_scale)

func _draw_full_liquid_sphere(center: Vector2, radius: float) -> void:
	if radius <= 1.0:
		return
	var top_color := theme_color.lerp(Color.BLACK, 0.03)
	var bottom_color := theme_color.lerp(Color.BLACK, 0.28)
	var rows := maxi(8, FULL_LIQUID_FILL_ROWS)
	var row_width := maxf(1.0, (radius * 2.0) / float(rows) + 1.25)
	for i in range(rows + 1):
		var y := lerpf(center.y - radius, center.y + radius, float(i) / float(rows))
		var dy := y - center.y
		var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
		var depth := clampf((dy / radius + 1.0) * 0.5, 0.0, 1.0)
		var fill_color := top_color.lerp(bottom_color, depth)
		draw_line(Vector2(center.x - chord, y), Vector2(center.x + chord, y), fill_color, row_width, true)

func _draw_liquid_segment(center: Vector2, radius: float, fill_top: float, fill_bottom: float, top_color: Color, bottom_color: Color) -> void:
	if radius <= 1.0 or fill_bottom <= fill_top:
		return
	var rows := maxi(8, LIQUID_FILL_ROWS)
	var row_width := maxf(1.0, (fill_bottom - fill_top) / float(rows) + 1.25)
	for i in range(rows + 1):
		var depth := float(i) / float(rows)
		var y := lerpf(fill_top, fill_bottom, depth)
		var dy := y - center.y
		var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
		if chord <= 0.5:
			continue
		var fill_color := top_color.lerp(bottom_color, depth * 0.78)
		draw_line(Vector2(center.x - chord, y), Vector2(center.x + chord, y), fill_color, row_width, true)
		var edge_shadow := Color(0.03, 0.02, 0.03, 0.12 * depth)
		draw_line(Vector2(center.x - chord, y), Vector2(center.x - chord * 0.76, y), edge_shadow, row_width, true)
		draw_line(Vector2(center.x + chord * 0.76, y), Vector2(center.x + chord, y), edge_shadow, row_width, true)

func _draw_liquid_surface_oval(center: Vector2, radius: float, y_center: float, half_width: float, half_height: float, _draw_scale: float) -> void:
	if radius <= 1.0 or half_width <= 0.5 or half_height <= 0.5:
		return
	var oval_center := Vector2(center.x, y_center)
	var surface_color := theme_color.lerp(Color.WHITE, 0.16)
	var rim_shadow := theme_color.lerp(Color.BLACK, 0.18)
	rim_shadow.a = 0.18
	var rows := maxi(4, SURFACE_OVAL_ROWS)
	var row_width := maxf(1.0, (half_height * 2.0) / float(rows) + 1.0)
	for i in range(rows + 1):
		var y := lerpf(oval_center.y - half_height, oval_center.y + half_height, float(i) / float(rows))
		var normalized := (y - oval_center.y) / maxf(1.0, half_height)
		var ellipse_half := half_width * sqrt(maxf(0.0, 1.0 - normalized * normalized))
		var circle_half := sqrt(maxf(0.0, radius * radius - pow(y - center.y, 2.0)))
		var half := minf(ellipse_half, circle_half)
		if half <= 0.5:
			continue
		var row_color := surface_color
		if normalized < -0.42:
			var rim_t := clampf((-0.42 - normalized) / 0.58, 0.0, 1.0)
			row_color = surface_color.lerp(rim_shadow, rim_t * 0.28)
		draw_line(Vector2(oval_center.x - half, y), Vector2(oval_center.x + half, y), row_color, row_width, true)

func _draw_ellipse_lines(ellipse_center: Vector2, half_width: float, half_height: float, color: Color, width: float, clip_center: Vector2, clip_radius: float) -> void:
	_draw_ellipse_arc_lines(ellipse_center, half_width, half_height, 0.0, TAU, color, width, clip_center, clip_radius)

func _draw_ellipse_arc_lines(ellipse_center: Vector2, half_width: float, half_height: float, start_angle: float, end_angle: float, color: Color, width: float, clip_center: Vector2, clip_radius: float) -> void:
	var previous := Vector2.ZERO
	var has_previous := false
	for i in range(97):
		var angle := lerpf(start_angle, end_angle, float(i) / 96.0)
		var point := ellipse_center + Vector2(cos(angle) * half_width, sin(angle) * half_height)
		var inside := point.distance_to(clip_center) <= clip_radius + width * 0.5
		if inside and has_previous:
			draw_line(previous, point, color, width, true)
		previous = point
		has_previous = inside

func _draw_inner_bevel(center: Vector2, radius: float, draw_scale: float) -> void:
	var bevel_radius := radius - 8.0 * draw_scale
	draw_arc(center, bevel_radius, PI * 0.12, PI * 0.88, BEVEL_ARC_SEGMENTS, Color(0.05, 0.04, 0.03, 0.14), maxf(4.0, 8.0 * draw_scale), true)
	draw_arc(center, bevel_radius - 5.0 * draw_scale, PI * 0.18, PI * 0.82, BEVEL_ARC_SEGMENTS, Color(0.05, 0.04, 0.03, 0.07), maxf(3.0, 5.0 * draw_scale), true)
	draw_arc(center, bevel_radius, PI * 1.12, PI * 1.88, BEVEL_ARC_SEGMENTS, Color(1, 1, 1, 0.13), maxf(2.0, 3.5 * draw_scale), true)

func _draw_liquid_edge_seal(center: Vector2, radius: float, draw_scale: float) -> void:
	var seal_width := LIQUID_EDGE_SEAL_WIDTH_SCALE * draw_scale
	var seal_radius := radius - seal_width * 0.50 + 0.6 * draw_scale
	if seal_radius <= 1.0 or seal_width <= 0.5:
		return
	draw_arc(center, seal_radius, -PI * 0.5, PI * 1.5, RING_ARC_SEGMENTS, Color("#171615"), seal_width, true)

func _draw_center_text(center: Vector2) -> void:
	var font := readout_font if readout_font != null else ThemeDB.fallback_font
	var min_size := minf(size.x, size.y)
	var draw_scale := min_size / 552.0
	var max_text_width := min_size * 0.72
	var number_parts := _stamina_display_number_parts()
	var current_text := str(number_parts.get("main", str(clampi(current, 0, maximum))))
	var decimal_text := str(number_parts.get("suffix", ""))
	var large := _fit_font_size(font, current_text, maxi(64, int(min_size * 0.34)), 48, max_text_width)
	var small_text := str(maximum)
	var small := _fit_font_size(font, small_text, maxi(48, int(min_size * 0.13)), 48, max_text_width)
	var current_center_y := center.y - 22.0 * draw_scale
	var divider_y := center.y + 91.0 * draw_scale
	var max_center_y := center.y + 128.0 * draw_scale
	var current_stroke := maxi(CENTER_NUMBER_STROKE_MIN, int(round(CENTER_NUMBER_STROKE_SCALE * draw_scale)))
	_draw_stroked_number_with_decimal_suffix(font, current_text, decimal_text, Vector2(center.x, current_center_y), large, Color.WHITE, current_stroke)
	_draw_center_divider(center, divider_y, 106.0 * draw_scale, draw_scale)
	_draw_text_centered(font, small_text, Vector2(center.x, max_center_y), small, _readout_denominator_color())

func _readout_denominator_color() -> Color:
	return Color.WHITE if dark_mode else Color(0, 0, 0, 0.8)

func _stamina_display_number_parts() -> Dictionary:
	var display_value := clampf(displayed_current, 0.0, float(maximum))
	var shown_current := clampi(int(floor(display_value)), 0, maximum)
	if not show_decimal:
		return {"main": str(shown_current), "suffix": ""}
	if shown_current >= maximum:
		return {"main": str(maximum), "suffix": ""}
	var decimal_digit := clampi(int(floor((display_value - float(shown_current)) * 10.0 + 0.0001)), 0, 9)
	return {
		"main": str(shown_current),
		"suffix": ".%d" % decimal_digit
	}

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

func _draw_center_divider(center: Vector2, y: float, width: float, draw_scale: float) -> void:
	var start := Vector2(center.x - width * 0.5, y)
	var finish := Vector2(center.x + width * 0.5, y)
	var line_width := maxf(2.0, 4.5 * draw_scale)
	var line_color := _readout_denominator_color()
	draw_line(start, finish, line_color, line_width, true)
	draw_circle(start, line_width * 0.5, line_color)
	draw_circle(finish, line_width * 0.5, line_color)

func _draw_stroked_text_centered(font: Font, text: String, center: Vector2, font_size: int, fill_color: Color, stroke_size: int) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var text_position := Vector2(center.x - text_size.x * 0.5, baseline)
	draw_string_outline(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, stroke_size, Color("#171615"))
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill_color)

func _draw_stroked_number_with_decimal_suffix(font: Font, main_text: String, suffix_text: String, center: Vector2, font_size: int, fill_color: Color, stroke_size: int) -> void:
	var main_size := font.get_string_size(main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var main_baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var main_position := Vector2(center.x - main_size.x * 0.5, main_baseline)
	draw_string_outline(font, main_position, main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, stroke_size, Color("#171615"))
	draw_string(font, main_position, main_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill_color)
	if suffix_text.is_empty():
		return
	var suffix_size := maxi(48, int(round(float(font_size) * CENTER_DECIMAL_SUFFIX_SCALE)))
	var suffix_stroke := maxi(6, int(round(float(stroke_size) * CENTER_DECIMAL_SUFFIX_SCALE)))
	var suffix_gap := maxf(4.0, float(font_size) * 0.075)
	var suffix_baseline := center.y + (font.get_ascent(suffix_size) - font.get_descent(suffix_size)) * 0.5
	var suffix_position := Vector2(main_position.x + main_size.x + suffix_gap, suffix_baseline)
	var suffix_fill := fill_color
	suffix_fill.a *= CENTER_DECIMAL_SUFFIX_ALPHA
	var suffix_outline := Color("#171615", CENTER_DECIMAL_SUFFIX_ALPHA)
	draw_string_outline(font, suffix_position, suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, suffix_size, suffix_stroke, suffix_outline)
	draw_string(font, suffix_position, suffix_text, HORIZONTAL_ALIGNMENT_LEFT, -1, suffix_size, suffix_fill)

func _draw_text_centered(font: Font, text: String, center: Vector2, font_size: int, fill_color: Color) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var text_position := Vector2(center.x - text_size.x * 0.5, baseline)
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, fill_color)
