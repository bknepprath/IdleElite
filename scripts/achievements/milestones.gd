class_name AchievementMilestones

const AchievementRewards = preload("res://scripts/achievements/rewards.gd")
const CUMULATIVE_TARGETS := [10, 25, 50, 100, 250, 500, 1000]


static func build_all(context: Dictionary, include_log_only := true) -> Array:
	var milestones := []
	_append_total_level_milestones(milestones, context)
	if include_log_only:
		_append_action_medal_log_milestones(milestones, context)
	_append_tier_count_milestones(milestones, context, false)
	_append_cumulative_medal_milestones(milestones, context, false)
	_append_crit_milestones(milestones, context, false)
	return milestones


static func build_visible_fast(context: Dictionary) -> Array:
	var milestones := []
	_append_total_level_milestones(milestones, context, true)
	_append_tier_count_milestones(milestones, context, true)
	_append_cumulative_medal_milestones(milestones, context, true)
	_append_crit_milestones(milestones, context, true)
	return milestones


static func total_level_milestone_medal(target: int, max_total: int, max_level: int) -> int:
	if max_total <= 0:
		return 1
	var scaled := int(ceil(float(target) / float(max_total) * float(max_level)))
	return clampi(scaled, 1, max_level)


static func _append_total_level_milestones(milestones: Array, context: Dictionary, first_incomplete_only := false) -> void:
	var total_level := int(context.get("total_level", 0))
	var max_total_level := int(context.get("max_total_level", 0))
	var max_mastery_level := int(context.get("max_mastery_level", 1))
	for target in AchievementRewards.TOTAL_LEVEL_TARGETS:
		var target_int := int(target)
		if max_total_level < target_int and total_level < target_int:
			continue
		if first_incomplete_only and total_level >= target_int:
			continue
		milestones.append({
			"id": "total-level-%s" % target_int,
			"chain_key": "total-level",
			"kind": "total_level",
			"title": "Total Level %s" % target_int,
			"subtitle": "Total Lv %s of %s" % [mini(total_level, target_int), target_int],
			"reward": _total_level_reward_text(target_int),
			"reward_stat": "max_stamina",
			"reward_amount": AchievementRewards.total_level_stamina(target_int),
			"current": total_level,
			"target": target_int,
			"completed": total_level >= target_int,
			"medal_level": total_level_milestone_medal(target_int, max_total_level, max_mastery_level),
			"accent": "#f4bf35"
		})
		if first_incomplete_only:
			break


static func _append_action_medal_log_milestones(milestones: Array, context: Dictionary) -> void:
	for raw_record in (context.get("action_medal_records", []) as Array):
		if typeof(raw_record) != TYPE_DICTIONARY:
			continue
		var record := raw_record as Dictionary
		var current_level := int(record.get("current_level", 0))
		for medal_level in range(1, current_level + 1):
			var medal_name := _medal_name(context, medal_level)
			var skill_id := str(record.get("skill_id", ""))
			var action_id := str(record.get("action_id", ""))
			milestones.append({
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


static func _append_tier_count_milestones(milestones: Array, context: Dictionary, first_incomplete_only: bool) -> void:
	var tier_counts: Array = context.get("tier_counts", [])
	var total_activity_count := int(context.get("total_activity_count", 0))
	for tier_index in range(mini(int(context.get("max_mastery_level", 1)), tier_counts.size())):
		var tier := tier_index + 1
		var target := AchievementRewards.tier_count_target(tier)
		var current := int(tier_counts[tier_index])
		if total_activity_count < target and current < target:
			continue
		if first_incomplete_only and current >= target:
			continue
		var medal_name := _medal_name(context, tier)
		milestones.append({
			"id": "tier-count-%s-%s" % [tier, target],
			"chain_key": "tier-count-medals",
			"kind": "tier_count",
			"tier": tier,
			"title": "%s Medals" % medal_name,
			"subtitle": "%s of %s %s medals earned" % [mini(current, target), target, medal_name],
			"reward": _tier_count_reward_text(tier),
			"reward_stat": "max_stamina",
			"reward_amount": AchievementRewards.tier_count_stamina(tier),
			"current": current,
			"target": target,
			"completed": current >= target,
			"medal_level": tier,
			"accent": _medal_accent(context, tier)
		})
		if first_incomplete_only:
			break


static func _append_cumulative_medal_milestones(milestones: Array, context: Dictionary, first_incomplete_only: bool) -> void:
	var total_counts := context.get("total_counts", {}) as Dictionary
	var cumulative := int(total_counts.get("earned", 0))
	var cumulative_possible := int(total_counts.get("possible", 0))
	for target in CUMULATIVE_TARGETS:
		var target_int := int(target)
		if cumulative_possible < target_int and cumulative < target_int:
			continue
		if first_incomplete_only and cumulative >= target_int:
			continue
		milestones.append({
			"id": "cumulative-%s" % target_int,
			"chain_key": "cumulative-medals",
			"kind": "cumulative_medals",
			"title": "Cumulative Medals",
			"subtitle": "%s of %s total medals earned" % [mini(cumulative, target_int), target_int],
			"reward": _cumulative_medal_reward_text(target_int),
			"reward_stat": "max_stamina",
			"reward_amount": AchievementRewards.cumulative_medal_stamina(target_int),
			"current": cumulative,
			"target": target_int,
			"completed": cumulative >= target_int,
			"medal_level": 1,
			"accent": "#f4bf35"
		})
		if first_incomplete_only:
			break


static func _append_crit_milestones(milestones: Array, context: Dictionary, first_incomplete_only: bool) -> void:
	var crit_seen := bool(context.get("activity_crit_seen", false))
	var mega_crit_seen := bool(context.get("activity_mega_crit_seen", false))
	var crit_reward_text := str(context.get("crit_reward_text", "Reward: crit chance"))
	var crit_reward_amount := float(context.get("crit_reward_amount", 0.0))
	if not first_incomplete_only or not crit_seen:
		milestones.append(_crit_milestone("activity-crit", "Critical Success", "Land your first CRIT!!", crit_reward_text, crit_reward_amount, crit_seen, 1, "#67b8ff"))
	if first_incomplete_only and not crit_seen:
		return
	if not first_incomplete_only or not mega_crit_seen:
		milestones.append(_crit_milestone("activity-mega-crit", "Mega Critical Success", "Land your first MEGA CRIT!!!!", crit_reward_text, crit_reward_amount, mega_crit_seen, 2, "#fff052"))


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


static func _total_level_reward_text(target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(AchievementRewards.total_level_stamina(target))


static func _cumulative_medal_reward_text(target: int) -> String:
	return "Reward: %s" % _stamina_reward_text(AchievementRewards.cumulative_medal_stamina(target))


static func _tier_count_reward_text(tier: int) -> String:
	return "Reward: %s" % _stamina_reward_text(AchievementRewards.tier_count_stamina(tier))
