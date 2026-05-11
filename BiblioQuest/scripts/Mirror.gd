extends StaticBody2D

var _is_player_near := false
var rotation_speed := 90.0 # Velocidade do giro em graus por segundo. Ajuste como preferir!

func _ready() -> void:
	add_to_group("mirror")

# O _process roda o tempo todo, mas o espelho só gira se o jogador estiver perto
func _process(delta: float) -> void:
	if _is_player_near:
		# is_action_pressed verifica se a tecla está sendo SEGURADA
		if Input.is_action_pressed("rotate_right"): # Tecla E
			rotation_degrees += rotation_speed * delta
		elif Input.is_action_pressed("rotate_left"): # Tecla Q
			rotation_degrees -= rotation_speed * delta

# Sinal disparado quando algo ENTRA na Area2D
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("O jogador esta perto.")
		_is_player_near = true

# Sinal disparado quando algo SAI da Area2D
func _on_interaction_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("O jogador saiu de perto.")
		_is_player_near = false
