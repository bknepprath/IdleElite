extends SceneTree

var game

func _init() -> void: call_deferred("run")

func run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES","1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS","1")
	AudioServer.set_bus_mute(0,true)
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game.skills.fight.xp=preload("res://scripts/progression/skill_state.gd").xp_for_level(12)
	game.skills.fight.level=12
	game._activity_unlock_runtime()._mark_action_manually_unlocked("fight","clear-rockslide")
	game.fishing_runtime.set_auto_eat_fish_enabled_for_skill(game,"fight",false)
	var runtime=game._rockslide_runtime()
	var report: Array[Dictionary]=[]
	for levels in [[0,0,0],[1,0,0],[0,1,0],[0,0,1],[0,6,0],[1,1,1],[2,2,2],[6,6,6]]:
		runtime.reset()
		runtime.upgrades={"power":levels[0],"speed":levels[1],"volley":levels[2]}
		game.running_skill_id="fight"
		game.running_action_id="clear-rockslide"
		game.stamina.fight=100000
		var seconds:=0.0
		while seconds<300 and not runtime.knocked_out():
			# Isolate combat pressure from food exhaustion in this audit.
			game.stamina.fight=100
			runtime.advance(.1)
			seconds+=.1
		report.append({"upgrades":levels,"first_knockout_seconds":snappedf(seconds,.1),"wave":runtime.wave(),"clears":runtime.clears,"shots":runtime.shots_fired})
	var output:=OS.get_environment("IDLE_ELITE_ROCKSLIDE_BALANCE_REPORT")
	if output.is_empty(): output="res://outputs/verification/rockslide-balance-oct25/current.json"
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file:=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ROCKSLIDE_BALANCE ",JSON.stringify(report))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0)
