extends PanelContainer

# LA TABLA DE MEJORES PUNTAJES
#
# La uso en dos lugares: al costado del menu principal y en la pantalla de
# cuando termina la partida (perdiendo o ganando el ultimo nivel). Por eso la
# hice como escena aparte: la armo una sola vez y la instancio donde la
# necesito.
#
# Los puntajes no los guarda esta escena, los tiene Game, que es el que lee
# y escribe el archivo. Aca solo los muestro.
#
# Las filas las creo por codigo porque no se cuantas va a haber (de 0 a 10).
# Uso un GridContainer con 4 columnas (puesto, puntos, hasta donde llego y
# fecha) asi quedan alineadas, cosa que con un Label solo no pasaba porque
# las letras no miden todas lo mismo.

const COLOR_NORMAL = Color(1, 1, 1, 0.85)
const COLOR_NUEVO = Color(0.96, 0.45, 0.13)   # el naranja del menu

@onready var grilla = $Margen/Lista/Grilla
@onready var texto_vacio = $Margen/Lista/TextoVacio


func _ready():
	actualizar(Game.puesto_nuevo)


# "resaltar" es el puesto que pinto de naranja (la partida que se acaba de
# terminar). Con -1 no pinto ninguno.
func actualizar(resaltar = -1):
	# Borro las filas viejas. Con remove_child primero, porque queue_free()
	# solo las borra al final del frame y por un frame se veian las viejas y
	# las nuevas juntas.
	for celda in grilla.get_children():
		grilla.remove_child(celda)
		celda.queue_free()

	texto_vacio.visible = Game.mejores_puntajes.size() == 0

	for i in range(Game.mejores_puntajes.size()):
		var fila = Game.mejores_puntajes[i]

		var color = COLOR_NORMAL
		if i == resaltar:
			color = COLOR_NUEVO

		# Los numeros que vienen del JSON llegan como decimales (120.0), por
		# eso el int().
		var hasta_donde = "Nivel " + str(int(fila["nivel"]))
		if fila.get("gano", false):
			hasta_donde = "Completo"

		_agregar_celda(str(i + 1) + ".", color, HORIZONTAL_ALIGNMENT_RIGHT)
		_agregar_celda(str(int(fila["puntos"])), color, HORIZONTAL_ALIGNMENT_RIGHT)
		_agregar_celda(hasta_donde, color, HORIZONTAL_ALIGNMENT_LEFT)
		_agregar_celda(str(fila["fecha"]), color, HORIZONTAL_ALIGNMENT_LEFT)


func _agregar_celda(texto, color, alineacion):
	var celda = Label.new()
	celda.text = texto
	celda.horizontal_alignment = alineacion
	celda.add_theme_color_override("font_color", color)
	celda.add_theme_font_size_override("font_size", 17)
	grilla.add_child(celda)
