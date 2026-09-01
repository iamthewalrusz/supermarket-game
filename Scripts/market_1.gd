extends Node2D

@onready var money_label: Label = $CanvasLayer/UI/MoneyLabel
@onready var hp_label: Label = $CanvasLayer/UI/HPLabel
@onready var win_label: Label = $CanvasLayer/UI/WinLabel
@onready var death_label: Label = $CanvasLayer/UI/DeathLabel
@onready var blocker: ColorRect = $CanvasLayer/UI/Blocker
@onready var money_array: Node = $Money
@onready var parallax_bg: Sprite2D = $Player/Camera2D/Background

# Parallax: the background scrolls at this fraction of the camera's speed (0 = static).
const BG_PARALLAX_FACTOR: float = 0.3
# Copies of the background texture tiled horizontally so it never runs out while scrolling.
const BG_TILE_COPIES: int = 3

var _base_camera_x: float = 0.0
var _bg_tile_width: float = 1.0

# Determined automatically from the number of money pickups in the scene.
var MONEY_TARGET: int = 0

var money: int = 0
var dead: bool = false


func _ready() -> void:
	# Target = number of money pickups placed in the scene.
	MONEY_TARGET = money_array.get_child_count()

	# Connect every money pickup so collecting it adds to our total.
	for item_node in get_tree().get_nodes_in_group("market_items"):
		var item := item_node as MarketItem
		item.collected.connect(_on_money_collected)

	var player := get_node_or_null("Player") as MarketPlayer
	if player:
		player.health_changed.connect(_on_health_changed)
		player.player_died.connect(_on_player_died)
		_update_hp(player.health)

	_update_money()
	_setup_parallax()


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
	money_label.text = "Money: %d / %d" % [money, MONEY_TARGET]


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
	if money >= MONEY_TARGET:
		_win()


func _win() -> void:
	win_label.visible = true
	blocker.visible = true
	_freeze_player()


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


func _on_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and win_label.visible and not dead:
		SceneTransition.fade_to("res://Scenes/menu.tscn")
