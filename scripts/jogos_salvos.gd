extends Control
class_name PainelJogosSalvos
## Tela "Jogos salvos" — Vila Lypia
## Mostra os 3 espaços de save. Cada um mostra:
##   - a fotinha de onde a criança parou;
##   - o nome que ela digitou, o capítulo, as moedas e quando salvou;
##   - os botões Jogar e Apagar (ou "Começar aqui", se o espaço está livre).
## Pensada para crianças: botões grandes, palavras simples, nada pisca, e
## apagar um jogo sempre pergunta antes ("Apagar o jogo da Joana?").
##
## Dois jeitos de abrir (quem abre é o painel_com_save.gd):
##   abrir(MODO_JOGAR)     -> veio do "Continuar": escolher qual jogo continuar
##   abrir(MODO_SUBSTITUIR) -> veio do "Novo Jogo" com os 3 espaços ocupados:
##                             escolher qual jogo vai dar lugar ao novo
##
## Monta a tela sozinha (não precisa criar nada no editor).
## Precisa do autoload "Salvamento" (Salvamento.gd).

signal jogar(espaco: String)        ## continuar o jogo salvo deste espaço
signal comecar(espaco: String)      ## começar um jogo novo neste espaço
signal mudou                        ## algum jogo foi apagado
signal fechado

enum { MODO_JOGAR, MODO_SUBSTITUIR }

# Mesmas cores do painel de Configurações.
const COR_FUNDO := Color(0.06, 0.05, 0.1, 0.82)
const COR_CAIXA := Color("2b2140")
const COR_TEXTO := Color("fff1c9")
const COR_SUAVE := Color("bfb3d6")
const COR_ESCOLHIDO := Color("fff1c9")
const COR_BOTAO := Color("3d3159")
const COR_LINHA := Color("352a4d")
const COR_PERIGO := Color("8a3b4a")

const TAMANHO_FOTO := Vector2(176, 99)

var _modo := MODO_JOGAR
var _titulo: Label
var _dica: Label
var _lista: VBoxContainer
var _ocupado := false


func _ready() -> void:
	_montar_tela()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


## Abre a tela no modo pedido e atualiza os 3 espaços.
func abrir(modo := MODO_JOGAR) -> void:
	_modo = modo
	_ocupado = false
	if _modo == MODO_SUBSTITUIR:
		_titulo.text = "Novo jogo"
		_dica.text = "Os 3 espaços já têm jogos salvos.\nEscolha qual jogo vai dar lugar ao novo."
	else:
		_titulo.text = "Jogos salvos"
		_dica.text = "Escolha o seu jogo para continuar de onde parou."
	_montar_lista()
	visible = true


func fechar() -> void:
	visible = false
	fechado.emit()


# ---------------------------------------------------------------- MONTAR

func _montar_tela() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)

	var caixa := PanelContainer.new()
	caixa.add_theme_stylebox_override("panel", _estilo(COR_CAIXA, 20, 22, COR_TEXTO.darkened(0.35)))
	caixa.custom_minimum_size = Vector2(780, 0)
	centro.add_child(caixa)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	caixa.add_child(coluna)

	_titulo = _rotulo("Jogos salvos", 30, COR_TEXTO, true)
	coluna.add_child(_titulo)
	_dica = _rotulo("", 18, COR_SUAVE, true)
	coluna.add_child(_dica)

	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 10)
	coluna.add_child(_lista)

	var voltar := _botao("Voltar", 24)
	voltar.add_theme_stylebox_override("normal", _estilo(COR_ESCOLHIDO, 10, 10))
	voltar.add_theme_stylebox_override("hover", _estilo(COR_ESCOLHIDO.lightened(0.1), 10, 10))
	voltar.add_theme_color_override("font_color", COR_CAIXA)
	voltar.add_theme_color_override("font_hover_color", COR_CAIXA)
	voltar.pressed.connect(fechar)
	coluna.add_child(voltar)


func _montar_lista() -> void:
	for filho in _lista.get_children():
		filho.queue_free()
	for item in Salvamento.espacos_info():
		_lista.add_child(_linha(item))


## Uma linha da lista: fotinha + textos + botões.
func _linha(item: Dictionary) -> Control:
	var caixa := PanelContainer.new()
	caixa.add_theme_stylebox_override("panel", _estilo(COR_LINHA, 14, 10))

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	caixa.add_child(linha)

	linha.add_child(_foto(item))

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 2)
	linha.add_child(textos)

	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", 8)
	botoes.alignment = BoxContainer.ALIGNMENT_END
	linha.add_child(botoes)

	var espaco: String = item["espaco"]
	if item["existe"]:
		textos.add_child(_rotulo(_nome(item), 24, COR_TEXTO))
		var capitulo: String = item["capitulo"]
		if capitulo != "":
			textos.add_child(_rotulo(capitulo, 18, COR_TEXTO.darkened(0.1)))
		var detalhes := _detalhes(item)
		if detalhes != "":
			textos.add_child(_rotulo(detalhes, 16, COR_SUAVE))
		_botoes_normais(botoes, item)
	else:
		textos.add_child(_rotulo("Jogo %d" % item["numero"], 24, COR_TEXTO))
		textos.add_child(_rotulo("Espaço livre", 18, COR_SUAVE))
		var comecar_aqui := _botao("Começar aqui", 20)
		comecar_aqui.custom_minimum_size = Vector2(170, 52)
		comecar_aqui.pressed.connect(_on_comecar.bind(espaco))
		botoes.add_child(comecar_aqui)

	return caixa


func _foto(item: Dictionary) -> Control:
	var moldura := PanelContainer.new()
	moldura.custom_minimum_size = TAMANHO_FOTO
	moldura.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	moldura.add_theme_stylebox_override("panel", _estilo(COR_CAIXA, 8, 0, COR_TEXTO.darkened(0.5)))
	var foto = item.get("foto")
	if foto is Texture2D:
		var imagem := TextureRect.new()
		imagem.texture = foto
		imagem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		imagem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		imagem.custom_minimum_size = TAMANHO_FOTO
		imagem.clip_contents = true
		moldura.add_child(imagem)
	else:
		var texto := _rotulo("Jogo %d" % item["numero"] if item["existe"] else "+", 22 if item["existe"] else 40, COR_SUAVE, true)
		texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		moldura.add_child(texto)
	return moldura


func _botoes_normais(botoes: HBoxContainer, item: Dictionary) -> void:
	for filho in botoes.get_children():
		filho.queue_free()
	var espaco: String = item["espaco"]
	if _modo == MODO_SUBSTITUIR:
		var usar := _botao("Usar este espaço", 20)
		usar.custom_minimum_size = Vector2(190, 52)
		usar.pressed.connect(_perguntar.bind(botoes, item, true))
		botoes.add_child(usar)
	else:
		var jogar_botao := _botao("Jogar", 22)
		jogar_botao.custom_minimum_size = Vector2(120, 52)
		jogar_botao.add_theme_stylebox_override("normal", _estilo(COR_ESCOLHIDO, 10, 8))
		jogar_botao.add_theme_stylebox_override("hover", _estilo(COR_ESCOLHIDO.lightened(0.1), 10, 8))
		jogar_botao.add_theme_color_override("font_color", COR_CAIXA)
		jogar_botao.add_theme_color_override("font_hover_color", COR_CAIXA)
		jogar_botao.pressed.connect(_on_jogar.bind(espaco))
		botoes.add_child(jogar_botao)
		var apagar_botao := _botao("Apagar", 18)
		apagar_botao.custom_minimum_size = Vector2(100, 52)
		apagar_botao.pressed.connect(_perguntar.bind(botoes, item, false))
		botoes.add_child(apagar_botao)


## Troca os botões da linha pela pergunta "Apagar o jogo da Joana?  Sim / Não".
## substituir = true: depois do "Sim", começa um jogo novo neste espaço.
func _perguntar(botoes: HBoxContainer, item: Dictionary, substituir: bool) -> void:
	for filho in botoes.get_children():
		filho.queue_free()
	var pergunta := _rotulo(_pergunta_apagar(item), 17, COR_TEXTO, true)
	pergunta.custom_minimum_size = Vector2(150, 0)
	pergunta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	botoes.add_child(pergunta)
	var sim := _botao("Sim", 20)
	sim.custom_minimum_size = Vector2(80, 52)
	sim.add_theme_stylebox_override("normal", _estilo(COR_PERIGO, 10, 8))
	sim.add_theme_stylebox_override("hover", _estilo(COR_PERIGO.lightened(0.12), 10, 8))
	sim.pressed.connect(_on_sim.bind(item["espaco"], substituir))
	botoes.add_child(sim)
	var nao := _botao("Não", 20)
	nao.custom_minimum_size = Vector2(80, 52)
	nao.pressed.connect(_botoes_normais.bind(botoes, item))
	botoes.add_child(nao)


# ---------------------------------------------------------------- AÇÕES

func _on_jogar(espaco: String) -> void:
	if _ocupado:
		return
	_ocupado = true
	print(">>> Jogos salvos: jogar ", espaco)
	visible = false
	jogar.emit(espaco)


func _on_comecar(espaco: String) -> void:
	if _ocupado:
		return
	_ocupado = true
	print(">>> Jogos salvos: começar jogo novo em ", espaco)
	visible = false
	comecar.emit(espaco)


func _on_sim(espaco: String, substituir: bool) -> void:
	if _ocupado:
		return
	if substituir:
		_on_comecar(espaco)
		return
	Salvamento.apagar(espaco)
	print(">>> Jogos salvos: apagado ", espaco)
	mudou.emit()
	if Salvamento.tem_save():
		_montar_lista()
	else:
		# Não sobrou nenhum jogo: volta para o menu (que mostra "Iniciar a Aventura").
		fechar()


# ---------------------------------------------------------------- TEXTOS

func _nome(item: Dictionary) -> String:
	var nome: String = item["nome"]
	if nome == "":
		return "Jogo %d" % item["numero"]
	return nome


## "Apagar o jogo de Joana?" ou, sem nome, "Apagar o Jogo 2?"
func _pergunta_apagar(item: Dictionary) -> String:
	var nome: String = item["nome"]
	if nome == "":
		return "Apagar o Jogo %d?" % item["numero"]
	return "Apagar o jogo de %s?" % nome


func _detalhes(item: Dictionary) -> String:
	var partes := []
	var moedas: int = item["moedas"]
	if moedas >= 0:
		partes.append("%d %s" % [moedas, "moeda" if moedas == 1 else "moedas"])
	var data: String = item["data"]
	if data != "":
		partes.append("salvo em " + data)
	return "  ·  ".join(partes)


# ---------------------------------------------------------------- ESTILO

func _botao(texto: String, tamanho: int) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", tamanho)
	b.add_theme_color_override("font_color", COR_TEXTO)
	b.add_theme_color_override("font_hover_color", COR_TEXTO)
	b.add_theme_color_override("font_pressed_color", COR_CAIXA)
	b.add_theme_stylebox_override("normal", _estilo(COR_BOTAO, 10, 8))
	b.add_theme_stylebox_override("hover", _estilo(COR_BOTAO.lightened(0.12), 10, 8))
	b.add_theme_stylebox_override("pressed", _estilo(COR_ESCOLHIDO, 10, 8))
	return b


func _rotulo(texto: String, tamanho: int, cor: Color, centralizado := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centralizado:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _estilo(cor: Color, raio: int, margem: int, borda := Color.TRANSPARENT) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = cor
	e.set_corner_radius_all(raio)
	e.set_content_margin_all(margem)
	if borda.a > 0:
		e.border_color = borda
		e.set_border_width_all(3)
	return e
