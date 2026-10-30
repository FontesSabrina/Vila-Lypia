extends Node2D
class_name CapituloFinal_Novo
## Capítulo Final — A Festa (O Grande Final)
##
## A PRÓPRIA CENA é o fundo (o Dialogic fica sem [background]).
## Assim o bolo do jogador aparece de verdade, porque é um nó da cena.
##
## Estrutura da cena (capitulo_final.tscn):
##   capitulo_final (Node2D, este script)
##   ├── PracaEscura (Sprite2D)            <- praça com as luzes apagadas (começo)
##   ├── PracaAcesa  (Sprite2D)            <- praça com as luzes acesas (depois do "SURPRESA!")
##   ├── ResultadoBolo (resultadoBolo.tscn) <- bolo pequeno no gazebo (também aceita o nome "BoloPraca")
##   └── Mesa (Node2D)                      <- opcional: visão de perto da mesa
##       ├── Fundo (Sprite2D)
##       ├── ResultadoBolo (resultadoBolo.tscn)
##       └── Presente (Node2D, opcional) -> caixinha / veludo / caderno / kit (Sprite2D)
##
## Sinais que a timeline manda:
##   acender_luzes     -> a praça acende (troca suave da escura para a acesa)
##   apagar_luzes      -> a praça apaga de novo (fim do Final 1)
##   flash             -> clarão branco na tela
##   mostrar_bolo      -> mostra a Mesa de perto (se existir)
##   esconder_bolo     -> volta para a praça
##   ganhar_lapis      -> o jogador ganha o Lápis Mágico
##   tentar_novamente  -> no fim da conversa, apaga o save e volta para o início
##   creditos          -> no fim da conversa: céu estrelado + "Fim" e depois os créditos
##
## CENA FINAL DO CÉU: quando a conversa termina, a "câmera" sobe pela praça
## até o céu estrelado com a lua e o "Fim" (imagem praca_ceu_fim.jpg: a praça
## acesa com o céu em cima, numa imagem só). Se a imagem não existir, o script
## desenha um céu e escreve "Fim". Depois, créditos.
##
## TESTE: rode a CENA (F6 com capitulo_final.tscn aberta), não o "Play Timeline"
## do Dialogic. No "Play Timeline" esta cena não é carregada.

const TIMELINE := "capitulo_final"
const CENA_CREDITOS := "res://scenes/creditos.tscn"
const CENA_INICIO := "res://scenes/main.tscn"

## Pontos de cada presente da loja da Linna.
const PONTOS_PRESENTE := {
	"caixinha": 1,
	"veludo": 3,
	"caderno": 4,
	"kit": 6,
}

## A partir de quantos pontos (0 a 18) o jogador ganha o Final 2.
## Abaixo disso é o Final 1. O Final 3 exige tudo completo.
const PONTOS_FINAL_NEUTRO := 8

## Os 6 convites do Capítulo II (pasta "Convite" do Dialogic).
const CONVITES := [
	"Convite.Convite_vincent_entregue",
	"Convite.Convite_Linna_entregue",
	"Convite.Convite_pietro_entregue",
	"Convite.Convite_P_Hera_entregue",
	"Convite.Convite_enzo_entregue",
	"Convite.Convite_Xerife_entregue",
]

## SÓ PARA TESTE: 0 = calcula o final normalmente.
## 1, 2 ou 3 = força esse final (para testar cada um sem jogar tudo).
## IMPORTANTE: volte para 0 antes de exportar.
const FINAL_DE_TESTE := 0

## SÓ PARA TESTE: bolo usado quando o Capítulo III ainda não foi jogado (-1).
const BOLO_DE_TESTE := 6

## Tempo (segundos) da troca entre praça escura e acesa.
const TEMPO_LUZES := 0.8

## Brilho dourado do bolo no Final Verdadeiro.
const COR_BRILHO := Color(1.3, 1.2, 0.95)

# --- Cena final do céu ---
## Em quais finais aparece o céu estrelado + "Fim" antes dos créditos.
const FINAIS_COM_CEU := [2, 3]
## Tempo (segundos) que a praça leva para descer e o céu aparecer.
const TEMPO_SUBIDA_CEU := 7.0
## Quanto tempo o "Fim" fica na tela antes dos créditos.
const TEMPO_FIM := 4.0
const TEXTO_FIM := "Fim"
## Imagem do céu com a lua e o "Fim". Se ela existir, é usada no lugar do céu
## desenhado pelo script (e o script NÃO escreve "Fim" por cima, porque a
## imagem já tem). Se não existir, o script desenha o céu e escreve "Fim".
const IMAGEM_CEU := "res://assets/backgrounds/praca_ceu_fim.jpg"
## Parte de baixo do céu (0.12 = 12%) que vira degradê por cima da praça,
## para a emenda entre as duas imagens não aparecer.
const FAIXA_EMENDA := 0.12

var _destino := ""
var _trocando := false
var _tween_brilho: Tween

@onready var praca_escura: CanvasItem = get_node_or_null("PracaEscura") as CanvasItem
@onready var praca_acesa: CanvasItem = get_node_or_null("PracaAcesa") as CanvasItem
## Aceita os dois nomes: "BoloPraca" ou "ResultadoBolo" (direto na raiz da cena).
@onready var bolo_praca: ResultadoBolo = (get_node_or_null("BoloPraca") if has_node("BoloPraca") else get_node_or_null("ResultadoBolo")) as ResultadoBolo
@onready var mesa: CanvasItem = get_node_or_null("Mesa") as CanvasItem
@onready var resultado_bolo: ResultadoBolo = get_node_or_null("Mesa/ResultadoBolo") as ResultadoBolo
@onready var presente: Node = get_node_or_null("Mesa/Presente")


func _ready() -> void:
	_preparar_cenario()
	_calcular_final()

	Dialogic.signal_event.connect(_on_dialogic_signal)
	Dialogic.timeline_ended.connect(_on_timeline_ended)

	# Fecha qualquer conversa que tenha sobrado da loja (anoitecer).
	if Dialogic.current_timeline:
		Dialogic.end_timeline()

	Dialogic.start(TIMELINE)


func _exit_tree() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)


# ---------------------------------------------------------------- CENÁRIO

## Começa com a praça escura, a mesa escondida e o bolo do gazebo pronto.
func _preparar_cenario() -> void:
	if praca_escura:
		praca_escura.visible = true
	else:
		push_warning("capitulo_final: nó 'PracaEscura' não encontrado.")

	if praca_acesa:
		praca_acesa.visible = true
		praca_acesa.modulate.a = 0.0
	else:
		push_warning("capitulo_final: nó 'PracaAcesa' não encontrado (a praça não vai acender).")

	if bolo_praca:
		bolo_praca.mostrar_bolo(_ingredientes_do_bolo())

	if mesa:
		mesa.visible = false


func _acender_luzes(acesa: bool) -> void:
	if praca_acesa == null:
		return
	var alvo := 1.0 if acesa else 0.0
	create_tween().tween_property(praca_acesa, "modulate:a", alvo, TEMPO_LUZES)


# ---------------------------------------------------------------- CÁLCULO DO FINAL

func _calcular_final() -> void:
	var convites := 0
	for variavel in CONVITES:
		if _verdadeiro(Dialogic.VAR.get_variable(variavel)):
			convites += 1

	var bolo: int = _ingredientes_do_bolo()
	var presente_comprado: String = GameState.presente_comprado
	var pontos: int = convites + bolo + int(PONTOS_PRESENTE.get(presente_comprado, 0))

	var tipo := 1
	if convites == 6 and bolo == 6 and presente_comprado == "kit":
		tipo = 3
	elif pontos >= PONTOS_FINAL_NEUTRO:
		tipo = 2

	if FINAL_DE_TESTE in [1, 2, 3]:
		tipo = FINAL_DE_TESTE
		print(">>> Final: usando FINAL_DE_TESTE = ", tipo)

	Dialogic.VAR.set_variable("Final.Convites", convites)
	Dialogic.VAR.set_variable("Final.Bolo", bolo)
	Dialogic.VAR.set_variable("Final.Presente", presente_comprado)
	Dialogic.VAR.set_variable("Final.Pontos", pontos)
	Dialogic.VAR.set_variable("Final.Tipo", tipo)
	GameState.final_alcancado = tipo

	print(">>> Final: convites=%d bolo=%d presente='%s' pontos=%d -> FINAL %d" % [convites, bolo, presente_comprado, pontos, tipo])


func _ingredientes_do_bolo() -> int:
	if GameState.bolo_ingredientes < 0:
		return BOLO_DE_TESTE
	return clampi(GameState.bolo_ingredientes, 0, 6)


func _verdadeiro(valor) -> bool:
	if valor is bool:
		return valor
	return str(valor).to_lower() == "true"


# ---------------------------------------------------------------- SINAIS

func _on_dialogic_signal(argumento: String) -> void:
	match argumento:
		"acender_luzes":
			_acender_luzes(true)
		"apagar_luzes":
			_acender_luzes(false)
		"flash":
			_flash()
		"mostrar_bolo":
			_mostrar_mesa()
		"esconder_bolo":
			_esconder_mesa()
		"ganhar_lapis":
			GameState.ganhar_lapis_magico()
		"tentar_novamente":
			_destino = "tentar_novamente"
		"creditos":
			_destino = "creditos"


func _on_timeline_ended() -> void:
	match _destino:
		"tentar_novamente":
			_tentar_novamente()
		_:
			# "creditos" ou qualquer outro caso.
			if GameState.final_alcancado in FINAIS_COM_CEU:
				_cena_do_ceu()
			else:
				_ir_para(CENA_CREDITOS)


# ---------------------------------------------------------------- MESA, BOLO E PRESENTE

func _mostrar_mesa() -> void:
	if mesa == null:
		return

	if resultado_bolo:
		resultado_bolo.mostrar_bolo(_ingredientes_do_bolo())

	_mostrar_presente()

	mesa.visible = true
	mesa.modulate.a = 0.0
	create_tween().tween_property(mesa, "modulate:a", 1.0, 0.6)

	# Final Verdadeiro: o bolo brilha (pulsa em dourado).
	if GameState.final_alcancado == 3 and resultado_bolo:
		_tween_brilho = create_tween().set_loops()
		_tween_brilho.tween_property(resultado_bolo, "self_modulate", COR_BRILHO, 0.9)
		_tween_brilho.tween_property(resultado_bolo, "self_modulate", Color.WHITE, 0.9)


func _esconder_mesa() -> void:
	if _tween_brilho and _tween_brilho.is_valid():
		_tween_brilho.kill()
	if resultado_bolo:
		resultado_bolo.self_modulate = Color.WHITE
	if mesa == null or not mesa.visible:
		return
	var tween := create_tween()
	tween.tween_property(mesa, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): mesa.visible = false)


## Mostra só o presente que o jogador comprou (filhos de "Presente" com o mesmo nome).
func _mostrar_presente() -> void:
	if presente == null:
		return
	var escolhido: String = GameState.presente_comprado
	for filho in presente.get_children():
		if filho is CanvasItem:
			(filho as CanvasItem).visible = (filho.name == escolhido)


# ---------------------------------------------------------------- EFEITOS

## Clarão branco por cima de tudo (fica acima do Dialogic).
func _flash() -> void:
	# Configuração "Sem clarões" (Acessibilidade): troca o clarão branco
	# por um escurecer-e-voltar bem suave, sem luz forte.
	var acess := get_node_or_null("/root/Acessibilidade")
	var sem_claroes: bool = acess != null and bool(acess.get("sem_claroes"))

	var camada := CanvasLayer.new()
	camada.layer = 128
	add_child(camada)

	var luz := ColorRect.new()
	luz.color = Color(0, 0, 0, 0) if sem_claroes else Color(1, 1, 1, 0)
	luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	luz.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(luz)

	var tween := create_tween()
	tween.tween_property(luz, "color:a", 0.35 if sem_claroes else 0.9, 0.6 if sem_claroes else 0.25)
	tween.tween_property(luz, "color:a", 0.0, 0.9)
	tween.tween_callback(camada.queue_free)


# ---------------------------------------------------------------- CENA FINAL DO CÉU

## A praça desce devagar, o céu estrelado com a lua desce junto por cima,
## aparece "Fim" e depois vão os créditos.
func _cena_do_ceu() -> void:
	var tela: Vector2 = get_viewport_rect().size
	var praca := praca_acesa as Sprite2D
	var usa_imagem := ResourceLoader.exists(IMAGEM_CEU)

	var ceu: Node2D
	var deslocamento: float

	if usa_imagem and praca and praca.texture:
		var area_praca: Rect2 = _area_na_tela(praca)

		var sprite := Sprite2D.new()
		sprite.texture = load(IMAGEM_CEU)
		sprite.centered = false
		var tam: Vector2 = sprite.texture.get_size()
		# Mesma largura da praça, para os dois desenhos terem o mesmo tamanho.
		var escala: float = area_praca.size.x / tam.x
		sprite.scale = Vector2(escala, escala)
		var altura_ceu: float = tam.y * escala

		# Imagem ALTA (praça + céu numa imagem só, como a praca_ceu_fim.jpg):
		# a parte de baixo dela é a própria praça, então ela fica exatamente
		# por cima da PracaAcesa e "sobe" até mostrar o céu.
		var imagem_alta: bool = altura_ceu > area_praca.size.y * 1.2
		if imagem_alta:
			sprite.position = Vector2(area_praca.position.x, area_praca.end.y - altura_ceu)
			ceu = sprite
			deslocamento = altura_ceu - area_praca.size.y
		else:
			# Imagem só do céu: fica colada em cima da praça, com emenda suave.
			var emenda: float = altura_ceu * FAIXA_EMENDA
			sprite.material = _material_emenda()
			sprite.position = Vector2(area_praca.position.x, area_praca.position.y - altura_ceu + emenda)
			ceu = sprite
			var topo_final: float = (tela.y - altura_ceu) / 2.0
			deslocamento = topo_final - sprite.position.y
	else:
		# --- Sem imagem (ou sem a PracaAcesa): céu desenhado pelo script ---
		var desenhado := CeuEstrelado.new()
		desenhado.tamanho = tela
		desenhado.position = Vector2(0, -tela.y)
		ceu = desenhado
		deslocamento = tela.y

	add_child(ceu)
	if praca:
		move_child(ceu, praca.get_index() + 1)

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Tudo desce junto (praça, bolo, mesa e o céu): parece que a câmera olha para cima.
	for filho in get_children():
		if filho is Node2D:
			tween.tween_property(filho, "position:y", (filho as Node2D).position.y + deslocamento, TEMPO_SUBIDA_CEU)

	await tween.finished
	if not is_inside_tree():
		return

	if usa_imagem:
		# A imagem já tem o "Fim": só espera um pouco na tela.
		await get_tree().create_timer(TEMPO_FIM + 1.5).timeout
	else:
		await _mostrar_fim()
	if is_inside_tree():
		_ir_para(CENA_CREDITOS)


## Retângulo que um Sprite2D ocupa na cena (posição e tamanho já com escala).
func _area_na_tela(sprite: Sprite2D) -> Rect2:
	var r: Rect2 = sprite.get_rect()
	var canto: Vector2 = sprite.to_global(r.position) - global_position
	return Rect2(canto, r.size * sprite.global_scale.abs())


## Shader que deixa a parte de baixo do céu transparente aos poucos.
func _material_emenda() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float faixa = 0.12;
void fragment() {
	vec4 cor = texture(TEXTURE, UV);
	cor.a *= 1.0 - smoothstep(1.0 - faixa, 1.0, UV.y);
	COLOR = cor;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("faixa", FAIXA_EMENDA)
	return mat


func _mostrar_fim() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)

	var fim := Label.new()
	fim.text = TEXTO_FIM
	fim.set_anchors_preset(Control.PRESET_FULL_RECT)
	fim.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fim.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fim.add_theme_font_size_override("font_size", 110)
	fim.add_theme_color_override("font_color", Color("fff1c9"))
	fim.add_theme_color_override("font_shadow_color", Color(1.0, 0.85, 0.45, 0.6))
	fim.add_theme_constant_override("shadow_offset_x", 0)
	fim.add_theme_constant_override("shadow_offset_y", 0)
	fim.add_theme_constant_override("shadow_outline_size", 18)
	fim.modulate.a = 0.0
	camada.add_child(fim)

	var tween := create_tween()
	tween.tween_property(fim, "modulate:a", 1.0, 1.5)
	tween.tween_interval(TEMPO_FIM)
	await tween.finished


## Céu noturno desenhado pelo código: degradê azul, estrelas que piscam e a lua.
class CeuEstrelado extends Node2D:
	var tamanho := Vector2(1152, 648)
	var _estrelas: Array = []
	var _tempo := 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 2026
		for i in 220:
			_estrelas.append({
				"pos": Vector2(rng.randf() * tamanho.x, rng.randf() * tamanho.y * 0.95),
				"raio": rng.randf_range(0.8, 2.4),
				"fase": rng.randf() * TAU,
				"velocidade": rng.randf_range(1.0, 3.0),
			})

	func _process(delta: float) -> void:
		_tempo += delta
		queue_redraw()

	func _draw() -> void:
		# Degradê do céu: azul bem escuro em cima, lilás perto do horizonte.
		var topo := Color("070b24")
		var meio := Color("1a1f4f")
		var baixo := Color("3b2c63")
		var h := tamanho.y
		draw_polygon(
			PackedVector2Array([Vector2(0, 0), Vector2(tamanho.x, 0), Vector2(tamanho.x, h * 0.6), Vector2(0, h * 0.6)]),
			PackedColorArray([topo, topo, meio, meio]))
		draw_polygon(
			PackedVector2Array([Vector2(0, h * 0.6), Vector2(tamanho.x, h * 0.6), Vector2(tamanho.x, h), Vector2(0, h)]),
			PackedColorArray([meio, meio, baixo, baixo]))

		# Estrelas piscando.
		for estrela in _estrelas:
			var brilho: float = 0.55 + 0.45 * sin(_tempo * float(estrela["velocidade"]) + float(estrela["fase"]))
			draw_circle(estrela["pos"], float(estrela["raio"]), Color(1, 1, 0.92, brilho))

		# Lua cheia com brilho em volta.
		var centro := Vector2(tamanho.x * 0.76, tamanho.y * 0.27)
		var raio := tamanho.y * 0.1
		for i in range(12, 0, -1):
			draw_circle(centro, raio * (1.0 + i * 0.12), Color(1.0, 0.95, 0.8, 0.025))
		draw_circle(centro, raio, Color("fff6d8"))
		# Manchinhas da lua.
		draw_circle(centro + Vector2(-raio * 0.3, -raio * 0.2), raio * 0.18, Color("eee2bd"))
		draw_circle(centro + Vector2(raio * 0.35, raio * 0.25), raio * 0.13, Color("eee2bd"))
		draw_circle(centro + Vector2(-raio * 0.05, raio * 0.45), raio * 0.09, Color("eee2bd"))


# ---------------------------------------------------------------- SAÍDAS

func _tentar_novamente() -> void:
	print(">>> Final: Tentar Novamente -> apagando save e voltando ao início")
	Salvamento.apagar()
	GameState.resetar()
	if Dialogic.VAR.has_method("reset"):
		Dialogic.VAR.reset()
	_ir_para(CENA_INICIO)


func _ir_para(caminho: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(caminho):
		push_error("capitulo_final: cena não encontrada: " + caminho)
		return
	_trocando = true
	get_tree().change_scene_to_file.call_deferred(caminho)
