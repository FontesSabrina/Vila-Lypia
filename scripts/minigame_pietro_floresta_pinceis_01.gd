extends Node2D
class_name FlorestaPietro01
## Floresta do Pietro, tela 1: aqui está o pincel 1.
## Quando os 3 pincéis forem pegos, mostra o aviso e volta ao mapa.

const NUMERO := 1
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

@onready var barra: Sprite2D = get_node_or_null("barra_pincel")
@onready var pincel: Control = get_node_or_null("pincel-01")

var _pegou := false


func _ready() -> void:
	if pincel and GameState.get("pincel%d_pego" % NUMERO):
		pincel.hide()


func _on_pincel_01_pressed() -> void:
	if _pegou:
		return
	_pegou = true

	# pegar_pincel() também avisa a barra pelo sinal pincel_coletado
	GameState.pegar_pincel(NUMERO)
	if pincel:
		pincel.hide()
	if barra and barra.has_method("atualizar_barra"):
		barra.atualizar_barra()

	if GameState.todos_pinceis_coletados():
		_concluir()


func _concluir() -> void:
	if Dialogic.current_timeline:
		return
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree():
		return
	Dialogic.start("aviso_pincel_pietro")
	await Dialogic.timeline_ended
	# Libera o estágio 2C do Pietro (agradecimento e recompensa)
	Dialogic.VAR.Bolo.Pietro.Bolo_Pietro_Pinceis_Concluido = true
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _ir(cena: String) -> void:
	get_tree().change_scene_to_file.call_deferred(cena)


# Seta para AVANÇAR (tela 02)
func _on_seta_02_pressed() -> void:
	_ir("res://scenes/minigame_pietro_floresta_pinceis_02.tscn")


# Seta para VOLTAR (entrada da floresta)
func _on_seta_03_pressed() -> void:
	_ir("res://scenes/minigame_pietro_floresta_pinceis.tscn")
