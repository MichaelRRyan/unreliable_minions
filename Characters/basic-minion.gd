extends Entity
class_name Minion

signal died

@export var speed : float = 300.0
@export var acceleration : float = 300.0
@export var jump_velocity : float = -400.0
@export var health : float = 10
@export var max_health : float = 10
@export var _fall_dmg_thershold : float = 200.0
@export var _fall_dmg_ratio : float = 0.01
@export var has_axe : bool
@export var has_hammer : bool
var _prev_velocity := Vector2.ZERO
var _prev_is_on_floor = false
var target
var is_interacting : bool = false
var has_task : bool = false
var is_moving : bool = true
var has_target : bool = false
var target_x : float = 0.0
var target_x_diff : float = 0.0
var rng = RandomNumberGenerator.new()
var random_number = 0.0

var view_array
@onready var view_area = $View

@onready var harvest_timer = $TimerHarvest

@onready var _pickup_component : PickupComponent = get_node("PickupComponent")


func _ready():
	health = max_health
	$HealthBar.value = health / max_health
	name = Global.minion_names[randi() % Global.minion_names.size()]

func _physics_process(delta):
	var direction = 0
	if is_on_floor():
		if not _prev_is_on_floor and _prev_velocity.y >= _fall_dmg_thershold:
			take_damage((_prev_velocity.y - _fall_dmg_thershold) * _fall_dmg_ratio)
			print(_prev_velocity)
		velocity.x *= _ground_friction
		
		if not has_target && not is_interacting && not has_target:
			get_view_array()
			for n in view_array.size():
				if has_axe:
					if view_array[n].is_in_group("tree"):
						target = view_array[n]
						has_target = true
						has_task = true
						target_x = target.get_global_position().x
				if has_hammer:
					if view_array[n].is_in_group("resource"):
						target = view_array[n]
						has_target = true
						has_task = true
						target_x = target.get_global_position().x
				
		
		if has_target && not is_interacting:
			target_x_diff = get_global_position().x - target_x
			if target_x_diff < 0.0:
				direction = 1
			else:
				direction = -1
		else:
			direction = 0

		if has_task && not has_target && not is_interacting:
			if random_number >= 0.0:
				direction = 1
			else:
				direction = -1
		
	else:
		velocity.y += gravity * delta
		velocity.x *= _air_friction
			
	if direction != 0:
		$AnimatedSprite2D.play("Walk")
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		$AnimatedSprite2D.play("Idle")
		
	if _pickup_component == null or not _pickup_component.is_held():
		velocity.x = clamp(velocity.x + direction * acceleration * delta, -speed, speed)
	
	_prev_velocity = velocity
	_prev_is_on_floor = is_on_floor()
	move_and_slide()

func _on_view_body_entered(body):
	if not has_target:
		if has_axe:
			if body.is_in_group("tree"):
				target = body
				has_target = true
				has_task = true
				target_x = target.get_global_position().x
				#print(target_x)
		if has_hammer:
			if body.is_in_group("resource"):
				target = body
				has_target = true
				has_task = true
				target_x = target.get_global_position().x
				#print(target_x)


func _on_timer_idle_timeout():
	if not has_target:
		if not is_interacting:
			has_task = not has_task
			random_number = rng.randf_range(-1.0, 1.0)


func _on_interact_range_body_entered(_body):
	if has_target:
		if target.is_in_group("tree"):
			has_target = false
			is_interacting = true
			has_task = true
			harvest_timer.start(3)
		if target.is_in_group("resource"):
			has_target = false
			is_interacting = true
			has_task = true
			harvest_timer.start(3)
			#building


func _on_timer_harvest_timeout():
	if target != null && target.is_in_group("tree"):
		target.chop()
		target.queue_free()
		harvest_timer.stop()
		is_interacting = false
		has_task = false
		has_target = false
		target = null
		reset_bools()
	elif target != null && target.is_in_group("resource"):
		target.queue_free()
		harvest_timer.stop()
		is_interacting = false
		has_task = false
		has_target = false
		target = null
		reset_bools()
	else:
		harvest_timer.stop()
		is_interacting = false
		has_task = false
		has_target = false
		reset_bools()

func reset_bools():
	is_interacting = false
	has_task = false
	has_target = false
	target = null

func get_view_array():
	view_array = view_area.get_overlapping_bodies()
	pass

func take_damage(amount : float):
	health -= amount
	$HealthBar.value = health / max_health
	if health <= 0:
		_die()

func _die():
	print(name + " has died.")
	emit_signal("died")
	queue_free()
