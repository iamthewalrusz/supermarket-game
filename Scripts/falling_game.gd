class_name FallingGame
extends Node2D

# All products the game can draw from. Each playthrough, 3 are randomly picked
# as targets (each with a random required count 2-5); the rest are distractors.
const PRODUCT_POOL: Array[Dictionary] = [
	{"name": "Apple", "texture": "res://Assets/apple-fruit-cartoon-transparent-28.png", "color": "ff4444"},
	{"name": "Milk", "texture": "res://Assets/milk-box-3d-rendering-isometric-icon-png.png", "color": "ffffff"},
	{"name": "Eggs", "texture": "res://Assets/1536745806-clipart-xl.png", "color": "ffddaa"},
	{"name": "Steak", "texture": "res://Assets/steak-graphic-clipart-design-free-png.png", "color": "ff6666"},
	{"name": "Banana", "texture": "res://Assets/banana.png", "color": "ffff66"},
	{"name": "Bread", "texture": "res://Assets/bread.png", "color": "cc9966"},
	{"name": "Cheese", "texture": "res://Assets/cheese.png", "color": "ffaa00"},
	{"name": "Fish", "texture": "res://Assets/fish.png", "color": "66ccff"},
]

const NUM_TARGETS: int = 3
const MIN_NEEDED: int = 2
const MAX_NEEDED: int = 5

const STARTING_LIVES: int = 3

var target_items: Array[Dictionary] = []
var distractor_items: Array[Dictionary] = []
var needed_per_item: Dictionary = {}

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
	# Pick 3 random products to be this playthrough's targets.
	var pool: Array[Dictionary] = PRODUCT_POOL.duplicate()
	pool.shuffle()
	target_items = pool.slice(0, NUM_TARGETS)
	distractor_items = pool.slice(NUM_TARGETS)

	# Give each target a random required count (2-5).
	for item: Dictionary in target_items:
		needed_per_item[item["name"]] = randi_range(MIN_NEEDED, MAX_NEEDED)
		collected_counts[item["name"]] = 0

	update_ui()
	spawn_timer.start()
	blocker.visible = false
	message_panel.visible = false

	# Record the items the player must find so the market platformer knows them.
	GameState.required_items = []
	for item: Dictionary in target_items:
		GameState.required_items.append(item["name"])

	target_list_label.text = build_target_list_text()


func build_target_list_text() -> String:
	var parts: Array[String] = []
	for item: Dictionary in target_items:
		parts.append("%s x%d" % [item["name"], int(needed_per_item[item["name"]])])
	return "Find: " + ", ".join(parts)


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

	var item_data: Dictionary
	var is_target: bool
	if spawn_target:
		item_data = target_items[randi() % target_items.size()]
		is_target = true
	else:
		item_data = distractor_items[randi() % distractor_items.size()]
		is_target = false

	var color: Color = Color.from_string(item_data["color"], Color.WHITE)
	item.setup(item_data["name"], is_target, load(item_data["texture"]), color)

	item.position.x = randf_range(120, 1030)
	item.position.y = -60
	item.fall_speed = randf_range(160, 320)
	item.collected.connect(_on_item_collected)

	add_child(item)


func _on_item_collected(item_name: String, is_target: bool) -> void:
	if game_over:
		return

	if is_target:
		if int(collected_counts[item_name]) < int(needed_per_item[item_name]):
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
	for item: Dictionary in target_items:
		var count: int = int(collected_counts[item["name"]])
		var needed: int = int(needed_per_item[item["name"]])
		collected_parts.append("%s %d/%d" % [item["name"], count, needed])
	collected_list_label.text = "Collected: " + ", ".join(collected_parts)


func _all_collected() -> bool:
	for item: Dictionary in target_items:
		if int(collected_counts[item["name"]]) < int(needed_per_item[item["name"]]):
			return false
	return true


func win_game() -> void:
	game_over = true
	spawn_timer.stop()
	message_label.text = "Great job!\nYou caught everything on the list!\nLet's go get some money!"
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
