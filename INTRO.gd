extends Control
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	INTRO()
	
func INTRO():
	await animation_player.animation_finished
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn") 
