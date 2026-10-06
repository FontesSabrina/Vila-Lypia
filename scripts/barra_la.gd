extends Sprite2D
class_name BarraNovelos
## Barra dos 4 novelos de lã da Linna.

@onready var novelo_1: TextureRect = $la_01
@onready var novelo_2: TextureRect = $la_02
@onready var novelo_3: TextureRect = $la_03
@onready var novelo_4: TextureRect = $la_04

@onready var sombra_1: TextureRect = $Sombra_la_01
@onready var sombra_2: TextureRect = $Sombra_la_02
@onready var sombra_3: TextureRect = $Sombra_la_03
@onready var sombra_4: TextureRect = $Sombra_la_04

## Timeline de aviso para voltar à Linna, pelo NOME (funciona em qualquer pasta).
@export var timeline_notificacao: String = "aviso_retorno_linna"

var notificacao_enviada: bool = false


func _ready() -> void:
	if is_instance_valid(GameState) and not GameState.novelo_coletado.is_connected(atualizar_barra):
		GameState.novelo_coletado.connect(atualizar_barra)
	atualizar_barra()


func atualizar_barra() -> void:
	if not is_instance_valid(GameState):
		return
	_mostrar(novelo_1, sombra_1, GameState.novelo1_pego)
	_mostrar(novelo_2, sombra_2, GameState.novelo2_pego)
	_mostrar(novelo_3, sombra_3, GameState.novelo3_pego)
	_mostrar(novelo_4, sombra_4, GameState.novelo4_pego)


func _mostrar(item: CanvasItem, sombra: CanvasItem, pego: bool) -> void:
	if item and sombra:
		item.visible = pego
		sombra.visible = not pego
