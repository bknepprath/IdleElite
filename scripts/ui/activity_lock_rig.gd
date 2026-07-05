extends Control

signal chain_moved(kind: String, intensity: float)
signal padlock_clicked
signal padlock_hovered

const LINKS_PER_SIDE := 5
const LINK_SIZE := Vector2(210, 130)
const PADLOCK_SIZE := Vector2(540, 590)
const PADLOCK_SOURCE_CROP_RIGHT := 3.0
const PADLOCK_SHADOW_OFFSET := Vector2(0, 16)
const CONSTRAINT_PASSES := 14
const LOCK_CHAIN_TAUT_RATIO := 1.16
const LOCK_CHAIN_TAUT_SLACK_PIXELS := 18.0
const LOCK_CHAIN_LIMIT_PASSES := 5
const CHAIN_METAL_TINT := Color("#b9c0c3")
const CHAIN_STROKE_TINT := Color(0.02, 0.018, 0.016, 0.82)
const CHAIN_LINK_SHADE_TINT := Color(0.05, 0.052, 0.054, 0.18)
const CHAIN_LINK_SHADE_START := 0.62
const CHAIN_SHADOW_OFFSET := Vector2(0, 12)
const CHAIN_SLACK_SAG_PIXELS := 66.0
const CHAIN_SLACK_PULL_RANGE_RATIO := 0.22
const CHAIN_SLACK_GRAVITY_PIXELS := 620.0
const CHAIN_SLACK_REST_PULL_MIN := 0.18
const CHAIN_SLACK_REST_PULL_MAX := 0.52
const CHAIN_EDGE_ANCHOR_INSET_RATIO := 0.30
const LOCK_DRAG_DEADZONE := 14.0
const CHAIN_SFX_COOLDOWN_MSEC := 170
const CHAIN_SFX_MOVE_DISTANCE := 38.0
const LOCK_CLICK_SHAKE_SECONDS := 0.26
const UNLOCK_DROP_SECONDS := 0.96
const UNLOCK_POP_SECONDS := 0.30
const UNLOCK_LOCK_CHAINS_TEXTURE := "res://assets/content/ui/unlock-lock-chains.png"
const UNLOCK_CHAIN_LINK_TEXTURE := "res://assets/content/ui/unlock-chain-link.png"
const UNLOCK_CHAIN_LEFT_TEXTURE := "res://assets/content/ui/unlock-chain-left.png"
const UNLOCK_CHAIN_RIGHT_TEXTURE := "res://assets/content/ui/unlock-chain-right.png"
const UNLOCK_PADLOCK_TEXTURE := "res://assets/content/ui/unlock-padlock.png"
const UNLOCK_LOCK_BODY_TEXTURE := "res://assets/content/ui/unlock-lock-body.png"
const UNLOCK_LOCK_SHACKLE_CLOSED_TEXTURE := "res://assets/content/ui/unlock-lock-shackle-closed.png"
const UNLOCK_LOCK_SHACKLE_OPEN_TEXTURE := "res://assets/content/ui/unlock-lock-shackle-open.png"
const UNLOCK_LOCK_TINT_MASK_TEXTURE := "res://assets/content/ui/unlock-lock-tint-mask.png"
const UNLOCK_LOCK_PULSE_MASK_TEXTURE := "res://assets/content/ui/unlock-lock-pulse-mask.png"
const READY_OPEN_CLINK_SECONDS := 0.30
const READY_OPEN_SHACKLE_LIFT := 86.0
const READY_OPEN_HANG_DROP := 86.0
const READY_OPEN_HANG_ROTATION := 0.16
const DROP_CHAIN_CAPTURE_BLEND_END := 0.42
const UNLOCK_SUCCESS_GREEN := Color("#45f08a")
const PADLOCK_HIT_ALPHA_THRESHOLD := 0.08
const LOCK_STATE_CLOSED := "closed"
const LOCK_STATE_READY_OPEN := "ready_open"
const LOCK_STATE_DROPPING := "dropping"
const LOCK_STATE_GONE := "gone"

class _ActivityLockNumber extends Control:
	var text := "1"
	var font: Font
	var font_size := 250
	var outline_size := 46
	var fill_color := Color.WHITE

	func set_text(next_text: String) -> void:
		text = next_text
		queue_redraw()

	func set_fill_color(next_color: Color) -> void:
		fill_color = next_color
		queue_redraw()

	func _draw() -> void:
		var active_font := font if font != null else ThemeDB.fallback_font
		var fitted := font_size
		var max_width := size.x * 0.86
		while fitted > 72 and active_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x > max_width:
			fitted -= 4
		var text_size := active_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted)
		var baseline := size.y * 0.5 + (active_font.get_ascent(fitted) - active_font.get_descent(fitted)) * 0.5
		var text_position := Vector2((size.x - text_size.x) * 0.5, baseline)
		for x in range(-outline_size, outline_size + 1, 3):
			for y in range(-outline_size, outline_size + 1, 3):
				if x == 0 and y == 0:
					continue
				var offset := Vector2(x, y)
				if offset.length() <= float(outline_size) + 0.25:
					draw_string(active_font, text_position + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, Color("#171615"))
		draw_string(active_font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted, fill_color)

var link_texture: Texture2D
var padlock_texture: Texture2D
var padlock_tint_mask_texture: Texture2D
var padlock_pulse_texture: Texture2D
var padlock_body_texture: Texture2D
var padlock_shackle_closed_texture: Texture2D
var padlock_shackle_open_texture: Texture2D
var padlock_hit_image: Image
var chain_points := {-1: [], 1: []}
var chain_prev_points := {-1: [], 1: []}
var chain_rest_lengths := {-1: [], 1: []}
var chain_base_points := {-1: [], 1: []}
var drop_chain_start_points := {-1: [], 1: []}
var drop_chain_start_links := {-1: [], 1: []}
var padlock_shadow: TextureRect
var padlock: TextureRect
var padlock_shackle: TextureRect
var padlock_tint: TextureRect
var level_label: _ActivityLockNumber
var level := 1
var theme_color := Color("#ffd238")
var lock_state := LOCK_STATE_CLOSED
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
var unlock_drop_active := false
var unlock_drop_progress := 0.0
var unlock_pop_progress := 0.0
var unlock_success_click_consumed := false
var unlock_drop_tween: Tween
var ready_open_tween: Tween
var ready_open_progress := 0.0
var lock_hovered := false
var rng := RandomNumberGenerator.new()
var chain_visible := true
var padlock_visible := true
var base_lock_x_shift := 0.0
var custom_chain_path_points: Array = []
var custom_chain_render_count := 0

static func new_lock_number() -> Control:
	return _ActivityLockNumber.new()

func setup(next_link_texture: Texture2D, next_padlock_texture: Texture2D, next_padlock_pulse_texture: Texture2D, unlock_level: int, font: Font, fallback_font: Font, next_padlock_hit_image: Image = null, next_padlock_tint_mask_texture: Texture2D = null, next_theme_color: Color = Color("#ffd238"), next_padlock_body_texture: Texture2D = null, next_padlock_shackle_closed_texture: Texture2D = null, next_padlock_shackle_open_texture: Texture2D = null) -> void:
	link_texture = next_link_texture
	padlock_texture = next_padlock_texture if next_padlock_hit_image != null else cropped_padlock_texture(next_padlock_texture)
	padlock_tint_mask_texture = next_padlock_tint_mask_texture
	padlock_pulse_texture = next_padlock_pulse_texture if next_padlock_pulse_texture != null else _alpha_mask_texture(padlock_texture)
	padlock_body_texture = next_padlock_body_texture
	padlock_shackle_closed_texture = next_padlock_shackle_closed_texture
	padlock_shackle_open_texture = next_padlock_shackle_open_texture
	padlock_hit_image = next_padlock_hit_image if next_padlock_hit_image != null else cropped_padlock_hit_image(next_padlock_texture)
	level = unlock_level
	theme_color = next_theme_color
	lock_state = LOCK_STATE_CLOSED
	mouse_filter = Control.MOUSE_FILTER_PASS
	rng.randomize()
	_build(font, fallback_font)
	set_process(false)
	call_deferred("_layout_base")

func set_unlock_level(next_level: int) -> void:
	level = next_level
	if level_label != null:
		level_label.set_text(str(level))


func set_theme_color(next_theme_color: Color) -> void:
	theme_color = next_theme_color
	if padlock_tint != null:
		padlock_tint.modulate = _padlock_tint_modulate()
	if level_label != null:
		level_label.set_fill_color(_lock_number_fill_color())


func set_lock_state(next_state: String) -> void:
	var previous_state := lock_state
	var normalized := next_state
	if not [LOCK_STATE_CLOSED, LOCK_STATE_READY_OPEN, LOCK_STATE_DROPPING, LOCK_STATE_GONE].has(normalized):
		normalized = LOCK_STATE_CLOSED
	lock_state = normalized
	if normalized != LOCK_STATE_READY_OPEN:
		_stop_ready_open_animation(false)
	_apply_lock_state_visuals()
	if previous_state != LOCK_STATE_READY_OPEN and normalized == LOCK_STATE_READY_OPEN:
		_play_ready_open_animation()


func set_chain_visible(next_visible: bool) -> void:
	chain_visible = next_visible
	queue_redraw()


func set_custom_chain_path(points: Array, render_count := 0) -> void:
	custom_chain_path_points = []
	for raw_point in points:
		if raw_point is Vector2:
			custom_chain_path_points.append(raw_point as Vector2)
	custom_chain_render_count = maxi(0, render_count)
	queue_redraw()


func set_padlock_visible(next_visible: bool) -> void:
	padlock_visible = next_visible
	_apply_lock_state_visuals()


func set_base_lock_x_shift(next_shift: float) -> void:
	base_lock_x_shift = next_shift
	_layout_base()


func sync_shared_motion(next_offset: Vector2, next_velocity: Vector2, next_rotation: float) -> void:
	lock_offset = next_offset
	lock_velocity = next_velocity
	lock_rotation = next_rotation
	if chain_visible:
		_reset_chain_points(false)
	_place_padlock(lock_offset, lock_rotation)
	queue_redraw()


func unlock_impulse() -> void:
	_rattle_lock()

func consume_unlock_click() -> void:
	unlock_success_click_consumed = true

func reset_unlock_drop_animation() -> void:
	if unlock_drop_tween != null and unlock_drop_tween.is_valid():
		unlock_drop_tween.kill()
	unlock_drop_tween = null
	unlock_drop_active = false
	unlock_drop_progress = 0.0
	unlock_pop_progress = 0.0
	_clear_drop_chain_start_points()
	_clear_drop_chain_start_links()
	lock_offset = Vector2.ZERO
	lock_rotation = 0.0
	_set_padlock_pop_scale(1.0)
	if lock_state == LOCK_STATE_DROPPING:
		lock_state = LOCK_STATE_CLOSED
		_apply_lock_state_visuals()
	_place_padlock(lock_offset, lock_rotation)
	queue_redraw()

func play_unlock_drop_animation() -> void:
	if unlock_drop_tween != null and unlock_drop_tween.is_valid():
		unlock_drop_tween.kill()
	unlock_drop_tween = null
	unlock_drop_active = false
	unlock_drop_progress = 0.0
	unlock_pop_progress = 0.0
	lock_offset = Vector2.ZERO
	lock_rotation = 0.0
	_set_padlock_pop_scale(1.0)
	_capture_drop_chain_start_points()
	set_lock_state(LOCK_STATE_DROPPING)
	unlock_drop_active = true
	click_shake_direction = -1.0 if rng.randf() < 0.5 else 1.0
	_pull_chains_from_lock(Vector2(0.0, -1.0), 36.0)
	_wake_motion_process()
	unlock_drop_tween = create_tween()
	unlock_drop_tween.tween_method(_set_unlock_drop_progress, 0.0, 1.0, UNLOCK_DROP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_unlock_drop_progress(progress: float) -> void:
	unlock_drop_progress = clampf(progress, 0.0, 1.0)
	var elapsed := unlock_drop_progress * UNLOCK_DROP_SECONDS
	unlock_pop_progress = clampf(elapsed / UNLOCK_POP_SECONDS, 0.0, 1.0)
	var fall_progress := _unlock_fall_progress()
	var gravity := fall_progress * fall_progress
	var fallover := smoothstep(0.18, 1.0, fall_progress)
	var settling_wobble := sin(fall_progress * PI * 1.75) * 0.045 * (1.0 - fall_progress)
	var pop_wiggle := _unlock_pop_wiggle()
	lock_offset = Vector2(click_shake_direction * 14.0 * fall_progress + pop_wiggle * 6.0, size.y * 0.46 * gravity - absf(pop_wiggle) * 2.0)
	lock_rotation = (0.78 * click_shake_direction * fallover) + settling_wobble + pop_wiggle * 0.10
	_set_padlock_pop_scale(_unlock_pop_scale())
	_place_padlock(lock_offset, lock_rotation)
	queue_redraw()

func _unlock_fall_progress() -> float:
	var elapsed := unlock_drop_progress * UNLOCK_DROP_SECONDS
	var fall_delay := UNLOCK_POP_SECONDS * 0.72
	var fall_elapsed := maxf(0.0, elapsed - fall_delay)
	return clampf(fall_elapsed / maxf(0.001, UNLOCK_DROP_SECONDS - fall_delay), 0.0, 1.0)

func _build(font: Font, fallback_font: Font) -> void:
	_clear_children()
	padlock_shadow = _padlock_shadow_piece(Color(0, 0, 0, 0.26))
	padlock_shadow.z_index = 4
	add_child(padlock_shadow)
	if _uses_split_padlock():
		padlock = _texture_piece(padlock_body_texture, Color.WHITE)
		padlock_shackle = _texture_piece(padlock_shackle_closed_texture, Color.WHITE)
		padlock_shackle.z_index = 5
		add_child(padlock_shackle)
	else:
		padlock = _padlock_piece(Color.WHITE)
	padlock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padlock.gui_input.connect(_on_padlock_gui_input)
	padlock.z_index = 5
	add_child(padlock)
	if padlock_tint_mask_texture != null:
		padlock_tint = _texture_piece(padlock_tint_mask_texture, _padlock_tint_modulate())
		padlock_tint.z_index = 6
		add_child(padlock_tint)
	level_label = _ActivityLockNumber.new()
	level_label.set_text(str(level))
	level_label.font_size = 206
	level_label.outline_size = 24
	level_label.set_fill_color(_lock_number_fill_color())
	if font != null:
		level_label.font = font
	elif fallback_font != null:
		level_label.font = fallback_font
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.z_index = 7
	add_child(level_label)
	_apply_lock_state_visuals()
	_layout_base()

func _padlock_piece(color: Color) -> TextureRect:
	return _texture_piece(padlock_texture, color)


func _padlock_shadow_piece(color: Color) -> TextureRect:
	return _texture_piece(padlock_body_texture if _uses_split_padlock() else padlock_texture, color)


func _texture_piece(texture: Texture2D, color: Color) -> TextureRect:
	var piece := TextureRect.new()
	piece.texture = texture
	piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece.modulate = color
	return piece


func _padlock_tint_modulate() -> Color:
	var color := theme_color
	color.a = 0.92
	return color


func _lock_number_fill_color() -> Color:
	return Color.WHITE


func _uses_split_padlock() -> bool:
	return padlock_body_texture != null and padlock_shackle_closed_texture != null


func _apply_lock_state_visuals() -> void:
	var lock_visible := lock_state != LOCK_STATE_GONE
	if padlock_shadow != null:
		padlock_shadow.visible = lock_visible and padlock_visible
	if padlock != null:
		padlock.visible = lock_visible and padlock_visible
	if padlock_tint != null:
		padlock_tint.visible = lock_visible and padlock_visible
	if padlock_shackle != null:
		padlock_shackle.visible = lock_visible and padlock_visible
		padlock_shackle.texture = _active_shackle_texture()
	if level_label != null:
		level_label.visible = lock_visible and padlock_visible
	mouse_filter = Control.MOUSE_FILTER_PASS if lock_visible and padlock_visible else Control.MOUSE_FILTER_IGNORE
	if not lock_visible or not padlock_visible:
		pressing_lock = false
		dragging_lock = false
		if not chain_visible:
			set_process(false)
	queue_redraw()


func _play_ready_open_animation() -> void:
	if lock_state != LOCK_STATE_READY_OPEN or not is_inside_tree():
		return
	_stop_ready_open_animation(false)
	ready_open_progress = 0.0
	_pull_chains_from_lock(Vector2(0.0, -1.0), 20.0)
	chain_moved.emit("ready_open", 0.32)
	_wake_motion_process()
	ready_open_tween = create_tween()
	ready_open_tween.tween_method(_set_ready_open_progress, 0.0, 1.0, READY_OPEN_CLINK_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _stop_ready_open_animation(update_visual := true) -> void:
	if ready_open_tween != null and ready_open_tween.is_valid():
		ready_open_tween.kill()
	ready_open_tween = null
	ready_open_progress = 0.0
	if update_visual:
		_place_padlock(lock_offset, lock_rotation)
		queue_redraw()


func _set_ready_open_progress(progress: float) -> void:
	ready_open_progress = clampf(progress, 0.0, 1.0)
	_place_padlock(lock_offset, lock_rotation)
	queue_redraw()


static func cropped_padlock_texture(source: Texture2D) -> Texture2D:
	if source == null:
		return null
	if DisplayServer.get_name() == "headless":
		return _placeholder_texture_for_source(source)
	var source_size := source.get_size()
	if source_size.x <= PADLOCK_SOURCE_CROP_RIGHT + 1.0:
		return source
	var cropped_image := cropped_padlock_hit_image(source)
	if cropped_image == null:
		return source
	return ImageTexture.create_from_image(cropped_image)

static func cropped_padlock_hit_image(source: Texture2D) -> Image:
	if source == null:
		return null
	var image := _image_for_pixel_access(source)
	if image == null:
		return null
	var source_size := source.get_size()
	if source_size.x <= PADLOCK_SOURCE_CROP_RIGHT + 1.0:
		return image
	var crop_width := maxi(1, int(round(source_size.x - PADLOCK_SOURCE_CROP_RIGHT)))
	var crop_height := maxi(1, int(round(source_size.y)))
	return image.get_region(Rect2i(Vector2i.ZERO, Vector2i(crop_width, crop_height)))

static func _image_for_pixel_access(source: Texture2D) -> Image:
	if source == null:
		return null
	var image := source.get_image()
	if image == null or image.is_empty():
		return null
	if image.is_compressed():
		var decompress_error := image.decompress()
		if decompress_error != OK:
			return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image

func _alpha_mask_texture(source: Texture2D) -> Texture2D:
	if source == null:
		return null
	if DisplayServer.get_name() == "headless":
		return _placeholder_texture_for_source(source)
	var image := _image_for_pixel_access(source)
	if image == null:
		return null
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			var alpha := clampf(pixel.a, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


static func _placeholder_texture_for_source(source: Texture2D) -> Texture2D:
	var placeholder := PlaceholderTexture2D.new()
	var source_size := source.get_size() if source != null else Vector2(8, 8)
	placeholder.size = Vector2(maxf(1.0, source_size.x), maxf(1.0, source_size.y))
	return placeholder

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_base()

func _gui_input(event: InputEvent) -> void:
	if pressing_lock or _padlock_contains_local_point(get_local_mouse_position()):
		_on_padlock_gui_input(event)

func handle_pointer_event(event: InputEvent) -> bool:
	if lock_state in [LOCK_STATE_DROPPING, LOCK_STATE_GONE]:
		return false
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

func pointer_over_lock_event(event: InputEvent) -> bool:
	if lock_state in [LOCK_STATE_DROPPING, LOCK_STATE_GONE]:
		return false
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	return _padlock_contains_local_point(_event_local_position(event))

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
		set_process(false)
		return
	_process_padlock_hover()
	if unlock_drop_active:
		return
	if pressing_lock and dragging_lock:
		var target := _limit_lock_offset(get_local_mouse_position() - press_position + drag_start_lock_offset)
		var next_offset := lock_offset.lerp(target, 1.0 - exp(-30.0 * delta))
		next_offset = _limit_lock_offset(next_offset)
		lock_velocity = (next_offset - lock_offset) / maxf(delta, 0.001)
		lock_offset = next_offset
		physics_active = true
		_emit_chain_moved_if_ready(false, "drag")
	elif physics_active:
		lock_velocity += -lock_offset * 72.0 * delta
		lock_velocity *= exp(-9.5 * delta)
		var next_offset := _limit_lock_offset(lock_offset + lock_velocity * delta)
		lock_velocity = (next_offset - lock_offset) / maxf(delta, 0.001)
		lock_offset = next_offset
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
	if not unlock_drop_active and not pressing_lock and not dragging_lock and not physics_active and click_shake_remaining <= 0.0:
		set_process(false)

func _process_padlock_hover() -> void:
	if not is_visible_in_tree():
		lock_hovered = false
		return
	var hovered := _padlock_contains_local_point(get_local_mouse_position())
	if hovered and not lock_hovered:
		padlock_hovered.emit()
	lock_hovered = hovered

func _layout_base() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	base_lock_position = Vector2(size.x * 0.5 - PADLOCK_SIZE.x * 0.5 + base_lock_x_shift, 48.0)
	_reset_chain_points(not _drop_motion_should_be_preserved())
	_place_padlock(lock_offset, lock_rotation)
	queue_redraw()


func _drop_motion_should_be_preserved() -> bool:
	return unlock_drop_active or lock_state in [LOCK_STATE_READY_OPEN, LOCK_STATE_DROPPING]

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
		chain_rest_lengths[side] = []
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
	var slack := _chain_slack_amount(side, offset)
	point.y += sin(t * PI) * _chain_target_sag(side, outer_anchor, inner_anchor, slack)
	return point

func _chain_slack_amount(side: int, offset: Vector2) -> float:
	if size.x <= 1.0:
		return 0.0
	var pull_range := maxf(1.0, size.x * CHAIN_SLACK_PULL_RANGE_RATIO)
	return clampf(float(side) * offset.x / pull_range, 0.0, 1.0)

func _chain_target_sag(side: int, outer_anchor: Vector2, inner_anchor: Vector2, slack: float) -> float:
	var visual_sag := size.y * lerpf(0.04, 0.09, slack) + CHAIN_SLACK_SAG_PIXELS * slack
	var rest_length := _chain_total_rest_length(side)
	var chord := outer_anchor.distance_to(inner_anchor)
	if rest_length <= chord + 1.0:
		return visual_sag
	var length_fit := _chain_sag_for_curve_length(outer_anchor, inner_anchor, rest_length)
	return maxf(visual_sag, length_fit)

func _chain_total_rest_length(side: int) -> float:
	var rest_lengths := chain_rest_lengths[side] as Array
	var total := 0.0
	for length_value in rest_lengths:
		total += float(length_value)
	if total > 0.0:
		return total
	var outer_anchor := _outer_chain_anchor(side)
	var inner_anchor := _lock_chain_anchor(side, Vector2.ZERO)
	var neutral_sag := size.y * 0.04
	return _chain_curve_length(outer_anchor, inner_anchor, neutral_sag)

func _chain_sag_for_curve_length(start: Vector2, end: Vector2, target_length: float) -> float:
	var chord := start.distance_to(end)
	if target_length <= chord + 1.0:
		return 0.0
	var high := maxf(32.0, size.y * 0.12)
	while _chain_curve_length(start, end, high) < target_length and high < size.y * 1.5:
		high *= 1.6
	var low := 0.0
	for iteration in range(12):
		var mid := (low + high) * 0.5
		if _chain_curve_length(start, end, mid) < target_length:
			low = mid
		else:
			high = mid
	return high

func _chain_curve_length(start: Vector2, end: Vector2, sag: float) -> float:
	var length := 0.0
	var previous := start
	for sample in range(1, 17):
		var t := float(sample) / 16.0
		var point := start.lerp(end, t)
		point.y += sin(t * PI) * sag
		length += previous.distance_to(point)
		previous = point
	return length

func _outer_chain_anchor(side: int) -> Vector2:
	var margin := LINK_SIZE.x * CHAIN_EDGE_ANCHOR_INSET_RATIO
	return Vector2(margin if side < 0 else size.x - margin, size.y * 0.28)

func _lock_chain_anchor(side: int, offset: Vector2) -> Vector2:
	var ready_lift := _lock_band_open_amount() * READY_OPEN_SHACKLE_LIFT
	var ready_hang := _lock_hang_drop_amount()
	return base_lock_position + offset + Vector2(PADLOCK_SIZE.x * 0.5 + float(side) * PADLOCK_SIZE.x * 0.34, PADLOCK_SIZE.y * 0.34 + ready_hang - ready_lift)

func _simulate_chains(delta: float) -> void:
	var damping := exp(-10.0 * delta)
	var rest_pull := 1.0 - exp(-18.0 * delta)
	for side in [-1, 1]:
		var points := chain_points[side] as Array
		var previous := chain_prev_points[side] as Array
		if points.is_empty():
			continue
		for i in range(points.size()):
			var point := points[i] as Vector2
			var last := previous[i] as Vector2
			var velocity := (point - last) * damping
			previous[i] = point
			point += velocity
			if i > 0 and i < points.size() - 1:
				var target_point := _base_chain_point(side, i, lock_offset)
				var slack := _chain_slack_amount(side, lock_offset)
				var arc_weight := sin(float(i) / float(points.size() - 1) * PI)
				point.y += CHAIN_SLACK_GRAVITY_PIXELS * slack * arc_weight * delta * delta
				point = point.lerp(target_point, rest_pull * lerpf(CHAIN_SLACK_REST_PULL_MIN, CHAIN_SLACK_REST_PULL_MAX, slack))
			points[i] = point
		for pass_index in range(CONSTRAINT_PASSES):
			points[0] = _outer_chain_anchor(side)
			points[points.size() - 1] = _lock_chain_anchor(side, lock_offset)
			_apply_chain_constraints(side)
		points[0] = _outer_chain_anchor(side)
		points[points.size() - 1] = _lock_chain_anchor(side, lock_offset)
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
			a += correction
		else:
			a += correction * 0.5
			b -= correction * 0.5
		points[i] = a
		points[i + 1] = b

func _limit_lock_offset(candidate: Vector2) -> Vector2:
	var limited := candidate
	for pass_index in range(LOCK_CHAIN_LIMIT_PASSES):
		for side in [-1, 1]:
			var outer_anchor := _outer_chain_anchor(side)
			var lock_anchor := _lock_chain_anchor(side, limited)
			var span := lock_anchor - outer_anchor
			var distance := span.length()
			var max_distance := _chain_taut_distance(side)
			if distance <= max_distance:
				continue
			var direction := span / maxf(distance, 0.001)
			var clamped_anchor := outer_anchor + direction * max_distance
			limited += clamped_anchor - lock_anchor
	return limited

func _chain_taut_distance(side: int) -> float:
	var total := _chain_total_rest_length(side)
	return total * LOCK_CHAIN_TAUT_RATIO + LOCK_CHAIN_TAUT_SLACK_PIXELS

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
			_wake_motion_process()
			accept_event()
		elif pressing_lock and not event.pressed:
			if not dragging_lock:
				unlock_success_click_consumed = false
				padlock_clicked.emit()
				if unlock_success_click_consumed:
					unlock_success_click_consumed = false
				else:
					_click_rattle_lock()
			pressing_lock = false
			dragging_lock = false
			physics_active = true
			_wake_motion_process()
			accept_event()
	elif event is InputEventMouseMotion and pressing_lock:
		if dragging_lock or pointer_position.distance_to(press_position) >= LOCK_DRAG_DEADZONE:
			var started_dragging := not dragging_lock
			dragging_lock = true
			physics_active = true
			_wake_motion_process()
			if started_dragging:
				last_chain_sound_offset = lock_offset
				_emit_chain_moved_if_ready(true, "drag_start")
			accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			pressing_lock = true
			dragging_lock = false
			press_position = pointer_position
			drag_start_lock_offset = lock_offset
			physics_active = true
			_wake_motion_process()
			accept_event()
		elif pressing_lock and not event.pressed:
			if not dragging_lock:
				unlock_success_click_consumed = false
				padlock_clicked.emit()
				if unlock_success_click_consumed:
					unlock_success_click_consumed = false
				else:
					_click_rattle_lock()
			pressing_lock = false
			dragging_lock = false
			physics_active = true
			_wake_motion_process()
			accept_event()
	elif event is InputEventScreenDrag and pressing_lock:
		if dragging_lock or pointer_position.distance_to(press_position) >= LOCK_DRAG_DEADZONE:
			var started_dragging := not dragging_lock
			dragging_lock = true
			physics_active = true
			_wake_motion_process()
			if started_dragging:
				last_chain_sound_offset = lock_offset
				_emit_chain_moved_if_ready(true, "drag_start")
			accept_event()

func _emit_chain_moved_if_ready(force := false, kind := "drag") -> void:
	var now := Time.get_ticks_msec()
	if not force and now - last_chain_sound_msec < CHAIN_SFX_COOLDOWN_MSEC:
		return
	if not force and lock_offset.distance_to(last_chain_sound_offset) < CHAIN_SFX_MOVE_DISTANCE:
		return
	last_chain_sound_msec = now
	last_chain_sound_offset = lock_offset
	var intensity := clampf(lock_velocity.length() / 620.0, 0.25, 1.0)
	chain_moved.emit(kind, intensity)

func _click_rattle_lock() -> void:
	click_shake_remaining = LOCK_CLICK_SHAKE_SECONDS
	click_shake_direction = -1.0 if rng.randf() < 0.5 else 1.0
	lock_velocity += Vector2(220.0 * click_shake_direction, rng.randf_range(-60.0, 70.0))
	_pull_chains_from_lock(Vector2(1.0 * click_shake_direction, 0.18), 44.0)
	_emit_chain_moved_if_ready(true, "click")
	physics_active = true
	_wake_motion_process()

func _wake_motion_process() -> void:
	if is_visible_in_tree() and not is_processing():
		set_process(true)

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
	if lock_state == LOCK_STATE_GONE:
		return false
	if padlock == null:
		return false
	var padlock_point := padlock.get_transform().affine_inverse() * point
	if not Rect2(Vector2.ZERO, padlock.size).has_point(padlock_point):
		return false
	if padlock_texture == null or padlock_hit_image == null or padlock_hit_image.is_empty():
		return true
	var texture_size := padlock_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return true
	var fit_scale := minf(padlock.size.x / texture_size.x, padlock.size.y / texture_size.y)
	var drawn_size := texture_size * fit_scale
	var drawn_position := (padlock.size - drawn_size) * 0.5
	var drawn_rect := Rect2(drawn_position, drawn_size)
	if not drawn_rect.has_point(padlock_point):
		return false
	var uv := (padlock_point - drawn_position) / drawn_size
	var sample_x := clampi(int(floor(uv.x * float(padlock_hit_image.get_width()))), 0, padlock_hit_image.get_width() - 1)
	var sample_y := clampi(int(floor(uv.y * float(padlock_hit_image.get_height()))), 0, padlock_hit_image.get_height() - 1)
	return padlock_hit_image.get_pixel(sample_x, sample_y).a >= PADLOCK_HIT_ALPHA_THRESHOLD

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
	if lock_state == LOCK_STATE_GONE or not chain_visible:
		return
	_draw_success_pulse()
	if not custom_chain_path_points.is_empty():
		var render_points := []
		for raw_point in custom_chain_path_points:
			render_points.append((raw_point as Vector2) + lock_offset)
		_draw_chain_with_depth(_chain_render_links_from_points(render_points, 0, custom_chain_render_count))
		return
	if unlock_drop_active and unlock_drop_progress > 0.0:
		for side in [-1, 1]:
			var dropped_links := _dropped_chain_render_links_for_side(side)
			_draw_chain_with_depth(dropped_links)
		return
	for side in [-1, 1]:
		_draw_chain_with_depth(_chain_render_links_for_side(side))

func _draw_success_pulse() -> void:
	if not unlock_drop_active or padlock_pulse_texture == null:
		return
	var pulse_progress := clampf(unlock_drop_progress * UNLOCK_DROP_SECONDS / (UNLOCK_POP_SECONDS * 1.85), 0.0, 1.0)
	if pulse_progress >= 1.0:
		return
	var alpha := pow(1.0 - pulse_progress, 1.35)
	var center := base_lock_position + lock_offset + PADLOCK_SIZE * 0.5
	var base_grow := lerpf(10.0, 72.0, pulse_progress)
	var tint := UNLOCK_SUCCESS_GREEN
	var layers := [
		{"grow": base_grow + 34.0, "alpha": 0.08},
		{"grow": base_grow + 22.0, "alpha": 0.13},
		{"grow": base_grow + 11.0, "alpha": 0.20},
		{"grow": base_grow, "alpha": 0.30},
	]
	for layer in layers:
		var grow := float(layer["grow"])
		var layer_alpha := alpha * float(layer["alpha"])
		var size_out := PADLOCK_SIZE + Vector2(grow * 2.0, grow * 2.0)
		var rect := Rect2(center - size_out * 0.5, size_out)
		draw_texture_rect(padlock_pulse_texture, rect, false, Color(tint.r, tint.g, tint.b, layer_alpha))

func _chain_render_links_for_side(side: int) -> Array:
	var points := chain_points[side] as Array
	if points.is_empty():
		return []
	var render_points := []
	if side > 0:
		for i in range(points.size() - 1, -1, -1):
			render_points.append(points[i])
	else:
		render_points = points.duplicate()
	return _chain_render_links_from_points(render_points, 0 if side < 0 else 100)

func _chain_render_links_from_points(points: Array, first_index := 0, point_count := 0) -> Array:
	var render_links := []
	var render_points := _chain_evenly_spaced_points(points, point_count if point_count > 0 else points.size())
	for i in range(render_points.size()):
		var previous_index := maxi(i - 1, 0)
		var next_index := mini(i + 1, render_points.size() - 1)
		var previous_point := render_points[previous_index] as Vector2
		var next_point := render_points[next_index] as Vector2
		var tangent := next_point - previous_point
		var link_rotation := _chain_link_rotation(tangent)
		var weave := -1.0 if i % 2 == 0 else 1.0
		link_rotation += weave * 0.02
		var link_index := first_index + i
		render_links.append({
			"center": render_points[i] as Vector2,
			"rotation": link_rotation,
			"size": LINK_SIZE,
			"index": link_index,
			"front_side": 1 if link_index % 2 == 0 else -1
		})
	return render_links

func _chain_evenly_spaced_points(points: Array, point_count: int) -> Array:
	if point_count <= 2 or points.size() <= 2:
		return points.duplicate()
	var segment_lengths := []
	var total_length := 0.0
	for i in range(points.size() - 1):
		var length := (points[i] as Vector2).distance_to(points[i + 1] as Vector2)
		segment_lengths.append(length)
		total_length += length
	if total_length <= 0.001:
		return points.duplicate()
	var spaced := []
	var segment_index := 0
	var segment_start_length := 0.0
	for i in range(point_count):
		var target_length := total_length * float(i) / float(point_count - 1)
		while segment_index < segment_lengths.size() - 1 and segment_start_length + float(segment_lengths[segment_index]) < target_length:
			segment_start_length += float(segment_lengths[segment_index])
			segment_index += 1
		var segment_length := maxf(float(segment_lengths[segment_index]), 0.001)
		var local_t := clampf((target_length - segment_start_length) / segment_length, 0.0, 1.0)
		spaced.append((points[segment_index] as Vector2).lerp(points[segment_index + 1] as Vector2, local_t))
	return spaced

func _chain_link_rotation(tangent: Vector2) -> float:
	var link_rotation := atan2(tangent.y, tangent.x)
	if link_rotation > PI * 0.5:
		link_rotation -= PI
	elif link_rotation < -PI * 0.5:
		link_rotation += PI
	return clampf(link_rotation, -0.24, 0.24)

func _dropped_chain_path_points(side: int) -> Array:
	var points := []
	var drop_progress := clampf(unlock_drop_progress * 1.25, 0.0, 1.0)
	var drop := drop_progress * drop_progress
	var rest := smoothstep(0.68, 1.0, drop_progress)
	var outer_anchor := _outer_chain_anchor(side)
	var inner_start := _lock_chain_anchor(side, Vector2.ZERO)
	var ground_y := size.y * 0.91
	var inner_ground := Vector2(size.x * 0.5 + float(side) * LINK_SIZE.x * 0.62, ground_y)
	var inner_anchor := inner_start.lerp(inner_ground, drop)
	for i in range(LINKS_PER_SIDE):
		var t := float(i) / float(maxi(1, LINKS_PER_SIDE - 1))
		var point := outer_anchor.lerp(inner_anchor, t)
		point.y += sin(t * PI) * (size.y * 0.07 + drop * size.y * 0.16)
		if t > 0.38:
			var laid_y := ground_y - sin((1.0 - t) * PI) * 22.0
			point.y = lerpf(point.y, laid_y, rest)
		points.append(point)
	var start_points := drop_chain_start_points.get(side, []) as Array
	if start_points.size() == points.size():
		var blend := smoothstep(0.0, DROP_CHAIN_CAPTURE_BLEND_END, drop_progress)
		for i in range(points.size()):
			points[i] = (start_points[i] as Vector2).lerp(points[i] as Vector2, blend)
	return points


func _dropped_chain_render_points_for_side(side: int) -> Array:
	var points := _dropped_chain_path_points(side)
	if side <= 0:
		return points
	var render_points := []
	for i in range(points.size() - 1, -1, -1):
		render_points.append(points[i] as Vector2)
	return render_points


func _dropped_chain_render_links_for_side(side: int) -> Array:
	var target_links := _chain_render_links_from_points(_dropped_chain_render_points_for_side(side), 100 if side > 0 else 0)
	var start_links := drop_chain_start_links.get(side, []) as Array
	if start_links.size() != target_links.size():
		return target_links
	var blend := smoothstep(0.0, DROP_CHAIN_CAPTURE_BLEND_END, clampf(unlock_drop_progress * 1.25, 0.0, 1.0))
	for i in range(target_links.size()):
		var start_link := start_links[i] as Dictionary
		var target_link := target_links[i] as Dictionary
		target_link["center"] = (start_link.get("center", target_link.get("center", Vector2.ZERO)) as Vector2).lerp(target_link.get("center", Vector2.ZERO) as Vector2, blend)
		target_link["rotation"] = lerpf(float(start_link.get("rotation", target_link.get("rotation", 0.0))), float(target_link.get("rotation", 0.0)), blend)
		target_links[i] = target_link
	return target_links


func _capture_drop_chain_start_points() -> void:
	for side in [-1, 1]:
		var points := []
		for raw_point in _visible_chain_path_points(side):
			points.append(raw_point as Vector2)
		drop_chain_start_points[side] = points
		var links := []
		for raw_link in _chain_render_links_for_side(side):
			links.append((raw_link as Dictionary).duplicate(true))
		drop_chain_start_links[side] = links


func _clear_drop_chain_start_points() -> void:
	drop_chain_start_points[-1] = []
	drop_chain_start_points[1] = []


func _clear_drop_chain_start_links() -> void:
	drop_chain_start_links[-1] = []
	drop_chain_start_links[1] = []


func _visible_chain_path_points(side: int) -> Array:
	var points := chain_points[side] as Array
	if points.is_empty():
		return []
	var render_points := []
	for raw_point in points:
		render_points.append(raw_point as Vector2)
	return render_points

func _draw_chain_with_depth(render_links: Array) -> void:
	for layer in _chain_shadow_layers():
		_draw_interlocked_chain(render_links, 0, layer["tint"] as Color, layer["offset"] as Vector2, layer["inflate"] as Vector2)
	for offset in _chain_stroke_offsets():
		_draw_interlocked_chain(render_links, 0, CHAIN_STROKE_TINT, offset, Vector2.ZERO)
	_draw_interlocked_chain_metal(render_links)

func _chain_shadow_layers() -> Array:
	return [
		{"offset": CHAIN_SHADOW_OFFSET + Vector2(0, 7), "inflate": Vector2(20, 20), "tint": Color(0, 0, 0, 0.045)},
		{"offset": CHAIN_SHADOW_OFFSET + Vector2(0, 3), "inflate": Vector2(12, 12), "tint": Color(0, 0, 0, 0.075)},
		{"offset": CHAIN_SHADOW_OFFSET, "inflate": Vector2(6, 6), "tint": Color(0, 0, 0, 0.09)},
	]

func _chain_stroke_offsets() -> Array:
	var stroke := 8.0
	return [
		Vector2(-stroke, 0),
		Vector2(stroke, 0),
		Vector2(0, -stroke),
		Vector2(0, stroke),
		Vector2(-stroke * 0.72, -stroke * 0.72),
		Vector2(stroke * 0.72, -stroke * 0.72),
		Vector2(-stroke * 0.72, stroke * 0.72),
		Vector2(stroke * 0.72, stroke * 0.72),
	]

func _draw_interlocked_chain(render_links: Array, index := 0, fill_override := Color.TRANSPARENT, center_offset := Vector2.ZERO, size_inflate := Vector2.ZERO) -> void:
	if index >= render_links.size():
		return
	var link := render_links[index] as Dictionary
	_draw_link_half(link, false, _link_front_side(link), fill_override, true, center_offset, size_inflate)
	_draw_interlocked_chain(render_links, index + 1, fill_override, center_offset, size_inflate)
	_draw_link_half(link, true, _link_front_side(link), fill_override, true, center_offset, size_inflate)

func _draw_interlocked_chain_metal(render_links: Array, index := 0) -> void:
	if index >= render_links.size():
		return
	var link := render_links[index] as Dictionary
	var front_side := _link_front_side(link)
	_draw_link_half(link, false, front_side, CHAIN_METAL_TINT)
	_draw_link_half_shade(link, false, front_side)
	_draw_interlocked_chain_metal(render_links, index + 1)
	_draw_link_half(link, true, front_side, CHAIN_METAL_TINT)
	_draw_link_half_shade(link, true, front_side)

func _link_front_side(link: Dictionary) -> int:
	return int(link.get("front_side", 1))

func _draw_link_half(link: Dictionary, front: bool, front_side := 1, fill_override := Color.TRANSPARENT, _draw_detail := true, center_offset := Vector2.ZERO, size_inflate := Vector2.ZERO) -> void:
	if link_texture != null:
		_draw_textured_link_half(link, front, front_side, fill_override, center_offset, size_inflate)
		return
	var center := (link["center"] as Vector2) + center_offset
	var link_rotation := float(link["rotation"])
	var link_size := (link["size"] as Vector2) + size_inflate
	var rx := link_size.x * 0.5
	var ry := link_size.y * 0.5
	var metal := link_size.y * 0.30
	var inner_rx := rx - metal
	var inner_ry := ry - metal
	var draw_right_side := front == (front_side > 0)
	var start_angle := -PI * 0.5 if draw_right_side else PI * 0.5
	var end_angle := PI * 0.5 if draw_right_side else PI * 1.5
	var outer := _ellipse_points(center, link_rotation, rx, ry, start_angle, end_angle, 18)
	var inner := _ellipse_points(center, link_rotation, inner_rx, inner_ry, end_angle, start_angle, 18)
	var polygon := PackedVector2Array()
	for point in outer:
		polygon.append(point)
	for point in inner:
		polygon.append(point)
	var fill := fill_override if fill_override.a > 0.0 else CHAIN_METAL_TINT
	draw_colored_polygon(polygon, fill)

func _draw_link_half_shade(link: Dictionary, front: bool, front_side := 1) -> void:
	if link_texture != null:
		_draw_textured_link_half_shade(link, front, front_side)
		return
	_draw_link_half(link, front, front_side, CHAIN_LINK_SHADE_TINT, true, Vector2(0, LINK_SIZE.y * 0.08), Vector2.ZERO)

func _draw_textured_link_half(link: Dictionary, front: bool, front_side := 1, fill_override := Color.TRANSPARENT, center_offset := Vector2.ZERO, size_inflate := Vector2.ZERO) -> void:
	var center := (link["center"] as Vector2) + center_offset
	var link_rotation := float(link["rotation"])
	var link_size := (link["size"] as Vector2) + size_inflate
	var texture_size := link_texture.get_size()
	var half_width := texture_size.x * 0.5
	var draw_right_side := front == (front_side > 0)
	var source_x := half_width if draw_right_side else 0.0
	var dest_x := 0.0 if draw_right_side else -link_size.x * 0.5
	var tint := fill_override if fill_override.a > 0.0 else CHAIN_METAL_TINT
	draw_set_transform(center, link_rotation, Vector2.ONE)
	draw_texture_rect_region(
		link_texture,
		Rect2(Vector2(dest_x, -link_size.y * 0.5), Vector2(link_size.x * 0.5, link_size.y)),
		Rect2(Vector2(source_x, 0), Vector2(half_width, texture_size.y)),
		tint
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_textured_link_half_shade(link: Dictionary, front: bool, front_side := 1) -> void:
	var center := link["center"] as Vector2
	var link_rotation := float(link["rotation"])
	var link_size := link["size"] as Vector2
	var texture_size := link_texture.get_size()
	var half_width := texture_size.x * 0.5
	var draw_right_side := front == (front_side > 0)
	var source_x := half_width if draw_right_side else 0.0
	var dest_x := 0.0 if draw_right_side else -link_size.x * 0.5
	var shade_y := clampf(CHAIN_LINK_SHADE_START, 0.0, 0.95)
	var source_y := texture_size.y * shade_y
	var dest_y := -link_size.y * 0.5 + link_size.y * shade_y
	var source_height := texture_size.y - source_y
	var dest_height := link_size.y * (1.0 - shade_y)
	draw_set_transform(center, link_rotation, Vector2.ONE)
	draw_texture_rect_region(
		link_texture,
		Rect2(Vector2(dest_x, dest_y), Vector2(link_size.x * 0.5, dest_height)),
		Rect2(Vector2(source_x, source_y), Vector2(half_width, source_height)),
		CHAIN_LINK_SHADE_TINT
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _ellipse_points(center: Vector2, link_rotation: float, rx: float, ry: float, start_angle: float, end_angle: float, steps: int) -> Array:
	var points := []
	var basis_x := Vector2(cos(link_rotation), sin(link_rotation))
	var basis_y := Vector2(-sin(link_rotation), cos(link_rotation))
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var angle := lerpf(start_angle, end_angle, t)
		var local := basis_x * (cos(angle) * rx) + basis_y * (sin(angle) * ry)
		points.append(center + local)
	return points

func _place_padlock(offset: Vector2, next_lock_rotation: float) -> void:
	var lock_position := base_lock_position + offset + Vector2(0.0, _lock_hang_drop_amount())
	var pop_scale := _unlock_pop_scale()
	var open_amount := _lock_band_open_amount()
	var ready_pop := sin(ready_open_progress * PI)
	var ready_settle := sin(ready_open_progress * TAU * 1.6) * (1.0 - ready_open_progress)
	var shackle_slide := Vector2(0.0, -open_amount * READY_OPEN_SHACKLE_LIFT - ready_pop * 4.0)
	var shared_rotation := next_lock_rotation + open_amount * READY_OPEN_HANG_ROTATION + ready_settle * 0.012
	var shared_pivot := PADLOCK_SIZE * 0.5
	if open_amount > 0.0:
		shared_pivot = Vector2(PADLOCK_SIZE.x * 0.5, PADLOCK_SIZE.y * 0.25)
	if padlock_shadow != null:
		padlock_shadow.size = PADLOCK_SIZE
		padlock_shadow.position = lock_position + PADLOCK_SHADOW_OFFSET
		padlock_shadow.pivot_offset = shared_pivot
		padlock_shadow.rotation = shared_rotation
		padlock_shadow.scale = Vector2.ONE * lerpf(1.0, pop_scale, 0.55)
	if padlock != null:
		padlock.size = PADLOCK_SIZE
		padlock.position = lock_position
		padlock.pivot_offset = shared_pivot
		padlock.rotation = shared_rotation
		padlock.scale = Vector2.ONE * pop_scale
	if padlock_shackle != null:
		var ready_scale := 1.0 + ready_pop * 0.035
		padlock_shackle.texture = _active_shackle_texture()
		padlock_shackle.size = PADLOCK_SIZE
		padlock_shackle.position = lock_position + shackle_slide
		padlock_shackle.pivot_offset = shared_pivot - shackle_slide
		padlock_shackle.rotation = shared_rotation
		padlock_shackle.scale = Vector2.ONE * pop_scale * ready_scale
	if padlock_tint != null:
		padlock_tint.size = PADLOCK_SIZE
		padlock_tint.position = lock_position
		padlock_tint.pivot_offset = shared_pivot
		padlock_tint.rotation = shared_rotation
		padlock_tint.scale = Vector2.ONE * pop_scale
	if level_label != null:
		level_label.size = Vector2(240, 210)
		level_label.position = lock_position + Vector2(PADLOCK_SIZE.x * 0.5 - level_label.size.x * 0.5 - 15.0, PADLOCK_SIZE.y * 0.52)
		level_label.pivot_offset = shared_pivot - (level_label.position - lock_position)
		level_label.rotation = shared_rotation
		level_label.scale = Vector2.ONE * pop_scale

func _unlock_pop_scale() -> float:
	if not unlock_drop_active:
		return 1.0
	if unlock_pop_progress >= 1.0:
		return 1.0
	var pop := pow(1.0 - unlock_pop_progress, 1.35) * 0.14
	var settle := sin(unlock_pop_progress * PI) * 0.018
	return 1.0 + pop - settle


func _lock_band_open_amount() -> float:
	if lock_state == LOCK_STATE_DROPPING:
		return 1.0
	if lock_state != LOCK_STATE_READY_OPEN:
		return 0.0
	var progress := clampf(ready_open_progress, 0.0, 1.0)
	return progress * progress * (3.0 - 2.0 * progress)


func _lock_hang_drop_amount() -> float:
	return _lock_band_open_amount() * READY_OPEN_HANG_DROP


func _active_shackle_texture() -> Texture2D:
	if padlock_shackle_open_texture != null and lock_state in [LOCK_STATE_READY_OPEN, LOCK_STATE_DROPPING]:
		return padlock_shackle_open_texture
	return padlock_shackle_closed_texture

func _unlock_pop_wiggle() -> float:
	if not unlock_drop_active or unlock_pop_progress >= 1.0:
		return 0.0
	var damping := pow(1.0 - unlock_pop_progress, 1.55)
	var wave := cos(unlock_pop_progress * TAU * 1.65)
	return wave * damping * click_shake_direction * 0.58

func _set_padlock_pop_scale(next_scale: float) -> void:
	if padlock_shadow != null:
		padlock_shadow.scale = Vector2.ONE * lerpf(1.0, next_scale, 0.55)
	if padlock != null:
		padlock.scale = Vector2.ONE * next_scale
	if padlock_shackle != null:
		padlock_shackle.scale = Vector2.ONE * next_scale
	if padlock_tint != null:
		padlock_tint.scale = Vector2.ONE * next_scale
	if level_label != null:
		level_label.scale = Vector2.ONE * next_scale

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


