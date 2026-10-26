extends RefCounted

const SaveRuntime = preload("res://scripts/save_state/save_runtime.gd")
const Store = preload("res://scripts/save_state/account_save_store.gd")
const Profile = preload("res://scripts/leaderboard/profile.gd")
const Identity = preload("res://scripts/online/identity_safety.gd")
var online
var auth := {}
var request: HTTPRequest
var history := false
var busy := false

func _init(owner) -> void:
	online = owner

func prepare_authenticated(data: Dictionary) -> void:
	var uid := Profile.sanitize_player_id(str(data.get("localId", "")))
	if uid.is_empty() or str(data.get("idToken", "")).is_empty() or str(data.get("refreshToken", "")).is_empty() or int(data.get("expiresIn", 0)) <= 0:
		fail("Google sign-in returned incomplete account data")
		return
	auth = data.duplicate(true)
	busy = true
	history = false
	read_account()

func read_account() -> void:
	if request == null:
		request = HTTPRequest.new()
		request.timeout = 20
		request.accept_gzip = not OS.has_feature("web")
		online.add_child(request)
		request.request_completed.connect(received)
	var uid := str(auth.localId)
	var path := "history/%s/slots" % uid if history else "users/%s" % uid
	var error := request.request(online._cloud_save_firebase_url(path, "auth=" + str(auth.idToken).uri_encode()), PackedStringArray(["Accept: application/json"]))
	if error != OK:
		fail("Could not check the account save. Your current game is unchanged")

func received(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not busy:
		return
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		fail("Could not check the account save. Your current game is unchanged")
		return
	var raw := body.get_string_from_utf8().strip_edges()
	var parsed = JSON.parse_string(raw)
	var candidate: Dictionary = {}
	if history:
		if raw != "null" and not parsed is Dictionary and not parsed is Array:
			fail("Account backups could not be read. Your current game is unchanged")
			return
		var rows: Array = parsed.values() if parsed is Dictionary else (parsed if parsed is Array else [])
		var best := -1
		for row in rows:
			if row is Dictionary:
				var payload: Dictionary = online._cloud_save_payload_from_record(row, true, str(auth.localId))
				if not payload.is_empty() and int(row.get("revision", 0)) > best:
					candidate = payload
					best = int(row.get("revision", 0))
		if not rows.is_empty() and candidate.is_empty():
			fail("Account backups need recovery. Your current game is unchanged")
			return
		if candidate.is_empty():
			candidate = fresh_guest()
		candidate["cloud_save_base_revision"] = maxi(0, best)
	elif parsed is Dictionary:
		candidate = online._cloud_save_payload_from_record(parsed, true, str(auth.localId))
		if candidate.is_empty():
			fail("Account save needs recovery. Your current game is unchanged")
			return
		candidate["cloud_save_base_revision"] = int(parsed.get("revision", 0))
	elif raw == "null":
		history = true
		read_account()
		return
	else:
		fail("Account save could not be read. Your current game is unchanged")
		return
	# Never copy the current guest's name, resources or progression into a different
	# existing account. Authenticated identity replaces only credentials in its save.
	for key in Identity.IDENTITY_COMPARISON_KEYS:
		if str(key).begins_with("leaderboard_auth_") or key in ["leaderboard_name_transfer_required", "leaderboard_deleted_auth_transition_pending", "leaderboard_legacy_username_recovery_required", "leaderboard_legacy_authless_old_uid"]:
			candidate.erase(key)
	candidate["leaderboard_player_id"] = str(auth.localId)
	candidate["leaderboard_auth_bound_uid"] = str(auth.localId)
	candidate["leaderboard_auth_refresh_token"] = str(auth.refreshToken)
	candidate["leaderboard_auth_provider"] = "google"
	candidate["leaderboard_auth_recovery_required"] = false
	candidate["cloud_save_base_signature"] = online.cloud_gameplay_signature(candidate)
	busy = false
	auth.clear()
	activate(candidate)

func fresh_guest() -> Dictionary:
	var skills := {}
	for definition in online.app.skill_defs:
		skills[str(definition.id)] = {"xp": 0, "level": 1}
	return {"save_schema_version": 2, "save_revision": 1, "save_reset_generation": 0, "saved_at": online.app._unix_now(), "selected_skill_id": "fight", "skills": skills, "mastery": {}, "mats": {}, "stamina": {}, "stamina_bank": {}, "leaderboard_player_id": Profile.make_player_id(), "leaderboard_display_name": Profile.make_guest_display_name("guest"), "leaderboard_auth_provider": "anonymous"}

func summary(payload: Dictionary) -> String:
	var total := 0
	for skill in payload.get("skills", {}).values():
		total += int(skill.get("level", 1))
	var date := Time.get_datetime_string_from_unix_time(int(payload.get("saved_at", 0)), true)
	return "Level %s\n%s UTC" % [total, date]

func panel(title: String, message: String) -> VBoxContainer:
	var dialog = online.app._settings_surface().privacy()
	var stack: VBoxContainer = dialog._panel(title, true)
	dialog.overlay.name = "AccountDialog"
	var label: Label = online.app._label(message, 52, online.app.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(label)
	return stack

func show_existing_account() -> void:
	var stack := panel("Account already exists", "Load the game saved to this Google account?\nYour guest game will stay on this device")
	var dialog = online.app._settings_surface().privacy()
	dialog._button(stack, "Load Google account", func():
		dialog.close()
		online._start_google_firebase_exchange(false, "account_switch"))
	dialog._button(stack, "Cancel", func(): online._clear_pending_google_credential(); dialog.close())

func show_switch(target: Dictionary) -> void:
	var stack := panel("Load account", summary(target) + "\nYour current game will be kept on this device")
	var dialog = online.app._settings_surface().privacy()
	dialog._button(stack, "Load this game", func(): activate(target))
	var saved_local := SaveRuntime.load_dictionary(Store.slot(target))
	if not saved_local.is_empty() and str(saved_local.get("leaderboard_auth_bound_uid", "")) == str(target.get("leaderboard_auth_bound_uid", "")):
		var local_target := Identity.payload_with_preserved_identity_for_comparison(saved_local, target)
		dialog._button(stack, "Use saved device copy", func(): show_local_copy(local_target))
	dialog._button(stack, "Cancel", dialog.close)

func show_local_copy(target: Dictionary) -> void:
	var stack := panel("Device copy", summary(target))
	var dialog = online.app._settings_surface().privacy()
	dialog._button(stack, "Load this game", func(): activate(target))
	dialog._button(stack, "Cancel", dialog.close)

func show_sign_out() -> void:
	var guest := SaveRuntime.load_dictionary(Store.ROOT + "/guest.json")
	# A guest identity that was upgraded to this Google account is no longer
	# anonymous. Never restore its old refresh token as a guest session.
	if guest.is_empty() or str(guest.get("leaderboard_auth_provider", "anonymous")) != "anonymous" or str(guest.get("leaderboard_player_id", "")) == str(online.leaderboard_auth_bound_uid):
		guest = fresh_guest()
	var stack := panel("Sign out", "Return to guest play on this device?\nYour account game will be kept on this device")
	var dialog = online.app._settings_surface().privacy()
	dialog._button(stack, "Sign out", func(): activate(guest))
	dialog._button(stack, "Cancel", dialog.close)

func show_conflict() -> void:
	var remote: Dictionary = online.cloud_save_last_remote_payload.duplicate(true)
	if remote.is_empty():
		return
	var local: Dictionary = online.app._save_runtime()._save_payload(online.app._unix_now())
	var etag: String = online.cloud_save_remote_etag
	var stack := panel("Choose a save", "This device\n%s\n\nCloud\n%s\n\nBoth copies will be kept as backups" % [summary(local), summary(remote)])
	var dialog = online.app._settings_surface().privacy()
	dialog._button(stack, "Use cloud save", func():
		var target := Identity.payload_with_preserved_identity_for_comparison(remote, local)
		target["cloud_save_base_revision"] = online.cloud_save_remote_revision
		target["cloud_save_base_signature"] = online.cloud_gameplay_signature(target)
		activate(target))
	dialog._button(stack, "Use this device", func():
		if online.cloud_save_remote_etag != etag or etag.is_empty() or not Store.stash(SaveRuntime, local):
			fail("Save changed. Check cloud save again")
			return
		online.cloud_save_manual_choice_payload = local
		online.cloud_save_manual_choice_etag = etag
		online.cloud_save_conflict_detected = false
		online._upload_cloud_save(true)
		dialog.close())
	dialog._button(stack, "Cancel", dialog.close)

func activate(target: Dictionary) -> void:
	var save = online.app._save_runtime()
	if busy or not online.app.save_restore_complete or save.save_writes_blocked or save.web_storage_guard.writes_disabled:
		fail("Finish save recovery before switching accounts")
		return
	if online.cloud_save_upload_in_flight or online.cloud_save_history_in_flight or online.leaderboard_auth_in_flight:
		fail("Saving is in progress. Try again in a moment")
		return
	busy = true
	if not save.save_game():
		fail("Your current game could not be saved. Account was not switched")
		return
	var current: Dictionary = save._save_payload(online.app._unix_now())
	if not Store.stage(SaveRuntime, current, target):
		# A committed transaction must be recovered before any gameplay write.
		if FileAccess.file_exists(Store.PENDING):
			save.save_writes_blocked = true
			save.save_writes_blocked_reason = "Account switch needs a restart"
		fail("Account switch could not finish. Restart to recover the saved copies")
		return
	save._sync_web_userfs_after_save()
	save.save_writes_blocked = true
	for child in online.get_children():
		if child is HTTPRequest:
			child.cancel_request()
	online.set_process(false)
	online.app.get_tree().call_deferred("reload_current_scene")

func fail(message: String) -> void:
	busy = false
	auth.clear()
	online.google_auth_status_message = message
	online.cloud_save_status_message = message
	var stack := panel("Account", message)
	var dialog = online.app._settings_surface().privacy()
	dialog._button(stack, "Close", dialog.close)
