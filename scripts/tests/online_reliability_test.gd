extends SceneTree

const Main = preload("res://scripts/main.gd")
const State = preload("res://scripts/leaderboard/state.gd")
var failures: Array[String] = []

class CapturedOnline extends "res://scripts/online/online_runtime.gd":
	var opened_targets: Array[Dictionary] = []
	var sent_messages: Array[String] = []
	var profile_fetches := 0
	func _fetch_profile_recovery_record() -> void:
		profile_fetches += 1
		profile_recovery_fetch_in_flight = true
	func _chat_stream_open_target(target: Dictionary) -> void:
		opened_targets.append(target)
	func _chat_send(message: String) -> void:
		sent_messages.append(message)
	func send_through_production(message: String) -> void:
		super._chat_send(message)

func _init() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	var game = Main.new()
	var online := CapturedOnline.new()
	game.online_runtime = online
	game.add_child(online)
	online.setup(game)
	game.current_screen = "menu"
	game.save_restore_complete = true
	game.skills = {"fight": {"xp": 1000, "level": 10}}
	game.leaderboard_profile.player_id = "uid-reliability"
	game.leaderboard_profile.display_name = "ReturnPlayer"
	game.leaderboard_profile.name_key = "returnplayer"
	game.leaderboard_profile.profile_claimed = true
	game.leaderboard_profile.name_claim_verified = true
	online.leaderboard_config_loaded = true
	online.leaderboard_config_database_url = "https://idle-elite-default-rtdb.firebaseio.com"
	online.leaderboard_config_web_api_key = "AIzaSyValidationOnlyNotARealFirebaseKey123456"
	online.leaderboard_auth_id_token = "test-token"
	online.leaderboard_auth_bound_uid = game.leaderboard_profile.player_id
	online.leaderboard_auth_expires_unix = game._unix_now() + 3600
	online.leaderboard_fresh_start_profile_confirmed_uid = game.leaderboard_profile.player_id
	online.ensure_leaderboard_http()

	_expect(not online._chat_stream_check_response(403, ["Content-Type: application/json"]), "A denied stream must never become live.")
	_expect(not online.chat_stream_connected and online.chat_stream_retry_unix > game._unix_now(), "A denied stream must back off.")
	_expect(not online._chat_stream_check_response(200, ["Content-Type: text/html"]), "A captive portal must not be treated as chat.")
	_expect(online._chat_stream_check_response(200, ["content-type: text/event-stream; charset=utf-8"]), "A valid stream must be accepted.")
	_expect(not online._chat_stream_check_response(307, ["Location: https://s-usc1a-nss-1.firebaseio.com/global_chat/v1/messages.json?ns=idle-elite"]), "A redirect must be followed before accepting a body.")
	_expect(online.opened_targets.size() == 1 and online.opened_targets[0].path.ends_with("?ns=idle-elite"), "Firebase redirects must retain the query.")
	online.chat_stream_redirect_count = online.CHAT_STREAM_MAX_REDIRECTS
	online._chat_stream_check_response(307, ["Location: https://idle-elite-default-rtdb.firebaseio.com/messages.json"])
	_expect(online.opened_targets.size() == 1, "Redirect loops must stop.")
	online._chat_stream_check_response(307, ["Location: https://firebaseio.com.evil.example/messages.json"])
	_expect(online.opened_targets.size() == 1, "Redirects must stay on verified Firebase hosts.")

	var event := "event: put\r\ndata: " + JSON.stringify({"path": "/", "data": {"m1": {"sender_id": "other-player", "name": "Player", "text": "café 🎣", "created_at": 12345}}}) + "\r\n\r\n"
	for byte in event.to_utf8_buffer():
		online._chat_stream_receive_bytes(PackedByteArray([byte]))
	_expect(online.chat_rows.size() == 1 and online.chat_rows[0].text == "café 🎣", "Chat must survive UTF-8 and CRLF split across network packets.")

	var state = game.leaderboard_state
	for category in state.categories():
		state.last_submitted_scores_by_category[category.id] = state.score_for_category(category.id)
	state.last_submitted_total_xp = state.score()
	state.repair_publish_version = State.REPAIR_PUBLISH_VERSION
	_expect(state.submit_ready(), "A returning unchanged save must republish once per session.")
	state.last_submit_unix = game._unix_now()
	_expect(not state.submit_ready(), "Session republishing must respect the saved 15-minute cooldown.")
	state.last_submit_unix = 0
	state.session_publish_confirmed = true
	_expect(not state.submit_ready(), "A confirmed unchanged session must stop publishing.")

	online.profile_recovery_fetch_in_flight = true
	online.send_through_production("Queued message")
	_expect(online.chat_pending_send_after_auth == "Queued message" and not online.chat_send_in_flight, "Chat must wait for the canonical username lookup.")
	online._resume_pending_online_writes()
	_expect(online.sent_messages.is_empty(), "An unfinished profile check must not release queued chat.")
	online.profile_recovery_fetch_in_flight = false
	online._resume_pending_online_writes()
	_expect(online.sent_messages == ["Queued message"] and online.chat_pending_send_after_auth.is_empty(), "Verified usernames must resume queued chat exactly once.")
	online.profile_recovery_lookup_gate = true
	online.profile_recovery_lookup_conclusive_missing = false
	online.send_through_production("Retry lookup")
	_expect(online.profile_fetches == 1, "Send must restart a failed username lookup instead of waiting forever.")
	online._on_profile_recovery_fetch_completed(HTTPRequest.RESULT_TIMEOUT, 0, PackedStringArray(), PackedByteArray())
	_expect(online.chat_pending_send_after_auth.is_empty(), "A failed lookup must release the stalled queued send.")
	_expect(online.chat_send_status_message.contains("Press Send to retry"), "A failed lookup must explain how to retry.")
	online._chat_stream_receive_text("event: keep-alive\ndata: {}\n\n")
	_expect(online.chat_send_status_message.contains("Press Send to retry"), "Read-stream updates must not erase send failures.")
	online.send_through_production("Retry lookup")
	_expect(online.profile_fetches == 2 and online.profile_recovery_fetch_in_flight, "A second send must start a real second lookup.")
	online.profile_recovery_fetch_in_flight = false
	online.profile_recovery_lookup_gate = false
	online._resume_pending_online_writes()
	_expect(online.sent_messages == ["Queued message", "Retry lookup"], "Recovered lookup must resume the requested message exactly once.")
	game.free()
	if failures.is_empty():
		print("online-reliability-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
