extends RigidBody2D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 3
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		if body.has_method("die"):
			body.die()
		elif body.has_method("take_damage"):
			body.take_damage()
		explode()
	elif body is TileMap or body.name == "Floor":
		explode()

func explode() -> void:
	# Disable collision and hide sprite
	$CollisionShape2D.set_deferred("disabled", true)
	$ColorRect.visible = false
	set_physics_process(false)
	freeze = true # Stop physics
	
	# Play particles if they exist
	if has_node("CPUParticles2D"):
		$CPUParticles2D.emitting = true
		await get_tree().create_timer(1.0).timeout # Wait for particles to finish
	
	queue_free()

