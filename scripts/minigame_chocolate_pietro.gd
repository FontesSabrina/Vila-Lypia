extends Node2D
class_name PietroCozinha
## Cozinha do Pietro (mini-jogo do chocolate).
## Ao voltar com o chocolate, aparece um aviso e o jogo volta ao mapa.
## A entrega é feita clicando na casa do Pietro no mapa.

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"
const TIMELINE_AVISO := "res://scenes/dtl_Dialogic/aviso_chocolate_pietro.dtl"


func _ready() -> void:
	# Pegou o chocolate e ainda não entregou: aviso e volta ao mapa
	if GameState.chocolate_pego and not Dialogic.VAR.Bolo.Pietro.Bolo_Pietro_Chocolate_Entregue:
		# Espera um quadro para a cena terminar de montar antes da fala
		await get_tree().process_frame
		if not is_inside_tree() or Dialogic.current_timeline:
			return
		Dialogic.start(TIMELINE_AVISO)
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
