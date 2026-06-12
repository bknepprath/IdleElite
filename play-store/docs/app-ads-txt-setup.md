# Idle Elite app-ads.txt Setup
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Idle Elite's AdMob publisher id is `pub-3570919669688101`, derived from the configured app id `ca-app-pub-3570919669688101~3616255490` and rewarded ad unit `ca-app-pub-3570919669688101/7376748559`.

The repository's hosted file lives at:

```text
public/app-ads.txt
```

Its authorized seller line is:

```text
google.com, pub-3570919669688101, DIRECT, f08c47fec0942fa0
```

## Why This File Exists

AdMob verifies app ownership by crawling `app-ads.txt` from the root of the developer website listed in the app's Google Play Store settings. The APK/AAB does not carry this file; it must be hosted publicly at a URL like:

```text
https://PROJECT_ID.web.app/app-ads.txt
```

or:

```text
https://your-custom-domain.example/app-ads.txt
```

## Firebase Hosting Deploy

This repo already uses Firebase for leaderboard/chat data, so `firebase.json` also defines a Hosting target with `public` as the hosted root.

Before deploying, confirm the Firebase CLI is logged in and targeting the correct Firebase project. If `.firebaserc` is not present, pass the project id explicitly:

```powershell
firebase deploy --only hosting --project <firebase-project-id>
```

After deploy, open the hosted file in a browser and confirm it shows the exact authorized seller line:

```text
https://<firebase-project-id>.web.app/app-ads.txt
```

## Play Console And AdMob Follow-Up

1. In Play Console, set the Store settings developer website to the same host that serves `app-ads.txt`, for example `https://<firebase-project-id>.web.app`.
2. Wait for Google Play/AdMob to detect the developer website change.
3. In AdMob, go to Apps > app-ads.txt and request a check for updates if the button is available.
4. Allow at least 24 hours for AdMob to crawl and verify the file.

References:

- Google AdMob app-ads.txt setup: https://support.google.com/admob/answer/9363762
- Google Mobile Ads app-ads.txt guide: https://developers.google.com/admob/android/app-ads
