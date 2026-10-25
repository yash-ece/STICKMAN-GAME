
extends Node2D

@export var player_number: int = 1

@export var move_force: float = 40000.0
@export var jump_force: float = 30000.0
@export var down_force: float = 30000.0
@export var horizontal_jerk: float = 30000.0
@export var max_speed: float = 30000.0
@export var max_health: int = 100

@onready var torso: RigidBody2D = $torso

var movement_arm: RigidBody2D
var health: int = 100
var is_dead: bool = false

# Persistent kill count stored in GameManager.
var kills: int:
	get:
		if player_number == 1:
			return GameManager.player1_kills
		return GameManager.player2_kills
	set(value):
		if player_number == 1:
			GameManager.player1_kills = value
		else:
			GameManager.player2_kills = value

var health_bar: ProgressBar
var health_label: Label
var kill_label: Label
var health_canvas: CanvasLayer


func _ready() -> void:
	health = max_health

	if player_number == 1:
		movement_arm = get_node_or_null("lower right arm") as RigidBody2D
	else:
		movement_arm = get_node_or_null("lower left arm") as RigidBody2D

	if movement_arm == null:
		push_error("Movement arm not found! Check the node name.")
		return

	# Register body parts for sword damage detection.
	for node in find_children("*", "RigidBody2D", true, false):
		var part := node as RigidBody2D
		part.add_to_group("stickman_parts")
		part.set_meta("stickman_root", self)

	setup_self_collision_exceptions()
	add_to_group("player")
	create_health_display()


func setup_self_collision_exceptions() -> void:
	var body_parts: Array[RigidBody2D] = []

	for node in find_children("*", "RigidBody2D", true, false):
		body_parts.append(node as RigidBody2D)

	for i in range(body_parts.size()):
		for j in range(i + 1, body_parts.size()):
			body_parts[i].add_collision_exception_with(body_parts[j])


func _physics_process(_delta: float) -> void:
	if is_dead or movement_arm == null:
		return

	var direction: float = 0.0

	if player_number == 1:
		if Input.is_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D):
			direction += 1.0
	else:
		if Input.is_key_pressed(KEY_LEFT):
			direction -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			direction += 1.0

	if direction != 0.0:
		movement_arm.apply_central_force(
			Vector2(direction * move_force, 0.0)
		)

	var velocity := movement_arm.linear_velocity
	velocity.x = clampf(velocity.x, -max_speed, max_speed)
	movement_arm.linear_velocity = velocity


func _input(event: InputEvent) -> void:
	if is_dead or movement_arm == null:
		return

	if event is not InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if player_number == 1:
		if event.keycode == KEY_W:
			movement_arm.apply_central_impulse(Vector2(0, -jump_force))
		elif event.keycode == KEY_S:
			movement_arm.apply_central_impulse(Vector2(0, down_force))
		elif event.keycode == KEY_Q:
			movement_arm.apply_central_impulse(Vector2(-horizontal_jerk, 0))
		elif event.keycode == KEY_E:
			movement_arm.apply_central_impulse(Vector2(horizontal_jerk, 0))
	else:
		if event.keycode == KEY_UP:
			movement_arm.apply_central_impulse(Vector2(0, -jump_force))
		elif event.keycode == KEY_DOWN:
			movement_arm.apply_central_impulse(Vector2(0, down_force))
		elif event.keycode == KEY_1:
			movement_arm.apply_central_impulse(Vector2(-horizontal_jerk, 0))
		elif event.keycode == KEY_2:
			movement_arm.apply_central_impulse(Vector2(horizontal_jerk, 0))


# Called by the sword when it hits this player.
func take_sword_damage(damage: int) -> void:
	if is_dead:
		return

	health = maxi(health - damage, 0)
	update_health_display()

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true

	# Award one kill to the surviving opponent.
	var players := get_tree().get_nodes_in_group("player")

	for node in players:
		var opponent := node as Node2D

		if opponent != self and opponent.has_method("add_kill"):
			if not opponent.get("is_dead"):
				opponent.add_kill()
				break

	# Freeze this player's body parts.
	for node in find_children("*", "RigidBody2D", true, false):
		var part := node as RigidBody2D
		part.freeze = true

	# Show the final score for two seconds.
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


func add_kill() -> void:
	kills += 1
	update_kill_display()


func create_health_display() -> void:
	health_canvas = CanvasLayer.new()
	add_child(health_canvas)

	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(200, 20)
	health_bar.size = Vector2(200, 20)
	health_canvas.add_child(health_bar)

	health_label = Label.new()
	health_label.text = str(health) + " / " + str(max_health)
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.size = Vector2(200, 25)
	health_canvas.add_child(health_label)

	# Automatically create the kill counter.
	kill_label = Label.new()
	kill_label.text = "Kills: " + str(kills)
	kill_label.add_theme_font_size_override("font_size", 18)
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kill_label.size = Vector2(200, 25)
	health_canvas.add_child(kill_label)

	update_health_display()


func update_health_display() -> void:
	if health_bar == null or health_label == null or kill_label == null:
		return

	health_bar.value = health
	health_label.text = str(health) + " / " + str(max_health)
	kill_label.text = "Kills: " + str(kills)

	var head := get_node_or_null("head") as Node2D

	if head == null:
		return

	var screen_position: Vector2 = (
		get_viewport().get_canvas_transform() * head.global_position
	)

	health_bar.position = screen_position + Vector2(-100, -60)
	health_label.position = screen_position + Vector2(-100, -85)
	kill_label.position = screen_position + Vector2(-100, -110)


func update_kill_display() -> void:
	if kill_label != null:
		kill_label.text = "Kills: " + str(kills)


func _process(_delta: float) -> void:
	update_health_display()
