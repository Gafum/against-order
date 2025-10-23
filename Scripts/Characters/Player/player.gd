extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -700.0

func _ready() -> void:
	velocity.x = SPEED

func _physics_process(delta: float) -> void:
	## Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func jump():
	if is_on_floor():
		velocity.y = JUMP_VELOCITY


func _input(event):
	## Handle jump (Left side tap).
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) :
		if(event.position.x < get_viewport().get_visible_rect().size.x/2):
			jump()
	
	## Handle jump (Space).
	if  (event is InputEventKey and event.keycode == KEY_SPACE):
		jump()
