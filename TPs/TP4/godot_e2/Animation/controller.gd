extends Node3D

# Velocidad de rotación en radianes por segundo
@export var velocidad_rotacion: float = 2.0

func _process(delta: float) -> void:

	# Flecha izquierda: rotación sobre el eje Y
	if Input.is_key_pressed(KEY_LEFT):
		rotate_y(velocidad_rotacion * delta)

	# Flecha derecha: rotación sobre el eje Y
	if Input.is_key_pressed(KEY_RIGHT):
		rotate_y(-velocidad_rotacion * delta)

	# Flecha arriba: rotación sobre el eje X
	if Input.is_key_pressed(KEY_UP):
		rotate_x(velocidad_rotacion * delta)

	# Flecha abajo: rotación sobre el eje X
	if Input.is_key_pressed(KEY_DOWN):
		rotate_x(-velocidad_rotacion * delta)
