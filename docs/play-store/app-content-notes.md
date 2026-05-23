# Google Play App Content Notes

These notes summarize the Play Console declarations that still need account-owner confirmation.

## Ads

- The app uses rewarded ads through Google AdMob.
- In Play Console, answer that the app contains ads.
- In Play Console, answer that the app uses the Android Advertising ID when AdMob is enabled.
- The release manifest currently includes `com.google.android.gms.permission.AD_ID` through the AdMob dependency.

## Data Safety Draft

Because AdMob is included, use Google's AdMob data disclosure guidance when completing the Data Safety form. The app itself stores idle game progress locally in Godot `user://` storage and does not currently implement accounts, sign-in, cloud save, chat, analytics, or purchases.

Draft answers to verify in Play Console:

- Data collected by the app itself: none beyond local on-device save data.
- Data shared/collected by SDK: AdMob may collect/share advertising-related identifiers and device data for ads, fraud prevention, analytics/diagnostics, and compliance, depending on SDK behavior and user settings.
- Data deletion: no account system exists. Local game data can be reset in the in-game Settings menu.
- Encryption in transit: yes for SDK/network traffic handled by Google SDKs.
- Users can request data deletion: not applicable for app-owned account data because there are no accounts, but the app should disclose the local reset option.

## Privacy Policy

Google Play requires a privacy policy for apps in Play Console, and ads/AdMob make this effectively mandatory for a launch-ready listing. The policy should name `Idle Elite`, mention rewarded ads via Google AdMob, explain local save data, and identify the developer/entity name used on the store listing.

A draft is available at `docs/play-store/privacy-policy-draft.md`. Replace the developer name/contact placeholders, host the policy on a public URL, then paste that URL into Play Console.

## Sources

- Google Play Data safety form: https://support.google.com/googleplay/android-developer/answer/10787469
- AdMob data disclosure guidance: https://developers.google.com/admob/android/privacy/play-data-disclosure
- Google Play Developer Program Policy, privacy policy note: https://support.google.com/googleplay/android-developer/answer/16549787
- Android App Bundle requirement: https://developer.android.com/guide/app-bundle
- Google Play target API requirements: https://support.google.com/googleplay/android-developer/answer/11926878
