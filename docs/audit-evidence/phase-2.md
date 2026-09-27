# Phase 2 Evidence

## Page-switch release state

The evidence was captured from `res://scenes/main.tscn` through the bounded visible-game runner at a raw 1080 x 1920 viewport. The images were not cropped, resized, or composited.

| Artifact | Release offset | SHA-256 |
| --- | ---: | --- |
| `phase-2-page-switch/before-fix-released.png` | `(0.0, 36.0)` | `A6B22C2D02172D7DED99011B823B6C4AD5A7903DAAAD40B63E271909D4BEAB7A` |
| `phase-2-page-switch/current-before.png` | Not applicable | `C088F46611606158A85C3A81260A0B1D64726FAE30C41B4125343A494D057627` |
| `phase-2-page-switch/current-released.png` | `(0.0, 0.0)` | `3674C161AA7202EBB93A00497597D7F17DB887E96CB6A3CA2A441A03EF355D61` |

The before-fix run failed with `page switch button stayed depressed after release: (0.0, 36.0)`. The current release-evidence run completed with no failures and returned the button to `(0.0, 0.0)`.

The broader cover-spam branch of `test-page-switch-cover-visual.ps1` still exits after the release checkpoint and is not represented as passing evidence. Phase 2 validates the release-state regression only.

## Fishing click-flow harness

`scripts/test-fishing-click-flow.ps1` completed the manual 23-location unlock sequence, the 23-location automatic visible chain, delayed reveal checks, and input-routing checks with `fishing-click-flow-ok`.

The harness now:

- rejects known generated-GDScript corruption signatures before starting Godot;
- uses an isolated writable Godot user-data directory;
- disables save writes for the test;
- restores its environment variables; and
- rejects headless Godot processes left behind by the run.

## Test and capture safeguards

`scripts/check-test-harness-contracts.ps1` is part of `scripts/check-project.ps1`. It parses every PowerShell harness, verifies the fishing corruption and isolation contracts, and requires maintained visual capture scripts to instantiate `res://scenes/main.tscn`, use viewport scaling, run through `--visible-game`, and avoid isolated `SubViewport` or canvas-items proof renders.

The obsolete `scripts/tests/giant_boulder_capture.gd` was removed because it constructed an isolated control tree with canvas-items scaling and could not serve as production-scene visual evidence.

`scripts/test-accidental-navigation-release.ps1` also uses isolated user data and disabled save writes. Its validation completed with `accidental-navigation-release-ok`.
