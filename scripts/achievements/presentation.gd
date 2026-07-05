const MASTERY_MEDALS_TEXTURE := "res://assets/content/ui/mastery-medals-spritesheet.png"
const TOTAL_LEVEL_ART := "res://assets/content/achievements/achievement-total-level.png"
const CRIT_ART := "res://assets/content/achievements/achievement-crit.png"
const CREDIT_ART := "res://assets/content/achievements/achievement-credit.png"
const CUMULATIVE_MEDALS_ART := "res://assets/content/achievements/achievement-cumulative-medals.png"

static var mastery_medal_textures := {}
static var mastery_medal_silhouette_materials := {}


class MedalSparkleStar:
	extends Control

	var fill_color := Color.WHITE
	var outline_color := Color("#171615", 0.66)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			pivot_offset = size * 0.5
			queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var center := size * 0.5
		var outer := minf(size.x, size.y) * 0.48
		var inner := outer * 0.34
		var points := PackedVector2Array()
		for i in range(8):
			var radius := outer if i % 2 == 0 else inner
			var angle := -PI * 0.5 + float(i) * PI * 0.25
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		draw_polygon(points, PackedColorArray([outline_color]))
		var inner_points := PackedVector2Array()
		for i in range(8):
			var radius := (outer - 3.5) if i % 2 == 0 else maxf(1.0, inner - 2.0)
			var angle := -PI * 0.5 + float(i) * PI * 0.25
			inner_points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		draw_polygon(inner_points, PackedColorArray([fill_color]))


static func clear_cache() -> void:
	mastery_medal_textures.clear()
	mastery_medal_silhouette_materials.clear()


static func card(color: Color, radius: int, margin: int, surface_style: Callable) -> StyleBoxFlat:
	return surface_style.call(color, radius, margin, true) as StyleBoxFlat


static func toast_queue_badge() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2f2a21")
	style.border_color = Color("#fff2c4")
	style.set_border_width_all(7)
	style.set_corner_radius_all(999)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style


static func skill_section() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.draw_center = false
	style.content_margin_left = 38
	style.content_margin_right = 38
	style.content_margin_top = 22
	style.content_margin_bottom = 30
	return style


static func skill_level_targets() -> Array:
	var targets := []
	for level in range(2, 100):
		targets.append(level)
	return targets


static func same_tier_medal_count(target: int) -> int:
	if target <= 1:
		return 1
	if target <= 10:
		return 3
	if target <= 25:
		return 5
	if target <= 50:
		return 7
	return 9


static func medal_cluster_positions(count: int) -> Array:
	if count <= 1:
		return [Vector2(89, 72)]
	if count <= 3:
		return [Vector2(48, 88), Vector2(94, 48), Vector2(140, 88)]
	if count <= 5:
		return [Vector2(42, 88), Vector2(70, 50), Vector2(112, 50), Vector2(140, 88), Vector2(91, 112)]
	if count <= 7:
		return [Vector2(34, 88), Vector2(58, 56), Vector2(92, 42), Vector2(126, 56), Vector2(150, 88), Vector2(68, 116), Vector2(116, 116)]
	if count <= 8:
		return [Vector2(28, 88), Vector2(50, 58), Vector2(78, 42), Vector2(110, 42), Vector2(138, 58), Vector2(160, 88), Vector2(68, 116), Vector2(120, 116)]
	return [Vector2(24, 88), Vector2(44, 62), Vector2(68, 44), Vector2(94, 38), Vector2(120, 44), Vector2(144, 62), Vector2(164, 88), Vector2(58, 116), Vector2(94, 122), Vector2(130, 116)]


static func mastery_medal_region(index: int, sheet_size: Vector2i) -> Rect2i:
	var regions := [
		Rect2i(0, 19, 278, 278),
		Rect2i(267, 19, 278, 278),
		Rect2i(536, 19, 278, 278),
		Rect2i(804, 19, 278, 261),
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
		Rect2i(1084, 578, 256, 256),
		Rect2i(15, 842, 256, 256),
		Rect2i(279, 842, 256, 256),
		Rect2i(546, 842, 256, 256),
		Rect2i(833, 842, 256, 256),
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
	var cell := Vector2i(int(floor(float(sheet_size.x) / float(columns))), int(floor(float(sheet_size.y) / float(rows))))
	return Rect2i(Vector2i((index % columns) * cell.x, int(floor(float(index) / float(columns))) * cell.y), cell)


static func mastery_medal_texture(level: int, max_level: int, texture_loader: Callable, visual_fallback: Callable) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		return visual_fallback.call() as Texture2D
	var sheet := texture_loader.call(MASTERY_MEDALS_TEXTURE) as Texture2D
	if sheet == null:
		return null
	var index := clampi(maxi(level, 1) - 1, 0, max_level - 1)
	if mastery_medal_textures.has(index):
		return mastery_medal_textures[index]
	var region := mastery_medal_region(index, Vector2i(sheet.get_width(), sheet.get_height()))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(region.position), Vector2(region.size))
	mastery_medal_textures[index] = atlas
	return atlas


static func mastery_medal_visual_texture(level: int, max_level: int, texture_loader: Callable, visual_fallback: Callable) -> Texture2D:
	var texture := mastery_medal_texture(level, max_level, texture_loader, visual_fallback)
	return texture if texture != null else visual_fallback.call() as Texture2D


static func mastery_medal_silhouette_material(color: Color) -> ShaderMaterial:
	var key := color.to_html(true)
	if mastery_medal_silhouette_materials.has(key):
		return mastery_medal_silhouette_materials[key] as ShaderMaterial
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.0, 0.0, 0.0, 0.7);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.01) {
		COLOR = vec4(0.0);
	} else {
		COLOR = vec4(fill_color.rgb, fill_color.a * tex.a);
	}
}
"""
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("fill_color", color)
	mastery_medal_silhouette_materials[key] = shader_material
	return shader_material


static func progress_pct(achievement: Dictionary) -> float:
	var target := maxi(1, int(achievement.get("target", 1)))
	var current := clampi(int(achievement.get("current", 0)), 0, target)
	return clampf(float(current) / float(target) * 100.0, 0.0, 100.0)
