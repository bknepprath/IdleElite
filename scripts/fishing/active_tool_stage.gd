extends Control

# One authored canvas for every tool, scaled only to the available layout.
const TOOL_DRAW_BOX := Vector2(200, 200)
const REFERENCE_SIZE := Vector2(248, 260)
const ENTRY_SECONDS := 0.44
const LOCATION_ENTRY_SECONDS := 0.58
const MANUAL_HAUL_SECONDS := 0.58
const ROD_PARTS = preload("res://assets/content/fishing/tools/rod-animation-parts.png")
const SplashFrames = preload("res://assets/content/fishing/tools/splash-crescent.png")
const FluidStrip = preload("res://scripts/fishing/fluid_strip.gd")
const WaterSurface = preload("res://scripts/fishing/contact_water.gdshader")
const ToolWaterMask = preload("res://scripts/fishing/tool_water_mask.gdshader")
const POOL_SIZE := Vector2(188, 36)
const POOL_STROKE := 3.0
const MAX_IMMERSION := 5.0
# Reviewed, fixed state scales; source bounds never determine visual scale.
const NET_STATE_SCALE := 0.82
const HANDS_STATE_SCALE := 0.72
const ROD_STATE_SCALE := 0.82
const ROD_WIDTH_SCALE := 0.72
const ROD_TIP := Vector2(181, 22)
const ROD_BUTT := Vector2(25, 178)
const MIRROR_STATE_SCALE := 0.90
# Offline-authored lower contact points on the shared 200px canvas. Used only
# to ground the lower edge, including rotation, never to fit or scale art.
const CONTACT_POINTS := {
	"net": [Vector2(72.9, 187.1), Vector2(75.9, 187.9), Vector2(88.7, 189.5), Vector2(93.1, 189.3), Vector2(132.9, 181.7)],
	"hands": [Vector2(29.2, 163.2), Vector2(34.8, 164.4), Vector2(156.5, 164.8), Vector2(165.2, 164.3), Vector2(169.4, 163.3)],
	"boat": [Vector2(37.8, 155.7), Vector2(38.4, 155.8), Vector2(84.4, 158.1), Vector2(144, 154.9), Vector2(154.5, 152.6)],
	"mirror": [Vector2(26.8, 178.8), Vector2(28.7, 179.3), Vector2(133.8, 181.2), Vector2(149.1, 180.9), Vector2(152.3, 180.1)],
}
# Shared authored canvas and broad contact edge; never fit to alpha bounds.
const SPLASH_DRAW_BOX := Vector2(116, 116) * 1.05
const SPLASH_CONTACT := Vector2(58, 109) * 1.05

class SplashLayer:
	extends Control
	var stage: Control
	var in_front := false
	func _draw() -> void:
		stage._draw_splashes(self, in_front)

var art: TextureRect
var hit: Button
var tool_id := ""
var fluid_kind := "water"
var elapsed := 0.0
var manual_haul_seconds := 0.0
var entry_seconds := 0.0
var ripple_strength := 0.0
var splash_strength := 0.0
var splash_progress := 0.0
var splash_age := 99.0
var splash_lifetime := 1.2
var splash_visual_progress := 1.0
var splash_burst_active := false
var withdrawal_armed := false
var boat_haul_splashed := false
var splash_sequence := 0 # Withdrawal only: catch particles synchronize to this.
var dip_sequence := 0
var dip_armed := true
var splash_draw_scale := 1.0
var active_splashes: Array[Dictionary] = []
var splash_sides := 3
var splash_variants := [0, 1]
var splash_angles := [0.0, 0.0]
var splash_depths := [false, true]
var splash_delay := 0.07
var splash_textures: Array[AtlasTexture] = []
var splash_random := RandomNumberGenerator.new()
var splash_layer: Control
var front_splash_layer: Control
var splash_material: ShaderMaterial
var pool_surface: ColorRect
var pool_foreground: ColorRect
var tool_water_material: ShaderMaterial
var pool_material: ShaderMaterial
var pool_front_material: ShaderMaterial
var fluid_color := Color("#3db8d9")
var fluid_highlight := Color("#9edbec")
var layout_scale := 1.0
var water_center := Vector2.ZERO
var pose_initialized := false
var line_end := Vector2.ZERO
var cast_progress := 0.0
var rod_lift := 0.0
var location_entry_seconds := 0.0
var location_entry_started_msec := 0
var location_entry_start := Vector2.ZERO
var location_entry_scale := Vector2.ONE
var flying_icon: TextureRect
var flying_tool: TextureRect

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	pool_material = ShaderMaterial.new()
	pool_material.shader = WaterSurface
	pool_surface = ColorRect.new()
	pool_surface.material = pool_material
	pool_surface.show_behind_parent = true
	pool_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pool_surface)
	splash_random.randomize()
	var frame_size := SplashFrames.get_size() / Vector2(3, 2)
	for row in range(2):
		for column in range(3):
			var frame := AtlasTexture.new()
			frame.atlas = SplashFrames
			frame.region = Rect2(Vector2(column, row) * frame_size, frame_size)
			frame.filter_clip = true
			splash_textures.append(frame)
	splash_layer = SplashLayer.new()
	splash_layer.stage = self
	splash_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	splash_material = ShaderMaterial.new()
	splash_material.shader = preload("res://scripts/fishing/splash_flat.gdshader")
	splash_layer.material = splash_material
	add_child(splash_layer)
	tool_water_material = ShaderMaterial.new()
	tool_water_material.shader = ToolWaterMask
	art = TextureRect.new()
	art.material = tool_water_material
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size = TOOL_DRAW_BOX
	art.pivot_offset = TOOL_DRAW_BOX * 0.5
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	pool_front_material = ShaderMaterial.new()
	pool_front_material.shader = WaterSurface
	pool_front_material.set_shader_parameter("front_half", true)
	pool_foreground = ColorRect.new()
	pool_foreground.material = pool_front_material
	pool_foreground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pool_foreground)
	front_splash_layer = SplashLayer.new()
	front_splash_layer.stage = self
	front_splash_layer.in_front = true
	front_splash_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front_splash_layer.material = splash_material
	add_child(front_splash_layer)
	for index in 2:
		var flying := TextureRect.new()
		flying.name = "IncomingLocationIcon" if index == 0 else "IncomingAnimationTool"
		flying.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flying.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flying.size = TOOL_DRAW_BOX
		flying.pivot_offset = TOOL_DRAW_BOX * .5
		flying.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flying.z_as_relative = false
		flying.z_index = 502
		flying.visible = false
		add_child(flying)
		if index == 0: flying_icon = flying
		else: flying_tool = flying
	var flight_material := ShaderMaterial.new()
	flight_material.shader = ToolWaterMask
	flight_material.set_shader_parameter("water_center",Vector2(0,1000000))
	flying_tool.material = flight_material
	hit = Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_child(hit)

func set_tool(next_id: String, texture: Texture2D, next_fluid: String) -> void:
	tool_id = next_id
	fluid_kind = next_fluid
	var palette := FluidStrip.palette_for(fluid_kind)
	fluid_color = palette.fluid
	fluid_highlight = fluid_color.lerp(Color.WHITE, 0.5)
	splash_material.set_shader_parameter("water_color", fluid_color)
	splash_material.set_shader_parameter("highlight_color", fluid_highlight)
	pool_material.set_shader_parameter("water_color", fluid_color)
	art.texture = texture
	if next_id in ["line", "reinforced_rod", "star_rod"]:
		var part := AtlasTexture.new()
		part.atlas = ROD_PARTS
		part.region = Rect2(Vector2(640, 0) if next_id == "reinforced_rod" else (Vector2(0, 640) if next_id == "star_rod" else Vector2.ZERO), Vector2(640, 640))
		art.texture = part
	tool_water_material.set_shader_parameter("shaft_width", ROD_WIDTH_SCALE if next_id in ["line", "reinforced_rod", "star_rod"] else 1.0)
	manual_haul_seconds = 0.0
	entry_seconds = ENTRY_SECONDS
	pose_initialized = false
	splash_burst_active = false
	withdrawal_armed = false
	boat_haul_splashed = false
	dip_armed = true
	active_splashes.clear()
	splash_age = 99.0

func begin_manual_haul() -> void:
	if tool_id in ["hands", "mirror"]: manual_haul_seconds = MANUAL_HAUL_SECONDS

func begin_location_entry(source: TextureRect, elapsed_seconds := 0.0) -> void:
	if not is_instance_valid(source): return
	location_entry_start = get_global_transform().affine_inverse() * source.get_global_rect().get_center()
	location_entry_scale = source.size * source.get_global_transform().get_scale() / get_global_transform().get_scale() / TOOL_DRAW_BOX
	flying_icon.texture = source.texture
	flying_tool.texture = art.texture
	(flying_tool.material as ShaderMaterial).set_shader_parameter("shaft_width",ROD_WIDTH_SCALE if tool_id in ["line","reinforced_rod","star_rod"] else 1.0)
	location_entry_seconds = maxf(0.0,LOCATION_ENTRY_SECONDS-elapsed_seconds)
	location_entry_started_msec = Time.get_ticks_msec()-int(elapsed_seconds*1000.0)
	entry_seconds = 0.0
	pose_initialized = false
	active_splashes.clear()
	splash_layer.queue_redraw()
	front_splash_layer.queue_redraw()

func cancel_location_entry() -> void:
	location_entry_seconds = 0.0
	flying_icon.visible = false
	flying_tool.visible = false
	art.visible = true

func _advance_location_entry(delta: float) -> void:
	location_entry_seconds = maxf(0.0,minf(location_entry_seconds-delta,LOCATION_ENTRY_SECONDS-float(Time.get_ticks_msec()-location_entry_started_msec)/1000.0))
	var progress := 1.0 - location_entry_seconds / LOCATION_ENTRY_SECONDS
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var destination := art.position + TOOL_DRAW_BOX * .5
	var bend := location_entry_start.lerp(destination,.5) + Vector2(0,-72.0 * layout_scale)
	var center := location_entry_start.lerp(bend,eased).lerp(bend.lerp(destination,eased),eased)
	var zoom := location_entry_scale.lerp(art.scale,eased) * (1.0 + sin(progress*PI)*.1)
	var turn := art.rotation * eased + sin(progress*PI)*.28*signf(destination.x-location_entry_start.x)
	var morph := smoothstep(.25,.75,progress)
	if flying_icon.texture == flying_tool.texture: morph = 1.0
	for flying in [flying_icon,flying_tool]:
		flying.visible = location_entry_seconds > 0.0
		flying.position = center - TOOL_DRAW_BOX * .5
		flying.scale = zoom
		flying.rotation = turn
	flying_icon.modulate.a = 1.0-morph
	flying_tool.modulate.a = morph
	art.visible = location_entry_seconds <= 0.0

func advance(progress: float, haul_progress: float, delta: float, instant: bool) -> void:
	var arriving := location_entry_seconds > 0.0
	if arriving:
		progress = 0.0
		haul_progress = -1.0
		instant = true
	if tool_id in ["hands", "mirror"] and manual_haul_seconds > 0.0:
		haul_progress = 1.0 - manual_haul_seconds / MANUAL_HAUL_SECONDS
		manual_haul_seconds = maxf(0.0, manual_haul_seconds - delta)
	elapsed += maxf(delta, 0.0)
	splash_age += maxf(delta, 0.0)
	for burst in active_splashes:
		burst.age += maxf(delta, 0.0)
	active_splashes = active_splashes.filter(func(burst: Dictionary): return burst.age < burst.lifetime)
	entry_seconds = maxf(0.0, entry_seconds - delta)
	layout_scale = minf(size.x / REFERENCE_SIZE.x, size.y / REFERENCE_SIZE.y)
	layout_scale = minf(1.15, maxf(0.1, layout_scale))
	water_center = Vector2(size.x * 0.5, size.y - 62.0 * layout_scale)
	var p := clampf(progress, 0.0, 1.0)
	var center := Vector2(0, -112)
	var angle := 0.0
	var contact := 0.3
	var splash := 0.0
	var hauling := haul_progress >= 0.0
	var withdrawing := hauling and haul_progress < 0.5
	var lift := sin(clampf(haul_progress, 0.0, 1.0) * PI) if hauling else 0.0
	cast_progress = smoothstep(0.0, 0.3, p)
	rod_lift = lift
	match tool_id:
		"net":
			var reach := 1.0 if hauling else smoothstep(0.0, 0.27, p)
			center = Vector2(sin(elapsed * 1.8) * 9.0, lerpf(-168.0, -58.0, reach) - lift * 72.0)
			angle = lerpf(-0.12, 0.12, reach) - lift * 0.18
			contact = reach * (1.0 - lift)
			splash = lift if hauling else 0.0
			splash_progress = haul_progress if hauling else reach
		"mirror":
			var reach := 1.0 if hauling else smoothstep(0.0, 0.34, p)
			var return_lift := smoothstep(0.0, 0.65, haul_progress) if hauling else 0.0
			center = Vector2(sin(p * TAU) * 6.0, lerpf(-165.0, -84.0, reach) - return_lift * 64.0)
			angle = sin(p * TAU) * 0.16
			contact = reach * (1.0 - return_lift)
			splash = return_lift
			splash_progress = return_lift
			withdrawing = hauling and haul_progress < 0.65
		"boat":
			center = Vector2(sin(elapsed * 1.1) * 8.0, -65.0 + sin(elapsed * 2.3) * 7.0 - lift * 18.0)
			angle = sin(elapsed * 1.6) * 0.055
			contact = 0.8
			splash = lift * 0.5
			splash_progress = haul_progress if hauling else 0.0
		"hands":
			var reach := 1.0 if hauling else smoothstep(0.15, 0.48, p)
			var return_lift := smoothstep(0.0, 0.65, haul_progress) if hauling else 0.0
			center = Vector2(sin(p * TAU) * 10.0, lerpf(-145.0, -36.0, reach) - return_lift * 80.0)
			angle = sin(p * TAU) * 0.08
			contact = reach * (1.0 - return_lift)
			splash = return_lift
			splash_progress = return_lift
			withdrawing = hauling and haul_progress < 0.65
		_:
			var cast := 1.0 if hauling else smoothstep(0.0, 0.3, p)
			cast_progress = cast
			center = Vector2(-46.0 + sin(elapsed * 1.4) * 3.0 - lift * 12.0, lerpf(-157.0, -88.0, cast) - lift * 22.0)
			angle = lerpf(-0.10, 0.10, cast) - lift * 0.62
			contact = cast * (1.0 - lift)
			splash = lift if hauling else 0.0
			splash_progress = haul_progress if hauling else cast
	# Entry settles wholly inside the stage instead of falling through its mask.
	var entry := smoothstep(0.0, 1.0, entry_seconds / ENTRY_SECONDS)
	center.y -= entry * 12.0
	var target_center := water_center + center * layout_scale
	var state_scale := 1.0
	if tool_id == "hands": state_scale = HANDS_STATE_SCALE
	elif tool_id == "net": state_scale = NET_STATE_SCALE
	elif tool_id == "mirror": state_scale = MIRROR_STATE_SCALE
	elif tool_id in ["line", "reinforced_rod", "star_rod"]: state_scale = ROD_STATE_SCALE
	var tool_scale := layout_scale * state_scale
	if CONTACT_POINTS.has(tool_id):
		var bottom_offset := _contact_bottom_offset(angle, tool_scale)
		var contact_height := water_center.y + MAX_IMMERSION * layout_scale - bottom_offset
		if tool_id == "boat":
			target_center.y = contact_height - (2.0 + sin(elapsed * 2.3) * 1.5 + lift * 18.0) * layout_scale
		else:
			target_center.y = lerpf(target_center.y, contact_height, smoothstep(0.75, 1.0, contact))
		target_center.y = minf(target_center.y, water_center.y + MAX_IMMERSION * layout_scale - bottom_offset)
	# Contain the authored canvas, including rotation, without fitting its pixels.
	target_center = _contained_tool_center(target_center, angle, tool_scale)
	var target_position := target_center - TOOL_DRAW_BOX * 0.5
	var blend := 1.0 if instant or not pose_initialized else minf(1.0, delta * 14.0)
	art.position = art.position.lerp(target_position, blend)
	art.rotation = lerpf(art.rotation, angle, blend)
	art.scale = Vector2.ONE * tool_scale
	# Reapply containment and depth after interpolation: rotating during return
	# can otherwise lower a corner while the center itself moves upward.
	var actual_center := art.position + TOOL_DRAW_BOX * 0.5
	actual_center = _contained_tool_center(actual_center, art.rotation, tool_scale)
	if CONTACT_POINTS.has(tool_id):
		actual_center.y = minf(actual_center.y, water_center.y + MAX_IMMERSION * layout_scale - _contact_bottom_offset(art.rotation, tool_scale))
	art.position = actual_center - TOOL_DRAW_BOX * 0.5
	tool_water_material.set_shader_parameter("object_center", art.position + TOOL_DRAW_BOX * 0.5)
	tool_water_material.set_shader_parameter("object_angle", art.rotation)
	tool_water_material.set_shader_parameter("object_scale", tool_scale)
	tool_water_material.set_shader_parameter("water_center", water_center)
	tool_water_material.set_shader_parameter("pool_radii", (POOL_SIZE * 0.5 - Vector2.ONE * POOL_STROKE) * layout_scale)
	pose_initialized = true
	var float_target := water_center + Vector2(28.0 + sin(elapsed * 1.7) * 12.0, -6.0 + sin(elapsed * 2.4) * 2.0) * layout_scale
	var rod_tip := art.get_transform() * _rod_source_point(ROD_TIP)
	if tool_id in ["line", "reinforced_rod", "star_rod"]:
		var rest_angle := lerpf(-0.10, 0.10, cast_progress)
		var rest_center := water_center + Vector2(-46.0 + sin(elapsed * 1.4) * 3.0, lerpf(-157.0, -88.0, cast_progress)) * layout_scale
		rest_center = _contained_tool_center(rest_center, rest_angle, tool_scale)
		var resting_tip := rest_center + (_rod_source_point(ROD_TIP) - TOOL_DRAW_BOX * .5).rotated(rest_angle) * tool_scale
		# The rendered rod tip drives the taut line. It cannot lift before the
		# shaft actually pulls back, including during pose interpolation.
		var pull := rod_tip - resting_tip
		pull.y = minf(pull.y, 0.0)
		float_target += pull
		rod_lift = clampf(-pull.y / (32.0 * layout_scale), 0.0, 1.0)
	line_end = (rod_tip + Vector2(4, 52) * layout_scale).lerp(float_target, cast_progress)
	ripple_strength = contact
	for surface in [pool_surface, pool_foreground]:
		surface.size = POOL_SIZE * layout_scale
		surface.position = water_center - surface.size * 0.5
	pool_front_material.set_shader_parameter("water_color", Color(fluid_color, 0.96))
	if arriving:
		_advance_location_entry(delta)
		sync_hit()
		queue_redraw()
		return
	# Launch from the rendered contact edge crossing the surface on withdrawal,
	# after interpolation and immersion limits. Entry/cast progress is unrelated
	# to the moment a hand, net or fishing line actually leaves the water.
	var contact_depth := interaction_depth()
	# The net dips on every attempt, even while fish accumulate before a haul.
	# Keep entry bursts separate from withdrawal events so fish never spawn early.
	if tool_id == "net":
		if contact_depth < -0.5:
			dip_armed = true
		if dip_armed and not withdrawing and contact_depth >= 0.5:
			dip_armed = false
			_begin_splash_burst(0.55, false)
	if tool_id == "boat":
		# The hull floats; its wake follows the haul rock rather than an exit.
		if not hauling: boat_haul_splashed = false
		if withdrawing and lift > 0.1 and not boat_haul_splashed:
			boat_haul_splashed = true
			_begin_splash_burst()
	else:
		if contact_depth > 0.5:
			withdrawal_armed = true
		if withdrawing and withdrawal_armed and contact_depth <= 0.5:
			withdrawal_armed = false
			_begin_splash_burst()
	splash_burst_active = splash_age < splash_lifetime
	splash_strength = splash
	splash_visual_progress = clampf(splash_age / splash_lifetime, 0.0, 1.0)
	sync_hit()
	queue_redraw()
	splash_layer.queue_redraw()
	front_splash_layer.queue_redraw()

func _rod_source_point(point: Vector2) -> Vector2:
	var cross_axis := Vector2.ONE.normalized()
	var local := point - TOOL_DRAW_BOX * .5
	return point - cross_axis * local.dot(cross_axis) * (1.0 - ROD_WIDTH_SCALE)

func _contained_tool_center(center: Vector2, angle: float, tool_scale: float) -> Vector2:
	if tool_id in ["line", "reinforced_rod", "star_rod"]:
		# Fixed authored shaft envelope, including its stroke and upgrade bands.
		# This grounds the diagonal rod without treating transparent corners as art.
		var minimum := Vector2(INF, INF)
		var maximum := Vector2(-INF, -INF)
		for end in [ROD_TIP, ROD_BUTT]:
			for side in [-1.0, 1.0]:
				var point := _rod_source_point(end + Vector2.ONE.normalized() * 32.0 * side)
				var offset := (point - TOOL_DRAW_BOX * .5).rotated(angle) * tool_scale
				minimum = minimum.min(offset)
				maximum = maximum.max(offset)
		return center.clamp(Vector2.ONE * 8.0 - minimum, size - Vector2.ONE * 8.0 - maximum)
	var half_extent := (absf(sin(angle)) + absf(cos(angle))) * TOOL_DRAW_BOX.x * .5 * tool_scale
	return center.clamp(Vector2.ONE * (half_extent + 8.0), size - Vector2.ONE * (half_extent + 8.0))

func interaction_depth() -> float:
	if tool_id in ["line", "reinforced_rod", "star_rod"]:
		return (immersed_line_end().y - water_center.y) / layout_scale
	return immersion_depth()

func _begin_splash_burst(draw_scale := 1.0, withdrawal := true) -> void:
	splash_age = 0.0
	splash_draw_scale = draw_scale
	if withdrawal:
		splash_sequence += 1
	else:
		dip_sequence += 1
	splash_sides = splash_random.randi_range(1, 3)
	for index in range(2):
		splash_variants[index] = splash_random.randi_range(0, 1)
		splash_angles[index] = splash_random.randf_range(-0.025, 0.025)
		splash_depths[index] = splash_random.randi_range(0, 1) == 1
	splash_delay = splash_random.randf_range(0.025, 0.06)
	splash_lifetime = splash_random.randf_range(1.1, 1.3)
	if tool_id == "net":
		if withdrawal:
			splash_sides = 3
			splash_depths[1] = not bool(splash_depths[0])
		elif splash_sides == 3:
			splash_depths[1] = not bool(splash_depths[0])
		else:
			splash_depths[0 if splash_sides == 1 else 1] = true
	active_splashes.append({"age": 0.0, "lifetime": splash_lifetime, "scale": splash_draw_scale,
		"sides": splash_sides, "depths": splash_depths.duplicate(), "variants": splash_variants.duplicate(),
		"angles": splash_angles.duplicate(), "delay": splash_delay})

func _contact_bottom_offset(angle: float, state_scale: float) -> float:
	var bottom := -INF
	for point: Vector2 in CONTACT_POINTS[tool_id]:
		bottom = maxf(bottom, ((point - TOOL_DRAW_BOX * 0.5).rotated(angle) * state_scale).y)
	return bottom + 0.5 * state_scale

func immersion_depth() -> float:
	if not CONTACT_POINTS.has(tool_id): return 0.0
	return (art.position.y + TOOL_DRAW_BOX.y * 0.5 + _contact_bottom_offset(art.rotation, art.scale.x) - water_center.y) / layout_scale

func immersed_line_end() -> Vector2:
	var radii := (POOL_SIZE * 0.5 - Vector2.ONE * POOL_STROKE) * layout_scale
	var x_fraction := clampf((line_end.x - water_center.x) / radii.x, -1.0, 1.0)
	var bottom := water_center.y + radii.y * sqrt(maxf(0.0, 1.0 - x_fraction * x_fraction))
	return Vector2(line_end.x, minf(line_end.y + 19.0 * layout_scale, minf(water_center.y + MAX_IMMERSION * layout_scale, bottom - 2.0 * layout_scale)))

func visual_bounds() -> Rect2:
	var transform := art.get_transform()
	var corners: Array[Vector2] = [Vector2.ZERO, Vector2(art.size.x, 0), art.size, Vector2(0, art.size.y)]
	if tool_id in ["line","reinforced_rod","star_rod"]:
		corners.clear()
		for end in [ROD_TIP,ROD_BUTT]:
			for side in [-1.0,1.0]: corners.append(_rod_source_point(end+Vector2.ONE.normalized()*32.0*side))
	var bounds := Rect2(transform * corners[0], Vector2.ZERO)
	for point in corners:
		bounds = bounds.expand(transform * point)
	return bounds

func sync_hit() -> void:
	var bounds := visual_bounds().grow(10.0).intersection(Rect2(Vector2.ZERO, size))
	hit.position = bounds.position
	hit.size = bounds.size
	hit.visible = visible and location_entry_seconds <= 0.0

func water_effect_bounds() -> Rect2:
	return Rect2(water_center - Vector2(124, 160) * layout_scale, Vector2(248, 184) * layout_scale)

func catch_origin() -> Vector2:
	return global_position + water_center + Vector2(0, -3) * layout_scale

func _draw() -> void:
	if not visible or size.x <= 0.0:
		return
	var radii := Vector2(92, 11) * layout_scale
	for index in range(3):
		var phase := fposmod(elapsed * 0.65 + float(index) / 3.0, 1.0)
		var radius := radii * lerpf(0.36, 1.0, phase)
		var color := Color(fluid_highlight, (1.0 - phase) * (0.4 + ripple_strength * 0.45))
		draw_polyline(_ellipse(water_center, radius), color, 3.0 * layout_scale, true)
	if tool_id in ["line", "reinforced_rod", "star_rod"] and location_entry_seconds <= 0.0:
		var tip := art.get_transform() * _rod_source_point(ROD_TIP)
		var slack := tip.lerp(line_end, 0.5) + Vector2(sin(elapsed * 3.1) * 8.0, lerpf(25.0, 2.0, rod_lift) + (1.0 - cast_progress) * 20.0) * layout_scale
		var line := PackedVector2Array()
		for index in range(25):
			var t := float(index) / 24.0
			line.append(tip.lerp(slack, t).lerp(slack.lerp(line_end, t), t))
		draw_polyline(line, Color.BLACK, 7.0 * layout_scale, true)
		draw_polyline(line, Color("#c8ccd1"), 3.0 * layout_scale, true)
		if ripple_strength > 0.5:
			draw_line(line_end, immersed_line_end(), Color("#c8ccd1"), 3.0 * layout_scale, true)
		var bobber := Color("#ef433c") if tool_id == "line" else (Color("#26282c") if tool_id == "reinforced_rod" else Color("#1bcbee"))
		draw_circle(line_end, 12.0 * layout_scale, Color.BLACK, true, -1, true)
		draw_circle(line_end, 8.0 * layout_scale, bobber, true, -1, true)
		draw_circle(line_end + Vector2(-2, -3) * layout_scale, 2.5 * layout_scale, Color.WHITE, true, -1, true)
func _draw_splashes(layer: Control, in_front: bool) -> void:
	if not visible: return
	for burst in active_splashes:
		# Two independent sheets peel away from the contact, with a delayed right
		# sheet. Mirroring keeps both roots attached to the same water surface.
		for index in range(2):
			if (int(burst.sides) & (1 << index)) == 0: continue
			if bool(burst.depths[index]) != in_front: continue
			var side := -1.0 if index == 0 else 1.0
			var is_rod := tool_id in ["line", "reinforced_rod", "star_rod"]
			var interaction_scale := (0.4 if is_rod else 1.0) * float(burst.scale)
			var delay := float(burst.delay) if index == 1 and int(burst.sides) == 3 else 0.0
			var phase := clampf((float(burst.age) - delay) / (float(burst.lifetime) - delay), 0.0, 1.0)
			var opacity := smoothstep(0.0, 0.08, phase) * (1.0 - smoothstep(0.68, 1.0, phase))
			var outward_end := minf(76.0, size.x * 0.5 / layout_scale - SPLASH_DRAW_BOX.x * 0.5 - 4.0)
			var outward_start := maxf(32.0, outward_end - 24.0)
			var origin := Vector2(line_end.x, water_center.y) if is_rod else water_center
			var contact := origin + Vector2(side * lerpf(outward_start, outward_end, phase), 8.0 - 92.0 * phase + 84.0 * phase * phase) * layout_scale * interaction_scale
			layer.draw_set_transform(contact, float(burst.angles[index]) * -side, Vector2(-side, 1.0) * layout_scale * interaction_scale)
			var frame_index := 0 if phase < 0.30 else (1 if phase < 0.65 else 2)
			var next_frame := mini(2, frame_index + 1)
			var blend := smoothstep(0.24, 0.30, phase) if frame_index == 0 else (smoothstep(0.59, 0.65, phase) if frame_index == 1 else 0.0)
			var row := int(burst.variants[index]) * 3
			var frame_rect := Rect2(-SPLASH_CONTACT, SPLASH_DRAW_BOX)
			layer.draw_texture_rect(splash_textures[row + frame_index], frame_rect, false, Color(1, 1, 1, opacity * (1.0 - blend)))
			if blend > 0.0:
				layer.draw_texture_rect(splash_textures[row + next_frame], frame_rect, false, Color(1, 1, 1, opacity * blend))
		layer.draw_set_transform(Vector2.ZERO)

func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(49):
		var angle := TAU * float(index) / 48.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
