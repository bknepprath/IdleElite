# Hub upgrade audit, October 25

Scope: construction signs and hub prop scale. Upgrade panels were exercised but their design was retained. No phone installation, save editing, release or publication.

All six unbuilt upgrades now use matching wooden signs, with distinct barn, seedling, fish, notice, axe and dummy emblems. The transparent 1536x1024 sheet uses six canonical 512px cells with a shared ground point at (256,450). Each sign has a fixed 200px draw box. Existing built tier artwork uses 80% of its prior authored size: barn 280px, garden 248px, pond 288px, mission 232px, totem 240px and dummy 224px. Touch targets and saved positions are retained. The trophy display is unchanged.

The audit found an old atlas-cell size minimum that enlarged four module types during initial creation. Hub prop creation now explicitly uses the authored draw box, matching subsequent refreshes. All six signs therefore have equal display scale. No scale is calculated from alpha bounds.

Construction recovery: a saved `building: true` flag with a missing, zero or future `build_started_unix_msec` can otherwise leave an upgrade pending indefinitely. Live runtime state repair restarts only that already-paid construction clock for the normal 15 seconds. Save normalization remains deterministic. Valid timestamps, legacy timestamp fields, upgrade levels, costs and skill gates remain compatible. This does not reconstruct deleted upgrade levels, and the cause of the reported phone reset has not been established.

Validation:

- Real production main scene at 1080x1920, reached through the actual hub navigation control
- All five levels of all six props checked for exact authored draw size and visually inspected
- All six construction signs tapped to open their actual upgrade panels
- Missing and future timers recovered for all six module types, including save roundtrip and exactly-once completion
- Empty hub can build the mission board through its actual Build button, spending 25 Softwood once
- Repaired mission construction finishes and its next upgrade remains available for 30 Hardwood
- Building Lv 10 gate and existing valid construction clocks retained
- Save normalization, save hardening and old-version update integration checked separately
- Required hub screen audit executed with isolated data

The older v1 integration fixture had no known cloud base, which now intentionally invokes first-login conflict review. Its alias comparison now supplies the known branch revision/signature so it continues testing alias migration and safe restoration under the current account-protection contract. Production cloud conflict behavior was not changed.

Raw viewport captures: `outputs/verification/hub-upgrade-audit-oct25/final/`. Level-zero and level-four captures show the final smaller signs and built props. `mission-building.png` and `mission-built.png` show construction states. Test script: `scripts/tests/hub_upgrade_audit_capture.gd`.

Art provenance, contract and generated master: `output/imagegen/hub-signs-oct25/`. Built-in ImageGen used approved hub tree/decor style anchors, with the old barn sign as a subject reference. Offline preparation translates cells to the shared ground anchor without scaling, repainting or altering source alpha. Tracked import metadata was preserved.
