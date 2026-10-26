extends SceneTree
const SkillState=preload("res://scripts/progression/skill_state.gd")
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
	for skill in ["woodcutting","fight"]:
		game.skills[skill].xp=SkillState.xp_for_level(80)
		game.skills[skill].level=80
		game.stamina[skill]=100
	var grove=game._grove_runtime()
	grove.rng.seed=725
	for id in grove.IDS: game._activity_unlock_runtime()._mark_action_manually_unlocked("woodcutting",id)
	for material in game.material_runtime.material_defs: game.material_runtime.set_amount(str(material),1000)
	var entrance: Dictionary=grove.state("grove-birch")
	check(grove.worker_opacity("grove-birch")==0,"Inactive worker starts invisible")
	game.running_skill_id="woodcutting"
	game.running_action_id="grove-birch"
	grove.advance(.1)
	check(grove.worker_opacity("grove-birch")>0 and grove.worker_opacity("grove-birch")<1,"Starting a grove fades the worker in")
	check(entrance.x==450.0 and entrance.y==.91 and entrance.age==0.0,"Entry remains front center until visible")
	for frame in 5: grove.advance(.1)
	check(not grove.worker_entering("grove-birch") and grove.worker_opacity("grove-birch")==1,"Entry settles before the normal action")
	game.running_skill_id=""
	for frame in 4: grove.advance(.1)
	check(grove.worker_opacity("grove-birch")==0,"Stopping a grove fades the worker completely out")
	for kind in grove.KINDS:
		var cost: Dictionary=grove.upgrade_cost(kind)
		var before: float=game.material_runtime.amount(str(cost.id))
		check(grove.buy_upgrade(kind),"Buy axe component: "+kind)
		check(game.material_runtime.amount(str(cost.id))==before-float(cost.amount),"Exact component price: "+kind)
	check(grove.swing_seconds("grove-birch")<1,"Handle speeds up swings")
	check(grove.minimum_yield("grove-birch")==2 and grove.maximum_yield("grove-birch")==3,"Head and sharpening change real harvest bounds")
	check(grove.buy_upgrade("sharpening"),"Sharpening can meet current maximum")
	check(not grove.buy_upgrade("sharpening"),"Sharpening cannot charge for an upgrade with no harvest effect")
	check(grove.buy_upgrade("head") and grove.maximum_yield("grove-birch")==4,"Head always increases maximum harvest")
	for id in grove.IDS:
		var action: Dictionary=game._action_data("woodcutting",id)
		var initial: Dictionary=grove.state(id)
		check(initial.trees.size()==2,"Two trees populate the ground plane: "+id)
		var depth_min: float=1
		var depth_max: float=0
		for tree in initial.trees:
			check(float(tree.x)>=110 and float(tree.x)<=790 and float(tree.y)>=.32 and float(tree.y)<=.91,"Spawn remains inside the authored field")
			depth_min=minf(depth_min,float(tree.y))
			depth_max=maxf(depth_max,float(tree.y))
		check(Vector2(float(initial.trees[0].x)-float(initial.trees[1].x),(float(initial.trees[0].y)-float(initial.trees[1].y))*360).length()>116,"Initial trees leave walking clearance: "+id)
		check(not action.grove.is_empty(),"Source rules reach catalog: "+id)
		check(not preload("res://scripts/progression/mastery_state.gd").action_has_mastery(game,action),"Tree arenas have no mastery: "+id)
		var old_mastery: Dictionary=game.mastery.duplicate(true)
		game.running_skill_id="woodcutting"
		game.running_action_id=id
		game.stamina.woodcutting=100
		var before: int=grove.felled
		var xp_before: int=game.skills.woodcutting.xp
		var selected_material: String=grove.tree_material(id,initial.trees[0])
		var wood_before: float=game.material_runtime.amount(selected_material)
		for step in 1800:
			grove.advance(.1)
			if grove.felled>before: break
		check(grove.felled==before+1,"Walking, chopping, falling produce a real harvest: "+id)
		check(game.material_runtime.amount(selected_material)>wood_before,"Matching wood awarded: "+id)
		check(game.skills.woodcutting.xp>xp_before,"XP only on harvest: "+id)
		var state: Dictionary=grove.state(id)
		check(state.trees[int(state.last_index)].phase=="stump","Felled tree becomes a stump: "+id)
		var old_position:=Vector2(float(state.trees[int(state.last_index)].x),float(state.trees[int(state.last_index)].y))
		check(not grove.harvest(id),"Repeated harvest cannot duplicate grants")
		check(game.mastery==old_mastery,"Harvest never earns medals: "+id)
		game.running_skill_id=""
		var clear_time: float=grove.stump_clear_seconds(id)
		check(grove.regrowth_seconds(id)-clear_time>=1.0,"Stump clears with a visible gap before regrowth: "+id)
		for step in ceili((clear_time+.1)/.1): grove.advance(.1)
		var stump: Dictionary=state.trees[int(state.last_index)]
		check(stump.phase=="stump" and grove.stump_opacity(id,stump)==0.0,"Stump disappears while its original regrowth timer is still running: "+id)
		for step in 200: grove.advance(.1)
		check(state.trees[int(state.last_index)].phase=="standing","Tree respawns: "+id)
		var new_position:=Vector2(float(state.trees[int(state.last_index)].x),float(state.trees[int(state.last_index)].y))
		check(new_position!=old_position,"Respawn selects a fresh random position: "+id)
	var arena_id: String="grove-birch"
	var capacity_before: int=grove.tree_capacity(arena_id)
	var cost: Dictionary=grove.arena_upgrade_cost(arena_id,"capacity")
	var wood_before: float=game.material_runtime.amount(str(cost.id))
	check(grove.buy_arena_upgrade(arena_id,"capacity"),"Arena capacity can be purchased")
	check(grove.tree_capacity(arena_id)==capacity_before+1 and grove.state(arena_id).trees.size()==capacity_before+1,"Capacity creates one additional live tree")
	check(game.material_runtime.amount(str(cost.id))==wood_before-float(cost.amount),"Arena upgrade charges exactly once")
	check(grove.tree_capacity("grove-pine")==2,"Arena upgrades remain local to their grove")
	var regrowth_before: float=grove.regrowth_seconds(arena_id)
	check(grove.buy_arena_upgrade(arena_id,"regrowth") and grove.regrowth_seconds(arena_id)<regrowth_before,"Regrowth upgrade shortens actual respawn time")
	var regrowth_state: Dictionary=grove.state(arena_id)
	regrowth_state.trees[0].phase="stump"
	regrowth_state.trees[0].age=grove.regrowth_seconds(arena_id)-.05
	game.running_skill_id=""
	grove.advance(.1)
	check(regrowth_state.trees[0].phase=="standing","Upgraded timer actually regrows a tree before the old deadline")
	var chance_before: float=grove.rare_chance(arena_id)
	check(grove.buy_arena_upgrade(arena_id,"rarity") and grove.rare_chance(arena_id)>chance_before,"Rarity upgrade increases the actual spawn chance")
	var saved_chance: float=grove.rules(arena_id).rare_chance
	grove.rules(arena_id).rare_chance=100
	var rare: Dictionary=grove.new_tree(arena_id,[])
	grove.rules(arena_id).rare_chance=saved_chance
	check(rare.rare and rare.bountiful and grove.source_id(arena_id,rare)==arena_id and rare.hp==grove.rules(arena_id).health,"Rare rolls retain the base tree type and durability")
	check(int(rare.gold_leaves) in [1,2,3],"New bonus trees roll a saved gold-leaf level")
	rare.gold_leaves=3
	var rare_xp: Dictionary=grove.tree_xp_rewards(arena_id,rare)
	check(int(rare_xp.woodcutting)==int(grove.tree_xp_rewards(arena_id,{}).woodcutting) and grove.tree_maximum_yield(arena_id,rare)==grove.maximum_yield(arena_id)*3,"Bountiful trees triple logs without changing base XP")
	var iron_id: String="grove-ironwood"
	var iron_chance: float=grove.rules(iron_id).rare_chance
	grove.rules(iron_id).rare_chance=100
	var iron: Dictionary=grove.new_tree(iron_id,[])
	grove.rules(iron_id).rare_chance=iron_chance
	check(iron.hp==grove.rules(iron_id).health and grove.tree_material(iron_id,iron)=="ironwood" and grove.tree_maximum_yield(iron_id,iron)>grove.maximum_yield(iron_id),"Bountiful Ironwood has base durability and extra Ironwood yield")
	var scene: Dictionary=grove.state(arena_id)
	scene.trees[0]=rare
	scene.trees[0].phase="falling"
	scene.trees[0].hp=0
	scene.target=0
	scene.phase="falling"
	game.stamina.woodcutting=100
	var xp_before: int=game.skills.woodcutting.xp
	var rare_material: String=grove.tree_material(arena_id,rare)
	wood_before=game.material_runtime.amount(rare_material)
	check(grove.harvest(arena_id),"Rare tree completes through the real harvest path")
	check(game.skills.woodcutting.xp==xp_before+int(rare_xp.woodcutting) and game.material_runtime.amount(rare_material)>wood_before,"Bountiful tree pays its own wood and XP exactly once")
	check(int(grove.harvest_bursts.back().amount)==int(game.material_runtime.amount(rare_material)-wood_before),"Harvest animation event contains exactly the awarded log count")
	check(not grove.harvest(arena_id),"Rare tree cannot pay twice")
	game.material_runtime.set_amount(str(grove.rules(arena_id).material),100000)
	for step in 5: check(grove.buy_arena_upgrade(arena_id,"capacity"),"Additional capacity level is available")
	check(grove.tree_capacity(arena_id)==8 and not grove.buy_arena_upgrade(arena_id,"capacity"),"Capacity cap prevents further charges")
	var save: Dictionary=grove.for_save()
	grove.reset()
	grove.restore(JSON.parse_string(JSON.stringify(save)))
	check(grove.axe_xp==int(save.axe_xp) and grove.upgrades==save.upgrades and grove.arena_upgrades==save.arena_upgrades,"Axe state round trips")
	for id in grove.IDS:
		for index in grove.state(id).trees.size():
			var saved_tree: Dictionary=save.groves[id].trees[index]
			var restored_tree: Dictionary=grove.state(id).trees[index]
			check(is_equal_approx(float(saved_tree.x),float(restored_tree.x)) and is_equal_approx(float(saved_tree.y),float(restored_tree.y)),"Ground positions survive saving without rerolling")
	var modern: Dictionary=grove.for_save()
	var legacy: Dictionary=modern.duplicate(true)
	legacy.version=3
	legacy.erase("arena_upgrades")
	legacy.groves["grove-birch"].target=7
	legacy.groves["grove-birch"].trees[7].phase="falling"
	legacy.groves["grove-birch"].trees[7].hp=0
	grove.restore(legacy)
	check(grove.state("grove-birch").target==0 and grove.state("grove-birch").trees[0].phase=="falling","Reducing the base preserves an old saved fall beyond the new capacity")
	legacy=modern.duplicate(true)
	legacy.version=1
	legacy.erase("arena_upgrades")
	legacy.groves["grove-birch"].trees=legacy.groves["grove-birch"].trees.slice(0,3)
	grove.restore(legacy)
	check(grove.state("grove-birch").trees.size()==2 and grove.axe_xp==int(modern.axe_xp),"Old saves retain progress with the new two-tree base")
	grove.restore(modern)
	game.running_skill_id="woodcutting"
	game.running_action_id="grove-birch"
	var s: Dictionary=grove.state("grove-birch")
	s.phase="falling"
	s.target=0
	s.trees[0].phase="falling"
	s.trees[0].hp=0
	game.stamina.woodcutting=0
	game.stamina_bank.woodcutting=0
	game.fishing_runtime.fish_currency=0
	var pending: int=grove.felled
	check(not grove.harvest("grove-birch") and grove.felled==pending,"No free wood without stamina")
	game.stamina.woodcutting=10
	check(grove.harvest("grove-birch") and grove.felled==pending+1,"Waiting tree pays once when stamina returns")
	var range_runtime=game._slingshot_range_runtime()
	game._activity_unlock_runtime()._mark_action_manually_unlocked("fight","practice-slingshot")
	check(range_runtime.sample_distance(80,0)>range_runtime.sample_distance(6,1),"High level minimum range exceeds low level best")
	var spread_low: float=(range_runtime.sample_distance(6,1)-range_runtime.sample_distance(6,0))/range_runtime.sample_distance(6,1)
	var spread_high: float=(range_runtime.sample_distance(80,1)-range_runtime.sample_distance(80,0))/range_runtime.sample_distance(80,1)
	check(spread_high<spread_low,"Higher levels have tighter relative dispersion")
	game.running_skill_id="fight"
	game.running_action_id="practice-slingshot"
	game.stamina.fight=100
	var xp: int=game.skills.fight.xp
	range_runtime.launch()
	var paid_stamina: float=game.stamina.fight
	check(range_runtime.phase=="flying" and game.skills.fight.xp==xp,"Launch pays stamina without awarding XP")
	var shot: Dictionary=JSON.parse_string(JSON.stringify(range_runtime.for_save()))
	range_runtime.restore(shot)
	game.running_skill_id=""
	for frame in 30: range_runtime.advance(.1)
	check(range_runtime.landings==1 and game.skills.fight.xp==xp+int(shot.earned_xp),"Paid airborne shot survives reload and switching then awards on landing")
	check(game.stamina.fight==paid_stamina,"Restored shot does not charge again")
	range_runtime.land()
	check(range_runtime.landings==1,"Landing cannot pay twice")
	var old: Dictionary={"groves":grove.for_save(),"slingshot_range":range_runtime.for_save()}
	var bad: Dictionary=old.duplicate(true)
	bad.groves.axe_xp=0
	check(preload("res://scripts/save_state/normalizers.gd").payload_regresses_game_progress(old,bad,game.skill_defs),"Cloud guards earned axe progress")
	bad=old.duplicate(true)
	bad.groves.arena_upgrades["grove-birch"].capacity=0
	check(preload("res://scripts/save_state/normalizers.gd").payload_regresses_game_progress(old,bad,game.skill_defs),"Cloud guards purchased arena upgrades")
	game.running_skill_id="woodcutting"
	game.running_action_id="grove-birch"
	check(not game._action_runtime()._apply_offline_active_action(3600).handled,"Offline loading cannot synthesize normal grove completions")
	print("GROVES_RANGE failures=",JSON.stringify(failures))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

