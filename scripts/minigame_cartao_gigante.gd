extends Node2D
class_name MinigameCartaoGigante
## Minigame do Cartão Gigante — Capítulo IV
## As peças ficam SEMPRE na bandeja (barra_cartao/Barra2).
## Ao arrastar, uma cópia flutuante ("fantasma") segue o mouse.
## Ao soltar perto da sombra certa, nasce uma peça colorida no lugar exato
## da sombra (mesma posição e tamanho) e a sombra é escondida.

const PARES := {
	"SolRadiante": "SolRadianteSobra",
	"PoemaEmGota": "PoemaEmGotaSobra",
	"EscudoTorto": "EscudoTortoSobra",
	"SeloDeCeraVermelho": "SeloDeCeraVermelhoSobra",
	"Dente-de-leão": "Dente-de-leãoSobra",
	"Cartao": "MolduraGeométricaSobra",
}

## Peças cuja versão final usa a textura da SOMBRA (e não a da bandeja).
## A moldura da bandeja é um cartãozinho com papel no meio, que tamparia tudo;
## a textura da sombra é só o contorno, com o meio transparente.
const USAR_TEXTURA_DA_SOMBRA := ["Cartao"]

## Peças que, depois de encaixadas, ficam desenhadas logo acima do fundo
## "Cartao" (atrás de todas as outras peças e do "Feliz Aniversário").
const FICAR_ATRAS := ["Cartao"]
const NO_FUNDO_CARTAO := "Cartao"   # o Sprite2D de fundo, na raiz da cena

const CAMINHO_BANDEJA := "barra_cartao/Barra2/"
const LIMITE_MINIMO := 90.0        # distância mínima aceita (px de tela)
const FRACAO_LIMITE := 0.35        # sombras grandes aceitam distância maior
## Ao terminar, a Bella fala pela timeline "bella_presente": como
## Cap4.Cartao_Feito já está ligado, ela cai na fala "Ficou espetacular!..."
## e, quando termina, o jogo vai para a loja da Linna.
const TIMELINE_FIM := "bella_presente"
const CENA_LOJA := "res://scenes/loja_IV.tscn"   # ajuste se a cena da loja tiver outro nome
const MOSTRAR_LOG := true

var _pecas := {}        # nome -> TextureButton (na bandeja)
var _sombras := {}      # nome -> Sprite2D (alvo no cartão)
var _encaixadas := {}   # nome -> bool

var _camada_arraste: CanvasLayer
var _fantasma: Sprite2D = null
var _nome_arrastando := ""
var _deslocamento := Vector2.ZERO
var _terminou := false


func _ready() -> void:
	# Camada própria para o fantasma ficar por cima da bandeja e do cartão
	_camada_arraste = CanvasLayer.new()
	_camada_arraste.layer = 100
	add_child(_camada_arraste)

	for nome in PARES:
		var peca := get_node_or_null(CAMINHO_BANDEJA + nome) as TextureButton
		var sombra := get_node_or_null(PARES[nome]) as Sprite2D

		if peca == null:
			push_error("Peça não encontrada (ou não é TextureButton): " + CAMINHO_BANDEJA + nome)
			continue
		if sombra == null:
			push_error("Sombra não encontrada (ou não é Sprite2D): " + PARES[nome])
			continue

		_pecas[nome] = peca
		_sombras[nome] = sombra
		_encaixadas[nome] = false
		peca.button_down.connect(_comecar_arraste.bind(nome))


func _exit_tree() -> void:
	if Dialogic.timeline_ended.is_connected(_ao_fim_timeline):
		Dialogic.timeline_ended.disconnect(_ao_fim_timeline)


# ---------------------------------------------------------------- ARRASTE

func _comecar_arraste(nome: String) -> void:
	if _terminou or _fantasma != null or _encaixadas.get(nome, true):
		return

	var peca: TextureButton = _pecas[nome]
	var tex := peca.texture_normal
	if tex == null:
		push_error("A peça '%s' está sem Texture Normal." % nome)
		return

	var centro_tela := _centro_peca_tela(peca)
	var tamanho_tela := _tamanho_peca_tela(peca)

	_fantasma = Sprite2D.new()
	_fantasma.texture = tex
	_fantasma.centered = true
	var esc := minf(tamanho_tela.x / tex.get_width(), tamanho_tela.y / tex.get_height())
	_fantasma.scale = Vector2(esc, esc)
	_fantasma.position = centro_tela
	_camada_arraste.add_child(_fantasma)

	_deslocamento = centro_tela - get_viewport().get_mouse_position()
	_nome_arrastando = nome
	peca.modulate.a = 0.35


func _input(event: InputEvent) -> void:
	if _fantasma == null:
		return

	if event is InputEventMouseMotion:
		_fantasma.position = get_viewport().get_mouse_position() + _deslocamento
	elif event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		_soltar()


func _soltar() -> void:
	var nome := _nome_arrastando
	var fantasma := _fantasma
	_fantasma = null
	_nome_arrastando = ""

	var sombra: Sprite2D = _sombras[nome]
	var centro_sombra := _centro_sombra_tela(sombra)
	var tamanho_sombra := _tamanho_sombra_tela(sombra)

	var limite := maxf(LIMITE_MINIMO, minf(tamanho_sombra.x, tamanho_sombra.y) * FRACAO_LIMITE)
	var distancia := fantasma.position.distance_to(centro_sombra)

	if MOSTRAR_LOG:
		print(">>> Soltou '%s' a %.1f px da sombra (limite %.1f). Peça: %s | Sombra: %s"
			% [nome, distancia, limite, fantasma.position, centro_sombra])

	if distancia <= limite:
		_encaixar(nome, fantasma, centro_sombra, tamanho_sombra)
	else:
		_devolver(nome, fantasma)


# ---------------------------------------------------------------- RESULTADOS

func _encaixar(nome: String, fantasma: Sprite2D, centro: Vector2, tamanho: Vector2) -> void:
	_encaixadas[nome] = true

	# A peça some da bandeja sem sair dela (não bagunça o layout das outras)
	var peca: TextureButton = _pecas[nome]
	peca.modulate.a = 0.0
	peca.disabled = true
	peca.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var sombra: Sprite2D = _sombras[nome]
	var usa_sombra := nome in USAR_TEXTURA_DA_SOMBRA

	# Fantasma desliza até a sombra e assume o tamanho dela
	# (a moldura vai sumindo no caminho, para o papel opaco não tampar nada)
	var escala_final := tamanho / fantasma.texture.get_size()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fantasma, "position", centro, 0.15)
	tw.tween_property(fantasma, "scale", escala_final, 0.15)
	if usa_sombra:
		tw.tween_property(fantasma, "modulate:a", 0.0, 0.15)
	await tw.finished

	# Nasce a peça definitiva, colorida, no lugar exato da sombra
	var tex_final: Texture2D = sombra.texture if usa_sombra else fantasma.texture
	var final := _criar_peca_final(sombra, tex_final, nome in FICAR_ATRAS)
	fantasma.queue_free()
	sombra.visible = false

	# "Pulinho" de comemoração
	var escala_original := final.scale
	var pulo := create_tween()
	pulo.tween_property(final, "scale", escala_original * 1.08, 0.08)
	pulo.tween_property(final, "scale", escala_original, 0.10)

	_verificar_fim()


func _criar_peca_final(sombra: Sprite2D, tex: Texture2D, ficar_atras: bool) -> Sprite2D:
	var final := Sprite2D.new()
	final.name = sombra.name + "_Final"
	final.texture = tex
	final.centered = true
	final.z_index = sombra.z_index
	final.z_as_relative = sombra.z_as_relative

	# Mesmo lugar e mesmo tamanho na tela que a sombra ocupa,
	# independente de modulate, self_modulate ou material da sombra.
	var rect := sombra.get_rect()
	final.position = sombra.transform * rect.get_center()
	final.rotation = sombra.rotation
	final.scale = sombra.scale * (rect.size / tex.get_size())

	var fundo := get_node_or_null(NO_FUNDO_CARTAO)
	if ficar_atras and fundo != null and fundo.get_parent() == sombra.get_parent():
		# Logo acima do fundo do cartão: atrás de todas as outras peças
		fundo.add_sibling(final)
	else:
		# Logo depois da sombra, mantendo a mesma ordem de desenho
		sombra.add_sibling(final)
	return final


func _devolver(nome: String, fantasma: Sprite2D) -> void:
	var peca: TextureButton = _pecas[nome]
	var tw := create_tween()
	tw.tween_property(fantasma, "position", _centro_peca_tela(peca), 0.2)
	await tw.finished
	fantasma.queue_free()
	peca.modulate.a = 1.0


func _verificar_fim() -> void:
	if _terminou:
		return
	for nome in _encaixadas:
		if not _encaixadas[nome]:
			return
	_finalizar()


func _finalizar() -> void:
	_terminou = true
	if Dialogic.VAR.has("Cap4.Cartao_Feito"):
		Dialogic.VAR.set_variable("Cap4.Cartao_Feito", true)
	else:
		push_warning("minigame_cartao_gigante: crie no Dialogic a variável Cap4.Cartao_Feito (tipo bool).")

	# Um instante para o jogador ver o cartão pronto antes da Bella falar.
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return

	if not Dialogic.timeline_ended.is_connected(_ao_fim_timeline):
		Dialogic.timeline_ended.connect(_ao_fim_timeline, CONNECT_ONE_SHOT)
	print(">>> Cartão pronto: Bella falando (", TIMELINE_FIM, ")")
	Dialogic.start(TIMELINE_FIM)


# Fim da fala da Bella: vai para a loja da Linna.
func _ao_fim_timeline() -> void:
	if ResourceLoader.exists(CENA_LOJA):
		print(">>> Cartão pronto: indo para a loja da Linna")
		get_tree().call_deferred("change_scene_to_file", CENA_LOJA)
	else:
		push_warning("Cena da loja ainda não existe: " + CENA_LOJA)


# ---------------------------------------------------------------- COORDENADAS (tudo em pixels de tela)

func _centro_peca_tela(peca: TextureButton) -> Vector2:
	return peca.get_global_transform_with_canvas() * (peca.size / 2.0)


func _tamanho_peca_tela(peca: TextureButton) -> Vector2:
	return peca.size * peca.get_global_transform_with_canvas().get_scale()


func _centro_sombra_tela(sombra: Sprite2D) -> Vector2:
	return sombra.get_global_transform_with_canvas() * sombra.get_rect().get_center()


func _tamanho_sombra_tela(sombra: Sprite2D) -> Vector2:
	return sombra.get_rect().size * sombra.get_global_transform_with_canvas().get_scale()
