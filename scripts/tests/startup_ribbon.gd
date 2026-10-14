extends "res://scripts/tests/first_session_input.gd"

var samples: Array = []
var exposed_incomplete := 0
var premature_ribbon := 0
var run_label := "baseline"

func _run() -> void:
	create_timer(100).timeout.connect(func(): quit(1))
	run_label = OS.get_environment("IDLE_ELITE_AUDIT_LABEL")
	if run_label.is_empty(): run_label = "baseline"
	capture_dir = "res://.codex-tmp/audit-2026-10-14/" + run_label
	DirAccess.make_dir_recursive_absolute(capture_dir)
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "95")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	var settled_frames := 0
	for frame in range(2400):
		await process_frame
		if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
		var boot = game._boot_warmup_runtime()
		var covered: bool = is_instance_valid(boot.overlay) and boot.overlay.visible and boot.overlay.modulate.a >= 0.999
		var desktop = game.desktop_layout
		var mounted: bool = desktop.ready and not desktop.rendering and not game._navigation_shell().screen_render_in_progress and desktop.columns.size() == desktop.page_count()
		if not covered and game.startup_initialized:
			if not mounted: exposed_incomplete += 1
			var nav = game._navigation_shell()
			if is_instance_valid(nav.nav_bar) and nav.nav_bar.is_visible_in_tree(): premature_ribbon += 1
			if is_instance_valid(desktop.toolbar) and desktop.toolbar.is_visible_in_tree() and desktop.intro_stage == 0: premature_ribbon += 1
			samples.append({"frame": frame, "mounted": mounted, "stage": desktop.intro_stage})
			if not mounted and exposed_incomplete == 1: save_frame("incomplete-boot")
		if not boot.active and mounted:
			settled_frames += 1
			if settled_frames >= 30: break
	check(game.startup_initialized, "Production scene finishes boot")
	check(exposed_incomplete == 0, "Boot must cover desktop construction through its final frame")
	check(premature_ribbon == 0, "Fresh opening never exposes either ribbon before its milestone")
	await capture("ribbon-before")
	var target: Control = game._tutorial_overlay_surface()._tutorial_target_control()
	check(is_instance_valid(target), "Actual tutorial target is available")
	if is_instance_valid(target): await click(target.get_global_rect().get_center())
	check(game.running_action_id == "push-ups", "Actual UI starts Push-Ups")
	var max_alpha := 0.0
	var alpha_regressions := 0
	var split_fade_frames := 0
	var position_jumps := 0
	var last_position := Vector2.ZERO
	var first_visible := false
	var transition_captured := false
	var ribbon_id: int = game.desktop_layout.toolbar.get_instance_id()
	for frame in range(1000):
		await process_frame
		if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
		var ribbon: Control = game.desktop_layout.toolbar
		var alpha := ribbon.modulate.a * ribbon.self_modulate.a if ribbon.is_visible_in_tree() else 0.0
		if alpha > 0.0 and alpha < 0.99 and not is_equal_approx(ribbon.modulate.a, alpha): split_fade_frames += 1
		if alpha + 0.015 < max_alpha: alpha_regressions += 1
		max_alpha = maxf(alpha, max_alpha)
		if alpha > 0.0:
			if first_visible and ribbon.position.distance_to(last_position) > 1.0: position_jumps += 1
			last_position = ribbon.position
			first_visible = true
		if not transition_captured and alpha > 0.15 and alpha < 0.9:
			save_frame("ribbon-transition")
			transition_captured = true
		if game.desktop_layout.intro_stage >= 2 and game.desktop_layout.intro_reveal_elapsed >= game.desktop_layout.INTRO_REVEAL_SECONDS: break
	check(max_alpha >= 0.999, "First completion reveals the ribbon")
	check(alpha_regressions == 0, "Ribbon never disappears or restarts its entrance")
	check(split_fade_frames == 0, "Ribbon icons and backing inherit the same entrance opacity")
	check(position_jumps == 0, "Ribbon stays stationary throughout introduction")
	check(game.desktop_layout.toolbar.get_instance_id() == ribbon_id, "Neighbor introduction retains the ribbon instance")
	await capture("ribbon-settled")
	var result := {"exposed_incomplete_frames": exposed_incomplete, "premature_ribbon_frames": premature_ribbon, "alpha_regressions": alpha_regressions, "position_jumps": position_jumps, "failures": failures, "samples": samples}
	FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE).store_string(JSON.stringify(result, "\t"))
	print("STARTUP_RIBBON ", JSON.stringify({"exposed_incomplete_frames": exposed_incomplete, "premature_ribbon_frames": premature_ribbon, "alpha_regressions": alpha_regressions, "position_jumps": position_jumps, "failures": failures}))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func save_frame(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var picture := root.get_texture().get_image()
	check(picture.get_size() == Vector2i(1920,1080), "Raw viewport dimensions are 1920x1080")
	picture.save_png(capture_dir + "/" + label + ".png")

func capture(label: String) -> void:
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
	save_frame(label)
