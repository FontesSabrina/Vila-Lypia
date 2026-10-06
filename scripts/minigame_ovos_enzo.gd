extends Node2D
class_name CozinhaPrincipalEnzo
## Cozinha do Enzo (mini-jogo dos ovos).
## Lupa 1 = armário (chave). Lupa 2 = geladeira (só abre com a chave).
## Ao voltar com os ovos, o Enzo agradece e o jogo volta ao mapa.

const CENA_ARMARIO := "res://scenes/minigame_ovos_enzo_armario.tscn"
const CENA_GELADEIRA := "res://scenes/minigame_ovos_enzo_geladeira.tscn"
const CENA_MAPA := "res://scenes/mapa_pricipal.tscn"


func _ready() -> void:
	if is_instance_valid(GameState) and GameState.ovos_pego:
		# Pequena pausa para a cena aparecer antes da fala
		await get_tree().create_timer(0.2).timeout
		if not is_inside_tree() or Dialogic.current_timeline:
			return
		Dialogic.start("bolo_enzo_02")
		await Dialogic.timeline_ended
		if is_inside_tree():
			get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


# Lupa do armário de baixo
func _on_lupa_01_pressed() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_ARMARIO)


# Lupa da geladeira: só abre com a chave (guardada no GameState, que é salvo)
func _on_lupa_02_pressed() -> void:
	if GameState.chave_pega:
		get_tree().change_scene_to_file.call_deferred(CENA_GELADEIRA)
	else:
		print("A geladeira está trancada! Preciso achar a chave.")
