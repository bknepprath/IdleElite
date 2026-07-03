class_name AchievementState

const AchievementMilestones = preload("res://scripts/achievements/milestones.gd")
const MedalBuffs = preload("res://scripts/progression/medal_buffs.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")

const ACTIVITY_CRIT_ACHIEVEMENT_CHANCE_MULT := 0.01


static func skill_medal_counts(host: Node, skill_id: String) -> Dictionary:
	var actions: Array = mastery_actions_for_skill(host, skill_id)
	var tiers := []
	for _i in range(host.MASTERY_MAX_LEVEL):
		tiers.append(0)
	var cumulative := 0
	for action in actions:
		var level: int = MasteryState.level(host.mastery, host._action_key(skill_id, str((action as Dictionary)["id"])))
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
		if host._is_passive_action(action_data):
			continue
		actions.append(action_data)
	return actions


static func milestones(host: Node, include_log_only := true) -> Array:
	return AchievementMilestones.build_all(milestone_context(host), include_log_only)


static func milestone_context(host: Node, include_action_records := true) -> Dictionary:
	return {
		"total_counts": all_medal_counts(host),
		"total_level": host._global_level(),
		"max_total_level": host.skill_defs.size() * 99,
		"action_medal_records": action_medal_records(host) if include_action_records else [],
		"tier_counts": all_medal_tier_counts(host),
		"total_activity_count": total_activity_count(host),
		"activity_crit_seen": host.activity_crit_seen,
		"activity_mega_crit_seen": host.activity_mega_crit_seen,
		"crit_reward_text": "Reward: +%s%% crit chance" % GameFormatting.percent_points(ACTIVITY_CRIT_ACHIEVEMENT_CHANCE_MULT * 100.0),
		"crit_reward_amount": ACTIVITY_CRIT_ACHIEVEMENT_CHANCE_MULT,
		"max_mastery_level": host.MASTERY_MAX_LEVEL,
		"medal_names": host.MASTERY_MEDAL_NAMES,
		"medal_accents": medal_accent_hexes(host)
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
				"skill_name": host._skill_name(skill_id),
				"current_level": current_level,
				"art": str(action.get("art", ""))
			})
	return records


static func medal_accent_hexes(host: Node) -> Array:
	var accents := []
	for accent in host.MASTERY_MEDAL_ACCENTS:
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
	return AchievementMilestones.build_visible_fast(context)


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
	var cache_key := "%s|%s|%s" % [host.stat_cache_version, stat, skill_id]
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
	for buff in host.GLOBAL_MEDAL_BUFFS:
		if str((buff as Dictionary).get("stat", "")) == stat and global_medal_tier_unlocked(host, int((buff as Dictionary).get("level", 0))):
			total += float((buff as Dictionary).get("amount", 0.0))
	return total


static func new_global_medal_buff_messages(host: Node, old_level: int, new_level: int, tiers_unlocked_before: Dictionary) -> Array:
	var messages := []
	for tier in range(old_level + 1, new_level + 1):
		if tier >= 1 and tier <= host.MASTERY_MAX_LEVEL and not bool(tiers_unlocked_before.get(tier, false)):
			messages.append("%s global buff unlocked: %s." % [host.MASTERY_MEDAL_NAMES[tier - 1], global_medal_tier_bonus_text(host, tier)])
	return messages


static func global_medal_tier_bonus_text(host: Node, level: int) -> String:
	for buff in host.GLOBAL_MEDAL_BUFFS:
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


static func activity_medal_buff_total(host: Node, skill_id: String, action: Dictionary, effect: String) -> float:
	var action_id := str(action.get("id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return 0.0
	var event_level_key := str(host._activity_data_catalog().activity_action_display_sort_level(action)) if host._is_event_action(action) else "0"
	var cache_key := "%s|%s|%s|%s|%s" % [host.stat_cache_version, skill_id, action_id, effect, event_level_key]
	if host.activity_medal_buff_total_cache.has(cache_key):
		return float(host.activity_medal_buff_total_cache[cache_key])
	var total := 0.0
	for raw_contribution in activity_medal_buff_contributions(host, skill_id, action, effect):
		var contribution := raw_contribution as Dictionary
		total += float(contribution.get("amount", 0.0))
	host.activity_medal_buff_total_cache[cache_key] = total
	return total


static func activity_medal_buff_contributions(host: Node, skill_id: String, action: Dictionary, effect: String) -> Array:
	var action_id := str(action.get("id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return []
	if host._is_passive_action(action):
		return []
	var is_event_target: bool = host._is_event_action(action)
	var playable_actions := playable_actions_for_medal_buffs_including_event(host, skill_id, action) if is_event_target else playable_actions_for_medal_buffs(host, skill_id)
	var target_index := playable_action_index(playable_actions, action_id) if is_event_target else playable_action_index_cached(host, skill_id, playable_actions, action_id)
	return MedalBuffs.contributions(
		playable_actions,
		target_index,
		effect,
		func(source_action_id: String) -> int: return MasteryState.level(host.mastery, host._action_key(skill_id, source_action_id)),
		host.MASTERY_MAX_LEVEL
	)


static func playable_actions_for_medal_buffs(host: Node, skill_id: String) -> Array:
	if host.playable_medal_buff_actions_cache.has(skill_id):
		return host.playable_medal_buff_actions_cache[skill_id] as Array
	var playable_actions := []
	for raw_action in host.actions_by_skill.get(skill_id, []):
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var action := raw_action as Dictionary
		if host._is_passive_action(action):
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
	playable_actions.sort_custom(func(left, right): return host._activity_data_catalog().activity_action_display_sort_less(left, right))
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
	var total := 0.0
	for raw_contribution in activity_medal_buff_contributions(host, skill_id, action, effect):
		var contribution := raw_contribution as Dictionary
		var amount := float(contribution.get("amount", 0.0))
		if amount <= 0.0:
			continue
		total += amount
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
	return own_medal_bonus + activity_medal_accuracy_bonus(host, skill_id, action)


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
