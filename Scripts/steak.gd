extends TextureRect

func _get_drag_data(_at_position):
	
	# 1. O fantasma agora é um TextureRect
	var preview = TextureRect.new()
	preview.texture = self.texture # Copiamos a imagem da maçã
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE # Mantém a configuração de tamanho
	preview.size = self.size * 0.25
	preview.modulate.a = 0.5 # Deixa meio transparente
	
	set_drag_preview(preview)
	
	# 2. Em vez de enviar só um texto, enviamos um Dicionário com o nome e o nó inteiro!
	return {"name": "Steak", "node": self}
