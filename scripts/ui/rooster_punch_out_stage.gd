class_name RoosterPunchOutStage
extends Control

signal stamina_damage(amount: int)

const INK := Color("#171615")
const ROOSTER_IDLE_PATH := "res://assets/content/fight/boss/rooster-idle.png"
const ROOSTER_HIT_PATH := "res://assets/content/fight/boss/rooster-hit.png"
const ROOSTER_ATTACK_PATH := "res://assets/content/fight/boss/rooster-attack.png"
const ROOSTER_DIZZY_PATH := "res://assets/content/fight/boss/rooster-dizzy.png"
const HAND_GUARD_LEFT_PATH := "res://assets/content/fight/boss/blue-hand-guard-left.png"
const HAND_GUARD_RIGHT_PATH := "res://assets/content/fight/boss/blue-hand-guard-right.png"
const HAND_PUNCH_LEFT_PATH := "res://assets/content/fight/boss/blue-hand-punch-left.png"
const HAND_PUNCH_RIGHT_PATH := "res://assets/content/fight/boss/blue-hand-punch-right.png"
const FARM_BACKGROUND_PATH := "res://assets/content/fight/backgrounds/02-rising.png"
const ROOSTER_MAX_HP := 120.0
const PLAYER_FALLBACK_STAMINA := 42.0
const ROOSTER_ATTACK_SECONDS := 1.85
const ROOSTER_DODGE_CHANCE := 0.22

var state := "idle"
var elapsed := 0.0
var rooster_hp := ROOSTER_MAX_HP
var player_stamina := PLAYER_FALLBACK_STAMINA
var rooster_attack_timer := 1.10
var punch_timer := 0.0
var punch_side := "left"
var hit_timer := 0.0
var dodge_timer := 0.0
var attack_timer := 0.0
var player_hit_flash := 0.0
var reset_timer := 0.0
var lost_fight := false
var cover_close_amount := 0.0
var floaters: Array[Dictionary] = []
var farm_background: Texture2D
var rooster_idle: Texture2D
var rooster_hit: Texture2D
var rooster_attack: Texture2D
var rooster_dizzy: Texture2D
var hand_guard_left: Texture2D
var hand_guard_right: Texture2D
var hand_punch_left: Texture2D
var hand_punch_right: Texture2D
var active_fight := false


func _ready() -> void:
	_sync_mouse_filter()
	clip_contents = true
	farm_background = _load_png_texture(FARM_BACKGROUND_PATH)
	rooster_idle = _load_png_texture(ROOSTER_IDLE_PATH)
	rooster_hit = _load_png_texture(ROOSTER_HIT_PATH)
	rooster_attack = _load_png_texture(ROOSTER_ATTACK_PATH)
	rooster_dizzy = _load_png_texture(ROOSTER_DIZZY_PATH)
	hand_guard_left = _load_png_texture(HAND_GUARD_LEFT_PATH)
	hand_guard_right = _load_png_texture(HAND_GUARD_RIGHT_PATH)
	hand_punch_left = _load_png_texture(HAND_PUNCH_LEFT_PATH)
	hand_punch_right = _load_png_texture(HAND_PUNCH_RIGHT_PATH)
	set_process(active_fight)


func set_active_fight(active: bool) -> void:
	active_fight = active
	_sync_mouse_filter()
	set_process(active_fight)
	queue_redraw()


func _sync_mouse_filter() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if active_fight else Control.MOUSE_FILTER_IGNORE


func setup_player_stamina(current_stamina: float) -> void:
	player_stamina = maxf(0.0, current_stamina)
	if player_stamina > 0.0 and lost_fight:
		_reset_fight()
	elif player_stamina <= 0.0:
		close_after_stamina_loss()


func close_after_stamina_loss() -> void:
	if lost_fight:
		return
	lost_fight = true
	player_stamina = 0.0
	punch_timer = 0.0
	attack_timer = 0.0
	reset_timer = 0.0


func _process(delta: float) -> void:
	if not active_fight:
		return
	elapsed += delta
	_step_fight(minf(delta, 0.05))
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not active_fight:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_start_player_punch("left" if (event as InputEventMouseButton).position.x < size.x * 0.5 else "right", true)
		accept_event()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_start_player_punch("left" if (event as InputEventScreenTouch).position.x < size.x * 0.5 else "right", true)
		accept_event()


func _step_fight(delta: float) -> void:
	_update_floaters(delta)
	punch_timer = maxf(0.0, punch_timer - delta)
	hit_timer = maxf(0.0, hit_timer - delta)
	dodge_timer = maxf(0.0, dodge_timer - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	player_hit_flash = maxf(0.0, player_hit_flash - delta * 2.6)
	if lost_fight:
		cover_close_amount = move_toward(cover_close_amount, 1.0, delta * 3.2)
		state = _visual_state()
		return
	cover_close_amount = move_toward(cover_close_amount, 0.0, delta * 2.0)
	if rooster_hp <= 0.0:
		reset_timer -= delta
		if reset_timer <= 0.0:
			_reset_fight()
		return
	rooster_attack_timer -= delta
	if rooster_attack_timer <= 0.0:
		_start_rooster_attack()
		rooster_attack_timer = ROOSTER_ATTACK_SECONDS + randf() * 0.55
	state = _visual_state()


func _start_player_punch(side: String, manual: bool) -> void:
	if punch_timer > 0.08 or rooster_hp <= 0.0 or lost_fight:
		return
	punch_side = side
	punch_timer = 0.24 if manual else 0.18
	if randf() < ROOSTER_DODGE_CHANCE and attack_timer <= 0.0:
		dodge_timer = 0.28
		_add_floater("DODGE", Vector2(size.x * 0.5, size.y * 0.34), Color("#fff1bd"), 0.60)
		return
	var damage := randi_range(7, 11) + (2 if manual else 0)
	rooster_hp = maxf(0.0, rooster_hp - float(damage))
	hit_timer = 0.22
	_add_floater("-%d" % damage, Vector2(size.x * 0.52, size.y * 0.31), Color("#ffe56b"), 0.68)
	if rooster_hp <= 0.0:
		reset_timer = 1.45
		_add_floater("KO", Vector2(size.x * 0.5, size.y * 0.25), Color("#fff1bd"), 0.92)


func _start_rooster_attack() -> void:
	if rooster_hp <= 0.0 or lost_fight:
		return
	attack_timer = 0.34
	var damage := randi_range(5, 8)
	player_stamina = maxf(0.0, player_stamina - float(damage))
	stamina_damage.emit(damage)
	player_hit_flash = 1.0
	_add_floater("-%d" % damage, Vector2(size.x * 0.50, size.y * 0.68), Color("#ff5748"), 0.66)
	if player_stamina <= 0.0:
		close_after_stamina_loss()


func _reset_fight() -> void:
	rooster_hp = ROOSTER_MAX_HP
	rooster_attack_timer = 1.10
	punch_timer = 0.0
	hit_timer = 0.0
	dodge_timer = 0.0
	attack_timer = 0.0
	player_hit_flash = 0.0
	reset_timer = 0.0
	lost_fight = false
	cover_close_amount = 0.0


func _visual_state() -> String:
	if lost_fight:
		return "attack"
	if rooster_hp <= 0.0:
		return "dizzy"
	if attack_timer > 0.0:
		return "attack"
	if hit_timer > 0.0:
		return "hit"
	return "idle"


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x < 4.0 or size.y < 4.0:
		return
	var stage := Rect2(Vector2.ZERO, size)
	var play_area := stage.grow(-18.0)
	_draw_backdrop(stage)
	_draw_boss_hp_bar(stage)
	_draw_rooster_sprite(play_area)
	_draw_hand_sprite(Vector2(size.x * 0.30, size.y * 0.92), hand_punch_left if punch_timer > 0.0 and punch_side == "left" else hand_guard_left, punch_timer > 0.0 and punch_side == "left")
	_draw_hand_sprite(Vector2(size.x * 0.70, size.y * 0.92), hand_punch_right if punch_timer > 0.0 and punch_side == "right" else hand_guard_right, punch_timer > 0.0 and punch_side == "right")
	_draw_floaters()
	if player_hit_flash > 0.0:
		_draw_rounded_rect(stage, 66.0, Color(1.0, 0.0, 0.0, 0.26 * player_hit_flash))
	if cover_close_amount > 0.0:
		_draw_defeat_cover(stage)


func _draw_boss_hp_bar(r: Rect2) -> void:
	var bar_height := clampf(r.size.y * 0.135, 44.0, 54.0)
	var rail := Rect2(r.position + Vector2(22.0, 32.0), Vector2(r.size.x - 44.0, bar_height))
	var radius := rail.size.y * 0.5
	_draw_rounded_rect(Rect2(rail.position + Vector2(0, 5), rail.size), radius, Color(0, 0, 0, 0.26))
	_draw_rounded_rect(rail, radius, Color("#3b0708"))
	_draw_rounded_rect(Rect2(rail.position, Vector2(rail.size.x * clampf(rooster_hp / ROOSTER_MAX_HP, 0.0, 1.0), rail.size.y)), radius, Color("#e3342e"))


func _draw_backdrop(r: Rect2) -> void:
	if farm_background != null:
		_draw_rounded_texture_cover(farm_background, r, 66.0)
	else:
		_draw_rounded_rect(r, 66.0, Color("#7bc55d"))


func _draw_rooster_sprite(r: Rect2) -> void:
	var texture := rooster_idle
	if state == "hit":
		texture = rooster_hit
	elif state == "attack":
		texture = rooster_attack
	elif state == "dizzy":
		texture = rooster_dizzy
	if texture == null:
		return
	var center := r.position + Vector2(r.size.x * 0.5, r.size.y * 0.58)
	if state == "hit":
		center += Vector2(40.0, -18.0)
	elif state == "attack":
		center += Vector2(0.0, 12.0)
	elif dodge_timer > 0.0:
		center += Vector2(sin(elapsed * 28.0) * 42.0, -10.0)
	var draw_size := Vector2(r.size.x * 0.88, r.size.y * 1.22)
	if state == "attack":
		draw_size = Vector2(r.size.x * 0.92, r.size.y * 1.18)
	elif state == "hit":
		draw_size = Vector2(r.size.x * 0.90, r.size.y * 1.18)
	_draw_texture_fit(texture, Rect2(center - draw_size * 0.5, draw_size))


func _draw_hand_sprite(base: Vector2, texture: Texture2D, punching: bool) -> void:
	if texture == null:
		return
	var draw_size := Vector2(size.x * 0.34, size.y * 0.30)
	var offset := Vector2(0.0, 0.0)
	if punching:
		draw_size = Vector2(size.x * 0.48, size.y * 0.34)
		offset = Vector2(0.0, -size.y * 0.22)
	_draw_texture_fit(texture, Rect2(base + offset - draw_size * 0.5, draw_size))


func _draw_defeat_cover(r: Rect2) -> void:
	var t := clampf(cover_close_amount, 0.0, 1.0)
	var panel_height := r.size.y * 0.56
	var top := Rect2(r.position + Vector2(0.0, -panel_height + panel_height * t), Vector2(r.size.x, panel_height + 12.0))
	var bottom := Rect2(r.position + Vector2(0.0, r.size.y - panel_height * t), Vector2(r.size.x, panel_height + 12.0))
	_draw_rounded_rect(top, 60.0, Color("#7f1118"))
	_draw_rounded_rect(Rect2(top.position + Vector2(0.0, top.size.y - 24.0), Vector2(top.size.x, 24.0)), 0.0, Color("#4b070a"))
	_draw_rounded_rect(bottom, 60.0, Color("#6e0d14"))
	_draw_rounded_rect(Rect2(bottom.position, Vector2(bottom.size.x, 24.0)), 0.0, Color("#b91c25"))


func _add_floater(text: String, position: Vector2, color: Color, lifetime: float) -> void:
	floaters.append({"text": text, "pos": position, "color": color, "life": lifetime, "max": lifetime})


func _update_floaters(delta: float) -> void:
	for i in range(floaters.size() - 1, -1, -1):
		var floater := floaters[i]
		floater["life"] = float(floater.get("life", 0.0)) - delta
		if float(floater["life"]) <= 0.0:
			floaters.remove_at(i)
		else:
			floaters[i] = floater


func _draw_floaters() -> void:
	for floater in floaters:
		var life := float(floater.get("life", 0.0))
		var max_life := maxf(0.01, float(floater.get("max", 0.5)))
		var t := 1.0 - life / max_life
		var pos := floater.get("pos", Vector2.ZERO) as Vector2
		pos += Vector2(0.0, -58.0 * t)
		var color := floater.get("color", Color.WHITE) as Color
		color.a = clampf(1.0 - t * 0.75, 0.0, 1.0)
		_draw_center_text(str(floater.get("text", "")), pos, 54, color, Color("#171615"))


func _draw_center_text(text: String, pos: Vector2, font_size: int, color: Color, outline: Color) -> void:
	var font := ThemeDB.fallback_font
	var origin := pos - Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x * 0.5, 0.0)
	for offset in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4), Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(3, 3)]:
		draw_string(font, origin + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, outline)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _draw_texture_fit(texture: Texture2D, rect: Rect2) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale := minf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var fitted := texture_size * scale
	draw_texture_rect(texture, Rect2(rect.get_center() - fitted * 0.5, fitted), false)


func _draw_texture_cover(texture: Texture2D, rect: Rect2) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale := maxf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var fitted := texture_size * scale
	draw_texture_rect(texture, Rect2(rect.get_center() - fitted * 0.5, fitted), false)


func _draw_rounded_texture_cover(texture: Texture2D, rect: Rect2, radius: float) -> void:
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		_draw_rounded_rect(rect, radius, Color("#7bc55d"))
		return
	_draw_rounded_rect(rect, radius, Color("#7bc55d"))
	var scale := maxf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var fitted := texture_size * scale
	var source_rect := Rect2((texture_size - rect.size / scale) * 0.5, rect.size / scale)
	var rows := 42
	for i in range(rows):
		var top := rect.size.y * float(i) / float(rows)
		var bottom := rect.size.y * float(i + 1) / float(rows)
		var mid_y := (top + bottom) * 0.5
		var inset := _rounded_rect_row_inset(mid_y, rect.size, radius)
		var dest := Rect2(rect.position + Vector2(inset, top), Vector2(maxf(0.0, rect.size.x - inset * 2.0), bottom - top + 1.0))
		if dest.size.x <= 0.0:
			continue
		var source := Rect2(source_rect.position + Vector2(inset / scale, top / scale), dest.size / scale)
		draw_texture_rect_region(texture, dest, source)


func _draw_rounded_rect(rect: Rect2, radius: float, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	draw_style_box(style, rect)


func _rounded_rect_row_inset(local_y: float, rect_size: Vector2, radius: float) -> float:
	var r := minf(radius, minf(rect_size.x, rect_size.y) * 0.5)
	if local_y < r:
		var dy := r - local_y
		return r - sqrt(maxf(0.0, r * r - dy * dy))
	if local_y > rect_size.y - r:
		var dy := local_y - (rect_size.y - r)
		return r - sqrt(maxf(0.0, r * r - dy * dy))
	return 0.0


func _load_png_texture(path: String) -> Texture2D:
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
