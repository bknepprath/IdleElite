extends SceneTree

class AdHost:
	extends Node
	var last_message := ""
	func _reward_feedback_surface(): return self
	func _shop_surface(): return self
	func _set_result(message: String) -> void: last_message = message
	func sync_bonus_display() -> void: pass

class RewardProbe:
	extends "res://scripts/monetization/ad_bonus.gd"
	var grants := 0
	func _grant_ad_bonus(_message: String) -> void: grants += 1

var failures := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var host := AdHost.new()
	root.add_child(host)
	var ads := RewardProbe.new(host)
	var bus := AudioServer.get_bus_index("Master")
	var prior_mute := AudioServer.is_bus_mute(bus)
	for muted in [false, true]:
		AudioServer.set_bus_mute(bus, muted)
		ads.web_request_id += 1
		var id := ads.web_request_id
		ads.web_request_active = true
		ads.ad_loading = true
		ads.ad_reward_earned_for_show = false
		ads._on_web_ad_event([id, "reward"])
		var before := ads.grants
		ads._on_web_ad_event([id, "showing"])
		check(paused and AudioServer.is_bus_mute(bus), "Ad must pause and mute gameplay synchronously")
		ads._on_web_ad_event([id, "reward"])
		ads._on_web_ad_event([id, "reward"])
		check(ads.grants == before + 1, "Completed ad grants exactly once")
		ads._on_web_ad_event([id, "resume"])
		ads._on_web_ad_event([id, "done", "viewed"])
		check(not paused and AudioServer.is_bus_mute(bus) == muted, "Original pause/mute state must be restored")
		check(not ads.ad_loading and not ads.ad_showing and not ads.web_request_active, "Done releases the button")
		ads._on_web_ad_event([id, "reward"])
		check(ads.grants == before + 1, "Stale reward cannot grant again")
	ads.web_request_id += 1
	ads.web_request_active = true
	ads.ad_loading = true
	ads.ad_reward_earned_for_show = false
	var before := ads.grants
	ads._on_web_ad_event([ads.web_request_id - 1, "showing"])
	check(not paused, "Stale showing callback cannot pause game")
	ads._on_web_ad_event([ads.web_request_id, "done", "unavailable"])
	check(ads.grants == before and not ads.ad_loading, "Unavailable ads never grant and permit retry")
	paused = false
	AudioServer.set_bus_mute(bus, prior_mute)
	host.queue_free()
	print("web-rewarded-bonus: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
