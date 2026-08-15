extends Node
## Autoload singleton that provides smooth fade transitions between scenes.
##
## Usage (from any script):
##     SceneTransition.fade_to("res://Scenes/intro.tscn")
##     SceneTransition.fade_to_reload()

const FADE_DURATION: float = 0.6
const FADE_COLOR: Color = Color.BLACK

var _fade_rect: ColorRect
var _transitioning: bool = false


func _ready() -> void:
	# Keep the fade layer above everything, even full-screen UIs.
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = FADE_COLOR
	_fade_rect.modulate = Color(1, 1, 1, 0)  # Start fully transparent.
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.offset_left = 0
	_fade_rect.offset_top = 0
	_fade_rect.offset_right = 0
	_fade_rect.offset_bottom = 0
	layer.add_child(_fade_rect)

	# Make sure the rect repaints itself when the viewport resizes.
	_fade_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fade_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL


## Fade to black, switch to [param scene_path], then fade back in.
func fade_to(scene_path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_out()
	get_tree().change_scene_to_file(scene_path)
	await _fade_in()
	_transitioning = false


## Fade to black, reload the current scene, then fade back in.
func fade_to_reload() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_out()
	get_tree().reload_current_scene()
	await _fade_in()
	_transitioning = false


## Fade to black without changing scene, then fade back in.
## Useful to restore a scene after a scripted overlay.
func fade_back_in() -> void:
	if _transitioning:
		return
	_transitioning = true
	await _fade_out()
	await _fade_in()
	_transitioning = false


func _fade_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished


func _fade_in() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
