extends Node2D

## Road scene: the player picks the correct building.
## Wrong choices show a short dialogue; the correct one leads into the market.

@onready var message_label: Label = $MessageLabel
@onready var blocker: ColorRect = $Blocker

# Lines still waiting to be shown (queued).
var dialogue_queue: Array[String] = []
# Scene to load once the dialogue queue is exhausted ("" = none).
var pending_scene: String = ""


func _ready() -> void:
	message_label.text = "Where is the market?"


func _queue_dialogue(lines: Array[String], scene_path: String) -> void:
	dialogue_queue = lines.duplicate()
	pending_scene = scene_path
	_show_next_line()


func _show_next_line() -> void:
	message_label.show()
	blocker.show()
	message_label.text = dialogue_queue.pop_front()


func _on_bank_button_pressed() -> void:
	_queue_dialogue([
		"Oops, that is the bank.",
		"Let's try another place!",
	], "")


func _on_market_button_pressed() -> void:
	_queue_dialogue([
		"Yes! This is the supermarket!",
		"Let's go in and find everything on our list!",
	], "res://Scenes/falling_game.tscn")


func _on_petshop_button_pressed() -> void:
	_queue_dialogue([
		"Oops, that is the petshop.",
		"The market is somewhere else...",
	], "")


func _on_message_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if dialogue_queue.is_empty():
			message_label.hide()
			blocker.hide()
			if pending_scene != "":
				SceneTransition.fade_to(pending_scene)
		else:
			message_label.text = dialogue_queue.pop_front()
