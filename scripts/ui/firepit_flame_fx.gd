extends Control

const FLAME_ATLAS_PATH := "res://assets/content/woodcutting/modules/woodcutting-firepit-flame-sheet.png"
const SMOKE_ATLAS_PATH := "res://assets/content/woodcutting/modules/woodcutting-firepit-smoke-sheet.png"
const FRAME_COUNT := 4
const SMOKE_FRAME_COUNT := 8
const FLAME_CELL_SIZE := Vector2(512, 512)
const SMOKE_CELL_SIZE := Vector2(256, 256)
const FRAME_SEQUENCE := [0, 1, 2, 3]
const FRAME_DURATION_SECONDS := 1.5
const SMOKE_PUFF_COUNT := 4
const FLAME_WARBLE_SHADER := """
shader_type canvas_item;
uniform float heat = 0.0;
void fragment() {
	vec2 uv = UV;
	float sway = sin(TIME * 2.4 + uv.y * 8.0) * 0.006;
	float flutter = sin(TIME * 3.7 + uv.y * 15.0) * 0.003;
	uv.x += (sway + flutter) * heat * smoothstep(0.16, 0.92, uv.y);
	COLOR = texture(TEXTURE, uv) * COLOR;
}
"""

var active := false
var heat := 0.0
var sequence_index := 0
var frame_elapsed := 0.0
var frame_textures: Array[Texture2D] = []
var smoke_textures: Array[Texture2D] = []
var flame_rect: TextureRect
var flame_material: ShaderMaterial
var smoke_puffs: Array[TextureRect] = []


func set_active(next_active: bool) -> void:
	if active == next_active:
		if active and not is_processing():
			set_process(true)
		return
	active = next_active
	set_process(active or heat > 0.01)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_frame_textures()
	flame_rect = TextureRect.new()
	flame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flame_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flame_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	flame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flame_rect.z_index = 1
	_build_flame_material()
	if flame_material != null:
		flame_rect.material = flame_material
	add_child(flame_rect)
	_build_smoke_puffs()
	_apply_frame(0)
	_sync_visual_transform()
	set_process(active or heat > 0.01)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and flame_rect != null:
		flame_rect.pivot_offset = size * Vector2(0.5, 0.80)


func _build_flame_material() -> void:
	var shader := Shader.new()
	shader.code = FLAME_WARBLE_SHADER
	flame_material = ShaderMaterial.new()
	flame_material.shader = shader


func _process(delta: float) -> void:
	var target := 1.0 if active else 0.0
	heat = lerpf(heat, target, 1.0 - exp(-delta * 5.0))
	if active:
		_advance_frame(delta)
	_sync_visual_transform()
	if not active and heat <= 0.01:
		heat = 0.0
		set_process(false)


func _build_frame_textures() -> void:
	frame_textures.clear()
	var atlas := load(FLAME_ATLAS_PATH) as Texture2D
	if atlas == null:
		return
	for frame_index in range(FRAME_COUNT):
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(Vector2(float(frame_index) * FLAME_CELL_SIZE.x, 0.0), FLAME_CELL_SIZE)
		frame.filter_clip = true
		frame_textures.append(frame)


func _advance_frame(delta: float) -> void:
	if frame_textures.is_empty():
		return
	frame_elapsed += maxf(0.0, delta)
	var guard := 0
	while guard < 8 and frame_elapsed >= _current_duration():
		frame_elapsed -= _current_duration()
		sequence_index = (sequence_index + 1) % FRAME_SEQUENCE.size()
		_apply_frame(sequence_index)
		guard += 1


func _current_duration() -> float:
	return FRAME_DURATION_SECONDS


func _apply_frame(next_sequence_index: int) -> void:
	if flame_rect == null or frame_textures.is_empty():
		return
	sequence_index = clampi(next_sequence_index, 0, FRAME_SEQUENCE.size() - 1)
	var frame_index := clampi(int(FRAME_SEQUENCE[sequence_index]), 0, frame_textures.size() - 1)
	flame_rect.texture = frame_textures[frame_index]


func _build_smoke_puffs() -> void:
	smoke_puffs.clear()
	_build_smoke_textures()
	if smoke_textures.is_empty():
		return
	for index in range(SMOKE_PUFF_COUNT):
		var puff := TextureRect.new()
		puff.texture = smoke_textures[index % smoke_textures.size()]
		puff.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		puff.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		puff.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		puff.mouse_filter = Control.MOUSE_FILTER_IGNORE
		puff.z_index = 2
		add_child(puff)
		smoke_puffs.append(puff)


func _build_smoke_textures() -> void:
	smoke_textures.clear()
	var atlas := load(SMOKE_ATLAS_PATH) as Texture2D
	if atlas == null:
		return
	for frame_index in range(SMOKE_FRAME_COUNT):
		var frame := AtlasTexture.new()
		frame.atlas = atlas
		frame.region = Rect2(Vector2(float(frame_index) * SMOKE_CELL_SIZE.x, 0.0), SMOKE_CELL_SIZE)
		frame.filter_clip = true
		smoke_textures.append(frame)


func _sync_visual_transform() -> void:
	if flame_rect == null:
		return
	var t := float(Time.get_ticks_msec()) / 1000.0
	flame_rect.modulate = Color(1.0, 1.0, 1.0, clampf(heat, 0.0, 1.0))
	flame_rect.pivot_offset = size * Vector2(0.5, 0.80)
	var warm_scale := 0.96 + sin(t * 2.1) * 0.012 * heat
	var side_scale := 1.0 + sin(t * 2.8 + 0.6) * 0.018 * heat
	var height_scale := 1.0 + sin(t * 2.4 + 1.1) * 0.014 * heat
	flame_rect.scale = Vector2(warm_scale * side_scale, warm_scale * height_scale)
	flame_rect.rotation = sin(t * 1.7 + 0.4) * 0.018 * heat
	if flame_material != null:
		flame_material.set_shader_parameter("heat", clampf(heat, 0.0, 1.0))
	_sync_smoke_puffs(t)


func _sync_smoke_puffs(t: float) -> void:
	if smoke_puffs.is_empty():
		return
	var base := size * Vector2(0.5, 0.44)
	for index in range(smoke_puffs.size()):
		var puff := smoke_puffs[index]
		var phase := float(index) * 0.23
		var cycle := fmod(t * (0.12 + float(index % 2) * 0.025) + phase, 1.0)
		var fade := sin(cycle * PI)
		var lane := float(index) - float(smoke_puffs.size() - 1) * 0.5
		var side := lane * 52.0 + sin(t * 0.95 + float(index) * 1.7) * 28.0
		var rise := cycle * (220.0 + float(index % 2) * 28.0)
		var puff_size := 178.0 + cycle * 126.0 + float(index % 2) * 28.0
		puff.size = Vector2(puff_size, puff_size)
		puff.position = base + Vector2(side, -rise + 24.0) - puff.size * 0.5
		puff.pivot_offset = puff.size * 0.5
		puff.rotation = sin(t * 0.58 + float(index)) * 0.13
		puff.scale = Vector2.ONE * (0.9 + cycle * 0.18)
		puff.modulate = Color(1.0, 1.0, 1.0, clampf(heat * fade * 0.36, 0.0, 0.36))
