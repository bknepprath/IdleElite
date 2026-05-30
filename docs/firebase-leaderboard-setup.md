# Firebase Realtime Database Leaderboard and Chat Setup

Idle Elite's Firebase features are deliberately cost-conservative:

- No realtime listeners are used for leaderboards.
- Global chat uses one Firebase Realtime Database REST stream while the skills chat strip or expanded chat is visible.
- The game reads only the currently visible leaderboard category.
- The game streams chat only while the skills chat strip or expanded chat is visible.
- The compact skills chat strip streams only `limitToLast=2`; the expanded chat streams `limitToLast=25`.
- Failed or cancelled chat streams wait 30 seconds before reconnecting.
- Visible-category reads are cached for 15 minutes.
- Failed or rejected visible-category reads also cool down for 15 minutes before retrying.
- Player score publishes are capped client-side to once per hour.
- Chat sends are capped client-side to one message every 2 seconds.
- Failed or rejected score publishes also cool down for one hour before retrying.
- Failed or rejected chat sends also cool down for 2 seconds before retrying.
- Auth, failed-read, and write retry cooldowns are saved locally so relaunches do not immediately retry bad Firebase states.
- Successful read timestamps are session-only because leaderboard rows and chat messages are not saved locally.
- Database rules add a second hourly write gate per player across all categories.
- Database rules add a second 2-second write gate per player for global chat.
- Queries must be `orderBy="score"` with `limitToLast=50`, backed by `.indexOn`.
- Chat streams must use `Accept: text/event-stream`, `orderBy="created_at"`, and a capped `limitToLast`, backed by `.indexOn`.
- Reads and writes are restricted to the known Idle Elite leaderboard categories only.
- Firebase Anonymous Auth is required so rules can bind each row and write gate to `auth.uid`.
- This beta does not ship Google sign-in or cloud saves.

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
2. Project settings > General > Your apps. Create or select a Web app and copy its Web API key.

The Web API key is not a secret, but leave it blank in the game until rules are published.

## Step Pair 3: Rules and Keys

1. In Realtime Database > Rules, paste the contents of `firebase-realtime-database.rules.json`, then publish.
2. Create the ignored local config with:

```powershell
.\scripts\write-firebase-leaderboard-config.ps1 -DatabaseUrl "https://your-project-id-default-rtdb.firebaseio.com" -WebApiKey "YOUR_WEB_API_KEY"
```

Leave `firebase-leaderboard-config.json` absent until rules are published. Without that file, the game makes no leaderboard network or auth calls. The local config file is ignored by git, and `export_presets.cfg` explicitly includes it in local Android exports when the file exists in the project folder.

At runtime, the game only accepts official Firebase Realtime Database URL host formats (`firebaseio.com` and `firebasedatabase.app`) and ignores malformed API keys, so a damaged local config fails closed. Keep the database URL lowercase, matching the Firebase console URL.

The Android export keeps `permissions/internet=true`; Firebase REST calls will not work on device without that permission.

Google sign-in and cloud saves are intentionally out of scope for this Firebase beta. Do not advertise account recovery or save backup until a native Android Google sign-in bridge and a separate cloud-save rules/audit pass are implemented.

## Duplicate Name Protection

Leaderboard names are reserved in `leaderboards/v1/name_claims/<name_key>` before the profile is locked locally. The client derives `name_key` by lowercasing the display name and collapsing spaces, hyphens, and underscores. If Firebase rejects the claim because another UID already owns that key, the profile UI shows `name is taken!`.

Score rows and chat messages include `name_key`, and RTDB rules require that key to be owned by the authenticated anonymous UID. This adds one finite REST `PUT` when a player saves a leaderboard name; it does not add any realtime listeners.

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
- Realtime Database billing and budget-alert guidance: https://firebase.google.com/docs/database/usage/billing
- Realtime Database locations and URL formats: https://firebase.google.com/docs/database/locations
- Google Cloud budgets and alerts: https://docs.cloud.google.com/billing/docs/how-to/budgets

## Smoke Test Checklist

Before shipping a build:

1. Open the leaderboard with Firebase values still blank. Confirm the game says Firebase is not connected and performs no network work.
2. Add the database URL and Web API key after rules are published.
3. Open only one leaderboard category. Confirm one anonymous auth request, then one GET request hits `/leaderboards/v1/scores/<category>.json?orderBy=%22score%22&limitToLast=50&auth=<idToken>`.
4. Switch away from and back to the same category inside 15 minutes. The cached rows should be reused rather than issuing another GET.
5. Earn score. Confirm at most one PATCH request hits `/leaderboards/v1.json?print=silent` per hour from the device. It should include score updates plus `player_write_gates/<playerId>`.
6. Try a second write inside an hour, even to another category. Firebase rules should reject it even if the client gate failed.
7. On a skills page, confirm one compact RTDB stream opens with `Accept: text/event-stream` at `/global_chat/v1/messages.json?orderBy=%22created_at%22&limitToLast=2&auth=<idToken>`.
8. Open expanded chat. Confirm the stream reconnects with `limitToLast=25`.
9. Leave the skills/chat surfaces. Confirm the RTDB stream closes and does not continue in the background.
10. Send two chat messages quickly. The second should be blocked by the client and rejected by rules if forced.
11. Tombstone a test chat message with the moderation script and confirm the game renders it as removed in the live stream.

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

This reuses a per-Firebase-project cached anonymous smoke-test refresh token in `.codex-tmp` when available, then performs one top-1 REST read for the requested visible category. It does not write leaderboard data. Add `-ResetAuth` if you intentionally want a fresh anonymous smoke-test user. Skill categories can use either game ids such as `skill_xp:fight` or Firebase path keys such as `skill_xp__fight`.

If the activity database gains or renames skills, regenerate the Firebase category allowlist first:

```powershell
.\scripts\update-firebase-leaderboard-rules.ps1
.\scripts\update-firebase-leaderboard-rules.ps1 -Check
```
