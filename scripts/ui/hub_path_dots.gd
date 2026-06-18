class_name HubPathDots
extends Control


var path_destinations := []
var blockers := []
var path_dots := []
var origin := Vector2.ZERO
var dot_radius := 68.0
var dot_step := 132.0
var dot_height_scale := 0.34
var path_color := Color("#a97943")
var edge_color := Color("#6f4c2e")
var stone_color := Color("#9d9485")

func set_paths(next_origin: Vector2, next_destinations: Array, next_blockers: Array) -> void:
	origin = next_origin
	path_destinations = next_destinations.duplicate()
	blockers = next_blockers.duplicate()
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
	var destination_pull := clampf((destination.x - origin.x) * 0.16, -92.0, 92.0)
	var x_jitter := lerpf(-28.0, 28.0, _unit(route_seed + 5.11))
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
		rects.append(_dot_rect(dot as Dictionary, 16.0))
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
	var blocker = _blocking_rect_for_segment(start, join)
	if blocker is Rect2:
		var rect := blocker as Rect2
		var side := _detour_side_for_blocker(rect, route_seed)
		var detour_y := clampf(lerpf(start.y, join.y, 0.52), rect.position.y - dot_step * 0.42, rect.end.y + dot_step * 0.58)
		var detour := Vector2(rect.get_center().x + side * (rect.size.x * 0.5 + dot_step * 0.70), detour_y)
		if detour.distance_to(start) > dot_step * 0.34:
			trunk_nodes.append(detour)
	if join.distance_to(trunk_nodes[trunk_nodes.size() - 1] as Vector2) > dot_step * 0.42:
		trunk_nodes.append(join)

func _collect_trunk_segment(start: Vector2, destination: Vector2, route_seed: float, next_dots: Array) -> void:
	var vertical := destination.y - start.y
	var control_a := start + Vector2(lerpf(-18.0, 18.0, _unit(route_seed + 1.0)), vertical * 0.42)
	var control_b := destination + Vector2(lerpf(-18.0, 18.0, _unit(route_seed + 3.0)), -vertical * 0.30)
	_collect_sampled_dotted_path(start, destination, route_seed, next_dots, func(t: float) -> Vector2:
		var q := 1.0 - t
		var wave := sin(t * PI) * lerpf(-22.0, 22.0, _unit(route_seed + 7.0))
		var point := q * q * q * start + 3.0 * q * q * t * control_a + 3.0 * q * t * t * control_b + t * t * t * destination
		point.x += wave
		return point
	)

func _collect_dotted_path(start: Vector2, destination: Vector2, route_seed: float, next_dots: Array) -> void:
	var control := Vector2(start.x, lerpf(start.y, destination.y, 0.54))
	_collect_sampled_dotted_path(start, destination, route_seed, next_dots, func(t: float) -> Vector2:
		var q := 1.0 - t
		return q * q * start + 2.0 * q * t * control + t * t * destination
	)

func _branch_arrival_point(start: Vector2, destination: Vector2, route_seed: float) -> Vector2:
	var side := signf(destination.x - start.x)
	if absf(side) < 0.001:
		side = 1.0 if _unit(route_seed + 17.0) > 0.5 else -1.0
	var destination_blocker = _blocker_near_point(destination)
	if destination_blocker is Rect2:
		var rect := destination_blocker as Rect2
		var centered_hotspot := absf(rect.get_center().x - origin.x) < dot_step * 1.18
		if centered_hotspot:
			side = _detour_side_for_blocker(rect, route_seed + 37.0)
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
	var control_a := start + Vector2(side * horizontal * (0.08 if not s_curve else -0.24) + lerpf(-12.0, 12.0, _unit(route_seed + 19.0)), y_direction * trunk_launch)
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
	var control := start.lerp(destination, 0.68) + Vector2(lerpf(-14.0, 14.0, _unit(route_seed + 3.0)), dot_step * lerpf(-0.04, 0.12, _unit(route_seed + 5.0)))
	_collect_sampled_dotted_path(start, destination, route_seed, next_dots, func(t: float) -> Vector2:
		var q := 1.0 - t
		return q * q * start + 2.0 * q * t * control + t * t * destination
	)

func _blocking_rect_for_segment(start: Vector2, destination: Vector2) -> Variant:
	for raw_blocker in blockers:
		if not raw_blocker is Rect2:
			continue
		var rect := (raw_blocker as Rect2).grow(dot_radius * 0.72)
		for i in range(1, 18):
			var t := float(i) / 18.0
			var point := start.lerp(destination, t)
			if rect.has_point(point):
				return raw_blocker
	return null

func _blocker_near_point(point: Vector2) -> Variant:
	for raw_blocker in blockers:
		if raw_blocker is Rect2 and (raw_blocker as Rect2).grow(dot_step * 0.45).has_point(point):
			return raw_blocker
	return null

func _detour_side_for_blocker(rect: Rect2, route_seed: float) -> float:
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
			var scatter := normal * lerpf(-46.0, 46.0, _unit(route_seed + float(dot_index) * 13.71))
			scatter += direction * lerpf(-24.0, 24.0, _unit(route_seed + float(dot_index) * 17.89))
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
	if _dot_hits_blocker(center, radius):
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
		if _dot_hits_blocker(clump_center, clump_radius):
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
		if _dot_hits_blocker(tiny_center, tiny_radius):
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
		if not _dot_rect(dot, 10.0).intersects(_dot_rect(existing, 10.0)):
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
				if _dot_rect(a, -6.0).intersects(_dot_rect(b, -6.0)):
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
	_draw_irregular_oval(center + Vector2(lerpf(-5.0, 5.0, _unit(noise_seed + 2.0)), lerpf(-1.4, 1.4, _unit(noise_seed + 3.0))), radius_x * 1.12, radius_y * 1.16, glaze, noise_seed + 5.0, 0.15)
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

func _draw_feathered_oval(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var fade_color := color
	var fade_steps := [
		{"scale": 1.20, "alpha": 0.09},
		{"scale": 1.10, "alpha": 0.25},
		{"scale": 1.03, "alpha": 0.52},
		{"scale": 1.00, "alpha": 0.94}
	]
	for raw_step in fade_steps:
		var step := raw_step as Dictionary
		fade_color.a = float(step.get("alpha", 1.0))
		var step_scale := float(step.get("scale", 1.0))
		_draw_oval(center, radius_x * step_scale, radius_y * step_scale, fade_color)

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

func _draw_oval(center: Vector2, radius_x: float, radius_y: float, color: Color) -> void:
	var oval_points := PackedVector2Array()
	for i in range(28):
		var angle := TAU * float(i) / 28.0
		oval_points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(oval_points, color)

func _dot_rect(dot: Dictionary, padding: float) -> Rect2:
	var center := dot.get("center", Vector2.ZERO) as Vector2
	var radius := float(dot.get("radius", dot_radius)) + padding
	var half_size := Vector2(radius, radius * dot_height_scale)
	return Rect2(center - half_size, half_size * 2.0)

func _dot_hits_blocker(center: Vector2, radius: float) -> bool:
	var rect := Rect2(center - Vector2(radius + 12.0, radius * dot_height_scale + 12.0), Vector2((radius + 12.0) * 2.0, (radius * dot_height_scale + 12.0) * 2.0))
	for raw_blocker in blockers:
		if raw_blocker is Rect2 and rect.intersects(raw_blocker as Rect2):
			return true
	return false

func _unit(noise_seed: float) -> float:
	return fposmod(sin(noise_seed * 12.9898 + 78.233) * 43758.5453, 1.0)
