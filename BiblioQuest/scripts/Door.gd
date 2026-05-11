extends StaticBody2D

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
	# Não desativamos mais a colisão! Se desativar, a luz passa reto e a porta convulsiona.
	# _collision.set_deferred("disabled", open) 
	
	var tex_w: float = _sprite.texture.get_width()
	var tex_h: float = _sprite.texture.get_height()
	_sprite.region_enabled = true
	if open:
		_sprite.region_rect = Rect2(tex_w * 0.5, 0.0, tex_w * 0.5, tex_h) # muda pra metade da direita da imagem
	else:
		_sprite.region_rect = Rect2(0.0, 0.0, tex_w * 0.5, tex_h) # muda pra esquerda ( porta fechada )

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
	get_tree().reload_current_scene()
