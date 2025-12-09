extends Area2D

@export var speed: float = 1200.0
@export var velocity_offset: Vector2 = Vector2.ZERO

var direction: Vector2 = Vector2.ZERO
var is_active: bool = true

var explosion_scene := preload("res://Scripts/Effects/Explosion/explosion.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
func _ready() -> void:
	rotation = direction.angle()
	name = "Bullet" + str(Time.get_ticks_msec())
	var animation_names := animated_sprite_2d.sprite_frames.get_animation_names()
	
	if (!len(animation_names)):
		return
	
	var random_ani_name = animation_names[randi() % animation_names.size()]
	animated_sprite_2d.play(random_ani_name)

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	var velocity = direction * speed + velocity_offset
	position += velocity * delta
	rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	if not is_active:
		return

	is_active = false

	_spawn_explosion()

	if body.is_in_group("destroyable"):
		if body.has_method("take_damage"):
			body.take_damage()

	queue_free()


func _spawn_explosion() -> void:
	if explosion_scene == null:
		return

	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	
	if animated_sprite_2d.sprite_frames.has_animation(animated_sprite_2d.animation):
		var texture = animated_sprite_2d.sprite_frames.get_frame_texture(animated_sprite_2d.animation, animated_sprite_2d.frame)
		if texture:
			explosion.modulate = _get_dominant_color(texture)
			
	get_tree().current_scene.add_child(explosion)


static var _color_cache: Dictionary = {}

func _get_dominant_color(texture: Texture2D) -> Color:
	if texture in _color_cache:
		return _color_cache[texture]
		
	var image = texture.get_image()
	if not image:
		return Color.WHITE
		
	var colors = {}
	var width = image.get_width()
	var height = image.get_height()
	
	for x in range(width):
		for y in range(height):
			var color = image.get_pixel(x, y)
			if color.a < 0.1:
				continue
				
			if color in colors:
				colors[color] += 1
			else:
				colors[color] = 1
				
	var dominant_color = Color.WHITE
	var max_count = -1
	
	for color in colors:
		if colors[color] > max_count:
			max_count = colors[color]
			dominant_color = color
			
	_color_cache[texture] = dominant_color
	return dominant_color


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	if is_active:
		queue_free()
