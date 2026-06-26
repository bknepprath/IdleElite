class_name FightingModuleStage
extends Control


func load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	var image := Image.new()
	var result := image.load(ProjectSettings.globalize_path(path))
	if result != OK:
		result = image.load(path)
	if result != OK:
		return null
	return ImageTexture.create_from_image(image)


func draw_round_rect(rect: Rect2, radius: float, color: Color) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0.0), Vector2(maxf(0.0, rect.size.x - r * 2.0), rect.size.y)), color)
	draw_rect(Rect2(rect.position + Vector2(0.0, r), Vector2(rect.size.x, maxf(0.0, rect.size.y - r * 2.0))), color)
	draw_circle(rect.position + Vector2(r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)


func draw_round_outline(rect: Rect2, radius: float, color: Color, width: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_line(Vector2(rect.position.x + r, rect.position.y), Vector2(rect.end.x - r, rect.position.y), color, width, true)
	draw_line(Vector2(rect.position.x + r, rect.end.y), Vector2(rect.end.x - r, rect.end.y), color, width, true)
	draw_line(Vector2(rect.position.x, rect.position.y + r), Vector2(rect.position.x, rect.end.y - r), color, width, true)
	draw_line(Vector2(rect.end.x, rect.position.y + r), Vector2(rect.end.x, rect.end.y - r), color, width, true)
	draw_arc(rect.position + Vector2(r, r), r, PI, PI * 1.5, 12, color, width, true)
	draw_arc(Vector2(rect.end.x - r, rect.position.y + r), r, PI * 1.5, TAU, 12, color, width, true)
	draw_arc(Vector2(rect.end.x - r, rect.end.y - r), r, 0.0, PI * 0.5, 12, color, width, true)
	draw_arc(Vector2(rect.position.x + r, rect.end.y - r), r, PI * 0.5, PI, 12, color, width, true)
