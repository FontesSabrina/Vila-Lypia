extends Sprite2D
class_name Chocolate

@onready var chocolate: TextureRect = $chocolate
@onready var sombra_chocolate: TextureRect = $Sombra_chocolate

func _ready() -> void:
	# Conecta o sinal se existir no GameState (evita erros se a cena recarregar)
	if is_instance_valid(GameState) and GameState.has_signal("chocolate_coletado"):
		if not GameState.chocolate_coletado.is_connected(atualizar_barra):
			GameState.chocolate_coletado.connect(atualizar_barra)
	
	atualizar_barra()

func atualizar_barra() -> void:
	if not is_instance_valid(GameState):
		return

	if chocolate and sombra_chocolate:
		chocolate.visible = GameState.chocolate_pego
		sombra_chocolate.visible = not GameState.chocolate_pego
