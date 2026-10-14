# Idle Elite v0.5.2 Launch Readiness

## Release

- Version name: `0.5.2`
- Version code: `37`
- Package: `com.idleelite.game`
- Track: Google Play production
- Previous production version: `0.5.1` (`36`)
- Google Play status: submitted for review for a 100% production rollout on August 15, 2026.
- Managed publishing: off; the release will publish automatically after approval.

## Artifacts

- AAB: `builds/android/idle-elite-release-v0.5.2-code37.aab`
- AAB size: `198,757,541` bytes
- AAB SHA-256: `7196083954EE398F23F3D06305EEBEF8BFDF2A137440014A22E664F2C6D2CC2A`
- APKS: `builds/android/idle-elite-release-v0.5.2-code37.apks`
- APKS size: `248,330,933` bytes
- APKS SHA-256: `E1A5CC333BE60868AF76C5EB8516457CFDA3CA9B7A820694539ACAEF841329FC`

## Android Configuration

- `window/stretch/mode` remains `viewport`.
- Release export rejects any non-`viewport` stretch mode.
- Manifest reports `minSdk=24` and `targetSdk=36`.
- Manifest contains AdMob app ID `ca-app-pub-3570919669688101~3616255490`.
- Production rewarded unit is `ca-app-pub-3570919669688101/7376748559`.

## Efficiency Changes Included

- Removed global boot-time texture warmup.
- Freed the boot overlay after startup.
- Deferred detail-card and preview texture loading until needed.
- Limited combat texture loading to the active enemy.
- Removed the duplicate hidden combat stage.
- Physical-device cold-start memory measurement improved from approximately `1.58 GB` PSS to `1.05 GB` PSS; graphics memory improved from approximately `1.15 GB` to `636 MB`.

## Validation

- Safe Godot project parse passed.
- Crash-audit contracts passed.
- Leaderboard cost-safety checks passed.
- Focused skill-detail regression check passed.
- `jarsigner -verify` passed.
- `bundletool validate` passed.
- Exported payload scan found no signing files, release files, or Codex temporary files.
- The preview package was installed and inspected on a physical Samsung phone without changing the installed production package.
- The accepted physical-device capture is `.codex-tmp/phone-screens/idle-elite-memory-final-accepted.png`.

## Known Validation Limitation

The exhaustive Windows headless activity-queue test intermittently terminates with a Godot signal 11 after several minutes. The failure moved among unrelated deferred UI operations and did not reproduce in the Android preview build. Temporary test-only workarounds were removed; the release contains only the verified runtime fixes.
