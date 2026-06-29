class_name AchievementPresentation


static func skill_level_targets() -> Array:
	var targets := []
	for level in range(2, 100):
		targets.append(level)
	return targets


static func same_tier_medal_count(target: int) -> int:
	if target <= 1:
		return 1
	if target <= 10:
		return 3
	if target <= 25:
		return 5
	if target <= 50:
		return 7
	return 9


static func medal_cluster_positions(count: int) -> Array:
	if count <= 1:
		return [Vector2(89, 72)]
	if count <= 3:
		return [Vector2(48, 88), Vector2(94, 48), Vector2(140, 88)]
	if count <= 5:
		return [Vector2(42, 88), Vector2(70, 50), Vector2(112, 50), Vector2(140, 88), Vector2(91, 112)]
	if count <= 7:
		return [Vector2(34, 88), Vector2(58, 56), Vector2(92, 42), Vector2(126, 56), Vector2(150, 88), Vector2(68, 116), Vector2(116, 116)]
	if count <= 8:
		return [Vector2(28, 88), Vector2(50, 58), Vector2(78, 42), Vector2(110, 42), Vector2(138, 58), Vector2(160, 88), Vector2(68, 116), Vector2(120, 116)]
	return [Vector2(24, 88), Vector2(44, 62), Vector2(68, 44), Vector2(94, 38), Vector2(120, 44), Vector2(144, 62), Vector2(164, 88), Vector2(58, 116), Vector2(94, 122), Vector2(130, 116)]


static func progress_pct(achievement: Dictionary) -> float:
	var target := maxi(1, int(achievement.get("target", 1)))
	var current := clampi(int(achievement.get("current", 0)), 0, target)
	return clampf(float(current) / float(target) * 100.0, 0.0, 100.0)
