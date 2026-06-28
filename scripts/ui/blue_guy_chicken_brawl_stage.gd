extends "res://scripts/ui/fighting_module_stage.gd"

signal chicken_killed(xp_amount: int)
signal punch_landed
signal knocked_out

const INK := Color("#171615")
const PAPER := Color("#fff1bd")
const BAR_EMPTY := Color("#3f2b25")
const HERO_HP_BLUE := Color("#4fc3ff")
const CHICKEN_HP := Color("#ffcf35")
const DANGER := Color("#ee4b38")
const XP_GOLD := Color("#ffe56b")
const WHITE := Color("#fffaf0")

const ARENA_FLOOR_PATH := "res://assets/content/fight/prototype/arena-floor.png"
const CHICKEN_IDLE_PATH := "res://assets/content/fight/prototype/chicken-idle.png"
const CHICKEN_COVER_CLEAN_PATH := "res://assets/content/fight/prototype/chicken-cover-clean.png"
const CHICKEN_HIT_PATH := "res://assets/content/fight/prototype/chicken-hit.png"
const CHICKEN_DIZZY_PATH := "res://assets/content/fight/prototype/chicken-dizzy.png"
const CHICKEN_DEFEATED_PATH := "res://assets/content/fight/prototype/chicken-defeated.png"
const CHICKEN_GRAY_IDLE_PATH := "res://assets/content/fight/prototype/chicken-gray-idle.png"
const CHICKEN_GRAY_HIT_PATH := "res://assets/content/fight/prototype/chicken-gray-hit.png"
const CHICKEN_GRAY_DIZZY_PATH := "res://assets/content/fight/prototype/chicken-gray-dizzy.png"
const CHICKEN_GRAY_DEFEATED_PATH := "res://assets/content/fight/prototype/chicken-gray-defeated.png"
const CHICKEN_BLACK_IDLE_PATH := "res://assets/content/fight/prototype/chicken-black-idle.png"
const CHICKEN_BLACK_HIT_PATH := "res://assets/content/fight/prototype/chicken-black-hit.png"
const CHICKEN_BLACK_DIZZY_PATH := "res://assets/content/fight/prototype/chicken-black-dizzy.png"
const CHICKEN_BLACK_DEFEATED_PATH := "res://assets/content/fight/prototype/chicken-black-defeated.png"
const BLUE_GUY_PUNCH_PATH := "res://assets/content/fight/prototype/blue-guy-punch.png"
const BLUE_GUY_GUARD_PATH := "res://assets/content/fight/prototype/blue-guy-guard.png"
const BLUE_GUY_KO_PATH := "res://assets/content/fight/prototype/blue-guy-ko.png"
const BLUE_GUY_UPPERCUT_PATH := "res://assets/content/fight/prototype/blue-guy-uppercut.png"
const COOKED_CHICKEN_DROP_PATH := "res://assets/content/fight/prototype/cooked-chicken-drop.png"

const HERO_BASE_MAX_HP := 33.0
const HERO_BASE_ATTACK_DAMAGE_MIN := 8.0
const HERO_BASE_ATTACK_DAMAGE_MAX := 11.0
const HERO_BASE_UPPERCUT_DAMAGE_MIN := 22.0
const HERO_BASE_UPPERCUT_DAMAGE_MAX := 30.0
const HERO_BASE_ATTACK_INTERVAL := 1.05
const HERO_LEVEL_MULT := 1.03
const HERO_STAT_BASELINE_LEVEL := 5
const HERO_HITBOX_RANGE := 0.205
const HERO_HITBOX_RADIUS := 0.142
const HERO_UPPERCUT_RANGE := 0.315
const HERO_UPPERCUT_RADIUS := 0.205
const HERO_UPPERCUT_CHANCE := 0.13
const HERO_UPPERCUT_COOLDOWN := 3.4
const CHICKEN_UPPERCUT_KNOCK_SECONDS := 0.46
const CHICKEN_UPPERCUT_KNOCK_SPEED := 0.54
const HIT_STOP_SECONDS := 0.055
const UPPERCUT_HIT_STOP_SECONDS := 0.095
const UPPERCUT_SHAKE_SECONDS := 0.22
const CHICKEN_BASE_HP_MIN := 34.0
const CHICKEN_BASE_HP_MAX := 42.0
const CHICKEN_DAMAGE := 8.0
const CHICKEN_ATTACK_RANGE := 0.145
const MAX_CHICKENS := 7
const WAVE_START_DELAY := 0.22
const NORMAL_WAVE_COUNT := 5
const END_WAVE_TOTAL := 34
const END_WAVE_MAX_CHICKENS := 24
const END_WAVE_SOFT_KILL_SECONDS := 1.55
const END_WAVE_SPAWN_INTERVAL := 0.055
const END_WAVE_CLEAR_BONUS_XP := 100
const AREA_CLEAR_RESTART_DELAY := 1.45
const HERO_KO_DURATION := 3.4
const HERO_KO_FADE_SECONDS := 0.48
const HERO_KO_FALL_SECONDS := 0.52
const HERO_KO_STAND_SECONDS := 0.62
const COVER_OPEN_SPEED := 4.8
const COOKED_CHICKEN_DROP_CHANCE := 0.07
const COOKED_CHICKEN_HEAL_RATIO := 0.16
const COOKED_CHICKEN_PICKUP_RADIUS := 0.12
const COOKED_CHICKEN_LIFETIME := 8.0
const COOKED_CHICKEN_CONSUME_SECONDS := 0.62

var elapsed_seconds := 0.0
var arena_floor: Texture2D
var idle_chicken: Texture2D
var cover_clean_chicken: Texture2D
var hit_chicken: Texture2D
var dizzy_chicken: Texture2D
var defeated_chicken: Texture2D
var gray_idle_chicken: Texture2D
var gray_hit_chicken: Texture2D
var gray_dizzy_chicken: Texture2D
var gray_defeated_chicken: Texture2D
var black_idle_chicken: Texture2D
var black_hit_chicken: Texture2D
var black_dizzy_chicken: Texture2D
var black_defeated_chicken: Texture2D
var blue_guy_punch: Texture2D
var blue_guy_guard: Texture2D
var blue_guy_ko: Texture2D
var blue_guy_uppercut: Texture2D
var cooked_chicken_drop: Texture2D

var title_label: Label
var ko_label: Label
var ko_timer_label: Label
var float_labels: Array[Label] = []

var hero_pos := Vector2(0.5, 0.55)
var hero_hp := HERO_BASE_MAX_HP
var hero_attack_cd := 0.16
var hero_attack_timer := 0.0
var hero_uppercut_cd := 1.2
var hero_attack_is_uppercut := false
var hero_attack_dir := Vector2.RIGHT
var hero_facing := 1
var hero_ko_timer := 0.0
var spawn_timer := 0.0
var chicken_serial := 0
var chickens: Array[Dictionary] = []
var food_drops: Array[Dictionary] = []
var feather_particles: Array[Dictionary] = []
var smoke_puffs: Array[Dictionary] = []
var ko_count := 0
var wave_index := 0
var wave_kills := 0
var wave_spawn_total := 0
var wave_spawn_remaining := 0
var wave_spawned_count := 0
var wave_start_delay_current := WAVE_START_DELAY
var wave_rest_timer := 0.0
var wave_rest_duration_current := 0.0
var wave_elapsed_current := 0.0
var wave_duration_current := 1.0
var wave_spawn_phase_duration_current := 1.0
var displayed_wave_progress := 0.0
var end_wave_active := false
var end_wave_soft_kill_timer := 0.0
var area_clear_restart_timer := 0.0
var fighting_level := 1
var cover_health_current := 30
var cover_health_maximum := 30
var cover_health_regen_fraction := 1.0
var active := false
var cover_open_amount := 0.0
var hit_stop_timer := 0.0
var module_shake_timer := 0.0
var module_shake_duration := 0.0
var module_shake_strength := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	clip_contents = true
	arena_floor = load_png_texture(ARENA_FLOOR_PATH)
	idle_chicken = load_png_texture(CHICKEN_IDLE_PATH)
	cover_clean_chicken = load_png_texture(CHICKEN_COVER_CLEAN_PATH)
	hit_chicken = load_png_texture(CHICKEN_HIT_PATH)
	dizzy_chicken = load_png_texture(CHICKEN_DIZZY_PATH)
	defeated_chicken = load_png_texture(CHICKEN_DEFEATED_PATH)
	gray_idle_chicken = load_png_texture(CHICKEN_GRAY_IDLE_PATH)
	gray_hit_chicken = load_png_texture(CHICKEN_GRAY_HIT_PATH)
	gray_dizzy_chicken = load_png_texture(CHICKEN_GRAY_DIZZY_PATH)
	gray_defeated_chicken = load_png_texture(CHICKEN_GRAY_DEFEATED_PATH)
	black_idle_chicken = load_png_texture(CHICKEN_BLACK_IDLE_PATH)
	black_hit_chicken = load_png_texture(CHICKEN_BLACK_HIT_PATH)
	black_dizzy_chicken = load_png_texture(CHICKEN_BLACK_DIZZY_PATH)
	black_defeated_chicken = load_png_texture(CHICKEN_BLACK_DEFEATED_PATH)
	blue_guy_punch = load_png_texture(BLUE_GUY_PUNCH_PATH)
	blue_guy_guard = load_png_texture(BLUE_GUY_GUARD_PATH)
	blue_guy_ko = load_png_texture(BLUE_GUY_KO_PATH)
	blue_guy_uppercut = load_png_texture(BLUE_GUY_UPPERCUT_PATH)
	cooked_chicken_drop = load_png_texture(COOKED_CHICKEN_DROP_PATH)
	_ensure_labels()
	if active:
		_seed_fight()
	else:
		_seed_inactive_state()
	set_process(true)


func setup_fighting_level(level: int) -> void:
	var old_max_hp := _hero_max_hp()
	fighting_level = maxi(1, level)
	var new_max_hp := _hero_max_hp()
	if hero_ko_timer <= 0.0 and old_max_hp > 0.0:
		hero_hp = clampf(hero_hp / old_max_hp * new_max_hp, 1.0, new_max_hp)


func setup_blue_guy_health(current_hp: int, maximum_hp: int, regen_fraction: float) -> void:
	cover_health_maximum = maxi(1, maximum_hp)
	cover_health_current = clampi(current_hp, 0, cover_health_maximum)
	cover_health_regen_fraction = clampf(regen_fraction, 0.0, 1.0)
	queue_redraw()


func set_active_fight(active_fight: bool) -> void:
	if active == active_fight:
		return
	active = active_fight
	if active:
		_seed_fight()
	else:
		_seed_inactive_state()


func _process(delta: float) -> void:
	elapsed_seconds += delta
	_step_visual_fx(delta)
	var target_cover_open := 1.0 if active else 0.0
	cover_open_amount = move_toward(cover_open_amount, target_cover_open, delta * COVER_OPEN_SPEED)
	if active:
		var clamped_delta := minf(delta, 0.05)
		var frozen := hit_stop_timer > 0.0
		hit_stop_timer = maxf(0.0, hit_stop_timer - delta)
		module_shake_timer = maxf(0.0, module_shake_timer - delta)
		if module_shake_timer <= 0.0:
			module_shake_strength = 0.0
		_step_fight(0.0 if frozen else clamped_delta)
		displayed_wave_progress = lerpf(displayed_wave_progress, _wave_indicator_progress(), 1.0 - exp(-10.0 * maxf(0.0, delta)))
	else:
		_step_inactive(minf(delta, 0.05))
		displayed_wave_progress = 0.0
		hit_stop_timer = 0.0
		module_shake_timer = 0.0
	_update_labels()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_labels()
		queue_redraw()


func _ensure_labels() -> void:
	if title_label != null:
		return
	title_label = _stage_label("Fight Chickens", 58, HORIZONTAL_ALIGNMENT_LEFT, 22)
	add_child(title_label)
	ko_label = _stage_label("", 84, HORIZONTAL_ALIGNMENT_CENTER, 28)
	add_child(ko_label)
	ko_timer_label = _stage_label("", 40, HORIZONTAL_ALIGNMENT_CENTER, 12)
	add_child(ko_timer_label)
	for i in range(14):
		var floating := _stage_label("", 42, HORIZONTAL_ALIGNMENT_CENTER)
		floating.visible = false
		add_child(floating)
		float_labels.append(floating)
	_layout_labels()


func _stage_label(text: String, font_size: int, align: HorizontalAlignment, outline_size := 12) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", outline_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _layout_labels() -> void:
	if title_label == null:
		return
	var s := _stage_scale()
	_layout_title_label(s)
	var banner := _ko_banner_rect(s)
	ko_label.position = banner.position + Vector2(20.0, 12.0)
	ko_label.size = Vector2(banner.size.x - 40.0, 76.0)
	ko_timer_label.position = banner.position + Vector2(20.0, 86.0)
	ko_timer_label.size = Vector2(banner.size.x - 40.0, 42.0)


func _update_labels() -> void:
	if title_label == null:
		return
	_layout_title_label(_stage_scale())
	ko_label.visible = false
	ko_timer_label.visible = false
	if hero_ko_timer > 0.0:
		ko_label.text = ""
		ko_timer_label.text = ""
	else:
		ko_label.text = ""
		ko_timer_label.text = ""
	_update_floaters()


func _seed_fight() -> void:
	chickens.clear()
	food_drops.clear()
	feather_particles.clear()
	smoke_puffs.clear()
	hero_hp = _hero_max_hp()
	hero_ko_timer = 0.0
	hero_attack_cd = 0.22
	hero_attack_timer = 0.0
	hero_uppercut_cd = 1.15
	hero_attack_is_uppercut = false
	spawn_timer = 0.0
	wave_index = 0
	wave_kills = 0
	wave_rest_timer = 0.0
	wave_rest_duration_current = 0.0
	wave_elapsed_current = 0.0
	wave_duration_current = 1.0
	wave_spawn_phase_duration_current = 1.0
	displayed_wave_progress = 0.0
	end_wave_active = false
	end_wave_soft_kill_timer = 0.0
	area_clear_restart_timer = 0.0
	hit_stop_timer = 0.0
	module_shake_timer = 0.0
	_start_wave_spawning(true)


func _seed_inactive_state() -> void:
	chickens.clear()
	food_drops.clear()
	feather_particles.clear()
	smoke_puffs.clear()
	hero_hp = _hero_max_hp()
	hero_ko_timer = 0.0
	hero_attack_timer = 0.0
	hero_attack_cd = 0.45
	hero_uppercut_cd = 1.2
	hero_attack_is_uppercut = false
	spawn_timer = 0.0
	chicken_serial = 0
	wave_index = 0
	wave_kills = 0
	wave_spawn_total = 0
	wave_spawn_remaining = 0
	wave_spawned_count = 0
	wave_start_delay_current = WAVE_START_DELAY
	wave_rest_timer = 0.0
	wave_rest_duration_current = 0.0
	wave_elapsed_current = 0.0
	wave_duration_current = 1.0
	wave_spawn_phase_duration_current = 1.0
	displayed_wave_progress = 0.0
	end_wave_active = false
	end_wave_soft_kill_timer = 0.0
	area_clear_restart_timer = 0.0
	hit_stop_timer = 0.0
	module_shake_timer = 0.0
	var positions := [
		Vector2(0.18, 0.30),
		Vector2(0.78, 0.34),
		Vector2(0.30, 0.76),
		Vector2(0.68, 0.72)
	]
	for pos in positions:
		chicken_serial += 1
		chickens.append({
			"id": chicken_serial,
			"pos": pos,
			"home": pos,
			"hp": CHICKEN_BASE_HP_MAX,
			"max_hp": CHICKEN_BASE_HP_MAX,
			"attack_cd": 999.0,
			"lunge_timer": 0.0,
			"lunge_dir": Vector2.ZERO,
			"hit_flash": 0.0,
			"uppercut_pop": 0.0,
			"dead_timer": 0.0,
			"damage_done": false,
			"speed": 0.0,
			"variant": "white",
			"wave": 0,
			"damage": CHICKEN_DAMAGE
		})


func _step_inactive(delta: float) -> void:
	hero_attack_timer = 0.0
	hero_attack_cd = 0.45
	hero_facing = 1
	for i in range(chickens.size()):
		var chicken := chickens[i]
		var home := chicken.get("home", chicken.get("pos", Vector2.ZERO)) as Vector2
		chicken["pos"] = home
		chicken["hp"] = float(chicken.get("max_hp", CHICKEN_BASE_HP_MAX))
		chicken["hit_flash"] = 0.0
		chicken["lunge_timer"] = 0.0
		chickens[i] = chicken


func _step_fight(delta: float) -> void:
	if hero_ko_timer > 0.0:
		_step_food_drops(delta)
		hero_ko_timer = maxf(0.0, hero_ko_timer - delta)
		if hero_ko_timer <= 0.0:
			_seed_fight()
		return

	if area_clear_restart_timer > 0.0:
		_step_area_clear_restart(delta)
		return

	wave_elapsed_current = minf(wave_duration_current, wave_elapsed_current + delta)
	if wave_spawn_remaining > 0:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_spawn_wave_burst()
	elif not end_wave_active and wave_rest_timer > 0.0:
		wave_rest_timer = maxf(0.0, wave_rest_timer - delta)
		if wave_rest_timer <= 0.0:
			if wave_index >= NORMAL_WAVE_COUNT - 1:
				_start_end_wave()
			else:
				wave_index += 1
				_start_wave_spawning(false)
				_add_float("WAVE %d" % (wave_index + 1), _norm_to_stage(Vector2(0.5, 0.22)), XP_GOLD, 1.05)
	if end_wave_active:
		end_wave_soft_kill_timer = maxf(0.0, end_wave_soft_kill_timer - delta)

	hero_attack_cd -= delta
	hero_attack_timer = maxf(0.0, hero_attack_timer - delta)
	hero_uppercut_cd = maxf(0.0, hero_uppercut_cd - delta)
	if hero_attack_cd <= 0.0:
		if _start_hero_attack():
			hero_attack_cd = _hero_attack_interval()
		else:
			hero_attack_cd = 0.10

	for i in range(chickens.size()):
		var chicken := chickens[i]
		_step_chicken(chicken, delta)
		chickens[i] = chicken
	_step_food_drops(delta)
	chickens = chickens.filter(func(chicken: Dictionary) -> bool:
		return float(chicken.get("dead_timer", 0.0)) < 1.25
	)
	if hero_hp <= 0.0:
		hero_hp = 0.0
		hero_ko_timer = HERO_KO_DURATION
		knocked_out.emit()
	elif end_wave_active and end_wave_soft_kill_timer <= 0.0:
		hero_hp = 0.0
		hero_ko_timer = HERO_KO_DURATION
		knocked_out.emit()
		_add_float("OVERWHELMED", _norm_to_stage(Vector2(0.5, 0.30)), DANGER, 0.95)


func _spawn_chicken(lane: int) -> void:
	chicken_serial += 1
	var side := lane % 4
	var edge_t := fposmod(float(lane) * 0.271 + float(chicken_serial) * 0.173, 1.0)
	var variant := _variant_for_spawn(chicken_serial)
	var stat_mult := _wave_stat_mult(variant)
	var max_hp := _roll_chicken_max_hp(stat_mult)
	var pos := Vector2.ZERO
	if side == 0:
		pos = Vector2(0.04, 0.16 + edge_t * 0.68)
	elif side == 1:
		pos = Vector2(0.96, 0.16 + edge_t * 0.68)
	elif side == 2:
		pos = Vector2(0.16 + edge_t * 0.68, 0.08)
	else:
		pos = Vector2(0.16 + edge_t * 0.68, 0.92)
	chickens.append({
		"id": chicken_serial,
		"pos": pos,
		"hp": max_hp,
		"max_hp": max_hp,
		"attack_cd": 0.55 + edge_t * 0.65,
		"lunge_timer": 0.0,
		"lunge_dir": Vector2.ZERO,
		"uppercut_knock_timer": 0.0,
		"uppercut_knock_duration": CHICKEN_UPPERCUT_KNOCK_SECONDS,
		"uppercut_knock_dir": Vector2.ZERO,
		"hit_flash": 0.0,
		"uppercut_pop": 0.0,
		"dead_timer": 0.0,
		"damage_done": false,
		"speed": (0.088 + edge_t * 0.026) * _wave_speed_mult(variant),
		"variant": variant,
		"wave": wave_index,
		"damage": CHICKEN_DAMAGE * _wave_damage_mult(variant)
	})


func _start_wave_spawning(immediate: bool) -> void:
	end_wave_active = false
	end_wave_soft_kill_timer = 0.0
	area_clear_restart_timer = 0.0
	wave_spawn_total = _wave_spawn_total_for_wave()
	wave_spawn_remaining = wave_spawn_total
	wave_spawned_count = 0
	wave_rest_timer = 0.0
	wave_rest_duration_current = _wave_rest_duration_for_wave()
	wave_start_delay_current = 0.18 if immediate else _wave_start_delay_for_wave()
	spawn_timer = 0.0 if immediate else wave_start_delay_current
	wave_spawn_phase_duration_current = _wave_spawn_phase_duration_for_current_wave()
	wave_duration_current = maxf(0.01, wave_spawn_phase_duration_current + wave_rest_duration_current)
	wave_elapsed_current = 0.0
	displayed_wave_progress = 0.0


func _start_end_wave() -> void:
	end_wave_active = true
	end_wave_soft_kill_timer = END_WAVE_SOFT_KILL_SECONDS
	area_clear_restart_timer = 0.0
	wave_index = NORMAL_WAVE_COUNT
	wave_kills = 0
	wave_spawn_total = END_WAVE_TOTAL
	wave_spawn_remaining = wave_spawn_total
	wave_spawned_count = 0
	wave_rest_timer = 0.0
	wave_rest_duration_current = 0.0
	wave_start_delay_current = 0.34
	spawn_timer = 0.05
	wave_spawn_phase_duration_current = _wave_spawn_phase_duration_for_current_wave()
	wave_duration_current = maxf(0.01, wave_spawn_phase_duration_current)
	wave_elapsed_current = 0.0
	displayed_wave_progress = 0.0
	_add_float("END WAVE", _norm_to_stage(Vector2(0.5, 0.22)), DANGER, 1.18)


func _spawn_wave_burst() -> void:
	if wave_spawn_remaining <= 0:
		return
	var open_slots := _max_chickens_for_wave() - _living_chicken_count()
	if open_slots <= 0:
		spawn_timer = 0.18
		return
	var burst_count := mini(open_slots, mini(wave_spawn_remaining, _wave_spawn_burst_count()))
	for i in range(burst_count):
		_spawn_chicken(chicken_serial + i + wave_index * 13)
	wave_spawn_remaining -= burst_count
	wave_spawned_count += burst_count
	if wave_spawn_remaining > 0:
		spawn_timer = _spawn_interval_for_wave()
	else:
		spawn_timer = 0.0
		if not end_wave_active:
			wave_rest_timer = wave_rest_duration_current


func _step_chicken(chicken: Dictionary, delta: float) -> void:
	var hp := float(chicken.get("hp", 0.0))
	var dead_timer := float(chicken.get("dead_timer", 0.0))
	var pos := chicken.get("pos", Vector2.ZERO) as Vector2
	var knock_timer := maxf(0.0, float(chicken.get("uppercut_knock_timer", 0.0)) - delta)
	if knock_timer > 0.0:
		var knock_dir := chicken.get("uppercut_knock_dir", Vector2.ZERO) as Vector2
		if knock_dir.length() > 0.001:
			pos += knock_dir.normalized() * CHICKEN_UPPERCUT_KNOCK_SPEED * delta
		chicken["uppercut_knock_timer"] = knock_timer
	else:
		chicken["uppercut_knock_timer"] = 0.0
	if hp <= 0.0:
		chicken["pos"] = _clamp_norm_to_arena(pos)
		chicken["dead_timer"] = dead_timer + delta
		chicken["hit_flash"] = maxf(0.0, float(chicken.get("hit_flash", 0.0)) - delta)
		chicken["uppercut_pop"] = maxf(0.0, float(chicken.get("uppercut_pop", 0.0)) - delta)
		return

	var to_hero := hero_pos - pos
	var dist := maxf(0.001, to_hero.length())
	var dir := to_hero / dist
	var attack_cd := maxf(0.0, float(chicken.get("attack_cd", 0.0)) - delta)
	var lunge_timer := maxf(0.0, float(chicken.get("lunge_timer", 0.0)) - delta)

	if knock_timer > 0.0:
		lunge_timer = 0.0
		attack_cd = maxf(attack_cd, 0.42)
	elif lunge_timer > 0.0:
		var lunge_dir := chicken.get("lunge_dir", dir) as Vector2
		pos += lunge_dir * delta * 0.30
		if lunge_timer < 0.10 and not bool(chicken.get("damage_done", false)) and pos.distance_to(hero_pos) <= 0.19:
			hero_hp = maxf(0.0, hero_hp - float(chicken.get("damage", CHICKEN_DAMAGE)))
			chicken["damage_done"] = true
			_add_float("-%d" % int(chicken.get("damage", CHICKEN_DAMAGE)), _norm_to_stage(hero_pos) + Vector2(26.0, -74.0) * _stage_scale(), DANGER)
	elif dist > CHICKEN_ATTACK_RANGE:
		pos += dir * float(chicken.get("speed", 0.09)) * delta
	else:
		if attack_cd <= 0.0:
			lunge_timer = 0.24
			attack_cd = 1.15
			chicken["lunge_dir"] = dir
			chicken["damage_done"] = false
			_spawn_smoke_puffs(pos, dir)

	chicken["pos"] = _clamp_norm_to_arena(pos)
	chicken["attack_cd"] = attack_cd
	chicken["lunge_timer"] = lunge_timer
	chicken["hit_flash"] = maxf(0.0, float(chicken.get("hit_flash", 0.0)) - delta)
	chicken["uppercut_pop"] = maxf(0.0, float(chicken.get("uppercut_pop", 0.0)) - delta)


func _start_hero_attack() -> bool:
	var normal_target_index := _nearest_punchable_chicken_index()
	var uppercut_target_index := _nearest_punchable_chicken_index_for_reach(HERO_UPPERCUT_RANGE + HERO_UPPERCUT_RADIUS)
	var food_index := _nearest_punchable_food_index()
	var use_uppercut := uppercut_target_index >= 0 and hero_uppercut_cd <= 0.0 and randf() <= HERO_UPPERCUT_CHANCE
	var target_index := uppercut_target_index if use_uppercut else normal_target_index
	if target_index < 0 and food_index < 0:
		return false
	var target_pos := hero_pos + Vector2.RIGHT
	if target_index >= 0 and food_index >= 0:
		var chicken_pos := chickens[target_index].get("pos", hero_pos + Vector2.RIGHT) as Vector2
		var food_pos := food_drops[food_index].get("pos", hero_pos + Vector2.RIGHT) as Vector2
		target_pos = food_pos if food_pos.distance_squared_to(hero_pos) < chicken_pos.distance_squared_to(hero_pos) else chicken_pos
	elif food_index >= 0:
		target_pos = food_drops[food_index].get("pos", hero_pos + Vector2.RIGHT) as Vector2
	else:
		target_pos = chickens[target_index].get("pos", hero_pos + Vector2.RIGHT) as Vector2
	var dir := target_pos - hero_pos
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	hero_attack_dir = dir.normalized()
	hero_facing = -1 if hero_attack_dir.x < -0.04 else 1
	hero_attack_is_uppercut = use_uppercut
	hero_attack_timer = 0.34 if use_uppercut else 0.24
	if use_uppercut:
		hero_uppercut_cd = HERO_UPPERCUT_COOLDOWN
		_add_float("UPPERCUT!", _norm_to_stage(hero_pos) + Vector2(0.0, -132.0) * _stage_scale(), XP_GOLD, 0.82)
	var did_hit := false
	for i in range(chickens.size()):
		var chicken := chickens[i]
		if float(chicken.get("hp", 0.0)) <= 0.0:
			continue
		var chicken_pos := chicken.get("pos", Vector2.ZERO) as Vector2
		if _chicken_inside_current_punch(chicken_pos):
			var hero_damage := _roll_hero_uppercut_damage() if use_uppercut else _roll_hero_attack_damage()
			var hp := maxf(0.0, float(chicken.get("hp", 0.0)) - hero_damage)
			chicken["hp"] = hp
			chicken["hit_flash"] = 0.38 if use_uppercut else 0.26
			_spawn_feather_burst(chicken_pos, 9 if use_uppercut else 5, use_uppercut)
			_trigger_hit_stop(use_uppercut)
			if use_uppercut:
				chicken["uppercut_pop"] = 0.36
				var knock_dir := chicken_pos - hero_pos
				if knock_dir.length() < 0.001:
					knock_dir = hero_attack_dir
				chicken["uppercut_knock_timer"] = CHICKEN_UPPERCUT_KNOCK_SECONDS
				chicken["uppercut_knock_duration"] = CHICKEN_UPPERCUT_KNOCK_SECONDS
				chicken["uppercut_knock_dir"] = knock_dir.normalized()
				_trigger_module_shake(UPPERCUT_SHAKE_SECONDS, 7.0 * _stage_scale())
			if hp <= 0.0:
				_spawn_feather_burst(chicken_pos, 7, true)
				chicken["dead_timer"] = 0.01
				ko_count += 1
				wave_kills += 1
				var xp_reward := _xp_reward_for_chicken_variant(str(chicken.get("variant", "white")))
				chicken_killed.emit(xp_reward)
				_add_float("+%d XP" % xp_reward, _norm_to_stage(chicken_pos) + Vector2(10.0, -72.0) * _stage_scale(), XP_GOLD)
				if not end_wave_active:
					_maybe_spawn_food_drop(chicken_pos)
			else:
				_add_float("-%d" % int(hero_damage), _norm_to_stage(chicken_pos) + Vector2(0.0, -92.0 if use_uppercut else -74.0) * _stage_scale(), Color("#fff27b") if use_uppercut else Color("#ffef7a"), 0.82 if use_uppercut else 0.72)
			chickens[i] = chicken
			if hp <= 0.0 and end_wave_active:
				_try_complete_end_wave()
			did_hit = true
	for i in range(food_drops.size()):
		var food_drop := food_drops[i]
		if bool(food_drop.get("consumed", false)):
			continue
		var food_pos := food_drop.get("pos", Vector2.ZERO) as Vector2
		if _food_inside_current_punch(food_pos):
			food_drops[i] = _consume_food_drop(food_drop)
			did_hit = true
	if did_hit:
		punch_landed.emit()
	return did_hit


func _nearest_punchable_chicken_index() -> int:
	return _nearest_punchable_chicken_index_for_reach(_hero_attack_reach())


func _nearest_punchable_chicken_index_for_reach(reach: float) -> int:
	var nearest := -1
	var nearest_dist := 999.0
	for i in range(chickens.size()):
		var chicken := chickens[i]
		if float(chicken.get("hp", 0.0)) <= 0.0:
			continue
		var dist := (chicken.get("pos", Vector2.ZERO) as Vector2).distance_to(hero_pos)
		if dist > reach:
			continue
		if dist < nearest_dist:
			nearest = i
			nearest_dist = dist
	return nearest


func _nearest_punchable_food_index() -> int:
	var nearest := -1
	var nearest_dist := 999.0
	for i in range(food_drops.size()):
		var food_drop := food_drops[i]
		if bool(food_drop.get("consumed", false)):
			continue
		var dist := (food_drop.get("pos", Vector2.ZERO) as Vector2).distance_to(hero_pos)
		if dist > _hero_attack_reach() + COOKED_CHICKEN_PICKUP_RADIUS:
			continue
		if dist < nearest_dist:
			nearest = i
			nearest_dist = dist
	return nearest


func _chicken_inside_current_punch(chicken_pos: Vector2) -> bool:
	return _point_inside_current_punch(chicken_pos, HERO_HITBOX_RADIUS)


func _food_inside_current_punch(food_pos: Vector2) -> bool:
	return _point_inside_current_punch(food_pos, COOKED_CHICKEN_PICKUP_RADIUS)


func _point_inside_current_punch(point: Vector2, radius: float) -> bool:
	var to_point := point - hero_pos
	var hitbox_radius := _current_attack_radius()
	if to_point.length() <= maxf(radius, hitbox_radius):
		return true
	var along_punch := clampf(to_point.dot(hero_attack_dir), 0.0, _current_attack_range())
	var closest_point := hero_pos + hero_attack_dir * along_punch
	return point.distance_to(closest_point) <= maxf(radius, hitbox_radius)


func _maybe_spawn_food_drop(chicken_pos: Vector2) -> void:
	if cooked_chicken_drop == null:
		return
	if randf() > COOKED_CHICKEN_DROP_CHANCE:
		return
	food_drops.append({
		"pos": _clamp_norm_to_arena(chicken_pos + Vector2(randf_range(-0.035, 0.035), randf_range(-0.028, 0.028))),
		"age": 0.0,
		"bob_phase": randf() * TAU,
		"consumed": false,
		"consume_timer": 0.0
	})


func _consume_food_drop(food_drop: Dictionary) -> Dictionary:
	var heal_amount := maxf(5.0, _hero_max_hp() * COOKED_CHICKEN_HEAL_RATIO)
	var missing_hp := _hero_max_hp() - hero_hp
	var applied_heal := minf(heal_amount, missing_hp)
	hero_hp = minf(_hero_max_hp(), hero_hp + heal_amount)
	food_drop["consumed"] = true
	food_drop["consume_timer"] = COOKED_CHICKEN_CONSUME_SECONDS
	food_drop["base_pos"] = food_drop.get("pos", hero_pos)
	if applied_heal > 0.2:
		_add_float("+%d HP" % int(round(applied_heal)), _norm_to_stage(food_drop.get("pos", hero_pos) as Vector2) + Vector2(0.0, -70.0) * _stage_scale(), HERO_HP_BLUE, 0.72)
	return food_drop


func _step_food_drops(delta: float) -> void:
	for i in range(food_drops.size()):
		var food_drop := food_drops[i]
		if bool(food_drop.get("consumed", false)):
			food_drop["consume_timer"] = maxf(0.0, float(food_drop.get("consume_timer", 0.0)) - delta)
		else:
			food_drop["age"] = float(food_drop.get("age", 0.0)) + delta
		food_drops[i] = food_drop
	food_drops = food_drops.filter(func(food_drop: Dictionary) -> bool:
		if bool(food_drop.get("consumed", false)):
			return float(food_drop.get("consume_timer", 0.0)) > 0.0
		return float(food_drop.get("age", 0.0)) < COOKED_CHICKEN_LIFETIME
	)


func _hero_attack_reach() -> float:
	return HERO_HITBOX_RANGE + HERO_HITBOX_RADIUS


func _current_attack_range() -> float:
	return HERO_UPPERCUT_RANGE if hero_attack_is_uppercut else HERO_HITBOX_RANGE


func _current_attack_radius() -> float:
	return HERO_UPPERCUT_RADIUS if hero_attack_is_uppercut else HERO_HITBOX_RADIUS


func _living_chicken_count() -> int:
	var count := 0
	for chicken in chickens:
		if float(chicken.get("hp", 0.0)) > 0.0:
			count += 1
	return count


func _try_complete_end_wave() -> void:
	if not end_wave_active or area_clear_restart_timer > 0.0:
		return
	if wave_spawn_remaining > 0 or _living_chicken_count() > 0:
		return
	_complete_end_wave()


func _complete_end_wave() -> void:
	end_wave_active = false
	end_wave_soft_kill_timer = 0.0
	spawn_timer = 0.0
	wave_rest_timer = 0.0
	wave_elapsed_current = wave_duration_current
	displayed_wave_progress = 1.0
	area_clear_restart_timer = AREA_CLEAR_RESTART_DELAY
	chicken_killed.emit(END_WAVE_CLEAR_BONUS_XP)
	var clear_center := _norm_to_stage(Vector2(0.5, 0.30))
	_add_float("area cleared!", clear_center, XP_GOLD, 1.32)
	_add_float("+%d XP" % END_WAVE_CLEAR_BONUS_XP, clear_center + Vector2(0.0, 62.0) * _stage_scale(), XP_GOLD, 1.28)


func _step_area_clear_restart(delta: float) -> void:
	_step_food_drops(delta)
	hero_attack_timer = maxf(0.0, hero_attack_timer - delta)
	hero_uppercut_cd = maxf(0.0, hero_uppercut_cd - delta)
	area_clear_restart_timer = maxf(0.0, area_clear_restart_timer - delta)
	if area_clear_restart_timer <= 0.0:
		_seed_fight()


func _variant_for_spawn(serial: int) -> String:
	if end_wave_active:
		return "black" if serial % 3 != 0 else "gray"
	match _wave_style_index():
		0:
			return "white"
		1:
			return "gray" if serial % 3 != 0 else "white"
		2:
			if serial % 5 == 0:
				return "black"
			return "gray" if serial % 2 == 0 else "white"
		3:
			return "black" if serial % 2 == 0 else "gray"
		4:
			if serial % 4 == 0:
				return "white"
			return "black" if serial % 3 != 0 else "gray"
	return "white"


func _xp_reward_for_chicken_variant(variant: String) -> int:
	if variant == "black":
		return 3
	if variant == "gray":
		return 2
	return 1


func _wave_stat_mult(variant: String) -> float:
	if end_wave_active:
		if variant == "black":
			return 2.85
		if variant == "gray":
			return 2.35
		return 2.10
	var style := _wave_style_index()
	var tier_bonus := float(style) * 0.10
	if variant == "black":
		return 1.62 + tier_bonus
	if variant == "gray":
		return 1.24 + tier_bonus * 0.65
	return 1.0 + tier_bonus * 0.42


func _wave_damage_mult(variant: String) -> float:
	if end_wave_active:
		if variant == "black":
			return 5.20
		if variant == "gray":
			return 4.45
		return 3.80
	var style := _wave_style_index()
	var tier_bonus := float(style) * 0.08
	if variant == "black":
		return 1.52 + tier_bonus
	if variant == "gray":
		return 1.18 + tier_bonus * 0.65
	return 1.0 + tier_bonus * 0.25


func _wave_speed_mult(variant: String) -> float:
	if end_wave_active:
		return 1.65 if variant == "black" else 1.50
	var style_bonus := float(_wave_style_index()) * 0.035
	if variant == "black":
		return 1.11 + style_bonus
	if variant == "gray":
		return 1.04 + style_bonus * 0.7
	return 1.0 + style_bonus * 0.4


func _spawn_interval_for_wave() -> float:
	if end_wave_active:
		return END_WAVE_SPAWN_INTERVAL
	match _wave_style_index():
		0:
			return 0.82
		1:
			return 0.70
		2:
			return 0.58
		3:
			return 0.48
		4:
			return 0.38
	return 0.70


func _max_chickens_for_wave() -> int:
	if end_wave_active:
		return END_WAVE_MAX_CHICKENS
	match _wave_style_index():
		0:
			return MAX_CHICKENS
		1:
			return MAX_CHICKENS + 1
		2:
			return MAX_CHICKENS + 2
		3:
			return MAX_CHICKENS + 2
		4:
			return MAX_CHICKENS + 3
	return MAX_CHICKENS


func _wave_spawn_total_for_wave() -> int:
	match _wave_style_index():
		0:
			return 5
		1:
			return 7
		2:
			return 9
		3:
			return 11
		4:
			return 14
	return 5


func _wave_spawn_burst_count() -> int:
	if end_wave_active:
		return 6
	match _wave_style_index():
		0:
			return 1
		1:
			return 1
		2:
			return 2
		3:
			return 2
		4:
			return 3
	return 1


func _wave_start_delay_for_wave() -> float:
	match _wave_style_index():
		0:
			return 0.20
		1:
			return 0.20
		2:
			return 0.18
		3:
			return 0.16
		4:
			return 0.14
	return WAVE_START_DELAY


func _wave_spawn_phase_duration_for_current_wave() -> float:
	var burst_count := maxi(1, _wave_spawn_burst_count())
	var burst_steps := maxi(1, int(ceil(float(maxi(1, wave_spawn_total)) / float(burst_count))))
	var interval_count := maxi(0, burst_steps - 1)
	return maxf(0.01, wave_start_delay_current + float(interval_count) * _spawn_interval_for_wave())


func _wave_rest_duration_for_wave() -> float:
	match _wave_style_index():
		0:
			return 1.65
		1:
			return 1.45
		2:
			return 1.25
		3:
			return 1.05
		4:
			return 0.82
	return 1.0


func _wave_style_index() -> int:
	return clampi(wave_index, 0, NORMAL_WAVE_COUNT - 1)


func _chicken_texture(variant: String, state: String) -> Texture2D:
	if variant == "black":
		if state == "hit":
			return black_hit_chicken if black_hit_chicken != null else hit_chicken
		if state == "dizzy":
			return black_dizzy_chicken if black_dizzy_chicken != null else dizzy_chicken
		if state == "defeated":
			return black_defeated_chicken if black_defeated_chicken != null else defeated_chicken
		return black_idle_chicken if black_idle_chicken != null else idle_chicken
	if variant == "gray":
		if state == "hit":
			return gray_hit_chicken if gray_hit_chicken != null else hit_chicken
		if state == "dizzy":
			return gray_dizzy_chicken if gray_dizzy_chicken != null else dizzy_chicken
		if state == "defeated":
			return gray_defeated_chicken if gray_defeated_chicken != null else defeated_chicken
		return gray_idle_chicken if gray_idle_chicken != null else idle_chicken
	if state == "hit":
		return hit_chicken
	if state == "dizzy":
		return dizzy_chicken
	if state == "defeated":
		return defeated_chicken
	return idle_chicken


func _add_float(text: String, position: Vector2, color: Color, life := 0.72) -> void:
	for label in float_labels:
		if not label.visible:
			label.set_meta("life", life)
			label.set_meta("max_life", life)
			label.set_meta("base", position)
			label.text = text
			label.add_theme_color_override("font_color", color)
			label.visible = true
			return


func _update_floaters() -> void:
	for label in float_labels:
		if not label.visible:
			continue
		var life := float(label.get_meta("life", 0.0)) - get_process_delta_time()
		var max_life := maxf(0.01, float(label.get_meta("max_life", 0.72)))
		var base := label.get_meta("base", Vector2.ZERO) as Vector2
		if life <= 0.0:
			label.visible = false
			continue
		var t := 1.0 - life / max_life
		label.set_meta("life", life)
		label.position = base + Vector2(-90.0, -34.0 - 62.0 * t)
		label.size = Vector2(180.0, 68.0)
		label.modulate.a = clampf(1.0 - t * 0.72, 0.0, 1.0)


func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var s := _stage_scale()
	var shake_offset := _module_shake_offset(s)
	draw_set_transform(shake_offset, 0.0, Vector2.ONE)
	_draw_arena(s)
	_draw_smoke_puffs(s)
	_draw_actors(s)
	_draw_food_drops(s)
	_draw_feather_particles(s)
	if hero_attack_timer > 0.0 and hero_ko_timer <= 0.0:
		_draw_hero_attack_flash(s)
	_draw_wave_indicator(s)
	_draw_player_stat_hud(s)
	_draw_low_hp_danger_tint(s)
	if hero_ko_timer > 0.0:
		_draw_punishment_overlay(s)
	if cover_open_amount < 0.995:
		_draw_inactive_cover(s)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_arena(s: float) -> void:
	var arena := _arena_rect(s)
	if arena_floor != null:
		_draw_rounded_texture_cover(arena_floor, arena, _stage_corner_radius(s), Color("#74bd57"), s)
	else:
		draw_round_rect(arena, _stage_corner_radius(s), Color("#74bd57"))
		for i in range(8):
			var y := arena.position.y + arena.size.y * (0.16 + float(i) * 0.10)
			draw_line(Vector2(arena.position.x + 10.0 * s, y), Vector2(arena.end.x - 10.0 * s, y), Color(0, 0, 0, 0.055), 3.0 * s, false)


func _module_shake_offset(s: float) -> Vector2:
	if module_shake_timer <= 0.0 or module_shake_duration <= 0.0:
		return Vector2.ZERO
	var t := clampf(module_shake_timer / module_shake_duration, 0.0, 1.0)
	var strength := module_shake_strength * t * t
	return Vector2(
		sin(elapsed_seconds * 117.0) * strength,
		cos(elapsed_seconds * 91.0) * strength * 0.62
	)


func _draw_low_hp_danger_tint(s: float) -> void:
	if not active or hero_ko_timer > 0.0:
		return
	var hp_pct := clampf(hero_hp / maxf(1.0, _hero_max_hp()), 0.0, 1.0)
	if hp_pct >= 0.25:
		return
	var arena := _arena_rect(s)
	var pulse := 0.55 + 0.45 * sin(elapsed_seconds * 8.0)
	var alpha := (0.25 - hp_pct) / 0.25 * (0.16 + pulse * 0.10)
	var width := maxf(12.0, 22.0 * s)
	draw_round_outline(arena.grow(-8.0 * s), maxf(1.0, _stage_corner_radius(s) - 8.0 * s), Color(1.0, 0.05, 0.02, alpha), width)
	draw_round_outline(arena.grow(-20.0 * s), maxf(1.0, _stage_corner_radius(s) - 20.0 * s), Color(1.0, 0.15, 0.02, alpha * 0.45), width * 0.45)


func _draw_wave_indicator(s: float) -> void:
	if not active or hero_ko_timer > 0.0:
		return
	var arena := _arena_rect(s)
	var progress := clampf(displayed_wave_progress, 0.0, 1.0)
	var fill_color := _wave_indicator_color(progress)
	var label := "Cleared" if area_clear_restart_timer > 0.0 else ("End Wave" if end_wave_active else "Wave %d" % (wave_index + 1))
	var label_size := int(clampf(arena.size.y * 0.20, 46.0, 58.0))
	var rail_size := Vector2(maxf(34.0, 44.0 * s), maxf(122.0, arena.size.y * 0.58))
	var rail := Rect2(Vector2(arena.end.x - rail_size.x - 28.0 * s, arena.end.y - rail_size.y - 30.0 * s), rail_size)
	var label_center := Vector2(rail.position.x - clampf(arena.size.x * 0.14, 118.0, 166.0), rail.end.y - 44.0 * s)
	var radius := rail.size.x * 0.5
	draw_round_rect(Rect2(rail.position + Vector2(0.0, 4.0) * s, rail.size), radius, Color(0, 0, 0, 0.28))
	draw_round_rect(rail, radius, Color("#211411", 0.94))
	var fill_height := rail.size.y * progress
	var fill_rect := Rect2(Vector2(rail.position.x, rail.end.y - fill_height), Vector2(rail.size.x, fill_height))
	if fill_rect.size.y > 0.5:
		_draw_rounded_rect_row(rail, fill_rect, radius, fill_color)
	draw_round_outline(rail, radius, INK, maxf(5.0, 7.0 * s))
	_draw_centered_text(label, label_center, label_size, WHITE, int(maxf(10.0, 14.0 * s)), INK)


func _draw_player_stat_hud(s: float) -> void:
	if not active or hero_ko_timer > 0.0:
		return
	var arena := _arena_rect(s)
	var font := get_theme_default_font()
	if font == null:
		return
	var text_size := int(clampf(arena.size.y * 0.148, 34.0, 46.0))
	var values := [
		"DMG %s" % _hero_attack_damage_range_text(),
		"SPD %.2f/s" % (1.0 / maxf(0.01, _hero_attack_interval())),
		"HP %d" % int(round(_hero_max_hp()))
	]
	var left_x := arena.position.x + clampf(arena.size.x * 0.052, 36.0, 54.0)
	var row_gap := clampf(arena.size.y * 0.150, 36.0, 46.0)
	var bottom_pad := clampf(arena.size.y * 0.108, 26.0, 36.0)
	var top_y := arena.end.y - bottom_pad - row_gap * 2.0
	var text_stroke := int(maxf(10.0, 14.0 * s))
	for i in range(3):
		var y := top_y + row_gap * float(i)
		_draw_left_text(font, values[i], Vector2(left_x, y), text_size, WHITE, text_stroke, INK)


func _step_visual_fx(delta: float) -> void:
	if delta <= 0.0:
		return
	for i in range(feather_particles.size()):
		var feather := feather_particles[i]
		var life := float(feather.get("life", 0.0)) - delta
		var pos := feather.get("pos", Vector2.ZERO) as Vector2
		var vel := feather.get("vel", Vector2.ZERO) as Vector2
		vel += Vector2(0.0, 210.0) * delta
		pos += vel * delta
		feather["life"] = life
		feather["pos"] = pos
		feather["vel"] = vel
		feather["spin"] = float(feather.get("spin", 0.0)) + float(feather.get("spin_speed", 0.0)) * delta
		feather_particles[i] = feather
	feather_particles = feather_particles.filter(func(feather: Dictionary) -> bool:
		return float(feather.get("life", 0.0)) > 0.0
	)
	for i in range(smoke_puffs.size()):
		var puff := smoke_puffs[i]
		var life := float(puff.get("life", 0.0)) - delta
		var pos := puff.get("pos", Vector2.ZERO) as Vector2
		var vel := puff.get("vel", Vector2.ZERO) as Vector2
		pos += vel * delta
		puff["life"] = life
		puff["pos"] = pos
		puff["radius"] = float(puff.get("radius", 8.0)) + 28.0 * delta
		smoke_puffs[i] = puff
	smoke_puffs = smoke_puffs.filter(func(puff: Dictionary) -> bool:
		return float(puff.get("life", 0.0)) > 0.0
	)


func _spawn_feather_burst(norm_pos: Vector2, count: int, strong: bool) -> void:
	var base := _norm_to_stage(norm_pos)
	var s := _stage_scale()
	for i in range(count):
		var angle := randf_range(-PI * 0.92, -PI * 0.08)
		var speed := randf_range(96.0, 210.0) * s * (1.22 if strong else 1.0)
		feather_particles.append({
			"pos": base + Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 10.0)) * s,
			"vel": Vector2(cos(angle), sin(angle)) * speed + Vector2(randf_range(-38.0, 38.0), randf_range(-34.0, 10.0)) * s,
			"life": randf_range(0.38, 0.68) * (1.22 if strong else 1.0),
			"max_life": randf_range(0.52, 0.78) * (1.18 if strong else 1.0),
			"size": randf_range(7.0, 13.0) * s * (1.12 if strong else 1.0),
			"spin": randf_range(0.0, TAU),
			"spin_speed": randf_range(-8.0, 8.0),
			"color": Color("#fff3cf") if randf() < 0.72 else Color("#f5dca7")
		})
	if feather_particles.size() > 72:
		feather_particles = feather_particles.slice(feather_particles.size() - 72, feather_particles.size())


func _spawn_smoke_puffs(norm_pos: Vector2, lunge_dir: Vector2) -> void:
	var base := _norm_to_stage(norm_pos) + Vector2(0.0, 58.0) * _stage_scale()
	var s := _stage_scale()
	var back_dir := -lunge_dir.normalized() if lunge_dir.length() > 0.001 else Vector2.LEFT
	for i in range(4):
		smoke_puffs.append({
			"pos": base + Vector2(randf_range(-18.0, 18.0), randf_range(-4.0, 8.0)) * s,
			"vel": (back_dir * randf_range(28.0, 58.0) + Vector2(randf_range(-18.0, 18.0), randf_range(-24.0, -6.0))) * s,
			"life": randf_range(0.24, 0.42),
			"max_life": 0.42,
			"radius": randf_range(8.0, 14.0) * s
		})
	if smoke_puffs.size() > 48:
		smoke_puffs = smoke_puffs.slice(smoke_puffs.size() - 48, smoke_puffs.size())


func _trigger_hit_stop(uppercut: bool) -> void:
	hit_stop_timer = maxf(hit_stop_timer, UPPERCUT_HIT_STOP_SECONDS if uppercut else HIT_STOP_SECONDS)


func _trigger_module_shake(duration: float, strength: float) -> void:
	module_shake_duration = maxf(0.01, duration)
	module_shake_timer = maxf(module_shake_timer, duration)
	module_shake_strength = maxf(module_shake_strength, strength)


func _draw_smoke_puffs(s: float) -> void:
	for puff in smoke_puffs:
		var life := float(puff.get("life", 0.0))
		var max_life := maxf(0.01, float(puff.get("max_life", 0.42)))
		var t := 1.0 - clampf(life / max_life, 0.0, 1.0)
		var alpha := (1.0 - t) * 0.24
		var pos := puff.get("pos", Vector2.ZERO) as Vector2
		var radius := float(puff.get("radius", 10.0))
		_draw_ellipse(pos, Vector2(radius * (1.35 + t * 0.45), radius * (0.62 + t * 0.25)), Color(0.72, 0.65, 0.54, alpha))


func _draw_feather_particles(s: float) -> void:
	for feather in feather_particles:
		var life := float(feather.get("life", 0.0))
		var max_life := maxf(0.01, float(feather.get("max_life", 0.6)))
		var alpha := clampf(life / max_life, 0.0, 1.0)
		var pos := feather.get("pos", Vector2.ZERO) as Vector2
		var size_px := float(feather.get("size", 9.0))
		var spin := float(feather.get("spin", 0.0))
		var color := feather.get("color", Color("#fff3cf")) as Color
		color.a = alpha * 0.92
		var right := Vector2(cos(spin), sin(spin))
		var up := Vector2(-right.y, right.x)
		var points := PackedVector2Array([
			pos + right * size_px,
			pos + up * size_px * 0.34,
			pos - right * size_px * 0.78,
			pos - up * size_px * 0.34
		])
		draw_colored_polygon(points, color)
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.20, 0.14, 0.08, alpha * 0.18), maxf(1.0, 1.5 * s), true)


func _wave_indicator_progress() -> float:
	return clampf(wave_elapsed_current / maxf(0.01, wave_duration_current), 0.0, 1.0)


func _wave_indicator_color(progress: float) -> Color:
	if area_clear_restart_timer > 0.0:
		return XP_GOLD
	if end_wave_active:
		return DANGER
	var spawn_ratio := clampf(wave_spawn_phase_duration_current / maxf(0.01, wave_duration_current), 0.08, 0.92)
	var spawn_color := Color("#ffb938")
	var rest_color := Color("#4fc3ff")
	var ready_color := Color("#38e57e")
	if progress <= spawn_ratio:
		return spawn_color
	var rest_t := clampf((progress - spawn_ratio) / maxf(0.01, 1.0 - spawn_ratio), 0.0, 1.0)
	return ready_color if rest_t >= 0.92 else rest_color


func _draw_actors(s: float) -> void:
	var draw_order := chickens.duplicate()
	draw_order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a.get("pos", Vector2.ZERO) as Vector2).y < (b.get("pos", Vector2.ZERO) as Vector2).y
	)
	var hero_stage := _norm_to_stage(hero_pos)
	var hero_inserted := false
	for chicken in draw_order:
		var chicken_y := (chicken.get("pos", Vector2.ZERO) as Vector2).y
		if not hero_inserted and hero_pos.y < chicken_y:
			_draw_hero(hero_stage, s)
			hero_inserted = true
		_draw_chicken(chicken, s)
	if not hero_inserted:
		_draw_hero(hero_stage, s)


func _draw_hero(center: Vector2, s: float) -> void:
	var ko := hero_ko_timer > 0.0
	var attack_duration := 0.34 if hero_attack_is_uppercut else 0.24
	var pulse := clampf(hero_attack_timer / attack_duration, 0.0, 1.0)
	var idle_bob := 0.0 if not active else sin(elapsed_seconds * 6.0) * 5.0 * s
	if ko:
		_draw_ko_hero(center, s)
	else:
		var is_striking := pulse > 0.20
		var texture := blue_guy_guard
		if is_striking:
			texture = blue_guy_uppercut if hero_attack_is_uppercut and blue_guy_uppercut != null else blue_guy_punch
		var lunge := hero_attack_dir * (pulse * (48.0 if hero_attack_is_uppercut else 32.0) * s)
		var rise := Vector2(0.0, -34.0 * sin(pulse * PI)) * s if hero_attack_is_uppercut else Vector2.ZERO
		var rotation := 0.08 * float(hero_facing) * pulse if hero_attack_is_uppercut else 0.04 * float(hero_facing) * pulse
		rotation += sin(elapsed_seconds * 4.2) * 0.012 * (1.0 - pulse)
		var hero_draw_size := Vector2(270, 270) * s if hero_attack_is_uppercut and is_striking else (Vector2(238, 238) * s if is_striking else Vector2(198, 198) * s)
		_draw_ellipse(center + Vector2(16, 98) * s, Vector2(82, 19) * s, Color(0, 0, 0, 0.20))
		_draw_character_texture(texture, center + Vector2(0, 30) * s + Vector2(0, idle_bob) + lunge + rise, hero_draw_size, rotation, 1.0, hero_facing < 0, true)
	_draw_local_health(center + Vector2(0, -118) * s, 132.0 * s, hero_hp / _hero_max_hp(), HERO_HP_BLUE, s)


func _draw_ko_hero(center: Vector2, s: float) -> void:
	var elapsed_ko := HERO_KO_DURATION - hero_ko_timer
	var fall_t := _smooth01(clampf(elapsed_ko / HERO_KO_FALL_SECONDS, 0.0, 1.0))
	var stand_t := _smooth01(clampf((HERO_KO_STAND_SECONDS - hero_ko_timer) / HERO_KO_STAND_SECONDS, 0.0, 1.0))
	var recovering := hero_ko_timer < HERO_KO_STAND_SECONDS
	var transition_t := stand_t if recovering else fall_t
	var standing_alpha := stand_t if recovering else 1.0 - fall_t
	var down_alpha := 1.0 - stand_t if recovering else fall_t
	var fall_dir := float(hero_facing)
	var down_center := center + Vector2(0, 58) * s
	var standing_center := center + Vector2(0, 30) * s
	var offset_t := 1.0 - transition_t if recovering else transition_t
	var stand_center := standing_center + Vector2(36.0 * fall_dir * offset_t, 42.0 * offset_t) * s
	var stand_rotation := 1.18 * fall_dir * transition_t if not recovering else 1.18 * fall_dir * (1.0 - transition_t)
	var stand_scale := 1.0 - 0.10 * transition_t if not recovering else 0.90 + 0.10 * transition_t
	var down_wiggle := 0.015 * sin(elapsed_seconds * 7.0)
	_draw_ellipse(center + Vector2(10, 88) * s, Vector2(82, 19) * s, Color(0, 0, 0, 0.22 * maxf(0.45, down_alpha)))
	if down_alpha > 0.02:
		_draw_character_texture(blue_guy_ko, down_center, Vector2(222, 134) * s, down_wiggle, down_alpha, false, true)
	if standing_alpha > 0.02:
		_draw_character_texture(blue_guy_guard, stand_center, Vector2(198, 198) * s * stand_scale, stand_rotation, standing_alpha, hero_facing < 0, true)


func _draw_chicken(chicken: Dictionary, s: float) -> void:
	var pos := chicken.get("pos", Vector2.ZERO) as Vector2
	var center := _norm_to_stage(pos)
	var hp := float(chicken.get("hp", 0.0))
	var max_hp := maxf(1.0, float(chicken.get("max_hp", CHICKEN_BASE_HP_MAX)))
	var hit_flash := float(chicken.get("hit_flash", 0.0))
	var uppercut_pop := float(chicken.get("uppercut_pop", 0.0))
	var knock_timer := float(chicken.get("uppercut_knock_timer", 0.0))
	var knock_duration := maxf(0.01, float(chicken.get("uppercut_knock_duration", CHICKEN_UPPERCUT_KNOCK_SECONDS)))
	var dead := hp <= 0.0
	var lunge_timer := float(chicken.get("lunge_timer", 0.0))
	var variant := str(chicken.get("variant", "white"))
	var texture := _chicken_texture(variant, "idle")
	if dead:
		texture = _chicken_texture(variant, "defeated")
	elif hit_flash > 0.0:
		texture = _chicken_texture(variant, "hit")
	elif lunge_timer > 0.0:
		texture = _chicken_texture(variant, "hit")
	elif hp / max_hp < 0.38:
		texture = _chicken_texture(variant, "dizzy")
	var lunge_dir := chicken.get("lunge_dir", Vector2.ZERO) as Vector2
	var id_phase := float(int(chicken.get("id", 0))) * 1.71
	var hop := 0.0 if not active else sin(elapsed_seconds * 7.0 + id_phase) * 4.0 * s
	var lunge_alpha := sin((lunge_timer / 0.24) * PI)
	center += lunge_dir * lunge_alpha * 38.0 * s
	var idle_wobble := 0.0 if not active else sin(elapsed_seconds * 4.4 + id_phase) * 2.0 * s
	center += Vector2(idle_wobble, hop)
	if hit_flash > 0.0:
		center += Vector2(sin(elapsed_seconds * 48.0 + id_phase) * 7.0 * s, 0.0)
	var arc_lift := 0.0
	if knock_timer > 0.0:
		var arc_t := 1.0 - clampf(knock_timer / knock_duration, 0.0, 1.0)
		arc_lift = -92.0 * sin(arc_t * PI)
	elif uppercut_pop > 0.0:
		var pop_t := clampf(uppercut_pop / 0.36, 0.0, 1.0)
		arc_lift = -46.0 * sin(pop_t * PI)
	center += Vector2(0.0, arc_lift) * s
	var face_left := pos.x < hero_pos.x
	var scale := 0.82 + pos.y * 0.34
	var alpha := clampf(1.0 - float(chicken.get("dead_timer", 0.0)) * 0.75, 0.0, 1.0)
	var death_tilt := float(chicken.get("dead_timer", 0.0)) * 0.70
	var lunge_scale := 1.0 + lunge_alpha * 0.06
	var state_scale := 1.0
	var knock_rotation := 0.0
	if knock_timer > 0.0:
		var knock_t := 1.0 - clampf(knock_timer / knock_duration, 0.0, 1.0)
		knock_rotation = sin(knock_t * PI) * 0.22 * (-1.0 if face_left else 1.0)
	if dead:
		state_scale = 1.26
	elif knock_timer > 0.0 or uppercut_pop > 0.0:
		state_scale = 1.20
	elif hit_flash > 0.0 or lunge_timer > 0.0:
		state_scale = 1.08
	_draw_ellipse(center + Vector2(0, 64) * s * scale, Vector2(58, 17) * s * scale, Color(0, 0, 0, 0.17 * alpha))
	_draw_character_texture(texture, center, Vector2(172, 156) * s * scale * lunge_scale * state_scale, -hit_flash * 0.10 + death_tilt + knock_rotation, alpha, face_left)
	if not dead:
		_draw_local_health(center + Vector2(0, -82) * s * scale, 78.0 * s * scale, hp / max_hp, CHICKEN_HP if hp / max_hp > 0.35 else DANGER, s)


func _draw_food_drops(s: float) -> void:
	if cooked_chicken_drop == null:
		return
	for food_drop in food_drops:
		_draw_food_drop(food_drop, s)


func _draw_food_drop(food_drop: Dictionary, s: float) -> void:
	var pos := food_drop.get("pos", Vector2.ZERO) as Vector2
	var center := _norm_to_stage(pos)
	var age := float(food_drop.get("age", 0.0))
	var bob_phase := float(food_drop.get("bob_phase", 0.0))
	var consumed := bool(food_drop.get("consumed", false))
	var alpha := 1.0
	var draw_scale := 1.0
	var rotation := -0.10 + sin(elapsed_seconds * 3.2 + bob_phase) * 0.06
	if consumed:
		var remaining := clampf(float(food_drop.get("consume_timer", 0.0)) / COOKED_CHICKEN_CONSUME_SECONDS, 0.0, 1.0)
		var consume_t := 1.0 - remaining
		var base_pos := food_drop.get("base_pos", pos) as Vector2
		center = _norm_to_stage(base_pos) + Vector2(0.0, -78.0 * consume_t) * s
		alpha = remaining
		draw_scale = 1.0 + consume_t * 0.42
		rotation += consume_t * 0.18
	else:
		var fade_t := clampf((age - (COOKED_CHICKEN_LIFETIME - 1.25)) / 1.25, 0.0, 1.0)
		alpha = 1.0 - fade_t
		center += Vector2(0.0, sin(elapsed_seconds * 5.0 + bob_phase) * 5.0) * s
		draw_scale = 1.0 + sin(elapsed_seconds * 6.2 + bob_phase) * 0.035
	_draw_ellipse(center + Vector2(6.0, 38.0) * s, Vector2(34.0, 9.0) * s * draw_scale, Color(0, 0, 0, 0.18 * alpha))
	_draw_character_texture(cooked_chicken_drop, center, Vector2(74.0, 74.0) * s * draw_scale, rotation, alpha, false, true)


func _draw_hero_attack_flash(s: float) -> void:
	if not active:
		return
	var attack_duration := 0.34 if hero_attack_is_uppercut else 0.24
	var pulse := clampf(hero_attack_timer / attack_duration, 0.0, 1.0)
	var flash_t := 1.0 - pulse
	var alpha := clampf(sin(flash_t * PI), 0.0, 1.0)
	if alpha <= 0.02:
		return
	var hit_center := _norm_to_stage(hero_pos + hero_attack_dir * _current_attack_range())
	var radius := (62.0 if hero_attack_is_uppercut else 38.0) * s * (1.0 + flash_t * 0.22)
	var fill_color: Color = Color(1.0, 0.80, 0.16, 0.20 * alpha) if hero_attack_is_uppercut else Color(1.0, 0.95, 0.42, 0.12 * alpha)
	var ring_color: Color = Color(1.0, 0.94, 0.48, 0.72 * alpha) if hero_attack_is_uppercut else Color(1.0, 0.96, 0.62, 0.42 * alpha)
	draw_circle(hit_center, radius * 0.62, fill_color)
	draw_arc(hit_center, radius, 0.0, TAU, 32, ring_color, maxf(4.0, (8.0 if hero_attack_is_uppercut else 5.0) * s), true)
	if hero_attack_is_uppercut:
		draw_arc(hit_center, radius * 0.58, -PI * 0.25, PI * 1.15, 24, Color(1.0, 1.0, 0.84, 0.58 * alpha), maxf(3.0, 5.0 * s), true)


func _draw_inactive_cover(s: float) -> void:
	var arena := _arena_rect(s)
	var t := _ease_garage_door(cover_open_amount)
	var top_rect := _cover_top_rect(s)
	var panel_height := _cover_panel_height(arena, s)
	var travel := _cover_panel_travel(arena, s)
	var bottom_rect := Rect2(Vector2(arena.position.x, arena.end.y - panel_height + travel * t), Vector2(arena.size.x, panel_height))
	var red := Color("#b92d34")
	var red_dark := Color("#681820")
	var red_light := Color("#e84c55")
	if t <= 0.015:
		var closed_rect := arena.grow(-10.0 * s)
		_draw_closed_cover_shell(closed_rect, 24.0 * s, red, red_dark, red_light, s)
	else:
		_draw_cover_panel(top_rect, 36.0 * s, red, red_dark, red_light, s, true)
		_draw_cover_panel(bottom_rect, 36.0 * s, red.darkened(0.04), red_dark.darkened(0.08), red_light, s, false)
	var seam_y := (top_rect.end.y + bottom_rect.position.y) * 0.5
	var seam_gap := maxf(8.0 * s, bottom_rect.position.y - top_rect.end.y)
	_draw_cover_seam(arena, seam_y, seam_gap, s)
	var cover_chicken := cover_clean_chicken if cover_clean_chicken != null else idle_chicken
	if cover_chicken != null:
		var badge_center := arena.get_center() + Vector2(0.0, 12.0) * s
		var badge_alpha := clampf(1.0 - t * 1.8, 0.0, 1.0)
		var chicken_size := Vector2(arena.size.y * 0.42, arena.size.y * 0.38)
		_draw_ellipse(badge_center + Vector2(0, chicken_size.y * 0.37), Vector2(chicken_size.x * 0.35, chicken_size.y * 0.11), Color(0, 0, 0, 0.18 * badge_alpha))
		_draw_character_texture(cover_chicken, badge_center, chicken_size, sin(elapsed_seconds * 0.8) * 0.010, badge_alpha, false, false)


func _layout_title_label(s: float) -> void:
	var top_rect := _cover_top_rect(s)
	title_label.position = top_rect.position + Vector2(30.0, 12.0) * s
	title_label.size = Vector2(maxf(0.0, top_rect.size.x - 60.0 * s), 108.0 * s)
	title_label.visible = cover_open_amount < 0.995
	title_label.modulate.a = clampf(1.0 - _ease_garage_door(cover_open_amount) * 1.8, 0.0, 1.0)


func _cover_top_rect(s: float) -> Rect2:
	var arena := _arena_rect(s)
	var t := _ease_garage_door(cover_open_amount)
	var panel_height := _cover_panel_height(arena, s)
	var travel := _cover_panel_travel(arena, s)
	return Rect2(arena.position + Vector2(0.0, -travel * t), Vector2(arena.size.x, panel_height))


func _cover_panel_height(arena: Rect2, s: float) -> float:
	return arena.size.y * 0.5 + 18.0 * s


func _cover_panel_travel(arena: Rect2, s: float) -> float:
	return _cover_panel_height(arena, s) + 22.0 * s


func _draw_cover_panel(rect: Rect2, radius: float, fill: Color, shadow: Color, highlight: Color, s: float, top_panel: bool) -> void:
	var round_top := top_panel
	var round_bottom := not top_panel
	_draw_cover_panel_shape(rect, radius, shadow, round_top, round_bottom, maxf(2.0, 4.0 * s))
	var face := rect.grow(-7.0 * s)
	var face_radius := maxf(1.0, radius - 7.0 * s)
	_draw_cover_panel_face(face, face_radius, fill, s, top_panel, round_top, round_bottom)
	var stripe_count := 5
	for i in range(stripe_count):
		var y := face.position.y + face.size.y * (float(i + 1) / float(stripe_count + 1))
		var groove_color := Color(0.12, 0.018, 0.02, 0.17)
		draw_line(Vector2(face.position.x + 28.0 * s, y), Vector2(face.end.x - 28.0 * s, y), groove_color, 3.0 * s, true)
		draw_line(Vector2(face.position.x + 32.0 * s, y + 4.0 * s), Vector2(face.end.x - 32.0 * s, y + 4.0 * s), Color(1.0, 0.56, 0.50, 0.08), 2.0 * s, true)
	var shine_y := face.position.y + (20.0 * s if top_panel else face.size.y - 22.0 * s)
	draw_line(Vector2(face.position.x + 34.0 * s, shine_y), Vector2(face.end.x - 34.0 * s, shine_y), Color(highlight.r, highlight.g, highlight.b, 0.42), 3.0 * s, true)
	_draw_cover_panel_outline(rect, radius, INK, 7.0 * s, round_top, round_bottom)


func _draw_closed_cover_shell(rect: Rect2, radius: float, fill: Color, shadow: Color, highlight: Color, s: float) -> void:
	draw_round_rect(rect, radius, fill.darkened(0.08))
	var face := rect.grow(-4.0 * s)
	var face_radius := maxf(1.0, radius - 4.0 * s)
	var row_height := maxf(2.0, 5.0 * s)
	var y := face.position.y
	while y < face.end.y:
		var next_y := minf(face.end.y, y + row_height)
		var mid_y := (y + next_y) * 0.5
		var t := clampf((mid_y - face.position.y) / maxf(1.0, face.size.y), 0.0, 1.0)
		var light_t := absf(t - 0.5) * 2.0
		var row_color := fill.lightened(0.07 * light_t).darkened(0.10 * t)
		var row_rect := Rect2(Vector2(face.position.x, y), Vector2(face.size.x, next_y - y))
		_draw_cover_panel_row(face, row_rect, face_radius, row_color, true, true)
		y = next_y
	var stripe_count := 9
	for i in range(stripe_count):
		var stripe_y := face.position.y + face.size.y * (float(i + 1) / float(stripe_count + 1))
		draw_line(Vector2(face.position.x + 28.0 * s, stripe_y), Vector2(face.end.x - 28.0 * s, stripe_y), Color(0.12, 0.018, 0.02, 0.15), 2.0 * s, true)
		draw_line(Vector2(face.position.x + 32.0 * s, stripe_y + 4.0 * s), Vector2(face.end.x - 32.0 * s, stripe_y + 4.0 * s), Color(1.0, 0.56, 0.50, 0.07), 2.0 * s, true)
	var plank_count := 6
	for i in range(1, plank_count):
		var x := face.position.x + face.size.x * (float(i) / float(plank_count))
		draw_line(Vector2(x, face.position.y + 22.0 * s), Vector2(x, face.end.y - 22.0 * s), Color(0.12, 0.018, 0.02, 0.10), 2.0 * s, true)
	draw_line(Vector2(face.position.x + 34.0 * s, face.position.y + 20.0 * s), Vector2(face.end.x - 34.0 * s, face.position.y + 20.0 * s), Color(highlight.r, highlight.g, highlight.b, 0.36), 3.0 * s, true)
	draw_round_outline(rect.grow(-1.0 * s), maxf(1.0, radius - 1.0 * s), Color(shadow.r, shadow.g, shadow.b, 0.76), 2.0 * s)


func _draw_cover_panel_face(rect: Rect2, radius: float, fill: Color, s: float, top_panel: bool, round_top: bool, round_bottom: bool) -> void:
	var row_height := maxf(2.0, 5.0 * s)
	var y := rect.position.y
	while y < rect.end.y:
		var next_y := minf(rect.end.y, y + row_height)
		var mid_y := (y + next_y) * 0.5
		var t := clampf((mid_y - rect.position.y) / maxf(1.0, rect.size.y), 0.0, 1.0)
		var light_t := 1.0 - t if top_panel else t
		var row_color := fill.lightened(0.10 * light_t).darkened(0.13 * t)
		var row_rect := Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, next_y - y))
		_draw_cover_panel_row(rect, row_rect, radius, row_color, round_top, round_bottom)
		y = next_y
	var plank_count := 6
	for i in range(1, plank_count):
		var x := rect.position.x + rect.size.x * (float(i) / float(plank_count))
		draw_line(Vector2(x, rect.position.y + 22.0 * s), Vector2(x, rect.end.y - 22.0 * s), Color(0.12, 0.018, 0.02, 0.12), 2.0 * s, true)


func _draw_cover_seam(arena: Rect2, seam_y: float, seam_gap: float, s: float) -> void:
	var left := arena.position.x + 30.0 * s
	var right := arena.end.x - 30.0 * s
	var top_y := seam_y - seam_gap * 0.5
	var bottom_y := seam_y + seam_gap * 0.5
	draw_line(Vector2(left, top_y), Vector2(right, top_y), Color("#2d0b0f", 0.66), 4.0 * s, true)
	draw_line(Vector2(left, bottom_y), Vector2(right, bottom_y), Color("#5a141a", 0.52), 3.0 * s, true)
	var latch_alpha := clampf(1.0 - seam_gap / maxf(1.0, arena.size.y * 0.22), 0.0, 1.0)
	if latch_alpha <= 0.02:
		return
	var latch_width := minf(190.0 * s, (right - left) * 0.28)
	var latch_rect := Rect2(
		Vector2(arena.get_center().x - latch_width * 0.5, seam_y - 12.0 * s),
		Vector2(latch_width, 24.0 * s)
	)
	draw_round_rect(latch_rect, 10.0 * s, Color("#3b1014", 0.62 * latch_alpha))
	draw_line(Vector2(latch_rect.position.x + 18.0 * s, seam_y), Vector2(latch_rect.end.x - 18.0 * s, seam_y), Color("#e1a944", 0.42 * latch_alpha), 4.0 * s, true)


func _draw_cover_panel_shape(rect: Rect2, radius: float, color: Color, round_top: bool, round_bottom: bool, row_height: float) -> void:
	var y := rect.position.y
	while y < rect.end.y:
		var next_y := minf(rect.end.y, y + row_height)
		var row_rect := Rect2(Vector2(rect.position.x, y), Vector2(rect.size.x, next_y - y))
		_draw_cover_panel_row(rect, row_rect, radius, color, round_top, round_bottom)
		y = next_y


func _draw_cover_panel_row(full_rect: Rect2, row_rect: Rect2, radius: float, color: Color, round_top: bool, round_bottom: bool) -> void:
	var mid_y := row_rect.position.y + row_rect.size.y * 0.5
	var r := minf(radius, minf(full_rect.size.x, full_rect.size.y) * 0.5)
	var left := full_rect.position.x
	var right := full_rect.end.x
	if round_top and mid_y < full_rect.position.y + r:
		var dy_top := full_rect.position.y + r - mid_y
		var inset_top := r - sqrt(maxf(0.0, r * r - dy_top * dy_top))
		left += inset_top
		right -= inset_top
	elif round_bottom and mid_y > full_rect.end.y - r:
		var dy_bottom := mid_y - (full_rect.end.y - r)
		var inset_bottom := r - sqrt(maxf(0.0, r * r - dy_bottom * dy_bottom))
		left += inset_bottom
		right -= inset_bottom
	var clipped_width := maxf(0.0, right - left)
	if clipped_width <= 0.5:
		return
	draw_rect(Rect2(Vector2(left, row_rect.position.y), Vector2(clipped_width, row_rect.size.y + 0.75)), color)


func _draw_cover_panel_outline(rect: Rect2, radius: float, color: Color, width: float, round_top: bool, round_bottom: bool) -> void:
	var points := PackedVector2Array()
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var left := rect.position.x
	var top := rect.position.y
	var right := rect.end.x
	var bottom := rect.end.y
	if round_top:
		_append_cover_arc_points(points, Vector2(right - r, top + r), r, -PI * 0.5, 0.0, 8)
	else:
		points.append(Vector2(right, top))
	if round_bottom:
		_append_cover_arc_points(points, Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 8)
	else:
		points.append(Vector2(right, bottom))
	if round_bottom:
		_append_cover_arc_points(points, Vector2(left + r, bottom - r), r, PI * 0.5, PI, 8)
	else:
		points.append(Vector2(left, bottom))
	if round_top:
		_append_cover_arc_points(points, Vector2(left + r, top + r), r, PI, PI * 1.5, 8)
	else:
		points.append(Vector2(left, top))
	points.append(points[0])
	draw_polyline(points, color, width, true)


func _append_cover_arc_points(points: PackedVector2Array, center: Vector2, radius: float, start_angle: float, end_angle: float, segments: int) -> void:
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)


func _draw_rounded_rect_row(full_rect: Rect2, row_rect: Rect2, radius: float, color: Color) -> void:
	var mid_y := row_rect.position.y + row_rect.size.y * 0.5
	var r := minf(radius, minf(full_rect.size.x, full_rect.size.y) * 0.5)
	var left := full_rect.position.x
	var right := full_rect.end.x
	if mid_y < full_rect.position.y + r:
		var dy_top := full_rect.position.y + r - mid_y
		var inset_top := r - sqrt(maxf(0.0, r * r - dy_top * dy_top))
		left += inset_top
		right -= inset_top
	elif mid_y > full_rect.end.y - r:
		var dy_bottom := mid_y - (full_rect.end.y - r)
		var inset_bottom := r - sqrt(maxf(0.0, r * r - dy_bottom * dy_bottom))
		left += inset_bottom
		right -= inset_bottom
	var clipped_width := maxf(0.0, right - left)
	if clipped_width <= 0.5:
		return
	draw_rect(Rect2(Vector2(left, row_rect.position.y), Vector2(clipped_width, row_rect.size.y + 0.75)), color)


func _draw_alpha_rounded_rect(rect: Rect2, radius: float, color: Color, s: float) -> void:
	var row_height := maxf(1.0, s)
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var y := rect.position.y
	while y < rect.end.y:
		var next_y := minf(rect.end.y, y + row_height)
		var mid_y := (y + next_y) * 0.5
		var left := rect.position.x
		var right := rect.end.x
		if mid_y < rect.position.y + r:
			var dy_top := rect.position.y + r - mid_y
			var inset_top := r - sqrt(maxf(0.0, r * r - dy_top * dy_top))
			left += inset_top
			right -= inset_top
		elif mid_y > rect.end.y - r:
			var dy_bottom := mid_y - (rect.end.y - r)
			var inset_bottom := r - sqrt(maxf(0.0, r * r - dy_bottom * dy_bottom))
			left += inset_bottom
			right -= inset_bottom
		var clipped_width := maxf(0.0, right - left)
		if clipped_width > 0.5:
			draw_rect(Rect2(Vector2(left, y), Vector2(clipped_width, next_y - y)), color)
		y = next_y


func _draw_local_health(center: Vector2, width: float, pct: float, color: Color, s: float) -> void:
	var rect := Rect2(center - Vector2(width * 0.5, 13.0 * s), Vector2(width, 26.0 * s))
	draw_round_rect(rect, 13.0 * s, INK)
	var inner := rect.grow(-5.0 * s)
	draw_round_rect(inner, 9.0 * s, BAR_EMPTY)
	var fill := Rect2(inner.position, Vector2(inner.size.x * clampf(pct, 0.0, 1.0), inner.size.y))
	draw_round_rect(fill, 9.0 * s, color)


func _draw_rounded_texture_cover(texture: Texture2D, rect: Rect2, radius: float, fallback_color: Color, s: float) -> void:
	draw_round_rect(rect, radius, fallback_color)
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	if texture_size.x <= 1.0 or texture_size.y <= 1.0:
		return
	var cover_scale := maxf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var source_size := rect.size / cover_scale
	var source_origin := (texture_size - source_size) * 0.5
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var strip_h := maxf(1.0, 3.0 * s)
	var y := 0.0
	while y < rect.size.y:
		var next_y := minf(rect.size.y, y + strip_h)
		var mid_y := (y + next_y) * 0.5
		var inset := 0.0
		if mid_y < r:
			var dy := r - mid_y
			inset = r - sqrt(maxf(0.0, r * r - dy * dy))
		elif mid_y > rect.size.y - r:
			var dy := mid_y - (rect.size.y - r)
			inset = r - sqrt(maxf(0.0, r * r - dy * dy))
		var dest := Rect2(
			rect.position + Vector2(inset, y),
			Vector2(maxf(0.0, rect.size.x - inset * 2.0), next_y - y)
		)
		if dest.size.x > 0.5 and dest.size.y > 0.5:
			var source := Rect2(
				source_origin + Vector2(inset / cover_scale, y / cover_scale),
				dest.size / cover_scale
			)
			draw_texture_rect_region(texture, dest, source, Color.WHITE, false, true)
		y = next_y


func _draw_punishment_overlay(s: float) -> void:
	var arena := _arena_rect(s)
	var screen_alpha := _ko_screen_alpha()
	_draw_alpha_rounded_rect(arena, _stage_corner_radius(s), Color(0.03, 0.012, 0.01, 0.34 * screen_alpha), s)
	var message_center := arena.get_center() + Vector2(0.0, -18.0) * s
	var wiggle := sin(elapsed_seconds * 2.0) * 0.035
	var pop := 1.0 + sin(elapsed_seconds * 2.0 + 0.7) * 0.018
	var death_font := int(clampf(arena.size.y * 0.34, 62.0, 104.0))
	var death_outline := int(clampf(arena.size.y * 0.085, 16.0, 26.0))
	_draw_centered_fit_text_rotated(
		"Oh dear, you are dead.",
		message_center + Vector2(0.0, 2.0),
		arena.size.x - 34.0 * s,
		death_font,
		_fade_color(Color("#fff8db"), screen_alpha),
		death_outline,
		_fade_color(INK, screen_alpha),
		wiggle,
		pop * 1.04
	)
	var fill_pct := 1.0 - clampf(hero_ko_timer / HERO_KO_DURATION, 0.0, 1.0)
	var meter_size := Vector2(arena.size.x - 82.0 * s, clampf(arena.size.y * 0.15, 30.0, 40.0))
	var meter_radius := meter_size.y * 0.5
	var meter := Rect2(Vector2(arena.position.x + 41.0 * s, arena.end.y - meter_size.y - 24.0 * s), meter_size)
	draw_round_rect(Rect2(meter.position + Vector2(0.0, 5.0) * s, meter.size), meter_radius, Color(0, 0, 0, 0.30 * screen_alpha))
	draw_round_rect(meter, meter_radius, _fade_color(Color("#351814"), screen_alpha))
	var fill_rect := Rect2(meter.position, Vector2(meter.size.x * fill_pct, meter.size.y))
	draw_round_rect(fill_rect, meter_radius, _fade_color(Color("#20d47a"), screen_alpha))
	draw_round_outline(meter, meter_radius, _fade_color(INK, screen_alpha), maxf(4.0, 6.0 * s))


func _ko_banner_rect(s: float) -> Rect2:
	var width := clampf(size.x * 0.68, 420.0, size.x - 76.0 * s)
	var height := clampf(size.y * 0.58, 132.0, 158.0)
	return Rect2(Vector2((size.x - width) * 0.5, size.y * 0.24), Vector2(width, height))


func _draw_centered_text(text: String, center: Vector2, font_size: int, fill: Color, outline_size: int, outline: Color) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var baseline := center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var position := Vector2(center.x - text_size.x * 0.5, baseline)
	draw_string_outline(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, outline_size, outline)
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fill)


func _draw_left_text(font: Font, text: String, anchor: Vector2, font_size: int, fill: Color, outline_size: float, outline: Color) -> void:
	var baseline := anchor.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var position := Vector2(anchor.x, baseline)
	draw_string_outline(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, int(round(outline_size)), outline)
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fill)


func _draw_centered_fit_text_rotated(text: String, center: Vector2, max_width: float, max_font_size: int, fill: Color, outline_size: int, outline: Color, rotation: float, scale_amount: float) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var font_size := max_font_size
	while font_size > 24:
		var measured := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		if measured.x <= max_width:
			break
		font_size -= 2
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var baseline := (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var position := Vector2(-text_size.x * 0.5, baseline)
	draw_set_transform(center, rotation, Vector2(scale_amount, scale_amount))
	draw_string_outline(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, outline_size, outline)
	draw_string_outline(font, position + Vector2(0.0, 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, maxf(1.0, outline_size * 0.45), Color(0, 0, 0, 0.28))
	draw_string(font, position, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, fill)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_character_texture(texture: Texture2D, center: Vector2, target_size: Vector2, rotation: float, alpha: float, flip_h := false, force_outline := false) -> void:
	if texture == null:
		return
	var source_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return
	var fit_scale := minf(target_size.x / source_size.x, target_size.y / source_size.y)
	var draw_size := source_size * fit_scale
	var rect := Rect2(-draw_size * 0.5, draw_size)
	draw_set_transform(center, rotation, Vector2(-1.0 if flip_h else 1.0, 1.0))
	if force_outline:
		var outline := maxf(3.0, minf(draw_size.x, draw_size.y) * 0.025)
		var outline_color := Color(0, 0, 0, alpha * 0.78)
		for offset in [Vector2(-outline, 0.0), Vector2(outline, 0.0), Vector2(0.0, -outline), Vector2(0.0, outline), Vector2(-outline, -outline), Vector2(outline, -outline), Vector2(outline, outline), Vector2(-outline, outline)]:
			draw_texture_rect(texture, Rect2(rect.position + offset, rect.size), false, outline_color)
	draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _arena_rect(s: float) -> Rect2:
	var inset := 0.0
	return Rect2(Vector2(inset, inset), Vector2(size.x - inset * 2.0, size.y - inset * 2.0))


func _stage_scale() -> float:
	return minf(size.x, size.y) / 720.0


func _stage_corner_radius(s: float) -> float:
	return 66.0 * s


func _smooth01(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


func _ko_screen_alpha() -> float:
	if hero_ko_timer <= 0.0:
		return 0.0
	var elapsed_ko := HERO_KO_DURATION - hero_ko_timer
	var fade_in := _smooth01(elapsed_ko / HERO_KO_FADE_SECONDS)
	var fade_out := _smooth01(hero_ko_timer / HERO_KO_FADE_SECONDS)
	return clampf(minf(fade_in, fade_out), 0.0, 1.0)


func _fade_color(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * clampf(alpha, 0.0, 1.0))


func _ease_garage_door(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	var smooth := clamped * clamped * (3.0 - 2.0 * clamped)
	return 1.0 - pow(1.0 - smooth, 2.2)


func _hero_max_hp() -> float:
	return HERO_BASE_MAX_HP * _hero_level_multiplier()


func _hero_attack_damage_min() -> float:
	return HERO_BASE_ATTACK_DAMAGE_MIN * _hero_level_multiplier()


func _hero_attack_damage_max() -> float:
	return HERO_BASE_ATTACK_DAMAGE_MAX * _hero_level_multiplier()


func _hero_uppercut_damage_min() -> float:
	return HERO_BASE_UPPERCUT_DAMAGE_MIN * _hero_level_multiplier()


func _hero_uppercut_damage_max() -> float:
	return HERO_BASE_UPPERCUT_DAMAGE_MAX * _hero_level_multiplier()


func _roll_hero_attack_damage() -> float:
	return randf_range(_hero_attack_damage_min(), _hero_attack_damage_max())


func _roll_hero_uppercut_damage() -> float:
	return randf_range(_hero_uppercut_damage_min(), _hero_uppercut_damage_max())


func _roll_chicken_max_hp(stat_mult: float) -> float:
	return randf_range(CHICKEN_BASE_HP_MIN, CHICKEN_BASE_HP_MAX) * stat_mult


func _hero_attack_damage_range_text() -> String:
	return "%d-%d" % [int(round(_hero_attack_damage_min())), int(round(_hero_attack_damage_max()))]


func _hero_attack_interval() -> float:
	return maxf(0.34, HERO_BASE_ATTACK_INTERVAL / _hero_level_multiplier())


func _hero_level_multiplier() -> float:
	return pow(HERO_LEVEL_MULT, maxf(0.0, float(fighting_level - HERO_STAT_BASELINE_LEVEL)))


func _norm_to_stage(pos: Vector2) -> Vector2:
	var arena := _arena_rect(_stage_scale())
	return arena.position + Vector2(pos.x * arena.size.x, pos.y * arena.size.y)


func _clamp_norm_to_arena(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x, 0.035, 0.965), clampf(pos.y, 0.07, 0.93))
