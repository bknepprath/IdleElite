extends RefCounted

const GameFormatting = preload("res://scripts/core/formatting.gd")
const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")

const AD_BONUS_SECONDS := 2 * 60 * 60
const AD_BONUS_WARN_THRESHOLD_SECONDS := 4 * 60 * 60
const AD_BONUS_MAX_SECONDS := 6 * 60 * 60
const AD_BONUS_XP_MULT := 0.10
const AD_BONUS_SPEED_MULT := 0.10
const AD_TEST_UNIT_ANDROID_REWARDED := "ca-app-pub-3940256099942544/5224354917"
const AD_LIVE_UNIT_ANDROID_REWARDED := "ca-app-pub-3570919669688101/7376748559"

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


func _init(host_ref = null) -> void:
	host = host_ref


func setup(host_ref) -> void:
	host = host_ref


func xp_multiplier() -> float:
	return xp_mult(seconds_remaining, AD_BONUS_XP_MULT)


func speed_multiplier() -> float:
	return speed_mult(seconds_remaining, AD_BONUS_SPEED_MULT)


func shop_status_text() -> String:
	return status_text(seconds_remaining)


func shop_label_text() -> String:
	var status := shop_status_text()
	if shop_bonus_notice_text.is_empty():
		return status
	return "%s\n%s" % [shop_bonus_notice_text, status]


func process(delta: float) -> void:
	seconds_remaining = tick(seconds_remaining, delta)


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
	if ads_initialized:
		return true
	if not _ads_supported():
		return false
	if _rewarded_ad_unit_id().is_empty():
		return false
	MobileAds.initialize()
	ads_initialized = true
	return true


func _ads_supported() -> bool:
	return OS.get_name() == "Android" and Engine.has_singleton("PoingGodotAdMobRewardedAd")


func _rewarded_ad_unit_id() -> String:
	if OS.get_name() != "Android":
		return ""
	if OS.is_debug_build():
		return AD_TEST_UNIT_ANDROID_REWARDED
	return AD_LIVE_UNIT_ANDROID_REWARDED


func _load_rewarded_ad(show_when_loaded: bool) -> void:
	if show_when_loaded and _should_grant_ad_preview_bonus():
		ad_loading = false
		ad_show_after_load = false
		_grant_ad_bonus("Ad bonus active: +10% XP, +10% speed for 2 hours.")
		return
	var unit_id := _rewarded_ad_unit_id()
	if unit_id.is_empty():
		host._reward_feedback_surface()._set_result("Ad Not Configured")
		return
	if not _ads_supported():
		host._reward_feedback_surface()._set_result("Ads need an Android build.")
		return
	if not _ensure_ads_initialized():
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
	RewardedAdLoader.new().load(unit_id, AdRequest.new(), ad_load_callback)


func _should_grant_ad_preview_bonus() -> bool:
	return OS.get_name() != "Android"


func _show_rewarded_ad() -> void:
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
	var message := "Ad failed to load."
	if error != null and not error.message.is_empty():
		message = "Ad failed to load: %s" % error.message
	host._reward_feedback_surface()._set_result(message)


func _on_rewarded_ad_showed() -> void:
	ad_showing = true


func _on_rewarded_ad_failed_to_show(error: AdError) -> void:
	ad_showing = false
	ad_show_after_load = false
	var message := "Ad failed to show."
	if error != null and not error.message.is_empty():
		message = "Ad failed to show: %s" % error.message
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
	ad_reward_earned_for_show = true
	_grant_ad_bonus("Ad bonus active: +10% XP, +10% speed for 2 hours.")


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
	if seconds_remaining > float(AD_BONUS_WARN_THRESHOLD_SECONDS):
		host._reward_feedback_surface()._set_result("Max stackable bonus time is 6 hours.")
		host._shop_surface().sync_bonus_display()
		return
	if ad_showing:
		host._reward_feedback_surface()._set_result("Ad already open.")
		return
	if rewarded_ad != null:
		_show_rewarded_ad()
	else:
		_load_rewarded_ad(true)


static func xp_mult(seconds_remaining: float, multiplier: float) -> float:
	return multiplier if seconds_remaining > 0.0 else 0.0


static func speed_mult(seconds_remaining: float, multiplier: float) -> float:
	return multiplier if seconds_remaining > 0.0 else 0.0


static func status_text(seconds_remaining: float) -> String:
	if seconds_remaining <= 0.0:
		return "No bonus active."
	return "Bonus remaining: %s" % GameFormatting.duration(seconds_remaining)


static func tick(seconds_remaining: float, delta: float) -> float:
	if seconds_remaining <= 0.0:
		return 0.0
	return maxf(0.0, seconds_remaining - delta)


static func grant_seconds(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> float:
	return minf(max_seconds, seconds_remaining + bonus_seconds)


static func stack_max_count(max_seconds: float, bonus_seconds: float) -> int:
	return maxi(1, int(ceil(max_seconds / maxf(1.0, bonus_seconds))))


static func stack_units(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> float:
	return clampf(seconds_remaining / maxf(1.0, bonus_seconds), 0.0, float(stack_max_count(max_seconds, bonus_seconds)))


static func stack_active_count(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> int:
	var units := stack_units(seconds_remaining, bonus_seconds, max_seconds)
	if units <= 0.0:
		return 0
	return clampi(int(ceil(units - 0.001)), 0, stack_max_count(max_seconds, bonus_seconds))
