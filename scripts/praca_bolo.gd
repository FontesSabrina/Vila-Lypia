extends Control
class_name PracaBolo

const CENA_MESA_BOLO := "res://scenes/minigame_bolo_mesa.tscn"
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"
const CENA_PRACA := "res://scenes/praca.tscn"

var _trocando: bool = false

func _ready() -> void:
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(argumento) -> void:
	var comando := str(argumento)

	# O estilo do balão já vem definido na própria timeline ([style name=...]).
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
		push_error("PracaBolo: cena não encontrada: " + caminho)
		return
	_trocando = true
	get_tree().call_deferred("change_scene_to_file", caminho)
