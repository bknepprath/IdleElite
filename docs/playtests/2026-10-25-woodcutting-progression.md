# Woodcutting progression, October 25

Reproduced in the real main scene at 1080x1920 using a legacy level-13 save state: ordinary activities through Prune Orchard Row are claimed, Birch Grove is not. The grove consumed the single locked-activity preview, hiding Fell Skinny Pine and its Resin demand. Three targeted assertions failed before the fix.

Activity unlock runtime now tracks the grove teaser separately. Existing ordinary earlier locks still prevent premature grove reveals. No source data, rewards, requirements or save keys changed.

Corrected actual-main run: WOODCUTTING_PROGRESSION failures=[]. Verified berries and the next Pine blocker both visible, Birch remains available, later ordinary activities and groves stay hidden, Resin demand is active, Resin success fills the barrier without bypassing level 15, actual touch on the padlock unlocks Pine at level 15, and level-16 Chop Knotty Maple appears next. A fresh level-1 state does not reveal Birch early.

Raw 1080x1920 evidence: outputs/verification/woodcutting-unlocks-oct25/after/. Before-fix evidence retained under before/. A further real-game run uses SkillState.recalculate_level to verify the ready lock and next reveal during live play, without an explicit screen rebuild or navigation away; it also passes. Preview tests muted. Android installation pending reconnection of the Samsung; no device was listed when testing completed. No publication.

Android preview AAB and signed universal APKS packaging completed successfully. Settings restored, zero tracked import files changed, and no headless Godot process remains. Installation still requires the Samsung to reconnect.


## Wi-Fi installation completed

Installed the signed preview APKS over Wi-Fi on the same Samsung, SM-S928U / R5CX22KSM1H. Last verified endpoint: 192.168.1.199:36155 (dynamic; verify adb devices before reuse). Computer Ethernet 192.168.1.164 and phone Wi-Fi share the same local network. The phone was already authorized; pairing code was unnecessary. The initial ADB server denied outbound sockets; restarting it through an approved network-enabled command resolved the issue. No firewall settings changed.

Package com.idleelite.game.preview updated in place, 0.7.2/code 44. Production package and save data preserved. Earlier pending-install notes above are superseded by this receipt. Future updates can use Wi-Fi while Wireless debugging remains available and the phone is reachable; a changed endpoint may require reconnecting.

Physical-phone check passed after the Wi-Fi install: the existing Woodcutting Lv 21 save restored with an active Pine Grove, axe Lv 3, and 2.17K Softwood. Grove and surrounding modules rendered normally without visible tearing. No Godot script errors; an Android WebView variations-seed warning was present. Raw phone capture phone/ready.png is 1080x2340. Game left open.
