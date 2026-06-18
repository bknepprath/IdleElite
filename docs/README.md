# Idle Elite Godot Documentation
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

This folder documents **Idle Elite**, a Godot 4 mobile idle RPG. Treat every Markdown page and HTML page here as support material for the Godot project: product requirements, activity data, UI references, feature plans, audio auditions, Android release work, and Play Store operations.

## How To Read These Docs

- **Agent orientation:** Start with `agent-onboarding-checklist.md`, `agent-codebase-map.md`, `main-gd-ownership-map.md`, `ui-runtime-boundary-map.md`, `activity-ui-boundary-map.md`, and `generated-file-hygiene.md` before broad code, asset, UI, metadata, or validation changes.
- **Planning home:** Start with `planning-system.md` or `planning-system.html` for active direction, doc roles, and the Now/Next/Later buckets.
- **Live implementation references:** `activity-database.html`, `activity-database.json`, `activity-database-contract.md`, `product-requirements.md`, and the Play Store runbooks describe the current Godot build or release pipeline.
- **Godot implementation references:** Active HTML files at the top of `docs/` should describe the current Godot implementation.
- **Archive:** Old plans, mocks, and historical references live in `docs/archive/`.
- **Feature planning:** active plans should map back to `docs/activity-database.json`, `scripts/main.gd`, Godot scenes, exported Android builds, or assets under `assets/`.
- **Release documentation:** everything under `play-store/docs/` is for the Android package `com.idleelite.game` unless a page explicitly calls out the preview package `com.idleelite.game.preview`.

## Guardrails

- Run Godot validation only through `.\scripts\check-project.ps1` or `.\run-godot-safe.ps1`.
- After editing fishing data, sync `docs/activity-database.json` into the generated JavaScript and run the activity database audit.
- Keep public-facing Play Store and privacy-policy text accurate to the Godot app: local Godot saves, optional rewarded ads, optional Firebase leaderboard/chat, no cloud saves, no purchases unless implemented.
