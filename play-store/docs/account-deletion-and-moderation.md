# Account deletion and chat moderation

Support mailbox: weskillnow@gmail.com. Public request page: https://idle-elite.web.app/delete-account.html.

## Ownership verification

Do not delete data based only on a public player name or UID. For a Google-linked account, require a request from the email on its Firebase Authentication record and verify the account association. For an anonymous account, send a unique temporary verification name to the requester and ask them to set it in the game; verify the change on the same authenticated UID before proceeding. Never request a password, token or sign-in code. If ownership cannot be verified, explain the remaining verification step instead of deleting data.

## Fulfill a verified deletion request

Use the Firebase Console for project idle-elite with an authorized administrator. Record the verified UID and the request scope. Do not execute a deletion while a player is still using the account; ask them to close the app first.

1. Disable the verified Authentication user to prevent new writes during removal. Revoke refresh tokens where supported.
2. Locate the UID’s current and previous cloud saves under `cloud_saves/v1`; remove every revision associated with that UID.
3. Remove `leaderboards/v1/profiles_by_uid/<uid>`, name claims whose stored `uid` matches, score rows in every category for the UID, and related per-user write/recovery/transfer records. Inspect the current database rules and records; never delete another UID merely because it shares a display name.
4. Find `global_chat/v1/messages` entries by `sender_id`. Remove that user’s messages, reports for those messages, reports made by the UID, chat and report write gates, and associated moderation records unless a specific legal retention obligation applies.
5. Delete the verified Firebase Authentication user, including the Google link. Do not delete the person’s Google account.
6. Re-read the targeted paths and Authentication record to confirm removal. Check cloud history, aliases and name claims again. Confirm completion to the requester, explaining any specific legally required retention. Do not attach raw records or tokens to the reply.
7. Instruct the requester to clear local app data if they also want the device save removed. Relaunching can create a new anonymous account; it must not be mistaken for the deleted account.

## Review chat reports

Reports are stored privately at `global_chat/v1/reports/<message_id>/<reporter_uid>`, containing a reason and server timestamp. Only administrators and authenticated moderator accounts can read them. Players cannot edit or delete reports, report themselves, report nonexistent messages, or submit more than one report per minute. A reporter can report a message once.

Review reports regularly and before each release. Inspect the referenced message and context; do not automatically punish a player based on the number of reports. Use the existing moderation tools to hide violating messages and record the reason. For repeated or severe violations, disable the offending authenticated account’s online access through the authorized moderation process. Address appeals through the support mailbox. Block controls only hide messages for the blocking player and do not replace moderation.

After resolving a report, archive only the minimum necessary moderation record and remove the resolved queue entry through administrator tools. Never change client rules to make reports public or allow players to moderate other users.

## Release prerequisites

Publish the three `public/*.html` policy pages, deploy the additive report rules after emulator validation, and update Play Console privacy/deletion URLs and Data safety disclosures. Configure AdMob privacy messages for app 1607281974. Validate consent forms on an Android device before release.
