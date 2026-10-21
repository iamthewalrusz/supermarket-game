class_name MazePlayer
extends CharacterBody2D
## Top-down player for the maze: walks the supermarket aisles and stops at walls.

const SPEED: float = 155.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * SPEED

	if direction != Vector2.ZERO:
		anim.play("walking")
		if absf(direction.x) > 0.01:
			anim.flip_h = direction.x < 0.0
	else:
		anim.play("standing")

	move_and_slide()
