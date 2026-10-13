# Wisdom and Ham feedback, 8 October 2026

Source: Ham OSRS Discord DMs dated 7-8 October. Wisdom follows the owner's per-skill resource design, superseding the proposed sixth skill and passive critical-hit reward.

## Implemented

- Wisdom is permanent and tracked separately for each skill. It is never spent on unlocks. A source credits only its owner skill, and gates check only their owner skill. Ordinary activities do not grant it. Successful source activities grant the same fixed amount online and offline, independently of berry/loot multipliers.
- Study Blueprint and Chameleon Camouflage each grant 1 Wisdom per success; Prune Orchard Row grants 2. Their primary XP rewards are 2, 2 and 5 respectively to create a training tradeoff.
- Optional activities require Wisdom alongside their skill requirements: Frame a Treehouse Platform 25, Build a Decoy Vault 60, Scope Out a Heist 120, Carve the Guild's Trophy Oar 300. These activities do not block the main skill progression. Existing trusted unlock flags remain valid.
- ImageGen concepts A (inset bottom strip) and B (side meter) are available for design review; neither is implemented. The owner replaced the reward-strip concept with a small book at the action art's bottom-right corner. Books use the skill color: blue Building, purple Thieving, green Woodcutting. Source cards retain normal height. Tapping the badge opens inline help with the reward amount and per-skill balance.
- A horizontal Wisdom requirement bar remains below gated activity art. Tapping opens an inline explanation with links only to sources for that skill. Skill padlocks remain separate. If all skill padlocks were opened first, the filled Wisdom bar becomes an unlock button. Automatic unlocks also observe Wisdom.
- Saved Wisdom is validated, reset with a new game, and included in progress-regression protection and recovery evidence.
- Skills-menu release handling now rejects clicks consumed by a drag. Mouse and touch hold-then-drag gestures are covered.
- Owner correction: Fishing capacity and XP use two compact 52px rows with the normal 16px text outline. Duplicate titles are omitted to expose the boat below. Practice Pool uses the same stat outline and baseline, with a fixed inset for its rod.
- Owner correction: Reflection Mirror remains 1,000,000 fish. All fishing-tool prices retain their original values. The runtime test checks the database/runtime agreement and exact purchase debit.
- Rechecked the prior fixes for the clipped fourth mission and unclear fishing tool rewards. Mission slots use the full card, with a separate Upgrade view. All seven tools have information buttons with concise practical explanations; the same button closes help.

## Data contract

Optional nonnegative integer activity fields `wisdom_reward` and `wisdom_required` default to zero. `wisdom_skill` defaults to the activity owner skill, and every current Wisdom activity explicitly names that owner in the database. Edit `docs/activity-database.json` first. `scripts/activity_data/catalog.gd` carries both fields into runtime action records. Wisdom is stored separately from spendable materials as a per-skill dictionary in the save's top-level `wisdom` field. Missing balances start at zero; invalid or unknown values are discarded. The experimental scalar save had no source history, so its balance is carried forward once as a starting balance in each skill. Saves thereafter remain independent, and regression protection checks each skill separately.

## Validation

- `scripts/check-activity-database-contracts.ps1`: passed.
- `scripts/audit-activity-database.ps1`: passed; expected XP-curve warnings for the three deliberately reduced Wisdom sources.
- `scripts/test-save-normalization.ps1`: assertions passed, exit 0. Existing shutdown warnings remain: 2 shaped-text RIDs, 4 CanvasItems and 19 ObjectDB instances.
- `scripts/test-ham-feedback.ps1`: passed, including earlier hub upgrades, rewards and fresh-skill progression.
- `scripts/test-mission-board.ps1 -VisibleGame`: passed at levels 0-4. Production-scene captures are in `.codex-tmp/mission-board-review`.
- `scripts/test-wisdom-feedback.ps1 -VisibleGame`: passed with `wisdom-feedback failures=[]` and `wisdom-feedback-ok`; log: `.codex-tmp/wisdom-feedback-visible.log`. Covers old-save compatibility, malformed values, save regression, all Wisdom gates, skill requirements, automatic/manual unlocks, online/offline success rewards, ordinary-activity exclusion, loot-boost independence, source links, independent per-skill rewards and gates, malformed per-skill save data, legacy scalar migration, corner-badge help taps, source-card height, skill colors, Time Bonuses overlap, mouse/touch menu scrolling, boat capacity, all seven tool explanations and mirror purchasing.

The UI test runs the real `res://scenes/main.tscn` with muted audio, an isolated save directory and network/save writes disabled. It uses production UI controls and captures raw 1080 x 1920 PNGs in `.codex-tmp/wisdom-review`; no images are cropped or resized.

The earlier performance-budget failures are not cleared by these functional tests. Android renderer/stretch settings are unchanged. No release, export, phone installation, commit or push was performed.

Final raw screenshots were visually inspected and all Wisdom-review PNG dimensions verified at 1080 x 1920. The final run used the production mirror offer to verify the purchase and exact debit. No Godot processes remained after validation.

Final owner-directed revision: source reward bars are removed. The generated book badge appears at the action-art bottom-right and uses the owner skill color, with no number on the badge. Reward amounts remain in the tap-to-open explanation. Existing resource icons remain on the left. Wisdom requirement bars and help use the corresponding skill balance and source list.

Completion feedback: actual online Wisdom gains produce a separate skill-colored book and amount beside the action artwork. Its own tween rises immediately to the right of the owner-skill XP popup, then fades. XP keeps its existing position. Wisdom uses a compact book with the earned amount over it, positioned to the right of the visible XP lettering; multiple XP rewards retain their vertical lanes. Materials retain their collection-container flight. Failed attempts, zero gains, and offline awards do not produce Wisdom pop-ups. Multiple XP rewards use separate vertical lanes. The real-game test captures before, pop, drift, and settled frames for Building and Woodcutting, and checks independent tweens, reward amounts, spacing, and cleanup.

Fishing wallet revision: the gear button opens a vertical list of five named tool rows. Each row contains its artwork and help button; the equipped tool has a teal fill and checkmark, and unavailable tools have a padlock. The current rod upgrade continues to occupy the single rod slot. Help expands below the list at the same width. Mouse and touch selection, locked-tool rejection, one equipped indicator, row/content containment, all seven tool-help views, and mirror purchasing passed the real-game feedback test. Raw captures include `fishing-wallet-locked.png`, `fishing-wallet-selected.png`, and the fishing tool help PNGs.

Wallet typography correction: tool labels and help now use the game's bold Fredoka font, white fill, and 16-pixel black outline. The list width is measured from its longest tool label plus the artwork, controls, and stroke padding, replacing the fixed 800-pixel width. The compact list and help passed the real-game checks and were visually inspected at 1080 x 1920.

Fishing offer typography correction: all equipment offer headings and hints now use the game's bold font and 16-pixel black outline, replacing the regular font and 6-pixel outline. Existing font sizes and card spacing are retained. The net and Bamboo rod were visually inspected in raw 1080 x 1920 production-game captures; both fit within their cards. The feedback run reported no failed checks. The wrapper's final CIM process query was blocked by sandbox permissions; its log/error and process cleanup checks were completed separately with elevated process-read access.

Wisdom requirement revision: the 96-pixel Wisdom bar sits directly beneath the existing progress bar without the intermediate ledge. The original bar retains its rounded lower corners; the Wisdom bar has four rounded corners. Both share the module face, width, and lower 3D base. Padlocks draw above the Wisdom bar, while the bar remains above the locked-card shade. The label reads Wisdom Required (current / required), with the existing bold font and 16-pixel outline. Tapping opens inline help or unlocks when all requirements are met.

The focused real-game test passed for alignment, rounded corners, shared parent, text fit, help, source navigation, and unlocking. It now clicks both skill padlocks through the real UI and captures the settled states with two, one, and no padlocks. After both are dismissed, the chain and dimmed activity remain while Wisdom is 12 / 25; the activity still cannot unlock. All three captures were visually inspected and verified as raw 1080 x 1920 PNGs. No Godot processes remained. Use -WisdomOnly with scripts/test-wisdom-feedback.ps1 for focused checks.

Wisdom unlock transition (2026-10-09): the full Wisdom bar reads "Unlock". Confirming it fades the text over 0.12 seconds, then slides the full-size bar upward behind the existing rounded progress rail over 0.55 seconds while the module's extra height closes. Neither the bar nor its text is scaled. The chain and dimming fade over the following 0.20 seconds, then manual unlock is finalized. Input remains blocked during the transition. Wisdom is not spent. The completed bar stays hidden and its layout space stays removed on refresh and page return. Already-unlocked cards mount in their compact state. Reward-only book badges are unchanged.

Animation verification uses `scripts/test-wisdom-feedback.ps1 -VisibleGame -WisdomOnly`, including raw 1080 x 1920 captures `wisdom-unlock-before.png`, `wisdom-unlock-retracting.png`, `wisdom-unlock-settled.png`, and `wisdom-unlock-returned.png` in `.codex-tmp/wisdom-review`. The test checks intermediate motion, delayed manual activation, chain/shade cleanup, retained Wisdom, final height, and page-return state.

Final animation run passed with wisdom-feedback failures=[] and wisdom-feedback-ok. All four raw captures were verified at 1080 x 1920 and visually inspected. No Godot processes remained after validation.

Revised full-size slide validation passed: wisdom-feedback failures=[] and wisdom-feedback-ok in .codex-tmp/wisdom-slide-review.log. Checks include the plain Unlock label, text fading before movement, unchanged bar dimensions throughout movement, final layout, and page return. No Godot processes remained.

Final right-side Wisdom revision passed scripts/test-wisdom-feedback.ps1 -VisibleGame -RewardsOnly, with wisdom-feedback failures=[] and wisdom-feedback-ok. Building, Thieving, and Woodcutting completions were checked for positioning, separate tweens, earned amounts, bounds, cleanup, and no rewards on failure. XP retains its original positioning; the 96px book carries the number. The run also verifies app-resume repair after fixing its stale detail-stack lookup. No Godot processes remained. Raw 1080 x 1920 captures are in .codex-tmp/wisdom-review/wisdom-reward-*.png.

Owner copy revision: tapping a Wisdom source book now shows only: This activity rewards wisdom.
