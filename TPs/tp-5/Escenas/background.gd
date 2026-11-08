extends CanvasLayer

@export_range(0.05, 1.0) var proporcion_altura_montanas: float = 0.25
@export_range(0.1, 3.0) var escala_montanas: float = 1.2
@export var margen_planeta: float = 24.0

@onready var montanas: TextureRect = $Montanas
@onready var planeta: AnimatedSprite2D = $Planeta


func _ready() -> void:
	get_viewport().size_changed.connect(_acomodar)
	# Esperar a que la camara hermana termine de entrar al arbol.
	_acomodar.call_deferred()


func _acomodar() -> void:
	var ventana: Vector2 = get_viewport().get_visible_rect().size
	var altura_textura: float = montanas.texture.get_height()
	var altura_franja: float = ventana.y * proporcion_altura_montanas * escala_montanas
	var factor: float = altura_franja / altura_textura
	# TILE repite horizontalmente; la escala conserva la proporcion de cada copia.
	montanas.scale = Vector2(factor, factor)
	montanas.position = Vector2(0.0, _valle_mas_bajo(ventana.y) - altura_franja)
	montanas.size = Vector2(ventana.x / factor, altura_textura)
	var cuadro: Texture2D = planeta.sprite_frames.get_frame_texture(planeta.animation, 0)
	var mitad_planeta: Vector2 = cuadro.get_size() * planeta.scale * 0.5
	planeta.position = Vector2(ventana.x - margen_planeta - mitad_planeta.x, margen_planeta + mitad_planeta.y)


func _valle_mas_bajo(altura_ventana: float) -> float:
	var camara: Camera2D = get_viewport().get_camera_2d()
	if camara != null:
		camara.force_update_scroll()
	var terreno: Node2D = get_parent().get_node("Terreno")
	var valle: float = -INF
	for cuerpo in terreno.get_children():
		var superficie := cuerpo.get_node_or_null("Superficie") as Line2D
		if superficie != null:
			for punto in superficie.points:
				var en_pantalla: Vector2 = superficie.get_global_transform_with_canvas() * punto
				valle = maxf(valle, en_pantalla.y)
		else:
			var visual := cuerpo.get_node_or_null("Visual") as Polygon2D
			if visual == null:
				continue
			# Los dos ultimos vertices cierran la base; no pertenecen al relieve.
			for indice in range(visual.polygon.size() - 2):
				var en_pantalla: Vector2 = visual.get_global_transform_with_canvas() * visual.polygon[indice]
				valle = maxf(valle, en_pantalla.y)
	return altura_ventana if is_inf(valle) else valle
