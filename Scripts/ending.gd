extends Node2D

@onready var message_label: Label = $MessageLabel
@onready var name_label: Label = $MessageLabel/NameLabel

# Each line is [speaker, text].
const DIALOGUE: Array = [
	["Sarah", "Mom and dad, we're done!"],
	["Rachel", "Yes, honey! We got all that we needed!"],
	["Rachel", "Let's go! I'll drive us back home!"],
]

var dialogue_index: int = 0


func _ready() -> void:
	_show_line()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_advance()


func _show_line() -> void:
	var line: Array = DIALOGUE[dialogue_index]
	name_label.text = line[0]
	message_label.text = line[1]


func _advance() -> void:
	dialogue_index += 1
	if dialogue_index < DIALOGUE.size():
		_show_line()
	else:
		SceneTransition.fade_to("res://Scenes/menu.tscn")


func _on_message_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance()
