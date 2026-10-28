extends Control
class_name Creditos
## Tela de créditos — monta tudo sozinha, não precisa criar nós na cena.
## Cena: res://scenes/creditos.tscn (raiz Control com este script).
## O texto sobe devagar. Clique ou tecla pula. No fim volta para o menu.

const CENA_MENU := "res://scenes/menu.tscn"
const DURACAO := 32.0   # segundos para o texto atravessar a tela
const MUSICA := "res://assets/som/Caminho da Vila.mp3"

## Edite aqui os créditos.
##   Linha vazia = espaço.
##   Linha que começa com "#" = título de seção (aparece em dourado).
const LINHAS := [
	"Vila Lypia",
	"",
	"",
	"#Desenvolvimento",
	"Alexandre do Amaral Quintão",
	"Sabrina Caetano Fontes",
	"",
	"#Orientador",
	"Prof. Paulo Vinicius Moreira Dutra",
	"",
	"#Projeto de Extensão",
	"Instituto Federal do Sudeste de Minas Gerais",
	"IF Sudeste MG",
	"",
	"",
	"#Ferramentas",
	"Motor do jogo: Godot Engine",
	"Diálogos: Dialogic",
	"Vozes: Fish Audio",
	"Imagens: Google Flow (Whisk)",
	"Remoção de fundo: Photoroom",
	"",
	"",
	"Obrigada por jogar!",
]

const TITULO_DO_FINAL := {
	1: "Final 1 — O Aniversário Esquecido",
	2: "Final 2 — Um Sorriso Incompleto",
	3: "Final Verdadeiro — O Coração da Vila",
}

var _saindo := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = Color("1b1420")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)

	var coluna := VBoxContainer.new()
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 14)
	add_child(coluna)

	var titulo_final: String = TITULO_DO_FINAL.get(GameState.final_alcancado, "")
	if titulo_final != "":
		coluna.add_child(_label(titulo_final, 30, Color("ffd76e")))
		coluna.add_child(_label("", 20))

	for i in LINHAS.size():
		var linha: String = LINHAS[i]
		if i == 0:
			coluna.add_child(_label(linha, 44))
		elif linha.begins_with("#"):
			coluna.add_child(_label(linha.substr(1), 26, Color("ffd76e")))
		else:
			coluna.add_child(_label(linha, 24))

	if GameState.lapis_magico:
		coluna.add_child(_label("", 20))
		coluna.add_child(_label("Item lendário obtido: Lápis Mágico", 22, Color("ffd76e")))

	_tocar_musica()

	# Espera um quadro para o VBox calcular a altura antes de animar.
	await get_tree().process_frame
	var tela := get_viewport_rect().size
	coluna.size.x = tela.x
	coluna.position = Vector2(0, tela.y)
	var tween := create_tween()
	tween.tween_property(coluna, "position:y", -coluna.size.y, DURACAO)
	tween.tween_callback(_voltar_ao_menu)


func _label(texto: String, tamanho: int, cor := Color.WHITE) -> Label:
	var label := Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	return label


func _tocar_musica() -> void:
	if not ResourceLoader.exists(MUSICA):
		return
	var som := AudioStreamPlayer.new()
	som.stream = load(MUSICA)
	som.volume_db = -14.0
	add_child(som)
	som.play()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
		_voltar_ao_menu()


func _voltar_ao_menu() -> void:
	if _saindo:
		return
	_saindo = true
	get_tree().change_scene_to_file.call_deferred(CENA_MENU)
