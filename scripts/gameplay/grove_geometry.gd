extends RefCounted

const HERO_SIDE := 152.5
const HERO_FRAME_SIZE := 640.0
const HERO_GROUND := Vector2(320,600)
const AXE_CONTACT := Vector2(604,464)
const TREE_SIDE := 200.0
# Authored left/right bark edges at the swing's strike height in each 512px tree.
const TRUNK_EDGES := [Vector2(210,308),Vector2(199,283),Vector2(174,299),Vector2(190,306),Vector2(124,359),Vector2(149,335)]

static func horizontal_projection(depth: float) -> float:
	var vertical:=lerpf(-.38,.65,clampf((depth-.32)/.59,0,1))
	return sqrt(1.0-vertical*vertical)*.9

static func tree_side(bountiful: bool,legacy_bonus: bool) -> float:
	return TREE_SIDE*(1.12 if bountiful else (1.08 if legacy_bonus else 1.0))

static func chopping_position(tree: Vector2,index: int,direction: float,side: float,field_size: Vector2) -> Vector2:
	var edges: Vector2=TRUNK_EDGES[clampi(index,0,TRUNK_EDGES.size()-1)]
	var bark_x: float=edges.x if direction>0 else edges.y
	var bark_offset: float=(bark_x-256.0)*side/512.0
	var blade_reach: float=(AXE_CONTACT.x-HERO_GROUND.x)*HERO_SIDE/HERO_FRAME_SIZE
	# Keep the worker just in front of the trunk's ground plane, avoiding
	# floating-point ties in canopy fading and depth ordering.
	var worker_depth: float=tree.y+.001
	# Convert the authored draw-space contact point back through the stage's
	# oval projection, including the slightly different ground depths.
	var width_scale: float=field_size.x/900.0
	var actor_scale: float=minf(width_scale,field_size.y/360.0)*(.82+tree.y*.28)
	var worker_scale: float=minf(width_scale,field_size.y/360.0)*(.82+worker_depth*.28)
	var bark_screen_x: float=(tree.x-450)*width_scale*horizontal_projection(tree.y)+bark_offset*actor_scale
	var worker_screen_x: float=bark_screen_x-direction*(blade_reach-2.0)*worker_scale
	return Vector2(450+worker_screen_x/(width_scale*horizontal_projection(worker_depth)),worker_depth)
