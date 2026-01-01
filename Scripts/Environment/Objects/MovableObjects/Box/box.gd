extends RigidBody2D

func _ready() -> void:
	add_to_group("Obstacle")
	contact_monitor = true
	max_contacts_reported = 3
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	if Global.is_game_over:
		freeze = true

func _on_body_entered(body: Node) -> void:
	if Global.is_game_over:
		return
		
	if body.is_in_group("Player"):
		if body.has_method("die"):
			body.die()
		elif body.has_method("take_damage"):
			body.take_damage()
		explode()
	elif body is TileMap or body.name == "Floor":
		explode()

const EXPLOSION_SCENE = preload("res://Scripts/Effects/BoxExplosion/box_explosion.tscn")

func explode() -> void:
	# Spawn explosion effect
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)
	
	queue_free()
