extends Sprite2D
class_name BarraLojaLinna

@onready var mapa = $MapaColorido
@onready var sombra_mapa = $SombraMapa

func _ready() -> void:
	if GameState and not GameState.is_connected("mapa_coletado", _on_mapa_coletado):
		GameState.mapa_coletado.connect(_on_mapa_coletado)
		
	atualizar_barra()

func _on_mapa_coletado() -> void:
	atualizar_barra()

func atualizar_barra() -> void:
	if mapa and sombra_mapa:
		mapa.visible = GameState.mapa_pego
		sombra_mapa.visible = not GameState.mapa_pego
