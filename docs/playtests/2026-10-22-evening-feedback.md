# October 22 evening Discord feedback



Source: Brian Notes #inbox, 17 comments posted October 22, 18:34–19:10. No Discord messages were sent.



## Implemented



- Jail overlays have a repeating tap pointer; taps still shorten the jail timer. Sub-minute countdowns use seconds.

- Still action portraits fit inside their squares. Animated character canvases retain their authored scale.

- Collapsing information panels update the rendered card height during the same animation step. Expanded combo help retains both skill colors.

- Navigation beside Chat no longer loses its visible edge to an invisible four-pixel Chat hit outset.

- XP symbols sit lower and have an additional one-pixel outline.

- Fishing information stays closed until requested. Success help omits the non-actionable diminishing-returns sentence; rod help omits Practice Pool/Rocks exceptions.

- Practice Pool uses a small pond in the ground. Locked fishing squares retain an empty wrapping mastery outline.

- Tool selection uses a wordless pill with contained icon hit targets and a green selected state. First-unlock Rocks recommendation is hands; saved choices still win.

- Tool offers and collection flights use the current chunky icons. Rod purchase metadata matches the actual level-18 Stick rod offer; Good and Star remain level 45 and 85.

- Rod shafts, flexible strings, bobbers and transient water are independent layers.

- The bottom strip has a calm slow wave and no top stroke. Owner requested the visible contact-water oval be restored.

- Splash sheets use two three-frame variants, random left/right/both sides and independent front/back layering. Current lifetime is 1.1–1.3 seconds, with held poses and an outward rise/fall trajectory. The whole water/tool contact is raised 24 authored pixels; splash pieces are 5% larger than the previous iteration. Rod interactions use 40% splash scale; active hands use 72% equipment scale; active net and rod bodies use 82%. These are fixed authored state scales, independent of image bounds. Rate estimates are centered as an aligned icon/value grid with left-aligned values to retain equal icon gaps.

- The contact oval uses an analytical antialiased ellipse instead of an aliased polygon edge. Its foreground half partly covers net/hands/line at contact. Contact water, ripples and both splash layers use the same palette as the area's fluid definition, including green sewers, dark deep/storm water, purple space, pale ice and lava.



## Verification



The dedicated visible production-main-scene evening regression passed at 1080x1920, including actual tool selection, no automatic help, empty locked mastery, taps two pixels above Chat, combo collapse and jail taps. A fourteen-screen raw viewport audit passed. The current Windows demo runs the same main scene at 1920x1080 with muted preview audio, isolated user data and save/online writes disabled.



Raw evidence is under `outputs/verification/brian-notes-evening-oct22/`. Art provenance and exact final-generation prompts are in `outputs/art/fishing-evening-oct22/generation.json`. Older splash captures and the initial recording precede later owner corrections; use the latest dated PNGs for the current iteration.



The seven-tool/23-location audit passed again after replacing a fixed 60ms entry wait with a wait for the real stage. Palette/immersion checks additionally visit the real sewer, deep-water, storm, space, ice, hands and rod controls after the final shared-color change. Current color proof is being collected during owner iteration.



Full `check-project.ps1` reached its final performance gate but failed `scroll/fishing mounted too many action cards for a visible skills page`. Do not claim a full-suite pass. No release build, deployment or physical-device acceptance was performed in this feedback pass.



## Desktop handoff



Sandbox-visible games were not discoverable by the desktop helper. The requested test preview was relaunched on the interactive desktop. Computer Use subsequently timed out waiting for app access, so no claim of verified foreground placement is made. Brian continued reviewing the live fishing preview. Agent-owned hidden test games are closed after validation; the owner-facing demo is left running.



## Final compact fishing layout



Owner iteration replaced the lower water strip and persistent rate panels. Location squares now flank one shared animation. Module height is 312px, down from 528px; its centered heading is 48px at y=12. The tool pill stays outside the owner module so it cannot obscure the central estimates. Food/min and XP/min appear in the center only while choosing equipment. Selected values remain for 650ms, then crossfade over 180ms back to the currently running animation. Catch bursts fade with the equipment so they cannot cover the estimates. Selection remains independent and saved per location.



Net/hands scales are fixed at 82%/72%, rods at 82%, and mirror at 90% of the shared authored equipment scale. The rod body is shifted 18 authored pixels left. Fixed contact points ground the tools; rotation is checked after interpolation. Immersion is limited to five authored pixels and equipment below the waterline is masked to the inner pool ellipse. The foreground water is 96% opaque; the pool has a three-pixel black rim. Splash pieces remain unoutlined. The three-frame sheets rise outward and fall back toward the surface rather than below the pool.



The production-main-scene seven-tool/23-location audit passed, including 121 contact and 121 haul samples for each tool. The compact interaction audit also passed through actual touch selection, changed rate values, fade and resumed rod animation, shallow net/hands contact, and suppression of catch effects during the rate preview. Raw portrait evidence is `compact-net-contact.png`, `compact-rates-open.png`, `compact-rates-selected.png`, `compact-rates-fading.png`, `compact-rod-settled.png`, and `compact-hands-contact.png` in the evidence directory above. Desktop captures are raw 1920x1080. These checks do not replace physical Android rendering acceptance.



## Base success correction



The owner rejected the October 21 global success curve: the requested nerf concerns starting activity chances, with early play remaining highly reliable and tier medal rewards providing strategic support to the next tier. The curve, catalog setting and base-chip transformation are removed. Existing additive bonuses and 100% cap are restored. All 38 level 1–10 base entries are preserved, as are recovery/passive/boss guarantees. A total of 119 later ordinary base rates are reduced individually, with dependable tasks and more demanding alternatives rather than a global penalty.



The production success audit passed at four medal/Barn profiles and checked every populated adjacent tier pair: completing the prior tier's Bronze set grants the existing five accuracy points to every next-tier action, subject only to the ordinary 100% cap. The ten-medal/Barn-4 scenario has 45 of 119 later activities at 100%, versus 67 with the former bases. These are synthetic comparisons with the curve absent in both cases. Full details and all before/after bases: `outputs/verification/success-base-oct22/`. `test-ham-oct21.ps1` passed after replacing its curve assertion with additive high-rate checks. No medal or tier rewards were reduced.


## October 22 action-art framing

Reviewed all 173 permanent activity definitions and five events. Authored focal crops fill the portrait while preserving medal clearance and headroom; the same crop applies throughout each animation. Practice Kicking now uses a smooth blue figure without mud. Loot a Pirate Ship retains its large scale and moves down/right to clear the medal. Production proof and validation are recorded in `docs/playtests/2026-10-22-action-art.md`.
