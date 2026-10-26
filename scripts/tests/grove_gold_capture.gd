extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var runtime=game._grove_runtime()
	runtime.reset()
	await open_notes_skill("woodcutting")
	for id in runtime.IDS:
		runtime.arena_levels(id).capacity=2
		var card:=await notes_card(id)
		if card.is_empty(): continue
		await align_notes_card(card)
		var state: Dictionary=runtime.state(id)
		while state.trees.size()<4: state.trees.append(runtime.new_tree(id,state.trees))
		for index in 4:
			var tree: Dictionary=state.trees[index]
			tree.x=[135.0,345.0,555.0,765.0][index]
			tree.y=.80
			tree.rare=index>0
			tree.bountiful=index>0
			tree.gold_leaves=index
			tree.source_id=id
			tree.hp=1
			check(runtime.tree_gold_leaf_count(id,tree)==index,"Exact visible leaf count for level "+str(index)+": "+id)
		state.target=3
		check(not runtime.tree_has_bonus_yield(id,state.trees[0]),"Normal tree has no bonus indicator: "+id)
		check(runtime.tree_has_bonus_yield(id,state.trees[1]),"Bountiful tree has a bonus indicator: "+id)
		card.grove_stage.queue_redraw()
		await settle(.15)
		await capture(id+"-leaf-levels")
		if id!="grove-birch": continue
		await settle(.65)
		await capture("leaves-standing")
		var stage: Control=card.grove_stage
		game.stamina.woodcutting=100
		await click(stage.get_global_transform_with_canvas()*stage.world_point(765,.80),true)
		for frame in 1400:
			await process_frame
			if state.phase=="falling" and float(state.age)>.62: break
		check(state.phase=="falling","Bountiful tree falls through actual gameplay")
		await capture("leaves-follow-falling-tree")
		for frame in 500:
			await process_frame
			if state.trees[3].phase=="stump": break
		check(state.trees[3].phase=="stump","Gold leaves leave with the canopy")
		await settle(.3)
		await capture("leaves-cleared-after-harvest")
		game._action_runtime()._stop_running_action("woodcutting",id)
	print("GROVE_GOLD failures=",JSON.stringify(failures))
	var result:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
