extends Node2D
class_name ResultadoBolo
## Mostra o bolo certo de acordo com quantos ingredientes foram usados.
##   0      -> Bolo Ruim    (Final A)
##   1 a 3  -> Bolo Simples (Final B)
##   4 a 5  -> Bolo Médio   (Final C)
##   6      -> Bolo Top     (Final D)

@onready var bolo_ruim: Sprite2D = get_node_or_null("BoloRuim")
@onready var bolo_simples: Sprite2D = get_node_or_null("BoloSimples")
@onready var bolo_medio: Sprite2D = get_node_or_null("BoloMedio")
@onready var bolo_top: Sprite2D = get_node_or_null("BoloTop")


func _ready() -> void:
	esconder_todos()


func esconder_todos() -> void:
	for bolo in [bolo_ruim, bolo_simples, bolo_medio, bolo_top]:
		if bolo:
			bolo.visible = false


func mostrar_bolo(total_ingredientes: int) -> void:
	esconder_todos()

	var bolo: Sprite2D
	var nome: String
	if total_ingredientes <= 0:
		# Se o nó BoloRuim não existir, usa o Simples no lugar.
		bolo = bolo_ruim if bolo_ruim else bolo_simples
		nome = "Bolo Ruim (Final A)"
	elif total_ingredientes <= 3:
		bolo = bolo_simples
		nome = "Bolo Simples (Nível Bom)"
	elif total_ingredientes <= 5:
		bolo = bolo_medio
		nome = "Bolo Médio (Nível Intermediário)"
	else:
		bolo = bolo_top
		nome = "Bolo Muito Top (Nível Excelente/Master)"

	if bolo:
		bolo.visible = true
	print("Resultado: ", nome, " - ", total_ingredientes, " ingredientes")
