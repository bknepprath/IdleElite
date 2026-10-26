extends SceneTree

const OnboardingRuntime = preload("res://scripts/tutorial/onboarding_runtime.gd")

class CompletionHost extends RefCounted:
	const TUTORIAL_STARTER_SKILL_ID := "fight"
	const TUTORIAL_STARTER_ACTION_ID := "push-ups"
	var immediate_saves := 0
	var dirty_completions := 0
	var completed := 0

	func _action_runtime():
		return self

	func record_activity_completion() -> void:
		completed += 1

	func save_game() -> void:
		immediate_saves += 1

	func _mark_save_dirty(_reason: String) -> void:
		dirty_completions += 1

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var host := CompletionHost.new()
	var runtime := OnboardingRuntime.new(host)
	runtime._record_activity_completion_for_tips("fight", "push-ups")
	var checks: Array[bool] = [
		host.immediate_saves == 1,
		host.dirty_completions == 0,
		runtime.onboarding_starter_action_completion_count == 1,
		runtime.onboarding_first_module_center_release_pending,
	]
	runtime.onboarding_tutorial_complete = true
	runtime.onboarding_first_module_center_released = true
	runtime.onboarding_first_module_center_release_pending = false
	for i in range(100):
		runtime._record_activity_completion_for_tips("fight", "push-ups")
	checks.append(host.immediate_saves == 1)
	checks.append(host.dirty_completions == 100)
	checks.append(runtime.onboarding_starter_action_completion_count == 101)
	checks.append(not runtime.onboarding_first_module_center_release_pending)
	runtime._record_activity_completion_for_tips("build", "stack-bricks")
	checks.append(host.immediate_saves == 1)
	checks.append(host.dirty_completions == 101)
	checks.append(host.completed == 102)
	if checks.has(false):
		push_error("Activity completion persistence regression: %s" % [checks])
		quit(1)
		return
	print("activity-completion-save-ok")
	quit(0)
