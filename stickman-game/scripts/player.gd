extends Node2D

@export var player_number: int = 1

@export var move_force: float = 40000.0
@export var jump_force: float = 30000.0
@export var max_speed: float = 30000.0

@export var max_health: int = 100

@onready var torso: RigidBody2D = $torso

var health: int = 100
var is_dead: bool = false

var health_bar: ProgressBar
var health_label: Label
var health_canvas: CanvasLayer


func _ready() -> void:
	health = max_health

	# Register all physical body parts.
	for node in find_children("*", "RigidBody2D", true, false):
		var part := node as RigidBody2D
		part.add_to_group("stickman_parts")
		part.set_meta("stickman_root", self)

	create_health_display()


func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	var direction: float = 0.0

	# Player 1: A and D.
	if player_number == 1:
		if Input.is_key_pressed(KEY_A):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D):
			direction += 1.0

	# Player 2: Left and Right arrows.
	else:
		if Input.is_key_pressed(KEY_LEFT):
			direction -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			direction += 1.0

	# Move the torso.
	if direction != 0.0:
		torso.apply_central_force(
			Vector2(direction * move_force, 0.0)
		)

	# Limit horizontal speed.
	if absf(torso.linear_velocity.x) > max_speed:
		torso.linear_velocity.x = (
			signf(torso.linear_velocity.x) * max_speed
		)

	update_health_display()


func _input(event: InputEvent) -> void:
	if is_dead:
		return

	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey

	if not key_event.pressed or key_event.echo:
		return

	# Player 1 jumps with W.
	if player_number == 1 and key_event.keycode == KEY_W:
		torso.apply_central_impulse(
			Vector2(0.0, -jump_force)
		)

	# Player 2 jumps with Up Arrow.
	elif player_number == 2 and key_event.keycode == KEY_UP:
		torso.apply_central_impulse(
			Vector2(0.0, -jump_force)
		)


func take_sword_damage(amount: int) -> void:
	if is_dead:
		return

	health = clampi(health - amount, 0, max_health)
	update_health_display()

	print("Player ", player_number, " HP: ", health)

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	print("Player ", player_number, " defeated!")

	for node in find_children("*", "RigidBody2D", true, false):
		var part := node as RigidBody2D
		part.freeze = true

	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()


func create_health_display() -> void:
	health_canvas = CanvasLayer.new()
	health_canvas.name = "HealthDisplay"
	add_child(health_canvas)

	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.size = Vector2(200, 20)
	health_canvas.add_child(health_bar)

	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.size = Vector2(200, 24)
	health_canvas.add_child(health_label)

	update_health_display()


func update_health_display() -> void:
	if not is_instance_valid(torso):
		return

	if not is_instance_valid(health_bar):
		return

	health_bar.value = health

	health_label.text = "P%d | HP: %d / %d" % [
		player_number,
		health,
		max_health
	]

	var head := get_node_or_null("head") as RigidBody2D
	var head_position: Vector2

	if head != null:
		head_position = head.global_position
	else:
		head_position = torso.global_position + Vector2(0.0, -100.0)

	var screen_position: Vector2 = (
		get_viewport().get_canvas_transform() * head_position
	)

	health_bar.position = screen_position + Vector2(-100.0, -65.0)
	health_label.position = screen_position + Vector2(-100.0, -90.0)
