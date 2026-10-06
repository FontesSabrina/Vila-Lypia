extends Node2D
class_name MesaPracaIV
## Mesa do gazebo (visão aproximada) — Capítulo IV
## Mostra o bolo do Capítulo III e cuida da Bella DESTA cena.
##
## A conversa com a Bella (timeline "bella_presente") começa:
##   - sozinha, quando o jogador chega aqui vindo da Bella da praça;
##   - ou quando o jogador clica no bella_botao (conexão do editor:
##     pressed -> _on_bella_botao_pressed).
## Quando a timeline termina:
##   - sinal "iniciar_minigame_cartao" -> minigame do cartão
##   - sinal "ir_para_loja"            -> loja da Linna (cartão já pronto)
##   - qualquer outro caso             -> volta para a praça

const CENA_PRACA := "res://scenes/praca_festa_iv.tscn"
const CENA_MINIGAME := "res://scenes/minigame_cartao_gigante.tscn"
const CENA_LOJA := "res://scenes/loja_IV.tscn"   # ajuste se a cena da loja tiver outro nome

const TIMELINE := "bella_presente"
const SINAL_MINIGAME := "iniciar_minigame_cartao"
const SINAL_LOJA := "ir_para_loja"

## Mesmo recado que o praca_festa_iv.gd deixa quando o jogador clica na Bella da praça.
const RECADO := "bella_falar_na_mesa"
const ESPERA_AO_CHEGAR := 0.5

# Só para testar esta cena sozinha, sem jogar o Capítulo III antes.
const BOLO_DE_TESTE := 6

var _trocando := false
var _conversando := false
var _destino := ""

@onready var resultado_bolo: ResultadoBolo = get_node_or_null("ResultadoBolo") as ResultadoBolo
@onready var bella_botao: CanvasItem = get_node_or_null("bella_botao") as CanvasItem

# Opcional: um Button ou TextureButton chamado "BotaoVoltar" para voltar à praça.
@onready var botao_voltar: BaseButton = get_node_or_null("BotaoVoltar") as BaseButton


func _ready() -> void:
	_mostrar_bolo_da_mesa()
	if botao_voltar:
		botao_voltar.pressed.connect(_voltar_para_praca)

	if bella_botao == null:
		push_warning("mesa_praca_iv: nó 'bella_botao' não encontrado.")
	elif bella_botao is BaseButton:
		# Liga o clique se a conexão do editor não existir.
		var chamada := Callable(self, "_on_bella_botao_pressed")
		if not (bella_botao as BaseButton).pressed.is_connected(chamada):
			(bella_botao as BaseButton).pressed.connect(chamada)

	var veio_da_praca := _tem_recado()
	print(">>> Mesa: pronta | veio da Bella da praça: ", veio_da_praca)

	if veio_da_praca:
		_apagar_recado()
		_comecar_depois()


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	_desligar_dialogic()


# Clique no bella_botao (conexão feita pelo editor, Node -> Signals).
func _on_bella_botao_pressed() -> void:
	_comecar_conversa()


# ---------------------------------------------------------------- BOLO

func _mostrar_bolo_da_mesa() -> void:
	if resultado_bolo == null:
		push_warning("mesa_praca_iv: nó 'ResultadoBolo' não encontrado. Arraste a cena resultadoBolo.tscn para dentro desta cena.")
		return

	var total: int = GameState.bolo_ingredientes
	if total < 0:
		print(">>> Mesa: Capítulo III ainda não jogado, usando o bolo de teste (", BOLO_DE_TESTE, " ingredientes)")
		total = BOLO_DE_TESTE

	resultado_bolo.mostrar_bolo(total)

	resultado_bolo.modulate.a = 0.0
	create_tween().tween_property(resultado_bolo, "modulate:a", 1.0, 0.8)


# ---------------------------------------------------------------- CONVERSA

func _comecar_depois() -> void:
	await get_tree().create_timer(ESPERA_AO_CHEGAR).timeout
	if not is_inside_tree():
		return
	_comecar_conversa()


func _comecar_conversa() -> void:
	if _trocando or _conversando or Dialogic.current_timeline:
		return

	_conversando = true
	_destino = ""
	if bella_botao:
		bella_botao.visible = false   # fica só o retrato do Dialogic
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)

	print(">>> Mesa: iniciando ", TIMELINE)
	Dialogic.start(TIMELINE)


func _on_dialogic_signal(argumento: String) -> void:
	if not _conversando:
		return
	print(">>> Mesa: sinal recebido: ", argumento)
	if argumento == SINAL_MINIGAME:
		_destino = CENA_MINIGAME
	elif argumento == SINAL_LOJA:
		_destino = CENA_LOJA


func _on_timeline_ended() -> void:
	if not _conversando:
		return
	_conversando = false
	_desligar_dialogic()

	var destino := _destino if _destino != "" else CENA_PRACA
	_destino = ""
	print(">>> Mesa: conversa terminou, indo para ", destino)
	_ir_para(destino)


func _desligar_dialogic() -> void:
	if Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.disconnect(_on_dialogic_signal)
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)


# ---------------------------------------------------------------- AJUDANTES

func _tem_recado() -> bool:
	var raiz := get_tree().root
	return raiz.has_meta(RECADO) and raiz.get_meta(RECADO) == true


func _apagar_recado() -> void:
	var raiz := get_tree().root
	if raiz.has_meta(RECADO):
		raiz.remove_meta(RECADO)


func _voltar_para_praca() -> void:
	if _trocando or _conversando or Dialogic.current_timeline:
		return
	_ir_para(CENA_PRACA)


func _ir_para(caminho: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(caminho):
		push_error("mesa_praca_iv: cena não encontrada: " + caminho)
		if bella_botao:
			bella_botao.visible = true
		return
	_trocando = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	get_tree().call_deferred("change_scene_to_file", caminho)
