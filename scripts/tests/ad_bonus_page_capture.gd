extends "res://scripts/tests/ham_oct21_capture.gd"

var proof_size := Vector2i(1080,1920)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Ad bonus capture requires --visible-game")
		quit(1)
		return
	create_timer(160).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "150")
	capture_dir = "res://outputs/verification/ad-bonus-timer-format"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.content_scale_size = Vector2i(1080,1920)
	root.size = Vector2i(1080,1920)
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
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.2)
	var ads = game._ad_bonus_runtime()
	ads.seconds_remaining = 0.0
	await click(game._navigation_shell().shop_tab.get_global_rect().get_center(),true)
	await settle(1.0)
	check(game.current_screen == "shop","Reach the changed screen through the actual Shop navigation")
	var shop = game._shop_surface()
	_verify_bonus_tiers(ads, shop)
	_verify_layout(shop)
	check(shop.bonus_bar.fill == 0.0 and shop.bonus_timer.text == "0s","Empty timer and bar")
	check(not shop.offer_button.disabled,"An empty bonus permits watching an ad")
	await capture("empty")
	var point: Vector2 = shop.offer_button.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = point
	down.pressed = true
	root.push_input(down,true)
	await settle(0.08)
	await capture("button-pressed")
	check(shop.offer_button.scale.x < 0.98,"Watch button visibly depresses")
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = point
	up.pressed = false
	root.push_input(up,true)
	await settle(0.03)
	await capture("button-release")
	await settle(0.35)
	check(shop.offer_button.scale.is_equal_approx(Vector2.ONE),"Watch button returns to its authored size")
	await capture("button-settled")
	check(ads.seconds_remaining == 0.0,"A desktop button press cannot grant an unearned ad reward")

	ads.seconds_remaining = 17104.0
	shop.sync_bonus_display()
	await settle(0.2)
	check(shop.offer_button.disabled,"Wait until the full two-hour reward fits")
	var before_seconds: int = shop.bonus_bar.last_second
	var before_fill: float = shop.bonus_bar.fill
	await settle(1.2)
	check(shop.bonus_bar.last_second < before_seconds and shop.bonus_bar.fill < before_fill,"Visible timer and continuous bar drain with the actual running bonus")
	await capture("active")
	_verify_layout(shop)

	ads.seconds_remaining = 0.0
	ads.ad_showing = true
	ads.ad_reward_earned_for_show = false
	ads._on_rewarded_ad_user_earned_reward(null)
	var first_reward: float = ads.seconds_remaining
	check(first_reward > 7199.0 and first_reward <= 7200.0,"Earned reward still grants two hours")
	ads._on_rewarded_ad_user_earned_reward(null)
	check(ads.seconds_remaining == first_reward,"Duplicate SDK callbacks cannot duplicate a reward")
	ads.ad_showing = false
	shop.sync_bonus_display()
	await settle(0.8)
	check(absf(shop.bonus_bar.fill - 1.0/3.0) < 0.001,"Two hours fills one third of the six-hour bar")
	await capture("two-hours")
	await settle(1.5)
	ads.seconds_remaining = 10800.0
	shop.sync_bonus_display()
	await settle(0.3)
	check(shop.xp_reward_label.text == "+12%" and shop.time_reward_label.text == "-12%", "Three-hour tier is visible")
	await capture("three-hours")
	ads.seconds_remaining = 18000.0
	shop.sync_bonus_display()
	await settle(0.3)
	check(shop.xp_reward_label.text == "+14%" and shop.time_reward_label.text == "-14%", "Five-hour tier is visible")
	await capture("five-hours")

	ads.seconds_remaining = 21600.0
	shop.sync_bonus_display()
	await RenderingServer.frame_post_draw
	check(shop.bonus_bar.fill > 0.9999 and shop.bonus_timer.text == "6:00:00","Six hours fills the whole bar")
	check(shop.offer_button.disabled,"A full bonus cannot request another ad")
	await capture("full")
	ads.seconds_remaining = 0.2
	await settle(0.8)
	shop.sync_bonus_display()
	check(shop.bonus_bar.fill == 0.0 and shop.bonus_timer.text == "0s" and not shop.offer_button.disabled,"Expiry clears the display and re-enables the button")
	ads.seconds_remaining = 7200.0
	game.dark_mode_enabled = true
	game._settings_surface().apply_dark_mode_visual()
	game._navigation_shell()._render_screen()
	await settle(0.8)
	_verify_layout(game._shop_surface())
	await capture("dark")
	await _capture_phone_proportions()
	print("ad-bonus-page failures=",failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)

func _verify_bonus_tiers(ads, shop) -> void:
	for pair in [[0.0,"0s"], [0.1,"1s"], [9.0,"9s"], [59.0,"59s"], [60.0,"1:00"], [309.0,"5:09"], [3599.0,"59:59"], [3600.0,"1:00:00"], [7200.0,"2:00:00"]]:
		check(shop._clock_text(pair[0]) == pair[1], "Timer omits insignificant leading zeros: " + str(pair[0]))
	var action_runtime = game._action_runtime()
	var action := {"id":"ad-tier-probe", "seconds":100.0, "xp":1000}
	ads.seconds_remaining = 0.0
	var base_xp: float = action_runtime._unrounded_xp_reward_amount(action, "build", "build", 1000)
	var base_seconds: float = action_runtime._effective_seconds("build", action)
	for pair in [[0.0, 0], [0.01, 10], [7199.9, 10], [7200.0, 10], [7200.1, 12], [14400.0, 12], [14400.1, 14], [21600.0, 14]]:
		ads.seconds_remaining = pair[0]
		check(ads.bonus_percent() == pair[1], "Exact remaining-time tier boundary: " + str(pair[0]))
		check(is_equal_approx(ads.xp_multiplier(), float(pair[1]) / 100.0) and is_equal_approx(ads.speed_multiplier(), float(pair[1]) / 100.0), "XP and time share the actual tier")
		check(is_equal_approx(action_runtime._unrounded_xp_reward_amount(action, "build", "build", 1000), base_xp + float(pair[1]) * 10.0), "Actual activity XP receives the tier bonus")
		check(is_equal_approx(action_runtime._effective_seconds("build", action), maxf(18.0, base_seconds - float(pair[1]))), "Actual activity duration receives the tier reduction")
	ads.seconds_remaining = 14400.1
	shop.sync_bonus_display()
	ads.process(0.2)
	shop.bonus_bar._process(0.0)
	check(shop.xp_reward_label.text == "+12%", "Live countdown lowers 14% to 12% at four hours")
	ads.seconds_remaining = 7200.1
	ads.process(0.2)
	shop.bonus_bar._process(0.0)
	check(shop.xp_reward_label.text == "+10%", "Live countdown lowers 12% to 10% at two hours")
	ads.restore_seconds_from_save({"ad_bonus_seconds_remaining":18000.0})
	check(ads.bonus_percent() == 14, "Restored saves derive the tier from stored time")
	ads.seconds_remaining = 0.0
	shop.sync_bonus_display()

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	check(screenshot.get_size() == proof_size,"Raw viewport capture size for " + label)
	screenshot.save_png(capture_dir + "/" + label + ".png")

func _capture_phone_proportions() -> void:
	game.dark_mode_enabled = false
	game._settings_surface().apply_dark_mode_visual()
	for dimensions in [Vector2i(1080,2340),Vector2i(1080,2160),Vector2i(1200,1920),Vector2i(1440,1920)]:
		proof_size = dimensions
		# A smaller visible OS window keeps the complete game on the monitor.
		# Godot still draws the raw native viewport at the declared proof_size.
		root.size = dimensions / 2
		await settle(0.4)
		game._navigation_shell()._render_screen()
		await settle(1.0)
		var shop = game._shop_surface()
		var page_rect: Rect2 = shop.presentation_root.get_global_rect()
		var scroll_rect: Rect2 = shop.presentation_scroll.get_global_rect()
		var frame_rect: Rect2 = shop.presentation_backdrop.get_global_rect()
		check(page_rect.is_equal_approx(frame_rect),"Backdrop fills the available page without distortion")
		var backdrop := shop.presentation_backdrop.texture as AtlasTexture
		check(backdrop != null and backdrop.region.has_point(backdrop.atlas.get_size() * Vector2(0.83,0.91)),"Selected blue book remains visible on every tested phone proportion")
		check(page_rect.encloses(shop.presentation_hero.get_global_rect()),"Hero stays inside the frame")
		check(scroll_rect.encloses(shop.offer_button.get_global_rect()),"Primary reward button stays visible")
		check(absf(shop.bonus_timer.get_global_rect().get_center().x - shop.bonus_bar.get_global_rect().get_center().x) < 1.0,"Responsive timer stays centered above its bar")
		for entry in shop.responsive_labels:
			var control: Control = entry.node
			var rendered_font := float(control.get_theme_font_size("font_size")) * 1080.0 / float(dimensions.x)
			var minimum_font := 36.0 if str(control.name).begins_with("AdBonusThreshold") else (40.0 if control.name == "AdBonusDeveloperMessage" else 52.0)
			check(rendered_font >= minimum_font - 0.5,"Text keeps its requested hierarchy at a physical 1080px phone width")
			check(control.get_global_rect().position.x >= scroll_rect.position.x - 1 and control.get_global_rect().end.x <= scroll_rect.end.x + 1,"Copy stays inside the frame: " + str(control.name))
		var suffix := "%dx%d" % [dimensions.x,dimensions.y]
		print("ad-presentation ",suffix," page=",page_rect," scroll=",scroll_rect," content_height=",shop.presentation_page.size.y)
		await capture("phone-" + suffix)
		var footer: Control = game.find_child("AdBonusDeveloperNote",true,false)
		if footer.get_global_rect().end.y > scroll_rect.end.y:
			await _swipe_content_up(scroll_rect)
			await _swipe_content_up(scroll_rect)
			check(shop.presentation_scroll.scroll_vertical > 0,"Short phones can scroll to the developer section")
			var rate: Control = game.find_child("AdBonusRateButton",true,false)
			check(rate.get_global_rect().end.y <= scroll_rect.end.y + 1,"Rating action remains reachable inside the frame")
			await capture("phone-" + suffix + "-footer")

func _swipe_content_up(rect: Rect2) -> void:
	var start := Vector2(rect.get_center().x,rect.end.y - 120)
	var end := Vector2(rect.get_center().x,rect.position.y + 120)
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = start
	down.pressed = true
	root.push_input(down,true)
	await settle(0.08)
	var previous := start
	for step in range(1,13):
		var point := start.lerp(end,float(step)/12.0)
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = point
		drag.relative = point - previous
		root.push_input(drag,true)
		previous = point
		await settle(0.02)
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = end
	up.pressed = false
	root.push_input(up,true)
	await settle(0.5)

func _verify_layout(shop) -> void:
	var description: Label = game.find_child("AdBonusDescription",true,false)
	var developer_message: Label = game.find_child("AdBonusDeveloperMessage",true,false)
	check(description == null,"Removed duration and cap copy stays absent")
	check(developer_message != null and developer_message.get_line_count() == 3,"Developer note keeps each sentence on its own unwrapped line")
	var footer: Control = game.find_child("AdBonusDeveloperNote",true,false)
	check(footer != null and footer.is_visible_in_tree(),"Developer note remains in the production page")
	if footer != null:
		check(footer.global_position.y > 1050 and footer.get_global_rect().end.y < 1700,"Developer message is separated near the bottom above navigation")
	check(shop.offer_button.get_global_rect().size.x <= 900,"Offer fits phone width")
	check(absf(shop.bonus_timer.get_global_rect().get_center().x - shop.bonus_bar.get_global_rect().get_center().x) < 1.0,"Timer stays centered above its bar")
	for label in game.find_children("*","Label",true,false):
		if label.is_visible_in_tree() and label.get_parent() != null and _is_shop_label(label):
			check(label.get_global_rect().position.x >= 45 and label.get_global_rect().end.x <= 1035,"Ad page copy fits the viewport: " + label.text)

func _is_shop_label(label: Label) -> bool:
	var parent := label.get_parent()
	while parent != null:
		if parent.name == "AdBonusPage":
			return true
		parent = parent.get_parent()
	return false
