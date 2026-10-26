extends SceneTree

const Save = preload("res://scripts/save_state/save_runtime.gd")
const Store = preload("res://scripts/save_state/account_save_store.gd")
const Session = preload("res://scripts/online/account_session.gd")
const Online = preload("res://scripts/online/online_runtime.gd")
var failures := []

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func same(path: String, expected: Dictionary) -> bool:
	return Save.load_dictionary(path) == JSON.parse_string(JSON.stringify(expected))

func payload(uid: String, xp: int, provider := "google") -> Dictionary:
	return {"save_schema_version":2, "save_revision":1, "save_reset_generation":0, "saved_at":100, "selected_skill_id":"fight", "skills":{"fight":{"xp":xp,"level":2}}, "mastery":{}, "mats":{}, "stamina":{}, "stamina_bank":{}, "leaderboard_player_id":uid, "leaderboard_auth_bound_uid":uid, "leaderboard_auth_provider":provider}

func _init() -> void:
	if not ProjectSettings.globalize_path("user://").contains("account-save-test"):
		push_error("Refusing account test outside its sandbox")
		quit(1)
		return
	var a := payload("accountA", 100, "anonymous")
	check(Online.google_response_loads_existing_account("google_fresh_sign_in", {"isNewUser": false}), "returning Google login from unbound guest uses account switch")
	check(Online.google_response_loads_existing_account("google_fresh_sign_in", {}), "missing new-account flag cannot adopt an existing account into guest progress")
	check(not Online.google_response_loads_existing_account("google_fresh_sign_in", {"isNewUser": true}), "first Google account keeps current progress")
	check(not Online.google_response_loads_existing_account("google_link", {"isNewUser": false}), "same-UID linking retains its established path")
	check(not Online.google_response_loads_existing_account("google_recover", {}), "recovery retains identity validation")
	var b := payload("accountB", 20)
	var base := payload("accountA", 100)
	base.mats = {"softwood": 100}
	var local := base.duplicate(true)
	var remote := base.duplicate(true)
	local.mats.softwood = 80
	remote.mats.softwood = 120
	var signature := Online.cloud_gameplay_signature(base)
	check(Online.cloud_branches_diverged(local, remote, 1, signature, 2), "equal XP with different resource changes requires choice")
	check(not Online.cloud_branches_diverged(base, remote, 1, signature, 2), "unchanged local branch can accept remote")
	check(not Online.cloud_branches_diverged(local, base, 1, signature, 1), "local branch can advance its known cloud revision")
	check(not Online.cloud_branches_diverged(local, local, 1, signature, 2), "identical changes do not conflict")
	remote = base.duplicate(true)
	remote.saved_at = 999
	remote.save_revision = 99
	remote.leaderboard_auth_refresh_token = "never-upload-this"
	check(Online.cloud_gameplay_signature(remote) == signature, "timestamps and credentials do not create false branches")
	check(Save.write_text(Save.SAVE_PATH, Save.encoded_payload(a)), "fixture write")
	check(Save.write_text(Save.SAVE_BACKUP_PATH, Save.encoded_payload(a)), "fixture backup")
	check(Store.stage(Save, a, b), "guest to Google switch")
	check(same(Save.SAVE_PATH, b), "target is active")
	check(same(Store.ROOT + "/guest.json", a), "guest preserved")
	check(not FileAccess.file_exists(Save.SAVE_BACKUP_PATH), "old account backup isolated")
	check(Store.stage(Save, b, a), "return to guest")
	check(same(Save.SAVE_PATH, a), "guest restored")
	check(same(Store.slot(b), b), "Google progress kept")
	check(not Store.stage(Save, a, {"skills":false}), "invalid target rejected")
	check(same(Save.SAVE_PATH, a), "rejection preserves active save")
	# Interrupted commit is replayed on next boot from its verified target.
	var transaction := Store.ROOT + "/switch-interrupted"
	DirAccess.make_dir_recursive_absolute(transaction)
	Save.write_text(transaction + "/target.json", Save.encoded_payload(b))
	Save.write_text(Store.PENDING, JSON.stringify({"directory":transaction}))
	check(Store.recover(Save), "interrupted transaction recovered")
	check(same(Save.SAVE_PATH, b), "recovery loaded exact target")
	check(Store.recover(Save), "recovery idempotent")
	Save.write_text(Store.PENDING, JSON.stringify({"directory":"user://accounts/../outside"}))
	check(not Store.recover(Save), "unsafe path rejected")
	check(same(Save.SAVE_PATH, b), "bad marker preserves save")
	print("ACCOUNT_SAVE_TEST failures=", failures)
	quit(0 if failures.is_empty() else 1)
