extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var runtime=game._grove_runtime()
	runtime.reset()
	for material in game.material_runtime.material_defs: game.material_runtime.set_amount(str(material),1000)
	await open_notes_skill("woodcutting")
	for id in ["grove-birch","grove-ironwood"]:
		var card:=await notes_card(id)
		await align_notes_card(card)
		var stage: Control=card.grove_stage
		var state: Dictionary=runtime.state(id)
		check(state.trees.size()==2,"Two base trees in "+id)
		await capture(id+"-two-trees")
		var chosen_seed:=0
		for seed_value in 1000:
			runtime.rng.seed=seed_value
			var candidate: Dictionary=runtime.new_tree(id,[],1.0)
			if bool(candidate.bountiful)==(id=="grove-birch"):
				chosen_seed=seed_value
				break
		runtime.rng.seed=chosen_seed
		state.trees[0]=runtime.new_tree(id,[],1.0)
		state.trees[0].x=450.0
		state.trees[0].y=.86
		state.trees[0].hp=1
		state.target=0
		var material: String=runtime.tree_material(id,state.trees[0])
		var before_wood: float=game.material_runtime.amount(material)
		var before: int=runtime.felled
		await capture(id+"-before-harvest")
		game.stamina.woodcutting=100
		await click(stage.get_global_transform_with_canvas()*stage.world_point(450,.91),true)
		for frame in 1200:
			await process_frame
			if runtime.felled>before: break
		check(runtime.felled==before+1,"Actual chopping finishes "+id)
		var amount: int=int(game.material_runtime.amount(material)-before_wood)
		check(int(runtime.harvest_bursts.back().amount)==amount,"One sprite scheduled per awarded log")
		if id=="grove-birch": check(amount>=3,"Bountiful base tree awards extra logs")
		await settle(.35)
		await capture(id+"-harvest-sprites")
		await settle(.3)
		await capture(id+"-harvest-floating")
		await settle(1.2)
		await capture(id+"-harvest-settled")
		game._action_runtime()._stop_running_action("woodcutting",id)
	print("GROVE_REWARDS failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
