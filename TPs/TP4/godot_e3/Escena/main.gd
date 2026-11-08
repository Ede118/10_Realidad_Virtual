extends Node3D

# ======================================================
# VARIABLES PRINCIPALES
# ======================================================

var planos: Array[MeshInstance3D] = []

var angulo_x: float = 0.0
var angulo_y: float = 0.0

var velocidad: float = 0.2

var eje_rotacion: int = 2
var sentido: int = 1

# ======================================================
# CONFIGURACIÓN INICIAL
# ======================================================

func _ready() -> void:
	crear_planos()
	crear_esfera()

# ======================================================
# CREACIÓN DE LOS SEIS PLANOS
# ======================================================

func crear_planos() -> void:
	var cantidad: int = 6
	var radio: float = 200.0

	for i in range(cantidad):
		var angulo: float = TAU * float(i) / cantidad

		var x: float = cos(angulo) * radio
		var z: float = sin(angulo) * radio

		var plano := MeshInstance3D.new()

		var malla := QuadMesh.new()
		malla.size = Vector2(120.0, 180.0)
		plano.mesh = malla

		plano.position = Vector3(x, 0.0, z)
		plano.rotation.y = -angulo + (PI / 2.0)

		var material := StandardMaterial3D.new()
		material.albedo_color = Color(
			randf_range(80.0 / 255.0, 1.0),
			randf_range(80.0 / 255.0, 1.0),
			randf_range(80.0 / 255.0, 1.0)
		)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		plano.material_override = material

		add_child(plano)
		planos.append(plano)

# ======================================================
# CREACIÓN DE LA ESFERA CENTRAL
# ======================================================

func crear_esfera() -> void:
	var esfera := MeshInstance3D.new()

	var malla := SphereMesh.new()
	malla.radius = 40.0
	malla.height = 80.0
	esfera.mesh = malla

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(
		200.0 / 255.0,
		100.0 / 255.0,
		50.0 / 255.0
	)
	esfera.material_override = material

	add_child(esfera)

# ======================================================
# ACTUALIZACIÓN DE LA ESCENA
# ======================================================

func _process(delta: float) -> void:
	# Modificación continua de la velocidad normalizada por delta
	if Input.is_key_pressed(KEY_KP_ADD) or Input.is_key_pressed(KEY_EQUAL):
		velocidad += 0.5 * delta
	elif Input.is_key_pressed(KEY_KP_SUBTRACT) or Input.is_key_pressed(KEY_MINUS):
		velocidad -= 0.5 * delta
		if velocidad < 0.0:
			velocidad = 0.0

	# Actualización de ángulos según el eje seleccionado
	if eje_rotacion == 1:
		angulo_x += velocidad * sentido * delta
	elif eje_rotacion == 2:
		angulo_y += velocidad * sentido * delta

	rotation = Vector3(angulo_x, angulo_y, 0.0)

# ======================================================
# DETECCIÓN DE TECLAS (PULSACIÓN ÚNICA)
# ======================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_RIGHT:
				eje_rotacion = 2
				sentido = 1
			elif event.keycode == KEY_LEFT:
				eje_rotacion = 2
				sentido = -1
			elif event.keycode == KEY_DOWN:
				eje_rotacion = 1
				sentido = 1
			elif event.keycode == KEY_UP:
				eje_rotacion = 1
				sentido = -1
			elif event.keycode == KEY_D:
				eje_rotacion = 0
			elif event.keycode == KEY_R:
				angulo_x = 0.0
				angulo_y = 0.0
				eje_rotacion = 2
				sentido = 1
				for plano in planos:
					cambiar_diseno(plano)

# ======================================================
# CAMBIO DE MATERIAL
# ======================================================

func cambiar_diseno(plano: MeshInstance3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(
		randf_range(80.0 / 255.0, 1.0),
		randf_range(80.0 / 255.0, 1.0),
		randf_range(80.0 / 255.0, 1.0)
	)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	plano.material_override = material
