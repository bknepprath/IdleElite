extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	if game._halloween_runtime().greeting_visible():
		await click(Vector2(540,950),true)
		await settle(.3)
	game._action_runtime().guaranteed_success_action_completions=1000
	await open_notes_skill("fishing")
	for pair in [["net","river-bend"],["hands","rapids"],["line","rapids"],["reinforced_rod","rapids"],["star_rod","rapids"],["boat","open-water"],["mirror","reflection"]]:
		var tool: String=pair[0]
		var id: String=pair[1]
		if tool in ["line","reinforced_rod","star_rod"]:
			game.fishing_runtime.reinforced_rod_collected=tool in ["reinforced_rod","star_rod"]
			game.fishing_runtime.star_rod_collected=tool=="star_rod"
		game.fishing_runtime.select_location_tool(id,tool)
		var method: Dictionary=await show_location(id,"")
		await select_module_tool(id,tool)
		method=game._fishing_ui_surface()._fishing_method_card_for_action("fishing",id)
		await settle(.25)
		check(method.method_title.modulate.a>.99 and method.tool_selector_icon.modulate.a>.99,"Idle identity restored: "+tool)
		await capture(tool+"-before")
		await entry_tap(method.method_image_hit_control.get_global_rect().get_center())
		var area: Dictionary=game._fishing_ui_surface()._fishing_area_card_for_action("fishing",id)
		var stage=area.active_tool_layer
		method=game._fishing_ui_surface()._fishing_method_card_for_action("fishing",id)
		check(game.running_action_id==id,"Real location tap starts "+tool)
		check(stage.tool_id==tool,"Animation uses the chosen tool: "+tool)
		check(stage.location_entry_seconds>0,"Tool starts at its own location: "+tool)
		check(stage.location_entry_start.distance_to(stage.get_global_transform().affine_inverse()*method.tool_selector_icon.get_global_rect().get_center())<5,"Flight starts at the actual corner icon: "+tool)
		await settle(.13)
		method=game._fishing_ui_surface()._fishing_method_card_for_action("fishing",id)
		stage=game._fishing_ui_surface()._fishing_area_card_for_action("fishing",id).active_tool_layer
		check(stage.flying_icon.visible and not stage.art.visible,"One transferred tool replaces stationary tool: "+tool)
		await capture(tool+"-departing")
		await settle(.18)
		method=game._fishing_ui_surface()._fishing_method_card_for_action("fishing",id)
		stage=game._fishing_ui_surface()._fishing_area_card_for_action("fishing",id).active_tool_layer
		await capture(tool+"-morph")
		await settle(.55)
		method=game._fishing_ui_surface()._fishing_method_card_for_action("fishing",id)
		stage=game._fishing_ui_surface()._fishing_area_card_for_action("fishing",id).active_tool_layer
		check(stage.location_entry_seconds==0 and stage.art.visible and not stage.flying_tool.visible,"Flight hands off to live tool: "+tool)
		check(method.method_title.modulate.a<.01 and method.tool_selector_icon.modulate.a<.01,"Active name and corner tool fade out: "+tool)
		check(method.tool_selector.disabled,"Hidden selector does not intercept active tile taps: "+tool)
		await capture(tool+"-active")
		if tool=="net":
			await click(stage.hit.get_global_rect().get_center(),true)
			check(game._fishing_ui_surface().fishing_tool_wallet_open,"Active animated tool opens its location's picker")
			await capture("active-tool-picker")
			await click(Vector2(1040,420),true)
			await settle(.5)
			check(not game._fishing_ui_surface().fishing_tool_wallet_open,"Outside tap closes the active tool picker")
		game._action_runtime()._stop_running_action("fishing",id)
		await settle(.55)
		method=game._fishing_ui_surface()._fishing_method_card_for_action("fishing",id)
		check(method.method_title.modulate.a>.99 and method.tool_selector_icon.modulate.a>.99 and not method.tool_selector.disabled,"Stopping restores location identity and picker: "+tool)
		await capture(tool+"-stopped")
	# A different location with the same tool must still launch its own icon.
	game.fishing_runtime.select_location_tool("river-bend","net")
	game.fishing_runtime.select_location_tool("rapids","net")
	var left: Dictionary=await show_location("river-bend","")
	await entry_tap(left.method_image_hit_control.get_global_rect().get_center())
	await settle(.7)
	left=game._fishing_ui_surface()._fishing_method_card_for_action("fishing","river-bend")
	var right: Dictionary=game._fishing_ui_surface()._fishing_method_card_for_action("fishing","rapids")
	await entry_tap(right.method_image_hit_control.get_global_rect().get_center())
	await settle(.13)
	var owner: Dictionary=game._fishing_ui_surface()._fishing_area_card_for_action("fishing","rapids")
	check(game.running_action_id=="rapids" and owner.active_tool_layer.location_entry_seconds>0,"Switching locations relaunches even the same tool")
	await capture("same-tool-location-switch")
	await settle(.6)
	left=game._fishing_ui_surface()._fishing_method_card_for_action("fishing","river-bend")
	right=game._fishing_ui_surface()._fishing_method_card_for_action("fishing","rapids")
	check(left.method_title.modulate.a>.99 and right.method_title.modulate.a<.01,"Only the active location hides its name")
	await capture("same-tool-switch-active")
	game._action_runtime()._stop_running_action("fishing","rapids")
	await settle(.4)
	print("FISHING_TOOL_ENTRY failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func entry_tap(point: Vector2) -> void:
	for down in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.position=point
		event.index=0
		event.pressed=down
		root.push_input(event,true)
		await process_frame
	await process_frame
