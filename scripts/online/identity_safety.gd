class_name OnlineIdentitySafety

# Leaderboard fresh start (owner decision for the 0.6.0 leaderboard wipe).
# Legacy leaderboard identities are wiped server-side instead of migrated, so a
# legacy authless save, a deleted/revoked anonymous login, or a pending legacy
# username transfer simply signs in anonymously like a new player, adopts the new
# Firebase UID, and re-claims its display name when it is free. Nothing waits on
# support-issued name recovery tickets. Local progress is never touched; genuine
# save-safety gates (cross-account cloud saves, fail-closed loading, Google
# account recovery, disabled accounts) are unaffected.
const LEADERBOARD_FRESH_START := true


const SECRET_SAVE_KEYS := {
	"leaderboard_auth_refresh_token": true,
	"leaderboard_auth_recovery_pending_refresh_token": true,
	"refreshToken": true,
	"refresh_token": true,
	"idToken": true,
	"id_token": true
}

const IDENTITY_COMPARISON_KEYS := [
	"leaderboard_player_id",
	"leaderboard_display_name",
	"leaderboard_avatar_index",
	"leaderboard_name_key",
	"leaderboard_profile_claimed",
	"leaderboard_name_claim_verified",
	"leaderboard_auth_provider",
	"leaderboard_auth_refresh_token",
	"leaderboard_auth_bound_uid",
	"leaderboard_auth_recovery_required",
	"leaderboard_auth_recovery_reason",
	"leaderboard_auth_definitive_failure_code",
	"leaderboard_legacy_authless_old_uid",
	"leaderboard_deleted_auth_transition_pending",
	"leaderboard_name_transfer_required",
	"leaderboard_legacy_username_recovery_required",
	"leaderboard_legacy_name_hint_display",
	"leaderboard_legacy_name_hint_key",
	"leaderboard_released_name_key"
]


static func is_local_placeholder_player_id(player_id: String) -> bool:
	var clean := player_id.strip_edges()
	if clean.length() != 33 or not clean.begins_with("p"):
		return false
	for i in range(1, clean.length()):
		var code := clean.unicode_at(i)
		if not ((code >= 48 and code <= 57) or (code >= 97 and code <= 102)):
			return false
	return true


static func legacy_authless_google_transition_allowed(
	player_id: String,
	refresh_token: String,
	bound_uid: String,
	auth_provider: String
) -> bool:
	var clean_player_id := player_id.strip_edges()
	var clean_bound_uid := bound_uid.strip_edges()
	return (
		is_local_placeholder_player_id(clean_player_id)
		and refresh_token.strip_edges().is_empty()
		# Builds from the first hardened-auth rollout derived the old local p+32
		# id as a bound UID before it could be distinguished from Firebase Auth.
		# Treat that exact self-binding as legacy-authless too. A different bound
		# UID is never eligible for this transition.
		and (clean_bound_uid.is_empty() or clean_bound_uid == clean_player_id)
		and auth_provider.strip_edges() != "google"
	)


static func refresh_failure_code(response_code: int, firebase_detail: String) -> String:
	if response_code == 429 or response_code >= 500 or response_code <= 0:
		return ""
	var detail := firebase_detail.strip_edges().to_upper()
	# Secure Token normally reports revoked/deleted identities as a structured
	# HTTP 400 error. A blanket 401/403 classification is unsafe: API-key
	# restrictions and project configuration outages also use those statuses and
	# must not permanently move every installed player into account recovery.
	if response_code != 400 and response_code != 401 and response_code != 403:
		return ""
	# Firebase messages may append human-readable detail after the symbolic code.
	# Compare the first token exactly so request/configuration errors such as
	# INVALID_GRANT_TYPE cannot be mistaken for a revoked player credential.
	var end := detail.length()
	for separator in [":", " ", "\t", "\r", "\n", ","]:
		var index := detail.find(separator)
		if index >= 0:
			end = mini(end, index)
	var error_code := detail.substr(0, end)
	return error_code if error_code in [
		"INVALID_REFRESH_TOKEN",
		"INVALID_GRANT",
		"TOKEN_EXPIRED",
		"USER_DISABLED",
		"USER_NOT_FOUND",
		"CREDENTIAL_TOO_OLD_LOGIN_AGAIN"
	] else ""


static func refresh_failure_is_definitive(response_code: int, firebase_detail: String) -> bool:
	return not refresh_failure_code(response_code, firebase_detail).is_empty()


static func recovery_refresh_allowed(
	recovery_required: bool,
	refresh_token: String,
	bound_uid: String,
	player_uid: String,
	definitive_failure_code: String
) -> bool:
	var clean_bound_uid := bound_uid.strip_edges()
	var clean_player_uid := player_uid.strip_edges()
	return (
		recovery_required
		and not refresh_token.strip_edges().is_empty()
		and not clean_bound_uid.is_empty()
		and clean_bound_uid == clean_player_uid
		and definitive_failure_code.strip_edges().is_empty()
	)


static func recovery_refresh_response_matches_binding(response_uid: String, bound_uid: String, player_uid: String) -> bool:
	var clean_response_uid := response_uid.strip_edges()
	var clean_bound_uid := bound_uid.strip_edges()
	var clean_player_uid := player_uid.strip_edges()
	return (
		not clean_response_uid.is_empty()
		and clean_response_uid == clean_bound_uid
		and clean_response_uid == clean_player_uid
	)


static func deleted_uid_transition_failure_code_valid(failure_code: String) -> bool:
	# USER_DISABLED is deliberately excluded. A support transfer must not become
	# a client-side bypass for an account that an administrator disabled.
	return failure_code.strip_edges().to_upper() == "USER_NOT_FOUND"


static func fresh_start_anonymous_restart_failure_code(failure_code: String) -> bool:
	# Any definitive refresh failure leaves an anonymous login unrecoverable (it has
	# no other credential). USER_DISABLED stays blocked: an administrator disabled
	# that account on purpose.
	var clean := failure_code.strip_edges().to_upper()
	return not clean.is_empty() and clean != "USER_DISABLED"


static func fresh_start_legacy_identity_state(payload: Dictionary) -> bool:
	# True when a saved identity's recovery/transfer state exists only because of
	# the retired legacy leaderboard migration, so fresh-start mode may clear it.
	if not LEADERBOARD_FRESH_START:
		return false
	if (
		bool(payload.get("leaderboard_name_transfer_required", false))
		or bool(payload.get("leaderboard_legacy_username_recovery_required", false))
		or bool(payload.get("leaderboard_deleted_auth_transition_pending", false))
		or not str(payload.get("leaderboard_legacy_authless_old_uid", "")).strip_edges().is_empty()
	):
		return true
	var provider := str(payload.get("leaderboard_auth_provider", "")).strip_edges()
	if provider == "google":
		return false
	var player_id := str(payload.get("leaderboard_player_id", "")).strip_edges()
	var refresh_token := str(payload.get("leaderboard_auth_refresh_token", "")).strip_edges()
	if legacy_authless_google_transition_allowed(player_id, refresh_token, str(payload.get("leaderboard_auth_bound_uid", "")), provider):
		return true
	var failure_code := str(payload.get("leaderboard_auth_definitive_failure_code", "")).strip_edges()
	if not failure_code.is_empty():
		return fresh_start_anonymous_restart_failure_code(failure_code)
	# An anonymous Firebase UID whose refresh token was lost can never be refreshed.
	return refresh_token.is_empty() and not player_id.is_empty()


static func fresh_start_claimed_name_released(existing_payload: Dictionary, next_payload: Dictionary) -> bool:
	# A claimed name may be dropped only when the same UID persisted that exact
	# key as released (fresh start found the server claim held by someone else).
	# The marker keeps older claimed backups from outranking the released save.
	if not LEADERBOARD_FRESH_START:
		return false
	var released_key := str(next_payload.get("leaderboard_released_name_key", "")).strip_edges()
	var existing_key := str(existing_payload.get("leaderboard_name_key", "")).strip_edges()
	var existing_player_id := str(existing_payload.get("leaderboard_player_id", "")).strip_edges()
	return (
		not released_key.is_empty()
		and released_key == existing_key
		and not existing_player_id.is_empty()
		and existing_player_id == str(next_payload.get("leaderboard_player_id", "")).strip_edges()
	)


static func google_link_collision(firebase_detail: String) -> bool:
	var detail := firebase_detail.strip_edges().to_upper()
	return (
		detail.contains("FEDERATED_USER_ID_ALREADY_LINKED")
		or detail.contains("EMAIL_EXISTS")
		or detail.contains("CREDENTIAL_ALREADY_IN_USE")
	)


static func cloud_safe_payload(value: Variant) -> Variant:
	if typeof(value) == TYPE_DICTIONARY:
		var clean := {}
		for raw_key in (value as Dictionary).keys():
			var key := str(raw_key)
			if SECRET_SAVE_KEYS.has(key):
				continue
			clean[raw_key] = cloud_safe_payload((value as Dictionary).get(raw_key))
		return clean
	if typeof(value) == TYPE_ARRAY:
		var clean_array := []
		for item in value as Array:
			clean_array.append(cloud_safe_payload(item))
		return clean_array
	return value


static func payload_with_preserved_identity_for_comparison(remote_payload: Dictionary, local_payload: Dictionary) -> Dictionary:
	var comparison := remote_payload.duplicate(true)
	for raw_key in IDENTITY_COMPARISON_KEYS:
		var key := str(raw_key)
		if local_payload.has(key):
			comparison[key] = local_payload.get(key)
	return comparison


static func payload_checksum(payload_json: String) -> String:
	return payload_json.sha256_text()


static func checksum_matches(payload_json: String, expected_checksum: String, allow_missing := false) -> bool:
	var expected := expected_checksum.strip_edges().to_lower()
	if expected.is_empty():
		return allow_missing
	return expected.length() == 64 and payload_checksum(payload_json) == expected
