extends Sprite2D
class_name Distintivo
## Barra dos 3 distintivos do Xerife.

@onready var distintivo_1 = $distintivo1
@onready var distintivo_2 = $distintivo2
@onready var distintivo_3 = $distintivo3

@onready var sombra_1 = $Sombra_Distintivo1
@onready var sombra_2 = $Sombra_Distintivo2
@onready var sombra_3 = $Sombra_Distintivo3


func _ready() -> void:
	# Atualiza sozinha quando um distintivo é coletado
	if is_instance_valid(GameState) and not GameState.distintivo_coletado.is_connected(atualizar_barra):
		GameState.distintivo_coletado.connect(atualizar_barra)
	atualizar_barra()


func atualizar_barra() -> void:
	if not is_instance_valid(GameState):
		return
	_mostrar(distintivo_1, sombra_1, GameState.distintivo1_pego)
	_mostrar(distintivo_2, sombra_2, GameState.distintivo2_pego)
	_mostrar(distintivo_3, sombra_3, GameState.distintivo3_pego)


func _mostrar(item: CanvasItem, sombra: CanvasItem, pego: bool) -> void:
	if item and sombra:
		item.visible = pego
		sombra.visible = not pego
