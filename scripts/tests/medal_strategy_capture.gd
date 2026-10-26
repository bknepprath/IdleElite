extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	if game._halloween_runtime().greeting_visible():
		await click(Vector2(540,950), true)
		await settle(0.4)
	game.mastery.clear()
	game._hub_runtime().hub_modules.barn = {"level":0,"building":false}
	game._ad_bonus_runtime().seconds_remaining = 0
	for skill_id in game.skills:
		game.skills[skill_id].xp = SkillState.xp_for_level(10)
		game.skills[skill_id].level = 10
	SkillState.invalidate_stat_caches(game)
	await open_notes_skill("build")
	await align_notes_card(await notes_card("stack-bricks"))
	await capture("building-base-cadence")
	for action_id in ["push-ups","kick-mud-off-boot","wrestle-stuck-gate-latch"]:
		game.mastery["fight:"+action_id] = {"level":2,"xp":MasteryState.xp_for_level(2)}
	SkillState.invalidate_stat_caches(game)
	await open_notes_skill("fight")
	await align_notes_card(await notes_card("wrestle-stuck-gate-latch"))
	await capture("third-activity-silver")
	check(is_equal_approx(game._action_runtime()._success_chance("fight",game._action_data("fight","wrestle-stuck-gate-latch")),99.8), "Visible Silver fixture uses 99.8 percent")
	var report := FileAccess.open(capture_dir + "/capture-result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	print("MEDAL_CAPTURE failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
