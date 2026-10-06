extends Control
class_name Slot

@onready var icone_item = $Panel/IconeItem
var item_guardado: ItemData = null

func definir_item(item: ItemData):
	item_guardado = item
	if item:
		icone_item.texture = item.icone
		icone_item.custom_minimum_size = Vector2(40, 40) # Força um tamanho
	else:
		icone_item.texture = null

# --- DRAG AND DROP ---

# O que acontece ao começar a arrastar
func _get_drag_data(at_position):
	if item_guardado == null:
		return null
	
	# Criar o preview (o ícone que segue o mouse)
	var preview = TextureRect.new()
	preview.texture = icone_item.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = Vector2(50, 50)
	set_drag_preview(preview)
	
	return self # Retorna este slot como dado do arraste

# Verifica se pode soltar aqui
func _can_drop_data(at_position, data):
	return data is Slot

# O que acontece ao soltar o item
func _drop_data(at_position, data):
	# 1. Troca os dados dos itens (a lógica do item em si)
	var item_temp = self.item_guardado
	self.item_guardado = data.item_guardado
	data.item_guardado = item_temp
	
	# 2. Troca as texturas visualmente
	var textura_temp = self.icone_item.texture
	self.icone_item.texture = data.icone_item.texture
	data.icone_item.texture = textura_temp
