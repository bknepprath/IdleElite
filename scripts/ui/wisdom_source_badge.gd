extends "res://scripts/ui/unlock_resource_badge.gd"

# The Wisdom book on an activity that gives Wisdom, for a place with no Wisdom
# panel of its own (a Fishing tile). It sits with the item badges and follows
# their rules: it shows while an activity of the skill that asks for Wisdom is
# still locked, a tap says what it is filling, a second tap goes there.

const WisdomState := preload("res://scripts/progression/wisdom_state.gd")
const RECHECK_SECONDS := 0.5

var wisdom_skill_id := ""
var since_check := 0.0

func setup(host_ref, skill_id: String, action: Dictionary) -> void:
	var book_action: Dictionary = action.duplicate()
	book_action["unlock_drop"] = {"id": "wisdom", "amount": int(action.get("wisdom_reward", 0)), "icon": "res://assets/content/icons/resources/wisdom.png"}
	super.setup(host_ref, skill_id, book_action)
	wisdom_skill_id = str(action.get("wisdom_skill", skill_id))
	name = "WisdomRewardBadge"
	icon.material = preload("res://scripts/ui/wisdom_panel.gd").book_material(wisdom_skill_id)

# Unlocking a Wisdom activity sends no signal, so the book looks for itself.
func _process(delta: float) -> void:
	since_check += delta
	if since_check < RECHECK_SECONDS: return
	since_check = 0.0
	_sync_availability()

func _sync_availability() -> void:
	_show_needed(WisdomState.applicable(host, wisdom_skill_id))

# The locked activity of the skill that asks for the least Wisdom: the one this
# Wisdom is filling.
func _wisdom_target() -> Dictionary:
	var target := {}
	for action in host.actions_by_skill.get(wisdom_skill_id, []):
		if int(action.get("wisdom_required", 0)) <= 0 or host._activity_unlock_runtime()._is_action_unlocked(wisdom_skill_id, action): continue
		if target.is_empty() or int(action.wisdom_required) < int(target.wisdom_required): target = action
	return target

func open_target() -> void:
	var runtime = host._project_runtime()
	var go: bool = runtime.second_tap("badge:%s:wisdom" % source_key)
	var target := _wisdom_target()
	if target.is_empty(): return
	# Only a locked frame that is on the page can be gone to.
	var project_id := str((target.get("unlock_project", {}) as Dictionary).get("id", ""))
	var shown: bool = not project_id.is_empty() and runtime.revealed_projects().has(project_id)
	if go and shown:
		runtime.open_project(wisdom_skill_id, project_id)
		return
	var required := int(target.wisdom_required)
	host._navigation_shell()._float_nav_locked_message(self, "Wisdom %d / %d\nfor %s%s" % [mini(WisdomState.total(host, wisdom_skill_id), required), required, str(target.name), runtime.GO_THERE_HINT if shown else ""])

# Wisdom is not sent to a locked frame piece by piece: nothing flies from here.
func _on_resource_sent(_key: String, _resource: String, _amount: int, _project_id: String) -> void:
	pass
