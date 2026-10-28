extends Node
## Acessibilidade — Vila Lypia  (AUTOLOAD, sem class_name)
##
## Guarda e aplica, no jogo inteiro, as configurações pensadas para crianças
## com sensibilidade sensorial (autismo, TDAH etc.):
##
##   SOM      volume separado de Música, Vozes e Efeitos
##            "Sons suaves": segura sons altos de repente (compressor)
##   TELA     Brilho (escurece a tela)
##            Cores suaves (tira um pouco da cor forte)
##            Sem clarões (desliga os flashes brancos)
##   TEXTO    Velocidade (Devagar / Normal / Rápida / Tudo de uma vez)
##            Tamanho das letras (Normal / Grande / Muito grande)
##            Avançar sozinho (desligado = a criança passa no seu tempo)
##   CLIQUES  Proteção contra cliques repetidos (sempre ligada):
##            - logo depois que uma conversa termina, os cliques ficam
##              parados por um instante, para o clique extra de quem passa
##              o texto rápido não abrir uma casa/praça que está embaixo;
##            - durante a conversa, Espaço/Enter só passam o texto e não
##              apertam mais o botão do cenário que estava selecionado.
##
## Cadastro: Projeto > Configurações do Projeto > Globais > Autoload
##   Caminho: res://scripts/Acessibilidade.gd   Nome: Acessibilidade
##   (coloque ABAIXO do Dialogic na lista)
##
## Outros scripts podem perguntar, por exemplo:
##   if Acessibilidade.sem_claroes: return

signal mudou

const ARQUIVO := "user://acessibilidade.cfg"

const BUS_MUSICA := "Musica"
const BUS_VOZES := "Vozes"
const BUS_EFEITOS := "Efeitos"

## Som com mais de X segundos é tratado como música; menos é efeito.
const DURACAO_MUSICA := 20.0

## Velocidade do texto (no Dialogic: número menor = mais rápido; 0 = tudo de uma vez)
const VELOCIDADES := [
	{"nome": "Devagar", "valor": 1.8},
	{"nome": "Normal", "valor": 1.0},
	{"nome": "Rápida", "valor": 0.5},
	{"nome": "Tudo de\numa vez", "valor": 0.0},
]

const TAMANHOS := [
	{"nome": "Normal", "valor": 1.0},
	{"nome": "Grande", "valor": 1.25},
	{"nome": "Muito\ngrande", "valor": 1.5},
]

const PADRAO := {
	"vol_musica": 0.7,
	"vol_vozes": 0.9,
	"vol_efeitos": 0.6,
	"sons_suaves": true,
	"brilho": 1.0,
	"cores_suaves": false,
	"sem_claroes": false,
	"velocidade": 1,
	"tamanho": 0,
	"avancar_sozinho": false,
	"tela_cheia": false,
}

# Valores atuais (os outros scripts podem ler)
var vol_musica: float
var vol_vozes: float
var vol_efeitos: float
var sons_suaves: bool
var brilho: float            # 0.5 (mais escuro) a 1.0 (normal)
var cores_suaves: bool
var sem_claroes: bool
var velocidade: int
var tamanho: int
var avancar_sozinho: bool
var tela_cheia: bool

var _camada: CanvasLayer
var _filtro: ColorRect

## Tempo (segundos) em que os cliques ficam parados depois de uma conversa.
const PAUSA_APOS_CONVERSA := 0.45
var _cliques_parados_ate := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_canais_de_som()
	_criar_filtro_de_tela()
	carregar()
	aplicar()
	# Toda vez que um som ou um balão de texto aparece no jogo, ajusta ele.
	get_tree().node_added.connect(_on_node_added)
	# Espera o Dialogic ficar pronto para ligar a proteção de cliques.
	_ligar_protecao_de_cliques.call_deferred()


# ---------------------------------------------------------------- SALVAR / CARREGAR

func carregar() -> void:
	for chave in PADRAO:
		set(chave, PADRAO[chave])
	var cfg := ConfigFile.new()
	if cfg.load(ARQUIVO) != OK:
		return
	for chave in PADRAO:
		set(chave, cfg.get_value("config", chave, PADRAO[chave]))
	velocidade = clampi(velocidade, 0, VELOCIDADES.size() - 1)
	tamanho = clampi(tamanho, 0, TAMANHOS.size() - 1)
	brilho = clampf(brilho, 0.5, 1.0)


func salvar() -> void:
	var cfg := ConfigFile.new()
	for chave in PADRAO:
		cfg.set_value("config", chave, get(chave))
	cfg.save(ARQUIVO)


func restaurar_padrao() -> void:
	for chave in PADRAO:
		set(chave, PADRAO[chave])
	aplicar()
	salvar()


## Muda um valor, aplica na hora e salva. Ex: Acessibilidade.mudar("brilho", 0.8)
func mudar(chave: String, valor) -> void:
	set(chave, valor)
	aplicar()
	salvar()


# ---------------------------------------------------------------- APLICAR

func aplicar() -> void:
	_aplicar_som()
	_aplicar_tela()
	_aplicar_texto()
	mudou.emit()


func _aplicar_som() -> void:
	_volume(BUS_MUSICA, vol_musica)
	_volume(BUS_VOZES, vol_vozes)
	_volume(BUS_EFEITOS, vol_efeitos)
	var master := AudioServer.get_bus_index("Master")
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, i) is AudioEffectCompressor:
			AudioServer.set_bus_effect_enabled(master, i, sons_suaves)


func _volume(bus: String, valor: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	AudioServer.set_bus_mute(i, valor <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(valor, 0.001)))


func _aplicar_tela() -> void:
	if _filtro:
		var mat := _filtro.material as ShaderMaterial
		mat.set_shader_parameter("brilho", brilho)
		mat.set_shader_parameter("saturacao", 0.55 if cores_suaves else 1.0)
		_filtro.visible = brilho < 0.999 or cores_suaves

	if tela_cheia:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _aplicar_texto() -> void:
	var dialogic := get_node_or_null("/root/Dialogic")
	if dialogic == null:
		return
	if dialogic.get("Settings") != null:
		dialogic.Settings.set("text_speed", float(VELOCIDADES[velocidade]["valor"]))
	var inputs = dialogic.get("Inputs")
	if inputs != null and inputs.get("auto_advance") != null:
		inputs.auto_advance.enabled_forced = avancar_sozinho
	for no in get_tree().get_nodes_in_group("dialogic_dialog_text"):
		_ajustar_tamanho(no)


# ---------------------------------------------------------------- SOM: CANAIS

func _criar_canais_de_som() -> void:
	for nome in [BUS_MUSICA, BUS_VOZES, BUS_EFEITOS]:
		if AudioServer.get_bus_index(nome) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nome)
			AudioServer.set_bus_send(i, "Master")

	# "Sons suaves": um compressor no Master segura picos de som alto.
	var master := AudioServer.get_bus_index("Master")
	var tem := false
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, i) is AudioEffectCompressor:
			tem = true
	if not tem:
		var comp := AudioEffectCompressor.new()
		comp.threshold = -16.0
		comp.ratio = 6.0
		comp.attack_us = 20.0
		comp.release_ms = 250.0
		comp.gain = 2.0
		AudioServer.add_bus_effect(master, comp)


func _on_node_added(no: Node) -> void:
	if no is AudioStreamPlayer:
		_escolher_canal.call_deferred(no)
	elif no is RichTextLabel and no.has_method("set_speed"):
		# É o texto do balão do Dialogic: espera o estilo carregar e ajusta
		_ajustar_tamanho_depois(no)


## Manda cada som para o canal certo (Vozes, Música ou Efeitos).
func _escolher_canal(p) -> void:
	# (sem tipo no parâmetro: o som pode ter sido apagado antes desta chamada)
	if not is_instance_valid(p) or not (p is AudioStreamPlayer) or p.bus != "Master":
		return   # se alguém já escolheu um canal, respeita
	var dialogic := get_node_or_null("/root/Dialogic")
	if dialogic and dialogic.get("Voice") != null and dialogic.Voice.get("voice_player") == p:
		p.bus = BUS_VOZES
		return
	var duracao := 0.0
	if p.stream:
		duracao = p.stream.get_length()
	p.bus = BUS_MUSICA if duracao >= DURACAO_MUSICA else BUS_EFEITOS
	if not p.finished.is_connected(_rechecar.bind(p)):
		# O stream pode ser trocado depois (ex.: voz e áudio do Dialogic)
		p.finished.connect(_rechecar.bind(p))


func _rechecar(p) -> void:
	if is_instance_valid(p) and p is AudioStreamPlayer and p.bus != BUS_VOZES:
		p.bus = "Master"
		_escolher_canal(p)


# ---------------------------------------------------------------- TEXTO: TAMANHO

func _ajustar_tamanho_depois(no) -> void:
	# Espera o estilo do Dialogic carregar. Se a cena trocar nesse meio tempo,
	# o balão some; por isso conferimos se ele ainda existe antes de ajustar.
	await get_tree().process_frame
	if not is_instance_valid(no):
		return
	await get_tree().process_frame
	if not is_instance_valid(no):
		return
	_ajustar_tamanho(no)


func _ajustar_tamanho(no) -> void:
	if not is_instance_valid(no) or not (no is Control):
		return
	var c := no as Control
	var nomes := ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]
	if not c.has_meta("tamanho_base"):
		var base := {}
		for n in nomes:
			base[n] = c.get_theme_font_size(n)
		c.set_meta("tamanho_base", base)
	var base_salvo: Dictionary = c.get_meta("tamanho_base")
	var fator: float = TAMANHOS[tamanho]["valor"]
	for n in nomes:
		c.add_theme_font_size_override(n, int(round(base_salvo[n] * fator)))


# ---------------------------------------------------------------- CLIQUES

func _ligar_protecao_de_cliques() -> void:
	var dialogic := get_node_or_null("/root/Dialogic")
	if dialogic == null:
		return
	dialogic.timeline_started.connect(_on_conversa_comecou)
	dialogic.timeline_ended.connect(_on_conversa_terminou)
	get_viewport().gui_focus_changed.connect(_on_foco_mudou)


func _on_conversa_comecou() -> void:
	# Tira a seleção do botão clicado (ex.: a casa no mapa). Senão o Espaço ou
	# o Enter, que passam o texto, também apertam esse botão.
	get_viewport().gui_release_focus()


func _on_conversa_terminou() -> void:
	_cliques_parados_ate = Time.get_ticks_msec() + int(PAUSA_APOS_CONVERSA * 1000.0)
	get_viewport().gui_release_focus()


func _on_foco_mudou(no: Control) -> void:
	if no == null or not _em_conversa():
		return
	# Durante a conversa, só os botões do próprio Dialogic (escolhas) podem
	# ficar selecionados.
	var layout = _layout_dialogic()
	if layout != null and layout.is_ancestor_of(no):
		return
	no.release_focus.call_deferred()


func _layout_dialogic() -> Node:
	var dialogic := get_node_or_null("/root/Dialogic")
	if dialogic == null or dialogic.get("Styles") == null:
		return null
	return dialogic.Styles.get_layout_node()


func _em_conversa() -> bool:
	var dialogic := get_node_or_null("/root/Dialogic")
	return dialogic != null and dialogic.current_timeline != null


## Conversa pedida mas o balão ainda não apareceu (dura 1 quadro).
func _conversa_comecando() -> bool:
	var layout = _layout_dialogic()
	return layout != null and not layout.is_inside_tree()


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton or event is InputEventScreenTouch):
		return
	# Durante a conversa quem cuida dos cliques é o Dialogic.
	if _em_conversa() and not _conversa_comecando():
		return
	if Time.get_ticks_msec() < _cliques_parados_ate or _conversa_comecando():
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- TELA: FILTRO

func _criar_filtro_de_tela() -> void:
	_camada = CanvasLayer.new()
	_camada.layer = 127       # por cima de tudo (menos o clarão do final)
	add_child(_camada)

	_filtro = ColorRect.new()
	_filtro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_filtro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D tela : hint_screen_texture, filter_linear_mipmap;
uniform float brilho = 1.0;
uniform float saturacao = 1.0;
void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;
	float cinza = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(cinza), c, saturacao) * brilho;
	COLOR = vec4(c, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_filtro.material = mat
	_filtro.visible = false
	_camada.add_child(_filtro)
