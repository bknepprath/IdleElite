extends "res://scripts/tests/ad_bonus_page_capture.gd"

func _run() -> void:
	create_timer(180).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "0")
	ProjectSettings.set_setting("application/config/itch_browser", false)
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "170")
	AudioServer.set_bus_mute(0, true)
	capture_dir = "res://outputs/verification/accounts"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1080,1920)
	root.content_scale_size = Vector2i(1080,1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for _frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized,"Production main scene must boot")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	for skill in game.skill_defs:
		game.skills[skill.id] = {"xp":SkillState.xp_for_level(99),"level":99}
		for action in game.actions_by_skill[skill.id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(skill.id,str(action.id))
			if MasteryState.action_has_mastery(game,action):
				game.mastery[str(skill.id)+":"+str(action.id)] = {"xp":MasteryState.xp_for_level(3),"level":3}
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game,false),game._save_runtime().achievement_toast_seen_ids,[])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	game._halloween_runtime().launch_greeting_claimed = true
	game._halloween_runtime().dismiss_launch_greeting()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.desktop_layout.restore_preferences({})
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.2)

	var online = game._online_runtime()
	online.google_auth_plugin = FakeGoogle.new()
	online.google_auth_plugin_connected = true
	online.leaderboard_auth_in_flight = false
	online.leaderboard_auth_provider = "anonymous"
	online.leaderboard_auth_recovery_required = false
	online.google_auth_status_message = ""
	game.current_screen = "skill"
	game._navigation_shell()._render_screen()
	await settle(1.0)
	var ui = game._profile_chat_overlay_surface()
	await click(game.settings_tab.get_global_rect().get_center())
	await settle(0.8)
	check(button("Account") != null, "Account entry available in Settings")
	if button("Account") != null:
		await click(button("Account").get_global_rect().get_center())
	await settle(0.8)
	check(ui._profile_overlay_visible(), "Actual profile UI opened")
	check(button("Sign in with Google") != null, "Google connection shown")
	await capture("guest-profile")
	# Local fixtures only: authenticate no real person and make no network writes.
	online.leaderboard_auth_provider = "google"
	online.leaderboard_auth_bound_uid = game.leaderboard_profile.player_id
	online.cloud_save_history_in_flight = true
	online.cloud_save_pending_history_purpose = "snapshot"
	online.cloud_save_pending_history_record = {"revision": 3}
	online.cloud_save_remote_revision = 3
	online.cloud_save_status_message = "Cloud save uploaded."
	ui._rebuild_profile_overlay_if_visible()
	await settle(0.4)
	check(account_status() == "Saving...", "Status waits for history backup")
	online._on_cloud_save_history_completed(HTTPRequest.RESULT_SUCCESS, 204, PackedStringArray(), PackedByteArray())
	await settle(0.4)
	check(account_status() == "Saved to your Google account", "Status refreshes after history backup")
	check(button("Save now") == null, "Automatic saves need no manual save button")
	await capture("account-save-ready")
	online.cloud_save_conflict_detected = true
	online.cloud_save_last_remote_payload = game._save_runtime()._save_payload(game._unix_now()-3600)
	online.cloud_save_last_remote_payload.skills.fight.level = 50
	online.cloud_save_last_remote_payload.skills.fight.xp = SkillState.xp_for_level(50)
	online.cloud_save_remote_etag = '"fixture"'
	online.cloud_save_remote_revision = 3
	ui._rebuild_profile_overlay_if_visible()
	await settle(0.8)
	var choose = button("Choose save")
	check(choose != null, "Conflict selection available")
	if choose != null:
		await click(choose.get_global_rect().get_center())
	await capture("save-choice")
	check(button("Use cloud save") != null, "Cloud choice present")
	check(button("Use this device") != null, "Device choice present")
	if button("Cancel") != null:
		await click(button("Cancel").get_global_rect().get_center())
	check(not game._settings_surface().privacy().visible(), "Cancel preserves current game")
	if button("Done") != null:
		await click(button("Done").get_global_rect().get_center())
	await settle(0.5)
	await capture("settings-ad-icon")
	print("ACCOUNT_UI failures=", failures)
	var report := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures": failures, "width": root.size.x, "height": root.size.y}))
	report.close()
	game.queue_free()
	await settle(.4)
	quit(0 if failures.is_empty() else 1)

class FakeGoogle extends RefCounted:
	func sign_in() -> int: return OK

func button(text: String) -> Button:
	for item in game.find_children("*", "Button", true, false):
		if item.text == text and item.is_visible_in_tree(): return item
	return null

func account_status() -> String:
	for item in game.find_children("*", "Label", true, false):
		if item.get_meta("account_save_status", false) and item.is_visible_in_tree() and not item.is_queued_for_deletion(): return item.text
	return ""
