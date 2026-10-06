extends Node2D
class_name HiddenObjectLinna
## Tutorial — procurar o mapa na loja da Linna.
## Ao clicar no mapa: marca no GameState, esconde o mapa, atualiza a barra
## e volta para a "main", que dispara a timeline "final_tutorial".

const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"
const CENA_MAIN := "res://scenes/main.tscn"

# Tipos abertos (BaseButton / Node) para não quebrar se o tipo do nó mudar.
@onready var mapa_btn: BaseButton = get_node_or_null("mapa") as BaseButton
@onready var barra: Node = get_node_or_null("barra_loja_linna")

var _mapa_clicado := false


func _ready() -> void:
	if mapa_btn == null:
		push_error("hidden_object_linna: não achei o botão 'mapa' (precisa ser Button ou TextureButton).")
	if barra == null:
		push_warning("hidden_object_linna: não achei o nó 'barra_loja_linna'.")

	if GameState.mapa_pego and mapa_btn:
		mapa_btn.hide()

	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)

	if mapa_btn and not mapa_btn.pressed.is_connected(_on_mapa_pressed):
		mapa_btn.pressed.connect(_on_mapa_pressed)

	print(">>> Loja da Linna: pronta | mapa já pego: ", GameState.mapa_pego, " | conversa aberta: ", Dialogic.current_timeline != null)


func _exit_tree() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)


func _on_dialogic_signal(argument: String) -> void:
	if argument == "voltar_mapa":
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _on_mapa_pressed() -> void:
	if _mapa_clicado:
		return
	_mapa_clicado = true
	print(">>> Loja da Linna: o jogador encontrou o mapa!")

	# 1. Salva no GameState que o mapa foi pego
	if is_instance_valid(GameState):
		GameState.pegar_mapa()

	# 2. Esconde o mapa na tela
	if mapa_btn:
		mapa_btn.hide()

	# 3. Atualiza a barra de itens
	if barra and barra.has_method("atualizar_barra"):
		barra.atualizar_barra()

	# 4. Aguarda 0.5 segundos e retorna para a cena 'main'
	# (O main vai ler que o mapa foi pego e disparar a timeline 'final_tutorial'.)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file.call_deferred(CENA_MAIN)
