# Terra Medium Codebase Audit Delegation Plan

Prepared: 2026-07-09  
Repository: Idle Elite  
Planning snapshot: branch `codex/godot-4.7-migration`, commit `d80298910e63`

## Recommendation

Use a hybrid audit:

- Sol extra-high owns scope, cross-system reasoning, challenge review, prioritization, and the final verdict.
- Terra medium performs bounded, read-only evidence passes with one clearly defined audit lane per context.
- Sol verifies every P0/P1 claim and a sample of P2 claims against the code before accepting the report.

Do not give one Terra medium context the vague task "audit the whole repo." This repository is too large and too stateful for that to produce consistently deep results. If only one model/context can be used, Sol extra-high should perform the audit directly. If delegation is available, the hybrid is the best cost/quality option.

## Why This Repository Needs a Controlled Audit

Observed at planning time:

- About 3,520 discoverable files.
- 80 first-party GDScript files under `scripts/`, totaling about 84,616 lines and 5,120 functions.
- UI owns about 52,914 of those lines across 38 GDScript files.
- The largest current files include:
  - `scripts/ui/skill_detail_surface.gd`: about 10,525 lines.
  - `scripts/ui/skill_swipe_activity_surface.gd`: about 6,888 lines.
  - `scripts/fishing/ui_surface.gd`: about 5,555 lines.
  - `scripts/ui/navigation_shell.gd`: about 5,251 lines.
  - `scripts/ui/hub_surface.gd`: about 3,241 lines.
- `scripts/main.gd` is now about 1,247 lines but preloads 54 modules.
- Roughly 9,567 source lines reference a generic `host`, so the central architectural question is whether ownership was truly extracted or the monolith was distributed behind host relays.
- There are 67 PowerShell validation/check/audit scripts but only two GDScript files under `scripts/tests/`. Several PowerShell tests are themselves very large and may mix behavioral testing with static source assertions.
- The working tree is highly active: 606 porcelain entries at planning time (`431 M`, `158 D`, `17 ??` directory/file entries), including 414 `.import` entries and 192 non-`.import` entries.
- Prior audit and refactor records are extensive. They are valuable evidence, but some describe an older architecture and must be reconciled with current code rather than repeated or trusted blindly.

These are scope signals, not findings. File size, function count, or host-reference count alone is never sufficient evidence for a defect.

## Audit Contract

Every Terra pass receives these rules verbatim.

### Mission

Produce an evidence-backed, read-only assessment of the assigned lane. Find concrete correctness, data-safety, performance, release, test-quality, or unnecessary-complexity risks. Do not implement fixes.

### Repository Safety

1. Read `AGENTS.md` before doing anything else.
2. Record `git rev-parse HEAD`, `git branch --show-current`, and `git status --porcelain=v1` at the start.
3. Preserve all existing changes. Do not restore, stage, move, rename, format, regenerate, import, or delete anything.
4. Treat committed `HEAD` and the current working tree as separate baselines. Label a finding `HEAD`, `worktree`, or `both`.
5. Do not call `Godot.exe` directly. The audit phase is static by default and should not launch Godot.
6. If runtime proof is essential, describe the smallest safe validation command and return it as a recommendation. Sol decides whether to run it later through `run-godot-safe.ps1`.
7. Never expose local secrets or print the contents of real Firebase/keystore credential files. It is acceptable to report that a tracked secret-like file exists and how it is referenced.

### In Scope

- First-party runtime code under `scripts/`.
- `scenes/main.tscn`, `project.godot`, and `export_presets.cfg` where they define runtime or release contracts.
- `docs/activity-database.json` and its source/generated/runtime boundary.
- Firebase rules/configuration and first-party online integration code.
- First-party test, check, capture, build, packaging, and release scripts.
- Compatibility-sensitive asset paths and generated-file rules, but not subjective art critique.
- Existing architecture/audit documents when reconciling their claims with current code.

### Excluded Unless a First-Party Boundary Is Broken

- `.git/`, `.godot/`, `.codex-tmp/`, `.codex-tools/`, `output/`, `test-results/`, and generated build output.
- Vendored implementation details in `addons/admob/`, `android/`, and `ios/`.
- Bulk inspection of PNG, audio, archive, library, or platform binary contents.
- Style-only commentary, speculative rewrites, and generic recommendations to "split large files."

Vendored or generated material may still be cited when first-party code configures it unsafely, ships the wrong artifact, depends on an invalid path, or accidentally tracks sensitive/generated state.

### Required Reading

Every pass:

- `AGENTS.md`
- `README.md`
- `docs/agent-onboarding-checklist.md`
- `docs/agent-codebase-map.md`
- `docs/generated-file-hygiene.md`

Read when relevant to the assigned lane:

- `docs/main-gd-ownership-map.md`
- `docs/ui-runtime-boundary-map.md`
- `docs/activity-ui-boundary-map.md`
- `docs/activity-database-contract.md`
- `docs/codebase-stabilization-audit.md`
- `docs/codebase-complete-refactor-plan-and-checklist.md`
- `docs/efficiency-audit-tracker.md`
- `docs/naming-audit.md`
- `docs/audio-structure-guide.md`
- `play-store/docs/launch-runbook.md`
- `play-store/docs/device-crash-reporting.md`

Prior documents are claims to verify. For each relevant claim, classify it as `current`, `stale`, `partially current`, or `unverified`.

### Evidence Standard

A valid finding must include:

1. A concrete invariant, failure mode, waste, or ownership problem.
2. Exact `path:line` evidence from current files.
3. The caller/callee or producer/consumer flow that makes the evidence meaningful.
4. User, save-data, runtime, release, security, cost, or developer impact.
5. The smallest plausible corrective direction, without writing the patch.
6. A focused validation that would fail before the fix and pass after it.
7. Baseline classification: `HEAD`, `worktree`, or `both`.
8. Relationship to existing audit notes: `new`, `confirms`, `supersedes`, or `contradicts`.

Reject a candidate finding when it is based only on size, naming taste, theoretical purity, a single isolated snippet, or an unverified assumption about Godot behavior. Trace definitions and all materially different callers with `rg` before making a claim.

### Finding Schema

Use this exact shape:

```text
ID: <lane>-NNN
Priority: P0 | P1 | P2 | P3
Confidence: high | medium | low
Baseline: HEAD | worktree | both
Category: correctness | save-compatibility | data-contract | lifecycle | input | performance | online | security | release | tests | tooling | complexity | documentation
Title: <specific failure or unnecessary mechanism>
Evidence: <path:line plus concise flow explanation>
Impact: <what actually breaks, costs, regresses, or becomes unsafe>
Minimal direction: <smallest credible correction; no implementation>
Validation: <focused command/check or proposed test>
Existing-record relation: new | confirms <doc> | supersedes <doc> | contradicts <doc>
```

Priority meanings:

- P0: active data loss, credential/security exposure, destructive release defect, or reliably unplayable build.
- P1: likely crash, save corruption/compatibility break, economy/progression corruption, uncontrolled network cost, or severe common-path performance failure.
- P2: concrete player-facing defect, meaningful performance/reliability issue, or architecture/test flaw with a demonstrated regression path.
- P3: bounded cleanup, misleading documentation, low-risk test gap, or simplification opportunity.

Low-confidence P0/P1 findings are not allowed in the final ranked list. They belong under `Needs proof` until verified.

## Delegation Lanes

Run Lanes A-E as separate Terra medium contexts. They are read-only and may run in parallel if desired. Run Lane F only after A-E return.

### Lane A: Architecture and Ownership

Primary question: did the `main.gd` extraction create real boundaries, or a distributed monolith coupled through `host`?

Inspect:

- `scripts/main.gd`
- `scripts/ui/skill_detail_surface.gd`
- `scripts/ui/skill_swipe_activity_surface.gd`
- `scripts/ui/navigation_shell.gd`
- `scripts/ui/input_routing_shell.gd`
- `scripts/app/lifecycle_runtime.gd`
- The ownership/boundary maps

Trace:

- Module construction and preload relationships.
- Generic `host` reads/writes and wrapper/relay chains.
- Duplicate ownership of navigation, visible page, active activity, lazy UI, and lifecycle state.
- Cycles hidden by static functions or dictionary/string-based access.
- Public functions with one caller, wrappers that only relay, and compatibility shims that no current caller needs.
- Whether older ownership docs still describe current entry points.

Do not report "file is too large." Report an actual ownership collision, duplicated state transition, unsafe relay, dead layer, or change-amplification path.

### Lane B: Gameplay State, Data, and Persistence

Primary question: can progression, action state, offline progress, or saves become incorrect across load, reset, alias migration, or feature boundaries?

Inspect:

- `scripts/save_state/`
- `scripts/activity_data/`
- `scripts/progression/`
- `scripts/gameplay/`
- `scripts/activity_queue/`
- `scripts/achievements/`
- `scripts/fishing/state.gd`
- `scripts/thieving/state.gd`
- `scripts/temporary_events/runtime.gd`
- `docs/activity-database.json`
- Activity database and save-normalization checks

Trace at minimum:

- Fresh save, existing save, malformed/partial save, legacy alias, and hard reset.
- Activity ID production, canonicalization, lookup, save, restore, and UI consumption.
- Offline elapsed-time handling, clock assumptions, repeated rewards, and idempotence.
- Currency/resource spend-and-award transactions and interruption ordering.
- Level/mastery/unlock implications and duplicate grant paths.
- Feature state that is level-derived versus explicitly serialized.

Treat serialized keys, IDs, node names, signals, and external strings as compatibility contracts.

### Lane C: UI, Input, Lifecycle, and Performance

Primary question: can a player-visible flow misroute input, retain stale UI state, leak work, or exceed mobile constraints?

Inspect the large UI surfaces plus:

- `scripts/ui/mobile_scroll_container.gd`
- `scripts/ui/button_press_state.gd`
- `scripts/app/performance_runtime.gd`
- `scripts/app/boot_warmup_runtime.gd`
- `scripts/core/visual_texture_cache.gd`
- Focused UI/performance test scripts

Trace at minimum:

- Touch press/drag/release/cancel across navigation, skill swipe, scroll, modal, and action controls.
- Hidden/off-page update guards and final-state cleanup.
- Tweens, timers, signal connections, queued frees, cached nodes/resources, and repeated builders.
- Work performed from `_process`, `_input`, `_unhandled_input`, `_draw`, and notification callbacks.
- Texture/resource loads and cache invalidation.
- Phone-readable text and clipping rules for changed or dynamically built UI.
- Performance tests: distinguish stable budget evidence from retry-masked or machine-sensitive noise.

Do not invent runtime performance claims from line count. Identify a hot-path operation or return the item under `Needs profiling` with a specific probe.

### Lane D: Online, Security, Monetization, and Release

Primary question: can configuration, network behavior, or packaging expose data, create uncontrolled cost, break release builds, or grant rewards incorrectly?

Inspect:

- `scripts/online/`
- `scripts/leaderboard/`
- `scripts/monetization/`
- `scripts/diagnostics/`
- Firebase configuration/rules and related scripts
- `project.godot`
- `export_presets.cfg`
- First-party Android/export/package/install scripts
- Relevant Play Store runbooks

Trace at minimum:

- Auth/profile/leaderboard/chat trust boundaries.
- Firebase read/write rules, query shape, pagination/limits, retry/backoff, and cost controls.
- Rewarded-ad callback ownership and duplicate reward prevention.
- Debug/test IDs and flags versus release IDs and flags.
- Export filters, package IDs, versioning, signing references, and accidental local-secret inclusion.
- Crash-report collection, redaction, retention, and player privacy.

Never print secret values. Report only location, tracking state, reference flow, and risk.

### Lane E: Validation, Tooling, and Generated-File Hygiene

Primary question: do the existing checks prove behavior, or can they pass while the game is broken and fail on harmless source changes?

Inspect:

- `scripts/check-project.ps1`
- `scripts/test-everything.ps1`
- `scripts/test-*.ps1`
- `scripts/check-*.ps1`
- `scripts/audit-*.ps1`
- `scripts/tests/*.gd`
- `run-godot-safe.ps1`
- `scripts/lib/godot-processes.ps1`
- `.gitignore` and generated-file guidance

Classify every meaningful check as:

- Behavioral runtime test.
- Static contract/source-shape assertion.
- Visual/capture smoke test.
- External/live integration test.
- Release/build test.

Look for:

- Tests that assert implementation text rather than behavior.
- Huge duplicated harnesses or helpers.
- False-positive/false-negative patterns and swallowed failures.
- Retry logic that changes a release gate into a warning.
- Missing cleanup of owned headless processes.
- Tests absent from the umbrella runner.
- Checks that modify source or import metadata unexpectedly.
- Generated/source pairs that can drift.
- Expensive redundant validation that can be replaced by one stronger owner test.

Produce a compact validation map showing what protects each critical system and the most important uncovered invariant.

### Lane F: Ponytail Complexity Pass

This lane is complexity-only and must remain separate from correctness findings.

Using the current code and the results of A-E, rank only evidence-backed opportunities with these tags:

- `delete:` dead code, unused compatibility, stale fallback, speculative feature.
- `native:` code replaced by a Godot/platform feature.
- `stdlib:` hand-rolled behavior replaced by a language/runtime facility.
- `yagni:` one-caller layer, one-implementation abstraction, unused configuration surface.
- `shrink:` duplicated logic with a clear smaller owner.

For every entry, name the current callers and the replacement. Do not estimate net line reduction unless the candidate paths and approximate removed ranges were inspected. Correctness, security, and performance findings stay in their original lanes.

## Terra Lane Output

Each lane returns one report containing:

1. Scope actually inspected, including files/flows not reached.
2. A five-to-ten-line system map.
3. Ranked confirmed findings.
4. `Needs proof` candidates, each with the missing evidence.
5. Existing-doc reconciliation.
6. What appears healthy or intentionally complex.
7. The three best next validations, without running them.

Silence is acceptable: if a lane has no supported finding, say so. Do not pad the report.

## Sol Synthesis and Challenge Review

Sol extra-high performs the final pass after all Terra reports return:

1. Re-open every P0/P1 evidence path and trace the relevant flow independently.
2. Re-open at least one representative P2 from each lane.
3. Reject duplicates, symptoms whose root cause is already listed, and suggestions contradicted by current worktree changes.
4. Reclassify anything based only on static inference as `Needs runtime proof`.
5. Resolve cross-lane conflicts, especially where simplification would weaken save compatibility, input safety, security, accessibility, or release safeguards.
6. Separate `fix now`, `fix after current worktree lands`, `instrument first`, `document only`, and `do not change`.
7. Define the smallest validation for each accepted `fix now` item.

Final report structure:

```text
# Idle Elite Codebase Audit

## Verdict
## Baseline and limitations
## Top risks
## Accepted findings
## Needs runtime proof
## Existing audit/doc reconciliation
## Validation coverage map
## Simplification candidates
## Sequenced remediation backlog
## Areas intentionally left unchanged
```

The remediation backlog must be dependency-ordered, not merely severity-sorted. Protect save/data contracts and add missing proof before changing the code they govern. Do not combine audit and implementation in the same task.

## Acceptance Gate

The audit is complete only when:

- All five primary lanes were covered or explicitly marked incomplete.
- Every accepted finding has exact evidence, impact, a minimal direction, and a validation.
- Every P0/P1 was independently verified by Sol.
- Current worktree findings are distinguished from committed-HEAD findings.
- Vendored/generated content was not mistaken for first-party architecture.
- Prior audit documents were reconciled rather than copied.
- The final top risks contain no generic style advice.
- The report names healthy boundaries and intentional complexity, not only defects.
- No code, assets, imports, generated data, or release configuration were changed during the audit.

## Copy-Paste Controller Prompt

Use this prompt when delegating a lane to Terra medium:

```text
Audit the Idle Elite repository at C:\Users\bknep\Documents\Idle Slop 1.

Your assigned lane is: <LANE NAME AND TEXT>.

Follow docs/terra-codebase-audit-plan.md exactly, especially the Audit Contract, evidence standard, baseline separation, exclusions, and lane output. This is a read-only audit. Do not edit files or run Godot. Start by reading AGENTS.md and recording HEAD, branch, and porcelain status. Treat existing audit documents as claims to verify. Return only supported findings in the required schema; put unresolved suspicions under Needs proof. Do not pad the report and do not propose a broad rewrite.
```

