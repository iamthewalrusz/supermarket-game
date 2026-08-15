extends ColorRect

@onready var label1 = $Label1
@onready var label2 = $Label2
@onready var label3 = $Label3
@onready var sound_effect = $"../SoundEffect"
var labels = []

func _ready() -> void:
	labels = [label1, label2, label3]
	for label in labels:
		label.get_node("Checkmark").hide()
	sound_effect.stream = preload("res://Assets/Audio/Sound Effects/check-mark.mp3")

# Verifica se pode receber
func _can_drop_data(_at_position, data):
	# Agora verificamos se o tipo de dado é um Dicionário (TYPE_DICTIONARY)
	if typeof(data) == TYPE_DICTIONARY and data.has("name"):
		return true
	else:
		return false

# Quando o mouse é solto
func _drop_data(_at_position, data):
	if data["name"] == "Steak":
		pass
	else:
		print("Você colocou na lista: ", data["name"])
		
		for label in labels:
			if label.text == "":
				label.text = data["name"]
				label.get_node("Checkmark").show()
				sound_effect.play()
				break
		
		# Fazemos a maçã original sumir da prateleira!
		data["node"].queue_free()
	
