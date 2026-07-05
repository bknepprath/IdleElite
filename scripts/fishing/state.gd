class_name FishingState
extends RefCounted

const AchievementState = preload("res://scripts/achievements/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")

const AREA_FLUID_KINDS := ["water", "sewer", "lava", "space", "deep_water", "storm", "ice"]
const FISHING_NET_FILL_MIN := 1
const FISHING_NET_FILL_MAX := 6
const FISHING_NET_SUCCESS_RATE_MULT := 0.25
const FISHING_NET_FILL_MASTERY_MULT := 0.1
const FISHING_NET_OFFER_UNLOCK_LEVEL := 3
const FISHING_ROD_OFFER_UNLOCK_LEVEL := 18
const FISHING_ROD_OFFER_COST := 1000
const FISHING_REINFORCED_ROD_UNLOCK_LEVEL := 45
const FISHING_REINFORCED_ROD_COST := 50000
const FISHING_STAR_ROD_UNLOCK_LEVEL := 85
const FISHING_STAR_ROD_COST := 250000
const FISHING_BOAT_OFFER_UNLOCK_LEVEL := 50
const FISHING_BOAT_BUILD_REQUIRED_LEVEL := 30
const FISHING_BOAT_OFFER_COST := 1000
const FISHING_MIRROR_OFFER_UNLOCK_LEVEL := 90
const FISHING_MIRROR_OFFER_COST := 1000000
const FISHING_NET_HAUL_THRESHOLD := 10
const FISHING_NET_HAUL_VISUAL_SECONDS := 0.74
const FISHING_NET_COLLECT_LAYOUT_DELAY_SECONDS := 3.62
const FISHING_BOAT_HAUL_THRESHOLD := 200
const FISHING_BOAT_HAUL_VISUAL_SECONDS := 0.55
const FISHING_ROD_HAUL_VISUAL_SECONDS := 0.48
const FISHING_NET_AREA_XP := {
	"beach": 1,
	"pier": 1,
	"river": 2,
	"sewers": 3,
	"winter_lake": 3,
	"reef": 3,
	"sea": 4,
	"stormy_sea": 4,
	"deep_sea": 5,
}
const FISHING_AREA_ID_ALIASES := {
	"lake": "winter_lake",
	"boat": "sea",
	"storm": "stormy_sea",
	"deep": "deep_sea",
}
const FISHING_LOCATION_THUMBNAIL_SHEET := "res://assets/content/fishing/locations/fishing-location-thumbnails-sheet.png"
const FISHING_TOOL_DEFS := [
	{"id": "hands", "name": "Bare hands", "archetype": "novice", "unlock": "starter", "art": "res://assets/content/fishing/tools/tool-bare-hands.png"},
	{"id": "net", "name": "Drag net", "archetype": "volume", "unlock": "Fishing Lv 3", "art": "res://assets/content/fishing/tools/net-player.png"},
	{"id": "line", "name": "Bamboo rod", "archetype": "steady", "unlock": "Fishing Lv 14", "art": "res://assets/content/fishing/tools/tool-bamboo-rod.png"},
	{"id": "reinforced_rod", "name": "Reinforced rod", "archetype": "steady", "unlock": "Fishing Lv 45", "art": "res://assets/content/fishing/tools/tool-bamboo-rod.png"},
	{"id": "star_rod", "name": "Star rod", "archetype": "steady", "unlock": "Fishing Lv 85", "art": "res://assets/content/fishing/tools/tool-bamboo-rod.png"},
	{"id": "boat", "name": "Boat", "archetype": "steady", "unlock": "Building at Fishing Lv 50", "art": "res://assets/content/fishing/tools/tool-boat.png"},
	{"id": "mirror", "name": "Reflection mirror", "archetype": "risk", "unlock": "Space Reflection", "art": "res://assets/content/fishing/tools/reflection-net.png"},
]
const FISHING_LOCATION_DEFS := {
	"beach": [
		{"id": "shallows", "name": "Shallows", "unlock": 1, "fish": "Minnow", "bg": "res://assets/content/fishing/backgrounds/00-tide-pool-shallows.png"},
		{"id": "rocky", "name": "Rocks", "unlock": 4, "fish": "Crab", "bg": "res://assets/content/fishing/backgrounds/03-crab-pier.png"},
	],
	"pier": [
		{"id": "dock-cup", "name": "Dock Edge", "unlock": 7, "fish": "Minnow", "bg": "res://assets/content/fishing/backgrounds/01-pond-dock.png"},
		{"id": "piling-line", "name": "Piling Line", "unlock": 11, "fish": "Panfish", "bg": "res://assets/content/fishing/backgrounds/01-pond-dock.png"},
	],
	"river": [
		{"id": "bend", "name": "River Bend", "unlock": 14, "fish": "Trout", "bg": "res://assets/content/fishing/backgrounds/02-river-bend.png"},
		{"id": "rapids", "name": "Rapids", "unlock": 18, "fish": "Salmon", "bg": "res://assets/content/fishing/backgrounds/02-river-bend.png"},
	],
	"sewers": [
		{"id": "drain-gate", "name": "Drain Gate", "unlock": 22, "fish": "Eel", "bg": "res://assets/content/fishing/backgrounds/sewer-pipe-outlet.png"},
		{"id": "tunnel-pool", "name": "Tunnel Pool", "unlock": 26, "fish": "Eel", "bg": "res://assets/content/fishing/backgrounds/sewer-pipe-outlet.png"},
	],
	"winter_lake": [
		{"id": "ice-hole", "name": "Ice Hole", "unlock": 34, "fish": "Snowfish", "bg": "res://assets/content/fishing/backgrounds/04-frozen-lake.png"},
	],
	"reef": [
		{"id": "pot", "name": "Reef Pot", "unlock": 30, "fish": "Crab", "bg": "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"},
		{"id": "cage", "name": "Reef Cage", "unlock": 46, "fish": "Lobster", "bg": "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"},
		{"id": "night-reef", "name": "Night Reef", "unlock": 58, "fish": "Reef Fish", "bg": "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"},
		{"id": "pearl-bed", "name": "Pearl Bed", "unlock": 74, "fish": "Pearl Oyster", "bg": "res://assets/content/fishing/backgrounds/05-coral-reef-shallows.png"},
	],
	"sea": [
		{"id": "rowboat", "name": "Rowboat", "unlock": 50, "fish": "Bass", "bg": "res://assets/content/fishing/backgrounds/07-rowboat-offshore.png"},
		{"id": "open-water", "name": "Open Water", "unlock": 52, "fish": "Tuna", "bg": "res://assets/content/fishing/backgrounds/07-rowboat-offshore.png"},
		{"id": "chum-line", "name": "Chum Line", "unlock": 70, "fish": "Reef Fish", "bg": "res://assets/content/fishing/backgrounds/07-rowboat-offshore.png"},
	],
	"stormy_sea": [
		{"id": "ripple", "name": "Storm Ripple", "unlock": 64, "fish": "Shark", "bg": "res://assets/content/fishing/backgrounds/10-storm-ocean.png"},
		{"id": "storm-line", "name": "Storm Line", "unlock": 78, "fish": "Storm Ray", "bg": "res://assets/content/fishing/backgrounds/10-storm-ocean.png"},
	],
	"deep_sea": [
		{"id": "wreck-drop", "name": "Wreck Drop", "unlock": 82, "fish": "Octopus", "bg": "res://assets/content/fishing/backgrounds/09-deep-sea-abyss.png"},
		{"id": "abyss", "name": "Abyss", "unlock": 86, "fish": "Shark", "bg": "res://assets/content/fishing/backgrounds/09-deep-sea-abyss.png"},
		{"id": "trench", "name": "Deep Trench", "unlock": 88, "fish": "Octopus", "bg": "res://assets/content/fishing/backgrounds/09-deep-sea-abyss.png"},
	],
	"space": [
		{"id": "starlight", "name": "Starlight", "unlock": 90, "fish": "Cosmic Starfish", "bg": "res://assets/content/fishing/backgrounds/11-cosmic-dream-sea.png"},
		{"id": "reflection", "name": "Reflection", "unlock": 95, "fish": "Cosmic Starfish", "bg": "res://assets/content/fishing/backgrounds/11-cosmic-dream-sea.png"},
	],
}
const FISHING_TOOL_LOCATION_ACTIONS := {
	"hands": {
		"beach.shallows": "beach-shallows",
		"beach.rocky": "beach-rocks",
		"pier.dock-cup": "pier-dock-edge",
		"pier.piling-line": "pier-piling-line",
		"river.bend": "river-bend",
		"river.rapids": "river-rapids",
		"sewers.drain-gate": "sewers-drain-gate",
		"sewers.tunnel-pool": "sewers-tunnel-pool",
		"winter_lake.ice-hole": "winter-lake-ice-hole",
		"reef.pot": "reef-pot",
		"reef.cage": "reef-cage",
		"reef.night-reef": "reef-night-reef",
		"reef.pearl-bed": "reef-pearl-bed",
		"sea.rowboat": "sea-rowboat",
		"sea.open-water": "sea-open-water",
		"sea.chum-line": "sea-chum-line",
		"stormy_sea.ripple": "stormy-sea-ripple",
		"stormy_sea.storm-line": "stormy-sea-storm-line",
		"deep_sea.wreck-drop": "deep-sea-wreck-drop",
		"deep_sea.abyss": "deep-sea-abyss",
		"deep_sea.trench": "deep-sea-trench",
		"space.starlight": "space-starlight",
		"space.reflection": "space-reflection",
	},
	"net": {
		"beach.shallows": "beach-shallows",
		"beach.rocky": "beach-rocks",
		"pier.dock-cup": "pier-dock-edge",
		"pier.piling-line": "pier-piling-line",
		"river.bend": "river-bend",
		"river.rapids": "river-rapids",
		"sewers.drain-gate": "sewers-drain-gate",
		"sewers.tunnel-pool": "sewers-tunnel-pool",
		"winter_lake.ice-hole": "winter-lake-ice-hole",
		"reef.pot": "reef-pot",
		"reef.cage": "reef-cage",
		"reef.night-reef": "reef-night-reef",
		"reef.pearl-bed": "reef-pearl-bed",
		"sea.rowboat": "sea-rowboat",
		"sea.open-water": "sea-open-water",
		"sea.chum-line": "sea-chum-line",
		"stormy_sea.ripple": "stormy-sea-ripple",
		"stormy_sea.storm-line": "stormy-sea-storm-line",
		"deep_sea.wreck-drop": "deep-sea-wreck-drop",
		"deep_sea.abyss": "deep-sea-abyss",
		"deep_sea.trench": "deep-sea-trench",
		"space.starlight": "space-starlight",
		"space.reflection": "space-reflection",
	},
	"line": {
		"beach.shallows": "beach-shallows",
		"beach.rocky": "beach-rocks",
		"pier.dock-cup": "pier-dock-edge",
		"pier.piling-line": "pier-piling-line",
		"river.bend": "river-bend",
		"river.rapids": "river-rapids",
		"sewers.drain-gate": "sewers-drain-gate",
		"sewers.tunnel-pool": "sewers-tunnel-pool",
		"winter_lake.ice-hole": "winter-lake-ice-hole",
		"reef.pot": "reef-pot",
		"reef.cage": "reef-cage",
		"reef.night-reef": "reef-night-reef",
		"reef.pearl-bed": "reef-pearl-bed",
		"sea.rowboat": "sea-rowboat",
		"sea.open-water": "sea-open-water",
		"sea.chum-line": "sea-chum-line",
		"stormy_sea.ripple": "stormy-sea-ripple",
		"stormy_sea.storm-line": "stormy-sea-storm-line",
		"deep_sea.wreck-drop": "deep-sea-wreck-drop",
		"deep_sea.abyss": "deep-sea-abyss",
		"deep_sea.trench": "deep-sea-trench",
		"space.starlight": "space-starlight",
		"space.reflection": "space-reflection",
	},
}
const FISHING_BOAT_FILL_MIN := 1
const FISHING_BOAT_FILL_MAX := 30
const FISHING_HANDS_TIME_MULT := 1.0
const FISHING_ROD_TIME_MULT := 1.25
const FISHING_REINFORCED_ROD_TIME_MULT := 1.2
const FISHING_STAR_ROD_TIME_MULT := 1.1
const FISHING_ROD_XP_MULT := 2.0
const FISHING_REINFORCED_ROD_XP_MULT := 2.5
const FISHING_STAR_ROD_XP_MULT := 3.0
const FISHING_REFLECT_NET_XP_MULT := 4.0
const FISHING_ACTION_CATCH_TEXTURE_PATHS := {
	"beach-shallows": "res://assets/content/fishing/catch-icons/00-minnow-cutout.png",
	"beach-rocks": "res://assets/content/fishing/catch-icons/02-crab-cutout.png",
	"reef-pot": "res://assets/content/fishing/catch-icons/02-crab-cutout.png",
	"stormy-sea-ripple": "res://assets/content/fishing/catch-icons/14-shark-cutout.png",
	"river-bend": "res://assets/content/fishing/catch-icons/03-trout-cutout.png",
	"river-rapids": "res://assets/content/fishing/catch-icons/05-salmon-cutout.png",
	"sewers-drain-gate": "res://assets/content/fishing/catch-icons/06-eel-cutout.png",
	"sewers-tunnel-pool": "res://assets/content/fishing/catch-icons/06-eel-cutout.png",
	"winter-lake-ice-hole": "res://assets/content/fishing/catch-icons/08-snowfish-cutout.png",
	"reef-cage": "res://assets/content/fishing/catch-icons/07-lobster-cutout.png",
	"reef-night-reef": "res://assets/content/fishing/catch-icons/10-reef-fish-cutout.png",
	"reef-pearl-bed": "res://assets/content/fishing/catch-icons/09-pearl-oyster-cutout.png",
	"sea-rowboat": "res://assets/content/fishing/catch-icons/04-bass-cutout.png",
	"sea-open-water": "res://assets/content/fishing/catch-icons/12-tuna-cutout.png",
	"sea-chum-line": "res://assets/content/fishing/catch-icons/10-reef-fish-cutout.png",
	"stormy-sea-storm-line": "res://assets/content/fishing/catch-icons/19-storm-ray-cutout.png",
	"deep-sea-wreck-drop": "res://assets/content/fishing/catch-icons/11-octopus-cutout.png",
	"deep-sea-abyss": "res://assets/content/fishing/catch-icons/14-shark-cutout.png",
	"deep-sea-trench": "res://assets/content/fishing/catch-icons/11-octopus-cutout.png",
	"space-reflection": "res://assets/content/fishing/catch-icons/23-cosmic-starfish-cutout.png",
	"space-starlight": "res://assets/content/fishing/catch-icons/23-cosmic-starfish-cutout.png",
}
const FISHING_ACTION_FOOD_VALUES := {
	"beach-shallows": 0.3,
	"beach-rocks": 1.0,
	"reef-cage": 1.25,
	"sea-open-water": 1.5,
	"stormy-sea-storm-line": 2.0,
	"deep-sea-abyss": 2.5,
	"deep-sea-trench": 2.0,
	"space-starlight": 1.0,
	"space-reflection": 1.0,
}
const FISHING_CATCH_TEXTURE_PATHS := [
	"res://assets/content/fishing/catch-icons/00-minnow-cutout.png",
	"res://assets/content/fishing/catch-icons/01-clam-cutout.png",
	"res://assets/content/fishing/catch-icons/02-crab-cutout.png",
	"res://assets/content/fishing/catch-icons/03-trout-cutout.png",
	"res://assets/content/fishing/catch-icons/04-bass-cutout.png",
	"res://assets/content/fishing/catch-icons/05-salmon-cutout.png",
	"res://assets/content/fishing/catch-icons/06-eel-cutout.png",
	"res://assets/content/fishing/catch-icons/07-lobster-cutout.png",
	"res://assets/content/fishing/catch-icons/08-snowfish-cutout.png",
	"res://assets/content/fishing/catch-icons/09-pearl-oyster-cutout.png",
	"res://assets/content/fishing/catch-icons/10-reef-fish-cutout.png",
	"res://assets/content/fishing/catch-icons/11-octopus-cutout.png",
	"res://assets/content/fishing/catch-icons/12-tuna-cutout.png",
	"res://assets/content/fishing/catch-icons/13-swordfish-cutout.png",
	"res://assets/content/fishing/catch-icons/14-shark-cutout.png",
	"res://assets/content/fishing/catch-icons/15-lanternfish-cutout.png",
	"res://assets/content/fishing/catch-icons/16-abyss-anglerfish-cutout.png",
	"res://assets/content/fishing/catch-icons/17-jellyfish-cutout.png",
	"res://assets/content/fishing/catch-icons/18-lightning-eel-cutout.png",
	"res://assets/content/fishing/catch-icons/19-storm-ray-cutout.png",
	"res://assets/content/fishing/catch-icons/20-golden-koi-cutout.png",
	"res://assets/content/fishing/catch-icons/21-ancient-coelacanth-cutout.png",
	"res://assets/content/fishing/catch-icons/22-tiny-leviathan-trophy-cutout.png",
	"res://assets/content/fishing/catch-icons/23-cosmic-starfish-cutout.png",
]

var equipped_tool_id := "hands"
var fish_currency := 0.0
var fish_currency_ever_earned := false
var area_definitions: Array = []
var action_location_key_cache := {}
var action_thumbnail_path_cache := {}
var action_mastery_id_cache := {}
var active_tool_init_token := 0
var net_stored_fish := 0
var net_successes := 0
var net_stored_xp := 0
var net_stored_mastery := 0.0
var net_haul_visual_seconds := 0.0
var net_set_in_water := false
var boat_stored_fish := 0
var boat_successes := 0
var boat_stored_xp := 0
var boat_stored_mastery := 0.0
var boat_haul_visual_seconds := 0.0
var net_collected := false
var net_collect_pending := false
var rod_set_in_water := false
var rod_haul_visual_seconds := 0.0
var rod_collected := false
var reinforced_rod_collected := false
var star_rod_collected := false
var boat_built := false
var boat_set_in_water := false
var mirror_collected := false
var selected_locations := {}
var auto_eat_fish_enabled_by_skill := {}


func reset() -> void:
	equipped_tool_id = "hands"
	fish_currency = 0.0
	fish_currency_ever_earned = false
	action_location_key_cache.clear()
	action_thumbnail_path_cache.clear()
	action_mastery_id_cache.clear()
	active_tool_init_token = 0
	net_stored_fish = 0
	net_successes = 0
	net_stored_xp = 0
	net_stored_mastery = 0.0
	net_haul_visual_seconds = 0.0
	net_set_in_water = false
	net_collected = false
	net_collect_pending = false
	boat_stored_fish = 0
	boat_successes = 0
	boat_stored_xp = 0
	boat_stored_mastery = 0.0
	boat_haul_visual_seconds = 0.0
	boat_built = false
	boat_set_in_water = false
	rod_set_in_water = false
	rod_haul_visual_seconds = 0.0
	rod_collected = false
	reinforced_rod_collected = false
	star_rod_collected = false
	mirror_collected = false
	selected_locations.clear()
	auto_eat_fish_enabled_by_skill.clear()


func auto_eat_fish_enabled_for_skill(host, skill_id: String) -> bool:
	if skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
		return false
	return bool(auto_eat_fish_enabled_by_skill.get(skill_id, false))


func set_auto_eat_fish_enabled_for_skill(host, skill_id: String, enabled: bool) -> void:
	if skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
		return
	if enabled:
		auto_eat_fish_enabled_by_skill[skill_id] = true
	else:
		auto_eat_fish_enabled_by_skill.erase(skill_id)


func auto_eat_fish_enabled_by_skill_for_save(host) -> Dictionary:
	var enabled_by_skill := {}
	for raw_skill_id in auto_eat_fish_enabled_by_skill.keys():
		var skill_id := str(raw_skill_id)
		if auto_eat_fish_enabled_for_skill(host, skill_id):
			enabled_by_skill[skill_id] = true
	return enabled_by_skill


func restore_auto_eat_fish_enabled_from_save(host, data: Dictionary) -> void:
	auto_eat_fish_enabled_by_skill.clear()
	var raw_enabled_by_skill = data.get("auto_eat_fish_enabled_by_skill", null)
	if raw_enabled_by_skill is Dictionary:
		var enabled_by_skill := raw_enabled_by_skill as Dictionary
		for raw_skill_id in enabled_by_skill.keys():
			var skill_id := str(raw_skill_id)
			set_auto_eat_fish_enabled_for_skill(host, skill_id, bool(enabled_by_skill.get(raw_skill_id, false)))
		return
	if bool(data.get("auto_eat_fish_enabled", false)):
		for raw_skill_id in host.skills.keys():
			var skill_id := str(raw_skill_id)
			if not host._fishing_rework_active_for_skill(skill_id):
				set_auto_eat_fish_enabled_for_skill(host, skill_id, true)


func load_area_definitions_from_skill(host, skill: Dictionary, actions: Array) -> void:
	area_definitions.clear()
	var loaded_areas = skill.get("areas", [])
	if typeof(loaded_areas) != TYPE_ARRAY or loaded_areas.is_empty():
		push_error("Fishing skill has no areas array in activity-database.json.")
		return
	var methods_by_area := methods_grouped_by_area(host, actions)
	for raw_area in loaded_areas:
		if typeof(raw_area) != TYPE_DICTIONARY:
			continue
		var area_meta := parse_area_metadata(host, raw_area as Dictionary)
		if area_meta.is_empty():
			continue
		var area_id := str(area_meta.get("id", ""))
		var method_rows: Array = methods_by_area.get(area_id, [])
		if method_rows.is_empty():
			continue
		method_rows.sort_custom(Callable(self, "_sort_area_method_rows"))
		var methods: Array = []
		for row in method_rows:
			methods.append(str(row.get("id", "")))
		area_meta["methods"] = methods
		area_definitions.append(area_meta)
	if area_definitions.is_empty():
		push_error("Fishing areas failed to load from activity-database.json.")
		return
	for area_id in methods_by_area.keys():
		if area_metadata_loaded(str(area_id)):
			continue
		push_warning("Fishing action(s) use area '%s' but it is missing from fishing.areas." % area_id)


func area_metadata_loaded(area_id: String) -> bool:
	for raw_area in area_definitions:
		if str(raw_area.get("id", "")) == area_id:
			return true
	return false


func methods_grouped_by_area(host, actions: Array) -> Dictionary:
	var grouped := {}
	for raw_action in actions:
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var action := raw_action as Dictionary
		if str(action.get("kind", "activity")) == "passive_item_collect":
			continue
		if action_should_render_standalone(host, "fishing", action):
			continue
		var action_id := str(action.get("id", ""))
		var area_id: String = canonical_area_id(str(action.get("area", "")))
		if action_id.is_empty() or area_id.is_empty():
			continue
		if not grouped.has(area_id):
			grouped[area_id] = []
		(grouped[area_id] as Array).append({
			"id": action_id,
			"unlock": int(action.get("unlock", 1)),
			"tier": int(action.get("tier", 1)),
		})
	return grouped


func _sort_area_method_rows(a: Dictionary, b: Dictionary) -> bool:
	var unlock_a := int(a.get("unlock", 1))
	var unlock_b := int(b.get("unlock", 1))
	if unlock_a != unlock_b:
		return unlock_a < unlock_b
	return int(a.get("tier", 1)) < int(b.get("tier", 1))


func parse_area_metadata(host, raw_area: Dictionary) -> Dictionary:
	var area_id: String = canonical_area_id(str(raw_area.get("id", "")))
	if area_id.is_empty():
		push_warning("Skipping fishing area with no id.")
		return {}
	var fluid := str(raw_area.get("fluid", "water"))
	if fluid not in AREA_FLUID_KINDS:
		push_warning("Fishing area '%s' has unknown fluid '%s'; using water." % [area_id, fluid])
		fluid = "water"
	var bg_path: String = host.visual_texture_cache._res_path(str(raw_area.get("background", raw_area.get("bg", ""))))
	if bg_path.is_empty():
		push_warning("Skipping fishing area '%s' with no background." % area_id)
		return {}
	return {
		"id": area_id,
		"name": str(raw_area.get("name", area_id.capitalize())),
		"fluid": fluid,
		"bg": bg_path,
	}


func area_key(skill_id: String, area_id: String) -> String:
	return "%s:area-%s" % [skill_id, area_id]


func area_module_key(skill_id: String, area_def: Dictionary) -> String:
	var area_id := str(area_def.get("id", ""))
	var module_index := int(area_def.get("module_index", -1))
	if module_index >= 0:
		return "%s:area-%s-%s" % [skill_id, area_id, module_index]
	return area_key(skill_id, area_id)


func area_module_display_name(area_def: Dictionary) -> String:
	var area_id := str(area_def.get("id", ""))
	var base_name := str(area_def.get("name", area_id.capitalize()))
	var module_index := int(area_def.get("module_index", -1))
	if module_index <= 0:
		return base_name
	match area_id:
		"sea":
			return "Sea #%d" % (module_index + 1)
		"reef":
			return "Reef #%d" % (module_index + 1)
	return "%s #%d" % [base_name, module_index + 1]


func next_locked_teaser_target(host, skill_id: String, location_defs: Dictionary, tool_location_actions: Dictionary) -> Dictionary:
	var best := {}
	var best_unlock := 999999
	var best_order := 999999
	var order := 0
	for raw_area in area_definitions:
		var area_def := raw_area as Dictionary
		var area_id := str(area_def.get("id", ""))
		if area_uses_location_tiles(area_def, location_defs):
			for raw_location in locations_for_area(area_id, location_defs):
				var location := raw_location as Dictionary
				if location_is_unlocked(host, area_id, location, location_defs, tool_location_actions):
					order += 1
					continue
				var unlock_level := int(location.get("unlock", 1))
				if unlock_level < best_unlock or (unlock_level == best_unlock and order < best_order):
					best_unlock = unlock_level
					best_order = order
					best = {
						"kind": "location",
						"unlock": unlock_level,
						"key": location_key(area_id, str(location.get("id", ""))),
					}
				order += 1
			continue
		for method_id in area_def.get("methods", []):
			var action_id := str(method_id)
			var action := host._action_data(skill_id, action_id) as Dictionary
			if action.is_empty() or host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
				order += 1
				continue
			var unlock_level := int(action.get("unlock", 1))
			if unlock_level < best_unlock or (unlock_level == best_unlock and order < best_order):
				best_unlock = unlock_level
				best_order = order
				best = {"kind": "action", "unlock": unlock_level, "action_id": action_id}
			order += 1
	return best


func global_teaser_action_id(host, skill_id: String, location_defs: Dictionary, tool_location_actions: Dictionary) -> String:
	var teaser_target := next_locked_teaser_target(host, skill_id, location_defs, tool_location_actions)
	if str(teaser_target.get("kind", "")) == "action":
		return str(teaser_target.get("action_id", ""))
	return ""


func global_teaser_location_key(host, skill_id: String, location_defs: Dictionary, tool_location_actions: Dictionary) -> String:
	var teaser_target := next_locked_teaser_target(host, skill_id, location_defs, tool_location_actions)
	if str(teaser_target.get("kind", "")) == "location":
		return str(teaser_target.get("key", ""))
	return ""


func method_should_show(host, skill_id: String, action_id: String, location_defs: Dictionary, tool_location_actions: Dictionary) -> bool:
	var action := host._action_data(skill_id, action_id) as Dictionary
	if action.is_empty():
		return false
	if action_should_render_standalone(host, skill_id, action):
		return false
	if host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		return true
	if host._activity_unlock_runtime()._action_has_pending_unlock_readiness(action_id):
		return true
	return action_id == global_teaser_action_id(host, skill_id, location_defs, tool_location_actions)


func action_should_render_standalone(host, skill_id: String, action: Dictionary) -> bool:
	if skill_id != "fishing":
		return false
	if action.is_empty() or host._passive_modules_runtime().is_passive_action(action):
		return false
	return ModuleUiRuntime.action_is_combo_module(skill_id, action, Callable(host._activity_unlock_runtime(), "_action_unlock_requirements"))


func visible_standalone_actions(host, skill_id: String) -> Array:
	var standalone_actions: Array = []
	for raw_action in host._activity_unlock_runtime()._visible_actions_for_skill(skill_id):
		var action := raw_action as Dictionary
		if action_should_render_standalone(host, skill_id, action):
			standalone_actions.append(action)
	if standalone_actions.size() > 1:
		standalone_actions.sort_custom(func(left, right): return host.activity_data_catalog.activity_action_display_sort_less(left, right))
	return standalone_actions


func standalone_and_event_actions_for_render(host, skill_id: String) -> Array:
	var actions := visible_standalone_actions(host, skill_id)
	for raw_event_action in host._temporary_event_runtime()._active_event_actions_for_skill(skill_id):
		actions.append(raw_event_action as Dictionary)
	if actions.size() > 1:
		actions.sort_custom(func(left, right): return host.activity_data_catalog.activity_action_display_sort_less(left, right))
	return actions


func area_should_show(host, skill_id: String, area_def: Dictionary, location_defs: Dictionary, tool_location_actions: Dictionary) -> bool:
	if str(area_def.get("id", "")) == "space" and not mirror_collected:
		return false
	if area_uses_location_tiles(area_def, location_defs):
		var area_id := str(area_def.get("id", ""))
		for raw_location in locations_for_area(area_id, location_defs):
			if location_should_show(host, area_id, raw_location as Dictionary, location_defs, tool_location_actions):
				return true
		return false
	for method_id in area_def.get("methods", []):
		if method_should_show(host, skill_id, str(method_id), location_defs, tool_location_actions):
			return true
	return false


func area_visible_method_ids(host, skill_id: String, area_def: Dictionary, location_defs: Dictionary, tool_location_actions: Dictionary) -> Array:
	var visible_ids: Array = []
	for method_id in area_def.get("methods", []):
		var action_id := str(method_id)
		if method_should_show(host, skill_id, action_id, location_defs, tool_location_actions):
			visible_ids.append(action_id)
	return visible_ids


func render_area_modules(host, skill_id: String, location_defs: Dictionary, tool_location_actions: Dictionary, max_buttons_per_module: int) -> Array:
	var modules: Array = []
	var render_order := 0
	for raw_area in area_definitions:
		var area_def := raw_area as Dictionary
		if not area_should_show(host, skill_id, area_def, location_defs, tool_location_actions):
			continue
		if area_uses_location_tiles(area_def, location_defs):
			var area_id := str(area_def.get("id", ""))
			var visible_locations: Array = []
			for raw_location in locations_for_area(area_id, location_defs):
				var location := raw_location as Dictionary
				if location_should_show(host, area_id, location, location_defs, tool_location_actions):
					visible_locations.append(location)
			var chunk_index := 0
			for start in range(0, visible_locations.size(), max_buttons_per_module):
				var location_module := area_def.duplicate(true)
				location_module["locations"] = visible_locations.slice(start, start + max_buttons_per_module)
				location_module["module_index"] = chunk_index
				location_module["render_order"] = render_order
				modules.append(location_module)
				render_order += 1
				chunk_index += 1
			continue
		var visible_methods := area_visible_method_ids(host, skill_id, area_def, location_defs, tool_location_actions)
		var chunk_index := 0
		for start in range(0, visible_methods.size(), max_buttons_per_module):
			var chunk := area_def.duplicate(true)
			chunk["methods"] = visible_methods.slice(start, start + max_buttons_per_module)
			chunk["module_index"] = chunk_index
			chunk["render_order"] = render_order
			modules.append(chunk)
			render_order += 1
			chunk_index += 1
	sort_render_modules(host, modules, location_defs, tool_location_actions)
	return modules


func _sort_render_modules(a: Dictionary, b: Dictionary) -> bool:
	var unlock_a := int(a.get("_sort_unlock", a.get("unlock", 999999)))
	var unlock_b := int(b.get("_sort_unlock", b.get("unlock", 999999)))
	if unlock_a != unlock_b:
		return unlock_a < unlock_b
	return int(a.get("render_order", 0)) < int(b.get("render_order", 0))


func sort_render_modules(host, modules: Array, location_defs: Dictionary, tool_location_actions: Dictionary) -> void:
	for raw_module in modules:
		var module := raw_module as Dictionary
		module["_sort_unlock"] = render_module_unlock(host, module, location_defs, tool_location_actions)
	modules.sort_custom(Callable(self, "_sort_render_modules"))
	for raw_module in modules:
		(raw_module as Dictionary).erase("_sort_unlock")


func render_module_unlock(host, area_def: Dictionary, location_defs: Dictionary, tool_location_actions: Dictionary) -> int:
	var area_id := str(area_def.get("id", ""))
	var best_unlock := 999999
	if area_uses_location_tiles(area_def, location_defs):
		for raw_location in locations_for_area_module(area_def, location_defs):
			var location := raw_location as Dictionary
			if not location_should_show(host, area_id, location, location_defs, tool_location_actions):
				continue
			best_unlock = mini(best_unlock, int(location.get("unlock", 1)))
	else:
		for raw_method in area_def.get("methods", []):
			var action := host._action_data("fishing", str(raw_method)) as Dictionary
			if action.is_empty():
				continue
			best_unlock = mini(best_unlock, int(action.get("unlock", 1)))
	if best_unlock == 999999:
		return int(area_def.get("render_order", 999999))
	return best_unlock


func action_belongs_to_area(host, area_id: String, action_id: String) -> bool:
	return area_id_for_action(host, action_id) == area_id


static func area_id_for_action(host, action_id: String) -> String:
	var action := host._action_data("fishing", action_id) as Dictionary
	if action.is_empty():
		return ""
	return canonical_area_id(str(action.get("area", "")))


func area_uses_location_tiles(area_def: Dictionary, location_defs: Dictionary) -> bool:
	return location_defs.has(str(area_def.get("id", "")))


func locations_for_area(area_id: String, location_defs: Dictionary) -> Array:
	return location_defs.get(area_id, []) as Array


func locations_for_area_module(area_def: Dictionary, location_defs: Dictionary) -> Array:
	if area_def.has("locations"):
		return area_def.get("locations", []) as Array
	return locations_for_area(str(area_def.get("id", "")), location_defs)


func location_key(area_id: String, location_id: String) -> String:
	return "%s.%s" % [area_id, location_id]


func location_action_id(area_id: String, location_id: String, tool_location_actions: Dictionary) -> String:
	var key := location_key(area_id, location_id)
	var tool_map := tool_location_actions.get(equipped_tool_id, {}) as Dictionary
	var action_id := str(tool_map.get(key, ""))
	if not action_id.is_empty():
		return action_id
	var hands_map := tool_location_actions.get("hands", {}) as Dictionary
	return str(hands_map.get(key, ""))


func location_mastery_action_id(area_id: String, location_id: String, tool_location_actions: Dictionary) -> String:
	var hands_map := tool_location_actions.get("hands", {}) as Dictionary
	return str(hands_map.get(location_key(area_id, location_id), location_action_id(area_id, location_id, tool_location_actions)))


func selected_location_id(host, area_def: Dictionary, location_defs: Dictionary, tool_location_actions: Dictionary) -> String:
	var area_id := str(area_def.get("id", ""))
	var locations := locations_for_area(area_id, location_defs)
	var saved_id := str(selected_locations.get(area_id, ""))
	for raw_location in locations:
		var location := raw_location as Dictionary
		if str(location.get("id", "")) == saved_id:
			return saved_id
	for raw_location in locations:
		var location := raw_location as Dictionary
		if location_is_unlocked(host, area_id, location, location_defs, tool_location_actions):
			return str(location.get("id", ""))
	return str((locations[0] as Dictionary).get("id", "")) if not locations.is_empty() else ""


func area_default_method(host, skill_id: String, area_def: Dictionary, location_defs: Dictionary, tool_location_actions: Dictionary) -> String:
	if (
		host.running_skill_id == skill_id
		and action_belongs_to_area(host, str(area_def.get("id", "")), host.running_action_id)
		and (area_def.get("methods", []) as Array).has(host.running_action_id)
	):
		return host.running_action_id
	if area_uses_location_tiles(area_def, location_defs):
		var area_id := str(area_def.get("id", ""))
		var saved_location_id := str(selected_locations.get(area_id, ""))
		for raw_location in locations_for_area_module(area_def, location_defs):
			var selected_location := raw_location as Dictionary
			if str(selected_location.get("id", "")) != saved_location_id:
				continue
			var selected_action_id := location_action_id(area_id, saved_location_id, tool_location_actions)
			if not selected_action_id.is_empty():
				return selected_action_id
		for raw_location in locations_for_area_module(area_def, location_defs):
			var fallback_location := raw_location as Dictionary
			if not location_should_show(host, area_id, fallback_location, location_defs, tool_location_actions):
				continue
			var fallback_action_id := location_action_id(area_id, str(fallback_location.get("id", "")), tool_location_actions)
			if not fallback_action_id.is_empty():
				return fallback_action_id
	for method_id in area_def.get("methods", []):
		var action_id := str(method_id)
		var action := host._action_data(skill_id, action_id) as Dictionary
		if not action.is_empty() and host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
			return action_id
	for method_id in area_def.get("methods", []):
		if method_should_show(host, skill_id, str(method_id), location_defs, tool_location_actions):
			return str(method_id)
	return ""


func location_should_show(host, area_id: String, location: Dictionary, location_defs: Dictionary, tool_location_actions: Dictionary) -> bool:
	if location_is_unlocked(host, area_id, location, location_defs, tool_location_actions):
		return true
	var key := location_key(area_id, str(location.get("id", "")))
	return key == next_locked_location_preview_key(host, location_defs, tool_location_actions)


func location_level_unlocked(host, location: Dictionary) -> bool:
	return SkillState.host_skill_level(host, "fishing") >= int(location.get("unlock", 1))


func location_is_available(host, _area_id: String, location: Dictionary) -> bool:
	if not location_level_unlocked(host, location):
		return false
	return true


func location_is_unlocked(host, area_id: String, location: Dictionary, location_defs: Dictionary, tool_location_actions: Dictionary) -> bool:
	if not location_is_available(host, area_id, location):
		return false
	var action := location_display_action(host, area_id, location, location_defs, tool_location_actions)
	if action.is_empty():
		return false
	return host._activity_unlock_runtime()._is_action_unlocked("fishing", action)


func location_area_is_unlocked(host, area_id: String, location_defs: Dictionary, tool_location_actions: Dictionary) -> bool:
	for raw_location in locations_for_area(area_id, location_defs):
		var location := raw_location as Dictionary
		if location_is_unlocked(host, area_id, location, location_defs, tool_location_actions):
			return true
	return false


func next_locked_location_preview_key(host, location_defs: Dictionary, tool_location_actions: Dictionary) -> String:
	return global_teaser_location_key(host, "fishing", location_defs, tool_location_actions)


func location_display_action(host, area_id: String, location: Dictionary, location_defs: Dictionary, tool_location_actions: Dictionary) -> Dictionary:
	var action_id := location_action_id(area_id, str(location.get("id", "")), tool_location_actions)
	var action := host._action_data("fishing", action_id) as Dictionary
	if not action.is_empty():
		return action
	var methods := []
	for area_def in area_definitions:
		if str(area_def.get("id", "")) == area_id:
			methods = area_def.get("methods", [])
			break
	for raw_method in methods:
		action = host._action_data("fishing", str(raw_method)) as Dictionary
		if not action.is_empty():
			return action
	return {}


func location_is_unlocked_after_manual_unlock(host, area_id: String, location: Dictionary, unlocked_action_id: String, location_defs: Dictionary, tool_location_actions: Dictionary) -> bool:
	var action_id := location_action_id(area_id, str(location.get("id", "")), tool_location_actions)
	if action_id == unlocked_action_id:
		return true
	return location_is_unlocked(host, area_id, location, location_defs, tool_location_actions)


func first_locked_location_action_after_manual_unlock(host, unlocked_action_id: String, preferred_area_id: String, location_defs: Dictionary, tool_location_actions: Dictionary) -> String:
	var best_action_id := ""
	var best_unlock := 999999
	var best_render_order := 999999
	var render_order := 0
	for raw_area in area_definitions:
		var area_def := raw_area as Dictionary
		if not area_uses_location_tiles(area_def, location_defs):
			continue
		var area_id := str(area_def.get("id", ""))
		if not preferred_area_id.is_empty() and area_id != preferred_area_id:
			continue
		for raw_location in locations_for_area(area_id, location_defs):
			var location := raw_location as Dictionary
			if location_is_unlocked_after_manual_unlock(host, area_id, location, unlocked_action_id, location_defs, tool_location_actions):
				render_order += 1
				continue
			var action_id := location_action_id(area_id, str(location.get("id", "")), tool_location_actions)
			if action_id.is_empty():
				render_order += 1
				continue
			var unlock_level := int(location.get("unlock", 1))
			if unlock_level < best_unlock or (unlock_level == best_unlock and render_order < best_render_order):
				best_unlock = unlock_level
				best_render_order = render_order
				best_action_id = action_id
			render_order += 1
	return best_action_id


func location_id_valid(area_id: String, location_id: String, location_defs: Dictionary) -> bool:
	for raw_location in locations_for_area(area_id, location_defs):
		var location := raw_location as Dictionary
		if str(location.get("id", "")) == location_id:
			return true
	return false


func collect_tool_from_equipped(tool_id: String) -> void:
	match tool_id:
		"net":
			net_collected = true
		"line":
			rod_collected = true
		"reinforced_rod":
			rod_collected = true
			reinforced_rod_collected = true
		"star_rod":
			rod_collected = true
			reinforced_rod_collected = true
			star_rod_collected = true
		"boat":
			boat_built = true
		"mirror":
			mirror_collected = true


func tool_is_unlocked(tool_id: String) -> bool:
	match tool_id:
		"hands":
			return true
		"net":
			return net_collected
		"line":
			return rod_collected and not reinforced_rod_collected and not star_rod_collected
		"reinforced_rod":
			return reinforced_rod_collected and not star_rod_collected
		"star_rod":
			return star_rod_collected
		"boat":
			return boat_built
		"mirror":
			return mirror_collected
	return false


func visible_rod_slot_id() -> String:
	if star_rod_collected:
		return "star_rod"
	if reinforced_rod_collected:
		return "reinforced_rod"
	return "line"


func set_equipped_tool(tool_id: String) -> void:
	equipped_tool_id = tool_id
	net_set_in_water = false
	boat_set_in_water = false
	rod_set_in_water = false
	rod_haul_visual_seconds = 0.0
	clear_inactive_batch_storage()


func clear_inactive_batch_storage() -> void:
	if equipped_tool_id != "net":
		net_stored_fish = 0
		net_successes = 0
		net_stored_xp = 0
		net_stored_mastery = 0.0
		net_haul_visual_seconds = 0.0
		net_set_in_water = false
	if equipped_tool_id != "boat":
		boat_stored_fish = 0
		boat_successes = 0
		boat_stored_xp = 0
		boat_stored_mastery = 0.0
		boat_haul_visual_seconds = 0.0


func ensure_action_index_cache(tool_location_actions: Dictionary, thumbnail_path: Callable) -> void:
	if not action_location_key_cache.is_empty():
		return
	var hands_map := tool_location_actions.get("hands", {}) as Dictionary
	for raw_tool_id in tool_location_actions.keys():
		var tool_map := tool_location_actions.get(raw_tool_id, {}) as Dictionary
		for raw_location_key in tool_map.keys():
			var location_key := str(raw_location_key)
			var action_id := str(tool_map.get(raw_location_key, ""))
			if action_id.is_empty():
				continue
			var parts := location_key.split(".")
			if parts.size() != 2:
				continue
			if not action_location_key_cache.has(action_id):
				action_location_key_cache[action_id] = location_key
				action_thumbnail_path_cache[action_id] = str(thumbnail_path.call(str(parts[0]), str(parts[1])))
			if not action_mastery_id_cache.has(action_id):
				action_mastery_id_cache[action_id] = str(hands_map.get(location_key, action_id))


func indexed_action_art_path(action: Dictionary, tool_location_actions: Dictionary, thumbnail_path: Callable) -> String:
	var action_id := str(action.get("id", ""))
	ensure_action_index_cache(tool_location_actions, thumbnail_path)
	if action_thumbnail_path_cache.has(action_id):
		return str(action_thumbnail_path_cache.get(action_id, ""))
	var art := str(action.get("art", ""))
	if not art.is_empty():
		return art
	var background := str(action.get("background", ""))
	if not background.is_empty():
		return background
	return art


func mastery_action_id(action_id: String, tool_location_actions: Dictionary, thumbnail_path: Callable) -> String:
	ensure_action_index_cache(tool_location_actions, thumbnail_path)
	if action_mastery_id_cache.has(action_id):
		return str(action_mastery_id_cache.get(action_id, action_id))
	return action_id


func record_batch_success(tool_id: String, fish_count: int, xp_reward: int, threshold: int, haul_visual_seconds: float) -> Dictionary:
	if tool_id == "boat":
		boat_set_in_water = true
		boat_successes += 1
		boat_stored_xp += xp_reward
		boat_stored_fish += fish_count
		if boat_stored_fish < threshold:
			return {"haul_count": 0, "feedback_xp": xp_reward, "feedback_mastery": 0.0}
		var boat_haul_count := boat_stored_fish
		var boat_feedback_xp := boat_stored_xp
		var boat_feedback_mastery := boat_stored_mastery
		boat_stored_fish = 0
		boat_successes = 0
		boat_stored_xp = 0
		boat_stored_mastery = 0.0
		boat_haul_visual_seconds = haul_visual_seconds
		return {"haul_count": boat_haul_count, "feedback_xp": boat_feedback_xp, "feedback_mastery": boat_feedback_mastery}
	net_set_in_water = true
	net_successes += 1
	net_stored_xp += xp_reward
	net_stored_fish += fish_count
	if net_stored_fish < threshold:
		return {"haul_count": 0, "feedback_xp": xp_reward, "feedback_mastery": 0.0}
	var net_haul_count := net_stored_fish
	var net_feedback_xp := net_stored_xp
	var net_feedback_mastery := net_stored_mastery
	net_stored_fish = 0
	net_successes = 0
	net_stored_xp = 0
	net_stored_mastery = 0.0
	net_haul_visual_seconds = haul_visual_seconds
	net_set_in_water = false
	return {"haul_count": net_haul_count, "feedback_xp": net_feedback_xp, "feedback_mastery": net_feedback_mastery}


func record_mastery_stored(tool_id: String, mastery_reward: float) -> void:
	if tool_id == "boat":
		boat_stored_mastery += mastery_reward
	else:
		net_stored_mastery += mastery_reward


func award_fish_currency(host, amount: float) -> void:
	var safe_amount := maxf(0.0, amount)
	if safe_amount <= 0.0:
		return
	fish_currency += safe_amount
	fish_currency_ever_earned = true
	host._fishing_ui_surface()._sync_auto_eat_fish_toggle_buttons()


func complete_action_attempt(host, action: Dictionary, active_key: String, bonus_snapshot_before: Dictionary) -> void:
	var skill_id = host.running_skill_id
	var action_id = host.running_action_id
	var reward_key = active_key
	var catch_burst_action_id = ""
	var catch_burst_fish_count = 0
	var mastery_action_id = host.fishing_runtime.mastery_action_id(action_id, FISHING_TOOL_LOCATION_ACTIONS, Callable(host, "_fishing_location_thumbnail_path"))
	var old_mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, mastery_action_id))
	var tiers_unlocked_before = {}
	for tier in range(1, host.MASTERY_MAX_LEVEL + 1):
		tiers_unlocked_before[tier] = AchievementState.global_medal_tier_unlocked(host, tier)
	var completed_achievements_before = AchievementState.completed_ids(AchievementState.milestones(host, false))
	var old_skill_level = SkillState.host_skill_level(host, skill_id)
	var locked_preview_available_before = host._activity_unlock_runtime()._locked_activity_preview_available()
	var direct_fish_currency_reward = has_direct_fish_currency_reward(action)
	var netting = equipped_tool_id == "net" and not direct_fish_currency_reward
	var boating = equipped_tool_id == "boat" and not direct_fish_currency_reward
	var batching = netting or boating
	var rodding = is_rod(equipped_tool_id)
	var success = host._action_runtime()._roll_action_success(skill_id, action)
	var stored_mastery_feedback = 0.0
	host._action_runtime().reset_consecutive_activity_crits()
	if success:
		if rodding:
			rod_haul_visual_seconds = FISHING_ROD_HAUL_VISUAL_SECONDS
			rod_set_in_water = false
		var xp_reward_map = host._action_runtime()._fishing_completion_xp_reward_map(action, skill_id)
		var old_reward_skill_levels = host._action_runtime()._skill_levels_for_reward_map(skill_id, xp_reward_map)
		var affected_reward_skill_ids = host._action_runtime()._apply_xp_reward_map(skill_id, xp_reward_map)
		var xp_reward = host._action_runtime()._reward_map_total(xp_reward_map)
		var direct_fish_currency_amount = roll_direct_fish_currency(action) if direct_fish_currency_reward else 0.0
		var fish_count = 0 if direct_fish_currency_reward else roll_fish_count(host, action, equipped_tool_id)
		var haul_count = fish_count
		var feedback_xp = xp_reward
		var feedback_mastery = 0.0
		if netting:
			var net_result = record_batch_success("net", fish_count, xp_reward, FISHING_NET_HAUL_THRESHOLD, FISHING_NET_HAUL_VISUAL_SECONDS)
			haul_count = int(net_result.get("haul_count", 0))
			feedback_xp = int(net_result.get("feedback_xp", xp_reward))
			feedback_mastery = float(net_result.get("feedback_mastery", 0.0))
		if boating:
			var boat_result = record_batch_success("boat", fish_count, xp_reward, FISHING_BOAT_HAUL_THRESHOLD, FISHING_BOAT_HAUL_VISUAL_SECONDS)
			haul_count = int(boat_result.get("haul_count", 0))
			feedback_xp = int(boat_result.get("feedback_xp", xp_reward))
			feedback_mastery = float(boat_result.get("feedback_mastery", 0.0))
		var show_success_feedback = not batching or haul_count > 0
		if show_success_feedback:
			host._fishing_ui_surface()._play_fishing_attempt_reveal(skill_id, action_id, true)
		var food_value = direct_fish_currency_amount if direct_fish_currency_reward else tool_food_value_for_catches(equipped_tool_id, action_id, haul_count)
		if food_value > 0.0:
			award_fish_currency(host, food_value)
		var earned_mastery_reward = net_mastery_reward(host, skill_id, action_id, haul_count > 0) if netting else mastery_reward(host, skill_id, action_id)
		if earned_mastery_reward > 0.0:
			MasteryState.add_host_xp(host, skill_id, mastery_action_id, earned_mastery_reward)
			if netting:
				if haul_count > 0:
					feedback_mastery += earned_mastery_reward
				else:
					record_mastery_stored("net", earned_mastery_reward)
					stored_mastery_feedback = earned_mastery_reward
			elif boating:
				if haul_count > 0:
					feedback_mastery += earned_mastery_reward
				else:
					record_mastery_stored("boat", earned_mastery_reward)
					stored_mastery_feedback = earned_mastery_reward
			else:
				feedback_mastery = earned_mastery_reward
		var new_mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, mastery_action_id))
		host._onboarding_runtime()._register_silver_opportunity_tip_anchor(skill_id, mastery_action_id, old_mastery_level, new_mastery_level)
		for raw_reward_skill_id in affected_reward_skill_ids:
			SkillState.recalculate_level(host, str(raw_reward_skill_id))
		host._activity_unlock_ceremony_surface().queue_locked_preview_reveal_if_needed(locked_preview_available_before)
		var any_reward_skill_level_up = host._action_runtime()._any_reward_skill_leveled_up(affected_reward_skill_ids, old_reward_skill_levels)
		host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
		var new_global_buffs = AchievementState.new_global_medal_buff_messages(host, old_mastery_level, new_mastery_level, tiers_unlocked_before)
		var xp_result_phrase = host._action_runtime()._xp_reward_result_phrase(xp_reward_map, skill_id)
		if batching and haul_count > 0 and feedback_xp != xp_reward:
			xp_result_phrase = "+%s XP" % GameFormatting.info_chip_number(float(feedback_xp))
		if netting:
			if haul_count > 0:
				host.last_result = "%s, +%s mastery, hauled +%s food from %s." % [xp_result_phrase, GameFormatting.significant_digits(feedback_mastery), GameFormatting.compact_number(maxf(0.0, food_value), 3), action["name"]]
			else:
				host.last_result = "%s, +%s catch entered net (%s/%s)." % [xp_result_phrase, fish_count, net_stored_fish, FISHING_NET_HAUL_THRESHOLD]
		elif boating:
			if haul_count > 0:
				host.last_result = "%s, +%s mastery, brought in +%s food from %s." % [xp_result_phrase, GameFormatting.significant_digits(feedback_mastery), GameFormatting.compact_number(maxf(0.0, food_value), 3), action["name"]]
			else:
				host.last_result = "%s, +%s catch loaded boat (%s/%s)." % [xp_result_phrase, fish_count, boat_stored_fish, FISHING_BOAT_HAUL_THRESHOLD]
		else:
			if feedback_mastery > 0.0:
				host.last_result = "%s, +%s mastery, +%s food from %s." % [xp_result_phrase, GameFormatting.significant_digits(feedback_mastery), GameFormatting.compact_number(maxf(0.0, food_value), 3), action["name"]]
			else:
				host.last_result = "%s, +%s food from %s." % [xp_result_phrase, GameFormatting.compact_number(maxf(0.0, food_value), 3), action["name"]]
		if host._hub_runtime().record_mission_action_completion(skill_id, action_id):
			host.last_result += " Mission progress."
		if not new_global_buffs.is_empty():
			host.last_result += " " + " ".join(new_global_buffs)
		if show_success_feedback:
			host._reward_feedback_surface()._play_action_feedback(reward_key, true, feedback_xp, feedback_mastery, false, false, xp_reward_map, food_value if direct_fish_currency_reward else 0.0)
		var area_card = host._fishing_ui_surface()._fishing_area_card_for_action(skill_id, action_id)
		if not direct_fish_currency_reward and not area_card.is_empty() and haul_count > 0:
			catch_burst_action_id = action_id
			catch_burst_fish_count = haul_count
		host._action_runtime().record_successful_activity_completion(reward_key)
		if not batching or haul_count > 0:
			host._audio_director()._play_activity_success_sound(1, new_mastery_level > old_mastery_level, false, false, false, 0)
		host._audio_director()._record_music_flow_action(true, 1, false, new_mastery_level > old_mastery_level, any_reward_skill_level_up or SkillState.host_skill_level(host, skill_id) > old_skill_level, 0.0)
	else:
		mark_missed(equipped_tool_id)
		if not batching and not rodding:
			host._fishing_ui_surface()._play_fishing_attempt_reveal(skill_id, action_id, false)
		host._action_runtime().reset_activity_completion_streak()
		var failure_mastery_level = MasteryState.level(host.mastery, host._action_key(skill_id, mastery_action_id))
		host.last_result = "Missed %s." % action["name"]
		if not MasteryState.is_maxed(host.mastery, host._action_key(skill_id, mastery_action_id), host.MASTERY_MAX_LEVEL):
			host.last_result += " Next medal needs a catch."
		var failure_global_buffs = AchievementState.new_global_medal_buff_messages(host, old_mastery_level, failure_mastery_level, tiers_unlocked_before)
		if not failure_global_buffs.is_empty():
			host.last_result += " " + " ".join(failure_global_buffs)
		if not batching and not rodding:
			host._reward_feedback_surface()._play_action_feedback(reward_key, false, 0, 0.0, false, false)
			host._audio_director()._play_fishing_failure_sfx()
		host._audio_director()._record_music_flow_action(false, 0, false, failure_mastery_level > old_mastery_level, false, 0.0)
	for achievement in AchievementState.newly_completed(AchievementState.milestones(host, false), completed_achievements_before):
		host._achievement_toast_surface().show_unlocked(achievement)
	host._onboarding_runtime()._record_activity_completion_for_tips(skill_id, action_id)
	host._update_ui(0.0, false)
	if success and stored_mastery_feedback > 0.0:
		host._reward_feedback_surface()._play_action_mastery_feedback(reward_key, stored_mastery_feedback)
	if not catch_burst_action_id.is_empty() and catch_burst_fish_count > 0:
		host._fishing_ui_surface().call_deferred("_play_fishing_catch_burst_for_action", skill_id, catch_burst_action_id, catch_burst_fish_count)
	host._reward_feedback_surface()._emphasize_visible_bonus_changes_deferred(bonus_snapshot_before)


func mark_missed(tool_id: String) -> void:
	if tool_id == "net":
		net_set_in_water = true
	elif tool_id == "boat":
		boat_set_in_water = true
	elif is_rod(tool_id):
		rod_set_in_water = true


func normalized_selected_locations(loaded_locations: Variant, area_loaded: Callable, location_valid: Callable) -> Dictionary:
	var normalized := {}
	if typeof(loaded_locations) != TYPE_DICTIONARY:
		return normalized
	var source := loaded_locations as Dictionary
	for raw_area_id in source.keys():
		var area_id := canonical_area_id(str(raw_area_id))
		if area_id.is_empty() or not bool(area_loaded.call(area_id)):
			continue
		var location_id := str(source.get(raw_area_id, ""))
		if location_id.is_empty():
			continue
		if bool(location_valid.call(area_id, location_id)):
			normalized[area_id] = location_id
	return normalized


func restore_selected_locations(loaded_locations: Variant, area_loaded: Callable, location_valid: Callable) -> void:
	selected_locations.clear()
	var normalized := normalized_selected_locations(loaded_locations, area_loaded, location_valid)
	for area_id in normalized.keys():
		selected_locations[area_id] = normalized[area_id]


func selected_locations_for_save(area_loaded: Callable, location_valid: Callable) -> Dictionary:
	return normalized_selected_locations(selected_locations, area_loaded, location_valid)


func equipped_tool_id_for_save(is_unlocked: Callable) -> String:
	if is_rod(equipped_tool_id):
		if star_rod_collected:
			return "star_rod"
		if reinforced_rod_collected:
			return "reinforced_rod"
		if rod_collected:
			return "line"
		return "hands"
	if bool(is_unlocked.call(equipped_tool_id)):
		return equipped_tool_id
	return "hands"


func rod_collected_for_save() -> bool:
	return rod_collected or reinforced_rod_collected or star_rod_collected


func reinforced_rod_collected_for_save() -> bool:
	return reinforced_rod_collected or star_rod_collected


func star_rod_collected_for_save() -> bool:
	return star_rod_collected


func reconcile_rod_collection() -> void:
	if star_rod_collected:
		reinforced_rod_collected = true
		rod_collected = true
	elif reinforced_rod_collected:
		rod_collected = true


func restore_from_save(data: Dictionary, net_threshold: int, boat_threshold: int, is_unlocked: Callable, area_loaded: Callable, location_valid: Callable) -> void:
	fish_currency = maxf(0.0, float(data.get("fish_currency", fish_currency)))
	fish_currency_ever_earned = bool(data.get("fish_currency_ever_earned", fish_currency_ever_earned or fish_currency > 0.0))
	equipped_tool_id = str(data.get("equipped_fishing_tool_id", equipped_tool_id))
	net_stored_fish = clampi(int(data.get("fishing_net_stored_fish", net_stored_fish)), 0, net_threshold - 1)
	net_successes = maxi(0, int(data.get("fishing_net_successes", net_successes)))
	net_stored_xp = maxi(0, int(data.get("fishing_net_stored_xp", net_stored_xp)))
	net_stored_mastery = maxf(0.0, float(data.get("fishing_net_stored_mastery", net_stored_mastery)))
	net_haul_visual_seconds = 0.0
	net_set_in_water = false
	boat_stored_fish = clampi(int(data.get("fishing_boat_stored_fish", boat_stored_fish)), 0, boat_threshold - 1)
	boat_successes = maxi(0, int(data.get("fishing_boat_successes", boat_successes)))
	boat_stored_xp = maxi(0, int(data.get("fishing_boat_stored_xp", boat_stored_xp)))
	boat_stored_mastery = maxf(0.0, float(data.get("fishing_boat_stored_mastery", boat_stored_mastery)))
	boat_haul_visual_seconds = 0.0
	boat_set_in_water = false
	rod_set_in_water = false
	rod_haul_visual_seconds = 0.0
	net_collected = bool(data.get("fishing_net_collect_completed", data.get("fishing_net_collected", false)))
	net_collect_pending = false
	rod_collected = bool(data.get("fishing_rod_collected", rod_collected))
	reinforced_rod_collected = bool(data.get("fishing_reinforced_rod_collected", reinforced_rod_collected))
	star_rod_collected = bool(data.get("fishing_star_rod_collected", star_rod_collected))
	reconcile_rod_collection()
	boat_built = bool(data.get("fishing_boat_built", boat_built))
	mirror_collected = bool(data.get("fishing_mirror_collected", mirror_collected))
	collect_tool_from_equipped(equipped_tool_id)
	if is_rod(equipped_tool_id):
		equipped_tool_id = visible_rod_slot_id() if rod_collected else "hands"
	if not bool(is_unlocked.call(equipped_tool_id)):
		equipped_tool_id = "hands"
	clear_inactive_batch_storage()
	restore_selected_locations(data.get("selected_fishing_locations", {}), area_loaded, location_valid)


func save_payload(net_threshold: int, boat_threshold: int, is_unlocked: Callable, area_loaded: Callable, location_valid: Callable) -> Dictionary:
	return {
		"fish_currency": maxf(0.0, fish_currency),
		"fish_currency_ever_earned": fish_currency_ever_earned or fish_currency > 0.0,
		"equipped_fishing_tool_id": equipped_tool_id_for_save(is_unlocked),
		"fishing_net_stored_fish": clampi(net_stored_fish, 0, net_threshold - 1),
		"fishing_net_successes": maxi(0, net_successes),
		"fishing_net_stored_xp": maxi(0, net_stored_xp),
		"fishing_net_stored_mastery": maxf(0.0, net_stored_mastery),
		"fishing_boat_stored_fish": clampi(boat_stored_fish, 0, boat_threshold - 1),
		"fishing_boat_successes": maxi(0, boat_successes),
		"fishing_boat_stored_xp": maxi(0, boat_stored_xp),
		"fishing_boat_stored_mastery": maxf(0.0, boat_stored_mastery),
		"fishing_net_collect_completed": net_collected,
		"fishing_rod_collected": rod_collected_for_save(),
		"fishing_reinforced_rod_collected": reinforced_rod_collected_for_save(),
		"fishing_star_rod_collected": star_rod_collected_for_save(),
		"fishing_boat_built": boat_built,
		"fishing_mirror_collected": mirror_collected,
		"selected_fishing_locations": selected_locations_for_save(area_loaded, location_valid),
	}


static func canonical_area_id(area_id: String) -> String:
	if FISHING_AREA_ID_ALIASES.has(area_id):
		return str(FISHING_AREA_ID_ALIASES[area_id])
	return area_id


static func is_rod(tool_id: String) -> bool:
	return tool_id in ["line", "reinforced_rod", "star_rod"]


static func action_is_space(action_id: String) -> bool:
	return action_id.begins_with("space-")


static func tool_catches_nothing_for_action(tool_id: String, action_id: String) -> bool:
	return action_is_space(action_id) and tool_id != "mirror"


static func tool_is_bad_for_action(tool_id: String, action_id: String) -> bool:
	if tool_catches_nothing_for_action(tool_id, action_id):
		return true
	match action_id:
		"beach-rocks":
			return is_rod(tool_id) or tool_id == "boat"
	return false


func tool_success_bonus() -> float:
	match equipped_tool_id:
		"reinforced_rod":
			return 5.0
		"star_rod":
			return 10.0
	return 0.0


func tool_warning_text(action_id: String) -> String:
	if tool_catches_nothing_for_action(equipped_tool_id, action_id):
		return "NO CATCH"
	if tool_is_bad_for_action(equipped_tool_id, action_id):
		return "BAD TOOL"
	if equipped_tool_id == "hands":
		var hands_chance := hands_success_chance(action_id)
		if hands_chance <= 10.0:
			return "AWFUL TOOL"
		if hands_chance <= 25.0:
			return "BAD TOOL"
		if hands_chance <= 45.0:
			return "WEAK TOOL"
	return ""


func tool_yield_bonus() -> int:
	return 0


func yield_label(host, action: Dictionary, tool_id := "", net_haul_threshold := 10) -> String:
	var active_tool_id := equipped_tool_id if tool_id.is_empty() else tool_id
	var action_id := str(action.get("id", ""))
	var direct_currency_range := direct_fish_currency_range(action)
	if not direct_currency_range.is_empty():
		var direct_min := float(direct_currency_range.get("min", 0.0))
		var direct_max := float(direct_currency_range.get("max", direct_min))
		if is_equal_approx(direct_min, direct_max):
			return GameFormatting.compact_number(maxf(0.0, direct_min), 3)
		return GameFormatting.compact_number_range(direct_min, direct_max, 3)
	if tool_catches_nothing_for_action(active_tool_id, action_id):
		return "0"
	if active_tool_id == "net":
		return "%d-%d/%d" % [FISHING_NET_FILL_MIN, FISHING_NET_FILL_MAX, net_haul_threshold]
	var range := yield_range(action, tool_id)
	var min_food := tool_food_value_for_catches(active_tool_id, action_id, int(range["min"]))
	var max_food := tool_food_value_for_catches(active_tool_id, action_id, int(range["max"]))
	if is_equal_approx(min_food, max_food):
		return GameFormatting.compact_number(maxf(0.0, min_food), 3)
	return GameFormatting.compact_number_range(min_food, max_food, 3)


func yield_range(action: Dictionary, tool_id := "") -> Dictionary:
	var active_tool_id := equipped_tool_id if tool_id.is_empty() else tool_id
	var action_id := str(action.get("id", ""))
	if has_direct_fish_currency_reward(action):
		return {"min": 0, "max": 0}
	if tool_catches_nothing_for_action(active_tool_id, action_id):
		return {"min": 0, "max": 0}
	if active_tool_id == "hands":
		return {"min": 1, "max": 1}
	if is_rod(active_tool_id):
		return {"min": 1, "max": 1}
	if tool_is_bad_for_action(active_tool_id, action_id):
		return {"min": 1, "max": 1}
	var rewards := action.get("rewards", {}) as Dictionary
	if rewards.has("fish_min") and rewards.has("fish_max"):
		var fish_min := maxi(1, int(rewards.get("fish_min", 1)))
		var fish_max := maxi(fish_min, int(rewards.get("fish_max", fish_min)))
		if active_tool_id == "net":
			return {"min": FISHING_NET_FILL_MIN, "max": FISHING_NET_FILL_MAX}
		if active_tool_id == "boat":
			return {"min": FISHING_BOAT_FILL_MIN, "max": FISHING_BOAT_FILL_MAX}
		var bonus := tool_yield_bonus() if active_tool_id == equipped_tool_id else 0
		return {"min": fish_min + bonus, "max": fish_max + bonus}
	var tier := int(action.get("tier", 1))
	if active_tool_id == "net":
		return {"min": FISHING_NET_FILL_MIN, "max": FISHING_NET_FILL_MAX}
	if active_tool_id == "boat":
		return {"min": FISHING_BOAT_FILL_MIN, "max": FISHING_BOAT_FILL_MAX}
	var fallback_bonus := tool_yield_bonus() if active_tool_id == equipped_tool_id else 0
	return {
		"min": maxi(1, tier - 1) + fallback_bonus,
		"max": maxi(maxi(1, tier - 1) + 1, tier + 1) + fallback_bonus,
	}


static func direct_fish_currency_range(action: Dictionary) -> Dictionary:
	var rewards := action.get("rewards", {}) as Dictionary
	if not rewards.has("fish_currency_min") or not rewards.has("fish_currency_max"):
		return {}
	var fish_min := maxf(0.0, float(rewards.get("fish_currency_min", 0.0)))
	var fish_max := maxf(fish_min, float(rewards.get("fish_currency_max", fish_min)))
	if fish_max <= 0.0:
		return {}
	return {"min": fish_min, "max": fish_max}


static func has_direct_fish_currency_reward(action: Dictionary) -> bool:
	return not direct_fish_currency_range(action).is_empty()


static func roll_direct_fish_currency(action: Dictionary) -> float:
	var reward_range := direct_fish_currency_range(action)
	if reward_range.is_empty():
		return 0.0
	var fish_min := float(reward_range.get("min", 0.0))
	var fish_max := float(reward_range.get("max", fish_min))
	if is_equal_approx(fish_min, fish_max):
		return fish_min
	return randf_range(fish_min, fish_max)


static func method_archetype(host, action_id: String) -> String:
	var action := host._action_data("fishing", action_id) as Dictionary
	if not action.is_empty():
		var from_data := str(action.get("archetype", "")).strip_edges()
		if not from_data.is_empty():
			return from_data
	match action_id:
		"beach-rocks", "sea-open-water", "space-reflection":
			return "volume"
		"sewers-drain-gate":
			return "chaos"
		"sea-chum-line":
			return "risk"
		"stormy-sea-ripple", "sewers-tunnel-pool", "deep-sea-abyss", "stormy-sea-storm-line", "reef-pearl-bed":
			return "commit"
		_:
			return "steady"


func attempt_success_chance(host, action_id: String) -> float:
	if tool_catches_nothing_for_action(equipped_tool_id, action_id):
		return 0.0
	if equipped_tool_id == "hands":
		return hands_success_chance(action_id)
	var action := host._action_data("fishing", action_id) as Dictionary
	var chance := 0.0
	if not action.is_empty():
		chance = float(action.get("success", attempt_success_chance_for_archetype(method_archetype(host, action_id)))) + tool_success_bonus()
	else:
		chance = attempt_success_chance_for_archetype(method_archetype(host, action_id)) + tool_success_bonus()
	if equipped_tool_id == "net":
		chance *= FISHING_NET_SUCCESS_RATE_MULT
	if tool_is_bad_for_action(equipped_tool_id, action_id):
		return 5.0
	return clampf(chance, 5.0, 100.0)


static func attempt_success_chance_for_archetype(archetype: String) -> float:
	match archetype:
		"novice":
			return 92.0
		"volume":
			return 78.0
		"chaos":
			return 62.0
		"commit":
			return 70.0
		"risk":
			return 68.0
		_:
			return 82.0


static func catch_texture_path(action: Dictionary) -> String:
	var action_id := str(action.get("id", ""))
	if FISHING_ACTION_CATCH_TEXTURE_PATHS.has(action_id):
		return FISHING_ACTION_CATCH_TEXTURE_PATHS[action_id]
	var tier_index := clampi(int(action.get("tier", 1)) - 1, 0, FISHING_CATCH_TEXTURE_PATHS.size() - 1)
	return FISHING_CATCH_TEXTURE_PATHS[tier_index]


func roll_fish_count(host, action: Dictionary, tool_id := "") -> int:
	if has_direct_fish_currency_reward(action):
		return 0
	var range := yield_range(action, tool_id)
	var active_tool_id := equipped_tool_id if tool_id.is_empty() else tool_id
	if int(range["max"]) <= 0:
		return 0
	if active_tool_id == "hands":
		return 1
	if is_rod(active_tool_id):
		return 1
	if active_tool_id == "net":
		return randi_range(FISHING_NET_FILL_MIN, FISHING_NET_FILL_MAX)
	if active_tool_id == "boat":
		return randi_range(FISHING_BOAT_FILL_MIN, FISHING_BOAT_FILL_MAX)
	var action_id := str(action.get("id", ""))
	if range["min"] == range["max"]:
		return range["min"]
	var count := randi_range(range["min"], range["max"])
	if method_archetype(host, action_id) == "volume" and randf() < 0.45:
		count += 1
	return clampi(count, range["min"], range["max"] + 1)


static func food_value_per_catch(action_id: String) -> float:
	return float(FISHING_ACTION_FOOD_VALUES.get(action_id, 1.0))


static func food_value_for_catches(action_id: String, catch_count: int) -> float:
	return maxf(0.0, float(catch_count) * food_value_per_catch(action_id))


static func tool_food_value_for_catches(tool_id: String, action_id: String, catch_count: int) -> float:
	if tool_id == "mirror" and not action_is_space(action_id):
		return 0.0
	return food_value_for_catches(action_id, catch_count)


func flat_xp_reward(host, action: Dictionary, skill_id: String) -> int:
	if tool_catches_nothing_for_action(equipped_tool_id, str(action.get("id", ""))):
		return 0
	if equipped_tool_id == "net":
		return net_xp_reward(host, action)
	return maxi(1, int(round(float(host._action_runtime()._effective_xp(action, skill_id, false)) * tool_xp_multiplier())))


static func net_xp_reward(host, action: Dictionary) -> int:
	var action_id := str(action.get("id", ""))
	if tool_catches_nothing_for_action("net", action_id):
		return 0
	var area_id: String = canonical_area_id(str(action.get("area", area_id_for_action(host, action_id))))
	return maxi(1, int(FISHING_NET_AREA_XP.get(area_id, 1)))


static func mastery_reward(host, skill_id: String, action_id: String) -> float:
	if not host._onboarding_runtime()._onboarding_mastery_rewards_allowed(skill_id):
		return 0.0
	var mastery_action_id: String = host.fishing_runtime.mastery_action_id(action_id, FISHING_TOOL_LOCATION_ACTIONS, Callable(host, "_fishing_location_thumbnail_path"))
	if MasteryState.is_maxed(host.mastery, host._action_key(skill_id, mastery_action_id), host.MASTERY_MAX_LEVEL):
		return 0.0
	return 1.0


static func net_mastery_reward(host, skill_id: String, action_id: String, harvest: bool) -> float:
	var reward := mastery_reward(host, skill_id, action_id)
	return reward if harvest else reward * FISHING_NET_FILL_MASTERY_MULT


static func hands_success_chance(action_id: String) -> float:
	match action_id:
		"beach-shallows":
			return 82.0
		"beach-rocks":
			return 74.0
		"pier-dock-edge":
			return 60.0
		"pier-piling-line":
			return 42.0
		"sewers-drain-gate":
			return 52.0
		"river-bend":
			return 15.0
		"river-rapids":
			return 8.0
		"winter-lake-ice-hole":
			return 4.0
		"sewers-tunnel-pool":
			return 20.0
	return 6.0


func tool_time_multiplier() -> float:
	if equipped_tool_id == "hands":
		return FISHING_HANDS_TIME_MULT
	match equipped_tool_id:
		"line":
			return FISHING_ROD_TIME_MULT
		"reinforced_rod":
			return FISHING_REINFORCED_ROD_TIME_MULT
		"star_rod":
			return FISHING_STAR_ROD_TIME_MULT
	return 1.0


func tool_xp_multiplier() -> float:
	match equipped_tool_id:
		"line":
			return FISHING_ROD_XP_MULT
		"reinforced_rod":
			return FISHING_REINFORCED_ROD_XP_MULT
		"star_rod":
			return FISHING_STAR_ROD_XP_MULT
		"mirror":
			return FISHING_REFLECT_NET_XP_MULT
	return 1.0
