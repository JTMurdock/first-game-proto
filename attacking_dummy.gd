extends CharacterBody3D

@onready var mesh = $MeshInstance3D
@onready var attack_hitbox = $AttackBox

const PARRY_WINDOW = 0.4
const ATTACK_DMG = 5


var ATTACK_TIMER = 0.3
var current_attack_state = EnemyAttackState.IDLE
var original_material: Material = null

enum EnemyAttackState{
	IDLE,
	WINDUP,
	ACTIVE,
	RECOVERY
}
func parry_window(delta):
	var flash_material = original_material.duplicate()
	flash_material.albedo_color = Color.GREEN
	mesh.set_surface_override_material(0, flash_material)
	
	await get_tree().create_timer(PARRY_WINDOW).timeout
	mesh.set_surface_override_material(0, original_material)
	

func handle_enemy_attack_state(delta):
	match current_attack_state:
		EnemyAttackState.WINDUP:
			if ATTACK_TIMER <= 0:
				ATTACK_TIMER = 0.2
				parry_window(delta)
				attack_hitbox.activate()
				current_attack_state = EnemyAttackState.ACTIVE
			else:
				ATTACK_TIMER -= delta
		EnemyAttackState.ACTIVE:
			if ATTACK_TIMER <= 0:
				ATTACK_TIMER = 0.2
				attack_hitbox.deactivate()
				current_attack_state = EnemyAttackState.RECOVERY
			else:
				ATTACK_TIMER -= delta
		EnemyAttackState.RECOVERY:
			if ATTACK_TIMER <= 0:
				current_attack_state = EnemyAttackState.IDLE
			else:
				ATTACK_TIMER -= delta	
		EnemyAttackState.IDLE:
			if ATTACK_TIMER <= 0:
				ATTACK_TIMER = PARRY_WINDOW
				current_attack_state = EnemyAttackState.WINDUP
			else:
				ATTACK_TIMER -= delta	
				
func _ready():
	original_material = mesh.get_active_material(0).duplicate()
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	handle_enemy_attack_state(delta)
	move_and_slide()
