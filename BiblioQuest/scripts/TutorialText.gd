extends RichTextLabel

@export_multiline var mensagens: Array[String] = []
# Nova lista para guardar as coordenadas exatas de cada texto!
@export var posicoes: Array[Vector2] = []

@export var tempo_por_letra: float = 0.05
@export var tempo_de_leitura: float = 3.0 

func _ready() -> void:
	text = ""
	visible_characters = 0
	
	if mensagens.size() > 0:
		_mostrar_proxima_mensagem(0)

func _mostrar_proxima_mensagem(indice: int) -> void:
	if indice >= mensagens.size():
		return 
		
	# --- A MÁGICA DA POSIÇÃO ACONTECE AQUI ---
	# Verifica se existe uma posição cadastrada para o texto atual
	if indice < posicoes.size():
		position = posicoes[indice]
		
	text = mensagens[indice]
	visible_characters = 0
	modulate.a = 1.0 
	
	var tempo_total := text.length() * tempo_por_letra
	var tween = create_tween()
	
	tween.tween_property(self, "visible_characters", text.length(), tempo_total)
	tween.tween_interval(tempo_de_leitura)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): _mostrar_proxima_mensagem(indice + 1))
