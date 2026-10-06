extends Node2D
class_name PietroCozinha01
## Geladeira do Pietro: aqui está o chocolate.

const CENA_COZINHA := "res://scenes/minigame_chocolate_pietro.tscn"

@onready var barra: Node2D = get_node_or_null("barra_chocolate")

var _pegou := false


func _ready() -> void:
	var chocolate := get_node_or_null("chocolate")
	if chocolate and GameState.chocolate_pego:
		chocolate.hide()


func _on_chocolate_pressed() -> void:
	if _pegou:
		return
	_pegou = true

	# pegar_chocolate() também avisa a barra pelo sinal chocolate_coletado
	GameState.pegar_chocolate()

	var chocolate := get_node_or_null("chocolate")
	if chocolate:
		chocolate.hide()
	if barra and barra.has_method("atualizar_barra"):
		barra.atualizar_barra()

	Dialogic.VAR.set_variable("Bolo.Pietro.Ingrediente_Pietro", true)

	# Volta para a cozinha, onde o Pietro agradece
	get_tree().change_scene_to_file.call_deferred(CENA_COZINHA)
