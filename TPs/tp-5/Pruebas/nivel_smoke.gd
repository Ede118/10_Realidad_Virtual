extends SceneTree

var fallos: int = 0
var escena: Node


func _initialize() -> void:
	_run.call_deferred()


func comprobar(condicion: bool, descripcion: String) -> void:
	if condicion:
		print("OK: ", descripcion)
	else:
		fallos += 1
		push_error(descripcion)


func nueva_partida(posicion: Vector2, velocidad: Vector2, angulo: float = 0.0) -> NaveLunar:
	if is_instance_valid(escena):
		escena.free()
	escena = load("res://Escenas/juego.tscn").instantiate()
	root.add_child(escena)
	current_scene = escena
	var nave: NaveLunar = escena.get_node("Cohete")
	nave.position = posicion
	nave.rotation = angulo
	nave.linear_velocity = velocidad
	nave.velocidad_antes_contacto = velocidad
	return nave


func esperar_cuadros(cantidad: int) -> void:
	for indice in range(cantidad):
		await physics_frame
	await process_frame


func tecla(codigo: Key, presionada: bool) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.pressed = presionada
	Input.parse_input_event(evento)


func _run() -> void:
	var nave: NaveLunar = await nueva_partida(Vector2(480, 150), Vector2.ZERO)
	await esperar_cuadros(12)
	var terreno: Node2D = escena.get_node("Terreno")
	var pico: Polygon2D = terreno.get_node("MontanaCentral/Visual")
	var valle: Line2D = terreno.get_node("Plataforma4/Superficie")
	var y_pico: float = (pico.to_global(pico.polygon[3])).y
	var y_valle: float = (valle.to_global(valle.points[0])).y
	comprobar(absf((y_pico + y_valle) * 0.5 - 864.0 * 0.95) < 0.01 and y_valle < 864.0, "Linea media al 5 por ciento y valle dentro de pantalla")
	var montanas: TextureRect = escena.get_node("Background/Montanas")
	var valle_pantalla: Vector2 = valle.get_global_transform_with_canvas() * valle.points[0]
	comprobar(absf(montanas.position.y + montanas.size.y * montanas.scale.y - valle_pantalla.y) < 0.1, "Fondo de montanas alineado al valle fisico")
	comprobar(nave.linear_velocity.y > 0.0 and nave.position.y > 150.0, "Gravedad y movimiento de RigidBody2D")
	comprobar(nave.combustible == 300.0, "Sin consumo con motor apagado")
	comprobar(not escena.get_node("Resultado").visible, "Pantalla de resultado oculta durante la partida")
	tecla(KEY_UP, true)
	await esperar_cuadros(12)
	comprobar(nave.combustible < 300.0 and nave.motor_encendido, "Empuje y consumo")
	comprobar(nave.sprite.animation == &"propulsion", "Animacion de propulsion")
	var barra: ProgressBar = escena.get_node("GUI/Interfaz/Panel/Combustible")
	comprobar(absf(barra.value - nave.combustible) < 1.0, "HUD conectado al combustible")
	tecla(KEY_UP, false)
	nave.combustible = 0.0
	tecla(KEY_SPACE, true)
	await esperar_cuadros(3)
	comprobar(not nave.motor_encendido and nave.combustible == 0.0, "Motor apagado sin combustible")
	tecla(KEY_SPACE, false)
	nave._registrar_giro(PI)
	nave._registrar_giro(PI)
	comprobar(nave.giros_completos == 1, "Bonus por giro de 360 grados")
	nave.giro_acumulado = 0.0
	nave.sentido_giro = 0.0
	nave._registrar_giro(PI)
	nave._registrar_giro(-PI)
	comprobar(nave.giros_completos == 1, "Invertir sentido reinicia el giro acumulado")

	nave = await nueva_partida(Vector2(230, 724.3), Vector2(0, 150))
	await esperar_cuadros(35)
	comprobar(nave.estado == NaveLunar.Estado.ESTRELLADO, "Contacto con montana destruye la nave")
	comprobar(not nave.sprite.visible and nave.freeze, "Nave oculta y detenida tras choque")
	await esperar_cuadros(35)
	comprobar(not nave.explosion.visible, "Explosion termina sin repetirse")
	comprobar(escena.get_node("Resultado").visible and not escena.get_node("GUI").visible, "Pantalla de derrota aparece tras la explosion")
	comprobar(escena.get_node("Resultado/Pantalla/Centro/Contenido/Puntuacion").text == "PUNTUACIÓN: 0", "Derrota muestra puntuacion cero")

	nave = await nueva_partida(Vector2(480, 784.05), Vector2(0, 30))
	await esperar_cuadros(30)
	comprobar(nave.estado == NaveLunar.Estado.ATERRIZADO, "Aterrizaje suave en plataforma")
	comprobar(nave.puntuacion == 500, "Puntuacion base con multiplicador x5")
	comprobar(escena.get_node("Resultado").visible and escena.get_node("Resultado/Pantalla/Centro/Contenido/Titulo").text == "ATERRIZAJE EXITOSO", "Pantalla de victoria al aterrizar")

	nave = await nueva_partida(Vector2(890, 773.55), Vector2(0, 30))
	nave.giros_completos = 2
	await esperar_cuadros(30)
	comprobar(nave.estado == NaveLunar.Estado.ATERRIZADO and nave.puntuacion == 1000, "Segunda plataforma y bonus de dos giros")
	comprobar(escena.get_node("Resultado/Pantalla/Centro/Contenido/Puntuacion").text == "PUNTUACIÓN: 1000", "Resultado incluye los puntos de los giros")

	# La antigua tercera plataforma ahora es terreno peligroso.
	nave = await nueva_partida(Vector2(1100, 801.55), Vector2(0, 30))
	await esperar_cuadros(40)
	comprobar(nave.estado == NaveLunar.Estado.ESTRELLADO, "Antigua tercera plataforma reemplazada por montana")
	var plataformas: Array[Node] = get_nodes_in_group("plataformas")
	comprobar(plataformas.size() == 3, "Quedan exactamente tres plataformas")

	nave = await nueva_partida(Vector2(1380, 822.55), Vector2(0, 30))
	await esperar_cuadros(30)
	comprobar(nave.estado == NaveLunar.Estado.ATERRIZADO, "Aterrizaje en cuarta plataforma")

	nave = await nueva_partida(Vector2(516, 784.05), Vector2(0, 30))
	await esperar_cuadros(40)
	comprobar(nave.estado == NaveLunar.Estado.ESTRELLADO, "Aterrizaje descentrado falla en plataforma estrecha")

	nave = await nueva_partida(Vector2(480, 759.05), Vector2(0, 300))
	await esperar_cuadros(20)
	comprobar(nave.estado == NaveLunar.Estado.ESTRELLADO, "Impacto rapido en plataforma explota")

	nave = await nueva_partida(Vector2(480, 774.05), Vector2(0, 30), deg_to_rad(20.0))
	await esperar_cuadros(30)
	comprobar(nave.estado == NaveLunar.Estado.ESTRELLADO, "Inclinacion excesiva impide aterrizar")

	var anterior: Node = escena
	tecla(KEY_R, true)
	await esperar_cuadros(3)
	tecla(KEY_R, false)
	comprobar(not is_instance_valid(anterior), "R recarga la escena")
	escena = current_scene
	nave = escena.get_node("Cohete")
	comprobar(nave.estado == NaveLunar.Estado.JUGANDO and nave.combustible == 300.0 and nave.puntuacion == 0 and nave.giros_completos == 0, "Reinicio restaura estado, combustible, puntos y giros")
	comprobar(not escena.get_node("Resultado").visible and escena.get_node("GUI").visible, "Reinicio oculta resultado y restaura HUD")

	nave = await nueva_partida(Vector2(480, 784.05), Vector2(0, 30))
	await esperar_cuadros(30)
	escena.get_node("Resultado/Pantalla/Centro/Contenido/Repetir").pressed.emit()
	await esperar_cuadros(3)
	escena = current_scene
	nave = escena.get_node("Cohete")
	comprobar(nave.estado == NaveLunar.Estado.JUGANDO and not escena.get_node("Resultado").visible, "Boton Repetir inicia una partida nueva")

	nave = await nueva_partida(Vector2(480, 784.05), Vector2(0, 30))
	await esperar_cuadros(30)
	escena.get_node("Resultado/Pantalla/Centro/Contenido/Menu").pressed.emit()
	await esperar_cuadros(3)
	escena = current_scene
	comprobar(escena.scene_file_path == "res://Escenas/menu_inicio.tscn", "Boton Menu abre el menu principal")
	print("Resultado: ", fallos, " fallos")
	quit(1 if fallos > 0 else 0)
