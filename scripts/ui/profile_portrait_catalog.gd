extends RefCounted

# Numeric IDs are shared by saves, chat, profiles and leaderboards. Replacing an
# entry updates existing owners too; retired artwork is not a separate choice.
const COUNT := 23
const FEATURED_IDS := [0, 20, 21, 22, 18]
const TEXTURES := {
	0: "res://assets/content/ui/profile-portraits/shark-bucket.png",
	18: "res://assets/content/ui/profile-portraits/brick-helmet-builder.png",
	20: "res://assets/content/ui/profile-portraits/cookie-jar-thief.png",
	21: "res://assets/content/ui/profile-portraits/wheelbarrow-champion.png",
	22: "res://assets/content/ui/profile-portraits/shrub-sunglasses.png",
}

static func picker_order() -> Array[int]:
	var result: Array[int] = []
	result.assign(FEATURED_IDS)
	for index in range(COUNT):
		if not result.has(index):
			result.append(index)
	return result

static func has_colored_background(index: int) -> bool:
	return index >= 10 and index < 20 and not TEXTURES.has(index)
