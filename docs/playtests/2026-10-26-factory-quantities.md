# Factory recipe quantities

Recipe amounts now occupy small lower-right badges inside the action boxes, with a white backing for legibility over item art. Single-input/output badges retain 14px padding from the box edges; multi-ingredient inputs have one badge per ingredient. Factory modules remain 440px tall. The progress rail and square mastery perimeter remain clear, and item hit targets, input reservation and transfer animations are unchanged.

The muted actual-main `factory_bounce_capture.gd` passed all nine converters, including three-ingredient Assemble Lantern and the two-digit Selective Net cost. Assertions cover badge containment, unchanged height, medal/header placement, all three transfer segments and exactly one completion output. All 45 screenshots are raw 1080 by 1920 captures. Inspected Melt Sand, Assemble Lantern and Weave Selective Net directly, including lower-right output badges and each ingredient count.

Evidence: `outputs/verification/factory-quantities-oct26/result.json` has no failures. Local changes only; no phone installation or publication.
