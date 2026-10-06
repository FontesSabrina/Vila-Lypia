extends Node
## (Sem class_name de propósito: autoload não precisa, e um class_name aqui
## dá conflito se existir outra cópia deste arquivo no projeto.)
## Salvamento — autoload (Projeto > Configurações do Projeto > Globals > Autoload)
## Nome do autoload: Salvamento
##
## Salva SOZINHO:
##   - toda vez que o jogador entra numa cena nova (menos as de CENAS_SEM_SAVE);
##   - quando o jogador fecha a janela do jogo.
## O save guarda, num slot do Dialogic:
##   - as variáveis do Dialogic (capítulos, amizades...);
##   - todas as variáveis do GameState (moedas, itens, bolo...);
##   - a cena em que o jogador estava.
##
## Para salvar em outro momento (ex: fim de um minigame): Salvamento.salvar()
##
## Também garante o sinal "iniciar_gameplay" (fim da cena_01 -> mini-jogo da
## Linna) quando a main NÃO está aberta (ex: o jogo começou direto no menu).
## Se a main estiver aberta, quem cuida é o main.gd.

const SLOT := "Default"

## Cenas que NUNCA são salvas como "onde o jogador parou".
## AJUSTE se o caminho da main ou do menu for diferente.
const CENAS_SEM_SAVE := [
	"res://scenes/main.tscn",
	"res://scenes/menu.tscn",
]

## Cenas cujo caminho tem uma destas palavras também NÃO são salvas:
## são mini-jogos, e o "Continuar" não deve cair no meio de um.
const PALAVRAS_SEM_SAVE := [
	"minigame",
	"hidden_object",
	"casa_hera_corredor",
	"rua_dos_ipes",
	"rua_das_ipes_direita",
	"rua_das_ipes_esquerda",
	"RuaDasIpesCentro",
]

## Para onde ir no "Continuar" se o save não tiver cena guardada.
const CENA_PADRAO := "res://scenes/mapa_pricipal.tscn"

## Mini-jogo do tutorial (o mesmo do main.gd).
const CENA_MINIJOGO_LINNA := "res://scenes/hidden_object_linna.tscn"

var _ultima_cena := ""
var _carregando := false
var _indo_minijogo := false


func _ready() -> void:
	# Para salvar também quando o jogador fecha a janela.
	get_tree().set_auto_accept_quit(false)
	Dialogic.signal_event.connect(_on_dialogic_signal)


# ---------------------------------------------------------------- MINI-JOGO

func _on_dialogic_signal(argumento: String) -> void:
	if argumento != "iniciar_gameplay":
		return
	# A main está aberta: o main.gd cuida (não troca duas vezes).
	if get_tree().current_scene is Main:
		return
	if _indo_minijogo:
		return
	_indo_minijogo = true
	print(">>> Salvamento: a main não está aberta, indo para o mini-jogo da Linna")
	get_tree().change_scene_to_file.call_deferred(CENA_MINIJOGO_LINNA)
	await get_tree().create_timer(1.0).timeout
	_indo_minijogo = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		salvar()
		get_tree().quit()


# Confere a cada quadro se a cena mudou; quando muda, salva.
func _process(_delta: float) -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return
	var caminho := cena.scene_file_path
	if caminho == _ultima_cena:
		return
	_ultima_cena = caminho
	if _carregando:
		_carregando = false
		return
	salvar()


# ---------------------------------------------------------------- API

func tem_save() -> bool:
	return Dialogic.Save.has_slot(SLOT)


func salvar() -> void:
	var cena := get_tree().current_scene
	var caminho := cena.scene_file_path if cena else ""
	if caminho == "" or caminho in CENAS_SEM_SAVE:
		return
	for palavra in PALAVRAS_SEM_SAVE:
		if str(palavra) in caminho:
			return
	# Não salva no meio de uma conversa (o save ficaria no meio da fala).
	if Dialogic.current_timeline:
		return

	var info := {
		"cena": caminho,
		"game_state": _ler_game_state(),
	}
	Dialogic.Save.save(SLOT, false, Dialogic.Save.ThumbnailMode.NONE, info)
	print(">>> Salvamento: jogo salvo em ", caminho)


## Carrega o save e abre a cena onde o jogador parou.
func carregar() -> void:
	if not tem_save():
		push_warning("Salvamento: não existe save para carregar.")
		return

	Dialogic.Save.load(SLOT)
	var info: Dictionary = Dialogic.Save.get_slot_info(SLOT)
	_escrever_game_state(info.get("game_state", {}))

	var destino: String = info.get("cena", CENA_PADRAO)
	if destino == "" or not ResourceLoader.exists(destino):
		destino = CENA_PADRAO
	print(">>> Salvamento: carregado, indo para ", destino)

	_carregando = true   # a troca de cena logo abaixo não precisa salvar de novo
	get_tree().call_deferred("change_scene_to_file", destino)


## Apaga o save (usado no Novo Jogo).
func apagar() -> void:
	if tem_save():
		Dialogic.Save.delete_slot(SLOT)
		print(">>> Salvamento: save apagado")


# ---------------------------------------------------------------- GAMESTATE

# Copia todas as variáveis do GameState (as declaradas com "var" no script).
func _ler_game_state() -> Dictionary:
	var dados := {}
	if not is_instance_valid(GameState):
		return dados
	for prop in GameState.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			dados[prop.name] = GameState.get(prop.name)
	return dados


# Devolve as variáveis guardadas para o GameState, no tipo certo.
func _escrever_game_state(dados: Dictionary) -> void:
	if not is_instance_valid(GameState):
		return
	for nome in dados:
		if not (nome in GameState):
			continue
		var valor = dados[nome]
		var atual = GameState.get(nome)
		if typeof(atual) == TYPE_INT:
			valor = int(valor)
		elif typeof(atual) == TYPE_FLOAT:
			valor = float(valor)
		elif typeof(atual) == TYPE_BOOL:
			valor = bool(valor)
		GameState.set(nome, valor)
	# Avisa o HUD das moedas, se houver.
	if GameState.has_signal("moedas_alteradas"):
		GameState.moedas_alteradas.emit(GameState.moedas)
