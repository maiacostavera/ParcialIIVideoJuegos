extends Control

# EL MENU PRINCIPAL
#
# Es la escena que arranca cuando apreto F5 (esta puesta como escena
# principal en Proyecto > Configuracion del proyecto > Aplicacion > Correr).
#
# Tiene tres opciones:
#   1) Nivel 1
#   2) Nivel 2
#   3) Salir
#
# Al costado esta la tabla de mejores puntajes (escenas/tabla_puntajes.tscn),
# que se llena sola, asi que aca no tengo que hacer nada con ella.
#
# Los botones los conecto por codigo con pressed.connect() en vez de hacerlo
# desde el editor, asi mirando este archivo se entiende que hace cada uno sin
# tener que ir a buscar las conexiones en el panel de Nodo.

@onready var boton_nivel_1 = $Centro/Panel/Margen/Lista/BotonNivel1
@onready var boton_nivel_2 = $Centro/Panel/Margen/Lista/BotonNivel2
@onready var boton_salir = $Centro/Panel/Margen/Lista/BotonSalir


func _ready():
	boton_nivel_1.pressed.connect(_apretaron_nivel_1)
	boton_nivel_2.pressed.connect(_apretaron_nivel_2)
	boton_salir.pressed.connect(_apretaron_salir)

	# Dejo el mouse visible y el primer boton marcado, asi tambien se puede
	# usar el menu con el teclado.
	boton_nivel_1.grab_focus()


func _apretaron_nivel_1():
	Game.sonar("boton")
	Game.empezar_nivel(1)


func _apretaron_nivel_2():
	Game.sonar("boton")
	Game.empezar_nivel(2)


func _apretaron_salir():
	Game.sonar("boton")
	get_tree().quit()
