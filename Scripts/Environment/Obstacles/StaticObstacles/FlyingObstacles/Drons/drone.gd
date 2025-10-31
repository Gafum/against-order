extends "res://Scripts/Environment/Obstacles/BaseObstacle/base_obstacle.tres.gd"

func _ready() -> void:
	self.position.y -= get_viewport().get_visible_rect().size.y/2

func _physics_process(delta: float) -> void:
	if(self.position.y < 500):
		self.position.y += delta*120 *(get_viewport().get_visible_rect().size.x/1280)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		queue_free()
