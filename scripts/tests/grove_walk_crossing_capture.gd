extends "res://scripts/tests/action_art_oct22.gd"

var walk_evidence: Array[Dictionary]=[]

func record_walk(stage: Control,state: Dictionary,label: String) -> void:
	# Let the live renderer consume the fixture's starting position before
	# sampling the viewport; never capture a previous-frame center-entry pose.
	await process_frame
	await process_frame
	var seen: Dictionary={}
	var sequence: Array[int]=[]
	var last_frame: int=-1
	for tick in 800:
		await RenderingServer.frame_post_draw
		if state.phase!="walking": break
		var frame: int=int(float(state.age)*10)%8
		if frame==last_frame: continue
		last_frame=frame
		sequence.append(frame)
		if not seen.has(frame) or sequence.size()>8:
			var image:=root.get_texture().get_image()
			check(image.get_size()==Vector2i(1080,1920),"Raw main viewport is 1080x1920")
			image.save_png(capture_dir+"/"+label+"-%02d-frame-%d.png"%[sequence.size()-1,frame])
			seen[frame]=true
			walk_evidence.append({"direction":label,"frame":frame,"age":state.age,"x":state.x,"y":state.y})
		if sequence.size()>=16: break
	check(seen.size()==8,"All eight walking poses rendered: "+label)
	check(sequence.size()>=16,"Two walk loops rendered: "+label)
	for index in range(1,sequence.size()):
		check(sequence[index]==(sequence[index-1]+1)%8,"Walking phases stay sequential: "+label)
	check(stage.HERO_SIDE==152.5 and stage.HERO_GROUND==Vector2(320,600),"Canonical worker scale and foot anchor are unchanged")

func audit_action_art() -> void:
	var runtime=game._grove_runtime()
	runtime.reset()
	await open_notes_skill("woodcutting")
	var card:=await notes_card("grove-birch")
	if card.is_empty(): quit(1); return
	await align_notes_card(card)
	var stage: Control=card.grove_stage
	var state: Dictionary=runtime.state("grove-birch")
	state.trees[0].x=790.0
	state.trees[0].y=.73
	state.trees[1].phase="stump"
	state.trees[1].age=0.0
	game.stamina.woodcutting=100
	await capture("inactive-before-walk")
	await click(stage.get_global_transform_with_canvas()*stage.world_point(790,.73),true)
	await settle(.5)
	check(game.running_action_id=="grove-birch","Actual arena tap activates the grove")
	state.x=100.0
	state.y=.73
	state.target=0
	state.phase="walking"
	state.age=0.0
	state.direction=1.0
	await record_walk(stage,state,"right")
	state.trees[0].x=110.0
	state.x=800.0
	state.age=0.0
	state.direction=-1.0
	await record_walk(stage,state,"left")
	for tick in 1000:
		await process_frame
		if state.phase=="chopping": break
	check(state.phase=="chopping","Walking still reaches the tree and enters chopping")
	await capture("settled-chopping")
	print("GROVE_WALK_CROSSING failures=",JSON.stringify(failures))
	var result:=FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures,"walk_frames":walk_evidence}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)
