extends Control
class_name BellaBotaoBolo

const CENA_MESA_BOLO := "res://scenes/minigame_bolo_mesa.tscn"
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"
const CENA_PRACA := "res://scenes/praca.tscn"

var _trocando: bool = false

# O botão da Bella. Procura um nó chamado "Bella" e, se não achar,
# usa o "Button" que já está na cena. Se nenhum existir, o script só
# dá um aviso no Output.
@onready var bella: BaseButton = _achar_bella()

func _achar_bella() -> BaseButton:
	for nome in ["Bella", "Button"]:
		var no := get_node_or_null(nome)
		if no is BaseButton:
			return no
	return null

func _ready() -> void:
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)

	if bella == null:
		push_warning("praca_bolo_zoom: nenhum botão 'Bella' ou 'Button' encontrado nesta cena.")
	elif not bella.pressed.is_connected(_on_button_pressed):
		# Só conecta se você não tiver ligado o sinal pelo editor (evita duplicar).
		bella.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if Dialogic.current_timeline:
		return
	# A Bella parada some enquanto a conversa acontece. Isso só tem efeito
	# visível se ela for um nó separado do fundo.
	_mostrar_bella(false)
	Dialogic.start("bolo")

# Fim da conversa: a Bella parada volta (a não ser que a cena esteja trocando).
func _on_timeline_ended() -> void:
	if _trocando:
		return
	_mostrar_bella(true)

func _mostrar_bella(mostrar: bool) -> void:
	if bella:
		bella.visible = mostrar
		bella.disabled = not mostrar

func _on_dialogic_signal(argumento) -> void:
	var comando := str(argumento)
	print(">>> praca_bolo_zoom recebeu sinal: ", comando)

	if comando.begins_with("estilo:"):
		return

	match comando:
		"mudar_para_minigame_bolo":
			_trocar_cena(CENA_MESA_BOLO)
		"voltar_mapa":
			_trocar_cena(CENA_MAPA)
		"ir_para_praca":
			_trocar_cena(CENA_PRACA)

func _trocar_cena(caminho: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(caminho):
		push_error("praca_bolo_zoom: cena não encontrada: " + caminho)
		return
	_trocando = true
	print(">>> Trocando para: ", caminho)
	get_tree().call_deferred("change_scene_to_file", caminho)
