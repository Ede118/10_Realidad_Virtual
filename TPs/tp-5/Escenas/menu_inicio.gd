extends Control


func _on_boton_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/juego.tscn")


func _on_boton_salir_pressed() -> void:
	get_tree().quit()
