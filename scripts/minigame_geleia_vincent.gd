extends Node2D
class_name MiniGameGeleia
## Depósito do Vincent: aqui está a geleia. Ao pegar, o Vincent comemora e o jogo volta ao mapa.

const MAPA_PRINCIPAL: String = "res://scenes/mapa_pricipal.tscn"
const TIMELINE_CONCLUSAO: String = "bolo_vincent_02"

@onready var geleia_area: TextureButton = get_node_or_null("GeleiaArea")
@onready var geleia_hud: CanvasItem = get_node_or_null("Geleia")
@onready var sombra_geleia_hud: CanvasItem = get_node_or_null("SombraGeleia")

var _pegou := false


func _ready() -> void:
	# Na barra, começa só a sombra
	if sombra_geleia_hud:
		sombra_geleia_hud.visible = true
	if geleia_hud:
		geleia_hud.visible = false


func _on_geleia_area_pressed() -> void:
	concluir_minigame()


func concluir_minigame() -> void:
	if _pegou or Dialogic.current_timeline:
		return
	_pegou = true

	if geleia_area:
		geleia_area.visible = false
	if sombra_geleia_hud:
		sombra_geleia_hud.visible = false
	if geleia_hud:
		geleia_hud.visible = true

	GameState.pegar_geleia()
	# A mesa do bolo conta os ingredientes sozinha (não precisa somar aqui)
	Dialogic.VAR.Bolo.Vincent.Ingrediente_Vincent = true
	print("Geleia encontrada!")

	Dialogic.start(TIMELINE_CONCLUSAO)
	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(MAPA_PRINCIPAL)
