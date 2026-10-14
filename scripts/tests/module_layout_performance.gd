extends SceneTree
const Runtime = preload("res://scripts/module_ui/runtime.gd")
var calls := 0
func allowed(_key: String) -> bool:
	calls += 1
	return false
func _init() -> void:
	var runtime := Runtime.new()
	assert(not runtime.is_collapsed("fishing_area:shore", allowed))
	assert(not runtime.is_pinned("fishing_area:shore", allowed))
	assert(calls == 0)
	runtime.collapsed["fishing_area:shore"] = true
	runtime.pinned_order.append("fishing_area:shore")
	assert(not runtime.is_collapsed("fishing_area:shore", allowed))
	assert(not runtime.is_pinned("fishing_area:shore", allowed))
	assert(calls == 2)
	var plan: Array = []
	for i in range(40):
		plan.append({"kind": "fishing_area", "area_def": {"id": str(i), "unlock": (i * 7) % 11, "module_index": i}, "height": 200})
	var level := func(entry, _skill): return entry.area_def.unlock
	var requirements := func(_skill, _action): return []
	for mode in [Runtime.SORT_LEVEL, Runtime.SORT_LEVEL_REVERSE]:
		runtime.sort_mode = mode
		var expected := plan.duplicate(true)
		expected.sort_custom(func(a, b): return runtime._detail_entry_sort_less(runtime._lazy_entry_detail_sort_proxy(a), runtime._lazy_entry_detail_sort_proxy(b), "fishing", level, requirements))
		var actual := runtime.sort_fishing_lazy_plan(plan.duplicate(true), "fishing", 28, level, requirements)
		for i in range(actual.size()):
			assert(actual[i].area_def.id == expected[i].area_def.id)
			assert(actual[i].y == i * 228)
	print("module-layout-performance-ok")
	quit()
