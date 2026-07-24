extends SceneTree

const FightStage = preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")


func _init() -> void:
	var stage := FightStage.new()
	stage.set("enemy_id", "giants")
	stage.set("enemy_population_curve", [1.0, 1.3, 1.6, 1.9, 2.0])
	stage.set("wave_spawn_phase_duration_current", 6.0)
	var rolls := floor(6.0 / 0.25) - 1.0
	for wave in range(4):
		stage.set("wave_index", wave)
		stage.set("wave_spawned_count", 1)
		var per_roll := float(stage.call("_random_spawn_chance_per_roll"))
		var extra_spawn_chance := 1.0 - pow(1.0 - per_roll, rolls)
		assert(is_equal_approx(extra_spawn_chance, [0.0, 0.3, 0.6, 0.9][wave]))
	stage.free()
	print("giant-spawn-curve-ok")
	quit()
