extends Node2D

@export var move_force: float = 30000.0
@export var jump_force: float = 20000.0
@export var punch_force: float = 25000.0
@export var max_speed: float = 30000.0

@onready var lower_arm: RigidBody2D = $"lower right arm"
@onready var torso: RigidBody2D = $torso

func _physics_process(_delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")

	# Move the lower arm
	if direction != 0:
		lower_arm.apply_central_force(Vector2(direction * move_force, 0))

	# Jump: push the torso upward
	if Input.is_action_just_pressed("ui_accept"):
		torso.apply_central_impulse(Vector2(0, -jump_force))

	# Punch: push the lower arm forward
	if Input.is_action_just_pressed("ui_right"):
		lower_arm.apply_central_impulse(Vector2(punch_force, 0))

	if Input.is_action_just_pressed("ui_left"):
		lower_arm.apply_central_impulse(Vector2(-punch_force, 0))
