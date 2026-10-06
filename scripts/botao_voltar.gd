extends Control
class_name BotaoVoltar
## Seta de voltar: leva para o mapa principal.

const MAPA_PRINCIPAL := "res://scenes/mapa_pricipal.tscn"


# Conectado ao sinal pressed() do nó filho 'Seta'
func _on_seta_pressed() -> void:
	# Libera qualquer caixa/foco pendente antes de trocar de cena
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner:
		focus_owner.release_focus()
	get_tree().change_scene_to_file.call_deferred(MAPA_PRINCIPAL)
