extends Node2D
class_name MesaBolo

@onready var sprite_ovos: TextureButton = $Ingredientes/ovos
@onready var sprite_chocolate: TextureButton = $Ingredientes/chocolate
@onready var sprite_fermento: TextureButton = $Ingredientes/fermento
@onready var sprite_farinha: TextureButton = $Ingredientes/farinha
@onready var sprite_acucar: TextureButton = $Ingredientes/acucar
@onready var sprite_geleia: TextureButton = $Ingredientes/geleia

# Caminho para a tigela onde os itens devem ser soltos
@onready var tigela: Sprite2D = $Tigela 

# Nó que mostra o bolo final (Ruim / Simples / Médio / Top) conforme os
# ingredientes usados.
@onready var resultado_bolo: ResultadoBolo = get_node_or_null("ResultadoBolo") as ResultadoBolo

# Som do forno quando o bolo termina de assar (o "plim!").
# Formatos aceitos: .mp3, .ogg ou .wav.
const SOM_FORNO_PRONTO := "res://assets/som/forno pronto.mp3"

# Item que a Bella entrega no final D (Pingente do Coração Unido).
# Coloque a imagem (PNG com fundo transparente) e o som nas pastas abaixo.
# Se algum arquivo não existir, o jogo só dá um aviso no Output e segue.
const IMG_PINGENTE := "res://assets/icon/item_coracao_unido.png"
const SOM_ITEM_RECEBIDO := "res://assets/som/item_recebido.mp3"

# Tamanho da imagem do item na tela (em pixels) e altura onde ela aparece
# (0 = topo da tela, 1 = base). 0.38 deixa ela acima da caixa de texto.
const TAMANHO_ITEM := 300.0
const ALTURA_ITEM := 0.38

# Timeline com os 4 finais do capítulo (A, B, C e D). Ela escolhe sozinha
# qual final a Bella fala, conforme {Bolo.Total_Ingredientes}:
#   0 = A | 1 a 3 = B | 4 a 5 = C | 6 = D (ganha o pingente)
const TIMELINE_FINAL := "bolo_final"

# Cena para onde ir depois que o final terminar: a praça do Capítulo IV.
# Deixe "" para ficar na mesa.
const CENA_APOS_FINAL := "res://scenes/praca_festa_iv.tscn"

var player_forno: AudioStreamPlayer
var player_item: AudioStreamPlayer

# Imagem do item na tela (criada por código em _preparar_item_pingente).
var camada_item: CanvasLayer
var imagem_item: TextureRect
var _tween_item: Tween
var pingente_entregue: bool = false

var item_sendo_arrastado: TextureButton = null
var posicao_original: Vector2 = Vector2.ZERO
var fase_assar_ativa: bool = false

# Fica true enquanto a Bella está falando. Nesse tempo o jogador não
# consegue arrastar nada.
var dialogo_ativo: bool = false

# Guardamos aqui o total de ingredientes calculado em
# verificar_ingredientes_coletados(). Usamos essa cópia local (em vez de
# ler Dialogic.VAR.Bolo.Total_Ingredientes na hora de mostrar o bolo)
# porque, se essa variável não existir no Dialogic, a atualização dela é
# silenciosamente pulada e o valor fica sempre travado — o que fazia o
# resultado final nunca mudar de nível.
var total_ingredientes_colocados: int = 0

func _ready() -> void:
	player_forno = _criar_player(SOM_FORNO_PRONTO)
	player_item = _criar_player(SOM_ITEM_RECEBIDO)
	_preparar_item_pingente()

	# Sinais que a timeline "bolo_final" envia: mostrar_pingente e
	# esconder_pingente. E, ao fim de qualquer timeline, a imagem some.
	if not Dialogic.signal_event.is_connected(_on_dialogic_signal):
		Dialogic.signal_event.connect(_on_dialogic_signal)
	if not Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.connect(_on_timeline_ended)

	verificar_ingredientes_coletados()
	conectar_botoes_arraste()

	if total_ingredientes_colocados == 0:
		# Sem ingredientes não há o que arrastar: pula o minigame e vai
		# direto para o final A.
		_final_sem_ingredientes()
	else:
		# Fala inicial da Bella: explica que é para arrastar para a tigela.
		_falar_bella("bolo_mesa_inicio")

# Cria um player de som a partir de um arquivo. Se o arquivo não existir,
# só avisa no Output e o jogo segue normalmente, sem esse som.
func _criar_player(caminho: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	if ResourceLoader.exists(caminho):
		player.stream = load(caminho)
		# Se o som estiver muito alto ou baixo, ajuste aqui (0 = normal,
		# valores negativos deixam mais baixo).
		player.volume_db = 0.0
	else:
		push_warning("Som não encontrado: " + caminho)
	return player

func _tocar(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.play()

# Toca uma timeline da Bella e bloqueia o arraste até ela terminar.
func _falar_bella(nome_timeline: String) -> void:
	# Espera 1 frame: iniciar o Dialogic dentro do _ready(), com a cena
	# ainda sendo montada, pode dar erro.
	await get_tree().process_frame
	if not is_inside_tree():
		return

	# A timeline anterior (a da praça) pode ainda estar fechando quando a
	# mesa abre. Espera até ~0,5 s e, se continuar ativa, encerra à força.
	var tentativas := 0
	while Dialogic.current_timeline and tentativas < 30:
		await get_tree().process_frame
		tentativas += 1
	if Dialogic.current_timeline:
		print(">>> Timeline anterior ainda ativa, encerrando à força")
		Dialogic.end_timeline()
		await get_tree().process_frame

	dialogo_ativo = true
	var camada = Dialogic.start(nome_timeline)

	# O Dialogic pode levar alguns frames para registrar a timeline. Espera
	# até ~0,5 s antes de concluir que ela não iniciou.
	var espera := 0
	while not Dialogic.current_timeline and espera < 30:
		await get_tree().process_frame
		espera += 1

	# Se a timeline não existir ou não tiver iniciado, não trava o jogo.
	if not Dialogic.current_timeline:
		print(">>> Não iniciou: ", nome_timeline, " | Dialogic.start devolveu: ", camada)
		dialogo_ativo = false
		return

	await Dialogic.timeline_ended
	# Pequena pausa para o clique que fechou a fala não pegar um item.
	await get_tree().create_timer(0.3).timeout
	dialogo_ativo = false

# ---------------------------------------------------------------------
# ITEM RECEBIDO (imagem do pingente + som)
# ---------------------------------------------------------------------

# Cria, por código, uma camada com a imagem do item (começa escondida).
func _preparar_item_pingente() -> void:
	camada_item = CanvasLayer.new()
	camada_item.layer = 5
	add_child(camada_item)

	imagem_item = TextureRect.new()
	imagem_item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagem_item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagem_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	imagem_item.size = Vector2(TAMANHO_ITEM, TAMANHO_ITEM)
	# Centro da imagem = ponto em torno do qual ela cresce na animação.
	imagem_item.pivot_offset = imagem_item.size / 2.0
	var tela := get_viewport_rect().size
	imagem_item.position = Vector2(
		tela.x / 2.0 - TAMANHO_ITEM / 2.0,
		tela.y * ALTURA_ITEM - TAMANHO_ITEM / 2.0
	)
	imagem_item.visible = false
	camada_item.add_child(imagem_item)

	if ResourceLoader.exists(IMG_PINGENTE):
		imagem_item.texture = load(IMG_PINGENTE)
	else:
		push_warning("Imagem do pingente não encontrada: " + IMG_PINGENTE)

# Toca o som e faz a imagem "pular" para a tela (cresce um pouco além do
# tamanho e assenta), como quando o jogador recebe um item.
func _mostrar_item_pingente() -> void:
	_tocar(player_item)
	if imagem_item == null or imagem_item.texture == null:
		return
	if _tween_item:
		_tween_item.kill()
	imagem_item.visible = true
	imagem_item.modulate.a = 0.0
	imagem_item.scale = Vector2(0.2, 0.2)
	_tween_item = create_tween().set_parallel(true)
	_tween_item.tween_property(imagem_item, "modulate:a", 1.0, 0.25)
	_tween_item.tween_property(imagem_item, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# A imagem some com um pequeno fade.
func _esconder_item_pingente() -> void:
	if imagem_item == null or not imagem_item.visible:
		return
	if _tween_item:
		_tween_item.kill()
	_tween_item = create_tween()
	_tween_item.tween_property(imagem_item, "modulate:a", 0.0, 0.25)
	_tween_item.tween_callback(func(): imagem_item.visible = false)

# Recebe os sinais da timeline "bolo_final".
func _on_dialogic_signal(argumento) -> void:
	match str(argumento):
		"mostrar_pingente":
			_dar_pingente()
			_mostrar_item_pingente()
		"esconder_pingente":
			_esconder_item_pingente()

# Garante que a imagem não fique na tela quando a conversa acabar.
func _on_timeline_ended() -> void:
	_esconder_item_pingente()

# ---------------------------------------------------------------------
# FINAIS DO CAPÍTULO
# ---------------------------------------------------------------------

# Nenhum ingrediente: sem minigame. Mostra o bolo ruim e vai ao final A.
func _final_sem_ingredientes() -> void:
	fase_assar_ativa = true   # garante que nada seja arrastado
	if tigela:
		tigela.visible = false
	await get_tree().create_timer(0.5).timeout
	_tocar(player_forno)
	if resultado_bolo:
		resultado_bolo.mostrar_bolo(0)
	await _mostrar_final()

# A Bella fala o final (a timeline escolhe A, B, C ou D pelo total de
# ingredientes); no final D o jogador ganha o pingente.
func _mostrar_final() -> void:
	var total := total_ingredientes_colocados

	# Guarda qual bolo saiu, para a praça do Capítulo IV mostrar o mesmo
	# bolo em cima da mesa.
	GameState.bolo_ingredientes = total

	# Garante que o Dialogic tenha o total certo, porque a timeline
	# "bolo_final" escolhe o final por essa variável.
	if "Bolo" in Dialogic.VAR and "Total_Ingredientes" in Dialogic.VAR.Bolo:
		Dialogic.VAR.Bolo.Total_Ingredientes = total

	print(">>> Final: ", TIMELINE_FINAL, " | ingredientes: ", total, " | bolo ", GameState.letra_do_bolo())
	await _falar_bella(TIMELINE_FINAL)

	# O pingente normalmente já foi dado pelo sinal "mostrar_pingente".
	# Aqui é só uma garantia caso a timeline não tenha o sinal.
	if total >= 6:
		_dar_pingente()

	# Vai direto para a praça do Capítulo IV.
	if CENA_APOS_FINAL != "":
		if ResourceLoader.exists(CENA_APOS_FINAL):
			get_tree().call_deferred("change_scene_to_file", CENA_APOS_FINAL)
		else:
			push_error("MesaBolo: cena não encontrada: " + CENA_APOS_FINAL)

# Bônus do final perfeito: Pingente do Coração Unido. Só é dado uma vez.
func _dar_pingente() -> void:
	if pingente_entregue:
		return
	pingente_entregue = true
	if GameState and GameState.has_method("pegar_pingente"):
		GameState.pegar_pingente()
	else:
		push_warning("MesaBolo: GameState.pegar_pingente() não existe. Atualize o GameState.gd.")
	# Marca também no Dialogic, se você criar a variável
	# Bolo > Pingente_Coracao_Unido (tipo bool). Se não existir, ignora.
	if _ler_variavel("Bolo.Pingente_Coracao_Unido") != null:
		Dialogic.VAR.set_variable("Bolo.Pingente_Coracao_Unido", true)

# ---------------------------------------------------------------------
# INGREDIENTES
# ---------------------------------------------------------------------

# Lê uma variável do Dialogic pelo caminho (ex: "Bolo.Enzo.Ovos_Entregue").
# Devolve null se o caminho não existir.
func _ler_variavel(caminho: String):
	var atual = Dialogic.current_state_info.get("variables", {})
	for parte in caminho.split("."):
		if atual is Dictionary and atual.has(parte):
			atual = atual[parte]
		else:
			return null
	return atual

# Testa vários nomes possíveis para o mesmo ingrediente. Usa o primeiro que
# existir. Se nenhum existir, avisa no Output quais variáveis a pasta tem.
func _tem_ingrediente(nome: String, candidatos: Array) -> bool:
	for caminho in candidatos:
		var valor = _ler_variavel(caminho)
		if valor != null:
			return bool(valor)

	var pasta: String = String(candidatos[0]).rsplit(".", true, 1)[0]
	var conteudo = _ler_variavel(pasta)
	var nomes_na_pasta = conteudo.keys() if conteudo is Dictionary else "(pasta não encontrada)"
	print("AVISO: variável do ingrediente '", nome, "' não encontrada. Testei: ", candidatos, " | Variáveis em '", pasta, "': ", nomes_na_pasta)
	return false

func verificar_ingredientes_coletados() -> void:
	var tem_ovos = _tem_ingrediente("ovos", [
		"Bolo.Enzo.Ovos_Entregue",
	])
	var tem_chocolate = _tem_ingrediente("chocolate", [
		"Bolo.Pietro.Bolo_Pietro_Chocolate_Entregue",
	])
	var tem_farinha = _tem_ingrediente("farinha", [
		"Bolo.Hera.Farinha_Concluido",
	])
	var tem_acucar = _tem_ingrediente("açúcar", [
		"Bolo.Linna.Bolo_Linna_Acucar_Entregue",
	])
	var tem_geleia = _tem_ingrediente("geleia", [
		"Bolo.Vincent.Bolo_Vincent_Geleia_Entregue",
	])
	var tem_fermento = _tem_ingrediente("fermento", [
		"Bolo.Xerife.Ingrediente_Pepper",
	])

	if sprite_ovos: sprite_ovos.visible = tem_ovos
	if sprite_chocolate: sprite_chocolate.visible = tem_chocolate
	if sprite_farinha: sprite_farinha.visible = tem_farinha
	if sprite_acucar: sprite_acucar.visible = tem_acucar
	if sprite_geleia: sprite_geleia.visible = tem_geleia
	if sprite_fermento: sprite_fermento.visible = tem_fermento

	var total = 0
	if tem_ovos: total += 1
	if tem_chocolate: total += 1
	if tem_farinha: total += 1
	if tem_acucar: total += 1
	if tem_geleia: total += 1
	if tem_fermento: total += 1

	if "Bolo" in Dialogic.VAR and "Total_Ingredientes" in Dialogic.VAR.Bolo:
		Dialogic.VAR.Bolo.Total_Ingredientes = total

	total_ingredientes_colocados = total
		
	print("Tudo certo! Total na mesa: ", total, " | Fermento: ", tem_fermento)

# ---------------------------------------------------------------------
# MINIGAME (arrastar) — sem alterações
# ---------------------------------------------------------------------

func conectar_botoes_arraste() -> void:
	for ingrediente in $Ingredientes.get_children():
		if ingrediente is TextureButton:
			ingrediente.button_down.connect(_on_item_button_down.bind(ingrediente))

	# A forma com massa também precisa ser arrastável. Ela é filha do
	# forno_controller (não do Ingredientes), então não entra no loop
	# acima — por isso conectamos o mesmo sinal a ela aqui. Como ela
	# começa "disabled = true" (ver FornoController._ready), clicar nela
	# não faz nada até a fase de assar ser liberada.
	var controlador = $forno_controller
	if controlador and controlador.forma_massa:
		controlador.forma_massa.button_down.connect(_on_item_button_down.bind(controlador.forma_massa))

func _on_item_button_down(item: TextureButton) -> void:
	if dialogo_ativo:
		return
	if item.visible:
		item_sendo_arrastado = item
		posicao_original = item.global_position

func _input(event: InputEvent) -> void:
	if dialogo_ativo:
		return

	if item_sendo_arrastado and event is InputEventMouseMotion:
		item_sendo_arrastado.global_position = event.position

	if item_sendo_arrastado and event is InputEventMouseButton and not event.pressed:
		if not fase_assar_ativa:
			if tigela:
				var distancia = item_sendo_arrastado.global_position.distance_to(tigela.global_position)
				
				if distancia < 120.0:
					print("Ingrediente colocado na tigela com sucesso: ", item_sendo_arrastado.name)
					# IMPORTANTE: esconder antes do queue_free().
					# queue_free() só remove o nó no final do frame, então se
					# verificar_conclusao_receita() rodar antes disso, esse
					# ingrediente ainda apareceria como "visible" e contaria
					# como restante — impedindo o último ingrediente de
					# fechar a receita.
					item_sendo_arrastado.visible = false
					item_sendo_arrastado.queue_free()
					verificar_conclusao_receita()
				else:
					item_sendo_arrastado.global_position = posicao_original
			else:
				item_sendo_arrastado.global_position = posicao_original
		else:
			# Fase de assar ativa: verifica se a forma foi solta no forno
			var controlador = $forno_controller
			if controlador and controlador.forma_massa and item_sendo_arrastado == controlador.forma_massa:
				if controlador.forninho:
					# Em vez de comparar distância entre pontos (frágil quando
					# os dois elementos têm tamanhos bem diferentes, como o
					# forno grande e a forma pequena), verificamos se os
					# retângulos das duas texturas realmente se sobrepõem na
					# tela. O grow() dá uma margem de folga, então não precisa
					# encaixar pixel-perfeito.
					var rect_forma = controlador.forma_massa.get_global_rect()
					var rect_forno = controlador.forninho.get_global_rect().grow(40.0)
					
					if rect_forno.intersects(rect_forma):
						print("Forma colocada no forno com sucesso!")
						controlador.assar_bolo()
						# Limpamos aqui, antes do "await" abaixo: a forma já
						# foi destruída dentro de assar_bolo(), então não faz
						# sentido (e pode até dar erro) continuar segurando a
						# referência a ela enquanto esperamos.
						item_sendo_arrastado = null
						# Deixa o forno ligado visível por um tempinho antes
						# de revelar o resultado. Troque o "3.0" (segundos)
						# se quiser esse tempo maior ou menor.
						await get_tree().create_timer(3.0).timeout
						# Bolo assado: toca o "plim!" do forno.
						_tocar(player_forno)
						if resultado_bolo:
							resultado_bolo.mostrar_bolo(total_ingredientes_colocados)
						controlador.esconder_forno()
						# A Bella fala o final certo (A, B, C ou D).
						_mostrar_final()
						return
					else:
						controlador.forma_massa.global_position = posicao_original
				else:
					item_sendo_arrastado.global_position = posicao_original
			else:
				if item_sendo_arrastado:
					item_sendo_arrastado.global_position = posicao_original
			
		item_sendo_arrastado = null

func verificar_conclusao_receita() -> void:
	var ingredientes_restantes = 0
	for ingrediente in $Ingredientes.get_children():
		if ingrediente is TextureButton and ingrediente.visible:
			ingredientes_restantes += 1
			
	if ingredientes_restantes == 0:
		print("Todos os ingredientes misturados!")
		if tigela: 
			tigela.visible = false 
			
		var controlador = $forno_controller
		if controlador and controlador.has_method("ativar_fase_assar"):
			controlador.ativar_fase_assar()
		
		fase_assar_ativa = true

		# Fala da Bella: agora é a hora de assar.
		_falar_bella("bolo_mesa_assar")
