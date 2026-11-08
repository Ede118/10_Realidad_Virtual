class_name NaveLunar
extends RigidBody2D

signal nivel_finalizado(exitoso: bool, puntos: int, giros: int)

enum Estado { JUGANDO, ATERRIZADO, ESTRELLADO }

# Processing usa pixeles por cuadro. Se convierten a segundos suponiendo 60 FPS.
const FPS_REFERENCIA: float = 60.0
const COMBUSTIBLE_INICIAL: float = 300.0
const PUNTOS_BASE: int = 100
const BONUS_360: int = 250

@export var gravedad: float = 0.05 * FPS_REFERENCIA * FPS_REFERENCIA
@export var empuje: float = 0.12 * FPS_REFERENCIA * FPS_REFERENCIA
@export var consumo_por_segundo: float = 0.7 * FPS_REFERENCIA
@export var velocidad_rotacion: float = PI / 40.0 * FPS_REFERENCIA
@export var limites_nivel: Rect2 = Rect2(0, 0, 1536, 864)

var combustible: float = COMBUSTIBLE_INICIAL
var estado: Estado = Estado.JUGANDO
var puntuacion: int = 0
var giros_completos: int = 0
var motor_encendido: bool = false
var giro_acumulado: float = 0.0
var sentido_giro: float = 0.0
var tiempo_bonus: float = 0.0
# Conserva la velocidad anterior a la respuesta del solver (que frena el impacto).
var velocidad_antes_contacto: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var explosion: AnimatedSprite2D = $Explosion
@onready var pata_izquierda: Marker2D = $PataIzquierda
@onready var pata_derecha: Marker2D = $PataDerecha


func _ready() -> void:
	position = Vector2(randf_range(limites_nivel.position.x + 140.0, limites_nivel.end.x - 100.0), randf_range(80.0, 140.0))
	linear_velocity = Vector2(randf_range(-0.8, 0.8), randf_range(0.6, 1.4)) * FPS_REFERENCIA
	velocidad_antes_contacto = linear_velocity
	explosion.animation_finished.connect(_on_explosion_finished)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if estado != Estado.JUGANDO:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		return

	# Evaluar todos los contactos: una montana prevalece sobre una plataforma.
	var plataforma: StaticBody2D = null
	for indice in range(state.get_contact_count()):
		var cuerpo := state.get_contact_collider_object(indice) as StaticBody2D
		if cuerpo == null:
			continue
		if not cuerpo.is_in_group("plataformas"):
			_finalizar(state, false)
			return
		plataforma = cuerpo
	if plataforma != null:
		_finalizar(state, _aterrizaje_valido(state, plataforma))
		return

	var delta: float = state.step
	tiempo_bonus = maxf(0.0, tiempo_bonus - delta)
	var direccion: float = float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
	var giro: float = direccion * velocidad_rotacion * delta
	var transformacion: Transform2D = state.transform
	transformacion = Transform2D(transformacion.get_rotation() + giro, transformacion.origin)
	state.transform = transformacion
	state.angular_velocity = 0.0
	_registrar_giro(giro)

	motor_encendido = combustible > 0.0 and (Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_SPACE))
	var aceleracion := Vector2(0.0, gravedad)
	if motor_encendido:
		aceleracion += Vector2.UP.rotated(transformacion.get_rotation()) * empuje
		combustible = maxf(0.0, combustible - consumo_por_segundo * delta)
		sprite.play("propulsion")
	else:
		sprite.play("reposo")

	# Integracion propia: evita sumar tambien la gravedad terrestre de Godot.
	# Equivale al factor 0.99 por cuadro del codigo original.
	var velocidad: Vector2 = (state.linear_velocity + aceleracion * delta) * pow(0.99, delta * FPS_REFERENCIA)
	velocidad.x = clampf(velocidad.x, -15.0 * FPS_REFERENCIA, 15.0 * FPS_REFERENCIA)
	velocidad.y = minf(velocidad.y, 10.0 * FPS_REFERENCIA)
	state.linear_velocity = velocidad
	velocidad_antes_contacto = velocidad

	# Si sale completamente del nivel, permite volver a intentar con R.
	if transformacion.origin.x < limites_nivel.position.x - 100.0 or transformacion.origin.x > limites_nivel.end.x + 100.0 or transformacion.origin.y > limites_nivel.end.y + 150.0:
		_finalizar(state, false)


func _aterrizaje_valido(state: PhysicsDirectBodyState2D, plataforma: StaticBody2D) -> bool:
	var superficie: Line2D = plataforma.get_node("Superficie")
	var inicio: Vector2 = superficie.to_global(superficie.points[0])
	var fin: Vector2 = superficie.to_global(superficie.points[1])
	var izquierda: Vector2 = state.transform * pata_izquierda.position
	var derecha: Vector2 = state.transform * pata_derecha.position
	var ambas_patas: bool = izquierda.x >= inicio.x and izquierda.x <= fin.x and derecha.x >= inicio.x and derecha.x <= fin.x
	var contacto_superior: bool = absf(izquierda.y - inicio.y) < 12.0 and absf(derecha.y - inicio.y) < 12.0
	var angulo: float = wrapf(state.transform.get_rotation(), -PI, PI)
	return ambas_patas and contacto_superior and absf(velocidad_antes_contacto.y) < 1.5 * FPS_REFERENCIA and absf(velocidad_antes_contacto.x) < FPS_REFERENCIA and absf(angulo) < deg_to_rad(12.0)


func _finalizar(state: PhysicsDirectBodyState2D, exitoso: bool) -> void:
	estado = Estado.ATERRIZADO if exitoso else Estado.ESTRELLADO
	motor_encendido = false
	state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 0.0
	set_deferred("freeze", true)
	if exitoso:
		puntuacion = PUNTOS_BASE * 5 + giros_completos * BONUS_360
		sprite.play("reposo")
		_notificar_resultado.call_deferred()
	else:
		sprite.hide()
		explosion.show()
		explosion.play("explosion")


func _registrar_giro(giro: float) -> void:
	if is_zero_approx(giro):
		return
	var nuevo_sentido: float = signf(giro)
	if sentido_giro == 0.0 or sentido_giro == nuevo_sentido:
		giro_acumulado += absf(giro)
	else:
		giro_acumulado = absf(giro)
	sentido_giro = nuevo_sentido
	while giro_acumulado >= TAU:
		giros_completos += 1
		giro_acumulado -= TAU
		tiempo_bonus = 1.5


func _on_explosion_finished() -> void:
	explosion.hide()
	_notificar_resultado()


func _notificar_resultado() -> void:
	nivel_finalizado.emit(estado == Estado.ATERRIZADO, puntuacion, giros_completos)
