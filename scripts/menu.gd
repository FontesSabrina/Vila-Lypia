extends Control
class_name MenuPrincipal
## Menu principal — Vila Lypia
## Só decide o que aparece:
##   - sem save -> PainelPrimeiraVez (Iniciar / Pular Tutorial)
##                 + Configurações e Sair do PainelComSave
##   - com save -> PainelComSave completo (Continuar / Novo Jogo / Configurações / Sair)
##                 O "Continuar" abre a tela "Jogos salvos" (3 espaços de save).
## As ações dos botões ficam em cada painel (painel_primeira_vez.gd e
## painel_com_save.gd). O save fica no autoload Salvamento (salvamento.gd).
##
## MÚSICA DO MENU: "Caminho da Vila" toca enquanto o menu está aberto
## (aparece devagar e repete sozinha). Quando a criança começa ou continua
## o jogo, a música some devagar, sem cortar de repente.

## A música do menu e o volume dela.
const MUSICA_MENU := "res://assets/som/Caminho da Vila.mp3"
const VOLUME_MENU_DB := -6.0
const BUS_MUSICA := "Musica"
## Segundos para a música aparecer e para sumir.
const MUSICA_APARECE := 2.0
const MUSICA_SOME := 1.5

## O tocador fica fora do menu (na raiz do jogo) para poder sumir devagar
## mesmo depois que o menu fecha.
var _musica: AudioStreamPlayer

@onready var painel_primeira_vez: Control = get_node_or_null("PainelPrimeiraVez") as Control
@onready var painel_com_save: Control = get_node_or_null("PainelComSave") as Control
@onready var painel_config: Control = get_node_or_null("PainelConfig") as Control


func _ready() -> void:
	# O fundo do menu não pode "comer" o clique dos botões.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if painel_config:
		painel_config.visible = false
	atualizar()

	_tocar_musica()
	# Quando o menu é só escondido (e não fechado), a música também some.
	visibility_changed.connect(_on_visibilidade_mudou)


func _exit_tree() -> void:
	_parar_musica()


## Mostra os painéis certos conforme existe ou não algum jogo salvo.
## (Chamado de novo quando a criança apaga um jogo na tela "Jogos salvos".)
func atualizar() -> void:
	var tem_save := Salvamento.tem_save()
	print(">>> Menu: pronto | tem save = ", tem_save)

	# Mostra só o painel certo (o escondido não recebe clique).
	if painel_primeira_vez:
		painel_primeira_vez.visible = not tem_save
	else:
		push_error("menu: nó 'PainelPrimeiraVez' não encontrado.")

	if painel_com_save:
		# Configurações e Sair aparecem sempre, com ou sem save
		painel_com_save.visible = true
		if painel_com_save.has_method("mostrar_so_config_e_sair"):
			painel_com_save.call("mostrar_so_config_e_sair", not tem_save)
	else:
		push_error("menu: nó 'PainelComSave' não encontrado.")


# ---------------------------------------------------------------- MÚSICA

func _tocar_musica() -> void:
	if _musica and is_instance_valid(_musica):
		return
	if not ResourceLoader.exists(MUSICA_MENU):
		push_warning("menu: música não encontrada: " + MUSICA_MENU)
		return
	var stream = load(MUSICA_MENU)
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = true
	var tocador := AudioStreamPlayer.new()
	tocador.name = "MusicaMenu"
	tocador.stream = stream
	tocador.bus = BUS_MUSICA if AudioServer.get_bus_index(BUS_MUSICA) != -1 else "Master"
	tocador.volume_db = -40.0
	tocador.process_mode = Node.PROCESS_MODE_ALWAYS
	tocador.ready.connect(func():
		tocador.play()
		var t := tocador.create_tween()
		t.tween_property(tocador, "volume_db", VOLUME_MENU_DB, MUSICA_APARECE)
	, CONNECT_ONE_SHOT)
	_musica = tocador
	get_tree().root.add_child.call_deferred(tocador)


func _parar_musica() -> void:
	if _musica == null or not is_instance_valid(_musica):
		_musica = null
		return
	var tocador := _musica
	_musica = null
	if not tocador.is_inside_tree():
		# Ainda nem entrou no jogo: só não deixa começar.
		tocador.ready.connect(tocador.queue_free, CONNECT_ONE_SHOT)
		return
	var t := tocador.create_tween()
	t.tween_property(tocador, "volume_db", -40.0, MUSICA_SOME)
	t.tween_callback(tocador.queue_free)


func _on_visibilidade_mudou() -> void:
	if is_visible_in_tree():
		_tocar_musica()
	else:
		_parar_musica()
