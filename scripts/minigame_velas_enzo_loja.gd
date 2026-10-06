extends Node2D
class_name MinigameVelasEnzoLoja
## Mini-jogo das velas do Enzo (loja): aqui está a vela 1.
## O botão na cena se chama "vela_03", mas conta como a vela 1.
## Quando as 3 velas forem pegas, mostra o aviso e volta ao mapa.

const NUMERO := 1
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"
## Aviso pelo NOME (funciona em qualquer pasta).
const TIMELINE_AVISO := "aviso_retorno_vela"

@onready var barra: Sprite2D = get_node_or_null("barra_vela")
@onready var vela: BaseButton = get_node_or_null("vela_03")

var _pegou := false


func _ready() -> void:
	if vela and GameState.get("vela%d_pego" % NUMERO):
		vela.hide()


func _on_vela_03_pressed() -> void:
	if _pegou:
		return
	_pegou = true
	if vela:
		vela.disabled = true
		vela.hide()

	# pegar_vela() também avisa a barra pelo sinal vela_coletada
	GameState.pegar_vela(NUMERO)
	if barra and barra.has_method("atualizar_barra"):
		barra.atualizar_barra()

	if GameState.todas_velas_coletadas():
		_concluir()


func _concluir() -> void:
	if Dialogic.current_timeline:
		return
	await get_tree().process_frame
	# Nomes REAIS das variáveis (liberam o agradecimento do Enzo)
	Dialogic.VAR.set_variable("Bolo.Enzo.Velas_Concluido", true)
	Dialogic.VAR.set_variable("Bolo.Enzo.Velas_Em_Andamento", false)

	Dialogic.start(TIMELINE_AVISO)
	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _ir(cena: String) -> void:
	get_tree().change_scene_to_file.call_deferred(cena)


func _on_seta_pressed() -> void:
	_ir("res://scenes/minigame_velas_enzo_casa.tscn")
