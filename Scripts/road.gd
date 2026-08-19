extends Node2D

## Road scene: drive the car with WASD / arrow keys, stop near a building,
## and press Space to select it. Wrong choices show a short dialogue;
## the correct one leads into the market.

@onready var car: CharacterBody2D = $Car
@onready var car_sprite: Sprite2D = $Car/Sprite2D
@onready var message_label: Label = $MessageLabel
@onready var blocker: ColorRect = $Blocker

const CAR_SPEED: float = 350.0
const ROAD_LEFT: float = 60.0
const ROAD_RIGHT: float = 1090.0
const ROAD_TOP: float = 485.0
const ROAD_BOTTOM: float = 590.0

# Lines still waiting to be shown (queued).
var dialogue_queue: Array[String] = []
# Scene to load once the dialogue queue is exhausted ("" = none).
var pending_scene: String = ""
# Which building zone the car is currently inside ("" if none).
var current_zone: String = ""


func _ready() -> void:
	message_label.text = "Drive to the market and press Space!"
	blocker.hide()

	# Connect zone detection signals.
	$BankZone.body_entered.connect(_on_zone_entered.bind("bank"))
	$BankZone.body_exited.connect(_on_zone_exited.bind("bank"))
	$MarketZone.body_entered.connect(_on_zone_entered.bind("market"))
	$MarketZone.body_exited.connect(_on_zone_exited.bind("market"))
	$PetshopZone.body_entered.connect(_on_zone_entered.bind("petshop"))
	$PetshopZone.body_exited.connect(_on_zone_exited.bind("petshop"))


func _physics_process(_delta: float) -> void:
	# Freeze the car while a dialogue is on screen.
	if dialogue_queue.size() > 0 or blocker.visible:
		car.velocity = Vector2.ZERO
		car.move_and_slide()
		return

	var direction: Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1

	direction = direction.normalized()

	# Flip sprite to face the direction of horizontal movement.
	if direction.x < -0.1:
		car_sprite.flip_h = true
	elif direction.x > 0.1:
		car_sprite.flip_h = false

	car.velocity = direction * CAR_SPEED
	car.move_and_slide()

	# Keep the car within the road bounds.
	car.global_position.x = clampf(car.global_position.x, ROAD_LEFT, ROAD_RIGHT)
	car.global_position.y = clampf(car.global_position.y, ROAD_TOP, ROAD_BOTTOM)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return

	# If a dialogue is on screen, advance or dismiss it.
	if dialogue_queue.size() > 0:
		message_label.text = dialogue_queue.pop_front()
		return

	if blocker.visible:
		message_label.hide()
		blocker.hide()
		if pending_scene != "":
			SceneTransition.fade_to(pending_scene)
		else:
			message_label.text = "Drive to the market and press Space!"
		return

	# No dialogue active — try to interact with the current building.
	_try_interact()


func _on_zone_entered(body: Node2D, zone: String) -> void:
	if body == car:
		current_zone = zone


func _on_zone_exited(body: Node2D, zone: String) -> void:
	if body == car and current_zone == zone:
		current_zone = ""


func _try_interact() -> void:
	match current_zone:
		"bank":
			_queue_dialogue([
				"Oops, that is the bank.",
				"Let's try another place!",
			], "")
		"market":
			_queue_dialogue([
				"Yes! This is the supermarket!",
				"Let's go in and find everything on our list!",
			], "res://Scenes/falling_game.tscn")
		"petshop":
			_queue_dialogue([
				"Oops, that is the petshop.",
				"The market is somewhere else...",
			], "")


func _queue_dialogue(lines: Array[String], scene_path: String) -> void:
	dialogue_queue = lines.duplicate()
	pending_scene = scene_path
	_show_next_line()


func _show_next_line() -> void:
	message_label.show()
	blocker.show()
	message_label.text = dialogue_queue.pop_front()


func _on_message_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if dialogue_queue.size() > 0:
			message_label.text = dialogue_queue.pop_front()
			return

		if blocker.visible:
			message_label.hide()
			blocker.hide()
			if pending_scene != "":
				SceneTransition.fade_to(pending_scene)
			else:
				message_label.text = "Drive to the market and press Space!"
