extends RefCounted

const GameFormatting = preload("res://scripts/core/formatting.gd")
const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")
const WebRewardedBridge = preload("res://scripts/monetization/web_rewarded_bridge.gd")

const AD_BONUS_SECONDS := 2 * 60 * 60
const AD_BONUS_WARN_THRESHOLD_SECONDS := 4 * 60 * 60
const AD_BONUS_MAX_SECONDS := 6 * 60 * 60
const AD_TEST_UNIT_ANDROID_REWARDED := "ca-app-pub-3940256099942544/5224354917"
const AD_LIVE_UNIT_ANDROID_REWARDED := "ca-app-pub-4125359195200512/8284370963"

var host
var seconds_remaining := 0.0
var rewarded_ad: RewardedAd
var ad_reward_listener := OnUserEarnedRewardListener.new()
var ad_load_callback := RewardedAdLoadCallback.new()
var ad_content_callback := FullScreenContentCallback.new()
var ad_callbacks_configured := false
var ads_initialized := false
var ad_loading := false
var ad_showing := false
var ad_show_after_load := false
var ad_reward_earned_for_show := false
var shop_bonus_notice_text := ""
var consent_bridge: Object
var consent_started := false
var consent_busy := false
var consent_can_request_ads := false
var privacy_options_required := false
var consent_pending_ad := false
var consent_revision := 0
var web_callback: JavaScriptObject
var web_bridge: JavaScriptObject
var web_request_id := 0
var web_request_active := false
var web_game_paused := false
var web_previous_pause := false
var web_previous_mute := false

func _init(host_ref = null) -> void:
	host = host_ref

func xp_multiplier() -> float:
	return float(bonus_percent()) / 100.0

func speed_multiplier() -> float:
	return float(bonus_percent()) / 100.0

func bonus_percent() -> int:
	if seconds_remaining > float(AD_BONUS_WARN_THRESHOLD_SECONDS):
		return 14
	if seconds_remaining > float(AD_BONUS_SECONDS):
		return 12
	return 10 if seconds_remaining > 0.0 else 0

func shop_status_text() -> String:
	return status_text(seconds_remaining)

func shop_label_text() -> String:
	return shop_status_text() if shop_bonus_notice_text.is_empty() else "%s\n%s" % [shop_bonus_notice_text, shop_status_text()]

func process(delta: float) -> void:
	seconds_remaining = tick(seconds_remaining, delta)
	if not consent_started and _ads_supported() and host.startup_initialized and not host._boot_warmup_runtime().active and not host._input_routing_shell()._any_modal_overlay_visible():
		_request_consent()

func _request_consent() -> void:
	if consent_busy:
		return
	consent_started = true
	if not Engine.has_singleton("IdleEliteConsent"):
		return # Missing native consent support must fail closed.
	consent_bridge = Engine.get_singleton("IdleEliteConsent")
	if not consent_bridge.is_connected("consent_finished", _on_consent_finished):
		consent_bridge.connect("consent_finished", _on_consent_finished)
	consent_busy = true
	consent_can_request_ads = false
	consent_bridge.request_consent()

func _on_consent_finished(can_request: bool, options_required: bool, _error: String) -> void:
	consent_busy = false
	consent_can_request_ads = can_request
	privacy_options_required = options_required
	var open_ad := consent_pending_ad
	consent_pending_ad = false
	if open_ad:
		if can_request:
			_load_rewarded_ad(true)
		else:
			host._reward_feedback_surface()._set_result("Ad privacy check unavailable. Try again.")

func show_privacy_options() -> void:
	if consent_busy or ad_showing:
		return
	if not privacy_options_required or consent_bridge == null:
		_request_consent()
		return
	consent_pending_ad = false
	consent_can_request_ads = false
	consent_busy = true
	consent_revision += 1
	ad_loading = false
	ad_show_after_load = false
	_destroy_rewarded_ad()
	consent_bridge.show_privacy_options()

func restore_seconds_from_save(data: Dictionary) -> void:
	seconds_remaining = SaveStateNormalizers.clamped_float(data, "ad_bonus_seconds_remaining", 0.0, float(AD_BONUS_MAX_SECONDS))

func _init_ads() -> void:
	if ad_callbacks_configured:
		return
	ad_callbacks_configured = true
	ad_reward_listener.on_user_earned_reward = _on_rewarded_ad_user_earned_reward
	ad_load_callback.on_ad_loaded = _on_rewarded_ad_loaded
	ad_load_callback.on_ad_failed_to_load = _on_rewarded_ad_failed_to_load
	ad_content_callback.on_ad_dismissed_full_screen_content = _on_rewarded_ad_dismissed
	ad_content_callback.on_ad_failed_to_show_full_screen_content = _on_rewarded_ad_failed_to_show
	ad_content_callback.on_ad_showed_full_screen_content = _on_rewarded_ad_showed

func _ensure_ads_initialized() -> bool:
	_init_ads()
	if consent_busy or not consent_can_request_ads:
		return false
	if ads_initialized:
		return true
	if not _ads_supported() or _rewarded_ad_unit_id().is_empty():
		return false
	MobileAds.initialize()
	ads_initialized = true
	return true

func _ads_supported() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMob") and Engine.has_singleton("PoingGodotAdMobRewardedAd")

func _rewarded_ad_unit_id() -> String:
	if OS.get_name() != "Android":
		return ""
	return AD_TEST_UNIT_ANDROID_REWARDED if OS.is_debug_build() else AD_LIVE_UNIT_ANDROID_REWARDED

func _load_rewarded_ad(show_when_loaded: bool) -> void:
	var unit_id := _rewarded_ad_unit_id()
	if unit_id.is_empty():
		host._reward_feedback_surface()._set_result("Ad Not Configured")
		return
	if not _ads_supported():
		host._reward_feedback_surface()._set_result("Ads need an Android build.")
		return
	if not _ensure_ads_initialized():
		if show_when_loaded:
			consent_pending_ad = true
			_request_consent()
			host._reward_feedback_surface()._set_result("Checking ad privacy settings...")
			if not consent_busy:
				consent_pending_ad = false
				host._reward_feedback_surface()._set_result("Ads unavailable.")
		return
	if ad_loading:
		ad_show_after_load = ad_show_after_load or show_when_loaded
		if show_when_loaded:
			host._reward_feedback_surface()._set_result("Ad loading...")
		return
	ad_loading = true
	ad_show_after_load = show_when_loaded
	if show_when_loaded:
		host._reward_feedback_surface()._set_result("Ad loading...")
	var revision := consent_revision
	ad_load_callback = RewardedAdLoadCallback.new()
	ad_load_callback.on_ad_loaded = func(ad: RewardedAd):
		if revision != consent_revision or not consent_can_request_ads:
			if ad != null: ad.destroy()
			return
		_on_rewarded_ad_loaded(ad)
	ad_load_callback.on_ad_failed_to_load = func(error: LoadAdError):
		if revision == consent_revision: _on_rewarded_ad_failed_to_load(error)
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), ad_load_callback)

func _show_rewarded_ad() -> void:
	if consent_busy or not consent_can_request_ads:
		_destroy_rewarded_ad()
		_load_rewarded_ad(true)
		return
	if rewarded_ad == null:
		_load_rewarded_ad(true)
		return
	ad_showing = true
	ad_reward_earned_for_show = false
	host._reward_feedback_surface()._set_result("Opening ad...")
	rewarded_ad.show(ad_reward_listener)

func _destroy_rewarded_ad() -> void:
	if rewarded_ad != null:
		rewarded_ad.destroy()
		rewarded_ad = null

func _on_rewarded_ad_loaded(ad: RewardedAd) -> void:
	ad_loading = false
	if ad == null:
		var should_report := ad_show_after_load
		ad_show_after_load = false
		if should_report:
			host._reward_feedback_surface()._set_result("Ad failed to load.")
		return
	_destroy_rewarded_ad()
	rewarded_ad = ad
	rewarded_ad.full_screen_content_callback = ad_content_callback
	if ad_show_after_load:
		ad_show_after_load = false
		_show_rewarded_ad()

func _on_rewarded_ad_failed_to_load(error: LoadAdError) -> void:
	var should_report := ad_show_after_load
	ad_loading = false
	ad_show_after_load = false
	if not should_report:
		return
	var message := "Ad failed to load: %s" % error.message if error != null and not error.message.is_empty() else "Ad failed to load."
	host._reward_feedback_surface()._set_result(message)

func _on_rewarded_ad_showed() -> void:
	ad_showing = true

func _on_rewarded_ad_failed_to_show(error: AdError) -> void:
	ad_showing = false
	ad_show_after_load = false
	var message := "Ad failed to show: %s" % error.message if error != null and not error.message.is_empty() else "Ad failed to show."
	host._reward_feedback_surface()._set_result(message)
	_destroy_rewarded_ad()
	_load_rewarded_ad(false)

func _on_rewarded_ad_dismissed() -> void:
	ad_showing = false
	_destroy_rewarded_ad()
	if not ad_reward_earned_for_show:
		host._reward_feedback_surface()._set_result("Ad closed before reward.")
	_load_rewarded_ad(false)

func _on_rewarded_ad_user_earned_reward(_item: RewardedItem) -> void:
	if not ad_showing or ad_reward_earned_for_show:
		return
	ad_reward_earned_for_show = true
	_grant_ad_bonus("Added 2 hours of ad bonus.")

func _grant_ad_bonus(message: String) -> void:
	var bonus_snapshot_before: Dictionary = host._reward_feedback_surface()._capture_visible_bonus_snapshot()
	seconds_remaining = grant_seconds(seconds_remaining, float(AD_BONUS_SECONDS), float(AD_BONUS_MAX_SECONDS))
	shop_bonus_notice_text = message
	host._reward_feedback_surface()._set_result(message)
	host._shop_surface().sync_bonus_display()
	host._update_ui(0.0, false)
	host._reward_feedback_surface()._emphasize_visible_bonus_changes_deferred(bonus_snapshot_before)
	host._shop_surface().emphasize_bonus_award()
	host.save_game()

func press_shop_ad() -> void:
	if is_itch_browser_build():
		host._settings_surface().privacy().show_itch_ad_notice()
		return
	if seconds_remaining > float(AD_BONUS_WARN_THRESHOLD_SECONDS):
		host._reward_feedback_surface()._set_result("Max stackable bonus time is 6 hours.")
		host._shop_surface().sync_bonus_display()
		return
	if ad_showing or ad_loading:
		host._reward_feedback_surface()._set_result("Ad already open.")
		return
	if OS.has_feature("web"):
		_request_web_rewarded_ad()
		return
	if rewarded_ad != null:
		_show_rewarded_ad()
	else:
		_load_rewarded_ad(true)

static func is_itch_browser_build() -> bool:
	return bool(ProjectSettings.get_setting("application/config/itch_browser", false))

func _request_web_rewarded_ad() -> void:
	if web_bridge == null:
		JavaScriptBridge.eval(WebRewardedBridge.SOURCE, true)
		web_bridge = JavaScriptBridge.get_interface("idleEliteRewardedAds")
		web_callback = JavaScriptBridge.create_callback(_on_web_ad_event)
		web_bridge.init(web_callback, WebRewardedBridge.PUBLISHER_ID, WebRewardedBridge.LIVE_ENABLED, OS.is_debug_build())
	web_request_id += 1
	web_request_active = true
	ad_loading = true
	ad_reward_earned_for_show = false
	host._reward_feedback_surface()._set_result("Ad loading...")
	host._shop_surface().sync_bonus_display()
	var master_bus := AudioServer.get_bus_index("Master")
	var audio = host._audio_director()
	var sound_enabled: bool = not AudioServer.is_bus_mute(master_bus) and (not audio.music_muted or not audio.sfx_muted)
	web_bridge.request(web_request_id, sound_enabled)

func _on_web_ad_event(args: Array) -> void:
	if args.size() < 2 or not web_request_active or int(args[0]) != web_request_id:
		return
	match str(args[1]):
		"showing":
			ad_loading = false
			ad_showing = true
			web_previous_pause = host.get_tree().paused
			web_previous_mute = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
			web_game_paused = true
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
			host.get_tree().paused = true
		"reward":
			_on_rewarded_ad_user_earned_reward(null)
		"resume":
			_resume_after_web_ad()
		"done":
			_resume_after_web_ad()
			web_request_active = false
			ad_loading = false
			ad_showing = false
			if not ad_reward_earned_for_show:
				host._reward_feedback_surface()._set_result("No ad available. Try again later.")
			host._shop_surface().sync_bonus_display()

func _resume_after_web_ad() -> void:
	if not web_game_paused:
		return
	web_game_paused = false
	host.get_tree().paused = web_previous_pause
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), web_previous_mute)

static func status_text(seconds_remaining: float) -> String:
	if seconds_remaining <= 0.0:
		return "No bonus active."
	return "Bonus remaining: %s" % GameFormatting.duration(seconds_remaining)

static func tick(seconds_remaining: float, delta: float) -> float:
	return maxf(0.0, maxf(0.0, seconds_remaining) - maxf(0.0, delta))

static func grant_seconds(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> float:
	return clampf(seconds_remaining + bonus_seconds, 0.0, maxf(0.0, max_seconds))

static func stack_max_count(max_seconds: float, bonus_seconds: float) -> int:
	return maxi(1, int(ceil(max_seconds / maxf(1.0, bonus_seconds))))

static func stack_units(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> float:
	return clampf(seconds_remaining / maxf(1.0, bonus_seconds), 0.0, float(stack_max_count(max_seconds, bonus_seconds)))

static func stack_active_count(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> int:
	var units := stack_units(seconds_remaining, bonus_seconds, max_seconds)
	return 0 if units <= 0.0 else clampi(int(ceil(units - 0.001)), 0, stack_max_count(max_seconds, bonus_seconds))
