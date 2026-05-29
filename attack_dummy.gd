extends CharacterBody3D

@onready var mesh = $MeshInstance3D

var health = 100
var original_material: Material = null

func take_damage(dmg):
	health -= dmg
	print("Dummy took damage: " + str(dmg))
	print("Dummy HP: " + str(health))
	flash_damage()
	if health <= 0:
		print("Dummy defeated")
		queue_free()
	
func flash_damage():
	var flash_material = original_material.duplicate()
	flash_material.albedo_color = Color.RED
	mesh.set_surface_override_material(0, flash_material)
	
	await get_tree().create_timer(0.1).timeout
	mesh.set_surface_override_material(0, original_material)
	
func _ready():
	original_material = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, original_material)
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
