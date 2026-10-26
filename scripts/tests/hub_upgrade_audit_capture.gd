extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var runtime=game._hub_runtime()
	var hub=game._hub_surface()
	hub.hub_tutorial_tip_seen=true
	for material in ["softwood","hardwood"]: game.material_runtime.set_amount(material,1000)
	game.fishing_runtime.fish_currency=10000
	for id in runtime.HUB_MODULE_ORDER: runtime.hub_modules[id]={"level":0,"building":false,"build_started_unix_msec":0}
	await click(game._navigation_shell().hub_tab.get_global_rect().get_center(),true)
	await settle(.5)
	check(game.current_screen=="hub","Hub reached through the real navigation ribbon")
	for level in range(5):
		for id in runtime.HUB_MODULE_ORDER: runtime.hub_modules[id]={"level":level,"building":false,"build_started_unix_msec":0}
		game._navigation_shell()._render_screen()
		await settle(.35)
		for id in runtime.HUB_MODULE_ORDER:
			check((hub.hub_module_art[id] as Control).size == hub._hub_module_visual_size(id, level), "Authored prop size used at level " + str(level) + ": " + id)
		await capture("hub-all-level-"+str(level))
	for id in runtime.HUB_MODULE_ORDER: runtime.hub_modules[id]={"level":0,"building":false,"build_started_unix_msec":0}
	game._navigation_shell()._render_screen()
	await settle(.4)
	for id in ["barn","garden","pond","mission","woodcutting_totem","fighting_display"]:
		var art: Control=hub.hub_module_art[id]
		await click(art.get_global_rect().get_center(),true)
		await settle(.4)
		check(hub.hub_detail_open,"Actual hub object opens its upgrade panel: "+id)
		await capture("upgrade-"+id)
		hub._close_hub_detail_popup()
		await settle(.4)
	await audit_mission_recovery(runtime, hub)
	print("HUB_UPGRADE_AUDIT failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)

func audit_mission_recovery(runtime, hub) -> void:
	var normalizers = load("res://scripts/save_state/normalizers.gd")
	var now := int(round(Time.get_unix_time_from_system() * 1000.0))
	for id in runtime.HUB_MODULE_ORDER:
		for broken_start in [0, now + 86400000]:
			runtime.hub_modules[id] = {"level": 2, "building": true, "build_started_unix_msec": broken_start}
			var restored: Dictionary = runtime.ensure_module_state(id)
			check(int(restored.level) == 2 and bool(restored.building), "Timer repair preserves paid levels and construction: " + id)
			check(abs(int(restored.build_started_unix_msec) - now) < 3000, "Missing/future construction clock repairs: " + id)
			check(runtime.module_build_remaining_seconds(id) <= 15, "Repaired clock has a finite countdown: " + id)
			var roundtrip: Dictionary = normalizers.hub_module_state(JSON.parse_string(JSON.stringify(restored)), 4)
			check(roundtrip == restored, "Repaired timer survives save roundtrip: " + id)
			runtime.hub_modules[id].build_started_unix_msec = now - 16000
			check(id in runtime.complete_ready_builds() and runtime.module_level(id) == 3, "Recovered construction finishes once: " + id)
			check(runtime.complete_ready_builds().is_empty(), "Recovered construction never awards twice: " + id)
	var valid := {"level": 1, "building": true, "build_started_unix_msec": now - 3000}
	check(normalizers.hub_module_state(valid, 4) == valid, "Valid in-progress construction remains unchanged")
	check(int(normalizers.hub_module_state({"level":9,"building":true},4).level) == 4, "Repair retains the upgrade level cap")
	for id in runtime.HUB_MODULE_ORDER: runtime.hub_modules[id] = {"level":0,"building":false}
	game.skills.build.level = 9
	check(not runtime.module_next_level_unlocked("mission"), "Mission retains its Building Lv 10 gate")
	game.skills.build.level = 99
	game.material_runtime.set_amount("softwood", 1000)
	game.material_runtime.set_amount("hardwood", 1000)
	game._navigation_shell()._render_screen()
	await settle(.3)
	await click((hub.hub_module_art.mission as Control).get_global_rect().get_center(), true)
	await settle(.5)
	await click(hub.hub_mission_view_buttons[1].get_global_rect().get_center(), true)
	await settle(.3)
	check(not hub.hub_detail_button.disabled, "An empty hub can build its mission board")
	await click(hub.hub_detail_button.get_global_rect().get_center(), true)
	await settle(.5)
	check(runtime.module_building("mission"), "Actual mission Build button starts paid construction")
	check(game.material_runtime.amount("softwood") == 975, "Build charges 25 Softwood once")
	hub._close_hub_detail_popup()
	await settle(.5)
	await capture("mission-building")
	runtime.hub_modules.mission.build_started_unix_msec = 0
	runtime.ensure_module_state("mission")
	check(game.material_runtime.amount("softwood") == 975, "Repair never charges construction twice")
	runtime.hub_modules.mission.build_started_unix_msec = now - 16000
	runtime.complete_ready_builds()
	game._navigation_shell()._render_screen()
	await settle(.4)
	await capture("mission-built")
	await click((hub.hub_module_art.mission as Control).get_global_rect().get_center(), true)
	await settle(.5)
	await click(hub.hub_mission_view_buttons[1].get_global_rect().get_center(), true)
	await settle(.3)
	check(not hub.hub_detail_button.disabled, "Recovered board can upgrade again")
	await click(hub.hub_detail_button.get_global_rect().get_center(), true)
	await settle(.3)
	check(runtime.module_building("mission") and runtime.module_level("mission") == 1, "Mission upgrade continues from the recovered level")
	check(game.material_runtime.amount("hardwood") == 970, "Next upgrade charges the correct 30 Hardwood")
