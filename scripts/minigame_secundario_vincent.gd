extends Node2D
class_name MiniGameLuvas
## Floresta: as 3 luvas do Vincent. Ao achar todas, mostra o aviso e volta ao mapa.

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"
const TIMELINE_AVISO := "aviso_retorno_vincent"

var luvas_encontradas: int = 0
var _terminou := false

@onready var luva_amarela_barra: CanvasItem = get_node_or_null("Luva Amarela2")
@onready var luva_azul_barra: CanvasItem = get_node_or_null("Luva Azul2")
@onready var luva_rosa_barra: CanvasItem = get_node_or_null("Luva Rosa_Vermelha2")

@onready var sombra_amarela: CanvasItem = get_node_or_null("SombraLuva Amarela")
@onready var sombra_azul: CanvasItem = get_node_or_null("SombraLuva Azul")
@onready var sombra_rosa: CanvasItem = get_node_or_null("SombraLuva Rosa_Vermelha")

@onready var luva_amarela_cena: TextureButton = get_node_or_null("Luva Amarela")
@onready var luva_azul_cena: TextureButton = get_node_or_null("Luva Azul")
@onready var luva_rosa_cena: TextureButton = get_node_or_null("Luva Rosa_Vermelha")


func _ready() -> void:
	# Na barra, começam só as sombras
	for sombra in [sombra_amarela, sombra_azul, sombra_rosa]:
		if sombra:
			sombra.visible = true
	for luva in [luva_amarela_barra, luva_azul_barra, luva_rosa_barra]:
		if luva:
			luva.visible = false


func _on_luva_amarela_pressed() -> void:
	_pegar_luva(luva_amarela_cena, sombra_amarela, luva_amarela_barra)


func _on_luva_azul_pressed() -> void:
	_pegar_luva(luva_azul_cena, sombra_azul, luva_azul_barra)


func _on_luva_rosa_vermelha_pressed() -> void:
	_pegar_luva(luva_rosa_cena, sombra_rosa, luva_rosa_barra)


func _pegar_luva(na_cena: TextureButton, sombra: CanvasItem, na_barra: CanvasItem) -> void:
	# Ignora clique numa luva que já foi pega
	if na_cena == null or not na_cena.visible:
		return
	na_cena.visible = false
	if sombra:
		sombra.visible = false
	if na_barra:
		na_barra.visible = true

	luvas_encontradas += 1
	if luvas_encontradas >= 3:
		concluir_minigame()


func concluir_minigame() -> void:
	if _terminou:
		return
	_terminou = true
	print("Todas as luvas foram encontradas!")

	# Nomes REAIS das variáveis (a recompensa é dada depois, no diálogo do Vincent)
	Dialogic.VAR.Bolo.Vincent.Bolo_Vincent_Luvas_Concluido = true
	Dialogic.VAR.Bolo.Vincent.Bolo_Vincent_Em_Andamento = false

	# Aviso pelo NOME: funciona em qualquer pasta
	Dialogic.start(TIMELINE_AVISO)
	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
