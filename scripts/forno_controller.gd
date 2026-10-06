extends Node2D
class_name FornoController
## Forno do mini-jogo do bolo: aparece só depois que todos os ingredientes
## forem para a tigela.

@onready var forninho: TextureButton = get_node_or_null("Forninho")
@onready var forninho_ligado: TextureButton = get_node_or_null("ForninhoLigado")
@onready var forma_massa: TextureButton = get_node_or_null("FormaComMassa")


func _ready() -> void:
	# Nada da fase de assar aparece no início
	_mostrar(forninho, false)
	_mostrar(forninho_ligado, false)
	_mostrar(forma_massa, false)


## Receita concluída na tigela: o forno (desligado) e a massa aparecem.
func ativar_fase_assar() -> void:
	_mostrar(forninho, true)
	_mostrar(forma_massa, true)
	print("Fase de assar liberada: o forno e a forma com massa apareceram.")


func assar_bolo() -> void:
	if forma_massa:
		forma_massa.queue_free()
		forma_massa = null
	_mostrar(forninho, false)
	_mostrar(forninho_ligado, true)
	print("Bolo colocado no forno e assando!")


## O bolo pronto apareceu: o forno sai de cena.
func esconder_forno() -> void:
	if forninho:
		forninho.visible = false
	if forninho_ligado:
		forninho_ligado.visible = false


func _mostrar(botao: TextureButton, sim: bool) -> void:
	if botao:
		botao.visible = sim
		botao.disabled = not sim
