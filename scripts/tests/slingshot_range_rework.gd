extends SceneTree

const SkillState=preload("res://scripts/progression/skill_state.gd")
const MasteryState=preload("res://scripts/progression/mastery_state.gd")
var failures: Array[String]=[]
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message);push_error(message)
func run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES","1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS","1")
	AudioServer.set_bus_mute(0,true)
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._activity_unlock_runtime()._mark_action_manually_unlocked("fight","practice-slingshot")
	game.skills.fight.xp=SkillState.xp_for_level(40)
	game.skills.fight.level=40
	game.stamina.fight=40
	game.running_skill_id="fight"
	game.running_action_id="practice-slingshot"
	var runtime=game._slingshot_range_runtime()
	check(not MasteryState.action_has_mastery(game,game._action_data("fight","practice-slingshot")),"Range is not a medal activity")
	check(runtime.sample_distance(80,0)>runtime.sample_distance(6,1),"Level growth creates distinctly longer shots")
	check((runtime.sample_distance(80,1)-runtime.sample_distance(80,0))/runtime.sample_distance(80,1)<(runtime.sample_distance(6,1)-runtime.sample_distance(6,0))/runtime.sample_distance(6,1),"Higher level narrows relative dispersion")
	check(not runtime.has_method("tap_release"),"There is no tappable timing boost")
	var action: Dictionary=game._action_data("fight","practice-slingshot")
	var cost: float=game._action_runtime()._effective_stamina("fight",action)
	runtime.age=runtime.draw_seconds()*.3
	runtime.advance(.1)
	check(game.stamina.fight==40,"Drawing does not consume stamina")
	var xp: int=game.skills.fight.xp
	for shot_number in 20:
		var before: float=game.stamina.fight
		check(runtime.launch(),"Funded shot releases")
		check(is_equal_approx(game.stamina.fight,before-cost),"Every release consumes the exact effective cost")
		check(not runtime.launch() and is_equal_approx(game.stamina.fight,before-cost),"An airborne shot cannot be charged twice")
		check(runtime.release_feedback_seconds>0 and is_equal_approx(runtime.last_stamina_cost,cost),"Release feedback shows the actual paid cost")
		xp+=runtime.earned_xp
		runtime.land()
		runtime.land()
		check(game.skills.fight.xp==xp and runtime.landings==shot_number+1,"XP is paid exactly once at ground contact")
	check(is_equal_approx(game.stamina.fight,40-20*cost),"Twenty shots have twenty payments")
	game.stamina.fight=20
	game.stamina_bank.fight=game.STAMINA_REGEN_SECONDS-.001
	game._action_runtime()._bank_stamina_regen("fight",.01,SkillState.max_stamina(game,"fight"))
	var regenerated: float=game.stamina.fight
	runtime.launch()
	check(is_equal_approx(game.stamina.fight,regenerated-cost),"Regeneration never makes a shot free")
	var shot: Dictionary=JSON.parse_string(JSON.stringify(runtime.for_save()))
	var paid: float=game.stamina.fight
	runtime.restore(shot)
	game.running_skill_id=""
	for frame in 24: runtime.advance(.1)
	check(game.skills.fight.xp==xp+int(shot.earned_xp),"Reloaded paid shot lands while away and awards its saved XP")
	check(game.stamina.fight==paid,"Restore never charges the paid shot again")
	runtime.restore({"version":1,"best_distance":200,"landings":7,"phase":"flying","distance":8,"earned_xp":7,"flight_seconds":1.3,"age":1.2})
	runtime.advance(.2)
	check(runtime.landings==8 and runtime.best_distance==200,"Legacy airborne saves keep records and their exact paid reward")
	runtime.reset()
	game.running_skill_id="fight"
	game.stamina.fight=0
	game.stamina_bank.fight=0
	game.fishing_runtime.fish_currency=0
	check(not runtime.launch() and runtime.phase=="ready","Exhaustion cannot launch a free projectile")
	game.stamina.fight=10
	runtime.age=0
	for frame in 18: runtime.advance(.1)
	check(runtime.phase=="flying" and not runtime.clean_release and is_equal_approx(game.stamina.fight,10-cost),"Idle shooting releases and pays automatically")
	runtime.reset()
	game.skills.build.xp=SkillState.xp_for_level(20)
	game.skills.build.level=20
	var hub=game._hub_runtime()
	hub.hub_modules.mission={"level":1,"building":false}
	hub.hub_missions=[{"skill_id":"fight","action_id":"practice-slingshot","remaining":100}]
	game._action_runtime().invalidate_stat_cache()
	var discounted: float=game._action_runtime()._effective_stamina("fight",action)
	check(discounted>0 and discounted<1,"Mission board supplies a real fractional stamina discount")
	game.stamina.fight=9.9
	check(runtime.launch() and is_equal_approx(game.stamina.fight,9.9-discounted),"Discounted release pays its exact fractional cost")
	check(SkillState.host_stamina_int("fight",game)==9,"A paid discounted shot can leave the displayed integer unchanged")
	for level in [6,25,50,99]:
		var distance: float=runtime.sample_distance(level,.5)
		var old_reward:=roundi(5+distance*.25)
		var new_reward:=roundi(2+distance*.08)
		check(float(new_reward)/old_reward<=.45,"XP is reduced by at least 55 percent at representative levels")
		print("SLINGSHOT_BALANCE level=",level," old_xp=",old_reward," new_xp=",new_reward)
	print("SLINGSHOT_RANGE_REWORK failures=",JSON.stringify(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
