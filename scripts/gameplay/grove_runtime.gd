extends RefCounted

const SkillState = preload("res://scripts/progression/skill_state.gd")
const Geometry = preload("res://scripts/gameplay/grove_geometry.gd")
const KINDS := ["handle","head","grip","sharpening","gem"]
const ARENA_KINDS := ["capacity","regrowth","rarity"]
const IDS := ["grove-birch","grove-pine","grove-oak","grove-maple","grove-ancient","grove-ironwood"]
const TREE_COUNT := 2
const FIELD_DEPTH := 360.0
var host
var axe_xp := 0
var felled := 0
var upgrades := {"handle":0,"head":0,"grip":0,"sharpening":0,"gem":0}
var arena_upgrades: Dictionary = {}
var groves: Dictionary = {}
var field_sizes: Dictionary = {}
var worker_presence: Dictionary = {}
var active_grove_id := ""
var harvest_bursts: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _init(owner) -> void:
	host=owner
	rng.randomize()

func applies(skill: String,id: String) -> bool:
	return skill=="woodcutting" and id in IDS

func rules(id: String) -> Dictionary:
	return host._action_data("woodcutting",id).get("grove",{})

func arena_levels(id: String) -> Dictionary:
	if not arena_upgrades.has(id): arena_upgrades[id]={"capacity":0,"regrowth":0,"rarity":0}
	return arena_upgrades[id]

func tree_capacity(id: String) -> int:
	return int(rules(id).get("tree_capacity",TREE_COUNT))+int(arena_levels(id).capacity)

func regrowth_seconds(id: String) -> float:
	return float(rules(id).get("respawn_seconds",8))/(1+float(arena_levels(id).regrowth)*float(rules(id).get("regrowth_speed_per_level",.1)))

func stump_clear_seconds(id: String) -> float:
	var regrowth:=regrowth_seconds(id)
	return regrowth-minf(1.5,regrowth*.3)

func stump_opacity(id: String,tree: Dictionary) -> float:
	if tree.phase=="falling": return 1.0
	if tree.phase!="stump": return 0.0
	var clear_time:=stump_clear_seconds(id)
	var fade_seconds:=minf(.35,clear_time*.25)
	return 1.0-smoothstep(clear_time-fade_seconds,clear_time,float(tree.age))

func rare_chance(id: String) -> float:
	return float(rules(id).get("rare_chance",5))+float(arena_levels(id).rarity)*float(rules(id).get("rare_chance_per_level",7))

func arena_upgrade_cost(id: String,kind: String) -> Dictionary:
	if id not in IDS or kind not in ARENA_KINDS: return {}
	var level:=int(arena_levels(id)[kind])
	if level>=int(rules(id).get(kind+"_limit",3 if kind=="capacity" else 5)): return {}
	var prices: Dictionary=rules(id).get("upgrade_costs",{})
	return {"id":str(rules(id).material),"amount":int(prices.get(kind,20))*(level+1)*(level+1)}

func buy_arena_upgrade(id: String,kind: String) -> bool:
	if not applies("woodcutting",id) or not host._activity_unlock_runtime()._is_action_unlocked("woodcutting",host._action_data("woodcutting",id)): return false
	var cost:=arena_upgrade_cost(id,kind)
	if cost.is_empty() or host.material_runtime.amount(str(cost.id))<float(cost.amount): return false
	if not host.material_runtime.spend_amount(str(cost.id),float(cost.amount)): return false
	arena_levels(id)[kind]=int(arena_levels(id)[kind])+1
	if kind=="capacity":
		var s:=state(id)
		while s.trees.size()<tree_capacity(id): s.trees.append(new_tree(id,s.trees,0.0))
	host._mark_save_dirty("grove arena upgrade")
	return true

func source_id(id: String,tree: Dictionary) -> String:
	var source:=str(tree.get("source_id",id))
	return source if source in [id,str(rules(id).get("rare_tree",id))] else id

func tree_multiplier(id: String,tree: Dictionary) -> float:
	if bool(tree.get("bountiful",false)):
		var fractions: Array=rules(id).get("bountiful_bonus_fractions",[.125,.375,1.0])
		var fraction:=float(fractions[bountiful_level(tree)-1])
		return 1.0+(float(rules(id).get("bountiful_loot_multiplier",3))-1.0)*fraction
	return float(rules(id).get("rare_reward_multiplier",1)) if bool(tree.get("rare",false)) else 1.0

static func bountiful_level(tree: Dictionary) -> int:
	# Existing bonus trees retain the full bonus when their save has no level.
	return integer(tree.get("gold_leaves",3),1,3) if bool(tree.get("bountiful",false)) else 0

func tree_gold_leaf_count(id: String,tree: Dictionary) -> int:
	return bountiful_level(tree) if bool(tree.get("bountiful",false)) else (3 if tree_has_bonus_yield(id,tree) else 0)

func roll_bountiful_level(id: String) -> int:
	var weights: Array=rules(id).get("bountiful_leaf_weights",[60,30,10])
	var total:=0.0
	for weight in weights: total+=maxf(0,float(weight))
	var roll:=rng.randf()*total
	for index in mini(3,weights.size()):
		roll-=maxf(0,float(weights[index]))
		if roll<0: return index+1
	return 3

func tree_health(id: String,tree: Dictionary) -> int:
	return maxi(1,ceili(int(rules(source_id(id,tree)).get("health",3))*(1.0 if bool(tree.get("bountiful",false)) else tree_multiplier(id,tree))))

func tree_minimum_yield(id: String,tree: Dictionary) -> int:
	return maxi(1,floori(minimum_yield(source_id(id,tree))*tree_multiplier(id,tree))) if bool(tree.get("bountiful",false)) else ceili(minimum_yield(source_id(id,tree))*tree_multiplier(id,tree))

func tree_maximum_yield(id: String,tree: Dictionary) -> int:
	return ceili(maximum_yield(source_id(id,tree))*tree_multiplier(id,tree))

func tree_has_bonus_yield(id: String,tree: Dictionary) -> bool:
	return tree_minimum_yield(id,tree)>minimum_yield(id) or tree_maximum_yield(id,tree)>maximum_yield(id)

func roll_tree_yield(id: String,tree: Dictionary) -> int:
	if not bool(tree.get("bountiful",false)):
		return rng.randi_range(tree_minimum_yield(id,tree),tree_maximum_yield(id,tree))
	# Round only the final fractional reward probabilistically, preserving the
	# intended average boost even when the base harvest is just one or two logs.
	var scaled:=rng.randi_range(minimum_yield(source_id(id,tree)),maximum_yield(source_id(id,tree)))*tree_multiplier(id,tree)
	return floori(scaled)+(1 if rng.randf()<fposmod(scaled,1.0) else 0)

func tree_material(id: String,tree: Dictionary) -> String:
	return str(rules(source_id(id,tree)).get("material","softwood"))

func tree_xp_rewards(id: String,tree: Dictionary) -> Dictionary:
	var rewards: Dictionary=host._action_runtime()._effective_xp_reward_map(host._action_data("woodcutting",source_id(id,tree)),"woodcutting").duplicate()
	for skill in rewards: rewards[skill]=roundi(int(rewards[skill])*(1+float(upgrades.gem)*.1)*(1.0 if bool(tree.get("bountiful",false)) else tree_multiplier(id,tree)))
	return rewards

func new_tree(id: String,trees: Array,spawn_age: float=1.0,ignore_index: int=-1) -> Dictionary:
	var point:=spawn_position(trees,ignore_index)
	var rare:=rng.randf()*100<rare_chance(id)
	var bountiful:=rare and str(rules(id).get("rare_variant",""))=="bountiful"
	var source:=id if bountiful or not rare else str(rules(id).get("rare_tree",id))
	var tree: Dictionary={"x":point.x,"y":point.y,"source_id":source,"rare":rare,"bountiful":bountiful,"phase":"standing","age":0.0,"spawn_age":spawn_age,"hit":0.0,"fall_direction":1.0}
	tree.gold_leaves=roll_bountiful_level(id) if bountiful else 0
	tree.hp=tree_health(id,tree)
	return tree

func state(id: String) -> Dictionary:
	if not groves.has(id):
		var trees: Array[Dictionary] = []
		for index in tree_capacity(id): trees.append(new_tree(id,trees))
		groves[id]={"trees":trees,"x":450.0,"y":.78,"target":0,"phase":"walking","age":0.0,"direction":-1.0,"contact":false,"reward_age":10.0,"reward_count":0,"last_index":-1,"reward_x":450.0,"reward_y":.6,"swings":0,"miss_age":10.0}
	return groves[id]

func spawn_position(trees: Array,ignore_index: int=-1) -> Vector2:
	var best:=Vector2(450,.6)
	var best_clearance: float=-1
	for attempt in 80:
		var point:=Vector2(rng.randf_range(110,790),rng.randf_range(.32,.91))
		# Leave the axe controls clear of tree crowns.
		if point.x>650 and point.y<.68: continue
		var clearance: float=INF
		for index in trees.size():
			if index==ignore_index: continue
			var other: Dictionary=trees[index]
			clearance=minf(clearance,Vector2(point.x-float(other.x),(point.y-float(other.y))*FIELD_DEPTH).length())
		if clearance>best_clearance:
			best=point
			best_clearance=clearance
		if clearance>=maxf(116,160-maxi(0,trees.size()-5)*14): break
	return best

static func depth_scale(depth: float) -> float:
	return .82+clampf(depth,0,1)*.28

func chopping_destination(id: String,tree: Dictionary,worker_x: float) -> Vector2:
	var direction:=1.0 if worker_x<float(tree.x) else -1.0
	var index:=int(rules(source_id(id,tree)).get("index",0))
	var side:=Geometry.tree_side(bool(tree.get("bountiful",false)),tree_multiplier(id,tree)>1)
	var field: Vector2=field_sizes.get(id,Vector2(900,360))
	var ground:=Vector2(float(tree.x),float(tree.y))
	var destination:=Geometry.chopping_position(ground,index,direction,side,field)
	if destination.x<70 or destination.x>820:
		destination=Geometry.chopping_position(ground,index,-direction,side,field)
	return Vector2(destination.x,destination.y*FIELD_DEPTH)

func walking_destination(s: Dictionary,point: Vector2,destination: Vector2) -> Vector2:
	if bool(s.get("detour",false)):
		var waypoint:=Vector2(float(s.waypoint_x),float(s.waypoint_y))
		if point.distance_to(waypoint)>4: return waypoint
		s.detour=false
	var travel:=destination-point
	if travel.length_squared()<1: return destination
	var nearest: float=INF
	var blocker:=Vector2.ZERO
	for index in s.trees.size():
		if index==int(s.target) or s.trees[index].phase!="standing": continue
		var tree: Dictionary=s.trees[index]
		var trunk:=Vector2(float(tree.x),float(tree.y)*FIELD_DEPTH)
		var along: float=(trunk-point).dot(travel)/travel.length_squared()
		if along<=0 or along>=1: continue
		if trunk.distance_to(point+travel*along)<42 and along<nearest:
			nearest=along
			blocker=trunk
	if nearest<INF:
		var normal:=Vector2(-travel.y,travel.x).normalized()*74
		var first:=blocker+normal
		var second:=blocker-normal
		var bounds:=Rect2(80,.28*FIELD_DEPTH,740,.67*FIELD_DEPTH)
		var waypoint:=first if bounds.has_point(first) else second
		if bounds.has_point(second) and point.distance_to(second)+second.distance_to(destination)<point.distance_to(waypoint)+waypoint.distance_to(destination): waypoint=second
		s.detour=true
		s.waypoint_x=waypoint.x
		s.waypoint_y=waypoint.y
		return waypoint
	return destination

func axe_level() -> int:
	return 1+int(sqrt(float(axe_xp)/20.0))

func level_progress() -> float:
	var level := axe_level()
	return float(axe_xp-20*(level-1)*(level-1))/float(20*(level*level-(level-1)*(level-1)))

func swing_seconds(id: String) -> float:
	return float(rules(id).get("swing_seconds",1))/(1.0+float(upgrades.handle)*.12)

func accuracy(id: String) -> float:
	return minf(100,float(rules(id).get("accuracy",95))+float(upgrades.grip)*2+float(axe_level()-1)*.25)

func minimum_yield(id: String) -> int:
	return mini(maximum_yield(id),int(rules(id).get("minimum",1))+int(upgrades.sharpening))

func maximum_yield(id: String) -> int:
	return int(rules(id).get("maximum",2))+int(upgrades.head)

func upgrade_cost(kind: String) -> Dictionary:
	if kind not in KINDS or int(upgrades[kind])>=8: return {}
	var level := int(upgrades[kind])+1
	var material: String={"handle":"scrapwood","head":"softwood","grip":"scrapwood","sharpening":"hardwood","gem":"wooden-parts"}[kind]
	if level>=5 and kind in ["head","sharpening"]: material="ironwood"
	return {"id":material,"amount":level*level*(4 if kind=="gem" else 15)}

func upgrade_available(kind: String) -> bool:
	return kind in KINDS and int(upgrades[kind])<8 and (kind!="sharpening" or int(upgrades.sharpening)<=int(upgrades.head))

func buy_upgrade(kind: String) -> bool:
	if not host._activity_unlock_runtime()._is_action_unlocked("woodcutting",host._action_data("woodcutting",IDS[0])): return false
	if not upgrade_available(kind): return false
	var cost := upgrade_cost(kind)
	if cost.is_empty() or host.material_runtime.amount(str(cost.id))<float(cost.amount): return false
	host.material_runtime.spend_amount(str(cost.id),float(cost.amount))
	upgrades[kind]=int(upgrades[kind])+1
	host._mark_save_dirty("axe component")
	return true

func advance(delta: float) -> void:
	var dt := clampf(delta,0,.1)
	for burst in harvest_bursts: burst.age=float(burst.age)+dt
	harvest_bursts=harvest_bursts.filter(func(burst: Dictionary): return float(burst.age)<1.2+float(burst.amount)*.025)
	var current_id: String=host.running_action_id if applies(host.running_skill_id,host.running_action_id) else ""
	if current_id!=active_grove_id:
		active_grove_id=current_id
		if not current_id.is_empty():
			var entry:=state(current_id)
			entry.x=450.0
			entry.y=.91
			entry.detour=false
			entry.direction=-1.0
			# Keep an already felled, unpaid tree intact across stop/start.
			if entry.trees[int(entry.target)].phase!="falling":
				entry.phase="walking"
				entry.age=0.0
				entry.contact=false
			worker_presence[current_id]={"alpha":0.0,"entering":true}
	for id in worker_presence:
		var presence: Dictionary=worker_presence[id]
		presence.alpha=move_toward(float(presence.alpha),1.0 if id==current_id else 0.0,dt/(.45 if id==current_id else .35))
		if id==current_id and float(presence.alpha)>=1.0: presence.entering=false
	for id in groves:
		var s: Dictionary = groves[id]
		s.reward_age=float(s.reward_age)+dt
		s.miss_age=float(s.miss_age)+dt
		for index in s.trees.size():
			var tree: Dictionary=s.trees[index]
			tree.hit=maxf(0,float(tree.hit)-dt)
			tree.spawn_age=minf(1,float(tree.get("spawn_age",1))+dt)
			if tree.phase=="stump":
				tree.age=float(tree.age)+dt
				if float(tree.age)>=regrowth_seconds(id):
					s.trees[index]=new_tree(id,s.trees,0.0,index)
					host._mark_save_dirty("grove tree respawn")
	if not applies(host.running_skill_id,host.running_action_id): return
	var id: String=host.running_action_id
	var s := state(id)
	if worker_entering(id): return
	var target := int(s.target)
	var tree: Dictionary=s.trees[target]
	# Also correct an already-running chop restored from an older save, or a
	# stance whose screen projection changed with the live arena dimensions.
	if s.phase in ["chopping","falling"]:
		var stance:=chopping_destination(id,tree,float(s.x))
		s.x=stance.x
		s.y=stance.y/FIELD_DEPTH
	if s.phase=="walking":
		if tree.phase!="standing":
			var found := false
			for offset in range(1,s.trees.size()+1):
				var candidate: int = (target+offset)%s.trees.size()
				if s.trees[candidate].phase=="standing":
					s.target=candidate
					found=true
					break
			if not found: return
			target=int(s.target)
			tree=s.trees[target]
		var trunk: float=tree.x
		var destination:=chopping_destination(id,tree,float(s.x))
		var point:=Vector2(float(s.x),float(s.y)*FIELD_DEPTH)
		var waypoint:=walking_destination(s,point,destination)
		var movement:=waypoint-point
		if absf(movement.x)>.5: s.direction=1.0 if movement.x>0 else -1.0
		point=point.move_toward(waypoint,115*dt)
		s.x=point.x
		s.y=point.y/FIELD_DEPTH
		s.age=float(s.age)+dt
		if point.distance_to(destination)<.1:
			s.direction=1.0 if trunk>float(s.x) else -1.0
			s.phase="chopping"
			s.age=0.0
			s.contact=false
	elif s.phase=="chopping":
		s.age=float(s.age)+dt
		var interval := swing_seconds(id)
		if float(s.age)>=interval*.54 and not bool(s.contact):
			s.contact=true
			s.swings=int(s.swings)+1
			if rng.randf()*100<=accuracy(source_id(id,tree)):
				tree.hp=maxi(0,int(tree.hp)-1)
				tree.hit=.22
				host._audio_director()._play_grove_hit_sfx(id)
				if int(tree.hp)==0:
					s.phase="falling"
					s.age=0.0
					tree.phase="falling"
					tree.age=0.0
					tree.fall_direction=s.direction
				host._mark_save_dirty("tree damage")
			else: s.miss_age=0.0
		if s.phase=="chopping" and float(s.age)>=interval:
			s.age=0.0
			s.contact=false
	elif s.phase=="falling":
		s.age=minf(1.1,float(s.age)+dt)
		tree.age=s.age
		if float(s.age)>=1.1: harvest(id)
	host.action_progress=1.0-float(tree.hp)/float(tree_health(id,tree))

func worker_opacity(id: String) -> float:
	return float(worker_presence.get(id,{}).get("alpha",0.0))

func worker_entering(id: String) -> bool:
	return bool(worker_presence.get(id,{}).get("entering",false))

func harvest(id: String) -> bool:
	var s := state(id)
	var tree: Dictionary=s.trees[int(s.target)]
	if tree.phase!="falling": return false
	var action: Dictionary=host._action_data("woodcutting",id)
	var cost: float=host._action_runtime()._effective_stamina("woodcutting",action)
	if SkillState.host_stamina_value("woodcutting",host)<cost: host._action_runtime()._auto_eat_fish_for_action("woodcutting",cost,null,false)
	if not SkillState.spend_action_stamina(host.stamina,host.stamina_bank,"woodcutting",cost,Callable(SkillState,"host_max_stamina").bind(host)): return false
	# Transition before grants makes repeated harvest calls harmless.
	tree.phase="stump"
	tree.age=0.0
	var count := roll_tree_yield(id,tree)
	var material:=tree_material(id,tree)
	host.material_runtime.set_amount(material,host.material_runtime.amount(material)+count)
	var rewards:=tree_xp_rewards(id,tree)
	for skill in rewards:
		host.skills[skill].xp=int(host.skills[skill].xp)+int(rewards[skill])
		SkillState.recalculate_level(host,str(skill))
	axe_xp+=ceili(int(rules(source_id(id,tree)).get("axe_xp",4))*(1.0 if bool(tree.get("bountiful",false)) else tree_multiplier(id,tree)))
	felled+=1
	host._hub_runtime().record_mission_action_completion("woodcutting",id)
	host._onboarding_runtime()._record_activity_completion_for_tips("woodcutting",id)
	s.reward_age=0.0
	s.reward_count=count
	s.reward_material=material
	s.last_index=int(s.target)
	s.reward_x=tree.x
	s.reward_y=tree.y
	harvest_bursts.append({"id":id,"x":float(tree.x),"y":float(tree.y),"amount":count,"material":material,"age":0.0})
	host._audio_director()._play_grove_collect_sfx(id)
	s.target=(int(s.target)+1)%s.trees.size()
	s.detour=false
	s.phase="walking"
	s.age=0.0
	host._mark_save_dirty("grove harvest")
	host._update_ui(0,false)
	return true

func reset() -> void:
	axe_xp=0
	felled=0
	upgrades={"handle":0,"head":0,"grip":0,"sharpening":0,"gem":0}
	arena_upgrades.clear()
	groves.clear()
	field_sizes.clear()
	worker_presence.clear()
	active_grove_id=""
	harvest_bursts.clear()

func for_save() -> Dictionary:
	return {"version":5,"axe_xp":axe_xp,"felled":felled,"upgrades":upgrades.duplicate(),"arena_upgrades":arena_upgrades.duplicate(true),"groves":groves.duplicate(true)}

func restore(raw) -> void:
	reset()
	if not raw is Dictionary: return
	axe_xp=integer(raw.get("axe_xp",0),0,1000000000)
	felled=integer(raw.get("felled",0),0,1000000000)
	var levels=raw.get("upgrades",{})
	if levels is Dictionary:
		for kind in KINDS: upgrades[kind]=integer(levels.get(kind,0),0,8)
	var arenas=raw.get("arena_upgrades",{})
	if arenas is Dictionary:
		for id in IDS:
			if not arenas.get(id) is Dictionary: continue
			for kind in ARENA_KINDS: arena_levels(id)[kind]=integer(arenas[id].get(kind,0),0,int(rules(id).get(kind+"_limit",3 if kind=="capacity" else 5)))
	var saved=raw.get("groves",{})
	if not saved is Dictionary: return
	for id in IDS:
		if not saved.get(id) is Dictionary: continue
		var entry: Dictionary=saved[id]
		var s := state(id)
		s.x=number(entry.get("x",390),70,820)
		s.y=number(entry.get("y",.78),.25,.94)
		s.target=integer(entry.get("target",0),0,s.trees.size()-1)
		s.direction=1.0 if number(entry.get("direction",1),-1,1)>=0 else -1.0
		var trees=entry.get("trees",[])
		if trees is Array:
			var old_target:=integer(entry.get("target",0),0,maxi(0,trees.size()-1))
			if old_target>=s.trees.size() and trees[old_target] is Dictionary and trees[old_target].get("phase","")=="falling":
				# A lower new base capacity must not discard an already felled tree.
				trees=trees.duplicate(true)
				trees[0]=trees[old_target]
				s.target=0
			for index in mini(s.trees.size(),trees.size()):
				if not trees[index] is Dictionary: continue
				var t: Dictionary=trees[index]
				s.trees[index].source_id=source_id(id,t)
				s.trees[index].bountiful=bool(t.get("bountiful",false)) and bool(t.get("rare",false)) and str(s.trees[index].source_id)==id
				s.trees[index].gold_leaves=bountiful_level(t) if bool(s.trees[index].bountiful) else 0
				s.trees[index].rare=bool(t.get("rare",false)) and (bool(s.trees[index].bountiful) or str(s.trees[index].source_id)==str(rules(id).get("rare_tree",id)))
				if int(raw.get("version",1))>=2:
					s.trees[index].x=number(t.get("x",s.trees[index].x),110,790)
					s.trees[index].y=number(t.get("y",s.trees[index].y),.32,.91)
				s.trees[index].hp=integer(t.get("hp",tree_health(id,s.trees[index])),0,tree_health(id,s.trees[index]))
				s.trees[index].phase=str(t.get("phase","standing")) if str(t.get("phase","standing")) in ["standing","stump","falling"] else "standing"
				s.trees[index].age=number(t.get("age",0),0,float(rules(id).respawn_seconds))
				s.trees[index].fall_direction=1.0 if number(t.get("fall_direction",1),-1,1)>=0 else -1.0
		# Only a target already felled resumes falling; no grants during restore.
		if s.trees[int(s.target)].phase=="falling":
			s.phase="falling"
			s.age=minf(1.1,float(s.trees[int(s.target)].age))

static func number(value, low: float, high: float) -> float:
	return clampf(float(value),low,high) if (value is int or value is float) and is_finite(float(value)) else low

static func integer(value,low: int,high: int) -> int:
	return int(number(value,low,high))
