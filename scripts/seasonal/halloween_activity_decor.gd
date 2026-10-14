extends Control

# All illustration and walking poses are ImageGen sprites. Geometry only places them.
var web_left: TextureRect
var web_right: TextureRect
var garland: TextureRect
var spider: TextureRect
var spider_frames: Array[AtlasTexture] = []
var elapsed := 0.0
var last_frame := -1

func _ready() -> void:
	name = "HalloweenActivityDecor"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 240
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sheet := load("res://assets/content/events/halloween/decorations.png") as Texture2D
	web_left = _sprite(sheet, 0, Vector2(120, 120))
	web_right = _sprite(sheet, 1, Vector2(150, 150))
	garland = _sprite(sheet, 2, Vector2(260, 130))
	for cell in range(3, 6): spider_frames.append(_cell(sheet, cell))
	spider = _sprite(sheet, 3, Vector2(68, 68))
	spider.pivot_offset = spider.size * 0.5
	resized.connect(_layout)
	_layout()

func _cell(sheet: Texture2D, cell: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2((cell % 3) * 512, (cell / 3) * 512, 512, 512)
	atlas.filter_clip = true
	return atlas

func _sprite(sheet: Texture2D, cell: int, draw_size: Vector2) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture = _cell(sheet, cell)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = draw_size
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sprite)
	return sprite

func _layout() -> void:
	if web_left == null: return
	web_left.position = Vector2(-18, -24)
	web_right.position = Vector2(size.x - 128, -28)
	garland.position = Vector2(size.x * 0.5 - 130, size.y - 74)
	_move_spider()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not get_global_rect().intersects(get_viewport_rect()): return
	elapsed += minf(delta, 0.05)
	var frame := int(elapsed * 6.0) % 3
	if frame != last_frame:
		spider.texture = spider_frames[frame]
		last_frame = frame
	_move_spider()

func _move_spider() -> void:
	if spider == null: return
	var phase := fmod(elapsed, 12.0) / 12.0
	var travel := (1.0 - cos(phase * TAU)) * 0.5
	spider.position = Vector2(size.x - 40, lerpf(70.0, maxf(70.0, size.y - 70.0), travel))
	spider.rotation = PI if phase < 0.5 else 0.0
