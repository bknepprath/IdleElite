extends SceneTree

const Presentation = preload("res://scripts/leaderboard/presentation.gd")
const State = preload("res://scripts/leaderboard/state.gd")
const Main = preload("res://scripts/main.gd")
var failures: Array[String] = []

# Exercise the production completion/retry state machine without live writes.
# Only the next outbound request is captured; callbacks use the real runtime.
class CapturedOnline extends "res://scripts/online/online_runtime.gd":
	var sent_paths: Array[String] = []
	var sent_fetches: Array[String] = []
	func _leaderboard_fetch_category(category_id: String, _allow_recent_refresh = false) -> void:
		sent_fetches.append(category_id)
		app.leaderboard_state.fetch_in_flight = true
		app.leaderboard_state.fetch_category_id = category_id
	func _leaderboard_send_next_single_score() -> void:
		if leaderboard_single_score_queue.is_empty():
			super._leaderboard_send_next_single_score()
		else:
			leaderboard_submit_in_flight = true
			leaderboard_submit_stage = "scores_single"
			sent_paths.append(str(leaderboard_single_score_queue.front().path))


func _init() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	_test_rank()
	_test_local_score_fallback()
	_test_submission_recovery()
	_test_missing_rows()
	_test_refresh_race()
	_test_status()
	if failures.is_empty():
		print("leaderboard-sync-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _game():
	var game = Main.new()
	var online := CapturedOnline.new()
	game.online_runtime = online
	game.add_child(online)
	online.setup(game)
	game.current_screen = "menu"
	game.skills = {"fight": {"level": 10, "xp": 1000}}
	game.leaderboard_profile.player_id = "uid-sync-player"
	game.leaderboard_profile.display_name = "SyncPlayer"
	game.leaderboard_profile.name_key = "syncplayer"
	game.leaderboard_profile.profile_claimed = true
	game.leaderboard_profile.name_claim_verified = true
	online.leaderboard_config_loaded = true
	online.leaderboard_config_database_url = "https://idle-elite-default-rtdb.firebaseio.com"
	online.leaderboard_config_web_api_key = "AIzaSyValidationOnlyNotARealFirebaseKey123456"
	online.leaderboard_auth_id_token = "test-token"
	online.leaderboard_auth_bound_uid = game.leaderboard_profile.player_id
	online.leaderboard_auth_expires_unix = game._unix_now() + 3600
	online.leaderboard_fresh_start_profile_confirmed_uid = game.leaderboard_profile.player_id
	return game


func _test_rank() -> void:
	var rows := [
		{"player_id": "a", "score": 495, "total_xp": 27661063},
		{"player_id": "b", "score": 495, "total_xp": 22050930},
		{"player_id": "c", "score": 495, "total_xp": 8835071},
		{"player_id": "d", "score": 495, "total_xp": 6658966},
	]
	_expect(Presentation.player_rank_text("absent", rows, 50) == "Not listed", "An absent high-level player must never get an estimated rank.")
	_expect(Presentation.player_rank_text("a", [], 50) == "Not listed", "An empty board must never report first place.")
	_expect(Presentation.player_rank_text("", rows, 50) == "Not listed", "A missing identity must never match a row.")
	_expect(Presentation.player_rank_text("d", rows, 50) == "#4", "Rank must match the displayed row including XP and name tiebreaks.")
	rows[0]["is_player"] = true
	_expect(Presentation.player_rank_text("absent", rows, 50) == "Not listed", "A cached player flag from another identity must not grant a rank.")
	_expect(Presentation.player_rank_text("d", rows, 3) == "Not listed", "Rows outside the displayed limit must not grant a rank.")


func _test_local_score_fallback() -> void:
	var local_row := {"player_id": "uid-sync-player", "name": "SyncPlayer", "score": 10, "total_xp": 1000, "avatar_index": 2}
	var server_rows := [
		{"player_id": "ahead", "name": "Ahead", "score": 20, "total_xp": 2000},
		{"player_id": "behind", "name": "Behind", "score": 5, "total_xp": 500},
	]
	var original := server_rows.duplicate(true)
	var rows := Presentation.rows_with_local_score(server_rows, local_row, true, 50, true)
	_expect(rows.size() == 3 and rows[1].player_id == local_row.player_id and rows[2].player_id == "behind", "The missing local score must be inserted by score and shift lower rows down.")
	_expect(rows[1].local_fallback and rows[1].is_player, "The fallback must be explicitly local and highlighted as the player.")
	_expect(server_rows == original and not local_row.has("local_fallback"), "Display rows must never mutate the server cache or source score.")
	_expect(Presentation.player_rank_text(local_row.player_id, rows, 50) == "Est. #2", "A locally inserted rank must be identified as an estimate.")
	var stale_own := local_row.duplicate()
	stale_own.score = 1
	stale_own.total_xp = 0
	server_rows.append(stale_own)
	rows = Presentation.rows_with_local_score(server_rows, local_row, true, 50, true)
	_expect(rows.size() == 3 and rows[1].score == 10 and rows[1].local_fallback, "An outdated own row must be replaced, never duplicated.")
	server_rows[2] = local_row.duplicate()
	rows = Presentation.rows_with_local_score(server_rows, local_row, true, 50, true)
	_expect(not rows[1].get("local_fallback", false) and Presentation.player_rank_text(local_row.player_id, rows, 50) == "#2", "A confirmed server row must replace the fallback without duplication.")
	server_rows[2].score = 25
	server_rows[2].total_xp = 2500
	rows = Presentation.rows_with_local_score(server_rows, local_row, true, 50, true)
	_expect(rows[0].score == 25 and not rows[0].get("local_fallback", false), "A better confirmed personal score must not be reduced by the local fallback.")
	var tied := [{"player_id": "other", "name": "A", "score": 10, "total_xp": 900}]
	rows = Presentation.rows_with_local_score(tied, local_row, true, 50, true)
	_expect(rows[0].player_id == local_row.player_id, "Total-level ties must use total XP before name.")
	rows = Presentation.rows_with_local_score(tied, local_row, false, 50, true)
	_expect(rows[0].player_id == "other", "Other categories must use the same name tiebreak as the server display.")
	rows = Presentation.rows_with_local_score([], local_row, true, 50, false)
	_expect(rows.size() == 1 and rows[0].score == 10 and Presentation.player_rank_text(local_row.player_id, rows, 50) == "Rank unavailable", "Offline or unloaded boards must show the saved score without claiming first place.")
	var full_board := []
	for index in range(50):
		full_board.append({"player_id": "other-%s" % index, "name": "Other %s" % index, "score": 99, "total_xp": 9000})
	rows = Presentation.rows_with_local_score(full_board, local_row, true, 50, true)
	_expect(rows.size() == 51 and rows.back().player_id == local_row.player_id, "A score below the cutoff must remain visible after the top 50.")
	_expect(Presentation.player_rank_text(local_row.player_id, rows, 50) == "Outside top 50", "A score outside the fetched board must never be assigned a fake rank of 51.")
	local_row.score = 100
	rows = Presentation.rows_with_local_score(full_board, local_row, true, 50, true)
	_expect(rows.size() == 50 and rows[0].player_id == local_row.player_id, "A top score must enter the list while retaining the top-50 limit.")
	var game = _game()
	game.leaderboard_state.rows_by_category[State.CATEGORY_TOTAL_LEVEL] = original
	game.leaderboard_state.fetch_unix_by_category[State.CATEGORY_TOTAL_LEVEL] = game._unix_now()
	var before_score: int = game.leaderboard_state.last_submitted_total_xp
	rows = game.leaderboard_presentation._display_rows_for_category(State.CATEGORY_TOTAL_LEVEL)
	_expect(rows.size() == 3 and rows[1].score == game.leaderboard_state.score_for_category(State.CATEGORY_TOTAL_LEVEL), "The production view must use the actual saved gameplay score.")
	_expect(game.leaderboard_state.rows_for_category(State.CATEGORY_TOTAL_LEVEL) == original and game.leaderboard_state.last_submitted_total_xp == before_score and game.leaderboard_state.submit_ready(), "Rendering a fallback must leave authoritative rows, acknowledgment and upload retries untouched.")
	game.god_mode_save_tainted = true
	_expect(game.leaderboard_presentation._display_rows_for_category(State.CATEGORY_TOTAL_LEVEL) == original, "Test saves must not be injected into the displayed rankings.")
	game.free()


func _test_submission_recovery() -> void:
	var game = _game()
	var online = game.online_runtime
	var state = game.leaderboard_state
	var total_path := "scores/total_level/uid-sync-player"
	var medals_path := "scores/medals_earned/uid-sync-player"
	# Deliberately reverse dictionary order relative to category order.
	state.pending_score_updates = {medals_path: {"score": 7}, total_path: {"score": 495, "total_xp": 34800000}}
	state.last_submit_payload_categories = [State.CATEGORY_TOTAL_LEVEL, State.CATEGORY_MEDALS]
	state.pending_repair_publish_version = State.REPAIR_PUBLISH_VERSION
	state.repair_publish_version = 0
	online.leaderboard_submit_stage = "scores"
	online.leaderboard_submit_in_flight = true
	online._on_leaderboard_submit_completed(HTTPRequest.RESULT_SUCCESS, 403, [], "{}".to_utf8_buffer())
	_expect(online.sent_paths == [total_path], "Fallback requests must map categories to their actual paths, not dictionary order.")
	game.skills["fight"]["xp"] = 40000000
	online._on_leaderboard_submit_completed(HTTPRequest.RESULT_SUCCESS, 200, [], "null".to_utf8_buffer())
	_expect(int(state.last_submitted_scores_by_category.get(State.CATEGORY_TOTAL_LEVEL, 0)) == 495, "Accepted level must come from the submitted payload.")
	_expect(state.last_submitted_total_xp == 34800000, "Accepted XP must come from the submitted payload, not current gameplay.")
	_expect(online.sent_paths == [total_path, medals_path], "A rejected batch must still try each independent category.")
	online._on_leaderboard_submit_completed(HTTPRequest.RESULT_SUCCESS, 401, [], "{}".to_utf8_buffer())
	_expect(not state.last_submitted_scores_by_category.has(State.CATEGORY_MEDALS), "A denied category must remain unacknowledged and retryable.")
	_expect(state.repair_publish_version == 0, "Partial failure must not mark repair complete.")
	_expect(not state.submission_error.is_empty() and state.next_submit_seconds() > 0, "Partial failure must show an error and respect the retry cooldown.")
	_expect(online.leaderboard_auth_id_token.is_empty() and online.leaderboard_fresh_start_profile_confirmed_uid.is_empty(), "Permission failures must recheck login and canonical profile on retry.")
	_expect(game.leaderboard_profile.player_id == "uid-sync-player", "Upload rejection must preserve the player's identity.")
	# Public read success must not erase upload failure status.
	online._leaderboard_store_fetch_rows(State.CATEGORY_TOTAL_LEVEL, [{"player_id": "someone-else", "score": 495, "total_xp": 27661063}])
	_expect(not state.submission_error.is_empty(), "A successful public read must not hide an upload failure.")
	# A later accepted retry clears only the error and the values it really sent.
	state.pending_score_updates = {medals_path: {"score": 7}}
	state.last_submit_payload_categories = [State.CATEGORY_MEDALS]
	state.pending_repair_publish_version = State.REPAIR_PUBLISH_VERSION
	online.leaderboard_submit_stage = "scores"
	online._on_leaderboard_submit_completed(HTTPRequest.RESULT_SUCCESS, 204, [], PackedByteArray())
	_expect(state.last_submitted_scores_by_category[State.CATEGORY_MEDALS] == 7 and state.submission_error.is_empty(), "An accepted retry must checkpoint its payload and clear the error.")
	_expect(state.repair_publish_version == State.REPAIR_PUBLISH_VERSION, "A fully accepted repair must complete.")
	# Server and transport errors must never acknowledge scores either.
	for code in [429, 500]:
		state.pending_score_updates = {medals_path: {"score": 8}}
		state.last_submit_payload_categories = [State.CATEGORY_MEDALS]
		online.leaderboard_submit_stage = "scores"
		online._on_leaderboard_submit_completed(HTTPRequest.RESULT_SUCCESS, code, [], PackedByteArray())
		_expect(state.last_submitted_scores_by_category[State.CATEGORY_MEDALS] == 7, "HTTP %s must leave the rejected score pending." % code)
	state.pending_score_updates = {medals_path: {"score": 8}}
	state.last_submit_payload_categories = [State.CATEGORY_MEDALS]
	online.leaderboard_submit_stage = "gate"
	online._on_leaderboard_submit_completed(HTTPRequest.RESULT_CANT_CONNECT, 0, [], PackedByteArray())
	_expect(state.last_submitted_scores_by_category[State.CATEGORY_MEDALS] == 7, "Offline failure must not advance the checkpoint.")
	# A late completion from a different identity must not affect the new account.
	state.pending_score_updates = {"scores/medals_earned/previous-uid": {"score": 99}}
	state.last_submit_payload_categories = [State.CATEGORY_MEDALS]
	online.leaderboard_submit_stage = "scores"
	online._on_leaderboard_submit_completed(HTTPRequest.RESULT_SUCCESS, 200, [], PackedByteArray())
	_expect(state.last_submitted_scores_by_category[State.CATEGORY_MEDALS] == 7, "A previous identity's response must not acknowledge the current player's scores.")
	online.leaderboard_submit_in_flight = true
	online.leaderboard_submit_stage = "scores"
	online._on_leaderboard_submit_completed(HTTPRequest.RESULT_SUCCESS, 200, [], PackedByteArray())
	_expect(not online.leaderboard_submit_in_flight and online.leaderboard_submit_stage.is_empty(), "A completion after pending metadata was reset must release the request slot.")
	game.free()


func _test_missing_rows() -> void:
	var game = _game()
	var state = game.leaderboard_state
	state.repair_publish_version = State.REPAIR_PUBLISH_VERSION
	state.last_submit_unix = game._unix_now()
	_expect(state.reconcile_published_rows(State.CATEGORY_TOTAL_LEVEL, []), "An eligible named player missing from a complete board must request repair.")
	_expect(state.repair_publish_version == 0 and not state.submit_ready(), "Repair must preserve the publish cooldown.")
	state.repair_publish_version = State.REPAIR_PUBLISH_VERSION
	var full_board := []
	for index in range(State.TOP_COUNT):
		full_board.append({"player_id": "other-%s" % index, "score": 495, "total_xp": 100000000})
	_expect(not state.reconcile_published_rows(State.CATEGORY_TOTAL_LEVEL, full_board), "Absence below the top-50 cutoff must not cause repair traffic.")
	_expect(state.repair_publish_version == State.REPAIR_PUBLISH_VERSION, "A normal unlisted player must keep the completed repair version.")
	state.last_submitted_scores_by_category[State.CATEGORY_TOTAL_LEVEL] = 495
	state.last_submitted_total_xp = 34800000
	state.reconcile_published_rows(State.CATEGORY_TOTAL_LEVEL, [{"player_id": "uid-sync-player", "score": 100, "total_xp": 1000}])
	_expect(state.repair_publish_version == 0, "A false historical checkpoint must not prevent repairing an older server row.")
	state.rows_by_category[State.CATEGORY_TOTAL_LEVEL] = full_board
	game.online_runtime._on_leaderboard_fetch_completed(HTTPRequest.RESULT_SUCCESS, 200, [], "not json".to_utf8_buffer())
	_expect(state.rows_by_category[State.CATEGORY_TOTAL_LEVEL] == full_board, "Malformed reads must retain the last valid leaderboard.")
	game.free()


func _test_refresh_race() -> void:
	var game = _game()
	game.current_screen = "leaderboard"
	var state = game.leaderboard_state
	var online = game.online_runtime
	var category: String = State.CATEGORY_TOTAL_LEVEL
	state.rows_by_category[category] = [{"player_id": "old-player", "score": 5}]
	state.fetch_in_flight = true
	state.fetch_category_id = category
	state.pending_score_updates = {"scores/total_level/uid-sync-player": {"score": 10, "total_xp": 1000}}
	state.last_submit_payload_categories = [category]
	state.pending_repair_publish_version = State.REPAIR_PUBLISH_VERSION
	online.leaderboard_submit_stage = "scores"
	online._on_leaderboard_submit_completed(HTTPRequest.RESULT_SUCCESS, 200, [], PackedByteArray())
	_expect(online.leaderboard_refresh_after_submit == category, "An upload must queue a refresh when an older read still occupies the request.")
	online._on_leaderboard_fetch_completed(HTTPRequest.RESULT_SUCCESS, 200, [], "{}".to_utf8_buffer())
	_expect(online.sent_fetches == [category], "A stale pre-upload read must trigger exactly one post-upload refresh.")
	_expect(state.rows_by_category[category].size() == 1 and state.repair_publish_version == State.REPAIR_PUBLISH_VERSION, "A pre-upload snapshot must not erase rows or trigger a false repair.")
	var published := {"uid-sync-player": {"name": "SyncPlayer", "score": 10, "total_xp": 1000}}
	online._on_leaderboard_fetch_completed(HTTPRequest.RESULT_SUCCESS, 200, [], JSON.stringify(published).to_utf8_buffer())
	_expect(Presentation.player_rank_text("uid-sync-player", state.rows_by_category[category], 50) == "#1", "The accepted upload must appear after the queued refresh.")
	game.free()


func _test_status() -> void:
	var failed := {"error": "Upload refused", "pending": true, "retry_wait": 900}
	_expect(Presentation.submit_status_title(false, true, true, true, false, 100, false, failed) == "Not synced", "A failed attempt timestamp must never show Synced.")
	_expect(Presentation.submit_status_detail(false, true, true, 0, false, true, false, "", 100, 1, true, false, failed).begins_with("Retry in "), "A failed upload must expose its automatic retry timing.")
	_expect(Presentation.submit_status_title(false, true, true, false, false, 100, false, {"recovery_required": true}) == "Sign in", "Permanent account recovery must not masquerade as automatic sync.")
	_expect(Presentation.submit_status_title(false, true, true, true, false, 100, false, {"pending": true}) == "Pending", "New unsent XP must not show Synced during cooldown.")
	_expect(Presentation.submit_status_title(false, true, true, true, false, 100, false) == "Synced", "Only an accepted, up-to-date submission should show Synced.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
