extends Control
class_name MenuPrincipal
## Menu principal — Vila Lypia
## Só decide o que aparece:
##   - sem save -> PainelPrimeiraVez (Iniciar / Pular Tutorial)
##                 + Configurações e Sair do PainelComSave
##   - com save -> PainelComSave completo (Continuar / Novo Jogo / Configurações / Sair)
## As ações dos botões ficam em cada painel (painel_primeira_vez.gd e
## painel_com_save.gd). O save fica no autoload Salvamento (salvamento.gd).

@onready var painel_primeira_vez: Control = get_node_or_null("PainelPrimeiraVez") as Control
@onready var painel_com_save: Control = get_node_or_null("PainelComSave") as Control
@onready var painel_config: Control = get_node_or_null("PainelConfig") as Control


func _ready() -> void:
	# O fundo do menu não pode "comer" o clique dos botões.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tem_save := Salvamento.tem_save()
	print(">>> Menu: pronto | tem save = ", tem_save)

	# Mostra só o painel certo (o escondido não recebe clique).
	if painel_primeira_vez:
		painel_primeira_vez.visible = not tem_save
	else:
		push_error("menu: nó 'PainelPrimeiraVez' não encontrado.")

	if painel_com_save:
		# Configurações e Sair aparecem sempre, com ou sem save
		painel_com_save.visible = true
		if painel_com_save.has_method("mostrar_so_config_e_sair"):
			painel_com_save.call("mostrar_so_config_e_sair", not tem_save)
	else:
		push_error("menu: nó 'PainelComSave' não encontrado.")

	if painel_config:
		painel_config.visible = false
