extends CanvasLayer

var host
var plate_texture: Texture2D
var screen: Control
var artwork: TextureRect
var dismiss_button: Button

func setup(owner, texture: Texture2D) -> void:
	host = owner
	plate_texture = texture
	name = "HalloweenGreeting"
	layer = host.BOOT_WARMUP_LAYER - 1

func _ready() -> void:
	screen = Control.new()
	screen.name = "HalloweenGreetingScreen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(shade)
	artwork = TextureRect.new()
	artwork.name = "ApprovedHalloweenArtwork"
	artwork.texture = plate_texture
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(artwork)
	# One native full-screen button consumes the complete tap, including release.
	# The approved Continue artwork remains visible, and all other pixels dismiss too.
	dismiss_button = Button.new()
	dismiss_button.name = "DismissHalloweenGreeting"
	dismiss_button.text = "Continue"
	dismiss_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dismiss_button.mouse_filter = Control.MOUSE_FILTER_STOP
	dismiss_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	dismiss_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		dismiss_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_outline_color", "font_shadow_color"]:
		dismiss_button.add_theme_color_override(color, Color.TRANSPARENT)
	screen.add_child(dismiss_button)
	dismiss_button.focus_next = dismiss_button.get_path()
	dismiss_button.focus_previous = dismiss_button.get_path()
	dismiss_button.pressed.connect(host._halloween_runtime().dismiss_launch_greeting)
	dismiss_button.grab_focus()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var canvas := get_viewport().get_visible_rect().size
	var available := Vector2(minf(1120.0, canvas.x - 32.0), canvas.y - 64.0)
	var source := plate_texture.get_size()
	var fit := minf(available.x / source.x, available.y / source.y)
	artwork.size = source * fit
	artwork.position = (canvas - artwork.size) * .5
