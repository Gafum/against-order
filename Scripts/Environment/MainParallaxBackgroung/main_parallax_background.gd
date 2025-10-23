extends ParallaxBackground

const BASE_WIDTH := 1280.0 

func _ready() -> void:
	update_background_scale()
	get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:      
	update_background_scale()

func update_background_scale() -> void:
	var viewport_width = get_viewport().get_visible_rect().size.x
	var scale_factor = viewport_width / BASE_WIDTH
	self.scroll_base_scale.x = 1/scale_factor
	self.scale.x = scale_factor
	print(scale_factor)
	if(scale_factor<1.3):
		self.scale.y = scale_factor
	else:
		self.scale.y = 1.1
	
