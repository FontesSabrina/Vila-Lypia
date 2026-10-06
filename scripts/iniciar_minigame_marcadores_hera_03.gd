extends Node2D
class_name IniciarMinigameMarcadoresHera03
## Mini-jogo dos marcadores da Hera, tela 3: escolha das 4 gavetas.
## As fitas estão na gaveta 4 (lupa 5).

const PASTA := "res://scenes/iniciar_minigame_marcadores_hera_gaveta_"


func _on_lupa_4_pressed() -> void:
	_abrir_gaveta(2)


func _on_lupa_5_pressed() -> void:
	_abrir_gaveta(4)


func _on_lupa_6_pressed() -> void:
	_abrir_gaveta(3)


func _on_lupa_7_pressed() -> void:
	_abrir_gaveta(1)


func _abrir_gaveta(numero: int) -> void:
	get_tree().change_scene_to_file.call_deferred(PASTA + str(numero) + ".tscn")
