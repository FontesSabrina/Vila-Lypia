extends Node2D
class_name LinnaAcucarInicio
## Início do mini-jogo do açúcar da Linna: três lupas, cada uma leva a um canto da loja.
## Funciona com as lupas ligadas pelo editor (Node -> Signals) ou não:
## se alguma lupa não tiver conexão do editor, o script liga pelo código.

const CENA_LUPA_1 := "res://scenes/minigame_acucar_linna_01.tscn"
const CENA_LUPA_2 := "res://scenes/minigame_acucar_linna_02.tscn"
const CENA_LUPA_3 := "res://scenes/minigame_acucar_linna_03.tscn"
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

var _trocando := false


func _ready() -> void:
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	_ligar(1, _on_lupa_1_pressed)
	_ligar(2, _on_lupa_2_pressed)
	_ligar(3, _on_lupa_3_pressed)


func _exit_tree() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)


# Clique em cada lupa (pelo editor ou pelo código)
func _on_lupa_1_pressed() -> void:
	_ir(CENA_LUPA_1)


func _on_lupa_2_pressed() -> void:
	_ir(CENA_LUPA_2)


func _on_lupa_3_pressed() -> void:
	_ir(CENA_LUPA_3)


func _on_dialogic_signal(argument: String) -> void:
	if argument == "iniciar_minigame_acucar":
		_ir(CENA_LUPA_1)
	elif argument == "voltar_mapa":
		_ir(CENA_MAPA)


# ---------------------------------------------------------------- AJUDANTES

# Acha a lupa (em qualquer lugar da cena) e liga o clique só se o editor
# ainda não tiver ligado. Assim nunca liga duas vezes.
func _ligar(numero: int, funcao: Callable) -> void:
	var lupa := _achar_lupa(numero)
	if lupa == null:
		push_warning("minigame_acucar_linna: não achei a lupa %d (o clique precisa estar ligado pelo editor)." % numero)
		return
	if not lupa.pressed.is_connected(funcao):
		lupa.pressed.connect(funcao)


func _achar_lupa(numero: int) -> BaseButton:
	for nome in ["Lupa%d" % numero, "Lupa %d" % numero, "lupa%d" % numero, "Lupa_%d" % numero, "lupa_%d" % numero]:
		var no := find_child(nome, true, false)
		if no is BaseButton:
			return no as BaseButton
	return null


func _ir(cena: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(cena):
		push_error("minigame_acucar_linna: cena não encontrada: " + cena)
		return
	_trocando = true
	get_tree().change_scene_to_file.call_deferred(cena)
