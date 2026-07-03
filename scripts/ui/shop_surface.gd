class_name ShopSurface
extends RefCounted

const AdBonus = preload("res://scripts/monetization/ad_bonus.gd")
const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")
const ShopAdStackLight = preload("res://scripts/ui/shop_ad_stack_light.gd")

var host
var shop_ad_stack_meter_panel: Control
var shop_ad_stack_lights := []
var shop_ad_stack_meter_key := ""

func _init(host_ref) -> void:
	host = host_ref

func render_page() -> void:
	host.shop_bonus_label = null
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
		shop_page_height = host.BASE_CANVAS.y - host.BOTTOM_NAV_HEIGHT - host.SKILLS_PAGE_TOP_PAD
	stack.custom_minimum_size.y = shop_page_height
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.alignment = BoxContainer.ALIGNMENT_BEGIN
	stack.add_theme_constant_override("separation", 24)
	host.content_scroll.add_child(stack)
	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 340)
	stack.add_child(top_spacer)
	var offer_stage := Control.new()
	offer_stage.custom_minimum_size = Vector2(host._skill_content_width(), 620)
	offer_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(offer_stage)
	var offer: Button = ad_offer_button()
	offer.pressed.connect(Callable(host._ad_bonus_runtime(), "press_shop_ad"))
	offer.size = offer.custom_minimum_size
	offer.position = Vector2((offer_stage.custom_minimum_size.x - offer.size.x) * 0.5, (offer_stage.custom_minimum_size.y - offer.size.y) * 0.5)
	offer_stage.add_child(offer)
	var stack_meter: Control = ad_stack_meter()
	stack_meter.size = stack_meter.custom_minimum_size
	stack_meter.position = Vector2(offer.position.x + offer.size.x + 24.0, (offer_stage.custom_minimum_size.y - stack_meter.size.y) * 0.5)
	offer_stage.add_child(stack_meter)

	host.shop_bonus_label = host._label("", 64, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	host.shop_bonus_label.custom_minimum_size = Vector2(1260, 82)
	host.shop_bonus_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host.shop_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.shop_bonus_label.text = host._ad_bonus_runtime().shop_label_text()
	stack.add_child(host.shop_bonus_label)
	var message_spacer := Control.new()
	message_spacer.custom_minimum_size = Vector2(0, 118)
	stack.add_child(message_spacer)
	var message: Label = host._label("Hi! Thanks for playing my game :)\nThere are no microtransactions here. Just an optional ad to speed things up if you'd like to use it. Thanks!", 66, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	message.custom_minimum_size = Vector2(1420, 220)
	message.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(message)
	if not host.shop_rate_prompt_dismissed:
		var review_spacer := Control.new()
		review_spacer.custom_minimum_size = Vector2(0, 42)
		stack.add_child(review_spacer)
		var review_stars := HBoxContainer.new()
		review_stars.alignment = BoxContainer.ALIGNMENT_CENTER
		review_stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		review_stars.add_theme_constant_override("separation", 10)
		var star_texture: Texture2D = host.visual_texture_cache._texture(host.PROGRESS_STAR_ICON_TEXTURE)
		for i in range(5):
			var star: TextureRect = host.visual_texture_cache._image_from_texture(star_texture, Vector2(48, 48))
			star.modulate = host.COLOR_MUTED.lightened(0.12)
			review_stars.add_child(star)
		stack.add_child(review_stars)
		var review: Label = host._label("Please rate Idle Elite on the store page to help me continue developing this game!", 60, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		review.custom_minimum_size = Vector2(1420, 150)
		review.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		review.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(review)
		var rate_button: Button = host._menu_button("Rate on Play Store")
		rate_button.custom_minimum_size = Vector2(840, 142)
		rate_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		rate_button.add_theme_font_size_override("font_size", 60)
		rate_button.add_theme_stylebox_override("normal", host._paper_button_style(Color("#48dd6c"), 42))
		rate_button.add_theme_stylebox_override("hover", host._paper_button_style(Color("#5eed7c"), 42))
		rate_button.add_theme_stylebox_override("pressed", host._paper_button_style(Color("#38c45a"), 42, 64, true))
		rate_button.pressed.connect(rate_pressed)
		stack.add_child(rate_button)
	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 96)
	stack.add_child(bottom_spacer)

func rate_pressed() -> void:
	var url: String = host.PLAY_STORE_RATING_ANDROID_URL if OS.get_name() == "Android" else host.PLAY_STORE_RATING_URL
	var err: Error = OS.shell_open(url)
	var opened := err == OK
	if not opened and url != host.PLAY_STORE_RATING_URL:
		opened = OS.shell_open(host.PLAY_STORE_RATING_URL) == OK
	if opened:
		host.shop_rate_prompt_dismissed = true
		host._set_result("Opening Play Store.")
		host.save_game()
		if host.current_screen == "shop":
			host._render_screen()
	else:
		host._set_result("Couldn't open Play Store.")

func sync_bonus_display() -> void:
	if host.shop_bonus_label != null:
		host._set_label_text_if_changed(host.shop_bonus_label, host._ad_bonus_runtime().shop_label_text())
	sync_ad_stack_meter()

func emphasize_bonus_award() -> void:
	if host.shop_bonus_label == null or not is_instance_valid(host.shop_bonus_label) or not host.shop_bonus_label.is_visible_in_tree():
		return
	host._reward_feedback_surface()._flash_bonus_control(host.shop_bonus_label)
	if shop_ad_stack_meter_panel != null and is_instance_valid(shop_ad_stack_meter_panel) and shop_ad_stack_meter_panel.is_visible_in_tree():
		host._reward_feedback_surface()._flash_bonus_control(shop_ad_stack_meter_panel, 0.06)
	host._reward_feedback_surface()._float_reward(host, host.shop_bonus_label, "+10% XP", 66, host.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -44), Vector2(0, -136), 0.0)
	host._reward_feedback_surface()._float_reward(host, host.shop_bonus_label, "-10% TIME", 66, host.BONUS_EMPHASIS_FLOAT_COLOR, Vector2(0, -10), Vector2(0, -136), 0.14)

func ad_offer_button() -> Button:
	var button: Button = host._menu_button("")
	button.custom_minimum_size = Vector2(1200, 540)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_stylebox_override("normal", host._paper_button_style(host.COLOR_BLUE, 54))
	button.add_theme_stylebox_override("hover", host._paper_button_style(host.COLOR_BLUE, 54))
	button.add_theme_stylebox_override("pressed", host._paper_button_style(host.COLOR_BLUE.darkened(0.10), 54, 72, true))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(host.visual_texture_cache._image(host.REWARDED_AD_ICON_TEXTURE, Vector2(340, 340)))
	var copy := VBoxContainer.new()
	copy.custom_minimum_size = Vector2(730, 0)
	copy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(copy)
	var details_text := "+10% XP\n+10% speed\n2 hours (stackable)"
	var details: Label = host._label(details_text, 74, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	details.add_theme_color_override("font_outline_color", host.COLOR_INK)
	details.add_theme_constant_override("outline_size", host.DEFAULT_BUTTON_TEXT_OUTLINE_SIZE)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.autowrap_mode = TextServer.AUTOWRAP_OFF
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(details)
	return button

func ad_stack_meter() -> Control:
	var meter := VBoxContainer.new()
	meter.custom_minimum_size = Vector2(112, 336)
	meter.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	meter.alignment = BoxContainer.ALIGNMENT_CENTER
	meter.add_theme_constant_override("separation", 18)
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_ad_stack_meter_panel = meter
	var lights := VBoxContainer.new()
	lights.alignment = BoxContainer.ALIGNMENT_CENTER
	lights.add_theme_constant_override("separation", 0)
	lights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.add_child(lights)
	var max_count := ad_stack_max_count()
	for i in range(max_count):
		var light := ShopAdStackLight.new()
		light.custom_minimum_size = Vector2(112, 112)
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light.set_meta("shop_ad_stack_index", max_count - i - 1)
		lights.add_child(light)
		shop_ad_stack_lights.append(light)
	sync_ad_stack_meter(true)
	return meter

func ad_stack_max_count() -> int:
	return AdBonus.stack_max_count(float(host.AD_BONUS_MAX_SECONDS), float(host.AD_BONUS_SECONDS))

func ad_stack_units() -> float:
	return AdBonus.stack_units(host.ad_bonus_seconds_remaining, float(host.AD_BONUS_SECONDS), float(host.AD_BONUS_MAX_SECONDS))

func ad_stack_active_count() -> int:
	return AdBonus.stack_active_count(host.ad_bonus_seconds_remaining, float(host.AD_BONUS_SECONDS), float(host.AD_BONUS_MAX_SECONDS))

func sync_ad_stack_meter(force := false) -> void:
	if shop_ad_stack_lights.is_empty():
		return
	var units := ad_stack_units()
	var max_count := ad_stack_max_count()
	var active_count := ad_stack_active_count()
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
