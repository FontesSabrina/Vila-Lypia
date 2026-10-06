extends Sprite2D
class_name BarraFarinha

@onready var farinha = $farinha
@onready var sombra_farinha = $Sombra_farinha

func _ready() -> void:
	# Conecta ao sinal global do GameState para atualizar automaticamente
	if GameState and not GameState.is_connected("farinha_coletada", _on_farinha_coletada):
		GameState.farinha_coletada.connect(_on_farinha_coletada)
		
	atualizar_barra()

func _on_farinha_coletada() -> void:
	atualizar_barra()

func atualizar_barra() -> void:
	if farinha and sombra_farinha:
		farinha.visible = GameState.farinha_pego
		sombra_farinha.visible = not GameState.farinha_pego
