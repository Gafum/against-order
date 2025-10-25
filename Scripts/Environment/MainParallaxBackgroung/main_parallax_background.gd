extends ParallaxBackground

var background_width := 5120.0
@onready var background_sprite: Sprite2D = $Layer0/Sprite

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	update_background_scale()
	background_width = background_sprite.texture.get_width()
	

func _on_viewport_size_changed() -> void:      
	update_background_scale()

func update_background_scale() -> void:
	var viewport_width = get_viewport().get_visible_rect().size.x
	var scale_factor = viewport_width / background_width
	if(scale_factor>0.85):
		self.scale.x = scale_factor+0.15
