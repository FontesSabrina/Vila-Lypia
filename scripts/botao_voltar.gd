extends Control
class_name BotaoVoltar
## Seta de voltar: leva para o mapa principal.
## Funciona também no meio de uma conversa do Dialogic.

const MAPA_PRINCIPAL := "res://scenes/mapa_pricipal.tscn"

## Camada acima da caixa de diálogo do Dialogic, para a seta aparecer por cima.
const CAMADA_SETA := 100

var _seta: Control = null
var _saindo := false


func _ready() -> void:
	_seta = get_node_or_null("Seta")
	if _seta == null:
		push_warning("botao_voltar: nó 'Seta' não encontrado.")
		return
	var camada := CanvasLayer.new()
	camada.layer = CAMADA_SETA
	add_child(camada)
	# Mantém a seta no mesmo lugar da tela, só que por cima da conversa.
	_seta.reparent(camada)


# O clique na seta é lido aqui, ANTES do Dialogic e da caixa de conversa.
# Assim a seta funciona mesmo quando a conversa está "segurando" o mouse.
func _input(event: InputEvent) -> void:
	if _saindo or _seta == null or not _seta.is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_event := _seta.make_input_local(event) as InputEventMouseButton
		if Rect2(Vector2.ZERO, _seta.size).has_point(local_event.position):
			get_viewport().set_input_as_handled()
			_on_seta_pressed()
	elif event is InputEventScreenTouch and event.pressed:
		var toque := _seta.make_input_local(event) as InputEventScreenTouch
		if Rect2(Vector2.ZERO, _seta.size).has_point(toque.position):
			get_viewport().set_input_as_handled()
			_on_seta_pressed()


# Também continua ligado ao sinal pressed() do nó filho 'Seta'
func _on_seta_pressed() -> void:
	if _saindo:
		return
	_saindo = true
	print(">>> botao_voltar: seta clicada, voltando para o mapa")
	# Libera qualquer caixa/foco pendente antes de trocar de cena
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
	# Se a Bella (ou outro morador) estiver falando, encerra a conversa,
	# senão ela continuaria aberta por cima do mapa.
	if Dialogic.current_timeline:
		Dialogic.end_timeline()
	get_tree().change_scene_to_file.call_deferred(MAPA_PRINCIPAL)
