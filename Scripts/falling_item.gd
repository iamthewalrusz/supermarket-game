class_name FallingItem
extends Area2D

signal collected(item_name: String, is_target: bool)

var item_name: String = ""
var is_target: bool = false
var fall_speed: float = 200.0
var was_collected: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label


func _ready() -> void:
	label.text = item_name
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta

	if position.y > 750:
		queue_free()


const TARGET_RENDER_AREA: float = 64.0 * 64.0


func setup(name_str: String, target: bool, texture: Texture2D, color: Color) -> void:
	item_name = name_str
	is_target = target
	if not sprite:
		sprite = $Sprite2D
	if not label:
		label = $Label
	sprite.texture = texture
	sprite.modulate = color
	label.text = item_name

	# Normalize so every item occupies the same on-screen area (64x64 px),
	# while keeping each image's aspect ratio intact.
	var tex_size: Vector2 = texture.get_size()
	var uniform_scale: float = sqrt(TARGET_RENDER_AREA / (tex_size.x * tex_size.y))
	sprite.scale = Vector2(uniform_scale, uniform_scale)


func _on_body_entered(_body: Node2D) -> void:
	_do_collect()


func _on_area_entered(_area: Area2D) -> void:
	_do_collect()


func _do_collect() -> void:
	if was_collected:
		return
	was_collected = true
	collected.emit(item_name, is_target)
	queue_free()
