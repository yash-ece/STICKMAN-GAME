extends Area2D

@export var damage: int = 15
@export var owner_player_number: int = 1

var hit_players: Dictionary = {}

func _ready() -> void:
	add_to_group("swords")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("stickman_parts"):
		return

	if not body.has_meta("stickman_root"):
		return

	var opponent = body.get_meta("stickman_root")

	if opponent.player_number == owner_player_number:
		return

	if opponent.is_dead:
		return

	var opponent_id: int = opponent.get_instance_id()

	if hit_players.has(opponent_id):
		return

	hit_players[opponent_id] = true
	opponent.take_sword_damage(damage)

	print("Sword hit Player ", opponent.player_number)
