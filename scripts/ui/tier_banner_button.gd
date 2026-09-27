extends Button

# Remember movement for the entire press, even after scroll suppression clears.
var tap_pending := false
var tap_cancelled := false
var press_position := Vector2.ZERO


func _ready() -> void:
	button_down.connect(_begin_tap)
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			(ancestor as ScrollContainer).get_v_scroll_bar().value_changed.connect(_cancel_on_scroll)
			break
		ancestor = ancestor.get_parent()


func _begin_tap() -> void:
	tap_pending = true
	tap_cancelled = false
	press_position = get_global_mouse_position()


func _input(event: InputEvent) -> void:
	if not tap_pending:
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		if get_global_mouse_position().distance_to(press_position) >= MobileScrollContainer.DRAG_DEADZONE:
			tap_cancelled = true
	elif event is InputEventScreenDrag:
		tap_cancelled = true


func _cancel_on_scroll(_value: float) -> void:
	if tap_pending:
		tap_cancelled = true


func consume_tap() -> bool:
	var accepted := (
		tap_pending
		and not tap_cancelled
		and get_global_mouse_position().distance_to(press_position) < MobileScrollContainer.DRAG_DEADZONE
	)
	tap_pending = false
	return accepted
