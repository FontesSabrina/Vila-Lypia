extends Node2D
class_name CorredorHera
## Corredor da casa da Hera. A seta leva para o mini-jogo dos marcadores.

const CENA_MARCADORES := "res://scenes/iniciar_minigame_marcadores_hera_01.tscn"


func _on_seta_01_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_MARCADORES)
