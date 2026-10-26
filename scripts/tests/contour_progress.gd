extends SceneTree

var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for index in range(polygon.size()):
		total += polygon[index].cross(polygon[(index+1)%polygon.size()])
	return absf(total)*.5

func _init() -> void:
	var rail = load("res://scripts/ui/activity_progress_rail.gd").new()
	for shape in ["production_v", "wide_u"]:
		rail.bottom_shape = shape
		rail.size = Vector2(930, 132 if shape == "production_v" else 80)
		var full: PackedVector2Array = rail._production_band_polygon(0,1,3) if shape == "production_v" else rail._wide_u_band_polygon(0,1,44)
		var full_area := area(full)
		check(full_area > 20000, shape+" has a complete visible rail")
		var last_area := 0.0
		var last_polygon := PackedVector2Array()
		for step in range(1001):
			var pct := float(step)/1000
			var polygon: PackedVector2Array = rail._production_band_polygon(0,pct,3) if shape == "production_v" else rail._wide_u_band_polygon(0,pct,44)
			var current_area := area(polygon)
			check(current_area+.01 >= last_area, shape+" never loses filled area at "+str(pct))
			check(current_area-last_area < full_area*.003, shape+" has no corner jump at "+str(pct))
			# The ink's end-cap inset is intentionally outside the colored fill.
			if step > 10 and step < 990:
				var section: PackedVector2Array = rail._contour_section(pct)
				var cap := PackedVector2Array()
				for point in polygon:
					if absf((point-section[0]).dot(section[1])) < .02: cap.append(point)
				check(cap.size() >= 2, shape+" has a normal cross-section at "+str(pct))
			last_area = current_area
			last_polygon = polygon
		check(absf(last_area-full_area) < .01, shape+" fills the unchanged full silhouette")
		check(last_polygon == full, shape+" completes without a residual seam")
		var left: PackedVector2Array = rail._production_band_polygon(0,.46,3) if shape == "production_v" else rail._wide_u_band_polygon(0,.46,44)
		var right: PackedVector2Array = rail._production_band_polygon(.46,1,3) if shape == "production_v" else rail._wide_u_band_polygon(.46,1,44)
		check(absf(area(left)+area(right)-full_area)<.5, shape+" adjacent segments share one boundary")
		rail.opportunity_windows.append(Vector2(.43,.49))
		if shape == "production_v":
			check(rail.get_opportunity_feedback_global_position().distance_to(rail._contour_section(.46)[0])<.01, "Timing feedback follows the contour interval")
		print("CONTOUR shape=",shape," area=",full_area," length=",rail.contour_distances[-1])
		check(absf(rail._contour_section(.46)[1].y)>.05, shape+" turns the moving edge on the slope")
		rail.contour_cache_key.clear()
		rail.size.x = 1400
		check(rail._contour_section(1)[0].x>1300,"Resizing invalidates cached geometry")
		rail.free()
		rail = load("res://scripts/ui/activity_progress_rail.gd").new()
	rail.free()
	print("CONTOUR_PROGRESS failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
