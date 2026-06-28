extends SceneTree

const DEFAULT_RESULT_PATH := "res://.codex-tmp/verify-live-fishing-save/result.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_write_json({"status": "failed", "error": "main scene did not load"})
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await _wait_for_startup(main)
	var skills := main.get("skills") as Dictionary
	var selected_skill_id := str(main.get("selected_skill_id"))
	var result := {
		"status": "ok",
		"selected_skill_id": selected_skill_id,
		"fishing_level": _skill_level(skills, "fishing"),
		"fishing_xp": _skill_xp(skills, "fishing"),
		"build_level": _skill_level(skills, "build"),
		"fight_level": _skill_level(skills, "fight"),
		"thieving_level": _skill_level(skills, "thieving"),
		"woodcutting_level": _skill_level(skills, "woodcutting"),
		"save_path": ProjectSettings.globalize_path(main.get("SAVE_PATH"))
	}
	_write_json(result)
	root.remove_child(main)
	main.queue_free()
	quit(0)


func _wait_for_startup(main: Node) -> void:
	for _i in range(720):
		if bool(main.get("startup_initialized")):
			await process_frame
			return
		await process_frame


func _skill_level(skills: Dictionary, skill_id: String) -> int:
	if not skills.has(skill_id) or typeof(skills[skill_id]) != TYPE_DICTIONARY:
		return -1
	return int((skills[skill_id] as Dictionary).get("level", -1))


func _skill_xp(skills: Dictionary, skill_id: String) -> int:
	if not skills.has(skill_id) or typeof(skills[skill_id]) != TYPE_DICTIONARY:
		return -1
	return int((skills[skill_id] as Dictionary).get("xp", -1))


func _write_json(payload: Dictionary) -> void:
	var path := OS.get_environment("IDLE_ELITE_VERIFY_LIVE_SAVE_RESULT")
	if path.is_empty():
		path = DEFAULT_RESULT_PATH
	var absolute_path := path if path.is_absolute_path() else ProjectSettings.globalize_path(path)
	var directory := absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
