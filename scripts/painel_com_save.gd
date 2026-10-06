extends Control
class_name PainelComSave
## Painel do menu quando JÁ existe save.
## Cuida dos próprios botões E faz as próprias ações:
##   - Continuar      -> carrega o save e volta para a cena onde o jogador parou
##   - Novo Jogo      -> apaga o save, fecha o menu e começa a cena_01
##   - Configurações  -> mostra/esconde o nó PainelConfig do menu (se existir)
##   - Sair do Jogo   -> fecha o jogo
## Os botões são ligados aqui pelo código (no _ready).
## O save em si fica no autoload Salvamento (salvamento.gd).

# ---------------------------------------------------------------- AJUSTE AQUI
const TIMELINE_INICIO := "cena_01"

@onready var botao_continuar: BaseButton = get_node_or_null("BotoesComSave/BotaoContinuar") as BaseButton
@onready var botao_novo_jogo: BaseButton = get_node_or_null("BotoesComSave/BotaoNovoJogo") as BaseButton
@onready var botao_configuracoes: BaseButton = get_node_or_null("BotoesComSave/BotaoConfiguracoes") as BaseButton
@onready var botao_sair: BaseButton = get_node_or_null("BotoesComSave/BotaoSair") as BaseButton

var _saindo := false


func _ready() -> void:
	# As áreas vazias do painel não podem "comer" o clique.
	_deixar_clique_passar(self)

	_ligar(botao_continuar, _on_continuar, "BotoesComSave/BotaoContinuar")
	_ligar(botao_novo_jogo, _on_novo_jogo, "BotoesComSave/BotaoNovoJogo")
	_ligar(botao_configuracoes, _on_configuracoes, "BotoesComSave/BotaoConfiguracoes")
	_ligar(botao_sair, _on_sair, "BotoesComSave/BotaoSair")

	print(">>> Painel com save: pronto")


# ---------------------------------------------------------------- AÇÕES

func _on_continuar() -> void:
	if _saindo:
		return
	_saindo = true
	travar(true)
	print(">>> Painel com save: Continuar")
	Salvamento.carregar()


func _on_novo_jogo() -> void:
	if _saindo:
		return
	_saindo = true
	print(">>> Painel com save: Novo Jogo -> ", TIMELINE_INICIO)
	Salvamento.apagar()
	_fechar_menu()
	Dialogic.start(TIMELINE_INICIO)


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
