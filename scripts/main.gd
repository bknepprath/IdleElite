extends Control

const FishingFluidStripClass = preload("res://scripts/fishing_fluid_strip.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const FishingUiSurface = preload("res://scripts/fishing/ui_surface.gd")
const ActivityQueueRuntime = preload("res://scripts/activity_queue/runtime.gd")
const ActivityDataCatalog = preload("res://scripts/activity_data/catalog.gd")
const AudioDirector = preload("res://scripts/audio/audio_director.gd")
const TipState = preload("res://scripts/tutorial/tip_state.gd")
const DetailTipState = preload("res://scripts/tutorial/tip_state.gd")
const OnboardingRuntime = preload("res://scripts/tutorial/onboarding_runtime.gd")
const ActivityLockNumber = preload("res://scripts/activity_lock_number.gd")
const ActivityLockRig = preload("res://scripts/activity_lock_rig.gd")
const ActivityLockCluster = preload("res://scripts/activity_lock_cluster.gd")
const AchievementPresentation = preload("res://scripts/achievements/presentation.gd")
const AchievementRewards = preload("res://scripts/achievements/rewards.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const AchievementStyles = preload("res://scripts/achievements/styles.gd")
const AdBonus = preload("res://scripts/monetization/ad_bonus.gd")
const MaterialRuntime = preload("res://scripts/materials/runtime.gd")
const FightingRuntime = preload("res://scripts/gameplay/fighting_runtime.gd")
const ActionRuntime = preload("res://scripts/gameplay/action_runtime.gd")
const ActivityUnlockRuntime = preload("res://scripts/gameplay/activity_unlock_runtime.gd")
const ConvergenceRuntime = preload("res://scripts/gameplay/convergence_runtime.gd")
const TestStateRuntime = preload("res://scripts/dev/test_state_runtime.gd")
const BootWarmupRuntime = preload("res://scripts/app/boot_warmup_runtime.gd")
const AppLifecycleRuntime = preload("res://scripts/app/lifecycle_runtime.gd")
const PerformanceRuntime = preload("res://scripts/app/performance_runtime.gd")
const HubRuntime = preload("res://scripts/gameplay/hub_runtime.gd")
const HubSurface = preload("res://scripts/ui/hub_surface.gd")
const PassiveModulesRuntime = preload("res://scripts/gameplay/passive_modules_runtime.gd")
const PassiveFirepitSurface = preload("res://scripts/ui/passive_firepit_surface.gd")
const InputRoutingShell = preload("res://scripts/ui/input_routing_shell.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const UpdateProcessShell = preload("res://scripts/ui/update_process_shell.gd")
const SkillDetailSurface = preload("res://scripts/ui/skill_detail_surface.gd")
const SkillSwipeActivitySurface = preload("res://scripts/ui/skill_swipe_activity_surface.gd")
const TutorialOverlaySurface = preload("res://scripts/ui/tutorial_overlay_surface.gd")
const AchievementToastSurface = preload("res://scripts/ui/achievement_toast_surface.gd")
const MaterialCollectionSurface = preload("res://scripts/ui/material_collection_surface.gd")
const RewardFeedbackSurface = preload("res://scripts/ui/reward_feedback_surface.gd")
const TemporaryEventSurface = preload("res://scripts/ui/temporary_event_surface.gd")
const SettingsSurface = preload("res://scripts/ui/settings_surface.gd")
const ShopSurface = preload("res://scripts/ui/shop_surface.gd")
const ChatState = preload("res://scripts/online/chat_state.gd")
const CrashReportRuntime = preload("res://scripts/diagnostics/crash_report_runtime.gd")
const OnlineRuntime = preload("res://scripts/online/online_runtime.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const VisualTextureCache = preload("res://scripts/core/visual_texture_cache.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const SaveStateFiles = preload("res://scripts/save_state/files.gd")
const SaveRuntime = preload("res://scripts/save_state/save_runtime.gd")
const TemporaryEventRuntime = preload("res://scripts/temporary_events/runtime.gd")
const ThievingState = preload("res://scripts/thieving/state.gd")
const ThievingSurface = preload("res://scripts/thieving/surface.gd")
const LeaderboardPresentation = preload("res://scripts/leaderboard/presentation.gd")
const LeaderboardState = preload("res://scripts/leaderboard/state.gd")
const FeatheredCollectGlow = preload("res://scripts/ui/feathered_collect_glow.gd")
const StopHoldCircle = preload("res://scripts/ui/stop_hold_circle.gd")
const RegenCircle = preload("res://scripts/ui/regen_circle.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const PageSwitchButtonFace = preload("res://scripts/ui/page_switch_button_face.gd")
const PrismConnectorOverlay = preload("res://scripts/ui/prism_connector_overlay.gd")
const PageSwitchChevronIcon = preload("res://scripts/ui/page_switch_chevron_icon.gd")
const BlueGuyHealthHeartGauge = preload("res://scripts/ui/blue_guy_health_heart_gauge.gd")
const CleanProgressBar = preload("res://scripts/ui/clean_progress_bar.gd")
const HubBuildProgressBar = preload("res://scripts/ui/hub_build_progress_bar.gd")
const PassiveSerpentineProgressBar = preload("res://scripts/ui/passive_serpentine_progress_bar.gd")
const ConvergenceMultiProgressBar = preload("res://scripts/ui/convergence_multi_progress_bar.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const FirepitFlameFx = preload("res://scripts/ui/firepit_flame_fx.gd")
const FirepitFuelRing = preload("res://scripts/ui/firepit_fuel_ring.gd")
const FirepitWarmthOverlay = preload("res://scripts/ui/firepit_warmth_overlay.gd")
const ActivityStartHighlightRing = preload("res://scripts/ui/activity_start_highlight_ring.gd")
const RoundedCornerCropOverlay = preload("res://scripts/ui/rounded_corner_crop_overlay.gd")
const OrganicLeaderboardBorder = preload("res://scripts/ui/organic_leaderboard_border.gd")
const ActivityCardInnerShadow = preload("res://scripts/ui/activity_card_inner_shadow.gd")
const SkillDetailPageShelfShadow = preload("res://scripts/ui/skill_detail_page_shelf_shadow.gd")
const SkillDetailGradientShelf = preload("res://scripts/ui/skill_detail_gradient_shelf.gd")
const SkillMenuPanelChrome = preload("res://scripts/ui/skill_menu_panel_chrome.gd")
const ButtonPressState = preload("res://scripts/ui/button_press_state.gd")
const ActivityCardBorder = preload("res://scripts/ui/activity_card_border.gd")
const PassiveModuleCardBorder = preload("res://scripts/ui/passive_module_card_border.gd")
const BuildableModuleOverlay = preload("res://scripts/ui/buildable_module_overlay.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const AchievementOverlaySurface = preload("res://scripts/ui/achievement_overlay_surface.gd")
const ConvergenceBuildOverlay = preload("res://scripts/ui/convergence_build_overlay.gd")
const ActionArtUi = preload("res://scripts/ui/action_art_ui.gd")
const PaperButtonStyles = preload("res://scripts/ui/paper_button_styles.gd")
const ActionArtTextureRect = preload("res://scripts/ui/action_art_texture_rect.gd")
const ActionArtAnimationRect = preload("res://scripts/ui/action_art_animation_rect.gd")
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ActivityCardDepth = preload("res://scripts/ui/activity_card_depth.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActivityProgressRail = preload("res://scripts/ui/activity_progress_rail.gd")
const DiamondArenaFrame = preload("res://scripts/ui/diamond_arena_frame.gd")
const RoosterPunchOutStage = preload("res://scripts/ui/rooster_punch_out_stage.gd")
const BlueGuyChickenBrawlStageClass = preload("res://scripts/ui/blue_guy_chicken_brawl_stage.gd")
const ThemeStyles = preload("res://scripts/ui/theme_styles.gd")
const ModuleActionCircleZone = preload("res://scripts/ui/module_action_circle_zone.gd")
const ModuleCollapseMinusGlyph = preload("res://scripts/ui/module_collapse_minus_glyph.gd")
const MedalSparkleStar = preload("res://scripts/ui/medal_sparkle_star.gd")
const MedalShineSlash = preload("res://scripts/ui/medal_shine_slash.gd")


const PAPER_BUTTON_OUTLINE_WIDTH := 9.0
const DEFAULT_BUTTON_TEXT_OUTLINE_SIZE := 24
const ACTION_CARD_TITLE_OUTLINE_SIZE := 34
const ACTION_CARD_FACE_BORDER_ENABLED := true
const ACTION_CARD_SIMPLE_BACKGROUND_ENABLED := false
const ACTION_CARD_FACE_RADIUS := 66.0
const ACTION_CARD_FACE_BORDER_Z_INDEX := 244
const PASSIVE_PROGRESS_BAR_Z_INDEX := ACTION_CARD_FACE_BORDER_Z_INDEX + 1
const STAMINA_GAUGE_PARENT_BUTTON_SUPPRESS_MSEC := 650
const TOP_LEVEL_NAV_DEBOUNCE_MSEC := 120
const UI_STATIC_REFRESH_INTERVAL_SECONDS := 0.50
const DETAIL_HEADER_GAUGE_REFRESH_SECONDS := 0.05
const PASSIVE_CARD_PROGRESS_REFRESH_SECONDS := 0.10
const DETAIL_ACTIONS_SCROLL_LIMIT_REFRESH_SECONDS := 0.10
const MASTERY_BAR_EASE_SECONDS := 0.16
const ACTIVITY_CRIT_OVERLAY_GROUP := "activity_crit_overlay"
const FISHING_COLLECTION_CANVAS_LAYER := 124

const SAVE_PATH := "user://idle_elite_save.json"
const SAVE_TEMP_PATH := "user://idle_elite_save.tmp.json"
const SAVE_BACKUP_PATH := "user://idle_elite_save.backup.json"
const SAVE_SCHEMA_VERSION := 1
const GUARANTEED_SUCCESS_ACTION_COMPLETIONS := 7
const GOD_MODE_TARGET_LEVEL := 99
const SKILL_XP_CURVE_BASE := SkillState.SKILL_XP_CURVE_BASE
const SKILL_XP_CURVE_EXPONENT := SkillState.SKILL_XP_CURVE_EXPONENT
const SKILL_XP_STRETCH_START_LEVEL := SkillState.SKILL_XP_STRETCH_START_LEVEL
const SKILL_XP_STRETCH_TARGET_LEVEL := SkillState.SKILL_XP_STRETCH_TARGET_LEVEL
const SKILL_XP_STRETCH_TARGET_MULTIPLIER := SkillState.SKILL_XP_STRETCH_TARGET_MULTIPLIER
const SKILL_XP_STRETCH_POWER := SkillState.SKILL_XP_STRETCH_POWER
const UNMARKED_MAXED_SAVE_COMPLETION_LIMIT := 5000
const DISCORD_INVITE_URL := "https://discord.com/invite/NHvsGdGfVW"
const PLAY_STORE_RATING_URL := "https://play.google.com/store/apps/details?id=com.idleelite.game"
const PLAY_STORE_RATING_ANDROID_URL := "market://details?id=com.idleelite.game"
const MAX_CRASH_REPORT_CLIPBOARD_CHARS := 1800
const AUTOSAVE_INTERVAL_SECONDS := 15.0
const TOTAL_LEVEL_BARGRAPH_TEXTURE := "res://assets/content/ui/total-level-bargraph.png"
const REWARDED_AD_ICON_TEXTURE := "res://assets/content/ui/rewarded-ad-icon.png"
const DISCORD_LOGO_ICON_TEXTURE := "res://assets/content/ui/discord-logo-icon.png"
const SETTINGS_GEAR_ICON_TEXTURE := "res://assets/content/ui/settings-gear-icon.png"
const SHOP_ICON_TEXTURE := "res://assets/content/ui/shop-icon.png"
const HERO_SPEECH_BUBBLE_TEXTURE := "res://assets/content/ui/hero-speech-bubble-down.png"
const PROGRESS_STAR_ICON_TEXTURE := "res://assets/content/ui/progress-star-icon.png"
const IDLE_ELITE_LOGO_TEXTURE := "res://assets/content/logo/idle-elite-logo-cutout.png"
const UNLOCK_LOCK_CHAINS_TEXTURE := "res://assets/content/ui/unlock-lock-chains.png"
const UNLOCK_CHAIN_LINK_TEXTURE := "res://assets/content/ui/unlock-chain-link.png"
const UNLOCK_CHAIN_LEFT_TEXTURE := "res://assets/content/ui/unlock-chain-left.png"
const UNLOCK_CHAIN_RIGHT_TEXTURE := "res://assets/content/ui/unlock-chain-right.png"
const UNLOCK_PADLOCK_TEXTURE := "res://assets/content/ui/unlock-padlock.png"
const UNLOCK_LOCK_BODY_TEXTURE := "res://assets/content/ui/unlock-lock-body.png"
const UNLOCK_LOCK_SHACKLE_CLOSED_TEXTURE := "res://assets/content/ui/unlock-lock-shackle-closed.png"
const UNLOCK_LOCK_SHACKLE_OPEN_TEXTURE := "res://assets/content/ui/unlock-lock-shackle-open.png"
const UNLOCK_LOCK_TINT_MASK_TEXTURE := "res://assets/content/ui/unlock-lock-tint-mask.png"
const UNLOCK_LOCK_PULSE_MASK_TEXTURE := "res://assets/content/ui/unlock-lock-pulse-mask.png"
const BUILD_REQUIRED_PLANK_PIECE_TEXTURES := [
	"res://assets/content/ui/build-required-wide-plank.png"
]
const LOG_CURRENCY_ICON_TEXTURE := "res://assets/content/icons/resources/log-currency.png"
const SCRAPWOOD_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/scrapwood.png"
const SOFTWOOD_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/softwood.png"
const HARDWOOD_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/hardwood.png"
const HONEY_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/honey.png"
const BERRIES_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/berries.png"
const MAT_COLLECTION_STONE_BACKGROUND_TEXTURE := "res://assets/content/ui/mats/mat-bg-stone.png"
const MAT_COLLECTION_WOOD_BACKGROUND_TEXTURE := "res://assets/content/ui/mats/mat-bg-wood.png"
const PLANK_ICON_TEXTURE := "res://assets/content/icons/resources/plank.png"
const UPGRADE_ARROW_ICON_TEXTURE := "res://assets/content/icons/upgrades/upgrade-arrow.png"
const SILVER_OPPORTUNITY_TIP_TEXT := "Silver medals unlock click opportunity windows.\nTap the activity while the progress bar is inside the window for a boost."
const HERO_UNLOCK_TOTAL_LEVEL := 25
const HERO_LOCKED_MESSAGE := "Total Lv 25 required!"
const HUB_UNLOCK_BUILD_LEVEL := 3
const HUB_LOCKED_MESSAGE := "Lv 3 Building required!"
const HUB_TUTORIAL_TITLE := "Player Hub"
const HUB_TUTORIAL_BODY := "Upgrade buildings here for bonuses across the whole game.\nTap a building to upgrade it.\nDrag a building to move it."
const SHOP_UNLOCK_BRONZE_MEDALS := 5
const SHOP_LOCKED_MESSAGE := "5 Bronze medals\nrequired!"
const HUB_NAV_LOCKED_MODULATE := Color("#3f3f3f")
const HUB_NAV_UNLOCK_FADE_SECONDS := 0.62
const PASSIVE_INFO_CLICK_AWAY_SECONDS := 2.0
const CONVERGENCE_BAR_HEIGHT := 156
const CONVERGENCE_BUILD_OVERLAY_COLOR := Color(0.10, 0.08, 0.06, 0.58)
const CONVERGENCE_UNBUILT_CARD_TINT := Color(0.78, 0.70, 0.58, 1.0)
const PLANK_BUILD_XP_MULT := 0.05
const MAT_COLLECTION_MODULE_SIZE := Vector2(754, 754)
const MAT_COLLECTION_MODULE_GAP := 28.0
const MAT_COLLECTION_AREA_HEIGHT := 870.0
const MAT_COLLECTION_CONNECTOR_HEIGHT := 74.0
const MAT_COLLECTION_CONNECTOR_TOP_OVERLAP := 3.0
const MAT_COLLECTION_APPEAR_SECONDS := 0.28
const MAT_COLLECTION_FLYER_ARC_SECONDS := 0.68
const BASE_MAX_STAMINA := SkillState.BASE_MAX_STAMINA
const STAMINA_REGEN_SECONDS := SkillState.STAMINA_REGEN_SECONDS
const BLUE_GUY_HEALTH_MAX := FightingRuntime.BLUE_GUY_HEALTH_MAX
const BLUE_GUY_HEALTH_REGEN_SECONDS := FightingRuntime.BLUE_GUY_HEALTH_REGEN_SECONDS
const HONEY_STAMINA_REGEN_MULT := 2.0
const HONEY_STAMINA_SECONDS_PER_CONSUMPTION := 10.0
const STAMINA_GAUGE_REGEN_BOOST_MULT := 3.0
const STAMINA_GAUGE_REGEN_EASE_SPEED := 7.5
const STAMINA_GAUGE_POP_SCALE := Vector2(1.018, 1.018)
const STAMINA_GAUGE_SETTLE_SCALE := Vector2(0.997, 0.997)
const STAMINA_GAUGE_HOLD_BOOST_SECONDS := 0.24
const MAX_OFFLINE_SECONDS := 8 * 60 * 60
const HUB_BUILD_SECONDS := HubRuntime.HUB_BUILD_SECONDS
const HUB_OFFLINE_SECONDS_PER_GARDEN_LEVEL := HubRuntime.HUB_OFFLINE_SECONDS_PER_GARDEN_LEVEL
const HUB_MODULE_MAX_LEVEL := HubRuntime.HUB_MODULE_MAX_LEVEL
const HUB_MODULE_DEFS := HubRuntime.HUB_MODULE_DEFS
const HUB_MODULE_ORDER := HubRuntime.HUB_MODULE_ORDER
const HUB_POSITION_ORDER := HubRuntime.HUB_POSITION_ORDER
const HUB_BARN_FAILURE_GAP_FACTORS := HubRuntime.HUB_BARN_FAILURE_GAP_FACTORS
const HUB_POND_REGEN_BONUS_BY_LEVEL := HubRuntime.HUB_POND_REGEN_BONUS_BY_LEVEL
const HUB_BUILD_SMOKE_SHEET := HubSurface.HUB_BUILD_SMOKE_SHEET
const HUB_BUILD_SMOKE_FRAME_COUNT := HubSurface.HUB_BUILD_SMOKE_FRAME_COUNT
const HUB_SPEND_BURST_MIN_ICONS := HubSurface.HUB_SPEND_BURST_MIN_ICONS
const HUB_SPEND_BURST_MAX_ICONS := HubSurface.HUB_SPEND_BURST_MAX_ICONS
const HUB_SPEND_BURST_ICON_SIZE := HubSurface.HUB_SPEND_BURST_ICON_SIZE
const HUB_FIELD_SIZE := HubSurface.HUB_FIELD_SIZE
const HUB_MODULE_BOTTOM_DRAG_MARGIN := HubSurface.HUB_MODULE_BOTTOM_DRAG_MARGIN
const HUB_TROPHY_DEFAULT_CENTER := Vector2(1725, 1190)
const HUB_TROPHY_SUCCESS_BONUS_BY_TIER := [0.0, 0.01, 0.02, 0.03, 0.05]
const EVENT_HOURGLASS_BADGE := "res://assets/content/ui/event-hourglass-badge.png"
const MIN_MOBILE_BODY_FONT_SIZE := 52
const MIN_MOBILE_INFO_TITLE_FONT_SIZE := 60
const INFO_POPOVER_PREWARM_FRAMES := 2
const HUB_MISSION_SLOT_COUNT_BY_LEVEL := HubRuntime.HUB_MISSION_SLOT_COUNT_BY_LEVEL
const HUB_MISSION_STAMINA_REDUCTION_BY_LEVEL := HubRuntime.HUB_MISSION_STAMINA_REDUCTION_BY_LEVEL
const HUB_MISSION_XP_BONUS_BY_LEVEL := HubRuntime.HUB_MISSION_XP_BONUS_BY_LEVEL
const HUB_MISSION_TIME_REDUCTION_BY_LEVEL := HubRuntime.HUB_MISSION_TIME_REDUCTION_BY_LEVEL
const HUB_MISSION_COOLDOWN_SECONDS_BY_LEVEL := HubRuntime.HUB_MISSION_COOLDOWN_SECONDS_BY_LEVEL
const HUB_MISSION_REP_MIN_BY_LEVEL := HubRuntime.HUB_MISSION_REP_MIN_BY_LEVEL
const HUB_MISSION_REP_MAX_BY_LEVEL := HubRuntime.HUB_MISSION_REP_MAX_BY_LEVEL
const HUB_MISSION_BOARD_TEXTURE := HubSurface.HUB_MISSION_BOARD_TEXTURE
const HUB_MISSION_BOARD_ART_SIZE := HubSurface.HUB_MISSION_BOARD_ART_SIZE
const HUB_MISSION_BOARD_SIZE := HubSurface.HUB_MISSION_BOARD_SIZE
const HUB_MISSION_BOARD_BUTTON_Y := HubSurface.HUB_MISSION_BOARD_BUTTON_Y
const HUB_MISSION_BOARD_TARGET_Y := HubSurface.HUB_MISSION_BOARD_TARGET_Y
const HUB_MISSION_BOARD_OPEN_SECONDS := HubSurface.HUB_MISSION_BOARD_OPEN_SECONDS
const HUB_MISSION_BOARD_CLOSE_SECONDS := HubSurface.HUB_MISSION_BOARD_CLOSE_SECONDS
const MASTERY_MAX_LEVEL := 20
const ACTION_CARD_MEDAL_PRESS_KIND := "__medal__"
const MASTERY_MEDAL_NAMES := [
	"Bronze",
	"Silver",
	"Gold",
	"Platinum",
	"Sapphire",
	"Emerald",
	"Ruby",
	"Diamond",
	"Demonic",
	"Heavenly",
	"Elite Bronze",
	"Elite Silver",
	"Elite Gold",
	"Elite Platinum",
	"Elite Sapphire",
	"Elite Emerald",
	"Elite Ruby",
	"Elite Diamond",
	"Elite Demonic",
	"Elite Heavenly"
]
const MASTERY_MEDAL_ACCENTS := [
	Color("#b77938"),
	Color("#a9adb7"),
	Color("#f4bf35"),
	Color("#a7d6e8"),
	Color("#3aa0ff"),
	Color("#35d86d"),
	Color("#e84d4d"),
	Color("#8fdcff"),
	Color("#9b54ff"),
	Color("#fff2a8"),
	Color("#c06d2c"),
	Color("#b8bec8"),
	Color("#ffd32f"),
	Color("#f1ebe0"),
	Color("#1f82ff"),
	Color("#22cc58"),
	Color("#ff2430"),
	Color("#aeeeff"),
	Color("#8a2cff"),
	Color("#fff0b8")
]
const ACTION_CARD_MEDAL_TAP_SPARKLE_COUNTS := [
	0, # Bronze
	1, # Silver
	2, # Gold
	2, # Platinum
	3, # Sapphire
	3, # Emerald
	4, # Ruby
	4, # Diamond
	5, # Demonic
	5, # Heavenly
	6, # Elite Bronze
	6, # Elite Silver
	7, # Elite Gold
	7, # Elite Platinum
	8, # Elite Sapphire
	8, # Elite Emerald
	9, # Elite Ruby
	10, # Elite Diamond
	15, # Elite Demonic
	20 # Elite Heavenly
]
const ACTION_CARD_MEDAL_TAP_SPARKLE_PALETTES := [
	[Color("#d9852e"), Color("#ffb15c"), Color("#ffd08a")], # Bronze
	[Color("#f4f7ff"), Color("#d5dbe4"), Color("#a9adb7")], # Silver
	[Color("#fff4a8"), Color("#ffd34a"), Color("#ffffff")], # Gold
	[Color("#ffffff"), Color("#e8f7ff"), Color("#c6d6df")], # Platinum
	[Color("#88d8ff"), Color("#3aa0ff"), Color("#0f66ff")], # Sapphire
	[Color("#d2ffd9"), Color("#a9ffbc"), Color("#35d86d"), Color("#1fb655")], # Emerald
	[Color("#ff9aa4"), Color("#e84d4d"), Color("#ff2430")], # Ruby
	[Color("#ffffff"), Color("#bdf3ff"), Color("#8fdcff")], # Diamond
	[Color("#171615"), Color("#3a0507"), Color("#850d12"), Color("#e1121b")], # Demonic
	[Color("#ffffff"), Color("#fff0ba"), Color("#ffe37a")], # Heavenly
	[Color("#ffb15c"), Color("#ffcf92"), Color("#c06d2c"), Color("#fff0ba")], # Elite Bronze
	[Color("#ffffff"), Color("#dce4ef"), Color("#aeb9c8"), Color("#cfefff")], # Elite Silver
	[Color("#fff4a8"), Color("#ffd32f"), Color("#ffffff"), Color("#ffec66")], # Elite Gold
	[Color("#ffffff"), Color("#f1ebe0"), Color("#d9f7ff"), Color("#c5d7e6")], # Elite Platinum
	[Color("#7fd1ff"), Color("#1f82ff"), Color("#35e8ff"), Color("#005eff")], # Elite Sapphire
	[Color("#d2ffd9"), Color("#7dff9b"), Color("#22cc58"), Color("#00a83f")], # Elite Emerald
	[Color("#ff8a94"), Color("#ff2430"), Color("#ff4c6d"), Color("#e01928")], # Elite Ruby
	[Color("#ffffff"), Color("#aeeeff"), Color("#82e7ff"), Color("#d8a8ff")], # Elite Diamond
	[Color("#171615"), Color("#2a0204"), Color("#5a070b"), Color("#9f1017"), Color("#ff2430")], # Elite Demonic
	[Color("#ff3b3b"), Color("#ffd93d"), Color("#48ff6d"), Color("#36e6ff"), Color("#6f7bff"), Color("#ff6bff"), Color("#ff9f1c"), Color("#b8ff2c"), Color("#ff4fd8")] # Elite Heavenly
]
const ACTION_CARD_MEDAL_TAP_EXTRA_SHINE_STEPS := [
	{"level": 8, "delay": 0.30},
	{"level": 15, "delay": 0.52},
	{"level": 20, "delay": 0.72}
]
const GLOBAL_MEDAL_BUFFS := [
	{"level": 1, "stat": "max_stamina", "amount": 1.0},
	{"level": 2, "stat": "xp_mult", "amount": 0.02},
	{"level": 3, "stat": "speed_mult", "amount": 0.02},
	{"level": 4, "stat": "success_bonus", "amount": 1.0},
	{"level": 5, "stat": "max_stamina", "amount": 1.0},
	{"level": 6, "stat": "xp_mult", "amount": 0.03},
	{"level": 7, "stat": "speed_mult", "amount": 0.03},
	{"level": 8, "stat": "success_bonus", "amount": 1.0},
	{"level": 9, "stat": "max_stamina", "amount": 2.0},
	{"level": 10, "stat": "xp_mult", "amount": 0.05},
	{"level": 11, "stat": "max_stamina", "amount": 2.0},
	{"level": 12, "stat": "xp_mult", "amount": 0.05},
	{"level": 13, "stat": "speed_mult", "amount": 0.04},
	{"level": 14, "stat": "success_bonus", "amount": 1.0},
	{"level": 15, "stat": "max_stamina", "amount": 2.0},
	{"level": 16, "stat": "xp_mult", "amount": 0.05},
	{"level": 17, "stat": "speed_mult", "amount": 0.04},
	{"level": 18, "stat": "success_bonus", "amount": 1.0},
	{"level": 19, "stat": "max_stamina", "amount": 3.0},
	{"level": 20, "stat": "xp_mult", "amount": 0.08}
]
const BASE_CANVAS := Vector2(2160, 3840)
const BOTTOM_NAV_HEIGHT := 420
const BOTTOM_NAV_SAFE_PAD := 96
const MODULE_UTILITY_ROW_HEIGHT := 344
const MODULE_UTILITY_ROW_GAP := 28
const MODULE_UTILITY_BUTTON_SIZE := Vector2(390, 289)
const MODULE_UTILITY_COLLAPSE_TOGGLE_SIZE := Vector2(146, 146)
const MODULE_UTILITY_BUTTONS_SLIDE_PIXELS := 156.0
const MODULE_UTILITY_BUTTONS_ENTER_SECONDS := 0.26
const MODULE_UTILITY_BUTTONS_EXIT_SECONDS := 0.18
const MODULE_UTILITY_BUTTONS_STAGGER_STEP := 0.16
const MODULE_UTILITY_BUTTONS_STAGGER_MIN_SCALE := 0.86
const MODULE_SORT_MENU_UNWRAP_SECONDS := 0.24
const MODULE_SORT_MENU_WRAP_SECONDS := 0.16
const MODULE_SORT_MENU_COLLAPSED_SCALE_Y := 0.14
const SKILL_DETAIL_BOTTOM_UI_CLEARANCE := 340
const TUTORIAL_PANEL_BOTTOM_GAP := 42
const TUTORIAL_PANEL_BODY_HEIGHT := 520
const SKILLS_PAGE_TOP_PAD := 96
const PAGE_PAD := 96
const CARD_RADIUS := 64
const ACTION_CARD_HEIGHT := 720
const COMBAT_DIAMOND_ARENA_CARD_HEIGHT := 1220
const ACTION_CARD_EXPANDED_HEIGHT := 1080
const THIEVING_HEIST_CARD_HEIGHT := 880
const ACTION_CARD_INFO_EXPAND_SECONDS := 0.22
const ACTION_CARD_INFO_FADE_IN_SECONDS := 0.08
const ACTION_CARD_INFO_FADE_OUT_SECONDS := 0.12
const FISHING_BACKGROUND_CROP_LEFT := 0.06
const FISHING_BACKGROUND_CROP_TOP := 0.06
const FISHING_BACKGROUND_CROP_RIGHT := 0.015
const FISHING_REWORK_ENABLED := true
const FISHING_FLUID_STRIP_HEIGHT := 88.0
const FISHING_FLUID_STRIP_BOTTOM_INSET := 0.0
const FISHING_FLUID_STRIP_Z_INDEX := 205
const FISHING_MODULE_TITLE_Z_INDEX := 500
const FISHING_METHOD_PADLOCK_SIZE := Vector2(336, 368)
const FISHING_METHOD_PADLOCK_LEVEL_SIZE := Vector2(150, 130)
const FISHING_METHOD_PADLOCK_LEVEL_FONT := 128
const FISHING_METHOD_PADLOCK_LEVEL_OUTLINE := 14
const FISHING_METHOD_TITLE_OUTLINE := 20
const FISHING_MODULE_TITLE_FONT_SIZE := 82
const FISHING_MODULE_TITLE_OUTLINE := 34
const FISHING_MODULE_TITLE_TOP := 18
const FISHING_MODULE_TITLE_BAND_HEIGHT := 106
const FISHING_MODULE_TITLE_LEFT_INSET := 54.0
const FISHING_MODULE_TITLE_RIGHT_INSET := 104.0
const FISHING_EQUIPMENT_OFFER_TITLE_SIDE_INSET := 88.0
const FISHING_AREA_STAT_FADE_SECONDS := 0.22
const FISHING_AREA_MAX_BUTTONS_PER_MODULE := 2
const FISHING_AREA_CONTENT_TOP_MARGIN := FISHING_MODULE_TITLE_TOP
const FISHING_AREA_WATER_BOTTOM_MARGIN := 70
const FISHING_AREA_STAT_COLUMN_TOP_MARGIN := FISHING_MODULE_TITLE_TOP + FISHING_MODULE_TITLE_BAND_HEIGHT
const FISHING_AREA_STAT_STACK_TOP := FISHING_AREA_STAT_COLUMN_TOP_MARGIN
const FISHING_AREA_METHOD_TOP_MARGIN := 0
const FISHING_ACTIVE_TOOL_VISUAL_LANE_WIDTH := 350.0
const FISHING_ACTIVE_TOOL_LAYER_SIZE := Vector2(820, 430)
const FISHING_ACTIVE_TOOL_LAYER_RIGHT_OFFSET := -470.0
const FISHING_ACTIVE_TOOL_LAYER_TOP := 250.0
const FISHING_ACTIVE_TOOL_ICON_SIZE := Vector2(319, 319)
const FISHING_ACTIVE_NET_ICON_SIZE := Vector2(437, 437)
const FISHING_ACTIVE_TOOL_FLOAT_Y := 26.0
const FISHING_ACTIVE_TOOL_DIP_Y := 222.0
const FISHING_ACTIVE_TOOL_HARVEST_Y := 166.0
const FISHING_ACTIVE_TOOL_INIT_SECONDS := 0.46
const FISHING_ACTIVE_TOOL_Z_INDEX := FISHING_FLUID_STRIP_Z_INDEX - 1
const FISHING_METHOD_ACTIVE_SWAY_SPEED := 1.18
const FISHING_METHOD_ACTIVE_SWAY_OFFSET := Vector2(4.2, 3.4)
const FISHING_METHOD_ACTIVE_SWAY_ROTATION := 0.026
const FISHING_METHOD_ACTIVE_SWAY_SCALE_PULSE := 0.042
const FISHING_METHOD_ACTIVE_SWAY_RETURN_SECONDS := 0.2
const FISHING_LOCATION_ACTIVE_CAMERA_ZOOM := 2.35
const FISHING_LOCATION_ACTIVE_CAMERA_PAN := Vector2(92.0, 74.0)
const FISHING_LOCATION_ACTIVE_CAMERA_EASE := 1.45
const FISHING_LOCATION_ACTIVE_CAMERA_RETURN_SECONDS := 0.18
const FISHING_PADLOCK_UNLOCK_DROP_SECONDS := 0.96
const FISHING_PADLOCK_UNLOCK_POP_SECONDS := 0.30
const FISH_CURRENCY_ICON_TEXTURE := "res://assets/content/icons/resources/fish-currency-icon.png"
const FISHING_LOCATION_TILE_SIZE := Vector2(410, 410)
const FISHING_NET_OFFER_UNLOCK_LEVEL := 3
const FISHING_NET_OFFER_HEIGHT := 740
const FISHING_NET_TOOL_ID := "net"
const FISHING_OFFER_UNAVAILABLE_ART_MODULATE := Color(1, 1, 1, 0.52)
const FISHING_ROD_OFFER_UNLOCK_LEVEL := 18
const FISHING_ROD_OFFER_COST := 1000
const FISHING_ROD_OFFER_HEIGHT := 740
const FISHING_ROD_UPGRADE_OFFER_HEIGHT := 740
const FISHING_REINFORCED_ROD_UNLOCK_LEVEL := 45
const FISHING_REINFORCED_ROD_COST := 50000
const FISHING_STAR_ROD_UNLOCK_LEVEL := 85
const FISHING_STAR_ROD_COST := 250000
const FISHING_BOAT_OFFER_UNLOCK_LEVEL := 50
const FISHING_BOAT_BUILD_REQUIRED_LEVEL := 30
const FISHING_BOAT_OFFER_COST := 1000
const FISHING_BOAT_OFFER_HEIGHT := 740
const FISHING_MIRROR_OFFER_UNLOCK_LEVEL := 90
const FISHING_MIRROR_OFFER_COST := 1000000
const FISHING_MIRROR_OFFER_HEIGHT := 740
const FISHING_NET_HAUL_THRESHOLD := 10
const FISHING_NET_HAUL_VISUAL_SECONDS := 0.74
const FISHING_NET_COLLECT_LAYOUT_DELAY_SECONDS := 3.62
const FISHING_BOAT_HAUL_THRESHOLD := 200
const FISHING_BOAT_HAUL_VISUAL_SECONDS := 0.55
const FISHING_ROD_HAUL_VISUAL_SECONDS := 0.48
const FISHING_TOOL_DEFS := [
	{"id": "hands", "name": "Bare hands", "archetype": "novice", "unlock": "starter", "art": "res://assets/content/fishing/tools/tool-bare-hands.png"},
	{"id": "net", "name": "Drag net", "archetype": "volume", "unlock": "Fishing Lv 3", "art": "res://assets/content/fishing/tools/net-player.png"},
	{"id": "line", "name": "Bamboo rod", "archetype": "steady", "unlock": "Fishing Lv 14", "art": "res://assets/content/fishing/tools/tool-bamboo-rod.png"},
	{"id": "reinforced_rod", "name": "Reinforced rod", "archetype": "steady", "unlock": "Fishing Lv 45", "art": "res://assets/content/fishing/tools/tool-bamboo-rod.png"},
	{"id": "star_rod", "name": "Star rod", "archetype": "steady", "unlock": "Fishing Lv 85", "art": "res://assets/content/fishing/tools/tool-bamboo-rod.png"},
	{"id": "boat", "name": "Boat", "archetype": "steady", "unlock": "Building at Fishing Lv 50", "art": "res://assets/content/fishing/tools/tool-boat.png"},
	{"id": "mirror", "name": "Reflection mirror", "archetype": "risk", "unlock": "Space Reflection", "art": "res://assets/content/fishing/tools/reflection-net.png"},
]
const FISHING_LOCATION_THUMBNAIL_SHEET := "res://assets/content/fishing/locations/fishing-location-thumbnails-sheet.png"
const FISHING_LOCATION_DEFS := {
	"beach": [
		{"id": "shallows", "name": "Shallows", "unlock": 1, "fish": "Minnow", "bg": "res://assets/content/fishing/backgrounds/00-tide-pool-shallows.png"},
		{"id": "rocky", "name": "Rocks", "unlock": 4, "fish": "Crab", "bg": "res://assets/content/fishing/backgrounds/03-crab-pier.png"},
	],
	"pier": [
		{"id": "dock-cup", "name": "Dock Edge", "unlock": 7, "fish": "Minnow", "bg": "res://assets/content/fishing/backgrounds/01-pond-dock.png"},
		{"id": "piling-line", "name": "Piling Line", "unlock": 11, "fish": "Panfish", "bg": "res://assets/content/fishing/backgrounds/01-pond-dock.png"},
	],
	"river": [
		{"id": "bend", "name": "River Bend", "unlock": 14, "fish": "Trout", "bg": "res://assets/content/fishing/backgrounds/02-river-bend.png"},
		{"id": "rapids", "name": "Rapids", "unlock": 18, "fish": "Salmon", "bg": "res://assets/content/fishing/backgrounds/02-river-bend.png"},
	],
	"sewers": [
		{"id": "drain-gate", "name": "Drain Gate", "unlock": 22, "fish": "Eel", "bg": "res://assets/content/fishing/backgrounds/sewer-pipe-outlet.png"},
		{"id": "tunnel-pool", "name": "Tunnel Pool", "unlock": 26, "fish": "Eel", "bg": "res://assets/content/fishing/backgrounds/sewer-pipe-outlet.png"},
	],
	"winter_lake": [
		{"id": "ice-hole", "name": "Ice Hole", "unlock": 34, "fish": "Snowfish", "bg": "res://assets/content/fishing/backgrounds/04-frozen-lake.png"},
	],
	"reef": [
		{"id": "pot", "name": "Reef Pot", "unlock": 30, "fish": "Crab", "bg": "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"},
		{"id": "cage", "name": "Reef Cage", "unlock": 46, "fish": "Lobster", "bg": "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"},
		{"id": "night-reef", "name": "Night Reef", "unlock": 58, "fish": "Reef Fish", "bg": "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"},
		{"id": "pearl-bed", "name": "Pearl Bed", "unlock": 74, "fish": "Pearl Oyster", "bg": "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"},
	],
	"sea": [
		{"id": "rowboat", "name": "Rowboat", "unlock": 50, "fish": "Bass", "bg": "res://assets/content/fishing/backgrounds/07-rowboat-offshore.png"},
		{"id": "open-water", "name": "Open Water", "unlock": 52, "fish": "Tuna", "bg": "res://assets/content/fishing/backgrounds/07-rowboat-offshore.png"},
		{"id": "chum-line", "name": "Chum Line", "unlock": 70, "fish": "Reef Fish", "bg": "res://assets/content/fishing/backgrounds/07-rowboat-offshore.png"},
	],
	"stormy_sea": [
		{"id": "ripple", "name": "Storm Ripple", "unlock": 64, "fish": "Shark", "bg": "res://assets/content/fishing/backgrounds/10-storm-ocean.png"},
		{"id": "storm-line", "name": "Storm Line", "unlock": 78, "fish": "Storm Ray", "bg": "res://assets/content/fishing/backgrounds/10-storm-ocean.png"},
	],
	"deep_sea": [
		{"id": "wreck-drop", "name": "Wreck Drop", "unlock": 82, "fish": "Octopus", "bg": "res://assets/content/fishing/backgrounds/09-deep-sea-abyss.png"},
		{"id": "abyss", "name": "Abyss", "unlock": 86, "fish": "Shark", "bg": "res://assets/content/fishing/backgrounds/09-deep-sea-abyss.png"},
		{"id": "trench", "name": "Deep Trench", "unlock": 88, "fish": "Octopus", "bg": "res://assets/content/fishing/backgrounds/09-deep-sea-abyss.png"},
	],
	"space": [
		{"id": "starlight", "name": "Starlight", "unlock": 90, "fish": "Cosmic Starfish", "bg": "res://assets/content/fishing/backgrounds/11-cosmic-dream-sea.png"},
		{"id": "reflection", "name": "Reflection", "unlock": 95, "fish": "Cosmic Starfish", "bg": "res://assets/content/fishing/backgrounds/11-cosmic-dream-sea.png"},
	],
}
const FISHING_TOOL_LOCATION_ACTIONS := {
	"hands": {
		"beach.shallows": "beach-shallows",
		"beach.rocky": "beach-rocks",
		"pier.dock-cup": "pier-dock-edge",
		"pier.piling-line": "pier-piling-line",
		"river.bend": "river-bend",
		"river.rapids": "river-rapids",
		"sewers.drain-gate": "sewers-drain-gate",
		"sewers.tunnel-pool": "sewers-tunnel-pool",
		"winter_lake.ice-hole": "winter-lake-ice-hole",
		"reef.pot": "reef-pot",
		"reef.cage": "reef-cage",
		"reef.night-reef": "reef-night-reef",
		"reef.pearl-bed": "reef-pearl-bed",
		"sea.rowboat": "sea-rowboat",
		"sea.open-water": "sea-open-water",
		"sea.chum-line": "sea-chum-line",
		"stormy_sea.ripple": "stormy-sea-ripple",
		"stormy_sea.storm-line": "stormy-sea-storm-line",
		"deep_sea.wreck-drop": "deep-sea-wreck-drop",
		"deep_sea.abyss": "deep-sea-abyss",
		"deep_sea.trench": "deep-sea-trench",
		"space.starlight": "space-starlight",
		"space.reflection": "space-reflection",
	},
	"net": {
		"beach.shallows": "beach-shallows",
		"beach.rocky": "beach-rocks",
		"pier.dock-cup": "pier-dock-edge",
		"pier.piling-line": "pier-piling-line",
		"river.bend": "river-bend",
		"river.rapids": "river-rapids",
		"sewers.drain-gate": "sewers-drain-gate",
		"sewers.tunnel-pool": "sewers-tunnel-pool",
		"winter_lake.ice-hole": "winter-lake-ice-hole",
		"reef.pot": "reef-pot",
		"reef.cage": "reef-cage",
		"reef.night-reef": "reef-night-reef",
		"reef.pearl-bed": "reef-pearl-bed",
		"sea.rowboat": "sea-rowboat",
		"sea.open-water": "sea-open-water",
		"sea.chum-line": "sea-chum-line",
		"stormy_sea.ripple": "stormy-sea-ripple",
		"stormy_sea.storm-line": "stormy-sea-storm-line",
		"deep_sea.wreck-drop": "deep-sea-wreck-drop",
		"deep_sea.abyss": "deep-sea-abyss",
		"deep_sea.trench": "deep-sea-trench",
		"space.starlight": "space-starlight",
		"space.reflection": "space-reflection",
	},
	"line": {
		"beach.shallows": "beach-shallows",
		"beach.rocky": "beach-rocks",
		"pier.dock-cup": "pier-dock-edge",
		"pier.piling-line": "pier-piling-line",
		"river.bend": "river-bend",
		"river.rapids": "river-rapids",
		"sewers.drain-gate": "sewers-drain-gate",
		"sewers.tunnel-pool": "sewers-tunnel-pool",
		"winter_lake.ice-hole": "winter-lake-ice-hole",
		"reef.pot": "reef-pot",
		"reef.cage": "reef-cage",
		"reef.night-reef": "reef-night-reef",
		"reef.pearl-bed": "reef-pearl-bed",
		"sea.rowboat": "sea-rowboat",
		"sea.open-water": "sea-open-water",
		"sea.chum-line": "sea-chum-line",
		"stormy_sea.ripple": "stormy-sea-ripple",
		"stormy_sea.storm-line": "stormy-sea-storm-line",
		"deep_sea.wreck-drop": "deep-sea-wreck-drop",
		"deep_sea.abyss": "deep-sea-abyss",
		"deep_sea.trench": "deep-sea-trench",
		"space.starlight": "space-starlight",
		"space.reflection": "space-reflection",
	},
}
const ACTIVITY_PADLOCK_CLICK_SHAKE_SECONDS := 0.26
const PASSIVE_MODULE_CARD_HEIGHT := 940
const ACTION_CARD_POP_GUTTER := 44
const ACTION_CARD_3D_DEPTH_OFFSET := Vector2(28.0, 34.0)
const ACTION_CARD_3D_PRESS_OFFSET := Vector2(28.0, 34.0)
const ACTION_CARD_3D_PRESS_SECONDS := 0.098
const ACTION_CARD_3D_RELEASE_SECONDS := 0.14
const ACTION_CARD_3D_PRESS_FEEDBACK_DELAY_SECONDS := 0.075
const ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE := 18.0
const ACTION_CARD_TAP_RELEASE_SLOP := 120.0
const ACTION_STAT_TAP_RELEASE_SLOP := 30.0
const PASSIVE_BUTTON_TAP_RELEASE_SLOP := 52.0
const ACTION_CARD_DUPLICATE_TAP_MSEC := 36
const ACTION_STOP_HOLD_ARM_DELAY_SECONDS := 0.16
const ACTION_STOP_HOLD_SECONDS := 0.45
const ACTION_STOP_HOLD_UNLOAD_SECONDS := 0.18
const ACTION_STOP_HOLD_RING_SIZE := Vector2(380, 380)
const HUB_HOTSPOT_DRAG_START_SLOP := HubSurface.HUB_HOTSPOT_DRAG_START_SLOP
const HUB_TUTORIAL_TIP_FADE_SECONDS := HubSurface.HUB_TUTORIAL_TIP_FADE_SECONDS
const ACTION_OPPORTUNITY_MIN_MEDAL_LEVEL := 2
const ACTION_OPPORTUNITY_SILVER_WINDOW := Vector2(0.52, 0.73)
const ACTION_OPPORTUNITY_GOLD_MIN_MEDAL_LEVEL := 3
const ACTION_OPPORTUNITY_GOLD_WIDTH := 0.19
const ACTION_OPPORTUNITY_GOLD_SWAY := 0.028
const ACTION_OPPORTUNITY_GOLD_MOVE_SECONDS := 1.35
const ACTION_OPPORTUNITY_GOLD_PAUSE_SECONDS := 0.7
const ACTION_OPPORTUNITY_PLATINUM_MIN_MEDAL_LEVEL := 4
const ACTION_OPPORTUNITY_PLATINUM_WINDOW := Vector2(0.10, 0.50)
const ACTION_OPPORTUNITY_TRIPLE_CLICK_MAX_STACKS := 3
const ACTION_OPPORTUNITY_TRIPLE_CLICK_SPEED_PER_STACK := 0.12
const ACTION_OPPORTUNITY_SAPPHIRE_MIN_MEDAL_LEVEL := 5
const ACTION_OPPORTUNITY_SAPPHIRE_LEFT_STOP := 0.05
const ACTION_OPPORTUNITY_SAPPHIRE_SLIDE_SECONDS := 2.2
const ACTION_OPPORTUNITY_EMERALD_MIN_MEDAL_LEVEL := 6
const ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW := Vector2(0.30, 0.70)
const ACTION_OPPORTUNITY_EMERALD_MIN_WINDOW := Vector2(0.42, 0.58)
const ACTION_OPPORTUNITY_EMERALD_SHRINK_PER_SUCCESS := 0.015
const ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS := 0.42
const ACTION_OPPORTUNITY_RUBY_MIN_MEDAL_LEVEL := 7
const ACTION_OPPORTUNITY_RUBY_WINDOW_WIDTH := 0.26
const ACTION_OPPORTUNITY_RUBY_START_LEFT := 0.37
const ACTION_OPPORTUNITY_RUBY_STEP := 0.03
const ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS := 0.42
const ACTION_OPPORTUNITY_DIAMOND_MIN_MEDAL_LEVEL := 8
const ACTION_OPPORTUNITY_DIAMOND_WIDTH := 0.19
const ACTION_OPPORTUNITY_DIAMOND_SWAY := 0.052
const ACTION_OPPORTUNITY_DIAMOND_MOVE_SECONDS := ACTION_OPPORTUNITY_GOLD_MOVE_SECONDS * 0.8
const ACTION_OPPORTUNITY_DIAMOND_PAUSE_SECONDS := ACTION_OPPORTUNITY_GOLD_PAUSE_SECONDS * 0.8
const ACTION_OPPORTUNITY_DIRECT_PROGRESS := 0.025
const ACTION_OPPORTUNITY_BOOST_SECONDS := 1.25
const ACTION_OPPORTUNITY_BOOST_MULT := 1.65
const ACTION_OPPORTUNITY_REGEN_SECONDS := 3.0
const ACTION_OPPORTUNITY_REGEN_MULT := 2.5
const ACTION_OPPORTUNITY_DUPLICATE_TAP_MSEC := 90
const ACTION_OPPORTUNITY_FORGIVENESS_IDEAL_SECONDS := 0.48
const ACTION_OPPORTUNITY_FORGIVENESS_MIN_SECONDS := 0.18
const ACTION_OPPORTUNITY_FORGIVENESS_MAX_EXTRA_WIDTH := 1.05
const ACTION_OPPORTUNITY_MISS_EXPAND_PER_SIDE := 0.005
const ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS := 0.36
const ACTION_PROGRESS_SPEED_EASE := 4.8
const ACTION_CANCELED_PROGRESS_DECAY_PER_SECOND := 0.24
const THIEVING_HEIST_BACKGROUND_SHEET := ThievingState.HEIST_BACKGROUND_SHEET
const THIEVING_HEIST_TROPHY_SHEET := ThievingState.HEIST_TROPHY_SHEET
const THIEVING_HEIST_JAIL_BARS_TEXTURE := ThievingState.HEIST_JAIL_BARS_TEXTURE
const THIEVING_HEIST_BACKGROUND_CELL := ThievingState.HEIST_BACKGROUND_CELL
const THIEVING_HEIST_TROPHY_CELL := ThievingState.HEIST_TROPHY_CELL
const THIEVING_HEIST_HORIZONTAL_BLEED := 0.0
const THIEVING_HEIST_UI_SAFE_INSET := PAGE_PAD + 132.0
const THIEVING_HEIST_LEVEL_SUCCESS_BONUS := ThievingState.HEIST_LEVEL_SUCCESS_BONUS
const THIEVING_HEIST_MAX_SUCCESS := ThievingState.HEIST_MAX_SUCCESS
const THIEVING_ACTION_JAIL_BASE_SECONDS := ThievingState.ACTION_JAIL_BASE_SECONDS
const THIEVING_ACTION_JAIL_SECONDS_PER_UNLOCK_LEVEL := ThievingState.ACTION_JAIL_SECONDS_PER_UNLOCK_LEVEL
const THIEVING_ACTION_JAIL_MIN_SECONDS := ThievingState.ACTION_JAIL_MIN_SECONDS
const THIEVING_HEIST_DEFS := ThievingState.HEIST_DEFS
const SKILL_MENU_COPY_WIDTH := 840
const SKILL_MENU_SHELF_HEIGHT := 368
const SKILL_MENU_TOP_SCROLL_PAD := 54
const SKILL_MENU_BOTTOM_SCROLL_CLEARANCE := 180
const SKILL_MENU_HEADER_HEIGHT := 610
const SKILL_MENU_ACTIVE_DRAWER_TOP_PAD := 18
const SKILL_MENU_ACTIVE_DRAWER_BOTTOM_PAD := 44
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
const SKILL_DETAIL_XP_BAR_HEIGHT := 62
const MODULE_UI_SORT_LEVEL := ModuleUiRuntime.SORT_LEVEL
const MODULE_UI_SORT_LEVEL_REVERSE := ModuleUiRuntime.SORT_LEVEL_REVERSE
const MODULE_UI_COLLAPSE_SAVE_VERSION := ModuleUiRuntime.COLLAPSE_SAVE_VERSION
const DETAIL_RESTORE_SCROLL_BOTTOM := -2
const NAV_OPEN_CLOSE_ICON_TEXTURE := "res://assets/content/ui/navigation-controls/nav-open-close.png"
const MODULE_PIN_ICON_TEXTURE := "res://assets/content/ui/navigation-controls/pin.png"
const MODULE_PIN_COLOR_TEXTURES := [
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-blue.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-green.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-orange.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-pink.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-purple.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-red.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-teal.png",
	"res://assets/content/ui/navigation-controls/pin-color/pin-color-yellow.png",
]
const MODULE_ACTION_ZONE_SIZE := Vector2(170, 170)
const MODULE_ACTION_ZONE_TOP_OFFSET := -52.0
const MODULE_ACTION_ZONE_OUTER_OFFSET := -42.0
const MODULE_COLLAPSE_ACTION_ZONE_SIZE := Vector2(174, 174)
const MODULE_COLLAPSE_ACTION_ZONE_TOP_OFFSET := -30.0
const MODULE_COLLAPSE_ACTION_ZONE_OUTER_OFFSET := -48.0
const MODULE_ACTION_ZONE_Z_INDEX := 920
const MODULE_PIN_BADGE_SIZE := Vector2(320, 320)
const MODULE_PIN_BADGE_HIT_MIN := Vector2(35, 2)
const MODULE_PIN_BADGE_HIT_MAX := Vector2(284, 316)
const MODULE_PIN_BADGE_CLIP_ORIGIN := Vector2(-220, -330)
const MODULE_PIN_BADGE_CLIP_SIZE := Vector2(520, 388)
const MODULE_PIN_BADGE_SETTLED_POSITION := Vector2(198, 128)
const MODULE_PIN_BADGE_PULL_OUT_POSITION := Vector2(236, 14)
const MODULE_PIN_CONFIRM_ANIMATION_SECONDS := 0.315
const MODULE_PIN_UNPIN_ANIMATION_SECONDS := 0.27
const MODULE_PIN_SOURCE_PRUNE_HOLD_SECONDS := 4.0
const MODULE_PIN_BADGE_Z_INDEX := 350
const MODULE_TITLE_OVER_PIN_Z_INDEX := 390
const MODULE_PIN_CONFIRM_STILL_SECONDS := 0.07
const MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS := 0.075
const MODULE_PIN_CONFIRM_TURNAROUND_SECONDS := 0.03
const MODULE_PIN_CONFIRM_POKE_SECONDS := 0.14
const MODULE_PIN_CONFIRM_APPEAR_OFFSET := Vector2(26, -78)
const MODULE_PIN_CONFIRM_ANTICIPATION_OFFSET := Vector2(34, -104)
const MODULE_PIN_EXIT_LIFT_OFFSET := Vector2(9, -29)
const MODULE_UTILITY_ACTIVE_FILL := Color("#d8d8d8")
const MODULE_COLLAPSE_BADGE_SIZE := Vector2(112, 112)
const MODULE_COLLAPSE_BADGE_POSITION := Vector2(-78, -58)
const MODULE_COLLAPSED_ROW_HEIGHT := 176.0
const MODULE_COLLAPSE_SQUEEZE_SECONDS := 0.34
const MODULE_COLLAPSED_TITLE_LIFT_Y := -24.0
const SKILL_DETAIL_TEXT_SEPARATION := 25
const SKILL_DETAIL_LEFT_SEPARATION := 67
const SKILL_DETAIL_XP_BAR_WIDTH := 710
const SKILL_DETAIL_ICON_SIZE := Vector2(400, 400)
const SKILL_DETAIL_ICON_Y_OFFSET := 16.0
const SKILL_SWIPE_THRESHOLD := 230.0
const SKILL_SWIPE_FEEDBACK_DEADZONE := 46.0
const SKILL_SWIPE_PAGE_GAP := 960.0
const SKILL_SWIPE_GAP_LOAD_TRANSITION_ENABLED := true
const SKILL_SWIPE_GAP_READY_WAIT_FRAMES := 4
const SKILL_SWIPE_SETTLE_SECONDS := 0.20
const SKILL_SWIPE_CANCEL_SECONDS := 0.14
const SKILL_SWIPE_DRAG_FRAME_FADE_ENABLED := false
const SKILL_SWIPE_PREVIEW_FADE_DISTANCE := SKILL_SWIPE_THRESHOLD * 1.25
const SKILL_SWIPE_PREVIEW_FADE_MIN_ALPHA := 0.30
const SKILL_SWIPE_PAPER_FADE_ENABLED := false
const SKILL_SWIPE_PAPER_FADE_DISTANCE := SKILL_SWIPE_THRESHOLD * 4.0
const SKILL_SWIPE_CREAM_COVER_FADE_IN_SECONDS := 0.08
const SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS := 0.12
const SKILL_SWIPE_PAGE_SWITCH_FADE_OUT_SECONDS := 0.22
const SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS := 0.28
const SKILL_SWIPE_MODULE_UTILITY_FADE_OUT_SECONDS := 0.18
const SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS := 0.24
const SKILL_SWIPE_SHELF_BACKGROUND_FADE_OUT_SECONDS := 0.18
const SKILL_SWIPE_SHELF_BACKGROUND_FADE_IN_SECONDS := 0.24
const DIRECT_SKILL_NAV_COVER_MIN_SECONDS := 0.24
const DIRECT_SKILL_NAV_COVER_FADE_IN_SECONDS := 0.10
const DIRECT_SKILL_NAV_COVER_FADE_SECONDS := 0.18
const PAGE_SWITCH_SCROLL_COVER_FADE_IN_SECONDS := 0.22
const PAGE_SWITCH_SCROLL_COVER_HOLD_SECONDS := 0.34
const PAGE_SWITCH_SCROLL_COVER_FADE_SECONDS := 0.18
const SKILL_SWIPE_LIGHT_PREVIEW_ENABLED := true
const SKILL_SWIPE_SHOW_INCOMING_PREVIEW_DURING_DRAG := false
const SKILL_SWIPE_LIGHT_PREVIEW_HEADER_ENABLED := true
const SKILL_SWIPE_LIGHT_PREVIEW_MAX_CARDS := 1
const SKILL_SWIPE_HIDDEN_PREVIEW_MAX_CARDS := 1
const SKILL_SWIPE_REAL_CARD_IDLE_PREWARM_ENABLED := false
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
const TUTORIAL_STARTER_ACTION_ID := "shove-wobbly-hay-bale"
const TUTORIAL_LEVEL_TWO_ACTION_ID := "kick-mud-off-boot"
const TUTORIAL_GATE_LATCH_ACTION_ID := "wrestle-stuck-gate-latch"
const TUTORIAL_DEFERRED_AFTER_GATE_ACTION_ID := "box-suspicious-feed-sack"
const ACTIVITY_START_HIGHLIGHT_DELAY_SECONDS := 3.0
const ACTIVITY_START_HIGHLIGHT_FADE_IN_SECONDS := 3.0
const ACTIVITY_START_HIGHLIGHT_FADE_OUT_SECONDS := 0.42
const ACTIVITY_START_HIGHLIGHT_GAP := 26.0
const ACTIVITY_START_HIGHLIGHT_RING_THICKNESS := 18.0
const ACTIVITY_START_HIGHLIGHT_BLUR_SPREAD := 22.0
const ACTIVITY_START_HIGHLIGHT_BLUR_LAYERS := 12
const ACTIVITY_START_HIGHLIGHT_BORDER_COLOR := Color("#ffd84a")
const ONBOARDING_HEADER_FADE_SECONDS := 0.62
const ONBOARDING_SUMMARY_FADE_SECONDS := 2.0
const ONBOARDING_AUTO_RUN_MESSAGE_COMPLETION_THRESHOLD := 1
const ONBOARDING_HEADER_REVEAL_PROGRESS_FRACTION := 0.5
const ONBOARDING_AUTO_RUN_MESSAGE_LINGER_SECONDS := 3.0
const ONBOARDING_STAMINA_GAUGE_DELAY_BEFORE_FADE_SECONDS := 2.0
const ONBOARDING_STAMINA_GAUGE_FADE_SECONDS := 2.0
const ONBOARDING_STAMINA_TIP_LINGER_SECONDS := 4.0
const ONBOARDING_STAMINA_TIP_FONT_SIZE := 56
const ONBOARDING_STAMINA_TIP_LABEL_WIDTH := 300.0
const ONBOARDING_SWIPE_STAMINA_THRESHOLD := 5.0
const ONBOARDING_FIGHT_ACTION_STATS_FADE_SECONDS := 2.0
const ONBOARDING_BOTTOM_TIP_FADE_SECONDS := 1.2
const ONBOARDING_OVERLAY_TIP_FONT_SIZE := 50
const ONBOARDING_MASTERY_OVERLAY_TIP_GAP := 47.0
const ONBOARDING_MASTERY_TIP_ABOVE_CARD_GAP := 112.0
const ONBOARDING_MEDAL_TIP_LINGER_SECONDS := 3.0
const ONBOARDING_LEVEL_UP_OVERLAY_TIP_GAP := 10.0
const STAMINA_TIP_DISCOVERY_HOLD_SECONDS := 4.0
const LOCKED_ACTIVITY_PREVIEW_XP_THRESHOLD := 16
const BOTTOM_TUTORIAL_TIP_FONT_SIZE := 64
const DETAIL_PULL_TIP_FONT_SIZE := 62
const DETAIL_PULL_TIP_HEIGHT := 188.0
const DETAIL_PULL_TIP_TRIGGER_OFFSET := 92.0
const DETAIL_PULL_TIP_FULL_OFFSET := 210.0
const DETAIL_PULL_TIP_TEXTS := [
	"tip: tap the top right corner of an activity to collapse it.",
	"tip: tap the top left corner of an activity to pin it into the Pins page.",
	"tip: you can collapse activities by pressing the top right.",
	"tip: you can expand collapsed activities by clicking anywhere on them.",
	"tip: use the sort button to change how activities are ordered.",
	"tip: tap info chips to see what is changing an activity's stats.",
	"tip: XP, stamina, time, and rate chips can explain their bonuses.",
	"tip: info chips show details like badge boosts, mission boosts, and other stat changes.",
	"tip: tap earned medals to see their celebration animation again.",
	"tip: training a combo skill is great XP without spending that skill's stamina.",
	"tip: toggle the fish button at the top left of the stamina gauge to automatically eat fish.",
	"tip: pinned activities stay easy to reach from the Pins page.",
	"tip: high-level sort puts your newest challenges closer to the top.",
	"tip: low-level sort makes it easier to clean up older medals.",
	"tip: combo activities can train two skills at once.",
	"tip: rating the game five stars will make the dev very happy.",
	"tip: badge boosts are strongest next door and fade with distance.",
	"tip: badges on lower activities can make the next few activities cost less stamina and finish faster.",
	"tip: badges on higher activities can give earlier activities more success rate and lower stamina cost."
]
const PASSIVE_BUTTON_TAP_CONFIRM_SECONDS := 0.08
const ACTIVITY_JUMP_TOP_TEXTURE := "res://assets/content/ui/activity-jump-top-circle.png"
const ACTIVITY_JUMP_BOTTOM_TEXTURE := "res://assets/content/ui/activity-jump-bottom-circle.png"
const ACTIVITY_BACK_TEXTURE := "res://assets/content/ui/activity-back-arrow.png"
const ACTIVITY_JUMP_ARROW_SIZE := Vector2(296, 296)
const ACTIVITY_BACK_BUTTON_SIZE := Vector2(460, 140)
const ACTIVITY_BACK_ARROW_SIZE := Vector2(250, 74)
const ACTIVITY_JUMP_ARROW_EDGE_INSET := 28.0
const ACTIVITY_JUMP_ARROW_BOTTOM_EDGE_INSET := 690.0
const ACTIVITY_JUMP_ARROW_LINGER_SECONDS := 1.2
const ACTIVITY_JUMP_ARROW_FADE_IN_SECONDS := 0.10
const ACTIVITY_JUMP_ARROW_FADE_OUT_SECONDS := 0.22
const ACTIVITY_JUMP_ARROW_EDGE_EPSILON := 6
const ACTIVITY_JUMP_ARROW_MIN_MODULES := 4
const ACTIVITY_JUMP_ARROW_LANDING_PREFILL_BUFFER_PX := 420.0
const LEADERBOARD_SUBMIT_INTERVAL_SECONDS := 15 * 60
const LEADERBOARD_ICON := "res://assets/content/ui/leaderboard-podium-icon.png"
const FIREBASE_DATABASE_URL := ""
const FIREBASE_WEB_API_KEY := ""
const FIREBASE_LOCAL_CONFIG_PATH := "res://firebase-leaderboard-config.json"
const LEADERBOARD_FIREBASE_ROOT := "leaderboards/v1"
const CHAT_FIREBASE_ROOT := "global_chat/v1"
const LEADERBOARD_FETCH_INTERVAL_SECONDS := 15 * 60
const LEADERBOARD_PROCESS_INTERVAL_SECONDS := 30.0
const LEADERBOARD_AUTH_REFRESH_MARGIN_SECONDS := 5 * 60
const LEADERBOARD_AUTH_RETRY_INTERVAL_SECONDS := 15 * 60
const CHAT_STREAM_RETRY_INTERVAL_SECONDS := 30
const CHAT_STREAM_RECONNECT_MIN_SECONDS := 5
const CHAT_STREAM_POLL_INTERVAL_SECONDS := 0.25
const CHAT_STREAM_MAX_BUFFER_CHARS := 65536
const CHAT_SEND_INTERVAL_SECONDS := 2
const CHAT_MESSAGE_MAX_CHARS := 80
const CHAT_STRIP_VISIBLE_COUNT := 2
const CHAT_FULL_VISIBLE_COUNT := 25
const CHAT_STRIP_HEIGHT := 260
const CHAT_KEYBOARD_PREVIEW_HEIGHT := 178
const CHAT_STRIP_EMPTY_GRACE_MSEC := 2200
const CHAT_STRIP_HIDE_GRACE_MSEC := 800
const CHAT_STRIP_ICON := "res://assets/content/ui/chat-speech-bubble.png"
const CHAT_UNREAD_DOT_DIAMETER := 44.0
const CHAT_UNREAD_DOT_EDGE_INSET := 32.0
const CHAT_UI_Z := 3500
const REWARD_FLOAT_Z := CHAT_UI_Z - 40
const SKILL_REWARD_FLOAT_GROUP := "skill_reward_float"
const SKILL_REWARD_FLOAT_MULTI_DELAY_SECONDS := 0.20
const SKILL_REWARD_FLOAT_MULTI_SPACING_X := 76.0
const SKILL_REWARD_FLOAT_MULTI_STACK_Y := 30.0
const STAMINA_NEED_FISH_FLOAT_GROUP := "stamina_need_fish_float"
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
const FIREBASE_AUTH_SIGN_UP_URL := "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s"
const FIREBASE_AUTH_REFRESH_URL := "https://securetoken.googleapis.com/v1/token?key=%s"
const FIREBASE_AUTH_SIGN_IN_WITH_IDP_URL := "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=%s"
const GOOGLE_AUTH_ANDROID_SINGLETON := "IdleEliteGoogleAuth"
const GOOGLE_AUTH_PROVIDER_ID := "google.com"
const GOOGLE_AUTH_REQUEST_URI := "http://localhost"
const GOOGLE_AUTH_WEB_CLIENT_ID_CONFIG_KEY := "google_web_client_id"
const CLOUD_SAVE_FIREBASE_ROOT := "cloud_saves/v1"
const CLOUD_SAVE_UPLOAD_INTERVAL_SECONDS := 5 * 60
const CLOUD_SAVE_MAX_PAYLOAD_CHARS := 950000
const LEADERBOARD_REPAIR_PUBLISH_VERSION := 1
const LEADERBOARD_BOTTOM_SCROLL_PAD := 720
const LEADERBOARD_BASE_FRAME_WIDTH := BASE_CANVAS.x
const PROFILE_DISPLAY_NAME_MAX_CHARS := 16
const PROFILE_NAME_KEY_MAX_CHARS := 16
const PROFILE_GUEST_NAME_PREFIX := "guest"
const LEADERBOARD_TOP_COUNT := 50
const LEADERBOARD_PLAYER_OVERLAY_HEIGHT := 470
const LEADERBOARD_CATEGORY_TOTAL_LEVEL := "total_level"
const LEADERBOARD_CATEGORY_TOTAL_XP_COMPAT := "total_xp"
const LEADERBOARD_CATEGORY_MEDALS := "medals_earned"
const LEADERBOARD_CATEGORY_ELITE_HEAVENLY := "elite_heavenly"
const LEADERBOARD_CATEGORY_SKILL_PREFIX := "skill_xp:"
const LEADERBOARD_HTTP_HEADER_JSON := "Content-Type: application/json"
const LEADERBOARD_HTTP_HEADER_ACCEPT_JSON := "Accept: application/json"
const LEADERBOARD_HTTP_HEADER_FORM := "Content-Type: application/x-www-form-urlencoded"
const AD_BONUS_SECONDS := AdBonus.AD_BONUS_SECONDS
const AD_BONUS_WARN_THRESHOLD_SECONDS := AdBonus.AD_BONUS_WARN_THRESHOLD_SECONDS
const AD_BONUS_MAX_SECONDS := AdBonus.AD_BONUS_MAX_SECONDS
const AD_BONUS_XP_MULT := AdBonus.AD_BONUS_XP_MULT
const AD_BONUS_SPEED_MULT := AdBonus.AD_BONUS_SPEED_MULT
const ACTIVITY_STREAK_BONUS_STEP := 5
const ACTIVITY_NORMAL_CRIT_CHANCE := 0.01
const ACTIVITY_STREAK_CRIT_CHANCE := 0.10
const ACTIVITY_CRIT_ACHIEVEMENT_CHANCE_MULT := AchievementState.ACTIVITY_CRIT_ACHIEVEMENT_CHANCE_MULT
const ACTIVITY_CRIT_XP_MULT := 3
const OFFLINE_XP_MULT := 0.30
const LOW_STAMINA_ACTION_SPEED_MULT := 0.20
const TIRED_ACTIVITY_FLOAT_TEXT := "Tired!\n20% speed"
const EVENT_NEED_STAMINA_FLOAT_TEXT := "Need\n%s STAM"
const TIRED_ACTIVITY_FLOAT_COLOR := Color("#fff2a8")
const AUTO_EAT_FISH_AFTER_SPEND_VISUAL_DELAY_MSEC := 180
const ACTIVITY_CRIT_FEEDBACK_SECONDS := 1.68
const ACTIVITY_CRIT_SHAKE_PIXELS := 17.0
const ACTIVITY_CRIT_LIFT_PIXELS := 7.0
const ACTIVITY_CRIT_CARD_SCALE_PEAK := 1.035
const ACTIVITY_CRIT_ART_BURST_SCALE := 1.52
const ACTIVITY_CRIT_TEXT_COLOR := Color("#ffd95a")
const ACTIVITY_CRIT_TEXT_SIZE := Vector2(760, 180)
const ACTIVITY_MEGA_CRIT_FEEDBACK_SECONDS := 5.04
const ACTIVITY_MEGA_CRIT_SHAKE_MULT := 0.28
const ACTIVITY_MEGA_CRIT_LIFT_MULT := 2.0
const ACTIVITY_MEGA_CRIT_CARD_SCALE_PEAK := 1.012
const ACTIVITY_MEGA_CRIT_ART_BURST_SCALE := 2.05
const ACTIVITY_MEGA_CRIT_TEXT_COLOR := Color("#fff052")
const ACTIVITY_MEGA_CRIT_TEXT_SIZE := Vector2(940, 220)
const ACTIVITY_MEGA_CRIT_HIGHLIGHT_BLEED := 10.0
const ACTIVITY_MEGA_CRIT_ART_DRIFT_PIXELS := 92.0
const BONUS_EMPHASIS_FLOAT_COLOR := Color("#33f17a")
const BONUS_EMPHASIS_FLASH_COLOR := Color("#3dff8d")
const BONUS_EMPHASIS_SECONDS := 0.54
const BONUS_EMPHASIS_CASCADE_SECONDS := 2.0
const FIGHT_PUNCH_STAMINA_COST_CHANCE := FightingRuntime.FIGHT_PUNCH_STAMINA_COST_CHANCE
const ACTIVITY_UNLOCK_CHAIN_FALL_SECONDS := 1.15
const ACTIVITY_UNLOCK_CHAIN_FADE_SECONDS := 0.85
const ACTIVITY_UNLOCK_MOTION_START_DELAY := 0.48
const ACTIVITY_UNLOCK_NEXT_PREVIEW_FADE_DELAY := 0.68
const ACTIVITY_UNLOCK_SPACER_SETTLE_SECONDS := 1.18
const ACTIVITY_PREVIEW_FADE_IN_SECONDS := 1.28
const ACTIVITY_UNLOCK_NEXT_PREVIEW_SETTLE_OFFSET := 12.0
const AD_TEST_UNIT_ANDROID_REWARDED := AdBonus.AD_TEST_UNIT_ANDROID_REWARDED
const AD_LIVE_UNIT_ANDROID_REWARDED := AdBonus.AD_LIVE_UNIT_ANDROID_REWARDED
const MODAL_OVERLAY_Z := 4096
const ACHIEVEMENT_TOAST_CANVAS_LAYER := 128
const ACHIEVEMENTS_MODAL_SIZE := Vector2(1760, 3000)
const ACHIEVEMENTS_MODAL_VIEWPORT_MARGIN := Vector2(64, 80)
const ACHIEVEMENTS_MODAL_SCROLL_HEIGHT := 2220.0
const OFFLINE_SUMMARY_MODAL_WIDTH := 1680.0
const OFFLINE_SUMMARY_MODAL_MIN_HEIGHT := 1240.0
const OFFLINE_SUMMARY_MODAL_MAX_HEIGHT := 2180.0
const OFFLINE_SUMMARY_MODAL_CHROME_HEIGHT := 1240.0
const OFFLINE_SUMMARY_MODAL_MAX_PROGRESS_HEIGHT := 820.0
const OFFLINE_SUMMARY_MODAL_VIEWPORT_MARGIN := Vector2(64, 80)
const OFFLINE_SUMMARY_SECTION_HEIGHT := 88.0
const OFFLINE_SUMMARY_ROW_HEIGHT := 214.0
const OFFLINE_SUMMARY_ROW_GAP := 28.0
const ACHIEVEMENT_TOAST_SIZE := Vector2(1500, 430)
const ACHIEVEMENT_TOAST_GAP := 28.0
const ACHIEVEMENT_TOAST_VIEWPORT_MARGIN := Vector2(36, 36)
const ACHIEVEMENT_TOAST_EXIT_DELAY := 9.0
const ACHIEVEMENT_TOAST_AUTO_EXIT_SECONDS := 0.64
const ACHIEVEMENT_TOAST_TAP_EXIT_SECONDS := 0.24
const ACHIEVEMENT_TOAST_QUEUE_BADGE_SIZE := Vector2(190, 118)
const ACHIEVEMENT_TOAST_QUEUE_BADGE_OFFSET := Vector2(28, 22)
const GLOBAL_BUFFS_MODAL_MIN_HEIGHT := 1440.0
const GLOBAL_BUFFS_MODAL_BASE_HEIGHT := 1260.0
const GLOBAL_BUFFS_MODAL_ROW_HEIGHT := 120.0
const GLOBAL_BUFFS_MODAL_MAX_HEIGHT := 2740.0
const GLOBAL_BUFFS_MODAL_SCROLL_CHROME := 760.0
const TUTORIAL_LAYER := ACHIEVEMENT_TOAST_CANVAS_LAYER + 1
const BOOT_WARMUP_LAYER := TUTORIAL_LAYER + 2
const CHAT_OVERLAY_CANVAS_LAYER := BOOT_WARMUP_LAYER + 1
const PROFILE_OVERLAY_CANVAS_LAYER := CHAT_OVERLAY_CANVAS_LAYER + 1
const SKILL_NAV_COVER_CANVAS_LAYER := PROFILE_OVERLAY_CANVAS_LAYER + 1
const PIN_TRANSITION_BLOCKER_MIN_SECONDS := 0.62
const PIN_TRANSITION_BLOCKER_FADE_SECONDS := 0.18
const DETAIL_LAZY_VIEWPORT_BUFFER_PX := 120.0
const FISHING_DETAIL_LAZY_VIEWPORT_BUFFER_PX := 1800.0
const DETAIL_LAZY_BOOT_VIEWPORT_BUFFER_PX := 240.0
const DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT := 2
const FISHING_DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT := 4
const DETAIL_LAZY_BOOT_EAGER_COUNT := 2
const BOOT_DETAIL_COMPLETE_BUDGET_PER_FRAME := 3
const BOOT_SWIPE_PREWARM_DELAY_SECONDS := 4.0
const SKILL_SWIPE_IDLE_PREWARM_ENABLED := false
const SKILL_SWIPE_PREVIEW_CACHE_PARKED_PAGES := false
const DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME := 1
const DETAIL_LAZY_UNMOUNT_ENABLED := true
const DETAIL_LAZY_UNMOUNT_BUFFER_PX := 180.0
const FISHING_DETAIL_LAZY_UNMOUNT_BUFFER_PX := 2800.0
const FISHING_DETAIL_RENDER_REVEAL_BUFFER_PX := 2200.0
const FISHING_DETAIL_RENDER_HIDE_BUFFER_PX := 3600.0
const FISHING_DETAIL_RENDER_CULL_ACTIVE_STEP_PX := 180.0
const FISHING_DETAIL_RENDER_CULL_ACTIVE_MIN_MSEC := 56
const FISHING_DETAIL_USE_FLAT_ART := true
const FISHING_SCROLL_MODE_SETTLE_MSEC := 160
const FISHING_DETAIL_VISIBLE_SETTLE_FILL_BUDGET := 1
const DETAIL_LAZY_UNMOUNT_BUDGET_PER_FRAME := 2
const DETAIL_LAZY_SETTLE_WARM_MOUNT_ENABLED := true
const DETAIL_LAZY_SETTLE_WARM_MOUNT_BUDGET_PER_FRAME := 1
const FISHING_DETAIL_LAZY_SETTLE_WARM_MOUNT_BUDGET_PER_FRAME := 1
const FISHING_DETAIL_IDLE_WARM_MOUNT_MAX_ACTION_CARDS := 12
const DETAIL_LAZY_FADE_IN_SECONDS := 0.28
const DETAIL_LAZY_SLIDE_IN_OFFSET_Y := 24.0
const DETAIL_LAZY_SCALE_IN_AMOUNT := 0.985
const MODULE_LIST_TRANSITION_SECONDS := 0.42
const MODULE_LIST_TRANSITION_NEW_SECONDS := 0.30
const MODULE_LIST_TRANSITION_NEW_OFFSET_Y := 28.0
const MODULE_LIST_TRANSITION_MIN_MOVE := 2.0
const DETAIL_LAZY_STACK_SEPARATION := 56.0
const DETAIL_LAZY_TIP_HEIGHT := 174.0
const DETAIL_LAZY_WINDOW_SYNC_INTERVAL_SECONDS := 0.035
const DETAIL_TEXTURE_PREWARM_REQUESTS_PER_FRAME := 2
const BACKGROUND_MAINTENANCE_INTERVAL_SECONDS := 0.25
const BACKGROUND_MAINTENANCE_STEP_COUNT := 7
const EXTENDED_AUDIO_WARMUP_FRAME_BUDGET_MSEC := 12
const OFFLINE_ACTIVE_BATCH_MIN_CYCLES := 12
const OFFLINE_ACTIVE_BATCH_MAX_CYCLES := 512
const OFFLINE_CONVERGENCE_BATCH_MIN_CYCLES := 12
const OFFLINE_CONVERGENCE_BATCH_MAX_CYCLES := 512
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
const SKILL_MENU_LIGHT_PASTEL_MIX := 0.68
const SKILL_MENU_DARK_THEME_DARKEN := 0.18
const SKILL_MENU_DARK_PANEL_MIX := 0.10
const SKILL_THEME_COLORS := {
	"fight": Color("#e84d4d"),
	"thieving": Color("#8956bc"),
	"build": Color("#237cd5"),
	"woodcutting": Color("#6ea937"),
	"fishing": Color("#2dc0b9")
}
const SKILL_SHORT_CODES := {
	"fight": "FGT",
	"thieving": "THV",
	"build": "BLD",
	"woodcutting": "WOD",
	"fishing": "FSH"
}

var skills := {}
var activity_data_catalog := ActivityDataCatalog.new()
var skill_defs := activity_data_catalog.skill_defs
var actions_by_skill := activity_data_catalog.actions_by_skill
var actions_by_key := activity_data_catalog.actions_by_key
var convergence_action_ids := activity_data_catalog.convergence_action_ids
var convergence_state_dirty: bool:
	get:
		return _convergence_runtime().convergence_state_dirty
	set(value):
		_convergence_runtime().convergence_state_dirty = bool(value)
var fishing_area_definitions: Array:
	get:
		return fishing_runtime.area_definitions
	set(value):
		fishing_runtime.area_definitions = value
var event_module_defs: Array:
	get:
		return _temporary_event_runtime().event_module_defs
	set(value):
		_temporary_event_runtime().event_module_defs = value
var temporary_event_active: Dictionary:
	get:
		return _temporary_event_runtime().temporary_event_active
	set(value):
		_temporary_event_runtime().temporary_event_active = value
var temporary_event_cooldowns: Dictionary:
	get:
		return _temporary_event_runtime().temporary_event_cooldowns
	set(value):
		_temporary_event_runtime().temporary_event_cooldowns = value
var temporary_event_next_roll_unix: int:
	get:
		return _temporary_event_runtime().temporary_event_next_roll_unix
	set(value):
		_temporary_event_runtime().temporary_event_next_roll_unix = value
var temporary_event_scheduler_elapsed: float:
	get:
		return _temporary_event_runtime().temporary_event_scheduler_elapsed
	set(value):
		_temporary_event_runtime().temporary_event_scheduler_elapsed = value
var selected_skill_id := "fight"
var current_screen := "home"
var running_skill_id := ""
var running_action_id := ""
var action_art_last_running_key := ""
var action_progress := 0.0
var event_running_skill_id := ""
var event_running_action_id := ""
var event_action_progress := 0.0
var canceled_action_progress_by_key := {}
var action_stop_hold_active := false
var action_stop_hold_armed := false
var action_stop_hold_unloading := false
var action_stop_hold_skill_id := ""
var action_stop_hold_action_id := ""
var action_stop_hold_elapsed := 0.0
var action_stop_hold_unload_elapsed := 0.0
var action_stop_hold_pointer_id := -1
var action_stop_hold_position := Vector2.ZERO
var action_stop_hold_start_position := Vector2.ZERO
var action_stop_hold_layer: CanvasLayer
var action_stop_hold_circle: StopHoldCircle
var action_opportunity_consumed := false
var action_opportunity_missed := false
var action_opportunity_boost_seconds := 0.0
var action_opportunity_boost_duration := 0.0
var action_opportunity_regen_skill_id := ""
var action_opportunity_regen_seconds := 0.0
var action_opportunity_cycle_elapsed := 0.0
var action_opportunity_triple_click_stacks := 0
var action_opportunity_emerald_shrink_steps := 0
var action_opportunity_emerald_window := ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
var action_opportunity_emerald_start_window := ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
var action_opportunity_emerald_target_window := ACTION_OPPORTUNITY_EMERALD_MAX_WINDOW
var action_opportunity_emerald_transition_elapsed := ACTION_OPPORTUNITY_EMERALD_SHRINK_SECONDS
var action_opportunity_ruby_left := ACTION_OPPORTUNITY_RUBY_START_LEFT
var action_opportunity_ruby_start_left := ACTION_OPPORTUNITY_RUBY_START_LEFT
var action_opportunity_ruby_target_left := ACTION_OPPORTUNITY_RUBY_START_LEFT
var action_opportunity_ruby_transition_elapsed := ACTION_OPPORTUNITY_RUBY_MOVE_SECONDS
var action_opportunity_miss_expand_per_side := 0.0
var action_opportunity_miss_expand_start := 0.0
var action_opportunity_miss_expand_target := 0.0
var action_opportunity_miss_expand_elapsed := ACTION_OPPORTUNITY_MISS_EXPAND_SECONDS
var action_opportunity_persistent_windows: Array[Vector2] = []
var action_opportunity_persistent_key := ""
var last_action_opportunity_tap_key := ""
var last_action_opportunity_tap_msec := 0
var action_card_press_consumed := false
var action_progress_speed_key:
	get: return _action_runtime().action_progress_speed_key
	set(value): _action_runtime().action_progress_speed_key = str(value)
var action_progress_speed_mult_current:
	get: return _action_runtime().action_progress_speed_mult_current
	set(value): _action_runtime().action_progress_speed_mult_current = float(value)
var tired_activity_zero_float_action_key := ""
var auto_eat_fish_after_spend_due_msec_by_skill := {}
var material_runtime := MaterialRuntime.new()
var fish_currency := 0.0
var fish_currency_ever_earned := false
var fishing_runtime := FishingState.new()
var thieving_state := ThievingState.new(self)
var equipped_fishing_tool_id: String:
	get:
		return fishing_runtime.equipped_tool_id
	set(value):
		fishing_runtime.equipped_tool_id = str(value)
var fishing_action_location_key_cache: Dictionary:
	get:
		return fishing_runtime.action_location_key_cache
	set(value):
		fishing_runtime.action_location_key_cache = value
var fishing_action_thumbnail_path_cache: Dictionary:
	get:
		return fishing_runtime.action_thumbnail_path_cache
	set(value):
		fishing_runtime.action_thumbnail_path_cache = value
var fishing_action_mastery_id_cache: Dictionary:
	get:
		return fishing_runtime.action_mastery_id_cache
	set(value):
		fishing_runtime.action_mastery_id_cache = value
var fishing_active_tool_init_token := 0
var fishing_tool_wallet_open := false
var fishing_net_stored_fish: int:
	get:
		return fishing_runtime.net_stored_fish
	set(value):
		fishing_runtime.net_stored_fish = int(value)
var fishing_net_successes: int:
	get:
		return fishing_runtime.net_successes
	set(value):
		fishing_runtime.net_successes = int(value)
var fishing_net_stored_xp: int:
	get:
		return fishing_runtime.net_stored_xp
	set(value):
		fishing_runtime.net_stored_xp = int(value)
var fishing_net_stored_mastery: float:
	get:
		return fishing_runtime.net_stored_mastery
	set(value):
		fishing_runtime.net_stored_mastery = float(value)
var fishing_net_haul_visual_seconds: float:
	get:
		return fishing_runtime.net_haul_visual_seconds
	set(value):
		fishing_runtime.net_haul_visual_seconds = float(value)
var fishing_net_set_in_water: bool:
	get:
		return fishing_runtime.net_set_in_water
	set(value):
		fishing_runtime.net_set_in_water = bool(value)
var fishing_boat_stored_fish: int:
	get:
		return fishing_runtime.boat_stored_fish
	set(value):
		fishing_runtime.boat_stored_fish = int(value)
var fishing_boat_successes: int:
	get:
		return fishing_runtime.boat_successes
	set(value):
		fishing_runtime.boat_successes = int(value)
var fishing_boat_stored_xp: int:
	get:
		return fishing_runtime.boat_stored_xp
	set(value):
		fishing_runtime.boat_stored_xp = int(value)
var fishing_boat_stored_mastery: float:
	get:
		return fishing_runtime.boat_stored_mastery
	set(value):
		fishing_runtime.boat_stored_mastery = float(value)
var fishing_boat_haul_visual_seconds: float:
	get:
		return fishing_runtime.boat_haul_visual_seconds
	set(value):
		fishing_runtime.boat_haul_visual_seconds = float(value)
var fishing_net_collected: bool:
	get:
		return fishing_runtime.net_collected
	set(value):
		fishing_runtime.net_collected = bool(value)
var fishing_net_collect_pending: bool:
	get:
		return fishing_runtime.net_collect_pending
	set(value):
		fishing_runtime.net_collect_pending = bool(value)
var fishing_rod_set_in_water: bool:
	get:
		return fishing_runtime.rod_set_in_water
	set(value):
		fishing_runtime.rod_set_in_water = bool(value)
var fishing_rod_haul_visual_seconds: float:
	get:
		return fishing_runtime.rod_haul_visual_seconds
	set(value):
		fishing_runtime.rod_haul_visual_seconds = float(value)
var fishing_rod_collected: bool:
	get:
		return fishing_runtime.rod_collected
	set(value):
		fishing_runtime.rod_collected = bool(value)
var fishing_reinforced_rod_collected: bool:
	get:
		return fishing_runtime.reinforced_rod_collected
	set(value):
		fishing_runtime.reinforced_rod_collected = bool(value)
var fishing_star_rod_collected: bool:
	get:
		return fishing_runtime.star_rod_collected
	set(value):
		fishing_runtime.star_rod_collected = bool(value)
var fishing_boat_built: bool:
	get:
		return fishing_runtime.boat_built
	set(value):
		fishing_runtime.boat_built = bool(value)
var fishing_boat_set_in_water: bool:
	get:
		return fishing_runtime.boat_set_in_water
	set(value):
		fishing_runtime.boat_set_in_water = bool(value)
var fishing_mirror_collected: bool:
	get:
		return fishing_runtime.mirror_collected
	set(value):
		fishing_runtime.mirror_collected = bool(value)
var selected_fishing_locations: Dictionary:
	get:
		return fishing_runtime.selected_locations
	set(value):
		fishing_runtime.selected_locations = value
var passive_modules := {}
var passive_modules_runtime: PassiveModulesRuntime
var convergence_runtime: ConvergenceRuntime
var convergence_modules: Dictionary:
	get:
		return _convergence_runtime().convergence_modules
	set(value):
		_convergence_runtime().convergence_modules = value
var built_modules := {}
var completed_bosses: Dictionary:
	get:
		return _fighting_runtime().completed_bosses
	set(value):
		_fighting_runtime().completed_bosses = value
var thieving_trophies: Dictionary:
	get:
		return thieving_state.trophies
	set(value):
		thieving_state.trophies = value
var thieving_action_jails: Dictionary:
	get:
		return thieving_state.action_jails
	set(value):
		thieving_state.action_jails = value
var pending_thieving_trophy_reward_float: Dictionary:
	get:
		return thieving_state.pending_trophy_reward_float
	set(value):
		thieving_state.pending_trophy_reward_float = value
var hub_runtime: HubRuntime
var hub_surface: HubSurface
var last_hub_mission_completion_ceremony_text := ""
var onboarding_runtime: OnboardingRuntime
var activity_unlock_runtime: ActivityUnlockRuntime
var manual_activity_unlocks:
	get: return _activity_unlock_runtime().manual_activity_unlocks
	set(value): _activity_unlock_runtime().manual_activity_unlocks = value
var manual_activity_requirement_unlocks:
	get: return _activity_unlock_runtime().manual_activity_requirement_unlocks
	set(value): _activity_unlock_runtime().manual_activity_requirement_unlocks = value
var manual_activity_unlocks_trust_checked:
	get: return _activity_unlock_runtime().manual_activity_unlocks_trust_checked
	set(value): _activity_unlock_runtime().manual_activity_unlocks_trust_checked = bool(value)
var manual_activity_unlocks_trusted:
	get: return _activity_unlock_runtime().manual_activity_unlocks_trusted
	set(value): _activity_unlock_runtime().manual_activity_unlocks_trusted = bool(value)

const FISHING_ACTION_ID_ALIASES := {
	"dip-a-tidepool-minnow": "beach-shallows",
	"drag-net-through-creek": "beach-rocks",
	"scoop-pond-minnows": "pier-dock-edge",
	"dangle-string-from-dock": "pier-piling-line",
	"cast-bamboo-rod": "river-bend",
	"fly-fish-at-river-bend": "river-rapids",
	"hand-grab-muddy-catfish": "sewers-drain-gate",
	"spear-fish-in-shallows": "sewers-tunnel-pool",
	"set-tiny-crab-pot": "reef-pot",
	"ice-fish-through-nervous-hole": "winter-lake-ice-hole",
	"cast-from-rowboat": "sea-rowboat",
	"drop-lobster-cage": "reef-cage",
	"trawl-from-tiny-boat": "sea-open-water",
	"night-fish-with-lantern": "reef-night-reef",
	"harpoon-suspicious-ripple": "stormy-sea-ripple",
	"chum-open-water": "sea-chum-line",
	"dive-for-pearl-oysters": "reef-pearl-bed",
	"cast-storm-kite-line": "stormy-sea-storm-line",
	"fish-with-magnetic-hook": "deep-sea-wreck-drop",
	"bait-a-tiny-leviathan": "deep-sea-abyss",
	"open-deep-sea-mailbox-trap": "deep-sea-trench",
	"dredge-wreck-with-magnet": "deep-sea-wreck-drop",
	"bait-the-abyss": "deep-sea-abyss",
	"drop-deep-trench-trap": "deep-sea-trench",
	"skim-a-starlight-minnow": "space-starlight",
	"net-the-reflection-of-a-fish": "space-reflection",
	"beach-crab-pot": "reef-pot",
	"beach-ripple": "stormy-sea-ripple",
}
var plank_boost_enabled := false
var last_passive_process_unix := 0
var last_thieving_action_jail_process_unix: int:
	get:
		return thieving_state.last_action_jail_process_unix
	set(value):
		thieving_state.last_action_jail_process_unix = int(value)
var activity_streak_action_key := ""
var activity_streak_count := 0
var mastery := {}
var stamina := {}
var stamina_bank := {}
var honey_stamina_seconds_remaining := 0.0
var blue_guy_health: float:
	get:
		return _fighting_runtime().blue_guy_health
	set(value):
		_fighting_runtime().blue_guy_health = float(value)
var blue_guy_health_bank: float:
	get:
		return _fighting_runtime().blue_guy_health_bank
	set(value):
		_fighting_runtime().blue_guy_health_bank = float(value)
var stamina_gauge_regen_multiplier := 1.0
var stamina_gauge_regen_target_multiplier := 1.0
var stamina_gauge_boost_skill_id := ""
var stamina_gauge_pending_click := false
var stamina_gauge_pending_skill_id := ""
var stamina_gauge_pending_hold_seconds := 0.0
var stamina_gauge_press_active := false
var stamina_gauge_pre_tip_hold_seconds := 0.0
var auto_eat_fish_enabled_by_skill := {}
var ad_bonus_seconds_remaining := 0.0:
	get:
		return _ad_bonus_runtime().seconds_remaining
	set(value):
		_ad_bonus_runtime().seconds_remaining = float(value)
var shop_rate_prompt_dismissed := false
var last_result := "Pick a skill and start training."
var offline_progress_enabled := true
var auto_unlock_lockpads_enabled := false
var nav_symbol_seen_ids: Dictionary:
	get:
		return _navigation_shell().nav_symbol_seen_ids
	set(value):
		_navigation_shell().nav_symbol_seen_ids = value
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
var nav_bar: PanelContainer
var bottom_nav_buttons_row: HBoxContainer
var pinned_return_screen := "skill"
var pinned_return_skill_id := ""
var pinned_return_detail_scroll := -1
var queue_return_screen: String:
	get:
		return _navigation_shell().queue_return_screen
	set(value):
		_navigation_shell().queue_return_screen = value
var queue_return_skill_id: String:
	get:
		return _navigation_shell().queue_return_skill_id
	set(value):
		_navigation_shell().queue_return_skill_id = value
var queue_return_detail_scroll: int:
	get:
		return _navigation_shell().queue_return_detail_scroll
	set(value):
		_navigation_shell().queue_return_detail_scroll = value
var queue_selection_mode := false
var activity_queue: Array:
	get:
		return _activity_queue_runtime().activity_queue
	set(value):
		_activity_queue_runtime().activity_queue = value
var activity_queue_running: bool:
	get:
		return _activity_queue_runtime().activity_queue_running
	set(value):
		_activity_queue_runtime().activity_queue_running = value
var activity_queue_index: int:
	get:
		return _activity_queue_runtime().activity_queue_index
	set(value):
		_activity_queue_runtime().activity_queue_index = value
var activity_queue_attempt_key: String:
	get:
		return _activity_queue_runtime().activity_queue_attempt_key
	set(value):
		_activity_queue_runtime().activity_queue_attempt_key = value
var pinned_active_shelf_header: Control
var pinned_active_shelf_background: Control
var pinned_active_shelf_skill_id := ""
var pinned_active_shelf_transition_skill_id := ""
var pinned_active_shelf_transition_active := false
var pinned_active_shelf_content: Control
var pinned_active_shelf_stamina_strip: Control
var pinned_active_shelf_stamina_gauges := {}
var pinned_active_shelf_xp_label: Label
var pinned_active_shelf_xp_bar: CleanProgressBar
var pinned_active_shelf_regen_circle: RegenCircle
var pinned_active_shelf_fish_circle: FishCircle
var pinned_active_shelf_tween: Tween
var pinned_active_shelf_height_tween: Tween
var skills_utility_return_screen := "skill"
var skills_utility_return_skill_id := ""
var bottom_nav_open_close_return_to_skill_active := false
var content_scroll: ScrollContainer
var home_scroll: MobileScrollContainer
var skills_content: Control
var home_total_label: Label
var home_skill_labels := {}
var hero_message: Label
var achievement_total_label: Label
var achievement_elite_label: Label
var achievement_total_bar: CleanProgressBar
var achievement_buff_label: Label
var achievement_total_level_label: Label
var achievement_best_card: MarginContainer
var achievement_best_art_frame: PanelContainer
var achievement_best_art: TextureRect
var achievement_best_name_label: Label
var achievement_best_medal: TextureRect
var achievement_skill_count_labels := {}
var achievement_skill_bars := {}
var achievement_skill_level_labels := {}
var achievement_skill_tier_name_labels := {}
var achievement_skill_tier_count_labels := {}
var achievement_skill_tier_bars := {}
var achievement_medal_slot_strips := {}
var achievement_medal_slot_panels := {}
var achievement_medal_slot_icons := {}
var leaderboard_tab: Button
var skills_tab: Button
var hero_tab: Button
var hub_tab: Button
var chat_home_tab: Button
var chat_hub_tab: Button
var chat_shop_tab: Button
var shop_tab: Button
var settings_tab: Button
var depressed_activity_shell_buttons := {}
var bottom_nav_transition_button_id := 0
var bottom_nav_transition_release_queued := false
var leaderboard_category_id := LEADERBOARD_CATEGORY_TOTAL_LEVEL
var leaderboard_last_submitted_score := 0
var leaderboard_last_submitted_total_xp := 0
var leaderboard_last_submitted_scores_by_category := {}
var leaderboard_last_submit_unix := 0
var leaderboard_repair_publish_version := 0
var leaderboard_display_name := ""
var leaderboard_name_key := ""
var leaderboard_avatar_index := 0
var leaderboard_profile_claimed := false
var leaderboard_name_claim_verified := false
var leaderboard_player_id := ""
var leaderboard_rows_by_category := {}
var leaderboard_fetch_unix_by_category := {}
var leaderboard_fetch_retry_unix_by_category := {}
var leaderboard_auth_request: HTTPRequest
var google_auth_exchange_request: HTTPRequest
var cloud_save_fetch_request: HTTPRequest
var cloud_save_upload_request: HTTPRequest
var leaderboard_fetch_request: HTTPRequest
var leaderboard_total_xp_fetch_request: HTTPRequest
var leaderboard_submit_request: HTTPRequest
var leaderboard_name_claim_request: HTTPRequest
var leaderboard_name_recovery_request: HTTPRequest
var profile_reference_update_request: HTTPRequest
var leaderboard_auth_in_flight := false
var leaderboard_auth_mode := ""
var leaderboard_auth_id_token := ""
var leaderboard_auth_refresh_token := ""
var leaderboard_auth_expires_unix := 0
var leaderboard_auth_retry_after_unix := 0
var leaderboard_auth_provider := "anonymous"
var leaderboard_config_loaded := false
var leaderboard_config_database_url := ""
var leaderboard_config_web_api_key := ""
var google_auth_web_client_id := ""
var google_auth_plugin: Object
var google_auth_plugin_connected := false
var google_auth_in_flight := false
var google_auth_status_message := ""
var cloud_save_fetch_in_flight := false
var cloud_save_upload_in_flight := false
var cloud_save_dirty := false
var cloud_save_last_upload_unix := 0
var cloud_save_last_fetch_unix := 0
var cloud_save_remote_checked := false
var cloud_save_last_remote_summary := {}
var cloud_save_last_remote_payload := {}
var cloud_save_status_message := ""
var leaderboard_fetch_in_flight := false
var leaderboard_fetch_category_id := ""
var leaderboard_total_xp_fetch_in_flight := false
var leaderboard_pending_total_rows := []
var leaderboard_submit_in_flight := false
var leaderboard_submit_stage := ""
var leaderboard_pending_score_updates := {}
var leaderboard_pending_repair_publish_version := 0
var leaderboard_name_claim_in_flight := false
var leaderboard_name_claim_pending_name := ""
var leaderboard_name_claim_pending_key := ""
var leaderboard_name_recovery_in_flight := false
var profile_reference_update_in_flight := false
var leaderboard_process_seconds := 0.0
var leaderboard_status_message := ""
var leaderboard_last_submit_payload_categories := []
var chat_send_request: HTTPRequest
var chat_fetch_request: HTTPRequest
var chat_stream_client: HTTPClient
var chat_stream_connected := false
var chat_stream_connecting := false
var chat_stream_request_sent := false
var chat_fetch_in_flight := false
var chat_stream_retry_unix := 0
var chat_stream_next_connect_unix := 0
var chat_stream_visible_count := 0
var chat_stream_buffer := ""
var chat_stream_event_name := ""
var chat_stream_event_data_lines := []
var chat_send_in_flight := false
var chat_send_stage := ""
var chat_rows := []
var chat_last_send_unix := 0
var chat_status_message := ""
var chat_message_edit: LineEdit
var chat_draft_message := ""
var chat_pending_send_after_auth := ""
var chat_enter_submit_armed := true
var chat_submit_deferred := false
var chat_pending_send_message_id := ""
var chat_pending_send_text := ""
var chat_pending_send_payload := {}
var chat_strip: PanelContainer
var chat_unread_dot: PanelContainer
var chat_strip_line_one: Label
var chat_strip_line_two: Label
var chat_strip_last_visible := false
var chat_strip_last_line_one := ""
var chat_strip_last_line_two := ""
var chat_strip_stable_line_one := ""
var chat_strip_stable_line_two := ""
var chat_strip_empty_started_msec := 0
var chat_strip_hide_started_msec := 0
var post_onboarding_bottom_chrome_fade_tween: Tween
var chat_last_opened_created_at := 0
var chat_last_opened_message_id := ""
var chat_overlay_layer: CanvasLayer
var fishing_collection_canvas: CanvasLayer
var chat_overlay: ColorRect
var chat_keyboard_fill: ColorRect
var chat_keyboard_preview: PanelContainer
var chat_keyboard_preview_label: Label
var chat_overlay_body: VBoxContainer
var chat_overlay_scroll: MobileScrollContainer
var chat_overlay_list: VBoxContainer
var chat_overlay_notice: Control
var chat_overlay_row_nodes := {}
var chat_overlay_row_signatures := {}
var chat_overlay_shell_ready := false
var chat_profile_button: Button
var chat_status_title_labels := []
var chat_status_detail_labels := []
var chat_stream_poll_timer: Timer
var chat_keyboard_lift_active := false
var chat_keyboard_lift_pixels := 0.0
var chat_keyboard_lift_hold_seconds := 0.0
var chat_keyboard_lift_last_height := 0.0
var chat_keyboard_lift_target_pixels := 0.0
var chat_keyboard_lift_viewport_height := 0.0
var chat_keyboard_lift_window_height := 0.0
var chat_keyboard_lift_zero_seconds := 0.0
var chat_keyboard_preview_keyboard_visible := false
var chat_keyboard_was_visible := false
var chat_keyboard_close_submit_done := false
var chat_keyboard_focus_active := false
var shop_bonus_label: Label
var skill_cards := {}
var skill_menu_active_drawers := {}
var action_cards := {}
var action_card_keys := []
var module_ui_runtime := ModuleUiRuntime.new()
var module_ui_animating_collapse_key := ""
var module_ui_pin_press_active := false
var module_ui_pin_press_module_key := ""
var module_ui_pin_press_card_host_id := 0
var module_ui_pin_press_position := Vector2.ZERO
var module_ui_pin_press_touch_index := -1
var module_ui_pin_press_dragged := false
var module_ui_collapse_press_active := false
var module_ui_collapse_press_module_key := ""
var module_ui_collapse_press_card_host_id := 0
var module_ui_collapse_press_position := Vector2.ZERO
var module_ui_collapse_press_touch_index := -1
var module_ui_collapse_press_dragged := false
var module_ui_pending_pin_scroll_anchor := {}
var module_ui_pin_scroll_anchor_debug := ""
var module_ui_pin_refresh_cover_requested := false
var module_ui_recent_pin_prune_hold_skill_id := ""
var module_ui_recent_pin_prune_hold_track_id := ""
var module_ui_recent_pin_prune_hold_until_msec := 0
var module_ui_refresh_token := 0
var action_pop_tweens := {}
var consecutive_activity_crit_count := 0
var activity_crit_seen := false
var activity_mega_crit_seen := false
var action_card_press_key := ""
var action_card_press_position := Vector2.ZERO
var action_card_press_stat_kind := ""
var action_card_press_dragged := false
var action_card_press_visual_token := 0
var action_card_press_visual_pending_key := ""
var passive_button_press_source: Control
var passive_button_press_kind := ""
var passive_button_press_module_id := ""
var passive_button_press_stat_type := ""
var passive_button_press_popover: Control
var passive_button_press_position := Vector2.ZERO
var passive_button_press_dragged := false
var passive_button_press_touch_index := -1
var passive_button_pending_tap_id := 0
var expanded_activity_stat_key := ""
var expanded_activity_stat_kind := ""
var last_activity_stat_toggle_key := ""
var last_activity_stat_toggle_kind := ""
var last_activity_stat_toggle_msec := 0
var last_action_card_tap_key := ""
var last_action_card_tap_msec := 0
var pending_activity_unlock_ceremony := {}
var activity_unlock_ceremony_count := 0
var activity_unlock_preview_after_ceremony_id := ""
var activity_unlock_preview_staged_action_ids := {}
var activity_unlock_preview_played_action_ids := {}
var activity_unlock_heist_preview_after_ceremony_id := ""
var activity_unlock_center_scroll_target := -1
var activity_unlock_detail_refresh_done := false
var fishing_auto_unlock_waiting_for_detail_refresh := false
var fishing_unlock_visible_mount_ids: Array = []
var fishing_unlock_preview_fade_marker_ids: Array = []
var activity_unlock_visual_scroll_tween: Tween
var detail_unlock_scroll_spacer_tween: Tween
var detail_unlock_auto_scroll_interrupted := false
var detail_unlock_scroll_spacer_heights := {}
var thieving_action_jail_material: ShaderMaterial
var detail_xp_label: Label
var detail_xp_bar: CleanProgressBar
var detail_stamina_bar: CleanProgressBar
var detail_regen_circle: RegenCircle
var detail_regen_circle_host: Control
var detail_regen_circle_fade_group: CanvasGroup
var detail_fish_circle: FishCircle
var detail_blue_guy_health_gauge: BlueGuyHealthHeartGauge
var detail_auto_eat_fish_button: TextureButton
var fishing_tool_wallet_layer: Control
var fishing_tool_wallet_canvas: CanvasLayer
var fishing_tool_wallet_popup: Control
var fishing_tool_wallet_pop_tween: Tween
var fishing_tool_wallet_last_toggle_msec := 0
var stamina_gauge_press_source: RegenCircle
var detail_header_body: Control
var detail_header_left_block: Control
var detail_actions_scroll: MobileScrollContainer
var detail_pull_tip_root: Control
var detail_pull_tip_label: Label
var detail_pull_tip_active := false
var detail_pull_tip_direction := 0
var detail_pull_recent_tip_texts: Array = []
var detail_thieving_scroll_restore_allowed := false
var detail_actions_top_spacer: Control
var onboarding_first_module_spacer_tween: Tween
var onboarding_first_module_center_release_pending := false
var onboarding_first_module_center_released := false
var detail_unlock_scroll_spacer: Control
var detail_shelf_shadow_overlay: Control
var detail_shelf_shadow_alpha := 0.0
var detail_back_button: BaseButton
var detail_back_press_active := false
var detail_back_press_touch_index := -1
var detail_stamina_gauge_pop_tween: Tween
var detail_stamina_gauge_pop_source: RegenCircle
var detail_action_card_nodes := {}
var detail_rendered_action_ids := []
var detail_lazy_plan: Array = []
var detail_lazy_last_scroll := -1.0
var detail_lazy_window_sync_elapsed := 0.0
var detail_lazy_stack: VBoxContainer = null
var detail_lazy_mounted_this_frame := false
var detail_lazy_all_mounted_cache_frame := -1
var detail_lazy_all_mounted_cache_value := false
var detail_lazy_render_cull_last_scroll := -999999.0
var detail_lazy_render_cull_last_msec := 0
var detail_lazy_mount_trace_context := ""
var fishing_detail_render_cull_counts_cache := {"rendered": 0, "culled": 0}
var fishing_detail_visible_culled_count_cache := 0
var detail_scroll_visual_work_hold_frames := 0
var detail_lazy_settle_warm_mount_skill_id := ""
var fishing_scroll_perf_active := false
var fishing_scroll_perf_start_msec := 0
var fishing_scroll_perf_frames := 0
var fishing_scroll_perf_over_50_frames := 0
var fishing_scroll_perf_max_delta_msec := 0.0
var fishing_scroll_perf_start_scroll := 0.0
var fishing_scroll_perf_last_scroll := 0.0
var fishing_scroll_perf_last_summary := {}
var fishing_scroll_mouse_pick_suspended := false
var fishing_scroll_mode_active := false
var fishing_scroll_mode_release_msec := 0
var fishing_detail_primary_pointer_down := false
var fishing_method_button_press_source_id := 0
var detail_lazy_refresh_token := 0
var detail_lazy_cache_bin: Control = null
var detail_background_maintenance_last_scroll := -1.0
var detail_scroll_visual_work_this_frame := false
var detail_texture_prewarm_skill_id := ""
var detail_texture_prewarm_request_queue: Array = []
var detail_texture_prewarm_pending := {}
var background_maintenance_elapsed := 0.0
var background_maintenance_pending_delta := 0.0
var background_maintenance_step_index := 0
var skill_detail_layout_refresh_hold_until_msec := 0
var skill_swipe_tracking := false
var skill_swipe_horizontal := false
var skill_swipe_start := Vector2.ZERO
var skill_swipe_last := Vector2.ZERO
var skill_swipe_touch_index := -1
var skill_swipe_tween: Tween
var skill_swipe_frame: Control
var skill_swipe_page: Control
var skill_strip_ids: Array = []
var skill_strip_index: int = 0
var skill_strip_refs: Dictionary = {}
var skill_strip_wrap_relocated_id := ""
var skill_swipe_animating := false
var skill_swipe_animation_mode := ""
var skill_swipe_drag_base_x := 0.0
var skill_swipe_drag_offset_x := 0.0
var skill_swipe_gap_render_offset_x := 0.0
var skill_swipe_child_click_suppressed := false
var skill_swipe_button_suppressed_until_msec := 0
var skill_swipe_handoff_cover: Control
var skill_nav_cover_layer: CanvasLayer
var page_switch_transition_button_id:
	get: return _navigation_shell().page_switch_transition_button_id
	set(value): _navigation_shell().page_switch_transition_button_id = value
var page_switch_transition_target_skill_id:
	get: return _navigation_shell().page_switch_transition_target_skill_id
	set(value): _navigation_shell().page_switch_transition_target_skill_id = value
var page_switch_press_active:
	get: return _navigation_shell().page_switch_press_active
	set(value): _navigation_shell().page_switch_press_active = value
var page_switch_press_target_skill_id:
	get: return _navigation_shell().page_switch_press_target_skill_id
	set(value): _navigation_shell().page_switch_press_target_skill_id = value
var page_switch_press_position:
	get: return _navigation_shell().page_switch_press_position
	set(value): _navigation_shell().page_switch_press_position = value
var page_switch_press_dragged:
	get: return _navigation_shell().page_switch_press_dragged
	set(value): _navigation_shell().page_switch_press_dragged = value
var pin_transition_blocker: ColorRect
var pin_transition_blocker_tween: Tween
var pin_transition_blocker_target_screen := ""
var pin_transition_blocker_started_msec := 0
var pin_transition_blocker_release_started := false
var pin_transition_blocker_fade_in_done := false
var skill_swipe_paper_fade_overlay: ColorRect
var skill_swipe_paper_fade_hold_alpha := 0.0
var skill_swipe_strip_committed_crossfade := false
var skill_swipe_cover_fade_tween: Tween
var skill_detail_refresh_cover_active := false
var direct_skill_nav_cover_active := false
var skill_swipe_outgoing_cover_active := false
var skill_swipe_rebuild_cover_active := false
var skill_swipe_queued_offset := 0
var skill_swipe_pending_full_finalize := false
var fishing_detail_swipe_press_active := false
var fishing_detail_swipe_press_position := Vector2.ZERO
var fishing_detail_swipe_press_touch_index := -1
var fishing_method_button_press_active := false
var fishing_offer_button_press_active := false
var skill_swipe_pending_preview_state := {}
var skill_swipe_defer_initial_lazy_mount := false
var skill_swipe_lazy_finalize_token := 0
var skill_swipe_finalize_schedule_token := 0
var skill_swipe_finalized_lazy_mount_pending := false
var main_process_frame_index := 0
var skill_swipe_finalize_ready_process_frame := -1
var skill_swipe_finalize_target_skill_id := ""
var skill_swipe_pending_resume_scroll_skill_id := ""
var activity_start_tip_seen:
	get: return _onboarding_runtime().activity_start_tip_seen
	set(value): _onboarding_runtime().activity_start_tip_seen = bool(value)
var activity_start_count := 0
var activity_completion_count := 0
var guaranteed_success_action_completions := 0
var locked_activity_preview_reveal_pending := false
var locked_activity_preview_reveal_skill_ids := {}
var locked_activity_preview_fade_play_pending := false
var locked_activity_preview_played_action_keys := {}
var unlock_padlock_tint_mask_texture: Texture2D
var unlock_padlock_texture: Texture2D
var unlock_padlock_hit_image: Image
var skill_swipe_tip_seen:
	get: return _onboarding_runtime().skill_swipe_tip_seen
	set(value): _onboarding_runtime().skill_swipe_tip_seen = bool(value)
var onboarding_explore_tip_seen:
	get: return _onboarding_runtime().onboarding_explore_tip_seen
	set(value): _onboarding_runtime().onboarding_explore_tip_seen = bool(value)
var onboarding_tutorial_complete:
	get: return _onboarding_runtime().onboarding_tutorial_complete
	set(value): _onboarding_runtime().onboarding_tutorial_complete = bool(value)
var onboarding_explore_tip_sequence_running:
	get: return _onboarding_runtime().onboarding_explore_tip_sequence_running
	set(value): _onboarding_runtime().onboarding_explore_tip_sequence_running = bool(value)
var passive_module_tip_seen:
	get: return _onboarding_runtime().passive_module_tip_seen
	set(value): _onboarding_runtime().passive_module_tip_seen = bool(value)
var silver_opportunity_tip_seen:
	get: return _onboarding_runtime().silver_opportunity_tip_seen
	set(value): _onboarding_runtime().silver_opportunity_tip_seen = bool(value)
var silver_opportunity_tip_action_key:
	get: return _onboarding_runtime().silver_opportunity_tip_action_key
	set(value): _onboarding_runtime().silver_opportunity_tip_action_key = str(value)
var stamina_gauge_tip_seen:
	get: return _onboarding_runtime().stamina_gauge_tip_seen
	set(value): _onboarding_runtime().stamina_gauge_tip_seen = bool(value)
var stamina_gauge_tip_root: Control
var onboarding_starter_action_completion_count:
	get: return _onboarding_runtime().onboarding_starter_action_completion_count
	set(value): _onboarding_runtime().onboarding_starter_action_completion_count = int(value)
var onboarding_header_reveal_after_progress:
	get: return _onboarding_runtime().onboarding_header_reveal_after_progress
	set(value): _onboarding_runtime().onboarding_header_reveal_after_progress = bool(value)
var onboarding_swipe_tip_eligible:
	get: return _onboarding_runtime().onboarding_swipe_tip_eligible
	set(value): _onboarding_runtime().onboarding_swipe_tip_eligible = bool(value)
var onboarding_swipe_navigation_unlocked:
	get: return _onboarding_runtime().onboarding_swipe_navigation_unlocked
	set(value): _onboarding_runtime().onboarding_swipe_navigation_unlocked = bool(value)
var onboarding_swipe_tip_sequence_running:
	get: return _onboarding_runtime().onboarding_swipe_tip_sequence_running
	set(value): _onboarding_runtime().onboarding_swipe_tip_sequence_running = bool(value)
var onboarding_fight_summary_revealed:
	get: return _onboarding_runtime().onboarding_fight_summary_revealed
	set(value): _onboarding_runtime().onboarding_fight_summary_revealed = bool(value)
var onboarding_fight_auto_run_message_shown:
	get: return _onboarding_runtime().onboarding_fight_auto_run_message_shown
	set(value): _onboarding_runtime().onboarding_fight_auto_run_message_shown = bool(value)
var onboarding_fight_stamina_revealed:
	get: return _onboarding_runtime().onboarding_fight_stamina_revealed
	set(value): _onboarding_runtime().onboarding_fight_stamina_revealed = bool(value)
var onboarding_fight_action_stats_revealed:
	get: return _onboarding_runtime().onboarding_fight_action_stats_revealed
	set(value): _onboarding_runtime().onboarding_fight_action_stats_revealed = bool(value)
var onboarding_fight_action_stats_fade_running:
	get: return _onboarding_runtime().onboarding_fight_action_stats_fade_running
	set(value): _onboarding_runtime().onboarding_fight_action_stats_fade_running = bool(value)
var onboarding_stamina_tip_sequence_running:
	get: return _onboarding_runtime().onboarding_stamina_tip_sequence_running
	set(value): _onboarding_runtime().onboarding_stamina_tip_sequence_running = bool(value)
var onboarding_mastery_tip_root: Control
var onboarding_medal_tip_root: Control
var onboarding_swipe_overlay_tip_root: Control
var onboarding_level_up_tip_root: Control
var onboarding_mastery_tip_dismissed := false
var onboarding_medal_tip_shown := false
var activity_unlock_ceremony_action_key := ""
var onboarding_header_sequence_token:
	get: return _onboarding_runtime().onboarding_header_sequence_token
	set(value): _onboarding_runtime().onboarding_header_sequence_token = int(value)
var onboarding_header_sequence_running:
	get: return _onboarding_runtime().onboarding_header_sequence_running
	set(value): _onboarding_runtime().onboarding_header_sequence_running = bool(value)
var onboarding_header_sequence_started_msec:
	get: return _onboarding_runtime().onboarding_header_sequence_started_msec
	set(value): _onboarding_runtime().onboarding_header_sequence_started_msec = int(value)
var onboarding_stamina_tip_sequence_started_msec:
	get: return _onboarding_runtime().onboarding_stamina_tip_sequence_started_msec
	set(value): _onboarding_runtime().onboarding_stamina_tip_sequence_started_msec = int(value)
var onboarding_auto_run_sequence_running:
	get: return _onboarding_runtime().onboarding_auto_run_sequence_running
	set(value): _onboarding_runtime().onboarding_auto_run_sequence_running = bool(value)
var activity_start_highlight_token := 0
var activity_start_highlight_pending := false
var activity_start_highlight_active := false
var activity_start_highlight_border: Control
var activity_start_highlight_card_key := ""
var activity_start_highlight_fade_tween: Tween
var activity_start_highlight_frame_clip_override_active := false
var activity_start_highlight_frame_clip_saved := true
var lock_click_tip_seen:
	get: return _onboarding_runtime().lock_click_tip_seen
	set(value): _onboarding_runtime().lock_click_tip_seen = bool(value)
var lock_click_tip_collapse_until_msec := 0
var settings_overlay: Control
var reset_data_buttons:
	get: return _settings_surface().reset_data_buttons
	set(value): _settings_surface().reset_data_buttons = value
var achievements_overlay: Control
var achievements_panel_frame: Control
var achievements_panel: PanelContainer
var achievements_scroll: ScrollContainer
var achievements_list_stack: VBoxContainer
var achievements_tab_buttons := {}
var achievements_hide_completed: CheckBox
var achievements_modal_tab := "achievements"
var achievements_rebuild_signature := ""
var offline_summary_overlay: Control
var offline_summary_panel_frame: Control
var offline_summary_panel: PanelContainer
var offline_summary_stack: VBoxContainer
var offline_summary_close_pending := false
var tutorial_layer: CanvasLayer
var tutorial_overlay: Control
var tutorial_panel: PanelContainer
var tutorial_target_ring: Panel
var tutorial_target_label: Label
var tutorial_title_label: Label
var tutorial_body_label: Label
var tutorial_step_label: Label
var tutorial_skip_button: Button
var tutorial_active:
	get: return _onboarding_runtime().tutorial_active
	set(value): _onboarding_runtime().tutorial_active = bool(value)
var tutorial_step:
	get: return _onboarding_runtime().tutorial_step
	set(value): _onboarding_runtime().tutorial_step = int(value)
var tutorial_step_changed_msec:
	get: return _onboarding_runtime().tutorial_step_changed_msec
	set(value): _onboarding_runtime().tutorial_step_changed_msec = int(value)
var tutorial_gate_latch_only_until_swipe:
	get: return _onboarding_runtime().tutorial_gate_latch_only_until_swipe
	set(value): _onboarding_runtime().tutorial_gate_latch_only_until_swipe = bool(value)
var paper_button_style_textures := {}
var summary_style_cache: StyleBoxFlat
var thieving_heist_feather_shader: Shader
var thieving_surface: ThievingSurface
var passive_firepit_surface: PassiveFirepitSurface
var empty_style_cache := StyleBoxEmpty.new()
var ui_static_refresh_elapsed := 0.0
var detail_header_gauge_refresh_elapsed := 0.0
var passive_card_progress_refresh_elapsed := 0.0
var detail_actions_scroll_limit_elapsed := 0.0
var top_level_nav_locked_until_msec := 0
var achievements_rebuild_token := 0
var _last_rendered_screen_key := ""
var max_stamina_cache_valid := false
var cached_max_stamina := BASE_MAX_STAMINA
var cached_max_stamina_by_skill := {}
var stat_cache_version:
	get: return _action_runtime().stat_cache_version
	set(value): _action_runtime().stat_cache_version = int(value)
var action_stat_value_cache:
	get: return _action_runtime().action_stat_value_cache
	set(value): _action_runtime().action_stat_value_cache = value if typeof(value) == TYPE_DICTIONARY else {}
var activity_medal_buff_total_cache := {}
var reward_bonus_cache := {}
var playable_medal_buff_actions_cache := {}
var playable_medal_buff_index_cache := {}
var last_save_unix_time := 0
var last_save_monotonic_msec := -1
var save_dirty := false
var save_dirty_reason := ""
var allow_next_save_progress_regression := false
var save_reset_generation := 0
var visual_texture_cache := VisualTextureCache.new()
var texture_cache := visual_texture_cache.texture_cache
var atlas_texture_cache := visual_texture_cache.atlas_texture_cache
var home_page_built := false
var pending_post_load_saved_at: int:
	get:
		return _save_runtime().pending_post_load_saved_at
	set(value):
		_save_runtime().pending_post_load_saved_at = int(value)
var loaded_save_this_boot := false
var pending_save_restore_data: Dictionary:
	get:
		return _save_runtime().pending_save_restore_data
	set(value):
		_save_runtime().pending_save_restore_data = value
var save_repaired_this_boot: bool:
	get:
		return _save_runtime().save_repaired_this_boot
	set(value):
		_save_runtime().save_repaired_this_boot = bool(value)
var activity_queue_runtime: ActivityQueueRuntime
var save_runtime: SaveRuntime
var action_runtime: ActionRuntime
var fighting_runtime: FightingRuntime
var test_state_runtime: TestStateRuntime
var boot_warmup_runtime: BootWarmupRuntime
var app_lifecycle_runtime: AppLifecycleRuntime
var performance_runtime: PerformanceRuntime
var temporary_event_runtime: TemporaryEventRuntime
var crash_report_runtime: CrashReportRuntime
var ad_bonus_runtime: AdBonus
var leaderboard_http_built := false
var online_runtime: OnlineRuntime
var audio_director: AudioDirector
var leaderboard_presentation: LeaderboardPresentation
var leaderboard_state: LeaderboardState
var button_press_runtime: ButtonPressState
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
var boot_warmup_active := false
var boot_warmup_layer: CanvasLayer
var boot_warmup_overlay: Control
var boot_warmup_background: ColorRect
var boot_warmup_splash: Control
var boot_warmup_shade: ColorRect
var boot_warmup_footer: VBoxContainer
var boot_warmup_label: Label
var boot_warmup_progress: CleanProgressBar
var boot_warmup_cancel_requested := false
var boot_warmup_game_revealed := false
var boot_warmup_show_msec := 0
var boot_warmup_hide_requested := false
var lazy_overlays_built := {}
var deferred_skill_validation_pending := false
var boot_detail_card_yield := false
var boot_detail_render_in_progress := false
var boot_lazy_background_mount_allowed := false
var boot_post_load_simulation_scheduled: bool:
	get:
		return _save_runtime().boot_post_load_simulation_scheduled
	set(value):
		_save_runtime().boot_post_load_simulation_scheduled = bool(value)
var deferred_selected_skill_mastery_pending := false
var boot_detail_render_queue: Array = []
var boot_detail_completion_token := 0
var boot_detail_scroll_locked := false
var screen_render_in_progress := false
var screen_render_target_key := ""
var pending_screen_render_request := {}
var pending_skill_detail_refresh_request := {}
var detail_lazy_blank_repair_next_msec := 0
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
		_activity_data_catalog().load_action_data(self)
		_save_runtime()._init_state()
		_validate_state()
		get_tree().quit()
		return
	var crash_runtime := _crash_report_runtime()
	crash_runtime.start_session()
	crash_runtime.call_deferred("load_pending_crash_report")
	crash_runtime.call_deferred("synthesize_unclean_session_crash_report")
	crash_runtime.call_deferred("write_session_marker", "booting")
	_load_font()
	_boot_warmup_runtime()._build_boot_warmup_overlay()
	_boot_warmup_runtime()._show_boot_warmup_overlay()
	await _boot_warmup_runtime()._boot_progress_step("Loading data...", 0.08)
	_activity_data_catalog().load_action_data(self)
	_save_runtime()._init_state()
	await _boot_warmup_runtime()._boot_progress_step("Loading save...", 0.20)
	load_game()
	_settings_surface().apply_dark_mode_visual()
	if _crash_report_runtime().pending_report_exists():
		last_result = "Crash report ready in Settings."
	_select_launch_skill_page()
	_prepare_selected_skill_for_render(true)
	deferred_skill_validation_pending = true
	deferred_selected_skill_mastery_pending = true
	await _build_ui_boot_async()
	await _boot_warmup_runtime()._finish_boot_render_async()
	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_INTERVAL_SECONDS
	timer.autostart = true
	timer.timeout.connect(Callable(_save_runtime(), "_autosave_if_needed"))
	add_child(timer)
	if _performance_runtime()._performance_overlay_enabled_on_boot():
		_performance_runtime()._set_performance_overlay_enabled(true)
	if DisplayServer.get_name() == "headless":
		boot_warmup_active = false
	if _test_state_runtime()._headless_boot_smoke_mode():
		_test_state_runtime().call_deferred("_run_headless_boot_smoke")
	if web_fishing_perf_probe_enabled:
		_fishing_ui_surface().call_deferred("_run_web_fishing_perf_probe_setup")


func _finish_boot_skill_detail_extras() -> void:
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	var actions_clip := detail_actions_scroll.get_parent()
	if actions_clip == null or not is_instance_valid(actions_clip):
		return
	_skill_detail_surface()._build_detail_jump_arrows(actions_clip)
	_add_skill_detail_shadow_overlay(_skill_detail_shadow_top_y())
	call_deferred("_deferred_boot_swipe_preview_prewarm")


func _deferred_boot_swipe_preview_prewarm() -> void:
	await get_tree().create_timer(BOOT_SWIPE_PREWARM_DELAY_SECONDS).timeout
	if current_screen != "skill":
		return
	_skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()


func _battery_governor_visual_work_active() -> bool:
	if boot_warmup_active or boot_detail_render_in_progress or screen_render_in_progress:
		return true
	if detail_scroll_visual_work_this_frame or detail_lazy_mounted_this_frame:
		return true
	if _skill_swipe_loading_transition_active():
		return true
	if action_stop_hold_active or action_stop_hold_unloading or not action_card_press_key.is_empty():
		return true
	if _hub_surface().hub_drag_module_id != "" or _hub_surface().hub_hotspot_hold_module_id != "":
		return true
	if chat_keyboard_lift_active:
		return true
	if activity_start_highlight_active or activity_start_highlight_pending:
		return true
	if _achievement_toast_surface().transient_work_active():
		return true
	if _navigation_shell()._page_switch_pending_transition_queued() or module_ui_animating_collapse_key != "":
		return true
	if current_screen == "pinned" and _navigation_shell()._pinned_active_shelf_has_jailed_action():
		return true
	if pin_transition_blocker != null and is_instance_valid(pin_transition_blocker) and pin_transition_blocker.visible:
		return true
	if _skill_detail_surface()._detail_jump_arrows_need_processing():
		return true
	return _skill_detail_has_fishing_camera_returning()


func _process_detail_lazy_window(delta: float) -> int:
	if detail_lazy_plan.is_empty() or detail_lazy_stack == null:
		return 0
	if _fishing_ui_surface()._fishing_ablation_enabled("no_lazy") and _fishing_rework_active_for_skill(selected_skill_id):
		return 0
	if skill_swipe_finalized_lazy_mount_pending:
		return 0
	if skill_swipe_pending_full_finalize:
		return 0
	if _skill_swipe_handoff_cover_is_opaque_cream_transition():
		return 0
	if (
		_fishing_rework_active_for_skill(selected_skill_id)
		and detail_lazy_settle_warm_mount_skill_id == selected_skill_id
		and not detail_scroll_visual_work_this_frame
	):
		return 0
	detail_lazy_window_sync_elapsed += maxf(0.0, delta)
	if not _detail_lazy_window_scan_due():
		return 0
	detail_lazy_window_sync_elapsed = 0.0
	var mounted_count := 0
	if _detail_lazy_should_sync_visible_window():
		mounted_count = _skill_detail_surface()._sync_detail_lazy_visible_cards(true, DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME)
	if mounted_count > 0:
		detail_lazy_mounted_this_frame = true
		return mounted_count
	_skill_detail_surface()._prune_detail_lazy_far_cards(DETAIL_LAZY_UNMOUNT_BUDGET_PER_FRAME)
	return 0


func _detail_lazy_window_scan_due() -> bool:
	if detail_lazy_last_scroll < -0.5:
		return true
	if absf(_detail_lazy_scroll_y() - detail_lazy_last_scroll) > 8.0:
		return true
	if detail_lazy_window_sync_elapsed >= DETAIL_LAZY_WINDOW_SYNC_INTERVAL_SECONDS:
		return true
	if running_skill_id == selected_skill_id and not running_action_id.is_empty():
		var running_lazy_entry := _detail_lazy_entry_for_track_id(running_action_id)
		if not running_lazy_entry.is_empty() and not bool(running_lazy_entry.get("mounted", false)):
			return true
	return false


func _skill_swipe_loading_transition_active() -> bool:
	return (
		current_screen == "skill"
		and (
			skill_swipe_tracking
			or skill_swipe_animating
			or skill_swipe_pending_full_finalize
			or skill_swipe_defer_initial_lazy_mount
			or direct_skill_nav_cover_active
			or _navigation_shell()._page_switch_scroll_cover_active()
			or skill_swipe_outgoing_cover_active
			or skill_swipe_rebuild_cover_active
			or skill_swipe_queued_offset != 0
		)
	)


func _detail_scroll_visual_work_active() -> bool:
	if current_screen != "skill" or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		detail_background_maintenance_last_scroll = -1.0
		detail_scroll_visual_work_hold_frames = 0
		return false
	var scroll_y := _detail_lazy_scroll_y()
	var scroll_changed := detail_background_maintenance_last_scroll >= -0.5 and absf(scroll_y - detail_background_maintenance_last_scroll) > 0.5
	detail_background_maintenance_last_scroll = scroll_y
	var actively_scrolling := (
		scroll_changed
		or detail_actions_scroll.drag_scrolling
		or absf(detail_actions_scroll.velocity) >= 4.0
		or (detail_actions_scroll.scroll_tween != null and detail_actions_scroll.scroll_tween.is_valid())
	)
	if actively_scrolling:
		detail_scroll_visual_work_hold_frames = 8
		return true
	if _fishing_rework_active_for_skill(selected_skill_id) and detail_scroll_visual_work_hold_frames > 0:
		detail_scroll_visual_work_hold_frames -= 1
		return true
	return false


func _process(delta: float) -> void:
	if not startup_initialized:
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
	detail_lazy_mounted_this_frame = false
	var detail_scroll_visual_work := _detail_scroll_visual_work_active()
	detail_scroll_visual_work_this_frame = detail_scroll_visual_work
	_fishing_ui_surface()._process_fishing_scroll_mode(detail_scroll_visual_work)
	_skill_detail_surface()._process_detail_card_texture_prewarm()
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_prewarm_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	var detail_lazy_mounted_count := 0
	if detail_lazy_plan.size() > 0:
		detail_lazy_mounted_count = _process_detail_lazy_window(delta)
	_maybe_resume_fishing_detail_idle_warm_mount()
	_process_detail_lazy_settle_warm_mount()
	_fishing_ui_surface()._process_fishing_scroll_perf_probe(delta, detail_scroll_visual_work)
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_lazy_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	if detail_lazy_mounted_count > 0 or detail_scroll_visual_work or _skill_swipe_loading_transition_active():
		background_maintenance_elapsed += maxf(0.0, delta)
	else:
		UpdateProcessShell.process_background_maintenance(self, delta)
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_background_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	_process_stamina_gauge_regen_boost(delta)
	_regen_stamina(delta)
	_hub_surface()._process_hub_hotspot_hold(delta)
	if not _fishing_detail_should_defer_action_process_for_scroll():
		_action_runtime()._process_action(delta)
	_process_action_stop_hold(delta)
	_passive_firepit_surface()._process_firepit_stop_hold(delta)
	_temporary_event_runtime()._process_temporary_event_scheduler(delta)
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_action_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	_audio_director()._process_music_flow(delta)
	_profile_chat_overlay_surface()._process_chat_keyboard_lift(delta)
	_profile_chat_overlay_surface()._process_chat_enter_submit_poll()
	if not _fishing_detail_scroll_frame_can_skip_ui_update():
		_update_ui(delta)
	_maybe_release_ready_skill_swipe_cover()
	_navigation_shell()._process_page_switch_pending_transition()
	_process_pin_transition_blocker()
	if trace_process:
		var now_usec := Time.get_ticks_usec()
		trace_ui_us = now_usec - trace_last_usec
		trace_last_usec = now_usec
	if _fishing_detail_can_defer_scroll_bounds_work(detail_lazy_mounted_count):
		detail_actions_scroll_limit_elapsed += delta
	else:
		detail_actions_scroll_limit_elapsed += delta
		if detail_actions_scroll_limit_elapsed >= DETAIL_ACTIONS_SCROLL_LIMIT_REFRESH_SECONDS:
			detail_actions_scroll_limit_elapsed = 0.0
			_sync_detail_actions_scroll_limit()
	_clamp_detail_actions_scroll_to_content()
	_fishing_ui_surface()._sync_fishing_detail_render_culling()
	_audio_director()._process_chain_proximity_audio(delta)
	var defer_fishing_scroll_tail_work := _fishing_detail_can_defer_scroll_tail_work()
	if not defer_fishing_scroll_tail_work:
		_skill_detail_surface()._process_detail_jump_arrows(delta)
	_process_pending_swipe_preview_finalize()
	if not defer_fishing_scroll_tail_work:
		_maybe_repair_blank_detail_lazy_stack()
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
				str(detail_lazy_plan.size()),
				str(action_cards.size()),
				str(_skill_detail_has_visible_lazy_placeholders() if current_screen == "skill" else false)
			])


func _fishing_detail_scroll_frame_can_skip_ui_update() -> bool:
	if current_screen != "skill" or selected_skill_id != "fishing":
		return false
	if not detail_scroll_visual_work_this_frame:
		return false
	if running_skill_id == selected_skill_id and not running_action_id.is_empty():
		return false
	if event_running_skill_id == selected_skill_id and not event_running_action_id.is_empty():
		return false
	if skill_swipe_tracking or skill_swipe_animating:
		return false
	if action_stop_hold_active or not action_card_press_key.is_empty():
		return false
	if activity_start_highlight_active or activity_start_highlight_pending:
		return false
	if locked_activity_preview_fade_play_pending:
		return false
	if _pending_activity_has_readiness_for_skill(selected_skill_id) or activity_unlock_ceremony_count > 0:
		return false
	if _skill_detail_has_fishing_camera_returning():
		return false
	if _skill_swipe_activity_surface()._skill_swipe_previews_need_frame_updates():
		return false
	return true


func _fishing_detail_should_defer_action_process_for_scroll() -> bool:
	if current_screen != "skill" or selected_skill_id != "fishing":
		fishing_detail_primary_pointer_down = false
		return false
	if running_skill_id != "fishing" and event_running_skill_id != "fishing":
		return false
	var scroll := _valid_control_ref(detail_actions_scroll) as MobileScrollContainer
	if scroll == null:
		return false
	return fishing_detail_primary_pointer_down or fishing_scroll_mode_active or scroll.drag_tracking or scroll.drag_scrolling


func _update_fishing_detail_primary_pointer_down(event: InputEvent) -> void:
	if current_screen != "skill" or selected_skill_id != "fishing":
		fishing_detail_primary_pointer_down = false
		return
	var event_position := _input_routing_shell()._fishing_detail_event_position(event)
	if _is_primary_press_event(event):
		fishing_detail_primary_pointer_down = (
			event_position != Vector2.INF
			and _position_inside_detail_actions_viewport(event_position)
			and not _position_inside_bottom_interactive_ui(event_position)
		)
	elif _button_press_runtime()._input_event_releases_primary_pointer(event):
		fishing_detail_primary_pointer_down = false


func _fishing_detail_can_defer_scroll_bounds_work(detail_lazy_mounted_count: int) -> bool:
	if current_screen != "skill" or selected_skill_id != "fishing":
		return false
	if not detail_scroll_visual_work_this_frame:
		return false
	if detail_lazy_mounted_count > 0 or detail_lazy_mounted_this_frame:
		return false
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return false
	if boot_detail_scroll_locked or activity_unlock_ceremony_count > 0:
		return false
	if not detail_unlock_scroll_spacer_heights.is_empty():
		return false
	if activity_unlock_visual_scroll_tween != null and activity_unlock_visual_scroll_tween.is_valid():
		return false
	if detail_unlock_scroll_spacer_tween != null and detail_unlock_scroll_spacer_tween.is_valid():
		return false
	return true


func _fishing_detail_can_defer_scroll_tail_work() -> bool:
	if current_screen != "skill" or selected_skill_id != "fishing":
		return false
	if not detail_scroll_visual_work_this_frame:
		return false
	if skill_swipe_tracking or skill_swipe_animating:
		return false
	if detail_lazy_plan.is_empty():
		return false
	if activity_unlock_ceremony_count > 0 or boot_detail_render_in_progress:
		return false
	if _skill_detail_surface()._detail_jump_arrows_need_processing():
		return false
	return true


func _unhandled_input(_event: InputEvent) -> void:
	pass


func _input(event: InputEvent) -> void:
	_input_routing_shell().input(event)


func _fishing_detail_scroll_container_should_own_event(event: InputEvent) -> bool:
	if current_screen != "skill" or selected_skill_id != "fishing":
		return false
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return false
	if not detail_actions_scroll.is_visible_in_tree():
		return false
	if not (event is InputEventMouseMotion or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventScreenTouch):
		return false
	var event_position := _input_routing_shell()._fishing_detail_event_position(event)
	if event_position == Vector2.INF or not _position_inside_detail_actions_viewport(event_position):
		return false
	if _position_inside_bottom_interactive_ui(event_position):
		return false
	if page_switch_press_active or module_ui_pin_press_active or action_stop_hold_active:
		return false
	if fishing_method_button_press_active or fishing_offer_button_press_active:
		return false
	if skill_swipe_tracking and skill_swipe_horizontal:
		return false
	if skill_swipe_tracking and not skill_swipe_horizontal:
		return false
	if detail_actions_scroll.drag_scrolling:
		return true
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		return detail_actions_scroll.drag_tracking and detail_actions_scroll.drag_touch_index == drag_event.index
	if event is InputEventMouseMotion:
		return detail_actions_scroll.drag_tracking and detail_actions_scroll.drag_touch_index < 0
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return not touch_event.pressed and detail_actions_scroll.drag_tracking and detail_actions_scroll.drag_touch_index == touch_event.index
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and not mouse_event.pressed
			and detail_actions_scroll.drag_tracking
			and detail_actions_scroll.drag_touch_index < 0
		)
	return false


func _fishing_detail_scroll_event_bypasses_global_input(event: InputEvent) -> bool:
	if current_screen != "skill" or selected_skill_id != "fishing":
		return false
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return false
	if not detail_actions_scroll.is_visible_in_tree():
		return false
	var event_position := _input_routing_shell()._fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return false
	if _position_inside_bottom_interactive_ui(event_position):
		return false
	if not _position_inside_detail_actions_viewport(event_position):
		return false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN or mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP
	if event is InputEventMouseMotion:
		return detail_actions_scroll.drag_tracking and detail_actions_scroll.drag_touch_index < 0
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		return detail_actions_scroll.drag_tracking and detail_actions_scroll.drag_touch_index == drag_event.index
	return false


func _fishing_detail_primary_press_skips_global_button_scan(event: InputEvent) -> bool:
	var trace_enabled := _fishing_ui_surface()._fishing_input_trace_enabled()
	var step_usec := Time.get_ticks_usec() if trace_enabled else 0
	if current_screen != "skill" or selected_skill_id != "fishing":
		return false
	var event_position := Vector2.INF
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return false
		event_position = mouse_event.global_position
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			return false
		event_position = touch_event.position
	else:
		return false
	if event_position == Vector2.INF:
		return false
	_fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_position", step_usec, event)
	step_usec = Time.get_ticks_usec() if trace_enabled else 0
	if _position_inside_bottom_interactive_ui(event_position):
		_fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_bottom_ui_true", step_usec, event)
		return false
	_fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_bottom_ui_false", step_usec, event)
	step_usec = Time.get_ticks_usec() if trace_enabled else 0
	if _input_routing_shell()._page_switch_button_control_at_position(event_position) != null:
		_fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_page_switch_true", step_usec, event)
		return false
	_fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_page_switch_false", step_usec, event)
	step_usec = Time.get_ticks_usec() if trace_enabled else 0
	var inside_detail := _position_inside_detail_actions_viewport(event_position)
	_fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_detail_viewport", step_usec, event)
	return inside_detail


func _fishing_detail_primary_press_started_on_fast_button(event: InputEvent) -> bool:
	if current_screen != "skill" or selected_skill_id != "fishing":
		return false
	if not _is_primary_press_event(event):
		return false
	var event_position := _input_routing_shell()._fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return false
	if _position_inside_bottom_interactive_ui(event_position):
		return true
	return _input_routing_shell()._page_switch_button_control_at_position(event_position) != null


func _fishing_detail_primary_press_should_defer_tap_scan(event: InputEvent) -> bool:
	var trace_enabled := _fishing_ui_surface()._fishing_input_trace_enabled()
	var step_usec := Time.get_ticks_usec() if trace_enabled else 0
	if not _fishing_detail_primary_press_skips_global_button_scan(event):
		_fishing_ui_surface()._trace_fishing_input_duration("fishing_defer_skip_scan_false", step_usec, event)
		return false
	_fishing_ui_surface()._trace_fishing_input_duration("fishing_defer_skip_scan_true", step_usec, event)
	step_usec = Time.get_ticks_usec() if trace_enabled else 0
	if fishing_detail_swipe_press_active:
		return false
	if queue_selection_mode:
		return false
	if page_switch_press_active or module_ui_pin_press_active or action_stop_hold_active:
		return false
	if fishing_method_button_press_active or fishing_offer_button_press_active:
		return false
	if skill_swipe_tracking or skill_swipe_animating:
		return false
	var event_position := _input_routing_shell()._fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return false
	_fishing_ui_surface()._trace_fishing_input_duration("fishing_defer_remaining_guards", step_usec, event)
	return true


func _route_pinned_shelf_action_card_input(event: InputEvent) -> bool:
	if current_screen != "skill":
		return false
	if _is_primary_press_event(event) and _event_points_inside_bottom_interactive_ui(event):
		return false
	if selected_skill_id == "fishing" and not action_card_press_key.begins_with("pinned_shelf:"):
		var fishing_event_position := _input_routing_shell()._fishing_detail_event_position(event)
		if fishing_event_position != Vector2.INF and _position_inside_detail_actions_viewport(fishing_event_position):
			return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		var event_position := _global_event_position(mouse_event.position, mouse_event.global_position)
		if mouse_event.pressed:
			var action_hit := _skill_detail_surface()._module_action_circle_at_position(event_position)
			if _non_shelf_pin_center_hit(action_hit, event_position):
				return false
			var card_hit := _pinned_shelf_action_card_at_position(event_position)
			if card_hit.is_empty():
				return false
			var card := card_hit.get("card", {}) as Dictionary
			action_card_press_consumed = false
			var routed := _begin_pinned_shelf_action_card_press(card, event_position, -1)
			return routed
		if action_card_press_key.begins_with("pinned_shelf:"):
			return _input_routing_shell()._route_action_card_release(event)
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			var action_hit := _skill_detail_surface()._module_action_circle_at_position(touch_event.position)
			if _non_shelf_pin_center_hit(action_hit, touch_event.position):
				return false
			var card_hit := _pinned_shelf_action_card_at_position(touch_event.position)
			if card_hit.is_empty():
				return false
			var card := card_hit.get("card", {}) as Dictionary
			action_card_press_consumed = false
			var routed := _begin_pinned_shelf_action_card_press(card, touch_event.position, touch_event.index)
			return routed
		if action_card_press_key.begins_with("pinned_shelf:"):
			return _input_routing_shell()._route_action_card_release(event)
	return false


func _non_shelf_pin_center_hit(action_hit: Dictionary, event_position: Vector2) -> bool:
	if action_hit.is_empty():
		return false
	if str(action_hit.get("kind", "")) != "pin":
		return false
	if str(action_hit.get("module_key", "")).begins_with("pinned_shelf:"):
		return false
	var host := _valid_control_ref(action_hit.get("host", null))
	if host == null:
		return false
	return true


func _pinned_shelf_action_card_at_position(event_position: Vector2) -> Dictionary:
	if current_screen != "skill" or not _position_inside_detail_actions_viewport(event_position):
		return {}
	var keys := action_card_keys.duplicate()
	keys.reverse()
	for raw_action_key in action_cards.keys():
		var action_key := str(raw_action_key)
		if action_key.begins_with("pinned_shelf:") and not keys.has(action_key):
			keys.push_front(action_key)
	for raw_key in keys:
		var key := str(raw_key)
		if not key.begins_with("pinned_shelf:") or not action_cards.has(key):
			continue
		var card := action_cards[key] as Dictionary
		var pop := _valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		if not pop.get_global_rect().has_point(event_position):
			continue
		var skill_id := str(card.get("skill_id", ""))
		var action_id := str(card.get("action_id", ""))
		if skill_id.is_empty() or action_id.is_empty():
			continue
		var action := _action_data(skill_id, action_id)
		if action.is_empty() or _is_passive_action(action):
			continue
		if bool(card.get("unlock_ceremony_active", false)) or bool(card.get("unlock_ceremony_pending", false)):
			continue
		if not _skill_detail_surface()._module_action_zone_kind_at_position(pop, event_position).is_empty():
			return {}
		return {
			"card": card,
			"skill_id": skill_id,
			"action_id": action_id
		}
	return {}


func _begin_pinned_shelf_action_card_press(card: Dictionary, press_position: Vector2, pointer_id := -1) -> bool:
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("action_id", ""))
	var action := _action_data(skill_id, action_id)
	if _input_routing_shell()._activity_card_is_locked_or_covered(skill_id, action, card):
		_cancel_action_stop_hold()
		return false
	if running_skill_id == skill_id and running_action_id == action_id:
		if _action_runtime()._try_action_opportunity_click(skill_id, action_id, press_position):
			action_card_press_consumed = true
			_cancel_action_stop_hold()
			skill_swipe_tracking = false
			skill_swipe_horizontal = false
			skill_swipe_touch_index = -1
			return true
	var stat_kind := _activity_stat_kind_at_position(card, press_position)
	if stat_kind.is_empty() and _action_card_medal_hit_at_position(card, press_position):
		stat_kind = ACTION_CARD_MEDAL_PRESS_KIND
	if stat_kind.is_empty() and running_skill_id == skill_id and running_action_id == action_id:
		if _action_runtime()._miss_action_opportunity_click(skill_id, action_id, press_position):
			action_card_press_consumed = true
			_cancel_action_stop_hold()
			skill_swipe_tracking = false
			skill_swipe_horizontal = false
			skill_swipe_touch_index = -1
			return true
		_begin_action_stop_hold(skill_id, action_id, press_position, pointer_id)
		return true
	var scroll := _valid_control_ref(detail_actions_scroll) as MobileScrollContainer
	if scroll != null:
		scroll.prepare_child_tap()
	action_card_press_key = str(card.get("card_key", _action_key(skill_id, action_id)))
	action_card_press_position = press_position
	action_card_press_stat_kind = stat_kind
	action_card_press_dragged = false
	if stat_kind.is_empty():
		_skill_swipe_activity_surface()._queue_action_card_3d_press(action_card_press_key)
	return true


func _begin_skill_swipe_tracking(pointer_position: Vector2, touch_index: int) -> void:
	if _onboarding_runtime()._onboarding_blocks_skill_swipe():
		if not _onboarding_runtime()._ensure_onboarding_swipe_unlocked(true):
			return
	_cancel_detail_lazy_settle_warm_mount()
	if not _skill_swipe_animation_blocks_input():
		_skill_swipe_activity_surface()._cancel_preview_prewarm()
		_interrupt_skill_swipe_animation_for_input()
		_skill_swipe_activity_surface()._park_skill_swipe_preview()
	skill_swipe_tracking = true
	skill_swipe_horizontal = false
	skill_swipe_start = pointer_position
	skill_swipe_last = pointer_position
	skill_swipe_drag_base_x = _current_skill_swipe_page_x()
	skill_swipe_touch_index = touch_index
	skill_swipe_strip_committed_crossfade = false
	_skill_detail_surface()._queue_skill_detail_and_swipe_texture_prewarm(selected_skill_id)
	_sync_skill_strip_page_visibility(true)


func _route_skill_swipe_button_input(event: InputEvent, source: Control = null) -> bool:
	if current_screen != "skill":
		return false
	if _navigation_shell()._event_points_inside_bottom_nav(event, source):
		_cancel_skill_swipe_feedback(false)
		action_card_press_key = ""
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		var event_position := _global_event_position(mouse_event.position, mouse_event.global_position, source)
		if mouse_event.pressed:
			_begin_skill_swipe_tracking(event_position, -1)
		elif skill_swipe_tracking:
			_finish_skill_swipe(event_position)
		return true
	if event is InputEventMouseMotion and skill_swipe_tracking:
		var motion_event := event as InputEventMouseMotion
		_update_skill_swipe_feedback(_global_event_position(motion_event.position, motion_event.global_position, source))
		return true
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		var event_position := _global_event_position(touch_event.position, touch_event.position, source)
		if touch_event.pressed:
			_begin_skill_swipe_tracking(event_position, touch_event.index)
		elif skill_swipe_tracking and touch_event.index == skill_swipe_touch_index:
			_finish_skill_swipe(event_position)
		return true
	if event is InputEventScreenDrag and skill_swipe_tracking:
		var drag_event := event as InputEventScreenDrag
		if drag_event.index == skill_swipe_touch_index:
			_update_skill_swipe_feedback(_global_event_position(drag_event.position, drag_event.position, source))
			return true
	return false


func _event_points_inside_bottom_interactive_ui(event: InputEvent, source: Control = null, nav_only := false) -> bool:
	var positions: Array[Vector2] = []
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		_add_unique_event_position(positions, _global_event_position(mouse_event.position, mouse_event.global_position, source))
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_add_unique_event_position(positions, _global_event_position(motion_event.position, motion_event.global_position, source))
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		_add_unique_event_position(positions, _global_event_position(touch_event.position, touch_event.position, source))
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_add_unique_event_position(positions, _global_event_position(drag_event.position, drag_event.position, source))
	for event_position in positions:
		if nav_only:
			if _navigation_shell()._position_inside_bottom_nav(event_position):
				return true
		elif _position_inside_bottom_interactive_ui(event_position):
			return true
	return false


func _position_inside_bottom_interactive_ui(event_position: Vector2) -> bool:
	for raw_control in [_navigation_shell().module_sort_menu, _navigation_shell().module_utility_row, chat_strip, nav_bar]:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
			continue
		var control_rect := control.get_global_rect().grow(4.0)
		if control_rect.has_point(event_position):
			return true
	return false


func _position_inside_detail_actions_viewport(event_position: Vector2, viewport_outset := 2.0) -> bool:
	var viewport_control: Control = null
	if current_screen == "skill":
		viewport_control = detail_actions_scroll
	elif current_screen == "pinned" or current_screen == "queue":
		viewport_control = content_scroll
	elif current_screen == "menu":
		return _position_inside_skill_menu_active_drawer(event_position)
	if viewport_control == null or not is_instance_valid(viewport_control):
		return false
	if not viewport_control.is_visible_in_tree():
		return false
	var viewport_rect := viewport_control.get_global_rect().grow(viewport_outset)
	for candidate in _activity_input_position_candidates(event_position):
		if viewport_rect.has_point(candidate):
			return true
	if current_screen == "queue":
		for candidate in _activity_input_position_candidates(event_position):
			if _queue_page_activity_card_contains_position(candidate):
				return true
	return false


func _queue_page_activity_card_contains_position(event_position: Vector2) -> bool:
	_prune_invalid_action_cards()
	for raw_key in action_card_keys:
		var key := str(raw_key)
		if not key.begins_with("queue_page:") or not action_cards.has(key):
			continue
		var card := action_cards.get(key, {}) as Dictionary
		if card.is_empty():
			continue
		var module_key := _skill_swipe_activity_surface()._activity_queue_module_key_for_card(card)
		if module_key.is_empty() or not _activity_queue_runtime().is_activity_queued(module_key):
			continue
		var pop := _valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		if pop.get_global_rect().grow(2.0).has_point(event_position):
			return true
	return false


func _position_inside_skill_menu_active_drawer(event_position: Vector2) -> bool:
	for raw_drawer in skill_menu_active_drawers.values():
		if typeof(raw_drawer) != TYPE_DICTIONARY:
			continue
		var drawer := raw_drawer as Dictionary
		var slot := drawer.get("slot") as Control
		if slot == null or not is_instance_valid(slot) or not slot.is_visible_in_tree():
			continue
		var drawer_rect := slot.get_global_rect().grow(2.0)
		for candidate in _activity_input_position_candidates(event_position):
			if drawer_rect.has_point(candidate):
				return true
	return false


func _positions_inside_detail_actions_viewport(positions: Array[Vector2], viewport_outset := 2.0) -> bool:
	for event_position in positions:
		if _position_inside_detail_actions_viewport(event_position, viewport_outset):
			return true
	return false


func _event_points_inside_detail_actions_viewport(event: InputEvent, source: Control = null, viewport_outset := 2.0) -> bool:
	var positions: Array[Vector2] = []
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		_add_unique_event_position(positions, _global_event_position(mouse_event.position, mouse_event.global_position, source))
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_add_unique_event_position(positions, _global_event_position(motion_event.position, motion_event.global_position, source))
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		_add_unique_event_position(positions, _global_event_position(touch_event.position, touch_event.position, source))
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_add_unique_event_position(positions, _global_event_position(drag_event.position, drag_event.position, source))
	return _positions_inside_detail_actions_viewport(positions, viewport_outset)


func _global_event_position(local_position: Vector2, event_global_position: Vector2, source: Control = null) -> Vector2:
	if source != null and is_instance_valid(source):
		var source_local_rect := Rect2(Vector2.ZERO, source.size)
		if event_global_position.distance_squared_to(local_position) <= 0.25 and source_local_rect.has_point(local_position):
			return source.get_global_position() + local_position
	if event_global_position != Vector2.ZERO:
		return event_global_position
	if source != null and is_instance_valid(source):
		return source.get_global_position() + local_position
	return local_position


func _route_detail_back_button_input(event: InputEvent) -> bool:
	if current_screen != "skill" or detail_back_button == null or not is_instance_valid(detail_back_button):
		detail_back_press_active = false
		detail_back_press_touch_index = -1
		return false
	var event_position := Vector2.ZERO
	var pressed := false
	var released := false
	var is_motion := false
	var touch_index := -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		event_position = event.global_position
		pressed = event.pressed
		released = not event.pressed
	elif event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_motion = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		touch_index = touch_event.index
		pressed = touch_event.pressed
		released = not touch_event.pressed
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		event_position = drag_event.position
		touch_index = drag_event.index
		is_motion = true
	else:
		return false
	if pressed:
		if not _detail_back_button_contains_position(event_position):
			return false
		detail_back_press_active = true
		detail_back_press_touch_index = touch_index
		action_card_press_key = ""
		action_card_press_stat_kind = ""
		action_card_press_dragged = false
		_cancel_skill_swipe_feedback(false)
		return true
	if not detail_back_press_active:
		return false
	if touch_index >= 0 and detail_back_press_touch_index >= 0 and touch_index != detail_back_press_touch_index:
		return false
	if is_motion:
		return true
	if released:
		detail_back_press_active = false
		detail_back_press_touch_index = -1
		if _detail_back_button_contains_position(event_position):
			_show_skills()
		return true
	return false


func _detail_back_button_contains_position(event_position: Vector2) -> bool:
	if detail_back_button == null or not is_instance_valid(detail_back_button):
		return false
	var back_rect := detail_back_button.get_global_rect().grow(36.0)
	return _first_position_in_rect(_activity_input_position_candidates(event_position), back_rect) != null


func _route_passive_button_global_input(event: InputEvent) -> bool:
	if passive_button_press_source == null or not is_instance_valid(passive_button_press_source):
		return false
	var event_position := Vector2.ZERO
	var is_drag := false
	var is_release := false
	if event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_drag = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		event_position = (event as InputEventMouseButton).global_position
		is_release = not (event as InputEventMouseButton).pressed
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		is_drag = true
	elif event is InputEventScreenTouch and (passive_button_press_touch_index < 0 or (event as InputEventScreenTouch).index == passive_button_press_touch_index):
		event_position = (event as InputEventScreenTouch).position
		is_release = not (event as InputEventScreenTouch).pressed
	if not is_drag and not is_release:
		return false
	if event_position.distance_to(passive_button_press_position) > PASSIVE_BUTTON_TAP_RELEASE_SLOP:
		passive_button_press_dragged = true
		passive_button_pending_tap_id += 1
		skill_swipe_button_suppressed_until_msec = Time.get_ticks_msec() + SKILL_SWIPE_BUTTON_SUPPRESS_MSEC
	if is_release and passive_button_press_dragged:
		_clear_passive_button_press()
		return true
	return false


func _route_passive_info_button_press(event: InputEvent) -> bool:
	var event_position := Vector2.ZERO
	var touch_index := -1
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		pressed = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		touch_index = touch_event.index
		pressed = touch_event.pressed
	if not pressed:
		return false
	if _position_inside_bottom_interactive_ui(event_position):
		return false
	if not _position_inside_detail_actions_viewport(event_position):
		return false
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if not bool(card.get("passive", false)):
			continue
		var info_button := _valid_control_ref(card.get("info_button"))
		var info_popover := _valid_control_ref(card.get("info_popover"))
		var action := card.get("action", {}) as Dictionary
		if info_button == null or info_popover == null or action.is_empty():
			continue
		if not info_button.is_visible_in_tree():
			continue
		if not info_button.get_global_rect().grow(8.0).has_point(event_position):
			continue
		var module_id := str(action.get("id", PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID))
		passive_button_press_source = info_button
		passive_button_press_kind = "info"
		passive_button_press_module_id = module_id
		passive_button_press_stat_type = ""
		passive_button_press_popover = info_popover
		passive_button_press_position = event_position
		passive_button_press_dragged = false
		passive_button_press_touch_index = touch_index
		_begin_skill_swipe_tracking(event_position, touch_index)
		return true
	return false


func _schedule_passive_info_click_away_dismiss(event: InputEvent) -> void:
	var event_position := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		pressed = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if not bool(card.get("passive", false)):
			continue
		var info_popover := _valid_control_ref(card.get("info_popover"))
		if info_popover == null or not info_popover.visible:
			continue
		var info_button := _valid_control_ref(card.get("info_button"))
		if info_button != null and info_button.get_global_rect().grow(8.0).has_point(event_position):
			continue
		if info_popover.get_global_rect().grow(8.0).has_point(event_position):
			continue
		_passive_firepit_surface()._schedule_passive_info_popover_dismiss(info_popover)


func _hide_skill_header_info_on_outside_press(event: InputEvent) -> void:
	var event_position := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		pressed = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	var visible_popovers: Array[Control] = []
	for raw_popover in get_tree().get_nodes_in_group("skill_header_info_popovers"):
		var popover := raw_popover as Control
		if popover != null and is_instance_valid(popover) and popover.visible:
			visible_popovers.append(popover)
	if visible_popovers.is_empty():
		return
	for raw_button in get_tree().get_nodes_in_group("skill_header_info_buttons"):
		var button := raw_button as Control
		if button != null and is_instance_valid(button) and button.get_global_rect().grow(8.0).has_point(event_position):
			return
	for popover in visible_popovers:
		if popover.get_global_rect().grow(8.0).has_point(event_position):
			return
	for popover in visible_popovers:
		_passive_firepit_surface()._hide_passive_info_popover(popover)


func _route_action_stop_hold_input(event: InputEvent) -> bool:
	if not action_stop_hold_active and not action_stop_hold_unloading:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and action_stop_hold_pointer_id >= 0:
		return true
	if event is InputEventMouseMotion and action_stop_hold_pointer_id >= 0:
		return true
	if event is InputEventScreenTouch and action_stop_hold_pointer_id < 0:
		return true
	if event is InputEventScreenDrag and action_stop_hold_pointer_id < 0:
		return true
	if event is InputEventMouseMotion and action_stop_hold_active and action_stop_hold_pointer_id < 0:
		var event_position := (event as InputEventMouseMotion).global_position
		if _action_stop_hold_motion_is_scroll_drag(event_position):
			_cancel_action_stop_hold()
			return false
		if not action_stop_hold_armed:
			return _handoff_action_stop_hold_to_swipe_if_needed(event_position)
		if _cancel_action_stop_hold_if_pointer_left_start_circle(event_position):
			return true
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and action_stop_hold_pointer_id < 0:
		if not event.pressed and action_stop_hold_active:
			if not action_stop_hold_armed:
				_finish_pending_action_stop_hold_click(event.global_position)
			_cancel_action_stop_hold()
		return true
	if event is InputEventScreenDrag and action_stop_hold_active and event.index == action_stop_hold_pointer_id:
		var event_position := (event as InputEventScreenDrag).position
		if _action_stop_hold_motion_is_scroll_drag(event_position):
			_cancel_action_stop_hold()
			return false
		if not action_stop_hold_armed:
			return _handoff_action_stop_hold_to_swipe_if_needed(event_position)
		if _cancel_action_stop_hold_if_pointer_left_start_circle(event_position):
			return true
		return true
	if event is InputEventScreenTouch and event.index == action_stop_hold_pointer_id:
		if not event.pressed and action_stop_hold_active:
			if not action_stop_hold_armed:
				_finish_pending_action_stop_hold_click(event.position)
			_cancel_action_stop_hold()
		return true
	return action_stop_hold_unloading


func _begin_action_stop_hold(skill_id: String, action_id: String, pointer_position: Vector2, pointer_id: int) -> void:
	action_stop_hold_active = true
	action_stop_hold_armed = false
	action_stop_hold_unloading = false
	action_stop_hold_skill_id = skill_id
	action_stop_hold_action_id = action_id
	action_stop_hold_elapsed = 0.0
	action_stop_hold_unload_elapsed = 0.0
	action_stop_hold_pointer_id = pointer_id
	action_stop_hold_start_position = pointer_position
	action_card_press_key = ""
	action_card_press_stat_kind = ""
	action_card_press_dragged = false
	_update_action_stop_hold_position(pointer_position)
	_hide_action_stop_hold_circle()


func _process_action_stop_hold(delta: float) -> void:
	if not action_stop_hold_active and not action_stop_hold_unloading:
		return
	if (
		running_skill_id != action_stop_hold_skill_id
		or running_action_id != action_stop_hold_action_id
		or running_action_id.is_empty()
	):
		_cancel_action_stop_hold()
		return
	if action_stop_hold_unloading:
		action_stop_hold_unload_elapsed += delta
		var unload := clampf(action_stop_hold_unload_elapsed / ACTION_STOP_HOLD_UNLOAD_SECONDS, 0.0, 1.0)
		_sync_action_stop_hold_circle(1.0, unload, true)
		if unload >= 1.0:
			var skill_id := action_stop_hold_skill_id
			var action_id := action_stop_hold_action_id
			var action_key := _action_key(skill_id, action_id)
			_hide_action_stop_hold_circle()
			_skill_swipe_activity_surface()._release_action_card_3d_press(action_key)
			_clear_action_stop_hold_state()
			_action_runtime()._stop_running_action(skill_id, action_id)
		return
	if not action_stop_hold_armed:
		if action_stop_hold_pointer_id < 0 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_cancel_action_stop_hold()
			return
		action_stop_hold_elapsed += delta
		if action_stop_hold_elapsed < ACTION_STOP_HOLD_ARM_DELAY_SECONDS:
			return
		action_stop_hold_armed = true
		action_stop_hold_elapsed = 0.0
		skill_swipe_tracking = false
		skill_swipe_horizontal = false
		skill_swipe_touch_index = -1
		_skill_swipe_activity_surface()._press_action_card_3d(_action_key(action_stop_hold_skill_id, action_stop_hold_action_id))
		_show_action_stop_hold_circle()
		return
	action_stop_hold_elapsed += delta
	var progress := clampf(action_stop_hold_elapsed / ACTION_STOP_HOLD_SECONDS, 0.0, 1.0)
	_sync_action_stop_hold_circle(progress, 0.0, false)
	if progress >= 1.0:
		action_stop_hold_active = false
		action_stop_hold_unloading = true
		action_stop_hold_unload_elapsed = 0.0
		_sync_action_stop_hold_circle(1.0, 0.0, true)


func _update_action_stop_hold_position(pointer_position: Vector2) -> void:
	action_stop_hold_position = pointer_position
	if action_stop_hold_circle != null and is_instance_valid(action_stop_hold_circle) and not action_stop_hold_circle.is_queued_for_deletion():
		action_stop_hold_circle.position = pointer_position - ACTION_STOP_HOLD_RING_SIZE * 0.5


func _handoff_action_stop_hold_to_swipe_if_needed(pointer_position: Vector2) -> bool:
	if pointer_position.distance_to(action_stop_hold_start_position) < SKILL_SWIPE_FEEDBACK_DEADZONE:
		return true
	var start_position := action_stop_hold_start_position
	var pointer_id := action_stop_hold_pointer_id
	_cancel_action_stop_hold()
	_begin_skill_swipe_tracking(start_position, pointer_id)
	_update_skill_swipe_feedback(pointer_position)
	return true


func _cancel_action_stop_hold_if_pointer_left_start_circle(pointer_position: Vector2) -> bool:
	if _action_stop_hold_pointer_inside_start_circle(pointer_position):
		return false
	_cancel_action_stop_hold()
	return true


func _action_stop_hold_pointer_inside_start_circle(pointer_position: Vector2) -> bool:
	var radius := minf(ACTION_STOP_HOLD_RING_SIZE.x, ACTION_STOP_HOLD_RING_SIZE.y) * 0.5
	return pointer_position.distance_to(action_stop_hold_start_position) <= radius


func _finish_pending_action_stop_hold_click(release_position: Vector2) -> void:
	if release_position.distance_to(action_stop_hold_start_position) > ACTION_CARD_TAP_RELEASE_SLOP:
		return
	_action_runtime()._miss_action_opportunity_click(action_stop_hold_skill_id, action_stop_hold_action_id, release_position)


func _show_action_stop_hold_circle() -> void:
	_ensure_action_stop_hold_circle()
	if action_stop_hold_circle == null or not is_instance_valid(action_stop_hold_circle) or action_stop_hold_circle.is_queued_for_deletion():
		return
	action_stop_hold_circle.theme_color = _skill_theme_color(action_stop_hold_skill_id)
	action_stop_hold_circle.size = ACTION_STOP_HOLD_RING_SIZE
	action_stop_hold_circle.position = action_stop_hold_position - ACTION_STOP_HOLD_RING_SIZE * 0.5
	_set_canvas_item_modulate_if_changed(action_stop_hold_circle, Color.WHITE)
	_set_canvas_item_visible_if_changed(action_stop_hold_circle, true)
	action_stop_hold_circle.set_progress(0.0, 0.0, false)


func _ensure_action_stop_hold_circle() -> void:
	if action_stop_hold_layer == null or not is_instance_valid(action_stop_hold_layer):
		action_stop_hold_layer = CanvasLayer.new()
		action_stop_hold_layer.layer = 140
		add_child(action_stop_hold_layer)
	if action_stop_hold_circle == null or not is_instance_valid(action_stop_hold_circle):
		action_stop_hold_circle = StopHoldCircle.new()
		action_stop_hold_circle.size = ACTION_STOP_HOLD_RING_SIZE
		_set_canvas_item_visible_if_changed(action_stop_hold_circle, false)
		action_stop_hold_layer.add_child(action_stop_hold_circle)


func _sync_action_stop_hold_circle(progress: float, unload: float, unloading: bool) -> void:
	if action_stop_hold_circle == null or not is_instance_valid(action_stop_hold_circle) or action_stop_hold_circle.is_queued_for_deletion():
		return
	action_stop_hold_circle.position = action_stop_hold_position - ACTION_STOP_HOLD_RING_SIZE * 0.5
	action_stop_hold_circle.set_progress(progress, unload, unloading)


func _hide_action_stop_hold_circle() -> void:
	if action_stop_hold_circle != null and is_instance_valid(action_stop_hold_circle) and not action_stop_hold_circle.is_queued_for_deletion():
		_set_canvas_item_visible_if_changed(action_stop_hold_circle, false)
		action_stop_hold_circle.set_progress(0.0, 0.0, false)


func _cancel_action_stop_hold() -> void:
	var action_key := _action_key(action_stop_hold_skill_id, action_stop_hold_action_id) if not action_stop_hold_skill_id.is_empty() and not action_stop_hold_action_id.is_empty() else ""
	_hide_action_stop_hold_circle()
	_skill_swipe_activity_surface()._release_action_card_3d_press(action_key)
	_clear_action_stop_hold_state()


func _clear_action_stop_hold_state() -> void:
	action_stop_hold_active = false
	action_stop_hold_armed = false
	action_stop_hold_unloading = false
	action_stop_hold_skill_id = ""
	action_stop_hold_action_id = ""
	action_stop_hold_elapsed = 0.0
	action_stop_hold_unload_elapsed = 0.0
	action_stop_hold_pointer_id = -1
	action_stop_hold_start_position = Vector2.ZERO

func _fishing_detail_input_context_active() -> bool:
	if current_screen == "skill":
		return selected_skill_id == "fishing"
	return current_screen == "pinned" or current_screen == "queue"


func _begin_fishing_detail_deferred_swipe_if_press(event: InputEvent) -> void:
	var press_position := Vector2.INF
	var touch_index := -1
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
				_clear_fishing_detail_deferred_swipe()
			return
		press_position = mouse_event.global_position
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			if fishing_detail_swipe_press_touch_index < 0 or touch_event.index == fishing_detail_swipe_press_touch_index:
				_clear_fishing_detail_deferred_swipe()
			return
		press_position = touch_event.position
		touch_index = touch_event.index
	else:
		return
	fishing_detail_swipe_press_active = true
	fishing_detail_swipe_press_position = press_position
	fishing_detail_swipe_press_touch_index = touch_index
	skill_swipe_tracking = false
	skill_swipe_horizontal = false
	skill_swipe_touch_index = -1


func _route_fishing_detail_deferred_swipe_input(event: InputEvent) -> bool:
	if not fishing_detail_swipe_press_active:
		return false
	if current_screen != "skill" or selected_skill_id != "fishing":
		_clear_fishing_detail_deferred_swipe()
		return false
	var event_position := Vector2.INF
	var is_motion := false
	var is_release := false
	if event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_motion = true
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		event_position = (event as InputEventMouseButton).global_position
		is_release = not (event as InputEventMouseButton).pressed
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if fishing_detail_swipe_press_touch_index >= 0 and drag_event.index != fishing_detail_swipe_press_touch_index:
			return false
		event_position = drag_event.position
		is_motion = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if fishing_detail_swipe_press_touch_index >= 0 and touch_event.index != fishing_detail_swipe_press_touch_index:
			return false
		event_position = touch_event.position
		is_release = not touch_event.pressed
	if is_release:
		var press_position := fishing_detail_swipe_press_position
		var touch_index := fishing_detail_swipe_press_touch_index
		_clear_fishing_detail_deferred_swipe()
		if (
			event_position != Vector2.INF
			and event_position.distance_to(press_position) <= PASSIVE_BUTTON_TAP_RELEASE_SLOP
			and _position_inside_detail_actions_viewport(event_position)
			and not _position_inside_bottom_interactive_ui(event_position)
			and not _skill_swipe_suppresses_button_action()
		):
			return _route_fishing_detail_deferred_tap_release(event_position, touch_index)
		return false
	if not is_motion or event_position == Vector2.INF:
		return false
	var drag_offset := event_position - fishing_detail_swipe_press_position
	if (
		absf(drag_offset.y) >= ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	):
		return _try_handoff_fishing_deferred_vertical_scroll(event, event_position)
	if not (
		absf(drag_offset.x) >= ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.x) > absf(drag_offset.y) * 1.15
	):
		return false
	var start_position := fishing_detail_swipe_press_position
	var touch_index := fishing_detail_swipe_press_touch_index
	_clear_fishing_detail_deferred_swipe()
	_begin_skill_swipe_tracking(start_position, touch_index)
	if skill_swipe_tracking:
		_update_skill_swipe_feedback(event_position)
	return true


func _route_fishing_detail_deferred_tap_release(event_position: Vector2, touch_index := -1) -> bool:
	if current_screen != "skill" or selected_skill_id != "fishing":
		return false
	if event_position == Vector2.INF:
		return false
	if _position_inside_bottom_interactive_ui(event_position) or not _position_inside_detail_actions_viewport(event_position):
		return false
	if _input_routing_shell()._route_fishing_method_lock_tap_at_position(event_position):
		return true
	var offer_button := _fishing_ui_surface()._fishing_offer_button_hit(event_position, true)
	if offer_button != null:
		_activate_fishing_offer_button(str(offer_button.get_meta("fishing_offer_id", "")), offer_button)
		return true
	var method_hit := _fishing_ui_surface()._fishing_method_button_hit(event_position, true)
	if not method_hit.is_empty():
		var method_card := method_hit.get("method_card", {}) as Dictionary
		if method_card.is_empty():
			return false
		var skill_id := str(method_card.get("skill_id", "fishing"))
		var action_id := str(method_card.get("action_id", ""))
		var owner_area_card := method_hit.get("owner_area_card", {}) as Dictionary
		var owner_pop := owner_area_card.get("pop", null) as Control
		var owner_area_pop_instance_id := owner_pop.get_instance_id() if owner_pop != null and is_instance_valid(owner_pop) else 0
		if owner_area_pop_instance_id == 0:
			owner_area_pop_instance_id = int(method_hit.get("owner_pop_instance_id", 0))
		if queue_selection_mode:
			if owner_area_card.is_empty():
				_skill_swipe_activity_surface()._queue_selection_toggle_from_card(method_card)
			else:
				_skill_swipe_activity_surface()._queue_selection_toggle_from_card(owner_area_card)
			return true
		if current_screen == "queue":
			var module_key := _skill_swipe_activity_surface()._activity_queue_module_key_for_card(owner_area_card if not owner_area_card.is_empty() else method_card)
			if not module_key.is_empty():
				_activity_queue_runtime()._start_activity_queue_from_key(module_key)
				return true
		_on_fishing_method_pressed(skill_id, action_id, str(method_card.get("fishing_area_key", "")), owner_area_pop_instance_id)
		return true
	return false


func _try_handoff_fishing_deferred_vertical_scroll(event: InputEvent, event_position: Vector2) -> bool:
	if not fishing_detail_swipe_press_active or event_position == Vector2.INF:
		return false
	var is_motion := event is InputEventMouseMotion
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if fishing_detail_swipe_press_touch_index >= 0 and drag_event.index != fishing_detail_swipe_press_touch_index:
			return false
		is_motion = true
	if not is_motion:
		return false
	var drag_offset := event_position - fishing_detail_swipe_press_position
	if not (
		absf(drag_offset.y) >= ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	):
		return false
	var scroll_press_position := fishing_detail_swipe_press_position
	var scroll_touch_index := fishing_detail_swipe_press_touch_index
	_clear_fishing_detail_deferred_swipe()
	_fishing_ui_surface()._handoff_fishing_vertical_scroll(scroll_press_position, event_position, scroll_touch_index)
	return true


func _clear_fishing_detail_deferred_swipe() -> void:
	fishing_detail_swipe_press_active = false
	fishing_detail_swipe_press_position = Vector2.ZERO
	fishing_detail_swipe_press_touch_index = -1


func _fishing_area_card_at_position(event_position: Vector2) -> Dictionary:
	if not _position_inside_detail_actions_viewport(event_position):
		return {}
	_prune_invalid_action_cards()
	if not _skill_detail_surface()._module_action_circle_at_direct_position(event_position).is_empty():
		return {}
	var keys := action_card_keys.duplicate()
	keys.reverse()
	for raw_key in keys:
		var key := str(raw_key)
		if not action_cards.has(key):
			continue
		var card := action_cards[key] as Dictionary
		if not bool(card.get("is_fishing_area", false)):
			continue
		var pop := _valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		if not pop.get_global_rect().has_point(event_position):
			continue
		if not _skill_detail_surface()._module_action_zone_kind_at_position(pop, event_position).is_empty():
			continue
		if _fishing_active_tool_hit_at_position(card, event_position):
			continue
		return card
	return {}


func _route_fishing_area_queue_selection_input(event: InputEvent) -> bool:
	if not queue_selection_mode:
		return false
	if current_screen != "skill" and current_screen != "pinned" and current_screen != "queue":
		return false
	if current_screen == "skill" and selected_skill_id != "fishing":
		return false
	var event_position := Vector2.INF
	var is_press := false
	var is_motion := false
	var is_release := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		is_press = mouse_event.pressed
		is_release = not mouse_event.pressed
	elif event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_motion = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		is_press = touch_event.pressed
		is_release = not touch_event.pressed
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		is_motion = true
	else:
		return false
	if is_press:
		if _position_inside_bottom_interactive_ui(event_position) or not _position_inside_detail_actions_viewport(event_position):
			return false
		var area_card := _fishing_area_card_at_position(event_position)
		if area_card.is_empty():
			return false
		var card_key := str(area_card.get("card_key", ""))
		if card_key.is_empty():
			card_key = ModuleUiRuntime.fishing_area(fishing_runtime.area_module_key(str(area_card.get("skill_id", "fishing")), area_card.get("area_def", {}) as Dictionary))
		if card_key.is_empty() or not action_cards.has(card_key):
			return false
		if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
			detail_actions_scroll.prepare_child_tap()
		action_card_press_key = card_key
		action_card_press_position = event_position
		action_card_press_stat_kind = ""
		action_card_press_dragged = false
		_skill_swipe_activity_surface()._queue_action_card_3d_press(action_card_press_key)
		return true
	if action_card_press_key.is_empty():
		return false
	var pressed_card = action_cards.get(action_card_press_key, {})
	if typeof(pressed_card) != TYPE_DICTIONARY or not bool((pressed_card as Dictionary).get("is_fishing_area", false)):
		return false
	if is_motion:
		_update_action_card_press_drag_state(event)
		return true
	if is_release:
		return _input_routing_shell()._route_action_card_release(event)
	return false


func _fishing_active_tool_hit_at_position(area_card: Dictionary, event_position: Vector2) -> bool:
	var layer := area_card.get("active_tool_layer") as Control
	var art := area_card.get("active_tool_art") as TextureRect
	if layer == null or art == null or not is_instance_valid(layer) or not is_instance_valid(art):
		return false
	if not layer.visible or not layer.is_visible_in_tree():
		return false
	return art.get_global_rect().grow(18.0).has_point(event_position)


func _active_action_scroll_container() -> MobileScrollContainer:
	if current_screen == "skill":
		return detail_actions_scroll
	if current_screen == "pinned" or current_screen == "queue":
		return _valid_control_ref(content_scroll) as MobileScrollContainer
	return null


func _detail_actions_scroll_suppresses_child_click() -> bool:
	var active_scroll := _active_action_scroll_container()
	return (
		active_scroll != null
		and is_instance_valid(active_scroll)
		and active_scroll.is_child_click_suppressed()
	)


func _action_card_press_motion_is_scroll_drag(event_position: Vector2) -> bool:
	var drag_offset := event_position - action_card_press_position
	return (
		absf(drag_offset.y) >= ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	)


func _action_card_press_motion_is_skill_swipe(event_position: Vector2) -> bool:
	if current_screen != "skill":
		return false
	var drag_offset := event_position - action_card_press_position
	return (
		absf(drag_offset.x) >= ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.x) > absf(drag_offset.y) * 1.15
	)


func _action_stop_hold_motion_is_scroll_drag(event_position: Vector2) -> bool:
	var drag_offset := event_position - action_stop_hold_start_position
	return (
		absf(drag_offset.y) >= ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	)


func _cancel_action_stop_hold_if_scroll_drag_event(event: InputEvent) -> bool:
	if not action_stop_hold_active:
		return false
	var event_position := Vector2.INF
	if event is InputEventMouseMotion:
		if action_stop_hold_pointer_id >= 0:
			return false
		event_position = (event as InputEventMouseMotion).global_position
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if drag_event.index != action_stop_hold_pointer_id:
			return false
		event_position = drag_event.position
	else:
		return false
	if event_position == Vector2.INF or not _action_stop_hold_motion_is_scroll_drag(event_position):
		return false
	_cancel_action_stop_hold()
	return true


func _update_action_card_press_drag_state(event: InputEvent) -> void:
	if action_card_press_key.is_empty():
		return
	var event_position := Vector2.ZERO
	var has_position := false
	if event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		has_position = true
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		has_position = true
	if not has_position:
		return
	if _action_card_press_motion_is_skill_swipe(event_position):
		var press_position := action_card_press_position
		var touch_index := _fishing_ui_surface()._motion_event_touch_index(event)
		action_card_press_dragged = true
		_skill_swipe_activity_surface()._cancel_pending_action_card_3d_press()
		if action_card_press_stat_kind.is_empty():
			_skill_swipe_activity_surface()._release_action_card_3d_press(action_card_press_key)
		if not skill_swipe_tracking:
			_begin_skill_swipe_tracking(press_position, touch_index)
		if skill_swipe_tracking:
			_update_skill_swipe_feedback(event_position)
		return
	if _detail_actions_scroll_suppresses_child_click() or _action_card_press_motion_is_scroll_drag(event_position):
		action_card_press_dragged = true
		_skill_swipe_activity_surface()._cancel_pending_action_card_3d_press()
		if action_card_press_stat_kind.is_empty():
			_skill_swipe_activity_surface()._release_action_card_3d_press(action_card_press_key)
		if _action_card_press_motion_is_scroll_drag(event_position):
			_fishing_ui_surface()._handoff_fishing_vertical_scroll(action_card_press_position, event_position, _fishing_ui_surface()._motion_event_touch_index(event))
		return
	if not action_card_press_stat_kind.is_empty() and event_position.distance_to(action_card_press_position) > ACTION_STAT_TAP_RELEASE_SLOP:
		action_card_press_dragged = true
		_skill_swipe_activity_surface()._cancel_pending_action_card_3d_press()


func _notification(what: int) -> void:
	_app_lifecycle_runtime().handle_notification(what)


func _exit_tree() -> void:
	_app_lifecycle_runtime()._prepare_for_shutdown()


func _build_ui_shell() -> void:
	var root := ColorRect.new()
	app_background_rect = root
	root.color = _theme_paper_color()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	home_page = Control.new()
	home_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	home_page.offset_bottom = -BOTTOM_NAV_HEIGHT
	add_child(home_page)
	
	skills_page = Control.new()
	skills_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	skills_page.offset_bottom = -BOTTOM_NAV_HEIGHT
	skills_page.clip_contents = true
	add_child(skills_page)
	_ensure_skill_swipe_paper_fade_overlay()


func _build_ui_boot_async():
	var boot_warmup := _boot_warmup_runtime()
	await boot_warmup._boot_progress_step("Building screen...", 0.34)
	_build_ui_shell()
	await boot_warmup._boot_progress_step("Loading skill page...", 0.42)
	_build_skills_page()
	await boot_warmup._boot_progress_step("Loading navigation...", 0.50)
	_navigation_shell()._build_nav_bar()
	_navigation_shell()._build_module_utility_row()
	await boot_warmup._boot_progress_step("Preparing popups...", 0.56)
	_achievement_toast_surface()._build_achievement_toast_layer()
	if tutorial_active:
		_ensure_tutorial_overlay()
		_tutorial_overlay_surface()._update_tutorial_overlay()
	await boot_warmup._boot_progress_step("Starting systems...", 0.60)
	await boot_warmup._boot_progress_step("Mounting skill view...", 0.62)
	await boot_warmup._boot_progress_step("Preparing first frame...", 0.64)
	await boot_warmup._boot_progress_step("Almost ready...", 0.66)


func _ensure_home_page() -> void:
	if home_page_built or home_page == null:
		return
	home_page_built = true
	_build_home_page()
	_achievement_overlay_surface().call_deferred("_prewarm_achievements_overlay")


func _lazy_overlay_built(key: String) -> bool:
	return bool(lazy_overlays_built.get(key, false))


func _mark_lazy_overlay_built(key: String) -> void:
	lazy_overlays_built[key] = true


func _ensure_tutorial_overlay() -> void:
	if _lazy_overlay_built("tutorial"):
		return
	_mark_lazy_overlay_built("tutorial")
	_tutorial_overlay_surface().build()


func _online_runtime() -> OnlineRuntime:
	if online_runtime == null or not is_instance_valid(online_runtime):
		online_runtime = OnlineRuntime.new()
		online_runtime.name = "OnlineRuntime"
		online_runtime.setup(self)
		add_child(online_runtime)
	return online_runtime


func _refresh_leaderboard_if_visible() -> void:
	if current_screen != "leaderboard" or skills_content == null:
		return
	_kill_transient_tweens_in_subtree(skills_content)
	_clear(skills_content)
	_leaderboard_presentation()._render_leaderboard_page()
	_update_page_visibility()


func _build_home_page() -> void:
	_achievement_overlay_surface().invalidate_home_achievement_build()
	achievement_skill_count_labels.clear()
	achievement_skill_bars.clear()
	achievement_skill_level_labels.clear()
	achievement_skill_tier_name_labels.clear()
	achievement_skill_tier_count_labels.clear()
	achievement_skill_tier_bars.clear()
	achievement_medal_slot_strips.clear()
	achievement_medal_slot_panels.clear()
	achievement_medal_slot_icons.clear()
	achievement_total_label = null
	achievement_elite_label = null
	achievement_total_bar = null
	achievement_buff_label = null
	achievement_total_level_label = null
	achievement_best_card = null
	achievement_best_art_frame = null
	achievement_best_art = null
	achievement_best_name_label = null
	achievement_best_medal = null
	hero_message = null
	var scroll := MobileScrollContainer.new()
	home_scroll = scroll
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	home_page.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", PAGE_PAD)
	margin.add_theme_constant_override("margin_right", PAGE_PAD)
	margin.add_theme_constant_override("margin_top", 96)
	margin.add_theme_constant_override("margin_bottom", BOTTOM_NAV_SAFE_PAD + 190)
	scroll.add_child(margin)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 52)
	margin.add_child(stack)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 74)
	stack.add_child(top_spacer)
	var logo := visual_texture_cache._image(IDLE_ELITE_LOGO_TEXTURE, Vector2(1684, 414))
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(logo)
	var achievement_page := PanelContainer.new()
	achievement_page.custom_minimum_size = Vector2(_skill_content_width(), 0)
	achievement_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievement_page.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	stack.add_child(achievement_page)
	_achievement_overlay_surface()._build_achievements(achievement_page)


func _build_skills_page() -> void:
	skills_content = Control.new()
	skills_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	skills_content.offset_top = SKILLS_PAGE_TOP_PAD
	skills_content.offset_bottom = 0
	skills_page.add_child(skills_content)


func _intro_bottom_controls_unlocked() -> bool:
	return onboarding_tutorial_complete and not tutorial_active


func _hero_unlocked() -> bool:
	return _global_level() >= HERO_UNLOCK_TOTAL_LEVEL


func _hub_unlocked() -> bool:
	return _skill_level("build") >= HUB_UNLOCK_BUILD_LEVEL


func _shop_unlocked() -> bool:
	var tiers := AchievementState.all_medal_tier_counts(self)
	if tiers.is_empty():
		return false
	return int(tiers[0]) >= SHOP_UNLOCK_BRONZE_MEDALS


func _state_object_ref(value) -> Object:
	if value == null:
		return null
	if typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value


func _valid_control_ref(value) -> Control:
	var object := _state_object_ref(value)
	if object == null:
		return null
	return object as Control


func _valid_texture_button_ref(value) -> TextureButton:
	var control := _valid_control_ref(value)
	if control == null:
		return null
	return control as TextureButton


func _valid_node_ref(value) -> Node:
	var object := _state_object_ref(value)
	if object == null:
		return null
	return object as Node


func _valid_canvas_item_ref(value) -> CanvasItem:
	var object := _state_object_ref(value)
	if object == null:
		return null
	return object as CanvasItem


func _valid_texture_rect_ref(value) -> TextureRect:
	var control := _valid_control_ref(value)
	if control == null:
		return null
	return control as TextureRect


func _valid_label_ref(value) -> Label:
	var control := _valid_control_ref(value)
	if control == null:
		return null
	return control as Label


func _valid_base_button_ref(value) -> BaseButton:
	var object := _state_object_ref(value)
	if object == null:
		return null
	return object as BaseButton


func _valid_button_ref(value) -> Button:
	var control := _valid_control_ref(value)
	if control == null:
		return null
	return control as Button


func _meta_vector2(node: Object, meta_name, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if node == null or not is_instance_valid(node) or not node.has_meta(meta_name):
		return fallback
	var value = node.get_meta(meta_name)
	if value is Vector2:
		return value
	return fallback


func _weak_object_ref(value) -> WeakRef:
	var object := _state_object_ref(value)
	if object == null:
		return null
	return weakref(object)


func _weak_ref_value(weak_ref: WeakRef) -> Variant:
	if weak_ref == null:
		return null
	return weak_ref.get_ref()


func _action_card_has_live_anchor(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	if _valid_control_ref(card.get("root")) != null:
		return true
	if _valid_control_ref(card.get("pop")) != null:
		return true
	if _valid_control_ref(card.get("button")) != null:
		return true
	if _valid_control_ref(card.get("method_button")) != null:
		return true
	return false


func _prune_invalid_action_cards() -> void:
	if action_cards.is_empty():
		return
	for raw_key in action_cards.keys():
		var key := str(raw_key)
		var raw_card = action_cards.get(raw_key)
		if typeof(raw_card) != TYPE_DICTIONARY:
			_discard_action_card_key(key)
			continue
		var card := raw_card as Dictionary
		if not _action_card_has_live_anchor(card):
			_discard_action_card_key(key)


func _flush_skill_swipe_handoff_for_navigation() -> void:
	_clear_skill_swipe_handoff_cover_immediate()


func _reset_navigation_render_state() -> void:
	_last_rendered_screen_key = ""
	_kill_skill_swipe_tween()
	_clear_skill_swipe_handoff_cover_immediate()
	_skill_swipe_activity_surface()._clear_skill_swipe_preview()
	skill_swipe_frame = null
	skill_swipe_page = null
	skill_swipe_drag_offset_x = 0.0
	skill_swipe_gap_render_offset_x = 0.0


func _clear_skills_content_orphans() -> void:
	if skills_content == null or skills_content.get_child_count() == 0:
		return
	_kill_transient_tweens_in_subtree(skills_content)
	_clear(skills_content)


func _finish_render_screen_transition(target_key: String) -> void:
	_apply_skills_content_layout_for_screen()
	_last_rendered_screen_key = target_key
	if current_screen == "skill" and not _skill_swipe_handoff_cover_is_opaque_cream_transition() and not skill_swipe_defer_initial_lazy_mount:
		_repair_blank_detail_lazy_stack()
		call_deferred("_repair_blank_detail_lazy_stack")
	if (
		skill_detail_refresh_cover_active
		and not skill_swipe_pending_full_finalize
		and module_ui_pending_pin_scroll_anchor.is_empty()
		and not module_ui_pin_refresh_cover_requested
	):
		_clear_skill_swipe_handoff_cover_immediate()
	elif direct_skill_nav_cover_active and not skill_swipe_pending_full_finalize:
		_fade_clear_direct_skill_nav_cover()
	elif (
		not skill_swipe_pending_full_finalize
		and
		not skill_swipe_outgoing_cover_active
		and not skill_swipe_rebuild_cover_active
		and not skill_swipe_animating
		and skill_swipe_handoff_cover != null
		and is_instance_valid(skill_swipe_handoff_cover)
		and not _navigation_shell()._page_switch_scroll_cover_active()
	):
		_clear_skill_swipe_handoff_cover_immediate()
	_update_page_visibility()
	_profile_chat_overlay_surface()._update_chat_strip(true)
	call_deferred("_update_ui", 0.0, true)
	if current_screen == "skill":
		if selected_skill_id == TUTORIAL_STARTER_SKILL_ID:
			if _onboarding_runtime()._onboarding_swipe_tip_sequence_resumable() and not onboarding_swipe_tip_sequence_running:
				call_deferred("_run_onboarding_swipe_tip_sequence")
		else:
			_onboarding_runtime().call_deferred("_maybe_show_onboarding_explore_tip")
	elif current_screen == "hub":
		_hub_surface().call_deferred("_maybe_show_hub_tutorial_tip")
	if (
		current_screen == "skill"
		and not _skill_swipe_handoff_cover_is_opaque_cream_transition()
		and not skill_swipe_defer_initial_lazy_mount
	):
		if detail_lazy_plan.size() > 0 and not _skill_detail_surface()._detail_lazy_all_mounted():
			call_deferred("_detail_lazy_refresh_after_page_ready", detail_lazy_refresh_token)


func _try_reveal_current_skill_page(target_key: String, scroll_latest_activity: bool) -> bool:
	if target_key.is_empty() or not target_key.begins_with("skill:"):
		return false
	if _last_rendered_screen_key != target_key:
		return false
	if skills_content == null or not is_instance_valid(skills_content) or skills_content.get_child_count() == 0:
		return false
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return false
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack) or not _skill_detail_stack_has_visible_modules(stack):
		return false
	if not _detail_render_signature_current(selected_skill_id):
		return false
	_clear_page_transient_input_state()
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""
	_kill_skill_swipe_tween()
	_apply_skills_content_layout_for_screen()
	_sync_skill_detail_back_arrow_visibility()
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		call_deferred("_sync_detail_actions_scroll_limit_deferred")
		if scroll_latest_activity:
			call_deferred("_scroll_to_resume_activity", false)
	_finish_render_screen_transition(target_key)
	return true


func _detail_render_signature_current(skill_id: String) -> bool:
	var plan_data := _detail_lazy_plan_and_signature_for_skill(skill_id)
	var expected := plan_data.get("signature", []) as Array
	if expected.size() != detail_rendered_action_ids.size():
		return false
	for index in range(expected.size()):
		if str(expected[index]) != str(detail_rendered_action_ids[index]):
			return false
	var expected_plan := plan_data.get("plan", []) as Array
	if expected_plan.size() != detail_lazy_plan.size():
		return false
	for index in range(expected_plan.size()):
		var expected_entry := expected_plan[index] as Dictionary
		var rendered_entry := detail_lazy_plan[index] as Dictionary
		if str(expected_entry.get("kind", "")) != str(rendered_entry.get("kind", "")):
			return false
		if str(expected_entry.get("track_id", "")) != str(rendered_entry.get("track_id", "")):
			return false
		if absf(float(expected_entry.get("height", 0.0)) - float(rendered_entry.get("height", 0.0))) > 0.5:
			return false
	return true


func _apply_skills_content_layout_for_screen() -> void:
	skills_content.offset_left = 0.0
	skills_content.offset_right = 0.0
	skills_content.offset_bottom = 0.0
	if current_screen == "hub" or current_screen == "menu" or current_screen == "pinned" or current_screen == "queue":
		skills_content.offset_top = 0.0
	else:
		skills_content.offset_top = SKILLS_PAGE_TOP_PAD
	if current_screen == "skill":
		_ensure_skill_swipe_frame_centered()
		if not skill_swipe_animating:
			_normalize_skill_detail_page_layout()


func _prepare_skills_page_transition(target_key: String) -> void:
	_cancel_boot_detail_completion()
	var leaving_skill := not target_key.begins_with("skill:")
	_cancel_skill_swipe_finalize_for_navigation()
	if not target_key.begins_with("skill:"):
		_flush_skill_swipe_handoff_for_navigation()
	var previous_key := _last_rendered_screen_key
	if previous_key.begins_with("skill:") and target_key.begins_with("skill:") and previous_key != target_key:
		_reward_feedback_surface()._clear_skill_reward_floats()
	if previous_key == target_key:
		if skills_content.get_child_count() > 0 or skill_swipe_handoff_cover != null:
			var preserve_pin_anchor_cover := skill_detail_refresh_cover_active and not module_ui_pending_pin_scroll_anchor.is_empty()
			if not preserve_pin_anchor_cover:
				_clear_skill_swipe_handoff_cover_immediate()
			if skills_content.get_child_count() > 0:
				_kill_transient_tweens_in_subtree(skills_content)
				_skill_swipe_activity_surface()._clear_skill_swipe_preview()
				_clear(skills_content)
				_navigation_shell()._reset_page_control_refs()
		return
	if previous_key.is_empty():
		return
	if previous_key.begins_with("skill:"):
		if skills_content.get_child_count() > 0:
			_kill_transient_tweens_in_subtree(skills_content)
			_skill_swipe_activity_surface()._clear_skill_swipe_preview()
			_clear(skills_content)
			_navigation_shell()._reset_page_control_refs()
		elif (
			skill_swipe_handoff_cover != null
			and is_instance_valid(skill_swipe_handoff_cover)
			and not _skill_swipe_handoff_cover_is_cream_transition()
		):
			_flush_skill_swipe_handoff_for_navigation()
		if leaving_skill:
			_clear_skill_swipe_handoff_cover_immediate()
		return
	if skills_content.get_child_count() > 0:
		_kill_transient_tweens_in_subtree(skills_content)
		_skill_swipe_activity_surface()._clear_skill_swipe_preview()
		_clear(skills_content)
		_navigation_shell()._reset_page_control_refs()


func _render_screen(scroll_latest_activity := false, restore_detail_scroll := -1, _boot_async := false):
	return await _navigation_shell()._render_screen(scroll_latest_activity, restore_detail_scroll, _boot_async)

func _detail_restore_scroll_value(restore_detail_scroll: int) -> int:
	if selected_skill_id == "thieving" and not detail_thieving_scroll_restore_allowed:
		return 0
	return maxi(0, restore_detail_scroll)


func _refresh_visible_skill_detail_action_list(restore_detail_scroll := -1, expected_skill_id := "", allow_thieving_scroll_restore := false, suppress_layout_transition := false):
	if current_screen != "skill":
		return
	var target_skill_id := expected_skill_id if not expected_skill_id.is_empty() else selected_skill_id
	if target_skill_id.is_empty() or selected_skill_id != target_skill_id:
		return
	if _skill_swipe_navigation_blocks_detail_refresh():
		return
	if screen_render_in_progress:
		_store_pending_skill_detail_refresh_request(restore_detail_scroll, target_skill_id, allow_thieving_scroll_restore, suppress_layout_transition)
		return
	var layout_snapshot := {} if suppress_layout_transition else _capture_detail_module_layout_snapshot()
	var effective_restore_scroll := restore_detail_scroll
	if effective_restore_scroll < 0 and detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		if not module_ui_pending_pin_scroll_anchor.is_empty():
			effective_restore_scroll = -1
		else:
			effective_restore_scroll = int(round(detail_actions_scroll.drag_scroll_position))
	_last_rendered_screen_key = ""
	if layout_snapshot.is_empty():
		_begin_skill_detail_refresh_cover()
	var prev_thieving_restore := detail_thieving_scroll_restore_allowed
	detail_thieving_scroll_restore_allowed = prev_thieving_restore or allow_thieving_scroll_restore
	await _render_screen(false, effective_restore_scroll, false)
	detail_thieving_scroll_restore_allowed = prev_thieving_restore
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	_update_ui(0.0, true)
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		_skill_detail_surface()._sync_detail_lazy_visible_cards(true, -1)
		await _restore_module_ui_pin_scroll_anchor(target_skill_id)
		if skill_detail_refresh_cover_active and not skill_swipe_pending_full_finalize:
			_clear_skill_swipe_handoff_cover_immediate()
	if not suppress_layout_transition and not layout_snapshot.is_empty():
		_skill_detail_surface().call_deferred("_play_detail_module_layout_transition", layout_snapshot)
	call_deferred("_sync_detail_actions_scroll_limit_deferred")


func _store_pending_screen_render_request(scroll_latest_activity: bool, restore_detail_scroll: int, boot_async: bool, requested_key := "") -> void:
	pending_screen_render_request = {
		"scroll_latest_activity": scroll_latest_activity,
		"restore_detail_scroll": restore_detail_scroll,
		"boot_async": boot_async,
		"requested_key": requested_key
	}


func _store_pending_skill_detail_refresh_request(restore_detail_scroll: int, target_skill_id: String, allow_thieving_scroll_restore: bool, suppress_layout_transition: bool) -> void:
	pending_skill_detail_refresh_request = {
		"restore_detail_scroll": restore_detail_scroll,
		"target_skill_id": target_skill_id,
		"allow_thieving_scroll_restore": allow_thieving_scroll_restore,
		"suppress_layout_transition": suppress_layout_transition
	}


func _finish_screen_render_request() -> void:
	screen_render_in_progress = false
	screen_render_target_key = ""
	if pending_screen_render_request.is_empty():
		_defer_pending_skill_detail_refresh_request()
		return
	var request := pending_screen_render_request
	pending_screen_render_request = {}
	call_deferred(
		"_render_screen",
		bool(request.get("scroll_latest_activity", false)),
		int(request.get("restore_detail_scroll", -1)),
		bool(request.get("boot_async", false))
	)


func _defer_pending_skill_detail_refresh_request() -> void:
	if pending_skill_detail_refresh_request.is_empty():
		return
	call_deferred("_run_pending_skill_detail_refresh_request")


func _run_pending_skill_detail_refresh_request() -> void:
	if pending_skill_detail_refresh_request.is_empty() or screen_render_in_progress:
		return
	var request := pending_skill_detail_refresh_request
	pending_skill_detail_refresh_request = {}
	_refresh_visible_skill_detail_action_list(
		int(request.get("restore_detail_scroll", -1)),
		str(request.get("target_skill_id", "")),
		bool(request.get("allow_thieving_scroll_restore", false)),
		bool(request.get("suppress_layout_transition", false))
	)


func _cancel_activity_unlock_transients_for_navigation() -> void:
	for raw_card in action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		_app_lifecycle_runtime()._kill_card_tween(card, "preview_fade_tween")
		_activity_unlock_runtime()._finalize_manual_activity_unlock_for_card(card)
		card["unlock_ceremony_finalized"] = true
		card["unlock_ceremony_pending"] = false
		card["unlock_ceremony_active"] = false
		card["unlock_ready_pending"] = false
	_clear_pending_activity_readiness_for_skill(selected_skill_id)
	activity_unlock_ceremony_count = 0
	activity_unlock_ceremony_action_key = ""
	_set_activity_unlock_preview_after_ceremony("")
	_clear_activity_unlock_preview_reveal_guards()
	activity_unlock_heist_preview_after_ceremony_id = ""
	activity_unlock_center_scroll_target = -1
	activity_unlock_detail_refresh_done = true
	if detail_unlock_scroll_spacer_tween != null and detail_unlock_scroll_spacer_tween.is_valid():
		detail_unlock_scroll_spacer_tween.kill()
		detail_unlock_scroll_spacer_tween = null
	detail_unlock_scroll_spacer_heights.clear()
	_clear_activity_unlock_visual_scroll_tween()


func _register_action_card(key: String, card: Dictionary) -> void:
	if key.is_empty() or card.is_empty():
		return
	if bool(card.get("preview_only", false)):
		return
	action_cards[key] = card
	if not action_card_keys.has(key):
		action_card_keys.append(key)
	card["card_key"] = key
	if not card.has("skill_id") or str(card.get("skill_id", "")).is_empty():
		var separator := key.find(":")
		if separator > 0:
			card["skill_id"] = key.substr(0, separator)
	if not bool(card.get("is_fishing_area", false)) and (not card.has("action_id") or str(card.get("action_id", "")).is_empty()):
		var separator := key.find(":")
		if separator > 0 and not key.begins_with("thieving_heist:") and not key.begins_with("pinned_page:") and not key.begins_with("pinned_shelf:"):
			card["action_id"] = key.substr(separator + 1)


func _discard_action_card_key(key: String) -> void:
	if key.is_empty():
		return
	action_cards.erase(key)
	action_card_keys.erase(key)


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


func _configure_skill_column_frame(frame: Control, content_width: float) -> void:
	frame.anchor_left = 0.0
	frame.anchor_right = 0.0
	frame.anchor_top = 0.0
	frame.anchor_bottom = 1.0
	frame.offset_top = 0.0
	frame.offset_bottom = 0.0
	frame.position = Vector2.ZERO
	frame.custom_minimum_size.x = content_width


func _apply_skill_column_layout(frame: Control, content_width: float, drag_x: float) -> void:
	_configure_skill_column_frame(frame, content_width)
	var left := (_skill_column_host_width() - content_width) * 0.5 + drag_x
	frame.offset_left = left
	frame.offset_right = left + content_width


func _skill_swipe_preview_fade_progress(abs_x: float) -> float:
	var t := clampf(abs_x / maxf(1.0, SKILL_SWIPE_PREVIEW_FADE_DISTANCE), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _set_skill_swipe_control_alpha(control: Control, alpha: float) -> void:
	if control == null or not is_instance_valid(control):
		return
	var next_modulate := control.modulate
	next_modulate.a = clampf(alpha, 0.0, 1.0)
	_set_canvas_item_modulate_if_changed(control, next_modulate)


func _skill_swipe_paper_fade_progress(abs_x: float) -> float:
	var t := clampf(abs_x / maxf(1.0, SKILL_SWIPE_PAPER_FADE_DISTANCE), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _ensure_skill_swipe_paper_fade_overlay() -> void:
	if skills_page == null or not is_instance_valid(skills_page):
		return
	if skill_swipe_paper_fade_overlay != null and is_instance_valid(skill_swipe_paper_fade_overlay):
		_apply_skill_page_cover_bounds(skill_swipe_paper_fade_overlay, true)
		return
	skill_swipe_paper_fade_overlay = ColorRect.new()
	skill_swipe_paper_fade_overlay.color = _theme_paper_color()
	_apply_skill_page_cover_bounds(skill_swipe_paper_fade_overlay, true)
	skill_swipe_paper_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_swipe_paper_fade_overlay.z_index = 0
	skill_swipe_paper_fade_overlay.z_as_relative = false
	skill_swipe_paper_fade_overlay.visible = false
	_ensure_skill_nav_cover_layer().add_child(skill_swipe_paper_fade_overlay)


func _sync_skill_swipe_paper_fade(drag_x: float) -> void:
	if skill_swipe_paper_fade_overlay == null or not is_instance_valid(skill_swipe_paper_fade_overlay):
		return
	_apply_skill_page_cover_bounds(skill_swipe_paper_fade_overlay, true)
	var alpha := maxf(_skill_swipe_paper_fade_progress(absf(drag_x)), skill_swipe_paper_fade_hold_alpha)
	if alpha <= 0.01:
		_set_canvas_item_visible_if_changed(skill_swipe_paper_fade_overlay, false)
		return
	_set_canvas_item_visible_if_changed(skill_swipe_paper_fade_overlay, true)
	_set_canvas_item_alpha_if_changed(skill_swipe_paper_fade_overlay, alpha)


func _hide_skill_swipe_paper_fade() -> void:
	skill_swipe_paper_fade_hold_alpha = 0.0
	if skill_swipe_paper_fade_overlay != null and is_instance_valid(skill_swipe_paper_fade_overlay):
		_set_canvas_item_visible_if_changed(skill_swipe_paper_fade_overlay, false)


func _sync_skill_strip_page_crossfade(drag_x: float) -> void:
	if skill_strip_ids.is_empty():
		return
	_hide_skill_swipe_paper_fade()
	var count := skill_strip_ids.size()
	if count <= 0 or skill_strip_index < 0:
		return
	var incoming_index := skill_strip_index
	var progress := 0.0
	if skill_swipe_strip_committed_crossfade and not skill_swipe_tracking:
		progress = 0.0
	elif absf(drag_x) > 1.0:
		var offset := 1 if drag_x < 0.0 else -1
		if _onboarding_runtime()._swipe_offset_accessible(offset):
			incoming_index = (skill_strip_index + offset) % count
			if incoming_index < 0:
				incoming_index += count
			progress = _skill_swipe_paper_fade_progress(absf(drag_x))
	for i in count:
		var sid := str(skill_strip_ids[i])
		var page := (skill_strip_refs.get(sid, {}) as Dictionary).get("page") as Control
		if page == null or not is_instance_valid(page):
			continue
		var alpha := 1.0 if i == skill_strip_index else 0.0
		if not skill_swipe_strip_committed_crossfade or skill_swipe_tracking:
			if i == skill_strip_index:
				alpha = 1.0 - progress
			elif i == incoming_index:
				alpha = progress
		_set_skill_swipe_control_alpha(page, alpha)


func _hold_skill_swipe_paper_fade_for_commit() -> void:
	if not skill_strip_ids.is_empty():
		_hide_skill_swipe_paper_fade()
		return
	if not SKILL_SWIPE_PAPER_FADE_ENABLED:
		_hide_skill_swipe_paper_fade()
		return
	skill_swipe_paper_fade_hold_alpha = 1.0
	_sync_skill_swipe_paper_fade(skill_swipe_drag_offset_x)


func _sync_skill_swipe_drag_frame_fade(drag_x: float) -> void:
	if not skill_strip_ids.is_empty():
		_sync_skill_strip_page_crossfade(drag_x)
		return
	if skill_swipe_animation_mode == "entry":
		_hide_skill_swipe_paper_fade()
		return
	if not SKILL_SWIPE_DRAG_FRAME_FADE_ENABLED:
		if SKILL_SWIPE_PAPER_FADE_ENABLED:
			_sync_skill_swipe_paper_fade(drag_x)
		else:
			_hide_skill_swipe_paper_fade()
		return
	var _legacy_overlay := ColorRect.new()
	_legacy_overlay.queue_free()


func _sync_skill_swipe_live_page_fade(drag_x: float) -> void:
	if skill_swipe_page == null or not is_instance_valid(skill_swipe_page):
		return
	if not skill_strip_ids.is_empty():
		return
	_set_skill_swipe_control_alpha(skill_swipe_page, 1.0)


func _sync_skill_swipe_preview_page_fade(current_x: float) -> void:
	var preview_page := _skill_swipe_activity_surface()._active_preview_page()
	if preview_page == null:
		return
	if not SKILL_SWIPE_SHOW_INCOMING_PREVIEW_DURING_DRAG:
		preview_page.visible = false
		_set_skill_swipe_control_alpha(preview_page, 1.0)
		return
	preview_page.visible = true
	var progress := _skill_swipe_preview_fade_progress(absf(current_x))
	var alpha := lerpf(SKILL_SWIPE_PREVIEW_FADE_MIN_ALPHA, 1.0, progress)
	_set_skill_swipe_control_alpha(preview_page, alpha)


func _apply_skill_swipe_drag_offset(drag_x: float) -> void:
	skill_swipe_drag_offset_x = drag_x
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	if not skill_strip_ids.is_empty():
		var page_width := _skill_content_width()
		var left := -float(skill_strip_index) * page_width + drag_x
		skill_swipe_frame.offset_left = left
		skill_swipe_frame.offset_right = left + page_width
		_sync_skill_swipe_drag_frame_fade(drag_x)
		return
	var content_width := _skill_swipe_frame_content_width()
	if skill_swipe_frame.custom_minimum_size.x > 1.0:
		content_width = skill_swipe_frame.custom_minimum_size.x
	_apply_skill_column_layout(skill_swipe_frame, content_width, drag_x)
	_sync_skill_swipe_drag_frame_fade(drag_x)
	_sync_skill_swipe_live_page_fade(drag_x)


func _reset_skill_swipe_frame_layout() -> void:
	_apply_skill_swipe_drag_offset(0.0)


func _ensure_skill_swipe_frame_centered() -> void:
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	if skill_swipe_tracking or skill_swipe_animating:
		_apply_skill_swipe_drag_offset(skill_swipe_drag_offset_x)
		return
	_apply_skill_swipe_drag_offset(0.0)


func _add_centered_skill_column(control: Control, drag_x: float = 0.0) -> void:
	var content_width := _skill_content_width()
	_apply_skill_column_layout(control, content_width, drag_x)
	skills_content.add_child(control)


func _detail_stack_entry(child: Control, child_width: float, stack_width: float) -> Control:
	if child == null or absf(stack_width - child_width) <= 0.001:
		return child
	var entry := Control.new()
	entry.set_meta("detail_stack_entry_wrapper", true)
	var child_height := child.custom_minimum_size.y
	if child_height <= 1.0:
		child_height = child.size.y
	entry.custom_minimum_size = Vector2(stack_width, maxf(1.0, child_height))
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.clip_contents = false
	child.anchor_left = 0.0
	child.anchor_right = 0.0
	child.anchor_top = 0.0
	child.anchor_bottom = 0.0
	child.size = Vector2(child_width, maxf(1.0, child_height))
	child.position = Vector2((stack_width - child_width) * 0.5, 0.0)
	child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	entry.add_child(child)
	return entry


func _is_primary_press_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _module_utility_row_reserved_height_for_screen() -> float:
	return float(MODULE_UTILITY_ROW_HEIGHT + MODULE_UTILITY_ROW_GAP) if _profile_chat_overlay_surface()._chat_strip_visible_on_current_screen() else 0.0


func _skills_content_bottom_inset_for_screen() -> float:
	if not _profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		return 0.0
	return float(CHAT_STRIP_HEIGHT) + _module_utility_row_reserved_height_for_screen()


func _bottom_ui_reserved_height_for_current_screen() -> float:
	return float(BOTTOM_NAV_HEIGHT) + _skills_content_bottom_inset_for_screen()



func _themed_progress_empty_color(theme_color: Color) -> Color:
	return theme_color.darkened(0.55).lerp(COLOR_INK, 0.02)


func _themed_progress_fill_color(theme_color: Color) -> Color:
	return theme_color.lightened(0.08)


func _themed_activity_card_fill_color(theme_color: Color) -> Color:
	return theme_color.darkened(0.18)


func _apply_activity_progress_rail_theme(bar: ActivityProgressRail, theme_color: Color) -> void:
	if bar == null:
		return
	bar.set_color_segments([], [])
	var fill := _themed_progress_fill_color(theme_color)
	var empty := _themed_progress_empty_color(theme_color)
	if bar.fill_color == fill and bar.empty_color == empty:
		return
	bar.fill_color = fill
	bar.empty_color = empty
	bar.queue_redraw()
	bar._queue_opportunity_overlay_redraw()


func _apply_activity_progress_rail_action_theme(bar: ActivityProgressRail, skill_id: String, action: Dictionary) -> void:
	if bar == null:
		return
	var segment_skill_ids := _combo_progress_segment_skill_ids(skill_id, action)
	if segment_skill_ids.size() <= 1:
		_apply_activity_progress_rail_theme(bar, _skill_theme_color(skill_id))
		return
	var fill_colors: Array[Color] = []
	var empty_colors: Array[Color] = []
	for raw_skill_id in segment_skill_ids:
		var segment_color := _skill_theme_color(str(raw_skill_id))
		fill_colors.append(_themed_progress_fill_color(segment_color))
		empty_colors.append(_themed_progress_empty_color(segment_color))
	bar.fill_color = fill_colors[0]
	bar.empty_color = empty_colors[0]
	bar.set_color_segments(fill_colors, empty_colors)


func _sync_action_card_progress_rail_theme(card: Dictionary, bar: ActivityProgressRail, skill_id: String, action: Dictionary) -> void:
	if bar == null:
		return
	var theme_key := "%s|%s|%s" % [
		skill_id,
		str(action.get("id", "")),
		hash(action.get("requirements", []))
	]
	if str(card.get("progress_rail_theme_key", "")) == theme_key:
		return
	_apply_activity_progress_rail_action_theme(bar, skill_id, action)
	card["progress_rail_theme_key"] = theme_key


func _combo_progress_segment_theme_colors(skill_id: String, action: Dictionary) -> Array[Color]:
	var colors: Array[Color] = []
	for raw_skill_id in _combo_progress_segment_skill_ids(skill_id, action):
		colors.append(_skill_theme_color(str(raw_skill_id)))
	return colors


func _apply_activity_card_depth_action_theme(depth: ActivityCardDepth, skill_id: String, action: Dictionary) -> void:
	if depth == null or not is_instance_valid(depth):
		return
	depth.set_segment_theme_colors(_combo_progress_segment_theme_colors(skill_id, action))


func _combo_progress_segment_skill_ids(skill_id: String, action: Dictionary) -> Array:
	var segment_skill_ids := []
	for raw_requirement in _activity_unlock_runtime()._action_unlock_requirements(skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		var requirement_skill := str(requirement.get("skill", skill_id)).strip_edges()
		if requirement_skill.is_empty():
			requirement_skill = skill_id
		segment_skill_ids.append(requirement_skill)
	return segment_skill_ids if segment_skill_ids.size() > 1 else []


func _apply_mastery_progress_bar_theme(bar: CleanProgressBar, theme_color: Color) -> void:
	if bar == null:
		return
	var track := theme_color.darkened(0.60).lerp(COLOR_INK, 0.02)
	if bar.track_color == track:
		return
	bar.track_color = track
	bar.queue_redraw()


func _apply_xp_progress_bar_theme(bar: CleanProgressBar, theme_color: Color) -> void:
	if bar == null:
		return
	var fill := _themed_progress_fill_color(theme_color)
	var track := _themed_progress_empty_color(theme_color)
	var depth_back := theme_color.darkened(0.50).lerp(COLOR_INK, 0.03)
	var shadow := theme_color.darkened(0.76)
	shadow.a = 0.20
	if (
		bar.fill_color == fill
		and bar.track_color == track
		and bar.border_color == COLOR_INK
		and bar.depth_enabled
		and bar.depth_back_color == depth_back
		and bar.depth_outline_color == COLOR_INK
		and bar.depth_shadow_color == shadow
	):
		return
	bar.fill_color = fill
	bar.track_color = track
	bar.border_color = COLOR_INK
	bar.depth_enabled = true
	bar.depth_back_color = depth_back
	bar.depth_outline_color = COLOR_INK
	bar.depth_shadow_color = shadow
	bar.queue_redraw()


func _update_skill_menu_card(card: Dictionary, skill_id: String, delta: float, instant: bool) -> void:
	var button := card.get("button") as Button
	if button != null and is_instance_valid(button):
		var accessible := _onboarding_runtime()._onboarding_skill_accessible(skill_id)
		_set_base_button_disabled_if_changed(button, not accessible)
		_set_canvas_item_modulate_if_changed(button, Color.WHITE if accessible else HUB_NAV_LOCKED_MODULATE)
	var activity_running := false
	var activity_progress := card.get("activity") as ActivityProgressRail
	if activity_progress != null and is_instance_valid(activity_progress):
		_set_canvas_item_visible_if_changed(activity_progress, activity_running)
	if _fishing_rework_active_for_skill(skill_id):
		var fish_gauge := card.get("fish") as FishCircle
		if fish_gauge != null:
			_set_fish_circle_for_skill(fish_gauge, skill_id, instant)
		return
	if skill_id == "fight":
		var health_gauge := card.get("health") as BlueGuyHealthHeartGauge
		if health_gauge != null:
			_fighting_runtime().set_blue_guy_health_gauge(health_gauge, instant)
		return
	var stamina_gauge := card.get("stamina") as RegenCircle
	if stamina_gauge != null:
		var max_stamina := _max_stamina(skill_id)
		var stamina_value := _stamina(skill_id)
		var stamina_decimal_fraction := SkillState.stamina_fraction(stamina, skill_id, Callable(self, "_max_stamina"))
		var circle_value := _stamina_regen_fraction(skill_id)
		stamina_gauge.set_dark_mode(dark_mode_enabled)
		stamina_gauge.set_theme_color(_skill_theme_color(skill_id))
		stamina_gauge.set_regen_ring_color(_stamina_regen_circle_color(skill_id))
		stamina_gauge.set_show_decimal(show_stamina_decimal)
		stamina_gauge.set_stamina(stamina_value, max_stamina, instant, stamina_decimal_fraction)
		stamina_gauge.set_value(circle_value, instant)


func _skill_detail_back_arrow_allowed() -> bool:
	return false


func _sync_activity_back_button_visibility(back_button: Button, interactive: bool) -> void:
	if back_button == null or not is_instance_valid(back_button):
		return
	var allowed := interactive and _skill_detail_back_arrow_allowed()
	_set_canvas_item_visible_if_changed(back_button, allowed)
	var next_mouse_filter := Control.MOUSE_FILTER_STOP if allowed else Control.MOUSE_FILTER_IGNORE
	if back_button.mouse_filter != next_mouse_filter:
		back_button.mouse_filter = next_mouse_filter


func _sync_skill_detail_back_arrow_visibility() -> void:
	if detail_back_button == null or not is_instance_valid(detail_back_button):
		if detail_header_body == null or not is_instance_valid(detail_header_body):
			return
		for child in detail_header_body.get_children():
			if child is Button:
				var candidate := child as Button
				if bool(candidate.get_meta("activity_back_button", false)):
					detail_back_button = candidate
					break
	if detail_back_button == null or not is_instance_valid(detail_back_button):
		return
	_sync_activity_back_button_visibility(detail_back_button as Button, true)


func _add_activity_back_arrow(parent: Control, interactive := true) -> Button:
	var back_button := Button.new()
	back_button.text = ""
	back_button.custom_minimum_size = ACTIVITY_BACK_BUTTON_SIZE
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.tooltip_text = ""
	back_button.set_meta("activity_back_button", true)
	var empty_style := StyleBoxEmpty.new()
	back_button.add_theme_stylebox_override("normal", empty_style)
	back_button.add_theme_stylebox_override("hover", empty_style)
	back_button.add_theme_stylebox_override("pressed", empty_style)
	back_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back_button.modulate = Color.WHITE
	_button_press_runtime().attach_button_depress_animation(back_button, 0.955)
	var back_tint := Color(1, 1, 1, 0.5)
	var arrow := TextureRect.new()
	arrow.texture = visual_texture_cache._texture_or_visual_fallback(ACTIVITY_BACK_TEXTURE)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.custom_minimum_size = ACTIVITY_BACK_ARROW_SIZE
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	arrow.modulate = back_tint
	arrow.offset_left = 34
	arrow.offset_top = 28
	arrow.offset_right = arrow.offset_left + ACTIVITY_BACK_ARROW_SIZE.x
	arrow.offset_bottom = arrow.offset_top + ACTIVITY_BACK_ARROW_SIZE.y
	back_button.add_child(arrow)
	var skills_label := _label("skills", MIN_MOBILE_BODY_FONT_SIZE, Color(0, 0, 0, 0.5), HORIZONTAL_ALIGNMENT_LEFT)
	skills_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if app_bold_font != null:
		skills_label.add_theme_font_override("font", app_bold_font)
	skills_label.offset_left = 270
	skills_label.offset_top = 24
	skills_label.offset_right = 442
	skills_label.offset_bottom = 108
	back_button.add_child(skills_label)
	back_button.offset_left = 24
	back_button.offset_top = 26
	back_button.offset_right = back_button.offset_left + ACTIVITY_BACK_BUTTON_SIZE.x
	back_button.offset_bottom = back_button.offset_top + ACTIVITY_BACK_BUTTON_SIZE.y
	back_button.z_index = 80
	if interactive:
		back_button.pressed.connect(_show_skills)
		detail_back_button = back_button
	parent.add_child(back_button)
	_sync_activity_back_button_visibility(back_button, interactive)
	return back_button


func _detail_lazy_scroll_y() -> float:
	var scroll := _valid_control_ref(detail_actions_scroll)
	if scroll == null:
		return 0.0
	return (scroll as ScrollContainer).drag_scroll_position if scroll is ScrollContainer else 0.0


func _detail_lazy_viewport_height() -> float:
	var scroll := _valid_control_ref(detail_actions_scroll)
	if scroll == null:
		return 1200.0
	return maxf(maxf(scroll.size.y, scroll.custom_minimum_size.y), 800.0)


func _detail_lazy_pinned_track_ids() -> Dictionary:
	var pinned := {}
	if selected_skill_id != "fishing" and not fishing_unlock_visible_mount_ids.is_empty():
		fishing_unlock_visible_mount_ids.clear()
	if selected_skill_id != "fishing" and not fishing_unlock_preview_fade_marker_ids.is_empty():
		fishing_unlock_preview_fade_marker_ids.clear()
	if running_skill_id == selected_skill_id and not running_action_id.is_empty():
		pinned[running_action_id] = true
	if event_running_skill_id == selected_skill_id and not event_running_action_id.is_empty():
		pinned[event_running_action_id] = true
	if selected_skill_id == "thieving":
		for raw_action_id in thieving_action_jails.keys():
			var jailed_action_id := str(raw_action_id)
			if jailed_action_id.is_empty() or _thieving_surface()._thieving_action_jail_remaining(jailed_action_id) <= 0:
				continue
			pinned[jailed_action_id] = true
	if not pending_activity_unlock_ceremony.is_empty():
		for raw_action_id in _pending_activity_readiness_action_ids():
			var pending_action_id := str(raw_action_id)
			if not pending_action_id.is_empty():
				pinned[pending_action_id] = true
	if not activity_unlock_preview_after_ceremony_id.is_empty():
		pinned[activity_unlock_preview_after_ceremony_id] = true
	if not activity_unlock_ceremony_action_key.is_empty():
		var ceremony_parts := activity_unlock_ceremony_action_key.split(":")
		if ceremony_parts.size() >= 2:
			pinned[str(ceremony_parts[1])] = true
	if selected_skill_id == "fishing":
		for raw_mount_id in fishing_unlock_visible_mount_ids:
			var queued_mount_id := str(raw_mount_id)
			if not queued_mount_id.is_empty():
				pinned[queued_mount_id] = true
		var next_fishing_unlock_id := _fishing_next_visible_auto_unlock_action_id()
		if not next_fishing_unlock_id.is_empty():
			pinned[next_fishing_unlock_id] = true
	for raw_card in action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if bool(card.get("unlock_ceremony_active", false)) or bool(card.get("unlock_ceremony_pending", false)):
			var ceremony_action_id := str(card.get("action_id", ""))
			if ceremony_action_id.is_empty():
				var ceremony_action := card.get("action", {}) as Dictionary
				ceremony_action_id = str(ceremony_action.get("id", ""))
			if not ceremony_action_id.is_empty():
				pinned[ceremony_action_id] = true
	var pending_heist_key := str(pending_thieving_trophy_reward_float.get("key", "")) if not pending_thieving_trophy_reward_float.is_empty() else ""
	if pending_heist_key.begins_with("thieving_heist:"):
		pinned["heist:%s" % pending_heist_key.substr("thieving_heist:".length())] = true
	for raw_module_key in module_ui_runtime.pin_preview_tokens.keys():
		if int(module_ui_runtime.pin_preview_tokens.get(raw_module_key, 0)) <= 0:
			continue
		var preview_track_id := ModuleUiRuntime.lazy_track_id(str(raw_module_key), selected_skill_id)
		if not preview_track_id.is_empty():
			pinned[preview_track_id] = true
	var now_msec := Time.get_ticks_msec()
	if (
		not module_ui_recent_pin_prune_hold_track_id.is_empty()
		and module_ui_recent_pin_prune_hold_skill_id == selected_skill_id
		and now_msec < module_ui_recent_pin_prune_hold_until_msec
	):
		pinned[module_ui_recent_pin_prune_hold_track_id] = true
	elif now_msec >= module_ui_recent_pin_prune_hold_until_msec:
		module_ui_recent_pin_prune_hold_skill_id = ""
		module_ui_recent_pin_prune_hold_track_id = ""
		module_ui_recent_pin_prune_hold_until_msec = 0
	return pinned


func _detail_lazy_entry_is_pinned(lazy_entry: Dictionary, pinned: Dictionary) -> bool:
	var track_id := str(lazy_entry.get("track_id", ""))
	if not track_id.is_empty() and pinned.has(track_id):
		return true
	if str(lazy_entry.get("kind", "")) == "fishing_area":
		for raw_method_id in lazy_entry.get("method_ids", []) as Array:
			if pinned.has(str(raw_method_id)):
				return true
	return false


func _detail_lazy_entry_height(lazy_entry: Dictionary) -> float:
	var entry_data := lazy_entry.get("entry", {}) as Dictionary
	var action := entry_data.get("action", {}) as Dictionary
	match str(lazy_entry.get("kind", "")):
		"heist":
			return float(THIEVING_HEIST_CARD_HEIGHT)
		"passive":
			return _passive_firepit_surface()._passive_action_card_height(action)
		"fishing_area":
			return float(ACTION_CARD_HEIGHT)
		"fishing_offer":
			return _fishing_ui_surface()._fishing_offer_height(str(lazy_entry.get("offer_id", "")))
		"lock_tip", "activity_start_tip", "skill_swipe_tip":
			return DETAIL_LAZY_TIP_HEIGHT
	return _activity_card_root_height_for_action(action) + _action_mat_collection_layout_height(selected_skill_id, action)


func _detail_lazy_track_id_for_entry(entry_data: Dictionary) -> String:
	if str(entry_data.get("kind", "")) == "thieving_heist":
		var heist := entry_data.get("heist", {}) as Dictionary
		return "heist:%s" % str(heist.get("id", ""))
	var action := entry_data.get("action", {}) as Dictionary
	return str(action.get("id", ""))


func _detail_lazy_viewport_buffer_px() -> float:
	if boot_detail_render_in_progress:
		return DETAIL_LAZY_BOOT_VIEWPORT_BUFFER_PX
	if _fishing_rework_active_for_skill(selected_skill_id):
		return FISHING_DETAIL_LAZY_VIEWPORT_BUFFER_PX
	return DETAIL_LAZY_VIEWPORT_BUFFER_PX


func _detail_lazy_unmount_buffer_px() -> float:
	if _fishing_rework_active_for_skill(selected_skill_id):
		return FISHING_DETAIL_LAZY_UNMOUNT_BUFFER_PX
	return DETAIL_LAZY_UNMOUNT_BUFFER_PX


func _detail_lazy_entry_rect_for_viewport(lazy_entry: Dictionary) -> Rect2:
	var stack_host := _valid_control_ref(lazy_entry.get("stack_host"))
	var stack := _valid_control_ref(detail_lazy_stack)
	if stack == null:
		stack = _detail_actions_stack()
	if stack_host != null and stack != null and is_instance_valid(stack) and stack_host.is_inside_tree():
		var actual_rect := _detail_control_rect_in_stack(stack_host, stack)
		if actual_rect.size.y > 1.0:
			return actual_rect
	var entry_y := float(lazy_entry.get("y", 0.0)) + _detail_actions_top_spacer_height()
	return Rect2(
		Vector2(0.0, entry_y),
		Vector2(_skill_content_width(), float(lazy_entry.get("height", 0.0)))
	)


func _detail_lazy_entry_in_viewport(lazy_entry: Dictionary) -> bool:
	var stack_host := _valid_control_ref(lazy_entry.get("stack_host"))
	if lazy_entry.has("stack_host") and stack_host == null:
		return false
	var scroll_y := _detail_lazy_scroll_y()
	var viewport_buffer := _detail_lazy_viewport_buffer_px()
	var view_top := scroll_y - viewport_buffer
	var view_bottom := scroll_y + _detail_lazy_viewport_height() + viewport_buffer
	var entry_rect := _detail_lazy_entry_rect_for_viewport(lazy_entry)
	var entry_y := entry_rect.position.y
	var entry_bottom := entry_y + entry_rect.size.y
	return entry_rect.size.y > 1.0 and entry_bottom >= view_top and entry_y <= view_bottom


func _detail_lazy_entry_in_visible_viewport(lazy_entry: Dictionary) -> bool:
	var stack_host := _valid_control_ref(lazy_entry.get("stack_host"))
	if lazy_entry.has("stack_host") and stack_host == null:
		return false
	var scroll_y := _detail_lazy_scroll_y()
	var view_top := scroll_y
	var view_bottom := scroll_y + _detail_lazy_viewport_height()
	var entry_rect := _detail_lazy_entry_rect_for_viewport(lazy_entry)
	var entry_y := entry_rect.position.y
	var entry_bottom := entry_y + entry_rect.size.y
	return entry_rect.size.y > 1.0 and entry_bottom >= view_top and entry_y <= view_bottom


func _detail_lazy_entry_intersects_scroll_window(lazy_entry: Dictionary, target_scroll_y: float, viewport_buffer: float) -> bool:
	var stack_host := _valid_control_ref(lazy_entry.get("stack_host"))
	if lazy_entry.has("stack_host") and stack_host == null:
		return false
	var view_top := maxf(0.0, target_scroll_y - maxf(0.0, viewport_buffer))
	var view_bottom := target_scroll_y + _detail_lazy_viewport_height() + maxf(0.0, viewport_buffer)
	var entry_rect := _detail_lazy_entry_rect_for_viewport(lazy_entry)
	var entry_y := entry_rect.position.y
	var entry_bottom := entry_y + entry_rect.size.y
	return entry_rect.size.y > 1.0 and entry_bottom >= view_top and entry_y <= view_bottom


func _sync_fishing_detail_visible_viewport_cards(max_mounts: int = -1) -> int:
	if current_screen != "skill" or not _fishing_rework_active_for_skill(selected_skill_id):
		return 0
	if detail_lazy_plan.is_empty() or _valid_control_ref(detail_lazy_stack) == null or _valid_control_ref(detail_actions_scroll) == null:
		return 0
	var content_width := _skill_content_width()
	var actions_width := content_width
	var mounted_count := 0
	var previous_mount_context := detail_lazy_mount_trace_context
	detail_lazy_mount_trace_context = "visible_viewport_fill"
	for raw_lazy_entry in detail_lazy_plan:
		if max_mounts >= 0 and mounted_count >= max_mounts:
			break
		var lazy_entry := raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if not _detail_lazy_entry_in_visible_viewport(lazy_entry):
			continue
		if _skill_detail_surface()._detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, false):
			mounted_count += 1
	detail_lazy_mount_trace_context = previous_mount_context
	if mounted_count > 0:
		detail_lazy_mounted_this_frame = true
	return mounted_count


func _sync_detail_lazy_cards_for_scroll_window(target_scroll_y: float, viewport_buffer := ACTIVITY_JUMP_ARROW_LANDING_PREFILL_BUFFER_PX) -> int:
	if current_screen != "skill":
		return 0
	if detail_lazy_plan.is_empty() or _valid_control_ref(detail_lazy_stack) == null or _valid_control_ref(detail_actions_scroll) == null:
		return 0
	var content_width := _skill_content_width()
	var actions_width := content_width
	var mounted_count := 0
	var previous_mount_context := detail_lazy_mount_trace_context
	detail_lazy_mount_trace_context = "jump_landing_prefill"
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if not _detail_lazy_entry_intersects_scroll_window(lazy_entry, target_scroll_y, viewport_buffer):
			continue
		if _skill_detail_surface()._detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, false):
			mounted_count += 1
	detail_lazy_mount_trace_context = previous_mount_context
	if mounted_count > 0:
		detail_lazy_mounted_this_frame = true
		detail_lazy_all_mounted_cache_frame = -1
	return mounted_count


func _detail_lazy_can_build_offscreen_cached_entry(skill_id: String) -> bool:
	if _fishing_rework_active_for_skill(skill_id):
		return false
	return true


func _detail_lazy_should_mount_entry(lazy_entry: Dictionary, pinned: Dictionary, plan_index: int) -> bool:
	if bool(lazy_entry.get("mounted", false)):
		return false
	var kind := str(lazy_entry.get("kind", ""))
	var initial_force_count := _detail_lazy_initial_force_mount_count_for_skill(selected_skill_id)
	if kind in ["lock_tip", "activity_start_tip", "skill_swipe_tip"]:
		return plan_index < initial_force_count
	if _detail_lazy_entry_is_pinned(lazy_entry, pinned):
		return true
	if _detail_lazy_mount_should_wait_for_scroll(lazy_entry):
		return false
	if plan_index < initial_force_count and _detail_lazy_scroll_y() <= DETAIL_LAZY_VIEWPORT_BUFFER_PX:
		return true
	return _detail_lazy_entry_in_viewport(lazy_entry)


func _detail_lazy_mount_should_wait_for_scroll(lazy_entry: Dictionary) -> bool:
	if not detail_scroll_visual_work_this_frame:
		return false
	if not _fishing_rework_active_for_skill(selected_skill_id):
		return false
	if lazy_entry.has("cached_root"):
		return false
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		var max_scroll := float(detail_actions_scroll.get_max_scroll_vertical())
		if max_scroll > 0.0 and _detail_lazy_scroll_y() >= max_scroll - 1.0:
			return false
	return str(lazy_entry.get("kind", "")) in ["action", "passive", "heist", "fishing_area", "fishing_offer"]


func _detail_lazy_should_sync_visible_window() -> bool:
	if detail_lazy_plan.is_empty() or _valid_control_ref(detail_lazy_stack) == null:
		return false
	if detail_lazy_last_scroll < -0.5:
		return true
	var scroll_y := _detail_lazy_scroll_y()
	if absf(scroll_y - detail_lazy_last_scroll) > 8.0:
		return true
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if _detail_lazy_entry_in_viewport(lazy_entry):
			return true
	var pinned := _detail_lazy_pinned_track_ids()
	if pinned.is_empty():
		return false
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		if _detail_lazy_entry_is_pinned(lazy_entry, pinned):
			return true
	return false


func _detail_lazy_slot_has_real_content(slot: Control) -> bool:
	if slot == null or not is_instance_valid(slot):
		return false
	for child in slot.get_children():
		if child == null or not is_instance_valid(child):
			continue
		if child is Control and bool(child.get_meta("detail_lazy_placeholder", false)):
			continue
		if child is CanvasItem and (child as CanvasItem).modulate.a <= 0.01:
			continue
		if child is Control:
			var child_control := child as Control
			if bool(child_control.get_meta("detail_lazy_render_culled", false)):
				return true
			if not child_control.visible or child_control.is_queued_for_deletion():
				continue
			if maxf(child_control.custom_minimum_size.y, child_control.size.y) <= 1.0:
				continue
		return true
	return false


func _detail_lazy_prepare_host_for_mount(stack_host: Control, placeholder: Control) -> void:
	if placeholder == null or not is_instance_valid(placeholder):
		return
	if stack_host != null and is_instance_valid(stack_host) and stack_host.has_meta("detail_lazy_placeholder"):
		stack_host.remove_meta("detail_lazy_placeholder")
	if placeholder == stack_host:
		if placeholder.has_meta("detail_lazy_placeholder"):
			placeholder.remove_meta("detail_lazy_placeholder")
		return
	var parent := placeholder.get_parent()
	if parent != null and is_instance_valid(parent):
		parent.remove_child(placeholder)
	placeholder.queue_free()


func _detail_lazy_add_child_to_host(host: Control, child: Control, content_width: float, actions_width: float) -> void:
	if DisplayServer.get_name() == "headless":
		_fill_headless_null_textures(child)
	var previous_height := maxf(host.custom_minimum_size.y, host.size.y)
	var child_height := child.custom_minimum_size.y
	if child_height <= 1.0:
		child_height = child.size.y
	var host_height := maxf(1.0, child_height)
	host.custom_minimum_size.y = host_height
	if absf(host.size.y - host_height) > 0.5 or bool(host.get_meta("detail_lazy_placeholder", false)):
		host.size.y = host_height
	host.update_minimum_size()
	if absf(actions_width - content_width) <= 0.001:
		host.add_child(child)
		_play_collapsed_host_squeeze_if_needed(host, child, previous_height, host_height)
		return
	child.anchor_left = 0.0
	child.anchor_right = 0.0
	child.anchor_top = 0.0
	child.anchor_bottom = 0.0
	child.size = Vector2(content_width, maxf(1.0, child_height))
	child.position = Vector2((actions_width - content_width) * 0.5, 0.0)
	child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	host.add_child(child)
	_play_collapsed_host_squeeze_if_needed(host, child, previous_height, host_height)


func _fill_headless_null_textures(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var fallback := visual_texture_cache._visual_fallback_texture()
	if node is TextureRect:
		var texture_rect := node as TextureRect
		if texture_rect.texture == null:
			texture_rect.texture = fallback
		texture_rect.visible = false
	if node is TextureButton:
		var texture_button := node as TextureButton
		if texture_button.texture_normal == null:
			texture_button.texture_normal = fallback
		if texture_button.texture_pressed == null:
			texture_button.texture_pressed = texture_button.texture_normal
		if texture_button.texture_hover == null:
			texture_button.texture_hover = texture_button.texture_normal
		if texture_button.texture_disabled == null:
			texture_button.texture_disabled = texture_button.texture_normal
		if texture_button.texture_focused == null:
			texture_button.texture_focused = texture_button.texture_normal
	for child in node.get_children():
		_fill_headless_null_textures(child)


func _play_collapsed_host_squeeze_if_needed(host: Control, child: Control, previous_height: float, target_height: float) -> void:
	if host == null or child == null or not is_instance_valid(host) or not is_instance_valid(child):
		return
	if not bool(child.get_meta("module_ui_collapsed_squeeze", false)):
		return
	var module_key := ModuleUiRuntime.normalize(child.get_meta("module_ui_key", ""))
	if module_key.is_empty() or module_key != module_ui_animating_collapse_key:
		return
	var start_height := maxf(previous_height, float(child.get_meta("module_ui_full_height", 0.0)))
	if start_height <= target_height + 8.0:
		if module_ui_animating_collapse_key == module_key:
			module_ui_animating_collapse_key = ""
		return
	_kill_module_list_transition_tween(host)
	var original_clip := host.clip_contents
	host.clip_contents = true
	_set_module_root_layout_height(host, start_height)
	child.size.y = start_height
	_set_collapsed_module_title_lift(child, false, true)
	_set_collapsed_module_title_lift(child, true, false)
	var tween := create_tween()
	host.set_meta("module_list_transition_tween", tween)
	var host_id := host.get_instance_id()
	var child_id := child.get_instance_id()
	tween.tween_method(_apply_collapsed_host_squeeze_height.bind(host_id, child_id), start_height, target_height, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_collapsed_host_squeeze_animation.bind(host_id, child_id, module_key, target_height, original_clip))


func _apply_collapsed_host_squeeze_height(value: float, host_id: int, child_id: int) -> void:
	var live_host := _valid_control_ref(instance_from_id(host_id))
	if live_host != null:
		_set_module_root_layout_height(live_host, value)
	var live_child := _valid_control_ref(instance_from_id(child_id))
	if live_child != null:
		live_child.size.y = value


func _finish_collapsed_host_squeeze_animation(host_id: int, child_id: int, module_key: String, target_height: float, original_clip: bool) -> void:
	var live_host := _valid_control_ref(instance_from_id(host_id))
	if live_host != null:
		_set_module_root_layout_height(live_host, target_height)
		live_host.clip_contents = original_clip
		if live_host.has_meta("module_list_transition_tween"):
			live_host.remove_meta("module_list_transition_tween")
	var live_child := _valid_control_ref(instance_from_id(child_id))
	if live_child != null:
		live_child.size.y = target_height
	if module_ui_animating_collapse_key == module_key:
		module_ui_animating_collapse_key = ""


func _detail_lazy_entry_kind(lazy_entry: Dictionary) -> String:
	return str(lazy_entry.get("kind", ""))


func _detail_lazy_kind_is_action_backed(kind: String) -> bool:
	return kind == "action" or kind == "passive"


func _detail_lazy_kind_is_fishing_module(kind: String) -> bool:
	return _detail_lazy_kind_is_action_backed(kind) or kind == "fishing_area" or kind == "fishing_offer"


func _detail_lazy_kind_is_module(kind: String) -> bool:
	return kind == "heist" or _detail_lazy_kind_is_fishing_module(kind)


func _detail_lazy_module_ui_key(lazy_entry: Dictionary, skill_id: String) -> String:
	match _detail_lazy_entry_kind(lazy_entry):
		"heist":
			var heist := (lazy_entry.get("entry") as Dictionary).get("heist", {}) as Dictionary
			return ModuleUiRuntime.thieving_heist(str(heist.get("id", "")))
		"passive", "action":
			var action := (lazy_entry.get("entry") as Dictionary).get("action", {}) as Dictionary
			return ModuleUiRuntime.action_for_record(skill_id, action, FISHING_ACTION_ID_ALIASES)
		"fishing_area":
			return ModuleUiRuntime.fishing_area(fishing_runtime.area_module_key(skill_id, lazy_entry.get("area_def", {}) as Dictionary))
		"fishing_offer":
			return ModuleUiRuntime.fishing_offer(str(lazy_entry.get("offer_id", "")))
	return ""


func _module_collapsed_squeeze_height() -> float:
	return MODULE_COLLAPSED_ROW_HEIGHT


func _module_root_full_height(root: Control) -> float:
	if root == null or not is_instance_valid(root):
		return _activity_card_root_height()
	if root.has_meta("module_ui_full_height"):
		return maxf(1.0, float(root.get_meta("module_ui_full_height")))
	return maxf(1.0, maxf(root.custom_minimum_size.y, root.size.y))


func _set_module_root_layout_height(root: Control, height: float) -> void:
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	var clamped_height := maxf(1.0, height)
	root.custom_minimum_size = Vector2(root.custom_minimum_size.x, clamped_height)
	if root.size.y <= 1.0 or absf(root.size.y - clamped_height) > 0.5:
		root.size.y = clamped_height
	root.update_minimum_size()


func _find_named_control_descendant(root: Node, node_name: String) -> Control:
	if root == null or not is_instance_valid(root):
		return null
	if root.name == node_name and root is Control:
		return root as Control
	for child in root.get_children():
		var found := _find_named_control_descendant(child, node_name)
		if found != null:
			return found
	return null


func _find_module_card_face(root: Control, module_key: String) -> Control:
	if root == null or not is_instance_valid(root):
		return null
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	for child in root.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		if ModuleUiRuntime.normalize(child_control.get_meta("module_ui_key", "")) == normalized_key:
			return child_control
		var found := _find_module_card_face(child_control, normalized_key)
		if found != null:
			return found
	return null


func _find_marked_module_title_label(root: Node) -> Label:
	if root == null or not is_instance_valid(root):
		return null
	var control := root as Control
	if control != null and control.has_meta("module_ui_title_label_id"):
		var title := _valid_label_ref(instance_from_id(int(control.get_meta("module_ui_title_label_id", 0))))
		if title != null:
			return title
	if root is Label and bool((root as Label).get_meta("module_ui_title_label", false)):
		return root as Label
	for child in root.get_children():
		var found := _find_marked_module_title_label(child)
		if found != null:
			return found
	return null


func _find_top_module_title_label(root: Node) -> Label:
	var best := {}
	_collect_top_module_title_label(root, best)
	return best.get("label", null) as Label


func _collect_top_module_title_label(root: Node, best: Dictionary) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is Label:
		var label := root as Label
		if not label.text.strip_edges().is_empty():
			var label_width := maxf(label.size.x, label.custom_minimum_size.x)
			if label_width > 160.0:
				var label_y := label.global_position.y if label.is_inside_tree() else label.position.y
				if label_y < float(best.get("y", INF)):
					best["label"] = label
					best["y"] = label_y
	for child in root.get_children():
		_collect_top_module_title_label(child, best)


func _module_title_label_for_lift(root: Control) -> Label:
	var title := _find_marked_module_title_label(root)
	if title != null:
		return title
	return _find_top_module_title_label(root)


func _kill_collapsed_module_title_tween(title: Label) -> void:
	_kill_meta_tween(title, "module_collapsed_title_tween")


func _set_collapsed_module_title_lift(root: Control, collapsed: bool, instant := true) -> void:
	var title := _module_title_label_for_lift(root)
	if title == null or not is_instance_valid(title):
		return
	if not title.has_meta("module_title_base_position"):
		title.set_meta("module_title_base_position", title.position)
	var base_position := _meta_vector2(title, "module_title_base_position", title.position)
	var target_position := base_position + Vector2(0.0, MODULE_COLLAPSED_TITLE_LIFT_Y if collapsed else 0.0)
	_kill_collapsed_module_title_tween(title)
	if instant:
		title.position = target_position
		return
	var tween := create_tween()
	title.set_meta("module_collapsed_title_tween", tween)
	tween.tween_property(title, "position", target_position, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var title_id := title.get_instance_id()
	tween.finished.connect(_finish_collapsed_module_title_lift.bind(title_id, target_position))


func _finish_collapsed_module_title_lift(title_id: int, target_position: Vector2) -> void:
	var live_title := _valid_control_ref(instance_from_id(title_id))
	if live_title != null:
		live_title.position = target_position
		if live_title.has_meta("module_collapsed_title_tween"):
			live_title.remove_meta("module_collapsed_title_tween")


func _set_collapsed_module_visual_clipping(root: Control, module_key: String, collapsed: bool, title_instant := true) -> void:
	if root == null or not is_instance_valid(root):
		return
	_set_collapsed_module_title_lift(root, collapsed, title_instant)
	var card_face := _find_module_card_face(root, module_key)
	if card_face != null:
		if not card_face.has_meta("module_ui_original_face_clip_contents"):
			card_face.set_meta("module_ui_original_face_clip_contents", card_face.clip_contents)
		card_face.clip_contents = true if collapsed else bool(card_face.get_meta("module_ui_original_face_clip_contents", false))
	var clip_host := _find_named_control_descendant(root, "ModulePinClipBox")
	if clip_host == null:
		return
	if collapsed:
		if clip_host.get_parent() != root:
			var original_parent := clip_host.get_parent() as Control
			if original_parent != null and is_instance_valid(original_parent):
				clip_host.set_meta("module_pin_original_parent_id", original_parent.get_instance_id())
				clip_host.set_meta("module_pin_original_position", clip_host.position)
				var global_position := clip_host.global_position
				original_parent.remove_child(clip_host)
				root.add_child(clip_host)
				clip_host.global_position = global_position
		var badge := _module_pin_badge(root)
		if badge == null:
			for child in clip_host.get_children():
				if child is TextureButton:
					badge = child as TextureButton
					break
		if badge != null:
			_set_module_pin_badge_clip_enabled(badge, false)
		return
	var restored_badge: TextureButton = null
	for child in clip_host.get_children():
		if child is TextureButton:
			restored_badge = child as TextureButton
			break
	if clip_host.has_meta("module_pin_original_parent_id"):
		var parent := _valid_control_ref(instance_from_id(int(clip_host.get_meta("module_pin_original_parent_id"))))
		if parent != null and clip_host.get_parent() != parent:
			if clip_host.get_parent() != null:
				clip_host.get_parent().remove_child(clip_host)
			parent.add_child(clip_host)
			clip_host.position = _meta_vector2(clip_host, "module_pin_original_position", clip_host.position)
		clip_host.remove_meta("module_pin_original_parent_id")
		if clip_host.has_meta("module_pin_original_position"):
			clip_host.remove_meta("module_pin_original_position")
	if restored_badge != null:
		_set_module_pin_badge_clip_enabled(restored_badge, true)


func _apply_collapsed_module_squeeze(root: Control, module_key: String, collapsed: bool) -> Control:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if root == null or not is_instance_valid(root) or normalized_key.is_empty():
		return root
	if root.name == "CollapsedModuleSqueeze" and root.get_child_count() > 0:
		if root.get_child_count() <= 0:
			return root
		var inner_root := root.get_child(0) as Control
		if inner_root == null or not is_instance_valid(inner_root):
			return root
		root.remove_child(inner_root)
		root = inner_root
	if bool(root.get_meta("module_ui_collapsed_squeeze", false)):
		if collapsed:
			_set_module_root_layout_height(root, _module_collapsed_squeeze_height())
			root.clip_contents = false
			_set_collapsed_module_visual_clipping(root, normalized_key, true)
			return root
		root.set_meta("module_ui_collapsed_squeeze", false)
		root.remove_from_group("collapsed_module_rows")
		root.mouse_filter = int(root.get_meta("module_ui_original_mouse_filter", Control.MOUSE_FILTER_IGNORE))
		root.clip_contents = bool(root.get_meta("module_ui_original_clip_contents", false))
		_set_collapsed_module_visual_clipping(root, normalized_key, false)
		_set_module_root_layout_height(root, _module_root_full_height(root))
		return root
	if not root.has_meta("module_ui_full_height"):
		root.set_meta("module_ui_full_height", maxf(1.0, maxf(root.custom_minimum_size.y, root.size.y)))
	if not root.has_meta("module_ui_original_mouse_filter"):
		root.set_meta("module_ui_original_mouse_filter", int(root.mouse_filter))
	if not root.has_meta("module_ui_original_clip_contents"):
		root.set_meta("module_ui_original_clip_contents", root.clip_contents)
	root.set_meta("module_ui_key", normalized_key)
	if collapsed:
		_set_module_root_layout_height(root, _module_collapsed_squeeze_height())
		root.clip_contents = false
		root.mouse_filter = Control.MOUSE_FILTER_STOP
		root.set_meta("module_ui_collapsed_squeeze", true)
		_set_collapsed_module_visual_clipping(root, normalized_key, true)
		root.add_to_group("collapsed_module_rows")
		var row_input := _on_collapsed_module_row_gui_input.bind(normalized_key, root.get_instance_id())
		if not root.gui_input.is_connected(row_input):
			root.gui_input.connect(row_input)
		return root
	root.mouse_filter = int(root.get_meta("module_ui_original_mouse_filter", Control.MOUSE_FILTER_IGNORE))
	root.clip_contents = bool(root.get_meta("module_ui_original_clip_contents", false))
	root.set_meta("module_ui_collapsed_squeeze", false)
	root.remove_from_group("collapsed_module_rows")
	_set_collapsed_module_visual_clipping(root, normalized_key, false)
	_set_module_root_layout_height(root, _module_root_full_height(root))
	return root


func _apply_lazy_entry_module_squeeze(root: Control, lazy_entry: Dictionary, skill_id: String) -> Control:
	var module_key := _detail_lazy_module_ui_key(lazy_entry, skill_id)
	if module_key.is_empty():
		return root
	return _apply_collapsed_module_squeeze(root, module_key, _module_ui_is_collapsed(module_key))


func _detail_lazy_create_slot_for_entry(
	stack: VBoxContainer,
	skill_id: String,
	lazy_entry: Dictionary,
	content_width: float,
	actions_width: float
) -> void:
	var height := float(lazy_entry.get("height", 0.0))
	var placeholder := Control.new()
	placeholder.custom_minimum_size = Vector2(content_width, height)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder.set_meta("detail_lazy_placeholder", true)
	var module_key := _detail_lazy_module_ui_key(lazy_entry, skill_id)
	if not module_key.is_empty():
		placeholder.set_meta("module_ui_key", module_key)
	lazy_entry["placeholder"] = placeholder
	if skill_id == "thieving" and str(lazy_entry.get("kind", "")) == "heist":
		placeholder.custom_minimum_size.x = actions_width
		stack.add_child(placeholder)
		lazy_entry["stack_host"] = placeholder
		lazy_entry["direct_stack_child"] = true
	else:
		var stack_entry := _detail_stack_entry(placeholder, content_width, actions_width)
		if not module_key.is_empty():
			stack_entry.set_meta("module_ui_key", module_key)
		stack.add_child(stack_entry)
		lazy_entry["stack_host"] = stack_entry


func _detail_lazy_create_slots(stack: VBoxContainer, skill_id: String, content_width: float, actions_width: float) -> void:
	for lazy_entry in detail_lazy_plan:
		_detail_lazy_create_slot_for_entry(stack, skill_id, lazy_entry as Dictionary, content_width, actions_width)


func _detail_lazy_create_slots_batched(
	stack: VBoxContainer,
	skill_id: String,
	content_width: float,
	actions_width: float,
	batch_size: int
) -> bool:
	var created_since_yield := 0
	var batch_limit := maxi(1, batch_size)
	for lazy_entry in detail_lazy_plan:
		if current_screen != "skill" or selected_skill_id != skill_id:
			return false
		if stack == null or not is_instance_valid(stack):
			return false
		_detail_lazy_create_slot_for_entry(stack, skill_id, lazy_entry as Dictionary, content_width, actions_width)
		created_since_yield += 1
		if created_since_yield >= batch_limit:
			created_since_yield = 0
			await get_tree().process_frame
	return true


func _play_detail_lazy_fade_in(target: Control) -> void:
	if target == null or not is_instance_valid(target):
		return
	_kill_detail_lazy_reveal_tween(target)
	var base_y := target.position.y
	var base_scale := target.scale
	target.set_meta("detail_lazy_reveal_base_y", base_y)
	target.set_meta("detail_lazy_reveal_base_scale", base_scale)
	target.modulate.a = 0.0
	target.position.y = base_y + DETAIL_LAZY_SLIDE_IN_OFFSET_Y
	target.pivot_offset = target.size * 0.5
	target.scale = base_scale * DETAIL_LAZY_SCALE_IN_AMOUNT
	var tween := create_tween()
	target.set_meta("detail_lazy_reveal_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(target, "modulate:a", 1.0, DETAIL_LAZY_FADE_IN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position:y", base_y, DETAIL_LAZY_FADE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", base_scale, DETAIL_LAZY_FADE_IN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_finish_detail_lazy_reveal.bind(target.get_instance_id(), base_y, base_scale))


func _finish_detail_lazy_reveal(target_id: int, base_y: float, base_scale: Vector2) -> void:
	var target := _valid_control_ref(instance_from_id(target_id))
	if target == null or target.is_queued_for_deletion():
		return
	target.modulate.a = 1.0
	target.position.y = base_y
	target.scale = base_scale
	if target.has_meta("detail_lazy_reveal_tween"):
		target.remove_meta("detail_lazy_reveal_tween")
	if target.has_meta("detail_lazy_reveal_base_y"):
		target.remove_meta("detail_lazy_reveal_base_y")
	if target.has_meta("detail_lazy_reveal_base_scale"):
		target.remove_meta("detail_lazy_reveal_base_scale")


func _kill_detail_lazy_reveal_tween(target: Control) -> void:
	if target == null or not is_instance_valid(target):
		return
	_kill_meta_tween(target, "detail_lazy_reveal_tween")
	if target.has_meta("detail_lazy_reveal_base_y"):
		target.position.y = float(target.get_meta("detail_lazy_reveal_base_y"))
		target.remove_meta("detail_lazy_reveal_base_y")
	if target.has_meta("detail_lazy_reveal_base_scale"):
		target.scale = _meta_vector2(target, "detail_lazy_reveal_base_scale", target.scale)
		target.remove_meta("detail_lazy_reveal_base_scale")


func _cancel_boot_detail_completion() -> void:
	boot_detail_completion_token += 1
	boot_detail_render_queue.clear()
	boot_detail_scroll_locked = false


func _detail_eager_add_to_stack(stack: VBoxContainer, node: Control) -> void:
	if stack == null or not is_instance_valid(stack) or node == null or not is_instance_valid(node):
		return
	stack.add_child(node)
	if (
		detail_unlock_scroll_spacer != null
		and is_instance_valid(detail_unlock_scroll_spacer)
		and detail_unlock_scroll_spacer.get_parent() == stack
	):
		var target_index := clampi(detail_unlock_scroll_spacer.get_index(), 0, maxi(0, stack.get_child_count() - 1))
		stack.move_child(node, target_index)


func _detail_eager_add_activity_start_tip_below_content(stack: VBoxContainer, note: Control, content_width: float, actions_width: float) -> void:
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return
	var entry := _detail_stack_entry(note, content_width, actions_width)
	stack.add_child(entry)
	var insert_index := maxi(0, stack.get_child_count() - 1)
	for i in range(stack.get_child_count()):
		var child := stack.get_child(i)
		if child == entry:
			continue
		if child.name == "DetailActionsTopSpacer":
			insert_index = mini(insert_index, i + 1)
			continue
		if child.name == "DetailActionsBottomSpacer":
			insert_index = mini(insert_index, i)
			break
		insert_index = i + 1
		break
	stack.move_child(entry, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))


func _detail_stack_child_for_action(action_id: String) -> Control:
	var stack := _resolve_detail_lazy_stack()
	if stack == null or not is_instance_valid(stack):
		return null
	if action_id.is_empty():
		return null
	if not detail_action_card_nodes.has(action_id):
		_ensure_detail_lazy_entry_mounted(action_id)
	if not detail_action_card_nodes.has(action_id):
		return null
	var node := detail_action_card_nodes[action_id] as Control
	if node == null or not is_instance_valid(node):
		return null
	if node.get_parent() == stack:
		return node
	var parent := node.get_parent() as Control
	if parent != null and is_instance_valid(parent) and parent.get_parent() == stack:
		return parent
	return null


func _detail_eager_add_tutorial_note_after_action(action_id: String, note: Control, content_width: float, actions_width: float) -> Control:
	var stack := _resolve_detail_lazy_stack()
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return null
	var entry := _detail_stack_entry(note, content_width, actions_width)
	stack.add_child(entry)
	var anchor := _detail_stack_child_for_action(action_id)
	if anchor != null and is_instance_valid(anchor) and anchor.get_parent() == stack:
		stack.move_child(entry, clampi(anchor.get_index() + 1, 0, maxi(0, stack.get_child_count() - 1)))
	elif detail_unlock_scroll_spacer != null and is_instance_valid(detail_unlock_scroll_spacer) and detail_unlock_scroll_spacer.get_parent() == stack:
		stack.move_child(entry, clampi(detail_unlock_scroll_spacer.get_index(), 0, maxi(0, stack.get_child_count() - 1)))
	return entry


func _skill_swipe_tip_anchor_track_id(skill_id: String) -> String:
	var visible_action_count := 0
	var fallback_action_id := ""
	for raw_entry in _visible_detail_entries_for_skill(skill_id):
		var entry := raw_entry as Dictionary
		if str(entry.get("kind", "")) != "action":
			continue
		var action := entry.get("action", {}) as Dictionary
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		if skill_id == TUTORIAL_STARTER_SKILL_ID and action_id == TUTORIAL_LEVEL_TWO_ACTION_ID:
			return action_id
		visible_action_count += 1
		if visible_action_count == 2:
			fallback_action_id = action_id
	return fallback_action_id


func _detail_eager_add_smooth_tutorial_tip_after_action(action_id: String, note: Control, content_width: float, actions_width: float, group_name: String) -> Control:
	var stack := _resolve_detail_lazy_stack()
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return null
	var entry := _detail_stack_entry(note, content_width, actions_width)
	if entry != note and not group_name.is_empty():
		note.remove_from_group(group_name)
		entry.add_to_group(group_name)
	var target_height := maxf(1.0, entry.custom_minimum_size.y)
	entry.custom_minimum_size.y = 0.0
	entry.modulate.a = 0.0
	entry.clip_contents = true
	stack.add_child(entry)
	var anchor := _detail_stack_child_for_action(action_id)
	if anchor != null and is_instance_valid(anchor) and anchor.get_parent() == stack:
		stack.move_child(entry, clampi(anchor.get_index() + 1, 0, maxi(0, stack.get_child_count() - 1)))
	elif detail_unlock_scroll_spacer != null and is_instance_valid(detail_unlock_scroll_spacer) and detail_unlock_scroll_spacer.get_parent() == stack:
		stack.move_child(entry, clampi(detail_unlock_scroll_spacer.get_index(), 0, maxi(0, stack.get_child_count() - 1)))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(entry, "custom_minimum_size:y", target_height, TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(entry, "modulate:a", 1.0, TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_finish_smooth_tutorial_tip_entry_reveal.bind(entry.get_instance_id()))
	return entry


func _detail_eager_add_skill_swipe_tip_after_anchor(stack: VBoxContainer, note: Control, content_width: float, actions_width: float) -> Control:
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return null
	var anchor_id := _skill_swipe_tip_anchor_track_id(selected_skill_id)
	if not anchor_id.is_empty():
		var anchored_entry := _detail_eager_add_smooth_tutorial_tip_after_action(anchor_id, note, content_width, actions_width, "skill_swipe_tip_notes")
		if anchored_entry != null and is_instance_valid(anchored_entry):
			return anchored_entry
	var entry := _detail_stack_entry(note, content_width, actions_width)
	stack.add_child(entry)
	if detail_unlock_scroll_spacer != null and is_instance_valid(detail_unlock_scroll_spacer) and detail_unlock_scroll_spacer.get_parent() == stack:
		stack.move_child(entry, clampi(detail_unlock_scroll_spacer.get_index(), 0, maxi(0, stack.get_child_count() - 1)))
	return entry


func _detail_eager_add_smooth_tutorial_tip(stack: VBoxContainer, note: Control, content_width: float, actions_width: float, group_name: String) -> Control:
	if stack == null or not is_instance_valid(stack) or note == null or not is_instance_valid(note):
		return null
	var entry := _detail_stack_entry(note, content_width, actions_width)
	if entry != note and not group_name.is_empty():
		note.remove_from_group(group_name)
		entry.add_to_group(group_name)
	var target_height := maxf(1.0, entry.custom_minimum_size.y)
	entry.custom_minimum_size.y = 0.0
	entry.modulate.a = 0.0
	entry.clip_contents = true
	_detail_eager_add_to_stack(stack, entry)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(entry, "custom_minimum_size:y", target_height, TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(entry, "modulate:a", 1.0, TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_finish_smooth_tutorial_tip_entry_reveal.bind(entry.get_instance_id()))
	return entry


func _finish_smooth_tutorial_tip_entry_reveal(entry_id: int) -> void:
	var entry := _valid_control_ref(instance_from_id(entry_id))
	if entry != null:
		entry.clip_contents = false


func _tutorial_note_is_in_stack(note: Control, stack: VBoxContainer) -> bool:
	if note == null or stack == null or not is_instance_valid(note) or not is_instance_valid(stack):
		return false
	var parent := note.get_parent() as Control
	if parent == null or not is_instance_valid(parent):
		return false
	return parent == stack or parent.get_parent() == stack


func _tutorial_note_group_has_node_in_stack(group_name: String, stack: VBoxContainer) -> bool:
	for node in get_tree().get_nodes_in_group(group_name):
		var note := node as Control
		if _tutorial_note_is_in_stack(note, stack):
			return true
	return false


func _append_detail_eager_trailing_tips(stack: VBoxContainer, content_width: float, actions_width: float) -> void:
	if _activity_start_inline_tip_available(selected_skill_id):
		if _tutorial_note_group_has_node_in_stack("activity_start_tip_notes", stack):
			return
		var note := _activity_start_tip_note(content_width)
		_detail_eager_add_activity_start_tip_below_content(stack, note, content_width, actions_width)
		_fade_in_activity_start_tip_note(note)
	elif _onboarding_runtime()._skill_swipe_tip_available():
		call_deferred("_run_onboarding_swipe_tip_sequence")


func _append_detail_eager_entry(stack: VBoxContainer, skill_id: String, entry_data: Dictionary, content_width: float, actions_width: float) -> void:
	if str(entry_data.get("kind", "")) == "thieving_heist":
		var heist := entry_data.get("heist", {}) as Dictionary
		var heist_id := str(heist.get("id", ""))
		var track_id := "heist:%s" % heist_id
		if detail_rendered_action_ids.has(track_id):
			return
		detail_rendered_action_ids.append(track_id)
		var heist_module_key := ModuleUiRuntime.thieving_heist(heist_id)
		var heist_root := _thieving_surface()._build_thieving_heist_card(heist, actions_width)
		heist_root = _apply_collapsed_module_squeeze(heist_root, heist_module_key, _module_ui_is_collapsed(heist_module_key))
		_detail_eager_add_to_stack(stack, heist_root)
		detail_action_card_nodes[track_id] = heist_root
		return
	var action := entry_data.get("action", {}) as Dictionary
	var action_id := str(action.get("id", ""))
	if action_id.is_empty() or detail_rendered_action_ids.has(action_id):
		return
	detail_rendered_action_ids.append(action_id)
	var action_module_key := ModuleUiRuntime.action_for_record(skill_id, action, FISHING_ACTION_ID_ALIASES)
	if _is_passive_action(action):
		var passive_card := _passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
		passive_card["root"] = _apply_collapsed_module_squeeze(passive_card["root"] as Control, action_module_key, _module_ui_is_collapsed(action_module_key))
		var stack_entry := _detail_stack_entry(passive_card["root"] as Control, content_width, actions_width)
		_detail_eager_add_to_stack(stack, stack_entry)
		var card := passive_card["card"] as Dictionary
		card["entry"] = stack_entry
		_register_action_card(_action_key(skill_id, action_id), card)
		_detail_lazy_finalize_action_card(card, skill_id, action, action_id)
		detail_action_card_nodes[action_id] = stack_entry
	else:
		var built := _skill_detail_surface()._build_detail_interactive_action_card(skill_id, action, content_width, actions_width)
		built["card_root"] = _apply_collapsed_module_squeeze(built["card_root"] as Control, action_module_key, _module_ui_is_collapsed(action_module_key))
		var stack_entry := _detail_stack_entry(built["card_root"] as Control, content_width, actions_width)
		_detail_eager_add_to_stack(stack, stack_entry)
		var card := built["card"] as Dictionary
		card["entry"] = stack_entry
		_register_action_card(_action_key(skill_id, action_id), card)
		_detail_lazy_finalize_action_card(card, skill_id, action, action_id)
		detail_action_card_nodes[action_id] = stack_entry
	if _should_show_lock_click_tip(skill_id, action):
		_detail_eager_add_to_stack(stack, _detail_stack_entry(_lock_click_tip_note(content_width), content_width, actions_width))
	if _should_show_passive_module_tip(skill_id, action):
		_detail_eager_add_smooth_tutorial_tip(stack, _passive_module_tip_note(content_width), content_width, actions_width, "passive_module_tip_notes")
	if _should_show_silver_opportunity_tip(skill_id, action):
		_detail_eager_add_smooth_tutorial_tip(stack, _silver_opportunity_tip_note(content_width), content_width, actions_width, "silver_opportunity_tip_notes")


func _complete_boot_detail_cards_async() -> void:
	if boot_detail_render_queue.is_empty():
		boot_detail_scroll_locked = false
		return
	var stack := _valid_control_ref(detail_lazy_stack)
	if stack == null:
		boot_detail_render_queue.clear()
		boot_detail_scroll_locked = false
		return
	boot_detail_completion_token += 1
	var token := boot_detail_completion_token
	var skill_id := selected_skill_id
	var content_width := _skill_content_width()
	var actions_width := content_width
	while boot_detail_render_queue.size() > 0:
		if token != boot_detail_completion_token or current_screen != "skill":
			boot_detail_scroll_locked = false
			return
		for _i in range(BOOT_DETAIL_COMPLETE_BUDGET_PER_FRAME):
			if boot_detail_render_queue.is_empty():
				break
			if token != boot_detail_completion_token:
				boot_detail_scroll_locked = false
				return
			var entry_data := boot_detail_render_queue.pop_front() as Dictionary
			_append_detail_eager_entry(stack, skill_id, entry_data, content_width, actions_width)
		await get_tree().process_frame
	if token != boot_detail_completion_token or current_screen != "skill":
		boot_detail_scroll_locked = false
		return
	_append_detail_eager_trailing_tips(stack, content_width, actions_width)
	boot_detail_render_queue.clear()
	boot_detail_scroll_locked = false
	call_deferred("_sync_detail_actions_scroll_limit_deferred")


func _detail_lazy_fade_allowed(skill_id: String, action: Dictionary) -> bool:
	if action.is_empty():
		return false
	return _is_action_unlocked(skill_id, action)


func _detail_lazy_finalize_action_card(card: Dictionary, skill_id: String, action: Dictionary, action_id: String) -> void:
	_ensure_interactive_action_card_button(card, skill_id, action_id)
	_prepare_locked_activity_preview_fade(card, skill_id, action)
	_sync_locked_activity_preview_presence(card, skill_id, action)
	if _action_has_pending_unlock_readiness(action_id):
		card["unlock_ready_pending"] = true
		card.erase("lock_overlay_sync_key")
	if _action_matches_pending_unlock_preview(action_id):
		if _stage_activity_unlock_preview_once(action_id, card):
			card["fade_in_pending"] = true
	elif activity_unlock_preview_after_ceremony_id == action_id:
		if _stage_activity_unlock_preview_once(action_id, card, false):
			card["fade_in_pending"] = true
	var medal := card.get("medal") as TextureRect
	_skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, _is_action_unlocked(skill_id, action))
	if skill_id == "thieving":
		_thieving_surface()._sync_thieving_action_jail_overlay(card, action_id)
	if _action_has_mastery(action):
		_set_action_card_medal(card, medal, MasteryState.level(mastery, _action_key(skill_id, action_id)), true)
		_update_action_card_mastery_bar(card, skill_id, action_id, 0.0, true)
	var running_here := (running_skill_id == skill_id and running_action_id == action_id) or (event_running_skill_id == skill_id and event_running_action_id == action_id)
	_material_collection_surface()._sync_mat_collection_card(card, running_here, true)
	_tutorial_overlay_surface()._apply_onboarding_fight_action_card_stats_visibility(card, skill_id)
	_schedule_activity_start_highlight_if_needed(skill_id, action_id)


func _ensure_interactive_action_card_button(card: Dictionary, skill_id: String, action_id: String) -> void:
	if card.is_empty() or skill_id.is_empty() or action_id.is_empty():
		return
	var existing := card.get("button") as Button
	if existing != null and is_instance_valid(existing):
		existing.mouse_filter = Control.MOUSE_FILTER_STOP
		return
	var pop_card := card.get("pop") as Control
	if pop_card == null or not is_instance_valid(pop_card):
		return
	_attach_swipe_preview_activity_button(card, skill_id, action_id, pop_card)


func _clear_detail_lazy_cache_bin() -> void:
	_clear_detail_lazy_cached_roots()
	if detail_lazy_cache_bin != null and is_instance_valid(detail_lazy_cache_bin):
		detail_lazy_cache_bin.queue_free()
	detail_lazy_cache_bin = null


func _clear_detail_lazy_cached_roots() -> void:
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		var cached_root := _valid_control_ref(lazy_entry.get("cached_root"))
		if cached_root != null and not cached_root.is_queued_for_deletion():
			if cached_root.get_parent() != null:
				cached_root.queue_free()
			else:
				cached_root.free()
		lazy_entry.erase("cached_root")
		lazy_entry.erase("cached_card")


func _park_detail_lazy_cached_root(root: Control) -> void:
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	_set_canvas_item_modulate_if_changed(root, Color.WHITE)
	if root.get_parent() != null:
		root.get_parent().remove_child(root)
	_set_canvas_item_visible_if_changed(root, false)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _discard_detail_lazy_cached_root(lazy_entry: Dictionary) -> void:
	var cached_root := _valid_control_ref(lazy_entry.get("cached_root"))
	var stack_host := _valid_control_ref(lazy_entry.get("stack_host"))
	if cached_root != null and cached_root != stack_host and not cached_root.is_queued_for_deletion():
		if cached_root.get_parent() != null:
			cached_root.queue_free()
		else:
			cached_root.free()
	lazy_entry.erase("cached_root")
	lazy_entry.erase("cached_card")


func _detail_lazy_build_cached_entry(
	lazy_entry: Dictionary,
	skill_id: String,
	content_width: float,
	actions_width: float
) -> bool:
	if bool(lazy_entry.get("mounted", false)) or lazy_entry.has("cached_root"):
		return false
	var kind := str(lazy_entry.get("kind", ""))
	var root: Control = null
	var cached_card := {}
	var cached_built := {}
	match kind:
		"action", "passive":
			var entry_data := lazy_entry.get("entry", {}) as Dictionary
			if _fishing_rework_active_for_skill(skill_id):
				var action := entry_data.get("action", {}) as Dictionary
				if action.is_empty():
					return false
				if _is_passive_action(action):
					var passive_built := _passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
					root = passive_built.get("root") as Control
					cached_card = passive_built.get("card", {}) as Dictionary
				else:
					var built := _skill_detail_surface()._build_detail_interactive_action_card(skill_id, action, content_width, actions_width)
					root = built.get("card_root") as Control
					cached_card = built.get("card", {}) as Dictionary
			else:
				var cached: Dictionary = _skill_swipe_activity_surface()._build_swipe_preview_real_card_cache_entry(
					skill_id,
					entry_data,
					content_width,
					actions_width
				)
				root = cached.get("root") as Control
				cached_card = cached.get("card", {}) as Dictionary
		"fishing_area":
			var area_def := lazy_entry.get("area_def", {}) as Dictionary
			if area_def.is_empty():
				return false
			cached_built = _fishing_ui_surface()._build_fishing_area_module(skill_id, area_def, content_width)
			root = cached_built.get("root") as Control
			cached_card = cached_built.get("area_card", {}) as Dictionary
		"fishing_offer":
			root = _fishing_ui_surface()._build_fishing_offer_module(str(lazy_entry.get("offer_id", "")), content_width)
		_:
			return false
	if root == null or not is_instance_valid(root):
		return false
	_park_detail_lazy_cached_root(root)
	lazy_entry["cached_root"] = root
	if not cached_card.is_empty():
		lazy_entry["cached_card"] = cached_card
	if not cached_built.is_empty():
		lazy_entry["cached_built"] = cached_built
	return true


func _detail_lazy_entry_for_track_id(track_id: String) -> Dictionary:
	if track_id.is_empty():
		return {}
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if _detail_lazy_entry_matches_track_id(lazy_entry, track_id):
			return lazy_entry
	return {}


func _detail_lazy_entry_matches_track_id(lazy_entry: Dictionary, track_id: String) -> bool:
	if str(lazy_entry.get("track_id", "")) == track_id:
		return true
	if str(lazy_entry.get("kind", "")) == "fishing_area":
		for raw_method_id in lazy_entry.get("method_ids", []) as Array:
			if str(raw_method_id) == track_id:
				return true
	return false


func _apply_detail_lazy_entry_height(value: float, track_id: String) -> void:
	var lazy_entry := _detail_lazy_entry_for_track_id(track_id)
	if lazy_entry.is_empty():
		return
	var height := maxf(0.0, value)
	lazy_entry["height"] = height
	var placeholder := _valid_control_ref(lazy_entry.get("placeholder"))
	if placeholder != null:
		placeholder.custom_minimum_size.y = height
		placeholder.size.y = height
		placeholder.update_minimum_size()
		var placeholder_parent := placeholder.get_parent() as Container
		if placeholder_parent != null:
			placeholder_parent.queue_sort()
	var stack_host := _valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host != null:
		stack_host.custom_minimum_size.y = height
		stack_host.size.y = height
		stack_host.update_minimum_size()
		var stack_parent := stack_host.get_parent() as Container
		if stack_parent != null:
			stack_parent.queue_sort()


func _repair_detail_lazy_action_card_registration(track_id: String, skill_id: String) -> bool:
	var lazy_entry := _detail_lazy_entry_for_track_id(track_id)
	if lazy_entry.is_empty() or not bool(lazy_entry.get("mounted", false)):
		return false
	var kind := _detail_lazy_entry_kind(lazy_entry)
	if not _detail_lazy_kind_is_action_backed(kind):
		return false
	var card := lazy_entry.get("card", {}) as Dictionary
	if card.is_empty():
		return false
	var root := _valid_control_ref(card.get("root"))
	if root == null or not root.is_inside_tree():
		return false
	_register_action_card(_action_key(skill_id, track_id), card)
	return true


func _remount_detail_lazy_action_card(track_id: String, skill_id: String) -> bool:
	var lazy_entry := _detail_lazy_entry_for_track_id(track_id)
	if lazy_entry.is_empty():
		return false
	var kind := _detail_lazy_entry_kind(lazy_entry)
	if not _detail_lazy_kind_is_action_backed(kind):
		return false
	var stack_host := _valid_control_ref(lazy_entry.get("stack_host"))
	if stack_host == null or not stack_host.is_inside_tree():
		return false
	_kill_transient_tweens_in_subtree(stack_host)
	for child in stack_host.get_children():
		if child == null:
			continue
		stack_host.remove_child(child)
		child.queue_free()
	lazy_entry["mounted"] = false
	lazy_entry["placeholder"] = null
	lazy_entry.erase("card")
	return _skill_detail_surface()._detail_lazy_mount_item(lazy_entry, skill_id, _skill_content_width(), _skill_content_width(), false)


func _ensure_detail_lazy_entry_mounted(track_id: String) -> void:
	if track_id.is_empty() or detail_lazy_plan.is_empty():
		return
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		if not _detail_lazy_entry_matches_track_id(lazy_entry, track_id):
			continue
		if bool(lazy_entry.get("mounted", false)):
			return
		var content_width := _skill_content_width()
		var actions_width := content_width
		_skill_detail_surface()._detail_lazy_mount_item(lazy_entry, selected_skill_id, content_width, actions_width, false)
		return


func _detail_lazy_refresh_after_page_ready(expected_token := -1):
	if detail_lazy_plan.is_empty():
		return
	if expected_token >= 0 and expected_token != detail_lazy_refresh_token:
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	if detail_actions_scroll.get_child_count() <= 0:
		return
	var stack := detail_actions_scroll.get_child(0) as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return
	detail_lazy_stack = stack
	if detail_lazy_plan.is_empty():
		detail_rendered_action_ids.clear()
		detail_lazy_plan = _fishing_ui_surface()._build_fishing_detail_lazy_plan(selected_skill_id) if _fishing_rework_active_for_skill(selected_skill_id) else _skill_detail_surface()._build_detail_lazy_plan(selected_skill_id)
	var content_width := _skill_content_width()
	_detail_lazy_rebind_plan_to_existing_stack(stack, selected_skill_id, content_width, content_width)
	await get_tree().process_frame
	if expected_token >= 0 and expected_token != detail_lazy_refresh_token:
		return
	if _valid_control_ref(detail_lazy_stack) != stack or not is_instance_valid(stack):
		return
	var initial_force_count := _detail_lazy_initial_force_mount_count_for_skill(selected_skill_id)
	if _fishing_rework_active_for_skill(selected_skill_id):
		_skill_detail_surface()._sync_detail_lazy_visible_cards(true, initial_force_count)
	else:
		_skill_detail_surface()._sync_detail_lazy_visible_cards(true, -1)
	if _fishing_rework_active_for_skill(selected_skill_id):
		_skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, initial_force_count)
	_queue_detail_lazy_settle_warm_mount(selected_skill_id)


func _detail_lazy_plan_and_signature_for_skill(skill_id: String) -> Dictionary:
	if _fishing_rework_active_for_skill(skill_id):
		return {
			"plan": _fishing_ui_surface()._build_fishing_detail_lazy_plan(skill_id),
			"signature": _fishing_ui_surface()._fishing_detail_render_signature()
		}
	var previous_ids := detail_rendered_action_ids.duplicate()
	detail_rendered_action_ids.clear()
	var plan := _skill_detail_surface()._build_detail_lazy_plan(skill_id)
	var signature := detail_rendered_action_ids.duplicate()
	detail_rendered_action_ids = previous_ids
	return {
		"plan": plan,
		"signature": signature
	}


func _detail_lazy_runtime_entries_by_track_id(plan: Array) -> Dictionary:
	var lazy_entries_by_track_id := {}
	for raw_lazy_entry in plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		var track_id := str(lazy_entry.get("track_id", ""))
		if not track_id.is_empty():
			lazy_entries_by_track_id[track_id] = lazy_entry
	return lazy_entries_by_track_id


func _detail_lazy_copy_runtime_entry_state(target_entry: Dictionary, source_entry: Dictionary) -> void:
	for key in [
		"stack_host",
		"placeholder",
		"direct_stack_child",
		"mounted",
		"card",
		"built",
		"cached_root",
		"cached_card"
	]:
		if source_entry.has(key):
			target_entry[key] = source_entry[key]


func _detail_lazy_stack_insert_index_for_plan_index(stack: VBoxContainer, plan_index: int) -> int:
	if stack == null or not is_instance_valid(stack):
		return 0
	var entry_index := 0
	var fallback_index := stack.get_child_count()
	for child_index in range(stack.get_child_count()):
		var child := stack.get_child(child_index)
		var control := child as Control
		if control != null and control.name == "DetailActionsBottomSpacer":
			fallback_index = child_index
			break
		if control != null and control.name == "DetailActionsTopSpacer":
			continue
		if entry_index >= plan_index:
			return child_index
		entry_index += 1
	return clampi(fallback_index, 0, stack.get_child_count())


func _detail_lazy_find_action_plan_index(plan: Array, action_id: String) -> int:
	if action_id.is_empty():
		return -1
	for index in range(plan.size()):
		var lazy_entry := plan[index] as Dictionary
		if str(lazy_entry.get("track_id", "")) != action_id:
			continue
		if str(lazy_entry.get("kind", "")) == "action":
			return index
	return -1


func _ensure_activity_unlock_preview_lazy_entry(action_id: String) -> bool:
	if action_id.is_empty():
		return false
	if not _activity_preview_card_for_action_id(action_id, false).is_empty():
		return true
	if current_screen != "skill" or selected_skill_id.is_empty():
		return false
	var stack := _valid_control_ref(detail_lazy_stack)
	if stack == null:
		return false
	if detail_lazy_plan.is_empty() or not _skill_detail_stack_has_visible_modules(stack):
		return false
	var plan_data := _detail_lazy_plan_and_signature_for_skill(selected_skill_id)
	var new_plan := plan_data.get("plan", []) as Array
	var new_signature := plan_data.get("signature", []) as Array
	var preview_index := _detail_lazy_find_action_plan_index(new_plan, action_id)
	if preview_index < 0:
		return false
	var old_entries_by_track_id := _detail_lazy_runtime_entries_by_track_id(detail_lazy_plan)
	for raw_new_entry in new_plan:
		var new_entry := raw_new_entry as Dictionary
		var track_id := str(new_entry.get("track_id", ""))
		if track_id == action_id or not old_entries_by_track_id.has(track_id):
			continue
		_detail_lazy_copy_runtime_entry_state(new_entry, old_entries_by_track_id[track_id] as Dictionary)
	var preview_entry := new_plan[preview_index] as Dictionary
	var content_width := _skill_content_width()
	var actions_width := content_width
	var layout_snapshot := _capture_detail_module_layout_snapshot()
	_detail_lazy_create_slot_for_entry(stack, selected_skill_id, preview_entry, content_width, actions_width)
	var host := _valid_control_ref(preview_entry.get("stack_host"))
	if host == null:
		return false
	var insert_index := _detail_lazy_stack_insert_index_for_plan_index(stack, preview_index)
	stack.move_child(host, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))
	if not _skill_detail_surface()._detail_lazy_mount_item(preview_entry, selected_skill_id, content_width, actions_width, false):
		_detail_lazy_remove_unmounted_inserted_host(preview_entry)
		return false
	_detail_lazy_reorder_existing_hosts_for_plan(stack, new_plan, action_id)
	detail_lazy_plan = new_plan
	detail_rendered_action_ids = new_signature
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	_sync_current_skill_strip_detail_refs()
	if not layout_snapshot.is_empty():
		_skill_detail_surface().call_deferred("_play_detail_module_layout_transition", layout_snapshot)
	return true


func _detail_lazy_primary_child_control(host: Control) -> Control:
	if host == null or not is_instance_valid(host):
		return null
	for child in host.get_children():
		var control := child as Control
		if control == null:
			continue
		if bool(control.get_meta("detail_lazy_placeholder", false)):
			continue
		return control
	return host


func _detail_lazy_remove_unmounted_inserted_host(inserted_entry: Dictionary) -> void:
	var track_id := str(inserted_entry.get("track_id", ""))
	if not track_id.is_empty():
		detail_action_card_nodes.erase(track_id)
		_discard_action_card_key(_action_key(selected_skill_id, track_id))
	var host := _valid_control_ref(inserted_entry.get("stack_host"))
	if host == null or not is_instance_valid(host):
		return
	var parent := host.get_parent()
	if parent != null and is_instance_valid(parent):
		parent.remove_child(host)
	host.queue_free()


func _detail_lazy_reorder_existing_hosts_for_plan(stack: VBoxContainer, plan: Array, skip_track_id: String) -> void:
	if stack == null or not is_instance_valid(stack):
		return
	for plan_index in range(plan.size()):
		var lazy_entry := plan[plan_index] as Dictionary
		if str(lazy_entry.get("track_id", "")) == skip_track_id:
			continue
		var host := _valid_control_ref(lazy_entry.get("stack_host"))
		if host == null or not is_instance_valid(host) or host.get_parent() != stack:
			continue
		var target_index := _detail_lazy_stack_insert_index_for_plan_index(stack, plan_index)
		stack.move_child(host, clampi(target_index, 0, maxi(0, stack.get_child_count() - 1)))


func _try_refresh_detail_module_order_in_place() -> bool:
	if current_screen != "skill" or selected_skill_id.is_empty():
		return false
	if screen_render_in_progress or boot_detail_render_in_progress or _skill_swipe_navigation_blocks_detail_refresh():
		return false
	if skill_swipe_pending_full_finalize or _skill_swipe_handoff_cover_is_opaque_cream_transition():
		return false
	var stack := detail_lazy_stack
	if stack == null or not is_instance_valid(stack):
		stack = _detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return false
	if detail_lazy_plan.is_empty() or not _skill_detail_stack_has_visible_modules(stack):
		return false
	var layout_snapshot := _capture_detail_module_layout_snapshot()
	if layout_snapshot.is_empty():
		return false
	var plan_data := _detail_lazy_plan_and_signature_for_skill(selected_skill_id)
	var new_plan := plan_data.get("plan", []) as Array
	if new_plan.is_empty():
		return false
	var new_signature := plan_data.get("signature", []) as Array
	var old_entries_by_track_id := _detail_lazy_runtime_entries_by_track_id(detail_lazy_plan)
	var new_track_ids := {}
	for raw_new_entry in new_plan:
		var new_entry := raw_new_entry as Dictionary
		var track_id := str(new_entry.get("track_id", ""))
		if track_id.is_empty():
			continue
		new_track_ids[track_id] = true
		if old_entries_by_track_id.has(track_id):
			_detail_lazy_copy_runtime_entry_state(new_entry, old_entries_by_track_id[track_id] as Dictionary)
	var content_width := _skill_content_width()
	var actions_width := content_width
	for plan_index in range(new_plan.size()):
		var new_entry := new_plan[plan_index] as Dictionary
		var host := _valid_control_ref(new_entry.get("stack_host"))
		if host != null and is_instance_valid(host):
			continue
		_detail_lazy_create_slot_for_entry(stack, selected_skill_id, new_entry, content_width, actions_width)
		if _detail_lazy_should_mount_entry(new_entry, _detail_lazy_pinned_track_ids(), plan_index):
			_skill_detail_surface()._detail_lazy_mount_item(new_entry, selected_skill_id, content_width, actions_width, false)
	for raw_old_entry in detail_lazy_plan:
		var old_entry := raw_old_entry as Dictionary
		var old_track_id := str(old_entry.get("track_id", ""))
		if old_track_id.is_empty() or new_track_ids.has(old_track_id):
			continue
		_detail_lazy_remove_unmounted_inserted_host(old_entry)
	detail_lazy_stack = stack
	detail_lazy_plan = new_plan
	detail_rendered_action_ids = new_signature
	_detail_lazy_reorder_existing_hosts_for_plan(stack, detail_lazy_plan, "")
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	_sync_current_skill_strip_detail_refs()
	_skill_detail_surface().call_deferred("_play_detail_module_layout_transition", layout_snapshot)
	call_deferred("_sync_detail_actions_scroll_limit_deferred")
	return true


func _module_list_transition_key_for_control(control: Control) -> String:
	if control == null or not is_instance_valid(control):
		return ""
	var direct_key := ModuleUiRuntime.normalize(control.get_meta("module_ui_key", ""))
	if not direct_key.is_empty():
		if bool(control.get_meta("module_ui_pinned_shelf_copy", false)):
			return "pinned_shelf:%s" % direct_key
		if bool(control.get_meta("module_ui_pinned_page_copy", false)):
			return "pinned_page:%s" % direct_key
		return direct_key
	for child in control.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		var child_key := _module_list_transition_key_for_control(child_control)
		if not child_key.is_empty():
			return child_key
	return ""


func _capture_detail_module_layout_snapshot() -> Dictionary:
	if current_screen != "skill":
		return {}
	var stack := _detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return {}
	var snapshot := {}
	var occurrence_counts := {}
	for child in stack.get_children():
		var control := child as Control
		if control == null or not is_instance_valid(control):
			continue
		if control.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		var module_key := _module_list_transition_key_for_control(control)
		if module_key.is_empty():
			continue
		var occurrence_index := int(occurrence_counts.get(module_key, 0))
		occurrence_counts[module_key] = occurrence_index + 1
		var occurrence_key := "%s#%s" % [module_key, occurrence_index]
		snapshot[occurrence_key] = {
			"global_rect": control.get_global_rect()
		}
	return snapshot


func _detail_module_transition_child_visible(control: Control) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return true
	var viewport_rect := detail_actions_scroll.get_global_rect().grow(220.0)
	return viewport_rect.intersects(control.get_global_rect())


func _kill_module_list_transition_tween(control: Control) -> void:
	_kill_meta_tween(control, "module_list_transition_tween")


func _clear_module_ui_animating_collapse_key(module_key: String) -> void:
	if module_ui_animating_collapse_key == ModuleUiRuntime.normalize(module_key):
		module_ui_animating_collapse_key = ""


func _finish_module_list_transition(
	control_id: int,
	final_position: Vector2,
	final_scale: Vector2,
	final_minimum_size := Vector2(-1.0, -1.0),
	final_clip_contents := false
) -> void:
	var control := _valid_control_ref(instance_from_id(control_id))
	if control == null or control.is_queued_for_deletion():
		return
	control.position = final_position
	control.scale = final_scale
	control.modulate.a = 1.0
	control.pivot_offset = Vector2.ZERO
	if final_minimum_size.x >= 0.0 and final_minimum_size.y >= 0.0:
		if _control_tree_has_bool_meta(control, "module_ui_collapsed_squeeze"):
			final_minimum_size.y = _module_collapsed_squeeze_height()
		control.custom_minimum_size = final_minimum_size
		if bool(control.get_meta("module_ui_collapsed_squeeze", false)):
			control.size.y = final_minimum_size.y
	control.clip_contents = final_clip_contents
	if bool(control.get_meta("module_ui_collapsed_squeeze", false)):
		control.clip_contents = false
		_set_collapsed_module_visual_clipping(control, str(control.get_meta("module_ui_key", "")), true)
	if control.has_meta("module_list_transition_tween"):
		control.remove_meta("module_list_transition_tween")


func _control_tree_has_named_descendant(control: Control, target_name: String) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if control.name == target_name:
		return true
	for child in control.get_children():
		var child_control := child as Control
		if child_control != null and _control_tree_has_named_descendant(child_control, target_name):
			return true
	return false


func _control_tree_has_bool_meta(control: Control, meta_key: String) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if bool(control.get_meta(meta_key, false)):
		return true
	for child in control.get_children():
		var child_control := child as Control
		if child_control != null and _control_tree_has_bool_meta(child_control, meta_key):
			return true
	return false


func _first_control_with_bool_meta(control: Control, meta_key: String) -> Control:
	if control == null or not is_instance_valid(control):
		return null
	if bool(control.get_meta(meta_key, false)):
		return control
	for child in control.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		var found := _first_control_with_bool_meta(child_control, meta_key)
		if found != null:
			return found
	return null


func _sync_current_skill_strip_detail_refs() -> void:
	if skill_strip_ids.is_empty() or selected_skill_id.is_empty() or not skill_strip_refs.has(selected_skill_id):
		return
	var refs := skill_strip_refs[selected_skill_id] as Dictionary
	refs["action_card_nodes"] = detail_action_card_nodes.duplicate()
	refs["rendered_action_ids"] = detail_rendered_action_ids.duplicate()
	refs["lazy_plan"] = detail_lazy_plan.duplicate()
	refs["lazy_stack"] = detail_lazy_stack
	refs["lazy_last_scroll"] = detail_lazy_last_scroll
	skill_strip_refs[selected_skill_id] = refs

func _detail_lazy_rebind_plan_to_existing_stack(stack: VBoxContainer, skill_id: String, content_width: float, actions_width: float) -> void:
	var plan_index := 0
	for child in stack.get_children():
		if not child is Control:
			continue
		var control := child as Control
		if control.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		if plan_index >= detail_lazy_plan.size():
			break
		var lazy_entry := detail_lazy_plan[plan_index] as Dictionary
		lazy_entry["stack_host"] = control
		lazy_entry["direct_stack_child"] = skill_id == "thieving" and str(lazy_entry.get("kind", "")) == "heist"
		if bool(control.get_meta("detail_lazy_placeholder", false)):
			lazy_entry["mounted"] = false
			lazy_entry["placeholder"] = control
			plan_index += 1
			continue
		if _detail_lazy_slot_has_real_content(control):
			lazy_entry["mounted"] = true
			lazy_entry["placeholder"] = null
		else:
			lazy_entry["mounted"] = false
			var existing_placeholder: Control = null
			for slot_child in control.get_children():
				if slot_child is Control and bool((slot_child as Control).get_meta("detail_lazy_placeholder", false)):
					existing_placeholder = slot_child as Control
					break
			if existing_placeholder != null and is_instance_valid(existing_placeholder):
				lazy_entry["placeholder"] = existing_placeholder
			else:
				var placeholder := Control.new()
				placeholder.custom_minimum_size = Vector2(content_width, float(lazy_entry.get("height", _activity_card_root_height())))
				placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
				placeholder.set_meta("detail_lazy_placeholder", true)
				if bool(lazy_entry.get("direct_stack_child", false)):
					placeholder.custom_minimum_size.x = actions_width
				lazy_entry["placeholder"] = placeholder
				control.add_child(placeholder)
		plan_index += 1


func _detail_lazy_initial_force_mount_count_for_skill(skill_id: String) -> int:
	if skill_id == "fishing":
		return FISHING_DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT
	if skill_id == "woodcutting":
		return 1
	return DETAIL_LAZY_INITIAL_FORCE_MOUNT_COUNT


func _queue_detail_lazy_settle_warm_mount(skill_id: String) -> void:
	if not DETAIL_LAZY_SETTLE_WARM_MOUNT_ENABLED:
		return
	if current_screen != "skill" or skill_id.is_empty() or selected_skill_id != skill_id:
		return
	if _skill_swipe_loading_transition_active() or _skill_swipe_handoff_cover_is_cream_transition():
		return
	if detail_lazy_plan.is_empty() or _valid_control_ref(detail_lazy_stack) == null:
		return
	_skill_detail_surface()._prewarm_detail_card_style_resources()
	detail_lazy_settle_warm_mount_skill_id = skill_id


func _cancel_detail_lazy_settle_warm_mount() -> void:
	detail_lazy_settle_warm_mount_skill_id = ""


func _maybe_resume_fishing_detail_idle_warm_mount() -> void:
	if current_screen != "skill" or not _fishing_rework_active_for_skill(selected_skill_id):
		return
	if detail_lazy_settle_warm_mount_skill_id == selected_skill_id:
		return
	if detail_lazy_plan.is_empty() or _valid_control_ref(detail_lazy_stack) == null:
		return
	if _skill_detail_surface()._detail_lazy_all_mounted():
		return
	if _fishing_ui_surface()._fishing_detail_scroll_is_actively_moving():
		return
	_queue_detail_lazy_settle_warm_mount(selected_skill_id)


func _detail_lazy_idle_warm_mount_can_mount(skill_id: String, lazy_entry: Dictionary) -> bool:
	if not _fishing_rework_active_for_skill(skill_id):
		return true
	if web_fishing_perf_probe_enabled:
		return true
	if FISHING_DETAIL_IDLE_WARM_MOUNT_MAX_ACTION_CARDS <= 0:
		return true
	var kind := str(lazy_entry.get("kind", ""))
	var card_cost := 0
	if kind == "fishing_area":
		card_cost = 1 + (lazy_entry.get("method_ids", []) as Array).size()
	elif kind in ["action", "passive", "heist"]:
		card_cost = 1
	return action_cards.size() + card_cost <= FISHING_DETAIL_IDLE_WARM_MOUNT_MAX_ACTION_CARDS


func _finish_detail_lazy_settle_warm_mount(skill_id: String) -> void:
	detail_lazy_settle_warm_mount_skill_id = ""
	if current_screen == "skill" and selected_skill_id == skill_id:
		if not (_fishing_rework_active_for_skill(selected_skill_id) and detail_scroll_visual_work_this_frame):
			_sync_hidden_locked_activity_preview_layouts()
		_sync_detail_actions_scroll_limit()
		if _fishing_rework_active_for_skill(selected_skill_id):
			_fishing_ui_surface()._sync_fishing_detail_render_culling(true)


func _process_detail_lazy_settle_warm_mount() -> void:
	var skill_id := detail_lazy_settle_warm_mount_skill_id
	if skill_id.is_empty():
		return
	if current_screen != "skill" or selected_skill_id != skill_id:
		detail_lazy_settle_warm_mount_skill_id = ""
		return
	if _skill_swipe_loading_transition_active() or _skill_swipe_handoff_cover_is_cream_transition():
		detail_lazy_settle_warm_mount_skill_id = ""
		return
	if detail_lazy_plan.is_empty() or _valid_control_ref(detail_lazy_stack) == null:
		detail_lazy_settle_warm_mount_skill_id = ""
		return
	if _fishing_rework_active_for_skill(skill_id) and _fishing_ui_surface()._fishing_detail_scroll_is_actively_moving():
		return
	if detail_scroll_visual_work_this_frame:
		if not _fishing_rework_active_for_skill(skill_id) or _fishing_ui_surface()._fishing_detail_scroll_is_actively_moving():
			return
	var cached_count := 0
	var warm_mount_budget := FISHING_DETAIL_LAZY_SETTLE_WARM_MOUNT_BUDGET_PER_FRAME if _fishing_rework_active_for_skill(skill_id) else DETAIL_LAZY_SETTLE_WARM_MOUNT_BUDGET_PER_FRAME
	var content_width := _skill_content_width()
	var actions_width := content_width
	var previous_mount_context := detail_lazy_mount_trace_context
	detail_lazy_mount_trace_context = "settle_warm_process"
	var reached_warm_mount_limit := false
	for raw_lazy_entry in detail_lazy_plan:
		if cached_count >= warm_mount_budget:
			break
		var lazy_entry := raw_lazy_entry as Dictionary
		var kind := str(lazy_entry.get("kind", ""))
		if not _detail_lazy_kind_is_module(kind):
			continue
		if bool(lazy_entry.get("mounted", false)):
			continue
		if not _detail_lazy_idle_warm_mount_can_mount(skill_id, lazy_entry):
			reached_warm_mount_limit = true
			break
		if lazy_entry.has("cached_root"):
			if _fishing_rework_active_for_skill(skill_id):
				if _skill_detail_surface()._detail_lazy_mount_item(lazy_entry, skill_id, content_width, actions_width, false):
					cached_count += 1
			continue
		if _fishing_rework_active_for_skill(skill_id):
			if _skill_detail_surface()._detail_lazy_mount_item(lazy_entry, skill_id, content_width, actions_width, false):
				cached_count += 1
			continue
		if (
			_detail_lazy_can_build_offscreen_cached_entry(skill_id)
			and _detail_lazy_build_cached_entry(lazy_entry, skill_id, content_width, actions_width)
		):
			cached_count += 1
	detail_lazy_mount_trace_context = previous_mount_context
	if reached_warm_mount_limit:
		_finish_detail_lazy_settle_warm_mount(skill_id)
		return
	if cached_count > 0:
		return
	if _fishing_rework_active_for_skill(skill_id) and not _skill_detail_surface()._detail_lazy_all_mounted():
		return
	_finish_detail_lazy_settle_warm_mount(skill_id)


func _repair_blank_detail_lazy_stack() -> bool:
	if current_screen != "skill":
		return false
	if detail_lazy_plan.is_empty():
		return false
	var stack := _detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return false
	if _skill_detail_stack_has_visible_modules(stack):
		return false
	var bottom_spacer := _valid_control_ref(detail_unlock_scroll_spacer)
	var had_bottom_spacer := bottom_spacer != null and bottom_spacer.get_parent() == stack
	if had_bottom_spacer:
		stack.remove_child(bottom_spacer)
	for child in stack.get_children():
		var control := child as Control
		if control == null:
			continue
		if control.name == "DetailActionsTopSpacer":
			continue
		stack.remove_child(control)
		control.queue_free()
	detail_lazy_stack = stack
	detail_action_card_nodes.clear()
	for raw_key in action_cards.keys():
		var key := str(raw_key)
		if key.begins_with("%s:" % selected_skill_id) or (selected_skill_id == "thieving" and key.begins_with("thieving_heist:")):
			_discard_action_card_key(key)
	detail_rendered_action_ids.clear()
	detail_lazy_plan = _fishing_ui_surface()._build_fishing_detail_lazy_plan(selected_skill_id) if _fishing_rework_active_for_skill(selected_skill_id) else _skill_detail_surface()._build_detail_lazy_plan(selected_skill_id)
	var content_width := _skill_content_width()
	_detail_lazy_create_slots(stack, selected_skill_id, content_width, content_width)
	_skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, _detail_lazy_initial_force_mount_count_for_skill(selected_skill_id))
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	if had_bottom_spacer and bottom_spacer != null and is_instance_valid(bottom_spacer):
		stack.add_child(bottom_spacer)
	return _skill_detail_stack_has_visible_modules(stack)


func _maybe_repair_blank_detail_lazy_stack() -> void:
	if current_screen != "skill" or detail_lazy_plan.is_empty():
		return
	if _skill_swipe_handoff_cover_is_opaque_cream_transition() or skill_swipe_defer_initial_lazy_mount:
		return
	var now := Time.get_ticks_msec()
	if now < detail_lazy_blank_repair_next_msec:
		return
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack) or _skill_detail_stack_has_visible_modules(stack):
		return
	detail_lazy_blank_repair_next_msec = now + 1000
	_repair_blank_detail_lazy_stack()


func _render_detail_eager_card_list_async(stack: VBoxContainer, content_width: float, actions_width: float, max_main_entries: int = -1):
	detail_lazy_plan.clear()
	detail_lazy_last_scroll = -1.0
	detail_lazy_stack = stack
	boot_detail_render_queue.clear()
	var skill_id := selected_skill_id
	if max_main_entries < 0:
		detail_rendered_action_ids.clear()
		for entry in _visible_detail_entries_for_skill(skill_id):
			_append_detail_eager_entry(stack, skill_id, entry as Dictionary, content_width, actions_width)
			await get_tree().process_frame
		_append_detail_eager_trailing_tips(stack, content_width, actions_width)
		detail_lazy_stack = null
		return
	detail_rendered_action_ids.clear()
	var main_rendered := 0
	for entry in _visible_detail_entries_for_skill(skill_id):
		var entry_data := entry as Dictionary
		if main_rendered >= max_main_entries:
			boot_detail_render_queue.append(entry_data)
			continue
		_append_detail_eager_entry(stack, skill_id, entry_data, content_width, actions_width)
		main_rendered += 1
		await get_tree().process_frame


func _begin_detail_lazy_card_list_render(skill_id: String) -> void:
	_clear_detail_lazy_cache_bin()
	detail_rendered_action_ids.clear()
	detail_lazy_plan = _skill_detail_surface()._build_detail_lazy_plan(skill_id)
	_skill_swipe_activity_surface()._apply_global_swipe_real_card_cache_to_lazy_plan(skill_id)


func _finish_detail_lazy_card_list_render() -> void:
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_RENDER") == "1":
		print("SWIPE_RENDER_TRACE lazy_list skill=%s defer=%s cover=%s alpha=%.3f plan=%s" % [
			selected_skill_id,
			str(skill_swipe_defer_initial_lazy_mount),
			str(_skill_swipe_handoff_cover_is_cream_transition()),
			0.0 if skill_swipe_handoff_cover == null or not is_instance_valid(skill_swipe_handoff_cover) else skill_swipe_handoff_cover.modulate.a,
			str(detail_lazy_plan.size())
		])
	if not skill_swipe_defer_initial_lazy_mount:
		_skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, _detail_lazy_initial_force_mount_count_for_skill(selected_skill_id))
	if not _skill_swipe_loading_transition_active() and not _skill_swipe_handoff_cover_is_cream_transition():
		_skill_detail_surface()._detail_lazy_mount_thieving_heists_sync(true)
	detail_lazy_last_scroll = _detail_lazy_scroll_y()
	if _skill_swipe_handoff_cover_is_opaque_cream_transition():
		skill_swipe_handoff_cover.set_meta("swipe_cover_last_lazy_mount_process_frame", Engine.get_process_frames())
	_skill_detail_surface()._queue_skill_detail_and_swipe_texture_prewarm(selected_skill_id)
	if not skill_swipe_defer_initial_lazy_mount and not _skill_swipe_handoff_cover_is_cream_transition():
		_skill_swipe_activity_surface()._queue_skill_swipe_real_card_cache_prewarm(selected_skill_id)
	_queue_detail_lazy_settle_warm_mount(selected_skill_id)


func _render_detail_lazy_card_list(stack: VBoxContainer, content_width: float, actions_width: float) -> void:
	_begin_detail_lazy_card_list_render(selected_skill_id)
	_detail_lazy_create_slots(stack, selected_skill_id, content_width, actions_width)
	_finish_detail_lazy_card_list_render()


func _render_detail_lazy_card_list_batched(stack: VBoxContainer, content_width: float, actions_width: float, batch_size: int) -> bool:
	var skill_id := selected_skill_id
	_begin_detail_lazy_card_list_render(skill_id)
	var slots_created := await _detail_lazy_create_slots_batched(
		stack,
		skill_id,
		content_width,
		actions_width,
		batch_size
	)
	if not slots_created:
		return false
	_finish_detail_lazy_card_list_render()
	return true


func _hold_recent_pinned_source_from_lazy_prune(module_key: String) -> void:
	var track_id := ModuleUiRuntime.lazy_track_id(module_key, selected_skill_id)
	if track_id.is_empty():
		return
	module_ui_recent_pin_prune_hold_skill_id = selected_skill_id
	module_ui_recent_pin_prune_hold_track_id = track_id
	module_ui_recent_pin_prune_hold_until_msec = Time.get_ticks_msec() + int(round(MODULE_PIN_SOURCE_PRUNE_HOLD_SECONDS * 1000.0))


func _show_pinned_activities() -> void:
	if current_screen == "pinned":
		_return_from_pinned_activities()
		return
	if not _top_level_nav_allowed("pinned"):
		return
	pinned_return_screen = _navigation_shell()._module_utility_return_screen_for_current()
	pinned_return_skill_id = selected_skill_id
	pinned_return_detail_scroll = _navigation_shell()._module_utility_return_detail_scroll_for_current()
	if current_screen == "settings":
		_settings_surface()._disarm_reset_data_confirmation()
		_begin_direct_skill_nav_cover()
	current_screen = "pinned"
	_render_screen()


func _return_from_pinned_activities() -> void:
	var target_screen := pinned_return_screen
	if target_screen.is_empty() or _navigation_shell()._module_utility_screen_overlays_skill_detail(target_screen):
		target_screen = "skill"
	if not _top_level_nav_allowed(target_screen):
		return
	if not pinned_return_skill_id.is_empty() and SkillState.has_skill_id(skill_defs, pinned_return_skill_id):
		selected_skill_id = pinned_return_skill_id
	var restore_scroll := pinned_return_detail_scroll if target_screen == "skill" else -1
	pinned_return_detail_scroll = -1
	_begin_direct_skill_nav_cover()
	current_screen = target_screen
	_render_screen(false, restore_scroll)


func _current_detail_scroll_for_pinned_return() -> int:
	if current_screen != "skill":
		return -1
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return -1
	return maxi(0, int(round(detail_actions_scroll.scroll_vertical)))


func _build_queue_activities_module(module_key: String, content_width: float) -> Control:
	return _build_page_activity_module_copy(module_key, content_width, _queue_page_card_key(module_key))


func _on_pinned_activities_action_scroll_input(event: InputEvent) -> void:
	if current_screen != "pinned" and current_screen != "queue":
		return
	var routed_event := _pinned_activities_globalized_scroll_event(event)
	if routed_event == null:
		return
	if _event_points_inside_bottom_interactive_ui(routed_event):
		return
	if _input_routing_shell()._route_action_card_release(routed_event):
		accept_event()
		return
	_update_action_card_press_drag_state(routed_event)
	if routed_event is InputEventMouseButton and routed_event.button_index == MOUSE_BUTTON_LEFT and routed_event.pressed:
		action_card_press_consumed = false
		var routed_mouse_event := routed_event as InputEventMouseButton
		var press_position: Vector2 = routed_mouse_event.global_position
		if _input_routing_shell()._route_action_card_press(press_position):
			accept_event()
			return
	elif routed_event is InputEventScreenTouch and routed_event.pressed:
		action_card_press_consumed = false
		var routed_touch_event := routed_event as InputEventScreenTouch
		var touch_position: Vector2 = routed_touch_event.position
		if _input_routing_shell()._route_action_card_press(touch_position, routed_touch_event.index):
			accept_event()
			return


func _pinned_activities_globalized_scroll_event(event: InputEvent) -> InputEvent:
	if content_scroll == null or not is_instance_valid(content_scroll):
		return null
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var global_position := _global_event_position(mouse_event.position, mouse_event.global_position, content_scroll)
		var routed := InputEventMouseButton.new()
		routed.button_index = mouse_event.button_index
		routed.pressed = mouse_event.pressed
		routed.button_mask = mouse_event.button_mask
		routed.position = global_position
		routed.global_position = global_position
		return routed
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		var global_position := _global_event_position(motion_event.position, motion_event.global_position, content_scroll)
		var routed := InputEventMouseMotion.new()
		routed.position = global_position
		routed.global_position = global_position
		routed.relative = motion_event.relative
		routed.velocity = motion_event.velocity
		return routed
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		var global_position := content_scroll.get_global_transform() * touch_event.position
		var routed := InputEventScreenTouch.new()
		routed.index = touch_event.index
		routed.pressed = touch_event.pressed
		routed.position = global_position
		return routed
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		var global_position := content_scroll.get_global_transform() * drag_event.position
		var routed := InputEventScreenDrag.new()
		routed.index = drag_event.index
		routed.position = global_position
		routed.relative = drag_event.relative
		routed.velocity = drag_event.velocity
		return routed
	return event

func _remove_registered_card_collapse_zone(card_key: String) -> void:
	if card_key.is_empty() or not action_cards.has(card_key):
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	var zones := card.get("module_action_zones", {}) as Dictionary
	if zones.is_empty():
		return
	zones.erase("collapse")
	if zones.is_empty():
		card.erase("module_action_zones")
	else:
		card["module_action_zones"] = zones


func _build_pinned_activities_module(module_key: String, content_width: float) -> Control:
	return _build_page_activity_module_copy(module_key, content_width, _pinned_page_card_key(module_key))


func _prepare_page_activity_module_copy_card(card: Dictionary, suppress_collection_modules := false) -> Dictionary:
	if card.is_empty():
		return card
	if suppress_collection_modules and not (card.get("mat_collection", {}) as Dictionary).is_empty():
		card["page_copy_suppresses_collection_modules"] = true
	return card


func _build_page_activity_module_copy(module_key: String, content_width: float, page_card_key: String) -> Control:
	if page_card_key.is_empty():
		return null
	if module_key.begins_with("action:"):
		var action_key := module_key.substr("action:".length())
		var parts := action_key.split(":", false, 2)
		if parts.size() < 2:
			return null
		var skill_id := str(parts[0])
		var action_id := str(parts[1])
		var action := _action_data(skill_id, action_id)
		if action.is_empty():
			return null
		if _is_passive_action(action):
			var passive_card := _passive_firepit_surface()._build_passive_module_card(skill_id, action, content_width, true)
			var passive_root := passive_card.get("root") as Control
			var passive_dict := passive_card.get("card", {}) as Dictionary
			passive_dict["entry"] = passive_root
			passive_dict["action_id"] = action_id
			passive_dict = _prepare_page_activity_module_copy_card(passive_dict, page_card_key.begins_with("pinned_page:"))
			_register_action_card(page_card_key, passive_dict)
			_detail_lazy_finalize_action_card(passive_dict, skill_id, action, action_id)
			return passive_root
		var built := _skill_detail_surface()._build_detail_interactive_action_card(skill_id, action, content_width, content_width)
		var card_root := built.get("card_root") as Control
		var card := _prepare_page_activity_module_copy_card(built.get("card", {}) as Dictionary, page_card_key.begins_with("pinned_page:"))
		var pop_card := card.get("pop") as Control
		if pop_card != null and is_instance_valid(pop_card):
			_attach_swipe_preview_activity_button(card, skill_id, action_id, pop_card)
		var page_entry: Control = card_root
		if page_card_key.begins_with("queue_page:"):
			page_entry = _page_activity_module_copy_entry(card_root, content_width)
		card["entry"] = page_entry
		_register_action_card(page_card_key, card)
		_detail_lazy_finalize_action_card(card, skill_id, action, action_id)
		return page_entry
	if module_key.begins_with("thieving_heist:"):
		var heist_id := module_key.substr("thieving_heist:".length())
		var heist := thieving_state.heist_def(heist_id)
		if heist.is_empty():
			return null
		return _thieving_surface()._build_thieving_heist_card(heist, content_width, false, page_card_key)
	if module_key.begins_with("fishing_area:"):
		var area_key := module_key.substr("fishing_area:".length())
		for raw_area_def in _fishing_render_area_modules("fishing"):
			var area_def := raw_area_def as Dictionary
			if fishing_runtime.area_module_key("fishing", area_def) != area_key:
				continue
			var built := _fishing_ui_surface()._build_fishing_area_module("fishing", area_def, content_width)
			var area_card := built.get("area_card", {}) as Dictionary
			if not area_card.is_empty():
				_register_action_card(page_card_key, area_card)
			return built.get("root") as Control
	if module_key.begins_with("fishing_offer:"):
		return _fishing_ui_surface()._build_fishing_offer_module(module_key.substr("fishing_offer:".length()), content_width)
	return null


func _page_activity_module_copy_entry(module_root: Control, content_width: float) -> Control:
	if module_root == null:
		return null
	var entry := Control.new()
	entry.set_meta("detail_stack_entry_wrapper", true)
	entry.set_meta("page_activity_module_copy_entry", true)
	var module_height := maxf(1.0, module_root.custom_minimum_size.y)
	if module_height <= 1.0:
		module_height = maxf(1.0, module_root.size.y)
	entry.custom_minimum_size = Vector2(content_width, module_height)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.clip_contents = false
	module_root.anchor_left = 0.0
	module_root.anchor_right = 1.0
	module_root.anchor_top = 0.0
	module_root.anchor_bottom = 0.0
	module_root.offset_left = 0.0
	module_root.offset_right = 0.0
	module_root.offset_top = 0.0
	module_root.offset_bottom = module_height
	module_root.custom_minimum_size = Vector2(content_width, module_height)
	module_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(module_root)
	return entry


func _pinned_page_card_key(module_key: String) -> String:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return ""
	return "pinned_page:%s" % normalized_key


func _queue_page_card_key(module_key: String) -> String:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return ""
	return "queue_page:%s" % normalized_key


func _render_page_switch_module(stack: VBoxContainer, skill_id: String, content_width: float, actions_width: float) -> void:
	if _onboarding_runtime()._onboarding_path_active() and not _onboarding_page_switch_module_visible():
		return
	var module := _navigation_shell()._build_page_switch_module(skill_id, content_width)
	if module == null:
		return
	var entry := _detail_stack_entry(module, content_width, actions_width)
	if entry != module:
		entry.name = "PageSwitchModuleEntry"
		entry.set_meta("page_switch_module_entry", true)
	if skill_id == "fight":
		var fight_entry := Control.new()
		fight_entry.name = "PageSwitchModuleEntry"
		fight_entry.set_meta("page_switch_module_entry", true)
		fight_entry.custom_minimum_size = Vector2(actions_width, entry.custom_minimum_size.y + 820.0)
		fight_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.position.y = 820.0
		fight_entry.add_child(entry)
		entry = fight_entry
	if _skill_swipe_page_switch_module_should_start_hidden():
		_set_skill_page_switch_module_alpha(entry, 0.0)
	stack.add_child(entry)


func _skill_swipe_page_switch_module_should_start_hidden() -> bool:
	return (
		current_screen == "skill"
		and skill_swipe_animating
		and skill_swipe_animation_mode == "entry"
	)


func _collect_page_switch_modules(root_node: Node, modules: Array) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	if root_node is Control and (
		root_node.name == "PageSwitchModule"
		or bool(root_node.get_meta("page_switch_module_entry", false))
	):
		modules.append(root_node)
		return
	for raw_child in root_node.get_children():
		_collect_page_switch_modules(raw_child as Node, modules)


func _current_page_switch_modules() -> Array:
	var modules := []
	var root_node: Node = skill_swipe_page if skill_swipe_page != null and is_instance_valid(skill_swipe_page) else skills_content
	_collect_page_switch_modules(root_node, modules)
	return modules


func _fade_skill_page_switch_modules(visible: bool, seconds: float) -> void:
	for raw_module in _current_page_switch_modules():
		var module := raw_module as Control
		if module == null or not is_instance_valid(module):
			continue
		_kill_meta_tween(module, "skill_swipe_page_switch_fade_tween")
		var target_alpha := 1.0 if visible else 0.0
		if seconds <= 0.001:
			_set_skill_page_switch_module_alpha(module, target_alpha)
			continue
		var tween := create_tween()
		module.set_meta("skill_swipe_page_switch_fade_tween", tween)
		var module_id := module.get_instance_id()
		tween.tween_method(
			func(alpha: float) -> void:
				_set_skill_page_switch_module_alpha(module_id, alpha),
			module.modulate.a,
			target_alpha,
			seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_finish_skill_page_switch_module_fade.bind(module.get_instance_id()))


func _finish_skill_page_switch_module_fade(module_id: int) -> void:
	var module := _valid_control_ref(instance_from_id(module_id))
	if module != null and module.has_meta("skill_swipe_page_switch_fade_tween"):
		module.remove_meta("skill_swipe_page_switch_fade_tween")


func _set_skill_page_switch_module_alpha(module_or_alpha, maybe_alpha = null) -> void:
	var module: Control = null
	var alpha := 1.0
	if maybe_alpha == null:
		module = _valid_control_ref(instance_from_id(int(module_or_alpha)))
		alpha = 1.0
	else:
		if module_or_alpha is Control:
			module = module_or_alpha as Control
		else:
			module = _valid_control_ref(instance_from_id(int(module_or_alpha)))
		alpha = float(maybe_alpha)
	if module == null:
		return
	var next_alpha := clampf(alpha, 0.0, 1.0)
	var next_modulate := module.modulate
	next_modulate.a = next_alpha
	_set_canvas_item_modulate_if_changed(module, next_modulate)
	if bool(module.get_meta("page_switch_module_entry", false)):
		for raw_child in module.get_children():
			var child := raw_child as Control
			if child != null and child.name == "PageSwitchModule":
				var child_modulate := child.modulate
				child_modulate.a = 1.0
				_set_canvas_item_modulate_if_changed(child, child_modulate)


func _set_skill_page_switch_modules_alpha(alpha: float) -> void:
	for raw_module in _current_page_switch_modules():
		var module := raw_module as Control
		if module == null or not is_instance_valid(module):
			continue
		_kill_meta_tween(module, "skill_swipe_page_switch_fade_tween")
		_set_skill_page_switch_module_alpha(module, alpha)


func _sync_skill_page_switch_modules_for_drag(abs_x: float) -> void:
	_set_skill_page_switch_modules_alpha(1.0)


func _set_skill_swipe_module_utility_alpha(alpha: float) -> void:
	var utility_row := _navigation_shell().module_utility_row
	if utility_row == null or not is_instance_valid(utility_row):
		return
	var next_modulate := utility_row.modulate
	next_modulate.a = clampf(alpha, 0.0, 1.0)
	_set_canvas_item_modulate_if_changed(utility_row, next_modulate)


func _fade_skill_swipe_module_utility_row(visible: bool, seconds: float) -> void:
	var utility_row := _navigation_shell().module_utility_row
	if utility_row == null or not is_instance_valid(utility_row):
		return
	_kill_meta_tween(utility_row, "skill_swipe_module_utility_fade_tween")
	var target_alpha := 1.0 if visible else 0.0
	if seconds <= 0.001:
		_set_skill_swipe_module_utility_alpha(target_alpha)
		return
	var tween := create_tween()
	utility_row.set_meta("skill_swipe_module_utility_fade_tween", tween)
	tween.tween_method(_set_skill_swipe_module_utility_alpha, utility_row.modulate.a, target_alpha, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_skill_swipe_module_utility_row_fade)


func _finish_skill_swipe_module_utility_row_fade() -> void:
	var utility_row := _navigation_shell().module_utility_row
	if utility_row != null and is_instance_valid(utility_row) and utility_row.has_meta("skill_swipe_module_utility_fade_tween"):
		utility_row.remove_meta("skill_swipe_module_utility_fade_tween")


func _sync_skill_swipe_module_utility_row_for_drag(abs_x: float) -> void:
	_kill_meta_tween(_navigation_shell().module_utility_row, "skill_swipe_module_utility_fade_tween")
	_set_skill_swipe_module_utility_alpha(1.0)


func _collect_skill_shelf_backgrounds(root_node: Node, backgrounds: Array) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	if root_node is Control and root_node.name == "SkillDetailFullBleedShelfBackground":
		backgrounds.append(root_node)
		return
	for raw_child in root_node.get_children():
		_collect_skill_shelf_backgrounds(raw_child as Node, backgrounds)


func _current_skill_shelf_backgrounds() -> Array:
	var backgrounds := []
	var root_node: Node = skill_swipe_page if skill_swipe_page != null and is_instance_valid(skill_swipe_page) else skills_content
	_collect_skill_shelf_backgrounds(root_node, backgrounds)
	return backgrounds


func _skill_swipe_shelf_background_should_start_hidden() -> bool:
	return (
		current_screen == "skill"
		and skill_swipe_animating
		and skill_swipe_animation_mode == "entry"
	)


func _set_skill_shelf_background_alpha(background: Control, alpha: float) -> void:
	if background == null or not is_instance_valid(background):
		return
	var next_modulate := background.modulate
	next_modulate.a = clampf(alpha, 0.0, 1.0)
	_set_canvas_item_modulate_if_changed(background, next_modulate)


func _set_skill_shelf_background_alpha_by_id(background_id: int, alpha: float) -> void:
	_set_skill_shelf_background_alpha(_valid_control_ref(instance_from_id(background_id)), alpha)


func _fade_skill_shelf_backgrounds(visible: bool, seconds: float) -> void:
	for raw_background in _current_skill_shelf_backgrounds():
		var background := raw_background as Control
		if background == null or not is_instance_valid(background):
			continue
		_kill_meta_tween(background, "skill_swipe_shelf_background_fade_tween")
		var target_alpha := 1.0 if visible else 0.0
		if seconds <= 0.001:
			_set_skill_shelf_background_alpha(background, target_alpha)
			continue
		var tween := create_tween()
		background.set_meta("skill_swipe_shelf_background_fade_tween", tween)
		var background_id := background.get_instance_id()
		tween.tween_method(
			func(alpha: float) -> void:
				_set_skill_shelf_background_alpha_by_id(background_id, alpha),
			background.modulate.a,
			target_alpha,
			seconds
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_callback(_finish_skill_shelf_background_fade.bind(background_id))


func _finish_skill_shelf_background_fade(background_id: int) -> void:
	var background := _valid_control_ref(instance_from_id(background_id))
	if background != null and background.has_meta("skill_swipe_shelf_background_fade_tween"):
		background.remove_meta("skill_swipe_shelf_background_fade_tween")


func _onboarding_page_switch_module_visible() -> bool:
	return (
		_onboarding_runtime()._onboarding_path_active()
		and not tutorial_active
		and onboarding_swipe_navigation_unlocked
	)


func _ensure_onboarding_page_switch_module_faded_in(stack: VBoxContainer) -> Control:
	if stack == null or not is_instance_valid(stack):
		return null
	if not _onboarding_page_switch_module_visible():
		return null
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null:
			continue
		if child.name == "PageSwitchModule" or _detail_stack_child_contains_named_node(child, "PageSwitchModule"):
			return child
	var content_width := _skill_content_width()
	var module := _navigation_shell()._build_page_switch_module(selected_skill_id, content_width)
	if module == null:
		return null
	var entry := _detail_stack_entry(module, content_width, content_width)
	var target_height := maxf(1.0, entry.custom_minimum_size.y)
	entry.custom_minimum_size.y = 0.0
	entry.modulate.a = 0.0
	entry.clip_contents = true
	stack.add_child(entry)
	var insert_index := maxi(0, stack.get_child_count() - 1)
	for i in range(stack.get_child_count()):
		var child := stack.get_child(i)
		if child == entry:
			continue
		if child.name == "DetailActionsBottomSpacer":
			insert_index = i
			break
	stack.move_child(entry, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(entry, "custom_minimum_size:y", target_height, TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(entry, "modulate:a", 1.0, TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(_finish_smooth_tutorial_tip_entry_reveal.bind(entry.get_instance_id()))
	call_deferred("_sync_detail_actions_scroll_limit_deferred")
	return entry


func _detail_stack_child_contains_named_node(root_node: Node, node_name: String) -> bool:
	if root_node == null:
		return false
	if root_node.name == node_name:
		return true
	for raw_child in root_node.get_children():
		if _detail_stack_child_contains_named_node(raw_child as Node, node_name):
			return true
	return false


func _event_points_inside_page_switch_button(event: InputEvent) -> bool:
	if current_screen != "skill":
		return false
	var event_position := _passive_button_event_position(event, null)
	return _input_routing_shell()._page_switch_button_control_at_position(event_position) != null


func _route_direct_module_action_zone_input(event: InputEvent) -> bool:
	if (current_screen != "skill" and current_screen != "pinned" and current_screen != "queue" and current_screen != "menu") or _input_routing_shell()._modal_blocks_background_input() or _input_routing_shell()._any_modal_overlay_visible():
		return false
	if _update_pending_module_pin_press(event):
		return true
	if module_ui_pin_press_active and _module_pin_press_event_belongs_to_active_press(event):
		_update_pending_module_pin_drag(event)
	if _update_pending_module_collapse_press(event):
		return true
	if module_ui_collapse_press_active and _module_collapse_press_event_belongs_to_active_press(event):
		_update_pending_module_collapse_drag(event)
	if not _is_primary_press_event(event):
		return false
	var event_position := _module_pin_press_event_position(event)
	if event_position == Vector2.INF or _position_inside_bottom_interactive_ui(event_position):
		return false
	var hit := _skill_detail_surface()._module_action_circle_at_direct_position(event_position)
	return _handle_module_action_zone_hit(hit, event, event_position)


func _route_module_action_zone_input(event: InputEvent) -> bool:
	if _update_pending_module_pin_press(event):
		return true
	if module_ui_pin_press_active and _module_pin_press_event_belongs_to_active_press(event):
		_update_pending_module_pin_drag(event)
	if _update_pending_module_collapse_press(event):
		return true
	if module_ui_collapse_press_active and _module_collapse_press_event_belongs_to_active_press(event):
		_update_pending_module_collapse_drag(event)
	if not _is_primary_press_event(event):
		return false
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		event_position = (event as InputEventMouseButton).global_position
	elif event is InputEventScreenTouch:
		event_position = (event as InputEventScreenTouch).position
	else:
		return false
	var hit := _skill_detail_surface()._module_action_circle_at_position(event_position)
	return _handle_module_action_zone_hit(hit, event, event_position)


func _handle_module_action_zone_hit(hit: Dictionary, event: InputEvent, event_position: Vector2) -> bool:
	if hit.is_empty():
		return false
	var card_host := _valid_control_ref(hit.get("host"))
	if card_host == null:
		return false
	var module_key := ModuleUiRuntime.normalize(hit.get("module_key", ""))
	if module_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(module_key):
		return false
	var card_host_id := card_host.get_instance_id()
	match str(hit.get("kind", "")):
		"pin":
			if _skill_detail_surface()._module_pin_badge_is_exiting(card_host):
				return true
			_begin_module_pin_press(module_key, card_host_id, event_position, _module_pin_press_touch_index_for_event(event))
			return true
		"collapse":
			if _module_ui_is_collapsed(module_key):
				_expand_module_ui_key(module_key)
				return true
			_begin_module_collapse_press(module_key, card_host_id, event_position, _module_pin_press_touch_index_for_event(event))
			return true
	return false


func _route_fishing_area_pin_corner_input(event: InputEvent) -> bool:
	if _update_pending_module_pin_press(event):
		return true
	if module_ui_pin_press_active and _module_pin_press_event_belongs_to_active_press(event):
		_update_pending_module_pin_drag(event)
	if current_screen != "skill" and current_screen != "pinned" and current_screen != "queue":
		return false
	if current_screen == "skill" and selected_skill_id != "fishing":
		return false
	if not _is_primary_press_event(event):
		return false
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		event_position = (event as InputEventMouseButton).global_position
	elif event is InputEventScreenTouch:
		event_position = (event as InputEventScreenTouch).position
	else:
		return false
	if _position_inside_bottom_interactive_ui(event_position) or not _position_inside_detail_actions_viewport(event_position):
		return false
	var hit := _fishing_area_pin_corner_hit(event_position)
	if hit.is_empty():
		return false
	var card_host := _valid_control_ref(hit.get("host"))
	if card_host == null:
		return false
	var module_key := ModuleUiRuntime.normalize(hit.get("module_key", ""))
	if module_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(module_key):
		return false
	if _skill_detail_surface()._module_pin_badge_is_exiting(card_host):
		return true
	_begin_module_pin_press(module_key, card_host.get_instance_id(), event_position, _module_pin_press_touch_index_for_event(event))
	return true


func _fishing_area_pin_corner_hit(event_position: Vector2) -> Dictionary:
	if not _position_inside_detail_actions_viewport(event_position):
		return {}
	_prune_invalid_action_cards()
	var keys := action_card_keys.duplicate()
	keys.reverse()
	for raw_key in keys:
		var key := str(raw_key)
		if not action_cards.has(key):
			continue
		var card := action_cards[key] as Dictionary
		if not bool(card.get("is_fishing_area", false)):
			continue
		var pop := _valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		var direct_kind := _skill_detail_surface()._module_action_zone_kind_at_direct_position(pop, event_position)
		if direct_kind.is_empty():
			direct_kind = _skill_detail_surface()._module_action_badge_kind_at_direct_position(pop, event_position)
		if direct_kind != "pin":
			continue
		return {
			"card": card,
			"host": pop,
			"module_key": str(pop.get_meta("module_ui_key", ""))
		}
	return {}


func _route_collapsed_module_expand_input(event: InputEvent) -> bool:
	if not _is_primary_press_event(event):
		return false
	if _detail_actions_scroll_suppresses_child_click():
		return false
	var press_position := Vector2.ZERO
	if event is InputEventMouseButton:
		press_position = (event as InputEventMouseButton).global_position
	elif event is InputEventScreenTouch:
		press_position = (event as InputEventScreenTouch).position
	else:
		return false
	if _position_inside_bottom_interactive_ui(press_position) or not _position_inside_detail_actions_viewport(press_position):
		return false
	var row := _collapsed_module_row_at_position(press_position)
	if row == null:
		return false
	var module_key := ModuleUiRuntime.normalize(row.get_meta("module_ui_key", ""))
	if module_key.is_empty():
		return false
	var action_hit := _skill_detail_surface()._module_action_circle_at_position(press_position)
	if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "pin":
		return false
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		detail_actions_scroll.prepare_child_tap()
	_expand_module_ui_key(module_key)
	return true


func _collapsed_module_row_at_position(event_position: Vector2) -> Control:
	for raw_row in get_tree().get_nodes_in_group("collapsed_module_rows"):
		var row := raw_row as Control
		if row == null or not is_instance_valid(row) or row.is_queued_for_deletion():
			continue
		if not row.visible:
			continue
		if row.get_global_rect().has_point(event_position):
			return row
	return null


func _collapsed_module_row_for_key(module_key: String) -> Control:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return null
	for raw_row in get_tree().get_nodes_in_group("collapsed_module_rows"):
		var row := raw_row as Control
		if row == null or not is_instance_valid(row) or row.is_queued_for_deletion():
			continue
		if ModuleUiRuntime.normalize(row.get_meta("module_ui_key", "")) == normalized_key:
			return row
	return null


func _collapsed_module_layout_host(row: Control) -> Control:
	if row == null or not is_instance_valid(row):
		return null
	var current := row
	while current != null and is_instance_valid(current):
		var parent := current.get_parent()
		if parent == detail_lazy_stack or parent is VBoxContainer:
			return current
		var parent_control := parent as Control
		if parent_control == null or not is_instance_valid(parent_control):
			break
		current = parent_control
	return row


func _on_module_collapse_zone_gui_input(event: InputEvent, module_key: String, card_host_id: int) -> void:
	if _update_pending_module_collapse_press(event):
		accept_event()
		return
	if module_ui_collapse_press_active and _module_collapse_press_event_belongs_to_active_press(event):
		_update_pending_module_collapse_drag(event)
	if not _is_primary_press_event(event):
		return
	if _fishing_ui_surface()._event_inside_fishing_location_image(event):
		return
	if not _module_ui_key_allows_pin_or_collapse(module_key):
		return
	if _module_ui_is_collapsed(module_key):
		_expand_module_ui_key(module_key)
		accept_event()
		return
	var card_host := _valid_control_ref(instance_from_id(card_host_id))
	if card_host == null or card_host.is_queued_for_deletion():
		return
	var zone := _skill_detail_surface()._module_action_zone_for_card(card_host, "collapse")
	if zone == null:
		return
	var event_position := _skill_detail_surface()._module_action_zone_event_global_position(zone, event)
	if event_position == Vector2.INF:
		return
	if _position_inside_bottom_interactive_ui(event_position):
		return
	if not _skill_detail_surface()._module_action_zone_event_inside_circle(card_host, "collapse", event):
		return
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	_begin_module_collapse_press(normalized_key, card_host_id, event_position, _module_pin_press_touch_index_for_event(event))
	accept_event()


func _module_ui_is_collapsed(module_key: String) -> bool:
	return module_ui_runtime.is_collapsed(module_key, Callable(self, "_module_ui_key_allows_pin_or_collapse"))


func _begin_module_collapse_press(module_key: String, card_host_id: int, press_position: Vector2, touch_index: int) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	module_ui_collapse_press_active = true
	module_ui_collapse_press_module_key = normalized_key
	module_ui_collapse_press_card_host_id = card_host_id
	module_ui_collapse_press_position = press_position
	module_ui_collapse_press_touch_index = touch_index
	module_ui_collapse_press_dragged = false
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		detail_actions_scroll.prepare_child_tap()


func _update_pending_module_collapse_press(event: InputEvent) -> bool:
	if not module_ui_collapse_press_active:
		return false
	if not _module_collapse_press_event_belongs_to_active_press(event):
		return false
	var event_position := _module_pin_press_event_position(event)
	var is_release := _module_pin_press_event_is_release(event)
	var is_motion := event is InputEventMouseMotion or event is InputEventScreenDrag
	if event_position != Vector2.INF and (is_motion or is_release):
		_update_pending_module_collapse_drag_at_position(event_position)
	if not is_release:
		return false
	var should_commit := (
		not module_ui_collapse_press_dragged
		and event_position != Vector2.INF
		and event_position.distance_to(module_ui_collapse_press_position) <= PASSIVE_BUTTON_TAP_RELEASE_SLOP
		and not _detail_actions_scroll_suppresses_child_click()
	)
	var pressed_module_key := module_ui_collapse_press_module_key
	var pressed_card_host_id := module_ui_collapse_press_card_host_id
	_clear_module_collapse_press()
	if should_commit:
		_commit_module_collapse_tap(pressed_module_key, pressed_card_host_id)
	return true


func _update_pending_module_collapse_drag(event: InputEvent) -> void:
	var event_position := _module_pin_press_event_position(event)
	if event_position == Vector2.INF:
		return
	_update_pending_module_collapse_drag_at_position(event_position)


func _update_pending_module_collapse_drag_at_position(event_position: Vector2) -> void:
	if not module_ui_collapse_press_active:
		return
	if (
		event_position.distance_to(module_ui_collapse_press_position) > PASSIVE_BUTTON_TAP_RELEASE_SLOP
		or skill_swipe_tracking
	):
		module_ui_collapse_press_dragged = true


func _module_collapse_press_event_belongs_to_active_press(event: InputEvent) -> bool:
	if module_ui_collapse_press_touch_index < 0:
		return event is InputEventMouseButton or event is InputEventMouseMotion
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).index == module_ui_collapse_press_touch_index
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).index == module_ui_collapse_press_touch_index
	return false


func _clear_module_collapse_press() -> void:
	module_ui_collapse_press_active = false
	module_ui_collapse_press_module_key = ""
	module_ui_collapse_press_card_host_id = 0
	module_ui_collapse_press_position = Vector2.ZERO
	module_ui_collapse_press_touch_index = -1
	module_ui_collapse_press_dragged = false


func _commit_module_collapse_tap(module_key: String, card_host_id: int) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	if _module_ui_is_collapsed(normalized_key):
		_expand_module_ui_key(normalized_key)
		return
	var card_host := _valid_control_ref(instance_from_id(card_host_id))
	if card_host == null or card_host.is_queued_for_deletion():
		return
	var badge := _skill_detail_surface()._module_collapse_badge(card_host)
	if badge != null and badge.visible and not badge.disabled:
		_collapse_module_ui_key(normalized_key, card_host_id)
	else:
		_show_module_collapse_confirm(card_host, normalized_key)


func _show_module_collapse_confirm(card_host: Control, module_key: String) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	var badge := _skill_detail_surface()._ensure_module_collapse_badge(card_host, normalized_key)
	if badge == null:
		return
	badge.visible = true
	badge.disabled = false
	_skill_detail_surface()._position_module_collapse_badge(badge)
	badge.scale = Vector2.ONE
	_set_canvas_item_alpha_if_changed(badge, 1.0)


func _collapse_module_ui_key(module_key: String, card_host_id: int) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key) or _module_ui_is_collapsed(normalized_key):
		return
	module_ui_runtime.collapsed[normalized_key] = true
	module_ui_animating_collapse_key = normalized_key
	var card_host := _valid_control_ref(instance_from_id(card_host_id))
	if card_host != null and not card_host.is_queued_for_deletion():
		var badge := _skill_detail_surface()._module_collapse_badge(card_host)
		if badge != null:
			badge.disabled = true
			badge.visible = false
	_mark_save_dirty("module collapsed")
	save_game()
	if card_host != null and _collapse_module_ui_key_in_place(normalized_key, card_host):
		return
	call_deferred("_refresh_visible_skill_detail_action_list", -1, selected_skill_id, true, true)


func _collapse_module_ui_key_in_place(module_key: String, card_host: Control) -> bool:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or card_host == null or not is_instance_valid(card_host) or not card_host.is_inside_tree():
		return false
	var row := card_host.get_parent() as Control
	if row == null or not is_instance_valid(row) or not row.is_inside_tree():
		return false
	var start_height := maxf(1.0, maxf(row.custom_minimum_size.y, row.size.y))
	var target_height := _module_collapsed_squeeze_height()
	if start_height <= target_height + 8.0:
		_set_module_root_layout_height(row, target_height)
		_update_detail_lazy_module_height(normalized_key, target_height)
		_clear_module_ui_animating_collapse_key(normalized_key)
		return true
	if not row.has_meta("module_ui_full_height"):
		row.set_meta("module_ui_full_height", start_height)
	if not row.has_meta("module_ui_original_mouse_filter"):
		row.set_meta("module_ui_original_mouse_filter", int(row.mouse_filter))
	if not row.has_meta("module_ui_original_clip_contents"):
		row.set_meta("module_ui_original_clip_contents", row.clip_contents)
	row.set_meta("module_ui_key", normalized_key)
	row.set_meta("module_ui_collapsed_squeeze", true)
	row.add_to_group("collapsed_module_rows")
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.clip_contents = false
	var row_input := _on_collapsed_module_row_gui_input.bind(normalized_key, row.get_instance_id())
	if not row.gui_input.is_connected(row_input):
		row.gui_input.connect(row_input)
	var layout_host := _collapsed_module_layout_host(row)
	_kill_module_list_transition_tween(row)
	if layout_host != null and layout_host != row:
		_kill_module_list_transition_tween(layout_host)
		_set_module_root_layout_height(layout_host, start_height)
	_set_collapsed_module_visual_clipping(row, normalized_key, true, false)
	var tween := create_tween()
	row.set_meta("module_list_transition_tween", tween)
	if layout_host != null and layout_host != row:
		layout_host.set_meta("module_list_transition_tween", tween)
	var layout_host_id := layout_host.get_instance_id() if layout_host != null else 0
	tween.tween_method(
		_set_collapsed_module_squeeze_height_for_tween.bind(row.get_instance_id(), layout_host_id),
		start_height,
		target_height,
		MODULE_COLLAPSE_SQUEEZE_SECONDS
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_collapsed_module_collapse_animation.bind(row.get_instance_id(), layout_host_id, normalized_key, target_height))
	return true


func _set_collapsed_module_squeeze_height_for_tween(value: float, row_id: int, layout_host_id: int) -> void:
	var row := _valid_control_ref(instance_from_id(row_id))
	if row != null:
		_set_module_root_layout_height(row, value)
	var host := _valid_control_ref(instance_from_id(layout_host_id))
	if host != null:
		_set_module_root_layout_height(host, value)


func _finish_collapsed_module_collapse_animation(row_id: int, layout_host_id: int, module_key: String, target_height: float) -> void:
	var row := _valid_control_ref(instance_from_id(row_id))
	var layout_host := _valid_control_ref(instance_from_id(layout_host_id))
	if layout_host != null:
		_set_module_root_layout_height(layout_host, target_height)
		if layout_host.has_meta("module_list_transition_tween"):
			layout_host.remove_meta("module_list_transition_tween")
	if row != null:
		_set_module_root_layout_height(row, target_height)
		row.size.y = target_height
		if row.has_meta("module_list_transition_tween"):
			row.remove_meta("module_list_transition_tween")
	_update_detail_lazy_module_height(module_key, target_height)
	_clear_module_ui_animating_collapse_key(module_key)


func _on_collapsed_module_row_gui_input(event: InputEvent, module_key: String, row_id: int) -> void:
	if not _is_primary_press_event(event):
		return
	if _detail_actions_scroll_suppresses_child_click():
		return
	var row := _valid_control_ref(instance_from_id(row_id))
	if row == null or row.is_queued_for_deletion():
		return
	if _event_points_inside_bottom_interactive_ui(event, row) or not _event_points_inside_detail_actions_viewport(event, row):
		return
	_expand_module_ui_key(module_key)
	accept_event()


func _module_ui_key_allows_pin_or_collapse(module_key: String) -> bool:
	return module_ui_runtime.key_allows_pin_or_collapse(
		module_key,
		Callable(self, "_module_ui_action_allows_pin_or_collapse"),
		Callable(self, "_module_ui_thieving_heist_allows_pin_or_collapse"),
		Callable(self, "_module_ui_fishing_area_is_unlocked")
	)


func _module_ui_action_allows_pin_or_collapse(skill_id: String, action_id: String) -> bool:
	var action := _action_data(skill_id, action_id)
	return not action.is_empty() and _is_action_unlocked(skill_id, action)


func _module_ui_thieving_heist_allows_pin_or_collapse(heist_id: String) -> bool:
	for raw_heist in thieving_state.visible_heists_for_render():
		var heist := raw_heist as Dictionary
		if str(heist.get("id", "")) == heist_id:
			return true
	return false


func _module_ui_fishing_area_is_unlocked(module_key: String) -> bool:
	for raw_area_def in _fishing_render_area_modules("fishing"):
		var area_def := raw_area_def as Dictionary
		if ModuleUiRuntime.fishing_area(fishing_runtime.area_module_key("fishing", area_def)) != module_key:
			continue
		var area_id := str(area_def.get("id", ""))
		if _fishing_area_uses_location_tiles(area_def):
			for raw_location in _fishing_locations_for_area(area_id):
				if _fishing_location_is_unlocked(area_id, raw_location as Dictionary):
					return true
			return false
		for raw_method_id in area_def.get("methods", []):
			var action := _action_data("fishing", str(raw_method_id))
			if not action.is_empty() and _is_action_unlocked("fishing", action):
				return true
		return false
	return false


func _expand_module_ui_key(module_key: String) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return
	var row := _collapsed_module_row_for_key(normalized_key)
	if row != null and is_instance_valid(row):
		if bool(row.get_meta("module_ui_expanding_from_collapsed", false)):
			return
		_play_collapsed_module_expand_animation(row, normalized_key)
		return
	_finish_expand_module_ui_key(normalized_key)


func _play_collapsed_module_expand_animation(row: Control, module_key: String) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if row == null or not is_instance_valid(row) or normalized_key.is_empty():
		_finish_expand_module_ui_key(normalized_key)
		return
	row.set_meta("module_ui_expanding_from_collapsed", true)
	_kill_module_list_transition_tween(row)
	var layout_host := _collapsed_module_layout_host(row)
	if layout_host != null and layout_host != row:
		_kill_module_list_transition_tween(layout_host)
	var start_height := maxf(1.0, maxf(row.custom_minimum_size.y, row.size.y))
	var target_height := _module_root_full_height(row)
	if target_height <= start_height + 8.0:
		if row.has_meta("module_ui_expanding_from_collapsed"):
			row.remove_meta("module_ui_expanding_from_collapsed")
		_finish_expand_module_ui_key(normalized_key)
		return
	row.clip_contents = false
	if layout_host != null and is_instance_valid(layout_host):
		_set_module_root_layout_height(layout_host, start_height)
	_set_collapsed_module_visual_clipping(row, normalized_key, true, true)
	_set_collapsed_module_title_lift(row, false, false)
	var tween := create_tween()
	row.set_meta("module_list_transition_tween", tween)
	if layout_host != null and layout_host != row:
		layout_host.set_meta("module_list_transition_tween", tween)
	var layout_host_id := layout_host.get_instance_id() if layout_host != null else 0
	var row_id := row.get_instance_id()
	tween.tween_method(_apply_collapsed_module_expand_height.bind(row_id, layout_host_id), start_height, target_height, MODULE_COLLAPSE_SQUEEZE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_collapsed_module_expand_animation.bind(row_id, layout_host_id, normalized_key, target_height))


func _apply_collapsed_module_expand_height(value: float, row_id: int, layout_host_id: int) -> void:
	var row := _valid_control_ref(instance_from_id(row_id))
	if row != null:
		_set_module_root_layout_height(row, value)
	var host := _valid_control_ref(instance_from_id(layout_host_id))
	if host != null:
		_set_module_root_layout_height(host, value)


func _finish_collapsed_module_expand_animation(row_id: int, layout_host_id: int, module_key: String, target_height: float) -> void:
	var row := _valid_control_ref(instance_from_id(row_id))
	var layout_host := _valid_control_ref(instance_from_id(layout_host_id))
	if layout_host != null:
		_set_module_root_layout_height(layout_host, target_height)
		if layout_host.has_meta("module_list_transition_tween"):
			layout_host.remove_meta("module_list_transition_tween")
	if row != null:
		_set_module_root_layout_height(row, target_height)
		_set_collapsed_module_visual_clipping(row, module_key, false, true)
		if row.has_meta("module_list_transition_tween"):
			row.remove_meta("module_list_transition_tween")
		if row.has_meta("module_ui_expanding_from_collapsed"):
			row.remove_meta("module_ui_expanding_from_collapsed")
		_finish_expanded_module_row_in_place(row, module_key, layout_host, target_height)
	_finish_expand_module_ui_key(module_key, row == null)


func _finish_expanded_module_row_in_place(row: Control, module_key: String, layout_host: Control, target_height: float) -> void:
	if row == null or not is_instance_valid(row):
		return
	row.set_meta("module_ui_collapsed_squeeze", false)
	row.remove_from_group("collapsed_module_rows")
	row.mouse_filter = int(row.get_meta("module_ui_original_mouse_filter", Control.MOUSE_FILTER_IGNORE))
	row.clip_contents = bool(row.get_meta("module_ui_original_clip_contents", false))
	_set_collapsed_module_visual_clipping(row, module_key, false, true)
	_set_module_root_layout_height(row, target_height)
	if layout_host != null and is_instance_valid(layout_host):
		_set_module_root_layout_height(layout_host, target_height)
	_update_detail_lazy_module_height(module_key, target_height)


func _update_detail_lazy_module_height(module_key: String, target_height: float) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or detail_lazy_plan.is_empty():
		return
	var changed := false
	for index in range(detail_lazy_plan.size()):
		var lazy_entry := detail_lazy_plan[index] as Dictionary
		if ModuleUiRuntime.normalize(_detail_lazy_module_ui_key(lazy_entry, selected_skill_id)) != normalized_key:
			continue
		lazy_entry["height"] = target_height
		detail_lazy_plan[index] = lazy_entry
		changed = true
		break
	if not changed:
		return
	var y := 0.0
	for index in range(detail_lazy_plan.size()):
		var lazy_entry := detail_lazy_plan[index] as Dictionary
		lazy_entry["y"] = y
		y += float(lazy_entry.get("height", 0.0)) + DETAIL_LAZY_STACK_SEPARATION
		detail_lazy_plan[index] = lazy_entry


func _finish_expand_module_ui_key(module_key: String, refresh_list := true) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return
	module_ui_runtime.collapsed.erase(normalized_key)
	_mark_save_dirty("module expanded")
	save_game()
	if refresh_list:
		call_deferred("_refresh_visible_skill_detail_action_list", -1, selected_skill_id, true, true)


func _on_module_pin_zone_gui_input(event: InputEvent, module_key: String, card_host_id: int) -> void:
	if _update_pending_module_pin_press(event):
		accept_event()
		return
	if module_ui_pin_press_active and _module_pin_press_event_belongs_to_active_press(event):
		_update_pending_module_pin_drag(event)
	if not _is_primary_press_event(event):
		return
	if not _module_ui_key_allows_pin_or_collapse(module_key):
		return
	var card_host := _valid_control_ref(instance_from_id(card_host_id))
	if card_host == null or card_host.is_queued_for_deletion():
		return
	var zone := _skill_detail_surface()._module_action_zone_for_card(card_host, "pin")
	if zone == null:
		return
	var event_position := _skill_detail_surface()._module_action_zone_event_global_position(zone, event)
	if event_position == Vector2.INF:
		return
	if _position_inside_bottom_interactive_ui(event_position):
		return
	if not _skill_detail_surface()._module_action_zone_event_inside_circle(card_host, "pin", event):
		return
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	_begin_module_pin_press(normalized_key, card_host_id, event_position, _module_pin_press_touch_index_for_event(event))
	accept_event()


func _begin_module_pin_press(module_key: String, card_host_id: int, press_position: Vector2, touch_index: int) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	module_ui_pin_press_active = true
	module_ui_pin_press_module_key = normalized_key
	module_ui_pin_press_card_host_id = card_host_id
	module_ui_pin_press_position = press_position
	module_ui_pin_press_touch_index = touch_index
	module_ui_pin_press_dragged = false


func _update_pending_module_pin_press(event: InputEvent) -> bool:
	if not module_ui_pin_press_active:
		return false
	if not _module_pin_press_event_belongs_to_active_press(event):
		return false
	var event_position := _module_pin_press_event_position(event)
	var is_release := _module_pin_press_event_is_release(event)
	var is_motion := event is InputEventMouseMotion or event is InputEventScreenDrag
	if event_position != Vector2.INF and (is_motion or is_release):
		_update_pending_module_pin_drag_at_position(event_position)
	if not is_release:
		return false
	var should_commit := (
		not module_ui_pin_press_dragged
		and event_position != Vector2.INF
		and event_position.distance_to(module_ui_pin_press_position) <= PASSIVE_BUTTON_TAP_RELEASE_SLOP
	)
	var module_key := module_ui_pin_press_module_key
	var card_host_id := module_ui_pin_press_card_host_id
	_clear_module_pin_press()
	if should_commit:
		_commit_module_pin_tap(module_key, card_host_id)
	return true


func _update_pending_module_pin_drag(event: InputEvent) -> void:
	var event_position := _module_pin_press_event_position(event)
	if event_position == Vector2.INF:
		return
	_update_pending_module_pin_drag_at_position(event_position)


func _update_pending_module_pin_drag_at_position(event_position: Vector2) -> void:
	if not module_ui_pin_press_active:
		return
	if (
		event_position.distance_to(module_ui_pin_press_position) > PASSIVE_BUTTON_TAP_RELEASE_SLOP
		or skill_swipe_tracking
	):
		module_ui_pin_press_dragged = true


func _module_pin_press_event_belongs_to_active_press(event: InputEvent) -> bool:
	if module_ui_pin_press_touch_index < 0:
		return event is InputEventMouseButton or event is InputEventMouseMotion
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).index == module_ui_pin_press_touch_index
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).index == module_ui_pin_press_touch_index
	return false


func _module_pin_press_event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).global_position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).global_position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2.INF


func _module_pin_press_event_is_release(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed
	if event is InputEventScreenTouch:
		return not (event as InputEventScreenTouch).pressed
	return false


func _module_pin_press_touch_index_for_event(event: InputEvent) -> int:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).index
	return -1


func _clear_module_pin_press() -> void:
	module_ui_pin_press_active = false
	module_ui_pin_press_module_key = ""
	module_ui_pin_press_card_host_id = 0
	module_ui_pin_press_position = Vector2.ZERO
	module_ui_pin_press_touch_index = -1
	module_ui_pin_press_dragged = false


func _commit_module_pin_tap(module_key: String, card_host_id: int) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	var card_host := _valid_control_ref(instance_from_id(card_host_id))
	if card_host == null or card_host.is_queued_for_deletion():
		return
	if _skill_detail_surface()._module_pin_badge_is_exiting(card_host):
		return
	if module_ui_runtime.is_pinned(normalized_key, Callable(self, "_module_ui_key_allows_pin_or_collapse")):
		_unpin_module_ui_key(normalized_key, card_host_id)
	else:
		_pin_module_ui_key(normalized_key, card_host_id)


func _on_module_pin_badge_pressed(module_key: String, card_host_id: int) -> void:
	_pin_module_ui_key(module_key, card_host_id)


func _pin_module_ui_key(module_key: String, card_host_id: int) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty() or not _module_ui_key_allows_pin_or_collapse(normalized_key):
		return
	if _module_pin_key_has_exiting_badge(normalized_key):
		return
	if module_ui_runtime.is_pinned(normalized_key, Callable(self, "_module_ui_key_allows_pin_or_collapse")):
		_unpin_module_ui_key(normalized_key, card_host_id)
		return
	var card_host := _valid_control_ref(instance_from_id(card_host_id))
	module_ui_runtime.assign_random_pin_texture_path(normalized_key, MODULE_PIN_COLOR_TEXTURES, MODULE_PIN_ICON_TEXTURE)
	module_ui_runtime.pinned_order.append(normalized_key)
	_hold_recent_pinned_source_from_lazy_prune(normalized_key)
	module_ui_runtime.pin_preview_tokens.erase(normalized_key)
	var played_confirm_animation := false
	if card_host != null and not card_host.is_queued_for_deletion():
		_sync_module_pin_badge(card_host, normalized_key)
		var badge := _module_pin_badge(card_host)
		if badge != null:
			_play_module_pin_confirm_animation(badge, card_host, normalized_key)
			played_confirm_animation = true
	_mark_save_dirty("module pinned")
	save_game()
	_refresh_module_ui_after_pin_change(MODULE_PIN_CONFIRM_ANIMATION_SECONDS if played_confirm_animation else 0.0)


func _unpin_module_ui_key(module_key: String, card_host_id: int) -> void:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return
	if not _module_ui_key_allows_pin_or_collapse(normalized_key):
		module_ui_runtime.pin_preview_tokens.erase(normalized_key)
		return
	var card_host := _valid_control_ref(instance_from_id(card_host_id))
	_hold_recent_pinned_source_from_lazy_prune(normalized_key)
	module_ui_runtime.pinned_order.erase(normalized_key)
	module_ui_runtime.clear_pin_texture_path(normalized_key)
	module_ui_runtime.pin_preview_tokens.erase(normalized_key)
	var played_unpin_animation := false
	if card_host != null and not card_host.is_queued_for_deletion():
		var badge := _module_pin_badge(card_host)
		var visible_badge := _visible_module_pin_badge_for_key(normalized_key)
		if visible_badge != null and (badge == null or not badge.visible or not badge.is_inside_tree() or not badge.is_visible_in_tree()):
			badge = visible_badge
			var badge_host := _module_pin_badge_owner_host(badge)
			if badge_host != null:
				card_host = badge_host
		if badge != null:
			_play_module_pin_unpin_animation(badge, card_host, normalized_key)
			played_unpin_animation = true
	for raw_badge in _visible_module_pin_badges_for_key(normalized_key):
		var visible_badge := raw_badge as TextureButton
		if visible_badge == null or not is_instance_valid(visible_badge) or visible_badge.has_meta("module_pin_tween"):
			continue
		var visible_badge_host := _module_pin_badge_owner_host(visible_badge)
		if visible_badge_host == null:
			visible_badge_host = card_host
		if visible_badge_host == null:
			continue
		_play_module_pin_unpin_animation(visible_badge, visible_badge_host, normalized_key)
		played_unpin_animation = true
	_mark_save_dirty("module unpinned")
	save_game()
	_refresh_module_ui_after_pin_change(MODULE_PIN_UNPIN_ANIMATION_SECONDS if played_unpin_animation else 0.0)


func _restore_module_ui_pin_scroll_anchor(skill_id: String) -> void:
	if module_ui_pending_pin_scroll_anchor.is_empty():
		module_ui_pin_scroll_anchor_debug = "restore-empty"
		return
	var anchor := module_ui_pending_pin_scroll_anchor.duplicate(true)
	if current_screen != "skill" or selected_skill_id != skill_id:
		module_ui_pin_scroll_anchor_debug = "restore-wrong-screen:%s/%s skill=%s target=%s" % [current_screen, selected_skill_id, skill_id, str(anchor)]
		module_ui_pending_pin_scroll_anchor.clear()
		return
	if str(anchor.get("skill_id", "")) != skill_id:
		module_ui_pin_scroll_anchor_debug = "restore-wrong-skill:%s target=%s" % [str(anchor), skill_id]
		module_ui_pending_pin_scroll_anchor.clear()
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		module_ui_pin_scroll_anchor_debug = "restore-missing-scroll"
		module_ui_pending_pin_scroll_anchor.clear()
		return
	await get_tree().process_frame
	await get_tree().process_frame
	_sync_detail_actions_scroll_limit()
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		module_ui_pending_pin_scroll_anchor.clear()
		return
	var module_key := ModuleUiRuntime.normalize(anchor.get("module_key", ""))
	if module_key.is_empty():
		module_ui_pin_scroll_anchor_debug = "restore-empty-key:%s" % str(anchor)
		module_ui_pending_pin_scroll_anchor.clear()
		return
	var anchor_control := _find_normal_module_ui_control_for_scroll_anchor(detail_actions_scroll, module_key)
	if anchor_control == null:
		module_ui_pin_scroll_anchor_debug = "restore-missing-anchor:%s" % str(anchor)
		module_ui_pending_pin_scroll_anchor.clear()
		return
	var old_y := float(anchor.get("screen_y", anchor_control.get_global_rect().position.y))
	var new_y := anchor_control.get_global_rect().position.y
	var delta_y := new_y - old_y
	if absf(delta_y) < 1.0:
		module_ui_pin_scroll_anchor_debug = "restore-waiting-delta old=%s new=%s anchor=%s" % [old_y, new_y, str(anchor)]
		module_ui_pending_pin_scroll_anchor.clear()
		return
	var base_scroll := int(round(detail_actions_scroll.scroll_vertical))
	var target_scroll := clampi(int(round(float(base_scroll) + delta_y)), 0, int(detail_actions_scroll.get_max_scroll_vertical()))
	detail_actions_scroll.scroll_vertical = target_scroll
	detail_actions_scroll.set("drag_scroll_position", float(target_scroll))
	module_ui_pending_pin_scroll_anchor.clear()
	module_ui_pin_scroll_anchor_debug = "restore-applied delta=%s target=%s old=%s new=%s" % [delta_y, target_scroll, old_y, new_y]


func _find_normal_module_ui_control_for_scroll_anchor(root_node: Node, module_key: String, inside_duplicate := false) -> Control:
	if root_node == null or not is_instance_valid(root_node):
		return null
	var control := root_node as Control
	var next_inside_duplicate := inside_duplicate
	if control != null:
		next_inside_duplicate = (
			inside_duplicate
			or bool(control.get_meta("module_ui_pinned_shelf_copy", false))
			or bool(control.get_meta("module_ui_pinned_page_copy", false))
		)
	for child in root_node.get_children():
		var found := _find_normal_module_ui_control_for_scroll_anchor(child, module_key, next_inside_duplicate)
		if found != null:
			return found
	if control != null and not next_inside_duplicate and ModuleUiRuntime.normalize(control.get_meta("module_ui_key", "")) == module_key:
		return control
	return null


func _refresh_module_ui_after_pin_change(delay_seconds := 0.0) -> void:
	module_ui_refresh_token += 1
	var refresh_token := module_ui_refresh_token
	if current_screen == "skill" or current_screen == "pinned":
		if delay_seconds > 0.0:
			call_deferred("_refresh_module_ui_after_pin_change_after_delay", refresh_token, current_screen, selected_skill_id, delay_seconds)
		else:
			call_deferred("_refresh_module_ui_after_pin_change_deferred", refresh_token, current_screen, selected_skill_id)


func _refresh_module_ui_after_pin_change_after_delay(refresh_token: int, target_screen: String, target_skill_id: String, delay_seconds: float) -> void:
	await get_tree().create_timer(maxf(0.01, delay_seconds)).timeout
	_refresh_module_ui_after_pin_change_deferred(refresh_token, target_screen, target_skill_id)


func _refresh_module_ui_after_pin_change_deferred(refresh_token: int, target_screen: String, target_skill_id: String) -> void:
	if refresh_token != module_ui_refresh_token:
		return
	if current_screen != target_screen:
		return
	if target_screen == "skill":
		if selected_skill_id != target_skill_id:
			return
		_sync_visible_module_pin_badges()
	elif target_screen == "pinned":
		_refresh_pinned_activities_shelf_after_pin_change()
		_sync_visible_module_pin_badges()
		_navigation_shell()._sync_pinned_active_shelf(0.0, true)


func _sync_visible_module_pin_badges() -> void:
	for raw_badge in get_tree().get_nodes_in_group("module_pin_badges"):
		var badge := raw_badge as TextureButton
		if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
			continue
		var module_key := ModuleUiRuntime.normalize(badge.get_meta("module_pin_module_key", ""))
		if module_key.is_empty():
			continue
		module_ui_runtime.apply_pin_badge_texture(badge, module_key, MODULE_PIN_COLOR_TEXTURES, MODULE_PIN_ICON_TEXTURE, Callable(visual_texture_cache, "_texture_or_visual_fallback"))
		if module_ui_runtime.is_pinned(module_key, Callable(self, "_module_ui_key_allows_pin_or_collapse")):
			_place_module_pin_badge_settled(badge)
		else:
			_set_module_pin_badge_clip_enabled(badge, true)
			badge.visible = false
			badge.disabled = true
			badge.position = MODULE_PIN_BADGE_SETTLED_POSITION
			badge.rotation_degrees = 0.0
			badge.scale = Vector2.ONE
			_set_canvas_item_alpha_if_changed(badge, 0.0)


func _refresh_pinned_activities_shelf_after_pin_change() -> void:
	if current_screen != "pinned" or content_scroll == null or not is_instance_valid(content_scroll):
		return
	var existing_shelf := _find_named_control_descendant(content_scroll, "PinnedActivitiesShelf")
	var existing_empty := _find_named_control_descendant(content_scroll, "PinnedActivitiesEmptyState")
	var anchor := existing_shelf if existing_shelf != null else existing_empty
	if anchor == null:
		return
	var stack := anchor.get_parent() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return
	var insert_index := anchor.get_index()
	var previous_scroll := int(round(content_scroll.scroll_vertical))
	var old_keys: Array[String] = []
	for child in stack.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		if child_control.name == "PinnedActivitiesShelf":
			for raw_module in child_control.get_children():
				var module_control := raw_module as Control
				if module_control == null:
					continue
				var module_key := ModuleUiRuntime.normalize(module_control.get_meta("module_ui_key", ""))
				if not module_key.is_empty():
					old_keys.append(module_key)
			stack.remove_child(child_control)
			child_control.queue_free()
		elif child_control.name == "PinnedActivitiesEmptyState":
			stack.remove_child(child_control)
			child_control.queue_free()
	for old_key in old_keys:
		action_cards.erase(_pinned_page_card_key(old_key))
	var content_width := _skill_content_width()
	var replacement := _build_pinned_activities_shelf_content(content_width)
	stack.add_child(replacement)
	stack.move_child(replacement, clampi(insert_index, 0, maxi(0, stack.get_child_count() - 1)))
	content_scroll.scroll_vertical = previous_scroll
	if content_scroll is MobileScrollContainer:
		(content_scroll as MobileScrollContainer).drag_scroll_position = float(previous_scroll)


func _build_pinned_activities_shelf_content(content_width: float) -> Control:
	var shelf := VBoxContainer.new()
	shelf.name = "PinnedActivitiesShelf"
	shelf.custom_minimum_size = Vector2(content_width, 0)
	shelf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelf.add_theme_constant_override("separation", 34)
	shelf.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for raw_key in module_ui_runtime.pinned_order:
		var module_key := ModuleUiRuntime.normalize(raw_key)
		if module_key.is_empty():
			continue
		var module_root := _build_pinned_activities_module(module_key, content_width)
		if module_root == null:
			continue
		module_root.set_meta("module_ui_pinned_page_copy", true)
		module_root.set_meta("module_ui_force_expanded", true)
		module_root.set_meta("module_ui_key", module_key)
		_skill_detail_surface()._remove_module_collapse_zones(module_root)
		_remove_registered_card_collapse_zone(_pinned_page_card_key(module_key))
		shelf.add_child(module_root)
	if shelf.get_child_count() <= 0:
		shelf.queue_free()
		return _navigation_shell()._pinned_activities_empty_state(content_width)
	return shelf


func _module_pin_badge(card_host: Control) -> TextureButton:
	if card_host == null or not is_instance_valid(card_host) or not card_host.has_meta("module_pin_badge_id"):
		return null
	return _valid_texture_button_ref(instance_from_id(int(card_host.get_meta("module_pin_badge_id", 0))))


func _visible_module_pin_badge_for_key(module_key: String) -> TextureButton:
	var badges := _visible_module_pin_badges_for_key(module_key)
	return badges[0] as TextureButton if not badges.is_empty() else null


func _visible_module_pin_badges_for_key(module_key: String) -> Array:
	var badges := []
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return badges
	for raw_badge in get_tree().get_nodes_in_group("module_pin_badges"):
		var badge := raw_badge as TextureButton
		if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
			continue
		if str(badge.get_meta("module_pin_module_key", "")) != normalized_key:
			continue
		if badge.visible and badge.is_inside_tree() and badge.is_visible_in_tree():
			badges.append(badge)
	return badges


func _module_pin_key_has_exiting_badge(module_key: String) -> bool:
	var normalized_key := ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return false
	for raw_badge in get_tree().get_nodes_in_group("module_pin_badges"):
		var badge := raw_badge as TextureButton
		if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
			continue
		if str(badge.get_meta("module_pin_module_key", "")) == normalized_key and badge.has_meta("module_pin_tween"):
			return true
	return false


func _module_pin_badge_owner_host(badge: TextureButton) -> Control:
	if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
		return null
	var clip_host := badge.get_parent() as Control
	if clip_host == null or not is_instance_valid(clip_host):
		return null
	return clip_host.get_parent() as Control


func _module_pin_badge_clip_host(badge: TextureButton) -> Control:
	if badge == null or not is_instance_valid(badge):
		return null
	var parent := badge.get_parent() as Control
	if parent == null or not is_instance_valid(parent) or parent.name != "ModulePinClipBox":
		return null
	return parent


func _set_module_pin_badge_clip_enabled(raw_badge: Object, enabled: bool) -> void:
	var badge := raw_badge as TextureButton
	if badge == null:
		return
	var clip_host := _module_pin_badge_clip_host(badge)
	if clip_host == null:
		return
	clip_host.position = MODULE_PIN_BADGE_CLIP_ORIGIN
	clip_host.size = MODULE_PIN_BADGE_CLIP_SIZE
	clip_host.custom_minimum_size = MODULE_PIN_BADGE_CLIP_SIZE
	clip_host.clip_contents = enabled
	clip_host.clip_children = CanvasItem.CLIP_CHILDREN_ONLY if enabled else CanvasItem.CLIP_CHILDREN_DISABLED


func _set_module_pin_badge_clip_enabled_by_id(badge_id: int, enabled: bool) -> void:
	var badge := _valid_texture_button_ref(instance_from_id(badge_id))
	_set_module_pin_badge_clip_enabled(badge, enabled)


func _ensure_module_pin_badge(card_host: Control, module_key: String) -> TextureButton:
	var existing := _module_pin_badge(card_host)
	if existing != null and is_instance_valid(existing) and not existing.is_queued_for_deletion():
		existing.set_meta("module_pin_module_key", ModuleUiRuntime.normalize(module_key))
		existing.material = null
		module_ui_runtime.apply_pin_badge_texture(existing, module_key, MODULE_PIN_COLOR_TEXTURES, MODULE_PIN_ICON_TEXTURE, Callable(visual_texture_cache, "_texture_or_visual_fallback"))
		if not existing.is_in_group("module_pin_badges"):
			existing.add_to_group("module_pin_badges")
		return existing
	var clip_host := Control.new()
	clip_host.name = "ModulePinClipBox"
	clip_host.anchor_left = 0.0
	clip_host.anchor_right = 0.0
	clip_host.anchor_top = 0.0
	clip_host.anchor_bottom = 0.0
	clip_host.position = MODULE_PIN_BADGE_CLIP_ORIGIN
	clip_host.size = MODULE_PIN_BADGE_CLIP_SIZE
	clip_host.custom_minimum_size = MODULE_PIN_BADGE_CLIP_SIZE
	clip_host.clip_contents = true
	clip_host.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	clip_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_host.z_index = MODULE_PIN_BADGE_Z_INDEX
	card_host.add_child(clip_host)
	var badge := TextureButton.new()
	badge.name = "ModulePinConfirmBadge"
	module_ui_runtime.apply_pin_badge_texture(badge, module_key, MODULE_PIN_COLOR_TEXTURES, MODULE_PIN_ICON_TEXTURE, Callable(visual_texture_cache, "_texture_or_visual_fallback"))
	badge.ignore_texture_size = true
	badge.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT
	badge.anchor_left = 0.0
	badge.anchor_right = 0.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.position = MODULE_PIN_BADGE_SETTLED_POSITION
	badge.size = MODULE_PIN_BADGE_SIZE
	badge.custom_minimum_size = MODULE_PIN_BADGE_SIZE
	badge.pivot_offset = MODULE_PIN_BADGE_SIZE * 0.5
	badge.focus_mode = Control.FOCUS_NONE
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 0
	badge.visible = false
	badge.modulate.a = 0.0
	badge.material = null
	badge.set_meta("module_pin_module_key", ModuleUiRuntime.normalize(module_key))
	badge.add_to_group("module_pin_badges")
	badge.pressed.connect(_on_module_pin_badge_pressed.bind(module_key, card_host.get_instance_id()))
	clip_host.add_child(badge)
	card_host.set_meta("module_pin_badge_id", badge.get_instance_id())
	return badge


func _sync_module_pin_badge(card_host: Control, module_key: String) -> void:
	if card_host == null or not is_instance_valid(card_host):
		return
	var badge := _ensure_module_pin_badge(card_host, module_key)
	if badge == null:
		return
	var pinned := module_ui_runtime.is_pinned(module_key, Callable(self, "_module_ui_key_allows_pin_or_collapse"))
	if pinned:
		_place_module_pin_badge_settled(badge)
	else:
		_set_module_pin_badge_clip_enabled(badge, true)
		badge.visible = false
		badge.disabled = true
		badge.position = MODULE_PIN_BADGE_SETTLED_POSITION
		badge.rotation_degrees = 0.0
		badge.scale = Vector2.ONE
		_set_canvas_item_alpha_if_changed(badge, 0.0)


func _place_module_pin_badge_settled(badge: TextureButton) -> void:
	if badge == null or not is_instance_valid(badge):
		return
	if badge.has_meta("module_pin_preview_tween"):
		_kill_meta_tween(badge, "module_pin_preview_tween")
	var clip_host := _module_pin_badge_clip_host(badge)
	if clip_host != null:
		clip_host.visible = true
	var module_key := str(badge.get_meta("module_pin_module_key", ""))
	var clipped := module_key.is_empty() or not _module_ui_is_collapsed(module_key)
	_set_module_pin_badge_clip_enabled(badge, clipped)
	badge.position = MODULE_PIN_BADGE_SETTLED_POSITION
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	badge.visible = true
	badge.disabled = false
	_set_canvas_item_alpha_if_changed(badge, 1.0)


func _play_module_pin_confirm_animation(badge: TextureButton, card_host: Control, module_key: String) -> void:
	if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		_kill_meta_tween(badge, "module_pin_tween")
	if badge.has_meta("module_pin_preview_tween"):
		_kill_meta_tween(badge, "module_pin_preview_tween")
	_set_module_pin_badge_clip_enabled(badge, false)
	badge.visible = true
	badge.disabled = true
	var appear_position := MODULE_PIN_BADGE_SETTLED_POSITION + MODULE_PIN_CONFIRM_APPEAR_OFFSET
	var anticipation_position := MODULE_PIN_BADGE_SETTLED_POSITION + MODULE_PIN_CONFIRM_ANTICIPATION_OFFSET
	badge.position = appear_position
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	_set_canvas_item_alpha_if_changed(badge, 1.0)
	var tween := create_tween()
	badge.set_meta("module_pin_tween", tween)
	var badge_id := badge.get_instance_id()
	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, MODULE_PIN_CONFIRM_STILL_SECONDS)
	tween.parallel().tween_property(badge, "position", appear_position, MODULE_PIN_CONFIRM_STILL_SECONDS)
	tween.parallel().tween_property(badge, "rotation_degrees", 0.0, MODULE_PIN_CONFIRM_STILL_SECONDS)
	tween.parallel().tween_property(badge, "scale", Vector2.ONE, MODULE_PIN_CONFIRM_STILL_SECONDS)

	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS)
	tween.parallel().tween_property(badge, "position", anticipation_position, MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(badge, "rotation_degrees", 0.0, MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(badge, "scale", Vector2.ONE, MODULE_PIN_CONFIRM_ANTICIPATION_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, MODULE_PIN_CONFIRM_TURNAROUND_SECONDS)
	tween.parallel().tween_property(badge, "position", anticipation_position, MODULE_PIN_CONFIRM_TURNAROUND_SECONDS)
	tween.parallel().tween_property(badge, "rotation_degrees", 0.0, MODULE_PIN_CONFIRM_TURNAROUND_SECONDS)
	tween.parallel().tween_property(badge, "scale", Vector2.ONE, MODULE_PIN_CONFIRM_TURNAROUND_SECONDS)

	tween.tween_callback(_set_module_pin_badge_clip_enabled_by_id.bind(badge.get_instance_id(), true))
	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, MODULE_PIN_CONFIRM_POKE_SECONDS)
	tween.parallel().tween_property(badge, "position", MODULE_PIN_BADGE_SETTLED_POSITION, MODULE_PIN_CONFIRM_POKE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(badge, "rotation_degrees", 0.0, MODULE_PIN_CONFIRM_POKE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(badge, "scale", Vector2.ONE, MODULE_PIN_CONFIRM_POKE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween.tween_callback(_audio_director()._play_module_pin_entry_sfx)
	tween.tween_callback(_finish_module_pin_confirm_animation.bind(badge.get_instance_id()))


func _finish_module_pin_confirm_animation(badge_id: int) -> void:
	var badge := _valid_texture_button_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		badge.remove_meta("module_pin_tween")
	var module_key := str(badge.get_meta("module_pin_module_key", ""))
	_place_module_pin_badge_settled(badge)


func _play_module_pin_unpin_animation(badge: TextureButton, card_host: Control, module_key: String) -> void:
	if badge == null or not is_instance_valid(badge) or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		_kill_meta_tween(badge, "module_pin_tween")
	if badge.has_meta("module_pin_preview_tween"):
		_kill_meta_tween(badge, "module_pin_preview_tween")
	_set_module_pin_badge_clip_enabled(badge, true)
	badge.visible = true
	badge.disabled = true
	badge.position = MODULE_PIN_BADGE_SETTLED_POSITION
	badge.rotation_degrees = 0.0
	badge.scale = Vector2.ONE
	_set_canvas_item_alpha_if_changed(badge, 1.0)
	_audio_director()._play_module_pin_exit_sfx()
	var tween := create_tween()
	badge.set_meta("module_pin_tween", tween)
	call_deferred("_disable_module_pin_badge_during_unpin", badge.get_instance_id())
	var badge_id := badge.get_instance_id()
	tween.set_parallel(true)
	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, 0.075)
	tween.tween_property(badge, "position", MODULE_PIN_BADGE_SETTLED_POSITION + MODULE_PIN_EXIT_LIFT_OFFSET, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_callback(_set_module_pin_badge_clip_enabled_by_id.bind(badge.get_instance_id(), false))
	tween.set_parallel(true)
	tween.tween_method(_keep_module_pin_badge_disabled.bind(badge_id), 0.0, 1.0, 0.195)
	tween.tween_property(badge, "position", MODULE_PIN_BADGE_PULL_OUT_POSITION, 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "scale", Vector2(0.96, 0.96), 0.195).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(badge, "modulate:a", 0.0, 0.15).set_delay(0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(_finish_module_pin_unpin_animation.bind(badge.get_instance_id(), card_host.get_instance_id(), module_key))


func _keep_module_pin_badge_disabled(_progress: float, badge_id: int) -> void:
	var badge := _valid_texture_button_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		badge.disabled = true


func _disable_module_pin_badge_during_unpin(badge_id: int) -> void:
	await get_tree().process_frame
	var badge := _valid_texture_button_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		badge.disabled = true
	await get_tree().process_frame
	badge = _valid_texture_button_ref(instance_from_id(badge_id))
	if badge == null or badge.is_queued_for_deletion():
		return
	if badge.has_meta("module_pin_tween"):
		badge.disabled = true


func _finish_module_pin_unpin_animation(badge_id: int, card_host_id: int, module_key: String) -> void:
	var badge := _valid_texture_button_ref(instance_from_id(badge_id))
	if badge != null and not badge.is_queued_for_deletion():
		if badge.has_meta("module_pin_tween"):
			badge.remove_meta("module_pin_tween")
		badge.visible = false
		badge.disabled = true
		badge.position = MODULE_PIN_BADGE_SETTLED_POSITION
		badge.rotation_degrees = 0.0
		badge.scale = Vector2.ONE
		_set_canvas_item_alpha_if_changed(badge, 0.0)
		_set_module_pin_badge_clip_enabled(badge, true)


func _onboarding_first_module_center_active(_skill_id: String = selected_skill_id) -> bool:
	return false


func _onboarding_first_module_top_spacer_height(skill_id: String = selected_skill_id) -> float:
	if not _onboarding_first_module_center_active(skill_id):
		return float(SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT)
	var visible_screen_height := _current_canvas_size().y - _bottom_ui_reserved_height_for_current_screen()
	if visible_screen_height <= 1.0:
		visible_screen_height = BASE_CANVAS.y - _bottom_ui_reserved_height_for_current_screen()
	var actions_global_top := SKILLS_PAGE_TOP_PAD + SKILL_DETAIL_HEADER_HEIGHT + SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT
	var target_card_top := visible_screen_height * 0.5 - _activity_card_root_height() * 0.5 - float(actions_global_top)
	return maxf(float(SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT), target_card_top)


func _sync_onboarding_first_module_top_spacer(instant := true) -> void:
	if detail_actions_top_spacer == null or not is_instance_valid(detail_actions_top_spacer):
		return
	var target_height := _onboarding_first_module_top_spacer_height()
	if onboarding_first_module_spacer_tween != null and onboarding_first_module_spacer_tween.is_valid():
		onboarding_first_module_spacer_tween.kill()
	onboarding_first_module_spacer_tween = null
	if instant:
		_apply_onboarding_first_module_top_spacer_height(target_height)
		return
	var start_height := maxf(detail_actions_top_spacer.custom_minimum_size.y, detail_actions_top_spacer.size.y)
	if absf(start_height - target_height) <= 1.0:
		_apply_onboarding_first_module_top_spacer_height(target_height)
		return
	onboarding_first_module_spacer_tween = create_tween()
	onboarding_first_module_spacer_tween.tween_method(
		_apply_onboarding_first_module_top_spacer_height,
		start_height,
		target_height,
		ONBOARDING_FIRST_MODULE_CENTER_RELEASE_SECONDS
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	onboarding_first_module_spacer_tween.finished.connect(_finish_onboarding_first_module_spacer_tween)


func _apply_onboarding_first_module_top_spacer_height(height: float) -> void:
	if detail_actions_top_spacer == null or not is_instance_valid(detail_actions_top_spacer):
		return
	detail_actions_top_spacer.custom_minimum_size = Vector2(0, height)
	detail_actions_top_spacer.update_minimum_size()


func _finish_onboarding_first_module_spacer_tween() -> void:
	onboarding_first_module_spacer_tween = null
	_sync_detail_actions_scroll_limit()


func _release_onboarding_first_module_centering() -> void:
	if current_screen != "skill" or selected_skill_id != TUTORIAL_STARTER_SKILL_ID:
		return
	onboarding_first_module_center_release_pending = false
	onboarding_first_module_center_released = true
	if detail_actions_top_spacer == null or not is_instance_valid(detail_actions_top_spacer):
		_sync_onboarding_first_module_top_spacer(false)
		return
	var stack := _detail_actions_stack()
	if stack != null and is_instance_valid(stack):
		stack.position.y = 0.0
	_sync_onboarding_first_module_top_spacer(false)


func _release_onboarding_first_module_centering_for_level_two_unlock(skill_id: String, action_ids: Array) -> void:
	if not onboarding_first_module_center_release_pending:
		return
	if current_screen != "skill" or selected_skill_id != TUTORIAL_STARTER_SKILL_ID:
		return
	if skill_id != TUTORIAL_STARTER_SKILL_ID:
		return
	for raw_action_id in action_ids:
		var action_id := str(raw_action_id)
		if action_id.is_empty():
			continue
		var action := _action_data(skill_id, action_id)
		if action.is_empty():
			continue
		if int(action.get("unlock", 0)) == 2:
			_release_onboarding_first_module_centering()
			return


func _should_release_onboarding_first_module_centering_for_preview(skill_id: String, action: Dictionary) -> bool:
	if not onboarding_first_module_center_release_pending:
		return false
	if skill_id != TUTORIAL_STARTER_SKILL_ID or action.is_empty():
		return false
	if str(action.get("id", "")) != _onboarding_runtime()._tutorial_current_locked_preview_action_id(skill_id):
		return false
	return int(action.get("unlock", 0)) == 2


func _suppress_detail_auto_scroll_for_first_module() -> bool:
	if not _onboarding_first_module_center_active():
		return false
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		detail_actions_scroll.drag_scroll_position = 0.0
		detail_actions_scroll.scroll_vertical = 0
	return true


func _add_skill_detail_shadow_overlay(top_y: float) -> void:
	if skills_content == null:
		return
	detail_shelf_shadow_alpha = _skill_detail_shadow_target_alpha()
	detail_shelf_shadow_overlay = _add_skill_detail_shadow_overlay_to(skills_content, top_y, detail_shelf_shadow_alpha)


func _skill_detail_shadow_top_y() -> float:
	return float(SKILL_DETAIL_HEADER_HEIGHT + SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT)


func _add_skill_detail_shadow_overlay_to(parent: Control, top_y: float, initial_alpha := -1.0) -> Control:
	if parent == null or not is_instance_valid(parent):
		return null
	var shelf_shadow := SkillDetailPageShelfShadow.new()
	shelf_shadow.name = "SkillDetailFixedShelfShadow"
	shelf_shadow.anchor_left = 0.0
	shelf_shadow.anchor_right = 1.0
	shelf_shadow.anchor_top = 0.0
	shelf_shadow.anchor_bottom = 0.0
	shelf_shadow.offset_left = 0.0
	shelf_shadow.offset_right = 0.0
	shelf_shadow.offset_top = top_y
	shelf_shadow.offset_bottom = top_y + 116.0
	shelf_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shelf_shadow.z_index = 500
	shelf_shadow.set_shadow_alpha(detail_shelf_shadow_alpha if initial_alpha < 0.0 else clampf(initial_alpha, 0.0, 1.0))
	parent.add_child(shelf_shadow)
	return shelf_shadow


func _skill_detail_shadow_target_alpha() -> float:
	if current_screen == "menu":
		if content_scroll == null or not is_instance_valid(content_scroll):
			return 0.0
		var menu_scroll_amount := float(content_scroll.scroll_vertical)
		return clampf(menu_scroll_amount / SKILL_DETAIL_SHADOW_FADE_SCROLL, 0.0, 1.0)
	if current_screen == "pinned":
		if content_scroll == null or not is_instance_valid(content_scroll):
			return 0.0
		var pinned_scroll_amount := maxf(float(content_scroll.scroll_vertical), float(content_scroll.get("drag_scroll_position")))
		return clampf(pinned_scroll_amount / SKILL_DETAIL_SHADOW_FADE_SCROLL, 0.0, 1.0)
	if current_screen != "skill" or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return 0.0
	if _onboarding_first_module_center_active():
		return 0.0
	var scroll_amount := float(detail_actions_scroll.scroll_vertical)
	return clampf(scroll_amount / SKILL_DETAIL_SHADOW_FADE_SCROLL, 0.0, 1.0)


func _update_skill_detail_shadow(delta: float, instant := false) -> void:
	var target_alpha := _skill_detail_shadow_target_alpha()
	if instant:
		detail_shelf_shadow_alpha = target_alpha
	else:
		var step := 1.0 - exp(-SKILL_DETAIL_SHADOW_FADE_SPEED * delta)
		detail_shelf_shadow_alpha = lerpf(detail_shelf_shadow_alpha, target_alpha, step)
		if absf(detail_shelf_shadow_alpha - target_alpha) <= 0.01:
			detail_shelf_shadow_alpha = target_alpha
	if detail_shelf_shadow_overlay == null:
		return
	if not is_instance_valid(detail_shelf_shadow_overlay) or detail_shelf_shadow_overlay.is_queued_for_deletion():
		detail_shelf_shadow_overlay = null
		return
	if not detail_shelf_shadow_overlay.is_inside_tree():
		return
	var should_show_shadow := detail_shelf_shadow_alpha > 0.001
	_set_canvas_item_visible_if_changed(detail_shelf_shadow_overlay, should_show_shadow)
	if not should_show_shadow:
		return
	if not is_instance_valid(detail_shelf_shadow_overlay) or detail_shelf_shadow_overlay.is_queued_for_deletion() or not detail_shelf_shadow_overlay.is_inside_tree():
		return
	if detail_shelf_shadow_overlay.has_method("set_shadow_alpha"):
		detail_shelf_shadow_overlay.call("set_shadow_alpha", detail_shelf_shadow_alpha)


func _on_detail_actions_user_scroll_direction(direction: int) -> void:
	if current_screen != "skill":
		return
	if action_stop_hold_active:
		_cancel_action_stop_hold()
	_audio_director()._focus_chain_scroll(direction)
	if _detail_unlock_scroll_spacer_height(selected_skill_id) > 1.0:
		detail_unlock_auto_scroll_interrupted = true
		if detail_unlock_scroll_spacer_tween != null and detail_unlock_scroll_spacer_tween.is_valid():
			detail_unlock_scroll_spacer_tween.kill()
			detail_unlock_scroll_spacer_tween = null
	if direction < 0:
		_release_detail_unlock_extra_scroll_space()
	_skill_detail_surface()._reveal_detail_jump_arrow(direction)
	_skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()
	_skill_detail_surface()._sync_detail_lazy_visible_cards(true, DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME)


func _update_page_visibility() -> void:
	home_page.visible = current_screen == "home"
	skills_page.visible = current_screen != "home"
	var navigation_shell := _navigation_shell()
	navigation_shell._refresh_hero_nav_unlock_state()
	navigation_shell._refresh_hub_nav_unlock_state()
	navigation_shell._refresh_shop_nav_unlock_state()
	if leaderboard_tab != null:
		navigation_shell._apply_nav_style(leaderboard_tab, current_screen == "leaderboard")
	navigation_shell._apply_nav_style(hero_tab, current_screen == "home" or current_screen == "achievements")
	navigation_shell._apply_nav_style(hub_tab, current_screen == "hub")
	navigation_shell._apply_nav_style(skills_tab, current_screen == "menu" or current_screen == "skill" or current_screen == "pinned")
	navigation_shell._apply_nav_style(shop_tab, current_screen == "shop")
	navigation_shell._apply_nav_style(settings_tab, current_screen == "settings")
	_profile_chat_overlay_surface()._update_chat_strip()
	_onboarding_runtime()._tutorial_check_progress()
	_tutorial_overlay_surface()._sync_tutorial_target_indicator()


func _visible_detail_regen_gauge_needs_header_refresh() -> bool:
	if current_screen != "skill" or _fishing_rework_active_for_skill(selected_skill_id):
		return false
	if detail_regen_circle == null or not is_instance_valid(detail_regen_circle) or not detail_regen_circle.is_inside_tree():
		return false
	var maximum := _max_stamina(selected_skill_id)
	return _stamina_value(selected_skill_id) < float(maximum) - 0.0001


func _skill_detail_needs_high_frequency_ui_update() -> bool:
	if current_screen == "menu":
		return not running_action_id.is_empty() or not event_running_action_id.is_empty()
	if current_screen == "queue":
		return true
	if current_screen == "pinned":
		var pinned_scroll := content_scroll as MobileScrollContainer
		return (
			not running_action_id.is_empty()
			or not event_running_action_id.is_empty()
			or action_stop_hold_active
			or not action_card_press_key.is_empty()
			or activity_start_highlight_active
			or activity_start_highlight_pending
			or locked_activity_preview_fade_play_pending
			or _navigation_shell()._pinned_active_shelf_has_jailed_action()
			or _skill_detail_has_fishing_camera_returning()
			or (pinned_scroll != null and is_instance_valid(pinned_scroll) and (pinned_scroll.drag_scrolling or absf(pinned_scroll.velocity) >= 4.0))
			or absf(detail_shelf_shadow_alpha - _skill_detail_shadow_target_alpha()) > 0.01
		)
	if current_screen != "skill":
		return false
	if running_skill_id == selected_skill_id and not running_action_id.is_empty():
		return true
	if event_running_skill_id == selected_skill_id and not event_running_action_id.is_empty():
		return true
	if skill_swipe_tracking or skill_swipe_animating:
		return true
	if action_stop_hold_active or not action_card_press_key.is_empty():
		return true
	if activity_start_highlight_active or activity_start_highlight_pending:
		return true
	if locked_activity_preview_fade_play_pending:
		return true
	if _pending_activity_has_readiness_for_skill(selected_skill_id) or activity_unlock_ceremony_count > 0:
		return true
	if _skill_detail_surface()._detail_jump_arrows_need_processing():
		return true
	if _skill_swipe_activity_surface()._skill_swipe_previews_need_frame_updates():
		return true
	if _skill_detail_has_fishing_camera_returning():
		return true
	if absf(detail_shelf_shadow_alpha - _skill_detail_shadow_target_alpha()) > 0.01:
		return true
	return false


func _skill_detail_has_fishing_camera_returning() -> bool:
	if current_screen != "skill" and current_screen != "pinned":
		return false
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if card.is_empty():
			continue
		if bool(card.get("is_fishing_area", false)) and _fishing_area_has_active_camera_return(card):
			return true
		if float(card.get("active_camera_zoom", 0.0)) > 1.0 and (
			bool(card.get("active_camera_returning", false))
			or bool(card.get("active_camera_was_running", false))
		):
			return true
	return false


func _skill_detail_action_cards_hidden_by_transition_cover() -> bool:
	if not (skill_swipe_pending_full_finalize or skill_swipe_rebuild_cover_active or skill_swipe_defer_initial_lazy_mount or skill_swipe_outgoing_cover_active):
		return false
	if skill_swipe_handoff_cover == null or not is_instance_valid(skill_swipe_handoff_cover):
		return false
	return skill_swipe_handoff_cover.visible and skill_swipe_handoff_cover.modulate.a >= 0.92


func _update_ui(delta: float, instant := false) -> void:
	var static_refresh := _consume_ui_static_refresh(delta, instant)
	_navigation_shell()._sync_bottom_nav_visibility()
	_navigation_shell()._sync_module_utility_row_visibility()
	_skill_swipe_activity_surface()._sync_queue_selection_banner()
	var skill_frame_refresh := instant or static_refresh or _skill_detail_needs_high_frequency_ui_update()
	var header_gauge_frame_refresh := skill_frame_refresh or _visible_detail_regen_gauge_needs_header_refresh()
	var detail_header_gauge_refresh := _consume_detail_header_gauge_refresh(delta, instant, static_refresh, header_gauge_frame_refresh)
	var passive_card_progress_refresh := _consume_passive_card_progress_refresh(delta, instant, static_refresh, skill_frame_refresh)
	_sync_action_art_animations_for_running_state(instant or static_refresh)
	if static_refresh and not boot_detail_render_in_progress and not screen_render_in_progress and _skill_detail_needs_action_list_refresh():
		var refresh_restore_scroll := detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1
		call_deferred("_refresh_visible_skill_detail_action_list", refresh_restore_scroll, selected_skill_id)
	if static_refresh and _skill_detail_shows_tutorial_tips():
		_show_lock_click_tip_note_if_needed()
		_onboarding_runtime()._resume_onboarding_stamina_mastery_sequence_if_needed()
	if static_refresh and current_screen == "home" and home_total_label != null:
		_set_label_text_if_changed(home_total_label, "Total Lv %s" % _global_level())
		for skill_id in home_skill_labels.keys():
			var skill_id_text := str(skill_id)
			_set_label_text_if_changed(home_skill_labels[skill_id] as Label, "%s Lvl %s" % [_skill_name(skill_id_text), _skill_level(skill_id_text)])
	if static_refresh and current_screen == "achievements":
		_achievement_overlay_surface()._update_achievements_ui(delta, instant)
	if current_screen == "menu":
		_update_skill_detail_shadow(delta, instant)
		for skill_id in skill_cards.keys():
			var skill_id_text := str(skill_id)
			var card: Dictionary = skill_cards[skill_id]
			if static_refresh:
				_normalize_skill_menu_card_button(card)
				_set_label_text_if_changed(card["title"] as Label, "%s" % _skill_name(skill_id_text))
				_set_label_text_if_changed(card["meta"] as Label, _skill_level_xp_text(skill_id_text))
				_apply_xp_progress_bar_theme(card["xp"] as CleanProgressBar, _skill_theme_color(skill_id_text))
			var xp := SkillState.xp_progress(skills, skill_id_text, _skill_level(skill_id_text))
			_set_bar(card["xp"], float(xp["pct"]), delta, instant)
			_update_skill_menu_card(card, skill_id_text, delta, instant)
			_navigation_shell()._sync_skill_menu_active_drawer(skill_id_text, instant)
	if current_screen == "skill":
		if static_refresh and _onboarding_runtime()._onboarding_fight_header_sequence_active():
			_tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
			_tutorial_overlay_surface()._apply_onboarding_fight_action_stats_visibility_all()
		if static_refresh and selected_skill_id == TUTORIAL_STARTER_SKILL_ID and _onboarding_runtime()._onboarding_path_active():
			_onboarding_runtime()._maybe_trigger_onboarding_swipe_tip_at_zero_stamina(TUTORIAL_STARTER_SKILL_ID)
			if _onboarding_runtime()._onboarding_swipe_tip_sequence_resumable() and not onboarding_swipe_tip_sequence_running:
				call_deferred("_run_onboarding_swipe_tip_sequence")
		if skill_frame_refresh:
			_sync_onboarding_overlay_tips()
			_onboarding_runtime()._maybe_trigger_onboarding_header_reveal_from_progress()
			_sync_activity_start_highlight_position()
		var detail_xp := SkillState.xp_progress(skills, selected_skill_id, _skill_level(selected_skill_id))
		if static_refresh and detail_xp_label != null:
			_set_label_text_if_changed(detail_xp_label, _skill_level_xp_text(selected_skill_id))
		if skill_frame_refresh and detail_xp_bar != null:
			if static_refresh:
				_apply_xp_progress_bar_theme(detail_xp_bar, _skill_theme_color(selected_skill_id))
			_set_bar(detail_xp_bar, float(detail_xp["pct"]), delta, instant)
		if detail_header_gauge_refresh and _fishing_rework_active_for_skill(selected_skill_id):
			if detail_fish_circle != null:
				_set_fish_circle_for_skill(detail_fish_circle, selected_skill_id, instant)
		elif detail_header_gauge_refresh and selected_skill_id == "fight" and detail_blue_guy_health_gauge != null:
			_fighting_runtime().set_blue_guy_health_gauge(detail_blue_guy_health_gauge, instant)
		elif detail_header_gauge_refresh and detail_regen_circle != null:
			var max_stamina := _max_stamina(selected_skill_id)
			var stamina_value := _stamina(selected_skill_id)
			var stamina_decimal_fraction := SkillState.stamina_fraction(stamina, selected_skill_id, Callable(self, "_max_stamina"))
			var circle_value := _stamina_regen_fraction(selected_skill_id)
			detail_regen_circle.set_dark_mode(dark_mode_enabled)
			detail_regen_circle.set_theme_color(_skill_theme_color(selected_skill_id))
			detail_regen_circle.set_regen_ring_color(_stamina_regen_circle_color(selected_skill_id))
			detail_regen_circle.set_show_decimal(show_stamina_decimal)
			detail_regen_circle.set_stamina(stamina_value, max_stamina, instant, stamina_decimal_fraction)
			detail_regen_circle.set_value(circle_value, instant)
		if skill_frame_refresh:
			_update_skill_detail_shadow(delta, instant)
		if _skill_swipe_activity_surface()._skill_swipe_previews_need_frame_updates():
			_skill_swipe_activity_surface()._update_skill_swipe_preview_states(delta, instant)
	if (current_screen == "pinned" or current_screen == "queue") and (skill_frame_refresh or static_refresh or instant):
		_navigation_shell()._sync_pinned_active_shelf(delta, instant)
		_update_skill_detail_shadow(delta, instant)
	if static_refresh or instant:
		_skill_swipe_activity_surface()._sync_queue_overlays_for_visible_cards()
	if current_screen == "skill" or current_screen == "pinned" or current_screen == "queue" or current_screen == "menu":
		if detail_lazy_mounted_this_frame and not instant:
			return
		if _skill_detail_action_cards_hidden_by_transition_cover():
			return
		if skill_frame_refresh:
			_apply_pending_activity_unlock_readiness()
		if static_refresh and current_screen == "skill" and not boot_detail_render_in_progress and selected_skill_id == "thieving":
			_thieving_surface()._cleanup_stale_thieving_heist_cards()
		if not skill_frame_refresh:
			return
		for raw_key in action_card_keys:
			var key := str(raw_key)
			if not action_cards.has(key):
				continue
			var card: Dictionary = action_cards[key]
			var card_root := _valid_control_ref(card.get("root", null))
			if card_root == null:
				_discard_action_card_key(key)
				continue
			var skill_id := str(card.get("skill_id", ""))
			if (
				current_screen != "pinned"
				and current_screen != "queue"
				and not skill_strip_ids.is_empty()
				and not skill_id.is_empty()
				and skill_id != selected_skill_id
				and skill_id != running_skill_id
				and skill_id != event_running_skill_id
			):
				continue
			var action_id := str(card.get("action_id", ""))
			if skill_id.is_empty() or action_id.is_empty():
				var separator := key.find(":")
				if separator > 0:
					if skill_id.is_empty():
						skill_id = key.substr(0, separator)
					if action_id.is_empty() and not key.begins_with("thieving_heist:"):
						action_id = key.substr(separator + 1)
			if card.get("heist_id") != null:
				if static_refresh:
					_thieving_surface()._update_thieving_heist_card(card, delta, instant)
				continue
			if card.get("is_fishing_area"):
				var area_running := (
					running_skill_id == skill_id
					and _fishing_ui_surface()._fishing_area_card_owns_action(card, running_action_id)
				)
				if bool(card.get("fluid_was_running", false)) and not area_running:
					card["fluid_exiting"] = true
				var area_camera_returning := _fishing_area_has_active_camera_return(card)
				if not static_refresh and not area_running and not bool(card.get("fluid_exiting", false)) and not area_camera_returning:
					continue
				_update_fishing_area_module(card, skill_id, area_running, delta, instant)
				continue
			if card.get("is_fishing_method"):
				action_id = str(card.get("action_id", action_id))
				var method_running := running_skill_id == skill_id and running_action_id == action_id
				if card.get("is_fishing_location"):
					method_running = (
						method_running
						and str(selected_fishing_locations.get(str(card.get("area_id", "")), "")) == str(card.get("location_id", ""))
					)
				if float(card.get("active_camera_zoom", 0.0)) > 1.0 and bool(card.get("active_camera_was_running", false)) and not method_running:
					card["active_camera_returning"] = true
				if not static_refresh and not method_running and not bool(card.get("active_camera_returning", false)):
					continue
				var method_action := _action_data(skill_id, action_id)
				var method_unlocked := _is_action_unlocked(skill_id, method_action)
				_update_fishing_method_slot(card, skill_id, action_id, method_action, method_unlocked, method_running, delta, instant)
				continue
			var action := _action_data(skill_id, action_id)
			var event_running := event_running_skill_id == skill_id and event_running_action_id == action_id
			var running := (running_skill_id == skill_id and running_action_id == action_id) or event_running
			var running_progress := event_action_progress if event_running else action_progress
			if not running and not static_refresh and not instant:
				continue
			if not running and not static_refresh and (skill_swipe_tracking or skill_swipe_animating):
				continue
			if not running and not static_refresh and not skill_strip_ids.is_empty() and skill_id != selected_skill_id:
				continue
			_fighting_runtime().sync_blue_guy_chicken_brawl_stage_active(card, skill_id, action_id, running)
			_fighting_runtime().sync_rooster_punch_out_stage_active(card, skill_id, action_id, running)
			if bool(card.get("swipe_proxy", false)):
				continue
			var unlocked := _is_action_unlocked(skill_id, action)
			if _is_passive_action(action):
				if static_refresh:
					_passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, unlocked)
				elif passive_card_progress_refresh:
					_passive_firepit_surface()._update_passive_card_progress(card, action, unlocked, instant)
				continue
			if static_refresh:
				if not card.has("xp") or not card.has("stamina") or not card.has("time") or not card.has("success"):
					_discard_action_card_key(key)
					continue
				_skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, unlocked)
				_skill_detail_surface()._sync_activity_stat_popup(card, skill_id, action, unlocked, delta, instant)
				var status := card.get("status") as Label
				if status != null:
					_set_label_text_if_changed(status, "")
				if _action_has_mastery(action):
					var medal := card.get("medal") as TextureRect
					var mastery_level := MasteryState.level(mastery, _action_key(skill_id, action_id))
					_set_action_card_medal(card, medal, mastery_level, instant)
					_update_action_card_mastery_bar(card, skill_id, action_id, delta, instant)
			if skill_id == "thieving":
				_thieving_surface()._sync_thieving_action_jail_overlay(card, action_id)
			_update_action_card_run_feedback(card, skill_id, running, delta, instant, running_progress)
		_sync_hidden_locked_activity_preview_layouts()
	if locked_activity_preview_fade_play_pending:
		_play_pending_locked_activity_preview_reveals()
	if static_refresh:
		_settings_surface()._refresh_audio_volume_controls()
	if static_refresh:
		_shop_surface().sync_bonus_display()
	_settings_surface()._expire_reset_data_confirm_if_needed()
	if static_refresh:
		_tutorial_overlay_surface()._sync_tutorial_target_indicator()


func _consume_ui_static_refresh(delta: float, instant: bool) -> bool:
	if instant or delta <= 0.0:
		ui_static_refresh_elapsed = 0.0
		return true
	ui_static_refresh_elapsed += delta
	if current_screen == "skill" and detail_lazy_mounted_this_frame:
		return false
	if current_screen == "skill" and _fishing_rework_active_for_skill(selected_skill_id) and detail_scroll_visual_work_this_frame:
		return false
	if _skill_swipe_loading_transition_active():
		return false
	if ui_static_refresh_elapsed < UI_STATIC_REFRESH_INTERVAL_SECONDS:
		return false
	ui_static_refresh_elapsed = 0.0
	return true


func _consume_detail_header_gauge_refresh(delta: float, instant: bool, static_refresh: bool, skill_frame_refresh: bool) -> bool:
	if instant or static_refresh:
		detail_header_gauge_refresh_elapsed = 0.0
		return true
	if not skill_frame_refresh or current_screen != "skill":
		return false
	detail_header_gauge_refresh_elapsed += maxf(0.0, delta)
	if detail_header_gauge_refresh_elapsed < DETAIL_HEADER_GAUGE_REFRESH_SECONDS:
		return false
	detail_header_gauge_refresh_elapsed = 0.0
	return true


func _consume_passive_card_progress_refresh(delta: float, instant: bool, static_refresh: bool, skill_frame_refresh: bool) -> bool:
	if instant or static_refresh:
		passive_card_progress_refresh_elapsed = 0.0
		return true
	if not skill_frame_refresh or current_screen != "skill":
		return false
	passive_card_progress_refresh_elapsed += maxf(0.0, delta)
	if passive_card_progress_refresh_elapsed < PASSIVE_CARD_PROGRESS_REFRESH_SECONDS:
		return false
	passive_card_progress_refresh_elapsed = 0.0
	return true


func _set_action_card_medal(card: Dictionary, medal: TextureRect, mastery_level: int, instant: bool) -> void:
	if medal == null or not is_instance_valid(medal):
		return
	var last_level := int(card.get("last_mastery_level", -1))
	if last_level == mastery_level:
		return
	var should_animate := not instant and last_level >= 0 and mastery_level > last_level and mastery_level > 0
	var old_texture := medal.texture
	var replacing := should_animate and last_level > 0 and old_texture != null and medal.visible
	_clear_action_card_medal_ceremony(card)
	if should_animate:
		_play_new_medal_ceremony(card, medal, old_texture, replacing, mastery_level)
	else:
		_place_action_card_medal(card, medal, mastery_level)
	card["last_mastery_level"] = mastery_level


func _action_card_medal_texture_for_level(mastery_level: int) -> Texture2D:
	return AchievementPresentation.mastery_medal_visual_texture(mastery_level, MASTERY_MAX_LEVEL, Callable(visual_texture_cache, "_texture"), Callable(visual_texture_cache, "_visual_fallback_texture")) if mastery_level > 0 else visual_texture_cache._visual_fallback_texture()


func _update_action_card_mastery_bar(card: Dictionary, skill_id: String, action_id: String, _delta: float, instant: bool) -> void:
	var mastery_bar := card.get("mastery") as Control
	if mastery_bar == null or not is_instance_valid(mastery_bar):
		return
	var action := _action_data(skill_id, action_id)
	if _convergence_runtime()._is_convergence_action(action):
		if bool(card.get("mastery_hidden_for_convergence", false)) and not mastery_bar.visible:
			return
		card["mastery_hidden_for_convergence"] = true
		mastery_bar.visible = false
		var medal := card.get("medal") as TextureRect
		if medal != null:
			medal.visible = false
		return
	card.erase("mastery_hidden_for_convergence")
	var mastery_action_id := str(card.get("mastery_action_id", action_id))
	var mastery_level := MasteryState.level(mastery, _action_key(skill_id, mastery_action_id))
	var maxed := mastery_level >= MASTERY_MAX_LEVEL
	var progress_pct := 100.0 if maxed else MasteryState.progress_pct(mastery, _action_key(skill_id, mastery_action_id), MASTERY_MAX_LEVEL)
	var theme_color := _skill_theme_color(skill_id)
	var refresh_key := "%s|%s|%s|%s|%s|%s" % [
		skill_id,
		mastery_action_id,
		mastery_level,
		GameFormatting.info_chip_number(progress_pct),
		maxed,
		theme_color.to_html(true)
	]
	if not instant and str(card.get("mastery_bar_refresh_key", "")) == refresh_key:
		return
	card["mastery_bar_refresh_key"] = refresh_key
	if mastery_bar is CleanProgressBar:
		_apply_mastery_progress_bar_theme(mastery_bar as CleanProgressBar, theme_color)
	mastery_bar.visible = not maxed
	if maxed:
		_clear_mastery_bar_tween(mastery_bar)
		return
	_set_mastery_bar(mastery_bar, progress_pct, instant or bool(card.get("mastery_bar_instant_updates", false)))


func _set_mastery_bar(mastery_bar: Control, target: float, instant: bool) -> void:
	if mastery_bar == null or not is_instance_valid(mastery_bar):
		return
	var current_value := 0.0
	if mastery_bar is CleanProgressBar:
		current_value = float((mastery_bar as CleanProgressBar).value)
	else:
		return
	var clamped_target := clampf(target, 0.0, 100.0)
	var previous_target := float(mastery_bar.get_meta("mastery_bar_target", -9999.0))
	var initialized := bool(mastery_bar.get_meta("mastery_bar_initialized", false))
	if instant or not initialized:
		_clear_mastery_bar_tween(mastery_bar)
		mastery_bar.set_meta("mastery_bar_initialized", true)
		mastery_bar.set_meta("mastery_bar_target", clamped_target)
		if absf(current_value - clamped_target) > 0.001:
			mastery_bar.call("set_value", clamped_target)
		return
	if absf(previous_target - clamped_target) <= 0.001:
		return
	mastery_bar.set_meta("mastery_bar_target", clamped_target)
	_clear_mastery_bar_tween(mastery_bar)
	if absf(current_value - clamped_target) <= 0.01:
		mastery_bar.call("set_value", clamped_target)
		return
	var tween := create_tween()
	mastery_bar.set_meta("mastery_bar_tween", tween)
	var mastery_bar_id := mastery_bar.get_instance_id()
	tween.tween_method(_set_mastery_bar_value_bound.bind(mastery_bar_id), current_value, clamped_target, MASTERY_BAR_EASE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_mastery_bar_tween.bind(mastery_bar_id, clamped_target))


func _set_mastery_bar_value_bound(value: float, mastery_bar_id: int) -> void:
	var mastery_bar := _valid_control_ref(instance_from_id(mastery_bar_id))
	if mastery_bar == null:
		return
	mastery_bar.call("set_value", value)


func _finish_mastery_bar_tween(mastery_bar_id: int, clamped_target: float) -> void:
	var callback_mastery_bar := _valid_control_ref(instance_from_id(mastery_bar_id))
	if callback_mastery_bar == null:
		return
	callback_mastery_bar.call("set_value", clamped_target)
	if callback_mastery_bar.has_meta("mastery_bar_tween"):
		callback_mastery_bar.remove_meta("mastery_bar_tween")


func _clear_mastery_bar_tween(mastery_bar: Control) -> void:
	_kill_meta_tween(mastery_bar, "mastery_bar_tween")


func _place_action_card_medal(card: Dictionary, medal: TextureRect, mastery_level: int) -> void:
	var destination := _action_card_medal_destination(card, medal)
	_set_canvas_item_visible_if_changed(medal, mastery_level > 0)
	medal.texture = _action_card_medal_texture_for_level(mastery_level)
	medal.position = destination
	medal.scale = Vector2.ONE
	medal.rotation_degrees = 0.0
	medal.pivot_offset = medal.size * 0.5
	_set_canvas_item_modulate_if_changed(medal, Color.WHITE)


func _play_action_card_medal_tap_ceremony(card: Dictionary) -> void:
	var medal := card.get("medal") as TextureRect
	if medal == null or not is_instance_valid(medal) or not medal.visible:
		return
	var mastery_level := _action_card_visible_medal_level(card)
	if mastery_level <= 0:
		return
	_clear_action_card_medal_tap_ceremony(card)
	_play_action_card_medal_tap_pop(card, medal)
	_play_action_card_medal_shader_shine(card, medal, mastery_level, 0.04, mastery_level <= 2)
	var sparkle_count := _action_card_medal_tap_sparkle_count(mastery_level)
	for i in range(sparkle_count):
		_spawn_action_card_medal_sparkle(card, medal, mastery_level, i, sparkle_count)
	for raw_shine_step in ACTION_CARD_MEDAL_TAP_EXTRA_SHINE_STEPS:
		var shine_step := raw_shine_step as Dictionary
		if mastery_level >= int(shine_step.get("level", 0)):
			var shine_delay := float(shine_step.get("delay", 0.30))
			_play_action_card_medal_shader_shine(card, medal, mastery_level, shine_delay, false)


func _play_action_card_medal_tap_pop(card: Dictionary, medal: TextureRect) -> void:
	_kill_meta_tween(medal, "medal_tap_pop_tween")
	var destination := _action_card_medal_destination(card, medal)
	medal.position = destination
	medal.scale = Vector2.ONE
	medal.rotation_degrees = 0.0
	medal.pivot_offset = medal.size * 0.5
	var tween := create_tween()
	medal.set_meta("medal_tap_pop_tween", tween)
	tween.tween_property(medal, "scale", Vector2(1.13, 1.13), 0.075).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", -3.0, 0.075).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(medal, "scale", Vector2(0.97, 0.97), 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 2.0, 0.075).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(medal, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 0.0, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_action_card_medal_tap_pop.bind(medal.get_instance_id()))


func _finish_action_card_medal_tap_pop(medal_id: int) -> void:
	var medal := _valid_texture_rect_ref(instance_from_id(medal_id))
	if medal == null:
		return
	medal.scale = Vector2.ONE
	medal.rotation_degrees = 0.0
	if medal.has_meta("medal_tap_pop_tween"):
		medal.remove_meta("medal_tap_pop_tween")


func _action_card_medal_tap_sparkle_count(mastery_level: int) -> int:
	if mastery_level <= 0:
		return 0
	var index := clampi(mastery_level - 1, 0, ACTION_CARD_MEDAL_TAP_SPARKLE_COUNTS.size() - 1)
	return int(ACTION_CARD_MEDAL_TAP_SPARKLE_COUNTS[index])


func _spawn_action_card_medal_sparkle(card: Dictionary, medal: TextureRect, mastery_level: int, sparkle_index: int, sparkle_count: int) -> void:
	var parent := medal.get_parent() as Control
	if parent == null or not is_instance_valid(parent):
		return
	var tier_ratio := clampf(float(mastery_level - 1) / float(maxi(1, MASTERY_MAX_LEVEL - 1)), 0.0, 1.0)
	var star := MedalSparkleStar.new()
	var star_size := randf_range(92.0, 112.0 + tier_ratio * 28.0)
	star.size = Vector2(star_size, star_size)
	star.fill_color = _action_card_medal_sparkle_color(mastery_level, sparkle_index)
	star.outline_color = Color("#171615", 0.58)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.z_index = medal.z_index + 4 + sparkle_index
	star.modulate = Color(1, 1, 1, 0)
	star.scale = Vector2(0.22, 0.22)
	star.rotation = randf_range(-0.35, 0.35)
	var origin := medal.position + medal.size * 0.5 - star.size * 0.5
	star.position = origin
	parent.add_child(star)
	var angle := randf_range(-PI, PI)
	var wave_ratio := float(sparkle_index) / maxf(1.0, float(sparkle_count - 1))
	var distance := randf_range(34.0, 70.0 + tier_ratio * 122.0) + wave_ratio * (18.0 + tier_ratio * 38.0)
	var target_position := origin + Vector2(cos(angle), sin(angle)) * distance
	var peak_scale := Vector2.ONE * randf_range(1.06, 1.42 + tier_ratio * 0.36)
	var delay := 0.07 + wave_ratio * (0.30 + tier_ratio * 0.15) + randf_range(0.0, 0.035)
	var tween := create_tween()
	star.set_meta("medal_tap_effect_tween", tween)
	_register_action_card_medal_tap_effect(card, star, tween)
	tween.tween_interval(delay)
	tween.tween_property(star, "modulate:a", 1.0, 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "scale", peak_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "position", origin.lerp(target_position, 0.56), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "rotation", star.rotation + randf_range(-0.75, 0.75), 0.26).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(star, "position", target_position, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(star, "scale", Vector2(0.18, 0.18), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(star, "modulate:a", 0.0, 0.30).set_delay(0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(_finish_action_card_medal_tap_effect.bind(str(card.get("card_key", "")), star.get_instance_id()))


func _play_action_card_medal_shader_shine(card: Dictionary, medal: TextureRect, mastery_level: int, delay: float, tiny := false) -> void:
	if medal == null or not is_instance_valid(medal):
		return
	var shine_overlay := MedalShineSlash.new()
	shine_overlay.anchor_left = 0.0
	shine_overlay.anchor_right = 0.0
	shine_overlay.anchor_top = 0.0
	shine_overlay.anchor_bottom = 0.0
	shine_overlay.position = Vector2.ZERO
	shine_overlay.size = medal.size
	shine_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shine_overlay.z_index = 1
	shine_overlay.modulate = Color.WHITE
	var tier_ratio := clampf(float(mastery_level - 1) / float(maxi(1, MASTERY_MAX_LEVEL - 1)), 0.0, 1.0)
	shine_overlay.line_width = 10.0 if tiny else 13.0 + tier_ratio * 7.0
	shine_overlay.shine_color = Color(1.0, 0.96, 0.76, 0.84 if tiny else 0.96)
	medal.add_child(shine_overlay)
	var duration := 0.34 if tiny else 0.42 + tier_ratio * 0.16
	var tween := create_tween()
	shine_overlay.set_meta("medal_tap_effect_tween", tween)
	_register_action_card_medal_tap_effect(card, shine_overlay, tween)
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_method(_set_action_card_medal_shader_shine_progress.bind(shine_overlay.get_instance_id()), 0.0, 1.0, duration).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(_finish_action_card_medal_tap_effect.bind(str(card.get("card_key", "")), shine_overlay.get_instance_id()))


func _set_action_card_medal_shader_shine_progress(progress: float, medal_id: int) -> void:
	var shine_overlay := instance_from_id(medal_id) as MedalShineSlash
	if shine_overlay == null or not is_instance_valid(shine_overlay):
		return
	shine_overlay.set_progress(progress)


func _restore_action_card_medal_material(medal: TextureRect) -> void:
	if medal == null or not is_instance_valid(medal):
		return
	if medal.has_meta("medal_shine_original_material"):
		medal.material = medal.get_meta("medal_shine_original_material") as Material
		medal.remove_meta("medal_shine_original_material")
	else:
		medal.material = null


func _action_card_medal_sparkle_color(mastery_level: int, sparkle_index: int) -> Color:
	var palette := _action_card_medal_sparkle_palette(mastery_level)
	if palette.is_empty():
		return Color.WHITE
	return palette[sparkle_index % palette.size()] as Color


func _action_card_medal_sparkle_palette(mastery_level: int) -> Array:
	if mastery_level <= 0:
		return []
	var index := clampi(mastery_level - 1, 0, ACTION_CARD_MEDAL_TAP_SPARKLE_PALETTES.size() - 1)
	return ACTION_CARD_MEDAL_TAP_SPARKLE_PALETTES[index] as Array


func _register_action_card_medal_tap_effect(card: Dictionary, node: Node, tween: Tween) -> void:
	var effects := card.get("medal_tap_effects", []) as Array
	effects.append(node)
	card["medal_tap_effects"] = effects
	var tweens := card.get("medal_tap_tweens", []) as Array
	tweens.append(tween)
	card["medal_tap_tweens"] = tweens


func _finish_action_card_medal_tap_effect(card_key: String, effect_id: int) -> void:
	var effect := _valid_node_ref(instance_from_id(effect_id))
	if effect != null:
		effect.queue_free()
	var card := action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	var remaining_effects := []
	for raw_effect in card.get("medal_tap_effects", []) as Array:
		if raw_effect != null and is_instance_valid(raw_effect) and raw_effect is Node and raw_effect.get_instance_id() != effect_id:
			remaining_effects.append(raw_effect)
	card["medal_tap_effects"] = remaining_effects


func _clear_action_card_medal_tap_ceremony(card: Dictionary) -> void:
	for raw_tween in card.get("medal_tap_tweens", []) as Array:
		if raw_tween != null and is_instance_valid(raw_tween) and raw_tween is Tween and raw_tween.is_valid():
			raw_tween.kill()
	card.erase("medal_tap_tweens")
	card.erase("medal_shine_active_count")
	var medal = card.get("medal", null)
	if medal != null and is_instance_valid(medal):
		_restore_action_card_medal_material(medal)
		if medal.has_meta("medal_tap_effect_tween"):
			medal.remove_meta("medal_tap_effect_tween")
	for raw_effect in card.get("medal_tap_effects", []) as Array:
		if raw_effect != null and is_instance_valid(raw_effect) and raw_effect is Node and raw_effect != medal:
			raw_effect.queue_free()
	card.erase("medal_tap_effects")


func _play_new_medal_ceremony(card: Dictionary, medal: TextureRect, old_texture: Texture2D, replacing: bool, mastery_level: int) -> void:
	var destination := _action_card_medal_destination(card, medal)
	medal.texture = _action_card_medal_texture_for_level(mastery_level)
	_set_canvas_item_visible_if_changed(medal, true)
	medal.position = destination + Vector2(92, -148)
	medal.scale = Vector2(1.34, 1.34)
	medal.rotation_degrees = -7.0
	medal.pivot_offset = medal.size * 0.5
	_set_canvas_item_modulate_if_changed(medal, Color(1, 1, 1, 0))
	if replacing:
		_start_replaced_medal_fall(card, medal, old_texture, destination)
	var anticipation_position := destination + Vector2(122, -192)
	var tween := create_tween()
	card["medal_ceremony_tween"] = tween
	tween.tween_property(medal, "position", anticipation_position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "scale", Vector2(1.48, 1.48), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", -13.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "modulate:a", 1.0, 0.12)
	tween.chain().tween_property(medal, "position", destination, 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "scale", Vector2(0.95, 0.95), 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 2.0, 0.48).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(medal, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(medal, "rotation_degrees", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var medal_id := medal.get_instance_id()
	tween.finished.connect(_finish_new_medal_ceremony.bind(str(card.get("card_key", "")), medal_id, destination))


func _finish_new_medal_ceremony(card_key: String, medal_id: int, destination: Vector2) -> void:
	var callback_medal := _valid_texture_rect_ref(instance_from_id(medal_id))
	if callback_medal != null and not callback_medal.is_queued_for_deletion():
		callback_medal.position = destination
		callback_medal.scale = Vector2.ONE
		callback_medal.rotation_degrees = 0.0
		_set_canvas_item_modulate_if_changed(callback_medal, Color.WHITE)
	var card := action_cards.get(card_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("medal_ceremony_tween")
		_play_earned_medal_tap_ceremony(card, callback_medal)


func _play_earned_medal_tap_ceremony(card: Dictionary, medal: TextureRect) -> void:
	if card.is_empty() or medal == null or not is_instance_valid(medal) or not medal.is_visible_in_tree():
		return
	var card_medal = card.get("medal", null)
	if card_medal != medal:
		return
	_play_action_card_medal_tap_ceremony(card)


func _start_replaced_medal_fall(card: Dictionary, medal: TextureRect, old_texture: Texture2D, destination: Vector2) -> void:
	var parent := medal.get_parent() as Control
	if parent == null or old_texture == null:
		return
	var outgoing := TextureRect.new()
	outgoing.texture = old_texture
	outgoing.anchor_left = 0.0
	outgoing.anchor_right = 0.0
	outgoing.anchor_top = 0.0
	outgoing.anchor_bottom = 0.0
	outgoing.position = destination
	outgoing.size = medal.size
	outgoing.expand_mode = medal.expand_mode
	outgoing.stretch_mode = medal.stretch_mode
	outgoing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outgoing.z_index = medal.z_index + 1
	outgoing.pivot_offset = outgoing.size * 0.5
	outgoing.modulate = Color.WHITE
	parent.add_child(outgoing)
	card["medal_outgoing"] = outgoing
	var tween := create_tween()
	card["medal_outgoing_tween"] = tween
	tween.set_parallel(true)
	tween.tween_property(outgoing, "position", destination + Vector2(-62, 260), 0.60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "rotation_degrees", -46.0, 0.60).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "scale", Vector2(0.76, 0.76), 0.54).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(outgoing, "modulate:a", 0.0, 0.39).set_delay(0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var outgoing_id := outgoing.get_instance_id()
	tween.finished.connect(_finish_replaced_medal_fall.bind(str(card.get("card_key", "")), outgoing_id))


func _finish_replaced_medal_fall(card_key: String, outgoing_id: int) -> void:
	var callback_outgoing := _valid_texture_rect_ref(instance_from_id(outgoing_id))
	if callback_outgoing != null:
		callback_outgoing.queue_free()
	var card := action_cards.get(card_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("medal_outgoing")
		card.erase("medal_outgoing_tween")


func _clear_action_card_medal_ceremony(card: Dictionary) -> void:
	_clear_action_card_medal_tap_ceremony(card)
	var ceremony_tween = card.get("medal_ceremony_tween", null)
	if ceremony_tween != null and is_instance_valid(ceremony_tween) and ceremony_tween is Tween and ceremony_tween.is_valid():
		ceremony_tween.kill()
	card.erase("medal_ceremony_tween")
	var outgoing_tween = card.get("medal_outgoing_tween", null)
	if outgoing_tween != null and is_instance_valid(outgoing_tween) and outgoing_tween is Tween and outgoing_tween.is_valid():
		outgoing_tween.kill()
	card.erase("medal_outgoing_tween")
	var outgoing = card.get("medal_outgoing", null)
	if outgoing != null and is_instance_valid(outgoing) and outgoing is Node:
		outgoing.queue_free()
	card.erase("medal_outgoing")


func _action_card_medal_destination(card: Dictionary, medal: TextureRect) -> Vector2:
	if card.has("medal_destination"):
		return card["medal_destination"] as Vector2
	card["medal_destination"] = medal.position
	return medal.position


func _action_card_static_refresh_key(skill_id: String, action: Dictionary, unlocked: bool, ceremony_active: bool) -> String:
	if _convergence_runtime()._is_convergence_action(action):
		return ""
	return "%s|%s|%s|%s|%s" % [
		_action_stat_value_cache_key("static", skill_id, action),
		unlocked,
		ceremony_active,
		hash(action.get("xp_rewards", {})),
		_skill_theme_color(skill_id).to_html(true)
	]


func _sync_convergence_card_static_state(card: Dictionary, action: Dictionary, unlocked: bool) -> void:
	var module_id := str(action.get("id", ConvergenceRuntime.CONVERGENCE_DEFAULT_MODULE_ID))
	var state := _convergence_runtime()._ensure_convergence_state(module_id)
	var built := bool(state.get("built", false))
	var building := bool(state.get("building", false))
	var requires_build := _convergence_runtime()._convergence_requires_build(action)
	var overlay := card.get("convergence_overlay") as ColorRect
	var overlay_label := card.get("convergence_overlay_label") as Label
	var cta := card.get("convergence_build_cta") as PanelContainer
	var cta_meta := card.get("convergence_build_cta_meta") as Label
	var bg := card.get("bg") as CanvasItem
	var art_panel := card.get("art_panel") as CanvasItem
	var art := card.get("art") as CanvasItem
	var convergence_progress := card.get("convergence_progress") as ConvergenceMultiProgressBar
	var should_overlay := requires_build and unlocked and (building or not built)
	if overlay != null:
		_set_canvas_item_visible_if_changed(overlay, should_overlay)
		var overlay_color := CONVERGENCE_BUILD_OVERLAY_COLOR if building else Color(0.08, 0.07, 0.05, 0.26)
		if not _colors_close_enough(overlay.color, overlay_color):
			overlay.color = overlay_color
	if overlay_label != null:
		_set_canvas_item_visible_if_changed(overlay_label, unlocked and building)
		if building:
			_set_label_text_if_changed(overlay_label, "BUILDING\n%s" % GameFormatting.countdown(_convergence_runtime()._convergence_build_remaining(module_id)))
	if cta != null:
		_set_canvas_item_visible_if_changed(cta, requires_build and unlocked and not built and not building)
	if cta_meta != null:
		var cta_text := "%s Softwood  |  %s" % [_convergence_runtime()._convergence_log_cost(action), GameFormatting.countdown(_convergence_runtime()._convergence_build_seconds(action))]
		if not requires_build:
			cta_text = "READY"
		_set_label_text_if_changed(cta_meta, cta_text)
	var tint := Color.WHITE if built else CONVERGENCE_UNBUILT_CARD_TINT
	if bg != null:
		_set_canvas_item_modulate_if_changed(bg, tint)
	if art_panel != null:
		_set_canvas_item_visible_if_changed(art_panel, not _convergence_runtime()._is_convergence_action(action))
	if art != null:
		_set_canvas_item_visible_if_changed(art, not _convergence_runtime()._is_convergence_action(action))
	if convergence_progress != null:
		convergence_progress.set_bar_pattern(_convergence_runtime()._convergence_bar_pattern(action))
		_set_canvas_item_visible_if_changed(convergence_progress, built)


func _sync_xp_reward_chips(xp_box: Control, xp_label: Label, skill_id: String, action: Dictionary) -> void:
	if xp_box == null or not is_instance_valid(xp_box) or xp_label == null or not is_instance_valid(xp_label):
		return
	if not _convergence_runtime()._is_convergence_action(action):
		var reward_parts := _action_xp_reward_parts_for_display(skill_id, action)
		_set_label_text_if_changed(xp_label, "+%s" % GameFormatting.info_chip_number(float(_action_xp_reward_total(reward_parts))))
	xp_label.visible = true
	if xp_box.has_meta("xp_reward_chip_grid"):
		var existing = xp_box.get_meta("xp_reward_chip_grid")
		if existing is GridContainer and is_instance_valid(existing):
			(existing as GridContainer).queue_free()
		xp_box.remove_meta("xp_reward_chip_grid")
	xp_box.set_meta("xp_reward_chip_key", "")


func _action_xp_reward_parts_for_display(skill_id: String, action: Dictionary) -> Array:
	var rewards := _effective_xp_reward_map(action, skill_id)
	var parts := []
	for reward_skill_id in _ordered_xp_reward_skill_ids(skill_id, rewards):
		var amount := maxi(0, int(rewards.get(reward_skill_id, 0)))
		if amount <= 0:
			continue
		parts.append({
			"skill": reward_skill_id,
			"amount": amount,
			"theme_color": _skill_theme_color(reward_skill_id)
		})
	if parts.is_empty():
		parts.append({
			"skill": skill_id,
			"amount": _effective_xp(action, skill_id),
			"theme_color": _skill_theme_color(skill_id)
		})
	return parts


func _base_xp_reward_parts_for_display(skill_id: String, action: Dictionary) -> Array:
	var rewards := _base_xp_reward_map(action, skill_id)
	var parts := []
	for reward_skill_id in _ordered_xp_reward_skill_ids(skill_id, rewards):
		var amount := maxi(0, int(rewards.get(reward_skill_id, 0)))
		if amount <= 0:
			continue
		parts.append({
			"skill": reward_skill_id,
			"amount": amount,
			"theme_color": _skill_theme_color(reward_skill_id)
		})
	if parts.is_empty():
		parts.append({
			"skill": skill_id,
			"amount": maxi(1, int(action.get("xp", 1))),
			"theme_color": _skill_theme_color(skill_id)
		})
	return parts


func _xp_reward_result_phrase(reward_map: Dictionary, owner_skill_id := "") -> String:
	var packed := PackedStringArray()
	var ordered_skill_ids := _ordered_xp_reward_skill_ids(owner_skill_id, reward_map)
	var visible_count := 0
	for raw_skill_id in ordered_skill_ids:
		if int(reward_map.get(str(raw_skill_id), 0)) > 0:
			visible_count += 1
	for raw_skill_id in ordered_skill_ids:
		var skill_id := str(raw_skill_id)
		var amount := maxi(0, int(reward_map.get(skill_id, 0)))
		if amount <= 0:
			continue
		if visible_count > 1:
			packed.append("+%s %s XP" % [GameFormatting.info_chip_number(float(amount)), _skill_name(skill_id)])
		else:
			packed.append("+%s XP" % GameFormatting.info_chip_number(float(amount)))
	if packed.is_empty():
		packed.append("+0 XP")
	return ", ".join(packed)


func _xp_reward_result_sentence(reward_map: Dictionary, owner_skill_id: String, action_name: String) -> String:
	return "%s from %s." % [_xp_reward_result_phrase(reward_map, owner_skill_id), action_name]


func _ordered_xp_reward_skill_ids(owner_skill_id: String, rewards: Dictionary) -> Array:
	var ordered := []
	if rewards.has(owner_skill_id):
		ordered.append(owner_skill_id)
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if skill_id.is_empty() or skill_id == owner_skill_id or not rewards.has(skill_id):
			continue
		ordered.append(skill_id)
	for raw_skill_id in rewards.keys():
		var skill_id := str(raw_skill_id)
		if not skill_id.is_empty() and not ordered.has(skill_id):
			ordered.append(skill_id)
	return ordered


func _action_xp_reward_total(parts: Array) -> int:
	var total := 0
	for raw_part in parts:
		if typeof(raw_part) != TYPE_DICTIONARY:
			continue
		total += maxi(0, int((raw_part as Dictionary).get("amount", 0)))
	return maxi(1, total)


func _sync_action_stat_chip_label_style(label: Label, buffed: bool, theme_color: Color, box: Control = null) -> void:
	if label == null:
		return
	if box == null:
		box = _action_stat_box_for_label(label)
	if box != null:
		box.set_meta("stat_box_buffed", buffed)
		box.set_meta("stat_box_theme_color", theme_color)
		_skill_detail_surface()._apply_action_stat_box_style(box, bool(box.get_meta("stat_box_style_active", false)))
	var style_key := "%s:%s:%s" % [buffed, theme_color.to_html(true), dark_mode_enabled]
	if str(label.get_meta("stat_chip_style_key", "")) == style_key:
		return
	label.set_meta("stat_chip_style_key", style_key)
	var title_label := (label.get_meta("stat_title_label") as Label) if label.has_meta("stat_title_label") else null
	if buffed:
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", 0)
		if title_label != null:
			title_label.add_theme_color_override("font_color", Color.WHITE)
			title_label.add_theme_constant_override("outline_size", 0)
	else:
		label.add_theme_color_override("font_color", ThemeStyles.ink_color(dark_mode_enabled, COLOR_INK, COLOR_DARK_INK))
		label.add_theme_constant_override("outline_size", 0)
		if title_label != null:
			title_label.add_theme_color_override("font_color", ThemeStyles.ink_color(dark_mode_enabled, COLOR_INK, COLOR_DARK_INK))
			title_label.add_theme_constant_override("outline_size", 0)


func _action_stat_box_for_label(label: Label) -> Control:
	if label == null:
		return null
	var parent := label.get_parent()
	if parent is Control and bool((parent as Control).get_meta("action_stat_box", false)):
		return parent as Control
	if parent != null and parent.get_parent() is Control:
		var grandparent := parent.get_parent() as Control
		if bool(grandparent.get_meta("action_stat_box", false)):
			return grandparent
	return null


func _action_stat_chip_buffed(skill_id: String, action: Dictionary, stat_kind: String) -> bool:
	match stat_kind:
		"xp":
			var base_rewards := _base_xp_reward_map(action, skill_id)
			var effective_rewards := _effective_xp_reward_map(action, skill_id)
			for raw_skill_id in base_rewards.keys():
				var reward_skill_id := str(raw_skill_id)
				if int(effective_rewards.get(reward_skill_id, 0)) > int(base_rewards.get(raw_skill_id, 0)):
					return true
			return false
		"stamina":
			var base_stamina := float(maxi(1, int(action.get("stamina", 1))))
			return _effective_stamina(skill_id, action) + 0.0001 < base_stamina
		"time":
			return _action_stat_time_chip_buffed(skill_id, action)
		"success":
			return _success_chance(skill_id, action) > _base_success_chance_for_chip(skill_id, action) + 0.001
	return false


func _action_shows_stamina_stat(skill_id: String, action: Dictionary) -> bool:
	return not _convergence_runtime()._is_convergence_action(action) and not _is_fishing_event_action(skill_id, action) and not (_fishing_rework_active_for_skill(skill_id) and not _is_event_action(action))


func _action_stamina_stat_text(skill_id: String, action: Dictionary) -> String:
	if not _action_shows_stamina_stat(skill_id, action):
		return ""
	var stamina_value := _effective_stamina(skill_id, action)
	if stamina_value < -0.0001:
		return "+%s" % GameFormatting.info_chip_number(absf(stamina_value))
	return "%s" % GameFormatting.info_chip_number(stamina_value)


func _is_fishing_event_action(skill_id: String, action: Dictionary) -> bool:
	return skill_id == "fishing" and _is_event_action(action)


func _action_stat_time_chip_buffed(skill_id: String, action: Dictionary) -> bool:
	if _fishing_rework_active_for_skill(skill_id):
		return AchievementState.activity_medal_time_reduction(self, skill_id, action) > 0.0 or _hub_runtime().mission_bonus_applies(skill_id, action)
	return (
		AchievementState.global_reward_bonus(self, "speed_mult", skill_id) > 0.0
		or _ad_bonus_runtime().speed_multiplier() > 0.0
		or AchievementState.activity_medal_time_reduction(self, skill_id, action) > 0.0
		or _hub_runtime().mission_bonus_applies(skill_id, action)
	)


func _base_success_chance_for_chip(skill_id: String, action: Dictionary) -> float:
	if _fishing_rework_active_for_skill(skill_id):
		return clampf(_fishing_attempt_success_chance(str(action.get("id", ""))), 5.0, 100.0)
	return clampf(float(action.get("success", 90.0)), 5.0, 100.0)


func _on_action_stat_button_pressed(skill_id: String, action_id: String, stat_kind: String) -> void:
	_toggle_activity_stat_popup(skill_id, action_id, stat_kind)
	get_viewport().set_input_as_handled()


func _toggle_activity_stat_popup(skill_id: String, action_id: String, stat_kind: String) -> void:
	var action := _action_data(skill_id, action_id)
	if action.is_empty():
		return
	var card := action_cards.get(_action_key(skill_id, action_id), {}) as Dictionary
	_toggle_activity_stat_popup_for_card(card, skill_id, action_id, stat_kind)


func _toggle_activity_stat_popup_for_card(card: Dictionary, skill_id: String, action_id: String, stat_kind: String) -> void:
	var action := _action_data(skill_id, action_id)
	if action.is_empty() or card.is_empty():
		return
	if _tutorial_blocks_activity_info_chips():
		return
	if _action_info_chips_blocked_by_lock(card):
		return
	if _activity_stat_clicks_should_start_action() and _is_action_unlocked(skill_id, action):
		_start_action_from_card_tap(skill_id, action_id)
		return
	var key := str(card.get("card_key", _action_key(skill_id, action_id)))
	var now := Time.get_ticks_msec()
	if (
		last_activity_stat_toggle_key == key
		and last_activity_stat_toggle_kind == stat_kind
		and now - last_activity_stat_toggle_msec < ACTION_CARD_DUPLICATE_TAP_MSEC
	):
		return
	last_activity_stat_toggle_key = key
	last_activity_stat_toggle_kind = stat_kind
	last_activity_stat_toggle_msec = now
	if expanded_activity_stat_key == key and expanded_activity_stat_kind == stat_kind:
		expanded_activity_stat_key = ""
		expanded_activity_stat_kind = ""
	else:
		expanded_activity_stat_key = key
		expanded_activity_stat_kind = stat_kind
	_cancel_skill_swipe_feedback(false)
	action_card_press_key = ""
	_update_ui(0.0, false)
	_press_activity_stat_box(key, stat_kind)


func _action_card_for_input_source(skill_id: String, action_id: String, source: Control) -> Dictionary:
	if source != null and is_instance_valid(source):
		for raw_card in action_cards.values():
			var candidate := raw_card as Dictionary
			if candidate.is_empty():
				continue
			if str(candidate.get("skill_id", "")) != skill_id or str(candidate.get("action_id", "")) != action_id:
				continue
			var candidate_button := candidate.get("button", null) as Control
			if candidate_button == source:
				return candidate
			var candidate_pop := candidate.get("pop", null) as Control
			if candidate_pop == source:
				return candidate
			if candidate_pop != null and is_instance_valid(candidate_pop) and candidate_pop.is_ancestor_of(source):
				return candidate
	var key := _action_key(skill_id, action_id)
	return action_cards.get(key, {}) as Dictionary


func _on_action_card_input(event: InputEvent, skill_id: String, action_id: String, source: Control) -> void:
	_skill_swipe_activity_surface()._on_action_card_input(event, skill_id, action_id, source)

func _on_passive_module_button_input(event: InputEvent, action_kind: String, module_id: String, stat_type: String, info_popover: Control, source: Control) -> void:
	var event_position := _passive_button_event_position(event, source)
	var is_press := false
	var is_release := false
	var touch_index := -1
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_press = event.pressed
		is_release = not event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		is_press = touch_event.pressed
		is_release = not touch_event.pressed
		touch_index = touch_event.index
	if is_press:
		if _position_inside_bottom_interactive_ui(event_position):
			return
		if not _position_inside_detail_actions_viewport(event_position):
			return
		if action_kind != "info" and _route_passive_info_button_press(event):
			get_viewport().set_input_as_handled()
			return
		passive_button_press_source = source
		passive_button_press_kind = action_kind
		passive_button_press_module_id = module_id
		passive_button_press_stat_type = stat_type
		passive_button_press_popover = info_popover
		passive_button_press_position = event_position
		passive_button_press_dragged = false
		passive_button_press_touch_index = touch_index
		_route_skill_swipe_button_input(event, source)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if passive_button_press_source == source or skill_swipe_tracking:
			if passive_button_press_source == source:
				if event_position.distance_to(passive_button_press_position) > PASSIVE_BUTTON_TAP_RELEASE_SLOP:
					passive_button_press_dragged = true
					passive_button_pending_tap_id += 1
			_route_skill_swipe_button_input(event, source)
			get_viewport().set_input_as_handled()
		return
	if is_release:
		var matches_press := passive_button_press_source == source and passive_button_press_kind == action_kind
		if skill_swipe_tracking:
			_route_skill_swipe_button_input(event, source)
		var tap_like := (
			matches_press
			and not passive_button_press_dragged
			and _position_inside_detail_actions_viewport(event_position)
			and event_position.distance_to(passive_button_press_position) <= PASSIVE_BUTTON_TAP_RELEASE_SLOP
		)
		if tap_like and not _skill_swipe_suppresses_button_action():
			_schedule_passive_module_button_activation(action_kind, module_id, stat_type, info_popover, source)
		else:
			_clear_passive_button_press()
		get_viewport().set_input_as_handled()


func _route_passive_module_button_input_by_position(event: InputEvent) -> bool:
	if current_screen != "skill" and current_screen != "pinned" and current_screen != "menu":
		return false
	if passive_button_press_source != null and is_instance_valid(passive_button_press_source):
		if event is InputEventMouseMotion or event is InputEventScreenDrag or _button_press_runtime()._input_event_releases_primary_pointer(event):
			var active_source := passive_button_press_source
			var routed_event := _passive_button_event_for_source(event, active_source)
			_on_passive_module_button_input(
				routed_event,
				passive_button_press_kind,
				passive_button_press_module_id,
				passive_button_press_stat_type,
				passive_button_press_popover,
				active_source
			)
			return true
	if not _is_primary_press_event(event):
		return false
	var event_position := _passive_button_global_event_position(event)
	if event_position == Vector2.INF:
		return false
	if _position_inside_bottom_interactive_ui(event_position) or not _position_inside_detail_actions_viewport(event_position):
		return false
	var hit := _passive_button_hit_at_position(event_position)
	if hit.is_empty():
		return false
	var source := hit.get("source", null) as Control
	if source == null or not is_instance_valid(source):
		return false
	_on_passive_module_button_input(
		_passive_button_event_for_source(event, source),
		str(hit.get("kind", "")),
		str(hit.get("module_id", "")),
		str(hit.get("stat_type", "")),
		hit.get("popover", null) as Control,
		source
	)
	return true


func _passive_button_global_event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).global_position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).global_position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2.INF


func _passive_button_event_for_source(event: InputEvent, source: Control) -> InputEvent:
	if source == null or not is_instance_valid(source):
		return event
	var global_position := _passive_button_global_event_position(event)
	if global_position == Vector2.INF:
		return event
	var local_position := source.get_global_transform().affine_inverse() * global_position
	var duplicate_event := event.duplicate()
	if duplicate_event is InputEventMouseButton:
		var mouse_button := duplicate_event as InputEventMouseButton
		mouse_button.position = local_position
		mouse_button.global_position = global_position
	elif duplicate_event is InputEventMouseMotion:
		var mouse_motion := duplicate_event as InputEventMouseMotion
		mouse_motion.position = local_position
		mouse_motion.global_position = global_position
	elif duplicate_event is InputEventScreenTouch:
		(duplicate_event as InputEventScreenTouch).position = global_position
	elif duplicate_event is InputEventScreenDrag:
		(duplicate_event as InputEventScreenDrag).position = global_position
	return duplicate_event


func _passive_button_hit_at_position(event_position: Vector2) -> Dictionary:
	_prune_invalid_action_cards()
	var keys := action_card_keys.duplicate()
	keys.reverse()
	for raw_action_key in action_cards.keys():
		var action_key := str(raw_action_key)
		if not keys.has(action_key):
			keys.push_front(action_key)
	for raw_key in keys:
		var key := str(raw_key)
		if not action_cards.has(key):
			continue
		var card := action_cards.get(key, {}) as Dictionary
		if not bool(card.get("passive", false)):
			continue
		var pop := _valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		if not pop.get_global_rect().has_point(event_position):
			continue
		var action := card.get("action", {}) as Dictionary
		var module_id := str(action.get("id", card.get("action_id", PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID)))
		var info_hit := _passive_source_hit_dict(card.get("info_button", null), event_position, "info", module_id, "", card.get("info_popover", null))
		if not info_hit.is_empty():
			return info_hit
		var plank_hit := _passive_source_hit_dict(card.get("plank", null), event_position, "plank", module_id)
		if not plank_hit.is_empty():
			return plank_hit
		var upgrade_buttons := card.get("upgrade_buttons", {}) as Dictionary
		for raw_stat_type in ["time", "yield", "capacity"]:
			var stat_type := str(raw_stat_type)
			var upgrade_hit := _passive_source_hit_dict(upgrade_buttons.get(stat_type, null), event_position, "upgrade", module_id, stat_type)
			if not upgrade_hit.is_empty():
				return upgrade_hit
		var firepit_hit := _passive_source_hit_dict(card.get("toggle", null), event_position, "firepit", module_id)
		if not firepit_hit.is_empty():
			return firepit_hit
		var loot := _valid_control_ref(card.get("loot", null))
		if loot != null and loot.has_meta("passive_log_collect_hotspot_id"):
			var hotspot := _valid_control_ref(instance_from_id(int(loot.get_meta("passive_log_collect_hotspot_id", 0))))
			var hotspot_hit := _passive_source_hit_dict(hotspot, event_position, "collect", module_id)
			if not hotspot_hit.is_empty():
				return hotspot_hit
		var collect_hit := _passive_source_hit_dict(card.get("button", null), event_position, "collect", module_id)
		if not collect_hit.is_empty():
			return collect_hit
	return {}


func _passive_source_hit_dict(source_variant, event_position: Vector2, action_kind: String, module_id: String, stat_type := "", info_popover_variant = null) -> Dictionary:
	var source := _valid_control_ref(source_variant)
	if source == null or not source.is_inside_tree() or not source.is_visible_in_tree():
		return {}
	if source.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return {}
	if source is BaseButton and (source as BaseButton).disabled:
		return {}
	if not source.get_global_rect().has_point(event_position):
		return {}
	return {
		"source": source,
		"kind": action_kind,
		"module_id": module_id,
		"stat_type": stat_type,
		"popover": _valid_control_ref(info_popover_variant)
	}


func _passive_button_event_position(event: InputEvent, source: Control) -> Vector2:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return _global_event_position(mouse_event.position, mouse_event.global_position, source)
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		return _global_event_position(motion_event.position, motion_event.global_position, source)
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return _global_event_position(touch_event.position, touch_event.position, source)
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		return _global_event_position(drag_event.position, drag_event.position, source)
	return Vector2.ZERO


func _schedule_passive_module_button_activation(action_kind: String, module_id: String, stat_type: String, info_popover: Control, source: Control) -> void:
	passive_button_pending_tap_id += 1
	var tap_id := passive_button_pending_tap_id
	var source_id := source.get_instance_id() if source != null and is_instance_valid(source) else 0
	var popover_id := info_popover.get_instance_id() if info_popover != null and is_instance_valid(info_popover) else 0
	await get_tree().create_timer(PASSIVE_BUTTON_TAP_CONFIRM_SECONDS).timeout
	if tap_id != passive_button_pending_tap_id:
		return
	var source_ref := _valid_control_ref(instance_from_id(source_id)) if source_id != 0 else null
	if source_ref == null or passive_button_press_source != source_ref or passive_button_press_kind != action_kind:
		return
	if passive_button_press_dragged or _skill_swipe_suppresses_button_action():
		_clear_passive_button_press()
		return
	_clear_passive_button_press()
	var popover_ref := _valid_control_ref(instance_from_id(popover_id)) if popover_id != 0 else null
	_activate_passive_module_button(action_kind, module_id, stat_type, popover_ref)
	_cancel_skill_swipe_feedback(false)


func _activate_passive_module_button(action_kind: String, module_id: String, stat_type: String, info_popover: Control) -> void:
	if action_kind == "collect":
		_passive_modules_runtime().collect_passive_module(module_id, _unix_now())
	elif action_kind == "info":
		_passive_firepit_surface()._toggle_passive_info_popover(info_popover)
	elif action_kind == "plank":
		_toggle_plank_boost()
	elif action_kind == "upgrade":
		_passive_modules_runtime().upgrade_passive_module(module_id, stat_type, _unix_now())
	elif action_kind == "firepit":
		_passive_modules_runtime().toggle_firepit_pressed(module_id, _unix_now())


func _on_passive_collect_pressed(module_id: String) -> void:
	_cancel_skill_swipe_feedback(false)
	_clear_passive_button_press()
	_passive_modules_runtime().collect_passive_module(module_id, _unix_now())


func _on_passive_plank_pressed(module_id := PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID) -> void:
	_cancel_skill_swipe_feedback(false)
	_clear_passive_button_press()
	_toggle_plank_boost()


func _on_passive_upgrade_pressed(module_id: String, stat_type: String) -> void:
	_cancel_skill_swipe_feedback(false)
	_clear_passive_button_press()
	_passive_modules_runtime().upgrade_passive_module(module_id, stat_type, _unix_now())


func _action_card_event_positions(event: InputEvent, source: Control) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if source == null:
		return positions
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var source_local_rect := Rect2(Vector2.ZERO, source.size)
		var mouse_position_is_local := source_local_rect.has_point(mouse_event.position)
		if mouse_position_is_local:
			_add_unique_event_position(positions, mouse_event.global_position)
			_add_unique_event_position(positions, source.get_global_position() + mouse_event.position)
		else:
			for event_position in _activity_input_position_candidates(mouse_event.global_position):
				_add_unique_event_position(positions, event_position)
			for event_position in _activity_input_position_candidates(mouse_event.position):
				_add_unique_event_position(positions, event_position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		var source_local_rect := Rect2(Vector2.ZERO, source.size)
		var touch_position_is_local := source_local_rect.has_point(touch_event.position)
		if touch_position_is_local:
			_add_unique_event_position(positions, source.get_global_position() + touch_event.position)
		else:
			for event_position in _activity_input_position_candidates(touch_event.position):
				_add_unique_event_position(positions, event_position)
	return positions


func _activity_input_position_candidates(event_position: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	_add_unique_event_position(positions, event_position)
	var window_size := Vector2.ZERO
	if DisplayServer.get_name() != "headless":
		window_size = Vector2(DisplayServer.window_get_size())
	if window_size.x > 1.0 and window_size.y > 1.0:
		_add_unique_event_position(positions, event_position * (BASE_CANVAS.x / window_size.x))
		_add_unique_event_position(positions, event_position * (BASE_CANVAS.y / window_size.y))
		_add_unique_event_position(positions, Vector2(event_position.x * BASE_CANVAS.x / window_size.x, event_position.y * BASE_CANVAS.y / window_size.y))
	if is_inside_tree():
		var visible_size := get_viewport_rect().size
		if visible_size.x > 1.0 and visible_size.y > 1.0:
			_add_unique_event_position(positions, event_position * (BASE_CANVAS.x / visible_size.x))
			_add_unique_event_position(positions, event_position * (BASE_CANVAS.y / visible_size.y))
	return positions


func _add_unique_event_position(positions: Array[Vector2], event_position: Vector2) -> void:
	for existing in positions:
		if existing.distance_to(event_position) <= 0.5:
			return
	positions.append(event_position)


func _first_position_in_rect(positions: Array[Vector2], rect: Rect2) -> Variant:
	for event_position in positions:
		if rect.has_point(event_position):
			return event_position
	return null


func _activity_stat_kind_from_positions(card: Dictionary, positions: Array[Vector2]) -> String:
	if _tutorial_blocks_activity_info_chips():
		return ""
	if _activity_stat_clicks_should_start_action():
		return ""
	if _action_info_chips_blocked_by_lock(card):
		return ""
	for event_position in positions:
		var stat_kind := _activity_stat_kind_at_position(card, event_position)
		if not stat_kind.is_empty():
			return stat_kind
	return ""


func _action_card_medal_hit_from_positions(card: Dictionary, positions: Array[Vector2]) -> bool:
	for event_position in positions:
		if _action_card_medal_hit_at_position(card, event_position):
			return true
	return false


func _action_card_medal_hit_at_position(card: Dictionary, event_position: Vector2) -> bool:
	var medal := card.get("medal") as TextureRect
	if medal == null or not is_instance_valid(medal):
		return false
	if not medal.visible or not medal.is_visible_in_tree():
		return false
	if _action_card_visible_medal_level(card) <= 0:
		return false
	return medal.get_global_rect().grow(26.0).has_point(event_position)


func _action_card_visible_medal_level(card: Dictionary) -> int:
	if card.is_empty() or bool(card.get("mastery_hidden_for_convergence", false)):
		return 0
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("mastery_action_id", card.get("action_id", "")))
	if skill_id.is_empty() or action_id.is_empty():
		return 0
	return clampi(MasteryState.level(mastery, _action_key(skill_id, action_id)), 0, MASTERY_MAX_LEVEL)


func _first_event_position(positions: Array[Vector2]) -> Vector2:
	return positions[0] if not positions.is_empty() else Vector2.ZERO


func _event_positions_close_to_press(positions: Array[Vector2]) -> bool:
	return _event_positions_within_press_slop(positions, ACTION_CARD_TAP_RELEASE_SLOP)


func _event_positions_within_press_slop(positions: Array[Vector2], slop: float) -> bool:
	for event_position in positions:
		if event_position.distance_to(action_card_press_position) <= slop:
			return true
	return false


func _event_positions_inside_activity_stat_box(card: Dictionary, stat_kind: String, positions: Array[Vector2]) -> bool:
	if stat_kind.is_empty() or card.is_empty():
		return false
	if stat_kind == ACTION_CARD_MEDAL_PRESS_KIND:
		return _action_card_medal_hit_from_positions(card, positions)
	if not _action_stat_box_accepts_input(card, stat_kind):
		return false
	var boxes := card.get("stat_boxes", {}) as Dictionary
	var box := boxes.get(stat_kind, null) as Control
	if box == null or not is_instance_valid(box) or not box.is_visible_in_tree():
		return false
	var rect := box.get_global_rect()
	for event_position in positions:
		if rect.has_point(event_position):
			return true
	return false


func _activity_stat_clicks_should_start_action() -> bool:
	return activity_start_count <= 0


func _activity_stat_kind_at_position(card: Dictionary, event_position: Vector2) -> String:
	if _tutorial_blocks_activity_info_chips():
		return ""
	if _activity_stat_clicks_should_start_action():
		return ""
	if _action_info_chips_blocked_by_lock(card):
		return ""
	var stat_row := card.get("stat_row", null) as Control
	if stat_row != null and is_instance_valid(stat_row) and stat_row.is_visible_in_tree() and stat_row.get_global_rect().has_point(event_position):
		var row_boxes := card.get("stat_boxes", {}) as Dictionary
		for kind in ["xp", "stamina", "time", "success"]:
			var row_box := row_boxes.get(kind) as Control
			if row_box != null and is_instance_valid(row_box) and _action_stat_box_accepts_input(card, kind) and row_box.get_global_rect().has_point(event_position):
				return kind
	var boxes := card.get("stat_boxes", {}) as Dictionary
	for kind in ["xp", "stamina", "time", "success"]:
		var box := boxes.get(kind) as Control
		if box != null and is_instance_valid(box) and _action_stat_box_accepts_input(card, kind) and box.get_global_rect().has_point(event_position):
			return kind
	return ""


func _tutorial_blocks_activity_info_chips() -> bool:
	return tutorial_active


func _action_stat_box_accepts_input(card: Dictionary, stat_kind: String) -> bool:
	if card.is_empty() or stat_kind.is_empty():
		return false
	if _tutorial_blocks_activity_info_chips():
		return false
	if _action_info_chips_blocked_by_lock(card):
		return false
	var boxes := card.get("stat_boxes", {}) as Dictionary
	var box := boxes.get(stat_kind, null) as Control
	if box == null or not is_instance_valid(box):
		return false
	if not bool(box.get_meta("action_stat_box_interactive", false)):
		return false
	if box.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	return _control_effectively_visible(box)


func _control_effectively_visible(control: Control, minimum_alpha := 0.05) -> bool:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return false
	var alpha := 1.0
	var current: Node = control
	while current != null:
		if current is CanvasItem:
			var canvas_item := current as CanvasItem
			alpha *= canvas_item.modulate.a
			if alpha <= minimum_alpha:
				return false
		current = current.get_parent()
	return true


func _action_info_chips_blocked_by_lock(card: Dictionary) -> bool:
	if card.is_empty():
		return true
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("action_id", ""))
	var action := card.get("action", {}) as Dictionary
	if action.is_empty() and not skill_id.is_empty() and not action_id.is_empty():
		action = _action_data(skill_id, action_id)
	if skill_id.is_empty() or action.is_empty():
		return true
	var resolved_action_id := str(action.get("id", action_id))
	return (
		not _is_action_unlocked(skill_id, action)
		or bool(card.get("unlock_ceremony_pending", false))
		or bool(card.get("unlock_ceremony_active", false))
		or bool(card.get("unlock_ready_pending", false))
		or _action_has_pending_unlock_readiness(resolved_action_id)
	)


func _sync_action_stat_box_input_enabled(card: Dictionary, enabled: bool) -> void:
	var boxes := card.get("stat_boxes", {}) as Dictionary
	for kind in boxes.keys():
		var box := boxes[kind] as Control
		if box == null or not is_instance_valid(box):
			continue
		if not bool(box.get_meta("action_stat_box_interactive", false)):
			continue
		box.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _set_activity_card_expanded(card: Dictionary, root: Control, expanded: bool, instant: bool) -> void:
	_skill_detail_surface()._set_activity_card_expanded(card, root, expanded, instant)
func _set_label_text_if_changed(label: Label, next_text: String) -> void:
	if label != null and label.text != next_text:
		label.text = next_text


func _set_button_text_if_changed(button: Button, next_text: String) -> void:
	if button != null and button.text != next_text:
		button.text = next_text


func _colors_close_enough(current: Color, next: Color) -> bool:
	return (
		absf(current.r - next.r) <= 0.001
		and absf(current.g - next.g) <= 0.001
		and absf(current.b - next.b) <= 0.001
		and absf(current.a - next.a) <= 0.001
	)


func _set_canvas_item_visible_if_changed(item: CanvasItem, should_show: bool) -> void:
	if item != null and is_instance_valid(item) and not item.is_queued_for_deletion() and item.visible != should_show:
		item.visible = should_show


func _set_canvas_item_modulate_if_changed(item: CanvasItem, next_modulate: Color) -> void:
	if item != null and is_instance_valid(item) and not item.is_queued_for_deletion() and not _colors_close_enough(item.modulate, next_modulate):
		item.modulate = next_modulate


func _set_canvas_item_alpha_if_changed(item: CanvasItem, next_alpha: float) -> void:
	if item == null or not is_instance_valid(item) or item.is_queued_for_deletion():
		return
	var clamped_alpha := clampf(next_alpha, 0.0, 1.0)
	if absf(item.modulate.a - clamped_alpha) <= 0.001:
		return
	var next_modulate := item.modulate
	next_modulate.a = clamped_alpha
	item.modulate = next_modulate


func _set_base_button_disabled_if_changed(button: BaseButton, should_disable: bool) -> void:
	if button != null and is_instance_valid(button) and not button.is_queued_for_deletion() and button.disabled != should_disable:
		button.disabled = should_disable


func _skill_level_completion_counts() -> Dictionary:
	var earned := 0
	var possible := 0
	for def in skill_defs:
		var level_targets := AchievementPresentation.skill_level_targets()
		possible += level_targets.size()
		for target in level_targets:
			if _skill_level(str(def["id"])) >= int(target):
				earned += 1
	return {"earned": earned, "possible": possible}


func _elite_completion_counts() -> Dictionary:
	var medal_counts := AchievementState.all_medal_counts(self)
	var skill_counts := _skill_level_completion_counts()
	return {
		"earned": int(medal_counts["earned"]) + int(skill_counts["earned"]),
		"possible": int(medal_counts["possible"]) + int(skill_counts["possible"])
	}


func _most_impressive_activity() -> Dictionary:
	var best := {}
	var best_score := -1.0
	var best_level := 0
	for def in skill_defs:
		var skill_id := str(def["id"])
		var actions: Array = AchievementState.mastery_actions_for_skill(self, skill_id)
		for action in actions:
			var action_id := str(action.get("id", ""))
			var level := MasteryState.level(mastery, _action_key(skill_id, action_id))
			if level <= 0:
				continue
			var seconds_required := float(action.get("seconds", 1.0)) * float(MasteryState.xp_for_level(level))
			if seconds_required > best_score or (is_equal_approx(seconds_required, best_score) and level > best_level):
				best_score = seconds_required
				best_level = level
				best = {
					"skill_id": skill_id,
					"action_id": action_id,
					"name": str(action.get("name", "")),
					"art": str(action.get("art", "")),
					"level": level,
					"medal": str(MASTERY_MEDAL_NAMES[clampi(level, 1, MASTERY_MAX_LEVEL) - 1]),
					"seconds_required": seconds_required
				}
	return best


func _global_medal_buff_lines() -> String:
	var lines := _active_global_buff_lines()
	if lines.is_empty():
		return "Earn your first Bronze medal to unlock the first global buff."
	return "\n".join(lines)


func _active_global_buff_lines() -> Array:
	var lines := []
	var stamina_bonus := int(round(AchievementState.global_reward_bonus(self, "max_stamina")))
	var xp_bonus := int(round((AchievementState.global_reward_bonus(self, "xp_mult") + _ad_bonus_runtime().xp_multiplier()) * 100.0))
	var speed_bonus := int(round((AchievementState.global_reward_bonus(self, "speed_mult") + _ad_bonus_runtime().speed_multiplier()) * 100.0))
	var success_bonus := int(round(AchievementState.global_reward_bonus(self, "success_bonus")))
	var crit_bonus := AchievementState.global_reward_bonus(self, "crit_chance_mult") * 100.0
	if stamina_bonus > 0:
		lines.append("+%s max stamina" % stamina_bonus)
	if xp_bonus > 0:
		lines.append("+%s%% XP" % xp_bonus)
	if speed_bonus > 0:
		lines.append("+%s%% speed" % speed_bonus)
	if success_bonus > 0:
		lines.append("+%s%% success" % success_bonus)
	if crit_bonus > 0.0:
		lines.append("+%s%% crit chance" % GameFormatting.percent_points(crit_bonus))
	var firepit_regen_bonus := _passive_modules_runtime().firepit_stamina_regen_bonus("woodcutting", _unix_now())
	if firepit_regen_bonus > 0.0:
		var now := _unix_now()
		lines.append(_passive_modules_runtime().firepit_comfort_text(_passive_modules_runtime().firepit_heat_tier(now)))
	return lines


func _on_stamina_gauge_input(event: InputEvent, skill_id := "", source: RegenCircle = null) -> void:
	if _stamina_gauge_event_hits_auto_eat_toggle(event):
		_cancel_pending_stamina_gauge_click()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_suppress_stamina_gauge_parent_button(source)
		if event.pressed:
			_begin_stamina_gauge_click_or_hold(skill_id, source)
		else:
			_finish_stamina_gauge_click_or_hold(skill_id, source)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		_suppress_stamina_gauge_parent_button(source)
		if event.pressed:
			_begin_stamina_gauge_click_or_hold(skill_id, source)
		else:
			_finish_stamina_gauge_click_or_hold(skill_id, source)
		get_viewport().set_input_as_handled()


func _cancel_pending_stamina_gauge_click() -> void:
	stamina_gauge_pending_click = false
	stamina_gauge_pending_skill_id = ""
	stamina_gauge_pending_hold_seconds = 0.0
	stamina_gauge_press_source = null


func _stamina_gauge_event_hits_auto_eat_toggle(event: InputEvent) -> bool:
	var event_position := Vector2.ZERO
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		event_position = _global_event_position(mouse_event.position, mouse_event.global_position, self)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = _global_event_position(touch_event.position, touch_event.position, self)
	else:
		return false
	for node in get_tree().get_nodes_in_group("auto_eat_fish_toggle"):
		var button := node as TextureButton
		if button == null or not is_instance_valid(button) or not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		if button.get_global_rect().grow(8.0).has_point(event_position):
			return true
	return false


func _suppress_stamina_gauge_parent_button(source: Control) -> void:
	var button := _stamina_gauge_parent_button(source)
	if button == null:
		return
	button.set_meta("stamina_gauge_suppress_parent_until_msec", Time.get_ticks_msec() + STAMINA_GAUGE_PARENT_BUTTON_SUPPRESS_MSEC)
	button.set_meta("suppress_current_press_animation", true)


func _stamina_gauge_parent_button(source: Control) -> BaseButton:
	var node := source as Node
	while node != null:
		if node is BaseButton:
			return node as BaseButton
		node = node.get_parent()
	return null


func _button_has_active_stamina_gauge_parent_suppression(button: BaseButton) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	var until_msec := int(button.get_meta("stamina_gauge_suppress_parent_until_msec", 0))
	if until_msec <= 0:
		return false
	if Time.get_ticks_msec() <= until_msec:
		return true
	button.remove_meta("stamina_gauge_suppress_parent_until_msec")
	return false


func _consume_skill_menu_gauge_parent_suppression(skill_id: String) -> bool:
	if not skill_cards.has(skill_id):
		return false
	var card := skill_cards.get(skill_id, {}) as Dictionary
	var button := card.get("button") as BaseButton
	if not _button_has_active_stamina_gauge_parent_suppression(button):
		return false
	button.remove_meta("stamina_gauge_suppress_parent_until_msec")
	return true


func _is_stamina_gauge_release_event(event: InputEvent) -> bool:
	if not stamina_gauge_press_active and not stamina_gauge_pending_click:
		return false
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


func _begin_stamina_gauge_click_or_hold(skill_id := "", source: RegenCircle = null) -> void:
	var target_skill_id := skill_id if not skill_id.is_empty() else selected_skill_id
	if target_skill_id.is_empty() or not _stamina_gauge_interaction_screen_active():
		return
	_cancel_skill_swipe_feedback(false)
	stamina_gauge_pending_click = true
	stamina_gauge_pending_skill_id = target_skill_id
	stamina_gauge_pending_hold_seconds = 0.0
	stamina_gauge_press_source = source


func _stamina_gauge_interaction_screen_active() -> bool:
	return current_screen == "skill" or current_screen == "menu" or current_screen == "pinned" or current_screen == "queue"


func _finish_stamina_gauge_click_or_hold(skill_id := "", source: RegenCircle = null) -> void:
	if stamina_gauge_pending_click:
		var target_skill_id := stamina_gauge_pending_skill_id
		var target_source := stamina_gauge_press_source if stamina_gauge_press_source != null else source
		stamina_gauge_pending_click = false
		stamina_gauge_pending_skill_id = ""
		stamina_gauge_pending_hold_seconds = 0.0
		stamina_gauge_press_source = null
		_try_eat_fish_for_stamina(target_skill_id if not target_skill_id.is_empty() else skill_id, target_source)
		return
	_set_stamina_gauge_pressed(false, skill_id, source)


func _set_stamina_gauge_pressed(pressed: bool, skill_id := "", source: RegenCircle = null) -> void:
	if pressed:
		var boost_skill_id := skill_id if not skill_id.is_empty() else selected_skill_id
		if boost_skill_id.is_empty() or (current_screen != "skill" and current_screen != "menu"):
			return
		stamina_gauge_press_active = true
		stamina_gauge_boost_skill_id = boost_skill_id
		stamina_gauge_press_source = source
		stamina_gauge_regen_target_multiplier = STAMINA_GAUGE_REGEN_BOOST_MULT
		_cancel_skill_swipe_feedback(false)
		_pop_stamina_gauge(source)
	else:
		stamina_gauge_pending_click = false
		stamina_gauge_pending_skill_id = ""
		stamina_gauge_pending_hold_seconds = 0.0
		stamina_gauge_press_active = false
		stamina_gauge_press_source = null
		stamina_gauge_pre_tip_hold_seconds = 0.0
		stamina_gauge_regen_target_multiplier = 1.0


func _cancel_stamina_gauge_boost_for_navigation() -> void:
	stamina_gauge_pending_click = false
	stamina_gauge_pending_skill_id = ""
	stamina_gauge_pending_hold_seconds = 0.0
	stamina_gauge_press_active = false
	stamina_gauge_boost_skill_id = ""
	stamina_gauge_press_source = null
	stamina_gauge_pre_tip_hold_seconds = 0.0
	stamina_gauge_regen_multiplier = 1.0
	stamina_gauge_regen_target_multiplier = 1.0
	_clear_stamina_gauge_pop_tween()


func _process_stamina_gauge_regen_boost(delta: float) -> void:
	if delta <= 0.0:
		return
	if (
		not stamina_gauge_pending_click
		and not stamina_gauge_press_active
		and stamina_gauge_regen_target_multiplier <= 1.0
		and absf(stamina_gauge_regen_multiplier - 1.0) <= 0.001
	):
		stamina_gauge_regen_multiplier = 1.0
		stamina_gauge_boost_skill_id = ""
		return
	if stamina_gauge_pending_click and not _stamina_gauge_interaction_screen_active():
		_set_stamina_gauge_pressed(false)
	if stamina_gauge_pending_click:
		stamina_gauge_pending_hold_seconds += delta
		if stamina_gauge_pending_hold_seconds >= STAMINA_GAUGE_HOLD_BOOST_SECONDS:
			var boost_skill_id := stamina_gauge_pending_skill_id
			var boost_source := stamina_gauge_press_source
			stamina_gauge_pending_click = false
			stamina_gauge_pending_skill_id = ""
			stamina_gauge_pending_hold_seconds = 0.0
			_set_stamina_gauge_pressed(true, boost_skill_id, boost_source)
	if stamina_gauge_press_active and current_screen != "skill" and current_screen != "menu":
		_set_stamina_gauge_pressed(false)
	var target := clampf(stamina_gauge_regen_target_multiplier, 1.0, STAMINA_GAUGE_REGEN_BOOST_MULT)
	var weight := 1.0 - exp(-STAMINA_GAUGE_REGEN_EASE_SPEED * delta)
	stamina_gauge_regen_multiplier = lerpf(stamina_gauge_regen_multiplier, target, weight)
	if absf(stamina_gauge_regen_multiplier - target) <= 0.001:
		stamina_gauge_regen_multiplier = target
		if not stamina_gauge_press_active and target <= 1.0:
			stamina_gauge_boost_skill_id = ""


func _try_eat_fish_for_stamina(skill_id := "", source: RegenCircle = null) -> void:
	var target_skill_id := skill_id if not skill_id.is_empty() else selected_skill_id
	var target := _visible_stamina_gauge_for_skill(target_skill_id, source)
	if target_skill_id.is_empty() or not _stamina_gauge_interaction_screen_active():
		return
	_cancel_skill_swipe_feedback(false)
	if _stamina_value(target_skill_id) >= float(_max_stamina(target_skill_id)) - 0.0001:
		_float_stamina_full(target)
		_play_stamina_gauge_eat_fail(target)
		return
	if fish_currency < 1.0:
		_float_stamina_need_fish(target)
		_play_stamina_gauge_eat_fail(target)
		return
	fish_currency = maxf(0.0, fish_currency - 1.0)
	stamina[target_skill_id] = minf(float(_max_stamina(target_skill_id)), _stamina_value(target_skill_id) + 1.0)
	_sync_stamina_bank(target_skill_id)
	_pop_stamina_gauge(target)
	_fishing_ui_surface()._float_eaten_fish_icon(target_skill_id, target)
	_audio_director()._play_fish_eat_blip()
	_update_ui(0.0, true)
	save_game()


func _auto_eat_fish_for_action(skill_id: String, stamina_cost: float, source: RegenCircle = null, show_fail := false) -> bool:
	_clear_auto_eat_fish_after_spend_delay(skill_id)
	if stamina_cost <= 0.0:
		return true
	if not _auto_eat_fish_enabled_for_skill(skill_id) or skill_id.is_empty() or _fishing_rework_active_for_skill(skill_id):
		return _stamina_value(skill_id) + 0.0001 >= stamina_cost
	if _stamina_value(skill_id) + 0.0001 >= stamina_cost:
		return true
	var maximum := float(_max_stamina(skill_id))
	if maximum <= 0.0 or stamina_cost > maximum + 0.0001:
		return false
	var current_stamina := _stamina_value(skill_id)
	var stamina_room := maxi(0, int(ceil(maximum - current_stamina - 0.0001)))
	var needed_fish := maxi(0, int(ceil(stamina_cost - current_stamina - 0.0001)))
	var available_fish := maxi(0, int(floor(fish_currency)))
	var fish_to_eat := mini(needed_fish, mini(stamina_room, available_fish))
	if fish_to_eat <= 0:
		if show_fail:
			_float_stamina_need_fish(source)
			_play_stamina_gauge_eat_fail(source)
		return _stamina_value(skill_id) + 0.0001 >= stamina_cost
	fish_currency = maxf(0.0, fish_currency - float(fish_to_eat))
	stamina[skill_id] = minf(maximum, current_stamina + float(fish_to_eat))
	_sync_stamina_bank(skill_id)
	var target := _visible_stamina_gauge_for_skill(skill_id, source)
	_pop_stamina_gauge(target)
	_play_staggered_eaten_fish_icons(skill_id, target.get_instance_id() if target != null and is_instance_valid(target) else 0, fish_to_eat)
	_update_ui(0.0, true)
	return _stamina_value(skill_id) + 0.0001 >= stamina_cost


func _schedule_auto_eat_fish_after_spend_delay(skill_id: String, stamina_cost: float) -> void:
	if skill_id.is_empty() or stamina_cost <= 0.0 or _fishing_rework_active_for_skill(skill_id):
		return
	if not _auto_eat_fish_enabled_for_skill(skill_id):
		return
	if _stamina_value(skill_id) + 0.0001 >= stamina_cost:
		_clear_auto_eat_fish_after_spend_delay(skill_id)
		return
	if not _auto_eat_fish_can_cover_action(skill_id, stamina_cost):
		_clear_auto_eat_fish_after_spend_delay(skill_id)
		return
	auto_eat_fish_after_spend_due_msec_by_skill[skill_id] = Time.get_ticks_msec() + AUTO_EAT_FISH_AFTER_SPEND_VISUAL_DELAY_MSEC


func _clear_auto_eat_fish_after_spend_delay(skill_id: String) -> void:
	if skill_id.is_empty():
		return
	auto_eat_fish_after_spend_due_msec_by_skill.erase(skill_id)


func _auto_eat_fish_after_spend_delay_active(skill_id: String) -> bool:
	return not skill_id.is_empty() and auto_eat_fish_after_spend_due_msec_by_skill.has(skill_id)


func _auto_eat_fish_after_spend_delay_due(skill_id: String) -> bool:
	if not _auto_eat_fish_after_spend_delay_active(skill_id):
		return false
	return Time.get_ticks_msec() >= int(auto_eat_fish_after_spend_due_msec_by_skill.get(skill_id, 0))


func _auto_eat_fish_can_cover_action(skill_id: String, stamina_cost: float) -> bool:
	if not _auto_eat_fish_enabled_for_skill(skill_id) or skill_id.is_empty() or _fishing_rework_active_for_skill(skill_id):
		return false
	if stamina_cost <= 0.0 or _stamina_value(skill_id) + 0.0001 >= stamina_cost:
		return true
	var maximum := float(_max_stamina(skill_id))
	if maximum <= 0.0 or stamina_cost > maximum + 0.0001:
		return false
	var current_stamina := _stamina_value(skill_id)
	var stamina_room := maxi(0, int(ceil(maximum - current_stamina - 0.0001)))
	var needed_fish := maxi(0, int(ceil(stamina_cost - current_stamina - 0.0001)))
	var available_fish := maxi(0, int(floor(fish_currency)))
	return mini(needed_fish, mini(stamina_room, available_fish)) >= needed_fish


func _play_staggered_eaten_fish_icons(skill_id: String, target_id: int, fish_count: int) -> void:
	var safe_count := clampi(fish_count, 0, 24)
	for i in range(safe_count):
		var target := _valid_control_ref(instance_from_id(target_id))
		if target == null:
			target = _visible_stamina_gauge_for_skill(skill_id)
		_fishing_ui_surface()._float_eaten_fish_icon(skill_id, target)
		_audio_director()._play_fish_eat_blip()
		if i < safe_count - 1:
			await get_tree().create_timer(0.055).timeout


func _float_stamina_need_fish(source: Control = null) -> void:
	_float_stamina_gauge_feedback(source, "need fish!", Color("#ffd95a"))


func _float_stamina_full(source: Control = null) -> void:
	_float_stamina_gauge_feedback(source, "full", Color("#9ff7ff"))


func _float_stamina_gauge_feedback(source: Control, text: String, color: Color) -> void:
	var target := source if source != null else detail_regen_circle
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return
	_reward_feedback_surface()._float_reward(
		self,
		target,
		text,
		58,
		color,
		Vector2(0, -48),
		Vector2(0, -150),
		0.0,
		false,
		-1.0,
		STAMINA_NEED_FISH_FLOAT_GROUP
	)


func _play_stamina_gauge_eat_fail(source: RegenCircle = null) -> void:
	var target := source if source != null else detail_regen_circle
	if target != null and is_instance_valid(target):
		_play_stamina_gauge_fail_shake(target)
	_audio_director()._play_failure_sfx()


func _play_stamina_gauge_fail_shake(target: Control) -> void:
	if target == null or not is_instance_valid(target):
		return
	var tween_meta_key := "stamina_eat_fail_tween"
	var rest_position_meta_key := "stamina_eat_fail_rest_position"
	var rest_rotation_meta_key := "stamina_eat_fail_rest_rotation"
	var base_position := target.position
	if target.has_meta(rest_position_meta_key):
		base_position = _meta_vector2(target, rest_position_meta_key, target.position)
	else:
		target.set_meta(rest_position_meta_key, base_position)
	var base_rotation := target.rotation
	if target.has_meta(rest_rotation_meta_key):
		base_rotation = float(target.get_meta(rest_rotation_meta_key))
	else:
		target.set_meta(rest_rotation_meta_key, base_rotation)
	_kill_meta_tween(target, tween_meta_key)
	target.pivot_offset = target.size * 0.5
	target.position = base_position
	target.rotation = base_rotation
	target.modulate = Color(1.0, 1.0, 1.0, target.modulate.a)
	var direction := -1.0 if randf() < 0.5 else 1.0
	var tween := create_tween()
	target.set_meta(tween_meta_key, tween)
	var target_id := target.get_instance_id()
	tween.set_parallel(true)
	tween.tween_method(_apply_stamina_fail_shake_frame.bind(target_id, base_position, base_rotation, direction), 0.0, 1.0, 0.36).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(_finish_stamina_fail_shake.bind(target_id, base_position, base_rotation, tween_meta_key, rest_position_meta_key, rest_rotation_meta_key))


func _apply_stamina_fail_shake_frame(progress: float, target_id: int, base_position: Vector2, base_rotation: float, direction: float) -> void:
	var tween_target := _valid_control_ref(instance_from_id(target_id))
	if tween_target == null:
		return
	var remaining := 1.0 - progress
	var wave := sin(progress * PI * 7.0) * remaining * direction
	tween_target.position = base_position + Vector2(wave * 14.0, absf(wave) * 3.0)
	tween_target.rotation = base_rotation + wave * 0.035


func _finish_stamina_fail_shake(target_id: int, base_position: Vector2, base_rotation: float, tween_meta_key: String, rest_position_meta_key: String, rest_rotation_meta_key: String) -> void:
	var tween_target := _valid_control_ref(instance_from_id(target_id))
	if tween_target == null:
		return
	tween_target.position = base_position
	tween_target.rotation = base_rotation
	tween_target.modulate = Color(1.0, 1.0, 1.0, tween_target.modulate.a)
	if tween_target.has_meta(tween_meta_key):
		tween_target.remove_meta(tween_meta_key)
	if tween_target.has_meta(rest_position_meta_key):
		tween_target.remove_meta(rest_position_meta_key)
	if tween_target.has_meta(rest_rotation_meta_key):
		tween_target.remove_meta(rest_rotation_meta_key)


func _visible_stamina_gauge_for_skill(skill_id: String, fallback: RegenCircle = null) -> RegenCircle:
	if fallback != null and is_instance_valid(fallback) and fallback.is_inside_tree() and fallback.is_visible_in_tree():
		return fallback
	if current_screen == "menu" and skill_cards.has(skill_id):
		var card := skill_cards.get(skill_id, {}) as Dictionary
		var menu_gauge := card.get("stamina") as RegenCircle
		if menu_gauge != null and is_instance_valid(menu_gauge) and menu_gauge.is_inside_tree():
			return menu_gauge
	if current_screen == "skill" and selected_skill_id == skill_id and detail_regen_circle != null and is_instance_valid(detail_regen_circle):
		return detail_regen_circle
	if (current_screen == "pinned" or current_screen == "queue") and pinned_active_shelf_skill_id == skill_id and pinned_active_shelf_regen_circle != null and is_instance_valid(pinned_active_shelf_regen_circle):
		return pinned_active_shelf_regen_circle
	if (current_screen == "pinned" or current_screen == "queue") and pinned_active_shelf_stamina_gauges.has(skill_id):
		var pinned_strip_gauge := pinned_active_shelf_stamina_gauges.get(skill_id, null) as RegenCircle
		if pinned_strip_gauge != null and is_instance_valid(pinned_strip_gauge) and pinned_strip_gauge.is_inside_tree() and pinned_strip_gauge.is_visible_in_tree():
			return pinned_strip_gauge
	return detail_regen_circle if detail_regen_circle != null and is_instance_valid(detail_regen_circle) else null


func _pop_stamina_gauge(source: RegenCircle = null) -> void:
	var target := source if source != null else detail_regen_circle
	if target == null or not is_instance_valid(target):
		return
	_clear_stamina_gauge_pop_tween()
	target.pivot_offset = target.size * 0.5
	target.scale = Vector2.ONE
	detail_stamina_gauge_pop_tween = create_tween()
	detail_stamina_gauge_pop_source = target
	detail_stamina_gauge_pop_tween.tween_property(target, "scale", STAMINA_GAUGE_POP_SCALE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	detail_stamina_gauge_pop_tween.tween_property(target, "scale", STAMINA_GAUGE_SETTLE_SCALE, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	detail_stamina_gauge_pop_tween.tween_property(target, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	detail_stamina_gauge_pop_tween.finished.connect(_finish_stamina_gauge_pop_tween)


func _clear_stamina_gauge_pop_tween() -> void:
	if detail_stamina_gauge_pop_tween != null and detail_stamina_gauge_pop_tween.is_valid():
		detail_stamina_gauge_pop_tween.kill()
	if detail_stamina_gauge_pop_source != null and is_instance_valid(detail_stamina_gauge_pop_source):
		detail_stamina_gauge_pop_source.scale = Vector2.ONE
	detail_stamina_gauge_pop_tween = null
	detail_stamina_gauge_pop_source = null


func _finish_stamina_gauge_pop_tween() -> void:
	detail_stamina_gauge_pop_tween = null
	detail_stamina_gauge_pop_source = null


func _visible_actions_for_skill(skill_id: String) -> Array:
	var visible_actions := []
	var mono_lock_blocker_seen := false
	for action in actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		if action_data.is_empty():
			continue
		if _onboarding_runtime()._tutorial_starter_only_detail_active(skill_id) and str(action_data.get("id", "")) != TUTORIAL_STARTER_ACTION_ID:
			continue
		if _onboarding_runtime()._tutorial_should_defer_action_until_skill_swipe(skill_id, action_data):
			if not _action_is_combo_module(skill_id, action_data):
				mono_lock_blocker_seen = true
			continue
		if not _is_action_unlocked(skill_id, action_data):
			if mono_lock_blocker_seen:
				continue
			if not _action_is_combo_module(skill_id, action_data):
				mono_lock_blocker_seen = true
		visible_actions.append(action)
	return visible_actions


func _visible_action_entries_for_skill(skill_id: String) -> Array:
	var entries := []
	for raw_action in _visible_actions_for_skill(skill_id):
		entries.append({"kind": "action", "action": raw_action as Dictionary})
	for raw_event_action in _temporary_event_runtime()._active_event_actions_for_skill(skill_id):
		entries.append({"kind": "action", "action": raw_event_action as Dictionary})
	if entries.size() > 1:
		entries.sort_custom(func(left, right):
			if typeof(left) != TYPE_DICTIONARY:
				return false
			if typeof(right) != TYPE_DICTIONARY:
				return true
			var left_action := (left as Dictionary).get("action", {}) as Dictionary
			var right_action := (right as Dictionary).get("action", {}) as Dictionary
			return _activity_data_catalog().activity_action_display_sort_less(left_action, right_action)
		)
	return entries


func _detail_entry_level_sort_value(entry: Dictionary, skill_id: String) -> int:
	match str(entry.get("kind", "action")):
		"thieving_heist":
			return maxi(1, int((entry.get("heist", {}) as Dictionary).get("unlock", 1)))
		"fishing_area":
			return _fishing_render_module_unlock(entry.get("area_def", {}) as Dictionary)
		"fishing_offer":
			return _fishing_ui_surface()._fishing_offer_unlock_level(str(entry.get("offer_id", "")))
		_:
			return _activity_data_catalog().activity_action_display_sort_level(entry.get("action", {}) as Dictionary)


func _action_is_collection_module(owner_skill_id: String, action: Dictionary) -> bool:
	return (
		owner_skill_id == "woodcutting"
		and str(action.get("kind", "")) == "passive_item_collect"
		and int(action.get("unlock", 0)) == 2
	)


func _visible_detail_entries_for_skill(skill_id: String) -> Array:
	var entries := []
	var pending_heists := thieving_state.visible_heists_for_render() if skill_id == "thieving" else []
	var heist_index := 0
	for raw_entry in _visible_action_entries_for_skill(skill_id):
		var entry := raw_entry as Dictionary
		var action := entry.get("action", {}) as Dictionary
		var action_sort_unlock := _activity_data_catalog().activity_action_display_sort_level(action)
		while heist_index < pending_heists.size() and int((pending_heists[heist_index] as Dictionary).get("unlock", 1)) <= action_sort_unlock:
			entries.append({"kind": "thieving_heist", "heist": pending_heists[heist_index]})
			heist_index += 1
		entries.append(entry)
	while heist_index < pending_heists.size():
		entries.append({"kind": "thieving_heist", "heist": pending_heists[heist_index]})
		heist_index += 1
	return module_ui_runtime.sort_detail_entries(
		entries,
		skill_id,
		Callable(self, "_detail_entry_level_sort_value"),
		Callable(self, "_action_is_combo_module"),
		Callable(self, "_action_is_collection_module")
	)

func _ensure_all_thieving_trophy_state() -> void:
	thieving_state.ensure_all_trophy_state()
	_hub_runtime().sync_trophy_level_from_thieving()


func _locked_activity_preview_available() -> bool:
	for raw_skill_id in skills.keys():
		var skill_id := str(raw_skill_id)
		if int(skills.get(skill_id, {}).get("xp", 0)) >= LOCKED_ACTIVITY_PREVIEW_XP_THRESHOLD:
			return true
	return false


func _first_locked_action_id(skill_id: String) -> String:
	for action in actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		if not _is_action_unlocked(skill_id, action_data) and _action_blocks_owner_skill_progression(skill_id, action_data):
			return str(action.get("id", ""))
	return ""


func _first_locked_action_id_after_manual_unlock(skill_id: String, unlocked_action_id: String) -> String:
	var passed_unlocked_action := false
	for action in actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		var action_id := str(action_data.get("id", ""))
		if action_id == unlocked_action_id:
			passed_unlocked_action = true
			continue
		if not passed_unlocked_action:
			continue
		if _onboarding_runtime()._tutorial_should_defer_action_until_skill_swipe(skill_id, action_data):
			continue
		if not _is_action_unlocked(skill_id, action_data):
			return action_id
	for action in actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		var action_id := str(action_data.get("id", ""))
		if action_id == unlocked_action_id:
			continue
		if not _is_action_unlocked(skill_id, action_data) and _action_blocks_owner_skill_progression(skill_id, action_data):
			return action_id
	return ""


func _preview_after_manual_activity_unlock(skill_id: String, unlocked_action_id: String) -> String:
	var preview_id := _onboarding_runtime()._tutorial_preview_after_manual_unlock(skill_id, unlocked_action_id)
	return preview_id if not preview_id.is_empty() else _first_locked_action_id_after_manual_unlock(skill_id, unlocked_action_id)


func _action_blocks_owner_skill_progression(skill_id: String, action: Dictionary) -> bool:
	if action.is_empty():
		return false
	if _action_is_combo_module(skill_id, action):
		return false
	var requirements := _activity_unlock_runtime()._action_unlock_requirements(skill_id, action)
	var has_owner_requirement := false
	for raw_requirement in requirements:
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		if str(requirement.get("skill", skill_id)) != skill_id:
			continue
		has_owner_requirement = true
		if not _activity_unlock_runtime()._requirement_met(requirement):
			return true
	if not has_owner_requirement:
		return false
	if _activity_unlock_runtime()._action_requirements_met_from_requirements(requirements):
		return not _is_action_unlocked(skill_id, action)
	return false


func _action_is_combo_module(owner_skill_id: String, action: Dictionary) -> bool:
	if action.is_empty():
		return false
	var combo_tags = action.get("combo_tags", [])
	if typeof(combo_tags) == TYPE_ARRAY and not (combo_tags as Array).is_empty():
		return true
	var display_tags = action.get("display_tags", [])
	if typeof(display_tags) == TYPE_ARRAY:
		for raw_tag in display_tags:
			if str(raw_tag).to_lower() == "combo":
				return true
	var xp_rewards = action.get("xp_rewards", {})
	if typeof(xp_rewards) == TYPE_DICTIONARY and (xp_rewards as Dictionary).size() > 1:
		return true
	for raw_requirement in _activity_unlock_runtime()._action_unlock_requirements(owner_skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		if str(requirement.get("skill", owner_skill_id)) != owner_skill_id:
			return true
	return false


func _skill_swipe_navigation_blocks_detail_refresh() -> bool:
	return (
		skill_swipe_animating
		or skill_swipe_pending_full_finalize
	)


func _normalize_skill_detail_page_layout(page: Control = null) -> void:
	_reset_skill_swipe_frame_layout()
	if not skill_strip_ids.is_empty():
		return
	var target_page := page
	if target_page == null or not is_instance_valid(target_page):
		target_page = skill_swipe_page
	if target_page != null and is_instance_valid(target_page):
		target_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		target_page.offset_left = 0.0
		target_page.offset_top = 0.0
		target_page.offset_right = 0.0
		target_page.offset_bottom = 0.0
		target_page.position = Vector2.ZERO


func _reset_skill_swipe_entry_positions() -> void:
	_restore_skill_strip_wrap_page()
	_normalize_skill_detail_page_layout()


func _set_skill_strip_page_virtual_pos(skill_id: String, virtual_left: float) -> void:
	if skill_strip_wrap_relocated_id == skill_id:
		return
	if not skill_strip_wrap_relocated_id.is_empty():
		_restore_skill_strip_wrap_page()
	var refs := skill_strip_refs.get(skill_id, {}) as Dictionary
	var page := refs.get("page") as Control
	if page == null or not is_instance_valid(page):
		return
	var content_width := _skill_content_width()
	page.offset_left = virtual_left
	page.offset_right = virtual_left + content_width
	skill_strip_wrap_relocated_id = skill_id


func _restore_skill_strip_wrap_page() -> void:
	if skill_strip_wrap_relocated_id.is_empty():
		return
	var sid := skill_strip_wrap_relocated_id
	skill_strip_wrap_relocated_id = ""
	var refs := skill_strip_refs.get(sid, {}) as Dictionary
	var page := refs.get("page") as Control
	if page == null or not is_instance_valid(page):
		return
	var page_idx := skill_strip_ids.find(sid)
	if page_idx < 0:
		return
	var content_width := _skill_content_width()
	page.offset_left = float(page_idx) * content_width
	page.offset_right = float(page_idx) * content_width + content_width


func _swap_skill_strip_refs(sid: String) -> void:
	if not skill_strip_refs.has(sid):
		return
	_sync_skill_strip_page_visibility(false)
	var refs := skill_strip_refs[sid] as Dictionary
	skill_swipe_page = refs.get("page") as Control
	detail_xp_label = refs.get("xp_label") as Label
	detail_xp_bar = refs.get("xp_bar") as CleanProgressBar
	detail_regen_circle = refs.get("regen_circle") as RegenCircle
	detail_regen_circle_host = refs.get("regen_circle_host") as Control
	detail_regen_circle_fade_group = refs.get("regen_circle_fade_group") as CanvasGroup
	detail_fish_circle = refs.get("fish_circle") as FishCircle
	detail_auto_eat_fish_button = refs.get("auto_eat_fish_button") as TextureButton
	detail_stamina_bar = refs.get("stamina_bar") as CleanProgressBar
	detail_header_body = refs.get("header_body") as Control
	detail_header_left_block = refs.get("header_left_block") as Control
	detail_actions_scroll = refs.get("actions_scroll") as MobileScrollContainer
	detail_unlock_scroll_spacer = refs.get("unlock_scroll_spacer") as Control
	detail_shelf_shadow_overlay = refs.get("shelf_shadow_overlay") as Control
	detail_back_button = refs.get("back_button") as BaseButton
	detail_action_card_nodes = refs.get("action_card_nodes", {}) as Dictionary
	detail_rendered_action_ids = refs.get("rendered_action_ids", []) as Array
	detail_lazy_plan = refs.get("lazy_plan", []) as Array
	detail_lazy_stack = refs.get("lazy_stack") as VBoxContainer
	detail_lazy_last_scroll = float(refs.get("lazy_last_scroll", -1.0))
	call_deferred("_sync_detail_actions_scroll_limit_deferred")


func _sync_skill_strip_page_visibility(include_neighbors := false) -> void:
	if skill_strip_ids.is_empty():
		return
	var current_idx := skill_strip_index
	var count := skill_strip_ids.size()
	if current_idx < 0 or count <= 0:
		return
	for i in count:
		var k := str(skill_strip_ids[i])
		var k_page := (skill_strip_refs.get(k, {}) as Dictionary).get("page") as Control
		if k_page == null or not is_instance_valid(k_page):
			continue
		var dist := mini(absi(i - current_idx), count - absi(i - current_idx))
		var should_show := dist == 0 or (include_neighbors and dist <= 1)
		k_page.visible = should_show
		k_page.process_mode = Node.PROCESS_MODE_INHERIT if dist == 0 else Node.PROCESS_MODE_DISABLED
		if not should_show:
			_set_skill_swipe_control_alpha(k_page, 1.0)


func _skill_detail_needs_action_list_refresh() -> bool:
	if screen_render_in_progress:
		return false
	if boot_detail_render_in_progress or boot_detail_scroll_locked or not boot_detail_render_queue.is_empty():
		return false
	if current_screen != "skill":
		return false
	if _skill_swipe_navigation_blocks_detail_refresh():
		return false
	if Time.get_ticks_msec() < skill_detail_layout_refresh_hold_until_msec:
		return false
	if _pending_activity_has_readiness_for_skill(selected_skill_id) or activity_unlock_ceremony_count > 0:
		return false
	if (
		not _fishing_rework_active_for_skill(selected_skill_id)
		and detail_lazy_plan.size() > 0
		and not _skill_detail_surface()._detail_lazy_all_mounted()
	):
		return false
	var expected_action_ids := []
	if _fishing_rework_active_for_skill(selected_skill_id):
		expected_action_ids = _fishing_ui_surface()._fishing_detail_render_signature()
	else:
		for entry in _visible_detail_entries_for_skill(selected_skill_id):
			var entry_data := entry as Dictionary
			if str(entry_data.get("kind", "")) == "thieving_heist":
				expected_action_ids.append("heist:%s" % str((entry_data.get("heist", {}) as Dictionary).get("id", "")))
			else:
				expected_action_ids.append(str((entry_data.get("action", {}) as Dictionary).get("id", "")))
	if expected_action_ids.size() != detail_rendered_action_ids.size():
		return true
	for i in range(expected_action_ids.size()):
		if str(expected_action_ids[i]) != str(detail_rendered_action_ids[i]):
			return true
	if _fishing_rework_active_for_skill(selected_skill_id):
		for raw_key in action_cards.keys():
			if not str(raw_key).begins_with("fishing:"):
				continue
			var card := action_cards[raw_key] as Dictionary
			if card == null:
				continue
			if card.get("is_fishing_area") and not card.get("uses_static_background_only", false) and card.get("fluid_strip") == null:
				return true
	else:
		var stack := _detail_actions_stack()
		if stack == null or not is_instance_valid(stack) or not _skill_detail_stack_has_visible_modules(stack):
			return true
		for raw_track_id in expected_action_ids:
			var track_id := str(raw_track_id)
			if track_id.is_empty():
				continue
			var node := _valid_control_ref(detail_action_card_nodes.get(track_id))
			if node == null or not node.is_inside_tree():
				if not track_id.begins_with("heist:") and _remount_detail_lazy_action_card(track_id, selected_skill_id):
					continue
				return true
			var card_key := _thieving_surface()._thieving_heist_card_key(track_id.substr("heist:".length())) if track_id.begins_with("heist:") else _action_key(selected_skill_id, track_id)
			if not action_cards.has(card_key):
				if not track_id.begins_with("heist:"):
					if _repair_detail_lazy_action_card_registration(track_id, selected_skill_id):
						continue
					if _remount_detail_lazy_action_card(track_id, selected_skill_id):
						continue
				return true
	return false


func _latest_unlocked_action_id(skill_id: String) -> String:
	var latest_id := ""
	for action in actions_by_skill.get(skill_id, []):
		if _is_action_unlocked(skill_id, action as Dictionary):
			latest_id = str(action["id"])
	return latest_id


func _scroll_to_latest_unlocked_activity(animated := true):
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	var action_id := _latest_unlocked_action_id(selected_skill_id)
	await _scroll_to_activity_card(action_id, animated, false)


func _scroll_to_resume_activity(animated := true) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	if running_skill_id == selected_skill_id and not running_action_id.is_empty():
		await _scroll_to_activity_card(running_action_id, animated, true)
		return
	await _scroll_to_latest_unlocked_activity(animated)


func _request_swipe_resume_scroll() -> void:
	# Swiping between skill detail pages should leave the incoming page at the
	# viewport chosen by the gesture/finalize handoff. Direct navigation paths
	# still opt into resume scrolling through _render_skill_detail.
	skill_swipe_pending_resume_scroll_skill_id = ""


func _apply_pending_swipe_resume_scroll(expected_skill_id: String = "") -> void:
	var target_skill_id := expected_skill_id if not expected_skill_id.is_empty() else skill_swipe_pending_resume_scroll_skill_id
	if target_skill_id.is_empty() or skill_swipe_pending_resume_scroll_skill_id != target_skill_id:
		return
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		call_deferred("_apply_pending_swipe_resume_scroll", target_skill_id)
		return
	skill_swipe_pending_resume_scroll_skill_id = ""
	await _scroll_to_resume_activity(false)


func _scroll_to_activity_card(action_id: String, animated := true, centered := false):
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	if action_id.is_empty():
		return
	_ensure_detail_lazy_entry_mounted(action_id)
	if not detail_action_card_nodes.has(action_id):
		return
	await get_tree().process_frame
	if detail_actions_scroll == null or not detail_action_card_nodes.has(action_id):
		return
	var card := _valid_control_ref(detail_action_card_nodes.get(action_id))
	if card == null or card.is_queued_for_deletion():
		return
	var target := _detail_actions_scroll_target_for_card(card, centered)
	if target < 0:
		return
	detail_actions_scroll.scroll_to_vertical(target, 0.24 if animated else 0.0)


func _detail_actions_scroll_target_for_action(action_id: String, centered := false) -> int:
	if current_screen != "skill" or detail_actions_scroll == null:
		return -1
	if action_id.is_empty():
		return -1
	_ensure_detail_lazy_entry_mounted(action_id)
	if not detail_action_card_nodes.has(action_id):
		return -1
	var card := _valid_control_ref(detail_action_card_nodes.get(action_id))
	if card == null or card.is_queued_for_deletion():
		return -1
	return _detail_actions_scroll_target_for_card(card, centered)


func _detail_actions_scroll_target_for_card(card: Control, centered := false) -> int:
	if card == null or not is_instance_valid(card) or card.is_queued_for_deletion() or detail_actions_scroll == null:
		return -1
	var target_y := card.position.y - 18.0
	if centered:
		var viewport_height := _detail_actions_scroll_viewport_height()
		target_y = card.position.y + card.size.y * 0.5 - viewport_height * 0.5
	_sync_detail_actions_scroll_limit()
	return clampi(int(round(target_y)), 0, detail_actions_scroll.get_max_scroll_vertical())


func _skill_detail_bottom_scroll_pad(skill_id := "") -> float:
	var page_gap := THIEVING_SKILL_DETAIL_BOTTOM_SCROLL_PAD if skill_id == "thieving" else SKILL_DETAIL_BOTTOM_SCROLL_PAD
	var play_area_pad := 1100.0 if skill_id == "fight" else 0.0
	return _skills_content_bottom_inset_for_screen() + float(page_gap) + NavigationShell.PAGE_SWITCH_MODULE_HEIGHT + SKILL_DETAIL_BOTTOM_UI_CLEARANCE + play_area_pad


func _detail_actions_bottom_scroll_pad(skill_id: String) -> float:
	var extra_pad := _detail_unlock_scroll_spacer_height(skill_id)
	if extra_pad > 0.0 and not _detail_unlock_extra_scroll_space_allowed(skill_id):
		extra_pad = 0.0
		detail_unlock_scroll_spacer_heights.erase(skill_id)
	return _skill_detail_bottom_scroll_pad(skill_id) + extra_pad


func _detail_unlock_extra_scroll_space_allowed(skill_id: String) -> bool:
	if current_screen != "skill" or skill_id.is_empty() or skill_id != selected_skill_id:
		return false
	return (
		_pending_activity_has_readiness_for_skill(skill_id)
		or activity_unlock_ceremony_count > 0
		or not activity_unlock_preview_after_ceremony_id.is_empty()
		or not activity_unlock_heist_preview_after_ceremony_id.is_empty()
	)


func _sync_detail_actions_bottom_spacer() -> void:
	if detail_unlock_scroll_spacer == null or not is_instance_valid(detail_unlock_scroll_spacer):
		return
	var height := _detail_actions_bottom_scroll_pad(selected_skill_id)
	var next_visible := height > 1.0
	if (
		absf(detail_unlock_scroll_spacer.custom_minimum_size.y - height) <= 0.5
		and detail_unlock_scroll_spacer.visible == next_visible
	):
		return
	detail_unlock_scroll_spacer.custom_minimum_size = Vector2(0, height)
	detail_unlock_scroll_spacer.visible = next_visible
	detail_unlock_scroll_spacer.update_minimum_size()


func _set_detail_unlock_scroll_spacer_height(height: float) -> void:
	var normalized_height := maxf(0.0, height)
	var current_height := _detail_unlock_scroll_spacer_height(selected_skill_id)
	if absf(current_height - normalized_height) <= 0.5:
		return
	if selected_skill_id.is_empty():
		detail_unlock_scroll_spacer_heights.clear()
	elif normalized_height > 1.0:
		detail_unlock_scroll_spacer_heights[selected_skill_id] = normalized_height
	else:
		detail_unlock_scroll_spacer_heights.erase(selected_skill_id)
	_sync_detail_actions_bottom_spacer()


func _detail_unlock_scroll_spacer_height(skill_id: String) -> float:
	if skill_id.is_empty() or not detail_unlock_scroll_spacer_heights.has(skill_id):
		return 0.0
	return maxf(0.0, float(detail_unlock_scroll_spacer_heights.get(skill_id, 0.0)))


func _sync_detail_actions_scroll_limit_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_sync_detail_actions_scroll_limit()


func _sync_detail_actions_scroll_limit() -> void:
	if current_screen != "skill":
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	_sync_hidden_locked_activity_preview_layouts()
	if boot_detail_scroll_locked:
		detail_actions_scroll.set_max_scroll_override(0)
		detail_actions_scroll.set_scroll_enabled_by_content(false)
		return
	var visible_content := _detail_authoritative_scrollable_module_bottom()
	if int(visible_content.get("count", 0)) <= 0:
		detail_actions_scroll.set_max_scroll_override(-1)
		detail_actions_scroll.set_scroll_enabled_by_content(true)
		return
	var viewport_height := _detail_actions_scroll_viewport_height()
	var real_content_bottom := float(visible_content.get("bottom", 0.0))
	var bottom_gap := maxf(0.0, _skill_detail_bottom_scroll_pad(selected_skill_id) - _skills_content_bottom_inset_for_screen())
	if int(visible_content.get("count", 0)) <= 1 and _detail_has_hidden_locked_activity_preview():
		bottom_gap = 0.0
	elif _detail_stack_page_switch_bottom() >= 0.0:
		var page_gap := THIEVING_SKILL_DETAIL_BOTTOM_SCROLL_PAD if selected_skill_id == "thieving" else SKILL_DETAIL_BOTTOM_SCROLL_PAD
		bottom_gap = maxf(0.0, bottom_gap - float(page_gap) - 12.0)
	var max_scroll_to_content := maxi(0, int(ceil(real_content_bottom + bottom_gap - viewport_height)))
	detail_actions_scroll.set_max_scroll_override(max_scroll_to_content)
	detail_actions_scroll.set_scroll_enabled_by_content(true)
	if detail_actions_scroll.scroll_vertical > detail_actions_scroll.get_max_scroll_vertical():
		var clamped_scroll := detail_actions_scroll.get_max_scroll_vertical()
		detail_actions_scroll.drag_scroll_position = float(clamped_scroll)
		detail_actions_scroll.scroll_vertical = clamped_scroll


func _detail_actions_scroll_viewport_height() -> float:
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return 0.0
	var viewport_height := detail_actions_scroll.size.y
	if viewport_height <= 1.0:
		viewport_height = detail_actions_scroll.custom_minimum_size.y
	var obscured_bottom := _skills_content_bottom_inset_for_screen()
	if viewport_height > obscured_bottom + 1.0:
		viewport_height -= obscured_bottom
	if viewport_height <= 1.0:
		viewport_height = _current_canvas_size().y - SKILL_DETAIL_HEADER_HEIGHT - SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT - _bottom_ui_reserved_height_for_current_screen()
	return maxf(1.0, viewport_height)


func _detail_stack_page_switch_bottom() -> float:
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return -1.0
	for child in stack.get_children():
		var control := child as Control
		if control == null or not is_instance_valid(control):
			continue
		if control.name == "PageSwitchModule":
			return _detail_control_bottom_in_stack(control, stack)
	return -1.0


func _detail_authoritative_scrollable_module_bottom() -> Dictionary:
	var stack_bottom := _detail_stack_module_content_bottom()
	if detail_lazy_plan.is_empty() or _skill_detail_surface()._detail_lazy_all_mounted():
		if int(stack_bottom.get("count", 0)) > 0:
			return stack_bottom
	var lazy_bottom := _detail_lazy_plan_module_content_bottom()
	if int(lazy_bottom.get("count", 0)) > 0:
		if int(stack_bottom.get("count", 0)) > 0:
			return {
				"bottom": maxf(float(lazy_bottom.get("bottom", 0.0)), float(stack_bottom.get("bottom", 0.0))),
				"count": int(lazy_bottom.get("count", 0)) + int(stack_bottom.get("count", 0))
			}
		return lazy_bottom
	if int(stack_bottom.get("count", 0)) > 0:
		return stack_bottom
	var registry_bottom := _detail_actions_scrollable_content_bottom()
	if int(registry_bottom.get("count", 0)) > 0:
		return registry_bottom
	return {"bottom": 0.0, "count": 0}


func _detail_has_hidden_locked_activity_preview() -> bool:
	if action_cards.is_empty():
		return false
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if bool(card.get("locked_preview_hidden", false)):
			return true
	return false


func _detail_lazy_plan_module_content_bottom() -> Dictionary:
	if detail_lazy_plan.is_empty():
		return {"bottom": 0.0, "count": 0}
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return {"bottom": 0.0, "count": 0}
	var bottom := 0.0
	var count := 0
	var top_spacer_height := _detail_actions_top_spacer_height()
	var stack_separation := float(stack.get_theme_constant("separation"))
	for raw_lazy_entry in detail_lazy_plan:
		var lazy_entry := raw_lazy_entry as Dictionary
		var kind := str(lazy_entry.get("kind", ""))
		if not _detail_lazy_kind_is_module(kind):
			continue
		var action_key := _action_key(selected_skill_id, str(lazy_entry.get("track_id", "")))
		var action_card := action_cards.get(action_key, {}) as Dictionary
		if bool(action_card.get("locked_preview_hidden", false)):
			continue
		var host := _valid_control_ref(lazy_entry.get("stack_host"))
		var host_bottom := -1.0
		if host != null and is_instance_valid(host):
			host_bottom = _detail_control_bottom_in_stack(host, stack)
		if host != null and host_bottom < 0.0:
			continue
		if host_bottom < 0.0:
			host_bottom = top_spacer_height + stack_separation + float(lazy_entry.get("y", 0.0)) + float(lazy_entry.get("height", _activity_card_root_height()))
		if host_bottom > 1.0:
			bottom = maxf(bottom, host_bottom)
			count += 1
	if count <= 0:
		return {"bottom": 0.0, "count": 0}
	return {"bottom": bottom, "count": count}


func _detail_stack_module_content_bottom() -> Dictionary:
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return {"bottom": 0.0, "count": 0}
	var bottom := 0.0
	var count := 0
	for child in stack.get_children():
		var control := child as Control
		if control == null or not is_instance_valid(control):
			continue
		if not _detail_stack_child_is_module_content(control):
			continue
		var child_bottom := _detail_control_bottom_in_stack(control, stack)
		if child_bottom < 0.0:
			continue
		bottom = maxf(bottom, child_bottom)
		count += 1
	if count <= 0:
		return {"bottom": 0.0, "count": 0}
	return {"bottom": bottom, "count": count}


func _detail_actions_top_spacer_height() -> float:
	if detail_actions_top_spacer != null and is_instance_valid(detail_actions_top_spacer):
		return maxf(detail_actions_top_spacer.size.y, detail_actions_top_spacer.custom_minimum_size.y)
	return float(SKILL_DETAIL_ACTIONS_TOP_SPACER_HEIGHT)


func _detail_stack_child_is_module_content(control: Control) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if control.name == "DetailActionsTopSpacer" or control.name == "DetailActionsBottomSpacer" or control.name == "PageSwitchModule":
		return false
	if not control.visible or control.is_queued_for_deletion() or control.modulate.a <= 0.01:
		return false
	if bool(control.get_meta("detail_lazy_placeholder", false)):
		return false
	if bool(control.get_meta("skill_swipe_preview_placeholder", false)):
		return false
	if _detail_control_has_any_group(control, ["activity_start_tip_notes", "skill_swipe_tip_notes", "onboarding_explore_tip_notes", "lock_click_tip_notes"]):
		return false
	if bool(control.get_meta("detail_stack_entry_wrapper", false)) and not _detail_lazy_slot_has_real_content(control):
		return false
	var height := maxf(control.size.y, control.custom_minimum_size.y)
	return height > 1.0


func _detail_control_has_any_group(control: Control, group_names: Array) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	for raw_group in group_names:
		if control.is_in_group(str(raw_group)):
			return true
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null and _detail_control_has_any_group(child, group_names):
			return true
	return false


func _detail_actions_scrollable_content_bottom() -> Dictionary:
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return {"bottom": 0.0, "count": 0}
	var bottom := 0.0
	var count := 0
	var measured_nodes := {}
	for raw_action_id in detail_rendered_action_ids:
		var action_id := str(raw_action_id)
		if not detail_action_card_nodes.has(action_id):
			continue
		var node := _valid_control_ref(detail_action_card_nodes.get(action_id))
		if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var node_id := node.get_instance_id()
		if measured_nodes.has(node_id):
			continue
		measured_nodes[node_id] = true
		var node_bottom := _detail_card_node_bottom_in_stack(node, stack)
		if node_bottom < 0.0:
			continue
		bottom = maxf(bottom, node_bottom)
		count += 1
	for raw_node in detail_action_card_nodes.values():
		var extra_node := _valid_control_ref(raw_node)
		if extra_node == null or not is_instance_valid(extra_node) or extra_node.is_queued_for_deletion():
			continue
		var extra_node_id := extra_node.get_instance_id()
		if measured_nodes.has(extra_node_id):
			continue
		measured_nodes[extra_node_id] = true
		var node_bottom := _detail_card_node_bottom_in_stack(extra_node, stack)
		if node_bottom < 0.0:
			continue
		bottom = maxf(bottom, node_bottom)
		count += 1
	if _detail_unlock_extra_scroll_space_allowed(selected_skill_id):
		var spacer_bottom := _detail_unlock_scroll_spacer_bottom_in_stack(stack)
		if spacer_bottom >= 0.0:
			bottom = maxf(bottom, spacer_bottom)
	if count > 0:
		return {"bottom": bottom, "count": count}
	return {"bottom": 0.0, "count": 0}


func _detail_card_node_bottom_in_stack(node: Control, stack: Control) -> float:
	var stack_child := _detail_stack_child_for_control(node, stack)
	if stack_child == null:
		return -1.0
	if bool(stack_child.get_meta("detail_stack_entry_wrapper", false)):
		var content_bottom := _detail_slot_content_bottom_in_stack(stack_child, stack)
		if content_bottom >= 0.0:
			return content_bottom
	return _detail_control_bottom_in_stack(node, stack)


func _detail_slot_content_bottom_in_stack(slot: Control, stack: Control) -> float:
	if slot == null or stack == null or not is_instance_valid(slot) or not is_instance_valid(stack):
		return -1.0
	if slot.name == "DetailActionsTopSpacer" or slot.name == "DetailActionsBottomSpacer":
		return -1.0
	if bool(slot.get_meta("detail_lazy_placeholder", false)):
		return -1.0
	var bottom := -1.0
	for raw_child in slot.get_children():
		var child := raw_child as Control
		if child == null or not is_instance_valid(child):
			continue
		if not child.visible or child.is_queued_for_deletion():
			continue
		if bool(child.get_meta("detail_lazy_placeholder", false)):
			continue
		var child_bottom := _detail_control_bottom_in_stack(child, stack)
		if child_bottom >= 0.0:
			bottom = maxf(bottom, child_bottom)
	if bottom >= 0.0:
		return bottom
	return _detail_control_bottom_in_stack(slot, stack)


func _detail_control_bottom_in_stack(control: Control, stack: Control) -> float:
	if control == null or stack == null or not is_instance_valid(control) or not is_instance_valid(stack):
		return -1.0
	if not control.visible or control.is_queued_for_deletion():
		return -1.0
	var rect := _detail_control_rect_in_stack(control, stack)
	if rect.size.y <= 1.0:
		return -1.0
	return rect.position.y + rect.size.y


func _detail_control_rect_in_stack(control: Control, stack: Control) -> Rect2:
	var size_for_rect := control.size
	if size_for_rect.y <= 1.0:
		size_for_rect.y = control.custom_minimum_size.y
	if size_for_rect.x <= 1.0:
		size_for_rect.x = control.custom_minimum_size.x
	var position_in_stack := control.position
	var parent := control.get_parent() as Control
	while parent != null and is_instance_valid(parent):
		if parent == stack:
			return Rect2(position_in_stack, size_for_rect)
		position_in_stack += parent.position
		parent = parent.get_parent() as Control
	return Rect2(Vector2.ZERO, Vector2.ZERO)


func _detail_unlock_scroll_spacer_bottom_in_stack(stack: Control) -> float:
	if detail_unlock_scroll_spacer == null or not is_instance_valid(detail_unlock_scroll_spacer):
		return -1.0
	if not detail_unlock_scroll_spacer.visible:
		return -1.0
	var height := maxf(detail_unlock_scroll_spacer.size.y, detail_unlock_scroll_spacer.custom_minimum_size.y)
	if height <= 1.0:
		return -1.0
	return _detail_control_bottom_in_stack(detail_unlock_scroll_spacer, stack)


func _detail_stack_child_for_control(control: Control, stack: Control) -> Control:
	if control == null or stack == null or not is_instance_valid(control) or not is_instance_valid(stack):
		return null
	if control.get_parent() == stack:
		return control
	var parent := control.get_parent() as Control
	while parent != null and is_instance_valid(parent):
		if parent.get_parent() == stack:
			return parent
		parent = parent.get_parent() as Control
	return null


func _release_detail_unlock_extra_scroll_space() -> void:
	if detail_unlock_scroll_spacer == null or not is_instance_valid(detail_unlock_scroll_spacer):
		return
	if detail_unlock_scroll_spacer_tween != null and detail_unlock_scroll_spacer_tween.is_valid():
		detail_unlock_scroll_spacer_tween.kill()
	var base_pad := _skill_detail_bottom_scroll_pad(selected_skill_id)
	var start_height := maxf(detail_unlock_scroll_spacer.custom_minimum_size.y, _detail_actions_bottom_scroll_pad(selected_skill_id))
	var start_extra := maxf(0.0, start_height - base_pad)
	if start_extra <= 1.0:
		_set_detail_unlock_scroll_spacer_height(0.0)
		return
	detail_unlock_scroll_spacer_tween = create_tween()
	detail_unlock_scroll_spacer_tween.tween_interval(ACTIVITY_UNLOCK_SPACER_SETTLE_SECONDS)
	detail_unlock_scroll_spacer_tween.finished.connect(_finish_detail_unlock_scroll_spacer_tween)


func _finish_detail_unlock_scroll_spacer_tween() -> void:
	_set_detail_unlock_scroll_spacer_height(0.0)
	detail_unlock_auto_scroll_interrupted = false
	detail_unlock_scroll_spacer_tween = null


func _clamp_detail_actions_scroll_to_content() -> void:
	if current_screen != "skill":
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	var max_scroll := detail_actions_scroll.get_max_scroll_vertical()
	if detail_actions_scroll.scroll_vertical <= max_scroll:
		detail_actions_scroll.drag_scroll_position = float(detail_actions_scroll.scroll_vertical)
		return
	detail_actions_scroll.drag_scroll_position = float(max_scroll)
	detail_actions_scroll.scroll_vertical = max_scroll


func _clamp_detail_actions_scroll_to_content_deferred() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_clamp_detail_actions_scroll_to_content()


func _detail_actions_stack() -> Control:
	if detail_actions_scroll == null or detail_actions_scroll.get_child_count() <= 0:
		return null
	return detail_actions_scroll.get_child(0) as Control


func _clear_activity_unlock_visual_scroll_tween() -> void:
	if activity_unlock_visual_scroll_tween != null and activity_unlock_visual_scroll_tween.is_valid():
		activity_unlock_visual_scroll_tween.kill()
	activity_unlock_visual_scroll_tween = null


func _restore_detail_actions_scroll(target: int) -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	await get_tree().process_frame
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		return
	if detail_actions_scroll == null:
		return
	_sync_detail_actions_scroll_limit()
	detail_actions_scroll.scroll_to_vertical(mini(target, detail_actions_scroll.get_max_scroll_vertical()), 0.0)
	await get_tree().process_frame
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		return
	if detail_actions_scroll != null:
		_sync_detail_actions_scroll_limit()
		detail_actions_scroll.scroll_to_vertical(mini(target, detail_actions_scroll.get_max_scroll_vertical()), 0.0)
	_clear_skill_swipe_handoff_cover()


func _scroll_detail_actions_to_bottom_after_layout() -> void:
	if current_screen != "skill" or detail_actions_scroll == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if current_screen != "skill" or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	_sync_detail_actions_scroll_limit()
	var max_scroll := detail_actions_scroll.get_max_scroll_vertical()
	detail_actions_scroll.drag_scroll_position = float(max_scroll)
	detail_actions_scroll.scroll_vertical = max_scroll
	detail_actions_scroll.scroll_to_vertical(max_scroll, 0.0)
	if _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_detail_reveal_mount_under_cover()
		_navigation_shell()._fade_clear_page_switch_scroll_cover()
	elif _skill_swipe_handoff_cover_is_opaque_cream_transition():
		_force_skill_detail_reveal_mount_under_cover()
		_fade_clear_skill_swipe_rebuild_cover()
	else:
		_clear_skill_swipe_handoff_cover()


func _update_skill_swipe_feedback(pointer_position: Vector2) -> void:
	if _onboarding_runtime()._onboarding_blocks_skill_swipe():
		if not _onboarding_runtime()._ensure_onboarding_swipe_unlocked(true):
			skill_swipe_tracking = false
			skill_swipe_touch_index = -1
			skill_swipe_horizontal = false
			return
	skill_swipe_last = pointer_position
	var delta := pointer_position - skill_swipe_start
	var abs_x := absf(delta.x)
	var abs_y := absf(delta.y)
	if _skill_swipe_animation_blocks_input():
		if not skill_swipe_horizontal:
			if abs_y >= SKILL_SWIPE_FEEDBACK_DEADZONE and abs_y > abs_x * 1.15:
				skill_swipe_tracking = false
				skill_swipe_touch_index = -1
				return
			if abs_x < 6.0:
				return
			if abs_x < abs_y * 1.25:
				return
			skill_swipe_horizontal = true
		if skill_swipe_horizontal:
			_suppress_skill_swipe_action_click()
		return
	if not skill_swipe_horizontal:
		if abs_y >= SKILL_SWIPE_FEEDBACK_DEADZONE and abs_y > abs_x * 1.15:
			skill_swipe_tracking = false
			skill_swipe_touch_index = -1
			return
		if abs_x < 6.0:
			return
		if abs_x < abs_y * 1.25:
			return
		skill_swipe_horizontal = true
		return
	if skill_swipe_horizontal:
		_suppress_skill_swipe_action_click()
	if not skill_strip_ids.is_empty():
		var strip_direction := 1.0 if delta.x > 0.0 else -1.0
		var strip_visual_distance := _skill_swipe_visual_distance(abs_x)
		var skill_count := skill_strip_ids.size()
		var page_width := _skill_content_width()
		if strip_direction > 0.0 and skill_strip_index == 0 and _onboarding_runtime()._swipe_offset_accessible(-1):
			_set_skill_strip_page_virtual_pos(str(skill_strip_ids[skill_count - 1]), -page_width)
		elif strip_direction < 0.0 and skill_strip_index == skill_count - 1 and _onboarding_runtime()._swipe_offset_accessible(1):
			_set_skill_strip_page_virtual_pos(str(skill_strip_ids[0]), float(skill_count) * page_width)
		else:
			_restore_skill_strip_wrap_page()
		_apply_skill_swipe_drag_offset(skill_swipe_drag_base_x + strip_direction * strip_visual_distance)
		return
	var target := _skill_swipe_visual_target()
	if target == null:
		return
	var offset := 1 if delta.x < 0.0 else -1
	if not _onboarding_runtime()._swipe_offset_accessible(offset):
		_skill_swipe_activity_surface()._park_skill_swipe_preview()
	var page_direction := 1.0 if delta.x > 0.0 else -1.0
	var page_visual_distance := _skill_swipe_visual_distance(abs_x)
	_skill_swipe_activity_surface()._set_skill_swipe_positions(offset, skill_swipe_drag_base_x + page_direction * page_visual_distance)
	_sync_skill_page_switch_modules_for_drag(abs_x)
	_sync_skill_swipe_module_utility_row_for_drag(abs_x)


func _skill_swipe_visual_target() -> Control:
	if skill_swipe_frame != null and is_instance_valid(skill_swipe_frame):
		return skill_swipe_frame
	return null


func _skill_swipe_visual_distance(abs_x: float) -> float:
	return clampf(abs_x, 0.0, _skill_swipe_page_span())


func _skill_swipe_page_span() -> float:
	var active_width := _skill_content_width()
	return active_width + SKILL_SWIPE_PAGE_GAP


func _current_skill_swipe_page_x() -> float:
	return skill_swipe_drag_offset_x


func _kill_skill_swipe_tween() -> void:
	if skill_swipe_tween != null and skill_swipe_tween.is_valid():
		skill_swipe_tween.kill()
	skill_swipe_tween = null
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""


func _clear_queued_skill_swipe_navigation() -> void:
	skill_swipe_queued_offset = 0


func _skill_swipe_animation_blocks_input() -> bool:
	return skill_swipe_pending_full_finalize or (
		skill_swipe_animating
		and (skill_swipe_animation_mode == "entry" or skill_swipe_animation_mode == "cancel")
	)


func _interrupt_skill_swipe_animation_for_input() -> void:
	if not skill_swipe_animating:
		return
	if _skill_swipe_animation_blocks_input():
		return
	var mode := skill_swipe_animation_mode
	var offset := _skill_swipe_activity_surface()._active_preview_offset()
	var preview_page := _skill_swipe_activity_surface()._active_preview_page()
	if mode == "settle" and offset != 0 and preview_page != null:
		_kill_skill_swipe_tween()
		_navigate_skill_page(offset, 0.0, false, false)
		return
	_kill_skill_swipe_tween()


func _apply_skill_page_cover_bounds(cover: Control, include_bottom_interactive_ui := false) -> void:
	if cover == null or not is_instance_valid(cover):
		return
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.offset_left = 0.0
	cover.offset_top = 0.0
	cover.offset_right = 0.0
	cover.offset_bottom = _skill_page_cover_bottom_offset(include_bottom_interactive_ui)


func _skill_page_cover_bottom_offset(include_bottom_interactive_ui := false) -> float:
	if include_bottom_interactive_ui or _profile_chat_overlay_surface()._chat_strip_visible_on_current_screen():
		return _global_chat_nav_cover_bottom_offset()
	if skills_page == null or not is_instance_valid(skills_page):
		return -_skills_content_bottom_inset_for_screen()
	var page_rect: Rect2 = skills_page.get_global_rect()
	var cover_bottom_y: float = page_rect.end.y - _skills_content_bottom_inset_for_screen()
	for raw_control in [chat_strip, nav_bar]:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control) or not control.visible:
			continue
		var rect: Rect2 = control.get_global_rect()
		if rect.size.y <= 1.0:
			continue
		cover_bottom_y = minf(cover_bottom_y, rect.position.y)
	return minf(0.0, cover_bottom_y - page_rect.end.y)


func _global_chat_nav_cover_bottom_offset() -> float:
	var viewport_bottom := _current_canvas_size().y
	var cover_bottom_y := viewport_bottom
	for raw_control in [chat_strip, nav_bar]:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control) or not control.visible:
			continue
		var rect: Rect2 = control.get_global_rect()
		if rect.size.y <= 1.0:
			continue
		cover_bottom_y = minf(cover_bottom_y, rect.position.y)
	if cover_bottom_y >= viewport_bottom - 1.0:
		cover_bottom_y = maxf(0.0, viewport_bottom - float(BOTTOM_NAV_HEIGHT))
	return minf(0.0, cover_bottom_y - viewport_bottom)


func _begin_skill_swipe_handoff_cover() -> void:
	_clear_skill_swipe_handoff_cover()
	if skills_page == null or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return
	var page := _skill_swipe_activity_surface()._active_preview_page()
	if page == null:
		return
	_skill_swipe_activity_surface()._take_preview_for_handoff(false)

	var cover := Control.new()
	_apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.z_index = -1
	cover.add_child(backing)
	if module_ui_pin_refresh_cover_requested or not module_ui_pending_pin_scroll_anchor.is_empty():
		cover.set_meta("module_pin_refresh_opaque_cover", true)
		skill_swipe_handoff_cover = cover
		skill_detail_refresh_cover_active = true
		return
	_skill_swipe_activity_surface()._set_active_preview(null, 0)

	var holder := Control.new()
	holder.position = skill_swipe_frame.global_position
	holder.size = skill_swipe_frame.size
	holder.custom_minimum_size = skill_swipe_frame.size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(holder)
	page.reparent(holder)
	page.position = Vector2.ZERO
	page.z_index = 0
	_add_skill_detail_shadow_overlay_to(cover, SKILLS_PAGE_TOP_PAD + _skill_detail_shadow_top_y(), detail_shelf_shadow_alpha)

	skill_swipe_handoff_cover = cover


func _clear_skill_swipe_handoff_cover() -> void:
	if _navigation_shell()._page_switch_scroll_cover_active() and _navigation_shell()._page_switch_render_cover_transition_waiting():
		return
	var was_page_switch_cover := _navigation_shell()._page_switch_scroll_cover_active()
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		if (
			skill_detail_refresh_cover_active
			and skill_swipe_handoff_cover != null
			and is_instance_valid(skill_swipe_handoff_cover)
		):
			return
	_kill_skill_swipe_cover_fade_tween()
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		skill_swipe_handoff_cover.queue_free()
	skill_swipe_handoff_cover = null
	skill_detail_refresh_cover_active = false
	direct_skill_nav_cover_active = false
	skill_swipe_outgoing_cover_active = false
	skill_swipe_rebuild_cover_active = false
	_navigation_shell()._clear_page_switch_render_cover_transition_state()
	if was_page_switch_cover:
		_navigation_shell()._release_page_switch_transition_button()


func _clear_skill_swipe_handoff_cover_immediate() -> void:
	if _navigation_shell()._page_switch_scroll_cover_active() and _navigation_shell()._page_switch_render_cover_transition_waiting():
		return
	var was_page_switch_cover := _navigation_shell()._page_switch_scroll_cover_active()
	if not module_ui_pending_pin_scroll_anchor.is_empty():
		if (
			skill_detail_refresh_cover_active
			and skill_swipe_handoff_cover != null
			and is_instance_valid(skill_swipe_handoff_cover)
		):
			return
	_kill_skill_swipe_cover_fade_tween()
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		skill_swipe_handoff_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_canvas_item_visible_if_changed(skill_swipe_handoff_cover, false)
		skill_swipe_handoff_cover.free()
	skill_swipe_handoff_cover = null
	skill_detail_refresh_cover_active = false
	direct_skill_nav_cover_active = false
	skill_swipe_outgoing_cover_active = false
	skill_swipe_rebuild_cover_active = false
	_navigation_shell()._clear_page_switch_render_cover_transition_state()
	if was_page_switch_cover:
		_navigation_shell()._release_page_switch_transition_button()


func _kill_skill_swipe_cover_fade_tween() -> void:
	if skill_swipe_cover_fade_tween != null and skill_swipe_cover_fade_tween.is_valid():
		skill_swipe_cover_fade_tween.kill()
	skill_swipe_cover_fade_tween = null


func _force_skill_swipe_cover_opaque_cream() -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	cover.set_meta("swipe_cream_transition_cover", true)
	skill_swipe_outgoing_cover_active = true


func _hold_skill_swipe_cover_for_pending_finalize() -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return
	_force_skill_swipe_cover_opaque_cream()
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	skill_swipe_rebuild_cover_active = false


func _maybe_release_ready_skill_swipe_cover() -> void:
	if current_screen != "skill" or skill_swipe_pending_full_finalize:
		return
	if skill_swipe_cover_fade_tween != null and skill_swipe_cover_fade_tween.is_valid():
		return
	if not _skill_swipe_handoff_cover_is_opaque_cream_transition():
		return
	if detail_lazy_plan.is_empty() or action_cards.is_empty():
		return
	_sync_detail_actions_scroll_limit()
	if not _skill_detail_ready_to_reveal_under_cover():
		return
	skill_swipe_outgoing_cover_active = true
	_fade_clear_skill_swipe_cover(SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS)


func _cancel_skill_swipe_finalize_for_navigation() -> void:
	skill_swipe_pending_full_finalize = false
	skill_swipe_pending_preview_state = {}
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""


func _begin_skill_detail_refresh_cover() -> void:
	if _skill_swipe_navigation_blocks_detail_refresh():
		return
	if (
		skill_detail_refresh_cover_active
		and skill_swipe_handoff_cover != null
		and is_instance_valid(skill_swipe_handoff_cover)
	):
		return
	_clear_skill_swipe_handoff_cover()
	if skills_page == null or not is_instance_valid(skills_page):
		return
	var opaque_pin_refresh := module_ui_pin_refresh_cover_requested or not module_ui_pending_pin_scroll_anchor.is_empty()
	var old_page := skill_swipe_frame
	if old_page == null or not is_instance_valid(old_page):
		if skills_content != null and is_instance_valid(skills_content) and skills_content.get_child_count() > 0:
			old_page = skills_content.get_child(0) as Control
	if not opaque_pin_refresh and (old_page == null or not is_instance_valid(old_page)):
		return
	var cover := Control.new()
	_apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.z_index = -1
	cover.add_child(backing)
	if opaque_pin_refresh:
		cover.set_meta("module_pin_refresh_opaque_cover", true)
		skill_swipe_handoff_cover = cover
		skill_detail_refresh_cover_active = true
		return

	var holder := Control.new()
	holder.position = old_page.global_position
	holder.size = old_page.size
	holder.custom_minimum_size = old_page.size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(holder)
	old_page.reparent(holder)
	old_page.z_index = 0
	_add_skill_detail_shadow_overlay_to(cover, SKILLS_PAGE_TOP_PAD + _skill_detail_shadow_top_y(), detail_shelf_shadow_alpha)
	skill_swipe_handoff_cover = cover
	skill_detail_refresh_cover_active = true


func _begin_direct_skill_nav_cover() -> void:
	if _skill_swipe_handoff_cover_is_opaque_cream_transition():
		direct_skill_nav_cover_active = true
		return
	_clear_skill_swipe_handoff_cover_immediate()
	var cover := Control.new()
	_apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	cover.modulate = Color(1.0, 1.0, 1.0, 0.0)
	cover.set_meta("swipe_cream_transition_cover", true)
	cover.set_meta("direct_skill_nav_cover", true)
	cover.set_meta("direct_skill_nav_cover_started_msec", Time.get_ticks_msec())
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.add_child(backing)

	skill_swipe_handoff_cover = cover
	direct_skill_nav_cover_active = true
	_start_skill_nav_cover_fade_in(cover)


func _ensure_skill_nav_cover_layer() -> CanvasLayer:
	if skill_nav_cover_layer == null or not is_instance_valid(skill_nav_cover_layer):
		skill_nav_cover_layer = CanvasLayer.new()
		skill_nav_cover_layer.name = "SkillNavCoverLayer"
		skill_nav_cover_layer.layer = SKILL_NAV_COVER_CANVAS_LAYER
		add_child(skill_nav_cover_layer)
	return skill_nav_cover_layer


func _process_pin_transition_blocker() -> void:
	if pin_transition_blocker == null or not is_instance_valid(pin_transition_blocker):
		return
	if not pin_transition_blocker.visible or pin_transition_blocker_release_started:
		return
	pin_transition_blocker.offset_bottom = _global_chat_nav_cover_bottom_offset()
	if not pin_transition_blocker_fade_in_done:
		return
	var elapsed_seconds := float(maxi(0, Time.get_ticks_msec() - pin_transition_blocker_started_msec)) / 1000.0
	if elapsed_seconds < PIN_TRANSITION_BLOCKER_MIN_SECONDS:
		return
	if not _pin_transition_blocker_target_ready():
		return
	pin_transition_blocker_release_started = true
	if pin_transition_blocker_tween != null and pin_transition_blocker_tween.is_valid():
		pin_transition_blocker_tween.kill()
	pin_transition_blocker_tween = create_tween()
	pin_transition_blocker_tween.tween_property(
		pin_transition_blocker,
		"modulate:a",
		0.0,
		PIN_TRANSITION_BLOCKER_FADE_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pin_transition_blocker_tween.tween_callback(_finish_pin_transition_blocker_fade)


func _pin_transition_blocker_target_ready() -> bool:
	if screen_render_in_progress:
		return false
	if not pending_screen_render_request.is_empty():
		return false
	if pin_transition_blocker_target_screen == "pinned":
		return current_screen == "pinned" and _pinned_page_ready_to_reveal_under_cover()
	if pin_transition_blocker_target_screen == "skill":
		return (
			current_screen == "skill"
			and detail_actions_scroll != null
			and is_instance_valid(detail_actions_scroll)
			and detail_actions_scroll.is_inside_tree()
			and detail_lazy_stack != null
			and is_instance_valid(detail_lazy_stack)
		)
	return current_screen == pin_transition_blocker_target_screen


func _finish_pin_transition_blocker_fade() -> void:
	pin_transition_blocker_tween = null
	if pin_transition_blocker != null and is_instance_valid(pin_transition_blocker):
		pin_transition_blocker.visible = false
		pin_transition_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin_transition_blocker_target_screen = ""
	pin_transition_blocker_release_started = false
	pin_transition_blocker_fade_in_done = false


func _start_skill_nav_cover_fade_in(cover: Control) -> void:
	if cover == null or not is_instance_valid(cover):
		return
	_kill_skill_swipe_cover_fade_tween()
	skill_swipe_cover_fade_tween = create_tween()
	skill_swipe_cover_fade_tween.tween_property(
		cover,
		"modulate:a",
		1.0,
		DIRECT_SKILL_NAV_COVER_FADE_IN_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	skill_swipe_cover_fade_tween.tween_callback(_finish_skill_nav_cover_fade_in.bind(cover.get_instance_id()))


func _finish_skill_nav_cover_fade_in(cover_id: int) -> void:
	if skill_swipe_cover_fade_tween != null and not skill_swipe_cover_fade_tween.is_valid():
		skill_swipe_cover_fade_tween = null
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		return
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)


func _fade_clear_direct_skill_nav_cover() -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover) or not bool(cover.get_meta("direct_skill_nav_cover", false)):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	if bool(cover.get_meta("direct_skill_nav_cover_release_pending", false)):
		return
	var started_msec := int(cover.get_meta("direct_skill_nav_cover_started_msec", Time.get_ticks_msec()))
	var elapsed_seconds := float(maxi(0, Time.get_ticks_msec() - started_msec)) / 1000.0
	var remaining_seconds := DIRECT_SKILL_NAV_COVER_MIN_SECONDS - elapsed_seconds
	if remaining_seconds > 0.0:
		cover.set_meta("direct_skill_nav_cover_release_pending", true)
		call_deferred("_fade_clear_direct_skill_nav_cover_after_delay", remaining_seconds)
		return
	_fade_clear_skill_swipe_cover(DIRECT_SKILL_NAV_COVER_FADE_SECONDS)


func _fade_clear_direct_skill_nav_cover_after_delay(delay_seconds: float) -> void:
	await get_tree().create_timer(maxf(0.01, delay_seconds), true, false, true).timeout
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover) or not bool(cover.get_meta("direct_skill_nav_cover", false)):
		return
	cover.remove_meta("direct_skill_nav_cover_release_pending")
	_fade_clear_direct_skill_nav_cover()


func _begin_skill_swipe_outgoing_cover() -> Control:
	_clear_skill_swipe_handoff_cover()
	if skills_page == null or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		return null

	var cover := Control.new()
	_apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	cover.modulate = Color.WHITE
	cover.set_meta("swipe_cream_transition_cover", true)
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_COVER") == "1":
		print("SWIPE_COVER_TRACE begin_outgoing selected=%s alpha=%.3f ready=%s placeholders=%s" % [
			selected_skill_id,
			cover.modulate.a,
			str(_skill_detail_ready_to_reveal_under_cover() if current_screen == "skill" else true),
			str(_skill_detail_has_visible_lazy_placeholders() if current_screen == "skill" else false)
		])
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(backing)

	var holder := Control.new()
	var holder_size: Vector2 = skill_swipe_frame.size
	if holder_size.x <= 1.0:
		holder_size.x = _skill_content_width()
	if holder_size.y <= 1.0:
		holder_size.y = _current_canvas_size().y
	holder.position = skill_swipe_frame.global_position
	holder.size = holder_size
	holder.custom_minimum_size = holder_size
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.modulate = Color(1.0, 1.0, 1.0, 0.0) if skill_swipe_paper_fade_hold_alpha >= 0.99 else Color.WHITE
	cover.add_child(holder)
	skill_swipe_frame.reparent(holder)
	skill_swipe_frame.position = Vector2.ZERO
	skill_swipe_frame.z_index = 0
	cover.set_meta("swipe_outgoing_page_holder_id", holder.get_instance_id())

	skill_swipe_handoff_cover = cover
	skill_swipe_outgoing_cover_active = true
	return cover


func _skill_swipe_handoff_cover_is_cream_transition() -> bool:
	return (
		skill_swipe_handoff_cover != null
		and is_instance_valid(skill_swipe_handoff_cover)
		and bool(skill_swipe_handoff_cover.get_meta("swipe_cream_transition_cover", false))
	)


func _skill_swipe_handoff_cover_is_opaque_cream_transition() -> bool:
	return (
		_skill_swipe_handoff_cover_is_cream_transition()
		and skill_swipe_handoff_cover.visible
		and skill_swipe_handoff_cover.modulate.a >= 0.92
	)


func _fade_skill_swipe_cover_to_opaque(seconds: float):
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	var holder_id := int(cover.get_meta("swipe_outgoing_page_holder_id", 0))
	var outgoing_holder: Control = null
	if holder_id != 0:
		outgoing_holder = _valid_control_ref(instance_from_id(holder_id))
	if outgoing_holder != null:
		var tween := create_tween()
		tween.tween_property(outgoing_holder, "modulate:a", 0.0, maxf(0.01, seconds)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		outgoing_holder = _valid_control_ref(instance_from_id(holder_id))
		if outgoing_holder != null:
			_set_canvas_item_alpha_if_changed(outgoing_holder, 0.0)
		return
	var next_modulate := cover.modulate
	next_modulate.a = clampf(next_modulate.a, 0.0, 1.0)
	_set_canvas_item_modulate_if_changed(cover, next_modulate)
	if cover.modulate.a >= 0.99:
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		return
	var tween := create_tween()
	tween.tween_property(cover, "modulate:a", 1.0, maxf(0.01, seconds)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if cover != null and is_instance_valid(cover):
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)


func _clear_skill_swipe_content_under_cover() -> void:
	if skills_content == null or not is_instance_valid(skills_content):
		return
	if (
		skill_swipe_frame != null
		and is_instance_valid(skill_swipe_frame)
		and not _skill_swipe_handoff_cover_is_opaque_cream_transition()
	):
		_kill_transient_tweens_in_subtree(skill_swipe_frame)
	while skills_content.get_child_count() > 0:
		var child := skills_content.get_child(0)
		skills_content.remove_child(child)
		child.queue_free()
	skill_swipe_frame = null
	skill_swipe_page = null
	_navigation_shell()._reset_page_control_refs()


func _begin_skill_swipe_rebuild_cover() -> void:
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		_force_skill_swipe_cover_opaque_cream()
		skill_swipe_outgoing_cover_active = false
		skill_swipe_rebuild_cover_active = true
		return
	_clear_skill_swipe_handoff_cover_immediate()
	if skills_page == null or not is_instance_valid(skills_page):
		return
	var cover := Control.new()
	_apply_skill_page_cover_bounds(cover, true)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.z_index = 0
	cover.z_as_relative = false
	cover.clip_contents = true
	cover.modulate = Color.WHITE
	cover.set_meta("swipe_cream_transition_cover", true)
	_ensure_skill_nav_cover_layer().add_child(cover)

	var backing := ColorRect.new()
	backing.color = _theme_paper_color()
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(backing)

	skill_swipe_handoff_cover = cover
	skill_swipe_rebuild_cover_active = true


func _active_skill_swipe_cover_ref(cover_id: int) -> Control:
	var cover := _valid_control_ref(instance_from_id(cover_id))
	if cover == null or cover != skill_swipe_handoff_cover:
		return null
	return cover


func _fade_clear_skill_swipe_rebuild_cover() -> void:
	if not skill_swipe_rebuild_cover_active and not skill_swipe_outgoing_cover_active:
		return
	_fade_clear_skill_swipe_cover(SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS)


func _fade_clear_skill_swipe_cover(seconds: float) -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_COVER") == "1":
		print("SWIPE_COVER_TRACE fade_clear screen=%s selected=%s pending=%s alpha=%.3f ready=%s placeholders=%s" % [
			current_screen,
			selected_skill_id,
			str(skill_swipe_pending_full_finalize),
			cover.modulate.a,
			str(_skill_detail_ready_to_reveal_under_cover() if current_screen == "skill" else true),
			str(_skill_detail_has_visible_lazy_placeholders() if current_screen == "skill" else false)
		])
	if skill_swipe_pending_full_finalize:
		_hold_skill_swipe_cover_for_pending_finalize()
		return
	if current_screen == "skill" and skill_swipe_defer_initial_lazy_mount and not _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_swipe_cover_opaque_cream()
		call_deferred("_fade_clear_skill_swipe_cover_after_layout_frame", seconds)
		return
	if current_screen == "skill" and not bool(cover.get_meta("swipe_cover_layout_frame_seen", false)):
		_kill_skill_swipe_cover_fade_tween()
		_set_canvas_item_visible_if_changed(cover, true)
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		cover.set_meta("swipe_cover_layout_frame_seen", true)
		call_deferred("_fade_clear_skill_swipe_cover_after_layout_frame", seconds)
		return
	if current_screen == "skill" and not _navigation_shell()._page_switch_scroll_cover_active() and not _skill_detail_ready_to_reveal_under_cover():
		_hold_skill_swipe_cover_until_detail_ready(seconds, 0)
		return
	if current_screen == "pinned" and not bool(cover.get_meta("pinned_cover_layout_frame_seen", false)):
		_kill_skill_swipe_cover_fade_tween()
		_set_canvas_item_visible_if_changed(cover, true)
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		cover.set_meta("pinned_cover_layout_frame_seen", true)
		call_deferred("_fade_clear_skill_swipe_cover_after_layout_frame", seconds)
		return
	if current_screen == "pinned" and not _pinned_page_ready_to_reveal_under_cover():
		_hold_skill_swipe_cover_until_pinned_ready(seconds, 0)
		return
	if current_screen == "skill" and _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_detail_reveal_mount_under_cover()
	_start_skill_swipe_cover_fade(seconds)


func _fade_clear_skill_swipe_cover_after_layout_frame(seconds: float) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1.0 / 120.0, true, false, true).timeout
	_fade_clear_skill_swipe_cover(seconds)


func _start_skill_swipe_cover_fade(seconds: float) -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	if current_screen == "skill" and skill_swipe_defer_initial_lazy_mount and not _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_swipe_cover_opaque_cream()
		call_deferred("_fade_clear_skill_swipe_cover_after_layout_frame", seconds)
		return
	if current_screen == "skill" and not _navigation_shell()._page_switch_scroll_cover_active() and not _skill_detail_ready_to_reveal_under_cover():
		_hold_skill_swipe_cover_until_detail_ready(seconds, 0)
		return
	if current_screen == "pinned" and not _pinned_page_ready_to_reveal_under_cover():
		_hold_skill_swipe_cover_until_pinned_ready(seconds, 0)
		return
	if current_screen == "skill" and _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_detail_reveal_mount_under_cover()
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_COVER") == "1":
		print("SWIPE_COVER_TRACE start_fade selected=%s alpha=%.3f ready=%s placeholders=%s" % [
			selected_skill_id,
			cover.modulate.a,
			str(_skill_detail_ready_to_reveal_under_cover() if current_screen == "skill" else true),
			str(_skill_detail_has_visible_lazy_placeholders() if current_screen == "skill" else false)
	])
	_kill_skill_swipe_cover_fade_tween()
	var cover_id := cover.get_instance_id()
	skill_swipe_cover_fade_tween = create_tween()
	skill_swipe_cover_fade_tween.tween_method(
		_apply_skill_swipe_cover_fade_alpha.bind(cover_id, seconds),
		cover.modulate.a,
		0.0,
		maxf(0.01, seconds)
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	skill_swipe_cover_fade_tween.tween_callback(_finish_skill_swipe_rebuild_cover_fade.bind(cover_id))


func _apply_skill_swipe_cover_fade_alpha(alpha: float, cover_id: int, seconds: float) -> void:
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		return
	if current_screen == "skill" and skill_swipe_defer_initial_lazy_mount and not _navigation_shell()._page_switch_scroll_cover_active():
		_force_skill_swipe_cover_opaque_cream()
		if not bool(cover.get_meta("swipe_cover_fade_cancel_requested", false)):
			cover.set_meta("swipe_cover_fade_cancel_requested", true)
			call_deferred("_cancel_skill_swipe_cover_fade_until_ready", cover_id, seconds)
		return
	if current_screen == "skill" and not _navigation_shell()._page_switch_scroll_cover_active() and not _skill_detail_ready_to_reveal_under_cover():
		_set_canvas_item_visible_if_changed(cover, true)
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		if not bool(cover.get_meta("swipe_cover_fade_cancel_requested", false)):
			cover.set_meta("swipe_cover_fade_cancel_requested", true)
			call_deferred("_cancel_skill_swipe_cover_fade_until_ready", cover_id, seconds)
		return
	if current_screen == "pinned" and not _pinned_page_ready_to_reveal_under_cover():
		_set_canvas_item_visible_if_changed(cover, true)
		_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
		if not bool(cover.get_meta("pinned_cover_fade_cancel_requested", false)):
			cover.set_meta("pinned_cover_fade_cancel_requested", true)
			call_deferred("_cancel_skill_swipe_cover_fade_until_pinned_ready", cover_id, seconds)
		return
	_set_canvas_item_alpha_if_changed(cover, alpha)


func _cancel_skill_swipe_cover_fade_until_ready(cover_id: int, seconds: float) -> void:
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		return
	if not bool(cover.get_meta("swipe_cover_fade_cancel_requested", false)):
		return
	cover.remove_meta("swipe_cover_fade_cancel_requested")
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	_hold_skill_swipe_cover_until_detail_ready(seconds, 0)


func _hold_skill_swipe_cover_until_detail_ready(seconds: float, attempts: int) -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	if not _skill_detail_ready_to_reveal_under_cover():
		_force_skill_detail_reveal_mount_under_cover()
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_COVER") == "1":
		print("SWIPE_COVER_TRACE hold_ready selected=%s attempts=%s alpha=%.3f ready=%s placeholders=%s" % [
			selected_skill_id,
			str(attempts),
			cover.modulate.a,
			str(_skill_detail_ready_to_reveal_under_cover()),
			str(_skill_detail_has_visible_lazy_placeholders())
		])
	if _skill_detail_ready_to_reveal_under_cover():
		_start_skill_swipe_cover_fade(seconds)
		return
	if attempts >= 18:
		_repair_blank_detail_lazy_stack()
		_force_skill_detail_reveal_mount_under_cover()
		if _skill_detail_ready_to_reveal_under_cover():
			_start_skill_swipe_cover_fade(seconds)
			return
	call_deferred("_hold_skill_swipe_cover_until_detail_ready_after_frame", seconds, attempts + 1)


func _hold_skill_swipe_cover_until_detail_ready_after_frame(seconds: float, attempts: int) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1.0 / 120.0, true, false, true).timeout
	_hold_skill_swipe_cover_until_detail_ready(seconds, attempts)


func _pinned_page_ready_to_reveal_under_cover() -> bool:
	if current_screen != "pinned":
		return true
	if content_scroll == null or not is_instance_valid(content_scroll) or not content_scroll.is_inside_tree():
		return false
	if skills_content == null or not is_instance_valid(skills_content) or not skills_content.is_inside_tree():
		return false
	if _find_named_control_descendant(skills_content, "PinnedActivitiesPage") == null:
		return false
	if _find_named_control_descendant(skills_content, "PinnedActivitiesActiveShelf") == null:
		return false
	return true


func _cancel_skill_swipe_cover_fade_until_pinned_ready(cover_id: int, seconds: float) -> void:
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		return
	if not bool(cover.get_meta("pinned_cover_fade_cancel_requested", false)):
		return
	cover.remove_meta("pinned_cover_fade_cancel_requested")
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	_hold_skill_swipe_cover_until_pinned_ready(seconds, 0)


func _hold_skill_swipe_cover_until_pinned_ready(seconds: float, attempts: int) -> void:
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_clear_skill_swipe_handoff_cover_immediate()
		return
	_kill_skill_swipe_cover_fade_tween()
	_set_canvas_item_visible_if_changed(cover, true)
	_set_canvas_item_modulate_if_changed(cover, Color.WHITE)
	skill_swipe_outgoing_cover_active = true
	if _pinned_page_ready_to_reveal_under_cover() or attempts >= 18:
		_start_skill_swipe_cover_fade(seconds)
		return
	call_deferred("_hold_skill_swipe_cover_until_pinned_ready_after_frame", seconds, attempts + 1)


func _hold_skill_swipe_cover_until_pinned_ready_after_frame(seconds: float, attempts: int) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(1.0 / 120.0, true, false, true).timeout
	_hold_skill_swipe_cover_until_pinned_ready(seconds, attempts)


func _finish_skill_swipe_rebuild_cover_fade(cover_id: int) -> void:
	skill_swipe_cover_fade_tween = null
	if skill_swipe_pending_full_finalize:
		_hold_skill_swipe_cover_for_pending_finalize()
		return
	var cover := _active_skill_swipe_cover_ref(cover_id)
	if cover == null:
		if skill_swipe_handoff_cover == null or not is_instance_valid(skill_swipe_handoff_cover):
			skill_swipe_handoff_cover = null
		skill_swipe_rebuild_cover_active = false
		return
	if skill_swipe_handoff_cover == cover:
		_clear_skill_swipe_handoff_cover_immediate()


func _cancel_skill_swipe_feedback(animated := true) -> void:
	skill_swipe_tracking = false
	skill_swipe_horizontal = false
	skill_swipe_touch_index = -1
	skill_swipe_drag_base_x = 0.0
	skill_swipe_strip_committed_crossfade = false
	if skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		_skill_swipe_activity_surface()._clear_skill_swipe_preview()
		return
	_kill_skill_swipe_tween()
	if animated and absf(skill_swipe_drag_offset_x) > 1.0:
		skill_swipe_animating = true
		skill_swipe_animation_mode = "cancel"
		_fade_skill_page_switch_modules(true, SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS)
		_fade_skill_swipe_module_utility_row(true, SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS)
		_fade_skill_shelf_backgrounds(true, SKILL_SWIPE_SHELF_BACKGROUND_FADE_IN_SECONDS)
		skill_swipe_tween = create_tween()
		skill_swipe_tween.set_parallel(true)
		var start_drag := skill_swipe_drag_offset_x
		skill_swipe_tween.tween_method(_apply_skill_swipe_drag_offset, start_drag, 0.0, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		var preview_page := _skill_swipe_activity_surface()._active_preview_page()
		if preview_page != null:
			var preview_exit := _skill_swipe_activity_surface()._skill_swipe_preview_rest_x(_skill_swipe_activity_surface()._active_preview_offset())
			skill_swipe_tween.tween_property(preview_page, "position:x", preview_exit, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			skill_swipe_tween.tween_property(preview_page, "modulate:a", 0.0, SKILL_SWIPE_CANCEL_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		skill_swipe_tween.finished.connect(_finish_skill_swipe_cancel_tween)
	else:
		_restore_skill_strip_wrap_page()
		_apply_skill_swipe_drag_offset(0.0)
		_sync_skill_strip_page_visibility(false)
		_skill_swipe_activity_surface()._park_skill_swipe_preview()
		_fade_skill_page_switch_modules(true, SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS)
		_fade_skill_swipe_module_utility_row(true, SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS)
		_fade_skill_shelf_backgrounds(true, SKILL_SWIPE_SHELF_BACKGROUND_FADE_IN_SECONDS)
		_skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()


func _finish_skill_swipe(end_position: Vector2) -> void:
	if _onboarding_runtime()._onboarding_blocks_skill_swipe():
		if not _onboarding_runtime()._ensure_onboarding_swipe_unlocked(true):
			skill_swipe_tracking = false
			skill_swipe_touch_index = -1
			skill_swipe_horizontal = false
			_cancel_skill_swipe_feedback(true)
			if skill_swipe_child_click_suppressed:
				call_deferred("_clear_skill_swipe_action_click_suppression")
			return
	var delta: Vector2 = end_position - skill_swipe_start
	skill_swipe_tracking = false
	skill_swipe_touch_index = -1
	skill_swipe_drag_base_x = 0.0
	if absf(delta.x) < SKILL_SWIPE_THRESHOLD or absf(delta.x) < absf(delta.y) * 1.35:
		if _skill_swipe_animation_blocks_input():
			if skill_swipe_child_click_suppressed:
				call_deferred("_clear_skill_swipe_action_click_suppression")
			return
		_cancel_skill_swipe_feedback(true)
		if skill_swipe_child_click_suppressed:
			call_deferred("_clear_skill_swipe_action_click_suppression")
		return
	if _skill_swipe_animation_blocks_input():
		_queue_skill_swipe_navigation(1 if delta.x < 0.0 else -1)
		_suppress_skill_swipe_action_click()
		if skill_swipe_child_click_suppressed:
			call_deferred("_clear_skill_swipe_action_click_suppression")
		return
	_update_skill_swipe_feedback(end_position)
	var offset := 1 if delta.x < 0.0 else -1
	if not _onboarding_runtime()._swipe_offset_accessible(offset):
		_cancel_skill_swipe_feedback(true)
		if skill_swipe_child_click_suppressed:
			call_deferred("_clear_skill_swipe_action_click_suppression")
		return
	_commit_skill_swipe(offset)
	if skill_swipe_child_click_suppressed:
		call_deferred("_clear_skill_swipe_action_click_suppression")


func _suppress_skill_swipe_action_click() -> void:
	skill_swipe_child_click_suppressed = true
	passive_button_pending_tap_id += 1
	skill_swipe_button_suppressed_until_msec = Time.get_ticks_msec() + SKILL_SWIPE_BUTTON_SUPPRESS_MSEC
	get_viewport().set_input_as_handled()


func _clear_skill_swipe_action_click_suppression() -> void:
	skill_swipe_child_click_suppressed = false


func _clear_skill_swipe_button_suppression() -> void:
	skill_swipe_child_click_suppressed = false
	skill_swipe_button_suppressed_until_msec = 0


func _skill_swipe_suppresses_button_action() -> bool:
	return skill_swipe_child_click_suppressed or Time.get_ticks_msec() < skill_swipe_button_suppressed_until_msec


func _collapse_expanded_activity_modules() -> void:
	expanded_activity_stat_key = ""
	expanded_activity_stat_kind = ""
	_clear_passive_button_press()
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		var info_popover := card.get("info_popover") as Control
		if info_popover != null and is_instance_valid(info_popover):
			_passive_firepit_surface()._schedule_passive_info_popover_dismiss(info_popover)
		var root := card.get("root") as Control
		if root != null and is_instance_valid(root) and card.has("bonus_panel"):
			_set_activity_card_expanded(card, root, false, true)
			card.erase("bonus_displayed_stat_kind")
			card.erase("bonus_pending_stat_kind")


func _clear_passive_button_press() -> void:
	passive_button_pending_tap_id += 1
	passive_button_press_source = null
	passive_button_press_kind = ""
	passive_button_press_module_id = ""
	passive_button_press_stat_type = ""
	passive_button_press_popover = null
	passive_button_press_position = Vector2.ZERO
	passive_button_press_dragged = false
	passive_button_press_touch_index = -1


func _commit_skill_swipe(offset: int) -> void:
	skill_swipe_horizontal = false
	if offset != 0 and skill_strip_ids.is_empty():
		_fade_skill_page_switch_modules(false, SKILL_SWIPE_PAGE_SWITCH_FADE_OUT_SECONDS)
		_fade_skill_swipe_module_utility_row(false, SKILL_SWIPE_MODULE_UTILITY_FADE_OUT_SECONDS)
		_fade_skill_shelf_backgrounds(false, SKILL_SWIPE_SHELF_BACKGROUND_FADE_OUT_SECONDS)
	var entry_x := signi(offset) * _skill_swipe_page_span()
	entry_x = skill_swipe_drag_offset_x
	var animate_commit_release := absf(entry_x) > 1.0 and absf(entry_x) < absf(_skill_swipe_commit_release_target_x(offset)) - 1.0
	if not animate_commit_release:
		if skill_strip_ids.is_empty():
			_hold_skill_swipe_paper_fade_for_commit()
		else:
			skill_swipe_strip_committed_crossfade = true
			_hide_skill_swipe_paper_fade()
	var outgoing_skill_id := selected_skill_id
	if offset != 0 and outgoing_skill_id == "fishing" and fishing_tool_wallet_open:
		_fishing_ui_surface()._clear_fishing_tool_circle_menu()
	if offset != 0 and outgoing_skill_id == TUTORIAL_STARTER_SKILL_ID:
		_onboarding_runtime()._clear_tutorial_gate_latch_only_after_skill_swipe(false)
	_complete_passive_module_tip_page_visit(outgoing_skill_id)
	_complete_silver_opportunity_tip_page_visit(outgoing_skill_id)
	if offset != 0 and _onboarding_runtime()._onboarding_path_active():
		if onboarding_explore_tip_seen:
			_onboarding_runtime()._graduate_onboarding_tutorial()
		elif outgoing_skill_id == TUTORIAL_STARTER_SKILL_ID:
			_tutorial_overlay_surface()._fade_tip_group("skill_swipe_tip_notes", false, true)
			_fade_out_onboarding_swipe_overlay_tip()
			if not skill_swipe_tip_seen:
				skill_swipe_tip_seen = true
				save_game()
	if animate_commit_release:
		_animate_skill_swipe_commit_release(offset, entry_x)
	else:
		_navigate_skill_page(offset, entry_x, true, false)
	action_card_press_key = ""
	action_card_press_stat_kind = ""
	action_card_press_dragged = false
	_clear_passive_button_press()
	_clear_module_pin_press()
	_clear_skill_swipe_button_suppression()


func _apply_skill_swipe_commit_release_offset(current_x: float, offset: int) -> void:
	_skill_swipe_activity_surface()._set_skill_swipe_positions(offset, current_x)


func _animate_skill_swipe_commit_release(offset: int, start_x: float) -> void:
	if offset == 0 or skill_swipe_frame == null or not is_instance_valid(skill_swipe_frame):
		_navigate_skill_page(offset, start_x, true, false)
		return
	if not skill_strip_ids.is_empty():
		skill_swipe_strip_committed_crossfade = false
	_kill_skill_swipe_tween()
	skill_swipe_animating = true
	skill_swipe_animation_mode = "settle"
	_skill_swipe_activity_surface()._set_active_preview(_skill_swipe_activity_surface()._active_preview_page(), offset)
	var target_x := _skill_swipe_commit_release_target_x(offset)
	var remaining_ratio := clampf(absf(target_x - start_x) / maxf(1.0, _skill_swipe_commit_release_span()), 0.0, 1.0)
	var settle_seconds := clampf(SKILL_SWIPE_SETTLE_SECONDS * remaining_ratio, 0.08, SKILL_SWIPE_SETTLE_SECONDS)
	skill_swipe_tween = create_tween()
	skill_swipe_tween.tween_method(
		_apply_skill_swipe_commit_release_offset.bind(offset),
		start_x,
		target_x,
		settle_seconds
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	skill_swipe_tween.finished.connect(_finish_skill_swipe_commit_tween.bind(offset, target_x))


func _skill_swipe_commit_release_span() -> float:
	return _skill_content_width() if not skill_strip_ids.is_empty() else _skill_swipe_page_span()


func _finish_skill_swipe_cancel_tween() -> void:
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""
	_restore_skill_strip_wrap_page()
	skill_swipe_strip_committed_crossfade = false
	_apply_skill_swipe_drag_offset(0.0)
	_sync_skill_strip_page_visibility(false)
	_skill_swipe_activity_surface()._park_skill_swipe_preview()
	if not _consume_queued_skill_swipe_navigation():
		_skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()


func _finish_skill_swipe_commit_tween(offset: int, target_x: float) -> void:
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""
	if skill_strip_ids.is_empty():
		_hold_skill_swipe_paper_fade_for_commit()
	else:
		skill_swipe_strip_committed_crossfade = true
	_navigate_skill_page(offset, target_x, true, false)


func _skill_swipe_commit_release_target_x(offset: int) -> float:
	return -float(signi(offset)) * _skill_swipe_commit_release_span()


func _queue_skill_swipe_navigation(offset: int) -> void:
	if offset == 0:
		return
	skill_swipe_queued_offset += offset


func _consume_queued_skill_swipe_navigation() -> bool:
	if skill_swipe_queued_offset == 0 or current_screen != "skill":
		return false
	var offset := skill_swipe_queued_offset
	skill_swipe_queued_offset = 0
	var skill_count := skill_defs.size()
	if skill_count <= 0:
		return false
	offset = offset % skill_count
	if offset == 0:
		_skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()
		return false
	if not _onboarding_runtime()._swipe_offset_accessible(offset):
		return false
	_force_skill_swipe_cover_opaque_cream()
	_skill_swipe_activity_surface()._ensure_skill_swipe_preview_page_cached(offset)
	_navigate_skill_page(offset, signi(offset) * _skill_swipe_page_span(), true, false)
	return true


func _discard_incoming_swipe_preview_for_animated_handoff(incoming_preview: Dictionary) -> void:
	if incoming_preview.is_empty():
		return
	_discard_incoming_swipe_preview(incoming_preview)


func _mount_swipe_preview_as_skill_detail(preview_page: Control, preview_state: Dictionary) -> void:
	var skill_id := str(preview_state.get("skill_id", selected_skill_id))
	_settings_surface()._clear_settings_page_control_refs()
	_navigation_shell()._reset_page_control_refs()
	var frame := Control.new()
	skill_swipe_frame = frame
	frame.clip_contents = false
	var frame_width := _skill_content_width()
	_apply_skill_column_layout(frame, frame_width, skill_swipe_gap_render_offset_x)
	skills_content.add_child(frame)
	skill_swipe_page = preview_page
	if preview_page.get_parent() != null:
		preview_page.reparent(frame)
	else:
		frame.add_child(preview_page)
	_normalize_skill_detail_page_layout(preview_page)
	preview_page.z_index = 20
	preview_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_xp_label = preview_state.get("xp_label") as Label
	detail_xp_bar = preview_state.get("xp_bar") as CleanProgressBar
	detail_regen_circle = preview_state.get("regen_circle") as RegenCircle
	detail_fish_circle = preview_state.get("fish_circle") as FishCircle
	detail_auto_eat_fish_button = preview_state.get("auto_eat_fish_button") as TextureButton
	detail_header_body = preview_state.get("header_body") as Control
	_ensure_promoted_swipe_header_gauge(preview_page, preview_state, skill_id)
	var preview_scroll := preview_state.get("actions_scroll") as MobileScrollContainer
	if preview_scroll != null and is_instance_valid(preview_scroll):
		_skill_detail_surface()._ensure_skill_detail_actions_clip_wrapper(preview_page, preview_scroll, frame_width)
		detail_actions_scroll = preview_scroll
		preview_scroll.visible = true
		preview_scroll.modulate = Color.WHITE
	_detail_lazy_show_preview_modules(preview_state)
	_ensure_swipe_preview_modules_visible(preview_page, preview_state)
	_wire_mounted_swipe_preview_detail(preview_state)
	_add_skill_detail_shadow_overlay(_skill_detail_shadow_top_y())
	if bool(preview_state.get("proxy_handoff", false)) and not (preview_state.get("action_cards", []) as Array).is_empty():
		detail_lazy_plan.clear()
		detail_lazy_last_scroll = -1.0
		detail_lazy_mounted_this_frame = false
		_promote_swipe_preview_to_interactive(preview_state)
		skill_swipe_pending_full_finalize = false
		skill_swipe_pending_preview_state = {}
		_schedule_proxy_skill_detail_full_refresh(skill_id)
		return
	skill_swipe_pending_full_finalize = true
	skill_swipe_pending_preview_state = preview_state
	_hold_skill_swipe_cover_for_pending_finalize()


func _wire_mounted_swipe_preview_detail(_preview_state: Dictionary) -> void:
	detail_lazy_stack = _detail_actions_stack() as VBoxContainer
	detail_rendered_action_ids.clear()
	detail_action_card_nodes.clear()
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		skill_swipe_page.mouse_filter = Control.MOUSE_FILTER_PASS
	if skill_swipe_frame != null and is_instance_valid(skill_swipe_frame):
		skill_swipe_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		detail_actions_scroll.mouse_filter = Control.MOUSE_FILTER_PASS


func _ensure_promoted_swipe_header_gauge(preview_page: Control, preview_state: Dictionary, skill_id: String) -> void:
	if preview_page == null or not is_instance_valid(preview_page):
		return
	var gauge_parent := _swipe_preview_header_gauge_parent(preview_state, preview_page)
	if gauge_parent == null or not is_instance_valid(gauge_parent):
		return
	if _fishing_rework_active_for_skill(skill_id):
		if detail_fish_circle != null and is_instance_valid(detail_fish_circle):
			preview_state["fish_circle"] = detail_fish_circle
			return
		_clear_swipe_preview_header_gauge_slot(gauge_parent)
		detail_regen_circle = null
		detail_regen_circle_host = null
		detail_regen_circle_fade_group = null
		detail_auto_eat_fish_button = null
		var fish_circle := FishCircle.new()
		fish_circle.custom_minimum_size = Vector2(552, 552)
		fish_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fish_circle.mouse_filter = Control.MOUSE_FILTER_PASS
		fish_circle.z_index = 3000
		fish_circle.z_as_relative = false
		gauge_parent.add_child(fish_circle)
		detail_fish_circle = fish_circle
		preview_state["fish_circle"] = fish_circle
		_attach_fishing_fish_circle_button(fish_circle)
		_set_fish_circle_for_skill(fish_circle, skill_id, true)
		return
	if detail_regen_circle != null and is_instance_valid(detail_regen_circle):
		var existing_toggle := preview_state.get("auto_eat_fish_button") as TextureButton
		if existing_toggle != null and is_instance_valid(existing_toggle):
			detail_auto_eat_fish_button = existing_toggle
			detail_auto_eat_fish_button.set_meta("auto_eat_skill_id", skill_id)
			preview_state["regen_circle"] = detail_regen_circle
			_fishing_ui_surface()._sync_auto_eat_fish_toggle_button(detail_auto_eat_fish_button)
			return
	_clear_swipe_preview_header_gauge_slot(gauge_parent)
	detail_fish_circle = null
	detail_regen_circle_host = Control.new()
	detail_regen_circle_host.custom_minimum_size = Vector2(552, 552)
	detail_regen_circle_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail_regen_circle_host.clip_contents = false
	detail_regen_circle_fade_group = CanvasGroup.new()
	detail_regen_circle = RegenCircle.new()
	detail_regen_circle.custom_minimum_size = Vector2(552, 552)
	detail_regen_circle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
	detail_regen_circle.modulate = Color.WHITE
	detail_regen_circle.set_dark_mode(dark_mode_enabled)
	detail_regen_circle.gui_input.connect(_on_stamina_gauge_input.bind("", detail_regen_circle))
	detail_regen_circle_fade_group.add_child(detail_regen_circle)
	detail_regen_circle_host.add_child(detail_regen_circle_fade_group)
	gauge_parent.add_child(detail_regen_circle_host)
	detail_auto_eat_fish_button = _fishing_ui_surface()._attach_auto_eat_fish_toggle(detail_regen_circle_host, skill_id)
	preview_state["regen_circle"] = detail_regen_circle
	preview_state["regen_circle_host"] = detail_regen_circle_host
	preview_state["regen_circle_fade_group"] = detail_regen_circle_fade_group
	preview_state["auto_eat_fish_button"] = detail_auto_eat_fish_button
	_set_regen_circle_for_skill(detail_regen_circle, skill_id, true)


func _swipe_preview_header_gauge_parent(preview_state: Dictionary, preview_page: Control) -> Control:
	var regen_circle := preview_state.get("regen_circle") as Control
	if regen_circle != null and is_instance_valid(regen_circle):
		return regen_circle.get_parent() as Control
	var fish_circle := preview_state.get("fish_circle") as Control
	if fish_circle != null and is_instance_valid(fish_circle):
		return fish_circle.get_parent() as Control
	var header_body := preview_state.get("header_body") as Control
	if header_body == null or not is_instance_valid(header_body):
		header_body = _find_swipe_preview_header_body(preview_page)
	if header_body == null or not is_instance_valid(header_body):
		return null
	var row := _find_first_descendant_of_class(header_body, "HBoxContainer") as HBoxContainer
	if row == null or not is_instance_valid(row) or row.get_child_count() <= 0:
		return null
	return row


func _find_swipe_preview_header_body(preview_page: Control) -> Control:
	if preview_page == null or not is_instance_valid(preview_page) or preview_page.get_child_count() <= 0:
		return null
	var header := preview_page.get_child(0) as Control
	if header == null or not is_instance_valid(header) or header.get_child_count() <= 0:
		return null
	return header.get_child(0) as Control


func _find_first_descendant_of_class(root: Control, target_class_name: String) -> Control:
	if root == null or not is_instance_valid(root):
		return null
	for child in root.get_children():
		var control := child as Control
		if control == null:
			continue
		if control.get_class() == target_class_name:
			return control
		var nested := _find_first_descendant_of_class(control, target_class_name)
		if nested != null:
			return nested
	return null


func _clear_swipe_preview_header_gauge_slot(gauge_parent: Control) -> void:
	if gauge_parent == null or not is_instance_valid(gauge_parent):
		return
	for child in gauge_parent.get_children():
		if child is Control and bool((child as Control).size_flags_horizontal & Control.SIZE_EXPAND):
			continue
		gauge_parent.remove_child(child)
		child.queue_free()


func _schedule_swipe_preview_finalize_after_navigation() -> void:
	if not skill_swipe_pending_full_finalize:
		return
	_freeze_pending_swipe_preview_stack_under_cover()
	skill_swipe_finalize_schedule_token += 1
	skill_swipe_finalize_target_skill_id = selected_skill_id
	skill_swipe_finalize_ready_process_frame = main_process_frame_index + maxi(1, SKILL_SWIPE_FINALIZE_SETTLE_FRAMES)
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
		print("SWIPE_FINALIZE_TRACE schedule frame=%s ready=%s target=%s pending=%s anim=%s tracking=%s" % [
			str(main_process_frame_index),
			str(skill_swipe_finalize_ready_process_frame),
			skill_swipe_finalize_target_skill_id,
			str(skill_swipe_pending_full_finalize),
			str(skill_swipe_animating),
			str(skill_swipe_tracking)
		])


func _freeze_pending_swipe_preview_stack_under_cover() -> void:
	if skill_swipe_handoff_cover == null or not is_instance_valid(skill_swipe_handoff_cover):
		return
	var preview_page := skill_swipe_page
	if preview_page == null or not is_instance_valid(preview_page):
		return
	var stack := _find_skill_preview_stack(preview_page) as Control
	if stack == null or not is_instance_valid(stack):
		return
	stack.visible = false
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process_pending_swipe_preview_finalize() -> void:
	if not skill_swipe_pending_full_finalize:
		skill_swipe_finalize_ready_process_frame = -1
		skill_swipe_finalize_target_skill_id = ""
		return
	if skill_swipe_finalize_ready_process_frame < 0:
		return
	if current_screen != "skill" or selected_skill_id != skill_swipe_finalize_target_skill_id:
		if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
			print("SWIPE_FINALIZE_TRACE cancel=mismatch frame=%s screen=%s selected=%s target=%s" % [
				str(main_process_frame_index),
				current_screen,
				selected_skill_id,
				skill_swipe_finalize_target_skill_id
			])
		skill_swipe_finalize_ready_process_frame = -1
		skill_swipe_finalize_target_skill_id = ""
		return
	if skill_swipe_tracking:
		if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
			print("SWIPE_FINALIZE_TRACE wait=tracking frame=%s ready=%s target=%s anim=%s tracking=%s" % [
				str(main_process_frame_index),
				str(skill_swipe_finalize_ready_process_frame),
				skill_swipe_finalize_target_skill_id,
				str(skill_swipe_animating),
				str(skill_swipe_tracking)
			])
		skill_swipe_finalize_ready_process_frame = main_process_frame_index + maxi(1, SKILL_SWIPE_FINALIZE_SETTLE_FRAMES)
		return
	if main_process_frame_index < skill_swipe_finalize_ready_process_frame:
		if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
			print("SWIPE_FINALIZE_TRACE wait=settle frame=%s ready=%s target=%s" % [
				str(main_process_frame_index),
				str(skill_swipe_finalize_ready_process_frame),
				skill_swipe_finalize_target_skill_id
			])
		return
	var target_skill_id := skill_swipe_finalize_target_skill_id
	if OS.get_environment("IDLE_ELITE_TRACE_SWIPE_FINALIZE") == "1":
		print("SWIPE_FINALIZE_TRACE finalize frame=%s target=%s" % [str(main_process_frame_index), target_skill_id])
	skill_swipe_finalize_ready_process_frame = -1
	skill_swipe_finalize_target_skill_id = ""
	_finalize_swipe_preview_to_full_detail(target_skill_id)


func _detail_lazy_show_preview_modules(preview_state: Dictionary) -> void:
	_cancel_skill_swipe_preview_modules_reveal(preview_state)
	var modules_root := preview_state.get("modules_root") as Control
	if modules_root != null and is_instance_valid(modules_root):
		modules_root.visible = true
		modules_root.modulate = Color.WHITE


func _cancel_skill_swipe_preview_modules_reveal(preview_state: Dictionary) -> void:
	_skill_swipe_activity_surface().preview_module_reveal_token += 1
	_app_lifecycle_runtime()._kill_card_tween(preview_state, "reveal_tween")


func _preview_actions_scroll_vertical(preview_state: Dictionary) -> int:
	var scroll := preview_state.get("actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll):
		return -1
	return scroll.scroll_vertical


func _find_skill_preview_actions_scroll(preview_page: Control) -> Control:
	if preview_page == null or not is_instance_valid(preview_page):
		return null
	var nested := _find_skill_preview_actions_scroll_in(preview_page)
	if nested != null:
		return nested
	return null


func _find_skill_preview_actions_scroll_in(control: Control) -> Control:
	if control == null or not is_instance_valid(control):
		return null
	for child in control.get_children():
		if child is ScrollContainer:
			return child as Control
	for child in control.get_children():
		var child_control := child as Control
		if child_control == null:
			continue
		var nested := _find_skill_preview_actions_scroll_in(child_control)
		if nested != null:
			return nested
	return null


func _incoming_swipe_preview_usable(incoming_preview: Dictionary) -> bool:
	var preview_page := incoming_preview.get("page") as Control
	var preview_state := incoming_preview.get("state", {}) as Dictionary
	if preview_page == null or not is_instance_valid(preview_page):
		return false
	var scroll := preview_state.get("actions_scroll") as Control
	if scroll == null or not is_instance_valid(scroll):
		scroll = _find_skill_preview_actions_scroll(preview_page)
	if scroll == null or not is_instance_valid(scroll):
		return false
	var cards := preview_state.get("action_cards", []) as Array
	if not cards.is_empty():
		return true
	var fishing_modules := preview_state.get("fishing_built_modules", []) as Array
	if not fishing_modules.is_empty():
		return true
	# Light preview cards are only a visual handoff. Promoting them to the live
	# page makes the modules appear briefly, then disappear when finalize swaps
	# them for real lazy slots.
	return _skill_swipe_handoff_cover_is_opaque_cream_transition()


func _ensure_swipe_preview_modules_visible(preview_page: Control, preview_state: Dictionary) -> void:
	_cancel_skill_swipe_preview_modules_reveal(preview_state)
	var modules_root := preview_state.get("modules_root") as Control
	if modules_root == null or not is_instance_valid(modules_root):
		modules_root = preview_state.get("actions_scroll") as Control
	if modules_root == null or not is_instance_valid(modules_root):
		modules_root = _find_skill_preview_actions_scroll(preview_page)
	if modules_root != null and is_instance_valid(modules_root):
		modules_root.visible = true
		modules_root.modulate = Color(1, 1, 1, 1)
	if preview_page != null and is_instance_valid(preview_page):
		preview_page.visible = true
		preview_page.modulate = Color.WHITE


func _find_skill_preview_stack(preview_page: Control) -> Control:
	var scroll := _find_skill_preview_actions_scroll(preview_page)
	if scroll == null or scroll.get_child_count() <= 0:
		return null
	return scroll.get_child(0) as Control


func _skill_detail_stack_has_visible_modules(stack: Control) -> bool:
	if stack == null or not is_instance_valid(stack):
		return false
	for child in stack.get_children():
		var control := child as Control
		if _detail_stack_child_is_module_content(control):
			return true
	return false


func _skill_detail_visible_module_stats() -> Dictionary:
	var stats := {
		"scroll_area": 0.0,
		"visible_modules": 0,
		"visible_module_area": 0.0,
		"action_stat_boxes": 0,
		"visible_action_stat_boxes": 0,
		"fishing_method_tiles": 0,
		"visible_fishing_method_tiles": 0,
		"freshly_mounted_modules": 0,
	}
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return stats
	if not detail_actions_scroll.visible or not detail_actions_scroll.is_visible_in_tree():
		return stats
	var scroll_rect := detail_actions_scroll.get_global_rect()
	stats["scroll_area"] = maxf(0.0, scroll_rect.size.x) * maxf(0.0, scroll_rect.size.y)
	if scroll_rect.size.x <= 1.0 or scroll_rect.size.y <= 1.0:
		return stats
	var visible_rect := Rect2(Vector2.ZERO, _current_canvas_size())
	var viewport_rect := scroll_rect.intersection(visible_rect)
	if viewport_rect.size.x <= 1.0 or viewport_rect.size.y <= 1.0:
		return stats
	var stack := _detail_actions_stack() as Control
	if stack == null or not is_instance_valid(stack):
		return stats
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null or not _detail_stack_child_is_module_content(child):
			continue
		var intersection := child.get_global_rect().intersection(viewport_rect)
		var area := maxf(0.0, intersection.size.x) * maxf(0.0, intersection.size.y)
		if area <= 1.0:
			continue
		stats["visible_modules"] = int(stats["visible_modules"]) + 1
		stats["visible_module_area"] = float(stats["visible_module_area"]) + area
		if not _detail_lazy_visible_module_mount_frames_settled(child):
			stats["freshly_mounted_modules"] = int(stats["freshly_mounted_modules"]) + 1
		var stat_boxes := _action_stat_box_visibility_stats(child, viewport_rect)
		stats["action_stat_boxes"] = int(stats["action_stat_boxes"]) + int(stat_boxes.get("total", 0))
		stats["visible_action_stat_boxes"] = int(stats["visible_action_stat_boxes"]) + int(stat_boxes.get("visible", 0))
		var fishing_tiles := _marked_control_visibility_stats(child, viewport_rect, "fishing_area_method_ready_marker")
		stats["fishing_method_tiles"] = int(stats["fishing_method_tiles"]) + int(fishing_tiles.get("total", 0))
		stats["visible_fishing_method_tiles"] = int(stats["visible_fishing_method_tiles"]) + int(fishing_tiles.get("visible", 0))
	return stats


func _mark_detail_lazy_module_mounted(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.set_meta("detail_lazy_mounted_process_frame", Engine.get_process_frames())


func _detail_lazy_visible_module_mount_frames_settled(control: Control) -> bool:
	return _detail_lazy_control_mount_frames_settled(control, Engine.get_process_frames())


func _detail_lazy_control_mount_frames_settled(control: Control, current_process_frame: int) -> bool:
	if control == null or not is_instance_valid(control):
		return true
	if control.has_meta("detail_lazy_mounted_process_frame"):
		var mounted_process_frame := int(control.get_meta("detail_lazy_mounted_process_frame"))
		if current_process_frame - mounted_process_frame < 2:
			return false
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null and not _detail_lazy_control_mount_frames_settled(child, current_process_frame):
			return false
	return true


func _marked_control_visibility_stats(control: Control, viewport_rect: Rect2, marker_name: String) -> Dictionary:
	var stats := {"total": 0, "visible": 0}
	_collect_marked_control_visibility_stats(control, viewport_rect, marker_name, stats)
	return stats


func _collect_marked_control_visibility_stats(control: Control, viewport_rect: Rect2, marker_name: String, stats: Dictionary) -> void:
	if control == null or not is_instance_valid(control):
		return
	if bool(control.get_meta(marker_name, false)):
		stats["total"] = int(stats.get("total", 0)) + 1
		if _control_rect_intersects_viewport(control, viewport_rect):
			stats["visible"] = int(stats.get("visible", 0)) + 1
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null:
			_collect_marked_control_visibility_stats(child, viewport_rect, marker_name, stats)


func _action_stat_box_visibility_stats(control: Control, viewport_rect: Rect2) -> Dictionary:
	var stats := {"total": 0, "visible": 0}
	_collect_action_stat_box_visibility_stats(control, viewport_rect, stats)
	return stats


func _collect_action_stat_box_visibility_stats(control: Control, viewport_rect: Rect2, stats: Dictionary) -> void:
	if control == null or not is_instance_valid(control):
		return
	if bool(control.get_meta("action_stat_box", false)):
		stats["total"] = int(stats.get("total", 0)) + 1
		if _control_rect_intersects_viewport(control, viewport_rect):
			stats["visible"] = int(stats.get("visible", 0)) + 1
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null:
			_collect_action_stat_box_visibility_stats(child, viewport_rect, stats)


func _skill_detail_stack_is_presentable(stack: Control) -> bool:
	if stack == null or not is_instance_valid(stack):
		return false
	if not stack.visible or not stack.is_visible_in_tree() or stack.modulate.a <= 0.01:
		return false
	return _skill_detail_stack_has_visible_modules(stack)


func _control_rect_intersects_viewport(control: Control, viewport_rect: Rect2) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if not control.visible or control.is_queued_for_deletion() or control.modulate.a <= 0.01:
		return false
	var rect := control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	return rect.intersects(viewport_rect)


func _control_tree_has_lazy_placeholder(control: Control) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	if bool(control.get_meta("detail_lazy_placeholder", false)):
		return true
	for raw_child in control.get_children():
		var child := raw_child as Control
		if child != null and _control_tree_has_lazy_placeholder(child):
			return true
	return false


func _skill_detail_has_visible_lazy_placeholders() -> bool:
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return false
	var stack := _detail_actions_stack() as Control
	if stack == null or not is_instance_valid(stack):
		return false
	var viewport_rect := detail_actions_scroll.get_global_rect()
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null:
			continue
		if child.name == "DetailActionsTopSpacer" or child.name == "DetailActionsBottomSpacer":
			continue
		if _control_rect_intersects_viewport(child, viewport_rect) and _control_tree_has_lazy_placeholder(child):
			return true
	return false


func _skill_detail_ready_to_reveal_under_cover() -> bool:
	if _skill_swipe_cover_reveal_blocked_by_animation():
		return false
	var stack := _detail_actions_stack() as Control
	if not _skill_detail_stack_is_presentable(stack):
		return false
	var stats := _skill_detail_visible_module_stats()
	if float(stats.get("scroll_area", 0.0)) < 100000.0:
		return false
	if int(stats.get("visible_modules", 0)) <= 0:
		return false
	if float(stats.get("visible_module_area", 0.0)) < 50000.0:
		return false
	if int(stats.get("freshly_mounted_modules", 0)) > 0:
		return false
	var action_stat_box_count := int(stats.get("action_stat_boxes", 0))
	if action_stat_box_count > 0 and not _tutorial_overlay_surface()._onboarding_fight_action_stats_should_hide():
		var visible_stat_box_count := int(stats.get("visible_action_stat_boxes", 0))
		if visible_stat_box_count < mini(2, action_stat_box_count):
			return false
	var fishing_tile_count := int(stats.get("fishing_method_tiles", 0))
	if fishing_tile_count > 0 and int(stats.get("visible_fishing_method_tiles", 0)) <= 0:
		return false
	return not _skill_detail_has_visible_lazy_placeholders()


func _skill_swipe_cover_reveal_blocked_by_animation() -> bool:
	if current_screen != "skill" or not skill_swipe_animating or skill_swipe_animation_mode.is_empty():
		return false
	var cover := skill_swipe_handoff_cover
	if (
		cover != null
		and is_instance_valid(cover)
		and skill_swipe_animation_mode == "entry"
		and bool(cover.get_meta("swipe_gap_entry_reveal_allowed", false))
	):
		return false
	return true


func _force_skill_detail_reveal_mount_under_cover() -> void:
	if current_screen != "skill":
		return
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		var stats := _skill_detail_visible_module_stats()
		if (
			float(stats.get("scroll_area", 0.0)) >= 100000.0
			and int(stats.get("visible_modules", 0)) <= 0
		):
			detail_actions_scroll.drag_scroll_position = 0.0
			detail_actions_scroll.scroll_vertical = 0
	if detail_lazy_plan.size() > 0:
		var cover := skill_swipe_handoff_cover
		var throttle_by_frame := _skill_swipe_handoff_cover_is_opaque_cream_transition()
		var process_frame := Engine.get_process_frames()
		if (
			throttle_by_frame
			and cover != null
			and is_instance_valid(cover)
			and int(cover.get_meta("swipe_cover_last_lazy_mount_process_frame", -1)) == process_frame
		):
			_sync_detail_actions_scroll_limit()
			_ensure_finalized_skill_detail_presentable(selected_skill_id)
			return
		var mounted := _skill_detail_surface()._sync_detail_lazy_visible_cards(true, DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME)
		if mounted <= 0 and not _skill_detail_stack_is_presentable(_detail_actions_stack() as Control):
			mounted = _skill_detail_surface()._sync_detail_lazy_next_cards(true, DETAIL_LAZY_MOUNT_BUDGET_PER_FRAME)
		if throttle_by_frame and mounted > 0 and cover != null and is_instance_valid(cover):
			cover.set_meta("swipe_cover_last_lazy_mount_process_frame", process_frame)
	_sync_detail_actions_scroll_limit()
	_ensure_finalized_skill_detail_presentable(selected_skill_id)


func _ensure_finalized_skill_detail_presentable(target_skill_id: String) -> bool:
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return false
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		skill_swipe_page.visible = true
		skill_swipe_page.modulate = Color.WHITE
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		detail_actions_scroll.visible = true
		detail_actions_scroll.modulate = Color.WHITE
	var stack := _detail_actions_stack() as VBoxContainer
	if stack != null and is_instance_valid(stack):
		stack.visible = true
		stack.modulate = Color.WHITE
		detail_lazy_stack = stack
	if _skill_detail_stack_is_presentable(stack):
		return true
	if _repair_blank_detail_lazy_stack():
		stack = _detail_actions_stack() as VBoxContainer
		if stack != null and is_instance_valid(stack):
			stack.visible = true
			stack.modulate = Color.WHITE
		return _skill_detail_stack_is_presentable(stack)
	return false


func _discard_incoming_swipe_preview(incoming_preview: Dictionary) -> void:
	var preview_state := incoming_preview.get("state", {}) as Dictionary
	var skill_id := str(preview_state.get("skill_id", ""))
	_skill_swipe_activity_surface()._move_swipe_preview_real_card_cache_to_global(preview_state)
	_skill_swipe_activity_surface()._free_swipe_preview_real_card_cache(preview_state)
	for raw_card in preview_state.get("action_cards", []) as Array:
		var card := raw_card as Dictionary
		if card.is_empty():
			continue
		var heist_id := str(card.get("heist_id", ""))
		if not heist_id.is_empty():
			_discard_action_card_key(_thieving_surface()._thieving_heist_card_key(heist_id))
			continue
		var action := card.get("action", {}) as Dictionary
		var action_id := str(action.get("id", ""))
		if not skill_id.is_empty() and not action_id.is_empty():
			_discard_action_card_key(_action_key(skill_id, action_id))
	if skill_id == "thieving":
		for key in action_cards.keys():
			if str(key).begins_with("thieving_heist:"):
				_discard_action_card_key(str(key))
	var preview_page := incoming_preview.get("page") as Control
	if preview_page != null and is_instance_valid(preview_page):
		preview_page.queue_free()


func _should_promote_incoming_swipe_preview(skill_id: String) -> bool:
	return false


func _prepare_full_rendered_swipe_target_for_cover_clear(target_skill_id: String) -> void:
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	if detail_lazy_plan.is_empty() or detail_lazy_stack == null or not is_instance_valid(detail_lazy_stack):
		return
	_ensure_finalized_skill_detail_presentable(target_skill_id)


func _rebuild_skill_detail_after_preview(restore_detail_scroll := -1) -> void:
	if skills_content == null:
		return
	var target_skill_id := selected_skill_id
	var target_key := _navigation_shell()._skill_detail_cache_key(target_skill_id)
	skill_swipe_pending_full_finalize = false
	skill_swipe_pending_preview_state = {}
	skill_swipe_finalize_ready_process_frame = -1
	skill_swipe_finalize_target_skill_id = ""
	skill_swipe_lazy_finalize_token += 1
	skill_swipe_finalized_lazy_mount_pending = false
	call_deferred("_rebuild_skill_detail_after_preview_deferred", restore_detail_scroll, target_skill_id, target_key)


func _rebuild_skill_detail_after_preview_deferred(restore_detail_scroll: int, target_skill_id: String, target_key: String) -> void:
	if current_screen != "skill" or selected_skill_id != target_skill_id or skills_content == null:
		return
	_kill_transient_tweens_in_subtree(skills_content)
	_skill_swipe_activity_surface()._clear_skill_swipe_preview()
	skill_swipe_frame = null
	skill_swipe_page = null
	_navigation_shell()._reset_page_control_refs()
	_clear_skills_content_orphans()
	await _skill_detail_surface()._render_skill_detail(false, restore_detail_scroll)
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	_normalize_skill_detail_page_layout()
	_finish_render_screen_transition(target_key)
	_fade_clear_skill_swipe_rebuild_cover()
	call_deferred("_apply_pending_swipe_resume_scroll", target_skill_id)


func _skill_swipe_install_target_page(target_key: String, incoming_preview: Dictionary = {}):
	_cancel_detail_lazy_settle_warm_mount()
	skill_swipe_finalize_schedule_token += 1
	skill_swipe_finalize_ready_process_frame = -1
	skill_swipe_finalize_target_skill_id = ""
	skill_swipe_pending_full_finalize = false
	skill_swipe_pending_preview_state = {}
	skill_swipe_finalized_lazy_mount_pending = false
	_hold_skill_detail_layout_refresh_after_navigation()
	_clear_page_transient_input_state()
	_prepare_skills_page_transition(target_key)
	skill_swipe_drag_offset_x = skill_swipe_gap_render_offset_x
	if (
		not incoming_preview.is_empty()
		and _incoming_swipe_preview_usable(incoming_preview)
		and _should_promote_incoming_swipe_preview(selected_skill_id)
	):
		var preview_page := incoming_preview.get("page") as Control
		var preview_state := incoming_preview.get("state", {}) as Dictionary
		_settings_surface()._clear_settings_page_control_refs()
		_kill_transient_tweens_in_subtree(skills_content)
		_skill_swipe_activity_surface()._clear_skill_swipe_preview()
		skill_swipe_frame = null
		skill_swipe_page = null
		_navigation_shell()._reset_page_control_refs()
		_clear_skills_content_orphans()
		_mount_swipe_preview_as_skill_detail(preview_page, preview_state)
		_promote_swipe_preview_to_interactive(preview_state)
		_finish_render_screen_transition(target_key)
		return
	if not incoming_preview.is_empty():
		_discard_incoming_swipe_preview(incoming_preview)
	_settings_surface()._clear_settings_page_control_refs()
	_kill_transient_tweens_in_subtree(skills_content)
	_apply_skills_content_layout_for_screen()
	_skill_swipe_activity_surface()._clear_skill_swipe_preview()
	skill_swipe_frame = null
	skill_swipe_page = null
	_navigation_shell()._reset_page_control_refs()
	_clear_skills_content_orphans()
	var defer_initial_mount := _skill_swipe_handoff_cover_is_opaque_cream_transition()
	skill_swipe_defer_initial_lazy_mount = defer_initial_mount
	await _skill_detail_surface()._render_skill_detail(false, -1)
	_normalize_skill_detail_page_layout()
	if defer_initial_mount:
		_force_skill_detail_reveal_mount_under_cover()
	else:
		_prepare_full_rendered_swipe_target_for_cover_clear(selected_skill_id)
	_finish_render_screen_transition(target_key)
	skill_swipe_defer_initial_lazy_mount = false


func _complete_skill_swipe_navigation() -> void:
	_request_swipe_resume_scroll()
	skill_swipe_animating = false
	skill_swipe_animation_mode = ""
	skill_swipe_drag_offset_x = 0.0
	_reset_skill_swipe_entry_positions()
	_ensure_skill_swipe_frame_centered()
	skill_swipe_strip_committed_crossfade = false
	_sync_skill_strip_page_crossfade(0.0)
	skill_swipe_paper_fade_hold_alpha = 0.0
	_sync_skill_swipe_paper_fade(0.0)
	if skill_swipe_handoff_cover != null and is_instance_valid(skill_swipe_handoff_cover):
		if skill_swipe_pending_full_finalize:
			skill_swipe_outgoing_cover_active = true
		else:
			_fade_clear_skill_swipe_cover(SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS)
	_sync_skill_strip_page_visibility(false)
	if skill_swipe_pending_full_finalize:
		_skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()
	elif not _consume_queued_skill_swipe_navigation():
		_skill_swipe_activity_surface()._queue_skill_swipe_preview_prewarm()
	if current_screen == "skill":
		_fade_skill_page_switch_modules(true, SKILL_SWIPE_PAGE_SWITCH_FADE_IN_SECONDS)
		_fade_skill_swipe_module_utility_row(true, SKILL_SWIPE_MODULE_UTILITY_FADE_IN_SECONDS)
		_fade_skill_shelf_backgrounds(true, SKILL_SWIPE_SHELF_BACKGROUND_FADE_IN_SECONDS)
		call_deferred("_queue_detail_lazy_settle_warm_mount", selected_skill_id)
		_schedule_swipe_preview_finalize_after_navigation()
		if not skill_swipe_pending_full_finalize:
			call_deferred("_apply_pending_swipe_resume_scroll", selected_skill_id)
		if selected_skill_id == TUTORIAL_STARTER_SKILL_ID:
			if _onboarding_runtime()._onboarding_swipe_tip_sequence_resumable() and not onboarding_swipe_tip_sequence_running:
				call_deferred("_run_onboarding_swipe_tip_sequence")
		else:
			_tutorial_overlay_surface()._fade_tip_group("skill_swipe_tip_notes", false, true)
			_onboarding_runtime()._mark_skill_swipe_tip_seen()
			_onboarding_runtime().call_deferred("_maybe_show_onboarding_explore_tip")


func _skill_detail_ready_for_gap_entry() -> bool:
	var stack := _detail_actions_stack() as Control
	if not _skill_detail_stack_is_presentable(stack):
		return false
	return not _skill_detail_has_visible_lazy_placeholders()


func _wait_for_skill_swipe_gap_entry_ready(target_skill_id: String) -> void:
	if target_skill_id.is_empty():
		return
	for _i in range(SKILL_SWIPE_GAP_READY_WAIT_FRAMES):
		if current_screen != "skill" or selected_skill_id != target_skill_id:
			return
		_force_skill_detail_reveal_mount_under_cover()
		if _skill_detail_ready_for_gap_entry():
			return
		await get_tree().process_frame
	if current_screen == "skill" and selected_skill_id == target_skill_id:
		_force_skill_detail_reveal_mount_under_cover()


func _begin_skill_swipe_incoming_entry(start_x: float) -> void:
	_kill_skill_swipe_tween()
	skill_swipe_animating = true
	skill_swipe_animation_mode = "entry"
	_hide_skill_swipe_paper_fade()
	_apply_skill_swipe_drag_offset(start_x)
	skill_swipe_tween = create_tween()
	skill_swipe_tween.tween_method(
		_apply_skill_swipe_drag_offset,
		start_x,
		0.0,
		SKILL_SWIPE_SETTLE_SECONDS
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	skill_swipe_tween.finished.connect(_complete_skill_swipe_navigation)


func _hold_skill_detail_layout_refresh_after_navigation() -> void:
	skill_detail_layout_refresh_hold_until_msec = maxi(
		skill_detail_layout_refresh_hold_until_msec,
		Time.get_ticks_msec() + int((SKILL_SWIPE_SETTLE_SECONDS + 0.35) * 1000.0)
	)


func _finalize_swipe_preview_to_full_detail(target_skill_id := "") -> void:
	if not skill_swipe_pending_full_finalize:
		return
	if not target_skill_id.is_empty() and selected_skill_id != target_skill_id:
		return
	skill_swipe_finalize_ready_process_frame = -1
	skill_swipe_finalize_target_skill_id = ""
	var preview_state := skill_swipe_pending_preview_state
	skill_swipe_pending_preview_state = {}
	var preserve_scroll := _preview_actions_scroll_vertical(preview_state)
	_hold_skill_detail_layout_refresh_after_navigation()
	skill_swipe_lazy_finalize_token += 1
	var token := skill_swipe_lazy_finalize_token
	call_deferred("_finalize_swipe_preview_to_lazy_detail", preview_state, preserve_scroll, selected_skill_id, token)


func _finalize_swipe_preview_to_lazy_detail(preview_state: Dictionary, preserve_scroll: int, target_skill_id: String, token: int) -> void:
	await _skill_detail_surface()._finalize_swipe_preview_to_lazy_detail(preview_state, preserve_scroll, target_skill_id, token)


func _promote_swipe_preview_to_interactive(preview_state: Dictionary) -> void:
	var skill_id := str(preview_state.get("skill_id", selected_skill_id))
	if _fishing_rework_active_for_skill(skill_id):
		_promote_fishing_swipe_preview(preview_state)
	else:
		for raw_card in preview_state.get("action_cards", []) as Array:
			var card := raw_card as Dictionary
			if card.is_empty():
				continue
			var heist_id := str(card.get("heist_id", ""))
			if not heist_id.is_empty():
				_promote_heist_swipe_preview_card(card, heist_id)
				continue
			if bool(card.get("passive", false)):
				_promote_passive_swipe_preview_card(card, skill_id)
				continue
			var action := card.get("action", {}) as Dictionary
			var action_id := str(action.get("id", card.get("action_id", "")))
			if action.is_empty() or action_id.is_empty():
				continue
			_promote_action_swipe_preview_card(card, skill_id, action_id, action)
	if detail_header_body != null and is_instance_valid(detail_header_body):
		_enable_skill_detail_back_arrow(detail_header_body)
		_tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
		_sync_skill_detail_back_arrow_visibility()
		if _onboarding_runtime()._onboarding_auto_run_message_resumable():
			_onboarding_runtime().call_deferred("_run_onboarding_auto_run_message_sequence")
		if _onboarding_runtime()._onboarding_header_reveal_sequence_resumable():
			_onboarding_runtime().call_deferred("_run_onboarding_header_reveal_sequence")
	if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll):
		var actions_clip := _skill_detail_surface()._ensure_skill_detail_actions_clip_wrapper(skill_swipe_page, detail_actions_scroll, _skill_content_width())
		if actions_clip == null or not is_instance_valid(actions_clip):
			actions_clip = detail_actions_scroll.get_parent() as Control
		if actions_clip != null and is_instance_valid(actions_clip):
			_skill_detail_surface()._build_detail_jump_arrows(actions_clip)
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		skill_swipe_page.mouse_filter = Control.MOUSE_FILTER_PASS


func _promote_action_swipe_preview_card(card: Dictionary, skill_id: String, action_id: String, action: Dictionary) -> void:
	if bool(card.get("swipe_promoted", false)):
		return
	card["swipe_promoted"] = true
	var card_root := card.get("root") as Control
	var pop_card := card.get("pop") as Control
	if card_root != null and is_instance_valid(card_root):
		card_root.mouse_filter = Control.MOUSE_FILTER_PASS
	if pop_card != null and is_instance_valid(pop_card):
		pop_card.mouse_filter = Control.MOUSE_FILTER_PASS
	_attach_swipe_preview_activity_button(card, skill_id, action_id, pop_card)
	card["action_id"] = action_id
	card["action"] = action
	card["preview_only"] = false
	_register_action_card(_action_key(skill_id, action_id), card)
	if not bool(card.get("swipe_proxy", false)):
		_detail_lazy_finalize_action_card(card, skill_id, action, action_id)
	detail_action_card_nodes[action_id] = card_root
	if not detail_rendered_action_ids.has(action_id):
		detail_rendered_action_ids.append(action_id)


func _promote_heist_swipe_preview_card(card: Dictionary, heist_id: String) -> void:
	if bool(card.get("swipe_promoted", false)):
		return
	card["swipe_promoted"] = true
	card["preview_only"] = false
	_register_action_card(_thieving_surface()._thieving_heist_card_key(heist_id), card)
	var heist_root := card.get("root") as Control
	if heist_root != null and is_instance_valid(heist_root):
		heist_root.mouse_filter = Control.MOUSE_FILTER_PASS
		var button := card.get("button") as Button
		if button != null and is_instance_valid(button):
			button.mouse_filter = Control.MOUSE_FILTER_STOP
		detail_action_card_nodes["heist:%s" % heist_id] = heist_root
	var track_id := "heist:%s" % heist_id
	if not detail_rendered_action_ids.has(track_id):
		detail_rendered_action_ids.append(track_id)


func _attach_swipe_preview_activity_button(card: Dictionary, skill_id: String, action_id: String, pop_card: Control) -> void:
	if card.get("button") != null:
		var existing := card.get("button") as Button
		if existing != null and is_instance_valid(existing):
			existing.mouse_filter = Control.MOUSE_FILTER_STOP
		return
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.z_index = 218
	button.gui_input.connect(_on_action_card_input.bind(skill_id, action_id, button))
	pop_card.add_child(button)
	card["button"] = button


func _promote_passive_swipe_preview_card(card: Dictionary, skill_id: String) -> void:
	if bool(card.get("swipe_promoted", false)):
		return
	card["swipe_promoted"] = true
	var action := card.get("action", {}) as Dictionary
	var module_id := str(action.get("id", ""))
	if module_id.is_empty():
		return
	var card_root := card.get("root") as Control
	var pop_card := card.get("pop") as Control
	if card_root != null and is_instance_valid(card_root):
		card_root.clip_contents = false
		card_root.mouse_filter = Control.MOUSE_FILTER_PASS
	if pop_card != null and is_instance_valid(pop_card):
		pop_card.mouse_filter = Control.MOUSE_FILTER_PASS
	var loot := card.get("loot") as Control
	if loot != null and is_instance_valid(loot):
		loot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var collect_button := card.get("button") as Button
	if collect_button != null and is_instance_valid(collect_button):
		collect_button.mouse_filter = Control.MOUSE_FILTER_STOP
		collect_button.gui_input.connect(_on_passive_module_button_input.bind("collect", module_id, "", null, collect_button))
		collect_button.pressed.connect(_on_passive_collect_pressed.bind(module_id))
	var info_button := card.get("info_button") as Button
	if info_button != null and is_instance_valid(info_button):
		info_button.mouse_filter = Control.MOUSE_FILTER_STOP
		var info_popover := card.get("info_popover") as Control
		if info_popover != null:
			info_button.gui_input.connect(_on_passive_module_button_input.bind("info", module_id, "", info_popover, info_button))
			info_button.pressed.connect(Callable(_passive_firepit_surface(), "_toggle_passive_info_popover").bind(info_popover))
	var plank_button := card.get("plank") as Button
	if plank_button != null and is_instance_valid(plank_button):
		plank_button.mouse_filter = Control.MOUSE_FILTER_STOP
		plank_button.gui_input.connect(_on_passive_module_button_input.bind("plank", module_id, "", null, plank_button))
		plank_button.pressed.connect(_on_passive_plank_pressed.bind(module_id))
	var upgrade_buttons := card.get("upgrade_buttons", {}) as Dictionary
	for stat_type in upgrade_buttons.keys():
		var upgrade := upgrade_buttons.get(stat_type) as Button
		if upgrade == null or not is_instance_valid(upgrade):
			continue
		upgrade.mouse_filter = Control.MOUSE_FILTER_STOP
		upgrade.gui_input.connect(_on_passive_module_button_input.bind("upgrade", module_id, stat_type, null, upgrade))
		upgrade.pressed.connect(_on_passive_upgrade_pressed.bind(module_id, stat_type))
	card["preview_only"] = false
	_register_action_card(_action_key(skill_id, module_id), card)
	if not bool(card.get("swipe_proxy", false)):
		_passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, _is_action_unlocked(skill_id, action))
	detail_action_card_nodes[module_id] = card_root
	if not detail_rendered_action_ids.has(module_id):
		detail_rendered_action_ids.append(module_id)


func _schedule_proxy_skill_detail_full_refresh(skill_id: String) -> void:
	if skill_id.is_empty():
		return
	call_deferred("_proxy_skill_detail_full_refresh_after_frames", skill_id, main_process_frame_index + SKILL_SWIPE_PROXY_FULL_REFRESH_DELAY_FRAMES)


func _proxy_skill_detail_full_refresh_after_frames(skill_id: String, ready_frame: int) -> void:
	while main_process_frame_index < ready_frame:
		if current_screen != "skill" or selected_skill_id != skill_id:
			return
		await get_tree().process_frame
	if current_screen != "skill" or selected_skill_id != skill_id:
		return
	if skill_swipe_tracking or skill_swipe_animating or skill_swipe_pending_full_finalize:
		call_deferred("_proxy_skill_detail_full_refresh_after_frames", skill_id, main_process_frame_index + 60)
		return
	_refresh_visible_skill_detail_action_list(-1, skill_id, true)


func _promote_fishing_swipe_preview(preview_state: Dictionary) -> void:
	var skill_id := "fishing"
	for raw_card in preview_state.get("action_cards", []) as Array:
		var card := raw_card as Dictionary
		if card.is_empty():
			continue
		var action := card.get("action", {}) as Dictionary
		var action_id := str(action.get("id", card.get("action_id", "")))
		if bool(card.get("passive", false)) or _is_passive_action(action):
			_promote_passive_swipe_preview_card(card, skill_id)
			continue
		if action.is_empty() or action_id.is_empty():
			continue
		_promote_action_swipe_preview_card(card, skill_id, action_id, action)
	for raw_built in preview_state.get("fishing_built_modules", []) as Array:
		var built := raw_built as Dictionary
		if built.is_empty():
			continue
		var area_key := str(built.get("area_key", ""))
		if area_key.is_empty():
			continue
		_register_action_card(area_key, built.get("area_card", {}) as Dictionary)
		var root := built.get("root") as Control
		if root != null and is_instance_valid(root):
			_enable_interactive_control_tree(root)
			for method_id in built.get("method_ids", []) as Array:
				detail_action_card_nodes[str(method_id)] = root
	detail_rendered_action_ids = _fishing_ui_surface()._fishing_detail_render_signature()


func _enable_interactive_control_tree(root: Control) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is Button:
		root.mouse_filter = Control.MOUSE_FILTER_STOP
	elif root.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		root.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in root.get_children():
		var child_control := child as Control
		if child_control != null:
			_enable_interactive_control_tree(child_control)


func _enable_skill_detail_back_arrow(header_body: Control) -> void:
	if header_body == null or not is_instance_valid(header_body):
		return
	for child in header_body.get_children():
		if child is BaseButton:
			var back_button := child as BaseButton
			if not bool(back_button.get_meta("activity_back_button", false)):
				continue
			back_button.visible = false
			back_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if detail_back_button == back_button:
				detail_back_button = null
			continue
		if child is Control and child.get_child_count() > 0:
			_enable_skill_detail_back_arrow(child as Control)


func _navigate_skill_page(offset: int, entry_x := 0.0, animate_entry := true, play_click := true) -> void:
	if not _onboarding_runtime()._swipe_offset_accessible(offset):
		return
	if not skill_strip_ids.is_empty():
		_navigate_skill_strip(offset, entry_x, animate_entry, play_click)
		return
	var current_index := _skill_index(selected_skill_id)
	if current_index < 0:
		return
	var skill_count := skill_defs.size()
	if skill_count <= 0:
		return
	_cancel_stamina_gauge_boost_for_navigation()
	_collapse_expanded_activity_modules()
	var next_index := (current_index + offset) % skill_count
	if next_index < 0:
		next_index += skill_count
	var next_skill_id := str(skill_defs[next_index]["id"])
	if play_click:
		_button_press_runtime().play_default_button_sfx()
	var use_outgoing_animation := animate_entry and absf(entry_x) > 1.0
	var use_gap_load_transition := use_outgoing_animation and SKILL_SWIPE_GAP_LOAD_TRANSITION_ENABLED
	var gap_entry_x := float(signi(offset)) * _skill_swipe_page_span() if use_gap_load_transition else 0.0
	var incoming_preview := {}
	if offset != 0:
		incoming_preview = _skill_swipe_activity_surface()._extract_incoming_swipe_preview(offset)
	_skill_swipe_activity_surface()._park_skill_swipe_preview()
	if offset != 0 and selected_skill_id == TUTORIAL_STARTER_SKILL_ID:
		_onboarding_runtime()._clear_tutorial_gate_latch_only_after_skill_swipe(false)
	if not play_click and not animate_entry and absf(entry_x) <= 1.0:
		_begin_skill_swipe_handoff_cover()
	var transition_cover := _begin_skill_swipe_outgoing_cover() if use_outgoing_animation else null
	if use_outgoing_animation:
		if not use_gap_load_transition:
			_discard_incoming_swipe_preview_for_animated_handoff(incoming_preview)
			incoming_preview = {}
		skill_swipe_animating = true
		skill_swipe_animation_mode = "entry"
		if transition_cover != null and is_instance_valid(transition_cover) and not use_gap_load_transition:
			await _fade_skill_swipe_cover_to_opaque(SKILL_SWIPE_CREAM_COVER_FADE_IN_SECONDS)
		if use_gap_load_transition:
			_hide_skill_swipe_paper_fade()
		_clear_skill_swipe_content_under_cover()
	selected_skill_id = next_skill_id
	current_screen = "skill"
	var target_key := _navigation_shell()._skill_detail_cache_key(next_skill_id)
	skill_swipe_gap_render_offset_x = gap_entry_x
	await _skill_swipe_install_target_page(target_key, incoming_preview)
	if use_gap_load_transition:
		_apply_skill_swipe_drag_offset(gap_entry_x)
		if transition_cover != null and is_instance_valid(transition_cover):
			transition_cover.set_meta("swipe_gap_entry_reveal_allowed", true)
	skill_swipe_gap_render_offset_x = 0.0
	_update_ui(0.0, true)
	if use_gap_load_transition:
		await _wait_for_skill_swipe_gap_entry_ready(next_skill_id)
	if use_outgoing_animation:
		_begin_skill_swipe_incoming_entry(gap_entry_x if use_gap_load_transition else float(signi(offset)) * _skill_swipe_page_span())
		if use_gap_load_transition:
			call_deferred("_release_skill_swipe_gap_cover_when_ready", next_skill_id)
	else:
		_reset_skill_swipe_entry_positions()
		_complete_skill_swipe_navigation()


func _release_skill_swipe_gap_cover_when_ready(target_skill_id: String) -> void:
	await _wait_for_skill_swipe_gap_entry_ready(target_skill_id)
	if current_screen != "skill" or selected_skill_id != target_skill_id:
		return
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		return
	if not bool(cover.get_meta("swipe_gap_entry_reveal_allowed", false)):
		return
	_fade_clear_skill_swipe_cover(SKILL_SWIPE_REBUILD_COVER_FADE_SECONDS)


func _navigate_skill_strip(offset: int, entry_x: float, animate_entry: bool, play_click: bool) -> void:
	var current_index := skill_strip_index
	var skill_count := skill_strip_ids.size()
	var new_index := (current_index + offset) % skill_count
	if new_index < 0:
		new_index += skill_count
	if new_index == current_index:
		return
	_cancel_stamina_gauge_boost_for_navigation()
	_collapse_expanded_activity_modules()
	if play_click:
		_button_press_runtime().play_default_button_sfx()
	var page_width := _skill_content_width()
	var tween_start := entry_x + float(offset) * page_width
	skill_strip_index = new_index
	selected_skill_id = str(skill_strip_ids[new_index])
	current_screen = "skill"
	_swap_skill_strip_refs(selected_skill_id)
	_sync_skill_strip_page_visibility(true)
	_skill_detail_surface()._sync_detail_lazy_visible_cards(true, -1)
	_ensure_finalized_skill_detail_presentable(selected_skill_id)
	_hold_skill_detail_layout_refresh_after_navigation()
	_clear_page_transient_input_state()
	_update_ui(0.0, true)
	if animate_entry and absf(entry_x) > 1.0:
		_kill_skill_swipe_tween()
		_restore_skill_strip_wrap_page()
		_apply_skill_swipe_drag_offset(tween_start)
		skill_swipe_animating = true
		skill_swipe_animation_mode = "entry"
		skill_swipe_tween = create_tween()
		skill_swipe_tween.tween_method(
			_apply_skill_swipe_drag_offset,
			tween_start,
			0.0,
			SKILL_SWIPE_SETTLE_SECONDS
		).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		skill_swipe_tween.finished.connect(_complete_skill_swipe_navigation)
	else:
		_complete_skill_swipe_navigation()


func _complete_passive_module_tip_page_visit(skill_id := selected_skill_id) -> void:
	if passive_module_tip_seen or skill_id != "woodcutting":
		return
	if get_tree().get_nodes_in_group("passive_module_tip_notes").is_empty():
		return
	passive_module_tip_seen = true
	_tutorial_overlay_surface()._fade_tip_group("passive_module_tip_notes")
	save_game()


func _ensure_silver_opportunity_tip_anchor() -> void:
	if silver_opportunity_tip_seen or not silver_opportunity_tip_action_key.is_empty():
		return
	for raw_skill_def in skill_defs:
		var skill_id := str((raw_skill_def as Dictionary).get("id", ""))
		if skill_id.is_empty() or _fishing_rework_active_for_skill(skill_id):
			continue
		for raw_action in actions_by_skill.get(skill_id, []):
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			if MasteryState.level(mastery, _action_key(skill_id, action_id)) >= ACTION_OPPORTUNITY_MIN_MEDAL_LEVEL:
				silver_opportunity_tip_action_key = _action_key(skill_id, action_id)
				return


func _register_silver_opportunity_tip_anchor(skill_id: String, action_id: String, old_level: int, new_level: int) -> void:
	if silver_opportunity_tip_seen or not silver_opportunity_tip_action_key.is_empty():
		return
	if _fishing_rework_active_for_skill(skill_id):
		return
	if old_level >= ACTION_OPPORTUNITY_MIN_MEDAL_LEVEL or new_level < ACTION_OPPORTUNITY_MIN_MEDAL_LEVEL:
		return
	silver_opportunity_tip_action_key = _action_key(skill_id, action_id)
	_insert_silver_opportunity_tip_for_action(skill_id, action_id)
	_mark_save_dirty("silver opportunity tip")


func _insert_silver_opportunity_tip_for_action(skill_id: String, action_id: String) -> void:
	if current_screen != "skill" or selected_skill_id != skill_id or silver_opportunity_tip_seen:
		return
	var stack := _detail_actions_stack() as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		return
	if _tutorial_note_group_has_node_in_stack("silver_opportunity_tip_notes", stack):
		return
	var anchor := _detail_stack_child_for_action(action_id)
	if anchor == null or not is_instance_valid(anchor) or anchor.get_parent() != stack:
		return
	var content_width := _skill_content_width()
	var actions_width := maxf(content_width, maxf(stack.custom_minimum_size.x, stack.size.x))
	var entry := _detail_eager_add_smooth_tutorial_tip(stack, _silver_opportunity_tip_note(content_width), content_width, actions_width, "silver_opportunity_tip_notes")
	if entry != null and is_instance_valid(entry) and entry.get_parent() == stack:
		stack.move_child(entry, clampi(anchor.get_index() + 1, 0, maxi(0, stack.get_child_count() - 1)))


func _complete_silver_opportunity_tip_for_action(skill_id: String, action_id: String) -> void:
	if silver_opportunity_tip_seen:
		return
	_ensure_silver_opportunity_tip_anchor()
	if silver_opportunity_tip_action_key.is_empty():
		silver_opportunity_tip_action_key = _action_key(skill_id, action_id)
	silver_opportunity_tip_seen = true
	_tutorial_overlay_surface()._fade_tip_group("silver_opportunity_tip_notes", false, true)
	save_game()


func _complete_silver_opportunity_tip_page_visit(skill_id := selected_skill_id) -> void:
	if silver_opportunity_tip_seen:
		return
	if get_tree().get_nodes_in_group("silver_opportunity_tip_notes").is_empty():
		return
	if not silver_opportunity_tip_action_key.is_empty() and not silver_opportunity_tip_action_key.begins_with("%s:" % skill_id):
		return
	silver_opportunity_tip_seen = true
	_tutorial_overlay_surface()._fade_tip_group("silver_opportunity_tip_notes")
	save_game()


func _fade_in_post_onboarding_bottom_chrome() -> void:
	if not onboarding_tutorial_complete:
		return
	_navigation_shell().module_utility_collapsed = true
	_profile_chat_overlay_surface()._ensure_chat_strip()
	_profile_chat_overlay_surface()._update_chat_strip(true)
	_navigation_shell()._sync_module_utility_row_visibility(false)
	if post_onboarding_bottom_chrome_fade_tween != null and post_onboarding_bottom_chrome_fade_tween.is_valid():
		post_onboarding_bottom_chrome_fade_tween.kill()
	post_onboarding_bottom_chrome_fade_tween = null
	var fade_targets := []
	for raw_control in [chat_strip, _navigation_shell().module_utility_row]:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control) or not control.visible:
			continue
		control.modulate.a = 0.0
		fade_targets.append(control)
	if fade_targets.is_empty():
		return
	post_onboarding_bottom_chrome_fade_tween = create_tween()
	var first := fade_targets[0] as Control
	post_onboarding_bottom_chrome_fade_tween.tween_property(first, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for index in range(1, fade_targets.size()):
		var control := fade_targets[index] as Control
		post_onboarding_bottom_chrome_fade_tween.parallel().tween_property(control, "modulate:a", 1.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	post_onboarding_bottom_chrome_fade_tween.finished.connect(_finish_post_onboarding_bottom_chrome_fade)


func _finish_post_onboarding_bottom_chrome_fade() -> void:
	post_onboarding_bottom_chrome_fade_tween = null


func _queue_locked_activity_preview_reveal_if_needed(previously_available: bool) -> void:
	if previously_available or not _locked_activity_preview_available():
		return
	if _pending_activity_has_readiness_for_skill(selected_skill_id) or activity_unlock_ceremony_count > 0:
		return
	if (
		current_screen == "skill"
		and selected_skill_id == TUTORIAL_STARTER_SKILL_ID
		and _onboarding_runtime()._onboarding_path_active()
		and not onboarding_first_module_center_released
	):
		onboarding_first_module_center_release_pending = true
	_queue_locked_activity_preview_reveal()


func _queue_locked_activity_preview_reveal() -> void:
	locked_activity_preview_reveal_skill_ids.clear()
	var first_locked_id := _onboarding_runtime()._tutorial_current_locked_preview_action_id(selected_skill_id) if not selected_skill_id.is_empty() else ""
	var preview_key := _action_key(selected_skill_id, first_locked_id) if not first_locked_id.is_empty() else ""
	if not preview_key.is_empty() and not bool(locked_activity_preview_played_action_keys.get(preview_key, false)):
		locked_activity_preview_reveal_skill_ids[selected_skill_id] = true
	locked_activity_preview_reveal_pending = not locked_activity_preview_reveal_skill_ids.is_empty()
	if locked_activity_preview_reveal_pending:
		locked_activity_preview_fade_play_pending = true
		_skill_swipe_activity_surface()._clear_skill_swipe_preview()


func _skill_swipe_tip_present() -> bool:
	if (
		onboarding_swipe_overlay_tip_root != null
		and is_instance_valid(onboarding_swipe_overlay_tip_root)
		and onboarding_swipe_overlay_tip_root.is_inside_tree()
	):
		return true
	for node in get_tree().get_nodes_in_group("skill_swipe_tip_notes"):
		var tip := node as Control
		if tip != null and is_instance_valid(tip) and tip.is_inside_tree():
			return true
	return false


func _show_skill_swipe_tip_note_if_needed() -> void:
	if not _onboarding_runtime()._skill_swipe_tip_available() or skill_swipe_tip_seen:
		return
	call_deferred("_run_onboarding_swipe_tip_sequence")


func _resolve_skill_swipe_tip_stack() -> VBoxContainer:
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return null
	if detail_actions_scroll.get_child_count() <= 0:
		return null
	return detail_actions_scroll.get_child(0) as VBoxContainer


func _mount_skill_swipe_tip_note() -> Control:
	var stack := _resolve_skill_swipe_tip_stack()
	if stack == null:
		return null
	for node in get_tree().get_nodes_in_group("skill_swipe_tip_notes"):
		var existing := node as Control
		if existing == null or not is_instance_valid(existing):
			continue
		if _tutorial_note_is_in_stack(existing, stack):
			onboarding_swipe_overlay_tip_root = null
			_ensure_onboarding_page_switch_module_faded_in(stack)
			return existing
		if existing == onboarding_swipe_overlay_tip_root:
			onboarding_swipe_overlay_tip_root = existing
			_fade_out_onboarding_swipe_overlay_tip(0.12)
	var content_width := _skill_content_width()
	var note := _skill_swipe_tip_note(content_width)
	note.modulate = Color(1, 1, 1, 0)
	_detail_eager_add_skill_swipe_tip_after_anchor(stack, note, content_width, content_width)
	_ensure_onboarding_page_switch_module_faded_in(stack)
	onboarding_swipe_overlay_tip_root = null
	return note


func _fade_in_skill_swipe_tip_note(note: Control):
	if note == null or not is_instance_valid(note):
		return
	note.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(note, "modulate:a", 1.0, ONBOARDING_BOTTOM_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished


func _wait_for_skill_swipe_tip_stack(attempt := 0) -> VBoxContainer:
	var stack := _resolve_skill_swipe_tip_stack()
	if stack != null:
		return stack
	if attempt >= 45:
		return null
	await get_tree().process_frame
	var next_stack := await _wait_for_skill_swipe_tip_stack(attempt + 1)
	return next_stack


func _run_onboarding_swipe_tip_sequence() -> void:
	if not _onboarding_runtime()._onboarding_swipe_tip_sequence_resumable():
		return
	if onboarding_swipe_tip_sequence_running:
		return
	onboarding_swipe_tip_sequence_running = true
	for attempt in range(20):
		if not _onboarding_runtime()._onboarding_swipe_tip_sequence_resumable():
			onboarding_swipe_tip_sequence_running = false
			return
		var note := _mount_skill_swipe_tip_note()
		if note != null and is_instance_valid(note):
			if note.modulate.a < 0.99:
				await _fade_in_skill_swipe_tip_note(note)
			onboarding_swipe_tip_sequence_running = false
			return
		await get_tree().process_frame
	onboarding_swipe_tip_sequence_running = false
	call_deferred("_run_onboarding_swipe_tip_sequence")


func _mount_onboarding_explore_tip_note() -> Control:
	for node in get_tree().get_nodes_in_group("onboarding_explore_tip_notes"):
		var existing := node as Control
		if existing == null or not is_instance_valid(existing):
			continue
		if _tutorial_note_is_in_stack(existing, _resolve_skill_swipe_tip_stack()):
			existing.queue_free()
			continue
		_position_onboarding_explore_tip(existing)
		return existing
	var overlay_parent := _onboarding_detail_overlay_parent()
	if overlay_parent == null:
		return null
	var note := _tutorial_overlay_surface()._create_onboarding_overlay_tip(
		"Other skills have unique rules and content to explore.\nHave fun!",
		"onboarding_explore_tip_notes",
		BOTTOM_TUTORIAL_TIP_FONT_SIZE
	)
	note.visible = false
	note.modulate = Color(1, 1, 1, 0)
	overlay_parent.add_child(note)
	_position_onboarding_explore_tip(note)
	_set_canvas_item_visible_if_changed(note, true)
	call_deferred("_sync_detail_actions_scroll_limit_deferred")
	return note


func _position_onboarding_explore_tip(tip: Control) -> void:
	if tip == null or not is_instance_valid(tip):
		return
	if bool(tip.get_meta("onboarding_explore_tip_position_locked", false)):
		return
	var overlay_parent := _onboarding_detail_overlay_parent()
	if overlay_parent == null:
		return
	var anchor := _lowest_visible_module_stack_child()
	if anchor == null:
		_tutorial_overlay_surface()._position_onboarding_overlay_tip_near_detail_bottom(tip, 70.0)
		return
	var anchor_rect := anchor.get_global_rect()
	var parent_rect := overlay_parent.get_global_rect()
	var detail_rect := detail_actions_scroll.get_global_rect() if detail_actions_scroll != null and is_instance_valid(detail_actions_scroll) else parent_rect
	var tip_size := tip.size
	if tip_size.y <= 1.0:
		tip_size = tip.get_combined_minimum_size()
	var x := anchor_rect.position.x - parent_rect.position.x + (anchor_rect.size.x - tip_size.x) * 0.5
	var y := anchor_rect.end.y - parent_rect.position.y + 34.0
	var max_y := detail_rect.end.y - parent_rect.position.y - tip_size.y - 58.0
	tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tip.position = Vector2(x, minf(y, max_y))
	tip.size = tip_size


func _lowest_visible_module_stack_child() -> Control:
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return null
	var best: Control = null
	var best_bottom := -INF
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null or not is_instance_valid(child):
			continue
		if not _detail_stack_child_is_module_content(child):
			continue
		var rect := child.get_global_rect()
		if rect.size.y <= 1.0:
			continue
		if rect.end.y > best_bottom:
			best_bottom = rect.end.y
			best = child
	return best


func _fade_in_onboarding_explore_tip_note(note: Control):
	if note == null or not is_instance_valid(note):
		return
	note.set_meta("onboarding_explore_tip_position_locked", false)
	_position_onboarding_explore_tip(note)
	_set_canvas_item_visible_if_changed(note, true)
	note.set_meta("onboarding_explore_tip_position_locked", true)
	note.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(note, "modulate:a", 1.0, ONBOARDING_BOTTOM_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished


func _run_onboarding_explore_tip_sequence() -> void:
	if onboarding_tutorial_complete:
		return
	if selected_skill_id == TUTORIAL_STARTER_SKILL_ID:
		return
	if onboarding_explore_tip_sequence_running:
		return
	onboarding_explore_tip_sequence_running = true
	var note := _mount_onboarding_explore_tip_note()
	if note != null and is_instance_valid(note):
		await get_tree().process_frame
		if note.modulate.a < 0.99:
			await _fade_in_onboarding_explore_tip_note(note)
		if not onboarding_explore_tip_seen:
			onboarding_explore_tip_seen = true
			save_game()
	else:
		call_deferred("_run_onboarding_explore_tip_sequence")
	onboarding_explore_tip_sequence_running = false


func _show_lock_click_tip_note_if_needed() -> void:
	if not _skill_detail_shows_tutorial_tips():
		return
	if current_screen != "skill" or detail_actions_scroll == null or lock_click_tip_seen:
		return
	if not get_tree().get_nodes_in_group("lock_click_tip_notes").is_empty():
		return
	var stack := _detail_actions_stack() as VBoxContainer
	if stack == null:
		return
	for action in _visible_actions_for_skill(selected_skill_id):
		var action_data := action as Dictionary
		if not _should_show_lock_click_tip(selected_skill_id, action_data):
			continue
		var action_id := str(action_data.get("id", ""))
		if action_id.is_empty() or not detail_action_card_nodes.has(action_id):
			continue
		var card_node := detail_action_card_nodes[action_id] as Control
		if card_node == null or not is_instance_valid(card_node):
			continue
		var note := _lock_click_tip_note(_skill_content_width())
		note.modulate = Color(1, 1, 1, 0)
		stack.add_child(note)
		stack.move_child(note, clampi(card_node.get_index() + 1, 0, stack.get_child_count() - 1))
		var tween := create_tween()
		tween.tween_property(note, "modulate:a", 1.0, TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		return


func _resolve_detail_lazy_stack() -> VBoxContainer:
	if detail_lazy_stack != null and is_instance_valid(detail_lazy_stack):
		return detail_lazy_stack
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return null
	if detail_actions_scroll.get_child_count() <= 0:
		return null
	return detail_actions_scroll.get_child(0) as VBoxContainer


func _card_for_action_id(skill_id: String, action_id: String) -> Dictionary:
	if skill_id.is_empty() or action_id.is_empty():
		return {}
	var key := _action_key(skill_id, action_id)
	if action_cards.has(key):
		return action_cards[key] as Dictionary
	return {}


func _onboarding_detail_overlay_parent() -> Control:
	return _activity_start_highlight_overlay_parent()


func _remove_onboarding_stack_mastery_tip_legacy() -> void:
	for node in get_tree().get_nodes_in_group("onboarding_mastery_tip_notes"):
		var tip := node as Control
		if tip != null and is_instance_valid(tip) and tip.get_parent() is VBoxContainer:
			tip.queue_free()
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root):
		if onboarding_mastery_tip_root.get_parent() is VBoxContainer:
			onboarding_mastery_tip_root.queue_free()
			onboarding_mastery_tip_root = null


func _remove_onboarding_mastery_tip() -> void:
	_remove_onboarding_stack_mastery_tip_legacy()
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root):
		onboarding_mastery_tip_root.queue_free()
	onboarding_mastery_tip_root = null


func _remove_onboarding_medal_tip() -> void:
	if onboarding_medal_tip_root != null and is_instance_valid(onboarding_medal_tip_root):
		onboarding_medal_tip_root.queue_free()
	onboarding_medal_tip_root = null


func _remove_onboarding_swipe_overlay_tip() -> void:
	if onboarding_swipe_overlay_tip_root != null and is_instance_valid(onboarding_swipe_overlay_tip_root):
		onboarding_swipe_overlay_tip_root.queue_free()
	onboarding_swipe_overlay_tip_root = null


func _remove_onboarding_level_up_tip() -> void:
	if onboarding_level_up_tip_root != null and is_instance_valid(onboarding_level_up_tip_root):
		onboarding_level_up_tip_root.queue_free()
	onboarding_level_up_tip_root = null


func _ensure_onboarding_mastery_tip_note() -> Control:
	if onboarding_mastery_tip_dismissed:
		return null
	_remove_onboarding_stack_mastery_tip_legacy()
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root):
		return onboarding_mastery_tip_root
	for node in get_tree().get_nodes_in_group("onboarding_mastery_tip_notes"):
		var existing := node as Control
		if existing != null and is_instance_valid(existing) and not existing.get_parent() is VBoxContainer:
			onboarding_mastery_tip_root = existing
			return existing
	var starter_card := _card_for_action_id(TUTORIAL_STARTER_SKILL_ID, TUTORIAL_STARTER_ACTION_ID)
	var card_root := starter_card.get("root") as Control if not starter_card.is_empty() else null
	var overlay_parent := _onboarding_detail_overlay_parent()
	if card_root == null or overlay_parent == null:
		return null
	_begin_activity_start_highlight_frame_clip_override()
	var note := _tutorial_overlay_surface()._create_onboarding_overlay_tip(
		"Gain mastery by completing actions.",
		"onboarding_mastery_tip_notes",
		BOTTOM_TUTORIAL_TIP_FONT_SIZE
	)
	note.modulate.a = 0.0
	overlay_parent.add_child(note)
	_tutorial_overlay_surface()._position_onboarding_overlay_tip_above_card(note, card_root, ONBOARDING_MASTERY_TIP_ABOVE_CARD_GAP)
	onboarding_mastery_tip_root = note
	return note


func _ensure_onboarding_medal_tip_note() -> Control:
	if onboarding_medal_tip_shown and onboarding_medal_tip_root == null:
		return null
	if onboarding_medal_tip_root != null and is_instance_valid(onboarding_medal_tip_root):
		return onboarding_medal_tip_root
	for node in get_tree().get_nodes_in_group("onboarding_medal_tip_notes"):
		var existing := node as Control
		if existing != null and is_instance_valid(existing):
			onboarding_medal_tip_root = existing
			return existing
	var starter_card := _card_for_action_id(TUTORIAL_STARTER_SKILL_ID, TUTORIAL_STARTER_ACTION_ID)
	var card_root := starter_card.get("root") as Control if not starter_card.is_empty() else null
	var overlay_parent := _onboarding_detail_overlay_parent()
	if card_root == null or overlay_parent == null:
		return null
	_begin_activity_start_highlight_frame_clip_override()
	var note := _tutorial_overlay_surface()._create_onboarding_overlay_tip(
		"Medals improve your activity stats.",
		"onboarding_medal_tip_notes"
	)
	note.modulate.a = 0.0
	overlay_parent.add_child(note)
	_tutorial_overlay_surface()._position_onboarding_overlay_tip_above_card(note, card_root, ONBOARDING_MASTERY_OVERLAY_TIP_GAP)
	onboarding_medal_tip_root = note
	return note


func _ensure_onboarding_level_up_tip(card: Dictionary) -> Control:
	if onboarding_level_up_tip_root != null and is_instance_valid(onboarding_level_up_tip_root):
		return onboarding_level_up_tip_root
	var card_root := card.get("root") as Control
	var overlay_parent := _onboarding_detail_overlay_parent()
	if card_root == null or overlay_parent == null:
		return null
	_begin_activity_start_highlight_frame_clip_override()
	var note := _tutorial_overlay_surface()._create_onboarding_overlay_tip(
		"Level up to reach harder activities.",
		"onboarding_level_up_tip_notes",
		BOTTOM_TUTORIAL_TIP_FONT_SIZE
	)
	note.modulate.a = 0.0
	overlay_parent.add_child(note)
	_tutorial_overlay_surface()._position_onboarding_overlay_tip_below_card(note, card_root, ONBOARDING_LEVEL_UP_OVERLAY_TIP_GAP)
	onboarding_level_up_tip_root = note
	return note


func _sync_onboarding_mastery_tip_position() -> void:
	if onboarding_mastery_tip_root == null or not is_instance_valid(onboarding_mastery_tip_root):
		return
	var starter_card := _card_for_action_id(TUTORIAL_STARTER_SKILL_ID, TUTORIAL_STARTER_ACTION_ID)
	var card_root := starter_card.get("root") as Control if not starter_card.is_empty() else null
	if card_root == null:
		return
	_tutorial_overlay_surface()._position_onboarding_overlay_tip_above_card(
		onboarding_mastery_tip_root,
		card_root,
		ONBOARDING_MASTERY_TIP_ABOVE_CARD_GAP
	)


func _sync_onboarding_medal_tip_position() -> void:
	if onboarding_medal_tip_root == null or not is_instance_valid(onboarding_medal_tip_root):
		return
	var starter_card := _card_for_action_id(TUTORIAL_STARTER_SKILL_ID, TUTORIAL_STARTER_ACTION_ID)
	var card_root := starter_card.get("root") as Control if not starter_card.is_empty() else null
	if card_root == null:
		return
	_tutorial_overlay_surface()._position_onboarding_overlay_tip_above_card(
		onboarding_medal_tip_root,
		card_root,
		ONBOARDING_MASTERY_OVERLAY_TIP_GAP
	)


func _sync_onboarding_level_up_tip_position(card: Dictionary) -> void:
	if onboarding_level_up_tip_root == null or not is_instance_valid(onboarding_level_up_tip_root):
		return
	var card_root := card.get("root") as Control
	if card_root == null or not is_instance_valid(card_root):
		return
	_tutorial_overlay_surface()._position_onboarding_overlay_tip_below_card(
		onboarding_level_up_tip_root,
		card_root,
		ONBOARDING_LEVEL_UP_OVERLAY_TIP_GAP
	)


func _sync_onboarding_overlay_tips() -> void:
	if selected_skill_id != TUTORIAL_STARTER_SKILL_ID:
		_remove_onboarding_level_up_tip()
		for node in get_tree().get_nodes_in_group("onboarding_explore_tip_notes"):
			var explore_tip := node as Control
			if explore_tip != null and is_instance_valid(explore_tip):
				_position_onboarding_explore_tip(explore_tip)
		return
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root) and not onboarding_mastery_tip_dismissed:
		_sync_onboarding_mastery_tip_position()
	if onboarding_medal_tip_root != null and is_instance_valid(onboarding_medal_tip_root):
		_sync_onboarding_medal_tip_position()
	if onboarding_level_up_tip_root != null and is_instance_valid(onboarding_level_up_tip_root):
		var locked_id := _onboarding_runtime()._tutorial_current_locked_preview_action_id(TUTORIAL_STARTER_SKILL_ID)
		var locked_card := _card_for_action_id(TUTORIAL_STARTER_SKILL_ID, locked_id)
		if not locked_card.is_empty():
			_sync_onboarding_level_up_tip_position(locked_card)
	if onboarding_swipe_overlay_tip_root != null and is_instance_valid(onboarding_swipe_overlay_tip_root):
		_sync_onboarding_swipe_tip_position()


func _sync_onboarding_swipe_tip_position() -> void:
	_tutorial_overlay_surface()._position_onboarding_overlay_tip_near_detail_bottom(onboarding_swipe_overlay_tip_root, 70.0)


func _resync_onboarding_skill_detail_after_navigation() -> void:
	if current_screen != "skill" or not _onboarding_runtime()._onboarding_path_active():
		return
	await get_tree().process_frame
	if current_screen != "skill" or not _onboarding_runtime()._onboarding_path_active():
		return
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if card == null or str(card.get("skill_id", selected_skill_id)) != selected_skill_id:
			continue
		var action := card.get("action", {}) as Dictionary
		if action.is_empty():
			continue
		card.erase("lock_overlay_sync_key")
		_skill_detail_surface()._sync_activity_lock_overlay(card, action, _is_action_unlocked(selected_skill_id, action))
		_tutorial_overlay_surface()._apply_onboarding_fight_action_card_stats_visibility(card, selected_skill_id)
	_tutorial_overlay_surface()._apply_onboarding_fight_header_visibility()
	_tutorial_overlay_surface()._apply_onboarding_fight_action_stats_visibility_all()
	_sync_skill_detail_back_arrow_visibility()
	if _onboarding_runtime()._onboarding_auto_run_message_resumable():
		_onboarding_runtime().call_deferred("_run_onboarding_auto_run_message_sequence")
	elif _onboarding_runtime()._onboarding_header_reveal_sequence_resumable():
		_onboarding_runtime().call_deferred("_run_onboarding_header_reveal_sequence")
	elif onboarding_fight_stamina_revealed and not stamina_gauge_tip_seen and _onboarding_runtime()._onboarding_fight_header_sequence_active():
		_onboarding_runtime().call_deferred("_run_onboarding_stamina_tip_sequence")
	elif _onboarding_runtime()._onboarding_swipe_tip_sequence_resumable():
		call_deferred("_run_onboarding_swipe_tip_sequence")
	elif selected_skill_id != TUTORIAL_STARTER_SKILL_ID:
		_onboarding_runtime().call_deferred("_maybe_show_onboarding_explore_tip")
	if _skill_detail_shows_tutorial_tips():
		_show_lock_click_tip_note_if_needed()
	_sync_onboarding_overlay_tips()


func _fade_out_onboarding_mastery_tip(duration: float) -> void:
	if onboarding_mastery_tip_dismissed:
		return
	onboarding_mastery_tip_dismissed = true
	var tip := onboarding_mastery_tip_root
	if tip == null or not is_instance_valid(tip):
		onboarding_mastery_tip_root = null
		return
	var tween := create_tween()
	tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "mastery"))


func _fade_out_onboarding_medal_tip(duration: float) -> void:
	if not onboarding_medal_tip_shown and onboarding_medal_tip_root == null:
		return
	onboarding_medal_tip_shown = true
	var tip := onboarding_medal_tip_root
	if tip == null or not is_instance_valid(tip):
		onboarding_medal_tip_root = null
		return
	var tween := create_tween()
	tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "medal"))


func _fade_out_onboarding_level_up_tip(duration: float = ACTIVITY_PREVIEW_FADE_IN_SECONDS) -> void:
	var tip := onboarding_level_up_tip_root
	if tip == null or not is_instance_valid(tip):
		onboarding_level_up_tip_root = null
		return
	onboarding_level_up_tip_root = null
	var tween := create_tween()
	tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "level_up"))


func _fade_out_onboarding_swipe_overlay_tip(duration: float = ONBOARDING_BOTTOM_TIP_FADE_SECONDS) -> void:
	var tip := onboarding_swipe_overlay_tip_root
	if tip == null or not is_instance_valid(tip):
		onboarding_swipe_overlay_tip_root = null
		return
	var tween := create_tween()
	tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "swipe"))


func _fade_out_onboarding_explore_tip(duration: float = ONBOARDING_BOTTOM_TIP_FADE_SECONDS) -> void:
	for node in get_tree().get_nodes_in_group("onboarding_explore_tip_notes"):
		var tip := node as Control
		if tip == null or not is_instance_valid(tip) or tip.is_queued_for_deletion():
			continue
		_position_onboarding_explore_tip(tip)
		tip.set_meta("onboarding_explore_tip_position_locked", true)
		_reparent_tip_to_unclipped_fade_layer(tip)
		tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween := create_tween()
		tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "explore"))


func _reparent_tip_to_unclipped_fade_layer(tip: Control) -> void:
	if tip == null or not is_instance_valid(tip):
		return
	var current_parent := tip.get_parent()
	if current_parent == self:
		return
	var global_rect := tip.get_global_rect()
	if current_parent != null:
		current_parent.remove_child(tip)
	add_child(tip)
	tip.z_as_relative = false
	tip.z_index = 4095
	tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var parent_origin := Vector2.ZERO
	if self is Control:
		parent_origin = (self as Control).get_global_rect().position
	tip.position = global_rect.position - parent_origin
	tip.size = global_rect.size
	tip.clip_contents = false
	_set_canvas_item_visible_if_changed(tip, true)


func _finish_onboarding_tip_fade(tip_id: int, tip_kind: String) -> void:
	var tip := _valid_control_ref(instance_from_id(tip_id))
	if tip != null:
		tip.queue_free()
	match tip_kind:
		"mastery":
			onboarding_mastery_tip_root = null
		"medal":
			onboarding_medal_tip_root = null
		"level_up":
			onboarding_level_up_tip_root = null
		"swipe":
			onboarding_swipe_overlay_tip_root = null
		"explore":
			onboarding_explore_tip_sequence_running = false


func _maybe_show_onboarding_medal_tip(old_level: int, new_level: int, skill_id: String, action_id: String) -> void:
	if onboarding_medal_tip_shown:
		return
	if not _onboarding_runtime()._onboarding_path_active():
		return
	if skill_id != TUTORIAL_STARTER_SKILL_ID or action_id != TUTORIAL_STARTER_ACTION_ID:
		return
	if old_level >= 1 or new_level < 1:
		return
	call_deferred("_run_onboarding_medal_tip_sequence")


func _run_onboarding_medal_tip_sequence() -> void:
	if onboarding_medal_tip_shown:
		return
	if not _onboarding_runtime()._onboarding_path_active():
		return
	if selected_skill_id != TUTORIAL_STARTER_SKILL_ID:
		return
	if (
		onboarding_mastery_tip_root != null
		and is_instance_valid(onboarding_mastery_tip_root)
		and not onboarding_mastery_tip_dismissed
	):
		_fade_out_onboarding_mastery_tip(0.45)
		await get_tree().create_timer(0.22).timeout
	var note := _ensure_onboarding_medal_tip_note()
	if note != null and is_instance_valid(note):
		var tween := create_tween()
		tween.tween_property(note, "modulate:a", 1.0, ONBOARDING_FIGHT_ACTION_STATS_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
		onboarding_medal_tip_shown = true
		save_game()
		await get_tree().create_timer(ONBOARDING_MEDAL_TIP_LINGER_SECONDS).timeout
		if onboarding_medal_tip_root != null and is_instance_valid(onboarding_medal_tip_root):
			_fade_out_onboarding_medal_tip(ONBOARDING_BOTTOM_TIP_FADE_SECONDS)


func _activity_start_tutorial_active() -> bool:
	return (
		current_screen == "skill"
		and _skill_detail_shows_tutorial_tips()
		and not activity_start_tip_seen
		and selected_skill_id == TUTORIAL_STARTER_SKILL_ID
	)


func _activity_start_inline_tip_available(skill_id: String = selected_skill_id) -> bool:
	if activity_start_tip_seen:
		return false
	if not _skill_detail_shows_tutorial_tips(skill_id):
		return false
	if _onboarding_runtime()._tutorial_starter_only_detail_active(skill_id):
		return true
	return skill_id != TUTORIAL_STARTER_SKILL_ID


func _tutorial_starter_action_key() -> String:
	return _action_key(TUTORIAL_STARTER_SKILL_ID, TUTORIAL_STARTER_ACTION_ID)


func _activity_start_tip_note(content_width: float) -> Control:
	return _tutorial_overlay_surface()._bottom_tutorial_tip_note(
		content_width,
		"Click an activity to start doing it.",
		"activity_start_tip_notes"
	)


func _fade_in_activity_start_tip_note(note: Control) -> void:
	if note == null or not is_instance_valid(note):
		return
	note.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(note, "modulate:a", 1.0, ACTIVITY_START_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _schedule_activity_start_highlight_if_needed(skill_id: String, action_id: String) -> void:
	if skill_id != TUTORIAL_STARTER_SKILL_ID or action_id != TUTORIAL_STARTER_ACTION_ID:
		return
	if not _activity_start_tutorial_active():
		return
	if activity_start_highlight_pending or activity_start_highlight_active:
		return
	call_deferred("_schedule_activity_start_highlight")


func _schedule_activity_start_highlight() -> void:
	if not _activity_start_tutorial_active():
		return
	activity_start_highlight_token += 1
	activity_start_highlight_pending = true
	var token := activity_start_highlight_token
	_run_activity_start_highlight_schedule(token)


func _run_activity_start_highlight_schedule(token: int) -> void:
	await get_tree().create_timer(ACTIVITY_START_HIGHLIGHT_DELAY_SECONDS).timeout
	if token != activity_start_highlight_token:
		return
	if not activity_start_highlight_pending or not _activity_start_tutorial_active():
		activity_start_highlight_pending = false
		return
	activity_start_highlight_pending = false
	_begin_activity_start_highlight_fade_in(token, 0)


func _begin_activity_start_highlight_fade_in(token: int, attempt: int) -> void:
	if token != activity_start_highlight_token or not _activity_start_tutorial_active():
		return
	var key := _tutorial_starter_action_key()
	if not action_cards.has(key):
		if attempt >= 90:
			return
		await get_tree().process_frame
		_begin_activity_start_highlight_fade_in(token, attempt + 1)
		return
	var card := action_cards[key] as Dictionary
	_attach_activity_start_highlight_border(card)
	activity_start_highlight_active = true
	activity_start_highlight_card_key = key
	var border := activity_start_highlight_border
	if border == null or not is_instance_valid(border):
		return
	border.set_glow_alpha(0.0)
	if activity_start_highlight_fade_tween != null:
		activity_start_highlight_fade_tween.kill()
	activity_start_highlight_fade_tween = create_tween()
	activity_start_highlight_fade_tween.tween_method(
		border.set_glow_alpha,
		0.0,
		1.0,
		ACTIVITY_START_HIGHLIGHT_FADE_IN_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _activity_start_highlight_glow_extent() -> float:
	return ACTIVITY_START_HIGHLIGHT_GAP + ACTIVITY_START_HIGHLIGHT_RING_THICKNESS + ACTIVITY_START_HIGHLIGHT_BLUR_SPREAD + 8.0


func _activity_start_highlight_overlay_parent() -> Control:
	if skill_swipe_frame != null and is_instance_valid(skill_swipe_frame):
		return skill_swipe_frame
	if skill_swipe_page != null and is_instance_valid(skill_swipe_page):
		return skill_swipe_page
	return null


func _begin_activity_start_highlight_frame_clip_override() -> void:
	var frame := skill_swipe_frame
	if frame == null or not is_instance_valid(frame) or activity_start_highlight_frame_clip_override_active:
		return
	activity_start_highlight_frame_clip_saved = frame.clip_contents
	frame.clip_contents = false
	activity_start_highlight_frame_clip_override_active = true


func _restore_activity_start_highlight_frame_clip() -> void:
	if not activity_start_highlight_frame_clip_override_active:
		return
	var frame := skill_swipe_frame
	if frame != null and is_instance_valid(frame):
		frame.clip_contents = activity_start_highlight_frame_clip_saved
	activity_start_highlight_frame_clip_override_active = false


func _position_activity_start_highlight_border(
	highlight: ActivityStartHighlightRing,
	card_root: Control,
	overlay_parent: Control
) -> void:
	var glow_extent := _activity_start_highlight_glow_extent()
	var card_rect := card_root.get_global_rect()
	var parent_rect := overlay_parent.get_global_rect()
	highlight.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	highlight.position = card_rect.position - parent_rect.position - Vector2(glow_extent, glow_extent)
	highlight.size = card_rect.size + Vector2(glow_extent * 2.0, glow_extent * 2.0)
	highlight.outer_pad = glow_extent
	highlight.queue_redraw()


func _sync_activity_start_highlight_position() -> void:
	if not activity_start_highlight_active:
		return
	if activity_start_highlight_border == null or not is_instance_valid(activity_start_highlight_border):
		return
	if activity_start_highlight_card_key.is_empty() or not action_cards.has(activity_start_highlight_card_key):
		return
	var card := action_cards[activity_start_highlight_card_key] as Dictionary
	var card_root := card.get("root") as Control
	var overlay_parent := activity_start_highlight_border.get_parent() as Control
	if card_root == null or not is_instance_valid(card_root) or overlay_parent == null:
		return
	_position_activity_start_highlight_border(
		activity_start_highlight_border as ActivityStartHighlightRing,
		card_root,
		overlay_parent
	)


func _attach_activity_start_highlight_border(card: Dictionary) -> void:
	_remove_activity_start_highlight_border_node()
	var card_root := card.get("root") as Control
	if card_root == null or not is_instance_valid(card_root):
		return
	var overlay_parent := _activity_start_highlight_overlay_parent()
	if overlay_parent == null:
		return
	_begin_activity_start_highlight_frame_clip_override()
	var highlight := ActivityStartHighlightRing.new()
	highlight.name = "ActivityStartHighlightBorder"
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.z_index = 280
	highlight.z_as_relative = false
	highlight.glow_color = ACTIVITY_START_HIGHLIGHT_BORDER_COLOR
	highlight.corner_radius = 66.0
	highlight.gap = ACTIVITY_START_HIGHLIGHT_GAP
	highlight.ring_thickness = ACTIVITY_START_HIGHLIGHT_RING_THICKNESS
	highlight.blur_spread = ACTIVITY_START_HIGHLIGHT_BLUR_SPREAD
	highlight.blur_layers = ACTIVITY_START_HIGHLIGHT_BLUR_LAYERS
	highlight.set_glow_alpha(0.0)
	overlay_parent.add_child(highlight)
	_position_activity_start_highlight_border(highlight, card_root, overlay_parent)
	activity_start_highlight_border = highlight


func _remove_activity_start_highlight_border_node() -> void:
	if activity_start_highlight_border != null and is_instance_valid(activity_start_highlight_border):
		activity_start_highlight_border.queue_free()
	activity_start_highlight_border = null
	activity_start_highlight_card_key = ""
	_restore_activity_start_highlight_frame_clip()


func _fade_out_activity_start_highlight() -> void:
	if activity_start_highlight_border == null or not is_instance_valid(activity_start_highlight_border):
		_remove_activity_start_highlight_border_node()
		activity_start_highlight_active = false
		activity_start_highlight_pending = false
		return
	activity_start_highlight_active = false
	activity_start_highlight_pending = false
	var border := activity_start_highlight_border
	activity_start_highlight_border = null
	activity_start_highlight_card_key = ""
	if activity_start_highlight_fade_tween != null:
		activity_start_highlight_fade_tween.kill()
	activity_start_highlight_fade_tween = create_tween()
	activity_start_highlight_fade_tween.tween_method(
		border.set_glow_alpha,
		border.modulate.a,
		0.0,
		ACTIVITY_START_HIGHLIGHT_FADE_OUT_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	activity_start_highlight_fade_tween.tween_callback(_finish_activity_start_highlight_fade.bind(border.get_instance_id()))


func _dismiss_activity_start_highlight(instant := false) -> void:
	activity_start_highlight_token += 1
	activity_start_highlight_pending = false
	activity_start_highlight_active = false
	if activity_start_highlight_fade_tween != null:
		activity_start_highlight_fade_tween.kill()
	activity_start_highlight_fade_tween = null
	if activity_start_highlight_border == null or not is_instance_valid(activity_start_highlight_border):
		activity_start_highlight_border = null
		activity_start_highlight_card_key = ""
		return
	if instant:
		_remove_activity_start_highlight_border_node()
	else:
		_fade_out_activity_start_highlight()


func _finish_activity_start_highlight_fade(border_id: int) -> void:
	var border := _valid_node_ref(instance_from_id(border_id))
	if border != null:
		border.queue_free()
	_restore_activity_start_highlight_frame_clip()


func _on_activity_start_tutorial_card_tapped(skill_id: String, action_id: String) -> void:
	if activity_start_tip_seen:
		return
	if skill_id != TUTORIAL_STARTER_SKILL_ID or action_id != TUTORIAL_STARTER_ACTION_ID:
		return
	if activity_start_highlight_pending:
		activity_start_highlight_pending = false
		activity_start_highlight_token += 1
		return
	if activity_start_highlight_active:
		_fade_out_activity_start_highlight()


func _skill_swipe_tip_note(content_width: float) -> Control:
	var note := _tutorial_overlay_surface()._bottom_tutorial_tip_note(
		content_width,
		"Some activities require multiple skills.\nSwipe left or right to see other skills.",
		"skill_swipe_tip_notes"
	)
	return note


func _lock_click_tip_note(content_width: float) -> Control:
	return _tutorial_overlay_surface()._bottom_tutorial_tip_note(
		content_width,
		"Unlock your next activity by clicking the lock.",
		"lock_click_tip_notes"
	)


func _passive_module_tip_note(content_width: float) -> Control:
	return _tutorial_overlay_surface()._bottom_tutorial_tip_note(
		content_width,
		PassiveFirepitSurface.WOODCUTTING_LOG_MODULE_TIP_TEXT,
		"passive_module_tip_notes"
	)


func _silver_opportunity_tip_note(content_width: float) -> Control:
	return _tutorial_overlay_surface()._bottom_tutorial_tip_note(
		content_width,
		SILVER_OPPORTUNITY_TIP_TEXT,
		"silver_opportunity_tip_notes"
	)


func _should_show_lock_click_tip(skill_id: String, action: Dictionary) -> bool:
	return (
		not lock_click_tip_seen
		and int(action.get("unlock", 1)) == 2
		and _activity_unlock_runtime()._can_unlock_action(skill_id, action)
		and not _is_action_unlocked(skill_id, action)
	)


func _should_show_passive_module_tip(skill_id: String, action: Dictionary) -> bool:
	var module_id := str(action.get("id", ""))
	return (
		not passive_module_tip_seen
		and skill_id == "woodcutting"
		and module_id == PassiveModulesRuntime.WOODCUTTING_LOG_MODULE_ID
		and _is_passive_action(action)
		and _passive_modules_runtime().is_passive_module_unlocked(module_id)
	)


func _should_show_silver_opportunity_tip(skill_id: String, action: Dictionary) -> bool:
	if silver_opportunity_tip_seen or _fishing_rework_active_for_skill(skill_id):
		return false
	var action_id := str(action.get("id", ""))
	if action_id.is_empty() or MasteryState.level(mastery, _action_key(skill_id, action_id)) < ACTION_OPPORTUNITY_MIN_MEDAL_LEVEL:
		return false
	_ensure_silver_opportunity_tip_anchor()
	return silver_opportunity_tip_action_key == _action_key(skill_id, action_id)


func _build_detail_pull_tip_overlay(parent: Control, _content_width: float) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var root := Control.new()
	detail_pull_tip_root = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	root.modulate.a = 0.0
	root.z_index = 76
	parent.add_child(root)

	var label := _label("", DETAIL_PULL_TIP_FONT_SIZE, Color("#4b3828"), HORIZONTAL_ALIGNMENT_CENTER)
	detail_pull_tip_label = label
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_position_detail_pull_tip_label(true, DETAIL_PULL_TIP_FULL_OFFSET)
	label.add_theme_color_override("font_outline_color", Color("#fff4ce"))
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_constant_override("line_spacing", -8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)


func _position_detail_pull_tip_label(at_top: bool, pull_amount: float) -> void:
	if detail_pull_tip_label == null or not is_instance_valid(detail_pull_tip_label):
		return
	detail_pull_tip_label.anchor_left = 0.0
	detail_pull_tip_label.anchor_right = 1.0
	detail_pull_tip_label.offset_left = ACTION_CARD_POP_GUTTER
	detail_pull_tip_label.offset_right = -ACTION_CARD_POP_GUTTER
	var centered_top := pull_amount * 0.5 - DETAIL_PULL_TIP_HEIGHT * 0.5
	if at_top:
		detail_pull_tip_label.anchor_top = 0.0
		detail_pull_tip_label.anchor_bottom = 0.0
		detail_pull_tip_label.offset_top = centered_top
		detail_pull_tip_label.offset_bottom = centered_top + DETAIL_PULL_TIP_HEIGHT
	else:
		detail_pull_tip_label.anchor_top = 1.0
		detail_pull_tip_label.anchor_bottom = 1.0
		detail_pull_tip_label.offset_top = -centered_top - DETAIL_PULL_TIP_HEIGHT
		detail_pull_tip_label.offset_bottom = -centered_top


func _next_detail_pull_tip_text() -> String:
	if DETAIL_PULL_TIP_TEXTS.is_empty():
		return "tip: keep exploring."
	var candidates: Array = []
	for raw_tip in DETAIL_PULL_TIP_TEXTS:
		var tip := str(raw_tip)
		if not detail_pull_recent_tip_texts.has(tip):
			candidates.append(tip)
	if candidates.is_empty():
		for raw_tip in DETAIL_PULL_TIP_TEXTS:
			candidates.append(str(raw_tip))
	var tip_index := randi() % candidates.size()
	return str(candidates[tip_index])


func _record_detail_pull_tip_seen(tip_text: String) -> void:
	var normalized_tip := str(tip_text).strip_edges()
	if normalized_tip.is_empty():
		return
	detail_pull_recent_tip_texts.erase(normalized_tip)
	detail_pull_recent_tip_texts.append(normalized_tip)
	while detail_pull_recent_tip_texts.size() > 3:
		detail_pull_recent_tip_texts.pop_front()
	_mark_save_dirty("detail pull tip seen")


func _detail_pull_tip_display_text(tip_text: String) -> String:
	var text := str(tip_text).strip_edges()
	if text.length() <= 42 or text.find("\n") >= 0:
		return text
	var target := text.length() / 2
	var best_index := -1
	var best_distance := 100000
	for i in range(text.length()):
		if text[i] != " ":
			continue
		if i < 12 or i > text.length() - 12:
			continue
		var distance := absi(i - target)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	if best_index < 0:
		return text
	return "%s\n%s" % [text.substr(0, best_index), text.substr(best_index + 1)]


func _on_detail_actions_pull_offset_changed(offset_y: float) -> void:
	if action_stop_hold_active and absf(offset_y) >= ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE:
		_cancel_action_stop_hold()
	if detail_pull_tip_root == null or not is_instance_valid(detail_pull_tip_root):
		detail_pull_tip_active = false
		return
	if current_screen != "skill":
		detail_pull_tip_root.visible = false
		detail_pull_tip_root.modulate.a = 0.0
		detail_pull_tip_active = false
		detail_pull_tip_direction = 0
		return
	var pull_direction := 1 if offset_y > 0.0 else 0
	var pull_amount := absf(offset_y)
	var should_show := pull_direction != 0 and pull_amount >= DETAIL_PULL_TIP_TRIGGER_OFFSET
	if (
		should_show
		and (not detail_pull_tip_active or detail_pull_tip_direction != pull_direction)
		and detail_pull_tip_label != null
		and is_instance_valid(detail_pull_tip_label)
	):
		var tip_text := _next_detail_pull_tip_text()
		_set_label_text_if_changed(detail_pull_tip_label, _detail_pull_tip_display_text(tip_text))
		_record_detail_pull_tip_seen(tip_text)
	detail_pull_tip_active = should_show
	detail_pull_tip_direction = pull_direction if should_show else 0
	if not should_show:
		detail_pull_tip_root.visible = false
		detail_pull_tip_root.modulate.a = 0.0
		return
	_position_detail_pull_tip_label(true, pull_amount)
	var denominator := maxf(1.0, DETAIL_PULL_TIP_FULL_OFFSET - DETAIL_PULL_TIP_TRIGGER_OFFSET)
	detail_pull_tip_root.visible = true
	detail_pull_tip_root.modulate.a = clampf((pull_amount - DETAIL_PULL_TIP_TRIGGER_OFFSET) / denominator, 0.0, 1.0)


func _apply_empty_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _queue_activity_unlock_readiness(trigger_skill_id: String, old_level: int, new_level: int, ready_by_skill: Dictionary) -> void:
	if ready_by_skill.is_empty() or not startup_initialized:
		return
	if trigger_skill_id == TUTORIAL_STARTER_SKILL_ID and old_level < 2 and new_level >= 2:
		_fade_out_onboarding_level_up_tip(ACTIVITY_PREVIEW_FADE_IN_SECONDS)
	ready_by_skill = _auto_unlock_nonvisible_ready_lockpads(ready_by_skill)
	if ready_by_skill.is_empty():
		return
	var pages := _pending_activity_readiness_pages()
	for raw_owner_skill_id in ready_by_skill.keys():
		var owner_skill_id := str(raw_owner_skill_id)
		if owner_skill_id.is_empty():
			continue
		var incoming_ready_ids := ready_by_skill.get(raw_owner_skill_id, []) as Array
		if incoming_ready_ids.is_empty():
			continue
		var entry := pages.get(owner_skill_id, {}) as Dictionary
		var merged_ready_ids := _merged_activity_ready_ids(entry.get("ready", []), incoming_ready_ids)
		if merged_ready_ids.is_empty():
			continue
		pages[owner_skill_id] = {
			"skill_id": owner_skill_id,
			"trigger_skill_id": trigger_skill_id,
			"old_level": old_level,
			"new_level": new_level,
			"ready": merged_ready_ids,
			"preview": str(entry.get("preview", "")),
		}
	if pages.is_empty():
		return
	pending_activity_unlock_ceremony = {"pages": pages}
	activity_unlock_detail_refresh_done = false
	activity_unlock_center_scroll_target = -1
	if auto_unlock_lockpads_enabled and not _onboarding_runtime()._onboarding_path_active():
		call_deferred("_auto_unlock_pending_lockpads")
	if current_screen == "skill" and _pending_activity_has_readiness_for_skill(selected_skill_id):
		call_deferred("_update_ui", 0.0, false)


func _auto_unlock_nonvisible_ready_lockpads(ready_by_skill: Dictionary) -> Dictionary:
	if not auto_unlock_lockpads_enabled:
		return ready_by_skill
	if _onboarding_runtime()._onboarding_path_active():
		return ready_by_skill
	var visible_ready_by_skill := {}
	for raw_owner_skill_id in ready_by_skill.keys():
		var owner_skill_id := str(raw_owner_skill_id)
		if owner_skill_id.is_empty():
			continue
		var incoming_ready_ids := ready_by_skill.get(raw_owner_skill_id, []) as Array
		var visible_ready_ids := []
		for raw_action_id in incoming_ready_ids:
			var action_id := str(raw_action_id)
			if action_id.is_empty():
				continue
			if current_screen == "skill" and owner_skill_id == selected_skill_id:
				visible_ready_ids.append(action_id)
			else:
				if not _auto_finalize_ready_lockpad(owner_skill_id, action_id):
					_auto_unlock_ready_requirement_lockpads_nonvisible(owner_skill_id, action_id)
		if not visible_ready_ids.is_empty():
			visible_ready_by_skill[owner_skill_id] = visible_ready_ids
	return visible_ready_by_skill


func _ready_lockpads_for_current_state() -> Dictionary:
	var ready_by_skill := {}
	for raw_owner_skill_id in actions_by_skill.keys():
		var owner_skill_id := str(raw_owner_skill_id)
		if owner_skill_id.is_empty():
			continue
		for raw_action in actions_by_skill.get(owner_skill_id, []) as Array:
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty() or _is_action_unlocked(owner_skill_id, action):
				continue
			if not _activity_unlock_runtime()._can_unlock_action(owner_skill_id, action) and _first_ready_action_requirement_lock_index(owner_skill_id, action) < 0:
				continue
			var owner_ready_ids := ready_by_skill.get(owner_skill_id, []) as Array
			if not owner_ready_ids.has(action_id):
				owner_ready_ids.append(action_id)
			ready_by_skill[owner_skill_id] = owner_ready_ids
	return ready_by_skill


func _auto_unlock_retroactive_lockpads() -> void:
	if not auto_unlock_lockpads_enabled:
		return
	if _onboarding_runtime()._onboarding_path_active():
		return
	var ready_by_skill := _ready_lockpads_for_current_state()
	if ready_by_skill.is_empty():
		return
	_queue_activity_unlock_readiness("", 0, 0, ready_by_skill)
	_auto_unlock_pending_lockpads()


func _run_startup_auto_unlock_lockpads() -> void:
	if not startup_initialized or not auto_unlock_lockpads_enabled:
		return
	if _onboarding_runtime()._onboarding_path_active():
		return
	_auto_unlock_retroactive_lockpads()
	_auto_unlock_pending_lockpads()

func _auto_finalize_ready_lockpad(skill_id: String, action_id: String) -> bool:
	var action := _action_data(skill_id, action_id)
	if action.is_empty() or _is_action_unlocked(skill_id, action) or not _activity_unlock_runtime()._can_unlock_action(skill_id, action):
		return false
	if current_screen == "skill" and selected_skill_id == skill_id and _fishing_rework_active_for_skill(skill_id):
		var preview_after_unlock := _fishing_preview_after_manual_unlock(action_id)
		if not preview_after_unlock.is_empty():
			_clear_activity_unlock_preview_reveal_guards()
		_set_activity_unlock_preview_after_ceremony(preview_after_unlock)
		if not preview_after_unlock.is_empty():
			_prestage_activity_unlock_preview_card(preview_after_unlock)
	var finalized := _activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, action_id, _auto_unlock_lockpad_save_reason(skill_id))
	if finalized:
		_request_current_skill_detail_unlock_refresh(skill_id)
	return finalized


func _request_current_skill_detail_unlock_refresh(skill_id: String) -> void:
	if current_screen != "skill" or skill_id != selected_skill_id:
		return
	activity_unlock_detail_refresh_done = false
	call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")


func _auto_unlock_lockpad_save_reason(skill_id: String) -> String:
	return "fishing method unlock" if _fishing_rework_active_for_skill(skill_id) else "activity unlock"


func _first_ready_action_requirement_lock_index(skill_id: String, action: Dictionary) -> int:
	if _activity_unlock_runtime()._action_unlock_requirements(skill_id, action).size() <= 1:
		return -1
	var states := _activity_unlock_runtime()._action_requirement_states(skill_id, action)
	for index in range(states.size()):
		var state := states[index] as Dictionary
		if bool(state.get("met", false)) and not bool(state.get("dismissed", false)):
			return index
	return -1


func _auto_unlock_ready_requirement_lockpads_nonvisible(skill_id: String, action_id: String) -> bool:
	var action := _action_data(skill_id, action_id)
	if action.is_empty() or _is_action_unlocked(skill_id, action):
		return false
	var changed := false
	while true:
		var requirement_index := _first_ready_action_requirement_lock_index(skill_id, action)
		if requirement_index < 0:
			break
		var final_requirement_unlock := _skill_detail_surface()._action_requirement_unlocks_complete_after(skill_id, action, requirement_index)
		if _activity_unlock_runtime()._mark_activity_requirement_manually_unlocked(skill_id, action, requirement_index):
			changed = true
		if final_requirement_unlock:
			_activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, action_id, _auto_unlock_lockpad_save_reason(skill_id))
			return true
	if changed:
		_mark_save_dirty("activity requirement unlock")
	return changed


func _ready_actions_for_level_gain(skill_id: String, old_level: int, new_level: int) -> Dictionary:
	var ready_by_skill := {}
	if new_level <= old_level:
		return ready_by_skill
	for raw_owner_skill_id in actions_by_skill.keys():
		var owner_skill_id := str(raw_owner_skill_id)
		for raw_action in actions_by_skill.get(owner_skill_id, []):
			var action := raw_action as Dictionary
			if action.is_empty():
				continue
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			if _is_action_unlocked(owner_skill_id, action):
				continue
			if not _action_requirements_crossed_by_level_gain(skill_id, owner_skill_id, action, old_level, new_level):
				continue
			if not _activity_unlock_runtime()._can_unlock_action(owner_skill_id, action):
				continue
			var owner_ready_ids := ready_by_skill.get(owner_skill_id, []) as Array
			if not owner_ready_ids.has(action_id):
				owner_ready_ids.append(action_id)
			ready_by_skill[owner_skill_id] = owner_ready_ids
	return ready_by_skill


func _action_requirements_crossed_by_level_gain(skill_id: String, owner_skill_id: String, action: Dictionary, old_level: int, new_level: int) -> bool:
	if new_level <= old_level:
		return false
	for raw_requirement in _activity_unlock_runtime()._action_unlock_requirements(owner_skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		if str(requirement.get("skill", "")) != skill_id:
			continue
		var requirement_level := int(requirement.get("level", 1))
		if requirement_level > old_level and requirement_level <= new_level:
			return true
	return false


func _merged_activity_ready_ids(existing_ids: Variant, incoming_ids: Array) -> Array:
	var merged := []
	if typeof(existing_ids) == TYPE_ARRAY:
		for raw_action_id in existing_ids:
			var action_id := str(raw_action_id)
			if not action_id.is_empty() and not merged.has(action_id):
				merged.append(action_id)
	for raw_action_id in incoming_ids:
		var action_id := str(raw_action_id)
		if not action_id.is_empty() and not merged.has(action_id):
			merged.append(action_id)
	return merged


func _pending_activity_readiness_pages() -> Dictionary:
	var pages := {}
	if pending_activity_unlock_ceremony.is_empty():
		return pages
	var raw_pages = pending_activity_unlock_ceremony.get("pages", {})
	if typeof(raw_pages) == TYPE_DICTIONARY:
		var source_pages := raw_pages as Dictionary
		for raw_skill_id in source_pages.keys():
			var skill_id := str(raw_skill_id)
			var raw_entry = source_pages.get(raw_skill_id, {})
			if skill_id.is_empty() or typeof(raw_entry) != TYPE_DICTIONARY:
				continue
			var entry := raw_entry as Dictionary
			var ready_ids := entry.get("ready", []) as Array
			if not ready_ids.is_empty():
				pages[skill_id] = entry
		return pages
	var legacy_skill_id := str(pending_activity_unlock_ceremony.get("skill_id", ""))
	if not legacy_skill_id.is_empty():
		pages[legacy_skill_id] = pending_activity_unlock_ceremony
	return pages


func _pending_activity_readiness_for_skill(skill_id: String) -> Dictionary:
	if skill_id.is_empty():
		return {}
	var pages := _pending_activity_readiness_pages()
	var raw_entry = pages.get(skill_id, {})
	if typeof(raw_entry) == TYPE_DICTIONARY:
		return raw_entry as Dictionary
	return {}


func _pending_activity_has_readiness_for_skill(skill_id: String) -> bool:
	return not _pending_activity_readiness_for_skill(skill_id).is_empty()


func _clear_pending_activity_readiness_for_skill(skill_id: String) -> void:
	if skill_id.is_empty() or pending_activity_unlock_ceremony.is_empty():
		return
	var pages := _pending_activity_readiness_pages()
	pages.erase(skill_id)
	pending_activity_unlock_ceremony = {} if pages.is_empty() else {"pages": pages}


func _clear_pending_activity_readiness_action(skill_id: String, action_id: String) -> void:
	if skill_id.is_empty() or action_id.is_empty() or pending_activity_unlock_ceremony.is_empty():
		return
	var pages := _pending_activity_readiness_pages()
	var entry := pages.get(skill_id, {}) as Dictionary
	if entry.is_empty():
		return
	var ready_ids := []
	for raw_action_id in entry.get("ready", []) as Array:
		var ready_id := str(raw_action_id)
		if not ready_id.is_empty() and ready_id != action_id:
			ready_ids.append(ready_id)
	if ready_ids.is_empty():
		pages.erase(skill_id)
	else:
		entry["ready"] = ready_ids
		entry["applied"] = false
		pages[skill_id] = entry
	pending_activity_unlock_ceremony = {} if pages.is_empty() else {"pages": pages}


func _mark_pending_activity_readiness_applied(skill_id: String) -> void:
	if skill_id.is_empty() or pending_activity_unlock_ceremony.is_empty():
		return
	var pages := _pending_activity_readiness_pages()
	var entry := pages.get(skill_id, {}) as Dictionary
	if entry.is_empty():
		return
	entry["applied"] = true
	pages[skill_id] = entry
	pending_activity_unlock_ceremony = {"pages": pages}


func _pending_activity_readiness_action_ids(skill_id: String = selected_skill_id) -> Array:
	var entry := _pending_activity_readiness_for_skill(skill_id)
	if entry.is_empty():
		return []
	var ready_ids := entry.get("ready", []) as Array
	if ready_ids.is_empty():
		ready_ids = entry.get("unlocked", []) as Array
	return ready_ids


func _action_has_pending_unlock_readiness(action_id: String) -> bool:
	if action_id.is_empty() or not _pending_activity_readiness_action_ids().has(action_id):
		return false
	var action := _action_data(selected_skill_id, action_id)
	if not action.is_empty() and _is_action_unlocked(selected_skill_id, action):
		_clear_pending_activity_readiness_action(selected_skill_id, action_id)
		_mark_save_dirty("activity unlock cleanup")
		return false
	return true


func _action_matches_pending_unlock_preview(action_id: String) -> bool:
	var entry := _pending_activity_readiness_for_skill(selected_skill_id)
	return not entry.is_empty() and str(entry.get("preview", "")) == action_id


func _set_activity_unlock_preview_after_ceremony(action_id: String) -> void:
	var normalized := str(action_id)
	if not normalized.is_empty() and activity_unlock_preview_after_ceremony_id != normalized:
		_clear_activity_unlock_preview_reveal_guards()
	activity_unlock_preview_after_ceremony_id = normalized
	if (
		current_screen == "skill"
		and _fishing_rework_active_for_skill(selected_skill_id)
		and not normalized.is_empty()
	):
		_ensure_detail_lazy_entry_mounted(normalized)


func _queue_fishing_unlock_visible_mount(action_id: String) -> void:
	if current_screen != "skill" or selected_skill_id != "fishing":
		return
	if not _fishing_rework_active_for_skill("fishing"):
		return
	var mount_ids := [str(action_id)]
	var next_preview_id := _fishing_preview_after_manual_unlock(str(action_id))
	if not next_preview_id.is_empty():
		mount_ids.append(next_preview_id)
		if not fishing_unlock_preview_fade_marker_ids.has(next_preview_id):
			fishing_unlock_preview_fade_marker_ids.append(next_preview_id)
	for raw_mount_id in mount_ids:
		var mount_id := str(raw_mount_id)
		if mount_id.is_empty() or fishing_unlock_visible_mount_ids.has(mount_id):
			continue
		fishing_unlock_visible_mount_ids.append(mount_id)
	_ensure_queued_fishing_unlock_entries_mounted()
	call_deferred("_ensure_queued_fishing_unlock_entries_mounted")


func _ensure_queued_fishing_unlock_entries_mounted() -> void:
	if fishing_unlock_visible_mount_ids.is_empty():
		return
	if current_screen != "skill" or selected_skill_id != "fishing" or detail_lazy_plan.is_empty():
		return
	for raw_mount_id in fishing_unlock_visible_mount_ids:
		var mount_id := str(raw_mount_id)
		if mount_id.is_empty():
			continue
		_ensure_detail_lazy_entry_mounted(mount_id)
		var mount_action := _action_data("fishing", mount_id)
		if mount_action.is_empty() or _is_action_unlocked("fishing", mount_action):
			continue
		if not fishing_unlock_preview_fade_marker_ids.has(mount_id):
			fishing_unlock_preview_fade_marker_ids.append(mount_id)
		_stage_activity_preview_for_action_id(mount_id, false)


func _clear_activity_unlock_preview_reveal_guards() -> void:
	activity_unlock_preview_staged_action_ids.clear()
	activity_unlock_preview_played_action_ids.clear()


func _prestage_activity_unlock_preview_card(action_id: String, delay := 0.12) -> void:
	if current_screen != "skill" or action_id.is_empty():
		return
	if _fishing_rework_active_for_skill(selected_skill_id):
		if activity_unlock_preview_after_ceremony_id == action_id:
			if not fishing_unlock_preview_fade_marker_ids.has(action_id):
				fishing_unlock_preview_fade_marker_ids.append(action_id)
			_stage_activity_preview_for_action_id(action_id, false)
		return
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if current_screen != "skill":
		return
	if activity_unlock_preview_after_ceremony_id != action_id:
		return
	_activity_preview_card_for_action_id(action_id, true)


func _stage_activity_unlock_preview_once(action_id: String, card: Dictionary, collapse_height := true) -> bool:
	if action_id.is_empty() or card.is_empty():
		return false
	if bool(activity_unlock_preview_staged_action_ids.get(action_id, false)):
		return false
	activity_unlock_preview_staged_action_ids[action_id] = true
	_stage_activity_preview_enter(card, collapse_height)
	return true


func _claim_activity_unlock_preview_play(action_id: String) -> bool:
	if action_id.is_empty():
		return true
	if bool(activity_unlock_preview_played_action_ids.get(action_id, false)):
		return false
	activity_unlock_preview_played_action_ids[action_id] = true
	return true


func _apply_pending_activity_unlock_readiness() -> void:
	if pending_activity_unlock_ceremony.is_empty():
		return
	var pending_entry := _pending_activity_readiness_for_skill(selected_skill_id)
	if pending_entry.is_empty():
		return
	if bool(pending_entry.get("applied", false)):
		return
	var readiness_action_ids := _pending_activity_readiness_action_ids()
	_release_onboarding_first_module_centering_for_level_two_unlock(selected_skill_id, readiness_action_ids)
	for raw_action_id in readiness_action_ids:
		var action_id := str(raw_action_id)
		var key := _action_key(selected_skill_id, action_id)
		var card := {}
		if action_cards.has(key):
			card = action_cards[key] as Dictionary
		elif _fishing_rework_active_for_skill(selected_skill_id):
			card = _fishing_method_card_for_action(selected_skill_id, action_id)
		if card.is_empty():
			continue
		var action := _action_data(selected_skill_id, action_id)
		if action.is_empty():
			continue
		if _is_action_unlocked(selected_skill_id, action):
			_clear_pending_activity_readiness_action(selected_skill_id, action_id)
			_mark_save_dirty("activity unlock cleanup")
			continue
		card["unlock_ceremony_pending"] = false
		card["unlock_ceremony_active"] = false
		card["unlock_ceremony_finalized"] = false
		card["unlock_ready_pending"] = true
		card.erase("lock_overlay_sync_key")
		if bool(card.get("locked_preview_hidden", false)):
			_reveal_locked_activity_card_in_place(card, selected_skill_id, action)
		if bool(card.get("passive", false)):
			_passive_firepit_surface()._update_passive_card_static_state(card, selected_skill_id, action, _is_action_unlocked(selected_skill_id, action))
		elif not bool(card.get("is_fishing_method", false)):
			_skill_swipe_activity_surface()._update_action_card_static_state(card, selected_skill_id, action, _is_action_unlocked(selected_skill_id, action))
		else:
			card["unlock_ceremony_pending"] = false
			card["unlock_ready_pending"] = true
	var preview_id := str(pending_entry.get("preview", ""))
	_set_activity_unlock_preview_after_ceremony(preview_id)
	if not preview_id.is_empty():
		_prestage_activity_unlock_preview_card(preview_id)
	_mark_pending_activity_readiness_applied(selected_skill_id)
	activity_unlock_detail_refresh_done = false
	if auto_unlock_lockpads_enabled:
		call_deferred("_auto_unlock_visible_pending_lockpads", selected_skill_id)


func _auto_unlock_visible_pending_lockpads(skill_id: String) -> void:
	if not auto_unlock_lockpads_enabled:
		return
	if _onboarding_runtime()._onboarding_path_active():
		return
	if current_screen != "skill" or skill_id != selected_skill_id:
		return
	if activity_unlock_ceremony_count > 0:
		return
	if _fishing_rework_active_for_skill(skill_id):
		if _auto_unlock_visible_fishing_location_lockpad():
			return
	var readiness_action_ids := _pending_activity_readiness_action_ids(skill_id)
	if readiness_action_ids.is_empty():
		return
	for raw_action_id in readiness_action_ids:
		var action_id := str(raw_action_id)
		if action_id.is_empty():
			continue
		var action := _action_data(skill_id, action_id)
		if action.is_empty():
			_clear_pending_activity_readiness_action(skill_id, action_id)
			continue
		if _is_action_unlocked(skill_id, action):
			_clear_pending_activity_readiness_action(skill_id, action_id)
			continue
		if not _activity_unlock_runtime()._can_unlock_action(skill_id, action):
			continue
		var card := _skill_detail_surface()._resolve_activity_unlock_card(skill_id, action_id)
		if card.is_empty():
			if _auto_finalize_ready_lockpad(skill_id, action_id):
				_clear_pending_activity_readiness_action(skill_id, action_id)
				call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
				return
			if _auto_unlock_ready_requirement_lockpads_nonvisible(skill_id, action_id):
				_clear_pending_activity_readiness_action(skill_id, action_id)
				call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
				return
			continue
		if bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false)):
			return
		if _auto_unlock_visible_activity_requirement_lock(card, skill_id, action):
			return
		if not _activity_unlock_runtime()._can_unlock_action(skill_id, action):
			_clear_pending_activity_readiness_action(skill_id, action_id)
			continue
		if bool(card.get("is_fishing_method", false)):
			_on_fishing_method_lock_pressed(skill_id, action_id)
		else:
			_audio_director()._play_padlock_cluster_sfx()
			_skill_detail_surface()._on_activity_lock_clicked(skill_id, action_id, null)
		return


func _auto_unlock_visible_fishing_location_lockpad() -> bool:
	if fishing_auto_unlock_waiting_for_detail_refresh:
		return true
	if not activity_unlock_preview_after_ceremony_id.is_empty():
		return true
	var action_id := _fishing_next_visible_auto_unlock_action_id()
	if action_id.is_empty():
		return false
	var action := _action_data("fishing", action_id)
	if action.is_empty() or _is_action_unlocked("fishing", action) or not _activity_unlock_runtime()._can_unlock_action("fishing", action):
		return false
	var card := _skill_detail_surface()._resolve_activity_unlock_card("fishing", action_id)
	if card.is_empty():
		return false
	if bool(card.get("unlock_ceremony_pending", false)) or bool(card.get("unlock_ceremony_active", false)):
		return true
	fishing_auto_unlock_waiting_for_detail_refresh = true
	_on_fishing_method_lock_pressed("fishing", action_id)
	return true


func _fishing_next_visible_auto_unlock_action_id() -> String:
	if selected_skill_id != "fishing":
		return ""
	var best_action_id := ""
	var best_unlock := 999999
	var best_render_order := 999999
	var render_order := 0
	for raw_area in fishing_runtime.area_definitions:
		var area_def := raw_area as Dictionary
		if not _fishing_area_uses_location_tiles(area_def):
			continue
		var area_id := str(area_def.get("id", ""))
		for raw_location in _fishing_locations_for_area(area_id):
			var location := raw_location as Dictionary
			if _fishing_location_is_unlocked(area_id, location):
				render_order += 1
				continue
			if not _fishing_location_should_show(area_id, location):
				render_order += 1
				continue
			var action_id := _fishing_location_action_id(area_id, str(location.get("id", "")))
			if action_id.is_empty():
				render_order += 1
				continue
			var action := _action_data("fishing", action_id)
			if action.is_empty() or not _activity_unlock_runtime()._can_unlock_action("fishing", action):
				render_order += 1
				continue
			var unlock_level := int(action.get("unlock", location.get("unlock", 1)))
			if unlock_level < best_unlock or (unlock_level == best_unlock and render_order < best_render_order):
				best_unlock = unlock_level
				best_render_order = render_order
				best_action_id = action_id
			render_order += 1
	return best_action_id


func _auto_unlock_pending_lockpads() -> void:
	if not auto_unlock_lockpads_enabled:
		return
	if _onboarding_runtime()._onboarding_path_active():
		return
	var pages := _pending_activity_readiness_pages()
	for raw_skill_id in pages.keys():
		var skill_id := str(raw_skill_id)
		if skill_id.is_empty():
			continue
		if current_screen == "skill" and skill_id == selected_skill_id:
			continue
		var entry := pages.get(raw_skill_id, {}) as Dictionary
		for raw_action_id in entry.get("ready", []) as Array:
			var action_id := str(raw_action_id)
			if action_id.is_empty():
				continue
			var action := _action_data(skill_id, action_id)
			if action.is_empty() or _is_action_unlocked(skill_id, action):
				_clear_pending_activity_readiness_action(skill_id, action_id)
				continue
			if _auto_finalize_ready_lockpad(skill_id, action_id) or _auto_unlock_ready_requirement_lockpads_nonvisible(skill_id, action_id):
				_clear_pending_activity_readiness_action(skill_id, action_id)
	if current_screen == "skill":
		_auto_unlock_visible_pending_lockpads(selected_skill_id)
		if activity_unlock_ceremony_count <= 0:
			_auto_cleanup_visible_pending_lockpads(selected_skill_id)
			_auto_unlock_visible_pending_lockpads(selected_skill_id)


func _auto_unlock_visible_activity_requirement_lock(card: Dictionary, skill_id: String, action: Dictionary) -> bool:
	if card.is_empty() or bool(card.get("is_fishing_method", false)):
		return false
	var action_id := str(action.get("id", ""))
	if action_id.is_empty() or _activity_unlock_runtime()._action_unlock_requirements(skill_id, action).size() <= 1:
		return false
	var requirement_index := _first_ready_action_requirement_lock_index(skill_id, action)
	if requirement_index < 0:
		return false
	var overlay := card.get("lock_overlay", {}) as Dictionary
	var group := _valid_control_ref(overlay.get("group"))
	if group == null:
		card.erase("lock_overlay_sync_key")
		_skill_detail_surface()._sync_activity_lock_overlay(card, action, false)
		overlay = card.get("lock_overlay", {}) as Dictionary
		group = _valid_control_ref(overlay.get("group"))
	if group == null or not group.has_method("play_requirement_unlock_drop_animation"):
		return false
	if group.has_method("consume_unlock_click"):
		group.call("consume_unlock_click")
	activity_unlock_detail_refresh_done = false
	activity_unlock_center_scroll_target = -1
	var final_requirement_unlock := _skill_detail_surface()._action_requirement_unlocks_complete_after(skill_id, action, requirement_index)
	if final_requirement_unlock:
		_clear_pending_activity_readiness_action(skill_id, action_id)
		var preview_after_unlock := _onboarding_runtime()._tutorial_preview_after_manual_unlock(skill_id, action_id)
		_set_activity_unlock_preview_after_ceremony(preview_after_unlock)
		activity_unlock_heist_preview_after_ceremony_id = thieving_state.heist_revealed_by_action_unlock(skill_id, action)
		if activity_unlock_heist_preview_after_ceremony_id.is_empty() and not activity_unlock_preview_after_ceremony_id.is_empty():
			_prestage_activity_unlock_preview_card(activity_unlock_preview_after_ceremony_id)
	_audio_director()._play_padlock_cluster_sfx()
	_skill_detail_surface()._play_activity_requirement_lock_dismissal(card, skill_id, action, requirement_index, group, final_requirement_unlock)
	if not final_requirement_unlock:
		if _first_ready_action_requirement_lock_index(skill_id, action) < 0 and not _activity_unlock_runtime()._can_unlock_action(skill_id, action):
			_clear_pending_activity_readiness_action(skill_id, action_id)
		else:
			_schedule_auto_unlock_pending_lockpads_after_delay(ActivityLockCluster.UNLOCK_DROP_SECONDS + 0.08)
	return true


func _auto_cleanup_visible_pending_lockpads(skill_id: String) -> void:
	if skill_id.is_empty() or pending_activity_unlock_ceremony.is_empty():
		return
	for raw_action_id in _pending_activity_readiness_action_ids(skill_id).duplicate():
		var action_id := str(raw_action_id)
		if action_id.is_empty():
			continue
		var action := _action_data(skill_id, action_id)
		if action.is_empty() or _is_action_unlocked(skill_id, action):
			_clear_pending_activity_readiness_action(skill_id, action_id)
			continue
		if _activity_unlock_runtime()._can_unlock_action(skill_id, action):
			continue
		if _first_ready_action_requirement_lock_index(skill_id, action) >= 0:
			_auto_unlock_ready_requirement_lockpads_nonvisible(skill_id, action_id)
		_clear_pending_activity_readiness_action(skill_id, action_id)


func _schedule_auto_unlock_pending_lockpads_after_delay(delay_seconds: float) -> void:
	await get_tree().create_timer(maxf(0.0, delay_seconds)).timeout
	_schedule_auto_unlock_pending_lockpads()


func _schedule_auto_unlock_pending_lockpads() -> void:
	if not auto_unlock_lockpads_enabled or pending_activity_unlock_ceremony.is_empty():
		return
	if _onboarding_runtime()._onboarding_path_active():
		return
	call_deferred("_auto_unlock_pending_lockpads")


func _play_activity_unlock_ceremony(card: Dictionary, lock_rig: Control = null) -> void:
	card["unlock_ceremony_pending"] = false
	card["unlock_ready_pending"] = false
	card["unlock_ceremony_active"] = true
	card["unlock_ceremony_finalized"] = false
	activity_unlock_ceremony_count += 1
	var ceremony_action_id := str(card.get("action_id", ""))
	if ceremony_action_id.is_empty():
		var ceremony_action := card.get("action", {}) as Dictionary
		ceremony_action_id = str(ceremony_action.get("id", ""))
	var ceremony_skill_id := str(card.get("skill_id", selected_skill_id))
	if not ceremony_action_id.is_empty():
		activity_unlock_ceremony_action_key = _action_key(ceremony_skill_id, ceremony_action_id)
	_skill_detail_surface()._prepare_activity_unlock_ceremony_overlay(card, lock_rig)
	var root := _valid_control_ref(card.get("root"))
	if root != null:
		card["unlock_ceremony_original_z_index"] = root.z_index
		card["unlock_ceremony_original_clip"] = root.clip_contents
		root.z_index = 90
		root.clip_contents = false
	var overlay := card.get("lock_overlay", {}) as Dictionary
	var overlay_root := _valid_control_ref(overlay.get("root"))
	var group := _valid_control_ref(lock_rig) if lock_rig != null else _valid_control_ref(overlay.get("group"))
	if group == null and overlay.has("group"):
		group = _valid_control_ref(overlay.get("group"))
	card["unlock_ceremony_lock_rig"] = group
	card["unlock_ceremony_overlay_root"] = overlay_root
	var button := _valid_button_ref(card.get("button"))
	var shade := _valid_canvas_item_ref(ActivityCardStyles.ensure_activity_card_shade(card, 0.50))
	if _tutorial_level_two_unlock_should_use_fast_reveal(ceremony_skill_id, ceremony_action_id):
		_play_tutorial_level_two_fast_unlock_ceremony(card, group, overlay_root, shade, button)
		return
	if overlay_root == null or group == null:
		if root != null and is_instance_valid(root):
			root.z_index = int(card.get("unlock_ceremony_original_z_index", 0))
			root.clip_contents = bool(card.get("unlock_ceremony_original_clip", false))
		card.erase("unlock_ceremony_original_z_index")
		card.erase("unlock_ceremony_original_clip")
		card.erase("unlock_ceremony_lock_rig")
		card.erase("unlock_ceremony_overlay_root")
		card["unlock_ceremony_active"] = false
		activity_unlock_ceremony_count = maxi(0, activity_unlock_ceremony_count - 1)
		activity_unlock_ceremony_action_key = ""
		if button != null:
			button.disabled = false
		return
	if button != null:
		button.disabled = true
	_start_activity_unlock_ceremony_motion(card)


func _tutorial_level_two_unlock_should_use_fast_reveal(skill_id: String, action_id: String) -> bool:
	return (
		_onboarding_runtime()._tutorial_gate_latch_sequence_active()
		and skill_id == TUTORIAL_STARTER_SKILL_ID
		and action_id == TUTORIAL_LEVEL_TWO_ACTION_ID
	)


func _play_tutorial_level_two_fast_unlock_ceremony(card: Dictionary, group: Control, overlay_root: Control, shade: CanvasItem, button: Button) -> void:
	if button != null and is_instance_valid(button):
		button.disabled = true
	if overlay_root != null and is_instance_valid(overlay_root):
		overlay_root.visible = true
		overlay_root.modulate = Color.WHITE
	if group != null and is_instance_valid(group):
		group.visible = true
		group.modulate = Color.WHITE
	if shade != null and is_instance_valid(shade):
		shade.visible = true
		shade.modulate = Color(1, 1, 1, 0.50)
	var fade_duration := DETAIL_LAZY_FADE_IN_SECONDS
	var tween := create_tween()
	tween.set_parallel(true)
	if group != null and is_instance_valid(group):
		tween.tween_property(group, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if shade != null and is_instance_valid(shade):
		tween.tween_property(shade, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	await get_tree().create_timer(fade_duration).timeout
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	_finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, true)
	await _run_post_unlock_ceremony_preview(card)
	var preview_id := activity_unlock_preview_after_ceremony_id
	if activity_unlock_heist_preview_after_ceremony_id.is_empty() and not preview_id.is_empty():
		_skill_detail_surface().call_deferred("_stage_unlock_preview_after_lock_click", preview_id)


func _start_activity_unlock_ceremony_motion(card: Dictionary) -> void:
	var group := _valid_control_ref(card.get("unlock_ceremony_lock_rig"))
	var overlay_root := _valid_control_ref(card.get("unlock_ceremony_overlay_root"))
	var shade := _valid_canvas_item_ref(ActivityCardStyles.ensure_activity_card_shade(card, 0.50))
	var button := _valid_button_ref(card.get("button"))
	if group == null or not is_instance_valid(group):
		var overlay := card.get("lock_overlay", {}) as Dictionary
		group = _valid_control_ref(overlay.get("group"))
	if overlay_root == null or not is_instance_valid(overlay_root):
		var overlay := card.get("lock_overlay", {}) as Dictionary
		overlay_root = _valid_control_ref(overlay.get("root"))
	_start_activity_unlock_ceremony_motion_after_delay(
		card,
		_weak_object_ref(group),
		_weak_object_ref(overlay_root),
		_weak_object_ref(shade),
		_weak_object_ref(button)
	)


func _start_activity_unlock_ceremony_motion_after_delay(card: Dictionary, group_ref: WeakRef, overlay_root_ref: WeakRef, shade_ref: WeakRef, button_ref: WeakRef) -> void:
	await get_tree().create_timer(ACTIVITY_UNLOCK_MOTION_START_DELAY).timeout
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	var group := _valid_control_ref(_weak_ref_value(group_ref))
	var overlay_root := _valid_control_ref(_weak_ref_value(overlay_root_ref))
	var shade := _valid_canvas_item_ref(_weak_ref_value(shade_ref))
	var button := _valid_button_ref(_weak_ref_value(button_ref))
	if current_screen != "skill":
		_finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, false)
		return
	if group == null or not is_instance_valid(group) or group.is_queued_for_deletion():
		var overlay := card.get("lock_overlay", {}) as Dictionary
		group = _valid_control_ref(overlay.get("group"))
	if group == null or not is_instance_valid(group) or group.is_queued_for_deletion():
		_finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, true)
		return
	if overlay_root == null or not is_instance_valid(overlay_root):
		var overlay := card.get("lock_overlay", {}) as Dictionary
		overlay_root = _valid_control_ref(overlay.get("root"))
	if overlay_root != null and is_instance_valid(overlay_root):
		overlay_root.visible = true
		overlay_root.modulate = Color.WHITE
	group.modulate = Color.WHITE
	group.visible = true
	group.set_process(true)
	if group.has_method("play_unlock_drop_animation"):
		var lock_rig_ref := _weak_object_ref(group)
		var lock_rig := group
		await get_tree().process_frame
		lock_rig = _valid_control_ref(_weak_ref_value(lock_rig_ref))
		if lock_rig == null or lock_rig.is_queued_for_deletion():
			_finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, true)
			return
		await get_tree().process_frame
		lock_rig = _valid_control_ref(_weak_ref_value(lock_rig_ref))
		if lock_rig == null or lock_rig.is_queued_for_deletion():
			_finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, true)
			return
		lock_rig.call("_layout_base")
		if lock_rig.size.y <= 1.0:
			lock_rig.call_deferred("_layout_base")
			await get_tree().process_frame
			lock_rig = _valid_control_ref(_weak_ref_value(lock_rig_ref))
			if lock_rig == null or lock_rig.is_queued_for_deletion():
				_finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, true)
				return
			lock_rig.call("_layout_base")
		_audio_director()._play_chain_fall_sfx_sequence(lock_rig)
		lock_rig.call("play_unlock_drop_animation")
		await get_tree().create_timer(ActivityLockCluster.UNLOCK_DROP_SECONDS + 0.05).timeout
	else:
		_audio_director()._play_chain_fall_sfx_sequence(group)
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	group = _valid_control_ref(_weak_ref_value(group_ref))
	if group == null or group.is_queued_for_deletion():
		_finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, true)
		return
	shade = _valid_canvas_item_ref(_weak_ref_value(shade_ref))
	if shade != null and is_instance_valid(shade):
		shade.visible = true
	var fade_tween := create_tween()
	fade_tween.tween_property(group, "modulate:a", 0.0, ACTIVITY_UNLOCK_CHAIN_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if shade != null and is_instance_valid(shade):
		fade_tween.parallel().tween_property(shade, "modulate:a", 0.0, ACTIVITY_UNLOCK_CHAIN_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(ACTIVITY_UNLOCK_CHAIN_FADE_SECONDS + 0.05).timeout
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	_finish_activity_unlock_ceremony_safe(card, overlay_root, shade, button, true)
	await _run_post_unlock_ceremony_preview(card)
	var preview_id := activity_unlock_preview_after_ceremony_id
	if activity_unlock_heist_preview_after_ceremony_id.is_empty() and not preview_id.is_empty():
		_skill_detail_surface().call_deferred("_stage_unlock_preview_after_lock_click", preview_id)


func _run_post_unlock_ceremony_preview(card: Dictionary):
	if current_screen != "skill":
		return
	if bool(card.get("unlock_ceremony_finalized", false)) == false:
		return
	if not activity_unlock_heist_preview_after_ceremony_id.is_empty():
		return
	if activity_unlock_preview_after_ceremony_id.is_empty():
		return
	if _play_next_locked_activity_preview_fade():
		return
	var preview_id := activity_unlock_preview_after_ceremony_id
	if preview_id.is_empty():
		return
	var preview_card := _activity_preview_card_for_action_id(preview_id, true)
	if preview_card.is_empty():
		return
	if not bool(preview_card.get("unlock_next_preview_pending", false)):
		return
	preview_card.erase("unlock_next_preview_pending")
	if not _claim_activity_unlock_preview_play(preview_id):
		return
	_skill_swipe_activity_surface()._play_activity_preview_fade_in(preview_card)


func _finish_activity_unlock_ceremony_safe(card: Dictionary, overlay_root_value: Variant, shade_value: Variant, button_value: Variant, refresh_detail: bool) -> void:
	if card.is_empty():
		return
	var overlay_root := _valid_control_ref(overlay_root_value)
	if overlay_root == null:
		var overlay := card.get("lock_overlay", {}) as Dictionary
		overlay_root = _valid_control_ref(overlay.get("root"))
	var shade := _valid_canvas_item_ref(shade_value)
	if shade == null:
		shade = _valid_canvas_item_ref(card.get("shade"))
	var button := _valid_button_ref(button_value)
	if button == null:
		button = _valid_button_ref(card.get("button"))
	_finish_activity_unlock_ceremony(card, overlay_root, shade, button, refresh_detail)


func _finish_activity_unlock_ceremony(card: Dictionary, overlay_root: Control, shade: CanvasItem, button: Button, refresh_detail: bool) -> void:
	if bool(card.get("unlock_ceremony_finalized", false)):
		return
	var pending_skill_id := str(card.get("manual_unlock_pending_skill_id", card.get("skill_id", selected_skill_id)))
	var pending_action_id := str(card.get("manual_unlock_pending_action_id", card.get("action_id", "")))
	if pending_action_id.is_empty():
		var pending_action := card.get("action", {}) as Dictionary
		pending_action_id = str(pending_action.get("id", ""))
	_clear_pending_activity_readiness_action(pending_skill_id, pending_action_id)
	card["unlock_ceremony_finalized"] = true
	card["requirement_lock_dismiss_active"] = false
	var lock_rig := _state_object_ref(card.get("unlock_ceremony_lock_rig"))
	if lock_rig != null:
		if lock_rig.has_method("set_lock_state"):
			lock_rig.call("set_lock_state", ActivityLockRig.LOCK_STATE_GONE)
	_activity_unlock_runtime()._finalize_manual_activity_unlock_for_card(card)
	card.erase("unlock_ceremony_lock_rig")
	card.erase("unlock_ceremony_overlay_root")
	activity_unlock_ceremony_action_key = ""
	var root := _valid_control_ref(card.get("root"))
	if root != null:
		root.z_index = int(card.get("unlock_ceremony_original_z_index", 0))
		root.clip_contents = bool(card.get("unlock_ceremony_original_clip", false))
	card.erase("unlock_ceremony_original_z_index")
	card.erase("unlock_ceremony_original_clip")
	if overlay_root != null and is_instance_valid(overlay_root):
		overlay_root.visible = false
	var overlay := card.get("lock_overlay", {}) as Dictionary
	if not overlay.is_empty():
		_skill_detail_surface()._set_activity_lock_overlay_active(overlay, false)
	if shade != null and is_instance_valid(shade):
		shade.visible = false
		shade.modulate = Color.WHITE
	card["unlock_ceremony_active"] = false
	if button != null and is_instance_valid(button):
		button.disabled = false
	activity_unlock_ceremony_count = maxi(0, activity_unlock_ceremony_count - 1)
	call_deferred("_finish_activity_unlock_card_static_state_deferred", card)
	_schedule_auto_unlock_pending_lockpads()
	if refresh_detail and activity_unlock_ceremony_count <= 0 and not activity_unlock_detail_refresh_done:
		call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")


func _finish_activity_unlock_card_static_state_deferred(card: Dictionary) -> void:
	await get_tree().process_frame
	if card.is_empty():
		return
	var root := _valid_control_ref(card.get("root"))
	if root == null or root.is_queued_for_deletion():
		return
	var skill_id := str(card.get("skill_id", selected_skill_id))
	var action := card.get("action", {}) as Dictionary
	if action.is_empty() and not skill_id.is_empty():
		var action_id := str(card.get("action_id", ""))
		if action_id.is_empty() and card.has("action"):
			action_id = str((card.get("action", {}) as Dictionary).get("id", ""))
		if not action_id.is_empty():
			action = _action_data(skill_id, action_id)
	if action.is_empty():
		return
	var unlocked := _is_action_unlocked(skill_id, action)
	if bool(card.get("passive", false)):
		_passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, unlocked)
	elif not bool(card.get("is_fishing_method", false)):
		_skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, unlocked)


func _sync_onboarding_level_up_tip_position_by_key(_tip_progress: float, card_key: String) -> void:
	var card := action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	_sync_onboarding_level_up_tip_position(card)


func _finish_activity_preview_fade_in(card_key: String, root_id: int, pop_id: int, lock_rig_id: int, expand_from_zero: bool, target_height: float, skill_id: String, action_id: String) -> void:
	var card := action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	var callback_root := _valid_control_ref(instance_from_id(root_id))
	if callback_root == null or callback_root.is_queued_for_deletion():
		card.erase("unlock_next_preview_smooth")
		card.erase("stable_preview_fade")
		card.erase("preview_fade_tween")
		card["fade_in_pending"] = false
		return
	_set_canvas_item_modulate_if_changed(callback_root, Color.WHITE)
	if expand_from_zero:
		_set_control_minimum_height(callback_root, target_height)
		callback_root.clip_contents = bool(card.get("preview_enter_original_clip", false))
		card.erase("preview_enter_target_height")
		card.erase("preview_enter_entry_target_height")
		card.erase("preview_enter_original_clip")
		_set_activity_preview_entry_height(card, callback_root, target_height)
	var callback_pop := _valid_control_ref(instance_from_id(pop_id)) if pop_id != 0 else null
	if callback_pop != null and not callback_pop.is_queued_for_deletion():
		_set_preview_pop_vertical_offset(callback_pop, 0.0)
	card.erase("unlock_next_preview_smooth")
	card.erase("stable_preview_fade")
	card.erase("preview_fade_tween")
	card["fade_in_pending"] = false
	if not skill_id.is_empty() and not action_id.is_empty():
		call_deferred("_finish_activity_preview_card_after_fade_deferred", card_key, skill_id, action_id, lock_rig_id)


func _finish_activity_preview_card_after_fade_deferred(card_key: String, skill_id: String, action_id: String, lock_rig_id: int) -> void:
	await get_tree().process_frame
	var card := action_cards.get(card_key, {}) as Dictionary
	var action := _action_data(skill_id, action_id)
	if card.is_empty() or skill_id.is_empty() or action.is_empty():
		return
	var root := _valid_control_ref(card.get("root"))
	if root == null or root.is_queued_for_deletion():
		return
	var callback_lock_rig := _valid_control_ref(instance_from_id(lock_rig_id)) if lock_rig_id != 0 else null
	if callback_lock_rig != null:
		_set_canvas_item_modulate_if_changed(callback_lock_rig, Color.WHITE)
	var final_unlocked := _is_action_unlocked(skill_id, action)
	if final_unlocked:
		_skill_detail_surface()._sync_activity_lock_overlay(card, action, true)
	else:
		_finish_locked_preview_overlay_without_resync(card, action)
	if skill_id == TUTORIAL_STARTER_SKILL_ID and action_id == TUTORIAL_GATE_LATCH_ACTION_ID:
		call_deferred("_show_skill_swipe_tip_note_if_needed")


func _finish_locked_preview_overlay_without_resync(card: Dictionary, action: Dictionary) -> void:
	var overlay := card.get("lock_overlay", {}) as Dictionary
	if overlay.is_empty():
		return
	var overlay_root := _valid_control_ref(overlay.get("root"))
	if overlay_root != null:
		_set_canvas_item_visible_if_changed(overlay_root, true)
	var rig := _state_object_ref(overlay.get("group"))
	if rig != null:
		_set_canvas_item_visible_if_changed(rig, true)
		_set_canvas_item_modulate_if_changed(rig, Color.WHITE)
		rig.set_process(true)
		if rig.has_method("set_unlock_level"):
			rig.call("set_unlock_level", int(action.get("unlock", 1)))
	card["lock_overlay_sync_key"] = "%s:%s:%s" % [true, false, int(action.get("unlock", 1))]


func _set_preview_pop_vertical_offset(pop: Control, offset_y: float) -> void:
	if pop == null or not is_instance_valid(pop):
		return
	if pop.anchor_top == 0.0 and pop.anchor_bottom == 1.0:
		pop.offset_top = offset_y
		pop.offset_bottom = _activity_card_pop_base_bottom_offset(pop) + offset_y
		_set_activity_card_depth_face_offset_from_pop(pop, Vector2(pop.offset_left - ACTION_CARD_POP_GUTTER, offset_y))
	else:
		pop.position.y = offset_y


func _set_preview_pop_vertical_offset_safe(offset_y: float, pop_id: int) -> void:
	var pop := _valid_control_ref(instance_from_id(pop_id))
	if pop == null or pop.is_queued_for_deletion():
		return
	_set_preview_pop_vertical_offset(pop, offset_y)


func _set_canvas_item_alpha_safe(alpha: float, canvas_item_id: int) -> void:
	var canvas_item := _valid_canvas_item_ref(instance_from_id(canvas_item_id))
	if canvas_item == null or canvas_item.is_queued_for_deletion():
		return
	_set_canvas_item_alpha_if_changed(canvas_item, alpha)


func _set_control_minimum_height_safe(height: float, control_id: int) -> void:
	var control := _valid_control_ref(instance_from_id(control_id))
	if control == null or control.is_queued_for_deletion():
		return
	_set_control_minimum_height(control, height)


func _set_control_minimum_height(control: Control, height: float) -> void:
	if control == null or not is_instance_valid(control) or control.is_queued_for_deletion():
		return
	var clamped_height := maxf(0.0, height)
	var next_minimum_size := control.custom_minimum_size
	var changed := absf(next_minimum_size.y - clamped_height) > 0.5
	if changed:
		next_minimum_size.y = clamped_height
		control.custom_minimum_size = next_minimum_size
	if clamped_height <= 1.0 or control.size.y < clamped_height:
		control.size.y = clamped_height
		changed = true
	if changed:
		control.update_minimum_size()


func _activity_preview_entry_control(card: Dictionary, root: Control) -> Control:
	var entry := _valid_control_ref(card.get("entry"))
	if entry == null or entry == root:
		return null
	return entry


func _activity_preview_entry_height(card: Dictionary, root: Control, fallback_height: float) -> float:
	var entry := _activity_preview_entry_control(card, root)
	if entry == null:
		return fallback_height
	var entry_height := maxf(entry.custom_minimum_size.y, entry.size.y)
	return entry_height if entry_height > 1.0 else fallback_height


func _set_activity_preview_entry_height(card: Dictionary, root: Control, height: float) -> void:
	var entry := _activity_preview_entry_control(card, root)
	if entry == null:
		return
	_set_control_minimum_height(entry, height)


func _sync_hidden_locked_activity_preview_layouts() -> void:
	if tutorial_active:
		return
	if action_cards.is_empty():
		return
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if card == null or not bool(card.get("locked_preview_hidden", false)):
			continue
		var root := _valid_control_ref(card.get("root"))
		if root == null or not root.is_inside_tree():
			continue
		_set_control_minimum_height(root, 0.0)
		_set_activity_preview_entry_height(card, root, 0.0)
		root.visible = true
		root.modulate = Color(1, 1, 1, 0)
		root.clip_contents = true


func _hold_skill_detail_layout_refresh(seconds: float) -> void:
	skill_detail_layout_refresh_hold_until_msec = maxi(
		skill_detail_layout_refresh_hold_until_msec,
		Time.get_ticks_msec() + int(ceil(maxf(0.0, seconds) * 1000.0))
	)


func _stage_activity_preview_enter(card: Dictionary, collapse_height := true) -> void:
	var root := card.get("root") as Control
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	_preserve_detail_scroll_after_height_change_if_above_view(root)
	var target_height := float(card.get("locked_preview_target_height", root.custom_minimum_size.y))
	if target_height <= 0.0:
		target_height = root.size.y
	if target_height <= 0.0:
		target_height = _activity_card_preview_root_height(card)
	var entry_target_height := float(card.get("locked_preview_entry_target_height", _activity_preview_entry_height(card, root, target_height)))
	if collapse_height:
		card["preview_enter_target_height"] = target_height
		card["preview_enter_entry_target_height"] = entry_target_height
	else:
		card.erase("preview_enter_target_height")
		card.erase("preview_enter_entry_target_height")
	var original_clip := bool(card.get("locked_preview_original_clip", root.clip_contents))
	card["preview_enter_original_clip"] = original_clip
	card["locked_preview_hidden"] = false
	card.erase("locked_preview_target_height")
	card.erase("locked_preview_entry_target_height")
	card.erase("locked_preview_original_clip")
	_set_control_minimum_height(root, 0.0 if collapse_height else target_height)
	_set_activity_preview_entry_height(card, root, 0.0 if collapse_height else entry_target_height)
	_set_canvas_item_visible_if_changed(root, true)
	_set_canvas_item_modulate_if_changed(root, Color(1, 1, 1, 0))
	root.clip_contents = true if collapse_height else original_clip
	var pop := card.get("pop") as Control
	if pop != null:
		_set_preview_pop_vertical_offset(pop, ACTIVITY_UNLOCK_NEXT_PREVIEW_SETTLE_OFFSET if bool(card.get("unlock_next_preview_smooth", false)) and not collapse_height else 34.0)


func _preserve_detail_scroll_after_height_change_if_above_view(control: Control) -> void:
	var context := _detail_scroll_height_change_preserve_context(control)
	if context.is_empty():
		return
	_preserve_detail_scroll_after_height_change_deferred(context)


func _detail_scroll_height_change_preserve_context(control: Control) -> Dictionary:
	if current_screen != "skill" or detail_actions_scroll == null or control == null:
		return {}
	if not is_instance_valid(detail_actions_scroll) or not is_instance_valid(control):
		return {}
	var stack := _detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return {}
	var tracked := _detail_stack_child_for_control(control, stack)
	if tracked == null or not is_instance_valid(tracked):
		return {}
	var before_rect := _detail_control_rect_in_stack(tracked, stack)
	var before_scroll := detail_actions_scroll.scroll_vertical
	if before_rect.position.y >= float(before_scroll) - 2.0:
		return {}
	return {
		"tracked_id": tracked.get_instance_id(),
		"before_height": before_rect.size.y,
		"before_scroll": before_scroll,
		"last_scroll": before_scroll,
		"cancelled": false
	}


func _preserve_detail_scroll_after_height_change_deferred(context: Dictionary) -> void:
	await get_tree().process_frame
	_apply_detail_scroll_height_change_preserve_context(1.0, context)


func _apply_detail_scroll_height_change_preserve_context(_progress: float, context: Dictionary) -> void:
	if context.is_empty() or bool(context.get("cancelled", false)):
		return
	if current_screen != "skill" or detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	var last_scroll := int(context.get("last_scroll", context.get("before_scroll", 0)))
	if absi(detail_actions_scroll.scroll_vertical - last_scroll) > 4:
		context["cancelled"] = true
		return
	var tracked := _valid_control_ref(instance_from_id(int(context.get("tracked_id", 0))))
	var stack := _detail_actions_stack()
	if tracked == null or stack == null or not is_instance_valid(stack):
		return
	var after_rect := _detail_control_rect_in_stack(tracked, stack)
	var height_delta := after_rect.size.y - float(context.get("before_height", 0.0))
	if absf(height_delta) <= 0.5:
		return
	var before_scroll := int(context.get("before_scroll", 0))
	var target_scroll := clampi(before_scroll + int(round(height_delta)), 0, detail_actions_scroll.get_max_scroll_vertical())
	detail_actions_scroll.drag_scroll_position = float(target_scroll)
	detail_actions_scroll.scroll_vertical = target_scroll
	context["last_scroll"] = target_scroll


func _sync_locked_activity_preview_presence(card: Dictionary, skill_id: String, action: Dictionary) -> void:
	var root := card.get("root") as Control
	if root == null or not is_instance_valid(root) or root.is_queued_for_deletion():
		return
	if _activity_preview_reveal_animation_pending(card):
		_set_canvas_item_visible_if_changed(root, true)
		return
	var unlocked := _is_action_unlocked(skill_id, action)
	var action_id := str(action.get("id", ""))
	var first_locked_id := _onboarding_runtime()._tutorial_current_locked_preview_action_id(skill_id)
	var waiting_for_unlock_fade := not unlocked and action_id == activity_unlock_preview_after_ceremony_id
	if waiting_for_unlock_fade and bool(card.get("locked_preview_hidden", false)):
		return
	var hidden_preview := false
	if not unlocked and not tutorial_active:
		var hide_first_until_discovered := action_id == first_locked_id and not _locked_activity_preview_available() and not locked_activity_preview_reveal_pending
		hidden_preview = hide_first_until_discovered
	if hidden_preview:
		card["locked_preview_hidden"] = true
		if not card.has("locked_preview_original_clip"):
			card["locked_preview_original_clip"] = root.clip_contents
		var root_height := maxf(root.custom_minimum_size.y, root.size.y)
		if root_height > 0.0:
			card["locked_preview_target_height"] = root_height
		var entry_target_height := _activity_preview_entry_height(card, root, float(card.get("locked_preview_target_height", root_height)))
		if entry_target_height > 1.0:
			card["locked_preview_entry_target_height"] = entry_target_height
		_set_control_minimum_height(root, 0.0)
		_set_activity_preview_entry_height(card, root, 0.0)
		_set_canvas_item_visible_if_changed(root, true)
		_set_canvas_item_modulate_if_changed(root, Color(1, 1, 1, 0))
		root.clip_contents = true
		return
	if bool(card.get("locked_preview_hidden", false)):
		card["locked_preview_hidden"] = false
		_set_canvas_item_visible_if_changed(root, true)
		var restored_height := float(card.get("locked_preview_target_height", _activity_card_preview_root_height(card)))
		_set_control_minimum_height(root, restored_height)
		_set_activity_preview_entry_height(card, root, float(card.get("locked_preview_entry_target_height", restored_height)))
		_set_canvas_item_modulate_if_changed(root, Color.WHITE)
		root.clip_contents = bool(card.get("locked_preview_original_clip", card.get("preview_enter_original_clip", false)))
		card.erase("locked_preview_target_height")
		card.erase("locked_preview_entry_target_height")
		card.erase("locked_preview_original_clip")


func _prepare_locked_activity_preview_fade(card: Dictionary, skill_id: String, action: Dictionary) -> void:
	if not locked_activity_preview_reveal_pending:
		return
	if not bool(locked_activity_preview_reveal_skill_ids.get(skill_id, false)):
		return
	if _is_action_unlocked(skill_id, action):
		return
	var action_id := str(action.get("id", ""))
	if action_id != _onboarding_runtime()._tutorial_current_locked_preview_action_id(skill_id):
		card["locked_preview_fade_in_pending"] = false
		card.erase("locked_preview_reveal_skill_id")
		card.erase("locked_preview_reveal_action_id")
		return
	var preview_key := _action_key(skill_id, action_id)
	if bool(locked_activity_preview_played_action_keys.get(preview_key, false)):
		locked_activity_preview_reveal_skill_ids.erase(skill_id)
		return
	if bool(card.get("locked_preview_fade_in_pending", false)) or card.get("preview_fade_tween") != null:
		return
	locked_activity_preview_reveal_skill_ids.erase(skill_id)
	card["unlock_next_preview_smooth"] = true
	var stable_tutorial_fade := _should_use_stable_tutorial_locked_preview_fade(skill_id, action_id)
	card["stable_preview_fade"] = stable_tutorial_fade
	_stage_activity_preview_enter(card, _should_expand_locked_activity_preview_reveal(skill_id, action_id) and not stable_tutorial_fade)
	card["locked_preview_fade_in_pending"] = true
	card["locked_preview_reveal_skill_id"] = skill_id
	card["locked_preview_reveal_action_id"] = action_id
	locked_activity_preview_fade_play_pending = true


func _should_use_stable_tutorial_locked_preview_fade(skill_id: String, action_id: String) -> bool:
	return (
		_onboarding_runtime()._onboarding_path_active()
		and skill_id == TUTORIAL_STARTER_SKILL_ID
		and action_id == TUTORIAL_LEVEL_TWO_ACTION_ID
	)


func _should_expand_locked_activity_preview_reveal(skill_id: String, action_id: String) -> bool:
	return (
		_onboarding_runtime()._onboarding_path_active()
		and skill_id == TUTORIAL_STARTER_SKILL_ID
		and action_id == TUTORIAL_LEVEL_TWO_ACTION_ID
	)


func _play_pending_locked_activity_preview_reveals() -> void:
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		_prepare_pending_locked_activity_preview_card(card)
		_play_locked_activity_preview_reveal(card)
	for raw_state in _skill_swipe_activity_surface()._preview_state_values():
		var state := raw_state as Dictionary
		if state == null:
			continue
		var preview_cards := state.get("action_cards", []) as Array
		for raw_card in preview_cards:
			var card := raw_card as Dictionary
			_prepare_pending_locked_activity_preview_card(card)
			_play_locked_activity_preview_reveal(card)
	locked_activity_preview_fade_play_pending = false
	locked_activity_preview_reveal_pending = not locked_activity_preview_reveal_skill_ids.is_empty()


func _prepare_pending_locked_activity_preview_card(card: Dictionary) -> void:
	if card == null:
		return
	var skill_id := str(card.get("skill_id", ""))
	var action := card.get("action", {}) as Dictionary
	if skill_id.is_empty() or action.is_empty():
		return
	_prepare_locked_activity_preview_fade(card, skill_id, action)


func _play_locked_activity_preview_reveal(card: Dictionary) -> void:
	if card == null or not bool(card.get("locked_preview_fade_in_pending", false)):
		return
	card["locked_preview_fade_in_pending"] = false
	var skill_id := str(card.get("locked_preview_reveal_skill_id", ""))
	var action_id := str(card.get("locked_preview_reveal_action_id", ""))
	if not skill_id.is_empty():
		locked_activity_preview_reveal_skill_ids.erase(skill_id)
		card.erase("locked_preview_reveal_skill_id")
	card.erase("locked_preview_reveal_action_id")
	if not skill_id.is_empty() and not action_id.is_empty():
		var preview_key := _action_key(skill_id, action_id)
		if bool(locked_activity_preview_played_action_keys.get(preview_key, false)):
			return
		locked_activity_preview_played_action_keys[preview_key] = true
	if _should_release_onboarding_first_module_centering_for_locked_preview(skill_id, action_id):
		onboarding_first_module_center_release_pending = true
		_release_onboarding_first_module_centering()
	_skill_swipe_activity_surface()._play_activity_preview_fade_in(card)


func _should_release_onboarding_first_module_centering_for_locked_preview(skill_id: String, action_id: String) -> bool:
	if current_screen != "skill" or selected_skill_id != TUTORIAL_STARTER_SKILL_ID:
		return false
	if skill_id != TUTORIAL_STARTER_SKILL_ID or action_id.is_empty():
		return false
	if not _onboarding_runtime()._onboarding_path_active():
		return false
	if action_id != _onboarding_runtime()._tutorial_current_locked_preview_action_id(skill_id):
		return false
	var action := _action_data(skill_id, action_id)
	return not action.is_empty() and int(action.get("unlock", 0)) == 2


func _activity_preview_reveal_animation_pending(card: Dictionary) -> bool:
	if card.is_empty():
		return false
	var preview_fade_tween = card.get("preview_fade_tween", null)
	return (
		(
			preview_fade_tween != null
			and is_instance_valid(preview_fade_tween)
			and preview_fade_tween is Tween
			and preview_fade_tween.is_valid()
		)
		or bool(card.get("fade_in_pending", false))
		or bool(card.get("unlock_next_preview_pending", false))
		or bool(card.get("locked_preview_fade_in_pending", false))
	)


func _reveal_locked_activity_card_in_place(card: Dictionary, skill_id: String, action: Dictionary) -> void:
	var root := card.get("root") as Control
	if root == null or not is_instance_valid(root):
		return
	if _activity_preview_reveal_animation_pending(card):
		_set_canvas_item_visible_if_changed(root, true)
		return
	_preserve_detail_scroll_after_height_change_if_above_view(root)
	card["locked_preview_hidden"] = false
	card.erase("locked_preview_target_height")
	card.erase("locked_preview_original_clip")
	card.erase("preview_enter_target_height")
	card.erase("preview_enter_original_clip")
	card.erase("unlock_next_preview_pending")
	card.erase("unlock_next_preview_smooth")
	card.erase("fade_in_pending")
	_app_lifecycle_runtime()._kill_card_tween(card, "preview_fade_tween")
	var target_height := _activity_card_preview_root_height(card)
	if root.custom_minimum_size.y > 1.0:
		target_height = root.custom_minimum_size.y
	elif root.size.y > 1.0:
		target_height = root.size.y
	var minimum_size := root.custom_minimum_size
	minimum_size.y = target_height
	root.custom_minimum_size = minimum_size
	_set_canvas_item_visible_if_changed(root, true)
	_set_canvas_item_modulate_if_changed(root, Color.WHITE)
	root.clip_contents = false
	var pop := card.get("pop") as Control
	if pop != null and is_instance_valid(pop):
		_set_preview_pop_vertical_offset(pop, 0.0)
	if not action.is_empty():
		_skill_detail_surface()._sync_activity_lock_overlay(card, action, _is_action_unlocked(skill_id, action))
		if bool(card.get("passive", false)):
			_passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, _is_action_unlocked(skill_id, action))
		elif not bool(card.get("is_fishing_method", false)) and not bool(card.get("is_fishing_area", false)):
			_skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, _is_action_unlocked(skill_id, action))


func _apply_skill_detail_unlock_refresh_in_place(preview_id: String) -> bool:
	_hold_skill_detail_layout_refresh(0.35)
	if _fishing_rework_active_for_skill(selected_skill_id):
		return false
	for raw_key in action_cards.keys():
		var card := action_cards[raw_key] as Dictionary
		if card == null:
			continue
		var skill_id := str(card.get("skill_id", selected_skill_id))
		if skill_id != selected_skill_id:
			continue
		var action := card.get("action", {}) as Dictionary
		if action.is_empty():
			continue
		if bool(card.get("passive", false)):
			_passive_firepit_surface()._update_passive_card_static_state(card, skill_id, action, _is_action_unlocked(skill_id, action))
		elif bool(card.get("is_fishing_method", false)) or bool(card.get("is_fishing_area", false)):
			continue
		else:
			_skill_swipe_activity_surface()._update_action_card_static_state(card, skill_id, action, _is_action_unlocked(skill_id, action))
	if preview_id.is_empty():
		return true
	if _play_activity_unlock_preview_in_place(preview_id):
		return true
	return false


func _play_activity_unlock_preview_in_place(preview_id: String) -> bool:
	var preview_card := _activity_preview_card_for_action_id(preview_id, true)
	if preview_card.is_empty() and _ensure_activity_unlock_preview_lazy_entry(preview_id):
		preview_card = _activity_preview_card_for_action_id(preview_id, true)
	if preview_card.is_empty():
		return false
	var preview_action := preview_card.get("action", {}) as Dictionary
	if preview_action.is_empty():
		preview_action = _action_data(selected_skill_id, preview_id)
	if preview_action.is_empty():
		return false
	preview_card["unlock_next_preview_smooth"] = true
	if not bool(activity_unlock_preview_staged_action_ids.get(preview_id, false)):
		_stage_activity_unlock_preview_once(preview_id, preview_card, false)
	if not _claim_activity_unlock_preview_play(preview_id):
		_reveal_locked_activity_card_in_place(preview_card, selected_skill_id, preview_action)
		call_deferred("_sync_detail_actions_scroll_limit_deferred")
		return true
	_skill_swipe_activity_surface()._play_activity_preview_fade_in(preview_card)
	call_deferred("_sync_detail_actions_scroll_limit_deferred")
	return true


func _refresh_skill_detail_after_activity_unlock_ceremony() -> void:
	if activity_unlock_ceremony_count > 0:
		activity_unlock_detail_refresh_done = false
		return
	if activity_unlock_detail_refresh_done:
		return
	activity_unlock_detail_refresh_done = true
	if current_screen != "skill":
		_set_activity_unlock_preview_after_ceremony("")
		activity_unlock_heist_preview_after_ceremony_id = ""
		activity_unlock_center_scroll_target = -1
		fishing_auto_unlock_waiting_for_detail_refresh = false
		return
	var preview_id := activity_unlock_preview_after_ceremony_id
	var heist_preview_id := activity_unlock_heist_preview_after_ceremony_id
	_set_activity_unlock_preview_after_ceremony("")
	activity_unlock_heist_preview_after_ceremony_id = ""
	activity_unlock_center_scroll_target = -1
	if not heist_preview_id.is_empty():
		var heist_refresh_scroll := detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1
		await _refresh_visible_skill_detail_action_list(heist_refresh_scroll, selected_skill_id)
		fishing_auto_unlock_waiting_for_detail_refresh = false
		if auto_unlock_lockpads_enabled:
			call_deferred("_auto_unlock_pending_lockpads")
		return
	if _apply_skill_detail_unlock_refresh_in_place(preview_id):
		fishing_auto_unlock_waiting_for_detail_refresh = false
		if auto_unlock_lockpads_enabled:
			call_deferred("_auto_unlock_pending_lockpads")
		return
	var ceremony_refresh_scroll := detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1
	await _refresh_visible_skill_detail_action_list(ceremony_refresh_scroll, selected_skill_id)
	if _fishing_rework_active_for_skill(selected_skill_id):
		_ensure_queued_fishing_unlock_entries_mounted()
	if not preview_id.is_empty():
		if not _play_activity_unlock_preview_in_place(preview_id):
			var preview_card := _activity_preview_card_for_action_id(preview_id)
			if not preview_card.is_empty():
				var preview_action := preview_card.get("action", {}) as Dictionary
				if preview_action.is_empty():
					preview_action = _action_data(selected_skill_id, preview_id)
				_reveal_locked_activity_card_in_place(preview_card, selected_skill_id, preview_action)
	fishing_auto_unlock_waiting_for_detail_refresh = false
	if auto_unlock_lockpads_enabled:
		call_deferred("_auto_unlock_pending_lockpads")


func _activity_preview_card_for_action_id(action_id: String, ensure_lazy_mount := false) -> Dictionary:
	if action_id.is_empty():
		return {}
	if ensure_lazy_mount:
		_ensure_detail_lazy_entry_mounted(action_id)
	var key := _action_key(selected_skill_id, action_id)
	if action_cards.has(key):
		var card := action_cards[key] as Dictionary
		var root := _valid_control_ref(card.get("root"))
		if card != null and root != null:
			return card
		_discard_action_card_key(key)
	if selected_skill_id == "fishing":
		var area_card := _fishing_ui_surface()._fishing_area_card_for_action(selected_skill_id, action_id)
		if not area_card.is_empty() and _valid_control_ref(area_card.get("root")) != null:
			return area_card
	return {}


func _stage_activity_preview_for_action_id(action_id: String, collapse_height := true) -> bool:
	var card := _activity_preview_card_for_action_id(action_id, true)
	if card.is_empty():
		return false
	if bool(card.get("unlock_next_preview_pending", false)):
		return true
	card["unlock_next_preview_smooth"] = true
	if not _stage_activity_unlock_preview_once(action_id, card, collapse_height):
		_stage_activity_preview_enter(card, collapse_height)
	card["fade_in_pending"] = true
	card["unlock_next_preview_pending"] = true
	return true


func _stage_next_locked_activity_preview(collapse_height := false) -> bool:
	var preview_id := activity_unlock_preview_after_ceremony_id
	if preview_id.is_empty():
		return false
	if not _stage_activity_preview_for_action_id(preview_id, collapse_height):
		return false
	_set_activity_unlock_preview_after_ceremony("")
	activity_unlock_detail_refresh_done = true
	return true


func _fade_staged_next_locked_activity_preview(action_id: String) -> void:
	await get_tree().create_timer(ACTIVITY_UNLOCK_NEXT_PREVIEW_FADE_DELAY).timeout
	if current_screen != "skill" or action_id.is_empty():
		return
	var card := _activity_preview_card_for_action_id(action_id)
	if card.is_empty():
		return
	if not bool(card.get("unlock_next_preview_pending", false)):
		return
	card.erase("unlock_next_preview_pending")
	if not _claim_activity_unlock_preview_play(action_id):
		return
	_skill_swipe_activity_surface()._play_activity_preview_fade_in(card)


func _play_next_locked_activity_preview_fade(_collapse_height := false) -> bool:
	var preview_id := activity_unlock_preview_after_ceremony_id
	if preview_id.is_empty():
		return false
	var card := _activity_preview_card_for_action_id(preview_id, true)
	if card.is_empty():
		return false
	if not bool(card.get("unlock_next_preview_pending", false)):
		card["unlock_next_preview_smooth"] = true
		_stage_activity_preview_enter(card, false)
		card["fade_in_pending"] = true
	card.erase("unlock_next_preview_pending")
	if not _claim_activity_unlock_preview_play(preview_id):
		_set_activity_unlock_preview_after_ceremony("")
		return true
	_skill_swipe_activity_surface()._play_activity_preview_fade_in(card)
	_set_activity_unlock_preview_after_ceremony("")
	activity_unlock_center_scroll_target = -1
	activity_unlock_detail_refresh_done = true
	call_deferred("_sync_detail_actions_scroll_limit_deferred")
	return true


func _skill_index(skill_id: String) -> int:
	for i in range(skill_defs.size()):
		if str(skill_defs[i]["id"]) == skill_id:
			return i
	return -1


func _low_stamina_training_text(action: Dictionary) -> String:
	return "%s is training tired at 20%% speed." % str(action.get("name", "Activity"))


func _capture_visible_bonus_snapshot_if_needed(skill_id: String, action_id: String, action: Dictionary) -> Dictionary:
	if _action_completion_could_change_visible_bonuses(skill_id, action_id, action):
		return _capture_visible_bonus_snapshot()
	return {}


func _action_completion_could_change_visible_bonuses(skill_id: String, action_id: String, action: Dictionary) -> bool:
	if skill_id.is_empty() or action_id.is_empty() or action.is_empty():
		return false
	var potential_rewards := _max_action_completion_xp_reward_map(skill_id, action)
	for raw_reward_skill_id in potential_rewards.keys():
		var reward_skill_id := str(raw_reward_skill_id)
		var potential_xp := int(potential_rewards.get(raw_reward_skill_id, 0))
		if potential_xp > 0 and _would_skill_xp_level_up(reward_skill_id, potential_xp):
			return true
	var mastery_reward := _mastery_reward_for_action(skill_id, action_id, action)
	if MasteryState.would_reward_level_up(mastery, _action_key(skill_id, action_id), mastery_reward, MASTERY_MAX_LEVEL):
		return true
	return false


func _max_action_completion_xp_reward_map(skill_id: String, action: Dictionary) -> Dictionary:
	if _fishing_rework_active_for_skill(skill_id) and not _is_event_action(action):
		return {skill_id: _fishing_flat_xp_reward(action, skill_id)}
	var force_plank_bonus := skill_id == "build" and plank_boost_enabled and material_runtime.amount("softwood") >= 1.0
	return _completion_xp_reward_map(action, skill_id, force_plank_bonus, false, true, false)


func _would_skill_xp_level_up(skill_id: String, amount: int) -> bool:
	if amount <= 0 or not skills.has(skill_id):
		return false
	var current_level := _skill_level(skill_id)
	if current_level >= 99:
		return false
	var xp_total := int(skills.get(skill_id, {}).get("xp", 0))
	return xp_total + amount >= SkillState.xp_for_level(current_level + 1)


func _capture_visible_bonus_snapshot() -> Dictionary:
	var action_stats := {}
	var max_stamina_by_skill := {}
	for def in skill_defs:
		var skill_id := str(def["id"])
		max_stamina_by_skill[skill_id] = _max_stamina(skill_id)
	for raw_key in action_cards.keys():
		var key := str(raw_key)
		var card := action_cards[key] as Dictionary
		if not _action_card_can_show_bonus_emphasis(card, key):
			continue
		var parts := key.split(":")
		if parts.size() < 2:
			continue
		var skill_id := str(parts[0])
		var action_id := str(parts[1])
		var action := _action_data(skill_id, action_id)
		if action.is_empty():
			continue
		if _is_passive_action(action):
			continue
		action_stats[key] = {
			"xp": _effective_xp(action, skill_id),
			"stamina": _effective_stamina(skill_id, action),
			"seconds": _action_cycle_seconds(skill_id, action),
			"base_seconds": maxf(0.1, float(action.get("seconds", 1.0))),
			"success": _success_chance(skill_id, action)
		}
	return {
		"max_stamina": _max_stamina(),
		"max_stamina_by_skill": max_stamina_by_skill,
		"global_buff_lines": _global_medal_buff_lines(),
		"actions": action_stats
	}


func _emphasize_visible_bonus_changes(before: Dictionary) -> void:
	if before.is_empty():
		return
	var entries := []
	var old_max_stamina_by_skill := before.get("max_stamina_by_skill", {}) as Dictionary
	for def in skill_defs:
		var skill_id := str(def["id"])
		var old_max_stamina := int(old_max_stamina_by_skill.get(skill_id, before.get("max_stamina", _max_stamina(skill_id))))
		var new_max_stamina := _max_stamina(skill_id)
		if new_max_stamina > old_max_stamina:
			_append_visible_stamina_bonus_entries(entries, new_max_stamina - old_max_stamina, skill_id)
	var old_global_buff_lines := str(before.get("global_buff_lines", _global_medal_buff_lines()))
	if old_global_buff_lines != _global_medal_buff_lines():
		_append_bonus_emphasis_entry(entries, {
			"kind": "global_buff",
			"anchor": achievement_buff_label
		})
	var old_actions := before.get("actions", {}) as Dictionary
	for raw_key in action_cards.keys():
		var key := str(raw_key)
		if not old_actions.has(key):
			continue
		var card := action_cards[key] as Dictionary
		if not _action_card_can_show_bonus_emphasis(card, key):
			continue
		var parts := key.split(":")
		if parts.size() < 2:
			continue
		var skill_id := str(parts[0])
		var action_id := str(parts[1])
		var action := _action_data(skill_id, action_id)
		if action.is_empty():
			continue
		if _is_passive_action(action):
			continue
		var old_stats := old_actions[key] as Dictionary
		var old_xp := int(old_stats.get("xp", _effective_xp(action, skill_id)))
		var new_xp := _effective_xp(action, skill_id)
		if new_xp > old_xp:
			_append_action_stat_bonus_entry(entries, card, key, "xp", "+%s XP" % (new_xp - old_xp))
		var old_stamina := float(old_stats.get("stamina", _effective_stamina(skill_id, action)))
		var new_stamina := _effective_stamina(skill_id, action)
		if new_stamina + 0.0001 < old_stamina:
			_append_action_stat_bonus_entry(entries, card, key, "stamina", "-%s STAM" % GameFormatting.stamina_cost_detail(old_stamina - new_stamina))
		var old_seconds := float(old_stats.get("seconds", _action_cycle_seconds(skill_id, action)))
		var new_seconds := _action_cycle_seconds(skill_id, action)
		if new_seconds + 0.001 < old_seconds:
			var base_seconds := maxf(0.1, float(old_stats.get("base_seconds", action.get("seconds", 1.0))))
			var reduction_pct := (old_seconds - new_seconds) / base_seconds * 100.0
			_append_action_stat_bonus_entry(entries, card, key, "time", GameFormatting.bonus_percent_delta(-reduction_pct))
		var old_success := float(old_stats.get("success", _success_chance(skill_id, action)))
		var new_success := _success_chance(skill_id, action)
		if new_success > old_success + 0.001:
			_append_action_stat_bonus_entry(entries, card, key, "success", GameFormatting.bonus_percent_delta(new_success - old_success))
	_play_visible_bonus_emphasis_entries(entries)


func _emphasize_visible_bonus_changes_deferred(before: Dictionary) -> void:
	if before.is_empty():
		return
	call_deferred("_emphasize_visible_bonus_changes", before)


func _append_visible_stamina_bonus_entries(entries: Array, amount: int, skill_id := "") -> void:
	if amount <= 0:
		return
	var text := "+%s MAX" % amount
	if current_screen == "menu":
		for raw_skill_id in skill_cards.keys():
			var card_skill_id := str(raw_skill_id)
			if not skill_id.is_empty() and card_skill_id != skill_id:
				continue
			var card := skill_cards[raw_skill_id] as Dictionary
			_append_bonus_emphasis_entry(entries, {
				"kind": "stamina",
				"anchor": _reward_feedback_surface()._skill_menu_card_side_gauge(card),
				"text": text,
				"font_size": 66,
				"start_offset": Vector2(0, -54),
				"rise": Vector2(0, -150)
			})
	elif current_screen == "skill" and (skill_id.is_empty() or skill_id == selected_skill_id):
		_append_bonus_emphasis_entry(entries, {
			"kind": "stamina",
			"anchor": detail_regen_circle,
			"text": text,
			"font_size": 72,
			"start_offset": Vector2(0, -70),
			"rise": Vector2(0, -170)
		})


func _append_action_stat_bonus_entry(entries: Array, card: Dictionary, card_key: String, stat_kind: String, text: String) -> void:
	if not _action_card_can_show_bonus_emphasis(card, card_key):
		return
	var boxes := card.get("stat_boxes", {}) as Dictionary
	_append_bonus_emphasis_entry(entries, {
		"kind": "action_stat",
		"anchor": boxes.get(stat_kind) as Control,
		"card": card,
		"card_key": card_key,
		"stat_kind": stat_kind,
		"text": text
	})


func _action_card_can_show_bonus_emphasis(card: Dictionary, card_key := "") -> bool:
	if card.is_empty() or bool(card.get("preview_only", false)):
		return false
	var resolved_key := card_key
	if resolved_key.is_empty():
		resolved_key = _action_card_key_from_card(card)
	var root := _valid_control_ref(card.get("root"))
	if root != null and (not root.visible or root.is_queued_for_deletion()):
		return false
	if current_screen == "skill":
		return _action_card_module_visible_in_detail_scroll(card, resolved_key)
	return root == null or root.is_visible_in_tree()


func _action_card_module_visible_in_detail_scroll(card: Dictionary, card_key: String) -> bool:
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll) or not detail_actions_scroll.is_visible_in_tree():
		return false
	var skill_id := str(card.get("skill_id", ""))
	if skill_id.is_empty() and not card_key.is_empty():
		var key_parts := card_key.split(":")
		if key_parts.size() >= 2:
			skill_id = str(key_parts[0])
	if skill_id != selected_skill_id:
		return false
	var host := _action_card_detail_stack_host(card, card_key)
	if host == null:
		return false
	return _detail_stack_host_visible_in_current_view(host)


func _action_card_detail_stack_host(card: Dictionary, card_key: String) -> Control:
	var stack := _resolve_detail_lazy_stack() as Control
	if stack == null or not is_instance_valid(stack):
		return null
	var entry := _valid_control_ref(card.get("entry"))
	if entry != null:
		var entry_host := _detail_stack_child_for_control(entry, stack)
		return entry_host if entry_host != null else entry
	var root := _valid_control_ref(card.get("root"))
	if root != null:
		var root_host := _detail_stack_child_for_control(root, stack)
		return root_host if root_host != null else root
	if not card_key.is_empty() and detail_action_card_nodes.has(card_key):
		var keyed_host := _valid_control_ref(detail_action_card_nodes.get(card_key))
		if keyed_host != null:
			return keyed_host
	var action_id := str(card.get("action_id", ""))
	if action_id.is_empty() and not card_key.is_empty():
		var key_parts := card_key.split(":")
		if key_parts.size() >= 2:
			action_id = str(key_parts[1])
	if not action_id.is_empty() and detail_action_card_nodes.has(action_id):
		var action_host := _valid_control_ref(detail_action_card_nodes.get(action_id))
		if action_host != null:
			return action_host
	return null


func _detail_stack_host_visible_in_current_view(host: Control) -> bool:
	if host == null or not is_instance_valid(host) or not host.visible or not host.is_visible_in_tree() or host.is_queued_for_deletion():
		return false
	var stack := _resolve_detail_lazy_stack() as Control
	if stack == null or not is_instance_valid(stack):
		return false
	var rect := _detail_control_rect_in_stack(host, stack)
	if rect.size.y <= 1.0:
		return false
	var view_top := _detail_lazy_scroll_y()
	var view_bottom := view_top + _detail_lazy_viewport_height()
	var visible_height := minf(rect.position.y + rect.size.y, view_bottom) - maxf(rect.position.y, view_top)
	return visible_height > 1.0


func _append_bonus_emphasis_entry(entries: Array, entry: Dictionary) -> void:
	var anchor := entry.get("anchor") as Control
	if not _is_bonus_emphasis_anchor_visible(anchor):
		return
	var rect := anchor.get_global_rect()
	entry["screen_y"] = rect.position.y
	entry["screen_x"] = rect.position.x
	entries.append(entry)


func _is_bonus_emphasis_anchor_visible(anchor: Control) -> bool:
	if anchor == null or not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
		return false
	var rect := anchor.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	var visible_rect := _bonus_emphasis_visible_rect_for_anchor(anchor)
	if visible_rect.size.x <= 1.0 or visible_rect.size.y <= 1.0 or not rect.intersects(visible_rect):
		return false
	if _bonus_emphasis_rect_intersects_visible_overlay(rect):
		return false
	var clipped := rect.intersection(visible_rect)
	var visible_area := clipped.size.x * clipped.size.y
	var full_area := rect.size.x * rect.size.y
	return full_area > 0.0 and visible_area / full_area >= 0.82


func _bonus_emphasis_visible_rect_for_anchor(_anchor: Control) -> Rect2:
	var visible_rect := Rect2(Vector2.ZERO, _current_canvas_size())
	if current_screen == "skill" and detail_actions_scroll != null and is_instance_valid(detail_actions_scroll) and detail_actions_scroll.is_visible_in_tree():
		visible_rect = visible_rect.intersection(detail_actions_scroll.get_global_rect())
	elif skills_page != null and is_instance_valid(skills_page) and skills_page.is_visible_in_tree():
		visible_rect = visible_rect.intersection(skills_page.get_global_rect())
	var chat_rect := _visible_control_global_rect(chat_strip)
	if chat_rect.size.x > 1.0 and chat_rect.size.y > 1.0:
		var chat_cropped_end_y := minf(visible_rect.end.y, chat_rect.position.y)
		visible_rect.size.y = maxf(0.0, chat_cropped_end_y - visible_rect.position.y)
	var nav_rect := _visible_control_global_rect(nav_bar)
	if nav_rect.size.x > 1.0 and nav_rect.size.y > 1.0:
		var nav_cropped_end_y := minf(visible_rect.end.y, nav_rect.position.y)
		visible_rect.size.y = maxf(0.0, nav_cropped_end_y - visible_rect.position.y)
	return visible_rect


func _bonus_emphasis_rect_intersects_visible_overlay(rect: Rect2) -> bool:
	var chat_rect := _visible_control_global_rect(chat_strip)
	if chat_rect.size.x > 1.0 and chat_rect.size.y > 1.0 and rect.intersects(chat_rect):
		return true
	var nav_rect := _visible_control_global_rect(nav_bar)
	if nav_rect.size.x > 1.0 and nav_rect.size.y > 1.0 and rect.intersects(nav_rect):
		return true
	return false


func _visible_control_global_rect(control: Control) -> Rect2:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return Rect2()
	return control.get_global_rect()


func _play_visible_bonus_emphasis_entries(entries: Array) -> void:
	if entries.is_empty():
		return
	entries.sort_custom(Callable(self, "_sort_bonus_emphasis_entries"))
	var highlighted_card_delays := {}
	var entry_count := entries.size()
	for i in range(entry_count):
		var entry := entries[i] as Dictionary
		var delay := 0.0 if entry_count <= 1 else lerpf(0.0, BONUS_EMPHASIS_CASCADE_SECONDS, float(i) / float(entry_count - 1))
		_play_bonus_emphasis_entry(entry, delay, i)
		var card_key := str(entry.get("card_key", ""))
		if not card_key.is_empty() and not highlighted_card_delays.has(card_key):
			highlighted_card_delays[card_key] = delay
	for key in highlighted_card_delays.keys():
		if action_cards.has(key):
			_reward_feedback_surface()._flash_action_bonus_bottom(action_cards[key] as Dictionary, float(highlighted_card_delays[key]))


func _sort_bonus_emphasis_entries(a: Dictionary, b: Dictionary) -> bool:
	var ay := float(a.get("screen_y", 0.0))
	var by := float(b.get("screen_y", 0.0))
	if absf(ay - by) > 1.0:
		return ay < by
	return float(a.get("screen_x", 0.0)) < float(b.get("screen_x", 0.0))


func _play_bonus_emphasis_entry(entry: Dictionary, delay: float, sequence_index := 0) -> void:
	var kind := str(entry.get("kind", ""))
	if kind == "action_stat":
		_emphasize_action_stat_bonus(entry.get("card", {}) as Dictionary, str(entry.get("stat_kind", "")), str(entry.get("text", "")), delay, sequence_index, str(entry.get("card_key", "")))
	elif kind == "stamina":
		var anchor := entry.get("anchor") as Control
		_reward_feedback_surface()._flash_bonus_control(anchor, delay)
		_reward_feedback_surface()._float_reward(self, anchor, str(entry.get("text", "")), int(entry.get("font_size", 66)), BONUS_EMPHASIS_FLOAT_COLOR, entry.get("start_offset", Vector2.ZERO), entry.get("rise", Vector2(0, -150)), delay)
	elif kind == "global_buff":
		_emphasize_global_buff_label(delay)


func _emphasize_action_stat_bonus(card: Dictionary, stat_kind: String, text: String, delay := 0.0, sequence_index := 0, card_key := "") -> void:
	if not _action_card_can_show_bonus_emphasis(card, card_key):
		return
	if delay > 0.0:
		var delayed_card_key := card_key
		if delayed_card_key.is_empty():
			delayed_card_key = _action_card_key_from_card(card)
		if delayed_card_key.is_empty():
			return
		var delayed_tween := create_tween()
		delayed_tween.tween_interval(delay)
		delayed_tween.tween_callback(_emphasize_action_stat_bonus_by_key.bind(delayed_card_key, stat_kind, text, sequence_index))
		return
	var boxes := card.get("stat_boxes", {}) as Dictionary
	var box := boxes.get(stat_kind) as Control
	if not _is_bonus_emphasis_anchor_visible(box):
		return
	_reward_feedback_surface()._flash_bonus_control(box)
	_reward_feedback_surface()._float_reward(self, box, text, 70, BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -58), Vector2(0, -154), 0.0)
	_audio_director()._play_info_chip_upgrade_sfx(sequence_index)


func _emphasize_action_stat_bonus_by_key(card_key: String, stat_kind: String, text: String, sequence_index := 0) -> void:
	if not action_cards.has(card_key):
		return
	var card := action_cards[card_key] as Dictionary
	if not _action_card_can_show_bonus_emphasis(card, card_key):
		return
	_emphasize_action_stat_bonus(card, stat_kind, text, 0.0, sequence_index, card_key)


func _action_card_key_from_card(card: Dictionary) -> String:
	var card_key := str(card.get("key", ""))
	if not card_key.is_empty():
		return card_key
	var skill_id := str(card.get("skill_id", ""))
	var action_id := str(card.get("action_id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	return _action_key(skill_id, action_id)


func _emphasize_global_buff_label(delay := 0.0) -> void:
	if achievement_buff_label == null or not is_instance_valid(achievement_buff_label) or not achievement_buff_label.is_visible_in_tree():
		return
	_reward_feedback_surface()._flash_bonus_control(achievement_buff_label, delay)
	_reward_feedback_surface()._float_reward(self, achievement_buff_label, "BUFF UP", 66, BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -46), Vector2(0, -138), delay)


func _regen_stamina(delta: float) -> void:
	_action_runtime()._process_action_opportunity_regen(delta)
	_apply_stamina_regen_seconds(delta, true)
	_fighting_runtime().apply_blue_guy_health_regen_seconds(delta)


func _apply_stamina_regen_seconds(seconds: float, allow_gauge_boost := false) -> void:
	_apply_stamina_regen_seconds_except(seconds, allow_gauge_boost, "")


func _apply_stamina_regen_seconds_except(seconds: float, allow_gauge_boost := false, excluded_skill_id := "") -> void:
	if seconds <= 0.0:
		return
	var honey_adjusted_seconds := _honey_adjusted_stamina_regen_seconds(seconds, excluded_skill_id)
	for def in skill_defs:
		var skill_id := str(def["id"])
		if skill_id == excluded_skill_id:
			continue
		var max_stamina := _max_stamina(skill_id)
		if _stamina_value(skill_id) >= float(max_stamina):
			stamina_bank[skill_id] = 0.0
			continue
		var regen_delta := honey_adjusted_seconds * (1.0 + _hub_surface()._hub_pond_regen_bonus())
		regen_delta *= 1.0 + _passive_modules_runtime().firepit_stamina_regen_bonus(skill_id, _unix_now())
		if allow_gauge_boost and skill_id == stamina_gauge_boost_skill_id:
			regen_delta *= stamina_gauge_regen_multiplier
		if allow_gauge_boost and skill_id == action_opportunity_regen_skill_id and action_opportunity_regen_seconds > 0.0:
			regen_delta *= ACTION_OPPORTUNITY_REGEN_MULT
		var next_bank := clampf(float(stamina_bank.get(skill_id, 0.0)), 0.0, STAMINA_REGEN_SECONDS) + regen_delta
		var recovered_stamina := int(floor(next_bank / STAMINA_REGEN_SECONDS))
		var next_stamina := _stamina_value(skill_id)
		if recovered_stamina > 0:
			next_stamina = minf(float(max_stamina), next_stamina + float(recovered_stamina))
		stamina[skill_id] = next_stamina
		stamina_bank[skill_id] = 0.0 if next_stamina >= float(max_stamina) - 0.0001 else fmod(next_bank, STAMINA_REGEN_SECONDS)
		_sync_stamina_bank(skill_id)


func _award_fish_currency(amount: float) -> void:
	var safe_amount := maxf(0.0, amount)
	if safe_amount <= 0.0:
		return
	fish_currency += safe_amount
	fish_currency_ever_earned = true
	_fishing_ui_surface()._sync_auto_eat_fish_toggle_buttons()


func _fish_currency_display_text(count: float) -> String:
	return GameFormatting.compact_number(maxf(0.0, count), 3)


func _fish_currency_range_display_text(min_count: float, max_count: float) -> String:
	var safe_min := maxf(0.0, min_count)
	var safe_max := maxf(safe_min, max_count)
	var suffixes := ["K", "M", "B", "T", "Qa", "Qi"]
	var min_scaled := safe_min
	var max_scaled := safe_max
	var min_suffix := -1
	var max_suffix := -1
	while absf(min_scaled) >= 1000.0 and min_suffix < suffixes.size() - 1:
		min_scaled /= 1000.0
		min_suffix += 1
	while absf(max_scaled) >= 1000.0 and max_suffix < suffixes.size() - 1:
		max_scaled /= 1000.0
		max_suffix += 1
	if min_suffix >= 0 and min_suffix == max_suffix:
		var min_text := GameFormatting.trim_trailing_decimal_zeroes(GameFormatting.significant_digits(min_scaled, 3))
		var max_text := GameFormatting.trim_trailing_decimal_zeroes(GameFormatting.significant_digits(max_scaled, 3))
		return "%s-%s%s" % [min_text, max_text, suffixes[min_suffix]]
	return "%s-%s" % [_fish_currency_display_text(safe_min), _fish_currency_display_text(safe_max)]


func _set_fish_circle_for_skill_bound(circle_id: int, skill_id: String, instant := false) -> void:
	var circle := instance_from_id(circle_id) as FishCircle
	_set_fish_circle_for_skill(circle, skill_id, instant)


func _set_fish_circle_for_skill(circle: FishCircle, skill_id: String, instant := false) -> void:
	if circle == null or not is_instance_valid(circle):
		return
	if not circle.is_inside_tree():
		return
	circle.set_theme_color(_skill_theme_color(skill_id))
	circle.set_fish_count(fish_currency, _fish_currency_display_text(fish_currency), instant)
	var tool_def := _fishing_tool_def(equipped_fishing_tool_id)
	circle.set_tool_text("")
	circle.set_tool_icon(str(tool_def.get("art", "res://assets/content/fishing/tools/tool-bare-hands.png")))


func _auto_eat_fish_enabled_for_skill(skill_id: String) -> bool:
	if skill_id.is_empty() or _fishing_rework_active_for_skill(skill_id):
		return false
	return bool(auto_eat_fish_enabled_by_skill.get(skill_id, false))


func _set_auto_eat_fish_enabled_for_skill(skill_id: String, enabled: bool) -> void:
	if skill_id.is_empty() or _fishing_rework_active_for_skill(skill_id):
		return
	if enabled:
		auto_eat_fish_enabled_by_skill[skill_id] = true
	else:
		auto_eat_fish_enabled_by_skill.erase(skill_id)


func _auto_eat_fish_enabled_by_skill_for_save() -> Dictionary:
	var enabled_by_skill := {}
	for raw_skill_id in auto_eat_fish_enabled_by_skill.keys():
		var skill_id := str(raw_skill_id)
		if _auto_eat_fish_enabled_for_skill(skill_id):
			enabled_by_skill[skill_id] = true
	return enabled_by_skill


func _restore_auto_eat_fish_enabled_from_save(data: Dictionary) -> void:
	auto_eat_fish_enabled_by_skill.clear()
	var raw_enabled_by_skill = data.get("auto_eat_fish_enabled_by_skill", null)
	if raw_enabled_by_skill is Dictionary:
		var enabled_by_skill := raw_enabled_by_skill as Dictionary
		for raw_skill_id in enabled_by_skill.keys():
			var skill_id := str(raw_skill_id)
			_set_auto_eat_fish_enabled_for_skill(skill_id, bool(enabled_by_skill.get(raw_skill_id, false)))
		return
	if bool(data.get("auto_eat_fish_enabled", false)):
		for raw_skill_id in skills.keys():
			var skill_id := str(raw_skill_id)
			if not _fishing_rework_active_for_skill(skill_id):
				_set_auto_eat_fish_enabled_for_skill(skill_id, true)


func _set_regen_circle_for_skill(circle: RegenCircle, skill_id: String, instant := false) -> void:
	if circle == null or not is_instance_valid(circle) or not circle.is_inside_tree():
		return
	var maximum := _max_stamina(skill_id)
	var stamina_value := _stamina(skill_id)
	var stamina_decimal_fraction := SkillState.stamina_fraction(stamina, skill_id, Callable(self, "_max_stamina"))
	var circle_value := _stamina_regen_fraction(skill_id)
	circle.set_dark_mode(dark_mode_enabled)
	circle.set_theme_color(_skill_theme_color(skill_id))
	circle.set_regen_ring_color(_stamina_regen_circle_color(skill_id), instant)
	circle.set_firepit_warmth(_passive_modules_runtime().firepit_stamina_regen_bonus(skill_id, _unix_now()) / (PassiveModulesRuntime.FIREPIT_STAMINA_REGEN_PER_TIER * float(PassiveModulesRuntime.FIREPIT_MAX_HEAT_TIER)))
	circle.set_show_decimal(show_stamina_decimal)
	circle.set_stamina(stamina_value, maximum, instant, stamina_decimal_fraction)
	circle.set_value(circle_value, instant)


func _start_action_from_card_tap(skill_id: String, action_id: String, visual_card_key := "") -> bool:
	if _material_collection_surface().berry_mode_card_tap_handled(skill_id, action_id):
		return false
	return _action_runtime()._start_action_from_card_tap(skill_id, action_id, visual_card_key)

func _pop_activity_button(action_key: String) -> void:
	if not action_cards.has(action_key):
		return
	var card := action_cards[action_key] as Dictionary
	if action_key.begins_with("thieving_heist:"):
		var heist_button := _valid_control_ref(card.get("button"))
		if heist_button != null:
			_animate_activity_press_effect(heist_button, "%s:button" % action_key, 0.965)
		return
	var pop := _valid_control_ref(card.get("pop"))
	if pop != null:
		_skill_swipe_activity_surface()._animate_action_card_3d_click(action_key)
		return
	if card.get("is_fishing_method"):
		var art_panel := _valid_control_ref(card.get("art_panel"))
		if art_panel != null:
			_animate_activity_press_effect(art_panel, action_key, 0.982)


func _press_activity_stat_box(action_key: String, stat_kind: String) -> void:
	if not action_cards.has(action_key):
		return
	var card := action_cards[action_key] as Dictionary
	var boxes := card.get("stat_boxes", {}) as Dictionary
	var box := boxes.get(stat_kind) as Control
	if box == null:
		return
	_animate_activity_press_effect(box, "%s:stat:%s" % [action_key, stat_kind], 0.94)


func _animate_activity_press_effect(control: Control, tween_key: String, pressed_scale: float) -> void:
	if control == null or not is_instance_valid(control):
		return
	if action_pop_tweens.has(tween_key):
		_app_lifecycle_runtime()._kill_tween_value(action_pop_tweens[tween_key])
	control.scale = Vector2.ONE
	control.pivot_offset = control.size * 0.5
	var tween := create_tween()
	action_pop_tweens[tween_key] = tween
	tween.tween_property(control, "scale", Vector2(pressed_scale, pressed_scale), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_activity_press_effect.bind(tween_key))


func _finish_activity_press_effect(tween_key: String) -> void:
	action_pop_tweens.erase(tween_key)


func _clear_action_pop_tweens() -> void:
	for tween in action_pop_tweens.values():
		_app_lifecycle_runtime()._kill_tween_value(tween)
	action_pop_tweens.clear()


func _hold_bottom_nav_transition_button(button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if bottom_nav_transition_button_id != 0 and bottom_nav_transition_button_id != button.get_instance_id():
		_button_press_runtime()._release_bottom_nav_transition_button()
	var button_id := button.get_instance_id()
	bottom_nav_transition_button_id = button_id
	button.set_meta("bottom_nav_transition_hold", true)
	_button_press_runtime().clear_nav_pop_tween(button_id)
	_button_press_runtime().animate_button_depress(button, float(button.get_meta("depress_animation_scale", 0.92)))


func _bottom_nav_transition_visual_active() -> bool:
	if direct_skill_nav_cover_active or skill_swipe_outgoing_cover_active or skill_swipe_rebuild_cover_active or skill_detail_refresh_cover_active:
		return true
	if _skill_swipe_handoff_cover_is_cream_transition() or _navigation_shell()._page_switch_scroll_cover_active():
		return true
	if pin_transition_blocker != null and is_instance_valid(pin_transition_blocker) and pin_transition_blocker.visible:
		return true
	return screen_render_in_progress or not pending_screen_render_request.is_empty()


func _release_current_action_card_press_state() -> void:
	if action_card_press_key.is_empty() and action_card_press_stat_kind.is_empty() and not action_card_press_dragged:
		return
	_skill_swipe_activity_surface()._release_action_card_3d_press(action_card_press_key)
	action_card_press_key = ""
	action_card_press_stat_kind = ""
	action_card_press_dragged = false


func _normalize_skill_menu_card_button(card: Dictionary) -> void:
	var button := card.get("button") as BaseButton
	if button == null or not is_instance_valid(button):
		return
	if button.scale.x <= 1.0001 and button.scale.y <= 1.0001:
		return
	_button_press_runtime().kill_button_depress_tween(button)
	button.scale = Vector2.ONE
	button.pivot_offset = button.size * 0.5


func _top_level_nav_allowed(target_screen: String) -> bool:
	var now := Time.get_ticks_msec()
	if screen_render_in_progress or _skill_swipe_loading_transition_active():
		return false
	if now < top_level_nav_locked_until_msec:
		return false
	if current_screen == target_screen:
		return false
	top_level_nav_locked_until_msec = now + TOP_LEVEL_NAV_DEBOUNCE_MSEC
	return true


func _select_skill(skill_id: String) -> void:
	if _consume_skill_menu_gauge_parent_suppression(skill_id):
		return
	_select_skill_with_initial_scroll(skill_id, true, -1)


func _select_skill_from_page_switch(skill_id: String, source_button: Button = null) -> void:
	if _navigation_shell()._page_switch_transition_active():
		return
	if _onboarding_runtime()._onboarding_path_active() and not _onboarding_runtime()._onboarding_swipe_to_other_skills_allowed():
		if not onboarding_swipe_tip_sequence_running:
			call_deferred("_run_onboarding_swipe_tip_sequence")
		_navigation_shell()._release_page_switch_transition_button()
		return
	_complete_onboarding_swipe_navigation_attempt(skill_id)
	if source_button != null and is_instance_valid(source_button) and page_switch_transition_button_id == 0:
		_navigation_shell()._hold_page_switch_transition_button(source_button, skill_id)
	_navigation_shell()._begin_page_switch_scroll_cover()
	var cover := skill_swipe_handoff_cover
	if cover == null or not is_instance_valid(cover):
		_navigation_shell()._release_page_switch_transition_button()
		_select_skill_with_initial_scroll(skill_id, false, DETAIL_RESTORE_SCROLL_BOTTOM, false)
		return
	var cover_id := cover.get_instance_id()
	_navigation_shell()._queue_page_switch_transition("select_skill", cover_id, {
		"skill_id": skill_id,
		"scroll_latest_activity": false,
		"restore_detail_scroll": DETAIL_RESTORE_SCROLL_BOTTOM,
		"play_nav_sfx": false,
	})


func _complete_onboarding_swipe_navigation_attempt(target_skill_id: String) -> void:
	if not _onboarding_runtime()._onboarding_path_active():
		return
	if selected_skill_id != TUTORIAL_STARTER_SKILL_ID or target_skill_id == TUTORIAL_STARTER_SKILL_ID:
		return
	if not onboarding_swipe_navigation_unlocked:
		return
	_tutorial_overlay_surface()._fade_tip_group("skill_swipe_tip_notes", false, true)
	_fade_out_onboarding_swipe_overlay_tip()
	_onboarding_runtime()._mark_skill_swipe_tip_seen()


func _select_skill_with_initial_scroll(skill_id: String, scroll_latest_activity: bool, restore_detail_scroll: int, play_nav_sfx := true) -> void:
	if screen_render_in_progress or (_skill_swipe_loading_transition_active() and not _navigation_shell()._page_switch_scroll_cover_active()):
		return
	if not _onboarding_runtime()._onboarding_skill_accessible(skill_id):
		var card := skill_cards.get(skill_id, {}) as Dictionary
		var source := card.get("button") as Control
		_onboarding_runtime()._show_onboarding_skill_locked_message(source)
		return
	if current_screen == "settings":
		_settings_surface()._disarm_reset_data_confirmation()
	if skill_id != selected_skill_id and selected_skill_id == TUTORIAL_STARTER_SKILL_ID:
		_onboarding_runtime()._clear_tutorial_gate_latch_only_after_skill_swipe(false)
	if current_screen != "skill":
		_begin_direct_skill_nav_cover()
	selected_skill_id = skill_id
	current_screen = "skill"
	if play_nav_sfx:
		_button_press_runtime().play_default_button_sfx()
	if tutorial_active:
		action_cards.clear()
		action_card_keys.clear()
		detail_action_card_nodes.clear()
		detail_rendered_action_ids.clear()
		detail_lazy_plan.clear()
		_render_screen(false, 0)
	else:
		_render_screen(scroll_latest_activity, restore_detail_scroll)
	if _navigation_shell()._page_switch_scroll_cover_active():
		_navigation_shell().call_deferred("_fade_clear_page_switch_scroll_cover")


func _show_home(source_button: Control = null) -> void:
	if not _top_level_nav_allowed("home"):
		return
	if not _hero_unlocked():
		_navigation_shell()._show_hero_locked_message(source_button)
		return
	_navigation_shell()._mark_nav_symbol_seen("hero")
	if current_screen == "settings":
		_settings_surface()._disarm_reset_data_confirmation()
	if current_screen == "skill":
		_complete_passive_module_tip_page_visit()
		_complete_silver_opportunity_tip_page_visit()
	current_screen = "home"
	_reward_feedback_surface()._clear_skill_reward_floats()
	_update_page_visibility()
	if not home_page_built:
		call_deferred("_finish_show_home")
		return
	_finish_show_home()


func _finish_show_home() -> void:
	if current_screen != "home":
		return
	_ensure_home_page()
	_update_page_visibility()
	_scroll_home_to_top()
	_achievement_overlay_surface()._queue_home_achievement_refresh()


func _show_skills(use_page_cover := false) -> void:
	if current_screen == "menu":
		return
	if not _top_level_nav_allowed("menu"):
		return
	if current_screen == "settings":
		_settings_surface()._disarm_reset_data_confirmation()
	if current_screen == "skill":
		_complete_passive_module_tip_page_visit()
		_complete_silver_opportunity_tip_page_visit()
	if use_page_cover:
		var cover_id := _navigation_shell()._begin_page_switch_scroll_cover_timed()
		if cover_id == 0:
			_complete_show_skills()
		else:
			_navigation_shell()._queue_page_switch_transition("show_skills", cover_id)
		return
	_complete_show_skills()


func _complete_show_skills() -> void:
	current_screen = "menu"
	await _render_screen()
	_navigation_shell()._fade_clear_page_switch_scroll_cover()


func _show_skills_module() -> void:
	if current_screen == "skill":
		return
	if not _top_level_nav_allowed("skill"):
		return
	var previous_screen := current_screen
	var can_reveal_current_skill_page := previous_screen == "home" or previous_screen == "achievements"
	if current_screen == "settings":
		_settings_surface()._disarm_reset_data_confirmation()
		if bottom_nav_open_close_return_to_skill_active:
			if not _settings_surface().settings_return_skill_id.is_empty() and SkillState.has_skill_id(skill_defs, _settings_surface().settings_return_skill_id):
				selected_skill_id = _settings_surface().settings_return_skill_id
			current_screen = "skill"
		else:
			_select_launch_skill_page()
	elif not SkillState.has_skill_id(skill_defs, selected_skill_id):
		_select_launch_skill_page()
	else:
		current_screen = "skill"
	if can_reveal_current_skill_page and not _onboarding_runtime()._onboarding_path_active():
		if _try_reveal_current_skill_page(_navigation_shell()._screen_page_cache_key(current_screen), true):
			return
	_render_screen(true)
	if _onboarding_runtime()._onboarding_path_active():
		call_deferred("_resync_onboarding_skill_detail_after_navigation")


func _show_hub(source_button: Control = null) -> void:
	if not _top_level_nav_allowed("hub"):
		return
	if not _hub_unlocked():
		_navigation_shell()._show_hub_locked_message(source_button)
		return
	_navigation_shell()._mark_nav_symbol_seen("hub")
	if current_screen == "settings":
		_settings_surface()._disarm_reset_data_confirmation()
	current_screen = "hub"
	_hub_surface().hub_detail_open = false
	_render_screen()


func _show_shop(source_button: Control = null) -> void:
	if not _top_level_nav_allowed("shop"):
		return
	if source_button != null and not _shop_unlocked():
		_navigation_shell()._show_shop_locked_message(source_button)
		return
	if _shop_unlocked():
		_navigation_shell()._mark_nav_symbol_seen("shop")
	if current_screen == "settings":
		_settings_surface()._disarm_reset_data_confirmation()
	current_screen = "shop"
	_render_screen()


func _show_leaderboard() -> void:
	if not _top_level_nav_allowed("leaderboard"):
		return
	_online_runtime().ensure_leaderboard_http()
	if current_screen == "settings":
		_settings_surface()._disarm_reset_data_confirmation()
	current_screen = "leaderboard"
	_online_runtime().fetch_leaderboard_category(leaderboard_category_id)
	_button_press_runtime().play_default_button_sfx()
	_render_screen()


func _scroll_home_to_top() -> void:
	if home_scroll == null or not is_instance_valid(home_scroll):
		return
	home_scroll.drag_scroll_position = 0.0
	home_scroll.scroll_vertical = 0


func _event_is_outside_panel_press(event: InputEvent, panel: Control) -> bool:
	if panel == null or not is_instance_valid(panel):
		return false
	var panel_rect := panel.get_global_rect()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		return not panel_rect.has_point(event.global_position)
	if event is InputEventScreenTouch and event.pressed:
		return not panel_rect.has_point(event.position)
	return false

func _force_tutorial_skill_scroll_to_top() -> void:
	if not tutorial_active or current_screen != "skill":
		return
	if detail_actions_scroll == null or not is_instance_valid(detail_actions_scroll):
		return
	if detail_lazy_plan.size() > 0 and not _skill_detail_stack_has_visible_modules(_detail_actions_stack()):
		_repair_blank_detail_lazy_stack()
	detail_actions_scroll.drag_scroll_position = 0.0
	detail_actions_scroll.scroll_vertical = 0
	_update_skill_detail_shadow(0.0, true)
	_tutorial_overlay_surface().call_deferred("_sync_tutorial_target_indicator")


func _mastery_medal_name(level: int) -> String:
	if level <= 0:
		return "Unranked"
	return str(MASTERY_MEDAL_NAMES[clampi(level, 1, MASTERY_MAX_LEVEL) - 1])


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


func _skill_icon_path(skill_id: String) -> String:
	return "res://assets/content/icons/skill-symbols/%s.png" % skill_id


func _set_result(text: String, play_sfx := true) -> void:
	_reward_feedback_surface()._set_result(text, play_sfx)

func _activity_data_catalog() -> ActivityDataCatalog:
	return activity_data_catalog


const FISHING_AREA_FLUID_KINDS := ["water", "sewer", "lava", "space", "deep_water", "storm", "ice"]


func _fishing_method_should_show(skill_id: String, action_id: String) -> bool:
	return fishing_runtime.method_should_show(self, skill_id, action_id, FISHING_LOCATION_DEFS, FISHING_TOOL_LOCATION_ACTIONS)


func _fishing_render_area_modules(skill_id: String) -> Array:
	return fishing_runtime.render_area_modules(self, skill_id, FISHING_LOCATION_DEFS, FISHING_TOOL_LOCATION_ACTIONS, FISHING_AREA_MAX_BUTTONS_PER_MODULE)


func _fishing_render_area_module_for_action(skill_id: String, action_id: String) -> Dictionary:
	if action_id.is_empty():
		return {}
	for raw_area in _fishing_render_area_modules(skill_id):
		var area_def := raw_area as Dictionary
		for raw_method_id in _fishing_area_module_method_ids(skill_id, area_def):
			if str(raw_method_id) == action_id:
				return area_def
	return {}


func _fishing_render_module_unlock(area_def: Dictionary) -> int:
	return fishing_runtime.render_module_unlock(self, area_def, FISHING_LOCATION_DEFS, FISHING_TOOL_LOCATION_ACTIONS)


func _fishing_preview_after_manual_unlock(unlocked_action_id: String) -> String:
	var next_location_preview := fishing_runtime.first_locked_location_action_after_manual_unlock(self, unlocked_action_id, "", FISHING_LOCATION_DEFS, FISHING_TOOL_LOCATION_ACTIONS)
	if not next_location_preview.is_empty():
		return next_location_preview
	return ""


func _fishing_method_short_label(action: Dictionary) -> String:
	var action_id := str(action.get("id", ""))
	var custom := {
		"beach-shallows": "Shallows",
		"beach-rocks": "Rocks",
		"reef-pot": "Reef Pot",
		"stormy-sea-ripple": "Storm Ripple",
		"pier-dock-edge": "Dock Edge",
		"pier-piling-line": "Piling Line",
		"river-bend": "River Bend",
		"river-rapids": "Rapids",
		"sewers-drain-gate": "Drain Gate",
		"sewers-tunnel-pool": "Tunnel Pool",
		"winter-lake-ice-hole": "Ice Hole",
		"reef-cage": "Reef Cage",
		"reef-night-reef": "Night Reef",
		"reef-pearl-bed": "Pearl Bed",
		"sea-rowboat": "Rowboat",
		"sea-open-water": "Open Water",
		"sea-chum-line": "Chum Line",
		"stormy-sea-storm-line": "Storm Line",
		"deep-sea-wreck-drop": "Wreck Drop",
		"deep-sea-abyss": "Abyss",
		"deep-sea-trench": "Deep Trench",
		"space-starlight": "Starlight",
		"space-reflection": "Reflection",
	}
	if custom.has(action_id):
		return str(custom[action_id])
	var words := str(action.get("name", "")).split(" ")
	return words[0] if not words.is_empty() else action_id


func _fishing_area_focused_method_label(action: Dictionary) -> String:
	var action_id := str(action.get("id", ""))
	var custom := {
		"river-bend": "River Bend",
		"river-rapids": "Rapids",
		"sewers-drain-gate": "Drain Gate",
		"sewers-tunnel-pool": "Tunnel Pool",
		"winter-lake-ice-hole": "Ice Hole",
		"reef-cage": "Reef Cage",
		"reef-night-reef": "Night Reef",
		"reef-pearl-bed": "Pearl Bed",
		"sea-rowboat": "Rowboat",
		"sea-open-water": "Open Water",
		"sea-chum-line": "Chum Line",
		"stormy-sea-storm-line": "Storm Line",
		"deep-sea-wreck-drop": "Wreck Drop",
		"deep-sea-abyss": "Abyss",
		"deep-sea-trench": "Deep Trench",
		"space-starlight": "Starlight",
		"space-reflection": "Reflection",
		"reef-pot": "Reef Pot",
		"stormy-sea-ripple": "Storm Ripple",
	}
	if custom.has(action_id):
		return str(custom[action_id])
	return _fishing_method_short_label(action)


func _fishing_tool_def(tool_id: String) -> Dictionary:
	for raw_tool in FISHING_TOOL_DEFS:
		var tool := raw_tool as Dictionary
		if str(tool.get("id", "")) == tool_id:
			return tool
	return FISHING_TOOL_DEFS[0] as Dictionary


func _fishing_tool_label(tool_id: String) -> String:
	return str(_fishing_tool_def(tool_id).get("name", tool_id.capitalize()))


func _fishing_rod_offer_available() -> bool:
	return not fishing_rod_collected and _skill_level("fishing") >= FISHING_ROD_OFFER_UNLOCK_LEVEL


func _fishing_net_offer_available() -> bool:
	return not fishing_net_collected and _skill_level("fishing") >= FISHING_NET_OFFER_UNLOCK_LEVEL


func _fishing_reinforced_rod_offer_available() -> bool:
	return fishing_rod_collected and not fishing_reinforced_rod_collected and _skill_level("fishing") >= FISHING_REINFORCED_ROD_UNLOCK_LEVEL


func _fishing_star_rod_offer_available() -> bool:
	return fishing_reinforced_rod_collected and not fishing_star_rod_collected and _skill_level("fishing") >= FISHING_STAR_ROD_UNLOCK_LEVEL


func _fishing_boat_offer_available() -> bool:
	return not fishing_boat_built and _skill_level("fishing") >= FISHING_BOAT_OFFER_UNLOCK_LEVEL


func _fishing_mirror_offer_available() -> bool:
	return not fishing_mirror_collected and _skill_level("fishing") >= FISHING_MIRROR_OFFER_UNLOCK_LEVEL


func _fishing_visible_wallet_tool_defs() -> Array:
	var visible_wallet_tools: Array = []
	var rod_slot_id := fishing_runtime.visible_rod_slot_id()
	for raw_tool in FISHING_TOOL_DEFS:
		var tool := raw_tool as Dictionary
		var tool_id := str(tool.get("id", ""))
		if tool_id in ["line", "reinforced_rod", "star_rod"] and tool_id != rod_slot_id:
			continue
		visible_wallet_tools.append(tool)
	return visible_wallet_tools


func _fishing_tool_icon_texture(tool_id_or_path: String) -> Texture2D:
	match tool_id_or_path:
		"hands":
			return visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/tool-bare-hands.png")
		"bamboo-rod":
			return visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/tool-bamboo-rod.png")
		"line":
			return _fishing_tool_icon_texture("bamboo-rod")
		"reinforced_rod", "star_rod":
			return _fishing_tool_icon_texture("bamboo-rod")
		"net":
			return visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/net-player.png")
		"boat":
			return visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/tool-boat.png")
		"mirror":
			return visual_texture_cache._texture_or_visual_fallback("res://assets/content/fishing/tools/reflection-net.png")
		"tool:hands":
			return _fishing_tool_icon_texture("hands")
		"tool:bamboo-rod":
			return _fishing_tool_icon_texture("bamboo-rod")
		_:
			for raw_tool in FISHING_TOOL_DEFS:
				var tool := raw_tool as Dictionary
				if str(tool.get("art", "")) == tool_id_or_path:
					return _fishing_tool_icon_texture(str(tool.get("id", "")))
			return visual_texture_cache._texture_or_visual_fallback(tool_id_or_path)


func _fishing_location_thumbnail_path(area_id: String, location_id: String) -> String:
	match fishing_runtime.location_key(area_id, location_id):
		"beach.shallows":
			return "res://assets/content/fishing/locations/location-shallows.png"
		"beach.rocky":
			return "res://assets/content/fishing/locations/location-rocky-ledge.png"
		"pier.dock-cup":
			return "res://assets/content/fishing/locations/location-dock-cup.png"
		"pier.piling-line":
			return "res://assets/content/fishing/locations/location-piling-line.png"
		"river.bend":
			return "res://assets/content/fishing/locations/river-bend.png"
		"river.rapids":
			return "res://assets/content/fishing/locations/river-rapids.png"
		"sewers.drain-gate":
			return "res://assets/content/fishing/locations/sewers-drain-gate.png"
		"sewers.tunnel-pool":
			return "res://assets/content/fishing/locations/sewers-tunnel-pool.png"
		"winter_lake.ice-hole":
			return "res://assets/content/fishing/locations/winter-lake-ice-hole.png"
		"reef.pot":
			return "res://assets/content/fishing/locations/reef-pot.png"
		"reef.cage":
			return "res://assets/content/fishing/locations/reef-cage.png"
		"reef.night-reef":
			return "res://assets/content/fishing/locations/reef-night-reef.png"
		"reef.pearl-bed":
			return "res://assets/content/fishing/locations/reef-pearl-bed.png"
		"sea.rowboat":
			return "res://assets/content/fishing/locations/sea-rowboat.png"
		"sea.open-water":
			return "res://assets/content/fishing/locations/sea-open-water.png"
		"sea.chum-line":
			return "res://assets/content/fishing/locations/sea-chum-line.png"
		"stormy_sea.ripple":
			return "res://assets/content/fishing/locations/stormy-sea-ripple.png"
		"stormy_sea.storm-line":
			return "res://assets/content/fishing/locations/stormy-sea-storm-line.png"
		"deep_sea.wreck-drop":
			return "res://assets/content/fishing/locations/deep-sea-wreck-drop.png"
		"deep_sea.abyss":
			return "res://assets/content/fishing/locations/deep-sea-abyss.png"
		"deep_sea.trench":
			return "res://assets/content/fishing/locations/deep-sea-trench.png"
		"space.starlight":
			return "res://assets/content/fishing/locations/space-starlight.png"
		"space.reflection":
			return "res://assets/content/fishing/locations/space-reflection.png"
	return "res://assets/content/fishing/locations/location-shallows.png"


func _fishing_location_thumbnail_texture(area_id: String, location_id: String) -> Texture2D:
	return visual_texture_cache._texture_or_visual_fallback(_fishing_location_thumbnail_path(area_id, location_id))


func _player_facing_action_art_path(skill_id: String, action: Dictionary) -> String:
	if skill_id == "fishing":
		return fishing_runtime.indexed_action_art_path(action, FISHING_TOOL_LOCATION_ACTIONS, Callable(self, "_fishing_location_thumbnail_path"))
	return str(action.get("art", ""))


func _fishing_area_uses_location_tiles(area_def: Dictionary) -> bool:
	return fishing_runtime.area_uses_location_tiles(area_def, FISHING_LOCATION_DEFS)


func _fishing_locations_for_area(area_id: String) -> Array:
	return fishing_runtime.locations_for_area(area_id, FISHING_LOCATION_DEFS)


func _fishing_locations_for_area_module(area_def: Dictionary) -> Array:
	return fishing_runtime.locations_for_area_module(area_def, FISHING_LOCATION_DEFS)


func _fishing_location_action_id(area_id: String, location_id: String) -> String:
	return fishing_runtime.location_action_id(area_id, location_id, FISHING_TOOL_LOCATION_ACTIONS)


func _fishing_location_mastery_action_id(area_id: String, location_id: String) -> String:
	return fishing_runtime.location_mastery_action_id(area_id, location_id, FISHING_TOOL_LOCATION_ACTIONS)


func _fishing_mastery_action_id(action_id: String) -> String:
	return fishing_runtime.mastery_action_id(action_id, FISHING_TOOL_LOCATION_ACTIONS, Callable(self, "_fishing_location_thumbnail_path"))


func _fishing_selected_location_id(area_def: Dictionary) -> String:
	return fishing_runtime.selected_location_id(self, area_def, FISHING_LOCATION_DEFS, FISHING_TOOL_LOCATION_ACTIONS)


func _fishing_location_should_show(area_id: String, location: Dictionary) -> bool:
	return fishing_runtime.location_should_show(self, area_id, location, FISHING_LOCATION_DEFS, FISHING_TOOL_LOCATION_ACTIONS)


func _fishing_location_is_available(_area_id: String, location: Dictionary) -> bool:
	return fishing_runtime.location_is_available(self, _area_id, location)


func _fishing_location_is_unlocked(area_id: String, location: Dictionary) -> bool:
	return fishing_runtime.location_is_unlocked(self, area_id, location, FISHING_LOCATION_DEFS, FISHING_TOOL_LOCATION_ACTIONS)


func _fishing_location_display_action(area_id: String, location: Dictionary) -> Dictionary:
	return fishing_runtime.location_display_action(self, area_id, location, FISHING_LOCATION_DEFS, FISHING_TOOL_LOCATION_ACTIONS)


func _attach_fishing_fish_circle_button(circle: Control) -> void:
	if circle == null:
		return
	var wallet_pressed_callable := Callable(_fishing_ui_surface(), "_on_fishing_tool_wallet_pressed")
	circle.mouse_filter = Control.MOUSE_FILTER_STOP
	if circle is BaseButton:
		var button := circle as BaseButton
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		if not button.pressed.is_connected(wallet_pressed_callable):
			button.pressed.connect(wallet_pressed_callable)
	if circle.has_signal("wallet_pressed") and not circle.is_connected("wallet_pressed", wallet_pressed_callable):
		circle.connect("wallet_pressed", wallet_pressed_callable)


func _on_fishing_tool_selected(tool_id: String) -> void:
	if not fishing_runtime.tool_is_unlocked(tool_id):
		return
	fishing_active_tool_init_token += 1
	if tool_id == equipped_fishing_tool_id:
		_fishing_ui_surface()._set_fishing_tool_wallet_open(false)
		return
	_audio_director()._play_chain_impact_cluster(1, 0.42, "click", 1.0)
	fishing_runtime.set_equipped_tool(tool_id)
	fishing_tool_wallet_open = false
	_fishing_ui_surface()._clear_fishing_tool_circle_menu()
	save_game()
	_render_screen(false, detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1)
	_set_result("%s equipped." % _fishing_tool_label(tool_id))


func _fishing_attempt_success_chance(action_id: String) -> float:
	return fishing_runtime.attempt_success_chance(self, action_id)


func _fishing_flat_xp_reward(action: Dictionary, skill_id: String) -> int:
	return fishing_runtime.flat_xp_reward(self, action, skill_id)


func _append_fishing_action_lazy_entry(plan: Array, y: float, action: Dictionary) -> float:
	var action_id := str(action.get("id", ""))
	if action_id.is_empty():
		return y
	var height := _activity_card_root_height()
	var module_key := ModuleUiRuntime.action_for_record("fishing", action, FISHING_ACTION_ID_ALIASES)
	if _module_ui_is_collapsed(module_key):
		height = _module_collapsed_squeeze_height()
	plan.append({
		"kind": "action",
		"entry": {"kind": "action", "action": action},
		"track_id": action_id,
		"y": y,
		"height": height,
		"mounted": false,
		"stack_host": null,
		"placeholder": null,
		"direct_stack_child": false
	})
	return y + height + DETAIL_LAZY_STACK_SEPARATION


func _fishing_area_module_method_ids(skill_id: String, area_def: Dictionary) -> Array:
	var method_ids: Array = []
	var area_id := str(area_def.get("id", ""))
	if _fishing_area_uses_location_tiles(area_def):
		for raw_location in _fishing_locations_for_area_module(area_def):
			var location := raw_location as Dictionary
			if not _fishing_location_should_show(area_id, location):
				continue
			var action := _fishing_location_display_action(area_id, location)
			var action_id := str(action.get("id", ""))
			if not action_id.is_empty():
				method_ids.append(action_id)
		return method_ids
	for raw_method_id in area_def.get("methods", []):
		var action_id := str(raw_method_id)
		if _fishing_method_should_show(skill_id, action_id):
			method_ids.append(action_id)
	return method_ids


func _discard_fishing_area_module_card_keys(area_key: String, area_card: Dictionary, skill_id: String) -> void:
	_discard_action_card_key(area_key)
	for raw_method_id in area_card.get("method_ids", []) as Array:
		_discard_action_card_key(_action_key(skill_id, str(raw_method_id)))
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		var action_id := str(method_card.get("action_id", ""))
		if not action_id.is_empty():
			_discard_action_card_key(_action_key(skill_id, action_id))
		if bool(method_card.get("is_fishing_location", false)):
			var location_key := "%s:location-%s-%s" % [
				str(method_card.get("skill_id", skill_id)),
				str(method_card.get("area_id", "")),
				str(method_card.get("location_id", ""))
			]
			_discard_action_card_key(location_key)


func _render_fishing_area_modules(stack: VBoxContainer, content_width: float) -> void:
	var skill_id := "fishing"
	_clear_detail_lazy_cache_bin()
	detail_rendered_action_ids = _fishing_ui_surface()._fishing_detail_render_signature()
	detail_lazy_plan = _fishing_ui_surface()._build_fishing_detail_lazy_plan(skill_id)
	detail_lazy_last_scroll = -1.0
	_detail_lazy_create_slots(stack, skill_id, content_width, content_width)
	var initial_force_count := _detail_lazy_initial_force_mount_count_for_skill(skill_id)
	if _fishing_ui_surface()._fishing_ablation_enabled("no_lazy"):
		_skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, detail_lazy_plan.size())
		_sync_detail_actions_scroll_limit()
		_fishing_ui_surface()._restore_fishing_detail_render_culling()
	else:
		_skill_detail_surface()._detail_lazy_mount_initial_window_sync(true, initial_force_count)
		_sync_detail_actions_scroll_limit()
		_fishing_ui_surface()._sync_fishing_detail_render_culling(true)
		_queue_detail_lazy_settle_warm_mount(skill_id)


func _add_fishing_preview_standalone_action(stack: VBoxContainer, skill_id: String, action: Dictionary, content_width: float, state: Dictionary) -> void:
	var action_card := _skill_swipe_activity_surface()._skill_swipe_preview_action_card(skill_id, action, content_width)
	(action_card["card"] as Dictionary)["preview_only"] = true
	var root := action_card["root"] as Control
	_set_preview_controls_mouse_filter(root)
	stack.add_child(root)
	(state["action_cards"] as Array).append(action_card["card"])


func _mark_fishing_preview_module_cards(built: Dictionary) -> void:
	var area_key := str(built.get("area_key", ""))
	if not area_key.is_empty():
		_discard_action_card_key(area_key)
	var area_card := built.get("area_card", {}) as Dictionary
	if area_card.is_empty():
		return
	area_card["preview_only"] = true
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		method_card["preview_only"] = true
		var method_key := _action_key(str(method_card.get("skill_id", "fishing")), str(method_card.get("action_id", "")))
		_discard_action_card_key(method_key)
		if bool(method_card.get("is_fishing_location", false)):
			var location_key := "%s:location-%s-%s" % [
				str(method_card.get("skill_id", "fishing")),
				str(method_card.get("area_id", "")),
				str(method_card.get("location_id", ""))
			]
			_discard_action_card_key(location_key)


func _set_preview_controls_mouse_filter(root: Control) -> void:
	if root == null:
		return
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		var child_control := child as Control
		if child_control != null:
			_set_preview_controls_mouse_filter(child_control)


func _fishing_active_tool_ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _fishing_active_tool_base_x(icon_width: float) -> float:
	return FISHING_ACTIVE_TOOL_LAYER_SIZE.x - FISHING_ACTIVE_TOOL_VISUAL_LANE_WIDTH + (FISHING_ACTIVE_TOOL_VISUAL_LANE_WIDTH - icon_width) * 0.5


func _fishing_tool_uses_initial_drop(tool_id: String) -> bool:
	return tool_id in ["net", "mirror", "boat"] or FishingState.is_rod(tool_id)


func _on_fishing_active_tool_pressed(anchor: Control) -> void:
	if anchor == null or not is_instance_valid(anchor):
		return
	_reward_feedback_surface()._float_reward(self, anchor, _fishing_tool_label(equipped_fishing_tool_id), 54, COLOR_INK, Vector2(0, -24), Vector2(0, -118), 0.0)


func _route_fishing_active_tool_input(event: InputEvent) -> bool:
	if selected_skill_id != "fishing":
		return false
	var event_position := Vector2.ZERO
	var is_press := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		event_position = mouse_event.global_position
		is_press = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		is_press = touch_event.pressed
	else:
		return false
	if not is_press:
		return false
	for raw_card in action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var method_card := raw_card as Dictionary
		if not bool(method_card.get("is_fishing_method", false)):
			continue
		var method_button := method_card.get("method_button") as Control
		if method_button != null and is_instance_valid(method_button) and method_button.visible and method_button.is_visible_in_tree():
			if method_button.get_global_rect().has_point(event_position):
				return false
	for raw_card in action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var area_card := raw_card as Dictionary
		if not bool(area_card.get("is_fishing_area", false)):
			continue
		if not _fishing_ui_surface()._fishing_area_card_owns_action(area_card, running_action_id):
			continue
		var layer := area_card.get("active_tool_layer") as Control
		var art := area_card.get("active_tool_art") as TextureRect
		if layer == null or art == null or not is_instance_valid(layer) or not is_instance_valid(art):
			continue
		if not layer.visible or not layer.is_visible_in_tree():
			continue
		var art_rect := art.get_global_rect().grow(18.0)
		if not art_rect.has_point(event_position):
			continue
		_reward_feedback_surface()._float_reward(self, art, _fishing_tool_label(equipped_fishing_tool_id), 54, COLOR_INK, Vector2(0, -24), Vector2(0, -118), 0.0)
		return true
	return false


func _activate_fishing_offer_button(offer_id: String, source: Button) -> void:
	if source == null or not is_instance_valid(source):
		return
	match offer_id:
		"net":
			var net_art := _valid_control_ref(instance_from_id(int(source.get_meta("fishing_net_art_id", 0))))
			_on_fishing_net_offer_pressed(source, net_art)
		"rod":
			_on_fishing_rod_offer_pressed(source)
		"mirror":
			_on_fishing_mirror_offer_pressed(source)
		"reinforced_rod", "star_rod":
			_on_fishing_rod_upgrade_offer_pressed(offer_id, source)
		"boat":
			_on_fishing_boat_offer_pressed(source)


func _on_fishing_net_offer_pressed(net_button: Control, net_art: Control = null) -> void:
	if fishing_net_collected or fishing_net_collect_pending:
		return
	fishing_net_collect_pending = true
	var collect_animation_started := false
	if net_button != null and is_instance_valid(net_button):
		_reward_feedback_surface()._float_reward(net_button, net_button, "Net found!", 58, COLOR_GOLD, Vector2(0, -40), Vector2(0, -170), 0.0)
		collect_animation_started = _fishing_ui_surface()._collect_fishing_net_offer_to_wallet(net_art if net_art != null and is_instance_valid(net_art) else net_button)
		_fishing_ui_surface()._play_fishing_offer_collected_transition(net_button, FISHING_NET_COLLECT_LAYOUT_DELAY_SECONDS if collect_animation_started else 0.10, collect_animation_started)
	_set_result("Collecting net...")
	if not collect_animation_started:
		_finish_fishing_net_collect()


func _finish_fishing_net_collect() -> void:
	if fishing_net_collected:
		fishing_net_collect_pending = false
		return
	fishing_net_collected = true
	fishing_net_collect_pending = false
	save_game()
	_set_result("Net collected!")
	_refresh_fish_circle_currency_only()
	_rerender_after_fishing_tool_collect()


func _on_fishing_rod_offer_pressed(rod_button: Control) -> void:
	if fishing_rod_collected:
		return
	if fish_currency < FISHING_ROD_OFFER_COST:
		if rod_button != null and is_instance_valid(rod_button):
			_reward_feedback_surface()._float_reward(rod_button, rod_button, "Need %s fish" % GameFormatting.compact_number(float(FISHING_ROD_OFFER_COST), 3), 50, Color("#ffd95a"), Vector2(0, -40), Vector2(0, -150), 0.0)
		_set_result("Need %s fish for the rod." % GameFormatting.compact_number(float(FISHING_ROD_OFFER_COST), 3))
		return
	fish_currency = maxf(0.0, fish_currency - float(FISHING_ROD_OFFER_COST))
	fishing_rod_collected = true
	save_game()
	if rod_button != null and is_instance_valid(rod_button):
		_reward_feedback_surface()._float_reward(rod_button, rod_button, "Rod collected!", 58, COLOR_GOLD, Vector2(0, -40), Vector2(0, -170), 0.0)
		_fishing_ui_surface()._fly_fishing_tool_to_wallet(rod_button, "res://assets/content/fishing/tools/tool-bamboo-rod.png")
		_fishing_ui_surface()._play_fishing_offer_collected_transition(rod_button)
	_set_result("Bamboo rod collected!")
	_refresh_fish_circle_currency_only()
	_rerender_after_fishing_tool_collect()


func _on_fishing_rod_upgrade_offer_pressed(tool_id: String, upgrade_button: Control) -> void:
	var needs_previous := (tool_id == "star_rod" and not fishing_reinforced_rod_collected) or (tool_id == "reinforced_rod" and not fishing_rod_collected)
	if needs_previous:
		return
	if (tool_id == "star_rod" and fishing_star_rod_collected) or (tool_id == "reinforced_rod" and fishing_reinforced_rod_collected):
		return
	var cost := _fishing_ui_surface()._fishing_rod_upgrade_cost(tool_id)
	if fish_currency < cost:
		if upgrade_button != null and is_instance_valid(upgrade_button):
			_reward_feedback_surface()._float_reward(upgrade_button, upgrade_button, "Need %s fish" % GameFormatting.compact_number(float(cost), 3), 50, Color("#ffd95a"), Vector2(0, -40), Vector2(0, -150), 0.0)
		_set_result("Need %s fish for the %s." % [GameFormatting.compact_number(float(cost), 3), _fishing_ui_surface()._fishing_rod_upgrade_title(tool_id)])
		return
	fish_currency = maxf(0.0, fish_currency - float(cost))
	if tool_id == "star_rod":
		fishing_star_rod_collected = true
	else:
		fishing_reinforced_rod_collected = true
	save_game()
	if upgrade_button != null and is_instance_valid(upgrade_button):
		_reward_feedback_surface()._float_reward(upgrade_button, upgrade_button, "%s collected!" % _fishing_ui_surface()._fishing_rod_upgrade_title(tool_id), 58, COLOR_GOLD, Vector2(0, -40), Vector2(0, -170), 0.0)
		_fishing_ui_surface()._fly_fishing_tool_to_wallet(upgrade_button, "res://assets/content/fishing/tools/tool-bamboo-rod.png")
		_fishing_ui_surface()._play_fishing_offer_collected_transition(upgrade_button)
	_set_result("%s collected!" % _fishing_ui_surface()._fishing_rod_upgrade_title(tool_id))
	_refresh_fish_circle_currency_only()
	_rerender_after_fishing_tool_collect()


func _on_fishing_boat_offer_pressed(boat_button: Control) -> void:
	if fishing_boat_built:
		return
	if _skill_level("build") < FISHING_BOAT_BUILD_REQUIRED_LEVEL:
		if boat_button != null and is_instance_valid(boat_button):
			_reward_feedback_surface()._float_reward(boat_button, boat_button, "Building Lv %s required" % FISHING_BOAT_BUILD_REQUIRED_LEVEL, 48, Color("#ffd95a"), Vector2(0, -40), Vector2(0, -150), 0.0)
		_set_result("Building Lv %s required to build the boat." % FISHING_BOAT_BUILD_REQUIRED_LEVEL)
		return
	if material_runtime.amount("softwood") < float(FISHING_BOAT_OFFER_COST):
		if boat_button != null and is_instance_valid(boat_button):
			_reward_feedback_surface()._float_reward(boat_button, boat_button, "Need %s Softwood" % GameFormatting.compact_number(float(FISHING_BOAT_OFFER_COST), 3), 50, Color("#ffd95a"), Vector2(0, -40), Vector2(0, -150), 0.0)
		_set_result("Need %s Softwood for the boat." % GameFormatting.compact_number(float(FISHING_BOAT_OFFER_COST), 3))
		return
	material_runtime.spend_amount("softwood", float(FISHING_BOAT_OFFER_COST))
	fishing_boat_built = true
	save_game()
	if boat_button != null and is_instance_valid(boat_button):
		_reward_feedback_surface()._float_reward(boat_button, boat_button, "Boat built!", 58, COLOR_GOLD, Vector2(0, -40), Vector2(0, -170), 0.0)
		_fishing_ui_surface()._fly_fishing_tool_to_wallet(boat_button, "res://assets/content/fishing/tools/tool-boat.png")
		_fishing_ui_surface()._play_fishing_offer_collected_transition(boat_button)
	_set_result("Boat built!")
	_refresh_fish_circle_currency_only()
	_rerender_after_fishing_tool_collect()


func _on_fishing_mirror_offer_pressed(mirror_button: Control) -> void:
	if fishing_mirror_collected:
		return
	if fish_currency < FISHING_MIRROR_OFFER_COST:
		if mirror_button != null and is_instance_valid(mirror_button):
			_reward_feedback_surface()._float_reward(mirror_button, mirror_button, "Need %s fish" % GameFormatting.compact_number(float(FISHING_MIRROR_OFFER_COST), 3), 50, Color("#ffd95a"), Vector2(0, -40), Vector2(0, -150), 0.0)
		_set_result("Need %s fish for the mirror." % GameFormatting.compact_number(float(FISHING_MIRROR_OFFER_COST), 3))
		return
	fish_currency = maxf(0.0, fish_currency - float(FISHING_MIRROR_OFFER_COST))
	fishing_mirror_collected = true
	save_game()
	if mirror_button != null and is_instance_valid(mirror_button):
		_reward_feedback_surface()._float_reward(mirror_button, mirror_button, "Mirror collected!", 58, COLOR_GOLD, Vector2(0, -40), Vector2(0, -170), 0.0)
		_fishing_ui_surface()._fly_fishing_tool_to_wallet(mirror_button, "res://assets/content/fishing/tools/reflection-net.png")
		_fishing_ui_surface()._play_fishing_offer_collected_transition(mirror_button)
	_set_result("Reflection mirror collected!")
	_refresh_fish_circle_currency_only()
	_rerender_after_fishing_tool_collect()


func _hide_control_bound(control_id: int) -> void:
	var control := _valid_control_ref(instance_from_id(control_id))
	if control != null:
		_set_canvas_item_visible_if_changed(control, false)


func _refresh_fish_circle_currency_only() -> void:
	if detail_fish_circle == null or not is_instance_valid(detail_fish_circle) or not detail_fish_circle.is_inside_tree():
		return
	detail_fish_circle.set_theme_color(_skill_theme_color(selected_skill_id))
	detail_fish_circle.set_fish_count(fish_currency, _fish_currency_display_text(fish_currency), true)


func _rerender_after_fishing_tool_collect() -> void:
	detail_rendered_action_ids = _fishing_ui_surface()._fishing_detail_render_signature()


func _cropped_unlock_padlock_texture() -> Texture2D:
	if unlock_padlock_texture != null:
		return unlock_padlock_texture
	if not visual_texture_cache._can_create_image_textures():
		return null
	var image := _cropped_unlock_padlock_image()
	if image == null:
		return null
	unlock_padlock_texture = visual_texture_cache._create_image_texture(image)
	return unlock_padlock_texture


func _cropped_unlock_padlock_image() -> Image:
	if unlock_padlock_hit_image != null:
		return unlock_padlock_hit_image
	var source := visual_texture_cache._texture(UNLOCK_PADLOCK_TEXTURE)
	if source == null:
		return null
	var image := source.get_image()
	if image == null or image.is_empty():
		return null
	if image.is_compressed():
		var decompress_error := image.decompress()
		if decompress_error != OK:
			return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	var source_size := source.get_size()
	if source_size.x <= 4.0:
		unlock_padlock_hit_image = image
		return unlock_padlock_hit_image
	var crop_width := maxi(1, int(round(source_size.x - 3.0)))
	var crop_height := maxi(1, int(round(source_size.y)))
	unlock_padlock_hit_image = image.get_region(Rect2i(Vector2i.ZERO, Vector2i(crop_width, crop_height)))
	return unlock_padlock_hit_image


func _unlock_padlock_tint_mask_texture() -> Texture2D:
	if unlock_padlock_tint_mask_texture != null:
		return unlock_padlock_tint_mask_texture
	unlock_padlock_tint_mask_texture = visual_texture_cache._texture(UNLOCK_LOCK_TINT_MASK_TEXTURE)
	return unlock_padlock_tint_mask_texture


func _play_padlock_click_shake(shake_body: Control) -> void:
	if shake_body == null or not is_instance_valid(shake_body):
		return
	_audio_director()._play_padlock_cluster_sfx()
	var pivot_size := shake_body.size
	if pivot_size.length_squared() <= 1.0:
		pivot_size = FISHING_METHOD_PADLOCK_SIZE
	shake_body.pivot_offset = pivot_size * 0.5
	var rest_meta_key := "padlock_shake_rest_position"
	if not shake_body.has_meta(rest_meta_key):
		shake_body.set_meta(rest_meta_key, shake_body.position)
	var base_position := _meta_vector2(shake_body, rest_meta_key, shake_body.position)
	var base_rotation := 0.0
	var shake_direction := -1.0 if randf() < 0.5 else 1.0
	var tween_meta_key := "padlock_shake_tween"
	_kill_meta_tween(shake_body, tween_meta_key)
	shake_body.position = base_position
	shake_body.rotation = base_rotation
	var tween := create_tween()
	shake_body.set_meta(tween_meta_key, tween)
	var shake_body_id := shake_body.get_instance_id()
	tween.tween_method(_apply_padlock_click_shake_frame.bind(shake_body_id, base_position, base_rotation, shake_direction), 0.0, 1.0, ACTIVITY_PADLOCK_CLICK_SHAKE_SECONDS).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_padlock_click_shake.bind(shake_body_id, base_position, base_rotation, tween_meta_key))


func _apply_padlock_click_shake_frame(progress: float, shake_body_id: int, base_position: Vector2, base_rotation: float, shake_direction: float) -> void:
	var body := _valid_control_ref(instance_from_id(shake_body_id))
	if body == null:
		return
	var shake_pct := 1.0 - progress
	var shake_wave := sin((1.0 - shake_pct) * PI * 7.0) * shake_pct * shake_direction
	body.position = base_position + Vector2(shake_wave * 10.0, absf(shake_wave) * 3.0)
	body.rotation = base_rotation + shake_wave * 0.085


func _finish_padlock_click_shake(shake_body_id: int, base_position: Vector2, base_rotation: float, tween_meta_key: String) -> void:
	var body := _valid_control_ref(instance_from_id(shake_body_id))
	if body == null:
		return
	body.position = base_position
	body.rotation = base_rotation
	if body.has_meta(tween_meta_key):
		body.remove_meta(tween_meta_key)


func _fishing_padlock_unlock_fall_progress(drop_progress: float) -> float:
	var elapsed := drop_progress * FISHING_PADLOCK_UNLOCK_DROP_SECONDS
	var fall_delay := FISHING_PADLOCK_UNLOCK_POP_SECONDS * 0.72
	var fall_elapsed := maxf(0.0, elapsed - fall_delay)
	return clampf(fall_elapsed / maxf(0.001, FISHING_PADLOCK_UNLOCK_DROP_SECONDS - fall_delay), 0.0, 1.0)


func _fishing_padlock_unlock_pop_scale(pop_progress: float) -> float:
	if pop_progress >= 1.0:
		return 1.0
	var pop := pow(1.0 - pop_progress, 1.35) * 0.14
	var settle := sin(pop_progress * PI) * 0.018
	return 1.0 + pop - settle


func _fishing_padlock_unlock_pop_wiggle(pop_progress: float, direction: float) -> float:
	if pop_progress >= 1.0:
		return 0.0
	var damping := pow(1.0 - pop_progress, 1.55)
	var wave := cos(pop_progress * TAU * 1.65)
	return wave * damping * direction * 0.58


func _apply_fishing_padlock_unlock_drop_frame(shake_body: Control, direction: float, progress: float) -> void:
	if shake_body == null or not is_instance_valid(shake_body) or shake_body.is_queued_for_deletion():
		return
	var padlock_size := FISHING_METHOD_PADLOCK_SIZE
	var drop_progress := clampf(progress, 0.0, 1.0)
	var elapsed := drop_progress * FISHING_PADLOCK_UNLOCK_DROP_SECONDS
	var pop_progress := clampf(elapsed / FISHING_PADLOCK_UNLOCK_POP_SECONDS, 0.0, 1.0)
	var fall_progress := _fishing_padlock_unlock_fall_progress(drop_progress)
	var gravity := fall_progress * fall_progress
	var fallover := smoothstep(0.18, 1.0, fall_progress)
	var settling_wobble := sin(fall_progress * PI * 1.75) * 0.045 * (1.0 - fall_progress)
	var pop_wiggle := _fishing_padlock_unlock_pop_wiggle(pop_progress, direction)
	var lock_offset := Vector2(
		direction * 14.0 * fall_progress + pop_wiggle * 6.0,
		padlock_size.y * 0.46 * gravity - absf(pop_wiggle) * 2.0
	)
	var lock_rotation := (0.78 * direction * fallover) + settling_wobble + pop_wiggle * 0.10
	var pop_scale := _fishing_padlock_unlock_pop_scale(pop_progress)
	shake_body.position = lock_offset
	shake_body.rotation = lock_rotation
	shake_body.scale = Vector2.ONE * pop_scale
	shake_body.pivot_offset = padlock_size * 0.5


func _apply_fishing_padlock_unlock_drop_frame_bound(progress: float, shake_body_id: int, direction: float) -> void:
	var shake_body := _valid_control_ref(instance_from_id(shake_body_id))
	_apply_fishing_padlock_unlock_drop_frame(shake_body, direction, progress)


func _finish_fishing_method_unlock_ceremony(method_card: Dictionary, refresh_detail: bool) -> void:
	if method_card.is_empty() or bool(method_card.get("unlock_ceremony_finalized", false)):
		return
	method_card["unlock_ceremony_finalized"] = true
	var pending_skill_id := str(method_card.get("manual_unlock_pending_skill_id", method_card.get("skill_id", selected_skill_id)))
	var pending_action_id := str(method_card.get("manual_unlock_pending_action_id", method_card.get("action_id", "")))
	_clear_pending_activity_readiness_action(pending_skill_id, pending_action_id)
	if not _activity_unlock_runtime()._finalize_manual_activity_unlock_for_card(method_card, "fishing method unlock"):
		_activity_unlock_runtime()._finalize_manual_activity_unlock(pending_skill_id, pending_action_id, "fishing method unlock")
	var method_button := method_card.get("method_button") as Button
	if method_button != null and is_instance_valid(method_button):
		_activate_fishing_method_button(method_card)
	method_card["unlock_ceremony_active"] = false
	activity_unlock_ceremony_count = maxi(0, activity_unlock_ceremony_count - 1)
	_schedule_auto_unlock_pending_lockpads()
	if refresh_detail and activity_unlock_ceremony_count <= 0:
		activity_unlock_detail_refresh_done = false
		call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")


func _activate_fishing_method_button(method_card: Dictionary, owner_area_pop_instance_id := 0) -> void:
	if method_card.is_empty():
		return
	var method_button := method_card.get("method_button") as Button
	if method_button == null or not is_instance_valid(method_button) or method_button.is_queued_for_deletion():
		return
	_set_base_button_disabled_if_changed(method_button, false)
	method_button.mouse_filter = Control.MOUSE_FILTER_STOP if current_screen == "pinned" else Control.MOUSE_FILTER_IGNORE
	var skill_id := str(method_card.get("skill_id", ""))
	var action_id := str(method_card.get("action_id", ""))
	var area_key := str(method_card.get("fishing_area_key", ""))
	if not bool(method_button.get_meta("fishing_method_pressed_connected", false)):
		method_button.gui_input.connect(_fishing_ui_surface()._on_fishing_method_button_input.bind(skill_id, action_id, area_key, owner_area_pop_instance_id, method_button))
		_button_press_runtime().attach_default_button_sfx(method_button)
		method_button.set_meta("fishing_method_pressed_connected", true)
	var art_panel := method_card.get("art_panel", null) as Control
	if art_panel != null and is_instance_valid(art_panel) and not art_panel.is_queued_for_deletion():
		art_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if not bool(art_panel.get_meta("fishing_method_art_pressed_connected", false)):
			art_panel.gui_input.connect(_fishing_ui_surface()._on_fishing_method_button_input.bind(skill_id, action_id, area_key, owner_area_pop_instance_id, method_button))
			art_panel.set_meta("fishing_method_art_pressed_connected", true)


func _sync_fishing_method_card_unlocked_live(method_card: Dictionary, owner_area_pop_instance_id := 0) -> void:
	if method_card.is_empty():
		return
	method_card["unlock_ready_pending"] = false
	method_card["unlock_ceremony_pending"] = false
	var art := method_card.get("art", null) as CanvasItem
	if art != null and is_instance_valid(art):
		art.modulate = Color.WHITE
	var art_panel := method_card.get("art_panel", null) as Panel
	if art_panel != null and is_instance_valid(art_panel):
		art_panel.add_theme_stylebox_override("panel", _fishing_ui_surface()._fishing_location_tile_style(true))
	var lock_root := method_card.get("lock_root", null) as Control
	if lock_root != null and is_instance_valid(lock_root):
		var padlock_hit_area := lock_root.get_meta("padlock_button") as Control
		if padlock_hit_area != null and is_instance_valid(padlock_hit_area):
			padlock_hit_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_activate_fishing_method_button(method_card, owner_area_pop_instance_id)


func _run_fishing_method_unlock_drop_motion(method_card: Dictionary) -> void:
	await get_tree().create_timer(ACTIVITY_UNLOCK_MOTION_START_DELAY).timeout
	if method_card.is_empty() or bool(method_card.get("unlock_ceremony_finalized", false)):
		return
	if current_screen != "skill":
		_finish_fishing_method_unlock_ceremony(method_card, false)
		return
	var lock_root := method_card.get("lock_root") as Control
	if lock_root == null or not is_instance_valid(lock_root) or lock_root.is_queued_for_deletion():
		_finish_fishing_method_unlock_ceremony(method_card, true)
		return
	var shake_body := lock_root.get_meta("padlock_shake_body") as Control
	if shake_body == null or not is_instance_valid(shake_body) or shake_body.is_queued_for_deletion():
		_finish_fishing_method_unlock_ceremony(method_card, true)
		return
	_kill_meta_tween(shake_body, "padlock_shake_tween")
	_audio_director()._play_padlock_cluster_sfx()
	shake_body.modulate = Color.WHITE
	shake_body.position = Vector2.ZERO
	shake_body.rotation = 0.0
	shake_body.scale = Vector2.ONE
	var direction := -1.0 if randf() < 0.5 else 1.0
	var drop_tween := create_tween()
	var shake_body_id := shake_body.get_instance_id()
	drop_tween.tween_method(
		_apply_fishing_padlock_unlock_drop_frame_bound.bind(shake_body_id, direction),
		0.0,
		1.0,
		FISHING_PADLOCK_UNLOCK_DROP_SECONDS
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var fade_tween := create_tween()
	var fade_delay := FISHING_PADLOCK_UNLOCK_DROP_SECONDS * 0.58
	var fade_seconds := maxf(0.08, FISHING_PADLOCK_UNLOCK_DROP_SECONDS - fade_delay)
	fade_tween.tween_property(shake_body, "modulate:a", 0.0, fade_seconds).set_delay(fade_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tween.finished.connect(_finish_fishing_method_unlock_ceremony_by_action.bind(
		str(method_card.get("skill_id", "fishing")),
		str(method_card.get("action_id", "")),
		true
	))


func _finish_fishing_method_unlock_ceremony_by_action(skill_id: String, action_id: String, refresh_detail: bool) -> void:
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	if not method_card.is_empty():
		_finish_fishing_method_unlock_ceremony(method_card, refresh_detail)
		return
	_clear_pending_activity_readiness_action(skill_id, action_id)
	_activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, action_id, "fishing method unlock")
	activity_unlock_ceremony_count = maxi(0, activity_unlock_ceremony_count - 1)
	_schedule_auto_unlock_pending_lockpads()
	if refresh_detail and activity_unlock_ceremony_count <= 0:
		activity_unlock_detail_refresh_done = false
		call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")


func _play_fishing_method_unlock_ceremony(method_card: Dictionary) -> void:
	if method_card.is_empty() or bool(method_card.get("unlock_ceremony_active", false)):
		return
	method_card["unlock_ceremony_pending"] = false
	method_card["unlock_ready_pending"] = false
	method_card["unlock_ceremony_active"] = true
	method_card["unlock_ceremony_finalized"] = false
	activity_unlock_ceremony_count += 1
	var method_button := method_card.get("method_button") as Button
	if method_button != null and is_instance_valid(method_button):
		var skill_id := str(method_card.get("skill_id", "fishing"))
		var action := _action_data(skill_id, str(method_card.get("action_id", "")))
		if not _is_action_unlocked(skill_id, action):
			_set_base_button_disabled_if_changed(method_button, true)
	var lock_root := method_card.get("lock_root") as Control
	if lock_root != null:
		var padlock_hit_area := lock_root.get_meta("padlock_button") as Control
		if padlock_hit_area != null:
			padlock_hit_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_run_fishing_method_unlock_drop_motion(method_card)


func _apply_fishing_area_selection(area_card: Dictionary, action_id: String, instant := false) -> void:
	var skill_id := str(area_card.get("skill_id", "fishing"))
	var action := _action_data(skill_id, action_id)
	if action.is_empty():
		return
	var warning_text := fishing_runtime.tool_warning_text(action_id)
	var xp_text := "+%s" % GameFormatting.info_chip_number(float(_fishing_flat_xp_reward(action, skill_id)))
	if not warning_text.is_empty():
		xp_text = warning_text.replace(" ", "\n")
	var yield_title := "FISH"
	var yield_text := fishing_runtime.yield_label(self, action, equipped_fishing_tool_id, FISHING_NET_HAUL_THRESHOLD)
	if equipped_fishing_tool_id == "net" and not FishingState.tool_catches_nothing_for_action(equipped_fishing_tool_id, action_id):
		yield_text = "%s/%s" % [mini(fishing_net_stored_fish, FISHING_NET_HAUL_THRESHOLD), FISHING_NET_HAUL_THRESHOLD]
		yield_title = "NET"
	if equipped_fishing_tool_id == "boat" and not FishingState.tool_catches_nothing_for_action(equipped_fishing_tool_id, action_id):
		yield_text = "%s/%s" % [mini(fishing_boat_stored_fish, FISHING_BOAT_HAUL_THRESHOLD), FISHING_BOAT_HAUL_THRESHOLD]
		yield_title = "BOAT"
	var running_here := running_skill_id == skill_id and running_action_id == action_id
	var selection_key := "%s:%s:%s:%s:%s" % [action_id, xp_text, yield_text, yield_title, warning_text]
	var border_key := "%s:%s" % [action_id, running_here]
	if (
		not instant
		and str(area_card.get("selection_sync_key", "")) == selection_key
		and str(area_card.get("selection_border_key", "")) == border_key
	):
		return
	area_card["selection_sync_key"] = selection_key
	area_card["selection_border_key"] = border_key
	area_card["selected_action_id"] = action_id
	var xp_label := area_card.get("area_xp") as Label
	if xp_label != null:
		if warning_text.is_empty():
			_skill_detail_surface()._sync_action_stat_chip_title(xp_label, "XP")
			_sync_action_stat_chip_label_style(xp_label, _action_stat_chip_buffed(skill_id, action, "xp"), _skill_theme_color(skill_id))
		else:
			_sync_action_stat_chip_label_style(xp_label, false, _skill_theme_color(skill_id))
			xp_label.add_theme_color_override("font_color", Color("#b82121"))
			xp_label.add_theme_constant_override("outline_size", 0)
			_skill_detail_surface()._sync_action_stat_chip_title(xp_label, "")
		_set_label_text_if_changed(xp_label, xp_text)
	var yield_label := area_card.get("area_yield") as Label
	if yield_label != null:
		_skill_detail_surface()._sync_action_stat_chip_title(yield_label, yield_title)
		_set_label_text_if_changed(yield_label, yield_text)
	var warning_label := area_card.get("area_warning") as Label
	if warning_label != null:
		_set_label_text_if_changed(warning_label, warning_text)
	var warning_box := area_card.get("area_warning_box") as Control
	if warning_box != null:
		_set_canvas_item_visible_if_changed(warning_box, not warning_text.is_empty())
	var border := area_card.get("border") as ActivityCardBorder
	if border != null:
		border.border_color = Color("#1f6f4a") if running_here else COLOR_INK
		border.queue_redraw()


func _fishing_area_stat_fade_controls(area_card: Dictionary) -> Array:
	var controls: Array = []
	var stat_column := area_card.get("stat_column") as Control
	if stat_column != null and is_instance_valid(stat_column):
		controls.append(stat_column)
	for raw_button in (area_card.get("stat_hit_buttons", {}) as Dictionary).values():
		var button := raw_button as Control
		if button != null and is_instance_valid(button):
			controls.append(button)
	return controls


func _set_fishing_area_stats_visible(area_card: Dictionary, should_show: bool, _delta: float, instant: bool) -> void:
	var target_alpha := 1.0 if should_show else 0.0
	_app_lifecycle_runtime()._kill_card_tween(area_card, "stat_fade_tween")
	var controls := _fishing_area_stat_fade_controls(area_card)
	if controls.is_empty():
		return
	if instant:
		for control in controls:
			_set_canvas_item_alpha_if_changed(control, target_alpha)
		area_card["stats_visible"] = should_show
		return
	var lead := controls[0] as Control
	if absf(lead.modulate.a - target_alpha) < 0.02:
		area_card["stats_visible"] = should_show
		return
	var tween := create_tween()
	area_card["stat_fade_tween"] = tween
	tween.set_parallel(true)
	for control in controls:
		tween.tween_property(control, "modulate:a", target_alpha, FISHING_AREA_STAT_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_fishing_area_stats_visible.bind(str(area_card.get("card_key", "")), should_show))


func _finish_fishing_area_stats_visible(card_key: String, should_show: bool) -> void:
	var area_card := action_cards.get(card_key, {}) as Dictionary
	if area_card.is_empty():
		return
	area_card.erase("stat_fade_tween")
	area_card["stats_visible"] = should_show


func _fishing_area_stat_hit_buttons(pop_card: Control, _skill_id: String, _area_key: String, _method_count: int) -> Dictionary:
	var hit_buttons := {}
	var kinds := ["xp", "yield"]
	var button_size := Vector2(300, 222)
	var right_inset := 54.0
	var stack_top := FISHING_AREA_STAT_STACK_TOP
	var stack_step := button_size.y + 28.0
	for i in range(kinds.size()):
		var kind := str(kinds[i])
		var button := Button.new()
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.anchor_left = 1.0
		button.anchor_right = 1.0
		button.anchor_top = 0.0
		button.anchor_bottom = 0.0
		button.offset_left = -(right_inset + button_size.x)
		button.offset_right = -right_inset
		button.offset_top = stack_top + float(i) * stack_step
		button.offset_bottom = button.offset_top + button_size.y
		button.z_index = 219
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		pop_card.add_child(button)
		button.modulate.a = 0.0
		hit_buttons[kind] = button
	return hit_buttons


func _sync_fishing_area_stat_hit_buttons(area_card: Dictionary, running: bool) -> void:
	var selected_id := str(area_card.get("selected_action_id", ""))
	var enabled := false and running and not selected_id.is_empty()
	for raw_button in (area_card.get("stat_hit_buttons", {}) as Dictionary).values():
		var button := raw_button as Button
		if button == null or not is_instance_valid(button):
			continue
		if bool(button.get_meta("fishing_area_stat_enabled", false)) == enabled:
			continue
		button.set_meta("fishing_area_stat_enabled", enabled)
		_set_base_button_disabled_if_changed(button, not enabled)
		if button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _update_fishing_area_module(area_card: Dictionary, skill_id: String, running: bool, delta: float, instant: bool) -> void:
	if _fishing_ui_surface()._fishing_ablation_enabled("no_fishing_updates"):
		return
	if (
		detail_scroll_visual_work_this_frame
		and not running
		and not bool(area_card.get("stats_running", false))
		and not _fishing_area_has_active_camera_return(area_card)
	):
		return
	if running and not running_action_id.is_empty():
		if _fishing_ui_surface()._fishing_area_card_owns_action(area_card, running_action_id):
			if running_action_id != str(area_card.get("selected_action_id", "")):
				_apply_fishing_area_selection(area_card, running_action_id, instant)
	var stats_running := running
	if bool(area_card.get("stats_running", false)) != stats_running:
		area_card["stats_running"] = stats_running
		if stats_running:
			var show_id := running_action_id
			if show_id.is_empty():
				show_id = str(area_card.get("selected_action_id", ""))
			if not show_id.is_empty():
				_apply_fishing_area_selection(area_card, show_id, instant)
		_set_fishing_area_stats_visible(area_card, stats_running, delta, instant)
	_sync_fishing_area_stat_hit_buttons(area_card, stats_running)
	if detail_scroll_visual_work_this_frame and not running and not _fishing_area_has_active_camera_return(area_card):
		return
	_fishing_ui_surface()._update_fishing_active_tool_animation(area_card, running, delta, instant)
	_update_action_card_run_feedback(area_card, skill_id, running, delta, instant)
	_update_fishing_area_method_slots(area_card, skill_id, delta, instant)


func _update_fishing_area_method_slots(area_card: Dictionary, skill_id: String, delta: float, instant: bool) -> void:
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		var action_id := str(method_card.get("action_id", ""))
		if action_id.is_empty():
			continue
		var method_action := _action_data(skill_id, action_id)
		var method_unlocked := _is_action_unlocked(skill_id, method_action)
		var method_running := running_skill_id == skill_id and running_action_id == action_id
		if bool(method_card.get("is_fishing_location", false)):
			method_running = (
				method_running
				and str(selected_fishing_locations.get(str(method_card.get("area_id", "")), "")) == str(method_card.get("location_id", ""))
			)
		if float(method_card.get("active_camera_zoom", 0.0)) > 1.0 and bool(method_card.get("active_camera_was_running", false)) and not method_running:
			method_card["active_camera_returning"] = true
		if detail_scroll_visual_work_this_frame and not method_running and not bool(method_card.get("active_camera_returning", false)):
			continue
		_update_fishing_method_slot(method_card, skill_id, action_id, method_action, method_unlocked, method_running, delta, instant)


func _fishing_area_has_active_camera_return(area_card: Dictionary) -> bool:
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var method_card := raw_method_card as Dictionary
		if method_card.is_empty():
			continue
		if bool(method_card.get("active_camera_returning", false)):
			return true
		if float(method_card.get("active_camera_zoom", 0.0)) > 1.0 and bool(method_card.get("active_camera_was_running", false)):
			return true
	return false


func _update_fishing_method_slot(
	card: Dictionary,
	skill_id: String,
	action_id: String,
	_action: Dictionary,
	_unlocked: bool,
	running: bool,
	delta: float,
	instant: bool
) -> void:
	var status := card.get("status") as Label
	if status != null:
		_set_label_text_if_changed(status, "")
	var medal := card.get("medal") as TextureRect
	var mastery_action_id := str(card.get("mastery_action_id", action_id))
	var mastery_level := MasteryState.level(mastery, _action_key(skill_id, mastery_action_id))
	_set_action_card_medal(card, medal, mastery_level, instant)
	_update_action_card_mastery_bar(card, skill_id, mastery_action_id, delta, instant)
	var art_panel := card.get("art_panel") as CanvasItem
	if art_panel != null:
		_set_canvas_item_modulate_if_changed(art_panel, Color.WHITE)
	var active_art := card.get("art") as Control
	_update_fishing_method_active_art(card, active_art, running, delta, instant)
	_update_fishing_method_attempt_bar(card, action_id, running, instant)
	var area_key := str(card.get("fishing_area_key", ""))
	var area_card_variant = action_cards.get(area_key, null)
	if typeof(area_card_variant) == TYPE_DICTIONARY:
		var area_card := area_card_variant as Dictionary
		if str(area_card.get("selected_action_id", "")) == action_id:
			_apply_fishing_area_selection(area_card, action_id, instant)


func _update_fishing_method_active_art(
	card: Dictionary,
	art: Control,
	running: bool,
	delta: float,
	instant: bool
) -> void:
	if art == null or not is_instance_valid(art):
		return
	var rest_position := card.get("active_rest_position", ActionArtUi.ACTION_ART_OFFSET) as Vector2
	var camera_zoom := float(card.get("active_camera_zoom", 0.0))
	if camera_zoom > 1.0:
		_fishing_ui_surface()._update_fishing_location_active_camera(card, art, running, delta, instant, rest_position, camera_zoom)
		return
	var sway_offset := card.get("active_sway_offset", FISHING_METHOD_ACTIVE_SWAY_OFFSET) as Vector2
	var sway_rotation := float(card.get("active_sway_rotation", FISHING_METHOD_ACTIVE_SWAY_ROTATION))
	var sway_scale_pulse := float(card.get("active_sway_scale_pulse", FISHING_METHOD_ACTIVE_SWAY_SCALE_PULSE))
	if running:
		var phase := float(card.get("method_active_sway_phase", 0.0)) + delta * FISHING_METHOD_ACTIVE_SWAY_SPEED * 1.20
		card["method_active_sway_phase"] = phase
		var bob := sin(phase)
		var sway := sin(phase * 0.85 + 0.55)
		var tilt := sin(phase * 0.95 - 0.35) * sway_rotation
		var pulse := 1.0 + sin(phase * 3.05) * sway_scale_pulse
		art.position = rest_position + Vector2(
			sway * sway_offset.x,
			bob * sway_offset.y
		)
		art.rotation = tilt
		art.scale = Vector2(pulse, pulse)
		return
	if instant:
		art.position = rest_position
		art.rotation = 0.0
		art.scale = Vector2.ONE
		return
	var return_step := clampf(delta / maxf(0.001, FISHING_METHOD_ACTIVE_SWAY_RETURN_SECONDS), 0.0, 1.0)
	art.position = art.position.lerp(rest_position, return_step)
	art.rotation = lerpf(art.rotation, 0.0, return_step)
	art.scale = art.scale.lerp(Vector2.ONE, return_step)
	if (
		art.position.distance_squared_to(rest_position) <= 0.25
		and absf(art.rotation) <= 0.001
		and art.scale.distance_squared_to(Vector2.ONE) <= 0.0001
	):
		art.position = rest_position
		art.rotation = 0.0
		art.scale = Vector2.ONE

func _play_fishing_location_tile_wiggle(method_card: Dictionary) -> void:
	if bool(method_card.get("is_fishing_location", false)) or bool(method_card.get("fixed_layout", false)):
		return
	var target := method_card.get("wiggle_root") as Control
	if target == null or not is_instance_valid(target):
		target = method_card.get("art_panel") as Control
	if target == null or not is_instance_valid(target):
		return
	target.pivot_offset = target.size * 0.5
	_kill_meta_tween(target, "fishing_tile_wiggle_tween")
	target.rotation = 0.0
	target.scale = Vector2.ONE
	var direction := -1.0 if randf() < 0.5 else 1.0
	var tween := create_tween()
	target.set_meta("fishing_tile_wiggle_tween", tween)
	tween.tween_property(target, "rotation", 0.035 * direction, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "scale", Vector2(1.025, 1.025), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "rotation", -0.024 * direction, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "rotation", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_fishing_location_tile_wiggle.bind(target.get_instance_id()))


func _finish_fishing_location_tile_wiggle(target_id: int) -> void:
	var target := _valid_control_ref(instance_from_id(target_id))
	if target != null:
		target.rotation = 0.0
		target.scale = Vector2.ONE
		if target.has_meta("fishing_tile_wiggle_tween"):
			target.remove_meta("fishing_tile_wiggle_tween")


func _update_fishing_method_attempt_bar(
	card: Dictionary,
	action_id: String,
	running: bool,
	instant: bool
) -> void:
	var attempt_bar := card.get("attempt_bar") as Control
	if attempt_bar == null or not is_instance_valid(attempt_bar):
		return
	if not attempt_bar.has_method("set_archetype") or not attempt_bar.has_method("set_attempt"):
		return
	var archetype := str(_fishing_tool_def("hands").get("archetype", FishingState.method_archetype(self, action_id)))
	if str(attempt_bar.get("archetype")) != archetype:
		attempt_bar.call("set_archetype", archetype)
	var reveal_kind := ""
	if not running:
		reveal_kind = str(card.get("attempt_reveal_kind", ""))
		if instant:
			card["attempt_reveal_kind"] = ""
	var progress := action_progress if running else 0.0
	attempt_bar.call("set_attempt", progress, running, reveal_kind)
	_set_canvas_item_alpha_if_changed(attempt_bar, 1.0 if running or not reveal_kind.is_empty() else 0.42)


func _on_fishing_method_pressed(skill_id: String, action_id: String, _area_key: String, owner_area_pop_instance_id := 0) -> void:
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	if bool(method_card.get("is_fishing_location", false)):
		var area_id := str(method_card.get("area_id", ""))
		var location_id := str(method_card.get("location_id", ""))
		if not area_id.is_empty() and not location_id.is_empty():
			selected_fishing_locations[area_id] = location_id
	var owner_area_card := _fishing_ui_surface()._fishing_area_card_for_pop_instance_id(owner_area_pop_instance_id)
	if owner_area_card.is_empty():
		_select_fishing_method(skill_id, action_id)
	else:
		_apply_fishing_area_selection(owner_area_card, action_id, false)
	if bool(method_card.get("is_fishing_location", false)):
		save_game()
		_play_fishing_location_tile_wiggle(method_card)
	_start_action_from_card_tap(skill_id, action_id)


func _on_fishing_method_lock_pressed(skill_id: String, action_id: String, preferred_shake_body: Control = null) -> void:
	var action := _action_data(skill_id, action_id)
	if action.is_empty() or _is_action_unlocked(skill_id, action):
		return
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	var shake_body := _fishing_method_padlock_shake_body(skill_id, action_id, preferred_shake_body)
	_onboarding_runtime()._mark_lock_click_tip_seen()
	if not _activity_unlock_runtime()._can_unlock_action(skill_id, action):
		if shake_body != null and is_instance_valid(shake_body):
			_play_padlock_click_shake(shake_body)
		_set_result("%s needs %s." % [str(action.get("name", "Method")), _skill_detail_surface()._missing_action_requirements_text(skill_id, action)])
		return
	activity_unlock_detail_refresh_done = false
	var preview_after_unlock := _onboarding_runtime()._tutorial_preview_after_manual_unlock(skill_id, action_id)
	if _fishing_rework_active_for_skill(skill_id) and not preview_after_unlock.is_empty():
		_clear_activity_unlock_preview_reveal_guards()
	_set_activity_unlock_preview_after_ceremony(preview_after_unlock)
	var preview_id := activity_unlock_preview_after_ceremony_id
	if not preview_id.is_empty():
		_prestage_activity_unlock_preview_card(preview_id)
	if _skill_detail_surface()._lock_click_tip_remaining_collapse_seconds() > 0.0:
		_skill_detail_surface()._stage_next_locked_activity_preview_after_tip_collapse(preview_id)
	var ceremony_started := false
	if method_card != null and method_card.get("lock_root") != null:
		_activity_unlock_runtime()._queue_manual_activity_unlock_for_ceremony(method_card, skill_id, action_id)
		_persist_fishing_method_unlock_click(skill_id, action_id)
		var owner_area_card := _fishing_ui_surface()._fishing_area_card_for_action(skill_id, action_id)
		var owner_pop := owner_area_card.get("pop", null) as Control
		var owner_area_pop_instance_id := owner_pop.get_instance_id() if owner_pop != null and is_instance_valid(owner_pop) else 0
		_sync_fishing_method_card_unlocked_live(method_card, owner_area_pop_instance_id)
		_play_fishing_method_unlock_ceremony(method_card)
		ceremony_started = true
	else:
		_persist_fishing_method_unlock_click(skill_id, action_id)
		call_deferred("_refresh_skill_detail_after_activity_unlock_ceremony")
	_set_result("%s unlocked." % str(action.get("name", "Method")))
	if not ceremony_started:
		_mark_save_dirty("fishing method unlock")


func _persist_fishing_method_unlock_click(skill_id: String, action_id: String) -> bool:
	_clear_pending_activity_readiness_action(skill_id, action_id)
	return _activity_unlock_runtime()._finalize_manual_activity_unlock(skill_id, action_id, "fishing method unlock")


func _on_fishing_method_lock_hit_input(event: InputEvent, skill_id: String, action_id: String, shake_body: Control = null) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	_on_fishing_method_lock_pressed(skill_id, action_id, shake_body)
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _fishing_method_padlock_shake_body(skill_id: String, action_id: String, preferred_shake_body: Control = null) -> Control:
	var preferred := _valid_control_ref(preferred_shake_body)
	if preferred != null and preferred.is_inside_tree():
		return preferred
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	var lock_root := _valid_control_ref(method_card.get("lock_root", null)) if not method_card.is_empty() else null
	var shake_body := _fishing_method_padlock_shake_body_from_root(lock_root)
	if shake_body != null:
		return shake_body
	for raw_card in action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if not bool(card.get("is_fishing_method", false)):
			continue
		if str(card.get("skill_id", "")) != skill_id or str(card.get("action_id", "")) != action_id:
			continue
		shake_body = _fishing_method_padlock_shake_body_from_root(_valid_control_ref(card.get("lock_root")))
		if shake_body != null:
			return shake_body
	return null


func _fishing_method_padlock_shake_body_from_root(lock_root: Control) -> Control:
	if lock_root == null or not is_instance_valid(lock_root) or not lock_root.is_inside_tree():
		return null
	if not lock_root.visible or not lock_root.is_visible_in_tree():
		return null
	return _valid_control_ref(lock_root.get_meta("padlock_shake_body"))


func _fishing_method_card_for_action(skill_id: String, action_id: String) -> Dictionary:
	var direct = action_cards.get(_action_key(skill_id, action_id))
	if typeof(direct) == TYPE_DICTIONARY:
		return direct as Dictionary
	for raw_key in action_cards.keys():
		var raw_card = action_cards.get(raw_key)
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if not card.get("is_fishing_method"):
			continue
		if str(card.get("skill_id", "")) == skill_id and str(card.get("action_id", "")) == action_id:
			return card
	for raw_card in action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var area_card := raw_card as Dictionary
		if not bool(area_card.get("is_fishing_area", false)):
			continue
		if str(area_card.get("skill_id", "")) != skill_id:
			continue
		for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
			if typeof(raw_method_card) != TYPE_DICTIONARY:
				continue
			var method_card := raw_method_card as Dictionary
			if not bool(method_card.get("is_fishing_method", false)):
				continue
			if str(method_card.get("skill_id", "")) == skill_id and str(method_card.get("action_id", "")) == action_id:
				return method_card
	return {}


func _select_fishing_method(skill_id: String, action_id: String) -> void:
	var area_card := _fishing_ui_surface()._fishing_area_card_for_action(skill_id, action_id)
	if area_card.is_empty():
		return
	_apply_fishing_area_selection(area_card, action_id, false)


func _fishing_rework_active_for_skill(skill_id: String) -> bool:
	return FISHING_REWORK_ENABLED and skill_id == "fishing"


func _skill_detail_shows_tutorial_tips(skill_id: String = selected_skill_id) -> bool:
	return not _fishing_rework_active_for_skill(skill_id)


func _dismiss_skill_detail_tutorial_tips() -> void:
	_complete_passive_module_tip_page_visit()
	_complete_silver_opportunity_tip_page_visit()
	_tutorial_overlay_surface()._fade_tip_group("lock_click_tip_notes")
	_dismiss_activity_start_highlight(true)
	_onboarding_runtime()._cancel_onboarding_header_sequence()
	_tutorial_overlay_surface()._fade_tip_group("stamina_cost_tip_notes")
	if stamina_gauge_tip_root != null and is_instance_valid(stamina_gauge_tip_root):
		_tutorial_overlay_surface()._fade_tip_control(stamina_gauge_tip_root)
		stamina_gauge_tip_root = null


func _fishing_fluid_kind_for_action(action: Dictionary) -> String:
	var action_id := str(action.get("id", ""))
	if str(action.get("area", "")) == "space" or action_id.begins_with("space-"):
		return "space"
	if str(action.get("area", "")) == "winter_lake":
		return "ice"
	if str(action.get("area", "")) == "deep_sea":
		return "deep_water"
	if str(action.get("area", "")) == "stormy_sea":
		return "storm"
	if action_id in ["sewers-drain-gate", "sewers-tunnel-pool"]:
		return "sewer"
	if action_id.contains("chum") or action_id.contains("leviathan") or action_id.contains("lobster"):
		return "lava"
	return "water"


func _attach_fishing_fluid_strip(parent: Control, action: Dictionary) -> Control:
	if _fishing_ui_surface()._fishing_ablation_enabled("no_fluid"):
		var spacer := Control.new()
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spacer.z_index = 1
		parent.add_child(spacer)
		return spacer
	var fluid: Control = FishingFluidStripClass.new()
	fluid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fluid.z_index = 1
	fluid.set_fluid_kind(_fishing_fluid_kind_for_action(action))
	parent.add_child(fluid)
	return fluid


func _sync_action_art_animation_state(card: Dictionary, running: bool) -> void:
	var art := _valid_control_ref(card.get("art"))
	if art == null or not is_instance_valid(art) or not art.has_method("set_playing"):
		return
	art.call("set_playing", running)


func _sync_action_art_animations_for_running_state(force := false) -> void:
	var running_key := _action_key(running_skill_id, running_action_id) if not running_skill_id.is_empty() and not running_action_id.is_empty() else ""
	var event_key := _action_key(event_running_skill_id, event_running_action_id) if not event_running_skill_id.is_empty() and not event_running_action_id.is_empty() else ""
	var active_key := "%s|%s" % [running_key, event_key]
	if not force and active_key == action_art_last_running_key:
		return
	action_art_last_running_key = active_key
	for raw_key in action_card_keys:
		var key := str(raw_key)
		if not action_cards.has(key):
			continue
		var card := action_cards[key] as Dictionary
		if card.is_empty():
			continue
		var skill_id := str(card.get("skill_id", ""))
		var action_id := str(card.get("action_id", ""))
		var running_here := (
			(not running_key.is_empty() and skill_id == running_skill_id and action_id == running_action_id)
			or (not event_key.is_empty() and skill_id == event_running_skill_id and action_id == event_running_action_id)
		)
		_sync_action_art_animation_state(card, running_here)


func _update_action_card_run_feedback(card: Dictionary, skill_id: String, running: bool, delta: float, instant: bool, progress_override := -1.0) -> void:
	_sync_action_art_animation_state(card, running)
	var card_progress := clampf(progress_override if progress_override >= 0.0 else action_progress, 0.0, 1.0)
	var art := _valid_control_ref(card.get("art"))
	if art != null and is_instance_valid(art) and art.has_method("set_action_progress"):
		art.call("set_action_progress", card_progress)
	if _fishing_rework_active_for_skill(skill_id) and card.get("is_fishing_method"):
		return
	if _fishing_rework_active_for_skill(skill_id):
		var fluid_strip := card.get("fluid_strip") as Control
		if fluid_strip != null:
			if fluid_strip.has_method("set_running"):
				fluid_strip.call("set_running", running)
			if running and fluid_strip.has_method("set_attempt_progress"):
				fluid_strip.call("set_attempt_progress", card_progress)
			if card.get("is_fishing_area"):
				var water_strip_host := card.get("water_strip_host") as Control
				if water_strip_host != null:
					var strip_visible := running
					if fluid_strip != null and fluid_strip.has_method("is_animating_visible"):
						strip_visible = strip_visible or bool(fluid_strip.call("is_animating_visible"))
					_set_canvas_item_visible_if_changed(water_strip_host, strip_visible)
					card["fluid_exiting"] = (not running) and strip_visible
					card["fluid_was_running"] = running
			return
	var action_id_for_card := str(card.get("action_id", ""))
	var action_for_card := _action_data(skill_id, action_id_for_card)
	if _convergence_runtime()._is_convergence_action(action_for_card):
		var convergence_progress := card.get("convergence_progress") as ConvergenceMultiProgressBar
		if convergence_progress != null:
			var values := _convergence_runtime()._convergence_segment_progress(action_for_card, card_progress if running else 0.0)
			var colors := []
			for raw_skill_id in _convergence_runtime()._convergence_skill_order(action_for_card):
				colors.append(_skill_theme_color(str(raw_skill_id)))
			_set_canvas_item_visible_if_changed(convergence_progress, _convergence_runtime()._convergence_is_built(action_id_for_card))
			convergence_progress.set_bar_pattern(_convergence_runtime()._convergence_bar_pattern(action_for_card))
			convergence_progress.set_segments(values, colors)
		return
	var progress_rail := card.get("progress") as ActivityProgressRail
	if progress_rail != null:
		_set_canvas_item_visible_if_changed(progress_rail, true)
		_sync_action_card_progress_rail_theme(card, progress_rail, skill_id, action_for_card)
		var action_id := str(card.get("action_id", ""))
		var opportunity_windows: Array[Vector2] = []
		var opportunity_active := false
		var opportunity_visible := false
		if running and not action_id.is_empty():
			opportunity_windows = _action_runtime()._action_opportunity_pattern_windows(skill_id, action_id)
			opportunity_active = _action_runtime()._action_opportunity_active(skill_id, action_id)
			opportunity_visible = true
		progress_rail.set_opportunity_windows(opportunity_windows, opportunity_active, opportunity_visible, action_opportunity_missed)
		var canceled_progress := 0.0 if running else _action_runtime()._canceled_action_progress(skill_id, action_id)
		var progress_target := (card_progress if running else canceled_progress) * 100.0
		var progress_instant := instant
		if not running and canceled_progress > 0.0:
			progress_instant = true
		if running and progress_target + 6.0 < progress_rail.value:
			progress_instant = true
		_set_bar(progress_rail, progress_target, delta, progress_instant)
	_material_collection_surface()._sync_mat_collection_card(card, running, instant)


func _update_detail_lazy_entry_height_for_card(card: Dictionary, height: float) -> void:
	var action_id := str(card.get("action_id", ""))
	if action_id.is_empty():
		return
	var lazy_entry := _detail_lazy_entry_for_track_id(action_id)
	if not lazy_entry.is_empty():
		lazy_entry["height"] = maxf(1.0, height)


func _clear_fishing_catch_burst(catch_burst: Control) -> void:
	if catch_burst == null or not is_instance_valid(catch_burst):
		return
	for child in catch_burst.get_children():
		if child != null and is_instance_valid(child):
			child.queue_free()


func _complete_fishing_action_attempt(action: Dictionary, active_key: String, bonus_snapshot_before: Dictionary) -> void:
	fishing_runtime.complete_action_attempt(self, action, active_key, bonus_snapshot_before)


func _play_fishing_catch_burst_for_action(skill_id: String, action_id: String, fish_count: int) -> void:
	var burst_area_card := _fishing_ui_surface()._fishing_area_card_for_action(skill_id, action_id)
	if burst_area_card.is_empty():
		return
	_fishing_ui_surface()._play_fishing_catch_burst(burst_area_card, action_id, fish_count)


func _play_fishing_attempt_reveal(skill_id: String, action_id: String, success: bool) -> void:
	if not _fishing_rework_active_for_skill(skill_id):
		return
	var area_id := fishing_runtime.area_id_for_action(self, action_id)
	var area_card := _fishing_ui_surface()._fishing_area_card_for_action(skill_id, action_id) if not area_id.is_empty() else {}
	if not area_card.is_empty():
		var fluid_strip := area_card.get("fluid_strip") as Control
		if fluid_strip != null and fluid_strip.has_method("play_reveal"):
			fluid_strip.call("play_reveal", success)
	var method_card := _fishing_method_card_for_action(skill_id, action_id)
	if not method_card.is_empty():
		method_card["attempt_reveal_kind"] = "success" if success else "fail"
		_update_fishing_method_attempt_bar(method_card, action_id, false, true)


func _validate_state(priority_skill_ids: Array = []) -> void:
	var validate_all := priority_skill_ids.is_empty()
	_invalidate_stat_caches()
	equipped_fishing_tool_id = "hands"
	for def in skill_defs:
		var skill_id := str(def["id"])
		if not skills.has(skill_id):
			skills[skill_id] = {"xp": 0, "level": 1}
		if not stamina.has(skill_id):
			stamina[skill_id] = float(_max_stamina(skill_id))
		if not stamina_bank.has(skill_id):
			stamina_bank[skill_id] = 0.0
		if validate_all or priority_skill_ids.has(skill_id):
			_validate_skill_actions(skill_id, true)
		else:
			_validate_skill_actions(skill_id, false)
		_recalculate_level(skill_id)
	if not skills.has(selected_skill_id):
		selected_skill_id = "fight"
	_passive_modules_runtime().sync_passive_module_unlocks(_unix_now())
	_ensure_all_thieving_trophy_state()
	_hub_surface()._validate_hub_module_positions()
	_hub_runtime().sync_missions()
	_invalidate_stat_caches()


func _validate_state_bootstrap() -> void:
	for def in skill_defs:
		var skill_id := str(def["id"])
		if not skills.has(skill_id):
			skills[skill_id] = {"xp": 0, "level": 1}
		if not stamina.has(skill_id):
			stamina[skill_id] = float(_max_stamina(skill_id))
		if not stamina_bank.has(skill_id):
			stamina_bank[skill_id] = 0.0
	if not skills.has(selected_skill_id):
		selected_skill_id = "fight"


func _prepare_selected_skill_for_render(boot_fast := false) -> void:
	_validate_state_bootstrap()
	if not skills.has(selected_skill_id):
		selected_skill_id = "fight"
	if _onboarding_runtime()._onboarding_path_active() and not _onboarding_runtime()._onboarding_skill_accessible(selected_skill_id):
		selected_skill_id = TUTORIAL_STARTER_SKILL_ID
	if boot_fast:
		var prepared_action_ids := {}
		for entry in _visible_detail_entries_for_skill(selected_skill_id):
			var entry_data := entry as Dictionary
			if str(entry_data.get("kind", "")) == "thieving_heist":
				continue
			var action := entry_data.get("action", {}) as Dictionary
			if action.is_empty():
				continue
			var action_id := str(action.get("id", ""))
			if action_id.is_empty() or prepared_action_ids.has(action_id):
				continue
			prepared_action_ids[action_id] = true
			var key := _action_key(selected_skill_id, action_id)
			if not mastery.has(key):
				mastery[key] = {"xp": 0, "level": 0}
			_recalculate_mastery(key)
		_ensure_skill_mastery_keys(selected_skill_id)
		_recalculate_level(selected_skill_id, false)
		return
	for action in actions_by_skill.get(selected_skill_id, []):
		var action_data := action as Dictionary
		if _convergence_runtime()._is_convergence_action(action_data):
			_convergence_runtime()._ensure_convergence_state(str(action_data.get("id", "")))
			continue
		if _is_passive_action(action_data):
			_passive_modules_runtime().ensure_passive_module_state(str(action_data.get("id", "")), _unix_now())
			continue
		var key := _action_key(selected_skill_id, str(action_data.get("id", "")))
		if not mastery.has(key):
			mastery[key] = {"xp": 0, "level": 0}
		_recalculate_mastery(key)
	_recalculate_level(selected_skill_id, false)


func _begin_background_boot_validation() -> void:
	if not is_inside_tree():
		return
	if deferred_selected_skill_mastery_pending:
		deferred_selected_skill_mastery_pending = false
		_prepare_selected_skill_for_render(false)
	if not deferred_skill_validation_pending:
		return
	if not pending_save_restore_data.is_empty():
		_save_runtime()._load_game_secondary_restore()
	await get_tree().process_frame
	_validate_remaining_skills_deferred()


func _ensure_skill_mastery_keys(skill_id: String) -> void:
	for action in actions_by_skill.get(skill_id, []):
		if _convergence_runtime()._is_convergence_action(action as Dictionary) or _is_passive_action(action as Dictionary):
			continue
		var key := _action_key(skill_id, str(action["id"]))
		if not mastery.has(key):
			mastery[key] = {"xp": 0, "level": 0}


func _validate_skill_actions(skill_id: String, recalculate_mastery: bool) -> void:
	for action in actions_by_skill.get(skill_id, []):
		if _convergence_runtime()._is_convergence_action(action as Dictionary):
			_convergence_runtime()._ensure_convergence_state(str(action.get("id", "")))
			continue
		if _is_passive_action(action as Dictionary):
			_passive_modules_runtime().ensure_passive_module_state(str(action.get("id", "")), _unix_now())
			continue
		var key := _action_key(skill_id, str(action["id"]))
		if not mastery.has(key):
			mastery[key] = {"xp": 0, "level": 0}
		if recalculate_mastery:
			_recalculate_mastery(key)


func _validate_remaining_skills_deferred() -> void:
	if not deferred_skill_validation_pending or not is_inside_tree():
		return
	for def in skill_defs:
		if not deferred_skill_validation_pending or not is_inside_tree():
			return
		var skill_id := str(def.get("id", ""))
		if skill_id.is_empty() or skill_id == selected_skill_id:
			continue
		_validate_skill_actions(skill_id, true)
		_recalculate_level(skill_id)
		await get_tree().process_frame
	deferred_skill_validation_pending = false
	_invalidate_stat_caches()
	if current_screen == "skill" or current_screen == "home":
		_update_ui(0.0)


func _sync_manual_activity_unlocks_from_levels() -> void:
	_sync_manual_activity_unlocks_from_levels_matching(false)


func _sync_legacy_manual_activity_unlocks_from_levels() -> void:
	_sync_manual_activity_unlocks_from_levels_matching(true)


func _sync_manual_activity_unlocks_from_levels_matching(legacy_single_skill_only: bool) -> void:
	for raw_skill_id in skills.keys():
		var skill_id := str(raw_skill_id)
		for raw_action in actions_by_skill.get(skill_id, []):
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty() or int(action.get("unlock", 1)) <= 1:
				continue
			if _is_passive_action(action):
				continue
			if legacy_single_skill_only and not _action_uses_legacy_single_skill_requirement(skill_id, action):
				continue
			if _activity_unlock_runtime()._can_unlock_action(skill_id, action):
				_activity_unlock_runtime()._mark_action_manually_unlocked(skill_id, action_id)


func _action_uses_legacy_single_skill_requirement(skill_id: String, action: Dictionary) -> bool:
	var requirements := _activity_unlock_runtime()._action_unlock_requirements(skill_id, action)
	if requirements.size() != 1:
		return false
	var requirement := requirements[0] as Dictionary
	return (
		str(requirement.get("skill", skill_id)) == skill_id
		and int(requirement.get("level", action.get("unlock", 1))) == int(action.get("unlock", 1))
	)


func _select_launch_skill_page() -> void:
	if _onboarding_runtime()._onboarding_path_active():
		selected_skill_id = TUTORIAL_STARTER_SKILL_ID
		current_screen = "skill"
		return
	if not running_skill_id.is_empty() and skills.has(running_skill_id) and not _action_data(running_skill_id, running_action_id).is_empty():
		selected_skill_id = running_skill_id
		current_screen = "skill"
		return
	var best_skill_id := selected_skill_id
	var best_level := -1
	var best_xp := -1
	for def in skill_defs:
		var skill_id := str(def["id"])
		var skill_level := _skill_level(skill_id)
		var skill_xp := int(skills.get(skill_id, {}).get("xp", 0))
		if best_skill_id.is_empty() or skill_level > best_level or (skill_level == best_level and skill_xp > best_xp):
			best_skill_id = skill_id
			best_level = skill_level
			best_xp = skill_xp
	if skills.has(best_skill_id):
		selected_skill_id = best_skill_id
	current_screen = "skill"


func _mark_save_dirty(reason := "") -> void:
	_save_runtime()._mark_save_dirty(reason)

func save_game() -> void:
	_save_runtime().save_game()

func _unix_now() -> int:
	return int(floor(Time.get_unix_time_from_system()))


func _unix_now_msec() -> int:
	return int(round(Time.get_unix_time_from_system() * 1000.0))


func _set_offline_result_text(offline_seconds: float, active_result: Dictionary) -> void:
	if not bool(active_result.get("handled", false)):
		return
	var completions := int(active_result.get("completions", 0))
	var action_name := str(active_result.get("action_name", "activity"))
	if completions <= 0:
		last_result = "Away %s: %s waited for stamina." % [GameFormatting.duration(offline_seconds), action_name]
		return
	var parts := [
		"Away %s: %s x%s" % [GameFormatting.duration(offline_seconds), action_name, completions]
	]
	var xp_total := int(active_result.get("xp", 0))
	if xp_total > 0:
		parts.append("+%s XP" % xp_total)
	var mastery_total := float(active_result.get("mastery", 0.0))
	if mastery_total > 0.0:
		parts.append("+%s mastery" % GameFormatting.significant_digits(mastery_total))
	var fish_total := float(active_result.get("fish", 0.0))
	if fish_total > 0.0:
		parts.append("+%s food" % _fish_currency_display_text(fish_total))
	var logs_spent := int(active_result.get("logs_spent", 0))
	if logs_spent > 0:
		parts.append("%s Softwood spent" % logs_spent)
	if bool(active_result.get("convergence", false)):
		parts.append("all-skill shrine XP")
	else:
		parts.append("offline XP and mastery at %s%%" % int(round(OFFLINE_XP_MULT * 100.0)))
	last_result = ", ".join(parts) + "."


func load_game() -> void:
	_save_runtime().load_game()


func _distribute_xp_reward_map_to_total(template: Dictionary, owner_skill_id: String, target_total: int) -> Dictionary:
	var template_total := _reward_map_total(template)
	if template_total <= 0:
		var empty_template_rewards := {}
		if not owner_skill_id.is_empty():
			empty_template_rewards[owner_skill_id] = maxi(1, target_total)
		return empty_template_rewards
	var rewards := {}
	var ordered_skill_ids := _ordered_xp_reward_skill_ids(owner_skill_id, template)
	var assigned := 0
	for raw_skill_id in ordered_skill_ids:
		var reward_skill_id := str(raw_skill_id)
		var template_amount := maxi(0, int(template.get(reward_skill_id, 0)))
		if reward_skill_id.is_empty() or template_amount <= 0:
			continue
		var amount := maxi(1, int(floor(float(maxi(1, target_total)) * float(template_amount) / float(template_total))))
		rewards[reward_skill_id] = amount
		assigned += amount
	if rewards.is_empty():
		var missing_split_rewards := {}
		if not owner_skill_id.is_empty():
			missing_split_rewards[owner_skill_id] = maxi(1, target_total)
		return missing_split_rewards
	var remainder := maxi(1, target_total) - assigned
	var remainder_skill := owner_skill_id if rewards.has(owner_skill_id) else str(ordered_skill_ids[0])
	rewards[remainder_skill] = maxi(1, int(rewards.get(remainder_skill, 0)) + remainder)
	return rewards


func _restore_fishing_state_from_save(data: Dictionary) -> void:
	fish_currency = maxf(0.0, float(data.get("fish_currency", fish_currency)))
	fish_currency_ever_earned = bool(data.get("fish_currency_ever_earned", fish_currency_ever_earned or fish_currency > 0.0))
	_restore_auto_eat_fish_enabled_from_save(data)
	fishing_runtime.restore_from_save(
		data,
		FISHING_NET_HAUL_THRESHOLD,
		FISHING_BOAT_HAUL_THRESHOLD,
		Callable(fishing_runtime, "tool_is_unlocked"),
		Callable(fishing_runtime, "area_metadata_loaded"),
		Callable(fishing_runtime, "location_id_valid").bind(FISHING_LOCATION_DEFS)
	)

func _skill_level(skill_id: String) -> int:
	return int(skills.get(skill_id, {}).get("level", 1))


func _skill_name(skill_id: String) -> String:
	for def in skill_defs:
		if str(def["id"]) == skill_id:
			return str(def["name"])
	return skill_id.capitalize()


func _skill_short_code(skill_id: String) -> String:
	if SKILL_SHORT_CODES.has(skill_id):
		return str(SKILL_SHORT_CODES[skill_id])
	var skill_display_name := _skill_name(skill_id).strip_edges()
	if skill_display_name.is_empty():
		return "XP"
	return skill_display_name.substr(0, mini(3, skill_display_name.length())).to_upper()


func _skill_detail_title_font_size(skill_id: String) -> int:
	if skill_id == "woodcutting":
		return SKILL_DETAIL_WOODCUTTING_TITLE_FONT_SIZE
	return SKILL_DETAIL_TITLE_FONT_SIZE


func _skill_theme_color(skill_id: String) -> Color:
	return SKILL_THEME_COLORS.get(skill_id, COLOR_BLUE)


func _skill_paper_button_color(skill_id: String) -> Color:
	var base := _skill_theme_color(skill_id)
	if dark_mode_enabled:
		return base.darkened(SKILL_MENU_DARK_THEME_DARKEN).lerp(COLOR_DARK_PANEL, SKILL_MENU_DARK_PANEL_MIX)
	return base.lerp(Color.WHITE, SKILL_MENU_LIGHT_PASTEL_MIX)


func _global_level() -> int:
	var total := 0
	for skill_id in skills.keys():
		total += _skill_level(str(skill_id))
	return total


func _max_stamina(skill_id: String = "") -> int:
	if not max_stamina_cache_valid:
		cached_max_stamina = BASE_MAX_STAMINA + int(floor(float(_global_level()) / 10.0)) + int(round(AchievementState.global_reward_bonus(self, "max_stamina")))
		cached_max_stamina_by_skill.clear()
		max_stamina_cache_valid = true
	if skill_id.is_empty():
		return cached_max_stamina
	if cached_max_stamina_by_skill.has(skill_id):
		return int(cached_max_stamina_by_skill[skill_id])
	var skill_max := cached_max_stamina + AchievementState.skill_medal_max_stamina_bonus(self, skill_id)
	cached_max_stamina_by_skill[skill_id] = skill_max
	return skill_max


func _invalidate_stat_caches() -> void:
	_action_runtime().invalidate_stat_cache()
	max_stamina_cache_valid = false
	cached_max_stamina_by_skill.clear()
	activity_medal_buff_total_cache.clear()
	reward_bonus_cache.clear()


func _stamina_value(skill_id: String) -> float:
	return SkillState.stamina_value(stamina, skill_id, Callable(self, "_max_stamina"))


func _stamina(skill_id: String) -> int:
	return SkillState.stamina_int(stamina, skill_id, Callable(self, "_max_stamina"))


func _stamina_regen_fraction(skill_id: String) -> float:
	return SkillState.stamina_regen_fraction(stamina, stamina_bank, skill_id, Callable(self, "_max_stamina"))


func _honey_can_consume_for_stamina() -> bool:
	return material_runtime.amount("honey") >= 1.0


func _player_has_stamina_honey() -> bool:
	return honey_stamina_seconds_remaining > 0.0001 or _honey_can_consume_for_stamina()


func _stamina_regen_needs_honey(excluded_skill_id := "") -> bool:
	for raw_def in skill_defs:
		var skill_id := str((raw_def as Dictionary).get("id", ""))
		if skill_id.is_empty() or skill_id == excluded_skill_id:
			continue
		if _stamina_value(skill_id) < float(_max_stamina(skill_id)) - 0.0001:
			return true
	return false


func _honey_adjusted_stamina_regen_seconds(seconds: float, excluded_skill_id := "") -> float:
	if seconds <= 0.0 or not _stamina_regen_needs_honey(excluded_skill_id):
		return seconds
	var remaining_seconds := seconds
	var boosted_seconds := 0.0
	while remaining_seconds > 0.0001:
		if honey_stamina_seconds_remaining <= 0.0001:
			if not _honey_can_consume_for_stamina() or not material_runtime.spend_amount("honey", 1.0):
				break
			honey_stamina_seconds_remaining = HONEY_STAMINA_SECONDS_PER_CONSUMPTION
		var consumed_seconds := minf(remaining_seconds, honey_stamina_seconds_remaining)
		honey_stamina_seconds_remaining = maxf(0.0, honey_stamina_seconds_remaining - consumed_seconds)
		boosted_seconds += consumed_seconds
		remaining_seconds -= consumed_seconds
	return boosted_seconds * HONEY_STAMINA_REGEN_MULT + remaining_seconds


func _spend_action_stamina(skill_id: String, stamina_cost: float) -> bool:
	if skill_id.is_empty() or stamina_cost <= 0.0:
		return true
	if _stamina_value(skill_id) + 0.0001 < stamina_cost:
		return false
	stamina[skill_id] = maxf(0.0, _stamina_value(skill_id) - stamina_cost)
	_sync_stamina_bank(skill_id)
	return true


func _restore_action_stamina(skill_id: String, amount: float) -> float:
	if skill_id.is_empty() or amount <= 0.0 or not stamina.has(skill_id):
		return 0.0
	var before := _stamina_value(skill_id)
	var restored := minf(float(_max_stamina(skill_id)), before + amount)
	stamina[skill_id] = restored
	_sync_stamina_bank(skill_id)
	return maxf(0.0, restored - before)


func _honey_stamina_regen_multiplier() -> float:
	return HONEY_STAMINA_REGEN_MULT if _player_has_stamina_honey() else 1.0


func _stamina_regen_circle_color(skill_id: String) -> Color:
	return material_runtime.color("honey") if _player_has_stamina_honey() else _skill_theme_color(skill_id)


func _sync_stamina_bank(skill_id: String) -> void:
	SkillState.sync_stamina_bank(stamina, stamina_bank, skill_id, Callable(self, "_max_stamina"))


func _skill_level_xp_text(skill_id: String) -> String:
	var level := _skill_level(skill_id)
	var xp := SkillState.xp_progress(skills, skill_id, level)
	if level >= 99:
		return "Lv %s (XP %s)" % [
			level,
			GameFormatting.compact_number(float(xp["current"]))
		]
	return "Lv %s (XP %s / %s)" % [
		level,
		GameFormatting.compact_number(float(xp["current"])),
		GameFormatting.compact_number(float(xp["needed"]))
	]


func _recalculate_level(skill_id: String, apply_unlocks := true) -> void:
	var xp_total := int(skills[skill_id]["xp"])
	var old_level := int(skills[skill_id].get("level", 1))
	var level := SkillState.skill_level_for_xp(xp_total)
	skills[skill_id]["level"] = level
	if level > old_level and apply_unlocks:
		_invalidate_stat_caches()
		var ready_by_skill := _ready_actions_for_level_gain(skill_id, old_level, level)
		_queue_activity_unlock_readiness(skill_id, old_level, level, ready_by_skill)
		if startup_initialized:
			_navigation_shell()._refresh_hero_nav_unlock_state()
			if skill_id == "build" and old_level < HUB_UNLOCK_BUILD_LEVEL and level >= HUB_UNLOCK_BUILD_LEVEL:
				_navigation_shell()._sync_hub_nav_button(false)
			_reward_feedback_surface()._show_visible_skill_level_up_float(skill_id)
			_audio_director()._play_level_up_sfx()
func _mastery_xp_reward(_action: Dictionary) -> float:
	return 1.0


func _mastery_reward_for_action(skill_id: String, action_id: String, action: Dictionary) -> float:
	if not _action_has_mastery(action):
		return 0.0
	if not _onboarding_runtime()._onboarding_mastery_rewards_allowed(skill_id):
		return 0.0
	if MasteryState.is_maxed(mastery, _action_key(skill_id, action_id), MASTERY_MAX_LEVEL):
		return 0.0
	return _mastery_xp_reward(action)


func _add_mastery_xp(skill_id: String, action_id: String, amount: float) -> void:
	if amount <= 0.0 or MasteryState.is_maxed(mastery, _action_key(skill_id, action_id), MASTERY_MAX_LEVEL):
		return
	if not _onboarding_runtime()._onboarding_mastery_rewards_allowed(skill_id):
		return
	var key := _action_key(skill_id, action_id)
	var result := MasteryState.add_xp(mastery, key, amount, MASTERY_MAX_LEVEL)
	if bool(result.get("level_changed", false)):
		_invalidate_stat_caches()
		_navigation_shell()._refresh_shop_nav_unlock_state()


func _recalculate_mastery(key: String) -> void:
	var result := MasteryState.recalculate_entry(mastery, key, MASTERY_MAX_LEVEL)
	if bool(result.get("level_changed", false)):
		_invalidate_stat_caches()
		_navigation_shell()._refresh_shop_nav_unlock_state()


func _effective_stamina(skill_id: String, action: Dictionary) -> float:
	return _action_runtime()._effective_stamina(skill_id, action)


func _active_action_stamina_cost() -> float:
	return _action_runtime()._active_action_stamina_cost()


func _effective_seconds(skill_id: String, action: Dictionary) -> float:
	return _action_runtime()._effective_seconds(skill_id, action)


func _apply_medal_time_reduction_to_seconds(skill_id: String, action: Dictionary, seconds: float) -> float:
	return _action_runtime()._apply_medal_time_reduction_to_seconds(skill_id, action, seconds)


func _fishing_net_soak_active(skill_id: String) -> bool:
	return _action_runtime()._fishing_net_soak_active(skill_id)


func _fishing_boat_soak_active(skill_id: String) -> bool:
	return _action_runtime()._fishing_boat_soak_active(skill_id)


func _fishing_batch_soak_active(skill_id: String) -> bool:
	return _action_runtime()._fishing_batch_soak_active(skill_id)


func _fishing_net_tick_seconds(action: Dictionary) -> float:
	return _action_runtime()._fishing_net_tick_seconds(action)


func _fishing_boat_tick_seconds(action: Dictionary) -> float:
	return _action_runtime()._fishing_boat_tick_seconds(action)


func _action_cycle_seconds(skill_id: String, action: Dictionary) -> float:
	return _action_runtime()._action_cycle_seconds(skill_id, action)


func _apply_mission_time_reduction(skill_id: String, action: Dictionary, seconds: float) -> float:
	return _action_runtime()._apply_mission_time_reduction(skill_id, action, seconds)


func _action_progress_speed_multiplier(skill_id: String, action: Dictionary, has_stamina_for_action: bool) -> float:
	return _action_runtime()._action_progress_speed_multiplier(skill_id, action, has_stamina_for_action)


func _smoothed_action_progress_speed_multiplier(action_key: String, target: float, delta: float) -> float:
	return _action_runtime()._smoothed_action_progress_speed_multiplier(action_key, target, delta)


func _record_successful_activity_completion(action_key: String) -> int:
	if activity_streak_action_key == action_key:
		activity_streak_count += 1
	else:
		activity_streak_action_key = action_key
		activity_streak_count = 1
	return ((activity_streak_count - 1) % ACTIVITY_STREAK_BONUS_STEP) + 1


func _reset_activity_completion_streak() -> void:
	activity_streak_action_key = ""
	activity_streak_count = 0


func _is_passive_action(action: Dictionary) -> bool:
	return _passive_modules_runtime().is_passive_action(action)


func _award_firepit_burn_xp(scrapwood_burned: int, animate := true) -> void:
	if scrapwood_burned <= 0 or not skills.has("woodcutting"):
		return
	var xp_reward := scrapwood_burned * PassiveModulesRuntime.FIREPIT_WOODCUTTING_XP_PER_SCRAPWOOD
	if xp_reward <= 0:
		return
	skills["woodcutting"]["xp"] = int(skills["woodcutting"].get("xp", 0)) + xp_reward
	_recalculate_level("woodcutting")
	_mark_save_dirty("firepit xp")
	if animate and (startup_initialized or action_cards.has(_action_key("woodcutting", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID))):
		_passive_firepit_surface()._hold_firepit_next_scrapwood_ring_empty()
		_passive_firepit_surface()._animate_firepit_scrapwood_to_fire(scrapwood_burned)

func _toggle_plank_boost() -> void:
	plank_boost_enabled = not plank_boost_enabled
	save_game()
	_update_ui(0.0, false)


func _plank_bonus_applies(skill_id: String) -> bool:
	return skill_id == "build" and plank_boost_enabled and material_runtime.amount("softwood") >= 1.0


func _action_stat_value_cache_key(kind: String, skill_id: String, action: Dictionary) -> String:
	return _action_runtime()._action_stat_value_cache_key(kind, skill_id, action)


func _effective_xp(action: Dictionary, skill_id := "", force_plank_bonus := false) -> int:
	var cache_key := _action_stat_value_cache_key("xp:%s" % force_plank_bonus, skill_id, action)
	if action_stat_value_cache.has(cache_key):
		return int(action_stat_value_cache[cache_key])
	var value := _effective_xp_reward_amount(action, skill_id, skill_id, maxi(1, int(action.get("xp", 1))), force_plank_bonus)
	action_stat_value_cache[cache_key] = value
	return value


func _effective_xp_reward_map(action: Dictionary, owner_skill_id := "", force_plank_bonus := false) -> Dictionary:
	var rewards := {}
	var base_rewards := _base_xp_reward_map(action, owner_skill_id)
	for raw_skill_id in base_rewards.keys():
		var reward_skill_id := str(raw_skill_id)
		var base_amount := maxi(0, int(base_rewards.get(raw_skill_id, 0)))
		if reward_skill_id.is_empty() or base_amount <= 0:
			continue
		rewards[reward_skill_id] = _effective_xp_reward_amount(action, owner_skill_id, reward_skill_id, base_amount, force_plank_bonus)
	if rewards.is_empty():
		rewards[owner_skill_id] = _effective_xp(action, owner_skill_id, force_plank_bonus)
	return _cap_xp_reward_map_total(action, owner_skill_id, rewards)


func _xp_reward_cap_for_action(action: Dictionary) -> int:
	var cap := int(action.get("xp_reward_cap", 0))
	if cap > 0:
		return cap
	var event_meta = action.get("event", {})
	if typeof(event_meta) == TYPE_DICTIONARY:
		return maxi(0, int((event_meta as Dictionary).get("xp_reward_cap", 0)))
	return 0


func _cap_xp_reward_map_total(action: Dictionary, owner_skill_id: String, reward_map: Dictionary) -> Dictionary:
	var cap := _xp_reward_cap_for_action(action)
	if cap <= 0:
		return reward_map
	var total := _reward_map_total(reward_map)
	if total <= cap:
		return reward_map
	return _distribute_xp_reward_map_to_total(reward_map, owner_skill_id, cap)


func _completion_xp_reward_map(action: Dictionary, owner_skill_id: String, force_plank_bonus: bool, xp_crit: bool, mega_crit: bool, streak_bonus: bool) -> Dictionary:
	var rewards := _effective_xp_reward_map(action, owner_skill_id, force_plank_bonus)
	var multiplier := _completion_xp_multiplier(xp_crit, mega_crit, streak_bonus)
	if multiplier <= 1:
		return rewards
	for raw_skill_id in rewards.keys():
		var skill_id := str(raw_skill_id)
		rewards[skill_id] = maxi(1, int(rewards.get(raw_skill_id, 0)) * multiplier)
	return rewards


func _fishing_completion_xp_reward_map(action: Dictionary, owner_skill_id: String) -> Dictionary:
	var rewards := _effective_xp_reward_map(action, owner_skill_id, false)
	rewards[owner_skill_id] = _fishing_flat_xp_reward(action, owner_skill_id)
	return rewards


func _apply_xp_reward_map(owner_skill_id: String, reward_map: Dictionary) -> Array:
	var affected_skill_ids := []
	for reward_skill_id in _ordered_xp_reward_skill_ids(owner_skill_id, reward_map):
		var amount := maxi(0, int(reward_map.get(reward_skill_id, 0)))
		if amount <= 0 or not skills.has(reward_skill_id):
			continue
		skills[reward_skill_id]["xp"] = int(skills[reward_skill_id].get("xp", 0)) + amount
		if not affected_skill_ids.has(reward_skill_id):
			affected_skill_ids.append(reward_skill_id)
	return affected_skill_ids


func _skill_levels_for_reward_map(owner_skill_id: String, reward_map: Dictionary) -> Dictionary:
	var levels := {}
	for reward_skill_id in _ordered_xp_reward_skill_ids(owner_skill_id, reward_map):
		if skills.has(reward_skill_id):
			levels[reward_skill_id] = _skill_level(reward_skill_id)
	return levels


func _reward_map_total(reward_map: Dictionary) -> int:
	var total := 0
	for amount in reward_map.values():
		total += maxi(0, int(amount))
	return total


func _any_reward_skill_leveled_up(affected_skill_ids: Array, old_levels: Dictionary) -> bool:
	for raw_skill_id in affected_skill_ids:
		var skill_id := str(raw_skill_id)
		if not skills.has(skill_id):
			continue
		if _skill_level(skill_id) > int(old_levels.get(skill_id, _skill_level(skill_id))):
			return true
	return false


func _completion_xp_multiplier(xp_crit: bool, mega_crit: bool, streak_bonus: bool) -> int:
	if mega_crit:
		return 9
	if xp_crit:
		return ACTIVITY_CRIT_XP_MULT
	if streak_bonus:
		return 2
	return 1


func _base_xp_reward_map(action: Dictionary, owner_skill_id := "") -> Dictionary:
	var rewards := {}
	var raw_rewards = action.get("xp_rewards", {})
	if typeof(raw_rewards) == TYPE_DICTIONARY:
		for raw_skill_id in (raw_rewards as Dictionary).keys():
			var reward_skill_id := str(raw_skill_id).strip_edges()
			var amount := maxi(0, int((raw_rewards as Dictionary).get(raw_skill_id, 0)))
			if amount > 0:
				amount = _temporary_event_runtime()._temporary_event_scaled_reward_amount(action, amount)
			if not reward_skill_id.is_empty() and amount > 0:
				rewards[reward_skill_id] = amount
	if rewards.is_empty():
		rewards[owner_skill_id] = _temporary_event_runtime()._temporary_event_scaled_reward_amount(action, maxi(1, int(action.get("xp", 1))))
	return rewards


func _effective_xp_reward_amount(action: Dictionary, owner_skill_id: String, reward_skill_id: String, base_amount: int, force_plank_bonus := false) -> int:
	var xp_bonus := AchievementState.global_reward_bonus(self, "xp_mult", reward_skill_id) + _ad_bonus_runtime().xp_multiplier()
	if reward_skill_id == owner_skill_id and (force_plank_bonus or _plank_bonus_applies(owner_skill_id)):
		xp_bonus += PLANK_BUILD_XP_MULT
	if reward_skill_id == owner_skill_id and _hub_runtime().mission_bonus_applies(owner_skill_id, action):
		xp_bonus += _hub_runtime().mission_xp_bonus()
	return maxi(1, int(round(float(maxi(1, base_amount)) * (1.0 + xp_bonus))))


func _is_action_unlocked(skill_id: String, action: Dictionary) -> bool:
	return _activity_unlock_runtime()._is_action_unlocked(skill_id, action)


func _is_event_action(action: Dictionary) -> bool:
	if str(action.get("kind", "")) == "event_activity":
		return true
	var active_event = action.get("active_event", {})
	return typeof(active_event) == TYPE_DICTIONARY and not (active_event as Dictionary).is_empty()


func _action_has_mastery(action: Dictionary) -> bool:
	if action.is_empty():
		return false
	return not _is_event_action(action) and not _is_passive_action(action) and not _convergence_runtime()._is_convergence_action(action)


func _restore_tip_metadata_from_save(data: Dictionary) -> void:
	var tip_metadata := DetailTipState.restored_metadata(data, DETAIL_PULL_TIP_TEXTS, Callable(_save_runtime(), "_action_key_for_save"))
	lock_click_tip_seen = bool(tip_metadata.get("lock_click_tip_seen", false))
	passive_module_tip_seen = bool(tip_metadata.get("passive_module_tip_seen", false))
	silver_opportunity_tip_seen = bool(tip_metadata.get("silver_opportunity_tip_seen", false))
	silver_opportunity_tip_action_key = str(tip_metadata.get("silver_opportunity_tip_action_key", ""))
	detail_pull_recent_tip_texts = tip_metadata.get("detail_pull_recent_tip_texts", []) as Array


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


func _canonical_action_key(key: String) -> String:
	var separator := key.find(":")
	if separator < 0:
		return ""
	var skill_id := key.substr(0, separator)
	var action_id := key.substr(separator + 1)
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	var action := _action_data(skill_id, action_id)
	if action.is_empty() or _is_passive_action(action):
		return ""
	return _action_key(skill_id, str(action.get("id", action_id)))


func _success_chance(skill_id: String, action: Dictionary) -> float:
	return _action_runtime()._success_chance(skill_id, action)


func _roll_action_success(skill_id: String, action: Dictionary) -> bool:
	return _action_runtime()._roll_action_success(skill_id, action)


func _consume_guaranteed_success_action_completion(skill_id: String, action: Dictionary) -> bool:
	return _action_runtime()._consume_guaranteed_success_action_completion(skill_id, action)


func _load_font() -> void:
	if ResourceLoader.exists("res://assets/fonts/Fredoka.ttf"):
		var loaded_font := load("res://assets/fonts/Fredoka.ttf") as Font
		if loaded_font == null:
			app_font = null
			app_bold_font = null
			return
		app_font = loaded_font
		var bold := FontVariation.new()
		bold.base_font = app_font
		bold.variation_embolden = 0.9
		app_bold_font = bold


func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	return ThemeStyles.label(text, font_size, color, align, app_font, app_bold_font, dark_mode_enabled, COLOR_INK, COLOR_DARK_INK, COLOR_MUTED, COLOR_DARK_MUTED, COLOR_LINE, COLOR_DARK_LINE)


func _theme_paper_color() -> Color:
	return ThemeStyles.paper_color(dark_mode_enabled, COLOR_PAPER, COLOR_DARK_PAPER)


func _apply_info_symbol_button_text_color(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	var glyph_color := ThemeStyles.text_color(COLOR_INK, dark_mode_enabled, COLOR_INK, COLOR_DARK_INK, COLOR_MUTED, COLOR_DARK_MUTED, COLOR_LINE, COLOR_DARK_LINE)
	button.add_theme_color_override("font_color", glyph_color)
	button.add_theme_color_override("font_hover_color", glyph_color)
	button.add_theme_color_override("font_pressed_color", glyph_color)
	button.add_theme_color_override("font_disabled_color", glyph_color)


func _sync_info_symbol_button_text_colors() -> void:
	if not is_inside_tree():
		return
	for raw_button in get_tree().get_nodes_in_group("skill_header_info_buttons"):
		_apply_info_symbol_button_text_color(raw_button as Button)


func _theme_surface_color(color: Color) -> Color:
	return ThemeStyles.surface_color(color, dark_mode_enabled, COLOR_PAPER, COLOR_DARK_PAPER, COLOR_PANEL, COLOR_DARK_PANEL, COLOR_LINE, COLOR_DARK_LINE, COLOR_DARK_PANEL_ALT)


func _theme_outline_color(outline_color: Color, fill_color: Color) -> Color:
	return ThemeStyles.outline_color(outline_color, fill_color, dark_mode_enabled, COLOR_INK, COLOR_DARK_LINE, COLOR_PAPER, COLOR_DARK_PAPER, COLOR_PANEL, COLOR_DARK_PANEL, COLOR_LINE, COLOR_DARK_PANEL_ALT)


func _action_card_background_texture(action: Dictionary) -> Texture2D:
	var bg_path := str(action.get("bg", ""))
	if bg_path.is_empty():
		bg_path = str(action.get("background", ""))
	return visual_texture_cache._texture_or_visual_fallback(bg_path)


func _action_card_background(skill_id: String, action: Dictionary) -> Control:
	var background_texture := _action_card_background_texture(action)
	if DisplayServer.get_name() == "headless" and OS.get_environment("IDLE_ELITE_HEADLESS_SIMPLE_ACTION_BG") == "1":
		var fallback_bg := ColorRect.new()
		fallback_bg.color = _skill_theme_color(skill_id).darkened(0.08)
		fallback_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback_bg.z_index = 150
		return fallback_bg
	if ACTION_CARD_SIMPLE_BACKGROUND_ENABLED and not _convergence_runtime()._is_convergence_action(action):
		var image := TextureRect.new()
		image.texture = background_texture
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.z_index = 150
		image.modulate = Color.WHITE
		return image
	var bg := RoundedTextureRect.new()
	bg.texture = background_texture
	bg.modulate = Color.WHITE
	bg.radius = ACTION_CARD_FACE_RADIUS
	bg.mask_inset = 0.0
	bg.corner_mask_mode = 1
	bg.crop_left = FISHING_BACKGROUND_CROP_LEFT if skill_id == "fishing" else 0.0
	bg.crop_top = FISHING_BACKGROUND_CROP_TOP if skill_id == "fishing" else 0.0
	bg.crop_right = FISHING_BACKGROUND_CROP_RIGHT if skill_id == "fishing" else 0.0
	bg.art_height = ACTION_CARD_HEIGHT
	bg.fallback_color = _themed_activity_card_fill_color(_skill_theme_color(skill_id))
	if _convergence_runtime()._is_convergence_action(action):
		bg.aspect_mode = 2
		bg.fallback_color = Color("#8baa54")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	return bg


func _activity_card_root_height(expanded := false) -> float:
	var face_height := ACTION_CARD_EXPANDED_HEIGHT if expanded else ACTION_CARD_HEIGHT
	return float(face_height) + ACTION_CARD_3D_DEPTH_OFFSET.y


func _activity_card_root_height_for_action(action: Dictionary, expanded := false) -> float:
	if _fighting_runtime().action_uses_diamond_combat_arena(action):
		return float(COMBAT_DIAMOND_ARENA_CARD_HEIGHT) + ACTION_CARD_3D_DEPTH_OFFSET.y
	return _activity_card_root_height(expanded)


func _action_mat_collection_layout_height(skill_id: String, action: Dictionary) -> float:
	var action_id := str(action.get("id", ""))
	if action_id.is_empty() or not _action_runtime()._action_has_mat_rewards(action):
		return 0.0
	return MAT_COLLECTION_AREA_HEIGHT if running_skill_id == skill_id and running_action_id == action_id else 0.0


func _activity_card_preview_root_height(card: Dictionary) -> float:
	if bool(card.get("passive", false)):
		return _passive_firepit_surface()._passive_action_card_height(card.get("action", {}) as Dictionary)
	return _activity_card_root_height()


func _activity_card_pop_base_bottom_offset(pop: Control) -> float:
	if pop == null or not is_instance_valid(pop):
		return 0.0
	var bottom_inset := 0.0
	if pop.has_meta("activity_card_depth_bottom_inset"):
		bottom_inset = float(pop.get_meta("activity_card_depth_bottom_inset"))
	return -bottom_inset


func _set_activity_card_depth_face_offset_from_pop(pop: Control, offset: Vector2) -> void:
	if pop == null or not is_instance_valid(pop) or not pop.has_meta("activity_card_depth_node_id"):
		return
	var depth_id := int(pop.get_meta("activity_card_depth_node_id"))
	var depth := instance_from_id(depth_id)
	if depth == null or not is_instance_valid(depth):
		return
	if depth is ActivityCardDepth:
		(depth as ActivityCardDepth).set_face_offset(offset)
	elif depth is PageSwitchButtonFace:
		(depth as PageSwitchButtonFace).set_face_offset(offset)
	if pop.has_meta("activity_card_connector_node_id"):
		var connector_id := int(pop.get_meta("activity_card_connector_node_id"))
		var connector := instance_from_id(connector_id) as PrismConnectorOverlay
		if connector != null and is_instance_valid(connector):
			connector.set_face_offset(offset)
	if pop.has_meta("activity_card_fill_node_id"):
		var fill_id := int(pop.get_meta("activity_card_fill_node_id"))
		var fill := instance_from_id(fill_id) as PrismConnectorOverlay
		if fill != null and is_instance_valid(fill):
			fill.set_face_offset(offset)
	if pop.has_meta("activity_card_outline_node_id"):
		var outline_id := int(pop.get_meta("activity_card_outline_node_id"))
		var outline := _valid_control_ref(instance_from_id(outline_id))
		if outline != null:
			var gutter := float(pop.get_meta("activity_button_gutter", ACTION_CARD_POP_GUTTER))
			var bottom_inset := float(pop.get_meta("activity_button_depth_bottom_inset", ACTION_CARD_3D_DEPTH_OFFSET.y))
			outline.offset_left = gutter + offset.x
			outline.offset_right = -gutter + offset.x
			outline.offset_top = offset.y
			outline.offset_bottom = -bottom_inset + offset.y


func _activity_card_title_z_index(unlocked: bool, title: CanvasItem = null) -> int:
	if unlocked:
		return MODULE_TITLE_OVER_PIN_Z_INDEX
	if title != null and title.has_meta("activity_card_locked_title_z_index"):
		return int(title.get_meta("activity_card_locked_title_z_index"))
	return 0


func _sync_activity_card_title_layer(card: Dictionary, unlocked: bool) -> void:
	var title := _valid_canvas_item_ref(card.get("title"))
	if title == null:
		return
	var next_z_index := _activity_card_title_z_index(unlocked, title)
	if title.z_index != next_z_index:
		title.z_index = next_z_index


func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 220)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 72)
	if app_bold_font != null:
		button.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		button.add_theme_font_override("font", app_font)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#efe8dc"))
	button.add_theme_color_override("font_outline_color", COLOR_INK)
	button.add_theme_constant_override("outline_size", DEFAULT_BUTTON_TEXT_OUTLINE_SIZE)
	button.add_theme_stylebox_override("normal", _paper_button_style(COLOR_BLUE, 48))
	button.add_theme_stylebox_override("hover", _paper_button_style(COLOR_BLUE, 48))
	button.add_theme_stylebox_override("pressed", _paper_button_style(COLOR_BLUE.darkened(0.10), 48, 72, true))
	button.add_theme_stylebox_override("disabled", _paper_button_style(Color("#b9b3a8"), 48, 72, false, true))
	_button_press_runtime().attach_button_depress_animation(button, 0.97)
	return button


func _progress(fill: Color, height: int, value := 0.0) -> CleanProgressBar:
	var bar := CleanProgressBar.new()
	bar.fill_color = fill
	bar.custom_minimum_size = Vector2(0, height)
	bar.set_value(value)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _skill_detail_xp_bar(skill_id: String, value := 0.0) -> CleanProgressBar:
	var bar := _progress(_skill_theme_color(skill_id), SKILL_DETAIL_XP_BAR_HEIGHT, value)
	bar.custom_minimum_size.x = SKILL_DETAIL_XP_BAR_WIDTH
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar.border_width = 7.0
	_apply_xp_progress_bar_theme(bar, _skill_theme_color(skill_id))
	return bar


func _set_bar(bar, target: float, delta: float, instant: bool) -> void:
	if bar == null:
		return
	var progress := bar as Control
	if progress == null:
		return
	var current_value := 0.0
	if progress is CleanProgressBar:
		current_value = float((progress as CleanProgressBar).value)
	elif progress is ActivityProgressRail:
		current_value = float((progress as ActivityProgressRail).value)
	elif progress is PassiveSerpentineProgressBar:
		current_value = float((progress as PassiveSerpentineProgressBar).value)
	if instant:
		if absf(current_value - target) > 0.001:
			progress.call("set_value", target)
	else:
		if absf(current_value - target) <= 0.01:
			if absf(current_value - target) > 0.001:
				progress.call("set_value", target)
			return
		var step_delta := minf(delta, 0.1)
		var speed := 12.0
		if progress is CleanProgressBar:
			speed = float((progress as CleanProgressBar).easing_speed)
		elif progress is ActivityProgressRail:
			speed = float((progress as ActivityProgressRail).easing_speed)
			if target < current_value:
				speed = 5.5
		elif progress is PassiveSerpentineProgressBar:
			speed = float((progress as PassiveSerpentineProgressBar).easing_speed)
			if target < current_value:
				speed = 5.5
		progress.call("set_value", lerpf(current_value, target, 1.0 - exp(-speed * step_delta)))


func _paper_button_style(color: Color, radius: int, margin := 72, pressed := false, disabled := false) -> StyleBoxTexture:
	return _paper_button_style_with_outline(color, radius, margin, pressed, disabled, COLOR_INK)


func _paper_button_style_with_outline(color: Color, radius: int, margin := 72, pressed := false, disabled := false, outline_color := COLOR_INK) -> StyleBoxTexture:
	return PaperButtonStyles.paper_button_style_with_shape(color, radius, margin, pressed, disabled, outline_color, 5.5, paper_button_style_textures, dark_mode_enabled, PAPER_BUTTON_OUTLINE_WIDTH, Callable(self, "_theme_surface_color"), Callable(self, "_theme_outline_color"), Callable(visual_texture_cache, "_can_create_image_textures"), Callable(visual_texture_cache, "_create_image_texture"), Callable(visual_texture_cache, "_visual_fallback_texture"))


func _surface_style(color: Color, radius: int, margin := 28, elevated := false) -> StyleBoxFlat:
	return ThemeStyles.surface_style(color, radius, margin, elevated, dark_mode_enabled, PASSIVE_BORDER, COLOR_PAPER, COLOR_DARK_PAPER, COLOR_PANEL, COLOR_DARK_PANEL, COLOR_LINE, COLOR_DARK_LINE, COLOR_DARK_PANEL_ALT)


func _skill_detail_shelf_style(skill_id: String, draw_bottom_border := true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if draw_bottom_border:
		style.bg_color = _skill_detail_shelf_color(skill_id)
	else:
		style.bg_color = Color.TRANSPARENT
		style.draw_center = false
	var border := _skill_theme_color(skill_id).lerp(_theme_paper_color(), 0.58)
	border.a = 0.82
	style.border_color = border
	style.border_width_bottom = 5 if draw_bottom_border else 0
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _add_skill_detail_shelf_background(parent: Control, skill_id: String, content_width: float) -> Control:
	var background := SkillDetailGradientShelf.new()
	background.name = "SkillDetailFullBleedShelfBackground"
	background.set_colors(_skill_detail_shelf_color(skill_id), _skill_detail_shelf_gradient_bottom_color(skill_id))
	background.anchor_left = 0.0
	background.anchor_right = 1.0
	background.anchor_top = 0.0
	background.anchor_bottom = 1.0
	var bleed := maxf(PAGE_PAD, (_skill_column_host_width() - content_width) * 0.5) + _skill_swipe_page_span()
	background.offset_left = -bleed
	background.offset_right = bleed
	background.offset_top = -SKILLS_PAGE_TOP_PAD
	background.offset_bottom = SKILL_DETAIL_ACTIONS_DIVIDER_HEIGHT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -20
	background.visible = not (tutorial_active or _onboarding_runtime()._onboarding_path_active())
	if _skill_swipe_shelf_background_should_start_hidden():
		background.modulate.a = 0.0
	parent.add_child(background)
	return background


func _skill_detail_shelf_color(skill_id: String) -> Color:
	return COLOR_DARK_PANEL if dark_mode_enabled else Color("#f1e7d7")


func _skill_detail_shelf_gradient_bottom_color(skill_id: String) -> Color:
	return _skill_detail_shelf_color(skill_id).lerp(_skill_theme_color(skill_id).darkened(0.22), 0.18)


func _module_utility_button_style(fill: Color, pressed := false, active := false) -> StyleBox:
	return PaperButtonStyles.chunky_activity_button_style(fill, 36, 18, pressed, active, paper_button_style_textures, COLOR_INK, COLOR_BLUE, Callable(visual_texture_cache, "_can_create_image_textures"), Callable(visual_texture_cache, "_create_image_texture"), Callable(visual_texture_cache, "_visual_fallback_texture"))


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
	if boot_warmup_runtime == null:
		boot_warmup_runtime = BootWarmupRuntime.new(self)
	return boot_warmup_runtime


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


func _leaderboard_presentation() -> LeaderboardPresentation:
	if leaderboard_presentation == null:
		leaderboard_presentation = LeaderboardPresentation.new(self)
	return leaderboard_presentation


func _leaderboard_state() -> LeaderboardState:
	if leaderboard_state == null:
		leaderboard_state = LeaderboardState.new(self)
	return leaderboard_state


func _button_press_runtime() -> ButtonPressState:
	if button_press_runtime == null:
		button_press_runtime = ButtonPressState.new(self)
	return button_press_runtime


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


func _note_player_input(event: InputEvent) -> void:
	var perf_runtime := _performance_runtime()
	if perf_runtime._input_event_wakes_battery_governor(event):
		perf_runtime._record_battery_governor_activity()
	_audio_director().note_player_input(event)

func _clear(node: Node) -> void:
	for child in node.get_children():
		_kill_transient_tweens_in_subtree(child)
		node.remove_child(child)
		child.queue_free()


func _queue_free_instance_id(instance_id: int) -> void:
	var node := _valid_node_ref(instance_from_id(instance_id))
	if node != null:
		node.queue_free()


func _remove_meta_from_instance_id(instance_id: int, meta_name: StringName) -> void:
	var node := _valid_node_ref(instance_from_id(instance_id))
	if node != null and node.has_meta(meta_name):
		node.remove_meta(meta_name)


func _clear_page_transient_input_state() -> void:
	_button_press_runtime().release_all_depressed_buttons()
	_skill_swipe_activity_surface().release_all_depressed_activity_shell_buttons()
	_navigation_shell()._clear_page_switch_input_state(false)
	_hub_surface()._clear_hub_hotspot_hold()
	_settings_surface()._clear_active_audio_slider()
	_clear_passive_button_press()
	_clear_skill_swipe_button_suppression()
	_fishing_ui_surface()._clear_active_fishing_method_button_press()
	_release_current_action_card_press_state()
	_cancel_action_stop_hold()
	detail_back_press_active = false
	detail_back_press_touch_index = -1
	_skill_detail_surface()._clear_detail_jump_arrow_input_state()
	_input_routing_shell()._clear_activity_lock_input_state()
	stamina_gauge_pending_click = false
	stamina_gauge_pending_skill_id = ""
	stamina_gauge_pending_hold_seconds = 0.0
	stamina_gauge_press_active = false
	stamina_gauge_press_source = null


func _kill_transient_tweens_in_subtree(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is Control:
		_kill_detail_lazy_reveal_tween(node as Control)
	_kill_meta_tween(node, "depress_tween")
	if node is Button:
		_settings_surface()._kill_reset_data_feedback_tween(node as Button)
	else:
		_kill_meta_tween(node, "reset_feedback_tween")
	_kill_meta_tween(node, "bonus_tween")
	_kill_meta_tween(node, "bonus_content_tween")
	_kill_meta_tween(node, "medal_ceremony_tween")
	_kill_meta_tween(node, "medal_outgoing_tween")
	_kill_meta_tween(node, "medal_tap_pop_tween")
	_kill_meta_tween(node, "medal_tap_effect_tween")
	_kill_meta_tween(node, "mastery_bar_tween")
	_kill_meta_tween(node, "activity_crit_text_tween")
	_kill_meta_tween(node, "hub_decor_pop_tween")
	_kill_meta_tween(node, "mat_flyer_tween")
	_kill_meta_tween(node, "mat_pulse_tween")
	for child in node.get_children():
		_kill_transient_tweens_in_subtree(child)


func _kill_meta_tween(node: Node, meta_name: String) -> void:
	if node == null or not is_instance_valid(node) or not node.has_meta(meta_name):
		return
	var tween = node.get_meta(meta_name)
	_app_lifecycle_runtime()._kill_tween_value(tween)
	node.remove_meta(meta_name)
