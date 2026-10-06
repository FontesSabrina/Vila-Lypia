extends Node2D
class_name FlorestaPeitroInicio
## Entrada da floresta do Pietro (mini-jogo dos pincéis).

const CENA_TELA_1 := "res://scenes/minigame_pietro_floresta_pinceis_01.tscn"


func _on_senta_01_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_TELA_1)
