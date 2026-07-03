extends Node
class_name OnlineRuntime

const ChatState = preload("res://scripts/online/chat_state.gd")
const LeaderboardProfile = preload("res://scripts/online/leaderboard_profile.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const SaveStateFiles = preload("res://scripts/save_state/files.gd")
const FIREBASE_URL_SCHEME := "https://"
const FIREBASE_US_HOST_SUFFIX := ".firebaseio.com"
const FIREBASE_REGIONAL_HOST_SUFFIX := ".firebasedatabase.app"
const FIREBASE_HOST_CHARS := "abcdefghijklmnopqrstuvwxyz0123456789-"
const FIREBASE_PLACEHOLDER_DATABASE_URL := "https://YOUR-PROJECT-default-rtdb.firebaseio.com"
const FIREBASE_PLACEHOLDER_WEB_API_KEY := "YOUR_FIREBASE_WEB_API_KEY"

signal cloud_save_loaded(payload)
signal cloud_save_status_changed()
signal leaderboard_rows_changed(category_id)
signal leaderboard_status_changed()
signal chat_rows_changed()
signal chat_status_changed()
signal profile_reference_changed()

var app


func setup(owner) -> void:
	app = owner


func process(delta: float) -> void:
	_process_leaderboard_sync(delta)


func fetch_cloud_save() -> void:
	_fetch_cloud_save()


func upload_cloud_save(payload: Dictionary = {}) -> void:
	_upload_cloud_save(false)


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
	if app.leaderboard_http_built:
		return
	app.leaderboard_http_built = true
	_build_leaderboard_http()


func _build_leaderboard_http() -> void:
	app.leaderboard_auth_request = HTTPRequest.new()
	app.leaderboard_auth_request.timeout = 15.0
	app.leaderboard_auth_request.request_completed.connect(_on_leaderboard_auth_completed)
	add_child(app.leaderboard_auth_request)
	app.google_auth_exchange_request = HTTPRequest.new()
	app.google_auth_exchange_request.timeout = 15.0
	app.google_auth_exchange_request.request_completed.connect(_on_google_auth_exchange_completed)
	add_child(app.google_auth_exchange_request)
	app.cloud_save_fetch_request = HTTPRequest.new()
	app.cloud_save_fetch_request.timeout = 15.0
	app.cloud_save_fetch_request.request_completed.connect(_on_cloud_save_fetch_completed)
	add_child(app.cloud_save_fetch_request)
	app.cloud_save_upload_request = HTTPRequest.new()
	app.cloud_save_upload_request.timeout = 15.0
	app.cloud_save_upload_request.request_completed.connect(_on_cloud_save_upload_completed)
	add_child(app.cloud_save_upload_request)
	app.leaderboard_fetch_request = HTTPRequest.new()
	app.leaderboard_fetch_request.timeout = 15.0
	app.leaderboard_fetch_request.request_completed.connect(_on_leaderboard_fetch_completed)
	add_child(app.leaderboard_fetch_request)
	app.leaderboard_total_xp_fetch_request = HTTPRequest.new()
	app.leaderboard_total_xp_fetch_request.timeout = 15.0
	app.leaderboard_total_xp_fetch_request.request_completed.connect(_on_leaderboard_total_xp_fetch_completed)
	add_child(app.leaderboard_total_xp_fetch_request)
	app.leaderboard_submit_request = HTTPRequest.new()
	app.leaderboard_submit_request.timeout = 15.0
	app.leaderboard_submit_request.request_completed.connect(_on_leaderboard_submit_completed)
	add_child(app.leaderboard_submit_request)
	app.leaderboard_name_claim_request = HTTPRequest.new()
	app.leaderboard_name_claim_request.timeout = 15.0
	app.leaderboard_name_claim_request.request_completed.connect(_on_leaderboard_name_claim_completed)
	add_child(app.leaderboard_name_claim_request)
	app.leaderboard_name_recovery_request = HTTPRequest.new()
	app.leaderboard_name_recovery_request.timeout = 15.0
	app.leaderboard_name_recovery_request.request_completed.connect(_on_leaderboard_name_recovery_completed)
	add_child(app.leaderboard_name_recovery_request)
	app.profile_reference_update_request = HTTPRequest.new()
	app.profile_reference_update_request.timeout = 15.0
	app.profile_reference_update_request.request_completed.connect(_on_profile_reference_update_completed)
	add_child(app.profile_reference_update_request)
	app.chat_stream_client = HTTPClient.new()
	app.chat_fetch_request = HTTPRequest.new()
	app.chat_fetch_request.timeout = 15.0
	app.chat_fetch_request.request_completed.connect(_on_chat_fetch_completed)
	add_child(app.chat_fetch_request)
	app.chat_send_request = HTTPRequest.new()
	app.chat_send_request.timeout = 15.0
	app.chat_send_request.request_completed.connect(_on_chat_send_completed)
	add_child(app.chat_send_request)
	app.chat_stream_poll_timer = Timer.new()
	app.chat_stream_poll_timer.wait_time = app.CHAT_STREAM_POLL_INTERVAL_SECONDS
	app.chat_stream_poll_timer.autostart = false
	app.chat_stream_poll_timer.timeout.connect(_process_chat_live_sync.bind(app.CHAT_STREAM_POLL_INTERVAL_SECONDS))
	add_child(app.chat_stream_poll_timer)


func _leaderboard_firebase_enabled() -> bool:
	return not _leaderboard_firebase_base_url().is_empty() and not _leaderboard_firebase_api_key().is_empty()


func _leaderboard_load_firebase_config() -> void:
	if app.leaderboard_config_loaded:
		return
	app.leaderboard_config_loaded = true
	if not FileAccess.file_exists(app.FIREBASE_LOCAL_CONFIG_PATH):
		return
	var file = FileAccess.open(app.FIREBASE_LOCAL_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = _parse_json_silent(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Online leaderboard config must be a JSON object.")
		return
	var firebase_config = parsed as Dictionary
	app.leaderboard_config_database_url = str(firebase_config.get("database_url", "")).strip_edges()
	app.leaderboard_config_web_api_key = str(firebase_config.get("web_api_key", "")).strip_edges()
	app.google_auth_web_client_id = str(firebase_config.get(app.GOOGLE_AUTH_WEB_CLIENT_ID_CONFIG_KEY, "")).strip_edges()


func _parse_json_silent(raw_text: String) -> Variant:
	var json := JSON.new()
	if json.parse(raw_text) != OK:
		return null
	return json.data


func _leaderboard_firebase_base_url() -> String:
	_leaderboard_load_firebase_config()
	return _firebase_sanitized_database_url(app.leaderboard_config_database_url, app.FIREBASE_DATABASE_URL)


func _leaderboard_firebase_api_key() -> String:
	_leaderboard_load_firebase_config()
	return _firebase_sanitized_api_key(app.leaderboard_config_web_api_key, app.FIREBASE_WEB_API_KEY)


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
	return _firebase_database_url(app.LEADERBOARD_FIREBASE_ROOT, path, query)


func _chat_firebase_url(path = "", query = "") -> String:
	return _firebase_database_url(app.CHAT_FIREBASE_ROOT, path, query)


func _cloud_save_firebase_url(path = "", query = "") -> String:
	return _firebase_database_url(app.CLOUD_SAVE_FIREBASE_ROOT, path, query)


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
	var token = app.leaderboard_auth_id_token.strip_edges()
	if token.is_empty():
		return query
	var auth_param = "auth=%s" % token.uri_encode()
	if query.is_empty():
		return auth_param
	return "%s&%s" % [query, auth_param]


func _firebase_server_timestamp() -> Dictionary:
	return {".sv": "timestamp"}


func _leaderboard_web_authless_writes_enabled() -> bool:
	return OS.has_feature("web")


func _ensure_leaderboard_player_id() -> void:
	if app.leaderboard_player_id.is_empty():
		app.leaderboard_player_id = LeaderboardProfile.make_player_id()
		app._mark_save_dirty("leaderboard player id")


func _leaderboard_write_ready() -> bool:
	if _leaderboard_web_authless_writes_enabled():
		_ensure_leaderboard_player_id()
		return not app.leaderboard_player_id.is_empty()
	return _leaderboard_ensure_auth()


func _leaderboard_category_key(category_id: String) -> String:
	return app._leaderboard_state().valid_category_id(category_id).replace(":", "__")


func _leaderboard_auth_ready() -> bool:
	return not app.leaderboard_auth_id_token.is_empty() and not app.leaderboard_player_id.is_empty() and app.leaderboard_auth_expires_unix > app._unix_now() + app.LEADERBOARD_AUTH_REFRESH_MARGIN_SECONDS


func _leaderboard_auth_retry_wait_seconds() -> int:
	return maxi(0, app.leaderboard_auth_retry_after_unix - app._unix_now())


func _leaderboard_note_auth_failure(message: String, clear_refresh_token = false) -> void:
	app.leaderboard_status_message = "%s Trying again in %s." % [message, GameFormatting.duration(float(app.LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS))]
	app.leaderboard_auth_retry_after_unix = app._unix_now() + app.LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS
	if clear_refresh_token:
		app.leaderboard_auth_refresh_token = ""
		app.save_game()
	else:
		app._mark_save_dirty("leaderboard auth retry")


func _leaderboard_note_submit_failure(message: String) -> void:
	app.leaderboard_status_message = "%s Trying again in %s." % [message, GameFormatting.duration(float(app.LEADERBOARD_SUBMIT_INTERVAL_SECONDS))]
	app.leaderboard_last_submit_unix = app._unix_now()
	app.leaderboard_last_submit_payload_categories.clear()
	app.leaderboard_pending_score_updates.clear()
	app.leaderboard_pending_repair_publish_version = 0
	app.leaderboard_submit_stage = ""
	app._mark_save_dirty("leaderboard submit retry")


func _leaderboard_note_fetch_failure(category_id: String, message: String) -> void:
	var valid_id = app._leaderboard_state().valid_category_id(category_id)
	app.leaderboard_fetch_retry_unix_by_category[valid_id] = app._unix_now()
	app.leaderboard_status_message = "%s Trying again in %s." % [message, GameFormatting.duration(float(app.LEADERBOARD_FETCH_INTERVAL_SECONDS))]
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
		app.leaderboard_status_message = "Online services are not connected yet."
		return false
	if _leaderboard_auth_ready():
		return true
	if app.leaderboard_auth_request == null or not is_instance_valid(app.leaderboard_auth_request):
		app.leaderboard_status_message = "Online login is still starting."
		return false
	if app.leaderboard_auth_in_flight:
		return false
	var retry_wait = _leaderboard_auth_retry_wait_seconds()
	if retry_wait > 0:
		app.leaderboard_status_message = "Online login is cooling down for %s." % GameFormatting.duration(float(retry_wait))
		return false
	var api_key = _leaderboard_firebase_api_key()
	if api_key.is_empty():
		app.leaderboard_status_message = "Online services are not connected yet."
		return false
	app.leaderboard_auth_in_flight = true
	if not app.leaderboard_auth_refresh_token.is_empty():
		app.leaderboard_auth_mode = "refresh"
		app.leaderboard_status_message = "Refreshing leaderboard login..."
		var body = "grant_type=refresh_token&refresh_token=%s" % app.leaderboard_auth_refresh_token.uri_encode()
		var err = app.leaderboard_auth_request.request(
			app.FIREBASE_AUTH_REFRESH_URL % api_key.uri_encode(),
			PackedStringArray([app.LEADERBOARD_HTTP_HEADER_FORM, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_POST,
			body
		)
		if err == OK:
			return false
	else:
		app.leaderboard_auth_mode = "sign_up"
		app.leaderboard_status_message = "Creating leaderboard login..."
		var err = app.leaderboard_auth_request.request(
			app.FIREBASE_AUTH_SIGN_UP_URL % api_key.uri_encode(),
			PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_POST,
			JSON.stringify({"returnSecureToken": true})
		)
		if err == OK:
			return false
	app.leaderboard_auth_in_flight = false
	app.leaderboard_auth_mode = ""
	_leaderboard_note_auth_failure("Online login failed to start.")
	return false


func _leaderboard_retry_chat_auth_without_refresh() -> bool:
	if app.chat_pending_send_after_auth.is_empty():
		return false
	if app.leaderboard_auth_refresh_token.is_empty():
		return false
	app.leaderboard_auth_refresh_token = ""
	app.leaderboard_auth_id_token = ""
	app.leaderboard_auth_expires_unix = 0
	app.leaderboard_auth_retry_after_unix = 0
	app.leaderboard_status_message = "Creating fresh chat login..."
	app.save_game()
	var auth_ready = _leaderboard_ensure_auth()
	app._profile_chat_overlay_surface()._render_chat_if_visible()
	return auth_ready or app.leaderboard_auth_in_flight


func _google_auth_available() -> bool:
	_ensure_google_auth_plugin()
	return app.google_auth_plugin != null and is_instance_valid(app.google_auth_plugin) and app.google_auth_plugin.has_method("sign_in")


func _ensure_google_auth_plugin() -> void:
	if app.google_auth_plugin != null and is_instance_valid(app.google_auth_plugin):
		return
	if OS.get_name() != "Android":
		return
	if not Engine.has_singleton(app.GOOGLE_AUTH_ANDROID_SINGLETON):
		return
	app.google_auth_plugin = Engine.get_singleton(app.GOOGLE_AUTH_ANDROID_SINGLETON)
	if app.google_auth_plugin == null or app.google_auth_plugin_connected:
		return
	if app.google_auth_plugin.has_signal("google_sign_in_succeeded"):
		app.google_auth_plugin.connect("google_sign_in_succeeded", _on_google_sign_in_succeeded)
	if app.google_auth_plugin.has_signal("google_sign_in_failed"):
		app.google_auth_plugin.connect("google_sign_in_failed", _on_google_sign_in_failed)
	app.google_auth_plugin_connected = true


func _start_google_account_sign_in() -> void:
	ensure_leaderboard_http()
	if app.google_auth_in_flight or app.leaderboard_auth_in_flight:
		return
	if not LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		app.google_auth_status_message = "Save a username before connecting Google."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not _leaderboard_firebase_enabled():
		app.google_auth_status_message = "Online services are not connected yet."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if app.google_auth_web_client_id.is_empty():
		app.google_auth_status_message = "Google sign-in needs google_web_client_id in firebase-leaderboard-config.json."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not _google_auth_available():
		app.google_auth_status_message = "Google sign-in is not available in this build yet."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	app.google_auth_in_flight = true
	app.google_auth_status_message = "Opening Google sign-in..."
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
	var err = OK
	if app.google_auth_plugin.has_method("sign_in_with_client_id"):
		err = int(app.google_auth_plugin.call("sign_in_with_client_id", app.google_auth_web_client_id))
	else:
		err = int(app.google_auth_plugin.call("sign_in"))
	if err != OK:
		app.google_auth_in_flight = false
		app.google_auth_status_message = "Google sign-in failed to start: %s" % error_string(err)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_google_sign_in_succeeded(id_token: String, account_email = "", display_name = "") -> void:
	app.google_auth_in_flight = false
	var clean_token = id_token.strip_edges()
	if clean_token.is_empty():
		app.google_auth_status_message = "Google sign-in returned an empty token."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	_exchange_google_id_token_for_firebase(clean_token, account_email, display_name)


func _on_google_sign_in_failed(message = "") -> void:
	app.google_auth_in_flight = false
	var detail = str(message).strip_edges()
	app.google_auth_status_message = _friendly_google_auth_failure_message(detail)
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
	if app.google_auth_exchange_request == null or not is_instance_valid(app.google_auth_exchange_request):
		app.google_auth_status_message = "Online login is still starting."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var api_key = _leaderboard_firebase_api_key()
	if api_key.is_empty():
		app.google_auth_status_message = "Online services are not connected yet."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	app.leaderboard_auth_in_flight = true
	app.leaderboard_auth_mode = "google"
	app.leaderboard_auth_provider = "google"
	app.google_auth_status_message = "Connecting Google account..."
	var body = {
		"postBody": "id_token=%s&providerId=%s" % [google_id_token.uri_encode(), app.GOOGLE_AUTH_PROVIDER_ID.uri_encode()],
		"requestUri": app.GOOGLE_AUTH_REQUEST_URI,
		"returnIdpCredential": true,
		"returnSecureToken": true
	}
	if not app.leaderboard_auth_id_token.strip_edges().is_empty():
		body["idToken"] = app.leaderboard_auth_id_token.strip_edges()
	var err = app.google_auth_exchange_request.request(
		app.FIREBASE_AUTH_SIGN_IN_WITH_IDP_URL % api_key.uri_encode(),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)
	if err != OK:
		app.leaderboard_auth_in_flight = false
		app.leaderboard_auth_mode = ""
		app.google_auth_status_message = "Google account link failed to start: %s" % error_string(err)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not str(display_name).strip_edges().is_empty() and not app.leaderboard_profile_claimed:
		app.leaderboard_display_name = LeaderboardProfile.sanitize_display_name(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS)
		app._mark_save_dirty("google account display name")
	elif not str(account_email).strip_edges().is_empty():
		app.cloud_save_status_message = "Signing in as %s" % str(account_email).strip_edges()
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_google_auth_exchange_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	app.leaderboard_auth_in_flight = false
	app.leaderboard_auth_mode = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		app.google_auth_status_message = "Google account login failed."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if response_code < 200 or response_code >= 300:
		var detail = _firebase_error_detail(body)
		app.google_auth_status_message = "Google account login returned HTTP %s%s" % [response_code, "." if detail.is_empty() else ": %s" % detail]
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		app.google_auth_status_message = "Google account login returned invalid JSON."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	_apply_firebase_auth_response(parsed as Dictionary, "google")
	app.google_auth_status_message = "Google account connected."
	app.cloud_save_dirty = true
	_fetch_cloud_save()
	if app._leaderboard_state().submit_ready():
		_leaderboard_submit_scores()
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _apply_firebase_auth_response(data: Dictionary, provider: String) -> bool:
	var id_token = str(data.get("idToken", data.get("id_token", "")))
	var refresh_token = str(data.get("refreshToken", data.get("refresh_token", "")))
	var local_id = str(data.get("localId", data.get("user_id", "")))
	var expires_in = maxi(0, int(data.get("expiresIn", data.get("expires_in", 0))))
	if id_token.is_empty() or refresh_token.is_empty() or local_id.is_empty() or expires_in <= 0:
		_leaderboard_note_auth_failure("Online login was incomplete.", provider == "refresh")
		return false
	app.leaderboard_auth_id_token = id_token
	app.leaderboard_auth_refresh_token = refresh_token
	app.leaderboard_auth_expires_unix = app._unix_now() + expires_in
	app.leaderboard_auth_retry_after_unix = 0
	app.leaderboard_auth_provider = provider if not provider.is_empty() else "anonymous"
	app.leaderboard_player_id = LeaderboardProfile.sanitize_player_id(local_id)
	if app.leaderboard_player_id.is_empty():
		_leaderboard_note_auth_failure("Online login id was invalid.", provider == "refresh")
		return false
	app.leaderboard_status_message = "Online login ready."
	app.save_game()
	return true


func _cloud_save_account_ready() -> bool:
	return _leaderboard_auth_ready() and app.leaderboard_auth_provider == "google"


func _cloud_save_status_text() -> String:
	if not _leaderboard_firebase_enabled():
		return "Cloud save is offline until Firebase is configured."
	if app.leaderboard_auth_provider != "google":
		if not LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
			return "Save a username before connecting Google."
		if app.google_auth_status_message.is_empty():
			return "Connect Google to back up progress to your account."
		return app.google_auth_status_message
	if app.cloud_save_upload_in_flight:
		return "Uploading cloud save..."
	if app.cloud_save_fetch_in_flight:
		return "Checking cloud save..."
	if not app.cloud_save_status_message.is_empty():
		return app.cloud_save_status_message
	return "Google connected. Progress saves to your account automatically."


func _cloud_save_summary(payload: Dictionary) -> Dictionary:
	return {
		"save_schema_version": int(payload.get("save_schema_version", 0)),
		"saved_at": maxi(0, int(payload.get("saved_at", 0))),
		"total_skill_xp": app._save_runtime()._save_total_skill_xp_evidence(payload),
		"total_level": app._global_level()
	}


func _cloud_save_payload_json(payload: Dictionary) -> String:
	var text := JSON.stringify(payload)
	if text.length() > app.CLOUD_SAVE_MAX_PAYLOAD_CHARS:
		return ""
	return text


func _cloud_save_record(payload: Dictionary, now: int) -> Dictionary:
	return {
		"uid": app.leaderboard_player_id,
		"updated_at": _firebase_server_timestamp(),
		"updated_at_unix": now,
		"save_schema_version": int(payload.get("save_schema_version", app.SAVE_SCHEMA_VERSION)),
		"saved_at": maxi(0, int(payload.get("saved_at", now))),
		"total_skill_xp": app._save_runtime()._save_total_skill_xp_evidence(payload),
		"total_level": app._global_level(),
		"payload_json": _cloud_save_payload_json(payload)
	}


func _fetch_cloud_save() -> void:
	ensure_leaderboard_http()
	if app.cloud_save_fetch_in_flight:
		return
	if not _cloud_save_account_ready():
		app.cloud_save_status_message = "Connect Google before checking cloud save."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	app.cloud_save_fetch_in_flight = true
	app.cloud_save_status_message = "Checking cloud save..."
	var err = app.cloud_save_fetch_request.request(
		_cloud_save_firebase_url("users/%s" % app.leaderboard_player_id, _leaderboard_authenticated_query()),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		app.cloud_save_fetch_in_flight = false
		app.cloud_save_status_message = "Cloud save check failed: %s" % error_string(err)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _upload_cloud_save(force = true) -> void:
	ensure_leaderboard_http()
	if app.cloud_save_fetch_in_flight:
		return
	if app.cloud_save_upload_in_flight:
		return
	if not _cloud_save_account_ready():
		if force:
			app.cloud_save_status_message = "Connect Google before uploading cloud save."
			app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if not app.cloud_save_remote_checked:
		_fetch_cloud_save()
		return
	var now = app._unix_now()
	if not force and app.cloud_save_last_upload_unix > 0 and now - app.cloud_save_last_upload_unix < app.CLOUD_SAVE_UPLOAD_INTERVAL_SECONDS:
		return
	var payload = app._save_runtime()._save_payload(now)
	var record = _cloud_save_record(payload, now)
	if str(record.get("payload_json", "")).is_empty():
		app.cloud_save_status_message = "Cloud save is too large to upload."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	app.cloud_save_upload_in_flight = true
	app.cloud_save_status_message = "Uploading cloud save..."
	var err = app.cloud_save_upload_request.request(
		_cloud_save_firebase_url("users/%s" % app.leaderboard_player_id, _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PUT,
		JSON.stringify(record)
	)
	if err != OK:
		app.cloud_save_upload_in_flight = false
		app.cloud_save_status_message = "Cloud save upload failed: %s" % error_string(err)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_cloud_save_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	app.cloud_save_fetch_in_flight = false
	app.cloud_save_last_fetch_unix = app._unix_now()
	if result != HTTPRequest.RESULT_SUCCESS:
		app.cloud_save_status_message = "Cloud save check failed."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if response_code == 404:
		app.cloud_save_status_message = "No cloud save found yet."
		app.cloud_save_remote_checked = true
		app.cloud_save_last_remote_summary.clear()
		app.cloud_save_last_remote_payload.clear()
		if app.cloud_save_dirty:
			_upload_cloud_save(false)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if response_code < 200 or response_code >= 300:
		app.cloud_save_status_message = "Cloud save check returned HTTP %s." % response_code
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	if parsed == null:
		app.cloud_save_status_message = "No cloud save found yet."
		app.cloud_save_remote_checked = true
		app.cloud_save_last_remote_summary.clear()
		app.cloud_save_last_remote_payload.clear()
		if app.cloud_save_dirty:
			_upload_cloud_save(false)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if typeof(parsed) != TYPE_DICTIONARY:
		app.cloud_save_status_message = "Cloud save record was invalid."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	var record = parsed as Dictionary
	var payload_text = str(record.get("payload_json", ""))
	var payload = _parse_json_silent(payload_text)
	if typeof(payload) != TYPE_DICTIONARY:
		app.cloud_save_status_message = "Cloud save payload was invalid."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	app.cloud_save_last_remote_payload = payload as Dictionary
	app.cloud_save_last_remote_summary = _cloud_save_summary(app.cloud_save_last_remote_payload)
	app.cloud_save_remote_checked = true
	var remote_xp = int(app.cloud_save_last_remote_summary.get("total_skill_xp", 0))
	var local_xp = app._save_runtime()._save_total_skill_xp_evidence(app._save_runtime()._save_payload(app._unix_now()))
	if _cloud_save_payload_should_replace_local(app.cloud_save_last_remote_payload):
		_restore_cloud_save_payload(app.cloud_save_last_remote_payload)
		app.cloud_save_dirty = false
		app.cloud_save_status_message = "Cloud save restored. Remote XP: %s." % GameFormatting.compact_number(float(remote_xp), 4)
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if app.cloud_save_dirty:
		_upload_cloud_save(false)
	app.cloud_save_status_message = "Cloud save found. Remote XP: %s. This device XP: %s." % [GameFormatting.compact_number(float(remote_xp), 4), GameFormatting.compact_number(float(local_xp), 4)]
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _on_cloud_save_upload_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	app.cloud_save_upload_in_flight = false
	if result != HTTPRequest.RESULT_SUCCESS:
		app.cloud_save_status_message = "Cloud save upload failed."
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	if response_code < 200 or response_code >= 300:
		var detail = _firebase_error_detail(body)
		app.cloud_save_status_message = "Cloud save upload returned HTTP %s%s" % [response_code, "." if detail.is_empty() else ": %s" % detail]
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		return
	app.cloud_save_last_upload_unix = app._unix_now()
	app.cloud_save_dirty = false
	app.cloud_save_status_message = "Cloud save uploaded."
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()


func _process_cloud_save_sync() -> void:
	if app.leaderboard_auth_provider == "google" and not _cloud_save_account_ready():
		_leaderboard_ensure_auth()
		return
	if _cloud_save_account_ready() and not app.cloud_save_remote_checked and not app.cloud_save_fetch_in_flight:
		_fetch_cloud_save()
		return
	if app.cloud_save_dirty:
		_upload_cloud_save(false)


func _cloud_save_payload_should_replace_local(remote_payload: Dictionary) -> bool:
	return SaveStateFiles.should_replace_best_save(app._save_runtime()._save_payload(app._unix_now()), remote_payload, app.skill_defs)


func _restore_cloud_save_payload(remote_payload: Dictionary) -> void:
	var auth_id_token: String = app.leaderboard_auth_id_token
	var auth_refresh_token: String = app.leaderboard_auth_refresh_token
	var auth_expires_unix: int = app.leaderboard_auth_expires_unix
	var player_id: String = app.leaderboard_player_id
	var restored_payload := remote_payload.duplicate(true)
	restored_payload["leaderboard_player_id"] = player_id
	restored_payload["leaderboard_auth_provider"] = "google"
	restored_payload["leaderboard_auth_refresh_token"] = auth_refresh_token
	restored_payload["leaderboard_auth_retry_after_unix"] = 0
	var save_runtime = app._save_runtime()
	save_runtime._clear_pending_save_restore_work()
	save_runtime._init_state()
	save_runtime._load_game_core(restored_payload)
	save_runtime.pending_save_restore_data = restored_payload
	save_runtime._restore_boot_render_save_fields(restored_payload)
	save_runtime._load_game_secondary_restore()
	save_runtime._apply_post_load_simulation()
	app.leaderboard_auth_id_token = auth_id_token
	app.leaderboard_auth_refresh_token = auth_refresh_token
	app.leaderboard_auth_expires_unix = auth_expires_unix
	app.leaderboard_auth_provider = "google"
	app.leaderboard_player_id = player_id
	app.cloud_save_remote_checked = true
	app.save_game()
	app._update_ui(0.0, true)


func _leaderboard_fetch_category(category_id: String, allow_recent_refresh = false) -> void:
	ensure_leaderboard_http()
	var leaderboard_state = app._leaderboard_state()
	var valid_id = leaderboard_state.valid_category_id(category_id)
	if not _leaderboard_firebase_enabled():
		app.leaderboard_status_message = "Online services are not connected yet."
		return
	var now = app._unix_now()
	var last_success_fetch = int(app.leaderboard_fetch_unix_by_category.get(valid_id, 0))
	var last_failed_fetch = int(app.leaderboard_fetch_retry_unix_by_category.get(valid_id, 0))
	var last_fetch = maxi(last_success_fetch, last_failed_fetch)
	if not allow_recent_refresh and last_fetch > 0 and now - last_fetch < app.LEADERBOARD_FETCH_INTERVAL_SECONDS:
		return
	if app.leaderboard_fetch_in_flight or app.leaderboard_total_xp_fetch_in_flight:
		return
	app.leaderboard_fetch_in_flight = true
	app.leaderboard_fetch_category_id = valid_id
	app.leaderboard_status_message = "Loading %s..." % leaderboard_state.category_label(valid_id)
	var category_key = _leaderboard_category_key(valid_id)
	var query = "orderBy=%%22score%%22&limitToLast=%s" % app.LEADERBOARD_TOP_COUNT
	var err = app.leaderboard_fetch_request.request(
		_leaderboard_firebase_url("scores/%s" % category_key, query),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		app.leaderboard_fetch_in_flight = false
		app.leaderboard_fetch_category_id = ""
		_leaderboard_note_fetch_failure(valid_id, "Leaderboard read failed: %s" % error_string(err))


func _leaderboard_finalize_fetch_rows(category_id: String, rows: Array) -> void:
	if category_id == app.LEADERBOARD_CATEGORY_TOTAL_LEVEL:
		app.leaderboard_pending_total_rows = rows
		var query = "orderBy=%%22score%%22&limitToLast=%s" % app.LEADERBOARD_TOP_COUNT
		app.leaderboard_total_xp_fetch_in_flight = true
		var err = app.leaderboard_total_xp_fetch_request.request(
			_leaderboard_firebase_url("scores/%s" % app.LEADERBOARD_CATEGORY_TOTAL_XP_COMPAT, query),
			PackedStringArray([app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_GET
		)
		if err == OK:
			return
		app.leaderboard_total_xp_fetch_in_flight = false
		app.leaderboard_pending_total_rows = []
	_leaderboard_store_fetch_rows(category_id, rows)


func _leaderboard_store_fetch_rows(category_id: String, rows: Array) -> void:
	app.leaderboard_rows_by_category[category_id] = rows
	app.leaderboard_fetch_unix_by_category[category_id] = app._unix_now()
	var had_retry_cooldown = app.leaderboard_fetch_retry_unix_by_category.has(category_id)
	if had_retry_cooldown:
		app.leaderboard_fetch_retry_unix_by_category.erase(category_id)
		app._mark_save_dirty("leaderboard retry cleared")
	app.leaderboard_status_message = "Leaderboard loaded."
	if app.current_screen == "leaderboard" and category_id == app.leaderboard_category_id:
		app._refresh_leaderboard_if_visible()


func _on_leaderboard_total_xp_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	app.leaderboard_total_xp_fetch_in_flight = false
	var rows = app.leaderboard_pending_total_rows
	app.leaderboard_pending_total_rows = []
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
			row["score_text"] = app._leaderboard_state().format_score(app.LEADERBOARD_CATEGORY_TOTAL_LEVEL, int(row.get("score", 0)), 0, int(row.get("total_xp", 0)))
			rows[i] = row
	_leaderboard_store_fetch_rows(app.LEADERBOARD_CATEGORY_TOTAL_LEVEL, rows)


func _leaderboard_submit_scores() -> void:
	if app.god_mode_save_tainted:
		app.leaderboard_status_message = "Test save: leaderboard publishing paused."
		return
	if not _leaderboard_firebase_enabled():
		app.leaderboard_status_message = "Online services are not connected yet."
		return
	if not _leaderboard_write_ready():
		return
	if not LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		app.leaderboard_status_message = "Save a unique leaderboard name before publishing."
		return
	var leaderboard_state = app._leaderboard_state()
	if app.leaderboard_submit_in_flight or not leaderboard_state.submit_ready():
		return
	_ensure_leaderboard_player_id()
	var repair_publish_due = leaderboard_state.repair_publish_due()
	var now_unix = app._unix_now()
	var server_timestamp = _firebase_server_timestamp()
	var score_updates = {}
	app.leaderboard_last_submit_payload_categories.clear()
	app.leaderboard_pending_repair_publish_version = 0
	for raw_category in leaderboard_state.categories():
		var category = raw_category as Dictionary
		var category_id = leaderboard_state.valid_category_id(str(category.get("id", "")))
		if category_id.is_empty():
			continue
		var score = maxi(0, leaderboard_state.score_for_category(category_id))
		var last_score = int(app.leaderboard_last_submitted_scores_by_category.get(category_id, 0))
		if score <= 0:
			continue
		if not repair_publish_due and score <= last_score:
			if not (category_id == app.LEADERBOARD_CATEGORY_TOTAL_LEVEL and leaderboard_state.score() > app.leaderboard_last_submitted_total_xp):
				continue
		var category_key = _leaderboard_category_key(category_id)
		score_updates["scores/%s/%s" % [category_key, app.leaderboard_player_id]] = {
			"name": app.leaderboard_display_name,
			"name_key": app.leaderboard_name_key,
			"avatar_index": app.leaderboard_avatar_index,
			"score": score,
			"skill_level": leaderboard_state.skill_level_for_category(category_id),
			"total_xp": leaderboard_state.total_xp_for_category(category_id),
			"updated_at": server_timestamp,
			"submitted_at_unix": now_unix
		}
		app.leaderboard_last_submit_payload_categories.append(category_id)
	if score_updates.is_empty():
		app.leaderboard_last_submitted_score = leaderboard_state.score()
		if repair_publish_due:
			app.leaderboard_repair_publish_version = app.LEADERBOARD_REPAIR_PUBLISH_VERSION
		app._mark_save_dirty("leaderboard submit checkpoint")
		return
	app.leaderboard_pending_score_updates = score_updates
	if repair_publish_due:
		app.leaderboard_pending_repair_publish_version = app.LEADERBOARD_REPAIR_PUBLISH_VERSION
	app.leaderboard_submit_stage = "gate"
	var gate_payload = {
		"updated_at": server_timestamp,
		"submitted_at_unix": now_unix
	}
	app.leaderboard_submit_in_flight = true
	app.leaderboard_status_message = "Publishing leaderboard scores..."
	var err = app.leaderboard_submit_request.request(
		_leaderboard_firebase_url("player_write_gates/%s" % app.leaderboard_player_id, _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PUT,
		JSON.stringify(gate_payload)
	)
	if err != OK:
		app.leaderboard_submit_in_flight = false
		app.leaderboard_submit_stage = ""
		app.leaderboard_pending_score_updates.clear()
		app.leaderboard_pending_repair_publish_version = 0
		_leaderboard_note_submit_failure("Leaderboard write failed: %s" % error_string(err))


func _process_leaderboard_sync(delta: float) -> void:
	app.leaderboard_process_seconds += delta
	if app.leaderboard_process_seconds < app.LEADERBOARD_PROCESS_INTERVAL_SECONDS:
		return
	app.leaderboard_process_seconds = 0.0
	if not _leaderboard_firebase_enabled():
		return
	if app.current_screen == "leaderboard":
		_leaderboard_fetch_category(app.leaderboard_category_id)
	if app._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		_chat_stream_connect()
	if app._leaderboard_state().submit_ready():
		_leaderboard_submit_scores()
	_process_cloud_save_sync()


func _on_leaderboard_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var category_id = app.leaderboard_fetch_category_id
	app.leaderboard_fetch_in_flight = false
	app.leaderboard_fetch_category_id = ""
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
				"score_text": app._leaderboard_state().format_score(category_id, score, maxi(0, int(row.get("skill_level", 0))), maxi(0, int(row.get("total_xp", 0)))),
				"avatar_index": LeaderboardProfile.valid_avatar_index(int(row.get("avatar_index", 0)), ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT),
				"is_player": player_id == app.leaderboard_player_id
			})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a = int(a.get("score", 0))
		var score_b = int(b.get("score", 0))
		if score_a == score_b:
			return str(a.get("name", "")) < str(b.get("name", ""))
		return score_a > score_b
	)
	if rows.size() > app.LEADERBOARD_TOP_COUNT:
		rows = rows.slice(0, app.LEADERBOARD_TOP_COUNT)
	_leaderboard_finalize_fetch_rows(category_id, rows)


func _on_leaderboard_auth_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var mode = app.leaderboard_auth_mode
	app.leaderboard_auth_in_flight = false
	app.leaderboard_auth_mode = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		if mode == "refresh" and _leaderboard_retry_chat_auth_without_refresh():
			return
		_leaderboard_note_auth_failure("Online login failed.", mode == "refresh")
		return
	if response_code < 200 or response_code >= 300:
		var detail = _firebase_error_detail(body)
		if mode == "refresh" and _leaderboard_retry_chat_auth_without_refresh():
			return
		if detail.is_empty():
			_leaderboard_note_auth_failure("Online login returned HTTP %s." % response_code, mode == "refresh")
		else:
			_leaderboard_note_auth_failure("Online login returned HTTP %s: %s" % [response_code, detail], mode == "refresh")
		return
	var parsed = _parse_json_silent(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		if mode == "refresh" and _leaderboard_retry_chat_auth_without_refresh():
			return
		_leaderboard_note_auth_failure("Online login returned invalid JSON.")
		return
	if not _apply_firebase_auth_response(parsed as Dictionary, "anonymous" if mode != "refresh" else str(app.leaderboard_auth_provider)):
		if mode == "refresh" and _leaderboard_retry_chat_auth_without_refresh():
			return
		return
	app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
	if app.current_screen == "leaderboard":
		_leaderboard_fetch_category(app.leaderboard_category_id)
	if app._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		_chat_stream_connect(true)
		_start_chat_stream_poll_timer()
		app._profile_chat_overlay_surface()._render_chat_if_visible()
	if app._leaderboard_state().submit_ready():
		_leaderboard_submit_scores()
	if not app.chat_pending_send_after_auth.is_empty():
		var queued_chat = app.chat_pending_send_after_auth
		app.chat_pending_send_after_auth = ""
		_chat_send(queued_chat)


func _claim_leaderboard_name(display_name: String) -> void:
	if app.leaderboard_name_claim_in_flight:
		return
	if not _leaderboard_firebase_enabled():
		app._profile_chat_overlay_surface()._set_profile_status_text("Online services are not connected yet.")
		return
	if not _leaderboard_write_ready():
		app._profile_chat_overlay_surface()._set_profile_status_text("Connecting leaderboard login...")
		return
	var name_key = LeaderboardProfile.name_key(display_name, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS)
	if name_key.is_empty():
		app._profile_chat_overlay_surface()._set_profile_status_text("Choose a username first.")
		app._profile_chat_overlay_surface()._focus_profile_name_edit()
		return
	var now_unix = app._unix_now()
	var server_timestamp = _firebase_server_timestamp()
	var payload = {
		"uid": app.leaderboard_player_id,
		"name": display_name,
		"name_key": name_key,
		"avatar_index": app.leaderboard_avatar_index,
		"created_at": server_timestamp,
		"updated_at": server_timestamp,
		"submitted_at_unix": now_unix
	}
	app.leaderboard_name_claim_pending_name = display_name
	app.leaderboard_name_claim_pending_key = name_key
	app.leaderboard_name_claim_in_flight = true
	app._profile_chat_overlay_surface()._set_profile_status_text("Checking username...")
	var err = app.leaderboard_name_claim_request.request(
		_leaderboard_firebase_url("name_claims/%s" % name_key, _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PUT,
		JSON.stringify(payload)
	)
	if err != OK:
		app.leaderboard_name_claim_in_flight = false
		app.leaderboard_name_claim_pending_name = ""
		app.leaderboard_name_claim_pending_key = ""
		app._profile_chat_overlay_surface()._set_profile_status_text("Username check failed. Try again.")


func _on_leaderboard_name_claim_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	app.leaderboard_name_claim_in_flight = false
	var claimed_name = app.leaderboard_name_claim_pending_name
	var claimed_key = app.leaderboard_name_claim_pending_key
	app.leaderboard_name_claim_pending_name = ""
	app.leaderboard_name_claim_pending_key = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		app._profile_chat_overlay_surface()._set_profile_status_text("Username check failed. Try again.")
		return
	if response_code == 401 or response_code == 403:
		app._profile_chat_overlay_surface()._set_profile_status_text("Username is taken.")
		app._profile_chat_overlay_surface()._focus_profile_name_edit()
		return
	if response_code < 200 or response_code >= 300:
		app._profile_chat_overlay_surface()._set_profile_status_text("Username check failed. Try again.")
		return
	app.leaderboard_display_name = claimed_name
	app.leaderboard_name_key = claimed_key
	app.leaderboard_profile_claimed = true
	app.leaderboard_name_claim_verified = true
	app.leaderboard_status_message = "Leaderboard name saved."
	app.save_game()
	_refresh_profile_references()
	app._profile_chat_overlay_surface()._rebuild_profile_overlay()
	if app.current_screen == "leaderboard":
		app._refresh_leaderboard_if_visible()
	if app._leaderboard_state().submit_ready():
		_leaderboard_submit_scores()


func _attempt_leaderboard_name_recovery() -> bool:
	if app.leaderboard_name_recovery_in_flight:
		return true
	if not _leaderboard_firebase_enabled():
		return false
	if not LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		return false
	if not _leaderboard_write_ready():
		return false
	if app.leaderboard_player_id.is_empty() or app.leaderboard_name_key.is_empty():
		return false
	var now_unix = app._unix_now()
	var server_timestamp = _firebase_server_timestamp()
	var payload = {
		"uid": app.leaderboard_player_id,
		"name": app.leaderboard_display_name,
		"name_key": app.leaderboard_name_key,
		"avatar_index": app.leaderboard_avatar_index,
		"created_at": server_timestamp,
		"updated_at": server_timestamp,
		"submitted_at_unix": now_unix
	}
	app.leaderboard_name_recovery_in_flight = true
	var err = app.leaderboard_name_recovery_request.request(
		_leaderboard_firebase_url("name_claims/%s" % app.leaderboard_name_key, _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PUT,
		JSON.stringify(payload)
	)
	if err != OK:
		app.leaderboard_name_recovery_in_flight = false
		return false
	app.leaderboard_status_message = "Checking name recovery..."
	return true


func _on_leaderboard_name_recovery_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	app.leaderboard_name_recovery_in_flight = false
	if result != HTTPRequest.RESULT_SUCCESS:
		app.leaderboard_status_message = "Name recovery check failed. Try again later."
		return
	if response_code >= 200 and response_code < 300:
		app.leaderboard_profile_claimed = true
		app.leaderboard_name_claim_verified = true
		app.leaderboard_status_message = "Leaderboard name recovered. Try chat again."
		app.leaderboard_repair_publish_version = 0
		app.save_game()
		_refresh_profile_references()
		app._profile_chat_overlay_surface()._rebuild_profile_overlay_if_visible()
		if app.current_screen == "leaderboard":
			app._refresh_leaderboard_if_visible()
		return
	var detail = _firebase_error_detail(body)
	if response_code == 401 or response_code == 403:
		app.leaderboard_status_message = "Name recovery needs support approval."
	else:
		app.leaderboard_status_message = "Name recovery returned HTTP %s." % response_code
	if not detail.is_empty() and response_code != 401 and response_code != 403:
		app.leaderboard_status_message = "%s %s" % [app.leaderboard_status_message, detail]


func _on_leaderboard_submit_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var stage = app.leaderboard_submit_stage
	if stage == "gate":
		if result != HTTPRequest.RESULT_SUCCESS:
			app.leaderboard_submit_in_flight = false
			_leaderboard_note_submit_failure("Leaderboard write gate failed.")
			return
		if response_code < 200 or response_code >= 300:
			app.leaderboard_submit_in_flight = false
			var gate_detail = _firebase_error_detail(body)
			if response_code == 401 or response_code == 403:
				app.leaderboard_auth_id_token = ""
				app.leaderboard_auth_expires_unix = 0
			if not gate_detail.is_empty():
				_leaderboard_note_submit_failure("Leaderboard write gate returned HTTP %s: %s" % [response_code, gate_detail])
			else:
				_leaderboard_note_submit_failure("Leaderboard write gate returned HTTP %s." % response_code)
			return
		app.leaderboard_submit_stage = "scores"
		var err = app.leaderboard_submit_request.request(
			_leaderboard_firebase_url("", _leaderboard_authenticated_query("print=silent")),
			PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_PATCH,
			JSON.stringify(app.leaderboard_pending_score_updates)
		)
		if err == OK:
			return
		app.leaderboard_submit_in_flight = false
		app.leaderboard_pending_score_updates.clear()
		_leaderboard_note_submit_failure("Leaderboard score write failed: %s" % error_string(err))
		return
	app.leaderboard_submit_in_flight = false
	app.leaderboard_submit_stage = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		_leaderboard_note_submit_failure("Leaderboard write failed.")
		return
	if response_code < 200 or response_code >= 300:
		var detail = _firebase_error_detail(body)
		if response_code == 401 or response_code == 403:
			app.leaderboard_auth_id_token = ""
			app.leaderboard_auth_expires_unix = 0
		if not detail.is_empty():
			_leaderboard_note_submit_failure("Leaderboard write returned HTTP %s: %s" % [response_code, detail])
		else:
			_leaderboard_note_submit_failure("Leaderboard write returned HTTP %s." % response_code)
		return
	app.leaderboard_last_submit_unix = app._unix_now()
	var leaderboard_state = app._leaderboard_state()
	app.leaderboard_last_submitted_score = leaderboard_state.score()
	app.leaderboard_last_submitted_total_xp = leaderboard_state.score()
	for raw_category_id in app.leaderboard_last_submit_payload_categories:
		var category_id = leaderboard_state.valid_category_id(str(raw_category_id))
		app.leaderboard_last_submitted_scores_by_category[category_id] = leaderboard_state.score_for_category(category_id)
	if app.leaderboard_pending_repair_publish_version > app.leaderboard_repair_publish_version:
		app.leaderboard_repair_publish_version = clampi(app.leaderboard_pending_repair_publish_version, 0, app.LEADERBOARD_REPAIR_PUBLISH_VERSION)
		app.leaderboard_status_message = "Leaderboard rows repaired."
	app.leaderboard_last_submit_payload_categories.clear()
	app.leaderboard_pending_score_updates.clear()
	app.leaderboard_pending_repair_publish_version = 0
	if app.leaderboard_status_message != "Leaderboard rows repaired.":
		app.leaderboard_status_message = "Leaderboard published."
	app.save_game()
	if app.current_screen == "leaderboard":
		_leaderboard_fetch_category(app.leaderboard_category_id, true)
		app._refresh_leaderboard_if_visible()


func _on_profile_reference_update_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	app.profile_reference_update_in_flight = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		return


func _chat_stream_connect(force_reconnect = false) -> void:
	if not app._profile_chat_overlay_surface()._global_chat_allowed():
		return
	if not _leaderboard_firebase_enabled():
		app.chat_status_message = "Online chat is not connected yet."
		return
	if _chat_web_polling_enabled():
		_chat_poll_messages(force_reconnect)
		return
	var now = app._unix_now()
	var visible_count = _chat_target_visible_count()
	if app.chat_stream_connected and app.chat_stream_visible_count >= visible_count and not force_reconnect:
		return
	var upgrading_visible_count = visible_count > app.chat_stream_visible_count and (app.chat_stream_connected or app.chat_stream_connecting or app.chat_stream_request_sent)
	if not force_reconnect and not upgrading_visible_count and app.chat_stream_next_connect_unix > now:
		return
	if app.chat_stream_connecting and app.chat_stream_visible_count >= visible_count and not force_reconnect:
		_start_chat_stream_poll_timer()
		return
	if not force_reconnect and app.chat_stream_retry_unix > now:
		return
	_chat_stream_disconnect(false)
	app.chat_stream_visible_count = visible_count
	var query = "orderBy=%%22created_at%%22&limitToLast=%s" % visible_count
	var target = _firebase_stream_target(_chat_firebase_url("messages", query))
	if target.is_empty():
		_chat_note_stream_failure("Chat stream URL was invalid.")
		return
	if app.chat_stream_client == null:
		_chat_note_stream_failure("Chat stream client is not ready yet.")
		return
	var err = app.chat_stream_client.connect_to_host(str(target.get("host", "")), 443, TLSOptions.client())
	if err != OK:
		_chat_note_stream_failure("Chat stream failed to connect: %s" % error_string(err))
		return
	app.chat_stream_next_connect_unix = now + app.CHAT_STREAM_RECONNECT_MIN_SECONDS
	app.chat_stream_connecting = true
	app.chat_stream_request_sent = false
	app.chat_stream_buffer = ""
	app.chat_stream_event_name = ""
	app.chat_stream_event_data_lines.clear()
	app.chat_stream_client.set_meta("request_path", str(target.get("path", "/")))
	app.chat_status_message = "Connecting global chat stream..."
	_start_chat_stream_poll_timer()


func _start_chat_stream_poll_timer() -> void:
	ensure_leaderboard_http()
	if app.chat_stream_poll_timer == null:
		return
	if app.chat_stream_poll_timer.is_stopped():
		app.chat_stream_poll_timer.start()
	_process_chat_live_sync(0.0)


func _stop_chat_stream_poll_timer() -> void:
	if app.chat_stream_poll_timer != null:
		app.chat_stream_poll_timer.stop()


func _process_chat_live_sync(delta: float) -> void:
	if not app._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		_chat_stream_disconnect(false)
		_stop_chat_stream_poll_timer()
		return
	if app.chat_strip == null or not is_instance_valid(app.chat_strip) or not app.chat_strip.visible:
		_chat_stream_disconnect(false)
		return
	if not _leaderboard_firebase_enabled():
		_chat_stream_disconnect(false)
		return
	if _chat_web_polling_enabled():
		_chat_poll_messages(false)
		return
	if app.chat_stream_client == null:
		ensure_leaderboard_http()
		if app.chat_stream_client == null:
			return
		if app._profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
			_chat_stream_connect()
		return
	var status = app.chat_stream_client.get_status()
	if status == HTTPClient.STATUS_DISCONNECTED:
		app.chat_stream_connected = false
		app.chat_stream_connecting = false
		_chat_stream_connect()
		return
	var poll_err = app.chat_stream_client.poll()
	if poll_err != OK:
		_chat_note_stream_failure("Chat stream failed: %s" % error_string(poll_err))
		return
	status = app.chat_stream_client.get_status()
	if status == HTTPClient.STATUS_CONNECTED and not app.chat_stream_request_sent:
		var request_path = str(app.chat_stream_client.get_meta("request_path", "/"))
		var err = app.chat_stream_client.request(
			HTTPClient.METHOD_GET,
			request_path,
			PackedStringArray(["Accept: text/event-stream"])
		)
		if err != OK:
			_chat_note_stream_failure("Chat stream request failed: %s" % error_string(err))
			return
		app.chat_stream_request_sent = true
		app.chat_status_message = "Opening global chat stream..."
		return
	if status == HTTPClient.STATUS_BODY:
		if not app.chat_stream_connected:
			app.chat_stream_connected = true
			app.chat_stream_connecting = false
			app.chat_stream_retry_unix = 0
			app.chat_status_message = "Global chat is live."
			app._mark_save_dirty("chat stream connected")
		var chunk = app.chat_stream_client.read_response_body_chunk()
		if chunk.size() > 0:
			_chat_stream_receive_text(chunk.get_string_from_utf8())
		return
	if status == HTTPClient.STATUS_CONNECTION_ERROR or status == HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
		_chat_note_stream_failure("Chat stream disconnected.")


func _chat_web_polling_enabled() -> bool:
	return OS.has_feature("web")


func _chat_poll_messages(force_refresh = false) -> void:
	ensure_leaderboard_http()
	if app.chat_fetch_request == null or not is_instance_valid(app.chat_fetch_request):
		app.chat_status_message = "Chat refresh is not ready yet."
		return
	if app.chat_fetch_in_flight:
		return
	var now = app._unix_now()
	var visible_count = _chat_target_visible_count()
	if not force_refresh and app.chat_stream_connected and app.chat_stream_visible_count >= visible_count and app.chat_stream_next_connect_unix > now:
		return
	if not force_refresh and app.chat_stream_retry_unix > now:
		return
	var query = "orderBy=%%22created_at%%22&limitToLast=%s" % visible_count
	app.chat_fetch_in_flight = true
	app.chat_stream_connecting = true
	app.chat_stream_request_sent = true
	app.chat_stream_visible_count = visible_count
	app.chat_status_message = "Refreshing global chat..."
	var err = app.chat_fetch_request.request(
		_chat_firebase_url("messages", query),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_GET
	)
	if err != OK:
		app.chat_fetch_in_flight = false
		app.chat_stream_connecting = false
		app.chat_stream_request_sent = false
		_chat_note_stream_failure("Chat refresh failed: %s" % error_string(err))
		app._profile_chat_overlay_surface()._render_chat_if_visible()


func _on_chat_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	app.chat_fetch_in_flight = false
	app.chat_stream_connecting = false
	app.chat_stream_request_sent = false
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
		app.chat_rows.clear()
	elif typeof(parsed) == TYPE_DICTIONARY:
		_chat_replace_rows(parsed as Dictionary)
	else:
		_chat_note_stream_failure("Chat refresh returned invalid data.")
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	app.chat_stream_connected = true
	app.chat_stream_retry_unix = 0
	app.chat_stream_next_connect_unix = app._unix_now() + app.CHAT_STREAM_RECONNECT_MIN_SECONDS
	app.chat_status_message = "Global chat is live."
	app._profile_chat_overlay_surface()._render_chat_if_visible()


func _chat_send(raw_text: String) -> void:
	var clean_text = app.ChatState.sanitize_message(raw_text, app.CHAT_MESSAGE_MAX_CHARS, app.CHAT_CENSORED_WORDS)
	if clean_text.is_empty():
		app.chat_status_message = "Write a message first."
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if not _leaderboard_firebase_enabled():
		app.chat_status_message = "Online chat is not connected yet."
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if not _leaderboard_web_authless_writes_enabled() and not _leaderboard_auth_ready() and _leaderboard_auth_retry_wait_seconds() > 0:
		app.leaderboard_auth_retry_after_unix = 0
	if not _leaderboard_write_ready():
		if app.leaderboard_auth_in_flight:
			app.chat_pending_send_after_auth = clean_text
			app.chat_status_message = "Connecting chat login, then sending..."
		else:
			app.chat_status_message = app.leaderboard_status_message
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if app.chat_send_in_flight:
		app.chat_status_message = "Still sending the previous message..."
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	var wait = _chat_next_send_seconds()
	if wait > 0:
		app.chat_status_message = "Chat is cooling down for %s." % GameFormatting.duration(float(wait))
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	var now_unix = app._unix_now()
	var message_id = app.ChatState.make_message_id(now_unix)
	var now_msec = app._unix_now_msec()
	var server_timestamp = _firebase_server_timestamp()
	var has_claimed_chat_name = LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS)
	if not has_claimed_chat_name and not LeaderboardProfile.is_guest_display_name(app.leaderboard_display_name, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS):
		app.leaderboard_display_name = LeaderboardProfile.make_guest_display_name(app.PROFILE_GUEST_NAME_PREFIX)
		app.leaderboard_name_key = ""
		app.save_game()
	var chat_name_key = app.leaderboard_name_key if has_claimed_chat_name else ""
	var chat_payload = ChatState.outgoing_message_payload(app.leaderboard_player_id, app.leaderboard_display_name, app._global_level(), app.leaderboard_avatar_index, clean_text, now_msec, now_unix, chat_name_key)
	var remote_chat_payload = ChatState.remote_message_payload(chat_payload, server_timestamp)
	var updates = ChatState.firebase_write_updates(message_id, app.leaderboard_player_id, remote_chat_payload, server_timestamp, now_unix)
	app.chat_send_in_flight = true
	app.chat_send_stage = "patch"
	app.chat_pending_send_message_id = message_id
	app.chat_pending_send_text = clean_text
	app.chat_pending_send_payload = remote_chat_payload
	app.chat_status_message = "Sending chat message..."
	_chat_upsert_row(message_id, chat_payload)
	app.chat_draft_message = ""
	if app.chat_message_edit != null and is_instance_valid(app.chat_message_edit):
		app.chat_message_edit.text = ""
	app._profile_chat_overlay_surface()._render_chat_if_visible()
	app._profile_chat_overlay_surface()._chat_scroll_to_latest_deferred()
	var err = OK
	if _leaderboard_web_authless_writes_enabled():
		err = app.chat_send_request.request(
			_chat_firebase_url("", _leaderboard_authenticated_query("print=silent")),
			PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_PATCH,
			JSON.stringify(updates)
		)
	else:
		app.chat_send_stage = "gate"
		err = app.chat_send_request.request(
			_chat_firebase_url("user_write_gates/%s" % app.leaderboard_player_id, _leaderboard_authenticated_query("print=silent")),
			PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
			HTTPClient.METHOD_PUT,
			JSON.stringify(updates.get("user_write_gates/%s" % app.leaderboard_player_id, {}))
		)
	if err != OK:
		app.chat_send_in_flight = false
		app.chat_send_stage = ""
		_chat_remove_row(message_id)
		_chat_restore_failed_send()
		_chat_note_send_failure("Chat write failed: %s" % error_string(err))
		app._profile_chat_overlay_surface()._render_chat_if_visible()


func _on_chat_send_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var completed_stage = app.chat_send_stage
	if completed_stage == "gate":
		if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
			app.chat_send_stage = "message"
			var message_err = app.chat_send_request.request(
				_chat_firebase_url("messages/%s" % app.chat_pending_send_message_id, _leaderboard_authenticated_query("print=silent")),
				PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
				HTTPClient.METHOD_PUT,
				JSON.stringify(app.chat_pending_send_payload)
			)
			if message_err == OK:
				return
			app.chat_send_in_flight = false
			app.chat_send_stage = ""
			_chat_remove_row(app.chat_pending_send_message_id)
			_chat_restore_failed_send()
			_chat_note_send_failure("Chat write failed: %s" % error_string(message_err))
			app._profile_chat_overlay_surface()._render_chat_if_visible()
			return
	app.chat_send_in_flight = false
	app.chat_send_stage = ""
	if result != HTTPRequest.RESULT_SUCCESS:
		_chat_remove_row(app.chat_pending_send_message_id)
		_chat_restore_failed_send()
		_chat_note_send_failure("Chat write failed.")
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	if response_code < 200 or response_code >= 300:
		_chat_remove_row(app.chat_pending_send_message_id)
		_chat_restore_failed_send()
		var detail = _firebase_error_detail(body)
		if response_code == 401 or response_code == 403:
			var rejection_message = "Online chat rejected this message. Please try again later."
			if LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
				if _attempt_leaderboard_name_recovery():
					rejection_message = "Online chat is checking name recovery. Try again in a moment."
				else:
					rejection_message = "Online chat rejected this name. Ask support to approve name recovery."
			if not detail.is_empty():
				rejection_message = "Online chat rejected this message: %s" % detail
				if LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS) and detail.to_lower().find("permission") >= 0:
					if app.leaderboard_name_recovery_in_flight:
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
	app.chat_last_send_unix = app._unix_now()
	app.chat_pending_send_message_id = ""
	app.chat_pending_send_text = ""
	app.chat_pending_send_payload.clear()
	app.chat_status_message = ""
	app.chat_draft_message = ""
	app.save_game()
	if app.chat_message_edit != null and is_instance_valid(app.chat_message_edit):
		app.chat_message_edit.text = ""
	_chat_stream_connect()
	app._profile_chat_overlay_surface()._render_chat_if_visible()
	app._profile_chat_overlay_surface()._chat_scroll_to_latest_deferred()


func _chat_note_stream_failure(message: String) -> void:
	_chat_stream_disconnect(false)
	app.chat_stream_retry_unix = app._unix_now() + app.CHAT_STREAM_RETRY_INTERVAL_SECONDS
	app.chat_stream_next_connect_unix = app.chat_stream_retry_unix
	app.chat_status_message = "%s Reconnecting in %s." % [message, GameFormatting.duration(float(app.CHAT_STREAM_RETRY_INTERVAL_SECONDS))]
	app._mark_save_dirty("chat stream retry")


func _chat_stream_disconnect(clear_status = true) -> void:
	_stop_chat_stream_poll_timer()
	if app.chat_stream_client != null:
		app.chat_stream_client.close()
	app.chat_stream_connected = false
	app.chat_stream_connecting = false
	app.chat_stream_request_sent = false
	app.chat_stream_visible_count = 0
	app.chat_stream_buffer = ""
	app.chat_stream_event_name = ""
	app.chat_stream_event_data_lines.clear()
	if clear_status and app.current_screen == "chat":
		app.chat_status_message = "Chat stream closed."


func _chat_stream_receive_text(text: String) -> void:
	app.chat_stream_buffer += text.replace("\r\n", "\n").replace("\r", "\n")
	if app.chat_stream_buffer.length() > app.CHAT_STREAM_MAX_BUFFER_CHARS:
		_chat_note_stream_failure("Chat stream sent too much pending data.")
		app._profile_chat_overlay_surface()._render_chat_if_visible()
		return
	while app.chat_stream_buffer.find("\n") >= 0:
		var line_end = app.chat_stream_buffer.find("\n")
		var line = app.chat_stream_buffer.substr(0, line_end)
		app.chat_stream_buffer = app.chat_stream_buffer.substr(line_end + 1)
		_chat_stream_receive_line(line)


func _chat_stream_receive_line(line: String) -> void:
	if line.is_empty():
		_chat_stream_dispatch_event()
		return
	if line.begins_with(":"):
		return
	if line.begins_with("event:"):
		app.chat_stream_event_name = line.substr(6).strip_edges()
	elif line.begins_with("data:"):
		app.chat_stream_event_data_lines.append(line.substr(5).strip_edges())


func _chat_stream_dispatch_event() -> void:
	var event_name = app.chat_stream_event_name
	var data_text = "\n".join(app.chat_stream_event_data_lines)
	app.chat_stream_event_name = ""
	app.chat_stream_event_data_lines.clear()
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
	app.chat_status_message = "Global chat is live."
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
			app.chat_rows.clear()
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
	app.chat_rows = rows
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
	app.chat_rows.append(row)
	_chat_sort_and_trim_rows()


func _chat_remove_row(message_id: String) -> void:
	for i in range(app.chat_rows.size() - 1, -1, -1):
		if str((app.chat_rows[i] as Dictionary).get("message_id", "")) == message_id:
			app.chat_rows.remove_at(i)


func _chat_existing_row(message_id: String) -> Dictionary:
	for raw_row in app.chat_rows:
		var row = raw_row as Dictionary
		if str(row.get("message_id", "")) == message_id:
			return row.duplicate()
	return {}


func _chat_row_from_entry(message_id: String, entry: Dictionary) -> Dictionary:
	var text = app.ChatState.sanitize_message(str(entry.get("text", "")), app.CHAT_MESSAGE_MAX_CHARS, app.CHAT_CENSORED_WORDS)
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
	app.chat_rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var created_a = int(a.get("created_at", 0))
		var created_b = int(b.get("created_at", 0))
		if created_a == created_b:
			return str(a.get("message_id", "")) < str(b.get("message_id", ""))
		return created_a < created_b
	)
	var trim_count = maxi(_chat_target_visible_count(), app.chat_stream_visible_count)
	if app.chat_rows.size() > trim_count:
		app.chat_rows = app.chat_rows.slice(app.chat_rows.size() - trim_count)


func _chat_target_visible_count() -> int:
	if app.chat_overlay != null and app.chat_overlay.visible:
		return app.CHAT_FULL_VISIBLE_COUNT
	return app.CHAT_STRIP_VISIBLE_COUNT


func _chat_latest_message_cursor() -> Dictionary:
	var latest = {"created_at": 0, "message_id": ""}
	for raw_row in app.chat_rows:
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
	if app.chat_overlay != null and app.chat_overlay.visible:
		return false
	var latest = _chat_latest_message_cursor()
	return _chat_cursor_after(
		int(latest.get("created_at", 0)),
		str(latest.get("message_id", "")),
		app.chat_last_opened_created_at,
		app.chat_last_opened_message_id
	)


func _chat_mark_opened_to_latest(save_now = false) -> void:
	var latest = _chat_latest_message_cursor()
	var latest_created_at = int(latest.get("created_at", 0))
	var latest_message_id = str(latest.get("message_id", ""))
	if not _chat_cursor_after(latest_created_at, latest_message_id, app.chat_last_opened_created_at, app.chat_last_opened_message_id):
		app._profile_chat_overlay_surface()._sync_chat_unread_dot()
		return
	app.chat_last_opened_created_at = latest_created_at
	app.chat_last_opened_message_id = latest_message_id
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
	app.chat_status_message = "%s Trying again in %s." % [message, GameFormatting.duration(float(app.CHAT_SEND_INTERVAL_SECONDS))]
	app._mark_save_dirty("chat send retry")


func _chat_note_send_rejected(message: String) -> void:
	app.chat_status_message = message
	app._mark_save_dirty("chat send rejected")


func _chat_restore_failed_send() -> void:
	app.chat_pending_send_message_id = ""
	app.chat_pending_send_payload.clear()
	if app.chat_pending_send_text.is_empty():
		return
	app.chat_draft_message = app.chat_pending_send_text
	if app.chat_message_edit != null and is_instance_valid(app.chat_message_edit):
		app.chat_message_edit.text = app.chat_pending_send_text
	app.chat_pending_send_text = ""


func _chat_next_send_seconds() -> int:
	if app.chat_last_send_unix <= 0:
		return 0
	return maxi(0, app.CHAT_SEND_INTERVAL_SECONDS - (app._unix_now() - app.chat_last_send_unix))




func _refresh_profile_references() -> void:
	_refresh_local_profile_references()
	if not _leaderboard_firebase_enabled() or app.profile_reference_update_in_flight:
		return
	if not _leaderboard_write_ready():
		return
	if app.leaderboard_player_id.is_empty():
		return
	var updates = _profile_reference_updates()
	if updates.is_empty():
		return
	app.profile_reference_update_in_flight = true
	var err = app.profile_reference_update_request.request(
		_firebase_database_url("", "", _leaderboard_authenticated_query("print=silent")),
		PackedStringArray([app.LEADERBOARD_HTTP_HEADER_JSON, app.LEADERBOARD_HTTP_HEADER_ACCEPT_JSON]),
		HTTPClient.METHOD_PATCH,
		JSON.stringify(updates)
	)
	if err != OK:
		app.profile_reference_update_in_flight = false


func _refresh_local_profile_references() -> void:
	for category_id in app.leaderboard_rows_by_category.keys():
		var rows = app.leaderboard_rows_by_category.get(category_id, [])
		if typeof(rows) != TYPE_ARRAY:
			continue
		for row in rows:
			if typeof(row) != TYPE_DICTIONARY:
				continue
			var row_data = row as Dictionary
			if str(row_data.get("player_id", "")) == app.leaderboard_player_id:
				row_data["name"] = app.leaderboard_display_name
				row_data["name_key"] = app.leaderboard_name_key
				row_data["avatar_index"] = app.leaderboard_avatar_index
	for raw_row in app.chat_rows:
		var row = raw_row as Dictionary
		if str(row.get("sender_id", "")) == app.leaderboard_player_id:
			row["name"] = app.leaderboard_display_name
			row["name_key"] = app.leaderboard_name_key
			row["total_level"] = app._global_level()
			row["avatar_index"] = app.leaderboard_avatar_index
	app._profile_chat_overlay_surface()._refresh_chat_profile_button()
	app._profile_chat_overlay_surface()._update_chat_strip()
	app._profile_chat_overlay_surface()._render_chat_if_visible()


func _profile_reference_updates() -> Dictionary:
	var now_unix = app._unix_now()
	var server_timestamp = _firebase_server_timestamp()
	var updates = {}
	if LeaderboardProfile.profile_claim_valid(app, app.PROFILE_GUEST_NAME_PREFIX, app.PROFILE_DISPLAY_NAME_MAX_CHARS, app.PROFILE_NAME_KEY_MAX_CHARS):
		updates["leaderboards/v1/name_claims/%s" % app.leaderboard_name_key] = {
			"uid": app.leaderboard_player_id,
			"name": app.leaderboard_display_name,
			"name_key": app.leaderboard_name_key,
			"avatar_index": app.leaderboard_avatar_index,
			"created_at": server_timestamp,
			"updated_at": server_timestamp,
			"submitted_at_unix": now_unix
		}
	var category_scores = {}
	var leaderboard_state = app._leaderboard_state()
	for raw_category in leaderboard_state.categories():
		var category = raw_category as Dictionary
		var category_id = leaderboard_state.valid_category_id(str(category.get("id", "")))
		if category_id.is_empty():
			continue
		var score = int(app.leaderboard_last_submitted_scores_by_category.get(category_id, 0))
		for row in leaderboard_state.rows_for_category(category_id):
			var row_data = row as Dictionary
			if str(row_data.get("player_id", "")) == app.leaderboard_player_id:
				score = maxi(score, int(row_data.get("score", 0)))
		if category_id == app.LEADERBOARD_CATEGORY_TOTAL_LEVEL and leaderboard_state.total_level_score_looks_legacy_xp(score):
			score = leaderboard_state.score_for_category(category_id)
		if score > 0:
			category_scores[category_id] = score
	for raw_category_id in category_scores.keys():
		var category_id = leaderboard_state.valid_category_id(str(raw_category_id))
		var category_key = _leaderboard_category_key(category_id)
		updates["leaderboards/v1/scores/%s/%s" % [category_key, app.leaderboard_player_id]] = {
			"name": app.leaderboard_display_name,
			"name_key": app.leaderboard_name_key,
			"avatar_index": app.leaderboard_avatar_index,
			"score": int(category_scores[category_id]),
			"skill_level": leaderboard_state.skill_level_for_category(category_id),
			"total_xp": leaderboard_state.total_xp_for_category(category_id),
			"updated_at": server_timestamp,
			"submitted_at_unix": now_unix
		}
	for raw_row in app.chat_rows:
		var row = raw_row as Dictionary
		if str(row.get("sender_id", "")) != app.leaderboard_player_id:
			continue
		if bool(row.get("deleted", false)):
			continue
		var message_id = str(row.get("message_id", ""))
		if message_id.is_empty():
			continue
		updates["global_chat/v1/messages/%s" % message_id] = {
			"sender_id": app.leaderboard_player_id,
			"name": app.leaderboard_display_name,
			"name_key": app.leaderboard_name_key,
			"total_level": app._global_level(),
			"avatar_index": app.leaderboard_avatar_index,
			"text": app.ChatState.sanitize_message(str(row.get("text", "")), app.CHAT_MESSAGE_MAX_CHARS, app.CHAT_CENSORED_WORDS),
			"created_at": maxi(0, int(row.get("created_at", 0))),
			"created_at_unix": maxi(0, int(row.get("created_at_unix", 0))),
			"deleted": false
		}
	return updates


