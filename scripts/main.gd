extends Node2D
class_name Main

# Pré-carrega a cena do menu
const MenuScene = preload("res://scenes/menu.tscn")

const CENA_MINIJOGO_LINNA := "res://scenes/hidden_object_linna.tscn"
## Praça para onde o fim do tutorial (final_tutorial -> "ir_para_praca") leva.
const CENA_PRACA := "res://scenes/praca.tscn"

var _trocando := false


func _ready() -> void:
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)

	# Se o jogador já pegou o mapa da Linna, pula o menu e vai direto para a conversa com a Bella
	if GameState and GameState.mapa_pego:
		Dialogic.start("final_tutorial")
	else:
		var menu_instancia = MenuScene.instantiate()
		var camada_ui = CanvasLayer.new()
		add_child(camada_ui)
		camada_ui.add_child(menu_instancia)


func _exit_tree() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)


func atualizar_estilo_balao_individual(nome_personagem: String) -> void:
	var pontos_amizade: float = 0.0

	match nome_personagem:
		"Enzo": pontos_amizade = float(Dialogic.VAR.Amizade.Enzo)
		"Linna": pontos_amizade = float(Dialogic.VAR.Amizade.Linna)
		"P_Hera", "Hera": pontos_amizade = float(Dialogic.VAR.Amizade.P_Hera)
		"Pietro": pontos_amizade = float(Dialogic.VAR.Amizade.Pietro)
		"Vincent": pontos_amizade = float(Dialogic.VAR.Amizade.Vincent)
		"Xerife": pontos_amizade = float(Dialogic.VAR.Amizade.Xerife)
		_: pontos_amizade = 0.0

	if pontos_amizade <= 3.0:
		Dialogic.Styles.load_style("cinzanovo")
	elif pontos_amizade <= 7.0:
		Dialogic.Styles.load_style("azulnovo")
	else:
		Dialogic.Styles.load_style("verdenovo")


func _on_dialogic_signal(argument: String) -> void:
	print(">>> SINAL DO DIALOGIC CAPTURADO NO MAIN: ", argument)

	if argument.begins_with("estilo:"):
		var npc = argument.get_slice(":", 1)
		atualizar_estilo_balao_individual(npc)

	elif argument == "iniciar_gameplay":
		_trocar_cena(CENA_MINIJOGO_LINNA)

	elif argument == "ir_para_praca":
		_trocar_cena(CENA_PRACA)

	elif argument == "ganhar_ovos":
		if is_instance_valid(GameState):
			GameState.pegar_ovos()

	elif argument == "ganhar_chave":
		if is_instance_valid(GameState):
			GameState.pegar_chave()

	elif argument == "ganhar_velas":
		if is_instance_valid(GameState):
			GameState.pegar_vela(1)
			GameState.pegar_vela(2)
			GameState.pegar_vela(3)

	elif argument == "ganhar_fita":
		if is_instance_valid(GameState):
			GameState.pegar_fita()

	elif argument == "ganhar_moeda":
		if is_instance_valid(GameState):
			GameState.adicionar_moedas(1)

		var no_moeda = get_tree().get_first_node_in_group("hud_moedas")
		if no_moeda and no_moeda.has_method("adicionar_moeda"):
			no_moeda.adicionar_moeda(1)


# Troca de cena como na versão antiga: a conversa NÃO é fechada, porque a
# timeline pode continuar de propósito na cena nova.
func _trocar_cena(caminho: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(caminho):
		push_error("main: cena não encontrada: " + caminho + " (ajuste a constante no topo do main.gd)")
		return
	_trocando = true

	print(">>> Main: indo para ", caminho)
	get_tree().change_scene_to_file.call_deferred(caminho)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("Clique detectado na tela na posição: ", event.position)
