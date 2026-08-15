extends Node2D

@onready var list_label: Label = $UI/ListLabel
@onready var win_label: Label = $UI/WinLabel
@onready var blocker: ColorRect = $UI/Blocker

var required_items: Array[String] = []
var picked_up_items: Array[String] = []


func _ready() -> void:
	# Read the items that were chosen in FallingGame (via the shared autoload).
	required_items = GameState.required_items.duplicate()
	if required_items.is_empty():
		required_items = ["Apple", "Milk", "Eggs"]

	for item_node in get_tree().get_nodes_in_group("market_items"):
		var item := item_node as MarketItem
		if item.item_name not in required_items:
			item.queue_free()
		else:
			item.picked_up.connect(_on_item_picked_up)

	_update_list()


func _update_list() -> void:
	var text := "Shopping List:"
	for name_i: String in required_items:
		var mark := "☐"
		if name_i in picked_up_items:
			mark = "✓"
		text += "\n" + mark + " " + name_i
	list_label.text = text


func _on_item_picked_up(item_name: String) -> void:
	if item_name in required_items and item_name not in picked_up_items:
		GameState.picked_up_in_market.append(item_name)
		picked_up_items.append(item_name)
		_update_list()
		if picked_up_items.size() >= required_items.size():
			_win()


func _win() -> void:
	win_label.visible = true
	blocker.visible = true
	var player := get_node_or_null("Player") as CharacterBody2D
	if player:
		player.set_physics_process(false)


func _on_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and win_label.visible:
		SceneTransition.fade_to("res://Scenes/falling_game.tscn")
