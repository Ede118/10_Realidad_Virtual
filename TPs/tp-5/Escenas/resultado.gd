extends CanvasLayer

signal repetir
signal menu_principal

@onready var titulo: Label = $Pantalla/Centro/Contenido/Titulo
@onready var puntuacion: Label = $Pantalla/Centro/Contenido/Puntuacion
@onready var detalle: Label = $Pantalla/Centro/Contenido/Detalle
@onready var boton_repetir: Button = $Pantalla/Centro/Contenido/Repetir


func mostrar(exitoso: bool, puntos: int, giros: int) -> void:
	titulo.text = "ATERRIZAJE EXITOSO" if exitoso else "COHETE DESTRUIDO"
	titulo.modulate = Color(0.3, 1.0, 0.7) if exitoso else Color(1.0, 0.4, 0.3)
	puntuacion.text = "PUNTUACIÓN: %d" % puntos
	detalle.text = "Aterrizaje: 500  |  Bonus por giros: %d" % (giros * 250) if exitoso else "El choque no otorga puntos."
	show()
	boton_repetir.grab_focus()


func _on_repetir_pressed() -> void:
	repetir.emit()


func _on_menu_pressed() -> void:
	menu_principal.emit()
