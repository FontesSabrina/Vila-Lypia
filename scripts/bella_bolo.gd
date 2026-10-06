extends Control
class_name BotaoBellaBolo
## Bella de longe na praça do bolo: leva para a cena com zoom.

const CENA_ZOOM := "res://scenes/praca_bolo_zoom.tscn"


func _on_seguindo_pressed() -> void:
	_ir()


func _on_bella_bolo_pressed() -> void:
	_ir()


func _ir() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_ZOOM)
