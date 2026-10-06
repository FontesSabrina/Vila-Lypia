class_name BarraOvos
extends Sprite2D

@onready var ovos: TextureRect = $ovos
@onready var sombra_ovos: TextureRect = $Sombra_ovos
@onready var chave: TextureRect = $chave
@onready var sombra_chave: TextureRect = $Sombra_chave

func _ready() -> void:
	# 1. Primeiro conecta os sinais (com verificação de segurança)
	if is_instance_valid(GameState):
		if GameState.has_signal("ovos_coletados") and not GameState.ovos_coletados.is_connected(atualizar_barra):
			GameState.ovos_coletados.connect(atualizar_barra)
		
		if GameState.has_signal("chave_coletada") and not GameState.chave_coletada.is_connected(atualizar_barra):
			GameState.chave_coletada.connect(atualizar_barra)
	
	# 2. Depois atualiza a barra com o estado inicial
	atualizar_barra()

func atualizar_barra() -> void:
	if not is_instance_valid(GameState):
		return

	if ovos and sombra_ovos:
		ovos.visible = GameState.ovos_pego
		sombra_ovos.visible = not GameState.ovos_pego

	if chave and sombra_chave:
		chave.visible = GameState.chave_pega
		sombra_chave.visible = not GameState.chave_pega
