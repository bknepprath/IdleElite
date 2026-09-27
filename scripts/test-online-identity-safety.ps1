param([switch]$StaticOnly)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$runtimePath = Join-Path $projectRoot "scripts\online\online_runtime.gd"
$identitySafetyPath = Join-Path $projectRoot "scripts\online\identity_safety.gd"
$normalizersPath = Join-Path $projectRoot "scripts\save_state\normalizers.gd"
$profileUiPath = Join-Path $projectRoot "scripts\ui\profile_chat_overlay_surface.gd"
$rulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"
$backfillPath = Join-Path $projectRoot "scripts\backfill-firebase-profiles-by-uid.ps1"
$backfillFixtureTestPath = Join-Path $projectRoot "scripts\test-firebase-profile-backfill.ps1"
$recoveryResolverPath = Join-Path $projectRoot "scripts\resolve-firebase-account-recovery-code.ps1"
$recoveryResolverTestPath = Join-Path $projectRoot "scripts\test-firebase-account-recovery-code.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\online-identity-safety"
$testScript = Join-Path $testDir "online_identity_safety_test.gd"
$testUserDataDir = Join-Path $testDir "user-data"
$previousTestUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
$runtime = Get-Content -LiteralPath $runtimePath -Raw
$identitySafety = Get-Content -LiteralPath $identitySafetyPath -Raw
$normalizers = Get-Content -LiteralPath $normalizersPath -Raw
$profileUi = Get-Content -LiteralPath $profileUiPath -Raw
$rules = Get-Content -LiteralPath $rulesPath -Raw | ConvertFrom-Json
$backfill = Get-Content -LiteralPath $backfillPath -Raw
$recoveryResolver = Get-Content -LiteralPath $recoveryResolverPath -Raw
$recoveryResolverTest = Get-Content -LiteralPath $recoveryResolverTestPath -Raw

Assert-True ($runtime -match 'IdentitySafety\.refresh_failure_code') "Refresh failures must be classified before requiring recovery."
$authReadyBlock = [regex]::Match($runtime, '(?s)func _leaderboard_auth_ready\(\).*?(?=\r?\nfunc )').Value
$recoveryRefreshAllowedBlock = [regex]::Match($runtime, '(?s)func _recovery_refresh_allowed\(\).*?(?=\r?\nfunc )').Value
$ensureAuthBlock = [regex]::Match($runtime, '(?s)func _leaderboard_ensure_auth\(\).*?(?=\r?\nfunc )').Value
$applyAuthBlock = [regex]::Match($runtime, '(?s)func _apply_firebase_auth_response\(.*?(?=\r?\nfunc )').Value
$profileFetchBlock = [regex]::Match($runtime, '(?s)func _fetch_profile_recovery_record\(\).*?(?=\r?\nfunc )').Value
$profileCompleteBlock = [regex]::Match($runtime, '(?s)func _on_profile_recovery_fetch_completed\(.*?(?=\r?\nfunc )').Value
Assert-True ($identitySafety -match 'func recovery_refresh_allowed' -and $identitySafety -match 'func recovery_refresh_response_matches_binding') "Recovery refresh must use explicit saved-token and same-binding contracts."
Assert-True ($recoveryRefreshAllowedBlock -match 'IdentitySafety\.recovery_refresh_allowed' -and $ensureAuthBlock -match '_recovery_refresh_allowed\(\)' -and $ensureAuthBlock -match 'leaderboard_auth_mode = "refresh_recovery" if leaderboard_auth_recovery_required else "refresh"' -and $ensureAuthBlock -match 'refresh_token=%s" % leaderboard_auth_refresh_token\.uri_encode') "Recovery may refresh only the preserved credential through its distinct mode."
Assert-True ($authReadyBlock -match 'not leaderboard_auth_recovery_required') "Recovery refresh must not open the normal write-ready auth gate."
Assert-True ($applyAuthBlock -match '"refresh_recovery":\s+uid_transition_allowed = IdentitySafety\.recovery_refresh_response_matches_binding\(local_id, expected_uid, current_uid\)') "Recovery refresh responses must match the bound and player UIDs exactly."
Assert-True ($applyAuthBlock -match 'if recovery_refresh:\s+leaderboard_auth_recovery_pending_refresh_token = refresh_token\s+else:\s+leaderboard_auth_refresh_token = refresh_token') "An unverified recovery response must not replace the preserved refresh token."
$uidMismatchIndex = $applyAuthBlock.IndexOf('if not uid_transition_allowed:')
$authTokenApplyIndex = $applyAuthBlock.IndexOf('leaderboard_auth_id_token = id_token')
$playerUidApplyIndex = $applyAuthBlock.IndexOf('app.leaderboard_profile.player_id = local_id')
Assert-True ($uidMismatchIndex -ge 0 -and $uidMismatchIndex -lt $authTokenApplyIndex -and $uidMismatchIndex -lt $playerUidApplyIndex) "A UID mismatch must fail before any token or player UID is applied."
Assert-True ($profileFetchBlock -match '_leaderboard_auth_ready\(\) or _recovery_profile_read_ready\(\)') "The constrained ID token may be used only for the canonical owner-profile read."
$canonicalFlagsIndex = $profileCompleteBlock.IndexOf('if not bool(record.get("profile_claimed", false))')
$refreshCommitIndex = $profileCompleteBlock.IndexOf('leaderboard_auth_refresh_token = leaderboard_auth_recovery_pending_refresh_token')
Assert-True ($canonicalFlagsIndex -ge 0 -and $refreshCommitIndex -gt $canonicalFlagsIndex) "Recovery must remain blocked until the canonical UID, name, key, and claim flags validate."
Assert-True ($profileCompleteBlock -match 'if record_is_conclusively_missing:\s+if recovery_refresh_verification:\s+_note_recovery_profile_verification_failure') "A missing canonical profile must not unlock recovery writes."
Assert-True ($profileCompleteBlock -match 'if recovery_refresh_verification and not identity_saved:[\s\S]*leaderboard_auth_refresh_token = str\(previous_recovery_state\.get\("refresh_token"') "A local-save failure must restore the preserved refresh token and recovery gate."
Assert-True ($runtime -match 'if-match: %s') "Cloud uploads must use Firebase ETag preconditions."
Assert-True ($runtime -match 'IdentitySafety\.cloud_safe_payload') "Cloud payloads must strip authentication secrets."
Assert-True ($runtime -match '_upload_cloud_save_history\(cloud_save_last_remote_record, "before_replace"\)') "Cloud upload must archive the validated current record before replacing it."
Assert-True ($runtime -match 'cloud_save_remote_write_blocked') "Invalid current cloud records must block automatic overwrite."
Assert-True ($runtime -match 'google_recover') "Google recovery must use a distinct same-UID transition mode."
Assert-True ($runtime -match 'google_link') "Google linking must use a distinct same-UID transition mode."
Assert-True ($runtime -match 'google_legacy_authless_transition') "Legacy authless profiles must use a distinct user-initiated Google transition mode."
Assert-True ($runtime -match 'google_deleted_auth_transition' -and $runtime -match 'deleted_auth_transition') "A deleted Firebase UID must use a distinct explicit Google transition mode."
Assert-True ($runtime -match 'leaderboard_auth_definitive_failure_code' -and $runtime -match 'deleted_uid_transition_failure_code_valid') "Deleted-UID transitions must require a persisted definitive missing-user code."
Assert-True ($runtime -match 'leaderboard_deleted_auth_transition_pending') "Deleted-UID transitions must persist a pending support-transfer marker."
Assert-True ($runtime -match 'func account_recovery_code\(\) -> String:' -and $runtime -match 'T-%s S-%s' -and $runtime -match '_auth_uid_fingerprint\(target_uid\)' -and $runtime -match '_auth_uid_fingerprint\(source_uid\)') "Pending transfers must expose only stable target/source UID fingerprints as a support code."
Assert-True ($runtime -match 'leaderboard_legacy_authless_old_uid' -and $runtime -match 'leaderboard_name_transfer_required') "Legacy transitions must persist the old UID and pending username-transfer state."
Assert-True ($runtime -match 'leaderboard_legacy_username_recovery_required' -and $runtime -match 'leaderboard_legacy_name_hint_key') "Wiped legacy profiles must preserve either an untrusted name hint or an explicit support-recovery state."
Assert-True ($runtime -match 'SaveStateNormalizers\.progress_evidence_score\(payload, app\.skill_defs\) > 0') "A no-hint authless transition must require real local gameplay evidence instead of treating every fresh placeholder as legacy."
Assert-True ($runtime -match 'allow_next_identity_transition_save\(current_uid, local_id\)' -and $runtime -match 'cancel_next_identity_transition_save\(\)') "The established UID change must use and cancel the exact one-shot save identity-transition hook."
Assert-True ($runtime -match 'func complete_legacy_name_transfer\(\)' -and $runtime -match '_attempt_leaderboard_name_recovery\(\)') "Username transfer must require a separate explicit player action."
Assert-True ($runtime -match 'name_recovery_gates/%s') "Every legacy username recovery request must include the ticket-enforcing recovery gate in its atomic update."
Assert-True ($runtime -match 'and not leaderboard_name_transfer_required') "Cloud save must remain blocked while a legacy username transfer is pending."
$cloudReadyBlock = [regex]::Match($runtime, '(?s)func _cloud_save_account_ready\(\).*?(?=\r?\nfunc )').Value
Assert-True ($cloudReadyBlock -match 'leaderboard_deleted_auth_transition_pending' -and $cloudReadyBlock -match 'leaderboard_legacy_username_recovery_required' -and $cloudReadyBlock -match 'deleted_uid_transition_failure_code_valid') "Only a validated deleted-UID transition with no recoverable name may retain conflict-checked cloud backup under the chosen Google UID."
Assert-True ($runtime -match 'profile_recovery_lookup_gate' -and $runtime -match 'record_is_conclusively_missing') "Invalid local profiles must remain gated until the canonical lookup conclusively reports no record."
Assert-True ($runtime -match 'if leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required or profile_recovery_blocks_username_edit\(\):') "Queued username claims must not race a pending transfer or canonical profile lookup."
Assert-True ($normalizers -match 'existing_name_transfer_required' -and $normalizers -match 'existing_legacy_username_recovery_required' -and $normalizers -match 'existing_legacy_old_uid') "Save regression checks must preserve all pending legacy username recovery states."
Assert-True ($normalizers -match 'existing_deleted_auth_transition_pending' -and $normalizers -match 'existing_definitive_failure_code') "Save regression checks must preserve deleted-UID support-transfer evidence."
Assert-True ($profileUi -match '104 if recovery_layout_active' -and $profileUi -match 'add_theme_font_size_override\("font_size", 104\)') "Profile recovery status, inputs, and action buttons must remain readable at the mobile viewport scale."
Assert-True ($profileUi -match 'Copy Recovery Code' -and $profileUi -match 'DisplayServer\.clipboard_set\(recovery_code\)' -and $profileUi -match '_label\(recovery_code, 104') "The profile must show and copy the non-secret recovery code at the mobile-readable size."
Assert-True ($runtime -notmatch 'app\.leaderboard_profile\.display_name = LeaderboardProfile\.make_guest_display_name') "Chat must not replace a saved username with a guest name."
Assert-True ($backfill -match '\[Parameter\(Mandatory = \$true\)\]\[string\]\$AuthExportPath') "Profile backfill must require a Firebase Auth JSON export."
Assert-True ($backfill -match '\$authExport\.users' -and $backfill -match '\.localId') "Profile backfill must reconcile Firebase Auth users by localId."
Assert-True ($backfill -match '\[switch\]\$ConfirmWritesPaused' -and $backfill -match 'if \(\$Apply\)[\s\S]*?Assert-True \(\[bool\]\$ConfirmWritesPaused\)') "Applying a profile backfill must require explicit confirmation that player writes are paused."
Assert-True ($backfill -match 'exploratory-writes-not-confirmed' -and $backfill -match 'authoritative-paused-window') "Backfill output must distinguish exploratory live reads from a paused authoritative reconciliation."
Assert-True ($backfill -match "PSObject\.Properties\['disabled'\]" -and $backfill -match 'disabled_referenced_uids') "Disabled Firebase Auth users must be classified as unreachable owners."
Assert-True ($backfill -match [regex]::Escape("'^p[a-f0-9]{32}`$'")) "Profile backfill must classify only exact lowercase legacy placeholder UIDs as authless."
Assert-True (([regex]::Matches($backfill, '-cmatch \$legacyAuthlessPattern')).Count -eq 2) "Legacy authless classification must be case-sensitive for claims and canonical profiles."
Assert-True ($backfill -match 'legacy-authless uid_fingerprint=' -and $backfill -match 'SHA256') "Profile backfill must report only one-way UID fingerprints."
Assert-True ($backfill -notmatch 'Write-Output[^\r\n]*(?:uid=\$uid|profiles_by_uid/\$uid|name_claims/\$nameKey)') "Profile backfill output must not expose raw Firebase UIDs or username keys."
Assert-True ($backfill -match 'Get-ClientNameKey -DisplayName \$displayName' -and $backfill -match '\$derivedNameKey -ceq \$nameKey') "Profile backfill claims must use the same normalized display-name key expected by the client."
Assert-True ($backfill -match 'Test-CanonicalProfileMatchesPlan' -and $backfill -match 'profile_claimed -is \[bool\]' -and $backfill -match 'name_claim_verified -is \[bool\]' -and $backfill -match 'updated_at_unix') "Existing canonical profiles must pass full identity and required-field validation."
Assert-True ($backfill -match 'orphan_profiles=' -and $backfill -match 'Every existing canonical profile must have exactly one matching validated name claim') "Existing canonical profiles must never escape the claim-consistency audit."
Assert-True ($backfill -match '\$legacyAuthlessByUid\.ContainsKey\(\$uid\)[\s\S]*?continue') "Profile backfill must never create canonical profiles for legacy authless claims."
Assert-True ($backfill -match 'firebase-profile-backfill-refused missing_auth_uids=') "Profile backfill must refuse non-placeholder UIDs missing from Firebase Auth."
Assert-True ($backfill -match 'legacy-authless-cleanup-conflict') "Profile backfill must refuse existing canonical legacy authless profiles for cleanup."
Assert-True ($backfill -match 'Test-ClaimMatchesPlan -Claim \$currentClaim' -and $backfill -match 'Refusing a stale plan because the source claim changed') "Apply must re-read and verify each source name claim immediately before creating its canonical profile."
Assert-True ($recoveryResolver -match '\[Parameter\(Mandatory = \$true\)\]\[string\]\$AuthExportPath' -and $recoveryResolver -match '\[Parameter\(Mandatory = \$true\)\]\[string\]\$RtdbBackupPath') "Recovery-code lookup must require restricted Auth and RTDB snapshots."
Assert-True ($recoveryResolver -match 'SHA256' -and $recoveryResolver -match 'targetMatches\.Count -eq 1' -and $recoveryResolver -match 'sourceMatches\.Count -eq 1') "Recovery-code lookup must resolve both fingerprints uniquely."
Assert-True ($recoveryResolver -match "PSObject\.Properties\['disabled'\]" -and $recoveryResolver -match 'targetClaimCount -eq 0' -and $recoveryResolver -match 'targetProfileExists') "Recovery-code lookup must reject unreachable or already-owned target accounts."
Assert-True ($recoveryResolver -match 'seenAuthUids\.ContainsKey\(\[string\]\$sourceMatch\.uid\)' -and $recoveryResolverTest -match 'source UID that still exists in Auth must never be transferable') "Recovery-code lookup must reject a source identifier that still exists in Firebase Auth."
Assert-True ($recoveryResolver -notmatch 'Write-(?:Output|Host|Verbose|Information|Warning|Debug)') "Recovery-code lookup must not log identifiers before its final unique result object."
Assert-True ($null -ne $rules.rules.leaderboards.v1.profiles_by_uid) "Rules must include owner-readable profiles_by_uid."
Assert-True ($null -ne $rules.rules.cloud_saves.v1.history) "Rules must include bounded cloud-save history slots."
$nameClaimWrite = $rules.rules.leaderboards.v1.name_claims.'$nameKey'.'.write'
$profileWrite = $rules.rules.leaderboards.v1.profiles_by_uid.'$uid'.'.write'
$profileRead = $rules.rules.leaderboards.v1.profiles_by_uid.'$uid'.'.read'
$legacyRecoveryGateWrite = $rules.rules.leaderboards.v1.name_recovery_gates.'$uid'.'.write'
$legacyRecoveryOldUidValidate = $rules.rules.leaderboards.v1.name_recovery_gates.'$uid'.old_uid.'.validate'
$scoreWrite = $rules.rules.leaderboards.v1.scores.'$category'.'$playerId'.'.write'
$chatWrite = $rules.rules.global_chat.v1.messages.'$messageId'.'.write'
$chatGateWrite = $rules.rules.global_chat.v1.user_write_gates.'$playerId'.'.write'
$currentCloudValidate = $rules.rules.cloud_saves.v1.users.'$uid'.'.validate'
$historyWrite = $rules.rules.cloud_saves.v1.history.'$uid'.slots.'$slot'.'.write'
Assert-True ($nameClaimWrite -match "target_uid") "Recovery tickets must target one authenticated UID."
Assert-True ($nameClaimWrite -match "expires_at") "Recovery tickets must expire."
Assert-True ($nameClaimWrite -match "name_recovery_gates" -and $nameClaimWrite -match [regex]::Escape("newData.parent().parent()") -and $nameClaimWrite -match "old_uid" -and $nameClaimWrite -match [regex]::Escape("data.child('uid').val()")) "Recovery transfers must include the post-update target gate bound to the pre-write claim owner."
Assert-True ($profileWrite -match "avatar_index") "Canonical profiles must match the claimed avatar."
Assert-True ($profileWrite -match [regex]::Escape("data.child('name_key')")) "A concurrent new-name claim must not overwrite an existing canonical username."
Assert-True ($profileWrite -notmatch "name_recovery_tickets") "A recovery ticket must not override a target canonical profile created after the resolver snapshot."
Assert-True ($profileRead -match "name_claims") "Stale transferred profiles must not remain recoverable by the old UID."
Assert-True ($profileRead -match [regex]::Escape("!data.exists()")) "An owner must be able to read a missing canonical profile so legacy records can self-heal."
Assert-True ($scoreWrite -match "profiles_by_uid") "Score names and avatars must match the canonical profile."
Assert-True ($chatWrite -match "profiles_by_uid") "Claimed chat names and avatars must match the canonical profile."
Assert-True ($scoreWrite -notmatch "auth == null") "Score writes must require Firebase Auth."
Assert-True ($chatWrite -notmatch "auth == null") "Chat writes must require Firebase Auth."
Assert-True ($chatGateWrite -notmatch "auth == null") "Chat write gates must require Firebase Auth."
Assert-True ($currentCloudValidate -match "revision" -and $currentCloudValidate -match "payload_checksum") "Revisioned cloud saves must require checksums."
Assert-True ($historyWrite -match [regex]::Escape("`$slot == '4'")) "Cloud history writes must be limited to the five fixed slots."
Assert-True ($historyWrite -match "payload_checksum") "Idempotent history retries must match the protected payload checksum."
Assert-True ($legacyRecoveryGateWrite -match "name_recovery_tickets" -and $legacyRecoveryGateWrite -match "target_uid" -and $legacyRecoveryGateWrite -match "expires_at") "Legacy username recovery gates must require the expiring target-UID admin ticket."
Assert-True ($legacyRecoveryGateWrite -match "old_uid" -and $legacyRecoveryGateWrite -match "name_claims") "Legacy username recovery gates must bind the requested name to the preserved old UID."
Assert-True ($legacyRecoveryOldUidValidate -match 'A-Z' -and $legacyRecoveryOldUidValidate -match '8,48') "Support-gated recovery must accept both legacy placeholders and deleted Firebase UIDs as preserved sources."

& $backfillFixtureTestPath

if ($StaticOnly) {
    Write-Output "online-identity-safety-static-ok"
    return
}

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
	$env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserDataDir
    @'
extends SceneTree

const IdentitySafety = preload("res://scripts/online/identity_safety.gd")
const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")

var failures: Array[String] = []

func _init() -> void:
	_expect(IdentitySafety.is_local_placeholder_player_id("p0123456789abcdef0123456789abcdef"), "Fresh local placeholder ids should be recognized.")
	_expect(not IdentitySafety.is_local_placeholder_player_id("firebaseUid123456789"), "Firebase ids must not be treated as local placeholders.")
	_expect(IdentitySafety.legacy_authless_google_transition_allowed("p0123456789abcdef0123456789abcdef", "", "", "anonymous"), "A legacy authless identity shape with no credential or binding should be eligible for runtime evidence checks.")
	_expect(IdentitySafety.legacy_authless_google_transition_allowed("p0123456789abcdef0123456789abcdef", "", "p0123456789abcdef0123456789abcdef", "anonymous"), "The early hardened build's derived self-binding should remain transition-compatible.")
	_expect(not IdentitySafety.legacy_authless_google_transition_allowed("p0123456789abcdef0123456789abcdef", "refresh", "", "anonymous"), "A profile with an Auth credential must never use the authless transition.")
	_expect(not IdentitySafety.legacy_authless_google_transition_allowed("p0123456789abcdef0123456789abcdef", "", "differentFirebaseUid", "anonymous"), "A profile bound to a different UID must never use the authless transition.")
	_expect(not IdentitySafety.legacy_authless_google_transition_allowed("p0123456789abcdef0123456789abcdef", "", "", "google"), "A Google profile must never be reclassified as legacy authless.")
	_expect(not IdentitySafety.refresh_failure_is_definitive(0, ""), "Transport failures must preserve the refresh token.")
	_expect(not IdentitySafety.refresh_failure_is_definitive(429, "TOO_MANY_ATTEMPTS"), "HTTP 429 must preserve the refresh token.")
	_expect(not IdentitySafety.refresh_failure_is_definitive(503, "UNAVAILABLE"), "HTTP 5xx must preserve the refresh token.")
	_expect(not IdentitySafety.refresh_failure_is_definitive(403, "API_KEY_SERVICE_BLOCKED"), "Project configuration failures must preserve the refresh token.")
	_expect(not IdentitySafety.refresh_failure_is_definitive(401, "PERMISSION_DENIED"), "Unknown authorization failures must preserve the refresh token.")
	_expect(not IdentitySafety.refresh_failure_is_definitive(400, "INVALID_GRANT_TYPE"), "Invalid grant-type requests must not be mistaken for revoked credentials.")
	_expect(IdentitySafety.refresh_failure_is_definitive(400, "INVALID_REFRESH_TOKEN"), "An invalid refresh token must require explicit recovery.")
	_expect(IdentitySafety.refresh_failure_is_definitive(400, "TOKEN_EXPIRED: refresh token expired"), "A definitive code may include a human-readable suffix.")
	_expect(IdentitySafety.refresh_failure_code(400, "USER_NOT_FOUND: deleted") == "USER_NOT_FOUND", "Deleted Firebase users must persist an exact normalized failure code.")
	_expect(IdentitySafety.recovery_refresh_allowed(true, "saved-refresh", "firebaseUid123", "firebaseUid123", ""), "Recovery may retry a preserved refresh token only for one unchanged binding.")
	_expect(not IdentitySafety.recovery_refresh_allowed(false, "saved-refresh", "firebaseUid123", "firebaseUid123", ""), "Normal auth must not enter the recovery-only refresh path.")
	_expect(not IdentitySafety.recovery_refresh_allowed(true, "", "firebaseUid123", "firebaseUid123", ""), "Recovery must not create or exchange a new credential when the preserved token is missing.")
	_expect(not IdentitySafety.recovery_refresh_allowed(true, "saved-refresh", "firebaseUid123", "differentUid", ""), "Recovery must not refresh across a bound/player UID mismatch.")
	_expect(not IdentitySafety.recovery_refresh_allowed(true, "saved-refresh", "firebaseUid123", "firebaseUid123", "USER_NOT_FOUND"), "A definitive credential failure must require explicit account recovery.")
	_expect(IdentitySafety.recovery_refresh_response_matches_binding("firebaseUid123", "firebaseUid123", "firebaseUid123"), "A recovery response may continue only when localId matches both stored UIDs.")
	_expect(not IdentitySafety.recovery_refresh_response_matches_binding("differentUid", "firebaseUid123", "firebaseUid123"), "A different response localId must preserve the old binding.")
	_expect(not IdentitySafety.recovery_refresh_response_matches_binding("firebaseUid123", "firebaseUid123", "differentUid"), "A pre-existing bound/player mismatch must block recovery even when localId matches one side.")
	_expect(IdentitySafety.deleted_uid_transition_failure_code_valid("USER_NOT_FOUND"), "A definitive missing-user response may enter the support-gated deleted-UID transition.")
	_expect(not IdentitySafety.deleted_uid_transition_failure_code_valid("INVALID_REFRESH_TOKEN"), "An invalid local token must not authorize a different Firebase UID.")
	_expect(not IdentitySafety.deleted_uid_transition_failure_code_valid("USER_DISABLED"), "A disabled account must not be bypassed through client-side UID transition.")
	_expect(SaveStateNormalizers.progress_evidence_score({}, []) == 0, "A fresh save must not be treated as gameplay evidence.")
	_expect(SaveStateNormalizers.progress_evidence_score({"log_currency": 1}, []) > 0, "Non-XP gameplay progress must count as recovery evidence.")
	_expect(IdentitySafety.google_link_collision("FEDERATED_USER_ID_ALREADY_LINKED"), "Existing Google accounts must be recognized during link attempts.")
	var original := {
		"leaderboard_auth_refresh_token": "secret",
		"progress": 42,
		"nested": {"idToken": "secret-two", "kept": true}
	}
	var clean = IdentitySafety.cloud_safe_payload(original)
	_expect(typeof(clean) == TYPE_DICTIONARY, "Cloud-safe payload should remain a dictionary.")
	_expect(not (clean as Dictionary).has("leaderboard_auth_refresh_token"), "Cloud-safe payload must remove refresh tokens.")
	_expect(not ((clean as Dictionary).get("nested", {}) as Dictionary).has("idToken"), "Cloud-safe payload must remove nested id tokens.")
	_expect(int((clean as Dictionary).get("progress", 0)) == 42, "Cloud-safe payload must preserve progress.")
	var comparison := IdentitySafety.payload_with_preserved_identity_for_comparison(
		{"progress": 99},
		{"leaderboard_player_id": "firebaseUid123456789", "leaderboard_auth_refresh_token": "local-only-secret"}
	)
	_expect(str(comparison.get("leaderboard_auth_refresh_token", "")) == "local-only-secret", "Remote gameplay comparison must preserve local auth identity in memory.")
	_expect(int(comparison.get("progress", 0)) == 99, "Remote gameplay comparison must retain remote progress.")
	var payload_json := JSON.stringify(clean)
	var checksum := IdentitySafety.payload_checksum(payload_json)
	_expect(IdentitySafety.checksum_matches(payload_json, checksum), "Matching cloud checksums should validate.")
	_expect(not IdentitySafety.checksum_matches(payload_json + "x", checksum), "Changed cloud payloads must fail checksum validation.")
	_expect(not IdentitySafety.checksum_matches(payload_json, ""), "Missing checksums must fail for revisioned cloud records.")
	_expect(IdentitySafety.checksum_matches(payload_json, "", true), "Explicit legacy reads may accept a missing checksum for migration.")
	if failures.is_empty():
		print("online-identity-safety-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $baselineHeadlessProcessIds = @{}
    foreach ($process in @(Get-HeadlessGodotProcesses)) {
        $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
    }
    & $runner --headless --path $projectRoot --script $testScript
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $newHeadless = @()
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $newHeadless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
        if ($newHeadless.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the identity-safety test."
    }
} finally {
    if ($null -eq $previousTestUserDataDir) {
        Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousTestUserDataDir
    }
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
