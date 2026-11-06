extends Area2D

# LA META (el punto B)
#
# Es la condicion de victoria del nivel: el jugador arranca en un lugar del
# mapa (el punto A, la letra P) y tiene que llegar hasta aca (la letra M).
# Cuando la toca, le aviso a Game y Game pausa el juego y muestra la pantalla
# de "nivel completado".
#
# La meta es una PUERTA en la pared. El nivel le saca un pedazo a la pared
# que esta pegada a la M y la partida pone la puerta ahi (ver
# _buscar_donde_va_la_puerta() en nivel.gd). El dibujo es el tile_442 del
# pack de Kenney, que es una tabla de madera con marco.
#
# Igual que los botiquines uso un Area2D, porque no quiero que choque, solo
# quiero enterarme cuando el jugador llega. Lo que si choca es la Tapa (un
# StaticBody2D en la capa del mundo), que esta para que no se pueda salir del
# mapa por el agujero de la pared ni se escapen las balas.
#
# La escena esta armada para una puerta en una pared de la derecha (afuera
# del mapa queda a la derecha). Si la puerta va en otra pared, orientar() la
# gira. El Cartel no lo giro, asi siempre se lee derecho.
#
# El Cartel va ABAJO de la puerta y no arriba: en el nivel 2 la puerta esta
# en la esquina de arriba a la derecha, y arriba se pisaba con los textos
# del HUD (nivel, puntaje...).

@onready var puerta = $Puerta
@onready var bisagra = $Puerta/Bisagra
@onready var colision_de_la_tapa = $Puerta/Tapa/Colision

var _ya_la_toco = false


func _ready():
	body_entered.connect(_cuando_la_tocan)


# La llama la partida cuando crea la meta. "afuera" es para que lado queda
# afuera del mapa, y como la escena esta hecha mirando a la derecha, el
# angulo de ese vector es justo lo que tengo que girar.
func orientar(afuera):
	puerta.rotation = afuera.angle()


func _cuando_la_tocan(quien):
	if _ya_la_toco:
		return
	if not quien.is_in_group("jugador"):
		return

	_ya_la_toco = true

	# La puerta se abre girando desde la bisagra para afuera.
	#
	# Game.ganar_nivel() pausa el juego, y un tween comun se pausaria junto
	# con todo y la puerta se quedaria cerrada. Con TWEEN_PAUSE_PROCESS el
	# tween sigue andando aunque el juego este en pausa.
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(bisagra, "rotation", -PI / 2.0, 0.3)

	# Le saco la colision a la tapa porque la puerta ya no esta en el hueco.
	# Va con set_deferred porque esta señal llega en pleno paso de fisica.
	colision_de_la_tapa.set_deferred("disabled", true)

	Game.ganar_nivel()
