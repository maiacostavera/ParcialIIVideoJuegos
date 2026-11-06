extends CanvasLayer

# EL HUD (los carteles de la pantalla)
#
# En vez de usar señales, en cada frame leo los valores del jugador y de
# Game y los escribo en los Labels. Es la forma mas facil que encontre y
# para este juego alcanza de sobra.
#
# Tambien tiene las tres pantallas que tapan el juego: la de ganar el nivel,
# la de perder y la de pausa. Las tengo como nodos ya armados y solo les
# cambio el visible, asi no tengo que crear nada con codigo.

@onready var barra_vida = $Todo/BarraVida
@onready var texto_vida = $Todo/BarraVida/TextoVida
@onready var icono_arma = $Todo/IconoArma
@onready var texto_arma = $Todo/TextoArma
@onready var texto_balas = $Todo/TextoBalas
@onready var texto_nivel = $Todo/TextoNivel
@onready var texto_puntaje = $Todo/TextoPuntaje
@onready var texto_enemigos = $Todo/TextoEnemigos
@onready var texto_meta = $Todo/TextoMeta

@onready var pantalla_victoria = $Todo/PantallaVictoria
@onready var titulo_victoria = $Todo/PantallaVictoria/Cartel/Margen/Lista/Titulo
@onready var texto_victoria = $Todo/PantallaVictoria/Cartel/Margen/Lista/Texto
@onready var boton_siguiente = $Todo/PantallaVictoria/Cartel/Margen/Lista/BotonSiguiente
@onready var boton_menu_victoria = $Todo/PantallaVictoria/Cartel/Margen/Lista/BotonMenu

@onready var pantalla_derrota = $Todo/PantallaDerrota
@onready var texto_derrota = $Todo/PantallaDerrota/Cartel/Margen/Lista/Texto
@onready var boton_reintentar = $Todo/PantallaDerrota/Cartel/Margen/Lista/BotonReintentar
@onready var boton_menu_derrota = $Todo/PantallaDerrota/Cartel/Margen/Lista/BotonMenu

@onready var pantalla_pausa = $Todo/PantallaPausa
@onready var boton_continuar = $Todo/PantallaPausa/Cartel/Margen/Lista/BotonContinuar
@onready var boton_reiniciar_pausa = $Todo/PantallaPausa/Cartel/Margen/Lista/BotonReiniciar
@onready var boton_menu_pausa = $Todo/PantallaPausa/Cartel/Margen/Lista/BotonMenu

# La tabla de mejores puntajes. Es la misma escena que esta en el menu, aca
# solo la muestro cuando termina la partida.
@onready var tabla_puntajes = $Todo/TablaPuntajes

var jugador = null
var en_pausa = false


func _ready():
	# Sin esto el HUD se pausa junto con el juego y los botones no se pueden
	# apretar. Como los hijos heredan el process_mode, poniendolo aca alcanza
	# para todos los botones.
	process_mode = Node.PROCESS_MODE_ALWAYS

	pantalla_victoria.visible = false
	pantalla_derrota.visible = false
	pantalla_pausa.visible = false
	tabla_puntajes.visible = false

	# Conecto los botones por codigo en vez de desde el editor, asi se ve en
	# el script que hace cada uno.
	boton_siguiente.pressed.connect(_apretaron_siguiente)
	boton_menu_victoria.pressed.connect(_apretaron_menu)
	boton_reintentar.pressed.connect(_apretaron_reintentar)
	boton_menu_derrota.pressed.connect(_apretaron_menu)
	boton_continuar.pressed.connect(_apretaron_continuar)
	boton_reiniciar_pausa.pressed.connect(_apretaron_reintentar)
	boton_menu_pausa.pressed.connect(_apretaron_menu)


func _process(_delta):
	# Busco al jugador cada vez porque cuando el HUD arranca todavia no existe.
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")

	texto_nivel.text = "Nivel  " + str(Game.nivel_actual)
	texto_puntaje.text = "Puntaje  " + str(Game.puntaje)
	texto_enemigos.text = "Enemigos  " + str(_cuantos_enemigos_quedan())

	if jugador != null:
		_mostrar_datos_del_jugador()
		_mostrar_distancia_a_la_meta()

	if Game.gano and not pantalla_victoria.visible:
		_mostrar_pantalla_de_victoria()

	if Game.perdio and not pantalla_derrota.visible:
		_mostrar_pantalla_de_derrota()


func _cuantos_enemigos_quedan():
	return get_tree().get_nodes_in_group("enemigos").size()


func _mostrar_datos_del_jugador():
	barra_vida.max_value = jugador.vida_maxima
	barra_vida.value = jugador.vida
	texto_vida.text = str(jugador.vida) + " / " + str(jugador.vida_maxima)

	var arma = jugador.arma_actual()
	icono_arma.texture = arma["icono"]
	texto_arma.text = arma["nombre"]

	var en_cargador = jugador.balas_en_cargador[jugador.arma]
	var reserva = jugador.balas_de_reserva[jugador.arma]

	if reserva < 0:
		texto_balas.text = str(en_cargador) + " / " + str(arma["cargador"])
	else:
		texto_balas.text = str(en_cargador) + " / " + str(arma["cargador"]) \
			+ "   (" + str(reserva) + ")"


# Muestro a cuantos metros esta la meta, porque el mapa es mas grande que la
# pantalla y si no no sabes para donde ir. Una celda del mapa son 64 pixeles,
# asi que la cuento como 1 metro.
func _mostrar_distancia_a_la_meta():
	var nivel = get_tree().get_first_node_in_group("nivel")
	if nivel == null:
		return

	var distancia = jugador.global_position.distance_to(nivel.donde_esta_la_meta)
	var metros = int(distancia / 64.0)
	texto_meta.text = "META a " + str(metros) + " m"


# =========================================================================
# Las pantallas
# =========================================================================

func _mostrar_pantalla_de_victoria():
	pantalla_pausa.visible = false

	if Game.hay_nivel_siguiente():
		titulo_victoria.text = "NIVEL COMPLETADO"
		texto_victoria.text = "Llegaste a la meta del nivel " \
			+ str(Game.nivel_actual) + " con " + str(Game.puntaje) + " puntos."
		boton_siguiente.text = "Siguiente nivel"
		boton_siguiente.visible = true
	else:
		# Era el ultimo nivel, asi que gano el juego entero.
		titulo_victoria.text = "GANASTE EL JUEGO"
		texto_victoria.text = "Terminaste los " + str(Game.CANTIDAD_DE_NIVELES) \
			+ " niveles con " + str(Game.puntaje) + " puntos." + _texto_del_puesto()
		boton_siguiente.visible = false
		# Termino la partida, asi que muestro la tabla al costado.
		_mostrar_tabla()

	pantalla_victoria.visible = true


func _mostrar_pantalla_de_derrota():
	pantalla_pausa.visible = false
	texto_derrota.text = "Te mataron en el nivel " + str(Game.nivel_actual) \
		+ ". Habias hecho " + str(Game.puntaje) + " puntos." + _texto_del_puesto()
	pantalla_derrota.visible = true
	_mostrar_tabla()


# La tabla la actualizo recien aca y no en su _ready(), porque el puntaje de
# esta partida se anota en Game justo cuando gano o pierdo.
func _mostrar_tabla():
	tabla_puntajes.actualizar(Game.puesto_nuevo)
	tabla_puntajes.visible = true


# Si la partida entro en la tabla, le agrego al cartel en que puesto quedo.
func _texto_del_puesto():
	if Game.puesto_nuevo < 0:
		return ""
	return "\nQuedaste en el puesto " + str(Game.puesto_nuevo + 1) + " de la tabla."


func _input(evento):
	# Con Enter reinicio el nivel cuando perdi, para no tener que ir con el
	# mouse hasta el boton.
	if Game.perdio and evento.is_action_pressed("reiniciar"):
		_apretaron_reintentar()
		return

	if evento.is_action_pressed("pausa"):
		# Si ya gane o perdi, Escape me lleva al menu en vez de pausar.
		if Game.gano or Game.perdio:
			_apretaron_menu()
		else:
			_cambiar_pausa()


func _cambiar_pausa():
	en_pausa = not en_pausa
	pantalla_pausa.visible = en_pausa
	get_tree().paused = en_pausa


# =========================================================================
# Los botones
# =========================================================================

func _apretaron_siguiente():
	Game.sonar("boton")
	Game.siguiente_nivel()


func _apretaron_reintentar():
	Game.sonar("boton")
	Game.reiniciar_nivel()


func _apretaron_continuar():
	Game.sonar("boton")
	_cambiar_pausa()


func _apretaron_menu():
	Game.sonar("boton")
	Game.ir_al_menu()
