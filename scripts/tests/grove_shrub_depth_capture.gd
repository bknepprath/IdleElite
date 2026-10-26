extends "res://scripts/tests/action_art_oct22.gd"

func depth_for_floor_y(stage: Control,floor_y: float) -> float:
	var field: Rect2=stage.field_rect()
	return .32+(((floor_y-field.get_center().y)/(field.size.y*.5)+.38)/1.03)*.59

func check_tree_order(stage: Control,state: Dictionary,tree: Dictionary,shrub_id: String,in_front: bool) -> void:
	var tree_index: int=-1
	var shrub_index: int=-1
	var order: Array=stage.arena_draw_order(state)
	for index in order.size():
		var item: Dictionary=order[index]
		if item.has("tree") and item.tree==tree: tree_index=index
		if item.has("shrub") and str(item.shrub.id)==shrub_id: shrub_index=index
	check(tree_index>=0 and shrub_index>=0,"Tree and shrub both participate in floor-depth ordering")
	check((tree_index>shrub_index)==in_front,"Tree correctly sorts "+("in front of " if in_front else "behind ")+shrub_id)

func audit_action_art() -> void:
	var runtime=game._grove_runtime()
	runtime.reset()
	await open_notes_skill("woodcutting")
	var card:=await notes_card("grove-birch")
	if card.is_empty(): quit(1); return
	await align_notes_card(card)
	var stage: Control=card.grove_stage
	var state: Dictionary=runtime.state("grove-birch")
	check(stage.shrub_layers.size()==15,"All fifteen shrub clusters have ground anchors")
	var edge_layers: Array[Dictionary]=[]
	for shrub_id in ["shrub-14","shrub-15"]:
		for layer in stage.shrub_layers:
			if str(layer.id)==shrub_id: edge_layers.append(layer)
	check(edge_layers.size()==2,"Both front edge shrubs are identified")
	if edge_layers.size()!=2: quit(1); return
	for index in 2:
		var tree: Dictionary=state.trees[index]
		tree.x=110.0 if index==0 else 790.0
		tree.rare=false
		tree.bountiful=false
		tree.source_id="grove-birch"
	state.target=0
	for in_front in [false,true]:
		for index in 2:
			var tree: Dictionary=state.trees[index]
			var ground: Vector2=stage.shrub_ground_point(edge_layers[index])
			tree.y=clampf(depth_for_floor_y(stage,ground.y)+(.075 if in_front else -.075),.32,.91)
			check_tree_order(stage,state,tree,str(edge_layers[index].id),in_front)
		stage.queue_redraw()
		await settle(.2)
		await capture("trees-in-front-of-shrubs" if in_front else "trees-behind-shrubs")
	state.trees[1].y=clampf(depth_for_floor_y(stage,stage.shrub_ground_point(edge_layers[1]).y)-.075,.32,.91)
	stage.queue_redraw()
	await settle(.2)
	await capture("mixed-tree-depth")
	# Freeze simulation, not the real production hierarchy or its renderer, for
	# deterministic worker poses on both sides of the same shrub's floor anchor.
	game.set_process(false)
	runtime.worker_presence["grove-birch"]={"alpha":1.0,"entering":false}
	state.x=110.0
	state.phase="walking"
	state.age=.3
	for in_front in [false,true]:
		state.y=clampf(depth_for_floor_y(stage,stage.shrub_ground_point(edge_layers[0]).y)+(.075 if in_front else -.075),.32,.91)
		stage.queue_redraw()
		await settle(.2)
		await capture("worker-in-front-of-shrub" if in_front else "worker-behind-shrub")
	game.set_process(true)
	print("GROVE_SHRUB_DEPTH failures=",JSON.stringify(failures))
	var result:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
