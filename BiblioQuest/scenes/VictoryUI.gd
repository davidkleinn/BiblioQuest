extends Control

@export_file("*.tscn") var next_level_path: String = "res://scenes/Level2.tscn"

@onready var dark_bg: ColorRect = $DarkBackground
@onready var buttons_container: VBoxContainer = $ButtonsContainer

func _ready() -> void:
	hide()
	$ButtonsContainer/BtnVictory.pressed.connect(_on_victory_pressed)
	$ButtonsContainer/BtnMenu.pressed.connect(_on_menu_pressed)
	$ButtonsContainer/BtnExit.pressed.connect(_on_exit_pressed)

func trigger_victory() -> void:
	show()
	get_tree().paused = true 
	
	dark_bg.modulate.a = 0.0 
	var pos_final_y = buttons_container.position.y
	buttons_container.position.y += 200 
	buttons_container.modulate.a = 0.0
	
	var tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(dark_bg, "modulate:a", 1.0, 0.5)
	tween.tween_property(buttons_container, "position:y", pos_final_y, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(buttons_container, "modulate:a", 1.0, 0.5)

# --- ANIMAÇÃO DE CLIQUE ---
func animate_click_and_execute(button: TextureButton, action: Callable) -> void:
	$ButtonsContainer/BtnVictory.disabled = true
	$ButtonsContainer/BtnMenu.disabled = true
	$ButtonsContainer/BtnExit.disabled = true
	
	button.pivot_offset = button.size / 2
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", Vector2(0.85, 0.85), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	action.call()

# --- AÇÕES DOS BOTÕES ---
func _on_victory_pressed() -> void:
	animate_click_and_execute($ButtonsContainer/BtnVictory, _do_next_level)

func _do_next_level() -> void:
	get_tree().paused = false
	# Se tiver um caminho definido para a próxima fase, vai pra ela
	if next_level_path != "":
		get_tree().change_scene_to_file(next_level_path)
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_menu_pressed() -> void:
	animate_click_and_execute($ButtonsContainer/BtnMenu, _do_menu)

func _do_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn") 

func _on_exit_pressed() -> void:
	animate_click_and_execute($ButtonsContainer/BtnExit, _do_exit)

func _do_exit() -> void:
	get_tree().quit()
