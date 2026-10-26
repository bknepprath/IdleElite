extends RefCounted

const SKILL_NAMES := {"fight": "Fighting", "thieving": "Thieving", "build": "Building", "woodcutting": "Woodcutting", "fishing": "Fishing"}
const MAX_BALANCE := 2000000000

static func normalize_balances(value: Variant) -> Dictionary:
	var balances := {}
	# The experimental shared balance did not record its source skill. Preserve
	# that progress as a one-time starting balance in each skill when loading it.
	for skill_id in SKILL_NAMES:
		var raw: Variant = value.get(skill_id, 0) if typeof(value) == TYPE_DICTIONARY else value
		var amount := 0
		if typeof(raw) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(raw)):
			amount = int(clampf(float(raw), 0.0, float(MAX_BALANCE)))
		balances[skill_id] = amount
	return balances

static func total(host, skill_id: String) -> int:
	return int(host.material_runtime.wisdom_by_skill.get(skill_id, 0))

static func requirement_met(host, skill_id: String, action: Dictionary) -> bool:
	if total(host, skill_id) >= int(action.get("wisdom_required", 0)):
		return true
	# Preserve activities the player unlocked before Wisdom was introduced.
	return host._activity_unlock_runtime()._manual_activity_unlock_flag_is_trusted(skill_id, str(action.get("id", "")))

# The Wisdom bar under an activity is there while its Wisdom is still to be
# earned. With locks set to open by themselves, a bar that is full is put away
# at once, as a padlock is when its level is reached, whatever else still locks
# the activity. With that setting off nothing opens by itself: the full bar
# stays, and is the Unlock button when it is the last thing left.
static func requirement_bar_shown(host, skill_id: String, action: Dictionary) -> bool:
	if int(action.get("wisdom_required", 0)) <= 0 or host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		return false
	return not host.auto_unlock_lockpads_enabled or not requirement_met(host, skill_id, action)

# Wisdom is of use in a skill while one of its activities that asks for Wisdom is
# still locked. Once the last of them is unlocked there is nothing left to earn
# it for, and its icons are not shown.
static func applicable(host, skill_id: String) -> bool:
	for action in host.actions_by_skill.get(skill_id, []):
		if int(action.get("wisdom_required", 0)) > 0 and not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
			return true
	return false

static func award(host, action: Dictionary) -> int:
	var skill_id := str(action.get("wisdom_skill", ""))
	var reward := maxi(0, int(action.get("wisdom_reward", 0)))
	if reward <= 0 or not SKILL_NAMES.has(skill_id):
		return 0
	var before := total(host, skill_id)
	var after := mini(MAX_BALANCE, before + reward)
	if after == before:
		return 0
	host.material_runtime.wisdom_by_skill[skill_id] = after
	host._mark_save_dirty("wisdom earned")
	var ready_ids := []
	for candidate in host.actions_by_skill.get(skill_id, []):
		var required := int(candidate.get("wisdom_required", 0))
		if required > before and required <= after and host._activity_unlock_runtime()._can_unlock_action(skill_id, candidate):
			ready_ids.append(str(candidate.id))
	if not ready_ids.is_empty():
		host._activity_unlock_runtime()._queue_activity_unlock_readiness("", 0, 0, {skill_id: ready_ids})
	return after - before

static func sources(host, skill_id: String) -> Array:
	var result := []
	for action in host.actions_by_skill.get(skill_id, []):
		if int(action.get("wisdom_reward", 0)) > 0:
			result.append({"skill_id": skill_id, "action": action})
	return result
