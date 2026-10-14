extends SceneTree
const InputShell = preload("res://scripts/ui/input_routing_shell.gd")
class HitProbe extends InputShell:
	var button: Button
	var card_hit := {}
	var card_queries := 0
	func _page_switch_button_control_at_position(_position: Vector2) -> Button:
		return button
	func _action_card_at_position(_position: Vector2) -> Dictionary:
		card_queries += 1
		return card_hit
func _init() -> void:
	var probe := HitProbe.new(null)
	assert(probe._page_switch_button_at_position(Vector2.ZERO) == null)
	assert(probe.card_queries == 0, "A press outside navigation must not scan activity cards")
	probe.button = Button.new()
	assert(probe._page_switch_button_at_position(Vector2.ZERO) == probe.button)
	probe.card_hit = {"action_id": "overlapping-action"}
	assert(probe._page_switch_button_at_position(Vector2.ZERO) == null, "An overlapping activity must retain input priority")
	assert(probe.card_queries == 2)
	probe.button.free()
	print("navigation-hit-scheduling-ok")
	quit()
