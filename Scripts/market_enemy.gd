class_name MarketEnemy
extends CharacterBody2D

## Simple patrolling enemy that damages the player on contact.

const SPEED: float = 90.0
const GRAVITY: float = 1600.0
const DAMAGE: int = 1

@export var patrol_min_x: float = 0.0
@export var patrol_max_x: float = 0.0

var direction: float = 1.0

var _hitbox: Area2D


func _ready() -> void:
	# Default patrol range centered on spawn if not configured.
	if patrol_max_x <= patrol_min_x:
		patrol_min_x = position.x - 100.0
		patrol_max_x = position.x + 100.0

	_hitbox = get_node_or_null("Hitbox") as Area2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = direction * SPEED
	move_and_slide()

	if position.x <= patrol_min_x:
		direction = 1.0
	elif position.x >= patrol_max_x:
		direction = -1.0

	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.flip_h = direction < 0.0

	# Continuously damage the player on contact, regardless of which way the
	# enemy is moving. The player's invulnerability window (1s) prevents
	# damage from spamming every frame while touching.
	_check_contact()


func _check_contact() -> void:
	if _hitbox == null:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body is MarketPlayer:
			(body as MarketPlayer).take_damage(DAMAGE)
