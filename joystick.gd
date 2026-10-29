extends Control

var finger_id := -1
var center := Vector2.ZERO
var knob := Vector2.ZERO
var radius := 68.0
var output := Vector2.ZERO

func _ready() -> void:
	custom_minimum_size = Vector2(170, 170)
	center = size / 2.0
	knob = center
	mouse_filter = Control.MOUSE_FILTER_STOP

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		center = size / 2.0
		if finger_id == -1:
			knob = center

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger_id == -1:
			finger_id = event.index
			_update_knob(event.position)
		elif not event.pressed and event.index == finger_id:
			finger_id = -1
			output = Vector2.ZERO
			knob = center
			_update_actions()
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == finger_id:
		_update_knob(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			finger_id = 999
			_update_knob(event.position)
		else:
			finger_id = -1
			output = Vector2.ZERO
			knob = center
			_update_actions()
			queue_redraw()
	elif event is InputEventMouseMotion and finger_id == 999:
		_update_knob(event.position)

func _update_knob(pos: Vector2) -> void:
	var offset := pos - center
	if offset.length() > radius:
		offset = offset.normalized() * radius
	knob = center + offset
	output = Vector2(offset.x / radius, offset.y / radius)
	_update_actions()
	queue_redraw()

func _update_actions() -> void:
	_set_action("move_left", output.x < -0.18)
	_set_action("move_right", output.x > 0.18)
	_set_action("move_forward", output.y < -0.18)
	_set_action("move_back", output.y > 0.18)
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.joystick_vector = output

func _set_action(action: String, active: bool) -> void:
	if active and not Input.is_action_pressed(action):
		Input.action_press(action)
	elif not active and Input.is_action_pressed(action):
		Input.action_release(action)

func _draw() -> void:
	draw_circle(center, radius, Color(0.04, 0.06, 0.08, 0.45))
	draw_arc(center, radius, 0, TAU, 48, Color(0.8, 0.9, 1, 0.65), 3.0, true)
	draw_circle(knob, 29.0, Color(0.72, 0.82, 0.9, 0.75))
	draw_arc(knob, 29.0, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0, true)
