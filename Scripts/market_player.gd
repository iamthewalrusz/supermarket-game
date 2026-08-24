class_name MarketPlayer
extends CharacterBody2D

signal health_changed(health: int)
signal player_died

const SPEED: float = 260.0
const JUMP_VELOCITY: float = -680.0
const GRAVITY: float = 1600.0

const MAX_HEALTH: int = 5
const INVULNERABLE_TIME: float = 1.0

var health: int = MAX_HEALTH
var invulnerable: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction: float = Input.get_axis("ui_left", "ui_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
		if anim:
			anim.play("walking")
			anim.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		if anim:
			anim.play("standing")

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	move_and_slide()


## Reduces the player's health, applying brief invulnerability afterwards.
func take_damage(amount: int) -> void:
	if invulnerable or health <= 0:
		return
	health = max(health - amount, 0)
	health_changed.emit(health)
	_start_invulnerability()
	if health <= 0:
		player_died.emit()


func _start_invulnerability() -> void:
	invulnerable = true
	var tween := create_tween()
	for i in range(5):
		tween.tween_property(self, "modulate:a", 0.3, 0.09)
		tween.tween_property(self, "modulate:a", 1.0, 0.09)
	tween.tween_callback(_end_invulnerability)


func _end_invulnerability() -> void:
	invulnerable = false
	modulate = Color.WHITE
