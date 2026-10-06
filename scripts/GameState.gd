extends Node
class_name GameStateGlobal

# === SINAIS ===
signal mapa_coletado
signal distintivo_coletado
signal chocolate_coletado
signal pincel_coletado
signal acucar_coletado
signal novelo_coletado
signal ovos_coletados
signal chave_coletada
signal vela_coletada
signal farinha_coletada
signal fita_coletada
signal geleia_coletada
signal pingente_coletado
signal moedas_alteradas(nova_quantidade: int)
signal presente_comprado_sinal(presente: String)

# === VARIÁVEIS DE ESTADO ===
var moedas: int = 0

var mapa_pego: bool = false

var distintivo1_pego: bool = false
var distintivo2_pego: bool = false
var distintivo3_pego: bool = false

var chocolate_pego: bool = false

var pincel1_pego: bool = false
var pincel2_pego: bool = false
var pincel3_pego: bool = false

var acucar_pego: bool = false
var novelo1_pego: bool = false
var novelo2_pego: bool = false
var novelo3_pego: bool = false
var novelo4_pego: bool = false

var ovos_pego: bool = false
var chave_pega: bool = false

var vela1_pego: bool = false
var vela2_pego: bool = false
var vela3_pego: bool = false

var farinha_pego: bool = false

var fita_pega: bool = false

var geleia_pega: bool = false

# Bônus do final perfeito do bolo (Pingente do Coração Unido)
var pingente_pego: bool = false

# Resultado do bolo do Capítulo III: quantos ingredientes foram usados (0 a 6).
# -1 = o bolo ainda não foi feito. A praça do Capítulo IV usa isso para
# mostrar o bolo certo em cima da mesa.
var bolo_ingredientes: int = -1

# Presente da Prefeita comprado na loja da Linna (Capítulo IV).
# "" = ainda não comprou | "caixinha" | "veludo" | "caderno" | "kit"
var presente_comprado: String = ""

# Selo final "Coração da Vila" (só no evento de amizade máxima).
var selo_coracao_vila: bool = false

# --- Métodos de Alteração de Dados ---

func pegar_mapa() -> void:
	mapa_pego = true
	mapa_coletado.emit()

func adicionar_moedas(qtd: int = 1) -> void:
	moedas += qtd
	moedas_alteradas.emit(moedas)

func pegar_acucar() -> void:
	acucar_pego = true
	acucar_coletado.emit()

func pegar_novelo(id: int) -> void:
	match id:
		1: novelo1_pego = true
		2: novelo2_pego = true
		3: novelo3_pego = true
		4: novelo4_pego = true
	novelo_coletado.emit()

func todas_velas_coletadas() -> bool:
	return vela1_pego and vela2_pego and vela3_pego

func todos_novelos_coletados() -> bool:
	return novelo1_pego and novelo2_pego and novelo3_pego and novelo4_pego

func todos_pinceis_coletados() -> bool:
	return pincel1_pego and pincel2_pego and pincel3_pego

func todos_distintivos_coletados() -> bool:
	return distintivo1_pego and distintivo2_pego and distintivo3_pego

func pegar_ovos() -> void:
	ovos_pego = true
	ovos_coletados.emit()

func pegar_chave() -> void:
	chave_pega = true
	chave_coletada.emit()

func pegar_vela(id: int) -> void:
	match id:
		1: vela1_pego = true
		2: vela2_pego = true
		3: vela3_pego = true
	vela_coletada.emit()

func pegar_farinha() -> void:
	farinha_pego = true
	farinha_coletada.emit()

func pegar_fita() -> void:
	fita_pega = true
	fita_coletada.emit()

func pegar_geleia() -> void:
	geleia_pega = true
	geleia_coletada.emit()

func pegar_chocolate() -> void:
	chocolate_pego = true
	chocolate_coletado.emit()

func pegar_pincel(id: int) -> void:
	match id:
		1: pincel1_pego = true
		2: pincel2_pego = true
		3: pincel3_pego = true
	pincel_coletado.emit()

func pegar_distintivo(id: int) -> void:
	match id:
		1: distintivo1_pego = true
		2: distintivo2_pego = true
		3: distintivo3_pego = true
	distintivo_coletado.emit()

func pegar_pingente() -> void:
	pingente_pego = true
	pingente_coletado.emit()

# Devolve a letra do final do bolo: "A", "B", "C" ou "D".
# Devolve "" se o bolo ainda não foi feito.
func letra_do_bolo() -> String:
	if bolo_ingredientes < 0:
		return ""
	elif bolo_ingredientes == 0:
		return "A"
	elif bolo_ingredientes <= 3:
		return "B"
	elif bolo_ingredientes <= 5:
		return "C"
	return "D"

# --- Loja da Linna (Capítulo IV) ---

## Tenta gastar moedas. Devolve true se o jogador tinha o suficiente.
func gastar_moedas(qtd: int) -> bool:
	if qtd > moedas:
		return false
	moedas -= qtd
	moedas_alteradas.emit(moedas)
	return true


## Registra o presente comprado ("caixinha", "veludo", "caderno" ou "kit").
func comprar_presente(presente: String) -> void:
	presente_comprado = presente
	presente_comprado_sinal.emit(presente)


func ganhar_selo_coracao_vila() -> void:
	selo_coracao_vila = true
