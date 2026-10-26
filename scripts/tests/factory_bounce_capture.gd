extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	for id in game.material_runtime.material_defs: game.material_runtime.set_amount(str(id),1000)
	for action in game.actions_by_skill.build:
		if not action.get("build",{}).is_empty(): game.built_modules[game._action_key("build",str(action.id))]=true
	await open_notes_skill("build")
	var results: Array=[]
	for factory in game.actions_by_skill.build:
		if not preload("res://scripts/production/factory_inventory_layout.gd").applies(factory): continue
		var id: String=factory.id
		var requested:=OS.get_environment("IDLE_ELITE_FACTORY_BOUNCE_IDS")
		if not requested.is_empty() and id not in requested.split(","): continue
		var action: Dictionary=game._action_data("build",id)
		var recipe: Dictionary=game._production_runtime().recipe(action)
		if int(recipe.get("limit",0))>0:
			for output in recipe.outputs: game.material_runtime.set_amount(str(output),0)
		var card:=await notes_card(id)
		await align_notes_card(card)
		var stage: Control=card.production_stage
		var inventory: Control=stage.factory_inventory
		check(inventory!=null and stage.input_panel.visible,"Every factory uses the full shared layout: "+id)
		check(stage.input_panel.size.y==200 and stage.output_panel.size==Vector2(200,200),"Full-size action boxes: "+id)
		check(card.medal.get_parent()==stage.output_panel and card.medal.position+card.medal.size*.5==Vector2.ZERO,"Medal uses output top-left corner: "+id)
		check(absf(stage.stat_strip.position.x+stage.stat_strip.size.x-stage.size.x+28)<2 and stage.stat_strip.position.y==0,"Stats align top-right: "+id)
		check(not stage.stat_strip.get_global_rect().intersects(card.medal.get_global_rect()),"Medal stays clear of header stats: "+id)
		check(int(action.presentation.height)==440,"Quantity badges do not increase factory height: "+id)
		var counts: Array=[stage.output_count] if not stage.input_items.is_empty() else [stage.input_count,stage.output_count]
		for item in stage.input_items: counts.append(item.count)
		for count in counts:
			var badge: Control=stage.quantity_badge(count)
			var box: Control=badge.get_parent()
			check(box.get_global_rect().grow(-6).encloses(badge.get_global_rect()),"Recipe quantity remains inside its action box, clear of mastery and progress edges: "+id)
		await capture(id+"-idle")
		await click(stage.output_hit.get_global_rect().get_center(),true)
		await settle(.1)
		check(inventory.top_items.size()==recipe.inputs.size(),"One inventory for every actual ingredient")
		if is_instance_valid(stage.output_menu) and stage.output_menu.visible: await click(stage.menu_choice.get_global_rect().get_center(),true)
		check(game.running_action_id==id,"Real recipe selection starts work")
		var reserved_bottom: float=game._current_canvas_size().y-game._reward_feedback_surface()._reward_float_reserved_bottom()
		check(inventory.top_items[0].global_position.y>game.detail_actions_scroll.global_position.y+4,"Upper inventories clear the skill header")
		check(inventory.boxes[stage.output_id].get_global_rect().end.y<reserved_bottom-4,"Output inventory clears the utility controls")
		var before: float=game.material_runtime.amount(stage.output_id)
		var crit_burst=game._reward_feedback_surface()._activity_crit_art_burst(card,card.pop)
		check(crit_burst!=null and crit_burst.texture==stage.output_icon.texture,"Critical art uses the actual output instead of old module artwork")
		if crit_burst!=null: crit_burst.queue_free()
		if card.pop.has_meta("activity_crit_art_burst_node"): card.pop.remove_meta("activity_crit_art_burst_node")
		var saved: Dictionary={}
		var images: Array=[]
		var deadline:=Time.get_ticks_msec()+22000
		while Time.get_ticks_msec()<deadline:
			await RenderingServer.frame_post_draw
			check(not card.art.visible,"Original module art stays hidden through every update and reward")
			var phase: float=game.action_progress
			var name:=""
			if game.material_runtime.amount(stage.output_id)>before:
				if stage.harvest_age>.65 and not saved.has("down"): name="down"
				if stage.harvest_age>.93: break
			elif phase>.18 and phase<.24 and not saved.has("input"): name="input"
			elif phase>.76 and phase<.86 and not saved.has("right"): name="right"
			if not name.is_empty():
				saved[name]=true
				var image:=root.get_texture().get_image()
				check(image.get_size()==Vector2i(1080,1920),"Proof keeps raw phone viewport")
				images.append({"name":id+"-"+name,"image":image})
		check(saved.has("input") and saved.has("right") and saved.has("down"),"All three real bounce segments play: "+id)
		check(game.material_runtime.amount(stage.output_id)==before+float(recipe.outputs[stage.output_id]),"One real cycle credits its exact output once")
		for image in images: image.image.save_png(capture_dir+"/"+image.name+".png")
		await capture(id+"-landed")
		results.append({"id":id,"segments":saved.keys(),"inputs":recipe.inputs.size()})
		game._action_runtime()._stop_running_action("build",id)
		await settle(.5)
	print("FACTORY_BOUNCE_CAPTURE failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"factories":results}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
