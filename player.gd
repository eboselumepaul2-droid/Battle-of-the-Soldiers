extends CharacterBody3D

signal health_changed(value: int)
signal fired

@export var move_speed := 5.2
@export var sprint_speed := 7.8
@export var jump_velocity := 5.0
@export var max_health := 100
var health := 100
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var fire_cooldown := 0.0
var is_sprinting := false
var joystick_vector := Vector2.ZERO
var touch_look_delta := Vector2.ZERO

@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

func _ready() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.38
	mesh.height = 1.8
	body_mesh.mesh = mesh
	body_mesh.position.y = 0.9
	body_mesh.material_override = _material(Color(0.16, 0.42, 0.75))
	health = max_health
	add_to_group("player")

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	var move_input := joystick_vector
	if move_input.length() < 0.05:
		move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	var cam_basis := camera.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0
	right = right.normalized()
	var direction := (right * move_input.x + forward * -move_input.y).normalized()
	is_sprinting = Input.is_action_pressed("sprint")
	var speed := sprint_speed if is_sprinting else move_speed
	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 9.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
	move_and_slide()
	if Input.is_action_pressed("fire"):
		shoot()

func shoot() -> void:
	if fire_cooldown > 0.0:
		return
	fire_cooldown = 0.22
	fired.emit()
	var origin := camera.global_position
	var end := origin + (-camera.global_transform.basis.z * 90.0)
	var query := PhysicsRayQueryParameters3D.create(origin, end)
	query.exclude = [get_rid()]
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target: Object = hit.get("collider")
		if target != null and target.has_method("take_damage"):
			target.take_damage(34, self)

func take_damage(amount: int, _source: Node = null) -> void:
	health = maxi(0, health - amount)
	health_changed.emit(health)
	if health <= 0:
		health = max_health
		global_position = Vector3(0, 1.2, 0)
		health_changed.emit(health)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	return mat
