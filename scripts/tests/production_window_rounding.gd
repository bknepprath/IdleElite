extends SceneTree

const Rail=preload("res://scripts/ui/activity_progress_rail.gd")
var failures: Array[String]=[]
var audited:=0
var maximum_turn:=0.0
var maximum_boundary_step:=0.0
func check(ok: bool,message: String) -> void:
	if not ok and failures.size()<20: failures.append(message)

func polygon_area(points: PackedVector2Array) -> float:
	var total:=0.0
	for index in points.size(): total+=points[index].cross(points[(index+1)%points.size()])
	return absf(total)*.5

func audit_outline(points: PackedVector2Array,label: String) -> void:
	check(points.size()>12,label+" has rounded edges")
	check(not Geometry2D.triangulate_polygon(points).is_empty(),label+" remains a simple noncollapsed outline")
	for index in points.size():
		var point:=points[index]
		check(is_finite(point.x) and is_finite(point.y),label+" has finite geometry")
		var incoming:=point-points[posmod(index-1,points.size())]
		var outgoing:=points[(index+1)%points.size()]-point
		if incoming.length()<.001 or outgoing.length()<.001: continue
		var turn:=absf(incoming.angle_to(outgoing))
		maximum_turn=maxf(maximum_turn,turn)
		check(turn<.22,label+" has no sharp turn: "+str(rad_to_deg(turn)))
	audited+=1

func _init() -> void:
	var rail:=Rail.new()
	rail.bottom_shape="production_v"
	for width_px in [930,1400]:
		rail.size=Vector2(width_px,132)
		for width in [.16,.19,.21,.26,.4]:
			var centered: PackedVector2Array=rail._production_opportunity_outline(.5-width*.5,.5+width*.5)
			var bounds: Vector2=rail._production_band_bounds(rail.size.x*.5)
			for tip_y in [bounds.x,bounds.y]:
				var tip:=Vector2(rail.size.x*.5,tip_y)
				var clearance:=INF
				for index in centered.size(): clearance=minf(clearance,tip.distance_to(Geometry2D.get_closest_point_to_segment(tip,centered[index],centered[(index+1)%centered.size()])))
				check(Geometry2D.is_point_in_polygon(tip,centered) or clearance<9.1,"The rounded frame still contains the authored V tip")
			var last_area:=0.0
			var last_outline:=PackedVector2Array()
			for frame in range(1001):
				var start: float=(1-width)*float(frame)/1000
				var end: float=start+width
				var outline: PackedVector2Array=rail._production_opportunity_outline(start,end)
				var label:="%dpx width %.2f frame %d"%[width_px,width,frame]
				audit_outline(outline,label)
				var current_area:=polygon_area(outline)
				check(current_area>100,label+" never collapses at a bend")
				if frame>0 and absf(current_area-last_area)>200:
					var movement:=boundary_step(outline,last_outline)
					maximum_boundary_step=maxf(maximum_boundary_step,movement)
					check(movement<4,label+" has no boundary pop: "+str(movement))
				last_area=current_area
				last_outline=outline
				var windows: Array[Vector2]=[Vector2(start,end)]
				rail.set_opportunity_windows(windows,true,true)
				check(rail.has_opportunity_progress(start+.00001) and rail.has_opportunity_progress(end-.00001),label+" retains the full original click interval")
				if start>.001: check(not rail.has_opportunity_progress(start-.001),label+" does not extend the hit interval")
				if end<.999: check(not rail.has_opportunity_progress(end+.001),label+" does not extend the hit interval")
	# Width expansion, shrink and endpoint cases, including very small windows.
	for width in [.01,.03,.08,.6,1.0]:
		for start in [0.0,(1-width)*.5,1-width]: audit_outline(rail._production_opportunity_outline(start,start+width),"edge width "+str(width))
	rail.free()
	print("PRODUCTION_WINDOW_ROUNDING audited=",audited," max_turn_degrees=",rad_to_deg(maximum_turn)," max_corner_boundary_step=",maximum_boundary_step," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)

func boundary_step(current: PackedVector2Array,previous: PackedVector2Array) -> float:
	var maximum:=0.0
	for point in current:
		var nearest:=INF
		for index in previous.size():
			nearest=minf(nearest,point.distance_to(Geometry2D.get_closest_point_to_segment(point,previous[index],previous[(index+1)%previous.size()])))
		maximum=maxf(maximum,nearest)
	return maximum
