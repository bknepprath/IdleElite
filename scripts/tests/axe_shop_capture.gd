extends "res://scripts/tests/action_art_oct22.gd"

func _run() -> void:
	OS.set_environment("IDLE_ELITE_DESKTOP","1")
	await super._run()

func part_point(shop: Control,kind: String) -> Vector2:
	return shop.get_global_transform_with_canvas() * (shop.art_rect.position + shop.PART_ANCHORS[kind] / 512.0 * shop.art_rect.size)

func audit_action_art() -> void:
	for material in game.material_runtime.material_defs: game.material_runtime.set_amount(str(material),1000)
	var runtime = game._grove_runtime()
	runtime.reset()
	await open_notes_skill("woodcutting")
	var card := await notes_card("grove-birch")
	await align_notes_card(card)
	var stage: Control = card.grove_stage
	await capture("arena-level")
	await click(stage.axe_button.get_global_rect().get_center(),true)
	var shop: Control = stage.shop
	check(shop.visible,"Axe badge opens the real shop")
	check(shop.get_global_rect().end.y < game.detail_actions_scroll.get_global_rect().end.y,"Shop remains inside the gameplay viewport")
	var before: Dictionary = runtime.upgrades.duplicate()
	var running_before: String = game.running_action_id
	for touch in [true,false]:
		for kind in runtime.KINDS:
			await click(part_point(shop,kind),touch)
			check(shop.selected_kind==kind,"Physical part selects with touch/mouse: "+kind)
			check(runtime.upgrades==before,"Selecting a piece does not purchase: "+kind)
			check(shop.title_label.text==str(kind).capitalize(),"Selected name refreshes: "+kind)
			check(not shop.cost_label.text.is_empty() and not shop.material_label.text.is_empty(),"Selected piece shows cost and material: "+kind)
			var selected_cost: Dictionary = runtime.upgrade_cost(kind)
			check(shop.inventory_label.text=="Owned 1K","Selected piece shows its own material inventory: "+kind)
			check(shop.material_label.text==game.material_runtime.display_name(str(selected_cost.id)),"Inventory belongs to the displayed cost material: "+kind)
			check(not shop.inventory_label.get_global_rect().intersects(shop.purchase_button.get_global_rect()),"Owned amount clears the purchase button")
			check(not shop.effect_label.text.is_empty(),"Selected piece shows its benefit: "+kind)
			check(not shop.material_label.get_global_rect().intersects(shop.purchase_button.get_global_rect()),"Material name clears the purchase button")
			if touch: await capture("shop-"+kind)
	check(game.running_action_id==running_before,"Shop input does not start the arena")
	await click(part_point(shop,"handle"),true)
	var cost: Dictionary = runtime.upgrade_cost("handle")
	var amount_before: float = game.material_runtime.amount(str(cost.id))
	await click(shop.purchase_button.get_global_rect().get_center(),true)
	check(int(runtime.upgrades.handle)==1,"Upgrade button purchases the selected handle once")
	check(game.material_runtime.amount(str(cost.id))==amount_before-float(cost.amount),"Purchase spends the exact displayed price")
	check(shop.level_label.text=="Level 1 → 2" and shop.cost_label.text=="60","Purchase refreshes level and next price")
	check(shop.inventory_label.text=="Owned 985","Purchase refreshes the owned balance immediately")
	await capture("shop-purchased")
	await click(part_point(shop,"sharpening"),true)
	await click(shop.purchase_button.get_global_rect().get_center(),false)
	await click(shop.purchase_button.get_global_rect().get_center(),true)
	check(int(runtime.upgrades.sharpening)==1,"Sharpening blocks a second ineffective purchase")
	check(shop.purchase_button.disabled and shop.requirement_label.text=="Head required","Head prerequisite is visible")
	await capture("shop-head-required")
	await click(part_point(shop,"gem"),false)
	game.material_runtime.set_amount("wooden-parts",0)
	await settle(.4)
	check(shop.purchase_button.disabled,"Insufficient materials disable purchase")
	check(shop.inventory_label.text=="Owned 0","Live inventory changes refresh while the shop stays open")
	await click(shop.purchase_button.get_global_rect().get_center(),true)
	check(int(runtime.upgrades.gem)==0,"Disabled purchase preserves the selected upgrade")
	await capture("shop-unaffordable")
	game.material_runtime.set_amount("ironwood",321)
	runtime.upgrades.head=4
	await click(part_point(shop,"head"),true)
	check(shop.inventory_label.text=="Owned 321" and shop.material_label.text=="Ironwood","Higher-level cost switches the owned balance to Ironwood")
	await capture("shop-ironwood-inventory")
	runtime.upgrades.head=8
	await click(part_point(shop,"head"),true)
	check(shop.purchase_button.disabled and shop.purchase_button.text=="Max level","Capped piece stays selectable with purchase disabled")
	check(not shop.cost_icon.visible and shop.material_label.text.is_empty(),"Capped piece has no stale cost")
	check(shop.inventory_label.text.is_empty(),"Capped piece has no stale inventory balance")
	await capture("shop-max-level")
	await click(shop.close_button.get_global_rect().get_center(),true)
	check(not shop.visible,"Close button dismisses shop")
	runtime.axe_xp=20
	await settle(.4)
	await capture("arena-level-2")
	await click(stage.axe_button.get_global_rect().get_center(),false)
	check(shop.visible,"Mouse reopens shop")
	await click(shop.get_global_rect().position+Vector2(-12,100),true)
	check(not shop.visible,"Outside tap dismisses shop")
	check(game.running_action_id==running_before,"Outside dismissal does not start chopping")
	# Recheck the actual production shop in the desktop layout.
	runtime.upgrades.head=0
	root.size=Vector2i(1920,1080)
	await settle(2)
	await game._skill_detail_surface()._scroll_to_activity_card("grove-birch",false,true)
	await settle(.7)
	card=game.action_cards.get("woodcutting:grove-birch",{})
	stage=card.grove_stage
	await desktop_click(stage.axe_button.get_global_rect().get_center())
	shop=stage.shop
	check(shop.visible,"Desktop badge opens the same production shop")
	await desktop_click(part_point(shop,"head"))
	check(shop.selected_kind=="head","Desktop axe head selects")
	check(not shop.material_label.get_global_rect().intersects(shop.purchase_button.get_global_rect()),"Desktop material name clears the purchase button")
	await RenderingServer.frame_post_draw
	var desktop_image:=root.get_texture().get_image()
	check(desktop_image.get_size()==Vector2i(1920,1080),"Desktop proof is the raw viewport")
	desktop_image.save_png(capture_dir+"/shop-desktop.png")
	await desktop_click(shop.close_button.get_global_rect().get_center())
	check(not shop.visible,"Desktop close dismisses shop")
	print("AXE_SHOP failures=",JSON.stringify(failures))
	var result := FileAccess.open(capture_dir+"/result.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"failures":failures}))
	result.close()
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	quit(0 if failures.is_empty() else 1)

func desktop_click(point: Vector2) -> void:
	# Input.parse_input_event accepts window pixels; controls report canvas units.
	var pixel_scale := Vector2(root.size) / root.get_visible_rect().size
	await click(point * pixel_scale, false)
