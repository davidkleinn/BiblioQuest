extends Control

# Certifique-se de que o caminho para o seu Level1 está correto aqui!
@export_file("*.tscn") var first_level_path: String = "res://scenes/Level1.tscn"

# O '@onready' pega a referência do botão dentro do container novo assim que o jogo liga
@onready var play_button: TextureButton = $MenuUI/PlayButton

func _ready() -> void:
	# O Godot vai definir o Pivot Offset automaticamente para metade do tamanho
	play_button.pivot_offset = play_button.size / 2


func _on_play_button_pressed() -> void:
	# 1. Desativa o botão para o jogador não clicar duas vezes e dar erro
	play_button.disabled = true
	
	# 2. Cria a animação (Tween)
	var tween = create_tween()
	
	# 3. Faz o botão crescer para 110% do tamanho em 0.1 segundos
	tween.tween_property(play_button, "scale", Vector2(0.9, 0.9), 0.1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# 4. Faz o botão voltar ao tamanho normal (100%) em mais 0.1 segundos
	tween.tween_property(play_button, "scale", Vector2(1.0, 1.0), 0.1)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	# 5. O script "espera" a animação terminar antes de executar a próxima linha
	await tween.finished
	
	# 6. Finalmente, muda para a primeira fase
	get_tree().change_scene_to_file(first_level_path)
