extends SceneTree
const Halloween = preload("res://scripts/seasonal/halloween_runtime.gd")
class Onboarding:
    extends RefCounted
    var tutorial_active := false
class Host:
    extends RefCounted
    var onboarding := Onboarding.new()
    func _onboarding_runtime(): return onboarding
    var loaded_save_this_boot := true
    var now := 1792702800
    func _unix_now() -> int: return now
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        push_error(message)
func _init() -> void:
    var events: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/activity-database.json")).seasonal_events
    var host := Host.new()
    var runtime = Halloween.new(host)
    runtime.configure(events)
    var halloween := {"year":2026,"month":10,"day":31}
    host.loaded_save_this_boot = false
    check(not runtime.launch_greeting_eligible(halloween),"First-time players never receive greeting")
    check(not runtime.claim_launch_greeting(halloween),"First launch cannot claim or display greeting")
    host.loaded_save_this_boot = true
    host.onboarding.tutorial_active = true
    check(not runtime.launch_greeting_eligible(halloween),"Returning players still in onboarding remain exempt")
    host.onboarding.tutorial_active = false
    check(runtime.launch_greeting_eligible(halloween),"Available throughout October 31 local time")
    check(not runtime.launch_greeting_eligible({"year":2026,"month":11,"day":1}),"Unavailable on November 1")
    check(not runtime.launch_greeting_eligible({"year":2026,"month":11,"day":2}),"Unavailable after Halloween")
    check(not runtime.launch_greeting_eligible({"year":2027,"month":10,"day":31}),"Does not recur under stale event configuration next year")
    check(not runtime.launch_greeting_eligible({"year":2025,"month":10,"day":31}),"Not enabled before this event year")
    check(runtime.claim_launch_greeting(halloween),"First presentation is allowed")
    check(not runtime.claim_launch_greeting(halloween),"Does not repeat within one launch")
    runtime.configure(events)
    check(not runtime.launch_greeting_eligible(halloween),"Catalog refresh does not repeat the popup")
    var next_launch = Halloween.new(host)
    next_launch.configure(events)
    check(next_launch.claim_launch_greeting(halloween),"A fresh launch can show it again")
    check(not next_launch.for_save().has("launch_greeting_claimed"),"Dismissal is never persisted as a permanent suppression flag")
    for cutoff in ["", "bad", "2026-1-01", "2026-13-01", "2026-11-99"]:
        var malformed = Halloween.new(host)
        var config: Dictionary = events.duplicate(true)
        config["halloween-2026"].launch_greeting.ends_before_local_date = cutoff
        malformed.configure(config)
        check(not malformed.launch_greeting_eligible(halloween),"Malformed cutoff fails closed: "+cutoff)
    var disabled = Halloween.new(host)
    var disabled_events: Dictionary = events.duplicate(true)
    disabled_events["halloween-2026"].enabled = false
    disabled.configure(disabled_events)
    check(not disabled.launch_greeting_eligible(halloween),"Inactive event never shows greeting")
    disabled_events["halloween-2026"].enabled = true
    disabled_events["halloween-2026"].ends_at_unix = host.now
    disabled.configure(disabled_events)
    check(not disabled.launch_greeting_eligible(halloween),"An expired event never shows greeting even before the local popup cutoff")
    print("HALLOWEEN_GREETING_POLICY failures=",JSON.stringify(failures))
    quit(0 if failures.is_empty() else 1)
