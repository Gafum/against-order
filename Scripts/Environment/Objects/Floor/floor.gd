extends StaticBody2D

var floor_width = 84

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	update_background_scale()
 
func _on_viewport_size_changed() -> void:      
	update_background_scale()

func update_background_scale() -> void:
	var viewport_width = get_viewport().get_visible_rect().size.x
	var scale_factor = viewport_width / floor_width
	self.scale.x = scale_factor
