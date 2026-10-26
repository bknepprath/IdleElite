extends RefCounted

const SkillState = preload("res://scripts/progression/skill_state.gd")
const ACTION_ID := "clear-rockslide"
const UPGRADE_KINDS := ["power", "speed", "volley"]
const SHOT_ORIGIN := Vector2(248, 160)
const STEP := 1.0 / 60.0

var host
var upgrades := {"power":0, "speed":0, "volley":0}
var lifetime_clears := 0
var best_wave := 1
var clears := 0
var integrity := 3
var rocks: Dictionary = {}
var groups: Dictionary = {}
var shots: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var shot_clock := 0.0
var spawn_clock := 0.0
var accumulator := 0.0
var next_id := 1
var was_active := false
var release_seconds := 0.0
var shots_fired := 0
var impacts := 0
var splits := 0
var session_failed := false
var knockout_remaining := 0.0
var wave_seconds := 0.0
var purchase_seconds := {"power":0.0,"speed":0.0,"volley":0.0}
var encounter_index := 0

func _init(owner) -> void:
	host = owner

func applies(skill_id: String, action_id: String) -> bool:
	return skill_id == "fight" and action_id == ACTION_ID

func active() -> bool:
	return applies(host.running_skill_id, host.running_action_id)

func rules() -> Dictionary:
	return host._action_data("fight",ACTION_ID).get("rockslide",{})

func wave() -> int:
	return 1 + clears / 4

func knockout_seconds() -> float:
	return maxf(1.0,float(rules().get("knockout_seconds",5.0)))

func knocked_out() -> bool:
	return knockout_remaining>0.0

func shot_interval() -> float:
	return shot_interval_at_level(int(upgrades.speed))

func shot_interval_at_level(level: int) -> float:
	return float(rules().get("shot_seconds",1.4))/(1.0+float(level)*float(rules().get("speed_gain_per_level",.12)))

func release_duration() -> float:
	return minf(.4,shot_interval()*.4)

func shot_damage() -> int:
	return 1 + int(upgrades.power)

func volley_size() -> int:
	return 1 + int(upgrades.volley)

func upgrade_cost(kind: String) -> Dictionary:
	if kind not in UPGRADE_KINDS: return {}
	var level := int(upgrades[kind])
	if level >= int(rules().get("upgrade_limit",6)): return {}
	var costs: Array=rules().get("upgrade_costs",{}).get(kind,[])
	if level>=costs.size(): return {}
	return (costs[level] as Dictionary).duplicate()

func type_rules(kind: String) -> Dictionary:
	return rules().get("rock_types",{}).get(kind,{})

func effective_damage(rock: Dictionary,damage: int) -> int:
	return maxi(1,damage-int(type_rules(str(rock.get("kind","boulder"))).get("armor",0)))

func encounter() -> Array:
	var patterns: Array=rules().get("wave_patterns",[])
	var selected: Array=[["boulder"]]
	for pattern in patterns:
		if wave()>=int(pattern.from_wave): selected=pattern.encounters
	return selected[encounter_index%selected.size()]

func spawn_encounter() -> void:
	var kinds:=encounter()
	for index in kinds.size():
		if groups.size()>=12 or rocks.size()>=26: break
		var group_id:=next_id
		groups[group_id]={"remaining":1,"failed":false}
		var x:=760.0 if encounter_index==0 and index==0 else 810.0+float(index)*130.0
		spawn_rock(group_id,x,false,0.0,str(kinds[index]))
	encounter_index+=1

func buy_upgrade(kind: String) -> bool:
	if not host._activity_unlock_runtime()._is_action_unlocked("fight", host._action_data("fight", ACTION_ID)): return false
	var cost := upgrade_cost(kind)
	if cost.is_empty() or host.material_runtime.amount(str(cost.id)) < float(cost.amount): return false
	host.material_runtime.spend_amount(str(cost.id), float(cost.amount))
	upgrades[kind] = int(upgrades[kind]) + 1
	purchase_seconds[kind] = .75
	host._mark_save_dirty("slingshot upgrade")
	return true

func ground_y(x: float) -> float:
	return 338.0 - maxf(0.0, x - 135.0) * (202.0 / 765.0)

func rock_position(rock: Dictionary) -> Vector2:
	return Vector2(float(rock.x), ground_y(float(rock.x)) - float(rock.radius) + float(rock.lift))

func clear_transient() -> void:
	rocks.clear()
	groups.clear()
	shots.clear()
	effects.clear()
	shot_clock = shot_interval()
	spawn_clock = .1
	accumulator = 0.0
	release_seconds = 0.0
	wave_seconds = 0.0
	encounter_index = 0

func reset() -> void:
	upgrades = {"power":0,"speed":0,"volley":0}
	purchase_seconds = {"power":0.0,"speed":0.0,"volley":0.0}
	lifetime_clears = 0
	best_wave = 1
	clears = 0
	integrity = 3
	was_active = false
	session_failed = false
	knockout_remaining = 0.0
	clear_transient()

func for_save() -> Dictionary:
	# Unfinished rocks have paid no stamina and awarded nothing.
	return {"version":2,"upgrades":upgrades.duplicate(),"clears":clears,"lifetime_clears":lifetime_clears,"best_wave":best_wave,"integrity":integrity,"knockout_remaining":knockout_remaining}

func restore(raw) -> void:
	reset()
	if not raw is Dictionary: return
	var saved: Dictionary = raw
	var levels = saved.get("upgrades",{})
	if levels is Dictionary:
		for kind in UPGRADE_KINDS: upgrades[kind] = bounded_integer(levels.get(kind,0),0,6)
	lifetime_clears = bounded_integer(saved.get("lifetime_clears",0),0,1000000000)
	clears = bounded_integer(saved.get("clears",0),0,lifetime_clears)
	best_wave = bounded_integer(saved.get("best_wave",1),1,250000001)
	var remaining = saved.get("knockout_remaining",0.0)
	if (remaining is int or remaining is float) and is_finite(float(remaining)):
		knockout_remaining=clampf(float(remaining),0.0,knockout_seconds())
	session_failed=knocked_out()
	integrity = 0 if knocked_out() else bounded_integer(saved.get("integrity",3),1,3)

static func bounded_integer(value, minimum: int, maximum: int) -> int:
	if not (value is int or value is float) or not is_finite(float(value)): return minimum
	return clampi(int(value),minimum,maximum)

func advance(delta: float) -> void:
	for kind in UPGRADE_KINDS: purchase_seconds[kind] = maxf(0,float(purchase_seconds[kind])-delta)
	if not active():
		if was_active:
			clear_transient()
			clears = 0
			integrity = 3
			knockout_remaining = 0.0
			session_failed = false
		was_active = false
		return
	if not was_active:
		clear_transient()
		was_active = true
		session_failed = knocked_out()
	accumulator += clampf(delta,0.0,.25)
	while accumulator >= STEP and active():
		accumulator -= STEP
		step(STEP)

func spawn_rock(group_id: int, x: float, small: bool, lift := 0.0,kind := "boulder") -> int:
	var id := next_id
	next_id += 1
	var definition:=type_rules(kind)
	var health:=1+(wave()-1)/4 if small else int(definition.get("health",rules().get("base_health",5)))+floori(float(wave()-1)*float(definition.get("health_per_wave",1.1)))
	rocks[id] = {"id":id,"group":group_id,"kind":"fragment" if small else kind,"parent_kind":kind,"x":x,"small":small,"hp":health,"max_hp":health,"radius":30.0 if small else float(definition.get("radius",66)),"lift":lift,"vy":-90.0 if small else 0.0,"vx":0.0,"rotation":0.0,"hit":0.0,"age":0.0}
	return id

func step(delta: float) -> void:
	if knocked_out():
		knockout_remaining=maxf(0.0,knockout_remaining-delta)
		if not knocked_out():
			clear_transient()
			clears=0
			integrity=3
			session_failed=false
			host._mark_save_dirty("rockslide recovered")
			host._update_ui(0.0,false)
		return
	release_seconds = maxf(0.0,release_seconds-delta)
	wave_seconds = maxf(0.0,wave_seconds-delta)
	for effect in effects: effect.age = float(effect.age)+delta
	effects = effects.filter(func(effect: Dictionary): return float(effect.age)<float(effect.duration))
	for id in rocks.keys():
		if not rocks.has(id): continue
		var rock: Dictionary = rocks[id]
		var definition:=type_rules(str(rock.get("parent_kind",rock.get("kind","boulder"))))
		var speed:=minf(300.0,float(definition.get("speed",44))+float(wave()-1)*float(definition.get("speed_per_wave",5)))
		rock.age = float(rock.age)+delta
		rock.x = float(rock.x)+(-speed+float(rock.vx))*delta
		rock.vx = move_toward(float(rock.vx),0.0,80.0*delta)
		rock.rotation = float(rock.rotation)-speed*delta/float(rock.radius)
		rock.hit = maxf(0.0,float(rock.hit)-delta)
		rock.vy = float(rock.vy)+360.0*delta
		rock.lift = float(rock.lift)+float(rock.vy)*delta
		if float(rock.lift)>0:
			if float(rock.vy)>85: add_effect("land",Vector2(float(rock.x),ground_y(float(rock.x))),0,.35)
			rock.lift = 0.0
			rock.vy = -float(rock.vy)*.25 if bool(rock.small) and float(rock.vy)>65 else 0.0
		if float(rock.x)<230.0: escape_rock(id)
		if knocked_out(): return
	for shot in shots:
		shot.age = float(shot.age)+delta
		if float(shot.age)>=float(shot.duration) and not bool(shot.done):
			shot.done = true
			hit_rock(int(shot.target),int(shot.damage))
	shots = shots.filter(func(shot: Dictionary): return not bool(shot.done))
	for group_id in groups.keys():
		if int(groups[group_id].remaining)==0: finish_group(group_id)
	if not active(): return
	spawn_clock -= delta
	if spawn_clock<=0 and groups.size()<12 and rocks.size()<26:
		spawn_encounter()
		spawn_clock = maxf(.85,float(rules().get("spawn_seconds",3.2))/(1.0+.14*float(wave()-1)))
	shot_clock -= delta
	if shot_clock<=0 and not rocks.is_empty():
		var targets: Array = rocks.values()
		targets.sort_custom(func(a: Dictionary,b: Dictionary): return float(a.x)<float(b.x))
		# Reserve incoming damage so a volley spreads across live targets instead
		# of wasting every pellet on a fragment already due to break.
		var pending := {}
		for shot in shots:
			if rocks.has(int(shot.target)):
				pending[int(shot.target)] = int(pending.get(int(shot.target),0))+effective_damage(rocks[int(shot.target)],int(shot.damage))
		for index in volley_size():
			var target: Dictionary = targets[index % targets.size()]
			for candidate in targets:
				if int(candidate.hp)>int(pending.get(int(candidate.id),0)):
					target = candidate
					break
			pending[int(target.id)] = int(pending.get(int(target.id),0))+effective_damage(target,shot_damage())
			shots.append({"target":int(target.id),"from":SHOT_ORIGIN,"to":rock_position(target),"age":0.0,"duration":maxf(.14,SHOT_ORIGIN.distance_to(rock_position(target))/1500.0)+float(index)*.025,"damage":shot_damage(),"done":false,"arc":float(index-1)*12.0})
			shots_fired += 1
		shot_clock = shot_interval()
		release_seconds = release_duration()
	host.action_progress = 0.0
	if not rocks.is_empty():
		var first: Dictionary = rocks.values()[0]
		host.action_progress = 1.0-float(first.hp)/float(first.max_hp)

func hit_rock(id: int, damage: int) -> void:
	if not rocks.has(id): return
	var rock: Dictionary = rocks[id]
	var position := rock_position(rock)
	impacts += 1
	rock.hp = int(rock.hp)-effective_damage(rock,damage)
	rock.hit = .12
	add_effect("hit",position,damage,.42)
	if int(rock.hp)>0: return
	rocks.erase(id)
	var group: Dictionary = groups[int(rock.group)]
	group.remaining = int(group.remaining)-1
	add_effect("break",position,0,.65)
	if not bool(rock.small):
		var count:=int(type_rules(str(rock.get("kind","boulder"))).get("fragments",2))
		if count>0: splits += 1
		for index in count:
			var direction:=lerpf(-1.0,1.0,float(index)/maxf(1.0,float(count-1)))
			var child := spawn_rock(int(rock.group),float(rock.x)+direction*38.0,true,-18.0,str(rock.get("kind","boulder")))
			rocks[child].vx = direction*100.0
			rocks[child].vy = -135.0 if direction<0 else -95.0
		group.remaining = int(group.remaining)+count

func add_effect(kind: String, position: Vector2, amount: int, duration: float) -> void:
	if effects.size()<100: effects.append({"kind":kind,"position":position,"amount":amount,"age":0.0,"duration":duration})

func escape_rock(id: int) -> void:
	if not rocks.has(id) or knocked_out(): return
	var rock: Dictionary = rocks[id]
	var group: Dictionary = groups[int(rock.group)]
	if not bool(group.failed):
		group.failed = true
		integrity -= 1
		add_effect("escape",Vector2(245,280),0,.7)
	group.remaining = int(group.remaining)-1
	rocks.erase(id)
	if integrity<=0:
		session_failed = true
		knockout_remaining=knockout_seconds()
		clear_transient()
		host.action_progress=0.0
		host._mark_save_dirty("rockslide knocked out")
		host._update_ui(0.0,false)

func finish_group(group_id: int) -> void:
	if knocked_out() or not groups.has(group_id): return
	if bool(groups[group_id].failed):
		groups.erase(group_id)
		return
	var action: Dictionary = host._action_data("fight",ACTION_ID)
	var cost: float = host._action_runtime()._effective_stamina("fight",action)
	if SkillState.host_stamina_value("fight",host)+.0001<cost:
		host._action_runtime()._auto_eat_fish_for_action("fight",cost,null,false)
	if not SkillState.spend_action_stamina(host.stamina,host.stamina_bank,"fight",cost,Callable(SkillState,"host_max_stamina").bind(host)): return
	groups.erase(group_id)
	clears += 1
	if clears%4==0: wave_seconds = 1.0
	lifetime_clears += 1
	best_wave = maxi(best_wave,wave())
	var rewards: Dictionary = host._action_runtime()._effective_xp_reward_map(action,"fight")
	for skill in rewards:
		host.skills[skill].xp = int(host.skills[skill].xp)+int(rewards[skill])
		SkillState.recalculate_level(host,str(skill))
	host._action_runtime()._award_action_mat_rewards(action,1.0,"fight")
	host._hub_runtime().record_mission_action_completion("fight",ACTION_ID)
	host._onboarding_runtime()._record_activity_completion_for_tips("fight",ACTION_ID)
	add_effect("reward",Vector2(475,195),int(rewards.get("fight",18)),1.1)
	host._mark_save_dirty("rockslide cleared")
	host._update_ui(0.0,false)
