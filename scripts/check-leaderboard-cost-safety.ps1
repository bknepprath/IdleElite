$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $projectRoot "scripts\main.gd"
$rulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"
$activityDatabasePath = Join-Path $projectRoot "docs\activity-database.json"
$setupGuidePath = Join-Path $projectRoot "docs\firebase-leaderboard-setup.md"
$gitignorePath = Join-Path $projectRoot ".gitignore"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$firebaseJsonPath = Join-Path $projectRoot "firebase.json"
$rulesGeneratorPath = Join-Path $projectRoot "scripts\update-firebase-leaderboard-rules.ps1"
$setupStatePath = Join-Path $projectRoot "scripts\check-firebase-leaderboard-setup-state.ps1"
$runtimeGuardPath = Join-Path $projectRoot "scripts\test-firebase-leaderboard-runtime-guard.ps1"
$liveReadSmokePath = Join-Path $projectRoot "scripts\test-firebase-leaderboard-live-read.ps1"
$configValidationPath = Join-Path $projectRoot "scripts\test-firebase-leaderboard-config-validation.ps1"
$rulesDeployPath = Join-Path $projectRoot "scripts\deploy-firebase-leaderboard-rules.ps1"
$chatReadToolPath = Join-Path $projectRoot "scripts\read-firebase-chat-messages.ps1"
$chatDeleteToolPath = Join-Path $projectRoot "scripts\remove-firebase-chat-message.ps1"
$chatPruneToolPath = Join-Path $projectRoot "scripts\prune-firebase-chat-messages.ps1"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-JsonProp {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) {
        return $null
    }
    return $prop.Value
}

Assert-True (Test-Path -LiteralPath $mainPath) "Missing scripts\main.gd"
Assert-True (Test-Path -LiteralPath $rulesPath) "Missing firebase-realtime-database.rules.json"
Assert-True (Test-Path -LiteralPath $activityDatabasePath) "Missing docs\activity-database.json"
Assert-True (Test-Path -LiteralPath $setupGuidePath) "Missing docs\firebase-leaderboard-setup.md"
Assert-True (Test-Path -LiteralPath $gitignorePath) "Missing .gitignore"
Assert-True (Test-Path -LiteralPath $exportPresetsPath) "Missing export_presets.cfg"
Assert-True (Test-Path -LiteralPath $firebaseJsonPath) "Missing firebase.json"
Assert-True (Test-Path -LiteralPath $rulesGeneratorPath) "Missing scripts\update-firebase-leaderboard-rules.ps1"
Assert-True (Test-Path -LiteralPath $setupStatePath) "Missing scripts\check-firebase-leaderboard-setup-state.ps1"
Assert-True (Test-Path -LiteralPath $runtimeGuardPath) "Missing scripts\test-firebase-leaderboard-runtime-guard.ps1"
Assert-True (Test-Path -LiteralPath $liveReadSmokePath) "Missing scripts\test-firebase-leaderboard-live-read.ps1"
Assert-True (Test-Path -LiteralPath $configValidationPath) "Missing scripts\test-firebase-leaderboard-config-validation.ps1"
Assert-True (Test-Path -LiteralPath $rulesDeployPath) "Missing scripts\deploy-firebase-leaderboard-rules.ps1"
Assert-True (Test-Path -LiteralPath $chatReadToolPath) "Missing scripts\read-firebase-chat-messages.ps1"
Assert-True (Test-Path -LiteralPath $chatDeleteToolPath) "Missing scripts\remove-firebase-chat-message.ps1"
Assert-True (Test-Path -LiteralPath $chatPruneToolPath) "Missing scripts\prune-firebase-chat-messages.ps1"

$main = Get-Content -LiteralPath $mainPath -Raw
$rules = Get-Content -LiteralPath $rulesPath -Raw | ConvertFrom-Json
$rulesRaw = Get-Content -LiteralPath $rulesPath -Raw
$setupGuide = Get-Content -LiteralPath $setupGuidePath -Raw
$gitignore = Get-Content -LiteralPath $gitignorePath -Raw
$exportPresets = Get-Content -LiteralPath $exportPresetsPath -Raw
$firebaseJson = Get-Content -LiteralPath $firebaseJsonPath -Raw | ConvertFrom-Json
$rulesGenerator = Get-Content -LiteralPath $rulesGeneratorPath -Raw
$setupState = Get-Content -LiteralPath $setupStatePath -Raw
$runtimeGuard = Get-Content -LiteralPath $runtimeGuardPath -Raw
$activityDatabase = Get-Content -LiteralPath $activityDatabasePath -Raw | ConvertFrom-Json
$liveReadSmoke = Get-Content -LiteralPath $liveReadSmokePath -Raw
$configValidation = Get-Content -LiteralPath $configValidationPath -Raw
$rulesDeploy = Get-Content -LiteralPath $rulesDeployPath -Raw
$chatReadTool = Get-Content -LiteralPath $chatReadToolPath -Raw
$chatDeleteTool = Get-Content -LiteralPath $chatDeleteToolPath -Raw
$chatPruneTool = Get-Content -LiteralPath $chatPruneToolPath -Raw
$skillIds = @($activityDatabase.skills | ForEach-Object { $_.id } | Where-Object { $_ })
Assert-True ($skillIds.Count -gt 0) "Activity database must define leaderboard skill categories."
$expectedCategoryKeys = @("total_level", "medals_earned", "total_xp") + @($skillIds | ForEach-Object { "skill_xp__$_" }) + @("elite_heavenly")
foreach ($categoryKey in $expectedCategoryKeys) {
    Assert-True ($categoryKey -match '^[a-z0-9_-]+$') "Generated leaderboard category key '$categoryKey' is unsafe for Firebase paths."
}

Assert-True ($main -match 'const FIREBASE_DATABASE_URL := ""') "Firebase URL must default to blank so fresh builds make no leaderboard network calls."
Assert-True ($main -match 'const FIREBASE_WEB_API_KEY := ""') "Firebase Web API key must default to blank so fresh builds make no leaderboard auth calls."
Assert-True ($main -match 'const FIREBASE_LOCAL_CONFIG_PATH := "res://firebase-leaderboard-config\.json"') "Firebase config must use the expected local opt-in config file."
Assert-True ($main -match '_leaderboard_load_firebase_config') "Leaderboard must load Firebase values from the local opt-in config file."
Assert-True ($main -match 'const LEADERBOARD_FIREBASE_US_HOST_SUFFIX := "\.firebaseio\.com"') "Game runtime must explicitly allow official US Realtime Database URLs."
Assert-True ($main -match 'const LEADERBOARD_FIREBASE_REGIONAL_HOST_SUFFIX := "\.firebasedatabase\.app"') "Game runtime must explicitly allow official regional Realtime Database URLs."
Assert-True ($main -match 'func _leaderboard_database_url_allowed\(url: String\) -> bool:') "Game runtime must reject malformed Firebase database URLs before any network call."
Assert-True ($main -match 'if not _leaderboard_database_url_allowed\(url\):\s*\r?\n\s*return ""') "Firebase base URL must be blanked when the configured database URL is not allowlisted."
Assert-True ($main -match 'host\.find\("your-project"\) >= 0 or host\.find\("your_project"\) >= 0') "Game runtime must reject placeholder Firebase database URLs."
Assert-True ($main -match 'if key\.length\(\) < 20 or key\.find\(" "\) >= 0 or key\.find\("\\t"\) >= 0 or key\.find\("\\n"\) >= 0 or key\.find\("\\r"\) >= 0:\s*\r?\n\s*return ""') "Game runtime must reject placeholder or whitespace-damaged Firebase Web API keys."
Assert-True ($gitignore -match '(?m)^firebase-leaderboard-config\.json$') "Local Firebase config must be ignored by git."
Assert-True ($exportPresets -match 'include_filter="[^"]*firebase-leaderboard-config\.json') "Android export must explicitly include the local Firebase config when present."
Assert-True ($exportPresets -match 'include_filter="[^"]*docs/activity-database\.json') "Android export must explicitly include the activity database JSON."
Assert-True ($exportPresets -match '(?m)^permissions/internet=true$') "Android export must include INTERNET permission for Firebase REST calls."
Assert-True ([string]$firebaseJson.database.rules -eq "firebase-realtime-database.rules.json") "firebase.json must deploy the generated Realtime Database rules file."
Assert-True ($rulesGenerator -match "\^\[a-z0-9_-\]\+\$") "Rules generator must reject category keys with Firebase-unsafe characters."
Assert-True ($rulesGenerator -match '\$duplicateCategoryKeys\s*=\s*@\(\$categoryKeys \| Group-Object') "Rules generator must reject duplicate category keys before emitting rules."
Assert-True ($main -match 'const LEADERBOARD_SUBMIT_INTERVAL_SECONDS := 60 \* 60') "Client write interval must stay at one hour."
Assert-True ($main -match 'func _leaderboard_has_pending_category_score\(\) -> bool:') "Submit readiness must detect pending category score improvements."
Assert-True ($main -match 'return _leaderboard_profile_claim_valid\(\) and _leaderboard_has_pending_category_score\(\) and _leaderboard_next_submit_seconds\(\) <= 0') "Submit readiness must require a claimed unique name, a pending category score, and the hourly submit gate."
Assert-True ($main -match 'const LEADERBOARD_FETCH_INTERVAL_SECONDS := 15 \* 60') "Visible-category reads must stay cached for at least 15 minutes."
Assert-True ($main -match 'const LEADERBOARD_PROCESS_INTERVAL_SECONDS := 30\.0') "Leaderboard sync tick must stay calm; expected 30 seconds."
Assert-True ($main -match 'const LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS := 15 \* 60') "Failed Firebase auth must cool down for at least 15 minutes."
Assert-True ($main -match 'func _leaderboard_fetch_category\(category_id: String, allow_recent_refresh := false\)') "Visible-category reads must default to honoring the 15-minute cache."
Assert-True ($main -match 'if not allow_recent_refresh and last_fetch > 0 and now - last_fetch < LEADERBOARD_FETCH_INTERVAL_SECONDS') "Leaderboard reads must enforce the 15-minute cache unless explicitly refreshed after a write."
Assert-True ($main -match '(?s)var last_success_fetch := int\(leaderboard_fetch_unix_by_category\.get\(valid_id, 0\)\).*?var last_failed_fetch := int\(leaderboard_fetch_retry_unix_by_category\.get\(valid_id, 0\)\).*?var last_fetch := maxi\(last_success_fetch, last_failed_fetch\).*?if not allow_recent_refresh and last_fetch > 0 and now - last_fetch < LEADERBOARD_FETCH_INTERVAL_SECONDS:.*?return.*?if not _leaderboard_ensure_auth\(\):') "Fresh visible-category cache hits must return before Firebase Auth refresh/sign-up work."
Assert-True ($main -match '(?s)func _leaderboard_fetch_category\(category_id: String, allow_recent_refresh := false\) -> void:.*?if not _leaderboard_firebase_enabled\(\):.*?return.*?if not _leaderboard_ensure_auth\(\):') "Visible-category reads must bail out before auth when Firebase config is absent or malformed."
Assert-True ($main -match '(?s)func _leaderboard_submit_scores\(\) -> void:.*?if not _leaderboard_firebase_enabled\(\):.*?return.*?if not _leaderboard_ensure_auth\(\):') "Leaderboard writes must bail out before auth when Firebase config is absent or malformed."
Assert-True ($main -match '_leaderboard_note_fetch_failure') "Leaderboard read failures must use the fetch cooldown helper."
Assert-True ($main -match 'leaderboard_fetch_retry_unix_by_category\[valid_id\] = _unix_now\(\)') "Leaderboard read failures must update the persisted category retry gate to avoid rapid retries."
Assert-True ($main -match 'var last_failed_fetch := int\(leaderboard_fetch_retry_unix_by_category\.get\(valid_id, 0\)\)') "Leaderboard reads must honor persisted failure retry gates."
Assert-True ($main -match 'Trying again in %s\." % \[message, _format_duration\(float\(LEADERBOARD_FETCH_INTERVAL_SECONDS\)\)\]') "Leaderboard read failures must cool down for the visible-category fetch interval."
Assert-True ($main -match '"leaderboard_fetch_retry_unix_by_category": leaderboard_fetch_retry_unix_by_category') "Leaderboard failure read cooldowns must be saved across relaunches."
Assert-True ($main -match 'var saved_fetch_retry_unix = data\.get\("leaderboard_fetch_retry_unix_by_category", \{\}\)') "Leaderboard failure read cooldowns must be loaded across relaunches."
Assert-True ($main -match 'Successful rows are not saved, so successful fetch timestamps intentionally reset on launch\.') "Successful fetch timestamps must reset on launch because row data is not persisted."
Assert-True ($main -notmatch '"leaderboard_fetch_unix_by_category": leaderboard_fetch_unix_by_category') "Successful fetch timestamps must not be saved without saved row data."
Assert-True ($main -match 'if current_screen == "leaderboard":\s*\r?\n\s*_leaderboard_fetch_category\(leaderboard_category_id\)') "Reads must only be requested for the visible leaderboard screen/category."
Assert-True ($main -match '(?s)func _process_leaderboard_sync\(delta: float\) -> void:.*?if not _leaderboard_firebase_enabled\(\):\s*\r?\n\s*return.*?if current_screen == "leaderboard":') "Background leaderboard sync must return before fetch/submit work when Firebase config is absent or malformed."
Assert-True ([regex]::Matches($main, '_leaderboard_fetch_category\(leaderboard_category_id, true\)').Count -eq 1) "Only one code path may bypass the read cache: the post-write visible-category refresh."
Assert-True ($main -match 'var query := "orderBy=%%22score%%22&limitToLast=%s" % LEADERBOARD_TOP_COUNT') "Reads must be ordered by score and capped to the top count."
Assert-True ($main -match 'HTTPClient\.METHOD_GET') "Leaderboard must use finite REST GET reads, not realtime listeners."
Assert-True ($main -match 'HTTPClient\.METHOD_PATCH') "Leaderboard writes must use one finite REST PATCH."
Assert-True ($main -match 'updates\["player_write_gates/%s" % leaderboard_player_id\]') "Writes must include the shared per-player hourly write gate."
Assert-True ($main -match 'FIREBASE_AUTH_SIGN_UP_URL') "Leaderboard must use Firebase Anonymous Auth before database access."
Assert-True ($main -match 'FIREBASE_AUTH_REFRESH_URL') "Leaderboard must refresh the anonymous auth token instead of creating a new account every launch."
Assert-True ($main -notmatch 'signInWithIdp|IdleEliteGoogleSignIn|_start_google_account_link|google_link') "Leaderboard-only beta must not expose dormant Google sign-in code paths."
Assert-True ($main -match 'leaderboard_auth_refresh_token') "Leaderboard auth refresh token must be persisted for account reuse."
Assert-True ($main -match 'leaderboard_auth_retry_after_unix') "Leaderboard auth failures must have a persisted in-memory retry deadline."
Assert-True ($main -match '_leaderboard_note_auth_failure') "Leaderboard auth failures must use the retry cooldown helper."
Assert-True ($main -match '"leaderboard_auth_retry_after_unix": leaderboard_auth_retry_after_unix') "Leaderboard auth retry deadlines must be saved across relaunches."
Assert-True ($main -match 'leaderboard_auth_retry_after_unix = maxi\(0, int\(data\.get\("leaderboard_auth_retry_after_unix", 0\)\)\)') "Leaderboard auth retry deadlines must be loaded across relaunches."
Assert-True ($main -match '_leaderboard_note_submit_failure') "Leaderboard write failures must use the submit cooldown helper."
Assert-True ($main -match 'leaderboard_last_submit_unix = _unix_now\(\)') "Leaderboard write failures must update the submit gate to avoid rapid retries."
Assert-True ($main -match 'Trying again in %s\." % \[message, _format_duration\(float\(LEADERBOARD_SUBMIT_INTERVAL_SECONDS\)\)\]') "Leaderboard write failures must cool down for the hourly submit interval."
Assert-True ($main -match '_leaderboard_authenticated_query') "Database REST calls must include the Firebase auth token."
Assert-True ($main -notmatch 'WebSocket|WebSocketPeer|connect_to_url') "WebSocket-style realtime transports are not allowed."
Assert-True ($main -match 'const CHAT_FIREBASE_ROOT := "global_chat/v1"') "Chat must use the expected Firebase root."
Assert-True ($main -match 'const CHAT_STREAM_RETRY_INTERVAL_SECONDS := 30') "Chat stream reconnects must cool down for at least 30 seconds after failure."
Assert-True ($main -match 'const CHAT_SEND_INTERVAL_SECONDS := 2') "Chat sends must stay client-limited to one message every two seconds."
Assert-True ($main -match 'const CHAT_STRIP_VISIBLE_COUNT := 2') "Chat strip reads must stay capped to 2 visible messages."
Assert-True ($main -match 'const CHAT_FULL_VISIBLE_COUNT := 25') "Full chat reads must stay capped to 25 visible messages."
Assert-True ($main -match 'const CHAT_MESSAGE_MAX_CHARS := 80') "Chat messages must stay capped to 80 characters."
Assert-True ($main -match 'CHAT_CENSORED_WORDS') "Chat must include a local banned-word filter."
Assert-True ($main -match 'const CHAT_STRIP_ICON := "res://assets/ui/chat-speech-bubble\.png"') "Chat strip must use the generated speech bubble icon asset."
Assert-True ($main -match 'func _chat_strip_visible_on_current_screen\(\) -> bool:\s*\r?\n\s*return current_screen == "menu" or current_screen == "skill"') "Chat strip must appear only on the skills menu and skill detail pages."
Assert-True ($main -notmatch 'chat_tab') "Chat must not be a bottom-nav tab."
Assert-True ($main -notmatch 'current_screen = "chat"') "Chat must not be a standalone menu screen."
Assert-True ($main -match 'func _process_chat_live_sync\(delta: float\) -> void:') "Chat must have an explicit visible-screen live sync loop."
Assert-True ($main -match '(?s)func _process_chat_live_sync\(delta: float\) -> void:.*?if not _chat_strip_visible_on_current_screen\(\):.*?_chat_stream_disconnect\(false\).*?return') "Chat realtime stream must close when the skills chat strip is not visible."
Assert-True ($main -match 'var query := "orderBy=%%22created_at%%22&limitToLast=%s" % visible_count') "Chat reads must query by created_at with the active capped visible count."
Assert-True ($main -match 'func _chat_target_visible_count\(\) -> int:') "Chat must switch stream limits by compact strip vs full chat."
Assert-True ($main -match 'Accept: text/event-stream') "Chat must use Firebase RTDB REST streaming."
Assert-True ($main -match 'chat_stream_client\.connect_to_host') "Chat must open exactly one explicit HTTPS stream client."
Assert-True ($main -match '_chat_stream_disconnect\(false\)') "Chat must explicitly disconnect the stream off-screen."
Assert-True ($main -match 'chat_send_request\.request\(') "Chat must use finite REST PATCH writes."
Assert-True ($main -match '"user_write_gates/%s" % leaderboard_player_id') "Chat writes must include the shared per-player two-second write gate."
Assert-True ($main -match '"chat_last_send_unix": chat_last_send_unix') "Chat send cooldown must be saved across relaunches."
Assert-True ($main -match '"chat_stream_retry_unix": chat_stream_retry_unix') "Chat stream reconnect cooldown must be saved across relaunches."
Assert-True ($main -match 'Chat rows are not saved; the realtime stream is reopened only while the skills chat strip is visible\.') "Chat rows must not be persisted locally."
Assert-True ($main -notmatch '"chat_rows": chat_rows') "Chat rows must not be saved locally."
Assert-True ($main -match 'one Firebase RTDB Server-Sent Events stream') "Chat UI must disclose that live chat uses one RTDB SSE stream."

$leaderboardRequests = [regex]::Matches($main, 'leaderboard_(fetch|submit)_request\.request\(').Count
Assert-True ($leaderboardRequests -eq 2) "Expected exactly two leaderboard HTTP request sites: one GET and one PATCH."
$leaderboardAuthRequests = [regex]::Matches($main, 'leaderboard_auth_request\.request\(').Count
Assert-True ($leaderboardAuthRequests -eq 2) "Expected exactly two auth request sites: anonymous sign-up and token refresh."

$rootRules = Get-JsonProp $rules "rules"
Assert-True ($null -ne $rootRules) "Rules JSON must contain a top-level rules object."
Assert-True ($rulesRaw -notmatch '\\u0026|\\u0027|\\u003c|\\u003e') "Rules file should keep Firebase rule expressions readable for console review."
Assert-True ((Get-JsonProp $rootRules ".read") -eq $false) "Database root .read must default to false."
Assert-True ((Get-JsonProp $rootRules ".write") -eq $false) "Database root .write must default to false."

$leaderboards = Get-JsonProp $rootRules "leaderboards"
$v1 = Get-JsonProp $leaderboards "v1"
$scores = Get-JsonProp $v1 "scores"
$nameClaims = Get-JsonProp $v1 "name_claims"
$nameClaim = Get-JsonProp $nameClaims '$nameKey'
$category = Get-JsonProp $scores '$category'
$player = Get-JsonProp $category '$playerId'
$gates = Get-JsonProp $v1 "player_write_gates"
$gatePlayer = Get-JsonProp $gates '$playerId'
$globalChat = Get-JsonProp $rootRules "global_chat"
$chatV1 = Get-JsonProp $globalChat "v1"
$chatMessages = Get-JsonProp $chatV1 "messages"
$chatMessage = Get-JsonProp $chatMessages '$messageId'
$chatGates = Get-JsonProp $chatV1 "user_write_gates"
$chatGatePlayer = Get-JsonProp $chatGates '$playerId'
$chatModerationLogs = Get-JsonProp $chatV1 "moderation_logs"
$chatModerationLog = Get-JsonProp $chatModerationLogs '$logId'

Assert-True ($null -ne $nameClaim) "Rules must define leaderboards/v1/name_claims/<nameKey>."
Assert-True ((Get-JsonProp $nameClaim ".read") -eq $false) "Name claims must not be publicly readable."
Assert-True ((Get-JsonProp $nameClaim ".write") -match [regex]::Escape("!data.exists() || data.child('uid').val() == auth.uid")) "Name claims must reject duplicate names owned by another user."
Assert-True ((Get-JsonProp $nameClaim ".write") -match [regex]::Escape("newData.child('uid').val() == auth.uid")) "Name claims must be bound to the authenticated anonymous UID."
Assert-True ((Get-JsonProp (Get-JsonProp $nameClaim "name_key") ".validate") -match "^[\s\S]*matches") "Name claim keys must be shape-validated."

Assert-True ($null -ne $category) "Rules must define leaderboards/v1/scores/<category>."
$categoryReadRule = Get-JsonProp $category ".read"
$categoryWriteRule = Get-JsonProp $player ".write"
Assert-True ($categoryReadRule -match "query.orderByChild == 'score' && query.limitToLast != null && query.limitToLast > 0 && query.limitToLast <= 50") "Reads must require score ordering and an explicit 1..50 limitToLast bound."
Assert-True ($categoryReadRule -match "auth != null") "Leaderboard reads must require Firebase Auth."
foreach ($categoryKey in $expectedCategoryKeys) {
    Assert-True ($categoryReadRule -match [regex]::Escape("'$categoryKey'")) "Read rules must allow known category $categoryKey."
    Assert-True ($categoryWriteRule -match [regex]::Escape("'$categoryKey'")) "Write rules must allow known category $categoryKey."
}
Assert-True (@(Get-JsonProp $category ".indexOn") -contains "score") "Scores must be indexed by score."
Assert-True ($categoryWriteRule -match [regex]::Escape('auth.uid == $playerId')) "Score writes must be bound to the authenticated anonymous UID."
Assert-True ($categoryWriteRule -match "name_claims") "Score writes must require ownership of the submitted name key."
Assert-True ($categoryWriteRule -match "newData.exists\(\)") "Score writes must reject client deletes."
Assert-True ($categoryWriteRule -match "player_write_gates") "Score writes must depend on the shared per-player write gate."
Assert-True ($categoryWriteRule -match "newData.child\('score'\).val\(\) == data.child\('score'\).val\(\)") "Leaderboard profile refreshes must not change scores."
Assert-True ($categoryWriteRule -match "updated_at'\)\.val\(\) >= now - 10000") "Score writes must require a fresh gate timestamp from the same write."
Assert-True ($categoryWriteRule -match "updated_at'\)\.val\(\) <= now \+ 60000") "Score writes must reject far-future gate timestamps."

$scoreRule = Get-JsonProp (Get-JsonProp $player "score") ".validate"
Assert-True ($scoreRule -match "newData.val\(\) >= data.val\(\)") "Scores must be monotonic per player/category."
Assert-True ((Get-JsonProp $player ".validate") -match "newData.hasChildren") "Score rows must require the expected child fields."
Assert-True ((Get-JsonProp $player ".validate") -match "name_key") "Score rows must store the claimed name key."
Assert-True ($null -ne (Get-JsonProp $player '$other')) "Score rows must reject unexpected fields."

Assert-True ($null -ne $gatePlayer) "Rules must define leaderboards/v1/player_write_gates/<playerId>."
Assert-True ((Get-JsonProp $gatePlayer ".read") -eq $false) "Write gates must not be readable."
Assert-True ((Get-JsonProp $gatePlayer ".write") -match [regex]::Escape('auth.uid == $playerId')) "Write gates must be bound to the authenticated anonymous UID."
Assert-True ((Get-JsonProp $gatePlayer ".write") -match "newData.exists\(\)") "Write gates must reject client deletes."
Assert-True ((Get-JsonProp $gatePlayer ".write") -match "3600000") "Firebase rules must enforce at least one hour between player writes."
Assert-True ((Get-JsonProp $gatePlayer ".validate") -match "newData.hasChildren") "Write gates must require the expected child fields."
Assert-True ($null -ne (Get-JsonProp $gatePlayer '$other')) "Write gates must reject unexpected fields."
Assert-True ((Get-JsonProp (Get-JsonProp $gatePlayer "updated_at") ".validate") -match "newData.val\(\) >= now - 10000") "Write gate timestamps must be fresh."
Assert-True ((Get-JsonProp (Get-JsonProp $gatePlayer "updated_at") ".validate") -match "newData.val\(\) <= now \+ 60000") "Write gate timestamps must reject far-future values."
Assert-True ($null -ne $chatMessages) "Rules must define global_chat/v1/messages."
Assert-True ((Get-JsonProp $chatMessages ".read") -match "query.orderByChild == 'created_at'") "Chat reads must require created_at ordering."
Assert-True ((Get-JsonProp $chatMessages ".read") -match "query.limitToLast != null && query.limitToLast > 0 && query.limitToLast <= 25") "Chat reads must require an explicit 1..25 limitToLast bound."
Assert-True (@(Get-JsonProp $chatMessages ".indexOn") -contains "created_at") "Chat messages must be indexed by created_at."
Assert-True ((Get-JsonProp $chatMessage ".write") -match [regex]::Escape("newData.child('sender_id').val() == auth.uid")) "Chat message creates must be bound to the authenticated anonymous UID."
Assert-True ((Get-JsonProp $chatMessage ".write") -match "name_claims") "Chat message creates must require ownership of the submitted name key."
Assert-True ((Get-JsonProp $chatMessage ".write") -match "user_write_gates") "Chat message creates must depend on the shared per-player write gate."
Assert-True ((Get-JsonProp $chatMessage ".write") -match "updated_at'\)\.val\(\) >= now - 10000") "Chat message creates must require a fresh gate timestamp from the same write."
Assert-True ((Get-JsonProp $chatMessage ".write") -match "updated_at'\)\.val\(\) <= now \+ 60000") "Chat message creates must reject far-future gate timestamps."
Assert-True ((Get-JsonProp $chatMessage ".write") -match "data.child\('sender_id'\).val\(\) == auth.uid") "Chat profile refreshes must be restricted to the original sender."
Assert-True ((Get-JsonProp $chatMessage ".write") -match "auth.token.moderator == true") "Chat message moderation must require a moderator custom claim."
Assert-True ((Get-JsonProp $chatMessage ".write") -match "newData.child\('deleted'\).val\(\) == true") "Chat moderation must use deletion tombstones."
Assert-True ((Get-JsonProp $chatMessage ".write") -match "newData.child\('text'\).val\(\) == data.child\('text'\).val\(\)") "Chat moderation must not rewrite message text."
Assert-True ((Get-JsonProp (Get-JsonProp $chatMessage "text") ".validate") -match "length <= 80") "Chat messages must be capped to 80 characters."
Assert-True ($null -ne (Get-JsonProp $chatMessage "name_key")) "Chat messages must validate the claimed name key when present."
Assert-True ((Get-JsonProp (Get-JsonProp $chatMessage "deleted") ".validate") -match "newData.val\(\) == false") "Player-created chat messages must start undeleted."
Assert-True ($null -ne (Get-JsonProp $chatMessage '$other')) "Chat messages must reject unexpected fields."
Assert-True ($null -ne $chatGatePlayer) "Rules must define global_chat/v1/user_write_gates/<playerId>."
Assert-True ((Get-JsonProp $chatGatePlayer ".read") -eq $false) "Chat write gates must not be readable."
Assert-True ((Get-JsonProp $chatGatePlayer ".write") -match "2000") "Firebase rules must enforce at least two seconds between chat writes."
Assert-True ((Get-JsonProp (Get-JsonProp $chatGatePlayer "updated_at") ".validate") -match "newData.val\(\) >= now - 10000") "Chat write gate timestamps must be fresh."
Assert-True ((Get-JsonProp (Get-JsonProp $chatGatePlayer "updated_at") ".validate") -match "newData.val\(\) <= now \+ 60000") "Chat write gate timestamps must reject far-future values."
Assert-True ((Get-JsonProp $chatModerationLog ".read") -match "auth.token.moderator == true") "Chat moderation logs must be readable only by moderators."
Assert-True ((Get-JsonProp $chatModerationLog ".write") -match "auth.token.moderator == true") "Chat moderation logs must be writable only by moderators."
Assert-True ($chatReadTool -match 'limitToLast=\{0\}') "Chat read moderation helper must keep an explicit read limit."
Assert-True ($chatReadTool -match '\$safeLimit = \[Math\]::Min\(\[Math\]::Max\(\$Limit, 1\), 25\)') "Chat read moderation helper must cap reads to 25."
Assert-True ($chatPruneTool -match '\$safeKeep = \[Math\]::Min\(\[Math\]::Max\(\$Keep, 1\), 500\)') "Chat prune helper must bound its keep count."
Assert-True ($chatPruneTool -match 'database:get /global_chat/v1/messages') "Chat prune helper must read the chat collection through Firebase CLI."
Assert-True ($chatPruneTool -match 'database:remove') "Chat prune helper must physically remove old chat rows."
Assert-True ($chatPruneTool -match '\[switch\]\$DryRun') "Chat prune helper must support dry runs."
Assert-True ($chatDeleteTool -match 'Invoke-RestMethod -Method Get') "Chat delete helper must read the existing message before tombstoning it."
Assert-True ($chatDeleteTool -match 'Invoke-RestMethod -Method Patch') "Chat delete helper must write a moderation tombstone."
Assert-True ($chatDeleteTool -match 'moderation_logs') "Chat delete helper must create a moderation log."

Assert-True ($liveReadSmoke -notmatch 'Invoke-RestMethod\s+-Method\s+(Patch|Put|Delete)') "Live Firebase smoke helper must stay read-only for database data."
Assert-True ($liveReadSmoke -match 'Invoke-RestMethod\s+-Method\s+Get') "Live Firebase smoke helper must use one finite REST GET."
Assert-True ([regex]::Matches($liveReadSmoke, 'Invoke-RestMethod\s+-Method\s+Get').Count -eq 1) "Live Firebase smoke helper must have exactly one database GET request site."
Assert-True ([regex]::Matches($liveReadSmoke, 'leaderboards/v1/scores').Count -eq 1) "Live Firebase smoke helper must target exactly one leaderboard scores endpoint."
Assert-True ($liveReadSmoke -match '\$databaseReadCount \+= 1') "Live Firebase smoke helper must count its database read."
Assert-True ($liveReadSmoke -match 'firebase-live-db-read-count-ok count=\$databaseReadCount') "Live Firebase smoke helper must report the database read count."
Assert-True ($liveReadSmoke -match 'orderBy=%22score%22&limitToLast=1') "Live Firebase smoke helper must use the same encoded score query shape as the game."
Assert-True ($liveReadSmoke -match 'limitToLast=1') "Live Firebase smoke helper must limit live reads to one row."
Assert-True ($liveReadSmoke -match 'docs\\activity-database\.json') "Live Firebase smoke helper must derive its category allowlist from the activity database."
Assert-True ($liveReadSmoke -match '\$categoryKey = \$Category\.Trim\(\)\.Replace\(":", "__"\)') "Live Firebase smoke helper must normalize game category ids to Firebase path keys."
Assert-True ($liveReadSmoke -match 'firebase-leaderboard-live-read-auth-\$projectCacheKey\.json') "Live Firebase smoke helper auth cache must be scoped to the Firebase project host."
Assert-True ($liveReadSmoke -match 'firebasedatabase\\\.app') "Live Firebase smoke helper must accept regional Realtime Database URLs."
Assert-True ($rulesDeploy -match 'check-leaderboard-cost-safety\.ps1') "Rules deploy helper must run the cost-safety audit before publishing rules."
Assert-True ($rulesDeploy -match 'update-firebase-leaderboard-rules\.ps1"\) -Check') "Rules deploy helper must verify generated rules are current before publishing."
Assert-True ($rulesDeploy -match '\[switch\]\$CheckOnly') "Rules deploy helper must support a local check-only mode."
Assert-True ($rulesDeploy -match 'firebase-leaderboard-rules-deploy-check-ok') "Rules deploy helper check-only mode must report success without deploying."
Assert-True ($rulesDeploy -match 'firebase deploy --only database --project') "Rules deploy helper must use a database-only Firebase rules deploy."
Assert-True ($rulesDeploy -notmatch 'database:(set|update|push|remove)') "Rules deploy helper must not write or delete database data."
Assert-True ($setupState -match 'update-firebase-leaderboard-rules\.ps1"\) -Check') "Setup state helper must verify generated rules are current."
Assert-True ($setupState -match 'firebase-setup-state-config-absent') "Setup state helper must report when local Firebase config is absent."
Assert-True ($setupState -match 'firebase-setup-state-config-ok') "Setup state helper must report when local Firebase config is valid."
Assert-True ($setupState -match '-cmatch \$firebaseDatabaseUrlPattern') "Setup state helper must validate Firebase database URLs case-sensitively."
Assert-True ($setupState -notmatch 'Invoke-RestMethod|HTTPClient|firebase deploy') "Setup state helper must not perform network or deploy work."
Assert-True ($runtimeGuard -match 'run-godot-safe\.ps1') "Runtime guard test must use the safe Godot wrapper."
Assert-True ($runtimeGuard -match '--script \$testScript') "Runtime guard test must run as a one-shot headless script."
Assert-True ($runtimeGuard -match 'firebase-runtime-guard-ok') "Runtime guard test must report success."
Assert-True ($runtimeGuard -match 'your-project-id-default-rtdb\.firebaseio\.com') "Runtime guard test must reject placeholder Firebase database URLs."
Assert-True ($runtimeGuard -match '_leaderboard_firebase_base_url\(\) == ""') "Runtime guard test must prove malformed Firebase hosts fail closed through the base URL getter."
Assert-True ($runtimeGuard -match '_leaderboard_firebase_api_key\(\) == ""') "Runtime guard test must prove malformed Firebase API keys fail closed through the API key getter."
Assert-True ($runtimeGuard -match '_leaderboard_fetch_category\(game\.LEADERBOARD_CATEGORY_TOTAL_LEVEL\)') "Runtime guard test must exercise visible-category fetch with absent Firebase config."
Assert-True ($runtimeGuard -match '_leaderboard_submit_scores\(\)') "Runtime guard test must exercise score submit with absent Firebase config."
Assert-True ($runtimeGuard -match '_process_leaderboard_sync\(31\.0\)') "Runtime guard test must exercise the background sync loop with absent Firebase config."
Assert-True ($runtimeGuard -match '_expect_leaderboard_requests_idle') "Runtime guard test must assert no Firebase request state starts with absent config."
Assert-True ($runtimeGuard -match 'game\.free\(\)') "Runtime guard test must free the temporary game object before exiting."
Assert-True ($runtimeGuard -match 'Remove-Item -LiteralPath \$testDir -Recurse -Force') "Runtime guard test must clean its temporary files."
Assert-True ($runtimeGuard -match 'Get-HeadlessGodotProcesses') "Runtime guard test must verify no headless Godot process remains."
Assert-True ($runtimeGuard -notmatch 'Invoke-RestMethod|HTTPClient|firebase deploy') "Runtime guard test must not perform network or deploy work."
Assert-True ($setupGuide -match 'Budget and Usage Alerts') "Firebase setup guide must include budget and usage alert steps."
Assert-True ($setupGuide -match 'Budgets & alerts') "Firebase setup guide must point to Google Cloud Billing budgets and alerts."
Assert-True ($setupGuide -match '25%, 50%, 75%, 90%, and 100%') "Firebase setup guide must recommend low budget alert thresholds while testing."
Assert-True ($setupGuide -match 'Budget alerts notify you; they are not a hard spending cap') "Firebase setup guide must warn that budget alerts are notifications, not hard caps."
Assert-True ($setupGuide -match 'Realtime Database > Usage') "Firebase setup guide must include Realtime Database usage review after setup."

$preflight = Get-Content -LiteralPath (Join-Path $projectRoot "scripts\check-firebase-leaderboard-preflight.ps1") -Raw
$configWriter = Get-Content -LiteralPath (Join-Path $projectRoot "scripts\write-firebase-leaderboard-config.ps1") -Raw
Assert-True ($preflight -match 'firebasedatabase\\\.app') "Preflight must accept regional Realtime Database URLs."
Assert-True ($preflight -match 'test-firebase-leaderboard-config-validation\.ps1') "Preflight must run the no-network Firebase config validation tests."
Assert-True ($preflight -match 'check-firebase-leaderboard-setup-state\.ps1') "Preflight must run the no-network Firebase setup state check."
Assert-True ($preflight -match 'deploy-firebase-leaderboard-rules\.ps1"\) -ProjectId "idle-elite-check" -CheckOnly') "Preflight must run the no-network Firebase rules deploy check."
Assert-True ($configWriter -match 'firebasedatabase\\\.app') "Config writer must accept regional Realtime Database URLs."
Assert-True ($configWriter -match '-cmatch \$firebaseDatabaseUrlPattern') "Config writer must validate Firebase database URLs case-sensitively."
Assert-True ($configWriter -match '\$OutputPath') "Config writer must support an alternate output path for no-network validation."
Assert-True ($configValidation -match 'firebase-config-validation-ok') "Config validation test must report success."
Assert-True ($configValidation -match 'europe-west1\.firebasedatabase\.app') "Config validation test must cover regional Realtime Database URLs."
Assert-True ($configValidation -match 'your-project-id-default-rtdb\.firebaseio\.com') "Config validation test must reject placeholder database URLs."
Assert-True ($configValidation -match 'uppercase-host') "Config validation test must reject uppercase Firebase database URL hosts."
Assert-True ($configValidation -match 'finally') "Config validation test must clean temporary files after validation."
Assert-True ($configValidation -match 'Remove-Item -LiteralPath \$testDir -Recurse -Force') "Config validation test must remove its temporary config directory."
Assert-True ($configValidation -notmatch 'Invoke-RestMethod|HTTPClient|firebase deploy') "Config validation test must not perform network or deploy work."

Write-Output "leaderboard-cost-safety-ok"
