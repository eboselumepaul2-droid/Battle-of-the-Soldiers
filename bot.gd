extends CharacterBody3D

@export var team := "enemy"
@export var move_speed := 2.8
@export var max_health := 100
var health := 100
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var attack_timer := 0.0
var respawn_timer := 0.0
var target: Node3D
var home_position := Vector3.ZERO

@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var collision: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.7
	collision.shape = capsule
	collision.position.y = 0.85
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.36
	mesh.height = 1.7
	body_mesh.mesh = mesh
	body_mesh.position.y = 0.85
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.2, 0.16) if team == "enemy" else Color(0.2, 0.68, 0.36)
	mat.roughness = 0.9
	body_mesh.material_override = mat
	health = max_health
	home_position = global_position
	add_to_group("bots")

func _physics_process(delta: float) -> void:
	if respawn_timer > 0.0:
		respawn_timer -= delta
		if respawn_timer <= 0.0:
			_respawn()
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if team == "enemy":
		target = player
	else:
		target = _nearest_enemy()
	if is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		var flat := target.global_position - global_position
		flat.y = 0
		if distance > (10.0 if team == "enemy" else 14.0):
			var direction := flat.normalized()
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			if direction.length() > 0.1:
				rotation.y = atan2(-direction.x, -direction.z)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if attack_timer <= 0.0:
				attack_timer = 1.0 if team == "enemy" else 0.85
				if team == "enemy" and target.has_method("take_damage"):
					target.take_damage(8, self)
				elif team == "ally" and target.has_method("take_damage"):
					target.take_damage(18, self)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
	move_and_slide()

func _nearest_enemy() -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for bot in get_tree().get_nodes_in_group("bots"):
		if bot == self or not is_instance_valid(bot):
			continue
		if bot.get("team") != "enemy" or bot.get("respawn_timer") > 0.0:
			continue
		var distance := global_position.distance_to(bot.global_position)
		if distance < best_distance:
			best_distance = distance
			best = bot as Node3D
	return best

func take_damage(amount: int, source: Node = null) -> void:
	if respawn_timer > 0.0:
		return
	health -= amount
	if health <= 0:
		if team == "enemy":
			var main := get_tree().current_scene
			if main.has_method("register_kill"):
				main.register_kill()
		respawn_timer = 3.0 if team == "enemy" else 5.0
		visible = false
		collision_layer = 0
		collision_mask = 0

func _respawn() -> void:
	health = max_health
	global_position = home_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	visible = true
	collision_layer = 1
	collision_mask = 1
