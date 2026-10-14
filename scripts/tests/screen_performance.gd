extends SceneTree

const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const SCREENS := ["menu", "hub", "shop", "achievements", "settings", "queue", "pinned", "leaderboard"]
var game: Node
var samples: Array = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await process_frame
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	if not game.startup_initialized or game._boot_warmup_runtime().active:
		push_error("Screen performance boot failed")
		quit(1)
		return
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._test_state_runtime()._god_mode_max_skills_state()
	game._test_state_runtime()._god_mode_unlock_actions_state()
	var keys: Array = []
	for skill in ["build", "woodcutting", "thieving", "fight"]:
		for action in game.actions_by_skill[skill].slice(0, 4):
			keys.append(ModuleUiRuntime.action(skill, str(action.id)))
	game.module_ui_runtime.pinned_order = keys.duplicate()
	game._activity_queue_runtime().activity_queue = keys.duplicate()
	Engine.max_fps = 0
	for cycle in range(2):
		for screen in SCREENS:
			game.current_screen = screen
			var started := Time.get_ticks_usec()
			await game._navigation_shell()._render_screen(false, -1, false)
			var entry_us := Time.get_ticks_usec() - started
			for i in range(90):
				await process_frame
			await sample(screen, "idle", cycle, entry_us)
			await sample(screen, "scroll", cycle, entry_us)
		await sample_overlays(cycle)
	var output := FileAccess.open("res://.codex-tmp/screen-performance.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(samples, "\t"))
	output.close()
	print("screen-performance-audit-ok")
	quit(0)

func sample_overlays(cycle: int) -> void:
	game.current_screen = "menu"
	await game._navigation_shell()._render_screen(false, -1, false)
	var surface = game._profile_chat_overlay_surface()
	var started := Time.get_ticks_usec()
	surface._ensure_profile_overlay()
	surface.profile_avatar_picker_open = false
	surface._rebuild_profile_overlay()
	surface.profile_overlay.show()
	var entry_us := Time.get_ticks_usec() - started
	for i in range(45):
		await process_frame
	await sample("profile", "idle", cycle, entry_us, surface.profile_overlay)
	await sample("profile", "scroll", cycle, entry_us, surface.profile_overlay)
	surface._hide_profile_overlay()
	var rows: Array = []
	for i in range(60):
		rows.append({"message_id":"perf-%s" % i, "sender_id":"performance-test", "name":"guest0001", "total_level":1, "avatar_index":0, "created_at_unix":i + 1, "text":"Offline performance test message %s" % i, "deleted":false})
	game._online_runtime().chat_rows = rows
	started = Time.get_ticks_usec()
	surface._ensure_chat_overlay()
	surface.chat_overlay.show()
	surface._ensure_chat_overlay_shell()
	surface._sync_chat_overlay_rows()
	entry_us = Time.get_ticks_usec() - started
	for i in range(45):
		await process_frame
	await sample("chat", "idle", cycle, entry_us, surface.chat_overlay)
	await sample("chat", "scroll", cycle, entry_us, surface.chat_overlay)
	surface._close_chat_overlay(false)

func sample(screen: String, mode: String, cycle: int, entry_us: int, scope: Node = null) -> void:
	var frames: Array[int] = []
	var scroll: Control
	var max_scroll := 0
	var sample_root: Node = scope if scope != null else game.skills_content
	for candidate in sample_root.find_children("*", "ScrollContainer", true, false):
		if candidate.is_visible_in_tree() and candidate.has_method("get_max_scroll_vertical"):
			var limit := int(candidate.get_max_scroll_vertical())
			if limit > max_scroll:
				scroll = candidate
				max_scroll = limit
	var over_60 := 0
	for i in range(240):
		var started := Time.get_ticks_usec()
		if mode == "scroll" and max_scroll > 0:
			var y := roundi(max_scroll * (0.5 - cos(float(i) / 239.0 * TAU) * 0.5))
			scroll.drag_scroll_position = float(y)
			scroll.scroll_vertical = y
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frames.append(elapsed)
		if elapsed > 16667:
			over_60 += 1
	frames.sort()
	var result := {"screen":screen, "mode":mode, "cycle":cycle, "entry_us":entry_us, "p50_us":frames[120], "p99_us":frames[237], "max_us":frames[-1], "over_60":over_60, "max_scroll":max_scroll, "scroll_sampled":mode == "scroll" and max_scroll > 0, "nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}
	samples.append(result)
	print("SCREEN_PERF ", JSON.stringify(result))
