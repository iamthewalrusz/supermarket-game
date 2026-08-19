extends Node2D

@onready var money_label: Label = $UI/MoneyLabel
@onready var hp_label: Label = $UI/HPLabel
@onready var win_label: Label = $UI/WinLabel
@onready var death_label: Label = $UI/DeathLabel
@onready var blocker: ColorRect = $UI/Blocker

const MONEY_TARGET: int = 8

var money: int = 0
var dead: bool = false


func _ready() -> void:
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
	if dead:
		return
	dead = true
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
		SceneTransition.fade_to("res://Scenes/falling_game.tscn")
