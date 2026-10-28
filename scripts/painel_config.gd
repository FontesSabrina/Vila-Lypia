extends Control
class_name PainelConfig
## Painel de Configurações — Vila Lypia
## Pensado para crianças com sensibilidade sensorial (autismo):
##   - poucas opções por vez (3 abas grandes: Sons, Tela, Texto);
##   - palavras simples e botões grandes;
##   - tudo muda na hora e mostra um exemplo, sem surpresas;
##   - nada pisca, nada se mexe sozinho, sem sons de clique;
##   - botão "Voltar ao normal" para desfazer tudo de uma vez.
##
## Monta a tela sozinho: basta um nó Control chamado "PainelConfig"
## dentro do menu.tscn com este script.
## Precisa do autoload "Acessibilidade" (Acessibilidade.gd).

const COR_FUNDO := Color(0.06, 0.05, 0.1, 0.82)
const COR_CAIXA := Color("2b2140")
const COR_TEXTO := Color("fff1c9")
const COR_SUAVE := Color("bfb3d6")
const COR_ESCOLHIDO := Color("fff1c9")
const COR_BOTAO := Color("3d3159")

var _abas: Array[Button] = []
var _paginas: Array[Control] = []
var _exemplo_texto: Label

# controles (para atualizar quando restaurar o padrão)
var _sliders := {}        # chave -> HSlider
var _rotulos := {}        # chave -> Label de %
var _checks := {}         # chave -> CheckButton
var _grupos := {}         # chave -> Array[Button]


func _ready() -> void:
	_montar_tela()
	_atualizar_tudo()
	_mostrar_aba(0)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func fechar() -> void:
	visible = false


func _acess() -> Node:
	return get_node_or_null("/root/Acessibilidade")


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
	caixa.custom_minimum_size = Vector2(760, 0)
	centro.add_child(caixa)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 12)
	caixa.add_child(coluna)

	coluna.add_child(_rotulo("Configurações", 30, COR_TEXTO, true))

	# Abas
	var linha_abas := HBoxContainer.new()
	linha_abas.add_theme_constant_override("separation", 12)
	coluna.add_child(linha_abas)
	for i in 3:
		var nome: String = ["Sons", "Tela", "Texto"][i]
		var b := _botao(nome, 24)
		b.toggle_mode = true
		b.custom_minimum_size.y = 48
		b.pressed.connect(_mostrar_aba.bind(i))
		linha_abas.add_child(b)
		_abas.append(b)

	# Páginas
	var area := MarginContainer.new()
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	coluna.add_child(area)
	_paginas = [_pagina_sons(), _pagina_tela(), _pagina_texto()]
	for p in _paginas:
		area.add_child(p)

	# Rodapé
	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override("separation", 12)
	coluna.add_child(rodape)
	var normal := _botao("Voltar ao normal", 20)
	normal.pressed.connect(_on_restaurar)
	rodape.add_child(normal)
	var voltar := _botao("Pronto", 24)
	voltar.add_theme_stylebox_override("normal", _estilo(COR_ESCOLHIDO, 10, 10))
	voltar.add_theme_stylebox_override("hover", _estilo(COR_ESCOLHIDO.lightened(0.1), 10, 10))
	voltar.add_theme_color_override("font_color", COR_CAIXA)
	voltar.add_theme_color_override("font_hover_color", COR_CAIXA)
	voltar.pressed.connect(fechar)
	rodape.add_child(voltar)


func _pagina_sons() -> Control:
	var p := _pagina()
	p.add_child(_dica("Deixe os sons do jeitinho que for confortável."))
	p.add_child(_linha_slider("Música", "vol_musica", 0.0, 1.0))
	p.add_child(_linha_slider("Vozes", "vol_vozes", 0.0, 1.0))
	p.add_child(_linha_slider("Efeitos", "vol_efeitos", 0.0, 1.0))
	p.add_child(_linha_check("Sons suaves", "sons_suaves", "Segura os sons altos de repente."))
	return p


func _pagina_tela() -> Control:
	var p := _pagina()
	p.add_child(_dica("Deixe a tela mais calma para os olhos."))
	p.add_child(_linha_slider("Brilho", "brilho", 0.5, 1.0))
	p.add_child(_linha_check("Cores suaves", "cores_suaves", "Cores mais calmas, menos fortes."))
	p.add_child(_linha_check("Sem clarões", "sem_claroes", "A tela não pisca em branco."))
	p.add_child(_linha_check("Tela cheia", "tela_cheia", ""))
	return p


func _pagina_texto() -> Control:
	var acess := _acess()
	var p := _pagina()
	p.add_child(_dica("Escolha como as falas aparecem."))
	p.add_child(_rotulo("Velocidade das letras", 22, COR_TEXTO))
	p.add_child(_linha_escolha("velocidade", acess.VELOCIDADES if acess else []))
	p.add_child(_rotulo("Tamanho das letras", 22, COR_TEXTO))
	p.add_child(_linha_escolha("tamanho", acess.TAMANHOS if acess else []))
	_exemplo_texto = _rotulo("Olá! Eu sou a Bella.", 22, COR_TEXTO, true)
	var quadro := PanelContainer.new()
	quadro.add_theme_stylebox_override("panel", _estilo(Color(0, 0, 0, 0.35), 10, 10))
	quadro.add_child(_exemplo_texto)
	p.add_child(quadro)
	p.add_child(_linha_check("Avançar sozinho", "avancar_sozinho", "Desligado: você passa as falas no seu tempo."))
	return p


# ---------------------------------------------------------------- PEÇAS

func _pagina() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	return v


func _linha_slider(nome: String, chave: String, minimo: float, maximo: float) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var r := _rotulo(nome, 22, COR_TEXTO)
	r.custom_minimum_size.x = 150
	h.add_child(r)
	var s := HSlider.new()
	s.min_value = minimo * 100.0
	s.max_value = maximo * 100.0
	s.step = 5
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.custom_minimum_size.y = 32
	s.add_theme_stylebox_override("slider", _estilo(Color("1b1528"), 8, 6))
	s.add_theme_stylebox_override("grabber_area", _estilo(COR_SUAVE, 8, 6))
	s.add_theme_stylebox_override("grabber_area_highlight", _estilo(COR_TEXTO, 8, 6))
	s.value_changed.connect(_on_slider.bind(chave))
	h.add_child(s)
	var pct := _rotulo("", 20, COR_TEXTO)
	pct.custom_minimum_size.x = 64
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(pct)
	_sliders[chave] = s
	_rotulos[chave] = pct
	return h


func _linha_check(nome: String, chave: String, explica: String) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var c := CheckButton.new()
	c.text = nome
	c.add_theme_font_size_override("font_size", 22)
	c.add_theme_color_override("font_color", COR_TEXTO)
	c.add_theme_color_override("font_pressed_color", COR_TEXTO)
	c.add_theme_color_override("font_hover_color", COR_TEXTO)
	c.toggled.connect(_on_check.bind(chave))
	v.add_child(c)
	if explica != "":
		var e := _rotulo(explica, 16, COR_SUAVE)
		e.add_theme_constant_override("line_spacing", 0)
		v.add_child(e)
	_checks[chave] = c
	return v


func _linha_escolha(chave: String, opcoes: Array) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	var grupo := ButtonGroup.new()
	var lista: Array[Button] = []
	for i in opcoes.size():
		var b := _botao(opcoes[i]["nome"], 18)
		b.toggle_mode = true
		b.button_group = grupo
		b.custom_minimum_size.y = 50
		b.pressed.connect(_on_escolha.bind(chave, i))
		h.add_child(b)
		lista.append(b)
	_grupos[chave] = lista
	return h


func _botao(texto: String, tamanho: int) -> Button:
	var b := Button.new()
	b.text = texto
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", tamanho)
	b.add_theme_color_override("font_color", COR_TEXTO)
	b.add_theme_color_override("font_hover_color", COR_TEXTO)
	b.add_theme_color_override("font_pressed_color", COR_CAIXA)
	b.add_theme_color_override("font_hover_pressed_color", COR_CAIXA)
	b.add_theme_stylebox_override("normal", _estilo(COR_BOTAO, 10, 8))
	b.add_theme_stylebox_override("hover", _estilo(COR_BOTAO.lightened(0.12), 10, 8))
	b.add_theme_stylebox_override("pressed", _estilo(COR_ESCOLHIDO, 10, 8))
	b.add_theme_stylebox_override("hover_pressed", _estilo(COR_ESCOLHIDO, 10, 8))
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


func _dica(texto: String) -> Label:
	return _rotulo(texto, 18, COR_SUAVE)


func _estilo(cor: Color, raio: int, margem: int, borda := Color.TRANSPARENT) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = cor
	e.set_corner_radius_all(raio)
	e.set_content_margin_all(margem)
	if borda.a > 0:
		e.border_color = borda
		e.set_border_width_all(3)
	return e


# ---------------------------------------------------------------- ATUALIZAR

func _mostrar_aba(i: int) -> void:
	for n in _abas.size():
		_abas[n].set_pressed_no_signal(n == i)
		_paginas[n].visible = n == i


func _atualizar_tudo() -> void:
	var a := _acess()
	if a == null:
		push_error("PainelConfig: cadastre o autoload 'Acessibilidade' (Acessibilidade.gd).")
		return
	for chave in _sliders:
		var v: float = a.get(chave)
		_sliders[chave].set_value_no_signal(round(v * 100.0))
		_rotulos[chave].text = "%d%%" % int(round(v * 100.0))
	for chave in _checks:
		_checks[chave].set_pressed_no_signal(a.get(chave))
	for chave in _grupos:
		var lista: Array = _grupos[chave]
		lista[a.get(chave)].set_pressed_no_signal(true)
	_atualizar_exemplo()


func _atualizar_exemplo() -> void:
	var a := _acess()
	if a and _exemplo_texto:
		_exemplo_texto.add_theme_font_size_override("font_size", int(22 * a.TAMANHOS[a.tamanho]["valor"]))


# ---------------------------------------------------------------- AÇÕES

func _on_slider(valor: float, chave: String) -> void:
	_rotulos[chave].text = "%d%%" % int(valor)
	var a := _acess()
	if a:
		a.mudar(chave, valor / 100.0)


func _on_check(ligado: bool, chave: String) -> void:
	var a := _acess()
	if a:
		a.mudar(chave, ligado)


func _on_escolha(chave: String, indice: int) -> void:
	var a := _acess()
	if a:
		a.mudar(chave, indice)
	_atualizar_exemplo()


func _on_restaurar() -> void:
	var a := _acess()
	if a:
		a.restaurar_padrao()
	_atualizar_tudo()
