extends ParallaxBackground

# Controla a velocidade que a pista se move (ajuste no Inspector!)
@export var scroll_speed: float = 200.0

func _process(delta):
	# Move o "tapete" inteiro no eixo Y (para baixo) constantemente
	scroll_offset.y += scroll_speed * delta
