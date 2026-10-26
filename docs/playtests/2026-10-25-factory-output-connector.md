# Continuous factory output connector

Fixed Melt Sand's output inventory line being clipped at the factory's rectangular bottom instead of reaching the V recess. The connector is now a separate sibling behind the factory face and rear plate. Its upper endpoint follows the actual transformed rear V tip with a 3px hidden overlap; its lower endpoint overlaps the output inventory border. Its alpha and visibility still follow inventory opening/closing, and the lower extent respects the revealed inventory height. No list sizing, hit targets, production values or saves changed.

The real-main `factory_inventory_capture.gd` passed all existing recipe, inventory, payment, output-menu and missing-input checks. Added regression checks prove the connector overlaps both endpoints, escapes the inventory clip, has no paper-colored pixels between its attachment points in the real rendered viewport, and disappears completely when stopped. Inspected the raw active and closed 1080x1920 frames. Required Building screen audit passed.

Evidence: `outputs/verification/factory-connector-oct25/`, especially `melt-sand-live-inventories.png` and `melt-sand-compact-stopped.png`. No phone installation, export or publication was performed.
