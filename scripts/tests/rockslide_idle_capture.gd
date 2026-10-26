extends "res://scripts/tests/action_art_oct22.gd"

func raw_capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(image.get_size()==Vector2i(1080,1920),"Raw production viewport remains 1080x1920")
	image.save_png(capture_dir+"/"+label+".png")

func knock_out(runtime) -> void:
	for index in 3:
		var group_id: int=9000+index
		runtime.groups[group_id]={"remaining":1,"failed":false}
		var rock: int=runtime.spawn_rock(group_id,229,false)
		runtime.escape_rock(rock)

func audit_action_art() -> void:
	var runtime=game._rockslide_runtime()
	runtime.reset()
	game.stamina.fight=100
	for material in ["scrapwood","softwood","wooden-parts"]: game.material_runtime.set_amount(material,10000)
	await open_notes_skill("fight")
	var card:=await notes_card("clear-rockslide")
	await align_notes_card(card)
	var stage: Control=card.rockslide_stage
	var before: Dictionary=runtime.upgrades.duplicate()
	for index in 3:
		var kind: String=runtime.UPGRADE_KINDS[index]
		await click(stage.resource_buttons[index].get_global_rect().get_center(),true)
		check(stage.resource_name_label.visible and stage.resource_name_label.text==game.material_runtime.display_name(str(runtime.upgrade_cost(kind).id)),"Resource tap shows catalog name: "+kind)
		check(runtime.upgrades==before and not runtime.active(),"Resource tap neither purchases nor starts the activity")
		for button in stage.buttons:
			check(not stage.resource_name_label.get_global_rect().intersects(button.get_global_rect()),"Resource name clears the upgrade controls")
		if index==2: await raw_capture("wooden-parts-name")
	game.material_runtime.set_amount("wooden-parts",0)
	await settle(.35)
	await click(stage.resource_buttons[2].get_global_rect().get_center(),false)
	check(stage.buttons[2].disabled and stage.resource_name_label.visible,"Resource names work on unaffordable upgrades")
	await click(stage.reward_resource_button.get_global_rect().get_center(),true)
	check(stage.resource_name_label.text=="Sand" and not runtime.active(),"Sand reward is identifiable without starting the activity")
	await raw_capture("sand-name")
	await click(stage.buttons[0].get_global_rect().position+Vector2(80,24),true)
	check(runtime.upgrades.power==1,"The upgrade's top row still purchases exactly once")
	await click(card.pop.get_global_rect().position+Vector2(470,320),true)
	check(runtime.active(),"Actual activity tap starts Rockslide")
	await settle(.4)
	runtime.clears=8
	runtime.lifetime_clears=8
	runtime.best_wave=3
	var xp_before: int=game.skills.fight.xp
	await raw_capture("before-knockout-wave-three")
	knock_out(runtime)
	await process_frame
	await process_frame
	await raw_capture("knockout-fall-start")
	await settle(.25)
	await raw_capture("knockout-fall-transition")
	await settle(.4)
	await raw_capture("knocked-out-countdown")
	check(runtime.active() and runtime.knocked_out(),"Knockout preserves the active idle action")
	check(runtime.rocks.is_empty() and runtime.shots.is_empty() and game.skills.fight.xp==xp_before,"No attacks or rewards during knockout")
	for tick in 600:
		await process_frame
		if runtime.knockout_remaining<.3: break
	await raw_capture("standing-back-up")
	for tick in 300:
		await process_frame
		if not runtime.knocked_out(): break
	await settle(.2)
	check(runtime.active() and not runtime.knocked_out() and runtime.wave()==1 and runtime.integrity==3,"The character automatically recovers at wave one")
	check(runtime.upgrades.power==1 and runtime.lifetime_clears==8 and runtime.best_wave==3,"Recovery retains earned progression")
	check(not runtime.rocks.is_empty(),"New run spawns a boulder without another tap")
	await raw_capture("automatic-wave-one")
	knock_out(runtime)
	await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center(),true)
	await settle(5.5)
	check(runtime.active() and not runtime.knocked_out() and runtime.wave()==1,"Automatic recovery also completes when the module is unmounted")
	print("ROCKSLIDE_IDLE failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
