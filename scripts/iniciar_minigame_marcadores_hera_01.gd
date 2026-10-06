extends Node2D
class_name IniciarMinigameMarcadoresHera01
## Mini-jogo dos marcadores da Hera, tela 1.

const CENA_PROXIMA := "res://scenes/iniciar_minigame_marcadores_hera_02.tscn"


func _on_lupa_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_PROXIMA)
