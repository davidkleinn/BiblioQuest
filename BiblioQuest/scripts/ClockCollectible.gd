extends CharacterBody2D

enum State { WANDERING, FLEEING }

@export_category("Parâmetros de IA do Relógio")
@export var perception_radius: float = 120.0 ## Raio em que detecta o jogador
@export var flee_distance: float = 150.0 ## Distância que tenta percorrer na fuga
@export var walk_speed: float = 40.0 ## Velocidade de patrulha
@export var run_speed: float = 175.0 ## Velocidade de fuga (Jogador tem 300)
@export var wander_radius: float = 80.0 ## Distância máxima que vaga do ponto inicial
@export var flee_recalculate_interval: float = 0.5 ## Segundos para recalcular a rota de fuga
@export var calm_down_multiplier: float = 1.5 ## Fator de histerese para voltar a acalmar
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# Variáveis Internas
var current_state: State = State.WANDERING
var start_position: Vector2
var player: Node2D = null
var flee_timer: float = 0.0
var wander_wait_timer: float = 0.0
var _is_collected := false

# Referências aos Nós
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var collection_area: Area2D = $CollectionArea
@onready var col_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	start_position = global_position
	player = get_tree().get_first_node_in_group("player")
	
	collection_area.body_entered.connect(_on_collection_area_body_entered)
	
	# Aguarda 1 frame da física para garantir que o mapa de navegação foi criado
	await get_tree().physics_frame
	anim_player.play("hop_walk")
	_pick_new_wander_point()

func _physics_process(delta: float) -> void:
	if _is_collected:
		return
		
	# 1. IA Lógica: Verifica se deve mudar de estado
	_check_state_transitions()
	
	# 2. IA Lógica: Processa o estado atual
	match current_state:
		State.WANDERING:
			_process_wandering(delta)
		State.FLEEING:
			_process_fleeing(delta)
			
	# 3. Lógica Física: Aplica o movimento
	_movement()

## ================= LÓGICA DE ESTADOS ================= ##

func _check_state_transitions() -> void:
	if player == null:
		return
		
	var dist_to_player := global_position.distance_to(player.global_position)
	
	# Transição: Ocioso -> Fuga
	if current_state == State.WANDERING and dist_to_player < perception_radius:
		current_state = State.FLEEING
		anim_player.speed_scale = 2.0
		anim_player.play("hop_walk")
		_calculate_flee_path()
		
	# Transição: Fuga -> Ocioso (Com Histerese para evitar flickering)
	elif current_state == State.FLEEING and dist_to_player > (perception_radius * calm_down_multiplier):
		current_state = State.WANDERING
		anim_player.speed_scale = 1.0
		anim_player.play("hop_walk")
		_pick_new_wander_point()

func _process_wandering(delta: float) -> void:
	# Se chegou no destino, aguarda um tempo curto e escolhe novo ponto
	if nav_agent.is_navigation_finished():
		wander_wait_timer -= delta
		if wander_wait_timer <= 0.0:
			_pick_new_wander_point()
			wander_wait_timer = randf_range(1.0, 3.0) # Espera de 1 a 3 segundos

func _process_fleeing(delta: float) -> void:
	# Recalcula a rota de fuga periodicamente para sempre desviar do jogador
	flee_timer -= delta
	if flee_timer <= 0.0:
		_calculate_flee_path()
		flee_timer = flee_recalculate_interval

## ================= LÓGICA DE MOVIMENTO ================= ##

func _movement() -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var next_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_pos)
	var speed := walk_speed if current_state == State.WANDERING else run_speed
	
	velocity = direction * speed
	move_and_slide() # Aplica a física (colisão com paredes/estantes)

## ================= PATHFINDING & NAVEGAÇÃO ================= ##

func _pick_new_wander_point() -> void:
	# Escolhe um ponto aleatório em volta da posição inicial
	var random_dir := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var random_dist := randf_range(10.0, wander_radius)
	nav_agent.target_position = start_position + (random_dir * random_dist)

func _calculate_flee_path() -> void:
	if player == null:
		return
	# Calcula vetor OPOSTO à posição do jogador
	var dir_away := player.global_position.direction_to(global_position)
	var target_pos := global_position + (dir_away * flee_distance)
	
	# O NavigationAgent garante que vai achar o caminho navegável mais próximo do alvo
	nav_agent.target_position = target_pos

## ================= EVENTO DE COLETA ================= ##

func _on_collection_area_body_entered(body: Node2D) -> void:
	if _is_collected or not body.is_in_group("player"):
		return
		
	_is_collected = true
	velocity = Vector2.ZERO # Trava o inseto
	col_shape.set_deferred("disabled", true) # Desativa a colisão física para não bugar a animação
	
	get_tree().call_group("level_manager", "add_time", 15.0)
	
	# Tween paralelo original
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 50, 0.4)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.4)
	
	await tween.finished
	queue_free()
