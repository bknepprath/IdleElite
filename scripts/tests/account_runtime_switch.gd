extends SceneTree

const Save = preload("res://scripts/save_state/save_runtime.gd")
const Store = preload("res://scripts/save_state/account_save_store.gd")
var failures := []

class FixtureSession extends "res://scripts/online/account_session.gd":
	var fixture_record: Dictionary
	func _init(owner, record: Dictionary) -> void:
		super(owner)
		fixture_record = record
	func read_account() -> void:
		received.call_deferred(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), JSON.stringify(fixture_record).to_utf8_buffer())

func _init() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func wait_ready(game) -> bool:
	for _index in range(600):
		await process_frame
		if game.startup_initialized and game.save_restore_complete and not game._boot_warmup_runtime().active:
			return true
	return false

func wait_replacement(old_id: int):
	for _index in range(600):
		await process_frame
		if current_scene != null and current_scene.get_instance_id() != old_id:
			var ready: bool = await wait_ready(current_scene)
			check(ready, "replacement scene restores its save")
			return current_scene
	return null

func run() -> void:
	create_timer(75).timeout.connect(func(): push_error("Account runtime test timed out"); quit(1))
	if DisplayServer.get_name() == "headless":
		push_error("Scene-reload test requires --visible-game; headless shutdown deliberately exits this game")
		quit(1)
		return
	root.size = Vector2i(1080, 1920)
	if not ProjectSettings.globalize_path("user://").contains("account-runtime-test"):
		quit(1)
		return
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "0")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	AudioServer.set_bus_mute(0, true)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	check(await wait_ready(game), "initial main scene boots")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game.material_runtime.set_amount("softwood", 123)
	check(game._save_runtime().save_game(), "guest save writes")
	var guest: Dictionary = game._save_runtime()._save_payload(game._unix_now())
	var target := guest.duplicate(true)
	target["leaderboard_player_id"] = "account-runtime-target"
	target["leaderboard_auth_bound_uid"] = "account-runtime-target"
	target["leaderboard_auth_provider"] = "google"
	target["leaderboard_auth_refresh_token"] = "fixture-only-no-network"
	target["mats"] = {"softwood": 7}
	target["log_currency"] = 7
	var old_id: int = game.get_instance_id()
	var online = game._online_runtime()
	var record: Dictionary = online._cloud_save_record(target, game._unix_now(), 3)
	record.uid = "account-runtime-target"
	online.account_session = FixtureSession.new(online, record)
	online.leaderboard_auth_mode = "google_fresh_sign_in"
	online._on_google_auth_exchange_completed(HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), JSON.stringify({"localId":"account-runtime-target", "idToken":"fixture-only", "refreshToken":"fixture-only-no-network", "expiresIn":"3600", "isNewUser":false}).to_utf8_buffer())
	game = await wait_replacement(old_id)
	check(game != null, "Google switch reloads real main scene")
	if game != null:
		check(game.leaderboard_profile.player_id == "account-runtime-target", "Google UID restored")
		check(int(game.material_runtime.amount("softwood")) == 7, "Google inventory stays separate")
		check(game._save_runtime().save_game(), "switched account can save")
		check(int(Save.load_dictionary(Store.ROOT + "/guest.json").mats.softwood) == 123, "guest retained on device")
		old_id = game.get_instance_id()
		game._online_runtime().accounts().show_sign_out()
		for item in game.find_children("*", "Button", true, false):
			if item.text == "Sign out" and item.is_visible_in_tree():
				item.pressed.emit()
				break
		game = await wait_replacement(old_id)
		check(game != null, "guest return reloads real main scene")
		if game != null:
			check(game.leaderboard_profile.player_id == str(guest.leaderboard_player_id), "guest identity restored")
			check(int(game.material_runtime.amount("softwood")) == 123, "guest inventory restored")
			check(game._save_runtime().save_game(), "returned guest can save")
			check(int(Save.load_dictionary(Store.slot(target)).mats.softwood) == 7, "Google inventory retained on device")
	print("ACCOUNT_RUNTIME_SWITCH failures=", failures)
	var report := FileAccess.open("res://outputs/verification/accounts/runtime-switch-result.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"failures": failures}))
	report.close()
	if game != null: game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
