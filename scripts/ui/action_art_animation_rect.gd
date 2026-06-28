class_name ActionArtAnimationRect
extends ActionArtTextureRect


var atlas_texture: Texture2D
var frame_textures: Array[Texture2D] = []
var frame_sequence: Array[int] = []
var frame_durations: Array[float] = []
var sequence_index := 0
var frame_elapsed := 0.0
var animation_playing := false
var progress_synced := false
var effect_name := ""
var effect_elapsed := 0.0
var effect_colors: Array[Color] = []
var effect_scenario_palettes: Array[Array] = []
var effect_cycle_seconds := 1.15
var effect_paint_seconds := 0.70
var effect_hold_seconds := 0.55
var effect_splash_visible := false
var effect_last_progress := 0.0
var effect_random_scenario := false
var effect_scenario_index := 0


func _ready() -> void:
	super._ready()
	set_process(false)


func configure_animation(source_texture: Texture2D, frame_count: int, cell_size: Vector2, sequence: Array, durations: Array, sync_mode := "", effects := {}) -> void:
	atlas_texture = source_texture
	frame_textures.clear()
	frame_sequence.clear()
	frame_durations.clear()
	sequence_index = 0
	frame_elapsed = 0.0
	effect_elapsed = 0.0
	effect_last_progress = 0.0
	effect_scenario_index = 0
	progress_synced = sync_mode == "progress"
	_configure_effects(effects)
	if atlas_texture == null or frame_count <= 0 or cell_size.x <= 0.0 or cell_size.y <= 0.0:
		if effect_name.is_empty():
			set_playing(false)
		return
	for frame_index in range(frame_count):
		var frame := AtlasTexture.new()
		frame.atlas = atlas_texture
		frame.region = Rect2(Vector2(float(frame_index) * cell_size.x, 0.0), cell_size)
		frame.filter_clip = true
		frame_textures.append(frame)
	for raw_index in sequence:
		var clamped_index := clampi(int(raw_index), 0, frame_textures.size() - 1)
		frame_sequence.append(clamped_index)
	if frame_sequence.is_empty():
		for frame_index in range(frame_textures.size()):
			frame_sequence.append(frame_index)
	for raw_duration in durations:
		frame_durations.append(maxf(0.016, float(raw_duration)))
	while frame_durations.size() < frame_sequence.size():
		frame_durations.append(0.1)
	_apply_sequence_frame(0)


func _configure_effects(effects: Variant) -> void:
	effect_name = ""
	effect_colors.clear()
	effect_scenario_palettes.clear()
	effect_cycle_seconds = 1.15
	effect_paint_seconds = 0.70
	effect_hold_seconds = 0.55
	effect_splash_visible = false
	effect_random_scenario = false
	if typeof(effects) != TYPE_DICTIONARY:
		set_paint_recolor_effect(false)
		return
	var source := effects as Dictionary
	effect_name = str(source.get("name", ""))
	effect_splash_visible = bool(source.get("splash", source.get("brush", false)))
	effect_random_scenario = bool(source.get("random_scenario", false))
	effect_cycle_seconds = maxf(0.25, float(source.get("cycle_seconds", 1.15)))
	effect_paint_seconds = maxf(0.08, float(source.get("paint_seconds", 0.70)))
	effect_hold_seconds = maxf(0.08, float(source.get("hold_seconds", 0.55)))
	for raw_color in source.get("colors", []):
		var color := Color(str(raw_color))
		if color.a > 0.0:
			effect_colors.append(color)
	if effect_colors.is_empty():
		effect_colors = [Color("#e8e1d4"), Color("#cdbb9d"), Color("#a97958"), Color("#7b6b55")]
	if typeof(source.get("scenario_palettes", [])) == TYPE_ARRAY:
		for raw_palette in source.get("scenario_palettes", []):
			var palette: Array[Color] = []
			if typeof(raw_palette) == TYPE_ARRAY:
				for raw_color in raw_palette:
					var color := Color(str(raw_color))
					if color.a > 0.0:
						palette.append(color)
			if not palette.is_empty():
				while palette.size() < 4:
					palette.append(palette[palette.size() - 1])
				effect_scenario_palettes.append(palette)
	set_paint_recolor_effect(effect_name == "paint_recolor")
	set_paint_recolor_palette(_current_effect_palette())
	_apply_effect_state(0.0)


func set_playing(next_playing: bool) -> void:
	if animation_playing == next_playing:
		return
	animation_playing = next_playing
	if animation_playing and effect_random_scenario and not frame_textures.is_empty():
		effect_scenario_index = randi() % frame_textures.size()
		_apply_scenario_frame(effect_scenario_index)
		_apply_effect_state(0.0)
	if not animation_playing:
		sequence_index = 0
		frame_elapsed = 0.0
		effect_elapsed = 0.0
		effect_last_progress = 0.0
		effect_scenario_index = 0
		_apply_sequence_frame(0)
		_apply_effect_state(0.0)
	queue_redraw()
	set_process(animation_playing and (not progress_synced or not effect_name.is_empty()))


func set_action_progress(progress: float) -> void:
	if not progress_synced or not animation_playing:
		return
	effect_last_progress = clampf(progress, 0.0, 1.0)
	_apply_progress_frame(effect_last_progress)
	_apply_effect_state(effect_last_progress)
	queue_redraw()


func _process(delta: float) -> void:
	if not animation_playing:
		return
	var safe_delta := maxf(0.0, delta)
	effect_elapsed += safe_delta
	if not frame_sequence.is_empty() and not frame_textures.is_empty() and not progress_synced and not effect_random_scenario:
		frame_elapsed += safe_delta
		var guard := 0
		while guard < 12 and frame_elapsed >= _current_duration():
			frame_elapsed -= _current_duration()
			sequence_index = (sequence_index + 1) % frame_sequence.size()
			_apply_sequence_frame(sequence_index)
			guard += 1
	if not effect_name.is_empty():
		_apply_effect_state(_stepped_paint_progress())
		queue_redraw()


func _current_duration() -> float:
	if frame_durations.is_empty():
		return 0.1
	return frame_durations[clampi(sequence_index, 0, frame_durations.size() - 1)]


func _apply_sequence_frame(next_sequence_index: int) -> void:
	if frame_sequence.is_empty() or frame_textures.is_empty():
		return
	sequence_index = clampi(next_sequence_index, 0, frame_sequence.size() - 1)
	var frame_index := frame_sequence[sequence_index]
	effect_scenario_index = frame_index
	texture = frame_textures[clampi(frame_index, 0, frame_textures.size() - 1)]


func _apply_scenario_frame(frame_index: int) -> void:
	if frame_textures.is_empty():
		return
	effect_scenario_index = clampi(frame_index, 0, frame_textures.size() - 1)
	sequence_index = _sequence_index_for_frame(effect_scenario_index)
	texture = frame_textures[effect_scenario_index]


func _apply_progress_frame(progress: float) -> void:
	if frame_sequence.is_empty() or frame_textures.is_empty():
		return
	var total_duration := 0.0
	for duration in frame_durations:
		total_duration += maxf(0.016, float(duration))
	if total_duration <= 0.0:
		_apply_sequence_frame(0)
		return
	var target := clampf(progress, 0.0, 1.0) * total_duration
	var elapsed := 0.0
	for index in range(frame_sequence.size()):
		var duration := maxf(0.016, float(frame_durations[clampi(index, 0, frame_durations.size() - 1)]))
		if target <= elapsed + duration or index == frame_sequence.size() - 1:
			_apply_sequence_frame(index)
			return
		elapsed += duration


func _apply_effect_state(progress: float) -> void:
	if effect_name != "paint_recolor":
		return
	if effect_scenario_palettes.is_empty():
		var from_color := _effect_from_color_for_step()
		var to_color := _effect_color_for_step()
		set_paint_recolor_palette([to_color, to_color, to_color, to_color])
		set_paint_recolor_detail_mode(-1)
		set_paint_recolor_transition_state(progress, from_color, to_color)
		return
	var palette := _current_effect_palette()
	set_paint_recolor_palette(palette)
	set_paint_recolor_detail_mode(effect_scenario_index)
	set_paint_recolor_state(progress, palette[0] if not palette.is_empty() else Color.WHITE)


func _current_effect_palette() -> Array[Color]:
	if effect_scenario_palettes.is_empty():
		return effect_colors
	var index := clampi(effect_scenario_index, 0, effect_scenario_palettes.size() - 1)
	return effect_scenario_palettes[index] as Array[Color]


func _sequence_index_for_frame(frame_index: int) -> int:
	for index in range(frame_sequence.size()):
		if frame_sequence[index] == frame_index:
			return index
	return clampi(frame_index, 0, maxi(0, frame_sequence.size() - 1))


func _effect_color_for_step() -> Color:
	if effect_colors.is_empty():
		return Color.WHITE
	var cycle_length := effect_paint_seconds + effect_hold_seconds
	var index := int(floor(effect_elapsed / cycle_length)) % effect_colors.size()
	return effect_colors[index]


func _effect_from_color_for_step() -> Color:
	if effect_colors.is_empty():
		return Color.WHITE
	var cycle_length := effect_paint_seconds + effect_hold_seconds
	var index := int(floor(effect_elapsed / cycle_length)) % effect_colors.size()
	if index <= 0:
		return Color("#169df2")
	return effect_colors[index - 1]


func _stepped_paint_progress() -> float:
	var cycle_length := effect_paint_seconds + effect_hold_seconds
	if cycle_length <= 0.0:
		return 1.0
	var local_elapsed := fposmod(effect_elapsed, cycle_length)
	if local_elapsed <= effect_paint_seconds:
		var t := clampf(local_elapsed / effect_paint_seconds, 0.0, 1.0)
		return t * t * (3.0 - 2.0 * t)
	return 1.0


func _draw() -> void:
	if not animation_playing or effect_name != "paint_recolor" or not effect_splash_visible:
		return
	var progress := _stepped_paint_progress()
	var palette := _current_effect_palette()
	var color := palette[0] if not palette.is_empty() else _effect_color_for_step()
	var sweep_y := lerpf(size.y * 0.14, size.y * 0.82, progress)
	var wobble := sin(effect_elapsed * TAU * 1.4) * size.x * 0.035
	var splash_center := Vector2(size.x * 0.60 + wobble + progress * size.x * 0.10, sweep_y)
	var sweep_color := color
	sweep_color.a = 0.32
	draw_line(
		splash_center + Vector2(-size.x * 0.10, size.y * 0.025),
		splash_center + Vector2(size.x * 0.10, -size.y * 0.030),
		sweep_color,
		maxf(5.0, size.x * 0.022),
		true
	)
	for index in range(5):
		var angle := effect_elapsed * TAU * 0.9 + float(index) * 1.7
		var offset := Vector2(cos(angle), sin(angle * 1.23)) * (size.x * (0.055 + float(index) * 0.010))
		var splash_color := color
		splash_color.a = 0.62 - float(index) * 0.08
		draw_circle(splash_center + offset, maxf(2.0, size.x * (0.012 - float(index) * 0.0015)), splash_color)
