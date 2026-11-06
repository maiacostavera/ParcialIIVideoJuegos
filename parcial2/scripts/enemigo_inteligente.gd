class_name EnemigoInteligente
extends Enemigo

# EL ZOMBIE INTELIGENTE
#
# Hereda de Enemigo igual que el tonto, asi que la vida, el mordiscon, los
# balazos y la muerte ya los tiene de la clase comun. Muerde exactamente
# igual que el otro.
#
# Lo unico que cambia es COMO llega hasta el jugador, y ahi esta toda la
# diferencia:
#
#   El tonto      camina siempre derecho. Si hay una pared en el medio se
#                 queda ahi apretado hasta que el jugador se corre.
#
#   El inteligente le pide al nivel un camino que esquive las paredes y los
#                 muebles, y lo va siguiendo punto por punto. Da la vuelta
#                 a la pared y te encuentra igual.
#
# Para el camino uso AStarGrid2D, que ya viene con Godot. El nivel arma la
# grilla una sola vez en su _ready() y yo solo le pregunto
# "nivel.camino_entre(donde estoy, donde esta el jugador)".
#
# Un detalle: si lo tengo a la vista no uso el camino, voy derecho. Primero
# porque es lo que haria cualquiera, y segundo porque seguir los puntos de
# la grilla cuando lo tengo al lado lo hacia caminar en zigzag.

# Cada cuanto vuelvo a calcular el camino. No lo hago todos los frames
# porque es la cuenta mas cara que hago y total el jugador tampoco se
# teletransporta.
const CADA_CUANTO_RECALCULO = 0.35

# Cuando estoy a menos de esto de un punto del camino, lo doy por pasado y
# apunto al siguiente.
const DISTANCIA_PARA_PASAR_EL_PUNTO = 20.0

@export_group("Lo que lo hace inteligente")
# Cuando te tiene a la vista acelera un poco, como si se envalentonara.
@export var velocidad_cuando_te_ve = 165.0

# El camino que me dio el nivel y por que punto voy.
var camino = PackedVector2Array()
var punto_actual = 0

var _tiempo_para_recalcular = 0.0


# Sobreescribo _physics_process para agregarle lo del camino, pero lo primero
# que hago es llamar al de la clase comun con super, porque ahi se calculan
# la distancia al jugador y si lo veo. Si me olvido del super, nada funciona.
func _physics_process(delta):
	super._physics_process(delta)

	_tiempo_para_recalcular = _tiempo_para_recalcular - delta

	# Solo calculo el camino cuando NO lo veo, que es justo cuando hay una
	# pared en el medio y lo necesito.
	if hay_jugador() and not lo_veo and _tiempo_para_recalcular <= 0.0:
		_pedir_un_camino_nuevo()

	# Para poder dibujar el camino con F3.
	queue_redraw()


# --- Las funciones que sobreescribo de la clase Enemigo ------------------

func como_me_llamo():
	return "Zombie listo"


func hacia_donde_persigo():
	# Si lo tengo a la vista voy derecho, no hace falta ningun camino.
	if lo_veo:
		camino = PackedVector2Array()
		return direccion_al_jugador()

	# Si todavia no tengo camino (o no habia ninguno), voy derecho igual.
	if camino.size() == 0:
		return direccion_al_jugador()

	# Voy salteando los puntos que ya pase.
	while punto_actual < camino.size():
		if global_position.distance_to(camino[punto_actual]) > DISTANCIA_PARA_PASAR_EL_PUNTO:
			break
		punto_actual = punto_actual + 1

	# Me quede sin puntos: llegue al final del camino.
	if punto_actual >= camino.size():
		return direccion_al_jugador()

	return (camino[punto_actual] - global_position).normalized()


func velocidad_de_ahora():
	if lo_veo:
		return velocidad_cuando_te_ve
	return velocidad


# --- Lo del camino ------------------------------------------------------

func _pedir_un_camino_nuevo():
	_tiempo_para_recalcular = CADA_CUANTO_RECALCULO

	var nivel = get_tree().get_first_node_in_group("nivel")
	if nivel == null:
		return

	camino = nivel.camino_entre(global_position, jugador.global_position)
	punto_actual = 0

	# El primer punto del camino es la celda donde ya estoy parado, asi que
	# lo salteo de una para no quedarme caminando hacia mis propios pies.
	if camino.size() > 1:
		punto_actual = 1


# Dibujo el camino cuando esta prendido el F3. No cambia nada del juego,
# es para poder mostrar en la entrega que el zombie va esquivando de verdad
# y no es casualidad.
func _draw():
	if not Game.ver_estados or camino.size() == 0:
		return

	var puntos = []
	for i in range(punto_actual, camino.size()):
		# to_local porque _draw() dibuja en coordenadas mias, no del mundo.
		puntos.append(to_local(camino[i]))

	if puntos.size() == 0:
		return

	var color = Color(1.0, 0.45, 0.55, 0.85)

	# La linea desde donde estoy hasta el primer punto que me falta.
	draw_line(Vector2.ZERO, puntos[0], color, 2.0)

	if puntos.size() >= 2:
		draw_polyline(PackedVector2Array(puntos), color, 2.0)

	for p in puntos:
		draw_circle(p, 3.0, color)
