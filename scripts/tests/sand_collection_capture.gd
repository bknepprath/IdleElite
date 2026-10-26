extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	for material in game.material_runtime.material_defs: game.material_runtime.set_amount(str(material),1000)
	game.built_modules["build:melt-sand"]=true
	await open_notes_skill("build")
	for id in ["melt-sand","gather-sand"]:
		var card:=await notes_card(id)
		await align_notes_card(card)
		await capture(id+"-idle")
		if id=="melt-sand":
			var stage: Control=card.production_stage
			var strip: Control=stage.stat_strip
			check(absf(strip.position.x+strip.size.x-stage.size.x+28)<2,"Melt Sand XP/time strip is aligned top-right")
			check(strip.position.y<60,"Melt Sand XP/time strip is in its top row")
			check(not strip.get_global_rect().intersects(stage.input_panel.get_global_rect()) and not strip.get_global_rect().intersects(stage.output_panel.get_global_rect()),"Header stats stay clear of the full input/output action boxes")
			await click(stage.output_hit.get_global_rect().get_center(),true)
			await settle(.2)
			if is_instance_valid(stage.output_menu) and stage.output_menu.visible: await click(stage.menu_choice.get_global_rect().get_center(),true)
			await settle(.3)
			check(game.running_action_id==id,"Factory still starts through its actual output selector")
			await capture("melt-sand-working")
			game._action_runtime()._stop_running_action("build",id)
			await settle(.2)
		if id=="gather-sand":
			var action: Dictionary=game._action_data("build",id)
			check(action.xp_rewards=={"build":12,"fishing":1},"Gather Sand retains 12 Building XP and adds 1 Fishing XP")
			var xp_parts: Array=game._action_runtime()._base_xp_reward_parts_for_display("build",action)
			check(xp_parts.size()==2 and xp_parts[1].skill=="fishing" and xp_parts[1].amount==1,"Gather Sand displays its Fishing XP reward")
			var fishing_xp_before: int=game.skills.fishing.xp
			var collection: Dictionary=card.get("mat_collection",{})
			check(not collection.is_empty() and collection.modules.has("sand"),"Sand uses the shared material collection box")
			check(not bool(collection.get("visible",false)),"Sand box begins closed")
			var before: float=game.material_runtime.amount("sand")
			await click(card.pop.get_global_rect().get_center(),true)
			await settle(.65)
			check(game.running_action_id==id,"Sand gathering starts through actual card input")
			check(bool(card.mat_collection.visible),"Resource box opens when gathering starts")
			await capture("gather-sand-open")
			var flyer: Control=null
			for frame in 2400:
				await process_frame
				for child in game.get_children():
					if child is Control and child.has_meta("mat_flyer_tween"): flyer=child
				if flyer!=null: break
			check(flyer!=null,"Actual successful harvest creates the shared collection flyer")
			await settle(.48)
			await capture("gather-sand-dropping")
			await settle(.45)
			check(game.material_runtime.amount("sand")==before+2,"Actual harvest awards exactly two Sand")
			check(game.skills.fishing.xp>=fishing_xp_before+1,"Actual successful Sand harvest credits Fishing XP through the normal reward pipeline")
			await capture("gather-sand-collected")
			game._action_runtime()._stop_running_action("build",id)
			await settle(.6)
			check(not bool(card.mat_collection.visible),"Stopping closes the material box")
			await capture("gather-sand-closed")
	for skill in game.actions_by_skill:
		for action in game.actions_by_skill[skill]:
			if game._action_runtime()._action_mat_reward_defs(action).is_empty(): continue
			if not game._production_runtime().recipe(action).is_empty() or not action.get("grove",{}).is_empty() or not action.get("rockslide",{}).is_empty() or bool(action.get("production",{}).get("honey",false)): continue
			check(game._material_collection_surface().has_item_boxes(skill,action),"Ordinary resource gathering gets material boxes: "+str(action.id))
	await open_notes_skill("thieving")
	var wax:=await notes_card("collect-beeswax")
	await align_notes_card(wax)
	await click(wax.pop.get_global_rect().get_center(),true)
	await settle(.6)
	check(not wax.mat_collection.is_empty() and bool(wax.mat_collection.visible),"Beeswax gathering follows the same rule")
	await capture("beeswax-collection-open")
	game._action_runtime()._stop_running_action("thieving","collect-beeswax")
	print("SAND_CAPTURE failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
