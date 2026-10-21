class_name MazeGame
extends Node2D
## Maze minigame that follows the market: steer through the supermarket maze to
## reach the cashier, then pay at the checkout.
##
## The layout is authored directly in the scene as tiles painted on the "Walls"
## and "Floor" TileMapLayers, so you can edit it with Godot's TileMap tools
## (select the layer, open the TileMap panel, paint/erase). The "Walls" tileset
## carries collision, so every wall you paint blocks the player automatically.
##
## The start is wherever the "Player" node sits; the goal/cashier is wherever the
## "Cashier" and "Goal" nodes sit. Move those nodes to relocate start and finish.

@onready var player: MazePlayer = $Player
@onready var cashier: Sprite2D = $Cashier
@onready var message_panel: Panel = $CanvasLayer/UI/MessagePanel
@onready var message_label: Label = $CanvasLayer/UI/MessagePanel/MessageLabel
@onready var blocker: ColorRect = $CanvasLayer/UI/Blocker

var _won: bool = false


func _ready() -> void:
	# Detect the player arriving at the cashier.
	$Goal.body_entered.connect(_on_goal_entered)

	message_panel.visible = false
	blocker.visible = false

	# Gently pulse the cashier so it stands out as the goal.
	var pulse: Tween = create_tween().set_loops()
	pulse.tween_property(cashier, "scale", Vector2(0.5, 0.5), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(cashier, "scale", Vector2(0.4, 0.4), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_goal_entered(body: Node2D) -> void:
	if _won or not (body is MazePlayer):
		return
	_won = true
	player.set_physics_process(false)
	message_label.text = "You made it to the cashier!\nTime to pay for your items..."
	message_panel.visible = true
	blocker.visible = true
	await get_tree().create_timer(2.2).timeout
	SceneTransition.fade_to("res://Scenes/ending.tscn")


func _on_blocker_gui_input(event: InputEvent) -> void:
	if _won and event is InputEventMouseButton and event.pressed:
		SceneTransition.fade_to("res://Scenes/ending.tscn")
