extends Node2D

@onready var level_timer: Timer = $LevelTimer
@onready var timer_ui: Control = $HUD/TimerUI
@onready var game_over_ui: Control = $HUD/GameOverUI

func _ready() -> void:
	# Coloca a fase no grupo para os relógios a encontrarem
	add_to_group("level_manager")
	
	# Conecta o sinal de fim de tempo
	level_timer.timeout.connect(_on_level_timer_timeout)

func _process(_delta: float) -> void:
	# Esse método roda a cada frame do jogo.
	# Ele checa quanto tempo falta no Timer e atualiza o UI na tela
	if level_timer and not level_timer.is_stopped():
		timer_ui.update_time(level_timer.time_left)

func _on_level_timer_timeout() -> void:
	# Ao invés de fechar o jogo, ativa a nossa tela estilosa!
	game_over_ui.trigger_game_over()

func add_time(amount: float) -> void:
	# Função que o relógio chama ao ser coletado
	var new_time = level_timer.time_left + amount
	level_timer.start(new_time)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		# 1. Tira o pause (caso o jogador aperte R durante a tela de Game Over/Vitória)
		get_tree().paused = false 
		
		# 2. Reinicia a fase instantaneamente
		get_tree().reload_current_scene()
