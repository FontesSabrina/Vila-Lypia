extends Node2D
class_name MiniGameFermento
## Mesa do Xerife: aqui está o fermento. Ao pegar, o Xerife fala e o jogo volta ao mapa.

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

var _pegou := false


func _on_fermento_pressed() -> void:
	if _pegou or Dialogic.current_timeline:
		return
	_pegou = true

	# Fase 1 = fermento achado: a timeline do Xerife entrega o fermento
	Dialogic.VAR.Bolo.Xerife.Xerife_Fase = 1

	for nome in ["Fermento", "SombraFermento"]:
		var no := get_node_or_null(nome)
		if no:
			no.hide()

	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree():
		return
	Dialogic.start("bolo_xerife_02")
	await Dialogic.timeline_ended
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
