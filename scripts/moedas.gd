extends Node2D
class_name Moedas
## Contador de moedas na tela (HUD).
## Ele só MOSTRA o número: quem soma as moedas é sempre o GameState.
## Antes ele também somava quando ouvia o sinal "ganhar_moeda", e a cena
## (main, mapa, sala da Hera) somava de novo: cada moeda contava DUAS vezes.

@onready var label: Label = get_node_or_null("IconeMoeda/Label")


func _ready() -> void:
	# Os scripts das cenas acham este HUD por este grupo
	add_to_group("hud_moedas")
	if is_instance_valid(GameState) and not GameState.moedas_alteradas.is_connected(_on_moedas_alteradas):
		GameState.moedas_alteradas.connect(_on_moedas_alteradas)
	atualizar_interface()


func _on_moedas_alteradas(_nova_quantidade: int) -> void:
	atualizar_interface()


## Chamado por scripts antigos DEPOIS de somarem no GameState.
## Não soma de novo: só atualiza o número na tela.
func adicionar_moeda(_qtd: int = 1) -> void:
	atualizar_interface()


## Mesmo papel, com o nome que o mapa usa.
func atualizar_texto() -> void:
	atualizar_interface()


func atualizar_interface() -> void:
	if label and is_instance_valid(GameState):
		label.text = str(GameState.moedas)
