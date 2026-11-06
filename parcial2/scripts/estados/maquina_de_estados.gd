class_name MaquinaDeEstados
extends Node

# Esta es la maquina de estados. Va como nodo hijo del jugador y de los
# enemigos, y cada estado es un nodo hijo de ella:
#
#   Jugador
#   └── MaquinaDeEstados
#       ├── Quieto        <- el primer hijo es con el que arranca
#       ├── Caminar
#       ├── Esquivar
#       ├── Recargar
#       └── Muerto
#
# Lo bueno de hacerlo con nodos es que lo veo dibujado en el editor y no me
# pierdo. Y como solo le aviso al estado activo, los otros no gastan nada.
#
# El mismo script lo usan el jugador y los dos enemigos. Lo unico que cambia
# son los nodos de estado que le cuelgo abajo en cada escena.

var estado_actual = null
var duenio = null    # el jugador o el enemigo que tiene esta maquina
var etiqueta = null  # el cartelito de debug, si el personaje tiene uno


# Esto lo llama el jugador o el enemigo al final de su _ready().
#
# Al principio lo hacia en el _ready() de este mismo script, pero no andaba:
# los hijos hacen _ready() ANTES que el padre, entonces cuando la maquina
# arrancaba el jugador todavia no habia terminado de prepararse y me tiraba
# errores de null. Haciendolo al reves (que el jugador avise cuando esta
# listo) se soluciono.
func iniciar(quien):
	duenio = quien

	for hijo in get_children():
		hijo.entidad = quien
		hijo.pedir_cambio.connect(cambiar_a)

	etiqueta = quien.get_node_or_null("Etiqueta")

	# Arranco con el primer hijo.
	if get_child_count() > 0:
		estado_actual = get_child(0)
		estado_actual.entrar()
		_actualizar_etiqueta()
	else:
		print("ERROR: la MaquinaDeEstados de ", quien.name, " no tiene estados")


func _physics_process(delta):
	if estado_actual == null:
		return

	estado_actual.actualizar(delta)

	if etiqueta != null:
		etiqueta.visible = Game.ver_estados


# Cambia de estado. El nombre tiene que ser igual al del nodo hijo.
func cambiar_a(nombre_del_estado):
	var nuevo = get_node_or_null(nombre_del_estado)

	if nuevo == null:
		# Si me equivoco escribiendo el nombre prefiero que me avise por
		# consola antes que el juego se rompa sin decir nada.
		print("ERROR: no existe el estado '", nombre_del_estado,
			"' en ", duenio.name)
		return

	if nuevo == estado_actual:
		return

	estado_actual.salir()
	estado_actual = nuevo
	estado_actual.entrar()
	_actualizar_etiqueta()


# Sirve para preguntar desde afuera en que estado estoy.
func esta_en(nombre_del_estado):
	return estado_actual != null and estado_actual.name == nombre_del_estado


func _actualizar_etiqueta():
	if etiqueta == null or estado_actual == null:
		return

	var texto = estado_actual.name

	# Si el duenio es un enemigo le agrego adelante que tipo es, asi con F3
	# veo de un vistazo cual es el tonto y cual el inteligente.
	#
	# Este "is Enemigo" funciona justamente porque la clase comun tiene
	# class_name Enemigo. Me sirve para los dos tipos de una sola vez, sin
	# preguntar por cada uno por separado.
	if duenio is Enemigo:
		texto = duenio.como_me_llamo() + ": " + texto

	etiqueta.text = texto
