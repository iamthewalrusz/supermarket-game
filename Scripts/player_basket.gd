class_name PlayerBasket
extends CharacterBody2D

const SPEED: float = 450.0

var limit_left: float = 80.0
var limit_right: float = 1070.0
var limit_bottom: float = 620.0


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED
	move_and_slide()

	position.x = clamp(position.x, limit_left, limit_right)
	position.y = clamp(position.y, 500, limit_bottom)
