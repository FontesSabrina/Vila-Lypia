extends CanvasLayer
class_name AberturaLivro
## Abertura do jogo — "A história do livro" (Vila Lypia)
##
## Depois de "Iniciar a Aventura" (ou "Novo Jogo"), antes da floresta:
##   1. O quarto vazio, à noite.
##   2. A mamãe chega com o livro.
##   3. A mamãe lê o livro.
##   4. As páginas: Anne desenhando a Vila Lypia.
##   5. A capa do livro.
##   (Desde a primeira imagem toca um som de noite: grilos e um ventinho,
##    e uma musiquinha leve de piano, que vira a música de ninar na imagem 6.)
##   6. O livro na mesinha, brilhando.
##      -> começa a música de ninar e a tela "pisca de sono", como olhos
##         fechando devagar, até ficar escura.
## Depois disso começa a primeira conversa do jogo (cena_01, na floresta).
##
## As imagens trocam devagar (sem piscar). Cada uma fica alguns segundos e
## passa sozinha; um clique (ou Espaço/Enter) passa para a próxima.
## O botão "Pular" vai direto para o jogo.
##
## COMO USAR (já está nos painéis do menu):
##     AberturaLivro.tocar(get_tree(), "cena_01")
## Não precisa criar cena nem nó no editor: a abertura monta tudo sozinha.

# ---------------------------------------------------------------- AJUSTE AQUI
## As 6 imagens, na ordem.
const IMAGENS := [
	"res://assets/backgrounds/abertura_01.jpg",
	"res://assets/backgrounds/abertura_02.jpg",
	"res://assets/backgrounds/abertura_03.jpg",
	"res://assets/backgrounds/abertura_04.jpg",
	"res://assets/backgrounds/abertura_05.jpg",
	"res://assets/backgrounds/abertura_06.jpg",
]
## Quantos segundos cada imagem fica na tela antes de passar sozinha.
## (A 4 tem o texto do livro, por isso fica mais tempo.)
const TEMPOS := [3.5, 4.5, 4.5, 7.0, 4.0, 2.5]
## Tempo da troca suave entre uma imagem e outra.
const TROCA := 1.4
## Depois de uma imagem aparecer, o clique só vale depois deste tempo
## (evita pular duas imagens com um clique só).
const ESPERA_CLIQUE := 0.8

## Musiquinha leve das imagens 1 a 5 (piano calminho de livro de histórias).
## Na imagem 6 ela some devagar e entra a música de ninar.
const MUSICA_HISTORIA := "res://assets/som/trilha_abertura.ogg"
const VOLUME_HISTORIA_DB := -8.0
## Tempo para a musiquinha virar a música de ninar.
const TROCA_MUSICA := 3.0

## Música de ninar (começa na imagem 6, quando os olhos vão fechando).
const MUSICA_NINAR := "res://assets/som/ninar.ogg"
const VOLUME_NINAR_DB := -6.0
const BUS_MUSICA := "Musica"

## Som da noite (grilos e um ventinho), desde a primeira imagem até o fim.
const SOM_NOITE := "res://assets/som/noite.ogg"
const VOLUME_NOITE_DB := -10.0
## Quando a música de ninar começa, os grilos ficam mais baixinhos.
const VOLUME_NOITE_COM_NINAR_DB := -16.0
const BUS_EFEITOS := "Efeitos"

## "Piscadas de sono": quanto o olho fecha (0 = aberto, 1 = fechado) e em
## quantos segundos. A última sempre fecha de vez.
const PISCADAS := [
	[0.55, 1.6], [0.25, 1.1],
	[0.80, 1.8], [0.45, 1.2],
	[1.00, 2.4],
]
## Tempo com a tela escura e a música tocando, antes de ir para a floresta.
const ESCURO_ANTES_DO_JOGO := 3.0
## Tempo para a música sumir no fim.
const MUSICA_SOME := 2.5

signal terminou

var timeline_depois := ""

var _imagem_a: TextureRect
var _imagem_b: TextureRect
var _palpebra_cima: TextureRect
var _palpebra_baixo: TextureRect
var _fundo_preto: ColorRect
var _botao_pular: Button
var _musica: AudioStreamPlayer
var _historia: AudioStreamPlayer
var _noite: AudioStreamPlayer
var _indice := -1
var _pode_clicar := false
var _pular_espera := false
var _acabando := false


## Começa a abertura por cima de tudo e, no fim, abre a timeline pedida.
static func tocar(arvore: SceneTree, timeline: String = "cena_01") -> AberturaLivro:
	var abertura := AberturaLivro.new()
	abertura.timeline_depois = timeline
	arvore.root.add_child(abertura)
	return abertura


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	_tocar_noite()
	_tocar_historia()
	_rodar()


func _input(event: InputEvent) -> void:
	if _acabando:
		return
	var clicou := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicou = true
	elif event.is_action_pressed("ui_accept"):
		clicou = true
	if clicou:
		get_viewport().set_input_as_handled()
		if _pode_clicar:
			_pular_espera = true


# ---------------------------------------------------------------- SEQUÊNCIA

func _rodar() -> void:
	for i in IMAGENS.size():
		await _mostrar(i)
		if _acabando:
			return
		await _esperar(TEMPOS[i] if i < TEMPOS.size() else 4.0)
		if _acabando:
			return
	await _dormir()


func _mostrar(i: int) -> void:
	_indice = i
	_pode_clicar = false
	var textura := _carregar(IMAGENS[i])
	# A imagem nova aparece por cima da antiga, devagar.
	_imagem_b.texture = textura
	_imagem_b.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_imagem_b, "modulate:a", 1.0, TROCA if i > 0 else TROCA * 1.5)
	await t.finished
	_imagem_a.texture = textura
	_imagem_b.modulate.a = 0.0
	await get_tree().create_timer(ESPERA_CLIQUE).timeout
	_pode_clicar = true


# Espera o tempo da imagem, ou até a criança clicar.
func _esperar(segundos: float) -> void:
	_pular_espera = false
	var fim := Time.get_ticks_msec() + int(segundos * 1000.0)
	while Time.get_ticks_msec() < fim and not _pular_espera and not _acabando:
		await get_tree().process_frame
	_pular_espera = false


# Imagem 6: música de ninar e os olhos fechando de sono.
func _dormir() -> void:
	_acabando = true
	_botao_pular.visible = false
	_tocar_ninar()
	for piscada in PISCADAS:
		await _fechar_olhos(float(piscada[0]), float(piscada[1]))
	_fundo_preto.visible = true
	await get_tree().create_timer(ESCURO_ANTES_DO_JOGO).timeout
	await _ir_para_o_jogo()


func _fechar_olhos(quanto: float, segundos: float) -> void:
	var altura := get_viewport().get_visible_rect().size.y
	# Cada pálpebra cobre metade da tela quando o olho está fechado (+ a borda suave).
	var alvo := (altura * 0.5 + 120.0) * quanto
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_palpebra_cima, "position:y", -_palpebra_cima.size.y + alvo, segundos)
	t.tween_property(_palpebra_baixo, "position:y", altura - alvo, segundos)
	await t.finished


func _ir_para_o_jogo() -> void:
	# A música de ninar e os grilos somem juntos, devagar.
	var t := create_tween().set_parallel(true)
	var algum_som := false
	for som in [_musica, _noite, _historia]:
		if som and som.playing:
			t.tween_property(som, "volume_db", -40.0, MUSICA_SOME)
			algum_som = true
	if algum_som:
		await t.finished
	else:
		t.kill()
	for som in [_musica, _noite, _historia]:
		if som:
			som.stop()
	if timeline_depois != "":
		Dialogic.start(timeline_depois)
	terminou.emit()
	# A floresta aparece devagar, saindo do escuro.
	await get_tree().create_timer(0.4).timeout
	# Só o escuro some; o quarto e o livro já ficam escondidos.
	_fundo_preto.visible = true
	_fundo_preto.modulate.a = 1.0
	for no in [_palpebra_cima, _palpebra_baixo, _imagem_a, _imagem_b]:
		no.visible = false
	var fundo_da_tela := _fundo_preto.get_parent().get_child(0) as CanvasItem
	if fundo_da_tela:
		fundo_da_tela.visible = false
	var t2 := create_tween()
	t2.tween_property(_fundo_preto, "modulate:a", 0.0, 1.5)
	await t2.finished
	queue_free()


func _on_pular() -> void:
	if _acabando:
		return
	_acabando = true
	_botao_pular.visible = false
	_fundo_preto.visible = true
	_fundo_preto.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_fundo_preto, "modulate:a", 1.0, 0.8)
	await t.finished
	await _ir_para_o_jogo()


func _tocar_ninar() -> void:
	if not ResourceLoader.exists(MUSICA_NINAR):
		push_warning("AberturaLivro: música de ninar não encontrada: " + MUSICA_NINAR)
		return
	_musica.stream = load(MUSICA_NINAR)
	_musica.volume_db = -30.0
	_musica.play()
	var t := create_tween().set_parallel(true)
	t.tween_property(_musica, "volume_db", VOLUME_NINAR_DB, 2.0)
	if _noite and _noite.playing:
		t.tween_property(_noite, "volume_db", VOLUME_NOITE_COM_NINAR_DB, 3.0)
	if _historia and _historia.playing:
		t.tween_property(_historia, "volume_db", -40.0, TROCA_MUSICA)
		t.chain().tween_callback(_historia.stop)


func _tocar_historia() -> void:
	if not ResourceLoader.exists(MUSICA_HISTORIA):
		push_warning("AberturaLivro: musiquinha não encontrada: " + MUSICA_HISTORIA)
		return
	var stream = load(MUSICA_HISTORIA)
	if "loop" in stream:
		stream.loop = true
	_historia.stream = stream
	_historia.volume_db = -30.0
	_historia.play()
	var t := create_tween()
	t.tween_property(_historia, "volume_db", VOLUME_HISTORIA_DB, 2.0)


func _tocar_noite() -> void:
	if not ResourceLoader.exists(SOM_NOITE):
		push_warning("AberturaLivro: som da noite não encontrado: " + SOM_NOITE)
		return
	var stream = load(SOM_NOITE)
	if "loop" in stream:
		stream.loop = true
	_noite.stream = stream
	_noite.volume_db = -40.0
	_noite.play()
	var t := create_tween()
	t.tween_property(_noite, "volume_db", VOLUME_NOITE_DB, 2.5)


# ---------------------------------------------------------------- TELA

func _montar() -> void:
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(raiz)

	var preto := ColorRect.new()
	preto.color = Color.BLACK
	preto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(preto)

	_imagem_a = _nova_imagem(raiz)
	_imagem_b = _nova_imagem(raiz)

	var altura := get_viewport().get_visible_rect().size.y
	_palpebra_cima = _nova_palpebra(raiz, true)
	_palpebra_cima.position.y = -_palpebra_cima.size.y
	_palpebra_baixo = _nova_palpebra(raiz, false)
	_palpebra_baixo.position.y = altura

	_fundo_preto = ColorRect.new()
	_fundo_preto.color = Color.BLACK
	_fundo_preto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fundo_preto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fundo_preto.visible = false
	raiz.add_child(_fundo_preto)

	_botao_pular = Button.new()
	_botao_pular.text = "Pular"
	_botao_pular.focus_mode = Control.FOCUS_NONE
	_botao_pular.add_theme_font_size_override("font_size", 20)
	_botao_pular.add_theme_color_override("font_color", Color("fff1c9"))
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.17, 0.13, 0.25, 0.75)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(10)
	_botao_pular.add_theme_stylebox_override("normal", estilo)
	_botao_pular.add_theme_stylebox_override("hover", estilo)
	_botao_pular.add_theme_stylebox_override("pressed", estilo)
	_botao_pular.anchor_left = 1.0
	_botao_pular.anchor_right = 1.0
	_botao_pular.anchor_top = 1.0
	_botao_pular.anchor_bottom = 1.0
	_botao_pular.offset_left = -120
	_botao_pular.offset_top = -64
	_botao_pular.offset_right = -20
	_botao_pular.offset_bottom = -20
	_botao_pular.pressed.connect(_on_pular)
	raiz.add_child(_botao_pular)

	_musica = AudioStreamPlayer.new()
	_musica.bus = BUS_MUSICA if AudioServer.get_bus_index(BUS_MUSICA) != -1 else "Master"
	add_child(_musica)

	_historia = AudioStreamPlayer.new()
	_historia.bus = _musica.bus
	add_child(_historia)

	_noite = AudioStreamPlayer.new()
	_noite.bus = BUS_EFEITOS if AudioServer.get_bus_index(BUS_EFEITOS) != -1 else "Master"
	add_child(_noite)


func _nova_imagem(pai: Control) -> TextureRect:
	var img := TextureRect.new()
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(img)
	return img


# Pálpebra: preta, com a borda que encosta no meio da tela bem suave.
func _nova_palpebra(pai: Control, de_cima: bool) -> TextureRect:
	var tela := get_viewport().get_visible_rect().size
	var gradiente := Gradient.new()
	if de_cima:
		gradiente.set_color(0, Color.BLACK)
		gradiente.set_color(1, Color(0, 0, 0, 0))
		gradiente.add_point(0.8, Color.BLACK)
	else:
		gradiente.set_color(0, Color(0, 0, 0, 0))
		gradiente.set_color(1, Color.BLACK)
		gradiente.add_point(0.2, Color.BLACK)
	var textura := GradientTexture2D.new()
	textura.gradient = gradiente
	textura.fill_from = Vector2(0, 0)
	textura.fill_to = Vector2(0, 1)
	textura.width = 4
	textura.height = 256
	var p := TextureRect.new()
	p.texture = textura
	p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p.stretch_mode = TextureRect.STRETCH_SCALE
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size = Vector2(tela.x, tela.y * 0.5 + 240.0)
	p.position = Vector2.ZERO
	pai.add_child(p)
	return p


func _carregar(caminho: String) -> Texture2D:
	if ResourceLoader.exists(caminho):
		return load(caminho) as Texture2D
	push_warning("AberturaLivro: imagem não encontrada: " + caminho)
	return null
