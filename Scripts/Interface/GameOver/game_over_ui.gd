extends Control

@onready var score_label = $CenterContainer/VBoxContainer/VBoxContainer/ScoreLabel

func set_score(value: int):
	score_label.text = "Final Score: " + str(value)

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scripts/Scenes/Start menu/Start_menu.tscn")
