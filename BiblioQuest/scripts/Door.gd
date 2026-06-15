extends StaticBody2D

@export_category("Configuração de Saída")
## Se for Nível 1 ou 2, coloque o caminho da próxima fase aqui.
@export_file("*.tscn") var next_level_path: String = ""
## Marque isso APENAS na porta do Nível 3!
@export var is_last_level: bool = false

@export var is_entry_door: bool = false
@export var is_exit_door: bool = false

var _is_activated := false
var _tween: Tween
var _base_scale: Vector2

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _trigger: Area2D = $TriggerArea

func _ready() -> void:
	# Salva a escala original (ex: 0.25) para não ficar gigante
	_base_scale = _sprite.scale 
	
	if is_entry_door:
		add_to_group("entry_door")
		_set_open(true)
	elif is_exit_door:
		add_to_group("exit_door")
		_set_open(false)
	
	_trigger.body_entered.connect(_on_trigger_body_entered)

func activate() -> void: # a função que abre a porta de saída 
	if not _is_activated:
		_is_activated = true
		_set_open(true)
		_start_pulse()

func deactivate() -> void:
	if _is_activated:
		_is_activated = false
		_set_open(false)
		if _tween and _tween.is_valid():
			_tween.kill()
		_sprite.scale = _base_scale # Volta para o tamanho normal

func _set_open(open: bool) -> void:
	# --- Lógica Visual (O Sprite) ---
	var tex_w: float = _sprite.texture.get_width()
	var tex_h: float = _sprite.texture.get_height()
	_sprite.region_enabled = true
	
	if open:
		_sprite.region_rect = Rect2(tex_w * 0.5, 0.0, tex_w * 0.5, tex_h) # porta aberta
	else:
		_sprite.region_rect = Rect2(0.0, 0.0, tex_w * 0.5, tex_h) # porta fechada

	# --- Lógica Física (O Fantasma) ---
	# Busca o jogador na cena
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		if open:
			# Se abriu, a porta cria uma exceção e ignora apenas o corpo do jogador!
			add_collision_exception_with(player)
		else:
			# Se fechou, ela volta a bloquear o jogador como uma parede normal.
			remove_collision_exception_with(player)

func _start_pulse() -> void: # a função de pulsação com tween
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_loops()
	# Pulsa aumentando 15% do tamanho BASE, e não indo pra escala 1.0
	_tween.tween_property(_sprite, "scale", _base_scale * 1.15, 0.35)
	_tween.tween_property(_sprite, "scale", _base_scale, 0.35)

func _on_trigger_body_entered(body: Node2D) -> void:
	if is_exit_door and _is_activated and body.is_in_group("player"):
		_advance_level()

func _advance_level() -> void:
	if is_last_level:
		# SE FOR O NÍVEL 3: Mostra a tela de vitória épica!
		var victory_ui = get_tree().get_first_node_in_group("victory_ui")
		if victory_ui:
			victory_ui.trigger_victory()
		else:
			push_error("⚠️ Não encontrei a VictoryUI! Tem certeza que ela está na cena e no grupo 'victory_ui'?")
	else:
		# SE FOR NÍVEL 1 OU 2: Apenas faz o fade suave para a próxima fase
		if next_level_path != "":
			SceneTransition.change_scene(next_level_path)
		else:
			push_error("⚠️ O caminho da próxima fase está vazio na porta!")
