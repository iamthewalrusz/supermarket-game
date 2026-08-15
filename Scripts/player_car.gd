extends CharacterBody2D

const SPEED = 400.0

# Limites Horizontais
@export var limit_left: float = 200.0
@export var limit_right: float = 940.0

# Limites Verticais (Ajuste esses valores de acordo com o tamanho da sua pista/tela)
@export var limit_top: float = 50.0
@export var limit_bottom: float = 650.0

@export var power_up = false

func _physics_process(_delta):
	# Lê as 4 direções e cria um Vector2 (que contém x e y)
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		# Se estiver apertando alguma tecla, aplica a velocidade nos dois eixos
		velocity = direction * SPEED
	else:
		# Se soltar as teclas, zera a velocidade em ambos os eixos
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()

	# Trava o carro nas bordas esquerda e direita
	position.x = clamp(position.x, limit_left, limit_right)
	# Trava o carro nas bordas superior e inferior
	position.y = clamp(position.y, limit_top, limit_bottom)
