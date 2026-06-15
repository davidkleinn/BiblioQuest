extends CanvasLayer

@onready var anim = $AnimationPlayer

func change_scene(path: String) -> void:
	# 1. Escurece a tela
	anim.play("fade_to_black")
	await anim.animation_finished
	
	# 2. Troca a fase por baixo dos panos
	get_tree().change_scene_to_file(path)
	
	# 3. Clareia a tela de novo
	anim.play("fade_from_black")
