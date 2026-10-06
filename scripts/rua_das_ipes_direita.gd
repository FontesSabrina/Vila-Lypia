extends Node2D
class_name RuaDasIpesDireita
## Mini-jogo dos novelos da Linna (Rua dos Ipês): aqui está o novelo 1.
## Quando os 4 novelos forem pegos, mostra o aviso e volta ao mapa.

const NUMERO := 1
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"
## Aviso pelo NOME (funciona em qualquer pasta).
const TIMELINE_AVISO := "aviso_retorno_linna"

var novelo: BaseButton = null
var _pegou := false


func _ready() -> void:
	for nome in ["la_01"]:
		novelo = get_node_or_null(str(nome)) as BaseButton
		if novelo:
			break
	if novelo and GameState.get("novelo%d_pego" % NUMERO):
		novelo.hide()


func _pegar_novelo() -> void:
	if _pegou:
		return
	_pegou = true
	if novelo:
		novelo.disabled = true
		novelo.hide()

	# pegar_novelo() também avisa a barra pelo sinal novelo_coletado
	GameState.pegar_novelo(NUMERO)

	if GameState.todos_novelos_coletados():
		_concluir()


func _concluir() -> void:
	if Dialogic.current_timeline:
		return
	await get_tree().process_frame
	Dialogic.VAR.set_variable("Bolo.Linna.Bolo_Linna_Novelos_Concluido", true)
	Dialogic.VAR.set_variable("Bolo.Linna.Bolo_Linna_Novelos_Em_Andamento", false)

	Dialogic.start(TIMELINE_AVISO)
	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _ir(cena: String) -> void:
	get_tree().change_scene_to_file.call_deferred(cena)


func _on_la_01_pressed() -> void:
	_pegar_novelo()


func _on_voltar_ipe_pressed() -> void:
	_ir("res://scenes/rua_dos_ipes.tscn")
