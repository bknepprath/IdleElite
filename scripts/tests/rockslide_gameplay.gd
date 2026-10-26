extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES","1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS","1")
	AudioServer.set_bus_mute(0,true)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game.skills.fight.xp = preload("res://scripts/progression/skill_state.gd").xp_for_level(12)
	game.skills.fight.level = 12
	game._activity_unlock_runtime()._mark_action_manually_unlocked("fight","clear-rockslide")
	var runtime = game._rockslide_runtime()
	var action: Dictionary = game._action_data("fight","clear-rockslide")
	check(not action.get("rockslide",{}).is_empty(),"Source definition reaches the runtime catalog")
	check(str(action.mat_rewards[0].id)=="sand","Sand source navigation can discover the new activity")
	check(not preload("res://scripts/progression/mastery_state.gd").action_has_mastery(game,action),"Rockslide has no medal system")
	var mastery_before: Dictionary=game.mastery.duplicate(true)
	game.running_skill_id = "fight"
	game.running_action_id = "clear-rockslide"
	game.stamina.fight = 20.0
	game.material_runtime.set_amount("sand",0)
	var xp_before := int(game.skills.fight.xp)
	var cost: float = game._action_runtime()._effective_stamina("fight",action)
	var reward: int = game._action_runtime()._effective_xp_reward_map(action,"fight").get("fight",0)
	runtime.advance(.2)
	check(runtime.rocks.size()==1,"A real boulder spawns without a mounted UI stage")
	check(runtime.shots.is_empty(),"Opening shot waits for the full slower wind-up")
	var root_id: int = runtime.rocks.keys()[0]
	runtime.hit_rock(root_id,1)
	check(int(runtime.rocks[root_id].hp)==4 and int(game.skills.fight.xp)==xp_before,"Impacts change real HP and pay no premature rewards")
	runtime.hit_rock(root_id,99)
	check(runtime.rocks.size()==2 and runtime.splits==1,"Broken large rock becomes two live fragments")
	var fragments: Array = runtime.rocks.values()
	check(float(fragments[0].vx)<0 and float(fragments[1].vx)>0 and float(fragments[0].vy)!=float(fragments[1].vy),"Fragments separate into distinct physical arcs")
	for id in runtime.rocks.keys(): runtime.hit_rock(id,99)
	runtime.advance(.02)
	check(runtime.lifetime_clears==1 and game.material_runtime.amount("sand")==1,"Clearing both fragments awards exactly one Sand")
	check(game.mastery==mastery_before,"Rockslide never grants mastery")
	check(int(game.skills.fight.xp)==xp_before+reward,"Whole group awards XP exactly once")
	check(is_equal_approx(float(game.stamina.fight),20.0-cost),"One stamina charge per completed group")
	runtime.advance(.02)
	check(runtime.lifetime_clears==1,"A cleared group cannot pay twice")
	var prior_shots: int = runtime.shots_fired
	for frame in 600: game._action_runtime()._process_action(1.0/60.0)
	check(runtime.shots_fired>prior_shots and runtime.impacts>3,"Mounted artwork is not required for automatic shooting and hits")
	check(int(game.skills.fight.xp)==xp_before+reward*runtime.lifetime_clears,"Normal timed activity loop cannot also grant XP")
	game.material_runtime.set_amount("scrapwood",0)
	check(not runtime.buy_upgrade("power") and int(runtime.upgrades.power)==0,"Unpaid upgrades are rejected")
	game.material_runtime.set_amount("scrapwood",10000)
	game.material_runtime.set_amount("softwood",10000)
	game.material_runtime.set_amount("wooden-parts",10000)
	game.material_runtime.set_amount("hardwood",10000)
	game.material_runtime.set_amount("ironwood",10000)
	var old_interval: float = runtime.shot_interval()
	check(runtime.buy_upgrade("power") and runtime.shot_damage()==2 and game.material_runtime.amount("scrapwood")==9985,"Power purchase spends the exact material cost and changes damage")
	check(runtime.buy_upgrade("speed") and runtime.shot_interval()<old_interval,"Speed purchase changes actual shot cadence")
	check(runtime.buy_upgrade("volley") and runtime.volley_size()==2,"The first Volley upgrade adds a real projectile")
	check(runtime.buy_upgrade("volley") and runtime.volley_size()==3,"Each Volley upgrade increases the projectile count")
	runtime.clear_transient()
	runtime.groups[800] = {"remaining":2,"failed":false}
	var near_id: int = runtime.spawn_rock(800,600,true)
	var far_id: int = runtime.spawn_rock(800,700,true)
	runtime.spawn_clock = 10
	runtime.shot_clock = 0
	runtime.step(.01)
	check(int(runtime.shots[0].target)==near_id and int(runtime.shots[1].target)==far_id,"Volley reserves lethal damage and spreads onto the next fragment")
	for i in 8: runtime.buy_upgrade("power")
	check(int(runtime.upgrades.power)==6 and runtime.upgrade_cost("power").is_empty(),"Upgrade levels and costs stop at their cap")
	runtime.clear_transient()
	runtime.groups[4000]={"remaining":1,"failed":false}
	var runner: int=runtime.spawn_rock(4000,700,false,0.0,"runner")
	runtime.hit_rock(runner,99)
	check(runtime.rocks.is_empty() and int(runtime.groups[4000].remaining)==0,"Fast stones finish without phantom fragments or stalled groups")
	runtime.groups.clear()
	runtime.groups[4001]={"remaining":1,"failed":false}
	var armored: int=runtime.spawn_rock(4001,700,false,0.0,"armored")
	var armored_hp: int=runtime.rocks[armored].hp
	runtime.hit_rock(armored,3)
	check(int(runtime.rocks[armored].hp)==armored_hp-2,"Armored rock absorbs one damage per hit")
	runtime.hit_rock(armored,99)
	check(runtime.rocks.size()==3 and int(runtime.groups[4001].remaining)==3,"Armored rock tracks all three real fragments")
	for id in runtime.rocks.keys(): runtime.hit_rock(id,99)
	check(int(runtime.groups[4001].remaining)==0,"Every armored fragment must be cleared before payment")
	runtime.clear_transient()
	runtime.spawn_clock=100
	runtime.groups[4002]={"remaining":1,"failed":false}
	var rolling: int=runtime.spawn_rock(4002,700,false)
	for frame in 60: runtime.step(1.0/60.0)
	check(float(runtime.rocks[rolling].lift)==0.0 and float(runtime.rocks[rolling].vy)==0.0,"Settled boulders roll without a perpetual artificial hop")
	runtime.clear_transient()
	runtime.clears=0
	runtime.spawn_encounter()
	check(runtime.rocks.size()==1 and str(runtime.rocks.values()[0].kind)=="boulder","Opening encounter starts with a readable ordinary boulder")
	runtime.rocks.clear()
	runtime.groups.clear()
	runtime.spawn_encounter()
	check(runtime.rocks.size()==1 and str(runtime.rocks.values()[0].kind)=="runner","Opening pattern changes to fast stones before wave two")
	runtime.clear_transient()
	runtime.clears=8
	runtime.spawn_encounter()
	check(str(runtime.rocks.values()[0].kind)=="armored","Wave three introduces the armored rock mechanic")
	var earned_speed: int=runtime.upgrades.speed
	runtime.upgrades.speed=2
	check(str(runtime.upgrade_cost("speed").id)=="wooden-parts","Speed cannot be maxed using only a pile of Softwood")
	runtime.upgrades.speed=4
	check(str(runtime.upgrade_cost("speed").id)=="ironwood","Late Speed upgrades require later-game wood")
	runtime.upgrades.speed=earned_speed
	var saved: Dictionary = game._save_runtime()._save_payload(int(Time.get_unix_time_from_system()))
	var round_trip: Dictionary = JSON.parse_string(JSON.stringify(saved.rockslide))
	runtime.reset()
	runtime.restore(round_trip)
	for kind in ["power","speed","volley"]:
		check(int(runtime.upgrades[kind])==int(round_trip.upgrades[kind]),"Real save payload restores upgrade: "+kind)
	check(runtime.lifetime_clears==int(round_trip.lifetime_clears),"Real save payload restores cleared groups")
	check(runtime.rocks.is_empty() and runtime.shots.is_empty(),"Loading cannot replay an already rewarded fragment")
	game.fishing_runtime.set_auto_eat_fish_enabled_for_skill(game,"fight",false)
	game.stamina.fight = 0
	var pending_clears: int = runtime.lifetime_clears
	runtime.groups[900] = {"remaining":0,"failed":false}
	runtime.finish_group(900)
	check(runtime.groups.has(900) and runtime.lifetime_clears==pending_clears,"An unpaid group waits rather than awarding free resources")
	game.stamina.fight = 10
	runtime.finish_group(900)
	check(not runtime.groups.has(900) and runtime.lifetime_clears==pending_clears+1,"Replenishing stamina completes a waiting group exactly once")
	var old_cloud := {"rockslide":runtime.for_save()}
	var downgraded: Dictionary = old_cloud.duplicate(true)
	downgraded.rockslide.upgrades.power = 0
	check(preload("res://scripts/save_state/normalizers.gd").payload_regresses_game_progress(old_cloud,downgraded,game.skill_defs),"An older cloud save cannot erase slingshot upgrades")
	runtime.clear_transient()
	var fail_xp := int(game.skills.fight.xp)
	for index in 3:
		var group_id: int = 1000+index
		runtime.groups[group_id] = {"remaining":1,"failed":false}
		var escaping: int = runtime.spawn_rock(group_id,229,false)
		runtime.escape_rock(escaping)
	check(runtime.active() and runtime.knocked_out() and runtime.integrity==0 and int(game.skills.fight.xp)==fail_xp,"Three escaped groups enter knockout without stopping the idle activity or granting rewards")
	check(runtime.rocks.is_empty() and runtime.groups.is_empty() and runtime.shots.is_empty(),"Knockout discards all unpaid rocks and in-flight shots")
	var paid_upgrades: Dictionary=runtime.upgrades.duplicate()
	var paid_clears: int=runtime.lifetime_clears
	var best_wave: int=runtime.best_wave
	var knocked_save: Dictionary=runtime.for_save()
	runtime.restore(JSON.parse_string(JSON.stringify(knocked_save)))
	check(runtime.knocked_out() and runtime.integrity==0,"Save restore retains a live knockout")
	for tick in 120: runtime.advance(1.0/60.0)
	check(runtime.knocked_out() and runtime.shots.is_empty() and runtime.rocks.is_empty(),"Knockout pauses shooting and spawning while its timer advances")
	check(runtime.lifetime_clears==paid_clears and int(game.skills.fight.xp)==fail_xp,"Knockout grants no rewards")
	for tick in 200: runtime.advance(1.0/60.0)
	check(runtime.active() and not runtime.knocked_out() and runtime.wave()==1 and runtime.integrity==3,"Knockout automatically recovers to wave one")
	check(runtime.upgrades==paid_upgrades and runtime.lifetime_clears==paid_clears and runtime.best_wave==best_wave,"Recovery retains purchased upgrades, lifetime clears and best wave")
	runtime.advance(.2)
	check(not runtime.rocks.is_empty(),"Wave one spawns again without another tap")
	for index in 3:
		var group_id: int=2000+index
		runtime.groups[group_id]={"remaining":1,"failed":false}
		var escaping: int=runtime.spawn_rock(group_id,229,false)
		runtime.escape_rock(escaping)
	check(runtime.knocked_out(),"The next run can knock out and repeat")
	game._action_runtime()._stop_running_action("fight","clear-rockslide")
	for tick in 400: runtime.advance(1.0/60.0)
	check(not runtime.active() and not runtime.knocked_out(),"Manually stopping during recovery never restarts the activity")
	game.running_skill_id = "fight"
	game.running_action_id = "clear-rockslide"
	var before_offline := int(game.skills.fight.xp)
	check(not bool(game._action_runtime()._apply_offline_active_action(3600).handled) and int(game.skills.fight.xp)==before_offline,"Offline loading does not invent timed rockslide completions")
	runtime.restore({"upgrades":{"power":999,"speed":-20,"volley":"bad"},"lifetime_clears":"bad","best_wave":-4})
	check(runtime.upgrades=={"power":6,"speed":0,"volley":0} and runtime.lifetime_clears==0 and runtime.best_wave==1,"Malformed saves clamp safely")
	game._save_runtime()._init_state()
	check(runtime.upgrades=={"power":0,"speed":0,"volley":0} and runtime.lifetime_clears==0,"Reset Data clears the new progression")
	print("ROCKSLIDE_GAMEPLAY failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
