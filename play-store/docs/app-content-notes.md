# Idle Elite Google Play app content

Current implementation: 0.7.2, version code 43. These are implementation-backed answers for the Console; the saved Console form still needs verification after the public pages are deployed.

## Accounts and deletion

- Account creation/sign-in: anonymous Firebase identity and optional Google OAuth linking. No email/password credential creation in the game.
- Google sign-in and cloud saves are implemented. Do not reuse the old statement that they are absent.
- Account and data deletion: https://idle-elite.web.app/delete-account.html, linked from Settings → Privacy & chat → Delete account / data. Publish and verify this URL before marking deletion available in Console.
- Privacy policy: https://idle-elite.web.app/privacy.html. Public source: `public/privacy.html`.
- Developer/support: WeSkillNow, weskillnow@gmail.com.
- Data in transit: HTTPS.

## Data types and purposes

| Data | Collection | Sharing | Purpose and choice |
| --- | --- | --- | --- |
| Player name | Collected | Public profile/rankings/chat, selected by the player | App functionality and account management; player chooses a display name |
| Email address | Collected by Firebase Authentication when Google is linked | Service-provider processing; no public email display | Account management, backup and recovery; optional Google linking |
| User IDs | Collected | Public Firebase UID accompanies rankings/chat; SDK/account identifiers may also be processed by Google | Account management, app functionality and abuse prevention |
| Other in-app messages | Public chat and reports collected | Chat is public; reports are private to authorized moderation | App functionality and abuse prevention; optional posting/reporting |
| App interactions / gameplay | Rankings, progress and optional cloud saves; AdMob interactions | Public rankings and Google advertising/measurement | App functionality; ad delivery, analytics and fraud prevention for SDK data |
| Approximate location | AdMob may infer it from IP address | Google advertising ecosystem | Advertising, analytics, fraud prevention |
| Diagnostics | AdMob SDK diagnostics | Google advertising ecosystem | Advertising, analytics, fraud prevention |
| Device or other IDs | AdMob advertising/app-set IDs; Firebase account identifiers | Google advertising ecosystem where applicable | Advertising, analytics, fraud prevention; account functionality |

Local crash logs are not automatically uploaded; the player can copy and share a report. The game does not request precise location, contacts, camera, microphone or health data. There are no in-app purchases. Public sharing initiated by the player and service-provider processing may qualify for Play’s disclosure exceptions; apply the current form definitions without omitting collection.

Online data is retained rather than processed only ephemerally. Cloud-save and public-chat use are optional; Firebase identity is created for online functionality. Do not mark all identifiers optional merely because rewarded ads are optional. Google’s Mobile Ads SDK initializes only after UMP permits an ad request, and actual rewarded ad display requires a player action.

## Ads and UGC

- Contains ads: yes. Uses Advertising ID: yes; permission supplied by Google Mobile Ads SDK.
- UMP 4.0.0 gates initialization and ad loading; required privacy choices are accessible from Settings.
- Configure and publish European and US state messages in AdMob for app `ca-app-pub-4125359195200512~1607281974`.
- Public chat requires acceptance of chat rules before posting. Players can report messages, block players and undo blocks. Reports require developer moderation; see `account-deletion-and-moderation.md`.

## Sources

- https://developers.google.com/admob/android/privacy/play-data-disclosure
- https://developer.android.com/privacy-and-security/declare-data-use
- https://firebase.google.com/docs/android/play-data-disclosure
- https://support.google.com/googleplay/android-developer/answer/10787469
