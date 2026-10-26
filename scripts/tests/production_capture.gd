extends "res://scripts/tests/action_art_oct22.gd"

func _run() -> void:
	if OS.get_environment("IDLE_ELITE_PRODUCTION_DESKTOP")=="1": OS.set_environment("IDLE_ELITE_DESKTOP","1")
	await super._run()

func audit_action_art() -> void:
	if game._halloween_runtime().greeting_visible():
		await click(Vector2(540,950),true)
		await settle(.3)
	for material in game.material_runtime.material_defs:
		game.material_runtime.set_amount(str(material),100)
	game.built_modules["build:melt-sand"] = true
	var requested := OS.get_environment("IDLE_ELITE_PRODUCTION_CAPTURE_IDS")
	var cases := [["build","gather-sand"],["build","melt-sand"],["build","shape-bottles"],["thieving","loot-beehive"],["thieving","collect-beeswax"],["build","make-candles"],["build","grind-lens"],["build","mix-fishing-bait"],["build","assemble-spyglass"],["build","assemble-lantern"],["thieving","explore-dark-passage"],["fight","fight-the-current"],["build","repair-waterwheel"],["build","weave-selective-net"],["build","carve-spyglass-tube"]]
	if OS.get_environment("IDLE_ELITE_PRODUCTION_FULL_CATALOG")=="1":
		cases.clear()
		for skill in game.actions_by_skill:
			for action in game.actions_by_skill[skill]:
				if not action.get("presentation",{}).is_empty(): cases.append([str(skill),str(action.id)])
	for skill in game.actions_by_skill:
		for action in game.actions_by_skill[skill]:
			if not action.get("build",{}).is_empty(): game.built_modules[game._action_key(str(skill),str(action.id))]=true
	for entry in cases:
		var skill: String = entry[0]
		var id: String = entry[1]
		if not requested.is_empty() and id not in requested.split(","): continue
		await open_notes_skill(skill)
		game._skill_detail_surface()._scroll_to_list_entry(id,false)
		await settle(.7)
		var card: Dictionary = await notes_card(id)
		if card.is_empty():
			print("PRODUCTION_MISSING ",id," unlocked=",game._activity_unlock_runtime()._is_action_unlocked(skill,game._action_data(skill,id))," built=",game.built_modules.has(skill+":"+id))
			for plan in game._skill_detail_surface().detail_lazy_plan:
				if str(plan).contains(id): print("PRODUCTION_PLAN ",plan.get("track_id")," ",plan.get("kind")," ",plan.get("mounted"))
			continue
		await align_notes_card(card)
		check(card.has("production_stage") or is_instance_valid(card.get("blue_guy_chicken_stage")),"Real special stage mounted: "+id)
		if not card.has("production_stage"): continue
		var stage: Control = card.production_stage
		check(stage.is_visible_in_tree(),"Special stage is visible: "+id)
		if id in ["assemble-lantern","weave-selective-net","assemble-spyglass"]:
			game.material_runtime.set_amount({"assemble-lantern":"lantern","weave-selective-net":"precision-net","assemble-spyglass":"spyglass"}[id],0)
			await settle(.4)
		await capture(id+"-before")
		if id=="loot-beehive":
			await click(stage.buttons[0].get_global_rect().get_center(),true)
			check(game._production_runtime().state.bottling,"Real Store button changes mode")
			await click(stage.buttons[0].get_global_rect().get_center(),false)
			check(not game._production_runtime().state.bottling,"Desktop mouse can change the store mode")
			await click(stage.buttons[0].get_global_rect().get_center(),true)
		if id=="repair-waterwheel":
			game._production_runtime().state.wheel_clearance=8
			game._production_runtime().state.wheel_progress=7
		await click(card.pop.get_global_rect().get_center(),true)
		await settle(.22)
		check(game.running_action_id==id,"Stage starts through the real UI: "+id+" (active="+str(game.running_action_id)+", result="+str(game.last_result)+")")
		await capture(id+"-transition")
		await settle(1.1)
		await capture(id+"-working")
		if id=="assemble-spyglass":
			await settle(2)
			await capture(id+"-fitting")
			for i in 100:
				await settle(.1)
				if game.material_runtime.amount("spyglass")>=1: break
			check(game.material_runtime.amount("spyglass")==1,"Actual assembly finishes one spyglass")
			await settle(.4)
			await click(stage.buttons[0].get_global_rect().get_center(),true)
			await capture(id+"-scouted")
		if id=="loot-beehive":
			var before: bool = game._production_runtime().state.use_bottled_honey
			await click(stage.buttons[1].get_global_rect().get_center(),true)
			check(game._production_runtime().state.use_bottled_honey!=before,"Real Use toggle changes automatic bottle consumption")
			await capture(id+"-opened")
		if id=="repair-waterwheel":
			for i in 150:
				await settle(.1)
				if game._production_runtime().state.wheel_built: break
			check(game._production_runtime().state.wheel_built,"Waterwheel finishes from actual work")
			await settle(.5)
			check(stage.buttons[1].is_visible_in_tree(),"Finished waterwheel exposes its queue controls")
			await click(stage.buttons[1].get_global_rect().get_center(),true)
			check(not game._production_runtime().state.queue.is_empty(),"Real waterwheel control enqueues glass")
			await capture(id+"-queue")
		game._action_runtime()._stop_running_action(skill,id)
		await settle(.25)
		await capture(id+"-settled")
	if OS.get_environment("IDLE_ELITE_PRODUCTION_NAVIGATION")=="1": await audit_production_navigation()
	if OS.get_environment("IDLE_ELITE_PRODUCTION_DESKTOP")=="1":
		await open_notes_skill("thieving")
		game._skill_detail_surface()._scroll_to_list_entry("loot-beehive",false)
		await settle(1)
		var desktop_card: Dictionary=await notes_card("loot-beehive")
		root.size=Vector2i(1920,1080)
		await settle(3)
		game._skill_detail_surface()._scroll_to_list_entry("loot-beehive",false)
		await settle(1)
		desktop_card=game.action_cards.get("thieving:loot-beehive",{})
		check(not desktop_card.is_empty(),"Desktop retains the selected production activity")
		if desktop_card.is_empty(): quit(1); return
		await capture_demo("desktop-before")
		await desktop_click(desktop_card.pop.get_global_rect().get_center())
		check(game.running_action_id=="loot-beehive","Desktop activity starts through actual pointer input")
		await settle(.22)
		await capture_demo("desktop-transition")
		await settle(.8)
		await capture_demo("desktop-working")
		var stored_before: bool=game._production_runtime().state.use_bottled_honey
		await desktop_click(desktop_card.production_stage.buttons[1].get_global_rect().get_center())
		check(game._production_runtime().state.use_bottled_honey!=stored_before,"Desktop Use control changes automatic bottle consumption")
		game._action_runtime()._stop_running_action("thieving","loot-beehive")
		await settle(.2)
		await capture_demo("desktop-settled")
	await settle(2)
	var report := FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	print("PRODUCTION_CAPTURE failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func desktop_click(point: Vector2) -> void:
	for down in [true,false]:
		var event:=InputEventMouseButton.new()
		event.position=point
		event.global_position=point
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		Input.parse_input_event(event.xformed_by(root.get_final_transform()))
		await settle(.06)
	await settle(.2)

func audit_production_navigation() -> void:
	game._action_runtime()._stop_running_action(game.running_skill_id,game.running_action_id)
	await open_notes_skill("thieving")
	game._skill_detail_surface()._scroll_to_list_entry("loot-beehive",false)
	await settle(.7)
	var honey_card: Dictionary=await notes_card("loot-beehive")
	await align_notes_card(honey_card)
	var start: Vector2=honey_card.production_stage.buttons[0].get_global_rect().get_center()
	var stored_mode: bool=game._production_runtime().state.bottling
	var original_scroll: int=game._skill_detail_surface().detail_actions_scroll.scroll_vertical
	var down:=InputEventScreenTouch.new()
	down.index=0; down.pressed=true; down.position=start
	Input.parse_input_event(down.xformed_by(root.get_final_transform()))
	await settle(.05)
	for i in 10:
		var drag:=InputEventScreenDrag.new()
		drag.index=0; drag.position=start-Vector2(0,(i+1)*15); drag.relative=Vector2(0,-15)
		Input.parse_input_event(drag.xformed_by(root.get_final_transform()))
		await settle(.025)
	down.pressed=false; down.position=start-Vector2(0,150)
	Input.parse_input_event(down.xformed_by(root.get_final_transform()))
	await settle(.3)
	check(game._production_runtime().state.bottling==stored_mode,"Dragging from Store does not change the honey mode")
	check(game._skill_detail_surface().detail_actions_scroll.scroll_vertical!=original_scroll,"A vertical drag from a production control scrolls the actual list")
	await open_notes_skill("build")
	game._skill_detail_surface()._scroll_to_list_entry("shape-bottles",false)
	await settle(.7)
	var card: Dictionary=await notes_card("shape-bottles")
	await align_notes_card(card)
	await click(card.production_stage.ingredient_row.get_child(0).get_global_rect().get_center(),true)
	await wait_for_destination("thieving:explore-dark-passage")
	check(game.selected_skill_id=="thieving" and game.action_cards.has("thieving:explore-dark-passage"),"Glass ingredient link reaches the fastest unlocked source through the real UI")
	await capture("ingredient-source")
	await open_notes_skill("build")
	game._production_runtime().state.wheel_built=false
	game._production_runtime().state.wheel_clearance=0
	game._skill_detail_surface()._scroll_to_list_entry("repair-waterwheel",false)
	await settle(.7)
	card=await notes_card("repair-waterwheel")
	await align_notes_card(card)
	await click(card.production_stage.buttons[0].get_global_rect().get_center(),false)
	await wait_for_destination("fight:fight-the-current")
	check(game.selected_skill_id=="fight" and game.action_cards.has("fight:fight-the-current"),"Waterwheel Clear button reaches Fighting work")
	await capture("clearance-source")
	await open_notes_skill("build")
	game._skill_detail_surface()._scroll_to_list_entry("assemble-spyglass",false)
	await settle(.7)
	card=await notes_card("assemble-spyglass")
	await align_notes_card(card)
	var target: String=card.production_stage.scout_action()
	await click(card.production_stage.buttons[1].get_global_rect().get_center(),true)
	await settle(.7)
	check(game.selected_skill_id=="fishing" and game._production_runtime().bait_active(target),"Bait button applies the saved location choice and opens Fishing")
	await capture("targeted-fishing")

func wait_for_destination(key: String) -> void:
	for i in 80:
		await settle(.05)
		var destination: Dictionary=game.action_cards.get(key,{})
		if not destination.is_empty() and is_instance_valid(destination.get("pop")) and destination.pop.get_global_rect().get_center().y>420 and destination.pop.get_global_rect().get_center().y<1500:
			await settle(.2)
			return
