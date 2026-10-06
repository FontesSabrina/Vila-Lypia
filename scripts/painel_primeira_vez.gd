extends Control
class_name PainelPrimeiraVez
## Painel do menu quando ainda NÃO existe save.
## Cuida dos próprios botões E faz as próprias ações:
##   - Iniciar a Aventura -> fecha o menu e começa a timeline cena_01
##   - Pular Tutorial     -> vai para o mapa
## Os botões são ligados aqui pelo código (no _ready).

# ---------------------------------------------------------------- AJUSTE AQUI
const TIMELINE_INICIO := "cena_01"
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"

@onready var botao_iniciar: BaseButton = get_node_or_null("VBoxContainer/BotaoIniciar") as BaseButton
@onready var botao_pular_tutorial: BaseButton = get_node_or_null("VBoxContainer/BotaoPularTutorial") as BaseButton

var _saindo := false


func _ready() -> void:
	# As áreas vazias do painel não podem "comer" o clique.
	_deixar_clique_passar(self)

	if botao_iniciar:
		botao_iniciar.pressed.connect(_on_iniciar)
	else:
		push_error("PainelPrimeiraVez: não achei VBoxContainer/BotaoIniciar")

	if botao_pular_tutorial:
		botao_pular_tutorial.pressed.connect(_on_pular_tutorial)
	else:
		push_error("PainelPrimeiraVez: não achei VBoxContainer/BotaoPularTutorial")

	print(">>> Painel primeira vez: pronto")


# ---------------------------------------------------------------- AÇÕES

func _on_iniciar() -> void:
	if _saindo:
		return
	_saindo = true
	print(">>> Painel primeira vez: Iniciar a Aventura -> ", TIMELINE_INICIO)
	_fechar_menu()
	Dialogic.start(TIMELINE_INICIO)


func _on_pular_tutorial() -> void:
	if _saindo:
		return
	_saindo = true
	print(">>> Painel primeira vez: Pular Tutorial -> mapa")
	if is_instance_valid(GameState):
		GameState.pegar_mapa()
	_ir_para(CENA_MAPA)


# ---------------------------------------------------------------- AJUDANTES

## Liga ou desliga os botões (usado para evitar clique duplo).
func travar(sim: bool) -> void:
	if botao_iniciar:
		botao_iniciar.disabled = sim
	if botao_pular_tutorial:
		botao_pular_tutorial.disabled = sim


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


func _ir_para(caminho: String) -> void:
	if not ResourceLoader.exists(caminho):
		push_error("PainelPrimeiraVez: cena não encontrada: " + caminho)
		_saindo = false
		return
	travar(true)
	get_tree().call_deferred("change_scene_to_file", caminho)


# Todo Control que NÃO é botão deixa o clique passar (o painel e os containers).
func _deixar_clique_passar(no: Node) -> void:
	if no is Control and not (no is BaseButton):
		(no as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for filho in no.get_children():
		_deixar_clique_passar(filho)


# Criadas pela conexão do editor (Node -> Signals). Ficam vazias de propósito:
# o clique já é tratado em _on_iniciar() e _on_pular_tutorial().
func _on_botao_iniciar_pressed() -> void:
	pass


func _on_botao_pular_tutorial_pressed() -> void:
	pass
