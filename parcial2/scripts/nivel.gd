extends Node2D

# EL NIVEL
#
# En vez de dibujar el mapa a mano con un TileMap, lo escribi como texto.
# Cada letra es una celda de 64x64 pixeles. Me parecio mucho mas comodo:
# cambio una letra y ya tengo otro mapa, sin abrir el editor.
#
# Que significa cada simbolo:
#
#   #  pared                    .  piso de madera
#   P  aca empieza el jugador (el PUNTO A)
#   M  aca esta la meta       (el PUNTO B, hay que llegar hasta aca)
#   Z  zombie tonto             I  zombie inteligente
#   h  botiquin                 a  cajon de municion
#   c  cajon    m  mesa    f  sofa      (estos tres frenan el paso)
#
# Ojo con las mayusculas: la "M" grande es la meta y la "m" chica es una
# mesa. Me equivoque una vez y el jugador ganaba el nivel apenas tocaba un
# mueble.
#
# Los dos mapas estan aca abajo como constantes, y en _ready() elijo cual
# usar segun Game.nivel_actual. Lo hice asi en vez de tener dos escenas de
# nivel separadas porque todo lo demas (las paredes, los muebles, como se
# lee el texto) es exactamente igual en los dos, asi no repito nada.

const TAMANIO_CELDA = 64

# NIVEL 1: bastante abierto, mas zombies tontos que inteligentes.
# El jugador arranca arriba a la izquierda y la meta esta abajo a la derecha,
# o sea que tiene que cruzar todo el mapa en diagonal.
const MAPA_1 = [
	"########################",
	"#P.....#..........#....#",
	"#......#....Z.....#....#",
	"#..c...#..........#..m.#",
	"#......#####..#####....#",
	"#..Z..........I........#",
	"#......................#",
	"####..####......####..##",
	"#........#..h...#......#",
	"#...Z....#......#...Z..#",
	"#........#......#......#",
	"#..####..####..####....#",
	"#.....a........f.......#",
	"#...I.........Z........#",
	"#.....................M#",
	"########################",
]

# NIVEL 2: mas cerrado, con pasillos y piezas. Tiene mas zombies inteligentes,
# que es donde mas se nota la diferencia: el tonto se traba en las esquinas y
# el inteligente da la vuelta y te encuentra igual.
# El jugador arranca arriba a la izquierda y la meta esta arriba a la
# derecha, pero las paredes lo obligan a bajar y dar toda la vuelta.
const MAPA_2 = [
	"########################",
	"#P...#..........#.....M#",
	"#....#..........#......#",
	"#..c.#...ZZ.....#...m..#",
	"#....#..........#......#",
	"#....######..####......#",
	"#..I.............#.....#",
	"#....#####..#....#..####",
	"#....#...#..#....#.....#",
	"#..h.#.I.#..#..a.#..Z..#",
	"#....#...#..#....#.....#",
	"#....##.##..#....####..#",
	"#...........#..........#",
	"#..Z....Z...#....I.....#",
	"#...........#..........#",
	"########################",
]

# Los tiles que uso del pack de Kenney.
const TILE_PARED = preload("res://assets/tile_86.png")
const TILE_PISO = preload("res://assets/tile_43.png")

# Los muebles que frenan el paso: el dibujo y el tamanio del circulo que les
# pongo de colision.
const MUEBLES = {
	"c": {"imagen": preload("res://assets/tile_129.png"), "radio": 25.0},
	"m": {"imagen": preload("res://assets/tile_501.png"), "radio": 27.0},
	"f": {"imagen": preload("res://assets/tile_478.png"), "radio": 25.0},
}

# Estas las lee la escena de la partida para saber donde poner cada cosa.
var donde_empieza_el_jugador = Vector2(300, 300)
var donde_esta_la_meta = Vector2(600, 600)
var donde_van_los_enemigos = []   # lista de {"posicion": ..., "tipo": "tonto"/"inteligente"}
var donde_van_los_items = []      # lista de {"posicion": ..., "clase": "vida"/"municion"}

# La salida es una puerta, y la puerta va EN LA PARED que esta pegada a la M
# (no arriba de la M). Ver _buscar_donde_va_la_puerta().
# "para_donde_abre" es para que lado queda afuera del mapa, la meta lo usa
# para girar la puerta.
var donde_va_la_puerta = Vector2(600, 600)
var para_donde_abre_la_puerta = Vector2.RIGHT
var _celda_de_la_puerta = Vector2i(-1, -1)

var ancho_en_pixeles = 0
var alto_en_pixeles = 0

var _mapa = []
var _filas = 0
var _columnas = 0

# El buscador de caminos. Lo usa el zombie inteligente para ir esquivando las
# paredes y los muebles hasta llegar al jugador.
#
# AStarGrid2D ya viene con Godot y sirve justo para esto: le digo de que
# tamanio es la grilla, cuales celdas estan tapadas, y el me devuelve la lista
# de puntos por los que hay que pasar. No tuve que programar el algoritmo.
var _buscador_de_caminos = AStarGrid2D.new()


func _ready():
	add_to_group("nivel")

	_mapa = _elegir_el_mapa()
	_filas = _mapa.size()
	_columnas = _mapa[0].length()
	ancho_en_pixeles = _columnas * TAMANIO_CELDA
	alto_en_pixeles = _filas * TAMANIO_CELDA

	_revisar_que_el_mapa_este_bien()
	# La puerta la busco antes de leer el mapa, porque _leer_el_mapa() tiene
	# que saber en que celda NO poner pared.
	_buscar_donde_va_la_puerta()
	_leer_el_mapa()
	_poner_los_muebles()
	_preparar_el_buscador_de_caminos()


# Elijo el mapa segun el nivel que me dijo Game. Si el numero no existe uso
# el 1, asi nunca se rompe.
func _elegir_el_mapa():
	if Game.nivel_actual == 2:
		return MAPA_2
	return MAPA_1


# La puerta de salida va en una pared pegada a la M. Pruebo los cuatro
# costados y me quedo con el primero que sea pared del BORDE del mapa, asi la
# puerta da para afuera y no a otra pieza.
#
# No toco los mapas de texto: la M sigue donde estaba y sigue siendo el
# punto B. Lo unico que cambia es que a la pared de al lado le saco un
# pedazo para poner la puerta.
func _buscar_donde_va_la_puerta():
	var celda_meta = Vector2i(-1, -1)
	for f in range(_filas):
		for c in range(_columnas):
			if _mapa[f][c] == "M":
				celda_meta = Vector2i(c, f)

	if celda_meta.x < 0:
		print("ERROR: el mapa no tiene meta (la letra M)")
		return

	# Si no encuentro ninguna pared del borde, la puerta queda arriba de la M
	# como estaba antes la meta, asi por lo menos se puede ganar igual.
	donde_va_la_puerta = Vector2(celda_meta) * TAMANIO_CELDA + Vector2(TAMANIO_CELDA, TAMANIO_CELDA) / 2

	for costado in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		var celda = celda_meta + costado
		if _es_pared_del_borde(celda):
			_celda_de_la_puerta = celda
			donde_va_la_puerta = Vector2(celda) * TAMANIO_CELDA + Vector2(TAMANIO_CELDA, TAMANIO_CELDA) / 2
			para_donde_abre_la_puerta = Vector2(costado)
			return

	print("ERROR: la M tiene que estar pegada a una pared del borde del mapa")


func _es_pared_del_borde(celda):
	if celda.x < 0 or celda.y < 0 or celda.x >= _columnas or celda.y >= _filas:
		return false
	if _mapa[celda.y][celda.x] != "#":
		return false
	return celda.x == 0 or celda.y == 0 or celda.x == _columnas - 1 or celda.y == _filas - 1


# Si edito el mapa y me como una letra, todo queda corrido y despues no
# entiendo por que. Esto me avisa por consola en que fila me equivoque.
func _revisar_que_el_mapa_este_bien():
	for f in range(_filas):
		if _mapa[f].length() != _columnas:
			print("ERROR en el mapa: la fila ", f, " tiene ", _mapa[f].length(),
				" letras y tendria que tener ", _columnas)


func _leer_el_mapa():
	for f in range(_filas):
		for c in range(_columnas):
			var letra = _mapa[f][c]
			var posicion = Vector2(c, f) * TAMANIO_CELDA
			var centro = posicion + Vector2(TAMANIO_CELDA, TAMANIO_CELDA) / 2

			# En la celda de la puerta no pongo pared: pongo piso y la puerta
			# va arriba. En el mapa de texto sigue siendo un "#", asi que para
			# el buscador de caminos sigue tapada y los zombies no la usan.
			if letra == "#" and Vector2i(c, f) != _celda_de_la_puerta:
				_poner_pared(posicion)
			else:
				_poner_piso(posicion)

			# Lo que no es pared ni piso son marcas: me guardo donde estan y
			# despues la partida se encarga de crear las cosas.
			if letra == "P":
				donde_empieza_el_jugador = centro
			elif letra == "M":
				donde_esta_la_meta = centro
			elif letra == "Z":
				donde_van_los_enemigos.append({"posicion": centro, "tipo": "tonto"})
			elif letra == "I":
				donde_van_los_enemigos.append({"posicion": centro, "tipo": "inteligente"})
			elif letra == "h":
				donde_van_los_items.append({"posicion": centro, "clase": "vida"})
			elif letra == "a":
				donde_van_los_items.append({"posicion": centro, "clase": "municion"})


func _poner_piso(posicion):
	var imagen = Sprite2D.new()
	imagen.texture = TILE_PISO
	imagen.centered = false   # si no, lo dibuja corrido medio tile
	imagen.position = posicion
	imagen.z_index = -2
	add_child(imagen)


# Cada pared es un StaticBody2D con su dibujo y su cuadrado de colision.
# Se que seria mas prolijo juntar las paredes que estan pegadas en un solo
# cuerpo, pero asi es mas facil de entender y el juego anda igual de rapido.
func _poner_pared(posicion):
	var pared = StaticBody2D.new()
	pared.position = posicion + Vector2(TAMANIO_CELDA, TAMANIO_CELDA) / 2
	pared.collision_layer = 1
	pared.collision_mask = 0
	add_child(pared)

	var imagen = Sprite2D.new()
	imagen.texture = TILE_PARED
	pared.add_child(imagen)

	var colision = CollisionShape2D.new()
	var cuadrado = RectangleShape2D.new()
	cuadrado.size = Vector2(TAMANIO_CELDA, TAMANIO_CELDA)
	colision.shape = cuadrado
	pared.add_child(colision)


# =========================================================================
# Buscar caminos (lo usa el zombie inteligente)
# =========================================================================

func _preparar_el_buscador_de_caminos():
	# La grilla es del mismo tamanio que el mapa de texto: una celda por letra.
	_buscador_de_caminos.region = Rect2i(0, 0, _columnas, _filas)
	_buscador_de_caminos.cell_size = Vector2(TAMANIO_CELDA, TAMANIO_CELDA)

	# Con este offset los puntos que me devuelve caen en el CENTRO de la
	# celda y no en la esquina de arriba a la izquierda.
	_buscador_de_caminos.offset = Vector2(TAMANIO_CELDA, TAMANIO_CELDA) / 2

	# Que pueda ir en diagonal, pero solo si las dos celdas de al lado estan
	# libres. Sin esto cortaba las esquinas y se metia adentro de las paredes.
	_buscador_de_caminos.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES

	# OJO con el orden: update() BORRA las celdas que marque como tapadas.
	# Asi que primero update() y recien despues marco las paredes. Al reves
	# no funcionaba y el zombie inteligente atravesaba todo.
	_buscador_de_caminos.update()

	for f in range(_filas):
		for c in range(_columnas):
			var letra = _mapa[f][c]
			# Las paredes y los muebles tapan el paso.
			if letra == "#" or MUEBLES.has(letra):
				_buscador_de_caminos.set_point_solid(Vector2i(c, f), true)


# Pasa una posicion en pixeles a la celda del mapa que le toca.
func celda_de(posicion):
	return Vector2i(int(posicion.x / TAMANIO_CELDA), int(posicion.y / TAMANIO_CELDA))


# Devuelve la lista de puntos para ir desde un lugar hasta otro esquivando
# las paredes. Si no hay camino devuelve una lista vacia.
#
# Los puntos vienen en coordenadas del mundo porque el nodo Nivel esta en la
# posicion (0, 0) de la escena, asi que la posicion local y la global son la
# misma.
func camino_entre(desde, hasta):
	var celda_inicial = celda_de(desde)
	var celda_final = celda_de(hasta)

	# Si alguna de las dos queda fuera del mapa no busco nada.
	if not _buscador_de_caminos.is_in_boundsv(celda_inicial):
		return PackedVector2Array()
	if not _buscador_de_caminos.is_in_boundsv(celda_final):
		return PackedVector2Array()

	# El "true" del final es para que, si el jugador esta parado justo en una
	# celda tapada (por ejemplo en el borde de una mesa), igual me devuelva el
	# camino hasta lo mas cerca que pueda llegar en vez de no devolver nada.
	return _buscador_de_caminos.get_point_path(celda_inicial, celda_final, true)


# =========================================================================

func _poner_los_muebles():
	for f in range(_filas):
		for c in range(_columnas):
			var letra = _mapa[f][c]
			if not MUEBLES.has(letra):
				continue

			var datos = MUEBLES[letra]
			var mueble = StaticBody2D.new()
			mueble.position = Vector2(c, f) * TAMANIO_CELDA + Vector2(32, 32)
			mueble.collision_layer = 1
			mueble.collision_mask = 0
			add_child(mueble)

			var imagen = Sprite2D.new()
			imagen.texture = datos["imagen"]
			mueble.add_child(imagen)

			var colision = CollisionShape2D.new()
			var circulo = CircleShape2D.new()
			circulo.radius = datos["radio"]
			colision.shape = circulo
			mueble.add_child(colision)
