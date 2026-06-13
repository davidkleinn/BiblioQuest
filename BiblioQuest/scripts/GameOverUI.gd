extends Control

@onready var dark_bg: ColorRect = $DarkBackground
@onready var buttons_container: VBoxContainer = $ButtonsContainer

func _ready() -> void:
	# Garante que começa invisível
	hide()
	
	# Conecta os sinais de clique dos botões via código
	$ButtonsContainer/BtnRestart.pressed.connect(_on_restart_pressed)
	$ButtonsContainer/BtnMenu.pressed.connect(_on_menu_pressed)
	$ButtonsContainer/BtnExit.pressed.connect(_on_exit_pressed)

func trigger_game_over() -> void:
	show() # Torna a tela visível
	get_tree().paused = true # Pausa todo o resto do jogo (inimigos, timer, player)
	
	# --- PREPARAÇÃO DA ANIMAÇÃO ---
	# Deixa o fundo totalmente invisível
	dark_bg.modulate.a = 0.0 
	# Salva a posição original e joga os botões 200 pixels pra baixo e invisíveis
	var pos_final_y = buttons_container.position.y
	buttons_container.position.y += 200 
	buttons_container.modulate.a = 0.0
	
	# --- EXECUÇÃO DO TWEEN (Tudo ao mesmo tempo) ---
	var tween = create_tween().set_parallel(true)
	
	# 1. O fundo preto vai surgindo em 0.5 segundos
	tween.tween_property(dark_bg, "modulate:a", 1.0, 0.5)
	
	# 2. Os botões sobem deslizando com um efeitinho de "mola" (TRANS_BACK) no final
	tween.tween_property(buttons_container, "position:y", pos_final_y, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
	# 3. Os botões vão aparecendo gradativamente junto com a subida
	tween.tween_property(buttons_container, "modulate:a", 1.0, 0.5)

# ... (Seu código lá de cima e a função trigger_game_over continuam iguais) ...

# --- FUNÇÃO AJUDANTE DE ANIMAÇÃO ---

func animate_click_and_execute(button: TextureButton, action: Callable) -> void:
	# 1. Desativa todos os botões para o jogador não "metralhar" cliques
	$ButtonsContainer/BtnRestart.disabled = true
	$ButtonsContainer/BtnMenu.disabled = true
	$ButtonsContainer/BtnExit.disabled = true
	
	# 2. Crava o pivô no meio do botão (Garante que ele encolha para o centro)
	button.pivot_offset = button.size / 2
	
	# 3. Cria o Tween e IGNORA O PAUSE (vital, pois o jogo está pausado)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# Afunda o botão (Escala 0.85)
	tween.tween_property(button, "scale", Vector2(0.85, 0.85), 0.1)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Volta dando um quique elástico (TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	# 4. Espera a animação terminar ANTES de trocar de tela!
	await tween.finished
	
	# 5. Executa a função que foi passada
	action.call()


# --- AÇÕES DOS BOTÕES (Agora chamando a animação antes) ---

func _on_restart_pressed() -> void:
	animate_click_and_execute($ButtonsContainer/BtnRestart, _do_restart)

func _do_restart() -> void:
	get_tree().paused = false 
	get_tree().reload_current_scene() 

func _on_menu_pressed() -> void:
	animate_click_and_execute($ButtonsContainer/BtnMenu, _do_menu)

func _do_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn") 

func _on_exit_pressed() -> void:
	animate_click_and_execute($ButtonsContainer/BtnExit, _do_exit)

func _do_exit() -> void:
	get_tree().quit()
