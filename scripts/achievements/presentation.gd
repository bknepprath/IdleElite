const MASTERY_MEDAL_TEXTURES := [
	"res://assets/content/ui/mastery-medals/mastery-medal-01-bronze.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-02-silver.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-03-gold.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-04-platinum.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-05-sapphire.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-06-emerald.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-07-ruby.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-08-diamond.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-09-demonic.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-10-heavenly.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-11-elite-bronze.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-12-elite-silver.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-13-elite-gold.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-14-elite-platinum.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-15-elite-sapphire.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-16-elite-emerald.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-17-elite-ruby.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-18-elite-diamond.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-19-elite-demonic.png",
	"res://assets/content/ui/mastery-medals/mastery-medal-20-elite-heavenly.png"
]
const TOTAL_LEVEL_ART := "res://assets/content/achievements/achievement-total-level.png"
const CRIT_ART := "res://assets/content/achievements/achievement-crit.png"
const CREDIT_ART := "res://assets/content/achievements/achievement-credit.png"
const CUMULATIVE_MEDALS_ART := "res://assets/content/achievements/achievement-cumulative-medals.png"
const ELITE_MEDAL_FIRST_LEVEL := 11
const ELITE_MEDAL_LAST_PLAIN_LEVEL := 18
const ELITE_MEDAL_DISPLAY_SCALE := 1.22
const WINGED_MEDAL_DISPLAY_SCALES := {
	9: 1.79,
	10: 1.57,
	19: 1.77,
	20: 1.77,
}
const MASTERY_MEDAL_ATLAS_REGIONS := [
	Rect2(212, 204, 344, 360),
	Rect2(212, 204, 344, 360),
	Rect2(212, 204, 343, 360),
	Rect2(214, 204, 339, 360),
	Rect2(209, 204, 349, 360),
	Rect2(208, 204, 351, 360),
	Rect2(211, 204, 346, 360),
	Rect2(211, 204, 346, 360),
	Rect2(61, 204, 645, 360),
	Rect2(100, 204, 567, 360),
	Rect2(240, 200, 288, 368),
	Rect2(241, 200, 285, 368),
	Rect2(241, 200, 286, 368),
	Rect2(242, 200, 284, 368),
	Rect2(236, 200, 295, 368),
	Rect2(239, 200, 290, 368),
	Rect2(237, 200, 293, 368),
	Rect2(238, 200, 292, 368),
	Rect2(120, 200, 527, 368),
	Rect2(121, 200, 526, 368),
]

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
			var radius := (outer - 1.75) if i % 2 == 0 else maxf(0.5, inner - 1.0)
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
	style.set_border_width_all(4)
	style.set_corner_radius_all(999)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 4
	style.content_margin_bottom = 5
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2.5)
	return style


static func skill_section() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.draw_center = false
	style.content_margin_left = 19
	style.content_margin_right = 19
	style.content_margin_top = 11
	style.content_margin_bottom = 15
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
		return [Vector2(44.5, 36)]
	if count <= 3:
		return [Vector2(24, 44), Vector2(47, 24), Vector2(70, 44)]
	if count <= 5:
		return [Vector2(21, 44), Vector2(35, 25), Vector2(56, 25), Vector2(70, 44), Vector2(45.5, 56)]
	if count <= 7:
		return [Vector2(17, 44), Vector2(29, 28), Vector2(46, 21), Vector2(63, 28), Vector2(75, 44), Vector2(34, 58), Vector2(58, 58)]
	if count <= 8:
		return [Vector2(14, 44), Vector2(25, 29), Vector2(39, 21), Vector2(55, 21), Vector2(69, 29), Vector2(80, 44), Vector2(34, 58), Vector2(60, 58)]
	return [Vector2(12, 44), Vector2(22, 31), Vector2(34, 22), Vector2(47, 19), Vector2(60, 22), Vector2(72, 31), Vector2(82, 44), Vector2(29, 58), Vector2(47, 61), Vector2(65, 58)]


static func mastery_medal_texture(level: int, max_level: int, texture_loader: Callable, visual_fallback: Callable) -> Texture2D:
	var index := clampi(maxi(level, 1) - 1, 0, max_level - 1)
	if mastery_medal_textures.has(index):
		return mastery_medal_textures[index]
	var source := texture_loader.call(str(MASTERY_MEDAL_TEXTURES[index])) as Texture2D
	var texture := _cropped_texture(source, index)
	if texture == null:
		return visual_fallback.call() as Texture2D
	mastery_medal_textures[index] = texture
	return texture


static func _cropped_texture(texture: Texture2D, index: int) -> Texture2D:
	if texture == null:
		return null
	if index < 0 or index >= MASTERY_MEDAL_ATLAS_REGIONS.size():
		return texture
	var region: Rect2 = MASTERY_MEDAL_ATLAS_REGIONS[index]
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	atlas.filter_clip = true
	return atlas


static func mastery_medal_visual_texture(level: int, max_level: int, texture_loader: Callable, visual_fallback: Callable) -> Texture2D:
	var texture := mastery_medal_texture(level, max_level, texture_loader, visual_fallback)
	return texture if texture != null else visual_fallback.call() as Texture2D


static func mastery_medal_display_scale(level: int) -> float:
	if WINGED_MEDAL_DISPLAY_SCALES.has(level):
		return float(WINGED_MEDAL_DISPLAY_SCALES[level])
	return ELITE_MEDAL_DISPLAY_SCALE if level >= ELITE_MEDAL_FIRST_LEVEL and level <= ELITE_MEDAL_LAST_PLAIN_LEVEL else 1.0


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
