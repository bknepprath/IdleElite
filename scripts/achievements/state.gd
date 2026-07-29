class_name AchievementState

const AchievementPresentation = preload("res://scripts/achievements/presentation.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

const TOTAL_LEVEL_TARGETS := [25, 50, 100, 150, 250, 375, 495]
const CUMULATIVE_TARGETS := [10, 25, 50, 100, 250, 500, 1000]
const TIER_COUNT_STEP := 5
const ACTIVITY_TIER_SIZE := 10
const TIER_SUPPORT_GOALS := [
	{"medal": "Bronze", "medal_level": 1, "stat": "accuracy", "amount": 5.0},
	{"medal": "Silver", "medal_level": 2, "stat": "stamina", "amount": 0.04},
	{"medal": "Gold", "medal_level": 3, "stat": "time", "amount": 0.05}
]

const ACTIVITY_CRIT_ACHIEVEMENT_CHANCE_MULT := 0.01
const _MEDAL_BUFF_STAMINA_SOFT_CAP := 0.72
const _MEDAL_BUFF_TIME_SOFT_CAP := 0.62


static func skill_medal_counts(host: Node, skill_id: String) -> Dictionary:
	var actions: Array = mastery_actions_for_skill(host, skill_id)
	var tiers := []
	for _i in range(host.MASTERY_MAX_LEVEL):
		tiers.append(0)
	var cumulative := 0
	for action in actions:
		var level: int = _mastery_level_for_action(host, skill_id, action as Dictionary)
		cumulative += level
		for tier in range(1, host.MASTERY_MAX_LEVEL + 1):
			if level >= tier:
				tiers[tier - 1] = int(tiers[tier - 1]) + 1
	return {
		"actions": actions.size(),
		"earned": cumulative,
		"possible": actions.size() * host.MASTERY_MAX_LEVEL,
		"tiers": tiers
	}


static func skill_medal_max_stamina_bonus(host: Node, skill_id: String) -> int:
	if skill_id.is_empty():
		return 0
	return int(floor(float(skill_medal_counts(host, skill_id).get("earned", 0)) / 3.0))


static func all_medal_counts(host: Node) -> Dictionary:
	var earned := 0
	var possible := 0
	for def in host.skill_defs:
		var counts := skill_medal_counts(host, str((def as Dictionary)["id"]))
		earned += int(counts["earned"])
		possible += int(counts["possible"])
	return {"earned": earned, "possible": possible}


static func skill_level_completion_counts(host: Node) -> Dictionary:
	var earned := 0
	var possible := 0
	for def in host.skill_defs:
		var level_targets := AchievementPresentation.skill_level_targets()
		possible += level_targets.size()
		for target in level_targets:
			if SkillState.host_skill_level(host, str(def["id"])) >= int(target):
				earned += 1
	return {"earned": earned, "possible": possible}


static func elite_completion_counts(host: Node) -> Dictionary:
	var medal_counts := all_medal_counts(host)
	var skill_counts := skill_level_completion_counts(host)
	return {
		"earned": int(medal_counts["earned"]) + int(skill_counts["earned"]),
		"possible": int(medal_counts["possible"]) + int(skill_counts["possible"])
	}


static func most_impressive_activity(host: Node) -> Dictionary:
	var best := {}
	var best_score := -1.0
	var best_level := 0
	for def in host.skill_defs:
		var skill_id := str(def["id"])
		var actions: Array = mastery_actions_for_skill(host, skill_id)
		for action in actions:
			var action_id := str(action.get("id", ""))
			var level := MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
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
					"medal": MasteryState.medal_name(level),
					"seconds_required": seconds_required
				}
	return best


static func global_medal_buff_lines(host: Node) -> String:
	var lines := active_global_buff_lines(host)
	if lines.is_empty():
		return "Earn your first Bronze medal to unlock the first global buff."
	return "\n".join(lines)


static func active_global_buff_lines(host: Node) -> Array:
	var lines := []
	var stamina_bonus := int(round(global_reward_bonus(host, "max_stamina")))
	var xp_bonus := int(round((global_reward_bonus(host, "xp_mult") + host._ad_bonus_runtime().xp_multiplier()) * 100.0))
	var speed_bonus := int(round((global_reward_bonus(host, "speed_mult") + host._ad_bonus_runtime().speed_multiplier()) * 100.0))
	var success_bonus := int(round(global_reward_bonus(host, "success_bonus")))
	var crit_bonus := global_reward_bonus(host, "crit_chance_mult") * 100.0
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
	var firepit_regen_bonus: float = host._passive_modules_runtime().firepit_stamina_regen_bonus("woodcutting", host._unix_now())
	if firepit_regen_bonus > 0.0:
		var now: int = host._unix_now()
		lines.append(host._passive_modules_runtime().firepit_comfort_text(host._passive_modules_runtime().firepit_heat_tier(now)))
	return lines


static func all_medal_tier_counts(host: Node) -> Array:
	var totals := []
	for _i in range(host.MASTERY_MAX_LEVEL):
		totals.append(0)
	for def in host.skill_defs:
		var counts := skill_medal_counts(host, str((def as Dictionary)["id"]))
		var tiers: Array = counts["tiers"]
		for i in range(mini(host.MASTERY_MAX_LEVEL, tiers.size())):
			totals[i] = int(totals[i]) + int(tiers[i])
	return totals


static func all_medal_summary(host: Node) -> Dictionary:
	var tiers := []
	for _i in range(host.MASTERY_MAX_LEVEL):
		tiers.append(0)
	var earned := 0
	var possible := 0
	var activity_count := 0
	for def in host.skill_defs:
		var counts := skill_medal_counts(host, str((def as Dictionary)["id"]))
		earned += int(counts.get("earned", 0))
		possible += int(counts.get("possible", 0))
		activity_count += int(counts.get("actions", 0))
		var skill_tiers: Array = counts.get("tiers", [])
		for i in range(mini(host.MASTERY_MAX_LEVEL, skill_tiers.size())):
			tiers[i] = int(tiers[i]) + int(skill_tiers[i])
	return {
		"earned": earned,
		"possible": possible,
		"tiers": tiers,
		"activity_count": activity_count
	}


static func total_activity_count(host: Node) -> int:
	var total := 0
	for def in host.skill_defs:
		total += int(mastery_actions_for_skill(host, str((def as Dictionary)["id"])).size())
	return total


static func mastery_actions_for_skill(host: Node, skill_id: String) -> Array:
	var actions := []
	for action in host.actions_by_skill.get(skill_id, []):
		var action_data := action as Dictionary
		if host._passive_modules_runtime().is_passive_action(action_data):
			continue
		actions.append(action_data)
	return actions


static func milestones(host: Node, include_log_only := true) -> Array:
	return _build_all_milestones(milestone_context(host), include_log_only)


static func milestone_context(host: Node, include_action_records := true) -> Dictionary:
	return {
		"total_counts": all_medal_counts(host),
		"total_level": SkillState.global_level(host.skills),
		"max_total_level": host.skill_defs.size() * 99,
		"action_medal_records": action_medal_records(host) if include_action_records else [],
		"tier_counts": all_medal_tier_counts(host),
		"total_activity_count": total_activity_count(host),
		"activity_crit_seen": host.activity_crit_seen,
		"activity_mega_crit_seen": host.activity_mega_crit_seen,
		"crit_reward_text": "Reward: +%s%% crit chance" % GameFormatting.percent_points(ACTIVITY_CRIT_ACHIEVEMENT_CHANCE_MULT * 100.0),
		"crit_reward_amount": ACTIVITY_CRIT_ACHIEVEMENT_CHANCE_MULT,
		"max_mastery_level": host.MASTERY_MAX_LEVEL,
		"medal_names": MasteryState.MEDAL_NAMES,
		"medal_accents": medal_accent_hexes()
	}


static func action_medal_records(host: Node) -> Array:
	var records := []
	for skill_def in host.skill_defs:
		var skill_id := str((skill_def as Dictionary).get("id", ""))
		if skill_id.is_empty():
			continue
		for raw_action in mastery_actions_for_skill(host, skill_id):
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			var current_level: int = MasteryState.level(host.mastery, host._action_key(skill_id, action_id))
			if current_level <= 0:
				continue
			records.append({
				"skill_id": skill_id,
				"action_id": action_id,
				"action_name": str(action.get("name", "Activity")),
				"skill_name": SkillState.skill_name(host.skill_defs, skill_id),
				"current_level": current_level,
				"art": str(action.get("art", ""))
			})
	return records


static func medal_accent_hexes() -> Array:
	var accents := []
	for accent in MasteryState.MEDAL_ACCENTS:
		accents.append("#" + (accent as Color).to_html(false))
	return accents


static func visible_host_milestones(host: Node, hide_completed: bool) -> Array:
	if hide_completed:
		return visible_host_milestones_fast(host)
	return visible_milestones(milestones(host, false), hide_completed)


static func visible_host_milestones_fast(host: Node) -> Array:
	var context := milestone_context(host, false)
	var medal_summary: Dictionary = all_medal_summary(host)
	context["total_counts"] = {
		"earned": int(medal_summary["earned"]),
		"possible": int(medal_summary["possible"])
	}
	context["tier_counts"] = medal_summary["tiers"]
	context["total_activity_count"] = int(medal_summary["activity_count"])
	return _build_visible_fast_milestones(context)


static func _build_all_milestones(context: Dictionary, include_log_only := true) -> Array:
	var milestone_list := []
	_append_total_level_milestones(milestone_list, context)
	if include_log_only:
		_append_action_medal_log_milestones(milestone_list, context)
	_append_tier_count_milestones(milestone_list, context, false)
	_append_cumulative_medal_milestones(milestone_list, context, false)
	_append_crit_milestones(milestone_list, context, false)
	return milestone_list


static func _build_visible_fast_milestones(context: Dictionary) -> Array:
	var milestone_list := []
	_append_total_level_milestones(milestone_list, context, true)
	_append_tier_count_milestones(milestone_list, context, true)
	_append_cumulative_medal_milestones(milestone_list, context, true)
	_append_crit_milestones(milestone_list, context, true)
	return milestone_list


static func _total_level_milestone_medal(target: int, max_total: int, max_level: int) -> int:
	if max_total <= 0:
		return 1
	var scaled := int(ceil(float(target) / float(max_total) * float(max_level)))
	return clampi(scaled, 1, max_level)


static func _append_total_level_milestones(milestone_list: Array, context: Dictionary, first_incomplete_only := false) -> void:
	var total_level := int(context.get("total_level", 0))
	var max_total_level := int(context.get("max_total_level", 0))
	var max_mastery_level := int(context.get("max_mastery_level", 1))
	for target in TOTAL_LEVEL_TARGETS:
		var target_int := int(target)
		if max_total_level < target_int and total_level < target_int:
			continue
		if first_incomplete_only and total_level >= target_int:
			continue
		milestone_list.append({
			"id": "total-level-%s" % target_int,
			"chain_key": "total-level",
			"kind": "total_level",
			"title": "Total Level %s" % target_int,
			"subtitle": "Total Lv %s of %s" % [mini(total_level, target_int), target_int],
			"reward": _total_level_reward_text(target_int),
			"reward_stat": "max_stamina",
			"reward_amount": _total_level_stamina(target_int),
			"current": total_level,
			"target": target_int,
			"completed": total_level >= target_int,
			"medal_level": _total_level_milestone_medal(target_int, max_total_level, max_mastery_level),
			"accent": "#f4bf35"
		})
		if first_incomplete_only:
			break


static func _append_action_medal_log_milestones(milestone_list: Array, context: Dictionary) -> void:
	for raw_record in (context.get("action_medal_records", []) as Array):
		if typeof(raw_record) != TYPE_DICTIONARY:
			continue
		var record := raw_record as Dictionary
		var current_level := int(record.get("current_level", 0))
		for medal_level in range(1, current_level + 1):
			var medal_name := _medal_name(context, medal_level)
			var skill_id := str(record.get("skill_id", ""))
			var action_id := str(record.get("action_id", ""))
			milestone_list.append({
				"id": "action-medal-%s-%s-%s" % [skill_id, action_id, medal_level],
				"chain_key": "action-medal-%s-%s" % [skill_id, action_id],
				"kind": "action_medal",
				"skill_id": skill_id,
				"action_id": action_id,
				"title": "%s %s" % [str(record.get("action_name", "Activity")), medal_name],
				"subtitle": "Earned %s mastery on %s." % [medal_name, str(record.get("skill_name", ""))],
				"reward": "Reward: permanent mastery credit",
				"current": medal_level,
				"target": medal_level,
				"completed": true,
				"log_only": true,
				"medal_level": medal_level,
				"art": str(record.get("art", "")),
				"accent": _medal_accent(context, medal_level)
			})


static func _append_tier_count_milestones(milestone_list: Array, context: Dictionary, first_incomplete_only: bool) -> void:
	var tier_counts: Array = context.get("tier_counts", [])
	var total_activity_count := int(context.get("total_activity_count", 0))
	for tier_index in range(mini(int(context.get("max_mastery_level", 1)), tier_counts.size())):
		var tier := tier_index + 1
		var target := _tier_count_target(tier)
		var current := int(tier_counts[tier_index])
		if total_activity_count < target and current < target:
			continue
		if first_incomplete_only and current >= target:
			continue
		var medal_name := _medal_name(context, tier)
		milestone_list.append({
			"id": "tier-count-%s-%s" % [tier, target],
			"chain_key": "tier-count-medals",
			"kind": "tier_count",
			"tier": tier,
			"title": "%s Medals" % medal_name,
			"subtitle": "%s of %s %s medals earned" % [mini(current, target), target, medal_name],
			"reward": _tier_count_reward_text(tier),
			"reward_stat": "max_stamina",
			"reward_amount": _tier_count_stamina(tier),
			"current": current,
			"target": target,
			"completed": current >= target,
			"medal_level": tier,
			"accent": _medal_accent(context, tier)
		})
		if first_incomplete_only:
			break


static func _append_cumulative_medal_milestones(milestone_list: Array, context: Dictionary, first_incomplete_only: bool) -> void:
	var total_counts := context.get("total_counts", {}) as Dictionary
	var cumulative := int(total_counts.get("earned", 0))
	var cumulative_possible := int(total_counts.get("possible", 0))
	for target in CUMULATIVE_TARGETS:
		var target_int := int(target)
		if cumulative_possible < target_int and cumulative < target_int:
			continue
		if first_incomplete_only and cumulative >= target_int:
			continue
		milestone_list.append({
			"id": "cumulative-%s" % target_int,
			"chain_key": "cumulative-medals",
			"kind": "cumulative_medals",
			"title": "Cumulative Medals",
			"subtitle": "%s of %s total medals earned" % [mini(cumulative, target_int), target_int],
			"reward": _cumulative_medal_reward_text(target_int),
			"reward_stat": "max_stamina",
			"reward_amount": _cumulative_medal_stamina(target_int),
			"current": cumulative,
			"target": target_int,
			"completed": cumulative >= target_int,
			"medal_level": 1,
			"accent": "#f4bf35"
		})
		if first_incomplete_only:
			break


static func _append_crit_milestones(milestone_list: Array, context: Dictionary, first_incomplete_only: bool) -> void:
	var crit_seen := bool(context.get("activity_crit_seen", false))
	var mega_crit_seen := bool(context.get("activity_mega_crit_seen", false))
	var crit_reward_text := str(context.get("crit_reward_text", "Reward: crit chance"))
	var crit_reward_amount := float(context.get("crit_reward_amount", 0.0))
	if not first_incomplete_only or not crit_seen:
		milestone_list.append(_crit_milestone("activity-crit", "Critical Success", "Land your first CRIT!!", crit_reward_text, crit_reward_amount, crit_seen, 1, "#67b8ff"))
	if first_incomplete_only and not crit_seen:
		return
	if not first_incomplete_only or not mega_crit_seen:
		milestone_list.append(_crit_milestone("activity-mega-crit", "Mega Critical Success", "Land your first MEGA CRIT!!!!", crit_reward_text, crit_reward_amount, mega_crit_seen, 2, "#fff052"))


static func _crit_milestone(id: String, title: String, subtitle: String, reward: String, reward_amount: float, completed: bool, medal_level: int, accent: String) -> Dictionary:
	return {
		"id": id,
		"chain_key": "activity-crits",
		"kind": "activity_crit",
		"title": title,
		"subtitle": subtitle,
		"reward": reward,
		"reward_stat": "crit_chance_mult",
		"reward_amount": reward_amount,
		"current": 1 if completed else 0,
		"target": 1,
		"completed": completed,
		"medal_level": medal_level,
		"accent": accent
	}


static func _medal_name(context: Dictionary, tier: int) -> String:
	var names: Array = context.get("medal_names", [])
	var index := clampi(tier - 1, 0, names.size() - 1)
	return str(names[index]) if not names.is_empty() else "Medal"


static func _medal_accent(context: Dictionary, tier: int) -> String:
	var accents: Array = context.get("medal_accents", [])
	var index := clampi(tier - 1, 0, accents.size() - 1)
	return str(accents[index]) if not accents.is_empty() else "#f4bf35"


static func _stamina_reward_text(amount: int) -> String:
	return "+%s max stamina" % maxi(1, amount)


static func _total_level_stamina(target: int) -> int:
	if target >= 250:
		return 4
	if target >= 100:
		return 3
	if target >= 50:
		return 2
	return 1


static func _cumulative_medal_stamina(target: int) -> int:
	if target >= 500:
		return 5
	if target >= 100:
		return 3
	if target >= 25:
		return 2
	return 1


static func _tier_count_target(tier: int) -> int:
	return maxi(1, tier) * TIER_COUNT_STEP


static func _tier_count_stamina(tier: int) -> int:
	if tier >= 9:
		return 3
	if tier >= 5:
		return 2
	return 1


static func _total_level_reward_text(target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_total_level_stamina(target))


static func _cumulative_medal_reward_text(target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_cumulative_medal_stamina(target))


static func _tier_count_reward_text(tier: int) -> String:
	return "Reward: %s" % _stamina_reward_text(_tier_count_stamina(tier))


static func normalized_seen_ids(value: Variant) -> Dictionary:
	var seen_ids := {}
	if typeof(value) != TYPE_DICTIONARY:
		return seen_ids
	var source := value as Dictionary
	for raw_id in source.keys():
		var id := str(raw_id)
		if id.is_empty() or not bool(source.get(raw_id, false)):
			continue
		seen_ids[id] = true
	return seen_ids


static func completed_ids(milestones: Array) -> Dictionary:
	var completed := {}
	for raw_achievement in milestones:
		if typeof(raw_achievement) != TYPE_DICTIONARY:
			continue
		var achievement := raw_achievement as Dictionary
		var id := str(achievement.get("id", ""))
		if id.is_empty() or not is_completed_public(achievement):
			continue
		completed[id] = true
	return completed


static func newly_completed(milestones: Array, before: Dictionary) -> Array:
	var unlocked := []
	for raw_achievement in milestones:
		if typeof(raw_achievement) != TYPE_DICTIONARY:
			continue
		var achievement := raw_achievement as Dictionary
		var id := str(achievement.get("id", ""))
		if id.is_empty() or not is_completed_public(achievement):
			continue
		if not bool(before.get(id, false)):
			unlocked.append(achievement)
	return unlocked


static func mark_completed_seen_ids(milestones: Array, seen_ids: Dictionary, excluded_ids: Array = []) -> void:
	for raw_achievement in milestones:
		if typeof(raw_achievement) != TYPE_DICTIONARY:
			continue
		var achievement := raw_achievement as Dictionary
		var id := str(achievement.get("id", ""))
		if id.is_empty() or excluded_ids.has(id) or not is_completed_public(achievement):
			continue
		seen_ids[id] = true


static func reward_bonus(milestones: Array, stat: String, skill_id := "") -> float:
	var total := 0.0
	for raw_achievement in milestones:
		if typeof(raw_achievement) != TYPE_DICTIONARY:
			continue
		var achievement := raw_achievement as Dictionary
		if not bool(achievement.get("completed", false)) or str(achievement.get("reward_stat", "")) != stat:
			continue
		var reward_skill_id := str(achievement.get("reward_skill_id", ""))
		if not skill_id.is_empty() and not reward_skill_id.is_empty() and reward_skill_id != skill_id:
			continue
		if skill_id.is_empty() and not reward_skill_id.is_empty():
			continue
		total += float(achievement.get("reward_amount", 0.0))
	return total


static func global_reward_bonus(host: Node, stat: String, skill_id := "") -> float:
	var cache_key := "%s|%s|%s" % [host._action_runtime().stat_cache_version, stat, skill_id]
	if host.reward_bonus_cache.has(cache_key):
		return float(host.reward_bonus_cache[cache_key])
	var value := global_medal_bonus(host, stat) + reward_bonus(milestones(host), stat, skill_id)
	host.reward_bonus_cache[cache_key] = value
	return value


static func global_medal_tier_unlocked(host: Node, level: int) -> bool:
	for key in host.mastery.keys():
		var entry = host.mastery[key]
		if typeof(entry) == TYPE_DICTIONARY and int(entry.get("level", 0)) >= level:
			return true
	return false


static func global_medal_bonus(host: Node, stat: String) -> float:
	var total := 0.0
	for buff in MasteryState.GLOBAL_MEDAL_BUFFS:
		if str((buff as Dictionary).get("stat", "")) == stat and global_medal_tier_unlocked(host, int((buff as Dictionary).get("level", 0))):
			total += float((buff as Dictionary).get("amount", 0.0))
	return total


static func new_global_medal_buff_messages(host: Node, old_level: int, new_level: int, tiers_unlocked_before: Dictionary) -> Array:
	var messages := []
	for tier in range(old_level + 1, new_level + 1):
		if tier >= 1 and tier <= host.MASTERY_MAX_LEVEL and not bool(tiers_unlocked_before.get(tier, false)):
			messages.append("%s global buff unlocked: %s." % [MasteryState.medal_name(tier), global_medal_tier_bonus_text(host, tier)])
	return messages


static func global_medal_tier_bonus_text(host: Node, level: int) -> String:
	for buff in MasteryState.GLOBAL_MEDAL_BUFFS:
		var buff_def := buff as Dictionary
		if int(buff_def.get("level", 0)) != level:
			continue
		var stat := str(buff_def.get("stat", ""))
		var amount := float(buff_def.get("amount", 0.0))
		if stat == "max_stamina":
			return "+%s max stamina" % int(round(amount))
		if stat == "xp_mult":
			return "+%s%% XP" % int(round(amount * 100.0))
		if stat == "speed_mult":
			return "+%s%% speed" % int(round(amount * 100.0))
		if stat == "success_bonus":
			return "+%s%% success" % int(round(amount))
	return "global power"


static func activity_medal_stamina_cost_reduction(host: Node, skill_id: String, action: Dictionary) -> float:
	return clampf(activity_medal_buff_total(host, skill_id, action, "stamina"), 0.0, 0.95)


static func activity_medal_time_reduction(host: Node, skill_id: String, action: Dictionary) -> float:
	return clampf(activity_medal_buff_total(host, skill_id, action, "time"), 0.0, 0.9)


static func activity_medal_accuracy_bonus(host: Node, skill_id: String, action: Dictionary) -> float:
	return clampf(activity_medal_buff_total(host, skill_id, action, "accuracy"), 0.0, 95.0)


static func action_tier(host: Node, action: Dictionary) -> int:
	var level := maxi(1, host.activity_data_catalog.activity_action_display_sort_level(action))
	return int(floor(float(level - 1) / float(ACTIVITY_TIER_SIZE))) + 1


static func tier_medal_counts(host: Node, skill_id: String, tier: int) -> Dictionary:
	var earned := 0
	var possible := 0
	var gold_plus := 0
	var actions := 0
	var medal_tiers := []
	for _i in range(host.MASTERY_MAX_LEVEL):
		medal_tiers.append(0)
	for action in playable_actions_for_medal_buffs(host, skill_id):
		var action_data := action as Dictionary
		if action_tier(host, action_data) != tier:
			continue
		actions += 1
		possible += host.MASTERY_MAX_LEVEL
		var medal_level := clampi(_mastery_level_for_action(host, skill_id, action_data), 0, host.MASTERY_MAX_LEVEL)
		earned += medal_level
		if medal_level >= 3:
			gold_plus += 1
		for medal_tier in range(1, host.MASTERY_MAX_LEVEL + 1):
			if medal_level >= medal_tier:
				medal_tiers[medal_tier - 1] = int(medal_tiers[medal_tier - 1]) + 1
	return {"actions": actions, "earned": earned, "possible": possible, "gold_plus": gold_plus, "tiers": medal_tiers}


static func _mastery_level_for_action(host: Node, skill_id: String, action: Dictionary) -> int:
	var action_id := _mastery_action_id_for_action(host, skill_id, action)
	return MasteryState.level(host.mastery, host._action_key(skill_id, action_id))


static func _mastery_action_id_for_action(host: Node, skill_id: String, action: Dictionary) -> String:
	var action_id := str(action.get("id", ""))
	if action_id.is_empty():
		return action_id
	if host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action):
		return host.fishing_runtime.mastery_action_id(action_id, host.fishing_runtime.FISHING_TOOL_LOCATION_ACTIONS, Callable(host._fishing_ui_surface(), "_fishing_location_thumbnail_path"))
	return action_id


static func tier_support_bonus(host: Node, skill_id: String, target_tier: int, stat: String) -> float:
	if target_tier <= 1:
		return 0.0
	var total := 0.0
	for raw_goal in tier_support_goals(host, skill_id, target_tier - 1):
		var goal := raw_goal as Dictionary
		if bool(goal.get("completed", false)) and str(goal.get("stat", "")) == stat:
			total += float(goal.get("amount", 0.0))
	return total


static func tier_support_goals(host: Node, skill_id: String, source_tier: int) -> Array:
	return tier_support_goals_from_counts(tier_medal_counts(host, skill_id, source_tier), source_tier + 1)


static func tier_support_goals_from_counts(counts: Dictionary, target_tier: int) -> Array:
	var goals := []
	var action_count := maxi(0, int(counts.get("actions", 0)))
	var medal_tiers: Array = counts.get("tiers", [])
	for raw_goal in TIER_SUPPORT_GOALS:
		var goal := (raw_goal as Dictionary).duplicate()
		var medal_level := int(goal.get("medal_level", 0))
		var earned := int(medal_tiers[medal_level - 1]) if medal_level > 0 and medal_tiers.size() >= medal_level else 0
		goal["earned"] = earned
		goal["possible"] = action_count
		goal["completed"] = action_count > 0 and earned >= action_count
		goal["reward_text"] = _tier_threshold_bonus_text(goal, target_tier)
		goals.append(goal)
	return goals


static func activity_tier_stamina_cost_reduction(host: Node, skill_id: String, action: Dictionary) -> float:
	var tier := action_tier(host, action)
	return clampf(tier_support_bonus(host, skill_id, tier, "stamina"), 0.0, 0.30)


static func activity_tier_time_reduction(host: Node, skill_id: String, action: Dictionary) -> float:
	var tier := action_tier(host, action)
	return clampf(tier_support_bonus(host, skill_id, tier, "time"), 0.0, 0.25)


static func activity_tier_accuracy_bonus(host: Node, skill_id: String, action: Dictionary) -> float:
	var tier := action_tier(host, action)
	return clampf(tier_support_bonus(host, skill_id, tier, "accuracy"), 0.0, 35.0)


static func tier_support_lines(host: Node, skill_id: String, source_tier: int) -> Array:
	var lines := []
	for raw_goal in tier_support_goals(host, skill_id, source_tier):
		var goal := raw_goal as Dictionary
		if bool(goal.get("completed", false)):
			lines.append(str(goal.get("reward_text", "")))
	return lines


static func next_tier_support_threshold_line(host: Node, skill_id: String, source_tier: int) -> String:
	for raw_goal in tier_support_goals(host, skill_id, source_tier):
		var goal := raw_goal as Dictionary
		var needed := int(goal.get("possible", 0)) - int(goal.get("earned", 0))
		if needed > 0:
			return "%s on %s more Tier %s activities: %s" % [str(goal.get("medal", "Medal")), needed, source_tier, str(goal.get("reward_text", ""))]
	return "All Tier %s support bonuses active." % source_tier


static func _tier_threshold_bonus_text(threshold: Dictionary, target_tier: int) -> String:
	var stat := str(threshold.get("stat", ""))
	var amount := float(threshold.get("amount", 0.0))
	if stat == "accuracy":
		return "+%s%% Tier %s accuracy" % [GameFormatting.percent_points(amount), target_tier]
	if stat == "stamina":
		return "-%s%% Tier %s stamina cost" % [GameFormatting.percent_points(amount * 100.0), target_tier]
	if stat == "time":
		return "+%s%% Tier %s speed" % [GameFormatting.percent_points(amount * 100.0), target_tier]
	return "Tier %s support" % target_tier


static func activity_medal_buff_total(host: Node, skill_id: String, action: Dictionary, effect: String) -> float:
	var action_id := str(action.get("id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return 0.0
	var event_level_key := str(host.activity_data_catalog.activity_action_display_sort_level(action)) if host._is_event_action(action) else "0"
	var cache_key := "%s|%s|%s|%s|%s" % [host._action_runtime().stat_cache_version, skill_id, action_id, effect, event_level_key]
	if host.activity_medal_buff_total_cache.has(cache_key):
		return float(host.activity_medal_buff_total_cache[cache_key])
	var total := _medal_buff_total(activity_medal_buff_contributions(host, skill_id, action, effect), effect)
	host.activity_medal_buff_total_cache[cache_key] = total
	return total


static func activity_medal_buff_contributions(host: Node, skill_id: String, action: Dictionary, effect: String) -> Array:
	var action_id := str(action.get("id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return []
	if host._passive_modules_runtime().is_passive_action(action):
		return []
	var is_event_target: bool = host._is_event_action(action)
	var playable_actions := playable_actions_for_medal_buffs_including_event(host, skill_id, action) if is_event_target else playable_actions_for_medal_buffs(host, skill_id)
	var target_index := playable_action_index(playable_actions, action_id) if is_event_target else playable_action_index_cached(host, skill_id, playable_actions, action_id)
	return _medal_buff_contributions(
		playable_actions,
		target_index,
		effect,
		func(source_action_id: String) -> int: return MasteryState.level(host.mastery, host._action_key(skill_id, source_action_id)),
		host.MASTERY_MAX_LEVEL
	)


static func _medal_buff_contributions(playable_actions: Array, target_index: int, effect: String, mastery_level: Callable, max_level: int) -> Array:
	var results := []
	if target_index < 0:
		return results
	for i in range(playable_actions.size()):
		if i == target_index:
			continue
		var source_action := playable_actions[i] as Dictionary
		var source_action_id := str(source_action.get("id", ""))
		if source_action_id.is_empty():
			continue
		var medal_tier := clampi(int(mastery_level.call(source_action_id)), 0, max_level)
		if medal_tier <= 0:
			continue
		var distance := target_index - i
		var per_tier := _medal_buff_per_tier(distance, effect)
		if per_tier <= 0.0:
			continue
		results.append({
			"source_id": source_action_id,
			"source_name": str(source_action.get("name", source_action_id.capitalize())),
			"level": medal_tier,
			"distance": distance,
			"per_tier": per_tier,
			"amount": per_tier * float(medal_tier)
		})
	return results


static func _medal_buff_total(contributions: Array, effect: String) -> float:
	var raw_total := 0.0
	for raw_contribution in contributions:
		raw_total += float((raw_contribution as Dictionary).get("amount", 0.0))
	match effect:
		"stamina":
			return _medal_buff_soft_cap(raw_total, _MEDAL_BUFF_STAMINA_SOFT_CAP)
		"time":
			return _medal_buff_soft_cap(raw_total, _MEDAL_BUFF_TIME_SOFT_CAP)
		_:
			return raw_total


static func _medal_buff_soft_cap(amount: float, cap: float) -> float:
	if amount <= 0.0 or cap <= 0.0:
		return 0.0
	return cap * (1.0 - exp(-amount / cap))


static func _medal_buff_per_tier(distance: int, effect: String) -> float:
	if distance > 0:
		if effect == "stamina" or effect == "time":
			if distance == 1:
				return 0.012
			if distance == 2:
				return 0.006
			if distance == 3:
				return 0.003
		return 0.0
	if distance < 0:
		if effect != "stamina" and effect != "accuracy":
			return 0.0
		var prior_distance := -distance
		if prior_distance >= 1 and prior_distance <= 5:
			var prior_percent := float(6 - prior_distance) * 0.1
			return prior_percent if effect == "accuracy" else prior_percent * 0.01
	return 0.0


static func playable_actions_for_medal_buffs(host: Node, skill_id: String) -> Array:
	if host.playable_medal_buff_actions_cache.has(skill_id):
		return host.playable_medal_buff_actions_cache[skill_id] as Array
	var playable_actions := []
	for raw_action in host.actions_by_skill.get(skill_id, []):
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var action := raw_action as Dictionary
		if host._passive_modules_runtime().is_passive_action(action):
			continue
		if str(action.get("id", "")).is_empty():
			continue
		playable_actions.append(action)
	host.playable_medal_buff_actions_cache[skill_id] = playable_actions
	return playable_actions


static func playable_actions_for_medal_buffs_including_event(host: Node, skill_id: String, event_action: Dictionary) -> Array:
	var playable_actions := (playable_actions_for_medal_buffs(host, skill_id) as Array).duplicate()
	var event_id := str(event_action.get("id", ""))
	if event_id.is_empty():
		return playable_actions
	var replaced := false
	for i in range(playable_actions.size()):
		var action := playable_actions[i] as Dictionary
		if str(action.get("id", "")) == event_id:
			playable_actions[i] = event_action
			replaced = true
			break
	if not replaced:
		playable_actions.append(event_action)
	playable_actions.sort_custom(func(left, right): return host.activity_data_catalog.activity_action_display_sort_less(left, right))
	return playable_actions


static func playable_action_index_cached(host: Node, skill_id: String, playable_actions: Array, action_id: String) -> int:
	var cache_key := "%s|%s" % [skill_id, action_id]
	if host.playable_medal_buff_index_cache.has(cache_key):
		return int(host.playable_medal_buff_index_cache[cache_key])
	var index := playable_action_index(playable_actions, action_id)
	host.playable_medal_buff_index_cache[cache_key] = index
	return index


static func playable_action_index(playable_actions: Array, action_id: String) -> int:
	for i in range(playable_actions.size()):
		var action := playable_actions[i] as Dictionary
		if str(action.get("id", "")) == action_id:
			return i
	return -1


static func activity_medal_buff_lines(host: Node, skill_id: String, action: Dictionary, effect: String, label: String) -> Array:
	var lines := []
	var total := activity_medal_buff_total(host, skill_id, action, effect)
	if total <= 0.0:
		return lines
	var displayed_amount := total if effect == "accuracy" else total * 100.0
	var effect_name := "neighbor medal bonus"
	lines.append("%s%s%% %s" % [label, GameFormatting.percent_points(displayed_amount), effect_name])
	return lines


static func activity_medal_rate_bonus(host: Node, skill_id: String, action: Dictionary) -> float:
	var action_id := str(action.get("id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return 0.0
	var own_medal_bonus := 0.0 if host._is_event_action(action) else float(clampi(MasteryState.level(host.mastery, host._action_key(skill_id, action_id)), 0, host.MASTERY_MAX_LEVEL))
	return own_medal_bonus + activity_medal_accuracy_bonus(host, skill_id, action) + activity_tier_accuracy_bonus(host, skill_id, action)


static func visible_milestones(milestones: Array, hide_completed: bool) -> Array:
	var chain_order := []
	var chains := {}
	for raw_achievement in milestones:
		if typeof(raw_achievement) != TYPE_DICTIONARY:
			continue
		var achievement := raw_achievement as Dictionary
		if not should_show_in_bonus_log(achievement):
			continue
		var chain_key := str(achievement.get("chain_key", achievement.get("id", "")))
		if chain_key.is_empty():
			continue
		if not chains.has(chain_key):
			chains[chain_key] = []
			chain_order.append(chain_key)
		(chains[chain_key] as Array).append(achievement)
	var visible_achievements := []
	for chain_key in chain_order:
		var chain: Array = chains[chain_key]
		var next_achievement := {}
		for achievement in chain:
			if bool(achievement.get("completed", false)):
				if not hide_completed:
					visible_achievements.append(achievement)
				continue
			if next_achievement.is_empty():
				next_achievement = achievement
		if not next_achievement.is_empty():
			visible_achievements.append(next_achievement)
	return visible_achievements


static func should_show_in_bonus_log(achievement: Dictionary) -> bool:
	return (
		not bool(achievement.get("log_only", false))
		and not str(achievement.get("reward_stat", "")).is_empty()
	)


static func is_completed_public(achievement: Dictionary) -> bool:
	return bool(achievement.get("completed", false)) and not bool(achievement.get("log_only", false))
