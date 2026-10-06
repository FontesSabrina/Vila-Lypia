extends Node2D
class_name LojaIV
## Loja da Linna (Capítulo IV, Cena 4): a compra do presente da Prefeita.
##
## 1. A Linna fala (timeline cap4_loja_intro) e, no fim, o catálogo abre.
## 2. Itens que o jogador não consegue pagar ficam apagados.
## 3. Ao clicar num item:
##    - AMIZADE MÁXIMA (Cap4.Excelentes >= 6): os moradores entram na loja
##      ANTES da confirmação (timeline cap4_loja_amizade) -> Kit do Criador de Mundos.
##    - Normal: aparece a confirmação; ao comprar, a Linna embrulha o presente
##      (timeline cap4_loja_compra).
## 4. Depois, a Cena 6 (timeline cap4_anoitecer) e o Capítulo Final.
##
## Nada precisa ser conectado pelo editor: o script liga os botões sozinho.

# ---------------------------------------------------------------- AJUSTE AQUI
const TIMELINE_INTRO := "cap4_loja_intro"
const TIMELINE_COMPRA := "cap4_loja_compra"
const TIMELINE_AMIZADE := "cap4_loja_amizade"
const TIMELINE_ANOITECER := "cap4_anoitecer"
## Cena do Capítulo Final (ainda não existe: troque quando criar).
const CENA_CAPITULO_FINAL := "res://scenes/capitulo_final.tscn"
## Quantas respostas excelentes liberam o evento de amizade máxima.
const EXCELENTES_PARA_EVENTO := 6

## SÓ PARA TESTAR abrindo a loja direto (F6), sem ter jogado antes:
## se o jogador tiver 0 moedas, recebe esta quantidade. Deixe 0 no jogo de verdade.
const MOEDAS_DE_TESTE := 0

## Nome do botão na cena -> nome para a pergunta, preço e código salvo no GameState.
## "curto" é o nome usado na pergunta do painel (mais curto, para caber).
const ITENS := {
	"Caixinha": {"nome": "a Caixinha de Música Comum", "curto": "a Caixinha de Música", "preco": 1, "codigo": "caixinha"},
	"Veludo": {"nome": "a Caixa de Veludo Protetora", "curto": "a Caixa de Veludo", "preco": 3, "codigo": "veludo"},
	"Caderno": {"nome": "o Caderno de Esboços Estrelado", "curto": "o Caderno de Esboços", "preco": 5, "codigo": "caderno"},
}

# ---------------------------------------------------------------- NÓS
@onready var catalogo: CanvasItem = get_node_or_null("Catalogo")
@onready var confirmacao: Control = get_node_or_null("Confirmacao")
# Procurados em qualquer lugar dentro do painel (funciona mesmo se estiverem
# dentro de containers, como MarginContainer / VBoxContainer / HBoxContainer).
@onready var pergunta: Label = _achar_no_painel("Pergunta") as Label
@onready var botao_sim: BaseButton = _achar_no_painel("BotaoSim") as BaseButton
@onready var botao_nao: BaseButton = _achar_no_painel("BotaoNao") as BaseButton

var _botoes := {}          # "Caixinha" -> TextureButton
var _item_escolhido := ""  # item clicado, esperando confirmação
var _ocupado := false      # true durante falas e compra (bloqueia cliques)


func _ready() -> void:
	if catalogo:
		catalogo.visible = false
	_esconder_confirmacao()

	if MOEDAS_DE_TESTE > 0 and GameState.moedas == 0:
		GameState.adicionar_moedas(MOEDAS_DE_TESTE)
		print(">>> Loja: TESTE, recebeu ", MOEDAS_DE_TESTE, " moedas")

	_preparar_itens()
	if botao_sim:
		botao_sim.pressed.connect(_on_sim)
	if botao_nao:
		botao_nao.pressed.connect(_esconder_confirmacao)

	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)

	# Já comprou (ex: voltou pelo save): segue direto para o anoitecer
	if GameState.presente_comprado != "":
		_anoitecer()
		return

	# A Linna fala primeiro; o catálogo abre no fim da fala
	_ocupado = true
	await get_tree().process_frame
	Dialogic.start(TIMELINE_INTRO)
	await Dialogic.timeline_ended
	_abrir_catalogo()


func _achar_no_painel(nome: String) -> Node:
	var painel := get_node_or_null("Confirmacao")
	return painel.find_child(nome, true, false) if painel else null


func _exit_tree() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)


func _on_dialogic_signal(argumento: String) -> void:
	if argumento == "abrir_catalogo":
		_abrir_catalogo()


# ---------------------------------------------------------------- CATÁLOGO

func _preparar_itens() -> void:
	for nome in ITENS:
		var botao := find_child(nome, true, false) as BaseButton
		if botao == null:
			push_error("loja_iv: não achei o botão '" + nome + "' dentro do Catalogo.")
			continue
		_botoes[nome] = botao
		botao.pressed.connect(_on_item_pressed.bind(nome))


func _abrir_catalogo() -> void:
	if catalogo == null or catalogo.visible:
		return
	_atualizar_itens()
	catalogo.visible = true
	_ocupado = false
	print(">>> Loja: catálogo aberto | moedas: ", GameState.moedas)


# Itens que o jogador não consegue pagar ficam apagados (mas continuam
# clicáveis, para mostrar quantas moedas faltam).
func _atualizar_itens() -> void:
	for nome in ITENS:
		var pode := GameState.moedas >= _preco(nome)
		var cor := Color.WHITE if pode else Color(1, 1, 1, 0.4)
		if _botoes.has(nome):
			_botoes[nome].modulate = cor
		var grupo := find_child("Preco" + nome, true, false) as CanvasItem
		if grupo:
			grupo.modulate = cor


func _preco(nome: String) -> int:
	return int(ITENS[nome]["preco"])


# ---------------------------------------------------------------- CLIQUE NO ITEM

func _on_item_pressed(nome: String) -> void:
	if _ocupado or (confirmacao and confirmacao.visible):
		return

	# Amizade máxima: os moradores entram ANTES da confirmação
	if _amizade_maxima():
		_evento_amizade()
		return

	_item_escolhido = nome
	var preco := _preco(nome)
	var falta := preco - GameState.moedas

	if falta > 0:
		_mostrar_confirmacao("Faltam %d %s para este presente." % [falta, _moedas(falta)], false)
	else:
		_mostrar_confirmacao("Comprar %s\npor %d %s?" % [ITENS[nome]["curto"], preco, _moedas(preco)], true)


func _moedas(qtd: int) -> String:
	return "moeda" if qtd == 1 else "moedas"


func _amizade_maxima() -> bool:
	return int(Dialogic.VAR.Cap4.Excelentes) >= EXCELENTES_PARA_EVENTO


# ---------------------------------------------------------------- CONFIRMAÇÃO

func _mostrar_confirmacao(texto: String, pode_comprar: bool) -> void:
	if pergunta:
		pergunta.text = texto
	if botao_sim:
		botao_sim.visible = pode_comprar
	if confirmacao:
		confirmacao.visible = true


func _esconder_confirmacao() -> void:
	_item_escolhido = ""
	if confirmacao:
		confirmacao.visible = false


func _on_sim() -> void:
	if _ocupado or _item_escolhido == "":
		return
	var nome := _item_escolhido
	if not GameState.gastar_moedas(_preco(nome)):
		return
	_ocupado = true
	_esconder_confirmacao()

	GameState.comprar_presente(ITENS[nome]["codigo"])
	print(">>> Loja: comprou ", ITENS[nome]["codigo"])

	# A Linna embrulha o presente
	if catalogo:
		catalogo.visible = false
	Dialogic.start(TIMELINE_COMPRA)
	await Dialogic.timeline_ended
	_anoitecer()


# ---------------------------------------------------------------- EVENTO ESPECIAL

func _evento_amizade() -> void:
	_ocupado = true
	_esconder_confirmacao()
	if catalogo:
		catalogo.visible = false

	# Os moradores juntam os recursos: o jogador não gasta moedas
	GameState.comprar_presente("kit")
	GameState.ganhar_selo_coracao_vila()
	print(">>> Loja: evento de amizade máxima -> Kit do Criador de Mundos")

	Dialogic.start(TIMELINE_AMIZADE)
	await Dialogic.timeline_ended
	_anoitecer()


# ---------------------------------------------------------------- CENA 6

func _anoitecer() -> void:
	_ocupado = true
	if catalogo:
		catalogo.visible = false
	await get_tree().process_frame
	if not is_inside_tree():
		return
	Dialogic.start(TIMELINE_ANOITECER)
	await Dialogic.timeline_ended
	if not is_inside_tree():
		return
	if ResourceLoader.exists(CENA_CAPITULO_FINAL):
		get_tree().change_scene_to_file.call_deferred(CENA_CAPITULO_FINAL)
	else:
		push_warning("loja_iv: o Capítulo Final ainda não existe: " + CENA_CAPITULO_FINAL)
