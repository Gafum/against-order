extends StaticBody2D

# Simply following the player

@export var follow_target_path: NodePath
var follow_target: Node2D

func _ready() -> void:
	follow_target = get_node(follow_target_path)

func _process(_delta: float) -> void:
	if follow_target:
		self.global_position.x = follow_target.global_position.x
