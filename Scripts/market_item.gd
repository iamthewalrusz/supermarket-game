class_name MarketItem
extends Area2D

signal collected(amount: int)

var amount: int = 1
var was_collected: bool = false


const TARGET_RENDER_AREA: float = 1600.0  # ~40x40 px


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Only detect the player, which lives on collision layer 2.
	collision_mask = 2

	# Normalize the sprite so every pickup occupies the same on-screen area,
	# keeping each image's aspect ratio intact.
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		var tex_size: Vector2 = sprite.texture.get_size()
		var uniform_scale: float = sqrt(TARGET_RENDER_AREA / (tex_size.x * tex_size.y))
		sprite.scale = Vector2(uniform_scale, uniform_scale)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not was_collected:
		was_collected = true
		collected.emit(amount)
		queue_free()
