extends CharacterBody3D

@onready var mesh = $MeshInstance3D
@onready var attack_hitbox = $AttackBox

const PARRY_WINDOW = 0.4
const ATTACK_DMG = 5.0
const PARRY_RANGE = 2.0
var parried = false


var ATTACK_TIMER = 0.3
var current_attack_state = EnemyAttackState.IDLE
var original_material: Material = null

enum EnemyAttackState{
	IDLE,
	WINDUP,
	PARRYABLE,
	ACTIVE,
	RECOVERY
}
func parry_active_visual():
	print("Green!")
	var flash_material = original_material.duplicate()
	flash_material.albedo_color = Color.GREEN
	mesh.set_surface_override_material(0, flash_material)
	
func parry_deactive_visual():
	print("Not green!")
	mesh.set_surface_override_material(0, original_material)
	

func handle_enemy_attack_state(delta):
	match current_attack_state:
		EnemyAttackState.WINDUP:
			if ATTACK_TIMER <= 0:
				ATTACK_TIMER = PARRY_WINDOW
				parry_active_visual()
				print("Parry window open")
				current_attack_state = EnemyAttackState.PARRYABLE
			else:
				ATTACK_TIMER -= delta
		EnemyAttackState.PARRYABLE:
			if ATTACK_TIMER <= 0:
				parry_deactive_visual()
				print("Parry window closed")
				ATTACK_TIMER = 0.2
				if !parried:
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
				parried = false
			else:
				ATTACK_TIMER -= delta	
		EnemyAttackState.IDLE:
			if ATTACK_TIMER <= 0:
				ATTACK_TIMER = PARRY_WINDOW
				current_attack_state = EnemyAttackState.WINDUP
			else:
				ATTACK_TIMER -= delta	

func try_parry(player):
	if parried:
		return
		
	if current_attack_state == EnemyAttackState.PARRYABLE:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player <= PARRY_RANGE:
			get_parried()

func get_parried():
	parried = true
	print("Player deflected attack!")
				
func _ready():
	original_material = mesh.get_active_material(0).duplicate()
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	handle_enemy_attack_state(delta)
	move_and_slide()
