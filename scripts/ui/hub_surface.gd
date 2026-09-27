extends Node

const HubRuntime = preload("res://scripts/gameplay/hub_runtime.gd")
const FishCircle = preload("res://scripts/ui/fish_circle.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActionArtUi = preload("res://scripts/ui/action_art_ui.gd")
const AchievementPresentation = preload("res://scripts/achievements/presentation.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const RewardFeedbackSurface = preload("res://scripts/ui/reward_feedback_surface.gd")
const StopHoldCircle = preload("res://scripts/ui/stop_hold_circle.gd")
const ThievingState = preload("res://scripts/thieving/state.gd")
const SaveRuntime = preload("res://scripts/save_state/save_runtime.gd")
const MaterialRuntime = preload("res://scripts/materials/runtime.gd")

const HUB_BUILD_SMOKE_SHEET := "res://assets/content/hub/hub-build-cloud-solid-sheet.png"
const HUB_BUILD_SMOKE_FRAME_COUNT := 4
const HUB_SPEND_BURST_MIN_ICONS := 7
const HUB_SPEND_BURST_MAX_ICONS := 12
const HUB_SPEND_BURST_ICON_SIZE := Vector2(46, 46)
const HUB_FIELD_SIZE := Vector2(1080, 1530)
const HUB_MODULE_BOTTOM_DRAG_MARGIN := 12.0
const HUB_MISSION_BOARD_TEXTURE := "res://assets/content/hub/hub-mission-board-popup.png"
const HUB_MISSION_BOARD_ART_SIZE := Vector2(1160, 1023)
const HUB_MISSION_BOARD_SIZE := Vector2(1160, 1155)
const HUB_MISSION_BOARD_BUTTON_Y := 1024.0
const HUB_MISSION_BOARD_TARGET_Y := 0.0
const HUB_MISSION_BOARD_OPEN_SECONDS := 0.34
const HUB_MISSION_BOARD_CLOSE_SECONDS := 0.24
const HUB_HOTSPOT_DRAG_START_SLOP := 21.0
const HUB_TUTORIAL_TITLE := "Player Hub"
const HUB_TUTORIAL_BODY := "Upgrade buildings here for bonuses across the whole game.\nTap a building to upgrade it.\nDrag a building to move it."
const HUB_TUTORIAL_TIP_FADE_SECONDS := 0.18
const HUB_TROPHY_DEFAULT_CENTER := Vector2(862.5, 595)
const HUB_MISSION_PAPER_BADGE := "res://assets/content/hub/hub-mission-paper-badge-v3.png"
const HUB_MISSION_BADGE_TITLE := "Mission Task"
const HUB_MISSION_BADGE_INFO := "This action is on your Mission Board. Completing it advances the mission and grants the board's boosted task bonuses."
const ACTION_CARD_TYPE_BADGE_OFFSET_LEFT := -98.5
const ACTION_CARD_TYPE_BADGE_OFFSET_RIGHT := 17.0
const ACTION_CARD_TYPE_BADGE_OFFSET_TOP := -34.0
const ACTION_CARD_TYPE_BADGE_OFFSET_BOTTOM := 81.5
const ACTION_CARD_TYPE_BADGE_POPOVER_SIZE := Vector2(800, 370)
const ACTION_CARD_TYPE_BADGE_POPOVER_OFFSET := Vector2(-780, 86)

class HubPathDots:
	extends Control


	var path_destinations := []
	var obstacle_rects := []
	var path_dots := []
	var origin := Vector2.ZERO
	var dot_radius := 34.0
	var dot_step := 66.0
	var dot_height_scale := 0.34
	var path_color := Color("#a97943")
	var edge_color := Color("#6f4c2e")
	var stone_color := Color("#9d9485")

	func set_paths(next_origin: Vector2, next_destinations: Array, next_obstacle_rects: Array) -> void:
		origin = next_origin
		path_destinations = next_destinations.duplicate()
		obstacle_rects = next_obstacle_rects.duplicate()
		_rebuild_dots()
		queue_redraw()

	func _rebuild_dots() -> void:
		path_dots.clear()
		var routes := _path_routes()
		if routes.is_empty():
			return
		var trunk_top_y := _central_trunk_top_y(routes)
		routes.sort_custom(func(a, b): return _route_destination_y(a) > _route_destination_y(b))
		var route_entries := []
		for route in routes:
			var destination := route.get("target", origin) as Vector2
			var route_seed := float(route.get("seed", 1.0))
			var join := _central_trunk_join(destination, trunk_top_y, route_seed)
			route_entries.append({"target": destination, "seed": route_seed, "join": join})
		_collect_trunk_path(route_entries, path_dots)
		for route_entry in route_entries:
			var destination := route_entry.get("target", origin) as Vector2
			var route_seed := float(route_entry.get("seed", 1.0))
			var join := route_entry.get("join", origin) as Vector2
			var arrival := _branch_arrival_point(join, destination, route_seed)
			_add_terminal_dot(join, route_seed + 23.0, path_dots)
			_collect_branch_path(join, arrival, destination, route_seed, path_dots)
			if arrival.distance_to(destination) > dot_step * 0.22:
				_collect_arrival_tail(arrival, destination, route_seed + 67.0, path_dots)
			_add_terminal_dot(arrival, route_seed, path_dots)
		_merge_overlapping_dots(path_dots)

	func _path_routes() -> Array:
		var routes := []
		for raw_point in path_destinations:
			if typeof(raw_point) == TYPE_DICTIONARY:
				var route := raw_point as Dictionary
				var destination = route.get("target", Vector2.ZERO)
				if destination is Vector2:
					routes.append({"target": destination as Vector2, "seed": float(route.get("seed", 1.0))})
			elif raw_point is Vector2:
				routes.append({"target": raw_point as Vector2, "seed": origin.x * 0.017 + origin.y * 0.023})
		return routes

	func _central_trunk_top_y(routes: Array) -> float:
		var top_y := origin.y
		for raw_route in routes:
			var route := raw_route as Dictionary
			var destination := route.get("target", origin) as Vector2
			top_y = minf(top_y, destination.y)
		return top_y + dot_step * 0.38

	func _central_trunk_join(destination: Vector2, trunk_top_y: float, route_seed: float) -> Vector2:
		var destination_pull := clampf((destination.x - origin.x) * 0.16, -46.0, 46.0)
		var x_jitter := lerpf(-14.0, 14.0, _unit(route_seed + 5.11))
		var join_y := clampf(destination.y + dot_step * lerpf(0.44, 1.02, _unit(route_seed + 8.37)), trunk_top_y, origin.y - dot_step * 0.75)
		return Vector2(origin.x + destination_pull + x_jitter, join_y)

	func _route_destination_y(route: Variant) -> float:
		if typeof(route) == TYPE_DICTIONARY:
			var destination = (route as Dictionary).get("target", origin)
			if destination is Vector2:
				return (destination as Vector2).y
		if route is Vector2:
			return (route as Vector2).y
		return origin.y

	func _draw() -> void:
		for dot in path_dots:
			_draw_path_dot(dot)

	func occupied_rects() -> Array:
		var rects := []
		for dot in path_dots:
			rects.append(_dot_rect(dot as Dictionary, 8.0))
		return rects

	func _collect_trunk_path(route_entries: Array, next_dots: Array) -> void:
		var trunk_nodes := [origin]
		var trunk_seed := origin.x * 0.017 + origin.y * 0.023
		for raw_entry in route_entries:
			var entry := raw_entry as Dictionary
			var join := entry.get("join", origin) as Vector2
			_append_trunk_node_with_detour(trunk_nodes, join, trunk_seed + float(trunk_nodes.size()) * 13.0)
		if trunk_nodes.size() < 2:
			return
		for i in range(trunk_nodes.size() - 1):
			var start := trunk_nodes[i] as Vector2
			var destination := trunk_nodes[i + 1] as Vector2
			_collect_trunk_segment(start, destination, trunk_seed + float(i) * 19.0, next_dots)
		_add_terminal_dot(trunk_nodes[trunk_nodes.size() - 1] as Vector2, trunk_seed + 73.0, next_dots)

	func _append_trunk_node_with_detour(trunk_nodes: Array, join: Vector2, route_seed: float) -> void:
		var start := trunk_nodes[trunk_nodes.size() - 1] as Vector2
		var obstacle_rect = _obstacle_rect_for_segment(start, join)
		if obstacle_rect is Rect2:
			var rect := obstacle_rect as Rect2
			var side := _detour_side_for_obstacle(rect, route_seed)
			var detour_y := clampf(lerpf(start.y, join.y, 0.52), rect.position.y - dot_step * 0.42, rect.end.y + dot_step * 0.58)
			var detour := Vector2(rect.get_center().x + side * (rect.size.x * 0.5 + dot_step * 0.70), detour_y)
			if detour.distance_to(start) > dot_step * 0.34:
				trunk_nodes.append(detour)
		if join.distance_to(trunk_nodes[trunk_nodes.size() - 1] as Vector2) > dot_step * 0.42:
			trunk_nodes.append(join)

	func _collect_trunk_segment(start: Vector2, destination: Vector2, route_seed: float, next_dots: Array) -> void:
		var vertical := destination.y - start.y
		var control_a := start + Vector2(lerpf(-9.0, 9.0, _unit(route_seed + 1.0)), vertical * 0.42)
		var control_b := destination + Vector2(lerpf(-9.0, 9.0, _unit(route_seed + 3.0)), -vertical * 0.30)
		_collect_sampled_dotted_path(start, destination, route_seed, next_dots, func(t: float) -> Vector2:
			var q := 1.0 - t
			var wave := sin(t * PI) * lerpf(-11.0, 11.0, _unit(route_seed + 7.0))
			var point := q * q * q * start + 3.0 * q * q * t * control_a + 3.0 * q * t * t * control_b + t * t * t * destination
			point.x += wave
			return point
		)

	func _branch_arrival_point(start: Vector2, destination: Vector2, route_seed: float) -> Vector2:
		var side := signf(destination.x - start.x)
		if absf(side) < 0.001:
			side = 1.0 if _unit(route_seed + 17.0) > 0.5 else -1.0
		var destination_obstacle = _obstacle_rect_near_point(destination)
		if destination_obstacle is Rect2:
			var rect := destination_obstacle as Rect2
			var centered_hotspot := absf(rect.get_center().x - origin.x) < dot_step * 1.18
			if centered_hotspot:
				side = _detour_side_for_obstacle(rect, route_seed + 37.0)
				return Vector2(rect.get_center().x + side * (rect.size.x * 0.5 + dot_step * 0.28), rect.end.y + dot_step * lerpf(0.18, 0.40, _unit(route_seed + 41.0)))
		var bottom_bias := _unit(route_seed + 71.0)
		if bottom_bias > 0.36:
			var bottom_drop := dot_step * lerpf(0.34, 0.72, _unit(route_seed + 73.0))
			var side_nudge := -side * dot_step * lerpf(0.04, 0.20, _unit(route_seed + 79.0))
			return destination + Vector2(side_nudge, bottom_drop)
		if bottom_bias > 0.14:
			return destination + Vector2(-side * dot_step * lerpf(0.22, 0.42, _unit(route_seed + 83.0)), dot_step * lerpf(0.02, 0.18, _unit(route_seed + 89.0)))
		return destination

	func _collect_branch_path(start: Vector2, arrival: Vector2, destination: Vector2, route_seed: float, next_dots: Array) -> void:
		var horizontal := absf(arrival.x - start.x)
		var vertical := absf(arrival.y - start.y)
		var side := signf(arrival.x - start.x)
		if absf(side) < 0.001:
			side = 1.0 if _unit(route_seed + 17.0) > 0.5 else -1.0
		var y_direction := signf(destination.y - start.y)
		if absf(y_direction) < 0.001:
			y_direction = -1.0
		var trunk_launch := clampf(absf(vertical) * 0.62 + horizontal * 0.08, dot_step * 1.05, dot_step * 2.45)
		var destination_ease := clampf(absf(vertical) * 0.34 + horizontal * 0.16, dot_step * 0.72, dot_step * 1.95)
		var s_curve := _unit(route_seed + 97.0) > 0.48
		var s_strength := dot_step * lerpf(0.32, 0.78, _unit(route_seed + 101.0))
		var control_a := start + Vector2(side * horizontal * (0.08 if not s_curve else -0.24) + lerpf(-6.0, 6.0, _unit(route_seed + 19.0)), y_direction * trunk_launch)
		var control_b := arrival + Vector2(-side * horizontal * (0.18 if not s_curve else 0.44), -y_direction * destination_ease)
		_collect_sampled_dotted_path(start, arrival, route_seed, next_dots, func(t: float) -> Vector2:
			var q := 1.0 - t
			var sag := sin(t * PI) * dot_step * lerpf(0.06, 0.18, _unit(route_seed + 31.0))
			var point := q * q * q * start + 3.0 * q * q * t * control_a + 3.0 * q * t * t * control_b + t * t * t * arrival
			if s_curve:
				point.x += sin(t * TAU) * s_strength
			point.y += sag
			return point
		)

	func _collect_arrival_tail(start: Vector2, destination: Vector2, route_seed: float, next_dots: Array) -> void:
		var control := start.lerp(destination, 0.68) + Vector2(lerpf(-7.0, 7.0, _unit(route_seed + 3.0)), dot_step * lerpf(-0.04, 0.12, _unit(route_seed + 5.0)))
		_collect_sampled_dotted_path(start, destination, route_seed, next_dots, func(t: float) -> Vector2:
			var q := 1.0 - t
			return q * q * start + 2.0 * q * t * control + t * t * destination
		)

	func _obstacle_rect_for_segment(start: Vector2, destination: Vector2) -> Variant:
		for raw_obstacle_rect in obstacle_rects:
			if not raw_obstacle_rect is Rect2:
				continue
			var rect := (raw_obstacle_rect as Rect2).grow(dot_radius * 0.72)
			for i in range(1, 18):
				var t := float(i) / 18.0
				var point := start.lerp(destination, t)
				if rect.has_point(point):
					return raw_obstacle_rect
		return null

	func _obstacle_rect_near_point(point: Vector2) -> Variant:
		for raw_obstacle_rect in obstacle_rects:
			if raw_obstacle_rect is Rect2 and (raw_obstacle_rect as Rect2).grow(dot_step * 0.45).has_point(point):
				return raw_obstacle_rect
		return null

	func _detour_side_for_obstacle(rect: Rect2, route_seed: float) -> float:
		var center_delta := rect.get_center().x - origin.x
		if absf(center_delta) > dot_step * 0.28:
			return -signf(center_delta)
		return -1.0 if _unit(route_seed + 113.0) < 0.5 else 1.0

	func _collect_sampled_dotted_path(start: Vector2, _destination: Vector2, route_seed: float, next_dots: Array, sampler: Callable) -> void:
		var previous := start
		var distance_bank := 0.0
		var dot_index := 0
		for i in range(1, 80):
			var t := float(i) / 79.0
			var point := sampler.call(t) as Vector2
			var segment := point - previous
			var segment_length := segment.length()
			var next_step := dot_step * lerpf(0.78, 1.24, _unit(route_seed + float(dot_index) * 9.13))
			while distance_bank + segment_length >= next_step and segment_length > 0.001:
				var needed := next_step - distance_bank
				var ratio := needed / segment_length
				var dot := previous + segment * ratio
				var direction := segment.normalized()
				var normal := Vector2(-direction.y, direction.x)
				var scatter := normal * lerpf(-23.0, 23.0, _unit(route_seed + float(dot_index) * 13.71))
				scatter += direction * lerpf(-12.0, 12.0, _unit(route_seed + float(dot_index) * 17.89))
				var radius := dot_radius * lerpf(0.90, 1.14, _unit(route_seed + float(dot_index) * 19.41))
				var fill := _path_dot_color(route_seed, dot_index)
				var dot_center := dot + scatter
				_add_or_merge_dot(next_dots, {"center": dot_center, "radius": radius, "fill": fill})
				_add_path_clump_dots(next_dots, dot_center, radius, direction, normal, route_seed, dot_index)
				_add_tiny_path_dots(next_dots, dot_center, radius, route_seed, dot_index)
				dot_index += 1
				previous = dot
				segment = point - previous
				segment_length = segment.length()
				distance_bank = 0.0
				next_step = dot_step * lerpf(0.78, 1.24, _unit(route_seed + float(dot_index) * 9.13))
			distance_bank += segment_length
			previous = point

	func _add_or_merge_dot(dot_list: Array, dot: Dictionary) -> void:
		var center := dot.get("center", Vector2.ZERO) as Vector2
		var radius := float(dot.get("radius", dot_radius))
		if _dot_hits_obstacle_rect(center, radius):
			return
		_add_or_merge_unblocked_dot(dot_list, dot)

	func _add_terminal_dot(center: Vector2, route_seed: float, next_dots: Array) -> void:
		var radius := dot_radius * lerpf(0.94, 1.08, _unit(route_seed + 41.0))
		var fill := stone_color if _unit(route_seed + 59.0) > 0.78 else _varied_path_color(route_seed + 59.0)
		_add_or_merge_unblocked_dot(next_dots, {"center": center, "radius": radius, "fill": fill})
		_add_tiny_path_dots(next_dots, center, radius, route_seed + 91.0, 0)

	func _path_dot_color(route_seed: float, dot_index: int) -> Color:
		var dot_seed := route_seed + float(dot_index) * 29.33
		if _unit(dot_seed) > 0.88:
			return stone_color
		return _varied_path_color(dot_seed)

	func _varied_path_color(noise_seed: float) -> Color:
		var low := Color("#94683e")
		var high := Color("#bd8851")
		return low.lerp(high, _unit(noise_seed + 7.17))

	func _add_path_clump_dots(next_dots: Array, center: Vector2, radius: float, direction: Vector2, normal: Vector2, route_seed: float, dot_index: int) -> void:
		if _unit(route_seed + float(dot_index) * 23.61) < 0.28:
			return
		var count := 1 + int(_unit(route_seed + float(dot_index) * 47.31) > 0.62)
		for clump_index in range(count):
			var clump_seed := route_seed + float(dot_index) * 71.29 + float(clump_index) * 17.41
			var side := -1.0 if _unit(clump_seed + 1.0) < 0.5 else 1.0
			var offset := normal * side * radius * lerpf(0.32, 0.76, _unit(clump_seed + 2.0))
			offset += direction * radius * lerpf(-0.46, 0.54, _unit(clump_seed + 3.0))
			var clump_center := center + offset
			var clump_radius := radius * lerpf(0.58, 0.88, _unit(clump_seed + 4.0))
			if _dot_hits_obstacle_rect(clump_center, clump_radius):
				continue
			_add_unmerged_dot(next_dots, {"center": clump_center, "radius": clump_radius, "fill": _varied_path_color(clump_seed + 5.0), "keep_separate": true})

	func _add_tiny_path_dots(next_dots: Array, center: Vector2, radius: float, route_seed: float, dot_index: int) -> void:
		if _unit(route_seed + float(dot_index) * 31.7) < 0.38:
			return
		var count := 1 + int(_unit(route_seed + float(dot_index) * 43.9) > 0.72)
		for tiny_index in range(count):
			var tiny_seed := route_seed + float(dot_index) * 67.3 + float(tiny_index) * 19.1
			var angle := TAU * _unit(tiny_seed)
			var distance := radius * lerpf(0.72, 1.34, _unit(tiny_seed + 3.0))
			var tiny_radius := radius * lerpf(0.18, 0.31, _unit(tiny_seed + 5.0))
			var tiny_center := center + Vector2(cos(angle), sin(angle) * dot_height_scale * 1.6) * distance
			if _dot_hits_obstacle_rect(tiny_center, tiny_radius):
				continue
			var fill := stone_color if _unit(tiny_seed + 11.0) > 0.82 else _varied_path_color(tiny_seed + 13.0)
			_add_unmerged_dot(next_dots, {"center": tiny_center, "radius": tiny_radius, "fill": fill, "keep_separate": true})

	func _add_unmerged_dot(dot_list: Array, dot: Dictionary) -> void:
		dot_list.append(dot)

	func _add_or_merge_unblocked_dot(dot_list: Array, dot: Dictionary) -> void:
		var center := dot.get("center", Vector2.ZERO) as Vector2
		var radius := float(dot.get("radius", dot_radius))
		for i in range(dot_list.size()):
			var existing := dot_list[i] as Dictionary
			if bool(existing.get("keep_separate", false)) or bool(dot.get("keep_separate", false)):
				continue
			var existing_center := existing.get("center", Vector2.ZERO) as Vector2
			var existing_radius := float(existing.get("radius", dot_radius))
			if not _dot_rect(dot, 5.0).intersects(_dot_rect(existing, 5.0)):
				continue
			if center.distance_to(existing_center) > maxf(radius, existing_radius) * 0.84:
				continue
			var radius_weight := radius * radius
			var existing_weight := existing_radius * existing_radius
			existing["center"] = (existing_center * existing_weight + center * radius_weight) / (existing_weight + radius_weight)
			existing["radius"] = maxf(existing_radius, radius) + minf(existing_radius, radius) * 0.05
			if dot.get("fill", path_color) == stone_color or existing.get("fill", path_color) == stone_color:
				existing["fill"] = stone_color
			dot_list[i] = existing
			return
		dot_list.append(dot)

	func _merge_overlapping_dots(next_dots: Array) -> void:
		var changed := true
		var guard := 0
		while changed and guard < 12:
			changed = false
			guard += 1
			var i := 0
			while i < next_dots.size():
				var j := i + 1
				while j < next_dots.size():
					var a := next_dots[i] as Dictionary
					var b := next_dots[j] as Dictionary
					if bool(a.get("keep_separate", false)) or bool(b.get("keep_separate", false)):
						j += 1
						continue
					if _dot_rect(a, -3.0).intersects(_dot_rect(b, -3.0)):
						var a_radius := float(a.get("radius", dot_radius))
						var b_radius := float(b.get("radius", dot_radius))
						var a_weight := a_radius * a_radius
						var b_weight := b_radius * b_radius
						a["center"] = ((a.get("center", Vector2.ZERO) as Vector2) * a_weight + (b.get("center", Vector2.ZERO) as Vector2) * b_weight) / (a_weight + b_weight)
						a["radius"] = maxf(a_radius, b_radius) + minf(a_radius, b_radius) * 0.08
						if a.get("fill", path_color) == stone_color or b.get("fill", path_color) == stone_color:
							a["fill"] = stone_color
						next_dots[i] = a
						next_dots.remove_at(j)
						changed = true
						continue
					j += 1
				i += 1

	func _draw_path_dot(dot: Dictionary) -> void:
		var center := dot.get("center", Vector2.ZERO) as Vector2
		var radius := float(dot.get("radius", dot_radius))
		var fill := dot.get("fill", path_color) as Color
		var patch_seed := center.x * 0.013 + center.y * 0.019 + radius * 0.071
		_draw_dirt_patch(center, radius, radius * dot_height_scale, fill, patch_seed)

	func _draw_dirt_patch(center: Vector2, radius_x: float, radius_y: float, color: Color, noise_seed: float) -> void:
		var underpaint := color.lerp(Color("#7b5b3c"), 0.20)
		underpaint.a = 0.10
		_draw_irregular_oval(center, radius_x * 1.38, radius_y * 1.52, underpaint, noise_seed + 1.0, 0.22)
		var glaze := color.lerp(Color("#c1935d"), 0.15)
		glaze.a = 0.20
		_draw_irregular_oval(center + Vector2(lerpf(-2.5, 2.5, _unit(noise_seed + 2.0)), lerpf(-0.7, 0.7, _unit(noise_seed + 3.0))), radius_x * 1.12, radius_y * 1.16, glaze, noise_seed + 5.0, 0.15)
		var body := color
		body.a = 0.34
		_draw_irregular_oval(center, radius_x * 0.96, radius_y * 0.92, body, noise_seed + 11.0, 0.11)
		if _unit(noise_seed + 17.0) > 0.34:
			var warm := color.lerp(Color("#c48747"), 0.28)
			warm.a = 0.16
			var offset := Vector2(lerpf(-0.18, 0.20, _unit(noise_seed + 19.0)) * radius_x, lerpf(-0.18, 0.20, _unit(noise_seed + 23.0)) * radius_y)
			_draw_irregular_oval(center + offset, radius_x * lerpf(0.34, 0.56, _unit(noise_seed + 29.0)), radius_y * lerpf(0.44, 0.72, _unit(noise_seed + 31.0)), warm, noise_seed + 37.0, 0.18)
		if _unit(noise_seed + 41.0) > 0.46:
			var cool := color.lerp(Color("#85694f"), 0.32)
			cool.a = 0.12
			var offset := Vector2(lerpf(-0.24, 0.24, _unit(noise_seed + 43.0)) * radius_x, lerpf(-0.22, 0.22, _unit(noise_seed + 47.0)) * radius_y)
			_draw_irregular_oval(center + offset, radius_x * lerpf(0.22, 0.42, _unit(noise_seed + 53.0)), radius_y * lerpf(0.32, 0.58, _unit(noise_seed + 59.0)), cool, noise_seed + 61.0, 0.20)

	func _draw_irregular_oval(center: Vector2, radius_x: float, radius_y: float, color: Color, noise_seed: float, wobble: float) -> void:
		var oval_points := PackedVector2Array()
		var count := 32
		for i in range(count):
			var angle := TAU * float(i) / float(count)
			var edge_noise := lerpf(-wobble, wobble, _unit(noise_seed + float(i) * 5.31))
			var tangent_noise := lerpf(-wobble * 0.18, wobble * 0.18, _unit(noise_seed + float(i) * 7.77))
			var radial := 1.0 + edge_noise
			oval_points.append(center + Vector2(cos(angle + tangent_noise) * radius_x * radial, sin(angle + tangent_noise) * radius_y * radial))
		draw_colored_polygon(oval_points, color)

	func _dot_rect(dot: Dictionary, padding: float) -> Rect2:
		var center := dot.get("center", Vector2.ZERO) as Vector2
		var radius := float(dot.get("radius", dot_radius)) + padding
		var half_size := Vector2(radius, radius * dot_height_scale)
		return Rect2(center - half_size, half_size * 2.0)

	func _dot_hits_obstacle_rect(center: Vector2, radius: float) -> bool:
		var rect := Rect2(center - Vector2(radius + 6.0, radius * dot_height_scale + 6.0), Vector2((radius + 6.0) * 2.0, (radius * dot_height_scale + 6.0) * 2.0))
		for raw_obstacle_rect in obstacle_rects:
			if raw_obstacle_rect is Rect2 and rect.intersects(raw_obstacle_rect as Rect2):
				return true
		return false

	func _unit(noise_seed: float) -> float:
		return fposmod(sin(noise_seed * 12.9898 + 78.233) * 43758.5453, 1.0)


class HubBuildProgressBar:
	extends Label

	var remaining_seconds := -1
	var total_seconds := 15.0

	func _init() -> void:
		text = ""
		horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		autowrap_mode = TextServer.AUTOWRAP_OFF
		text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_color_override("font_color", Color.BLACK)
		add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.42))
		add_theme_constant_override("outline_size", 4)

	func set_progress(next_value: float) -> void:
		set_countdown(maxi(0, ceili((1.0 - clampf(next_value, 0.0, 1.0)) * total_seconds)))

	func set_total_seconds(seconds: float) -> void:
		total_seconds = maxf(0.001, seconds)

	func set_countdown(seconds: int) -> void:
		var clamped := maxi(0, seconds)
		if remaining_seconds == clamped:
			return
		remaining_seconds = clamped
		text = "%ss" % remaining_seconds

class MissionCooldownRing:
	extends Control

	var progress := 0.0

	func set_progress(next_progress: float) -> void:
		progress = clampf(next_progress, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.34
		var width := maxf(13.0, radius * 0.24)
		var outer_radius := radius + width * 0.72
		draw_circle(center + Vector2(0, 2), outer_radius, Color(0.04, 0.035, 0.03, 0.36))
		draw_circle(center, outer_radius, Color.BLACK)
		draw_circle(center, maxf(0.0, outer_radius - 9.0), Color("#6f6a5e"))
		draw_arc(center, radius, -PI * 0.5, PI * 1.5, 48, Color("#2e2a24"), width + 8.0, true)
		draw_arc(center, radius, -PI * 0.5, PI * 1.5, 48, Color("#a8a096"), width, true)
		if progress > 0.001:
			draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Color("#35d86d"), width, true)
		draw_circle(center, maxf(0.0, radius - width * 0.82), Color("#77736c"))

var host: Node

func setup(next_host: Node) -> void:
	host = next_host

func accept_event() -> void:
	host.accept_event()

# Hub-owned UI state.
var hub_detail_open := false
var hub_detail_transition_pending := false
var hub_module_buttons := {}
var hub_module_art := {}
var hub_module_progress_bars := {}
var hub_module_smoke_layers := {}
var hub_detail_panel: Control
var hub_detail_motion_tween: Tween
var hub_detail_title: Label
var hub_detail_body: Label
var hub_detail_cost: Label
var hub_detail_button: Button
var hub_detail_secondary_button: Button
var hub_detail_missions_box: VBoxContainer
var hub_build_mode := false
var hub_hotspot_hold_module_id := ""
var hub_hotspot_hold_pointer_id := -2
var hub_hotspot_hold_elapsed := 0.0
var hub_hotspot_hold_start_global := Vector2.ZERO
var hub_hotspot_hold_current_global := Vector2.ZERO
var hub_hotspot_hold_move_armed := false
var hub_hotspot_hold_circle: StopHoldCircle
var hub_drag_module_id := ""
var hub_drag_pointer_id := -1
var hub_drag_offset := Vector2.ZERO
var hub_drag_start_center := Vector2.ZERO
var hub_drag_valid := true
var hub_module_positions := {}
var hub_path_dots: HubPathDots
var hub_decor_items := []
var hub_decor_layout := []
var hub_mission_detail_wait_last_seconds := -1
var hub_hidden_process_unix := -1
var hub_tutorial_tip_seen := false
var hub_tutorial_host: Control
var hub_tutorial_tip_root: Control
var hub_tutorial_tip_tween: Tween
var hub_tutorial_info_button: Button
# Host state proxies.
var app_bold_font:
	get: return host.app_bold_font
	set(value): host.app_bold_font = value

var app_font:
	get: return host.app_font
	set(value): host.app_font = value

var action_cards:
	get: return host.action_cards
	set(value): host.action_cards = value

var ACTION_CARD_FACE_BORDER_Z_INDEX:
	get: return host.ACTION_CARD_FACE_BORDER_Z_INDEX
	set(value): host.ACTION_CARD_FACE_BORDER_Z_INDEX = value

var BOTTOM_NAV_HEIGHT:
	get: return NavigationShell.BOTTOM_NAV_HEIGHT

var COLOR_INK:
	get: return host.COLOR_INK
	set(value): host.COLOR_INK = value

var COLOR_MUTED:
	get: return host.COLOR_MUTED
	set(value): host.COLOR_MUTED = value

var COLOR_PANEL:
	get: return host.COLOR_PANEL
	set(value): host.COLOR_PANEL = value

var current_screen:
	get: return host.current_screen
	set(value): host.current_screen = value

var HUB_BARN_FAILURE_GAP_FACTORS:
	get: return HubRuntime.HUB_BARN_FAILURE_GAP_FACTORS

var HUB_BUILD_SECONDS:
	get: return HubRuntime.HUB_BUILD_SECONDS

var HUB_MISSION_COOLDOWN_SECONDS_BY_LEVEL:
	get: return HubRuntime.HUB_MISSION_COOLDOWN_SECONDS_BY_LEVEL

var HUB_MISSION_SLOT_COUNT_BY_LEVEL:
	get: return HubRuntime.HUB_MISSION_SLOT_COUNT_BY_LEVEL

var HUB_MISSION_STAMINA_REDUCTION_BY_LEVEL:
	get: return HubRuntime.HUB_MISSION_STAMINA_REDUCTION_BY_LEVEL

var HUB_MISSION_TIME_REDUCTION_BY_LEVEL:
	get: return HubRuntime.HUB_MISSION_TIME_REDUCTION_BY_LEVEL

var HUB_MISSION_XP_BONUS_BY_LEVEL:
	get: return HubRuntime.HUB_MISSION_XP_BONUS_BY_LEVEL

var HUB_MODULE_DEFS:
	get: return HubRuntime.HUB_MODULE_DEFS

var HUB_MODULE_MAX_LEVEL:
	get: return HubRuntime.HUB_MODULE_MAX_LEVEL

var HUB_MODULE_ORDER:
	get: return HubRuntime.HUB_MODULE_ORDER

var HUB_OVERLAY_Z:
	get: return host.HUB_OVERLAY_Z
	set(value): host.HUB_OVERLAY_Z = value

var HUB_POND_REGEN_BONUS_BY_LEVEL:
	get: return HubRuntime.HUB_POND_REGEN_BONUS_BY_LEVEL

var HUB_POSITION_ORDER:
	get: return HubRuntime.HUB_POSITION_ORDER

var last_hub_mission_completion_ceremony_text:
	get: return host.last_hub_mission_completion_ceremony_text
	set(value): host.last_hub_mission_completion_ceremony_text = value

var leaderboard_player_id:
	get: return host.leaderboard_profile.player_id
	set(value): host.leaderboard_profile.player_id = value

var MIN_MOBILE_BODY_FONT_SIZE:
	get: return host.MIN_MOBILE_BODY_FONT_SIZE
	set(value): host.MIN_MOBILE_BODY_FONT_SIZE = value

var MIN_MOBILE_INFO_TITLE_FONT_SIZE:
	get: return host.MIN_MOBILE_INFO_TITLE_FONT_SIZE
	set(value): host.MIN_MOBILE_INFO_TITLE_FONT_SIZE = value

var selected_skill_id:
	get: return host.selected_skill_id
	set(value): host.selected_skill_id = value

var SKILL_REWARD_FLOAT_GROUP:
	get: return RewardFeedbackSurface.SKILL_REWARD_FLOAT_GROUP

var skills_content:
	get: return host.skills_content
	set(value): host.skills_content = value

var stamina:
	get: return host.stamina
	set(value): host.stamina = value

# End host state proxies.

func _action_data(skill_id: String, action_id: String) -> Dictionary:
	return host._action_data(skill_id, action_id)

func _hub_runtime() -> HubRuntime:
	return host._hub_runtime()

func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	return host._label(text, font_size, color, align)

func _menu_button(text: String) -> Button:
	return host._menu_button(text)

func _set_label_text_if_changed(label: Label, next_text: String) -> void:
	host._app_lifecycle_runtime().set_label_text_if_changed(label, next_text)

func _set_canvas_item_alpha_if_changed(item: CanvasItem, next_alpha: float) -> void:
	host._app_lifecycle_runtime().set_canvas_item_alpha_if_changed(item, next_alpha)

func _set_canvas_item_visible_if_changed(item: CanvasItem, should_show: bool) -> void:
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(item, should_show)

func _skill_level(skill_id: String) -> int:
	return SkillState.host_skill_level(host, skill_id)

func _state_object_ref(value) -> Object:
	return host._app_lifecycle_runtime().state_object_ref(value)

func _surface_style(color: Color, radius: int, margin := 28, elevated := false) -> StyleBoxFlat:
	return host._surface_style(color, radius, margin, elevated)

func _theme_outline_color(outline_color: Color, fill_color: Color) -> Color:
	return host._theme_outline_color(outline_color, fill_color)

func _theme_surface_color(color: Color) -> Color:
	return host._theme_surface_color(color)

func _unix_now() -> int:
	return host._unix_now()

func _valid_control_ref(value) -> Control:
	return host._app_lifecycle_runtime().valid_control_ref(value)


func save_game() -> void:
	host.save_game()

# End host method proxies.





func _get(property: StringName):
	if host != null:
		return host.get(property)
	return null

func _set(property: StringName, value) -> bool:
	if host != null:
		host.set(property, value)
		return true
	return false
func _valid_hub_module_button(module_id: String) -> Control:
	var button := _state_object_ref(hub_module_buttons.get(module_id)) as Control
	if button == null:
		hub_module_buttons.erase(module_id)
	return button

func _valid_hub_module_art(module_id: String) -> TextureRect:
	var art := _state_object_ref(hub_module_art.get(module_id)) as TextureRect
	if art == null:
		hub_module_art.erase(module_id)
	return art

func _valid_hub_module_progress_bar(module_id: String) -> HubBuildProgressBar:
	var progress := _state_object_ref(hub_module_progress_bars.get(module_id)) as HubBuildProgressBar
	if progress == null:
		hub_module_progress_bars.erase(module_id)
	return progress

func _valid_hub_module_smoke_layers(module_id: String) -> Array:
	if not hub_module_smoke_layers.has(module_id):
		return []
	var raw_layers = hub_module_smoke_layers.get(module_id)
	if typeof(raw_layers) != TYPE_ARRAY:
		hub_module_smoke_layers.erase(module_id)
		return []
	var layers := raw_layers as Array
	var live_layers := []
	var pruned := false
	for raw_smoke in layers:
		var smoke := _state_object_ref(raw_smoke) as TextureRect
		if smoke == null:
			pruned = true
			continue
		live_layers.append(smoke)
	if live_layers.is_empty():
		hub_module_smoke_layers.erase(module_id)
	elif pruned:
		hub_module_smoke_layers[module_id] = live_layers
	return live_layers

func _clear_hub_page_control_refs() -> void:
	_kill_hub_detail_motion_tween()
	_kill_hub_tutorial_tip_tween()
	hub_module_buttons.clear()
	hub_module_art.clear()
	hub_module_progress_bars.clear()
	hub_module_smoke_layers.clear()
	hub_decor_items.clear()
	hub_path_dots = null
	hub_tutorial_host = null
	hub_tutorial_tip_root = null
	hub_tutorial_info_button = null
	hub_detail_panel = null
	hub_detail_title = null
	hub_detail_body = null
	hub_detail_cost = null
	hub_detail_button = null
	hub_detail_secondary_button = null
	hub_detail_missions_box = null

func _render_hub_page() -> void:
	_clear_hub_page_control_refs()
	var hub_frame := Control.new()
	hub_frame.anchor_left = 0.5
	hub_frame.anchor_right = 0.5
	hub_frame.anchor_top = 0.0
	hub_frame.anchor_bottom = 1.0
	hub_frame.offset_left = -HUB_FIELD_SIZE.x * 0.5
	hub_frame.offset_right = HUB_FIELD_SIZE.x * 0.5
	hub_frame.offset_top = 0.0
	hub_frame.offset_bottom = 0.0
	hub_frame.clip_contents = true
	hub_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	skills_content.add_child(hub_frame)
	hub_tutorial_host = hub_frame
	var grass_bg := ColorRect.new()
	grass_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	grass_bg.offset_top = -4
	grass_bg.offset_bottom = 4
	grass_bg.color = Color("#a7cb72")
	grass_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub_frame.add_child(grass_bg)
	var hub_viewport_height := maxf(1.0, host._current_canvas_size().y - float(BOTTOM_NAV_HEIGHT))
	var hub_render_size := Vector2(HUB_FIELD_SIZE.x, maxf(HUB_FIELD_SIZE.y, hub_viewport_height))
	var field := Control.new()
	field.position = Vector2.ZERO
	field.custom_minimum_size = hub_render_size
	field.size = hub_render_size
	field.clip_contents = true
	field.mouse_filter = Control.MOUSE_FILTER_PASS
	hub_frame.add_child(field)
	_add_hub_decor(field)
	hub_path_dots = HubPathDots.new()
	hub_path_dots.set_anchors_preset(Control.PRESET_FULL_RECT)
	hub_path_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub_path_dots.z_index = 4
	field.add_child(hub_path_dots)
	_update_hub_path_dots()
	_add_hub_trophy_display(field)
	var sorted_modules = HUB_MODULE_ORDER.duplicate()
	sorted_modules.sort_custom(func(a, b): return _hub_module_center(str(a)).y < _hub_module_center(str(b)).y)
	for module_id in sorted_modules:
		_add_hub_module(field, str(module_id))
	if hub_detail_open:
		_add_hub_detail_panel(field)
		_update_hub_detail_panel()
	_update_hub_decor_visibility()
	_add_hub_tutorial_info_button(hub_frame)

func _add_hub_tutorial_info_button(parent: Control) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var button := Button.new()
	hub_tutorial_info_button = button
	button.text = "i"
	button.tooltip_text = ""
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = -66
	button.offset_right = -22
	button.offset_top = 25
	button.offset_bottom = 69
	button.z_index = HUB_OVERLAY_Z + 70
	button.z_as_relative = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 29)
	if app_bold_font != null:
		button.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		button.add_theme_font_override("font", app_font)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", COLOR_INK)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_stylebox_override("normal", _hub_tutorial_info_button_style())
	button.add_theme_stylebox_override("hover", _hub_tutorial_info_button_style(false, true))
	button.add_theme_stylebox_override("pressed", _hub_tutorial_info_button_style(true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host.button_press_runtime.attach_button_depress_animation(button, 0.92)
	button.pressed.connect(_on_hub_tutorial_info_pressed)
	parent.add_child(button)

func _on_hub_tutorial_info_pressed() -> void:
	_show_hub_tutorial_tip(false)

func _maybe_show_hub_tutorial_tip() -> void:
	if current_screen != "hub" or not host._navigation_shell()._hub_unlocked() or hub_tutorial_tip_seen:
		return
	_show_hub_tutorial_tip(true)

func _show_hub_tutorial_tip(_auto_show := false) -> void:
	if current_screen != "hub":
		return
	var parent = hub_tutorial_host if hub_tutorial_host != null and is_instance_valid(hub_tutorial_host) else skills_content
	if parent == null or not is_instance_valid(parent):
		return
	if not hub_tutorial_tip_seen:
		hub_tutorial_tip_seen = true
		save_game()
	if hub_tutorial_tip_root == null or not is_instance_valid(hub_tutorial_tip_root):
		hub_tutorial_tip_root = _hub_tutorial_tip_control()
		parent.add_child(hub_tutorial_tip_root)
	if hub_tutorial_tip_root == null or not is_instance_valid(hub_tutorial_tip_root) or hub_tutorial_tip_root.is_queued_for_deletion():
		hub_tutorial_tip_root = null
		return
	_kill_hub_tutorial_tip_tween()
	_set_canvas_item_visible_if_changed(hub_tutorial_tip_root, true)
	_set_canvas_item_alpha_if_changed(hub_tutorial_tip_root, 0.0)
	hub_tutorial_tip_tween = create_tween()
	hub_tutorial_tip_tween.tween_property(hub_tutorial_tip_root, "modulate:a", 1.0, HUB_TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hub_tutorial_tip_tween.finished.connect(_finish_hub_tutorial_tip_tween)

func _hub_tutorial_tip_control() -> Control:
	var root = Control.new()
	root.name = "HubTutorialTip"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = HUB_OVERLAY_Z + 80
	root.z_as_relative = false

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -BOTTOM_NAV_HEIGHT
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.custom_minimum_size = Vector2(1040, 0)
	stack.add_theme_constant_override("separation", 23)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(stack)

	var title := _label(HUB_TUTORIAL_TITLE, 63, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_outline_color", COLOR_INK)
	title.add_theme_constant_override("outline_size", 23)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title)

	var body := _label(HUB_TUTORIAL_BODY, 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_color_override("font_outline_color", COLOR_INK)
	body.add_theme_constant_override("outline_size", 19)
	body.add_theme_constant_override("line_spacing", 15)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(body)
	return root

func _maybe_dismiss_hub_tutorial_tip_for_input(event: InputEvent) -> void:
	if current_screen != "hub" or not _hub_tutorial_tip_visible():
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_dismiss_hub_tutorial_tip()
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_dismiss_hub_tutorial_tip()
	elif event is InputEventScreenDrag:
		_dismiss_hub_tutorial_tip()

func _dismiss_hub_tutorial_tip() -> void:
	if hub_tutorial_tip_root == null or not is_instance_valid(hub_tutorial_tip_root) or hub_tutorial_tip_root.is_queued_for_deletion():
		hub_tutorial_tip_root = null
		return
	var root = hub_tutorial_tip_root
	_kill_hub_tutorial_tip_tween()
	hub_tutorial_tip_tween = create_tween()
	hub_tutorial_tip_tween.tween_property(root, "modulate:a", 0.0, HUB_TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hub_tutorial_tip_tween.tween_callback(_finish_hub_tutorial_tip_hide.bind(root.get_instance_id()))

func _finish_hub_tutorial_tip_hide(root_id: int) -> void:
	var root = _valid_control_ref(instance_from_id(root_id))
	if root != null and not root.is_queued_for_deletion():
		_set_canvas_item_visible_if_changed(root, false)
		root.queue_free()
	if hub_tutorial_tip_root == root:
		hub_tutorial_tip_root = null
	hub_tutorial_tip_tween = null

func _hub_tutorial_tip_visible() -> bool:
	return (
		hub_tutorial_tip_root != null
		and is_instance_valid(hub_tutorial_tip_root)
		and not hub_tutorial_tip_root.is_queued_for_deletion()
		and hub_tutorial_tip_root.visible
		and hub_tutorial_tip_root.modulate.a > 0.01
	)

func _kill_hub_tutorial_tip_tween() -> void:
	if hub_tutorial_tip_tween != null and hub_tutorial_tip_tween.is_valid():
		hub_tutorial_tip_tween.kill()
	hub_tutorial_tip_tween = null

func _finish_hub_tutorial_tip_tween() -> void:
	hub_tutorial_tip_tween = null

func _add_hub_decor(parent: Control) -> void:
	_ensure_hub_decor_layout()
	var sorted_layout = hub_decor_layout.duplicate()
	sorted_layout.sort_custom(func(a, b): return _hub_decor_entry_base_y(a) < _hub_decor_entry_base_y(b))
	for raw_entry in sorted_layout:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry := raw_entry as Dictionary
		var decor_type := str(entry.get("type", "decor"))
		var index := int(entry.get("index", 0))
		var decor_position := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		var display_size := Vector2(float(entry.get("w", 85.0)), float(entry.get("h", 85.0)))
		var item: TextureRect
		if decor_type == "tree":
			item = _hub_sheet_image("res://assets/content/hub/hub-tree-sheet.png", clampi(index, 0, 5), Vector2(512, 512), display_size)
		else:
			item = _hub_sheet_image("res://assets/content/hub/hub-decor-sheet.png", clampi(index, 0, 15), Vector2(256, 256), display_size)
		item.position = decor_position
		item.z_index = _hub_decor_depth_z_index(decor_position, display_size)
		parent.add_child(item)
		_register_hub_decor_item(item)

func _ensure_hub_decor_layout() -> void:
	if not hub_decor_layout.is_empty():
		return
	hub_decor_layout = _generate_hub_decor_layout()
	save_game()

func _generate_hub_decor_layout() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _hub_decor_seed()
	var layout := []
	for i in range(9):
		var decor_size := rng.randf_range(115.0, 195.0)
		var display_size := Vector2(decor_size, decor_size)
		layout.append(_hub_decor_entry("tree", rng.randi_range(0, 5), _hub_find_decor_position(layout, "tree", display_size, rng, true), display_size))
	var weighted_decor := [0, 0, 0, 1, 1, 2, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
	for i in range(54):
		var index := int(weighted_decor[rng.randi_range(0, weighted_decor.size() - 1)])
		var decor_size := rng.randf_range(59.0, 95.0)
		if index >= 4 and index <= 6:
			decor_size = rng.randf_range(72.5, 110.0)
		elif index >= 12:
			decor_size = rng.randf_range(80.0, 117.5)
		var display_size := Vector2(decor_size, decor_size)
		layout.append(_hub_decor_entry("decor", index, _hub_find_decor_position(layout, "decor", display_size, rng, false), display_size))
	return layout

func _hub_decor_entry(decor_type: String, index: int, decor_position: Vector2, display_size: Vector2) -> Dictionary:
	return {
		"type": decor_type,
		"index": index,
		# Keep legacy 4K integer quantization after the 0.5 layout migration.
		# Rounding directly to native 1080 pixels changes collision outcomes and
		# causes the seeded decoration generator to produce a different map.
		"x": round(decor_position.x * 2.0) * 0.5,
		"y": round(decor_position.y * 2.0) * 0.5,
		"w": round(display_size.x * 2.0) * 0.5,
		"h": round(display_size.y * 2.0) * 0.5
	}

func _hub_decor_entry_base_y(raw_entry: Variant) -> float:
	if typeof(raw_entry) != TYPE_DICTIONARY:
		return 0.0
	var entry := raw_entry as Dictionary
	return float(entry.get("y", 0.0)) + float(entry.get("h", 85.0)) * 0.86

func _hub_decor_depth_z_index(decor_position: Vector2, display_size: Vector2) -> int:
	var base_y := decor_position.y + display_size.y * 0.86
	return 5 + int(clampf(base_y / 12.0, 0.0, 130.0))

func _hub_random_decor_position(rng: RandomNumberGenerator, display_size: Vector2, tree := false) -> Vector2:
	var margin := 23.0 if tree else 12.0
	var min_x := margin
	var max_x := maxf(min_x, HUB_FIELD_SIZE.x - display_size.x - margin)
	var min_y := 40.0
	var max_y := maxf(min_y, HUB_FIELD_SIZE.y - ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT - display_size.y - (37.0 if tree else 20.0))
	var x := rng.randf_range(min_x, max_x)
	var y := rng.randf_range(min_y, max_y)
	if tree and rng.randf() < 0.58:
		if rng.randf() < 0.5:
			x = rng.randf_range(min_x, minf(max_x, min_x + 115.0))
		else:
			x = rng.randf_range(maxf(min_x, max_x - 115.0), max_x)
	return Vector2(x, y)

func _hub_clamp_decor_position(decor_type: String, decor_position: Vector2, display_size: Vector2) -> Vector2:
	var margin := 23.0 if decor_type == "tree" else 12.0
	var max_x := maxf(margin, HUB_FIELD_SIZE.x - display_size.x - margin)
	var max_y := maxf(40.0, HUB_FIELD_SIZE.y - ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT - display_size.y - (37.0 if decor_type == "tree" else 20.0))
	return Vector2(
		clampf(decor_position.x, margin, max_x),
		clampf(decor_position.y, 40.0, max_y)
	)

func _hub_find_decor_position(existing_layout: Array, decor_type: String, display_size: Vector2, rng: RandomNumberGenerator, tree := false, preferred_position: Variant = null) -> Vector2:
	if preferred_position is Vector2:
		var preferred := _hub_clamp_decor_position(decor_type, preferred_position as Vector2, display_size)
		if _hub_decor_position_clear(existing_layout, decor_type, preferred, display_size):
			return preferred
	var attempts := 70 if tree else 34
	var fallback := _hub_random_decor_position(rng, display_size, tree)
	for _i in range(attempts):
		var candidate := _hub_random_decor_position(rng, display_size, tree)
		fallback = candidate
		if _hub_decor_position_clear(existing_layout, decor_type, candidate, display_size):
			return candidate
	return fallback

func _hub_decor_position_clear(existing_layout: Array, decor_type: String, decor_position: Vector2, display_size: Vector2) -> bool:
	var rect := _hub_decor_block_rect(decor_type, decor_position, display_size)
	for raw_entry in existing_layout:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry := raw_entry as Dictionary
		var other_type := str(entry.get("type", "decor"))
		var other_size := Vector2(float(entry.get("w", 85.0)), float(entry.get("h", 85.0)))
		var other_position := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		var other_rect := _hub_decor_block_rect(other_type, other_position, other_size)
		if rect.intersects(other_rect):
			return false
	return true

func _hub_decor_block_rect(decor_type: String, decor_position: Vector2, display_size: Vector2) -> Rect2:
	var block_scale := Vector2(0.54, 0.46)
	var center_ratio := Vector2(0.50, 0.62)
	if decor_type == "tree":
		block_scale = Vector2(0.70, 0.74)
		center_ratio = Vector2(0.50, 0.56)
	var block_size := Vector2(maxf(display_size.x * block_scale.x, 41.0), maxf(display_size.y * block_scale.y, 36.0))
	var center := decor_position + display_size * center_ratio
	return Rect2(center - block_size * 0.5, block_size)

func _hub_decor_seed() -> int:
	var basis := str(leaderboard_player_id)
	if basis.is_empty():
		basis = "%s:%s:%s" % [SaveRuntime.SAVE_PATH, OS.get_unique_id(), _unix_now()]
	var decor_hash := 2166136261
	for i in range(basis.length()):
		decor_hash = int((decor_hash ^ basis.unicode_at(i)) * 16777619) & 0x7fffffff
	return maxi(1, decor_hash)

func _restore_hub_decor_layout(raw_layout: Variant, pre_migration_layout := false) -> void:
	hub_decor_layout = _normalized_hub_decor_layout(raw_layout, pre_migration_layout)

func _normalized_hub_decor_layout(raw_layout: Variant, pre_migration_layout := false) -> Array:
	var normalized := []
	if typeof(raw_layout) != TYPE_ARRAY:
		return normalized
	var rng := RandomNumberGenerator.new()
	rng.seed = _hub_decor_seed() + 101
	for raw_entry in raw_layout as Array:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry := raw_entry as Dictionary
		var decor_type := str(entry.get("type", "decor"))
		if decor_type != "tree" and decor_type != "decor":
			continue
		var max_index := 5 if decor_type == "tree" else 15
		var layout_scale := 0.5 if pre_migration_layout else 1.0
		var display_size := Vector2(
			clampf(float(entry.get("w", 85.0)) * layout_scale, 40.0, 230.0),
			clampf(float(entry.get("h", 85.0)) * layout_scale, 40.0, 230.0)
		)
		var raw_position := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))) * layout_scale
		var decor_position := _hub_find_decor_position(normalized, decor_type, display_size, rng, decor_type == "tree", raw_position)
		normalized.append({
			"type": decor_type,
			"index": clampi(int(entry.get("index", 0)), 0, max_index),
			"x": decor_position.x,
			"y": decor_position.y,
			"w": display_size.x,
			"h": display_size.y
		})
	return normalized

func _register_hub_decor_item(item: Control) -> void:
	hub_decor_items.append({"node": item, "rect": Rect2(item.position, item.custom_minimum_size)})

func _add_hub_trophy_display(parent: Control) -> void:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.clip_contents = false
	button.custom_minimum_size = Vector2(215, 150)
	button.size = button.custom_minimum_size
	button.position = _hub_module_center("trophy") - button.size * 0.5
	button.z_index = _hub_module_depth_z_index("trophy")
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.gui_input.connect(_on_hub_module_gui_input.bind("trophy"))
	parent.add_child(button)
	hub_module_buttons["trophy"] = button
	host._skill_detail_surface()._add_module_action_zones(button, ModuleUiRuntime.hub("trophy"))
	var platform := TextureRect.new()
	platform.texture = host.visual_texture_cache._texture_or_visual_fallback("res://assets/content/hub/hub-trophy-platform.png")
	platform.set_anchors_preset(Control.PRESET_FULL_RECT)
	platform.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	platform.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	platform.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(platform)
	var trophy_def := _hub_best_trophy_def()
	if not trophy_def.is_empty():
		var trophy := TextureRect.new()
		trophy.texture = host.visual_texture_cache._spritesheet_or_visual_fallback(ThievingState.HEIST_TROPHY_SHEET, int(trophy_def.get("cell", 0)), ThievingState.HEIST_TROPHY_CELL)
		trophy.custom_minimum_size = Vector2(157.5, 157.5)
		trophy.size = trophy.custom_minimum_size
		trophy.position = Vector2((button.size.x - trophy.size.x) * 0.5, -58.0)
		trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trophy.z_index = 2
		button.add_child(trophy)

func _hub_module_build_remaining_seconds(module_id: String) -> int:
	return _hub_runtime().module_build_remaining_seconds(module_id)

func _add_hub_module(parent: Control, module_id: String) -> void:
	var def := HUB_MODULE_DEFS.get(module_id, {}) as Dictionary
	if def.is_empty():
		return
	var level := _hub_module_level(module_id)
	var building := _hub_module_building(module_id)
	var sprite_index := clampi(level, 0, int(def.get("cell_count", 5)) - 1)
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.clip_contents = false
	button.custom_minimum_size = def.get("size", Vector2(250, 250))
	button.size = button.custom_minimum_size
	button.position = _hub_module_center(module_id) - button.size * 0.5
	button.z_index = _hub_module_depth_z_index(module_id)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.gui_input.connect(_on_hub_module_gui_input.bind(module_id))
	parent.add_child(button)
	hub_module_buttons[module_id] = button
	host._skill_detail_surface()._add_module_action_zones(button, ModuleUiRuntime.hub(module_id))
	var visual_size := _hub_module_visual_size(module_id, sprite_index)
	var art := _hub_sheet_image(str(def.get("sheet", "")), sprite_index, Vector2(512, 512), visual_size)
	art.position = _hub_module_art_position(button.size, module_id, sprite_index, visual_size)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	button.add_child(art)
	hub_module_art[module_id] = art
	if building:
		var smoke_layers := []
		var smoke_specs := [
			{"frame": 0, "alpha": 1.0}
		]
		for spec in smoke_specs:
			var smoke_rect := _hub_module_build_smoke_rect(module_id)
			var smoke := _hub_build_smoke(int(spec.get("frame", 0)), smoke_rect.size)
			smoke.position = smoke_rect.position
			smoke.set_meta("hub_smoke_base_position", smoke.position)
			smoke.modulate.a = float(spec.get("alpha", 0.72))
			smoke.pivot_offset = smoke.size * 0.5
			smoke.z_index = button.z_index + 8
			parent.add_child(smoke)
			smoke_layers.append(smoke)
		hub_module_smoke_layers[module_id] = smoke_layers
		var progress := HubBuildProgressBar.new()
		progress.set_total_seconds(HUB_BUILD_SECONDS)
		progress.set_countdown(_hub_module_build_remaining_seconds(module_id))
		var progress_rect := _hub_module_build_progress_rect(module_id)
		progress.position = progress_rect.position
		progress.custom_minimum_size = progress_rect.size
		progress.size = progress_rect.size
		progress.z_index = button.z_index + 9
		_apply_hub_build_countdown_style(progress, progress_rect)
		parent.add_child(progress)
		hub_module_progress_bars[module_id] = progress

func _on_hub_module_gui_input(event: InputEvent, module_id: String) -> void:
	var button := _valid_hub_module_button(module_id)
	if button == null:
		_clear_hub_hotspot_hold()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			_begin_hub_hotspot_hold(module_id, mouse_event.global_position, -1)
		else:
			_finish_hub_hotspot_press(module_id, mouse_event.global_position, -1)
		accept_event()
	elif event is InputEventMouseMotion:
		if hub_hotspot_hold_module_id == module_id and hub_hotspot_hold_pointer_id < 0:
			_update_hub_hotspot_hold_position((event as InputEventMouseMotion).global_position)
			accept_event()
		elif hub_drag_module_id == module_id and hub_drag_pointer_id < 0:
			_drag_hub_module_to(button, (event as InputEventMouseMotion).global_position)
			accept_event()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_begin_hub_hotspot_hold(module_id, host._control_local_point_to_global(button, touch_event.position), touch_event.index)
		else:
			_finish_hub_hotspot_press(module_id, host._control_local_point_to_global(button, touch_event.position), touch_event.index)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if hub_hotspot_hold_module_id == module_id and hub_hotspot_hold_pointer_id == drag_event.index:
			_update_hub_hotspot_hold_position(host._control_local_point_to_global(button, drag_event.position))
			accept_event()
		elif hub_drag_module_id == module_id and hub_drag_pointer_id == drag_event.index:
			_drag_hub_module_to(button, host._control_local_point_to_global(button, drag_event.position))
			accept_event()

func _route_hub_hotspot_hold_input(event: InputEvent) -> bool:
	var module_id = hub_hotspot_hold_module_id
	if module_id.is_empty() and hub_drag_module_id.is_empty():
		return false
	if current_screen != "hub":
		_clear_hub_hotspot_hold()
		return false
	if module_id.is_empty():
		module_id = hub_drag_module_id
	var button := _valid_hub_module_button(module_id)
	if button == null:
		_clear_hub_hotspot_hold()
		return false
	if event is InputEventMouseMotion and hub_hotspot_hold_pointer_id < 0:
		_update_hub_hotspot_hold_position((event as InputEventMouseMotion).global_position)
		return true
	if event is InputEventMouseButton and hub_hotspot_hold_pointer_id < 0:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		if not mouse_event.pressed:
			_finish_hub_hotspot_press(module_id, mouse_event.global_position, -1)
		return true
	if event is InputEventScreenDrag and (event as InputEventScreenDrag).index == hub_hotspot_hold_pointer_id:
		_update_hub_hotspot_hold_position((event as InputEventScreenDrag).position)
		return true
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).index == hub_hotspot_hold_pointer_id:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			_finish_hub_hotspot_press(module_id, touch_event.position, touch_event.index)
		return true
	return false

func _begin_hub_hotspot_hold(module_id: String, global_point: Vector2, pointer_id: int) -> void:
	if current_screen != "hub" or hub_detail_transition_pending:
		return
	hub_hotspot_hold_module_id = module_id
	hub_hotspot_hold_pointer_id = pointer_id
	hub_hotspot_hold_elapsed = 0.0
	hub_hotspot_hold_start_global = global_point
	hub_hotspot_hold_current_global = global_point
	hub_hotspot_hold_move_armed = false

func _update_hub_hotspot_hold_position(global_point: Vector2) -> void:
	if hub_hotspot_hold_module_id.is_empty():
		return
	hub_hotspot_hold_current_global = global_point
	if hub_hotspot_hold_move_armed and hub_drag_module_id == hub_hotspot_hold_module_id:
		var button := _valid_hub_module_button(hub_drag_module_id)
		if button != null:
			_drag_hub_module_to(button, global_point)
		return
	if global_point.distance_to(hub_hotspot_hold_start_global) >= HUB_HOTSPOT_DRAG_START_SLOP:
		_arm_hub_hotspot_move_drag()
	else:
		_hide_hub_hotspot_hold_circle()

func _finish_hub_hotspot_press(module_id: String, global_point: Vector2, pointer_id: int) -> void:
	if hub_drag_module_id == module_id and hub_drag_pointer_id == pointer_id:
		_finish_hub_module_drag()
		_clear_hub_hotspot_hold()
		return
	if hub_hotspot_hold_module_id != module_id or hub_hotspot_hold_pointer_id != pointer_id:
		return
	var was_move_hold = hub_hotspot_hold_move_armed
	var start_global = hub_hotspot_hold_start_global
	_clear_hub_hotspot_hold()
	if was_move_hold:
		return
	if global_point.distance_to(start_global) > HUB_HOTSPOT_DRAG_START_SLOP:
		return
	if module_id == "trophy":
		_on_hub_trophy_pressed()
	else:
		_on_hub_module_pressed(module_id)

func _process_hub_hotspot_hold(delta: float) -> void:
	if hub_hotspot_hold_module_id.is_empty() or hub_hotspot_hold_move_armed:
		return
	if current_screen != "hub":
		_clear_hub_hotspot_hold()
		return
	if hub_hotspot_hold_pointer_id < 0 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_clear_hub_hotspot_hold()
		return
	hub_hotspot_hold_elapsed += delta
	_hide_hub_hotspot_hold_circle()

func _arm_hub_hotspot_move_drag() -> void:
	var module_id = hub_hotspot_hold_module_id
	var button := _valid_hub_module_button(module_id)
	if button == null:
		_clear_hub_hotspot_hold()
		return
	hub_hotspot_hold_move_armed = true
	hub_build_mode = false
	_hide_hub_hotspot_hold_circle()
	_start_hub_module_drag(module_id, button, hub_hotspot_hold_start_global, hub_hotspot_hold_pointer_id)
	_drag_hub_module_to(button, hub_hotspot_hold_current_global)

func _clear_hub_hotspot_hold() -> void:
	_hide_hub_hotspot_hold_circle()
	hub_hotspot_hold_module_id = ""
	hub_hotspot_hold_pointer_id = -2
	hub_hotspot_hold_elapsed = 0.0
	hub_hotspot_hold_start_global = Vector2.ZERO
	hub_hotspot_hold_current_global = Vector2.ZERO
	hub_hotspot_hold_move_armed = false

func _hide_hub_hotspot_hold_circle() -> void:
	if hub_hotspot_hold_circle != null and is_instance_valid(hub_hotspot_hold_circle) and not hub_hotspot_hold_circle.is_queued_for_deletion():
		_set_canvas_item_visible_if_changed(hub_hotspot_hold_circle, false)
		hub_hotspot_hold_circle.set_progress(0.0, 0.0, false)

func _start_hub_module_drag(module_id: String, button: Control, global_point: Vector2, pointer_id: int) -> void:
	hub_drag_module_id = module_id
	hub_drag_pointer_id = pointer_id
	hub_drag_start_center = _hub_module_center(module_id)
	hub_drag_valid = true
	var field_point := _hub_global_to_field_point(button, global_point)
	hub_drag_offset = field_point - _hub_module_center(module_id)
	hub_detail_open = false
	button.z_index = 60
	button.modulate = Color.WHITE
	_update_hub_build_overlays_position(module_id)
	_pop_hub_module(module_id)

func _drag_hub_module_to(button: Control, global_point: Vector2) -> void:
	if hub_drag_module_id.is_empty():
		return
	var field_point := _hub_global_to_field_point(button, global_point)
	var next_center = field_point - hub_drag_offset
	next_center = _clamp_hub_module_center(next_center)
	hub_drag_valid = _hub_module_position_valid(hub_drag_module_id, next_center)
	hub_module_positions[hub_drag_module_id] = next_center
	button.position = next_center - button.size * 0.5
	button.modulate = Color.WHITE if hub_drag_valid else Color(1.0, 0.02, 0.02, 1.0)
	_update_hub_build_overlays_position(hub_drag_module_id)
	_update_hub_path_dots()

func _finish_hub_module_drag() -> void:
	if hub_drag_module_id.is_empty():
		return
	var module_id = hub_drag_module_id
	var button := _valid_hub_module_button(module_id)
	if not hub_drag_valid:
		hub_module_positions[module_id] = hub_drag_start_center
		if button != null:
			button.position = hub_drag_start_center - button.size * 0.5
		_update_hub_build_overlays_position(module_id)
	if button != null:
		button.modulate = Color.WHITE
		button.z_index = _hub_module_depth_z_index(module_id)
	_update_hub_build_overlays_position(module_id)
	hub_drag_module_id = ""
	hub_drag_pointer_id = -1
	hub_drag_valid = true
	_update_hub_path_dots()
	if _hub_module_center(module_id) != hub_drag_start_center:
		save_game()

func _hub_global_to_field_point(button: Control, global_point: Vector2) -> Vector2:
	var parent = button.get_parent() as Control
	if parent == null:
		return global_point
	return parent.get_global_transform_with_canvas().affine_inverse() * global_point

func _hub_module_center(module_id: String) -> Vector2:
	if hub_module_positions.has(module_id):
		var raw_position = hub_module_positions[module_id]
		if raw_position is Vector2:
			return _clamp_hub_module_center(raw_position as Vector2)
	return _hub_default_module_center(module_id)

func _hub_default_module_center(module_id: String) -> Vector2:
	if module_id == "trophy":
		return _clamp_hub_module_center(HUB_TROPHY_DEFAULT_CENTER)
	if HUB_MODULE_DEFS.has(module_id):
		var raw_position = (HUB_MODULE_DEFS[module_id] as Dictionary).get("position", HUB_FIELD_SIZE * 0.5)
		if raw_position is Vector2:
			return _clamp_hub_module_center(raw_position as Vector2)
	return HUB_FIELD_SIZE * 0.5

func _clamp_hub_module_center(module_position: Vector2) -> Vector2:
	return Vector2(
		clampf(module_position.x, 80.0, HUB_FIELD_SIZE.x - 80.0),
		clampf(module_position.y, 90.0, HUB_FIELD_SIZE.y - ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT - HUB_MODULE_BOTTOM_DRAG_MARGIN)
	)

func _hub_module_position_valid(module_id: String, center: Vector2) -> bool:
	var rect := _hub_module_collision_rect_at(module_id, center, 4.0)
	for raw_other_id in HUB_POSITION_ORDER:
		var other_id := str(raw_other_id)
		if other_id == module_id:
			continue
		if rect.intersects(_hub_module_collision_rect(other_id, 4.0)):
			return false
	return true

func _hub_module_positions_for_save() -> Dictionary:
	return _hub_runtime().module_positions_for_save()

func _restore_hub_module_positions(raw_positions: Variant, pre_migration_layout := false) -> void:
	_hub_runtime().restore_module_positions(raw_positions, pre_migration_layout)

func _normalized_hub_module_positions(raw_positions: Variant) -> Dictionary:
	return _hub_runtime().normalized_module_positions(raw_positions)

func _validate_hub_module_positions() -> void:
	_hub_runtime().validate_module_positions()

func _hub_can_store_position(module_id: String) -> bool:
	return _hub_runtime().can_store_position(module_id)

func _update_hub_path_dots() -> void:
	if hub_path_dots == null or not is_instance_valid(hub_path_dots):
		return
	var targets := []
	for raw_module_id in HUB_MODULE_ORDER:
		var module_id = str(raw_module_id)
		targets.append({"target": _hub_path_target(module_id), "seed": _hub_route_seed(module_id)})
	hub_path_dots.set_paths(_hub_path_origin(), targets, _hub_path_blocker_rects())
	_update_hub_decor_visibility()

func _hub_path_origin() -> Vector2:
	return Vector2(HUB_FIELD_SIZE.x * 0.5, HUB_FIELD_SIZE.y + 110.0)

func _hub_route_seed(module_id: String) -> float:
	var route_seed := 0.0
	for i in range(module_id.length()):
		route_seed += float(module_id.unicode_at(i)) * float(i + 3) * 0.371
	return route_seed + 11.0

func _hub_path_blocker_rects() -> Array:
	var rects := []
	for raw_module_id in HUB_POSITION_ORDER:
		rects.append(_hub_module_path_blocker_rect(str(raw_module_id), 4.0))
	return rects

func _hub_path_target(module_id: String) -> Vector2:
	var center := _hub_module_center(module_id)
	var visual_size := _hub_current_module_visual_size(module_id)
	if module_id == "trophy":
		return center + Vector2(0, visual_size.y * 0.24)
	if module_id == "pond":
		return _hub_module_visible_art_rect(module_id).get_center()
	return center + Vector2(0, visual_size.y * 0.28)

func _hub_current_module_visual_size(module_id: String) -> Vector2:
	return _hub_module_visual_size(module_id, _hub_detail_sprite_index(module_id))

func _hub_module_visual_size(module_id: String, sprite_index := -1) -> Vector2:
	if module_id == "trophy":
		return Vector2(215, 150)
	if HUB_MODULE_DEFS.has(module_id):
		var def := HUB_MODULE_DEFS[module_id] as Dictionary
		if sprite_index >= 0 and def.has("visual_sizes"):
			var visual_sizes := def.get("visual_sizes", []) as Array
			if sprite_index < visual_sizes.size():
				return visual_sizes[sprite_index] as Vector2
		return def.get("visual_size", def.get("size", Vector2(250, 250))) as Vector2
	return Vector2(215, 150)

func _hub_module_art_position(button_size: Vector2, module_id: String, sprite_index: int, visual_size: Vector2) -> Vector2:
	var anchor := _hub_module_visual_anchor(module_id)
	var cell_offset := _hub_module_cell_bottom_offset(module_id, sprite_index)
	var scaled_offset := Vector2(
		cell_offset.x * visual_size.x / 512.0,
		cell_offset.y * visual_size.y / 512.0
	)
	return button_size * 0.5 + anchor - visual_size * 0.5 - scaled_offset

func _hub_module_visible_art_rect(module_id: String) -> Rect2:
	return _hub_module_visible_art_rect_at(module_id, _hub_module_center(module_id), _hub_detail_sprite_index(module_id))

func _hub_module_visible_art_rect_at(module_id: String, center: Vector2, sprite_index: int) -> Rect2:
	if not HUB_MODULE_DEFS.has(module_id):
		var fallback_size := _hub_module_visual_size(module_id, sprite_index)
		return Rect2(center - fallback_size * 0.5, fallback_size)
	var def := HUB_MODULE_DEFS[module_id] as Dictionary
	var button_size := def.get("size", Vector2(250, 250)) as Vector2
	var visual_size := _hub_module_visual_size(module_id, sprite_index)
	var art_position := center - button_size * 0.5 + _hub_module_art_position(button_size, module_id, sprite_index, visual_size)
	var bounds := Rect2(Vector2.ZERO, Vector2(512, 512))
	if def.has("visible_bounds"):
		var visible_bounds := def.get("visible_bounds", []) as Array
		if sprite_index >= 0 and sprite_index < visible_bounds.size():
			var raw_bounds = visible_bounds[sprite_index]
			if raw_bounds is Rect2:
				bounds = raw_bounds as Rect2
	var visual_scale := Vector2(visual_size.x / 512.0, visual_size.y / 512.0)
	return Rect2(art_position + bounds.position * visual_scale, bounds.size * visual_scale)

func _hub_module_visual_anchor(module_id: String) -> Vector2:
	if HUB_MODULE_DEFS.has(module_id):
		var def := HUB_MODULE_DEFS[module_id] as Dictionary
		var raw_anchor = def.get("visual_anchor", Vector2.ZERO)
		if raw_anchor is Vector2:
			return raw_anchor as Vector2
	return Vector2.ZERO

func _hub_module_cell_bottom_offset(module_id: String, sprite_index: int) -> Vector2:
	if HUB_MODULE_DEFS.has(module_id):
		var def := HUB_MODULE_DEFS[module_id] as Dictionary
		if def.has("cell_bottom_offsets"):
			var offsets := def.get("cell_bottom_offsets", []) as Array
			if sprite_index >= 0 and sprite_index < offsets.size():
				var raw_offset = offsets[sprite_index]
				if raw_offset is Vector2:
					return raw_offset as Vector2
	return Vector2.ZERO

func _hub_module_path_blocker_rect(module_id: String, padding: float) -> Rect2:
	var visual_size := _hub_current_module_visual_size(module_id)
	var target := _hub_path_target(module_id)
	if module_id == "pond":
		return _hub_module_collision_rect(module_id, padding)
	var blocker_size := Vector2(maxf(visual_size.x * 0.52, 95.0), maxf(visual_size.y * 0.16, 46.0))
	return Rect2(target - blocker_size * 0.5 - Vector2(padding, padding), blocker_size + Vector2(padding * 2.0, padding * 2.0))

func _hub_module_depth_z_index(module_id: String) -> int:
	return 12 + int(clampf(_hub_module_center(module_id).y / 9.0, 0.0, 180.0))

func _hub_module_collision_rect(module_id: String, padding: float) -> Rect2:
	return _hub_module_collision_rect_at(module_id, _hub_module_center(module_id), padding)

func _hub_module_collision_rect_at(module_id: String, center: Vector2, padding: float) -> Rect2:
	if module_id == "pond":
		var visible_rect := _hub_module_visible_art_rect_at(module_id, center, _hub_detail_sprite_index(module_id))
		var pond_size := Vector2(maxf(visible_rect.size.x * 0.62, 125.0), maxf(visible_rect.size.y * 0.18, 35.0))
		var pond_center := visible_rect.position + Vector2(visible_rect.size.x * 0.5, visible_rect.size.y * 0.86)
		return Rect2(pond_center - pond_size * 0.5 - Vector2(padding, padding), pond_size + Vector2(padding * 2.0, padding * 2.0))
	var placement_size := _hub_module_placement_size(module_id)
	var footprint_center := _hub_module_placement_center(module_id, center)
	return Rect2(footprint_center - placement_size * 0.5 - Vector2(padding, padding), placement_size + Vector2(padding * 2.0, padding * 2.0))

func _hub_module_build_progress_rect(module_id: String) -> Rect2:
	var smoke_rect := _hub_module_build_smoke_rect(module_id)
	var countdown_size := Vector2(
		clampf(smoke_rect.size.x * 0.54, 95.0, 130.0),
		clampf(smoke_rect.size.y * 0.28, 60.0, 72.0)
	)
	return Rect2(smoke_rect.get_center() - countdown_size * 0.5, countdown_size)

func _hub_module_build_smoke_rect(module_id: String) -> Rect2:
	var visible_rect := _hub_module_visible_art_rect(module_id)
	var smoke_size := clampf(visible_rect.size.x * 0.72, 175.0, 215.0)
	var center := visible_rect.get_center() + Vector2(0.0, -visible_rect.size.y * 0.08)
	return Rect2(center - Vector2(smoke_size, smoke_size) * 0.5, Vector2(smoke_size, smoke_size))

func _update_hub_build_overlays_position(module_id: String) -> void:
	var button := _valid_hub_module_button(module_id)
	var base_z := _hub_module_depth_z_index(module_id)
	if button != null:
		base_z = button.z_index
	var layers := _valid_hub_module_smoke_layers(module_id)
	if not layers.is_empty():
		var smoke_rect := _hub_module_build_smoke_rect(module_id)
		for raw_smoke in layers:
			var smoke := _state_object_ref(raw_smoke) as TextureRect
			if smoke == null:
				continue
			smoke.position = smoke_rect.position
			smoke.size = smoke_rect.size
			smoke.custom_minimum_size = smoke_rect.size
			smoke.pivot_offset = smoke.size * 0.5
			smoke.set_meta("hub_smoke_base_position", smoke_rect.position)
			smoke.z_index = base_z + 8
	var progress := _valid_hub_module_progress_bar(module_id)
	if progress != null:
		var progress_rect := _hub_module_build_progress_rect(module_id)
		progress.position = progress_rect.position
		progress.size = progress_rect.size
		progress.custom_minimum_size = progress_rect.size
		progress.z_index = base_z + 9
		_apply_hub_build_countdown_style(progress, progress_rect)

func _clear_hub_module_build_overlays(module_id: String) -> void:
	var progress := _valid_hub_module_progress_bar(module_id)
	if progress != null:
		progress.queue_free()
	hub_module_progress_bars.erase(module_id)
	for raw_smoke in _valid_hub_module_smoke_layers(module_id):
		var smoke := _state_object_ref(raw_smoke) as TextureRect
		if smoke != null:
			smoke.queue_free()
	hub_module_smoke_layers.erase(module_id)

func _refresh_hub_module_art(module_id: String) -> void:
	if not HUB_MODULE_DEFS.has(module_id):
		return
	var button := _valid_hub_module_button(module_id)
	var art := _valid_hub_module_art(module_id)
	if button == null or art == null:
		return
	var def := HUB_MODULE_DEFS[module_id] as Dictionary
	var sprite_index := clampi(_hub_module_level(module_id), 0, int(def.get("cell_count", 5)) - 1)
	var visual_size := _hub_module_visual_size(module_id, sprite_index)
	art.texture = _hub_sheet_or_visual_fallback(str(def.get("sheet", "")), sprite_index, Vector2(512, 512))
	art.custom_minimum_size = visual_size
	art.size = visual_size
	art.position = _hub_module_art_position(button.size, module_id, sprite_index, visual_size)
	button.z_index = _hub_module_depth_z_index(module_id)

func _hub_module_placement_size(module_id: String) -> Vector2:
	var visual_size := _hub_module_visual_size(module_id)
	if module_id == "trophy":
		return Vector2(maxf(visual_size.x * 0.58, 110.0), maxf(visual_size.y * 0.34, 48.0))
	if module_id == "pond":
		return Vector2(maxf(visual_size.x * 0.30, 125.0), maxf(visual_size.y * 0.07, 35.0))
	return Vector2(maxf(visual_size.x * 0.55, 125.0), maxf(visual_size.y * 0.22, 54.0))

func _hub_module_placement_center(module_id: String, center: Vector2) -> Vector2:
	var visual_size := _hub_module_visual_size(module_id)
	if module_id == "trophy":
		return center + Vector2(0.0, visual_size.y * 0.24)
	if module_id == "pond":
		return center + Vector2(-visual_size.x * 0.03, visual_size.y * 0.34)
	return center + Vector2(0.0, visual_size.y * 0.25)

func _hub_module_decor_clear_rect(module_id: String, padding: float) -> Rect2:
	var visual_size := _hub_module_visual_size(module_id)
	var center := _hub_module_center(module_id)
	var clear_size := visual_size
	if module_id == "trophy":
		clear_size = Vector2(maxf(visual_size.x * 1.10, 225.0), maxf(visual_size.y * 0.92, 140.0))
	elif module_id == "pond":
		var visible_rect := _hub_module_visible_art_rect(module_id)
		return visible_rect.grow(padding + 40.0)
	else:
		clear_size = Vector2(maxf(visual_size.x * 1.08, 295.0), maxf(visual_size.y * 0.90, 235.0))
	var clear_center := center + Vector2(0.0, visual_size.y * 0.11)
	return Rect2(clear_center - clear_size * 0.5 - Vector2(padding, padding), clear_size + Vector2(padding * 2.0, padding * 2.0))

func _update_hub_decor_visibility() -> void:
	if hub_decor_items.is_empty():
		return
	if current_screen != "hub":
		_clear_hub_page_control_refs()
		return
	var eaten_rects := []
	if hub_path_dots != null and is_instance_valid(hub_path_dots):
		eaten_rects.append_array(hub_path_dots.occupied_rects())
	for raw_module_id in HUB_POSITION_ORDER:
		eaten_rects.append(_hub_module_decor_clear_rect(str(raw_module_id), 32.0))
	var live_items := []
	for item in hub_decor_items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var item_dict := item as Dictionary
		var node := _state_object_ref(item_dict.get("node")) as Control
		if node == null:
			continue
		live_items.append(item)
		var rect := item_dict.get("rect", Rect2()) as Rect2
		var should_show_decor := true
		for raw_eaten_rect in eaten_rects:
			if raw_eaten_rect is Rect2 and rect.intersects(raw_eaten_rect as Rect2):
				should_show_decor = false
				break
		_set_hub_decor_visibility_state(node, should_show_decor, hub_drag_module_id.is_empty() and hub_hotspot_hold_module_id.is_empty())
	hub_decor_items = live_items

func _set_hub_decor_visibility_state(node: Control, should_show: bool, animate := true) -> void:
	if node == null or not is_instance_valid(node):
		return
	if not node.has_meta("hub_decor_visibility_initialized"):
		node.set_meta("hub_decor_visibility_initialized", true)
		node.set_meta("hub_decor_logical_visible", should_show)
		node.visible = should_show
		node.modulate.a = 1.0 if should_show else 0.0
		node.scale = Vector2.ONE
		return
	var previous_visible := bool(node.get_meta("hub_decor_logical_visible", node.visible))
	if previous_visible == should_show:
		return
	node.set_meta("hub_decor_logical_visible", should_show)
	host._app_lifecycle_runtime()._kill_meta_tween(node, "hub_decor_pop_tween")
	if not animate:
		node.visible = should_show
		node.modulate.a = 1.0 if should_show else 0.0
		node.scale = Vector2.ONE
		return
	node.pivot_offset = node.size * 0.5
	var tween := create_tween()
	node.set_meta("hub_decor_pop_tween", tween)
	if should_show:
		node.visible = true
		node.modulate.a = 0.0
		node.scale = Vector2(0.72, 0.72)
		tween.set_parallel(true)
		tween.tween_property(node, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "scale", Vector2(1.13, 1.13), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(node, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		node.visible = true
		node.modulate.a = 1.0
		node.scale = Vector2.ONE
		tween.set_parallel(true)
		tween.tween_property(node, "modulate:a", 0.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "scale", Vector2(0.68, 0.68), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(_finish_hub_decor_hide.bind(node.get_instance_id()))

func _finish_hub_decor_hide(node_id: int) -> void:
	var node := _valid_control_ref(instance_from_id(node_id))
	if node == null:
		return
	if bool(node.get_meta("hub_decor_logical_visible", false)):
		return
	node.visible = false

func _add_hub_detail_panel(parent: Control) -> void:
	if _hub_runtime().hub_selected_module_id == "mission":
		_add_hub_mission_board_panel(parent)
		return
	_add_hub_detail_dismiss_layer(parent)
	var layout := _hub_detail_bubble_layout(_hub_runtime().hub_selected_module_id)
	var panel_pos := layout.get("position", Vector2(295, 180)) as Vector2
	var panel_size := layout.get("size", Vector2(920, 430)) as Vector2
	hub_detail_panel = PanelContainer.new()
	hub_detail_panel.anchor_left = 0.0
	hub_detail_panel.anchor_right = 0.0
	hub_detail_panel.anchor_top = 0.0
	hub_detail_panel.anchor_bottom = 0.0
	hub_detail_panel.offset_left = panel_pos.x
	hub_detail_panel.offset_right = panel_pos.x + panel_size.x
	hub_detail_panel.offset_top = panel_pos.y
	hub_detail_panel.offset_bottom = panel_pos.y + panel_size.y
	hub_detail_panel.z_index = HUB_OVERLAY_Z + 3
	hub_detail_panel.add_theme_stylebox_override("panel", _hub_bubble_style())
	hub_detail_panel.gui_input.connect(_on_hub_detail_panel_gui_input)
	parent.add_child(hub_detail_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 21)
	margin.add_theme_constant_override("margin_right", 21)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 15)
	hub_detail_panel.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	margin.add_child(stack)
	hub_detail_title = _label("", 60, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	stack.add_child(hub_detail_title)
	hub_detail_body = _label("", 48, COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	hub_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(hub_detail_body)
	hub_detail_missions_box = VBoxContainer.new()
	hub_detail_missions_box.add_theme_constant_override("separation", 6)
	hub_detail_missions_box.visible = false
	stack.add_child(hub_detail_missions_box)
	hub_detail_cost = _label("", 52, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	stack.add_child(hub_detail_cost)
	hub_detail_button = _menu_button("")
	hub_detail_button.custom_minimum_size = Vector2(0, 63)
	hub_detail_button.add_theme_font_size_override("font_size", 48)
	hub_detail_button.pressed.connect(_upgrade_selected_hub_module)
	stack.add_child(hub_detail_button)
	hub_detail_secondary_button = _menu_button("")
	hub_detail_secondary_button.custom_minimum_size = Vector2(0, 55)
	hub_detail_secondary_button.add_theme_font_size_override("font_size", 48)
	hub_detail_secondary_button.pressed.connect(_jump_to_hub_mission_task)
	hub_detail_secondary_button.visible = false
	stack.add_child(hub_detail_secondary_button)

func _add_hub_mission_board_panel(parent: Control) -> void:
	_add_hub_detail_dismiss_layer(parent)
	var board = Control.new()
	board.anchor_left = 0.0
	board.anchor_right = 0.0
	board.anchor_top = 0.0
	board.anchor_bottom = 0.0
	board.custom_minimum_size = HUB_MISSION_BOARD_SIZE
	board.size = HUB_MISSION_BOARD_SIZE
	board.position = _hub_mission_board_target_position()
	board.z_index = HUB_OVERLAY_Z + 3
	board.z_as_relative = false
	board.mouse_filter = Control.MOUSE_FILTER_STOP
	board.gui_input.connect(_on_hub_detail_panel_gui_input)
	parent.add_child(board)
	hub_detail_panel = board

	var art := TextureRect.new()
	art.texture = host.visual_texture_cache._texture_or_visual_fallback(HUB_MISSION_BOARD_TEXTURE)
	art.position = Vector2.ZERO
	art.size = HUB_MISSION_BOARD_ART_SIZE
	art.custom_minimum_size = HUB_MISSION_BOARD_ART_SIZE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(art)

	var margin := MarginContainer.new()
	margin.position = Vector2.ZERO
	margin.size = HUB_MISSION_BOARD_ART_SIZE
	margin.custom_minimum_size = HUB_MISSION_BOARD_ART_SIZE
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_top", 115)
	margin.add_theme_constant_override("margin_bottom", 115)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(stack)

	hub_detail_title = _label("", 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	hub_detail_title.custom_minimum_size = Vector2(0, 61)
	hub_detail_title.add_theme_color_override("font_outline_color", Color.BLACK)
	hub_detail_title.add_theme_constant_override("outline_size", 14)
	hub_detail_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(hub_detail_title)

	hub_detail_body = _label("", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	hub_detail_body.custom_minimum_size = Vector2(0, 128)
	hub_detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hub_detail_body.add_theme_color_override("font_outline_color", Color.BLACK)
	hub_detail_body.add_theme_constant_override("outline_size", 10)
	hub_detail_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(hub_detail_body)

	var missions_scroll := MobileScrollContainer.new()
	missions_scroll.name = "MissionSlotsScroll"
	missions_scroll.custom_minimum_size = Vector2(0, 520)
	missions_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	missions_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	missions_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	missions_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	missions_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	stack.add_child(missions_scroll)

	hub_detail_missions_box = VBoxContainer.new()
	hub_detail_missions_box.add_theme_constant_override("separation", 7)
	hub_detail_missions_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hub_detail_missions_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hub_detail_missions_box.visible = false
	missions_scroll.add_child(hub_detail_missions_box)

	hub_detail_cost = _label("", MIN_MOBILE_BODY_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	hub_detail_cost.custom_minimum_size = Vector2(0, 0)
	hub_detail_cost.add_theme_color_override("font_outline_color", Color.BLACK)
	hub_detail_cost.add_theme_constant_override("outline_size", 5.5)
	hub_detail_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub_detail_cost.visible = false
	stack.add_child(hub_detail_cost)

	var button_holder := CenterContainer.new()
	button_holder.position = Vector2(0, HUB_MISSION_BOARD_BUTTON_Y)
	button_holder.size = Vector2(HUB_MISSION_BOARD_SIZE.x, 150)
	button_holder.custom_minimum_size = button_holder.size
	button_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(button_holder)

	hub_detail_button = _menu_button("")
	hub_detail_button.text = ""
	hub_detail_button.custom_minimum_size = Vector2(725, 150)
	hub_detail_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hub_detail_button.add_theme_font_size_override("font_size", 48)
	hub_detail_button.add_theme_color_override("font_disabled_color", Color.WHITE)
	hub_detail_button.add_theme_color_override("font_outline_color", Color.BLACK)
	hub_detail_button.add_theme_constant_override("outline_size", 8.5)
	hub_detail_button.pressed.connect(_upgrade_selected_hub_module)
	button_holder.add_child(hub_detail_button)

	var button_copy_margin := MarginContainer.new()
	button_copy_margin.name = "MissionUpgradeCopy"
	button_copy_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	button_copy_margin.add_theme_constant_override("margin_left", 17)
	button_copy_margin.add_theme_constant_override("margin_right", 17)
	button_copy_margin.add_theme_constant_override("margin_top", 5)
	button_copy_margin.add_theme_constant_override("margin_bottom", 5)
	button_copy_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hub_detail_button.add_child(button_copy_margin)
	var button_copy := VBoxContainer.new()
	button_copy.name = "Stack"
	button_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	button_copy.add_theme_constant_override("separation", 0)
	button_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_copy_margin.add_child(button_copy)
	var button_title := _label("", 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	button_title.name = "Title"
	button_title.add_theme_color_override("font_outline_color", Color.BLACK)
	button_title.add_theme_constant_override("outline_size", 10)
	button_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_copy.add_child(button_title)
	var button_cost := _label("", 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	button_cost.name = "Cost"
	button_cost.add_theme_color_override("font_outline_color", Color.BLACK)
	button_cost.add_theme_constant_override("outline_size", 7)
	button_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button_copy.add_child(button_cost)

	hub_detail_secondary_button = null

func _add_hub_detail_dismiss_layer(parent: Control) -> void:
	var dismiss_layer := Control.new()
	dismiss_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dismiss_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	dismiss_layer.z_index = HUB_OVERLAY_Z
	dismiss_layer.z_as_relative = false
	dismiss_layer.gui_input.connect(_on_hub_detail_dismiss_gui_input)
	parent.add_child(dismiss_layer)

func _on_hub_detail_dismiss_gui_input(event: InputEvent) -> void:
	if host._input_routing_shell()._is_primary_press_event(event):
		_close_hub_detail_popup()
		accept_event()

func _on_hub_detail_panel_gui_input(event: InputEvent) -> void:
	if not host._input_routing_shell()._is_primary_press_event(event):
		return
	if _hub_runtime().hub_selected_module_id == "mission":
		accept_event()
		return
	if hub_detail_button != null and is_instance_valid(hub_detail_button) and hub_detail_button.visible:
		if hub_detail_button.get_global_rect().has_point(hub_detail_button.get_global_mouse_position()):
			return
	if hub_detail_missions_box != null and is_instance_valid(hub_detail_missions_box) and hub_detail_missions_box.visible:
		if hub_detail_missions_box.get_global_rect().has_point(hub_detail_missions_box.get_global_mouse_position()):
			return
	if hub_detail_secondary_button != null and is_instance_valid(hub_detail_secondary_button) and hub_detail_secondary_button.visible:
		if hub_detail_secondary_button.get_global_rect().has_point(hub_detail_secondary_button.get_global_mouse_position()):
			return
	_close_hub_detail_popup()
	accept_event()

func _close_hub_detail_popup() -> void:
	if not hub_detail_open or hub_detail_transition_pending:
		return
	if _hub_runtime().hub_selected_module_id == "mission":
		hub_detail_transition_pending = true
		call_deferred("_apply_close_hub_mission_board_popup")
		return
	hub_detail_transition_pending = true
	call_deferred("_apply_close_hub_detail_popup")

func _apply_close_hub_mission_board_popup() -> void:
	if not hub_detail_open:
		hub_detail_transition_pending = false
		return
	if hub_detail_panel == null or not is_instance_valid(hub_detail_panel):
		_apply_close_hub_detail_popup()
		return
	_kill_hub_detail_motion_tween()
	var board = hub_detail_panel
	hub_detail_motion_tween = create_tween()
	hub_detail_motion_tween.tween_property(board, "position", _hub_mission_board_offscreen_position(), HUB_MISSION_BOARD_CLOSE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hub_detail_motion_tween.finished.connect(_finish_close_hub_detail_popup_tween)

func _apply_close_hub_detail_popup() -> void:
	hub_detail_transition_pending = false
	if not hub_detail_open:
		return
	hub_detail_open = false
	host._navigation_shell()._render_screen()

func _animate_hub_mission_board_open() -> void:
	if hub_detail_panel == null or not is_instance_valid(hub_detail_panel):
		hub_detail_transition_pending = false
		return
	_kill_hub_detail_motion_tween()
	var board = hub_detail_panel
	board.position = _hub_mission_board_offscreen_position()
	hub_detail_motion_tween = create_tween()
	hub_detail_motion_tween.tween_property(board, "position", _hub_mission_board_target_position(), HUB_MISSION_BOARD_OPEN_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hub_detail_motion_tween.finished.connect(_finish_open_hub_detail_popup_tween)

func _kill_hub_detail_motion_tween() -> void:
	if hub_detail_motion_tween != null and hub_detail_motion_tween.is_valid():
		hub_detail_motion_tween.kill()
	hub_detail_motion_tween = null

func _finish_close_hub_detail_popup_tween() -> void:
	hub_detail_motion_tween = null
	hub_detail_transition_pending = false
	if hub_detail_open:
		hub_detail_open = false
		host._navigation_shell()._render_screen()

func _finish_open_hub_detail_popup_tween() -> void:
	hub_detail_motion_tween = null
	hub_detail_transition_pending = false

func _hub_mission_board_target_position() -> Vector2:
	return Vector2((HUB_FIELD_SIZE.x - HUB_MISSION_BOARD_SIZE.x) * 0.5, HUB_MISSION_BOARD_TARGET_Y)

func _hub_mission_board_offscreen_position() -> Vector2:
	return _hub_mission_board_target_position() + Vector2(0, -HUB_MISSION_BOARD_SIZE.y - 60.0)

func _hub_detail_bubble_layout(module_id: String) -> Dictionary:
	var panel_size := Vector2(620, 325) if module_id == "mission" else Vector2(920, 430)
	var target := _hub_detail_target(module_id)
	var offset := Vector2(0, -340)
	if module_id == "trophy":
		offset = Vector2(-620, -360)
	elif HUB_MODULE_DEFS.has(module_id):
		offset = (HUB_MODULE_DEFS[module_id] as Dictionary).get("bubble_offset", offset) as Vector2
	var candidate_offsets := [
		offset,
		Vector2(0, -380),
		Vector2(-630, -380),
		Vector2(260, -380),
		Vector2(-630, -60),
		Vector2(260, -60),
		Vector2(0, 180),
		Vector2(-630, 160),
		Vector2(260, 160)
	]
	var avoid_rect := _hub_detail_avoid_rect(module_id, 48.0)
	var pos := _hub_clamped_bubble_position(target + offset, panel_size)
	var best_score := INF
	for raw_offset in candidate_offsets:
		var candidate := _hub_clamped_bubble_position(target + (raw_offset as Vector2), panel_size)
		var candidate_rect := Rect2(candidate, panel_size)
		var left := maxf(candidate_rect.position.x, avoid_rect.position.x)
		var top := maxf(candidate_rect.position.y, avoid_rect.position.y)
		var right := minf(candidate_rect.end.x, avoid_rect.end.x)
		var bottom := minf(candidate_rect.end.y, avoid_rect.end.y)
		var overlap := 0.0
		if right > left and bottom > top:
			overlap = (right - left) * (bottom - top)
		var distance_score := candidate.distance_to(target + offset)
		var side_penalty := 0.0
		if candidate_rect.has_point(target):
			side_penalty += 500000.0
		var score := overlap * 160.0 + distance_score + side_penalty
		if score < best_score:
			best_score = score
			pos = candidate
	return {"position": pos, "size": panel_size, "target": target}

func _hub_clamped_bubble_position(pos: Vector2, panel_size: Vector2) -> Vector2:
	pos.x = clampf(pos.x, 24.0, HUB_FIELD_SIZE.x - panel_size.x - 24.0)
	pos.y = clampf(pos.y, 65.0, HUB_FIELD_SIZE.y - ProfileChatOverlaySurface.CHAT_STRIP_HEIGHT - panel_size.y - 36.0)
	return pos

func _hub_detail_avoid_rect(module_id: String, padding: float) -> Rect2:
	if not _hub_can_store_position(module_id):
		var target := _hub_detail_target(module_id)
		return Rect2(target - Vector2(80, 80), Vector2(160, 160)).grow(padding)
	var center := _hub_module_center(module_id)
	var visual_size := _hub_module_visual_size(module_id, _hub_detail_sprite_index(module_id))
	var avoid_size := Vector2(maxf(visual_size.x * 0.82, 180.0), maxf(visual_size.y * 0.72, 140.0))
	if module_id == "trophy":
		avoid_size = Vector2(maxf(visual_size.x * 0.92, 195.0), maxf(visual_size.y * 0.78, 115.0))
	var rect_center := center + Vector2(0.0, visual_size.y * 0.08)
	return Rect2(rect_center - avoid_size * 0.5, avoid_size).grow(padding)

func _hub_detail_sprite_index(module_id: String) -> int:
	if module_id == "trophy":
		return -1
	if HUB_MODULE_DEFS.has(module_id):
		return clampi(_hub_module_level(module_id), 0, int((HUB_MODULE_DEFS[module_id] as Dictionary).get("cell_count", 5)) - 1)
	return -1

func _hub_detail_target(module_id: String) -> Vector2:
	if _hub_can_store_position(module_id):
		return _hub_path_target(module_id)
	return HUB_FIELD_SIZE * 0.5

func _hub_bubble_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _theme_surface_color(COLOR_PANEL)
	style.border_color = _theme_outline_color(COLOR_INK, COLOR_PANEL)
	style.set_border_width_all(4.5)
	style.corner_radius_top_left = 17
	style.corner_radius_top_right = 17
	style.corner_radius_bottom_left = 17
	style.corner_radius_bottom_right = 17
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	return style

func _hub_sheet_image(path: String, index: int, cell_size: Vector2, display_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = _hub_sheet_or_visual_fallback(path, index, cell_size)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.custom_minimum_size = display_size
	# The 4K layout inherited the source atlas cell as a minimum render size
	# because expand mode was applied after sizing. Preserve that authored
	# appearance at half scale without keeping 4K screen-space geometry.
	image.size = Vector2(maxf(display_size.x, cell_size.x * 0.5), maxf(display_size.y, cell_size.y * 0.5))
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func _hub_sheet_texture(path: String, index: int, cell_size: Vector2) -> Texture2D:
	var texture: Texture2D = host.visual_texture_cache._texture(path)
	if texture == null:
		return null
	var columns = maxi(1, int(texture.get_width() / cell_size.x))
	var rows = maxi(1, int(texture.get_height() / cell_size.y))
	var safe_index := clampi(index, 0, columns * rows - 1)
	var cell := Vector2(float(safe_index % columns), floor(float(safe_index) / float(columns)))
	return host.visual_texture_cache._atlas_texture(path, Rect2(Vector2(cell.x * cell_size.x, cell.y * cell_size.y), cell_size), true)

func _hub_sheet_or_visual_fallback(path: String, index: int, cell_size: Vector2) -> Texture2D:
	var loaded_texture := _hub_sheet_texture(path, index, cell_size)
	return loaded_texture if loaded_texture != null else host.visual_texture_cache._visual_fallback_texture()

func _hub_build_smoke(frame_offset := 0, display_size := Vector2(190, 190)) -> TextureRect:
	var frame = (int(floor(float(Time.get_ticks_msec()) / 1000.0)) + frame_offset) % HUB_BUILD_SMOKE_FRAME_COUNT
	var smoke := _hub_sheet_image(HUB_BUILD_SMOKE_SHEET, frame, Vector2(256, 256), display_size)
	return smoke

func _animate_hub_build_smoke(smoke: TextureRect, now_seconds: float, layer_index: int) -> void:
	var phase := now_seconds * 1.06 + float(layer_index) * 0.73
	var stretch := sin(phase) * 0.045
	var breathe := sin(phase * 0.61 + 1.4) * 0.020
	smoke.scale = Vector2(1.0 + stretch + breathe, 1.0 - stretch * 0.62 + breathe)
	smoke.rotation = sin(phase * 0.48) * 0.025
	if smoke.has_meta("hub_smoke_base_position"):
		var base_position: Vector2 = host._app_lifecycle_runtime().meta_vector2(smoke, "hub_smoke_base_position", smoke.position)
		smoke.position = base_position + Vector2(sin(phase * 0.42) * 8.0, sin(phase * 0.36 + 0.8) * 6.0)

func _apply_hub_build_countdown_style(countdown: HubBuildProgressBar, rect: Rect2) -> void:
	if countdown == null:
		return
	countdown.add_theme_font_size_override("font_size", int(clampf(rect.size.y * 0.82, 48.0, 54.0)))
	if app_bold_font != null:
		countdown.add_theme_font_override("font", app_bold_font)

func _position_hub_build_countdown_in_smoke(module_id: String) -> void:
	var countdown := _valid_hub_module_progress_bar(module_id)
	if countdown == null:
		return
	var progress_rect := _hub_module_build_progress_rect(module_id)
	var countdown_size := progress_rect.size
	var layers := _valid_hub_module_smoke_layers(module_id)
	if not layers.is_empty():
		var smoke := _state_object_ref(layers[0]) as TextureRect
		if smoke != null:
			countdown.position = smoke.position + (smoke.size - countdown_size) * 0.5
			countdown.size = countdown_size
			countdown.custom_minimum_size = countdown_size
			return
	countdown.position = progress_rect.position
	countdown.size = countdown_size
	countdown.custom_minimum_size = countdown_size

func _ensure_hub_module_state(module_id: String) -> Dictionary:
	return _hub_runtime().ensure_module_state(module_id)

func _hub_module_level(module_id: String) -> int:
	return _hub_runtime().module_level(module_id)

func _hub_module_building(module_id: String) -> bool:
	return _hub_runtime().module_building(module_id)

func _hub_module_build_progress(module_id: String) -> float:
	return _hub_runtime().module_build_progress(module_id)

func _process_hub_modules(_delta: float) -> void:
	var hub_ui_active = current_screen == "hub"
	var hub_ui_refs_live = (
		not hub_module_buttons.is_empty()
		or not hub_module_art.is_empty()
		or not hub_module_progress_bars.is_empty()
		or not hub_module_smoke_layers.is_empty()
		or not hub_decor_items.is_empty()
		or hub_detail_panel != null
	)
	if not hub_ui_active and hub_ui_refs_live:
		_clear_hub_page_control_refs()
	if not hub_ui_active:
		var now_unix := _unix_now()
		if now_unix == hub_hidden_process_unix:
			return
		hub_hidden_process_unix = now_unix
	else:
		hub_hidden_process_unix = -1
	for module_id in HUB_MODULE_ORDER:
		var id := str(module_id)
		var state := _ensure_hub_module_state(id)
		if not bool(state.get("building", false)):
			continue
		if hub_ui_active:
			var bar := _valid_hub_module_progress_bar(id)
			if bar != null:
				bar.set_countdown(_hub_module_build_remaining_seconds(id))
		if hub_ui_active:
			var layers := _valid_hub_module_smoke_layers(id)
			var now_seconds := float(Time.get_ticks_msec()) / 1000.0
			var frame_base := int(now_seconds)
			for i in range(layers.size()):
				var smoke := _state_object_ref(layers[i]) as TextureRect
				if smoke == null:
					continue
				smoke.texture = _hub_sheet_or_visual_fallback(HUB_BUILD_SMOKE_SHEET, (frame_base + i) % HUB_BUILD_SMOKE_FRAME_COUNT, Vector2(256, 256))
				_animate_hub_build_smoke(smoke, now_seconds, i)
			_position_hub_build_countdown_in_smoke(id)
	var completed_modules = _hub_runtime().complete_ready_builds()
	var changed = not completed_modules.is_empty()
	var missions_changed := _hub_runtime().sync_missions()
	if missions_changed:
		changed = true
	if changed:
		save_game()
		if current_screen == "hub":
			for raw_completed_id in completed_modules:
				var completed_id := str(raw_completed_id)
				_clear_hub_module_build_overlays(completed_id)
				_refresh_hub_module_art(completed_id)
			if not completed_modules.is_empty():
				_update_hub_path_dots()
			if hub_detail_open or missions_changed:
				_update_hub_detail_panel()
	elif _hub_mission_detail_wait_refresh_needed():
		_update_hub_detail_panel()

func _show_hub_mission_completion_ceremony(skill_id: String, action_id: String) -> void:
	last_hub_mission_completion_ceremony_text = "MISSION ICON POP"
	_play_hub_mission_completion_icon_ceremony(skill_id, action_id)

func _hub_mission_badge() -> Dictionary:
	var root := Control.new()
	_configure_action_card_type_badge_root(root)
	root.visible = false
	var paper := TextureRect.new()
	paper.set_anchors_preset(Control.PRESET_FULL_RECT)
	paper.texture = host.visual_texture_cache._texture_or_visual_fallback(HUB_MISSION_PAPER_BADGE)
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(paper)
	var label := _label("", 48, COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 12.0
	label.offset_right = -12.0
	label.offset_top = 24.0
	label.offset_bottom = -17.0
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	_add_action_card_type_badge_help(root, HUB_MISSION_BADGE_TITLE, HUB_MISSION_BADGE_INFO)
	return {"root": root, "label": label}

func _configure_action_card_type_badge_root(root: Control) -> void:
	root.anchor_left = 1.0
	root.anchor_right = 1.0
	root.anchor_top = 0.0
	root.anchor_bottom = 0.0
	root.offset_left = ACTION_CARD_TYPE_BADGE_OFFSET_LEFT
	root.offset_right = ACTION_CARD_TYPE_BADGE_OFFSET_RIGHT
	root.offset_top = ACTION_CARD_TYPE_BADGE_OFFSET_TOP
	root.offset_bottom = ACTION_CARD_TYPE_BADGE_OFFSET_BOTTOM
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = ACTION_CARD_FACE_BORDER_Z_INDEX + 8

func _add_action_card_type_badge_help(root: Control, title_text: String, body_text: String) -> void:
	var popover := _action_card_type_badge_popover(title_text, body_text)
	root.add_child(popover)
	host._passive_firepit_surface()._prewarm_passive_info_popover(popover)
	var button := Button.new()
	button.text = ""
	button.tooltip_text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 1
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(_toggle_action_card_type_badge_popover.bind(popover))
	root.add_child(button)

func _action_card_type_badge_popover(title_text: String, body_text: String) -> PanelContainer:
	var popover := PanelContainer.new()
	popover.position = ACTION_CARD_TYPE_BADGE_POPOVER_OFFSET
	popover.custom_minimum_size = ACTION_CARD_TYPE_BADGE_POPOVER_SIZE
	popover.size = ACTION_CARD_TYPE_BADGE_POPOVER_SIZE
	popover.visible = false
	popover.mouse_filter = Control.MOUSE_FILTER_STOP
	popover.z_index = 2
	popover.add_to_group("action_card_type_badge_popovers")
	popover.add_theme_stylebox_override("panel", _action_card_type_badge_popover_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_bottom", 11)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var title := _label(title_text, MIN_MOBILE_INFO_TITLE_FONT_SIZE, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title)
	var body := _label(body_text, host.MIN_MOBILE_HELP_FONT_SIZE, COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(744, 260)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(body)
	return popover

func _toggle_action_card_type_badge_popover(popover: Control) -> void:
	if popover == null or not is_instance_valid(popover):
		return
	var should_show := not popover.visible
	_hide_action_card_type_badge_popovers(popover)
	popover.visible = should_show
	if should_show:
		popover.modulate = Color(1, 1, 1, 0)
		popover.scale = Vector2(0.96, 0.96)
		popover.pivot_offset = Vector2(ACTION_CARD_TYPE_BADGE_POPOVER_SIZE.x, 0)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(popover, "modulate:a", 1.0, 0.08)
		tween.tween_property(popover, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		popover.modulate = Color.WHITE
		popover.scale = Vector2.ONE
	get_viewport().set_input_as_handled()

func _hide_action_card_type_badge_popovers(except: Control = null) -> void:
	for raw_popover in get_tree().get_nodes_in_group("action_card_type_badge_popovers"):
		var popover := raw_popover as Control
		if popover != null and is_instance_valid(popover) and popover != except:
			popover.visible = false

func _action_card_type_badge_popover_style() -> StyleBoxFlat:
	var style := _surface_style(COLOR_PANEL, 11, 11, true)
	style.border_color = COLOR_INK
	style.border_width_left = 3.5
	style.border_width_right = 3.5
	style.border_width_top = 3.5
	style.border_width_bottom = 3.5
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3.5)
	return style

func _sync_hub_mission_badge(card: Dictionary, skill_id: String, action: Dictionary, unlocked: bool) -> void:
	var mission := _hub_runtime().mission_for_action(skill_id, str(action.get("id", "")))
	var should_show_badge := unlocked and not mission.is_empty()
	var badge := card.get("mission_badge") as Control
	var label := card.get("mission_badge_label") as Label
	if should_show_badge and (badge == null or not is_instance_valid(badge) or label == null or not is_instance_valid(label)):
		var badge_data := _ensure_hub_mission_badge(card)
		badge = badge_data.get("root") as Control
		label = badge_data.get("label") as Label
	if badge == null or label == null:
		card["mission_badge_remaining"] = -1
		return
	badge.visible = should_show_badge
	if not should_show_badge:
		card["mission_badge_remaining"] = -1
		return
	var remaining := maxi(0, int(mission.get("remaining", 0)))
	var previous_remaining := int(card.get("mission_badge_remaining", -1))
	_set_label_text_if_changed(label, str(remaining))
	card["mission_badge_remaining"] = remaining
	if previous_remaining > 0 and remaining < previous_remaining:
		_play_hub_mission_badge_success(card)

func _ensure_hub_mission_badge(card: Dictionary) -> Dictionary:
	var root := card.get("mission_badge") as Control
	var label := card.get("mission_badge_label") as Label
	if root != null and is_instance_valid(root) and label != null and is_instance_valid(label):
		return {"root": root, "label": label}
	var parent := card.get("mission_badge_parent") as Control
	if parent == null or not is_instance_valid(parent):
		return {}
	var badge := _hub_mission_badge()
	parent.add_child(badge["root"] as Control)
	card["mission_badge"] = badge["root"]
	card["mission_badge_label"] = badge["label"]
	return badge

func _play_hub_mission_badge_success(card: Dictionary) -> void:
	var badge := card.get("mission_badge") as Control
	if badge == null or not is_instance_valid(badge) or not badge.is_visible_in_tree():
		return
	_play_hub_mission_badge_pop(card, badge, 1.16, 0.12, 0.16)

func _play_hub_mission_completion_icon_ceremony(skill_id: String, action_id: String) -> void:
	var card: Dictionary = host._reward_feedback_surface()._visible_action_feedback_card(skill_id, action_id)
	var badge := card.get("mission_badge") as Control
	var temporary := false
	if badge == null or not is_instance_valid(badge) or not badge.is_visible_in_tree():
		if card.is_empty():
			return
		var badge_data := _ensure_hub_mission_badge(card)
		badge = badge_data.get("root") as Control
		var label := badge_data.get("label") as Label
		if label != null:
			label.text = ""
		if badge == null or not is_instance_valid(badge):
			return
		badge.visible = true
		temporary = true
	_spawn_hub_mission_completion_sparkles(badge)
	_play_hub_mission_badge_pop(card, badge, 1.42, 0.16, 0.22, temporary)

func _play_hub_mission_badge_pop(card: Dictionary, badge: Control, peak_scale: float, up_seconds: float, down_seconds: float, remove_after := false) -> void:
	host._app_lifecycle_runtime()._kill_card_tween(card, "mission_badge_tween")
	badge.pivot_offset = badge.size * 0.5
	badge.scale = Vector2.ONE
	badge.modulate = Color("#93ff9e")
	var tween := create_tween()
	card["mission_badge_tween"] = tween
	tween.set_parallel(true)
	tween.tween_property(badge, "scale", Vector2(peak_scale, peak_scale), up_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate", Color.WHITE, 0.28)
	tween.chain().tween_property(badge, "scale", Vector2.ONE, down_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var badge_id := badge.get_instance_id()
	tween.finished.connect(_finish_hub_mission_badge_success.bind(str(card.get("card_key", "")), badge_id, remove_after))

func _spawn_hub_mission_completion_sparkles(badge: Control) -> void:
	var parent := badge.get_parent() as Control
	if parent == null:
		return
	var center := badge.position + badge.size * 0.5
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var star := AchievementPresentation.MedalSparkleStar.new()
		star.fill_color = Color("#ffe56b") if i % 2 == 0 else Color("#93ff9e")
		star.outline_color = COLOR_INK
		star.size = Vector2(29, 29)
		star.position = center - star.size * 0.5
		star.z_index = mini(4090, badge.z_index + 6 + i)
		star.modulate.a = 0.0
		parent.add_child(star)
		var travel := Vector2(cos(angle), sin(angle)) * 210.0
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(star, "position", star.position + travel, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "modulate:a", 1.0, 0.08)
		tween.chain().tween_property(star, "modulate:a", 0.0, 0.18)
		tween.tween_callback(star.queue_free)

func _finish_hub_mission_badge_success(card_key: String, badge_id: int, remove_after := false) -> void:
	var callback_badge := _valid_control_ref(instance_from_id(badge_id))
	if callback_badge != null:
		callback_badge.scale = Vector2.ONE
		callback_badge.modulate = Color.WHITE
		if remove_after:
			callback_badge.queue_free()
	var card := action_cards.get(card_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("mission_badge_tween")

func _hub_mission_summary_text() -> String:
	if _hub_runtime().sync_missions():
		save_game()
	var level := _hub_runtime().mission_level()
	if level <= 0:
		return "Build the board to start boosted missions."
	var lines := [
		"%s mission slot%s" % [_hub_runtime().mission_slot_count(), "" if _hub_runtime().mission_slot_count() == 1 else "s"],
		"-%s%% stamina, +%s%% XP, +%s%% speed." % [
			GameFormatting.percent_points(_hub_runtime().mission_stamina_reduction() * 100.0),
			GameFormatting.percent_points(_hub_runtime().mission_xp_bonus() * 100.0),
			GameFormatting.percent_points(_hub_runtime().mission_time_reduction() * 100.0)
		]
	]
	if _hub_runtime().hub_missions.is_empty():
		var wait := maxi(0, _hub_runtime().hub_mission_cooldown_until_unix - _unix_now())
		lines.append("Next mission in %s." % GameFormatting.duration(float(wait)))
	return "\n".join(lines)

func _jump_to_hub_mission_task(mission_index := 0) -> void:
	var mission := _hub_mission_at_index(mission_index)
	if mission.is_empty():
		return
	var skill_id := str(mission.get("skill_id", ""))
	var action_id := str(mission.get("action_id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return
	_kill_hub_detail_motion_tween()
	hub_detail_open = false
	hub_detail_transition_pending = false
	selected_skill_id = skill_id
	current_screen = "skill"
	host._navigation_shell()._render_screen(false, -1)
	await host._skill_detail_surface()._scroll_to_activity_card(action_id, true, true)

func _hub_mission_at_index(mission_index: int) -> Dictionary:
	if _hub_runtime().sync_missions():
		save_game()
	if mission_index < 0 or mission_index >= _hub_runtime().hub_missions.size():
		return {}
	return _hub_runtime().hub_missions[mission_index] as Dictionary

func _sync_hub_detail_mission_cards() -> void:
	if hub_detail_missions_box == null or not is_instance_valid(hub_detail_missions_box):
		return
	for child in hub_detail_missions_box.get_children():
		child.queue_free()
	var show_cards = _hub_runtime().hub_selected_module_id == "mission"
	hub_detail_missions_box.visible = show_cards
	if not show_cards:
		hub_mission_detail_wait_last_seconds = -1
		return
	if _hub_runtime().sync_missions():
		save_game()
	var active_slots := _hub_runtime().mission_slot_count()
	var max_slots := _hub_runtime().mission_max_slot_count()
	for i in range(max_slots):
		if i >= active_slots:
			hub_detail_missions_box.add_child(_hub_mission_locked_slab(i))
			continue
		if i >= _hub_runtime().hub_missions.size():
			hub_detail_missions_box.add_child(_hub_mission_wait_slab(i))
			continue
		var mission := _hub_runtime().hub_missions[i] as Dictionary
		var action := _action_data(str(mission.get("skill_id", "")), str(mission.get("action_id", "")))
		if action.is_empty():
			hub_detail_missions_box.add_child(_hub_mission_wait_slab(i))
			continue
		hub_detail_missions_box.add_child(_hub_mission_slab(mission, action, i))
	hub_mission_detail_wait_last_seconds = maxi(0, _hub_runtime().hub_mission_cooldown_until_unix - _unix_now()) if _hub_runtime().hub_missions.size() < active_slots else -1

func _hub_mission_detail_wait_refresh_needed() -> bool:
	if current_screen != "hub" or not hub_detail_open or _hub_runtime().hub_selected_module_id != "mission":
		hub_mission_detail_wait_last_seconds = -1
		return false
	if _hub_runtime().mission_level() <= 0 or _hub_runtime().hub_mission_cooldown_until_unix <= 0:
		hub_mission_detail_wait_last_seconds = -1
		return false
	if _hub_runtime().hub_missions.size() >= _hub_runtime().mission_slot_count():
		hub_mission_detail_wait_last_seconds = -1
		return false
	var wait := maxi(0, _hub_runtime().hub_mission_cooldown_until_unix - _unix_now())
	if wait == hub_mission_detail_wait_last_seconds:
		return false
	hub_mission_detail_wait_last_seconds = wait
	return true

func _hub_mission_wait_slab(slot_index := 0) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 180)
	panel.add_theme_stylebox_override("panel", _hub_mission_wait_slab_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 17)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var wait := maxi(0, _hub_runtime().hub_mission_cooldown_until_unix - _unix_now())
	if wait > 0:
		var ring := MissionCooldownRing.new()
		ring.custom_minimum_size = Vector2(95, 95)
		ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cooldown := maxi(1, _hub_runtime().mission_cooldown_seconds())
		ring.set_progress(1.0 - clampf(float(wait) / float(cooldown), 0.0, 1.0))
		row.add_child(ring)

	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 4)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var title_text := "Next mission in %s" % GameFormatting.duration(float(wait)) if wait > 0 else "Finding mission..."
	if wait <= 0 and slot_index > 0:
		title_text = "Open mission slot"
	var title := _label(title_text, 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 12)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)
	var body_text := "A fresh boosted task will appear here."
	if wait <= 0 and _hub_runtime().mission_eligible_actions({}).is_empty():
		body_text = "Unlock more actions to get missions."
	var body := _label(body_text, 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	body.add_theme_color_override("font_outline_color", Color.BLACK)
	body.add_theme_constant_override("outline_size", 10)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(body)
	return panel

func _hub_mission_locked_slab(slot_index: int) -> Button:
	var required_level := _hub_runtime().mission_required_level_for_slot(slot_index)
	var button := Button.new()
	button.text = ""
	button.disabled = true
	button.custom_minimum_size = Vector2(0, 180)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_stylebox_override("normal", _hub_mission_slab_style(false, true))
	button.add_theme_stylebox_override("hover", _hub_mission_slab_style(false, true))
	button.add_theme_stylebox_override("pressed", _hub_mission_slab_style(false, true))
	button.add_theme_stylebox_override("disabled", _hub_mission_slab_style(false, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 4)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(copy)

	var title := _label("Higher Tier Sign Needed", 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 12)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)

	var detail := _label("Mission Slot %s - unlocks at Lv %s" % [slot_index + 1, required_level], 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	detail.autowrap_mode = TextServer.AUTOWRAP_OFF
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.add_theme_color_override("font_outline_color", Color.BLACK)
	detail.add_theme_constant_override("outline_size", 10)
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(detail)
	return button

func _hub_mission_slab(mission: Dictionary, action: Dictionary, mission_index: int) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, 180)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _hub_mission_slab_style(false))
	button.add_theme_stylebox_override("hover", _hub_mission_slab_style(false))
	button.add_theme_stylebox_override("pressed", _hub_mission_slab_style(true))
	button.add_theme_stylebox_override("disabled", _hub_mission_slab_style(false, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(_jump_to_hub_mission_task.bind(mission_index))
	host.button_press_runtime.attach_button_depress_animation(button, 0.98)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 17)
	margin.add_theme_constant_override("margin_right", 17)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var art_panel := Panel.new()
	art_panel.custom_minimum_size = Vector2(99, 99)
	art_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art_panel.clip_contents = true
	art_panel.add_theme_stylebox_override("panel", ActivityCardStyles.cached_action_art(Callable(host, "_surface_style")))
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(art_panel)
	var art := TextureRect.new()
	art.texture = host.visual_texture_cache._texture_or_visual_fallback(str(action.get("art", "")))
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_panel.add_child(art)
	ActionArtUi.add_corner_badges(
		art_panel,
		ActionArtUi.resource_icon_paths(action, Callable(host._action_runtime(), "_action_mat_reward_defs"), Callable(host.material_runtime, "icon_path"), Callable(host._temporary_event_runtime(), "_temporary_event_log_reward_mat_id")),
		ActionArtUi.special_type_icon_path(action, Callable(host, "_is_event_action")),
		Callable(host.visual_texture_cache, "_texture_or_visual_fallback")
	)
	art_panel.add_child(ActionArtUi.border_overlay(ActivityCardStyles.cached_action_art_border(Callable(host, "_surface_style"))))

	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 3)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.custom_minimum_size = Vector2(350, 0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	var title := _label(str(action.get("name", "Task")), 60, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 12)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(title)
	var meta := _label("%s task" % SkillState.skill_name(host.skill_defs, str(mission.get("skill_id", ""))), 48, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	meta.autowrap_mode = TextServer.AUTOWRAP_OFF
	meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	meta.add_theme_color_override("font_outline_color", Color.BLACK)
	meta.add_theme_constant_override("outline_size", 10)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(meta)

	var remaining_label := _label("%s left" % int(mission.get("remaining", 0)), 60, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	remaining_label.custom_minimum_size = Vector2(180, 0)
	remaining_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	remaining_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	remaining_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	remaining_label.add_theme_color_override("font_outline_color", Color.BLACK)
	remaining_label.add_theme_constant_override("outline_size", 12)
	remaining_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(remaining_label)
	return button

func _hub_mission_slab_style(pressed: bool, disabled := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if disabled:
		style.bg_color = Color("#77736c")
		style.border_color = Color("#2e2a24")
	else:
		style.bg_color = Color("#8f5b28") if not pressed else Color("#70431f")
		style.border_color = Color.BLACK
	style.set_border_width_all(6)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 3.5
	style.shadow_offset = Vector2(0, 2.5)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func _hub_mission_wait_slab_style() -> StyleBoxFlat:
	var style := _hub_mission_slab_style(false)
	style.bg_color = Color("#6f6a5e")
	style.border_color = Color("#2e2a24")
	return style

func _set_hub_mission_upgrade_button_copy(title_text: String, cost_text: String) -> void:
	if hub_detail_button == null or not is_instance_valid(hub_detail_button):
		return
	hub_detail_button.text = ""
	var title := hub_detail_button.get_node_or_null("MissionUpgradeCopy/Stack/Title") as Label
	if title != null and is_instance_valid(title):
		title.text = title_text
	var cost := hub_detail_button.get_node_or_null("MissionUpgradeCopy/Stack/Cost") as Label
	if cost != null and is_instance_valid(cost):
		cost.text = cost_text
		cost.visible = not cost_text.is_empty()

func _on_hub_module_pressed(module_id: String) -> void:
	if hub_build_mode or hub_detail_transition_pending:
		return
	if hub_detail_open:
		_close_hub_detail_popup()
		return
	hub_detail_transition_pending = true
	call_deferred("_apply_open_hub_detail_popup", module_id)

func _apply_open_hub_detail_popup(module_id: String) -> void:
	if current_screen != "hub" or hub_build_mode:
		hub_detail_transition_pending = false
		return
	_hub_runtime().hub_selected_module_id = module_id
	hub_detail_open = true
	hub_detail_transition_pending = module_id == "mission"
	host._navigation_shell()._render_screen()
	_pop_hub_module(module_id)
	_update_hub_detail_panel()
	if module_id == "mission":
		_animate_hub_mission_board_open()
	else:
		hub_detail_transition_pending = false

func _on_hub_trophy_pressed() -> void:
	if hub_build_mode or hub_detail_transition_pending:
		return
	if hub_detail_open:
		_close_hub_detail_popup()
		return
	hub_detail_transition_pending = true
	call_deferred("_apply_open_hub_detail_popup", "trophy")

func _pop_hub_module(module_id: String) -> void:
	var button := _valid_hub_module_button(module_id)
	if button == null:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2(0.94, 0.94), 0.05)
	tween.tween_property(button, "scale", Vector2(1.06, 1.06), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.10)

func _update_hub_detail_panel() -> void:
	if hub_detail_panel == null or not is_instance_valid(hub_detail_panel):
		return
	var module_id = _hub_runtime().hub_selected_module_id
	if module_id == "trophy":
		hub_detail_title.text = "Trophy Platform"
		hub_detail_body.text = "%s\n%s" % [_hub_trophy_current_bonus_text(), _hub_trophy_next_bonus_text()]
		hub_detail_cost.visible = false
		hub_detail_cost.text = ""
		hub_detail_button.visible = false
		hub_detail_button.disabled = true
		if hub_detail_secondary_button != null:
			hub_detail_secondary_button.visible = false
		if hub_detail_missions_box != null:
			hub_detail_missions_box.visible = false
		return
	hub_detail_button.visible = true
	if not HUB_MODULE_DEFS.has(module_id):
		module_id = "pond"
		_hub_runtime().hub_selected_module_id = module_id
	var def := HUB_MODULE_DEFS[module_id] as Dictionary
	var level := _hub_module_level(module_id)
	var building := _hub_module_building(module_id)
	if module_id == "mission":
		_update_hub_mission_board_panel(def, level, building)
		return
	hub_detail_title.text = "%s Lv %s" % [str(def.get("name", "Module")), level]
	var body_lines := []
	for line in [_hub_module_current_bonus_text(module_id), _hub_module_next_bonus_text(module_id)]:
		if not str(line).is_empty():
			body_lines.append(str(line))
	hub_detail_body.text = "\n".join(body_lines)
	var next_level_locked := not _hub_module_next_level_unlocked(module_id)
	var cost_text := _hub_module_cost_text(module_id)
	hub_detail_cost.visible = not next_level_locked and not cost_text.is_empty()
	hub_detail_cost.text = cost_text if hub_detail_cost.visible else ""
	_sync_hub_detail_mission_cards()
	if hub_detail_secondary_button != null:
		hub_detail_secondary_button.visible = false
		hub_detail_secondary_button.disabled = true
	if building:
		hub_detail_button.text = "Building..."
		hub_detail_button.disabled = true
	elif level >= HUB_MODULE_MAX_LEVEL:
		hub_detail_button.text = "Maxed Out"
		hub_detail_button.disabled = true
	elif next_level_locked:
		hub_detail_button.text = "Building Lv %s" % _hub_module_next_unlock_level(module_id)
		hub_detail_button.disabled = true
	else:
		hub_detail_button.text = "Build" if level <= 0 else "Upgrade"
		hub_detail_button.disabled = not _can_afford_hub_module(module_id)

func _update_hub_mission_board_panel(_def: Dictionary, level: int, building: bool) -> void:
	if hub_detail_title != null and is_instance_valid(hub_detail_title):
		hub_detail_title.text = "Mission Board Lv %s" % level
	if hub_detail_body != null and is_instance_valid(hub_detail_body):
		if level <= 0:
			hub_detail_body.text = "Build the board to start boosted task missions."
		else:
			hub_detail_body.text = "Tap a mission to jump to its task. -%s%% stamina, +%s%% XP, +%s%% speed." % [
				GameFormatting.percent_points(_hub_runtime().mission_stamina_reduction() * 100.0),
				GameFormatting.percent_points(_hub_runtime().mission_xp_bonus() * 100.0),
				GameFormatting.percent_points(_hub_runtime().mission_time_reduction() * 100.0)
			]
	_sync_hub_detail_mission_cards()
	var next_level_locked := not _hub_module_next_level_unlocked("mission")
	var cost_text := _hub_module_cost_text("mission")
	if hub_detail_cost != null and is_instance_valid(hub_detail_cost):
		hub_detail_cost.visible = false
		hub_detail_cost.text = ""
	if hub_detail_button == null or not is_instance_valid(hub_detail_button):
		return
	hub_detail_button.visible = true
	var button_title := ""
	var button_cost := cost_text if not next_level_locked and not cost_text.is_empty() else ""
	if building:
		button_title = "Building..."
		hub_detail_button.disabled = true
	elif level >= HUB_MODULE_MAX_LEVEL:
		button_title = "Maxed Out"
		button_cost = ""
		hub_detail_button.disabled = true
	elif next_level_locked:
		button_title = "Building Lv %s" % _hub_module_next_unlock_level("mission")
		button_cost = ""
		hub_detail_button.disabled = true
	else:
		button_title = "Build" if level <= 0 else "Upgrade"
		hub_detail_button.disabled = not _can_afford_hub_module("mission")
	_set_hub_mission_upgrade_button_copy(button_title, button_cost)

func _hub_module_current_bonus_text(module_id: String) -> String:
	var level := _hub_module_level(module_id)
	match module_id:
		"pond":
			return "Current: +%s%% stamina regen speed." % GameFormatting.percent_points(_hub_pond_regen_bonus() * 100.0)
		"barn":
			return "Current: %s%% success rate bonus." % GameFormatting.percent_points(_hub_barn_failure_factor() * 100.0)
		"garden":
			return "Current: +%sh offline progress cap." % level
		"trophy":
			return "Current: trophy display tier %s." % level
		"mission":
			return "Current: %s" % _hub_mission_summary_text()
	return "Current: no bonus yet."

func _hub_module_next_bonus_text(module_id: String) -> String:
	var next_level := _hub_module_level(module_id) + 1
	if next_level > HUB_MODULE_MAX_LEVEL:
		return "Next: maxed."
	var unlock_level := _hub_module_next_unlock_level(module_id)
	if _hub_build_level() < unlock_level:
		return ""
	match module_id:
		"pond":
			return "Next: +%s%% total stamina regen speed." % GameFormatting.percent_points(float(HUB_POND_REGEN_BONUS_BY_LEVEL[next_level]) * 100.0)
		"barn":
			return "Next: %s%% success rate bonus." % GameFormatting.percent_points(float(HUB_BARN_FAILURE_GAP_FACTORS[next_level]) * 100.0)
		"garden":
			return "Next: +%sh offline progress cap." % next_level
		"trophy":
			return "Next: better stolen trophy display."
		"mission":
			return "Next: %s slots, -%s%% stamina, +%s%% XP, +%s%% speed, %s cooldown." % [
				int(HUB_MISSION_SLOT_COUNT_BY_LEVEL[next_level]),
				GameFormatting.percent_points(float(HUB_MISSION_STAMINA_REDUCTION_BY_LEVEL[next_level]) * 100.0),
				GameFormatting.percent_points(float(HUB_MISSION_XP_BONUS_BY_LEVEL[next_level]) * 100.0),
				GameFormatting.percent_points(float(HUB_MISSION_TIME_REDUCTION_BY_LEVEL[next_level]) * 100.0),
				GameFormatting.duration(float(HUB_MISSION_COOLDOWN_SECONDS_BY_LEVEL[next_level]))
			]
	return "Next: upgrade."

func _hub_trophy_current_bonus_text() -> String:
	var tier := _hub_best_trophy_tier()
	if tier <= 0:
		return "Current: none."
	return "Current: +%s%% success chance." % GameFormatting.percent_points(_hub_runtime().trophy_success_bonus() * 100.0)

func _hub_trophy_next_bonus_text() -> String:
	var next_heist := _hub_next_trophy_def()
	if next_heist.is_empty():
		return "Next: maxed."
	var unlock_level := int(next_heist.get("unlock", 1))
	if _skill_level("thieving") < unlock_level:
		return "Next: requires level %s Thieving." % unlock_level
	var trophy_tier := clampi(int(next_heist.get("tier", 0)), 0, HubRuntime.HUB_TROPHY_SUCCESS_BONUS_BY_TIER.size() - 1)
	var trophy_name := str(next_heist.get("trophy", "next trophy"))
	return "Next: %s, +%s%% success chance." % [
		trophy_name,
		GameFormatting.percent_points(float(HubRuntime.HUB_TROPHY_SUCCESS_BONUS_BY_TIER[trophy_tier]) * 100.0)
	]

func _hub_next_trophy_def() -> Dictionary:
	return _hub_runtime().next_trophy_def()

func _hub_best_trophy_tier() -> int:
	return _hub_runtime().best_trophy_tier()

func _hub_best_trophy_def() -> Dictionary:
	return _hub_runtime().best_trophy_def()

func _hub_module_wood_currency_for_level(module_id: String, level: int) -> String:
	return _hub_runtime().module_wood_currency_for_level(module_id, level)

func _hub_module_wood_currency_name(module_id: String, level: int) -> String:
	var wood_currency := _hub_module_wood_currency_for_level(module_id, level)
	var mat_def := MaterialRuntime.MAT_COLLECTION_DEFS.get(wood_currency, {}) as Dictionary
	return str(mat_def.get("name", "Softwood"))

func _hub_module_cost_text(module_id: String) -> String:
	var level := _hub_module_level(module_id)
	if level >= HUB_MODULE_MAX_LEVEL:
		return "Cost: maxed"
	var unlock_level := _hub_module_next_unlock_level(module_id)
	if _hub_build_level() < unlock_level:
		return ""
	var costs := (HUB_MODULE_DEFS[module_id] as Dictionary).get("costs", []) as Array
	var cost := int(costs[level])
	if module_id == "pond":
		return "Cost: %s fish" % cost
	if module_id == "garden":
		var fish_costs := (HUB_MODULE_DEFS[module_id] as Dictionary).get("fish_costs", []) as Array
		return "Cost: %s %s + %s fish" % [cost, _hub_module_wood_currency_name(module_id, level), int(fish_costs[level])]
	return "Cost: %s %s" % [cost, _hub_module_wood_currency_name(module_id, level)]

func _can_afford_hub_module(module_id: String) -> bool:
	return _hub_runtime().can_afford_module(module_id)

func _hub_module_next_unlock_level(module_id: String) -> int:
	return _hub_runtime().module_next_unlock_level(module_id)

func _hub_module_next_level_unlocked(module_id: String) -> bool:
	return _hub_runtime().module_next_level_unlocked(module_id)

func _hub_build_level() -> int:
	return _skill_level("build")

func _upgrade_selected_hub_module() -> void:
	if _hub_runtime().hub_selected_module_id == "trophy":
		return
	_upgrade_hub_module(_hub_runtime().hub_selected_module_id)

func _upgrade_hub_module(module_id: String) -> void:
	var result = _hub_runtime().upgrade_module(module_id)
	if bool(result.get("blocked", false)):
		_pop_hub_module(module_id)
		return
	if result.is_empty():
		return
	hub_detail_open = false
	save_game()
	host._navigation_shell()._render_screen()
	_play_hub_module_build_spend_burst(module_id, int(result.get("spent_logs", 0)), int(result.get("spent_fish", 0)))

func _play_hub_module_build_spend_burst(module_id: String, spent_logs: int, spent_fish: int) -> void:
	if current_screen != "hub" or (spent_logs <= 0 and spent_fish <= 0):
		return
	if not is_inside_tree():
		return
	var start_global = _hub_module_spend_burst_start_global(module_id)
	var start_local: Vector2 = host._control_global_point_to_local(host, start_global)
	var burst_specs := []
	if spent_logs > 0:
		burst_specs.append({
			"path": MaterialRuntime.LOG_CURRENCY_ICON_TEXTURE,
			"count": _hub_spend_burst_icon_count(spent_logs),
			"bias": -0.42 if spent_fish > 0 else 0.0
		})
	if spent_fish > 0:
		burst_specs.append({
			"path": FishCircle.FISH_CURRENCY_ICON_TEXTURE,
			"count": _hub_spend_burst_icon_count(spent_fish),
			"bias": 0.42 if spent_logs > 0 else 0.0
		})
	var icon_index := 0
	for raw_spec in burst_specs:
		var spec := raw_spec as Dictionary
		var texture: Texture2D = host.visual_texture_cache._texture(str(spec.get("path", "")))
		if texture == null:
			continue
		var count = int(spec.get("count", HUB_SPEND_BURST_MIN_ICONS))
		var bias := float(spec.get("bias", 0.0))
		for _i in range(count):
			var delay := float(icon_index) * 0.022 + randf_range(0.0, 0.045)
			_spawn_hub_spend_burst_icon(texture, start_local, bias, delay)
			icon_index += 1

func _hub_spend_burst_icon_count(cost: int) -> int:
	var count = HUB_SPEND_BURST_MIN_ICONS
	var threshold := 50
	var safe_cost := maxi(1, cost)
	while safe_cost >= threshold and count < HUB_SPEND_BURST_MAX_ICONS:
		count += 1
		threshold *= 4
	return clampi(count, HUB_SPEND_BURST_MIN_ICONS, HUB_SPEND_BURST_MAX_ICONS)

func _hub_module_spend_burst_start_global(module_id: String) -> Vector2:
	var art := _valid_hub_module_art(module_id)
	if art != null and art.is_inside_tree():
		var art_rect := art.get_global_rect()
		return Vector2(art_rect.get_center().x, art_rect.position.y + art_rect.size.y * 0.08)
	var button := _valid_hub_module_button(module_id)
	if button != null and button.is_inside_tree():
		var button_rect := button.get_global_rect()
		return Vector2(button_rect.get_center().x, button_rect.position.y + button_rect.size.y * 0.18)
	return host.get_global_rect().get_center()

func _spawn_hub_spend_burst_icon(texture: Texture2D, start_local: Vector2, side_bias: float, delay: float) -> void:
	var icon: TextureRect = host.visual_texture_cache._image_from_texture(texture, HUB_SPEND_BURST_ICON_SIZE)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 4096
	icon.z_as_relative = false
	icon.pivot_offset = HUB_SPEND_BURST_ICON_SIZE * 0.5
	icon.position = start_local - HUB_SPEND_BURST_ICON_SIZE * 0.5 + Vector2(randf_range(-36.0, 36.0), randf_range(-12.0, 18.0))
	icon.scale = Vector2(0.48, 0.48)
	icon.modulate = Color(1, 1, 1, 0)
	icon.rotation = randf_range(-0.32, 0.32)
	host.add_child(icon)
	var horizontal_push := randf_range(-210.0, 210.0) + side_bias * randf_range(120.0, 240.0)
	var vertical_push := -randf_range(250.0, 420.0)
	var target_position: Vector2 = icon.position + Vector2(horizontal_push, vertical_push)
	var target_scale := Vector2.ONE * randf_range(0.78, 1.06)
	var target_rotation: float = icon.rotation + randf_range(-1.25, 1.25)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(icon, "position", target_position, 0.84).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2.ONE * 1.14, 0.13).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", target_scale, 0.56).set_delay(delay + 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "rotation", target_rotation, 0.84).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "modulate:a", 1.0, 0.08).set_delay(delay)
	tween.tween_property(icon, "modulate:a", 0.0, 0.36).set_delay(delay + 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(icon.get_instance_id()))

func _hub_barn_failure_factor() -> float:
	return _hub_runtime().barn_failure_factor()

func _hub_pond_regen_bonus() -> float:
	return _hub_runtime().pond_regen_bonus()

func _hub_offline_cap_seconds() -> int:
	return _hub_runtime().offline_cap_seconds()

func _hub_tutorial_info_button_style(pressed := false, hovered := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = (Color("#5a96dd") if not hovered else Color("#68a8ef")).darkened(0.08 if pressed else 0.0)
	style.border_color = COLOR_INK
	style.set_border_width_all(3.5)
	style.corner_radius_top_left = 499.5
	style.corner_radius_top_right = 499.5
	style.corner_radius_bottom_left = 499.5
	style.corner_radius_bottom_right = 499.5
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 2 if not pressed else 0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 3.5 if not pressed else 1.5
	style.shadow_offset = Vector2(0, 2.5 if not pressed else 1)
	return style
