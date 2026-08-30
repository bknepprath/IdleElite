# Firebase Realtime Database Leaderboard and Chat Setup
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


Idle Elite's Firebase features are deliberately cost-conservative:

- No realtime listeners are used for leaderboards.
- Global chat uses one Firebase Realtime Database REST stream while the skills chat strip or expanded chat is visible.
- The game reads only the currently visible leaderboard category.
- The game streams chat only while the skills chat strip or expanded chat is visible.
- The compact skills chat strip opens with `limitToLast=2`; the expanded chat upgrades the stream to `limitToLast=25`. Closing expanded chat keeps the live stream open and reuses cached rows for the strip instead of reconnecting.
- Failed or cancelled chat streams wait 30 seconds before reconnecting.
- Visible-category reads are cached for 15 minutes.
- Failed or rejected visible-category reads also cool down for 15 minutes before retrying.
- Player score publishes are capped client-side to once every 15 minutes.
- Chat sends are capped client-side to one message every 2 seconds.
- Failed or rejected score publishes also cool down for 15 minutes before retrying.
- Failed or rejected chat sends also cool down for 2 seconds before retrying.
- Auth cooldowns for publishing/chat, failed-read cooldowns, and write retry cooldowns are saved locally so relaunches do not immediately retry bad Firebase states.
- Successful read timestamps are session-only because leaderboard rows and chat messages are not saved locally.
- Database rules add a second 15-minute write gate per player across all categories.
- Database rules add a second 2-second write gate per player for global chat.
- Queries must be `orderBy="score"` with `limitToLast=50`, backed by `.indexOn`.
- Chat streams must use `Accept: text/event-stream`, `orderBy="created_at"`, and a capped `limitToLast`, backed by `.indexOn`.
- Reads and writes are restricted to the known Idle Elite leaderboard categories only.
- Viewing leaderboard scores and reading chat messages do not require Firebase Auth. Publishing scores, reserving names, write gates, and chat writes use Firebase Anonymous Auth so rules can bind writes to `auth.uid`.
- Google sign-in can link the Firebase Auth user to a Google account, then cloud saves store one owner-only save record under `cloud_saves/v1/users/<uid>`.

## Step Pair 1: Project and Database

1. In the Firebase console, create or open the Idle Elite project.
2. Build > Realtime Database > Create Database. Choose the closest region and start in locked mode.

Copy the database URL. It should look like:

```text
https://your-project-id-default-rtdb.firebaseio.com
```

For non-US regions, Firebase may instead show a regional URL like:

```text
https://your-project-id-default-rtdb.europe-west1.firebasedatabase.app
```

## Step Pair 2: Auth and App Config

1. Build > Authentication > Sign-in method. Enable Anonymous sign-in.
2. Enable Google sign-in. Release builds require it for account recovery and cloud save.
3. Project settings > General > Your apps. Register the Android app with package `com.idleelite.game`.
4. Add the SHA-1 fingerprint for the Google Play **App signing key certificate**. Also add the upload-key SHA-1 when testing a locally generated bundletool APK. These are different certificates when Play App Signing is enabled; registering only the upload certificate does not make Google sign-in work in the Play-delivered build.
5. Create or select a Web app in the same Firebase project and copy its Web API key.
6. Create or select the OAuth web client in that same project and copy its Web client ID. The Android Credential Manager passes this server/web client ID, not the Android OAuth client ID.
7. Confirm the Google OAuth consent configuration permits the intended closed testers or is published for the intended player audience.

The Web API key is not a secret, but leave it blank in the game until rules are published.

## Step Pair 3: Rules and Keys

For an existing production database, complete **Existing-Player Migration** below before publishing these rules.

1. In Realtime Database > Rules, paste the contents of `firebase-realtime-database.rules.json`, then publish.
2. Create the ignored local config with:

```powershell
.\scripts\write-firebase-leaderboard-config.ps1 -DatabaseUrl "https://your-project-id-default-rtdb.firebaseio.com" -WebApiKey "YOUR_WEB_API_KEY" -GoogleWebClientId "YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com"
```

Leave `firebase-leaderboard-config.json` absent until rules are published. Without that file, the game makes no leaderboard network or auth calls. The local config file is ignored by git, and `export_presets.cfg` explicitly includes it in local Android exports when the file exists in the project folder.

At runtime, the game only accepts official Firebase Realtime Database URL host formats (`firebaseio.com` and `firebasedatabase.app`) and ignores malformed API keys, so a damaged local config fails closed. Keep the database URL lowercase, matching the Firebase console URL.

The Android export keeps `permissions/internet=true`; Firebase REST calls will not work on device without that permission.

Cloud saves require Firebase Auth and are owner-only in Realtime Database rules. The game stores the normalized local save payload as `payload_json` plus summary fields, a revision, and a SHA-256 checksum. Before replacing an existing current record, the client must archive that validated record in one of five bounded history slots. Invalid current records and saves with progress that diverges in both directions are preserved rather than overwritten automatically. The profile screen lets the player connect Google; cloud checks and uploads then happen automatically during the normal save flow. Do not advertise Google backup in a public release until the Android Google sign-in bridge is included in the exported build and a device smoke test has passed.

## Existing-Player Migration

Use this order for a release that transitions existing players:

1. In Google Cloud Identity Platform settings, verify anonymous-user automatic cleanup is disabled (`autodeleteAnonymousUsers=false`). The reported week-to-month account loss pattern is consistent with anonymous-account cleanup and must be ruled out before release.
2. Create an access-controlled evidence directory under ignored `release/`, then take pre-freeze safety exports. Do not write either export to the repository root or any tracked path. The Auth export contains account identifiers and credential metadata.

```powershell
New-Item -ItemType Directory -Force .\release\firebase-migration-evidence | Out-Null
firebase auth:export .\release\firebase-migration-evidence\pre-freeze-firebase-auth-export.json --project "your-firebase-project-id" --format=json
firebase database:get / --project "your-firebase-project-id" --output .\release\firebase-migration-evidence\pre-freeze-firebase-rtdb-backup.json
```

3. If anonymous-user cleanup was enabled, stop the rollout. Disabling cleanup does not cancel anonymous accounts that were already scheduled for deletion. Back up every affected UID's Auth mapping, `name_claims`, `profiles_by_uid`, scores, and cloud-save records, then establish a verified support migration path before shipping.
4. Run an exploratory canonical-profile audit without writing. Player writes are still open, so this pass is useful for finding blockers but is not final reconciliation evidence:

```powershell
.\scripts\backfill-firebase-profiles-by-uid.ps1 -ProjectId "your-firebase-project-id" -AuthExportPath ".\release\firebase-migration-evidence\pre-freeze-firebase-auth-export.json"
```

5. Review the complete auth plan. `missing_auth_uids` is fatal for every non-placeholder UID. A referenced disabled Auth user is also fatal because it is not a reachable owner. `legacy_authless` means a claimed lowercase `p` plus 32 hexadecimal characters has no Firebase Auth user; the tool deliberately skips it instead of creating an unreachable canonical profile. `legacy_canonical_conflicts` is fatal because a prior run created a canonical profile for an authless UID and requires a reviewed backup and cleanup. Resolve every invalid claim, malformed or duplicate Auth record, disabled referenced user, duplicate-UID claim, missing-Auth UID, legacy canonical conflict, orphan canonical profile, or existing-profile conflict before applying. Every existing `profiles_by_uid` record must have exactly one matching validated claim. The tool validates the client-derived name key and every required canonical-profile identity field, flag, provider, and timestamp. It refuses the entire write pass while a fatal condition exists. Individual account identifiers are emitted only as short SHA-256 fingerprints so they do not enter CI or Codex logs.
6. Generate the temporary migration-freeze rules package. The generator first verifies that the committed final rules are current, recursively changes every `.write` rule to boolean `false`, proves that no non-false write remains, and writes the rules plus a database-only temporary `firebase.json` under ignored `release/`:

```powershell
.\scripts\write-firebase-migration-freeze-rules.ps1
```

7. Deploy the freeze from its temporary directory. This intentionally pauses every player database write while preserving the final rules' reads, indexes, and validation. Do not use the repository's normal `firebase.json` for this step, and do not leave the freeze deployed longer than the reconciliation window:

```powershell
Push-Location .\release\firebase-migration-freeze
try {
    firebase deploy --config .\firebase.json --only database --project "your-firebase-project-id"
    if ($LASTEXITCODE -ne 0) {
        throw "Migration-freeze deployment failed."
    }
} finally {
    Pop-Location
}
```

8. After the freeze deployment succeeds, take fresh authoritative Auth and RTDB snapshots. These filenames are the evidence inputs used later by the release receipt:

```powershell
$authEvidence = ".\release\firebase-migration-evidence\firebase-auth-export.json"
$rtdbEvidence = ".\release\firebase-migration-evidence\firebase-rtdb-backup.json"
Remove-Item -LiteralPath $authEvidence, $rtdbEvidence -Force -ErrorAction SilentlyContinue
firebase auth:export $authEvidence --project "your-firebase-project-id" --format=json
if ($LASTEXITCODE -ne 0) { throw "Firebase Auth export failed." }
firebase database:get / --project "your-firebase-project-id" --output $rtdbEvidence
if ($LASTEXITCODE -ne 0) { throw "Firebase RTDB backup failed." }
```

9. Run the paused-window plan, review it, then apply the canonical-profile backfill. `-ConfirmWritesPaused` is an operator acknowledgement; the deployed freeze is what actually blocks player writes. Apply re-reads the exact source claim and target profile immediately before every create:

```powershell
.\scripts\backfill-firebase-profiles-by-uid.ps1 -ProjectId "your-firebase-project-id" -AuthExportPath ".\release\firebase-migration-evidence\firebase-auth-export.json" -ConfirmWritesPaused
.\scripts\backfill-firebase-profiles-by-uid.ps1 -ProjectId "your-firebase-project-id" -AuthExportPath ".\release\firebase-migration-evidence\firebase-auth-export.json" -ConfirmWritesPaused -Apply
```

10. Refresh the Auth export, then run the paused-window dry audit again. It must report no remaining creates or conflicts against the latest Auth state. Refresh the RTDB backup after the applied backfill so the receipt hashes the reconciled state, not the pre-apply state:

```powershell
Remove-Item -LiteralPath .\release\firebase-migration-evidence\firebase-auth-export.json -Force -ErrorAction SilentlyContinue
firebase auth:export .\release\firebase-migration-evidence\firebase-auth-export.json --project "your-firebase-project-id" --format=json
if ($LASTEXITCODE -ne 0) { throw "Final Firebase Auth export failed." }
.\scripts\backfill-firebase-profiles-by-uid.ps1 -ProjectId "your-firebase-project-id" -AuthExportPath ".\release\firebase-migration-evidence\firebase-auth-export.json" -ConfirmWritesPaused
Remove-Item -LiteralPath .\release\firebase-migration-evidence\firebase-rtdb-backup.json -Force -ErrorAction SilentlyContinue
firebase database:get / --project "your-firebase-project-id" --output .\release\firebase-migration-evidence\firebase-rtdb-backup.json
if ($LASTEXITCODE -ne 0) { throw "Final Firebase RTDB backup failed." }
```

11. Run the generated-rules check and local Firebase preflight, then replace the freeze with the authenticated final rules. If reconciliation is not clean, do not deploy the final rules or create a readiness receipt:

```powershell
.\scripts\check-firebase-leaderboard-preflight.ps1
.\scripts\deploy-firebase-leaderboard-rules.ps1 -ProjectId "your-firebase-project-id"
```

12. Create the ignored, version-bound release receipt. This command records only hashes, sizes, confirmations, and the release version. It does not copy player records or Firebase identifiers into Git. This is an operator attestation gate, not a live Firebase, Google Cloud, or Play Console verifier. Supply every confirmation only after checking it against the configured production project.

```powershell
.\scripts\write-firebase-migration-readiness-receipt.ps1 `
    -AuthExportPath ".\release\firebase-migration-evidence\firebase-auth-export.json" `
    -RtdbBackupPath ".\release\firebase-migration-evidence\firebase-rtdb-backup.json" `
    -ConfirmAnonymousCleanupDisabled `
    -ConfirmSnapshotsMatchConfiguredProject `
    -ConfirmPlayerWritesPausedDuringFinalReconciliation `
    -ConfirmBackfillAppliedAndReconciled `
    -ConfirmCanonicalRulesDeployed `
    -ConfirmGoogleProviderEnabled `
    -ConfirmGoogleOAuthAudienceReady `
    -ConfirmPlaySigningSha1Registered `
    -ConfirmUploadSha1Registered `
    -ConfirmSupportTransferProcedureReady
```

13. Run `.\scripts\check-firebase-migration-readiness.ps1`. The Android release builder runs the same check and refuses to export when the receipt is missing, stale, for another Firebase target, or for another version.
14. Release the updated game. Existing local usernames and gameplay progress remain in the same save schema and transition in place. A surviving anonymous Firebase identity is linked to Google; it is not silently switched to a different Firebase UID. During normal linking or same-UID recovery, selecting a Google account owned by another authenticated profile leaves the current profile unchanged.

Legacy authless `p` plus 32-hex profiles require the explicit profile-screen Google transition. For a valid claimed profile, or a wiped-flag profile that still has a syntactically valid non-guest display/name-key hint, the client preserves the local username, gameplay, name hint, and old UID, saves the new Google UID with `leaderboard_name_transfer_required=true`, and pauses cloud upload, score publishing, chat writes, and profile-reference writes. A hint remains untrusted and wiped claimed/verified flags remain false; valid preexisting flags may remain in the local save but cannot authorize writes while transfer is pending. The client does not move the server name claim automatically.

If no usable name hint remains but the save contains gameplay evidence, the explicit Google transition still preserves progress. It saves the old UID with `leaderboard_legacy_username_recovery_required=true`, permits the normal conflict-checked cloud-save flow, and keeps score, chat, new-name claims, and profile-reference writes paused. Support can identify the old claim from the preserved old UID and tell the player which existing username to enter under **Recover Approved Username**. The atomic server request still requires that existing claim to belong to the preserved old UID and requires the expiring target-UID ticket. A zero-progress unclaimed placeholder continues through normal fresh Google sign-in and is not classified as a legacy account.

A normal Firebase UID is allowed to switch to a different Google-backed UID only after its stored refresh credential receives a definitive `USER_NOT_FOUND` response from Firebase. The client persists that normalized failure code, the deleted source UID, the chosen Google UID, local gameplay, and any valid local name hint under a distinct `google_deleted_auth_transition` state. `INVALID_REFRESH_TOKEN`, `TOKEN_EXPIRED`, configuration failures, transport failures, and `USER_DISABLED` do not authorize this different-UID path. They remain same-UID recovery or support cases.

The deleted-UID transition does not move a server claim. If a valid name or hint exists, cloud upload, score publishing, chat writes, new-name claims, and profile-reference writes remain paused until the existing claim is transferred with an expiring ticket targeted to the chosen Google UID. If no usable name hint exists, conflict-checked cloud backup may proceed under the chosen Google UID while username, score, chat, and profile-reference writes remain support-gated. The client clears the deleted-account marker, failure code, and source UID only after the ticketed atomic name/profile transfer returns success. Before issuing a ticket, support must verify the player, confirm the chosen target UID, and review any canonical profile already attached to that target UID; the client never treats the local failure marker, local save, or public source UID as ownership proof.

Support must verify the player and selected target Firebase Auth UID, create the expiring ticket described below, and have the player press **Complete Username Transfer** or **Recover Approved Username** as applicable. A local save, public score row, chat row, player ID, name hint, failure code, or knowledge of the name is not proof of ownership because identifiers were public and the save is not server-signed.

After the Google transition, the profile screen shows a non-secret recovery code in the form `T-<12 hex> S-<12 hex>` and a **Copy Recovery Code** button. The two values are truncated SHA-256 fingerprints of the chosen target UID and preserved source UID; the UI does not expose either raw UID or an auth token. Have the player send only that code. After receiving it, take fresh case-specific Auth and RTDB snapshots on an access-controlled support machine. Do not reuse the rollout receipt snapshots: a target Google UID created after release cannot appear in an older Auth export.

```powershell
New-Item -ItemType Directory -Force ".\release\firebase-support-evidence\CASE-ID" | Out-Null
firebase auth:export ".\release\firebase-support-evidence\CASE-ID\firebase-auth-export.json" --project "your-firebase-project-id" --format=json
firebase database:get / --project "your-firebase-project-id" --output ".\release\firebase-support-evidence\CASE-ID\firebase-rtdb-backup.json"
```

Resolve the code against those fresh restricted snapshots:

```powershell
.\scripts\resolve-firebase-account-recovery-code.ps1 `
    -RecoveryCode "T-0123456789ab S-fedcba987654" `
    -AuthExportPath ".\release\firebase-support-evidence\CASE-ID\firebase-auth-export.json" `
    -RtdbBackupPath ".\release\firebase-support-evidence\CASE-ID\firebase-rtdb-backup.json"
```

The resolver is read-only. It refuses malformed snapshots, disabled or ambiguous targets, zero or multiple source-claim matches, any source UID still present in Auth, and targets that already own a claim or canonical profile. It logs no raw identifier while refusing a request. Only a unique, conflict-free result prints the raw target UID, source UID, name key, display name, and avatar needed for the operator's reviewed ticket workflow. Keep that result in the restricted support case. A unique code lookup identifies database records; it does not verify that the requester owns them.

Do not publish the authenticated-only rules until the updated client and the ticket-handling support procedure are ready. Legacy authless players keep their local progress if they update after the rules change, but their online writes remain paused until the explicit Google transition and approved name transfer finish.

Older builds may lose mutation access after the authenticated-only rules are published, but public leaderboard and chat reads remain available. This prevents older authless clients from impersonating another saved player ID during the rollout.

## Duplicate Name Protection

Leaderboard names are reserved in `leaderboards/v1/name_claims/<name_key>` before the profile is locked locally. The client derives `name_key` by lowercasing the display name and collapsing spaces, hyphens, and underscores. If Firebase rejects the claim because another UID already owns that key, the profile UI shows `name is taken!`.

Score rows and claimed-name chat messages include `name_key`, and RTDB rules require the name, key, and avatar to match both the authenticated UID's claim and canonical `profiles_by_uid` record. This adds one finite REST `PUT` when a player saves a leaderboard name; it does not add any realtime listeners.

## Name Recovery Tickets

If a legitimate player is stuck because their locked local name points at an old UID in `name_claims`, first verify the Firebase Auth UID they are recovering. Create a short-lived admin ticket containing that exact target UID and an expiry in Unix epoch milliseconds:

```text
leaderboards/v1/name_recovery_tickets/<name_key>/active = true
leaderboards/v1/name_recovery_tickets/<name_key>/target_uid = <verified Firebase Auth UID>
leaderboards/v1/name_recovery_tickets/<name_key>/expires_at = <Unix epoch milliseconds>
```

Use a short validity window, such as 15 minutes. RTDB rules require `target_uid == auth.uid` and `expires_at >= now`; a name-only active flag is not sufficient.

Before transfer, record the old claim UID for the support case and verify that the ticket's target UID is the Google-authenticated UID shown by the recovery session. The source may be a legacy `p` plus 32-hex identifier or a deleted Firebase UID; in both cases the existing claim must still name that exact source. After the ticket exists, ask the player to reopen the updated build and press **Complete Username Transfer**. If the local name hint was lost, tell the player the verified existing username and have them enter it under **Recover Approved Username**. That explicit action atomically writes `name_recovery_gates/<target_uid>`, re-saves the locked name claim, and saves its canonical `profiles_by_uid/<target_uid>` record. Rules require the gate's `old_uid` to own the existing claim and require the same active target-UID ticket even if the requested name path would otherwise be creatable. The client clears its saved old UID and pending-recovery state only after Firebase accepts the complete atomic update. A denied or failed request retains the recovery state.

The old UID's stale `profiles_by_uid` record becomes unreadable as soon as the claim moves. After the player confirms recovery, use an admin-authenticated backup-and-cleanup operation to remove that stale old-UID profile and any superseded target-UID claim/profile references, then remove the ticket even if its expiry has passed. Never let a player client delete canonical profiles.

## Global Chat Moderation

Global chat is public, anonymous-Firebase-backed, and deliberately small:

- Display name, claimed name key, avatar index, anonymous Firebase uid, message text, created timestamp, and deletion tombstone fields may be stored.
- Message text is capped to 80 characters.
- The client masks exact banned-word tokens before sending. This is a light client-side guardrail, not a substitute for moderation.
- The client shows deleted messages as moderator-removed tombstones instead of removing the row from history.
- Player clients cannot edit or delete messages after posting.
- Moderator deletion requires a Firebase Auth custom claim: `moderator: true`.

Use Firebase Admin tooling outside the game to grant the moderator custom claim only to trusted Firebase Auth users. After a moderator signs in and obtains an ID token with that claim, local tools can inspect and tombstone messages:

```powershell
.\scripts\read-firebase-chat-messages.ps1 -ModeratorIdToken "FIREBASE_MODERATOR_ID_TOKEN" -Limit 25
.\scripts\remove-firebase-chat-message.ps1 -ModeratorIdToken "FIREBASE_MODERATOR_ID_TOKEN" -MessageId "MESSAGE_ID" -Reason "Reason for deletion"
```

These tools use capped REST reads and moderator tombstone writes. They do not hard-delete message rows.

Prune old chat rows with a Firebase CLI admin session. Keep the latest 50 messages:

```powershell
.\scripts\prune-firebase-chat-messages.ps1 -ProjectId "idle-elite" -Keep 50 -DryRun
.\scripts\prune-firebase-chat-messages.ps1 -ProjectId "idle-elite" -Keep 50
```

This helper uses Firebase CLI admin access instead of loosening player delete rules.

The realtime chat listener is justified because the feature is explicitly a global live chat. To keep it cost-safe, the game opens exactly one capped RTDB Server-Sent Events stream only on the chat surfaces, closes it immediately off-screen, does not save chat rows locally, and reconnects with a cooldown after failures or rules cancellations.

If you prefer the Firebase CLI after signing in, `firebase.json` maps only the Realtime Database rules file. Deploy rules with:

```powershell
.\scripts\deploy-firebase-leaderboard-rules.ps1 -ProjectId "your-firebase-project-id"
```

The helper runs the generated-rules check and cost-safety audit before calling `firebase deploy --only database`. To verify the local deploy target without contacting Firebase, run:

```powershell
.\scripts\deploy-firebase-leaderboard-rules.ps1 -ProjectId "your-firebase-project-id" -CheckOnly
```

## Step Pair 4: Budget and Usage Alerts

1. In Google Cloud Console > Billing > Budgets & alerts, create a small budget for the Firebase project. Use low thresholds while testing, for example 25%, 50%, 75%, 90%, and 100%.
2. In Firebase console > Realtime Database > Usage, verify you can see connection, storage, and download usage. Also enable Firebase alert emails for your individual account.

Budget alerts notify you; they are not a hard spending cap. The leaderboard code and rules are therefore written to reduce accidental reads/writes before billing gets involved.

Official references:

- Firebase Realtime Database security rules: https://firebase.google.com/docs/database/security
- Realtime Database query-based rules: https://firebase.google.com/docs/database/security/rules-conditions
- Identity Platform automatic cleanup for anonymous users: https://cloud.google.com/identity-platform/docs/anonymous-user-cleanup
- Realtime Database billing and budget-alert guidance: https://firebase.google.com/docs/database/usage/billing
- Realtime Database locations and URL formats: https://firebase.google.com/docs/database/locations
- Google Cloud budgets and alerts: https://docs.cloud.google.com/billing/docs/how-to/budgets

## Smoke Test Checklist

Before shipping a build:

1. Open the leaderboard with Firebase values still blank. Confirm the game says Firebase is not connected and performs no network work.
2. Add the database URL and Web API key after rules are published.
3. Open only one leaderboard category. Confirm one public GET request hits `/leaderboards/v1/scores/<category>.json?orderBy=%22score%22&limitToLast=50` with no `auth` query parameter.
4. Switch away from and back to the same category inside 15 minutes. The cached rows should be reused rather than issuing another GET.
5. Earn score. Confirm one authenticated write claims `player_write_gates/<playerId>`, followed by at most one authenticated score PATCH every 15 minutes from the device.
6. Try a second write inside 15 minutes, even to another category. Firebase rules should reject it even if the client gate failed.
7. On a skills page, confirm one public compact RTDB stream opens with `Accept: text/event-stream` at `/global_chat/v1/messages.json?orderBy=%22created_at%22&limitToLast=2`.
8. Open expanded chat. Confirm the stream reconnects with `limitToLast=25`.
9. Close expanded chat. Confirm the RTDB stream stays open and the compact strip reuses cached rows with no downgrade reconnect to `limitToLast=2`.
10. Leave the skills/chat surfaces. Confirm the RTDB stream closes and does not continue in the background.
11. Send two chat messages quickly. The second should be blocked by the client and rejected by rules if forced.
12. Tombstone a test chat message with the moderation script and confirm the game renders it as removed in the live stream.
13. Connect Google from the profile screen. Confirm Firebase Auth shows the user linked to the Google provider.
14. After normal gameplay progress saves, confirm an authenticated `PUT` writes `cloud_saves/v1/users/<uid>` with `uid`, summary fields, `revision`, `payload_checksum`, and `payload_json`.
15. On the next upload, confirm the prior validated current record reaches `cloud_saves/v1/history/<uid>/slots/<0..4>` before the current-record PUT begins. A failed history write must leave the current record unchanged.
16. Restart or use a second install/device signed into the same Google account. Confirm the game performs a bounded authenticated cloud-save check, can recover a valid history record when current is missing or invalid, and does not allow older cloud saves to reduce local progress.
17. Create progress unique to two devices and confirm the game reports a conflict without automatically replacing either save.
18. Load a claimed legacy authless `p` plus 32-hex profile with no Auth export match. Connect Google and confirm the local username and gameplay remain unchanged, the old UID and pending-transfer flag survive restart, and no cloud, score, chat, or profile-reference write occurs. Repeat with claimed/verified flags wiped but a valid non-guest display/name-key hint; confirm the hint is preserved separately and remains untrusted until ticketed transfer succeeds.
19. Without an admin ticket, press **Complete Username Transfer** and confirm Firebase rejects the request while the local transition state remains. Create a short-lived ticket for the exact target UID, press the button again, and confirm the name claim and canonical target-UID profile move together before the local pending state clears.
20. Load an invalid or wiped local username with a surviving refresh token and bound UID. Open Profile and confirm the username field and claim button stay disabled through authentication and the canonical profile GET. Confirm a valid record restores the username, a transport, `404`, permission, or invalid-record response remains blocked, and only a successful authenticated response whose JSON body is exactly `null` enables a new username.
21. Load a progressed legacy authless profile with no usable name hint. Connect Google and confirm the old UID and support-recovery flag survive restart, cloud conflict checks and backup work, and score/chat/profile claims remain paused. Verify **Recover Approved Username** fails for an unused or wrong name even with no claim collision, fails for the correct old name without a ticket, and succeeds only when the old UID owns that claim and the active ticket targets the authenticated Google UID.

Run the local guardrail audit before any Firebase-enabled build:

```powershell
.\scripts\check-leaderboard-cost-safety.ps1
```

Check where local setup stands without contacting Firebase:

```powershell
.\scripts\check-firebase-leaderboard-setup-state.ps1
```

Run the full local preflight before Android testing or release:

```powershell
.\scripts\check-firebase-leaderboard-preflight.ps1
```

The preflight includes no-network config writer and runtime guard tests that accept both official Realtime Database URL formats and reject placeholders, malformed hosts, or malformed keys before a real config file is created.

After rules are published and `firebase-leaderboard-config.json` exists, run a read-only live smoke test:

```powershell
.\scripts\test-firebase-leaderboard-live-read.ps1 -Category total_level
```

This performs one public top-1 REST read for the requested visible category. It does not create an auth user and does not write leaderboard data. The combined Total category uses `total_level`; skill categories can use either game ids such as `skill_xp:fight` or Firebase path keys such as `skill_xp__fight`.

If the activity database gains or renames skills, regenerate the Firebase category allowlist first:

```powershell
.\scripts\update-firebase-leaderboard-rules.ps1
.\scripts\update-firebase-leaderboard-rules.ps1 -Check
```
