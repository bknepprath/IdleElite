extends SceneTree

const SaveRuntime = preload("res://scripts/save_state/save_runtime.gd")
var failures: Array[String] = []

class AdHost:
	extends RefCounted
	func _reward_feedback_surface():
		return self
	func _set_result(_message: String) -> void:
		pass

class RewardProbe:
	extends "res://scripts/monetization/ad_bonus.gd"
	var grants := 0
	func _grant_ad_bonus(_message: String) -> void:
		grants += 1

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	var ad := RewardProbe.new(AdHost.new())
	ad.press_shop_ad()
	check(ad.grants == 0, "Unsupported/blocked ads must never grant a reward.")
	ad._on_rewarded_ad_user_earned_reward(null)
	check(ad.grants == 0, "A callback outside an active show must be ignored.")
	ad.ad_showing = true
	ad._on_rewarded_ad_user_earned_reward(null)
	ad._on_rewarded_ad_user_earned_reward(null)
	check(ad.grants == 1, "A reward-earned callback must grant once per showing.")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "180")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	var deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if game.startup_initialized and game.save_restore_complete and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized and game.save_restore_complete, "Production main scene must finish restoring.")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	var save = game._save_runtime()
	var lifecycle = game._app_lifecycle_runtime()
	game._navigation_shell().screen_render_in_progress = true
	lifecycle.call_deferred("_repair_after_app_resume")
	await process_frame
	await process_frame
	game._navigation_shell().screen_render_in_progress = false
	await process_frame
	await process_frame
	check(not game.app_resume_repair_pending, "Resume repair must yield frames while navigation is busy, then complete.")
	for cycle in range(5):
		var offer := Control.new()
		game.add_child(offer)
		game._fishing_ui_surface()._start_fishing_net_offer_idle_motion(offer)
		await process_frame
		await process_frame
		var offer_tween: Tween = offer.get_meta("fishing_net_offer_idle_tween")
		offer.queue_free()
		await process_frame
		await process_frame
		check(not offer_tween.is_valid(), "Freeing a fishing offer must terminate its infinite tween.")
	check(save._trusted_offline_seconds(0, game._unix_now()) == 0, "Missing timestamp must not earn maximum offline rewards.")
	game.offline_progress_enabled = false
	lifecycle.suspended_at_unix = game._unix_now() - 120
	save.suspend_saved_at_unix = lifecycle.suspended_at_unix
	check(game.save_game(), "A late background callback may persist state safely.")
	check(int(SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH).get("saved_at", 0)) == lifecycle.suspended_at_unix, "A background save must retain the suspension timestamp.")
	game._ad_bonus_runtime().seconds_remaining = 600.0
	lifecycle._resume_from_app_suspend()
	check(lifecycle.suspended_at_unix == -1, "Resume must clear suspension.")
	check(game._ad_bonus_runtime().seconds_remaining <= 480.0, "Expired boosts must be consumed with offline progress disabled.")
	var after_resume: float = game._ad_bonus_runtime().seconds_remaining
	save.last_save_unix_time = game._unix_now() - 30
	lifecycle._resume_from_app_suspend()
	check(game._ad_bonus_runtime().seconds_remaining == after_resume, "Duplicate resume must not count unsaved foreground time again.")
	var disk := SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	check(int(disk.get("saved_at", 0)) >= game._unix_now() - 1, "Disabled offline progression must persist the consumed interval.")
	game.offline_progress_enabled = true
	lifecycle._save_for_app_suspend()
	var revision: int = save.save_revision
	lifecycle.last_lifecycle_save_monotonic_msec = -10000
	lifecycle._save_for_app_suspend()
	check(save.save_revision == revision, "Repeated background notifications must not advance saved time.")
	var swipe = game._skill_swipe_activity_surface()
	swipe.skill_swipe_tracking = true
	swipe.skill_swipe_horizontal = true
	lifecycle._cancel_interrupted_pointer()
	check(not swipe.skill_swipe_tracking and not swipe.skill_swipe_horizontal, "Window exit must cancel pointer tracking.")
	lifecycle._resume_from_app_suspend()
	var hub = game._hub_runtime()
	hub.hub_mission_cooldown_until_unix = game._unix_now() + 1800
	check(game.save_game(), "Mission deadline save must succeed.")
	disk = SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	var saved_deadline: int = hub.hub_mission_cooldown_until_unix
	hub.hub_mission_cooldown_until_unix = 0
	hub.restore_mission_cooldown(disk)
	check(hub.hub_mission_cooldown_until_unix == saved_deadline, "Restart restore must preserve the absolute mission deadline.")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._test_state_runtime()._god_mode_unlock_actions_state()
	game.offline_progress_enabled = false
	game._settings_surface()._toggle_offline_progress_enabled()
	check(game.offline_progress_enabled, "The production settings toggle must enable offline progression.")
	game._action_runtime()._start_action("woodcutting", str(game.actions_by_skill.woodcutting[0].id), false, false)
	check(game.running_skill_id == "woodcutting", "Offline fixture must start a real activity.")
	var before_offline_xp: int = game.skills.woodcutting.xp
	lifecycle.suspended_at_unix = game._unix_now() - 120
	lifecycle._resume_from_app_suspend()
	check(game.skills.woodcutting.xp > before_offline_xp, "Enabling offline progress in Settings must earn activity XP on resume.")
	var resumed_xp: int = game.skills.woodcutting.xp
	lifecycle._resume_from_app_suspend()
	check(game.skills.woodcutting.xp == resumed_xp, "Repeated resume notifications must not duplicate offline XP.")
	disk = SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	check(int(disk.skills.woodcutting.xp) == resumed_xp, "Offline XP must be committed before another cold start.")
	print("stability-regressions: settling resume")
	for frame in range(60):
		await process_frame
	for failure in failures:
		push_error(failure)
	if failures.is_empty():
		print("stability-regressions: PASS")
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	print("stability-regressions: shutdown returned")
	quit(0 if failures.is_empty() else 1)
