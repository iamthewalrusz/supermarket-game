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

## How many tiles out from the player the fog is lifted. Revealed tiles stay
## uncovered, so the path the player has travelled stays visible.
const REVEAL_RADIUS: int = 2

@onready var player: MazePlayer = $Player
@onready var cashier: Sprite2D = $Cashier
@onready var fog: TileMapLayer = $Fog
@onready var message_panel: Panel = $CanvasLayer/UI/MessagePanel
@onready var message_label: Label = $CanvasLayer/UI/MessagePanel/MessageLabel
@onready var blocker: ColorRect = $CanvasLayer/UI/Blocker

var _won: bool = false
var _caught: bool = false
var _last_reveal_tile: Vector2i = Vector2i(999999, 999999)


func _ready() -> void:
	# Detect the player arriving at the cashier.
	$Goal.body_entered.connect(_on_goal_entered)

	# Any maze guard that touches the player sends the run back to the start.
	for enemy in get_tree().get_nodes_in_group("maze_enemies"):
		if enemy is MazeEnemy:
			(enemy as MazeEnemy).player_caught.connect(_on_player_caught)

	message_panel.visible = false
	blocker.visible = false

	# Lift the fog around the player's starting tile right away.
	_reveal_around_player()

	# Gently pulse the cashier so it stands out as the goal.
	var pulse: Tween = create_tween().set_loops()
	pulse.tween_property(cashier, "scale", Vector2(0.5, 0.5), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(cashier, "scale", Vector2(0.4, 0.4), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(_delta: float) -> void:
	_reveal_around_player()


## Clears fog tiles within REVEAL_RADIUS of the player. Tiles uncovered earlier
## stay uncovered, drawing the route the player has already walked.
func _reveal_around_player() -> void:
	if fog == null or player == null:
		return

	var tile: Vector2i = fog.local_to_map(fog.to_local(player.global_position))
	if tile == _last_reveal_tile:
		return
	_last_reveal_tile = tile

	for dy in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
		for dx in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
			if dx * dx + dy * dy > REVEAL_RADIUS * REVEAL_RADIUS + REVEAL_RADIUS:
				continue
			fog.erase_cell(tile + Vector2i(dx, dy))


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


## Called when a maze guard reaches the player: restart the maze from the top.
func _on_player_caught() -> void:
	if _won or _caught:
		return
	_caught = true
	player.set_physics_process(false)
	message_label.text = "Caught by a maze guard!\nStart over from the beginning..."
	message_panel.visible = true
	blocker.visible = true
	await get_tree().create_timer(1.8).timeout
	SceneTransition.fade_to_reload()


func _on_blocker_gui_input(event: InputEvent) -> void:
	if _won and event is InputEventMouseButton and event.pressed:
		SceneTransition.fade_to("res://Scenes/ending.tscn")
