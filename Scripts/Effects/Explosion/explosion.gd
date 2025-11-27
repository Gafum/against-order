extends Node2D

@onready var particle_object = $GPUParticles2D

func _ready():
	particle_object.emitting = true
	await get_tree().create_timer(particle_object.lifetime).timeout
	particle_object.emitting = false
	particle_object.queue_free()
	queue_free()
