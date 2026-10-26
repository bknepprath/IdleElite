# Factory layout and bounce sequence

Melt Sand's separate compact recipe row was removed. All nine production converters now share Shape Bottles' full input/output arrangement, at the existing 440px family height. XP/time sits at the top right; the medal overlaps the output action box's top-left corner. Input and output quantities remain beneath their full-size boxes. Backgrounds, icon artwork, mastery rings, the continuous V-shaped rail and its opportunity windows retain their style.

Every converter opens ingredient inventories above and its output inventory below. One-ingredient recipes keep a single 200px input box; multi-ingredient recipes retain their existing 300px input group with the actual ingredients and quantities. All ingredient inventories and flyers derive from the recipe. The controller now applies to the factory family by definition rather than an individual activity flag. Existing source entries explicitly record the uniform presentation.

The fixed 112px transfer sprites follow three parabolic hops: upper inventory into the left input, left input toward the right output while morphing, then the actual completed output into its lower inventory. Incoming ingredients stagger slightly; contact pulses and a small authored scale overshoot give the hits more weight. The conversion hop has 132px lift; initial/output hops have 120/136px lift. The real progress and completion event drive the sequence. Reservation, completion timing, stamina, XP rules and material output quantities remain unchanged. Animation never grants or spends resources.

Inventory opening keeps the whole group between the skill header and bottom utility controls. Rows have a 16px connector gap, and the output connector overlaps the actual rear V tip outside clipping. Hidden recipe input/output menus and source navigation retain their existing controls. The shared Honey information control now anchors to its container width, so it fits compact recipe inventories too.

The final visual pass exposed original kiln artwork returning during generic UI refreshes and critical bursts. Converter cards now mark their original art as replaced and publish the actual output icon as reward_art. Visibility refresh respects that replacement, and critical effects use the displayed subject. The final capture tests check original-art visibility on every observed frame and explicitly verify the critical burst's output texture.

Passed validation:

- Activity database contracts and database audit, with no missing assets
- production_paths.gd: existing recipe reservation, quantities, progression and save compatibility
- factory_bounce_capture.gd across all nine converters: actual output selection, consistent header/medal/action boxes, all three hop segments, one/two/three ingredients and exactly one recipe output credit
- Final raw capture at Melt Sand, Shape Bottles and Assemble Lantern after spacing/critical-art fixes, including header and utility clearance
- factory_inventory_capture.gd after the final row spacing: exact Sand reservation, Glass output, live counts, selector taps, closing, continuous connector pixels and no unpaid output
- No script/parse errors in final logs; the environment emits its existing root-certificate warning
- No agent-owned Godot process remained after verification

All proof images are raw real-main 1080x1920 viewport captures. Full family evidence: outputs/verification/factory-bounce-oct26. Final before/input/right/down/landed frames: outputs/verification/factory-bounce-oct26/final. Inventory/payment evidence: outputs/verification/factory-inventory-full-oct26/final. Tests use the silent audio driver, post-startup mute, isolated user storage, disabled save writes and no online requests.

No art generation, renderer/stretch change, Android export, phone update or external publication was performed.
