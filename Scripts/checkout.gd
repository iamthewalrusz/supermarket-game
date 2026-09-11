class_name Checkout
extends Node2D
## Follow-up to the market level: the player must pick which shopping cart is
## theirs. The correct cart holds exactly the products they caught in the
## falling game and totals the same price they had to pay. Two decoy carts
## differ in products and/or price.

const PRODUCT_POOL: Array[Dictionary] = [
	{"name": "Apple", "price": 1.50, "texture": "res://Assets/apple-fruit-cartoon-transparent-28.png"},
	{"name": "Milk", "price": 2.20, "texture": "res://Assets/milk-box-3d-rendering-isometric-icon-png.png"},
	{"name": "Eggs", "price": 2.00, "texture": "res://Assets/1536745806-clipart-xl.png"},
	{"name": "Steak", "price": 4.00, "texture": "res://Assets/steak-graphic-clipart-design-free-png.png"},
	{"name": "Banana", "price": 1.50, "texture": "res://Assets/banana.png"},
	{"name": "Bread", "price": 2.30, "texture": "res://Assets/bread.png"},
	{"name": "Cheese", "price": 3.50, "texture": "res://Assets/cheese.png"},
	{"name": "Fish", "price": 3.20, "texture": "res://Assets/fish.png"},
]

const CART_ICON: String = "res://Assets/generated/shopping_cart_frame_0.png"

@onready var carts_box: HBoxContainer = $CanvasLayer/UI/Carts
@onready var feedback_label: Label = $CanvasLayer/UI/Feedback
@onready var result_panel: Panel = $CanvasLayer/UI/ResultPanel
@onready var result_label: Label = $CanvasLayer/UI/ResultPanel/ResultLabel

# Data for each cart: { "items": Array, "correct": bool }
var _carts: Array[Dictionary] = []
var _panels: Array[PanelContainer] = []
var _selected: int = 0
var _solved: bool = false
var _locked: bool = false

var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat
var _wrong_style: StyleBoxFlat

var _correct_total: int = 0


func _ready() -> void:
	_build_styles()
	var items: Array[Dictionary] = _load_items()
	_correct_total = _total_cents(items)
	_build_carts(items)
	_update_selection()
	result_panel.visible = false
	feedback_label.visible = false


# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------

# The products the player caught (from the falling game). Falls back to a fixed
# set when this scene is run on its own.
func _load_items() -> Array[Dictionary]:
	if not GameState.required_items_detail.is_empty():
		var items: Array[Dictionary] = []
		for entry: Dictionary in GameState.required_items_detail:
			items.append(entry.duplicate())
		return items

	var fallback: Array[Dictionary] = []
	for entry: Dictionary in [
		{"name": "Apple", "count": 2},
		{"name": "Milk", "count": 3},
		{"name": "Eggs", "count": 2},
	]:
		var item: Dictionary = _pool_item(entry["name"])
		item["count"] = entry["count"]
		fallback.append(item)
	return fallback


func _pool_item(item_key: String) -> Dictionary:
	for entry: Dictionary in PRODUCT_POOL:
		if entry["name"] == item_key:
			return {
				"name": item_key,
				"price_cents": roundi(float(entry["price"]) * 100.0),
				"texture": entry["texture"],
				"count": 1,
			}
	return {"name": item_key, "price_cents": 100, "texture": "", "count": 1}


# Builds three carts, exactly one of which matches what the player caught.
func _build_carts(correct: Array[Dictionary]) -> void:
	var correct_sig: String = _signature(correct)
	var wrong_a: Array[Dictionary] = _make_wrong(correct, correct_sig)
	var wrong_b: Array[Dictionary] = _make_wrong(correct, correct_sig)
	# Make sure the two decoys aren't identical to each other.
	var guard: int = 0
	while _signature(wrong_b) == _signature(wrong_a) and guard < 20:
		wrong_b = _make_wrong(correct, correct_sig)
		guard += 1

	var layouts: Array[Array] = [correct, wrong_a, wrong_b]
	layouts.shuffle()

	for i: int in range(layouts.size()):
		var is_correct: bool = _signature(layouts[i]) == correct_sig and _total_cents(layouts[i]) == _correct_total
		_carts.append({"items": layouts[i], "correct": is_correct})
		var panel: PanelContainer = _make_cart_panel(layouts[i], i)
		_panels.append(panel)
		carts_box.add_child(panel)


# Produces a decoy cart that differs from the correct one in total price and/or
# in the products it holds.
func _make_wrong(correct: Array[Dictionary], correct_sig: String) -> Array[Dictionary]:
	var variant: Array[Dictionary] = _duplicate_items(correct)
	for _attempt: int in range(30):
		variant = _duplicate_items(correct)
		match randi() % 2:
			0:
				# Change one product's quantity (same products, different price).
				var i: int = randi() % variant.size()
				var delta: int = 1 if randi() % 2 == 0 else -1
				variant[i]["count"] = maxi(1, int(variant[i]["count"]) + delta)
			_:
				# Swap a product for a different one (different products + price).
				var j: int = randi() % variant.size()
				var candidates: Array[String] = _pool_names_not_in(variant)
				if candidates.is_empty():
					variant[j]["count"] = maxi(1, int(variant[j]["count"]) + 1)
				else:
					var replacement: Dictionary = _pool_item(candidates[randi() % candidates.size()])
					replacement["count"] = randi_range(1, 4)
					variant[j] = replacement
		if _total_cents(variant) != _correct_total and _signature(variant) != correct_sig:
			return variant

	# Guaranteed-different fallback: add one extra unit of the first product.
	variant = _duplicate_items(correct)
	variant[0]["count"] = int(variant[0]["count"]) + 1
	return variant


func _duplicate_items(items: Array[Dictionary]) -> Array[Dictionary]:
	var copy: Array[Dictionary] = []
	for item: Dictionary in items:
		copy.append(item.duplicate())
	return copy


func _total_cents(items: Array[Dictionary]) -> int:
	var total: int = 0
	for item: Dictionary in items:
		total += int(item["price_cents"]) * int(item["count"])
	return total


# A stable fingerprint of a cart's contents (products + quantities), used to
# tell whether two carts are really the same.
func _signature(items: Array[Dictionary]) -> String:
	var parts: Array[String] = []
	for item: Dictionary in items:
		parts.append("%s:%d" % [item["name"], int(item["count"])])
	parts.sort()
	return ",".join(parts)


func _pool_names_not_in(items: Array[Dictionary]) -> Array[String]:
	var used: Array[String] = []
	for item: Dictionary in items:
		used.append(item["name"])
	var result: Array[String] = []
	for entry: Dictionary in PRODUCT_POOL:
		if not used.has(entry["name"]):
			result.append(entry["name"])
	return result


# ---------------------------------------------------------------------------
# UI
# ---------------------------------------------------------------------------

func _make_cart_panel(items: Array[Dictionary], index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 420)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_entered.connect(_on_cart_hovered.bind(index))
	panel.gui_input.connect(_on_cart_gui_input.bind(index))

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_BEGIN
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	# Cart icon + title.
	var icon := TextureRect.new()
	icon.texture = load(CART_ICON)
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	col.add_child(icon)

	var title := Label.new()
	title.text = "Cart %d" % (index + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	col.add_child(title)

	# One row per product.
	for item: Dictionary in items:
		col.add_child(_make_product_row(item))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(spacer)

	col.add_child(_make_separator())

	var total := Label.new()
	total.text = "Total: %s" % _format_money(_total_cents(items))
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total.add_theme_font_size_override("font_size", 30)
	total.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	total.add_theme_constant_override("outline_size", 6)
	total.add_theme_color_override("font_outline_color", Color.BLACK)
	col.add_child(total)

	return panel


func _make_product_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 12)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item["texture"] != "":
		icon.texture = load(item["texture"])
	row.add_child(icon)

	var label := Label.new()
	label.text = "%s x%d" % [item["name"], int(item["count"])]
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	row.add_child(label)

	return row


func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	return sep


func _build_styles() -> void:
	_normal_style = _make_style(Color(0.1, 0.1, 0.15, 0.92), Color(0.4, 0.4, 0.5, 1.0), 3)
	_selected_style = _make_style(Color(0.16, 0.18, 0.26, 0.98), Color(1.0, 0.9, 0.3, 1.0), 6)
	_wrong_style = _make_style(Color(0.16, 0.08, 0.08, 0.92), Color(0.8, 0.25, 0.25, 1.0), 3)


func _make_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(16)
	return style


func _update_selection() -> void:
	for i: int in range(_panels.size()):
		var panel: PanelContainer = _panels[i]
		if _carts[i].get("wrong_picked", false):
			panel.add_theme_stylebox_override("panel", _wrong_style)
		elif i == _selected:
			panel.add_theme_stylebox_override("panel", _selected_style)
		else:
			panel.add_theme_stylebox_override("panel", _normal_style)


func _format_money(cents: int) -> String:
	var dollars: int = floori(cents / 100.0)
	var leftover: int = cents % 100
	return "$%d.%02d" % [dollars, leftover]


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if _solved or _locked:
		return
	if Input.is_action_just_pressed("ui_left"):
		_selected = wrapi(_selected - 1, 0, _panels.size())
		_update_selection()
	elif Input.is_action_just_pressed("ui_right"):
		_selected = wrapi(_selected + 1, 0, _panels.size())
		_update_selection()
	elif Input.is_action_just_pressed("ui_accept"):
		_choose(_selected)


func _on_cart_hovered(index: int) -> void:
	if _solved or _locked:
		return
	_selected = index
	_update_selection()


func _on_cart_gui_input(event: InputEvent, index: int) -> void:
	if _solved or _locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected = index
		_update_selection()
		_choose(index)


func _choose(index: int) -> void:
	if _carts[index].get("wrong_picked", false):
		return

	if _carts[index]["correct"]:
		_solved = true
		_show_result("That's my cart! 🎉\nEverything matches — great shopping!")
	else:
		_carts[index]["wrong_picked"] = true
		_update_selection()
		_toast("That's not my cart!\nCheck the products and the total.", Color(1.0, 0.4, 0.4))
		_locked = true
		await get_tree().create_timer(1.2).timeout
		_locked = false
		# If every wrong cart has been used up, that shouldn't happen (two decoys),
		# but guard anyway.
		if _remaining_decoy_count() == 0 and not _solved:
			_show_result("Hmm, that was the last one.\nLet's try again!")
			await get_tree().create_timer(1.5).timeout
			SceneTransition.fade_to_reload()


func _remaining_decoy_count() -> int:
	var count: int = 0
	for cart: Dictionary in _carts:
		if not cart["correct"] and not cart.get("wrong_picked", false):
			count += 1
	return count


func _toast(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	feedback_label.visible = true
	feedback_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(0.9)
	tween.tween_property(feedback_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void: feedback_label.visible = false)


func _show_result(text: String) -> void:
	result_label.text = text
	result_panel.visible = true
	await get_tree().create_timer(2.2).timeout
	SceneTransition.fade_to("res://Scenes/menu.tscn")
