extends Node2D
class_name EscadaHera
## Escada da casa da Hera. A seta leva para a sala da Hera.

# Caminho DENTRO do projeto (res://). O caminho antigo (C:/Users/...)
# só funcionava no seu computador e quebrava no .exe e na faculdade.
const CENA_SALA_HERA := "res://scenes/casa_hera_corredor_sala_hera.tscn"


func _on_seta_02_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_SALA_HERA)
