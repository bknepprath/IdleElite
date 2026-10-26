extends Button

const Arc := preload("res://scripts/ui/lock_progress_bar.gd")
# The holders were cut from sheets three columns wide and the left and right
# ones never re-centred. How far the middle of each one's art is to the right of
# the middle of its 256 px canvas, and the same for an icon whose art is off.
const HOLDER_ART_OFFSET_X := {"timber": 13.0, "stone": 0.5, "iron": -12.0, "bronze": 14.0, "silver": 0.0, "gold": -13.5, "titanium": 13.5, "platinum": 0.0, "obsidian": -13.0}
const ICON_ART_OFFSET_X := {"unlock-grit.png": 6.5}
const ART_CANVAS := 256.0
const HOLDER_SIZE := 220.0
const ICON_SIZE := 110.0
var resource := ""
var progress: Control
var resource_icon: TextureRect

func setup(host, row: Dictionary, material_id := "stone") -> void:
	resource = str(row.id)
	# The list's scroll container takes the pointer, so a button inside it never
	# sees a tap of its own. The input shell presses the buttons in this group.
	add_to_group("feedback_help_buttons")
	set_meta("inside_detail_list", true)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for key in ["normal", "hover", "pressed", "focus", "disabled"]: add_theme_stylebox_override(key, StyleBoxEmpty.new())
	var body := TextureRect.new()
	body.texture = load("res://assets/content/ui/unlock-holder-%s.png" % material_id)
	body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Translate the frame so its opening sits behind the icon, preserving its size
	# and the shared icon/bar center.
	var holder_shift := -float(HOLDER_ART_OFFSET_X.get(material_id, 0.0)) * HOLDER_SIZE / ART_CANVAS
	body.offset_left = holder_shift
	body.offset_right = holder_shift
	resource_icon = TextureRect.new()
	resource_icon.texture = host.visual_texture_cache._texture_or_visual_fallback(str(row.icon))
	resource_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	resource_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resource_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resource_icon.position = Vector2(55.0 - float(ICON_ART_OFFSET_X.get(str(row.icon).get_file(), 0.0)) * ICON_SIZE / ART_CANVAS, 48)
	resource_icon.size = Vector2(ICON_SIZE, ICON_SIZE)
	add_child(resource_icon)
	progress = Arc.new()
	progress.setup(host.app_bold_font)
	progress.fill_color = Color("#ffd84a")
	progress.position = Vector2(60, 150)
	progress.size = Vector2(100, 28)
	add_child(progress)
	update_requirement(row)

func update_requirement(row: Dictionary) -> void:
	progress.set_progress(float(row.amount) / maxi(1, int(row.target)))
	tooltip_text = str(row.tooltip)
