extends Node2D

var road_item = preload("res://Scenes/road_item.tscn")
var road_obstacle = preload("res://Scenes/road_obstacle.tscn")
var road_power_up = preload("res://Scenes/road_power_up.tscn")

var score: float = 0.0
const WIN_SCORE: float = 250.0
var game_ended: bool = false

@onready var timer = $Timer
@onready var timer_obstacle = $TimerObstacle
@onready var timer_power_up = $TimerPowerUp
@onready var timer_power_up_status = $TimerPowerUpStatus
@onready var power_up_bar = $UI/PowerUpBar
@onready var player_car = $PlayerCar
@onready var score_label = $UI/Label 
@export var road_left: float = 200.0
@export var road_right: float = 940.0

var speed_increase_rate: float = 0.01  # How much to add per second
var max_time_scale: float = 3.0       # Cap the speed to keep it playable

func _ready() -> void:
	Engine.time_scale = 1.0
	power_up_bar.visible = false
	

func _process(delta: float) -> void:
	if game_ended:
		return
		
	if Engine.time_scale < max_time_scale:
		# Increase time_scale based on real-world time (delta)
		Engine.time_scale += speed_increase_rate * delta
		
	score += 1.0 * delta
	score_label.text = "Score: " + str(int(score)) + " / " + str(int(WIN_SCORE))
	
	if score >= WIN_SCORE:
		_win_game()
		return
	
	# Se o timer estiver rodando, precisamos atualizar a barra visualmente
	if not timer_power_up_status.is_stopped():
		# Descobre a porcentagem de tempo que resta (de 0.0 a 1.0)
		var time_left_ratio = timer_power_up_status.time_left / timer_power_up_status.wait_time
		
		# Converte para a escala da barra (0 a 100)
		power_up_bar.value = time_left_ratio * 100

func _on_timer_timeout():
	timer.wait_time = randf_range(1.0, 2.0)
	
	var new_item = road_item.instantiate()
	
	var random_x = randf_range(road_left + 20, road_right - 20)
	
	new_item.position = Vector2(random_x, -50)
	new_item.collected.connect(_on_item_collected)
	add_child(new_item)

func _on_timer_obstacle_timeout() -> void:
	timer_obstacle.wait_time = randf_range(1.0, 2.0)
	var new_obstacle = road_obstacle.instantiate()
	
	var random_x = randf_range(road_left + 20, road_right - 20)
	
	new_obstacle.position = Vector2(random_x, -50)
	new_obstacle.hit.connect(_on_obstacle_hit)
	add_child(new_obstacle)
	
func _on_timer_power_up_timeout() -> void:
	timer_power_up.wait_time = randf_range(30.0, 45.0)
	var new_power_up = road_power_up.instantiate()
	
	var random_x = randf_range(road_left + 20, road_right - 20)
	
	new_power_up.position = Vector2(random_x, -50)
	new_power_up.power.connect(_on_power)
	add_child(new_power_up)

func _on_item_collected(points_received):
	score += points_received 
	score_label.text = "Score: " + str(score)

func _on_obstacle_hit() -> void:
	if game_ended:
		return
	if player_car.power_up:
		pass
	else:
		SceneTransition.fade_to_reload()

func _on_power():
	player_car.power_up = true
	
	# Torna a barra visível e reseta o valor dela para o máximo (100)
	power_up_bar.visible = true
	power_up_bar.value = 100
	
	timer_power_up_status.start()
	
	player_car.modulate = Color(1.5, 1.5, 0.5)

func _on_timer_power_up_status_timeout() -> void:
	player_car.power_up = false
	power_up_bar.visible = false
	player_car.modulate = Color.WHITE

func _win_game() -> void:
	game_ended = true
	timer.stop()
	timer_obstacle.stop()
	timer_power_up.stop()
	score_label.text = "You arrived! Score: " + str(int(score))
	# Brief pause so the player sees the win, then transition
	await get_tree().create_timer(1.5).timeout
	Engine.time_scale = 1.0
	SceneTransition.fade_to("res://Scenes/road.tscn")
