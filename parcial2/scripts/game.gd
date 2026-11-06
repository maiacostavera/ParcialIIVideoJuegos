extends Node

# GAME (autoload)
#
# Este script esta puesto como Autoload en Proyecto > Configuracion del
# proyecto > Autoload, con el nombre "Game". Al ser Autoload esta siempre
# cargado, asi que desde cualquier script puedo escribir Game.puntaje y
# funciona.
#
# Lo uso para guardar las cosas que tienen que sobrevivir cuando cambio de
# escena: en que nivel estoy, el puntaje y la tabla de mejores puntajes. Si
# esto estuviera en la escena de la partida, al pasar de nivel se borraria
# todo.

# Las escenas del juego. Las pongo como constantes para no escribir la ruta
# a mano en cada lugar y equivocarme en una letra.
const ESCENA_MENU = "res://escenas/menu_principal.tscn"
const ESCENA_PARTIDA = "res://escenas/partida.tscn"

const CANTIDAD_DE_NIVELES = 2

# Los sonidos. Son .wav que estan en assets/sonidos/.
const SONIDOS = {
	"disparo": "res://assets/sonidos/disparo.wav",
	"golpe": "res://assets/sonidos/golpe.wav",
	"impacto": "res://assets/sonidos/impacto.wav",
	"muerte": "res://assets/sonidos/muerte.wav",
	"recarga": "res://assets/sonidos/recarga.wav",
	"item": "res://assets/sonidos/item.wav",
	"boton": "res://assets/sonidos/boton.wav",
	"victoria": "res://assets/sonidos/victoria.wav",
	"derrota": "res://assets/sonidos/derrota.wav",
}

# --- Como viene la partida ---
var nivel_actual = 1
var puntaje = 0
var enemigos_eliminados = 0
var perdio = false
var gano = false

# --- Volumen ---
var volumen = 0.8        # de 0 a 1

# Se prende y apaga con F3. Muestra arriba de cada personaje en que estado
# esta. Lo deje para poder mostrar que la maquina de estados anda de verdad.
var ver_estados = false

# --- Mejores puntajes ---
# Se guardan en un archivo en user://, que es una carpeta que Godot le da a
# cada juego para guardar cosas (en Windows esta en AppData). Asi la tabla
# sigue estando aunque cierre el juego.
const ARCHIVO_PUNTAJES = "user://puntajes.json"
const CUANTOS_PUNTAJES_GUARDO = 10

# Lista de {"puntos": ..., "nivel": ..., "gano": ..., "fecha": ...}, ordenada
# de mayor a menor.
var mejores_puntajes = []

# En que lugar de la tabla quedo la ultima partida, para pintarla de otro
# color. Vale -1 si no entro (o si todavia no termino ninguna).
var puesto_nuevo = -1

# --- Fundido entre escenas ---
# Para que no cambie de golpe de una escena a otra, la tapo con una cortina
# negra, cambio la escena y la vuelvo a destapar.
const DURACION_FUNDIDO = 0.35

var _cortina = null
var _cambiando_de_escena = false


func _ready():
	# Cuando el jugador gana o pierde pauso el juego con get_tree().paused.
	# Si no pongo esto, este script tambien se pausa y despues no puedo
	# cambiar de escena ni hacer sonar nada.
	process_mode = Node.PROCESS_MODE_ALWAYS
	aplicar_volumen()
	cargar_puntajes()
	_crear_la_cortina()

	# El juego arranca con la cortina puesta y la saco de a poco, asi el menu
	# tampoco aparece de golpe.
	_cambiando_de_escena = true
	_cortina.modulate.a = 1.0
	_destapar()


func _input(evento):
	if evento.is_action_pressed("ver_estados"):
		ver_estados = not ver_estados


# =========================================================================
# Cambiar de escena
# =========================================================================

# Lo llaman los botones "Nivel 1" y "Nivel 2" del menu.
func empezar_nivel(numero):
	nivel_actual = numero
	puntaje = 0
	enemigos_eliminados = 0
	puesto_nuevo = -1
	_ir_a(ESCENA_PARTIDA)


# Lo llama el boton "Siguiente nivel" de la pantalla de victoria.
# El puntaje NO lo reseteo: se va acumulando entre niveles.
func siguiente_nivel():
	# Si ya se esta haciendo el fundido no sumo otro nivel. Pasa si apretan
	# dos veces el boton mientras se oscurece la pantalla.
	if _cambiando_de_escena:
		return
	if not hay_nivel_siguiente():
		ir_al_menu()
		return
	nivel_actual = nivel_actual + 1
	_ir_a(ESCENA_PARTIDA)


func reiniciar_nivel():
	puntaje = 0
	enemigos_eliminados = 0
	puesto_nuevo = -1
	_ir_a(ESCENA_PARTIDA)


func ir_al_menu():
	_ir_a(ESCENA_MENU)


func hay_nivel_siguiente():
	return nivel_actual < CANTIDAD_DE_NIVELES


# Esta la uso en todas las de arriba. Antes de cambiar de escena tengo que
# despausar y limpiar perdio/gano, porque si no la escena nueva arranca
# pausada y con la pantalla de "perdiste" puesta.
#
# Primero pongo la cortina negra (fundido), y recien cuando esta todo negro
# despauso y cambio la escena. Si despausara antes, los zombies se moverian
# mientras se oscurece la pantalla de "perdiste".
func _ir_a(ruta):
	# Si ya estoy cambiando de escena no hago nada. Pasa por ejemplo si
	# apretan dos veces seguidas el boton.
	if _cambiando_de_escena:
		return
	_cambiando_de_escena = true

	# Mientras se oscurece no dejo que hagan clic en los botones de abajo.
	_cortina.mouse_filter = Control.MOUSE_FILTER_STOP

	# Este tween anda aunque el juego este pausado porque Game tiene
	# process_mode ALWAYS (ver _ready()).
	var tween = create_tween()
	tween.tween_property(_cortina, "modulate:a", 1.0, DURACION_FUNDIDO)
	await tween.finished

	perdio = false
	gano = false
	get_tree().paused = false
	get_tree().change_scene_to_file(ruta)
	_destapar()


# Saca la cortina de a poco para que aparezca la escena nueva.
func _destapar():
	var tween = create_tween()
	tween.tween_property(_cortina, "modulate:a", 0.0, DURACION_FUNDIDO)
	await tween.finished
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cambiando_de_escena = false


# La cortina es un ColorRect negro que tapa toda la pantalla. La creo por
# codigo porque Game es un Autoload que es solo un script, no tiene escena
# donde ponerla. Va adentro de un CanvasLayer con layer 100 para que quede
# arriba de todo, incluso del HUD.
func _crear_la_cortina():
	var capa = CanvasLayer.new()
	capa.layer = 100
	add_child(capa)

	_cortina = ColorRect.new()
	_cortina.color = Color.BLACK
	_cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	capa.add_child(_cortina)


# =========================================================================
# Puntaje, ganar y perder
# =========================================================================

func sumar_puntos(cantidad):
	puntaje = puntaje + cantidad


func contar_enemigo_eliminado():
	enemigos_eliminados = enemigos_eliminados + 1


# Lo llama el jugador cuando se queda sin vida.
func perder_partida():
	if perdio or gano:
		return
	perdio = true
	sonar("derrota")
	anotar_puntaje(false)
	get_tree().paused = true


# Lo llama la meta cuando el jugador la toca.
func ganar_nivel():
	if perdio or gano:
		return
	gano = true
	sonar("victoria")
	# Si era el ultimo nivel termino la partida, asi que la anoto en la
	# tabla. Si hay nivel siguiente todavia no, porque el puntaje se sigue
	# sumando en el otro nivel.
	if not hay_nivel_siguiente():
		anotar_puntaje(true)
	get_tree().paused = true


# =========================================================================
# Tabla de mejores puntajes
# =========================================================================

# Se fija si el puntaje de la partida que termino entra en la tabla, y si
# entra lo mete en su lugar y guarda el archivo.
#
# Se anota cuando perdes o cuando ganas el ultimo nivel. Si salis al menu a
# la mitad desde la pausa no se anota, porque la partida no termino.
func anotar_puntaje(gano_el_juego):
	puesto_nuevo = -1

	# Una partida con 0 puntos no tiene sentido guardarla.
	if puntaje <= 0:
		return

	# Busco el lugar: antes del primero que tenga menos puntos que yo.
	var lugar = mejores_puntajes.size()
	for i in range(mejores_puntajes.size()):
		if puntaje > mejores_puntajes[i]["puntos"]:
			lugar = i
			break

	if lugar >= CUANTOS_PUNTAJES_GUARDO:
		return   # no le alcanzo para entrar

	var hoy = Time.get_date_dict_from_system()
	var nuevo = {
		"puntos": puntaje,
		"nivel": nivel_actual,
		"gano": gano_el_juego,
		"fecha": "%02d/%02d/%d" % [hoy["day"], hoy["month"], hoy["year"]],
	}

	mejores_puntajes.insert(lugar, nuevo)

	# Si ya habia 10, el de abajo de todo se cae de la tabla.
	if mejores_puntajes.size() > CUANTOS_PUNTAJES_GUARDO:
		mejores_puntajes.resize(CUANTOS_PUNTAJES_GUARDO)

	puesto_nuevo = lugar
	guardar_puntajes()


# Los guardo como JSON porque es texto y se puede abrir con el bloc de notas
# para ver que se guardo bien.
func guardar_puntajes():
	var archivo = FileAccess.open(ARCHIVO_PUNTAJES, FileAccess.WRITE)
	if archivo == null:
		print("ERROR: no pude guardar los puntajes en ", ARCHIVO_PUNTAJES)
		return
	archivo.store_string(JSON.stringify(mejores_puntajes, "\t"))
	archivo.close()


func cargar_puntajes():
	mejores_puntajes = []

	# La primera vez que se abre el juego el archivo todavia no existe.
	if not FileAccess.file_exists(ARCHIVO_PUNTAJES):
		return

	var archivo = FileAccess.open(ARCHIVO_PUNTAJES, FileAccess.READ)
	if archivo == null:
		return

	# Si el archivo esta roto, parse_string devuelve null en vez de una
	# lista. En ese caso arranco con la tabla vacia en vez de romper el juego.
	var datos = JSON.parse_string(archivo.get_as_text())
	if datos is Array:
		mejores_puntajes = datos


# =========================================================================
# Sonido
# =========================================================================

# Hace sonar un efecto. Creo el reproductor, lo hago sonar y cuando termina
# se borra solo.
#
# Al principio ponia un nodo AudioStreamPlayer dentro de cada escena, pero
# tenia un problema: el enemigo hace queue_free() al morir y se borraba junto
# con el sonido, entonces el quejido se cortaba enseguida. Haciendolo desde
# aca el sonido no depende de quien lo pidio.
func sonar(nombre):
	if not SONIDOS.has(nombre):
		print("ERROR: no existe el sonido '", nombre, "'")
		return

	var audio = load(SONIDOS[nombre])
	if audio == null:
		return   # si falta el archivo no quiero que se caiga el juego

	var reproductor = AudioStreamPlayer.new()
	reproductor.stream = audio
	reproductor.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(reproductor)
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()


# =========================================================================
# Volumen
# =========================================================================

# El volumen va de 0 a 1, pero Godot lo pide en decibeles, por eso uso
# linear_to_db(). Si esta en 0 directamente silencio el bus, porque
# linear_to_db(0) da -infinito.
func aplicar_volumen():
	var bus = AudioServer.get_bus_index("Master")
	if volumen <= 0.0:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(volumen))
