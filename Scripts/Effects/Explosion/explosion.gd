extends Node2D

@onready var particle_object = $GPUParticles2D

func _ready():
	particle_object.emitting = true
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, particle_object.lifetime)
	
	await get_tree().create_timer(particle_object.lifetime).timeout
	particle_object.emitting = false
	queue_free()
