extends Node2D
class_name PietroCozinha
## Cozinha do Pietro (mini-jogo do chocolate).
## Ao voltar com o chocolate, o Pietro agradece e o jogo volta ao mapa.

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"


func _ready() -> void:
	if GameState.chocolate_pego:
		# Espera um quadro para a cena terminar de montar antes da fala
		await get_tree().process_frame
		if not is_inside_tree() or Dialogic.current_timeline:
			return
		# Chamada pelo NOME: funciona em qualquer pasta
		Dialogic.start("bolo_pietro_02")
		await Dialogic.timeline_ended
		if is_inside_tree():
			get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _on_seta_01_pressed() -> void:
	_ir("res://scenes/minigame_chocolate_pietro_01.tscn")   # Geladeira


func _on_seta_02_pressed() -> void:
	_ir("res://scenes/minigame_chocolate_pietro_02.tscn")   # Armário


func _on_seta_03_pressed() -> void:
	_ir("res://scenes/minigame_chocolate_pietro_03.tscn")   # Balcão/Fogão


func _ir(cena: String) -> void:
	get_tree().change_scene_to_file.call_deferred(cena)
