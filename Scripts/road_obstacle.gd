extends Area2D

signal hit

const FALL_SPEED = 200.0

func _process(delta):
	position.y += FALL_SPEED * delta

func _on_body_entered(body):
	if body.name == "PlayerCar":
		hit.emit()
		
	queue_free()
