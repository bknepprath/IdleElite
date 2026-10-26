extends "res://scripts/tests/axe_shop_capture.gd"

func audit_action_art() -> void:
	var runtime=game._grove_runtime()
	runtime.reset()
	runtime.rng.seed=625
	for material in game.material_runtime.material_defs: game.material_runtime.set_amount(str(material),1000)
	for id in runtime.IDS:
		await open_notes_skill("woodcutting")
		var card:=await notes_card(id)
		await align_notes_card(card)
		var stage: Control=card.grove_stage
		var field: Rect2=stage.field_rect()
		check(field.size.x/field.size.y>1.8,"Arena is a horizontal oval: "+id)
		check(not card.bg.visible,"Rectangular field background is hidden: "+id)
		for tree in runtime.state(id).trees:
			var point: Vector2=(stage.world_point(float(tree.x),float(tree.y))-field.get_center())/(field.size*.5)
			check(point.length()<.95,"Tree roots stay inside the oval: "+id)
		await capture(id+"-oval")
	await open_notes_skill("woodcutting")
	var card:=await notes_card("grove-birch")
	await align_notes_card(card)
	var stage: Control=card.grove_stage
	var state: Dictionary=runtime.state("grove-birch")
	var tree: Dictionary=state.trees[0]
	# Deterministic source state, reached through the normal card input.
	tree.x=450.0
	tree.y=.86
	tree.hp=1
	tree.rare=false
	tree.source_id="grove-birch"
	state.x=407.0
	state.y=.872
	for index in range(1,state.trees.size()): state.trees[index].y=.35+index*.06
	state.target=0
	game.stamina.woodcutting=100
	await click(stage.get_global_transform_with_canvas()*stage.world_point(450,.86),true)
	check(game.running_action_id=="grove-birch","Oval ground tap starts chopping")
	for frame in 1200:
		await process_frame
		if tree.phase=="stump": break
	check(tree.phase=="stump","Real chop and fall leave a stump")
	game._action_runtime()._stop_running_action("woodcutting","grove-birch")
	var clear_time: float=runtime.stump_clear_seconds("grove-birch")
	var regrowth_time: float=runtime.regrowth_seconds("grove-birch")
	for moment in [{"age":clear_time-.6,"name":"stump-before"},{"age":clear_time-.175,"name":"stump-fading"},{"age":clear_time+.12,"name":"stump-cleared"},{"age":regrowth_time-.2,"name":"stump-gap"}]:
		for frame in 1400:
			if float(tree.age)>=float(moment.age): break
			await process_frame
		check(tree.phase=="stump","Regrowth has not started during the stump gap")
		await capture(str(moment.name))
	check(runtime.stump_opacity("grove-birch",tree)==0.0,"No visible stump remains before regrowth")
	for frame in 600:
		await process_frame
		if state.trees[0]!=tree and float(state.trees[0].get("spawn_age",0))>.6: break
	check(state.trees[0]!=tree and state.trees[0].phase=="standing","New tree returns at the original regrowth deadline")
	await capture("tree-regrown")
	await click(stage.axe_button.get_global_rect().get_center(),true)
	check(stage.shop.visible,"Axe shop opens over the oval arena")
	await click(stage.shop.close_button.get_global_rect().get_center(),true)
	root.size=Vector2i(1920,1080)
	await settle(2)
	await game._skill_detail_surface()._scroll_to_activity_card("grove-birch",false,true)
	await settle(.7)
	await RenderingServer.frame_post_draw
	var desktop_image:=root.get_texture().get_image()
	check(desktop_image.get_size()==Vector2i(1920,1080),"Desktop proof is a raw 1920 x 1080 viewport")
	desktop_image.save_png(capture_dir+"/oval-desktop.png")
	print("GROVE_OVAL failures=",JSON.stringify(failures)," stump_gap_seconds=",regrowth_time-clear_time)
	var result:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures,"stump_gap_seconds":regrowth_time-clear_time}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
