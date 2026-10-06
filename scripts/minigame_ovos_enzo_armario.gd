extends Node2D
class_name MinigameArmarioEnzo
## Armário do Enzo: aqui está a chave da geladeira.

const CENA_COZINHA := "res://scenes/minigame_ovos_enzo.tscn"

var _pegou := false


func _ready() -> void:
	# Se a chave já foi pega, ela não aparece de novo
	var chave := get_node_or_null("chave")
	if chave and GameState.chave_pega:
		chave.hide()


func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_COZINHA)


func _on_chave_pressed() -> void:
	if _pegou:
		return
	_pegou = true
	GameState.pegar_chave()
	print("Chave pega com sucesso!")

	var chave := get_node_or_null("chave")
	if chave:
		chave.hide()
	get_tree().change_scene_to_file.call_deferred(CENA_COZINHA)
