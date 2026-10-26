extends "res://scripts/tests/action_art_oct22.gd"

const Wisdom = preload("res://scripts/progression/wisdom_state.gd")

func audit_action_art() -> void:
	await settle(1.0)
	if game._halloween_runtime().greeting_visible():
		await click(Vector2(540, 950), true)
		await settle(0.5)
	var unlocks = game._activity_unlock_runtime()
	var projects = game._project_runtime()
	game.material_runtime.wisdom_by_skill.fishing = 0
	for skill_id in game.actions_by_skill:
		for action in game.actions_by_skill[skill_id]:
			if skill_id == "fishing":
				check(int(action.get("wisdom_reward", 0)) == 0 and int(action.get("wisdom_required", 0)) == 0, "Fishing has no Wisdom: " + str(action.id))
			elif int(action.get("wisdom_required", 0)) > 0:
				check(str(action.get("wisdom_skill", skill_id)) != "fishing", "Other skill does not require Fishing Wisdom")
	for action_id in ["chum-line", "deep-trench"]:
		var action: Dictionary = game._action_data("fishing", action_id)
		unlocks.manual_activity_unlocks.erase("fishing:" + action_id)
		check(unlocks._can_unlock_action("fishing", action), "Zero Wisdom permits eligible unlock: " + action_id)
		var project_id := str(action.unlock_project.id)
		var completed: Dictionary = projects.work[project_id].duplicate()
		projects.work[project_id] = {}
		check(not unlocks._can_unlock_action("fishing", action), "Resource requirements remain: " + action_id)
		projects.work[project_id] = completed
		unlocks._mark_action_manually_unlocked("fishing", action_id)
	check(not Wisdom.applicable(game, "fishing") and Wisdom.sources(game, "fishing").is_empty(), "Fishing exposes no Wisdom UI or sources")
	game.material_runtime.restore_wallet({"wisdom": {"fishing": 123, "build": 12}})
	game._action_runtime()._award_action_mat_rewards(game._action_data("fishing", "river-bend"))
	check(Wisdom.total(game, "fishing") == 123, "Fishing no longer earns Wisdom; historical balance survives")
	var payload: Dictionary = game._save_runtime()._save_payload(game._unix_now())
	game.material_runtime.restore_wallet(payload)
	check(Wisdom.total(game, "fishing") == 123, "Legacy save balance round-trips without affecting access")
	Wisdom.award(game, game._action_data("build", "study-blueprint"))
	check(Wisdom.total(game, "build") == 13, "Other skills still earn their own Wisdom")
	unlocks.manual_activity_unlocks.erase("build:frame-a-treehouse-platform")
	check(not unlocks._can_unlock_action("build", game._action_data("build", "frame-a-treehouse-platform")), "Other skills keep their Wisdom gates")
	await open_notes_skill("fishing")
	await show_location("river-bend", "")
	var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	check(not method.is_empty(), "River Bend is mounted in the real Fishing screen")
	check(game.find_children("WisdomRewardBadge", "", true, false).is_empty(), "No book badge is created in Fishing")
	if not method.is_empty():
		await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
		await settle(0.5)
		await capture("river-without-wisdom")
	var nav = game._navigation_shell()
	check(is_equal_approx(game.skills_tab.get_global_rect().get_center().x, 540.0), "Middle navigation icon is centered")
	check(is_equal_approx(nav.hero_tab.get_global_rect().get_center().x + nav.shop_tab.get_global_rect().get_center().x, 1080.0), "Outer navigation buttons are symmetric")
	await click(game._profile_chat_overlay_surface().chat_strip_control().get_global_rect().get_center(), true)
	await settle(0.5)
	check(game._profile_chat_overlay_surface().chat_overlay_visible(), "Chat reached through actual UI")
	check(is_equal_approx(nav.chat_home_tab.get_global_rect().get_center().x + nav.chat_shop_tab.get_global_rect().get_center().x, 1080.0), "Chat ribbon is symmetric")
	await capture("chat-centered-ribbon")
	print("FISHING_WITHOUT_WISDOM failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
