extends Node2D
class_name VoltarCozinhaPietro
## Telas do mini-jogo do chocolate sem chocolate: a seta volta para a cozinha do Pietro.

const CENA_COZINHA := "res://scenes/minigame_chocolate_pietro.tscn"


func _on_seta_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_COZINHA)
