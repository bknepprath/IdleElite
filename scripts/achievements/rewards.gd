class_name AchievementRewards

const TOTAL_LEVEL_ART := "res://assets/content/achievements/achievement-total-level.png"
const CRIT_ART := "res://assets/content/achievements/achievement-crit.png"
const CREDIT_ART := "res://assets/content/achievements/achievement-credit.png"
const CUMULATIVE_MEDALS_ART := "res://assets/content/achievements/achievement-cumulative-medals.png"

const TOTAL_LEVEL_TARGETS := [25, 50, 100, 150, 250, 375, 495]
const TIER_COUNT_STEP := 5


static func total_level_stamina(target: int) -> int:
	if target >= 250:
		return 4
	if target >= 100:
		return 3
	if target >= 50:
		return 2
	return 1


static func cumulative_medal_stamina(target: int) -> int:
	if target >= 500:
		return 5
	if target >= 100:
		return 3
	if target >= 25:
		return 2
	return 1


static func tier_count_target(tier: int) -> int:
	return maxi(1, tier) * TIER_COUNT_STEP


static func tier_count_stamina(tier: int) -> int:
	if tier >= 9:
		return 3
	if tier >= 5:
		return 2
	return 1
