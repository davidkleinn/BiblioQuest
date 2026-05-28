extends Node2D

@export_range(0.0, 1.0) var opacity_loss_per_bounce: float = 0.001
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

func _physics_process(_delta: float) -> void:
	if emitter == null:
		push_warning("LightBeam: Emitter é nulo — o feixe não será desenhado.")
		_clear_lines()
		return

	# Busca a porta de saída apenas uma vez
	if _exit_door == null:
		_exit_door = get_tree().get_first_node_in_group("exit_door")
		
	# Chama a função que desenha a luz
	_cast_beam()

func _cast_beam() -> void:
	var hit_exit_door := false
	var points: Array[Vector2] = []

	var pos := emitter.global_position
	var dir := start_direction.normalized()
	var space := get_world_2d().direct_space_state

	# Primeiro ponto: origem do feixe
	points.append(to_local(pos))

	for _i in max_bounces + 1:
		var query := PhysicsRayQueryParameters2D.create(
			pos + dir * 8.0,   
			pos + dir * max_length,
			1 | 4 | 8 | 32 | 2 
		)

		var result := space.intersect_ray(query)

		if not result:
			# Feixe vai até o infinito sem bater em nada
			points.append(to_local(pos + dir * max_length))
			break

		var hit_pt: Vector2 = result["position"]
		var collider          = result["collider"]
		points.append(to_local(hit_pt))

		# ========== BLOCO DO ESPELHO ==========
		if collider is Node and (collider as Node).is_in_group("mirror"):
			var mirror := collider as Node2D
			
			# TRUQUE VISUAL: Substituímos o ponto da borda pelo CENTRO do espelho!
			# O to_local garante que a linha desenhe certo.
			points[points.size() - 1] = to_local(mirror.global_position) 
			
			# FÍSICA MATEMÁTICA: Cria uma normal base. 
			var fake_normal := Vector2(-1, -1).normalized().rotated(mirror.global_rotation)
			
			# Vira a normal de frente para a luz
			if dir.dot(fake_normal) > 0:
				fake_normal = -fake_normal
				
			# Calcula a nova direção e trava reto
			dir = dir.bounce(fake_normal).normalized()
			dir = Vector2(round(dir.x), round(dir.y))
			
			# O próximo raio precisa sair do centro + uma distância segura
			pos = mirror.global_position + dir * 15.0
			
		# ========== BLOCO DA PORTA DE SAÍDA ==========
		elif collider is Node and (collider as Node).is_in_group("exit_door"):
			hit_exit_door = true
			break # Bateu na porta, a luz para aqui e não continua andando!
			
		# ========== BLOCO DAS PAREDES / ESTANTES ==========
		else:
			break # Se bateu em qualquer outra coisa sólida, interrompe o feixe!

	# ── Atualiza as Line2D (precisam de pelo menos 2 pontos) ───────────────
	if points.size() < 2:
		points.append(to_local(emitter.global_position + dir * 10.0))

	var packed := PackedVector2Array(points)
	_line_glow.points = packed
	_line_core.points = packed

	# == LÓGICA DE PERDA DE LUZ POR REBATIDA ==
	var total_length := 0.0
	var segment_lengths: Array[float] = []

	for i in range(points.size() - 1):
		var dist := points[i].distance_to(points[i+1])
		segment_lengths.append(dist)
		total_length += dist

	if total_length > 0.0:
		var glow_grad := Gradient.new()
		var core_grad := Gradient.new()
		
		var glow_colors := PackedColorArray()
		var core_colors := PackedColorArray()
		var offsets := PackedFloat32Array()
		
		var current_dist := 0.0
		
		for i in range(segment_lengths.size()):
			var start_offset := clampf(current_dist / total_length, 0.0, 1.0)
			var end_offset := clampf((current_dist + segment_lengths[i]) / total_length, 0.0, 1.0)
			
			var opacity := maxf(0.0, 1.0 - (i * opacity_loss_per_bounce))
			
			if i > 0:
				start_offset = clampf(start_offset + 0.00001, 0.0, 1.0)
				
			offsets.append(start_offset)
			glow_colors.append(Color(1.0, 0.85, 0.1, 1.0 * opacity))
			core_colors.append(Color(1.0, 0.97, 0.3, 1.0 * opacity))
			
			offsets.append(end_offset)
			glow_colors.append(Color(1.0, 0.85, 0.1, 0.7 * opacity))
			core_colors.append(Color(1.0, 0.97, 0.3, 1.0 * opacity))
			
			current_dist += segment_lengths[i]
		
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
