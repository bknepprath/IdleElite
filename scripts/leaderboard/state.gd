class_name LeaderboardState

const LeaderboardProfile = preload("res://scripts/leaderboard/profile.gd")
const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

const SUBMIT_INTERVAL_SECONDS := 15 * 60
const REPAIR_PUBLISH_VERSION := 1
const TOP_COUNT := 50
const CATEGORY_TOTAL_LEVEL := "total_level"
const CATEGORY_TOTAL_XP_COMPAT := "total_xp"
const CATEGORY_MEDALS := "medals_earned"
const CATEGORY_ELITE_HEAVENLY := "elite_heavenly"
const CATEGORY_SKILL_PREFIX := "skill_xp:"

var host
var category_id := ""
var rows_by_category := {}
var fetch_unix_by_category := {}
var fetch_retry_unix_by_category := {}
var fetch_in_flight := false
var fetch_category_id := ""
var total_xp_fetch_in_flight := false
var pending_total_rows := []
var process_seconds := 0.0
var status_message := ""
var last_submitted_score := 0
var last_submitted_total_xp := 0
var last_submitted_scores_by_category := {}
var last_submit_unix := 0
var repair_publish_version := 0
var pending_score_updates := {}
var pending_repair_publish_version := 0
var last_submit_payload_categories := []


func _init(host_ref = null) -> void:
	host = host_ref
	if host != null:
		category_id = CATEGORY_TOTAL_LEVEL


func total_level_score_ceiling() -> int:
	return maxi(99, host.skills.size() * 99)


func total_level_score_looks_legacy_xp(score: int) -> bool:
	return score > total_level_score_ceiling()


func score() -> int:
	var total := 0
	for skill_id in host.skills.keys():
		total += int(host.skills.get(skill_id, {}).get("xp", 0))
	for key in host.mastery.keys():
		total += int(round(float(host.mastery.get(key, {}).get("xp", 0)) * 0.25))
	return maxi(0, total)


func categories() -> Array:
	var category_defs := [
		{"id": CATEGORY_TOTAL_LEVEL, "label": "Total"}
	]
	for raw_def in host.skill_defs:
		var skill := raw_def as Dictionary
		var skill_id := str(skill.get("id", ""))
		if skill_id.is_empty():
			continue
		category_defs.append({"id": CATEGORY_SKILL_PREFIX + skill_id, "label": SkillState.skill_name(host.skill_defs, skill_id)})
	category_defs.append({"id": CATEGORY_MEDALS, "label": "Medals"})
	category_defs.append({"id": CATEGORY_ELITE_HEAVENLY, "label": "Elite Heavenly"})
	return category_defs


func valid_category_id(category_id: String) -> String:
	for category in categories():
		if str((category as Dictionary).get("id", "")) == category_id:
			return category_id
	return CATEGORY_TOTAL_LEVEL


func selected_category_index() -> int:
	var valid_id := valid_category_id(category_id)
	var category_defs := categories()
	for i in range(category_defs.size()):
		if str((category_defs[i] as Dictionary).get("id", "")) == valid_id:
			return i
	return 0


func select_category_index(index: int) -> String:
	var category_defs := categories()
	if index < 0 or index >= category_defs.size():
		return ""
	var category_id := valid_category_id(str((category_defs[index] as Dictionary).get("id", "")))
	if self.category_id == category_id:
		return ""
	self.category_id = category_id
	return category_id


func category_label(category_id: String) -> String:
	var valid_id := valid_category_id(category_id)
	for category in categories():
		var category_def := category as Dictionary
		if str(category_def.get("id", "")) == valid_id:
			return str(category_def.get("label", valid_id))
	return "Total"


func score_for_category(category_id: String) -> int:
	var valid_id := valid_category_id(category_id)
	if valid_id == CATEGORY_TOTAL_LEVEL:
		return SkillState.global_level(host.skills)
	if valid_id == CATEGORY_MEDALS:
		return int(AchievementState.all_medal_counts(host).get("earned", 0))
	if valid_id == CATEGORY_ELITE_HEAVENLY:
		var tiers: Array = AchievementState.all_medal_tier_counts(host)
		if tiers.size() >= host.MASTERY_MAX_LEVEL:
			return int(tiers[host.MASTERY_MAX_LEVEL - 1])
		return 0
	if valid_id.begins_with(CATEGORY_SKILL_PREFIX):
		var skill_id := valid_id.substr(CATEGORY_SKILL_PREFIX.length())
		return int(host.skills.get(skill_id, {}).get("xp", 0))
	return SkillState.global_level(host.skills)


func skill_level_for_category(category_id: String) -> int:
	var valid_id := valid_category_id(category_id)
	if not valid_id.begins_with(CATEGORY_SKILL_PREFIX):
		return 0
	var skill_id := valid_id.substr(CATEGORY_SKILL_PREFIX.length())
	return SkillState.host_skill_level(host, skill_id)


func total_xp_for_category(category_id: String) -> int:
	var valid_id := valid_category_id(category_id)
	if valid_id == CATEGORY_TOTAL_LEVEL:
		return score()
	return 0


func skill_level_from_total_xp(total_xp: int) -> int:
	var level := 1
	var xp_total := maxi(0, total_xp)
	while level < 99 and xp_total >= SkillState.xp_for_level(level + 1):
		level += 1
	return level


func queued_score() -> int:
	if host.god_mode_save_tainted:
		return 0
	return maxi(0, score() - last_submitted_score)


func has_pending_category_score() -> bool:
	for raw_category in categories():
		var category := raw_category as Dictionary
		var category_id := valid_category_id(str(category.get("id", "")))
		if category_id.is_empty():
			continue
		var category_score := maxi(0, score_for_category(category_id))
		var last_score := int(last_submitted_scores_by_category.get(category_id, 0))
		if category_score > 0 and category_score > last_score:
			return true
		if category_id == CATEGORY_TOTAL_LEVEL and score() > last_submitted_total_xp:
			return true
	return false


func repair_publish_due() -> bool:
	if repair_publish_version >= REPAIR_PUBLISH_VERSION:
		return false
	if not LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS):
		return false
	for raw_category in categories():
		var category := raw_category as Dictionary
		var category_id := valid_category_id(str(category.get("id", "")))
		if category_id.is_empty():
			continue
		if score_for_category(category_id) > 0:
			return true
	return false


func next_submit_seconds() -> int:
	if last_submit_unix <= 0:
		return 0
	var elapsed: int = host._unix_now() - last_submit_unix
	return maxi(0, SUBMIT_INTERVAL_SECONDS - elapsed)


func submit_ready() -> bool:
	if host.god_mode_save_tainted:
		return false
	return LeaderboardProfile.profile_claim_valid(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS) and (has_pending_category_score() or repair_publish_due()) and next_submit_seconds() <= 0


func rows() -> Array:
	return rows_for_category(category_id)


func rows_for_category(category_id: String) -> Array:
	var valid_id := valid_category_id(category_id)
	if host._online_runtime()._leaderboard_firebase_enabled():
		var cached = rows_by_category.get(valid_id, null)
		if typeof(cached) == TYPE_ARRAY:
			return cached as Array
	return []


func last_submitted_scores_for_save() -> Dictionary:
	var normalized := normalized_last_submitted_scores(last_submitted_scores_by_category)
	if total_level_score_looks_legacy_xp(int(normalized.get(CATEGORY_TOTAL_LEVEL, 0))):
		normalized[CATEGORY_TOTAL_LEVEL] = 0
	return normalized


func reset_submission_metadata() -> void:
	last_submitted_score = 0
	last_submitted_total_xp = 0
	last_submitted_scores_by_category.clear()
	last_submit_unix = 0
	repair_publish_version = 0
	clear_pending_submit()


func clear_pending_submit() -> void:
	pending_score_updates.clear()
	pending_repair_publish_version = 0
	last_submit_payload_categories.clear()


func restore_submission_metadata_from_save(data: Dictionary) -> void:
	last_submitted_score = maxi(0, int(data.get("leaderboard_last_submitted_score", 0)))
	last_submitted_total_xp = maxi(0, int(data.get("leaderboard_last_submitted_total_xp", last_submitted_score)))
	last_submitted_scores_by_category = normalized_last_submitted_scores(data.get("leaderboard_last_submitted_scores_by_category", {}))
	if total_level_score_looks_legacy_xp(int(last_submitted_scores_by_category.get(CATEGORY_TOTAL_LEVEL, 0))):
		last_submitted_scores_by_category[CATEGORY_TOTAL_LEVEL] = 0
	last_submit_unix = maxi(0, int(data.get("leaderboard_last_submit_unix", 0)))
	repair_publish_version = clampi(int(data.get("leaderboard_repair_publish_version", 0)), 0, REPAIR_PUBLISH_VERSION)


func normalized_last_submitted_scores(loaded_scores: Variant) -> Dictionary:
	return SaveStateNormalizers.normalized_leaderboard_category_values(loaded_scores, Callable(self, "valid_category_id"))


func fetch_retry_unix_by_category_for_save() -> Dictionary:
	return normalized_fetch_retry_unix_by_category(fetch_retry_unix_by_category)


func restore_fetch_metadata_from_save(data: Dictionary) -> void:
	# Successful rows are not saved, so successful fetch timestamps intentionally reset on launch.
	fetch_unix_by_category.clear()
	restore_fetch_retry_unix_by_category_from_save(data.get("leaderboard_fetch_retry_unix_by_category", {}))


func restore_fetch_retry_unix_by_category_from_save(loaded_retry_unix: Variant) -> void:
	fetch_retry_unix_by_category = normalized_fetch_retry_unix_by_category(loaded_retry_unix)


func normalized_fetch_retry_unix_by_category(loaded_retry_unix: Variant) -> Dictionary:
	return SaveStateNormalizers.normalized_leaderboard_category_values(loaded_retry_unix, Callable(self, "valid_category_id"))
