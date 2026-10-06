extends Control
class_name MapaBotao
## Botão do mapa (canto da tela): abre o mapa principal.

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

## true = o mapa já nasce liberado na gameplay da praça.
var mapa_liberado: bool = true


func liberar_mapa() -> void:
	mapa_liberado = true
	visible = true
	print("Mapa liberado com sucesso para a gameplay!")


func _on_mapa_pressed() -> void:
	if mapa_liberado:
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
	else:
		print("O mapa ainda está bloqueado durante o tutorial!")
