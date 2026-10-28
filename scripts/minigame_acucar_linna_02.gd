extends Node2D
class_name LinnaAcucar02
## Canto da loja sem açúcar: só a seta de voltar.

const CENA_INICIO := "res://scenes/minigame_acucar_linna.tscn"

@onready var seta_voltar: TextureButton = get_node_or_null("seta_voltar")


func _ready() -> void:
	if seta_voltar:
		if not seta_voltar.pressed.is_connected(_on_seta_voltar_pressed):
			seta_voltar.pressed.connect(_on_seta_voltar_pressed)


func _on_seta_voltar_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_INICIO)
