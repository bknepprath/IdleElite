extends SceneTree

const FINAL_FISHING_ACTION_ID := "reflection"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "30")
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _frame in range(600):
		if scene.get("boot_restore_complete") and not scene.get("screen_render_in_progress"):
			break
		await process_frame
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var surface = scene.call("_skill_detail_surface")
	if not surface._beta_notice_unlocked():
		push_error("beta notice did not unlock after all final modules")
		quit(1)
		return
	for skill_id in ["thieving", "build", "woodcutting", "fishing"]:
		var entries: Array = surface._visible_detail_entries_for_skill(skill_id)
		if entries.is_empty() or str((entries[-1] as Dictionary).get("kind", "")) != "beta_notice":
			push_error("beta notice missing from %s" % skill_id)
			quit(1)
			return
	var board: Control = surface._build_beta_notice_board(1000.0)
	if not _control_tree_ignores_input(board):
		push_error("beta notice contains an input target")
		quit(1)
		return
	board.free()
	scene.call("_activity_unlock_runtime").manual_activity_unlocks.erase(scene.call("_action_key", "fishing", FINAL_FISHING_ACTION_ID))
	if surface._beta_notice_unlocked():
		push_error("beta notice stayed unlocked with one final module locked")
		quit(1)
		return
	print("beta-notice-unlock-ok")
	quit()


func _control_tree_ignores_input(node: Node) -> bool:
	if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return false
	for child in node.get_children():
		if not _control_tree_ignores_input(child):
			return false
	return true
