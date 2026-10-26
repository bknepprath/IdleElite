extends RefCounted

const SkillState = preload("res://scripts/progression/skill_state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const ACTION_ID := "practice-slingshot"
var host
var phase := "ready"
var age := 0.0
var distance := 0.0
var flight_seconds := 1.5
var earned_xp := 0
var best_distance := 0.0
var landings := 0
var release_seconds := 0.0
var reward_seconds := 0.0
var clean_release := false
var record_shot := false
var release_feedback_seconds := 0.0
var last_stamina_cost := 0.0
var rng := RandomNumberGenerator.new()

func _init(owner) -> void:
	host = owner
	rng.randomize()

func applies(skill: String,id: String) -> bool:
	return skill=="fight" and id==ACTION_ID

func active() -> bool:
	return applies(host.running_skill_id,host.running_action_id)

func draw_seconds() -> float:
	return float(host._action_data("fight",ACTION_ID).slingshot_range.get("draw_seconds",1.25))

func release_duration() -> float:
	return float(host._action_data("fight",ACTION_ID).slingshot_range.get("release_seconds",.4))

func draw_progress() -> float:
	return clampf(age/maxf(.001,draw_seconds()),0,1) if phase=="ready" else 0.0

func sample_distance(level: int,roll: float) -> float:
	var rules: Dictionary = host._action_data("fight",ACTION_ID).get("slingshot_range",{})
	var progress := clampf(float(level-1)/maxf(1,float(rules.get("max_level",100))-1),0,1)
	var variance := lerpf(float(rules.get("maximum_variance",.7)),float(rules.get("minimum_variance",.08)),progress)
	var maximum := float(rules.get("base_distance",8))+maxi(0,mini(level,int(rules.get("max_level",100)))-1)*float(rules.get("distance_per_level",1.6))
	return snappedf(maximum*lerpf(1.0-variance,1.0,clampf(roll,0,1)),.1)

func advance(delta: float) -> void:
	release_seconds = maxf(0,release_seconds-delta)
	reward_seconds = maxf(0,reward_seconds-delta)
	release_feedback_seconds = maxf(0,release_feedback_seconds-delta)
	if phase=="flying":
		age += minf(delta,.25)
		if age>=flight_seconds: land()
	elif active():
		age += minf(delta,.25)
		if age>=draw_seconds():
			age=draw_seconds()
			launch()
	else:
		age = 0
	if active(): host.action_progress = clampf(age/maxf(.001,flight_seconds),0,1) if phase=="flying" else 0

func launch() -> bool:
	if not active() or phase=="flying": return false
	var action: Dictionary = host._action_data("fight",ACTION_ID)
	var cost: float = host._action_runtime()._effective_stamina("fight",action)
	if not SkillState.spend_action_stamina(host.stamina,host.stamina_bank,"fight",cost,Callable(SkillState,"host_max_stamina").bind(host)):
		host._action_runtime()._auto_eat_fish_for_action("fight",cost,null,false)
		return false
	clean_release=false
	last_stamina_cost=cost
	release_feedback_seconds=.85
	distance = sample_distance(SkillState.host_skill_level(host,"fight"),rng.randf())
	record_shot=distance>best_distance
	var base: int = host._action_runtime()._effective_xp_reward_map(action,"fight").get("fight",2)
	earned_xp = maxi(1,roundi(base+distance*float(action.slingshot_range.get("xp_per_meter",.08))))
	flight_seconds = 1.15+minf(distance,180)/180.0*.75
	age = 0
	phase = "flying"
	release_seconds = release_duration()
	host._mark_save_dirty("slingshot launch")
	return true

func land() -> void:
	if phase!="flying": return
	phase = "ready"
	age = -float(host._action_data("fight",ACTION_ID).slingshot_range.get("landing_pause_seconds",.7))
	landings += 1
	best_distance = maxf(best_distance,distance)
	reward_seconds = 1.2
	host.skills.fight.xp = int(host.skills.fight.xp)+earned_xp
	SkillState.recalculate_level(host,"fight")
	var action: Dictionary = host._action_data("fight",ACTION_ID)
	MasteryState.add_host_xp(host,"fight",ACTION_ID,MasteryState.reward_for_action(host,"fight",ACTION_ID,action))
	host._hub_runtime().record_mission_action_completion("fight",ACTION_ID)
	host._onboarding_runtime()._record_activity_completion_for_tips("fight",ACTION_ID)
	host._mark_save_dirty("slingshot landing")
	host._update_ui(0,false)

func reset() -> void:
	phase="ready"
	age=0
	distance=0
	best_distance=0
	landings=0
	reward_seconds=0
	release_seconds=0
	clean_release=false
	record_shot=false
	release_feedback_seconds=0
	last_stamina_cost=0

func for_save() -> Dictionary:
	return {"version":2,"best_distance":best_distance,"landings":landings,"phase":phase,"age":age,"distance":distance,"flight_seconds":flight_seconds,"earned_xp":earned_xp,"clean_release":clean_release,"record_shot":record_shot}

func restore(raw) -> void:
	reset()
	if not raw is Dictionary: return
	best_distance = number(raw.get("best_distance",0),0,100000)
	landings = int(number(raw.get("landings",0),0,1000000000))
	if raw.get("phase","")=="flying":
		phase="flying"
		clean_release=raw.get("clean_release",false)==true
		record_shot=raw.get("record_shot",false)==true
		distance=number(raw.get("distance",0),0,100000)
		flight_seconds=number(raw.get("flight_seconds",1.5),1,2)
		age=number(raw.get("age",0),0,flight_seconds)
		earned_xp=int(number(raw.get("earned_xp",1),1,100000))

static func number(value,minimum: float,maximum: float) -> float:
	if not (value is float or value is int) or not is_finite(float(value)): return minimum
	return clampf(float(value),minimum,maximum)
