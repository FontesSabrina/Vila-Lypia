extends Sprite2D
class_name BarraAcucar

@onready var acucar: TextureRect = $acucar
@onready var sombra_acucar: TextureRect = $Sombra_acucar

func _ready() -> void:
	# 1. Primeiro conecta o sinal (com verificação de segurança)
	if is_instance_valid(GameState) and GameState.has_signal("acucar_coletado"):
		if not GameState.acucar_coletado.is_connected(atualizar_barra):
			GameState.acucar_coletado.connect(atualizar_barra)
	
	# 2. Depois atualiza a barra com o estado inicial
	atualizar_barra()

func atualizar_barra() -> void:
	if not is_instance_valid(GameState):
		return

	if acucar and sombra_acucar:
		acucar.visible = GameState.acucar_pego
		sombra_acucar.visible = not GameState.acucar_pego
