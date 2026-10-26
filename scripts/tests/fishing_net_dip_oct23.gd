extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	await settle(1.0)
	if game._halloween_runtime().greeting_visible():
		await click(Vector2(540, 950), true)
		await settle(0.5)
	await open_notes_skill("fishing")
	if game.current_screen != "skill":
		await capture("navigation-blocked")
		game.queue_free()
		await process_frame
		quit(1)
		return
	game._action_runtime().guaranteed_success_action_completions = 1000
	for id in ["river-bend", "drain-gate"]:
		await show_location(id, "")
		await select_module_tool(id, "net")
		await show_location(id, "")
		var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", id)
		if method.is_empty():
			await capture("missing-location")
			game.queue_free()
			await process_frame
			quit(1)
			return
		game.fishing_runtime.net_stored_fish = 0
		await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
		await settle(0.5)
		var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", id)
		var stage = area.active_tool_layer
		var dip_start: int = stage.dip_sequence
		var haul_start: int = stage.splash_sequence
		var previous: Image
		var dipped := false
		var hauled := false
		var maximum_depth := -100.0
		var started := Time.get_ticks_msec()
		while Time.get_ticks_msec() - started < 25000:
			await process_frame
			maximum_depth = maxf(maximum_depth, stage.interaction_depth())
			check(stage.immersion_depth() <= 5.05, "Net stays shallow: " + id)
			if not dipped and stage.dip_sequence > dip_start:
				dipped = true
				check(stage.splash_sequence == haul_start, "Dip does not trigger a catch: " + id)
				check(stage.splash_draw_scale == 0.55, "Small entry splash: " + id)
				if previous != null: previous.save_png(capture_dir + "/" + id + "-before-dip.png")
				await settle(0.16)
				await capture(id + "-dip")
				game.fishing_runtime.net_stored_fish = 9
			if dipped and stage.splash_sequence > haul_start:
				hauled = true
				check(stage.splash_draw_scale == 1.0, "Larger withdrawal splash: " + id)
				if previous != null: previous.save_png(capture_dir + "/" + id + "-before-catch.png")
				await settle(0.16)
				await capture(id + "-catch")
				await settle(0.55)
				var catch_still_visible := false
				for burst in stage.active_splashes:
					if burst.scale == 1.0 and burst.age < burst.lifetime: catch_still_visible = true
				check(catch_still_visible, "Return dip does not erase the catch splash: " + id)
				await capture(id + "-falling")
				await settle(0.8)
				await capture(id + "-settled")
				break
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				previous = root.get_texture().get_image()
		check(dipped and hauled, "Live net dips and hauls in " + id)
		check(stage.splash_material.get_shader_parameter("water_color") == stage.fluid_color, "Splash matches pool: " + id)
		print("NET_DIP ", id, " size=", stage.size, " maximum_depth=", maximum_depth, " dipped=", dipped, " hauled=", hauled)
		game._action_runtime()._stop_running_action("fishing", id)
		await settle(0.2)
	print("NET_DIP failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
