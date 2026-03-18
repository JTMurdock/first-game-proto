extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.002
const SPEED = 5.0
const JUMP_FORCE = 8.0
const GRAVITY = 20.0
const DASH_SPEED = 20.0
const DASH_DURATION = 0.12
const DASH_COOLDOWN = 0.5
var dash_timer = 0.0
var dash_cooldown_left = 0.0
var dash_direction = Vector3.ZERO

func get_input_direction(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_backwards"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	var direction = Vector3.ZERO
	
	if input_dir != Vector3.ZERO:
		var forward = transform.basis.z
		var right = transform.basis.x
		direction = (right * input_dir.x + forward * input_dir.z).normalized()
		
		return direction

enum PlayerState{
	IDLE,
	MOVE,
	JUMP,
	ATTACK,
	FALL,
	DASH,
}

@onready var pivot = $"Pivot (Node3D)"

var current_movement_state = PlayerState.IDLE

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-40), deg_to_rad(60) )

func handle_movement_state(delta):
	var direction = get_input_direction(delta)
	match current_movement_state:
		PlayerState.IDLE:
			handle_idle_state(delta)
		PlayerState.MOVE:
			handle_move_state(delta, direction)
		PlayerState.JUMP:
			handle_jump_state(delta)
		PlayerState.FALL:
			handle_fall_state(delta)
		PlayerState.DASH:
			handle_dash_state(delta, direction)

func handle_idle_state(delta):
	if Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backwards") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
		current_movement_state = PlayerState.MOVE
	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0:
		current_movement_state = PlayerState.DASH

func handle_move_state(delta, direction):
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
func handle_dash_state(delta):
	dash_timer = DASH_DURATION
	dash_cooldown_left = DASH_COOLDOWN
		
	if direction == Vector3.ZERO:
		dash_direction = transform.basis.z.normalized()
	else:
		dash_direction = direction
	
	if dash_timer > 0.0:
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.z = dash_direction.z * DASH_SPEED
		dash_timer -= delta
	else:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
			
func _physics_process(delta):
	if Input.is_action_just_pressed("close"):
		get_tree().quit()
		
	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0:
		dash_timer = DASH_DURATION
		dash_cooldown_left = DASH_COOLDOWN
		
		if direction == Vector3.ZERO:
			dash_direction = transform.basis.z.normalized()
		else:
			dash_direction = direction
	
	if dash_timer > 0.0:
		velocity.x = dash_direction.x * DASH_SPEED
		velocity.z = dash_direction.z * DASH_SPEED
		dash_timer -= delta
	else:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	
	if is_on_floor():
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_FORCE
	else:
		velocity.y -= GRAVITY * delta
	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta
	
	move_and_slide()
	
