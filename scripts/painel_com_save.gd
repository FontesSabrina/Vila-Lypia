extends Control
class_name PainelComSave
## Painel do menu quando JÁ existe save.
## Cuida dos próprios botões E faz as próprias ações:
##   - Continuar      -> abre a tela "Jogos salvos" (os 3 espaços de save):
##                       a criança escolhe o jogo dela e continua de onde parou
##   - Novo Jogo      -> começa um jogo novo no primeiro espaço livre.
##                       Se os 3 estão ocupados, abre "Jogos salvos" para
##                       escolher qual jogo vai dar lugar ao novo.
##   - Configurações  -> mostra/esconde o nó PainelConfig do menu (se existir)
##   - Sair do Jogo   -> fecha o jogo
## Os botões são ligados aqui pelo código (no _ready).
## O save em si fica no autoload Salvamento (Salvamento.gd), e a tela
## "Jogos salvos" no script jogos_salvos.gd (criada aqui, pelo código).

# ---------------------------------------------------------------- AJUSTE AQUI
const TIMELINE_INICIO := "cena_01"
const SCRIPT_JOGOS_SALVOS := preload("res://scripts/jogos_salvos.gd")

@onready var botao_continuar: BaseButton = get_node_or_null("BotoesComSave/BotaoContinuar") as BaseButton
@onready var botao_novo_jogo: BaseButton = get_node_or_null("BotoesComSave/BotaoNovoJogo") as BaseButton
@onready var botao_configuracoes: BaseButton = get_node_or_null("BotoesComSave/BotaoConfiguracoes") as BaseButton
@onready var botao_sair: BaseButton = get_node_or_null("BotoesComSave/BotaoSair") as BaseButton

var _saindo := false
var _jogos_salvos: PainelJogosSalvos


func _ready() -> void:
	# As áreas vazias do painel não podem "comer" o clique.
	_deixar_clique_passar(self)

	_ligar(botao_continuar, _on_continuar, "BotoesComSave/BotaoContinuar")
	_ligar(botao_novo_jogo, _on_novo_jogo, "BotoesComSave/BotaoNovoJogo")
	_ligar(botao_configuracoes, _on_configuracoes, "BotoesComSave/BotaoConfiguracoes")
	_ligar(botao_sair, _on_sair, "BotoesComSave/BotaoSair")

	_criar_jogos_salvos.call_deferred()
	print(">>> Painel com save: pronto")


# ---------------------------------------------------------------- AÇÕES

func _on_continuar() -> void:
	if _saindo:
		return
	print(">>> Painel com save: Continuar -> Jogos salvos")
	if _jogos_salvos:
		_jogos_salvos.abrir(PainelJogosSalvos.MODO_JOGAR)


func _on_novo_jogo() -> void:
	if _saindo:
		return
	var livre := Salvamento.primeiro_espaco_livre()
	if livre != "":
		_comecar_jogo(livre)
		return
	# Os 3 espaços estão ocupados: a criança escolhe qual jogo substituir.
	print(">>> Painel com save: Novo Jogo -> espaços cheios, escolher qual substituir")
	if _jogos_salvos:
		_jogos_salvos.abrir(PainelJogosSalvos.MODO_SUBSTITUIR)


func _on_configuracoes() -> void:
	print(">>> Painel com save: Configurações")
	var config: Control = null
	if get_parent() != null:
		config = get_parent().get_node_or_null("PainelConfig") as Control
	if config:
		config.visible = not config.visible
	else:
		push_warning("PainelComSave: crie um nó 'PainelConfig' dentro do menu para as configurações.")


func _on_sair() -> void:
	print(">>> Painel com save: Sair do Jogo")
	get_tree().quit()


# ---------------------------------------------------------------- JOGOS SALVOS

## Continua o jogo salvo do espaço escolhido.
func _jogar(espaco: String) -> void:
	if _saindo:
		return
	_saindo = true
	travar(true)
	Salvamento.carregar(espaco)


## Começa um jogo novo no espaço escolhido (apaga o que havia nele).
func _comecar_jogo(espaco: String) -> void:
	if _saindo:
		return
	_saindo = true
	print(">>> Painel com save: Novo Jogo em ", espaco, " -> ", TIMELINE_INICIO)
	# Zera tudo da partida anterior (importante quando o menu é aberto
	# depois dos créditos, com o jogo ainda aberto).
	Salvamento.novo_jogo(espaco)
	_fechar_menu()
	# Primeiro a abertura do livro (6 imagens + música de ninar);
	# no fim ela mesma começa a cena_01 na floresta.
	AberturaLivro.tocar(get_tree(), TIMELINE_INICIO)


## Um jogo foi apagado: o menu confere se ainda existe algum save.
func _on_jogos_mudaram() -> void:
	var menu := get_parent()
	if menu and menu.has_method("atualizar"):
		menu.call("atualizar")


func _criar_jogos_salvos() -> void:
	var menu := get_parent()
	if menu == null:
		return
	_jogos_salvos = SCRIPT_JOGOS_SALVOS.new()
	_jogos_salvos.name = "PainelJogosSalvos"
	menu.add_child(_jogos_salvos)
	_jogos_salvos.jogar.connect(_jogar)
	_jogos_salvos.comecar.connect(_comecar_jogo)
	_jogos_salvos.mudou.connect(_on_jogos_mudaram)


# ---------------------------------------------------------------- AJUDANTES

## Jogo sem save: mostra só Configurações e Sair (Continuar e Novo Jogo somem).
## Com save: mostra os quatro botões.
func mostrar_so_config_e_sair(sim: bool) -> void:
	if botao_continuar:
		botao_continuar.visible = not sim
	if botao_novo_jogo:
		botao_novo_jogo.visible = not sim


## Liga ou desliga os botões (usado para evitar clique duplo).
func travar(sim: bool) -> void:
	for botao in [botao_continuar, botao_novo_jogo, botao_configuracoes, botao_sair]:
		if botao:
			botao.disabled = sim


func _ligar(botao: BaseButton, funcao: Callable, caminho: String) -> void:
	if botao:
		botao.pressed.connect(funcao)
	else:
		push_error("PainelComSave: não achei " + caminho)


# O menu inteiro some da tela.
# - Se o menu está dentro da main (num CanvasLayer criado pelo main.gd),
#   apaga esse CanvasLayer.
# - Se o menu é a própria cena aberta (o jogo começou direto no menu.tscn),
#   só ESCONDE o menu: apagar a cena aberta deixaria o jogo sem cena nenhuma.
func _fechar_menu() -> void:
	var no: Node = get_parent()
	while no != null and not (no is CanvasLayer) and no != get_tree().current_scene:
		no = no.get_parent()
	if no is CanvasLayer:
		no.queue_free()
		return
	var menu: Node = get_parent() if get_parent() != null else self
	if menu is CanvasItem:
		(menu as CanvasItem).visible = false
	print(">>> Menu escondido (o jogo começou direto na cena do menu)")


# Todo Control que NÃO é botão deixa o clique passar (o painel e os containers).
func _deixar_clique_passar(no: Node) -> void:
	if no is Control and not (no is BaseButton):
		(no as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for filho in no.get_children():
		_deixar_clique_passar(filho)


# Criadas pela conexão do editor (Node -> Signals), se você tiver conectado.
# Ficam vazias de propósito: o clique já é tratado pelas funções acima.
func _on_botao_continuar_pressed() -> void:
	pass


func _on_botao_novo_jogo_pressed() -> void:
	pass


func _on_botao_configuracoes_pressed() -> void:
	pass


func _on_botao_sair_pressed() -> void:
	pass
