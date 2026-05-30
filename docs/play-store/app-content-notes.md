# Google Play App Content Notes

These notes summarize the Play Console declarations that still need account-owner confirmation.

## Ads

- The app uses rewarded ads through Google AdMob.
- In Play Console, answer that the app contains ads.
- In Play Console, answer that the app uses the Android Advertising ID when AdMob is enabled.
- The release manifest currently includes `com.google.android.gms.permission.AD_ID` through the AdMob dependency.

## Data Safety Draft

Because AdMob is included, use Google's AdMob data disclosure guidance when completing the Data Safety form. The app itself stores idle game progress locally in Godot `user://` storage. If Firebase features are enabled in a build, the app also uses Firebase Authentication and Firebase Realtime Database for public leaderboard ranking and global chat. The app does not currently implement email/password accounts, Google sign-in, cloud save, analytics, or purchases.

Draft answers to verify in Play Console:

- Data collected by the app itself: local on-device save data. If Firebase is enabled, online leaderboard display name, selected avatar index, leaderboard category scores, global chat messages, message/moderation timestamps, deletion tombstones, and Firebase user id.
- Data shared/collected by SDK: AdMob may collect/share advertising-related identifiers and device data for ads, fraud prevention, analytics/diagnostics, and compliance, depending on SDK behavior and user settings.
- Data deletion: local game data can be reset in the in-game Settings menu. If Firebase is enabled, remote leaderboard rows and chat data require a developer support deletion/moderation path; confirm the public contact address before launch.
- Encryption in transit: yes for SDK/network traffic handled by Google SDKs.
- Users can request data deletion: yes if Firebase is enabled. The privacy policy should explain local reset and how to request remote leaderboard/chat data deletion.

## Privacy Policy

Google Play requires a privacy policy for apps in Play Console, and ads/AdMob make this effectively mandatory for a launch-ready listing. The policy should name `Idle Elite`, mention rewarded ads via Google AdMob, explain local save data, describe Firebase Authentication and Realtime Database leaderboard/chat data if enabled, and identify the developer/entity name used on the store listing.

A draft is available at `docs/play-store/privacy-policy-draft.md`. Replace the developer name/contact placeholders, host the policy on a public URL, then paste that URL into Play Console.

## Sources

- Google Play Data safety form: https://support.google.com/googleplay/android-developer/answer/10787469
- AdMob data disclosure guidance: https://developers.google.com/admob/android/privacy/play-data-disclosure
- Google Play Developer Program Policy, privacy policy note: https://support.google.com/googleplay/android-developer/answer/16549787
- Android App Bundle requirement: https://developer.android.com/guide/app-bundle
- Google Play target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
