extends "res://scripts/tests/action_art_oct22.gd"

var sync_measurements: Array = []

func audit_action_art() -> void:
	if OS.get_environment("IDLE_ELITE_ROD_ONLY") == "1":
		await open_notes_skill("fishing")
		game._action_runtime().guaranteed_success_action_completions = 1000
		game.fishing_runtime.star_rod_collected = false
		game._action_runtime().invalidate_stat_cache()
		await audit_wallet_comparison()
		await audit_rod_pullback()
	else:
		await audit_splash_sync()
	print("SPLASH_SYNC failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture(label: String) -> void:
	if OS.get_environment("IDLE_ELITE_ART_DEMO") == "1":
		await capture_demo(label)
	else:
		await super.capture(label)

func show_art_desktop_demo() -> void:
	await open_notes_skill("fishing")
	game._action_runtime().guaranteed_success_action_completions = 1000
	game.fishing_runtime.star_rod_collected = false
	game._action_runtime().invalidate_stat_cache()
	await show_location("river-bend", "")
	await select_module_tool("river-bend","reinforced_rod")
	await show_location("river-bend", "")
	var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing","river-bend")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(),true)
	root.size = Vector2i(1920,1080)
	await settle(3)
	game.desktop_layout.focus_column(0)
	var definition: Dictionary = game._fishing_ui_surface().render_area_module_for_action("fishing","river-bend")
	var key: String = game.fishing_runtime.area_module_key("fishing",definition)
	await game._skill_detail_surface()._scroll_to_activity_card(key,false,true)
	await settle(.8)
	await capture_demo("rod-active-desktop")
	print("SPLASH_SYNC_DEMO_READY failures=",JSON.stringify(failures))

func audit_splash_sync() -> void:
	await open_notes_skill("fishing")
	await show_location("river-bend", "")
	await select_module_tool("river-bend", "net", "wallet-left-corner")
	await select_module_tool("rapids", "star_rod", "wallet-right-corner")
	var fish = game.fishing_runtime
	game.material_runtime.set_amount("softwood",10000)
	for tool in ["hands","net","line","reinforced_rod","star_rod","boat","mirror"]:
		fish.reinforced_rod_collected = tool != "line"
		fish.star_rod_collected = tool not in ["line","reinforced_rod"]
		game._action_runtime().invalidate_stat_cache()
		await settle(.25)
		var id := "open-water" if tool == "boat" else ("reflection" if tool == "mirror" else "river-bend")
		await show_location(id,"")
		await select_module_tool(id,tool)
		await show_location(id,"")
		var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing",id)
		await click((method.method_image_hit_control as Control).get_global_rect().get_center(),true)
		await settle(.4)
		var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing",id)
		var stage = area.active_tool_layer
		for frame in range(360):
			await process_frame
			area = game._fishing_ui_surface()._fishing_area_card_for_action("fishing",id)
			if area.is_empty(): continue
			stage = area.active_tool_layer
			if stage.pose_initialized and stage.size.y >= 200.0 and stage.modulate.a >= .99: break
		check(stage.size.y >= 200.0,"Production layout settled before timing sweep: " + tool)
		check(stage.is_visible_in_tree() and stage.tool_id == tool,"Actual UI mounts the chosen tool: " + tool)
		game.set_process(false)
		stage.set_tool(tool,game._fishing_ui_surface()._fishing_small_tool_icon_texture(tool),str(area.area_def.get("fluid","water")))
		var initial: int = stage.splash_sequence
		var triggers: Array = []
		for frame in range(241):
			var p := float(frame)/240.0
			var previous: int = stage.splash_sequence
			stage.advance(p,-1.0,1.0/120.0,false)
			check(stage.immersion_depth() <= 5.05,"Shallow contact remains bounded: " + tool)
			if stage.splash_sequence != previous:
				check(tool in ["hands","mirror"] and p > .72,"No splash on the way into water: " + tool)
				check(stage.interaction_depth() <= .5,"Splash starts at surface exit: " + tool)
				triggers.append({"cycle_progress":p,"depth":stage.interaction_depth()})
		var expected := 0
		check(stage.splash_sequence-initial == expected,"No premature splash before completion: " + tool)
		initial = stage.splash_sequence
		for frame in range(241):
			var h := float(frame)/240.0
			var previous: int = stage.splash_sequence
			stage.advance(.65,h,1.0/120.0,false)
			check(stage.immersion_depth() <= 5.05,"Shallow haul remains bounded: " + tool)
			if stage.splash_sequence != previous:
				check(h < (.65 if tool in ["hands","mirror"] else .5),"Splash belongs to the outward haul: " + tool)
				if tool != "boat": check(stage.interaction_depth() <= .5,"Haul splash starts at surface exit: " + tool)
				triggers.append({"haul_progress":h,"depth":stage.interaction_depth()})
		check(stage.splash_sequence-initial == 1,"Exactly one exit burst per haul: " + tool)
		# A right-only burst must start immediately, just like a left-only one.
		check(stage.splash_delay <= .06,"Second sheet offset stays within 60ms: " + tool)
		sync_measurements.append({"tool":tool,"stage_size":[stage.size.x,stage.size.y],"triggers":triggers})
		print("SPLASH_TOOL ",tool," stage=",stage.size," triggers=",JSON.stringify(triggers))
		game.set_process(true)
		game._action_runtime()._stop_running_action("fishing",id)
		await settle(.1)
	game._action_runtime().guaranteed_success_action_completions = 1000
	await show_location("shallows","")
	await select_module_tool("shallows","hands")
	var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing","shallows")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(),true)
	var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing","shallows")
	var stage = area.active_tool_layer
	var previous_sequence: int = stage.splash_sequence
	var previous_image: Image
	var saw_contact := false
	var captured := false
	for frame in range(1800):
		await RenderingServer.frame_post_draw
		area = game._fishing_ui_surface()._fishing_area_card_for_action("fishing","shallows")
		if area.is_empty(): continue
		var current_stage = area.active_tool_layer
		if not is_instance_valid(stage) or current_stage != stage:
			stage = current_stage
			previous_sequence = stage.splash_sequence
			saw_contact = false
			previous_image = null
		if stage.interaction_depth() > .5: saw_contact = true
		if saw_contact and stage.splash_sequence != previous_sequence:
			check(stage.interaction_depth() <= .5,"Real hands splash follows its rendered water exit")
			if previous_image != null: previous_image.save_png(capture_dir + "/hands-before-pull.png")
			await capture("hands-surface-exit")
			var fish_pop: Control = null
			for node in (area.catch_burst as Control).find_children("*","TextureRect",true,false):
				if node.get_meta("fishing_catch_particle",false): fish_pop = node; break
			check(is_instance_valid(fish_pop),"Real rewarded fish launches on the same frame as the water exit")
			var launch_y: float = fish_pop.position.y if is_instance_valid(fish_pop) else 0.0
			await settle(.15)
			await capture("hands-splash-rising")
			if is_instance_valid(fish_pop): check(fish_pop.modulate.a > .9,"Fish is fully readable after emergence")
			var quick_y: float = fish_pop.position.y if is_instance_valid(fish_pop) else 0.0
			await settle(.5)
			await capture("hands-splash-falling")
			if is_instance_valid(fish_pop):
				check(quick_y < launch_y and fish_pop.position.y < quick_y,"Fish keeps drifting upward after its quick launch")
				check((launch_y-quick_y)/.15 > (quick_y-fish_pop.position.y)/.5,"Fish rises quickly, then decelerates")
				check(fish_pop.modulate.a > 0.0 and fish_pop.modulate.a <= 1.0,"Fish fades during the late upward drift")
			await settle(.8)
			await capture("hands-settled")
			check(not is_instance_valid(fish_pop),"Fish fades away and is released")
			captured = true
			break
		previous_sequence = stage.splash_sequence
		if saw_contact and game.action_progress > .72:
			previous_image = root.get_texture().get_image()
	check(captured,"Natural hands cycle produced exit-synchronized splash proof")
	await audit_rod_pullback()
	var output := FileAccess.open(capture_dir + "/result.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"tools":sync_measurements,"natural_hands_capture":captured,"failures":failures},"  "))

func audit_rod_pullback() -> void:
	game._action_runtime()._stop_running_action("fishing","shallows")
	game.fishing_runtime.star_rod_collected = false
	game.fishing_runtime.reinforced_rod_collected = true
	game._action_runtime().invalidate_stat_cache()
	await show_location("river-bend", "")
	await select_module_tool("river-bend","reinforced_rod")
	await show_location("river-bend", "")
	var surface = game._fishing_ui_surface()
	var method: Dictionary = surface._fishing_method_card_for_action("fishing","river-bend")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(),true)
	var saw_rest := false
	var captured_pull := false
	var resting_angle := 0.0
	var resting_line_y := 0.0
	for frame in range(1800):
		await RenderingServer.frame_post_draw
		var area: Dictionary = surface._fishing_area_card_for_action("fishing","river-bend")
		if area.is_empty(): continue
		var stage = area.active_tool_layer
		if stage.tool_id != "reinforced_rod" or not stage.pose_initialized or stage.size.y < 200: continue
		if not saw_rest and stage.interaction_depth() > 0.5 and game.action_progress > .65:
			saw_rest = true
			resting_angle = stage.art.rotation
			resting_line_y = stage.line_end.y
			await capture("rod-resting")
		if saw_rest and stage.splash_age < .12 and stage.rod_lift > .1:
			check(stage.art.rotation < resting_angle-.1,"Rod visibly pulls back before line emergence")
			check(stage.line_end.y < resting_line_y,"Rod pull carries its line upward")
			await capture("rod-surface-exit")
			await settle(.12)
			await capture("rod-pulled-back")
			await settle(.9)
			await capture("rod-settled")
			captured_pull = true
			break
	check(captured_pull,"Natural rod haul produces rest, pull and return proof")

func audit_wallet_comparison() -> void:
	await show_location("river-bend", "")
	var surface = game._fishing_ui_surface()
	var method: Dictionary = surface._fishing_method_card_for_action("fishing","river-bend")
	var anchor: Control = method.tool_selector
	await click(anchor.get_global_rect().get_center(),true)
	await settle(.3)
	var popup: Control = surface.fishing_tool_wallet_popup
	check(is_instance_valid(popup),"Comparison wallet opens through UI")
	if not is_instance_valid(popup): return
	var previous_food := ""
	for tool in ["net","reinforced_rod"]:
		for choice in popup.find_children("*","Button",true,false):
			if str(choice.get_meta("tool_id","")) == tool:
				await click(choice.get_global_rect().get_center(),true)
				break
		await settle(.3)
		check(surface.fishing_tool_wallet_popup == popup and surface.fishing_tool_wallet_open,"Repeated gear choices preserve the same wallet")
		check(game.fishing_runtime.tool_id_for_action("river-bend") == tool,"Comparison selects "+tool)
		check(is_instance_valid(anchor) and method.tool_selector == anchor,"Selection preserves the production control")
		for choice in popup.find_children("*","Button",true,false):
			check(bool(choice.get_meta("tool_selected",false)) == (str(choice.get_meta("tool_id","")) == tool),"Wallet highlight follows selection")
		var food := str((method.rate_food as Label).text)
		if not previous_food.is_empty(): check(food != previous_food,"Rate estimate updates without closing the wallet")
		previous_food = food
		await capture("wallet-comparison-"+tool)
	await click(Vector2(1040,420),true)
	await settle(.4)
	check(not surface.fishing_tool_wallet_open,"Outside tap closes comparison wallet")
