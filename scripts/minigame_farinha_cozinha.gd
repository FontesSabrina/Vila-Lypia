extends Node2D
class_name CozinhaHera
## Cozinha da Hera (mini-jogo da farinha). A lupa abre o armário.

const CENA_ARMARIO := "res://scenes/minigame_farinha_armario.tscn"
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"
const TIMELINE_AVISO := "res://scenes/dtl_Dialogic/aviso_farinha_hera.dtl"


func _ready() -> void:
	# Pegou a farinha mas ainda não entregou: mostra o aviso e volta ao mapa
	# (a entrega é feita clicando na casa da Hera no mapa)
	var entregue: bool = Dialogic.VAR.Bolo.Hera.Excelente_Mostrado
	if GameState.farinha_pego and not entregue:
		await get_tree().process_frame
		if not is_inside_tree() or Dialogic.current_timeline:
			return
		Dialogic.start(TIMELINE_AVISO)
		await Dialogic.timeline_ended
		if is_inside_tree():
			get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _on_lupa_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_ARMARIO)
