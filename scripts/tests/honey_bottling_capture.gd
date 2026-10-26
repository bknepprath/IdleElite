extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	var p = game._production_runtime()
	var m = game.material_runtime
	p.reset()
	for id in ["empty-bottle","bottled-honey","honey"]: m.set_amount(id,0)
	for id in game.stamina:
		game.stamina[id] = SkillState.host_max_stamina(id,game)
		game.stamina_bank[id] = 0
	game._action_data("thieving","loot-beehive").success = 100
	game._action_runtime().invalidate_stat_cache()
	await open_notes_skill("thieving")
	var card := await notes_card("loot-beehive")
	await align_notes_card(card)
	var stage = card.production_stage
	check(card.action.get("presentation",{}).is_empty(), "Beehive uses the ordinary action card again")
	check(not stage.input_root.visible and not stage.lower_boxes["bottled-honey"].visible, "No bottle controls before bottle discovery")
	await capture("ordinary-beehive")
	await click(card.pop.get_global_rect().get_center(),true)
	await settle(.55)
	await capture("raw-honey-before")
	await wait_for_material("honey",1)
	await settle(.22)
	await capture("raw-honey-falling")
	await settle(.48)
	await capture("raw-honey-landed")
	check(m.amount("honey")>=1 or game.honey_stamina_seconds_remaining>0, "Normal harvest stores the honey hand or consumes it for its original effect")
	game._action_runtime()._stop_running_action("thieving","loot-beehive")
	await settle(.5)
	m.set_amount("empty-bottle",2)
	await settle(.6)
	check(stage.input_root.visible and stage.lower_boxes["bottled-honey"].visible, "Bottle discovery reveals input and both outputs")
	await capture("bottles-unlocked-off")
	await click(stage.bottle_toggle.get_global_rect().get_center(),true)
	check(p.state.bottling, "Real Bottle toggle enables bottling")
	await click(card.pop.get_global_rect().get_center(),true)
	await settle(.2)
	await capture("bottling-before")
	await wait_for_material("bottled-honey",1)
	await settle(.22)
	await capture("bottled-honey-falling")
	await settle(.48)
	await capture("bottled-honey-landed")
	check(stage.badge_id=="bottled-honey", "Portrait badge matches bottled output while an empty remains")
	await wait_for_material("bottled-honey",2)
	await settle(.2)
	check(stage.badge_id=="honey" and m.amount("empty-bottle")==0, "Empty bottle supply automatically returns the portrait badge to a honey hand")
	var raw_before: float = m.amount("honey")
	await wait_for_material("honey",raw_before+1)
	await settle(.22)
	await capture("empty-bottle-fallback")
	game._action_runtime()._stop_running_action("thieving","loot-beehive")
	await settle(.6)
	check(m.amount("bottled-honey")==2 and not p.state.use_bottled_honey, "Bottled honey remains stored with Use off")
	await click(stage.use_toggle.get_global_rect().get_center(),true)
	check(p.state.use_bottled_honey, "Real Use toggle enables automatic consumption")
	await capture("use-enabled")
	# Remove raw honey solely to isolate the bottle's effect in this test.
	m.set_amount("honey",0)
	game.honey_stamina_seconds_remaining = 0
	await open_notes_skill("build")
	var other := await notes_card("stack-bricks")
	await align_notes_card(other)
	game.stamina.thieving = 5
	game.stamina_bank.thieving = 0
	await click(other.pop.get_global_rect().get_center(),true)
	await settle(.4)
	check(game.running_action_id=="stack-bricks", "Next task starts in another skill")
	check(m.amount("bottled-honey")==1 and m.amount("empty-bottle")==1, "Next task consumes one enabled bottle and returns its empty")
	check(game.honey_stamina_seconds_remaining>8.5 and game.honey_stamina_seconds_remaining<=10, "New bottle provides its ten-second effect")
	game._action_runtime()._stop_running_action("build","stack-bricks")
	var report := FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	print("HONEY_CAPTURE failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)

func wait_for_material(id: String, amount: float) -> void:
	var deadline := Time.get_ticks_msec()+14000
	while game.material_runtime.amount(id)<amount and Time.get_ticks_msec()<deadline:
		await process_frame
	check(game.material_runtime.amount(id)>=amount, "Live harvest credits "+id)
