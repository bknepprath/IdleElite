extends "res://scripts/tests/action_art_oct22.gd"
func audit_action_art() -> void:
	for material in game.material_runtime.material_defs: game.material_runtime.set_amount(str(material),1000)
	var r=game._grove_runtime()
	r.reset()
	for id in r.IDS:
		var only:=OS.get_environment("IDLE_ELITE_GROVE_CAPTURE_IDS")
		if not only.is_empty() and id not in only.split(","): continue
		await open_notes_skill("woodcutting")
		var card:=await notes_card(id)
		await align_notes_card(card)
		check(card.has("grove_stage"),"Grove mounts: "+id)
		if not card.has("grove_stage"): continue
		check(not is_instance_valid(card.get("medal")),"Grove has no medal control")
		check(not card.bg.visible,"Oval arena replaces the rectangular land background")
		await capture(id+"-idle")
		if id=="grove-birch":
			# Select a valid random seed that demonstrates the capacity purchase's rare spawn.
			var rare_seed: int=-1
			for seed_value in 1000:
				r.rng.seed=seed_value
				if bool(r.new_tree(id,r.state(id).trees,0.0).rare):
					rare_seed=seed_value
					break
			r.rng.seed=rare_seed
			for index in 3: await click(card.grove_stage.arena_buttons[index].get_global_rect().get_center(),true)
			check(r.tree_capacity(id)==3 and r.regrowth_seconds(id)<20 and r.rare_chance(id)>5,"Three real arena buttons buy capacity, regrowth and rarity")
			check(bool(r.state(id).trees.back().rare),"Real capacity purchase rolls and renders a higher-tier tree")
			await capture("arena-upgrades-purchased")
		if id!="grove-birch": r.state(id).trees[0].hp=1
		var before: int=r.felled
		game.stamina.woodcutting=100
		await click(card.pop.get_global_rect().position+Vector2(470,350),true)
		check(game.running_action_id==id,"Grove starts from actual tap")
		var captured: Dictionary={}
		for frame in 1500:
			await process_frame
			var s: Dictionary=r.state(id)
			var phase: String=s.phase
			var key:=phase
			if phase=="chopping": key="chop-contact" if float(s.age)/r.swing_seconds(id)>=.54 else "chop-raised"
			if phase=="falling" and float(s.age)<.5: key="fall-start"
			if phase=="falling" and float(s.age)>=.5: key="fall-transition"
			if not captured.has(key):
				captured[key]=true
				await capture(id+"-"+key)
			if r.felled>before and float(s.reward_age)<.3:
				await capture(id+"-logs")
				break
		check(r.felled>before,"Visible grove completes its harvest")
		await settle(1.4)
		await capture(id+"-stump")
		if id=="grove-birch":
			await click(card.grove_stage.axe_button.get_global_rect().get_center(),true)
			check(card.grove_stage.shop.visible,"Axe ring opens component upgrades")
			await capture("axe-shop")
			await click(card.grove_stage.shop.purchase_button.get_global_rect().get_center(),true)
			check(int(r.upgrades.handle)==1,"Real axe shop buys Handle")
			await capture("axe-shop-purchased")
			await click(card.grove_stage.shop.close_button.get_global_rect().get_center(),true)
			check(not card.grove_stage.shop.visible,"Axe shop closes before navigation")
		game._action_runtime()._stop_running_action("woodcutting",id)
	await open_notes_skill("fight")
	var card:=await notes_card("practice-slingshot")
	await align_notes_card(card)
	await capture("slingshot-range-idle")
	game.stamina.fight=100
	await click(card.pop.get_global_rect().position+Vector2(340,190),true)
	await settle(.8)
	await capture("slingshot-range-release")
	await settle(.55)
	await capture("slingshot-range-arc")
	await settle(.9)
	await capture("slingshot-range-landed")
	check(game._slingshot_range_runtime().landings>0,"Slingshot lands and rewards through real UI")
	game._action_runtime()._stop_running_action("fight","practice-slingshot")
	print("GROVE_CAPTURE failures=",JSON.stringify(failures))
	var f:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"failures":failures}))
	f.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
