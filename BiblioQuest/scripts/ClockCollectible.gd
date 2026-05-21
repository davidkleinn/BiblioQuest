extends Area2D

var _is_collected := false

func _ready() -> void:
	# Conecta o sinal que avisa se algum corpo entrou no relógio
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Se já foi coletado ou se quem pisou não foi o jogador, ignora
	if _is_collected or not body.is_in_group("player"):
		return
		
	_is_collected = true
	
	# Usamos o grupo para mandar a fase adicionar +15 segundos
	get_tree().call_group("level_manager", "add_time", 15.0)
	
	# --- ANIMAÇÃO ESTILO MOEDA DO MARIO ---
	# Criamos um Tween paralelo (ele roda o movimento e o sumiço ao mesmo tempo)
	var tween = create_tween().set_parallel(true)
	
	# 1. Faz o relógio subir 50 pixels da posição atual dele em 0.4 segundos
	tween.tween_property(self, "position:y", position.y - 50, 0.4)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	# 2. Faz ele desaparecer (Fade Out) alterando a opacidade (modulate:a) para 0
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	
	# Espera os 0.4 segundos da animação terminarem
	await tween.finished
	
	# Deleta o relógio do jogo para não pesar na memória
	queue_free()
