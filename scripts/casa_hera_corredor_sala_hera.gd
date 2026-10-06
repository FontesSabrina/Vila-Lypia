extends Node2D
class_name SalaHera
## Sala da Hera (fim do mini-jogo dos marcadores).
## A seta marca os marcadores como concluídos e abre a conversa da Hera.

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

var _conversando := false


func _ready() -> void:
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)


func _exit_tree() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)


func _on_seta_3_pressed() -> void:
	if _conversando or Dialogic.current_timeline:
		return
	_conversando = true
	# Atende à condição do estágio 2C da timeline bolo_hera_02
	Dialogic.VAR.Bolo.Hera.Bolo_Hera_Marcadores_Concluido = true
	Dialogic.start("bolo_hera_02")


func _on_dialogic_signal(argument: String) -> void:
	if argument == "voltar_mapa":
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)

	elif argument == "ganhar_moeda":
		if is_instance_valid(GameState):
			GameState.adicionar_moedas(1)

		var no_moeda = get_tree().get_first_node_in_group("hud_moedas")
		if no_moeda and no_moeda.has_method("adicionar_moeda"):
			no_moeda.adicionar_moeda(1)
		elif no_moeda and no_moeda.has_method("atualizar_texto"):
			no_moeda.atualizar_texto()
