extends Node

const ChatState = preload("res://scripts/online/chat_state.gd")
const LeaderboardPresentation = preload("res://scripts/leaderboard/presentation.gd")
const LeaderboardProfile = preload("res://scripts/leaderboard/profile.gd")
const LeaderboardState = preload("res://scripts/leaderboard/state.gd")
const IdentitySafety = preload("res://scripts/online/identity_safety.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const SaveRuntime = preload("res://scripts/save_state/save_runtime.gd")
const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const FIREBASE_URL_SCHEME := "https://"
const FIREBASE_US_HOST_SUFFIX := ".firebaseio.com"
const FIREBASE_REGIONAL_HOST_SUFFIX := ".firebasedatabase.app"
const FIREBASE_HOST_CHARS := "abcdefghijklmnopqrstuvwxyz0123456789-"
const FIREBASE_PLACEHOLDER_DATABASE_URL := "https://YOUR-PROJECT-default-rtdb.firebaseio.com"
const FIREBASE_PLACEHOLDER_WEB_API_KEY := "YOUR_FIREBASE_WEB_API_KEY"
const FIREBASE_LOCAL_CONFIG_PATH := "res://firebase-leaderboard-config.json"
const LEADERBOARD_FIREBASE_ROOT := "leaderboards/v1"
const CHAT_FIREBASE_ROOT := "global_chat/v1"
const LEADERBOARD_FETCH_INTERVAL_SECONDS := 15 * 60
const LEADERBOARD_PROCESS_INTERVAL_SECONDS := 30.0
const LEADERBOARD_AUTH_REFRESH_MARGIN_SECONDS := 5 * 60
const LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS := 15 * 60
const FIREBASE_AUTH_SIGN_UP_URL := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s"
const FIREBASE_AUTH_REFRESH_URL := "https://securetoken.googleapis.com/v1/token?key=%s"
const FIREBASE_AUTH_SIGN_IN_WITH_IDP_URL := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=%s"
const GOOGLE_AUTH_ANDROID_SINGLETON := "IdleEliteGoogleAuth"
const GOOGLE_AUTH_PROVIDER_ID := "google.com"
const GOOGLE_AUTH_REQUEST_URI := "http://localhost"
const GOOGLE_AUTH_WEB_CLIENT_ID_CONFIG_KEY := "google_web_client_id"
const CLOUD_SAVE_FIREBASE_ROOT := "cloud_saves/v1"
const CLOUD_SAVE_UPLOAD_INTERVAL_SECONDS := 5 * 60
const CLOUD_SAVE_MAX_PAYLOAD_CHARS := 950000
const CLOUD_SAVE_HISTORY_SLOT_COUNT := 5
const FIREBASE_ETAG_REQUEST_HEADER := "X-Firebase-ETag: true"
const DISABLE_ONLINE_REQUESTS_ENV := "IDLE_ELITE_DISABLE_ONLINE_REQUESTS"
const LEADERBOARD_HTTP_HEADER_JSON := "Content-Type: application/json"
const LEADERBOARD_HTTP_HEADER_ACCEPT_JSON := "Accept: application/json"
const LEADERBOARD_HTTP_HEADER_FORM := "Content-Type: application/x-www-form-urlencoded"

signal cloud_save_loaded(payload)
signal cloud_save_status_changed()
signal leaderboard_rows_changed(category_id)
signal leaderboard_status_changed()
signal chat_rows_changed()
signal chat_status_changed()
signal profile_reference_changed()

var app
var leaderboard_auth_request: HTTPRequest
var google_auth_exchange_request: HTTPRequest
var cloud_save_fetch_request: HTTPRequest
var cloud_save_upload_request: HTTPRequest
var cloud_save_history_request: HTTPRequest
var cloud_save_history_fetch_request: HTTPRequest
var profile_recovery_fetch_request: HTTPRequest
var leaderboard_fetch_request: HTTPRequest
var leaderboard_total_xp_fetch_request: HTTPRequest
var leaderboard_submit_request: HTTPRequest
var leaderboard_name_claim_request: HTTPRequest
var leaderboard_name_recovery_request: HTTPRequest
var profile_reference_update_request: HTTPRequest
var chat_send_request: HTTPRequest
var chat_fetch_request: HTTPRequest
var chat_stream_client: HTTPClient
var chat_stream_poll_timer: Timer
var leaderboard_http_built := false
var cloud_save_fetch_in_flight := false
var cloud_save_upload_in_flight := false
var cloud_save_dirty := false
var cloud_save_last_upload_unix := 0
var cloud_save_last_fetch_unix := 0
var cloud_save_remote_checked := false
var cloud_save_last_remote_summary := {}
var cloud_save_last_remote_payload := {}
var cloud_save_status_message := ""
var cloud_save_remote_etag := ""
var cloud_save_remote_revision := 0
var cloud_save_pending_record := {}
var cloud_save_last_remote_record := {}
var cloud_save_last_remote_record_archived := false
var cloud_save_history_in_flight := false
var cloud_save_pending_history_record := {}
var cloud_save_pending_history_purpose := ""
var cloud_save_history_fetch_in_flight := false
var cloud_save_history_checked := false
var cloud_save_history_fetch_reason := ""
var cloud_save_conflict_detected := false
var cloud_save_remote_write_blocked := false
var chat_stream_connected := false
var chat_stream_connecting := false
var chat_stream_request_sent := false
var chat_fetch_in_flight := false
var chat_stream_retry_unix := 0
var chat_stream_next_connect_unix := 0
var chat_stream_visible_count := 0
var chat_stream_buffer := ""
var chat_stream_event_name := ""
var chat_stream_event_data_lines := []
var leaderboard_auth_in_flight := false
var leaderboard_auth_mode := ""
var leaderboard_auth_id_token := ""
var leaderboard_auth_refresh_token := ""
var leaderboard_auth_expires_unix := 0
var leaderboard_auth_retry_after_unix := 0
var leaderboard_auth_provider := "anonymous"
var leaderboard_auth_bound_uid := ""
var leaderboard_auth_recovery_required := false
var leaderboard_auth_recovery_reason := ""
var leaderboard_auth_definitive_failure_code := ""
var leaderboard_auth_recovery_pending_refresh_token := ""
var leaderboard_legacy_authless_old_uid := ""
var leaderboard_deleted_auth_transition_pending := false
var leaderboard_name_transfer_required := false
var leaderboard_legacy_username_recovery_required := false
var leaderboard_legacy_name_hint_display := ""
var leaderboard_legacy_name_hint_key := ""
var leaderboard_auth_last_error_class := "none"
var leaderboard_auth_last_transition_outcome := "none"
var leaderboard_auth_diagnostic_events := []
var leaderboard_config_loaded := false
var leaderboard_config_database_url := ""
var leaderboard_config_web_api_key := ""
var google_auth_web_client_id := ""
var google_auth_plugin: Object
var google_auth_plugin_connected := false
var google_auth_in_flight := false
var google_auth_status_message := ""
var google_auth_pending_id_token := ""
var google_auth_pending_email := ""
var google_auth_pending_display_name := ""
var google_auth_exchange_was_link := false
var google_auth_exchange_intent := ""
var leaderboard_submit_in_flight := false
var leaderboard_submit_stage := ""
var leaderboard_name_claim_in_flight := false
var leaderboard_name_claim_pending_name := ""
var leaderboard_name_claim_pending_key := ""
var leaderboard_name_claim_request_started := false
var leaderboard_name_recovery_in_flight := false
var leaderboard_name_recovery_pending_display := ""
var leaderboard_name_recovery_pending_key := ""
var profile_reference_update_in_flight := false
var profile_reference_update_stage := ""
var profile_reference_pending_updates := {}
var profile_reference_refresh_queued := false
var profile_recovery_fetch_in_flight := false
var profile_recovery_required_after_google_switch := false
var profile_recovery_lookup_gate := false
var profile_recovery_lookup_conclusive_missing := false
var chat_send_in_flight := false
var chat_send_stage := ""
var chat_rows := []
var chat_last_send_unix := 0
var chat_status_message := ""
var chat_pending_send_after_auth := ""
var chat_pending_send_message_id := ""
var chat_pending_send_text := ""
var chat_pending_send_payload := {}
var chat_last_opened_created_at := 0
var chat_last_opened_message_id := ""


func setup(owner) -> void:
	app = owner


func process(delta: float) -> void:
	_process_leaderboard_sync(delta)


func fetch_cloud_save() -> void:
	_fetch_cloud_save()


func upload_cloud_save(payload: Dictionary = {}) -> void:
	_upload_cloud_save(false)


func reset_cloud_save_state() -> void:
	cloud_save_fetch_in_flight = false
	cloud_save_upload_in_flight = false
	cloud_save_dirty = false
	cloud_save_last_upload_unix = 0
	cloud_save_last_fetch_unix = 0
	cloud_save_remote_checked = false
	cloud_save_last_remote_summary.clear()
	cloud_save_last_remote_payload.clear()
	cloud_save_status_message = ""
	cloud_save_remote_etag = ""
	cloud_save_remote_revision = 0
	cloud_save_pending_record.clear()
	cloud_save_last_remote_record.clear()
	cloud_save_last_remote_record_archived = false
	cloud_save_history_in_flight = false
	cloud_save_pending_history_record.clear()
	cloud_save_pending_history_purpose = ""
	cloud_save_history_fetch_in_flight = false
	cloud_save_history_checked = false
	cloud_save_history_fetch_reason = ""
	cloud_save_conflict_detected = false
	cloud_save_remote_write_blocked = false


func reset_chat_runtime_state() -> void:
	chat_stream_connected = false
	chat_stream_connecting = false
	chat_stream_request_sent = false
	chat_fetch_in_flight = false
	chat_rows.clear()
	chat_stream_retry_unix = 0
	chat_stream_next_connect_unix = 0
	chat_stream_visible_count = 0
	chat_stream_buffer = ""
	chat_stream_event_name = ""
	chat_stream_event_data_lines.clear()
	chat_send_in_flight = false
	chat_last_send_unix = 0
	chat_last_opened_created_at = 0
	chat_last_opened_message_id = ""
	chat_status_message = ""
	chat_send_stage = ""
	chat_pending_send_after_auth = ""
	chat_pending_send_message_id = ""
	chat_pending_send_text = ""
	chat_pending_send_payload.clear()


func reset_leaderboard_runtime_state() -> void:
	leaderboard_auth_in_flight = false
	leaderboard_auth_mode = ""
	leaderboard_auth_id_token = ""
	leaderboard_auth_refresh_token = ""
	leaderboard_auth_expires_unix = 0
	leaderboard_auth_retry_after_unix = 0
	leaderboard_auth_provider = "anonymous"
	leaderboard_auth_bound_uid = ""
	leaderboard_auth_recovery_required = false
	leaderboard_auth_recovery_reason = ""
	leaderboard_auth_definitive_failure_code = ""
	leaderboard_auth_recovery_pending_refresh_token = ""
	leaderboard_legacy_authless_old_uid = ""
	leaderboard_deleted_auth_transition_pending = false
	leaderboard_name_transfer_required = false
	leaderboard_legacy_username_recovery_required = false
	leaderboard_legacy_name_hint_display = ""
	leaderboard_legacy_name_hint_key = ""
	leaderboard_auth_last_error_class = "none"
	leaderboard_auth_last_transition_outcome = "none"
	leaderboard_auth_diagnostic_events.clear()
	google_auth_in_flight = false
	google_auth_status_message = ""
	google_auth_pending_id_token = ""
	google_auth_pending_email = ""
	google_auth_pending_display_name = ""
	google_auth_exchange_was_link = false
	google_auth_exchange_intent = ""
	leaderboard_submit_in_flight = false
	leaderboard_submit_stage = ""
	leaderboard_name_claim_in_flight = false
	leaderboard_name_claim_pending_name = ""
	leaderboard_name_claim_pending_key = ""
	leaderboard_name_claim_request_started = false
	leaderboard_name_recovery_in_flight = false
	leaderboard_name_recovery_pending_display = ""
	leaderboard_name_recovery_pending_key = ""
	profile_reference_update_in_flight = false
	profile_reference_update_stage = ""
	profile_reference_pending_updates.clear()
	profile_reference_refresh_queued = false
	profile_recovery_fetch_in_flight = false
	profile_recovery_required_after_google_switch = false
	profile_recovery_lookup_gate = false
	profile_recovery_lookup_conclusive_missing = false


func restore_leaderboard_auth_metadata_from_save(data: Dictionary) -> void:
	leaderboard_auth_id_token = ""
	leaderboard_auth_refresh_token = LeaderboardProfile.refresh_token_for_save(str(data.get("leaderboard_auth_refresh_token", "")))
	leaderboard_auth_recovery_pending_refresh_token = ""
	leaderboard_auth_expires_unix = 0
	leaderboard_auth_retry_after_unix = maxi(0, int(data.get("leaderboard_auth_retry_after_unix", 0)))
	leaderboard_auth_provider = LeaderboardProfile.auth_provider_for_save(str(data.get("leaderboard_auth_provider", "")).strip_edges())


func auth_identity_metadata_for_save() -> Dictionary:
	return {
		"leaderboard_auth_bound_uid": LeaderboardProfile.sanitize_player_id(leaderboard_auth_bound_uid),
		"leaderboard_auth_recovery_required": leaderboard_auth_recovery_required,
		"leaderboard_auth_recovery_reason": leaderboard_auth_recovery_reason.substr(0, 120),
		"leaderboard_auth_definitive_failure_code": leaderboard_auth_definitive_failure_code,
		"leaderboard_legacy_authless_old_uid": LeaderboardProfile.sanitize_player_id(leaderboard_legacy_authless_old_uid),
		"leaderboard_deleted_auth_transition_pending": leaderboard_deleted_auth_transition_pending,
		"leaderboard_name_transfer_required": leaderboard_name_transfer_required,
		"leaderboard_legacy_username_recovery_required": leaderboard_legacy_username_recovery_required,
		"leaderboard_legacy_name_hint_display": LeaderboardProfile.sanitize_display_name(leaderboard_legacy_name_hint_display, app.PROFILE_DISPLAY_NAME_MAX_CHARS),
		"leaderboard_legacy_name_hint_key": LeaderboardProfile.sanitize_name_key(leaderboard_legacy_name_hint_key, app.PROFILE_NAME_KEY_MAX_CHARS)
	}


func restore_auth_identity_metadata_from_save(data: Dictionary) -> void:
	var saved_bound_uid := LeaderboardProfile.sanitize_player_id(str(data.get("leaderboard_auth_bound_uid", "")))
	var saved_player_uid := LeaderboardProfile.sanitize_player_id(str(data.get("leaderboard_player_id", app.leaderboard_profile.player_id)))
	var saved_profile_claimed := bool(data.get("leaderboard_profile_claimed", false))
	var saved_name_key := LeaderboardProfile.sanitize_name_key(str(data.get("leaderboard_name_key", "")), app.PROFILE_NAME_KEY_MAX_CHARS)
	var saved_legacy_authless := IdentitySafety.legacy_authless_google_transition_allowed(
		saved_player_uid,
		leaderboard_auth_refresh_token,
		saved_bound_uid,
		leaderboard_auth_provider
	)
	# Legacy web builds created p+32 ids without Firebase Auth. Do not turn that
	# public local id into a canonical Auth binding during restore.
	if saved_bound_uid.is_empty() and not saved_legacy_authless and (
		not leaderboard_auth_refresh_token.is_empty()
		or saved_profile_claimed
		or str(data.get("leaderboard_auth_provider", "")) == "google"
		or not IdentitySafety.is_local_placeholder_player_id(saved_player_uid)
	):
		saved_bound_uid = saved_player_uid
	leaderboard_auth_bound_uid = saved_bound_uid
	leaderboard_auth_recovery_required = bool(data.get("leaderboard_auth_recovery_required", false))
	leaderboard_auth_recovery_reason = str(data.get("leaderboard_auth_recovery_reason", "")).strip_edges().substr(0, 120)
	leaderboard_auth_definitive_failure_code = IdentitySafety.refresh_failure_code(400, str(data.get("leaderboard_auth_definitive_failure_code", "")))
	leaderboard_legacy_authless_old_uid = LeaderboardProfile.sanitize_player_id(str(data.get("leaderboard_legacy_authless_old_uid", "")))
	leaderboard_deleted_auth_transition_pending = bool(data.get("leaderboard_deleted_auth_transition_pending", false))
	leaderboard_name_transfer_required = bool(data.get("leaderboard_name_transfer_required", false))
	leaderboard_legacy_username_recovery_required = bool(data.get("leaderboard_legacy_username_recovery_required", false))
	var raw_hint_display := LeaderboardProfile.sanitize_display_name(str(data.get("leaderboard_legacy_name_hint_display", data.get("leaderboard_display_name", ""))), app.PROFILE_DISPLAY_NAME_MAX_CHARS)
	var raw_hint_key := LeaderboardProfile.sanitize_name_key(str(data.get("leaderboard_legacy_name_hint_key", saved_name_key)), app.PROFILE_NAME_KEY_MAX_CHARS)
	var hint_is_valid := (
		not raw_hint_key.is_empty()
		and not LeaderboardProfile.is_guest_display_name(raw_hint_display, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
		and not LeaderboardProfile.is_default_display_name(raw_hint_display, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
		and LeaderboardProfile.make_name_key(raw_hint_display, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS) == raw_hint_key
	)
	var legacy_transition_state_present := leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required
	var saved_identity_may_need_canonical_recovery: bool = (
		not leaderboard_auth_refresh_token.is_empty()
		or not saved_bound_uid.is_empty()
		or leaderboard_auth_provider == "google"
		or (not saved_player_uid.is_empty() and not IdentitySafety.is_local_placeholder_player_id(saved_player_uid))
	)
	if hint_is_valid and (saved_legacy_authless or legacy_transition_state_present or saved_identity_may_need_canonical_recovery):
		leaderboard_legacy_name_hint_display = raw_hint_display
		leaderboard_legacy_name_hint_key = raw_hint_key
	else:
		leaderboard_legacy_name_hint_display = ""
		leaderboard_legacy_name_hint_key = ""
	if not legacy_transition_state_present:
		leaderboard_legacy_authless_old_uid = ""
		if leaderboard_deleted_auth_transition_pending:
			leaderboard_auth_recovery_required = true
			leaderboard_auth_recovery_reason = "Saved account transfer needs support."
	elif leaderboard_deleted_auth_transition_pending and (
		leaderboard_legacy_authless_old_uid.is_empty()
		or IdentitySafety.is_local_placeholder_player_id(leaderboard_legacy_authless_old_uid)
		or not IdentitySafety.deleted_uid_transition_failure_code_valid(leaderboard_auth_definitive_failure_code)
	):
		leaderboard_auth_recovery_required = true
		leaderboard_auth_recovery_reason = "Saved deleted-account transfer needs support."
	elif not leaderboard_deleted_auth_transition_pending and not IdentitySafety.is_local_placeholder_player_id(leaderboard_legacy_authless_old_uid):
		leaderboard_auth_recovery_required = true
		leaderboard_auth_recovery_reason = "Saved legacy profile recovery needs support."
	elif leaderboard_name_transfer_required and not _legacy_name_hint_valid():
		leaderboard_name_transfer_required = false
		leaderboard_legacy_username_recovery_required = true
	elif leaderboard_auth_provider != "google" or leaderboard_auth_refresh_token.is_empty() or saved_player_uid == leaderboard_legacy_authless_old_uid:
		leaderboard_auth_recovery_required = true
		leaderboard_auth_recovery_reason = "Reconnect Google to finish the saved profile recovery."
	if leaderboard_auth_recovery_required and leaderboard_auth_recovery_reason.is_empty():
		leaderboard_auth_recovery_reason = "Saved online identity needs recovery."
	_record_auth_diagnostic("identity_restored")


func _save_restore_complete() -> bool:
	return app != null and bool(app.save_restore_complete)


func _auth_uid_fingerprint(uid: String) -> String:
	var clean := LeaderboardProfile.sanitize_player_id(uid)
	return "" if clean.is_empty() else clean.sha256_text().substr(0, 12)


func _record_auth_diagnostic(event_name: String, detail = "") -> void:
	leaderboard_auth_diagnostic_events.append({
		"at_unix": app._unix_now() if app != null else 0,
		"event": event_name.strip_edges().substr(0, 48),
		"detail": str(detail).strip_edges().substr(0, 120),
		"provider": leaderboard_auth_provider,
		"refresh_token_present": not leaderboard_auth_refresh_token.is_empty(),
		"bound_uid_present": not leaderboard_auth_bound_uid.is_empty(),
		"bound_uid_fingerprint": _auth_uid_fingerprint(leaderboard_auth_bound_uid),
		"recovery_required": leaderboard_auth_recovery_required,
		"name_transfer_required": leaderboard_name_transfer_required,
		"legacy_username_recovery_required": leaderboard_legacy_username_recovery_required,
		"definitive_failure_code": leaderboard_auth_definitive_failure_code,
		"deleted_auth_transition_pending": leaderboard_deleted_auth_transition_pending
	})
	while leaderboard_auth_diagnostic_events.size() > 20:
		leaderboard_auth_diagnostic_events.pop_front()


func auth_diagnostics_for_support() -> Dictionary:
	return {
		"provider": leaderboard_auth_provider,
		"refresh_token_present": not leaderboard_auth_refresh_token.is_empty(),
		"bound_uid_present": not leaderboard_auth_bound_uid.is_empty(),
		"bound_uid_fingerprint": _auth_uid_fingerprint(leaderboard_auth_bound_uid),
		"recovery_required": leaderboard_auth_recovery_required,
		"definitive_failure_code": leaderboard_auth_definitive_failure_code,
		"name_transfer_required": leaderboard_name_transfer_required,
		"legacy_username_recovery_required": leaderboard_legacy_username_recovery_required,
		"deleted_auth_transition_pending": leaderboard_deleted_auth_transition_pending,
		"legacy_old_uid_fingerprint": _auth_uid_fingerprint(leaderboard_legacy_authless_old_uid),
		"last_error_class": leaderboard_auth_last_error_class,
		"last_uid_transition_outcome": leaderboard_auth_last_transition_outcome,
		"events": leaderboard_auth_diagnostic_events.duplicate(true)
	}


func account_recovery_code() -> String:
	if not (leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required):
		return ""
	var target_uid := LeaderboardProfile.sanitize_player_id(leaderboard_auth_bound_uid)
	var current_uid := LeaderboardProfile.sanitize_player_id(app.leaderboard_profile.player_id)
	var source_uid := LeaderboardProfile.sanitize_player_id(leaderboard_legacy_authless_old_uid)
	if target_uid.is_empty() or source_uid.is_empty() or target_uid != current_uid or target_uid == source_uid:
		return ""
	return "T-%s S-%s" % [_auth_uid_fingerprint(target_uid), _auth_uid_fingerprint(source_uid)]


func _save_identity_state(reason: String) -> bool:
	if not _save_restore_complete():
		return false
	app._mark_save_dirty(reason)
	return bool(app.save_game())


func _legacy_name_hint_valid() -> bool:
	var display_name := LeaderboardProfile.sanitize_display_name(leaderboard_legacy_name_hint_display, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
	var name_key := LeaderboardProfile.sanitize_name_key(leaderboard_legacy_name_hint_key, app.PROFILE_NAME_KEY_MAX_CHARS)
	return (
		not name_key.is_empty()
		and not LeaderboardProfile.is_guest_display_name(display_name, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
		and not LeaderboardProfile.is_default_display_name(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
		and LeaderboardProfile.make_name_key(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS) == name_key
	)


func _capture_current_profile_as_legacy_name_hint() -> void:
	var display_name := LeaderboardProfile.sanitize_display_name(app.leaderboard_profile.display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
	var name_key := LeaderboardProfile.sanitize_name_key(app.leaderboard_profile.name_key, app.PROFILE_NAME_KEY_MAX_CHARS)
	if (
		not name_key.is_empty()
		and not LeaderboardProfile.is_guest_display_name(display_name, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
		and not LeaderboardProfile.is_default_display_name(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
		and LeaderboardProfile.make_name_key(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS) == name_key
	):
		leaderboard_legacy_name_hint_display = display_name
		leaderboard_legacy_name_hint_key = name_key


func _local_save_has_player_progress() -> bool:
	if not _save_restore_complete():
		return false
	var payload: Dictionary = app._save_runtime()._save_payload(app._unix_now())
	return SaveStateNormalizers.progress_evidence_score(payload, app.skill_defs) > 0


func _legacy_authless_google_transition_eligible() -> bool:
	if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required:
		return IdentitySafety.is_local_placeholder_player_id(leaderboard_legacy_authless_old_uid)
	var base_identity_is_authless := IdentitySafety.legacy_authless_google_transition_allowed(
		app.leaderboard_profile.player_id,
		leaderboard_auth_refresh_token,
		leaderboard_auth_bound_uid,
		leaderboard_auth_provider
	)
	if not base_identity_is_authless:
		return false
	return (
		LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS)
		or _legacy_name_hint_valid()
		or _local_save_has_player_progress()
	)


func _deleted_auth_google_transition_eligible() -> bool:
	var player_uid := LeaderboardProfile.sanitize_player_id(app.leaderboard_profile.player_id)
	var bound_uid := LeaderboardProfile.sanitize_player_id(leaderboard_auth_bound_uid)
	if leaderboard_deleted_auth_transition_pending:
		return (
			(leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required)
			and not leaderboard_legacy_authless_old_uid.is_empty()
			and not IdentitySafety.is_local_placeholder_player_id(leaderboard_legacy_authless_old_uid)
			and IdentitySafety.deleted_uid_transition_failure_code_valid(leaderboard_auth_definitive_failure_code)
			and leaderboard_auth_provider == "google"
			and not leaderboard_auth_refresh_token.is_empty()
			and player_uid == bound_uid
			and player_uid != leaderboard_legacy_authless_old_uid
		)
	return (
		leaderboard_auth_recovery_required
		and IdentitySafety.deleted_uid_transition_failure_code_valid(leaderboard_auth_definitive_failure_code)
		and not leaderboard_auth_refresh_token.is_empty()
		and not player_uid.is_empty()
		and not IdentitySafety.is_local_placeholder_player_id(player_uid)
		and bound_uid == player_uid
	)


func profile_recovery_blocks_username_edit() -> bool:
	return profile_recovery_lookup_gate and not profile_recovery_lookup_conclusive_missing


func legacy_authless_google_transition_required() -> bool:
	return not leaderboard_name_transfer_required and not leaderboard_legacy_username_recovery_required and _legacy_authless_google_transition_eligible()


func deleted_auth_google_transition_required() -> bool:
	return not leaderboard_name_transfer_required and not leaderboard_legacy_username_recovery_required and _deleted_auth_google_transition_eligible()


func prepare_profile_recovery_on_open() -> void:
	ensure_leaderboard_http()
	if not _save_restore_complete() or leaderboard_name_transfer_required:
		return
	if not leaderboard_auth_recovery_required and LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		profile_recovery_lookup_gate = false
		return
	if not leaderboard_auth_recovery_required and profile_recovery_lookup_conclusive_missing:
		profile_recovery_lookup_gate = false
		return
	var player_uid := LeaderboardProfile.sanitize_player_id(app.leaderboard_profile.player_id)
	var has_prior_online_identity := (
		not leaderboard_auth_refresh_token.is_empty()
		or not leaderboard_auth_bound_uid.is_empty()
		or (not player_uid.is_empty() and not IdentitySafety.is_local_placeholder_player_id(player_uid))
	)
	if not has_prior_online_identity:
		profile_recovery_lookup_gate = false
		return
	profile_recovery_lookup_gate = true
	profile_recovery_lookup_conclusive_missing = false
	app.leaderboard_state.status_message = "Checking the saved username for this account..."
	if _leaderboard_auth_ready() or _recovery_profile_read_ready():
		_fetch_profile_recovery_record()
	else:
		_leaderboard_ensure_auth()


func _identity_has_prior_binding() -> bool:
	if not leaderboard_auth_bound_uid.is_empty() or not leaderboard_auth_refresh_token.is_empty():
		return true
	if leaderboard_auth_provider == "google" or app.leaderboard_profile.profile_claimed or not app.leaderboard_profile.name_key.is_empty():
		return true
	return not IdentitySafety.is_local_placeholder_player_id(app.leaderboard_profile.player_id)


func _anonymous_signup_allowed() -> bool:
	return not _identity_has_prior_binding() and not leaderboard_auth_recovery_required and not legacy_authless_google_transition_required()


func _set_auth_recovery_required(reason: String, definitive_failure_code := "") -> void:
	leaderboard_auth_id_token = ""
	leaderboard_auth_expires_unix = 0
	leaderboard_auth_recovery_pending_refresh_token = ""
	leaderboard_auth_recovery_required = true
	leaderboard_auth_recovery_reason = reason.strip_edges().substr(0, 120)
	var normalized_failure_code := IdentitySafety.refresh_failure_code(400, str(definitive_failure_code))
	if not normalized_failure_code.is_empty():
		leaderboard_auth_definitive_failure_code = normalized_failure_code
	leaderboard_auth_last_error_class = "definitive_identity_failure"
	if leaderboard_auth_last_transition_outcome != "blocked_uid_mismatch":
		leaderboard_auth_last_transition_outcome = "recovery_required"
	if leaderboard_auth_recovery_reason.is_empty():
		leaderboard_auth_recovery_reason = "Online identity needs recovery."
	app.leaderboard_state.status_message = "%s Sign in with Google to recover this account." % leaderboard_auth_recovery_reason
	google_auth_status_message = app.leaderboard_state.status_message
	if leaderboard_name_claim_in_flight and not leaderboard_name_claim_request_started:
		leaderboard_name_claim_in_flight = false
		leaderboard_name_claim_pending_name = ""
		leaderboard_name_claim_pending_key = ""
	_record_auth_diagnostic("recovery_required", leaderboard_auth_recovery_reason)
	_save_identity_state("online identity recovery required")
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func clear_chat_clock_guard_metadata() -> void:
	chat_last_send_unix = 0
	chat_stream_retry_unix = 0
	chat_stream_next_connect_unix = 0
	chat_status_message = ""


func chat_metadata_for_save(now_unix: int) -> Dictionary:
	return ChatState.metadata_for_save(self, now_unix, app.CHAT_STREAM_RETRY_INTERVAL_SECONDS)


func restore_chat_metadata_from_save(data: Dictionary) -> void:
	ChatState.restore_metadata_to_runtime(self, data, app._unix_now(), app.CHAT_STREAM_RETRY_INTERVAL_SECONDS)


func mark_cloud_save_dirty() -> void:
	cloud_save_dirty = true


func cloud_save_status_text() -> String:
	return _cloud_save_status_text()


func fetch_leaderboard_category(category_id: String) -> void:
	_leaderboard_fetch_category(category_id)


func submit_leaderboard_scores() -> void:
	_leaderboard_submit_scores()


func send_chat(raw_text: String) -> void:
	_chat_send(raw_text)


func mark_chat_opened_to_latest(save_now = false) -> void:
	_chat_mark_opened_to_latest(save_now)


func ensure_leaderboard_http() -> void:
	if leaderboard_http_built:
		return
	leaderboard_http_built = true
	_build_leaderboard_http()


func _build_leaderboard_http() -> void:
	leaderboard_auth_request = HTTPRequest.new()
	leaderboard_auth_request.timeout = 15.0
	leaderboard_auth_request.request_completed.connect(_on_leaderboard_auth_completed)
	add_child(leaderboard_auth_request)
	google_auth_exchange_request = HTTPRequest.new()
	google_auth_exchange_request.timeout = 15.0
	google_auth_exchange_request.request_completed.connect(_on_google_auth_exchange_completed)
	add_child(google_auth_exchange_request)
	cloud_save_fetch_request = HTTPRequest.new()
	cloud_save_fetch_request.timeout = 15.0
	cloud_save_fetch_request.request_completed.connect(_on_cloud_save_fetch_completed)
	add_child(cloud_save_fetch_request)
	cloud_save_upload_request = HTTPRequest.new()
	cloud_save_upload_request.timeout = 15.0
	cloud_save_upload_request.request_completed.connect(_on_cloud_save_upload_completed)
	add_child(cloud_save_upload_request)
	cloud_save_history_request = HTTPRequest.new()
	cloud_save_history_request.timeout = 15.0
	cloud_save_history_request.request_completed.connect(_on_cloud_save_history_completed)
	add_child(cloud_save_history_request)
	cloud_save_history_fetch_request = HTTPRequest.new()
	cloud_save_history_fetch_request.timeout = 15.0
	cloud_save_history_fetch_request.request_completed.connect(_on_cloud_save_history_fetch_completed)
	add_child(cloud_save_history_fetch_request)
	leaderboard_fetch_request = HTTPRequest.new()
	leaderboard_fetch_request.timeout = 15.0
	leaderboard_fetch_request.request_completed.connect(_on_leaderboard_fetch_completed)
	add_child(leaderboard_fetch_request)
	leaderboard_total_xp_fetch_request = HTTPRequest.new()
	leaderboard_total_xp_fetch_request.timeout = 15.0
	leaderboard_total_xp_fetch_request.request_completed.connect(_on_leaderboard_total_xp_fetch_completed)
	add_child(leaderboard_total_xp_fetch_request)
	leaderboard_submit_request = HTTPRequest.new()
	leaderboard_submit_request.timeout = 15.0
	leaderboard_submit_request.request_completed.connect(_on_leaderboard_submit_completed)
	add_child(leaderboard_submit_request)
	leaderboard_name_claim_request = HTTPRequest.new()
	leaderboard_name_claim_request.timeout = 15.0
	leaderboard_name_claim_request.request_completed.connect(_on_leaderboard_name_claim_completed)
	add_child(leaderboard_name_claim_request)
	leaderboard_name_recovery_request = HTTPRequest.new()
	leaderboard_name_recovery_request.timeout = 15.0
	leaderboard_name_recovery_request.request_completed.connect(_on_leaderboard_name_recovery_completed)
	add_child(leaderboard_name_recovery_request)
	profile_reference_update_request = HTTPRequest.new()
	profile_reference_update_request.timeout = 15.0
	profile_reference_update_request.request_completed.connect(_on_profile_reference_update_completed)
	add_child(profile_reference_update_request)
	profile_recovery_fetch_request = HTTPRequest.new()
	profile_recovery_fetch_request.timeout = 15.0
	profile_recovery_fetch_request.request_completed.connect(_on_profile_recovery_fetch_completed)
	add_child(profile_recovery_fetch_request)
	chat_stream_client = HTTPClient.new()
	chat_fetch_request = HTTPRequest.new()
	chat_fetch_request.timeout = 15.0
	chat_fetch_request.request_completed.connect(_on_chat_fetch_completed)
	add_child(chat_fetch_request)
	chat_send_request = HTTPRequest.new()
	chat_send_request.timeout = 15.0
	chat_send_request.request_completed.connect(_on_chat_send_completed)
	add_child(chat_send_request)
	chat_stream_poll_timer = Timer.new()
	chat_stream_poll_timer.wait_time = app.CHAT_STREAM_POLL_INTERVAL_SECONDS
	chat_stream_poll_timer.autostart = false
	chat_stream_poll_timer.timeout.connect(_process_chat_live_sync.bind(app.CHAT_STREAM_POLL_INTERVAL_SECONDS))
	add_child(chat_stream_poll_timer)


func _leaderboard_firebase_enabled() -> bool:
	if OS.get_environment(DISABLE_ONLINE_REQUESTS_ENV) == "1":
		return false
	return not _leaderboard_firebase_base_url().is_empty() and not _leaderboard_firebase_api_key().is_empty()


func _leaderboard_load_firebase_config() -> void:
	if leaderboard_config_loaded:
		return
	leaderboard_config_loaded = true
	if not FileAccess.file_exists(FIREBASE_LOCAL_CONFIG_PATH):
		return
	var file = FileAccess.open(FIREBASE_LOCAL_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = _parse_json_silent(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Online leaderboard config must be a JSON object.")
		return
	var firebase_config = parsed as Dictionary
	leaderboard_config_database_url = str(firebase_config.get("database_url", "")).strip_edges()
	leaderboard_config_web_api_key = str(firebase_config.get("web_api_key", "")).strip_edges()
	google_auth_web_client_id = str(firebase_config.get(GOOGLE_AUTH_WEB_CLIENT_ID_CONFIG_KEY, "")).strip_edges()


func _parse_json_silent(raw_text: String) -> Variant:
	var json := JSON.new()
	if json.parse(raw_text) != OK:
		return null
	return json.data


func _leaderboard_firebase_base_url() -> String:
	_leaderboard_load_firebase_config()
	return _firebase_sanitized_database_url(leaderboard_config_database_url, app.FIREBASE_DATABASE_URL)


func _leaderboard_firebase_api_key() -> String:
	_leaderboard_load_firebase_config()
	return _firebase_sanitized_api_key(leaderboard_config_web_api_key, app.FIREBASE_WEB_API_KEY)


func _firebase_sanitized_database_url(config_url: String, default_url: String) -> String:
	var url := config_url if not config_url.is_empty() else default_url.strip_edges()
	while url.ends_with("/"):
		url = url.substr(0, url.length() - 1)
	if url == FIREBASE_PLACEHOLDER_DATABASE_URL:
		return ""
	if not _leaderboard_database_url_allowed(url):
		return ""
	return url


func _firebase_sanitized_api_key(config_key: String, default_key: String) -> String:
	var key := config_key if not config_key.is_empty() else default_key.strip_edges()
	if key == FIREBASE_PLACEHOLDER_WEB_API_KEY:
		return ""
	if key.length() < 20 or key.find(" ") >= 0 or key.find("\t") >= 0 or key.find("\n") >= 0 or key.find("\r") >= 0:
		return ""
	return key


func _leaderboard_database_url_allowed(url: String) -> bool:
	if url.is_empty() or not url.begins_with(FIREBASE_URL_SCHEME):
		return false
	var host := url.substr(FIREBASE_URL_SCHEME.length()).to_lower()
	if host.is_empty() or host.find("/") >= 0 or host.find(":") >= 0:
		return false
	if host.find("your-project") >= 0 or host.find("your_project") >= 0:
		return false
	if host.ends_with(FIREBASE_US_HOST_SUFFIX):
		var database_name := host.substr(0, host.length() - FIREBASE_US_HOST_SUFFIX.length())
		return _leaderboard_firebase_host_label_allowed(database_name)
	if host.ends_with(FIREBASE_REGIONAL_HOST_SUFFIX):
		var database_and_region := host.substr(0, host.length() - FIREBASE_REGIONAL_HOST_SUFFIX.length())
		var separator := database_and_region.find(".")
		if separator <= 0 or separator >= database_and_region.length() - 1:
			return false
		return (
			_leaderboard_firebase_host_label_allowed(database_and_region.substr(0, separator))
			and _leaderboard_firebase_host_label_allowed(database_and_region.substr(separator + 1))
		)
	return false


func _leaderboard_firebase_host_label_allowed(value: String) -> bool:
	if value.is_empty() or value.begins_with("-") or value.ends_with("-"):
		return false
	for i in range(value.length()):
		if FIREBASE_HOST_CHARS.find(value.substr(i, 1)) < 0:
			return false
	return true


func _leaderboard_firebase_url(path = "", query = "") -> String:
	return _firebase_database_url(LEADERBOARD_FIREBASE_ROOT, path, query)


func _chat_firebase_url(path = "", query = "") -> String:
	return _firebase_database_url(CHAT_FIREBASE_ROOT, path, query)


func _cloud_save_firebase_url(path = "", query = "") -> String:
	return _firebase_database_url(CLOUD_SAVE_FIREBASE_ROOT, path, query)


func _firebase_database_url(root_path: String, path = "", query = "") -> String:
	var root := root_path.strip_edges()
	while root.begins_with("/"):
		root = root.substr(1)
	while root.ends_with("/"):
		root = root.substr(0, root.length() - 1)
	var clean_path := path.strip_edges()
	while clean_path.begins_with("/"):
		clean_path = clean_path.substr(1)
	var url := "%s/%s" % [_leaderboard_firebase_base_url(), root]
	if not clean_path.is_empty():
		url = "%s/%s" % [url, clean_path]
	url = "%s.json" % url
	if not query.is_empty():
		url = "%s?%s" % [url, query]
	return url


func _leaderboard_authenticated_query(query = "") -> String:
	if _leaderboard_web_authless_writes_enabled():
		return query
	var token = leaderboard_auth_id_token.strip_edges()
	if token.is_empty():
		return query
	var auth_param = "auth=%s" % token.uri_encode()
	if query.is_empty():
		return auth_param
	return "%s&%s" % [query, auth_param]


func _firebase_server_timestamp() -> Dictionary:
	return {".sv": "timestamp"}


func _leaderboard_web_authless_writes_enabled() -> bool:
	# Public reads remain available, but every mutation must be attributable to a
	# Firebase UID. Realtime Database rules cannot distinguish an itch client
	# from an arbitrary unauthenticated REST caller.
	return false


func _ensure_leaderboard_player_id() -> void:
	if app.leaderboard_profile.player_id.is_empty():
		app.leaderboard_profile.player_id = LeaderboardProfile.make_player_id()
		app._mark_save_dirty("leaderboard player id")


func _leaderboard_write_ready() -> bool:
	if _leaderboard_web_authless_writes_enabled():
		_ensure_leaderboard_player_id()
		return not app.leaderboard_profile.player_id.is_empty()
	return _leaderboard_ensure_auth()


func _leaderboard_category_key(category_id: String) -> String:
	return app.leaderboard_state.valid_category_id(category_id).replace(":", "__")


func _leaderboard_auth_ready() -> bool:
	var player_uid := LeaderboardProfile.sanitize_player_id(app.leaderboard_profile.player_id)
	var bound_uid := LeaderboardProfile.sanitize_player_id(leaderboard_auth_bound_uid)
	return (
		not leaderboard_auth_recovery_required
		and not leaderboard_auth_id_token.is_empty()
		and not player_uid.is_empty()
		and player_uid == bound_uid
		and leaderboard_auth_expires_unix > app._unix_now() + LEADERBOARD_AUTH_REFRESH_MARGIN_SECONDS
	)


func _recovery_refresh_allowed() -> bool:
	return IdentitySafety.recovery_refresh_allowed(
		leaderboard_auth_recovery_required,
		leaderboard_auth_refresh_token,
		LeaderboardProfile.sanitize_player_id(leaderboard_auth_bound_uid),
		LeaderboardProfile.sanitize_player_id(app.leaderboard_profile.player_id),
		leaderboard_auth_definitive_failure_code
	)


func _recovery_profile_verification_pending() -> bool:
	var player_uid := LeaderboardProfile.sanitize_player_id(app.leaderboard_profile.player_id)
	var bound_uid := LeaderboardProfile.sanitize_player_id(leaderboard_auth_bound_uid)
	return (
		leaderboard_auth_recovery_required
		and not leaderboard_auth_recovery_pending_refresh_token.is_empty()
		and not leaderboard_auth_id_token.is_empty()
		and not player_uid.is_empty()
		and player_uid == bound_uid
	)


func _recovery_profile_read_ready() -> bool:
	return (
		_recovery_profile_verification_pending()
		and leaderboard_auth_expires_unix > app._unix_now() + LEADERBOARD_AUTH_REFRESH_MARGIN_SECONDS
	)


func _leaderboard_auth_retry_wait_seconds() -> int:
	return maxi(0, leaderboard_auth_retry_after_unix - app._unix_now())


func _leaderboard_note_auth_failure(message: String, definitive_identity_failure = false, definitive_failure_code := "") -> void:
	var leaderboard_state = app.leaderboard_state
	if definitive_identity_failure:
		_set_auth_recovery_required(message, definitive_failure_code)
		if not google_auth_pending_id_token.is_empty():
			var recovery_intent: String = "deleted_auth_transition" if _deleted_auth_google_transition_eligible() else "recover_same_uid"
			_start_google_firebase_exchange(false, recovery_intent)
		return
	leaderboard_auth_last_error_class = "transient"
	_record_auth_diagnostic("auth_transient_failure", message)
	leaderboard_state.status_message = "%s Trying again in %s." % [message, GameFormatting.duration(float(LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS))]
	leaderboard_auth_retry_after_unix = app._unix_now() + LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS
	if _save_restore_complete():
		app._mark_save_dirty("leaderboard auth retry")


func _leaderboard_note_submit_failure(message: String) -> void:
	var leaderboard_state = app.leaderboard_state
	leaderboard_state.status_message = "%s Trying again in %s." % [message, GameFormatting.duration(float(LeaderboardState.SUBMIT_INTERVAL_SECONDS))]
	app.leaderboard_state.last_submit_unix = app._unix_now()
	app.leaderboard_state.last_submit_payload_categories.clear()
	app.leaderboard_state.pending_score_updates.clear()
	app.leaderboard_state.pending_repair_publish_version = 0
	leaderboard_submit_stage = ""
	app._mark_save_dirty("leaderboard submit retry")


func _leaderboard_note_fetch_failure(category_id: String, message: String) -> void:
	var leaderboard_state = app.leaderboard_state
	var valid_id = leaderboard_state.valid_category_id(category_id)
	leaderboard_state.fetch_retry_unix_by_category[valid_id] = app._unix_now()
	leaderboard_state.status_message = "%s Trying again in %s." % [message, GameFormatting.duration(float(LEADERBOARD_FETCH_INTERVAL_SECONDS))]
	app._mark_save_dirty("leaderboard fetch retry")


func _firebase_error_detail(body: PackedByteArray) -> String:
	var raw := body.get_string_from_utf8().strip_edges()
	if raw.is_empty():
		return ""
	var parsed = _parse_json_silent(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return raw.substr(0, 120)
	var error = (parsed as Dictionary).get("error", {})
	if typeof(error) == TYPE_DICTIONARY:
		var message := str((error as Dictionary).get("message", "")).strip_edges()
		if not message.is_empty():
			return message
	var data_message := str((parsed as Dictionary).get("message", "")).strip_edges()
	if not data_message.is_empty():
		return data_message
	return raw.substr(0, 120)


func _leaderboard_ensure_auth() -> bool:
	ensure_leaderboard_http()
	if not _leaderboard_firebase_enabled():
		app.leaderboard_state.status_message = "Online services are not connected yet."
		return false
	if _leaderboard_auth_ready():
		return true
	if not _save_restore_complete():
		app.leaderboard_state.status_message = "Online login is waiting for save recovery."
		return false
	if leaderboard_auth_recovery_required:
		if _recovery_profile_read_ready():
			var recovery_retry_wait := _leaderboard_auth_retry_wait_seconds()
			if recovery_retry_wait > 0:
				app.leaderboard_state.status_message = "Saved username verification is cooling down for %s." % GameFormatting.duration(float(recovery_retry_wait))
			else:
				_fetch_profile_recovery_record()
			return false
		if not _recovery_refresh_allowed():
			app.leaderboard_state.status_message = "%s Sign in with Google to recover this account." % leaderboard_auth_recovery_reason
			return false
	if leaderboard_auth_request == null or not is_instance_valid(leaderboard_auth_request):
		app.leaderboard_state.status_message = "Online login is still starting."
		return false
	if leaderboard_auth_in_flight:
		return false
	var retry_wait = _leaderboard_auth_retry_wait_seconds()
	if retry_wait > 0:
		app.leaderboard_state.status_message = "Online login is cooling down for %s." % GameFormatting.duration(float(retry_wait))
		return false
	var api_key = _leaderboard_firebase_api_key()
	if api_key.is_empty():
		app.leaderboard_state.status_message = "Online services are not connected yet."
		return false
	leaderboard_auth_in_flight = true
	if not leaderboard_auth_refresh_token.is_empty():
		leaderboard_auth_mode = "refresh_recovery" if leaderboard_auth_recovery_required else "refresh"
		app.leaderboard_state.status_message = "Verifying the saved online account..." if leaderboard_auth_recovery_required else "Refreshing leaderboard login..."
		var body = "grant_type=refresh_token&refresh_token=%s" % leaderboard_auth_refresh_token.uri_encode()
		var err = leaderboard_auth_request.request(
			FIREBASE_AUTH_REFRESH_URL % api_key.uri_encode(),
			PackedStringArray([LEADERBOARD_HTTP_HEADER_FORM, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_POST,
			body
		)
		if err == OK:
			return false
	else:
		if not _anonymous_signup_allowed():
			leaderboard_auth_in_flight = false
			leaderboard_auth_mode = ""
			_set_auth_recovery_required("The previous online login is missing.")
			return false
		leaderboard_auth_mode = "sign_up"
		app.leaderboard_state.status_message = "Creating leaderboard login..."
		var err = leaderboard_auth_request.request(
			FIREBASE_AUTH_SIGN_UP_URL % api_key.uri_encode(),
			PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_POST,
			JSON.stringify({"returnSecureToken": true})
		)
		if err == OK:
			return false
	leaderboard_auth_in_flight = false
	leaderboard_auth_mode = ""
	_leaderboard_note_auth_failure("Online login failed to start.")
	return false


func _leaderboard_retry_chat_auth_without_refresh() -> bool:
	if chat_pending_send_after_auth.is_empty() or leaderboard_auth_refresh_token.is_empty():
		return false
	_set_auth_recovery_required("The saved online login could not be verified.")
	app._profile_chat_overlay_surface()._render_chat_if_visible()
	return false


func _google_auth_available() -> bool:
	_ensure_google_auth_plugin()
	return google_auth_plugin != null and is_instance_valid(google_auth_plugin) and google_auth_plugin.has_method("sign_in")


func _ensure_google_auth_plugin() -> void:
	if google_auth_plugin != null and is_instance_valid(google_auth_plugin):
		return
	if OS.get_name() != "Android":
		return
	if not Engine.has_singleton(GOOGLE_AUTH_ANDROID_SINGLETON):
		return
	google_auth_plugin = Engine.get_singleton(GOOGLE_AUTH_ANDROID_SINGLETON)
	if google_auth_plugin == null or google_auth_plugin_connected:
		return
	if google_auth_plugin.has_signal("google_sign_in_succeeded"):
		google_auth_plugin.connect("google_sign_in_succeeded", _on_google_sign_in_succeeded)
	if google_auth_plugin.has_signal("google_sign_in_failed"):
		google_auth_plugin.connect("google_sign_in_failed", _on_google_sign_in_failed)
	google_auth_plugin_connected = true


func _start_google_account_sign_in() -> void:
	ensure_leaderboard_http()
	if google_auth_in_flight or leaderboard_auth_in_flight:
		return
	if not _leaderboard_firebase_enabled():
		google_auth_status_message = "Online services are not connected yet."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if google_auth_web_client_id.is_empty():
		google_auth_status_message = "Google sign-in needs google_web_client_id in firebase-leaderboard-config.json."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not _save_restore_complete():
		google_auth_status_message = "Google sign-in is waiting for save recovery."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not _google_auth_available():
		google_auth_status_message = "Google sign-in is not available in this build yet."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	google_auth_in_flight = true
	google_auth_status_message = "Opening Google sign-in..."
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
	var err = OK
	if google_auth_plugin.has_method("sign_in_with_client_id"):
		err = int(google_auth_plugin.call("sign_in_with_client_id", google_auth_web_client_id))
	else:
		err = int(google_auth_plugin.call("sign_in"))
	if err != OK:
		google_auth_in_flight = false
		google_auth_status_message = "Google sign-in failed to start: %s" % error_string(err)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_google_sign_in_succeeded(id_token: String, account_email = "", display_name = "") -> void:
	google_auth_in_flight = false
	var clean_token = id_token.strip_edges()
	if clean_token.is_empty():
		google_auth_status_message = "Google sign-in returned an empty token."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	google_auth_pending_id_token = clean_token
	google_auth_pending_email = str(account_email).strip_edges()
	google_auth_pending_display_name = str(display_name).strip_edges()
	_exchange_google_id_token_for_firebase(clean_token, account_email, display_name)


func _on_google_sign_in_failed(message = "") -> void:
	google_auth_in_flight = false
	_clear_pending_google_credential()
	var detail = str(message).strip_edges()
	google_auth_status_message = _friendly_google_auth_failure_message(detail)
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _friendly_google_auth_failure_message(detail: String) -> String:
	var clean_detail = detail.strip_edges()
	if clean_detail.is_empty():
		return "Google sign-in was cancelled."
	var lower_detail = clean_detail.to_lower()
	if lower_detail.contains("cancel") or lower_detail.contains("canceled") or lower_detail.contains("cancelled"):
		return "Google sign-in was cancelled."
	if lower_detail.contains("no credentials") or lower_detail.contains("no credential"):
		return "No Google account was selected. Try Connect Google again."
	if lower_detail.contains("network") or lower_detail.contains("timeout"):
		return "Google sign-in needs an internet connection. Try again in a moment."
	return "Google sign-in failed: %s" % clean_detail


func _exchange_google_id_token_for_firebase(google_id_token: String, account_email = "", display_name = "") -> void:
	if google_auth_exchange_request == null or not is_instance_valid(google_auth_exchange_request):
		google_auth_status_message = "Online login is still starting."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	google_auth_pending_id_token = google_id_token.strip_edges()
	google_auth_pending_email = str(account_email).strip_edges()
	google_auth_pending_display_name = str(display_name).strip_edges()
	var intent := "fresh_sign_in"
	if _legacy_authless_google_transition_eligible():
		intent = "legacy_authless_transition"
	elif _deleted_auth_google_transition_eligible():
		intent = "deleted_auth_transition"
	elif leaderboard_auth_recovery_required:
		intent = "recover_same_uid"
	elif _identity_has_prior_binding():
		intent = "link_same_uid"
	google_auth_exchange_intent = intent
	if intent == "link_same_uid" and not _leaderboard_auth_ready():
		google_auth_status_message = "Refreshing the current account before linking Google..."
		_leaderboard_ensure_auth()
		if leaderboard_auth_recovery_required:
			google_auth_exchange_intent = "recover_same_uid"
			_start_google_firebase_exchange(false, "recover_same_uid")
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	_start_google_firebase_exchange(intent == "link_same_uid", intent)


func _start_google_firebase_exchange(link_existing_identity: bool, requested_intent := "") -> void:
	var api_key = _leaderboard_firebase_api_key()
	if api_key.is_empty() or google_auth_pending_id_token.is_empty():
		google_auth_status_message = "Online services are not connected yet."
		_clear_pending_google_credential()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var intent := str(requested_intent).strip_edges()
	if intent.is_empty():
		intent = "link_same_uid" if link_existing_identity else ("recover_same_uid" if leaderboard_auth_recovery_required else "fresh_sign_in")
	google_auth_exchange_intent = intent
	leaderboard_auth_in_flight = true
	match intent:
		"link_same_uid":
			leaderboard_auth_mode = "google_link"
		"recover_same_uid":
			leaderboard_auth_mode = "google_recover"
		"legacy_authless_transition":
			leaderboard_auth_mode = "google_legacy_authless_transition"
		"deleted_auth_transition":
			leaderboard_auth_mode = "google_deleted_auth_transition"
		_:
			leaderboard_auth_mode = "google_fresh_sign_in"
	google_auth_exchange_was_link = link_existing_identity
	google_auth_status_message = "Connecting Google account..." if link_existing_identity else "Signing in with Google..."
	var body = {
		"postBody": "id_token=%s&providerId=%s" % [google_auth_pending_id_token.uri_encode(), GOOGLE_AUTH_PROVIDER_ID.uri_encode()],
		"requestUri": GOOGLE_AUTH_REQUEST_URI,
		"returnIdpCredential": true,
		"returnSecureToken": true
	}
	if intent == "recover_same_uid":
		# Recovery must never create a different Firebase account merely because
		# the wrong Google account was selected.
		body["autoCreate"] = false
	if link_existing_identity and not leaderboard_auth_id_token.strip_edges().is_empty():
		body["idToken"] = leaderboard_auth_id_token.strip_edges()
	var err = google_auth_exchange_request.request(
		FIREBASE_AUTH_SIGN_IN_WITH_IDP_URL % api_key.uri_encode(),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	if err != OK:
		leaderboard_auth_in_flight = false
		leaderboard_auth_mode = ""
		google_auth_status_message = "Google account link failed to start: %s" % error_string(err)
		_clear_pending_google_credential()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not google_auth_pending_email.is_empty():
		cloud_save_status_message = "Signing in as %s" % google_auth_pending_email
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_google_auth_exchange_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var exchange_mode := leaderboard_auth_mode
	leaderboard_auth_in_flight = false
	leaderboard_auth_mode = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		google_auth_status_message = "Google account login failed."
		_clear_pending_google_credential()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if response_code < 200 or response_code >= 300:
		var detail = _firebase_error_detail(body)
		if exchange_mode == "google_link" and IdentitySafety.google_link_collision(detail):
			google_auth_status_message = "This Google account belongs to another game profile. The current profile was not changed."
			_clear_pending_google_credential()
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
			return
		google_auth_status_message = "Google account login returned HTTP %s%s" % [response_code, "." if detail.is_empty() else ": %s" % detail]
		_clear_pending_google_credential()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		google_auth_status_message = "Google account login returned invalid JSON."
		_clear_pending_google_credential()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not _apply_firebase_auth_response(parsed as Dictionary, "google", exchange_mode):
		_clear_pending_google_credential()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	_clear_pending_google_credential()
	if leaderboard_name_transfer_required:
		google_auth_status_message = "Google connected. Username transfer needs support approval."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	google_auth_status_message = "Google connected. Username recovery needs support." if leaderboard_legacy_username_recovery_required else "Google account connected."
	mark_cloud_save_dirty()
	_fetch_profile_recovery_record()
	if profile_recovery_blocks_username_edit():
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	_fetch_cloud_save()
	if app.leaderboard_state.submit_ready():
		_leaderboard_submit_scores()
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _clear_pending_google_credential() -> void:
	google_auth_pending_id_token = ""
	google_auth_pending_email = ""
	google_auth_pending_display_name = ""
	google_auth_exchange_was_link = false
	google_auth_exchange_intent = ""


func _apply_firebase_auth_response(data: Dictionary, provider: String, transition_mode = "") -> bool:
	var id_token = str(data.get("idToken", data.get("id_token", "")))
	var refresh_token = str(data.get("refreshToken", data.get("refresh_token", "")))
	var local_id = LeaderboardProfile.sanitize_player_id(str(data.get("localId", data.get("user_id", ""))))
	var expires_in = maxi(0, int(data.get("expiresIn", data.get("expires_in", 0))))
	if id_token.is_empty() or refresh_token.is_empty() or local_id.is_empty() or expires_in <= 0:
		_leaderboard_note_auth_failure("Online login was incomplete.")
		return false
	var mode := str(transition_mode)
	if mode.is_empty():
		mode = "google_sign_in" if provider == "google" else "refresh"
	var current_uid := LeaderboardProfile.sanitize_player_id(app.leaderboard_profile.player_id)
	var expected_uid := LeaderboardProfile.sanitize_player_id(leaderboard_auth_bound_uid)
	if expected_uid.is_empty() and _identity_has_prior_binding():
		expected_uid = current_uid
	var recovery_refresh: bool = mode == "refresh_recovery"
	var uid_transition_allowed := false
	match mode:
		"sign_up":
			uid_transition_allowed = _anonymous_signup_allowed() and IdentitySafety.is_local_placeholder_player_id(current_uid)
		"refresh", "google_link", "google_recover":
			uid_transition_allowed = not expected_uid.is_empty() and local_id == expected_uid
		"refresh_recovery":
			uid_transition_allowed = IdentitySafety.recovery_refresh_response_matches_binding(local_id, expected_uid, current_uid)
		"google_fresh_sign_in":
			uid_transition_allowed = _anonymous_signup_allowed() and IdentitySafety.is_local_placeholder_player_id(current_uid)
		"google_legacy_authless_transition":
			var legacy_transition_already_started: bool = leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required
			var legacy_source_uid: String = leaderboard_legacy_authless_old_uid if legacy_transition_already_started else current_uid
			uid_transition_allowed = _legacy_authless_google_transition_eligible() and local_id != legacy_source_uid
		"google_deleted_auth_transition":
			var deleted_source_uid: String = leaderboard_legacy_authless_old_uid if leaderboard_deleted_auth_transition_pending else current_uid
			uid_transition_allowed = _deleted_auth_google_transition_eligible() and local_id != deleted_source_uid
		"google_sign_in":
			# Compatibility for direct tests/older callers: only a genuinely fresh
			# install may accept an arbitrary Google UID.
			uid_transition_allowed = (
				(_anonymous_signup_allowed() and IdentitySafety.is_local_placeholder_player_id(current_uid))
				or (not expected_uid.is_empty() and local_id == expected_uid)
			)
		_:
			uid_transition_allowed = not expected_uid.is_empty() and local_id == expected_uid
	if not uid_transition_allowed:
		leaderboard_auth_last_transition_outcome = "blocked_uid_mismatch"
		_record_auth_diagnostic("uid_transition_blocked", "%s:%s" % [mode, _auth_uid_fingerprint(local_id)])
		_set_auth_recovery_required("Online login returned a different account id.")
		return false
	var legacy_authless_transition: bool = mode == "google_legacy_authless_transition"
	var deleted_auth_transition: bool = mode == "google_deleted_auth_transition"
	var protected_identity_transition: bool = legacy_authless_transition or deleted_auth_transition
	var fresh_google_identity: bool = mode in ["google_fresh_sign_in", "google_sign_in", "google_legacy_authless_transition", "google_deleted_auth_transition"] and current_uid != local_id
	var previous_auth_state: Dictionary = {
		"id_token": leaderboard_auth_id_token,
		"refresh_token": leaderboard_auth_refresh_token,
		"expires_unix": leaderboard_auth_expires_unix,
		"retry_after_unix": leaderboard_auth_retry_after_unix,
		"provider": leaderboard_auth_provider,
		"bound_uid": leaderboard_auth_bound_uid,
		"recovery_required": leaderboard_auth_recovery_required,
		"recovery_reason": leaderboard_auth_recovery_reason,
		"definitive_failure_code": leaderboard_auth_definitive_failure_code,
		"recovery_pending_refresh_token": leaderboard_auth_recovery_pending_refresh_token,
		"last_error_class": leaderboard_auth_last_error_class,
		"last_transition_outcome": leaderboard_auth_last_transition_outcome,
		"player_id": current_uid,
		"legacy_old_uid": leaderboard_legacy_authless_old_uid,
		"deleted_auth_transition_pending": leaderboard_deleted_auth_transition_pending,
		"name_transfer_required": leaderboard_name_transfer_required,
		"legacy_username_recovery_required": leaderboard_legacy_username_recovery_required,
		"legacy_name_hint_display": leaderboard_legacy_name_hint_display,
		"legacy_name_hint_key": leaderboard_legacy_name_hint_key,
		"profile_recovery_lookup_gate": profile_recovery_lookup_gate,
		"profile_recovery_lookup_conclusive_missing": profile_recovery_lookup_conclusive_missing
	}
	if fresh_google_identity:
		reset_cloud_save_state()
	leaderboard_auth_id_token = id_token
	if recovery_refresh:
		leaderboard_auth_recovery_pending_refresh_token = refresh_token
	else:
		leaderboard_auth_refresh_token = refresh_token
		leaderboard_auth_recovery_pending_refresh_token = ""
	leaderboard_auth_expires_unix = app._unix_now() + expires_in
	leaderboard_auth_retry_after_unix = 0
	if recovery_refresh:
		leaderboard_auth_last_error_class = "recovery_verification_pending"
	else:
		leaderboard_auth_provider = provider if not provider.is_empty() else "anonymous"
		leaderboard_auth_bound_uid = local_id
		leaderboard_auth_recovery_required = false
		leaderboard_auth_recovery_reason = ""
		if not deleted_auth_transition:
			leaderboard_auth_definitive_failure_code = ""
		leaderboard_auth_last_error_class = "none"
	if protected_identity_transition:
		if leaderboard_legacy_authless_old_uid.is_empty():
			leaderboard_legacy_authless_old_uid = current_uid
		if not leaderboard_name_transfer_required and not leaderboard_legacy_username_recovery_required:
			if not _legacy_name_hint_valid():
				_capture_current_profile_as_legacy_name_hint()
			leaderboard_name_transfer_required = _legacy_name_hint_valid()
			leaderboard_legacy_username_recovery_required = not leaderboard_name_transfer_required
		leaderboard_deleted_auth_transition_pending = deleted_auth_transition
	if recovery_refresh:
		leaderboard_auth_last_transition_outcome = "refresh_recovery_pending_profile"
	elif deleted_auth_transition:
		leaderboard_auth_last_transition_outcome = "deleted_auth_google_pending_recovery"
	elif legacy_authless_transition:
		leaderboard_auth_last_transition_outcome = "legacy_authless_google_pending_recovery"
	elif fresh_google_identity:
		leaderboard_auth_last_transition_outcome = "fresh_google_identity"
	else:
		leaderboard_auth_last_transition_outcome = "%s_same_identity" % mode
	app.leaderboard_profile.player_id = local_id
	if recovery_refresh:
		profile_recovery_lookup_gate = true
		profile_recovery_lookup_conclusive_missing = false
	elif (not protected_identity_transition or leaderboard_legacy_username_recovery_required) and mode != "sign_up" and not LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		profile_recovery_lookup_gate = true
		profile_recovery_lookup_conclusive_missing = false
	if recovery_refresh:
		app.leaderboard_state.status_message = "Verifying the saved username for this account..."
	elif leaderboard_name_transfer_required:
		app.leaderboard_state.status_message = "Username transfer needs support approval."
	elif leaderboard_legacy_username_recovery_required:
		app.leaderboard_state.status_message = "Google connected. Username recovery needs support."
	else:
		app.leaderboard_state.status_message = "Online login ready."
	_record_auth_diagnostic("auth_applied", leaderboard_auth_last_transition_outcome)
	if protected_identity_transition:
		# Persist the preserved source id and pending-transfer marker atomically
		# with the Google UID before any server profile operation is allowed.
		app._save_runtime().allow_next_identity_transition_save(current_uid, local_id)
		if not _save_identity_state("deleted account Google transition" if deleted_auth_transition else "legacy authless Google transition"):
			leaderboard_auth_id_token = str(previous_auth_state.get("id_token", ""))
			leaderboard_auth_refresh_token = str(previous_auth_state.get("refresh_token", ""))
			leaderboard_auth_expires_unix = int(previous_auth_state.get("expires_unix", 0))
			leaderboard_auth_retry_after_unix = int(previous_auth_state.get("retry_after_unix", 0))
			leaderboard_auth_provider = str(previous_auth_state.get("provider", "anonymous"))
			leaderboard_auth_bound_uid = str(previous_auth_state.get("bound_uid", ""))
			leaderboard_auth_recovery_required = bool(previous_auth_state.get("recovery_required", false))
			leaderboard_auth_recovery_reason = str(previous_auth_state.get("recovery_reason", ""))
			leaderboard_auth_definitive_failure_code = str(previous_auth_state.get("definitive_failure_code", ""))
			leaderboard_auth_recovery_pending_refresh_token = str(previous_auth_state.get("recovery_pending_refresh_token", ""))
			leaderboard_auth_last_error_class = "local_save_failure"
			leaderboard_auth_last_transition_outcome = "deleted_auth_transition_not_saved" if deleted_auth_transition else "legacy_authless_transition_not_saved"
			leaderboard_legacy_authless_old_uid = str(previous_auth_state.get("legacy_old_uid", ""))
			leaderboard_deleted_auth_transition_pending = bool(previous_auth_state.get("deleted_auth_transition_pending", false))
			leaderboard_name_transfer_required = bool(previous_auth_state.get("name_transfer_required", false))
			leaderboard_legacy_username_recovery_required = bool(previous_auth_state.get("legacy_username_recovery_required", false))
			leaderboard_legacy_name_hint_display = str(previous_auth_state.get("legacy_name_hint_display", ""))
			leaderboard_legacy_name_hint_key = str(previous_auth_state.get("legacy_name_hint_key", ""))
			profile_recovery_lookup_gate = bool(previous_auth_state.get("profile_recovery_lookup_gate", false))
			profile_recovery_lookup_conclusive_missing = bool(previous_auth_state.get("profile_recovery_lookup_conclusive_missing", false))
			app.leaderboard_profile.player_id = str(previous_auth_state.get("player_id", ""))
			app.leaderboard_state.status_message = "Google account was not applied because the local save failed."
			google_auth_status_message = app.leaderboard_state.status_message
			_record_auth_diagnostic("identity_transition_save_failed")
			app._save_runtime().cancel_next_identity_transition_save()
			return false
	else:
		_save_identity_state("online identity authenticated")
	return true


func _cloud_save_account_ready() -> bool:
	return (
		_save_restore_complete()
		and _leaderboard_auth_ready()
		and leaderboard_auth_provider == "google"
		and not leaderboard_name_transfer_required
		and (
			not leaderboard_deleted_auth_transition_pending
			or (
				leaderboard_legacy_username_recovery_required
				and IdentitySafety.deleted_uid_transition_failure_code_valid(leaderboard_auth_definitive_failure_code)
			)
		)
	)


func _cloud_save_status_text() -> String:
	if not _leaderboard_firebase_enabled():
		return "Cloud save is offline until Firebase is configured."
	if leaderboard_auth_recovery_required:
		return "Sign in with Google to recover cloud saves for this account."
	if leaderboard_name_transfer_required:
		return "Cloud save is paused until the username transfer is approved."
	if leaderboard_deleted_auth_transition_pending:
		return "Progress backup is active. Username recovery still needs support." if leaderboard_legacy_username_recovery_required and IdentitySafety.deleted_uid_transition_failure_code_valid(leaderboard_auth_definitive_failure_code) else "Cloud save is paused until account recovery is reviewed."
	if leaderboard_auth_provider != "google":
		if google_auth_status_message.is_empty():
			return "Connect Google to back up progress to your account."
		return google_auth_status_message
	if cloud_save_upload_in_flight:
		return "Uploading cloud save..."
	if cloud_save_fetch_in_flight:
		return "Checking cloud save..."
	if not cloud_save_status_message.is_empty():
		return cloud_save_status_message
	return "Google connected. Progress saves to your account automatically."


func _cloud_save_summary(payload: Dictionary) -> Dictionary:
	return {
		"save_schema_version": int(payload.get("save_schema_version", 0)),
		"saved_at": maxi(0, int(payload.get("saved_at", 0))),
		"total_skill_xp": app._save_runtime()._save_total_skill_xp_evidence(payload),
		"total_level": SkillState.global_level(app.skills)
	}


func _cloud_save_payload_json(payload: Dictionary) -> String:
	var safe_payload = IdentitySafety.cloud_safe_payload(payload)
	if typeof(safe_payload) != TYPE_DICTIONARY:
		return ""
	var text := JSON.stringify(safe_payload)
	if text.length() > CLOUD_SAVE_MAX_PAYLOAD_CHARS:
		return ""
	return text


func _cloud_save_record(payload: Dictionary, now: int, revision = -1) -> Dictionary:
	var payload_json := _cloud_save_payload_json(payload)
	var next_revision := maxi(1, int(revision) if int(revision) >= 0 else cloud_save_remote_revision + 1)
	return {
		"uid": app.leaderboard_profile.player_id,
		"updated_at": _firebase_server_timestamp(),
		"updated_at_unix": now,
		"save_schema_version": int(payload.get("save_schema_version", SaveRuntime.SAVE_SCHEMA_VERSION)),
		"saved_at": maxi(0, int(payload.get("saved_at", now))),
		"total_skill_xp": app._save_runtime()._save_total_skill_xp_evidence(payload),
		"total_level": SkillState.global_level(app.skills),
		"revision": next_revision,
		"payload_checksum": IdentitySafety.payload_checksum(payload_json),
		"payload_json": payload_json
	}


func _cloud_save_payload_from_record(record: Dictionary, allow_legacy_checksum := false) -> Dictionary:
	if LeaderboardProfile.sanitize_player_id(str(record.get("uid", ""))) != app.leaderboard_profile.player_id:
		return {}
	var payload_text := str(record.get("payload_json", ""))
	if payload_text.is_empty() or payload_text.length() > CLOUD_SAVE_MAX_PAYLOAD_CHARS:
		return {}
	var has_revision := record.has("revision") and int(record.get("revision", 0)) > 0
	if not IdentitySafety.checksum_matches(
		payload_text,
		str(record.get("payload_checksum", "")),
		allow_legacy_checksum and not has_revision
	):
		return {}
	var parsed = _parse_json_silent(payload_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var safe_payload = IdentitySafety.cloud_safe_payload(parsed)
	if typeof(safe_payload) != TYPE_DICTIONARY:
		return {}
	var payload := safe_payload as Dictionary
	var schema_value = payload.get("save_schema_version", 0)
	var record_schema_value = record.get("save_schema_version", null)
	if typeof(schema_value) not in [TYPE_INT, TYPE_FLOAT] or typeof(record_schema_value) not in [TYPE_INT, TYPE_FLOAT]:
		return {}
	var schema_version := int(schema_value)
	var record_schema_version := int(record_schema_value)
	if record_schema_version != schema_version:
		return {}
	if schema_version < 0 or schema_version > SaveRuntime.SAVE_SCHEMA_VERSION:
		return {}
	if not SaveRuntime._payload_semantic_error(payload, schema_version).is_empty():
		return {}
	var migrated_payload: Dictionary = app._save_runtime()._migrate_save_to_current_schema(payload)
	if migrated_payload.is_empty():
		return {}
	return migrated_payload


func _cloud_save_archival_record(record: Dictionary, payload: Dictionary) -> Dictionary:
	var payload_json := _cloud_save_payload_json(payload)
	if payload_json.is_empty():
		return {}
	var now_unix: int = app._unix_now()
	return {
		"uid": app.leaderboard_profile.player_id,
		"updated_at": _firebase_server_timestamp(),
		"updated_at_unix": now_unix,
		"save_schema_version": maxi(1, int(payload.get("save_schema_version", SaveRuntime.SAVE_SCHEMA_VERSION))),
		"saved_at": maxi(1, int(record.get("saved_at", payload.get("saved_at", now_unix)))),
		"total_skill_xp": app._save_runtime()._save_total_skill_xp_evidence(payload),
		"total_level": maxi(0, int(record.get("total_level", 0))),
		"revision": maxi(1, int(record.get("revision", 0))),
		"payload_checksum": IdentitySafety.payload_checksum(payload_json),
		"payload_json": payload_json
	}


func _cloud_save_payload_conflicts_with_local(remote_payload: Dictionary) -> bool:
	var local_payload: Dictionary = app._save_runtime()._save_payload(app._unix_now())
	var comparison_payload: Dictionary = IdentitySafety.payload_with_preserved_identity_for_comparison(remote_payload, local_payload)
	return (
		SaveStateNormalizers.payload_regresses_game_progress(local_payload, comparison_payload, app.skill_defs)
		and SaveStateNormalizers.payload_regresses_game_progress(comparison_payload, local_payload, app.skill_defs)
	)


func _apply_cloud_save_candidate(remote_payload: Dictionary, revision: int, source_label := "cloud") -> void:
	cloud_save_last_remote_payload = remote_payload.duplicate(true)
	cloud_save_last_remote_summary = _cloud_save_summary(cloud_save_last_remote_payload)
	cloud_save_last_remote_summary["revision"] = maxi(0, revision)
	cloud_save_remote_revision = maxi(0, revision)
	cloud_save_remote_checked = true
	_maybe_recover_profile_from_legacy_cloud_payload(cloud_save_last_remote_payload)
	if _cloud_save_payload_conflicts_with_local(cloud_save_last_remote_payload):
		cloud_save_conflict_detected = true
		cloud_save_dirty = true
		cloud_save_status_message = "Cloud and device progress both contain unique changes. Neither save was overwritten."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	cloud_save_conflict_detected = false
	var remote_xp := int(cloud_save_last_remote_summary.get("total_skill_xp", 0))
	var local_xp: int = int(app._save_runtime()._save_total_skill_xp_evidence(app._save_runtime()._save_payload(app._unix_now())))
	if _cloud_save_payload_should_replace_local(cloud_save_last_remote_payload):
		cloud_save_dirty = false
		_restore_cloud_save_payload(cloud_save_last_remote_payload)
		cloud_save_status_message = "%s save restored. Remote XP: %s." % ["Backup" if source_label == "history" else "Cloud", GameFormatting.compact_number(float(remote_xp), 4)]
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if cloud_save_dirty:
		_upload_cloud_save(false)
	cloud_save_status_message = "%s save found. Remote XP: %s. This device XP: %s." % ["Backup" if source_label == "history" else "Cloud", GameFormatting.compact_number(float(remote_xp), 4), GameFormatting.compact_number(float(local_xp), 4)]
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _firebase_response_etag(headers: PackedStringArray) -> String:
	for raw_header in headers:
		var header := str(raw_header).strip_edges()
		var separator := header.find(":")
		if separator <= 0:
			continue
		if header.substr(0, separator).strip_edges().to_lower() == "etag":
			return header.substr(separator + 1).strip_edges()
	return ""


func _fetch_cloud_save() -> void:
	ensure_leaderboard_http()
	if cloud_save_fetch_in_flight:
		return
	if not _save_restore_complete():
		cloud_save_status_message = "Cloud save is waiting for local save recovery."
		return
	if not _cloud_save_account_ready():
		cloud_save_status_message = "Connect Google before checking cloud save."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	cloud_save_fetch_in_flight = true
	cloud_save_status_message = "Checking cloud save..."
	var err = cloud_save_fetch_request.request(
		_cloud_save_firebase_url("users/%s" % app.leaderboard_profile.player_id, _leaderboard_authenticated_query()),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_ACCEPT_JSON, FIREBASE_ETAG_REQUEST_HEADER]),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		cloud_save_fetch_in_flight = false
		cloud_save_status_message = "Cloud save check failed: %s" % error_string(err)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _upload_cloud_save(force = true) -> void:
	ensure_leaderboard_http()
	if not _save_restore_complete():
		return
	if cloud_save_fetch_in_flight:
		return
	if cloud_save_upload_in_flight:
		return
	if cloud_save_history_in_flight:
		return
	if cloud_save_remote_write_blocked:
		cloud_save_status_message = "The current cloud save is invalid. It was not overwritten."
		return
	if cloud_save_conflict_detected:
		cloud_save_status_message = "Cloud and device progress both contain unique changes. Neither save was overwritten."
		return
	if not _cloud_save_account_ready():
		if force:
			cloud_save_status_message = "Connect Google before uploading cloud save."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not cloud_save_remote_checked:
		_fetch_cloud_save()
		return
	var now = app._unix_now()
	if not force and cloud_save_last_upload_unix > 0 and now - cloud_save_last_upload_unix < CLOUD_SAVE_UPLOAD_INTERVAL_SECONDS:
		return
	var payload = app._save_runtime()._save_payload(now)
	var record = _cloud_save_record(payload, now)
	if str(record.get("payload_json", "")).is_empty():
		cloud_save_status_message = "Cloud save is too large to upload."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	cloud_save_upload_in_flight = true
	cloud_save_dirty = false
	cloud_save_pending_record = record.duplicate(true)
	if not cloud_save_last_remote_record.is_empty() and not cloud_save_last_remote_record_archived:
		cloud_save_status_message = "Protecting the previous cloud save before upload..."
		if _upload_cloud_save_history(cloud_save_last_remote_record, "before_replace"):
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
			return
		cloud_save_upload_in_flight = false
		cloud_save_dirty = true
		cloud_save_pending_record.clear()
		cloud_save_status_message = "The previous cloud save could not be protected, so it was not overwritten."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	_start_cloud_save_put()


func _start_cloud_save_put() -> void:
	if cloud_save_pending_record.is_empty() or not _cloud_save_account_ready():
		cloud_save_upload_in_flight = false
		cloud_save_dirty = true
		cloud_save_pending_record.clear()
		cloud_save_status_message = "Cloud save upload was stopped before replacing the previous save."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	cloud_save_status_message = "Uploading cloud save..."
	var expected_etag := cloud_save_remote_etag if not cloud_save_remote_etag.is_empty() else "null_etag"
	var err = cloud_save_upload_request.request(
		_cloud_save_firebase_url("users/%s" % app.leaderboard_profile.player_id, _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON, FIREBASE_ETAG_REQUEST_HEADER, "if-match: %s" % expected_etag]),
		HTTPClient.METHOD_PUT,
		JSON.stringify(cloud_save_pending_record)
	)
	if err != OK:
		cloud_save_upload_in_flight = false
		cloud_save_dirty = true
		cloud_save_pending_record.clear()
		cloud_save_status_message = "Cloud save upload failed: %s" % error_string(err)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_cloud_save_fetch_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	cloud_save_fetch_in_flight = false
	cloud_save_last_fetch_unix = app._unix_now()
	if result != HTTPRequest.RESULT_SUCCESS:
		cloud_save_status_message = "Cloud save check failed."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	cloud_save_remote_etag = _firebase_response_etag(headers)
	if cloud_save_remote_etag.is_empty() and (response_code == 404 or body.get_string_from_utf8().strip_edges() == "null"):
		cloud_save_remote_etag = "null_etag"
	if response_code == 404:
		cloud_save_remote_revision = 0
		_handle_missing_current_cloud_save()
		return
	if response_code < 200 or response_code >= 300:
		cloud_save_status_message = "Cloud save check returned HTTP %s." % response_code
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	if parsed == null:
		if cloud_save_remote_etag.is_empty():
			cloud_save_remote_etag = "null_etag"
		cloud_save_remote_revision = 0
		_handle_missing_current_cloud_save()
		return
	if typeof(parsed) != TYPE_DICTIONARY:
		cloud_save_remote_revision = 0
		cloud_save_last_remote_record.clear()
		cloud_save_last_remote_record_archived = false
		cloud_save_remote_write_blocked = true
		_fetch_cloud_save_history("current_invalid")
		return
	var record := parsed as Dictionary
	cloud_save_remote_revision = maxi(0, int(record.get("revision", 0)))
	if LeaderboardProfile.sanitize_player_id(str(record.get("uid", ""))) != app.leaderboard_profile.player_id:
		cloud_save_status_message = "Cloud save account id did not match."
		cloud_save_remote_checked = false
		cloud_save_last_remote_record.clear()
		cloud_save_last_remote_record_archived = false
		cloud_save_remote_write_blocked = true
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var safe_payload := _cloud_save_payload_from_record(record, true)
	if safe_payload.is_empty():
		cloud_save_last_remote_record.clear()
		cloud_save_last_remote_record_archived = false
		cloud_save_remote_write_blocked = true
		_fetch_cloud_save_history("current_invalid")
		return
	var archival_record := _cloud_save_archival_record(record, safe_payload)
	if archival_record.is_empty():
		cloud_save_last_remote_record.clear()
		cloud_save_last_remote_record_archived = false
		cloud_save_remote_write_blocked = true
		_fetch_cloud_save_history("current_invalid")
		return
	cloud_save_last_remote_record = archival_record
	cloud_save_last_remote_record_archived = false
	cloud_save_remote_revision = maxi(cloud_save_remote_revision, int(archival_record.get("revision", 1)))
	cloud_save_remote_write_blocked = false
	cloud_save_history_checked = false
	_apply_cloud_save_candidate(safe_payload, cloud_save_remote_revision, "cloud")
	cloud_save_last_remote_summary["payload_checksum"] = str(record.get("payload_checksum", ""))


func _handle_missing_current_cloud_save() -> void:
	cloud_save_last_remote_summary.clear()
	cloud_save_last_remote_payload.clear()
	cloud_save_last_remote_record.clear()
	cloud_save_last_remote_record_archived = false
	cloud_save_remote_write_blocked = false
	if not cloud_save_history_checked:
		_fetch_cloud_save_history("current_missing")
		return
	cloud_save_remote_checked = true
	cloud_save_conflict_detected = false
	cloud_save_status_message = "No cloud save found yet."
	if cloud_save_dirty:
		_upload_cloud_save(false)
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_cloud_save_upload_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	cloud_save_upload_in_flight = false
	if result != HTTPRequest.RESULT_SUCCESS:
		cloud_save_dirty = true
		cloud_save_pending_record.clear()
		cloud_save_status_message = "Cloud save upload failed."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if response_code == 412:
		cloud_save_dirty = true
		cloud_save_pending_record.clear()
		cloud_save_remote_checked = false
		cloud_save_remote_etag = ""
		cloud_save_last_remote_record.clear()
		cloud_save_last_remote_record_archived = false
		cloud_save_status_message = "Cloud save changed on another device. Checking it before retrying."
		_fetch_cloud_save()
		return
	if response_code < 200 or response_code >= 300:
		cloud_save_dirty = true
		cloud_save_pending_record.clear()
		var detail = _firebase_error_detail(body)
		cloud_save_status_message = "Cloud save upload returned HTTP %s%s" % [response_code, "." if detail.is_empty() else ": %s" % detail]
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var uploaded_record := cloud_save_pending_record.duplicate(true)
	cloud_save_pending_record.clear()
	cloud_save_last_upload_unix = app._unix_now()
	cloud_save_remote_revision = maxi(cloud_save_remote_revision, int(uploaded_record.get("revision", cloud_save_remote_revision)))
	var response_etag := _firebase_response_etag(headers)
	if response_etag.is_empty():
		cloud_save_remote_checked = false
		cloud_save_remote_etag = ""
	else:
		cloud_save_remote_checked = true
		cloud_save_remote_etag = response_etag
	var uploaded_payload = _parse_json_silent(str(uploaded_record.get("payload_json", "")))
	if typeof(uploaded_payload) == TYPE_DICTIONARY:
		cloud_save_last_remote_payload = uploaded_payload as Dictionary
		cloud_save_last_remote_summary = _cloud_save_summary(cloud_save_last_remote_payload)
		cloud_save_last_remote_summary["revision"] = cloud_save_remote_revision
		cloud_save_last_remote_summary["payload_checksum"] = str(uploaded_record.get("payload_checksum", ""))
	cloud_save_last_remote_record = uploaded_record.duplicate(true)
	cloud_save_last_remote_record_archived = false
	cloud_save_remote_write_blocked = false
	cloud_save_status_message = "Cloud save uploaded."
	_upload_cloud_save_history(uploaded_record, "snapshot")
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _upload_cloud_save_history(record: Dictionary, purpose := "snapshot") -> bool:
	if record.is_empty() or cloud_save_history_in_flight or not _cloud_save_account_ready():
		return false
	var revision := maxi(1, int(record.get("revision", 1)))
	var slot := revision % CLOUD_SAVE_HISTORY_SLOT_COUNT
	cloud_save_history_in_flight = true
	cloud_save_pending_history_record = record.duplicate(true)
	cloud_save_pending_history_purpose = purpose
	var err = cloud_save_history_request.request(
		_cloud_save_firebase_url("history/%s/slots/%s" % [app.leaderboard_profile.player_id, slot], _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PUT,
		JSON.stringify(record)
	)
	if err != OK:
		cloud_save_history_in_flight = false
		cloud_save_pending_history_record.clear()
		cloud_save_pending_history_purpose = ""
		return false
	return true


func _on_cloud_save_history_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	var purpose := cloud_save_pending_history_purpose
	var archived_record := cloud_save_pending_history_record.duplicate(true)
	var succeeded := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
	cloud_save_history_in_flight = false
	cloud_save_pending_history_record.clear()
	cloud_save_pending_history_purpose = ""
	if purpose == "before_replace":
		if not succeeded:
			cloud_save_upload_in_flight = false
			cloud_save_dirty = true
			cloud_save_pending_record.clear()
			cloud_save_status_message = "The previous cloud save could not be protected, so it was not overwritten."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
			return
		cloud_save_last_remote_record_archived = true
		_start_cloud_save_put()
		return
	if succeeded and purpose == "snapshot" and int(archived_record.get("revision", 0)) == cloud_save_remote_revision:
		cloud_save_last_remote_record_archived = true


func _fetch_cloud_save_history(reason: String) -> void:
	if cloud_save_history_fetch_in_flight:
		return
	if cloud_save_history_checked:
		cloud_save_status_message = "Cloud save was invalid and no valid backup was found. The device save was preserved."
		cloud_save_remote_checked = false
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not _cloud_save_account_ready():
		return
	cloud_save_history_fetch_in_flight = true
	cloud_save_history_fetch_reason = reason
	cloud_save_status_message = "Checking cloud save backups..."
	var err = cloud_save_history_fetch_request.request(
		_cloud_save_firebase_url("history/%s/slots" % app.leaderboard_profile.player_id, _leaderboard_authenticated_query()),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		cloud_save_history_fetch_in_flight = false
		cloud_save_history_checked = true
		cloud_save_status_message = "Cloud save backup check failed. The device save was preserved."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_cloud_save_history_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	cloud_save_history_fetch_in_flight = false
	cloud_save_history_checked = true
	var reason := cloud_save_history_fetch_reason
	cloud_save_history_fetch_reason = ""
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if reason == "current_missing":
			_handle_missing_current_cloud_save()
		else:
			cloud_save_remote_checked = false
			cloud_save_status_message = "Cloud save was invalid and backup recovery failed. The device save was preserved."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		if reason == "current_missing":
			_handle_missing_current_cloud_save()
		else:
			cloud_save_remote_checked = false
			cloud_save_status_message = "Cloud save was invalid and no valid backup was found. The device save was preserved."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var best_payload := {}
	var best_comparison := {}
	var best_revision := 0
	var local_payload: Dictionary = app._save_runtime()._save_payload(app._unix_now())
	for raw_slot in (parsed as Dictionary).keys():
		var raw_record = (parsed as Dictionary).get(raw_slot, {})
		if typeof(raw_record) != TYPE_DICTIONARY:
			continue
		var record := raw_record as Dictionary
		var payload := _cloud_save_payload_from_record(record, false)
		if payload.is_empty():
			continue
		var comparison := IdentitySafety.payload_with_preserved_identity_for_comparison(payload, local_payload)
		if best_payload.is_empty() or SaveRuntime.should_replace_best_save(best_comparison, comparison, app.skill_defs):
			best_payload = payload
			best_comparison = comparison
			best_revision = maxi(0, int(record.get("revision", 0)))
	if best_payload.is_empty():
		if reason == "current_missing":
			_handle_missing_current_cloud_save()
		else:
			cloud_save_remote_checked = false
			cloud_save_status_message = "Cloud save was invalid and no valid backup was found. The device save was preserved."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	_apply_cloud_save_candidate(best_payload, maxi(cloud_save_remote_revision, best_revision), "history")


func _process_cloud_save_sync() -> void:
	if not _save_restore_complete():
		return
	if leaderboard_auth_provider == "google" and not _cloud_save_account_ready():
		_leaderboard_ensure_auth()
		return
	if _cloud_save_account_ready() and not cloud_save_remote_checked and not cloud_save_fetch_in_flight:
		_fetch_cloud_save()
		return
	if cloud_save_dirty:
		_upload_cloud_save(false)


func _cloud_save_payload_should_replace_local(remote_payload: Dictionary) -> bool:
	var local_payload: Dictionary = app._save_runtime()._save_payload(app._unix_now())
	var comparison_payload: Dictionary = IdentitySafety.payload_with_preserved_identity_for_comparison(remote_payload, local_payload)
	return SaveRuntime.should_replace_best_save(local_payload, comparison_payload, app.skill_defs)


func _maybe_recover_profile_from_legacy_cloud_payload(remote_payload: Dictionary) -> void:
	if LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		return
	if LeaderboardProfile.sanitize_player_id(str(remote_payload.get("leaderboard_player_id", ""))) != app.leaderboard_profile.player_id:
		return
	if not bool(remote_payload.get("leaderboard_profile_claimed", false)) or not bool(remote_payload.get("leaderboard_name_claim_verified", false)):
		return
	var display_name := LeaderboardProfile.sanitize_display_name(str(remote_payload.get("leaderboard_display_name", "")), app.PROFILE_DISPLAY_NAME_MAX_CHARS)
	var name_key := LeaderboardProfile.sanitize_name_key(str(remote_payload.get("leaderboard_name_key", "")), app.PROFILE_NAME_KEY_MAX_CHARS)
	if name_key.is_empty() or LeaderboardProfile.make_name_key(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS) != name_key:
		return
	app.leaderboard_profile.display_name = display_name
	app.leaderboard_profile.name_key = name_key
	app.leaderboard_profile.avatar_index = LeaderboardProfile.valid_avatar_index(int(remote_payload.get("leaderboard_avatar_index", app.leaderboard_profile.avatar_index)), ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT)
	app.leaderboard_profile.profile_claimed = true
	app.leaderboard_profile.name_claim_verified = true
	profile_recovery_required_after_google_switch = false
	google_auth_status_message = "Google account and username recovered."
	_save_identity_state("legacy cloud profile recovered")
	_refresh_profile_references()


func _restore_cloud_save_payload(remote_payload: Dictionary) -> void:
	if not _save_restore_complete():
		return
	var auth_id_token: String = leaderboard_auth_id_token
	var auth_refresh_token: String = leaderboard_auth_refresh_token
	var auth_expires_unix: int = leaderboard_auth_expires_unix
	var auth_bound_uid: String = leaderboard_auth_bound_uid
	var auth_definitive_failure_code: String = leaderboard_auth_definitive_failure_code
	var player_id: String = app.leaderboard_profile.player_id
	var display_name: String = app.leaderboard_profile.display_name
	var name_key: String = app.leaderboard_profile.name_key
	var profile_claimed: bool = app.leaderboard_profile.profile_claimed
	var name_claim_verified: bool = app.leaderboard_profile.name_claim_verified
	var avatar_index: int = app.leaderboard_profile.avatar_index
	var legacy_old_uid: String = leaderboard_legacy_authless_old_uid
	var deleted_auth_transition_pending: bool = leaderboard_deleted_auth_transition_pending
	var name_transfer_required: bool = leaderboard_name_transfer_required
	var legacy_username_recovery_required: bool = leaderboard_legacy_username_recovery_required
	var legacy_name_hint_display: String = leaderboard_legacy_name_hint_display
	var legacy_name_hint_key: String = leaderboard_legacy_name_hint_key
	var restored_payload := remote_payload.duplicate(true)
	restored_payload["leaderboard_player_id"] = player_id
	restored_payload["leaderboard_display_name"] = display_name
	restored_payload["leaderboard_name_key"] = name_key
	restored_payload["leaderboard_profile_claimed"] = profile_claimed
	restored_payload["leaderboard_name_claim_verified"] = name_claim_verified
	restored_payload["leaderboard_avatar_index"] = avatar_index
	restored_payload["leaderboard_auth_provider"] = "google"
	restored_payload["leaderboard_auth_refresh_token"] = auth_refresh_token
	restored_payload["leaderboard_auth_bound_uid"] = auth_bound_uid
	restored_payload["leaderboard_auth_recovery_required"] = false
	restored_payload["leaderboard_auth_recovery_reason"] = ""
	restored_payload["leaderboard_auth_definitive_failure_code"] = auth_definitive_failure_code
	restored_payload["leaderboard_auth_retry_after_unix"] = 0
	restored_payload["leaderboard_legacy_authless_old_uid"] = legacy_old_uid
	restored_payload["leaderboard_deleted_auth_transition_pending"] = deleted_auth_transition_pending
	restored_payload["leaderboard_name_transfer_required"] = name_transfer_required
	restored_payload["leaderboard_legacy_username_recovery_required"] = legacy_username_recovery_required
	restored_payload["leaderboard_legacy_name_hint_display"] = legacy_name_hint_display
	restored_payload["leaderboard_legacy_name_hint_key"] = legacy_name_hint_key
	var save_runtime = app._save_runtime()
	save_runtime._clear_pending_save_restore_work()
	save_runtime._init_state()
	save_runtime._load_game_core(restored_payload)
	save_runtime.pending_save_restore_data = restored_payload
	save_runtime._restore_boot_render_save_fields(restored_payload)
	save_runtime._load_game_secondary_restore()
	save_runtime._apply_post_load_simulation()
	leaderboard_auth_id_token = auth_id_token
	leaderboard_auth_refresh_token = auth_refresh_token
	leaderboard_auth_expires_unix = auth_expires_unix
	leaderboard_auth_provider = "google"
	leaderboard_auth_bound_uid = auth_bound_uid
	leaderboard_auth_recovery_required = false
	leaderboard_auth_recovery_reason = ""
	leaderboard_auth_definitive_failure_code = auth_definitive_failure_code
	leaderboard_legacy_authless_old_uid = legacy_old_uid
	leaderboard_deleted_auth_transition_pending = deleted_auth_transition_pending
	leaderboard_name_transfer_required = name_transfer_required
	leaderboard_legacy_username_recovery_required = legacy_username_recovery_required
	leaderboard_legacy_name_hint_display = legacy_name_hint_display
	leaderboard_legacy_name_hint_key = legacy_name_hint_key
	app.leaderboard_profile.player_id = player_id
	cloud_save_remote_checked = true
	_save_identity_state("cloud save restored")
	app._update_ui(0.0, true)


func _leaderboard_fetch_category(category_id: String, allow_recent_refresh = false) -> void:
	ensure_leaderboard_http()
	var leaderboard_state = app.leaderboard_state
	var valid_id = leaderboard_state.valid_category_id(category_id)
	if not _leaderboard_firebase_enabled():
		leaderboard_state.status_message = "Online services are not connected yet."
		return
	var now = app._unix_now()
	var last_success_fetch = int(leaderboard_state.fetch_unix_by_category.get(valid_id, 0))
	var last_failed_fetch = int(leaderboard_state.fetch_retry_unix_by_category.get(valid_id, 0))
	var last_fetch = maxi(last_success_fetch, last_failed_fetch)
	if not allow_recent_refresh and last_fetch > 0 and now - last_fetch < LEADERBOARD_FETCH_INTERVAL_SECONDS:
		return
	if leaderboard_state.fetch_in_flight or leaderboard_state.total_xp_fetch_in_flight:
		return
	leaderboard_state.fetch_in_flight = true
	leaderboard_state.fetch_category_id = valid_id
	leaderboard_state.status_message = "Loading %s..." % leaderboard_state.category_label(valid_id)
	var category_key = _leaderboard_category_key(valid_id)
	var query = "orderBy=%%22score%%22&limitToLast=%s" % LeaderboardState.TOP_COUNT
	var err = leaderboard_fetch_request.request(
		_leaderboard_firebase_url("scores/%s" % category_key, query),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		leaderboard_state.fetch_in_flight = false
		leaderboard_state.fetch_category_id = ""
		_leaderboard_note_fetch_failure(valid_id, "Leaderboard read failed: %s" % error_string(err))


func _leaderboard_finalize_fetch_rows(category_id: String, rows: Array) -> void:
	var leaderboard_state = app.leaderboard_state
	if category_id == LeaderboardState.CATEGORY_TOTAL_LEVEL:
		leaderboard_state.pending_total_rows = rows
		var query = "orderBy=%%22score%%22&limitToLast=%s" % LeaderboardState.TOP_COUNT
		leaderboard_state.total_xp_fetch_in_flight = true
		var err = leaderboard_total_xp_fetch_request.request(
			_leaderboard_firebase_url("scores/%s" % LeaderboardState.CATEGORY_TOTAL_XP_COMPAT, query),
			PackedStringArray([LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_GET
		)
		if err == OK:
			return
		leaderboard_state.total_xp_fetch_in_flight = false
		leaderboard_state.pending_total_rows = []
	_leaderboard_store_fetch_rows(category_id, rows)


func _leaderboard_store_fetch_rows(category_id: String, rows: Array) -> void:
	var leaderboard_state = app.leaderboard_state
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a = int(a.get("score", 0))
		var score_b = int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		if category_id == LeaderboardState.CATEGORY_TOTAL_LEVEL:
			var total_xp_a = int(a.get("total_xp", 0))
			var total_xp_b = int(b.get("total_xp", 0))
			if total_xp_a != total_xp_b:
				return total_xp_a > total_xp_b
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	if rows.size() > LeaderboardState.TOP_COUNT:
		rows = rows.slice(0, LeaderboardState.TOP_COUNT)
	leaderboard_state.rows_by_category[category_id] = rows
	leaderboard_state.fetch_unix_by_category[category_id] = app._unix_now()
	var had_retry_cooldown = leaderboard_state.fetch_retry_unix_by_category.has(category_id)
	if had_retry_cooldown:
		leaderboard_state.fetch_retry_unix_by_category.erase(category_id)
		app._mark_save_dirty("leaderboard retry cleared")
	leaderboard_state.status_message = "Leaderboard loaded."
	if app.current_screen == "leaderboard" and category_id == leaderboard_state.category_id:
		app.leaderboard_presentation._refresh_if_visible()


func _on_leaderboard_total_xp_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var leaderboard_state = app.leaderboard_state
	leaderboard_state.total_xp_fetch_in_flight = false
	var rows = leaderboard_state.pending_total_rows
	leaderboard_state.pending_total_rows = []
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		var parsed = _parse_json_silent(body.get_string_from_utf8())
		var xp_by_player = {}
		if typeof(parsed) == TYPE_DICTIONARY:
			for raw_player_id in (parsed as Dictionary).keys():
				var entry = (parsed as Dictionary).get(raw_player_id, {})
				if typeof(entry) == TYPE_DICTIONARY:
					xp_by_player[str(raw_player_id)] = maxi(0, int((entry as Dictionary).get("score", 0)))
		for i in range(rows.size()):
			var row = rows[i] as Dictionary
			if int(row.get("total_xp", 0)) <= 0:
				row["total_xp"] = int(xp_by_player.get(str(row.get("player_id", "")), 0))
			row["score_text"] = LeaderboardPresentation.format_score(LeaderboardState.CATEGORY_TOTAL_LEVEL, int(row.get("score", 0)), 0, int(row.get("total_xp", 0)), LeaderboardState.CATEGORY_TOTAL_LEVEL, LeaderboardState.CATEGORY_MEDALS, LeaderboardState.CATEGORY_ELITE_HEAVENLY, LeaderboardState.CATEGORY_SKILL_PREFIX, Callable(leaderboard_state, "skill_level_from_total_xp"))
			rows[i] = row
	_leaderboard_store_fetch_rows(LeaderboardState.CATEGORY_TOTAL_LEVEL, rows)


func _leaderboard_submit_scores() -> void:
	if app.god_mode_save_tainted:
		app.leaderboard_state.status_message = "Test save: leaderboard publishing paused."
		return
	if not _leaderboard_firebase_enabled():
		app.leaderboard_state.status_message = "Online services are not connected yet."
		return
	if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required:
		app.leaderboard_state.status_message = "Leaderboard publishing is paused until legacy username recovery is complete."
		return
	if not _leaderboard_write_ready():
		return
	if not LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		app.leaderboard_state.status_message = "Save a unique leaderboard name before publishing."
		return
	var leaderboard_state = app.leaderboard_state
	if leaderboard_submit_in_flight or not leaderboard_state.submit_ready():
		return
	_ensure_leaderboard_player_id()
	var repair_publish_due = leaderboard_state.repair_publish_due()
	var now_unix = app._unix_now()
	var server_timestamp = _firebase_server_timestamp()
	var score_updates = {}
	app.leaderboard_state.last_submit_payload_categories.clear()
	app.leaderboard_state.pending_repair_publish_version = 0
	for raw_category in leaderboard_state.categories():
		var category = raw_category as Dictionary
		var category_id = leaderboard_state.valid_category_id(str(category.get("id", "")))
		if category_id.is_empty():
			continue
		var score = maxi(0, leaderboard_state.score_for_category(category_id))
		var last_score = int(app.leaderboard_state.last_submitted_scores_by_category.get(category_id, 0))
		if score <= 0:
			continue
		if not repair_publish_due and score <= last_score:
			if not (category_id == LeaderboardState.CATEGORY_TOTAL_LEVEL and leaderboard_state.score() > app.leaderboard_state.last_submitted_total_xp):
				continue
		var category_key = _leaderboard_category_key(category_id)
		score_updates["scores/%s/%s" % [category_key, app.leaderboard_profile.player_id]] = {
			"name": app.leaderboard_profile.display_name,
			"name_key": app.leaderboard_profile.name_key,
			"avatar_index": app.leaderboard_profile.avatar_index,
			"score": score,
			"skill_level": leaderboard_state.skill_level_for_category(category_id),
			"total_xp": leaderboard_state.total_xp_for_category(category_id),
			"updated_at": server_timestamp,
			"submitted_at_unix": now_unix
		}
		app.leaderboard_state.last_submit_payload_categories.append(category_id)
	if score_updates.is_empty():
		app.leaderboard_state.last_submitted_score = leaderboard_state.score()
		if repair_publish_due:
			app.leaderboard_state.repair_publish_version = LeaderboardState.REPAIR_PUBLISH_VERSION
		app._mark_save_dirty("leaderboard submit checkpoint")
		return
	app.leaderboard_state.pending_score_updates = score_updates
	if repair_publish_due:
		app.leaderboard_state.pending_repair_publish_version = LeaderboardState.REPAIR_PUBLISH_VERSION
	leaderboard_submit_stage = "gate"
	var gate_payload = {
		"updated_at": server_timestamp,
		"submitted_at_unix": now_unix
	}
	leaderboard_submit_in_flight = true
	app.leaderboard_state.status_message = "Publishing leaderboard scores..."
	var err = leaderboard_submit_request.request(
		_leaderboard_firebase_url("player_write_gates/%s" % app.leaderboard_profile.player_id, _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PUT,
		JSON.stringify(gate_payload)
	)
	if err != OK:
		leaderboard_submit_in_flight = false
		leaderboard_submit_stage = ""
		app.leaderboard_state.pending_score_updates.clear()
		app.leaderboard_state.pending_repair_publish_version = 0
		_leaderboard_note_submit_failure("Leaderboard write failed: %s" % error_string(err))


func _process_leaderboard_sync(delta: float) -> void:
	var leaderboard_state = app.leaderboard_state
	leaderboard_state.process_seconds += delta
	if leaderboard_state.process_seconds < LEADERBOARD_PROCESS_INTERVAL_SECONDS:
		return
	leaderboard_state.process_seconds = 0.0
	if not _leaderboard_firebase_enabled():
		return
	if leaderboard_name_claim_in_flight and not leaderboard_name_claim_request_started:
		_start_queued_name_claim()
	if app.current_screen == "leaderboard":
		_leaderboard_fetch_category(leaderboard_state.category_id)
	if app._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		_chat_stream_connect()
	if leaderboard_state.submit_ready():
		_leaderboard_submit_scores()
	_process_cloud_save_sync()


func _on_leaderboard_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var leaderboard_state = app.leaderboard_state
	var category_id = leaderboard_state.fetch_category_id
	leaderboard_state.fetch_in_flight = false
	leaderboard_state.fetch_category_id = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		_leaderboard_note_fetch_failure(category_id, "Leaderboard read failed.")
		return
	if response_code < 200 or response_code >= 300:
		_leaderboard_note_fetch_failure(category_id, "Leaderboard read returned HTTP %s." % response_code)
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	var rows = []
	if typeof(parsed) == TYPE_DICTIONARY:
		for raw_player_id in (parsed as Dictionary).keys():
			var player_id = str(raw_player_id)
			var entry = (parsed as Dictionary).get(raw_player_id, {})
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var row = entry as Dictionary
			var score = maxi(0, int(row.get("score", 0)))
			if score <= 0:
				continue
			rows.append({
				"player_id": player_id,
				"name": LeaderboardProfile.sanitize_display_name(str(row.get("name", "Player")), app.PROFILE_DISPLAY_NAME_MAX_CHARS),
				"name_key": LeaderboardProfile.sanitize_name_key(str(row.get("name_key", "")), app.PROFILE_NAME_KEY_MAX_CHARS),
				"score": score,
				"total_xp": maxi(0, int(row.get("total_xp", 0))),
				"score_text": LeaderboardPresentation.format_score(app.leaderboard_state.valid_category_id(category_id), score, maxi(0, int(row.get("skill_level", 0))), maxi(0, int(row.get("total_xp", 0))), LeaderboardState.CATEGORY_TOTAL_LEVEL, LeaderboardState.CATEGORY_MEDALS, LeaderboardState.CATEGORY_ELITE_HEAVENLY, LeaderboardState.CATEGORY_SKILL_PREFIX, Callable(app.leaderboard_state, "skill_level_from_total_xp")),
				"avatar_index": LeaderboardProfile.valid_avatar_index(int(row.get("avatar_index", 0)), ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT),
				"is_player": player_id == app.leaderboard_profile.player_id
			})
	_leaderboard_finalize_fetch_rows(category_id, rows)


func _on_leaderboard_auth_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var mode = leaderboard_auth_mode
	leaderboard_auth_in_flight = false
	leaderboard_auth_mode = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		_leaderboard_note_auth_failure("Online login failed.")
		return
	if response_code < 200 or response_code >= 300:
		var detail = _firebase_error_detail(body)
		var definitive_failure_code: String = IdentitySafety.refresh_failure_code(response_code, detail) if mode in ["refresh", "refresh_recovery"] else ""
		var definitive_refresh_failure: bool = not definitive_failure_code.is_empty()
		if detail.is_empty():
			_leaderboard_note_auth_failure("Online login returned HTTP %s." % response_code, definitive_refresh_failure, definitive_failure_code)
		else:
			_leaderboard_note_auth_failure("Online login returned HTTP %s: %s" % [response_code, detail], definitive_refresh_failure, definitive_failure_code)
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_leaderboard_note_auth_failure("Online login returned invalid JSON.")
		return
	if not _apply_firebase_auth_response(parsed as Dictionary, "anonymous" if mode == "sign_up" else str(leaderboard_auth_provider), mode):
		return
	if not google_auth_pending_id_token.is_empty():
		var resume_intent := google_auth_exchange_intent
		if resume_intent.is_empty():
			resume_intent = "link_same_uid"
		_start_google_firebase_exchange(resume_intent == "link_same_uid", resume_intent)
		return
	_fetch_profile_recovery_record()
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
	if profile_recovery_blocks_username_edit():
		return
	if app.current_screen == "leaderboard":
		_leaderboard_fetch_category(app.leaderboard_state.category_id)
	if app._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		_chat_stream_connect(true)
		_start_chat_stream_poll_timer()
		app._profile_chat_overlay_surface()._render_chat_if_visible()
	if app.leaderboard_state.submit_ready():
		_leaderboard_submit_scores()
	if leaderboard_name_claim_in_flight and not leaderboard_name_claim_request_started:
		_start_queued_name_claim()
	if not chat_pending_send_after_auth.is_empty():
		var queued_chat = chat_pending_send_after_auth
		chat_pending_send_after_auth = ""
		_chat_send(queued_chat)


func _claim_leaderboard_name(display_name: String) -> void:
	if leaderboard_name_claim_in_flight:
		return
	if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required:
		app._profile_chat_overlay_surface()._set_profile_status_text("Complete the approved username transfer first.")
		return
	if legacy_authless_google_transition_required() or deleted_auth_google_transition_required():
		app._profile_chat_overlay_surface()._set_profile_status_text("Connect Google to recover this profile.")
		return
	if profile_recovery_blocks_username_edit():
		app._profile_chat_overlay_surface()._set_profile_status_text("Checking the saved username for this account...")
		prepare_profile_recovery_on_open()
		return
	var clean_name := LeaderboardProfile.sanitize_display_name(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
	var name_key = LeaderboardProfile.make_name_key(clean_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS)
	if name_key.is_empty() or LeaderboardProfile.is_guest_display_name(clean_name, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS):
		app._profile_chat_overlay_surface()._set_profile_status_text("Choose a username first.")
		app._profile_chat_overlay_surface()._focus_profile_name_edit()
		return
	if not _leaderboard_firebase_enabled():
		app._profile_chat_overlay_surface()._set_profile_status_text("Online services are not connected yet.")
		return
	leaderboard_name_claim_pending_name = clean_name
	leaderboard_name_claim_pending_key = name_key
	leaderboard_name_claim_in_flight = true
	leaderboard_name_claim_request_started = false
	if not _leaderboard_write_ready():
		if leaderboard_auth_recovery_required:
			leaderboard_name_claim_in_flight = false
			leaderboard_name_claim_pending_name = ""
			leaderboard_name_claim_pending_key = ""
			app._profile_chat_overlay_surface()._set_profile_status_text("Sign in with Google to recover this account.")
		else:
			app._profile_chat_overlay_surface()._set_profile_status_text("Connecting leaderboard login...")
		return
	_start_queued_name_claim()


func _start_queued_name_claim() -> void:
	if not leaderboard_name_claim_in_flight or leaderboard_name_claim_request_started:
		return
	if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required or profile_recovery_blocks_username_edit():
		return
	if leaderboard_name_claim_pending_name.is_empty() or leaderboard_name_claim_pending_key.is_empty():
		leaderboard_name_claim_in_flight = false
		return
	if not _leaderboard_write_ready():
		return
	var now_unix = app._unix_now()
	var server_timestamp = _firebase_server_timestamp()
	var payload = {
		"uid": app.leaderboard_profile.player_id,
		"name": leaderboard_name_claim_pending_name,
		"name_key": leaderboard_name_claim_pending_key,
		"avatar_index": app.leaderboard_profile.avatar_index,
		"created_at": server_timestamp,
		"updated_at": server_timestamp,
		"submitted_at_unix": now_unix
	}
	var updates := {"name_claims/%s" % leaderboard_name_claim_pending_key: payload}
	if not _leaderboard_web_authless_writes_enabled():
		updates["profiles_by_uid/%s" % app.leaderboard_profile.player_id] = _profile_recovery_record(leaderboard_name_claim_pending_name, leaderboard_name_claim_pending_key, now_unix)
	leaderboard_name_claim_request_started = true
	app._profile_chat_overlay_surface()._set_profile_status_text("Checking username...")
	var err = leaderboard_name_claim_request.request(
		_leaderboard_firebase_url("", _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PATCH,
		JSON.stringify(updates)
	)
	if err != OK:
		leaderboard_name_claim_in_flight = false
		leaderboard_name_claim_request_started = false
		leaderboard_name_claim_pending_name = ""
		leaderboard_name_claim_pending_key = ""
		app._profile_chat_overlay_surface()._set_profile_status_text("Username check failed. Try again.")


func _on_leaderboard_name_claim_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	leaderboard_name_claim_in_flight = false
	leaderboard_name_claim_request_started = false
	var claimed_name = leaderboard_name_claim_pending_name
	var claimed_key = leaderboard_name_claim_pending_key
	leaderboard_name_claim_pending_name = ""
	leaderboard_name_claim_pending_key = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		app._profile_chat_overlay_surface()._set_profile_status_text("Username check failed. Try again.")
		return
	if response_code == 401 or response_code == 403:
		app._profile_chat_overlay_surface()._set_profile_status_text("Username is unavailable.")
		app._profile_chat_overlay_surface()._focus_profile_name_edit()
		return
	if response_code < 200 or response_code >= 300:
		app._profile_chat_overlay_surface()._set_profile_status_text("Username check failed. Try again.")
		return
	app.leaderboard_profile.display_name = claimed_name
	app.leaderboard_profile.name_key = claimed_key
	app.leaderboard_profile.profile_claimed = true
	app.leaderboard_profile.name_claim_verified = true
	app.leaderboard_state.status_message = "Leaderboard name saved."
	_save_identity_state("leaderboard username claimed")
	_refresh_profile_references()
	app._profile_chat_overlay_surface()._rebuild_profile_overlay()
	if app.current_screen == "leaderboard":
		app.leaderboard_presentation._refresh_if_visible()
	if app.leaderboard_state.submit_ready():
		_leaderboard_submit_scores()


func _profile_recovery_record(display_name: String, name_key: String, now_unix: int) -> Dictionary:
	return {
		"uid": app.leaderboard_profile.player_id,
		"display_name": LeaderboardProfile.sanitize_display_name(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS),
		"name_key": LeaderboardProfile.sanitize_name_key(name_key, app.PROFILE_NAME_KEY_MAX_CHARS),
		"avatar_index": LeaderboardProfile.valid_avatar_index(app.leaderboard_profile.avatar_index, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT),
		"profile_claimed": true,
		"name_claim_verified": true,
		"auth_provider": leaderboard_auth_provider,
		"updated_at": _firebase_server_timestamp(),
		"updated_at_unix": now_unix
	}


func complete_legacy_name_transfer() -> void:
	if not leaderboard_name_transfer_required or leaderboard_name_recovery_in_flight:
		return
	if not _leaderboard_auth_ready():
		_leaderboard_ensure_auth()
		app.leaderboard_state.status_message = "Reconnect Google, then press Complete Username Transfer again." if leaderboard_auth_recovery_required else "Login is refreshing. Press Complete Username Transfer again."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not _attempt_leaderboard_name_recovery():
		app.leaderboard_state.status_message = "Username transfer could not start. Try again."
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func complete_legacy_username_recovery(display_name: String) -> void:
	if not leaderboard_legacy_username_recovery_required or leaderboard_name_recovery_in_flight or profile_recovery_blocks_username_edit():
		return
	var clean_name := LeaderboardProfile.sanitize_display_name(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
	var name_key := LeaderboardProfile.make_name_key(clean_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS)
	if name_key.is_empty() or LeaderboardProfile.is_guest_display_name(clean_name, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS) or LeaderboardProfile.is_default_display_name(clean_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS):
		app._profile_chat_overlay_surface()._set_profile_status_text("Enter the username approved by support.")
		return
	leaderboard_name_recovery_pending_display = clean_name
	leaderboard_name_recovery_pending_key = name_key
	if not _leaderboard_auth_ready():
		_leaderboard_ensure_auth()
		app.leaderboard_state.status_message = "Reconnect Google, then press Recover Approved Username again." if leaderboard_auth_recovery_required else "Login is refreshing. Press Recover Approved Username again."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not _attempt_leaderboard_name_recovery():
		app.leaderboard_state.status_message = "Approved username recovery could not start. Try again."
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _note_recovery_profile_verification_failure(message: String) -> void:
	profile_recovery_lookup_gate = true
	profile_recovery_lookup_conclusive_missing = false
	leaderboard_auth_retry_after_unix = app._unix_now() + LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS
	leaderboard_auth_last_error_class = "canonical_profile_verification"
	leaderboard_auth_last_transition_outcome = "refresh_recovery_profile_unverified"
	app.leaderboard_state.status_message = message
	google_auth_status_message = message
	_record_auth_diagnostic("refresh_recovery_profile_unverified")
	_save_identity_state("online profile verification blocked")
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _fetch_profile_recovery_record() -> void:
	ensure_leaderboard_http()
	if profile_recovery_fetch_in_flight or _leaderboard_web_authless_writes_enabled() or leaderboard_name_transfer_required:
		return
	if not _save_restore_complete() or not (_leaderboard_auth_ready() or _recovery_profile_read_ready()):
		return
	if app.leaderboard_profile.player_id.is_empty() or app.leaderboard_profile.player_id != leaderboard_auth_bound_uid:
		return
	profile_recovery_fetch_in_flight = true
	var err = profile_recovery_fetch_request.request(
		_leaderboard_firebase_url("profiles_by_uid/%s" % app.leaderboard_profile.player_id, _leaderboard_authenticated_query()),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		profile_recovery_fetch_in_flight = false
		if _recovery_profile_verification_pending():
			_note_recovery_profile_verification_failure("Saved username check failed to start. Try again.")
		elif profile_recovery_blocks_username_edit():
			app.leaderboard_state.status_message = "Saved username check failed to start. Try again."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_profile_recovery_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	profile_recovery_fetch_in_flight = false
	var recovery_refresh_verification := _recovery_profile_verification_pending()
	if result != HTTPRequest.RESULT_SUCCESS:
		if recovery_refresh_verification:
			_note_recovery_profile_verification_failure("Saved username check failed. Try again.")
		elif profile_recovery_blocks_username_edit():
			app.leaderboard_state.status_message = "Saved username check failed. Try again."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var raw_body := body.get_string_from_utf8().strip_edges()
	var parsed = _parse_json_silent(raw_body)
	# Realtime Database returns a successful JSON null for an absent node. A 404
	# can also mean a wrong database URL or endpoint and must not unlock a new
	# claim over a possibly existing canonical profile.
	var record_is_conclusively_missing := response_code >= 200 and response_code < 300 and raw_body == "null"
	if record_is_conclusively_missing:
		if recovery_refresh_verification:
			_note_recovery_profile_verification_failure("No canonical saved username was found for this account. Contact support.")
			return
		profile_recovery_lookup_gate = false
		profile_recovery_lookup_conclusive_missing = true
		if profile_recovery_required_after_google_switch:
			profile_recovery_required_after_google_switch = false
			google_auth_status_message = "Google connected. Choose a username for this account."
		elif LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
			_refresh_profile_references()
		else:
			app.leaderboard_state.status_message = "No saved username was found. Choose a username."
		if _cloud_save_account_ready():
			_fetch_cloud_save()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		if leaderboard_name_claim_in_flight and not leaderboard_name_claim_request_started:
			_start_queued_name_claim()
		return
	if response_code < 200 or response_code >= 300 or typeof(parsed) != TYPE_DICTIONARY:
		if recovery_refresh_verification:
			_note_recovery_profile_verification_failure("Saved username could not be verified. Try again.")
		elif profile_recovery_blocks_username_edit():
			app.leaderboard_state.status_message = "Saved username could not be verified. Try again."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var record := parsed as Dictionary
	var record_uid := LeaderboardProfile.sanitize_player_id(str(record.get("uid", "")))
	var display_name := LeaderboardProfile.sanitize_display_name(str(record.get("display_name", "")), app.PROFILE_DISPLAY_NAME_MAX_CHARS)
	var name_key := LeaderboardProfile.sanitize_name_key(str(record.get("name_key", "")), app.PROFILE_NAME_KEY_MAX_CHARS)
	if record_uid != app.leaderboard_profile.player_id or name_key.is_empty() or LeaderboardProfile.make_name_key(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS) != name_key:
		if recovery_refresh_verification:
			_note_recovery_profile_verification_failure("Saved username data needs support review.")
		elif profile_recovery_blocks_username_edit():
			app.leaderboard_state.status_message = "Saved username data needs support review."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not bool(record.get("profile_claimed", false)) or not bool(record.get("name_claim_verified", false)):
		if recovery_refresh_verification:
			_note_recovery_profile_verification_failure("Saved username data needs support review.")
		elif profile_recovery_blocks_username_edit():
			app.leaderboard_state.status_message = "Saved username data needs support review."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var previous_recovery_state: Dictionary = {}
	if recovery_refresh_verification:
		previous_recovery_state = {
			"refresh_token": leaderboard_auth_refresh_token,
			"pending_refresh_token": leaderboard_auth_recovery_pending_refresh_token,
			"recovery_required": leaderboard_auth_recovery_required,
			"recovery_reason": leaderboard_auth_recovery_reason,
			"definitive_failure_code": leaderboard_auth_definitive_failure_code,
			"last_error_class": leaderboard_auth_last_error_class,
			"last_transition_outcome": leaderboard_auth_last_transition_outcome,
			"display_name": app.leaderboard_profile.display_name,
			"name_key": app.leaderboard_profile.name_key,
			"avatar_index": app.leaderboard_profile.avatar_index,
			"profile_claimed": app.leaderboard_profile.profile_claimed,
			"name_claim_verified": app.leaderboard_profile.name_claim_verified,
			"required_after_google_switch": profile_recovery_required_after_google_switch
		}
	app.leaderboard_profile.display_name = display_name
	app.leaderboard_profile.name_key = name_key
	app.leaderboard_profile.avatar_index = LeaderboardProfile.valid_avatar_index(int(record.get("avatar_index", app.leaderboard_profile.avatar_index)), ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT)
	app.leaderboard_profile.profile_claimed = true
	app.leaderboard_profile.name_claim_verified = true
	profile_recovery_required_after_google_switch = false
	profile_recovery_lookup_gate = false
	profile_recovery_lookup_conclusive_missing = false
	if recovery_refresh_verification:
		leaderboard_auth_refresh_token = leaderboard_auth_recovery_pending_refresh_token
		leaderboard_auth_recovery_pending_refresh_token = ""
		leaderboard_auth_recovery_required = false
		leaderboard_auth_recovery_reason = ""
		leaderboard_auth_definitive_failure_code = ""
		leaderboard_auth_retry_after_unix = 0
		leaderboard_auth_last_error_class = "none"
		leaderboard_auth_last_transition_outcome = "refresh_recovery_verified"
	google_auth_status_message = "Google account and username recovered."
	var identity_saved := _save_identity_state("online profile recovered")
	if recovery_refresh_verification and not identity_saved:
		leaderboard_auth_refresh_token = str(previous_recovery_state.get("refresh_token", ""))
		leaderboard_auth_recovery_pending_refresh_token = str(previous_recovery_state.get("pending_refresh_token", ""))
		leaderboard_auth_recovery_required = bool(previous_recovery_state.get("recovery_required", true))
		leaderboard_auth_recovery_reason = str(previous_recovery_state.get("recovery_reason", ""))
		leaderboard_auth_definitive_failure_code = str(previous_recovery_state.get("definitive_failure_code", ""))
		leaderboard_auth_last_error_class = "local_save_failure"
		leaderboard_auth_last_transition_outcome = "refresh_recovery_verification_not_saved"
		leaderboard_auth_retry_after_unix = app._unix_now() + LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS
		app.leaderboard_profile.display_name = str(previous_recovery_state.get("display_name", ""))
		app.leaderboard_profile.name_key = str(previous_recovery_state.get("name_key", ""))
		app.leaderboard_profile.avatar_index = int(previous_recovery_state.get("avatar_index", 0))
		app.leaderboard_profile.profile_claimed = bool(previous_recovery_state.get("profile_claimed", false))
		app.leaderboard_profile.name_claim_verified = bool(previous_recovery_state.get("name_claim_verified", false))
		profile_recovery_required_after_google_switch = bool(previous_recovery_state.get("required_after_google_switch", false))
		profile_recovery_lookup_gate = true
		profile_recovery_lookup_conclusive_missing = false
		app.leaderboard_state.status_message = "Verified username could not be saved. Try again."
		google_auth_status_message = app.leaderboard_state.status_message
		_record_auth_diagnostic("refresh_recovery_verification_not_saved")
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	_refresh_local_profile_references()
	if _cloud_save_account_ready():
		_fetch_cloud_save()
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
	if app.current_screen == "leaderboard":
		app.leaderboard_presentation._refresh_if_visible()


func _attempt_leaderboard_name_recovery() -> bool:
	if leaderboard_name_recovery_in_flight:
		return true
	if not _leaderboard_firebase_enabled():
		return false
	var recovery_display := LeaderboardProfile.sanitize_display_name(leaderboard_name_recovery_pending_display, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
	var recovery_name_key := LeaderboardProfile.sanitize_name_key(leaderboard_name_recovery_pending_key, app.PROFILE_NAME_KEY_MAX_CHARS)
	if recovery_name_key.is_empty():
		if leaderboard_name_transfer_required and _legacy_name_hint_valid():
			recovery_display = leaderboard_legacy_name_hint_display
			recovery_name_key = leaderboard_legacy_name_hint_key
		elif LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
			recovery_display = app.leaderboard_profile.display_name
			recovery_name_key = app.leaderboard_profile.name_key
	if recovery_name_key.is_empty() or LeaderboardProfile.make_name_key(recovery_display, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS) != recovery_name_key:
		return false
	if not _leaderboard_write_ready():
		return false
	if app.leaderboard_profile.player_id.is_empty():
		return false
	leaderboard_name_recovery_pending_display = recovery_display
	leaderboard_name_recovery_pending_key = recovery_name_key
	var now_unix = app._unix_now()
	var server_timestamp = _firebase_server_timestamp()
	var payload = {
		"uid": app.leaderboard_profile.player_id,
		"name": recovery_display,
		"name_key": recovery_name_key,
		"avatar_index": app.leaderboard_profile.avatar_index,
		"created_at": server_timestamp,
		"updated_at": server_timestamp,
		"submitted_at_unix": now_unix
	}
	var recovery_updates := {"name_claims/%s" % recovery_name_key: payload}
	if not _leaderboard_web_authless_writes_enabled():
		recovery_updates["profiles_by_uid/%s" % app.leaderboard_profile.player_id] = _profile_recovery_record(recovery_display, recovery_name_key, now_unix)
	if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required:
		recovery_updates["name_recovery_gates/%s" % app.leaderboard_profile.player_id] = {
			"name_key": recovery_name_key,
			"old_uid": leaderboard_legacy_authless_old_uid,
			"target_uid": app.leaderboard_profile.player_id,
			"updated_at": server_timestamp
		}
	leaderboard_name_recovery_in_flight = true
	var err = leaderboard_name_recovery_request.request(
		_leaderboard_firebase_url("", _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PATCH,
		JSON.stringify(recovery_updates)
	)
	if err != OK:
		leaderboard_name_recovery_in_flight = false
		return false
	app.leaderboard_state.status_message = "Checking name recovery..."
	return true


func _on_leaderboard_name_recovery_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	leaderboard_name_recovery_in_flight = false
	if result != HTTPRequest.RESULT_SUCCESS:
		app.leaderboard_state.status_message = "Name recovery check failed. Try again later."
		return
	if response_code >= 200 and response_code < 300:
		var completed_legacy_transfer := leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required
		var recovered_display := leaderboard_name_recovery_pending_display
		var recovered_name_key := leaderboard_name_recovery_pending_key
		leaderboard_name_recovery_pending_display = ""
		leaderboard_name_recovery_pending_key = ""
		if completed_legacy_transfer and not recovered_name_key.is_empty():
			app.leaderboard_profile.display_name = recovered_display
			app.leaderboard_profile.name_key = recovered_name_key
		app.leaderboard_profile.profile_claimed = true
		app.leaderboard_profile.name_claim_verified = true
		if completed_legacy_transfer:
			leaderboard_name_transfer_required = false
			leaderboard_legacy_username_recovery_required = false
			leaderboard_deleted_auth_transition_pending = false
			leaderboard_auth_definitive_failure_code = ""
			leaderboard_legacy_authless_old_uid = ""
			leaderboard_legacy_name_hint_display = ""
			leaderboard_legacy_name_hint_key = ""
			profile_recovery_lookup_gate = false
			profile_recovery_lookup_conclusive_missing = false
			google_auth_status_message = "Google account and username connected."
		app.leaderboard_state.status_message = "Username transfer complete." if completed_legacy_transfer else "Leaderboard name recovered. Try chat again."
		app.leaderboard_state.repair_publish_version = 0
		if completed_legacy_transfer:
			var current_player_uid: String = LeaderboardProfile.sanitize_player_id(app.leaderboard_profile.player_id)
			app._save_runtime().allow_next_identity_transition_save(current_player_uid, current_player_uid)
		_save_identity_state("legacy username transfer complete" if completed_legacy_transfer else "leaderboard username recovered")
		_refresh_profile_references()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		if app.current_screen == "leaderboard":
			app.leaderboard_presentation._refresh_if_visible()
		return
	var detail = _firebase_error_detail(body)
	if response_code == 401 or response_code == 403:
		app.leaderboard_state.status_message = "Username transfer needs support approval." if leaderboard_name_transfer_required else "Name recovery needs support approval."
	else:
		app.leaderboard_state.status_message = "Name recovery returned HTTP %s." % response_code
	if not detail.is_empty() and response_code != 401 and response_code != 403:
		app.leaderboard_state.status_message = "%s %s" % [app.leaderboard_state.status_message, detail]


func _on_leaderboard_submit_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var stage = leaderboard_submit_stage
	if stage == "gate":
		if result != HTTPRequest.RESULT_SUCCESS:
			leaderboard_submit_in_flight = false
			_leaderboard_note_submit_failure("Leaderboard write gate failed.")
			return
		if response_code < 200 or response_code >= 300:
			leaderboard_submit_in_flight = false
			var gate_detail = _firebase_error_detail(body)
			if response_code == 401 or response_code == 403:
				leaderboard_auth_id_token = ""
				leaderboard_auth_expires_unix = 0
			if not gate_detail.is_empty():
				_leaderboard_note_submit_failure("Leaderboard write gate returned HTTP %s: %s" % [response_code, gate_detail])
			else:
				_leaderboard_note_submit_failure("Leaderboard write gate returned HTTP %s." % response_code)
			return
		leaderboard_submit_stage = "scores"
		var err = leaderboard_submit_request.request(
			_leaderboard_firebase_url("", _leaderboard_authenticated_query("print=silent")),
			PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_PATCH,
			JSON.stringify(app.leaderboard_state.pending_score_updates)
		)
		if err == OK:
			return
		leaderboard_submit_in_flight = false
		app.leaderboard_state.pending_score_updates.clear()
		_leaderboard_note_submit_failure("Leaderboard score write failed: %s" % error_string(err))
		return
	leaderboard_submit_in_flight = false
	leaderboard_submit_stage = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		_leaderboard_note_submit_failure("Leaderboard write failed.")
		return
	if response_code < 200 or response_code >= 300:
		var detail = _firebase_error_detail(body)
		if response_code == 401 or response_code == 403:
			leaderboard_auth_id_token = ""
			leaderboard_auth_expires_unix = 0
		if not detail.is_empty():
			_leaderboard_note_submit_failure("Leaderboard write returned HTTP %s: %s" % [response_code, detail])
		else:
			_leaderboard_note_submit_failure("Leaderboard write returned HTTP %s." % response_code)
		return
	app.leaderboard_state.last_submit_unix = app._unix_now()
	var leaderboard_state = app.leaderboard_state
	app.leaderboard_state.last_submitted_score = leaderboard_state.score()
	app.leaderboard_state.last_submitted_total_xp = leaderboard_state.score()
	for raw_category_id in app.leaderboard_state.last_submit_payload_categories:
		var category_id = leaderboard_state.valid_category_id(str(raw_category_id))
		app.leaderboard_state.last_submitted_scores_by_category[category_id] = leaderboard_state.score_for_category(category_id)
	if app.leaderboard_state.pending_repair_publish_version > app.leaderboard_state.repair_publish_version:
		app.leaderboard_state.repair_publish_version = clampi(app.leaderboard_state.pending_repair_publish_version, 0, LeaderboardState.REPAIR_PUBLISH_VERSION)
		app.leaderboard_state.status_message = "Leaderboard rows repaired."
	app.leaderboard_state.last_submit_payload_categories.clear()
	app.leaderboard_state.pending_score_updates.clear()
	app.leaderboard_state.pending_repair_publish_version = 0
	if app.leaderboard_state.status_message != "Leaderboard rows repaired.":
		app.leaderboard_state.status_message = "Leaderboard published."
	app.save_game()
	if app.current_screen == "leaderboard":
		_leaderboard_fetch_category(app.leaderboard_state.category_id, true)
		app.leaderboard_presentation._refresh_if_visible()


func _on_profile_reference_update_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_finish_profile_reference_update()
		return
	if profile_reference_update_stage == "canonical" and not profile_reference_pending_updates.is_empty():
		var reference_updates := profile_reference_pending_updates.duplicate(true)
		profile_reference_pending_updates.clear()
		profile_reference_update_stage = "references"
		var err = profile_reference_update_request.request(
			_firebase_database_url("", "", _leaderboard_authenticated_query("print=silent")),
			PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_PATCH,
			JSON.stringify(reference_updates)
		)
		if err == OK:
			return
	_finish_profile_reference_update()


func _finish_profile_reference_update() -> void:
	profile_reference_update_in_flight = false
	profile_reference_update_stage = ""
	profile_reference_pending_updates.clear()
	if profile_reference_refresh_queued:
		profile_reference_refresh_queued = false
		call_deferred("_refresh_profile_references")


func _chat_stream_connect(force_reconnect = false) -> void:
	if not app._profile_chat_overlay_surface()._global_chat_allowed():
		return
	if not _leaderboard_firebase_enabled():
		chat_status_message = "Online chat is not connected yet."
		return
	if _chat_web_polling_enabled():
		_chat_poll_messages(force_reconnect)
		return
	var now = app._unix_now()
	var visible_count = _chat_target_visible_count()
	if chat_stream_connected and chat_stream_visible_count >= visible_count and not force_reconnect:
		return
	var upgrading_visible_count = visible_count > chat_stream_visible_count and (chat_stream_connected or chat_stream_connecting or chat_stream_request_sent)
	if not force_reconnect and not upgrading_visible_count and chat_stream_next_connect_unix > now:
		return
	if chat_stream_connecting and chat_stream_visible_count >= visible_count and not force_reconnect:
		_start_chat_stream_poll_timer()
		return
	if not force_reconnect and chat_stream_retry_unix > now:
		return
	_chat_stream_disconnect(false)
	chat_stream_visible_count = visible_count
	var query = "orderBy=%%22created_at%%22&limitToLast=%s" % visible_count
	var target = _firebase_stream_target(_chat_firebase_url("messages", query))
	if target.is_empty():
		_chat_note_stream_failure("Chat stream URL was invalid.")
		return
	if chat_stream_client == null:
		_chat_note_stream_failure("Chat stream client is not ready yet.")
		return
	var err = chat_stream_client.connect_to_host(str(target.get("host", "")), 443, TLSOptions.client())
	if err != OK:
		_chat_note_stream_failure("Chat stream failed to connect: %s" % error_string(err))
		return
	chat_stream_next_connect_unix = now + app.CHAT_STREAM_RECONNECT_MIN_SECONDS
	chat_stream_connecting = true
	chat_stream_request_sent = false
	chat_stream_buffer = ""
	chat_stream_event_name = ""
	chat_stream_event_data_lines.clear()
	chat_stream_client.set_meta("request_path", str(target.get("path", "/")))
	chat_status_message = "Connecting global chat stream..."
	_start_chat_stream_poll_timer()


func _start_chat_stream_poll_timer() -> void:
	ensure_leaderboard_http()
	if chat_stream_poll_timer == null:
		return
	if chat_stream_poll_timer.is_stopped():
		chat_stream_poll_timer.start()
	_process_chat_live_sync(0.0)


func _stop_chat_stream_poll_timer() -> void:
	if chat_stream_poll_timer != null:
		chat_stream_poll_timer.stop()


func _process_chat_live_sync(delta: float) -> void:
	if not app._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		_chat_stream_disconnect(false)
		_stop_chat_stream_poll_timer()
		return
	var chat_strip: Control = app._profile_chat_overlay_surface().chat_strip_control()
	if chat_strip == null or not is_instance_valid(chat_strip) or not chat_strip.visible:
		_chat_stream_disconnect(false)
		return
	if not _leaderboard_firebase_enabled():
		_chat_stream_disconnect(false)
		return
	if _chat_web_polling_enabled():
		_chat_poll_messages(false)
		return
	if chat_stream_client == null:
		ensure_leaderboard_http()
		if chat_stream_client == null:
			return
		if app._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
			_chat_stream_connect()
		return
	var status = chat_stream_client.get_status()
	if status == HTTPClient.STATUS_DISCONNECTED:
		chat_stream_connected = false
		chat_stream_connecting = false
		_chat_stream_connect()
		return
	var poll_err = chat_stream_client.poll()
	if poll_err != OK:
		_chat_note_stream_failure("Chat stream failed: %s" % error_string(poll_err))
		return
	status = chat_stream_client.get_status()
	if status == HTTPClient.STATUS_CONNECTED and not chat_stream_request_sent:
		var request_path = str(chat_stream_client.get_meta("request_path", "/"))
		var err = chat_stream_client.request(
			HTTPClient.METHOD_GET,
			request_path,
			PackedStringArray(["Accept: text/event-stream"])
		)
		if err != OK:
			_chat_note_stream_failure("Chat stream request failed: %s" % error_string(err))
			return
		chat_stream_request_sent = true
		chat_status_message = "Opening global chat stream..."
		return
	if status == HTTPClient.STATUS_BODY:
		if not chat_stream_connected:
			chat_stream_connected = true
			chat_stream_connecting = false
			chat_stream_retry_unix = 0
			chat_status_message = "Global chat is live."
			app._mark_save_dirty("chat stream connected")
		var chunk = chat_stream_client.read_response_body_chunk()
		if chunk.size() > 0:
			_chat_stream_receive_text(chunk.get_string_from_utf8())
		return
	if status == HTTPClient.STATUS_CONNECTION_ERROR or status == HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
		_chat_note_stream_failure("Chat stream disconnected.")


func _chat_web_polling_enabled() -> bool:
	return OS.has_feature("web")


func _chat_poll_messages(force_refresh = false) -> void:
	ensure_leaderboard_http()
	if chat_fetch_request == null or not is_instance_valid(chat_fetch_request):
		chat_status_message = "Chat refresh is not ready yet."
		return
	if chat_fetch_in_flight:
		return
	var now = app._unix_now()
	var visible_count = _chat_target_visible_count()
	if not force_refresh and chat_stream_connected and chat_stream_visible_count >= visible_count and chat_stream_next_connect_unix > now:
		return
	if not force_refresh and chat_stream_retry_unix > now:
		return
	var query = "orderBy=%%22created_at%%22&limitToLast=%s" % visible_count
	chat_fetch_in_flight = true
	chat_stream_connecting = true
	chat_stream_request_sent = true
	chat_stream_visible_count = visible_count
	chat_status_message = "Refreshing global chat..."
	var err = chat_fetch_request.request(
		_chat_firebase_url("messages", query),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		chat_fetch_in_flight = false
		chat_stream_connecting = false
		chat_stream_request_sent = false
		_chat_note_stream_failure("Chat refresh failed: %s" % error_string(err))
		app._profile_chat_overlay_surface()._render_chat_if_visible()


func _on_chat_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	chat_fetch_in_flight = false
	chat_stream_connecting = false
	chat_stream_request_sent = false
	if result != HTTPRequest.RESULT_SUCCESS:
		_chat_note_stream_failure("Chat refresh failed.")
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if response_code < 200 or response_code >= 300:
		var detail = _firebase_error_detail(body)
		if detail.is_empty():
			_chat_note_stream_failure("Chat refresh returned HTTP %s." % response_code)
		else:
			_chat_note_stream_failure("Chat refresh returned HTTP %s: %s" % [response_code, detail])
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	if parsed == null:
		chat_rows.clear()
	elif typeof(parsed) == TYPE_DICTIONARY:
		_chat_replace_rows(parsed as Dictionary)
	else:
		_chat_note_stream_failure("Chat refresh returned invalid data.")
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	chat_stream_connected = true
	chat_stream_retry_unix = 0
	chat_stream_next_connect_unix = app._unix_now() + app.CHAT_STREAM_RECONNECT_MIN_SECONDS
	chat_status_message = "Global chat is live."
	app._profile_chat_overlay_surface()._render_chat_if_visible()


func _chat_send(raw_text: String) -> void:
	var clean_text = ChatState.sanitize_message(raw_text, app.CHAT_MESSAGE_MAX_CHARS, app.CHAT_CENSORED_WORDS)
	if clean_text.is_empty():
		chat_status_message = "Write a message first."
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if not _leaderboard_firebase_enabled():
		chat_status_message = "Online chat is not connected yet."
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required:
		chat_status_message = "Complete legacy username recovery before chatting."
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if not _leaderboard_web_authless_writes_enabled() and not _leaderboard_auth_ready() and _leaderboard_auth_retry_wait_seconds() > 0:
		leaderboard_auth_retry_after_unix = 0
	if not _leaderboard_write_ready():
		if leaderboard_auth_in_flight:
			chat_pending_send_after_auth = clean_text
			chat_status_message = "Connecting chat login, then sending..."
		else:
			chat_status_message = app.leaderboard_state.status_message
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if chat_send_in_flight:
		chat_status_message = "Still sending the previous message..."
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	var wait = _chat_next_send_seconds()
	if wait > 0:
		chat_status_message = "Chat is cooling down for %s." % GameFormatting.duration(float(wait))
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	var now_unix = app._unix_now()
	var message_id = ChatState.make_message_id(now_unix)
	var now_msec = int(round(Time.get_unix_time_from_system() * 1000.0))
	var server_timestamp = _firebase_server_timestamp()
	var has_claimed_chat_name = LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS)
	if not has_claimed_chat_name and not LeaderboardProfile.is_guest_display_name(app.leaderboard_profile.display_name, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS):
		chat_status_message = "Save or recover this username before chatting."
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	var chat_name_key = app.leaderboard_profile.name_key if has_claimed_chat_name else ""
	var chat_payload = ChatState.outgoing_message_payload(app.leaderboard_profile.player_id, app.leaderboard_profile.display_name, SkillState.global_level(app.skills), app.leaderboard_profile.avatar_index, clean_text, now_msec, now_unix, chat_name_key)
	var remote_chat_payload = ChatState.remote_message_payload(chat_payload, server_timestamp)
	var updates = ChatState.firebase_write_updates(message_id, app.leaderboard_profile.player_id, remote_chat_payload, server_timestamp, now_unix)
	chat_send_in_flight = true
	chat_send_stage = "patch"
	chat_pending_send_message_id = message_id
	chat_pending_send_text = clean_text
	chat_pending_send_payload = remote_chat_payload
	chat_status_message = "Sending chat message..."
	_chat_upsert_row(message_id, chat_payload)
	app._profile_chat_overlay_surface().clear_chat_draft_message()
	app._profile_chat_overlay_surface()._render_chat_if_visible()
	app._profile_chat_overlay_surface()._chat_scroll_to_latest_deferred()
	var err = OK
	if _leaderboard_web_authless_writes_enabled():
		err = chat_send_request.request(
			_chat_firebase_url("", _leaderboard_authenticated_query("print=silent")),
			PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_PATCH,
			JSON.stringify(updates)
		)
	else:
		chat_send_stage = "gate"
		err = chat_send_request.request(
			_chat_firebase_url("user_write_gates/%s" % app.leaderboard_profile.player_id, _leaderboard_authenticated_query("print=silent")),
			PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_PUT,
			JSON.stringify(updates.get("user_write_gates/%s" % app.leaderboard_profile.player_id, {}))
		)
	if err != OK:
		chat_send_in_flight = false
		chat_send_stage = ""
		_chat_remove_row(message_id)
		_chat_restore_failed_send()
		_chat_note_send_failure("Chat write failed: %s" % error_string(err))
		app._profile_chat_overlay_surface()._render_chat_if_visible()


func _on_chat_send_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var completed_stage = chat_send_stage
	if completed_stage == "gate":
		if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
			chat_send_stage = "message"
			var message_err = chat_send_request.request(
				_chat_firebase_url("messages/%s" % chat_pending_send_message_id, _leaderboard_authenticated_query("print=silent")),
				PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
				HTTPClient.METHOD_PUT,
				JSON.stringify(chat_pending_send_payload)
			)
			if message_err == OK:
				return
			chat_send_in_flight = false
			chat_send_stage = ""
			_chat_remove_row(chat_pending_send_message_id)
			_chat_restore_failed_send()
			_chat_note_send_failure("Chat write failed: %s" % error_string(message_err))
			app._profile_chat_overlay_surface()._render_chat_if_visible()
			return
	chat_send_in_flight = false
	chat_send_stage = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		_chat_remove_row(chat_pending_send_message_id)
		_chat_restore_failed_send()
		_chat_note_send_failure("Chat write failed.")
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if response_code < 200 or response_code >= 300:
		_chat_remove_row(chat_pending_send_message_id)
		_chat_restore_failed_send()
		var detail = _firebase_error_detail(body)
		if response_code == 401 or response_code == 403:
			var rejection_message = "Online chat rejected this message. Please try again later."
			if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required:
				rejection_message = "Complete the approved username transfer before chatting."
			elif LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
				if _attempt_leaderboard_name_recovery():
					rejection_message = "Online chat is checking name recovery. Try again in a moment."
				else:
					rejection_message = "Online chat rejected this name. Ask support to approve name recovery."
			if not detail.is_empty():
				rejection_message = "Online chat rejected this message: %s" % detail
				if not leaderboard_name_transfer_required and not leaderboard_legacy_username_recovery_required and LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS) and detail.to_lower().find("permission") >= 0:
					if leaderboard_name_recovery_in_flight:
						rejection_message = "Online chat is checking name recovery. Try again in a moment."
					else:
						rejection_message = "Online chat rejected this name. Ask support to approve name recovery."
			_chat_note_send_rejected(rejection_message)
			app._profile_chat_overlay_surface()._render_chat_if_visible()
			return
		if not detail.is_empty():
			_chat_note_send_failure("Chat write returned HTTP %s: %s" % [response_code, detail])
		else:
			_chat_note_send_failure("Chat write returned HTTP %s." % response_code)
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	chat_last_send_unix = app._unix_now()
	chat_pending_send_message_id = ""
	chat_pending_send_text = ""
	chat_pending_send_payload.clear()
	chat_status_message = ""
	app._profile_chat_overlay_surface().clear_chat_draft_message()
	app.save_game()
	_chat_stream_connect()
	app._profile_chat_overlay_surface()._render_chat_if_visible()
	app._profile_chat_overlay_surface()._chat_scroll_to_latest_deferred()


func _chat_note_stream_failure(message: String) -> void:
	_chat_stream_disconnect(false)
	chat_stream_retry_unix = app._unix_now() + app.CHAT_STREAM_RETRY_INTERVAL_SECONDS
	chat_stream_next_connect_unix = chat_stream_retry_unix
	chat_status_message = "%s Reconnecting in %s." % [message, GameFormatting.duration(float(app.CHAT_STREAM_RETRY_INTERVAL_SECONDS))]
	app._mark_save_dirty("chat stream retry")


func _chat_stream_disconnect(clear_status = true) -> void:
	_stop_chat_stream_poll_timer()
	if chat_stream_client != null:
		chat_stream_client.close()
	chat_stream_connected = false
	chat_stream_connecting = false
	chat_stream_request_sent = false
	chat_stream_visible_count = 0
	chat_stream_buffer = ""
	chat_stream_event_name = ""
	chat_stream_event_data_lines.clear()
	if clear_status and app.current_screen == "chat":
		chat_status_message = "Chat stream closed."


func _chat_stream_receive_text(text: String) -> void:
	chat_stream_buffer += text.replace("\r\n", "\n").replace("\r", "\n")
	if chat_stream_buffer.length() > app.CHAT_STREAM_MAX_BUFFER_CHARS:
		_chat_note_stream_failure("Chat stream sent too much pending data.")
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	while chat_stream_buffer.find("\n") >= 0:
		var line_end = chat_stream_buffer.find("\n")
		var line = chat_stream_buffer.substr(0, line_end)
		chat_stream_buffer = chat_stream_buffer.substr(line_end + 1)
		_chat_stream_receive_line(line)


func _chat_stream_receive_line(line: String) -> void:
	if line.is_empty():
		_chat_stream_dispatch_event()
		return
	if line.begins_with(":"):
		return
	if line.begins_with("event:"):
		chat_stream_event_name = line.substr(6).strip_edges()
	elif line.begins_with("data:"):
		chat_stream_event_data_lines.append(line.substr(5).strip_edges())


func _chat_stream_dispatch_event() -> void:
	var event_name = chat_stream_event_name
	var data_text = "\n".join(chat_stream_event_data_lines)
	chat_stream_event_name = ""
	chat_stream_event_data_lines.clear()
	if event_name.is_empty() and data_text.is_empty():
		return
	if event_name == "cancel" or event_name == "auth_revoked":
		_chat_note_stream_failure("Chat stream was cancelled.")
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if data_text.is_empty():
		return
	var parsed = _parse_json_silent(data_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_chat_apply_stream_payload(parsed as Dictionary, event_name)
	chat_status_message = "Global chat is live."
	app._profile_chat_overlay_surface()._render_chat_if_visible()


func _chat_apply_stream_payload(payload: Dictionary, event_name = "") -> void:
	var path = str(payload.get("path", "/"))
	var stream_data = payload.get("data", null)
	var is_patch_event = event_name == "patch"
	if path == "/":
		if typeof(stream_data) == TYPE_DICTIONARY and is_patch_event:
			_chat_merge_rows(stream_data as Dictionary)
		elif typeof(stream_data) == TYPE_DICTIONARY:
			_chat_replace_rows(stream_data as Dictionary)
		elif stream_data == null and not is_patch_event:
			chat_rows.clear()
		return
	var clean_path = path.substr(1) if path.begins_with("/") else path
	var parts = clean_path.split("/", false)
	if parts.is_empty():
		return
	var message_id = str(parts[0])
	if message_id.is_empty():
		return
	if stream_data == null:
		_chat_remove_row(message_id)
		return
	if typeof(stream_data) == TYPE_DICTIONARY:
		if is_patch_event and parts.size() == 1:
			var existing = _chat_existing_row(message_id)
			for key in (stream_data as Dictionary).keys():
				existing[str(key)] = (stream_data as Dictionary).get(key)
			_chat_upsert_row(message_id, existing)
		elif parts.size() == 1:
			_chat_upsert_row(message_id, stream_data as Dictionary)
		else:
			var existing = _chat_existing_row(message_id)
			if existing.is_empty():
				return
			existing[str(parts[1])] = stream_data
			_chat_upsert_row(message_id, existing)


func _chat_replace_rows(data: Dictionary) -> void:
	var rows = []
	for raw_message_id in data.keys():
		var entry = data.get(raw_message_id, {})
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var row = _chat_row_from_entry(str(raw_message_id), entry as Dictionary)
		if not row.is_empty():
			rows.append(row)
	chat_rows = rows
	_chat_sort_and_trim_rows()


func _chat_merge_rows(data: Dictionary) -> void:
	for raw_message_id in data.keys():
		var message_id = str(raw_message_id)
		var entry = data.get(raw_message_id, null)
		if entry == null:
			_chat_remove_row(message_id)
		elif typeof(entry) == TYPE_DICTIONARY:
			var existing = _chat_existing_row(message_id)
			for key in (entry as Dictionary).keys():
				existing[str(key)] = (entry as Dictionary).get(key)
			_chat_upsert_row(message_id, existing)
	_chat_sort_and_trim_rows()


func _chat_upsert_row(message_id: String, entry: Dictionary) -> void:
	var row = _chat_row_from_entry(message_id, entry)
	if row.is_empty():
		return
	_chat_remove_row(message_id)
	chat_rows.append(row)
	_chat_sort_and_trim_rows()


func _chat_remove_row(message_id: String) -> void:
	for i in range(chat_rows.size() - 1, -1, -1):
		if str((chat_rows[i] as Dictionary).get("message_id", "")) == message_id:
			chat_rows.remove_at(i)


func _chat_existing_row(message_id: String) -> Dictionary:
	for raw_row in chat_rows:
		var row = raw_row as Dictionary
		if str(row.get("message_id", "")) == message_id:
			return row.duplicate()
	return {}


func _chat_row_from_entry(message_id: String, entry: Dictionary) -> Dictionary:
	var text = ChatState.sanitize_message(str(entry.get("text", "")), app.CHAT_MESSAGE_MAX_CHARS, app.CHAT_CENSORED_WORDS)
	var deleted = bool(entry.get("deleted", false))
	if text.is_empty() and not deleted:
		return {}
	return {
		"message_id": message_id,
			"sender_id": LeaderboardProfile.sanitize_player_id(str(entry.get("sender_id", ""))),
			"name": LeaderboardProfile.sanitize_display_name(str(entry.get("name", "Player")), app.PROFILE_DISPLAY_NAME_MAX_CHARS),
			"name_key": LeaderboardProfile.sanitize_name_key(str(entry.get("name_key", "")), app.PROFILE_NAME_KEY_MAX_CHARS),
			"total_level": maxi(0, int(entry.get("total_level", 0))),
			"avatar_index": LeaderboardProfile.valid_avatar_index(int(entry.get("avatar_index", 0)), ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT),
		"text": text,
		"created_at": maxi(0, int(entry.get("created_at", 0))),
		"created_at_unix": maxi(0, int(entry.get("created_at_unix", 0))),
		"deleted": deleted
	}


func _chat_sort_and_trim_rows() -> void:
	chat_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var created_a = int(a.get("created_at", 0))
		var created_b = int(b.get("created_at", 0))
		if created_a == created_b:
			return str(a.get("message_id", "")) < str(b.get("message_id", ""))
		return created_a < created_b
	)
	var trim_count = maxi(_chat_target_visible_count(), chat_stream_visible_count)
	if chat_rows.size() > trim_count:
		chat_rows = chat_rows.slice(chat_rows.size() - trim_count)


func _chat_target_visible_count() -> int:
	if app._profile_chat_overlay_surface().chat_overlay_visible():
		return app.CHAT_FULL_VISIBLE_COUNT
	return app.CHAT_STRIP_VISIBLE_COUNT


func _chat_latest_message_cursor() -> Dictionary:
	var latest = {"created_at": 0, "message_id": ""}
	for raw_row in chat_rows:
		var row = raw_row as Dictionary
		var created_at = maxi(0, int(row.get("created_at", 0)))
		var message_id = str(row.get("message_id", ""))
		if _chat_cursor_after(created_at, message_id, int(latest.get("created_at", 0)), str(latest.get("message_id", ""))):
			latest["created_at"] = created_at
			latest["message_id"] = message_id
	return latest


func _chat_cursor_after(created_at: int, message_id: String, cursor_created_at: int, cursor_message_id: String) -> bool:
	if created_at != cursor_created_at:
		return created_at > cursor_created_at
	return message_id > cursor_message_id


func _chat_has_unread_messages() -> bool:
	if app._profile_chat_overlay_surface().chat_overlay_visible():
		return false
	var latest = _chat_latest_message_cursor()
	return _chat_cursor_after(
		int(latest.get("created_at", 0)),
		str(latest.get("message_id", "")),
		chat_last_opened_created_at,
		chat_last_opened_message_id
	)


func _chat_mark_opened_to_latest(save_now = false) -> void:
	var latest = _chat_latest_message_cursor()
	var latest_created_at = int(latest.get("created_at", 0))
	var latest_message_id = str(latest.get("message_id", ""))
	if not _chat_cursor_after(latest_created_at, latest_message_id, chat_last_opened_created_at, chat_last_opened_message_id):
		app._profile_chat_overlay_surface()._sync_chat_unread_dot()
		return
	chat_last_opened_created_at = latest_created_at
	chat_last_opened_message_id = latest_message_id
	app._profile_chat_overlay_surface()._sync_chat_unread_dot()
	if save_now:
		app.save_game()
	else:
		app._mark_save_dirty("chat read cursor")


func _firebase_stream_target(url: String) -> Dictionary:
	if not url.begins_with(FIREBASE_URL_SCHEME):
		return {}
	var rest := url.substr(FIREBASE_URL_SCHEME.length())
	var slash_index := rest.find("/")
	if slash_index <= 0:
		return {}
	var host := rest.substr(0, slash_index)
	var path := rest.substr(slash_index)
	return {
		"host": host,
		"path": path
	}


func _chat_note_send_failure(message: String) -> void:
	chat_status_message = "%s Trying again in %s." % [message, GameFormatting.duration(float(app.CHAT_SEND_INTERVAL_SECONDS))]
	app._mark_save_dirty("chat send retry")


func _chat_note_send_rejected(message: String) -> void:
	chat_status_message = message
	app._mark_save_dirty("chat send rejected")


func _chat_restore_failed_send() -> void:
	chat_pending_send_message_id = ""
	chat_pending_send_payload.clear()
	if chat_pending_send_text.is_empty():
		return
	app._profile_chat_overlay_surface().set_chat_draft_message(chat_pending_send_text)
	chat_pending_send_text = ""


func _chat_next_send_seconds() -> int:
	if chat_last_send_unix <= 0:
		return 0
	return maxi(0, app.CHAT_SEND_INTERVAL_SECONDS - (app._unix_now() - chat_last_send_unix))




func _refresh_profile_references() -> void:
	_refresh_local_profile_references()
	if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required:
		return
	if not _leaderboard_firebase_enabled():
		return
	if profile_reference_update_in_flight:
		profile_reference_refresh_queued = true
		return
	if not _leaderboard_write_ready():
		return
	if app.leaderboard_profile.player_id.is_empty():
		return
	var updates = _profile_reference_updates()
	if updates.is_empty():
		return
	var canonical_updates := {}
	var reference_updates := {}
	for raw_path in updates.keys():
		var path := str(raw_path)
		if path.begins_with("leaderboards/v1/name_claims/") or path.begins_with("leaderboards/v1/profiles_by_uid/"):
			canonical_updates[raw_path] = updates.get(raw_path)
		else:
			reference_updates[raw_path] = updates.get(raw_path)
	profile_reference_update_in_flight = true
	profile_reference_pending_updates = reference_updates.duplicate(true)
	profile_reference_update_stage = "canonical" if not canonical_updates.is_empty() else "references"
	var first_updates: Dictionary = canonical_updates if not canonical_updates.is_empty() else reference_updates
	var err = profile_reference_update_request.request(
		_firebase_database_url("", "", _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([LEADERBOARD_HTTP_HEADER_JSON, LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PATCH,
		JSON.stringify(first_updates)
	)
	if err != OK:
		_finish_profile_reference_update()


func _refresh_local_profile_references() -> void:
	for category_id in app.leaderboard_state.rows_by_category.keys():
		var rows = app.leaderboard_state.rows_by_category.get(category_id, [])
		if typeof(rows) != TYPE_ARRAY:
			continue
		for row in rows:
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var row_data = row as Dictionary
			if str(row_data.get("player_id", "")) == app.leaderboard_profile.player_id:
				row_data["name"] = app.leaderboard_profile.display_name
				row_data["name_key"] = app.leaderboard_profile.name_key
				row_data["avatar_index"] = app.leaderboard_profile.avatar_index
	for raw_row in chat_rows:
		var row = raw_row as Dictionary
		if str(row.get("sender_id", "")) == app.leaderboard_profile.player_id:
			row["name"] = app.leaderboard_profile.display_name
			row["name_key"] = app.leaderboard_profile.name_key
			row["total_level"] = SkillState.global_level(app.skills)
			row["avatar_index"] = app.leaderboard_profile.avatar_index
	app._profile_chat_overlay_surface()._refresh_chat_profile_button()
	app._profile_chat_overlay_surface()._update_chat_strip()
	app._profile_chat_overlay_surface()._render_chat_if_visible()


func _profile_reference_updates() -> Dictionary:
	var now_unix = app._unix_now()
	var server_timestamp = _firebase_server_timestamp()
	var updates = {}
	if LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		updates["leaderboards/v1/name_claims/%s" % app.leaderboard_profile.name_key] = {
			"uid": app.leaderboard_profile.player_id,
			"name": app.leaderboard_profile.display_name,
			"name_key": app.leaderboard_profile.name_key,
			"avatar_index": app.leaderboard_profile.avatar_index,
			"created_at": server_timestamp,
			"updated_at": server_timestamp,
			"submitted_at_unix": now_unix
		}
		if not _leaderboard_web_authless_writes_enabled():
			updates["leaderboards/v1/profiles_by_uid/%s" % app.leaderboard_profile.player_id] = _profile_recovery_record(app.leaderboard_profile.display_name, app.leaderboard_profile.name_key, now_unix)
	var category_scores = {}
	var leaderboard_state = app.leaderboard_state
	for raw_category in leaderboard_state.categories():
		var category = raw_category as Dictionary
		var category_id = leaderboard_state.valid_category_id(str(category.get("id", "")))
		if category_id.is_empty():
			continue
		var score = int(app.leaderboard_state.last_submitted_scores_by_category.get(category_id, 0))
		for row in leaderboard_state.rows_for_category(category_id):
			var row_data = row as Dictionary
			if str(row_data.get("player_id", "")) == app.leaderboard_profile.player_id:
				score = maxi(score, int(row_data.get("score", 0)))
		if category_id == LeaderboardState.CATEGORY_TOTAL_LEVEL and leaderboard_state.total_level_score_looks_legacy_xp(score):
			score = leaderboard_state.score_for_category(category_id)
		if score > 0:
			category_scores[category_id] = score
	for raw_category_id in category_scores.keys():
		var category_id = leaderboard_state.valid_category_id(str(raw_category_id))
		var category_key = _leaderboard_category_key(category_id)
		updates["leaderboards/v1/scores/%s/%s" % [category_key, app.leaderboard_profile.player_id]] = {
			"name": app.leaderboard_profile.display_name,
			"name_key": app.leaderboard_profile.name_key,
			"avatar_index": app.leaderboard_profile.avatar_index,
			"score": int(category_scores[category_id]),
			"skill_level": leaderboard_state.skill_level_for_category(category_id),
			"total_xp": leaderboard_state.total_xp_for_category(category_id),
			"updated_at": server_timestamp,
			"submitted_at_unix": now_unix
		}
	for raw_row in chat_rows:
		var row = raw_row as Dictionary
		if str(row.get("sender_id", "")) != app.leaderboard_profile.player_id:
			continue
		if bool(row.get("deleted", false)):
			continue
		var message_id = str(row.get("message_id", ""))
		if message_id.is_empty():
			continue
		updates["global_chat/v1/messages/%s" % message_id] = {
			"sender_id": app.leaderboard_profile.player_id,
			"name": app.leaderboard_profile.display_name,
			"name_key": app.leaderboard_profile.name_key,
			"total_level": SkillState.global_level(app.skills),
			"avatar_index": app.leaderboard_profile.avatar_index,
			"text": ChatState.sanitize_message(str(row.get("text", "")), app.CHAT_MESSAGE_MAX_CHARS, app.CHAT_CENSORED_WORDS),
			"created_at": maxi(0, int(row.get("created_at", 0))),
			"created_at_unix": maxi(0, int(row.get("created_at_unix", 0))),
			"deleted": false
		}
	return updates


