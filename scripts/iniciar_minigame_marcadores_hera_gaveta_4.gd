extends Node2D
class_name IniciarMinigameHeraGavetaFitas
## Gaveta 4: aqui estão as fitas da Hera.
## Ao pegar, mostra o aviso e volta ao mapa.
## A entrega é feita clicando na casa da Hera no mapa.

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

@onready var fita: TextureButton = get_node_or_null("Fitas")
@onready var barra_fitas: Sprite2D = get_node_or_null("barra_fitas") as Sprite2D

var _pegou := false


func _ready() -> void:
	if fita:
		if not fita.pressed.is_connected(_on_fitas_pressed):
			fita.pressed.connect(_on_fitas_pressed)
		fita.visible = not GameState.fita_pega


func _on_fitas_pressed() -> void:
	# Trava contra clique duplo (começaria o aviso duas vezes)
	if _pegou or Dialogic.current_timeline:
		return
	_pegou = true

	GameState.pegar_fita()
	if fita:
		fita.visible = false
	if barra_fitas and barra_fitas.has_method("atualizar_barra"):
		barra_fitas.atualizar_barra()

	Dialogic.VAR.Bolo.Hera.Bolo_Hera_Marcadores_Concluido = true

	# Aviso e, depois que o jogador fechar, volta ao mapa
	Dialogic.start("aviso_hera")
	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
