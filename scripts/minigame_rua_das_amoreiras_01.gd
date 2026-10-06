extends Node2D
class_name RuaDasAmorreiras01
## Rua das Amoreiras, tela 1: aqui está o distintivo 1 do Xerife.
## Quando os 3 distintivos forem pegos (em qualquer ordem), mostra o aviso e volta ao mapa.

const NUMERO := 1
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

@onready var barra: Node2D = get_node_or_null("barra_distintivos")
@onready var distintivo: Control = get_node_or_null("Distintivo01")

var _pegou := false


func _ready() -> void:
	if distintivo and GameState.get("distintivo%d_pego" % NUMERO):
		distintivo.hide()


func _on_distintivo_01_pressed() -> void:
	if _pegou:
		return
	_pegou = true

	# pegar_distintivo() também avisa a barra pelo sinal distintivo_coletado
	GameState.pegar_distintivo(NUMERO)
	if distintivo:
		distintivo.hide()
	if barra and barra.has_method("atualizar_barra"):
		barra.atualizar_barra()

	if GameState.todos_distintivos_coletados():
		_concluir()


func _concluir() -> void:
	if Dialogic.current_timeline:
		return
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	Dialogic.start("aviso_retorno_xerife")
	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _ir(cena: String) -> void:
	get_tree().change_scene_to_file.call_deferred(cena)


func _on_seta_01_pressed() -> void:
	_ir("res://scenes/minigame_rua_das_amoreiras_02.tscn")
