class_name Enemigo
extends CharacterBody2D

# ENEMIGO: LA CLASE COMUN
#
# Esta es la clase de la que heredan los dos tipos de enemigo que tiene el
# juego. Con "class_name Enemigo" arriba le pongo nombre a la clase, y eso
# hace que los otros scripts puedan escribir "extends Enemigo".
#
#   Enemigo  (este archivo)
#     ├── EnemigoTonto         -> enemigo_tonto.gd
#     └── EnemigoInteligente   -> enemigo_inteligente.gd
#
# Aca pongo todo lo que los dos hacen IGUAL: tener vida, recibir balazos,
# moverse, mirar al jugador, morir y dejar la mancha de sangre.
#
# Lo que cada uno hace DISTINTO son las cinco funciones que estan marcadas
# mas abajo con el titulo "funciones que cambia cada tipo de enemigo". Aca
# las dejo escritas pero casi vacias, y cada hijo las vuelve a escribir con
# lo suyo. Eso es sobreescribir un metodo.
#
# Antes esto lo tenia hecho con una variable "tipo" que valia 0 o 1, y en
# cada lado tenia que preguntar "if tipo == 0 ... else ...". Funcionaba, pero
# cada vez que queria agregar algo tenia que ir a buscar todos los if. Asi
# es mas largo de escribir al principio pero despues no toco nada: agrego un
# archivo nuevo con "extends Enemigo" y listo.

@export var vida_maxima = 60
@export var velocidad = 130.0
@export var puntos_que_da = 10

# El color del sprite. Lo uso para que los dos zombies se distingan de un
# vistazo: el tonto queda con el color normal y el inteligente mas rojizo.
#
# Lo guardo en una variable en vez de ponerlo a mano en la escena porque
# recibir_danio() hace un parpadeo blanco y despues tiene que volver a ESTE
# color. Antes volvia siempre a Color.WHITE y el zombie inteligente perdia
# el tinte apenas le pegaba un tiro.
@export var color_del_sprite = Color.WHITE

@export_group("Morder")
@export var danio_de_golpe = 12
@export var distancia_para_pegar = 46.0
@export var espera_entre_golpes = 0.8

# A partir de esta distancia el enemigo se despierta y empieza a perseguir.
# Hasta ese momento se queda en el estado Quieto.
#
# Esto lo agregue despues de probar el nivel: como los enemigos arrancan todos
# despiertos, se me venian los siete juntos desde la otra punta del mapa y era
# imposible. Asi el nivel se va abriendo de a poco, como en el Hotline Miami.
@export var distancia_para_despertar = 520.0

@onready var cuerpo = $Cuerpo
@onready var sprite = $Cuerpo/Sprite
@onready var maquina = $MaquinaDeEstados

var vida = 0

# Cuanto falta para poder volver a atacar. Lo bajo en _physics_process para
# que siga bajando aunque el enemigo cambie de estado.
var espera_ataque = 0.0

# Estas tres las calculo una vez por frame y las leen los estados, asi no
# hago la misma cuenta cuatro veces en el mismo frame.
var jugador = null
var distancia_al_jugador = 0.0
var lo_veo = false

# De donde vino el ultimo balazo. Lo uso para que la mancha de sangre salga
# para el lado correcto.
var ultimo_golpe = Vector2.ZERO


func _ready():
	add_to_group("enemigos")
	vida = vida_maxima
	sprite.modulate = color_del_sprite
	maquina.iniciar(self)
	# Nota: en las escenas de los enemigos les puse la mascara de colision 5,
	# que es la capa 1 (mundo) + la capa 3 (enemigos). Al principio solo
	# chocaban con las paredes, entonces se amontonaban todos en el mismo
	# lugar y parecian uno solo. Haciendo que choquen entre ellos quedan
	# repartidos sin que yo tenga que programar nada.


func _physics_process(delta):
	espera_ataque = max(0.0, espera_ataque - delta)

	jugador = get_tree().get_first_node_in_group("jugador")

	# Si el jugador no esta, o la partida ya termino, no calculo nada mas.
	if jugador == null or Game.perdio or Game.gano:
		lo_veo = false
		distancia_al_jugador = 99999.0
		return

	distancia_al_jugador = global_position.distance_to(jugador.global_position)
	lo_veo = puedo_ver_al_jugador()


# =========================================================================
# FUNCIONES QUE CAMBIA CADA TIPO DE ENEMIGO
#
# Estas tres estan escritas aca para que la clase comun sepa que existen,
# pero el que decide que hacen de verdad es cada hijo.
#
# Es la parte importante: los dos enemigos son zombies, muerden igual y se
# mueren igual. Lo UNICO que los hace tonto o inteligente es como deciden
# hacia donde caminar.
# =========================================================================

# El nombre que muestro en el cartelito de arriba de la cabeza (con F3).
func como_me_llamo():
	return "Zombie"


# Para donde caminar mientras persigue al jugador.
#
# Esta es LA funcion que cambia entre los dos. La version de aca es la mas
# boba: derecho hacia el jugador, sin fijarse si hay una pared en el medio.
# El zombie tonto se queda con esta; el inteligente la vuelve a escribir
# usando el buscador de caminos del nivel.
func hacia_donde_persigo():
	return direccion_al_jugador()


# A que velocidad camina en este momento. Por defecto siempre la misma, pero
# el inteligente la cambia cuando tiene al jugador a la vista.
#
# La puse aca y no en el estado para no tener que preguntar de que tipo es el
# enemigo: el estado llama a mover() y cada enemigo se mueve como le toca.
func velocidad_de_ahora():
	return velocidad


# =========================================================================
# COSAS QUE HACEN LOS DOS IGUAL
# De aca para abajo es lo que usan los estados.
# =========================================================================

func hay_jugador():
	return jugador != null and not Game.perdio and not Game.gano


func direccion_al_jugador():
	if jugador == null:
		return Vector2.ZERO
	return (jugador.global_position - global_position).normalized()


func mirar_al_jugador():
	if jugador != null:
		cuerpo.rotation = direccion_al_jugador().angle()


# Giro el sprite hacia un lugar cualquiera (lo usa el inteligente para mirar
# hacia donde esta caminando cuando perdio de vista al jugador).
func mirar_hacia(punto):
	if punto != global_position:
		cuerpo.rotation = (punto - global_position).angle()


func mover(direccion, delta):
	# move_toward hace que la velocidad suba de a poco en vez de arrancar de
	# golpe, queda mucho mejor que velocity = direccion * velocidad.
	velocity = velocity.move_toward(direccion * velocidad_de_ahora(), 900.0 * delta)
	move_and_slide()


func frenar(delta):
	velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()


func puede_atacar():
	return espera_ataque <= 0.0


# Si lo tengo lo bastante cerca como para morderlo.
func puedo_atacar_al_jugador():
	return distancia_al_jugador <= distancia_para_pegar


# El mordiscon. Los dos zombies muerden igual, por eso esta aca en la clase
# comun y no lo repito en cada hijo.
func atacar():
	if jugador == null:
		return

	espera_ataque = espera_entre_golpes
	jugador.recibir_danio(danio_de_golpe, direccion_al_jugador())
	Game.sonar("golpe")

	# Un estiron rapido para que se vea el mordiscon.
	var tween = create_tween()
	tween.tween_property(cuerpo, "scale", Vector2(1.15, 0.9), 0.08)
	tween.tween_property(cuerpo, "scale", Vector2.ONE, 0.12)


# Tiro un rayo invisible desde el enemigo hasta el jugador y miro si choca
# con algo. Si choca es porque hay una pared en el medio y no lo ve.
# Esto lo saque de la documentacion de Godot (PhysicsRayQueryParameters2D).
# El 1 del final es la capa de colision del mundo (las paredes).
func puedo_ver_al_jugador():
	if jugador == null:
		return false

	var espacio = get_world_2d().direct_space_state
	var consulta = PhysicsRayQueryParameters2D.create(
		global_position, jugador.global_position, 1, [get_rid()]
	)
	var choque = espacio.intersect_ray(consulta)
	return choque.is_empty()


# =========================================================================
# Esto lo llaman las balas del jugador
# =========================================================================

func recibir_danio(cantidad, de_donde = Vector2.ZERO):
	if vida <= 0:
		return

	vida = vida - cantidad
	ultimo_golpe = de_donde
	Game.sonar("impacto")

	# Empujoncito del balazo.
	velocity = velocity + de_donde.normalized() * 140.0

	# Parpadeo blanco y vuelta al color que le toca a este zombie.
	sprite.modulate = Color(1.6, 1.6, 1.6)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", color_del_sprite, 0.18)

	if vida <= 0:
		maquina.cambiar_a("Muerto")


# Lo llama el estado Muerto.
func morir():
	_dejar_mancha()
	Game.sonar("muerte")
	Game.sumar_puntos(puntos_que_da)
	Game.contar_enemigo_eliminado()
	queue_free()


# Dejo una mancha de sangre en el piso donde me mataron. Es un Sprite2D
# suelto que agrego al nivel, con z_index -1 para que quede abajo de los
# personajes.
func _dejar_mancha():
	var nivel = get_tree().get_first_node_in_group("nivel")
	if nivel == null:
		return

	var mancha = Sprite2D.new()
	mancha.texture = preload("res://assets/tile_320.png")
	mancha.global_position = global_position + ultimo_golpe.normalized() * 10.0
	mancha.rotation = randf() * TAU
	mancha.modulate = Color(0.55, 0.1, 0.12, 0.85)
	mancha.z_index = -1
	nivel.add_child(mancha)
