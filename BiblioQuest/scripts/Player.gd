extends CharacterBody2D

const SPEED := 300.0
const PUSH_SPEED_FACTOR := 0.50  # player fica mais lento ao arrastar a estante

var facing := Vector2(0, 1)

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)

	if input_dir != Vector2.ZERO:
		facing = input_dir.normalized()

	# Só procura estante se o jogador está tentando se mover
	var bookshelf: Node = null
	if input_dir != Vector2.ZERO:
		bookshelf = _find_bookshelf_ahead()

	if bookshelf != null and input_dir != Vector2.ZERO:
		# --- MODO ARRASTO ---
		# Jogador fica mais lento para simular o peso da estante
		var push_speed := SPEED * PUSH_SPEED_FACTOR # metade da velocidade de movimento ao empurrar estante
		velocity = facing * push_speed # usado pra suavizar o movimento

		# Move a estante exatamente o mesmo delta que o jogador este frame
		var delta_move := facing * push_speed * delta # a estante se move "junto" com o jogador
		var estante_moveu: bool = bookshelf.push_by(delta_move)

		# Se a estante bateu na parede, o jogador também para
		if not estante_moveu:
			velocity = Vector2.ZERO

	elif input_dir != Vector2.ZERO:
		# --- MODO NORMAL ---
		velocity = facing * SPEED # suavização de movimento
	else:
		velocity = Vector2.ZERO

	move_and_slide() # usado junto com o velocity pra criar a movimentação de "arrasto" suavizada

#func _input(event: InputEvent) -> void:
#	if event.is_action_pressed("interact"):

# Detecta estante a poucos pixels à frente (para o arrasto contínuo)
# Detecta estante a poucos pixels à frente (para o arrasto contínuo)
# Detecta estante à frente (ajustando a distância se for lado ou cima/baixo)
# Detecta estante à frente compensando a assimetria do desenho
# Detecta estante à frente compensando a assimetria do desenho em 4 direções
func _find_bookshelf_ahead() -> Node:
	var space := get_world_2d().direct_space_state
	
	var origem := global_position
	var distancia_braco := 0.0
	
	# 1. Olhando para a DIREITA (empurrando da esquerda pra direita)
	if facing.x > 0: 
		origem.x += 12.0  # "empurra" a collision box da sprite pra direita
		distancia_braco = 5.0 # Diminuí de 10 para 5, já que estava longe
		
	# 2. Olhando para a ESQUERDA (empurrando da direita pra esquerda)
	elif facing.x < 0: 
		# Sem deslocamento de origem, pois o sprite alinha melhor à esquerda
		distancia_braco = 10.0 # a sprite já está um pouco alinhada à esquerda
		
	# 3. Olhando para BAIXO (empurrando de cima pra baixo)
	elif facing.y > 0: 
		# Sem deslocamento de origem
		distancia_braco = 30.0 # já está um pouco mais pra baixo
		
	# 4. Olhando para CIMA (empurrando de baixo pra cima)
	elif facing.y < 0: 
		origem.y -= 10.0 # Desloca o collision box do sprite um pouco para cima
		distancia_braco = 15.0 # compensa a collision box da sprite um pouco mais pra cima
		
	var query := PhysicsRayQueryParameters2D.create(
		origem,
		origem + facing * distancia_braco,
		4  # Layer 3 = Estante -> bitmask 4
	)
	query.exclude = [self]
	var result := space.intersect_ray(query)
	
	if result and result["collider"].is_in_group("bookshelf"):
		return result["collider"]
	return null
