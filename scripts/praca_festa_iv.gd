extends Node2D
class_name PracaPresente

# Cena de aproximação da mesa, para onde o jogador vai ao clicar no gazebo.
const CENA_MESA := "res://scenes/mesa_praca_iv.tscn"

# BELLA DA PRAÇA: clicar nela NÃO abre o diálogo aqui. Ela só leva o jogador
# para a mesa e deixa um recado; a mesa (mesa_praca_iv.gd) vê o recado e
# começa a conversa sozinha. A timeline "bella_presente" decide o que ela fala.
# Se a Bella for a cena bella_presente.tscn (com o bella_presente.gd), é o
# script dela que faz isso. Senão, a praça procura um botão com um destes nomes:
const NOS_BELLA := ["bella", "Bella", "bella_botao", "BotaoBella", "bella_presente"]

# Recado para a mesa (o mesmo nome usado no mesa_praca_iv.gd).
const RECADO := "bella_falar_na_mesa"

# Área clicável em cima do gazebo, em pixels da tela (x, y, largura, altura).
# Foi calculada em cima do seu print (tela de 1152 x 648). Se o clique não
# pegar no lugar certo, ligue DEBUG_MOSTRAR_AREA: a área aparece em vermelho
# e você ajusta os números.
const AREA_MESA := Rect2(450, 80, 260, 270)
const DEBUG_MOSTRAR_AREA := false

# Só para testar esta cena sozinha, sem jogar o Capítulo III antes:
# quantos ingredientes o bolo de teste deve ter
# (0 = bolo A, 1 a 3 = B, 4 a 5 = C, 6 = D).
const BOLO_DE_TESTE := 6

# Só para TESTAR: mostra os moradores mesmo sem a conversa da Bella ter
# acontecido (Cap4 > Intro_Feita). Volte para false no jogo de verdade.
const MOSTRAR_MORADORES_SEMPRE := false

# Cada morador: a timeline dele, a variável que marca que ele já conversou,
# os nomes possíveis do botão na cena e se conta para o total de conversas.
const MORADORES := {
	"vincent": {"timeline": "cap4_vincent", "feito": "Cap4.Vincent_Feito", "nos": ["Vincent", "vincent"], "obrigatorio": true},
	"pietro": {"timeline": "cap4_pietro", "feito": "Cap4.Pietro_Feito", "nos": ["Pietro", "pietro"], "obrigatorio": true},
	"hera": {"timeline": "cap4_hera", "feito": "Cap4.Hera_Feito", "nos": ["Hera", "hera"], "obrigatorio": true},
	"enzo": {"timeline": "cap4_enzo", "feito": "Cap4.Enzo_Feito", "nos": ["Enzo", "enzo"], "obrigatorio": true},
	"xerife": {"timeline": "cap4_pepper", "feito": "Cap4.Pepper_Feito", "nos": ["Xerife", "xerife", "Pepper"], "obrigatorio": true},
	"linna": {"timeline": "cap4_linna", "feito": "Cap4.Linna_Feita", "nos": ["Linna", "linna"], "obrigatorio": true},
}

var _trocando: bool = false
var _conversa_ativa: bool = false
var _morador_atual: String = ""

# Botões dos moradores achados na cena (chave -> botão) e se cada um estava
# visível na última atualização (para o fade só rodar quando ele aparece).
var _botoes: Dictionary = {}
var _visiveis: Dictionary = {}

# Botão da Bella na praça e o brilho que chama atenção.
var botao_bella: BaseButton = null
var _tween_bella: Tween = null

# O bolo em cima da mesa do gazebo (a cena "resultadoBolo" dentro desta
# cena). Se o nó não existir, a praça funciona normalmente, sem o bolo.
@onready var resultado_bolo: ResultadoBolo = get_node_or_null("ResultadoBolo") as ResultadoBolo

# Se você preferir, pode criar um nó Button ou TextureButton chamado
# "BotaoMesa" em cima do gazebo. Nesse caso ele é usado no lugar da área.
@onready var botao_mesa: BaseButton = get_node_or_null("BotaoMesa") as BaseButton

func _ready() -> void:
	# A partir daqui, o mapa sempre leva para esta praça (e não para a
	# praca_bolo do Capítulo III). Usa a variável do Dialogic Cena > Praca_IV.
	if "Cena" in Dialogic.VAR and "Praca_IV" in Dialogic.VAR.Cena:
		Dialogic.VAR.Cena.Praca_IV = true
	else:
		push_warning("praca_festa_iv: crie no Dialogic a variável Cena > Praca_IV (tipo bool), senão o mapa não lembra desta praça.")

	_mostrar_bolo_da_mesa()

	if botao_mesa:
		botao_mesa.pressed.connect(_ir_para_mesa)

	_preparar_moradores()
	_preparar_bella()

	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)

	_atualizar_moradores(true)

	# Se o jogador voltou para a praça depois de falar com todos,
	# o cartão continua liberado e a Bella volta a brilhar.
	_checar_fim_das_conversas()
	queue_redraw()

func _exit_tree() -> void:
	# Garante que a mãozinha não fique presa ao sair da cena.
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

# ---------------------------------------------------------------------
# BOLO NA MESA
# ---------------------------------------------------------------------

# Mostra em cima da mesa o mesmo bolo que o jogador fez no Capítulo III.
func _mostrar_bolo_da_mesa() -> void:
	if resultado_bolo == null:
		push_warning("praca_festa_iv: nó 'ResultadoBolo' não encontrado. Arraste a cena resultadoBolo.tscn para dentro desta cena.")
		return

	var total: int = GameState.bolo_ingredientes
	if total < 0:
		# O bolo ainda não foi feito (você abriu esta cena direto para testar).
		print(">>> Capítulo III ainda não jogado: usando o bolo de teste (", BOLO_DE_TESTE, " ingredientes)")
		total = BOLO_DE_TESTE

	resultado_bolo.mostrar_bolo(total)
	print(">>> Bolo na praça: ", total, " ingredientes | bolo ", GameState.letra_do_bolo())

	# O bolo aparece devagar, com um fade.
	resultado_bolo.modulate.a = 0.0
	create_tween().tween_property(resultado_bolo, "modulate:a", 1.0, 0.8)

# ---------------------------------------------------------------------
# VARIÁVEIS DO DIALOGIC
# ---------------------------------------------------------------------

# Lê uma variável do Dialogic pelo caminho (ex: "Cap4.Vincent_Feito").
# Se o nome não existir, avisa no Output e devolve o valor padrão.
func _ler(caminho: String, padrao = false):
	var atual = Dialogic.current_state_info.get("variables", {})
	for parte in caminho.split("."):
		if atual is Dictionary and atual.has(parte):
			atual = atual[parte]
		else:
			push_warning("praca_festa_iv: variável do Dialogic não encontrada: " + caminho)
			return padrao
	return atual

# Grava uma variável do Dialogic pelo caminho (ex: "Cap4.Cartao_Liberado").
func _gravar(caminho: String, valor) -> void:
	if Dialogic.VAR.has(caminho):
		Dialogic.VAR.set_variable(caminho, valor)
	else:
		push_warning("praca_festa_iv: crie no Dialogic a variável " + caminho + " (tipo bool).")

func _intro_feita() -> bool:
	return MOSTRAR_MORADORES_SEMPRE or _ler("Cap4.Intro_Feita", false) == true

func _feito(chave: String) -> bool:
	return _ler(MORADORES[chave]["feito"], false) == true

# ---------------------------------------------------------------------
# MORADORES (botões na praça)
# ---------------------------------------------------------------------

# Acha o botão de cada morador pelo nome e liga o clique. Se o clique já foi
# ligado pelo editor (as funções _on_vincent_pressed etc.), não liga de novo.
func _preparar_moradores() -> void:
	for chave in MORADORES:
		var nome_morador: String = str(chave)
		var botao: BaseButton = null
		for nome in MORADORES[nome_morador]["nos"]:
			var no: Node = get_node_or_null(str(nome))
			if no is BaseButton:
				botao = no as BaseButton
				break

		if botao == null:
			push_warning("praca_festa_iv: não achei o botão do morador '" + nome_morador + "'. Nomes aceitos: " + str(MORADORES[nome_morador]["nos"]))
			continue

		_botoes[nome_morador] = botao
		_visiveis[nome_morador] = false
		botao.visible = false

		var metodo: String = "_on_" + nome_morador + "_pressed"
		var chamada: Callable = Callable(self, metodo)
		if has_method(metodo) and not botao.pressed.is_connected(chamada):
			botao.pressed.connect(chamada)

# Mostra só quem deve aparecer: depois da conversa da Bella, e só quem ainda
# não conversou. Quem está falando agora também fica escondido.
func _atualizar_moradores(animar: bool) -> void:
	var liberado: bool = _intro_feita()
	var indice: int = 0
	for chave in _botoes:
		var nome_morador: String = str(chave)
		var botao: BaseButton = _botoes[nome_morador]
		var em_conversa: bool = _conversa_ativa and nome_morador == _morador_atual
		var deve_aparecer: bool = liberado and not _feito(nome_morador) and not em_conversa

		if deve_aparecer and not _visiveis[nome_morador]:
			if animar:
				_aparecer(botao, 0.25 * indice)
			else:
				botao.visible = true
			indice += 1
		elif not deve_aparecer:
			botao.visible = false
		_visiveis[nome_morador] = deve_aparecer

# O morador aparece com um fade suave, um de cada vez.
func _aparecer(botao: BaseButton, atraso: float) -> void:
	botao.modulate.a = 0.0
	botao.visible = true
	var tween: Tween = create_tween()
	tween.tween_interval(atraso)
	tween.tween_property(botao, "modulate:a", 1.0, 0.4)

# ---------------------------------------------------------------------
# CONVERSAS COM OS MORADORES
# ---------------------------------------------------------------------

func _on_vincent_pressed() -> void:
	_conversar("vincent")

func _on_pietro_pressed() -> void:
	_conversar("pietro")

func _on_hera_pressed() -> void:
	_conversar("hera")

func _on_enzo_pressed() -> void:
	_conversar("enzo")

func _on_xerife_pressed() -> void:
	_conversar("xerife")

func _on_linna_pressed() -> void:
	_conversar("linna")

func _conversar(chave: String) -> void:
	if _conversa_ativa or Dialogic.current_timeline:
		return
	if not _intro_feita():
		return
	if _feito(chave):
		return

	_conversa_ativa = true
	_morador_atual = chave
	# O morador parado some, para aparecer só o retrato do Dialogic.
	if _botoes.has(chave):
		_botoes[chave].visible = false
	print(">>> Praça: iniciando ", MORADORES[chave]["timeline"])
	Dialogic.start(MORADORES[chave]["timeline"])

# Fim de qualquer timeline nesta cena.
func _on_timeline_ended() -> void:
	if _trocando:
		return

	if not _conversa_ativa:
		_atualizar_moradores(true)
		return

	_conversa_ativa = false
	_morador_atual = ""
	_atualizar_moradores(false)
	_checar_fim_das_conversas()

# true quando todos os 6 moradores já conversaram.
func _todos_feitos() -> bool:
	for chave in MORADORES:
		var nome_morador: String = str(chave)
		if MORADORES[nome_morador]["obrigatorio"] and not _feito(nome_morador):
			return false
	return true

# Quando todos já conversaram, libera o cartão e a Bella começa a brilhar.
# Clicando nela, o jogador vai para a mesa, ouve a fala e depois o minigame.
func _checar_fim_das_conversas() -> void:
	if not _todos_feitos():
		return
	if _ler("Cap4.Cartao_Feito", false) == true:
		return
	print(">>> Praça: todos os moradores já conversaram | respostas excelentes: ", _ler("Cap4.Excelentes", 0))
	_gravar("Cap4.Cartao_Liberado", true)
	_destacar_bella()

# ---------------------------------------------------------------------
# BELLA DA PRAÇA (só leva para a mesa)
# ---------------------------------------------------------------------

# Acha o botão da Bella (no próprio nó ou dentro dele) e liga o clique.
# Se o clique já foi ligado pelo editor (_on_bella_pressed), não liga de novo.
func _preparar_bella() -> void:
	# Se a Bella é a cena bella_presente.tscn (com o bella_presente.gd),
	# o próprio script dela cuida do clique. A praça não liga nada.
	if not get_tree().get_nodes_in_group("bella_presente").is_empty():
		print(">>> Praça: a Bella usa o bella_presente.gd, ela mesma cuida do clique")
		return

	for nome in NOS_BELLA:
		var no: Node = get_node_or_null(str(nome))
		if no != null:
			botao_bella = _achar_botao(no)
			if botao_bella != null:
				break

	if botao_bella == null:
		push_warning("praca_festa_iv: não achei o botão da Bella. Use um Button/TextureButton com um destes nomes: " + str(NOS_BELLA))
		return

	var chamada := Callable(self, "_on_bella_pressed")
	if not botao_bella.pressed.is_connected(chamada):
		botao_bella.pressed.connect(chamada)
	print(">>> Praça: Bella pronta | botão: ", botao_bella.name)

func _achar_botao(no: Node) -> BaseButton:
	if no is BaseButton:
		return no as BaseButton
	for filho in no.get_children():
		var achado := _achar_botao(filho)
		if achado != null:
			return achado
	return null

func _on_bella_pressed() -> void:
	if _trocando or _conversa_ativa or Dialogic.current_timeline:
		return
	print(">>> Praça: Bella clicada, indo para a mesa")
	_parar_destaque_bella()
	get_tree().root.set_meta(RECADO, true)
	_ir_para(CENA_MESA)

# Brilho suave piscando na Bella, para o jogador saber que é com ela.
func _destacar_bella() -> void:
	# Bella com o bella_presente.gd: ela mesma faz o brilho.
	get_tree().call_group("bella_presente", "atualizar_destaque")
	if botao_bella == null or _tween_bella != null:
		return
	_tween_bella = create_tween().set_loops()
	_tween_bella.tween_property(botao_bella, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.6)
	_tween_bella.tween_property(botao_bella, "modulate", Color.WHITE, 0.6)

func _parar_destaque_bella() -> void:
	if _tween_bella != null:
		_tween_bella.kill()
		_tween_bella = null
	if botao_bella != null:
		botao_bella.modulate = Color.WHITE

# ---------------------------------------------------------------------
# GAZEBO (clique na mesa)
# ---------------------------------------------------------------------

# Mostra a área clicável em vermelho (só para ajustar, com DEBUG_MOSTRAR_AREA).
func _draw() -> void:
	if DEBUG_MOSTRAR_AREA and botao_mesa == null:
		draw_rect(AREA_MESA, Color(1, 0, 0, 0.3))

# Vira uma mãozinha quando o mouse passa por cima do gazebo.
func _process(_delta: float) -> void:
	if botao_mesa != null or _trocando or _conversa_ativa or Dialogic.current_timeline:
		return
	if AREA_MESA.has_point(get_global_mouse_position()):
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _unhandled_input(event: InputEvent) -> void:
	if botao_mesa != null:
		return
	# Durante uma conversa, o clique para passar a fala não pode abrir a mesa.
	if _conversa_ativa or Dialogic.current_timeline:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if AREA_MESA.has_point(get_global_mouse_position()):
			_ir_para_mesa()

func _ir_para_mesa() -> void:
	if _conversa_ativa or Dialogic.current_timeline:
		return
	_ir_para(CENA_MESA)

func _ir_para(caminho: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(caminho):
		push_error("praca_festa_iv: cena não encontrada: " + caminho)
		return
	_trocando = true
	_parar_destaque_bella()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	get_tree().call_deferred("change_scene_to_file", caminho)
