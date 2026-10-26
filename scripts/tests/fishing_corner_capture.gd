extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	if game._halloween_runtime().greeting_visible():
		await click(Vector2(540, 950), true)
		await settle(0.4)
	# Leave real resource projects unfinished so their source badges are visible.
	for action_id in ["chum-line", "drain-gate"]:
		game._activity_unlock_runtime().manual_activity_unlocks.erase(game._action_key("fishing", action_id))
		var action: Dictionary = game._action_data("fishing", action_id)
		game._project_runtime().work[str(action.unlock_project.id)] = {}
	game.material_runtime.set_amount("lures", 0)
	game.fishing_runtime.select_location_tool("river-bend", "net")
	game.fishing_runtime.select_location_tool("rapids", "star_rod")
	game._project_runtime().queue_availability_refresh()
	await open_notes_skill("fishing")
	var method: Dictionary = await show_location("river-bend", "")
	await settle(0.6)
	await capture("river-corners")
	var fishing = game._fishing_ui_surface()
	for action_id in ["river-bend", "rapids"]:
		var location: Dictionary = fishing._fishing_method_card_for_action("fishing", action_id)
		var square: Rect2 = location.art_panel.get_global_rect()
		var tool: Rect2 = location.tool_selector.get_global_rect()
		var owner: Dictionary = fishing._fishing_area_card_for_action("fishing", action_id)
		var module_rect: Rect2 = owner.pop.get_global_rect()
		check(module_rect.end.y - tool.end.y >= 14.0, "Tool clears module bottom by at least fourteen pixels: " + action_id)
		check(tool.get_center().distance_to(square.end) < 1, "Tool occupies bottom-right: " + action_id)
		for badge in location.art_panel.find_children("*", "Control", true, false):
			if badge.has_method("accepts_tap_at") and badge.is_visible_in_tree():
				check(badge.get_global_rect().has_point(Vector2(square.end.x, square.position.y)), "Resource occupies top-right: " + action_id)
				check(not tool.intersects(badge.get_global_rect().grow(14)), "Resource and tool taps remain separate")
	await click(method.tool_selector.get_global_rect().get_center(), true)
	await settle(0.35)
	check(fishing.is_fishing_tool_wallet_open(), "Bottom-right tool opens wallet through real input")
	check(fishing.fishing_tool_wallet_popup.get_global_rect().has_point(method.tool_selector.get_global_rect().get_center()), "Wallet follows relocated selector")
	check(not fishing.fishing_tool_wallet_popup.get_global_rect().intersects(method.rate_panel.get_global_rect()), "Raised rate estimates clear the tool wallet")
	await capture("river-tool-wallet")
	await click(Vector2(540, 805), true)
	await settle(0.3)
	check(not fishing.is_fishing_tool_wallet_open(), "Outside tap closes wallet")
	method = await show_location("river-bend", "river-before-start")
	print("CORNERS_START rect=", method.method_image_hit_control.get_global_rect())
	await click(method.method_image_hit_control.get_global_rect().get_center(), true)
	await settle(0.8)
	check(game.running_action_id == "river-bend", "Action remains independently clickable")
	await capture("river-active")
	game._action_runtime()._stop_running_action("fishing", "river-bend")
	await show_location("tunnel-pool", "sewer-corners")
	var report := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures": failures}))
	report.close()
	print("FISHING_CORNERS failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
