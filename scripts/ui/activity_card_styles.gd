extends RefCounted

const ActivityCardDepth = preload("res://scripts/ui/activity_card_depth.gd")
const PaperButtonStyles = preload("res://scripts/ui/paper_button_styles.gd")

const NORMAL_ACTIVITY_CARD_DEPTH_OFFSET := Vector2(0.0, 36.0)
const RECOVERY_ACTIVITY_CARD_DEPTH_OFFSET := Vector2(0.0, 72.0)
const NORMAL_ACTIVITY_CARD_PRESS_OFFSET := NORMAL_ACTIVITY_CARD_DEPTH_OFFSET
const RECOVERY_WIDE_U_BOTTOM_RISE := 72.0
const RECOVERY_WIDE_U_SHOULDER_RATIO := 0.285
const RECOVERY_WIDE_U_RAIL_HEIGHT := 220.0
const ACTION_CARD_STROKE_WIDTH := 12.0

static var activity_shade_style_cache := {}
static var action_art_style_cache: StyleBoxFlat
static var action_art_border_style_cache: StyleBoxFlat

class LockedModuleShade extends Panel:
	var shade_style := StyleBoxFlat.new()

	func _init() -> void:
		shade_style.bg_color = Color(0.50, 0.50, 0.50, 0.42)
		shade_style.set_corner_radius_all(54)
		shade_style.anti_aliasing = true
		add_theme_stylebox_override("panel", shade_style)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_wash_alpha(next_alpha: float) -> void:
		shade_style.bg_color.a = clampf(0.30 + next_alpha * 0.60, 0.0, 0.72)


class PageSwitchButtonFace extends Control:
	var side := ""
	var fill_color := Color("#32c5bd")
	var ink_color := Color("#171615")
	var stroke_width := 10.0
	var radius := 66.0
	var diagonal_radius := 32.0
	var diagonal_width := 96.0
	var arrow_edge_width := 76.0
	var arrow_corner_radius := 26.0
	var draw_fill := true
	var draw_stroke := true
	var draw_depth_connectors := false
	var depth_offset := Vector2.ZERO
	var face_offset := Vector2.ZERO

	func set_face_offset(next_offset: Vector2) -> void:
		var clamped_offset := Vector2(
			clampf(next_offset.x, 0.0, maxf(0.0, depth_offset.x)),
			clampf(next_offset.y, 0.0, maxf(0.0, depth_offset.y))
		)
		if face_offset.is_equal_approx(clamped_offset):
			return
		face_offset = clamped_offset
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var points := _shape_points()
		if points.size() < 3:
			return
		if draw_fill and draw_stroke:
			draw_polygon(points, PackedColorArray([ink_color]))
			var inset_polygons := Geometry2D.offset_polygon(points, -stroke_width, Geometry2D.JOIN_ROUND)
			if not inset_polygons.is_empty():
				draw_polygon(inset_polygons[0], PackedColorArray([fill_color]))
		elif draw_fill:
			draw_polygon(points, PackedColorArray([fill_color]))
		if draw_depth_connectors:
			_draw_depth_connectors(points)
		if draw_stroke and not draw_fill:
			var stroke_polygons := Geometry2D.offset_polygon(points, -stroke_width * 0.5, Geometry2D.JOIN_ROUND)
			if stroke_polygons.is_empty():
				return
			var closed := PackedVector2Array(stroke_polygons[0])
			closed.append(closed[0])
			draw_polyline(closed, ink_color, stroke_width, true)
			for point in stroke_polygons[0]:
				draw_circle(point, stroke_width * 0.5, ink_color, true, -1.0, true)

	func _draw_depth_connectors(points: PackedVector2Array) -> void:
		var connector_offset := face_offset - depth_offset
		if connector_offset.length_squared() <= 0.25:
			return
		var width := maxf(3.0, stroke_width * 0.72)
		var top_right := _extreme_shape_point(points, 1.0)
		var bottom_left := _extreme_shape_point(points, -1.0)
		draw_line(top_right + connector_offset, top_right, ink_color, width, true)
		draw_line(bottom_left + connector_offset, bottom_left, ink_color, width, true)

	func _extreme_shape_point(points: PackedVector2Array, direction: float) -> Vector2:
		var best := points[0]
		var best_score := direction * (best.x - best.y)
		for point in points:
			var score := direction * (point.x - point.y)
			if score > best_score:
				best = point
				best_score = score
		return best

	func _shape_points() -> PackedVector2Array:
		var w := size.x
		var h := size.y
		var arrow := minf(arrow_edge_width, w * 0.34)
		var vertices := PackedVector2Array()
		if side == "right":
			vertices.append(Vector2(0.0, h * 0.5))
			vertices.append(Vector2(arrow, 0.0))
			vertices.append(Vector2(w, 0.0))
			vertices.append(Vector2(w, h))
			vertices.append(Vector2(arrow, h))
		else:
			vertices.append(Vector2(0.0, 0.0))
			vertices.append(Vector2(w - arrow, 0.0))
			vertices.append(Vector2(w, h * 0.5))
			vertices.append(Vector2(w - arrow, h))
			vertices.append(Vector2(0.0, h))
		return _rounded_polygon(vertices)

	func _rounded_polygon(vertices: PackedVector2Array) -> PackedVector2Array:
		var rounded := PackedVector2Array()
		var count := vertices.size()
		if count < 3:
			return rounded
		for index in range(count):
			var previous := vertices[(index - 1 + count) % count]
			var current := vertices[index]
			var next := vertices[(index + 1) % count]
			var incoming := previous - current
			var outgoing := next - current
			if incoming.length_squared() <= 0.01 or outgoing.length_squared() <= 0.01:
				_append_unique_shape_point(rounded, current)
				continue
			var corner_radius := _corner_radius(index)
			var max_radius := minf(incoming.length(), outgoing.length()) * 0.46
			var r := clampf(corner_radius, 0.0, max_radius)
			var start := current + incoming.normalized() * r
			var finish := current + outgoing.normalized() * r
			_append_unique_shape_point(rounded, start)
			for step in range(1, 8):
				var t := float(step) / 8.0
				var a := start.lerp(current, t)
				var b := current.lerp(finish, t)
				_append_unique_shape_point(rounded, a.lerp(b, t))
			_append_unique_shape_point(rounded, finish)
		return rounded

	func _is_diagonal_corner(index: int) -> bool:
		if side == "right":
			return index == 2 or index == 3
		return index == 0 or index == 4

	func _corner_radius(index: int) -> float:
		if not side.is_empty():
			return arrow_corner_radius
		if _is_diagonal_corner(index):
			return diagonal_radius
		return radius

	func _append_unique_shape_point(points: PackedVector2Array, point: Vector2) -> void:
		if points.is_empty() or points[points.size() - 1].distance_squared_to(point) > 0.01:
			points.append(point)


class PrismConnectorOverlay extends Control:
	var side := ""
	var ink_color := Color("#171615")
	var side_fill_color := Color("#8f521f")
	var bottom_fill_color := Color("#c8792c")
	var stroke_width := ACTION_CARD_STROKE_WIDTH
	var radius := 66.0
	var diagonal_radius := 32.0
	var diagonal_width := 96.0
	var arrow_edge_width := 76.0
	var arrow_corner_radius := 26.0
	var depth_offset := Vector2.ZERO
	var face_offset := Vector2.ZERO
	var face_gutter := 0.0
	var face_bottom_inset := 0.0
	var draw_fill := true
	var draw_strokes := true

	func set_face_offset(next_offset: Vector2) -> void:
		var clamped_offset := Vector2(
			clampf(next_offset.x, 0.0, maxf(0.0, depth_offset.x)),
			clampf(next_offset.y, 0.0, maxf(0.0, depth_offset.y))
		)
		if face_offset.is_equal_approx(clamped_offset):
			return
		face_offset = clamped_offset
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var face_size := _connector_face_size()
		if face_size.x <= 1.0 or face_size.y <= 1.0:
			return
		var travel := depth_offset - face_offset
		if travel.length_squared() <= 0.25:
			return
		var points := _connector_points()
		if points.size() != 2:
			return
		if draw_fill:
			if side.is_empty():
				_draw_rounded_prism_fill(travel)
			else:
				_draw_side_faces(travel)
		if draw_strokes:
			if side.is_empty():
				_draw_rounded_prism_outline(points, travel)
			else:
				_draw_side_face_outline(travel)

	func _connector_points() -> PackedVector2Array:
		if side.is_empty():
			return _rounded_rect_connector_points()
		var shape_points := _diagonal_shape_points()
		if shape_points.size() < 3:
			return PackedVector2Array()
		return _diagonal_connector_points(shape_points)

	func _diagonal_connector_points(_points: PackedVector2Array) -> PackedVector2Array:
		var origin := _connector_face_origin()
		var top_right := _extreme_shape_point(_points, Vector2(1.0, -1.0))
		var bottom_left := _extreme_shape_point(_points, Vector2(-1.0, 1.0))
		return PackedVector2Array([
			origin + top_right,
			origin + bottom_left,
		])

	func _draw_rounded_prism_outline(connectors: PackedVector2Array, travel: Vector2) -> void:
		var half := stroke_width * 0.5
		var direction := travel.normalized()
		var back_perimeter := _rounded_visible_perimeter(_connector_face_origin() + travel, _connector_face_size(), half, travel)
		var path := PackedVector2Array([connectors[0] + direction * half, back_perimeter[0]])
		for index in range(1, back_perimeter.size()):
			path.append(back_perimeter[index])
		path.append(connectors[1] + direction * half)
		draw_polyline(path, ink_color, stroke_width, false)

	func _draw_rounded_prism_fill(travel: Vector2) -> void:
		var fill_inset := stroke_width / 3.0
		var front_perimeter := _rounded_visible_perimeter(_connector_face_origin(), _connector_face_size(), fill_inset, travel)
		var back_perimeter := _rounded_visible_perimeter(_connector_face_origin() + travel, _connector_face_size(), fill_inset, travel)
		var polygon := PackedVector2Array(front_perimeter)
		for index in range(back_perimeter.size() - 1, -1, -1):
			polygon.append(back_perimeter[index])
		draw_polygon(polygon, PackedColorArray([side_fill_color]))

	func _rounded_visible_perimeter(origin: Vector2, face_size: Vector2, inset: float, travel: Vector2) -> PackedVector2Array:
		var corner_radius := maxf(0.0, minf(radius, minf(face_size.x, face_size.y) * 0.5 - inset))
		var tangent_normal := Vector2(travel.y, -travel.x).normalized()
		var top_right_center := origin + Vector2(face_size.x - inset - corner_radius, inset + corner_radius)
		var bottom_right_center := origin + Vector2(face_size.x - inset - corner_radius, face_size.y - inset - corner_radius)
		var bottom_left_center := origin + Vector2(inset + corner_radius, face_size.y - inset - corner_radius)
		var start_angle := atan2(tangent_normal.y, tangent_normal.x)
		var finish_angle := atan2(-tangent_normal.y, -tangent_normal.x)
		var perimeter := PackedVector2Array([top_right_center + tangent_normal * corner_radius])
		_append_prism_arc(perimeter, top_right_center, corner_radius, start_angle, 0.0)
		perimeter.append(bottom_right_center + Vector2(corner_radius, 0.0))
		_append_prism_arc(perimeter, bottom_right_center, corner_radius, 0.0, PI * 0.5)
		perimeter.append(bottom_left_center + Vector2(0.0, corner_radius))
		_append_prism_arc(perimeter, bottom_left_center, corner_radius, PI * 0.5, finish_angle)
		return perimeter

	func _append_prism_arc(path: PackedVector2Array, center: Vector2, arc_radius: float, start_angle: float, finish_angle: float) -> void:
		for step in range(1, 9):
			var angle := lerpf(start_angle, finish_angle, float(step) / 8.0)
			path.append(center + Vector2(cos(angle), sin(angle)) * arc_radius)

	func _diagonal_corner_inset(current: Vector2, previous: Vector2, next: Vector2) -> float:
		var incoming := previous - current
		var outgoing := next - current
		if incoming.length_squared() <= 0.01 or outgoing.length_squared() <= 0.01:
			return 0.0
		var max_radius := minf(incoming.length(), outgoing.length()) * 0.46
		return clampf(diagonal_radius, 0.0, max_radius)

	func _rounded_rect_connector_points() -> PackedVector2Array:
		var origin := _connector_face_origin()
		var face_size := _connector_face_size()
		if face_size.x <= stroke_width or face_size.y <= stroke_width:
			return PackedVector2Array()
		var half := stroke_width * 0.5
		var corner_radius := maxf(0.0, minf(radius, minf(face_size.x, face_size.y) * 0.5 - half))
		var travel := depth_offset - face_offset
		var tangent_normal := Vector2(travel.y, -travel.x).normalized()
		var top_right_center := Vector2(face_size.x - half - corner_radius, half + corner_radius)
		var bottom_left_center := Vector2(half + corner_radius, face_size.y - half - corner_radius)
		var top_right := origin + top_right_center + tangent_normal * corner_radius
		var bottom_left := origin + bottom_left_center - tangent_normal * corner_radius
		return PackedVector2Array([top_right, bottom_left])

	func _diagonal_shape_points() -> PackedVector2Array:
		var face_size := _connector_face_size()
		var w := face_size.x
		var h := face_size.y
		var arrow := minf(arrow_edge_width, w * 0.34)
		var vertices := PackedVector2Array()
		if side == "right":
			vertices.append(Vector2(0.0, h * 0.5))
			vertices.append(Vector2(arrow, 0.0))
			vertices.append(Vector2(w, 0.0))
			vertices.append(Vector2(w, h))
			vertices.append(Vector2(arrow, h))
		else:
			vertices.append(Vector2(0.0, 0.0))
			vertices.append(Vector2(w - arrow, 0.0))
			vertices.append(Vector2(w, h * 0.5))
			vertices.append(Vector2(w - arrow, h))
			vertices.append(Vector2(0.0, h))
		return _rounded_polygon(vertices)

	func _draw_side_faces(travel: Vector2) -> void:
		var points := _diagonal_shape_points() if not side.is_empty() else _rounded_rect_shape_points()
		if points.size() < 3:
			return
		var origin := _connector_face_origin()
		for index in range(points.size()):
			var p0 := points[index]
			var p1 := points[(index + 1) % points.size()]
			var normal := _edge_outward_normal(p0, p1)
			if not _side_face_visible(normal, travel):
				continue
			var face := PackedVector2Array([
				origin + p0,
				origin + p1,
				origin + p1 + travel,
				origin + p0 + travel,
			])
			draw_polygon(face, PackedColorArray([_side_face_color(normal)]))

	func _draw_side_face_outline(travel: Vector2) -> void:
		var points := _diagonal_shape_points() if not side.is_empty() else _rounded_rect_shape_points()
		if points.size() < 3:
			return
		var inset_polygons := Geometry2D.offset_polygon(points, -stroke_width * 0.5, Geometry2D.JOIN_ROUND)
		if inset_polygons.is_empty():
			return
		points = inset_polygons[0]
		var origin := _connector_face_origin()
		var visible := PackedByteArray()
		for index in range(points.size()):
			visible.append(1 if _side_face_visible(_edge_outward_normal(points[index], points[(index + 1) % points.size()]), travel) else 0)
		var start_index := -1
		for index in range(points.size()):
			if visible[index] == 1 and visible[(index - 1 + points.size()) % points.size()] == 0:
				start_index = index
				break
		if start_index < 0:
			return
		var direction := travel.normalized()
		var outline := PackedVector2Array([
			origin + points[start_index] + direction * stroke_width * 0.5,
			origin + points[start_index] + travel,
		])
		var index := start_index
		while visible[index] == 1:
			outline.append(origin + points[(index + 1) % points.size()] + travel)
			index = (index + 1) % points.size()
			if index == start_index:
				break
		var back_end := outline[outline.size() - 1]
		outline.append(back_end - travel + direction * stroke_width * 0.5)
		draw_polyline(outline, ink_color, stroke_width, true)
		for point in outline:
			draw_circle(point, stroke_width * 0.5, ink_color, true, -1.0, true)

	func _rounded_rect_shape_points() -> PackedVector2Array:
		var face_size := _connector_face_size()
		return _rounded_polygon(PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(face_size.x, 0.0),
			Vector2(face_size.x, face_size.y),
			Vector2(0.0, face_size.y),
		]))

	func _edge_outward_normal(p0: Vector2, p1: Vector2) -> Vector2:
		var edge := p1 - p0
		if edge.length_squared() <= 0.001:
			return Vector2.ZERO
		return Vector2(edge.y, -edge.x).normalized()

	func _side_face_visible(normal: Vector2, travel: Vector2) -> bool:
		if normal.length_squared() <= 0.001 or normal.dot(travel) <= 0.15:
			return false
		if absf(travel.x) <= 0.01:
			return normal.y > 0.01
		return normal.x > 0.08 or normal.y > 0.56

	func _side_face_color(normal: Vector2) -> Color:
		var positive_x := maxf(0.0, normal.x)
		var positive_y := maxf(0.0, normal.y)
		var bottom_weight := positive_y / maxf(0.001, positive_x + positive_y)
		return side_fill_color.lerp(bottom_fill_color, bottom_weight)

	func _connector_face_origin() -> Vector2:
		return Vector2(face_gutter, 0.0) + face_offset

	func _connector_face_size() -> Vector2:
		return Vector2(
			maxf(0.0, size.x - face_gutter * 2.0),
			maxf(0.0, size.y - face_bottom_inset)
		)

	func _rounded_polygon(vertices: PackedVector2Array) -> PackedVector2Array:
		var rounded := PackedVector2Array()
		var count := vertices.size()
		if count < 3:
			return rounded
		for index in range(count):
			var previous := vertices[(index - 1 + count) % count]
			var current := vertices[index]
			var next := vertices[(index + 1) % count]
			var incoming := previous - current
			var outgoing := next - current
			if incoming.length_squared() <= 0.01 or outgoing.length_squared() <= 0.01:
				_append_unique_shape_point(rounded, current)
				continue
			var corner_radius := _corner_radius(index)
			var max_radius := minf(incoming.length(), outgoing.length()) * 0.46
			var r := clampf(corner_radius, 0.0, max_radius)
			var start := current + incoming.normalized() * r
			var finish := current + outgoing.normalized() * r
			_append_unique_shape_point(rounded, start)
			for step in range(1, 8):
				var t := float(step) / 8.0
				var a := start.lerp(current, t)
				var b := current.lerp(finish, t)
				_append_unique_shape_point(rounded, a.lerp(b, t))
			_append_unique_shape_point(rounded, finish)
		return rounded

	func _is_diagonal_corner(index: int) -> bool:
		if side == "right":
			return index == 2 or index == 3
		return index == 0 or index == 4

	func _corner_radius(index: int) -> float:
		if not side.is_empty():
			return arrow_corner_radius
		if _is_diagonal_corner(index):
			return diagonal_radius
		return radius

	func _extreme_shape_point(points: PackedVector2Array, direction: Vector2) -> Vector2:
		var best := points[0]
		var best_score := best.dot(direction)
		for point in points:
			var score := point.dot(direction)
			if score > best_score:
				best = point
				best_score = score
		return best

	func _append_unique_shape_point(points: PackedVector2Array, point: Vector2) -> void:
		if points.is_empty() or points[points.size() - 1].distance_squared_to(point) > 0.01:
			points.append(point)


class ActionArtMasteryRing extends Control:
	var ring_color := Color("#ffd02f")
	var empty_color := Color("#862d2d")
	var ring_shadow_color := Color("#171615")
	var stroke_width := 40.0
	var shadow_width := 64.0
	var radius := 58.0
	var inset := 2.0
	var gap_start_fraction := 0.10
	var gap_finish_fraction := 0.84
	var progress := 0.5

	func set_progress(next_progress: float) -> void:
		var clamped := clampf(next_progress, 0.0, 1.0)
		if absf(progress - clamped) <= 0.001:
			return
		progress = clamped
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		var points := _rounded_rect_points()
		var start := gap_start_fraction
		var finish := gap_finish_fraction
		_draw_path_segment(points, ring_shadow_color, shadow_width, start, finish)
		_draw_path_segment(points, empty_color, stroke_width, start, finish)
		_draw_path_segment(points, ring_color, stroke_width, start, lerpf(start, finish, clampf(progress, 0.0, 1.0)))

	func _rounded_rect_points() -> PackedVector2Array:
		var half_width := shadow_width * 0.5
		var left := inset + half_width
		var top := inset + half_width
		var right := size.x - inset - half_width
		var bottom := size.y - inset - half_width
		var r := minf(radius, minf((right - left), (bottom - top)) * 0.5)
		var path := PackedVector2Array()
		path.append(Vector2(left + r, top))
		path.append(Vector2(right - r, top))
		_append_arc_points(path, Vector2(right - r, top + r), r, -PI * 0.5, 0.0)
		path.append(Vector2(right, bottom - r))
		_append_arc_points(path, Vector2(right - r, bottom - r), r, 0.0, PI * 0.5)
		path.append(Vector2(left + r, bottom))
		_append_arc_points(path, Vector2(left + r, bottom - r), r, PI * 0.5, PI)
		path.append(Vector2(left, top + r))
		_append_arc_points(path, Vector2(left + r, top + r), r, PI, PI * 1.5)
		path.append(Vector2(left + r, top))
		return path

	func _append_arc_points(path: PackedVector2Array, center: Vector2, arc_radius: float, start_angle: float, end_angle: float) -> void:
		for step in range(1, 25):
			var t := float(step) / 24.0
			var angle := lerpf(start_angle, end_angle, t)
			path.append(center + Vector2(cos(angle), sin(angle)) * arc_radius)

	func _draw_path_segment(points: PackedVector2Array, color: Color, width: float, start_fraction: float, finish_fraction: float) -> void:
		if points.size() < 2 or finish_fraction <= start_fraction:
			return
		var total := _path_length(points)
		var start_distance := total * clampf(start_fraction, 0.0, 1.0)
		var finish_distance := total * clampf(finish_fraction, 0.0, 1.0)
		var drawn := 0.0
		var visible_path := PackedVector2Array()
		for index in range(points.size() - 1):
			var segment_start := points[index]
			var segment_finish := points[index + 1]
			var length := segment_start.distance_to(segment_finish)
			var next_drawn := drawn + length
			if next_drawn <= start_distance:
				drawn = next_drawn
				continue
			if drawn >= finish_distance:
				break
			var a := maxf(start_distance, drawn)
			var b := minf(finish_distance, next_drawn)
			var local_start := segment_start.lerp(segment_finish, (a - drawn) / length)
			var local_finish := segment_start.lerp(segment_finish, (b - drawn) / length)
			if visible_path.is_empty():
				visible_path.append(local_start)
			elif visible_path[visible_path.size() - 1].distance_squared_to(local_start) > 0.01:
				visible_path.append(local_start)
			visible_path.append(local_finish)
			drawn = next_drawn
		if visible_path.size() >= 2:
			draw_polyline(visible_path, color, width, true)
			draw_circle(visible_path[0], width * 0.5, color)
			draw_circle(visible_path[visible_path.size() - 1], width * 0.5, color)

	func _path_length(points: PackedVector2Array) -> float:
		var total := 0.0
		for index in range(points.size() - 1):
			total += points[index].distance_to(points[index + 1])
		return total


static func cached_shade(alpha: float) -> StyleBoxFlat:
	var key := int(round(alpha * 1000.0))
	if activity_shade_style_cache.has(key):
		return activity_shade_style_cache[key] as StyleBoxFlat
	var style := shade(alpha)
	activity_shade_style_cache[key] = style
	return style


static func cached_action_art(surface_style: Callable) -> StyleBoxFlat:
	if action_art_style_cache != null:
		return action_art_style_cache
	action_art_style_cache = action_art(surface_style)
	return action_art_style_cache


static func cached_action_art_border(surface_style: Callable) -> StyleBoxFlat:
	if action_art_border_style_cache != null:
		return action_art_border_style_cache
	action_art_border_style_cache = action_art_border(cached_action_art(surface_style))
	return action_art_border_style_cache


static func clear_cache() -> void:
	activity_shade_style_cache.clear()
	action_art_style_cache = null
	action_art_border_style_cache = null


static func featured_art(surface_style: Callable, line_color: Color) -> StyleBoxFlat:
	var style := surface_style.call(Color("#fffaf0"), 24, 8, true) as StyleBoxFlat
	style.border_color = line_color
	style.set_border_width_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func shade(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.5, 0.5, alpha)
	style.set_corner_radius_all(54)
	return style


static func activity_card_title_z_index(unlocked: bool, title: CanvasItem = null, module_title_over_pin_z_index := 0) -> int:
	if unlocked:
		return module_title_over_pin_z_index
	if title != null and is_instance_valid(title) and title.has_meta("activity_card_locked_title_z_index"):
		return int(title.get_meta("activity_card_locked_title_z_index"))
	return 0


static func activity_card_title_text(raw_title: String) -> String:
	return raw_title.replace("\u2009", "").replace(" - ", "-").replace("-", "\u2009–\u2009")


static func sync_activity_card_title_layer(card: Dictionary, unlocked: bool, module_title_over_pin_z_index := 0) -> void:
	var title := _valid_canvas_item_ref(card.get("title"))
	if title == null:
		return
	var next_z_index := activity_card_title_z_index(unlocked, title, module_title_over_pin_z_index)
	if title.z_index != next_z_index:
		title.z_index = next_z_index


static func root_height(expanded: bool, action_card_height: float, action_card_expanded_height: float, depth_offset_y: float) -> float:
	var face_height := action_card_expanded_height if expanded else action_card_height
	return float(face_height) + depth_offset_y


static func root_height_for_action(action: Dictionary, expanded: bool, uses_diamond_arena: bool, action_card_height: float, expanded_height: float, diamond_height: float, depth_offset_y: float) -> float:
	if uses_diamond_arena:
		return float(diamond_height) + depth_offset_y
	return root_height(expanded, action_card_height, expanded_height, depth_offset_y)


static func mat_collection_layout_height(skill_id: String, action: Dictionary, has_mat_rewards: bool, running_skill_id: String, running_action_id: String, mat_collection_area_height: float) -> float:
	var action_id := str(action.get("id", ""))
	if action_id.is_empty() or not has_mat_rewards:
		return 0.0
	return mat_collection_area_height if running_skill_id == skill_id and running_action_id == action_id else 0.0


static func preview_root_height(card: Dictionary, passive_height: float, default_root_height: float) -> float:
	if bool(card.get("passive", false)):
		return passive_height
	return default_root_height


static func _valid_canvas_item_ref(value) -> CanvasItem:
	if value == null:
		return null
	if typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value as CanvasItem


static func action_card_background_edge_underlay(fill_color: Color, radius: float) -> Panel:
	var underlay := Panel.new()
	underlay.anchor_left = 0.0
	underlay.anchor_right = 1.0
	underlay.anchor_top = 0.0
	underlay.anchor_bottom = 1.0
	underlay.offset_left = -3.0
	underlay.offset_right = 3.0
	underlay.offset_top = -3.0
	underlay.offset_bottom = 3.0
	underlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	underlay.z_index = 149
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(int(round(radius + 3.0)))
	style.anti_aliasing = true
	underlay.add_theme_stylebox_override("panel", style)
	return underlay


static func activity_card_face_skin(fill_color: Color, radius: float, cache: Dictionary, ink: Color, blue: Color, can_create: Callable, create_texture: Callable, fallback_texture: Callable) -> StyleBoxTexture:
	var style := PaperButtonStyles.chunky_activity_button_style(fill_color, int(round(radius)), 0, false, false, cache, ink, blue, can_create, create_texture, fallback_texture)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


static func activity_card_face_outline_skin(radius: float, cache: Dictionary, ink: Color, blue: Color, can_create: Callable, create_texture: Callable, fallback_texture: Callable) -> StyleBoxTexture:
	return activity_card_face_skin(Color(0, 0, 0, 0), radius, cache, ink, blue, can_create, create_texture, fallback_texture)


static func activity_card_art_outline_skin(radius: float, cache: Dictionary, ink: Color, can_create: Callable, create_texture: Callable, fallback_texture: Callable) -> StyleBoxTexture:
	var key := "activity_art_outline:%s:%s" % [radius, ink.to_html(true)]
	if cache.has(key):
		return cache[key] as StyleBoxTexture
	var style := StyleBoxTexture.new()
	if can_create.call():
		var final_size := Vector2i(160, 104)
		var supersample := 4.0
		var texture_size := Vector2i(int(final_size.x * supersample), int(final_size.y * supersample))
		var border := 4.0 * supersample
		var outer := Rect2(Vector2.ZERO, Vector2(float(texture_size.x), float(texture_size.y)))
		var inner := outer.grow(-border)
		var outer_radius := minf(radius * supersample, 44.0 * supersample)
		var inner_radius := maxf(1.0, outer_radius - border)
		var image := Image.create(texture_size.x, texture_size.y, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		for y in range(texture_size.y):
			for x in range(texture_size.x):
				var point := Vector2(float(x) + 0.5, float(y) + 0.5)
				if PaperButtonStyles.contains(point, outer, outer_radius) and not PaperButtonStyles.contains(point, inner, inner_radius):
					image.set_pixel(x, y, ink)
		image.resize(final_size.x, final_size.y, Image.INTERPOLATE_LANCZOS)
		style.texture = create_texture.call(image)
	else:
		style.texture = fallback_texture.call()
	style.texture_margin_left = 28
	style.texture_margin_right = 28
	style.texture_margin_top = 28
	style.texture_margin_bottom = 28
	cache[key] = style
	return style


static func activity_card_depth_layer(theme_color: Color, depth_offset: Vector2, radius: float, gutter: float) -> ActivityCardDepth:
	var depth := ActivityCardDepth.new()
	depth.depth_offset = depth_offset
	depth.radius = radius
	depth.back_color = theme_color.darkened(0.52)
	depth.side_color = theme_color.darkened(0.48)
	depth.bottom_color = theme_color.darkened(0.24)
	depth.draw_lip_lines = false
	depth.draw_back_plate_bottom_outline = true
	var highlight := theme_color.lightened(0.42)
	highlight.a = 0.24
	depth.highlight_color = highlight
	var themed_shadow := theme_color.darkened(0.72)
	themed_shadow.a = 0.28
	depth.shadow_color = themed_shadow
	depth.anchor_left = 0.0
	depth.anchor_right = 1.0
	depth.anchor_top = 0.0
	depth.anchor_bottom = 1.0
	depth.offset_left = gutter
	depth.offset_right = -gutter + depth_offset.x
	depth.offset_top = 0.0
	depth.offset_bottom = 0.0
	depth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	depth.z_index = 0
	return depth


static func apply_normal_activity_card_depth(depth: ActivityCardDepth, theme_color := Color("#e84d4d")) -> void:
	if depth == null:
		return
	depth.back_color = theme_color.darkened(0.42)
	depth.side_color = depth.back_color
	depth.bottom_color = depth.back_color
	depth.draw_lip_lines = false
	depth.draw_back_plate_bottom_outline = false


static func normal_activity_card_bottom_base(radius: float, ink: Color, theme_color := Color("#e84d4d")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = theme_color.darkened(0.42)
	style.border_color = ink
	style.border_width_left = int(ACTION_CARD_STROKE_WIDTH)
	style.border_width_top = 0
	style.border_width_right = int(ACTION_CARD_STROKE_WIDTH)
	style.border_width_bottom = int(ACTION_CARD_STROKE_WIDTH)
	style.corner_radius_top_left = int(round(radius))
	style.corner_radius_top_right = int(round(radius))
	style.corner_radius_bottom_left = int(round(radius))
	style.corner_radius_bottom_right = int(round(radius))
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.25
	return style


static func normal_activity_card_body(radius: float, ink: Color, theme_color := Color("#e84d4d")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = theme_color.darkened(0.42)
	style.border_color = ink
	style.set_border_width_all(int(ACTION_CARD_STROKE_WIDTH))
	style.set_corner_radius_all(int(round(radius)))
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.5
	return style


static func action_art_mastery_ring(theme_color := Color("#e84d4d")) -> ActionArtMasteryRing:
	var ring := ActionArtMasteryRing.new()
	ring.empty_color = theme_color.darkened(0.42)
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.offset_left = -36.0
	ring.offset_top = -36.0
	ring.offset_right = 36.0
	ring.offset_bottom = 36.0
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ring


static func page_switch_button_face() -> PageSwitchButtonFace:
	return PageSwitchButtonFace.new()


static func is_page_switch_button_face(control: Object) -> bool:
	return control is PageSwitchButtonFace


static func prism_connector_overlay(depth_offset: Vector2, radius: float, side: String, stroke_width: float, ink_color: Color) -> PrismConnectorOverlay:
	var connector := PrismConnectorOverlay.new()
	connector.side = side
	connector.depth_offset = depth_offset
	connector.radius = radius
	connector.diagonal_radius = 32.0
	connector.stroke_width = stroke_width
	connector.ink_color = ink_color
	connector.set_anchors_preset(Control.PRESET_FULL_RECT)
	connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return connector


static func is_prism_connector_overlay(control: Object) -> bool:
	return control is PrismConnectorOverlay


static func activity_card_pop_base_bottom_offset(pop: Control) -> float:
	if pop == null or not is_instance_valid(pop):
		return 0.0
	var bottom_inset := 0.0
	if pop.has_meta("activity_card_depth_bottom_inset"):
		bottom_inset = float(pop.get_meta("activity_card_depth_bottom_inset"))
	return -bottom_inset


static func set_activity_card_depth_face_offset_from_pop(pop: Control, offset: Vector2, action_card_pop_gutter: float, action_card_depth_offset_y: float) -> void:
	if pop == null or not is_instance_valid(pop) or not pop.has_meta("activity_card_depth_node_id"):
		return
	var depth_id := int(pop.get_meta("activity_card_depth_node_id"))
	var depth := instance_from_id(depth_id)
	if depth == null or not is_instance_valid(depth):
		return
	if depth is ActivityCardDepth:
		(depth as ActivityCardDepth).set_face_offset(offset)
	elif depth is PageSwitchButtonFace:
		(depth as PageSwitchButtonFace).set_face_offset(offset)
	elif depth is PrismConnectorOverlay:
		(depth as PrismConnectorOverlay).set_face_offset(offset)
	if pop.has_meta("activity_card_connector_node_id"):
		var connector_id := int(pop.get_meta("activity_card_connector_node_id"))
		var connector := instance_from_id(connector_id) as PrismConnectorOverlay
		if connector != null and is_instance_valid(connector):
			connector.set_face_offset(offset)
	if pop.has_meta("activity_card_fill_node_id"):
		var fill_id := int(pop.get_meta("activity_card_fill_node_id"))
		var fill := instance_from_id(fill_id) as PrismConnectorOverlay
		if fill != null and is_instance_valid(fill):
			fill.set_face_offset(offset)
	if pop.has_meta("activity_card_outline_node_id"):
		var outline_id := int(pop.get_meta("activity_card_outline_node_id"))
		var outline = instance_from_id(outline_id)
		if outline is Control and is_instance_valid(outline):
			var outline_control := outline as Control
			var gutter := float(pop.get_meta("activity_button_gutter", action_card_pop_gutter))
			var bottom_inset := float(pop.get_meta("activity_button_depth_bottom_inset", action_card_depth_offset_y))
			outline_control.offset_left = gutter + offset.x
			outline_control.offset_right = -gutter + offset.x
			outline_control.offset_top = offset.y
			outline_control.offset_bottom = -bottom_inset + offset.y


static func activity_card_shade_layer(pop_card: Control, alpha := 0.20) -> Panel:
	if pop_card == null:
		return null
	var shade_panel := LockedModuleShade.new()
	shade_panel.set_wash_alpha(alpha)
	shade_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade_panel.visible = false
	shade_panel.z_index = 279
	shade_panel.offset_left = ACTION_CARD_STROKE_WIDTH
	shade_panel.offset_right = -ACTION_CARD_STROKE_WIDTH
	shade_panel.offset_top = ACTION_CARD_STROKE_WIDTH
	shade_panel.offset_bottom = float(pop_card.get_meta("activity_card_depth_bottom_inset", 0.0)) - ACTION_CARD_STROKE_WIDTH
	pop_card.add_child(shade_panel)
	return shade_panel


static func ensure_activity_card_shade(card: Dictionary, alpha := 0.20) -> Panel:
	var existing_panel := card.get("shade") as Panel
	if existing_panel != null and is_instance_valid(existing_panel):
		return existing_panel
	var pop_card := card.get("pop") as Control
	if pop_card == null or not is_instance_valid(pop_card):
		return null
	var shade_panel := activity_card_shade_layer(pop_card, alpha)
	card["shade"] = shade_panel
	return shade_panel


static func action_art(surface_style: Callable) -> StyleBoxFlat:
	var style := surface_style.call(Color.WHITE, 56, 16, true) as StyleBoxFlat
	style.border_color = Color("#171615")
	style.set_border_width_all(12)
	style.shadow_color = Color.TRANSPARENT
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


static func action_art_border(action_art_style: StyleBoxFlat) -> StyleBoxFlat:
	var style := action_art_style.duplicate() as StyleBoxFlat
	style.draw_center = false
	return style


static func art_glow(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.28)
	style.border_color = Color(color.r, color.g, color.b, 0.95)
	style.set_border_width_all(24)
	style.set_corner_radius_all(56)
	return style


static func bonus_emphasis(flash_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.20)
	style.border_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.88)
	style.set_border_width_all(18)
	style.set_corner_radius_all(38)
	style.shadow_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.42)
	style.shadow_size = 18
	style.shadow_offset = Vector2.ZERO
	return style


static func bonus_bottom_highlight(flash_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.28)
	style.border_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.95)
	style.set_border_width_all(14)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.34)
	style.shadow_size = 16
	style.shadow_offset = Vector2.ZERO
	return style


static func tutorial_target_ring() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.89, 0.24, 0.0)
	style.draw_center = false
	style.border_color = Color("#ffd94d")
	style.set_border_width_all(12)
	style.set_corner_radius_all(54)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


static func crit_glow(mega_crit := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var fill := Color("#fff052") if mega_crit else Color("#67b8ff")
	var border := Color("#ffbf1f") if mega_crit else Color("#1f9dff")
	style.draw_center = true
	style.bg_color = Color(fill.r, fill.g, fill.b, 0.34 if mega_crit else 0.31)
	style.border_color = Color(border.r, border.g, border.b, 1.0 if mega_crit else 0.96)
	style.set_border_width_all(68 if mega_crit else 46)
	style.shadow_color = Color(1.0, 0.70, 0.0, 0.82) if mega_crit else Color(0.10, 0.58, 1.0, 0.62)
	style.shadow_size = 68 if mega_crit else 42
	style.shadow_offset = Vector2.ZERO
	style.set_corner_radius_all(82 if mega_crit else 66)
	return style


static func button_face(fill: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(int(round(radius)))
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.25
	return style
