extends "res://scripts/tests/action_art_oct22.gd"

func capture(label: String) -> void:
	var card := await notes_card("clear-rockslide")
	await align_notes_card(card)
	await super.capture(label)

func audit_action_art() -> void:
	var runtime = game._rockslide_runtime()
	runtime.reset()
	game.stamina.fight = 100
	for id in ["scrapwood","softwood","wooden-parts"]: game.material_runtime.set_amount(id,10000)
	await open_notes_skill("fight")
	var card := await notes_card("clear-rockslide")
	await align_notes_card(card)
	check(card.has("rockslide_stage"),"Real rockslide stage mounts in the actual activity card")
	if not card.has("rockslide_stage"): quit(1); return
	var stage: Control = card.rockslide_stage
	await capture("rockslide-idle")
	await click(card.pop.get_global_rect().position+Vector2(470,320),true)
	check(runtime.active(),"Actual activity tap starts the simulation")
	await settle(.3)
	await capture("rockslide-shot")
	await settle(.8)
	await capture("rockslide-impact")
	for frame in 480:
		await process_frame
		if runtime.splits>0: break
	check(runtime.splits>0,"Live firing breaks the large boulder into fragments")
	await capture("rockslide-split")
	for frame in 600:
		await process_frame
		if runtime.lifetime_clears>0: break
	check(runtime.lifetime_clears>0,"Live fragments finish and grant actual rewards")
	await capture("rockslide-cleared")
	var upgrade: Button=stage.buttons[0]
	var resting_y:=upgrade.position.y
	var press:=InputEventScreenTouch.new()
	press.index=0
	press.position=upgrade.get_global_rect().get_center()
	press.pressed=true
	root.push_input(press,true)
	await settle(.15)
	check(upgrade.position.y>resting_y,"Upgrade face depresses into its extruded base")
	await super.capture("rockslide-upgrade-pressed")
	press=press.duplicate()
	press.pressed=false
	root.push_input(press,true)
	await settle(.15)
	check(is_equal_approx(upgrade.position.y,resting_y),"Upgrade face returns after release")
	await click(stage.buttons[1].get_global_rect().get_center(),true)
	await click(stage.buttons[2].get_global_rect().get_center(),true)
	await click(stage.buttons[2].get_global_rect().get_center(),true)
	check(runtime.shot_damage()==2 and runtime.volley_size()==3 and int(runtime.upgrades.speed)==1,"Real upgrade controls affect actual shots")
	await settle(.7)
	await capture("rockslide-upgraded")
	for frame in 1800:
		await process_frame
		if runtime.wave()>1: break
	check(runtime.wave()>1,"Four cleared groups visibly advance the wave")
	await capture("rockslide-next-wave")
	var before: int = runtime.shots_fired
	await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center(),true)
	await settle(6.0)
	print("ROCKSLIDE_AWAY active=",runtime.active()," shots=",runtime.shots_fired," before=",before)
	check(runtime.active() and runtime.shots_fired>before,"Shooting continues when the module is unmounted")
	# Navigate back without the menu helper, which intentionally stops actions.
	var menu: Control = game.skill_cards.fight.button
	game.content_scroll.scroll_vertical += int(menu.get_global_rect().get_center().y-950)
	await settle(.5)
	await click(menu.get_global_rect().get_center(),true)
	card = await notes_card("clear-rockslide")
	await align_notes_card(card)
	await capture("rockslide-returned")
	game._action_runtime()._stop_running_action("fight","clear-rockslide")
	await settle(.3)
	await capture("rockslide-stopped")
	print("ROCKSLIDE_CAPTURE failures=",JSON.stringify(failures))
	var report := FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
