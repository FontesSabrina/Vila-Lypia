class_name BarraFitas
extends Sprite2D

@onready var fita: TextureRect = $fitas
@onready var sombra_fita: TextureRect = $Sombra_fitas

func _ready() -> void:
	if is_instance_valid(GameState) and GameState.has_signal("fita_coletada"):
		if not GameState.fita_coletada.is_connected(atualizar_barra):
			GameState.fita_coletada.connect(atualizar_barra)
	
	atualizar_barra()

func atualizar_barra() -> void:
	if not is_instance_valid(GameState):
		return

	if fita and sombra_fita:
		fita.visible = GameState.fita_pega
		sombra_fita.visible = not GameState.fita_pega
