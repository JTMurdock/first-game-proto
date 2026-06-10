extends Area3D
var DAMAGE = 5

@onready var attacking_dummy = get_parent()

func activate():
	monitoring = true
	print("Attack dummy hitbox active")

func deactivate():
	monitoring = false
	print("Attack dummy hitbox deactive")
	
func _ready():
	monitoring = false
	area_entered.connect(_on_attack_hitbox_entered)
	
func _on_attack_hitbox_entered(area):
	if area.is_in_group("player_hurtbox"):
		var player = area.get_parent()
		if player.has_method("take_damage"):
			player.take_damage(DAMAGE)
			print("Player damaged for: " + str(DAMAGE))
