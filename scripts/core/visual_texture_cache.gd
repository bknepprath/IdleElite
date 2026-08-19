var texture_cache := {}
var atlas_texture_cache := {}
var fishing_ablation_enabled := Callable()
var runtime_scope_generation := 0
var texture_scope_generation := {}
var atlas_scope_generation := {}


func begin_runtime_scope() -> void:
	runtime_scope_generation += 1


func finish_runtime_scope() -> void:
	if runtime_scope_generation <= 0:
		return
	for raw_key in texture_cache.keys().duplicate():
		var key := str(raw_key)
		if key.begins_with("__"):
			continue
		if int(texture_scope_generation.get(key, -1)) == runtime_scope_generation:
			continue
		texture_cache.erase(key)
		texture_scope_generation.erase(key)
	for raw_key in atlas_texture_cache.keys().duplicate():
		var key := str(raw_key)
		if int(atlas_scope_generation.get(key, -1)) == runtime_scope_generation:
			continue
		atlas_texture_cache.erase(key)
		atlas_scope_generation.erase(key)


func clear_runtime_cache() -> void:
	texture_cache.clear()
	atlas_texture_cache.clear()
	texture_scope_generation.clear()
	atlas_scope_generation.clear()
	runtime_scope_generation = 0


func runtime_cache_counts() -> Dictionary:
	return {
		"textures": texture_cache.size(),
		"atlases": atlas_texture_cache.size(),
	}


func _touch_texture_scope(key: String) -> void:
	if runtime_scope_generation > 0 and not key.begins_with("__"):
		texture_scope_generation[key] = runtime_scope_generation


func _touch_atlas_scope(key: String) -> void:
	if runtime_scope_generation > 0:
		atlas_scope_generation[key] = runtime_scope_generation


func _res_path(path: String) -> String:
	if path.is_empty() or path.begins_with("res://"):
		return path
	return "res://%s" % path


func _uncached_texture_paths(paths: Array) -> Array:
	var pending := []
	for raw_path in paths:
		var path := str(raw_path)
		if path.is_empty():
			continue
		var normalized := _res_path(path)
		if texture_cache.has(normalized):
			continue
		pending.append(path)
	return pending


func _can_create_image_textures() -> bool:
	return DisplayServer.get_name() != "headless"


func _create_image_texture(image: Image) -> Texture2D:
	if image == null or image.is_empty():
		return null
	if DisplayServer.get_name() == "headless":
		return _placeholder_texture(Vector2i(image.get_width(), image.get_height()))
	if not image.has_mipmaps() and image.get_width() > 1 and image.get_height() > 1:
		image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _texture_from_image(path: String, image: Image) -> Texture2D:
	var texture := _create_image_texture(image)
	texture_cache[_res_path(path)] = texture
	return texture


func _atlas_texture(path: String, region: Rect2, filter_clip := false, fishing_ablation_enabled := Callable()) -> Texture2D:
	var normalized := _res_path(path)
	var cache_key := "%s|atlas|%.3f,%.3f,%.3f,%.3f|%s" % [
		normalized,
		region.position.x,
		region.position.y,
		region.size.x,
		region.size.y,
		str(filter_clip)
	]
	if atlas_texture_cache.has(cache_key):
		_touch_atlas_scope(cache_key)
		return atlas_texture_cache[cache_key] as Texture2D
	if DisplayServer.get_name() == "headless":
		var headless_fallback := _visual_fallback_texture()
		atlas_texture_cache[cache_key] = headless_fallback
		_touch_atlas_scope(cache_key)
		return headless_fallback
	var source := _texture(normalized, fishing_ablation_enabled)
	if source == null:
		var fallback := _visual_fallback_texture()
		atlas_texture_cache[cache_key] = fallback
		_touch_atlas_scope(cache_key)
		return fallback
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = region
	atlas.filter_clip = filter_clip
	atlas_texture_cache[cache_key] = atlas
	_touch_atlas_scope(cache_key)
	return atlas


func _image(path: String, minimum_size: Vector2, fishing_ablation_enabled := Callable()) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _texture_or_visual_fallback(path, fishing_ablation_enabled)
	image.custom_minimum_size = minimum_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _spritesheet_texture(path: String, index: int, cell_size: Vector2, fishing_ablation_enabled := Callable()) -> Texture2D:
	return _atlas_texture(path, Rect2(Vector2(maxi(0, index) * cell_size.x, 0), cell_size), false, fishing_ablation_enabled)


func _spritesheet_or_visual_fallback(path: String, index: int, cell_size: Vector2, fishing_ablation_enabled := Callable()) -> Texture2D:
	var loaded_texture := _spritesheet_texture(path, index, cell_size, fishing_ablation_enabled)
	return loaded_texture if loaded_texture != null else _visual_fallback_texture()


func _visual_fallback_texture() -> Texture2D:
	var cache_key := "__visual_fallback_texture__"
	if texture_cache.has(cache_key):
		return texture_cache[cache_key] as Texture2D
	if DisplayServer.get_name() == "headless":
		var placeholder := _placeholder_texture(Vector2i(8, 8))
		texture_cache[cache_key] = placeholder
		return placeholder
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	var texture := ImageTexture.create_from_image(image)
	texture_cache[cache_key] = texture
	return texture


func _fill_headless_null_textures(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var fallback := _visual_fallback_texture()
	if node is TextureRect:
		var texture_rect := node as TextureRect
		if texture_rect.texture == null:
			texture_rect.texture = fallback
		texture_rect.visible = false
	if node is TextureButton:
		var texture_button := node as TextureButton
		if texture_button.texture_normal == null:
			texture_button.texture_normal = fallback
		if texture_button.texture_pressed == null:
			texture_button.texture_pressed = texture_button.texture_normal
		if texture_button.texture_hover == null:
			texture_button.texture_hover = texture_button.texture_normal
		if texture_button.texture_disabled == null:
			texture_button.texture_disabled = texture_button.texture_normal
		if texture_button.texture_focused == null:
			texture_button.texture_focused = texture_button.texture_normal
	for child in node.get_children():
		_fill_headless_null_textures(child)


func _placeholder_texture(texture_size: Vector2i) -> Texture2D:
	var placeholder := PlaceholderTexture2D.new()
	placeholder.size = Vector2(maxi(1, texture_size.x), maxi(1, texture_size.y))
	return placeholder


func _texture_or_visual_fallback(path: String, fishing_ablation_enabled := Callable()) -> Texture2D:
	var loaded_texture := _texture(path, fishing_ablation_enabled)
	return loaded_texture if loaded_texture != null else _visual_fallback_texture()


func _first_texture_or_visual_fallback(paths: Array, fishing_ablation_enabled := Callable()) -> Texture2D:
	for raw_path in paths:
		var path := str(raw_path)
		var loaded_texture: Texture2D = _texture(path, fishing_ablation_enabled)
		if loaded_texture != null:
			return loaded_texture
	return _visual_fallback_texture()


func _image_from_texture(texture: Texture2D, minimum_size: Vector2, texture_path := "", fishing_ablation_enabled := Callable()) -> TextureRect:
	var image := TextureRect.new()
	var loaded_texture := _texture(texture_path, fishing_ablation_enabled) if not texture_path.is_empty() else texture
	image.texture = loaded_texture if loaded_texture != null else _visual_fallback_texture()
	image.custom_minimum_size = minimum_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func _texture(path: String, fishing_ablation_enabled := Callable()) -> Texture2D:
	if path.is_empty():
		return null
	var normalized := _res_path(path)
	_touch_texture_scope(normalized)
	var active_fishing_ablation_enabled := fishing_ablation_enabled if fishing_ablation_enabled.is_valid() else self.fishing_ablation_enabled
	if active_fishing_ablation_enabled.is_valid() and bool(active_fishing_ablation_enabled.call("no_art")) and _path_is_fishing_visual(normalized):
		var ablation_key := "__fishing_ablation_no_art__"
		if texture_cache.has(ablation_key):
			return texture_cache[ablation_key] as Texture2D
		var fallback := _placeholder_texture(Vector2i(16, 16))
		texture_cache[ablation_key] = fallback
		return fallback
	if texture_cache.has(normalized):
		return texture_cache[normalized] as Texture2D
	if DisplayServer.get_name() == "headless" and not _headless_should_load_real_texture(normalized):
		var headless_fallback := _visual_fallback_texture()
		texture_cache[normalized] = headless_fallback
		return headless_fallback
	if ResourceLoader.exists(normalized):
		var loaded = load(normalized)
		if loaded is Texture2D:
			texture_cache[normalized] = loaded
			return loaded
	var image := Image.new()
	if image.load(normalized) != OK:
		var fallback := _visual_fallback_texture()
		texture_cache[normalized] = fallback
		return fallback
	var texture := _texture_from_image(normalized, image)
	return texture


func _path_is_fishing_visual(normalized_path: String) -> bool:
	var lower_path := normalized_path.to_lower()
	return (
		lower_path.contains("/fishing/")
		or lower_path.contains("/combo/fishing/")
		or lower_path.contains("fish")
	)


func _headless_should_load_real_texture(normalized_path: String) -> bool:
	return false
