extends "res://scripts/tests/action_art_oct22.gd"

func quick_tap(point: Vector2) -> void:
	for down in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.index=0
		event.position=point
		event.pressed=down
		root.push_input(event,true)
		await process_frame

func audit_action_art() -> void:
	for material in game.material_runtime.material_defs: game.material_runtime.set_amount(str(material),1000)
	var runtime=game._grove_runtime()
	runtime.reset()
	runtime.rng.seed=625
	await open_notes_skill("woodcutting")
	for id in runtime.IDS:
		var card:=await notes_card(id)
		await align_notes_card(card)
		var stage: Control=card.grove_stage
		check(not card.bg.visible,"No rectangular ground background")
		for child in card.pop.get_parent().get_children():
			if child.name in ["NormalActivityCardBackFace","NormalActivityCardPrismConnectors"]:
				check(not child.visible,"No surrounding rectangular shell")
		check(stage.axe_button.size==Vector2(148,148),"Compact Lv circle retains a generous touch target")
		for widget in stage.arena_widgets:
			check(is_equal_approx(widget.title_label.position.y,widget.value_label.position.y),"Upgrade name and value share one row")
			check(widget.title_label.position.x>=12 and widget.value_label.position.x+widget.value_label.size.x<=widget.size.x-12,"Upgrade row fits without wrapping or clipping")
			check(widget.normal_style.bg_color.is_equal_approx(ThemeStyles.skill_theme_color("woodcutting",Color.WHITE)),"Arena upgrades use the actual woodcutting theme color")
		await capture(id+"-inactive")
	var card:=await notes_card("grove-birch")
	await align_notes_card(card)
	var stage: Control=card.grove_stage
	var state: Dictionary=runtime.state("grove-birch")
	runtime.axe_xp=20*11*11
	stage.queue_redraw()
	await settle(.1)
	check(runtime.axe_level()==12,"Two-digit badge fixture uses level 12")
	await capture("axe-lv-12")
	runtime.axe_xp=0
	game.stamina.woodcutting=100
	var before: int=runtime.felled
	var point: Vector2=stage.get_global_transform_with_canvas()*stage.world_point(450,.91)
	await quick_tap(point)
	await settle(.12)
	check(game.running_action_id=="grove-birch","Oval starts through actual input")
	check(runtime.worker_opacity("grove-birch")>0 and runtime.worker_opacity("grove-birch")<1,"Worker fades in")
	check(is_equal_approx(float(state.x),450) and is_equal_approx(float(state.y),.91),"Worker enters front center before walking")
	check(runtime.felled==before,"Fade-in cannot grant a harvest")
	await capture("worker-fading-in")
	await settle(.55)
	check(runtime.worker_opacity("grove-birch")==1 and not runtime.worker_entering("grove-birch"),"Worker fully appears and starts walking")
	await capture("worker-walking")
	game._action_runtime()._stop_running_action("woodcutting","grove-birch")
	await settle(.12)
	check(runtime.worker_opacity("grove-birch")>0 and runtime.worker_opacity("grove-birch")<1,"Worker fades out")
	await capture("worker-fading-out")
	await settle(.45)
	check(runtime.worker_opacity("grove-birch")==0,"Inactive worker disappears")
	await capture("worker-inactive")
	await quick_tap(point)
	await settle(.12)
	check(is_equal_approx(float(state.x),450) and is_equal_approx(float(state.y),.91),"Reactivation returns to front center")
	await capture("worker-returning")
	await settle(.6)
	for button in stage.arena_buttons: await click(button.get_global_rect().get_center(),true)
	check(runtime.tree_capacity("grove-birch")==3 and runtime.regrowth_seconds("grove-birch")<20 and runtime.rare_chance("grove-birch")==12,"Clearer three-row controls buy their actual capacity, regrowth and rarity upgrades")
	await capture("grove-upgrades-purchased")
	await click(stage.axe_button.get_global_rect().get_center(),true)
	check(stage.shop.visible,"Smaller LV badge still opens the component shop")
	await click(stage.shop.close_button.get_global_rect().get_center(),true)
	check(not stage.shop.visible,"Component shop still closes")
	await open_notes_skill("fight")
	game._rockslide_runtime().reset()
	game.stamina.fight=100
	card=await notes_card("clear-rockslide")
	await align_notes_card(card)
	stage=card.rockslide_stage
	check(not is_instance_valid(card.get("medal")),"Rockslide has no medal control")
	for index in 3:
		var button: Button=stage.buttons[index]
		var title: Label=button.get_node("UpgradeName")
		var value: Label=button.get_node("UpgradeEffect")
		check(absf((title.position.x+value.position.x+value.size.x)*.5-button.size.x*.5)<1,"Upgrade name and value centered together")
		var icon: TextureRect=stage.price_icons[index]
		var price: Label=stage.price_labels[index]
		check(absf((icon.position.x+price.position.x+price.size.x)*.5-button.size.x*.5)<1,"Material icon and price centered together")
	await capture("rockslide-ready")
	await quick_tap(card.pop.get_global_rect().position+Vector2(450,280))
	var poses: Dictionary={}
	for frame in 900:
		await RenderingServer.frame_post_draw
		var pose: int=stage.animation_frame()
		if pose in [0,3,4,5,7] and not poses.has(pose):
			poses[pose]=true
			root.get_texture().get_image().save_png(capture_dir+"/rockslide-pose-"+str(pose)+".png")
		if poses.size()==5: break
	check(poses.size()==5,"Slower draw, release, recoil and recovery all appear")
	await click(stage.buttons[1].get_global_rect().get_center(),true)
	check(int(game._rockslide_runtime().upgrades.speed)==1,"Centered Speed button buys an upgrade")
	await capture("rockslide-speed-upgraded")
	print("ARENA_POLISH failures=",JSON.stringify(failures))
	var report:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures}))
	report.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
