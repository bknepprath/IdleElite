extends SceneTree

const FightStage := preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")


func _init() -> void:
	seed(8804)
	var cape_source := Image.load_from_file("res://assets/content/fight/enemies/vampires/vampires-cape-summon-source.png")
	assert(cape_source.get_size() == Vector2i(1360, 1254))
	var giant_transform_frame := Image.load_from_file("res://assets/content/fight/enemies/vampires/giant-bat/transform/frame-02.png")
	assert(giant_transform_frame.get_pixel(0, 0).a == 0.0)
	var cape_cell := Vector2i(cape_source.get_width() / 2, cape_source.get_height() / 2)
	for frame_index in range(4):
		var cell_origin := Vector2i(frame_index % 2, frame_index / 2) * cape_cell
		var used_rect := cape_source.get_region(Rect2i(cell_origin, cape_cell)).get_used_rect()
		assert(used_rect.position.x >= 8 and used_rect.end.x <= cape_cell.x - 8)
	var stage := FightStage.new()
	stage.set("enemy_id", "vampires")
	stage.set("hero_pos", Vector2(0.5, 0.55))
	stage.set("hero_hp", 100.0)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.size = Vector2(1080.0, 620.0)
	var vampire := {
		"id": 1,
		"pos": Vector2(0.22, 0.42),
		"hp": 80.0,
		"max_hp": 100.0,
		"damage": 12.0,
		"vampire_teleport_timer": 0.0,
	}
	var giant_candidate := vampire.duplicate(true)
	giant_candidate["hp"] = 49.0
	giant_candidate["damage"] = 10.0
	giant_candidate["speed"] = 0.10
	assert(bool(stage.call("_try_transform_vampire_giant", giant_candidate, 0.279)))
	assert(bool(giant_candidate.get("vampire_giant_transformed", false)))
	assert(is_equal_approx(float(giant_candidate.get("max_hp", 0.0)), 200.0))
	assert(is_equal_approx(float(giant_candidate.get("hp", 0.0)), 98.0))
	assert(is_equal_approx(float(giant_candidate.get("damage", 0.0)), 16.0))
	assert(not bool(stage.call("_try_transform_vampire_giant", giant_candidate, 0.0)))
	var refused_giant := vampire.duplicate(true)
	refused_giant["hp"] = 49.0
	assert(not bool(stage.call("_try_transform_vampire_giant", refused_giant, 0.28)))
	assert(bool(refused_giant.get("vampire_giant_roll_done", false)))
	stage.call("_load_monster_movement_frames")
	stage.call("_load_enemy_attack_frames")
	var movement_frames := stage.get("enemy_movement_frames") as Dictionary
	var transform_frames := movement_frames.get("vampire-giant-transform", []) as Array
	giant_candidate["transform_timer"] = 1.96875
	assert(stage.call("_movement_texture", giant_candidate) == transform_frames[1])
	giant_candidate["transform_timer"] = 1.6875
	assert(stage.call("_movement_texture", giant_candidate) == transform_frames[0])
	var giant_walk_frames := movement_frames.get("vampire-giant-walk", []) as Array
	var giant_flight_frames := movement_frames.get("vampire-giant-flight", []) as Array
	var giant_attack_frames := (stage.get("enemy_attack_frames") as Dictionary).get("vampire-giant-attack", []) as Array
	assert(is_equal_approx(float(stage.call("_vampire_giant_head_scale", giant_walk_frames[0])), 0.97))
	assert(is_equal_approx(float(stage.call("_vampire_giant_head_scale", giant_flight_frames[0])), 1.39))
	assert(is_equal_approx(float(stage.call("_vampire_giant_head_scale", giant_attack_frames[3])), 0.88))
	assert(stage.call("_movement_texture", giant_candidate) != null)
	giant_candidate["transform_timer"] = 0.0
	giant_candidate["pos"] = Vector2(0.35, 0.42)
	giant_candidate["attack_phase"] = ""
	giant_candidate["hit_flash"] = 0.0
	giant_candidate["stagger_timer"] = 0.0
	assert(stage.call("_movement_texture", giant_candidate) != null)
	var giant_chickens: Array[Dictionary] = [giant_candidate]
	stage.set("chickens", giant_chickens)
	stage.call("_spawn_vampire_shockwave", vampire)
	stage.call("_step_vampire_shockwaves", 1.0)
	giant_candidate = (stage.get("chickens") as Array)[0] as Dictionary
	assert(int(giant_candidate.get("vampire_giant_buff_count", 0)) == 1)
	assert(is_equal_approx(float(giant_candidate.get("max_hp", 0.0)), 240.0))
	assert(is_equal_approx(float(giant_candidate.get("hp", 0.0)), 117.6))
	assert(is_equal_approx(float(giant_candidate.get("damage", 0.0)), 16.8))
	var no_chickens: Array[Dictionary] = []
	stage.set("chickens", no_chickens)
	var no_shockwaves: Array[Dictionary] = []
	stage.set("vampire_shockwaves", no_shockwaves)
	assert(stage.call("_vampire_attack_kind_for_roll", vampire, 0.0) == "bats")
	assert(stage.call("_vampire_attack_kind_for_roll", vampire, 0.50) == "shockwave")
	var cadence_vampire := vampire.duplicate(true)
	cadence_vampire["vampire_attack_count"] = 0
	stage.call("_begin_enemy_attack", cadence_vampire, Vector2.RIGHT)
	assert(str(cadence_vampire.get("vampire_attack_kind", "")) == "bats")
	cadence_vampire["vampire_attack_count"] = 1
	stage.call("_begin_enemy_attack", cadence_vampire, Vector2.RIGHT)
	assert(str(cadence_vampire.get("vampire_attack_kind", "")) == "shockwave")
	vampire["hp"] = 24.0
	assert(stage.call("_vampire_attack_kind_for_roll", vampire, 0.0) == "bite")
	assert(stage.call("_vampire_attack_kind_for_roll", vampire, 0.75) == "swipe")
	var old_pos := vampire["pos"] as Vector2
	var teleport_pos := stage.call("_step_vampire_idle_teleport", vampire, old_pos, 0.1) as Vector2
	assert(teleport_pos.is_equal_approx(old_pos))
	assert(str(vampire.get("vampire_teleport_phase", "")) == "out")
	teleport_pos = stage.call("_step_vampire_idle_teleport", vampire, teleport_pos, 0.25) as Vector2
	assert(not teleport_pos.is_equal_approx(old_pos))
	assert(str(vampire.get("vampire_teleport_phase", "")) == "in")
	assert((vampire.get("render_pos", old_pos) as Vector2).is_equal_approx(teleport_pos))
	assert((stage.get("smoke_puffs") as Array).size() == 20)
	assert(bool(((stage.get("smoke_puffs") as Array)[0] as Dictionary).get("teleport", false)))
	teleport_pos = stage.call("_step_vampire_idle_teleport", vampire, teleport_pos, 0.25) as Vector2
	assert(str(vampire.get("vampire_teleport_phase", "")) == "")
	var cooldown_teleporter := vampire.duplicate(true)
	cooldown_teleporter["attack_phase"] = ""
	cooldown_teleporter["attack_cd"] = 0.01
	cooldown_teleporter["vampire_teleport_phase"] = "out"
	cooldown_teleporter["vampire_teleport_fx_timer"] = 0.02
	cooldown_teleporter["vampire_teleport_target"] = Vector2(0.34, 0.48)
	stage.call("_step_chicken", cooldown_teleporter, 0.02)
	assert(str(cooldown_teleporter.get("vampire_teleport_phase", "")) == "in")
	stage.call("_step_chicken", cooldown_teleporter, 0.25)
	assert(str(cooldown_teleporter.get("vampire_teleport_phase", "")) == "")
	assert(str(cooldown_teleporter.get("attack_phase", "")) == "windup")
	vampire["vampire_walk_timer"] = 1.0
	vampire["vampire_teleport_timer"] = 1.0
	var walk_pos := stage.call("_step_vampire_idle_teleport", vampire, teleport_pos, 0.25) as Vector2
	assert(walk_pos.distance_to(stage.get("hero_pos") as Vector2) < teleport_pos.distance_to(stage.get("hero_pos") as Vector2))
	vampire["attack_phase"] = "windup"
	vampire["interrupt_protected"] = false
	stage.call("_stagger_enemy", vampire)
	assert(str(vampire.get("attack_phase", "")) == "stagger")
	vampire["stagger_timer"] = 0.01
	vampire["attack_cd"] = 10.0
	vampire["vampire_idle_timer"] = 0.0
	vampire["vampire_teleport_phase"] = ""
	vampire["vampire_teleport_timer"] = 10.0
	vampire["vampire_walk_timer"] = 0.0
	stage.call("_step_chicken", vampire, 0.02)
	assert(str(vampire.get("attack_phase", "")) == "")
	assert(float(vampire.get("vampire_idle_timer", 0.0)) > 0.0)
	vampire["vampire_walk_timer"] = 1.0
	vampire["hit_flash"] = 0.0
	stage.call("_load_monster_movement_frames")
	assert(stage.call("_movement_texture", vampire) != null)
	stage.call("_load_enemy_attack_frames")
	var attack_frames := stage.get("enemy_attack_frames") as Dictionary
	assert((attack_frames.get("vampires-attack", []) as Array)[0] != (attack_frames.get("vampires-cape", []) as Array)[0])
	vampire["attack_phase"] = "strike"
	vampire["vampire_attack_kind"] = "shockwave"
	assert(stage.call("_enemy_attack_texture", vampire) != null)
	vampire["vampire_attack_kind"] = "bats"
	assert(stage.call("_enemy_attack_texture", vampire) == (attack_frames.get("vampires-cape", []) as Array)[2])
	vampire["vampire_attack_kind"] = "swipe"
	assert(stage.call("_enemy_attack_texture", vampire) == (attack_frames.get("vampires-attack", []) as Array)[2])
	vampire["attack_phase"] = ""
	vampire["attack_cd"] = 10.0
	vampire["vampire_idle_timer"] = 1.70
	vampire["vampire_teleport_timer"] = 10.0
	vampire["vampire_walk_timer"] = 0.0
	stage.call("_step_chicken", vampire, 0.10)
	assert(str(vampire.get("attack_phase", "")) == "windup")
	assert(str(vampire.get("vampire_attack_kind", "")) == "bats")
	vampire["attack_phase"] = ""
	assert((stage.call("_step_enemy_approach", vampire, teleport_pos, Vector2.RIGHT, 1.0, 1.0) as Vector2).is_equal_approx(teleport_pos))
	vampire["pos"] = Vector2(0.22, 0.55)
	assert(stage.call("_vampire_bat_spawn_pattern_for_roll", 0.0) == "channel")
	assert(stage.call("_vampire_bat_spawn_pattern_for_roll", 0.9) == "burst")
	assert(bool(stage.call("_vampire_bat_facing_right", true, -0.10)))
	assert(not bool(stage.call("_vampire_bat_facing_right", true, -0.80)))
	var channel_vampire := vampire.duplicate(true)
	channel_vampire["attack_phase"] = "windup"
	channel_vampire["interrupt_protected"] = false
	channel_vampire["vampire_bat_spawn_pattern"] = "channel"
	channel_vampire["vampire_bat_channel_remaining"] = 7
	channel_vampire["vampire_bat_channel_total"] = 7
	channel_vampire["vampire_bat_channel_spawned"] = 0
	channel_vampire["vampire_bat_channel_beat_timer"] = 0.45
	stage.call("_step_vampire_bat_channel", channel_vampire, 0.45)
	assert((stage.get("vampire_bats") as Array).size() == 1)
	stage.call("_step_vampire_bat_channel", channel_vampire, 0.10)
	assert((stage.get("vampire_bats") as Array).size() == 1)
	stage.call("_stagger_enemy", channel_vampire)
	assert(str(channel_vampire.get("attack_phase", "")) == "stagger")
	assert(int(channel_vampire.get("vampire_bat_channel_remaining", -1)) == 0)
	var no_bats: Array[Dictionary] = []
	stage.set("vampire_bats", no_bats)
	stage.call("_spawn_vampire_bats", vampire)
	var bats := stage.get("vampire_bats") as Array
	assert(bats.size() == 4)
	var left_start := (bats[0] as Dictionary).get("pos", Vector2.ZERO) as Vector2
	var right_start := (bats[3] as Dictionary).get("pos", Vector2.ZERO) as Vector2
	stage.call("_step_vampire_bats", 0.10)
	bats = stage.get("vampire_bats") as Array
	assert(((bats[0] as Dictionary).get("pos", Vector2.ZERO) as Vector2).x < left_start.x)
	assert(((bats[3] as Dictionary).get("pos", Vector2.ZERO) as Vector2).x > right_start.x)
	var orbiting_bats := bats.duplicate(true)
	for i in range(orbiting_bats.size()):
		var orbiting_bat := orbiting_bats[i] as Dictionary
		orbiting_bat["pos"] = stage.get("hero_pos")
		orbiting_bat["scatter_timer"] = 0.0
		orbiting_bat["attack_cd"] = 999.0
		orbiting_bats[i] = orbiting_bat
	stage.set("vampire_bats", orbiting_bats)
	stage.call("_step_vampire_bats", 1.0)
	orbiting_bats = stage.get("vampire_bats") as Array
	assert(orbiting_bats.any(func(bat: Dictionary) -> bool: return (bat.get("pos", Vector2.ZERO) as Vector2).x < 0.48))
	assert(orbiting_bats.any(func(bat: Dictionary) -> bool: return (bat.get("pos", Vector2.ZERO) as Vector2).x > 0.52))
	assert(orbiting_bats.any(func(bat: Dictionary) -> bool: return (bat.get("pos", Vector2.ZERO) as Vector2).y < 0.53))
	assert(orbiting_bats.any(func(bat: Dictionary) -> bool: return (bat.get("pos", Vector2.ZERO) as Vector2).y > 0.57))
	stage.set("vampire_bats", bats)
	for i in range(bats.size()):
		var bat := bats[i] as Dictionary
		bat["pos"] = Vector2(0.54, 0.55) if i == 0 else Vector2(0.88 + float(i) * 0.015, 0.55)
		bats[i] = bat
	stage.set("vampire_bats", bats)
	assert(not bool(stage.call("_start_hero_attack")))
	stage.call("_step_vampire_bats", 0.75)
	bats = stage.get("vampire_bats") as Array
	for i in range(bats.size()):
		var bat := bats[i] as Dictionary
		bat["pos"] = Vector2(0.54, 0.55) if i == 0 else Vector2(0.88 + float(i) * 0.015, 0.55)
		bats[i] = bat
	stage.set("vampire_bats", bats)
	assert(bool(stage.call("_start_hero_attack")))
	bats = stage.get("vampire_bats") as Array
	assert(bats.size() == 3)
	for i in range(bats.size()):
		var bat := bats[i] as Dictionary
		bat["pos"] = (stage.get("hero_pos") as Vector2) + Vector2.from_angle(float(bat.get("orbit_angle", 0.0))) * 0.18
		bat["attack_cd"] = 0.0
		bat["attack_timer"] = 0.0
		bats[i] = bat
	stage.set("vampire_bats", bats)
	stage.set("hero_hurt_cooldown", 0.0)
	stage.set("hero_hp", 100.0)
	stage.call("_step_vampire_bats", 0.01)
	stage.call("_step_vampire_bats", 0.21)
	assert(float(stage.get("hero_hp")) < 100.0)
	assert((stage.get("vampire_bats") as Array).size() == 3)
	stage.set("hero_hp", 100.0)
	stage.set("hero_hurt_cooldown", 0.0)
	bats = stage.get("vampire_bats") as Array
	vampire["pos"] = Vector2(0.38, 0.55)
	for i in range(bats.size()):
		var nearby_bat := bats[i] as Dictionary
		nearby_bat["pos"] = Vector2(0.43 + float(i) * 0.012, 0.55)
		bats[i] = nearby_bat
	stage.set("vampire_bats", bats)
	var base_buff_damage := float((bats[0] as Dictionary).get("damage", 0.0))
	stage.call("_spawn_vampire_shockwave", vampire)
	stage.call("_step_vampire_shockwaves", 1.0)
	assert(float(stage.get("hero_hp")) == 100.0)
	assert(int(stage.get("hero_purple_buff_punches")) == 1)
	bats = stage.get("vampire_bats") as Array
	assert(bats.any(func(bat: Dictionary) -> bool:
		return int(bat.get("buff_count", 0)) == 1 and is_equal_approx(float(bat.get("buff_scale", 1.0)), 1.20)
	))
	assert(is_equal_approx(float((bats[0] as Dictionary).get("damage", 0.0)), base_buff_damage * 1.05))
	var same_shockwaves := stage.get("vampire_shockwaves") as Array
	(same_shockwaves[0] as Dictionary)["radius"] = 22.0
	stage.set("vampire_shockwaves", same_shockwaves)
	stage.call("_step_vampire_shockwaves", 1.0)
	bats = stage.get("vampire_bats") as Array
	assert(int((bats[0] as Dictionary).get("buff_count", 0)) == 1)
	stage.call("_spawn_vampire_shockwave", vampire)
	stage.call("_step_vampire_shockwaves", 1.0)
	bats = stage.get("vampire_bats") as Array
	var twice_buffed := bats[0] as Dictionary
	assert(int(twice_buffed.get("buff_count", 0)) == 2)
	assert(is_equal_approx(float(twice_buffed.get("buff_scale", 1.0)), 1.40))
	assert(is_equal_approx(float(twice_buffed.get("hp", 0.0)), 3.0))
	assert(is_equal_approx(float(twice_buffed.get("damage", 0.0)), base_buff_damage * 1.05 * 1.05))
	for i in range(bats.size()):
		var bat := bats[i] as Dictionary
		bat["pos"] = Vector2(0.54, 0.55) if i == 0 else Vector2(0.90 + float(i) * 0.015, 0.55)
		bat["spawn_invuln_timer"] = 0.0
		bats[i] = bat
	stage.set("vampire_bats", bats)
	var bat_xp_rewards: Array[int] = []
	stage.chicken_killed.connect(func(xp_amount: int) -> void: bat_xp_rewards.append(xp_amount))
	assert(bool(stage.call("_start_hero_attack")))
	assert(int(stage.get("hero_purple_buff_punches")) == 0)
	assert(bool(stage.get("hero_attack_purple_buffed")))
	assert(is_equal_approx(float((stage.get("vampire_bats") as Array)[0].get("hp", 0.0)), 2.0))
	assert(bool(stage.call("_start_hero_attack")))
	assert(is_equal_approx(float((stage.get("vampire_bats") as Array)[0].get("hp", 0.0)), 1.0))
	assert(bool(stage.call("_start_hero_attack")))
	assert((stage.get("vampire_bats") as Array).size() == 2)
	assert(bat_xp_rewards == [2])
	assert(int(stage.call("_living_chicken_count")) == 2)
	stage.set("chickens", [])
	stage.set("wave_index", 4)
	stage.set("wave_spawn_remaining", 2)
	stage.set("wave_spawned_count", 0)
	stage.set("enemy_population_cap", 2)
	stage.set("enemy_population_curve", [1, 1, 1, 2, 2])
	stage.call("_spawn_wave_burst")
	assert((stage.get("chickens") as Array).size() == 1)
	stage.set("wave_index", 1)
	stage.set("wave_spawned_count", 0)
	stage.call("_step_random_wave_spawning", 0.01)
	assert((stage.get("chickens") as Array).size() == 2)
	stage.set("wave_spawn_phase_duration_current", 6.0)
	assert(is_zero_approx(float(stage.call("_random_spawn_chance_per_roll"))))
	assert(is_equal_approx(float(stage.call("_wave_rest_duration_for_wave")), 12.0))
	stage.set("hero_hurt_cooldown", 0.0)
	stage.set("hero_hp", 100.0)
	vampire["hp"] = 20.0
	stage.call("_apply_vampire_bite", vampire)
	assert(float(stage.get("hero_hp")) == 88.0)
	assert(float(vampire.get("hp", 0.0)) == 32.0)
	stage.free()
	print("vampire-specials-ok")
	quit()
