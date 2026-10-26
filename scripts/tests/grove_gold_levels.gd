extends SceneTree

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
	var runtime=game._grove_runtime()
	runtime.rng.seed=251025
	for id in runtime.IDS:
		var base_average: float=(runtime.minimum_yield(id)+runtime.maximum_yield(id))*.5
		for level in [1,2,3]:
			var tree: Dictionary={"bountiful":true,"rare":true,"source_id":id,"gold_leaves":level}
			var multiplier: float=[1.25,1.75,3.0][level-1]
			check(is_equal_approx(runtime.tree_multiplier(id,tree),multiplier),"Configured harvest multiplier: "+id+" / "+str(level))
			check(runtime.tree_gold_leaf_count(id,tree)==level,"Leaf count matches gameplay level")
			check(runtime.tree_health(id,tree)==int(runtime.rules(id).health),"Bonus does not add tree health")
			check(runtime.tree_xp_rewards(id,tree)==runtime.tree_xp_rewards(id,{}),"Bonus changes logs only")
			var total:=0
			for sample in 12000:
				var amount: int=runtime.roll_tree_yield(id,tree)
				total+=amount
				check(amount>=runtime.tree_minimum_yield(id,tree) and amount<=runtime.tree_maximum_yield(id,tree),"Fractional harvest remains within its possible bounds")
			var mean:=float(total)/12000.0
			check(absf(mean-base_average*multiplier)<base_average*.035,"Actual average harvest honors the small/intermediate/full bonus: "+id+" / "+str(level))
			print("GOLD_LEAF_MEAN ",id," level=",level," actual=",mean," expected=",base_average*multiplier)
		var counts: Array[int]=[0,0,0]
		for sample in 12000: counts[runtime.roll_bountiful_level(id)-1]+=1
		for index in 3: check(absf(float(counts[index])/12000.0-[.6,.3,.1][index])<.025,"Bonus levels follow source spawn weights: "+id)
		check(runtime.tree_gold_leaf_count(id,{})==0,"Normal trees have no gold leaves")
		check(runtime.bountiful_level({"bountiful":true})==3,"Unversioned bonus trees retain full bonus")
		runtime.arena_levels(id).capacity=1
		var state: Dictionary=runtime.state(id)
		for index in 3:
			state.trees[index].rare=true
			state.trees[index].bountiful=true
			state.trees[index].source_id=id
			state.trees[index].gold_leaves=index+1
	var saved: Dictionary=runtime.for_save()
	runtime.restore(JSON.parse_string(JSON.stringify(saved)))
	for id in runtime.IDS:
		for index in 3: check(runtime.bountiful_level(runtime.state(id).trees[index])==index+1,"All gold-leaf levels survive save roundtrip: "+id)
	var legacy: Dictionary=saved.duplicate(true)
	legacy.version=4
	for id in runtime.IDS:
		for tree in legacy.groves[id].trees: tree.erase("gold_leaves")
	runtime.restore(legacy)
	for id in runtime.IDS:
		for tree in runtime.state(id).trees: check(runtime.bountiful_level(tree)==3 and is_equal_approx(runtime.tree_multiplier(id,tree),3.0),"Legacy bonus trees retain triple logs: "+id)
	print("GROVE_GOLD_LEVELS failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
