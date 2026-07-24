extends SceneTree

const FightStage := preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")


func _init() -> void:
	var stage := FightStage.new()
	stage.set("enemy_id", "dragons")
	stage.set("hero_pos", Vector2(0.80, 0.55))
	stage.call("_load_monster_movement_frames")
	stage.call("_load_enemy_attack_frames")
	stage.call("_load_effect_frames")

	var dragon := {
		"id": 1,
		"pos": Vector2(0.20, 0.55),
		"hp": 100.0,
		"attack_phase": "",
		"hit_flash": 0.0,
		"stagger_timer": 0.0,
		"dragon_is_walking": false,
	}
	assert(stage.call("_movement_texture", dragon) == null)
	dragon["dragon_is_walking"] = true
	var movement_frames := (stage.get("enemy_movement_frames") as Dictionary).get("dragons", []) as Array
	assert(movement_frames.size() == 4)
	assert(stage.call("_movement_texture", dragon) != null)

	dragon["dragon_attack_kind"] = "brawl"
	assert(is_equal_approx(float(stage.call("_enemy_strike_duration", dragon)), 0.52))
	var transition_dragon := dragon.duplicate(true)
	transition_dragon["attack_phase"] = "strike"
	transition_dragon["attack_timer"] = 0.01
	transition_dragon["attack_duration"] = 0.52
	stage.call("_step_chicken", transition_dragon, 0.02)
	assert(str(transition_dragon.get("attack_phase", "")) == "recovery")
	stage.set("hero_pos", Vector2(0.50, 0.55))
	var brawl_hold := stage.call("_step_enemy_approach", dragon, Vector2(0.20, 0.55), Vector2.RIGHT, 0.30, 1.0) as Vector2
	var brawl_walk := stage.call("_step_enemy_approach", dragon, Vector2(0.19, 0.55), Vector2.RIGHT, 0.31, 1.0) as Vector2
	assert(brawl_hold.is_equal_approx(Vector2(0.20, 0.55)))
	assert(brawl_walk.x > 0.19)
	stage.set("hero_pos", Vector2(0.50, 0.55))
	var aligned_sidestep := stage.call("_step_enemy_approach", dragon, Vector2(0.50, 0.25), Vector2.DOWN, 0.30, 1.0) as Vector2
	assert(not is_equal_approx(aligned_sidestep.x, 0.50))
	stage.set("arena_shape", "diamond")
	stage.set("hero_pos", Vector2(0.45, 0.55))
	var boundary_pos := stage.call("_clamp_norm_to_arena", Vector2(0.0, 0.25)) as Vector2
	dragon["dragon_brawl_side"] = -1.0
	var boundary_sidestep := stage.call("_step_enemy_approach", dragon, boundary_pos, (stage.get("hero_pos") as Vector2) - boundary_pos, boundary_pos.distance_to(stage.get("hero_pos") as Vector2), 0.05) as Vector2
	assert((stage.call("_clamp_norm_to_arena", boundary_sidestep) as Vector2).distance_squared_to(boundary_pos) > 0.0000001)
	stage.set("hero_pos", boundary_pos + Vector2(0.08, 0.0))
	dragon["dragon_attack_kind"] = "breath"
	var boundary_retreat := stage.call("_step_enemy_approach", dragon, boundary_pos, Vector2.RIGHT, 0.08, 0.05) as Vector2
	assert(boundary_retreat.distance_squared_to(boundary_pos) > 0.0000001)
	assert(boundary_retreat.distance_squared_to(stage.get("hero_pos") as Vector2) > boundary_pos.distance_squared_to(stage.get("hero_pos") as Vector2))
	stage.set("arena_shape", "diamond")
	stage.set("hero_pos", Vector2(0.50, 0.55))
	var cycle_dragon := {
		"id": 3,
		"pos": Vector2(0.50, 0.25),
		"hp": 100000.0,
		"max_hp": 100000.0,
		"damage": 1.0,
		"speed": 0.09,
		"attack_cd": 0.0,
		"attack_phase": "",
		"attack_timer": 0.0,
		"attack_duration": 0.0,
		"attack_damage_done": false,
		"stagger_timer": 0.0,
		"interrupt_protected": false,
		"dragon_attack_kind": "brawl",
	}
	var seen_dragon_strikes := {}
	var empty_seconds := 0.0
	var longest_empty_seconds := 0.0
	for _frame in range(1200):
		stage.call("_step_chicken", cycle_dragon, 0.05)
		var cycle_phase := str(cycle_dragon.get("attack_phase", ""))
		if cycle_phase.is_empty():
			empty_seconds += 0.05
			longest_empty_seconds = maxf(longest_empty_seconds, empty_seconds)
		else:
			empty_seconds = 0.0
		if cycle_phase == "strike":
			seen_dragon_strikes[str(cycle_dragon.get("dragon_attack_kind", ""))] = true
		if seen_dragon_strikes.size() == 3:
			break
	assert(seen_dragon_strikes.has("brawl"))
	assert(seen_dragon_strikes.has("breath"))
	assert(seen_dragon_strikes.has("pounce"))
	assert(longest_empty_seconds < 8.0)

	stage.call("_update_dragon_breath_aim", dragon, dragon["pos"])
	assert(str(dragon.get("dragon_breath_aim", "")) == "straight")
	assert((dragon.get("breath_dir") as Vector2).is_equal_approx(Vector2.RIGHT))
	stage.set("hero_pos", Vector2(0.80, 0.20))
	stage.call("_update_dragon_breath_aim", dragon, dragon["pos"])
	assert(str(dragon.get("dragon_breath_aim", "")) == "far")
	assert((dragon.get("breath_dir") as Vector2).y < 0.0)
	stage.set("hero_pos", Vector2(0.80, 0.82))
	stage.call("_update_dragon_breath_aim", dragon, dragon["pos"])
	assert(str(dragon.get("dragon_breath_aim", "")) == "near")
	assert((dragon.get("breath_dir") as Vector2).y > 0.0)
	var mouth_right := stage.call("_dragon_mouth_pos", dragon["pos"], dragon["breath_dir"]) as Vector2
	var mouth_left := stage.call("_dragon_mouth_pos", dragon["pos"], Vector2.LEFT) as Vector2
	assert(mouth_right.x > (dragon["pos"] as Vector2).x and mouth_right.y < (dragon["pos"] as Vector2).y)
	assert(mouth_left.x < (dragon["pos"] as Vector2).x)

	dragon["dragon_attack_kind"] = "breath"
	dragon["dragon_cycle_damage_done"] = true
	stage.call("_begin_enemy_attack", dragon, Vector2.RIGHT)
	assert(not bool(dragon.get("dragon_cycle_damage_done", true)))
	assert(int(dragon.get("dragon_breath_emissions", -1)) == 0)
	dragon["attack_phase"] = "strike"
	var attack_frames := stage.get("enemy_attack_frames") as Dictionary
	assert(stage.call("_enemy_attack_texture", dragon) == (attack_frames.get("dragons-breath-near-hold") as Array)[0])
	assert(is_equal_approx(float(stage.call("_enemy_strike_duration", dragon)), 1.20))

	dragon["dragon_attack_kind"] = "brawl"
	stage.set("hero_pos", Vector2(0.45, 0.20))
	stage.call("_update_dragon_melee_aim", dragon, dragon["pos"])
	assert(str(dragon.get("dragon_melee_aim", "")) == "far")
	assert(stage.call("_enemy_attack_texture", dragon) == (attack_frames.get("dragons-claw-far-hold") as Array)[0])
	stage.set("hero_pos", Vector2(0.45, 0.82))
	stage.call("_update_dragon_melee_aim", dragon, dragon["pos"])
	assert(str(dragon.get("dragon_melee_aim", "")) == "near")
	assert(stage.call("_enemy_attack_texture", dragon) == (attack_frames.get("dragons-claw-near-hold") as Array)[0])
	stage.set("hero_pos", Vector2(0.20, 0.20))
	stage.call("_update_dragon_melee_aim", dragon, dragon["pos"])
	assert(str(dragon.get("dragon_melee_aim", "")) == "vertical-far")
	assert(stage.call("_enemy_attack_texture", dragon) == (attack_frames.get("dragons-claw-vertical-far-hold") as Array)[0])
	stage.set("hero_pos", Vector2(0.20, 0.82))
	stage.call("_update_dragon_melee_aim", dragon, dragon["pos"])
	assert(str(dragon.get("dragon_melee_aim", "")) == "vertical-near")
	assert(stage.call("_enemy_attack_texture", dragon) == (attack_frames.get("dragons-claw-vertical-near-hold") as Array)[0])
	stage.set("hero_pos", Vector2(0.45, 0.55))
	stage.call("_update_dragon_melee_aim", dragon, dragon["pos"])
	assert(str(dragon.get("dragon_melee_aim", "")) == "straight")

	(stage.get("active_effects") as Array).clear()
	dragon["dragon_attack_kind"] = "breath"
	stage.set("hero_pos", Vector2(0.45, 0.82))
	dragon["roll_dir"] = dragon["breath_dir"]
	dragon["signature_t"] = 0.50
	dragon["dragon_breath_beat_timer"] = 0.0
	dragon["dragon_breath_emissions"] = 0
	dragon["attack_damage_done"] = true
	dragon["dragon_cycle_damage_done"] = true
	for beat in range(7):
		stage.call("_step_enemy_strike", dragon, dragon["pos"], Vector2.RIGHT, 0.18)
	assert(int(dragon.get("dragon_breath_emissions", 0)) == 7)
	var effects := stage.get("active_effects") as Array
	assert(effects.size() == 7)
	for index in range(effects.size()):
		assert(str(effects[index].get("name", "")) == "dragon-breath-fire-tuft")
		assert(float(effects[index].get("max_life", 0.0)) > 1.0)
		if index > 0:
			var step := (effects[index].get("pos", Vector2.ZERO) as Vector2) - (effects[index - 1].get("pos", Vector2.ZERO) as Vector2)
			assert(step.dot(dragon["breath_dir"] as Vector2) > 0.0)
			assert(step.length() < 0.055)
			assert(not is_equal_approx(float(effects[index].get("wiggle_phase", 0.0)), float(effects[index - 1].get("wiggle_phase", 0.0))))
	var diagonal_layout := stage.call("_effect_layout", "dragon-breath-fire-tuft", dragon["breath_dir"]) as Dictionary
	assert(absf(float(diagonal_layout.get("rotation", 0.0))) > 0.30)

	(stage.get("active_effects") as Array).clear()
	stage.set("hero_pos", Vector2(0.58, 0.55))
	stage.set("hero_hp", 100.0)
	stage.set("hero_hurt_cooldown", 0.0)
	dragon["pos"] = Vector2(0.35, 0.55)
	dragon["dragon_attack_kind"] = "pounce"
	dragon["attack_phase"] = ""
	stage.call("_begin_enemy_attack", dragon, Vector2.RIGHT)
	assert(bool(dragon.get("interrupt_protected", false)))
	assert(is_equal_approx(float(stage.call("_enemy_strike_duration", dragon)), 0.82))
	assert(is_equal_approx(float(stage.call("_enemy_attack_range", dragon)), 0.34))
	assert((attack_frames.get("dragons-pounce", []) as Array).size() == 4)
	dragon["attack_phase"] = "windup"
	stage.call("_stagger_enemy", dragon, true)
	assert(str(dragon.get("attack_phase", "")) == "windup")
	dragon["attack_phase"] = "strike"
	dragon["signature_t"] = 0.70
	stage.call("_step_enemy_strike", dragon, dragon["pos"], Vector2.RIGHT, 0.01)
	assert(bool(dragon.get("slam_impacted", false)))
	assert(float(stage.get("hero_hp")) < 100.0)
	assert(float(stage.get("hero_toss_timer")) > 0.0)
	var half_toss_distance := (stage.get("hero_toss_target") as Vector2).distance_to(stage.get("hero_toss_start") as Vector2)
	assert(half_toss_distance <= 0.151 and half_toss_distance >= 0.145)
	var pounce_effects := stage.get("active_effects") as Array
	assert(not pounce_effects.is_empty())
	assert(str(pounce_effects.back().get("name", "")) == "dragon-pounce-shockwave")
	var pounce_layout := stage.call("_effect_layout", "dragon-pounce-shockwave", Vector2.RIGHT) as Dictionary
	var troll_layout := stage.call("_effect_layout", "cave-troll-slam", Vector2.RIGHT) as Dictionary
	assert((pounce_layout.get("size") as Vector2).x < (troll_layout.get("size") as Vector2).x)

	var walk_heights: Array[int] = []
	for path in [
		"res://assets/content/fight/enemies/dragons/dragons-low-walk-01.png",
		"res://assets/content/fight/enemies/dragons/dragons-low-walk-02.png",
		"res://assets/content/fight/enemies/dragons/dragons-low-walk-03.png",
		"res://assets/content/fight/enemies/dragons/dragons-low-walk-04.png",
		"res://assets/content/fight/enemies/dragons/dragons-breath-03.png",
		"res://assets/content/fight/enemies/dragons/dragons-breath-far.png",
		"res://assets/content/fight/enemies/dragons/dragons-breath-near.png",
		"res://assets/content/fight/enemies/dragons/dragons-claw-far.png",
		"res://assets/content/fight/enemies/dragons/dragons-claw-near.png",
		"res://assets/content/fight/enemies/dragons/dragons-claw-vertical-far.png",
		"res://assets/content/fight/enemies/dragons/dragons-claw-vertical-near.png",
		"res://assets/content/fight/effects/dragon-breath-fire-tuft.png",
		"res://assets/content/fight/enemies/dragons/dragons-pounce-01.png",
		"res://assets/content/fight/enemies/dragons/dragons-pounce-02.png",
		"res://assets/content/fight/enemies/dragons/dragons-pounce-03.png",
		"res://assets/content/fight/enemies/dragons/dragons-pounce-04.png",
	]:
		var image := Image.load_from_file(path)
		assert(not image.is_empty())
		assert(image.get_pixel(0, 0).a == 0.0)
		if "claw-far" in path or "claw-near" in path or "claw-vertical" in path:
			assert(image.get_size() == Vector2i(512, 512))
			assert(image.get_used_rect().size.x >= 300 and image.get_used_rect().size.y >= 250)
		if "low-walk" in path:
			walk_heights.append(image.get_used_rect().size.y)
	assert(float(walk_heights.max()) / float(walk_heights.min()) < 1.10)
	var tuft_image := Image.load_from_file("res://assets/content/fight/effects/dragon-breath-fire-tuft.png")
	var tuft_rect := tuft_image.get_used_rect()
	for y in range(tuft_rect.position.y, tuft_rect.end.y, 8):
		for x in range(tuft_rect.position.x, tuft_rect.end.x, 8):
			var pixel := tuft_image.get_pixel(x, y)
			assert(pixel.a < 0.5 or pixel.r + pixel.g + pixel.b > 0.25)
	var fight_source := FileAccess.get_file_as_string("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
	assert("_frame_scale_to_idle" not in fight_source)
	assert("_guys_frame_scale" not in fight_source)

	print("dragon-specials-ok")
	quit(0)
