extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.002
const SPEED = 5.0
const JUMP_FORCE = 8.0
const GRAVITY = 20.0
const DASH_SPEED = 20.0
const DASH_DURATION = 0.12
const DASH_COOLDOWN = 0.5
const LIGHT_ATTACK_DMG = 10.0
const HEAVY_ATTACK_DMG = 40.0
const PARRY_WINDOW = 0.5
var dash_timer = 0.0
var dash_cooldown_left = 0.0
var dash_direction = Vector3.ZERO
var health = 100
var parrying = false
var parry_cooldown = 0.0
var free_mouse_mode = false

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
    FALL,
    DASH,
}

@onready var pivot = $"Pivot (Node3D)"
@onready var melee_hitbox = $"MeleeHitbox"

var current_movement_state = PlayerState.IDLE

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    
func _unhandled_input(event):
    if free_mouse_mode:
        return
    
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
        pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
        
        pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-40), deg_to_rad(60) )
       
func handle_debug_inputs():
    if Input.is_action_just_pressed("KEY_CTRL") and free_mouse_mode == false:
        free_mouse_mode = true
    elif Input.is_action_just_pressed("KEY_CTRL") and free_mouse_mode == true:
        free_mouse_mode = false
    
    if free_mouse_mode:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_movement_state(delta, direction):
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
    velocity.x= 0
    velocity.z = 0
    if !is_on_floor():
        current_movement_state = PlayerState.FALL
    if Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backwards") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left"):
        current_movement_state = PlayerState.MOVE
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_FORCE
        current_movement_state = PlayerState.JUMP
    if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0:
        dash_timer = DASH_DURATION
        dash_cooldown_left = DASH_COOLDOWN
        current_movement_state = PlayerState.DASH
    
    return Vector3.ZERO

func handle_move_state(delta, direction):
    if direction != Vector3.ZERO:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        current_movement_state = PlayerState.IDLE
    
    if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0:
        dash_timer = DASH_DURATION
        dash_cooldown_left = DASH_COOLDOWN
        current_movement_state = PlayerState.DASH
    
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = JUMP_FORCE
        current_movement_state = PlayerState.JUMP
    
func handle_dash_state(delta, direction):
    if direction == Vector3.ZERO:
        dash_direction = transform.basis.z.normalized()
    else:
        dash_direction = direction
    
    if dash_timer > 0.0:
        velocity.x = dash_direction.x * DASH_SPEED
        velocity.z = dash_direction.z * DASH_SPEED
        dash_timer -= delta
    if dash_timer <= 0.0:
        current_movement_state = PlayerState.IDLE
        
func handle_jump_state(delta):
    if velocity.y >= 0:
        velocity.y -= GRAVITY * delta
    else:
        current_movement_state = PlayerState.FALL

func handle_fall_state(delta):
    if !is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        current_movement_state = PlayerState.IDLE

enum AttackPhase{
    IDLE,
    LIGHT_WINDUP,
    HEAVY_WINDUP,
    LIGHT_ACTIVE,
    HEAVY_ACTIVE,
    RECOVERY
}

var attack_phase = AttackPhase.IDLE
var attack_timer = 0.0
func handle_attack_state(delta):
    match attack_phase:
        AttackPhase.IDLE:
            if Input.is_action_just_pressed("light_attack"):
                attack_phase = AttackPhase.LIGHT_WINDUP
                attack_timer = 0.1
            elif Input.is_action_just_pressed("heavy_attack"):
                attack_phase = AttackPhase.HEAVY_WINDUP
                attack_timer = 0.4
        AttackPhase.LIGHT_WINDUP:
            attack_timer -= delta
            if attack_timer <= 0.0:
                attack_phase = AttackPhase.LIGHT_ACTIVE
                attack_timer = 0.1
                melee_hitbox.activate(LIGHT_ATTACK_DMG)
        AttackPhase.HEAVY_WINDUP:
            attack_timer -= delta
            if attack_timer <= 0:
                attack_phase = AttackPhase.HEAVY_ACTIVE
                melee_hitbox.activate(HEAVY_ATTACK_DMG)
        AttackPhase.LIGHT_ACTIVE:
            attack_timer -= delta
            if attack_timer <= 0:
                melee_hitbox.deactivate()
                attack_timer = 0.1
                attack_phase = AttackPhase.RECOVERY
        AttackPhase.HEAVY_ACTIVE:
            attack_timer -= delta
            if attack_timer <= 0:
                melee_hitbox.deactivate()
                attack_timer = 0.1
                attack_phase = AttackPhase.RECOVERY
        AttackPhase.RECOVERY:
            attack_timer -= delta
            if attack_timer <= 0:
                attack_phase = AttackPhase.IDLE
func take_damage(dmg):
    health -= dmg
    print("Current player health: " + str(health))

func handle_parry(delta):
    if parry_cooldown > 0:
        parry_cooldown -= delta
    if Input.is_action_just_pressed("parry") and parry_cooldown <= 0:
        parry_cooldown = 0.5
        attack_timer = PARRY_WINDOW
        parrying = true
        print("Player attempts a deflect")
    if parrying:
        parry(delta)
        
        
func parry(delta):
    attack_timer -= delta
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy.has_method("try_parry"):
            enemy.try_parry(self)
    
    if attack_timer <= 0:
        parrying = false
        attack_phase = AttackPhase.IDLE
    
          
func _physics_process(delta):
    if Input.is_action_just_pressed("close"):
        get_tree().quit()
    var movement_direction = get_input_direction(delta)
    handle_movement_state(delta, movement_direction)
    handle_attack_state(delta)
    handle_debug_inputs()
    handle_parry(delta)
    
    if dash_cooldown_left > 0.0:
        dash_cooldown_left -= delta
    
    move_and_slide()
    
