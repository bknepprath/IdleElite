# Text audit: 2026-09-07

Audited skill information, stat breakdowns, passive/hub information, tier mastery, offline summary, and bottom chat typography.

Changes:
- Skill information popovers size to their existing 52px body text instead of reserving excess height.
- Tier mastery requirements and reward details use 52px text; supporting labels use 48px and main rewards 60px. Cards and expanded banner are taller to accommodate wrapping.
- Offline summary body text uses 52px, highlights 48px, and titles/values 60px. Modal and cards were enlarged accordingly.
- Bottom Global Chat strip uses the shared bold font at 52px, with height increased to 148px.
- Bottom-left collapse arrow and ring are black.

Validation:
- Ran the real main scene visibly using an isolated save, reached information popovers and tier expansion through native button input, and simulated two hours of offline production progress.
- Inspected raw 1080x1920 captures in .codex-tmp/text-audit: fishing-info.png, thieving-info.png, tier-info.png, tier-info-lower.png, offline-info.png.
- UI harness completed with no failed assertions. Targeted git diff whitespace check passed.
- Existing shutdown RID/ObjectDB leak warnings remain. The migration contract check remains blocked by its existing fishing-name heavy-outline assertion.
- No owned Godot processes remained after verification; the user Project Manager was left running.

## Tier typography correction

Reduced mastery requirement and medal labels to 36px, reward heading to 32px, value to 48px, and reward detail to 36px per user feedback. Increased reward outlines to 10/12px. Reduced goal card height to 280px and expanded banner to 1370px. Replaced the level/XP dot with whitespace. Verified through the real main-scene tier button at 1080x1920; harness assertions passed. Existing shutdown leak warnings remain.
