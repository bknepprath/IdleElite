extends "res://scripts/tests/ham_feedback_capture.gd"

func _run() -> void:
	create_timer(300).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/fishing-tool-balance"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	check(game.startup_initialized, "Real main scene boots")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game._action_runtime().activity_start_count = 10
	game._save_runtime().fishing_help_seen = true
	for id in game.skills:
		game.skills[id].xp = SkillState.xp_for_level(40)
		game.skills[id].level = 40
		for action in game.actions_by_skill[id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(id, str(action.id))
	for definition in game._project_runtime().definitions.values():
		var work := {}
		for step in definition.project.steps: work[str(step.id)] = int(step.target)
		if definition.project.has("cost"): work.materials = 1
		game._project_runtime().work[str(definition.project.id)] = work
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game.material_runtime.set_amount("scrapwood", 100)
	game.material_runtime.set_amount("berries", 100)
	game.material_runtime.set_amount("softwood", 100)
	for action in game.actions_by_skill.woodcutting:
		game.mastery[game._action_key("woodcutting", action.id)] = {"xp":MasteryState.xp_for_level(3), "level":3}
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.0)
	if game._halloween_runtime().greeting_visible():
		await click(Vector2(540, 950), true)
		await settle(0.4)
	await capture("menu")
	if OS.get_environment("IDLE_ELITE_FISHING_HELP_ONLY") == "1":
		await capture_tool_help()
		print("fishing-tool-balance failures=",failures)
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	if OS.get_environment("IDLE_ELITE_FISHING_ANIMATION_ONLY") == "1":
		await audit_active_animations()
		print("fishing-tool-balance failures=", failures)
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	if OS.get_environment("IDLE_ELITE_FISHING_MODULE_ONLY") == "1":
		await capture_module_tools()
		print("fishing-tool-balance failures=", failures)
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	game._action_runtime().guaranteed_success_action_completions = 100
	var matrix := measure_matrix()
	check_prices_and_save()
	check_long_run_rates()
	await check_live_offline_rewards()
	await capture_tool_rates()
	await capture_prices()
	var result := {"failures":failures,"rates":matrix}
	var output := FileAccess.open(capture_dir + "/result.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  "))
	output.close()
	print("fishing-tool-balance failures=",failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func measure_matrix() -> Array:
	var matrix := []
	var before: Array = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/tests/fixtures/fishing-rates-before-2026-10-22.json"))
	var old_rates := {}
	for row in before: old_rates[row.action + ":" + row.tool] = row
	for action in game.actions_by_skill.fishing:
		if game.fishing_runtime.action_should_render_standalone(game,"fishing",action): continue
		for tool in ["hands","net","line","reinforced_rod","star_rod","boat","mirror"]:
			game.fishing_runtime.equipped_tool_id = tool
			game._action_runtime().invalidate_stat_cache()
			var rates: Dictionary = game.fishing_runtime.expected_rates(game,action)
			var old: Dictionary = old_rates.get(action.id + ":" + tool,{})
			var compatible: bool = not game.fishing_runtime.tool_catches_nothing_for_action(tool,action.id)
			if not compatible:
				check(rates.food_per_min == 0.0 and rates.xp_per_min == 0.0,"Unsuitable tool gives zero rates: " + action.id + ":" + tool)
			elif not old.is_empty():
				# This fixture predates the removal of the 90% curve and the
				# opening mastery rebalance. Compare output at today's chance.
				var chance_ratio: float = game._action_runtime()._success_chance("fishing", action) / 100.0 / float(old.chance)
				check(is_equal_approx(float(rates.xp_per_min),float(old.xp_per_min)*chance_ratio),"XP per successful cycle preserved: " + action.id + ":" + tool)
				if tool != "mirror": check(is_equal_approx(float(rates.food_per_min),float(old.food_per_min)*0.15*chance_ratio),"85% food cut at current success chance: " + action.id + ":" + tool)
			matrix.append({"action":action.id,"tool":tool,"food_per_min":rates.food_per_min,"xp_per_min":rates.xp_per_min})
	for action in game.actions_by_skill.fishing:
		if game.fishing_runtime.action_should_render_standalone(game,"fishing",action): continue
		var compatible: Array = game.fishing_runtime.compatible_tool_ids(action.id)
		if not (compatible.has("net") and compatible.has("line")): continue
		game.fishing_runtime.equipped_tool_id = "net"
		var net: Dictionary = game.fishing_runtime.expected_rates(game,action)
		for rod in ["line","reinforced_rod","star_rod"]:
			game.fishing_runtime.equipped_tool_id = rod
			var rates: Dictionary = game.fishing_runtime.expected_rates(game,action)
			check(net.food_per_min > rates.food_per_min and net.xp_per_min < rates.xp_per_min,"Net/rod tradeoff: " + action.id + ":" + rod)
	return matrix

func check_prices_and_save() -> void:
	var fish = game.fishing_runtime
	check(fish.purchase_cost("line")==100 and fish.purchase_cost("reinforced_rod")==5000 and fish.purchase_cost("star_rod")==25000 and fish.purchase_cost("mirror")==100000,"Food prices reduced 90%")
	check(fish.purchase_cost("boat")==1000,"Boat still costs 1000 Softwood")
	fish.fish_currency = 12345.678
	fish.rod_collected = true
	fish.reinforced_rod_collected = true
	fish.star_rod_collected = true
	fish.boat_built = true
	fish.mirror_collected = true
	var saved: Dictionary = fish.save_payload(10,200,func(_id): return true,func(_id): return true,func(_a,_b): return true)
	fish.restore_from_save(saved,10,200,func(_id): return true,func(_id): return true,func(_a,_b): return true)
	check(is_equal_approx(fish.fish_currency,12345.678) and fish.star_rod_collected and fish.boat_built and fish.mirror_collected,"Existing food and owned equipment preserved")
	var surface = game._fishing_ui_surface()
	fish.rod_collected = false
	fish.reinforced_rod_collected = false
	fish.star_rod_collected = false
	fish.mirror_collected = false
	for tool in ["line","reinforced_rod","star_rod","mirror"]:
		var cost: int = fish.purchase_cost(tool)
		var flag: String = "rod_collected" if tool=="line" else tool + "_collected"
		fish.fish_currency = float(cost)-0.01
		if tool=="line": surface._on_fishing_rod_offer_pressed(null)
		elif tool=="mirror": surface._on_fishing_mirror_offer_pressed(null)
		else: surface._on_fishing_rod_upgrade_offer_pressed(tool,null)
		check(not bool(fish.get(flag)),"Purchase cannot overspend fractional food: " + tool)
		fish.fish_currency = cost
		if tool=="line": surface._on_fishing_rod_offer_pressed(null)
		elif tool=="mirror": surface._on_fishing_mirror_offer_pressed(null)
		else: surface._on_fishing_rod_upgrade_offer_pressed(tool,null)
		check(bool(fish.get(flag)) and fish.fish_currency == 0.0,"Actual reduced-price purchase: " + tool)
	fish.boat_built = false
	fish.fish_currency = 123.0
	game.material_runtime.set_amount("softwood",999)
	surface._on_fishing_boat_offer_pressed(null)
	check(not fish.boat_built,"Boat still requires Softwood")
	game.material_runtime.set_amount("softwood",1000)
	surface._on_fishing_boat_offer_pressed(null)
	check(fish.boat_built and game.material_runtime.amount("softwood")==0 and fish.fish_currency==123.0,"Boat spends wood, preserves food")
	fish.equipped_tool_id = "boat"
	game._action_runtime().guaranteed_success_action_completions = 0
	check(not game._action_runtime()._roll_action_success("fishing",game._action_data("fishing","shallows")),"Starter guarantee cannot bypass tool restriction")
	game._action_runtime().guaranteed_success_action_completions = 100
	fish.equipped_tool_id = "line"
	var ads = game._ad_bonus_runtime()
	ads.seconds_remaining = 20000
	var boosted: Dictionary = fish.expected_rates(game,game._action_data("fishing","rapids"))
	ads.seconds_remaining = 3600
	var lower: Dictionary = fish.expected_rates(game,game._action_data("fishing","rapids"))
	check(float(boosted.xp_per_min) > float(lower.xp_per_min),"Rates refresh across ad tiers without manual invalidation")
	ads.seconds_remaining = 0
	fish.equipped_tool_id = "boat"
	fish.select_area_tool("beach", "hands")
	check(game._action_runtime()._start_action("fishing","shallows",false,false) and fish.equipped_tool_id == "hands","Starting location equips its saved area tool")
	game._action_runtime()._stop_running_action("fishing", "shallows")

func clear_batches() -> void:
	game.fishing_runtime.net_stored_fish = 0
	game.fishing_runtime.boat_stored_fish = 0
	game.fishing_runtime.net_stored_xp = 0
	game.fishing_runtime.boat_stored_xp = 0
	game.fishing_runtime.net_stored_mastery = 0
	game.fishing_runtime.boat_stored_mastery = 0

func check_long_run_rates() -> void:
	var fish = game.fishing_runtime
	for pair in [["net","river-bend"],["line","river-bend"],["boat","open-water"],["mirror","reflection"]]:
		fish.equipped_tool_id = pair[0]
		var action: Dictionary = game._action_data("fishing",pair[1])
		var rates: Dictionary = fish.expected_rates(game,action)
		var seconds: float = game._action_runtime()._action_cycle_seconds("fishing",action)
		var probability: float = game._action_runtime()._success_chance("fishing",action)/100.0
		var awarded := 0.0
		var xp := 0
		clear_batches()
		seed(69420)
		for i in range(20000):
			if randf() >= probability: continue
			var count: int = fish.roll_fish_count(game,action)
			var reward: int = fish.flat_xp_reward(game,action,"fishing")
			xp += reward
			if pair[0] in ["net","boat"]:
				count = int(fish.record_batch_success(pair[0],count,reward,10 if pair[0]=="net" else 200,0.74).haul_count)
			awarded += fish.tool_food_value_for_catches(pair[0],pair[1],count)
		var actual_food := awarded*60.0/(20000.0*seconds)
		var actual_xp := float(xp)*60.0/(20000.0*seconds)
		check(absf(actual_food-float(rates.food_per_min))/maxf(0.01,float(rates.food_per_min))<0.05,"Long-run food prediction: " + str(pair))
		check(absf(actual_xp-float(rates.xp_per_min))/maxf(0.01,float(rates.xp_per_min))<0.05,"Long-run XP prediction: " + str(pair))
		print("RATE_CHECK ",pair," predicted=",rates," actual_food=",actual_food," actual_xp=",actual_xp)

func prepare_parity_attempt(tool: String, action_id: String) -> void:
	game.fishing_runtime.equipped_tool_id = tool
	clear_batches()
	game.fishing_runtime.net_stored_fish = 9
	game.fishing_runtime.boat_stored_fish = 199
	game.running_skill_id = "fishing"
	game.running_action_id = action_id
	for id in game.skills:
		game.skills[id].level = 99
		game.skills[id].xp = SkillState.xp_for_level(99)
	game._action_runtime().invalidate_stat_cache()

func check_live_offline_rewards() -> void:
	game.set_process(false)
	for action in game.actions_by_skill.fishing:
		game.mastery[game._action_key("fishing",action.id)] = {"xp":MasteryState.xp_for_level(20),"level":20}
	for pair in [["net","river-bend"],["star_rod","river-bend"],["boat","open-water"],["mirror","reflection"],["net","fight-rat-king"],["boat","fight-armored-catfish"]]:
		var action: Dictionary = game._action_data("fishing",pair[1])
		for attempt in range(50):
			prepare_parity_attempt(pair[0],pair[1])
			var before: float = game.fishing_runtime.fish_currency
			seed(attempt+100)
			game.fishing_runtime.complete_action_attempt(game,action,game._action_key("fishing",pair[1]),{})
			var live: float = game.fishing_runtime.fish_currency-before
			var live_xp := {}
			for id in game.skills: live_xp[id] = int(game.skills[id].xp)-SkillState.xp_for_level(99)
			prepare_parity_attempt(pair[0],pair[1])
			before = game.fishing_runtime.fish_currency
			seed(attempt+100)
			var offline: Dictionary = game._action_runtime()._grant_offline_fishing_action_completion("fishing",pair[1],action,true,true)
			for id in game.skills:
				var expected: int = maxi(1,int(round(float(live_xp[id])*0.30))) if int(live_xp[id]) > 0 else 0
				check(int(game.skills[id].xp)-SkillState.xp_for_level(99)==expected,"Offline XP keeps each rewarded skill: " + str(pair) + ":" + str(id))
			check(is_equal_approx(live,float(offline.fish)),"Live/offline food: " + str(pair) + ":" + str(attempt))
			check(is_equal_approx(game.fishing_runtime.fish_currency-before,float(offline.fish)),"Offline payout matches inventory")
	game._action_runtime()._stop_running_action("fishing",game.running_action_id)
	clear_batches()
	# One whole food remains the auto-eat unit; fractional food cannot be overspent.
	game.stamina.fight = 0.0
	game.fishing_runtime.set_auto_eat_fish_enabled_for_skill(game,"fight",true)
	game.fishing_runtime.fish_currency = 0.99
	game._action_runtime()._auto_eat_fish_for_action("fight",1.0,null,false)
	check(is_equal_approx(game.fishing_runtime.fish_currency,0.99),"Auto-eat preserves fractional food below one")
	game.fishing_runtime.fish_currency = 1.0
	game._action_runtime()._auto_eat_fish_for_action("fight",1.0,null,false)
	check(game.fishing_runtime.fish_currency == 0.0 and game.stamina.fight > 0.0,"One food still restores stamina")
	game.set_process(true)

func select_wallet_tool(tool: String) -> void:
	var action_id := "open-water" if tool == "boat" else ("reflection" if tool == "mirror" else "river-bend")
	await show_location(action_id, "before-tool-selection")
	await select_module_tool(action_id, tool)


func show_location(action_id: String, name: String) -> Dictionary:
	var surface = game._fishing_ui_surface()
	var definition: Dictionary = surface.render_area_module_for_action("fishing",action_id)
	var key: String = game.fishing_runtime.area_module_key("fishing",definition)
	await game._skill_detail_surface()._scroll_to_activity_card(key,false,true)
	await settle(0.6)
	var card: Dictionary = surface._fishing_area_card_for_action("fishing",action_id)
	check(not card.is_empty(),"Production location mounted: " + action_id)
	if card.is_empty(): return {}
	var scroll = game.detail_actions_scroll
	scroll.scroll_vertical += int((card.root as Control).get_global_rect().position.y-455)
	scroll.set("drag_scroll_position",float(scroll.scroll_vertical))
	await settle(0.5)
	var method: Dictionary = surface._fishing_method_card_for_action("fishing",action_id)
	check(method.has("rate_food") and not method.rate_panel.is_visible_in_tree(),"Rates stay hidden until tool selection: " + action_id)
	check(game.running_skill_id.is_empty(),"Rate preview starts no activity")
	if not name.is_empty(): await capture(name)
	return method

func capture_tool_rates() -> void:
	var fish = game.fishing_runtime
	fish.net_collected = true
	fish.rod_collected = true
	fish.reinforced_rod_collected = true
	fish.star_rod_collected = true
	fish.boat_built = true
	fish.mirror_collected = true
	game.fishing_runtime.fish_currency = 123.45
	await open_notes_skill("fishing")
	await select_wallet_tool("net")
	var method := await show_location("river-bend","river-net")
	var net_text := str(method.rate_food.text) if not method.is_empty() else ""
	if not method.is_empty():
		var net_xp := str(method.rate_xp.text)
		await click((method.method_image_hit_control as Control).get_global_rect().get_center(),true)
		await settle(0.8)
		method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
		check(game.running_action_id=="river-bend","Location starts through actual UI")
		check(str(method.rate_food.text)==net_text and str(method.rate_xp.text)==net_xp,"Starting fishing does not change expected rates")
		await capture("river-net-running")
		await click((method.method_image_hit_control as Control).get_global_rect().get_center(),true)
		await settle(0.4)
		check(game.running_skill_id.is_empty(),"Location stops through actual UI")
	await select_wallet_tool("star_rod")
	method = await show_location("river-bend","river-rod")
	if not method.is_empty(): check(str(method.rate_food.text)!=net_text,"Switching tool updates displayed rate")
	await select_wallet_tool("boat")
	await show_location("open-water","offshore-boat")
	await show_location("reflection","space-without-mirror")
	await select_wallet_tool("mirror")
	await show_location("reflection","space-mirror")

func open_notes_skill(id: String) -> void:
	game.running_skill_id = ""
	game.running_action_id = ""
	if game.current_screen not in ["skill", "menu"]:
		await click(game.skills_tab.get_global_rect().get_center(), true)
		await settle(0.7)
	if game.current_screen != "menu":
		await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center(), true)
		await settle(0.7)
	check(game.current_screen == "menu", "Menu reached through actual navigation")
	if game.current_screen != "menu": return
	var button: Control = game.skill_cards[id].button
	game.content_scroll.scroll_vertical += int(button.get_global_rect().get_center().y - 950)
	await settle(0.5)
	print("NOTES_MENU target=",id," rect=",button.get_global_rect()," viewport=",root.get_visible_rect())
	await click(button.get_global_rect().get_center(), true)
	await settle(1.0)
	check(game.current_screen == "skill" and game.selected_skill_id == id, "Menu opens " + id)

func notes_card(id: String) -> Dictionary:
	await game._skill_detail_surface()._scroll_to_activity_card(id, false, true)
	await settle(0.8)
	var card: Dictionary = game.action_cards.get(game._action_key(game.selected_skill_id,id),{})
	check(not card.is_empty(), "Production card mounted: " + id)
	return card

func align_notes_card(card: Dictionary) -> void:
	var control: Control = card.get("firepit_entry_root", card.root)
	var scroll: ScrollContainer = game.detail_actions_scroll
	scroll.scroll_vertical += int(control.get_global_rect().position.y - 455)
	scroll.set("drag_scroll_position", float(scroll.scroll_vertical))
	await settle(0.4)


func capture_prices() -> void:
	var fish = game.fishing_runtime
	fish.equipped_tool_id = "hands"
	fish.fish_currency = 200000
	fish.rod_collected = false
	fish.reinforced_rod_collected = false
	fish.star_rod_collected = false
	fish.mirror_collected = false
	for offer in ["rod","reinforced_rod","star_rod","mirror"]:
		if offer == "reinforced_rod": fish.rod_collected = true
		if offer == "star_rod": fish.reinforced_rod_collected = true
		game._navigation_shell()._render_screen(false)
		await settle(0.5)
		var track: String = "fishing_offer:" + str(offer)
		await game._skill_detail_surface()._scroll_to_activity_card(track,false,true)
		await settle(0.7)
		var entry: Dictionary = game._skill_detail_surface()._detail_lazy_entry_for_track_id(track)
		check(not entry.is_empty(),"Actual offer mounted: " + offer)
		if entry.is_empty(): continue
		var slot: Control = entry.stack_host
		game.detail_actions_scroll.scroll_vertical += int(slot.get_global_rect().position.y-455)
		game.detail_actions_scroll.set("drag_scroll_position",float(game.detail_actions_scroll.scroll_vertical))
		await settle(0.4)
		await capture("price-" + offer)

func capture_tool_help() -> void:
	var fish = game.fishing_runtime
	fish.net_collected = true
	fish.rod_collected = true
	fish.reinforced_rod_collected = false
	fish.star_rod_collected = false
	fish.boat_built = true
	fish.mirror_collected = true
	await open_notes_skill("fishing")
	var surface = game._fishing_ui_surface()
	for tool in ["net","line","boat","mirror"]:
		var action_id := "open-water" if tool == "boat" else ("reflection" if tool == "mirror" else "river-bend")
		await show_location(action_id, "before-tool-help")
		var area: Dictionary = surface._fishing_method_card_for_action("fishing", action_id)
		await click((area.tool_selector as Control).get_global_rect().get_center(),true)
		await settle(0.3)
		var target: Button = null
		check(surface.fishing_tool_wallet_popup.find_children("*", "Label", true, false).is_empty(), "Tool pill is icon-only")
		for button in surface.fishing_tool_wallet_popup.find_children("*", "Button", true, false):
			if str(button.get_meta("tool_id", "")) == tool: target = button
		check(target != null, "Owned compatible tool appears: " + tool)
		await capture("tool-pill-" + tool)
		if target != null:
			await click(target.get_global_rect().get_center(), true)
			await settle(0.4)
			check(game.fishing_runtime.tool_id_for_action(action_id) == tool, "Icon-only pill selects " + tool)

func select_module_tool(action_id: String, tool: String, popup_capture := "") -> void:
	var surface = game._fishing_ui_surface()
	var area: Dictionary = surface._fishing_method_card_for_action("fishing", action_id)
	check(not area.is_empty() and area.has("tool_selector"), "Module has tool selector: " + action_id)
	if area.is_empty(): return
	var picker_anchor := area.tool_selector as Control
	if (area.tool_selector as BaseButton).disabled:
		picker_anchor = surface._fishing_area_card_for_action("fishing",action_id).active_tool_hit as Control
	await click(picker_anchor.get_global_rect().get_center(), true)
	await settle(0.3)
	check(surface.fishing_tool_wallet_open, "Module tool selector opens through touch")
	if surface.fishing_tool_wallet_popup == null: return
	check((area.rate_panel as Control).is_visible_in_tree(), "Rates appear during tool selection: " + action_id)
	check(surface.fishing_tool_wallet_popup.get_global_rect().has_point(picker_anchor.get_global_rect().get_center()), "Wallet overlays its selected tool: " + action_id)
	var owner: Dictionary = surface._fishing_area_card_for_action("fishing", action_id)
	check(not (area.rate_panel as Control).get_global_rect().intersects(surface.fishing_tool_wallet_popup.get_global_rect()), "Picker leaves center estimates unobstructed: " + action_id)
	if action_id == "river-bend": await capture("wallet-rate-clearance")
	check((area.rate_panel as Control).get_global_rect().get_center().x - (owner.pop as Control).get_global_rect().get_center().x < 1.0, "Rate preview is centered: " + action_id)
	if not popup_capture.is_empty(): await capture(popup_capture)
	var target: Button = null
	for button in surface.fishing_tool_wallet_popup.find_children("*", "Button", true, false):
		if str(button.get_meta("tool_id", "")) == tool: target = button
	check(target != null, "Module picker contains tool: " + tool)
	if target == null: return
	await click(target.get_global_rect().get_center(), true)
	await settle(0.6)
	check(game.fishing_runtime.tool_id_for_action(action_id) == tool, "Module remembers selection: " + tool)
	check(surface.fishing_tool_wallet_open, "Selecting gear keeps the wallet open: " + tool)
	# Observe real dismissal and fade without click()'s post-tap delay.
	await capture("wallet-before-dismissal")
	var outside := InputEventScreenTouch.new()
	outside.position = Vector2(1040,420)
	outside.pressed = true
	root.push_input(outside,true)
	await process_frame
	outside = InputEventScreenTouch.new()
	outside.position = Vector2(1040,420)
	outside.pressed = false
	root.push_input(outside,true)
	await process_frame
	await capture("wallet-fade-transition")
	await settle(.3)
	check(not surface.fishing_tool_wallet_open, "Outside tap closes the wallet")
	await settle(.5)
	await capture("wallet-fade-settled")

func capture_module_tools() -> void:
	capture_dir = "res://.codex-tmp/fishing-stage-tools"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var fish = game.fishing_runtime
	fish.net_collected = true
	fish.rod_collected = true
	fish.star_rod_collected = true
	fish.boat_built = true
	fish.mirror_collected = true
	fish.fish_currency = 123.45
	fish.selected_area_tools.clear()
	check_recommended_tools()
	for action_id in ["river-bend", "rapids", "drain-gate", "tunnel-pool"]:
		game._activity_unlock_runtime()._mark_action_manually_unlocked("fishing", action_id)
	check(fish.tool_id_for_action("river-bend") == "net" and fish.tool_id_for_action("rapids") == "star_rod", "Unlock initializes useful location defaults")
	game.skills.fishing.xp = SkillState.xp_for_level(99)
	game.skills.fishing.level = 99
	for action in game.actions_by_skill.fishing:
		game.mastery[game._action_key("fishing", action.id)] = {"xp": int((MasteryState.xp_for_level(3) + MasteryState.xp_for_level(4)) / 2), "level": 3}
	game.mastery[game._action_key("fishing", "rapids")] = {"xp": int(lerpf(MasteryState.xp_for_level(3), MasteryState.xp_for_level(4), 0.75)), "level": 3}
	game._action_runtime().invalidate_stat_cache()
	await open_notes_skill("fishing")
	var method := await show_location("river-bend", "modules-net-and-rod")
	var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
	check(is_equal_approx((area.root as Control).size.y, 312.0), "Compact box preserves artwork, mastery, rates and badges")
	check((area.area_title as Label).horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER, "Area heading is above the center lane")
	check((method.art_panel as Control).global_position.y - (area.pop as Control).global_position.y < 100, "Top padding is compact")
	check((method.mastery_ring as Control).is_visible_in_tree() and not (method.mastery as Control).visible, "0.7.0 square mastery outline is visible; straight bar stays hidden")
	check(method.get("compatible_tools", null) == null, "Tiny compatibility icons removed")
	check((method.tool_selector as Control).size.x >= 104 and (method.tool_selector as Control).size.y >= 104, "Tool selector has full touch target")
	var icons: Array = (method.rate_panel as Control).find_children("*", "TextureRect", true, false)
	check(icons.size() == 2 and is_equal_approx(icons[0].global_position.x, icons[1].global_position.x), "Fish and XP icons share a fixed column")
	var _mastery_rect: Rect2 = (method.mastery_ring as Control).get_global_rect()
	check(not (method.rate_panel as Control).is_visible_in_tree(), "Rate panel is hidden outside tool selection")
	check((method.tool_selector as Button).get_theme_stylebox("normal") is StyleBoxEmpty, "Tool button has no circle or background")
	var selector_rect: Rect2 = (method.tool_selector as Control).get_global_rect()
	var square_rect: Rect2 = (method.art_panel as Control).get_global_rect()
	check(selector_rect.get_center().distance_to(square_rect.end) < 1.0, "Tool straddles the exact bottom-right corner of its location square")
	check((method.tool_selector as Control).get_parent() == method.art_panel, "Tool is attached to its own square")
	var icon := (method.tool_selector as Control).get_child(0) as TextureRect
	check(icon.texture == game._fishing_ui_surface()._fishing_small_tool_icon_texture("net") and icon.material == null and icon.size == Vector2(92, 92), "Selector uses miniature artwork without darkening shader")
	var next_location: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "rapids")
	check(not (method.tool_selector as Control).get_global_rect().intersects((next_location.medal as Control).get_global_rect()), "Tool control clears neighbouring medal")
	for level in range(1, 21):
		var medal_size: Vector2 = game._skill_swipe_activity_surface()._action_card_medal_size(level)
		var medal_rect := Rect2((next_location.art_panel as Control).global_position - medal_size * 0.5 + Vector2(12, 9), medal_size)
		check(not (method.tool_selector as Control).get_global_rect().grow(12).intersects(medal_rect), "Tool clears neighbouring medal at level %d" % level)
	var before_text := str(method.rate_food.text)
	await select_module_tool("river-bend", "star_rod", "module-tool-picker")
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	check(str(method.rate_food.text) != before_text, "Rates update before starting")
	check(game.running_skill_id.is_empty(), "Tool preview starts no activity")
	check(fish.tool_id_for_action("rapids") == "star_rod" and fish.tool_id_for_action("drain-gate") == "net", "Changing River Bend preserves Rapids and Sewers")
	await capture("module-river-rod")
	await select_module_tool("river-bend", "net")
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
	await settle(0.08)
	check(game.running_action_id == "river-bend" and fish.equipped_tool_id == "net", "Starting equips the module's chosen tool")
	area = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
	check((area.active_tool_layer as Control).is_visible_in_tree(), "Side tool animation retained")
	check(not area.has("fluid_strip"), "Bottom water strip removed")
	await capture("module-net-start")
	await settle(0.25)
	await capture("module-net-transition")
	await settle(0.8)
	method = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", "river-bend")
	area = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", "river-bend")
	var _water_rect: Rect2 = area.active_tool_layer.pool_surface.get_global_rect()
	for id in ["river-bend", "rapids"]:
		var active_location: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", id)
		check(not (active_location.rate_panel as Control).is_visible_in_tree(), "Rate preview fades before the running animation: " + id)
		var title := active_location.method_title as Label
		check(title.get_global_rect().get_center().distance_to((active_location.art_panel as Control).get_global_rect().get_center()) < 1.0, "Location title stays centered: " + id)
		check(title.modulate.a < .01 if id==game.running_action_id else title.modulate.a>.99,"Only the active location title fades out: "+id)
	await capture("module-net-running")
	await select_module_tool("river-bend", "star_rod")
	check(game.running_action_id == "river-bend" and fish.equipped_tool_id == "star_rod", "Active module switches running tool")
	await settle(0.8)
	await capture("module-rod-running")
	await select_module_tool("rapids", "net")
	check(game.running_action_id == "river-bend" and fish.equipped_tool_id == "star_rod", "Changing Rapids preserves running River Bend equipment")
	game._action_runtime()._stop_running_action("fishing", "river-bend")
	await settle(0.3)
	await show_location("open-water", "module-boat")
	await select_module_tool("open-water", "boat", "module-boat-picker")
	await show_location("reflection", "module-mirror")
	await select_module_tool("reflection", "mirror", "module-mirror-picker")
	fish.select_location_tool("reef-pot", "net")
	fish.select_location_tool("reef-cage", "star_rod")
	fish.select_location_tool("night-reef", "star_rod")
	check(fish.tool_id_for_action("reef-pot") == "net" and fish.tool_id_for_action("reef-cage") == "star_rod", "Split Reef boxes keep independent tools")
	var sanitized: Dictionary = fish.normalized_area_tools({"missing/0":"net", "river/-1":"net", "river/99":"net", "river/nope":"net", "river/0/extra":"net", "river/0":"line", "river-bend":"net"}, func(_id): return true)
	check(sanitized.size() == 2 and sanitized.get("rapids", "") == "star_rod" and sanitized.get("river-bend", "") == "net", "Legacy box choices expand to locations; direct location choice wins")
	var saved: Dictionary = fish.save_payload(10, 200, func(_id): return true, func(_id): return true, func(_a, _b): return true)
	fish.selected_area_tools.clear()
	fish.restore_from_save(saved, 10, 200, func(_id): return true, func(_id): return true, func(_a, _b): return true)
	check(fish.tool_id_for_action("river-bend") == "star_rod" and fish.tool_id_for_action("rapids") == "net" and fish.tool_id_for_action("reef-pot") == "net" and fish.tool_id_for_action("reef-cage") == "star_rod" and fish.tool_id_for_action("drain-gate") == "net" and fish.tool_id_for_action("reflection") == "mirror", "Independent module tools survive save reload")
	fish.select_location_tool("river-bend", "net")
	fish.select_location_tool("rapids", "star_rod")
	game.material_runtime.wisdom_by_skill["fishing"] = 0
	for action_id in ["chum-line", "drain-gate"]:
		game._activity_unlock_runtime().manual_activity_unlocks.erase(game._action_key("fishing", action_id))
		var action: Dictionary = game._action_data("fishing", action_id)
		var project_id := str((action.get("unlock_project", {}) as Dictionary).get("id", ""))
		game._project_runtime().work[project_id] = {}
	game.material_runtime.set_amount("lures", 0)
	game._project_runtime().queue_availability_refresh()
	game._navigation_shell()._render_screen(false)
	await settle(0.8)
	method = await show_location("river-bend", "location-buttons-with-badges")
	var seen_badges := 0
	for id in ["river-bend", "rapids"]:
		var location: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", id)
		for badge in (location.art_panel as Control).find_children("*", "Control", true, false):
			if badge.has_method("accepts_tap_at") and badge.is_visible_in_tree():
				seen_badges += 1
				check(not (location.tool_selector as Control).get_global_rect().intersects(badge.get_global_rect().grow(14)), "Location tool does not overlap resource/book badge")
				check(badge.get_global_rect().has_point(Vector2((location.art_panel as Control).get_global_rect().end.x, (location.art_panel as Control).global_position.y)), "Resource badge overlaps its own top-right corner")
	check(seen_badges > 0, "Production resource/book badge is visible beside location tools")
	await show_location("shallows", "module-hands")
	var output := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"failures": failures}, "  "))
	output.close()

func check_recommended_tools() -> void:
	var fresh = game.fishing_runtime.get_script().new()
	fresh.net_collected = true
	fresh.rod_collected = true
	fresh.equipped_tool_id = "mirror"
	check(fresh.tool_id_for_action("river-bend") == "net" and fresh.tool_id_for_action("rapids") == "line", "Recommendations ignore unrelated equipped tool")
	check(fresh.selected_area_tools.is_empty(), "Locked/pre-unlock previews do not freeze defaults")
	fresh.initialize_location_tool("river-bend")
	check(fresh.selected_area_tools.get("river-bend", "") == "net", "First unlock assigns recommended owned tool")
	fresh.select_location_tool("river-bend", "hands")
	fresh.initialize_location_tool("river-bend")
	fresh.star_rod_collected = true
	check(fresh.tool_id_for_action("river-bend") == "hands", "Explicit choice survives repeated initialization and new gear")
	var payload: Dictionary = fresh.save_payload(10, 200, func(_id): return true, func(_id): return true, func(_a, _b): return true)
	fresh.selected_area_tools.clear()
	fresh.restore_from_save(payload, 10, 200, func(_id): return true, func(_id): return true, func(_a, _b): return true)
	check(fresh.tool_id_for_action("river-bend") == "hands", "Explicit choice survives save reload")
	fresh.net_collected = false
	fresh.rod_collected = false
	fresh.reinforced_rod_collected = false
	fresh.star_rod_collected = false
	check(fresh.recommended_location_tool("rapids") == "hands", "Default falls back to owned compatible gear")
	fresh.boat_built = true
	fresh.mirror_collected = true
	check(fresh.recommended_location_tool("open-water") == "boat" and fresh.recommended_location_tool("reflection") == "mirror", "Specialist defaults select boat and mirror")


func check_active_stage(action_id: String, label: String) -> Dictionary:
	var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", action_id)
	check(not area.is_empty(), "Active area mounted: " + label)
	if area.is_empty(): return {}
	var stage = area.active_tool_layer
	check(stage.is_visible_in_tree(), "Active stage visible: " + label)
	check(not stage.clip_contents, "Tools are not cut by a legacy mask: " + label)
	check(stage.immersion_depth() <= stage.MAX_IMMERSION + 0.05, "Only a shallow tool edge dips under water: " + label)
	check(stage.art.material == stage.tool_water_material, "Every tool retains the curved pool mask: " + label)
	check(stage.pool_front_material.get_shader_parameter("water_color").a >= 0.95, "Foreground water stays opaque: " + label)
	if stage.tool_id in ["line", "reinforced_rod", "star_rod"]:
		check(stage.immersed_line_end().y <= stage.water_center.y + stage.MAX_IMMERSION * stage.layout_scale + 0.05, "Rod line stays within shallow water: " + label)
	var bounds: Rect2 = stage.visual_bounds()
	check(Rect2(Vector2.ZERO, stage.size).encloses(bounds), "Complete transformed tool stays inside stage: " + label)
	var stage_rect: Rect2 = stage.get_global_rect()
	var tool_rect := Rect2(stage.global_position + bounds.position, bounds.size)
	var water_rect: Rect2 = stage.water_effect_bounds()
	water_rect.position += stage.global_position
	check((area.pop as Control).get_global_rect().encloses(water_rect), "Water effects stay inside area mask: " + label)
	check((area.pop as Control).get_global_rect().encloses(stage_rect), "Stage stays inside area: " + label)
	check(not stage_rect.intersects((area.area_title as Control).get_global_rect()), "Stage clears area heading: " + label)
	# Keep the shared center equipment and pool inside the compact area while
	# protecting the two location squares and their corner controls.
	check((area.pop as Control).get_global_rect().encloses(tool_rect), "Equipment stays inside area mask: " + label)
	for raw in (area.method_slots as Dictionary).values():
		var method := raw as Dictionary
		for key in ["mastery_ring", "rate_panel", "tool_selector", "medal"]:
			var control := method.get(key) as Control
			if is_instance_valid(control) and control.is_visible_in_tree():
				check(not tool_rect.grow(10).intersects(control.get_global_rect()), "Tool clears " + key + ": " + label)
				check(not water_rect.grow(10).intersects(control.get_global_rect()), "Ripples clear " + key + ": " + label)
	return {"stage": str(stage_rect), "tool": str(bounds), "scale": stage.layout_scale, "progress": game.action_progress, "net_haul_seconds": game.fishing_runtime.net_haul_visual_seconds, "rod_haul_seconds": game.fishing_runtime.rod_haul_visual_seconds}


func audit_active_animations() -> void:
	capture_dir = "res://.codex-tmp/fishing-active-animations"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var fish = game.fishing_runtime
	fish.net_collected = true
	fish.rod_collected = true
	fish.boat_built = true
	fish.mirror_collected = true
	fish.fish_currency = 1000.0
	game.skills.fishing.xp = SkillState.xp_for_level(99)
	game.skills.fishing.level = 99
	game._action_runtime().guaranteed_success_action_completions = 1000
	for action in game.actions_by_skill.fishing:
		game.mastery[game._action_key("fishing", action.id)] = {"xp": MasteryState.xp_for_level(3), "level": 3}
	await open_notes_skill("fishing")
	var cases := [["hands", "shallows"], ["net", "river-bend"], ["line", "rapids"], ["reinforced_rod", "rapids"], ["star_rod", "rapids"], ["boat", "open-water"], ["mirror", "reflection"]]
	var measurements := {}
	for entry in cases:
		var tool: String = entry[0]
		var action_id: String = entry[1]
		fish.reinforced_rod_collected = tool in ["reinforced_rod", "star_rod"]
		fish.star_rod_collected = tool == "star_rod"
		fish.selected_area_tools.clear()
		game._action_runtime().invalidate_stat_cache()
		game._navigation_shell()._render_screen(false)
		await settle(0.3)
		await show_location(action_id, tool + "-idle")
		await select_module_tool(action_id, tool, tool + "-picker")
		var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", action_id)
		await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
		for frame in range(60):
			await process_frame
			var active_area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", action_id)
			if not active_area.is_empty() and (active_area.active_tool_layer as Control).is_visible_in_tree(): break
		check(game.running_action_id == action_id and fish.equipped_tool_id == tool, "Actual UI starts selected tool: " + tool)
		measurements[tool + "-entry"] = check_active_stage(action_id, tool + " entry")
		await capture(tool + "-entry")
		game.action_progress = 0.45
		await settle(0.55)
		measurements[tool + "-reach"] = check_active_stage(action_id, tool + " reach")
		await capture(tool + "-reach")
		game.action_progress = 0.66
		for frame in range(12):
			await process_frame
			check_active_stage(action_id, tool + " wait frame " + str(frame))
		await capture(tool + "-wait")
		# Sweep both complete timelines in the actual mounted production stage.
		# This catches between-keyframe rotation and interpolation overshoot.
		var mounted_area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", action_id)
		var mounted_stage = mounted_area.active_tool_layer
		for frame in range(121):
			mounted_stage.advance(float(frame) / 120.0, -1.0, 1.0 / 60.0, false)
			check(mounted_stage.immersion_depth() <= mounted_stage.MAX_IMMERSION + 0.05, "Full contact timeline stays shallow: " + tool + " frame " + str(frame))
		for frame in range(121):
			mounted_stage.advance(0.65, float(frame) / 120.0, 1.0 / 60.0, false)
			check(mounted_stage.immersion_depth() <= mounted_stage.MAX_IMMERSION + 0.05, "Full haul timeline stays shallow: " + tool + " frame " + str(frame))
		await settle(0.15)
		if tool == "net": fish.net_stored_fish = FishingState.FISHING_NET_HAUL_THRESHOLD - 1
		elif tool == "boat": fish.boat_stored_fish = FishingState.FISHING_BOAT_HAUL_THRESHOLD - 1
		var before_food: float = fish.fish_currency
		game._action_runtime().guaranteed_success_action_completions = 0
		game.action_progress = 0.9999
		for frame in range(90):
			await process_frame
			if fish.fish_currency > before_food: break
		check(fish.fish_currency > before_food, "Real completion still pays food: " + tool)
		measurements[tool + "-haul"] = check_active_stage(action_id, tool + " haul")
		await capture(tool + "-haul")
		await settle(0.28)
		measurements[tool + "-haul-transition"] = check_active_stage(action_id, tool + " haul transition")
		await capture(tool + "-haul-transition")
		await settle(0.65)
		measurements[tool + "-settled"] = check_active_stage(action_id, tool + " settled")
		await capture(tool + "-settled")
		for phase in [0.0, 0.15, 0.30, 0.50, 0.74, 0.95]:
			game.action_progress = phase
			await settle(0.15)
			check_active_stage(action_id, tool + " phase " + str(phase))
		game._action_runtime()._stop_running_action("fishing", action_id)
		await settle(0.12)
		var area: Dictionary = game._fishing_ui_surface()._fishing_area_card_for_action("fishing", action_id)
		check(not (area.active_tool_layer as Control).visible, "Stop hides stage: " + tool)
	check(FishingState.tool_name("line") == "Stick rod" and FishingState.tool_name("reinforced_rod") == "Good rod" and FishingState.tool_name("star_rod") == "Star rod", "Rod display names use source rules")
	var rod_paths: Dictionary={}
	for rod_id in ["line","reinforced_rod","star_rod"]:
		var rod_path: String=game._fishing_ui_surface()._fishing_small_tool_icon_path(rod_id)
		check(ResourceLoader.exists(rod_path),"Rod icon exists: "+rod_id)
		rod_paths[rod_path]=true
	check(rod_paths.size()==3,"All rod tiers have distinct art paths, including in headless validation")
	await capture_prices()
	fish.rod_collected = true
	fish.reinforced_rod_collected = true
	fish.star_rod_collected = true
	fish.mirror_collected = true
	var locations := {}
	for raw_action_id in (FishingState.balance_rules.recommended_location_tools as Dictionary):
		var action_id := str(raw_action_id)
		await show_location(action_id, "")
		var method: Dictionary = game._fishing_ui_surface()._fishing_method_card_for_action("fishing", action_id)
		await click((method.method_image_hit_control as Control).get_global_rect().get_center(), true)
		await settle(0.3)
		check(game.running_action_id == action_id, "Every location starts through actual UI: " + action_id)
		game.action_progress = 0.65
		for frame in range(12):
			await process_frame
			locations[action_id] = check_active_stage(action_id, action_id + " frame " + str(frame))
		if action_id in ["ice-hole", "tunnel-pool", "storm-ripple"]: await capture(action_id + "-active")
		game._action_runtime()._stop_running_action("fishing", action_id)
		await settle(0.12)
	check(locations.size() == 23, "All 23 location stages checked")
	var output := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"failures": failures, "bounds": measurements, "locations": locations}, "  "))
	output.close()
