class_name FallingGame
extends Node2D

const TARGET_ITEMS: Array[Dictionary] = [
	{"name": "Apple", "texture": "res://Assets/apple-fruit-cartoon-transparent-28.png"},
	{"name": "Milk", "texture": "res://Assets/milk-box-3d-rendering-isometric-icon-png.png"},
	{"name": "Eggs", "texture": "res://Assets/1536745806-clipart-xl.png"},
]

const DISTRACTOR_ITEMS: Array[Dictionary] = [
	{"name": "Steak", "texture": "res://Assets/steak-graphic-clipart-design-free-png.png", "color": "ff6666"},
	{"name": "Banana", "texture": "res://Assets/banana.png", "color": "ffff66"},
	{"name": "Bread", "texture": "res://Assets/bread.png", "color": "cc9966"},
	{"name": "Cheese", "texture": "res://Assets/cheese.png", "color": "ffaa00"},
	{"name": "Fish", "texture": "res://Assets/fish.png", "color": "66ccff"},
]

const STARTING_LIVES: int = 3
const NEEDED_PER_ITEM: int = 3

var collected_counts: Dictionary = {}
var lives: int = STARTING_LIVES
var score: float = 0.0
var game_over: bool = false

@onready var spawn_timer: Timer = $SpawnTimer
@onready var player_basket: PlayerBasket = $PlayerBasket
@onready var target_list_label: Label = $UI/TargetListLabel
@onready var collected_list_label: Label = $UI/CollectedListLabel
@onready var lives_label: Label = $UI/LivesLabel
@onready var score_label: Label = $UI/ScoreLabel
@onready var message_panel: Panel = $UI/MessagePanel
@onready var message_label: Label = $UI/MessagePanel/MessageLabel
@onready var blocker: ColorRect = $UI/Blocker
@onready var anim = $PlayerBasket/AnimatedSprite2D

func _ready() -> void:
	# Record how many of each item the player must find.
	for item: Dictionary in TARGET_ITEMS:
		collected_counts[item["name"]] = 0

	update_ui()
	spawn_timer.start()
	blocker.visible = false
	message_panel.visible = false

	# Record the items the player must find so the market platformer knows them.
	GameState.required_items = []
	for item: Dictionary in TARGET_ITEMS:
		GameState.required_items.append(item["name"])

	var target_names: Array[String] = []
	for item: Dictionary in TARGET_ITEMS:
		target_names.append(item["name"])
	target_list_label.text = "Find 5 of each: " + ", ".join(target_names)


func _process(delta: float) -> void:
	if game_over:
		return
	score += 10.0 * delta
	score_label.text = "Score: %d" % int(score)
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		anim.play("walking")
	else:
		anim.play("standing")

func spawn_item() -> void:
	if game_over:
		return

	var item_scene: PackedScene = preload("res://Scenes/falling_item.tscn")
	var item: FallingItem = item_scene.instantiate()

	var spawn_target: bool = (randi() % 100) < 55

	if spawn_target:
		var item_data: Dictionary = TARGET_ITEMS[randi() % TARGET_ITEMS.size()]
		item.setup(item_data["name"], true, load(item_data["texture"]), Color.WHITE)
	else:
		var item_data: Dictionary = DISTRACTOR_ITEMS[randi() % DISTRACTOR_ITEMS.size()]
		var color: Color = Color.from_string(item_data["color"], Color.WHITE)
		item.setup(item_data["name"], false, load(item_data["texture"]), color)

	item.position.x = randf_range(120, 1030)
	item.position.y = -60
	item.fall_speed = randf_range(160, 320)
	item.collected.connect(_on_item_collected)

	add_child(item)


func _on_item_collected(item_name: String, is_target: bool) -> void:
	if game_over:
		return

	if is_target:
		if int(collected_counts[item_name]) < NEEDED_PER_ITEM:
			collected_counts[item_name] = int(collected_counts[item_name]) + 1
			score += 100
			update_ui()

			if _all_collected():
				win_game()
		else:
			# Already have enough of this item - collecting it costs a heart.
			_lose_heart()
	else:
		_lose_heart()


func _lose_heart() -> void:
	lives -= 1
	update_ui()
	_shake_player()

	if lives <= 0:
		lose_game()


func _shake_player() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(player_basket, "modulate", Color.RED, 0.08)
	tween.tween_property(player_basket, "modulate", Color.WHITE, 0.25)


func update_ui() -> void:
	var heart_text: String = ""
	for i: int in range(STARTING_LIVES):
		if i < lives:
			heart_text += "❤ "
		else:
			heart_text += "🖤 "
	lives_label.text = heart_text.strip_edges()

	var collected_parts: Array[String] = []
	for item: Dictionary in TARGET_ITEMS:
		var count: int = int(collected_counts[item["name"]])
		collected_parts.append("%s %d/%d" % [item["name"], count, NEEDED_PER_ITEM])
	collected_list_label.text = "Collected: " + ", ".join(collected_parts)


func _all_collected() -> bool:
	for item: Dictionary in TARGET_ITEMS:
		if int(collected_counts[item["name"]]) < NEEDED_PER_ITEM:
			return false
	return true


func win_game() -> void:
	game_over = true
	spawn_timer.stop()
	message_label.text = "Great job!\nYou caught 5 of each item on the list!\nLet's go get some money!"
	message_panel.visible = true
	blocker.visible = true


func lose_game() -> void:
	game_over = true
	spawn_timer.stop()
	message_label.text = "Oh no!\nYou dropped the basket!\nLet's try that again..."
	message_panel.visible = true
	blocker.visible = true


func _on_spawn_timer_timeout() -> void:
	spawn_item()
	spawn_timer.wait_time = randf_range(0.7, 1.8)
	spawn_timer.start()


func _on_blocker_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if lives > 0:
			SceneTransition.fade_to("res://Scenes/market1.tscn")
		else:
			SceneTransition.fade_to_reload()
