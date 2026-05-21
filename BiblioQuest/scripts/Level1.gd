extends Node2D

@onready var level_timer: Timer = $LevelTimer
@onready var timer_label: Label = $HUD/TimerLabel

func _ready() -> void:
	# Coloca a fase no grupo para os relógios a encontrarem
	add_to_group("level_manager")
	
	# Conecta o sinal de fim de tempo
	level_timer.timeout.connect(_on_level_timer_timeout)

func _process(_delta: float) -> void:
	# Esse método roda a cada frame do jogo.
	# Ele checa quanto tempo falta no Timer e atualiza o texto na tela
	if level_timer and not level_timer.is_stopped():
		# 'ceil' arredonda o tempo para cima (ex: 59.4 virá 60) para ficar mais bonito
		var tempo_restante = ceil(level_timer.time_left)
		timer_label.text = "Tempo: " + str(tempo_restante) + "s"

func _on_level_timer_timeout() -> void:
	# O tempo acabou! Fecha o jogo
	get_tree().quit()

func add_time(amount: float) -> void:
	# Função que o relógio chama ao ser coletado
	var new_time = level_timer.time_left + amount
	level_timer.start(new_time)
