class_name MarketItem
extends Area2D

signal picked_up(item_name: String)

var item_name: String = ""
var collected: bool = false


const TARGET_RENDER_AREA: float = 1600.0  # ~40x40 px


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Derive the item name from the node name when not set explicitly
	# (e.g. "ItemApple" -> "Apple").
	if item_name.is_empty():
		var node_name: String = name
		if node_name.begins_with("Item"):
			item_name = node_name.trim_prefix("Item")
		else:
			item_name = node_name

	# Normalize the sprite so every item occupies the same on-screen area,
	# keeping each image's aspect ratio intact.
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		var tex_size: Vector2 = sprite.texture.get_size()
		var uniform_scale: float = sqrt(TARGET_RENDER_AREA / (tex_size.x * tex_size.y))
		sprite.scale = Vector2(uniform_scale, uniform_scale)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not collected:
		collected = true
		picked_up.emit(item_name)
		queue_free()