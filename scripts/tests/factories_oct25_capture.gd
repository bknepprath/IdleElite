extends "res://scripts/tests/action_art_oct22.gd"
func audit_action_art() -> void:
	for material in game.material_runtime.material_defs: game.material_runtime.set_amount(str(material),1000)
	for skill in game.actions_by_skill:
		for action in game.actions_by_skill[skill]:
			if not action.get("build",{}).is_empty(): game.built_modules[game._action_key(str(skill),str(action.id))]=true
	await open_notes_skill("build")
	for action in game.actions_by_skill.build:
		if not bool(action.get("presentation",{}).get("building",false)): continue
		var id: String=action.id
		var filter:=OS.get_environment("IDLE_ELITE_FACTORY_CAPTURE_ID")
		if not filter.is_empty() and id!=filter: continue
		var recipe: Dictionary=game._production_runtime().recipe(action)
		if int(recipe.get("limit",0))>0:
			for material in recipe.outputs: game.material_runtime.set_amount(str(material),0)
		var card:=await notes_card(id)
		await align_notes_card(card)
		check(card.has("production_stage") and card.production_stage.regular_layout,"Converter layout: "+id)
		check(card.progress.is_visible_in_tree(),"Visible continuous V rail: "+id)
		check(not card.stamina.is_visible_in_tree() and not card.success.is_visible_in_tree(),"Only time and XP: "+id)
		await capture(id+"-before")
		await click(card.production_stage.output_hit.get_global_rect().get_center(),true)
		await settle(.1)
		await capture(id+"-menu")
		if is_instance_valid(card.production_stage.output_menu) and card.production_stage.output_menu.visible: await click(card.production_stage.menu_choice.get_global_rect().get_center(),true)
		await settle(.2)
		check(game.running_action_id==id,"Output starts real batch: "+id)
		await capture(id+"-working")
		await settle(1.3)
		await capture(id+"-progress")
		game._action_runtime()._stop_running_action("build",id)
	for pair in [["thieving","loot-beehive"],["thieving","explore-dark-passage"],["fight","fight-the-current"],["build","repair-waterwheel"],["build","gather-sand"],["thieving","collect-beeswax"]]:
		if not OS.get_environment("IDLE_ELITE_FACTORY_CAPTURE_ID").is_empty(): break
		await open_notes_skill(pair[0])
		var card:=await notes_card(pair[1])
		await align_notes_card(card)
		await capture(pair[1]+"-compact")
	print("FACTORIES_CAPTURE failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
