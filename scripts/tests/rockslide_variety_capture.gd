extends "res://scripts/tests/action_art_oct22.gd"

func raw_capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	check(image.get_size()==Vector2i(1080,1920),"Variety proof uses the raw 1080x1920 game viewport")
	image.save_png(capture_dir+"/"+label+".png")

func audit_action_art() -> void:
	var runtime=game._rockslide_runtime()
	runtime.reset()
	for material in ["scrapwood","softwood","wooden-parts","hardwood","ironwood"]: game.material_runtime.set_amount(material,10000)
	await open_notes_skill("fight")
	var card:=await notes_card("clear-rockslide")
	await align_notes_card(card)
	var stage: Control=card.rockslide_stage
	await click(card.pop.get_global_rect().position+Vector2(470,320),true)
	game.stamina.fight=100
	await settle(.4)
	check(runtime.active(),"Real activity tap activates the mixed-rock simulation")
	# Deterministic live-model fixture: three actual rock types roll through
	# the production stage. No isolated renderer or replacement UI is used.
	runtime.clear_transient()
	runtime.spawn_clock=100
	runtime.shot_clock=100
	for index in 3:
		var kind: String=["boulder","runner","armored"][index]
		var group_id: int=7000+index
		runtime.groups[group_id]={"remaining":1,"failed":false}
		var id: int=runtime.spawn_rock(group_id,float([390,580,790][index]),false,0.0,kind)
		runtime.rocks[id].rotation=float([.2,1.1,2.3][index])
	await process_frame
	await process_frame
	await raw_capture("mixed-rocks-contact-start")
	await settle(.3)
	await raw_capture("mixed-rocks-contact-rolling")
	await settle(.4)
	await raw_capture("mixed-rocks-contact-settled")
	for rock in runtime.rocks.values():
		check(float(rock.lift)==0 and float(rock.vy)==0,"Settled "+str(rock.kind)+" follows the ground without hopping")
	var runner: Dictionary=runtime.rocks.values()[1]
	runtime.hit_rock(int(runner.id),1)
	await raw_capture("damaged-runner")
	var heavy: Dictionary=runtime.rocks.values()[2]
	runtime.hit_rock(int(heavy.id),5)
	await raw_capture("damaged-armored-boulder")
	game._action_runtime()._stop_running_action("fight","clear-rockslide")
	await settle(.2)
	runtime.reset()
	runtime.upgrades.speed=2
	stage.refresh_controls()
	await click(stage.resource_buttons[1].get_global_rect().get_center(),true)
	check(stage.resource_name_label.text=="Wooden Parts","Later Speed levels require crafted resources instead of only Softwood")
	await raw_capture("speed-crafted-resource-cost")
	await click(card.pop.get_global_rect().position+Vector2(470,320),true)
	await settle(3.6)
	var has_runner:=false
	for rock in runtime.rocks.values(): has_runner=has_runner or str(rock.kind)=="runner"
	check(has_runner,"The actual opening pattern introduces a fast stone before wave two")
	await raw_capture("live-opening-pattern")
	print("ROCKSLIDE_VARIETY failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
