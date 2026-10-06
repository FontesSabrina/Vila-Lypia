extends Control
class_name MapaPricipal

# Mantido preca.tscn pois ele realmente existe no seu FileSystem
var cena_anterior: String = "res://scenes/preca.tscn"

# As três versões da praça, de acordo com o capítulo.
const CENA_PRACA_ANTIGA := "res://scenes/praca.tscn"
const CENA_PRACA_BOLO := "res://scenes/praca_bolo.tscn"
const CENA_PRACA_IV := "res://scenes/praca_festa_iv.tscn"

# As ruas: o botão do mapa SEMPRE abre a imagem da rua.
const CENA_RUA_AMOREIRAS := "res://scenes/rua_das_amoreiras.tscn"
const CENA_RUA_IPES := "res://scenes/rua_das_ipes_principal.tscn"

# true enquanto uma conversa com um morador, começada aqui no mapa, está tocando.
# Nessa hora o sinal "ir_para_praca" é ignorado: ao fim da fala, o jogador
# continua no mapa principal.
var _conversa_npc: bool = false

func _ready() -> void:
	# CONECTA O ESCUTADOR DE SINAIS DO DIALOGIC NO MAPA
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)

func _exit_tree() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

# Começa a conversa com um morador a partir do mapa.
# As timelines são chamadas pelo NOME (ex: "Enzo_01"), não pelo caminho:
# assim continuam funcionando em qualquer pasta (ex: res://scenes/dtl_Dialogic).
func _falar_com(timeline: String) -> void:
	if Dialogic.current_timeline:
		return
	_conversa_npc = true
	print(">>> Mapa: conversa com morador: ", timeline)
	Dialogic.start(timeline)

	# Se a timeline não abriu (nome errado ou erro dentro dela), o fim da
	# conversa nunca chega: desmarca aqui para o mapa não ficar travado.
	await get_tree().process_frame
	if not Dialogic.current_timeline:
		_conversa_npc = false
		push_error("mapa: a timeline '" + timeline + "' não abriu. Confira se existe um arquivo " + timeline + ".dtl e se ele abre no Dialogic.")

# Fim da conversa: o jogador continua no mapa principal.
func _on_timeline_ended() -> void:
	if _conversa_npc:
		_conversa_npc = false
		print(">>> Mapa: conversa terminou, continuando no mapa")

# Lê uma variável do Dialogic pelo caminho (ex: "Bolo.Enzo.Velas_Em_Andamento").
# Se o nome não existir, avisa no Output e devolve o valor padrão, sem travar o jogo.
func _ler(caminho: String, padrao = false):
	var atual = Dialogic.current_state_info.get("variables", {})
	for parte in caminho.split("."):
		if atual is Dictionary and atual.has(parte):
			atual = atual[parte]
		else:
			push_warning("mapa: variável do Dialogic não encontrada: " + caminho)
			return padrao
	return atual

# Estado da missão do bolo (Bolo > Estado). 1 = a Bella já explicou o bolo.
func _estado_bolo() -> int:
	return int(_ler("Bolo.Estado", 0))

# true se o jogador já chegou na praça do Capítulo IV (Cena > Praca_IV).
func _praca_iv_liberada() -> bool:
	return _ler("Cena.Praca_IV", false) == true

# Escolhe qual versão da praça mostrar. A do Capítulo IV vem primeiro:
# depois que o jogador chegou nela, o mapa não volta mais para a praca_bolo.
func _cena_da_praca() -> String:
	if _praca_iv_liberada():
		return CENA_PRACA_IV
	if _ler("Cena.Praca_Estado", false) == true:
		return CENA_PRACA_BOLO
	return CENA_PRACA_ANTIGA

func atualizar_estilo_balao_individual(nome_personagem: String) -> void:
	var pontos_amizade: float = 0.0

	match nome_personagem:
		"Enzo": pontos_amizade = float(_ler("Amizade.Enzo", 0))
		"Linna": pontos_amizade = float(_ler("Amizade.Linna", 0))
		"P_Hera", "Hera": pontos_amizade = float(_ler("Amizade.P_Hera", 0))
		"Pietro": pontos_amizade = float(_ler("Amizade.Pietro", 0))
		"Vincent": pontos_amizade = float(_ler("Amizade.Vincent", 0))
		"Xerife": pontos_amizade = float(_ler("Amizade.Xerife", 0))
		_: pontos_amizade = 0.0

	if pontos_amizade <= 3.0:
		Dialogic.Styles.load_style("cinzanovo")
	elif pontos_amizade <= 7.0:
		Dialogic.Styles.load_style("azulnovo")
	else:
		Dialogic.Styles.load_style("verdenovo")

# Captura os sinais emitidos nas escolhas dos diálogos enquanto o jogador está no mapa.
# Esta é agora a ÚNICA fonte de verdade para "sinal -> cena de minigame",
# pra não ter mais destinos divergentes entre Main e MapaPricipal.
func _on_dialogic_signal(argumento: String) -> void:
	var tree = get_tree()
	if not tree:
		return

	if argumento.begins_with("estilo:"):
		var npc = argumento.get_slice(":", 1)
		atualizar_estilo_balao_individual(npc)
		return

	print(">>> Mapa: sinal recebido: ", argumento)

	match argumento:
		"iniciar_minigame_ovos":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_ovos_enzo.tscn")
		"iniciar_minigame_velas_enzo":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_velas_enzo.tscn")
		"iniciar_minigame_novelos":
			tree.call_deferred("change_scene_to_file", "res://scenes/rua_dos_ipes.tscn")
		"minigame_geleia_vincent":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_geleia_vincent.tscn")
		"iniciar_minigame_chocolate":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_chocolate_pietro.tscn")
		"iniciar_minigame_fermento":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_fermento_xerife.tscn")
		"iniciar_minigame_distintivos":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_rua_das_amoreiras_01.tscn")
		"iniciar_minigame_acucar":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_acucar_linna.tscn")
		"iniciar_minigame_farinha":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_farinha_cozinha.tscn")
		"iniciar_minigame_fitas":
			tree.call_deferred("change_scene_to_file", "res://scenes/casa_hera_corredor.tscn")
		"mudar_para_minigame_bolo":
			tree.call_deferred("change_scene_to_file", "res://scenes/minigame_bolo_mesa.tscn")
		"ir_para_praca":
			# Conversa com morador começada no mapa: ao terminar, fica no mapa.
			if _conversa_npc:
				print(">>> Mapa: 'ir_para_praca' ignorado (conversa com morador)")
				return
			# Se o Capítulo IV já começou, a praça é a dele; senão, a de sempre.
			var destino_praca: String = CENA_PRACA_IV if _praca_iv_liberada() else CENA_PRACA_ANTIGA
			tree.call_deferred("change_scene_to_file", destino_praca)
		"voltar_mapa":
			tree.call_deferred("change_scene_to_file", "res://scenes/mapa_pricipal.tscn")
		"ganhar_ovos":
			if is_instance_valid(GameState):
				GameState.pegar_ovos()
		"ganhar_chave":
			if is_instance_valid(GameState):
				GameState.pegar_chave()
		"ganhar_velas":
			if is_instance_valid(GameState):
				GameState.pegar_vela(1)
				GameState.pegar_vela(2)
				GameState.pegar_vela(3)
		"ganhar_fita":
			if is_instance_valid(GameState):
				GameState.pegar_fita()
		"ganhar_moeda":
			if is_instance_valid(GameState):
				GameState.adicionar_moedas(1)
			# Atualiza apenas a interface de texto, caso esteja visível no mapa
			var no_moeda = tree.get_first_node_in_group("hud_moedas")
			if no_moeda and no_moeda.has_method("atualizar_texto"):
				no_moeda.atualizar_texto()

# Botão da Floresta: Abre a cena da floresta
func _on_floresta_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/floresta.tscn")

func _on_casaprefeita_pressed() -> void:
	var erro = get_tree().change_scene_to_file("res://scenes/casaprefeita.tscn")
	if erro != OK:
		print("Erro ao carregar Casa da Prefeita!")

func _on_casaenzo_pressed() -> void:
	if _estado_bolo() == 1:
		_falar_com("bolo_enzo_02")
	else:
		# Pelo caminho completo: o Dialogic não estava achando "Enzo_01" pelo nome
		_falar_com("res://scenes/dtl_Dialogic/Enzo_01.dtl")

func _on_casahera_pressed() -> void:
	if _estado_bolo() == 1:
		_falar_com("bolo_hera_02")
	else:
		_falar_com("P_Hera_01")

func _on_praca_pressed() -> void:
	var cena_destino: String = _cena_da_praca()

	var erro = get_tree().change_scene_to_file(cena_destino)
	if erro != OK:
		print("Erro ao carregar a praça! Caminho tentado: ", cena_destino)

func _on_casalinna_pressed() -> void:
	if _estado_bolo() == 1:
		_falar_com("bolo_linna_02")
	else:
		_falar_com("Linna_01")

func _on_casapietro_pressed() -> void:
	if _estado_bolo() == 1:
		_falar_com("bolo_pietro_02")
	else:
		_falar_com("Pietro_01")

func _on_casavincent_pressed() -> void:
	if _estado_bolo() == 1:
		_falar_com("bolo_vincent_02")
	else:
		_falar_com("Vincent_01")

func _on_casaxerife_pressed() -> void:
	if _estado_bolo() == 1:
		_falar_com("bolo_xerife_02")
	else:
		_falar_com("XerifeP_01")

# Rua das Amoreiras: SEMPRE abre a rua (a imagem).
# O mini-jogo dos distintivos começa pelo diálogo do Xerife
# (sinal "iniciar_minigame_distintivos", tratado em _on_dialogic_signal).
func _on_rua_das_amoreiras_pressed() -> void:
	print(">>> Mapa: abrindo a Rua das Amoreiras")
	get_tree().change_scene_to_file.call_deferred(CENA_RUA_AMOREIRAS)

func _on_botao_fechar_pressed() -> void:
	# Capítulo IV: fechar o mapa volta para a praça do Capítulo IV.
	if _praca_iv_liberada():
		get_tree().change_scene_to_file.call_deferred(CENA_PRACA_IV)
	elif _ler("Cena.Praca_Estado", false) == true or _ler("Bella.Estado_Bella", 0) == 2:
		get_tree().change_scene_to_file.call_deferred(CENA_PRACA_BOLO)
	else:
		get_tree().change_scene_to_file.call_deferred(cena_anterior)

# Rua dos Ipês: SEMPRE abre a rua (a imagem).
# O mini-jogo das velas começa pelo diálogo do Enzo
# (sinal "iniciar_minigame_velas_enzo", tratado em _on_dialogic_signal).
func _on_ruadosipes_pressed() -> void:
	print(">>> Mapa: abrindo a Rua dos Ipês")
	get_tree().change_scene_to_file.call_deferred(CENA_RUA_IPES)
