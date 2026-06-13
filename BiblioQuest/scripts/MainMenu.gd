extends Control

# Certifique-se de que o caminho para o seu Level1 está correto aqui!
@export_file("*.tscn") var first_level_path: String = "res://scenes/Level1.tscn"

# O '@onready' pega a referência do botão dentro do container novo assim que o jogo liga
@onready var play_button: TextureButton = $MenuUI/PlayButton

func _ready() -> void:
	# O Godot vai definir o Pivot Offset automaticamente para metade do tamanho
	play_button.pivot_offset = play_button.size / 2

func _on_play_button_pressed() -> void:
	# 1. Desativa o botão
	play_button.disabled = true
	
	# 2. Centraliza o pivô na hora exata do clique
	play_button.pivot_offset = play_button.size / 2
	
	# 3. Cria a animação exata do Game Over
	var tween = create_tween()
	
	# Afunda
	tween.tween_property(play_button, "scale", Vector2(0.85, 0.85), 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Quica de volta
	tween.tween_property(play_button, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 4. ESPERA O EFEITO TERMINAR!
	await tween.finished
	
	# 5. Só então troca de fase
	get_tree().change_scene_to_file(first_level_path)
