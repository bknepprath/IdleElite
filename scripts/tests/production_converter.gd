extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var production=game._production_runtime()
	production.state.wheel_built=false
	for id in game.material_runtime.material_defs: game.material_runtime.set_amount(str(id),1000)
	game.material_runtime.set_amount("spyglass",0)
	game.material_runtime.set_amount("precision-net",0)
	for action in game.actions_by_skill.build:
		if not action.get("build",{}).is_empty(): game.built_modules[game._action_key("build",str(action.id))]=true
	await open_notes_skill("build")
	var checked: Array=[]
	for action in game.actions_by_skill.build:
		if not preload("res://scripts/production/factory_inventory_layout.gd").applies(action): continue
		var id: String=action.id
		var recipe: Dictionary=production.recipe(action)
		if int(recipe.get("limit",0))>0:
			for output in recipe.outputs: game.material_runtime.set_amount(str(output),0)
		var card:=await notes_card(id)
		await align_notes_card(card)
		var stage: Control=card.production_stage
		check(not stage.has_output_options(),"Only the single output exists: "+id)
		await click(stage.output_hit.get_global_rect().get_center(),true)
		game.set_process(false)
		await settle(.4)
		check(game.running_action_id==id,"One output tap starts the actual recipe: "+id)
		check(not is_instance_valid(stage.output_menu),"No one-choice popup is created: "+id)
		check(production.state.escrow.has(id),"Input reservation exists for the running batch")
		var balances: Dictionary=game.material_runtime.wallet.duplicate(true)
		var progress: float=game.action_progress
		await click(stage.output_hit.get_global_rect().get_center(),true)
		check(game.running_action_id==id and game.material_runtime.wallet==balances and game.action_progress==progress,"Repeated taps do not stop, restart or charge the batch again")
		await click(stage.factory_inventory.boxes[stage.output_id].get_global_rect().get_center(),true)
		check(not is_instance_valid(stage.output_menu) and game.material_runtime.wallet==balances,"Output inventory tap follows the same direct-start rule")
		if id in ["melt-sand","shape-bottles"]: await capture(id+"-one-tap")
		checked.append(id)
		game._action_runtime()._stop_running_action("build",id)
		game.set_process(true)
		await settle(.3)
	# A real queue remains reachable when the Waterwheel adds another action.
	production.state.wheel_built=true
	var card:=await notes_card("melt-sand")
	await align_notes_card(card)
	var stage: Control=card.production_stage
	await click(stage.output_hit.get_global_rect().get_center(),true)
	check(stage.has_output_options() and is_instance_valid(stage.output_menu) and stage.output_menu.visible,"Waterwheel queue retains its useful menu")
	var queued: int=production.state.queue.size()
	for control in stage.buttons:
		if control.text=="+1": await click(control.get_global_rect().get_center(),true)
	check(production.state.queue.size()==queued+1,"Actual queue button still reserves a crafting job")
	await click(Vector2(1040,500),true)
	check(not stage.output_menu.visible,"Useful menu still dismisses outside")
	# Owned equipment still exposes its existing controls.
	production.state.wheel_built=false
	game.material_runtime.set_amount("spyglass",1)
	card=await notes_card("assemble-spyglass")
	await align_notes_card(card)
	stage=card.production_stage
	await click(stage.output_hit.get_global_rect().get_center(),true)
	var tools: Array=[]
	for control in stage.buttons: tools.append(control.text)
	check(stage.output_menu.visible and "Scout" in tools and "Bait" in tools,"Owned equipment keeps its actual controls")
	check(checked.size()==9,"Every current converter was tested with one tap")
	print("PRODUCTION_CONVERTER failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"one_tap_factories":checked}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
