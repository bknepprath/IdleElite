class ActionArtTextureRect:
	extends TextureRect



	static var shared_mask_shader: Shader

	var use_mask_material := false
	var radius := 56.0
	var mask_shader_params_initialized := false
	var mask_shader_params_size := Vector2(-1.0, -1.0)
	var mask_shader_params_radius := -1.0
	var paint_effect_enabled := false
	var paint_effect_progress := 0.0
	var paint_effect_color := Color.WHITE
	var paint_effect_from_color := Color.WHITE
	var paint_effect_color_secondary := Color.WHITE
	var paint_effect_color_shadow := Color.WHITE
	var paint_effect_color_accent := Color.WHITE
	var paint_effect_detail_mode := 0

	func _init() -> void:
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	func _ready() -> void:
		if use_mask_material:
			_ensure_mask_material()

	func _notification(what: int) -> void:
		if use_mask_material and what == NOTIFICATION_RESIZED:
			_update_mask_params()

	func set_mask_material_enabled(enabled: bool) -> void:
		if use_mask_material == enabled:
			return
		use_mask_material = enabled
		mask_shader_params_initialized = false
		if not use_mask_material:
			material = null
			return
		_ensure_mask_material()

	func set_paint_recolor_effect(enabled: bool) -> void:
		if paint_effect_enabled == enabled:
			return
		paint_effect_enabled = enabled
		if paint_effect_enabled:
			use_mask_material = true
			_ensure_mask_material()
		_update_paint_effect_params()

	func set_paint_recolor_state(progress: float, color: Color) -> void:
		paint_effect_progress = clampf(progress, 0.0, 1.0)
		paint_effect_color = color
		_update_paint_effect_params()

	func set_paint_recolor_transition_state(progress: float, from_color: Color, to_color: Color) -> void:
		paint_effect_progress = clampf(progress, 0.0, 1.0)
		paint_effect_from_color = from_color
		paint_effect_color = to_color
		_update_paint_effect_params()

	func set_paint_recolor_palette(colors: Array[Color]) -> void:
		if not colors.is_empty():
			paint_effect_color = colors[0]
		if colors.size() >= 2:
			paint_effect_color_secondary = colors[1]
		else:
			paint_effect_color_secondary = paint_effect_color
		if colors.size() >= 3:
			paint_effect_color_shadow = colors[2]
		else:
			paint_effect_color_shadow = paint_effect_color_secondary
		if colors.size() >= 4:
			paint_effect_color_accent = colors[3]
		else:
			paint_effect_color_accent = paint_effect_color_shadow
		_update_paint_effect_params()

	func set_paint_recolor_detail_mode(detail_mode: int) -> void:
		paint_effect_detail_mode = detail_mode
		_update_paint_effect_params()

	func _ensure_mask_material() -> void:
		if material != null:
			return
		if shared_mask_shader == null:
			shared_mask_shader = Shader.new()
			shared_mask_shader.code = """
	shader_type canvas_item;

	uniform vec2 control_size = vec2(1.0, 1.0);
	uniform float radius_px = 56.0;
	uniform bool paint_recolor_enabled = false;
	uniform float paint_progress = 0.0;
	uniform vec4 paint_color = vec4(1.0, 1.0, 1.0, 1.0);
	uniform vec4 paint_from_color = vec4(1.0, 1.0, 1.0, 1.0);
	uniform vec4 paint_color_secondary = vec4(1.0, 1.0, 1.0, 1.0);
	uniform vec4 paint_color_shadow = vec4(1.0, 1.0, 1.0, 1.0);
	uniform vec4 paint_color_accent = vec4(1.0, 1.0, 1.0, 1.0);
	uniform int paint_detail_mode = 0;

	float camo_noise(vec2 p) {
		return fract(sin(dot(p, vec2(41.23, 19.87))) * 43758.5453);
	}

	void fragment() {
		vec2 p = UV * control_size;
		vec2 half_size = control_size * 0.5;
		float r = min(radius_px, min(half_size.x, half_size.y));
		vec2 q = abs(p - half_size) - (half_size - vec2(r));
		float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
		float alpha = 1.0 - smoothstep(0.0, 1.0, distance);
		vec4 color = texture(TEXTURE, UV) * COLOR;
		if (paint_recolor_enabled) {
			float blue_dominance = color.b - max(color.r, color.g);
			float saturated_blue = smoothstep(0.015, 0.18, blue_dominance) * smoothstep(0.20, 0.48, color.b);
			float stroke_axis = UV.y * 0.86 + UV.x * 0.30;
			float bristle = sin(UV.x * 42.0 + UV.y * 11.0) * 0.030 + sin(UV.x * 91.0 - UV.y * 25.0) * 0.014;
			float stroke_edge = paint_progress * 1.30 - 0.10 + bristle;
			float stroke = smoothstep(stroke_axis - 0.085, stroke_axis + 0.055, stroke_edge);
			float dry_gap = smoothstep(0.66, 0.98, sin(UV.x * 64.0 + UV.y * 37.0 + paint_progress * 5.0) * 0.5 + 0.5);
			float mask = saturated_blue * clamp(stroke - dry_gap * 0.12 * (1.0 - stroke), 0.0, 1.0);
			float floor_band = smoothstep(0.48, 0.78, UV.y);
			float side_band = smoothstep(0.60, 0.86, UV.x) * smoothstep(0.30, 0.62, UV.y);
			float noise_a = camo_noise(floor(UV * vec2(10.0, 14.0)));
			float noise_b = camo_noise(floor((UV + vec2(0.13, 0.31)) * vec2(16.0, 11.0)));
			vec3 target = mix(paint_color.rgb, paint_color_secondary.rgb, floor_band);
			target = mix(target, paint_color_shadow.rgb, side_band * 0.55);
			target = mix(target, paint_color_accent.rgb, smoothstep(0.55, 0.88, noise_a) * 0.24);
			target = mix(target, paint_color_secondary.rgb, smoothstep(0.62, 0.94, noise_b) * floor_band * 0.28);
			float detail = 0.0;
			if (paint_detail_mode < 0) {
				target = paint_color.rgb;
			} else if (paint_detail_mode == 0) {
				detail = smoothstep(0.020, 0.000, abs(fract(UV.y * 7.0 + UV.x * 1.4) - 0.5));
			} else if (paint_detail_mode == 1) {
				detail = smoothstep(0.62, 0.90, noise_a);
			} else if (paint_detail_mode == 2) {
				detail = max(
					smoothstep(0.018, 0.000, abs(fract(UV.y * 8.0) - 0.5)),
					smoothstep(0.018, 0.000, abs(fract(UV.x * 5.0 + floor(UV.y * 8.0) * 0.5) - 0.5))
				);
			} else if (paint_detail_mode == 3) {
				detail = smoothstep(0.97, 0.995, noise_a);
			} else if (paint_detail_mode == 4) {
				detail = smoothstep(0.018, 0.000, abs(fract(UV.y * 6.0 + UV.x * 0.7) - 0.5));
			} else {
				detail = max(
					smoothstep(0.018, 0.000, abs(fract(UV.x * 6.0) - 0.5)),
					smoothstep(0.018, 0.000, abs(fract(UV.y * 6.0) - 0.5))
				);
			}
			target = mix(target, paint_color_accent.rgb, detail * smoothstep(0.52, 0.86, paint_progress) * 0.46);
			vec3 base = mix(color.rgb, paint_from_color.rgb, saturated_blue * 0.985);
			color.rgb = mix(base, target, mask * 0.985);
		}
		color.a *= alpha;
		COLOR = color;
	}
	"""
		var shader_material := ShaderMaterial.new()
		shader_material.shader = shared_mask_shader
		material = shader_material
		_update_mask_params()

	func _update_mask_params() -> void:
		var shader_material := material as ShaderMaterial
		if shader_material == null:
			return
		if (
			mask_shader_params_initialized
			and mask_shader_params_size.is_equal_approx(size)
			and absf(mask_shader_params_radius - radius) <= 0.001
		):
			return
		shader_material.set_shader_parameter("control_size", size)
		shader_material.set_shader_parameter("radius_px", radius)
		mask_shader_params_initialized = true
		mask_shader_params_size = size
		mask_shader_params_radius = radius
		_update_paint_effect_params()

	func _update_paint_effect_params() -> void:
		var shader_material := material as ShaderMaterial
		if shader_material == null:
			return
		shader_material.set_shader_parameter("paint_recolor_enabled", paint_effect_enabled)
		shader_material.set_shader_parameter("paint_progress", paint_effect_progress)
		shader_material.set_shader_parameter("paint_color", paint_effect_color)
		shader_material.set_shader_parameter("paint_from_color", paint_effect_from_color)
		shader_material.set_shader_parameter("paint_color_secondary", paint_effect_color_secondary)
		shader_material.set_shader_parameter("paint_color_shadow", paint_effect_color_shadow)
		shader_material.set_shader_parameter("paint_color_accent", paint_effect_color_accent)
		shader_material.set_shader_parameter("paint_detail_mode", paint_effect_detail_mode)

class ActionArtAnimationRect:
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

const EVENT_HOURGLASS_BADGE := "res://assets/content/ui/event-hourglass-badge.png"
const ACTION_ART_PANEL_SIZE := Vector2(410, 410)
const ACTION_ART_SIZE := Vector2(427.2, 427.2)
const ACTION_ART_OFFSET := Vector2(-8.6, -8.6)
const ACTION_ART_CORNER_ICON_SIZE := Vector2(172, 172)
const ACTION_ART_CORNER_ICON_EDGE_OVERLAP := 60.0
const ACTION_ART_CORNER_ICON_LIST_STEP := 104.0
const ACTION_ART_CORNER_ICON_STROKE_PIXELS := 14.0

static func image(action: Dictionary, texture_or_fallback: Callable, visual_fallback: Callable, headless: bool) -> ActionArtTextureRect:
	var path := str(action.get("art", ""))
	var animation := action.get("art_animation", {}) as Dictionary
	var node: ActionArtTextureRect = ActionArtAnimationRect.new() if not animation.is_empty() else ActionArtTextureRect.new()
	if headless:
		node.texture = visual_fallback.call()
		node.set_mask_material_enabled(false)
	else:
		node.texture = texture_or_fallback.call(path)
		node.set_mask_material_enabled(needs_texture_mask(path))
		if node is ActionArtAnimationRect:
			var animated_node := node as ActionArtAnimationRect
			var cell_size := Vector2(
				float(animation.get("cell_width", 256.0)),
				float(animation.get("cell_height", 256.0))
			)
			animated_node.configure_animation(
				texture_or_fallback.call(str(animation.get("atlas", ""))),
				int(animation.get("frame_count", 1)),
				cell_size,
				animation.get("sequence", []) as Array,
				animation.get("durations", []) as Array,
				str(animation.get("sync", "")),
				animation.get("effects", {})
			)
	var art_size := display_size(action)
	node.custom_minimum_size = art_size
	node.size = art_size
	node.position = display_offset(action)
	node.radius = 56.0
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = 1
	return node


static func add_corner_badges(art_panel: Control, resource_icon_paths: Array, special_type_icon_path: String, texture_or_fallback: Callable) -> void:
	if art_panel == null or not is_instance_valid(art_panel):
		return
	art_panel.clip_contents = false
	for index in resource_icon_paths.size():
		art_panel.add_child(corner_badge(str(resource_icon_paths[index]), false, index, texture_or_fallback))
	if not special_type_icon_path.is_empty():
		art_panel.add_child(corner_badge(special_type_icon_path, true, 0, texture_or_fallback))


static func corner_badge(icon_path: String, align_right: bool, index: int, texture_or_fallback: Callable) -> Control:
	var host := Control.new()
	host.custom_minimum_size = ACTION_ART_CORNER_ICON_SIZE
	host.size = ACTION_ART_CORNER_ICON_SIZE
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 30 + index
	var x := ACTION_ART_PANEL_SIZE.x - ACTION_ART_CORNER_ICON_SIZE.x + ACTION_ART_CORNER_ICON_EDGE_OVERLAP if align_right else -ACTION_ART_CORNER_ICON_EDGE_OVERLAP + ACTION_ART_CORNER_ICON_LIST_STEP * index
	host.position = Vector2(x, ACTION_ART_PANEL_SIZE.y - ACTION_ART_CORNER_ICON_SIZE.y + ACTION_ART_CORNER_ICON_EDGE_OVERLAP)

	var stroke := TextureRect.new()
	stroke.texture = texture_or_fallback.call(icon_path)
	stroke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stroke.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stroke.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stroke.size = ACTION_ART_CORNER_ICON_SIZE + Vector2(ACTION_ART_CORNER_ICON_STROKE_PIXELS, ACTION_ART_CORNER_ICON_STROKE_PIXELS)
	stroke.position = Vector2(-ACTION_ART_CORNER_ICON_STROKE_PIXELS, -ACTION_ART_CORNER_ICON_STROKE_PIXELS) * 0.5
	stroke.modulate = Color(0.05, 0.035, 0.02, 0.9)
	stroke.z_index = 0
	host.add_child(stroke)

	var icon := TextureRect.new()
	icon.texture = texture_or_fallback.call(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = ACTION_ART_CORNER_ICON_SIZE
	icon.size = ACTION_ART_CORNER_ICON_SIZE
	icon.z_index = 1
	host.add_child(icon)
	return host


static func resource_icon_paths(action: Dictionary, action_mat_reward_defs: Callable, mat_icon_path: Callable, temporary_event_log_reward_mat_id: Callable) -> Array:
	var icon_paths := []
	var mat_rewards := action_mat_reward_defs.call(action) as Array
	for raw_reward in mat_rewards:
		var reward := raw_reward as Dictionary
		var icon_path := str(mat_icon_path.call(str(reward.get("id", ""))))
		if not icon_path.is_empty() and not icon_paths.has(icon_path):
			icon_paths.append(icon_path)
	if not icon_paths.is_empty():
		return icon_paths
	var raw_resource_rewards = action.get("resource_rewards", {})
	if typeof(raw_resource_rewards) != TYPE_DICTIONARY:
		return icon_paths
	var resource_rewards := raw_resource_rewards as Dictionary
	if int(resource_rewards.get("logs_max", resource_rewards.get("logs_min", resource_rewards.get("logs", 0)))) > 0:
		icon_paths.append(str(mat_icon_path.call(str(temporary_event_log_reward_mat_id.call()))))
	return icon_paths


static func special_type_icon_path(action: Dictionary, is_event_action: Callable) -> String:
	if bool(is_event_action.call(action)):
		return EVENT_HOURGLASS_BADGE
	return ""


static func display_size(action: Dictionary) -> Vector2:
	return ACTION_ART_SIZE


static func display_offset(action: Dictionary) -> Vector2:
	return ACTION_ART_OFFSET


static func border_overlay(style: StyleBox) -> Panel:
	var border := Panel.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = 20
	border.add_theme_stylebox_override("panel", style)
	return border


static func needs_texture_mask(path: String) -> bool:
	return path.to_lower().contains("/backgrounds/")
