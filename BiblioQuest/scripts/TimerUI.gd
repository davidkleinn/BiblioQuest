extends Control

@export_category("Assets do Timer")
@export var numbers_texture: Texture2D

@export var columns: int = 5
@export var rows: int = 2

var number_atlases: Array[Texture2D] = []

@onready var min_10: TextureRect = $DigitsContainer/Min10
@onready var min_1: TextureRect = $DigitsContainer/Min1
@onready var sec_10: TextureRect = $DigitsContainer/Sec10
@onready var sec_1: TextureRect = $DigitsContainer/Sec1

func _ready() -> void:
	if numbers_texture == null:
		push_error("⚠️ Arraste a imagem Timer_Numbers para o Inspector!")
		return
		
	var char_width := numbers_texture.get_width() / columns
	var char_height := numbers_texture.get_height() / rows
	
	for i in range(10):
		var col: int = i % columns 
		var row: int = i / columns 
		
		var x_pos := col * char_width
		var y_pos := row * char_height
		
		var novo_atlas := AtlasTexture.new()
		novo_atlas.atlas = numbers_texture
		novo_atlas.region = Rect2(x_pos, y_pos, char_width, char_height)
		number_atlases.append(novo_atlas)

func update_time(time_left: float) -> void:
	if number_atlases.size() < 10:
		return
		
	var total_seconds := int(ceil(time_left))
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	
	var min_str := "%02d" % minutes
	var sec_str := "%02d" % seconds
	
	min_10.texture = number_atlases[int(min_str[0])]
	min_1.texture = number_atlases[int(min_str[1])]
	sec_10.texture = number_atlases[int(sec_str[0])]
	sec_1.texture = number_atlases[int(sec_str[1])]
