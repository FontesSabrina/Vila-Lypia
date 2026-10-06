extends Node2D
class_name MinigameGeladeira
## Geladeira do Enzo: aqui estão os ovos.

const CENA_COZINHA := "res://scenes/minigame_ovos_enzo.tscn"

var _pegou := false


func _ready() -> void:
	var ovo := get_node_or_null("ovo")
	if ovo and GameState.ovos_pego:
		ovo.hide()


func _on_ovo_pressed() -> void:
	if _pegou:
		return
	_pegou = true
	GameState.pegar_ovos()
	print("Ovo coletado com sucesso!")

	var ovo := get_node_or_null("ovo")
	if ovo:
		ovo.hide()
	get_tree().change_scene_to_file.call_deferred(CENA_COZINHA)
