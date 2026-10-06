extends Sprite2D
class_name BarraPinceis
## Barra dos 3 pincéis do Pietro.

@onready var pincel_1 = $pincel01
@onready var pincel_2 = $pincel02
@onready var pincel_3 = $pincel03

@onready var sombra_1 = $Sombra_pincel01
@onready var sombra_2 = $Sombra_pincel02
@onready var sombra_3 = $Sombra_pincel03


func _ready() -> void:
	if is_instance_valid(GameState) and not GameState.pincel_coletado.is_connected(atualizar_barra):
		GameState.pincel_coletado.connect(atualizar_barra)
	atualizar_barra()


func atualizar_barra() -> void:
	if not is_instance_valid(GameState):
		return
	_mostrar(pincel_1, sombra_1, GameState.pincel1_pego)
	_mostrar(pincel_2, sombra_2, GameState.pincel2_pego)
	_mostrar(pincel_3, sombra_3, GameState.pincel3_pego)


func _mostrar(item: CanvasItem, sombra: CanvasItem, pego: bool) -> void:
	if item and sombra:
		item.visible = pego
		sombra.visible = not pego
