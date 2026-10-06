extends Node2D
class_name IniciarMinigameMarcadoresHera02
## Mini-jogo dos marcadores da Hera, tela 2.

const CENA_PROXIMA := "res://scenes/iniciar_minigame_marcadores_hera_03.tscn"


func _on_lupa_2_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_PROXIMA)
