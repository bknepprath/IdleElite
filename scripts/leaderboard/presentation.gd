class_name LeaderboardPresentation

const GameFormatting = preload("res://scripts/core/formatting.gd")


static func format_score(
	valid_category_id: String,
	score: int,
	skill_level: int,
	total_xp: int,
	total_level_category_id: String,
	medals_category_id: String,
	elite_category_id: String,
	skill_prefix: String,
	skill_level_from_total_xp: Callable
) -> String:
	if valid_category_id == total_level_category_id:
		if total_xp > 0:
			return "Lv %s  |  %s XP" % [score, GameFormatting.compact_number(float(total_xp), 4)]
		return "Lv %s" % score
	if valid_category_id == medals_category_id or valid_category_id == elite_category_id:
		return "%s medals" % score
	if valid_category_id.begins_with(skill_prefix):
		var level := skill_level if skill_level > 0 else int(skill_level_from_total_xp.call(score))
		return "Lv %s  |  %s XP" % [level, GameFormatting.compact_number(float(score), 4)]
	return "%s XP" % GameFormatting.compact_number(float(score), 4)


static func player_rank_text(score: int, rows: Array, top_count: int) -> String:
	if score <= 0:
		return "unranked"
	var rank := 1
	for row in rows:
		if int((row as Dictionary).get("score", 0)) > score:
			rank += 1
	if rank > top_count:
		return "#%s+" % top_count
	return "#%s" % rank


static func submit_status_title(
	god_mode_save_tainted: bool,
	firebase_enabled: bool,
	profile_claim_valid: bool,
	auth_ready: bool,
	submit_in_flight: bool,
	last_submit_unix: int,
	submit_ready: bool
) -> String:
	if god_mode_save_tainted:
		return "Test save"
	if not firebase_enabled:
		return "Rankings offline"
	if not profile_claim_valid:
		return "Choose Username"
	if not auth_ready:
		return "Scores ready"
	if submit_in_flight:
		return "Updating..."
	if last_submit_unix <= 0:
		return "Scores ready"
	if submit_ready:
		return "Scores ready"
	return "Scores saved"


static func submit_status_detail(
	god_mode_save_tainted: bool,
	firebase_enabled: bool,
	profile_claim_valid: bool,
	retry_wait: int,
	auth_in_flight: bool,
	auth_ready: bool,
	submit_in_flight: bool,
	simple_status: String,
	last_submit_unix: int,
	queued_score: int,
	category_pending: bool,
	submit_ready: bool
) -> String:
	if god_mode_save_tainted:
		return "Rankings are hidden for this test save."
	if not firebase_enabled:
		return "Online rankings are not available."
	if not profile_claim_valid:
		return "Save a name to join rankings."
	if retry_wait > 0:
		return "Will try again soon."
	if auth_in_flight and not auth_ready:
		return "Connecting..."
	if not auth_ready:
		return "Scores update automatically."
	if submit_in_flight:
		return "Updating rankings..."
	if not simple_status.is_empty():
		return simple_status
	if last_submit_unix <= 0:
		return "Scores update automatically."
	if queued_score <= 0 and not category_pending:
		return "Your score is up to date."
	if submit_ready:
		return "New score ready."
	return "New score saved."


static func simple_status_message(raw_status: String) -> String:
	var status := raw_status.strip_edges()
	if status.is_empty() or status == "Leaderboard loaded.":
		return ""
	if status == "Leaderboard published." or status == "Leaderboard name saved.":
		return "Scores saved."
	if status.findn("failed") >= 0 or status.findn("http") >= 0 or status.findn("denied") >= 0 or status.findn("retry") >= 0:
		return "Will try again soon."
	if status.findn("loading") >= 0 or status.findn("creating") >= 0 or status.findn("refreshing") >= 0 or status.findn("checking") >= 0:
		return "Connecting..."
	return ""


static func empty_state_detail_text(raw_status: String) -> String:
	var fallback := "Scores appear here after the first update."
	var status := raw_status.strip_edges()
	if status.is_empty() or status == "Leaderboard loaded.":
		return fallback
	if status.begins_with("Leaderboard read"):
		return status
	return fallback
