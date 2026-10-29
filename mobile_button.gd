extends Button

@export var action_name := "fire"

func _ready() -> void:
	button_down.connect(func(): Input.action_press(action_name))
	button_up.connect(func(): Input.action_release(action_name))
	focus_mode = Control.FOCUS_NONE
