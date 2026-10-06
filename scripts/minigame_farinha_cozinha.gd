extends Node2D
class_name CozinhaHera
## Cozinha da Hera (mini-jogo da farinha). A lupa abre o armário.

const CENA_ARMARIO := "res://scenes/minigame_farinha_armario.tscn"
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"


func _ready() -> void:
	# Pegou a farinha mas a Hera ainda não agradeceu: abre a fala dela
	var concluida: bool = Dialogic.VAR.Bolo.Hera.Farinha_Concluido
	if GameState.farinha_pego and not concluida:
		await get_tree().process_frame
		if not is_inside_tree() or Dialogic.current_timeline:
			return
		Dialogic.start("bolo_hera_02")
		await Dialogic.timeline_ended
		if is_inside_tree():
			get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _on_lupa_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_ARMARIO)
