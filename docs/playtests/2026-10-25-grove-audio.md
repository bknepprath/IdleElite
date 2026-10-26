# Grove sound effects, October 25

Two short wooden impacts alternate on successful axe contact at 54 percent of the swing. Pitch varies from 0.94 to 1.06, with base -14 dB and +/-1 dB variation. Misses do not play impact thuds. Source assets copied unchanged from existing wood-post and wood-bucket candidates to assets/sfx/grove-axe-thud-1.wav and grove-axe-thud-2.wav.

The existing xp_spark.wav supplies one collection cue when paid logs and XP are awarded, at -16 dB and pitch 0.98 to 1.04. A higher-priority reward accent ducks it by another 6 dB. A large harvest still produces one cue, not one per log. Each layer reuses one SFX-bus player, respecting the SFX mute/volume controls and input unlock. Inactive, hidden, unmounted and fully clipped arenas do not initiate these sounds. Reward and save rules are unchanged.

Actual-main test grove_audio_capture.gd passed two timed impacts, alternating assets, one bountiful paid harvest, quiet playback levels, and inactive/duplicate-harvest guards. Raw 1080x1920 evidence and the actual SFX-bus recording: outputs/verification/grove-audio-oct25/. Monitoring used the Dummy driver; no audible preview was played. The mix includes the normal start tap and is measured separately below. GROVES_RANGE failures=[] covers existing grove/range gameplay and saves.

Android preview update pending build and Wi-Fi installation. No publication.

Measured real-game SFX mix, including the ordinary activity-start tap: {"seconds": 4.829750566893424, "peak_dbfs": -4.586608647387108, "rms_dbfs": -39.27989753991976, "clipped_samples": 0}.

Android Preview built and installed over Wi-Fi on Samsung SM-S928U / R5CX22KSM1H. Existing com.idleelite.game.preview updated in place; saves and the production package retained. Export guards passed, zero tracked import changes were restored, and no headless Godot process remained after validation/export. Preview monitoring stayed muted during checks.

Phone startup passed after the audio update: existing Fighting/Rockslide state restored, with no script, missing-resource or fatal errors and no visible rendering corruption. Left the game open. Phone media volume was already 3/15 at handoff and was left unchanged. Physical startup capture: outputs/verification/grove-audio-oct25/phone/ready.png.
