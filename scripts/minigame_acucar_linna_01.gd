extends Sprite2D
class_name LinnaAcucar01
## Canto da loja onde está o açúcar. Ao pegar, a Linna agradece e o jogo volta ao mapa.

const CENA_INICIO := "res://scenes/minigame_acucar_linna.tscn"
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

@onready var seta_voltar: TextureButton = get_node_or_null("seta_voltar")
@onready var acucar: TextureButton = get_node_or_null("acucar")
@onready var barra_acucar: Sprite2D = get_node_or_null("barra_açucar") as Sprite2D

var _pegou := false


func _ready() -> void:
	if seta_voltar:
		seta_voltar.pressed.connect(_on_seta_voltar_pressed)
	if acucar:
		acucar.pressed.connect(_on_acucar_pressed)
		acucar.visible = not GameState.acucar_pego


func _on_seta_voltar_pressed() -> void:
	if _pegou:
		return
	get_tree().change_scene_to_file.call_deferred(CENA_INICIO)


func _on_acucar_pressed() -> void:
	# Trava contra clique duplo (começaria a conversa duas vezes)
	if _pegou or Dialogic.current_timeline:
		return
	_pegou = true

	GameState.pegar_acucar()
	if acucar:
		acucar.visible = false
	if barra_acucar and barra_acucar.has_method("atualizar_barra"):
		barra_acucar.atualizar_barra()

	Dialogic.VAR.set_variable("Bolo.Linna.Bolo_Linna_Acucar_Concluido", true)
	Dialogic.start("bolo_linna_02")

	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
