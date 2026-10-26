extends RefCounted

const AdBonus = preload("res://scripts/monetization/ad_bonus.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")

const REWARDED_AD_ICON_TEXTURE := "res://assets/content/ui/rewarded-ad-icon.png"
const AD_BONUS_BACKDROP_TEXTURE := "res://assets/content/ui/ad-bonus-backdrop-blue-book.png"
const AD_BONUS_HERO_TEXTURE := "res://assets/content/ui/ad-bonus-hero-powered-up.png"
const PRESENTATION_INK := Color("#30291f")
const PRESENTATION_ACCENT := Color("#624824")
const PRESENTATION_MUTED := Color("#796d5e")
const PLAY_STORE_RATING_URL := "https://play.google.com/store/apps/details?id=com.idleelite.game"
const PLAY_STORE_RATING_ANDROID_URL := "market://details?id=com.idleelite.game"

class WatchPlayIcon:
	extends Control

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(72, 72))
		var triangle := PackedVector2Array([Vector2(20, 10), Vector2(61, 36), Vector2(20, 62)])
		draw_colored_polygon(triangle, Color("#fff8df"))
		draw_polyline(PackedVector2Array([triangle[0], triangle[1], triangle[2], triangle[0]]), Color("#171615"), 6.0, true)

class BonusTimeBar:
	extends Control

	var runtime
	var timer_label: Label
	var fill := 0.0
	var last_second := -1
	var track_color := Color("#ddd5c5")
	var rewards_changed: Callable
	var last_percent := -1

	func _process(_delta: float) -> void:
		if runtime == null or not is_visible_in_tree():
			return
		var seconds := clampf(float(runtime.seconds_remaining), 0.0, float(AdBonus.AD_BONUS_MAX_SECONDS))
		var next_fill := seconds / float(AdBonus.AD_BONUS_MAX_SECONDS)
		if fill != next_fill:
			fill = next_fill
			queue_redraw()
		var percent: int = runtime.bonus_percent()
		if percent != last_percent:
			last_percent = percent
			if rewards_changed.is_valid():
				rewards_changed.call()
		var whole_seconds := int(ceil(seconds))
		if whole_seconds != last_second:
			last_second = whole_seconds
			timer_label.text = clock_text(seconds)

	static func clock_text(seconds: float) -> String:
		var whole := int(ceil(maxf(0.0, seconds)))
		if whole >= 3600:
			return "%d:%02d:%02d" % [whole / 3600, (whole % 3600) / 60, whole % 60]
		if whole >= 60:
			return "%d:%02d" % [whole / 60, whole % 60]
		return "%ds" % whole

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var outline := StyleBoxFlat.new()
		outline.bg_color = Color("#171615")
		outline.set_corner_radius_all(28)
		outline.draw(get_canvas_item(), rect)
		var track := StyleBoxFlat.new()
		track.bg_color = track_color
		track.set_corner_radius_all(22)
		track.draw(get_canvas_item(), rect.grow(-6.0))
		var inner := rect.grow(-10.0)
		if fill > 0.0:
			var paint := StyleBoxFlat.new()
			paint.bg_color = Color("#ffd84a")
			paint.set_corner_radius_all(int(minf(18.0, inner.size.x * fill * 0.5)))
			paint.draw(get_canvas_item(), Rect2(inner.position, Vector2(inner.size.x * fill, inner.size.y)))
			var highlight := Rect2(inner.position + Vector2(10, 6), Vector2(maxf(0.0, inner.size.x * fill - 20.0), 9))
			if highlight.size.x > 0.0:
				draw_rect(highlight, Color(1, 1, 1, 0.38))

class BonusThresholdMarks:
	extends Control

	var tick_color := Color("#796d5e")

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		for index in [1, 2]:
			var x := 10.0 + (size.x - 20.0) * float(index) / 3.0
			draw_line(Vector2(x, 0), Vector2(x, 9), tick_color, 2.0, true)

var host
var rate_prompt_dismissed := false
var xp_reward_label: Label
var time_reward_label: Label
var shop_ad_stack_meter_panel: Control
var bonus_timer: Label
var bonus_bar: BonusTimeBar
var bonus_threshold_marks: BonusThresholdMarks
var offer_button: Button
var offer_title: Label
var availability_label: Label
var presentation_root: Control
var presentation_backdrop: TextureRect
var presentation_backdrop_source: Texture2D
var presentation_scroll: MobileScrollContainer
var presentation_page: VBoxContainer
var presentation_hero: TextureRect
var responsive_labels := []
var responsive_icons := []
var responsive_spacers := []
var responsive_rows := []
var rate_button: Button

func _init(host_ref) -> void:
	host = host_ref

func rate_prompt_dismissed_for_save() -> bool:
	return rate_prompt_dismissed

func restore_rate_prompt_from_save(data: Dictionary) -> void:
	rate_prompt_dismissed = bool(data.get("shop_rate_prompt_dismissed", false))

func render_page() -> void:
	bonus_timer = null
	bonus_bar = null
	offer_button = null
	offer_title = null
	availability_label = null
	shop_ad_stack_meter_panel = null
	responsive_labels.clear()
	responsive_icons.clear()
	responsive_spacers.clear()
	responsive_rows.clear()
	rate_button = null
	presentation_root = Control.new()
	presentation_root.name = "AdBonusPresentation"
	presentation_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	presentation_root.clip_contents = true
	presentation_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.skills_content.add_child(presentation_root)
	presentation_backdrop = TextureRect.new()
	presentation_backdrop.name = "AdBonusBackdrop"
	presentation_backdrop_source = host.visual_texture_cache._texture(AD_BONUS_BACKDROP_TEXTURE)
	presentation_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	presentation_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	if host.dark_mode_enabled:
		presentation_backdrop.modulate = Color(0.24, 0.23, 0.22)
	presentation_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation_root.add_child(presentation_backdrop)
	presentation_scroll = MobileScrollContainer.new()
	presentation_scroll.name = "AdBonusContentScroll"
	presentation_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	presentation_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	presentation_root.add_child(presentation_scroll)
	host.content_scroll = presentation_scroll
	presentation_page = VBoxContainer.new()
	presentation_page.name = "AdBonusPage"
	presentation_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	presentation_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	presentation_page.add_theme_constant_override("separation", 0)
	presentation_scroll.add_child(presentation_page)
	presentation_hero = host.visual_texture_cache._image(AD_BONUS_HERO_TEXTURE, Vector2(760, 270))
	presentation_hero.name = "AdBonusHero"
	presentation_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	presentation_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	presentation_hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	presentation_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation_page.add_child(presentation_hero)
	var title := _centered_label("Ad bonus", 72, PRESENTATION_ACCENT)
	title.name = "AdBonusTitle"
	presentation_page.add_child(title)
	_spacer(presentation_page, 12)
	var rewards := HBoxContainer.new()
	rewards.name = "AdBonusRewards"
	rewards.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards.add_theme_constant_override("separation", 64)
	presentation_page.add_child(rewards)
	xp_reward_label = _reward(rewards, "res://assets/content/ui/infochip-symbol-xp-outlined.png", "+10%")
	time_reward_label = _reward(rewards, "res://assets/content/ui/infochip-symbol-time-outlined.png", "-10%")
	_spacer(presentation_page, 24)
	offer_button = ad_offer_button()
	offer_button.pressed.connect(Callable(host._ad_bonus_runtime(), "press_shop_ad"))
	presentation_page.add_child(offer_button)
	_spacer(presentation_page, 48)
	var meter := VBoxContainer.new()
	meter.name = "AdBonusCountdown"
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.add_theme_constant_override("separation", 12)
	presentation_page.add_child(meter)
	shop_ad_stack_meter_panel = meter
	bonus_timer = _centered_label("0s", 60, Color.WHITE)
	bonus_timer.name = "AdBonusTimer"
	bonus_timer.add_theme_color_override("font_outline_color", Color.BLACK)
	bonus_timer.add_theme_constant_override("outline_size", host.DEFAULT_BUTTON_TEXT_OUTLINE_SIZE)
	meter.add_child(bonus_timer)
	bonus_bar = BonusTimeBar.new()
	bonus_bar.name = "AdBonusTimeBar"
	bonus_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bonus_bar.runtime = host._ad_bonus_runtime()
	bonus_bar.timer_label = bonus_timer
	bonus_bar.track_color = Color("#4d4032") if host.dark_mode_enabled else Color("#ded2bd")
	bonus_bar.rewards_changed = _sync_bonus_rewards
	meter.add_child(bonus_bar)
	bonus_threshold_marks = BonusThresholdMarks.new()
	bonus_threshold_marks.name = "AdBonusThresholdMarks"
	bonus_threshold_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bonus_threshold_marks.tick_color = Color("#d6c4a2") if host.dark_mode_enabled else PRESENTATION_MUTED
	meter.add_child(bonus_threshold_marks)
	for index in [1, 2]:
		var mark := _presentation_label("%d%%" % (10 + index * 2), 36, PRESENTATION_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		mark.name = "AdBonusThreshold%d" % (10 + index * 2)
		bonus_threshold_marks.add_child(mark)
		mark.anchor_left = float(index) / 3.0
		mark.anchor_right = mark.anchor_left
		mark.offset_left = 10.0 - 20.0 * float(index) / 3.0
		mark.offset_right = mark.offset_left
		mark.offset_top = 12
		mark.grow_horizontal = Control.GROW_DIRECTION_BOTH
	availability_label = _centered_label("", 52, PRESENTATION_MUTED)
	availability_label.name = "AdBonusAvailability"
	presentation_page.add_child(availability_label)
	var flexible_space := Control.new()
	flexible_space.custom_minimum_size.y = 40
	flexible_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	presentation_page.add_child(flexible_space)
	var footer := VBoxContainer.new()
	footer.name = "AdBonusDeveloperNote"
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_theme_constant_override("separation", 14)
	presentation_page.add_child(footer)
	footer.add_child(_centered_label("From the developer", 60, PRESENTATION_ACCENT))
	var message := _centered_label("Thanks for playing!\nOptional ads support development.\nNo microtransactions.", 40, PRESENTATION_MUTED)
	message.name = "AdBonusDeveloperMessage"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(message)
	if not rate_prompt_dismissed:
		rate_button = host._menu_button("Rate Idle Elite")
		rate_button.name = "AdBonusRateButton"
		rate_button.custom_minimum_size = Vector2(480, 90)
		rate_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rate_button.add_theme_font_size_override("font_size", 52)
		responsive_labels.append({"node":rate_button,"font_size":52})
		rate_button.add_theme_stylebox_override("normal", host._paper_button_style(Color("#48dd6c"), 21))
		rate_button.add_theme_stylebox_override("hover", host._paper_button_style(Color("#5eed7c"), 21))
		rate_button.add_theme_stylebox_override("pressed", host._paper_button_style(Color("#38c45a"), 21, 32, true))
		rate_button.pressed.connect(rate_pressed)
		footer.add_child(rate_button)
	presentation_root.resized.connect(_layout_presentation)
	_layout_presentation()
	host.call_deferred("_update_ui", 0.0, false)
	sync_bonus_display()

func _layout_presentation() -> void:
	if presentation_root == null or not is_instance_valid(presentation_root) or not is_instance_valid(offer_button):
		return
	var bounds := presentation_root.size
	var landscape := bounds.x > bounds.y * 1.25
	# A wide browser must not magnify a portrait page to its entire width.
	# Fit the authored column to the available height and keep it centered.
	var unit := clampf(bounds.y / 1500.0, 0.55, 1.15) if landscape else maxf(1.0, bounds.x / 1080.0)
	presentation_backdrop.size = bounds
	if presentation_backdrop_source != null and bounds.x > 0.0 and bounds.y > 0.0:
		# Keep the selected book at the bottom visible when a short phone needs
		# vertical cropping. The foreground hero has its own uncropped draw box.
		var source_size := presentation_backdrop_source.get_size()
		var cover_scale := maxf(bounds.x / source_size.x, bounds.y / source_size.y)
		var source_crop := bounds / cover_scale
		var background := AtlasTexture.new()
		background.atlas = presentation_backdrop_source
		background.region = Rect2(Vector2((source_size.x - source_crop.x) * 0.5, source_size.y - source_crop.y), source_crop)
		presentation_backdrop.texture = background
	if landscape:
		var column_width := minf(880.0 * unit, bounds.x - 80.0 * unit)
		presentation_scroll.position = Vector2((bounds.x - column_width) * 0.5, 24.0 * unit)
		presentation_scroll.size = Vector2(column_width, maxf(1.0, bounds.y - 48.0 * unit))
	else:
		presentation_scroll.position = Vector2(100, 90) * unit
		presentation_scroll.size = (bounds - Vector2(200, 190) * unit).max(Vector2.ONE)
	var content_width := presentation_scroll.size.x
	presentation_page.custom_minimum_size = presentation_scroll.size
	presentation_hero.custom_minimum_size = Vector2(0, clampf(presentation_scroll.size.y * 0.215, 250.0 * unit, 380.0 * unit))
	offer_button.custom_minimum_size = Vector2(content_width, 150 * unit)
	bonus_bar.custom_minimum_size = Vector2(content_width, 48 * unit)
	bonus_threshold_marks.custom_minimum_size.y = 64 * unit
	availability_label.custom_minimum_size.y = 68 * unit
	bonus_timer.add_theme_constant_override("outline_size", int(round(float(host.DEFAULT_BUTTON_TEXT_OUTLINE_SIZE) * unit)))
	for entry in responsive_labels:
		if is_instance_valid(entry.node):
			entry.node.add_theme_font_size_override("font_size", int(round(float(entry.font_size) * unit)))
	for entry in responsive_icons:
		if is_instance_valid(entry.node):
			entry.node.custom_minimum_size = entry.draw_size * unit
	for row in responsive_rows:
		row.custom_minimum_size.y = 112.0 * unit
		row.add_theme_constant_override("separation", int(round(12.0 * unit)))
	presentation_page.get_node("AdBonusRewards").add_theme_constant_override("separation", int(round(64.0 * unit)))
	if is_instance_valid(rate_button):
		rate_button.custom_minimum_size = Vector2(480, 90) * unit
	var spacing := unit * clampf(presentation_scroll.size.y / (1576.0 * unit), 0.65, 1.15)
	for entry in responsive_spacers:
		if is_instance_valid(entry.node):
			entry.node.custom_minimum_size.y = float(entry.height) * spacing

func _spacer(parent: Control, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	parent.add_child(spacer)
	responsive_spacers.append({"node":spacer,"height":height})

func _presentation_label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label: Label = host._label(text, font_size, color, align)
	var text_color := color
	if host.dark_mode_enabled:
		if color == PRESENTATION_INK:
			text_color = Color("#fff2d7")
		elif color == PRESENTATION_ACCENT:
			text_color = Color("#ffdc77")
		elif color == PRESENTATION_MUTED:
			text_color = Color("#d6c4a2")
	label.add_theme_color_override("font_color", text_color)
	responsive_labels.append({"node":label,"font_size":font_size})
	return label

func _centered_label(text: String, font_size: int, color: Color) -> Label:
	var label := _presentation_label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _reward(parent: Control, icon_path: String, text: String) -> Label:
	var row := HBoxContainer.new()
	responsive_rows.append(row)
	row.custom_minimum_size.y = 112
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var icon: TextureRect = host.visual_texture_cache._image(icon_path, Vector2(88, 88))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	responsive_icons.append({"node":icon,"draw_size":Vector2(88, 88)})
	row.add_child(icon)
	var label := _presentation_label(text, 68, PRESENTATION_INK, HORIZONTAL_ALIGNMENT_LEFT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	parent.add_child(row)
	return label

func _sync_bonus_rewards() -> void:
	var percent := maxi(10, int(host._ad_bonus_runtime().bonus_percent()))
	xp_reward_label.text = "+%d%%" % percent
	time_reward_label.text = "-%d%%" % percent

func rate_pressed() -> void:
	var url: String = PLAY_STORE_RATING_ANDROID_URL if OS.get_name() == "Android" else PLAY_STORE_RATING_URL
	var err: Error = OS.shell_open(url)
	var opened := err == OK
	if not opened and url != PLAY_STORE_RATING_URL:
		opened = OS.shell_open(PLAY_STORE_RATING_URL) == OK
	if opened:
		rate_prompt_dismissed = true
		host._reward_feedback_surface()._set_result("Opening Play Store.")
		host.save_game()
		if host.current_screen == "shop":
			host._navigation_shell()._render_screen()
	else:
		host._reward_feedback_surface()._set_result("Couldn't open Play Store.")

func sync_bonus_display() -> void:
	if bonus_timer == null or not is_instance_valid(bonus_timer):
		return
	var runtime = host._ad_bonus_runtime()
	var seconds := maxf(0.0, float(runtime.seconds_remaining))
	var waiting := seconds > float(AdBonus.AD_BONUS_WARN_THRESHOLD_SECONDS) and not AdBonus.is_itch_browser_build()
	var busy := bool(runtime.ad_loading) or bool(runtime.ad_showing)
	offer_button.disabled = waiting or busy
	offer_title.text = "Loading ad…" if busy else ("Bonus stored" if waiting else "Watch ad")
	availability_label.text = "Next ad in %s" % _clock_text(seconds - float(AdBonus.AD_BONUS_WARN_THRESHOLD_SECONDS)) if waiting else ""
	bonus_bar._process(0.0)

func _clock_text(seconds: float) -> String:
	return BonusTimeBar.clock_text(seconds)

func emphasize_bonus_award() -> void:
	if bonus_timer == null or not is_instance_valid(bonus_timer) or not bonus_timer.is_visible_in_tree():
		return
	host._reward_feedback_surface()._flash_bonus_control(shop_ad_stack_meter_panel, 0.06)
	host._reward_feedback_surface()._flash_bonus_control(offer_button, 0.035)

func ad_offer_button() -> Button:
	var button := Button.new()
	button.name = "AdBonusWatchButton"
	button.custom_minimum_size = Vector2(880, 176)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", host._paper_button_style(Color("#ffd84a"), 30))
	button.add_theme_stylebox_override("hover", host._paper_button_style(Color("#ffe477"), 30))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(Color("#edbe32"), 30, 36, true))
	button.add_theme_stylebox_override("disabled", host._paper_button_style(Color("#b9b3a8"), 30, 36, false, true))
	host.button_press_runtime.attach_button_depress_animation(button, 0.95)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)
	var play := WatchPlayIcon.new()
	play.custom_minimum_size = Vector2(72, 72)
	play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	responsive_icons.append({"node":play,"draw_size":Vector2(72,72)})
	row.add_child(play)
	offer_title = _presentation_label("Watch ad", 64, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	offer_title.add_theme_color_override("font_color", Color("#171615"))
	offer_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(offer_title)
	return button
