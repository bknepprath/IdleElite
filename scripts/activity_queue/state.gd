class_name ActivityQueueState

const ModuleUiKeys = preload("res://scripts/module_ui/keys.gd")


static func normalized_queue(value: Variant) -> Array:
	var queue: Array = []
	if typeof(value) != TYPE_ARRAY:
		return queue
	var seen := {}
	for raw_key in value:
		var key := ModuleUiKeys.normalize(raw_key)
		if key.is_empty() or seen.has(key):
			continue
		seen[key] = true
		queue.append(key)
	return queue


static func next_index(current_index: int, queue_size: int) -> int:
	if queue_size <= 0:
		return -1
	return (current_index + 1) % queue_size
