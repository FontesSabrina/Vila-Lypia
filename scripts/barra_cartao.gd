extends Node2D
class_name BarraCartao

# Ícones da bandeja. Cada um começa apagado (acinzentado) e "ganha cor"
# quando a peça correspondente é encaixada corretamente no cartão.
# Os ícones ficam DENTRO do nó "Barra2", por isso a busca é feita em todos os
# filhos (antes procurava só direto na raiz e não achava nenhum).
@onready var _icones: Dictionary = {
	"sol": _achar("SolRadiante"),
	"poema": _achar("PoemaEmGota"),
	"escudo": _achar("EscudoTorto"),
	"selo": _achar("SeloDeCeraVermelho"),
	"dente_leao": _achar("Dente-de-leão"),
	"moldura": _achar("Cartao"),
}

func _achar(nome: String) -> CanvasItem:
	var no := find_child(nome, true, false)
	return no as CanvasItem

const COR_APAGADA := Color(0.5, 0.5, 0.5, 1.0)
const COR_COMPLETA := Color(1, 1, 1, 1)

func _ready() -> void:
	for nome in _icones:
		var icone: CanvasItem = _icones[nome]
		if icone:
			icone.modulate = COR_APAGADA
		else:
			push_warning("barra_cartao: nó '" + nome + "' não encontrado.")

# Chamado pelo minigame quando o jogador acerta uma peça. O ícone dela na
# bandeja ganha cor, com um pequeno "pulinho" de destaque.
func colorir_peca(nome_peca: String) -> void:
	if not _icones.has(nome_peca):
		push_warning("barra_cartao: peça desconhecida '" + nome_peca + "'.")
		return
	var icone: CanvasItem = _icones[nome_peca]
	if icone == null:
		return

	var escala_original: Vector2 = icone.scale
	var tween := create_tween()
	tween.tween_property(icone, "modulate", COR_COMPLETA, 0.4)
	tween.parallel().tween_property(icone, "scale", escala_original * 1.25, 0.15)
	tween.tween_property(icone, "scale", escala_original, 0.15)

# true quando as 6 peças já estão coloridas na bandeja.
func todas_coloridas() -> bool:
	for nome in _icones:
		var icone: CanvasItem = _icones[nome]
		if icone and icone.modulate != COR_COMPLETA:
			return false
	return true
