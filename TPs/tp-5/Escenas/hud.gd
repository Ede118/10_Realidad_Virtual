extends CanvasLayer

@onready var nave: NaveLunar = get_parent().get_node("Cohete")
@onready var combustible: ProgressBar = $Interfaz/Panel/Combustible


func _process(_delta: float) -> void:
	combustible.value = nave.combustible
