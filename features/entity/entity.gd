extends CharacterBody2D

@export var _ground_friction := 0.9
@export var _air_friction := 0.995

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.x *= _air_friction
	else:
		velocity.x *= _ground_friction

	move_and_slide()