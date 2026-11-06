extends Node2D

# LA PARTIDA
#
# Es la escena del juego en si. Arranca cuando aprieto "Nivel 1" o "Nivel 2"
# en el menu, y lo unico que hace es armar el nivel: pone al jugador en el
# punto A, la meta en el punto B, y reparte los enemigos y los botiquines en
# los lugares que dice el mapa.
#
# Los nodos vacios (Personajes, Balas) estan para tener todo ordenado y no
# que me queden 50 nodos sueltos colgando de la escena.
#
# Importante el orden: el nodo Nivel es hijo mio, y en Godot los hijos hacen
# _ready() ANTES que el padre. Asi que cuando llega mi _ready(), el nivel ya
# leyo el mapa y le puedo preguntar donde va cada cosa.

@export var escena_jugador: PackedScene
@export var escena_enemigo_tonto: PackedScene
@export var escena_enemigo_inteligente: PackedScene
@export var escena_item: PackedScene
@export var escena_meta: PackedScene

@onready var nivel = $Nivel
@onready var personajes = $Personajes
@onready var balas = $Balas


func _ready():
	# Los pongo en grupos para que los otros scripts los encuentren sin tener
	# que escribir la ruta completa tipo get_node("../../Balas"), que si
	# despues muevo un nodo se rompe todo.
	personajes.add_to_group("personajes")
	balas.add_to_group("balas")

	_crear_meta()
	_crear_jugador()
	_crear_enemigos()
	_crear_items()


func _crear_jugador():
	if escena_jugador == null:
		print("ERROR: falta poner la escena del jugador en el inspector")
		return

	var jugador = escena_jugador.instantiate()
	personajes.add_child(jugador)
	jugador.global_position = nivel.donde_empieza_el_jugador


func _crear_meta():
	if escena_meta == null:
		print("ERROR: falta poner la escena de la meta en el inspector")
		return

	var meta = escena_meta.instantiate()
	personajes.add_child(meta)
	# La meta es una puerta y va en la pared de al lado de la M, no arriba de
	# la M (eso lo calcula el nivel).
	meta.global_position = nivel.donde_va_la_puerta
	meta.orientar(nivel.para_donde_abre_la_puerta)


# Aca se ve la otra ventaja de que los dos enemigos hereden de la misma
# clase: elijo que escena crear segun la letra del mapa, pero despues los
# trato igual a los dos (los agrego a Personajes y les pongo la posicion).
func _crear_enemigos():
	for datos in nivel.donde_van_los_enemigos:
		var escena = escena_enemigo_tonto
		if datos["tipo"] == "inteligente":
			escena = escena_enemigo_inteligente

		if escena == null:
			print("ERROR: falta poner la escena del enemigo ", datos["tipo"])
			continue

		var enemigo = escena.instantiate()
		personajes.add_child(enemigo)
		enemigo.global_position = datos["posicion"]

		# Aparece creciendo, queda lindo.
		#
		# Le hago el tween al nodo Cuerpo (que es solo el dibujo) y no al
		# enemigo entero, porque si le cambio la escala al CharacterBody2D
		# tambien le cambio la del circulo de colision, y Godot me tiraba un
		# aviso de que la colision quedaba en tamanio cero.
		enemigo.cuerpo.scale = Vector2.ZERO
		var tween = create_tween()
		tween.tween_property(enemigo.cuerpo, "scale", Vector2.ONE, 0.22)


func _crear_items():
	if escena_item == null:
		return

	for datos in nivel.donde_van_los_items:
		var item = escena_item.instantiate()
		# La clase se la pongo antes del add_child porque el _ready() del item
		# la usa para elegir el dibujo.
		item.clase = datos["clase"]
		personajes.add_child(item)
		item.global_position = datos["posicion"]
