extends Control
class_name BotaoBella
## Bella de longe na praça: leva para a cena com zoom (praca_bela).

const CENA_ZOOM := "res://scenes/praca_bela.tscn"


func _on_seguindo_pressed() -> void:
	_ir()


func _on_bella_pressed() -> void:
	_ir()


func _ir() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_ZOOM)
