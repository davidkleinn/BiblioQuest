extends Node2D

@onready var level_timer: Timer = $LevelTimer
@onready var timer_ui: Control = $HUD/TimerUI
@onready var game_over_ui: Control = $HUD/GameOverUI
# 1. Criamos a referência para a sua tela de vitória!
@onready var victory_ui: Control = $HUD/VictoryUI

func _ready() -> void:
	# Coloca a fase no grupo para os relógios a encontrarem
	add_to_group("level_manager")
	
	# 2. Coloca a PRÓPRIA FASE no grupo da vitória. 
	# Assim, quando a porta gritar "Quem é victory_ui?", a fase responde!
	add_to_group("victory_ui")
	
	# Conecta o sinal de fim de tempo
	level_timer.timeout.connect(_on_level_timer_timeout)

func _process(_delta: float) -> void:
	# Esse método roda a cada frame do jogo.
	if level_timer and not level_timer.is_stopped():
		timer_ui.update_time(level_timer.time_left)

func _on_level_timer_timeout() -> void:
	# Ao invés de fechar o jogo, ativa a nossa tela estilosa!
	game_over_ui.trigger_game_over()

func add_time(amount: float) -> void:
	# Função que o relógio chama ao ser coletado
	var new_time = level_timer.time_left + amount
	level_timer.start(new_time)

# --- A MÁGICA DA VITÓRIA ACONTECE AQUI ---
func trigger_victory() -> void:
	# 1. Para o cronômetro IMEDIATAMENTE para não dar Game Over no fundo!
	if level_timer:
		level_timer.stop()
		
	# 2. Ativa a tela de vitória
	if victory_ui:
		# Se a sua VictoryUI tiver o script original dela, roda ele:
		if victory_ui.has_method("trigger_victory"):
			victory_ui.trigger_victory()
		else:
			# Se for só a interface sem script, a gente pausa o jogo e mostra ela na força bruta!
			get_tree().paused = true
			victory_ui.visible = true
	else:
		push_error("⚠️ ERRO: O nó VictoryUI não foi encontrado dentro do HUD!")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		# Tira o pause (caso o jogador aperte R durante a tela de Game Over/Vitória)
		get_tree().paused = false 
		
		# Reinicia a fase instantaneamente
		get_tree().reload_current_scene()
