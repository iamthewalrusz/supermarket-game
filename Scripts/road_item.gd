extends Area2D

# 1. Criamos o nosso próprio sinal que avisa quantos pontos o item vale
signal collected(points)

const FALL_SPEED = 200.0

func _process(delta):
	position.y += FALL_SPEED * delta

func _on_body_entered(body):
	if body.name == "PlayerCar":
		# print("Good job! You got an item for the market!")
		
		# 2. Emitimos o sinal enviando 10 pontos como recompensa
		collected.emit(10) 
		
		# Deleta o item da tela
		queue_free()
