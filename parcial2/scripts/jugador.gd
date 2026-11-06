extends CharacterBody2D

# EL JUGADOR
#
# Este script NO decide que hacer en cada momento. Solo sabe COMO hacer cada
# cosa: moverse, apuntar, disparar, recargar. El CUANDO lo deciden los estados
# que estan en el nodo MaquinaDeEstados.
#
# Me costo entender la diferencia al principio, pero la ventaja se ve cuando
# queres agregar algo: si manianna quiero un estado "Aturdido" lo agrego como
# nodo nuevo y no toco nada de este archivo.
#
# Cosa importante de los sprites de Kenney: el personaje mira para la DERECHA.
# Entonces rotacion 0 = mirando a la derecha, y puedo usar directo el angulo
# hacia el mouse sin sumarle ni restarle nada.

# Las tres armas. Use un diccionario porque asi tengo todos los datos de cada
# arma juntos y despues solo cambio el numero de arma. La pistola es la 1 y
# es la que tiene balas infinitas, para no quedarme sin nada nunca.
#
# El "offset_x" es cuanto hay que correr el sprite. Esto me volvio loco: los
# PNG de Kenney no tienen al personaje en el centro de la imagen, el arma
# sobresale para la derecha, asi que si no lo corro el personaje gira raro,
# como si bailara. Los numeros los saque probando hasta que quedo bien.
const ARMAS = [
	{
		"nombre": "Pistola",
		"sprite": preload("res://assets/manBlue_gun.png"),
		"icono": preload("res://assets/weapon_gun.png"),
		"offset_x": 8.0,
		"canio": Vector2(31, 10),
		"danio": 34,
		"cadencia": 0.26,     # segundos entre tiro y tiro
		"cargador": 12,
		"recarga": 1.0,
		"desvio": 1.5,        # en grados
		"automatica": false,
		"balas_de_reserva": -1,   # -1 significa infinitas
	},
	{
		"nombre": "Ametralladora",
		"sprite": preload("res://assets/manBlue_machine.png"),
		"icono": preload("res://assets/weapon_machine.png"),
		"offset_x": 8.0,
		"canio": Vector2(31, 10),
		"danio": 17,
		"cadencia": 0.08,
		"cargador": 30,
		"recarga": 1.6,
		"desvio": 6.5,
		"automatica": true,
		"balas_de_reserva": 120,
	},
	{
		"nombre": "Silenciada",
		"sprite": preload("res://assets/manBlue_silencer.png"),
		"icono": preload("res://assets/weapon_silencer.png"),
		"offset_x": 10.5,
		"canio": Vector2(36, 10),
		"danio": 62,
		"cadencia": 0.55,
		"cargador": 8,
		"recarga": 1.35,
		"desvio": 0.5,
		"automatica": false,
		"balas_de_reserva": 48,
	},
]

# Este es el sprite de cuando esta recargando (baja el arma).
const SPRITE_RECARGANDO = preload("res://assets/manBlue_reload.png")
const OFFSET_RECARGANDO = 3.0

@export var velocidad = 255.0
@export var vida_maxima = 100
@export var escena_bala: PackedScene
# El fogonazo, las chispas y el humo que salen cuando disparo.
@export var escena_particulas_disparo: PackedScene

@export_group("Esquivar")
@export var velocidad_esquive = 720.0
@export var duracion_esquive = 0.16
@export var espera_entre_esquives = 0.85

@onready var cuerpo = $Cuerpo
@onready var sprite = $Cuerpo/Sprite
@onready var canio = $Cuerpo/Canio
@onready var maquina = $MaquinaDeEstados

var vida = 100
var arma = 0                # cual de las tres armas tengo en la mano (0, 1 o 2)
var balas_en_cargador = []  # cuantas balas me quedan en cada arma
var balas_de_reserva = []

# Estos tres son contadores de tiempo. Los bajo yo en _physics_process porque
# tienen que seguir bajando aunque cambie de estado.
var espera_tiro = 0.0
var espera_esquive = 0.0
var tiempo_invulnerable = 0.0


func _ready():
	add_to_group("jugador")
	vida = vida_maxima

	# Arranco con todos los cargadores llenos.
	for a in ARMAS:
		balas_en_cargador.append(a["cargador"])
		balas_de_reserva.append(a["balas_de_reserva"])

	_poner_sprite_del_arma()
	_acomodar_camara()

	# Recien aca, cuando ya esta todo listo, arranco la maquina de estados.
	maquina.iniciar(self)


func _acomodar_camara():
	# Para que la camara no muestre el negro de afuera del mapa.
	var nivel = get_tree().get_first_node_in_group("nivel")
	if nivel == null:
		return
	$Camara.limit_left = 0
	$Camara.limit_top = 0
	$Camara.limit_right = int(nivel.ancho_en_pixeles)
	$Camara.limit_bottom = int(nivel.alto_en_pixeles)


func _physics_process(delta):
	# Bajo los contadores. Uso max() para que no se vayan a negativo.
	espera_tiro = max(0.0, espera_tiro - delta)
	espera_esquive = max(0.0, espera_esquive - delta)
	tiempo_invulnerable = max(0.0, tiempo_invulnerable - delta)


# =========================================================================
# De aca para abajo estan las cosas que usan los estados
# =========================================================================

# --- Moverse -------------------------------------------------------------

# Devuelve para donde apuntan las teclas. Si no aprieto nada da (0, 0).
func teclas_de_movimiento():
	return Input.get_vector("izquierda", "derecha", "arriba", "abajo")


func mirar_al_mouse():
	cuerpo.rotation = (get_global_mouse_position() - global_position).angle()


func mover(direccion, delta):
	# move_toward hace que vaya subiendo la velocidad de a poco en vez de
	# arrancar de golpe. Queda mucho mejor que velocity = direccion * velocidad.
	velocity = velocity.move_toward(direccion * velocidad, 2000.0 * delta)
	move_and_slide()


func frenar(delta):
	velocity = velocity.move_toward(Vector2.ZERO, 2600.0 * delta)
	move_and_slide()


func moverse_esquivando(direccion):
	velocity = direccion * velocidad_esquive
	move_and_slide()


# Para donde esquivar. Si no estoy apretando teclas, esquivo para adelante.
func direccion_del_esquive():
	var teclas = teclas_de_movimiento()
	if teclas != Vector2.ZERO:
		return teclas.normalized()
	return Vector2.RIGHT.rotated(cuerpo.rotation)


func puede_esquivar():
	return espera_esquive <= 0.0


func empezar_espera_del_esquive():
	espera_esquive = espera_entre_esquives
	# Mientras esquivo no me pueden pegar. Sin esto el esquive no servia para
	# nada y era solo "correr mas rapido".
	tiempo_invulnerable = duracion_esquive + 0.06


func poner_transparente(si_o_no):
	if si_o_no:
		sprite.modulate = Color(1, 1, 1, 0.55)
	else:
		sprite.modulate = Color.WHITE


# --- Armas ---------------------------------------------------------------

func arma_actual():
	return ARMAS[arma]


# Mira si apreto 1, 2 o 3 y cambia de arma.
# Devuelve true si cambio, asi el estado Recargar sabe que tiene que cancelar.
func revisar_cambio_de_arma():
	var nueva = arma

	if Input.is_action_just_pressed("arma_1"):
		nueva = 0
	if Input.is_action_just_pressed("arma_2"):
		nueva = 1
	if Input.is_action_just_pressed("arma_3"):
		nueva = 2

	if nueva == arma:
		return false

	arma = nueva
	espera_tiro = 0.2   # una demorita al cambiar, si no es muy facil
	_poner_sprite_del_arma()
	return true


func quiere_disparar():
	if arma_actual()["automatica"]:
		return Input.is_action_pressed("disparar")
	return Input.is_action_just_pressed("disparar")


func cargador_vacio():
	return balas_en_cargador[arma] <= 0


func disparar():
	if espera_tiro > 0.0 or cargador_vacio() or escena_bala == null:
		return

	var a = arma_actual()
	balas_en_cargador[arma] = balas_en_cargador[arma] - 1
	espera_tiro = a["cadencia"]

	# El desvio hace que no todos los tiros salgan perfectos.
	var desvio = deg_to_rad(a["desvio"])
	var angulo = cuerpo.rotation + randf_range(-desvio, desvio)

	var bala = escena_bala.instantiate()
	get_tree().get_first_node_in_group("balas").add_child(bala)
	bala.disparar_desde(canio.global_position, angulo, a["danio"], "jugador")
	Game.sonar("disparo")
	_tirar_particulas_del_disparo()

	# Retroceso: me empuja un poquito para atras cuando disparo.
	velocity = velocity - Vector2.RIGHT.rotated(cuerpo.rotation) * 70.0


# Pongo las particulas en la punta del canio, mirando para donde apunta el
# arma. Las agrego al nodo Balas y no adentro del jugador para que el humo
# se quede en el lugar del tiro y no me siga cuando camino.
func _tirar_particulas_del_disparo():
	if escena_particulas_disparo == null:
		return

	var particulas = escena_particulas_disparo.instantiate()
	get_tree().get_first_node_in_group("balas").add_child(particulas)
	particulas.global_position = canio.global_position
	particulas.rotation = cuerpo.rotation


# --- Recargar ------------------------------------------------------------

func quiere_recargar():
	return Input.is_action_just_pressed("recargar")


func puede_recargar():
	# No tiene sentido recargar si ya esta lleno o si no me queda nada.
	var a = arma_actual()
	if balas_en_cargador[arma] >= a["cargador"]:
		return false
	if balas_de_reserva[arma] == 0:
		return false
	return true


func tiempo_de_recarga():
	return arma_actual()["recarga"]


func terminar_recarga():
	var a = arma_actual()
	var faltan = a["cargador"] - balas_en_cargador[arma]

	if balas_de_reserva[arma] < 0:
		# La pistola tiene balas infinitas.
		balas_en_cargador[arma] = a["cargador"]
	else:
		# Si no me alcanza la reserva, cargo lo que tengo.
		var saco = min(faltan, balas_de_reserva[arma])
		balas_en_cargador[arma] = balas_en_cargador[arma] + saco
		balas_de_reserva[arma] = balas_de_reserva[arma] - saco


func poner_sprite_de_recarga():
	sprite.texture = SPRITE_RECARGANDO
	sprite.offset.x = OFFSET_RECARGANDO


func poner_sprite_del_arma():
	_poner_sprite_del_arma()


# --- Vida ----------------------------------------------------------------

func esta_invulnerable():
	return tiempo_invulnerable > 0.0


# Lo llama el estado Muerto cuando entra.
func morir():
	velocity = Vector2.ZERO
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.8)
	Game.perder_partida()


# =========================================================================
# Esto lo llaman las balas de los enemigos y los botiquines, no los estados
# =========================================================================

func recibir_danio(cantidad, _de_donde = Vector2.ZERO):
	if esta_invulnerable() or vida <= 0:
		return

	vida = max(0, vida - cantidad)

	# Un ratito invulnerable despues de que me peguen, si no entre varios
	# zombies me matan en un segundo y no llegas a hacer nada.
	tiempo_invulnerable = 0.35

	# Parpadeo en rojo. El Tween hace la animacion solo, es comodisimo.
	sprite.modulate = Color(1.0, 0.45, 0.45)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)

	if vida == 0:
		# Morirse no es algo que el estado actual pueda decidir, le pasa por
		# arriba. Por eso le aviso a la maquina directamente desde aca.
		maquina.cambiar_a("Muerto")


func curar(cantidad):
	vida = min(vida_maxima, vida + cantidad)


# Devuelve true si me sirvio, si no el cajon de municion no se gasta.
func dar_municion(cantidad):
	var me_sirvio = false

	for i in range(ARMAS.size()):
		if balas_de_reserva[i] < 0:
			continue   # la pistola ya tiene infinitas
		var maximo = ARMAS[i]["balas_de_reserva"]
		if balas_de_reserva[i] < maximo:
			balas_de_reserva[i] = min(maximo, balas_de_reserva[i] + cantidad)
			me_sirvio = true

	return me_sirvio


# =========================================================================

func _poner_sprite_del_arma():
	var a = arma_actual()
	sprite.texture = a["sprite"]
	sprite.offset.x = a["offset_x"]
	canio.position = a["canio"]
