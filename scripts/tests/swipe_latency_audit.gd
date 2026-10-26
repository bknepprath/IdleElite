extends "res://scripts/tests/action_art_oct22.gd"

var results: Array = []

func audit_action_art() -> void:
	Engine.max_fps = 60
	game._temporary_event_runtime().temporary_event_active.clear()
	game._temporary_event_runtime().temporary_event_next_roll_unix = game._unix_now()+86400
	await open_notes_skill("build")
	if OS.get_environment("IDLE_ELITE_SWIPE_VISUAL")=="1":
		for offset in [1,-1,1]:
			await swipe_measure(offset,"visual")
			await settle(.1)
		write_report()
		return
	if OS.get_environment("IDLE_ELITE_SWIPE_DIAGNOSTIC")=="1":
		for frame in 180:
			await process_frame
			if frame%30==0:
				var a=game._skill_swipe_activity_surface()._adjacent_pages()
				var s=game._skill_swipe_activity_surface()
				var d=game._skill_detail_surface()
				print("ADJ_DIAG ",JSON.stringify({"enabled":a.enabled(),"blocked":a._build_blocked(),"token":a.build_token,"pages":a.debug_state(),"rendering":a.neighbour_render_active,"render_skill":a.render_record.get("skill_id",""),"tracking":s.skill_swipe_tracking,"animating":s.skill_swipe_animating,"scroll_work":d.detail_scroll_visual_work_this_frame,"mount_work":d.detail_lazy_mounted_this_frame,"loading":game._skill_swipe_loading_transition_active(),"render_screen":game._navigation_shell().screen_render_in_progress,"cover":is_instance_valid(s.skill_swipe_handoff_cover),"boot":game.boot_detail_render_in_progress,"boot_scroll":game.boot_detail_scroll_locked,"queue":game.boot_detail_render_queue.size(),"tutorial":game._onboarding_runtime().tutorial_active}))
	for step in 12:
		await swipe_measure(1 if step<7 else -1, "rapid")
		await settle(.06)
	# A page invalidated by progress or reopening must not stall at finger-down.
	game._skill_swipe_activity_surface()._adjacent_pages().discard_all()
	await swipe_measure(1,"cold")
	await settle(.4)
	await swipe_measure(-1,"return")
	write_report()

func write_report() -> void:
	var report := FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures":failures,"samples":results},"\t"))
	report.close()
	print("SWIPE_LATENCY failures=",JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)

func send_touch(point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index=0
	event.pressed=down
	event.position=point
	Input.parse_input_event(event.xformed_by(root.get_final_transform()))

func send_drag(point: Vector2, previous: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index=0
	event.position=point
	event.relative=point-previous
	Input.parse_input_event(event.xformed_by(root.get_final_transform()))

func page_content_visible(page: Control) -> bool:
	if not is_instance_valid(page) or not page.is_visible_in_tree(): return false
	for card in game.action_cards.values():
		var control: Control=card.get("root")
		if is_instance_valid(control) and page.is_ancestor_of(control) and control.is_visible_in_tree() and control.get_global_rect().intersects(Rect2(0,410,1080,990)):
			return true
	return false

func swipe_measure(offset: int, mode: String) -> void:
	var swipe = game._skill_swipe_activity_surface()
	var adjacent = swipe._adjacent_pages()
	var source: String=game.selected_skill_id
	var target: String=swipe._skill_id_for_swipe_offset(offset)
	var ready: bool=adjacent.page_ready(offset)
	var debug_before: Dictionary=adjacent.debug_state()
	if ready: validate_page_layout(adjacent.page_for_offset(offset))
	var proof: Array=[]
	var image_prefix: String=str(results.size())+"-"+source+"-to-"+target
	if mode=="visual": proof.append({"name":"before","image":root.get_texture().get_image()})
	var started := Time.get_ticks_usec()
	var previous_tick := started
	var frame_ms: Array = []
	var first_content := -1.0
	var start := Vector2(860 if offset>0 else 220,1020)
	var finish := Vector2(180 if offset>0 else 900,1020)
	send_touch(start,true)
	await process_frame
	frame_ms.append((Time.get_ticks_usec()-previous_tick)/1000.0)
	previous_tick=Time.get_ticks_usec()
	var previous := start
	for index in range(1,17):
		var point:=start.lerp(finish,float(index)/16)
		send_drag(point,previous)
		previous=point
		await process_frame
		frame_ms.append((Time.get_ticks_usec()-previous_tick)/1000.0)
		previous_tick=Time.get_ticks_usec()
		if mode=="visual" and index==12: proof.append({"name":"during","image":root.get_texture().get_image()})
		if first_content<0 and page_content_visible(adjacent.page_for_offset(offset)):
			first_content=(Time.get_ticks_usec()-started)/1000.0
	var release_time := Time.get_ticks_usec()
	send_touch(finish,false)
	var deadline := Time.get_ticks_msec()+12000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		frame_ms.append((Time.get_ticks_usec()-previous_tick)/1000.0)
		previous_tick=Time.get_ticks_usec()
		if game.selected_skill_id==target and first_content<0 and page_content_visible(swipe.skill_swipe_page): first_content=(Time.get_ticks_usec()-started)/1000.0
		if game.selected_skill_id==target and not swipe.skill_swipe_animating and not game._skill_swipe_loading_transition_active(): break
	var release_ms := (Time.get_ticks_usec()-release_time)/1000.0
	check(game.selected_skill_id==target,"Swipe lands on "+target)
	check(page_content_visible(swipe.skill_swipe_page),"Incoming real page has visible cards: "+target)
	validate_page_layout(swipe.skill_swipe_page)
	frame_ms.sort()
	var result := {"from":source,"to":target,"mode":mode,"ready_start":ready,"first_content_ms":first_content,"release_ms":release_ms,"frame_p95_ms":frame_ms[int(frame_ms.size()*.95)],"frame_max_ms":frame_ms.back(),"neighbours_before":debug_before,"neighbours_after":adjacent.debug_state(),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))}
	results.append(result)
	print("SWIPE_SAMPLE ",JSON.stringify(result))
	if mode=="visual":
		await RenderingServer.frame_post_draw
		proof.append({"name":"settled","image":root.get_texture().get_image()})
		for frame in proof:
			check(frame.image.get_size()==Vector2i(1080,1920),"Raw real-game proof retains native portrait dimensions")
			frame.image.save_png(capture_dir+"/"+image_prefix+"-"+frame.name+".png")

func validate_page_layout(page: Control) -> void:
	if not is_instance_valid(page): return
	for card in game.action_cards.values():
		if not card.has("grove_stage") or not page.is_ancestor_of(card.root): continue
		var stage=card.grove_stage
		for widget in stage.arena_widgets:
			check(widget.position.y>stage.size.y-200 and widget.size.x>200,"Tree arena buttons are positioned before their page arrives")
			check(widget.button.size.x>=widget.size.x-1 and widget.base.size.x>=widget.size.x-1,"Tree arena button faces are sized before their page arrives")
			check(widget.value_label.position.x>=widget.title_label.position.x+widget.title_label.size.x,"Tree arena button text does not arrive stacked")
