extends Node2D

@onready var money_label: Label = $CanvasLayer/UI/MoneyLabel
@onready var hp_label: Label = $CanvasLayer/UI/HPLabel
@onready var win_label: Label = $CanvasLayer/UI/WinLabel
@onready var death_label: Label = $CanvasLayer/UI/DeathLabel
@onready var blocker: ColorRect = $CanvasLayer/UI/Blocker
@onready var money_array: Node = $Money
@onready var parallax_bg: Sprite2D = $Player/Camera2D/Background
@onready var value_popup: Panel = $CanvasLayer/UI/ValuePopup
@onready var value_rows: VBoxContainer = $CanvasLayer/UI/ValuePopup/Content/Rows

# Parallax: the background scrolls at this fraction of the camera's speed (0 = static).
const BG_PARALLAX_FACTOR: float = 0.3
# Copies of the background texture tiled horizontally so it never runs out while scrolling.
const BG_TILE_COPIES: int = 3

var _base_camera_x: float = 0.0
var _bg_tile_width: float = 1.0

# The money goal (in cents), set from the combined price of the falling-game
# products. Tracked in cents so decimal prices (like $2.50) work exactly.
var MONEY_TARGET: int = 0
# Value of a dollar-bill pickup vs a coin pickup, in cents.
const MONEY_VALUE_CENTS: int = 100
const COIN_VALUE_CENTS: int = 50
const QUARTER_VALUE_CENTS: int = 25
const DIME_VALUE_CENTS: int = 10

var money: int = 0
var dead: bool = false


func _ready() -> void:
	# Give every money pickup its value (dollar bill = $1, coin = $0.50), then
	# connect it so collecting adds up.
	for node in get_tree().get_nodes_in_group("market_items"):
		var item := node as MarketItem
		if item:
			item.amount = _pickup_value_cents(item)
			item.collected.connect(_on_money_collected)

	# The money goal comes from the falling game: the combined price of every
	# product the player caught. If we're running this scene standalone (no
	# falling game before it), fall back to collecting all the money in the level.
	MONEY_TARGET = GameState.money_target if GameState.money_target > 0 else _total_available_money()

	var player := get_node_or_null("Player") as MarketPlayer
	if player:
		player.health_changed.connect(_on_health_changed)
		player.player_died.connect(_on_player_died)
		_update_hp(player.health)

	_update_money()
	_setup_parallax()

	# Show the "how much is each worth?" popup at the start of the level.
	_show_value_popup()


# Returns how many cents this pickup is worth. Coins are $0.50, everything
# else is a $1 bill.
func _pickup_value_cents(item: MarketItem) -> int:
	if item.scene_file_path.ends_with("dime.tscn"):
		return DIME_VALUE_CENTS
	if item.scene_file_path.ends_with("quarter.tscn"):
		return QUARTER_VALUE_CENTS
	if item.scene_file_path.ends_with("coin.tscn"):
		return COIN_VALUE_CENTS
	return MONEY_VALUE_CENTS


# Sums the money value of every pickup in the level (used as a standalone fallback).
func _total_available_money() -> int:
	var total: int = 0
	for node in get_tree().get_nodes_in_group("market_items"):
		var item := node as MarketItem
		if item:
			total += _pickup_value_cents(item)
	return total


func _setup_parallax() -> void:
	# Use the full texture vertically (it exactly fills the screen, so no vertical
	# tiling is needed) and repeat it horizontally so it can scroll forever.
	if parallax_bg and parallax_bg.texture:
		var tex_size := parallax_bg.texture.get_size()
		_bg_tile_width = tex_size.x
		parallax_bg.region_enabled = true
		parallax_bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		parallax_bg.region_rect = Rect2(0, 0, _bg_tile_width * BG_TILE_COPIES, tex_size.y)
	var cam := $Player/Camera2D as Camera2D
	if cam:
		_base_camera_x = cam.global_position.x


func _process(_delta: float) -> void:
	# While the "how much is each worth?" popup is up, Space/Enter dismisses it.
	if value_popup.visible:
		if Input.is_action_just_pressed("ui_accept"):
			_dismiss_value_popup()
		return

	# Press Space while standing on a money pickup to collect it.
	if Input.is_action_just_pressed("ui_accept"):
		_try_collect_nearby()

	var cam := $Player/Camera2D as Camera2D
	if not cam or not parallax_bg or _bg_tile_width <= 1.0:
		return
	# Shift the shown texture region by a fraction of the camera's horizontal travel.
	var travel := cam.global_position.x - _base_camera_x
	var shift_px := travel * BG_PARALLAX_FACTOR / parallax_bg.scale.x
	var rect := parallax_bg.region_rect
	rect.position.x = wrapf(shift_px, 0.0, _bg_tile_width)
	parallax_bg.region_rect = rect


func _update_money() -> void:
	money_label.text = "Money: %s / %s" % [_format_money(money), _format_money(MONEY_TARGET)]


# Formats a cent amount as dollars, e.g. 1525 -> "$15.25".
func _format_money(cents: int) -> String:
	var sign_str: String = "-" if cents < 0 else ""
	var abs_cents: int = absi(cents)
	var dollars: int = floori(abs_cents / 100.0)
	var leftover: int = abs_cents % 100
	return "%s$%d.%02d" % [sign_str, dollars, leftover]


# Collects the first money pickup the player is currently standing on.
func _try_collect_nearby() -> void:
	if dead:
		return
	for node in get_tree().get_nodes_in_group("market_items"):
		var item := node as MarketItem
		if item and item.collect_if_ready():
			return


func _update_hp(health: int) -> void:
	var hearts := ""
	for i in range(MarketPlayer.MAX_HEALTH):
		hearts += "❤" if i < health else "🖤"
	hp_label.text = hearts


func _on_health_changed(health: int) -> void:
	_update_hp(health)


func _on_money_collected(amount: int) -> void:
	money += amount
	_update_money()
	if money == MONEY_TARGET:
		_win()
	elif money > MONEY_TARGET:
		_call_out()


func _win() -> void:
	win_label.visible = true
	blocker.visible = true
	_freeze_player()


# Collecting more money than needed gets the player called out and restarts.
func _call_out() -> void:
	_die_with_message("You grabbed too much money!\nTry again!")


func _on_player_died() -> void:
	_die_with_message("You got caught!\nTry again!")


func _on_player_fell(_body: Node2D) -> void:
	_die_with_message("You fell!\nTry again!")


func _die_with_message(message: String) -> void:
	if dead:
		return
	dead = true
	death_label.text = message
	death_label.visible = true
	blocker.visible = true
	_freeze_player()
	# Let the player see the message, then restart the market.
	await get_tree().create_timer(1.5).timeout
	SceneTransition.fade_to_reload()


func _freeze_player() -> void:
	var player := get_node_or_null("Player") as CharacterBody2D
	if player:
		player.set_physics_process(false)


func _unfreeze_player() -> void:
	var player := get_node_or_null("Player") as CharacterBody2D
	if player:
		player.set_physics_process(true)


# Shows the "how much is each worth?" popup and pauses the player.
func _show_value_popup() -> void:
	_build_value_rows()
	value_popup.visible = true
	_freeze_player()


func _dismiss_value_popup() -> void:
	if not value_popup.visible:
		return
	value_popup.visible = false
	_unfreeze_player()


# Fills the popup with one row per money type, each showing its sprite and value.
func _build_value_rows() -> void:
	for child in value_rows.get_children():
		child.queue_free()

	var entries: Array = [
		["res://Assets/Sprites/money.png", "%s — Dollar bill" % _format_money(MONEY_VALUE_CENTS)],
		["res://Assets/Sprites/coin.png", "%s — Coin" % _format_money(COIN_VALUE_CENTS)],
		["res://Assets/Sprites/quarter.png", "%s — Quarter" % _format_money(QUARTER_VALUE_CENTS)],
		["res://Assets/Sprites/dime.png", "%s — Dime" % _format_money(DIME_VALUE_CENTS)],
	]

	for entry in entries:
		value_rows.add_child(_make_value_row(entry[0], entry[1]))


# Creates a single sprite + label row for the popup.
func _make_value_row(texture_path: String, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)

	var tex_rect := TextureRect.new()
	tex_rect.texture = load(texture_path)
	tex_rect.custom_minimum_size = Vector2(44, 44)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(tex_rect)

	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	row.add_child(label)

	return row


func _unhandled_input(event: InputEvent) -> void:
	if not value_popup.visible:
		return
	if event is InputEventKey and event.pressed:
		_dismiss_value_popup()


func _on_value_popup_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_dismiss_value_popup()


func _on_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and win_label.visible and not dead:
		SceneTransition.fade_to("res://Scenes/checkout.tscn")
