extends RefCounted

const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")


static func read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


static func write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	file.close()
	return true


static func load_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_buffer(file.get_length()).get_string_from_utf8()
	var json := JSON.new()
	if json.parse(raw) != OK:
		return {}
	var save_payload: Variant = json.data
	if typeof(save_payload) != TYPE_DICTIONARY:
		return {}
	return save_payload as Dictionary


static func write_payload_atomically(payload: Dictionary, save_path: String, temp_path: String, backup_path: String) -> bool:
	var payload_text := JSON.stringify(payload)
	if FileAccess.file_exists(save_path):
		var existing := load_dictionary(save_path)
		if not existing.is_empty():
			var existing_text := read_text(save_path)
			if not existing_text.is_empty():
				write_text(backup_path, existing_text)
	if not write_text(temp_path, payload_text):
		return false
	var temp_data := load_dictionary(temp_path)
	if temp_data.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return false
	if FileAccess.file_exists(save_path):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		if remove_error != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
			return false
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(save_path)
	)
	if rename_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return false
	return true


static func best_dictionary_from_paths(paths: Array, skill_defs: Array) -> Dictionary:
	var best_save := {}
	for path in paths:
		if not FileAccess.file_exists(path):
			continue
		var candidate_save := load_dictionary(path)
		if candidate_save.is_empty():
			continue
		if should_replace_best_save(best_save, candidate_save, skill_defs):
			best_save = candidate_save
	return best_save


static func should_replace_best_save(best_save: Dictionary, candidate: Dictionary, skill_defs: Array) -> bool:
	if candidate.is_empty():
		return false
	if best_save.is_empty():
		return true
	var candidate_reset_generation := SaveStateNormalizers.save_reset_generation(candidate)
	var best_reset_generation := SaveStateNormalizers.save_reset_generation(best_save)
	if candidate_reset_generation != best_reset_generation:
		return candidate_reset_generation > best_reset_generation
	var candidate_xp := SaveStateNormalizers.total_skill_xp_evidence(candidate, skill_defs)
	var best_xp := SaveStateNormalizers.total_skill_xp_evidence(best_save, skill_defs)
	if candidate_xp != best_xp:
		return candidate_xp > best_xp
	return int(candidate.get("saved_at", 0)) > int(best_save.get("saved_at", 0))
