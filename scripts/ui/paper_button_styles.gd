static func paper_button_style_with_shape(color: Color, radius: int, margin: int, pressed: bool, disabled: bool, outline_color: Color, bevel_side_lift: float, cache: Dictionary, dark_mode: bool, outline_width: float, theme_surface: Callable, theme_outline: Callable, can_create: Callable, create_texture: Callable, fallback_texture: Callable) -> StyleBoxTexture:
	var themed_color: Color = theme_surface.call(color)
	var themed_outline: Color = theme_outline.call(outline_color, color)
	var key := "%s:%s:%s:%s:%s:%s:%s:%s" % [dark_mode, themed_color.to_html(true), radius, margin, pressed, disabled, themed_outline.to_html(true), bevel_side_lift]
	if cache.has(key):
		return cache[key] as StyleBoxTexture
	var style := StyleBoxTexture.new()
	if can_create.call():
		# Radius and margin only set the style's margins. Styles that differ in
		# nothing else share one texture instead of each drawing its own.
		var texture_key := "paper-texture:%s:%s:%s:%s:%s:%s" % [_exact_color_key(themed_color), pressed, disabled, _exact_color_key(themed_outline), bevel_side_lift, outline_width]
		if not cache.has(texture_key):
			var draw_started_usec := Time.get_ticks_usec()
			cache[texture_key] = create_texture.call(paper_button_image(themed_color, pressed, disabled, themed_outline, bevel_side_lift, outline_width))
			_note_main_thread_draw(draw_started_usec)
		style.texture = cache[texture_key]
	else:
		style.texture = fallback_texture.call()
	style.texture_margin_left = 15
	style.texture_margin_right = 15
	style.texture_margin_top = 15
	style.texture_margin_bottom = 17
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = max(9, margin - 9 + (3 if pressed else 0))
	style.content_margin_bottom = max(9, margin - 4 - (2 if pressed else 0))
	cache[key] = style
	return style


# Textures drawn on the main thread since the last reading, for the debug
# report in main.gd.
static var main_thread_draw_count := 0
static var main_thread_draw_usec := 0


static func _note_main_thread_draw(started_usec: int) -> void:
	main_thread_draw_count += 1
	main_thread_draw_usec += Time.get_ticks_usec() - started_usec


static func take_main_thread_draw_stats() -> Dictionary:
	var stats := {"count": main_thread_draw_count, "usec": main_thread_draw_usec}
	main_thread_draw_count = 0
	main_thread_draw_usec = 0
	return stats


# Two colours share a texture only when they are the same colour, not merely the
# same once rounded to eight bits.
static func _exact_color_key(color: Color) -> String:
	return "%.9f,%.9f,%.9f,%.9f" % [color.r, color.g, color.b, color.a]


static func paper_button_image(themed_color: Color, pressed: bool, disabled: bool, themed_outline: Color, bevel_side_lift: float, outline_width: float) -> Image:
	var texture_size := Vector2i(64, 46)
	var outer := Rect2(Vector2.ZERO, Vector2(float(texture_size.x), float(texture_size.y)))
	var inner := outer.grow(-outline_width)
	var inner_radius := 7.0
	var bevel_height := 11.0
	var bevel_strength := 0.40 if not disabled else 0.22
	var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var fill := themed_color.darkened(0.08 if pressed else 0.0)
	if disabled:
		fill = themed_color.darkened(0.12)
	for y in range(texture_size.y):
		for x in range(texture_size.x):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			if not contains(point, outer, 11.0):
				continue
			var pixel := themed_outline
			if contains(point, inner, inner_radius):
				pixel = fill
				var horizontal := absf((point.x - (inner.position.x + inner.size.x * 0.5)) / maxf(1.0, inner.size.x * 0.5))
				var side_curve := pow(clampf(horizontal, 0.0, 1.0), 2.15)
				var bevel_top := inner.end.y - bevel_height - bevel_side_lift * side_curve + (2.0 if pressed else 0.0)
				if point.y >= bevel_top:
					var shade_t := clampf((point.y - bevel_top) / bevel_height, 0.0, 1.0)
					pixel = fill.lerp(fill.darkened(bevel_strength), 0.38 + shade_t * 0.58)
				elif point.y <= inner.position.y + 2.5 and not pressed:
					pixel = fill.lightened(0.12)
			image.set_pixel(x, y, pixel)
	return image


static func chunky_activity_button_style(color: Color, radius: int, margin: int, pressed: bool, active: bool, cache: Dictionary, ink: Color, blue: Color, can_create: Callable, create_texture: Callable, fallback_texture: Callable) -> StyleBoxTexture:
	var outline_color := blue if active else ink
	var key := "chunky:%s:%s:%s:%s:%s:%s" % [color.to_html(true), radius, margin, pressed, active, outline_color.to_html(true)]
	if cache.has(key):
		return cache[key] as StyleBoxTexture
	var style := StyleBoxTexture.new()
	if can_create.call():
		style.texture = _chunky_button_texture(color, radius, pressed, outline_color, create_texture)
	else:
		style.texture = fallback_texture.call()
	style.texture_margin_left = 21
	style.texture_margin_right = 21
	style.texture_margin_top = 18
	style.texture_margin_bottom = 26
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = max(7, margin - 5 + (4 if pressed else 0))
	style.content_margin_bottom = max(7, margin - 8 - (2.5 if pressed else 0.0))
	cache[key] = style
	return style


# A chunky texture is drawn pixel by pixel at four times its size and scaled
# down: about a tenth of a second each on a desktop, on the frame that first
# shows the button. The handful the game uses are drawn on a worker thread after
# boot instead. One asked for before its image is ready is drawn on the spot, as
# before. Textures do not depend on the theme, so they outlive a theme change.
static var _chunky_textures := {}
static var _chunky_images := {}
static var _chunky_mutex := Mutex.new()
static var _chunky_thread: Thread = null


static func chunky_texture_key(color: Color, radius: int, pressed: bool, outline_color: Color) -> String:
	return "%s:%s:%s:%s" % [_exact_color_key(color), radius, pressed, _exact_color_key(outline_color)]


static func _chunky_button_texture(color: Color, radius: int, pressed: bool, outline_color: Color, create_texture: Callable) -> Texture2D:
	var texture_key := chunky_texture_key(color, radius, pressed, outline_color)
	if _chunky_textures.has(texture_key):
		return _chunky_textures[texture_key] as Texture2D
	finish_chunky_prewarm(false)
	_chunky_mutex.lock()
	var image := _chunky_images.get(texture_key, null) as Image
	_chunky_images.erase(texture_key)
	_chunky_mutex.unlock()
	var draw_started_usec := Time.get_ticks_usec()
	var drawn_here := image == null
	if drawn_here:
		image = chunky_button_image(color, radius, pressed, outline_color)
	var texture := create_texture.call(image) as Texture2D
	if drawn_here:
		_note_main_thread_draw(draw_started_usec)
	_chunky_textures[texture_key] = texture
	return texture


# specs: [{"color": Color, "radius": int, "pressed": bool, "outline": Color}, ...]
static func prewarm_chunky_images(specs: Array) -> void:
	if _chunky_thread != null or specs.is_empty():
		return
	if OS.has_feature("web"):
		# A web build may have no threads. Its textures are drawn when first shown.
		return
	var pending: Array = []
	for raw_spec in specs:
		var spec := raw_spec as Dictionary
		if not _chunky_textures.has(chunky_texture_key(spec["color"], int(spec["radius"]), bool(spec["pressed"]), spec["outline"])):
			pending.append(spec.duplicate())
	if pending.is_empty():
		return
	var thread := Thread.new()
	if thread.start(_draw_chunky_images.bind(pending)) == OK:
		_chunky_thread = thread


static func _draw_chunky_images(specs: Array) -> void:
	for raw_spec in specs:
		var spec := raw_spec as Dictionary
		var color: Color = spec["color"]
		var outline: Color = spec["outline"]
		var image := chunky_button_image(color, int(spec["radius"]), bool(spec["pressed"]), outline)
		_chunky_mutex.lock()
		_chunky_images[chunky_texture_key(color, int(spec["radius"]), bool(spec["pressed"]), outline)] = image
		_chunky_mutex.unlock()


# Joins the worker once it is done. With wait, blocks until it is.
static func finish_chunky_prewarm(wait: bool) -> void:
	if _chunky_thread == null:
		return
	if wait or not _chunky_thread.is_alive():
		_chunky_thread.wait_to_finish()
		_chunky_thread = null


static func clear_chunky_cache() -> void:
	finish_chunky_prewarm(true)
	_chunky_mutex.lock()
	_chunky_images.clear()
	_chunky_mutex.unlock()
	_chunky_textures.clear()


static func chunky_button_image(color: Color, radius: int, pressed: bool, outline_color: Color) -> Image:
	var final_texture_size := Vector2i(96, 66)
	var supersample := 4.0
	var texture_size := Vector2i(
		int(final_texture_size.x * supersample),
		int(final_texture_size.y * supersample)
	)
	var border := 6.0 * supersample
	var bottom_lip := (17.0 if not pressed else 10.0) * supersample
	var outer := Rect2(Vector2.ZERO, Vector2(float(texture_size.x), float(texture_size.y)))
	var inner := outer.grow(-border)
	var outer_radius := minf(float(radius) * supersample, 27.0 * supersample)
	var inner_radius := maxf(4.0, outer_radius - border)
	var fill := color.darkened(0.07 if pressed else 0.0)
	var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(texture_size.y):
		for x in range(texture_size.x):
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			if not contains(point, outer, outer_radius):
				continue
			var pixel := outline_color
			if contains(point, inner, inner_radius):
				var horizontal := absf((point.x - inner.get_center().x) / maxf(1.0, inner.size.x * 0.5))
				var side_curve := pow(clampf(horizontal, 0.0, 1.0), 1.75)
				var bevel_top := inner.end.y - bottom_lip - 4.5 * supersample * side_curve + ((3.5 * supersample) if pressed else 0.0)
				pixel = fill
				if point.y >= bevel_top:
					var shade_t := clampf((point.y - bevel_top) / maxf(1.0, inner.end.y - bevel_top), 0.0, 1.0)
					pixel = fill.lerp(fill.darkened(0.58), 0.48 + shade_t * 0.46)
				elif point.y <= inner.position.y + 3.5 * supersample and not pressed:
					pixel = fill.lightened(0.12)
				elif point.y <= inner.position.y + 9.0 * supersample and not pressed:
					pixel = fill.lightened(0.05)
			image.set_pixel(x, y, pixel)
	image.resize(final_texture_size.x, final_texture_size.y, Image.INTERPOLATE_LANCZOS)
	return image


static func contains(point: Vector2, rect: Rect2, radius: float) -> bool:
	var clamped_radius := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var center := Vector2(
		clampf(point.x, rect.position.x + clamped_radius, rect.end.x - clamped_radius),
		clampf(point.y, rect.position.y + clamped_radius, rect.end.y - clamped_radius)
	)
	return point.distance_to(center) <= clamped_radius or (
		point.x >= rect.position.x + clamped_radius
		and point.x <= rect.end.x - clamped_radius
		and point.y >= rect.position.y
		and point.y <= rect.end.y
	) or (
		point.x >= rect.position.x
		and point.x <= rect.end.x
		and point.y >= rect.position.y + clamped_radius
		and point.y <= rect.end.y - clamped_radius
	)
