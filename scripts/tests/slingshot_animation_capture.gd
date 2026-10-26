extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	game.stamina.fight=100
	game._rockslide_runtime().reset()
	await open_notes_skill("fight")
	for id in ["clear-rockslide","practice-slingshot"]:
		var card:=await notes_card(id)
		await align_notes_card(card)
		var stage: Control=card.production_stage
		await capture(id+"-ready")
		if id=="clear-rockslide":
			var stats: Array=stage.top_stats()
			check(stats.size()==3,"XP, stamina and Sand share the top stats row")
			var title_end: float=24+game.app_bold_font.get_string_size(card.action.name,HORIZONTAL_ALIGNMENT_LEFT,-1,60).x
			check(float(stats[0].position.x)>title_end+12,"Top stats do not overlap the title")
			for item in stats:
				check(is_equal_approx(float(item.position.y),62),"All stats have the same baseline")
		else:
			check(stage.top_stats().size()==2,"Practice XP estimate and stamina share one top row")
		await click(card.pop.get_global_rect().position+Vector2(470,220),true)
		check(game.running_action_id==id,"Actual card tap starts "+id)
		var frames: Dictionary={}
		var shot_counter: int=game._rockslide_runtime().shots_fired if id=="clear-rockslide" else game._slingshot_range_runtime().landings
		for tick in 720:
			await RenderingServer.frame_post_draw
			var pose: int=stage.animation_frame()
			if not frames.has(pose):
				frames[pose]=true
				var image:=root.get_texture().get_image()
				check(image.get_size()==Vector2i(1080,1920),"Raw production viewport dimensions")
				image.save_png(capture_dir+"/"+id+"-pose-"+str(pose)+".png")
			if frames.size()==8: break
		check(frames.size()==8,"All eight wind-up, release and recovery poses appear during live "+id)
		check(game._rockslide_runtime().shots_fired>shot_counter if id=="clear-rockslide" else game._slingshot_range_runtime().phase=="flying" or game._slingshot_range_runtime().landings>shot_counter,"The pose sequence accompanies real projectiles")
		game._action_runtime()._stop_running_action("fight",id)
		await settle(.3)
		await capture(id+"-stopped")
	print("SLINGSHOT_ANIMATION failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
