# AdMob ID verification, October 23

Verified the active native-1080p checkout at `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p` against the owner-supplied migration IDs.

- Current Android plugin application ID: `ca-app-pub-4125359195200512~1607281974`.
- Current Boost rewarded unit: `ca-app-pub-4125359195200512/8284370963`.
- Android release runtime selects that live rewarded unit; debug runtime selects Google's separate test rewarded unit.
- AdMob Android export plugin reads the configured application ID into the `com.google.android.gms.ads.APPLICATION_ID` manifest metadata. The development override path does not exist.
- Existing `builds/android/idle-elite-release-v0.7.1-code43.aab`, dated October 21, contains the new application ID in its manifest. Its actual compiled configuration and ad-bonus scripts were extracted and loaded through headless Godot; both compiled constants match the current source. Audit result: `ADMOB_ID_AUDIT_PASS=true`. No headless process remained.
- The release runbook's obsolete manifest example was corrected. Historical release records remain historical. The old publisher stays in `public/app-ads.txt` as explicitly documented for migration, alongside the new publisher.
- The parent archived 2160p checkout retains old runtime IDs. It is not the current development or release checkout.

The configured live app-ads.txt URL could not be accessed with the web tool. This check verifies source and the existing local bundle, not AdMob dashboard approval, website crawl status, live serving, earnings, or which package Google Play is currently distributing. No new Android build was exported or published.
