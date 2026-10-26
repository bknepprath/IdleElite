extends "res://scripts/tests/action_art_oct22.gd"

const Geometry = preload("res://scripts/gameplay/grove_geometry.gd")
var measurements: Array[Dictionary]=[]

func check_contact(stage: Control,runtime,id: String,tree: Dictionary,direction: float,depth: float,bountiful: bool) -> void:
	tree.x=450.0
	tree.y=depth
	tree.bountiful=bountiful
	tree.rare=bountiful
	var destination: Vector2=runtime.chopping_destination(id,tree,100.0 if direction>0 else 800.0)
	var worker: Vector2=stage.world_point(destination.x,destination.y/runtime.FIELD_DEPTH)
	var reach: Vector2=(Geometry.AXE_CONTACT-Geometry.HERO_GROUND)*Geometry.HERO_SIDE/Geometry.HERO_FRAME_SIZE*stage.world_scale(destination.y/runtime.FIELD_DEPTH)
	var axe_point: Vector2=worker+Vector2(reach.x*direction,reach.y)
	var side:=Geometry.tree_side(bountiful,false)
	var tree_point: Vector2=stage.world_point(450,depth)
	var index:=int(runtime.rules(id).index)
	var bark_x: float=Geometry.TRUNK_EDGES[index].x if direction>0 else Geometry.TRUNK_EDGES[index].y
	var bark_point: Vector2=tree_point+Vector2((bark_x-256)*side/512.0,reach.y/stage.world_scale(depth))*stage.world_scale(depth)
	var penetration: float=(axe_point.x-bark_point.x)*direction
	check(penetration>0 and penetration<3,"Axe contacts near bark without passing through: "+id+" direction "+str(direction)+" depth "+str(depth)+" bonus "+str(bountiful))
	measurements.append({"grove":id,"direction":direction,"depth":depth,"bountiful":bountiful,"penetration_pixels":penetration,"worker_x":destination.x})

func audit_action_art() -> void:
	var runtime=game._grove_runtime()
	runtime.reset()
	await open_notes_skill("woodcutting")
	for id in runtime.IDS:
		var card:=await notes_card(id)
		if card.is_empty(): continue
		await align_notes_card(card)
		var stage: Control=card.grove_stage
		var state: Dictionary=runtime.state(id)
		var tree: Dictionary=state.trees[0]
		tree.source_id=id
		tree.hp=100
		state.trees[1].phase="stump"
		state.trees[1].age=0.0
		for depth in [.32,.6,.91]:
			for direction in [1.0,-1.0]:
				for bonus in [false,true]: check_contact(stage,runtime,id,tree,direction,depth,bonus)
		for direction in [1.0,-1.0]:
			tree.x=450.0
			tree.y=.65
			tree.rare=false
			tree.bountiful=false
			tree.phase="standing"
			tree.hp=100
			game.stamina.woodcutting=100
			await click(stage.get_global_transform_with_canvas()*stage.world_point(450,.65),true)
			await settle(.5)
			state.x=200.0 if direction>0 else 700.0
			state.y=.65
			state.target=0
			state.phase="walking"
			state.age=0.0
			state.detour=false
			var poses: Dictionary={}
			for tick in 1800:
				await RenderingServer.frame_post_draw
				if state.phase!="chopping": continue
				var ratio: float=float(state.age)/runtime.swing_seconds(id)
				var pose:=0 if ratio<.5 else (1 if ratio<.72 else 2)
				if not poses.has(pose):
					poses[pose]=true
					var image:=root.get_texture().get_image()
					check(image.get_size()==Vector2i(1080,1920),"Contact proof uses the raw production viewport")
					image.save_png(capture_dir+"/"+id+("-right" if direction>0 else "-left")+"-pose-"+str(pose)+".png")
				if poses.size()==3: break
			check(poses.size()==3,"Approach reaches windup/contact/follow-through: "+id)
			check(float(state.direction)==direction,"Worker faces the trunk: "+id)
			check(float(state.y)>float(tree.y),"The active tree stays behind the worker without canopy fading: "+id)
			game._action_runtime()._stop_running_action("woodcutting",id)
			await settle(.4)
	print("GROVE_AXE_CONTACT failures=",JSON.stringify(failures))
	var result:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures,"measurements":measurements}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
