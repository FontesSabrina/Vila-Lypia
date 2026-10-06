extends Control
class_name InventarioM
## Inventário (slots de itens) e contador de moedas.
## As moedas ficam SEMPRE no GameState: este script só mostra o número.
## Assim o valor não zera ao trocar de cena e é salvo junto com o jogo.

var jogo_mapa_concluido: bool = false
var item_mapa_pendente: ItemData = null

## Moedas do jogador (lidas do GameState).
var moedas: int:
	get:
		return GameState.moedas if is_instance_valid(GameState) else 0

var label_moedas: Node = null

@export var slots: Array[Slot]


func _ready() -> void:
	label_moedas = get_node_or_null("../LabelMoedas")

	# O número na tela acompanha o GameState automaticamente
	if is_instance_valid(GameState) and not GameState.moedas_alteradas.is_connected(_on_moedas_alteradas):
		GameState.moedas_alteradas.connect(_on_moedas_alteradas)
	_on_moedas_alteradas(moedas)

	# Todos os slots começam vazios
	for slot in slots:
		if slot:
			slot.definir_item(null)
			slot.item_guardado = null


func adicionar_item(item_data: ItemData) -> void:
	# Não adiciona se já existir no inventário
	for slot in slots:
		if slot and slot.item_guardado == item_data:
			print("Este item já está no inventário!")
			return

	# Adiciona no primeiro slot vazio
	for slot in slots:
		if slot and slot.item_guardado == null:
			slot.definir_item(item_data)
			slot.item_guardado = item_data
			print("Item fixado no slot!")
			return

	print("O inventário está cheio!")


## Soma moedas no GameState (o número na tela atualiza sozinho pelo sinal).
func adicionar_moedas(quantidade: int) -> void:
	if is_instance_valid(GameState):
		GameState.adicionar_moedas(quantidade)


func _on_moedas_alteradas(nova_quantidade: int) -> void:
	if label_moedas:
		label_moedas.text = str(nova_quantidade)


func _on_botao_fechar_pressed() -> void:
	visible = false
