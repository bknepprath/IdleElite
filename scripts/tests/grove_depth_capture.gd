extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var runtime=game._grove_runtime()
	runtime.reset()
	runtime.axe_xp=1220
	game.material_runtime.set_amount("softwood",321)
	runtime.arena_levels("grove-birch").capacity=1
	await open_notes_skill("woodcutting")
	var card:=await notes_card("grove-birch")
	await align_notes_card(card)
	var stage: Control=card.grove_stage
	var state: Dictionary=runtime.state("grove-birch")
	for index in 3:
		var tree: Dictionary=state.trees[index]
		tree.x=float([110,790,450][index])
		tree.y=float([.6,.6,.32][index])
		tree.rare=false
		tree.bountiful=false
		tree.source_id="grove-birch"
		tree.hp=100
	state.target=2
	stage.queue_redraw()
	await settle(.15)
	check(stage.top_stats(state,"grove-birch")[0].text=="321","Header shows current wood inventory")
	await capture("edge-trees-and-shadow")
	await click(stage.arena_buttons[2].get_global_rect().get_center(),true)
	check(stage.top_stats(state,"grove-birch")[0].text=="296","Header updates immediately after spending wood")
	await capture("inventory-after-upgrade")
	game.stamina.woodcutting=100
	await click(stage.get_global_transform_with_canvas()*stage.world_point(450,.91),true)
	var poses: Dictionary={}
	for frame in 1400:
		await RenderingServer.frame_post_draw
		if state.phase!="chopping": continue
		var phase: float=float(state.age)/runtime.swing_seconds("grove-birch")
		var pose:=0 if phase<.5 else (1 if phase<.72 else 2)
		if not poses.has(pose):
			poses[pose]=true
			var image:=root.get_texture().get_image()
			check(image.get_size()==Vector2i(1080,1920),"Raw production viewport dimensions")
			image.save_png(capture_dir+"/chop-"+str(pose)+".png")
		if poses.size()==3: break
	check(poses.size()==3,"Raised, contact and follow-through poses captured in the real game")
	await click(stage.axe_button.get_global_rect().get_center(),true)
	check(stage.shop.visible,"Shadowed badge still opens the axe shop")
	await click(stage.shop.close_button.get_global_rect().get_center(),true)
	check(not stage.shop.visible,"Axe shop closes normally")
	game._action_runtime()._stop_running_action("woodcutting","grove-birch")
	await settle(.5)
	await capture("inactive-layering")
	print("GROVE_DEPTH failures=",JSON.stringify(failures))
	var result:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
