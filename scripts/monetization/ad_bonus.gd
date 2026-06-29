class_name AdBonus

const GameFormatting = preload("res://scripts/core/formatting.gd")


static func xp_mult(seconds_remaining: float, multiplier: float) -> float:
	return multiplier if seconds_remaining > 0.0 else 0.0


static func speed_mult(seconds_remaining: float, multiplier: float) -> float:
	return multiplier if seconds_remaining > 0.0 else 0.0


static func status_text(seconds_remaining: float) -> String:
	if seconds_remaining <= 0.0:
		return "No bonus active."
	return "Bonus remaining: %s" % GameFormatting.duration(seconds_remaining)


static func tick(seconds_remaining: float, delta: float) -> float:
	if seconds_remaining <= 0.0:
		return 0.0
	return maxf(0.0, seconds_remaining - delta)


static func grant_seconds(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> float:
	return minf(max_seconds, seconds_remaining + bonus_seconds)


static func stack_max_count(max_seconds: float, bonus_seconds: float) -> int:
	return maxi(1, int(ceil(max_seconds / maxf(1.0, bonus_seconds))))


static func stack_units(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> float:
	return clampf(seconds_remaining / maxf(1.0, bonus_seconds), 0.0, float(stack_max_count(max_seconds, bonus_seconds)))


static func stack_active_count(seconds_remaining: float, bonus_seconds: float, max_seconds: float) -> int:
	var units := stack_units(seconds_remaining, bonus_seconds, max_seconds)
	if units <= 0.0:
		return 0
	return clampi(int(ceil(units - 0.001)), 0, stack_max_count(max_seconds, bonus_seconds))
