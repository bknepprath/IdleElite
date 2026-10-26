# Idle Elite 0.7.1 / code43 validation - October 22, 2026

Idle Elite AdMob migration validation - October 22, 2026

Account: weskillnow@gmail.com / pub-4125359195200512
Package: com.idleelite.game
New app ID: ca-app-pub-4125359195200512~1607281974
Boost Rewarded: ca-app-pub-4125359195200512/8284370963
Reward configuration freshly inspected: amount 1, item Boost XP + Speed; ad-unit and app-level no cap.
Google debug rewarded unit retained: ca-app-pub-3940256099942544/5224354917

Fresh results
- Existing AdMob app/unit reused; no duplicate created and no new AdSense account proposed or created.
- Clicked Verify app in the verified weskillnow session. AdMob explicitly reported successful verification. App now Getting ready / Review in progress, with limited serving.
- Account approval was still pending on the account home at this session's inspection. Test ads do not establish live-ad serving readiness.
- curl.exe fetched https://idle-elite.web.app/app-ads.txt with HTTP 200, text/plain, 118 bytes, and both exact seller lines. The earlier deployment is already live; no redundant deployment was needed.
- Both old and new seller lines retained. No payments, tax, identity, old-account closure, Play upload, Firebase rules or player records changed.

Game and version
- Authoritative active checkout: C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p
- Root checkout is archived/stale (0.5.3); its old IDs remain historical and it must not be built for release.
- Active checkout already uses the new app ID in addons/admob/android/config.gd and android/build/src/debug/AndroidManifest.xml, and the new live unit in scripts/monetization/ad_bonus.gd.
- No AdMob IDs are directly set in export_presets.cfg or project.godot. The plugin supplies manifest metadata.
- Historical release records retain old IDs. public/app-ads.txt intentionally retains the old seller.
- Brian clarified Play is 0.7.0 and development is 0.7.2. The 0.7.2 source and export version were preserved. No rebuild or downgrade of that checkout was performed.
- Existing signed 0.7.1/code43 migration candidate was revalidated and its matching debug package was tested. Changelog file is exactly: Ads backend update

AAB
C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p\builds\android\idle-elite-release-v0.7.1-code43.aab
Size: 166832193 bytes
SHA256: 8EF51ED91F344FACC11B58A3167F72F6F6C85C1839C1EFAAA500930CCC8718A4
Fresh bundletool validation exit 0; jarsigner exit 0 / jar verified. Expected self-signed upload certificate warnings recorded.
Manifest freshly confirmed: com.idleelite.game, version 0.7.1/code43, minSdk 24, targetSdk 36, new AdMob app ID.
Original build evidence records use of scripts/build-android-release.ps1, preserved viewport/gl_compatibility, matching signer, 16KB ELF and APK alignment, and local payload exclusions. No fresh Godot build was run in this session.

Physical Samsung test
Device R5CX22KSM1H, SM_S928U (Galaxy S24 Ultra), raw capture dimensions 1080x2340.
Installed existing debug APKS as com.idleelite.game.preview. Production app was neither replaced nor uninstalled.
All 167 compiled GDScript files, including ad_bonus.gdc and AdMob config.gdc, match the signed 0.7.1 candidate byte-for-byte. Debug runtime selects Google's test rewarded unit.
The actual shop button loaded a visibly labelled Test Ad. Completion returned to the game with one two-hour Boost, +10% XP and +10% speed, with one stack lit and 1h59m remaining. A second completed ad stacked another two hours.
Early Back presses did not establish a pre-reward cancellation test; cancellation remains unverified. Do not claim that test passed.
No tearing or full-screen pixel corruption observed in inspected game captures. No rendering setting changed.
Media volume was 0 before and after testing. Agent-launched preview was force-stopped. No Godot process remained.

Release limitations
- This is not an ads-only candidate: the prior artifact comparison identifies eight pre-existing gameplay/UI script changes relative to Play 0.7.0.
- Prior full check-project validation failed a skills-page performance assertion (scroll/fishing mounted too many action cards). This session did not repair or rerun that unrelated test against a reconstructed 0.7.1 source.
- Account approval and app review remain pending.
- No release approval is inferred. Stop before Google Play upload.

Evidence directory
C:\Users\bknep\Documents\Idle Slop 1\outputs\admob-migration\evidence
Files: active-reference-audit.txt, root-tracked-reference-files.txt, active-tracked-reference-files.txt, curl-2026-10-22-headers.txt, curl-2026-10-22-app-ads.txt, manifest-071.xml, bundle-validation-071.txt, signature-validation-071.txt, preview-parity-071.json, verified-2026-10-22.jpg, phone-test-ad.png, phone-reward-return.png.
New test scratch: H:\Codex\Scratch\IdleElite-admob-071. Flareon verified; approximately 1.25 TB free at this session's check. Existing artifact paths remain authoritative.
