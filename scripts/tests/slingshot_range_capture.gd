extends "res://scripts/tests/action_art_oct22.gd"

func audit_action_art() -> void:
	game.stamina.fight=100
	var runtime=game._slingshot_range_runtime()
	runtime.reset()
	runtime.best_distance=8
	runtime.rng.seed=112
	game.skills.fight.xp=SkillState.xp_for_level(25)
	game.skills.fight.level=25
	await open_notes_skill("fight")
	var card:=await notes_card("practice-slingshot")
	await align_notes_card(card)
	var stage: Control=card.slingshot_range_stage
	check(not card.progress.visible and (not is_instance_valid(card.medal) or not card.medal.visible),"No generic progress rail or medals")
	var stats: Array=stage.top_stats()
	check(stats.size()==1 and stats[0].icon_size.y==52,"Header has only full-size stamina and its number")
	check(stage.find_children("*","TextureRect",true,false).is_empty(),"No tutorial arrow exists")
	await capture("slingshot-before")
	await click(stage.shooter_button.get_global_rect().get_center(),true)
	check(runtime.active(),"Actual shooter tap starts the idle range")
	var poses: Dictionary={}
	var shots: Array=[]
	var stored: Dictionary={}
	var xp: int=game.skills.fight.xp
	var timed_tap:=false
	for frame in 1200:
		await RenderingServer.frame_post_draw
		poses[stage.animation_frame()]=true
		if runtime.phase=="ready" and runtime.draw_progress()>.8 and not timed_tap:
			timed_tap=true
			await click(stage.shooter_button.get_global_rect().get_center(),true)
			check(not runtime.clean_release,"Tapping during draw never grants a timing boost")
		if runtime.phase=="flying" and not stored.has("release"):
			stored["release"]=true
			shots.append({"name":"slingshot-release","image":root.get_texture().get_image()})
		if runtime.phase=="flying" and runtime.age/runtime.flight_seconds>.45 and not stored.has("apex"):
			stored["apex"]=true
			check(game.skills.fight.xp==xp,"Airborne rock has not awarded XP")
			shots.append({"name":"slingshot-flight","image":root.get_texture().get_image()})
		if runtime.landings==1: break
	check(runtime.landings==1 and game.skills.fight.xp==xp+runtime.earned_xp,"First contact awards the nerfed XP once")
	game._action_runtime()._stop_running_action("fight","practice-slingshot")
	shots.append({"name":"flag-before-pop","image":root.get_texture().get_image()})
	var previous: float=stage.flag_meters()
	var peak:=0.0
	var captures: Array[float]=[.16,.36,.64]
	var flag_index:=0
	for frame in 200:
		await RenderingServer.frame_post_draw
		check(stage.flag_meters()+.001>=previous,"Record flag moves continuously toward the new record")
		check(stage.flag_meters()-previous<15,"Record flag never jolts to its new position")
		previous=stage.flag_meters()
		peak=maxf(peak,stage.flag_scale())
		if flag_index<captures.size() and stage.flag_age>=captures[flag_index]:
			shots.append({"name":"flag-transition-"+str(flag_index),"image":root.get_texture().get_image()})
			flag_index+=1
		if stage.flag_age>=stage.FLAG_POP_SECONDS: break
	check(peak>1.15 and is_equal_approx(stage.flag_scale(),1),"Bottom-anchored flag overshoots then settles to normal size")
	check(is_equal_approx(stage.flag_meters(),runtime.best_distance),"Flag settles at exact saved record distance")
	for shot in shots:
		check(shot.image.get_size()==Vector2i(1080,1920),"Every raw animation frame keeps phone dimensions")
		shot.image.save_png(capture_dir+"/"+shot.name+".png")
	await capture("slingshot-settled")
	var rock:=await notes_card("clear-rockslide")
	await align_notes_card(rock)
	for item in rock.production_stage.top_stats():
		check(item.icon_size.y==48,"Rockslide icons match number height")
	await capture("rockslide-header")
	await open_notes_skill("woodcutting")
	var grove:=await notes_card("grove-birch")
	await align_notes_card(grove)
	await capture("grove-header")
	game.material_runtime.set_amount("sand",1000)
	game.built_modules["build:melt-sand"]=true
	await open_notes_skill("build")
	var factory:=await notes_card("melt-sand")
	await align_notes_card(factory)
	await capture("production-header")
	print("SLINGSHOT_RANGE_CAPTURE failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"poses":poses.keys(),"flag_peak":peak,"xp":runtime.earned_xp}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
