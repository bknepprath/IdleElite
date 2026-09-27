extends Control

signal chicken_killed(xp_amount: int)
signal punch_landed(shield_dropped: bool)
signal knocked_out

const INK := Color("#171615")
const BAR_EMPTY := Color("#3f2b25")
const HERO_HP_BLUE := Color("#4fc3ff")
const DANGER := Color("#ee4b38")
const REWARD_GREEN := Color("#38e57e")
const ACTIVE_WAVE_BLUE := Color("#4fc3ff")
const WHITE := Color("#fffaf0")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")

const ARENA_FLOOR_PATH := "res://assets/content/fight/prototype/arena-floor.png"
const ARENA_FLOOR_PATHS := {
	"werewolves": "res://assets/content/fight/terrain/werewolves-moonlit-grass.png",
	"cave-trolls": "res://assets/content/fight/terrain/cave-trolls-cave-floor.png",
	"giants": "res://assets/content/fight/terrain/giants-mountain-stone.png",
	"vampires": "res://assets/content/fight/terrain/vampires-carpeted-hall.png",
}
const ARENA_DEPTH_COLOR := Color("#315d1d")
const ARENA_DEPTH_COLORS := {
	"werewolves": Color("#0b3f5a"),
	"cave-trolls": Color("#343832"),
	"giants": Color("#756b5b"),
	"vampires": Color("#650e14"),
}
const CHICKEN_IDLE_PATH := "res://assets/content/fight/prototype/chicken-idle.png"
const CHICKEN_WINDUP_PATH := "res://assets/content/fight/prototype/chicken-windup-v2.png"
const CHICKEN_COVER_CLEAN_PATH := "res://assets/content/fight/prototype/chicken-cover-clean.png"
const CHICKEN_HIT_PATH := "res://assets/content/fight/prototype/chicken-hit.png"
const CHICKEN_DIZZY_PATH := "res://assets/content/fight/prototype/chicken-dizzy.png"
const CHICKEN_DEFEATED_PATH := "res://assets/content/fight/prototype/chicken-defeated.png"
const CHICKEN_GRAY_IDLE_PATH := "res://assets/content/fight/prototype/chicken-gray-idle.png"
const CHICKEN_GRAY_WINDUP_PATH := "res://assets/content/fight/prototype/chicken-gray-windup-v2.png"
const CHICKEN_GRAY_HIT_PATH := "res://assets/content/fight/prototype/chicken-gray-hit.png"
const CHICKEN_GRAY_DIZZY_PATH := "res://assets/content/fight/prototype/chicken-gray-dizzy.png"
const CHICKEN_GRAY_DEFEATED_PATH := "res://assets/content/fight/prototype/chicken-gray-defeated.png"
const CHICKEN_BLACK_IDLE_PATH := "res://assets/content/fight/prototype/chicken-black-idle.png"
const CHICKEN_BLACK_WINDUP_PATH := "res://assets/content/fight/prototype/chicken-black-windup-v2.png"
const CHICKEN_BLACK_HIT_PATH := "res://assets/content/fight/prototype/chicken-black-hit.png"
const CHICKEN_BLACK_DIZZY_PATH := "res://assets/content/fight/prototype/chicken-black-dizzy.png"
const CHICKEN_BLACK_DEFEATED_PATH := "res://assets/content/fight/prototype/chicken-black-defeated.png"
const BLUE_GUY_PUNCH_PATH := "res://assets/content/fight/prototype/blue-guy-punch.png"
const BLUE_GUY_GUARD_PATH := "res://assets/content/fight/prototype/blue-guy-guard.png"
const BLUE_GUY_KO_PATH := "res://assets/content/fight/prototype/blue-guy-ko.png"
const BLUE_GUY_KO_FRAME_PATHS := [
	"res://assets/content/fight/prototype/blue-guy-ko-01.png",
	"res://assets/content/fight/prototype/blue-guy-ko-02.png",
	"res://assets/content/fight/prototype/blue-guy-ko-03.png",
	"res://assets/content/fight/prototype/blue-guy-ko-04.png",
	"res://assets/content/fight/prototype/blue-guy-ko-05.png",
	"res://assets/content/fight/prototype/blue-guy-ko-06.png",
]
const BLUE_GUY_UPPERCUT_PATH := "res://assets/content/fight/prototype/blue-guy-uppercut.png"
const COOKED_CHICKEN_DROP_PATH := "res://assets/content/fight/prototype/cooked-chicken-drop.png"
const GOBLIN_SHIELD_PATH := "res://assets/content/fight/enemies/goblins/goblin-shield.png"
const GIANT_BOULDER_PATHS := [
	"res://assets/content/fight/enemies/giants/giant-boulder-01.png",
	"res://assets/content/fight/enemies/giants/giant-boulder-02.png",
	"res://assets/content/fight/enemies/giants/giant-boulder-03.png",
]
const VAMPIRE_BAT_PATHS := [
	"res://assets/content/fight/enemies/vampires/vampire-bat-flap-01.png",
	"res://assets/content/fight/enemies/vampires/vampire-bat-flap-02.png",
]
const FIGHT_EFFECTS_PATH := "res://assets/content/fight/effects/"
const INCLUDED_SCREEN_RIGHT := {"chicken-swarm": true, "goblins": true, "rouses": true, "guys": true, "werewolves": true, "cave-trolls": true, "giants": true, "vampires": true, "dragons": true}
const MOVEMENT_FPS := 6.0
const GIANT_WALK_FPS := 10.0 / 3.0
const GUYS_RUN_FPS := 10.0
const WEREWOLF_TRANSFORM_DURATION := 0.80
const CAVE_TROLL_CANONICAL_FRAME_SCALE := 2.0

const HERO_BASE_MAX_HP := 33.0
const HERO_BASE_ATTACK_DAMAGE_MIN := 8.0
const HERO_BASE_ATTACK_DAMAGE_MAX := 11.0
const HERO_BASE_UPPERCUT_DAMAGE_MIN := 22.0
const HERO_BASE_UPPERCUT_DAMAGE_MAX := 30.0
const HERO_BASE_ATTACK_INTERVAL := 1.05
const HERO_LEVEL_MULT := 1.03
const HERO_STAT_BASELINE_LEVEL := 5
const HERO_HITBOX_RANGE := 0.205
const HERO_HITBOX_RADIUS := 0.080
const HERO_UPPERCUT_RANGE := 0.315
const HERO_UPPERCUT_RADIUS := 0.205
const CHICKEN_PUNCH_RANGE := 0.145
const CHICKEN_PUNCH_RADIUS := 0.040
const CHICKEN_UPPERCUT_RANGE := 0.190
const CHICKEN_UPPERCUT_RADIUS := 0.075
const HERO_UPPERCUT_CHANCE := 0.13
const HERO_UPPERCUT_COOLDOWN := 3.4
const CHICKEN_UPPERCUT_KNOCK_SECONDS := 0.46
const CHICKEN_UPPERCUT_KNOCK_SPEED := 0.54
const GUYS_PUNCH_FLEE_RADIUS := 0.33
const GUYS_PUNCH_FLEE_SECONDS := 0.70
const GUYS_ATTACK_RANGE := 0.22
const GUYS_COUNTER_WINDUP := 0.18
const GUYS_UNLOCK_LEVEL := 32
const GUYS_LEVEL_ADVANTAGE_MULT := 1.018
const GIANTS_LEVEL_ADVANTAGE_MULT := 1.028
const GUYS_END_WAVE_STAT_SCALE := 0.35
const GUYS_OPENING_DAMAGE_SCALE := 1.10
const ENEMY_DEATH_FADE_DELAY := 1.93
const ENEMY_DEATH_FADE_SECONDS := 0.32
const ENEMY_DEATH_LIFETIME := ENEMY_DEATH_FADE_DELAY + ENEMY_DEATH_FADE_SECONDS
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
const RANDOM_SPAWN_ROLL_SECONDS := 0.25
const RANDOM_SPAWN_EXPECTED_SCALE := 0.70
const AREA_CLEAR_RESTART_DELAY := 1.45
const HERO_KO_DURATION := 3.4
const HERO_KO_FADE_SECONDS := 0.48
const HERO_KO_FALL_SECONDS := 0.84
const HERO_KO_STAND_SECONDS := 0.62
const GIANT_TOSS_DURATION := 1.12
const GIANT_TOSS_TRAVEL_SECONDS := 0.46
const GIANT_TOSS_STAND_START := 0.72
const GIANT_TOSS_DISTANCE := 0.30
const GIANT_STOMP_BUMP_DURATION := 0.34
const GIANT_STOMP_BUMP_DISTANCE := 0.055
const GIANT_STOMP_BUMP_HEIGHT := 18.0
const GIANT_BOULDER_PICKUP_RANGE := 0.15
const GIANT_BOULDER_THROW_DURATION := 0.72
const GIANT_BOULDER_THROW_DISTANCE := 0.26
const GIANT_BOULDER_HIT_RADIUS := 0.085
const GIANT_BOULDER_ATTACK_CHANCE := 0.30
const VAMPIRE_BAT_COUNT := 4
const VAMPIRE_BAT_MOVE_SPEED := 0.20
const VAMPIRE_BAT_SURROUND_RADIUS := 0.18
const VAMPIRE_BAT_SLOT_REACHED_RADIUS := 0.04
const VAMPIRE_BAT_ORBIT_SPEED := 0.42
const VAMPIRE_BAT_ATTACK_SECONDS := 0.56
const VAMPIRE_BAT_DIRECTION_RESPONSE := 5.0
const VAMPIRE_BAT_FACING_THRESHOLD := 0.35
const VAMPIRE_BAT_SPAWN_INVULN_SECONDS := 0.75
const VAMPIRE_BAT_DAMAGE_SCALE := 0.15
const VAMPIRE_BAT_ATTACK_CHANCE := 0.44
const VAMPIRE_BAT_CHANNEL_CHANCE := 0.50
const VAMPIRE_BAT_CHANNEL_BEAT_SECONDS := 0.55
const VAMPIRE_BAT_CHANNEL_START_SECONDS := 0.45
const VAMPIRE_BAT_CHANNEL_MAX_COUNT := 7
const VAMPIRE_SHOCKWAVE_ATTACK_CHANCE := 0.18
const VAMPIRE_BAT_BUFF_SCALE_STEP := 0.20
const VAMPIRE_SHOCKWAVE_SPEED := 180.0
const VAMPIRE_SHOCKWAVE_MAX_RADIUS := 210.0
const VAMPIRE_SHOCKWAVE_HERO_BUFF_MULT := 1.05
const VAMPIRE_BITE_CHANCE := 0.12
const VAMPIRE_BITE_HEALTH_RATIO := 0.25
const VAMPIRE_TELEPORT_HALF_SECONDS := 0.24
const VAMPIRE_WALK_CHANCE := 0.35
const VAMPIRE_MAX_IDLE_SECONDS := 1.75
const VAMPIRE_WAVE_REST_SECONDS := 12.0
const VAMPIRE_GIANT_TRANSFORM_CHANCE := 0.28
const VAMPIRE_GIANT_TRANSFORM_HEALTH_RATIO := 0.50
const VAMPIRE_GIANT_TRANSFORM_DURATION := 2.25
const VAMPIRE_GIANT_HEALTH_MULT := 2.0
const VAMPIRE_GIANT_DAMAGE_MULT := 1.60
const VAMPIRE_GIANT_SIZE_MULT := 3.5
const VAMPIRE_GIANT_BUFF_SCALE_STEP := 0.05
const VAMPIRE_GIANT_FLIGHT_CHANCE := 0.28
const CAVE_TROLL_STUN_DURATION := 0.55
const KO_RETREAT_SPEED := 0.24
const KO_RETREAT_FADE_SECONDS := 0.42
const KO_RETREAT_WIGGLE_SCALE := 0.25
const COVER_OPEN_SPEED := 4.8
const COOKED_CHICKEN_DROP_CHANCE := 0.07
const COOKED_CHICKEN_HEAL_RATIO := 0.16
const COOKED_CHICKEN_PICKUP_RADIUS := 0.12
const COOKED_CHICKEN_LIFETIME := 8.0
const COOKED_CHICKEN_CONSUME_SECONDS := 0.62
const DIAMOND_HERO_DRAW_SCALE := 0.62
const DIAMOND_ENEMY_DRAW_SCALE := 0.54
const DRAGON_BRAWL_RANGE := 0.30
const DRAGON_BRAWL_MIN_HORIZONTAL_GAP := 0.16
const DRAGON_MELEE_DEPTH_THRESHOLD := 0.055
const DRAGON_MELEE_VERTICAL_THRESHOLD := 0.10
const DRAGON_BREATH_RANGE := 0.39
const DRAGON_POUNCE_RANGE := 0.34
const DRAGON_POUNCE_DISTANCE := 0.13
const DRAGON_POUNCE_IMPACT_RANGE := 0.23
const DRAGON_POUNCE_STRIKE_SECONDS := 0.82
const DRAGON_POUNCE_LAND_PROGRESS := 0.68
const DRAGON_BREATH_STRIKE_SECONDS := 1.20
const DRAGON_BREATH_BEAT_SECONDS := 0.18
const DRAGON_BREATH_BURST_COUNT := 7
const DRAGON_BREATH_TUFT_SPACING := 0.044
const DRAGON_BREATH_DEPTH_THRESHOLD := 0.09
const DRAGON_BREATH_DEPTH_SLOPE := 0.70
const DRAGON_MOUTH_OFFSET := Vector2(0.18, -0.255)

const FIGHT_PROFILES := {
	"chicken-swarm": {"kind": "swarm", "curve": [4, 5, 6, 7, 8], "cap": 8, "final": 12, "signature": "swarm_lunge"},
	"goblins": {"kind": "skirmisher", "curve": [2, 3, 3, 4, 5], "cap": 3, "final": 5, "signature": "shielded_hold_ground"},
	"rouses": {"kind": "brute", "curve": [1, 1, 2, 2, 3], "cap": 2, "final": 3, "signature": "momentum_roll"},
	"guys": {"kind": "duelist", "curve": [16, 20, 24, 28, 32], "cap": 24, "final": 40, "signature": "duelist_guard"},
	"werewolves": {"kind": "charger", "curve": [1, 1, 2, 2, 3], "cap": 2, "final": 3, "signature": "howl_charge"},
	"cave-trolls": {"kind": "heavy", "curve": [1, 1, 1, 2, 2], "cap": 2, "final": 2, "signature": "alternating_club_swing_ground_pound"},
	"giants": {"kind": "scaled_guy", "curve": [1, 1.3, 1.6, 1.9, 2], "cap": 2, "final": 2, "signature": "opportunistic_stomp_toss_boulder"},
	"vampires": {"kind": "elusive", "curve": [1, 1, 1, 2, 2], "cap": 2, "final": 2, "signature": "teleport_cape_bats_low_health_bite_drain"},
	"dragons": {"kind": "boss_wave", "curve": [1, 1, 1, 1, 1], "cap": 1, "final": 1, "signature": "breath_land"}
}

var elapsed_seconds := 0.0
var arena_floor: Texture2D
var idle_chicken: Texture2D
var windup_chicken: Texture2D
var cover_clean_chicken: Texture2D
var hit_chicken: Texture2D
var dizzy_chicken: Texture2D
var defeated_chicken: Texture2D
var gray_idle_chicken: Texture2D
var gray_windup_chicken: Texture2D
var gray_hit_chicken: Texture2D
var gray_dizzy_chicken: Texture2D
var gray_defeated_chicken: Texture2D
var black_idle_chicken: Texture2D
var black_windup_chicken: Texture2D
var black_hit_chicken: Texture2D
var black_dizzy_chicken: Texture2D
var black_defeated_chicken: Texture2D
var blue_guy_punch: Texture2D
var blue_guy_guard: Texture2D
var blue_guy_ko: Texture2D
var blue_guy_ko_frames: Array[Texture2D] = []
var blue_guy_uppercut: Texture2D
var cooked_chicken_drop: Texture2D
var goblin_shield: Texture2D
var giant_boulder_textures: Array[Texture2D] = []
var vampire_bat_textures: Array[Texture2D] = []
var enemy_attack_frames: Dictionary = {}
var chicken_attack_variant_frames: Dictionary = {}
var enemy_movement_frames: Dictionary = {}
var texture_used_rect_cache: Dictionary = {}
var effect_frames: Dictionary = {}
var active_effects: Array[Dictionary] = []

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
var hero_hurt_cooldown := 0.0
var hero_purple_buff_punches := 0
var hero_attack_purple_buffed := false
var hero_toss_timer := 0.0
var hero_toss_start := hero_pos
var hero_toss_target := hero_pos
var hero_toss_direction := Vector2.RIGHT
var hero_bump_timer := 0.0
var hero_stun_timer := 0.0
var hero_ko_timer := 0.0
var spawn_timer := 0.0
var chicken_serial := 0
var chickens: Array[Dictionary] = []
var giant_boulders: Array[Dictionary] = []
var vampire_bats: Array[Dictionary] = []
var vampire_shockwaves: Array[Dictionary] = []
var vampire_bat_next_id := 0
var food_drops: Array[Dictionary] = []
var feather_particles: Array[Dictionary] = []
var smoke_puffs: Array[Dictionary] = []
var ko_count := 0
var arena_shape := "round"
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
var area_clear_restart_timer := 0.0
var fighting_level := 1
var enemy_unlock_level := HERO_STAT_BASELINE_LEVEL
var cover_health_current := 30
var cover_health_maximum := 30
var cover_health_regen_fraction := 1.0
var active := false
var cover_open_amount := 0.0
var hit_stop_timer := 0.0
var module_shake_timer := 0.0
var module_shake_duration := 0.0
var module_shake_strength := 0.0
var diamond_stats_tucked := false
var stage_title := "Fight Chickens"
var enemy_base_hp_min := CHICKEN_BASE_HP_MIN
var enemy_base_hp_max := CHICKEN_BASE_HP_MAX
var enemy_unlock_health_scale := 1.0
var enemy_damage := CHICKEN_DAMAGE
var enemy_speed_scale := 1.0
var enemy_spawn_rhythm := 1.0
var enemy_id := "chicken-swarm"
var enemy_kind := "swarm"
var enemy_signature := "swarm_lunge"
var enemy_population_curve: Array = [4, 5, 6, 7, 8]
var enemy_population_cap := MAX_CHICKENS
var enemy_final_population := 12
var enemy_idle_art_path := ""
var enemy_sprite_scale := 1.0
var enemy_art_faces_right := false
var combat_base_reward_xp := 0
var combat_par_reward_xp := 0
var combat_reward_xp := 0
var combat_kill_reward_share := 0.0
var planned_kill_count := 0
var kill_count_awarded := 0
var kill_xp_already_awarded := 0
var area_clear_xp_awarded := false
var runtime_assets_loaded := false


func load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded as Texture2D
	var source_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(source_path):
		var source_image := Image.new()
		if source_image.load(source_path) == OK:
			return ImageTexture.create_from_image(source_image)
	var image := Image.new()
	var result := image.load(source_path)
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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	clip_contents = arena_shape != "diamond"
	blue_guy_guard = load_png_texture(BLUE_GUY_GUARD_PATH)
	_ensure_labels()
	if active:
		_ensure_runtime_assets_loaded()
		_seed_fight()
	else:
		_seed_inactive_state()
	set_process(active)


func _gui_input(event: InputEvent) -> void:
	if arena_shape != "diamond":
		return
	var tap_pos := Vector2.INF
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		tap_pos = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		tap_pos = (event as InputEventScreenTouch).position
	if tap_pos == Vector2.INF:
		return
	if try_handle_primary_tap(tap_pos):
		accept_event()


func try_handle_primary_tap(tap_pos: Vector2) -> bool:
	return _try_shatter_held_boulder(tap_pos) or _toggle_diamond_stats_if_tapped(tap_pos)


func _toggle_diamond_stats_if_tapped(tap_pos: Vector2) -> bool:
	if arena_shape != "diamond" or not _diamond_stats_plate_draw_rect(_stage_scale()).has_point(tap_pos):
		return false
	diamond_stats_tucked = not diamond_stats_tucked
	queue_redraw()
	return true


func setup_fighting_level(level: int) -> void:
	var old_max_hp := _hero_max_hp()
	fighting_level = maxi(1, level)
	_refresh_combat_reward_xp()
	var new_max_hp := _hero_max_hp()
	if hero_ko_timer <= 0.0 and old_max_hp > 0.0:
		hero_hp = clampf(hero_hp / old_max_hp * new_max_hp, 1.0, new_max_hp)


func setup_blue_guy_health(current_hp: int, maximum_hp: int, regen_fraction: float) -> void:
	cover_health_maximum = maxi(1, maximum_hp)
	cover_health_current = clampi(current_hp, 0, cover_health_maximum)
	cover_health_regen_fraction = clampf(regen_fraction, 0.0, 1.0)
	queue_redraw()


func setup_action(action: Dictionary) -> void:
	runtime_assets_loaded = false
	stage_title = str(action.get("name", stage_title))
	enemy_unlock_level = maxi(1, int(action.get("unlock", HERO_STAT_BASELINE_LEVEL)))
	if title_label != null:
		title_label.text = stage_title
	var combat: Variant = action.get("combat", {})
	if combat is Dictionary:
		var combat_stats: Dictionary = combat as Dictionary
		var base_health := maxf(1.0, float(combat_stats.get("health", CHICKEN_BASE_HP_MAX)))
		enemy_base_hp_min = maxf(1.0, base_health * 0.85)
		enemy_base_hp_max = maxf(enemy_base_hp_min, base_health * 1.15)
		enemy_unlock_health_scale = clampf(float(combat_stats.get("unlock_health_scale", 1.0)), 0.05, 1.0)
		enemy_damage = maxf(0.1, float(combat_stats.get("contact_damage", CHICKEN_DAMAGE)))
		enemy_speed_scale = maxf(0.1, float(combat_stats.get("speed", 1.0)))
		enemy_spawn_rhythm = maxf(0.1, float(combat_stats.get("spawn_rhythm", 1.0)))
		enemy_id = str(combat_stats.get("enemy_id", "chicken-swarm"))
		enemy_kind = str(combat_stats.get("enemy_kind", "swarm"))
		var profile: Dictionary = FIGHT_PROFILES.get(enemy_id, FIGHT_PROFILES["chicken-swarm"]) as Dictionary
		enemy_signature = str(combat_stats.get("signature", profile.get("signature", "swarm_lunge")))
		enemy_population_curve = (combat_stats.get("population_curve", profile.get("curve", [4, 5, 6, 7, 8])) as Array).duplicate()
		enemy_population_cap = maxi(1, int(combat_stats.get("population_cap", profile.get("cap", MAX_CHICKENS))))
		enemy_final_population = maxi(1, int(combat_stats.get("final_population", profile.get("final", 12))))
		combat_base_reward_xp = maxi(0, int(floor(float(combat_stats.get("reward_xp", 0.0)))))
		combat_par_reward_xp = maxi(combat_base_reward_xp, int(floor(float(combat_stats.get("par_reward_xp", combat_base_reward_xp)))))
		_refresh_combat_reward_xp()
		combat_kill_reward_share = clampf(float(combat_stats.get("kill_reward_share", 0.0)), 0.0, 1.0)
		planned_kill_count = _planned_kill_count_for_reward()
		enemy_sprite_scale = _enemy_sprite_scale_for_id(enemy_id)
		enemy_art_faces_right = true if INCLUDED_SCREEN_RIGHT.has(enemy_id) else not (enemy_id in ["chicken-swarm", "dragons"])
	arena_floor = load_png_texture(_arena_floor_path_for_enemy(enemy_id))
	enemy_idle_art_path = str(action.get("art", ""))
	if active:
		_ensure_runtime_assets_loaded()
		_seed_fight()
	else:
		_apply_enemy_preview_art_path(enemy_idle_art_path)
		_seed_inactive_state()
	queue_redraw()


func _ensure_runtime_assets_loaded() -> void:
	if runtime_assets_loaded:
		return
	blue_guy_punch = load_png_texture(BLUE_GUY_PUNCH_PATH)
	if blue_guy_guard == null:
		blue_guy_guard = load_png_texture(BLUE_GUY_GUARD_PATH)
	blue_guy_ko = load_png_texture(BLUE_GUY_KO_PATH)
	blue_guy_ko_frames.clear()
	for frame_path in BLUE_GUY_KO_FRAME_PATHS:
		var ko_frame := load_png_texture(frame_path)
		if ko_frame != null:
			blue_guy_ko_frames.append(ko_frame)
	blue_guy_uppercut = load_png_texture(BLUE_GUY_UPPERCUT_PATH)
	cooked_chicken_drop = load_png_texture(COOKED_CHICKEN_DROP_PATH)
	_load_chicken_state_textures()
	_load_enemy_special_textures()
	_load_monster_movement_frames()
	_load_effect_frames()
	_load_enemy_attack_frames()
	_apply_enemy_art_path(enemy_idle_art_path)
	runtime_assets_loaded = true


func _refresh_combat_reward_xp() -> void:
	var ramp_levels := maxi(1, mini(8, 99 - enemy_unlock_level))
	var progress := clampf(float(fighting_level - enemy_unlock_level) / float(ramp_levels), 0.0, 1.0)
	combat_reward_xp = int(round(lerpf(float(combat_base_reward_xp), float(combat_par_reward_xp), progress * progress)))


func _arena_floor_path_for_enemy(id: String) -> String:
	return str(ARENA_FLOOR_PATHS.get(id, ARENA_FLOOR_PATH))


func _arena_depth_color_for_enemy(id: String) -> Color:
	return ARENA_DEPTH_COLORS.get(id, ARENA_DEPTH_COLOR) as Color


func _reset_reward_ledger() -> void:
	planned_kill_count = _planned_kill_count_for_reward()
	kill_count_awarded = 0
	kill_xp_already_awarded = 0
	area_clear_xp_awarded = false


func _planned_kill_count_for_reward() -> int:
	var planned := 0
	if enemy_population_curve.is_empty():
		planned = NORMAL_WAVE_COUNT * MAX_CHICKENS
	else:
		for wave in range(NORMAL_WAVE_COUNT):
			planned += maxi(1, int(enemy_population_curve[clampi(wave, 0, enemy_population_curve.size() - 1)]))
	return planned + enemy_final_population


func _xp_reward_for_kill() -> int:
	kill_count_awarded += 1
	if planned_kill_count <= 0:
		return 0
	var target := mini(kill_xp_budget(), int(floor(float(kill_xp_budget()) * float(kill_count_awarded) / float(planned_kill_count))))
	var payout := maxi(0, target - kill_xp_already_awarded)
	kill_xp_already_awarded += payout
	return payout


func kill_xp_budget() -> int:
	return int(floor(float(combat_reward_xp) * combat_kill_reward_share))


func _xp_reward_for_area_clear() -> int:
	if area_clear_xp_awarded:
		return 0
	area_clear_xp_awarded = true
	return maxi(0, combat_reward_xp - kill_xp_already_awarded)


func _apply_enemy_art_path(idle_art_path: String) -> void:
	if idle_art_path.is_empty():
		return
	var idle_res := _asset_to_res_path(idle_art_path)
	if idle_res.ends_with("-states-source.png") and enemy_id == "giants":
		var source := load_png_texture(idle_res)
		if source == null:
			return
		var frame_width := float(source.get_width()) / 4.0
		idle_chicken = _atlas_texture(source, Rect2(0.0, 0.0, frame_width, source.get_height()))
		cover_clean_chicken = idle_chicken
		hit_chicken = _atlas_texture(source, Rect2(frame_width, 0.0, frame_width, source.get_height()))
		dizzy_chicken = _atlas_texture(source, Rect2(frame_width * 2.0, 0.0, frame_width, source.get_height()))
		defeated_chicken = _atlas_texture(source, Rect2(frame_width * 3.0, 0.0, frame_width, source.get_height()))
		return
	if not idle_res.ends_with("-idle.png"):
		return
	var loaded_idle := load_png_texture(idle_res)
	if loaded_idle == null:
		return
	idle_chicken = loaded_idle
	cover_clean_chicken = loaded_idle
	hit_chicken = load_png_texture(idle_res.replace("-idle.png", "-hit.png"))
	dizzy_chicken = load_png_texture(idle_res.replace("-idle.png", "-dizzy.png"))
	defeated_chicken = load_png_texture(idle_res.replace("-idle.png", "-defeated.png"))
	if hit_chicken == null:
		hit_chicken = idle_chicken
	if dizzy_chicken == null:
		dizzy_chicken = idle_chicken
	if defeated_chicken == null:
		defeated_chicken = idle_chicken
	gray_idle_chicken = null
	gray_windup_chicken = null
	gray_hit_chicken = null
	gray_dizzy_chicken = null
	gray_defeated_chicken = null
	black_idle_chicken = null
	black_windup_chicken = null
	black_hit_chicken = null
	black_dizzy_chicken = null
	black_defeated_chicken = null


func _apply_enemy_preview_art_path(idle_art_path: String) -> void:
	if idle_art_path.is_empty():
		return
	var idle_res := _asset_to_res_path(idle_art_path)
	if idle_res.ends_with("-states-source.png") and enemy_id == "giants":
		var source := load_png_texture(idle_res)
		if source != null:
			var frame_width := float(source.get_width()) / 4.0
			idle_chicken = _atlas_texture(source, Rect2(0.0, 0.0, frame_width, source.get_height()))
			cover_clean_chicken = idle_chicken
		return
	if idle_res.ends_with("-idle.png"):
		idle_chicken = load_png_texture(idle_res)
		cover_clean_chicken = idle_chicken


func _load_chicken_state_textures() -> void:
	idle_chicken = null
	windup_chicken = null
	cover_clean_chicken = null
	hit_chicken = null
	dizzy_chicken = null
	defeated_chicken = null
	gray_idle_chicken = null
	gray_windup_chicken = null
	gray_hit_chicken = null
	gray_dizzy_chicken = null
	gray_defeated_chicken = null
	black_idle_chicken = null
	black_windup_chicken = null
	black_hit_chicken = null
	black_dizzy_chicken = null
	black_defeated_chicken = null
	if enemy_id != "chicken-swarm":
		return
	idle_chicken = load_png_texture(CHICKEN_IDLE_PATH)
	windup_chicken = load_png_texture(CHICKEN_WINDUP_PATH)
	cover_clean_chicken = load_png_texture(CHICKEN_COVER_CLEAN_PATH)
	hit_chicken = load_png_texture(CHICKEN_HIT_PATH)
	dizzy_chicken = load_png_texture(CHICKEN_DIZZY_PATH)
	defeated_chicken = load_png_texture(CHICKEN_DEFEATED_PATH)
	gray_idle_chicken = load_png_texture(CHICKEN_GRAY_IDLE_PATH)
	gray_windup_chicken = load_png_texture(CHICKEN_GRAY_WINDUP_PATH)
	gray_hit_chicken = load_png_texture(CHICKEN_GRAY_HIT_PATH)
	gray_dizzy_chicken = load_png_texture(CHICKEN_GRAY_DIZZY_PATH)
	gray_defeated_chicken = load_png_texture(CHICKEN_GRAY_DEFEATED_PATH)
	black_idle_chicken = load_png_texture(CHICKEN_BLACK_IDLE_PATH)
	black_windup_chicken = load_png_texture(CHICKEN_BLACK_WINDUP_PATH)
	black_hit_chicken = load_png_texture(CHICKEN_BLACK_HIT_PATH)
	black_dizzy_chicken = load_png_texture(CHICKEN_BLACK_DIZZY_PATH)
	black_defeated_chicken = load_png_texture(CHICKEN_BLACK_DEFEATED_PATH)


func _load_enemy_special_textures() -> void:
	goblin_shield = null
	giant_boulder_textures.clear()
	vampire_bat_textures.clear()
	if enemy_id == "goblins":
		goblin_shield = load_png_texture(GOBLIN_SHIELD_PATH)
	elif enemy_id == "giants":
		for boulder_path in GIANT_BOULDER_PATHS:
			var boulder_texture := load_png_texture(boulder_path)
			if boulder_texture != null:
				giant_boulder_textures.append(boulder_texture)
	elif enemy_id == "vampires":
		for bat_path in VAMPIRE_BAT_PATHS:
			var bat_texture := load_png_texture(bat_path)
			if bat_texture != null:
				vampire_bat_textures.append(bat_texture)


func _load_enemy_attack_frames() -> void:
	var family := "chicken" if enemy_id == "chicken-swarm" else enemy_id
	var prefixes := ["%s-attack" % family]
	if enemy_id == "dragons":
		prefixes = ["dragons-claw", "dragons-breath", "dragons-pounce"]
	enemy_attack_frames.clear()
	for prefix in prefixes:
		var frames: Array[Texture2D] = []
		for frame in range(1, 5):
			frames.append(load_png_texture("res://assets/content/fight/%s/%s-%02d.png" % ["prototype" if family == "chicken" else "enemies/%s" % enemy_id, prefix, frame]))
		enemy_attack_frames[prefix] = frames
	if enemy_id == "dragons":
		for aim in ["far", "near"]:
			for attack in ["breath", "claw"]:
				var hold := load_png_texture("res://assets/content/fight/enemies/dragons/dragons-%s-%s.png" % [attack, aim])
				enemy_attack_frames["dragons-%s-%s-hold" % [attack, aim]] = [hold]
		for aim in ["vertical-far", "vertical-near"]:
			var hold := load_png_texture("res://assets/content/fight/enemies/dragons/dragons-claw-%s.png" % aim)
			enemy_attack_frames["dragons-claw-%s-hold" % aim] = [hold]
	if enemy_id == "cave-trolls":
		var pound_source := load_png_texture("res://assets/content/fight/enemies/cave-trolls/cave-trolls-pound-source.png")
		if pound_source != null:
			var cell_size := Vector2(float(pound_source.get_width()), float(pound_source.get_height())) * 0.5
			var pound_frames: Array[Texture2D] = []
			for frame in range(4):
				var cell := Vector2(float(frame % 2), float(floori(float(frame) / 2.0)))
				pound_frames.append(_atlas_texture(pound_source, Rect2(cell * cell_size, cell_size)))
			enemy_attack_frames["cave-trolls-pound"] = pound_frames
	if enemy_id == "vampires":
		var cape_source := load_png_texture("res://assets/content/fight/enemies/vampires/vampires-cape-summon-source.png")
		if cape_source != null:
			var cell_size := Vector2(float(cape_source.get_width()), float(cape_source.get_height())) * 0.5
			var cape_frames: Array[Texture2D] = []
			for frame in range(4):
				var cell := Vector2(float(frame % 2), float(floori(float(frame) / 2.0)))
				cape_frames.append(_atlas_texture(cape_source, Rect2(cell * cell_size, cell_size)))
			enemy_attack_frames["vampires-cape"] = cape_frames
		var mind_source := load_png_texture("res://assets/content/fight/enemies/vampires/vampires-mind.png")
		if mind_source != null:
			var mind_cell_size := Vector2(float(mind_source.get_width()), float(mind_source.get_height())) * 0.5
			var mind_frames: Array[Texture2D] = []
			for frame in range(4):
				var cell := Vector2(float(frame % 2), float(floori(float(frame) / 2.0)))
				mind_frames.append(_atlas_texture(mind_source, Rect2(cell * mind_cell_size, mind_cell_size)))
			enemy_attack_frames["vampires-mind"] = mind_frames
		var giant_attack: Array[Texture2D] = []
		for frame in range(4):
			giant_attack.append(load_png_texture("res://assets/content/fight/enemies/vampires/giant-bat/attack/frame-%02d.png" % frame))
		enemy_attack_frames["vampire-giant-attack"] = giant_attack
	chicken_attack_variant_frames.clear()
	if enemy_id == "chicken-swarm":
		for variant in ["white", "gray", "black"]:
			var prefix := "chicken-attack" if variant == "white" else "chicken-%s-attack" % variant
			var frames: Array[Texture2D] = []
			for frame in range(1, 5):
				frames.append(load_png_texture("res://assets/content/fight/prototype/%s-%02d.png" % [prefix, frame]))
			chicken_attack_variant_frames[variant] = frames


func _load_monster_movement_frames() -> void:
	enemy_movement_frames.clear()
	if enemy_id == "chicken-swarm":
		for variant in ["white", "gray", "black"]:
			var chicken_frames: Array[Texture2D] = []
			for frame in range(1, 5):
				var name := "chicken-white-move-%02d.png" % frame if variant == "white" else "chicken-%s-move-%02d.png" % [variant, frame]
				chicken_frames.append(load_png_texture("res://assets/content/fight/prototype/%s" % name))
			enemy_movement_frames["chicken-swarm:%s" % variant] = chicken_frames
		return
	if enemy_id == "guys":
		for motion in ["walk", "run"]:
			var guy_frames: Array[Texture2D] = []
			for frame in range(1, 5):
				guy_frames.append(load_png_texture("res://assets/content/fight/enemies/guys/guys-%s-%02d.png" % [motion, frame]))
			if motion == "run":
				var walk_frames: Array = enemy_movement_frames.get("guys", []) as Array
				guy_frames.insert(1, walk_frames[2])
				guy_frames.insert(4, walk_frames[0])
			enemy_movement_frames["guys" if motion == "walk" else "guys-run"] = guy_frames
		return
	if enemy_id in ["goblins", "rouses", "werewolves", "cave-trolls", "giants", "vampires", "dragons"]:
		var family := enemy_id
		var frames: Array[Texture2D] = []
		var frame_count := 8 if family == "giants" else 4
		var movement_prefix := "dragons-low-walk" if family == "dragons" else "%s-move" % family
		for frame in range(1, frame_count + 1):
			frames.append(load_png_texture("res://assets/content/fight/enemies/%s/%s-%02d.png" % [family, movement_prefix, frame]))
		enemy_movement_frames[family] = frames
	if enemy_id == "werewolves":
		var werewolf_transform: Array[Texture2D] = []
		for frame in range(1, 6):
			werewolf_transform.append(load_png_texture("res://assets/content/fight/enemies/werewolves/werewolves-transform-%02d.png" % frame))
		enemy_movement_frames["werewolves-transform"] = werewolf_transform
	elif enemy_id == "vampires":
		var giant_walk: Array[Texture2D] = []
		for frame in range(8):
			giant_walk.append(load_png_texture("res://assets/content/fight/enemies/vampires/giant-bat/walk/frame-%02d.png" % frame))
		enemy_movement_frames["vampire-giant-walk"] = giant_walk
		for animation in ["transform", "flight"]:
			var giant_frames: Array[Texture2D] = []
			var giant_frame_count := 4 if animation == "transform" else 3
			for frame in range(giant_frame_count):
				giant_frames.append(load_png_texture("res://assets/content/fight/enemies/vampires/giant-bat/%s/frame-%02d.png" % [animation, frame]))
			enemy_movement_frames["vampire-giant-%s" % animation] = giant_frames


func _load_effect_frames() -> void:
	effect_frames.clear()
	var effects := ["hit-impact-yellow", "dizzy-stars"]
	if enemy_id == "dragons":
		effects.append_array(["dragon-breath-flame", "cave-troll-slam"])
	elif enemy_id == "cave-trolls":
		effects.append("cave-troll-slam")
	elif enemy_id == "werewolves":
		effects.append("wolf-claw-tear")
	for effect in effects:
		var frames: Array[Texture2D] = []
		for frame in range(1, 5):
			frames.append(load_png_texture("%s%s-%02d.png" % [FIGHT_EFFECTS_PATH, effect, frame]))
		effect_frames[effect] = frames
	if enemy_id == "dragons":
		var fire_tuft := load_png_texture(FIGHT_EFFECTS_PATH + "dragon-breath-fire-tuft.png")
		effect_frames["dragon-breath-fire-tuft"] = [fire_tuft, fire_tuft, fire_tuft, fire_tuft]
		effect_frames["dragon-pounce-shockwave"] = effect_frames.get("cave-troll-slam", [])


func _enemy_attack_texture(chicken: Dictionary) -> Texture2D:
	var phase := str(chicken.get("attack_phase", ""))
	var teleport_phase := str(chicken.get("vampire_teleport_phase", ""))
	if phase.is_empty() and teleport_phase.is_empty() and not (enemy_id == "guys" and bool(chicken.get("guarding", false))):
		return null
	var prefix := "chicken-attack" if enemy_id == "chicken-swarm" else "%s-attack" % enemy_id
	if enemy_id == "cave-trolls" and str(chicken.get("cave_troll_attack_kind", "pound")) == "pound":
		prefix = "cave-trolls-pound"
	if enemy_id == "dragons":
		var dragon_kind := str(chicken.get("dragon_attack_kind", "brawl"))
		prefix = "dragons-claw" if dragon_kind == "brawl" else ("dragons-pounce" if dragon_kind == "pounce" else "dragons-breath")
		if phase == "strike" and prefix == "dragons-breath":
			var aim := str(chicken.get("dragon_breath_aim", "straight"))
			if aim != "straight":
				var hold_frames: Array = enemy_attack_frames.get("dragons-breath-%s-hold" % aim, []) as Array
				if not hold_frames.is_empty() and hold_frames[0] != null:
					return hold_frames[0] as Texture2D
		if phase == "strike" and prefix == "dragons-claw":
			var aim := str(chicken.get("dragon_melee_aim", "straight"))
			if aim != "straight":
				var hold_frames: Array = enemy_attack_frames.get("dragons-claw-%s-hold" % aim, []) as Array
				if not hold_frames.is_empty() and hold_frames[0] != null:
					return hold_frames[0] as Texture2D
	if enemy_id == "vampires":
		var vampire_kind := str(chicken.get("vampire_attack_kind", "swipe"))
		if bool(chicken.get("vampire_giant_transformed", false)):
			prefix = "vampire-giant-attack"
			if vampire_kind == "swoosh":
				var flight_frames: Array = enemy_movement_frames.get("vampire-giant-flight", []) as Array
				if not flight_frames.is_empty():
					var flight_progress := clampf(float(chicken.get("signature_t", 0.0)), 0.0, 1.0)
					return flight_frames[clampi(int(floor(flight_progress * flight_frames.size())), 0, flight_frames.size() - 1)] as Texture2D
		elif not teleport_phase.is_empty() or vampire_kind == "bats":
			prefix = "vampires-cape"
		elif vampire_kind == "shockwave":
			prefix = "vampires-mind"
	var frames: Array = enemy_attack_frames.get(prefix, []) as Array
	if enemy_id == "chicken-swarm":
		frames = chicken_attack_variant_frames.get(str(chicken.get("variant", "white")), []) as Array
	if frames.size() < 4:
		return null
	if enemy_id == "vampires" and not teleport_phase.is_empty():
		var progress := 1.0 - float(chicken.get("vampire_teleport_fx_timer", 0.0)) / VAMPIRE_TELEPORT_HALF_SECONDS
		var index := clampi(int(floor(progress * 2.0)), 0, 1) + (0 if teleport_phase == "out" else 2)
		return frames[index] as Texture2D
	if enemy_id == "guys" and bool(chicken.get("guarding", false)) and phase.is_empty():
		return frames[0] as Texture2D
	if enemy_id == "giants" and str(chicken.get("giant_attack_kind", "toss")) == "stomp":
		return frames[0] as Texture2D if phase == "strike" else idle_chicken
	var t := float(chicken.get("signature_t", 0.0))
	var index := 0 if phase == "windup" and t < 0.5 else (1 if phase == "windup" else (2 if phase == "strike" else 3))
	return frames[index] as Texture2D


func _atlas_texture(source: Texture2D, region: Rect2) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = region
	return atlas


func _asset_to_res_path(path: String) -> String:
	if path.begins_with("res://"):
		return path
	return "res://%s" % path


func set_active_fight(active_fight: bool) -> void:
	if active_fight:
		_ensure_runtime_assets_loaded()
	if active == active_fight:
		return
	active = active_fight
	if active:
		_seed_fight()
	else:
		_seed_inactive_state()
	set_process(active)
	queue_redraw()


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
	title_label = _stage_label(stage_title, 60, HORIZONTAL_ALIGNMENT_LEFT, 22)
	add_child(title_label)
	ko_label = _stage_label("", 84, HORIZONTAL_ALIGNMENT_CENTER, 28)
	add_child(ko_label)
	ko_timer_label = _stage_label("", 40, HORIZONTAL_ALIGNMENT_CENTER, 12)
	add_child(ko_timer_label)
	for i in range(14):
		var floating := _stage_label("", 52, HORIZONTAL_ALIGNMENT_CENTER)
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
	_reset_reward_ledger()
	chickens.clear()
	vampire_bats.clear()
	vampire_shockwaves.clear()
	food_drops.clear()
	feather_particles.clear()
	smoke_puffs.clear()
	active_effects.clear()
	hero_pos = Vector2(0.5, 0.55)
	hero_hp = _hero_max_hp()
	hero_ko_timer = 0.0
	hero_attack_cd = 0.22
	hero_attack_timer = 0.0
	hero_uppercut_cd = 1.15
	hero_attack_is_uppercut = false
	hero_hurt_cooldown = 0.0
	hero_purple_buff_punches = 0
	hero_attack_purple_buffed = false
	hero_toss_timer = 0.0
	hero_bump_timer = 0.0
	hero_stun_timer = 0.0
	hero_toss_start = hero_pos
	hero_toss_target = hero_pos
	_reset_giant_boulders()
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
	area_clear_restart_timer = 0.0
	hit_stop_timer = 0.0
	module_shake_timer = 0.0
	_start_wave_spawning(true)


func _seed_inactive_state() -> void:
	_reset_reward_ledger()
	chickens.clear()
	vampire_bats.clear()
	vampire_shockwaves.clear()
	food_drops.clear()
	feather_particles.clear()
	smoke_puffs.clear()
	active_effects.clear()
	hero_pos = Vector2(0.5, 0.55)
	hero_hp = _hero_max_hp()
	hero_ko_timer = 0.0
	hero_attack_timer = 0.0
	hero_attack_cd = 0.45
	hero_uppercut_cd = 1.2
	hero_attack_is_uppercut = false
	hero_hurt_cooldown = 0.0
	hero_purple_buff_punches = 0
	hero_attack_purple_buffed = false
	hero_toss_timer = 0.0
	hero_bump_timer = 0.0
	hero_stun_timer = 0.0
	hero_toss_start = hero_pos
	hero_toss_target = hero_pos
	_reset_giant_boulders()
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
			"shield_up": enemy_id == "goblins",
			"shield_fall_timer": 0.0,
			"shield_fall_direction": Vector2.ZERO,
			"shield_fall_rotation": 0.0,
			"dead_timer": 0.0,
			"damage_done": false,
			"speed": 0.0,
			"variant": "white",
			"wave": 0,
			"damage": CHICKEN_DAMAGE,
			"face_right": pos.x < hero_pos.x
		})


func _reset_giant_boulders() -> void:
	giant_boulders.clear()
	if enemy_id != "giants" or giant_boulder_textures.is_empty():
		return
	var positions := [Vector2(0.28, 0.37), Vector2(0.72, 0.37), Vector2(0.50, 0.79)]
	for i in range(positions.size()):
		var pos := _clamp_norm_to_arena(positions[i])
		giant_boulders.append({
			"pos": pos,
			"start": pos,
			"target": pos,
			"texture_index": i % giant_boulder_textures.size(),
			"state": "ground",
			"owner_id": -1,
			"timer": 0.0,
			"rotation": -0.10 + float(i) * 0.13,
			"damage": 0.0,
			"damage_done": false,
		})


func _step_inactive(delta: float) -> void:
	hero_attack_timer = 0.0
	hero_attack_cd = 0.45
	hero_toss_timer = 0.0
	hero_bump_timer = 0.0
	hero_stun_timer = 0.0
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
	_step_giant_boulders(delta)
	_step_vampire_bats(delta)
	_step_vampire_shockwaves(delta)
	if hero_ko_timer > 0.0:
		_step_enemy_ko_retreats(delta)
		_step_food_drops(delta)
		hero_ko_timer = maxf(0.0, hero_ko_timer - delta)
		if hero_ko_timer <= 0.0:
			_seed_fight()
		return

	if area_clear_restart_timer > 0.0:
		_step_area_clear_restart(delta)
		return

	wave_elapsed_current = minf(wave_duration_current, wave_elapsed_current + delta)
	if end_wave_active or wave_elapsed_current < wave_spawn_phase_duration_current:
		if _wave_uses_random_spawns():
			_step_random_wave_spawning(delta)
		elif wave_spawn_remaining > 0:
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				_spawn_wave_burst()
	elif not end_wave_active:
		wave_spawn_remaining = 0
		wave_rest_timer = maxf(0.0, wave_duration_current - wave_elapsed_current)
		if wave_elapsed_current >= wave_duration_current:
			_advance_normal_wave()

	hero_attack_cd -= delta
	hero_attack_timer = maxf(0.0, hero_attack_timer - delta)
	hero_uppercut_cd = maxf(0.0, hero_uppercut_cd - delta)
	hero_hurt_cooldown = maxf(0.0, hero_hurt_cooldown - delta)
	hero_stun_timer = maxf(0.0, hero_stun_timer - delta)
	_step_hero_toss(delta)
	_step_hero_bump(delta)
	if hero_toss_timer <= 0.0 and hero_bump_timer <= 0.0 and hero_stun_timer <= 0.0 and hero_attack_cd <= 0.0:
		if _start_hero_attack():
			hero_attack_cd = _hero_attack_interval()
		elif hero_attack_cd <= 0.0:
			hero_attack_cd = 0.10

	for i in range(chickens.size()):
		var chicken := chickens[i]
		_step_chicken(chicken, delta)
		_update_enemy_render_pos(chicken, delta)
		chickens[i] = chicken
	_step_food_drops(delta)
	chickens = chickens.filter(func(chicken: Dictionary) -> bool:
		return float(chicken.get("dead_timer", 0.0)) < ENEMY_DEATH_LIFETIME
	)
	if not end_wave_active and wave_index < NORMAL_WAVE_COUNT and wave_spawn_remaining == 0 and _living_chicken_count() == 0:
		_advance_normal_wave()
	if hero_hp <= 0.0:
		hero_hp = 0.0
		hero_ko_timer = HERO_KO_DURATION
		_start_enemy_ko_retreats()
		knocked_out.emit()


func _start_enemy_ko_retreats() -> void:
	hit_stop_timer = 0.0
	module_shake_timer = 0.0
	module_shake_strength = 0.0
	vampire_bats.clear()
	vampire_shockwaves.clear()
	for chicken in chickens:
		if float(chicken.get("hp", 0.0)) <= 0.0:
			continue
		_release_giant_boulder(chicken)
		var pos := chicken.get("pos", Vector2.ZERO) as Vector2
		var retreat_dir := (pos - hero_pos).normalized()
		if retreat_dir.length_squared() <= 0.001:
			retreat_dir = Vector2.from_angle(float(int(chicken.get("id", 0))) * 2.399963)
		chicken["ko_retreat_dir"] = retreat_dir
		chicken["ko_retreat_alpha"] = 1.0
		chicken["ko_retreat_fading"] = false
		chicken["attack_phase"] = ""
		chicken["attack_timer"] = 0.0
		chicken["lunge_timer"] = 0.0
		chicken["stagger_timer"] = 0.0
		chicken["hit_flash"] = 0.0
		chicken["uppercut_pop"] = 0.0
		chicken["uppercut_knock_timer"] = 0.0
		chicken["punch_flee_timer"] = 0.0
		chicken["guarding"] = false
		chicken["transform_timer"] = 0.0
		_update_chicken_facing(chicken, retreat_dir)


func _step_enemy_ko_retreats(delta: float) -> void:
	for i in range(chickens.size()):
		var chicken := chickens[i]
		if float(chicken.get("hp", 0.0)) <= 0.0:
			_step_chicken(chicken, delta)
			_update_enemy_render_pos(chicken, delta)
			chickens[i] = chicken
			continue
		var alpha := float(chicken.get("ko_retreat_alpha", 1.0))
		var fading := bool(chicken.get("ko_retreat_fading", false))
		if not fading:
			var pos := chicken.get("pos", Vector2.ZERO) as Vector2
			var retreat_dir := chicken.get("ko_retreat_dir", Vector2.RIGHT) as Vector2
			var next_pos := pos + retreat_dir * KO_RETREAT_SPEED * delta
			var inside := _diamond_contains_norm(next_pos) if arena_shape == "diamond" else Rect2(0.035, 0.07, 0.93, 0.86).has_point(next_pos)
			if inside:
				chicken["pos"] = next_pos
			else:
				chicken["pos"] = _clamp_norm_to_diamond(next_pos, 0.0) if arena_shape == "diamond" else Vector2(clampf(next_pos.x, 0.035, 0.965), clampf(next_pos.y, 0.07, 0.93))
				chicken["ko_retreat_fading"] = true
				fading = true
			_update_chicken_facing(chicken, retreat_dir)
		if fading:
			alpha = maxf(0.0, alpha - delta / KO_RETREAT_FADE_SECONDS)
			chicken["ko_retreat_alpha"] = alpha
		_update_enemy_render_pos(chicken, delta)
		chickens[i] = chicken
	chickens = chickens.filter(func(chicken: Dictionary) -> bool:
		return float(chicken.get("dead_timer", 0.0)) < ENEMY_DEATH_LIFETIME and float(chicken.get("ko_retreat_alpha", 1.0)) > 0.0
	)


func _advance_normal_wave() -> void:
	if wave_index >= NORMAL_WAVE_COUNT - 1:
		_start_end_wave()
	else:
		wave_index += 1
		_start_wave_spawning(false)
		_add_float("WAVE %d" % (wave_index + 1), _norm_to_stage(Vector2(0.5, 0.22)), ACTIVE_WAVE_BLUE, 1.05)


func _spawn_chicken(lane: int) -> void:
	chicken_serial += 1
	# Four entry edges plus the windup/recovery holds are deliberate crowd choreography.
	var side := lane % 4
	var edge_t := fposmod(float(lane) * 0.271 + float(chicken_serial) * 0.173, 1.0)
	var variant := _variant_for_spawn(chicken_serial)
	var stat_mult := _wave_stat_mult(variant)
	var max_hp := _roll_chicken_max_hp(stat_mult)
	var initial_attack_cd := 0.55 + edge_t * 0.65
	if enemy_id == "guys":
		initial_attack_cd = 0.10
	if enemy_id == "rouses":
		initial_attack_cd = 0.30
	if enemy_id == "werewolves":
		initial_attack_cd = maxf(initial_attack_cd, WEREWOLF_TRANSFORM_DURATION)
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
		"attack_cd": initial_attack_cd,
		"transform_timer": 0.0,
		"werewolf_transformed": false,
		"lunge_timer": 0.0,
		"lunge_dir": Vector2.ZERO,
		"uppercut_knock_timer": 0.0,
		"uppercut_knock_duration": CHICKEN_UPPERCUT_KNOCK_SECONDS,
		"uppercut_knock_dir": Vector2.ZERO,
		"hit_flash": 0.0,
		"uppercut_pop": 0.0,
		"shield_up": enemy_id == "goblins",
		"shield_fall_timer": 0.0,
		"shield_fall_direction": Vector2.ZERO,
		"shield_fall_rotation": 0.0,
		"dead_timer": 0.0,
		"damage_done": false,
		"attack_phase": "",
		"attack_timer": 0.0,
		"attack_duration": 0.0,
		"attack_damage_done": false,
		"effect_fired": false,
		"slam_impacted": false,
		"dragon_cycle_damage_done": false,
		"stagger_timer": 0.0,
		"interrupt_protected": false,
		"punch_flee_timer": 0.0,
		"punch_flee_dir": Vector2.ZERO,
		"punch_flee_side": 1.0,
		"signature_t": 0.0,
		"roll_dir": Vector2.ZERO,
		"vampire_target_pos": Vector2.ZERO,
		"vampire_crossed": false,
		"vampire_flank_side": 0.0,
		"vampire_attack_count": 0,
		"vampire_attack_kind": "swipe",
		"vampire_bat_spawn_pattern": "burst",
		"vampire_bat_channel_remaining": 0,
		"vampire_bat_channel_total": 0,
		"vampire_bat_channel_spawned": 0,
		"vampire_bat_channel_beat_timer": 0.0,
		"vampire_teleport_timer": randf_range(0.55, 1.05),
		"vampire_teleport_phase": "",
		"vampire_teleport_fx_timer": 0.0,
		"vampire_teleport_target": pos,
		"vampire_walk_timer": 0.0,
		"vampire_idle_timer": 0.0,
		"vampire_force_bats": false,
		"vampire_giant_roll_done": false,
		"vampire_giant_transformed": false,
		"vampire_giant_buff_count": 0,
		"cave_troll_attack_kind": "pound",
		"cave_troll_attack_count": 0,
		"giant_attack_kind": "stomp",
		"giant_planned_attack": "",
		"giant_boulder_index": -1,
		"grabbed_hero": false,
		"dragon_attack_kind": "brawl",
		"dragon_next_attack_kind": "breath",
		"dragon_pounce_origin": pos,
		"dragon_pounce_target": pos,
		"breath_dir": Vector2.ZERO,
		"dragon_breath_aim": "straight",
		"dragon_melee_aim": "straight",
		"dragon_breath_beat_timer": 0.0,
		"dragon_breath_emissions": 0,
		"dragon_is_walking": false,
		"wall_hit": false,
		"rouses_crashed": false,
		"rouses_returned": false,
		"roll_origin": pos,
		"wall_missed": false,
		"charge_skidded": false,
		"speed": (0.088 + edge_t * 0.026) * _wave_speed_mult(variant) * enemy_speed_scale,
		"variant": variant,
		"wave": wave_index,
		"damage": enemy_damage * _wave_damage_mult(variant),
		"face_right": pos.x < hero_pos.x
	})


func _start_wave_spawning(immediate: bool) -> void:
	end_wave_active = false
	area_clear_restart_timer = 0.0
	wave_spawn_total = _wave_spawn_total_for_wave()
	wave_spawn_remaining = -1 if _wave_uses_random_spawns() else wave_spawn_total
	wave_spawned_count = 0
	wave_rest_timer = 0.0
	wave_rest_duration_current = _wave_rest_duration_for_wave()
	wave_start_delay_current = 0.18 if immediate else _wave_start_delay_for_wave()
	spawn_timer = 0.0 if immediate or _wave_uses_random_spawns() else wave_start_delay_current
	wave_spawn_phase_duration_current = _wave_spawn_phase_duration_for_current_wave()
	wave_duration_current = maxf(0.01, wave_spawn_phase_duration_current + wave_rest_duration_current)
	wave_elapsed_current = 0.0
	displayed_wave_progress = 0.0


func _start_end_wave() -> void:
	end_wave_active = true
	area_clear_restart_timer = 0.0
	wave_index = NORMAL_WAVE_COUNT
	wave_kills = 0
	wave_spawn_total = enemy_final_population
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
	var opening_single := enemy_id == "chicken-swarm" and wave_index == 0 and wave_spawned_count == 0
	var burst_count := mini(wave_spawn_remaining, 1 if opening_single else _wave_spawn_burst_count())
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


func _step_random_wave_spawning(delta: float) -> void:
	if wave_spawned_count == 0:
		_spawn_chicken(chicken_serial + wave_index * 13)
		wave_spawned_count += 1
		spawn_timer = RANDOM_SPAWN_ROLL_SECONDS
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	spawn_timer = RANDOM_SPAWN_ROLL_SECONDS
	if randf() <= _random_spawn_chance_per_roll():
		_spawn_chicken(chicken_serial + wave_index * 13)
		wave_spawned_count += 1


func _reserve_nearest_giant_boulder(chicken: Dictionary) -> int:
	var owner_id := int(chicken.get("id", -1))
	var giant_pos := chicken.get("pos", Vector2.ZERO) as Vector2
	var best_index := -1
	var best_distance := INF
	for i in range(giant_boulders.size()):
		var boulder := giant_boulders[i]
		if str(boulder.get("state", "ground")) != "ground" or int(boulder.get("owner_id", -1)) >= 0:
			continue
		var distance := giant_pos.distance_squared_to(boulder.get("pos", giant_pos) as Vector2)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	if best_index >= 0:
		var boulder := giant_boulders[best_index]
		boulder["state"] = "reserved"
		boulder["owner_id"] = owner_id
		giant_boulders[best_index] = boulder
		chicken["giant_boulder_index"] = best_index
	return best_index


func _plan_giant_attack(chicken: Dictionary) -> void:
	if not str(chicken.get("giant_planned_attack", "")).is_empty():
		return
	var planned_attack := "stomp" if randf() < 0.5 else "toss"
	if randf() < GIANT_BOULDER_ATTACK_CHANCE and _reserve_nearest_giant_boulder(chicken) >= 0:
		planned_attack = "boulder"
	chicken["giant_planned_attack"] = planned_attack


func _release_giant_boulder(chicken: Dictionary) -> void:
	var boulder_index := int(chicken.get("giant_boulder_index", -1))
	if boulder_index < 0 or boulder_index >= giant_boulders.size():
		return
	var boulder := giant_boulders[boulder_index]
	var boulder_state := str(boulder.get("state", "ground"))
	if int(boulder.get("owner_id", -1)) == int(chicken.get("id", -2)) and boulder_state in ["reserved", "held"]:
		boulder["state"] = "ground"
		boulder["owner_id"] = -1
		boulder["timer"] = 0.0
		if boulder_state == "held":
			var face := 1.0 if bool(chicken.get("face_right", true)) else -1.0
			boulder["pos"] = _clamp_norm_to_arena((chicken.get("pos", Vector2.ZERO) as Vector2) + Vector2(face * 0.07, 0.02))
		giant_boulders[boulder_index] = boulder
	chicken["giant_boulder_index"] = -1
	chicken["giant_planned_attack"] = ""


func _held_giant_boulder_center(boulder: Dictionary) -> Vector2:
	var owner := _giant_boulder_owner(int(boulder.get("owner_id", -1)))
	if owner.is_empty():
		return Vector2.INF
	var pos := boulder.get("pos", Vector2.ZERO) as Vector2
	var owner_pos := owner.get("pos", pos) as Vector2
	var face := 1.0 if bool(owner.get("face_right", true)) else -1.0
	var lift_t := 1.0
	if str(owner.get("attack_phase", "")) == "windup":
		lift_t = _smooth01(clampf(float(owner.get("signature_t", 0.0)) * 1.45, 0.0, 1.0))
	return _norm_to_stage(pos).lerp(_norm_to_stage(owner_pos + Vector2(face * 0.06, -0.18)), lift_t)


func _try_shatter_held_boulder(tap_pos: Vector2) -> bool:
	if not active or enemy_id != "giants":
		return false
	var s := _stage_scale()
	for i in range(giant_boulders.size()):
		var boulder := giant_boulders[i]
		if str(boulder.get("state", "")) != "held":
			continue
		var owner_id := int(boulder.get("owner_id", -1))
		var owner := _giant_boulder_owner(owner_id)
		if owner.is_empty() or str(owner.get("attack_phase", "")) != "windup":
			continue
		var center := _held_giant_boulder_center(boulder)
		if center == Vector2.INF or center.distance_to(tap_pos) > 70.0 * s:
			continue
		boulder["state"] = "destroyed"
		boulder["owner_id"] = -1
		giant_boulders[i] = boulder
		for giant_index in range(chickens.size()):
			var giant := chickens[giant_index]
			if int(giant.get("id", -2)) != owner_id:
				continue
			giant["giant_boulder_index"] = -1
			giant["giant_planned_attack"] = ""
			giant["attack_phase"] = "recovery"
			giant["attack_timer"] = 0.55
			giant["attack_duration"] = 0.55
			giant["attack_damage_done"] = true
			giant["effect_fired"] = true
			giant["interrupt_protected"] = false
			chickens[giant_index] = giant
			break
		_spawn_boulder_debris(center)
		_trigger_module_shake(0.12, 5.0)
		queue_redraw()
		return true
	return false


func _spawn_boulder_debris(center: Vector2) -> void:
	var s := _stage_scale()
	var colors := [Color("#b4aa9c"), Color("#91887d"), Color("#716a62")]
	var fragment_count := 12
	for i in range(fragment_count):
		var angle := TAU * float(i) / float(fragment_count) + randf_range(-0.16, 0.16)
		var speed := randf_range(145.0, 260.0) * s
		feather_particles.append({
			"kind": "stone",
			"pos": center + Vector2(randf_range(-12.0, 12.0), randf_range(-10.0, 10.0)) * s,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": randf_range(0.48, 0.72),
			"max_life": 0.72,
			"size": randf_range(15.0, 24.0) * s,
			"spin": randf_range(0.0, TAU),
			"spin_speed": randf_range(-10.0, 10.0),
			"color": colors[i % colors.size()],
		})
	if feather_particles.size() > 72:
		feather_particles = feather_particles.slice(feather_particles.size() - 72, feather_particles.size())


func _throw_giant_boulder(chicken: Dictionary) -> void:
	var boulder_index := int(chicken.get("giant_boulder_index", -1))
	if boulder_index < 0 or boulder_index >= giant_boulders.size():
		return
	var boulder := giant_boulders[boulder_index]
	if str(boulder.get("state", "ground")) != "held":
		return
	var giant_pos := chicken.get("pos", Vector2.ZERO) as Vector2
	var throw_dir := (hero_pos - giant_pos).normalized()
	if throw_dir.length_squared() <= 0.001:
		throw_dir = Vector2.RIGHT
	var target := _clamp_norm_to_arena(hero_pos + throw_dir * GIANT_BOULDER_THROW_DISTANCE)
	boulder["state"] = "flying"
	boulder["owner_id"] = -1
	boulder["start"] = giant_pos + throw_dir * 0.045
	boulder["pos"] = boulder["start"]
	boulder["target"] = target
	boulder["timer"] = 0.0
	boulder["rotation"] = 0.0
	boulder["spin"] = 1.0 if throw_dir.x >= 0.0 else -1.0
	boulder["damage"] = float(chicken.get("damage", CHICKEN_DAMAGE)) * 1.15
	boulder["damage_done"] = false
	giant_boulders[boulder_index] = boulder
	chicken["giant_boulder_index"] = -1


func _step_giant_boulders(delta: float) -> void:
	if enemy_id != "giants":
		return
	for i in range(giant_boulders.size()):
		var boulder := giant_boulders[i]
		if str(boulder.get("state", "ground")) != "flying":
			continue
		var previous_pos := boulder.get("pos", Vector2.ZERO) as Vector2
		var timer := minf(GIANT_BOULDER_THROW_DURATION, float(boulder.get("timer", 0.0)) + delta)
		var t := clampf(timer / GIANT_BOULDER_THROW_DURATION, 0.0, 1.0)
		var start := boulder.get("start", previous_pos) as Vector2
		var target := boulder.get("target", previous_pos) as Vector2
		var next_pos := start.lerp(target, _smooth01(t))
		boulder["timer"] = timer
		boulder["pos"] = next_pos
		boulder["rotation"] = float(boulder.get("spin", 1.0)) * t * TAU * 1.35
		if not bool(boulder.get("damage_done", false)):
			var closest := Geometry2D.get_closest_point_to_segment(hero_pos, previous_pos, next_pos)
			if closest.distance_to(hero_pos) <= GIANT_BOULDER_HIT_RADIUS and hero_hurt_cooldown <= 0.0:
				_apply_enemy_contact_damage({"damage": boulder.get("damage", CHICKEN_DAMAGE), "roll_dir": (target - start).normalized()})
				boulder["damage_done"] = true
		if timer >= GIANT_BOULDER_THROW_DURATION:
			boulder["state"] = "ground"
			boulder["owner_id"] = -1
			boulder["pos"] = target
			boulder["start"] = target
			boulder["target"] = target
			boulder["timer"] = 0.0
		giant_boulders[i] = boulder


func _vampire_attack_kind_for_roll(chicken: Dictionary, roll: float) -> String:
	if bool(chicken.get("vampire_force_bats", false)):
		return "bats"
	var hp_ratio := float(chicken.get("hp", 0.0)) / maxf(1.0, float(chicken.get("max_hp", 1.0)))
	if hp_ratio < VAMPIRE_BITE_HEALTH_RATIO and roll < VAMPIRE_BITE_CHANCE:
		return "bite"
	if roll < VAMPIRE_BAT_ATTACK_CHANCE:
		return "bats"
	return "shockwave" if roll < VAMPIRE_BAT_ATTACK_CHANCE + VAMPIRE_SHOCKWAVE_ATTACK_CHANCE else "swipe"


func _vampire_bat_spawn_pattern_for_roll(roll: float) -> String:
	return "channel" if roll < VAMPIRE_BAT_CHANNEL_CHANCE else "burst"


func _step_vampire_idle_teleport(chicken: Dictionary, pos: Vector2, delta: float) -> Vector2:
	var teleport_phase := str(chicken.get("vampire_teleport_phase", ""))
	if not teleport_phase.is_empty():
		var fx_timer := maxf(0.0, float(chicken.get("vampire_teleport_fx_timer", 0.0)) - delta)
		chicken["vampire_teleport_fx_timer"] = fx_timer
		if fx_timer > 0.0:
			return pos
		if teleport_phase == "out":
			var target := chicken.get("vampire_teleport_target", pos) as Vector2
			chicken["vampire_teleport_phase"] = "in"
			chicken["vampire_teleport_fx_timer"] = VAMPIRE_TELEPORT_HALF_SECONDS
			chicken["render_pos"] = target
			chicken["render_sim_pos"] = target
			chicken["face_right"] = hero_pos.x > target.x
			_spawn_smoke_puffs(target, (target - pos).normalized(), true)
			return target
		chicken["vampire_teleport_phase"] = ""
		chicken["vampire_teleport_timer"] = randf_range(1.6, 2.6)
		var should_walk := posmod(int(chicken.get("vampire_attack_count", 0)), 2) == 1 or randf() < VAMPIRE_WALK_CHANCE
		chicken["vampire_walk_timer"] = randf_range(0.65, 1.15) if should_walk else 0.0
		return pos
	var timer := maxf(0.0, float(chicken.get("vampire_teleport_timer", 0.0)) - delta)
	chicken["vampire_teleport_timer"] = timer
	var walk_timer := maxf(0.0, float(chicken.get("vampire_walk_timer", 0.0)) - delta)
	chicken["vampire_walk_timer"] = walk_timer
	if walk_timer > 0.0:
		var toward_hero := hero_pos - pos
		if toward_hero.length() > _enemy_attack_range(chicken):
			pos += toward_hero.normalized() * float(chicken.get("speed", 0.09)) * delta
	if timer > 0.0:
		return pos
	var candidate := _clamp_norm_to_arena(hero_pos + Vector2.from_angle(randf() * TAU) * randf_range(0.30, 0.46))
	chicken["vampire_teleport_phase"] = "out"
	chicken["vampire_teleport_fx_timer"] = VAMPIRE_TELEPORT_HALF_SECONDS
	chicken["vampire_teleport_target"] = candidate
	chicken["face_right"] = hero_pos.x > pos.x
	_spawn_smoke_puffs(pos, (candidate - pos).normalized(), true)
	return pos


func _spawn_vampire_bats(chicken: Dictionary) -> void:
	for i in range(VAMPIRE_BAT_COUNT):
		_spawn_vampire_bat(chicken, i, VAMPIRE_BAT_COUNT)


func _spawn_vampire_bat(chicken: Dictionary, spawn_index: int, total_count: int) -> void:
	var origin := chicken.get("pos", Vector2.ZERO) as Vector2
	var spread := (float(spawn_index) - (float(total_count) - 1.0) * 0.5) * 0.024
	var start := _clamp_norm_to_arena(origin + Vector2(spread, -0.055 + absf(spread) * 0.35))
	var scatter_dir := Vector2(-1.0 if spawn_index < total_count / 2 else 1.0, -0.32 if posmod(spawn_index, 2) == 0 else 0.22).normalized()
	var bat_id := vampire_bat_next_id
	vampire_bat_next_id += 1
	vampire_bats.append({
		"id": bat_id,
		"pos": start,
		"hp": 1.0,
		"spawn_invuln_timer": VAMPIRE_BAT_SPAWN_INVULN_SECONDS,
		"attack_cd": randf_range(0.45, 0.85),
		"attack_timer": 0.0,
		"attack_start": start,
		"attack_target": hero_pos,
		"damage": maxf(1.0, float(chicken.get("damage", CHICKEN_DAMAGE)) * VAMPIRE_BAT_DAMAGE_SCALE),
		"damage_done": false,
		"flap_phase": float(spawn_index) * 0.43,
		"move_phase": randf() * TAU,
		"orbit_angle": float(spawn_index) * TAU / float(total_count),
		"orbit_direction": -1.0 if posmod(spawn_index, 2) == 0 else 1.0,
		"move_dir": scatter_dir,
		"facing_right": scatter_dir.x >= 0.0,
		"scatter_dir": scatter_dir,
		"scatter_timer": 0.55,
		"buff_scale": 1.0,
		"buff_count": 0,
		"shockwave_buffed": false,
	})


func _step_vampire_bat_channel(chicken: Dictionary, delta: float) -> void:
	if str(chicken.get("vampire_bat_spawn_pattern", "burst")) != "channel" or str(chicken.get("attack_phase", "")) != "windup":
		return
	var remaining := int(chicken.get("vampire_bat_channel_remaining", 0))
	if remaining <= 0:
		return
	var beat_timer := maxf(0.0, float(chicken.get("vampire_bat_channel_beat_timer", 0.0)) - delta)
	chicken["signature_t"] = 1.0 - clampf(beat_timer / VAMPIRE_BAT_CHANNEL_BEAT_SECONDS, 0.0, 1.0)
	if beat_timer <= 0.0:
		var total := int(chicken.get("vampire_bat_channel_total", remaining))
		var spawned := int(chicken.get("vampire_bat_channel_spawned", 0))
		_spawn_vampire_bat(chicken, spawned, total)
		chicken["vampire_bat_channel_spawned"] = spawned + 1
		remaining -= 1
		beat_timer = VAMPIRE_BAT_CHANNEL_BEAT_SECONDS
	chicken["vampire_bat_channel_remaining"] = remaining
	chicken["vampire_bat_channel_beat_timer"] = beat_timer


func _vampire_bat_facing_right(current_facing: bool, horizontal_direction: float) -> bool:
	if horizontal_direction > VAMPIRE_BAT_FACING_THRESHOLD:
		return true
	if horizontal_direction < -VAMPIRE_BAT_FACING_THRESHOLD:
		return false
	return current_facing


func _step_vampire_bats(delta: float) -> void:
	if enemy_id != "vampires":
		return
	if hero_ko_timer > 0.0:
		vampire_bats.clear()
		return
	for i in range(vampire_bats.size()):
		var bat := vampire_bats[i]
		bat["spawn_invuln_timer"] = maxf(0.0, float(bat.get("spawn_invuln_timer", 0.0)) - delta)
		var pos := bat.get("pos", Vector2.ZERO) as Vector2
		var attack_timer := maxf(0.0, float(bat.get("attack_timer", 0.0)) - delta)
		var attack_cd := maxf(0.0, float(bat.get("attack_cd", 0.0)) - delta)
		var scatter_timer := maxf(0.0, float(bat.get("scatter_timer", 0.0)) - delta)
		if scatter_timer > 0.0:
			var scatter_dir := bat.get("scatter_dir", Vector2.RIGHT) as Vector2
			pos = _clamp_norm_to_arena(pos + scatter_dir * VAMPIRE_BAT_MOVE_SPEED * delta)
			bat["move_dir"] = scatter_dir
		elif attack_timer > 0.0:
			var attack_start := bat.get("attack_start", pos) as Vector2
			var attack_target := bat.get("attack_target", hero_pos) as Vector2
			var progress := 1.0 - attack_timer / VAMPIRE_BAT_ATTACK_SECONDS
			var next_pos := attack_start.lerp(attack_target, sin(clampf(progress, 0.0, 1.0) * PI) * 0.92)
			var travel := next_pos - pos
			pos = next_pos
			if travel.length_squared() > 0.000001:
				bat["move_dir"] = travel.normalized()
			if progress >= 0.35 and not bool(bat.get("damage_done", false)):
				bat["damage_done"] = true
				if hero_hurt_cooldown <= 0.0:
					_apply_enemy_contact_damage({"damage": bat.get("damage", CHICKEN_DAMAGE), "roll_dir": bat["move_dir"]})
		else:
			var orbit_angle := float(bat.get("orbit_angle", 0.0)) + float(bat.get("orbit_direction", 1.0)) * VAMPIRE_BAT_ORBIT_SPEED * delta
			bat["orbit_angle"] = orbit_angle
			var surround_target := _clamp_norm_to_arena(hero_pos + Vector2.from_angle(orbit_angle) * VAMPIRE_BAT_SURROUND_RADIUS)
			var to_slot := surround_target - pos
			if to_slot.length() <= VAMPIRE_BAT_SLOT_REACHED_RADIUS and attack_cd <= 0.0:
				attack_timer = VAMPIRE_BAT_ATTACK_SECONDS
				attack_cd = randf_range(1.10, 1.60)
				bat["attack_start"] = pos
				bat["attack_target"] = hero_pos
				bat["damage_done"] = false
			else:
				var toward := to_slot.normalized() if to_slot.length_squared() > 0.001 else Vector2.RIGHT
				var weave := toward.orthogonal() * sin(elapsed_seconds * 2.0 + float(bat.get("move_phase", 0.0))) * 0.16
				var desired_dir := (toward + weave).normalized()
				var previous_dir := bat.get("move_dir", desired_dir) as Vector2
				var move_dir := previous_dir.lerp(desired_dir, clampf(delta * VAMPIRE_BAT_DIRECTION_RESPONSE, 0.0, 1.0)).normalized()
				pos = _clamp_norm_to_arena(pos + move_dir * VAMPIRE_BAT_MOVE_SPEED * delta)
				bat["move_dir"] = move_dir
		var move_dir := bat.get("move_dir", Vector2.RIGHT) as Vector2
		bat["facing_right"] = _vampire_bat_facing_right(bool(bat.get("facing_right", move_dir.x >= 0.0)), move_dir.x)
		bat["pos"] = pos
		bat["attack_timer"] = attack_timer
		bat["attack_cd"] = attack_cd
		bat["scatter_timer"] = scatter_timer
		vampire_bats[i] = bat
	vampire_bats = vampire_bats.filter(func(bat: Dictionary) -> bool:
		return float(bat.get("hp", 0.0)) > 0.0
	)


func _spawn_vampire_shockwave(chicken: Dictionary) -> void:
	vampire_shockwaves.append({
		"origin": chicken.get("pos", Vector2.ZERO),
		"radius": 22.0,
		"damage": float(chicken.get("damage", CHICKEN_DAMAGE)) * 0.65,
		"touched": false,
		"buffed_bat_ids": {},
	})


func _step_vampire_shockwaves(delta: float) -> void:
	if enemy_id != "vampires":
		vampire_shockwaves.clear()
		return
	var s := maxf(0.01, _stage_scale())
	for i in range(vampire_shockwaves.size()):
		var shockwave := vampire_shockwaves[i]
		var previous_radius := float(shockwave.get("radius", 0.0))
		var radius := previous_radius + VAMPIRE_SHOCKWAVE_SPEED * delta
		var origin := shockwave.get("origin", Vector2.ZERO) as Vector2
		var hero_distance := _norm_to_stage(origin).distance_to(_norm_to_stage(hero_pos)) / s
		if not bool(shockwave.get("touched", false)) and hero_distance >= previous_radius and hero_distance <= radius + 10.0:
			shockwave["touched"] = true
			hero_purple_buff_punches = 1
		for bat_index in range(vampire_bats.size()):
			var bat := vampire_bats[bat_index]
			var bat_distance := _norm_to_stage(origin).distance_to(_norm_to_stage(bat.get("pos", origin) as Vector2)) / s
			var buffed_bat_ids := shockwave.get("buffed_bat_ids", {}) as Dictionary
			var bat_id := int(bat.get("id", -1))
			if not buffed_bat_ids.has(bat_id) and bat_distance >= previous_radius and bat_distance <= radius + 10.0:
				buffed_bat_ids[bat_id] = true
				shockwave["buffed_bat_ids"] = buffed_bat_ids
				var buff_count := int(bat.get("buff_count", 0)) + 1
				bat["shockwave_buffed"] = true
				bat["buff_count"] = buff_count
				bat["buff_scale"] = 1.0 + float(buff_count) * VAMPIRE_BAT_BUFF_SCALE_STEP
				bat["hp"] = maxf(float(bat.get("hp", 1.0)), float(buff_count + 1))
				bat["damage"] = float(bat.get("damage", CHICKEN_DAMAGE)) * 1.05
				vampire_bats[bat_index] = bat
		for chicken in chickens:
			if not bool(chicken.get("vampire_giant_transformed", false)):
				continue
			var giant_distance := _norm_to_stage(origin).distance_to(_norm_to_stage(chicken.get("pos", origin) as Vector2)) / s
			if giant_distance >= previous_radius and giant_distance <= radius + 10.0:
				chicken["vampire_giant_buff_count"] = int(chicken.get("vampire_giant_buff_count", 0)) + 1
				chicken["hp"] = float(chicken.get("hp", 1.0)) * 1.20
				chicken["max_hp"] = float(chicken.get("max_hp", 1.0)) * 1.20
				chicken["damage"] = float(chicken.get("damage", CHICKEN_DAMAGE)) * 1.05
		shockwave["radius"] = radius
		vampire_shockwaves[i] = shockwave
	vampire_shockwaves = vampire_shockwaves.filter(func(shockwave: Dictionary) -> bool:
		return float(shockwave.get("radius", 0.0)) < VAMPIRE_SHOCKWAVE_MAX_RADIUS
	)


func _step_chicken(chicken: Dictionary, delta: float) -> void:
	var hp := float(chicken.get("hp", 0.0))
	var dead_timer := float(chicken.get("dead_timer", 0.0))
	var pos := chicken.get("pos", Vector2.ZERO) as Vector2
	var old_pos := pos
	var transform_timer := maxf(0.0, float(chicken.get("transform_timer", 0.0)) - delta)
	chicken["transform_timer"] = transform_timer
	var shield_fall_timer := maxf(0.0, float(chicken.get("shield_fall_timer", 0.0)) - delta)
	chicken["shield_fall_timer"] = shield_fall_timer
	if shield_fall_timer <= 0.0:
		chicken["shield_fall_direction"] = Vector2.ZERO
		chicken["shield_fall_rotation"] = 0.0
	var knock_timer := maxf(0.0, float(chicken.get("uppercut_knock_timer", 0.0)) - delta)
	if knock_timer > 0.0:
		var knock_dir := chicken.get("uppercut_knock_dir", Vector2.ZERO) as Vector2
		if knock_dir.length() > 0.001:
			var knock_scale := float(chicken.get("death_bounce_scale", 1.0)) if hp <= 0.0 else 1.0
			pos += knock_dir.normalized() * CHICKEN_UPPERCUT_KNOCK_SPEED * knock_scale * delta
		chicken["uppercut_knock_timer"] = knock_timer
	else:
		chicken["uppercut_knock_timer"] = 0.0
	if hp <= 0.0:
		_release_giant_boulder(chicken)
		var dead_pos := _clamp_norm_to_arena(pos)
		_update_chicken_facing(chicken, dead_pos - old_pos)
		chicken["pos"] = dead_pos
		chicken["dead_timer"] = dead_timer + delta
		chicken["hit_flash"] = maxf(0.0, float(chicken.get("hit_flash", 0.0)) - delta)
		chicken["uppercut_pop"] = maxf(0.0, float(chicken.get("uppercut_pop", 0.0)) - delta)
		return
	var stagger_timer := maxf(0.0, float(chicken.get("stagger_timer", 0.0)) - delta)
	chicken["stagger_timer"] = stagger_timer
	chicken["hit_flash"] = maxf(0.0, float(chicken.get("hit_flash", 0.0)) - delta)
	chicken["uppercut_pop"] = maxf(0.0, float(chicken.get("uppercut_pop", 0.0)) - delta)
	chicken["punch_flee_timer"] = maxf(0.0, float(chicken.get("punch_flee_timer", 0.0)) - delta)
	if knock_timer > 0.0 or stagger_timer > 0.0:
		chicken["lunge_timer"] = 0.0
		chicken["attack_phase"] = "stagger" if stagger_timer > 0.0 else ""
		chicken["pos"] = _clamp_norm_to_arena(pos)
		return
	if enemy_id == "werewolves" and transform_timer > 0.0:
		chicken["attack_phase"] = ""
		chicken["attack_timer"] = 0.0
		chicken["pos"] = _clamp_norm_to_arena(pos)
		return
	if enemy_id == "vampires" and transform_timer > 0.0:
		chicken["attack_phase"] = ""
		chicken["attack_timer"] = 0.0
		chicken["pos"] = _clamp_norm_to_arena(pos)
		return

	var attack_cd := maxf(0.0, float(chicken.get("attack_cd", 0.0)) - delta)
	var phase := str(chicken.get("attack_phase", ""))
	if phase == "stagger":
		phase = ""
		chicken["interrupt_protected"] = false
	if enemy_id == "vampires" and not bool(chicken.get("vampire_giant_transformed", false)):
		var visibly_idle := phase.is_empty() and str(chicken.get("vampire_teleport_phase", "")).is_empty() and float(chicken.get("vampire_walk_timer", 0.0)) <= 0.0
		var vampire_idle_timer := float(chicken.get("vampire_idle_timer", 0.0)) + delta if visibly_idle else 0.0
		chicken["vampire_idle_timer"] = vampire_idle_timer
		if vampire_idle_timer >= VAMPIRE_MAX_IDLE_SECONDS:
			chicken["vampire_force_bats"] = true
			attack_cd = 0.0
	if enemy_id == "vampires" and not bool(chicken.get("vampire_giant_transformed", false)) and phase.is_empty() and (attack_cd > 0.0 or not str(chicken.get("vampire_teleport_phase", "")).is_empty()):
		pos = _step_vampire_idle_teleport(chicken, pos, delta)
	var attack_range := _enemy_attack_range(chicken)
	var attack_target := hero_pos
	var approaching_boulder := false
	if enemy_id == "giants" and phase.is_empty() and attack_cd <= 0.0:
		_plan_giant_attack(chicken)
	if enemy_id == "giants" and phase.is_empty() and str(chicken.get("giant_planned_attack", "")) == "boulder":
		var boulder_index := int(chicken.get("giant_boulder_index", -1))
		if boulder_index >= 0 and boulder_index < giant_boulders.size():
			attack_target = giant_boulders[boulder_index].get("pos", hero_pos) as Vector2
			attack_range = GIANT_BOULDER_PICKUP_RANGE
			approaching_boulder = true
	var to_hero := attack_target - pos
	var dist := maxf(0.001, to_hero.length())
	var dir := to_hero / dist
	var phase_timer := maxf(0.0, float(chicken.get("attack_timer", 0.0)) - delta)
	var signature_t := 1.0 - phase_timer / maxf(0.01, float(chicken.get("attack_duration", 0.01)))
	chicken["signature_t"] = clampf(signature_t, 0.0, 1.0)
	if phase == "windup":
		if enemy_id == "vampires":
			_step_vampire_bat_channel(chicken, delta)
		if enemy_id == "giants" and str(chicken.get("giant_attack_kind", "stomp")) == "toss":
			var grab_pos := hero_pos - dir * 0.12
			pos = pos.move_toward(grab_pos, delta * 0.28)
		if phase_timer <= 0.0:
			phase = "strike"
			phase_timer = _enemy_strike_duration(chicken)
			chicken["attack_duration"] = phase_timer
			chicken["attack_damage_done"] = false
			_spawn_smoke_puffs(pos, dir)
	elif phase == "strike":
		_step_enemy_strike(chicken, pos, dir, delta)
		pos = chicken.get("pos", pos) as Vector2
		var contact_pos := pos
		if phase_timer <= 0.0 or bool(chicken.get("wall_hit", false)) or bool(chicken.get("rouses_crashed", false)) or (enemy_id == "werewolves" and bool(chicken.get("wall_missed", false))):
			phase = "recovery"
			phase_timer = _enemy_recovery_duration()
			chicken["attack_duration"] = phase_timer
			chicken["wall_hit"] = false
			chicken["interrupt_protected"] = false
		chicken["pos"] = contact_pos
	elif phase == "recovery":
		_step_enemy_recovery(chicken, pos, delta)
		pos = chicken.get("pos", pos) as Vector2
		if phase_timer <= 0.0:
			if enemy_id == "rouses":
				pos = chicken.get("roll_origin", pos) as Vector2
				chicken["rouses_returned"] = true
			if enemy_id == "vampires":
				chicken["vampire_teleport_timer"] = 0.05
			phase = ""
			phase_timer = 0.0
			if enemy_id == "dragons":
				var finished_kind := str(chicken.get("dragon_attack_kind", "brawl"))
				var next_kind := "breath" if finished_kind == "brawl" else ("pounce" if finished_kind == "breath" else "brawl")
				chicken["dragon_attack_kind"] = next_kind
				chicken["dragon_next_attack_kind"] = "breath" if next_kind == "brawl" else ("pounce" if next_kind == "breath" else "brawl")
				attack_cd = 0.0
	else:
		var approach_pos := _step_enemy_approach(chicken, pos, dir, dist, delta)
		pos = _clamp_norm_to_arena(approach_pos) if approaching_boulder else _clamp_enemy_approach_to_hero_ring(chicken, pos, approach_pos)
		var can_start_attack := float(chicken.get("punch_flee_timer", 0.0)) <= 0.0 and dist <= attack_range
		if enemy_id == "vampires":
			can_start_attack = str(chicken.get("vampire_teleport_phase", "")).is_empty()
		if enemy_id == "werewolves" and not bool(chicken.get("werewolf_transformed", false)):
			can_start_attack = false
		if enemy_id == "dragons" and str(chicken.get("dragon_attack_kind", "brawl")) == "breath":
			can_start_attack = dist >= DRAGON_BREATH_RANGE
		if enemy_id == "dragons" and str(chicken.get("dragon_attack_kind", "brawl")) == "brawl":
			can_start_attack = can_start_attack and _dragon_has_clear_brawl_position(pos)
		if attack_cd <= 0.0 and can_start_attack:
			_begin_enemy_attack(chicken, dir)
			pos = chicken.get("pos", pos) as Vector2
			phase = "windup"
			phase_timer = float(chicken.get("attack_timer", 0.0))
			chicken["attack_duration"] = phase_timer
			attack_cd = _enemy_attack_cooldown()

	# A R.O.U.S. roll is a committed out-and-back attack, so the diamond's
	# walkable clamp must not bend either leg around the hero.
	var next_pos := _clamp_rouses_roll_to_stage(pos) if enemy_id == "rouses" and phase in ["strike", "recovery"] else _clamp_norm_to_arena(pos)
	if enemy_id == "dragons":
		chicken["dragon_is_walking"] = phase.is_empty() and next_pos.distance_squared_to(old_pos) > 0.0000001
	_update_chicken_facing(chicken, next_pos - old_pos)
	chicken["pos"] = next_pos
	chicken["attack_cd"] = attack_cd
	chicken["attack_phase"] = phase
	chicken["attack_timer"] = phase_timer
	chicken["lunge_timer"] = phase_timer if phase == "strike" and enemy_id == "chicken-swarm" else 0.0


func _step_enemy_approach(chicken: Dictionary, pos: Vector2, dir: Vector2, dist: float, delta: float) -> Vector2:
	var speed := float(chicken.get("speed", 0.09))
	match enemy_id:
		"goblins":
			return pos if dist <= _enemy_attack_range(chicken) else pos + dir * speed * delta
		"rouses":
			if dist <= _enemy_attack_range(chicken):
				return pos
			return pos + dir * speed * delta * 2.0
		"guys":
			if float(chicken.get("punch_flee_timer", 0.0)) > 0.0:
				chicken["guarding"] = false
				var radial := (pos - hero_pos).normalized()
				var flee_dir := radial.orthogonal() * float(chicken.get("punch_flee_side", 1.0))
				chicken["punch_flee_dir"] = flee_dir
				return pos + flee_dir.normalized() * speed * delta * float(chicken.get("punch_flee_speed", 1.25))
			chicken["guarding"] = fmod(elapsed_seconds + float(chicken.get("id", 0)), 1.8) < 0.65
			return pos + dir * speed * delta * 0.48
		"vampires":
			return pos + dir * speed * delta * 1.25 if bool(chicken.get("vampire_giant_transformed", false)) else pos
		"dragons":
			var dragon_kind := str(chicken.get("dragon_attack_kind", "brawl"))
			if dragon_kind == "breath":
				if dist < DRAGON_BREATH_RANGE:
					var retreat := pos - dir * speed * delta * 3.2
					if _clamp_norm_to_arena(retreat).distance_squared_to(pos) > 0.0000001:
						return retreat
					var lateral := dir.orthogonal() * speed * delta * 3.2
					var lateral_a := _clamp_norm_to_arena(pos + lateral)
					var lateral_b := _clamp_norm_to_arena(pos - lateral)
					return lateral_a if lateral_a.distance_squared_to(hero_pos) > lateral_b.distance_squared_to(hero_pos) else lateral_b
				return pos
			if dragon_kind == "pounce":
				return pos if dist <= DRAGON_POUNCE_RANGE else pos + dir * speed * delta * 1.35
			if dist <= DRAGON_BRAWL_RANGE + 0.10 and not _dragon_has_clear_brawl_position(pos):
				var side := float(chicken.get("dragon_brawl_side", 0.0))
				if is_zero_approx(side):
					side = -1.0 if pos.x < hero_pos.x else (1.0 if pos.x > hero_pos.x else (-1.0 if posmod(int(chicken.get("id", 0)), 2) == 0 else 1.0))
					chicken["dragon_brawl_side"] = side
				var sidestep := pos + Vector2(side * speed * delta * 1.8, 0.0)
				if _clamp_norm_to_arena(sidestep).distance_squared_to(pos) <= 0.0000001:
					side = -side
					chicken["dragon_brawl_side"] = side
					sidestep = pos + Vector2(side * speed * delta * 1.8, 0.0)
				return sidestep
			if dist <= DRAGON_BRAWL_RANGE:
				return pos
			var pace := 0.72 if fmod(elapsed_seconds + float(chicken.get("id", 0)) * 0.61, 2.6) < 0.82 else 1.8
			return pos + dir * speed * delta * pace
	return pos + dir * speed * delta


func _dragon_has_clear_brawl_position(pos: Vector2) -> bool:
	return absf(pos.x - hero_pos.x) >= DRAGON_BRAWL_MIN_HORIZONTAL_GAP


func _update_dragon_breath_aim(chicken: Dictionary, dragon_pos: Vector2) -> void:
	var to_hero := hero_pos - dragon_pos
	var horizontal := 1.0 if to_hero.x >= 0.0 else -1.0
	var aim := "straight"
	var vertical := 0.0
	if to_hero.y <= -DRAGON_BREATH_DEPTH_THRESHOLD:
		aim = "far"
		vertical = -DRAGON_BREATH_DEPTH_SLOPE
	elif to_hero.y >= DRAGON_BREATH_DEPTH_THRESHOLD:
		aim = "near"
		vertical = DRAGON_BREATH_DEPTH_SLOPE
	chicken["dragon_breath_aim"] = aim
	chicken["breath_dir"] = Vector2(horizontal, vertical).normalized()
	chicken["face_right"] = horizontal > 0.0


func _update_dragon_melee_aim(chicken: Dictionary, dragon_pos: Vector2) -> void:
	var to_hero := hero_pos - dragon_pos
	var aim := "far" if to_hero.y < -DRAGON_MELEE_DEPTH_THRESHOLD else ("near" if to_hero.y > DRAGON_MELEE_DEPTH_THRESHOLD else "straight")
	if aim != "straight" and absf(to_hero.x) <= DRAGON_MELEE_VERTICAL_THRESHOLD:
		aim = "vertical-%s" % aim
	chicken["dragon_melee_aim"] = aim


func _begin_enemy_attack(chicken: Dictionary, dir: Vector2) -> void:
	var windup := 0.30
	var attack_dir := dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	chicken["roll_dir"] = attack_dir
	match enemy_id:
		"goblins": windup = 0.24
		"rouses":
			windup = 0.42
			chicken["roll_origin"] = chicken.get("pos", Vector2.ZERO)
			chicken["rouses_returned"] = false
			chicken["interrupt_protected"] = true
		"guys":
			windup = GUYS_COUNTER_WINDUP
			chicken["interrupt_protected"] = true
		"werewolves":
			windup = 0.62
			chicken["interrupt_protected"] = true
		"cave-trolls":
			var attack_count := int(chicken.get("cave_troll_attack_count", 0))
			chicken["cave_troll_attack_kind"] = "pound" if posmod(attack_count, 3) == 0 else "club"
			chicken["cave_troll_attack_count"] = attack_count + 1
			chicken["face_right"] = attack_dir.x > 0.0
			chicken["interrupt_protected"] = true
			windup = 0.72 if str(chicken["cave_troll_attack_kind"]) == "pound" else 0.78
		"giants":
			var boulder_index := int(chicken.get("giant_boulder_index", -1))
			var planned_attack := str(chicken.get("giant_planned_attack", ""))
			if planned_attack not in ["stomp", "toss", "boulder"] or (planned_attack == "boulder" and boulder_index < 0):
				planned_attack = "stomp" if randf() < 0.5 else "toss"
			chicken["giant_attack_kind"] = planned_attack
			chicken["giant_planned_attack"] = ""
			chicken["face_right"] = attack_dir.x > 0.0
			var giant_attack_kind := str(chicken["giant_attack_kind"])
			windup = 0.60 if giant_attack_kind == "stomp" else 0.70
			if giant_attack_kind == "boulder" and boulder_index >= 0 and boulder_index < giant_boulders.size():
				var boulder := giant_boulders[boulder_index]
				boulder["state"] = "held"
				boulder["owner_id"] = int(chicken.get("id", -1))
				boulder["start"] = boulder.get("pos", Vector2.ZERO)
				giant_boulders[boulder_index] = boulder
				chicken["interrupt_protected"] = true
		"vampires":
			if bool(chicken.get("vampire_giant_transformed", false)):
				chicken["vampire_attack_kind"] = "swoosh" if randf() < VAMPIRE_GIANT_FLIGHT_CHANCE else "wing"
				chicken["interrupt_protected"] = true
				chicken["face_right"] = attack_dir.x > 0.0
				windup = 0.48 if str(chicken["vampire_attack_kind"]) == "swoosh" else 0.62
				chicken["attack_timer"] = windup
				chicken["attack_duration"] = windup
				chicken["attack_damage_done"] = false
				chicken["effect_fired"] = false
				chicken["lunge_dir"] = dir
				return
			var attack_count := int(chicken.get("vampire_attack_count", 0))
			var cycle_index := posmod(attack_count, 4)
			var vampire_kind := "bats" if cycle_index == 0 else ("shockwave" if cycle_index == 1 else _vampire_attack_kind_for_roll(chicken, randf()))
			chicken["vampire_force_bats"] = false
			chicken["vampire_idle_timer"] = 0.0
			chicken["vampire_attack_count"] = attack_count + 1
			var vampire_pos := chicken.get("pos", Vector2.ZERO) as Vector2
			chicken["vampire_attack_kind"] = vampire_kind
			chicken["vampire_target_pos"] = hero_pos
			chicken["vampire_crossed"] = false
			if vampire_kind in ["bats", "shockwave"]:
				if vampire_kind == "bats":
					var spawn_pattern := _vampire_bat_spawn_pattern_for_roll(randf())
					chicken["vampire_bat_spawn_pattern"] = spawn_pattern
					if spawn_pattern == "channel":
						var bat_count := randi_range(VAMPIRE_BAT_COUNT, VAMPIRE_BAT_CHANNEL_MAX_COUNT)
						chicken["vampire_bat_channel_remaining"] = bat_count
						chicken["vampire_bat_channel_total"] = bat_count
						chicken["vampire_bat_channel_spawned"] = 0
						chicken["vampire_bat_channel_beat_timer"] = VAMPIRE_BAT_CHANNEL_START_SECONDS
						chicken["interrupt_protected"] = false
						windup = VAMPIRE_BAT_CHANNEL_START_SECONDS + float(bat_count - 1) * VAMPIRE_BAT_CHANNEL_BEAT_SECONDS + 0.30
					else:
						windup = 0.78
				else:
					windup = 0.92
				chicken["roll_dir"] = (hero_pos - vampire_pos).normalized()
				chicken["face_right"] = hero_pos.x > vampire_pos.x
			else:
				windup = 0.54 if vampire_kind == "bite" else 0.68
				var flank_side := -1.0 if posmod(attack_count + int(chicken.get("id", 0)), 2) == 0 else 1.0
				var flank_distance := 0.105 if vampire_kind == "bite" else 0.175
				var vertical_offset := 0.012 * float(posmod(int(chicken.get("id", 0)), 3) - 1)
				var flank_pos := _clamp_norm_to_arena(hero_pos + Vector2(flank_side * flank_distance, vertical_offset))
				var saved_dir := (hero_pos - flank_pos).normalized()
				chicken["vampire_flank_side"] = flank_side
				chicken["pos"] = flank_pos
				chicken["render_pos"] = flank_pos
				chicken["render_sim_pos"] = flank_pos
				chicken["roll_dir"] = saved_dir if saved_dir.length() > 0.001 else attack_dir
				chicken["face_right"] = hero_pos.x > flank_pos.x
				_spawn_smoke_puffs(vampire_pos, chicken["roll_dir"] as Vector2, true)
				_spawn_smoke_puffs(flank_pos, chicken["roll_dir"] as Vector2, true)
		"dragons":
			var dragon_kind := str(chicken.get("dragon_attack_kind", "brawl"))
			windup = 0.72 if dragon_kind == "brawl" else (0.92 if dragon_kind == "pounce" else 0.88)
			chicken["dragon_cycle_damage_done"] = false
			if dragon_kind == "breath":
				_update_dragon_breath_aim(chicken, chicken.get("pos", Vector2.ZERO) as Vector2)
				chicken["roll_dir"] = chicken.get("breath_dir", attack_dir)
				chicken["face_right"] = (chicken.get("breath_dir", attack_dir) as Vector2).x > 0.0
				chicken["dragon_breath_beat_timer"] = 0.0
				chicken["dragon_breath_emissions"] = 0
			elif dragon_kind == "brawl":
				_update_dragon_melee_aim(chicken, chicken.get("pos", Vector2.ZERO) as Vector2)
			elif dragon_kind == "pounce":
				var pounce_origin := chicken.get("pos", Vector2.ZERO) as Vector2
				var pounce_distance := minf(DRAGON_POUNCE_DISTANCE, maxf(0.0, pounce_origin.distance_to(hero_pos) - 0.16))
				chicken["dragon_pounce_origin"] = pounce_origin
				chicken["dragon_pounce_target"] = _clamp_norm_to_arena(pounce_origin + attack_dir * pounce_distance)
				chicken["face_right"] = attack_dir.x > 0.0
				chicken["interrupt_protected"] = true
	chicken["attack_timer"] = windup
	chicken["attack_duration"] = windup
	chicken["attack_damage_done"] = false
	chicken["effect_fired"] = false
	chicken["slam_impacted"] = false
	chicken["wall_hit"] = false
	chicken["rouses_crashed"] = false
	chicken["wall_missed"] = false
	chicken["charge_skidded"] = false
	chicken["lunge_dir"] = dir


func _step_enemy_strike(chicken: Dictionary, pos: Vector2, dir: Vector2, delta: float) -> void:
	var attack_dir := chicken.get("roll_dir", Vector2.ZERO) as Vector2
	if attack_dir.length() <= 0.001:
		attack_dir = dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
		chicken["roll_dir"] = attack_dir
	match enemy_id:
		"chicken-swarm":
			chicken["pos"] = pos + attack_dir * delta * 0.30
		"goblins":
			chicken["pos"] = pos
		"guys":
			chicken["pos"] = pos
		"rouses":
			var roll_pos := pos + attack_dir * delta * 0.475
			if roll_pos.x < 0.06 or roll_pos.x > 0.94 or roll_pos.y < 0.08 or roll_pos.y > 0.92:
				if not bool(chicken.get("rouses_crashed", false)):
					_queue_effect("dizzy-stars", _clamp_norm_to_arena(roll_pos), Vector2.ZERO)
				chicken["wall_hit"] = true
				chicken["rouses_crashed"] = true
				chicken["pos"] = _clamp_rouses_roll_to_stage(roll_pos)
			else:
				chicken["pos"] = roll_pos
		"werewolves":
			var charge_speed := 5.00 if bool(chicken.get("attack_damage_done", false)) else 0.78
			var charge_pos := pos + attack_dir * delta * charge_speed
			if charge_pos.x < 0.07 or charge_pos.x > 0.93 or charge_pos.y < 0.09 or charge_pos.y > 0.91:
				chicken["wall_missed"] = true
				chicken["charge_skidded"] = true
				chicken["pos"] = _clamp_norm_to_arena(charge_pos)
			else:
				chicken["pos"] = charge_pos
		"vampires":
			var vampire_kind := str(chicken.get("vampire_attack_kind", "swipe"))
			if vampire_kind == "swoosh":
				var swoop_side := -1.0 if posmod(int(chicken.get("id", 0)), 2) == 0 else 1.0
				chicken["pos"] = _clamp_norm_to_arena(pos + (attack_dir + attack_dir.orthogonal() * swoop_side * 0.24).normalized() * delta * 0.95)
			elif vampire_kind == "wing":
				chicken["pos"] = _clamp_norm_to_arena(pos + attack_dir * delta * 0.28)
			elif vampire_kind == "bats":
				chicken["pos"] = pos
				if str(chicken.get("vampire_bat_spawn_pattern", "burst")) == "burst" and float(chicken.get("signature_t", 0.0)) >= 0.16 and not bool(chicken.get("effect_fired", false)):
					chicken["effect_fired"] = true
					_spawn_vampire_bats(chicken)
			elif vampire_kind == "shockwave":
				chicken["pos"] = pos
				if float(chicken.get("signature_t", 0.0)) >= 0.16 and not bool(chicken.get("effect_fired", false)):
					chicken["effect_fired"] = true
					_spawn_vampire_shockwave(chicken)
			else:
				var slide_speed := 0.24 if vampire_kind == "bite" else 0.62
				chicken["pos"] = _clamp_norm_to_arena(pos + attack_dir * delta * slide_speed)
		"dragons":
			var dragon_kind := str(chicken.get("dragon_attack_kind", "brawl"))
			if dragon_kind == "brawl":
				# ponytail: hold the boss in the readable brawl pocket; the recovery owns retreat.
				chicken["pos"] = pos
				_update_dragon_melee_aim(chicken, pos)
			elif dragon_kind == "pounce":
				var pounce_progress := _smooth01(clampf(float(chicken.get("signature_t", 0.0)) / DRAGON_POUNCE_LAND_PROGRESS, 0.0, 1.0))
				chicken["pos"] = (chicken.get("dragon_pounce_origin", pos) as Vector2).lerp(chicken.get("dragon_pounce_target", pos) as Vector2, pounce_progress)
			else:
				chicken["pos"] = pos
				_update_dragon_breath_aim(chicken, pos)

	var contact_range := _enemy_contact_range(chicken)
	var contact_pos := chicken.get("pos", pos) as Vector2
	if enemy_id == "vampires" and str(chicken.get("vampire_attack_kind", "swipe")) == "swipe" and not bool(chicken.get("vampire_crossed", false)):
		var target_pos := chicken.get("vampire_target_pos", hero_pos) as Vector2
		var before_plane := (pos - target_pos).dot(attack_dir)
		var after_plane := (contact_pos - target_pos).dot(attack_dir)
		if before_plane <= 0.0 and after_plane >= 0.0:
			chicken["vampire_crossed"] = true
	var can_hit := contact_pos.distance_to(hero_pos) <= contact_range
	if enemy_id == "vampires":
		var vampire_kind := str(chicken.get("vampire_attack_kind", "swipe"))
		if vampire_kind in ["bats", "shockwave"]:
			can_hit = false
		elif vampire_kind == "bite":
			can_hit = can_hit and float(chicken.get("signature_t", 0.0)) >= 0.22
	var impact_frame := false
	if enemy_id == "cave-trolls":
		var is_pound := str(chicken.get("cave_troll_attack_kind", "pound")) == "pound"
		var impact_time := 0.62 if is_pound else 0.68
		if float(chicken.get("signature_t", 0.0)) >= impact_time and not bool(chicken.get("slam_impacted", false)):
			chicken["slam_impacted"] = true
			impact_frame = true
			_queue_effect("cave-troll-slam", contact_pos, attack_dir)
			if is_pound and can_hit:
				_start_hero_stun_bump(contact_pos)
		if not impact_frame:
			can_hit = false
	if enemy_id == "giants" and str(chicken.get("giant_attack_kind", "toss")) == "stomp":
		var stomp_impact := float(chicken.get("signature_t", 0.0)) >= 0.08 and not bool(chicken.get("slam_impacted", false))
		if stomp_impact:
			chicken["slam_impacted"] = true
			_queue_effect("cave-troll-slam", contact_pos, attack_dir)
			if can_hit:
				_start_hero_bump(contact_pos)
		else:
			can_hit = false
	if enemy_id == "giants" and str(chicken.get("giant_attack_kind", "toss")) == "boulder":
		can_hit = false
		if float(chicken.get("signature_t", 0.0)) >= 0.32 and not bool(chicken.get("effect_fired", false)):
			chicken["effect_fired"] = true
			_throw_giant_boulder(chicken)
	if enemy_id == "dragons":
		var dragon_kind := str(chicken.get("dragon_attack_kind", "brawl"))
		if dragon_kind == "breath":
			var beat_timer := float(chicken.get("dragon_breath_beat_timer", 0.0)) - delta
			var emissions := int(chicken.get("dragon_breath_emissions", 0))
			var breath_dir := chicken.get("breath_dir", dir) as Vector2
			if float(chicken.get("signature_t", 0.0)) >= 0.06 and beat_timer <= 0.0 and emissions < DRAGON_BREATH_BURST_COUNT:
				var side := -1.0 if emissions % 2 == 0 else 1.0
				var lateral := Vector2(-breath_dir.y, breath_dir.x)
				var mouth_pos := _dragon_mouth_pos(contact_pos, breath_dir)
				var tuft_pos := mouth_pos + breath_dir * (emissions * DRAGON_BREATH_TUFT_SPACING) + lateral * side * 0.012
				_queue_effect("dragon-breath-fire-tuft", tuft_pos, breath_dir.rotated(side * 0.05))
				emissions += 1
				beat_timer += DRAGON_BREATH_BEAT_SECONDS
			chicken["dragon_breath_beat_timer"] = beat_timer
			chicken["dragon_breath_emissions"] = emissions
			var to_hero := hero_pos - contact_pos
			var along := to_hero.dot(breath_dir)
			var lateral := absf(to_hero.cross(breath_dir))
			can_hit = breath_dir.length() > 0.001 and along >= 0.0 and along <= 0.78 and lateral <= 0.10 + along * 0.18
		elif dragon_kind == "pounce":
			var landed := float(chicken.get("signature_t", 0.0)) >= DRAGON_POUNCE_LAND_PROGRESS
			if landed and not bool(chicken.get("slam_impacted", false)):
				chicken["slam_impacted"] = true
				_queue_effect("dragon-pounce-shockwave", contact_pos, attack_dir)
				if contact_pos.distance_to(hero_pos) <= DRAGON_POUNCE_IMPACT_RANGE:
					chicken["attack_damage_done"] = true
					chicken["dragon_cycle_damage_done"] = true
					_apply_enemy_contact_damage(chicken)
					_start_hero_toss(contact_pos, GIANT_TOSS_DISTANCE * 0.5)
			can_hit = false
		else:
			can_hit = contact_pos.distance_to(hero_pos) <= contact_range
	if enemy_id == "giants" and str(chicken.get("giant_attack_kind", "toss")) == "toss" and can_hit and float(chicken.get("signature_t", 0.0)) > 0.55 and not bool(chicken.get("grabbed_hero", false)):
		chicken["grabbed_hero"] = true
		_start_hero_toss(contact_pos)
	if enemy_id == "werewolves" and bool(chicken.get("wall_missed", false)):
		can_hit = false
	if can_hit and not bool(chicken.get("attack_damage_done", false)):
		chicken["attack_damage_done"] = true
		if enemy_id != "dragons" or str(chicken.get("dragon_attack_kind", "brawl")) == "brawl" or not bool(chicken.get("dragon_cycle_damage_done", false)):
			if enemy_id == "vampires" and str(chicken.get("vampire_attack_kind", "swipe")) == "bite":
				_apply_vampire_bite(chicken)
			else:
				_apply_enemy_contact_damage(chicken)
			if enemy_id == "dragons":
				chicken["dragon_cycle_damage_done"] = true


func _dragon_mouth_pos(dragon_pos: Vector2, breath_dir: Vector2) -> Vector2:
	var depth_scale := 0.82 + dragon_pos.y * 0.34
	var facing := 1.0 if breath_dir.x >= 0.0 else -1.0
	return dragon_pos + Vector2(DRAGON_MOUTH_OFFSET.x * facing, DRAGON_MOUTH_OFFSET.y + breath_dir.y * 0.018) * depth_scale


func _step_enemy_recovery(chicken: Dictionary, pos: Vector2, delta: float) -> void:
	if enemy_id == "rouses":
		var origin := chicken.get("roll_origin", pos) as Vector2
		chicken["pos"] = pos.move_toward(origin, delta * 0.95)
		if (chicken["pos"] as Vector2).is_equal_approx(origin):
			chicken["rouses_returned"] = true
	if enemy_id == "vampires":
		chicken["pos"] = pos
	if enemy_id == "dragons" and str(chicken.get("dragon_attack_kind", "brawl")) == "brawl":
		var retreat_side := 1.0 if pos.x > hero_pos.x else -1.0
		var retreat_target := Vector2(0.945 if retreat_side > 0.0 else 0.055, 0.55)
		var dragon_retreat := (retreat_target - pos).normalized()
		chicken["pos"] = _clamp_norm_to_arena(pos + dragon_retreat * delta * 0.40)
	if enemy_id == "giants" and bool(chicken.get("grabbed_hero", false)):
		if hero_toss_timer <= 0.0:
			chicken["grabbed_hero"] = false


func _start_hero_toss(giant_pos: Vector2, toss_distance := GIANT_TOSS_DISTANCE) -> void:
	var toss_dir := (hero_pos - giant_pos).normalized()
	if toss_dir.length_squared() <= 0.001:
		toss_dir = Vector2.RIGHT
	var target := _clamp_norm_to_arena(hero_pos + toss_dir * toss_distance)
	if target.distance_to(hero_pos) < toss_distance * 0.55:
		toss_dir = -toss_dir
		target = _clamp_norm_to_arena(hero_pos + toss_dir * toss_distance)
	hero_toss_start = hero_pos
	hero_toss_target = target
	hero_toss_direction = toss_dir
	hero_toss_timer = GIANT_TOSS_DURATION
	hero_bump_timer = 0.0
	hero_attack_timer = 0.0
	hero_facing = 1 if toss_dir.x >= 0.0 else -1


func _step_hero_toss(delta: float) -> void:
	if hero_toss_timer <= 0.0:
		return
	hero_toss_timer = maxf(0.0, hero_toss_timer - delta)
	var elapsed := GIANT_TOSS_DURATION - hero_toss_timer
	var travel_t := _smooth01(clampf(elapsed / GIANT_TOSS_TRAVEL_SECONDS, 0.0, 1.0))
	hero_pos = _clamp_norm_to_arena(hero_toss_start.lerp(hero_toss_target, travel_t))


func _start_hero_bump(giant_pos: Vector2) -> void:
	if hero_toss_timer > 0.0:
		return
	var bump_dir := (hero_pos - giant_pos).normalized()
	if bump_dir.length_squared() <= 0.001:
		bump_dir = Vector2.RIGHT
	var target := _clamp_norm_to_arena(hero_pos + bump_dir * GIANT_STOMP_BUMP_DISTANCE)
	if target.distance_to(hero_pos) < GIANT_STOMP_BUMP_DISTANCE * 0.5:
		bump_dir = -bump_dir
		target = _clamp_norm_to_arena(hero_pos + bump_dir * GIANT_STOMP_BUMP_DISTANCE)
	hero_toss_start = hero_pos
	hero_toss_target = target
	hero_toss_direction = bump_dir
	hero_bump_timer = GIANT_STOMP_BUMP_DURATION
	hero_attack_timer = 0.0


func _start_hero_stun_bump(troll_pos: Vector2) -> void:
	if hero_toss_timer > 0.0:
		return
	_start_hero_bump(troll_pos)
	hero_stun_timer = maxf(hero_stun_timer, CAVE_TROLL_STUN_DURATION)
	_queue_effect("dizzy-stars", hero_pos, Vector2.ZERO)


func _step_hero_bump(delta: float) -> void:
	if hero_bump_timer <= 0.0:
		return
	hero_bump_timer = maxf(0.0, hero_bump_timer - delta)
	var elapsed := GIANT_STOMP_BUMP_DURATION - hero_bump_timer
	var travel_t := _smooth01(clampf(elapsed / GIANT_STOMP_BUMP_DURATION, 0.0, 1.0))
	hero_pos = _clamp_norm_to_arena(hero_toss_start.lerp(hero_toss_target, travel_t))


func _stagger_enemy(chicken: Dictionary, force_interrupt := false) -> void:
	var phase := str(chicken.get("attack_phase", ""))
	if enemy_id == "dragons" and str(chicken.get("dragon_attack_kind", "")) == "pounce" and phase in ["windup", "strike"]:
		return
	if phase != "windup" and not (force_interrupt and phase == "strike"):
		return
	if bool(chicken.get("interrupt_protected", false)) and not force_interrupt:
		return
	_release_giant_boulder(chicken)
	chicken["attack_phase"] = "stagger"
	chicken["attack_timer"] = 0.0
	chicken["vampire_bat_channel_remaining"] = 0
	chicken["vampire_bat_channel_beat_timer"] = 0.0
	chicken["stagger_timer"] = 0.42
	chicken["attack_damage_done"] = true
	chicken["hit_flash"] = 0.42
	_queue_effect("dizzy-stars", chicken.get("pos", Vector2.ZERO) as Vector2, Vector2.ZERO)
	chicken["interrupt_protected"] = true


func _try_transform_vampire_giant(chicken: Dictionary, roll: float) -> bool:
	if enemy_id != "vampires" or bool(chicken.get("vampire_giant_roll_done", false)) or bool(chicken.get("vampire_giant_transformed", false)):
		return false
	if float(chicken.get("hp", 0.0)) / maxf(1.0, float(chicken.get("max_hp", 1.0))) >= VAMPIRE_GIANT_TRANSFORM_HEALTH_RATIO:
		return false
	chicken["vampire_giant_roll_done"] = true
	if roll >= VAMPIRE_GIANT_TRANSFORM_CHANCE:
		return false
	var health_ratio := float(chicken.get("hp", 0.0)) / maxf(1.0, float(chicken.get("max_hp", 1.0)))
	chicken["max_hp"] = float(chicken.get("max_hp", 1.0)) * VAMPIRE_GIANT_HEALTH_MULT
	chicken["hp"] = float(chicken["max_hp"]) * health_ratio
	chicken["damage"] = float(chicken.get("damage", CHICKEN_DAMAGE)) * VAMPIRE_GIANT_DAMAGE_MULT
	chicken["speed"] = float(chicken.get("speed", 0.09)) * 1.20
	chicken["vampire_giant_transformed"] = true
	chicken["transform_timer"] = VAMPIRE_GIANT_TRANSFORM_DURATION
	chicken["attack_phase"] = ""
	chicken["attack_timer"] = 0.0
	chicken["attack_cd"] = VAMPIRE_GIANT_TRANSFORM_DURATION
	chicken["vampire_teleport_phase"] = ""
	chicken["vampire_walk_timer"] = 0.0
	chicken["interrupt_protected"] = true
	return true


func _apply_enemy_contact_damage(chicken: Dictionary) -> void:
	if hero_hurt_cooldown > 0.0:
		return
	var damage := float(chicken.get("damage", CHICKEN_DAMAGE))
	hero_hp = maxf(0.0, hero_hp - damage)
	hero_hurt_cooldown = 0.0 if enemy_id == "guys" else 0.42
	if enemy_id == "werewolves":
		_queue_effect("wolf-claw-tear", hero_pos, chicken.get("roll_dir", Vector2.ZERO) as Vector2)
	_add_float("CRIT! -%d" % int(round(damage)) if enemy_id == "werewolves" else "-%d" % int(round(damage)), _norm_to_stage(hero_pos) + Vector2(26.0, -74.0) * _stage_scale(), DANGER)


func _apply_vampire_bite(chicken: Dictionary) -> void:
	var hero_hp_before := hero_hp
	_apply_enemy_contact_damage(chicken)
	var drained := maxf(0.0, hero_hp_before - hero_hp)
	if drained <= 0.0:
		return
	chicken["hp"] = minf(float(chicken.get("max_hp", 1.0)), float(chicken.get("hp", 0.0)) + drained)
	_add_float("+%d" % int(round(drained)), _norm_to_stage(chicken.get("pos", Vector2.ZERO) as Vector2) + Vector2(0.0, -94.0) * _stage_scale(), REWARD_GREEN)


func _enemy_attack_range(chicken: Dictionary = {}) -> float:
	match enemy_id:
		"goblins": return 0.17
		"rouses", "werewolves": return 0.20
		"guys": return GUYS_ATTACK_RANGE
		"cave-trolls": return 0.22
		"giants": return 0.28
		"vampires": return 0.15 if str(chicken.get("vampire_attack_kind", "swipe")) == "bite" else 0.24
		"dragons":
			var dragon_kind := str(chicken.get("dragon_attack_kind", "brawl"))
			return DRAGON_BRAWL_RANGE if dragon_kind == "brawl" else (DRAGON_POUNCE_RANGE if dragon_kind == "pounce" else DRAGON_BREATH_RANGE)
	return CHICKEN_ATTACK_RANGE


func _enemy_contact_range(chicken: Dictionary = {}) -> float:
	if enemy_id == "guys":
		return GUYS_ATTACK_RANGE
	if enemy_id == "dragons" and str(chicken.get("dragon_attack_kind", "")) == "pounce":
		return DRAGON_POUNCE_IMPACT_RANGE
	return _enemy_attack_range(chicken) + (0.045 if enemy_id not in ["dragons", "cave-trolls"] else 0.07)


func _enemy_hero_ring_radius(chicken: Dictionary = {}) -> float:
	return clampf(_enemy_attack_range(chicken) * 0.72, 0.115, 0.20)


func _clamp_enemy_approach_to_hero_ring(chicken: Dictionary, previous_pos: Vector2, next_pos: Vector2) -> Vector2:
	var movement := next_pos - previous_pos
	if movement.length_squared() <= 0.000001:
		return next_pos
	var closest_t := clampf((hero_pos - previous_pos).dot(movement) / movement.length_squared(), 0.0, 1.0) if movement.length_squared() > 0.000001 else 0.0
	var radius := _enemy_hero_ring_radius(chicken)
	if (previous_pos + movement * closest_t).distance_to(hero_pos) >= radius:
		return next_pos
	var direction := (previous_pos - hero_pos).normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.from_angle(float(int(chicken.get("id", 0))) * 2.399963)
	return hero_pos + direction * radius


func _update_enemy_render_pos(chicken: Dictionary, delta: float) -> void:
	var sim_pos := chicken.get("pos", Vector2.ZERO) as Vector2
	var previous_sim_pos := chicken.get("render_sim_pos", sim_pos) as Vector2
	var render_pos := chicken.get("render_pos", sim_pos) as Vector2
	if float(chicken.get("hp", 0.0)) <= 0.0:
		chicken["render_pos"] = _clamp_norm_to_arena(render_pos + sim_pos - previous_sim_pos)
		chicken["render_sim_pos"] = sim_pos
		return
	if enemy_id == "rouses" and str(chicken.get("attack_phase", "")) in ["strike", "recovery"]:
		chicken["render_pos"] = _clamp_rouses_roll_to_stage(render_pos + sim_pos - previous_sim_pos)
		chicken["render_sim_pos"] = sim_pos
		return
	if enemy_id == "dragons" and str(chicken.get("dragon_attack_kind", "")) == "pounce" and str(chicken.get("attack_phase", "")) == "strike":
		chicken["render_pos"] = _clamp_norm_to_arena(render_pos + sim_pos - previous_sim_pos)
		chicken["render_sim_pos"] = sim_pos
		return
	var follow := 1.0 - exp(-18.0 * delta)
	var next_render_pos := render_pos.lerp(sim_pos, follow)
	chicken["render_pos"] = next_render_pos
	chicken["render_sim_pos"] = sim_pos
	if str(chicken.get("attack_phase", "")).is_empty() and float(chicken.get("uppercut_knock_timer", 0.0)) <= 0.0 and float(chicken.get("hit_flash", 0.0)) <= 0.0:
		_update_chicken_facing(chicken, next_render_pos - render_pos)


func _clamp_rouses_roll_to_stage(pos: Vector2) -> Vector2:
	if arena_shape == "diamond":
		return _clamp_norm_to_diamond(pos, 0.0)
	return Vector2(clampf(pos.x, 0.035, 0.965), clampf(pos.y, 0.07, 0.93))


func _enemy_strike_duration(chicken: Dictionary = {}) -> float:
	match enemy_id:
		"goblins": return 0.16
		"rouses": return 0.42
		"werewolves": return 0.35
		"cave-trolls": return 0.24
		"giants": return 0.34
		"vampires": return 0.66
		"dragons":
			var dragon_kind := str(chicken.get("dragon_attack_kind", "brawl"))
			return 0.52 if dragon_kind == "brawl" else (DRAGON_POUNCE_STRIKE_SECONDS if dragon_kind == "pounce" else DRAGON_BREATH_STRIKE_SECONDS)
	return 0.24


func _enemy_recovery_duration() -> float:
	match enemy_id:
		"rouses", "werewolves": return 0.68
		"cave-trolls": return 0.92
		"giants": return 1.20
		"vampires": return 0.90
		"dragons": return 1.35
	return 0.38


func _enemy_attack_cooldown() -> float:
	match enemy_id:
		"goblins": return 0.78
		"rouses": return 2.20
		"guys": return 0.45
		"werewolves": return 1.55
		"cave-trolls": return 1.80
		"giants": return 2.20
		"vampires": return 1.70
		"dragons": return 2.40
	return 1.15


func _update_chicken_facing(chicken: Dictionary, travel: Vector2) -> void:
	if enemy_id == "goblins" and float(chicken.get("hp", 0.0)) > 0.0:
		var to_hero_x := hero_pos.x - (chicken.get("pos", hero_pos) as Vector2).x
		if absf(to_hero_x) > 0.055:
			chicken["face_right"] = to_hero_x > 0.0
		return
	if not is_zero_approx(travel.x):
		chicken["face_right"] = travel.x > 0.0


func _start_hero_attack() -> bool:
	if hero_toss_timer > 0.0 or hero_bump_timer > 0.0 or hero_stun_timer > 0.0:
		return false
	var normal_target_index := _nearest_punchable_chicken_index()
	var uppercut_target_index := _nearest_punchable_chicken_index_for_reach(_hero_uppercut_reach())
	var bat_target_index := _nearest_punchable_vampire_bat_index_for_reach(_hero_attack_reach())
	var food_index := _nearest_punchable_food_index()
	var use_uppercut := uppercut_target_index >= 0 and hero_uppercut_cd <= 0.0 and randf() <= HERO_UPPERCUT_CHANCE
	var target_index := uppercut_target_index if use_uppercut else normal_target_index
	if target_index < 0 and bat_target_index < 0 and food_index < 0:
		return false
	var target_pos := hero_pos + Vector2.RIGHT
	var target_dist := INF
	for candidate in [
		chickens[target_index].get("pos", target_pos) if target_index >= 0 else null,
		vampire_bats[bat_target_index].get("pos", target_pos) if bat_target_index >= 0 else null,
		food_drops[food_index].get("pos", target_pos) if food_index >= 0 else null,
	]:
		if candidate is Vector2 and (candidate as Vector2).distance_squared_to(hero_pos) < target_dist:
			target_pos = candidate as Vector2
			target_dist = target_pos.distance_squared_to(hero_pos)
	var dir := target_pos - hero_pos
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	hero_attack_dir = dir.normalized()
	hero_facing = -1 if hero_attack_dir.x < -0.04 else 1
	hero_attack_is_uppercut = use_uppercut
	hero_attack_timer = 0.34 if use_uppercut else 0.24
	hero_attack_purple_buffed = hero_purple_buff_punches > 0 and (target_index >= 0 or bat_target_index >= 0)
	var purple_buff_mult := VAMPIRE_SHOCKWAVE_HERO_BUFF_MULT if hero_attack_purple_buffed else 1.0
	if hero_attack_purple_buffed:
		hero_purple_buff_punches = maxi(0, hero_purple_buff_punches - 1)
	if use_uppercut:
		hero_uppercut_cd = HERO_UPPERCUT_COOLDOWN
		_add_float("UPPERCUT!", _norm_to_stage(hero_pos) + Vector2(0.0, -132.0) * _stage_scale(), ACTIVE_WAVE_BLUE, 0.82)
	var did_hit := false
	var shield_dropped := false
	for i in range(chickens.size()):
		if i != target_index and enemy_id == "chicken-swarm":
			continue
		var chicken := chickens[i]
		if not _is_punchable_enemy(chicken):
			continue
		var chicken_pos := chicken.get("pos", Vector2.ZERO) as Vector2
		if _chicken_inside_current_punch(chicken_pos):
			if enemy_id == "goblins" and bool(chicken.get("shield_up", false)):
				chicken["shield_up"] = false
				chicken["shield_fall_timer"] = ENEMY_DEATH_LIFETIME
				var shield_side := 1.0 if chicken_pos.x < hero_pos.x else -1.0
				chicken["shield_fall_direction"] = Vector2(shield_side * 0.42, 1.0).normalized()
				chicken["shield_fall_rotation"] = shield_side * 1.9
				var shield_drop_pos := chicken.get("render_pos", chicken_pos) as Vector2
				chicken["shield_drop_pos"] = shield_drop_pos
				chicken["shield_drop_scale"] = (0.82 + shield_drop_pos.y * 0.34) * (DIAMOND_ENEMY_DRAW_SCALE if arena_shape == "diamond" else 1.0) * enemy_sprite_scale
				chicken["shield_drop_face_right"] = bool(chicken.get("face_right", chicken_pos.x < hero_pos.x))
				chicken["hit_flash"] = 0.26 if not use_uppercut else 0.38
				_spawn_feather_burst(chicken_pos, 5 if not use_uppercut else 9, use_uppercut)
				_trigger_hit_stop(use_uppercut)
				_queue_effect("hit-impact-yellow", chicken_pos, hero_attack_dir)
				chickens[i] = chicken
				did_hit = true
				shield_dropped = true
				continue
			var guarded_hit := enemy_id == "guys" and bool(chicken.get("guarding", false))
			var hero_damage := _roll_hero_uppercut_damage() if use_uppercut else _roll_hero_attack_damage()
			hero_damage *= purple_buff_mult
			if guarded_hit:
				hero_damage *= 0.72
			var hp := maxf(0.0, float(chicken.get("hp", 0.0)) - hero_damage)
			chicken["hp"] = hp
			chicken["hit_flash"] = 0.38 if use_uppercut else 0.26
			if enemy_id == "werewolves" and not bool(chicken.get("werewolf_transformed", false)):
				chicken["werewolf_transformed"] = true
				chicken["transform_timer"] = WEREWOLF_TRANSFORM_DURATION
				chicken["attack_phase"] = ""
				chicken["attack_timer"] = 0.0
				chicken["attack_cd"] = 0.0
			if hp > 0.0:
				_try_transform_vampire_giant(chicken, randf())
			var force_boulder_drop := false
			if use_uppercut and enemy_id == "giants":
				var boulder_index := int(chicken.get("giant_boulder_index", -1))
				force_boulder_drop = boulder_index >= 0 and boulder_index < giant_boulders.size() and str(giant_boulders[boulder_index].get("state", "")) == "held"
			_stagger_enemy(chicken, force_boulder_drop)
			if guarded_hit and hp > 0.0 and str(chicken.get("attack_phase", "")).is_empty():
				_begin_enemy_attack(chicken, hero_pos - chicken_pos)
				chicken["attack_phase"] = "windup"
				chicken["attack_timer"] = GUYS_COUNTER_WINDUP
				chicken["attack_duration"] = GUYS_COUNTER_WINDUP
				chicken["attack_cd"] = _enemy_attack_cooldown()
				chicken["guarding"] = false
			_spawn_feather_burst(chicken_pos, 9 if use_uppercut else 5, use_uppercut)
			_trigger_hit_stop(use_uppercut)
			_queue_effect("hit-impact-yellow", chicken_pos, hero_attack_dir)
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
				var death_knock_dir := chicken_pos - hero_pos
				if death_knock_dir.length() < 0.001:
					death_knock_dir = hero_attack_dir
				chicken["uppercut_knock_timer"] = CHICKEN_UPPERCUT_KNOCK_SECONDS
				chicken["uppercut_knock_duration"] = CHICKEN_UPPERCUT_KNOCK_SECONDS
				chicken["uppercut_knock_dir"] = death_knock_dir.normalized()
				chicken["death_bounce_scale"] = 1.0 if use_uppercut else 1.0 / 3.0
				ko_count += 1
				wave_kills += 1
				var xp_reward := _xp_reward_for_kill()
				chicken_killed.emit(xp_reward)
				if xp_reward > 0:
					_add_float("+%d XP" % xp_reward, _norm_to_stage(chicken_pos) + Vector2(10.0, -72.0) * _stage_scale(), REWARD_GREEN)
				if not end_wave_active:
					_maybe_spawn_food_drop(chicken_pos)
			elif enemy_id != "chicken-swarm":
				_add_float("-%d" % int(hero_damage), _norm_to_stage(chicken_pos) + Vector2(0.0, -92.0 if use_uppercut else -74.0) * _stage_scale(), DANGER, 0.82 if use_uppercut else 0.72)
			chickens[i] = chicken
			if hp <= 0.0 and end_wave_active:
				_try_complete_end_wave()
			did_hit = true
	if enemy_id == "vampires":
		for i in range(vampire_bats.size()):
			var bat := vampire_bats[i]
			var bat_pos := bat.get("pos", Vector2.ZERO) as Vector2
			if float(bat.get("hp", 0.0)) > 0.0 and float(bat.get("spawn_invuln_timer", 0.0)) <= 0.0 and _chicken_inside_current_punch(bat_pos):
				bat["hp"] = maxf(0.0, float(bat.get("hp", 0.0)) - 1.0)
				vampire_bats[i] = bat
				_queue_effect("hit-impact-yellow", bat_pos, hero_attack_dir)
				_spawn_smoke_puffs(bat_pos, hero_attack_dir)
				if float(bat["hp"]) <= 0.0:
					var bat_xp := int(bat.get("buff_count", 0))
					if bat_xp > 0:
						chicken_killed.emit(bat_xp)
						_add_float("+%d XP" % bat_xp, _norm_to_stage(bat_pos) + Vector2(10.0, -58.0) * _stage_scale(), REWARD_GREEN)
				did_hit = true
		vampire_bats = vampire_bats.filter(func(bat: Dictionary) -> bool:
			return float(bat.get("hp", 0.0)) > 0.0
		)
	if enemy_id == "guys" and not use_uppercut:
		_trigger_guys_punch_flee()
	for i in range(food_drops.size()):
		var food_drop := food_drops[i]
		if bool(food_drop.get("consumed", false)):
			continue
		var food_pos := food_drop.get("pos", Vector2.ZERO) as Vector2
		if _food_inside_current_punch(food_pos):
			food_drops[i] = _consume_food_drop(food_drop)
			did_hit = true
	if did_hit:
		punch_landed.emit(shield_dropped)
	return did_hit


func _trigger_guys_punch_flee() -> void:
	for i in range(chickens.size()):
		var chicken := chickens[i]
		if float(chicken.get("hp", 0.0)) <= 0.0 or not str(chicken.get("attack_phase", "")).is_empty():
			continue
		var chicken_pos := chicken.get("pos", Vector2.ZERO) as Vector2
		var to_chicken := chicken_pos - hero_pos
		if to_chicken.length() <= _enemy_attack_range(chicken) or to_chicken.dot(hero_attack_dir) < 0.0 or _chicken_inside_current_punch(chicken_pos) or not _point_inside_current_punch(chicken_pos, GUYS_PUNCH_FLEE_RADIUS):
			continue
		var along_punch := clampf(to_chicken.dot(hero_attack_dir), 0.0, _current_attack_range())
		var punch_escape := chicken_pos - (hero_pos + hero_attack_dir * along_punch)
		var radial := to_chicken.normalized() if to_chicken.length() > 0.001 else hero_attack_dir
		var sideways := radial.orthogonal()
		chicken["punch_flee_side"] = -1.0 if sideways.dot(punch_escape) < 0.0 else 1.0
		chicken["punch_flee_dir"] = sideways * float(chicken["punch_flee_side"])
		chicken["punch_flee_timer"] = randf_range(GUYS_PUNCH_FLEE_SECONDS - 0.10, GUYS_PUNCH_FLEE_SECONDS + 0.10)
		chicken["punch_flee_speed"] = randf_range(1.15, 1.35)
		chicken["guarding"] = false
		chickens[i] = chicken


func _nearest_punchable_chicken_index() -> int:
	return _nearest_punchable_chicken_index_for_reach(_hero_attack_reach())


func _nearest_punchable_chicken_index_for_reach(reach: float) -> int:
	var nearest := -1
	var nearest_dist := 999.0
	for i in range(chickens.size()):
		var chicken := chickens[i]
		if not _is_punchable_enemy(chicken):
			continue
		var dist := (chicken.get("pos", Vector2.ZERO) as Vector2).distance_to(hero_pos)
		if dist > reach:
			continue
		if dist < nearest_dist:
			nearest = i
			nearest_dist = dist
	return nearest


func _nearest_punchable_vampire_bat_index_for_reach(reach: float) -> int:
	if enemy_id != "vampires":
		return -1
	var nearest := -1
	var nearest_dist := INF
	for i in range(vampire_bats.size()):
		var bat := vampire_bats[i]
		if float(bat.get("hp", 0.0)) <= 0.0 or float(bat.get("spawn_invuln_timer", 0.0)) > 0.0:
			continue
		var dist := (bat.get("pos", Vector2.ZERO) as Vector2).distance_to(hero_pos)
		if dist <= reach and dist < nearest_dist:
			nearest = i
			nearest_dist = dist
	return nearest


func _is_punchable_enemy(chicken: Dictionary) -> bool:
	return float(chicken.get("hp", 0.0)) > 0.0 and not (enemy_id == "werewolves" and float(chicken.get("transform_timer", 0.0)) > 0.0)


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
	return _point_inside_current_punch(chicken_pos, _current_attack_radius())


func _food_inside_current_punch(food_pos: Vector2) -> bool:
	return _point_inside_current_punch(food_pos, COOKED_CHICKEN_PICKUP_RADIUS)


func _point_inside_current_punch(point: Vector2, radius: float) -> bool:
	var to_point := point - hero_pos
	var hitbox_radius := _current_attack_radius()
	var along_punch := to_point.dot(hero_attack_dir)
	if enemy_id == "goblins" and along_punch < 0.0:
		return false
	along_punch = clampf(along_punch, 0.0, _current_attack_range())
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
	if enemy_id == "chicken-swarm":
		return CHICKEN_PUNCH_RANGE + CHICKEN_PUNCH_RADIUS
	return HERO_HITBOX_RANGE + HERO_HITBOX_RADIUS


func _hero_uppercut_reach() -> float:
	if enemy_id == "chicken-swarm":
		return CHICKEN_UPPERCUT_RANGE + CHICKEN_UPPERCUT_RADIUS
	return HERO_UPPERCUT_RANGE + HERO_UPPERCUT_RADIUS


func _current_attack_range() -> float:
	if enemy_id == "chicken-swarm":
		return CHICKEN_UPPERCUT_RANGE if hero_attack_is_uppercut else CHICKEN_PUNCH_RANGE
	return HERO_UPPERCUT_RANGE if hero_attack_is_uppercut else HERO_HITBOX_RANGE


func _current_attack_radius() -> float:
	if enemy_id == "chicken-swarm":
		return CHICKEN_UPPERCUT_RADIUS if hero_attack_is_uppercut else CHICKEN_PUNCH_RADIUS
	return HERO_UPPERCUT_RADIUS if hero_attack_is_uppercut else HERO_HITBOX_RADIUS


func _living_chicken_count() -> int:
	var count := 0
	for chicken in chickens:
		if float(chicken.get("hp", 0.0)) > 0.0:
			count += 1
	for bat in vampire_bats:
		if float(bat.get("hp", 0.0)) > 0.0:
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
	spawn_timer = 0.0
	wave_rest_timer = 0.0
	wave_elapsed_current = wave_duration_current
	displayed_wave_progress = 1.0
	area_clear_restart_timer = AREA_CLEAR_RESTART_DELAY
	var xp_reward := _xp_reward_for_area_clear()
	chicken_killed.emit(xp_reward)
	var clear_center := _norm_to_stage(Vector2(0.5, 0.30))
	_add_float("area cleared!", clear_center, REWARD_GREEN, 1.32)
	if xp_reward > 0:
		_add_float("+%d XP" % xp_reward, clear_center + Vector2(0.0, 62.0) * _stage_scale(), REWARD_GREEN, 1.28)


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


func _wave_stat_mult(variant: String) -> float:
	if end_wave_active:
		if enemy_id == "rouses":
			return {"black": 0.20, "gray": 0.16}.get(variant, 0.12)
		var end_scale := float({"guys": GUYS_END_WAVE_STAT_SCALE, "goblins": 0.08, "werewolves": 0.12, "cave-trolls": 0.28, "giants": 0.45, "vampires": 0.08, "dragons": 0.10}.get(enemy_id, 1.0))
		if variant == "black":
			return 2.85 * end_scale
		if variant == "gray":
			return 2.35 * end_scale
		var end_stat := 2.10 * end_scale
		return end_stat
	var style := _wave_style_index()
	if enemy_id == "rouses":
		var rouses_bonus := float(style) * 0.16
		var rouses_progression_scale := 1.0 if style == 0 else 0.55
		return {"black": 2.25 + rouses_bonus, "gray": 1.68 + rouses_bonus * 0.65}.get(variant, 1.25 + rouses_bonus * 0.42) * rouses_progression_scale
	var tier_bonus := float(style) * 0.10
	var goblin_scale := 0.55 if enemy_id == "goblins" and style >= 3 else 1.0
	var werewolf_scale := 0.45 if enemy_id == "werewolves" and style >= 2 else 1.0
	var cave_troll_scale := 0.40 if enemy_id == "cave-trolls" and style >= 2 else 1.0
	var future_scale := 0.28 if enemy_id == "vampires" and style >= 2 else (0.30 if enemy_id == "dragons" and style >= 1 else 1.0)
	if variant == "black":
		return (1.62 + tier_bonus) * goblin_scale * werewolf_scale * cave_troll_scale * future_scale
	if variant == "gray":
		return (1.24 + tier_bonus * 0.65) * goblin_scale * werewolf_scale * cave_troll_scale * future_scale
	var white_stat := 1.0 + tier_bonus * 0.42
	return white_stat * goblin_scale * werewolf_scale * cave_troll_scale * future_scale


func _wave_damage_mult(variant: String) -> float:
	if end_wave_active:
		if enemy_id == "rouses":
			return {"black": 0.12, "gray": 0.10}.get(variant, 0.08)
		var end_scale := float({"guys": GUYS_END_WAVE_STAT_SCALE, "goblins": 0.08, "werewolves": 0.08, "cave-trolls": 0.15, "giants": 0.30, "vampires": 0.06, "dragons": 0.07}.get(enemy_id, 1.0))
		if variant == "black":
			return 5.20 * end_scale
		if variant == "gray":
			return 4.45 * end_scale
		var end_damage := 3.80 * end_scale
		return end_damage
	var style := _wave_style_index()
	if enemy_id == "rouses":
		var rouses_bonus := float(style) * 0.18
		var wave_scale := 1.00 if wave_index == 0 else 0.38
		return {"black": 1.85 + rouses_bonus, "gray": 1.45 + rouses_bonus * 0.65}.get(variant, 1.20 + rouses_bonus * 0.25) * wave_scale
	var tier_bonus := float(style) * 0.08
	var goblin_scale := 0.55 if enemy_id == "goblins" and style >= 3 else 1.0
	var werewolf_scale := 0.40 if enemy_id == "werewolves" and style >= 2 else 1.0
	var cave_troll_scale := 0.32 if enemy_id == "cave-trolls" and style >= 2 else 1.0
	var future_scale := 0.22 if enemy_id == "vampires" and style >= 2 else (0.22 if enemy_id == "dragons" and style >= 1 else 1.0)
	if variant == "black":
		return (1.52 + tier_bonus) * goblin_scale * werewolf_scale * cave_troll_scale * future_scale
	if variant == "gray":
		return (1.18 + tier_bonus * 0.65) * goblin_scale * werewolf_scale * cave_troll_scale * future_scale
	var white_damage := 1.0 + tier_bonus * 0.25
	if enemy_id == "goblins":
		return white_damage * (1.22 if style == 0 else 1.0) * goblin_scale
	if enemy_id == "guys" and style == 0:
		return white_damage * GUYS_OPENING_DAMAGE_SCALE
	return white_damage * werewolf_scale * cave_troll_scale * future_scale


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
	var interval := 0.70 if not end_wave_active else 0.42
	return maxf(0.08, interval * enemy_spawn_rhythm)


func _wave_spawn_total_for_wave() -> int:
	if end_wave_active:
		return maxi(1, enemy_final_population)
	if enemy_population_curve.is_empty():
		return MAX_CHICKENS
	return maxi(1, int(enemy_population_curve[clampi(_wave_style_index(), 0, enemy_population_curve.size() - 1)]))


func _wave_spawn_burst_count() -> int:
	if end_wave_active:
		return mini(2, enemy_population_cap)
	return 1 if enemy_population_cap <= 2 else mini(2, enemy_population_cap)


func _wave_uses_random_spawns() -> bool:
	return not end_wave_active and wave_index < NORMAL_WAVE_COUNT - 1


func _random_spawn_chance_per_roll() -> float:
	var random_rolls := maxf(1.0, floor(wave_spawn_phase_duration_current / RANDOM_SPAWN_ROLL_SECONDS) - 1.0)
	if enemy_id == "giants":
		var expected_spawns := float(enemy_population_curve[clampi(_wave_style_index(), 0, enemy_population_curve.size() - 1)])
		var guaranteed_spawns := floori(expected_spawns)
		if wave_spawned_count < guaranteed_spawns:
			return 1.0
		if wave_spawned_count >= ceili(expected_spawns):
			return 0.0
		return 1.0 - pow(1.0 - (expected_spawns - float(guaranteed_spawns)), 1.0 / random_rolls)
	var target_spawns := float(_wave_spawn_total_for_wave()) if enemy_id == "vampires" else maxf(2.0, float(_wave_spawn_total_for_wave()) * RANDOM_SPAWN_EXPECTED_SCALE)
	return clampf((target_spawns - 1.0) / random_rolls, 0.0, 1.0)


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
	var scheduled_duration := wave_start_delay_current + float(interval_count) * _spawn_interval_for_wave()
	return maxf(6.0 + float(_wave_style_index()) * 0.2, scheduled_duration)


func _wave_rest_duration_for_wave() -> float:
	if enemy_id == "vampires":
		return VAMPIRE_WAVE_REST_SECONDS
	match _wave_style_index():
		0:
			return 3.0
		1:
			return 2.8
		2:
			return 2.6
		3:
			return 2.4
		4:
			return 2.2
	return 2.6


func _wave_style_index() -> int:
	return clampi(wave_index, 0, NORMAL_WAVE_COUNT - 1)


func _movement_texture(chicken: Dictionary) -> Texture2D:
	if not INCLUDED_SCREEN_RIGHT.has(enemy_id) or float(chicken.get("hp", 0.0)) <= 0.0:
		return null
	var transform_timer := float(chicken.get("transform_timer", 0.0))
	if enemy_id == "werewolves" and transform_timer > 0.0:
		var transform_frames: Array = enemy_movement_frames.get("werewolves-transform", []) as Array
		if transform_frames.size() == 5:
			var progress := 1.0 - transform_timer / WEREWOLF_TRANSFORM_DURATION
			return transform_frames[clampi(int(floor(progress * 5.0)), 0, 4)] as Texture2D
	if enemy_id == "vampires" and transform_timer > 0.0:
		var giant_transform: Array = enemy_movement_frames.get("vampire-giant-transform", []) as Array
		if not giant_transform.is_empty():
			var progress := 1.0 - transform_timer / VAMPIRE_GIANT_TRANSFORM_DURATION
			var struggle_sequence := [0, 1, 0, 1, 2, 1, 2, 3]
			var sequence_index := clampi(int(floor(progress * struggle_sequence.size())), 0, struggle_sequence.size() - 1)
			return giant_transform[mini(struggle_sequence[sequence_index], giant_transform.size() - 1)] as Texture2D
	if not str(chicken.get("attack_phase", "")).is_empty() or float(chicken.get("hit_flash", 0.0)) > 0.0 or float(chicken.get("stagger_timer", 0.0)) > 0.0:
		return null
	var key := enemy_id
	var fps := MOVEMENT_FPS
	if enemy_id == "dragons" and not bool(chicken.get("dragon_is_walking", false)):
		return null
	if enemy_id == "vampires" and bool(chicken.get("vampire_giant_transformed", false)):
		key = "vampire-giant-walk"
		fps = 10.0
	elif enemy_id == "vampires" and float(chicken.get("vampire_walk_timer", 0.0)) <= 0.0:
		return null
	if enemy_id == "chicken-swarm":
		key = "chicken-swarm:%s" % str(chicken.get("variant", "white"))
	elif enemy_id == "giants":
		fps = GIANT_WALK_FPS
	elif enemy_id == "werewolves" and not bool(chicken.get("werewolf_transformed", false)):
		key = "guys"
	elif enemy_id == "guys" and float(chicken.get("punch_flee_timer", 0.0)) > 0.0:
		key = "guys-run"
		fps = GUYS_RUN_FPS
	var frames: Array = enemy_movement_frames.get(key, []) as Array
	if frames.size() < 4:
		return null
	var phase := float(int(chicken.get("id", 0))) * 0.37
	var index := int(floor((elapsed_seconds * fps + phase))) % frames.size()
	return frames[index] as Texture2D


func _chicken_texture(variant: String, state: String) -> Texture2D:
	if enemy_id == "chicken-swarm" and variant == "black":
		if state == "windup":
			return black_windup_chicken
		if state == "hit":
			return black_hit_chicken if black_hit_chicken != null else black_idle_chicken
		if state == "dizzy":
			return black_dizzy_chicken if black_dizzy_chicken != null else black_idle_chicken
		if state == "defeated":
			return black_defeated_chicken if black_defeated_chicken != null else black_idle_chicken
		return black_idle_chicken
	if enemy_id == "chicken-swarm" and variant == "gray":
		if state == "windup":
			return gray_windup_chicken
		if state == "hit":
			return gray_hit_chicken if gray_hit_chicken != null else gray_idle_chicken
		if state == "dizzy":
			return gray_dizzy_chicken if gray_dizzy_chicken != null else gray_idle_chicken
		if state == "defeated":
			return gray_defeated_chicken if gray_defeated_chicken != null else gray_idle_chicken
		return gray_idle_chicken
	if state == "windup":
		return windup_chicken if windup_chicken != null else idle_chicken
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
	_draw_wave_indicator(s)
	if active or arena_shape != "diamond":
		_draw_smoke_puffs(s)
		_draw_giant_boulders(s, false)
		_draw_dragon_breath_fire(s)
		_draw_actors(s)
		_draw_vampire_bats(s)
		_draw_vampire_shockwaves(s)
		_draw_giant_boulders(s, true)
		_draw_food_drops(s)
		_draw_feather_particles(s)
		_draw_effects(s)
		if hero_attack_timer > 0.0 and hero_ko_timer <= 0.0:
			_draw_hero_attack_flash(s)
	_draw_player_stat_hud(s)
	if hero_ko_timer > 0.0:
		_draw_punishment_overlay(s)
	if cover_open_amount < 0.995:
		_draw_inactive_cover(s)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_arena(s: float) -> void:
	var arena := _arena_rect(s)
	if arena_shape == "diamond":
		_draw_diamond_module_backplate(s)
		_draw_diamond_arena_floor(arena, s)
		return
	if arena_floor != null:
		_draw_rounded_texture_cover(arena_floor, arena, _stage_corner_radius(s), Color("#74bd57"), s)
	else:
		draw_round_rect(arena, _stage_corner_radius(s), Color("#74bd57"))
		for i in range(8):
			var y := arena.position.y + arena.size.y * (0.16 + float(i) * 0.10)
			draw_line(Vector2(arena.position.x + 10.0 * s, y), Vector2(arena.end.x - 10.0 * s, y), Color(0, 0, 0, 0.055), 3.0 * s, false)


func _draw_diamond_arena_floor(arena: Rect2, s: float) -> void:
	var points := _diamond_arena_points()
	var rounded_points := _rounded_diamond_points(points, 72.0 * s, 10)
	_draw_diamond_button_depth(rounded_points, s)
	if arena_floor != null:
		_draw_diamond_texture_cover(arena_floor, arena, rounded_points, Color("#74bd57"), s)
	else:
		draw_colored_polygon(rounded_points, Color("#74bd57"))
	_draw_diamond_front_and_depth_outline(rounded_points, s)
	_draw_diamond_depth_corner_connectors(rounded_points, _diamond_depth_offset(s), s)
	for i in range(8):
		var y := arena.position.y + arena.size.y * (0.18 + float(i) * 0.09)
		var half_width := _diamond_half_width_at_y(y, rounded_points)
		var center_x := arena.get_center().x
		draw_line(Vector2(center_x - half_width + 22.0 * s, y), Vector2(center_x + half_width - 22.0 * s, y), Color(0, 0, 0, 0.055), 3.0 * s, false)


func _draw_diamond_module_backplate(s: float) -> void:
	var rect := _diamond_stats_plate_draw_rect(s)
	draw_round_rect(rect, 16.0 * s, Color("#5f090d"))
	draw_round_outline(rect, 16.0 * s, INK, 8.0 * s)


func _diamond_stats_plate_rect(s: float) -> Rect2:
	var points := _diamond_arena_points()
	var left := points[3]
	var bottom := points[2]
	return Rect2(
		Vector2(left.x + 56.0 * s, left.y - 38.0 * s),
		Vector2(maxf(1.0, bottom.x - left.x - 56.0 * s), maxf(1.0, bottom.y - left.y - 4.0 * s))
	)


func _diamond_stats_plate_draw_rect(s: float) -> Rect2:
	var rect := _diamond_stats_plate_rect(s)
	if not diamond_stats_tucked:
		return rect
	return Rect2(rect.position + Vector2(rect.size.x * 0.31, -rect.size.y * 0.31), rect.size)


func _diamond_arena_points() -> PackedVector2Array:
	var s := _stage_scale()
	var inset := maxf(12.0 * s, 10.0)
	var side_inset := maxf(16.0 * s, 12.0)
	var center := size * 0.5
	return PackedVector2Array([
		Vector2(center.x, inset),
		Vector2(size.x - side_inset, center.y),
		Vector2(center.x, size.y - inset),
		Vector2(side_inset, center.y),
	])


func _draw_diamond_button_depth(points: PackedVector2Array, s: float) -> void:
	if points.size() < 4:
		return
	var offset := _diamond_depth_offset(s)
	var back := PackedVector2Array()
	for point in points:
		back.append(point + offset)
	_draw_diamond_prism_faces(points, back, offset, s)
	_draw_diamond_visible_depth_outline(back, s)


func _draw_diamond_prism_faces(front: PackedVector2Array, back: PackedVector2Array, offset: Vector2, s: float) -> void:
	var depth_color := _arena_depth_color_for_enemy(enemy_id)
	for i in range(front.size()):
		var next := (i + 1) % front.size()
		if not _diamond_depth_edge_visible(front[i], front[next], offset):
			continue
		draw_colored_polygon(PackedVector2Array([front[i], front[next], back[next], back[i]]), depth_color)


func _draw_diamond_depth_caps(front: PackedVector2Array, offset: Vector2, s: float) -> void:
	var bottom := _diamond_extreme_y_point(front, true) + offset
	_draw_ellipse(bottom, Vector2(26.0, 15.0) * s, _arena_depth_color_for_enemy(enemy_id))


func _draw_diamond_visible_back_outline(front: PackedVector2Array, back: PackedVector2Array, offset: Vector2, s: float) -> void:
	for i in range(front.size()):
		var next := (i + 1) % front.size()
		var normal := _diamond_edge_outward_normal(front[i], front[next])
		if normal.dot(offset) > 0.15:
			draw_line(back[i], back[next], INK, 8.0 * s, true)


func _draw_diamond_front_and_depth_outline(front: PackedVector2Array, s: float) -> void:
	var closed := PackedVector2Array(front)
	closed.append(front[0])
	draw_polyline(closed, INK, 8.0 * s, true)


func _draw_diamond_bottom_back_outline(front: PackedVector2Array, offset: Vector2, s: float) -> void:
	for i in range(front.size()):
		var next := (i + 1) % front.size()
		if not _diamond_depth_edge_visible(front[i], front[next], offset):
			continue
		draw_line(front[i] + offset, front[next] + offset, INK, 8.0 * s, true)


func _draw_diamond_visible_depth_outline(back: PackedVector2Array, s: float) -> void:
	if back.size() < 4:
		return
	var offset := _diamond_depth_offset(s)
	for i in range(back.size()):
		var next := (i + 1) % back.size()
		var front_start := back[i] - offset
		var front_finish := back[next] - offset
		if _diamond_depth_edge_visible(front_start, front_finish, offset):
			draw_line(back[i], back[next], INK, 8.0 * s, true)


func _diamond_lower_depth_path(points: PackedVector2Array, cutoff_y: float) -> PackedVector2Array:
	var path := PackedVector2Array()
	for i in range(points.size()):
		var current := points[i]
		var next := points[(i + 1) % points.size()]
		if current.y >= cutoff_y:
			path.append(current)
		if (current.y < cutoff_y and next.y >= cutoff_y) or (current.y >= cutoff_y and next.y < cutoff_y):
			var t := (cutoff_y - current.y) / (next.y - current.y)
			path.append(current.lerp(next, t))
	if path.size() > 1 and path[0].x > path[path.size() - 1].x:
		path.reverse()
	return path


func _draw_diamond_depth_corner_connectors(front: PackedVector2Array, offset: Vector2, s: float) -> void:
	for i in range(front.size()):
		var next := (i + 1) % front.size()
		var visible := _diamond_depth_edge_visible(front[i], front[next], offset)
		var previous := _diamond_depth_edge_visible(front[(i - 1 + front.size()) % front.size()], front[i], offset)
		if visible == previous:
			continue
		draw_line(front[i], front[i] + offset, INK, 8.0 * s, true)


func _diamond_depth_offset(_s: float) -> Vector2:
	return ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET * 2.0


func _diamond_extreme_x_point(points: PackedVector2Array, right_side: bool) -> Vector2:
	var best := points[0]
	for point in points:
		if (right_side and point.x > best.x) or (not right_side and point.x < best.x):
			best = point
	return best


func _diamond_extreme_y_point(points: PackedVector2Array, bottom_side: bool) -> Vector2:
	var best := points[0]
	for point in points:
		if (bottom_side and point.y > best.y) or (not bottom_side and point.y < best.y):
			best = point
	return best


func _diamond_extreme_depth_connector_point(points: PackedVector2Array, positive: bool) -> Vector2:
	var best := points[0]
	var best_score := best.x - best.y
	for point in points:
		var score := point.x - point.y
		if (positive and score > best_score) or (not positive and score < best_score):
			best = point
			best_score = score
	return best


func _rounded_diamond_points(points: PackedVector2Array, corner_radius: float, segments: int) -> PackedVector2Array:
	var rounded := PackedVector2Array()
	if points.size() < 4:
		return points
	var safe_segments := maxi(2, segments)
	for i in range(points.size()):
		var previous := points[(i - 1 + points.size()) % points.size()]
		var corner := points[i]
		var next := points[(i + 1) % points.size()]
		var effective_radius := corner_radius * (0.42 if i == 1 or i == 3 else 1.0)
		var cut := minf(effective_radius, minf(corner.distance_to(previous), corner.distance_to(next)) * 0.34)
		var start := corner.move_toward(previous, cut)
		var finish := corner.move_toward(next, cut)
		for step in range(safe_segments + 1):
			var t := float(step) / float(safe_segments)
			var a := start.lerp(corner, t)
			var b := corner.lerp(finish, t)
			rounded.append(a.lerp(b, t))
	return rounded


func _draw_diamond_depth_outlines(front: PackedVector2Array, back: PackedVector2Array, visible_edges: Array[bool], travel: Vector2, s: float) -> void:
	var width := 8.0 * s
	for i in range(front.size()):
		if not bool(visible_edges[i]):
			continue
		var next := (i + 1) % front.size()
		draw_line(back[i], back[next], INK, width, true)


func _diamond_edge_outward_normal(p0: Vector2, p1: Vector2) -> Vector2:
	var edge := p1 - p0
	if edge.length_squared() <= 0.001:
		return Vector2.ZERO
	return Vector2(edge.y, -edge.x).normalized()


func _diamond_depth_edge_visible(p0: Vector2, p1: Vector2, travel: Vector2) -> bool:
	var normal := _diamond_edge_outward_normal(p0, p1)
	return normal.dot(travel) > 0.15


func _diamond_side_face_visible(normal: Vector2, travel: Vector2) -> bool:
	if normal.length_squared() <= 0.001 or normal.dot(travel) <= 0.15:
		return false
	return normal.x > 0.08 or normal.y > 0.56


func _diamond_half_width_at_y(y: float, points: PackedVector2Array) -> float:
	if points.size() > 4:
		return _polygon_half_width_at_y(y, points)
	var top := points[0]
	var right := points[1]
	var bottom := points[2]
	var center_y := right.y
	var sharp := lerpf(0.0, right.x - top.x, clampf((y - top.y) / maxf(1.0, center_y - top.y), 0.0, 1.0)) if y <= center_y else lerpf(right.x - bottom.x, 0.0, clampf((y - center_y) / maxf(1.0, bottom.y - center_y), 0.0, 1.0))
	var r := maxf(20.0, 72.0 * _stage_scale())
	if y < top.y + r:
		var dy_top := y - (top.y + r)
		sharp = minf(sharp, sqrt(maxf(0.0, r * r - dy_top * dy_top)))
	elif y > bottom.y - r:
		var dy_bottom := y - (bottom.y - r)
		sharp = minf(sharp, sqrt(maxf(0.0, r * r - dy_bottom * dy_bottom)))
	if absf(y - center_y) < r:
		var dy_side := y - center_y
		var side_cap := right.x - top.x - (r - sqrt(maxf(0.0, r * r - dy_side * dy_side)))
		sharp = minf(sharp, side_cap)
	return sharp


func _polygon_half_width_at_y(y: float, points: PackedVector2Array) -> float:
	var intersections: Array[float] = []
	for i in range(points.size()):
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		if is_equal_approx(a.y, b.y):
			continue
		var min_y := minf(a.y, b.y)
		var max_y := maxf(a.y, b.y)
		if y < min_y or y >= max_y:
			continue
		var t := (y - a.y) / (b.y - a.y)
		intersections.append(lerpf(a.x, b.x, t))
	if intersections.size() < 2:
		return 0.0
	intersections.sort()
	return maxf(0.0, (float(intersections[intersections.size() - 1]) - float(intersections[0])) * 0.5)


func _clamp_stage_point_to_diamond(point: Vector2, margin: float) -> Vector2:
	var points := _diamond_arena_points()
	var top := points[0]
	var bottom := points[2]
	var clamped_y := clampf(point.y, top.y + margin, bottom.y - margin)
	var half_width := maxf(1.0, _diamond_half_width_at_y(clamped_y, points) - margin)
	var center_x := size.x * 0.5
	return Vector2(clampf(point.x, center_x - half_width, center_x + half_width), clamped_y)


func _module_shake_offset(s: float) -> Vector2:
	if module_shake_timer <= 0.0 or module_shake_duration <= 0.0:
		return Vector2.ZERO
	var t := clampf(module_shake_timer / module_shake_duration, 0.0, 1.0)
	var strength := module_shake_strength * t * t
	return Vector2(
		sin(elapsed_seconds * 117.0) * strength,
		cos(elapsed_seconds * 91.0) * strength * 0.62
	)


func _draw_wave_indicator(s: float) -> void:
	if not active or hero_ko_timer > 0.0:
		return
	var arena := _arena_rect(s)
	var progress := clampf(displayed_wave_progress, 0.0, 1.0)
	var fill_color := _wave_indicator_color(progress)
	var label := "Cleared" if area_clear_restart_timer > 0.0 else ("End Wave" if end_wave_active else "Wave %d" % (wave_index + 1))
	if arena_shape == "diamond":
		_draw_diamond_wave_indicator(progress, fill_color, label, s)
		return
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


func _draw_diamond_wave_indicator(progress: float, fill_color: Color, label: String, s: float) -> void:
	var points := _diamond_arena_points()
	var top := points[0]
	var left := points[3]
	var edge := top - left
	if edge.length_squared() <= 1.0:
		return
	var direction := edge.normalized()
	var inward := direction.rotated(PI * 0.5)
	var angle := direction.angle()
	var rail_center := left.lerp(top, 0.44) - inward * 30.0 * s
	var rail_size := Vector2(clampf(edge.length() * 0.48, 160.0 * s, 236.0 * s), 28.0 * s)
	var radius := rail_size.y * 0.5
	draw_set_transform(rail_center, angle, Vector2.ONE)
	var rail := Rect2(-rail_size * 0.5, rail_size)
	draw_round_rect(Rect2(rail.position + Vector2(0.0, 4.0 * s), rail.size), radius, Color(0, 0, 0, 0.28))
	draw_round_rect(rail, radius, Color("#211411", 0.94))
	var fill := Rect2(rail.position, Vector2(rail.size.x * clampf(progress, 0.0, 1.0), rail.size.y))
	if fill.size.x > 0.5:
		draw_round_rect(fill, radius, fill_color)
	draw_round_outline(rail, radius, INK, maxf(5.0, 7.0 * s))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_centered_fit_text_rotated(label, rail_center - inward * 48.0 * s, rail_size.x * 1.24, int(clampf(50.0 * s, 40.0, 58.0)), WHITE, int(maxf(10.0, 14.0 * s)), INK, angle, 1.0)


func _draw_player_stat_hud(s: float) -> void:
	if not active or hero_ko_timer > 0.0:
		return
	if arena_shape == "diamond" and diamond_stats_tucked:
		return
	var arena := _arena_rect(s)
	var font := get_theme_default_font()
	if font == null:
		return
	var text_size := int(clampf(arena.size.y * (0.188 if arena_shape == "diamond" else 0.148), 34.0, 57.0))
	var values := [
		"HP %d" % int(round(hero_hp)),
		"DMG %s" % _hero_attack_damage_range_text(),
		"SPD %.2f/s" % (1.0 / maxf(0.01, _hero_attack_interval()))
	] if arena_shape == "diamond" else [
		"DMG %s" % _hero_attack_damage_range_text(),
		"SPD %.2f/s" % (1.0 / maxf(0.01, _hero_attack_interval())),
		"HP %d" % int(round(hero_hp))
	]
	var stats_plate := _diamond_stats_plate_rect(s) if arena_shape == "diamond" else Rect2()
	var left_x := stats_plate.position.x + 18.0 * s if arena_shape == "diamond" else arena.position.x + clampf(arena.size.x * 0.052, 36.0, 54.0)
	var row_gap := clampf(arena.size.y * 0.165, 48.0, 58.0) if arena_shape == "diamond" else clampf(arena.size.y * 0.150, 36.0, 46.0)
	var bottom_pad := 34.0 * s if arena_shape == "diamond" else clampf(arena.size.y * 0.108, 26.0, 36.0)
	var top_y := stats_plate.end.y - bottom_pad - row_gap * 2.0 if arena_shape == "diamond" else arena.end.y - bottom_pad - row_gap * 2.0
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
	for effect in active_effects:
		effect["life"] = float(effect.get("life", 0.0)) - delta
	active_effects = active_effects.filter(func(item: Dictionary) -> bool:
		return float(item.get("life", 0.0)) > 0.0
	)


func _queue_effect(effect_name: String, norm_pos: Vector2, direction: Vector2) -> void:
	var frames: Array = effect_frames.get(effect_name, []) as Array
	if frames.size() < 4 or frames[0] == null:
		return
	var life := 1.24 if effect_name == "dragon-breath-fire-tuft" else 0.34
	active_effects.append({"name": effect_name, "pos": norm_pos, "direction": direction, "life": life, "max_life": life, "wiggle_phase": norm_pos.x * 29.0 + norm_pos.y * 43.0})
	if active_effects.size() > 24:
		active_effects = active_effects.slice(active_effects.size() - 24, active_effects.size())


func _draw_effects(s: float) -> void:
	for effect in active_effects:
		if str(effect.get("name", "")) != "dragon-breath-fire-tuft":
			_draw_effect_item(effect, s)


func _draw_dragon_breath_fire(s: float) -> void:
	for effect in active_effects:
		if str(effect.get("name", "")) == "dragon-breath-fire-tuft":
			_draw_effect_item(effect, s, 1.12, Color.BLACK)
	for index in range(active_effects.size() - 1, -1, -1):
		var effect := active_effects[index]
		if str(effect.get("name", "")) == "dragon-breath-fire-tuft":
			_draw_effect_item(effect, s)


func _draw_effect_item(effect: Dictionary, s: float, size_scale := 1.0, modulate := Color.WHITE) -> void:
	var effect_name := str(effect.get("name", ""))
	var frames: Array = effect_frames.get(effect_name, []) as Array
	if frames.size() < 4:
		return
	var direction := effect.get("direction", Vector2.ZERO) as Vector2
	var layout := _effect_layout(effect_name, direction)
	var life := float(effect.get("life", 0.0))
	var max_life := float(effect.get("max_life", 0.34))
	var frame := clampi(int(floor((1.0 - life / max_life) * 4.0)), 0, 3)
	var center: Vector2 = _norm_to_stage(effect.get("pos", Vector2.ZERO) as Vector2) + (layout.get("offset", Vector2.ZERO) as Vector2) * s
	var rotation := float(layout.get("rotation", 0.0))
	if effect_name == "dragon-breath-fire-tuft":
		var wiggle := sin(elapsed_seconds * 17.0 + float(effect.get("wiggle_phase", 0.0)))
		var travel := direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
		center += Vector2(-travel.y, travel.x) * wiggle * 4.0 * s
		rotation += wiggle * 0.055
	var fade_seconds := 0.18 if effect_name == "dragon-breath-fire-tuft" else (0.04 if effect_name == "wolf-claw-tear" else 0.34)
	var alpha := clampf(life / fade_seconds, 0.0, 1.0)
	_draw_character_texture(frames[frame] as Texture2D, center, layout.get("size", Vector2(96.0, 96.0)) * s * size_scale, rotation, alpha, bool(layout.get("flip", false)), false, modulate)


func _effect_layout(effect_name: String, direction: Vector2) -> Dictionary:
	var travel := direction.normalized() if direction.length() > 0.001 else Vector2.RIGHT
	match effect_name:
		"hit-impact-yellow":
			return {"size": Vector2(56.0, 56.0), "offset": Vector2(0.0, -34.0), "flip": false}
		"dizzy-stars":
			return {"size": Vector2(116.0, 116.0), "offset": Vector2(0.0, -122.0), "flip": false}
		"dragon-breath-flame":
			var flip := travel.x < -0.001
			var rotation := travel.angle() if not flip else (-travel).angle()
			return {"size": Vector2(240.0, 120.0), "offset": travel * 120.0 + Vector2(0.0, -54.0), "flip": flip, "rotation": rotation}
		"dragon-breath-fire-tuft":
			var flip := travel.x < -0.001
			var rotation := travel.angle() if not flip else (-travel).angle()
			return {"size": Vector2(132.0, 104.0), "offset": Vector2.ZERO, "flip": flip, "rotation": rotation}
		"cave-troll-slam":
			return {"size": Vector2(240.0, 120.0), "offset": travel * 100.0 + Vector2(0.0, 24.0), "flip": false}
		"dragon-pounce-shockwave":
			return {"size": Vector2(154.0, 72.0), "offset": travel * 34.0 + Vector2(0.0, 22.0), "flip": false}
		"wolf-claw-tear":
			return {"size": Vector2(154.0, 154.0), "offset": Vector2(0.0, -58.0), "flip": false}
	return {"size": Vector2(96.0, 96.0), "offset": Vector2.ZERO, "flip": false}


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


func _spawn_smoke_puffs(norm_pos: Vector2, lunge_dir: Vector2, teleport := false) -> void:
	var base := _norm_to_stage(norm_pos) + Vector2(0.0, 12.0 if teleport else 58.0) * _stage_scale()
	var s := _stage_scale()
	var back_dir := -lunge_dir.normalized() if lunge_dir.length() > 0.001 else Vector2.LEFT
	for i in range(10 if teleport else 4):
		smoke_puffs.append({
			"pos": base + Vector2(randf_range(-32.0, 32.0), randf_range(-82.0, 28.0) if teleport else randf_range(-4.0, 8.0)) * s,
			"vel": (back_dir * randf_range(18.0, 46.0) + Vector2(randf_range(-24.0, 24.0), randf_range(-38.0, -8.0))) * s,
			"life": randf_range(0.38, 0.62) if teleport else randf_range(0.24, 0.42),
			"max_life": 0.62 if teleport else 0.42,
			"radius": randf_range(16.0, 25.0) * s if teleport else randf_range(8.0, 14.0) * s,
			"teleport": teleport,
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
		var teleport := bool(puff.get("teleport", false))
		var alpha := (1.0 - t) * (0.58 if teleport else 0.24)
		var pos := puff.get("pos", Vector2.ZERO) as Vector2
		var radius := float(puff.get("radius", 10.0))
		var color := Color(0.32, 0.25, 0.40, alpha) if teleport else Color(0.72, 0.65, 0.54, alpha)
		_draw_ellipse(pos, Vector2(radius * (1.35 + t * 0.45), radius * (0.62 + t * 0.25)), color)


func _draw_feather_particles(s: float) -> void:
	for feather in feather_particles:
		var life := float(feather.get("life", 0.0))
		var max_life := maxf(0.01, float(feather.get("max_life", 0.6)))
		var alpha := clampf(life / max_life, 0.0, 1.0)
		var pos := feather.get("pos", Vector2.ZERO) as Vector2
		var size_px := float(feather.get("size", 9.0))
		var spin := float(feather.get("spin", 0.0))
		var stone := str(feather.get("kind", "")) == "stone"
		var color := feather.get("color", Color("#fff3cf")) as Color
		color.a = alpha * 0.92
		var right := Vector2(cos(spin), sin(spin))
		var up := Vector2(-right.y, right.x)
		var points := PackedVector2Array([
			pos + right * size_px,
			pos + up * size_px * (0.58 if stone else 0.34),
			pos - right * size_px * (0.62 if stone else 0.78),
			pos - up * size_px * (0.48 if stone else 0.34)
		])
		draw_colored_polygon(points, color)
		var outline := Color(0.10, 0.09, 0.08, alpha * (0.82 if stone else 0.18))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline, maxf(1.0, (3.0 if stone else 1.5) * s), true)


func _wave_indicator_progress() -> float:
	return clampf(wave_elapsed_current / maxf(0.01, wave_duration_current), 0.0, 1.0)


func _wave_indicator_color(_progress: float) -> Color:
	if area_clear_restart_timer > 0.0:
		return REWARD_GREEN
	if end_wave_active:
		return ACTIVE_WAVE_BLUE
	return Color("#38e57e") if wave_elapsed_current >= wave_spawn_phase_duration_current else ACTIVE_WAVE_BLUE


func _draw_vampire_bats(s: float) -> void:
	if enemy_id != "vampires" or vampire_bat_textures.size() < 2:
		return
	for bat in vampire_bats:
		var pos := bat.get("pos", Vector2.ZERO) as Vector2
		var frame := int(floor(elapsed_seconds * 8.0 + float(bat.get("flap_phase", 0.0)))) % 2
		var depth_scale := 0.88 + pos.y * 0.20
		var buff_scale := float(bat.get("buff_scale", 1.0))
		var buff_count := int(bat.get("buff_count", 0))
		var draw_pos := _norm_to_stage(pos) + Vector2(0.0, -54.0) * s * depth_scale
		if buff_count > 0:
			var glow_alpha := minf(0.56, 0.16 + float(buff_count) * 0.10)
			draw_circle(draw_pos, 50.0 * s * depth_scale * buff_scale, Color(0.58, 0.12, 0.90, glow_alpha))
			draw_circle(draw_pos, 35.0 * s * depth_scale * buff_scale, Color(0.82, 0.46, 1.0, glow_alpha * 0.82))
		_draw_character_texture(
			vampire_bat_textures[frame],
			draw_pos,
			Vector2(120.0, 84.0) * s * depth_scale * buff_scale,
			0.0,
			1.0,
			not bool(bat.get("facing_right", true)),
			false
		)


func _draw_vampire_shockwaves(s: float) -> void:
	for shockwave in vampire_shockwaves:
		var radius := float(shockwave.get("radius", 0.0))
		var progress := clampf(radius / VAMPIRE_SHOCKWAVE_MAX_RADIUS, 0.0, 1.0)
		var center := _norm_to_stage(shockwave.get("origin", Vector2.ZERO) as Vector2)
		var alpha := (1.0 - progress) * 0.78
		draw_arc(center, radius * s, 0.0, TAU, 72, Color(0.62, 0.20, 0.88, alpha), maxf(4.0, 11.0 * s), true)
		draw_arc(center, maxf(1.0, radius - 13.0) * s, 0.0, TAU, 72, Color(0.86, 0.60, 1.0, alpha * 0.62), maxf(2.0, 4.0 * s), true)


func _draw_giant_boulders(s: float, airborne: bool) -> void:
	if enemy_id != "giants" or giant_boulder_textures.is_empty():
		return
	for boulder in giant_boulders:
		var state := str(boulder.get("state", "ground"))
		if state not in ["ground", "reserved", "held", "flying"]:
			continue
		if airborne != (state in ["held", "flying"]):
			continue
		var texture_index := clampi(int(boulder.get("texture_index", 0)), 0, giant_boulder_textures.size() - 1)
		var texture := giant_boulder_textures[texture_index]
		var pos := boulder.get("pos", Vector2.ZERO) as Vector2
		var center := _norm_to_stage(pos)
		var rotation := float(boulder.get("rotation", 0.0))
		var draw_size := Vector2(150.0, 150.0) * s
		if state in ["ground", "reserved"]:
			var depth_scale := 0.82 + pos.y * 0.28
			draw_size *= depth_scale
			var content := _texture_content_rect(texture, draw_size)
			center = Vector2(center.x, center.y - content.end.y)
			rotation = 0.0
			_draw_ellipse(_norm_to_stage(pos) - Vector2(0.0, 3.0) * s, Vector2(44.0, 11.0) * s * depth_scale, Color(0, 0, 0, 0.18))
		elif state == "held":
			var owner := _giant_boulder_owner(int(boulder.get("owner_id", -1)))
			if owner.is_empty():
				continue
			var face := 1.0 if bool(owner.get("face_right", true)) else -1.0
			var lift_t := 1.0
			if str(owner.get("attack_phase", "")) == "windup":
				lift_t = _smooth01(clampf(float(owner.get("signature_t", 0.0)) * 1.45, 0.0, 1.0))
			center = _held_giant_boulder_center(boulder)
			rotation = lerpf(rotation, -0.18 * face, lift_t)
		elif state == "flying":
			var flight_t := clampf(float(boulder.get("timer", 0.0)) / GIANT_BOULDER_THROW_DURATION, 0.0, 1.0)
			var launch_lift := 120.0 * (1.0 - _smooth01(flight_t))
			center += Vector2(0.0, -launch_lift - 72.0 * sin(flight_t * PI)) * s
			var landing_pos := boulder.get("target", pos) as Vector2
			_draw_ellipse(_norm_to_stage(landing_pos) - Vector2(0.0, 3.0) * s, Vector2(44.0, 11.0) * s, Color(0, 0, 0, 0.08 + flight_t * 0.10))
		_draw_character_texture(texture, center, draw_size, rotation, 1.0, false, false)


func _giant_boulder_owner(owner_id: int) -> Dictionary:
	for chicken in chickens:
		if int(chicken.get("id", -1)) == owner_id and float(chicken.get("hp", 0.0)) > 0.0:
			return chicken
	return {}


func _draw_actors(s: float) -> void:
	var draw_order := chickens.duplicate()
	draw_order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a.get("render_pos", a.get("pos", Vector2.ZERO)) as Vector2).y < (b.get("render_pos", b.get("pos", Vector2.ZERO)) as Vector2).y
	)
	var hero_stage := _norm_to_stage(hero_pos)
	if enemy_id == "dragons":
		_draw_hero(hero_stage, s)
		for chicken in draw_order:
			_draw_chicken(chicken, s)
		return
	var hero_inserted := false
	for chicken in draw_order:
		var chicken_y := (chicken.get("render_pos", chicken.get("pos", Vector2.ZERO)) as Vector2).y
		if not hero_inserted and hero_pos.y < chicken_y:
			_draw_hero(hero_stage, s)
			hero_inserted = true
		_draw_chicken(chicken, s)
	if not hero_inserted:
		_draw_hero(hero_stage, s)


func _draw_hero(center: Vector2, s: float) -> void:
	if arena_shape == "diamond":
		center = _clamp_stage_point_to_diamond(center, 92.0 * s)
	var ko := hero_ko_timer > 0.0
	var attack_duration := 0.34 if hero_attack_is_uppercut else 0.24
	var pulse := clampf(hero_attack_timer / attack_duration, 0.0, 1.0)
	var idle_bob := 0.0
	if hero_bump_timer > 0.0:
		var bump_elapsed := GIANT_STOMP_BUMP_DURATION - hero_bump_timer
		idle_bob = -GIANT_STOMP_BUMP_HEIGHT * sin(clampf(bump_elapsed / GIANT_STOMP_BUMP_DURATION, 0.0, 1.0) * PI) * s
	if ko:
		_draw_ko_hero(center, s)
	elif hero_toss_timer > 0.0:
		_draw_tossed_hero(center, s)
	else:
		var is_striking := pulse > 0.20
		var texture := blue_guy_guard
		if is_striking:
			texture = blue_guy_uppercut if hero_attack_is_uppercut and blue_guy_uppercut != null else blue_guy_punch
		var lunge := hero_attack_dir * (pulse * (48.0 if hero_attack_is_uppercut else 32.0) * s)
		var rise := Vector2(0.0, -28.0 * sin(pulse * PI)) * s if hero_attack_is_uppercut else Vector2.ZERO
		var rotation := 0.08 * float(hero_facing) * pulse if hero_attack_is_uppercut else 0.02 * float(hero_facing) * pulse
		rotation += sin(elapsed_seconds * 4.2) * 0.012 * (1.0 - pulse)
		var diamond_scale := DIAMOND_HERO_DRAW_SCALE if arena_shape == "diamond" else 1.0
		var purple_buff_active := hero_purple_buff_punches > 0 or (hero_attack_purple_buffed and hero_attack_timer > 0.0)
		var purple_buff_scale := 1.20 if purple_buff_active else 1.0
		var guard_draw_size := Vector2(198, 198) * s * diamond_scale * purple_buff_scale
		var hero_draw_size := (Vector2(270, 270) if hero_attack_is_uppercut and is_striking else (Vector2(212, 212) if is_striking else Vector2(198, 198))) * s * diamond_scale * purple_buff_scale
		var guard_content := _texture_content_rect(blue_guy_guard, guard_draw_size)
		var hero_content := _texture_content_rect(texture, hero_draw_size)
		var foot_line_y := center.y - 12.0 * s + guard_content.end.y
		var hero_sprite_center := Vector2(center.x + lunge.x, foot_line_y - hero_content.end.y + idle_bob + lunge.y * 0.22 + rise.y)
		var shadow_center := center + Vector2(-10, 42) * s
		if purple_buff_active:
			var glow_alpha := 0.38 + sin(elapsed_seconds * 5.0) * 0.07
			draw_circle(hero_sprite_center, 94.0 * s * diamond_scale, Color(0.57, 0.13, 0.88, glow_alpha))
			draw_circle(hero_sprite_center, 70.0 * s * diamond_scale, Color(0.82, 0.48, 1.0, glow_alpha * 0.82))
		_draw_ellipse(shadow_center, Vector2(92, 23) * s, Color(0, 0, 0, 0.055))
		_draw_ellipse(shadow_center, Vector2(78, 19) * s, Color(0, 0, 0, 0.075))
		_draw_ellipse(shadow_center, Vector2(62, 15) * s, Color(0, 0, 0, 0.095))
		_draw_character_texture(texture, hero_sprite_center, hero_draw_size, rotation, 1.0, hero_facing < 0, true)
	if not ko:
		var hero_health_offset := Vector2(0, -86) * s if arena_shape == "diamond" else Vector2(0, -118) * s
		var hero_health_width := 94.0 * s if arena_shape == "diamond" else 132.0 * s
		_draw_local_health(center + hero_health_offset, hero_health_width, hero_hp / _hero_max_hp(), HERO_HP_BLUE, s)


func _draw_tossed_hero(center: Vector2, s: float) -> void:
	var elapsed := GIANT_TOSS_DURATION - hero_toss_timer
	var bounce := _enemy_death_bounce_pose(elapsed, hero_facing > 0, 1.0, hero_toss_direction)
	var stand_t := _smooth01(clampf((elapsed - GIANT_TOSS_STAND_START) / (GIANT_TOSS_DURATION - GIANT_TOSS_STAND_START), 0.0, 1.0))
	var draw_scale := DIAMOND_HERO_DRAW_SCALE if arena_shape == "diamond" else 1.0
	var guard_size := Vector2(198, 198) * s * draw_scale
	var knocked_size := guard_size * 1.55
	var ground_line_y := center.y - 12.0 * s + _texture_content_rect(blue_guy_guard, guard_size).end.y
	var knocked_center := Vector2(center.x, ground_line_y - _texture_content_rect(blue_guy_ko, knocked_size).end.y + bounce.x * s)
	var standing_center := Vector2(center.x, ground_line_y - _texture_content_rect(blue_guy_guard, guard_size).end.y)
	_draw_ellipse(Vector2(center.x + 5.0 * s, ground_line_y + 2.0 * s), Vector2(74, 17) * s * draw_scale, Color(0, 0, 0, 0.16))
	_draw_character_texture(blue_guy_ko, knocked_center, knocked_size, bounce.y, 1.0 - stand_t, hero_facing < 0, false)
	if stand_t > 0.0:
		_draw_character_texture(blue_guy_guard, standing_center, guard_size, 0.0, stand_t, hero_facing < 0, true)


func _draw_ko_hero(center: Vector2, s: float) -> void:
	var draw_scale := DIAMOND_HERO_DRAW_SCALE if arena_shape == "diamond" else 1.0
	var elapsed_ko := HERO_KO_DURATION - hero_ko_timer
	var stand_t := _smooth01(clampf((HERO_KO_STAND_SECONDS - hero_ko_timer) / HERO_KO_STAND_SECONDS, 0.0, 1.0))
	var recovering := hero_ko_timer < HERO_KO_STAND_SECONDS
	var ko_texture := _blue_guy_ko_frame(elapsed_ko)
	var down_alpha := 1.0 - stand_t if recovering else 1.0
	var standing_alpha := stand_t if recovering else 0.0
	var guard_draw_size := Vector2(198, 198) * s * draw_scale
	var guard_content := _texture_content_rect(blue_guy_guard, guard_draw_size)
	var ground_line_y := center.y - 12.0 * s + guard_content.end.y
	var ko_draw_size := Vector2(430, 430) * s * draw_scale
	var ko_content := _texture_content_rect(ko_texture, ko_draw_size)
	var ko_center := Vector2(center.x, ground_line_y - ko_content.end.y)
	var stand_center := Vector2(center.x, ground_line_y - guard_content.end.y)
	_draw_ellipse(Vector2(center.x + 5.0 * s, ground_line_y + 2.0 * s), Vector2(74, 17) * s * draw_scale, Color(0, 0, 0, 0.16))
	if down_alpha > 0.02:
		_draw_character_texture(ko_texture, ko_center, ko_draw_size, 0.0, down_alpha, hero_facing < 0, false)
	if standing_alpha > 0.02:
		_draw_character_texture(blue_guy_guard, stand_center, guard_draw_size, 0.0, standing_alpha, hero_facing < 0, true)


func _blue_guy_ko_frame(elapsed_ko: float) -> Texture2D:
	if blue_guy_ko_frames.is_empty():
		return blue_guy_ko
	var progress := clampf(elapsed_ko / HERO_KO_FALL_SECONDS, 0.0, 1.0)
	var frame_index := clampi(int(floor(progress * blue_guy_ko_frames.size())), 0, blue_guy_ko_frames.size() - 1)
	return blue_guy_ko_frames[frame_index]


func _draw_chicken(chicken: Dictionary, s: float) -> void:
	var pos := chicken.get("render_pos", chicken.get("pos", Vector2.ZERO)) as Vector2 if is_processing() else chicken.get("pos", Vector2.ZERO) as Vector2
	if arena_shape == "diamond" and not _diamond_contains_norm(pos):
		return
	var hp := float(chicken.get("hp", 0.0))
	var max_hp := maxf(1.0, float(chicken.get("max_hp", CHICKEN_BASE_HP_MAX)))
	var hit_flash := float(chicken.get("hit_flash", 0.0))
	var uppercut_pop := float(chicken.get("uppercut_pop", 0.0))
	var knock_timer := float(chicken.get("uppercut_knock_timer", 0.0))
	var knock_duration := maxf(0.01, float(chicken.get("uppercut_knock_duration", CHICKEN_UPPERCUT_KNOCK_SECONDS)))
	var dead := hp <= 0.0
	var lunge_timer := float(chicken.get("lunge_timer", 0.0))
	var attack_phase := str(chicken.get("attack_phase", ""))
	var signature_t := float(chicken.get("signature_t", 0.0))
	var variant := str(chicken.get("variant", "white"))
	var texture := _chicken_texture(variant, "idle")
	var vampire_giant := enemy_id == "vampires" and bool(chicken.get("vampire_giant_transformed", false))
	if dead:
		if vampire_giant:
			var giant_walk: Array = enemy_movement_frames.get("vampire-giant-walk", []) as Array
			texture = giant_walk[0] as Texture2D if not giant_walk.is_empty() else texture
		else:
			texture = _chicken_texture(variant, "defeated")
	elif (enemy_id == "werewolves" or vampire_giant) and float(chicken.get("transform_timer", 0.0)) > 0.0:
		texture = _movement_texture(chicken)
	elif vampire_giant:
		var giant_walk_texture := _movement_texture(chicken)
		var giant_walk: Array = enemy_movement_frames.get("vampire-giant-walk", []) as Array
		texture = giant_walk_texture if giant_walk_texture != null else (giant_walk[0] as Texture2D if not giant_walk.is_empty() else texture)
	elif attack_phase == "stagger" or float(chicken.get("stagger_timer", 0.0)) > 0.0:
		texture = _chicken_texture(variant, "dizzy")
	elif hit_flash > 0.0:
		texture = _chicken_texture(variant, "hit")
	elif enemy_id == "chicken-swarm" and attack_phase == "windup":
		texture = _chicken_texture(variant, "windup")
	else:
		var movement_texture := _movement_texture(chicken)
		if movement_texture != null:
			texture = movement_texture
	var attack_texture := _enemy_attack_texture(chicken)
	if attack_texture != null and not dead and attack_phase != "stagger" and float(chicken.get("stagger_timer", 0.0)) <= 0.0 and hit_flash <= 0.0 and knock_timer <= 0.0 and uppercut_pop <= 0.0:
		texture = attack_texture
	var actor_sprite_scale := enemy_sprite_scale
	if enemy_id == "werewolves":
		var guy_scale := _enemy_sprite_scale_for_id("guys")
		actor_sprite_scale = lerpf(guy_scale, enemy_sprite_scale, 1.0 - float(chicken.get("transform_timer", 0.0)) / WEREWOLF_TRANSFORM_DURATION) if bool(chicken.get("werewolf_transformed", false)) else guy_scale
	if vampire_giant:
		var transform_progress := 1.0 - clampf(float(chicken.get("transform_timer", 0.0)) / VAMPIRE_GIANT_TRANSFORM_DURATION, 0.0, 1.0)
		actor_sprite_scale *= lerpf(1.0, VAMPIRE_GIANT_SIZE_MULT, transform_progress)
		actor_sprite_scale *= 1.0 + float(chicken.get("vampire_giant_buff_count", 0)) * VAMPIRE_GIANT_BUFF_SCALE_STEP
	var scale := (0.82 + pos.y * 0.34) * (DIAMOND_ENEMY_DRAW_SCALE if arena_shape == "diamond" else 1.0) * actor_sprite_scale
	var center := _norm_to_stage(pos) - Vector2(0, 64) * s * scale
	var lunge_dir := chicken.get("lunge_dir", Vector2.ZERO) as Vector2
	var id_phase := float(int(chicken.get("id", 0))) * 1.71
	var ko_wiggle_scale := KO_RETREAT_WIGGLE_SCALE if hero_ko_timer > 0.0 else 1.0
	var teleporting := enemy_id == "vampires" and not str(chicken.get("vampire_teleport_phase", "")).is_empty()
	var hop := 0.0 if not active or dead or teleporting else sin(elapsed_seconds * 7.0 + id_phase) * 4.0 * s * ko_wiggle_scale
	var lunge_alpha := 0.0 if dead else sin(clampf((lunge_timer / 0.42) * PI, 0.0, PI))
	center += lunge_dir * lunge_alpha * 38.0 * s
	var idle_wobble := 0.0 if not active or dead else sin(elapsed_seconds * 4.4 + id_phase) * 2.0 * s * ko_wiggle_scale
	center += Vector2(idle_wobble, hop)
	if vampire_giant and float(chicken.get("transform_timer", 0.0)) > 0.0:
		center += Vector2(sin(elapsed_seconds * 39.0 + id_phase), cos(elapsed_seconds * 31.0 + id_phase)) * 7.0 * s
	if hit_flash > 0.0 and not dead:
		center += Vector2(sin(elapsed_seconds * 48.0 + id_phase) * 7.0 * s, 0.0)
	var ground_center := center
	var arc_lift := 0.0
	var death_rotation := 0.0
	if dead:
		var knock_dir := chicken.get("uppercut_knock_dir", Vector2.RIGHT) as Vector2
		var stage_knock_dir := _norm_to_stage(pos + knock_dir) - _norm_to_stage(pos)
		var death_pose := _enemy_death_bounce_pose(
			float(chicken.get("dead_timer", 0.0)),
			bool(chicken.get("face_right", pos.x < hero_pos.x)),
			float(chicken.get("death_bounce_scale", 1.0 / 3.0)),
			stage_knock_dir
		)
		arc_lift = death_pose.x
		death_rotation = death_pose.y
	elif knock_timer > 0.0:
		var arc_t := 1.0 - clampf(knock_timer / knock_duration, 0.0, 1.0)
		arc_lift = -92.0 * sin(arc_t * PI)
	elif uppercut_pop > 0.0:
		var pop_t := clampf(uppercut_pop / 0.36, 0.0, 1.0)
		arc_lift = -46.0 * sin(pop_t * PI)
	center += Vector2(0.0, arc_lift) * s
	var face_right := bool(chicken.get("face_right", pos.x < hero_pos.x))
	var dead_timer := float(chicken.get("dead_timer", 0.0))
	var alpha := (1.0 - clampf((dead_timer - ENEMY_DEATH_FADE_DELAY) / ENEMY_DEATH_FADE_SECONDS, 0.0, 1.0) if dead else 1.0) * clampf(float(chicken.get("ko_retreat_alpha", 1.0)), 0.0, 1.0)
	var lunge_scale := 1.0 if enemy_id in ["cave-trolls", "giants", "vampires", "dragons"] else 1.0 + lunge_alpha * 0.06
	var state_scale := 1.0
	var knock_rotation := 0.0
	if knock_timer > 0.0 and not dead:
		var knock_t := 1.0 - clampf(knock_timer / knock_duration, 0.0, 1.0)
		knock_rotation = sin(knock_t * PI) * 0.22 * (-1.0 if face_right else 1.0)
	if enemy_id == "giants":
		state_scale *= 1.52
	if enemy_id == "dragons":
		state_scale *= 1.30
	if attack_phase == "windup":
		state_scale *= 1.0 + sin(signature_t * PI) * 0.06
	if not dead and enemy_id == "rouses" and attack_phase == "strike":
		state_scale *= 0.78
	if dead:
		state_scale *= _enemy_death_scale_for_id(enemy_id)
	elif knock_timer > 0.0 or uppercut_pop > 0.0:
		state_scale = 1.20
	elif hit_flash > 0.0 or lunge_timer > 0.0:
		state_scale = 1.08
	if enemy_id == "chicken-swarm" and not dead:
		state_scale *= 1.15
	state_scale = _enemy_transient_sprite_scale(state_scale)
	var shadow_scale := _enemy_shadow_scale_for_id(enemy_id)
	var target_size := Vector2(172, 156) * s * scale * lunge_scale * state_scale
	var shadow_center := ground_center + Vector2(0, 64) * s * scale
	var shadow_radii := Vector2(58, 17) * s * scale * shadow_scale
	if enemy_id in ["cave-trolls", "giants", "vampires", "dragons"] and not dead:
		if enemy_id == "giants":
			target_size *= _giant_head_scale(texture)
		elif vampire_giant:
			target_size *= _vampire_giant_head_scale(texture)
		var content_rect := _texture_content_rect(texture, target_size)
		center = Vector2(ground_center.x, shadow_center.y - content_rect.end.y + arc_lift * s)
	if (enemy_id == "guys" or (enemy_id == "werewolves" and not bool(chicken.get("werewolf_transformed", false)))) and not dead:
		var content_rect := _texture_content_rect(texture, target_size)
		center = Vector2(ground_center.x, shadow_center.y - content_rect.end.y + arc_lift * s)
	if dead:
		var content_rect := _texture_content_rect(texture, target_size)
		center = Vector2(ground_center.x, shadow_center.y - content_rect.end.y + arc_lift * s)
		if enemy_id == "giants":
			center.y += 8.0 * s
		shadow_radii.x = maxf(shadow_radii.x, content_rect.size.x * 0.38)
	var giant_buff_count := int(chicken.get("vampire_giant_buff_count", 0)) if vampire_giant else 0
	if giant_buff_count > 0 and not dead:
		var glow_alpha := minf(0.58, 0.18 + float(giant_buff_count) * 0.10)
		draw_circle(center, maxf(target_size.x, target_size.y) * 0.38, Color(0.58, 0.12, 0.88, glow_alpha))
		draw_circle(center, maxf(target_size.x, target_size.y) * 0.29, Color(0.82, 0.45, 1.0, glow_alpha * 0.70))
	_draw_ellipse(shadow_center, shadow_radii, Color(0, 0, 0, 0.17 * alpha))
	var transform_thrash := sin(elapsed_seconds * 35.0 + id_phase) * 0.055 if vampire_giant and float(chicken.get("transform_timer", 0.0)) > 0.0 else 0.0
	var sprite_rotation := -hit_flash * 0.10 + death_rotation + knock_rotation + transform_thrash
	var shield_up := enemy_id == "goblins" and bool(chicken.get("shield_up", false))
	if shield_up:
		_draw_goblin_shield(chicken, center, s, scale, face_right, alpha)
	var giant_uses_lift_frames := enemy_id == "giants" and str(chicken.get("giant_attack_kind", "toss")) in ["toss", "boulder"] and not attack_phase.is_empty()
	var art_faces_right := false if giant_uses_lift_frames else enemy_art_faces_right
	if enemy_id == "guys" and attack_texture != null:
		art_faces_right = false
	var sprite_size := _draw_character_texture(texture, center, target_size, sprite_rotation, alpha, face_right != art_faces_right)
	if not shield_up:
		_draw_goblin_shield(chicken, center, s, scale, face_right, alpha)
	if not dead and hp < max_hp - 0.01:
		var health_width := 64.0 * s if arena_shape == "diamond" else 78.0 * s * scale
		var head_side := (1.0 if face_right else -1.0) if enemy_id == "dragons" else 0.0
		_draw_local_health(_enemy_health_bar_center(center, sprite_size, sprite_rotation, s, head_side), health_width, hp / max_hp, DANGER, s)


func _enemy_death_bounce_pose(dead_timer: float, face_right: bool, bounce_scale := 1.0, bounce_direction := Vector2.RIGHT) -> Vector2:
	var lift := 0.0
	var rotation := 0.0
	if dead_timer < 0.38:
		var t := clampf(dead_timer / 0.38, 0.0, 1.0)
		lift = -92.0 * sin(t * PI)
		rotation = 0.95 * sin(t * PI)
	elif dead_timer < 0.63:
		var t := (dead_timer - 0.38) / 0.25
		lift = -38.0 * sin(t * PI)
		rotation = -0.30 * sin(t * PI)
	var horizontal_motion := absf(bounce_direction.normalized().x) if bounce_direction.length_squared() > 0.001 else 1.0
	rotation *= horizontal_motion
	return Vector2(lift, rotation * (-1.0 if face_right else 1.0)) * bounce_scale


func _texture_content_rect(texture: Texture2D, target_size: Vector2) -> Rect2:
	if texture == null:
		return Rect2()
	var source_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return Rect2()
	var used_rect: Rect2i
	if texture_used_rect_cache.has(texture):
		used_rect = texture_used_rect_cache[texture] as Rect2i
	else:
		var image := texture.get_image()
		if image != null and image.is_compressed() and image.decompress() != OK:
			image = null
		used_rect = image.get_used_rect() if image != null else Rect2i(Vector2i.ZERO, Vector2i(source_size))
		texture_used_rect_cache[texture] = used_rect
	var fit_scale := minf(target_size.x / source_size.x, target_size.y / source_size.y)
	var draw_size := source_size * fit_scale
	return Rect2(Vector2(used_rect.position) * fit_scale - draw_size * 0.5, Vector2(used_rect.size) * fit_scale)


func _enemy_transient_sprite_scale(scale_amount: float) -> float:
	match enemy_id:
		"cave-trolls": return CAVE_TROLL_CANONICAL_FRAME_SCALE
		"vampires": return 1.0
		"giants": return 1.52
		"dragons": return 1.30
	return scale_amount


func _giant_head_scale(texture: Texture2D) -> float:
	var attack_frames := enemy_attack_frames.get("giants-attack", []) as Array
	var frame_index := attack_frames.find(texture)
	return float([1.0, 1.0, 1.15, 1.10][frame_index]) if frame_index >= 0 else 1.0


func _vampire_giant_head_scale(texture: Texture2D) -> float:
	var frame_groups := [
		["vampire-giant-walk", [0.97, 0.96, 0.97, 1.04, 1.00, 1.03, 1.02, 1.00]],
		["vampire-giant-attack", [0.94, 0.96, 0.96, 0.88]],
		["vampire-giant-flight", [1.39, 0.81, 1.16]],
	]
	for frame_group: Array in frame_groups:
		var frame_index := (enemy_movement_frames.get(frame_group[0], []) as Array).find(texture)
		if frame_index < 0:
			frame_index = (enemy_attack_frames.get(frame_group[0], []) as Array).find(texture)
		if frame_index >= 0:
			return float((frame_group[1] as Array)[frame_index])
	return 1.0


func _draw_goblin_shield(chicken: Dictionary, center: Vector2, s: float, scale: float, face_right: bool, alpha: float) -> void:
	if enemy_id != "goblins" or goblin_shield == null:
		return
	var draw_scale := scale
	var draw_face_right := face_right
	var shield_center := center
	var shield_rotation := 0.0
	var shield_alpha := alpha
	if bool(chicken.get("shield_up", false)):
		shield_center += Vector2(-68.0 if face_right else 68.0, 18.0) * s * scale
		shield_rotation = -0.08 if face_right else 0.08
	else:
		var fall_timer := float(chicken.get("shield_fall_timer", 0.0))
		if fall_timer <= 0.0:
			return
		var elapsed := ENEMY_DEATH_LIFETIME - fall_timer
		var fall_t := clampf(elapsed / 0.63, 0.0, 1.0)
		var fall_dir := chicken.get("shield_fall_direction", Vector2.ZERO) as Vector2
		draw_scale = float(chicken.get("shield_drop_scale", scale))
		draw_face_right = bool(chicken.get("shield_drop_face_right", face_right))
		var drop_pos := chicken.get("shield_drop_pos", chicken.get("render_pos", chicken.get("pos", Vector2.ZERO))) as Vector2
		var ground_center := _norm_to_stage(drop_pos) - Vector2(0.0, 64.0) * s * draw_scale
		ground_center += Vector2(-68.0 if draw_face_right else 68.0, 18.0) * s * draw_scale + fall_dir * 118.0 * fall_t * s
		var bounce := _enemy_death_bounce_pose(elapsed, draw_face_right, 1.0 / 3.0, fall_dir)
		shield_center = ground_center + Vector2(0.0, bounce.x) * s
		shield_rotation = float(chicken.get("shield_fall_rotation", 0.0)) * fall_t + bounce.y
		shield_alpha = 1.0 - clampf((elapsed - ENEMY_DEATH_FADE_DELAY) / ENEMY_DEATH_FADE_SECONDS, 0.0, 1.0)
		_draw_ellipse(ground_center + Vector2(0.0, 20.0) * s * draw_scale, Vector2(25.0, 7.0) * s * draw_scale, Color(0.0, 0.0, 0.0, 0.15 * shield_alpha))
	var shield_size := Vector2(76.0, 76.0) * s * draw_scale
	var shield_margin := shield_size.length() * 0.48
	if arena_shape == "diamond":
		shield_center = _clamp_stage_point_to_diamond(shield_center, shield_margin)
	_draw_character_texture(goblin_shield, shield_center, shield_size, shield_rotation, shield_alpha, not draw_face_right, false)


func _enemy_health_bar_center(center: Vector2, sprite_size: Vector2, rotation: float, s: float, head_side: float) -> Vector2:
	var top_extent := (absf(cos(rotation)) * sprite_size.y + absf(sin(rotation)) * sprite_size.x) * 0.5
	return center + Vector2(sprite_size.x * 0.30 * head_side, -top_extent - 12.0 * s)


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
	var fill_color: Color = Color(0.31, 0.76, 1.0, 0.20 * alpha) if hero_attack_is_uppercut else Color(0.31, 0.76, 1.0, 0.12 * alpha)
	var ring_color: Color = Color(0.72, 0.92, 1.0, 0.72 * alpha) if hero_attack_is_uppercut else Color(0.55, 0.86, 1.0, 0.42 * alpha)
	draw_circle(hit_center, radius * 0.62, fill_color)
	draw_arc(hit_center, radius, 0.0, TAU, 32, ring_color, maxf(4.0, (8.0 if hero_attack_is_uppercut else 5.0) * s), true)
	if hero_attack_is_uppercut:
		draw_arc(hit_center, radius * 0.58, -PI * 0.25, PI * 1.15, 24, Color(0.86, 0.96, 1.0, 0.58 * alpha), maxf(3.0, 5.0 * s), true)


func _draw_inactive_cover(s: float) -> void:
	if arena_shape == "diamond":
		_draw_diamond_inactive_cover(s)
		return
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


func _draw_diamond_inactive_cover(s: float) -> void:
	var t := _ease_garage_door(cover_open_amount)
	var points := _rounded_diamond_points(_diamond_arena_points(), 72.0 * s, 10)
	var offset := _diamond_depth_offset(s)
	var closed_points := PackedVector2Array()
	for point in points:
		closed_points.append(point.lerp(point + offset, t))
	draw_colored_polygon(closed_points, Color("#8d171d"))
	for i in range(7):
		var line_y := size.y * (0.29 + float(i) * 0.065)
		var half_width := _diamond_half_width_at_y(line_y, closed_points)
		var center_x := size.x * 0.5
		draw_line(Vector2(center_x - half_width + 26.0 * s, line_y), Vector2(center_x + half_width - 26.0 * s, line_y), Color(0.12, 0.018, 0.02, 0.20), 3.0 * s, true)
	draw_polyline(closed_points, INK, 8.0 * s, true)
	var cover_chicken := cover_clean_chicken if cover_clean_chicken != null else idle_chicken
	if cover_chicken == null:
		return
	var badge_alpha := clampf(1.0 - t * 1.8, 0.0, 1.0)
	var badge_center := size * 0.5 + Vector2(0.0, 5.0) * s
	var chicken_size := Vector2(size.x * 0.30, size.y * 0.28)
	_draw_ellipse(badge_center + Vector2(0, chicken_size.y * 0.35), Vector2(chicken_size.x * 0.34, chicken_size.y * 0.10), Color(0, 0, 0, 0.22 * badge_alpha))
	_draw_character_texture(cover_chicken, badge_center, chicken_size, sin(elapsed_seconds * 0.8) * 0.010, badge_alpha, false, false)


func _layout_title_label(s: float) -> void:
	var top_rect := _cover_top_rect(s)
	title_label.position = top_rect.position + Vector2(30.0, 12.0) * s
	title_label.size = Vector2(maxf(0.0, top_rect.size.x - 60.0 * s), maxf(60.0, 108.0 * s))
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
	draw_line(Vector2(latch_rect.position.x + 18.0 * s, seam_y), Vector2(latch_rect.end.x - 18.0 * s, seam_y), Color("#ee4b38", 0.42 * latch_alpha), 4.0 * s, true)


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


func _draw_diamond_texture_cover(texture: Texture2D, rect: Rect2, points: PackedVector2Array, fallback_color: Color, s: float) -> void:
	draw_colored_polygon(points, fallback_color)
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	if texture_size.x <= 1.0 or texture_size.y <= 1.0:
		return
	var cover_scale := maxf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var source_size := rect.size / cover_scale
	var source_origin := (texture_size - source_size) * 0.5
	var center_x := rect.get_center().x
	var strip_h := maxf(1.0, 3.0 * s)
	var y := rect.position.y
	while y < rect.end.y:
		var next_y := minf(rect.end.y, y + strip_h)
		var mid_y := (y + next_y) * 0.5
		var half_width := _diamond_half_width_at_y(mid_y, points)
		var dest := Rect2(Vector2(center_x - half_width, y), Vector2(half_width * 2.0, next_y - y))
		if dest.size.x > 0.5 and dest.size.y > 0.5:
			var source := Rect2(source_origin + (dest.position - rect.position) / cover_scale, dest.size / cover_scale)
			draw_texture_rect_region(texture, dest, source, Color.WHITE, false, true)
		y = next_y


func _draw_punishment_overlay(s: float) -> void:
	var arena := _arena_rect(s)
	var screen_alpha := _ko_screen_alpha()
	var message_center := Vector2(arena.get_center().x, arena.position.y + arena.size.y * 0.20)
	var wiggle := sin(elapsed_seconds * 2.0) * 0.035
	var pop := 1.0 + sin(elapsed_seconds * 2.0 + 0.7) * 0.018
	_draw_centered_fit_text_rotated(
		"KNOCKED OUT",
		message_center,
		arena.size.x * 0.58,
		72,
		_fade_color(Color("#fff8db"), screen_alpha),
		18,
		_fade_color(INK, screen_alpha),
		wiggle,
		pop
	)
	var fill_pct := 1.0 - clampf(hero_ko_timer / HERO_KO_DURATION, 0.0, 1.0)
	var meter_size := Vector2(arena.size.x * 0.42, 32.0 * s)
	var meter_radius := meter_size.y * 0.5
	var meter := Rect2(Vector2(arena.get_center().x - meter_size.x * 0.5, arena.position.y + arena.size.y * 0.29), meter_size)
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


func _draw_character_texture(texture: Texture2D, center: Vector2, target_size: Vector2, rotation: float, alpha: float, flip_h := false, force_outline := false, modulate := Color.WHITE) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var source_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return Vector2.ZERO
	var fit_scale := minf(target_size.x / source_size.x, target_size.y / source_size.y)
	var draw_size := source_size * fit_scale
	var rect := Rect2(-draw_size * 0.5, draw_size)
	draw_set_transform(center, rotation, Vector2(-1.0 if flip_h else 1.0, 1.0))
	if force_outline:
		var outline := maxf(3.0, minf(draw_size.x, draw_size.y) * 0.025)
		var outline_color := Color(0, 0, 0, alpha * 0.78)
		for offset in [Vector2(-outline, 0.0), Vector2(outline, 0.0), Vector2(0.0, -outline), Vector2(0.0, outline), Vector2(-outline, -outline), Vector2(outline, -outline), Vector2(outline, outline), Vector2(-outline, outline)]:
			draw_texture_rect(texture, Rect2(rect.position + offset, rect.size), false, outline_color)
	var tint := modulate
	tint.a *= alpha
	draw_texture_rect(texture, rect, false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return draw_size


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
	var unlock_progress := clampf(float(fighting_level - enemy_unlock_level) / 8.0, 0.0, 1.0)
	return randf_range(enemy_base_hp_min, enemy_base_hp_max) * stat_mult * lerpf(enemy_unlock_health_scale, 1.0, unlock_progress)


func _enemy_sprite_scale_for_id(enemy_id: String) -> float:
	match enemy_id:
		"chicken-swarm":
			return 1.90
		"goblins":
			return 1.2834
		"rouses":
			return 2.70
		"guys":
			return 1.294
		"werewolves":
			return 2.52
		"cave-trolls":
			return 2.40
		"giants":
			return 2.89
		"vampires":
			return 1.53
		"dragons":
			return 5.80
	return 1.0


func _enemy_death_scale_for_id(id: String) -> float:
	match id:
		"chicken-swarm": return 0.70
		"rouses": return 0.80
		"guys": return 1.00
		"werewolves": return 0.92
		"cave-trolls": return 1.25
		"vampires": return 0.84
	return 1.0


func _enemy_shadow_scale_for_id(id: String) -> float:
	match id:
		"chicken-swarm": return 0.30
		"goblins": return 0.62
		"rouses": return 0.38
		"guys", "werewolves": return 0.52
		"cave-trolls", "giants": return 0.70
		"vampires": return 0.48
		"dragons": return 0.78
	return 0.55


func _hero_attack_damage_range_text() -> String:
	return "%d-%d" % [int(round(_hero_attack_damage_min())), int(round(_hero_attack_damage_max()))]


func _hero_attack_interval() -> float:
	return maxf(0.34, HERO_BASE_ATTACK_INTERVAL / pow(HERO_LEVEL_MULT, maxi(0, fighting_level - enemy_unlock_level)))


func _hero_level_multiplier() -> float:
	var multiplier := pow(HERO_LEVEL_MULT, maxf(0.0, float(fighting_level - HERO_STAT_BASELINE_LEVEL)))
	if enemy_id == "guys":
		multiplier *= pow(GUYS_LEVEL_ADVANTAGE_MULT, maxf(0.0, float(fighting_level - GUYS_UNLOCK_LEVEL)))
	if enemy_id == "giants":
		multiplier *= pow(GIANTS_LEVEL_ADVANTAGE_MULT, maxf(0.0, float(fighting_level - enemy_unlock_level)))
	return multiplier


func _norm_to_stage(pos: Vector2) -> Vector2:
	var arena := _arena_rect(_stage_scale())
	return arena.position + Vector2(pos.x * arena.size.x, pos.y * arena.size.y)


func _clamp_norm_to_arena(pos: Vector2) -> Vector2:
	if arena_shape == "diamond":
		return _clamp_norm_to_diamond(pos, 0.055)
	return Vector2(clampf(pos.x, 0.035, 0.965), clampf(pos.y, 0.07, 0.93))


func _clamp_norm_to_diamond(pos: Vector2, margin: float) -> Vector2:
	var y := clampf(pos.y, 0.07 + margin, 0.93 - margin)
	var half_width := (0.5 - margin) * (1.0 - absf(y - 0.5) / 0.43)
	return Vector2(clampf(pos.x, 0.5 - half_width, 0.5 + half_width), y)


func _diamond_contains_norm(pos: Vector2) -> bool:
	if pos.y < 0.07 or pos.y > 0.93:
		return false
	var half_width := 0.5 * (1.0 - absf(pos.y - 0.5) / 0.43)
	return absf(pos.x - 0.5) <= half_width
