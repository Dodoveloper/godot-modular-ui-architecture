extends CharacterBody2D


signal name_changed(new_name: String)

@export_category("Identity")
@export var character_name := "Player Name":
	set(value):
		character_name = value
		name_changed.emit(character_name)

@export_category("Movement")
@export var speed: float = 250.0
@export var acceleration: float = 1200.0
@export var friction: float = 1500.0

@export_category("Jump")
@export var jump_velocity: float = 350.0
@export var gravity: float = 1200.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = -jump_velocity
	
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	
	move_and_slide()
