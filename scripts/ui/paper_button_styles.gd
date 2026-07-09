static func paper_button_style_with_shape(color: Color, radius: int, margin: int, pressed: bool, disabled: bool, outline_color: Color, bevel_side_lift: float, cache: Dictionary, dark_mode: bool, outline_width: float, theme_surface: Callable, theme_outline: Callable, can_create: Callable, create_texture: Callable, fallback_texture: Callable) -> StyleBoxTexture:
	var themed_color: Color = theme_surface.call(color)
	var themed_outline: Color = theme_outline.call(outline_color, color)
	var key := "%s:%s:%s:%s:%s:%s:%s:%s" % [dark_mode, themed_color.to_html(true), radius, margin, pressed, disabled, themed_outline.to_html(true), bevel_side_lift]
	if cache.has(key):
		return cache[key] as StyleBoxTexture
	var style := StyleBoxTexture.new()
	if can_create.call():
		var texture_size := Vector2i(128, 92)
		var outer := Rect2(Vector2.ZERO, Vector2(float(texture_size.x), float(texture_size.y)))
		var inner := outer.grow(-outline_width)
		var inner_radius := 14.0
		var bevel_height := 22.0
		var bevel_strength := 0.40 if not disabled else 0.22
		var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		var fill := themed_color.darkened(0.08 if pressed else 0.0)
		if disabled:
			fill = themed_color.darkened(0.12)
		for y in range(texture_size.y):
			for x in range(texture_size.x):
				var point := Vector2(float(x) + 0.5, float(y) + 0.5)
				if not contains(point, outer, 22.0):
					continue
				var pixel := themed_outline
				if contains(point, inner, inner_radius):
					pixel = fill
					var horizontal := absf((point.x - (inner.position.x + inner.size.x * 0.5)) / maxf(1.0, inner.size.x * 0.5))
					var side_curve := pow(clampf(horizontal, 0.0, 1.0), 2.15)
					var bevel_top := inner.end.y - bevel_height - bevel_side_lift * side_curve + (4.0 if pressed else 0.0)
					if point.y >= bevel_top:
						var shade_t := clampf((point.y - bevel_top) / bevel_height, 0.0, 1.0)
						pixel = fill.lerp(fill.darkened(bevel_strength), 0.38 + shade_t * 0.58)
					elif point.y <= inner.position.y + 5.0 and not pressed:
						pixel = fill.lightened(0.12)
				image.set_pixel(x, y, pixel)
		style.texture = create_texture.call(image)
	else:
		style.texture = fallback_texture.call()
	style.texture_margin_left = 30
	style.texture_margin_right = 30
	style.texture_margin_top = 30
	style.texture_margin_bottom = 34
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = max(18, margin - 18 + (6 if pressed else 0))
	style.content_margin_bottom = max(18, margin - 8 - (4 if pressed else 0))
	cache[key] = style
	return style


static func chunky_activity_button_style(color: Color, radius: int, margin: int, pressed: bool, active: bool, cache: Dictionary, ink: Color, blue: Color, can_create: Callable, create_texture: Callable, fallback_texture: Callable) -> StyleBoxTexture:
	var outline_color := blue if active else ink
	var key := "chunky:%s:%s:%s:%s:%s:%s" % [color.to_html(true), radius, margin, pressed, active, outline_color.to_html(true)]
	if cache.has(key):
		return cache[key] as StyleBoxTexture
	var style := StyleBoxTexture.new()
	if can_create.call():
		var final_texture_size := Vector2i(192, 132)
		var supersample := 4.0
		var texture_size := Vector2i(
			int(final_texture_size.x * supersample),
			int(final_texture_size.y * supersample)
		)
		var border := 9.0 * supersample
		var bottom_lip := (34.0 if not pressed else 20.0) * supersample
		var outer := Rect2(Vector2.ZERO, Vector2(float(texture_size.x), float(texture_size.y)))
		var inner := outer.grow(-border)
		var outer_radius := minf(float(radius) * supersample, 54.0 * supersample)
		var inner_radius := maxf(8.0, outer_radius - border)
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
					var bevel_top := inner.end.y - bottom_lip - 9.0 * supersample * side_curve + ((7.0 * supersample) if pressed else 0.0)
					pixel = fill
					if point.y >= bevel_top:
						var shade_t := clampf((point.y - bevel_top) / maxf(1.0, inner.end.y - bevel_top), 0.0, 1.0)
						pixel = fill.lerp(fill.darkened(0.58), 0.48 + shade_t * 0.46)
					elif point.y <= inner.position.y + 7.0 * supersample and not pressed:
						pixel = fill.lightened(0.12)
					elif point.y <= inner.position.y + 18.0 * supersample and not pressed:
						pixel = fill.lightened(0.05)
				image.set_pixel(x, y, pixel)
		image.resize(final_texture_size.x, final_texture_size.y, Image.INTERPOLATE_LANCZOS)
		style.texture = create_texture.call(image)
	else:
		style.texture = fallback_texture.call()
	style.texture_margin_left = 42
	style.texture_margin_right = 42
	style.texture_margin_top = 36
	style.texture_margin_bottom = 52
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = max(14, margin - 10 + (8 if pressed else 0))
	style.content_margin_bottom = max(14, margin - 16 - (5 if pressed else 0))
	cache[key] = style
	return style


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
