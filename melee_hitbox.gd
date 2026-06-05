extends Area3D
var damage = 0

func activate(dmg):
	monitoring = true
	damage = dmg
	print("Player hitbox active")

func deactivate():
	monitoring = false
	print("Player hitbox deactive")
	
func _ready():
	monitoring = false
	area_entered.connect(_on_attack_hitbox_entered)
	
func _on_attack_hitbox_entered(area):
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			print("Enemy damaged for: " + str(damage))
