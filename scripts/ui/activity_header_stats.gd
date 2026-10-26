extends RefCounted

# Authored source rectangles for static symbols, independent of animation frames.
const REGIONS := {
	"infochip-symbol-xp-outlined.png": Rect2(22,76,465,315),
	"infochip-symbol-stamina-outlined.png": Rect2(108,32,298,411),
	"infochip-symbol-time-outlined.png": Rect2(93,40,325,403),
	"sand.png": Rect2(40,111,451,382),
}
const ICON_GAP := 4.0
const STAT_GAP := 18.0

static func compact_texture(texture: Texture2D) -> Texture2D:
	var region: Rect2 = REGIONS.get(texture.resource_path.get_file(),Rect2())
	if region.size == Vector2.ZERO: return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

static func layout(values: Array[Dictionary],font: Font,font_size: int,right: float,baseline: float) -> Array[Dictionary]:
	var width := maxf(0,values.size()-1)*STAT_GAP
	for item in values:
		item.icon = compact_texture(item.icon)
		item["icon_size"] = Vector2(float(font_size)*item.icon.get_width()/item.icon.get_height(),font_size)
		item["icon_width"] = item.icon_size.x
		item["width"] = item.icon_size.x+ICON_GAP+font.get_string_size(item.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		width += float(item.width)
	var x := right-width
	for item in values:
		item["position"] = Vector2(x,baseline)
		x += float(item.width)+STAT_GAP
	return values

static func fit_symbol(symbol: TextureRect,font_size: int) -> void:
	symbol.texture = compact_texture(symbol.texture)
	symbol.material = null
	symbol.custom_minimum_size = Vector2(float(font_size)*symbol.texture.get_width()/symbol.texture.get_height(),font_size)
	var row := symbol.get_parent() as BoxContainer
	if row != null: row.add_theme_constant_override("separation",int(ICON_GAP))
