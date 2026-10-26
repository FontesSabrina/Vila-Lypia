extends Node2D
class_name CapituloFinal
## Capítulo Final — A Festa (O Grande Final)
##
## A PRÓPRIA CENA é o fundo (o Dialogic fica sem [background]).
## Assim o bolo do jogador aparece de verdade, porque é um nó da cena.
##
## Estrutura da cena (capitulo_final.tscn):
##   CapituloFinal (Node2D, este script)
##   ├── PracaEscura (Sprite2D)          <- praça com as luzes apagadas (começo)
##   ├── PracaAcesa  (Sprite2D)          <- praça com as luzes acesas (depois do "SURPRESA!")
##   ├── ResultadoBolo (resultadoBolo.tscn) <- bolo pequeno no gazebo (também aceita o nome "BoloPraca")
##   └── Mesa (Node2D)                    <- opcional: visão de perto da mesa
##       ├── Fundo (Sprite2D)
##       ├── ResultadoBolo (resultadoBolo.tscn)
##       └── Presente (Node2D, opcional) -> caixinha / veludo / caderno / kit (Sprite2D)
##
## Sinais que a timeline manda:
##   acender_luzes     -> a praça acende (troca suave da escura para a acesa)
##   apagar_luzes      -> a praça apaga de novo (fim do Final 1)
##   flash             -> clarão branco na tela
##   mostrar_bolo      -> mostra a Mesa de perto com o bolo e o presente
##   esconder_bolo     -> volta para a praça
##   ganhar_lapis      -> o jogador ganha o Lápis Mágico
##   tentar_novamente  -> no fim da conversa, apaga o save e volta para o início
##   creditos          -> no fim da conversa, vai para a tela de créditos
##
## TESTE: rode a CENA (F6 com capitulo_final.tscn aberta), não o "Play Timeline"
## do Dialogic. No "Play Timeline" esta cena não é carregada, então o fundo
## e o bolo não aparecem.

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
const FINAL_DE_TESTE := 3

## SÓ PARA TESTE: bolo usado quando o Capítulo III ainda não foi jogado (-1).
const BOLO_DE_TESTE := 6

## Tempo (segundos) da troca entre praça escura e acesa.
const TEMPO_LUZES := 0.8

## Brilho dourado do bolo no Final Verdadeiro.
const COR_BRILHO := Color(1.3, 1.2, 0.95)

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
			# "creditos" ou qualquer outro caso: vai para os créditos.
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
	var camada := CanvasLayer.new()
	camada.layer = 128
	add_child(camada)

	var luz := ColorRect.new()
	luz.color = Color(1, 1, 1, 0)
	luz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	luz.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(luz)

	var tween := create_tween()
	tween.tween_property(luz, "color:a", 0.9, 0.25)
	tween.tween_property(luz, "color:a", 0.0, 0.9)
	tween.tween_callback(camada.queue_free)


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
