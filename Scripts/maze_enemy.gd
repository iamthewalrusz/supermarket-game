class_name MazeEnemy
extends CharacterBody2D
## Top-down maze guard that patrols a corridor and, on contact with the player,
## signals that the run is over so the maze can restart from the beginning.
##
## On spawn it works out whether its corridor runs left-right or up-down (by
## probing for walls with a ray) and patrols along that axis, so it never gets
## stuck vibrating in a one-tile gap. A guard with no room at all stays put.
## Place instances anywhere in the maze; the rest is automatic, though the
## optional patrol bounds below clamp the route further.

## Emitted when this guard touches the player. MazeGame listens for it and
## restarts the maze.
signal player_caught

enum Axis { NONE, HORIZONTAL, VERTICAL }

const SPEED: float = 90.0
## Collision layer the maze walls live on, used for the direction probe.
const WALL_MASK: int = 1
## How far (px) the probe ray reaches to see if a side is open.
const PROBE_DISTANCE: float = 20.0

@export var patrol_min_x: float = 0.0
@export var patrol_max_x: float = 0.0
@export var patrol_min_y: float = 0.0
@export var patrol_max_y: float = 0.0

var direction: float = 1.0

var _axis: Axis = Axis.NONE

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	# Default patrol range centred on spawn when not explicitly configured.
	if patrol_max_x <= patrol_min_x:
		patrol_min_x = position.x - 100.0
		patrol_max_x = position.x + 100.0
	if patrol_max_y <= patrol_min_y:
		patrol_min_y = position.y - 100.0
		patrol_max_y = position.y + 100.0

	hitbox.body_entered.connect(_on_hitbox_body_entered)

	# The walls aren't registered in the physics space during _ready(), so wait
	# a couple of physics frames before probing for the patrol axis.
	_choose_axis_when_ready()


func _choose_axis_when_ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if is_inside_tree():
		_choose_axis()


## Picks the axis with room to walk: prefer horizontal, fall back to vertical,
## and stand still if boxed in on all four sides.
func _choose_axis() -> void:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var horizontal_open: bool = not _is_blocked(space, Vector2.RIGHT) or not _is_blocked(space, Vector2.LEFT)
	var vertical_open: bool = not _is_blocked(space, Vector2.DOWN) or not _is_blocked(space, Vector2.UP)

	if horizontal_open:
		_axis = Axis.HORIZONTAL
	elif vertical_open:
		_axis = Axis.VERTICAL
	else:
		_axis = Axis.NONE


func _is_blocked(space: PhysicsDirectSpaceState2D, dir: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position, global_position + dir * PROBE_DISTANCE, WALL_MASK, [get_rid()]
	)
	return not space.intersect_ray(query).is_empty()


func _physics_process(_delta: float) -> void:
	if _axis == Axis.NONE:
		velocity = Vector2.ZERO
		return

	var step: Vector2 = Vector2.RIGHT if _axis == Axis.HORIZONTAL else Vector2.DOWN
	velocity = step * direction * SPEED
	move_and_slide()

	# Reverse at the patrolled bounds or against any wall in the way.
	if is_on_wall():
		direction = -direction

	if _axis == Axis.HORIZONTAL:
		if position.x <= patrol_min_x:
			direction = 1.0
		elif position.x >= patrol_max_x:
			direction = -1.0
		sprite.flip_h = direction < 0.0
	else:
		if position.y <= patrol_min_y:
			direction = 1.0
		elif position.y >= patrol_max_y:
			direction = -1.0


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is MazePlayer:
		player_caught.emit()