extends Node2D
class_name CorredorHeraVoltar
## Corredor da Hera, na VOLTA do mini-jogo (depois de pegar as fitas).
## A seta segue para a escada, que leva à sala da Hera.

const CENA_ESCADA := "res://scenes/casa_hera_corredor_escada.tscn"



func _on_seta_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_ESCADA)
