extends Control

const FishingState = preload("res://scripts/fishing/state.gd")
const FishingUiSurface = preload("res://scripts/fishing/ui_surface.gd")
const ActivityQueueRuntime = preload("res://scripts/activity_queue/runtime.gd")
const ActivityDataCatalog = preload("res://scripts/activity_data/catalog.gd")
const AudioDirector = preload("res://scripts/audio/audio_director.gd")
const OnboardingRuntime = preload("res://scripts/tutorial/onboarding_runtime.gd")
const ActivityLockRig = preload("res://scripts/ui/activity_lock_rig.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const AdBonus = preload("res://scripts/monetization/ad_bonus.gd")
const MaterialRuntime = preload("res://scripts/materials/runtime.gd")
const FightingRuntime = preload("res://scripts/gameplay/fighting_runtime.gd")
const ActionRuntime = preload("res://scripts/gameplay/action_runtime.gd")
const ActivityUnlockRuntime = preload("res://scripts/gameplay/activity_unlock_runtime.gd")
const ConvergenceRuntime = preload("res://scripts/gameplay/convergence_runtime.gd")
const BootWarmupRuntime = preload("res://scripts/app/boot_warmup_runtime.gd")
const AppLifecycleRuntime = preload("res://scripts/app/lifecycle_runtime.gd")
const PerformanceRuntime = preload("res://scripts/app/performance_runtime.gd")
const HubRuntime = preload("res://scripts/gameplay/hub_runtime.gd")
const HubSurface = preload("res://scripts/ui/hub_surface.gd")
const PassiveModulesRuntime = preload("res://scripts/gameplay/passive_modules_runtime.gd")
const PassiveFirepitSurface = preload("res://scripts/ui/passive_firepit_surface.gd")
const InputRoutingShell = preload("res://scripts/ui/input_routing_shell.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const SkillDetailSurface = preload("res://scripts/ui/skill_detail_surface.gd")
const SkillSwipeActivitySurface = preload("res://scripts/ui/skill_swipe_activity_surface.gd")
const ActivityUnlockCeremonySurface = preload("res://scripts/ui/activity_unlock_ceremony_surface.gd")
const TutorialOverlaySurface = preload("res://scripts/ui/tutorial_overlay_surface.gd")
const AchievementToastSurface = preload("res://scripts/ui/achievement_toast_surface.gd")
const MaterialCollectionSurface = preload("res://scripts/ui/material_collection_surface.gd")
const RewardFeedbackSurface = preload("res://scripts/ui/reward_feedback_surface.gd")
const TemporaryEventSurface = preload("res://scripts/ui/temporary_event_surface.gd")
const SettingsSurface = preload("res://scripts/ui/settings_surface.gd")
const ShopSurface = preload("res://scripts/ui/shop_surface.gd")
const CrashReportRuntime = preload("res://scripts/diagnostics/crash_report_runtime.gd")
const OnlineRuntime = preload("res://scripts/online/online_runtime.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const VisualTextureCache = preload("res://scripts/core/visual_texture_cache.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const SaveRuntime = preload("res://scripts/save_state/save_runtime.gd")
const LeaderboardProfile = preload("res://scripts/leaderboard/profile.gd")
const TemporaryEventRuntime = preload("res://scripts/temporary_events/runtime.gd")
const ThievingState = preload("res://scripts/thieving/state.gd")
const ThievingSurface = preload("res://scripts/thieving/surface.gd")
const StopHoldCircle = preload("res://scripts/ui/stop_hold_circle.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const ButtonPressState = preload("res://scripts/ui/button_press_state.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const AchievementOverlaySurface = preload("res://scripts/ui/achievement_overlay_surface.gd")
const PaperButtonStyles = preload("res://scripts/ui/paper_button_styles.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ThemeStyles = preload("res://scripts/ui/theme_styles.gd")

const PAPER_BUTTON_OUTLINE_WIDTH := 9.0
const DEFAULT_BUTTON_TEXT_OUTLINE_SIZE := 24
const ACTION_CARD_TITLE_OUTLINE_SIZE := 34
const ACTION_CARD_FACE_BORDER_ENABLED := true
const ACTION_CARD_FACE_RADIUS := 66.0
const ACTION_CARD_FACE_BORDER_Z_INDEX := 244
const PASSIVE_PROGRESS_BAR_Z_INDEX := ACTION_CARD_FACE_BORDER_Z_INDEX + 1
const UI_STATIC_REFRESH_INTERVAL_SECONDS := 0.50
const DETAIL_HEADER_GAUGE_REFRESH_SECONDS := 0.05
const PASSIVE_CARD_PROGRESS_REFRESH_SECONDS := 0.10
const DETAIL_ACTIONS_SCROLL_LIMIT_REFRESH_SECONDS := 0.10
const GOD_MODE_TARGET_LEVEL := 99
const UNMARKED_MAXED_SAVE_COMPLETION_LIMIT := 5000
const TOTAL_LEVEL_BARGRAPH_TEXTURE := "res://assets/content/ui/total-level-bargraph.png"
const SETTINGS_GEAR_ICON_TEXTURE := "res://assets/content/ui/settings-gear-icon.png"
const SHOP_ICON_TEXTURE := "res://assets/content/ui/shop-icon.png"
const HERO_SPEECH_BUBBLE_TEXTURE := "res://assets/content/ui/hero-speech-bubble-down.png"
const PROGRESS_STAR_ICON_TEXTURE := "res://assets/content/ui/progress-star-icon.png"
const BASE_MAX_STAMINA := SkillState.BASE_MAX_STAMINA
const STAMINA_REGEN_SECONDS := SkillState.STAMINA_REGEN_SECONDS
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const MIN_MOBILE_BODY_FONT_SIZE := 52
const MIN_MOBILE_INFO_TITLE_FONT_SIZE := 60
const MASTERY_MAX_LEVEL := 20
const ACTION_CARD_MEDAL_PRESS_KIND := "__medal__"
const BASE_CANVAS := Vector2(2160, 3840)
const SKILL_DETAIL_BOTTOM_UI_CLEARANCE := 340
const SKILLS_PAGE_TOP_PAD := 96
const PAGE_PAD := 96
const CARD_RADIUS := 64
const ACTION_CARD_HEIGHT := 720
const COMBAT_DIAMOND_ARENA_CARD_HEIGHT := 1220
const ACTION_CARD_EXPANDED_HEIGHT := 1280
const ACTION_CARD_INFO_EXPAND_SECONDS := 0.22
const ACTION_CARD_INFO_FADE_IN_SECONDS := 0.08
const ACTION_CARD_INFO_FADE_OUT_SECONDS := 0.12
const FISHING_BACKGROUND_CROP_LEFT := 0.06
const FISHING_BACKGROUND_CROP_TOP := 0.06
const FISHING_BACKGROUND_CROP_RIGHT := 0.015
const FISHING_REWORK_ENABLED := true
const ACTIVITY_PADLOCK_CLICK_SHAKE_SECONDS := 0.26
const PASSIVE_MODULE_CARD_HEIGHT := 940
const ACTION_CARD_POP_GUTTER := 44
const ACTION_CARD_3D_DEPTH_OFFSET := Vector2(14.0, 16.0)
const ACTION_CARD_3D_PRESS_OFFSET := Vector2(28.0, 34.0)
const ACTION_CARD_3D_PRESS_SECONDS := 0.098
const ACTION_CARD_3D_PRESS_HOLD_SECONDS := 0.045
const ACTION_CARD_3D_RELEASE_SECONDS := 0.14
const ACTION_CARD_3D_PRESS_FEEDBACK_DELAY_SECONDS := 0.075
const ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE := 18.0
const ACTION_CARD_TAP_RELEASE_SLOP := 120.0
const ACTION_STAT_TAP_RELEASE_SLOP := 30.0
const PASSIVE_BUTTON_TAP_RELEASE_SLOP := 52.0
const ACTION_CARD_DUPLICATE_TAP_MSEC := 36
const ACTION_PROGRESS_SPEED_EASE := 4.8
const ACTION_CANCELED_PROGRESS_DECAY_PER_SECOND := 0.24
const SKILL_MENU_ICON_BADGE_SIZE := Vector2(324, 324)
const SKILL_MENU_ICON_SYMBOL_SIZE := Vector2(336, 336)
const ACHIEVEMENT_SECTION_SKILL_ICON_SIZE := Vector2(178, 178)
const SKILL_DETAIL_HEADER_HEIGHT := 704
const SKILL_DETAIL_HEADER_MARGIN_BOTTOM := 34
const SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT := 18
const SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT := 8
const PINNED_ACTIVITIES_STAMINA_GAUGE_SIZE := Vector2(452, 452)
const ONBOARDING_FIRST_MODULE_CENTER_RELEASE_SECONDS := 0.72
const SKILL_DETAIL_BOTTOM_SCROLL_PAD := 48
const THIEVING_SKILL_DETAIL_BOTTOM_SCROLL_PAD := 48
const SKILL_DETAIL_TITLE_FONT_SIZE := 152
const SKILL_DETAIL_WOODCUTTING_TITLE_FONT_SIZE := 128
const SKILL_DETAIL_XP_FONT_SIZE := 62
const SKILL_DETAIL_XP_BAR_HEIGHT := 96
const DETAIL_RESTORE_SCROLL_BOTTOM := -2
const MODULE_TITLE_OVER_PIN_Z_INDEX := 390
const SKILL_DETAIL_TEXT_SEPARATION := 25
const SKILL_DETAIL_LEFT_SEPARATION := 67
const SKILL_DETAIL_XP_BAR_WIDTH := 710
const SKILL_DETAIL_ICON_SIZE := Vector2(400, 400)
const SKILL_DETAIL_ICON_BORDER_WIDTH := 18.0
const SKILL_DETAIL_ICON_Y_OFFSET := 16.0
const SKILL_SWIPE_THRESHOLD := 230.0
const SKILL_SWIPE_FEEDBACK_DEADZONE := 46.0
const SKILL_SWIPE_PAGE_GAP := 960.0
const SKILL_SWIPE_GAP_LOAD_TRANSITION_ENABLED := true
const SKILL_SWIPE_GAP_READY_WAIT_FRAMES := 4
const SKILL_SWIPE_SETTLE_SECONDS := 0.20
const SKILL_SWIPE_CANCEL_SECONDS := 0.14
const SKILL_SWIPE_PREVIEW_FADE_DISTANCE := SKILL_SWIPE_THRESHOLD * 1.25
const SKILL_SWIPE_PREVIEW_FADE_MIN_ALPHA := 0.30
const SKILL_SWIPE_PAPER_FADE_DISTANCE := SKILL_SWIPE_THRESHOLD * 4.0
const SKILL_SWIPE_CREAM_COVER_FADE_IN_SECONDS := 0.08
const SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS := 0.12
const SKILL_SWIPE_PAGE_SWITCH_FADE_OUT_SECONDS := 0.22
const SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS := 0.28
const SKILL_SWIPE_MODULE_UTILITY_FADE_OUT_SECONDS := 0.18
const SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS := 0.24
const DIRECT_SKILL_NAV_COVER_MIN_SECONDS := 0.24
const DIRECT_SKILL_NAV_COVER_FADE_IN_SECONDS := 0.10
const DIRECT_SKILL_NAV_COVER_FADE_SECONDS := 0.18
const PAGE_SWITCH_SCROLL_COVER_FADE_IN_SECONDS := 0.22
const PAGE_SWITCH_SCROLL_COVER_HOLD_SECONDS := 0.34
const PAGE_SWITCH_SCROLL_COVER_FADE_SECONDS := 0.18
const SKILL_SWIPE_LIGHT_PREVIEW_ENABLED := true
const SKILL_SWIPE_LIGHT_PREVIEW_HEADER_ENABLED := true
const SKILL_SWIPE_LIGHT_PREVIEW_MAX_CARDS := 1
const SKILL_SWIPE_HIDDEN_PREVIEW_MAX_CARDS := 1
const SKILL_SWIPE_REAL_CARD_PREWARM_COUNT := 4
const SKILL_SWIPE_REAL_PREVIEW_TEXTURE_PREWARM_ENABLED := true
const SKILL_SWIPE_FINALIZE_SETTLE_FRAMES := 1
const SKILL_SWIPE_FINALIZE_VISIBLE_MOUNT_LIMIT := 2
const SKILL_SWIPE_FINALIZE_SLOT_BATCH_SIZE := 1
const SKILL_SWIPE_PREVIEW_FREE_BATCH_SIZE := 1
const SKILL_SWIPE_PROXY_FULL_REFRESH_DELAY_FRAMES := 720
const SKILL_SWIPE_BUTTON_SUPPRESS_MSEC := 320
const SKILL_DETAIL_SHADOW_FADE_SCROLL := 72.0
const SKILL_DETAIL_SHADOW_FADE_SPEED := 10.0
const TUTORIAL_TIP_FADE_SECONDS := 0.28
const TUTORIAL_TIP_FADE_OUT_SECONDS := 1.2
const ACTIVITY_START_TIP_FADE_SECONDS := 0.62
const TUTORIAL_STARTER_SKILL_ID := "fight"
const TUTORIAL_STARTER_ACTION_ID := "push-ups"
const TUTORIAL_LEVEL_TWO_ACTION_ID := "kick-mud-off-boot"
const TUTORIAL_GATE_LATCH_ACTION_ID := "wrestle-stuck-gate-latch"
const TUTORIAL_DEFERRED_AFTER_GATE_ACTION_ID := "box-suspicious-feed-sack"
const ONBOARDING_HEADER_FADE_SECONDS := 0.62
const ONBOARDING_SUMMARY_FADE_SECONDS := 2.0
const ONBOARDING_AUTO_RUN_MESSAGE_COMPLETION_THRESHOLD := 1
const ONBOARDING_HEADER_REVEAL_PROGRESS_FRACTION := 0.5
const ONBOARDING_AUTO_RUN_MESSAGE_LINGER_SECONDS := 3.0
const ONBOARDING_STAMINA_GAUGE_DELAY_BEFORE_FADE_SECONDS := 2.0
const ONBOARDING_STAMINA_GAUGE_FADE_SECONDS := 2.0
const ONBOARDING_STAMINA_TIP_LINGER_SECONDS := 4.0
const ONBOARDING_STAMINA_TIP_LABEL_WIDTH := 300.0
const ONBOARDING_SWIPE_STAMINA_THRESHOLD := 5.0
const ONBOARDING_FIGHT_ACTION_STATS_FADE_SECONDS := 2.0
const ONBOARDING_BOTTOM_TIP_FADE_SECONDS := 1.2
const STAMINA_TIP_DISCOVERY_HOLD_SECONDS := 4.0
const BOTTOM_TUTORIAL_TIP_FONT_SIZE := 64
const PASSIVE_BUTTON_TAP_CONFIRM_SECONDS := 0.08
const FIREBASE_DATABASE_URL := ""
const FIREBASE_WEB_API_KEY := ""
const CHAT_STREAM_RETRY_INTERVAL_SECONDS := 30
const CHAT_STREAM_RECONNECT_MIN_SECONDS := 5
const CHAT_STREAM_POLL_INTERVAL_SECONDS := 0.25
const CHAT_STREAM_MAX_BUFFER_CHARS := 65536
const CHAT_SEND_INTERVAL_SECONDS := 2
const CHAT_MESSAGE_MAX_CHARS := 80
const CHAT_STRIP_VISIBLE_COUNT := 2
const CHAT_FULL_VISIBLE_COUNT := 25
const HUB_OVERLAY_Z := 2800
const CHAT_CENSORED_WORDS := [
	"fag",
	"faggot",
	"faggots",
	"nigga",
	"niggas",
	"nigger",
	"niggers"
]
const PROFILE_DISPLAY_NAME_MAX_CHARS := 16
const PROFILE_NAME_KEY_MAX_CHARS := 16
const PROFILE_GUEST_NAME_PREFIX := "guest"
const LOW_STAMINA_ACTION_SPEED_MULT := 0.20
const ACTIVITY_PREVIEW_FADE_IN_SECONDS := 1.28
const MODAL_OVERLAY_Z := 4096
const TUTORIAL_LAYER := AchievementToastSurface.CANVAS_LAYER + 1
const BOOT_WARMUP_LAYER := TUTORIAL_LAYER + 2
const SKILL_NAV_COVER_CANVAS_LAYER := ProfileChatOverlaySurface.PROFILE_OVERLAY_CANVAS_LAYER + 1
const PIN_TRANSITION_BLOCKER_MIN_SECONDS := 0.62
const PIN_TRANSITION_BLOCKER_FADE_SECONDS := 0.18
const FISHING_DETAIL_RENDER_REVEAL_BUFFER_PX := 2200.0
const FISHING_DETAIL_RENDER_HIDE_BUFFER_PX := 3600.0
const FISHING_DETAIL_RENDER_CULL_ACTIVE_STEP_PX := 180.0
const FISHING_DETAIL_RENDER_CULL_ACTIVE_MIN_MSEC := 56
const FISHING_DETAIL_USE_FLAT_ART := true
const FISHING_SCROLL_MODE_SETTLE_MSEC := 160
const FISHING_DETAIL_VISIBLE_SETTLE_FILL_BUDGET := 1
const FISHING_DETAIL_IDLE_WARM_MOUNT_MAX_ACTION_CARDS := 12
const MODULE_LIST_TRANSITION_SECONDS := 0.42
const MODULE_LIST_TRANSITION_NEW_SECONDS := 0.30
const MODULE_LIST_TRANSITION_NEW_OFFSET_Y := 28.0
const MODULE_LIST_TRANSITION_MIN_MOVE := 2.0
const DETAIL_TEXTURE_PREWARM_REQUESTS_PER_FRAME := 2
const BACKGROUND_MAINTENANCE_INTERVAL_SECONDS := 0.25
const BACKGROUND_MAINTENANCE_STEP_COUNT := 7
const EXTENDED_AUDIO_WARMUP_FRAME_BUDGET_MSEC := 12
const ACTION_PROGRESS_RAIL_INSET := 0
const ACTION_PROGRESS_RAIL_HEIGHT := 88
const PASSIVE_BORDER := 0

const COLOR_INK := Color("#171615")
const COLOR_PAPER := Color("#f8f1e5")
const COLOR_PANEL := Color("#fffdf8")
const COLOR_LINE := Color("#d9cfbc")
const COLOR_MUTED := Color("#6e6658")
const COLOR_DARK_PAPER := Color("#202329")
const COLOR_DARK_PANEL := Color("#2b2f37")
const COLOR_DARK_PANEL_ALT := Color("#343942")
const COLOR_DARK_LINE := Color("#4b515c")
const COLOR_DARK_INK := Color("#f4f1e8")
const COLOR_DARK_MUTED := Color("#c7c0b4")
const COLOR_GOLD := Color("#fff2a8")
const COLOR_GREEN := Color("#35d86d")
const COLOR_BLUE := Color("#3aa0ff")
const COLOR_NAV := Color("#444a5b")
const COLOR_RED := Color("#e84d4d")
var skills := {}
var activity_data_catalog := ActivityDataCatalog.new()
var skill_defs := activity_data_catalog.skill_defs
var actions_by_skill := activity_data_catalog.actions_by_skill
var actions_by_key := activity_data_catalog.actions_by_key
var convergence_action_ids := activity_data_catalog.convergence_action_ids
var fishing_area_definitions: Array:
	get:
		return fishing_runtime.area_definitions
	set(value):
		fishing_runtime.area_definitions = value
var selected_skill_id := "fight"
var current_screen := "home"
var running_skill_id := ""
var running_action_id := ""
var action_progress := 0.0
var canceled_action_progress_by_key := {}
var action_card_press_consumed := false
var tired_activity_zero_float_action_key := ""
var material_runtime := MaterialRuntime.new()
var fishing_runtime := FishingState.new()
var thieving_state := ThievingState.new(self)
var passive_modules := {}
var passive_modules_runtime: PassiveModulesRuntime
var convergence_runtime: ConvergenceRuntime
var convergence_modules: Dictionary:
	get:
		return _convergence_runtime().convergence_modules
	set(value):
		_convergence_runtime().convergence_modules = value
var built_modules := {}
var hub_runtime: HubRuntime
var hub_surface: HubSurface
var last_hub_mission_completion_ceremony_text := ""
var onboarding_runtime: OnboardingRuntime
var activity_unlock_runtime: ActivityUnlockRuntime
var activity_unlock_ceremony_surface: ActivityUnlockCeremonySurface
var manual_activity_unlocks:
	get: return _activity_unlock_runtime().manual_activity_unlocks
	set(value): _activity_unlock_runtime().manual_activity_unlocks = value
var manual_activity_requirement_unlocks:
	get: return _activity_unlock_runtime().manual_activity_requirement_unlocks
	set(value): _activity_unlock_runtime().manual_activity_requirement_unlocks = value

const FISHING_ACTION_ID_ALIASES := {
	"build:add-roof-to-something-roofless": "roof-the-roofless",
	"fishing:anchor-the-tiny-boat-dock": "anchor-tiny-boat-dock",
	"build:assemble-windmill-that-judges-you": "assemble-windmill",
	"woodcutting:axe-the-world-trees-paperwork": "axe-world-tree-forms",
	"fishing:beach-crab-pot": "reef-pot",
	"fishing:beach-ripple": "storm-ripple",
	"fishing:beach-rocks": "rocks",
	"fishing:beach-shallows": "shallows",
	"fight:body-slam-the-root-cellar-door": "unstuck-root-cellar-door",
	"fight:brawl-with-kicking-milk-pail": "brawl-with-milk-pail",
	"fishing:cast-from-rowboat": "rowboat",
	"fishing:cast-bamboo-rod": "river-bend",
	"fishing:cast-storm-kite-line": "storm-line",
	"fight:chicken-sparring-pit": "fight-chickens",
	"fishing:chum-open-water": "chum-line",
	"woodcutting:clear-the-forests-legal-department": "clear-forest-legal",
	"fight:covered-wagon-ambush-drill": "ambush-log-wagon",
	"thieving:crack-the-breakroom-snack-safe": "crack-snack-safe",
	"thieving:crack-the-vault-between-dimensions": "crack-dimensional-vault",
	"fishing:deep-sea-abyss": "abyss",
	"fishing:deep-sea-trench": "deep-trench",
	"fishing:deep-sea-wreck-drop": "wreck-drop",
	"fight:defeat-the-tractor-that-would-not-start": "defeat-stubborn-tractor",
	"fishing:dip-a-tidepool-minnow": "shallows",
	"thieving:distract-fruit-stand-with-jazz-hands": "jazz-hands-diversion",
	"fishing:dive-for-pearl-oysters": "pearl-bed",
	"fight:dodge-the-irrigation-betrayal": "flow-like-water",
	"fishing:drag-net-through-creek": "rocks",
	"fishing:drop-deep-trench-trap": "deep-trench",
	"fishing:drop-lobster-cage": "reef-cage",
	"fishing:dredge-wreck-with-magnet": "wreck-drop",
	"fight:duel-leaning-fence-post": "duel-fence-post",
	"woodcutting:fell-the-wooden-concept-of-height": "chop-super-tall-tree",
	"fishing:fly-fish-at-river-bend": "river-rapids",
	"fight:fight-rouses": "fight-r.o.u.s.es",
	"fight:fight-the-barn-door-at-midnight": "fight-barn-door",
	"fishing:fish-with-magnetic-hook": "wreck-drop",
	"fight:grapple-overfull-compost-bin": "grapple-compost-bin",
	"build:hammer-one-suspicious-nail": "hammer-nails",
	"fishing:hand-grab-muddy-catfish": "drain-gate",
	"fishing:harpoon-suspicious-ripple": "storm-ripple",
	"woodcutting:harvest-the-first-trees-apology": "harvest-tree-apology",
	"fight:hold-the-line-at-the-pumpkin-patch": "hold-pumpkin-line",
	"thieving:hotwire-a-parked-alien-spaceship": "hotwire-alien-ship",
	"fishing:ice-fish-through-nervous-hole": "ice-hole",
	"build:install-elevator-in-the-shack": "install-elevator",
	"thieving:lift-honey-from-beehive": "loot-beehive",
	"thieving:lift-loose-coins-from-couch-cushions": "steal-a-penny",
	"thieving:lift-the-mayors-ceremonial-purse": "skip-taxes",
	"fishing:net-the-reflection-of-a-fish": "reflection",
	"fishing:night-fish-with-lantern": "night-reef",
	"fishing:open-deep-sea-mailbox-trap": "deep-trench",
	"fight:parry-windmill-shadow": "conquer-windmill-fear",
	"build:patch-fence-with-confidence": "patch-fence",
	"thieving:pick-the-worlds-friendliest-lock": "pick-friendly-lock",
	"thieving:pickpocket-an-interdimensional-god": "pickpocket-dimensional-god",
	"thieving:pickpocket-the-security-camera": "pickpocket-camera",
	"fishing:pier-dock-edge": "dock-edge",
	"fishing:pier-piling-line": "piling-line",
	"thieving:pocket-a-penny-nobody-wanted": "borrow-cookie-permanently",
	"thieving:borrow-a-cookie-permanently": "sneak-past-tip-jar",
	"thieving:burgle-the-dream-of-a-sleeping-wizard": "burgle-wizard-dream",
	"build:construct-suspiciously-tall-silo": "build-tall-silo",
	"build:build-the-building-that-builds-you": "build-builder-building",
	"fishing:space-starlight": "starlight",
	"fishing:space-reflection": "reflection",
	"build:permit-the-impossible-megastructure": "permit-mega-structure",
	"fight:punch-through-corn-maze-panic": "escape-corn-maze",
	"fishing:reef-night-reef": "night-reef",
	"fishing:reef-pearl-bed": "pearl-bed",
	"fight:rematch-the-same-hay-bale-somehow-stronger": "rematch-buff-hay-bale",
	"fishing:river-rapids": "rapids",
	"thieving:rob-the-bank-during-a-robbery-drill": "remove-competition",
	"fishing:scoop-pond-minnows": "dock-edge",
	"fishing:sea-chum-line": "chum-line",
	"fishing:sea-open-water": "open-water",
	"fishing:sea-rowboat": "rowboat",
	"fishing:sewers-drain-gate": "drain-gate",
	"fishing:sewers-tunnel-pool": "tunnel-pool",
	"thieving:shoplift-from-the-concept-of-money": "shoplift-from-money",
	"fight:shove-wobbly-hay-bale": "push-ups",
	"fishing:skim-a-starlight-minnow": "starlight",
	"thieving:sneak-past-tip-jar-eye-contact": "pocket-couch-coins",
	"fishing:spear-fish-in-shallows": "tunnel-pool",
	"fight:square-up-with-rake-in-grass": "square-up-with-rake",
	"thieving:steal-a-password-from-a-fortune-cookie": "steal-fortune-password",
	"thieving:steal-a-wallet-from-a-mannequin": "steal-mannequin-wallet",
	"thieving:steal-the-alibi-you-used-to-do-it": "steal-your-alibi",
	"thieving:steal-the-fishermans-lucky-hook": "steal-fishermans-lucky-hook",
	"fishing:stormy-sea-ripple": "storm-ripple",
	"fishing:stormy-sea-storm-line": "storm-line",
	"thieving:swap-price-tags-at-the-broom-store": "swap-broom-price-tags",
	"thieving:swipe-the-banks-practice-vault": "practice-cracking-vault",
	"fight:tackle-runaway-water-trough": "tackle-water-trough",
	"fight:trade-blows-with-the-weather-vane": "parry-weather-vane",
	"fishing:trawl-from-tiny-boat": "open-water",
	"fishing:winter-lake-ice-hole": "ice-hole",
	"fight:win-the-great-barn-rafters-melee": "win-barn-rafter-melee",
	"woodcutting:woodcutting-firepit": "firepit",
}
var plank_boost_enabled := false
var last_passive_process_unix := 0
var mastery := {}
var stamina := {}
var stamina_bank := {}
var honey_stamina_seconds_remaining := 0.0
var stamina_gauge_pre_tip_hold_seconds := 0.0
var last_result := "Pick a skill and start training."
var offline_progress_enabled := true
var auto_unlock_lockpads_enabled := false
var god_mode_enabled := false
var god_mode_save_tainted := false
var show_stamina_decimal := false
var offline_progress_cap_notifications_enabled := false
var dark_mode_enabled := false
var app_font: Font
var app_bold_font: Font
var app_background_rect: ColorRect
var mastery_medal_dot_texture: Texture2D
var home_page: Control
var skills_page: Control
var queue_selection_mode := false
var content_scroll: ScrollContainer
var skills_content: Control
var hero_message: Label
var skills_tab: Button
var settings_tab: Button
var skill_cards := {}
var action_cards := {}
var action_card_keys := []
var module_ui_runtime := ModuleUiRuntime.new()
var module_ui_animating_collapse_key:
	get: return _skill_detail_surface().module_ui_animating_collapse_key
	set(value): _skill_detail_surface().module_ui_animating_collapse_key = value
var module_ui_pending_pin_scroll_anchor:
	get: return _skill_detail_surface().module_ui_pending_pin_scroll_anchor
	set(value): _skill_detail_surface().module_ui_pending_pin_scroll_anchor = value
var module_ui_pin_scroll_anchor_debug:
	get: return _skill_detail_surface().module_ui_pin_scroll_anchor_debug
	set(value): _skill_detail_surface().module_ui_pin_scroll_anchor_debug = value
var module_ui_pin_refresh_cover_requested:
	get: return _skill_detail_surface().module_ui_pin_refresh_cover_requested
	set(value): _skill_detail_surface().module_ui_pin_refresh_cover_requested = value
var module_ui_refresh_token:
	get: return _skill_detail_surface().module_ui_refresh_token
	set(value): _skill_detail_surface().module_ui_refresh_token = value
var activity_crit_seen := false
var activity_mega_crit_seen := false
var fishing_auto_unlock_waiting_for_detail_refresh := false
var detail_actions_scroll:
	get: return _skill_detail_surface().detail_actions_scroll
	set(value): _skill_detail_surface().detail_actions_scroll = value
var background_maintenance_elapsed := 0.0
var background_maintenance_pending_delta := 0.0
var background_maintenance_step_index := 0
var main_process_frame_index := 0
var stamina_gauge_tip_root: Control
var lock_click_tip_collapse_until_msec := 0
var settings_overlay: Control
var tutorial_layer: CanvasLayer
var tutorial_overlay: Control
var tutorial_panel: PanelContainer
var tutorial_target_ring: Panel
var tutorial_target_label: Label
var tutorial_title_label: Label
var tutorial_body_label: Label
var tutorial_step_label: Label
var tutorial_skip_button: Button
var paper_button_style_textures := {}
var summary_style_cache: StyleBoxFlat
var thieving_surface: ThievingSurface
var passive_firepit_surface: PassiveFirepitSurface
var empty_style_cache := StyleBoxEmpty.new()
var ui_static_refresh_elapsed:
	get: return _performance_runtime().ui_static_refresh_elapsed
	set(value): _performance_runtime().ui_static_refresh_elapsed = float(value)
var _last_rendered_screen_key: String:
	get:
		return _navigation_shell().last_rendered_screen_key
	set(value):
		_navigation_shell().last_rendered_screen_key = str(value)
var activity_medal_buff_total_cache := {}
var reward_bonus_cache := {}
var playable_medal_buff_actions_cache := {}
var playable_medal_buff_index_cache := {}
var visual_texture_cache := VisualTextureCache.new()
var loaded_save_this_boot := false
var activity_queue_runtime: ActivityQueueRuntime
var save_runtime: SaveRuntime
var action_runtime: ActionRuntime
var fighting_runtime: FightingRuntime
var test_state_runtime: TestStateRuntime
var app_boot_warmup_runtime: BootWarmupRuntime
var app_lifecycle_runtime: AppLifecycleRuntime
var performance_runtime: PerformanceRuntime
var temporary_event_runtime: TemporaryEventRuntime
var crash_report_runtime: CrashReportRuntime
var ad_bonus_runtime: AdBonus
var online_runtime: OnlineRuntime
var audio_director: AudioDirector
var leaderboard_presentation: LeaderboardPresentation = LeaderboardPresentation.new(self)
var leaderboard_state: LeaderboardState = LeaderboardState.new(self)
var leaderboard_profile: LeaderboardProfile = LeaderboardProfile.new(PROFILE_GUEST_NAME_PREFIX)
var button_press_runtime: ButtonPressState = ButtonPressState.new(self)
var skill_detail_surface: SkillDetailSurface
var skill_swipe_activity_surface: SkillSwipeActivitySurface
var navigation_shell: NavigationShell
var input_routing_shell: InputRoutingShell
var fishing_ui_surface: FishingUiSurface
var profile_chat_overlay_surface: ProfileChatOverlaySurface
var achievement_overlay_surface: AchievementOverlaySurface
var tutorial_overlay_surface: TutorialOverlaySurface
var achievement_toast_surface: AchievementToastSurface
var material_collection_surface: MaterialCollectionSurface
var reward_feedback_surface: RewardFeedbackSurface
var temporary_event_surface: TemporaryEventSurface
var settings_surface: SettingsSurface
var shop_surface: ShopSurface
var deferred_skill_validation_pending := false
var boot_detail_card_yield := false
var boot_detail_render_in_progress := false
var boot_lazy_background_mount_allowed := false
var deferred_selected_skill_mastery_pending := false
var boot_detail_render_queue: Array = []
var boot_detail_completion_token := 0
var boot_detail_scroll_locked := false
var shutdown_cleanup_started := false
var startup_initialized := false
var app_resume_repair_pending := false
var web_fishing_perf_probe_enabled := false
func _ready() -> void:
	_fishing_ui_surface()._load_fishing_debug_env_flags()
	visual_texture_cache.fishing_ablation_enabled = Callable(_fishing_ui_surface(), "_fishing_ablation_enabled")
	_performance_runtime()._configure_performance_mode()
	_fishing_ui_surface()._install_web_direct_wheel_scroll_bridge()
	web_fishing_perf_probe_enabled = _fishing_ui_surface()._web_fishing_perf_probe_requested()
	if OS.get_name() == "Web" or OS.has_feature("web"):
		var perf_requested_literal := "true" if web_fishing_perf_probe_enabled else "false"
		JavaScriptBridge.eval("window.__idleEliteProbeBoot = {os:%s, hasWebFeature:%s, perfRequested:%s, href:window.location.href};" % [
			JSON.stringify(OS.get_name()),
			"true" if OS.has_feature("web") else "false",
			perf_requested_literal
		], false)
	if _test_state_runtime()._headless_validation_mode():
		activity_data_catalog.load_action_data(self)
		_save_runtime()._init_state()
		_boot_warmup_runtime().validate_state()
		get_tree().quit()
		return
	_crash_report_runtime().begin_boot_session()
	_load_font()
	_boot_warmup_runtime().build_overlay()
	_boot_warmup_runtime().show_overlay()
	await _boot_warmup_runtime()._boot_progress_step("Loading data...", 0.08)
	activity_data_catalog.load_action_data(self)
	_save_runtime()._init_state()
	await _boot_warmup_runtime()._boot_progress_step("Loading save...", 0.20)
	_save_runtime().load_game()
	_settings_surface().apply_dark_mode_visual()
	if _crash_report_runtime().pending_report_exists():
		last_result = "Crash report ready in Settings."
	_navigation_shell()._select_launch_skill_page()
	_boot_warmup_runtime().prepare_selected_skill_for_render(true)
	deferred_skill_validation_pending = true
	deferred_selected_skill_mastery_pending = true
	await _build_ui_boot_async()
	await _boot_warmup_runtime()._finish_boot_render_async()
	var timer := Timer.new()
	timer.wait_time = SaveRuntime.AUTOSAVE_INTERVAL_SECONDS
	timer.autostart = true
	timer.timeout.connect(Callable(_save_runtime(), "_autosave_if_needed"))
	add_child(timer)
	if _performance_runtime()._performance_overlay_enabled_on_boot():
		_performance_runtime()._set_performance_overlay_enabled(true)
	if DisplayServer.get_name() == "headless":
		_boot_warmup_runtime().active = false
	if _test_state_runtime()._headless_boot_smoke_mode():
		_test_state_runtime().call_deferred("_run_headless_boot_smoke")
	if web_fishing_perf_probe_enabled:
		_fishing_ui_surface().call_deferred("_run_web_fishing_perf_probe_setup")
func _finish_boot_skill_detail_extras() -> void:
	if _skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(_skill_detail_surface().detail_actions_scroll):
		return
	var actions_clip := _skill_detail_surface().detail_actions_scroll.get_parent()
	if actions_clip == null or not is_instance_valid(actions_clip):
		return
	_skill_detail_surface()._build_detail_jump_arrows(actions_clip)
	_skill_detail_surface()._add_skill_detail_shadow_overlay(_skill_detail_surface()._skill_detail_shadow_top_y())

func _skill_swipe_loading_transition_active() -> bool:
	return (
		current_screen == "skill"
		and (
			_skill_swipe_activity_surface().skill_swipe_tracking
			or _skill_swipe_activity_surface().skill_swipe_animating
			or _skill_swipe_activity_surface().skill_swipe_pending_full_finalize
			or _skill_swipe_activity_surface().skill_swipe_defer_initial_lazy_mount
			or _skill_swipe_activity_surface().direct_skill_nav_cover_active
			or _navigation_shell()._page_switch_scroll_cover_active()
			or _skill_swipe_activity_surface().skill_swipe_outgoing_cover_active
			or _skill_swipe_activity_surface().skill_swipe_rebuild_cover_active
			or _skill_swipe_activity_surface().skill_swipe_queued_offset != 0
		)
	)

func _process(delta: float) -> void:
	if not startup_initialized:
		return
	if _app_lifecycle_runtime().recover_suspended_process():
		return
	if boot_detail_render_in_progress and not boot_lazy_background_mount_allowed:
		return
	var trace_process := OS.get_environment("IDLE_ELITE_TRACE_PROCESS_SLOW") == "1"
	var trace_process_skill := OS.get_environment("IDLE_ELITE_TRACE_PROCESS_SKILL")
	if trace_process and not trace_process_skill.is_empty() and selected_skill_id != trace_process_skill:
		trace_process = false
	var trace_start_usec := Time.get_ticks_usec() if trace_process else 0
	var trace_last_usec := trace_start_usec
	var trace_prewarm_us := 0
	var trace_lazy_us := 0
	var trace_background_us := 0
	var trace_action_us := 0
	var trace_ui_us := 0
	main_process_frame_index += 1
	var detail_scroll_visual_work := _skill_detail_surface()._detail_scroll_visual_work_active()
	_skill_detail_surface().detail_scroll_visual_work_this_frame = detail_scroll_visual_work
	_fishing_ui_surface()._process_fishing_scroll_mode(detail_scroll_visual_work)
	_skill_detail_surface()._process_detail_card_texture_prewarm()
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_prewarm_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	var detail_lazy_mounted_count := _skill_detail_surface()._process_detail_lazy_runtime(delta, detail_scroll_visual_work)
	_fishing_ui_surface()._process_fishing_scroll_perf_probe(delta, detail_scroll_visual_work)
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_lazy_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	if detail_lazy_mounted_count > 0 or detail_scroll_visual_work or _skill_swipe_loading_transition_active():
		background_maintenance_elapsed += maxf(0.0, delta)
	else:
		_app_lifecycle_runtime().process_background_maintenance(delta)
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_background_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	_action_runtime()._process_stamina_gauge_regen_boost(delta)
	_action_runtime()._process_action_opportunity_regen(delta)
	_action_runtime()._apply_stamina_regen_seconds(delta, true)
	_fighting_runtime().apply_blue_guy_health_regen_seconds(delta)
	_hub_surface()._process_hub_hotspot_hold(delta)
	if not _fishing_ui_surface()._fishing_detail_should_defer_action_process_for_scroll():
		_action_runtime()._process_action(delta)
	_action_stop_hold().process_action(delta)
	_passive_firepit_surface()._process_firepit_stop_hold(delta)
	_temporary_event_runtime()._process_temporary_event_scheduler(delta)
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_action_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	_audio_director()._process_music_flow(delta)
	_profile_chat_overlay_surface()._process_chat_keyboard_lift(delta)
	_profile_chat_overlay_surface()._process_chat_enter_submit_poll()
	if not _fishing_ui_surface()._fishing_detail_scroll_frame_can_skip_ui_update():
		_update_ui(delta)
	_skill_swipe_activity_surface()._maybe_release_ready_skill_swipe_cover()
	_navigation_shell()._process_page_switch_pending_transition()
	_navigation_shell()._process_pin_transition_blocker()
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_ui_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	if _fishing_ui_surface()._fishing_detail_can_defer_scroll_bounds_work(detail_lazy_mounted_count):
		_skill_detail_surface().detail_actions_scroll_limit_elapsed += delta
	else:
		_skill_detail_surface().detail_actions_scroll_limit_elapsed += delta
		if _skill_detail_surface().detail_actions_scroll_limit_elapsed >= DETAIL_ACTIONS_SCROLL_LIMIT_REFRESH_SECONDS:
			_skill_detail_surface().detail_actions_scroll_limit_elapsed = 0.0
			_skill_detail_surface()._sync_detail_actions_scroll_limit()
	_skill_detail_surface()._clamp_detail_actions_scroll_to_content()
	_fishing_ui_surface()._sync_fishing_detail_render_culling()
	_audio_director()._process_chain_proximity_audio(delta)
	var defer_fishing_scroll_tail_work := _fishing_ui_surface()._fishing_detail_can_defer_scroll_tail_work()
	if not defer_fishing_scroll_tail_work:
		_skill_detail_surface()._process_detail_jump_arrows(delta)
	_skill_swipe_activity_surface()._process_pending_swipe_preview_finalize()
	if not defer_fishing_scroll_tail_work:
		_skill_detail_surface()._maybe_repair_blank_detail_lazy_stack()
	_performance_runtime()._process_battery_governor()
	_fishing_ui_surface()._publish_web_fishing_perf_probe_state()
	if trace_process:
		var trace_total_us := Time.get_ticks_usec() - trace_start_usec
		if trace_total_us >= 2000:
			print("PROCESS_TRACE frame=%s screen=%s skill=%s total=%s prewarm=%s lazy=%s background=%s action=%s ui=%s rest=%s mounted=%s plan=%s cards=%s placeholders=%s" % [
				str(main_process_frame_index),
				current_screen,
				selected_skill_id,
				str(trace_total_us),
				str(trace_prewarm_us),
				str(trace_lazy_us),
				str(trace_background_us),
				str(trace_action_us),
				str(trace_ui_us),
				str(trace_total_us - trace_prewarm_us - trace_lazy_us - trace_background_us - trace_action_us - trace_ui_us),
				str(detail_lazy_mounted_count),
				str(_skill_detail_surface().detail_lazy_plan.size()),
				str(action_cards.size()),
				str(_skill_swipe_activity_surface()._skill_detail_has_visible_lazy_placeholders() if current_screen == "skill" else false)
			])

func _input(event: InputEvent) -> void:
	_input_routing_shell().input(event)

func _action_stop_hold() -> StopHoldCircle:
	var layer := get_node_or_null("ActionStopHoldLayer") as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = "ActionStopHoldLayer"
		layer.layer = 140
		add_child(layer)
	var circle := layer.get_node_or_null("ActionStopHoldCircle") as StopHoldCircle
	if circle == null:
		circle = StopHoldCircle.new()
		circle.name = "ActionStopHoldCircle"
		circle.setup(self)
		layer.add_child(circle)
	else:
		circle.setup(self)
	return circle

func _notification(what: int) -> void:
	_app_lifecycle_runtime().handle_notification(what)

func _exit_tree() -> void:
	_app_lifecycle_runtime()._prepare_for_shutdown()

func _build_ui_boot_async():
	var boot_warmup := _boot_warmup_runtime()
	await boot_warmup._boot_progress_step("Building screen...", 0.34)
	_navigation_shell()._build_ui_shell()
	await boot_warmup._boot_progress_step("Loading skill page...", 0.42)
	_build_skills_page()
	await boot_warmup._boot_progress_step("Loading navigation...", 0.50)
	_navigation_shell()._build_nav_bar()
	_navigation_shell()._build_module_utility_row()
	_navigation_shell()._prebuild_skill_menu_page_cache()
	await boot_warmup._boot_progress_step("Preparing popups...", 0.56)
	_achievement_toast_surface().ensure_built()
	if _onboarding_runtime().tutorial_active:
		_tutorial_overlay_surface().ensure_built()
		_tutorial_overlay_surface()._update_tutorial_overlay()
	await boot_warmup._boot_progress_step("Starting systems...", 0.60)
	await boot_warmup._boot_progress_step("Mounting skill view...", 0.62)
	await boot_warmup._boot_progress_step("Preparing first frame...", 0.64)
	await boot_warmup._boot_progress_step("Almost ready...", 0.66)

func _online_runtime() -> OnlineRuntime:
	if online_runtime == null or not is_instance_valid(online_runtime):
		online_runtime = OnlineRuntime.new()
		online_runtime.name = "OnlineRuntime"
		online_runtime.setup(self)
		add_child(online_runtime)
	return online_runtime

func _build_skills_page() -> void:
	skills_content = Control.new()
	skills_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	skills_content.offset_top = SKILLS_PAGE_TOP_PAD
	skills_content.offset_bottom = 0
	skills_page.add_child(skills_content)

func _skill_content_width() -> float:
	return BASE_CANVAS.x - PAGE_PAD * 2.0

func _skill_swipe_frame_content_width(skill_id: String = "") -> float:
	if skill_id.is_empty():
		skill_id = selected_skill_id
	return _skill_content_width()

func _skill_column_host_width() -> float:
	if skills_content != null and is_instance_valid(skills_content) and skills_content.size.x > 1.0:
		return skills_content.size.x
	return _current_canvas_size().x

func _add_centered_skill_column(control: Control, drag_x: float = 0.0) -> void:
	var content_width := _skill_content_width()
	_skill_swipe_activity_surface()._apply_skill_column_layout(control, content_width, drag_x)
	skills_content.add_child(control)

func _suppress_detail_auto_scroll_for_first_module() -> bool:
	if not _skill_detail_surface().onboarding_first_module_center_active():
		return false
	if _skill_detail_surface().detail_actions_scroll != null and is_instance_valid(_skill_detail_surface().detail_actions_scroll):
		_skill_detail_surface().detail_actions_scroll.drag_scroll_position = 0.0
		_skill_detail_surface().detail_actions_scroll.scroll_vertical = 0
	return true

func _on_detail_actions_user_scroll_direction(direction: int) -> void:
	if current_screen != "skill":
		return
	if _action_stop_hold().active():
		_action_stop_hold().cancel_action()
	_audio_director()._focus_chain_scroll(direction)
	if _skill_detail_surface()._detail_unlock_scroll_spacer_height(selected_skill_id) > 1.0:
		_skill_detail_surface().detail_unlock_auto_scroll_interrupted = true
		if _skill_detail_surface().detail_unlock_scroll_spacer_tween != null and _skill_detail_surface().detail_unlock_scroll_spacer_tween.is_valid():
			_skill_detail_surface().detail_unlock_scroll_spacer_tween.kill()
			_skill_detail_surface().detail_unlock_scroll_spacer_tween = null
	if direction < 0:
		_skill_detail_surface()._release_detail_unlock_extra_scroll_space()
	_skill_detail_surface()._reveal_detail_jump_arrow(direction)
	_skill_detail_surface()._sync_detail_lazy_visible_cards(true, _skill_detail_surface().DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME)

func _update_ui(delta: float, instant := false) -> void:
	var static_refresh := _performance_runtime()._consume_ui_static_refresh(delta, instant)
	_navigation_shell()._sync_bottom_nav_visibility()
	_navigation_shell()._sync_module_utility_row_visibility()
	if static_refresh and current_screen == "skill":
		_skill_detail_surface()._refresh_mounted_tier_banners()
	_skill_swipe_activity_surface()._sync_queue_selection_banner()
	var skill_frame_refresh := instant or static_refresh or _performance_runtime()._skill_detail_needs_high_frequency_ui_update()
	var header_gauge_frame_refresh := skill_frame_refresh or _skill_detail_surface()._visible_detail_regen_gauge_needs_header_refresh()
	var detail_header_gauge_refresh := _skill_detail_surface()._consume_detail_header_gauge_refresh(delta, instant, static_refresh, header_gauge_frame_refresh)
	var passive_card_progress_refresh := _skill_detail_surface()._consume_passive_card_progress_refresh(delta, instant, static_refresh, skill_frame_refresh)
	_skill_swipe_activity_surface()._sync_action_art_animations_for_running_state(instant or static_refresh)
	if static_refresh and not boot_detail_render_in_progress and not _navigation_shell().screen_render_in_progress and _skill_detail_surface()._skill_detail_needs_action_list_refresh():
		var refresh_restore_scroll := _skill_detail_surface().detail_actions_scroll.scroll_vertical if _skill_detail_surface().detail_actions_scroll != null else -1
		_skill_detail_surface().call_deferred("_refresh_visible_skill_detail_action_list", refresh_restore_scroll, selected_skill_id)
	if static_refresh and _onboarding_runtime()._skill_detail_shows_tutorial_tips():
		_tutorial_overlay_surface()._show_lock_click_tip_note_if_needed()
		_onboarding_runtime()._resume_onboarding_stamina_mastery_sequence_if_needed()
	if static_refresh and current_screen == "achievements":
		_achievement_overlay_surface()._update_achievements_ui(delta, instant)
	if current_screen == "menu":
		_navigation_shell()._sync_skill_menu_page(delta, instant, static_refresh)
	if current_screen == "skill":
		if static_refresh and _onboarding_runtime()._onboarding_fight_header_sequence_active():
			_tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
			_tutorial_overlay_surface()._apply_onboarding_fight_action_stats_visibility_all()
		if static_refresh and selected_skill_id == TUTORIAL_STARTER_SKILL_ID and _onboarding_runtime()._onboarding_path_active():
			_onboarding_runtime()._maybe_trigger_onboarding_swipe_tip_at_zero_stamina(TUTORIAL_STARTER_SKILL_ID)
			if _onboarding_runtime()._onboarding_swipe_tip_sequence_resumable() and not _onboarding_runtime().onboarding_swipe_tip_sequence_running:
				_tutorial_overlay_surface().call_deferred("_run_onboarding_swipe_tip_sequence")
		if skill_frame_refresh:
			_tutorial_overlay_surface().sync_onboarding_overlay_tips()
			_onboarding_runtime()._maybe_trigger_onboarding_header_reveal_from_progress()
			_tutorial_overlay_surface()._sync_activity_start_highlight_position()
		_skill_detail_surface()._update_detail_header_gauges(static_refresh, skill_frame_refresh, detail_header_gauge_refresh, delta, instant)
		if skill_frame_refresh:
			_skill_detail_surface()._update_skill_detail_shadow(delta, instant)
		if _skill_swipe_activity_surface()._skill_swipe_previews_need_frame_updates():
			_skill_swipe_activity_surface()._update_skill_swipe_preview_states(delta, instant)
	if (current_screen == "pinned" or current_screen == "queue") and (skill_frame_refresh or static_refresh or instant):
		_navigation_shell()._sync_pinned_active_shelf(delta, instant)
		_skill_detail_surface()._update_skill_detail_shadow(delta, instant)
	if static_refresh or instant:
		_skill_swipe_activity_surface()._sync_queue_overlays_for_visible_cards()
	if not _skill_swipe_activity_surface()._refresh_visible_action_cards(delta, instant, static_refresh, skill_frame_refresh, passive_card_progress_refresh):
		return
	if _activity_unlock_ceremony_surface().locked_preview_fade_play_pending:
		_activity_unlock_ceremony_surface().play_pending_locked_activity_preview_reveals()
	if static_refresh:
		_settings_surface()._refresh_audio_volume_controls()
	if static_refresh:
		_shop_surface().sync_bonus_display()
	_settings_surface()._expire_reset_data_confirm_if_needed()
	if static_refresh:
		_tutorial_overlay_surface()._sync_tutorial_target_indicator()

func _stamina_gauge_event_hits_auto_eat_toggle(event: InputEvent) -> bool:
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		event_position = _input_routing_shell()._global_event_position(mouse_event.position, mouse_event.global_position, self)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = _input_routing_shell()._global_event_position(touch_event.position, touch_event.position, self)
	else:
		return false
	for node in get_tree().get_nodes_in_group("auto_eat_fish_toggle"):
		var button := node as TextureButton
		if button == null or not is_instance_valid(button) or not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		if button.get_global_rect().grow(8.0).has_point(event_position):
			return true
	return false

func _consume_skill_menu_gauge_parent_suppression(skill_id: String) -> bool:
	if not skill_cards.has(skill_id):
		return false
	var card := skill_cards.get(skill_id, {}) as Dictionary
	var button := card.get("button") as BaseButton
	if not button_press_runtime._button_has_active_stamina_gauge_parent_suppression(button):
		return false
	button.remove_meta("stamina_gauge_suppress_parent_until_msec")
	return true

func _play_staggered_eaten_fish_icons(skill_id: String, target_id: int, fish_count: int) -> void:
	var safe_count := clampi(fish_count, 0, 24)
	for i in range(safe_count):
		var target := _app_lifecycle_runtime().valid_control_ref(instance_from_id(target_id))
		if target == null:
			target = _reward_feedback_surface()._visible_stamina_gauge_for_skill(skill_id)
		_fishing_ui_surface()._float_eaten_fish_icon(skill_id, target)
		_audio_director()._play_fish_eat_blip()
		if i < safe_count - 1:
			await get_tree().create_timer(0.055).timeout

func _apply_empty_button_style(button: Button) -> void:
	ThemeStyles.apply_empty_button_style(button)

func _request_current_skill_detail_unlock_refresh(skill_id: String) -> void:
	if current_screen != "skill" or skill_id != selected_skill_id:
		return
	_activity_unlock_ceremony_surface().detail_refresh_done = false
	call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")

func _refresh_skill_detail_after_activity_unlock_ceremony() -> void:
	_activity_unlock_ceremony_surface().refresh_skill_detail_after_ceremony()

func _skill_index(skill_id: String) -> int:
	for i in range(skill_defs.size()):
		if str(skill_defs[i]["id"]) == skill_id:
			return i
	return -1

func _fit_scale_to_canvas(base_size: Vector2, margin: Vector2) -> float:
	var canvas_size := _current_canvas_size()
	var available := Vector2(
		maxf(1.0, canvas_size.x - margin.x * 2.0),
		maxf(1.0, canvas_size.y - margin.y * 2.0)
	)
	return clampf(minf(available.x / base_size.x, available.y / base_size.y), 0.1, 1.0)

func _current_canvas_size() -> Vector2:
	var canvas_size := size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		var viewport := get_viewport()
		if viewport != null:
			canvas_size = viewport.get_visible_rect().size
	if canvas_size.x <= 1.0 or canvas_size.y <= 1.0:
		canvas_size = BASE_CANVAS
	return canvas_size

func _fishing_rework_active_for_skill(skill_id: String) -> bool:
	return FISHING_REWORK_ENABLED and skill_id == "fishing"

func _mark_save_dirty(reason := "") -> void:
	_save_runtime()._mark_save_dirty(reason)

func save_game() -> void:
	_save_runtime().save_game()

func _unix_now() -> int:
	return int(floor(Time.get_unix_time_from_system()))

func _restore_fishing_state_from_save(data: Dictionary) -> void:
	fishing_runtime.restore_auto_eat_fish_enabled_from_save(self, data)
	fishing_runtime.restore_from_save(
		data,
		FishingState.FISHING_NET_HAUL_THRESHOLD,
		FishingState.FISHING_BOAT_HAUL_THRESHOLD,
		Callable(fishing_runtime, "tool_is_unlocked"),
		Callable(fishing_runtime, "area_metadata_loaded"),
		Callable(fishing_runtime, "location_id_valid").bind(FishingState.FISHING_LOCATION_DEFS)
	)

func _is_event_action(action: Dictionary) -> bool:
	if str(action.get("kind", "")) == "event_activity":
		return true
	var active_event = action.get("active_event", {})
	return typeof(active_event) == TYPE_DICTIONARY and not (active_event as Dictionary).is_empty()

func _action_data(skill_id: String, action_id: String) -> Dictionary:
	var cached = actions_by_key.get(_action_key(skill_id, action_id), null)
	if typeof(cached) == TYPE_DICTIONARY:
		return cached as Dictionary
	var active_event := _temporary_event_runtime()._active_event_action_data(skill_id, action_id)
	if not active_event.is_empty():
		return active_event
	return {}

func _action_key(skill_id: String, action_id: String) -> String:
	return "%s:%s" % [skill_id, ModuleUiRuntime.canonical_action_id(skill_id, action_id, FISHING_ACTION_ID_ALIASES)]

func _load_font() -> void:
	var fonts := ThemeStyles.load_app_fonts()
	app_font = fonts.get("font", null) as Font
	app_bold_font = fonts.get("bold_font", null) as Font

func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	return ThemeStyles.label(text, font_size, color, align, app_font, app_bold_font, dark_mode_enabled, COLOR_INK, COLOR_DARK_INK, COLOR_MUTED, COLOR_DARK_MUTED, COLOR_LINE, COLOR_DARK_LINE)

func _theme_paper_color() -> Color:
	return ThemeStyles.paper_color(dark_mode_enabled, COLOR_PAPER, COLOR_DARK_PAPER)

func _theme_surface_color(color: Color) -> Color:
	return ThemeStyles.surface_color(color, dark_mode_enabled, COLOR_PAPER, COLOR_DARK_PAPER, COLOR_PANEL, COLOR_DARK_PANEL, COLOR_LINE, COLOR_DARK_LINE, COLOR_DARK_PANEL_ALT)

func _theme_outline_color(outline_color: Color, fill_color: Color) -> Color:
	return ThemeStyles.outline_color(outline_color, fill_color, dark_mode_enabled, COLOR_INK, COLOR_DARK_LINE, COLOR_PAPER, COLOR_DARK_PAPER, COLOR_PANEL, COLOR_DARK_PANEL, COLOR_LINE, COLOR_DARK_PANEL_ALT)

func _menu_button(text: String) -> Button:
	return ThemeStyles.menu_button(text, app_font, app_bold_font, COLOR_INK, COLOR_BLUE, Color("#b9b3a8"), DEFAULT_BUTTON_TEXT_OUTLINE_SIZE, Callable(self, "_paper_button_style"), Callable(button_press_runtime, "attach_button_depress_animation"))

func _paper_button_style(color: Color, radius: int, margin := 72, pressed := false, disabled := false) -> StyleBoxTexture:
	return PaperButtonStyles.paper_button_style_with_shape(color, radius, margin, pressed, disabled, COLOR_INK, 5.5, paper_button_style_textures, dark_mode_enabled, PAPER_BUTTON_OUTLINE_WIDTH, Callable(self, "_theme_surface_color"), Callable(self, "_theme_outline_color"), Callable(visual_texture_cache, "_can_create_image_textures"), Callable(visual_texture_cache, "_create_image_texture"), Callable(visual_texture_cache, "_visual_fallback_texture"))

func _surface_style(color: Color, radius: int, margin := 28, elevated := false) -> StyleBoxFlat:
	return ThemeStyles.surface_style(color, radius, margin, elevated, dark_mode_enabled, PASSIVE_BORDER, COLOR_PAPER, COLOR_DARK_PAPER, COLOR_PANEL, COLOR_DARK_PANEL, COLOR_LINE, COLOR_DARK_LINE, COLOR_DARK_PANEL_ALT)

func _audio_director() -> AudioDirector:
	if audio_director == null or not is_instance_valid(audio_director):
		audio_director = AudioDirector.new()
		audio_director.name = "AudioDirector"
		audio_director.setup(self)
		add_child(audio_director)
	return audio_director

func _passive_modules_runtime() -> PassiveModulesRuntime:
	if passive_modules_runtime == null:
		passive_modules_runtime = PassiveModulesRuntime.new(self)
	return passive_modules_runtime

func _convergence_runtime() -> ConvergenceRuntime:
	if convergence_runtime == null:
		convergence_runtime = ConvergenceRuntime.new(self)
	return convergence_runtime

func _passive_firepit_surface() -> PassiveFirepitSurface:
	if passive_firepit_surface == null:
		passive_firepit_surface = PassiveFirepitSurface.new(self)
	return passive_firepit_surface

func _hub_runtime() -> HubRuntime:
	if hub_runtime == null:
		hub_runtime = HubRuntime.new(self)
	return hub_runtime

func _hub_surface() -> HubSurface:
	if hub_surface == null:
		hub_surface = HubSurface.new()
		hub_surface.name = "HubSurface"
		hub_surface.setup(self)
		add_child(hub_surface)
	return hub_surface

func _thieving_surface() -> ThievingSurface:
	if thieving_surface == null or not is_instance_valid(thieving_surface):
		thieving_surface = ThievingSurface.new()
		thieving_surface.name = "ThievingSurface"
		thieving_surface.setup(self)
		add_child(thieving_surface)
	return thieving_surface

func _save_runtime() -> SaveRuntime:
	if save_runtime == null:
		save_runtime = SaveRuntime.new(self)
	return save_runtime

func _activity_queue_runtime() -> ActivityQueueRuntime:
	if activity_queue_runtime == null:
		activity_queue_runtime = ActivityQueueRuntime.new(self)
	return activity_queue_runtime

func _action_runtime() -> ActionRuntime:
	if action_runtime == null:
		action_runtime = ActionRuntime.new(self)
	return action_runtime

func _activity_unlock_runtime() -> ActivityUnlockRuntime:
	if activity_unlock_runtime == null:
		activity_unlock_runtime = ActivityUnlockRuntime.new(self)
	return activity_unlock_runtime

func _activity_unlock_ceremony_surface() -> ActivityUnlockCeremonySurface:
	if activity_unlock_ceremony_surface == null:
		activity_unlock_ceremony_surface = ActivityUnlockCeremonySurface.new(self)
	return activity_unlock_ceremony_surface

func _onboarding_runtime() -> OnboardingRuntime:
	if onboarding_runtime == null:
		onboarding_runtime = OnboardingRuntime.new(self)
	return onboarding_runtime

func _fighting_runtime() -> FightingRuntime:
	if fighting_runtime == null:
		fighting_runtime = FightingRuntime.new(self)
	return fighting_runtime

func _test_state_runtime() -> TestStateRuntime:
	if test_state_runtime == null:
		test_state_runtime = TestStateRuntime.new(self)
	return test_state_runtime

func _boot_warmup_runtime() -> BootWarmupRuntime:
	if app_boot_warmup_runtime == null:
		app_boot_warmup_runtime = BootWarmupRuntime.new(self)
	return app_boot_warmup_runtime

func _temporary_event_runtime() -> TemporaryEventRuntime:
	if temporary_event_runtime == null:
		temporary_event_runtime = TemporaryEventRuntime.new(self)
	return temporary_event_runtime

func _crash_report_runtime() -> CrashReportRuntime:
	if crash_report_runtime == null:
		crash_report_runtime = CrashReportRuntime.new(self)
	return crash_report_runtime

func _ad_bonus_runtime() -> AdBonus:
	if ad_bonus_runtime == null:
		ad_bonus_runtime = AdBonus.new(self)
	return ad_bonus_runtime

func _app_lifecycle_runtime() -> AppLifecycleRuntime:
	if app_lifecycle_runtime == null:
		app_lifecycle_runtime = AppLifecycleRuntime.new(self)
	return app_lifecycle_runtime

func _performance_runtime() -> PerformanceRuntime:
	if performance_runtime == null:
		performance_runtime = PerformanceRuntime.new(self)
	return performance_runtime

func _profile_chat_overlay_surface() -> ProfileChatOverlaySurface:
	if profile_chat_overlay_surface == null:
		profile_chat_overlay_surface = ProfileChatOverlaySurface.new(self)
	return profile_chat_overlay_surface

func _achievement_overlay_surface() -> AchievementOverlaySurface:
	if achievement_overlay_surface == null:
		achievement_overlay_surface = AchievementOverlaySurface.new(self)
	return achievement_overlay_surface

func _tutorial_overlay_surface() -> TutorialOverlaySurface:
	if tutorial_overlay_surface == null:
		tutorial_overlay_surface = TutorialOverlaySurface.new(self)
	return tutorial_overlay_surface

func _achievement_toast_surface() -> AchievementToastSurface:
	if achievement_toast_surface == null:
		achievement_toast_surface = AchievementToastSurface.new(self)
	return achievement_toast_surface

func _material_collection_surface() -> MaterialCollectionSurface:
	if material_collection_surface == null:
		material_collection_surface = MaterialCollectionSurface.new(self)
	return material_collection_surface

func _reward_feedback_surface() -> RewardFeedbackSurface:
	if reward_feedback_surface == null:
		reward_feedback_surface = RewardFeedbackSurface.new(self)
	return reward_feedback_surface

func _temporary_event_surface() -> TemporaryEventSurface:
	if temporary_event_surface == null:
		temporary_event_surface = TemporaryEventSurface.new(self)
	return temporary_event_surface

func _settings_surface() -> SettingsSurface:
	if settings_surface == null:
		settings_surface = SettingsSurface.new(self)
	return settings_surface

func _shop_surface() -> ShopSurface:
	if shop_surface == null:
		shop_surface = ShopSurface.new(self)
	return shop_surface

func _fishing_ui_surface() -> FishingUiSurface:
	if fishing_ui_surface == null:
		fishing_ui_surface = FishingUiSurface.new(self)
	return fishing_ui_surface

func _skill_detail_surface() -> SkillDetailSurface:
	if skill_detail_surface == null:
		skill_detail_surface = SkillDetailSurface.new(self)
	return skill_detail_surface

func _navigation_shell() -> NavigationShell:
	if navigation_shell == null:
		navigation_shell = NavigationShell.new(self)
	return navigation_shell

func _input_routing_shell() -> InputRoutingShell:
	if input_routing_shell == null:
		input_routing_shell = InputRoutingShell.new(self)
	return input_routing_shell

func _skill_swipe_activity_surface() -> SkillSwipeActivitySurface:
	if skill_swipe_activity_surface == null:
		skill_swipe_activity_surface = SkillSwipeActivitySurface.new(self)
	return skill_swipe_activity_surface

func _clear(node: Node) -> void:
	_app_lifecycle_runtime()._clear_children(node)

func _clear_page_transient_input_state(clear_transition := false) -> void:
	button_press_runtime.release_all_depressed_buttons()
	_skill_swipe_activity_surface().release_all_depressed_activity_shell_buttons()
	_navigation_shell()._clear_page_switch_input_state(clear_transition)
	_hub_surface()._clear_hub_hotspot_hold()
	_settings_surface()._clear_active_audio_slider()
	_passive_firepit_surface()._clear_passive_button_press()
	_skill_swipe_activity_surface()._clear_skill_swipe_button_suppression()
	_fishing_ui_surface()._clear_active_fishing_method_button_press()
	_skill_detail_surface()._release_current_action_card_press_state()
	_action_stop_hold().cancel_action()
	_skill_detail_surface()._clear_detail_back_button_input_state()
	_skill_detail_surface()._clear_detail_jump_arrow_input_state()
	_input_routing_shell()._clear_activity_lock_input_state()
	_action_runtime()._release_current_stamina_gauge_press_state()
