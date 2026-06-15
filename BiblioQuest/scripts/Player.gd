extends CharacterBody2D

const SPEED := 300.0
const PUSH_SPEED_FACTOR := 0.50  # player fica mais lento ao arrastar a estante

var facing := Vector2(0, 1)

# 1. REFERÊNCIA DA ANIMAÇÃO
# Certifique-se de que o nó de animação do player se chama "AnimatedSprite2D"
@onready var anim: AnimatedSprite2D = $Sprite2D

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
		var push_speed := SPEED * PUSH_SPEED_FACTOR 
		velocity = facing * push_speed 

		var delta_move := facing * push_speed * delta 
		var estante_moveu: bool = bookshelf.push_by(delta_move)

		if not estante_moveu:
			velocity = Vector2.ZERO

	elif input_dir != Vector2.ZERO:
		# --- MODO NORMAL ---
		velocity = facing * SPEED 
	else:
		velocity = Vector2.ZERO

	move_and_slide() 
	
	# 2. CHAMA A FUNÇÃO DE ANIMAÇÃO (Depois de calcular o movimento)
	_update_animation()


# Detecta estante à frente compensando a assimetria do desenho em 4 direções
func _find_bookshelf_ahead() -> Node:
	var space := get_world_2d().direct_space_state
	
	var origem := global_position
	var distancia_braco := 0.0
	
	# 1. Olhando para a DIREITA 
	if facing.x > 0: 
		origem.x += 18.0  
		distancia_braco = 7.5 
		
	# 2. Olhando para a ESQUERDA 
	elif facing.x < 0: 
		distancia_braco = 15.0 
		
	# 3. Olhando para BAIXO 
	elif facing.y > 0: 
		distancia_braco = 45.0 
		
	# 4. Olhando para CIMA 
	elif facing.y < 0: 
		origem.y -= 15.0 
		distancia_braco = 22.5 
		
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

# 3. A FUNÇÃO QUE TROCA AS ANIMAÇÕES
func _update_animation() -> void:
	# Se o jogador está PARADO (velocity é zero)
	if velocity == Vector2.ZERO:
		if facing.y > 0:
			anim.play("idle_down")
		elif facing.y < 0:
			anim.play("idle_up")
		elif facing.x > 0:
			anim.flip_h = false # Vira a imagem pro lado certo
			anim.play("idle_side")
		elif facing.x < 0:
			anim.flip_h = true  # Espelha a imagem pra esquerda
			anim.play("idle_side")
			
	# Se o jogador está ANDANDO
	else:
		if facing.y > 0:
			anim.play("walk_down")
		elif facing.y < 0:
			anim.play("walk_up")
		elif facing.x > 0:
			anim.flip_h = false
			anim.play("walk_side")
		elif facing.x < 0:
			anim.flip_h = true
			anim.play("walk_side")
