extends Node2D

@export_range(0.0, 1.0) var opacity_loss_per_bounce: float = 0.1
## Arraste o nó "BeamEmitter" (filho do LightBeam) para cá no Inspector!
@export var emitter: Node2D

## Direção inicial do feixe  (1,0)=direita  (-1,0)=esquerda  (0,1)=baixo  (0,-1)=cima
@export var start_direction: Vector2 = Vector2(1.0, 0.0)

@export var max_bounces: int = 8
@export var max_length: float = 5000.0

@onready var _line_glow: Line2D = $LineGlow
@onready var _line_core: Line2D = $LineCore

var _exit_door: Node = null

func _ready() -> void:
	# Garante que o feixe aparece ACIMA do chão e das paredes
	z_index = 20
	start_direction = start_direction.normalized()

	# ── LineGlow: halo externo difuso ──────────────────────────────────────
	_line_glow.z_index = 20
	_line_glow.width = 18.0
	_line_glow.joint_mode   = Line2D.LINE_JOINT_ROUND
	_line_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line_glow.end_cap_mode   = Line2D.LINE_CAP_ROUND

	# ── LineCore: núcleo brilhante opaco ──────────────────────────────────
	_line_core.z_index = 21
	_line_core.width = 7.0
	_line_core.joint_mode   = Line2D.LINE_JOINT_ROUND
	_line_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line_core.end_cap_mode   = Line2D.LINE_CAP_ROUND

	if emitter == null:
		push_error("⚠️  LightBeam: o campo 'Emitter' não foi preenchido no Inspector!")

func _physics_process(_delta: float) -> void: # loop principal do feixe de luz que roda a cada frame de física
	# ── Avisos de configuração (visíveis no Output do Godot) ───────────────
	if emitter == null:
		push_warning("LightBeam: Emitter é nulo — o feixe não será desenhado.")
		_clear_lines()
		return

	# Busca a porta de saída apenas uma vez (ou se ainda não achou)
	if _exit_door == null:
		_exit_door = get_tree().get_first_node_in_group("exit_door")

	_cast_beam()

func _cast_beam() -> void:
	var hit_exit_door := false
	var points: Array[Vector2] = []

	var pos := emitter.global_position
	var dir := start_direction.normalized()
	var space := get_world_2d().direct_space_state

	# Primeiro ponto: origem do feixe
	points.append(to_local(pos))

	for _i in max_bounces + 1: # é o loop que permite os múltiplos ricocheteios no mesmo frame
		# Máscara: Paredes(1) + Estante(4) + Espelho(8) + PortaSaida(32) + Jogador(2)
		# PortaEntrada (16) NÃO está na máscara → feixe nasce "dentro" dela
		var query := PhysicsRayQueryParameters2D.create( # aqui é onde o raio é criado
			pos + dir * 8.0,   # pequeno offset para não re-colidir no ponto atual
			pos + dir * max_length,
			1 | 4 | 8 | 32 | 2 # a definição de quais camadas o feixe deve reconhecer
		)

		var result := space.intersect_ray(query) # a chamada que faz a "pergunta" ao servido de física

		if not result:
			# Feixe vai até o infinito sem bater em nada
			points.append(to_local(pos + dir * max_length))
			break

		var hit_pt: Vector2 = result["position"]
		var collider          = result["collider"]
		points.append(to_local(hit_pt))

		if collider is Node and (collider as Node).is_in_group("mirror"):
			# A pesquisa que você fez: Usando bounce() com a normal da colisão
			var normal: Vector2 = result["normal"]
			dir = dir.bounce(normal).normalized() # função matemática para refletir o feixe no espelho 
			
			# Trava Mágica: Arredonda o vetor para manter a luz sempre reta (cima/baixo/lados)
			# Isso impede que o feixe saia torto caso o espelho gire fora de centro
			dir = Vector2(round(dir.x), round(dir.y)) # aqui ele arredonda o vetor para manter o feixe em angulos retos
			
			# Avança o ponto de colisão alguns pixels para o feixe não nascer dentro do próprio espelho
			pos = hit_pt + dir * 10.0
		elif collider is Node and (collider as Node).is_in_group("exit_door"):
			hit_exit_door = true
			break
		else:
			break

# ── Atualiza as Line2D (precisam de pelo menos 2 pontos) ───────────────
	if points.size() < 2:
		points.append(to_local(emitter.global_position + dir * 10.0))

	var packed := PackedVector2Array(points)
	_line_glow.points = packed
	_line_core.points = packed

	# == NOVA LÓGICA DE PERDA DE LUZ POR REBATIDA ==
	var total_length := 0.0
	var segment_lengths: Array[float] = []

	# 1. Mede o tamanho de cada pedaço da linha
	for i in range(points.size() - 1):
		var dist := points[i].distance_to(points[i+1])
		segment_lengths.append(dist)
		total_length += dist

	# 2. Constrói a coloração se o feixe existir
	if total_length > 0.0:
		var glow_grad := Gradient.new()
		var core_grad := Gradient.new()
		
		var glow_colors := PackedColorArray()
		var core_colors := PackedColorArray()
		var offsets := PackedFloat32Array()
		
		var current_dist := 0.0
		
		# Aplica a cor em cada segmento individualmente
		for i in range(segment_lengths.size()):
			# Calcula onde esse pedaço começa e termina (de 0.0 a 1.0)
			var start_offset := clampf(current_dist / total_length, 0.0, 1.0)
			var end_offset := clampf((current_dist + segment_lengths[i]) / total_length, 0.0, 1.0)
			
			# Lógica do Puzzle: Perde 10% (0.1) a cada rebatida (i)
			# i=0 (100%), i=1 (90%), i=2 (80%). O max(0.0) impede que fique negativo
			var opacity := maxf(0.0, 1.0 - (i * opacity_loss_per_bounce))
			
			# Adiciona um micro-deslocamento pra criar um "corte seco" de cor na quina do espelho
			if i > 0:
				start_offset = clampf(start_offset + 0.00001, 0.0, 1.0)
				
			# Define a cor de início do pedaço
			offsets.append(start_offset)
			glow_colors.append(Color(1.0, 0.85, 0.1, 0.45 * opacity))
			core_colors.append(Color(1.0, 0.97, 0.3, 1.0 * opacity))
			
			# Define a cor de finalização do pedaço (garantindo que a linha seja sólida e não degradê)
			offsets.append(end_offset)
			glow_colors.append(Color(1.0, 0.85, 0.1, 0.45 * opacity))
			core_colors.append(Color(1.0, 0.97, 0.3, 1.0 * opacity))
			
			current_dist += segment_lengths[i]
		
		# Aplica tudo na tela
		glow_grad.offsets = offsets
		glow_grad.colors = glow_colors
		_line_glow.gradient = glow_grad
		
		core_grad.offsets = offsets
		core_grad.colors = core_colors
		_line_core.gradient = core_grad

	# ── Ativa ou desativa a porta de saída ────────────────────────────────
	if _exit_door:
		if hit_exit_door:
			_exit_door.call("activate")
		else:
			_exit_door.call("deactivate")

func _clear_lines() -> void:
	_line_glow.points = PackedVector2Array()
	_line_core.points = PackedVector2Array()
