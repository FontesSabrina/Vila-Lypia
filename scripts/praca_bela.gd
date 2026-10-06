extends Control
class_name BellaPraca
## Praça com a Bella de perto (convites).
## Quando a conversa termina, volta para a praça certa do capítulo.

const CENA_CONVITES := "res://scenes/criacao_convites.tscn"
# Sem "ç" no nome do arquivo: o caminho antigo "praça_bolo.tscn" não existia.
const CENA_PRACA_BOLO := "res://scenes/praca_bolo.tscn"
const CENA_PRACA := "res://scenes/preca.tscn"

var _trocando := false


func _ready() -> void:
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)


func _exit_tree() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)


func _on_amigos_pressed() -> void:
	if not Dialogic.current_timeline:
		Dialogic.start("conversa_bella_dicas")


func _on_dialogic_signal(argument: String) -> void:
	if argument == "iniciar_criacao_convites":
		_trocar(CENA_CONVITES)
	elif argument == "ir_para_praca_bolo":
		_trocar(CENA_PRACA_BOLO)


func _on_timeline_ended() -> void:
	# Se a Bella já passou para o capítulo do bolo, vai para a praça do bolo
	if Dialogic.VAR.Bella.Estado_Bella == 2 or Dialogic.VAR.Cena.Praca_Estado == true:
		_trocar(CENA_PRACA_BOLO)
	else:
		_trocar(CENA_PRACA)


# Só troca uma vez (o sinal e o fim da conversa podem chegar juntos)
func _trocar(caminho: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(caminho):
		push_error("praca_bela: cena não encontrada: " + caminho)
		return
	_trocando = true
	get_tree().change_scene_to_file.call_deferred(caminho)
