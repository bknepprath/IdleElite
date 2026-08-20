extends RefCounted

const AdBonus = preload("res://scripts/monetization/ad_bonus.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const RewardFeedbackSurface = preload("res://scripts/ui/reward_feedback_surface.gd")

const REWARDED_AD_ICON_TEXTURE := "res://assets/content/ui/rewarded-ad-icon.png"
const PLAY_STORE_RATING_URL := "https://play.google.com/store/apps/details?id=com.idleelite.game"
const PLAY_STORE_RATING_ANDROID_URL := "market://details?id=com.idleelite.game"

class ShopAdStackLight:
	extends Control

	var fill := 0.0

	func set_fill(next_fill: float) -> void:
		var clamped := clampf(next_fill, 0.0, 1.0)
		if absf(fill - clamped) < 0.001:
			return
		fill = clamped
		queue_redraw()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		if size.x <= 8.0 or size.y <= 8.0:
			return
		var side := minf(size.x, size.y)
		var outer := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		var glow_alpha := fill * 0.34
		if glow_alpha > 0.0:
			_draw_round_rect(outer.grow(5.0), 20.0, Color(1.0, 0.77, 0.16, glow_alpha))
		_draw_round_rect(outer, 14.0, Color("#171615"))
		var stroke := maxf(7.0, side * 0.14)
		var inner := outer.grow(-stroke)
		var body_color := Color("#cfe5ee").lerp(Color("#ffd84a"), fill)
		_draw_round_rect(inner, 8.0, body_color)
		var top_face := Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.24))
		draw_rect(top_face, Color(1.0, 1.0, 1.0, 0.20 + fill * 0.16))
		var side_face := Rect2(inner.position + Vector2(inner.size.x * 0.76, 0.0), Vector2(inner.size.x * 0.24, inner.size.y))
		draw_rect(side_face, Color(0.0, 0.0, 0.0, 0.09 + fill * 0.08))
		var bottom_face := Rect2(inner.position + Vector2(0.0, inner.size.y * 0.78), Vector2(inner.size.x, inner.size.y * 0.22))
		draw_rect(bottom_face, Color(0.0, 0.0, 0.0, 0.11 + fill * 0.08))
		var shine := Rect2(inner.position + Vector2(inner.size.x * 0.14, inner.size.y * 0.12), Vector2(inner.size.x * 0.42, maxf(8.0, inner.size.y * 0.16)))
		draw_rect(shine, Color(1.0, 1.0, 1.0, 0.32 + fill * 0.18))
		var glint_color := Color(1.0, 1.0, 1.0, 0.32 + fill * 0.28)
		draw_line(
			inner.position + Vector2(inner.size.x * 0.72, inner.size.y * 0.20),
			inner.position + Vector2(inner.size.x * 0.82, inner.size.y * 0.07),
			glint_color,
			4.0,
			true
		)
		draw_line(
			inner.position + Vector2(inner.size.x * 0.78, inner.size.y * 0.26),
			inner.position + Vector2(inner.size.x * 0.89, inner.size.y * 0.15),
			glint_color,
			3.0,
			true
		)

	func _draw_round_rect(rect: Rect2, radius: float, color: Color) -> void:
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return
		var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
		draw_rect(Rect2(rect.position + Vector2(r, 0.0), Vector2(maxf(0.0, rect.size.x - r * 2.0), rect.size.y)), color)
		draw_rect(Rect2(rect.position + Vector2(0.0, r), Vector2(rect.size.x, maxf(0.0, rect.size.y - r * 2.0))), color)
		draw_circle(rect.position + Vector2(r, r), r, color)
		draw_circle(rect.position + Vector2(rect.size.x - r, r), r, color)
		draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, color)
		draw_circle(rect.position + Vector2(r, rect.size.y - r), r, color)

var host
var rate_prompt_dismissed := false
var bonus_label: Label
var shop_ad_stack_meter_panel: Control
var shop_ad_stack_lights := []
var shop_ad_stack_meter_key := ""

func _init(host_ref) -> void:
	host = host_ref

func rate_prompt_dismissed_for_save() -> bool:
	return rate_prompt_dismissed

func restore_rate_prompt_from_save(data: Dictionary) -> void:
	rate_prompt_dismissed = bool(data.get("shop_rate_prompt_dismissed", false))

func render_page() -> void:
	bonus_label = null
	shop_ad_stack_meter_panel = null
	shop_ad_stack_lights.clear()
	shop_ad_stack_meter_key = ""
	host.content_scroll = MobileScrollContainer.new()
	host.content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	host._add_centered_skill_column(host.content_scroll)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = host._skill_content_width()
	var shop_page_height: float = host.skills_page.size.y - host.SKILLS_PAGE_TOP_PAD
	if shop_page_height <= 1.0:
		shop_page_height = host.BASE_CANVAS.y - NavigationShell.BOTTOM_NAV_HEIGHT - host.SKILLS_PAGE_TOP_PAD
	stack.custom_minimum_size.y = shop_page_height
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_BEGIN
	stack.add_theme_constant_override("separation", 12)
	host.content_scroll.add_child(stack)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 170)
	stack.add_child(top_spacer)
	var offer_stage := Control.new()
	offer_stage.custom_minimum_size = Vector2(host._skill_content_width(), 310)
	offer_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(offer_stage)
	var offer: Button = ad_offer_button()
	offer.pressed.connect(Callable(host._ad_bonus_runtime(), "press_shop_ad"))
	offer.size = offer.custom_minimum_size
	offer.position = Vector2((offer_stage.custom_minimum_size.x - offer.size.x) * 0.5, (offer_stage.custom_minimum_size.y - offer.size.y) * 0.5)
	offer_stage.add_child(offer)
	var stack_meter: Control = ad_stack_meter()
	stack_meter.size = stack_meter.custom_minimum_size
	stack_meter.position = Vector2(offer.position.x + offer.size.x + 12.0, (offer_stage.custom_minimum_size.y - stack_meter.size.y) * 0.5)
	offer_stage.add_child(stack_meter)

	bonus_label = host._label("", 52, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	bonus_label.custom_minimum_size = Vector2(630, 41)
	bonus_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus_label.text = host._ad_bonus_runtime().shop_label_text()
	stack.add_child(bonus_label)
	var message_spacer := Control.new()
	message_spacer.custom_minimum_size = Vector2(0, 37)
	stack.add_child(message_spacer)
	var message: Label = host._label("Hi! Thanks for playing my game :)\nThere are no microtransactions here. Just an optional ad to speed things up if you'd like to use it. Thanks!", 48, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	message.custom_minimum_size = Vector2(960, 110)
	message.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_constant_override("line_spacing", -18)
	stack.add_child(message)
	if not rate_prompt_dismissed:
		var review_spacer := Control.new()
		review_spacer.custom_minimum_size = Vector2(0, 0)
		stack.add_child(review_spacer)
		var review_stars := HBoxContainer.new()
		review_stars.alignment = BoxContainer.ALIGNMENT_CENTER
		review_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		review_stars.add_theme_constant_override("separation", 5)
		var star_texture: Texture2D = host.visual_texture_cache._texture(host.PROGRESS_STAR_ICON_TEXTURE)
		for i in range(5):
			var star: TextureRect = host.visual_texture_cache._image_from_texture(star_texture, Vector2(24, 24))
			star.modulate = host.COLOR_MUTED.lightened(0.12)
			review_stars.add_child(star)
		stack.add_child(review_stars)
		var review: Label = host._label("Please rate Idle Elite on the store page to help me continue developing this game!", 48, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		review.custom_minimum_size = Vector2(960, 75)
		review.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		review.add_theme_constant_override("line_spacing", -18)
		stack.add_child(review)
		var rate_button: Button = host._menu_button("Rate on Play Store")
		rate_button.custom_minimum_size = Vector2(420, 71)
		rate_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rate_button.add_theme_font_size_override("font_size", 48)
		rate_button.add_theme_stylebox_override("normal", host._paper_button_style(Color("#48dd6c"), 21))
		rate_button.add_theme_stylebox_override("hover", host._paper_button_style(Color("#5eed7c"), 21))
		rate_button.add_theme_stylebox_override("pressed", host._paper_button_style(Color("#38c45a"), 21, 32, true))
		rate_button.pressed.connect(rate_pressed)
		stack.add_child(rate_button)
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 48)
	stack.add_child(bottom_spacer)

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
	if bonus_label != null:
		host._app_lifecycle_runtime().set_label_text_if_changed(bonus_label, host._ad_bonus_runtime().shop_label_text())
	sync_ad_stack_meter()

func emphasize_bonus_award() -> void:
	if bonus_label == null or not is_instance_valid(bonus_label) or not bonus_label.is_visible_in_tree():
		return
	host._reward_feedback_surface()._flash_bonus_control(bonus_label)
	if shop_ad_stack_meter_panel != null and is_instance_valid(shop_ad_stack_meter_panel) and shop_ad_stack_meter_panel.is_visible_in_tree():
		host._reward_feedback_surface()._flash_bonus_control(shop_ad_stack_meter_panel, 0.06)
	host._reward_feedback_surface()._float_reward(host, bonus_label, "+10% XP", 60, RewardFeedbackSurface.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -22), Vector2(0, -68), 0.0)
	host._reward_feedback_surface()._float_reward(host, bonus_label, "-10% TIME", 60, RewardFeedbackSurface.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -5), Vector2(0, -68), 0.14)

func ad_offer_button() -> Button:
	var button: Button = host._menu_button("")
	button.custom_minimum_size = Vector2(600, 270)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_stylebox_override("normal", host._paper_button_style(host.COLOR_BLUE, 27))
	button.add_theme_stylebox_override("hover", host._paper_button_style(host.COLOR_BLUE, 27))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(host.COLOR_BLUE.darkened(0.10), 27, 36, true))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 21)
	margin.add_theme_constant_override("margin_right", 21)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 13)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(host.visual_texture_cache._image(REWARDED_AD_ICON_TEXTURE, Vector2(170, 170)))
	var copy := VBoxContainer.new()
	copy.custom_minimum_size = Vector2(365, 0)
	copy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var details_text := "+10% XP\n+10% speed\n2 hours\nstackable"
	var details: Label = host._label(details_text, 48, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	details.add_theme_color_override("font_outline_color", host.COLOR_INK)
	details.add_theme_constant_override("outline_size", host.DEFAULT_BUTTON_TEXT_OUTLINE_SIZE)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(details)
	return button

func ad_stack_meter() -> Control:
	var meter := VBoxContainer.new()
	meter.custom_minimum_size = Vector2(56, 168)
	meter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	meter.alignment = BoxContainer.ALIGNMENT_CENTER
	meter.add_theme_constant_override("separation", 9)
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_ad_stack_meter_panel = meter
	var lights := VBoxContainer.new()
	lights.alignment = BoxContainer.ALIGNMENT_CENTER
	lights.add_theme_constant_override("separation", 0)
	lights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.add_child(lights)
	var max_count := AdBonus.stack_max_count(float(AdBonus.AD_BONUS_MAX_SECONDS), float(AdBonus.AD_BONUS_SECONDS))
	for i in range(max_count):
		var light := ShopAdStackLight.new()
		light.custom_minimum_size = Vector2(56, 56)
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light.set_meta("shop_ad_stack_index", max_count - i - 1)
		lights.add_child(light)
		shop_ad_stack_lights.append(light)
	sync_ad_stack_meter(true)
	return meter

func sync_ad_stack_meter(force := false) -> void:
	if shop_ad_stack_lights.is_empty():
		return
	var units := AdBonus.stack_units(host._ad_bonus_runtime().seconds_remaining, float(AdBonus.AD_BONUS_SECONDS), float(AdBonus.AD_BONUS_MAX_SECONDS))
	var max_count := AdBonus.stack_max_count(float(AdBonus.AD_BONUS_MAX_SECONDS), float(AdBonus.AD_BONUS_SECONDS))
	var active_count := AdBonus.stack_active_count(host._ad_bonus_runtime().seconds_remaining, float(AdBonus.AD_BONUS_SECONDS), float(AdBonus.AD_BONUS_MAX_SECONDS))
	var light_buckets := []
	for i in range(shop_ad_stack_lights.size()):
		var fill := clampf(units - float(i), 0.0, 1.0)
		light_buckets.append(int(round(fill * 12.0)))
	var key := "%d/%d:%s" % [active_count, max_count, str(light_buckets)]
	if not force and key == shop_ad_stack_meter_key:
		return
	shop_ad_stack_meter_key = key
	for i in range(shop_ad_stack_lights.size()):
		var light := shop_ad_stack_lights[i] as ShopAdStackLight
		if light == null or not is_instance_valid(light):
			continue
		var stack_index := int(light.get_meta("shop_ad_stack_index", i))
		var bucket_index := clampi(stack_index, 0, light_buckets.size() - 1)
		var fill := float(light_buckets[bucket_index]) / 12.0
		light.set_fill(fill)
