extends Control
class_name BotaoBellaPresente
## Bella da praça (cena bella_presente.tscn).
## O clique NÃO abre o diálogo aqui: só leva o jogador para a mesa e deixa um
## recado. A mesa (mesa_praca_iv.gd) vê o recado, começa a conversa
## "bella_presente" e, quando ela termina, decide para onde ir
## (minigame do cartão ou de volta para a praça).

const CENA_MESA := "res://scenes/mesa_praca_iv.tscn"

## Recado para a mesa (o mesmo nome usado no mesa_praca_iv.gd).
const RECADO := "bella_falar_na_mesa"

var _trocando: bool = false
var _tween_brilho: Tween = null


func _ready() -> void:
	# O grupo avisa a praça que esta Bella cuida do próprio clique,
	# e deixa a praça pedir o brilho quando o cartão for liberado.
	add_to_group("bella_presente")
	print(">>> Bella: pronta em ", _cena_atual())
	atualizar_destaque()


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


# Chamado pela conexão do editor (pressed do botão da Bella).
func _on_bella_pressed() -> void:
	if _trocando or Dialogic.current_timeline:
		return

	# Se esta Bella estiver na própria mesa, a mesa cuida da conversa.
	if _cena_atual() == CENA_MESA:
		var mesa := get_tree().current_scene
		if mesa != null and mesa.has_method("_on_bella_botao_pressed"):
			mesa.call("_on_bella_botao_pressed")
		return

	print(">>> Bella: indo para a mesa antes de conversar")
	get_tree().root.set_meta(RECADO, true)
	_ir_para(CENA_MESA)


# ---------------------------------------------------------------- BRILHO

## Chamado pela praça quando o último morador termina de conversar.
## A Bella pisca de leve enquanto o cartão está liberado e ainda não foi feito.
func atualizar_destaque() -> void:
	var liberado: bool = _ler("Cap4.Cartao_Liberado") == true
	var feito: bool = _ler("Cap4.Cartao_Feito") == true
	if liberado and not feito and _cena_atual() != CENA_MESA:
		_iniciar_destaque()
	else:
		_parar_destaque()


func _iniciar_destaque() -> void:
	if _tween_brilho != null:
		return
	_tween_brilho = create_tween().set_loops()
	_tween_brilho.tween_property(self, "modulate", Color(1.3, 1.3, 1.3, 1.0), 0.6)
	_tween_brilho.tween_property(self, "modulate", Color.WHITE, 0.6)


func _parar_destaque() -> void:
	if _tween_brilho != null:
		_tween_brilho.kill()
		_tween_brilho = null
	modulate = Color.WHITE


# ---------------------------------------------------------------- AJUDANTES

func _ler(caminho: String, padrao = false):
	var atual = Dialogic.current_state_info.get("variables", {})
	for parte in caminho.split("."):
		if atual is Dictionary and atual.has(parte):
			atual = atual[parte]
		else:
			return padrao
	return atual


func _cena_atual() -> String:
	var cena := get_tree().current_scene
	return cena.scene_file_path if cena else ""


func _ir_para(caminho: String) -> void:
	if _trocando:
		return
	if not ResourceLoader.exists(caminho):
		push_error("bella_presente: cena não encontrada: " + caminho)
		get_tree().root.remove_meta(RECADO)
		return
	_trocando = true
	_parar_destaque()
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	get_tree().call_deferred("change_scene_to_file", caminho)
