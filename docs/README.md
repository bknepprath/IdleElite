# Idle Elite Godot Documentation
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

This folder documents **Idle Elite**, a Godot 4 mobile idle RPG. Treat every Markdown page and HTML page here as support material for the Godot project: product requirements, activity data, UI references, feature plans, audio auditions, Android release work, and Play Store operations.

## How To Read These Docs

- **Live implementation references:** `activity-database.html`, `activity-database.json`, `product-requirements.md`, and the Play Store runbooks describe the current Godot build or release pipeline.
- **Godot implementation references:** Legacy HTML filenames are kept for link stability, but their contents should document the current Godot implementation rather than old browser-only references.
- **Feature planning:** fishing, fighting, passive module, stamina, and chain-physics docs should map back to `docs/activity-database.json`, `scripts/main.gd`, Godot scenes, exported Android builds, or assets under `assets/`.
- **Release documentation:** everything under `play-store/docs/` is for the Android package `com.idleelite.game` unless a page explicitly calls out the preview package `com.idleelite.game.preview`.

## Guardrails

- Run Godot validation only through `.\scripts\check-project.ps1` or `.\run-godot-safe.ps1`.
- After editing fishing data, sync `docs/activity-database.json` into the generated JavaScript and run the activity database audit.
- Keep public-facing Play Store and privacy-policy text accurate to the Godot app: local Godot saves, optional rewarded ads, optional Firebase leaderboard/chat, no cloud saves, no purchases unless implemented.
