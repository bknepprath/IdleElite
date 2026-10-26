extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	game.material_runtime.set_amount("sand",1000)
	game.built_modules["build:melt-sand"]=true
	var key: String=game._action_key("build","melt-sand")
	game.mastery[key]={"xp":MasteryState.xp_for_level(5),"level":5}
	await open_notes_skill("build")
	var card:=await notes_card("melt-sand")
	await align_notes_card(card)
	await capture("window-before")
	await click(card.production_stage.output_hit.get_global_rect().get_center(),true)
	await align_notes_card(card)
	if is_instance_valid(card.production_stage.output_menu) and card.production_stage.output_menu.visible: await click(card.production_stage.menu_choice.get_global_rect().get_center(),true)
	check(game.running_action_id=="melt-sand","Actual output selection starts production")
	# Keep the whole notch away from inventory clipping and the utility row.
	var rail: Control=card.progress
	check(rail.bottom_shape=="production_v","Window follows the real V-shaped production rail")
	var maximum_turn:=0.0
	var records: Array=[]
	var captures: Array=[]
	var saved:=0
	var deadline:=Time.get_ticks_msec()+6500
	var targets: Array[float]=[.65,.58,.53,.48,.43,.38,.31,.20]
	var next_target:=0
	while Time.get_ticks_msec()<deadline:
		await RenderingServer.frame_post_draw
		if rail.opportunity_windows.is_empty(): continue
		var interval: Vector2=rail.opportunity_windows[0]
		var outline: PackedVector2Array=rail._production_opportunity_outline(interval.x,interval.y)
		check(not Geometry2D.triangulate_polygon(outline).is_empty(),"Actual window frame remains a simple outline")
		for index in outline.size():
			var incoming:=outline[index]-outline[posmod(index-1,outline.size())]
			var outgoing:=outline[(index+1)%outline.size()]-outline[index]
			if incoming.length()<.001 or outgoing.length()<.001: continue
			var turn:=absf(incoming.angle_to(outgoing))
			maximum_turn=maxf(maximum_turn,turn)
			check(turn<.22,"Actual window has no sharp join in frame "+str(records.size()))
		records.append({"interval":[interval.x,interval.y],"points":outline.size()})
		var at_corner:=interval.x<.68 and interval.y>.30
		var at_target:=next_target<targets.size() and interval.x<=targets[next_target]
		if at_corner or at_target:
			var img:=root.get_texture().get_image()
			check(img.get_size()==Vector2i(1080,1920),"Every raw corner frame retains the phone viewport")
			if at_corner:
				captures.append({"name":"corner-frame-%03d"%saved,"image":img})
				saved+=1
			while next_target<targets.size() and interval.x<=targets[next_target]:
				captures.append({"name":"window-bend-%02d"%next_target,"image":img})
				next_target+=1
		if interval.x<=.051 and next_target==targets.size(): break
	check(next_target==targets.size(),"Natural Sapphire motion crosses the entire notch and both shoulders")
	check(saved>10,"Consecutive raw frames cover the corner transitions")
	var windows: Array[Vector2]=[Vector2(.35,.61)]
	# Hold a real production opportunity window at the notch for both feedback paths.
	game._action_runtime().action_opportunity_persistent_key=key
	game._action_runtime().action_opportunity_persistent_windows=windows
	game.mastery[key]={"xp":MasteryState.xp_for_level(5),"level":5}
	await settle(.2)
	var stationary: PackedVector2Array=rail._production_opportunity_outline(windows[0].x,windows[0].y).duplicate()
	await settle(.3)
	check(rail._production_opportunity_outline(windows[0].x,windows[0].y)==stationary,"Repeated stationary draws do not mutate cached geometry")
	rail.play_opportunity_feedback(true,windows)
	await capture("window-success")
	check(rail._production_opportunity_outline(windows[0].x,windows[0].y)==stationary,"Green feedback does not translate the cached outline")
	await settle(.5)
	rail.play_opportunity_feedback(false,windows)
	await capture("window-miss")
	check(rail._production_opportunity_outline(windows[0].x,windows[0].y)==stationary,"Red shake does not translate the cached outline")
	await settle(.8)
	game._action_runtime()._stop_running_action("build","melt-sand")
	await settle(.5)
	await capture("window-stopped")
	# Encode after the motion audit; PNG compression must not stall the shot
	# and skip the very transition frames this test is meant to inspect.
	for entry in captures: entry.image.save_png(capture_dir+"/"+str(entry.name)+".png")
	print("PRODUCTION_WINDOW_CAPTURE frames=",records.size()," corner_pngs=",saved," failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"frames":records,"corner_pngs":saved,"maximum_turn_degrees":rad_to_deg(maximum_turn)}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
