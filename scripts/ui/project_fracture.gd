extends Control

# All visible damage and debris are ImageGen sprites. This node only moves them.
var material_id := "timber"
var stage := 0
var age := 1.0
var chips: Array = []
var frames: Array[Texture2D] = []
var chip_texture: Texture2D
var cover: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	if material_id in ["timber", "stone"]:
		# Original generated broad slabs, each with a fixed authored atlas cell.
		var sheet: Texture2D = load("res://assets/content/ui/project-%s-states.png" % material_id)
		for index in range(3):
			var frame := AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(0, index * 230, 768, 230)
			frames.append(frame)
	else:
		for index in range(4):
			frames.append(load("res://assets/content/ui/project-damage-%s-%d.png" % [material_id, index]))
	chip_texture = load("res://assets/content/ui/project-chip-%s.png" % material_id)
	cover = TextureRect.new()
	cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	cover.texture = frames[stage]
	resized.connect(_layout_cover)
	_layout_cover()

func set_stage(next: int, animate: bool) -> void:
	next = clampi(next, 0, frames.size() - 1)
	if next == stage: return
	stage = next
	if is_instance_valid(cover): cover.texture = frames[stage]
	_clear_chips()
	age = 0.0 if animate and is_visible_in_tree() else 1.0
	if age == 0.0:
		var rect := _art_rect()
		for i in range(6):
			var side := -1.0 if i % 2 == 0 else 1.0
			var sprite := TextureRect.new()
			sprite.texture = chip_texture
			sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite.size = Vector2(48, 48)
			sprite.pivot_offset = sprite.size * 0.5
			add_child(sprite)
			var origin := rect.position + rect.size * Vector2(0.23 if side < 0 else 0.77, 0.3 + (i % 3) * 0.17)
			sprite.position = origin - sprite.pivot_offset
			chips.append({"sprite": sprite, "origin": sprite.position, "velocity": Vector2(side * (65 + (i % 3) * 28), -125 - (i % 3) * 35), "spin": side * (2.0 + i % 3)})
	set_process(age < 0.7)

func last_stage() -> int:
	return maxi(1, frames.size() - 1)

func _art_rect() -> Rect2:
	# Size from the module width, never from alpha bounds or the current damage.
	var canvas := Vector2(768, 230) if material_id in ["timber", "stone"] else Vector2(418, 220)
	var draw_width := size.x + 48.0
	var draw_size := Vector2(draw_width, draw_width * canvas.y / canvas.x)
	return Rect2((size - draw_size) * 0.5, draw_size)

func _layout_cover() -> void:
	if not is_instance_valid(cover): return
	var rect := _art_rect()
	cover.position = rect.position
	cover.size = rect.size

func _clear_chips() -> void:
	for chip in chips:
		if is_instance_valid(chip.sprite):
			chip.sprite.hide()
			chip.sprite.queue_free()
	chips.clear()

func _process(delta: float) -> void:
	age += delta
	if age >= 0.7 or not is_visible_in_tree():
		_clear_chips()
		age = 1.0
		set_process(false)
		return
	for chip in chips:
		chip.sprite.position = chip.origin + chip.velocity * age + Vector2(0, 380 * age * age)
		chip.sprite.rotation = age * chip.spin
		chip.sprite.modulate.a = clampf((0.7 - age) / 0.22, 0, 1)
