extends StaticBody2D

@export var is_movable: bool = true

func _ready() -> void:
	add_to_group("bookshelf")
	if not is_movable:
		# Deixa a estante fixa um pouco mais escura/cinza!
		$Sprite2D.modulate = Color(0.6, 0.6, 0.6)

## Tenta mover a estante pela quantidade 'delta_pos'.
## Retorna TRUE se moveu, FALSE se estava bloqueada (parede ou outra estante).
func push_by(delta_pos: Vector2) -> bool: # função principal de movimento
	if not is_movable:
		return false
	
	var new_pos := global_position + delta_pos

	if _is_position_clear(new_pos): 
		global_position = new_pos
		return true

	return false  # bloqueado — jogador também deve parar

## Checa via PhysicsShapeQuery se a posição alvo está livre
func _is_position_clear(pos: Vector2) -> bool: # é aqui que a estante  "pensa" antes de se mover
	var col_shape := $CollisionShape2D as CollisionShape2D
	if col_shape == null or col_shape.shape == null:
		return true  # sem shape, considera livre para não travar

	var space := get_world_2d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters2D.new()
	shape_query.shape = col_shape.shape
	shape_query.transform = Transform2D(rotation, pos)
	shape_query.collision_mask = 1 | 4  # Paredes(1) + Estantes(4)
	shape_query.exclude = [self.get_rid()]

	return space.intersect_shape(shape_query).is_empty() # a chamada que verifica o volume retangular da estante
