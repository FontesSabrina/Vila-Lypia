extends Node
## (Sem class_name de propósito: autoload não precisa, e um class_name aqui
## dá conflito se existir outra cópia deste arquivo no projeto.)
## Salvamento — autoload (Projeto > Configurações do Projeto > Globals > Autoload)
## Nome do autoload: Salvamento
##
## JOGOS SALVOS: o jogo tem 3 espaços de save ("Jogo 1", "Jogo 2", "Jogo 3").
## Assim cada criança do mesmo computador tem o seu jogo, sem apagar o do outro.
## O espaço em uso fica em "espaco_atual" (escolhido no menu).
##
## Salva SOZINHO, no espaço em uso:
##   - toda vez que o jogador entra numa cena nova (menos as de CENAS_SEM_SAVE);
##   - quando o jogador fecha a janela do jogo.
## Cada save guarda, num slot do Dialogic:
##   - as variáveis do Dialogic (capítulos, amizades...);
##   - todas as variáveis do GameState (moedas, itens, bolo...);
##   - a cena em que o jogador estava;
##   - o nome do jogador, o capítulo, as moedas e a data (para a tela de
##     Jogos salvos);
##   - uma fotinha da tela (thumbnail.png), tirada logo depois de a cena abrir.
##
## O "Jogo 1" usa o mesmo slot do save antigo ("Default"): quem já tinha um
## jogo salvo antes desta versão continua com ele, agora no Jogo 1.
##
## Para salvar em outro momento (ex: fim de um minigame): Salvamento.salvar()
##
## Também garante o sinal "iniciar_gameplay" (fim da cena_01 -> mini-jogo da
## Linna) quando a main NÃO está aberta (ex: o jogo começou direto no menu).
## Se a main estiver aberta, quem cuida é o main.gd.

## Os 3 espaços de save (nomes das pastas do Dialogic em user://dialogic/saves/).
const ESPACOS := ["Default", "Espaco2", "Espaco3"]

## Cenas que NUNCA são salvas como "onde o jogador parou".
## AJUSTE se o caminho da main ou do menu for diferente.
const CENAS_SEM_SAVE := [
	"res://scenes/main.tscn",
	"res://scenes/menu.tscn",
	# Créditos: senão o "Continuar" depois do fim abriria os créditos de novo.
	"res://scenes/creditos.tscn",
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

## Tamanho da fotinha de cada jogo salvo (em pixels).
const TAMANHO_FOTO := Vector2i(320, 180)
## Espera depois de a cena abrir para tirar a fotinha (a cena já desenhada).
const ESPERA_FOTO := 0.6

## Espaço de save em uso ("Default", "Espaco2" ou "Espaco3").
## Vazio = ainda não escolhido (o salvar() usa o último usado, ou o Jogo 1).
var espaco_atual := ""

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
		salvar(true)
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
	if salvar():
		_tirar_foto_depois(caminho)


# ---------------------------------------------------------------- API

## true se existe pelo menos um jogo salvo (em qualquer espaço).
func tem_save() -> bool:
	for espaco in ESPACOS:
		if _existe(espaco):
			return true
	return false


## O primeiro espaço sem jogo salvo, ou "" se os 3 estão ocupados.
func primeiro_espaco_livre() -> String:
	for espaco in ESPACOS:
		if not _existe(espaco):
			return espaco
	return ""


## Informações dos 3 espaços, para a tela de Jogos salvos.
## Cada item: {espaco, numero, existe, nome, capitulo, moedas, data, foto}
func espacos_info() -> Array:
	var lista := []
	for i in ESPACOS.size():
		var espaco: String = ESPACOS[i]
		var item := {
			"espaco": espaco,
			"numero": i + 1,
			"existe": _existe(espaco),
			"nome": "",
			"capitulo": "",
			"moedas": -1,
			"data": "",
			"foto": null,
		}
		if item["existe"]:
			var info: Dictionary = Dialogic.Save.get_slot_info(espaco)
			item["nome"] = str(info.get("nome", ""))
			item["capitulo"] = str(info.get("capitulo", ""))
			item["moedas"] = int(info.get("moedas", -1))
			item["data"] = str(info.get("data", ""))
			item["foto"] = Dialogic.Save.get_slot_thumbnail(espaco)
		lista.append(item)
	return lista


## Escolhe em qual espaço o jogo vai salvar daqui para frente.
func usar_espaco(espaco: String) -> void:
	if not (espaco in ESPACOS):
		push_warning("Salvamento: espaço desconhecido: " + espaco)
		return
	espaco_atual = espaco
	print(">>> Salvamento: usando o espaço ", espaco)


## Começa um jogo novo no espaço escolhido: apaga o que havia nele e zera tudo.
func novo_jogo(espaco: String) -> void:
	apagar(espaco)
	usar_espaco(espaco)
	GameState.resetar()
	if Dialogic.VAR.has_method("reset"):
		Dialogic.VAR.reset()


## Salva no espaço em uso. Devolve true se salvou.
## (com_foto = true tira a fotinha na hora, ex: ao fechar a janela)
func salvar(com_foto := false) -> bool:
	var cena := get_tree().current_scene
	var caminho := cena.scene_file_path if cena else ""
	if caminho == "" or caminho in CENAS_SEM_SAVE:
		return false
	for palavra in PALAVRAS_SEM_SAVE:
		if str(palavra) in caminho:
			return false
	# Não salva no meio de uma conversa (o save ficaria no meio da fala).
	if Dialogic.current_timeline:
		return false

	var espaco := _espaco_em_uso()
	var info := {
		"cena": caminho,
		"game_state": _ler_game_state(),
		"nome": _nome_do_jogador(),
		"capitulo": _capitulo_atual(caminho),
		"moedas": GameState.moedas if is_instance_valid(GameState) else 0,
		"data": _data_de_agora(),
	}
	Dialogic.Save.save(espaco, false, Dialogic.Save.ThumbnailMode.NONE, info)
	if com_foto:
		_guardar_foto(espaco)
	print(">>> Salvamento: jogo salvo em ", espaco, " -> ", caminho)
	return true


## Carrega um jogo salvo e abre a cena onde o jogador parou.
## Sem espaço: usa o espaço em uso.
func carregar(espaco := "") -> void:
	if espaco == "":
		espaco = _espaco_em_uso()
	if not _existe(espaco):
		push_warning("Salvamento: não existe save no espaço " + espaco)
		return

	usar_espaco(espaco)
	Dialogic.Save.load(espaco)
	var info: Dictionary = Dialogic.Save.get_slot_info(espaco)
	_escrever_game_state(info.get("game_state", {}))

	var destino: String = info.get("cena", CENA_PADRAO)
	if destino == "" or not ResourceLoader.exists(destino):
		destino = CENA_PADRAO
	print(">>> Salvamento: carregado ", espaco, ", indo para ", destino)

	_carregando = true   # a troca de cena logo abaixo não precisa salvar de novo
	get_tree().call_deferred("change_scene_to_file", destino)


## Apaga um jogo salvo. Sem espaço: apaga o do espaço em uso
## (usado no "Tentar Novamente" do final).
func apagar(espaco := "") -> void:
	if espaco == "":
		espaco = _espaco_em_uso()
	if _existe(espaco):
		Dialogic.Save.delete_slot(espaco)
		print(">>> Salvamento: save apagado do espaço ", espaco)


# ---------------------------------------------------------------- AJUDANTES

func _existe(espaco: String) -> bool:
	return Dialogic.Save.has_slot(espaco) and not Dialogic.Save.get_slot_info(espaco).is_empty()


func _espaco_em_uso() -> String:
	if espaco_atual != "":
		return espaco_atual
	# Ninguém escolheu (ex: cena aberta direto pelo F6): usa o último usado.
	var ultimo: String = Dialogic.Save.get_latest_slot()
	if ultimo in ESPACOS:
		espaco_atual = ultimo
	else:
		espaco_atual = ESPACOS[0]
	return espaco_atual


func _nome_do_jogador() -> String:
	var nome := str(Dialogic.VAR.get_variable("NomeJogador", "")).strip_edges()
	if nome == "" or nome == "????":
		return ""
	return nome


## Nome do capítulo em que o jogador está, para mostrar no Jogos salvos.
func _capitulo_atual(caminho: String) -> String:
	if "capitulo_final" in caminho or (is_instance_valid(GameState) and GameState.final_alcancado > 0):
		return "Capítulo Final – A festa"
	if _ler_var("Cena.Praca_IV", false) == true or "_iv" in caminho.to_lower():
		return "Capítulo IV – O cartão e o presente"
	if int(_ler_var("Bolo.Estado", 0)) >= 1 or _ler_var("Cena.Praca_Estado", false) == true \
			or int(_ler_var("Bella.Estado_Bella", 0)) >= 2:
		return "Capítulo III – O bolo"
	if is_instance_valid(GameState) and GameState.mapa_pego:
		return "Capítulo II – Os convites"
	return "Tutorial"


func _ler_var(nome: String, padrao):
	if Dialogic.VAR.has(nome):
		return Dialogic.VAR.get_variable(nome, padrao)
	return padrao


func _data_de_agora() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%02d/%02d às %02d:%02d" % [d.day, d.month, d.hour, d.minute]


# Espera a cena nova aparecer na tela e guarda a fotinha dela.
func _tirar_foto_depois(caminho: String) -> void:
	var espaco := _espaco_em_uso()
	await get_tree().create_timer(ESPERA_FOTO).timeout
	var cena := get_tree().current_scene
	if cena == null or cena.scene_file_path != caminho:
		return
	await RenderingServer.frame_post_draw
	_guardar_foto(espaco)


func _guardar_foto(espaco: String) -> void:
	if not _existe(espaco):
		return
	var textura := get_viewport().get_texture()
	if textura == null:
		return
	var imagem := textura.get_image()
	if imagem == null or imagem.is_empty():
		return
	imagem.resize(TAMANHO_FOTO.x, TAMANHO_FOTO.y, Image.INTERPOLATE_BILINEAR)
	Dialogic.Save.latest_thumbnail = imagem
	Dialogic.Save.save_slot_thumbnail(espaco)


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
