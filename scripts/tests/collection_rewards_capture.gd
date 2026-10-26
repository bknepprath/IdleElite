extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	check(game._audio_director().music_muted and game._audio_director().sfx_muted,"Playtest music and SFX remain muted after startup")
	check(AudioServer.is_bus_mute(0),"Master bus remains muted after startup")
	var halloween=game._halloween_runtime()
	halloween.enabled=true
	halloween.ends_at_unix=0
	halloween.candy=0
	halloween.auto_by_skill={}
	var results: Array=[]
	var cases: Array=[["thieving","trick-or-treat"]]
	for skill in ["thieving","woodcutting","build"]:
		for action in game.actions_by_skill[skill]:
			if str(action.id)=="trick-or-treat": continue
			if game._material_collection_surface().has_item_boxes(skill,action): cases.append([skill,str(action.id)])
	for pair in cases:
		var skill: String=pair[0]
		var id: String=pair[1]
		game.set_process(true)
		if game.current_screen!="skill" or game.selected_skill_id!=skill: await open_notes_skill(skill)
		var card:=await notes_card(id)
		await align_notes_card(card)
		check(not card.mat_collection.is_empty(),"Real resource holder exists: "+id)
		game.stamina[skill]=100
		# Force only the outcome for a deterministic visual audit, not its rewards.
		card.action.success=100
		game._action_runtime().invalidate_stat_cache()
		await click(card.pop.get_global_rect().get_center(),true)
		await settle(.4)
		check(game.running_action_id==id and bool(card.mat_collection.visible),"Actual card tap opens its holder: "+id)
		game.set_process(false)
		await capture(id+"-before")
		var before: Dictionary={}
		for item in card.mat_collection.modules:
			before[item]=halloween.candy if item=="candy" else game.material_runtime.amount(item)
		for attempt in 12:
			game.action_progress=.999
			game._action_runtime()._process_action(.1)
			await process_frame
			var credited:=false
			for item in before:
				var balance: float=halloween.candy if item=="candy" else game.material_runtime.amount(item)
				credited=credited or balance>float(before[item])
			if credited: break
		var samples: Array=[]
		var seen: Dictionary={}
		var flyer_refs: Array=[]
		var previous_y:=0.0
		var rose:=false
		var fell:=false
		var saved: Dictionary={}
		var landed: Dictionary={}
		var deadline:=Time.get_ticks_msec()+1500
		while Time.get_ticks_msec()<deadline:
			await RenderingServer.frame_post_draw
			for child in game.get_children():
				if not child is Control or not child.has_meta("mat_flyer_tween"): continue
				var item: String=child.get_meta("mat_flyer_item_id")
				if not card.mat_collection.modules.has(item): continue
				seen[item]=true
				if child not in flyer_refs: flyer_refs.append(child)
				check(child.get_meta("mat_flyer_target_id")==card.mat_collection.modules[item].get_instance_id(),"Receipt targets its own item holder: "+item)
				var progress: float=child.get_meta("mat_flyer_progress",0.0)
				if previous_y!=0:
					rose=rose or child.position.y<previous_y-.1
					fell=fell or child.position.y>previous_y+.1
				previous_y=child.position.y
				for threshold in [.08,.40,.88]:
					var label:=str(threshold)
					if progress>=threshold and not saved.has(label):
						saved[label]=true
						var image:=root.get_texture().get_image()
						check(image.get_size()==Vector2i(1080,1920),"Raw production viewport stays 1080x1920")
						samples.append({"name":id+"-flight-"+label.replace(".",""),"image":image})
				if progress>.999 and not landed.has(child.get_instance_id()):
					landed[child.get_instance_id()]=true
					var target: Control=card.mat_collection.modules[item]
					check((child.get_global_transform()*Vector2(child.size*.5)).distance_to(target.get_global_rect().get_center())<32,"Flyer actually reaches the holder: "+item)
		check(landed.size()==flyer_refs.size() and not landed.is_empty(),"Every flyer reached its destination: "+id)
		check(not seen.is_empty() and rose and fell,"Actual credited reward pops up then falls into its holder: "+id)
		for item in card.mat_collection.modules:
			var after: float=halloween.candy if item=="candy" else game.material_runtime.amount(item)
			if after>float(before[item]): check(seen.has(item),"Every credited output animates: "+item)
		for sample in samples: sample.image.save_png(capture_dir+"/"+sample.name+".png")
		var balance: Dictionary=game.material_runtime.wallet.duplicate(true)
		var candy_balance: int=halloween.candy
		await capture(id+"-settled")
		check(balance==game.material_runtime.wallet and candy_balance==halloween.candy,"Visuals never award extra inventory")
		for flyer in flyer_refs: check(not is_instance_valid(flyer),"Completed collection flyer is cleaned up")
		results.append({"id":id,"items":seen.keys(),"rose":rose,"fell":fell})
		game._action_runtime()._stop_running_action(skill,id)
		game.set_process(true)
		await settle(.5)
	check(not cases.is_empty() and results.size()==cases.size(),"Every data-defined standard-holder activity was reached through the real UI")
	print("COLLECTION_CAPTURE failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"activities":results}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
