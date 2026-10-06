extends Control
class_name Floresta
## Floresta.
## A cena SEMPRE abre e mostra a imagem da floresta.
## Só leva para um mini-jogo quando a missão correspondente está ativa:
##   - Pietro ativo e pincéis não concluídos  -> mini-jogo dos pincéis
##   - Vincent ativo e luvas não concluídas   -> mini-jogo das luvas
## Se uma variável do Dialogic não existir, conta como "não" (não trava).

const MINIGAME_PINCEIS: String = "res://scenes/minigame_pietro_floresta_pinceis_01.tscn"
# Caminho corrigido para o arquivo real da cena:
const MINIGAME_LUVAS: String = "res://scenes/minigame_secundario_vincent.tscn"


func _ready() -> void:
	call_deferred("_verificar_acesso_floresta")


func _verificar_acesso_floresta() -> void:
	# 1. Checa Pietro
	var pietro_ativo := _ler_qualquer([
		"Bolo.Pietro.Bolo_Pietro_Em_Andamento",
		"Bolo.Pietro.Em_Andamento",
	])
	var pietro_concluido := _ler_qualquer([
		"Bolo.Pietro.Bolo_Pietro_Pinceis_Concluido",
		"Bolo.Pietro.Pinceis_Concluido",
	])

	if pietro_ativo and not pietro_concluido:
		_ir_para(MINIGAME_PINCEIS)
		return

	# 2. Checa Vincent (a variável que fica true ao aceitar no diálogo)
	var vincent_ativo := _ler_qualquer([
		"Bolo.Vincent.Bolo_Vincent_Em_Andamento",
		"Bolo.Vincent.Em_Andamento",
	])
	var luvas_concluidas := _ler_qualquer([
		"Bolo.Vincent.Bolo_Vincent_Luvas_Concluido",
		"Bolo.Vincent.Luvas_Concluido",
	])

	if vincent_ativo and not luvas_concluidas:
		_ir_para(MINIGAME_LUVAS)
		return

	# 3. Nenhuma missão ativa: fica na floresta, mostrando a imagem.
	print(">>> Floresta: nenhuma missão ativa, mostrando a floresta")


# ---------------------------------------------------------------- AJUDANTES

# Devolve true se QUALQUER um dos nomes existir no Dialogic e for true.
# Nomes que não existem são ignorados (não travam o jogo).
func _ler_qualquer(caminhos: Array) -> bool:
	for caminho in caminhos:
		var valor = _ler(str(caminho))
		if valor != null:
			return valor == true
	return false


# Lê uma variável do Dialogic pelo caminho (ex: "Bolo.Vincent.Em_Andamento").
# Devolve null se ela não existir.
func _ler(caminho: String):
	var atual = Dialogic.current_state_info.get("variables", {})
	for parte in caminho.split("."):
		if atual is Dictionary and atual.has(parte):
			atual = atual[parte]
		else:
			return null
	return atual


func _ir_para(caminho: String) -> void:
	if not ResourceLoader.exists(caminho):
		push_warning("floresta: cena do mini-jogo não encontrada: " + caminho + " (ficando na floresta)")
		return
	print(">>> Floresta: missão ativa, indo para ", caminho)
	get_tree().change_scene_to_file.call_deferred(caminho)
