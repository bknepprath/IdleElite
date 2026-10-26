extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	game.material_runtime.set_amount("sand",40)
	game.stamina.build=100
	game._action_runtime().guaranteed_success_action_completions=1000
	await open_notes_skill("build")
	var card:=await notes_card("gather-sand")
	await align_notes_card(card)
	var art: Control=card.art
	check(art.has_method("set_action_progress"),"Gather Sand uses the production animated portrait")
	check(art.frame_textures.size()==12 and art.progress_synced,"Twelve generated poses are synchronized to gathering progress")
	check(art.overlay_frames.size()==4 and not art.frame_overlay.visible,"Four falling-Sand frames are separate and hidden while idle")
	check(not art.animation_playing,"Inactive gathering holds its ready pose")
	await capture("sand-scooping-idle")
	await click(card.art_panel.get_global_rect().get_center(),true)
	check(game.running_action_id=="gather-sand" and art.animation_playing,"Actual portrait tap starts gathering and its animation")
	var expected_frames: Array[int]=[5,1,2,3,6,7,8]
	var labels: Array[String]=["approach","dig","lift","raise","turn","carry","reach"]
	for index in expected_frames.size():
		for frame in range(1200):
			await process_frame
			if art.frame_sequence[art.sequence_index]==expected_frames[index]: break
		check(art.frame_sequence[art.sequence_index]==expected_frames[index],"Natural cycle reaches "+labels[index])
		await capture("sand-scooping-"+labels[index])
	for target in range(4):
		for frame in range(1200):
			await process_frame
			if art.overlay_frame_index==target: break
		check(art.overlay_frame_index==target and art.frame_overlay.visible,"Natural pour shows falling-Sand frame "+str(target))
		check(art.frame_sequence[art.sequence_index] in [9,10,11],"Falling Sand appears only during tipping and final grains")
		check(art.frame_overlay.get_global_rect().is_equal_approx(art.get_global_rect()),"Pour overlay shares the exact portrait canvas")
		await capture("sand-pour-"+str(target))
	for frame in range(1200):
		await process_frame
		if game.action_progress>.91: break
	check(not art.frame_overlay.visible,"Pour effect clears before returning to ready")
	await capture("sand-scooping-recover")
	check(bool(card.mat_collection.visible),"Existing Sand inventory opens during gathering")
	for frame in range(1200):
		await process_frame
		if game.material_runtime.amount("sand")>40: break
	check(game.material_runtime.amount("sand")==42,"One actual completion still awards exactly two Sand")
	await settle(.35)
	await capture("sand-scooping-collected")
	game._action_runtime()._stop_running_action("build","gather-sand")
	await settle(.65)
	check(not art.animation_playing and art.sequence_index==0,"Stopping returns to a stable ready pose")
	check(not art.frame_overlay.visible,"Stopping also clears the falling-Sand layer")
	check(not bool(card.mat_collection.visible),"Stopping preserves collection-box close behavior")
	await capture("sand-scooping-stopped")
	print("SAND_SCOOPING failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
