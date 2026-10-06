extends Sprite2D
class_name BarraVella
## Barra das 3 velas do Enzo.

@onready var vela_01 = $vela_01
@onready var vela_02 = $vela_02
@onready var vela_03 = $vela_03

@onready var sombra_1 = $Sombra_vela_01
@onready var sombra_2 = $Sombra_vela_02
@onready var sombra_3 = $Sombra_vela_03


func _ready() -> void:
	if is_instance_valid(GameState) and not GameState.vela_coletada.is_connected(atualizar_barra):
		GameState.vela_coletada.connect(atualizar_barra)
	atualizar_barra()


func atualizar_barra() -> void:
	if not is_instance_valid(GameState):
		return
	_mostrar(vela_01, sombra_1, GameState.vela1_pego)
	_mostrar(vela_02, sombra_2, GameState.vela2_pego)
	_mostrar(vela_03, sombra_3, GameState.vela3_pego)


func _mostrar(item: CanvasItem, sombra: CanvasItem, pego: bool) -> void:
	if item and sombra:
		item.visible = pego
		sombra.visible = not pego


# Criadas por conexões do editor (Node -> Signals). Ficam vazias de propósito.
# Se você desconectar esses sinais no editor, pode apagar as duas.
func _on_seta_pressed() -> void:
	pass


func _on_vela_02_pressed() -> void:
	pass
