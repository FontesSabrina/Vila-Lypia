extends Node2D
class_name ArmarioFarinha
## Armário da Hera: aqui está a farinha. Ao pegar, a Hera agradece e o jogo volta ao mapa.

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

@onready var barra_farinha = get_node_or_null("UI/barra_farinha")

var _pegou := false


func _ready() -> void:
	var pote := get_node_or_null("Farinha")
	if pote and GameState.farinha_pego:
		pote.hide()


func _on_farinha_pressed() -> void:
	if _pegou or Dialogic.current_timeline:
		return
	_pegou = true

	GameState.pegar_farinha()
	var pote := get_node_or_null("Farinha")
	if pote:
		pote.hide()
	if barra_farinha and barra_farinha.has_method("atualizar_barra"):
		barra_farinha.atualizar_barra()

	# Nomes REAIS das variáveis (a mesa do bolo conta a farinha por Farinha_Concluido)
	Dialogic.VAR.set_variable("Bolo.Hera.Farinha_Concluido", true)
	Dialogic.VAR.set_variable("Bolo.Hera.Em_Andamento", false)

	Dialogic.start("bolo_hera_02")
	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
