extends SceneTree

var failures: Array[String]=[]

func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failures.append(message)

func run() -> void:
	var catalog=preload("res://scripts/activity_data/catalog.gd")
	var ui=preload("res://scripts/ui/action_art_ui.gd")
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://docs/activity-database.json"))
	var action: Dictionary={}
	for skill in source.skills:
		for item in skill.actions:
			if item.id=="gather-sand": action=item
	var animation: Dictionary=catalog._action_art_animation_for_load(action.art_animation)
	var art=ui.ActionArtAnimationRect.new()
	root.add_child(art)
	await process_frame
	art.configure_animation(load(animation.atlas),animation.frame_count,Vector2(384,384),animation.sequence,animation.durations,animation.sync,animation.effects)
	art.set_art_framing(action.art_framing)
	art.set_playing(true)
	check(not art.is_processing(),"Synced overlay does not run on a separate wall-clock timer")
	for index in range(4):
		art.set_action_progress(.64+.26*(index+.5)/4.0)
		check(art.frame_overlay.visible and art.overlay_frame_index==index,"Each progress interval chooses its exact falling-Sand frame")
	art.set_action_progress(.91)
	check(not art.frame_overlay.visible,"Overlay clears at the end of the pour")
	art.set_action_progress(.75)
	art.set_playing(false)
	check(not art.frame_overlay.visible and art.sequence_index==0,"Stopping clears particles and resets the body")
	art.configure_animation(load(animation.atlas),1,Vector2(384,384),[0],[1],"",{"name":"paint_recolor","colors":["#ef4f5f","#39c96d"],"splash":true})
	art.set_playing(true)
	check(art.is_processing() and art.paint_effect_enabled and art.frame_overlay==null,"Existing paint recolor retains its timer and shader without an overlay")
	art.set_playing(false)
	art.configure_animation(load(animation.atlas),4,Vector2(384,384),[0,1,2,3],[1,1,1,1],"progress",{})
	art.set_playing(true)
	art.set_action_progress(.6)
	check(art.sequence_index==2 and not art.is_processing() and not art.paint_effect_enabled,"Ordinary synced body animation remains unchanged")
	art.queue_free()
	await process_frame
	print("ACTION_ART_OVERLAY failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
