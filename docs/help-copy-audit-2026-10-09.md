# Help copy audit — October 9, 2026

- Fishing tools: replaced the repeated Practice Pool rules with “Tools do not affect Practice Pool.”
- Berry boosts: “Double XP and loot for 1 berry per successful attempt. Tap Berries to choose activities.”
- Wisdom requirements: explain where to earn that skill's Wisdom and that unlocking does not spend it. The progress bar already shows the balance.
- Wisdom sources retain the owner's exact sentence: “This activity rewards wisdom.”
- Success help uses “Success Chance” and short source/value entries. Removed repeated “success chance” wording within that list.
- XP help identifies the affected skill when needed, uses consistent source/value entries, and explains whole-number rounding in one short sentence.
- At the owner's request, active-bonus list text is 40px instead of 52px, with a proportional 10px black outline. The heading and primary values retain their existing sizes. Berry and medal explanations retain 52px text. Font overrides only update when switching between those sizes.

No balance, tool prices, Wisdom rewards, or unlock requirements changed.

## Verification

- `scripts/test-ham-feedback.ps1`: feedback regression checks passed.
- Temporary real-game review `.codex-tmp/run-help-copy-review.ps1 -VisibleGame`: XP, success, time, berry, and all seven fishing tool help panels passed. Uses the production main scene and actual UI interactions, muted audio, isolated test state, and disabled saving/network requests.
- `scripts/test-wisdom-feedback.ps1 -VisibleGame -WisdomOnly`: passed on a standalone run, including Wisdom help and unlock behavior.
- An earlier temporary review failed to reach the Wisdom card reliably. Its blank capture was rejected; the established Wisdom test supplied the verified capture. An overlapping validation also triggered the wrapper's unrelated-process guard; the standalone rerun completed cleanly.
- Raw 1080 × 1920 captures were visually inspected: `.codex-tmp/help-copy-review/{xp-bonuses,success-bonuses,time-bonuses,berry-help,fishing-*-help}.png` and `.codex-tmp/wisdom-review/wisdom-help.png`.
