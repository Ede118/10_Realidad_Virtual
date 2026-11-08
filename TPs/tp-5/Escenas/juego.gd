extends Node2D

@onready var resultado: CanvasLayer = $Resultado


func _ready() -> void:
	$Cohete.nivel_finalizado.connect(_mostrar_resultado)
	resultado.repetir.connect(_repetir_nivel)
	resultado.menu_principal.connect(_volver_al_menu)


func _mostrar_resultado(exitoso: bool, puntos: int, giros: int) -> void:
	$GUI.hide()
	resultado.mostrar(exitoso, puntos, giros)


func _repetir_nivel() -> void:
	get_tree().reload_current_scene()


func _volver_al_menu() -> void:
	get_tree().change_scene_to_file("res://Escenas/menu_inicio.tscn")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		# Igual que reiniciar() en Processing: combustible a 300; giros y puntos a cero.
		_repetir_nivel()
