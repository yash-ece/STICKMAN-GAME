extends RigidBody2D

@export var damage: int = 2

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 20
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	# Ignore swords and all objects except Player 1's body parts
	if body.name not in [
		"torso",
		"head",
		"upper right arm",
		"lower right arm",
		"upper left arm",
		"lower left arm",
		"upper right leg",
		"lower right leg",
		"upper left leg",
		"lower left leg"
	]:
		return

	# Confirm this body part belongs to Player 1
	var player = body.get_parent()

	while player != null and not player.has_method("take_sword_damage"):
		player = player.get_parent()

	if player == null:
		return

	if player.player_number != 1 or player.is_dead:
		return

	player.take_sword_damage(damage)
	print("RedSword hit Player 1: ", body.name)
