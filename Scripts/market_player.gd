class_name MarketPlayer
extends CharacterBody2D

const SPEED: float = 320.0
const JUMP_VELOCITY: float = -680.0
const GRAVITY: float = 1600.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction: float = Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()