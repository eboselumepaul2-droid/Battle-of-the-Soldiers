extends Node3D

const PLAYER_SCENE := preload("res://scenes/Player.tscn")
const BOT_SCENE := preload("res://scenes/Bot.tscn")
const JOYSTICK_SCRIPT := preload("res://scripts/joystick.gd")
const BUTTON_SCRIPT := preload("res://scripts/mobile_button.gd")

var player: CharacterBody3D
var hud: CanvasLayer
var health_label: Label
var score_label: Label
var message_label: Label
var kills := 0
var best_kills := 0
var best_path := "user://best_kills.save"

func _ready() -> void:
	_load_best()
	_build_world()
	_spawn_player()
	_spawn_bots()
	_build_hud()

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.36, 0.55)
	sky_mat.sky_horizon_color = Color(0.72, 0.78, 0.8)
	sky_mat.ground_bottom_color = Color(0.15, 0.18, 0.17)
	sky_mat.ground_horizon_color = Color(0.55, 0.58, 0.52)
	env.sky.sky_material = sky_mat
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.7, 0.78)
	env.ambient_light_energy = 0.8
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -25, 0)
	sun.light_energy = 1.1
	add_child(sun)
	_add_box("Ground", Vector3(0, -0.5, 0), Vector3(100, 1, 100), Color(0.24, 0.32, 0.24), true)
	# Cover blocks and simple buildings form a small training arena.
	_add_box("Warehouse", Vector3(-12, 2, -14), Vector3(12, 4, 8), Color(0.36, 0.4, 0.42), true)
	_add_box("Warehouse roof", Vector3(-12, 4.2, -14), Vector3(12.5, 0.5, 8.5), Color(0.22, 0.26, 0.28), true)
	_add_box("East building", Vector3(15, 2.5, -18), Vector3(9, 5, 10), Color(0.48, 0.43, 0.35), true)
	_add_box("West cover", Vector3(-20, 0.9, 5), Vector3(5, 1.8, 3), Color(0.38, 0.42, 0.38), true)
	_add_box("Center cover", Vector3(2, 0.8, -5), Vector3(5, 1.6, 2), Color(0.42, 0.43, 0.4), true)
	_add_box("South cover", Vector3(17, 0.8, 9), Vector3(3, 1.6, 6), Color(0.4, 0.43, 0.38), true)
	for i in range(8):
		var x := -32.0 + float(i) * 9.0
		_add_box("Barrier_%d" % i, Vector3(x, 0.65, 24), Vector3(4, 1.3, 1.3), Color(0.42, 0.39, 0.3), true)
	# Low-cost perimeter walls keep the action inside the arena.
	_add_box("North wall", Vector3(0, 1.5, -49), Vector3(100, 3, 1), Color(0.25, 0.29, 0.3), true)
	_add_box("South wall", Vector3(0, 1.5, 49), Vector3(100, 3, 1), Color(0.25, 0.29, 0.3), true)
	_add_box("East wall", Vector3(49, 1.5, 0), Vector3(1, 3, 100), Color(0.25, 0.29, 0.3), true)
	_add_box("West wall", Vector3(-49, 1.5, 0), Vector3(1, 3, 100), Color(0.25, 0.29, 0.3), true)

func _add_box(label: String, pos: Vector3, dimensions: Vector3, color: Color, solid: bool) -> void:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = label
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = dimensions
		collision.shape = shape
		body.add_child(collision)
	add_child(body)

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = Vector3(0, 0.1, 12)
	add_child(player)
	player.health_changed.connect(_on_health_changed)

func _spawn_bots() -> void:
	for i in range(6):
		var enemy := BOT_SCENE.instantiate()
		enemy.team = "enemy"
		enemy.position = Vector3(-22 + (i % 3) * 20, 0.1, -12 - int(i / 3) * 15)
		add_child(enemy)
	for i in range(2):
		var ally := BOT_SCENE.instantiate()
		ally.team = "ally"
		ally.position = Vector3(-3 + i * 6, 0.1, 16)
		add_child(ally)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var top := HBoxContainer.new()
	top.anchor_left = 0.02
	top.anchor_top = 0.02
	top.anchor_right = 0.98
	top.anchor_bottom = 0.12
	top.add_theme_constant_override("separation", 22)
	hud.add_child(top)
	health_label = _make_label("HEALTH 100", 24)
	score_label = _make_label("KILLS 0  |  BEST %d" % best_kills, 24)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(health_label)
	top.add_child(spacer)
	top.add_child(score_label)
	var joystick := Control.new()
	joystick.set_script(JOYSTICK_SCRIPT)
	joystick.anchor_left = 0.025
	joystick.anchor_top = 0.68
	joystick.anchor_right = 0.025
	joystick.anchor_bottom = 0.68
	joystick.position = Vector2(0, 0)
	joystick.custom_minimum_size = Vector2(170, 170)
	joystick.size = Vector2(170, 170)
	hud.add_child(joystick)
	_add_action_button("FIRE", "fire", Vector2(-150, -170), Color(0.72, 0.16, 0.12), 92)
	_add_action_button("JUMP", "jump", Vector2(-85, -275), Color(0.18, 0.4, 0.72), 68)
	_add_action_button("SPRINT", "sprint", Vector2(-245, -95), Color(0.2, 0.42, 0.3), 68)
	message_label = _make_label("TRAINING ARENA  •  ELIMINATE ENEMIES", 18)
	message_label.anchor_left = 0.25
	message_label.anchor_right = 0.75
	message_label.anchor_top = 0.88
	message_label.anchor_bottom = 0.98
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(message_label)

func _add_action_button(caption: String, action: String, offset: Vector2, color: Color, diameter: int) -> void:
	var button := Button.new()
	button.set_script(BUTTON_SCRIPT)
	button.action_name = action
	button.text = caption
	button.custom_minimum_size = Vector2(diameter, diameter)
	button.size = Vector2(diameter, diameter)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.position = offset
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.12)
	style.set_corner_radius_all(diameter / 2)
	style.set_border_width_all(2)
	style.border_color = Color(1, 1, 1, 0.7)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("pressed", style)
	hud.add_child(button)

func _make_label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _on_health_changed(value: int) -> void:
	if is_instance_valid(health_label):
		health_label.text = "HEALTH %d" % value

func register_kill() -> void:
	kills += 1
	best_kills = maxi(best_kills, kills)
	if is_instance_valid(score_label):
		score_label.text = "KILLS %d  |  BEST %d" % [kills, best_kills]
	_save_best()

func _load_best() -> void:
	if FileAccess.file_exists(best_path):
		var file := FileAccess.open(best_path, FileAccess.READ)
		if file:
			best_kills = int(file.get_as_text())

func _save_best() -> void:
	var file := FileAccess.open(best_path, FileAccess.WRITE)
	if file:
		file.store_string(str(best_kills))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
