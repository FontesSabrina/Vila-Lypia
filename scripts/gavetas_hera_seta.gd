extends Node2D
class_name GavetasHera
## Gaveta sem fitas: a seta volta para a escolha das gavetas.

const CENA_GAVETAS := "res://scenes/iniciar_minigame_marcadores_hera_03.tscn"


func _on_seta_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_GAVETAS)
